# 17 · 桌面组件与系统管理器

> 对应示例：`examples/26_appwidget_managers.kt`。取材：李刚《疯狂Android讲义（第3版）》第 14 章（桌面/壁纸/快捷方式/桌面控件）与 10.2–10.6（电话/短信/音频/振动/闹钟五个系统管理器）。这一章的定位：**应用活在系统里的方式**——到桌面上去、到系统服务里去。

## 1. 桌面坐标系：三种存在

Android 桌面（Launcher）上第三方应用能有三种存在（书 14.1 的划分沿用至今）：

| 存在 | 占位 | 本质 | 2026 现状 |
|---|---|---|---|
| 快捷方式 | 一格 | 指向入口 Activity 的图标 | 活着，但创建方式全换（下节） |
| 桌面控件 AppWidget | 一格到多格 | `AppWidgetProvider`（广播接收器）+ 跨进程视图 | 活着，各家 Launcher 仍支持；Glance（Compose 写 widget）是官方新路线 |
| 动态壁纸 | 整个背景层 | `WallpaperService` + Surface 绘图 | API 原样，需求萎缩但仍可用 |

## 2. AppWidget：一个会过马路广播的视图

桌面控件的本质（书 14.4.1 讲得极准）是：**你的代码跑在自己的进程里，视图却渲染在 Launcher 进程里**。所以中间只能传 `RemoteViews`——一份"视图操作说明书"，由 Launcher 代为执行。这解释了它的全部限制：**只支持白名单控件**（TextView、ImageView、ProgressBar、ListView/GridView/StackView、AnalogClock、Chronometer、Button 等），**不能 setOnClickListener，只能 setOnClickPendingIntent**，自定义 View 一律谢绝。

`AppWidgetProvider` 是 `BroadcastReceiver` 的子类，四个生命周期回调：

| 回调 | 时机 |
|---|---|
| `onEnabled` | 该控件的**第一个**实例被放到桌面 |
| `onUpdate` | 到达更新周期 / 新实例添加（主力回调） |
| `onDeleted` | 某个实例被移除 |
| `onDisabled` | **最后一个**实例被移除（清理闹钟之类的收尾放这） |

`onUpdate` 的四步定式（书 14.4.1，一步不多）：

```kotlin
class ClockWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        val views = RemoteViews(context.packageName, R.layout.widget_clock)  // ① 说明书
            .apply { setTextViewText(R.id.clock_text, "10:24") }            // ② 改内容
        manager.updateAppWidget(ids, views)     // ③④ ComponentName 隐含在 ids 重载里
    }
}
```

配套的**两份登记**（无它们控件不会出现在 Launcher 的 widget 列表里）：

1. **Manifest**：`<receiver android:name=".ClockWidget">` 配 `<intent-filter android.appwidget.action.APPWIDGET_UPDATE>` + `<meta-data android:name="android.appwidget.provider" android:resource="@xml/clock_info"/>`
2. **`res/xml/clock_info.xml`**（`<appwidget-provider>` 元数据）：`minWidth/minHeight`（格子尺寸，**70dp 法则**：占 n 格 ≈ 70n−30 dp）、`updatePeriodMillis`（**系统下限 30 分钟**，要更勤得自己用 AlarmManager/WorkManager 推）、`initialLayout`（首帧占位布局）、`resizeMode`/`widgetCategory`

**带数据集的控件**（书 14.4.2）：`views.setRemoteAdapter(R.id.list, Intent(context, StackWidgetService::class.java))` 把列表数据源指向一个 `RemoteViewsService`——它的 `onGetViewFactory()` 返回 `RemoteViewsFactory`，长得就是 Adapter（`onCreate/onDataSetChanged/getViewAt/count`），唯一区别是 `getViewAt` 返回的必须是 `RemoteViews`（同跨进程理由）。数据变了调 `notifyAppWidgetViewDataChanged` 让工厂重查。

**校准**：ListView/GridView 在 widget 里的地位被 `setRemoteAdapter(…, RemoteCollectionItems)`（API 31 的直灌数据版）与 **Glance**（Jetpack，用 Compose 风格 API 生成 RemoteViews）渐进替代；但 Service/Factory 那套仍是存量主流。

## 3. 动态壁纸：Surface 通道的第二个客户

`WallpaperService` 的 Engine 与 13 章 SurfaceView 同机制（书 14.2.1）：`onCreateEngine()` 返回 `WallpaperService.Engine` 子类，在 `surfaceCreated` 拿 `SurfaceHolder`，`onVisibilityChanged(visible)` 控制动画启停（不可见必须停——壁纸在桌面后面跑满帧是耗电事故），`onOffsetsChanged` 还能感知用户翻页的偏移（视差壁纸就这么做）。Manifest 走 Service 登记但必须 `android.permission.BIND_WALLPAPER` + `res/xml` 里的 `wallpaper` 元数据。书里"蜿蜒壁纸"（0.1 秒一帧画矩形串）是完整可抄的骨架。

## 4. 快捷方式：广播已死，钉住当立

书 14.3 的三步（`INSTALL_SHORTCUT` 广播 + extras + `sendBroadcast`）**已整体废弃**——现代 Launcher 不认这个广播，恶意快捷方式的锅让这条路被系统关死。今天的正门是 API 26 的**钉住快捷方式**：系统弹窗、用户确认、无静默安装：

```kotlin
val sm = getSystemService(ShortcutManager::class.java)
if (sm.isRequestPinShortcutSupported) {
    val pin = ShortcutInfo.Builder(this, "memo_new")
        .setShortLabel("新建便签")
        .setIntent(Intent(this, EditActivity::class.java).setAction(Intent.ACTION_VIEW))
        .build()
    sm.requestPinShortcut(pin, null)     // 系统确认弹窗，用户点"添加"才落桌面
}
```

静态快捷方式/动态快捷方式（同一 ShortcutManager 的另两档）是长按图标弹出的那排，与桌面钉住共享一套 ShortcutInfo。

## 5. 系统管理器五连

书 10.2–10.6 的五位"getXxx 管理器"全是同一个模式：`getSystemService(X::class.java)` 拿服务，绝无 new。逐个过，**每个都带 2026 校准**：

**TelephonyManager（10.2）**：读网络/SIM 状态的 `getXxx()` 一族（网络国家、SIM 序列号…`READ_PHONE_STATE` 权限，部分还要运行时申请）；监听通话用 `listen(PhoneStateListener, events)`——**已废弃**，替代是 `registerTelephonyCallback(executor, TelephonyCallback)`，能力分小接口按需实现。来电号码在现代系统受隐私限制远比书时代严。

**SmsManager（10.3）**：`sendTextMessage(dest, scAddress, text, sentPI, deliveredPI)` 一行发短信（`SEND_SMS` 运行时权限）。两个 PendingIntent 分别回"已发出/已送达"，这是它设计的精髓；群发就是循环——书里自己提醒了：循环在主线程遇上网络延迟就是 ANR，挪后台（今天用协程，书时代用 IntentService）。**构造**：`SmsManager.getDefault()` 已废弃，改 `getSystemService(SmsManager::class.java)`。**接收**方在 10 章广播里讲过；短信拦截类应用还需成为默认短信 App 才能写数据库。

**AudioManager（10.4）**：核心概念是**流类型**——`STREAM_MUSIC/RING/ALARM/NOTIFICATION/SYSTEM/VOICE_CALL` 各有独立音量曲线；`adjustStreamVolume(type, ADJUST_RAISE/LOWER/MUTE, FLAG_SHOW_UI)` 增减静音一条龙。**校准**：`setStreamMute` 已废弃（静音交 ADJUST_MUTE），且播放侧的"音量礼仪"已经交给 16 章的音频焦点机制——裸设别人流音量的场景基本绝迹。

**Vibrator（10.5）**：`vibrate(2000)` 两秒——**已废弃**。现代三件套：`VibrationEffect.createOneShot(200, VibrationEffect.DEFAULT_AMPLITUDE)`（波形/强度可编程）、`vibrator.effect` 挂 `VibrationEffect`、以及 API 31 起获取入口换 `VibratorManager.defaultVibrator`（多马达设备可分区震）。权限 `VIBRATE`（普通权限，装上即有）。

**AlarmManager（10.6）**：全局定时器，到点替你 fire 一个 PendingIntent（组件三选一，书里闹钟/换壁纸两个实例都是活教材）。四个 type 先分两轴：**时间基准**（`RTC` 挂钟 vs `ELAPSED_REALTIME` 开机起算）× **是否唤醒**（`_WAKEUP` 休眠也拉起，否则休眠顺延）。**三重校准**（这是本 API 十年来最大的变化）：

1. **4.4 起默认批处理**：`set()` 的闹钟系统可偏移合并省电；要准点用 `setExact*` 家族
2. **Doze/应用待机**（6.0/7.0 起）：休眠窗口内连 `setRepeating` 都会被拖到维护窗口；真需要准时用药 `setExactAndAllowWhileIdle`，且 API 31+ 要 `SCHEDULE_EXACT_ALARM` 权限、`canScheduleExactAlarms()` 先探（用户可在设置里关）
3. **能不用就不用**：周期后台任务的现代默认答案是 **WorkManager**（21 章）——约束感知（电量/网络）、不必醒设备、免权限；AlarmManager 只留给"用户明确期待此刻发生"的闹钟/提醒语义

## 6. PendingIntent：别人的 Intent，你的授权

书 10.3 借发短信引出的概念值得独立记：**PendingIntent = 包装好的 Intent + 授权他人代发**。AppWidget 的点击、闹钟的到点触发、通知的 action（10 章）全是它的客户。三档工厂按目标组件选：`getActivity/getBroadcast/getService`。两条铁律：

- **API 31 起必须显式 FLAG**：`FLAG_IMMUTABLE`（绝大多数场景——不然后台恶意 App 里的老版可被改写 extras）或 `FLAG_MUTABLE`（仅通知直接回复等确实要系统填内容的场景）
- **匹配即复用**：相同 Intent + requestCode 的请求返回同一 token——想换内容必须换 requestCode 或先 cancel，"闹钟改时间没生效"九成栽在这

## 7. 常见坑

**Widget 列表里不出现**：Manifest 没配 `APPWIDGET_UPDATE` intent-filter，或 meta-data 指的 xml 缺 `initialLayout`——两份登记一份都不能少。

**updatePeriodMillis 填 1000 想每秒刷新**：系统下限 30 分钟，小值被静默抬到下限；要高频只能自己推（AlarmManager/WorkManager + `updateAppWidget`）。

**RemoteViews 里用自定义 View / setOnClickListener**：直接不支持——白名单控件 + `setOnClickPendingIntent`，没有变通。

**onUpdate 里做网络请求**：BroadcastReceiver 的主线程 10 秒 ANR 红线（10 章讲过）；要异步得 `goAsync()` 拿 10 秒宽限或转 Service/WorkManager 干完再推 RemoteViews。

**快捷方式广播静默无效**：`INSTALL_SHORTCUT` 在现代 Launcher 上无报错无效果——别再从老代码抄，走 requestPinShortcut。

**vibrate(2000) 不震**：方法废弃之外，多半是忘了 `VIBRATE` 权限（普通权限也要声明），或拿 Vibrator 的方式在 API 31+ 返回了空壳——用 VibratorManager 入口。

**闹钟改了时间还在旧时间响**：PendingIntent 匹配复用规则（6 节）——同 requestCode 视为"同一个闹钟"，内容更新要 cancel 原再 set，或换 requestCode。

**setStreamMute 编译过不了/行为怪**：它废弃了，ADJUST_MUTE 是替代；而播放中应有的"静音礼貌"其实是音频焦点的事（16 章）。

## 8. 实战建议

- Widget 的内容更新源选型：**周期数据 WorkManager、实时数据手动推、列表数据 RemoteViewsService**——三档覆盖全部场景
- 写 widget 先画"数据从哪来、谁负责推"的时序图，再动手——这个体系里 90% 的 bug 是"没人推更新"
- Glance 值得新项目评估：同一套 Compose 心智写 widget，底层仍编译成 RemoteViews（兼容老 Launcher）
- 系统管理器统一从 `getSystemService` 拿、统一先查 deprecated 标记——这一族 API 十年动了好几轮，书里的调用形态要对照本章校准表
- 精确闹钟三问：用户期待此刻发生吗？Doze 白名单/权限给了吗？WorkManager 真的不够吗？——三问过完再写 setExactAndAllowWhileIdle
- PendingIntent 一律 `FLAG_IMMUTABLE` 起步，requestCode 当作"变更令牌"管理

---
上一章：[16 多媒体开发](16-media.md) ｜ 下一章：[18 WebView 与混合开发](18-webview-hybrid.md) ｜ 返回：[README](../README.md)
