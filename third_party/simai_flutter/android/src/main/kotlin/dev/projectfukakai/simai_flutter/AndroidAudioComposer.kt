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

internal class AndroidAudioComposer(
    private val musicFile: File,
    private val hitSoundFile: File?,
    private val videoFile: File,
    private val outputFile: File,
    private val workingDirectory: File,
    private val isCancelled: () -> Boolean,
) {
    private val decodedPcmFile = File(workingDirectory, "music.pcm")
    private val encodedAudioFile = File(workingDirectory, "audio.m4a")

    fun compose(
        durationUs: Long,
        timelineStartUs: Long,
        musicOffsetUs: Long,
        musicVolume: Float,
        hitEventTimesUs: List<Long>,
    ) {
        checkCancelled()
        val decoded = decodeMusicToPcm()
        val hitSound = hitSoundFile?.let(WavPcm16::read)
        encodeMixedAac(
            decoded = decoded,
            hitSound = hitSound,
            durationUs = durationUs,
            timelineStartUs = timelineStartUs,
            musicOffsetUs = musicOffsetUs,
            musicVolume = musicVolume,
            hitEventTimesUs = hitEventTimesUs,
        )
        checkCancelled()
        muxTracks(videoFile, encodedAudioFile, outputFile)
    }

    private fun decodeMusicToPcm(): DecodedPcm {
        val extractor = MediaExtractor()
        var decoder: MediaCodec? = null
        try {
            extractor.setDataSource(musicFile.absolutePath)
            val trackIndex = (0 until extractor.trackCount).firstOrNull { index ->
                extractor.getTrackFormat(index)
                    .getString(MediaFormat.KEY_MIME)
                    ?.startsWith("audio/") == true
            } ?: error("No audio track was found in ${musicFile.name}.")
            extractor.selectTrack(trackIndex)
            val inputFormat = extractor.getTrackFormat(trackIndex)
            val mime = inputFormat.getString(MediaFormat.KEY_MIME)
                ?: error("Music track has no MIME type.")
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

            FileOutputStream(decodedPcmFile).buffered(64 * 1024).use { output ->
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
                file = decodedPcmFile,
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
        hitSound: WavPcm16?,
        durationUs: Long,
        timelineStartUs: Long,
        musicOffsetUs: Long,
        musicVolume: Float,
        hitEventTimesUs: List<Long>,
    ) {
        val outputFrames = ceil(durationUs * OUTPUT_SAMPLE_RATE / 1_000_000.0).toLong()
        val musicStartSeconds = (musicOffsetUs - timelineStartUs) / 1_000_000.0
        val hitStarts = hitEventTimesUs.map {
            ((it - timelineStartUs) * OUTPUT_SAMPLE_RATE / 1_000_000.0).roundToLong()
        }.sorted()
        val mixer = PcmMixer(
            decoded = decoded,
            hitSound = hitSound,
            musicStartSeconds = musicStartSeconds,
            musicVolume = musicVolume,
            hitStarts = hitStarts,
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
    }
}

private data class DecodedPcm(
    val file: File,
    val sampleRate: Int,
    val channels: Int,
    val frameCount: Long,
)

private class PcmMixer(
    decoded: DecodedPcm,
    private val hitSound: WavPcm16?,
    private val musicStartSeconds: Double,
    private val musicVolume: Float,
    private val hitStarts: List<Long>,
) {
    private val music = PcmFileSampler(decoded)

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
        val hit = hitSound
        if (hit != null) {
            val chunkEnd = outputStartFrame + frameCount
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
                val gain = (0.72 / sqrt(overlap.toDouble())).toFloat()
                for (outputFrame in from until to) {
                    val hitFrame = (outputFrame - start).toInt()
                    val value = hit.samples[hitFrame] / 32768f * gain
                    val local = (outputFrame - outputStartFrame).toInt() * 2
                    samples[local] += value
                    samples[local + 1] += value
                }
                index++
            }
        }
        samples.forEach { sample ->
            output.putShort((sample.coerceIn(-1f, 1f) * 32767f).toInt().toShort())
        }
    }

    fun close() = music.close()
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

private data class WavPcm16(val samples: ShortArray, val frameCount: Long) {
    companion object {
        fun read(file: File): WavPcm16 {
            val bytes = file.readBytes()
            require(bytes.size >= 44 && String(bytes, 0, 4) == "RIFF" && String(bytes, 8, 4) == "WAVE") {
                "Unsupported hit sound WAV file."
            }
            var offset = 12
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
                    val format = buffer.getShort(offset + 8).toInt()
                    channels = buffer.getShort(offset + 10).toInt()
                    sampleRate = buffer.getInt(offset + 12)
                    bitDepth = buffer.getShort(offset + 22).toInt()
                    require(format == 1) { "Hit sound must use PCM WAV." }
                } else if (id == "data") {
                    dataOffset = offset + 8
                    dataSize = min(size, bytes.size - dataOffset)
                    break
                }
                offset += 8 + size + (size and 1)
            }
            require(channels == 1 && sampleRate == 48_000 && bitDepth == 16 && dataOffset >= 0) {
                "Hit sound must be mono 48kHz PCM16 WAV."
            }
            val samples = ShortArray(dataSize / 2)
            ByteBuffer.wrap(bytes, dataOffset, dataSize).order(ByteOrder.LITTLE_ENDIAN)
                .asShortBuffer().get(samples)
            return WavPcm16(samples, samples.size.toLong())
        }
    }
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
