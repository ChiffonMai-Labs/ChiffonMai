package com.example.my_first_flutter_app

import android.app.ActivityManager
import android.app.ApplicationExitInfo
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.os.Build
import java.io.File
import java.io.PrintWriter
import java.io.StringWriter

/**
 * 崩溃记录。
 *
 * Java / Kotlin 崩溃当场写文件并发通知；引擎等原生崩溃和 ANR 时进程已经没了，
 * 只能在下次启动时查系统的退出记录（Android 11+）。日志由 Dart 在下次启动时导出。
 */
object CrashReporter {
    private const val PENDING_FILE = "pending_crash.txt"
    private const val PREFS = "crash_reporter"
    private const val KEY_LAST_EXIT = "last_exit_ms"
    private const val CHANNEL_ID = "com.example.my_first_flutter_app.channel.crash"
    private const val NOTIFICATION_ID = 2101
    private const val MAX_DETAIL = 20000
    private var installed = false

    fun install(context: Context) {
        if (installed) return
        installed = true
        val app = context.applicationContext
        val previous = Thread.getDefaultUncaughtExceptionHandler()
        Thread.setDefaultUncaughtExceptionHandler { thread, error ->
            // 这里任何失败都不能影响系统原本的崩溃处理。
            try {
                val stack = StringWriter().also { error.printStackTrace(PrintWriter(it)) }
                    .toString().take(MAX_DETAIL)
                File(app.filesDir, PENDING_FILE)
                    .writeText("${System.currentTimeMillis()}\n$stack")
                notify(app, "ChiffonMai 崩溃了", "重新打开后会自动导出日志")
            } catch (_: Throwable) {
            }
            previous?.uncaughtException(thread, error)
        }
    }

    /** 取走上次的崩溃记录，取一次即清除；没有时返回 null。 */
    fun takePending(context: Context): Map<String, String>? {
        val app = context.applicationContext
        var result: Map<String, String>? = null
        try {
            val file = File(app.filesDir, PENDING_FILE)
            if (file.exists()) {
                val text = file.readText()
                file.delete()
                result = mapOf(
                    "reason" to "应用崩溃",
                    "time" to text.substringBefore('\n'),
                    "detail" to text.substringAfter('\n', ""),
                )
            }
        } catch (_: Exception) {
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val exit = takeSystemExit(app)
                if (result == null) result = exit
            } catch (_: Exception) {
            }
        }
        return result
    }

    private fun takeSystemExit(app: Context): Map<String, String>? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) return null
        val prefs = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        // 第一次运行只记下时间，不把升级前的旧记录当成刚发生的崩溃。
        val last = prefs.getLong(KEY_LAST_EXIT, -1L)
        val manager = app.getSystemService(ActivityManager::class.java) ?: return null
        val exits = manager.getHistoricalProcessExitReasons(null, 0, 5)
        val newest = exits.maxOfOrNull { it.timestamp } ?: 0L
        prefs.edit()
            .putLong(KEY_LAST_EXIT, maxOf(newest, System.currentTimeMillis()))
            .apply()
        if (last < 0) return null
        val exit = exits.firstOrNull {
            it.timestamp > last && it.processName == app.packageName && reasonLabel(it.reason) != null
        } ?: return null
        return mapOf(
            "reason" to (reasonLabel(exit.reason) ?: "应用崩溃"),
            "time" to exit.timestamp.toString(),
            "detail" to (exit.description ?: ""),
        )
    }

    private fun reasonLabel(reason: Int): String? = when (reason) {
        ApplicationExitInfo.REASON_CRASH -> "应用崩溃"
        ApplicationExitInfo.REASON_CRASH_NATIVE -> "原生崩溃"
        ApplicationExitInfo.REASON_ANR -> "应用无响应"
        else -> null
    }

    /** 没有通知权限时系统会直接忽略。 */
    fun notify(context: Context, title: String, text: String) {
        val app = context.applicationContext
        val manager = app.getSystemService(NotificationManager::class.java) ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, NativeL10n.text(app, "崩溃提醒"), NotificationManager.IMPORTANCE_DEFAULT)
            )
        }
        val open = app.packageManager.getLaunchIntentForPackage(app.packageName)?.let {
            PendingIntent.getActivity(
                app,
                NOTIFICATION_ID,
                it,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        }
        @Suppress("DEPRECATION")
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(app, CHANNEL_ID)
        } else {
            Notification.Builder(app)
        }
        manager.notify(
            NOTIFICATION_ID,
            builder
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(NativeL10n.text(app, title))
                .setContentText(NativeL10n.text(app, text))
                .setContentIntent(open)
                .setAutoCancel(true)
                .build()
        )
    }
}
