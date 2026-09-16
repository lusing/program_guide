// 14 扩展与 typedef：extension、可空/泛型扩展、冲突解析、extension type
// 运行：dart run examples/14_extensions.dart

// ═══ 14.1 扩展既有类型 ═══
extension StringX on String {
  int get wordCount => trim().isEmpty ? 0 : trim().split(RegExp(r'\s+')).length;

  String get reversed => String.fromCharCodes(codeUnits.reversed);
}

// ═══ 14.2 泛型扩展 ═══
extension ListX<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;

  String joinWithComma() => map((e) => '$e').join('、');
}

// ═══ 14.3 扩展可空类型：内部 this 可为 null ═══
extension NullableStringX on String? {
  String orDash() => this ?? '-';
}

// ═══ 14.4 冲突时必须显式调用 ═══
extension ShoutX on String {
  String shout() => toUpperCase();
}

extension WhisperX on String {
  String shout() => '$this...'; // 与 ShoutX 同名同签名：冲突
}

// ═══ 14.5 extension type：零开销"新类型"（Dart 3.3+） ═══
extension type Meters(double value) {
  double get inFeet => value * 3.28084;

  Meters operator +(Meters other) => Meters(value + other.value);
}

extension type Seconds(int value) {
  String get human {
    final m = value ~/ 60;
    final s = value % 60;
    return m > 0 ? '$m 分 $s 秒' : '$s 秒';
  }
}

// ═══ 14.6 typedef：类型别名 ═══
typedef IntList = List<int>;
typedef Mapper<S, T> = T Function(S);

void main() {
  // ═══ 14.1（续） ═══
  print('wordCount=${'dart is nice'.wordCount}');
  print('reversed=${'abcdef'.reversed}');

  // ═══ 14.2（续） ═══
  print('firstOrNull=${[9, 1].firstOrNull} / ${<int>[].firstOrNull}');
  print('joinWithComma=${[1, 2, 3].joinWithComma()}');

  // ═══ 14.3（续） ═══
  String? maybe; // 未初始化的可空变量默认就是 null
  print('orDash=${maybe.orDash()}');

  // ═══ 14.4（续）两个扩展有同名方法时，隐式调用直接编译报错 ═══
  print(ShoutX('hi').shout());
  print(WhisperX('hi').shout());

  // ═══ 14.5（续） ═══
  var len = Meters(5);
  print('5 米 = ${len.inFeet.toStringAsFixed(2)} 英尺；相加 = ${(len + Meters(1)).value} 米');
  print('95 秒 = ${Seconds(95).human}');
  // Meters(5) + 3 是编译错误：新类型不与底层 double 自动互通（这正是意义）

  // ═══ 14.6（续） ═══
  IntList scores = [90, 85];
  // ignore: prefer_function_declarations_over_variables
  Mapper<String, int> lengthOf = (s) => s.length; // 函数类型别名 + 闭包
  print('scores 长度 ${scores.length}，lengthOf("Dart") = ${lengthOf('Dart')}');
}
