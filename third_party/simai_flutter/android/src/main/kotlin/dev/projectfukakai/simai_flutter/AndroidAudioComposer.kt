package dev.projectfukakai.simai_flutter

import android.media.AudioFormat
import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMuxer
import java.io.File
import java.io.FileOutputStream
import java.io.RandomAccessFile
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.ceil
import kotlin.math.floor
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

internal data class JudgementSoundEvent(
    val timeUs: Long,
    val kind: String,
    val volume: Float,
)

internal class AndroidAudioComposer(
    private val musicFile: File,
    private val hitSoundFile: File?,
    private val judgementSoundFiles: Map<String, File> = emptyMap(),
    private val videoFile: File,
    private val outputFile: File,
    private val workingDirectory: File,
    private val isCancelled: () -> Boolean,
) {
    private val decodedPcmFile = File(workingDirectory, "music.pcm")
    private val decodedHitSoundPcmFile = File(workingDirectory, "hitsound.pcm")
    private val encodedAudioFile = File(workingDirectory, "audio.m4a")

    fun compose(
        durationUs: Long,
        timelineStartUs: Long,
        musicOffsetUs: Long,
        musicVolume: Float,
        hitSoundVolume: Float = 2.0f,
        hitEventTimesUs: List<Long>,
        judgementEvents: List<JudgementSoundEvent> = emptyList(),
    ) {
        checkCancelled()
        val decoded = decodeAudioFileToPcm(musicFile, decodedPcmFile)
        val hitSound = hitSoundFile?.let { decodeHitSoundTo48kMono(it, decodedHitSoundPcmFile) }
        val decodedJudgeByPath = mutableMapOf<String, HitSoundPcm>()
        val judgeBank = mutableMapOf<String, HitSoundPcm>()
        var tempIndex = 0
        for ((kind, file) in judgementSoundFiles) {
            checkCancelled()
            val path = file.absolutePath
            val cached = decodedJudgeByPath[path]
            if (cached != null) {
                judgeBank[kind] = cached
                continue
            }
            val tempPcm = File(workingDirectory, "judge_${tempIndex++}.pcm")
            val pcm = decodeHitSoundTo48kMono(file, tempPcm)
            decodedJudgeByPath[path] = pcm
            judgeBank[kind] = pcm
        }
        encodeMixedAac(
            decoded = decoded,
            hitSound = hitSound,
            judgeBank = judgeBank,
            durationUs = durationUs,
            timelineStartUs = timelineStartUs,
            musicOffsetUs = musicOffsetUs,
            musicVolume = musicVolume,
            hitSoundVolume = hitSoundVolume,
            hitEventTimesUs = hitEventTimesUs,
            judgementEvents = judgementEvents,
        )
        checkCancelled()
        muxTracks(videoFile, encodedAudioFile, outputFile)
    }

    private fun decodeHitSoundTo48kMono(file: File, tempPcmFile: File): HitSoundPcm {
        WavPcm16.tryReadMono48k(file, MAX_HIT_SOUND_FRAMES)?.let { return it }
        val decoded = decodeAudioFileToPcm(file, tempPcmFile)
        val sampler = PcmFileSampler(decoded)
        try {
            val targetFrames = ceil(decoded.frameCount * OUTPUT_SAMPLE_RATE.toDouble() / decoded.sampleRate)
                .toLong()
                .coerceIn(1L, MAX_HIT_SOUND_FRAMES)
                .toInt()
            val samples = FloatArray(targetFrames)
            val rateRatio = decoded.sampleRate.toDouble() / OUTPUT_SAMPLE_RATE.toDouble()
            for (i in 0 until targetFrames) {
                val srcFrame = i * rateRatio
                val mixed = if (decoded.channels == 1) {
                    sampler.sample(srcFrame, 0)
                } else {
                    (sampler.sample(srcFrame, 0) + sampler.sample(srcFrame, 1)) * 0.5f
                }
                samples[i] = mixed
            }
            return HitSoundPcm(samples, targetFrames.toLong())
        } finally {
            sampler.close()
        }
    }

    private fun decodeAudioFileToPcm(sourceFile: File, targetPcmFile: File): DecodedPcm {
        val extractor = MediaExtractor()
        var decoder: MediaCodec? = null
        try {
            extractor.setDataSource(sourceFile.absolutePath)
            val trackIndex = (0 until extractor.trackCount).firstOrNull { index ->
                extractor.getTrackFormat(index)
                    .getString(MediaFormat.KEY_MIME)
                    ?.startsWith("audio/") == true
            } ?: error("No audio track was found in ${sourceFile.name}.")
            extractor.selectTrack(trackIndex)
            val inputFormat = extractor.getTrackFormat(trackIndex)
            val mime = inputFormat.getString(MediaFormat.KEY_MIME)
                ?: error("Audio track has no MIME type in ${sourceFile.name}.")
            if (android.os.Build.VERSION.SDK_INT >= 24) {
                inputFormat.setInteger(MediaFormat.KEY_PCM_ENCODING, AudioFormat.ENCODING_PCM_16BIT)
            }
            val activeDecoder = MediaCodec.createDecoderByType(mime)
            decoder = activeDecoder
            activeDecoder.configure(inputFormat, null, null, 0)
            activeDecoder.start()

            var sampleRate = inputFormat.integerOrNull(MediaFormat.KEY_SAMPLE_RATE) ?: 48000
            var channels = inputFormat.integerOrNull(MediaFormat.KEY_CHANNEL_COUNT) ?: 2
            var pcmEncoding = AudioFormat.ENCODING_PCM_16BIT
            var inputDone = false
            var outputDone = false
            var bytesWritten = 0L
            val info = MediaCodec.BufferInfo()

            FileOutputStream(targetPcmFile).buffered(64 * 1024).use { output ->
                while (!outputDone) {
                    checkCancelled()
                    if (!inputDone) {
                        val inputIndex = activeDecoder.dequeueInputBuffer(10_000)
                        if (inputIndex >= 0) {
                            val input = activeDecoder.getInputBuffer(inputIndex)
                                ?: error("Audio decoder returned a null input buffer.")
                            val size = extractor.readSampleData(input, 0)
                            if (size < 0) {
                                activeDecoder.queueInputBuffer(
                                    inputIndex,
                                    0,
                                    0,
                                    0,
                                    MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                                )
                                inputDone = true
                            } else {
                                activeDecoder.queueInputBuffer(
                                    inputIndex,
                                    0,
                                    size,
                                    extractor.sampleTime,
                                    0,
                                )
                                extractor.advance()
                            }
                        }
                    }

                    when (val outputIndex = activeDecoder.dequeueOutputBuffer(info, 10_000)) {
                        MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                            val format = activeDecoder.outputFormat
                            sampleRate = format.integerOrNull(MediaFormat.KEY_SAMPLE_RATE) ?: sampleRate
                            channels = format.integerOrNull(MediaFormat.KEY_CHANNEL_COUNT) ?: channels
                            pcmEncoding = format.integerOrNull(MediaFormat.KEY_PCM_ENCODING)
                                ?: AudioFormat.ENCODING_PCM_16BIT
                        }
                        in 0..Int.MAX_VALUE -> {
                            val data = activeDecoder.getOutputBuffer(outputIndex)
                                ?: error("Audio decoder returned a null output buffer.")
                            if (info.size > 0) {
                                data.position(info.offset)
                                data.limit(info.offset + info.size)
                                if (pcmEncoding == AudioFormat.ENCODING_PCM_FLOAT) {
                                    data.order(ByteOrder.nativeOrder())
                                    val floatData = data.asFloatBuffer()
                                    val converted = ByteBuffer.allocate(floatData.remaining() * 2)
                                        .order(ByteOrder.LITTLE_ENDIAN)
                                    while (floatData.hasRemaining()) {
                                        val sample = (floatData.get().coerceIn(-1f, 1f) * 32767f).toInt()
                                        converted.putShort(sample.toShort())
                                    }
                                    output.write(converted.array(), 0, converted.position())
                                    bytesWritten += converted.position()
                                } else {
                                    require(pcmEncoding == AudioFormat.ENCODING_PCM_16BIT) {
                                        "Unsupported decoded PCM encoding: $pcmEncoding"
                                    }
                                    val bytes = ByteArray(info.size)
                                    data.get(bytes)
                                    output.write(bytes)
                                    bytesWritten += bytes.size
                                }
                            }
                            outputDone = info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                            activeDecoder.releaseOutputBuffer(outputIndex, false)
                        }
                    }
                }
            }
            return DecodedPcm(
                file = targetPcmFile,
                sampleRate = sampleRate,
                channels = channels,
                frameCount = bytesWritten / (channels * 2),
            )
        } finally {
            runCatching { decoder?.stop() }
            runCatching { decoder?.release() }
            extractor.release()
        }
    }

    private fun encodeMixedAac(
        decoded: DecodedPcm,
        hitSound: HitSoundPcm?,
        judgeBank: Map<String, HitSoundPcm>,
        durationUs: Long,
        timelineStartUs: Long,
        musicOffsetUs: Long,
        musicVolume: Float,
        hitSoundVolume: Float,
        hitEventTimesUs: List<Long>,
        judgementEvents: List<JudgementSoundEvent>,
    ) {
        val outputFrames = ceil(durationUs * OUTPUT_SAMPLE_RATE / 1_000_000.0).toLong()
        val musicStartSeconds = (musicOffsetUs - timelineStartUs) / 1_000_000.0
        val hitStarts = hitEventTimesUs.map {
            ((it - timelineStartUs) * OUTPUT_SAMPLE_RATE / 1_000_000.0).roundToLong()
        }.sorted()
        val preparedJudgeEvents = judgementEvents.mapNotNull { event ->
            val pcm = judgeBank[event.kind] ?: return@mapNotNull null
            val volume = event.volume.coerceIn(0f, 3f)
            if (volume <= 0f) return@mapNotNull null
            PreparedJudgementEvent(
                startFrame = ((event.timeUs - timelineStartUs) * OUTPUT_SAMPLE_RATE / 1_000_000.0).roundToLong(),
                pcm = pcm,
                volume = volume,
            )
        }.sortedBy { it.startFrame }
        val mixer = PcmMixer(
            decoded = decoded,
            hitSound = hitSound,
            musicStartSeconds = musicStartSeconds,
            musicVolume = musicVolume,
            hitSoundVolume = hitSoundVolume,
            hitStarts = hitStarts,
            judgeEvents = preparedJudgeEvents,
        )

        var encoder: MediaCodec? = null
        var encoderStarted = false
        var muxer: MediaMuxer? = null
        var muxerStarted = false

        try {
            val format = MediaFormat.createAudioFormat(
                MediaFormat.MIMETYPE_AUDIO_AAC,
                OUTPUT_SAMPLE_RATE,
                OUTPUT_CHANNELS,
            ).apply {
                setInteger(
                    MediaFormat.KEY_AAC_PROFILE,
                    MediaCodecInfo.CodecProfileLevel.AACObjectLC,
                )
                setInteger(MediaFormat.KEY_BIT_RATE, 192_000)
                setInteger(MediaFormat.KEY_MAX_INPUT_SIZE, 16 * 1024)
            }
            val activeEncoder = MediaCodec.createEncoderByType(MediaFormat.MIMETYPE_AUDIO_AAC)
            encoder = activeEncoder
            activeEncoder.configure(format, null, null, MediaCodec.CONFIGURE_FLAG_ENCODE)
            activeEncoder.start()
            encoderStarted = true
            val activeMuxer = MediaMuxer(
                encodedAudioFile.absolutePath,
                MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4,
            )
            muxer = activeMuxer
            val info = MediaCodec.BufferInfo()
            var trackIndex = -1
            var inputFrame = 0L
            var inputDone = false
            var outputDone = false
            while (!outputDone) {
                checkCancelled()
                if (!inputDone) {
                    val inputIndex = activeEncoder.dequeueInputBuffer(10_000)
                    if (inputIndex >= 0) {
                        val input = activeEncoder.getInputBuffer(inputIndex)
                            ?: error("AAC encoder returned a null input buffer.")
                        input.clear()
                        input.order(ByteOrder.LITTLE_ENDIAN)
                        if (inputFrame >= outputFrames) {
                            activeEncoder.queueInputBuffer(
                                inputIndex,
                                0,
                                0,
                                inputFrame * 1_000_000 / OUTPUT_SAMPLE_RATE,
                                MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                            )
                            inputDone = true
                        } else {
                            val capacityFrames = input.capacity() / (OUTPUT_CHANNELS * 2)
                            val frames = min(capacityFrames.toLong(), outputFrames - inputFrame).toInt()
                            mixer.write(input, inputFrame, frames)
                            activeEncoder.queueInputBuffer(
                                inputIndex,
                                0,
                                frames * OUTPUT_CHANNELS * 2,
                                inputFrame * 1_000_000 / OUTPUT_SAMPLE_RATE,
                                0,
                            )
                            inputFrame += frames
                        }
                    }
                }

                when (val outputIndex = activeEncoder.dequeueOutputBuffer(info, 10_000)) {
                    MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                        trackIndex = activeMuxer.addTrack(activeEncoder.outputFormat)
                        activeMuxer.start()
                        muxerStarted = true
                    }
                    in 0..Int.MAX_VALUE -> {
                        val output = activeEncoder.getOutputBuffer(outputIndex)
                            ?: error("AAC encoder returned a null output buffer.")
                        if (info.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                            info.size = 0
                        }
                        if (info.size > 0) {
                            check(muxerStarted)
                            output.position(info.offset)
                            output.limit(info.offset + info.size)
                            activeMuxer.writeSampleData(trackIndex, output, info)
                        }
                        outputDone = info.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                        activeEncoder.releaseOutputBuffer(outputIndex, false)
                    }
                }
            }
        } finally {
            mixer.close()
            if (encoderStarted) runCatching { encoder?.stop() }
            runCatching { encoder?.release() }
            if (muxerStarted) runCatching { muxer?.stop() }
            runCatching { muxer?.release() }
        }
    }

    private fun muxTracks(video: File, audio: File, output: File) {
        if (output.exists()) output.delete()
        output.parentFile?.mkdirs()
        val videoExtractor = MediaExtractor()
        val audioExtractor = MediaExtractor()
        var muxer: MediaMuxer? = null
        var muxerStarted = false
        try {
            videoExtractor.setDataSource(video.absolutePath)
            audioExtractor.setDataSource(audio.absolutePath)
            val videoTrack = findTrack(videoExtractor, "video/")
            val audioTrack = findTrack(audioExtractor, "audio/")
            val activeMuxer = MediaMuxer(
                output.absolutePath,
                MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4,
            )
            muxer = activeMuxer
            val outputVideoTrack = activeMuxer.addTrack(videoExtractor.getTrackFormat(videoTrack))
            val outputAudioTrack = activeMuxer.addTrack(audioExtractor.getTrackFormat(audioTrack))
            activeMuxer.start()
            muxerStarted = true
            copyTrack(videoExtractor, videoTrack, activeMuxer, outputVideoTrack)
            copyTrack(audioExtractor, audioTrack, activeMuxer, outputAudioTrack)
        } finally {
            if (muxerStarted) runCatching { muxer?.stop() }
            runCatching { muxer?.release() }
            videoExtractor.release()
            audioExtractor.release()
        }
    }

    private fun copyTrack(
        extractor: MediaExtractor,
        track: Int,
        muxer: MediaMuxer,
        outputTrack: Int,
    ) {
        extractor.selectTrack(track)
        val format = extractor.getTrackFormat(track)
        val reportedMax = format.integerOrNull(MediaFormat.KEY_MAX_INPUT_SIZE) ?: 0
        val bufferSize = max(8 * 1024 * 1024, reportedMax).coerceAtMost(32 * 1024 * 1024)
        val buffer = ByteBuffer.allocateDirect(bufferSize)
        val info = MediaCodec.BufferInfo()
        while (true) {
            checkCancelled()
            buffer.clear()
            val size = extractor.readSampleData(buffer, 0)
            if (size < 0) break
            info.set(0, size, extractor.sampleTime, extractor.sampleFlags)
            muxer.writeSampleData(outputTrack, buffer, info)
            extractor.advance()
        }
        extractor.unselectTrack(track)
    }

    private fun findTrack(extractor: MediaExtractor, prefix: String): Int =
        (0 until extractor.trackCount).firstOrNull { index ->
            extractor.getTrackFormat(index).getString(MediaFormat.KEY_MIME)?.startsWith(prefix) == true
        } ?: error("Missing $prefix track.")

    private fun checkCancelled() {
        if (isCancelled()) throw ExportCancelledException()
    }

    companion object {
        private const val OUTPUT_SAMPLE_RATE = 48_000
        private const val OUTPUT_CHANNELS = 2
        private const val MAX_HIT_SOUND_FRAMES = 5L * OUTPUT_SAMPLE_RATE
    }
}

private class HitSoundPcm(val samples: FloatArray, val frameCount: Long)

private data class DecodedPcm(
    val file: File,
    val sampleRate: Int,
    val channels: Int,
    val frameCount: Long,
)

private class PreparedJudgementEvent(
    val startFrame: Long,
    val pcm: HitSoundPcm,
    val volume: Float,
)

private class PcmMixer(
    decoded: DecodedPcm,
    private val hitSound: HitSoundPcm?,
    private val musicStartSeconds: Double,
    private val musicVolume: Float,
    private val hitSoundVolume: Float,
    private val hitStarts: List<Long>,
    private val judgeEvents: List<PreparedJudgementEvent>,
) {
    private val music = PcmFileSampler(decoded)
    private val judgeStarts: List<Long> = judgeEvents.map { it.startFrame }
    private val maxJudgeFrames: Long = judgeEvents.maxOfOrNull { it.pcm.frameCount } ?: 0L

    fun write(output: ByteBuffer, outputStartFrame: Long, frameCount: Int) {
        val samples = FloatArray(frameCount * 2)
        for (frame in 0 until frameCount) {
            val outputFrame = outputStartFrame + frame
            val musicSeconds = outputFrame / 48_000.0 - musicStartSeconds
            if (musicSeconds >= 0) {
                val sourceFrame = musicSeconds * music.sampleRate
                samples[frame * 2] += music.sample(sourceFrame, 0) * musicVolume
                samples[frame * 2 + 1] += music.sample(sourceFrame, 1) * musicVolume
            }
        }
        val chunkEnd = outputStartFrame + frameCount
        val hit = hitSound
        if (hit != null && hitStarts.isNotEmpty()) {
            val first = lowerBound(hitStarts, outputStartFrame - hit.frameCount)
            var index = first
            while (index < hitStarts.size && hitStarts[index] < chunkEnd) {
                val start = hitStarts[index]
                val from = max(outputStartFrame, start)
                val to = min(chunkEnd, start + hit.frameCount)
                val overlap = max(
                    1,
                    upperBound(hitStarts, start) - lowerBound(hitStarts, start - hit.frameCount + 1),
                )
                val gain = (hitSoundVolume.toDouble() / sqrt(overlap.toDouble())).toFloat()
                for (outputFrame in from until to) {
                    val hitFrame = (outputFrame - start).toInt()
                    val value = hit.samples[hitFrame] * gain
                    val local = (outputFrame - outputStartFrame).toInt() * 2
                    samples[local] += value
                    samples[local + 1] += value
                }
                index++
            }
        }
        if (judgeEvents.isNotEmpty()) {
            val first = lowerBound(judgeStarts, outputStartFrame - maxJudgeFrames)
            var index = first
            while (index < judgeEvents.size && judgeEvents[index].startFrame < chunkEnd) {
                val event = judgeEvents[index]
                val start = event.startFrame
                val end = start + event.pcm.frameCount
                if (end > outputStartFrame) {
                    val from = max(outputStartFrame, start)
                    val to = min(chunkEnd, end)
                    val overlap = max(
                        1,
                        upperBound(judgeStarts, start) -
                            lowerBound(judgeStarts, start - JUDGE_OVERLAP_WINDOW_FRAMES + 1),
                    )
                    val gain = (event.volume.toDouble() * 0.82 / sqrt(overlap.toDouble())).toFloat()
                    val pcmSamples = event.pcm.samples
                    for (outputFrame in from until to) {
                        val sfxFrame = (outputFrame - start).toInt()
                        val value = pcmSamples[sfxFrame] * gain
                        val local = (outputFrame - outputStartFrame).toInt() * 2
                        samples[local] += value
                        samples[local + 1] += value
                    }
                }
                index++
            }
        }
        samples.forEach { sample ->
            output.putShort((sample.coerceIn(-1f, 1f) * 32767f).toInt().toShort())
        }
    }

    fun close() = music.close()

    companion object {
        // 与 SimaiJudgementSoundBank._overlapWindowUs (80ms) 对齐。
        private const val JUDGE_OVERLAP_WINDOW_FRAMES = 3840L
    }
}

private class PcmFileSampler(decoded: DecodedPcm) {
    val sampleRate = decoded.sampleRate
    private val channels = decoded.channels
    private val frameCount = decoded.frameCount
    private val file = RandomAccessFile(decoded.file, "r")
    private var cacheStart = -1L
    private var cacheFrames = 0
    private var cache = ShortArray(0)

    fun sample(frame: Double, outputChannel: Int): Float {
        if (frame < 0 || frame >= frameCount) return 0f
        val first = floor(frame).toLong()
        val fraction = (frame - first).toFloat()
        val a = sampleAt(first, outputChannel)
        val b = sampleAt(min(first + 1, frameCount - 1), outputChannel)
        return a + (b - a) * fraction
    }

    private fun sampleAt(frame: Long, outputChannel: Int): Float {
        ensureCached(frame)
        val localFrame = (frame - cacheStart).toInt()
        val channel = if (channels == 1) 0 else outputChannel.coerceAtMost(channels - 1)
        return cache[localFrame * channels + channel] / 32768f
    }

    private fun ensureCached(frame: Long) {
        if (frame >= cacheStart && frame < cacheStart + cacheFrames) return
        cacheStart = frame / CACHE_FRAMES * CACHE_FRAMES
        cacheFrames = min(CACHE_FRAMES.toLong(), frameCount - cacheStart).toInt()
        val byteCount = cacheFrames * channels * 2
        val bytes = ByteArray(byteCount)
        file.seek(cacheStart * channels * 2)
        val read = file.read(bytes)
        val actualSamples = max(0, read) / 2
        cache = ShortArray(cacheFrames * channels)
        ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN).asShortBuffer()
            .get(cache, 0, min(actualSamples, cache.size))
    }

    fun close() = file.close()

    companion object {
        private const val CACHE_FRAMES = 8192
    }
}

private object WavPcm16 {
    fun tryReadMono48k(file: File, maxFrames: Long): HitSoundPcm? = runCatching {
        val bytes = file.readBytes()
        if (bytes.size < 44 || String(bytes, 0, 4) != "RIFF" || String(bytes, 8, 4) != "WAVE") {
            return@runCatching null
        }
        var offset = 12
        var format = 0
        var channels = 0
        var sampleRate = 0
        var bitDepth = 0
        var dataOffset = -1
        var dataSize = 0
        val buffer = ByteBuffer.wrap(bytes).order(ByteOrder.LITTLE_ENDIAN)
        while (offset + 8 <= bytes.size) {
            val id = String(bytes, offset, 4)
            val size = buffer.getInt(offset + 4)
            if (id == "fmt ") {
                format = buffer.getShort(offset + 8).toInt()
                channels = buffer.getShort(offset + 10).toInt()
                sampleRate = buffer.getInt(offset + 12)
                bitDepth = buffer.getShort(offset + 22).toInt()
            } else if (id == "data") {
                dataOffset = offset + 8
                dataSize = min(size, bytes.size - dataOffset)
                break
            }
            offset += 8 + size + (size and 1)
        }
        if (format != 1 || (channels != 1 && channels != 2) || sampleRate <= 0 || bitDepth != 16 || dataOffset < 0) {
            return@runCatching null
        }
        val rawSamples = ShortArray(dataSize / 2)
        ByteBuffer.wrap(bytes, dataOffset, dataSize).order(ByteOrder.LITTLE_ENDIAN)
            .asShortBuffer().get(rawSamples)
        val sourceFrames = rawSamples.size / channels
        if (sourceFrames <= 0) return@runCatching null
        if (sampleRate == 48_000) {
            val cappedCount = min(sourceFrames.toLong(), maxFrames).toInt()
            val samples = FloatArray(cappedCount) { i ->
                if (channels == 1) {
                    rawSamples[i] / 32768f
                } else {
                    (rawSamples[i * 2] + rawSamples[i * 2 + 1]) / 65536f
                }
            }
            return@runCatching HitSoundPcm(samples, cappedCount.toLong())
        }
        val targetFrames = ceil(sourceFrames * 48_000.0 / sampleRate)
            .toLong()
            .coerceIn(1L, maxFrames)
            .toInt()
        val rateRatio = sampleRate.toDouble() / 48_000.0
        fun monoAt(frameIdx: Int): Float {
            val safe = frameIdx.coerceIn(0, sourceFrames - 1)
            return if (channels == 1) {
                rawSamples[safe] / 32768f
            } else {
                (rawSamples[safe * 2] + rawSamples[safe * 2 + 1]) / 65536f
            }
        }
        val samples = FloatArray(targetFrames) { i ->
            val pos = i * rateRatio
            val idx0 = floor(pos).toInt()
            val frac = (pos - idx0).toFloat()
            val a = monoAt(idx0)
            val b = monoAt(idx0 + 1)
            a + (b - a) * frac
        }
        HitSoundPcm(samples, targetFrames.toLong())
    }.getOrNull()
}

private fun MediaFormat.integerOrNull(key: String): Int? =
    if (containsKey(key)) getInteger(key) else null

private fun lowerBound(values: List<Long>, target: Long): Int {
    var low = 0
    var high = values.size
    while (low < high) {
        val middle = (low + high) ushr 1
        if (values[middle] < target) low = middle + 1 else high = middle
    }
    return low
}

private fun upperBound(values: List<Long>, target: Long): Int {
    var low = 0
    var high = values.size
    while (low < high) {
        val middle = (low + high) ushr 1
        if (values[middle] <= target) low = middle + 1 else high = middle
    }
    return low
}

private fun Double.roundToLong(): Long = kotlin.math.round(this).toLong()
