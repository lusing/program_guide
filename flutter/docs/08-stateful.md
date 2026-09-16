# 08 · 有状态 Widget：setState 与生命周期

> 对应示例：examples/08_stateful/

## 8.1 解决什么问题

第 03 章立了规矩：Widget 是不可变配置。那点击计数怎么涨、输入框怎么联动？答案是把"会变的部分"从配置里搬出去，放进一个**长期存活的 State 对象**——StatefulWidget 就是"配置 + State"的组合体。理解这对搭档的分工（谁不可变、谁活着、谁重建），是从"能搭界面"到"能写应用"的分水岭。

```dart
// ═══ 8.1 StatefulWidget = 配置 + State：状态活在这 ═══
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});

  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState extends State<CounterPage> {
  int _count = 0;
  // ═══ 8.3 TextEditingController：读输入框内容/预填文本 ═══
  final _nameCtrl = TextEditingController();
```

分工：`CounterPage`（配置，可 const、可重建 N 次）与 `_CounterPageState`（状态，**页面存活期间只有一个**）。State 里放可变字段 `_count`——按惯例加下划线私有（[Dart 教程·第 07 章](../dart/docs/07-classes.md) 的库级私有）。热重载改的是配置侧，State 保留——这就是热重载"状态不丢"的原理。

## 8.2 生命周期：initState → build* → dispose

```dart
  // ═══ 8.2 生命周期：initState 做一次性准备 ═══
  @override
  void initState() {
    super.initState();
    _nameCtrl.text = '阿 Dart';
  }

  // ═══ 8.2（续）dispose：离开页面时释放资源 ═══
  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }
```

| 阶段 | 何时 | 该干什么 |
|---|---|---|
| `initState` | 插入树，仅一次 | 一次性准备：控制器初值、发首个请求、订阅流 |
| `build` | **多次**（初始化+每次 setState 后） | 纯描述界面 |
| `didUpdateWidget` | 父级给了新配置 | 对比 widget.xxx 变化做响应（少用） |
| `dispose` | 移出树，仅一次 | 释放：controller.dispose、取消订阅 |

两条纪律：**重活进 initState 不进 build**（build 会被频繁调用）；**创建于 State 的资源在 dispose 释放**（成对出现）。

## 8.3 TextEditingController：受控的输入

```dart
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: '名字'),
            ),
            const SizedBox(height: 8),
            Text('你好，${_nameCtrl.text}'),
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () => setState(() {}), // 手动触发重建，Text 才会刷新
              child: const Text('刷新问候'),
            ),
```

TextField 是"表面自由、背后受控"的组件：不传 controller 它自己管自己；传入 controller 后你既能**预填**（initState 里 `text = '阿 Dart'`）也能**随时读取**（`_nameCtrl.text`）。示例特意演示了一个关键事实：**改 controller.text 不会触发重建**——"刷新问候"按钮用 `setState(() {})`（空回调，只为触发 build）才让问候语更新。真正的输入联动做法是给 controller 加 listener（`_nameCtrl.addListener(...)` 里 setState）。

## 8.4 setState：标记重建，不是"赋值语法糖"

```dart
            // ═══ 8.4 setState：告诉框架"状态变了，重新 build" ═══
            FilledButton(
              onPressed: () => setState(() => _count++),
              child: const Text('加一'),
            ),
```

setState 做两件事：跑你的回调（改状态）+ **标记这个 State 需要重建**，下一帧框架重新调 build。两个常见误解：在回调外改 `_count` 界面不动（没标记）；`setState(() => someAsyncFn())` 会炸——回调必须同步（箭头函数返回 Future 会被框架拒绝，Dart 的赋值表达式有返回值，留意）。

## 8.5 重建范围与优化直觉

setState 重建的是**整个 State 的 build**。界面小时无所谓；某块区域重建昂贵（复杂列表项、动画）就把它拆成独立的小 StatefulWidget/StatelessWidget——重建范围跟着组件边界走。更系统的状态共享（跨页面、跨组件）是第 09 章的事。

## 坑位清单

- **build 里 setState**：死循环（build 中标记重建）。
- **initState 里用 ScaffoldMessenger/Navigator**：树还没插完，祖先不可达——这类调用放 `didChangeDependencies` 或延后到回调里。
- **dispose 后访问 controller**：抛错；异步回调里用资源前查 `mounted`（第 10 章的 async 回调同理）。
- **忘 dispose**：TextEditingController/AnimationController/StreamSubscription——凡是 initState 里 new 的资源，dispose 里成对释放。
