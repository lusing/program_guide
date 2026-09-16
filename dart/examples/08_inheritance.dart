// 08 继承、抽象与接口：extends、abstract、implicit interface
// 运行：dart run examples/08_inheritance.dart

// ═══ 8.3 抽象类：约定子类必须实现的行为 ═══
abstract class Shape {
  String get name; // 抽象 getter：无实现

  double area(); // 抽象方法

  // 抽象类可以有具体方法（供 extends 的子类复用）
  void describe() => print('$name 的面积是 ${area().toStringAsFixed(2)}');
}

// ═══ 8.1 extends：继承实现 ═══
class Circle extends Shape {
  final double r;
  Circle(this.r);

  @override
  String get name => '圆';

  @override
  double area() => 3.14159 * r * r;
}

class Rect extends Shape {
  final double w;
  final double h;
  Rect(this.w, this.h);

  @override
  String get name => '矩形';

  @override
  double area() => w * h;
}

// ═══ 8.4 implicit interface：每个类同时隐式定义一个接口 ═══
// implements 只拿"契约"（所有成员签名），不带任何实现
class Square implements Shape {
  final double side;
  Square(this.side);

  @override
  String get name => '正方形';

  @override
  double area() => side * side;

  @override
  void describe() => print('[$name] area=${area().toStringAsFixed(1)}（自己实现）');
}

// ═══ 8.5 一个类可以同时实现多个契约 ═══
abstract class Storable {
  Map<String, dynamic> toJson();
}

class StorableRect extends Rect implements Storable {
  StorableRect(super.w, super.h); // super 参数：直接转发给父类构造

  @override
  Map<String, dynamic> toJson() => {'w': w, 'h': h};
}

void main() {
  // ═══ 8.1/8.2 继承复用与多态 ═══
  Shape c = Circle(2);
  c.describe(); // describe 来自抽象类，area 来自 Circle——模板方法模式

  for (final s in [Circle(1), Rect(3, 4), Square(5)]) {
    s.describe(); // 同一调用，不同实现
  }

  // ═══ 8.4（续）implements vs extends 的本质区别 ═══
  Square(2).describe(); // implements 拿不到 describe 的实现，必须自己写

  // ═══ 8.5（续）多接口 ═══
  print(StorableRect(3, 4).toJson());

  // ═══ 8.6 组合方式选型 ═══
  // extends：想要实现复用（单继承）
  // implements：只要契约、全部自己写（可多个）
  // with：混入横向能力（第 09 章）
}
