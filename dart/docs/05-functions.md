# 05 · 函数：参数三形态与一等公民

> 对应示例：examples/05_functions.dart

## 5.1 解决什么问题

翻开 Flutter 的 API，满眼都是 `width: 120, height: 40` 这样的调用——为什么 Dart 生态如此偏爱命名参数？反过来，老 JS 代码里 `createUser('Alice', 30, true)` 这种"第三个布尔参数是什么意思"的谜语，Dart 是怎么从语法上消灭的？答案都在函数的参数系统里。同时，函数在 Dart 里是**一等公民**：能赋值、能传参、能返回——这是集合操作（第 06 章）、异步（第 15 章）全部语法的基础。

先看最简形态与箭头语法：

```dart
// ═══ 5.1 箭头语法 =>：单表达式函数的简写 ═══
int square(int x) => x * x;
```

`=> expr` 与 `{ return expr; }` **完全等价**，只是更短。限制也只有一条：`=>` 右边必须是单个表达式，写不了语句块。

## 5.2 命名参数：可读性的主力军

```dart
// ═══ 5.2 命名参数：{} 包裹，required 必填，其余可给默认值 ═══
String formatUser({required String name, int age = 0, String role = 'guest'}) {
  return '$name（age=$age, role=$role）';
}
```

调用长这样（引用示例的演示段）：

```dart
  print(formatUser(name: 'Alice', age: 30, role: 'admin'));
  print(formatUser(name: 'Bob')); // age/role 用默认值
```

要点三条：

- 花括号 `{}` 里的参数调用时**必须写名字**，顺序随意；
- `required` 把命名参数变回"必填"——漏了是编译错误，不是运行时坑；
- 命名参数默认值直接写 `= 值`（可选位置参数同理）。

设计习惯：**对外 API 尽量命名参数**。参数超过两个、或有布尔参数时收益立现：`copy(deep: true)` 永远比 `copy(true)` 清楚。

## 5.3 可选位置参数：老派但没死

```dart
// ═══ 5.3 可选位置参数：[] 包裹，按位置省略 ═══
int sumRange(int start, [int end = 10, int step = 1]) {
```

方括号 `[]` 里的参数按位置省略、从后往前——`sumRange(1)`、`sumRange(1, 5)`、`sumRange(1, 5, 2)` 都合法，但 `sumRange(1, step: 2)` 不行。它适合"参数有自然顺序且前短后长"的内部函数；公共 API 用它要克制。注意**`{}` 与 `[]` 不能出现在同一个参数列表里**——Dart 要你明确选一种风格。

## 5.4 函数类型：给"函数这个值"起个类型名

```dart
// ═══ 5.4 函数类型：一等公民的类型写法 ═══
int Function(int) makeAdder(int base) {
```

读法：`int Function(int)` 是"吃一个 int、返回 int 的函数"的类型。返回函数的函数（高阶函数）在 Dart 里就这么写。参数位置同理：`void Function(int) callback` 表示"接收 int、无返回值的回调"。复杂签名可以起别名——`typedef`，第 14 章统一讲。

## 5.5 函数是值：匿名函数与高阶调用

```dart
  // ═══ 5.5 函数是值：匿名函数传给高阶方法 ═══
  var numbers = [1, 2, 3, 4, 5];
  var doubled = numbers.map((n) => n * 2).toList();
  var evens = numbers.where((n) => n.isEven).toList();
  print('doubled: $doubled');
  print('evens: $evens');
```

`(n) => n * 2` 是**匿名函数**（lambda）：没有名字的函数值，参数类型此处可省（由 map 的泛型上下文推断）。它作为参数传给 `map`/`where` 这类高阶方法——这就是"函数是一等公民"的日常形态。第 06 章把这套集合操作讲全。

## 5.6 闭包：函数记住了它的环境

```dart
// ═══ 5.4 函数类型：一等公民的类型写法 ═══
int Function(int) makeAdder(int base) {
  // ═══ 5.6 闭包：返回的函数捕获了 base ═══
  return (int x) => base + x;
}
```

```dart
  int Function(int) add10 = makeAdder(10);
  print('add10(5) = ${add10(5)}');
```

`makeAdder(10)` 返回的匿名函数，函数体里用到了外层的 `base`——**这个函数带着对 base 的引用一起逃出了 makeAdder**，之后随时调用都还能用。这就是闭包：函数值 + 它捕获的环境。Dart 闭包捕获的是**变量本身**（不是当时的快照），第 04 章坑位清单里"循环变量捕获"的坑就源于此。

## 5.7 返回多个值：函数的"打包出口"

```dart
(int, int) minMax(List<int> items) {
  // ═══ 5.7 返回多个值：用记录（第 13 章详解） ═══
  var min = items.reduce((a, b) => a < b ? a : b);
  var max = items.reduce((a, b) => a > b ? a : b);
  return (min, max);
}
```

```dart
  // ═══ 5.7（续）解构接收 ═══
  var (min, max) = minMax([4, 1, 7, 3]);
  print('min=$min, max=$max');
```

返回类型 `(int, int)` 是**记录（record）**——Dart 3 的轻量聚合类型：不用为"返回两个值"专门建 Pair 类，调用方用 `var (a, b) = ...` 解构接收。此处会用了就行，完整机制（命名字段、结构相等、与模式配合）在第 13 章。

## 坑位清单

- **命名参数忘写 `required`**：参数变成"可省略的必填"，调用方漏传后你在函数体里拿到 null 或默认值，错误现场离病因很远——签名设计时想清楚每个参数是不是真的可选。
- **`{}` 和 `[]` 混用**：编译错误，一种参数列表只能选一种可选形态。
- **`=>` 后面跟了语句块**：`=> { ... }` 的大括号会被当成 set 字面量或直接报错，多语句用老实的 `{ return …; }`。
- **闭包捕获可变变量**：循环里生成的闭包共享同一个变量槽，全部拿到最终值；要"每轮快照"用 `for (final x in …)`（final 每轮新绑定）。
