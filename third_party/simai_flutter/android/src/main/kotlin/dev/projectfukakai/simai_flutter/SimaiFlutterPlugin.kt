package dev.projectfukakai.simai_flutter

import android.Manifest
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaFormat
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.io.File
import java.io.IOException
import java.nio.ByteBuffer
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicInteger

class SimaiFlutterPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var flutterAssets: FlutterPlugin.FlutterAssets
    private val sessions = ConcurrentHashMap<Int, AndroidVideoExportSession>()
    private val nextSessionId = AtomicInteger(1)
    private val exportExecutor = Executors.newCachedThreadPool()

    companion object {
        private const val VIDEO_MIME_TYPE = "video/mp4"
        private const val SHARE_DIRECTORY = "simai_flutter_share"
        private const val SHARE_FILE_MAX_AGE_MS = 24L * 60L * 60L * 1000L

        init {
            System.loadLibrary("simai_video_export")
        }
    }

    private external fun nativeBufferAddress(buffer: ByteBuffer): Long

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        flutterAssets = binding.flutterAssets
        val taskQueue = binding.binaryMessenger.makeBackgroundTaskQueue()
        channel = MethodChannel(
            binding.binaryMessenger,
            "simai_flutter/video_export",
            StandardMethodCodec.INSTANCE,
            taskQueue,
        )
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        sessions.values.forEach { it.cancel() }
        sessions.clear()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            when (call.method) {
                "isSupported" -> {
                    val width = call.requireInt("width")
                    val height = call.requireInt("height")
                    val fps = call.requireInt("fps")
                    result.success(isHardwareAvcSupported(width, height, fps))
                }
                "start" -> start(call, result)
                "submitFrame" -> {
                    val session = requireSession(call.requireInt("sessionId"))
                    session.submitFrame(
                        slot = call.requireInt("slot"),
                        presentationTimeUs = call.requireLong("presentationTimeUs"),
                        pvTimeUs = call.argument<Number>("pvTimeUs")?.toLong(),
                    )
                    result.success(null)
                }
                "validateStorage" -> {
                    val session = requireSession(call.requireInt("sessionId"))
                    session.ensureDiskSpace(call.requireLong("durationUs"))
                    result.success(null)
                }
                "finish" -> finishAsync(call, result)
                "cancel" -> {
                    val id = call.requireInt("sessionId")
                    sessions.remove(id)?.cancel()
                    result.success(null)
                }
                "saveToGallery" -> result.success(
                    saveToGallery(call.requireString("path")),
                )
                "shareVideo" -> {
                    shareVideo(
                        path = call.requireString("path"),
                        text = call.argument("text"),
                    )
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (cancelled: ExportCancelledException) {
            result.error("cancelled", cancelled.message, null)
        } catch (error: PluginActionException) {
            result.error(error.code, error.message, null)
        } catch (error: Throwable) {
            result.error(
                error.javaClass.simpleName.ifEmpty { "native_error" },
                error.message ?: "Native video export failed.",
                null,
            )
        }
    }

    private fun start(call: MethodCall, result: MethodChannel.Result) {
        val width = call.requireInt("width")
        val height = call.requireInt("height")
        val fps = call.requireInt("fps")
        val codecInfo = findHardwareAvcEncoder(width, height, fps)
        if (codecInfo == null) {
            result.error("unsupported", "No hardware AVC encoder supports ${width}x$height@$fps.", null)
            return
        }
        if (sessions.isNotEmpty()) {
            result.error("busy", "Another video export is already running.", null)
            return
        }

        val id = nextSessionId.getAndIncrement()
        val audioAsset = call.argument<String>("audioAsset")
        val audioAssetKey = audioAsset?.let { flutterAssets.getAssetFilePathByName(it) }
        val hitAssetKey = flutterAssets.getAssetFilePathByName(
            "assets/answer.wav",
            "simai_flutter",
        )
        val hitSoundFilePath = call.argument<String>("hitSoundFilePath")?.takeIf { it.isNotBlank() }
        val judgementSoundAssetKeys = call.argument<Map<*, *>>("judgementSoundAssetPaths")
            ?.entries
            ?.mapNotNull { (k, v) ->
                val kind = k as? String
                val asset = (v as? String)?.takeIf { it.isNotBlank() }
                if (kind != null && asset != null) {
                    kind to flutterAssets.getAssetFilePathByName(asset, "simai_flutter")
                } else {
                    null
                }
            }
            ?.toMap()
            .orEmpty()
        val judgementSoundFilePaths = call.argument<Map<*, *>>("judgementSoundFilePaths")
            ?.entries
            ?.mapNotNull { (k, v) ->
                val kind = k as? String
                val path = (v as? String)?.takeIf { it.isNotBlank() }
                if (kind != null && path != null) kind to path else null
            }
            ?.toMap()
            .orEmpty()
        val pvVideoPath = call.argument<String>("pvVideoPath")?.takeIf { it.isNotBlank() }
        val pvRect = call.argument<List<Number>>("pvRect")?.map { it.toInt() }?.toIntArray()
        val saveToGallery = call.argument<Boolean>("saveToGallery") ?: false
        val displayName = call.argument<String>("displayName")?.takeIf { it.isNotBlank() }
        val session = AndroidVideoExportSession(
            id = id,
            context = context,
            width = width,
            height = height,
            fps = fps,
            videoBitrate = call.requireInt("videoBitrate"),
            videoCodecName = codecInfo.name,
            requestedOutputPath = call.argument("outputPath"),
            audioAssetKey = audioAssetKey,
            audioFilePath = call.argument("audioFilePath"),
            hitAssetKey = hitAssetKey,
            hitSoundFilePath = hitSoundFilePath,
            judgementSoundAssetKeys = judgementSoundAssetKeys,
            judgementSoundFilePaths = judgementSoundFilePaths,
            audioMode = call.requireString("audioMode"),
            pvVideoPath = pvVideoPath,
            pvRect = pvRect,
            saveToGallery = saveToGallery,
            displayName = displayName,
        )
        try {
            session.start()
        } catch (error: Throwable) {
            session.cancel()
            throw error
        }
        sessions[id] = session
        result.success(
            mapOf(
                "sessionId" to id,
                "bufferAddresses" to session.frameBuffers.map(::nativeBufferAddress),
                "bufferLength" to session.frameByteCount,
                "audioDurationUs" to session.audioDurationUs,
                "hitSoundDurationUs" to session.hitSoundDurationUs,
                "outputPath" to session.outputFile.absolutePath,
            ),
        )
    }

    private fun finishAsync(call: MethodCall, result: MethodChannel.Result) {
        val id = call.requireInt("sessionId")
        val session = requireSession(id)
        val durationUs = call.requireLong("durationUs")
        val timelineStartUs = call.requireLong("timelineStartUs")
        val musicOffsetUs = call.requireLong("musicOffsetUs")
        val musicVolume = call.requireDouble("musicVolume")
        val hitSoundVolume = call.argument<Number>("hitSoundVolume")?.toDouble() ?: 2.0
        val hitEvents = call.argument<List<Number>>("hitEventTimesUs")
            ?.map { it.toLong() }
            .orEmpty()
        val judgeTimes = call.argument<List<Number>>("judgementEventTimesUs")
            ?.map { it.toLong() }
            .orEmpty()
        val judgeKinds = call.argument<List<String>>("judgementEventKinds").orEmpty()
        val judgeVolumes = call.argument<List<Number>>("judgementEventVolumes")
            ?.map { it.toFloat() }
            .orEmpty()
        val judgeCount = minOf(judgeTimes.size, judgeKinds.size, judgeVolumes.size)
        val judgementEvents = List(judgeCount) { idx ->
            JudgementSoundEvent(
                timeUs = judgeTimes[idx],
                kind = judgeKinds[idx],
                volume = judgeVolumes[idx],
            )
        }
        exportExecutor.execute {
            var succeeded = false
            try {
                val outcome = session.finish(
                    durationUs = durationUs,
                    timelineStartUs = timelineStartUs,
                    musicOffsetUs = musicOffsetUs,
                    musicVolume = musicVolume,
                    hitSoundVolume = hitSoundVolume,
                    hitEventTimesUs = hitEvents,
                    judgementEvents = judgementEvents,
                    directGallerySaver = if (session.saveToGallery) {
                        { renderedFile ->
                            trySaveDirectlyToGallery(
                                source = renderedFile,
                                preferredDisplayName = session.displayName,
                            )
                        }
                    } else {
                        null
                    },
                )
                result.success(
                    mapOf(
                        "outputPath" to outcome.outputPath,
                        "fileSizeBytes" to outcome.fileSizeBytes.coerceAtMost(Int.MAX_VALUE.toLong()).toInt(),
                        "savedToGallery" to outcome.savedToGallery,
                        "galleryUri" to outcome.galleryUri,
                    ),
                )
                succeeded = true
            } catch (cancelled: ExportCancelledException) {
                result.error("cancelled", cancelled.message, null)
            } catch (error: Throwable) {
                result.error(
                    error.javaClass.simpleName.ifEmpty { "native_error" },
                    error.message ?: "Native video export failed.",
                    null,
                )
            } finally {
                if (!succeeded) session.cancel()
                sessions.remove(id)
            }
        }
    }

    private fun requireSession(id: Int): AndroidVideoExportSession =
        sessions[id] ?: throw IllegalStateException("Unknown video export session $id")

    private fun trySaveDirectlyToGallery(
        source: File,
        preferredDisplayName: String?,
    ): String? {
        val displayName = sanitizeDisplayName(preferredDisplayName, fallback = source.mp4DisplayName)
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveToScopedGallery(source, displayName).toString()
        } else {
            if (context.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
                PackageManager.PERMISSION_GRANTED
            ) {
                return null
            }
            saveToLegacyGallery(source, displayName).toString()
        }
    }

    private fun saveToGallery(path: String): String {
        val source = requireVideoFile(path)
        val displayName = source.mp4DisplayName
        val assetUri = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            saveToScopedGallery(source, displayName).toString()
        } else {
            saveToLegacyGallery(source, displayName).toString()
        }
        deleteExportedVideo(source, "The video was saved, but its local export file could not be deleted.")
        return assetUri
    }

    private fun saveToScopedGallery(source: File, displayName: String): Uri {
        val resolver = context.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.Video.Media.DISPLAY_NAME, displayName)
            put(MediaStore.Video.Media.MIME_TYPE, VIDEO_MIME_TYPE)
            put(
                MediaStore.Video.Media.RELATIVE_PATH,
                "${Environment.DIRECTORY_MOVIES}/ChiffonMai",
            )
            put(MediaStore.Video.Media.IS_PENDING, 1)
        }
        val uri = resolver.insert(MediaStore.Video.Media.EXTERNAL_CONTENT_URI, values)
            ?: throw PluginActionException(
                "gallery_write_failed",
                "Unable to create a video entry in the media library.",
            )
        try {
            resolver.openOutputStream(uri, "w")?.use { output ->
                source.inputStream().buffered().use { input -> input.copyTo(output) }
            } ?: throw IOException("Unable to open the media library destination.")
            values.clear()
            values.put(MediaStore.Video.Media.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return uri
        } catch (error: Throwable) {
            resolver.delete(uri, null, null)
            throw PluginActionException(
                "gallery_write_failed",
                error.message ?: "Unable to copy the exported video to the media library.",
            )
        }
    }

    @Suppress("DEPRECATION")
    private fun saveToLegacyGallery(source: File, displayName: String): Uri {
        if (context.checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            throw PluginActionException(
                "photo_permission_denied",
                "WRITE_EXTERNAL_STORAGE must be granted by the host application before saving a video.",
            )
        }
        val movies = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_MOVIES)
        val directory = File(movies, "ChiffonMai")
        if (!directory.exists() && !directory.mkdirs()) {
            throw PluginActionException(
                "gallery_write_failed",
                "Unable to create the Movies/ChiffonMai directory.",
            )
        }
        val destination = uniqueFile(directory, displayName)
        try {
            source.inputStream().buffered().use { input ->
                destination.outputStream().buffered().use(input::copyTo)
            }
            val values = ContentValues().apply {
                put(MediaStore.Video.Media.DISPLAY_NAME, destination.name)
                put(MediaStore.Video.Media.TITLE, destination.nameWithoutExtension)
                put(MediaStore.Video.Media.MIME_TYPE, VIDEO_MIME_TYPE)
                put(MediaStore.Video.Media.DATA, destination.absolutePath)
                put(MediaStore.Video.Media.SIZE, destination.length())
                put(MediaStore.Video.Media.DATE_ADDED, System.currentTimeMillis() / 1000)
            }
            return context.contentResolver.insert(
                MediaStore.Video.Media.EXTERNAL_CONTENT_URI,
                values,
            ) ?: throw IOException("Unable to register the video in the media library.")
        } catch (error: Throwable) {
            destination.delete()
            throw PluginActionException(
                "gallery_write_failed",
                error.message ?: "Unable to copy the exported video to Movies/ChiffonMai.",
            )
        }
    }

    private fun shareVideo(path: String, text: String?) {
        if (path.startsWith("content://", ignoreCase = true)) {
            try {
                val uri = Uri.parse(path)
                val intent = Intent(Intent.ACTION_SEND).apply {
                    type = VIDEO_MIME_TYPE
                    putExtra(Intent.EXTRA_STREAM, uri)
                    if (!text.isNullOrBlank()) putExtra(Intent.EXTRA_TEXT, text)
                    clipData = android.content.ClipData.newRawUri(text ?: "video.mp4", uri)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                val chooser = Intent.createChooser(intent, null).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                }
                context.startActivity(chooser)
                return
            } catch (error: Throwable) {
                throw PluginActionException(
                    "share_failed",
                    error.message ?: "Unable to open the system share sheet.",
                )
            }
        }
        val source = requireVideoFile(path)
        val shareDirectory = File(context.cacheDir, SHARE_DIRECTORY)
        if (!shareDirectory.exists() && !shareDirectory.mkdirs()) {
            throw PluginActionException(
                "share_failed",
                "Unable to create the temporary video sharing directory.",
            )
        }
        pruneStaleShareFiles(shareDirectory)
        val sharedFile = File(
            shareDirectory,
            "simai_${System.currentTimeMillis()}_${source.mp4DisplayName}",
        )
        var shareSheetOpened = false
        try {
            source.inputStream().buffered().use { input ->
                sharedFile.outputStream().buffered().use(input::copyTo)
            }
            val uri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.simai_flutter.fileprovider",
                sharedFile,
            )
            val intent = Intent(Intent.ACTION_SEND).apply {
                type = VIDEO_MIME_TYPE
                putExtra(Intent.EXTRA_STREAM, uri)
                if (!text.isNullOrBlank()) putExtra(Intent.EXTRA_TEXT, text)
                clipData = android.content.ClipData.newRawUri(sharedFile.name, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            val chooser = Intent.createChooser(intent, null).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            context.startActivity(chooser)
            shareSheetOpened = true
            deleteExportedVideo(
                source,
                "The share sheet was opened, but the local export file could not be deleted.",
            )
        } catch (error: Throwable) {
            if (!shareSheetOpened) sharedFile.delete()
            if (error is PluginActionException) throw error
            throw PluginActionException(
                "share_failed",
                error.message ?: "Unable to open the system share sheet.",
            )
        }
    }

    private fun requireVideoFile(path: String): File {
        val file = File(path)
        if (!file.isAbsolute || !file.isFile || !file.canRead()) {
            throw PluginActionException(
                "file_not_found",
                "The exported video does not exist or cannot be read: $path",
            )
        }
        return file
    }

    private fun deleteExportedVideo(file: File, failureMessage: String) {
        if (file.exists() && !file.delete()) {
            throw PluginActionException("local_cleanup_failed", failureMessage)
        }
    }

    private fun uniqueFile(directory: File, displayName: String): File {
        val requested = File(directory, displayName)
        if (!requested.exists()) return requested
        val baseName = requested.nameWithoutExtension
        var suffix = 2
        while (true) {
            val candidate = File(directory, "$baseName ($suffix).mp4")
            if (!candidate.exists()) return candidate
            suffix++
        }
    }

    private fun pruneStaleShareFiles(directory: File) {
        val cutoff = System.currentTimeMillis() - SHARE_FILE_MAX_AGE_MS
        directory.listFiles()?.forEach { file ->
            if (file.isFile && file.lastModified() < cutoff) file.delete()
        }
    }

    private fun isHardwareAvcSupported(width: Int, height: Int, fps: Int): Boolean {
        return findHardwareAvcEncoder(width, height, fps) != null
    }

    private fun findHardwareAvcEncoder(
        width: Int,
        height: Int,
        fps: Int,
    ): MediaCodecInfo? {
        return MediaCodecList(MediaCodecList.ALL_CODECS).codecInfos.firstOrNull { info ->
            if (!info.isEncoder || !info.supportedTypes.contains(MediaFormat.MIMETYPE_VIDEO_AVC)) {
                return@firstOrNull false
            }
            val hardware = if (Build.VERSION.SDK_INT >= 29) {
                info.isHardwareAccelerated
            } else {
                val name = info.name.lowercase()
                !name.startsWith("omx.google") && !name.startsWith("c2.android")
            }
            if (!hardware) return@firstOrNull false
            runCatching {
                val capabilities = info.getCapabilitiesForType(MediaFormat.MIMETYPE_VIDEO_AVC)
                capabilities.colorFormats.contains(MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface) &&
                    capabilities.videoCapabilities?.areSizeAndRateSupported(
                        width,
                        height,
                        fps.toDouble(),
                    ) == true
            }.getOrDefault(false)
        }
    }

    private fun sanitizeDisplayName(preferred: String?, fallback: String): String {
        val cleaned = preferred
            ?.replace(Regex("""[\\/:*?"<>|\r\n]+"""), "_")
            ?.trim()
            ?.take(120)
            ?.takeIf { it.isNotEmpty() }
            ?: return fallback
        return if (cleaned.endsWith(".mp4", ignoreCase = true)) cleaned else "$cleaned.mp4"
    }

    private val File.mp4DisplayName: String
        get() = if (name.endsWith(".mp4", ignoreCase = true)) name else "$name.mp4"
}

private fun MethodCall.requireInt(key: String): Int =
    (argument<Number>(key) ?: error("Missing argument: $key")).toInt()

private fun MethodCall.requireDouble(key: String): Double =
    (argument<Number>(key) ?: error("Missing argument: $key")).toDouble()

private fun MethodCall.requireString(key: String): String =
    argument<String>(key) ?: error("Missing argument: $key")

private fun MethodCall.requireLong(key: String): Long =
    (argument<Number>(key) ?: error("Missing argument: $key")).toLong()

class ExportCancelledException : RuntimeException("Video export was cancelled.")

private class PluginActionException(
    val code: String,
    override val message: String,
) : RuntimeException(message)
