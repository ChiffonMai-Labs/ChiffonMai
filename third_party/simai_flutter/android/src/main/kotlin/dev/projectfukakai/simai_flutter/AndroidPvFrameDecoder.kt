package dev.projectfukakai.simai_flutter

import android.graphics.SurfaceTexture
import android.media.MediaCodec
import android.media.MediaExtractor
import android.media.MediaFormat
import android.media.MediaMetadataRetriever
import android.opengl.Matrix
import android.os.Handler
import android.os.HandlerThread
import android.view.Surface
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

/**
 * Android 原生 PV 视频顺序硬解器。
 *
 * 通过 MediaExtractor + MediaCodec 解码到绑定了外部 OES 纹理的 SurfaceTexture，
 * 在导出循环中按时间单调推进并支持旋转元数据及 BoxFit.cover 居中裁切。
 */
internal class AndroidPvFrameDecoder(
    videoPath: String,
    oesTextureId: Int,
    targetWidth: Int,
    targetHeight: Int,
) {
    private val extractor = MediaExtractor()
    private val codec: MediaCodec
    private val handlerThread = HandlerThread("SimaiPvDecoderThread")
    private val surfaceTexture: SurfaceTexture
    private val outputSurface: Surface
    private val bufferInfo = MediaCodec.BufferInfo()
    private val frameSyncLock = Object()

    @Volatile
    private var frameAvailable = false
    private var inputEos = false
    private var outputEos = false
    private var hasDecodedFrame = false
    private var lastPtsUs = Long.MIN_VALUE
    private var released = false

    val durationUs: Long
    val transformMatrix = FloatArray(16).apply { Matrix.setIdentityM(this, 0) }
    val textureCoordinates: FloatBuffer

    init {
        val file = File(videoPath)
        require(file.isFile && file.canRead()) {
            "PV 视频文件不存在或不可读: $videoPath"
        }
        require(targetWidth > 0 && targetHeight > 0) {
            "PV 目标绘制尺寸必须为正数: ${targetWidth}x$targetHeight"
        }

        var createdCodec: MediaCodec? = null
        var createdSurfaceTexture: SurfaceTexture? = null
        var createdOutputSurface: Surface? = null
        try {
            extractor.setDataSource(file.absolutePath)
            val videoTrackIndex = (0 until extractor.trackCount).firstOrNull { index ->
                extractor.getTrackFormat(index)
                    .getString(MediaFormat.KEY_MIME)
                    ?.startsWith("video/") == true
            } ?: error("PV 文件中未找到视频轨道: ${file.name}")

            extractor.selectTrack(videoTrackIndex)
            val format = extractor.getTrackFormat(videoTrackIndex)
            val mime = format.getString(MediaFormat.KEY_MIME)
                ?: error("PV 视频轨道缺少 MIME 类型。")
            val rawWidth = format.getInteger(MediaFormat.KEY_WIDTH)
            val rawHeight = format.getInteger(MediaFormat.KEY_HEIGHT)
            require(rawWidth > 0 && rawHeight > 0) {
                "PV 视频尺寸无效: ${rawWidth}x$rawHeight"
            }

            val metadata = readFallbackMetadata(file.absolutePath)
            val rotation = normalizeRotation(
                if (format.containsKey(MediaFormat.KEY_ROTATION)) {
                    format.getInteger(MediaFormat.KEY_ROTATION)
                } else {
                    metadata.rotationDegrees
                },
            )
            if (!format.containsKey(MediaFormat.KEY_ROTATION) && rotation != 0) {
                format.setInteger(MediaFormat.KEY_ROTATION, rotation)
            }

            val resolvedDurationUs = if (format.containsKey(MediaFormat.KEY_DURATION)) {
                format.getLong(MediaFormat.KEY_DURATION)
            } else {
                metadata.durationUs
            }
            durationUs = resolvedDurationUs.coerceAtLeast(0L)

            val displayWidth = if (rotation == 90 || rotation == 270) rawHeight else rawWidth
            val displayHeight = if (rotation == 90 || rotation == 270) rawWidth else rawHeight
            textureCoordinates = buildCoverTextureCoordinates(
                videoWidth = displayWidth,
                videoHeight = displayHeight,
                targetWidth = targetWidth,
                targetHeight = targetHeight,
            )

            handlerThread.start()
            val frameHandler = Handler(handlerThread.looper)
            createdSurfaceTexture = SurfaceTexture(oesTextureId).apply {
                setOnFrameAvailableListener({
                    synchronized(frameSyncLock) {
                        frameAvailable = true
                        frameSyncLock.notifyAll()
                    }
                }, frameHandler)
            }
            createdOutputSurface = Surface(createdSurfaceTexture)
            createdCodec = MediaCodec.createDecoderByType(mime).apply {
                configure(format, createdOutputSurface, null, 0)
                start()
            }

            surfaceTexture = createdSurfaceTexture
            outputSurface = createdOutputSurface
            codec = createdCodec
        } catch (error: Throwable) {
            runCatching { createdSurfaceTexture?.setOnFrameAvailableListener(null) }
            runCatching { createdCodec?.stop() }
            runCatching { createdCodec?.release() }
            runCatching { createdOutputSurface?.release() }
            runCatching { createdSurfaceTexture?.release() }
            runCatching { extractor.release() }
            runCatching { handlerThread.quitSafely() }
            throw error
        }
    }

    /**
     * 顺序推进解码至不早于 `targetTimeUs - 8_333L` 的帧并更新 OES 纹理。
     *
     * 当 `targetTimeUs < 0` 或 `targetTimeUs > durationUs` 时返回 `false`。
     */
    fun advanceTo(targetTimeUs: Long): Boolean {
        if (released || durationUs <= 0L || targetTimeUs < 0L || targetTimeUs > durationUs) {
            return false
        }
        val thresholdUs = targetTimeUs - FRAME_MATCH_TOLERANCE_US
        if (hasDecodedFrame && lastPtsUs >= thresholdUs) {
            return true
        }
        if (outputEos) {
            return hasDecodedFrame
        }

        var idleLoops = 0
        while (!outputEos) {
            if (!inputEos) {
                val inputIndex = codec.dequeueInputBuffer(DEQUEUE_TIMEOUT_US)
                if (inputIndex >= 0) {
                    val inputBuffer = codec.getInputBuffer(inputIndex)
                    val sampleSize = if (inputBuffer != null) {
                        extractor.readSampleData(inputBuffer, 0)
                    } else {
                        -1
                    }
                    if (sampleSize < 0) {
                        codec.queueInputBuffer(
                            inputIndex,
                            0,
                            0,
                            0L,
                            MediaCodec.BUFFER_FLAG_END_OF_STREAM,
                        )
                        inputEos = true
                    } else {
                        val sampleTimeUs = extractor.sampleTime
                        codec.queueInputBuffer(inputIndex, 0, sampleSize, sampleTimeUs, 0)
                        extractor.advance()
                    }
                }
            }

            val outputIndex = codec.dequeueOutputBuffer(bufferInfo, DEQUEUE_TIMEOUT_US)
            when {
                outputIndex == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    idleLoops++
                    if (idleLoops > MAX_DEQUEUE_IDLE_LOOPS) {
                        return hasDecodedFrame
                    }
                }
                outputIndex == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    idleLoops = 0
                }
                outputIndex >= 0 -> {
                    idleLoops = 0
                    val isEos = (bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM) != 0
                    val hasData = bufferInfo.size > 0
                    val ptsUs = bufferInfo.presentationTimeUs
                    if (isEos) {
                        outputEos = true
                    }
                    if (hasData && (ptsUs >= thresholdUs || isEos)) {
                        synchronized(frameSyncLock) {
                            frameAvailable = false
                        }
                        codec.releaseOutputBuffer(outputIndex, true)
                        if (waitForNewFrame()) {
                            surfaceTexture.updateTexImage()
                            surfaceTexture.getTransformMatrix(transformMatrix)
                            lastPtsUs = ptsUs
                            hasDecodedFrame = true
                        }
                        if (ptsUs >= thresholdUs || outputEos) {
                            return hasDecodedFrame
                        }
                    } else {
                        codec.releaseOutputBuffer(outputIndex, false)
                        if (outputEos) {
                            return hasDecodedFrame
                        }
                    }
                }
            }
        }
        return hasDecodedFrame
    }

    /** 释放硬解器、SurfaceTexture 与后台回调线程。 */
    fun release() {
        if (released) return
        released = true
        runCatching { surfaceTexture.setOnFrameAvailableListener(null) }
        synchronized(frameSyncLock) {
            frameSyncLock.notifyAll()
        }
        runCatching { codec.stop() }
        runCatching { codec.release() }
        runCatching { outputSurface.release() }
        runCatching { surfaceTexture.release() }
        runCatching { extractor.release() }
        runCatching { handlerThread.quitSafely() }
    }

    private fun waitForNewFrame(): Boolean {
        val deadlineMs = System.currentTimeMillis() + FRAME_AVAILABLE_TIMEOUT_MS
        synchronized(frameSyncLock) {
            while (!frameAvailable && !released) {
                val remainingMs = deadlineMs - System.currentTimeMillis()
                if (remainingMs <= 0L) {
                    return false
                }
                try {
                    frameSyncLock.wait(remainingMs)
                } catch (_: InterruptedException) {
                    Thread.currentThread().interrupt()
                    return false
                }
            }
            if (!frameAvailable || released) return false
            frameAvailable = false
            return true
        }
    }

    private fun readFallbackMetadata(path: String): FallbackVideoMetadata {
        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(path)
            val rotation = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_VIDEO_ROTATION,
            )?.toIntOrNull() ?: 0
            val durationMs = retriever.extractMetadata(
                MediaMetadataRetriever.METADATA_KEY_DURATION,
            )?.toLongOrNull() ?: 0L
            FallbackVideoMetadata(rotation, durationMs * 1000L)
        } catch (_: Throwable) {
            FallbackVideoMetadata(0, 0L)
        } finally {
            runCatching { retriever.release() }
        }
    }

    private fun normalizeRotation(degrees: Int): Int {
        val normalized = ((degrees % 360) + 360) % 360
        return when (normalized) {
            90, 180, 270 -> normalized
            else -> 0
        }
    }

    private fun buildCoverTextureCoordinates(
        videoWidth: Int,
        videoHeight: Int,
        targetWidth: Int,
        targetHeight: Int,
    ): FloatBuffer {
        val videoAspect = videoWidth.toFloat() / videoHeight.toFloat()
        val targetAspect = targetWidth.toFloat() / targetHeight.toFloat()
        var uMin = 0f
        var uMax = 1f
        var vMin = 0f
        var vMax = 1f
        if (videoAspect > targetAspect) {
            val scaleU = targetAspect / videoAspect
            val offsetU = (1f - scaleU) * 0.5f
            uMin = offsetU
            uMax = 1f - offsetU
        } else if (videoAspect < targetAspect) {
            val scaleV = videoAspect / targetAspect
            val offsetV = (1f - scaleV) * 0.5f
            vMin = offsetV
            vMax = 1f - offsetV
        }
        // 匹配 SurfaceTexture 的左下角原点坐标：(-1,-1) 到 (1,1)
        val coords = floatArrayOf(
            uMin, vMin,
            uMax, vMin,
            uMin, vMax,
            uMax, vMax,
        )
        return ByteBuffer.allocateDirect(coords.size * 4)
            .order(ByteOrder.nativeOrder())
            .asFloatBuffer()
            .apply {
                put(coords)
                position(0)
            }
    }

    private data class FallbackVideoMetadata(
        val rotationDegrees: Int,
        val durationUs: Long,
    )

    companion object {
        private const val FRAME_MATCH_TOLERANCE_US = 8_333L
        private const val DEQUEUE_TIMEOUT_US = 10_000L
        private const val FRAME_AVAILABLE_TIMEOUT_MS = 300L
        private const val MAX_DEQUEUE_IDLE_LOOPS = 300
    }
}
