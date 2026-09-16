# 07 · 类与对象：构造函数的六种形态

> 对应示例：examples/07_classes.dart

## 7.1 解决什么问题

Java/C# 用"构造函数重载"解决"一个类多种建法"，Dart 干脆禁了重载（方法也不能重载！），改用一套**命名构造 + 初始化列表 + 工厂构造**的组合拳——这套拳法是读懂 Flutter 源码的第一关，也是本章主角。先看最简类：

```dart
class Point {
  final double x;
  final double y;

  Point(this.x, this.y); // 主构造：参数直赋字段
```

`Point(this.x, this.y)` 一行干三件事：声明参数、赋值字段、语法糖自动展开成 `Point(double x, double y) : x = x, y = y`。字段尽量 `final`——不可变对象没有"半初始化被人改了一半"的状态（要"改"就复制一个新的，见第 20 章 copyWith）。

## 7.2–7.4 构造函数家族：六种形态一张表

示例文件里 Point 类集齐了前四种，先看代码再上表：

```dart
  Point.origin()
      : x = 0,
        y = 0; // 命名构造 + 初始化列表

  Point.checked(double x, double y)
      : assert(x >= 0 && y >= 0, '坐标不能为负'),
        x = x,
        y = y; // 初始化列表：构造体之前执行，可做断言

  Point.alongX(double x) : this(x, 0); // 重定向构造：转发到主构造
```

| 形态 | 写法 | 干什么用 |
|---|---|---|
| 主构造 | `Point(this.x, this.y)` | 参数直赋字段 |
| 命名构造 | `Point.origin() : …` | 一个类多个"语义化出口"（替代重载） |
| 初始化列表 | `: 断言, 字段 = 值` | 构造体**之前**执行；给 final 字段赋值/校验的唯一前置位置 |
| 重定向构造 | `: this(…)` | 转发给别的构造，自身无逻辑 |
| 工厂构造 | `factory Point(…) { … }` | **自己决定返回哪个实例**（7.5） |
| 常量构造 | `const Point(0, 0)`（字段全 final） | 编译期实例，配合 const 规范化（第 03 章） |

命名构造是 Dart 的"重载替身"：`Point.origin()`、`Point.fromJSON(…)`、`Duration.zero`——名字即文档。初始化列表冒号后逗号分隔，先于构造体执行，`assert` 放这里能在开发期最早暴露非法参数。

## 7.5 工厂构造 factory：把"造对象"变成"可能不发新对象"

```dart
class Temperature {
  final double celsius;
  static final Map<double, Temperature> _cache = {};

  Temperature._(this.celsius); // 私有构造：外界只能走 factory

  factory Temperature(double celsius) {
    return _cache.putIfAbsent(celsius, () => Temperature._(celsius));
  }

  double get fahrenheit => celsius * 9 / 5 + 32;

  @override
  String toString() => '$celsius°C';
}
```

```dart
  var t1 = Temperature(25);
  var t2 = Temperature(25);
  print('factory 复用实例：${identical(t1, t2)}，25°C = ${t1.fahrenheit}°F');
```

`factory` 构造看起来像普通构造，但函数体里**自己 return 实例**：可以返回缓存（本例，`identical` 为 true 证明复用）、单例，甚至子类。配套手法是私有命名构造 `Temperature._`——下划线开头库内私有（见 7.6 的私有一节），外界只能走 factory 入口。这是 Dart 单例的标准写法之一。

## 7.6 getter/setter：成员的"门面"

```dart
  // ═══ 7.6 getter：像字段一样访问的计算属性 ═══
  double get distanceFromOrigin => math.sqrt(x * x + y * y);
```

```dart
class Account {
  double _balance = 0; // 下划线开头：库内私有

  double get balance => _balance;

  set balance(double value) {
    if (value < 0) {
      throw ArgumentError('余额不能为负');
    }
    _balance = value;
  }
}
```

getter 是"长得像字段的计算属性"：调用方写 `p.distanceFromOrigin`，实现方保留改成计算逻辑的自由。setter 用来拦截写入（校验/联动）。一个重要的 Dart 事实：**私有性以"库"为单位**（一个 .dart 文件就是一个库），`_balance` 挡住的是"别的文件"，不是"别的类"——同文件内所有类互相可见。这与 Java/C# 的 class-level private 不同，大文件要靠自觉拆分。

## 7.7 运算符重载与 ==：成对出现的仪式

```dart
  // ═══ 7.7 运算符重载与 == ═══
  Point operator +(Point other) => Point(x + other.x, y + other.y);
  Point operator *(double k) => Point(x * k, y * k);

  @override
  bool operator ==(Object other) =>
      other is Point && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
```

```dart
  print('p + p * 2 = ${p + p * 2}'); // 运算符重载参与表达式
  print('==(3,4): ${Point(3, 4) == p}（重写后按值比较）');
```

自定义类型想参与算术就重载运算符（`+`、`*`、`[]`、`==` 都是运算符）。但 `==` 有一条铁律：**重写 == 必须同时重写 hashCode**——它们是一对协议（相等的对象必须有相等的哈希），破坏它的话 Map/Set 里的对象会"凭空消失"。模板四步：`other is T` 判型 → 比字段 → `Object.hash(字段…)` 一行搞定哈希 → 顺手 toString。

## 坑位清单

- **重写 == 不重 hashCode**：Map 检索与 Set 判重全部失灵——IDE 的"生成 == 与 hashCode"或者手抄模板，永远成对写。
- **默认 == 是引用相等**：不重写时 `Point(3,4) == Point(3,4)` 是 false；自定义"值语义"类别忘了重写（record 自带，第 13 章）。
- **初始化列表里不能用 this**：`: this.x = …` 非法；列表阶段对象还没"出生"，只能给字段直接赋值。
- **factory 里访问不了实例成员**：factory 运行时还没有实例，只能用 static 成员（缓存表正是 static）。
- **私有是库级**：`_x` 挡不住同文件的邻居类；想隔离就拆文件。
