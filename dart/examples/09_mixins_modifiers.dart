// 09 Mixin 与类修饰符：with、mixin/on、线性化、sealed/base/final/interface
// 运行：dart run examples/09_mixins_modifiers.dart

// ═══ 9.1 mixin：可组合的行为片段 ═══
mixin Logger {
  void log(String msg) => print('[log] $msg');
}

abstract class Animal {
  String get name;
  void breathe() => print('$name 呼吸');
}

// ═══ 9.2 mixin on：限定只能混入某个类之上，从而安全使用其成员 ═══
mixin Pet on Animal {
  void greet() => print('$name 摇尾巴（作为宠物打招呼）');
}

// ═══ 9.3 线性化：右边的 mixin 覆盖左边的同名方法 ═══
mixin A {
  String who() => 'A';
}

mixin B {
  String who() => 'B';
}

class Dog extends Animal with Pet, Logger {
  @override
  String get name => '阿黄';
}

class Confused with A, B {}

// ═══ 9.4 sealed：封闭继承树，换来穷尽检查（配合第 13 章 switch） ═══
sealed class Result<T> {
  const Result();
}

class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

class Err<T> extends Result<T> {
  final String message;
  const Err(this.message);
}

String describeResult(Result<int> r) => switch (r) {
      Ok(value: var v) => '成功：$v',
      Err(message: var m) => '失败：$m',
      // 不需要 _ 兜底：sealed 保证子类全部在本文件内，编译器能数得清
    };

// ═══ 9.5 base/final/interface 修饰符（Dart 3） ═══
base class BaseModel {
  void id() => print('base：允许被 extends/with，禁止被 implements');
}

final class FinalModel {
  void id() => print('final：禁止 extends 与 implements，只能直接用');
}

interface class InterfaceModel {
  void id() => print('interface：允许 implements，禁止 extends');
}

void main() {
  var dog = Dog();
  dog.breathe(); // 来自 Animal
  dog.greet(); // 来自 Pet（on Animal 才能用）
  dog.log('你好'); // 来自 Logger

  // ═══ 9.3（续） ═══
  print('with A, B 的 who() = ${Confused().who()}'); // B 胜出：从左到右叠加，后者覆盖

  // ═══ 9.4（续） ═══
  print(describeResult(const Ok(42)));
  print(describeResult(const Err('网络超时')));

  // ═══ 9.5（续） ═══
  // class MyModel implements BaseModel {} // 编译错误：base 类禁止被 implements
  BaseModel().id();
  FinalModel().id();
  InterfaceModel().id();
}
