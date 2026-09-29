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

## 坑位清单

- **通道名两边不一致**：静默 `MissingPluginException`——先查字符串，域名风格防撞车。
- **invokeMethod 不包 try**：换个平台（Web/测试）就崩——三分支 try 是模板代码不是可选项。
- **宿主返回 null 没处理**：`invokeMethod<int>` 可空——null 走"未知"分支别硬拆箱。
- **改了宿主代码热重载找自信**：原生侧改动要完全重启 `flutter run`。
- **widget 测试直连真通道**：mock 挂 messenger 或注入函数（24 章手法），二选一。
- **自定义对象直接过河**：StandardCodec 只认基本类型与容器——复杂对象拆 Map 过河再组装。
