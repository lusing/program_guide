// 13 记录与模式匹配：record、解构、switch 全模式、sealed 穷尽
// 运行：dart run examples/13_records_patterns.dart

import 'dart:math' as math;

// ═══ 13.6 sealed 层级 + 穷尽 switch：模式匹配的最佳搭档 ═══
sealed class Shape {
  const Shape();
}

class Circle extends Shape {
  final double r;
  const Circle(this.r);
}

class Rect extends Shape {
  final double w, h;
  const Rect(this.w, this.h);
}

class Triangle extends Shape {
  final double a, b, c;
  const Triangle(this.a, this.b, this.c);
}

double area(Shape s) => switch (s) {
      Circle(r: var r) => 3.14159 * r * r, // 对象模式：按字段名解构
      Rect(w: var w, h: var h) => w * h,
      Triangle(a: var a, b: var b, c: var c) => heron(a, b, c),
    };

double heron(double a, double b, double c) {
  final s = (a + b + c) / 2;
  return math.sqrt((s - a) * (s - b) * (s - c) * s);
}

// ═══ 13.5 模式族谱：一张 switch 认识全部模式 ═══
String classify(Object obj) => switch (obj) {
      int n when n > 0 => '正整数 $n', // 类型 + when 卫兵
      int() => '非正整数', // 空参类型模式
      String s => '字符串"$s"（长度 ${s.length}）',
      [int first, ...] => '以 $first 开头的列表', // 列表模式
      {'name': String name} => '含 name=$name 的映射', // 映射模式
      _ => '其他',
    };

(int, int) bounds(List<int> list) {
  // ═══ 13.3 函数返回多值 ═══
  var min = list.first;
  var max = list.first;
  for (final n in list) {
    if (n < min) {
      min = n;
    }
    if (n > max) {
      max = n;
    }
  }
  return (min, max);
}

void main() {
  // ═══ 13.1 record：轻量结构化值，== 按结构比较 ═══
  var point = (x: 3, y: 4); // 命名字段 record
  var other = (x: 3, y: 4);
  print('point == other: ${point == other}（结构相等，无需重写 ==）');
  print('字段访问：x=${point.x}');
  var rgb = (255, 128, 0); // 位置字段 record
  print('位置字段：第一个=${rgb.$1}');

  // ═══ 13.2 解构：一次声明多个变量 ═══
  var (x: px, y: py) = point; // 命名字段解构：变量名可不同于字段名
  final (r, g, b) = rgb; // 位置字段解构
  print('解构：x=$px y=$py r=$r g=$g b=$b');

  // ═══ 13.3（续） ═══
  var (lo, hi) = bounds([4, 1, 7, 3]);
  print('bounds: lo=$lo hi=$hi');

  // ═══ 13.4/13.5（续） ═══
  for (final v in [7, -2, 'Dart', [10, 20], {'name': 'Bob'}, 3.14]) {
    print('${v.runtimeType}: ${classify(v)}');
  }

  // ═══ 13.6（续）穷尽 switch：新增子类时编译器强制补分支 ═══
  for (final s in [const Circle(1), const Rect(3, 4), const Triangle(3, 4, 5)]) {
    print('${s.runtimeType} 面积 = ${area(s).toStringAsFixed(2)}');
  }
}
