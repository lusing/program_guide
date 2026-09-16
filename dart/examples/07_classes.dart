// 07 类与对象：构造函数家族、getter/setter、运算符重载、== 与 hashCode
// 运行：dart run examples/07_classes.dart

import 'dart:math' as math;

// ═══ 7.1–7.4 构造函数家族 ═══
class Point {
  final double x;
  final double y;

  Point(this.x, this.y); // 主构造：参数直赋字段

  Point.origin()
      : x = 0,
        y = 0; // 命名构造 + 初始化列表

  Point.checked(double x, double y)
      : assert(x >= 0 && y >= 0, '坐标不能为负'),
        x = x,
        y = y; // 初始化列表：构造体之前执行，可做断言

  Point.alongX(double x) : this(x, 0); // 重定向构造：转发到主构造

  // ═══ 7.6 getter：像字段一样访问的计算属性 ═══
  double get distanceFromOrigin => math.sqrt(x * x + y * y);

  // ═══ 7.7 运算符重载与 == ═══
  Point operator +(Point other) => Point(x + other.x, y + other.y);
  Point operator *(double k) => Point(x * k, y * k);

  @override
  bool operator ==(Object other) =>
      other is Point && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Point($x, $y)';
}

// ═══ 7.5 工厂构造 factory：自己决定返回哪个实例 ═══
class Temperature {
  final double celsius;
  static final Map<double, Temperature> _cache = {};

  Temperature._(this.celsius); // 私有构造：外界只能走 factory

  factory Temperature(double celsius) {
    return _cache.putIfAbsent(celsius, () => Temperature._(celsius));
  }

  double get fahrenheit => celsius * 9 / 5 + 32;

  @override
  String toString() => '$celsius°C';
}

// ═══ 7.6（续）setter：拦截写入 ═══
class Account {
  double _balance = 0; // 下划线开头：库内私有

  double get balance => _balance;

  set balance(double value) {
    if (value < 0) {
      throw ArgumentError('余额不能为负');
    }
    _balance = value;
  }
}

void main() {
  var p = Point(3, 4);
  print('p=$p 距原点=${p.distanceFromOrigin}');
  print('origin=${Point.origin()} alongX=${Point.alongX(5)}');
  print('p + p * 2 = ${p + p * 2}'); // 运算符重载参与表达式
  print('==(3,4): ${Point(3, 4) == p}（重写后按值比较）');
  print('checked: ${Point.checked(1, 1)}');

  var t1 = Temperature(25);
  var t2 = Temperature(25);
  print('factory 复用实例：${identical(t1, t2)}，25°C = ${t1.fahrenheit}°F');

  var acc = Account();
  acc.balance = 100;
  print('balance=${acc.balance}');
  try {
    acc.balance = -1;
  } on ArgumentError catch (e) {
    print('setter 拦截：$e');
  }
}
