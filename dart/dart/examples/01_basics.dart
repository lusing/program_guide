// 01 基础语法：变量、内置类型、字符串插值、常量
void main() {
  // 字符串插值
  var name = 'Dart';
  int year = 2026;
  double pi = 3.14159;
  bool isStable = true;

  print('Hello, $name!');
  print('year=$year, pi=${pi.toStringAsFixed(2)}, stable=$isStable');

  // 类型推断与显式标注
  var city = 'Beijing'; // 推断为 String
  String greeting = 'Welcome to $city';
  print(greeting);

  // const（编译期常量）与 final（运行期一次性赋值）
  const maxRetry = 3;
  final timestamp = DateTime.now();
  print('maxRetry=$maxRetry');
  print('timestamp=$timestamp');

  // 数字解析与转换
  int a = int.parse('42');
  double b = double.parse('3.5');
  print('a + b = ${a + b}');
  print('int -> double: ${a.toDouble()}');
  print('double -> int: ${b.round()}');

  // 字符串常用操作
  var text = ' Dart Guide ';
  print('trim: "${text.trim()}"');
  print('upper: ${text.trim().toUpperCase()}');
  print('split: ${'a,b,c'.split(',')}');
  print('padLeft: ${'7'.padLeft(3, '0')}');
}
