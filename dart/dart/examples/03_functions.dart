// 03 函数：命名参数、可选位置参数、箭头函数、闭包、一等公民
String formatUser({required String name, int age = 0, String role = 'guest'}) {
  return '$name (age=$age, role=$role)';
}

// 可选位置参数用方括号，可带默认值
int sumRange(int start, [int end = 10, int step = 1]) {
  var total = 0;
  for (var i = start; i <= end; i += step) {
    total += i;
  }
  return total;
}

// 箭头语法：仅适用于单个表达式
int square(int x) => x * x;

void main() {
  // 命名参数调用
  print(formatUser(name: 'Alice', age: 30, role: 'admin'));
  print(formatUser(name: 'Bob'));

  // 可选位置参数
  print('sumRange(1) = ${sumRange(1)}');
  print('sumRange(1, 5, 2) = ${sumRange(1, 5, 2)}');
  print('square(7) = ${square(7)}');

  // 函数是一等公民：可赋值、可传参
  var numbers = [1, 2, 3, 4, 5];
  var doubled = numbers.map((n) => n * 2).toList();
  print('doubled: $doubled');

  var filtered = numbers.where((n) => n > 2).toList();
  print('filtered: $filtered');

  // 闭包：捕获外部变量
  int Function(int) makeAdder(int base) {
    return (int x) => base + x;
  }

  var add10 = makeAdder(10);
  print('add10(5) = ${add10(5)}');

  // 函数作为参数（回调）
  applyTwice(3, (v) {
    print('callback got: $v');
  });

  // 返回多个值可配合记录（Dart 3）
  var (min, max) = minMax([4, 1, 7, 3]);
  print('min=$min, max=$max');
}

void applyTwice(int value, void Function(int) callback) {
  callback(value);
  callback(value * 2);
}

(int, int) minMax(List<int> items) {
  var min = items.reduce((a, b) => a < b ? a : b);
  var max = items.reduce((a, b) => a > b ? a : b);
  return (min, max);
}
