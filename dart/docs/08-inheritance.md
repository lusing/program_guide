# 08 · 继承、抽象与隐式接口

> 对应示例：examples/08_inheritance.dart

## 8.1 解决什么问题

Dart 没有 `interface` 关键字——初听奇怪，其实是 Dart 最重要的一条设计：**每个类都隐式定义了一个接口**。`class Dog extends Animal` 给你实现复用，而 `class Dog implements Animal` 是"我承诺实现 Animal 的所有成员，但一行实现都不要"。这条规则加上单继承，把 Java 里 class/interface 两套关键字的活合成了一套。

先看基座——抽象类：

```dart
// ═══ 8.3 抽象类：约定子类必须实现的行为 ═══
abstract class Shape {
  String get name; // 抽象 getter：无实现

  double area(); // 抽象方法

  // 抽象类可以有具体方法（供 extends 的子类复用）
  void describe() => print('$name 的面积是 ${area().toStringAsFixed(2)}');
}
```

`abstract` 类不能实例化，专做父类。注意它**可以同时有抽象成员和具体成员**——`describe()` 有实现、`area()` 没有。这直接支撑一个高频模式：

## 8.1/8.2 extends 与多态：模板方法模式

```dart
class Circle extends Shape {
  final double r;
  Circle(this.r);

  @override
  String get name => '圆';

  @override
  double area() => 3.14159 * r * r;
}
```

```dart
  // ═══ 8.1/8.2 继承复用与多态 ═══
  Shape c = Circle(2);
  c.describe(); // describe 来自抽象类，area 来自 Circle——模板方法模式

  for (final s in [Circle(1), Rect(3, 4), Square(5)]) {
    s.describe(); // 同一调用，不同实现
  }
```

`describe()` 的骨架写在父类，其中"变化点" `area()` 留给子类填——这就是模板方法模式，Flutter 源码到处都是（State 生命周期即此类）。多态规则与其他语言一致：**静态类型决定能调什么，运行时类型决定实际执行谁**。

`@override` 注解可写可不写，但永远该写——它让"想覆盖却拼错了名字"直接变成编译错误。

## 8.4 implicit interface：implements 的真义

```dart
// ═══ 8.4 implicit interface：每个类同时隐式定义一个接口 ═══
// implements 只拿"契约"（所有成员签名），不带任何实现
class Square implements Shape {
  final double side;
  Square(this.side);

  @override
  String get name => '正方形';

  @override
  double area() => side * side;

  @override
  void describe() => print('[$name] area=${area().toStringAsFixed(1)}（自己实现）');
}
```

关键区别一行见血：`Square implements Shape` 之后，**连 Shape 里带实现的 `describe()` 也必须自己重写**——implements 拿到的只是"成员清单"这个契约，不带任何实现。为什么？因为 Dart 承诺"任何类都能当接口用"：哪怕是一个普通的非抽象类，你都可以 implements 它来"声明我提供同样的能力"，而不背上它的实现包袱。

| | `extends Shape` | `implements Shape` |
|---|---|---|
| 得到实现 | 是（具体方法直接用） | 否（全部自己写） |
| 抽象成员 | 补齐即可 | 补齐 + 具体成员也要重写 |
| 数量 | 只能一个 | 可以多个 |
| 语义 | "是一个"（is-a） | "提供其能力"（can-do） |

## 8.5 多接口与 super 参数

```dart
// ═══ 8.5 一个类可以同时实现多个契约 ═══
abstract class Storable {
  Map<String, dynamic> toJson();
}

class StorableRect extends Rect implements Storable {
  StorableRect(super.w, super.h); // super 参数：直接转发给父类构造

  @override
  Map<String, dynamic> toJson() => {'w': w, 'h': h};
}
```

这一小段藏两件事：

- **组合三味**：`extends Rect`（要实现）+ `implements Storable`（再加一个契约），单继承与多接口并行不悖；
- **`super.w` 参数**：构造参数直接转发给父类构造，等价于 `StorableRect(double w, double h) : super(w, h);`，只是更短——Dart 2.17 起的惯用法。

## 8.6 三种组合方式选型

把第 09 章的 mixin 也放进表里提前占位：

| 写法 | 拿到什么 | 数量 | 适用 |
|---|---|---|---|
| `extends` | 实现复用 | 1 | "是一个"，子类是父类的特化 |
| `implements` | 纯契约 | 多 | "提供其能力"，自己全部实现 |
| `with`（第 09 章） | 横切行为片段 | 多 | 日志、缓存这类"与主类型无关的能力" |

选型口诀：**先问 is-a（extends）还是 can-do（implements），横切能力交给 mixin**。真实代码里 implements + mixin 用得远比深继承树多。

## 坑位清单

- **implements 后忘实现具体方法**：`describe()` 漏写是编译错误，错误信息会精确点名缺哪个成员——这不是坑，是编译器在替你查账。
- **抽象类不能 new**：`Shape()` 编译错；但抽象类可以有工厂构造与静态成员（`Shape.fromJson(…)` 是常见出口）。
- **多态看运行时**：`Shape s = Circle(2); s is Circle` 为 true；需要时可用模式匹配窄化（第 13 章），别用老式 as 强转。
- **深继承别超过两三层**：Dart 生态风格偏"组合优先"，继承树一深，`super` 调用链和初始化顺序都会变成负担（第 09 章的 mixin 是出路）。
