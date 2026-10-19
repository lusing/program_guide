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

### 为什么配置和状态要分开

回忆第 03 章的三棵树模型：Widget 树是"不断重建的图纸"，Element 是"稳定的厂房"。StatefulWidget 的拆法正是这个模型的直接推论——**Widget 层随便重建（图纸便宜），State 层长期存活（厂房里的机器不能随便搬）**。`createState()` 只在 Element 首次挂载时调用一次，之后无论 Widget 重建多少次，State 都是同一个实例。这个"配置换、状态留"的机制让框架可以大胆重建 Widget，同时保住用户输入、滚动位置、动画进度这些"活着的数据"。

### mounted：State 还在不在树里

每个 State 都有一个 `mounted` 布尔属性：true = 这个 State 对应的 Element 还在树里。异步操作（网络请求、定时器、文件读写）的回调里用 `mounted` 判断"页面还在吗"——用户可能在等待期间退出了页面：

```dart
Future<void> _load() async {
  final data = await api.fetch();
  if (!mounted) return;  // 页面已销毁，setState 会抛错
  setState(() => _data = data);
}
```

`setState` 在 unmounted 的 State 上调用会抛 `setState() called after dispose()`——所有 async 回调的标配守卫（第 10/13/14 章反复出现）。

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
| `didChangeDependencies` | initState 后 + 依赖的 InheritedWidget 变化时 | 需要 context 的初始化（Theme.of、Localizations.of） |
| `build` | **多次**（初始化+每次 setState 后） | 纯描述界面 |
| `didUpdateWidget` | 父级给了新配置 | 对比 widget.xxx 变化做响应（少用） |
| `deactivate` | 子树被临时移出树（GlobalKey 复用） | 极少重写 |
| `dispose` | 移出树，仅一次 | 释放：controller.dispose、取消订阅 |

两条纪律：**重活进 initState 不进 build**（build 会被频繁调用）；**创建于 State 的资源在 dispose 释放**（成对出现）。

### initState 与 didChangeDependencies 的分工

两个"初始化"钩子的区别在 context 的可用性：

- `initState` 里 **不能用 `context` 依赖祖先**（Theme.of、MediaQuery.of、Navigator.of 都会抛"dependOnInheritedWidgetOfExactType 不能在 initState 调用"）——树还没插完，祖先链未建立。
- `didChangeDependencies` 里可以——它在树建立后立刻调用，且每当依赖的 InheritedWidget 变化时再次调用。

实操规则：**不碰 context 的初始化放 initState**（建 controller、设初值、发起不依赖 context 的请求）；**要读 Theme/MediaQuery 的初始化放 didChangeDependencies**。大多数页面的 didChangeDependencies 可以空着——需要它的典型场景是"按主题/语言动态调整初始状态"。

### didUpdateWidget：配置变了怎么响应

父级重建时如果给了 StatefulWidget 新的配置（比如 `DetailPage(id: 7)` 变成 `DetailPage(id: 8)`），框架**复用同一个 State** 但调用 `didUpdateWidget(oldWidget)`——你可以对比 `widget.id != oldWidget.id` 决定要不要重新拉数据：

```dart
@override
void didUpdateWidget(covariant DetailPage oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (widget.itemId != oldWidget.itemId) {
    _load();  // id 变了，重新加载
  }
}
```

注意 `covariant` 关键字——收窄参数类型到具体 Widget 类。日常用得少（大多数页面的配置不变或整页替换），知道它存在即可。

### deactivate：几乎用不到的钩子

`deactivate` 在子树被**临时**移出树时调用（GlobalKey 把 State 从一个位置挪到另一个位置）——正常页面进出不经过它（直接 dispose）。99% 的 State 不需要重写 deactivate。

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

TextField 是"表面自由、背后受控"的组件：不传 controller 它自己管自己；传入 controller 后你既能**预填**（initState 里 `text = '阿 Dart'`）也能**随时读取**（`_nameCtrl.text`）。示例特意演示了一个关键事实：**改 controller.text 不会触发重建**——"刷新问候"按钮用 `setState(() {})`（空回调，只为触发 build）才让问候语更新。

### 实时联动：addListener

要"边输边联动"（输入框一变，下面的预览跟着变），给 controller 挂 listener：

```dart
@override
void initState() {
  super.initState();
  _nameCtrl.addListener(_onNameChanged);
}

void _onNameChanged() => setState(() {});  // text 变了，重建让 Text 读到新值

@override
void dispose() {
  _nameCtrl.removeListener(_onNameChanged);  // 先摘监听
  _nameCtrl.dispose();
  super.dispose();
}
```

`_nameCtrl.addListener(_onNameChanged)` 注册回调——每次文本变化（包括程序赋值）都触发。dispose 的顺序：先 `removeListener` 再 `dispose`（虽然 dispose 本身会清监听，显式 remove 是双保险，也避免 dispose 后 listener 被误触发）。

### selection 与编程控制光标

`controller.selection` 读写当前选区——`TextSelection.collapsed(offset: 0)` 把光标移到开头。配合 `FocusNode.requestFocus()` 实现"页面打开聚焦搜索框且光标在末尾"这类细节。

## 8.4 setState：标记重建，不是"赋值语法糖"

```dart
            // ═══ 8.4 setState：告诉框架"状态变了，重新 build" ═══
            FilledButton(
              onPressed: () => setState(() => _count++),
              child: const Text('加一'),
            ),
```

setState 做两件事：跑你的回调（改状态）+ **标记这个 State 需要重建**（内部调 `Element.markNeedsBuild()`），下一帧框架重新调 build。三个常见误解：

1. **回调外改状态界面不动**：`_count++;` 之后没调 setState，框架不知道要重建——赋值和标记是两步。
2. **`setState(() => someAsyncFn())` 会炸**：回调必须同步返回 void；箭头函数若返回 Future（比如 `setState(() => _future = fetch())`），框架会拒绝——写块体 `{ _future = fetch(); }`。
3. **setState 立即重建**：不是——它只是"标记"。真正的 build 在下一帧，多个 setState 会合并成一次重建。

### setState 的调用时机限制

`setState` 不能在 build 阶段调用——build 正在重建时标记"需要重建"是逻辑死循环（框架直接抛错）。异步回调、事件处理器（onPressed）、timer 回调里都可以；唯一禁区是 build 方法本身及其同步调用链。

## 8.5 重建范围与优化直觉

setState 重建的是**整个 State 的 build**。界面小时无所谓；某块区域重建昂贵（复杂列表项、动画）就把它拆成独立的小 StatefulWidget/StatelessWidget——重建范围跟着组件边界走。更系统的状态共享（跨页面、跨组件）是第 09 章的事。

这个直觉的量化验证在第 25 章：const 构造的子树在父级重建时直接跳过（identical 检查），拆出去的子组件只在自己的 setState 时重建。两条规则配合：**变化半径小的状态放小组件，静态子树全 const**。

## 8.6 热重载与 State 的关系

热重载（`r`）保留 State——改 build 方法里的 UI 代码，计数器/输入框的值不丢。这个"状态不丢"不是魔法，正是 8.1 架构的直接结果：热重载替换的是**代码（Widget 的 build 逻辑）**，State 实例原样保留。

两个例外需要热重启（`R`）：

- 改了 `initState` 的**逻辑**：State 没重建，initState 不会重跑——新逻辑不生效
- 加了/删了字段、改了字段类型：State 的对象布局变了，旧实例无法复用

判断口诀：**改 build 热重载，改 initState/字段热重启**。

## 坑位清单

- **build 里 setState**：死循环（build 中标记重建）。
- **initState 里用 ScaffoldMessenger/Navigator/Theme.of**：树还没插完，祖先不可达——这类调用放 `didChangeDependencies` 或延后到回调里。
- **dispose 后访问 controller**：抛错；异步回调里用资源前查 `mounted`（第 10 章的 async 回调同理）。
- **忘 dispose**：TextEditingController/AnimationController/StreamSubscription——凡是 initState 里 new 的资源，dispose 里成对释放。
- **addListener 后忘 removeListener**：dispose 时 controller.dispose 会清，但页面存活期间的重复 addListener（比如 didUpdateWidget 里又 add 一次）会累积——注册和注销成对写。
- **setState 里做网络请求**：回调必须同步——请求发起放回调外，回调里只更新状态字段。
- **didUpdateWidget 忘调 super**：框架钩子都要求先走 super——漏掉行为未定义。
---

上一章：[07 · 交互与对话框：点击、轻提示、确认](07-interaction.md) ｜ 下一章：[09 · 状态提升与共享：数据放哪](09-state-sharing.md) ｜ 返回：[README](../README.md)
