# 10 · BroadcastReceiver、Service 与通知

> 对应示例：`examples/10_broadcast_receiver.kt`、`examples/11_service_basics.kt`、`examples/12_notifications.kt`

## 1. 四组件里的"无界面"两位

Android 的四大组件（components，详见[第 01 章](01-overview.md)）里，Activity 负责"看得见的每一屏"，其余三位都在幕后：

| 组件 | 职责 | 入口回调 | 详见 |
|---|---|---|---|
| Activity | 界面 + 交互 | `onCreate` → `onStart` → `onResume` | 第 04、06 章 |
| Service | 无界面的后台执行 | `onCreate` / `onStartCommand` | 本章 |
| BroadcastReceiver | 订阅广播事件 | `onReceive` | 本章 |
| ContentProvider | 跨应用数据共享 | `query` 等一套数据接口 | 第 11 章 |

三条共性规矩，比单个组件的用法更重要：

1. **都要在 `AndroidManifest.xml` 里注册**（BroadcastReceiver 动态注册的除外，见第 2 节），注册名由系统实例化——所以组件类需要一个公开的无参构造
2. **回调默认跑在主线程**：`onReceive`、`onStartCommand` 都不例外，里面做重活等于在主线程做重活（第 08 章的教训直接适用）
3. **组件的生命周期由系统管理，不由你**：你只能通过 `startService` / `sendBroadcast` 这类方式"提议"，何时创建、何时销毁是系统的决定

本章三个示例依旧只用框架 API，不引 Jetpack。

## 2. BroadcastReceiver：订阅系统级事件

广播（broadcast）是 Android 的发布-订阅机制：发送方把一条带 **Action**（动作字符串）的 Intent 抛向系统，所有注册时声明"我关心这个 Action"的接收方都会被回调。`examples/10_broadcast_receiver.kt` 是最小闭环：

```kotlin
class Example10BroadcastReceiver : Activity() {
    private val receiver = GuideReceiver()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val tv = TextView(this).apply { text = "receiver registered" }
        setContentView(tv)
        registerReceiver(receiver, IntentFilter("guide.ACTION_PING"))
        sendBroadcast(Intent("guide.ACTION_PING"))
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterReceiver(receiver)
    }

    private class GuideReceiver : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
        }
    }
}
```

四个动作连起来读：

| 调用 | 作用 |
|---|---|
| `GuideReceiver : BroadcastReceiver()` | 接收方：继承并实现 `onReceive` |
| `registerReceiver(receiver, IntentFilter("guide.ACTION_PING"))` | **动态注册**：声明"我接收 Action 为 `guide.ACTION_PING` 的广播" |
| `sendBroadcast(Intent("guide.ACTION_PING"))` | 发送：Intent 的 action 与过滤器匹配即投递，接收方收到 `onReceive` |
| `unregisterReceiver(receiver)` | 注销：`onDestroy` 里成对出现，不注销会泄漏并在日志里挨骂 |

`IntentFilter` 可以塞多个 Action（`addAction`），一个接收方订阅多类事件；`onReceive` 里用 `intent.action` 区分来源。这套 Action 匹配与第 06 章隐式 Intent 是同一个机制，只是方向反过来——隐式 Intent 找"一个处理者"，广播找"所有订阅者"。

### 动态注册 vs 静态注册

注册广播有两条路，能力边界完全不同：

| | 动态注册（`registerReceiver`） | 静态注册（manifest `<receiver>`） |
|---|---|---|
| 生效期 | 代码注册到注销之间（通常绑 Activity/进程生命周期） | 安装后常驻，应用未运行也可被拉起 |
| 能收什么 | 任意广播 | 应用安装/替换、开机等少数豁免项 |
| Android 8+（API 26）限制 | 不受影响 | **绝大多数系统隐式广播不再投递给静态注册者** |
| 典型用途 | 页面内响应电量/网络变化 | `BOOT_COMPLETED` 开机自启 |

静态注册的样子（第 02 章的清单文件）：

```xml
<receiver android:name=".BootReceiver" android:exported="true">
    <intent-filter>
        <action android:name="android.intent.action.BOOT_COMPLETED" />
    </intent-filter>
</receiver>
```

Google 收紧静态注册的原因很直白：任何广播都能唤醒任意静态接收者 → 系统广播风暴 → 全机待机耗电。所以**默认写动态注册**，静态只留给 `BOOT_COMPLETED` 这类官方豁免清单。

几个高频出现的广播 Action，正好感受静态/动态的分界线：

| Action | 时机 | 可用注册方式 |
|---|---|---|
| `Intent.ACTION_BOOT_COMPLETED` | 开机完成 | 静态（官方豁免，开机自启的正路） |
| `Intent.ACTION_BATTERY_LOW` | 电量不足 | 静态（豁免）；高频的 `ACTION_BATTERY_CHANGED` 仅动态 |
| `Intent.ACTION_TIME_TICK` | 每分钟一次 | 仅动态 |
| `Intent.ACTION_SCREEN_ON` / `ACTION_SCREEN_OFF` | 亮屏/息屏 | 仅动态 |

不确定某个广播是否豁免时，查官方文档的 "implicit broadcast exceptions" 清单，别靠试。

两条新规矩：targetSdk 34（Android 14）起动态注册自定义广播必须显式声明导出标志，`registerReceiver(receiver, filter, Context.RECEIVER_NOT_EXPORTED)`（`RECEIVER_EXPORTED` 表示允许其他应用发来），漏写直接 `SecurityException`；另外进程内事件别再用广播——官方 `LocalBroadcastManager` 已废弃，进程内用普通回调/Flow 即可。

### onReceive 的十秒红线

`onReceive` 必须尽快返回——**约 10 秒不返回系统就抛 ANR**。原因是接收方不拥有自己的进程主权：系统只是"顺便"把你的进程拉起来跑这一个回调。重活（网络、解码、落盘）的正确去向是转手：`onReceive` 里 `startService`/`goAsync()` 拿宽限，或直接交给 WorkManager（第 3 节末尾）。

## 3. Service：没有界面的后台执行

Service 是"想在没有界面的情况下继续跑逻辑"的载体。`examples/11_service_basics.kt` 短到可以全文贴出：

```kotlin
class Example11ServiceBasics : Service() {
    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        stopSelf(startId)
        return START_NOT_STICKY
    }
}
```

它还必须在 manifest 里注册（否则 `startService` 直接抛异常）：

```xml
<service android:name=".Example11ServiceBasics" />
```

调用方的完整链路：

```kotlin
startService(Intent(this, Example11ServiceBasics::class.java))  // 启动
stopService(Intent(this, Example11ServiceBasics::class.java))   // 外部叫停
```

时序与语义：

1. 首次 `startService`：系统创建 Service 实例 → `onCreate()`（一次）→ `onStartCommand(intent, flags, startId)`
2. 再次 `startService`：**不再走 `onCreate`，只回调 `onStartCommand`**，每次调用带一个新 Intent——想传数据就塞进 Intent 的 extra（第 06 章）
3. 停止：示例在 `onStartCommand` 里 `stopSelf(startId)` 自停（处理完即走），外部也可以 `stopService`；停止时回调 `onDestroy()`
4. `onStartCommand` 的返回值是"进程被杀后如何对待我"的遗嘱：

| 返回值 | 进程被杀后 | 适合 |
|---|---|---|
| `START_NOT_STICKY` | 不重建，丢弃未完成任务 | 丢了也无所谓的任务（示例的选择） |
| `START_STICKY` | 重建服务，但重投的 Intent 为 `null` | 常驻型（音乐播放器） |
| `START_REDELIVER_INTENT` | 重建并重投最后一个 Intent | 丢了会出事的任务（发报一半的请求） |

Intent 里可以带数据，这是启动式服务唯一的传参通道：

```kotlin
val intent = Intent(this, Example11ServiceBasics::class.java)
    .putExtra("payload", "https://example.com/file.zip")
startService(intent)   // onStartCommand 的 intent 参数原样收到
```

两次 `startService` 加一次自停的回调时间线（调试与面试都用得上）：

```text
startService #1 ─→ onCreate ─→ onStartCommand(startId=1)
startService #2 ─→              onStartCommand(startId=2)
stopSelf(2)      ─→ onDestroy
```

`stopSelf(startId)` 带 startId 的语义是"如果这是**最近一次**启动，就停我"——队列里还有更早的活没干完时不会误停，这是它比无参 `stopSelf()` 稳妥的地方。

### started vs bound：两种使用模式

同一个 Service 类，有两种打开方式，决定了它的生命周期归属：

| | started（启动式） | bound（绑定式） |
|---|---|---|
| 启动 | `startService(intent)` | `bindService(intent, conn, flags)` |
| 生命周期归属 | 自己管：`stopSelf` / `stopService` 才停 | 绑定者管：所有绑定者 `unbindService` 后即销毁 |
| 通信方式 | Intent 单向投递，没有返回通道 | `onBind` 返回 `IBinder`，双向方法调用与回调 |
| 多次调用 | 每次都触发 `onStartCommand` | 同一绑定者重复绑定只连一次 |
| 典型场景 | "去把这个活干完" | 界面与后台长期互动（播放器控制条） |

示例里 `onBind` 返回 `null`，即声明"我只支持启动式"。绑定式要另写一个 `Binder` 子类并通过 `ServiceConnection` 收连接回调——本教程的示例项目用不到，记住"返回 null = 纯启动式"这条即可。

两个必须内化的现代事实：

- **`onStartCommand` 跑在主线程**。Service 不是后台线程！里面做网络/数据库照样 ANR，重活要自己开线程（第 08 章）或交给下面的 WorkManager
- **后台执行的现代首选是 WorkManager**：可延迟、可设约束（充电/Wi-Fi 才跑）、进程被杀任务仍在、系统按电池策略调度。裸 Service 留给"正在被用户感知"的执行（如播放音乐），那种场景叫**前台服务**（foreground service）——`startForegroundService` 启动后必须在数秒内 `startForeground` 挂一条常驻通知，通知与权限的账单见第 11 章

## 4. 通知

通知（notification）是系统级 UI：由应用构建，状态栏展示、抽屉管理、锁屏可见。`examples/12_notifications.kt` 走完最小链路：

```kotlin
val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
val channelId = "guide_channel"
val channel = NotificationChannel(
    channelId,
    "Guide",
    NotificationManager.IMPORTANCE_DEFAULT
)
manager.createNotificationChannel(channel)
val builder = Notification.Builder(this, channelId)
val notification = builder
    .setContentTitle("Guide")
    .setContentText("Android notification sample")
    .setSmallIcon(android.R.drawable.ic_dialog_info)
    .build()
manager.notify(1001, notification)
```

分三段看：

**第一段：拿 `NotificationManager`**。通知是系统服务（第 01 章的服务列表），`getSystemService(NOTIFICATION_SERVICE)` 取管理器。

**第二段：建 NotificationChannel（通知渠道）**。API 26（Android 8.0）起**没有渠道的通知一律不展示**。渠道构造三要素：

| 参数 | 值 | 说明 |
|---|---|---|
| id | `"guide_channel"` | 应用内唯一标识，builder 按它挂靠 |
| 用户可见名 | `"Guide"` | 展示在系统设置里，用户按渠道开关/调重要性 |
| importance | `IMPORTANCE_DEFAULT` | 声音提醒级别；`HIGH` 会以悬浮横幅（heads-up）打断 |

渠道是给用户的"通知分类开关"：聊天、提醒、营销各建一渠道，用户可以单独静音某一类。`createNotificationChannel` 幂等，且**渠道一旦创建，代码再改 importance 也无效**（以用户在系统设置里改的为准）——重要性别设错，错了只能换渠道 id 或卸载重装。

**第三段：构建并发送**。`Notification.Builder(this, channelId)` 双参构造把通知绑到渠道上；`setSmallIcon` 是**必需项**（没有小图标的通知无效）；`setContentTitle` / `setContentText` 是两行文案；最后 `notify(1001, notification)`——第一个参数是通知 id，**同 id 再发即更新原通知**，不同 id 各占一条，`cancel(1001)` 可撤销。

最后一张必缴的税单：**API 33（Android 13）起发送通知需要 `POST_NOTIFICATIONS` 运行时权限**，未授权时 `notify` 不报错、通知静默消失。用户默认拒绝、需要你主动申请——完整流程见[第 11 章](11-permissions-content.md)。

### 让通知可点击

示例里的通知点不动。要响应点击，得挂一个 `PendingIntent`（延迟意图）：

```kotlin
val intent = Intent(this, Example10BroadcastReceiver::class.java)
val pending = PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_IMMUTABLE)
builder
    .setContentIntent(pending)   // 点击行为：由系统在用户点下时执行
    .setAutoCancel(true)         // 点击后自动从抽屉消失
```

`PendingIntent` 是"预先授权的意图凭据"：你把启动某个界面/组件的意图打包交给系统进程，用户点击时由系统代为执行——普通 `Intent` 没有这种跨进程托付能力。`FLAG_IMMUTABLE` 在 targetSdk 31+ 是必填的旗标。

## 5. 常见坑

**`onReceive` 里做网络请求**：网络请求动辄数秒，十秒红线一碰即 ANR；即使侥幸返回，进程优先级低随时被杀，回调后你的代码根本没机会跑完。广播只当"门铃"用：`onReceive` 里转交 `startService` 或 WorkManager，重活在别处做。

**忘建 channel 直接 notify**：API 26+ 上系统在 logcat 留一行 `No Channel found for ...` 然后把通知整条丢弃——**多数设备上不抛异常**，症状是"代码明明跑了、通知就是不出来"，比崩溃难查得多。排查顺序：先渠道建没建，再 `POST_NOTIFICATIONS` 授权没有，最后才是 builder。

**通知缺 `setSmallIcon`**：构建链一气呵成偏偏漏了小图标，结果是无效通知被系统拒绝，部分系统直接抛 `IllegalArgumentException`。`setSmallIcon` 与 channel 同级必需。

**`startService` 后不 stop**：Service 启动后常驻内存，耗电且被系统标记为"后台滥用"（Android 8+ 后台启动 Service 本就受限制）。任务完成就 `stopSelf`；周期性/可延迟任务干脆用 WorkManager，别让 Service 空转。

## 6. 实战建议

- 广播接收方一律成对写 `registerReceiver` / `unregisterReceiver`，注册放 `onStart`、注销放 `onStop` 比放 `onCreate` / `onDestroy` 更省泄漏面
- 新工程动态注册自定义广播时直接带上 `RECEIVER_NOT_EXPORTED`，顺手杜绝 targetSdk 34 的 `SecurityException`
- 默认不写 Service：一次性重活给 WorkManager（[第 14 章](14-compose-architecture.md)），仅"用户正盯着"的执行（导航、播放）才用前台服务
- 通知渠道按"用户会想分开静音的粒度"划分，宁可细不可粗；id 用常量收口
- 通知 id 收进常量表：进度类通知复用固定 id 做原地更新，新事件用新 id，避免抽屉被刷屏

---
上一章：[09 本地数据持久化](09-data-storage.md) ｜ 下一章：[11 运行时权限、ContentResolver 与硬件服务](11-permissions-content.md)
