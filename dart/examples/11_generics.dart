// 11 泛型：泛型类/方法、约束、协变边界、reified 类型
// 运行：dart run examples/11_generics.dart

// ═══ 11.1 泛型类 ═══
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

// ═══ 11.2/11.3 泛型方法与约束：T extends num 才能用 > ═══
T maxOf<T extends num>(T a, T b) => a > b ? a : b;

List<T> sortedCopy<T extends Comparable<T>>(List<T> list) => [...list]..sort();

// ═══ 11.4 泛型 + 空安全：返回 T? 表达"可能没有" ═══
T? firstOrNull<T>(List<T> list, bool Function(T) test) {
  for (final item in list) {
    if (test(item)) {
      return item;
    }
  }
  return null;
}

void main() {
  var box = Box('字符串也可以'); // T 推断为 String
  print('box=${box.open()}（${box.content.runtimeType}）');
  print(Pair(1, '一')); // K=int, V=String

  // ═══ 11.2（续） ═══
  print('maxOf(3, 7) = ${maxOf(3, 7)}');
  print('maxOf(2.5, 2.1) = ${maxOf(2.5, 2.1)}');
  print('sortedCopy: ${sortedCopy([3, 1, 2])}');
  print('firstOrNull: ${firstOrNull([5, 8, 11], (n) => n > 10)}');

  // ═══ 11.5 协变：List<int> 可以当 List<num> 用（有代价） ═══
  List<int> ints = [1, 2, 3];
  List<num> nums = ints; // 合法：Dart 泛型协变
  // nums.add(1.5); // 编译通过、运行时抛 TypeError！ints 实际只能装 int
  print('nums=$nums runtimeType=${nums.runtimeType}');

  // ═══ 11.6 reified：类型参数运行时仍在（对比 Java 擦除） ═══
  print('is List<int>: ${nums is List<int>}'); // 通过父类引用做运行时判断
  print('is List<String>: ${nums is List<String>}');
}
