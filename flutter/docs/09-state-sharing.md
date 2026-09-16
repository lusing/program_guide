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

ChangeNotifier 是 Flutter 自带的**观察者基类**（也是 Listenable 的标准实现）：状态对象自己管理"谁在听我"，改完数据 `notifyListeners()` 一声令下，所有监听者各自重建。**谁改谁通知**——不靠 setState，粒度跟着监听者走。

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

## 9.5 生态选型：什么时候上工具

原生方案（提升 + InheritedNotifier）能撑大多数应用，但样板代码多（每个状态写一套 Scope/of）。生态工具解决的是**人体工学**：

| 方案 | 一句话 | 适合 |
|---|---|---|
| 原生（本教程） | 零依赖，理解原理 | 小应用、学习期 |
| provider | 官方风格的 InheritedNotifier 封装 | 中小应用首选 |
| Riverpod | 编译期安全、不依赖 BuildContext | 中大型、团队 |
| Bloc/RxDart | 流式事件驱动 | 大型、强规范团队 |

建议路径：**先用原生写痛了，再上 provider/Riverpod**——知道工具在替你做什么，才不会滥用。

## 坑位清单

- **notifyListeners 忘调**：界面纹丝不动（改了数据没广播）——ChangeNotifier 的方法里，改完必通知。
- **InheritedNotifier 每次通知重建整片子树**：粒度控制靠"订阅范围小"（把 depend 收在真正用数据的叶子），不是无脑包全页。
- **const 构造里装 ChangeNotifier**：编译错（notifier 非常量）——CartScope 构造去掉 const。
- **提升后又全树 setState**：状态提上去了、通知却炸全页——该换成 notifier 精确重建。
