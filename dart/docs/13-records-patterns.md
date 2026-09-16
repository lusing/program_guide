# 13 · 记录与模式匹配：Dart 3 的表达力跃迁

> 对应示例：examples/13_records_patterns.dart

## 13.1 解决什么问题

三个日常的样板代码场景：**返回两个值要专门建个类**；**switch 只能配常量**，判类型还得先 is 再 as 再判空；**解包对象字段要三行赋值**。Dart 3 的 records + patterns 把三件事一次解决——这是本教程最值得花时间的一章，第 09 章的 sealed 在这里兑现全部价值。

先看 record 本体：

```dart
  // ═══ 13.1 record：轻量结构化值，== 按结构比较 ═══
  var point = (x: 3, y: 4); // 命名字段 record
  var other = (x: 3, y: 4);
  print('point == other: ${point == other}（结构相等，无需重写 ==）');
  print('字段访问：x=${point.x}');
  var rgb = (255, 128, 0); // 位置字段 record
  print('位置字段：第一个=${rgb.$1}');
```

record 是**匿名的、不可变的、按结构比较的聚合值**。两种字段风格：

- **命名字段** `(x: 3, y: 4)`：用 `.x` 访问，适合"字段有名字才好读"的数据；
- **位置字段** `(255, 128, 0)`：用 `.$1`、`.$2` 访问，适合"位置即语义"的短元组。

`==` 自动按**全部字段的结构**比较（`point == other` 为 true），不用像类那样手写 == 和 hashCode（对比第 07 章）。record 与 class 的选型：**临时聚合/函数多返回值/轻量键 → record；有身份、有行为、要继承 → class**。

## 13.2 解构：一次声明多个变量

```dart
  // ═══ 13.2 解构：一次声明多个变量 ═══
  var (x: px, y: py) = point; // 命名字段解构：变量名可不同于字段名
  final (r, g, b) = rgb; // 位置字段解构
  print('解构：x=$px y=$py r=$r g=$g b=$b');
```

解构把"赋值"升级成"按形状拆开"：命名字段解构写 `字段名: 变量名`（变量名可以换，这也是给字段起中转名的手法）；位置解构按顺序接。注意命名字段 record 不能用位置模式解构（反之亦然）——形状必须对得上。

## 13.3 函数返回多值：告别 Pair 类

```dart
(int, int) bounds(List<int> list) {
  // ═══ 13.3 函数返回多值 ═══
  var min = list.first;
  var max = list.first;
  for (final n in list) {
    // …
  }
  return (min, max);
}
```

```dart
  // ═══ 13.3（续） ═══
  var (lo, hi) = bounds([4, 1, 7, 3]);
  print('bounds: lo=$lo hi=$hi');
```

返回类型 `(int, int)` + 调用方解构接收——以前要建的 `class Bounds { int lo; int hi; }` 直接消失。第 05 章埋的伏笔在此完整兑现。

## 13.4/13.5 模式族谱：一张 switch 认识全部模式

第 04 章只用了常量与 `||`，这里是完整族谱——一张 classify 尽数收录：

```dart
// ═══ 13.5 模式族谱：一张 switch 认识全部模式 ═══
String classify(Object obj) => switch (obj) {
      int n when n > 0 => '正整数 $n', // 类型 + when 卫兵
      int() => '非正整数', // 空参类型模式
      String s => '字符串"$s"（长度 ${s.length}）',
      [int first, ...] => '以 $first 开头的列表', // 列表模式
      {'name': String name} => '含 name=$name 的映射', // 映射模式
      _ => '其他',
    };
```

```dart
  for (final v in [7, -2, 'Dart', [10, 20], {'name': 'Bob'}, 3.14]) {
    print('${v.runtimeType}: ${classify(v)}');
  }
```

族谱表（分支从上到下依次匹配）：

| 模式 | 例子 | 匹配什么/顺便做什么 |
|---|---|---|
| 常量 | `'Sat'`、`3` | 字面量相等 |
| 变量 | `int n` / `String s` | 匹配类型并**绑定变量** |
| 空参类型 | `int()` | 只判类型不要值 |
| 逻辑组合 | `\|\|`、`&&` | 或 / 与 |
| 关系 | `>= 90` | 与常量比大小 |
| when 卫兵 | `int n when n > 0` | 模式之外的任意条件 |
| 列表 | `[int first, ...]` | 形状 + 首元素类型，`...` 吸收剩余 |
| 映射 | `{'name': String name}` | 含某键且值匹配 |
| 对象 | `Circle(r: var r)` | 按类型 + 字段解构（见 13.6） |
| 通配 | `_` | 万能兜底，丢弃值 |

模式匹配的本质升级：**一个分支 = 判型 + 取值 + 绑定变量**三件事一行写完，`is` + `as` + 判空的样板代码全部蒸发。

## 13.6 sealed + 穷尽 switch：最佳搭档

第 09 章的 sealed 在这里合体：

```dart
// ═══ 13.6 sealed 层级 + 穷尽 switch：模式匹配的最佳搭档 ═══
sealed class Shape {
  const Shape();
}

class Circle extends Shape {
  final double r;
  const Circle(this.r);
}

class Rect extends Shape {
  final double w, h;
  const Rect(this.w, this.h);
}

class Triangle extends Shape {
  final double a, b, c;
  const Triangle(this.a, this.b, this.c);
}

double area(Shape s) => switch (s) {
      Circle(r: var r) => 3.14159 * r * r, // 对象模式：按字段名解构
      Rect(w: var w, h: var h) => w * h,
      Triangle(a: var a, b: var b, c: var c) => heron(a, b, c),
    };
```

```dart
  // ═══ 13.6（续）穷尽 switch：新增子类时编译器强制补分支 ═══
  for (final s in [const Circle(1), const Rect(3, 4), const Triangle(3, 4, 5)]) {
    print('${s.runtimeType} 面积 = ${area(s).toStringAsFixed(2)}');
  }
```

注意 area 的 switch **没有 `_` 兜底**：Shape 是 sealed，编译器知道子类只有 Circle/Rect/Triangle 三个，全写了就是穷尽。红利在演进时兑现：哪天加 `class Polygon extends Shape`，所有 switch **当场编译失败**并列出漏网处——重构安全网。对象模式 `Circle(r: var r)` 一行完成"判型 + 拆字段"，这才是"多态算面积"之外的第二种写法：虚方法分发（第 08 章）适合行为内聚，模式匹配适合**行为随使用方变化**（这里"求面积"是外部函数）。

## 13.7 模式还能用在哪

switch 表达式之外，三处同样合法：

```dart
if (pair case (int x, int y)) print(x + y);   // if-case：判形状再干活
for (final (lo, hi) in pairs) print(lo + hi); // for-in 直接解构元素
switch (cmd) { case ('add', var title): … }  // switch 语句里的解构 case
```

第 20 章的命令解析就是 if-case/switch 模式的实战舞台。

## 坑位清单

- **命名字段与位置字段不可互解**：`(x: 3, y: 4)` 不能用 `(a, b)` 模式解构——编译错误，不是宽松匹配。
- **record 的 == 比较全部字段**：`(1, 'a') == (1, 'b')` 为 false；字段类型不同比较也为 false，不抛错。
- **非 sealed 类型穷尽需 `_`**：对 String/Object 这类开放类型 switch，漏 `_` 直接编译错误（提醒你"没人数得清"）。
- **`_` 丢弃不绑定**：解构时用 `_` 的位置拿不到值，要留证据就起名字。
- **对象模式字段名要对**：`Circle(r: var r)` 的 `r:` 是字段名不是变量名——写错是编译错误（好在有编译器兜着）。
