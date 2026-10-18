# 09 · 状态提升与共享：数据放哪

> 对应示例：examples/09_state_sharing/

## 9.1 解决什么问题

第 08 章的状态住在一个 State 里，够单页用。但真实应用马上遇到两个问题：**两个兄弟组件要读同一份数据**（计数按钮在 A 组件、显示在 B 组件）；**状态要跨页面/跨层级流动**。Dart/Flutter 给的原生答案有两层：状态提升（组织术）与 InheritedNotifier（广播术）——本章都练一遍，最后看生态里的工具在解决什么。

## 9.2 状态提升：数据放公共祖先

```dart
// ═══ 9.1 状态提升：两个子组件通过父级共享同一份数据 ═══
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('状态共享')),
      body: const Column(
        children: [
          CartAdder(), // 子 A：只负责改
          CartViewer(), // 子 B：只负责显示
        ],
      ),
    );
  }
}
```

提升（lifting state up）的规矩：**数据放能看见所有使用者的最近公共祖先**，改数据的函数也由祖先下发，子组件通过回调上抛事件。数据向下（构造参数）、事件向上（回调）——单向数据流，出问题时排查路径清晰。局限也明显：层级一深，中间组件被迫当"传菜员"（每层转发一遍构造参数）——这正是下一节要解决的。

### 单向数据流

状态提升形成的"数据下传、事件上抛"结构就是单向数据流（unidirectional data flow）：

```text
        CartPage (持有 _count)
        ↓ 传 count      ↑ 传 onAdd 回调
    ┌───────┴───────┐
    ↓               ↓
CartViewer      CartAdder
"显示 count"    "点按钮调 onAdd"
```

子组件不直接改共享数据——它们发事件（调回调），由祖先决定怎么改。这条纪律让数据变更路径唯一（只有 CartPage 的 setState 一处），排查"谁改了数据"时不用全树搜索。

## 9.3 ChangeNotifier：可监听的状态对象

```dart
// ═══ 9.3 ChangeNotifier：一个可监听的状态对象 ═══
class Cart extends ChangeNotifier {
  int count = 0;

  void add() {
    count++;
    notifyListeners(); // 通知所有监听者重建
  }
}
```

ChangeNotifier 是 Flutter 自带的**观察者基类**（`Listenable` 的标准实现）：状态对象自己管理"谁在听我"（`addListener`/`removeListener`），改完数据 `notifyListeners()` 一声令下，所有监听者各自重建。**谁改谁通知**——不靠 setState，粒度跟着监听者走。

### ChangeNotifier 的 API 面

| 方法 | 用途 |
|---|---|
| `addListener(VoidCallback)` | 注册监听者 |
| `removeListener(VoidCallback)` | 注销监听者 |
| `notifyListeners()` | 通知全部监听者（必须在数据变更后调用） |
| `dispose()` | 释放（dispose 后再 notifyListeners 会抛错） |

`notifyListeners` 的调用时机：在**状态字段更新之后**——先改后通知，监听者读到的才是新值。dispose 后调用 notifyListeners 在 debug 模式会触发 assert（"A ChangeNotifier was used after being disposed"）——异步操作回调里先查 `mounted` 再改状态。

### 与 setState 的关系

setState 是"标记这个 State 重建"；notifyListeners 是"通知所有监听者重建"。两者都是"改完数据喊一声"，区别在于 setState 只管自己，notifyListeners 管所有订阅者。ChangeNotifier 模式让状态对象**脱离 Widget 树存活**——它可以放在任何地方（全局单例、InheritedWidget 的字段、甚至另一个 Isolate），监听者各自决定怎么响应。

## 9.4 InheritedNotifier：沿树广播 + 自动订阅

```dart
// ═══ 9.4 InheritedWidget：沿树向下广播、O(1) 取回 ═══
// 注意：Cart() 不是常量（ChangeNotifier 无 const 构造），所以 CartScope 不能是 const
class CartScope extends InheritedNotifier<Cart> {
  CartScope({super.key, required super.child}) : super(notifier: Cart());

  static Cart of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CartScope>()!.notifier!;
}
```

```dart
  @override
  Widget build(BuildContext context) {
    // ═══ 9.4（续）dependOn... 建立依赖：notifyListeners 时这里重建 ═══
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text('购物车：${CartScope.of(context).count} 件'),
    );
  }
```

InheritedWidget 是 Flutter 的"沿树广播"原语：放在树的任何位置，**所有后代都能 O(1) 取回**——你早就用过它：`Theme.of(context)`、`ScaffoldMessenger.of(context)`（第 06/07 章）全是这个套路。配合 InheritedNotifier（泛型收 ChangeNotifier）：

- **读**：`CartScope.of(context)`——`dependOn...` 版本顺手建立依赖关系；
- **改**：`CartScope.of(context).add()`——notifyListeners 后，**只有 depend 过的子树重建**，中间层纹丝不动；
- 传菜员问题消失：中间组件不需要知道 Cart 的存在。

读代码时认出这个模式：`Xxx.of(context)` = 向上找 XxxScope = 隐式订阅了它。

### InheritedNotifier 的自动订阅机制

`InheritedNotifier` 内部做了两件事：

1. **监听 notifier**：构造时 `notifier.addListener(_handleUpdate)`——notifier 变化时触发 `updateShouldNotify`
2. **通知依赖者**：`updateShouldNotify` 返回 true 时，所有 `dependOnInheritedWidgetOfExactType` 过的 Element 被标记重建

你不需要手写 addListener/removeListener——InheritedNotifier 替你管理监听生命周期（dispose 时自动 removeListener）。这是它比"手写 InheritedWidget + 手动 addListener"更简洁的原因。

### dependOn 与 getInheritedWidgetOfExactType 的区别

`context.dependOnInheritedWidgetOfExactType<T>()`：取回 + **建立依赖**（T 变化时当前 Element 重建）。
`context.getInheritedWidgetOfExactType<T>()`：只取回，**不建立依赖**（T 变化时当前 Element 不重建）。

什么时候用后者：一次性读取（比如 initState 里读一次主题色）——不需要随主题变化重建的场景。日常 `Xxx.of(context)` 都用 dependOn 版本。

## 9.5 生态选型：什么时候上工具

原生方案（提升 + InheritedNotifier）能撑大多数应用，但样板代码多（每个状态写一套 Scope/of）。生态工具解决的是**人体工学**：

| 方案 | 一句话 | 适合 |
|---|---|---|
| 原生（本教程） | 零依赖，理解原理 | 小应用、学习期 |
| provider | 官方风格的 InheritedNotifier 封装 | 中小应用首选 |
| Riverpod | 编译期安全、不依赖 BuildContext | 中大型、团队 |
| Bloc/RxDart | 流式事件驱动 | 大型、强规范团队 |

建议路径：**先用原生写痛了，再上 provider/Riverpod**——知道工具在替你做什么，才不会滥用。

### provider 在替你做什么

`package:provider` 的核心 `ChangeNotifierProvider` 就是本例 `CartScope` 的通用化——你写 `ChangeNotifierProvider(create: (_) => Cart(), child: ...)`，它替你生成 InheritedNotifier 层。消费侧 `context.watch<Cart>()` = `dependOn...`，`context.read<Cart>()` = `getInheritedWidgetOfExactType`（不重建）。看穿了这层，provider 没有任何魔法——只是把 9.3/9.4 的样板代码压缩成一行。

## 坑位清单

- **notifyListeners 忘调**：界面纹丝不动（改了数据没广播）——ChangeNotifier 的方法里，改完必通知。
- **InheritedNotifier 每次通知重建整片子树**：粒度控制靠"订阅范围小"（把 depend 收在真正用数据的叶子），不是无脑包全页。
- **const 构造里装 ChangeNotifier**：编译错（notifier 非常量）——CartScope 构造去掉 const。
- **提升后又全树 setState**：状态提上去了、通知却炸全页——该换成 notifier 精确重建。
- **dispose 后 notifyListeners**：ChangeNotifier 已释放还通知——异步回调里先查 mounted；ChangeNotifier 自己的 dispose 里调 notifyListeners 也是错的。
- **getInheritedWidgetOfExactType 当 watch 用**：取了不建立依赖，数据变了界面不更新——要订阅就用 dependOn 版本（或 provider 的 watch）。
---

上一章：[08 · 有状态 Widget：setState 与生命周期](08-stateful.md) ｜ 下一章：[10 · 导航与路由：页面的栈](10-navigation.md) ｜ 返回：[README](../README.md)
