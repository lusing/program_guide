# 11 · 运行时权限、ContentResolver 与硬件服务

> 对应示例：`examples/13_runtime_permission.kt`、`examples/14_content_resolver.kt`、`examples/17_location_manager.kt`、`examples/18_sensor_manager.kt`

## 1. 权限模型：两层缺一不可

Android 是多应用沙箱系统：你的应用默认什么敏感资源都摸不到，想要就得声明权限（permission）。API 23（Android 6.0）把权限劈成两档：

| 档位 | 授予时机 | 用户感知 | 例子 |
|---|---|---|---|
| normal（普通权限） | **安装时**自动授予 | 装应用时列表里扫一眼 | `INTERNET`、`ACCESS_NETWORK_STATE`、`VIBRATE` |
| dangerous（危险权限） | **运行时**逐项弹窗授权 | 用到时系统对话框 | `CAMERA`、`ACCESS_FINE_LOCATION`、`READ_CONTACTS` |

危险权限的授予逻辑：**manifest 声明 + 运行时请求，两层缺一不可**。

```xml
<!-- 第一层：AndroidManifest.xml 里声明"我可能要用" -->
<uses-permission android:name="android.permission.CAMERA" />
```

只声明不请求 → 用相机照样被拒；只请求不声明（见第 6 节）→ 请求立即被驳回。声明是"资格"，请求是"使用时的签字"。

危险权限总共几十个，按**权限组**（permission group）归类，系统设置里用户看到的开关也是按组展示的：

| 权限组 | 代表权限 |
|---|---|
| CAMERA | `CAMERA` |
| LOCATION | `ACCESS_FINE_LOCATION`、`ACCESS_COARSE_LOCATION` |
| CONTACTS | `READ_CONTACTS`、`WRITE_CONTACTS` |
| MICROPHONE | `RECORD_AUDIO` |
| STORAGE | `READ_EXTERNAL_STORAGE`（API 33 起细化为照片/视频/音频三类媒体权限） |
| PHONE / SMS / SENSORS | `CALL_PHONE`、`SEND_SMS`、`BODY_SENSORS` |

同一组内的权限请求时可能被系统一并通过，但别依赖这个行为——逐项请求、逐项判断才是稳的。

用户授权还可撤销：系统设置里随时关，应用下次用必须重新确认。所以危险权限的状态是**三值的**——已授权 / 未授权 / 永久拒绝（第 2 节），不是简单的开关。

## 2. 运行时权限的标准流程

`examples/13_runtime_permission.kt` 是教科书式骨架：

```kotlin
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
    if (checkSelfPermission(Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
        requestPermissions(arrayOf(Manifest.permission.CAMERA), 101)
        tv.text = "requesting CAMERA"
    } else {
        tv.text = "CAMERA granted"
    }
} else {
    tv.text = "runtime permission not required"
}
```

三步读法：

1. **版本闸门**：运行时权限 API 23 才有，`Build.VERSION.SDK_INT >= Build.VERSION_CODES.M` 是固定前奏（低版本装了即授权，无需请求）
2. **先查后请**：`checkSelfPermission` 返回授权态，已是 `PERMISSION_GRANTED` 就别再弹窗打扰用户——每次进入页面都请求是最招人烦的反模式
3. **发起请求**：`requestPermissions(arrayOf(Manifest.permission.CAMERA), 101)` 弹系统对话框；`101` 是**回调码**（requestCode），用来在回调里对号入座

请求是**异步**的——对话框弹出时 `onCreate` 照常往下走（所以示例先把界面设成 "requesting CAMERA"），用户点完按钮后结果回到：

```kotlin
override fun onRequestPermissionsResult(
    requestCode: Int,
    permissions: Array<out String>,
    grantResults: IntArray
) {
    if (requestCode == 101) {
        val granted = grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        // granted == true 才能用相机；否则走降级路径
    }
}
```

`grantResults` 与 `permissions` 按下标一一对应，一次请求多项权限时逐项判断。

### 现代写法：Activity Result API

上面的 `requestCode` 回调是"全局信箱"式设计：所有请求挤一个回调、靠魔数对号，重排代码就错位。现代写法是 **Activity Result API**（androidx.activity）：

```kotlin
private val requestCamera =
    registerForActivityResult(ActivityResultContracts.RequestPermission()) { granted: Boolean ->
        // granted 即结果，无需 requestCode
    }

// 需要时：
requestCamera.launch(Manifest.permission.CAMERA)
```

每个权限一个 launcher 变量，结果就近写在 lambda 里，`requestCode` 整个消失。两条硬规矩：`registerForActivityResult` 必须在 Activity **创建早期**（字段初始化处）调用，不能等回调里再注册；`launch` 可以随时调用。新代码一律写这个，老式回调留作读旧工程用。

### shouldShowRequestPermissionRationale 与"永久拒绝"

`Activity.shouldShowRequestPermissionRationale(permission)` 的返回值配合用户行为解读：

| 状态 | 返回值 | 应对 |
|---|---|---|
| 从未请求过 | `false` | 直接请求 |
| 拒绝过一次（没勾"不再询问"） | `true` | 先展示理由 UI，再请求 |
| 勾选了"不再询问"（**永久拒绝**） | `false` | 请求会立即被驳回，对话框都不弹 |

永久拒绝是陷阱套陷阱：返回值和"从未请求"一样是 `false`，但行为完全不同。区分办法是记录"我请求过且被拒"的历史；永久拒绝后唯一出路是引导用户去系统设置手动开：

```kotlin
startActivity(Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
    Uri.fromParts("package", packageName, null)))
```

第 10 章通知的 `POST_NOTIFICATIONS`（API 33+）走的正是这套流程——多数用户默认没开，通知功能上线前先把这条权限请求写好。

## 3. ContentResolver：读别人的数据库

权限管的是"能不能"，ContentResolver（内容解析器）管的是"怎么拿别人的数据"。`examples/14_content_resolver.kt` 三行读遍系统设置表：

```kotlin
val cursor = contentResolver.query(Settings.System.CONTENT_URI, arrayOf("name"), null, null, null)
val count = cursor?.count ?: 0
cursor?.close()
```

`query` 五参数与第 09 章 `SQLiteDatabase.query` 的前五个**完全同构**——这不是巧合，是刻意设计：

| 参数 | 本例的值 | 含义 |
|---|---|---|
| uri | `Settings.System.CONTENT_URI` | 要查**谁**（`content://settings/system`） |
| projection | `arrayOf("name")` | 要哪些列（投影） |
| selection | `null` | 过滤条件（WHERE，占位符 `?`） |
| selectionArgs | `null` | 占位符实参 |
| sortOrder | `null` | 排序 |

返回值同样是 `Cursor`，同样用完要 `close()`。

**ContentProvider（内容提供器）是应用间数据共享的标准门面**：每个提供器对外发布一组 `content://` URI，别人只能通过 URI + `ContentResolver` 按它定好的列结构查改，无法越过它摸底层文件——权限、格式、粒度全由提供器把关。系统的通讯录（`ContactsContract`）、媒体库（`MediaStore`，第 09 章的 Scoped Storage）、设置（`Settings`）全都走这套门面；你自己的应用要向外界供数据，也是实现一个 `ContentProvider` 并在 manifest 注册。

和直接读文件的对比，一张表看清边界：

| | 直接读文件 | ContentResolver |
|---|---|---|
| 寻址 | 文件路径 | `content://` URI |
| 能读谁的 | 只有自己沙箱里的 | 提供方声明的任意应用数据 |
| 前置条件 | 无 | 提供方要求的权限（如 `READ_CONTACTS`） |
| 数据形态 | 字节流，格式自己解析 | 结构化行列（Cursor） |

一句话观点：ContentResolver 是 Android 版的"跨应用数据库协议"，**把数据当成带权限的表来查，而不是当成文件来摸**。

换个数据源体会一下通用性——读通讯录（已取得 `READ_CONTACTS` 运行时权限的前提下）：

```kotlin
val projection = arrayOf(
    ContactsContract.Contacts._ID,
    ContactsContract.Contacts.DISPLAY_NAME
)
contentResolver.query(
    ContactsContract.Contacts.CONTENT_URI,
    projection, null, null, null
)?.use { c ->
    while (c.moveToNext()) {
        val name = c.getString(1)   // DISPLAY_NAME 在投影里排第二
    }
}
```

与读系统设置唯一的区别是换了 URI 和列名——五参数模型、Cursor 遍历、`use` 收尾原样复用。官方把每类数据的 URI 和列名都定成常量（`ContactsContract`、`MediaStore`），查文档就是查这张常量表。

## 4. 位置：LocationManager

位置是"危险权限 + 硬件服务"的典型组合。`examples/17_location_manager.kt` 完整生命周期：

```kotlin
class Example17LocationManager : Activity() {
    private var locationManager: LocationManager? = null
    private val listener = LocationListener { _: Location -> }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        locationManager = getSystemService(LOCATION_SERVICE) as LocationManager
        locationManager?.requestLocationUpdates(LocationManager.GPS_PROVIDER, 1000L, 1.0f, listener)
    }

    override fun onDestroy() {
        super.onDestroy()
        locationManager?.removeUpdates(listener)
    }
}
```

要点：

- `getSystemService(LOCATION_SERVICE) as LocationManager`——系统服务的标准取法（第 10 章的 `NOTIFICATION_SERVICE` 同族）
- `requestLocationUpdates` 的中间两个参数是**节流闸门**：`1000L`（毫秒）= 至少隔 1 秒才回调一次；`1.0f`（米）= 至少移动 1 米才回调。两者是"或"关系，谁先满足谁触发——既省电又免于回调风暴
- `LocationListener` 是单方法接口（SAM），Kotlin 里直接写 lambda，`it` 是 `Location`（含经纬度 `latitude` / `longitude`）
- `onDestroy` 里 `removeUpdates`——位置回调高频且持续，忘记注销等于让 GPS 陪着你的僵尸 Activity 一直耗电

定位源（provider）选型：

| Provider | 来源 | 特点 |
|---|---|---|
| `GPS_PROVIDER` | 卫星 | 精确（数米），冷启动慢、室内没有信号、耗电 |
| `NETWORK_PROVIDER` | 基站/Wi-Fi | 快而省电，精度百米级 |
| `PASSIVE_PROVIDER` | 捎带别的应用触发的定位 | 最省电，但不可控 |

只要"上次在哪"而不需要持续跟踪时，不必注册监听，直接查缓存：

```kotlin
val last = locationManager?.getLastKnownLocation(LocationManager.GPS_PROVIDER)
// 可能为 null：该定位源从没定过位。null 时再退回 requestLocationUpdates
```

权限上，`ACCESS_FINE_LOCATION`（精确）与 `ACCESS_COARSE_LOCATION`（粗略）**都是危险权限**，manifest 声明 + 运行时请求两步走（第 2 节流程原样套用）；targetSdk 31+ 若声明 FINE 必须同时声明 COARSE。生态里更常用的是 Google Play services 的 `FusedLocationProviderClient`（融合定位）：一个 API 自动融合 GPS/网络/传感器并做电池优化——但它是外部依赖，本章先用框架自带的 LocationManager 把机制讲透。

## 5. 传感器：SensorManager

传感器（sensor）是同一套"系统服务 + 注册监听"模式的最纯样本。`examples/18_sensor_manager.kt`：

```kotlin
private val listener = object : SensorEventListener {
    override fun onSensorChanged(event: SensorEvent?) {
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {
    }
}

override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    sensorManager = getSystemService(SENSOR_SERVICE) as SensorManager
    val accelerometer = sensorManager?.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    if (accelerometer != null) {
        sensorManager?.registerListener(listener, accelerometer, SensorManager.SENSOR_DELAY_NORMAL)
    }
}

override fun onDestroy() {
    super.onDestroy()
    sensorManager?.unregisterListener(listener)
}
```

要点：

- `getDefaultSensor(Sensor.TYPE_ACCELEROMETER)` 按类型取加速度计，**可能返回 `null`**（低端机、无该硬件的模拟器）——判空再注册是硬要求；同理还有 `TYPE_GYROSCOPE`、`TYPE_LIGHT` 等
- `SensorEventListener` 是双方法接口，只能写 `object` 表达式：`onSensorChanged` 收数据（`event.values` 是 `FloatArray`，加速度计三轴各一），`onAccuracyChanged` 收精度变化（多数应用忽略）
- 第三个参数 `SENSOR_DELAY_NORMAL` 是采样速率档位：`NORMAL`（约 5 次/秒）→ `UI` → `GAME` → `FASTEST`（不做节流）。**越快越耗电**，按需选档，别默认拉满
- `onDestroy` 里 `unregisterListener`：传感器回调默认走主线程、离开界面仍在采样，不注销是后台耗电的经典来源（第 6 节）

和 LocationManager 对照记忆：**取服务 → 拿到"源" → `register` 监听 → `unregister` 收尾**，Android 的硬件访问几乎全是这四步。

## 6. 常见坑

**manifest 漏声明**：只写了运行时请求、忘了 `<uses-permission>`。症状极具迷惑性——`requestPermissions` 对话框弹都不弹，`onRequestPermissionsResult` 立刻返回拒绝。排查权限问题永远先看 manifest，再看授权态，最后看代码。

**权限回调 requestCode 对不上**：多个权限请求共用回调，`if (requestCode == 101)` 的魔数从别的页面复制来的，改了请求码忘了改判断——结果是"用户明明点了允许，代码还是走拒绝分支"。老式 API 尤其如此；迁移到 Activity Result API 后此坑整体消失。

**传感器/位置监听没注销**：`registerListener` / `requestLocationUpdates` 之后没有配对的 `unregisterListener` / `removeUpdates`。回调持有 Activity 引用（内存泄漏）+ 硬件持续采样（耗电）双重罪。成对写、放在 `onDestroy`（或 `onPause`，视是否需要后台继续）里。

**主线程解析大量 Cursor**：`Cursor` 的数据躺在跨进程的 `CursorWindow` 里，`moveToNext` + `getString` 是逐行 IPC 拷贝——查几百行通讯录在主线程做就是 ANR 预备役。遍历放后台线程/协程（第 08 章），只把结果列表带回主线程。

## 7. 实战建议

- 权限请求写进"功能触发的时刻"（点拍照才请求相机），而不是启动时排队轰炸；先查 `checkSelfPermission`，已授权绝不重复弹
- 新代码一律 Activity Result API；老式 `requestPermissions` + requestCode 只用于读旧工程
- 为"拒绝后"设计：权限被拒不是错误路径，是正常分支——拍照没有相机权限就切系统相机应用（第 06 章隐式 Intent），定位被拒就手选城市
- 读写系统数据（通讯录、媒体库）用 `ContentResolver` + 官方 Contract 类，别琢磨文件路径直读——Scoped Storage 之下后者既不可行也不体面
- 硬件服务四步诀"取服务、拿源、注册、注销"背下来，位置与传感器如此，指南针、计步器也如此
- 第 15 章的 MemoPad 不涉及权限与硬件，但通知权限链路（第 10 章）与本章第 2 节的流程会在你自己的扩展需求里天天见面

---
上一章：[10 BroadcastReceiver、Service 与通知](10-system-components.md) ｜ 下一章：[12 Jetpack Compose 基础](12-compose-basics.md)
