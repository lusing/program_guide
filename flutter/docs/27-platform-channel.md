# 27 · 平台通道：MethodChannel 直通原生

> 对应示例：examples/27_platform_channel/（含真实 Windows C++ 宿主代码）

## 27.1 解决什么问题

Flutter 的 UI 层是纯 Dart，但设备能力（电池、传感器、系统设置）住在原生世界。第 24 章的 image_picker 之所以能拉起文件框，是因为它内部就藏着一座桥——**MethodChannel**。包不够用的时候，自己造桥。本章把书的经典例子（查电池）在 Windows 上完整走一遍：Dart 侧、C++ 宿主侧、测试侧三份代码，`flutter build windows` 实测过桥。

```text
Dart (invokeMethod) ──StandardMethodCodec──▶ BinaryMessenger ◀──▶ 宿主 (handler)
     Future<T>                                    消息               result.Success/Error
```

三份角色记牢：**Dart 是客户端**（异步调用、Future 返回）、**通道名是合同**（两边字符串一致）、**编解码自动**（基本类型 int/String/bool/List/Map 免费过河，自定义对象要自己序列化）。

## 27.2 Dart 侧：调用与异常三分支

```dart
// ═══ 27.2 通道名用域名风格保证全局唯一（书 18.1 的纪律） ═══
const _channel = MethodChannel('guide.flutter/battery');

Future<String> fetchBatteryLevel() async {
  try {
    final level = await _channel.invokeMethod<int>('getBatteryLevel');
    if (level == null || level < 0) return '电池状态未知';
    return '电池电量：$level%';
  } on PlatformException catch (e) {
    return '获取失败（${e.code}：${e.message}）';   // 宿主 result.Error(...)
  } on MissingPluginException {
    return '宿主没有实现这个通道';                    // result.NotImplemented / 无宿主
  }
}
```

宿主侧三种回话对应三种异常面：`Success(v)` → 正常返回；`Error(code, msg)` → `PlatformException`；`NotImplemented()` → `MissingPluginException`。**调用永远包 try**——同一份 Dart 代码会跑在你没实现通道的平台上（Web/测试环境）。

### 27.2.1 invokeMethod 的签名与语义

`MethodChannel.invokeMethod<T>(String method, [dynamic arguments])` 返回 `Future<T?>`。要点：

- **泛型 T 是"期望的返回类型"**：编解码器把宿主回传的字节解码成 Dart 值，你声明 `int` 就按 int 拆——宿主真回了 String 会抛 `TypeError`。T 可空（`Future<T?>`）因为宿主 `Success(null)` 是合法回话。
- **arguments 是动态类型**：StandardMethodCodec 支持 null/bool/int/double/String/Uint8List/List/Map 及其嵌套。传自定义对象前，先 `jsonEncode` 或手工拆成 Map。
- **异步是硬约束**：消息过 BinaryMessenger 走事件循环，宿主 handler 跑在平台线程。`await` 之前 UI 不会被卡——但这也意味着**不能在 build 里同步调通道**（第 14 章 FutureBuilder 的用武之地）。
- **错误传播**：宿主 `result.Error(code, message, details)` → Dart 侧 `PlatformException`（带 code/message/details 三字段，details 常放结构化数据）；宿主没实现 → `MissingPluginException`；通道存在但方法名没匹配（走了 `NotImplemented` 分支）也是 `MissingPluginException`。**两种异常都继承自 PlatformException 的父级，但捕获要分开写**——先 `on PlatformException` 再 `on MissingPluginException`，顺序反了 MissingPlugin 会被 Platform 吃掉。

### 27.2.2 反向调用：宿主 → Dart

MethodChannel 是双向的。Dart 侧 `channel.setMethodCallHandler(...)` 挂处理器，宿主侧（以 Android Kotlin 为例）`channel.invokeMethod("onBatteryChanged", level)` 主动推。典型场景：推送到达、支付回调、下载进度。注意 handler 里也要三分支 try——宿主代码也可能传错参数。

## 27.3 Windows 宿主侧：C++ 注册通道

生成的 `windows/runner/flutter_window.cpp` 里，`OnCreate()` 是注册时机（引擎就绪后）。三步：建通道、挂 handler、按方法名分发：

```cpp
// ═══ 27.3 windows/runner/flutter_window.cpp（节选） ═══
#include <flutter/method_channel.h>
#include <flutter/standard_method_codec.h>

bool FlutterWindow::OnCreate() {
  // ... 模板原有：CreateFlutterView / RegisterPlugins(engine) ...
  battery_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "guide.flutter/battery",                       // 与 Dart 侧字符串一致
          &flutter::StandardMethodCodec::GetInstance());
  battery_channel_->SetMethodCallHandler(
      [](const flutter::MethodCall<flutter::EncodableValue>& call,
         std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        if (call.method_name() == "getBatteryLevel") {
          SYSTEM_POWER_STATUS status;
          if (GetSystemPowerStatus(&status) && status.BatteryLifePercent <= 100) {
            result->Success(status.BatteryLifePercent);   // ← Dart 的 Future<int>
          } else {
            result->Error("UNAVAILABLE", "获取不到电池状态"); // 台式机/未知 → 255
          }
        } else {
          result->NotImplemented();                       // ← MissingPluginException
        }
      });
  return true;
}
```

与书 18.2 的 Android 版（`MainActivity.kt` 里 `setMethodCallHandler` + `BatteryManager`）、18.3 的 iOS 版（`AppDelegate.swift` 里 `UIDevice`）对照着读——**三个宿主的 handler 形状完全同构**：查方法名 → 干活 → `Success/Error/NotImplemented` 三选一。写一次就懂了所有插件的开箱结构。Windows 侧细节：头文件里给 `FlutterWindow` 加一个 `battery_channel_` 成员；`BatteryLifePercent` 为 255 表示"未知"（台式机常见），当错误处理（对应书 Android 版的 `-1` 分支）。

改完宿主代码**必须完全停掉重跑**——原生侧不走热重载/热重启（18 章桌面坑的原生版）。

### 27.3.1 C++ 宿主的类型映射

StandardMethodCodec 在 C++ 侧的载体是 `flutter::EncodableValue`（`std::variant` 的封装）。常用映射：

| Dart 类型 | C++ EncodableValue 构造 |
|---|---|
| null | `EncodableValue()` |
| bool | `EncodableValue(true)` |
| int（32 位内） | `EncodableValue(42)` |
| int（超 32 位）/ double | `EncodableValue(static_cast<int64_t>(x))` / `EncodableValue(3.14)` |
| String | `EncodableValue(std::string("..."))` |
| List | `EncodableValue(EncodableList{...})` |
| Map | `EncodableValue(EncodableMap{{EncodableValue(k), EncodableValue(v)}})` |

读参数用 `std::get<std::string>(call.arguments())` 之类——**取之前先判 `std::holds_alternative`**，宿主崩溃会直接带崩整个应用（不像 Dart 侧抛异常能接）。

## 27.4 通道家族：EventChannel 与 BasicMessageChannel

### 27.4.1 EventChannel：事件流

MethodChannel 是一问一答；**连续数据**（传感器读数、电量变化、下载进度）用 EventChannel：

```dart
// ═══ 27.4.1 Dart 侧：receiveBroadcastStream 拿到广播 Stream ═══
const _events = EventChannel('guide.flutter/batteryEvents');

Stream<int> batteryChanges() =>
    _events.receiveBroadcastStream().map((e) => e as int);
```

`receiveBroadcastStream()` 返回**广播 Stream**——多订阅者共享，cancel 一个不影响别人。页面里用 `StreamBuilder` 接（第 14 章），`dispose` 里取消订阅（第 08 章纪律）。宿主侧（Android Kotlin 示例）：

```kotlin
// 宿主侧：EventSink 推三样东西——Success(值) / Error(错) / EndOfStream(收尾)
EventChannel(engine.dartExecutor.binaryMessenger, CHANNEL_EVENTS)
    .setStreamHandler(object : StreamHandler {
        private var sink: EventSink? = null
        private val receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
                sink?.success(intent.getIntExtra(BatteryManager.EXTRA_LEVEL, -1))
            }
        }
        override fun onListen(arguments: Any?, events: EventSink?) {
            sink = events
            ctx.registerReceiver(receiver, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
        }
        override fun onCancel(arguments: Any?) {
            ctx.unregisterReceiver(receiver)   // Dart 侧 cancel 订阅时回调——清理在这
            sink = null
        }
    })
```

`onListen`/`onCancel` 与 Dart 侧 Stream 的生命周期严格对应：**第一个订阅者到达时 onListen，最后一个取消时 onCancel**。资源申请/释放挂在这对回调上，别在 handler 外部乱挂。

### 27.4.2 BasicMessageChannel：裸消息

无方法语义的双向消息通道，默认 `StandardMessageCodec`，可换 `StringCodec`/`BinaryCodec`/`JSONMessageCodec`：

```dart
// ═══ 27.4.2 双向持续通信：音频帧、日志流、自定义协议 ═══
const _audio = BasicMessageChannel<Uint8List>(
    'guide.flutter/audio', BinaryCodec());   // 二进制直通，零拷贝

// Dart → 宿主
_audio.send(audioBytes);
// 宿主 → Dart（持续推）
_audio.setMessageHandler((message) async {
  // message 是 Uint8List；返回值会作为 ack 回给宿主
  return Uint8List(0);
});
```

选型速查：

| 通道 | 语义 | Dart 侧形态 | 典型场景 |
|---|---|---|---|
| MethodChannel | 方法调用（一问一答） | `Future<T?>` | 查一次电池、弹系统对话框 |
| EventChannel | 事件流（一订阅多推送） | `Stream<T>` | 传感器、电量变化、位置更新 |
| BasicMessageChannel | 裸消息（双向持续） | `Future` + handler | 音频帧、自定义协议、混合栈通信 |

## 27.5 测试：mock 通道

真宿主在 widget 测试里不存在——mock 挂在 messenger 上（第一方手法，24 章"注入"之外的另一条路）：

```dart
// ═══ 27.5 把通道处理器整个换掉 ═══
TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    .setMockMethodCallHandler(_channel, (call) async {
  if (call.method == 'getBatteryLevel') return 87;
  if (call.method == 'boom') throw PlatformException(code: 'UNAVAILABLE');
  return null; // 模拟未实现
});
```

成功值、`PlatformException`、未实现三条分支都能在测试里精确复现（示例测试三连）。真机验证用 `flutter run -d windows`——笔记本上能看到真实电量，台式机走 `UNAVAILABLE` 分支。

### 27.5.1 mock 的现代化写法与边界

**"当年如此/现在这样"**：书年代用 `channel.setMockMethodCallHandler(...)` 实例方法——现已废弃，推荐 `tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, ...)` 或全局 `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger`。旧写法在 3.x 仍能用但会弹 deprecation 警告。

两个新纪律：

- **每个测试独立设置、独立清理**：`setMockMethodCallHandler(channel, null)` 清掉；或在 `tearDown` 里统一清。否则上个测试的 handler 会污染下一个。
- **官方立场**：mock 通道是**最后手段**（api.flutter.dev 的 TestDefaultBinaryMessenger 文档明说）。优先顺序：① mock 插件的公共 API（类实例直接替换）→ ② mock 插件的平台接口（联合插件的 platform interface）→ ③ mock 平台通道。理由：通道名/参数是插件内部细节，插件升级会变；且 federated 插件在不同平台的通道名可能不同，mock 了 Windows 的通道在 macOS 上测试会漏。自己写的通道（如本章的 `guide.flutter/battery`）不受此限——协议是你定的，mock 天经地义。

## 27.6 移动端宿主对照：Android 与 iOS 的四副面孔

本教程主线用 Windows C++ 宿主实测（27.3）；同一套 Dart 侧代码落到移动端，宿主注册长这样（书第 10 章给了 Java/Kotlin/OC/Swift 四版，这里按现代 API 校订——本节文档级，与 28 章 iOS 同待遇：Windows 主线上知道每步在干嘛）。

**Android · Kotlin（现代模板默认）**——入口从书年代的 `onCreate + getFlutterView()` 迁到 `configureFlutterEngine`：

```kotlin
// ═══ 27.6a android/app/src/main/.../MainActivity.kt ═══
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(engine: FlutterEngine) {
        super.configureFlutterEngine(engine)
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getBatteryLevel") {
                    val level = getBatteryLevel()       // BatteryManager 广播取值
                    if (level != -1) result.success(level)
                    else result.error("UNAVAILABLE", "电量不可用", null)
                } else result.notImplemented()
            }
    }
}
```

**Android · Java**：同结构，匿名内部类版 `new MethodChannel(getFlutterView(), CHANNEL).setMethodCallHandler(new MethodCallHandler() {...})` 是书当年的写法——`getFlutterView()` 与手调 `GeneratedPluginRegistrant.registerWith(this)` 均已废弃，注册插件由模板自动完成。

**iOS · Swift**——AppDelegate 里拿 root ViewController 的 messenger：

```swift
// ═══ 27.6b ios/Runner/AppDelegate.swift ═══
override func application(_ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: ...) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
        FlutterMethodChannel(name: CHANNEL,
                             binaryMessenger: controller.binaryMessenger)
            .setMethodCallHandler { call, result in
                // UIDevice.current.batteryLevel：-1.0 表示未知（模拟器）
                // 成功 result(level)、失败 result(FlutterError(code:...))
            }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
}
```

**iOS · Objective-C**：`FlutterMethodChannel channelWithName:binaryMessenger:` + block handler，书 10.3.1 的原版结构。

四版宿主对比 Windows C++（27.3），规律只有一条：**拿 messenger/二进制信使 → 建 channel → 挂 handler → success/error/notImplemented 三分支**。语言是皮，协议是骨。电量这个例子在各平台的"未知值"还各有性格：Windows `BatteryLifePercent == 255`、Android 广播拿不到、iOS `batteryLevel == -1.0`（模拟器恒如此）——跨平台的"未知"分支永远别省。

## 27.7 自定义编解码与大型对象过河

StandardMethodCodec 的免费午餐只覆盖基本类型 + 容器。复杂对象两条路：

- **拆 Map 过河**（推荐）：Dart 侧 `toMap()`/`fromMap()`，宿主侧对应字典。可读、可测、跨版本稳。
- **自定义 Codec**：实现 `MethodCodec` 接口（如基于 JSON 或 protobuf）。只在性能敏感（大对象高频传输）时考虑——两端各写一份编解码，测试矩阵翻倍。

大对象（图片、音频）**别走 MethodChannel 的参数/返回值**——用 `BasicMessageChannel + BinaryCodec` 零拷贝传字节，或干脆写临时文件传路径（第 17 章的纪律）。

## 坑位清单

- **通道名两边不一致**：静默 `MissingPluginException`——先查字符串，域名风格防撞车。
- **invokeMethod 不包 try**：换个平台（Web/测试）就崩——三分支 try 是模板代码不是可选项。
- **宿主返回 null 没处理**：`invokeMethod<int>` 可空——null 走"未知"分支别硬拆箱。
- **改了宿主代码热重载找自信**：原生侧改动要完全重启 `flutter run`。
- **widget 测试直连真通道**：mock 挂 messenger 或注入函数（24 章手法），二选一。
- **自定义对象直接过河**：StandardCodec 只认基本类型与容器——复杂对象拆 Map 过河再组装。
- **C++ 宿主 std::get 不判类型**：参数类型不对直接带崩应用——先 `holds_alternative` 再取。
- **EventChannel 资源泄漏**：`onCancel` 里不清理（receiver/listener 不注销）——Dart 侧 cancel 后宿主还在推，内存与电量双漏。
- **mock handler 跨测试污染**：上个用例的 handler 没清，下个用例断言莫名其妙通过/失败——`tearDown` 里统一置 null。
- **在 build 里同步 invokeMethod**：通道是异步的，build 里调返回 Future 没 await——用 FutureBuilder/StreamBuilder 挂（第 14 章）。
- **大对象走 MethodChannel 参数**：编解码 + 拷贝双开销——BinaryCodec 裸传或临时文件传路径。

---

上一章：[26 · Cupertino 与平台自适应](26-adaptive.md) ｜ 下一章：[28 · 移动端构建与发布：以 Android 为例](28-android-release.md) ｜ 返回：[README](../README.md)
