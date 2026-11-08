package com.example.my_first_flutter_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.BitmapShader
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.graphics.RectF
import android.graphics.Shader
import android.os.Bundle
import android.view.View
import android.widget.RemoteViews
import java.io.File
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.util.Calendar
import kotlin.concurrent.thread

/**
 * 桌面小组件。
 *
 * ## 数据从哪来
 *
 * * Rating 和自动同步：由 App 打开时通过 `com.example.app/home_widget` 通道推过来，
 *   存在 [HomeWidgetStore]。它们要用账号凭据，原生侧不碰，所以 App 没打开时显示的是上一次的结果。
 * * 舞萌状态：公开接口，系统每 30 分钟触发一次 [BaseHomeWidget.onUpdate] 时原生侧自己取。
 *
 * ## 为什么不用现成的插件
 *
 * 需要的只是几个 RemoteViews 和一个通道，不值得多加一个依赖。
 */
object HomeWidgetStore {
    private const val PREFS = "home_widget"
    private const val STATUS_URL = "https://mai.chongxi.us/api/bot"
    private const val MIN_FETCH_GAP_MS = 10 * 60 * 1000L

    /** 头像位图的边长。要随 RemoteViews 过 Binder，不用太大。 */
    private const val AVATAR_PX = 132

    private var cachedAvatarPath: String? = null
    private var cachedAvatar: Bitmap? = null

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    /** App 推来的数据，只覆盖传了的键。 */
    fun write(context: Context, values: Map<String, Any?>) {
        val store = prefs(context)
        val editor = store.edit()
        val newRating = values["rating"] as? String
        // 数字变了才算更新时间，否则每次打开 App 都会显示「刚刚更新」
        if (newRating != null && newRating != store.getString("rating", null)) {
            editor.putLong("rating_ms", System.currentTimeMillis())
        }
        for ((key, value) in values) {
            when (value) {
                is String -> editor.putString(key, value)
                is Int -> editor.putLong(key, value.toLong())
                is Long -> editor.putLong(key, value)
                null -> editor.remove(key)
            }
        }
        editor.apply()
    }

    /** 取舞萌状态。网络线程里调用，失败时保留上一次的结果。 */
    fun fetchServerStatus(context: Context) {
        val store = prefs(context)
        val now = System.currentTimeMillis()
        if (now - store.getLong("server_fetch_ms", 0) < MIN_FETCH_GAP_MS) return
        var connection: HttpURLConnection? = null
        try {
            connection = URL(STATUS_URL).openConnection() as HttpURLConnection
            connection.connectTimeout = 6000
            connection.readTimeout = 6000
            if (connection.responseCode != 200) return
            val body = connection.inputStream.bufferedReader().use { it.readText() }
            val json = JSONObject(body)
            val services = json.optJSONArray("services")
            var healthy = 0
            val total = services?.length() ?: 0
            for (i in 0 until total) {
                val state = services!!.optJSONObject(i)?.optString("state")
                if (state == "ok" || state == "normal" || state == "up") healthy++
            }
            val latency = json.optJSONObject("latency")
            val parts = mutableListOf<String>()
            if (total > 0) parts.add("$healthy/$total 正常")
            val load = latency?.optString("load_text").orEmpty()
            val ms = latency?.opt("current_ms") as? Number
            val speed = listOfNotNull(
                load.ifEmpty { null },
                ms?.let { "${it.toInt()} ms" }
            ).joinToString(" ")
            if (speed.isNotEmpty()) parts.add(speed)
            store.edit()
                .putString("server", json.optString("verdict_text").ifEmpty { "暂时未知" })
                .putString("server_detail", parts.joinToString(" · "))
                .putString(
                    "server_tone",
                    if (json.optString("status") == "normal") "ok" else "warn"
                )
                .putLong("server_fetch_ms", now)
                .apply()
        } catch (e: Exception) {
            android.util.Log.w("HomeWidget", "取舞萌状态失败: $e")
        } finally {
            connection?.disconnect()
        }
    }

    private fun timeLabel(context: Context, ms: Long): String {
        val time = Calendar.getInstance().apply { timeInMillis = ms }
        val now = Calendar.getInstance()
        val clock = "%02d:%02d".format(
            time.get(Calendar.HOUR_OF_DAY),
            time.get(Calendar.MINUTE)
        )
        val sameDay = time.get(Calendar.YEAR) == now.get(Calendar.YEAR) &&
            time.get(Calendar.DAY_OF_YEAR) == now.get(Calendar.DAY_OF_YEAR)
        return if (sameDay) {
            NativeL10n.text(context, "今天 $clock")
        } else {
            NativeL10n.text(context, "${time.get(Calendar.MONTH) + 1}月${time.get(Calendar.DAY_OF_MONTH)}日 $clock")
        }
    }

    /** 裁成和 App 里一样的圆角方形（圆角 = 边长的 1/6）。 */
    private fun loadAvatar(path: String?): Bitmap? {
        if (path.isNullOrEmpty()) return null
        if (path == cachedAvatarPath) return cachedAvatar
        val result = try {
            val source = if (File(path).exists()) BitmapFactory.decodeFile(path) else null
            source?.let {
                val output =
                    Bitmap.createBitmap(AVATAR_PX, AVATAR_PX, Bitmap.Config.ARGB_8888)
                val scale = maxOf(AVATAR_PX / it.width.toFloat(), AVATAR_PX / it.height.toFloat())
                val matrix = Matrix().apply {
                    setScale(scale, scale)
                    postTranslate(
                        (AVATAR_PX - it.width * scale) / 2f,
                        (AVATAR_PX - it.height * scale) / 2f
                    )
                }
                val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG).apply {
                    shader = BitmapShader(it, Shader.TileMode.CLAMP, Shader.TileMode.CLAMP)
                        .also { s -> s.setLocalMatrix(matrix) }
                }
                val size = AVATAR_PX.toFloat()
                Canvas(output).drawRoundRect(RectF(0f, 0f, size, size), size / 6, size / 6, paint)
                output
            }
        } catch (e: Exception) {
            android.util.Log.w("HomeWidget", "读取头像失败: $e")
            null
        }
        cachedAvatarPath = path
        cachedAvatar = result
        return result
    }

    private fun toneColor(context: Context, tone: String?): Int = context.getColor(
        when (tone) {
            "ok" -> R.color.widget_ok
            "warn" -> R.color.widget_warn
            "error" -> R.color.widget_error
            "active" -> R.color.widget_primary
            else -> R.color.widget_off
        }
    )

    private fun setDot(context: Context, views: RemoteViews, id: Int, tone: String?) {
        views.setInt(id, "setColorFilter", toneColor(context, tone))
    }

    /** 点击后打开 App；[action] 是要打开的功能名，交给 Dart 处理。 */
    private fun openIntent(context: Context, action: String?): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
            if (action != null) putExtra(MainActivity.EXTRA_WIDGET_ACTION, action)
        }
        return PendingIntent.getActivity(
            context,
            action?.hashCode() ?: 0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    /** 四种布局的控件 ID 共用，某个布局没有的控件 RemoteViews 会直接跳过。 */
    private fun build(context: Context, layout: Int, options: Bundle): RemoteViews {
        val store = prefs(context)
        val views = RemoteViews(context.packageName, layout)
        val labels = when (layout) {
            R.layout.home_widget_large -> listOf(R.id.w_server to R.string.native_text_58, R.id.w_sync_title to R.string.native_text_72, R.id.w_btn_sync to R.string.native_text_73, R.id.w_btn_ocr to R.string.native_text_74, R.id.w_btn_player to R.string.native_text_68)
            R.layout.home_widget_medium -> listOf(R.id.w_label_w_server_dot to R.string.native_text_75, R.id.w_server to R.string.native_text_58, R.id.w_server_detail to R.string.native_text_61, R.id.w_label_w_sync_dot to R.string.native_text_72, R.id.w_sync to R.string.native_text_58, R.id.w_sync_detail to R.string.native_text_61)
            R.layout.home_widget_rating -> listOf(R.id.w_rating_note to R.string.native_text_59)
            R.layout.home_widget_status -> listOf(R.id.w_label_w_server_dot to R.string.native_text_75, R.id.w_server to R.string.native_text_58, R.id.w_server_detail to R.string.native_text_61, R.id.w_label_w_sync_dot to R.string.native_text_72, R.id.w_sync to R.string.native_text_58, R.id.w_sync_detail to R.string.native_text_61)
            else -> emptyList()
        }
        for ((view, text) in labels) views.setTextViewText(view, NativeL10n.localizedContext(context).getString(text))

        views.setTextViewText(R.id.w_nickname, store.getString("nickname", "ChiffonMai"))
        val avatar = loadAvatar(store.getString("avatar_path", null))
        if (avatar != null) {
            views.setImageViewBitmap(R.id.w_avatar, avatar)
        } else {
            views.setImageViewResource(R.id.w_avatar, R.mipmap.ic_launcher)
        }

        val rating = store.getString("rating", null)
        val b35 = store.getLong("b35", 0)
        val b15 = store.getLong("b15", 0)
        val hasRating = !rating.isNullOrEmpty() && rating != "0"
        views.setTextViewText(R.id.w_rating, if (hasRating) rating else "--")
        views.setTextViewText(R.id.w_b35, "B35 ${if (hasRating) b35 else "-"}")
        views.setTextViewText(R.id.w_b15, "B15 ${if (hasRating) b15 else "-"}")
        views.setProgressBar(
            R.id.w_rating_bar,
            100,
            if (b35 + b15 > 0) (b35 * 100 / (b35 + b15)).toInt() else 0,
            false
        )
        val ratingMs = store.getLong("rating_ms", 0)
        views.setTextViewText(
            R.id.w_rating_note,
            NativeL10n.text(context, if (hasRating && ratingMs > 0) "${timeLabel(context, ratingMs)} 更新" else "打开 App 刷新数据")
        )

        views.setTextViewText(R.id.w_server, NativeL10n.text(context, store.getString("server", "暂时未知").orEmpty()))
        views.setTextViewText(
            R.id.w_server_detail,
            NativeL10n.text(context, store.getString("server_detail", "联网后自动更新").orEmpty())
        )
        setDot(context, views, R.id.w_server_dot, store.getString("server_tone", null))

        val syncMs = store.getLong("sync_ms", 0)
        val syncTime = if (syncMs > 0) timeLabel(context, syncMs) else ""
        val syncDetail = NativeL10n.text(context, store.getString("sync_detail", "打开 App 更新").orEmpty())
        views.setTextViewText(R.id.w_sync, NativeL10n.text(context, store.getString("sync", "暂时未知").orEmpty()))
        views.setTextViewText(
            R.id.w_sync_detail,
            listOf(syncDetail, syncTime).filter { it.isNotEmpty() }.joinToString(" · ")
        )
        views.setTextViewText(
            R.id.w_sync_time,
            syncTime.ifEmpty { store.getString("sync", "") }
        )
        setDot(context, views, R.id.w_sync_dot, store.getString("sync_tone", null))

        val rows = listOf(
            Triple(R.id.w_src1_name, R.id.w_src1_value, R.id.w_src1_dot),
            Triple(R.id.w_src2_name, R.id.w_src2_value, R.id.w_src2_dot),
            Triple(R.id.w_src3_name, R.id.w_src3_value, R.id.w_src3_dot)
        )
        for ((index, row) in rows.withIndex()) {
            val n = index + 1
            views.setTextViewText(row.first, NativeL10n.text(context, store.getString("src${n}_name", "-").orEmpty()))
            views.setTextViewText(row.second, NativeL10n.text(context, store.getString("src${n}_value", "-").orEmpty()))
            setDot(context, views, row.third, store.getString("src${n}_tone", null))
        }

        applyCompactRules(context, views, layout, options)

        views.setOnClickPendingIntent(R.id.w_root, openIntent(context, null))
        views.setOnClickPendingIntent(R.id.w_server_area, openIntent(context, "服务器状态"))
        views.setOnClickPendingIntent(R.id.w_sync_area, openIntent(context, "自动同步"))
        views.setOnClickPendingIntent(R.id.w_btn_sync, openIntent(context, "同步成绩到多端"))
        views.setOnClickPendingIntent(R.id.w_btn_ocr, openIntent(context, "结算画面识别"))
        views.setOnClickPendingIntent(R.id.w_btn_player, openIntent(context, "随身听"))
        return views
    }

    /**
     * 高度不够时隐藏次要信息。内容是垂直居中的，放不下会向上下溢出、叠在别的元素上。
     * 桌面没上报尺寸（高度为 0）时按放得下处理。竖屏的实际高度是 MAX_HEIGHT。
     */
    private fun applyCompactRules(
        context: Context,
        views: RemoteViews,
        layout: Int,
        options: Bundle
    ) {
        val reported = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT)
        if (reported <= 0) return
        // 文字用 sp，系统字体调大时同样的高度放得更少
        val height = reported / maxOf(1f, context.resources.configuration.fontScale)
        fun hideBelow(limit: Int, vararg ids: Int) {
            if (height >= limit) return
            for (id in ids) views.setViewVisibility(id, View.GONE)
        }
        if (layout == R.layout.home_widget_large) {
            hideBelow(300, R.id.w_btn_sync, R.id.w_btn_ocr, R.id.w_btn_player)
            hideBelow(250, R.id.w_sync_area)
        } else {
            hideBelow(140, R.id.w_rating_note, R.id.w_b35, R.id.w_b15)
            hideBelow(130, R.id.w_server_detail, R.id.w_sync_detail)
            hideBelow(115, R.id.w_rating_bar, R.id.w_rating_title)
        }
    }

    fun refreshAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val kinds = listOf(
            HomeWidgetRating::class.java to R.layout.home_widget_rating,
            HomeWidgetStatus::class.java to R.layout.home_widget_status,
            HomeWidgetMedium::class.java to R.layout.home_widget_medium,
            HomeWidgetLarge::class.java to R.layout.home_widget_large
        )
        for ((kind, layout) in kinds) {
            for (id in manager.getAppWidgetIds(ComponentName(context, kind))) {
                manager.updateAppWidget(id, build(context, layout, manager.getAppWidgetOptions(id)))
            }
        }
    }
}

abstract class BaseHomeWidget : AppWidgetProvider() {
    /** 用户拉伸小组件后按新尺寸重新决定显示哪些内容。 */
    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        HomeWidgetStore.refreshAll(context)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        // 先画已有内容，再取一次舞萌状态。goAsync 让广播在网络请求期间不被回收。
        HomeWidgetStore.refreshAll(context)
        val pending = goAsync()
        thread {
            try {
                HomeWidgetStore.fetchServerStatus(context)
                HomeWidgetStore.refreshAll(context)
            } finally {
                pending.finish()
            }
        }
    }
}

class HomeWidgetRating : BaseHomeWidget()
class HomeWidgetStatus : BaseHomeWidget()
class HomeWidgetMedium : BaseHomeWidget()
class HomeWidgetLarge : BaseHomeWidget()
