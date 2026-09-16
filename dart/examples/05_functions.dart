// 05 函数：参数三形态、箭头语法、函数类型、闭包、一等公民
// 运行：dart run examples/05_functions.dart

// ═══ 5.2 命名参数：{} 包裹，required 必填，其余可给默认值 ═══
String formatUser({required String name, int age = 0, String role = 'guest'}) {
  return '$name（age=$age, role=$role）';
}

// ═══ 5.3 可选位置参数：[] 包裹，按位置省略 ═══
int sumRange(int start, [int end = 10, int step = 1]) {
  var total = 0;
  for (var i = start; i <= end; i += step) {
    total += i;
  }
  return total;
}

// ═══ 5.1 箭头语法 =>：单表达式函数的简写 ═══
int square(int x) => x * x;

// ═══ 5.4 函数类型：一等公民的类型写法 ═══
int Function(int) makeAdder(int base) {
  // ═══ 5.6 闭包：返回的函数捕获了 base ═══
  return (int x) => base + x;
}

void applyTwice(int value, void Function(int) callback) {
  callback(value);
  callback(value * 2);
}

(int, int) minMax(List<int> items) {
  // ═══ 5.7 返回多个值：用记录（第 13 章详解） ═══
  var min = items.reduce((a, b) => a < b ? a : b);
  var max = items.reduce((a, b) => a > b ? a : b);
  return (min, max);
}

void main() {
  // ═══ 5.2（续）命名参数调用：与顺序无关 ═══
  print(formatUser(name: 'Alice', age: 30, role: 'admin'));
  print(formatUser(name: 'Bob')); // age/role 用默认值

  // ═══ 5.3（续） ═══
  print('sumRange(1) = ${sumRange(1)}');
  print('sumRange(1, 5, 2) = ${sumRange(1, 5, 2)}');
  print('square(7) = ${square(7)}');

  // ═══ 5.5 函数是值：匿名函数传给高阶方法 ═══
  var numbers = [1, 2, 3, 4, 5];
  var doubled = numbers.map((n) => n * 2).toList();
  var evens = numbers.where((n) => n.isEven).toList();
  print('doubled: $doubled');
  print('evens: $evens');

  // ═══ 5.4/5.6（续） ═══
  int Function(int) add10 = makeAdder(10);
  print('add10(5) = ${add10(5)}');

  applyTwice(3, (v) => print('callback got: $v'));

  // ═══ 5.7（续）解构接收 ═══
  var (min, max) = minMax([4, 1, 7, 3]);
  print('min=$min, max=$max');
}
