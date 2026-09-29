# 19 · Widget 测试：自动化的界面验证

> 对应示例：examples/19_testing/

## 19.1 解决什么问题

每章的"验证"到目前都是人肉跑 `flutter run` 看一眼。**widget 测试**把"渲染一帧、点一下、断言界面"自动化——本教程 19 个工程能在几分钟内全量回归，靠的就是它。先分层再动手：

| 层 | 工具 | 速度 | 测什么 |
|---|---|---|---|
| 纯逻辑 | `test()`（Dart 教程·第 19 章同款） | 毫秒 | 不碰 Widget 的逻辑 |
| Widget | `testWidgets`（flutter_test） | 秒级 | 界面行为（渲染/交互） |
| 集成 | integration_test（生态） | 分钟 | 真机/多页流程 |

19 章工程本身就是"被测示例"：`lib/counter.dart` 纯逻辑 + `lib/main.dart` 薄 UI，test/ 下两层各一份。**纯逻辑下沉、UI 变薄**，是可测性的第一原则（与 [Dart 教程·第 19 章](../dart/docs/19-testing.md) 的"可测试设计"一脉相承）。

## 19.2 纯逻辑层：与 Dart 测试完全同构

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:testing_app/counter.dart';

void main() {
  group('Counter 纯逻辑', () {
    test('递增与复位', () {
      final c = Counter();
      c.increment();
      c.increment();
      expect(c.value, 2);
      c.reset();
      expect(c.value, 0);
    });

    test('0 再减抛 StateError（负例）', () {
      expect(() => Counter().decrement(), throwsStateError);
    });
  });
}
```

flutter_test 是 package:test 的超集（matcher/group/setUp 全通用）——Dart 教程 19 章的所有写法原样能用，只是 import 换成 flutter_test。**能下沉到纯逻辑的断言尽量下沉**：快、稳、好排错。

## 19.3 testWidgets 骨架：渲染、找、断言

```dart
void main() {
  testWidgets('点击 FAB 界面计数递增', (tester) async {
    await tester.pumpWidget(const TestingApp());
    expect(find.text('value = 0'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();
    expect(find.text('value = 1'), findsOneWidget);
  });
}
```

- **pumpWidget(x)**：把 x 挂到测试环境并渲染一帧；
- **pump()**：再走一帧（setState 后必须泵一帧才重建）；`pumpAndSettle()` 泵到没有动画/过渡为止；
- **tester.tap / enterText / longPress / drag**：注入交互。

finder 速查（选最specific 的）：

| Finder | 例子 |
|---|---|
| `find.text('…')` | 按文案（最常用） |
| `find.byType(TextField)` | 按类型 |
| `find.byIcon(Icons.add)` | 按图标 |
| `find.byKey(const Key('x'))` | 按 key（最稳，给测试专用节点打） |
| `find.widgetWithText(FilledButton, '删除')` | 类型+文案组合 |

matcher 补充：`findsNWidgets(3)`、`findsNothing`、`findsWidgets`（≥1）。

## 19.4 pump 与假时钟

widget 测试跑在 FakeAsync 里：**真实时间不流动**，`pump(Duration)` 推进假时钟——这就是为什么动画、Timer、Stream.periodic 都可控。两条经验（本章都踩过实雷）：

- **pumpAndSettle 的盲区**：settle 靠"还有没有帧要调度"；两个事件之间没有帧时它提前返回——定时器驱动的流要手动逐格 `pump(300ms)`（14 章示例）。
- **手势的收尾定时器**：双击识别器留 40ms 定时器，测试结束前 `pump(100ms)` 冲掉，否则"Timer is still pending"（07 章示例）。

## 19.5 可测性：把边界注入化

真实网络/文件/时钟进不了假时钟世界，两种处理：**依赖注入假实现**（13 章 fetcher、20 章 InMemoryStorage）与 **mock**（17 章 prefs 的 setMockInitialValues）。设计时就问一句："这个页面能不能在不碰真实 IO 的情况下 pump？"——能，就好测。

跑法：`flutter test` / `--plain-name "用例名"` / `--coverage`（配合 lcov 看覆盖率）。本仓库 build.ps1 -All 的全量验证就是 19 个工程各跑一遍。

## 19.6 集成测试：跑在真进程里的另一半

书 14.4 的集成测试讲的是老方案 flutter_driver（App 与"驾驶员"两个进程，经服务端口通信）——**现在这样**：`integration_test` 包（flutter.dev 第一方）把两者合进一个进程，测试代码直接编译进 App：

```yaml
# ═══ 19.6 pubspec ═══
dev_dependencies:
  integration_test:
    sdk: flutter
```

```dart
// ═══ 19.6 integration_test/app_test.dart（目录名是约定）═══
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('记事本全流程', (tester) async {
    app.main();                       // 启动整个应用（不是 pumpWidget 单页）
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '集成测试');
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('集成测试'), findsOneWidget);
  });
}
```

跑法：`flutter test integration_test/app_test.dart -d windows`（桌面也能跑！指定设备就是真机/模拟器）。与 widget 测试的分工：**widget 测试在进程外仿真 UI（毫秒级、可入 CI 全量），集成测试在真进程里走完整启动链路（插件初始化、真实窗口、多页流程）**。本教程的示例全部轻量，widget 测试层足够覆盖，故未引入集成测试工程；发布前拿它过一遍主流程是性价比最高的一道保险。

## 坑位清单

- **断言前忘 pump**：setState 之后界面还没重建——tap 后至少 `pump()` 一次。
- **find.text 命中多个**：同文案多处（如 AppBar 与正文）——换 byKey 或更 specific 的 finder。
- **真实 IO 塞进 testWidgets**：假时钟里事件不推进，测试卡死——注入/mock（19.5）。
- **await 期间页面已变**：异步回调后先查 `mounted` 再断言（生产代码同款纪律）。
---

上一章：[18 · 桌面专题：Windows 的一等公民](18-desktop.md) ｜ 下一章：[20 · 实战：记事本](20-notes.md) ｜ 返回：[README](../README.md)
