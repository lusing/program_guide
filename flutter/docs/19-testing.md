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

## 坑位清单

- **断言前忘 pump**：setState 之后界面还没重建——tap 后至少 `pump()` 一次。
- **find.text 命中多个**：同文案多处（如 AppBar 与正文）——换 byKey 或更 specific 的 finder。
- **真实 IO 塞进 testWidgets**：假时钟里事件不推进，测试卡死——注入/mock（19.5）。
- **await 期间页面已变**：异步回调后先查 `mounted` 再断言（生产代码同款纪律）。
