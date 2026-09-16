// 04 控制流：if/for/while、break/continue、switch 语句与 Dart 3 switch 表达式
// 运行：dart run examples/04_control_flow.dart

// ═══ 4.5 switch 表达式：Dart 3 的核心新语法 ═══
// 支持模式组合（||）、关系模式与 => 返回值，可直接参与赋值
String dayType(String weekday) => switch (weekday) {
      'Sat' || 'Sun' => '周末',
      'Mon' || 'Tue' || 'Wed' || 'Thu' || 'Fri' => '工作日',
      _ => '未知',
    };

// ═══ 4.4 switch 语句：case 体非空必须以 break/return/throw 结束（Dart 3） ═══
String grade(int score) {
  switch (score) {
    case >= 90:
      return 'A';
    case >= 80:
      return 'B';
    case >= 60:
      return 'C';
    default:
      return '不及格';
  }
}

void main() {
  // ═══ 4.1 if：条件必须是 bool，没有 truthy ═══
  int score = 88;
  if (score >= 90) {
    print('A');
  } else if (score >= 80) {
    print('B');
  } else {
    print('C');
  }
  var list = [1, 2, 3];
  if (list.isNotEmpty) {
    print('list 非空，长度 ${list.length}');
  }

  // ═══ 4.2 for / for-in / while / do-while ═══
  var sum = 0;
  for (var i = 1; i <= 10; i++) {
    sum += i;
  }
  print('sum(1..10) = $sum');

  for (final fruit in ['apple', 'banana', 'cherry']) {
    print('fruit: $fruit');
  }

  var n = 5;
  var factorial = 1;
  while (n > 1) {
    factorial *= n;
    n--;
  }
  print('5! = $factorial');

  var count = 0;
  do {
    count++;
  } while (count < 3);
  print('do-while count = $count');

  // ═══ 4.3 break 与 continue ═══
  for (var i = 0; i < 10; i++) {
    if (i.isOdd) continue;
    if (i > 6) break;
    print('even i = $i');
  }

  // ═══ 4.4（续） ═══
  print('grade(88) = ${grade(88)}');

  // ═══ 4.5（续） ═══
  print('Sat -> ${dayType('Sat')}');
  print('Mon -> ${dayType('Mon')}');

  // ═══ 4.6 条件表达式：?: 是表达式，if 不是 ═══
  var parity = sum.isEven ? '偶' : '奇';
  print('55 是$parity数');
}
