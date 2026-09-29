package guide.android.examples

import android.app.Activity
import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.widget.Button
import android.widget.LinearLayout
import android.widget.RemoteViews
import android.widget.TextView
import android.widget.Toast
import java.text.SimpleDateFormat
import java.util.Date

// ---- 17 章第 2 节：AppWidgetProvider 液晶时钟（更新逻辑四步定式）----
// 真实工程里 layoutRes/textRes 来自 R.layout.widget_clock / R.id.clock_text
// （aapt 生成）；教学工程无资源管线，调用形态以参数传入并占位 0 通过编译。

class ClockWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        // 生产代码：pushTime(context, manager, ids, R.layout.widget_clock, R.id.clock_text)
        pushTime(context, manager, ids, 0, 0)
    }

    companion object {
        fun pushTime(context: Context, manager: AppWidgetManager, ids: IntArray,
                     layoutRes: Int, textRes: Int) {
            val views = RemoteViews(context.packageName, layoutRes).apply {   // ① 说明书
                setTextViewText(textRes,                                      // ② 改内容
                    SimpleDateFormat("HH:mm:ss").format(Date()))
            }
            manager.updateAppWidget(ids, views)          // ③ 提交：按 id 批量刷新
        }

        /** 按 ComponentName 刷新（服务端主动推时的常用重载） */
        fun pushByName(context: Context, layoutRes: Int, textRes: Int, text: String) {
            val views = RemoteViews(context.packageName, layoutRes)
            views.setTextViewText(textRes, text)
            AppWidgetManager.getInstance(context).updateAppWidget(
                ComponentName(context, ClockWidget::class.java), views)
        }
    }
}

// ---- 17 章第 4 节：钉住快捷方式（requestPinShortcut，广播版已废弃）----

class Example26PinShortcut : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(Button(this).apply {
            text = "请求钉到桌面（系统弹窗确认）"
            setOnClickListener {
                val sm = getSystemService(android.content.pm.ShortcutManager::class.java)
                if (sm.isRequestPinShortcutSupported) {
                    val pin = android.content.pm.ShortcutInfo.Builder(this@Example26PinShortcut, "memo_new")
                        .setShortLabel("新建便签")
                        .setIntent(Intent(this@Example26PinShortcut,
                            Example26PinShortcut::class.java).setAction(Intent.ACTION_VIEW))
                        .build()
                    sm.requestPinShortcut(pin, null)      // 用户点"添加"才落桌面
                } else {
                    Toast.makeText(context, "当前启动器不支持钉住", Toast.LENGTH_SHORT).show()
                }
            }
        })
    }
}

// ---- 17 章第 5 节：系统管理器四连 ----

class Example26Managers : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val log = TextView(this)
        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 64, 32, 32)
        }

        // ① Vibrator：API 31 起入口换 VibratorManager，振动效果走 VibrationEffect
        root.addView(Button(this).apply {
            text = "振动 200ms（VIBRATE 权限）"
            setOnClickListener {
                val vibrator = if (android.os.Build.VERSION.SDK_INT >= 31) {
                    (getSystemService(Context.VIBRATOR_MANAGER_SERVICE)
                            as android.os.VibratorManager).defaultVibrator
                } else {
                    @Suppress("DEPRECATION")
                    getSystemService(Context.VIBRATOR_SERVICE) as android.os.Vibrator
                }
                vibrator.vibrate(
                    android.os.VibrationEffect.createOneShot(
                        200, android.os.VibrationEffect.DEFAULT_AMPLITUDE))
            }
        })

        // ② AudioManager：按流类型调音量
        root.addView(Button(this).apply {
            text = "媒体音量 +1（带系统音量条）"
            setOnClickListener {
                val am = getSystemService(Context.AUDIO_SERVICE) as android.media.AudioManager
                am.adjustStreamVolume(
                    android.media.AudioManager.STREAM_MUSIC,
                    android.media.AudioManager.ADJUST_RAISE,
                    android.media.AudioManager.FLAG_SHOW_UI)
            }
        })

        // ③ AlarmManager：精确闹钟（Doze 时代三问后再用）
        root.addView(Button(this).apply {
            text = "60 秒后精确触发（需 SCHEDULE_EXACT_ALARM，API 31+）"
            setOnClickListener {
                val am = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                if (am.canScheduleExactAlarms()) {
                    val pi = PendingIntent.getBroadcast(
                        this@Example26Managers, 0,
                        Intent("guide.android.examples.EXACT_TICK")
                            .setPackage(packageName),
                        PendingIntent.FLAG_IMMUTABLE)           // API 31 起必须显式
                    am.setExactAndAllowWhileIdle(
                        AlarmManager.RTC_WAKEUP,
                        System.currentTimeMillis() + 60_000, pi)
                    Log.d("Managers", "60s exact alarm set")
                } else {
                    Toast.makeText(context, "精确闹钟权限被拒", Toast.LENGTH_SHORT).show()
                }
            }
        })

        // ④ SmsManager：发送回执双 PendingIntent（SEND_SMS 运行时权限）
        root.addView(Button(this).apply {
            text = "发短信（示意，需权限与号码）"
            setOnClickListener {
                val sm = getSystemService(android.telephony.SmsManager::class.java)
                val sent = PendingIntent.getBroadcast(
                    this@Example26Managers, 1, Intent("SMS_SENT").setPackage(packageName),
                    PendingIntent.FLAG_IMMUTABLE)
                sm.sendTextMessage("10086", null, "hello", sent, null)
            }
        })

        root.addView(log)
        setContentView(root)
    }
}
