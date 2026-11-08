package com.example.my_first_flutter_app

import android.app.DownloadManager
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Environment
import org.json.JSONArray
import org.json.JSONObject
import java.io.File
import java.security.MessageDigest
import java.util.concurrent.Executors

/** 系统下载管理器持有任务，Flutter 页面销毁和切后台都不会取消下载。 */
object AppUpdateDownloads {
    const val EXTRA_OPEN_UPDATE = "open_app_update"
    private const val PREFS = "app_update_download"
    private const val AUTO_INSTALL_SUCCESS = "autoInstallSuccess"
    private const val NOTICE = 42061
    private val worker = Executors.newSingleThreadExecutor()
    private val processing = mutableSetOf<Long>()
    private val completionCallbacks = mutableMapOf<Long, MutableList<() -> Unit>>()

    private fun manager(context: Context) = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager
    private fun read(context: Context) = JSONObject(context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        .getString("state", "{}") ?: "{}")
    private fun save(context: Context, state: JSONObject) {
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString("state", state.toString()).apply()
    }

    @Synchronized
    fun installSnapshot(context: Context): JSONObject = read(context)

    /** 只更新仍属于同一次下载的安装状态，迟到的安装回调不能覆盖新任务。 */
    @Synchronized
    fun updateInstallState(context: Context, downloadId: Long?, phase: String?,
                           message: String?, manualRequired: Boolean?): Boolean {
        val state = read(context)
        if (downloadId != null && state.optLong("downloadId", -1) != downloadId) return false
        if (state.optString("phase") !in listOf("ready", "installing")) return false
        if (phase != null) state.put("phase", phase)
        if (message != null) state.put("message", message)
        if (manualRequired != null) state.put("autoManualRequired", manualRequired)
        save(context, state)
        return true
    }

    fun notifyInstallReady(context: Context) = notify(context, true)
    fun target(context: Context): File {
        val root = context.getExternalFilesDir(Environment.DIRECTORY_DOWNLOADS)
            ?: throw IllegalStateException("更新下载目录不可用")
        return File(root, "app_updates/update.apk")
    }

    @Synchronized
    fun start(context: Context, args: Map<*, *>): String {
        val existing = JSONObject(state(context))
        if (existing.optString("phase") in listOf("downloading", "verifying", "installing")) return existing.toString()
        val urls = (args["urls"] as? List<*>)?.filterIsInstance<String>() ?: emptyList()
        require(urls.isNotEmpty() && urls.size <= 4 && urls.all {
            val uri = Uri.parse(it)
            uri.scheme == "https" && !uri.host.isNullOrBlank() && uri.userInfo == null
        }) { "下载地址无效" }
        val size = (args["size"] as? Number)?.toLong() ?: 0
        val build = (args["build"] as? Number)?.toLong() ?: 0
        val digest = args["sha256"] as? String ?: ""
        require(size in 1..(300L * 1024 * 1024) && build > 0 &&
            digest.matches(Regex("[a-f0-9]{64}"))) { "安装包校验信息无效" }
        val state = JSONObject().put("urls", JSONArray(urls)).put("size", size)
            .put("build", build).put("sha256", digest).put("version", args["version"])
            .put("updateLog", (args["updateLog"] as? String).orEmpty().take(32768))
            .put("sourceIndex", 0)
        AppUpdateAutoInstall.stop(context, "已切换更新任务")
        remove(context, existing)
        context.getSystemService(NotificationManager::class.java)?.cancel(NOTICE)
        enqueue(context, state)
        return state.toString()
    }

    private fun enqueue(context: Context, state: JSONObject) {
        val file = target(context)
        file.parentFile?.mkdirs()
        if (file.exists()) check(file.delete()) { "无法清理上次的更新文件" }
        val urls = state.getJSONArray("urls")
        val request = DownloadManager.Request(Uri.parse(urls.getString(state.getInt("sourceIndex"))))
            .setTitle(NativeL10n.text(context, "ChiffonMai v${state.optString("version")} 更新"))
            .setDescription(NativeL10n.text(context, "后台下载中，可继续使用 App"))
            .setMimeType("application/vnd.android.package-archive")
            .setNotificationVisibility(DownloadManager.Request.VISIBILITY_VISIBLE)
            .setAllowedOverRoaming(false)
            .setDestinationInExternalFilesDir(context, Environment.DIRECTORY_DOWNLOADS, "app_updates/update.apk")
            .addRequestHeader("User-Agent", "ChiffonMai-Updater")
        val id = manager(context).enqueue(request)
        state.put("downloadId", id).put("phase", "downloading")
            .put("message", "正在后台下载更新…").put("received", 0).put("total", state.getLong("size"))
            .remove("path")
        save(context, state)
    }

    @Synchronized
    fun state(context: Context): String {
        val state = read(context)
        val installed = context.packageManager.getPackageInfo(context.packageName, 0)
        @Suppress("DEPRECATION")
        val installedBuild = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
            installed.longVersionCode else installed.versionCode.toLong()
        // 覆盖安装会保留偏好，已安装的版本不能在下次启动时继续提示安装。
        if (state.optLong("build") in 1..installedBuild) {
            val automatic = state.optString("phase") == "installing" && state.optLong("build") == installedBuild
            val editor = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().remove("state")
            if (automatic) {
                // 成功记录独立于下载任务，覆盖安装结束旧进程或错过广播后仍能在首次启动时读取。
                val success = JSONObject()
                    .put("id", "${state.optLong("downloadId", -1)}:$installedBuild")
                    .put("version", installed.versionName ?: state.optString("version"))
                    .put("build", installedBuild).put("updateLog", state.optString("updateLog"))
                editor.putString(AUTO_INSTALL_SUCCESS, success.toString())
            }
            check(editor.commit()) { "无法保存更新完成状态" }
            remove(context, state)
            context.getSystemService(NotificationManager::class.java)?.cancel(NOTICE)
            if (automatic) {
                notify(context, false, state.optString("version"))
            }
            return "{}"
        }
        val phase = state.optString("phase")
        if (phase == "ready" && !target(context).isFile) {
            state.put("phase", "failed").put("message", "安装包已被清理，请重新下载")
            save(context, state)
        }
        if (phase !in listOf("downloading", "verifying")) return state.toString()
        val id = state.optLong("downloadId", -1)
        manager(context).query(DownloadManager.Query().setFilterById(id)).use { cursor ->
            if (!cursor.moveToFirst()) {
                state.put("phase", "cancelled").put("message", "下载已取消")
                save(context, state)
            } else {
                val status = cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))
                state.put("received", cursor.getLong(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR)))
                if (status == DownloadManager.STATUS_PAUSED) state.put("message", "等待网络或系统继续下载…")
                if (status == DownloadManager.STATUS_SUCCESSFUL || status == DownloadManager.STATUS_FAILED) complete(context, id)
            }
        }
        return state.toString()
    }

    @Synchronized
    fun pendingAutoInstallSuccess(context: Context): String? {
        state(context)
        return context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(AUTO_INSTALL_SUCCESS, null)
    }

    /** 确认已经展示的那一次成功记录，不能清掉后来产生的新记录。 */
    @Synchronized
    fun acknowledgeAutoInstallSuccess(context: Context, id: String): Boolean {
        val stored = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val raw = stored.getString(AUTO_INSTALL_SUCCESS, null) ?: return true
        if (JSONObject(raw).optString("id") != id) return false
        return stored.edit().remove(AUTO_INSTALL_SUCCESS).commit()
    }

    @Synchronized
    fun cancel(context: Context): String {
        AppUpdateAutoInstall.stop(context, "已取消自动安装")
        val state = read(context)
        remove(context, state)
        state.put("phase", "cancelled").put("message", "下载已取消").remove("path")
        save(context, state)
        context.getSystemService(NotificationManager::class.java)?.cancel(NOTICE)
        return state.toString()
    }

    fun retry(context: Context): String {
        val state = read(context)
        val urls = state.optJSONArray("urls") ?: throw IllegalStateException("请重新检查更新后下载")
        return start(context, mapOf("urls" to (0 until urls.length()).map { urls.getString(it) },
            "size" to state.optLong("size"), "sha256" to state.optString("sha256"),
            "version" to state.optString("version"), "build" to state.optLong("build"),
            "updateLog" to state.optString("updateLog")))
    }

    private fun remove(context: Context, state: JSONObject) {
        val id = state.optLong("downloadId", -1)
        if (id >= 0) manager(context).remove(id)
    }

    /** 完成广播可能在 App 已退出时到达；校验在工作线程中进行，不启动 Flutter 页面。 */
    @Synchronized
    fun complete(context: Context, id: Long, finished: (() -> Unit)? = null) {
        if (read(context).optLong("downloadId", -1) != id) { finished?.invoke(); return }
        if (finished != null) completionCallbacks.getOrPut(id) { mutableListOf() }.add(finished)
        if (!processing.add(id)) return
        worker.execute {
            try { verifyCompleted(context.applicationContext, id) }
            finally {
                val callbacks = synchronized(this) { processing.remove(id); completionCallbacks.remove(id) }
                callbacks?.forEach { it.invoke() }
            }
        }
    }

    private fun verifyCompleted(context: Context, id: Long) {
        var packageValidation = false
        try {
            val snapshot = synchronized(this) {
                val state = read(context)
                if (state.optLong("downloadId", -1) != id ||
                    state.optString("phase") !in listOf("downloading", "verifying")) return
                manager(context).query(DownloadManager.Query().setFilterById(id)).use { cursor ->
                    if (!cursor.moveToFirst()) return
                    when (cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))) {
                        DownloadManager.STATUS_FAILED -> throw IllegalStateException("下载失败")
                        DownloadManager.STATUS_SUCCESSFUL -> Unit
                        else -> return
                    }
                }
                state.put("phase", "verifying").put("message", "正在后台校验安装包…")
                save(context, state)
                JSONObject(state.toString())
            }
            val file = target(context)
            require(file.length() == snapshot.getLong("size")) { "安装包下载不完整" }
            val digest = MessageDigest.getInstance("SHA-256")
            file.inputStream().buffered().use { input ->
                val buffer = ByteArray(64 * 1024)
                while (true) {
                    val count = input.read(buffer)
                    if (count < 0) break
                    digest.update(buffer, 0, count)
                }
            }
            val hash = digest.digest().joinToString("") { "%02x".format(it.toInt() and 0xff) }
            require(hash == snapshot.getString("sha256")) { "安装包完整性校验失败" }
            packageValidation = true
            AppUpdateInstaller.validate(context, file.path, snapshot.getLong("build"))
            synchronized(this) {
                val current = read(context)
                if (current.optLong("downloadId", -1) != id || current.optString("phase") != "verifying") return
                current.put("phase", "ready").put("path", file.path)
                    .put("received", file.length()).put("message", if (AppUpdateAutoInstall.enabled(context))
                        "更新已下载，等待 App 在后台无任务持续 8 秒后尝试自动安装" else "更新已下载，可在方便时安装")
                save(context, current)
                notify(context, true)
            }
            AppUpdateAutoInstall.schedule(context)
        } catch (error: Exception) {
            synchronized(this) {
                val state = read(context)
                if (state.optLong("downloadId", -1) != id ||
                    state.optString("phase") !in listOf("downloading", "verifying")) return
                remove(context, state)
                val next = state.optInt("sourceIndex") + 1
                if (!packageValidation && next < state.getJSONArray("urls").length()) {
                    state.put("sourceIndex", next)
                    try { enqueue(context, state); return } catch (_: Exception) { }
                }
                state.put("phase", "failed").put("message", error.message ?: "更新下载失败，请重试")
                    .remove("path")
                save(context, state)
                notify(context, false)
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun notify(context: Context, ready: Boolean, installedVersion: String? = null) {
        try {
            val manager = context.getSystemService(NotificationManager::class.java) ?: return
            val channel = "com.example.my_first_flutter_app.channel.app_update"
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) manager.createNotificationChannel(
                NotificationChannel(channel, NativeL10n.text(context, "应用更新"), NotificationManager.IMPORTANCE_LOW))
            val intent = Intent(context, MainActivity::class.java)
                .addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            if (installedVersion == null) intent.putExtra(EXTRA_OPEN_UPDATE, true)
            val open = PendingIntent.getActivity(context, NOTICE, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) Notification.Builder(context, channel)
                else Notification.Builder(context)
            val localized = NativeL10n.localizedContext(context)
            val title = if (installedVersion != null) localized.getString(R.string.app_update_installed_title)
                else NativeL10n.text(context, if (ready) "ChiffonMai 更新已下载" else "ChiffonMai 更新下载失败")
            val message = if (installedVersion != null) localized.getString(R.string.app_update_installed_message, installedVersion)
                else NativeL10n.text(context, if (ready) read(context).optString("message", "点按后选择安装") else "点按查看详情或重新下载")
            manager.notify(NOTICE, builder.setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle(title)
                .setContentText(message)
                .setOnlyAlertOnce(true).setAutoCancel(true).setContentIntent(open).build())
        } catch (_: Exception) { /* 通知未授权时仍可在 App 内查看任务。 */ }
    }
}

class AppUpdateDownloadReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != DownloadManager.ACTION_DOWNLOAD_COMPLETE) return
        val id = intent.getLongExtra(DownloadManager.EXTRA_DOWNLOAD_ID, -1)
        if (id < 0) return
        val pending = goAsync()
        AppUpdateDownloads.complete(context, id) { pending.finish() }
    }
}
