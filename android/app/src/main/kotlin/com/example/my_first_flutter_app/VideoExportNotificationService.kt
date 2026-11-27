package com.example.my_first_flutter_app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import androidx.core.content.ContextCompat

/**
 * 谱面视频导出的前台保活服务与通知栏进度展示。
 *
 * 导出过程中由 Kotlin `HardwareVideoEncoder`（基于 MediaCodec 离屏 EGL Surface）在后台线程编码，
 * 因此即使退到桌面或关闭导出页，只要保活服务运行且 WakeLock 未被释放，导出即可持续推进并实时刷新进度。
 */
class VideoExportNotificationService : Service() {

    companion object {
        const val PROGRESS_NOTIFICATION_ID = 1126
        const val RESULT_NOTIFICATION_ID = 1127

        const val PROGRESS_CHANNEL_ID =
            "com.example.my_first_flutter_app.channel.video_export_progress"
        const val RESULT_CHANNEL_ID =
            "com.example.my_first_flutter_app.channel.video_export_result"

        const val ACTION_UPDATE_PROGRESS =
            "com.example.my_first_flutter_app.VIDEO_EXPORT_UPDATE"
        const val ACTION_CANCEL_FROM_NOTIFICATION =
            "com.example.my_first_flutter_app.VIDEO_EXPORT_CANCEL"

        private const val EXTRA_TITLE = "title"
        private const val EXTRA_DETAIL = "detailText"
        private const val EXTRA_SUB_TEXT = "subText"
        private const val EXTRA_PERMILLE = "progressPermille"
        private const val EXTRA_INDETERMINATE = "indeterminate"
        private const val EXTRA_CANCELLING = "cancelling"

        private const val REQUEST_OPEN_EXPORT = 201
        private const val REQUEST_CANCEL = 202
        private const val WAKE_LOCK_TAG = "chiffonmai:video_export"
        private const val WAKE_LOCK_TIMEOUT_MS = 30L * 60L * 1000L

        fun updateProgress(
            context: Context,
            title: String,
            detailText: String,
            subText: String?,
            progressPermille: Int,
            indeterminate: Boolean,
            cancelling: Boolean
        ) {
            val intent = Intent(context, VideoExportNotificationService::class.java).apply {
                action = ACTION_UPDATE_PROGRESS
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_DETAIL, detailText)
                putExtra(EXTRA_SUB_TEXT, subText ?: "")
                putExtra(EXTRA_PERMILLE, progressPermille.coerceIn(0, 1000))
                putExtra(EXTRA_INDETERMINATE, indeterminate)
                putExtra(EXTRA_CANCELLING, cancelling)
            }
            try {
                ContextCompat.startForegroundService(context, intent)
            } catch (e: Exception) {
                android.util.Log.w("VideoExportNotif", "更新导出前台服务失败: $e")
            }
        }

        fun finish(
            context: Context,
            status: String,
            title: String,
            message: String?
        ) {
            stopServiceAndClearProgress(context)
            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
                    ?: return
            ensureResultChannel(context, manager)
            when (status) {
                "completed" -> {
                    val detail = message?.takeIf { it.isNotBlank() } ?: "已保存到系统相册"
                    val contentText = if (title.isNotBlank()) {
                        "$title · $detail"
                    } else {
                        detail
                    }
                    val notification = buildResultNotification(
                        context = context,
                        title = "谱面视频导出完成",
                        text = contentText
                    )
                    manager.notify(RESULT_NOTIFICATION_ID, notification)
                }
                "failed" -> {
                    val detail = message?.takeIf { it.isNotBlank() } ?: "请返回重试"
                    val notification = buildResultNotification(
                        context = context,
                        title = "谱面视频导出失败",
                        text = if (title.isNotBlank()) "$title · $detail" else detail
                    )
                    manager.notify(RESULT_NOTIFICATION_ID, notification)
                }
                else -> {
                    // cancelled 等状态只清理进度通知，不额外弹窗打扰
                }
            }
        }

        fun clear(context: Context) {
            stopServiceAndClearProgress(context)
        }

        private fun stopServiceAndClearProgress(context: Context) {
            try {
                context.stopService(Intent(context, VideoExportNotificationService::class.java))
            } catch (_: Exception) {
            }
            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as? NotificationManager
            manager?.cancel(PROGRESS_NOTIFICATION_ID)
        }

        private fun ensureProgressChannel(context: Context, manager: NotificationManager) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            if (manager.getNotificationChannel(PROGRESS_CHANNEL_ID) != null) return
            val channel = NotificationChannel(
                PROGRESS_CHANNEL_ID,
                "谱面视频导出进度",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "在后台导出谱面视频时显示实时进度与取消操作"
                setShowBadge(false)
                enableVibration(false)
                setSound(null, null)
            }
            manager.createNotificationChannel(channel)
        }

        private fun ensureResultChannel(context: Context, manager: NotificationManager) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            if (manager.getNotificationChannel(RESULT_CHANNEL_ID) != null) return
            val channel = NotificationChannel(
                RESULT_CHANNEL_ID,
                "谱面视频导出结果",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "通知谱面视频导出成功或失败状态"
            }
            manager.createNotificationChannel(channel)
        }

        private fun buildResultNotification(
            context: Context,
            title: String,
            text: String
        ): Notification {
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                Notification.Builder(context, RESULT_CHANNEL_ID)
            } else {
                @Suppress("DEPRECATION")
                Notification.Builder(context)
            }
            return builder
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(text)
                .setStyle(Notification.BigTextStyle().bigText(text))
                .setContentIntent(openExportPendingIntent(context))
                .setAutoCancel(true)
                .build()
        }

        private fun openExportPendingIntent(context: Context): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
                putExtra(MainActivity.EXTRA_OPEN_VIDEO_EXPORT, true)
            }
            return PendingIntent.getActivity(
                context,
                REQUEST_OPEN_EXPORT,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
    }

    private lateinit var notificationManager: NotificationManager
    private var wakeLock: PowerManager.WakeLock? = null
    private var isForeground = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        notificationManager =
            getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        ensureProgressChannel(this, notificationManager)
        val pm = getSystemService(Context.POWER_SERVICE) as? PowerManager
        wakeLock = pm?.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, WAKE_LOCK_TAG)?.apply {
            setReferenceCounted(false)
        }
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent == null) {
            stopForegroundAndSelf()
            return START_NOT_STICKY
        }
        when (intent.action) {
            ACTION_CANCEL_FROM_NOTIFICATION -> {
                val callback = VideoExportNotificationBridge.onCancelRequested
                if (callback != null) {
                    callback.invoke()
                } else {
                    stopForegroundAndSelf()
                }
            }
            ACTION_UPDATE_PROGRESS -> {
                acquireWakeLock()
                val title = intent.getStringExtra(EXTRA_TITLE) ?: ""
                val detail = intent.getStringExtra(EXTRA_DETAIL) ?: ""
                val subText = intent.getStringExtra(EXTRA_SUB_TEXT) ?: ""
                val permille = intent.getIntExtra(EXTRA_PERMILLE, 0)
                val indeterminate = intent.getBooleanExtra(EXTRA_INDETERMINATE, false)
                val cancelling = intent.getBooleanExtra(EXTRA_CANCELLING, false)
                val notification = buildProgressNotification(
                    title = title,
                    detailText = detail,
                    subText = subText,
                    permille = permille,
                    indeterminate = indeterminate,
                    cancelling = cancelling
                )
                try {
                    if (!isForeground) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            startForeground(
                                PROGRESS_NOTIFICATION_ID,
                                notification,
                                ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC
                            )
                        } else {
                            startForeground(PROGRESS_NOTIFICATION_ID, notification)
                        }
                        isForeground = true
                    } else {
                        notificationManager.notify(PROGRESS_NOTIFICATION_ID, notification)
                    }
                } catch (e: Exception) {
                    android.util.Log.w("VideoExportNotif", "显示导出进度通知失败: $e")
                }
            }
        }
        return START_NOT_STICKY
    }

    override fun onTimeout(startId: Int, fgsType: Int) {
        stopForegroundAndSelf()
    }

    override fun onDestroy() {
        releaseWakeLock()
        stopForegroundCompat()
        isForeground = false
        super.onDestroy()
    }

    private fun buildProgressNotification(
        title: String,
        detailText: String,
        subText: String,
        permille: Int,
        indeterminate: Boolean,
        cancelling: Boolean
    ): Notification {
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, PROGRESS_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        val contentTitle = if (title.isNotBlank()) {
            "正在导出谱面视频 · $title"
        } else {
            "正在导出谱面视频"
        }
        builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(contentTitle)
            .setContentText(detailText)
            .setProgress(1000, permille.coerceIn(0, 1000), indeterminate)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setContentIntent(openExportPendingIntent(this))

        if (subText.isNotBlank()) {
            builder.setSubText(subText)
        }

        if (!cancelling) {
            val cancelIntent = Intent(this, VideoExportNotificationService::class.java).apply {
                action = ACTION_CANCEL_FROM_NOTIFICATION
            }
            val cancelPendingIntent = PendingIntent.getService(
                this,
                REQUEST_CANCEL,
                cancelIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                builder.addAction(
                    Notification.Action.Builder(null, "取消导出", cancelPendingIntent).build()
                )
            } else {
                @Suppress("DEPRECATION")
                builder.addAction(0, "取消导出", cancelPendingIntent)
            }
        }
        return builder.build()
    }

    private fun acquireWakeLock() {
        try {
            wakeLock?.acquire(WAKE_LOCK_TIMEOUT_MS)
        } catch (_: Exception) {
        }
    }

    private fun releaseWakeLock() {
        try {
            val wl = wakeLock ?: return
            if (wl.isHeld) wl.release()
        } catch (_: Exception) {
        }
    }

    private fun stopForegroundCompat() {
        try {
            if (isForeground) {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } else {
                    @Suppress("DEPRECATION")
                    stopForeground(true)
                }
                isForeground = false
            }
        } catch (_: Exception) {
        }
    }

    private fun stopForegroundAndSelf() {
        releaseWakeLock()
        stopForegroundCompat()
        try {
            notificationManager.cancel(PROGRESS_NOTIFICATION_ID)
        } catch (_: Exception) {
        }
        stopSelf()
    }
}

object VideoExportNotificationBridge {
    @Volatile
    var onCancelRequested: (() -> Unit)? = null
}
