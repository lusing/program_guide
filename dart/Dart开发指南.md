# Dart 语言开发指南

> 本指南基于 **Dart SDK 3.13.2 (stable)** 编写，全部例程均通过 `dart run` 实际编译与运行验证。
> 验证环境：Windows x64，SDK 路径 `G:\scoop\apps\dart\3.13.2\bin\dart.exe`。

## 目录

- [一、环境准备](#一环境准备)
- [二、基础语法](#二基础语法)
- [三、控制流](#三控制流)
- [四、函数](#四函数)
- [五、集合](#五集合)
- [六、类与面向对象](#六类与面向对象)
- [七、空安全](#七空安全)
- [八、泛型](#八泛型)
- [九、异步编程](#九异步编程)
- [十、异常处理](#十异常处理)
- [十一、记录与模式匹配](#十一记录与模式匹配)
- [十二、扩展](#十二扩展)
- [十三、JSON 与文件 IO](#十三json-与文件-io)
- [十四、包管理与项目结构](#十四包管理与项目结构)
- [十五、常用命令速查](#十五常用命令速查)

---

## 一、环境准备

### 1.1 安装与验证

Dart SDK 可通过 Scoop、Homebrew 或官网安装包获取。安装后验证版本：

```powershell
dart --version
```

验证输出：

```text
Dart SDK version: 3.13.2 (stable) (Tue Aug 25 01:01:12 2026 -0700) on "windows_x64"
```

### 1.2 第一个程序

新建 `hello.dart`：

```dart
void main() {
  print('Hello, Dart!');
}
```

运行方式有两种：

```powershell
# 直接运行（JIT，适合开发调试）
dart run hello.dart

# 编译为原生可执行文件（AOT，适合发布）
dart compile exe hello.dart -o hello.exe
.\hello.exe
```

### 1.3 核心工具链

| 命令 | 用途 |
| --- | --- |
| `dart run <file>` | 运行 Dart 脚本 |
| `dart analyze` | 静态分析，检查错误与代码风格 |
| `dart format .` | 按官方风格格式化代码 |
| `dart compile exe` | 编译为原生可执行文件 |
| `dart compile js` | 编译为 JavaScript（Web） |
| `dart pub get` | 拉取 `pubspec.yaml` 声明的依赖 |
| `dart test` | 运行单元测试 |
| `dart doc` | 生成 API 文档 |

---

## 二、基础语法

Dart 是强类型语言，支持类型推断：`var` 声明的变量由初始化值推断类型，且推断后类型固定。`int`、`double`、`bool`、`String` 是最常用的内置类型。

`const` 表示编译期常量，值在编译时确定；`final` 表示运行期一次性赋值，赋值后不可再修改。

```dart
// 01 基础语法：变量、内置类型、字符串插值、常量
void main() {
  // 字符串插值
  var name = 'Dart';
  int year = 2026;
  double pi = 3.14159;
  bool isStable = true;

  print('Hello, $name!');
  print('year=$year, pi=${pi.toStringAsFixed(2)}, stable=$isStable');

  // 类型推断与显式标注
  var city = 'Beijing'; // 推断为 String
  String greeting = 'Welcome to $city';
  print(greeting);

  // const（编译期常量）与 final（运行期一次性赋值）
  const maxRetry = 3;
  final timestamp = DateTime.now();
  print('maxRetry=$maxRetry');
  print('timestamp=$timestamp');

  // 数字解析与转换
  int a = int.parse('42');
  double b = double.parse('3.5');
  print('a + b = ${a + b}');
  print('int -> double: ${a.toDouble()}');
  print('double -> int: ${b.round()}');

  // 字符串常用操作
  var text = ' Dart Guide ';
  print('trim: "${text.trim()}"');
  print('upper: ${text.trim().toUpperCase()}');
  print('split: ${'a,b,c'.split(',')}');
  print('padLeft: ${'7'.padLeft(3, '0')}');
}
```

运行输出：

```text
Hello, Dart!
year=2026, pi=3.14, stable=true
Welcome to Beijing
maxRetry=3
timestamp=2026-09-02 18:04:48.056840
a + b = 45.5
int -> double: 42.0
double -> int: 4
trim: "Dart Guide"
upper: DART GUIDE
split: [a, b, c]
padLeft: 007
```

要点小结：

- 字符串插值：`$变量` 或 `${表达式}`。
- `int.parse` / `double.parse` 解析失败会抛 `FormatException`；安全场景用 `int.tryParse` 返回 `null`。
- 字符串是不可变对象，所有"修改"操作都返回新字符串。

---

## 三、控制流

Dart 3 引入了 switch 表达式，支持 `||` 或模式、范围比较与 `=>` 返回值写法，可直接参与赋值。

```dart
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
```

运行输出：

```text
等级 B
sum(1..10) = 55
fruit: apple
fruit: banana
fruit: cherry
5! = 120
do-while count = 3
even i = 0
even i = 2
even i = 4
even i = 6
Mon -> 工作日
```

要点小结：

- `for-in` 是遍历集合的首选写法，比索引循环更简洁安全。
- switch 表达式必须穷尽所有情况（或用 `_` 兜底），否则编译报错，这能有效防止遗漏分支。
- 数字内置便捷判断：`isEven`、`isOdd`、`isNegative`。

---

## 四、函数

Dart 中函数是一等公民：可以赋值给变量、作为参数传递、作为返回值。参数分三类：必填位置参数、命名参数（`{}` 包裹，可加 `required`）、可选位置参数（`[]` 包裹）。

```dart
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
```

运行输出：

```text
Alice (age=30, role=admin)
Bob (age=0, role=guest)
sumRange(1) = 55
sumRange(1, 5, 2) = 9
square(7) = 49
doubled: [2, 4, 6, 8, 10]
filtered: [3, 4, 5]
add10(5) = 15
callback got: 3
callback got: 6
min=1, max=7
```

要点小结：

- 命名参数调用时与顺序无关，可读性好，是 Flutter API 的主流风格。
- `required` 修饰的命名参数必须传入，否则编译报错。
- 函数类型写法：`返回类型 Function(参数类型)`，如 `int Function(int)`。
- 需要返回多个值时，优先使用记录（见第十一章），避免为此专门建类。

---

## 五、集合

三大内置集合：`List`（有序可重复）、`Map`（键值对）、`Set`（无序不重复）。集合字面量支持展开 `...`、集合 `if` 与集合 `for`。

```dart
// 04 集合：List、Map、Set 与集合操作符
void main() {
  // List
  var scores = [90, 85, 77];
  scores.add(95);
  print('scores: $scores, length=${scores.length}');
  print('first=${scores.first}, last=${scores.last}');
  scores.sort((a, b) => b.compareTo(a));
  print('sorted desc: $scores');

  // 集合操作符：展开、if、for
  var base = [1, 2];
  var flag = true;
  var extended = [...base, if (flag) 3, for (var i = 4; i <= 5; i++) i];
  print('extended: $extended');

  // Map
  var capitals = {
    'China': 'Beijing',
    'Japan': 'Tokyo',
    'France': 'Paris',
  };
  capitals['Germany'] = 'Berlin';
  print('China -> ${capitals['China']}');
  print('containsKey(US) = ${capitals.containsKey('US')}');
  print('putIfAbsent: ${capitals.putIfAbsent('US', () => 'Washington')}');
  capitals.forEach((country, capital) => print('  $country: $capital'));

  // Set：自动去重
  var tags = {'dart', 'flutter', 'dart'};
  print('tags: $tags, size=${tags.length}');

  // 函数式操作：where / map / fold / any / every
  var nums = [1, 2, 3, 4, 5, 6];
  var evens = nums.where((n) => n.isEven).toList();
  var squares = nums.map((n) => n * n).toList();
  var total = nums.fold<int>(0, (acc, n) => acc + n);
  print('evens: $evens');
  print('squares: $squares');
  print('total: $total');
  print('any > 5: ${nums.any((n) => n > 5)}');
  print('every > 0: ${nums.every((n) => n > 0)}');

  // 不可变视图
  var fixed = List.unmodifiable([1, 2, 3]);
  print('unmodifiable: $fixed');
}
```

运行输出：

```text
scores: [90, 85, 77, 95], length=4
first=90, last=95
sorted desc: [95, 90, 85, 77]
extended: [1, 2, 3, 4, 5]
China -> Beijing
containsKey(US) = false
putIfAbsent: Washington
  China: Beijing
  Japan: Tokyo
  France: Paris
  Germany: Berlin
  US: Washington
tags: {dart, flutter}, size=2
evens: [2, 4, 6]
squares: [1, 4, 9, 16, 25, 36]
total: 21
any > 5: true
every > 0: true
unmodifiable: [1, 2, 3]
```

要点小结：

- `map` / `where` 返回惰性 `Iterable`，需要多次遍历或索引访问时调用 `.toList()` 固化。
- `fold` 是通用归约；求和等简单场景也可用 `reduce`，但 `reduce` 无法指定初始值且空集合会抛异常。
- 对外暴露集合时用 `List.unmodifiable` 等只读视图，防止调用方篡改内部状态。

---

## 六、类与面向对象

Dart 的类支持构造器简写、命名构造器、`const` 构造器、抽象类、mixin 与接口（任何类都可被 `implements`）。注意：子类要声明 `const` 构造器，其父类必须提供 `const` 构造器。

```dart
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
```

运行输出：

```text
Rectangle(area=12.00)
Rectangle(area=25.00)
Circle(area=12.57)
I am User
toJson: {name: Carol, age: 28}
pretty:
  name: Carol
  age: 28
rectangle width = 2.0
```

要点小结：

- `extends` 单继承，`with` 混入多个 mixin，`implements` 实现接口（必须重写全部成员）。
- `is` 判断类型成功后，变量会被自动"类型提升"，可直接访问子类型成员。
- 字段尽量声明为 `final`，配合构造器参数一次性初始化，构建不可变对象。

---

## 七、空安全

Dart 默认所有类型不可空。需要允许 `null` 时在类型后加 `?`。核心操作符：`?.`（安全调用）、`??`（空值合并）、`??=`（为空才赋值）、`!`（断言非空，慎用）。

```dart
// 06 空安全：可空类型、?.、??、!、late、类型提升
void main() {
  // 默认不可空；加 ? 表示可空
  String? nickname;
  print('nickname = $nickname'); // null
  nickname = 'Ace';
  print('nickname = $nickname');

  // ?. 安全调用：左侧为 null 时整体为 null
  String? city;
  print('city length = ${city?.length}'); // null
  city = 'Shanghai';
  print('city length = ${city?.length}'); // 8

  // ?? 空值合并
  var displayName = nickname ?? 'Anonymous';
  print('displayName = $displayName');

  // ??= 仅在为 null 时赋值
  int? retryCount;
  retryCount ??= 3;
  print('retryCount = $retryCount');

  // 可空集合的级联与链式调用
  var parts = '2026-09-02'.split('-');
  var year = int.tryParse(parts[0]);
  print('year = $year');

  // late：延迟初始化，使用前必须赋值
  late String config;
  config = loadConfig();
  print('config = $config');

  // 类型提升：is 判断后可直接当作非空/子类型使用
  Object data = 'hello null safety';
  if (data is String) {
    print('length = ${data.length}');
  }

  // 空安全下的集合
  List<int?> sparse = [1, null, 3];
  var nonNull = sparse.whereType<int>().toList();
  print('nonNull = $nonNull');
}

String loadConfig() => 'mode=production';
```

运行输出：

```text
nickname = null
nickname = Ace
city length = null
city length = 8
displayName = Ace
retryCount = 3
year = 2026
config = mode=production
length = 17
nonNull = [1, 3]
```

要点小结：

- 优先用 `?.` 与 `??` 组合处理可空值，避免使用 `!` 断言（运行时可能抛异常）。
- `late` 适用于"构造后、使用前一定会赋值"的场景，如依赖注入字段。
- `whereType<T>()` 可从可空集合中过滤出非空的指定类型元素。

---

## 八、泛型

泛型让类、方法在多种类型上复用，同时保留编译期类型检查。`T extends ...` 可对类型参数施加约束。

```dart
// 07 泛型：泛型类、泛型方法、类型约束
class Stack<T> {
  final List<T> _items = [];

  void push(T item) => _items.add(item);

  T pop() {
    if (_items.isEmpty) {
      throw StateError('Stack is empty');
    }
    return _items.removeLast();
  }

  T? get peek => _items.isEmpty ? null : _items.last;
  int get length => _items.length;
  bool get isEmpty => _items.isEmpty;
}

// 泛型方法
T firstOrDefault<T>(List<T> items, T fallback) {
  return items.isEmpty ? fallback : items.first;
}

// 类型约束：T 必须实现 Comparable
T maxOf<T extends Comparable<T>>(List<T> items) {
  if (items.isEmpty) {
    throw ArgumentError('items must not be empty');
  }
  var result = items.first;
  for (var item in items.skip(1)) {
    if (item.compareTo(result) > 0) {
      result = item;
    }
  }
  return result;
}

// 泛型接口与实现
abstract class Repository<T> {
  void save(T entity);
  List<T> findAll();
}

class InMemoryUserRepo implements Repository<String> {
  final List<String> _users = [];

  @override
  void save(String entity) => _users.add(entity);

  @override
  List<String> findAll() => List.unmodifiable(_users);
}

void main() {
  var stack = Stack<int>();
  stack.push(1);
  stack.push(2);
  stack.push(3);
  print('peek = ${stack.peek}');
  print('pop = ${stack.pop()}');
  print('length = ${stack.length}');

  print('firstOrDefault(empty) = ${firstOrDefault(<int>[], -1)}');
  print('firstOrDefault(nums) = ${firstOrDefault([7, 8], -1)}');

  print('maxOf ints = ${maxOf([3, 9, 2])}');
  print('maxOf strings = ${maxOf(['apple', 'zebra', 'mango'])}');

  var repo = InMemoryUserRepo();
  repo.save('alice');
  repo.save('bob');
  print('users = ${repo.findAll()}');

  // 泛型类型信息在运行时可用
  print('stack is Stack<int>: ${stack is Stack<int>}');
}
```

运行输出：

```text
peek = 3
pop = 3
length = 2
firstOrDefault(empty) = -1
firstOrDefault(nums) = 7
maxOf ints = 9
maxOf strings = zebra
users = [alice, bob]
stack is Stack<int>: true
```

要点小结：

- 空字面量集合要显式标注类型参数，如 `<int>[]`，否则推断为 `List<dynamic>`。
- Dart 泛型是具体化的（reified）：运行时可以用 `is Stack<int>` 判断具体类型参数。
- 约束 `T extends Comparable<T>` 让编译器保证传入类型可比较。

---

## 九、异步编程

Dart 单线程 + 事件循环模型下，耗时操作通过 `Future`（一次性结果）与 `Stream`（多次事件）表达，`async`/`await` 让异步代码保持同步写法。

```dart
// 08 异步编程：Future、async/await、Stream
import 'dart:async';

Future<String> fetchUserName() async {
  // 模拟网络延迟
  await Future.delayed(Duration(milliseconds: 50));
  return 'DartUser';
}

Future<int> fetchScore(String user) async {
  await Future.delayed(Duration(milliseconds: 30));
  return user.length * 10;
}

Stream<int> countDown(int from) async* {
  for (var i = from; i >= 1; i--) {
    await Future.delayed(Duration(milliseconds: 20));
    yield i;
  }
}

void main() async {
  // async/await 串行
  var user = await fetchUserName();
  var score = await fetchScore(user);
  print('user=$user, score=$score');

  // Future.wait 并发执行
  var results = await Future.wait([
    Future.delayed(Duration(milliseconds: 40), () => 'A'),
    Future.delayed(Duration(milliseconds: 10), () => 'B'),
  ]);
  print('parallel results: $results');

  // 错误处理：try/catch 捕获 await 抛出的异常
  try {
    await Future.error(StateError('simulated failure'));
  } on StateError catch (e) {
    print('caught: ${e.message}');
  }

  // catchError 链式写法
  var fallback = await Future<int>.error(FormatException('bad input'))
      .catchError((_) => -1);
  print('fallback = $fallback');

  // Stream 消费
  var buffer = StringBuffer('countdown: ');
  await for (var tick in countDown(3)) {
    buffer.write('$tick ');
  }
  print(buffer.toString().trim());

  // Stream 转换
  var doubled = countDown(3).map((n) => n * 2);
  var list = await doubled.toList();
  print('doubled stream: $list');
}
```

运行输出：

```text
user=DartUser, score=80
parallel results: [A, B]
caught: simulated failure
fallback = -1
countdown: 3 2 1
doubled stream: [6, 4, 2]
```

要点小结：

- 多个互不依赖的异步任务用 `Future.wait` 并发执行，总耗时取决于最慢的一个。
- `await` 的异常可以直接用 `try/catch` 捕获，与同步代码一致。
- `async*` + `yield` 生成 `Stream`，适合逐条产出数据的场景（如分页读取、倒计时）。

---

## 十、异常处理

Dart 用 `throw` 抛出任意对象（惯例是抛 `Exception` 或 `Error` 的子类），`try`/`on`/`catch`/`finally` 组合捕获。`on` 按类型过滤，`catch` 拿到对象与堆栈，`rethrow` 在记录日志后继续上抛。

```dart
// 09 异常处理：throw、try/catch/on/finally、自定义异常
class InsufficientBalanceError extends Error {
  final double balance;
  final double amount;

  InsufficientBalanceError(this.balance, this.amount);

  @override
  String toString() =>
      'InsufficientBalanceError: 需要 $amount，但余额只有 $balance';
}

class ValidationException implements Exception {
  final String field;
  final String reason;

  ValidationException(this.field, this.reason);

  @override
  String toString() => 'ValidationException($field): $reason';
}

double withdraw(double balance, double amount) {
  if (amount <= 0) {
    throw ValidationException('amount', '金额必须为正数');
  }
  if (amount > balance) {
    throw InsufficientBalanceError(balance, amount);
  }
  return balance - amount;
}

void main() {
  // on 按类型捕获，catch 拿到异常对象与堆栈
  try {
    withdraw(100, 250);
  } on InsufficientBalanceError catch (e) {
    print('捕获到余额不足: $e');
  }

  try {
    withdraw(100, -5);
  } on ValidationException catch (e) {
    print('捕获到校验异常: $e');
  }

  // finally 总会执行
  try {
    var result = withdraw(100, 30);
    print('取款成功，余额 $result');
  } finally {
    print('finally: 释放资源');
  }

  // 通用 catch 可捕获任意对象（含 Error）
  try {
    throw StateError('something broke');
  } catch (e, st) {
    print('generic catch: $e');
    print('stack first line: ${st.toString().split('\n').first}');
  }

  // 重新抛出
  try {
    try {
      throw FormatException('bad format');
    } catch (e) {
      print('inner catch: $e');
      rethrow;
    }
  } on FormatException catch (e) {
    print('outer catch: ${e.message}');
  }
}
```

运行输出：

```text
捕获到余额不足: InsufficientBalanceError: 需要 250.0，但余额只有 100.0
捕获到校验异常: ValidationException(amount): 金额必须为正数
取款成功，余额 70.0
finally: 释放资源
generic catch: Bad state: something broke
stack first line: #0      main (file:///.../09_error_handling.dart:57:5)
inner catch: FormatException: bad format
outer catch: bad format
```

要点小结：

- 惯例区分：`Exception` 表示可预期的业务异常（调用方应处理），`Error` 表示程序缺陷（应修复代码）。
- 自定义异常重写 `toString()`，让日志直接可读。
- `rethrow` 会保留原始堆栈，直接 `throw e` 会重置堆栈位置，排查问题时信息更少。

---

## 十一、记录与模式匹配

Dart 3 引入记录（Records）与模式匹配（Patterns）。记录是轻量级不可变数据结构，适合返回多值；模式匹配可在 `switch`、`if-case` 与解构赋值中按结构提取数据。

```dart
// 10 Dart 3 新特性：记录（Records）与模式匹配（Patterns）
enum HttpStatus { ok, created, notFound, serverError }

// 记录作为轻量返回值
(double, double) divideWithRemainder(int a, int b) {
  return (a / b, (a % b).toDouble());
}

// 带字段名的记录
({String name, int age}) makeUser() => (name: 'Dave', age: 35);

void main() {
  // 记录基础
  var point = (3, 4);
  print('point = $point, x=${point.$1}, y=${point.$2}');

  var (quotient, remainder) = divideWithRemainder(17, 5);
  print('17 / 5 = $quotient 余 $remainder');

  var user = makeUser();
  print('user: ${user.name}, ${user.age}');

  // 记录交换变量
  var left = 1;
  var right = 2;
  (left, right) = (right, left);
  print('swapped: left=$left, right=$right');

  // if-case 模式匹配
  Object data = [1, 'two', 3.0];
  if (data case [int a, String s, double d]) {
    print('matched list: a=$a, s=$s, d=$d');
  }

  // switch 表达式 + 对象模式
  var status = HttpStatus.notFound;
  var message = switch (status) {
    HttpStatus.ok => '成功',
    HttpStatus.created => '已创建',
    HttpStatus.notFound => '未找到',
    HttpStatus.serverError => '服务器错误',
  };
  print('status message: $message');

  // 逻辑或模式与守卫
  int code = 404;
  var category = switch (code) {
    >= 200 && < 300 => '成功',
    404 || 410 => '资源缺失',
    >= 500 => '服务端错误',
    _ => '其他',
  };
  print('code $code -> $category');

  // null 检查模式
  String? maybe = 'value';
  if (maybe case String value?) {
    print('non-null string: $value');
  }
}
```

运行输出：

```text
point = (3, 4), x=3, y=4
17 / 5 = 3.4 余 2.0
user: Dave, 35
swapped: left=2, right=1
matched list: a=1, s=two, d=3.0
status message: 未找到
code 404 -> 资源缺失
non-null string: value
```

要点小结：

- 位置记录用 `$1`、`$2` 访问；命名字段记录用 `.name` 访问，两者可混合。
- `switch` 表达式对枚举自动穷尽检查，新增枚举值时编译器会提醒补分支。
- 关系模式（`>= 200 && < 300`）与逻辑或模式（`404 || 410`）能显著简化区间与多值判断。

---

## 十二、扩展

扩展（Extensions）可以为已有类型（包括第三方库类型）添加方法与静态成员，无需继承或包装。泛型扩展同样受支持。

```dart
// 11 扩展（Extensions）：为已有类型添加方法与静态成员
extension StringX on String {
  bool get isBlank => trim().isEmpty;

  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }

  String repeatWithSeparator(String separator, int times) {
    return List.filled(times, this).join(separator);
  }
}

extension ListX<T> on List<T> {
  T? get firstOrZero => isEmpty ? null : first;

  List<T> takeFirst(int count) => sublist(0, count.clamp(0, length));
}

extension IntX on int {
  bool get isPrime {
    if (this < 2) return false;
    for (var i = 2; i * i <= this; i++) {
      if (this % i == 0) return false;
    }
    return true;
  }
}

void main() {
  print('"  ".isBlank = ${'  '.isBlank}');
  print('"dart".capitalize() = ${'dart'.capitalize()}');
  print('"ab".repeat = ${'ab'.repeatWithSeparator('-', 3)}');

  var nums = [10, 20, 30];
  print('firstOrZero = ${nums.firstOrZero}');
  print('empty firstOrZero = ${<int>[].firstOrZero}');
  print('takeFirst(2) = ${nums.takeFirst(2)}');

  var primes = <int>[];
  for (var i = 2; i <= 30; i++) {
    if (i.isPrime) primes.add(i);
  }
  print('primes <= 30: $primes');
}
```

运行输出：

```text
"  ".isBlank = true
"dart".capitalize() = Dart
"ab".repeat = ab-ab-ab
firstOrZero = 10
empty firstOrZero = null
takeFirst(2) = [10, 20]
primes <= 30: [2, 3, 5, 7, 11, 13, 17, 19, 23, 29]
```

要点小结：

- 扩展成员与类型已有成员同名时，已有成员优先；扩展之间冲突可用 `ExtensionName(receiver).member` 显式调用。
- 扩展不能添加实例字段，只能添加方法、getter、静态成员。
- 命名扩展（如 `StringX`）便于按需导入与查找来源。

---

## 十三、JSON 与文件 IO

`dart:convert` 提供 JSON 编解码，`dart:io` 提供文件读写。惯例是为模型类实现 `toJson()` 与 `fromJson()` 工厂构造器。

```dart
// 12 JSON 编解码与文件 IO（dart:convert、dart:io）
import 'dart:convert';
import 'dart:io';

class Article {
  final String title;
  final List<String> tags;

  Article({required this.title, required this.tags});

  // 序列化
  Map<String, Object?> toJson() => {'title': title, 'tags': tags};

  // 反序列化
  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      title: json['title'] as String,
      tags: (json['tags'] as List).cast<String>(),
    );
  }

  @override
  String toString() => 'Article(title=$title, tags=$tags)';
}

void main() async {
  // 对象 <-> JSON 字符串
  var article = Article(title: 'Dart 指南', tags: ['dart', 'tutorial']);
  var jsonText = jsonEncode(article);
  print('encoded: $jsonText');

  var decoded = Article.fromJson(jsonDecode(jsonText) as Map<String, dynamic>);
  print('decoded: $decoded');

  // 格式化输出
  var pretty = JsonEncoder.withIndent('  ').convert(article.toJson());
  print('pretty:\n$pretty');

  // 文件读写
  var dir = Directory.systemTemp.createTempSync('dart_guide_');
  var file = File('${dir.path}${Platform.pathSeparator}note.txt');

  await file.writeAsString('第一行\n第二行', encoding: utf8);
  var content = await file.readAsString(encoding: utf8);
  print('file content:\n$content');

  // 追加写入与按行读取
  await file.writeAsString('\n第三行', mode: FileMode.append, encoding: utf8);
  var lines = await file.readAsLines(encoding: utf8);
  print('lines = $lines');
  print('exists = ${await file.exists()}, size = ${await file.length()} bytes');

  // 清理
  await file.delete();
  await dir.delete();
  print('cleaned up: ${!await dir.exists()}');
}
```

运行输出：

```text
encoded: {"title":"Dart 指南","tags":["dart","tutorial"]}
decoded: Article(title=Dart 指南, tags=[dart, tutorial])
pretty:
{
  "title": "Dart 指南",
  "tags": [
    "dart",
    "tutorial"
  ]
}
file content:
第一行
第二行
lines = [第一行, 第二行, 第三行]
exists = true, size = 29 bytes
cleaned up: true
```

要点小结：

- `jsonEncode` 会自动调用对象的 `toJson()` 方法。
- `jsonDecode` 返回 `dynamic`，需要显式转型为 `Map<String, dynamic>` 或 `List`。
- 文件操作优先使用异步方法（`readAsString`、`writeAsString`），避免阻塞事件循环；跨平台路径拼接用 `Platform.pathSeparator` 或 `path` 包。

---

## 十四、包管理与项目结构

Dart 使用 pub 作为包管理器，依赖声明在项目根目录的 `pubspec.yaml`。

### 14.1 创建项目

```powershell
# 创建命令行项目
dart create my_app
cd my_app

# 拉取依赖
dart pub get

# 运行
dart run
```

### 14.2 pubspec.yaml 示例

```yaml
name: my_app
description: A sample Dart CLI application.
version: 1.0.0

environment:
  sdk: ^3.13.0

dependencies:
  args: ^2.4.0        # 命令行参数解析
  http: ^1.2.0        # HTTP 客户端

dev_dependencies:
  lints: ^4.0.0       # 官方静态分析规则
  test: ^1.25.0       # 单元测试框架
```

### 14.3 标准目录结构

```text
my_app/
├── bin/            # 可执行入口（dart run 默认运行此目录）
│   └── my_app.dart
├── lib/            # 库代码（可被其他包导入）
│   ├── src/        # 内部实现，不对外暴露
│   └── my_app.dart # 统一导出入口
├── test/           # 单元测试（以 _test.dart 结尾）
├── pubspec.yaml    # 依赖与元数据声明
└── analysis_options.yaml  # 静态分析配置
```

### 14.4 单元测试

`test/counter_test.dart`：

```dart
import 'package:test/test.dart';

void main() {
  test('字符串拼接', () {
    expect('Hello, ' + 'Dart', equals('Hello, Dart'));
  });

  group('数学运算', () {
    test('加法', () => expect(1 + 1, equals(2)));
    test('除法', () => expect(10 / 4, equals(2.5)));
  });
}
```

运行：`dart test`。

---

## 十五、常用命令速查

| 场景 | 命令 |
| --- | --- |
| 运行脚本 | `dart run app.dart` |
| 静态分析 | `dart analyze` |
| 格式化 | `dart format .` |
| 运行测试 | `dart test` |
| 添加依赖 | `dart pub add http` |
| 升级依赖 | `dart pub upgrade` |
| 编译原生可执行文件 | `dart compile exe bin/app.dart -o app.exe` |
| 编译 JS | `dart compile js web/main.dart -o main.js` |
| 编译 WASM | `dart compile wasm web/main.dart -o main.wasm` |
| 生成文档 | `dart doc` |
| 查看 SDK 版本 | `dart --version` |

## 附：例程验证说明

本指南全部 12 个例程（01 至 12 章）均以独立 `.dart` 文件形式，使用如下命令逐一验证：

```powershell
G:\scoop\apps\dart\3.13.2\bin\dart.exe run <例程文件>.dart
```

验证结果：全部例程编译通过并正常运行，文中"运行输出"即为实际运行结果。
