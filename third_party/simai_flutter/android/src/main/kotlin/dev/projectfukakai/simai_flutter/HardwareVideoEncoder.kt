package dev.projectfukakai.simai_flutter

import android.media.MediaCodec
import android.media.MediaCodecInfo
import android.media.MediaCodecList
import android.media.MediaFormat
import android.media.MediaMuxer
import android.os.Build
import android.opengl.EGL14
import android.opengl.EGLExt
import android.opengl.GLES11Ext
import android.opengl.GLES20
import android.view.Surface
import java.io.File
import java.nio.ByteBuffer
import java.nio.ByteOrder
import java.nio.FloatBuffer

internal class HardwareVideoEncoder(
    private val width: Int,
    private val height: Int,
    private val fps: Int,
    private val bitrate: Int,
    private val codecName: String,
    private val outputFile: File,
    private val pvVideoPath: String? = null,
    private val pvRect: IntArray? = null,
) {
    private lateinit var codec: MediaCodec
    private val bufferInfo = MediaCodec.BufferInfo()
    private lateinit var inputSurface: Surface
    private lateinit var egl: CodecInputEglSurface
    private lateinit var muxer: MediaMuxer
    private var muxerTrack = -1
    private var muxerStarted = false
    private var finished = false
    @Volatile private var cancelled = false
    private var releasing = false
    private val stateLock = Any()

    fun start() {
        val encoderCapabilities = runCatching {
            MediaCodecList(MediaCodecList.ALL_CODECS).codecInfos
                .first { it.name == codecName }
                .getCapabilitiesForType(MediaFormat.MIMETYPE_VIDEO_AVC)
                .encoderCapabilities
        }.getOrNull()
        val candidates = buildList {
            if (encoderCapabilities?.isBitrateModeSupported(
                    MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_CQ,
                ) == true
            ) {
                add(VideoRateControl.CONSTANT_QUALITY)
            }
            if (encoderCapabilities?.isBitrateModeSupported(
                    MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR,
                ) == true
            ) {
                add(VideoRateControl.VARIABLE_BITRATE)
            }
            add(VideoRateControl.TARGET_BITRATE)
        }
        var lastError: Throwable? = null
        for (candidate in candidates) {
            val attemptCodec = MediaCodec.createByCodecName(codecName)
            var attemptSurface: Surface? = null
            var attemptMuxer: MediaMuxer? = null
            var attemptEgl: CodecInputEglSurface? = null
            try {
                val format = createFormat(candidate, encoderCapabilities)
                attemptCodec.configure(
                    format,
                    null,
                    null,
                    MediaCodec.CONFIGURE_FLAG_ENCODE,
                )
                val surface = attemptCodec.createInputSurface()
                attemptSurface = surface
                attemptCodec.start()
                val createdMuxer = MediaMuxer(
                    outputFile.absolutePath,
                    MediaMuxer.OutputFormat.MUXER_OUTPUT_MPEG_4,
                )
                attemptMuxer = createdMuxer
                val createdEgl = CodecInputEglSurface(
                    surface = surface,
                    width = width,
                    height = height,
                    pvVideoPath = pvVideoPath,
                    pvRect = pvRect,
                )
                attemptEgl = createdEgl
                codec = attemptCodec
                inputSurface = surface
                muxer = createdMuxer
                egl = createdEgl
                return
            } catch (error: Throwable) {
                lastError = error
                runCatching { attemptEgl?.release() }
                runCatching { attemptSurface?.release() }
                runCatching { attemptCodec.stop() }
                runCatching { attemptCodec.release() }
                runCatching { attemptMuxer?.release() }
                outputFile.delete()
            }
        }
        throw IllegalStateException(
            "Unable to configure the H.264 encoder with CQ, VBR, or target bitrate.",
            lastError,
        )
    }

    private fun createFormat(
        rateControl: VideoRateControl,
        encoderCapabilities: MediaCodecInfo.EncoderCapabilities?,
    ): MediaFormat = MediaFormat.createVideoFormat(
        MediaFormat.MIMETYPE_VIDEO_AVC,
        width,
        height,
    ).apply {
        setInteger(
            MediaFormat.KEY_COLOR_FORMAT,
            MediaCodecInfo.CodecCapabilities.COLOR_FormatSurface,
        )
        setInteger(MediaFormat.KEY_BIT_RATE, bitrate)
        setInteger(MediaFormat.KEY_FRAME_RATE, fps)
        setInteger(MediaFormat.KEY_I_FRAME_INTERVAL, 2)
        when (rateControl) {
            VideoRateControl.CONSTANT_QUALITY -> {
                setInteger(
                    MediaFormat.KEY_BITRATE_MODE,
                    MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_CQ,
                )
                encoderCapabilities?.qualityRange?.let { range ->
                    val quality = range.lower +
                        ((range.upper.toLong() - range.lower) * 70 / 100).toInt()
                    setInteger(MediaFormat.KEY_QUALITY, quality)
                }
            }
            VideoRateControl.VARIABLE_BITRATE -> setInteger(
                MediaFormat.KEY_BITRATE_MODE,
                MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_VBR,
            )
            VideoRateControl.TARGET_BITRATE -> {
                if (encoderCapabilities?.isBitrateModeSupported(
                        MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_CBR,
                    ) == true
                ) {
                    setInteger(
                        MediaFormat.KEY_BITRATE_MODE,
                        MediaCodecInfo.EncoderCapabilities.BITRATE_MODE_CBR,
                    )
                }
            }
        }
        if (Build.VERSION.SDK_INT >= 29) {
            setInteger(MediaFormat.KEY_MAX_B_FRAMES, 0)
        }
    }

    fun submit(rgba: ByteBuffer, presentationTimeUs: Long, pvTimeUs: Long? = null) {
        check(!finished) { "Video encoder is already finished." }
        rgba.position(0)
        egl.drawFrame(rgba, presentationTimeUs * 1000, pvTimeUs)
        drain(endOfStream = false)
    }

    fun finish() {
        synchronized(stateLock) {
            if (finished) return
            finished = true
        }
        try {
            checkCancelled()
            codec.signalEndOfInputStream()
            drain(endOfStream = true)
        } finally {
            releaseOnce()
        }
    }

    fun cancel() {
        cancelled = true
        val releaseNow = synchronized(stateLock) {
            if (finished) {
                false
            } else {
                finished = true
                true
            }
        }
        if (releaseNow) releaseOnce()
    }

    private fun drain(endOfStream: Boolean) {
        var idleCount = 0
        while (true) {
            checkCancelled()
            val index = codec.dequeueOutputBuffer(bufferInfo, if (endOfStream) 10_000 else 0)
            when {
                index == MediaCodec.INFO_TRY_AGAIN_LATER -> {
                    if (!endOfStream) return
                    check(++idleCount <= 1000) {
                        "Timed out while draining the H.264 encoder."
                    }
                }
                index == MediaCodec.INFO_OUTPUT_FORMAT_CHANGED -> {
                    idleCount = 0
                    check(!muxerStarted) { "Video output format changed twice." }
                    muxerTrack = muxer.addTrack(codec.outputFormat)
                    muxer.start()
                    muxerStarted = true
                }
                index >= 0 -> {
                    idleCount = 0
                    val data = codec.getOutputBuffer(index)
                        ?: error("Video encoder returned a null output buffer.")
                    if (bufferInfo.flags and MediaCodec.BUFFER_FLAG_CODEC_CONFIG != 0) {
                        bufferInfo.size = 0
                    }
                    if (bufferInfo.size > 0) {
                        check(muxerStarted) { "Video muxer has not started." }
                        data.position(bufferInfo.offset)
                        data.limit(bufferInfo.offset + bufferInfo.size)
                        muxer.writeSampleData(muxerTrack, data, bufferInfo)
                    }
                    val eos = bufferInfo.flags and MediaCodec.BUFFER_FLAG_END_OF_STREAM != 0
                    codec.releaseOutputBuffer(index, false)
                    if (eos) return
                }
            }
        }
    }

    private fun release() {
        runCatching { egl.release() }
        runCatching { inputSurface.release() }
        runCatching { codec.stop() }
        runCatching { codec.release() }
        if (muxerStarted) runCatching { muxer.stop() }
        runCatching { muxer.release() }
    }

    private fun releaseOnce() {
        synchronized(stateLock) {
            if (releasing) return
            releasing = true
        }
        release()
    }

    private fun checkCancelled() {
        if (cancelled) throw ExportCancelledException()
    }
}

private enum class VideoRateControl {
    CONSTANT_QUALITY,
    VARIABLE_BITRATE,
    TARGET_BITRATE,
}

private class CodecInputEglSurface(
    surface: Surface,
    private val width: Int,
    private val height: Int,
    pvVideoPath: String? = null,
    private val pvRect: IntArray? = null,
) {
    private val display = EGL14.eglGetDisplay(EGL14.EGL_DEFAULT_DISPLAY)
    private val context: android.opengl.EGLContext
    private val eglSurface: android.opengl.EGLSurface
    private val program: Int
    private val texture: Int
    private val positionLocation: Int
    private val textureCoordinateLocation: Int
    private val samplerLocation: Int

    private var oesProgram: Int = 0
    private var oesTexture: Int = 0
    private var oesPositionLocation: Int = -1
    private var oesTextureCoordinateLocation: Int = -1
    private var oesTexMatrixLocation: Int = -1
    private var oesSamplerLocation: Int = -1
    private var pvDecoder: AndroidPvFrameDecoder? = null

    private val vertices: FloatBuffer = floatBufferOf(
        -1f, -1f,
        1f, -1f,
        -1f, 1f,
        1f, 1f,
    )
    private val textureCoordinates: FloatBuffer = floatBufferOf(
        0f, 1f,
        1f, 1f,
        0f, 0f,
        1f, 0f,
    )

    init {
        check(display != EGL14.EGL_NO_DISPLAY) { "Unable to acquire EGL display." }
        val versions = IntArray(2)
        check(EGL14.eglInitialize(display, versions, 0, versions, 1)) {
            "Unable to initialize EGL."
        }
        val configAttributes = intArrayOf(
            EGL14.EGL_RED_SIZE, 8,
            EGL14.EGL_GREEN_SIZE, 8,
            EGL14.EGL_BLUE_SIZE, 8,
            EGL14.EGL_ALPHA_SIZE, 8,
            EGL14.EGL_RENDERABLE_TYPE, EGL14.EGL_OPENGL_ES2_BIT,
            0x3142, 1, // EGL_RECORDABLE_ANDROID
            EGL14.EGL_NONE,
        )
        val configs = arrayOfNulls<android.opengl.EGLConfig>(1)
        val count = IntArray(1)
        check(
            EGL14.eglChooseConfig(
                display,
                configAttributes,
                0,
                configs,
                0,
                1,
                count,
                0,
            ) && count[0] > 0,
        ) { "Unable to choose an encoder EGL config." }
        val config = configs[0] ?: error("Encoder EGL config was null.")
        context = EGL14.eglCreateContext(
            display,
            config,
            EGL14.EGL_NO_CONTEXT,
            intArrayOf(EGL14.EGL_CONTEXT_CLIENT_VERSION, 2, EGL14.EGL_NONE),
            0,
        )
        check(context != EGL14.EGL_NO_CONTEXT) { "Unable to create EGL context." }
        eglSurface = EGL14.eglCreateWindowSurface(
            display,
            config,
            surface,
            intArrayOf(EGL14.EGL_NONE),
            0,
        )
        check(eglSurface != EGL14.EGL_NO_SURFACE) { "Unable to create encoder EGL surface." }
        makeCurrent()

        program = createProgram(VERTEX_SHADER, FRAGMENT_SHADER)
        positionLocation = GLES20.glGetAttribLocation(program, "aPosition")
        textureCoordinateLocation = GLES20.glGetAttribLocation(program, "aTexCoord")
        samplerLocation = GLES20.glGetUniformLocation(program, "uTexture")
        val textures = IntArray(1)
        GLES20.glGenTextures(1, textures, 0)
        texture = textures[0]
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texture)
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_MIN_FILTER,
            GLES20.GL_LINEAR,
        )
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_MAG_FILTER,
            GLES20.GL_LINEAR,
        )
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_WRAP_S,
            GLES20.GL_CLAMP_TO_EDGE,
        )
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_WRAP_T,
            GLES20.GL_CLAMP_TO_EDGE,
        )
        GLES20.glPixelStorei(GLES20.GL_UNPACK_ALIGNMENT, 1)
        GLES20.glTexImage2D(
            GLES20.GL_TEXTURE_2D,
            0,
            GLES20.GL_RGBA,
            width,
            height,
            0,
            GLES20.GL_RGBA,
            GLES20.GL_UNSIGNED_BYTE,
            null,
        )

        if (pvVideoPath != null && pvRect != null && pvRect.size == 4 && pvRect[2] > 0 && pvRect[3] > 0) {
            try {
                oesProgram = createProgram(OES_VERTEX_SHADER, OES_FRAGMENT_SHADER)
                oesPositionLocation = GLES20.glGetAttribLocation(oesProgram, "aPosition")
                oesTextureCoordinateLocation = GLES20.glGetAttribLocation(oesProgram, "aTexCoord")
                oesTexMatrixLocation = GLES20.glGetUniformLocation(oesProgram, "uTexMatrix")
                oesSamplerLocation = GLES20.glGetUniformLocation(oesProgram, "uTexture")

                val oesTextures = IntArray(1)
                GLES20.glGenTextures(1, oesTextures, 0)
                oesTexture = oesTextures[0]
                GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, oesTexture)
                GLES20.glTexParameteri(
                    GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
                    GLES20.GL_TEXTURE_MIN_FILTER,
                    GLES20.GL_LINEAR,
                )
                GLES20.glTexParameteri(
                    GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
                    GLES20.GL_TEXTURE_MAG_FILTER,
                    GLES20.GL_LINEAR,
                )
                GLES20.glTexParameteri(
                    GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
                    GLES20.GL_TEXTURE_WRAP_S,
                    GLES20.GL_CLAMP_TO_EDGE,
                )
                GLES20.glTexParameteri(
                    GLES11Ext.GL_TEXTURE_EXTERNAL_OES,
                    GLES20.GL_TEXTURE_WRAP_T,
                    GLES20.GL_CLAMP_TO_EDGE,
                )
                GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, 0)

                pvDecoder = AndroidPvFrameDecoder(
                    videoPath = pvVideoPath,
                    oesTextureId = oesTexture,
                    targetWidth = pvRect[2],
                    targetHeight = pvRect[3],
                )
            } catch (error: Throwable) {
                release()
                throw error
            }
        }
    }

    fun drawFrame(rgba: ByteBuffer, presentationTimeNs: Long, pvTimeUs: Long? = null) {
        makeCurrent()
        val decoder = pvDecoder
        val rect = pvRect
        if (decoder != null && rect != null) {
            // 先清为纯黑底，再绘制 PV 视频区域，最后以预乘 Alpha 叠画 Flutter 图层
            GLES20.glDisable(GLES20.GL_BLEND)
            GLES20.glViewport(0, 0, width, height)
            GLES20.glClearColor(0f, 0f, 0f, 1f)
            GLES20.glClear(GLES20.GL_COLOR_BUFFER_BIT)

            if (pvTimeUs != null && decoder.advanceTo(pvTimeUs)) {
                val left = rect[0]
                val top = rect[1]
                val pvW = rect[2]
                val pvH = rect[3]
                val glY = height - top - pvH
                GLES20.glViewport(left, glY, pvW, pvH)
                GLES20.glUseProgram(oesProgram)
                vertices.position(0)
                decoder.textureCoordinates.position(0)
                GLES20.glEnableVertexAttribArray(oesPositionLocation)
                GLES20.glVertexAttribPointer(
                    oesPositionLocation,
                    2,
                    GLES20.GL_FLOAT,
                    false,
                    0,
                    vertices,
                )
                GLES20.glEnableVertexAttribArray(oesTextureCoordinateLocation)
                GLES20.glVertexAttribPointer(
                    oesTextureCoordinateLocation,
                    2,
                    GLES20.GL_FLOAT,
                    false,
                    0,
                    decoder.textureCoordinates,
                )
                GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
                GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, oesTexture)
                GLES20.glUniform1i(oesSamplerLocation, 0)
                GLES20.glUniformMatrix4fv(oesTexMatrixLocation, 1, false, decoder.transformMatrix, 0)
                GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
                GLES20.glDisableVertexAttribArray(oesPositionLocation)
                GLES20.glDisableVertexAttribArray(oesTextureCoordinateLocation)
                GLES20.glBindTexture(GLES11Ext.GL_TEXTURE_EXTERNAL_OES, 0)
            }

            GLES20.glViewport(0, 0, width, height)
            GLES20.glEnable(GLES20.GL_BLEND)
            GLES20.glBlendFunc(GLES20.GL_ONE, GLES20.GL_ONE_MINUS_SRC_ALPHA)
        } else {
            GLES20.glDisable(GLES20.GL_BLEND)
            GLES20.glViewport(0, 0, width, height)
        }

        GLES20.glActiveTexture(GLES20.GL_TEXTURE0)
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, texture)
        GLES20.glTexSubImage2D(
            GLES20.GL_TEXTURE_2D,
            0,
            0,
            0,
            width,
            height,
            GLES20.GL_RGBA,
            GLES20.GL_UNSIGNED_BYTE,
            rgba,
        )
        GLES20.glUseProgram(program)
        vertices.position(0)
        textureCoordinates.position(0)
        GLES20.glEnableVertexAttribArray(positionLocation)
        GLES20.glVertexAttribPointer(
            positionLocation,
            2,
            GLES20.GL_FLOAT,
            false,
            0,
            vertices,
        )
        GLES20.glEnableVertexAttribArray(textureCoordinateLocation)
        GLES20.glVertexAttribPointer(
            textureCoordinateLocation,
            2,
            GLES20.GL_FLOAT,
            false,
            0,
            textureCoordinates,
        )
        GLES20.glUniform1i(samplerLocation, 0)
        GLES20.glDrawArrays(GLES20.GL_TRIANGLE_STRIP, 0, 4)
        GLES20.glDisableVertexAttribArray(positionLocation)
        GLES20.glDisableVertexAttribArray(textureCoordinateLocation)
        if (decoder != null) {
            GLES20.glDisable(GLES20.GL_BLEND)
        }
        EGLExt.eglPresentationTimeANDROID(display, eglSurface, presentationTimeNs)
        check(EGL14.eglSwapBuffers(display, eglSurface)) { "Encoder EGL swap failed." }
    }

    fun release() {
        runCatching { pvDecoder?.release() }
        pvDecoder = null
        runCatching {
            makeCurrent()
            if (oesTexture != 0) {
                GLES20.glDeleteTextures(1, intArrayOf(oesTexture), 0)
                oesTexture = 0
            }
            if (oesProgram != 0) {
                GLES20.glDeleteProgram(oesProgram)
                oesProgram = 0
            }
            GLES20.glDeleteTextures(1, intArrayOf(texture), 0)
            GLES20.glDeleteProgram(program)
        }
        runCatching {
            EGL14.eglMakeCurrent(
                display,
                EGL14.EGL_NO_SURFACE,
                EGL14.EGL_NO_SURFACE,
                EGL14.EGL_NO_CONTEXT,
            )
        }
        runCatching { EGL14.eglDestroySurface(display, eglSurface) }
        runCatching { EGL14.eglDestroyContext(display, context) }
        runCatching { EGL14.eglReleaseThread() }
        runCatching { EGL14.eglTerminate(display) }
    }

    private fun makeCurrent() {
        check(EGL14.eglMakeCurrent(display, eglSurface, eglSurface, context)) {
            "Unable to make encoder EGL context current."
        }
    }

    private fun createProgram(vertexSource: String, fragmentSource: String): Int {
        val vertex = compileShader(GLES20.GL_VERTEX_SHADER, vertexSource)
        val fragment = compileShader(GLES20.GL_FRAGMENT_SHADER, fragmentSource)
        val program = GLES20.glCreateProgram()
        GLES20.glAttachShader(program, vertex)
        GLES20.glAttachShader(program, fragment)
        GLES20.glLinkProgram(program)
        val linked = IntArray(1)
        GLES20.glGetProgramiv(program, GLES20.GL_LINK_STATUS, linked, 0)
        GLES20.glDeleteShader(vertex)
        GLES20.glDeleteShader(fragment)
        check(linked[0] != 0) { "Unable to link encoder GL program: ${GLES20.glGetProgramInfoLog(program)}" }
        return program
    }

    private fun compileShader(type: Int, source: String): Int {
        val shader = GLES20.glCreateShader(type)
        GLES20.glShaderSource(shader, source)
        GLES20.glCompileShader(shader)
        val compiled = IntArray(1)
        GLES20.glGetShaderiv(shader, GLES20.GL_COMPILE_STATUS, compiled, 0)
        check(compiled[0] != 0) { "Unable to compile encoder shader: ${GLES20.glGetShaderInfoLog(shader)}" }
        return shader
    }

    companion object {
        private const val VERTEX_SHADER = """
            attribute vec4 aPosition;
            attribute vec2 aTexCoord;
            varying vec2 vTexCoord;
            void main() {
              gl_Position = aPosition;
              vTexCoord = aTexCoord;
            }
        """
        private const val FRAGMENT_SHADER = """
            precision mediump float;
            varying vec2 vTexCoord;
            uniform sampler2D uTexture;
            void main() {
              gl_FragColor = texture2D(uTexture, vTexCoord);
            }
        """
        private const val OES_VERTEX_SHADER = """
            attribute vec4 aPosition;
            attribute vec2 aTexCoord;
            uniform mat4 uTexMatrix;
            varying vec2 vTexCoord;
            void main() {
              gl_Position = aPosition;
              vTexCoord = (uTexMatrix * vec4(aTexCoord, 0.0, 1.0)).xy;
            }
        """
        private const val OES_FRAGMENT_SHADER = """
            #extension GL_OES_EGL_image_external : require
            precision mediump float;
            varying vec2 vTexCoord;
            uniform samplerExternalOES uTexture;
            void main() {
              gl_FragColor = texture2D(uTexture, vTexCoord);
            }
        """
    }
}

private fun floatBufferOf(vararg values: Float): FloatBuffer =
    ByteBuffer.allocateDirect(values.size * 4)
        .order(ByteOrder.nativeOrder())
        .asFloatBuffer()
        .apply {
            put(values)
            position(0)
        }
