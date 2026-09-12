// 05 类与面向对象：构造器、继承、抽象类、mixin、接口
abstract class Shape {
  const Shape(); // 提供 const 构造器，子类才能声明 const 构造器

  double area();

  @override
  String toString() => '$runtimeType(area=${area().toStringAsFixed(2)})';
}

class Rectangle extends Shape {
  final double width;
  final double height;

  // 构造器简写：参数直接初始化字段
  Rectangle(this.width, this.height);

  // 命名构造器
  Rectangle.square(double side)
      : width = side,
        height = side;

  @override
  double area() => width * height;
}

class Circle extends Shape {
  final double radius;
  const Circle(this.radius); // const 构造器

  @override
  double area() => 3.14159 * radius * radius;
}

// mixin：横向复用行为
mixin Printable {
  void describe() => print('I am $runtimeType');
}

mixin Serializable {
  Map<String, Object?> toJson();
}

class User with Printable, Serializable {
  final String name;
  final int age;

  User({required this.name, required this.age});

  @override
  Map<String, Object?> toJson() => {'name': name, 'age': age};
}

// 接口：任何类都可以被 implements
class JsonWriter {
  String write(Map<String, Object?> data) => data.toString();
}

class PrettyWriter implements JsonWriter {
  @override
  String write(Map<String, Object?> data) {
    return data.entries.map((e) => '  ${e.key}: ${e.value}').join('\n');
  }
}

void main() {
  var shapes = <Shape>[Rectangle(3, 4), Rectangle.square(5), Circle(2)];
  for (var s in shapes) {
    print(s);
  }

  var user = User(name: 'Carol', age: 28);
  user.describe();
  print('toJson: ${user.toJson()}');

  var writer = PrettyWriter();
  print('pretty:\n${writer.write(user.toJson())}');

  // 类型判断与转型
  Shape shape = Rectangle(2, 6);
  if (shape is Rectangle) {
    print('rectangle width = ${shape.width}');
  }
}
