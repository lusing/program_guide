// 02 控制流：if、for、while、switch 语句与 Dart 3 switch 表达式
void main() {
  // if-else
  int score = 88;
  if (score >= 90) {
    print('等级 A');
  } else if (score >= 80) {
    print('等级 B');
  } else {
    print('等级 C');
  }

  // 经典 for 循环
  var sum = 0;
  for (var i = 1; i <= 10; i++) {
    sum += i;
  }
  print('sum(1..10) = $sum');

  // for-in 遍历集合
  var fruits = ['apple', 'banana', 'cherry'];
  for (var fruit in fruits) {
    print('fruit: $fruit');
  }

  // while 与 do-while
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

  // break 与 continue
  for (var i = 0; i < 10; i++) {
    if (i.isOdd) continue;
    if (i > 6) break;
    print('even i = $i');
  }

  // Dart 3 switch 表达式：支持 || 模式与默认分支
  String weekday = 'Mon';
  var dayType = switch (weekday) {
    'Mon' || 'Tue' || 'Wed' || 'Thu' || 'Fri' => '工作日',
    'Sat' || 'Sun' => '周末',
    _ => '未知',
  };
  print('$weekday -> $dayType');
}
