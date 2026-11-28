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
import java.util.concurrent.ExecutionException
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

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
    private val hitSoundFilePath: String? = null,
    private val judgementSoundAssetKeys: Map<String, String> = emptyMap(),
    private val judgementSoundFilePaths: Map<String, String> = emptyMap(),
    private val audioMode: String,
    private val pvVideoPath: String? = null,
    private val pvRect: IntArray? = null,
    val saveToGallery: Boolean = false,
    val displayName: String? = null,
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
    var hitSoundDurationUs: Long = 100_000L
        private set

    private val workingDirectory = File(context.cacheDir, "simai_video_${id}")
    private val videoOnlyFile = File(workingDirectory, "video.mp4")
    private val finalMuxedFile = File(workingDirectory, "final.mp4")
    private var materializedAudioFile: File? = null
    private var materializedHitSoundFile: File? = null
    private var encoder: HardwareVideoEncoder? = null
    // 固定单线程驱动 EGL 与硬编生命周期，避免 Flutter 后台任务队列在系统中断（如下拉通知栏）后切换工作线程触发 EGL_BAD_ACCESS。
    private val encoderExecutor: ExecutorService = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "SimaiVideoEncoder-$id").apply { isDaemon = true }
    }
    @Volatile private var cancelled = false

    private fun <T> runOnEncoderThread(block: () -> T): T {
        if (encoderExecutor.isShutdown) {
            throw ExportCancelledException()
        }
        try {
            return encoderExecutor.submit<T>(block).get()
        } catch (error: ExecutionException) {
            throw error.cause ?: error
        } catch (_: InterruptedException) {
            Thread.currentThread().interrupt()
            throw ExportCancelledException()
        }
    }

    fun start() {
        require(audioMode in setOf("musicAndHitSounds", "musicOnly", "silent")) {
            "Unsupported audio mode: $audioMode"
        }
        if (!saveToGallery) {
            outputFile.parentFile?.mkdirs()
        }
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
            if (audioMode == "musicAndHitSounds") {
                val resolvedHitFile = hitSoundFilePath
                    ?.let(::File)
                    ?.takeIf { it.isFile }
                    ?: copyAsset(hitAssetKey, "answer.wav")
                materializedHitSoundFile = resolvedHitFile
                hitSoundDurationUs = runCatching { probeAudioDurationUs(resolvedHitFile) }
                    .getOrDefault(100_000L)
                    .coerceIn(50_000L, 5_000_000L)
            }
        }
        if (pvVideoPath != null) {
            require(pvRect != null && pvRect.size == 4 && pvRect[2] > 0 && pvRect[3] > 0) {
                "启用 PV 背景导出时必须提供有效的 pvRect。"
            }
        }
        runOnEncoderThread {
            encoder = HardwareVideoEncoder(
                width = width,
                height = height,
                fps = fps,
                bitrate = videoBitrate,
                codecName = videoCodecName,
                outputFile = videoOnlyFile,
                pvVideoPath = pvVideoPath,
                pvRect = pvRect,
            ).also { it.start() }
        }
    }

    fun submitFrame(slot: Int, presentationTimeUs: Long, pvTimeUs: Long? = null) {
        checkCancelled()
        require(slot in frameBuffers.indices) { "Invalid frame buffer slot $slot" }
        runOnEncoderThread {
            checkCancelled()
            encoder?.submit(frameBuffers[slot], presentationTimeUs, pvTimeUs)
                ?: error("Video encoder is not running.")
        }
    }

    fun finish(
        durationUs: Long,
        timelineStartUs: Long,
        musicOffsetUs: Long,
        musicVolume: Double,
        hitSoundVolume: Double = 2.0,
        hitEventTimesUs: List<Long>,
        judgementEvents: List<JudgementSoundEvent> = emptyList(),
        directGallerySaver: ((File) -> String?)? = null,
    ): FinishOutcome {
        try {
            checkCancelled()
            ensureDiskSpace(durationUs)
            runOnEncoderThread {
                encoder?.finish()
                encoder = null
            }
            checkCancelled()
            val producedFile = if (audioMode == "silent") {
                videoOnlyFile
            } else {
                val hitFile = if (audioMode == "musicAndHitSounds" && hitEventTimesUs.isNotEmpty()) {
                    materializedHitSoundFile ?: copyAsset(hitAssetKey, "answer.wav")
                } else {
                    null
                }
                val judgementFiles = if (audioMode == "musicAndHitSounds" && judgementEvents.isNotEmpty()) {
                    val neededKinds = judgementEvents.asSequence().map { it.kind }.toSet()
                    buildMap<String, File> {
                        for (kind in neededKinds) {
                            val custom = judgementSoundFilePaths[kind]?.let(::File)?.takeIf { it.isFile }
                            val resolved = custom ?: judgementSoundAssetKeys[kind]?.let { assetKey ->
                                copyAsset(assetKey, "judge_$kind.wav")
                            }
                            if (resolved != null && resolved.isFile) {
                                put(kind, resolved)
                            }
                        }
                    }
                } else {
                    emptyMap()
                }
                AndroidAudioComposer(
                    musicFile = materializedAudioFile!!,
                    hitSoundFile = hitFile,
                    judgementSoundFiles = judgementFiles,
                    videoFile = videoOnlyFile,
                    outputFile = finalMuxedFile,
                    workingDirectory = workingDirectory,
                    isCancelled = { cancelled },
                ).compose(
                    durationUs = durationUs,
                    timelineStartUs = timelineStartUs,
                    musicOffsetUs = musicOffsetUs,
                    musicVolume = musicVolume.toFloat().coerceIn(0f, 1f),
                    hitSoundVolume = hitSoundVolume.toFloat().coerceIn(0f, 3f),
                    hitEventTimesUs = hitEventTimesUs,
                    judgementEvents = judgementEvents,
                )
                checkCancelled()
                finalMuxedFile
            }
            val fileSize = producedFile.length()
            if (saveToGallery && directGallerySaver != null) {
                val galleryUri = directGallerySaver(producedFile)
                if (!galleryUri.isNullOrBlank()) {
                    cleanupWorkingFiles(keepOutput = false)
                    return FinishOutcome(
                        outputPath = galleryUri,
                        fileSizeBytes = fileSize,
                        savedToGallery = true,
                        galleryUri = galleryUri,
                    )
                }
            }
            moveReplacing(producedFile, outputFile)
            cleanupWorkingFiles(keepOutput = true)
            return FinishOutcome(
                outputPath = outputFile.absolutePath,
                fileSizeBytes = outputFile.length(),
                savedToGallery = false,
                galleryUri = null,
            )
        } finally {
            encoderExecutor.shutdown()
        }
    }

    fun cancel() {
        cancelled = true
        if (!encoderExecutor.isShutdown) {
            runCatching {
                runOnEncoderThread {
                    encoder?.cancel()
                    encoder = null
                }
            }
            encoderExecutor.shutdown()
        } else {
            runCatching { encoder?.cancel() }
            encoder = null
        }
        cleanupWorkingFiles(keepOutput = false)
    }

    internal data class FinishOutcome(
        val outputPath: String,
        val fileSizeBytes: Long,
        val savedToGallery: Boolean,
        val galleryUri: String?,
    )

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
        if (saveToGallery) {
            return
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
