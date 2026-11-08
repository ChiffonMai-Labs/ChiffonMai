package com.example.my_first_flutter_app

import android.app.Activity
import android.content.Intent
import android.content.Context
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

/** 只允许本应用缓存目录中的同包名、同签名、指定版本 APK 进入系统安装器。 */
class AppUpdateInstaller(private val activity: Activity) {
    private var channel: MethodChannel? = null
    fun notifyIntent() {
        if (activity.intent?.getBooleanExtra(AppUpdateDownloads.EXTRA_OPEN_UPDATE, false) == true)
            channel?.invokeMethod("onUpdateAction", null)
    }
    fun register(engine: FlutterEngine) {
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, "com.example.app/app_update")
        channel!!
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "supportedAbis" -> result.success(Build.SUPPORTED_ABIS.toList())
                        "setAppTaskBusy" -> {
                            AppUpdateAutoInstall.setTaskBusy(activity, call.argument<Boolean>("busy") ?: true)
                            result.success(null)
                        }
                        "startBackgroundDownload" -> result.success(AppUpdateDownloads.start(activity,
                            call.arguments as? Map<*, *> ?: emptyMap<Any, Any>()))
                        "getUpdateState" -> {
                            // 先确认覆盖安装结果，避免恢复旧会话时把成功状态改回待安装。
                            AppUpdateDownloads.state(activity)
                            AppUpdateAutoInstall.recover(activity)
                            result.success(AppUpdateDownloads.state(activity))
                        }
                        "getPendingAutoInstallSuccess" -> result.success(AppUpdateDownloads.pendingAutoInstallSuccess(activity))
                        "acknowledgeAutoInstallSuccess" -> result.success(AppUpdateDownloads.acknowledgeAutoInstallSuccess(activity,
                            call.argument<String>("id") ?: ""))
                        "getAutoInstallSettings" -> result.success(AppUpdateAutoInstall.settings(activity))
                        "requestForegroundInstall" -> result.success(AppUpdateAutoInstall.requestFromForeground(activity,
                            call.argument<Number>("downloadId")?.toLong() ?: -1,
                            call.argument<Number>("build")?.toLong() ?: -1))
                        "setAutoInstallEnabled" -> result.success(AppUpdateAutoInstall.setEnabled(activity,
                            call.argument<Boolean>("enabled") ?: false))
                        "cancelBackgroundDownload" -> result.success(AppUpdateDownloads.cancel(activity))
                        "retryBackgroundDownload" -> result.success(AppUpdateDownloads.retry(activity))
                        "takePendingUpdateAction" -> {
                            val pending = activity.intent?.getBooleanExtra(AppUpdateDownloads.EXTRA_OPEN_UPDATE, false) == true
                            activity.intent?.removeExtra(AppUpdateDownloads.EXTRA_OPEN_UPDATE)
                            result.success(pending)
                        }
                        "openInstallSettings" -> {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                activity.startActivity(Intent(Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                                    Uri.parse("package:${activity.packageName}")))
                            }
                            result.success(null)
                        }
                        "validateApk", "installApk" -> {
                            val file = validate(activity, call.argument<String>("path"),
                                call.argument<Number>("build")?.toLong())
                            if (call.method == "validateApk") {
                                result.success(true)
                            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
                                !activity.packageManager.canRequestPackageInstalls()) {
                                result.success("permission_required")
                            } else {
                                AppUpdateAutoInstall.stop(activity, "已改为手动安装更新")
                                AppUpdateDownloads.updateInstallState(activity, null, null, null, true)
                                val uri = FileProvider.getUriForFile(activity,
                                    "${activity.packageName}.app_update", file)
                                activity.startActivity(Intent(Intent.ACTION_VIEW).apply {
                                    setDataAndType(uri, "application/vnd.android.package-archive")
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                })
                                result.success("launched")
                            }
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("APP_UPDATE_FAILED", NativeL10n.text(activity, error.message ?: "无法准备安装更新"), null)
                }
            }
    }

    companion object {
    @Suppress("DEPRECATION")
    fun validate(context: Context, path: String?, expectedBuild: Long?): File {
        require(!path.isNullOrBlank() && expectedBuild != null) { "安装包信息缺失" }
        val directory = File(context.cacheDir, "app_updates").canonicalFile
        val file = File(path).canonicalFile
        require((file.parentFile == directory || file == AppUpdateDownloads.target(context).canonicalFile) &&
            file.name == "update.apk" && file.isFile) {
            "安装包不在更新缓存目录中"
        }
        val manager = context.packageManager
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
            PackageManager.GET_SIGNING_CERTIFICATES else PackageManager.GET_SIGNATURES
        val archive = manager.getPackageArchiveInfo(file.path, flags)
            ?: throw IllegalArgumentException("下载的文件不是有效 APK")
        val installed = manager.getPackageInfo(context.packageName, flags)
        require(archive.packageName == context.packageName) { "安装包不属于 ChiffonMai" }
        fun version(info: PackageInfo): Long = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
            info.longVersionCode else info.versionCode.toLong()
        require(version(archive) == expectedBuild && version(archive) > version(installed)) {
            "安装包版本与待更新版本不匹配，请使用网页下载"
        }
        fun signers(info: PackageInfo): Set<String> {
            val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P)
                info.signingInfo?.apkContentsSigners else info.signatures
            return signatures?.map { signature ->
                MessageDigest.getInstance("SHA-256").digest(signature.toByteArray())
                    .joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }
            }?.toSet() ?: emptySet()
        }
        val currentSigners = signers(installed)
        require(currentSigners.isNotEmpty() && signers(archive) == currentSigners) {
            "安装包签名不匹配，已停止安装"
        }
        return file
    }
    }
}
