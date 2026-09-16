# 11 · 泛型：参数化类型与协变边界

> 对应示例：examples/11_generics.dart

## 11.1 解决什么问题

没有泛型的集合只能是 `List<dynamic>`：装什么都能过编译，读出来全是 dynamic，错误全推迟到运行时。泛型把"容器装什么"写进类型，错误提前到编译期。同时 Dart 的泛型有两个非常有个性的决定——**协变**（方便但有运行时代价）和 **reified**（类型参数运行时真实存在）——本章把这两个决定讲透。

先看基本盘：

```dart
class Box<T> {
  final T content;
  Box(this.content);

  T open() => content;
}

class Pair<K, V> {
  final K first;
  final V second;
  const Pair(this.first, this.second);

  @override
  String toString() => '($first, $second)';
}
```

```dart
  var box = Box('字符串也可以'); // T 推断为 String
  print('box=${box.open()}（${box.content.runtimeType}）');
  print(Pair(1, '一')); // K=int, V=String
```

`Box('…')` 不写 `<String>` 也能推断——构造处类型推断让签名保持干净。多个类型参数用逗号隔开（Pair 的 K/V）。

## 11.2/11.3 泛型方法与约束：T 才能有的能力

```dart
// ═══ 11.2/11.3 泛型方法与约束：T extends num 才能用 > ═══
T maxOf<T extends num>(T a, T b) => a > b ? a : b;

List<T> sortedCopy<T extends Comparable<T>>(List<T> list) => [...list]..sort();
```

```dart
  print('maxOf(3, 7) = ${maxOf(3, 7)}');
  print('maxOf(2.5, 2.1) = ${maxOf(2.5, 2.1)}');
  print('sortedCopy: ${sortedCopy([3, 1, 2])}');
```

不写约束时 T 只能当 Object 用（调不了任何特定方法）；`T extends num` 之后，T 拥有 num 的全部能力（`>` 运算）。注意 `maxOf(3, 7)` 返回类型仍是 int 而不是 num——**约束不改变 T 的具体化**，这是保持调用方类型信息的关键。`Comparable<T>` 这种"自我引用"约束是比较器的标准形状。

## 11.4 泛型 + 空安全：T? 表达"可能没有"

```dart
// ═══ 11.4 泛型 + 空安全：返回 T? 表达"可能没有" ═══
T? firstOrNull<T>(List<T> list, bool Function(T) test) {
  for (final item in list) {
    if (test(item)) {
      return item;
    }
  }
  return null;
}
```

返回 `T?` 是第 10 章与本章的合流：查找失败不抛异常、不返回哨兵值，而是类型诚实地告诉调用方"可能没有"——调用方自然会用 `??`/模式匹配接住。社区包 collection 里的 firstWhereOrNull 就是这个签名。

## 11.5 协变：方便与代价的交易

Dart 泛型是**协变的**：

```dart
  // ═══ 11.5 协变：List<int> 可以当 List<num> 用（有代价） ═══
  List<int> ints = [1, 2, 3];
  List<num> nums = ints; // 合法：Dart 泛型协变
  // nums.add(1.5); // 编译通过、运行时抛 TypeError！ints 实际只能装 int
  print('nums=$nums runtimeType=${nums.runtimeType}');
```

`List<int>` 可以赋给 `List<num>`——直觉上顺理成章（一组 int 当然是"一组数字"）。代价藏在写入侧：`nums.add(1.5)` **编译能过，运行时抛 TypeError**，因为底层那个列表真实身份是 `List<int>`，装不进 double。Dart 的选择是"读方便 + 写时运行时兜底"，与 Java 泛型（不变 + 通配符 ? extends）的繁琐静态方案相对。工程含义：**协变引用只读别写**；需要能写的通用集合，一开始就建 `List<num>`。

## 11.6 reified：类型参数活着到达运行时

```dart
  // ═══ 11.6 reified：类型参数运行时仍在（对比 Java 擦除） ═══
  print('is List<int>: ${nums is List<int>}'); // 通过父类引用做运行时判断
  print('is List<String>: ${nums is List<String>}');
```

Java 的泛型是编译期擦除（运行时没有 `List<int>` 这个类型，只有 List）；Dart 相反，**类型参数具体化（reified）**：`nums is List<int>` 能判、`runtimeType` 打印得出完整类型。这让 JSON 解码后的类型分派（第 18 章）、集合的精确类型分支都变得自然。`runtimeType` 适合调试与展示；业务判断用 `is`。

## 坑位清单

- **协变写入是运行时雷**：`List<num> nums = <int>[…]; nums.add(1.5);` 编译绿灯运行时爆——这条要形成肌肉记忆。
- **`List<dynamic>` 不是万金油**：读出元素全是 dynamic，用之前还得 cast/判型；能写具体类型参数就写。
- **无约束 T 上调用方法**：`T t; t.toString()` 之外几乎啥都不能干——需要能力就加 `extends` 约束。
- **`is T` 对 null 的语义**：`null is int` 为 false；判可空用 `is int?` 或先判 null。
