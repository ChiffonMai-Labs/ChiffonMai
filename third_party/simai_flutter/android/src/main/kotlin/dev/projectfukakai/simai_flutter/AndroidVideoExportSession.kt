package dev.projectfukakai.simai_flutter

import android.content.Context
import android.media.MediaExtractor
import android.media.MediaFormat
import android.os.StatFs
import android.system.Os
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.util.UUID

internal class AndroidVideoExportSession(
    val id: Int,
    private val context: Context,
    private val width: Int,
    private val height: Int,
    private val fps: Int,
    private val videoBitrate: Int,
    private val videoCodecName: String,
    requestedOutputPath: String?,
    private val audioAssetKey: String?,
    private val audioFilePath: String?,
    private val hitAssetKey: String,
    private val audioMode: String,
) {
    val frameByteCount: Int = Math.multiplyExact(Math.multiplyExact(width, height), 4)
    val frameBuffers: List<ByteBuffer> = List(2) {
        ByteBuffer.allocateDirect(frameByteCount).order(ByteOrder.nativeOrder())
    }
    val outputFile: File = requestedOutputPath?.let { path ->
        require(path.isNotBlank() && File(path).isAbsolute) {
            "The output path must be an absolute file path."
        }
        File(path)
    } ?: defaultOutputFile()
    var audioDurationUs: Long = 0
        private set

    private val workingDirectory = File(context.cacheDir, "simai_video_${id}")
    private val videoOnlyFile = File(workingDirectory, "video.mp4")
    private val finalMuxedFile = File(workingDirectory, "final.mp4")
    private var materializedAudioFile: File? = null
    private var encoder: HardwareVideoEncoder? = null
    @Volatile private var cancelled = false

    fun start() {
        require(audioMode in setOf("musicAndHitSounds", "musicOnly", "silent")) {
            "Unsupported audio mode: $audioMode"
        }
        outputFile.parentFile?.mkdirs()
        workingDirectory.mkdirs()
        if (audioMode != "silent") {
            materializedAudioFile = when {
                audioFilePath != null -> File(audioFilePath)
                audioAssetKey != null -> copyAsset(audioAssetKey, "music_source")
                else -> null
            }
            val audio = materializedAudioFile
                ?: error("The selected audio mode requires a music source.")
            require(audio.isFile) { "Music source does not exist: ${audio.absolutePath}" }
            audioDurationUs = probeAudioDurationUs(audio)
        }
        encoder = HardwareVideoEncoder(
            width = width,
            height = height,
            fps = fps,
            bitrate = videoBitrate,
            codecName = videoCodecName,
            outputFile = videoOnlyFile,
        ).also { it.start() }
    }

    fun submitFrame(slot: Int, presentationTimeUs: Long) {
        checkCancelled()
        require(slot in frameBuffers.indices) { "Invalid frame buffer slot $slot" }
        encoder?.submit(frameBuffers[slot], presentationTimeUs)
            ?: error("Video encoder is not running.")
    }

    fun finish(
        durationUs: Long,
        timelineStartUs: Long,
        musicOffsetUs: Long,
        musicVolume: Double,
        hitEventTimesUs: List<Long>,
    ): File {
        checkCancelled()
        ensureDiskSpace(durationUs)
        encoder?.finish()
        encoder = null
        checkCancelled()
        if (audioMode == "silent") {
            moveReplacing(videoOnlyFile, outputFile)
        } else {
            val hitFile = if (audioMode == "musicAndHitSounds") {
                copyAsset(hitAssetKey, "answer.wav")
            } else {
                null
            }
            AndroidAudioComposer(
                musicFile = materializedAudioFile!!,
                hitSoundFile = hitFile,
                videoFile = videoOnlyFile,
                outputFile = finalMuxedFile,
                workingDirectory = workingDirectory,
                isCancelled = { cancelled },
            ).compose(
                durationUs = durationUs,
                timelineStartUs = timelineStartUs,
                musicOffsetUs = musicOffsetUs,
                musicVolume = musicVolume.toFloat().coerceIn(0f, 1f),
                hitEventTimesUs = hitEventTimesUs,
            )
            checkCancelled()
            moveReplacing(finalMuxedFile, outputFile)
        }
        cleanupWorkingFiles(keepOutput = true)
        return outputFile
    }

    fun cancel() {
        cancelled = true
        encoder?.cancel()
        encoder = null
        cleanupWorkingFiles(keepOutput = true)
    }

    private fun checkCancelled() {
        if (cancelled) throw ExportCancelledException()
    }

    private fun copyAsset(assetKey: String, name: String): File {
        val target = File(workingDirectory, name)
        context.assets.open(assetKey).use { input ->
            target.outputStream().buffered().use { output ->
                input.copyTo(output, 64 * 1024)
            }
        }
        return target
    }

    private fun probeAudioDurationUs(file: File): Long {
        val extractor = MediaExtractor()
        return try {
            extractor.setDataSource(file.absolutePath)
            val track = (0 until extractor.trackCount).firstOrNull { index ->
                extractor.getTrackFormat(index)
                    .getString(MediaFormat.KEY_MIME)
                    ?.startsWith("audio/") == true
            } ?: error("No audio track was found in ${file.name}.")
            val format = extractor.getTrackFormat(track)
            require(format.containsKey(MediaFormat.KEY_DURATION)) {
                "The music source has no valid audio duration."
            }
            format.getLong(MediaFormat.KEY_DURATION).also { duration ->
                require(duration > 0) { "The music source has no valid audio duration." }
            }
        } finally {
            extractor.release()
        }
    }

    fun ensureDiskSpace(durationUs: Long) {
        val durationSeconds = durationUs / 1_000_000.0
        val estimatedFinal = ((videoBitrate + 192_000) * durationSeconds / 8).toLong()
        val required = (estimatedFinal * 2.5).toLong() + 64L * 1024 * 1024
        val available = StatFs(workingDirectory.absolutePath).availableBytes
        require(available >= required) {
            "Insufficient storage: need approximately $required bytes, have $available bytes."
        }
        val outputDirectory = outputFile.parentFile
            ?: error("The output path has no parent directory.")
        outputDirectory.mkdirs()
        require(outputDirectory.isDirectory && outputDirectory.canWrite()) {
            "The output directory is not writable: ${outputDirectory.absolutePath}"
        }
        val outputRequired = estimatedFinal + 16L * 1024 * 1024
        val outputAvailable = StatFs(outputDirectory.absolutePath).availableBytes
        require(outputAvailable >= outputRequired) {
            "Insufficient output storage: need approximately $outputRequired bytes, have $outputAvailable bytes."
        }
    }

    private fun cleanupWorkingFiles(keepOutput: Boolean) {
        workingDirectory.walkBottomUp().forEach { file ->
            if (!keepOutput || file.absolutePath != outputFile.absolutePath) {
                runCatching { file.delete() }
            }
        }
    }

    private fun defaultOutputFile(): File {
        val directory = File(context.cacheDir, "simai_exports").apply { mkdirs() }
        return File(directory, "simai_${System.currentTimeMillis()}.mp4")
    }

    private fun moveReplacing(source: File, target: File) {
        val parent = target.parentFile ?: error("The output path has no parent directory.")
        parent.mkdirs()
        val staging = File(parent, ".${target.name}.${UUID.randomUUID()}.tmp")
        try {
            source.inputStream().use { input ->
                staging.outputStream().use { output -> input.copyTo(output, 64 * 1024) }
            }
            Os.rename(staging.absolutePath, target.absolutePath)
            source.delete()
        } finally {
            staging.delete()
        }
    }
}
