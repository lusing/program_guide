// ═══ 22.4 手写 scoped_model 核心 ≈ 60 行 ═══
// 历史事实：2018 年的 scoped_model 包里，Model 就是 ChangeNotifier 的子类——
// 观察者能力全部继承而来，包本身只做了"挂树 + 订阅"这层薄封装。
import 'package:flutter/widgets.dart';

/// 零件一：Model —— 可通知的状态基类。
abstract class Model extends ChangeNotifier {}

/// 零件二：ScopedModel —— 把一份中央状态挂到树上（通常包住 MaterialApp）。
class ScopedModel<T extends Model> extends StatelessWidget {
  const ScopedModel({super.key, required this.model, required this.child});

  final T model;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      _InheritedScope<T>(notifier: model, child: child);
}

class _InheritedScope<T extends Model> extends InheritedNotifier<T> {
  const _InheritedScope({required T super.notifier, required super.child});
}

/// 零件三：ScopedModelDescendant —— 订阅 + 取用。
/// notifyListeners 时只有 builder 重跑；child 是不随通知重建的"静态子树"。
class ScopedModelDescendant<T extends Model> extends StatelessWidget {
  const ScopedModelDescendant({super.key, required this.builder, this.child});

  final Widget? child;
  final Widget Function(BuildContext, Widget?, T) builder;

  @override
  Widget build(BuildContext context) => builder(
        context,
        child,
        context
            .dependOnInheritedWidgetOfExactType<_InheritedScope<T>>()!
            .notifier!,
      );
}
