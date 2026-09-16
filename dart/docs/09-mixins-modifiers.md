# 09 · Mixin 与类修饰符：组合优于继承的 Dart 答案

> 对应示例：examples/09_mixins_modifiers.dart

## 9.1 解决什么问题

单继承装不下"会日志 + 会缓存 + 会校验"这类**横切能力**——它们和主类型没有 is-a 关系。多继承能装，但有菱形问题（两个父类同一方法，听谁的？）。Dart 的答案是 mixin：**可组合的行为片段 + 一条确定性的叠加规则（线性化）**。与第 08 章的三味表接上：extends 管"是一个"，implements 管"能做什么"，with 管"随身附加的能力"。

```dart
// ═══ 9.1 mixin：可组合的行为片段 ═══
mixin Logger {
  void log(String msg) => print('[log] $msg');
}

abstract class Animal {
  String get name;
  void breathe() => print('$name 呼吸');
}

class Dog extends Animal with Pet, Logger {
  @override
  String get name => '阿黄';
}
```

`Dog` 一行拿到三样东西：Animal 的实现（extends）、Pet 的行为（with）、Logger 的行为（with）。mixin 里写的就是普通成员，但它**不能被实例化、不能有构造参数**——它天生是"往别人身上挂"的。

## 9.2 mixin on：给混入加前置条件

```dart
// ═══ 9.2 mixin on：限定只能混入某个类之上，从而安全使用其成员 ═══
mixin Pet on Animal {
  void greet() => print('$name 摇尾巴（作为宠物打招呼）');
}
```

`on Animal` 声明："我只允许混在 Animal 及其子类上"。为什么？因为 `greet()` 要用 `name`——只有挂在 Animal 之上，这个成员才保证存在。`on` 是把"隐式依赖"写进类型系统的手段，库作者用它防止 mixin 被错误地挂到无关类上。

## 9.3 线性化：谁覆盖谁，一条规则定死

```dart
// ═══ 9.3 线性化：右边的 mixin 覆盖左边的同名方法 ═══
mixin A {
  String who() => 'A';
}

mixin B {
  String who() => 'B';
}

class Confused with A, B {}
```

```dart
  print('with A, B 的 who() = ${Confused().who()}'); // B 胜出：从左到右叠加，后者覆盖
```

Dart 把 `class C with A, B` 展开成一条**单向链**：`C → B → A → Object`，方法解析就是沿链找第一个。所以 B 覆盖 A——**写在前面的被后面覆盖**，没有菱形、没有投票，规则完全确定（这与 C++ 的虚继承博弈、Python MRO 的 C3 线性化目的一致，但规则更简单）。工程含义：with 的顺序是接口的一部分，随意调换可能改变行为。

## 9.4 sealed：把继承树锁进一个文件

```dart
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
```

`sealed` 的交易条件：**所有子类必须与它在同一个库（文件）里**。换来的是编译器对继承树"全知全能"——switch 到它的子类时不需要 `_` 兜底，编译器验证穷尽性。收益在第 13 章会完整展开：新增一个子类，所有漏处理的 switch **当场编译失败**，重构安全网就是它。这是建模"固定种类的状态"（成功/失败、各种命令）的首选工具，第 20 章实战直接采用。

## 9.5 base/final/interface：控制别人怎么用你的类

类修饰符是 Dart 3 给**库作者**的权限面板：

```dart
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
```

| 修饰符 | extends | implements | with | 意图 |
|---|---|---|---|---|
| （无修饰） | 允许 | 允许 | —（非 mixin） | 默认全开放 |
| `base` | 允许 | **禁止** | 允许 | "要用就拿实现去继承，别只抄接口"——保证实现不被绕过 |
| `interface` | **禁止** | 允许 | — | "我是纯契约"——防止实现被继承耦合 |
| `final` | **禁止** | **禁止** | — | "我就是终端实现"——版本演进不破坏子类 |
| `sealed` | 同文件允许 | 同文件允许 | — | 封闭树换穷尽检查（9.4） |

设计感言：修饰符是写给**未来的你**的护栏——库一旦被别人 extends，你以后改内部实现就处处掣肘；`final`/`base` 在发布库时是默认稳妥选择。

## 坑位清单

- **mixin 没有构造参数**：`with` 语法无处传参，需要配置就挂可写属性或用泛型。
- **同名方法"静默后者胜"**：线性化覆盖不产生任何警告，A/B 同名时务必心里有线（或干脆别让 mixin 互相撞名）。
- **sealed 子类必须同库**：跨文件 extends sealed 类是编译错误；反过来，同文件内它可以被正常 extends/implements。
- **base 类跨库 implements 是编译错**：限制跨库生效；同库内不受约束。
- **`class X with M` 要求 M 是 mixin（或类）**：普通类也可以被 with（拿实现），但官方风格是 mixin 声明 mixin；拿不准就声明成 mixin。
