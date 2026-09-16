import 'package:flutter/material.dart';

// 09 状态提升与共享：提升到父级、ChangeNotifier、InheritedWidget
void main() => runApp(const StateSharingApp());

class StateSharingApp extends StatelessWidget {
  const StateSharingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
      ),
      home: CartScope(child: const CartPage()),
    );
  }
}

// ═══ 9.3 ChangeNotifier：一个可监听的状态对象 ═══
class Cart extends ChangeNotifier {
  int count = 0;

  void add() {
    count++;
    notifyListeners(); // 通知所有监听者重建
  }
}

// ═══ 9.4 InheritedWidget：沿树向下广播、O(1) 取回 ═══
// 注意：Cart() 不是常量（ChangeNotifier 无 const 构造），所以 CartScope 不能是 const
class CartScope extends InheritedNotifier<Cart> {
  CartScope({super.key, required super.child}) : super(notifier: Cart());

  static Cart of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CartScope>()!.notifier!;
}

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

class CartAdder extends StatelessWidget {
  const CartAdder({super.key});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      // ═══ 9.3（续）谁改谁通知，监听者自动重建 ═══
      onPressed: () => CartScope.of(context).add(),
      child: const Text('加入购物车'),
    );
  }
}

class CartViewer extends StatelessWidget {
  const CartViewer({super.key});

  @override
  Widget build(BuildContext context) {
    // ═══ 9.4（续）dependOn... 建立依赖：notifyListeners 时这里重建 ═══
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text('购物车：${CartScope.of(context).count} 件'),
    );
  }
}
