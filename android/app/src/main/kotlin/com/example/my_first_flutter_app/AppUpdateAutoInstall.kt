package com.example.my_first_flutter_app

import android.app.Activity
import android.app.ActivityManager
import android.app.PendingIntent
import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageInstaller
import android.media.AudioManager
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.util.Log
import java.security.MessageDigest
import java.util.UUID
import java.util.concurrent.Executors
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference

/** 用户明确开启后，等待 App 在后台无任务持续 8 秒；不支持免确认时只通知。 */
object AppUpdateAutoInstall {
    private const val PREFS = "app_update_auto_install"
    private const val JOB = 42062
    private const val IDLE_DELAY_MS = 8_000L
    private const val RESULT_ACTION = "cloud.chiffonmai.app.AUTO_INSTALL_RESULT"
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())
    private val idleSince = AtomicLong(0)
    private val foregroundConsent = AtomicLong(-1)
    @Volatile private var foreground = false
    @Volatile private var taskBusy = false
    @Volatile private var appContext: Context? = null
    private val currentWork = AtomicReference<AtomicBoolean?>(null)
    private val idleCheck = Runnable { appContext?.let { checkIdleWindow(it) } }

    private fun prefs(context: Context) = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    fun enabled(context: Context) = Build.VERSION.SDK_INT >= 31 && prefs(context).getBoolean("enabled", false)
    fun settings(context: Context): Map<String, Any> = mapOf(
        "enabled" to enabled(context), "supported" to (Build.VERSION.SDK_INT >= 31),
        "canInstall" to (Build.VERSION.SDK_INT < 26 || context.packageManager.canRequestPackageInstalls()),
        "busy" to hasActiveTaskOrAudio(context))

    fun setEnabled(context: Context, value: Boolean): Map<String, Any> {
        require(!value || Build.VERSION.SDK_INT >= 31) { "自动安装测试功能需要 Android 12 及以上" }
        // 先同步更新授权状态，后台任务在提交安装前还会再次核对。
        check(prefs(context).edit().putBoolean("enabled", value).commit()) { "自动安装设置保存失败" }
        if (!value) {
            stop(context, "已关闭自动安装，可手动安装更新")
            AppUpdateDownloads.updateInstallState(context, null, null,
                "已关闭自动安装，可手动安装更新", null)
        }
        else {
            AppUpdateDownloads.updateInstallState(context, null, null,
                "更新已下载，等待 App 在后台无任务持续 8 秒后尝试自动安装", false)
            schedule(context)
        }
        return settings(context)
    }

    private fun hasActiveTaskOrAudio(context: Context): Boolean {
        val audio = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        return taskBusy || audio.isMusicActive || audio.mode != AudioManager.MODE_NORMAL
    }

    private fun inUse(context: Context): Boolean {
        val info = ActivityManager.RunningAppProcessInfo()
        ActivityManager.getMyMemoryState(info)
        return foreground || info.importance <= ActivityManager.RunningAppProcessInfo.IMPORTANCE_VISIBLE ||
            hasActiveTaskOrAudio(context)
    }

    /** 仅接收前台对话框的本次确认；先真实退到后台，之后仍复用完整安装校验。 */
    fun requestFromForeground(activity: Activity, downloadId: Long, build: Long): String {
        check(downloadId >= 0 && build > 0) { "安装任务信息不完整" }
        check(enabled(activity)) { "自动安装已关闭，请手动安装更新" }
        check(foreground && !hasActiveTaskOrAudio(activity)) { "请先结束正在进行的任务或播放后再更新" }
        check(activity.packageManager.canRequestPackageInstalls()) { "请先允许此来源安装应用" }
        val state = AppUpdateDownloads.installSnapshot(activity)
        check(state.optString("phase") == "ready" && !state.optBoolean("autoManualRequired") &&
            state.optLong("downloadId", -1) == downloadId && state.optLong("build", -1) == build) {
            "安装任务已变化，请重新查看更新状态"
        }
        foregroundConsent.set(downloadId)
        if (!activity.moveTaskToBack(true)) {
            foregroundConsent.set(-1)
            throw IllegalStateException("无法将应用退到后台，请稍后重试")
        }
        // 不自行修改 foreground，由 Activity.onStop 确认真正离开前台后才开始。
        schedule(activity)
        return "requested"
    }

    fun setForeground(context: Context, value: Boolean) {
        foreground = value
        idleSince.set(0)
        if (value) {
            // 新包首次启动时先核实成功结果，不能把旧会话重置成待安装后再读取。
            AppUpdateDownloads.state(context)
            stop(context, "更新已下载，等待 App 退到后台后再尝试自动安装")
        }
        else schedule(context)
    }

    fun setTaskBusy(context: Context, value: Boolean) {
        if (taskBusy == value) return
        taskBusy = value
        idleSince.set(0)
        if (value) stop(context, "更新已下载，等待当前任务结束后再尝试自动安装")
        else schedule(context)
    }

    fun schedule(context: Context) {
        appContext = context.applicationContext
        main.removeCallbacks(idleCheck)
        main.post(idleCheck)
    }

    private fun quietForDelay(context: Context): Boolean {
        val since = idleSince.get()
        return !inUse(context) && since > 0 && SystemClock.elapsedRealtime() - since >= IDLE_DELAY_MS
    }

    private fun allowedToInstall(context: Context, confirmedDownloadId: Long?): Boolean =
        !inUse(context) && (confirmedDownloadId != null || quietForDelay(context))

    /** Android 14 的安装约束接口只向当前安装来源或更新所有者开放，自更新不自动获得该权限。 */
    private fun canUseInstallConstraints(context: Context): Boolean {
        if (Build.VERSION.SDK_INT < 34) return false
        return runCatching {
            val source = context.packageManager.getInstallSourceInfo(context.packageName)
            source.installingPackageName == context.packageName ||
                source.updateOwnerPackageName == context.packageName
        }.getOrDefault(false)
    }

    private fun checkIdleWindow(context: Context) {
        if (!enabled(context) || foreground || taskBusy) {
            idleSince.set(0)
            return
        }
        val state = AppUpdateDownloads.installSnapshot(context)
        if (state.optString("phase") != "ready" || state.optBoolean("autoManualRequired")) return
        if (!context.packageManager.canRequestPackageInstalls()) return
        val consent = foregroundConsent.get()
        if (consent >= 0 && consent != state.optLong("downloadId", -1)) foregroundConsent.set(-1)
        if (consent >= 0 && consent == state.optLong("downloadId", -1) && !inUse(context)) {
            run(context, AtomicBoolean(false), consent) {}
            return
        }
        if (inUse(context)) idleSince.set(0)
        else idleSince.compareAndSet(0, SystemClock.elapsedRealtime())
        if (quietForDelay(context)) {
            run(context, AtomicBoolean(false)) {}
            return
        }
        // 存活进程用短计时器及时尝试；系统 Job 作为进程重建后的后备，不再等待整机空闲。
        val scheduler = context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler
        val pending = scheduler.getPendingJob(JOB)
        if (pending == null || pending.isRequireDeviceIdle) {
            scheduler.schedule(JobInfo.Builder(JOB, ComponentName(context, AppUpdateAutoInstallJob::class.java))
                .setMinimumLatency(IDLE_DELAY_MS)
                .setPersisted(true)
                .build())
        }
        main.postDelayed(idleCheck, 1_000L)
    }

    /** 取消尚未完成的安装会话；关闭开关不取消已下载文件和正常的下载任务。 */
    fun stop(context: Context, message: String) {
        (context.getSystemService(Context.JOB_SCHEDULER_SERVICE) as JobScheduler).cancel(JOB)
        main.removeCallbacks(idleCheck)
        idleSince.set(0)
        foregroundConsent.set(-1)
        currentWork.get()?.set(true)
        val stored = prefs(context)
        val session = stored.getInt("session", -1)
        val downloadId = stored.getLong("downloadId", -1)
        stored.edit().remove("session").remove("token").remove("downloadId").apply()
        if (session >= 0) {
            runCatching { context.packageManager.packageInstaller.abandonSession(session) }
            AppUpdateDownloads.updateInstallState(context, downloadId, "ready", message, false)
        }
    }

    fun recover(context: Context) {
        val stored = prefs(context)
        val id = stored.getInt("session", -1)
        if (id < 0 || currentWork.get() != null) return
        val info = context.packageManager.packageInstaller.getSessionInfo(id)
        if (info == null || !info.isSealed) stop(context, "上次自动安装未完成，可手动安装更新")
    }

    fun run(context: Context, stopped: AtomicBoolean, confirmedDownloadId: Long? = null, finished: () -> Unit) {
        if (!currentWork.compareAndSet(null, stopped)) {
            finished()
            return
        }
        if (confirmedDownloadId != null) foregroundConsent.compareAndSet(confirmedDownloadId, -1)
        executor.execute {
            try { install(context, stopped, confirmedDownloadId) }
            finally {
                currentWork.compareAndSet(stopped, null)
                finished()
                schedule(context)
            }
        }
    }

    private fun install(context: Context, stopped: AtomicBoolean, confirmedDownloadId: Long?) {
        if (Build.VERSION.SDK_INT < 31 || !enabled(context) || !allowedToInstall(context, confirmedDownloadId) || stopped.get()) return
        if (!context.packageManager.canRequestPackageInstalls()) return
        // 先清理已经安装的旧版本状态，避免升级后遗留的任务再次提交。
        AppUpdateDownloads.state(context)
        val candidate = AppUpdateDownloads.installSnapshot(context)
        if (candidate.optString("phase") != "ready" || candidate.optBoolean("autoManualRequired")) return
        val downloadId = candidate.optLong("downloadId", -1)
        if (confirmedDownloadId != null && confirmedDownloadId != downloadId) return
        val installer = context.packageManager.packageInstaller
        var sessionId = -1
        try {
            val file = AppUpdateInstaller.validate(context, candidate.optString("path"), candidate.optLong("build"))
            val archive = context.packageManager.getPackageArchiveInfo(file.path, 0)
                ?: throw IllegalArgumentException("安装包无法读取")
            val minTarget = when {
                Build.VERSION.SDK_INT >= 37 -> 35
                Build.VERSION.SDK_INT >= 36 -> 34
                Build.VERSION.SDK_INT >= 35 -> 33
                Build.VERSION.SDK_INT >= 34 -> 31
                Build.VERSION.SDK_INT >= 33 -> 30
                else -> 29
            }
            require((archive.applicationInfo?.targetSdkVersion ?: 0) >= minTarget) {
                "该安装包不满足当前系统的免确认要求，请手动安装"
            }
            val parameters = PackageInstaller.SessionParams(PackageInstaller.SessionParams.MODE_FULL_INSTALL).apply {
                setAppPackageName(context.packageName)
                setSize(file.length())
                setRequireUserAction(PackageInstaller.SessionParams.USER_ACTION_NOT_REQUIRED)
            }
            sessionId = installer.createSession(parameters)
            val token = UUID.randomUUID().toString()
            check(prefs(context).edit().putInt("session", sessionId).putString("token", token)
                .putLong("downloadId", downloadId).commit()) { "无法保存安装任务" }
            if (stopped.get() || !enabled(context) || !allowedToInstall(context, confirmedDownloadId) ||
                !AppUpdateDownloads.updateInstallState(context, downloadId, "installing", "正在准备自动安装更新…", null))
                throw InterruptedException()
            installer.openSession(sessionId).use { session ->
                val digest = MessageDigest.getInstance("SHA-256")
                file.inputStream().buffered().use { input ->
                    session.openWrite("base.apk", 0, file.length()).use { output ->
                        val buffer = ByteArray(64 * 1024)
                        while (true) {
                            if (stopped.get() || !enabled(context) || foreground || taskBusy) throw InterruptedException()
                            val count = input.read(buffer)
                            if (count < 0) break
                            digest.update(buffer, 0, count)
                            output.write(buffer, 0, count)
                        }
                        session.fsync(output)
                    }
                }
                val hash = digest.digest().joinToString("") { "%02x".format(it.toInt() and 0xff) }
                require(hash == candidate.optString("sha256")) { "安装包校验失败，请重新下载" }
                if (stopped.get() || !enabled(context) || !allowedToInstall(context, confirmedDownloadId) ||
                    prefs(context).getString("token", null) != token) throw InterruptedException()
                val intent = Intent(context, AppUpdateInstallReceiver::class.java)
                    .setAction(RESULT_ACTION).setData(Uri.parse("chiffonmai-update://install/$token"))
                    .putExtra("token", token).putExtra("session", sessionId)
                val status = PendingIntent.getBroadcast(context, sessionId, intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE).intentSender
                fun commitSelfUpdate() {
                    // 直接提交也必须重新核对后台窗口和本次会话，不能绕过用户开关及任务保护。
                    if (stopped.get() || !enabled(context) || !allowedToInstall(context, confirmedDownloadId) ||
                        !context.packageManager.canRequestPackageInstalls() ||
                        prefs(context).getString("token", null) != token) throw InterruptedException()
                    session.commit(status)
                }
                if (Build.VERSION.SDK_INT >= 34 && canUseInstallConstraints(context)) {
                    // 系统再次确认本应用不可见、没有音视频或网络交互且未在通话；不要求整机空闲。
                    val constraints = PackageInstaller.InstallConstraints.Builder()
                        .setAppNotForegroundRequired().setAppNotInteractingRequired()
                        .setNotInCallRequired().build()
                    try {
                        installer.commitSessionAfterInstallConstraintsAreMet(sessionId, status, constraints, 10 * 60 * 1000L)
                    } catch (error: SecurityException) {
                        // 安装来源可能变化，或 ROM 额外限制该接口；标准自更新提交仍由系统核验权限。
                        Log.w("AppUpdateAutoInstall", "安装约束接口拒绝访问，改用标准自更新提交", error)
                        commitSelfUpdate()
                    }
                } else {
                    Log.i("AppUpdateAutoInstall", "使用标准自更新提交，保留应用后台与任务检查")
                    commitSelfUpdate()
                }
            }
        } catch (_: InterruptedException) {
            if (sessionId >= 0) runCatching { installer.abandonSession(sessionId) }
            clearSession(context, sessionId)
            AppUpdateDownloads.updateInstallState(context, downloadId, "ready", "更新已下载，等待 App 在后台无任务持续 8 秒后再安装", false)
        } catch (error: Exception) {
            if (sessionId >= 0) runCatching { installer.abandonSession(sessionId) }
            clearSession(context, sessionId)
            // abandonSession 可能先触发写流异常；正常暂停不能因此被误判为必须手动安装。
            if (stopped.get() || !enabled(context) || foreground || taskBusy) {
                AppUpdateDownloads.updateInstallState(context, downloadId, "ready",
                    "更新已下载，等待 App 在后台无任务持续 8 秒后再安装", false)
            } else if (AppUpdateDownloads.updateInstallState(context, downloadId, "ready",
                "自动安装未完成：${error.message ?: "系统暂不支持"}，可手动安装", true))
                AppUpdateDownloads.notifyInstallReady(context)
        }
    }

    private fun clearSession(context: Context, id: Int) {
        val stored = prefs(context)
        if (stored.getInt("session", -1) == id) stored.edit()
            .remove("session").remove("token").remove("downloadId").apply()
    }

    fun result(context: Context, intent: Intent) {
        if (intent.action != RESULT_ACTION) return
        val stored = prefs(context)
        val sessionId = intent.getIntExtra("session", -1)
        if (sessionId < 0 || sessionId != stored.getInt("session", -1) ||
            intent.getStringExtra("token") != stored.getString("token", null)) return
        val downloadId = stored.getLong("downloadId", -1)
        val status = intent.getIntExtra(PackageInstaller.EXTRA_STATUS, PackageInstaller.STATUS_FAILURE)
        clearSession(context, sessionId)
        if (status == PackageInstaller.STATUS_SUCCESS) {
            AppUpdateDownloads.state(context) // 清理已经安装版本的文件和任务记录。
            return
        }
        runCatching { context.packageManager.packageInstaller.abandonSession(sessionId) }
        val message = if (status == PackageInstaller.STATUS_PENDING_USER_ACTION)
            "系统需要你确认安装，请点按后手动安装更新" else "自动安装未完成，可手动安装更新"
        if (AppUpdateDownloads.updateInstallState(context, downloadId, "ready", message, true))
            AppUpdateDownloads.notifyInstallReady(context)
    }
}

class AppUpdateAutoInstallJob : JobService() {
    private var stopped = AtomicBoolean(false)
    override fun onStartJob(params: JobParameters): Boolean {
        stopped = AtomicBoolean(false)
        AppUpdateAutoInstall.run(applicationContext, stopped) {
            jobFinished(params, false) // 未满足条件时由应用自己的 8 秒窗口重新调度。
        }
        return true
    }
    override fun onStopJob(params: JobParameters): Boolean {
        stopped.set(true)
        return false // 条件恢复后重新计时，避免系统退避策略拉长应用内的空闲窗口。
    }
}

class AppUpdateInstallReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_MY_PACKAGE_REPLACED) {
            // 旧进程可能随覆盖安装结束，由新包核实安装结果并尝试通知。
            AppUpdateDownloads.state(context)
        } else {
            AppUpdateAutoInstall.result(context, intent)
        }
    }
}
