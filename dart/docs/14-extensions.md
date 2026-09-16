# 14 · 扩展：不改源码地"加方法"

> 对应示例：examples/14_extensions.dart

## 14.1 解决什么问题

想给 String 加个 `wordCount`：Java 只能写 `StringUtil.wordCount(s)` 这种工具类静态方法——调用方读起来是"数据在左、逻辑在右"的割裂句式。Dart 的 extension 让你**对任何类型追加成员**，调用方写 `s.wordCount`，读起来像 String 天生就有这个方法。最后一节还有个更强的亲戚：extension type——零开销地"造新类型"。

```dart
// ═══ 14.1 扩展既有类型 ═══
extension StringX on String {
  int get wordCount => trim().isEmpty ? 0 : trim().split(RegExp(r'\s+')).length;

  String get reversed => String.fromCharCodes(codeUnits.reversed);
}
```

```dart
  print('wordCount=${'dart is nice'.wordCount}');
  print('reversed=${'abcdef'.reversed}');
```

一个关键机制：扩展是**静态解析**的——编译器把 `s.wordCount` 直接换成 `StringX(s).wordCount` 式的静态调用，运行时没有任何查找、没有性能损失，也不会"污染"String 本身（别的文件不 import 这个扩展就看不见）。

## 14.2 泛型扩展：给一整族类型加能力

```dart
// ═══ 14.2 泛型扩展 ═══
extension ListX<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;

  String joinWithComma() => map((e) => '$e').join('、');
}
```

```dart
  print('firstOrNull=${[9, 1].firstOrNull} / ${<int>[].firstOrNull}');
  print('joinWithComma=${[1, 2, 3].joinWithComma()}');
```

`on List<T>` 让扩展覆盖所有元素类型的列表，成员里还能用 T（`firstOrNull` 返回 `T?`，正好用上第 11 章的"可能没有"建模）。社区包 collection 的 `firstWhereOrNull` 等增强全是这么写的。

## 14.3 扩展可空类型：把判空藏进方法里

```dart
// ═══ 14.3 扩展可空类型：内部 this 可为 null ═══
extension NullableStringX on String? {
  String orDash() => this ?? '-';
}
```

```dart
  String? maybe; // 未初始化的可空变量默认就是 null
  print('orDash=${maybe.orDash()}');
```

`on String?` 的扩展可以直接对 null 调用（`maybe.orDash()` 不抛错）——成员内部的 `this` 是 `String?`，第一件事通常就是 `??`。这是"把判空样板收进库函数"的标准手法，Flutter 生态的 null-safe 取值工具多由此实现。

## 14.4 同名冲突：显式调用一锤定音

```dart
// ═══ 14.4 冲突时必须显式调用 ═══
extension ShoutX on String {
  String shout() => toUpperCase();
}

extension WhisperX on String {
  String shout() => '$this...'; // 与 ShoutX 同名同签名：冲突
}
```

```dart
  print(ShoutX('hi').shout());
  print(WhisperX('hi').shout());
```

两个扩展对同一类型提供同名方法时，`'hi'.shout()` 这种隐式调用**直接编译报错**（Dart 不猜你要哪个）。出路是把扩展当"命名空间"显式调用：`ShoutX('hi').shout()`。工程上更常见的冲突来自"两个库各有一个同名扩展"——用 import 的 `hide`/`show` 解决。

## 14.5 extension type：零开销的"新类型"（Dart 3.3+）

扩展是"给旧类型加方法"；extension type 是**造一个编译期的新类型**：

```dart
// ═══ 14.5 extension type：零开销"新类型"（Dart 3.3+） ═══
extension type Meters(double value) {
  double get inFeet => value * 3.28084;

  Meters operator +(Meters other) => Meters(value + other.value);
}
```

```dart
  var len = Meters(5);
  print('5 米 = ${len.inFeet.toStringAsFixed(2)} 英尺；相加 = ${(len + Meters(1)).value} 米');
```

设计动机看一行就懂：`Meters(5) + 3` 是**编译错误**——新类型不与底层 double 自动互通。于是"米加秒""把 id 当字符串拼进 SQL"这类**单位/领域混淆**在编译期被拦下，而运行时它就是那个 double（零包装、零分配）。与普通包装类（第 07 章）的差别正在"零开销 + 编译期隔离"；限制是它没有运行时身份（is 检查会被拆穿成底层类型）。

## 14.6 typedef：给复杂类型起小名

```dart
// ═══ 14.6 typedef：类型别名 ═══
typedef IntList = List<int>;
typedef Mapper<S, T> = T Function(S);
```

```dart
  IntList scores = [90, 85];
  // ignore: prefer_function_declarations_over_variables
  Mapper<String, int> lengthOf = (s) => s.length; // 函数类型别名 + 闭包
  print('scores 长度 ${scores.length}，lengthOf("Dart") = ${lengthOf('Dart')}');
```

typedef 是纯别名（不造新类型，与 extension type 相反），两大用途：**函数类型签名降噪**（第 05 章的 `int Function(int)` 写长了很吵，`typedef Adder = int Function(int)` 一劳永逸）和**语义化重命名**（`typedef UserId = int` 让签名自解释）。

## 坑位清单

- **扩展成员不能存状态**：extension 里没有字段——要缓存就挂外部 Map（或用 extension type + 类组合）。
- **扩展不能被子类覆写**：静态分发，虚方法语义不存在；多态行为回类体系（第 08 章）。
- **扩展在 null 上的行为取决于 on 的类型**：`on String` 的扩展不能对 null 隐式调用；要收 null 就声明 `on String?`。
- **extension type 没有运行时身份**：`Meters(5) is double` 为 true——需要运行时类型隔离就回到包装类。
- **typedef 不产生新类型**：`IntList` 与 `List<int>` 完全等价，防不了"装错货"——那是 extension type 的活。
