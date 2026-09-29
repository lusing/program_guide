# 31 · Flutter 插件开发：把通道装进可复用的包

> 对应示例：examples/31_plugin/（guide_battery 插件：MethodChannel 问电量 + EventChannel 推充电状态；example/ 演示应用一屏看懂两条通道）

## 31.1 解决什么问题

第 27 章学会了在**应用里**写 `MethodChannel` 直通原生。但通道代码住在应用工程里，换个项目就得重抄一遍。**插件（plugin）就是把"Dart API + 各平台原生实现"打包成一个可复用库**——蓝牙、WiFi、手电筒，凡是 Dart 够不着的底层能力，都以插件形态存在：

```text
你的应用 ──依赖──▶ 插件包
                   ├── lib/*.dart        对应用暴露的 Dart API（唯一公面孔）
                   ├── windows/ *.cpp    Windows 原生实现
                   ├── android/ *.kt     Android 原生实现（同构）
                   ├── ios/ *.swift      iOS 原生实现（同构）
                   └── example/          演示应用（也是活的测试场）
```

素材对应《Flutter技术入门与实战（第 2 版）》13 章：13.1 版本号插件（插件工程入门）、13.2 电池插件（**MethodChannel 拿电量 + EventChannel 推状态**——本章主角）、13.3 Channel 详解（三剑客与四要素）、13.4 PlatformView。书上做 Android/iOS，我们在 Windows 上实测同一条路。

> **当年如此 → 现在这样**：书里的插件是"Flutter 1.0 + 无空安全"时代的代码——`static Battery _instance;`（可空实例字段）、`new List()`、Android 用 `Registrar.registerWith` 静态注册（v1 embedding）。今天的 `flutter create -t plugin` 产物已经是空安全 + 联邦结构 + 各平台现代注册方式，本章全部按现代形态走，旧写法只在对照时出现。

## 31.2 创建插件工程：解剖模板产物

```bash
flutter create --template=plugin --platforms=windows --project-name guide_battery 31_plugin
```

模板生成的**不是**单文件通道，而是三层"联邦"结构（federated plugin）：

| 文件 | 角色 | 谁碰它 |
|---|---|---|
| `lib/guide_battery.dart` | 应用层 API：`GuideBattery` 类 | 使用插件的人 |
| `lib/guide_battery_platform_interface.dart` | 抽象契约：`abstract class ... extends PlatformInterface` | 定义"必须实现什么" |
| `lib/guide_battery_method_channel.dart` | 默认实现：两条通道 + 值映射 | 各平台的通道翻译 |
| `windows/guide_battery_plugin.cpp/.h` | C++ 原生实现 | 平台开发者 |
| `example/` | 演示应用（独立 pubspec，`path: ../` 依赖插件） | 联调与验收 |

```dart
// ═══ 31.2 应用层：只有 API，没有通道 ═══
class GuideBattery {
  Future<int> batteryLevel() =>
      GuideBatteryPlatform.instance.batteryLevel();     // 转发给"当前实现"
  Stream<BatteryStatus> onBatteryStatus() =>
      GuideBatteryPlatform.instance.onBatteryStatus();
}
```

为什么隔一层接口？**可替换性**。测试时塞一个假实现（`GuideBatteryPlatform.instance = MockX()`）、某平台想走非通道方案（FFI、纯 Dart），都不动应用代码。`PlatformInterface` 基类还带"token 门禁"：不是 `with MockPlatformInterfaceMixin` 的类冒充实现，setter 直接断言拒绝——防止平台实现之间意外串味。

## 31.3 MethodChannel：电量一问一答

Dart 侧（`guide_battery_method_channel.dart`）：

```dart
// ═══ 31.3 ═══
@visibleForTesting
final methodChannel = const MethodChannel('guide_battery');  // 接头暗号

@override
Future<int> batteryLevel() async {
  final level = await methodChannel.invokeMethod<int>('getBatteryLevel');
  return level!;                       // 原生若 Error()，这里抛 PlatformException
}
```

C++ 侧（`windows/guide_battery_plugin.cpp`，27 章的 `GetSystemPowerStatus` 搬进插件）：

```cpp
// ═══ 31.3 ═══
if (method_call.method_name().compare("getBatteryLevel") == 0) {
  SYSTEM_POWER_STATUS sps;
  if (GetSystemPowerStatus(&sps) && sps.BatteryLifePercent != 255) {
    result->Success(flutter::EncodableValue(
        static_cast<int32_t>(sps.BatteryLifePercent)));
  } else {
    result->Error("UNAVAILABLE", "battery level not readable on this machine");
  }
} else {
  result->NotImplemented();
}
```

与 27 章应用侧通道的三点不同：**通道常量变成插件的公开契约**（两端一字不差）；**错误要有出口**（台式机没电池 → `Error(code, message)` → Dart 侧 `PlatformException`，example 的 FutureBuilder 走错误分支给"重试"）；**注册自动化**——插件通过 `pluginClass` 写进 pubspec，构建时被工具链自动挂载，应用零配置。

## 31.4 EventChannel：状态推送流

电量是"问一次答一次"；充电状态是**持续变化的**——插拔电源、充满，都在原生层先知道。轮询（每秒调一次 MethodChannel）浪费且迟钝；正确姿势是 `EventChannel`：**原生主动推，Dart 当流听**。

Dart 侧：

```dart
// ═══ 31.4 ═══
@visibleForTesting
final eventChannel = const EventChannel('guide_battery_status');

@override
Stream<BatteryStatus> onBatteryStatus() {
  return _onStatus ??= eventChannel
      .receiveBroadcastStream()               // 广播流：多订阅者共享一次 listen
      .map((dynamic event) => _parseStatus(event as String));
}
```

C++ 侧给事件通道挂一对 `StreamHandlerFunctions`——它们对应 Dart 流的 `onListen`/`onCancel`：

```cpp
// ═══ 31.4 ═══
auto handler =
    std::make_unique<flutter::StreamHandlerFunctions<flutter::EncodableValue>>(
        [plugin_pointer = plugin.get()](
            const flutter::EncodableValue *arguments,
            std::unique_ptr<flutter::EventSink<flutter::EncodableValue>> &&events) {
          plugin_pointer->StartStatusStream(std::move(events));  // onListen
          return nullptr;
        },
        [plugin_pointer = plugin.get()](const flutter::EncodableValue *arguments) {
          plugin_pointer->StopStatusStream();                    // onCancel
          return nullptr;
        });
plugin->status_channel_->SetStreamHandler(std::move(handler));
```

生命周期是本章的核心心智模型：

```text
Dart listen()  ──▶ 原生 onListen(sink)   ──▶ 启动轮询线程
原生 sink->Success(value) ──▶ Dart 流吐出事件 ──▶ StreamBuilder 重建
Dart cancel()  ──▶ 原生 onCancel()       ──▶ 停线程、放掉 sink
```

教学版轮询线程每 500ms 读一次 `GetSystemPowerStatus`，**状态变化才推**（`status != last`）。生产级会改听 `WM_POWERBROADCAST` 广播——机制不变，事件源更优雅。三处工程细节：轮询线程与 sink 的访问用 `std::mutex` 保护（onCancel 可能在拖动线程里发生）；析构先停线程再拆成员（垂死的 sink 不许被引用）；重复 listen（热重启场景）先清旧线程。

**值的纪律**：通道只传朴素值（字符串/数字/列表/字典——`StandardMessageCodec` 认识的类型）。原生推 `'charging'` 字符串，Dart 侧 `_parseStatus` 映射回 `enum BatteryStatus`——两端各自演进枚举也不至于炸，未知标签在 map 阶段炸 `ArgumentError`（值域由插件收口）。

## 31.5 Channel 三剑客与四要素

书 13.3 的总结至今成立。三种通道各司其职：

| 通道 | 方向 | 语义 | 本章实例 |
|---|---|---|---|
| `MethodChannel` | 双向请求/响应 | 方法调用 + 返回值/异常 | `getBatteryLevel` |
| `EventChannel` | 原生 → Dart | 持续事件流 | 充电状态推送 |
| `BasicMessageChannel` | 双向消息 | 朴素报文，无方法语义 | 传大块数据/双工通信 |

每种通道都由同样四要素构成：

- **name**（String）：全局唯一接头暗号，跨端一字不差；
- **messager**（BinaryMessenger）：真正收发二进制消息的邮局，通道只是挂在其上的"分拣规则"；
- **codec**（Codec）：`StandardMessageCodec`（默认，支持 null/bool/num/String/ByteData/List/Map）/`JSONMessageCodec`/`StringCodec`/`BinaryCodec`，方法通道还有对应的 MethodCodec 两兄弟；
- **handler**（Handler）：收信人——`MethodHandler`（onMethodCall 分发方法）、`StreamHandler`（onListen/onCancel 管流）、`MessageHandler`（纯收信）。

EventChannel 的实现真相：**它就是一条以 listen/cancel 为方法名的 MethodChannel**——Dart `listen` → 原生 `onListen`；之后原生用"成功信封"（codec 编码的事件体）直接发往通道名，Dart 流就吐事件。理解了这一点，31.6 的测试注入法就顺理成章。

## 31.6 插件的测试：两层各测各的

**接口层测试**（`test/guide_battery_test.dart`）不碰通道——换掉 `GuideBatteryPlatform.instance` 塞假实现，验证联邦结构的可替换性是动真格的（没带 token 的裸类会被 `PlatformInterface.verifyToken` 拒绝）。

**通道层测试**（`test/guide_battery_method_channel_test.dart`）mock 原生：方法通道照旧 `setMockMethodCallHandler`；**事件通道用信封注入法**——基于 31.5 的真相：

```dart
// ═══ 31.6 ═══
// 1) mock 掉 listen/cancel 的"握手"
setMockMethodCallHandler(const MethodChannel('guide_battery_status'), ...);
// 2) 模拟原生 sink->Success(label)：成功信封直接投给 Dart
await messenger.handlePlatformMessage(
  'guide_battery_status',
  const StandardMethodCodec().encodeSuccessEnvelope('charging'),
  (_) {},
);
// → 订阅者的 onData 立刻收到 BatteryStatus.charging
```

用这套注入可以精确断言**广播语义**：两个订阅者共享一次 `listen`、最后一个退订才触发 `cancel`（`receiveBroadcastStream` 的缓存让多订阅者复用同一条底层流）。

**example 应用层**（`example/test/`）再mock 一遍通道，测 UI 三态与状态换脸——插件的使用者同样不需要真机。模板还送了 `integration_test/`（真机跑的原生集成测试）；我们删掉了它——原生侧由 build.ps1 的 `flutter build windows` 硬验证（连 C++ 一起编译），教学重心放在 Dart 两层。

## 31.7 PlatformView 与更大世界

**PlatformView**：把原生视图**嵌进** Flutter 页面（书 13.4：Android `AndroidView`、iOS `UIKitView`）——地图、WebView、视频播放器这类"画不出来只能借"的控件。Dart 侧声明 `UiKitView(viewType: 'maps')`，原生侧注册视图工厂。代价是合成开销与生命周期复杂度，能用组合控件替代就别上 PlatformView。**Windows 桌面**对 PlatformView 的支持远不如移动端成熟——需要嵌入原生控件时，优先考虑整窗（多窗口）或纹理（Texture/ExternalTexture）方案。

**联邦插件的完全体**：本章单平台插件里三层文件同居一包。发布到 pub.dev 的跨平台大插件会拆成三个包——`xxx`（应用层）、`xxx_platform_interface`（契约）、`xxx_windows`/`xxx_android`/...（各端实现，各有版本号）——各端独立演进、社区可给冷门平台补实现。结构即 31.2 的物理拆分版。

**开发体验提示**：改原生代码没有热重载，得完全重启；Android Studio 的"打开 Android 模块"、Xcode 的"打开 iOS 模块"是为了让原生侧也能断点调试——Windows 插件的 C++ 直接用 VS 打开 `example/build/windows/x64/*.sln` 即可。

## 坑位清单

- **C++ 宿主禁中文注释（重申 27 章铁律）**：UTF-8 无 BOM 的中文注释被 MSVC 按本地码页误读，一个警告（被当错误）+ 雪崩式语法错——报错位置离谱时先查文件里有没有非 ASCII 字符。
- **`StreamHandlerFunctions` 在 `event_stream_handler_functions.h`**：模板只 include 了 method_channel 头，事件通道的头要自己补，否则"不是 flutter 的成员"+ 一串怪错（`__this 不是成员` 这种）。
- **EventSink 的方法叫 `Success` 不叫 `Event`**：Windows C++ wrapper 对齐 Dart 流语义（`Success/Error/EndOfStream`），不是 Android Java 端的 `event()`。
- **模板的 googletest 1.11 与新 CMake 不容**：`# === Tests ===` 段 `FetchContent` 拉的 googletest 声明 `cmake_minimum_required < 3.5`，CMake 4.x 直接拒配——本仓库删掉了这段原生单测脚手架（保留见 19.6 的 Dart 集成测试思路）。
- **CMake 缓存中毒**：失败的配置会把默认 `CMAKE_INSTALL_PREFIX`（`C:/Program Files/...`）写进 cache，之后修好源码也报"cannot create directory: C:/Program Files/xxx"——`rm -rf build`（或 `flutter clean`）重配才好。
- **example 是独立包**：根包 `flutter analyze` 会连 example 的文件一起查（报错路径带 `example\` 前缀），但根包 `flutter test` 不跑 example 的测试——验证脚本两处都要跑。
- **`invokeMethod<int>` 的类型对不上会炸 TypeError**：原生返回的整数实际是 `int`，但两端约定错类型（如按 String 收）在 await 处崩——插件作者要把类型兜在实现层。
- **书时代的空安全差异**：`static Battery _instance;`（可空字段）、`Future get batteryLevel`（无泛型）都是无空安全写法；现代插件 SDK 约束 `sdk: ^3.x`，照书抄会满屏告警。

---

上一章：[30 · 国际化](30-i18n.md) ｜ 下一章：[32 · IM 聊天界面实战](32-im-ui.md) ｜ 返回：[README](../README.md)
