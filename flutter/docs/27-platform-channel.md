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

## 27.4 反向与流式：通道家族

- **native → Dart**：宿主也能 `channel->InvokeMethod(...)`，Dart 侧 `setMethodCallHandler` 接——通知类场景（推送到达、支付回调）。
- **EventChannel**：事件流（传感器连续读数、电量变化订阅）——Dart 侧是 Stream，宿主侧 sink 推送。用法同 MethodChannel 的兄弟。
- **BasicMessageChannel**：无方法语义的裸消息，少用。

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

## 坑位清单

- **通道名两边不一致**：静默 `MissingPluginException`——先查字符串，域名风格防撞车。
- **invokeMethod 不包 try**：换个平台（Web/测试）就崩——三分支 try 是模板代码不是可选项。
- **宿主返回 null 没处理**：`invokeMethod<int>` 可空——null 走"未知"分支别硬拆箱。
- **改了宿主代码热重载找自信**：原生侧改动要完全重启 `flutter run`。
- **widget 测试直连真通道**：mock 挂 messenger 或注入函数（24 章手法），二选一。
- **自定义对象直接过河**：StandardCodec 只认基本类型与容器——复杂对象拆 Map 过河再组装。
---

上一章：[26 · Cupertino 与平台自适应](26-adaptive.md) ｜ 下一章：[28 · 移动端构建与发布：以 Android 为例](28-android-release.md) ｜ 返回：[README](../README.md)
