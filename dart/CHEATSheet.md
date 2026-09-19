# Dart 速查表

配合[教程](docs/01-overview.md)使用，条目按章号索引；主线 Dart 3.13。

## 变量与常量（03）

```dart
var x = 1;          // 类型推断，推断后固定
final y = DateTime.now();  // 运行期一次性赋值
const z = 3.14;     // 编译期常量，深度不可变、规范化
dynamic d;          // 逃生舱：关闭静态检查（尽量别用）
late final cfg = load();   // 首次访问才求值
```

## 内置类型（03）

| 类型 | 备注 |
|---|---|
| `int` / `double` | 64 位；无 float；无隐式转换，`5 ~/ 2` 整除 |
| `num` | int/double 共同父类 |
| `String` | 不可变；插值 `$x` / `${expr}`；`'''多行'''`；`r'raw'` |
| `bool` | 无 truthy |

```dart
int.parse('42');   // 失败抛 FormatException
int.tryParse('4x'); // 失败返回 null
3.7.round(); 3.7.truncate();
```

## 函数（05）

```dart
String f({required String name, int age = 0}) => …;  // 命名参数
int g(int start, [int end = 10]) => …;                // 可选位置参数
int square(int x) => x * x;                           // 箭头
int Function(int) add10 = makeAdder(10);              // 函数类型
var (lo, hi) = minMax(list);                          // record 多返回值解构
```

## 集合（06）

```dart
var list = [1, 2];
var set = <String>{'a'};
var map = {'k': 1};
var built = [...list, if (ok) 9, for (final x in list) x * 10]; // 字面量构建
list.where(f).map(f).toList();      // 惰性管道，toList 落袋
list.fold(0, (a, b) => a + b);      // 万能归约（空集合安全）
[...list]..sort();                  // 拷贝排序不动原列表
List.unmodifiable([1]);             // 只读视图
```

## 类（07）

```dart
class Point {
  final double x, y;
  Point(this.x, this.y);                 // 主构造：参数直赋
  Point.origin() : x = 0, y = 0;         // 命名构造 + 初始化列表
  Point.alongX(double x) : this(x, 0);   // 重定向
  factory Point.cached(double x) { … }   // 工厂：自己决定返回实例
  double get dist => …;                  // getter
  set dist(double v) { … }
  Point operator +(Point o) => …;
  @override bool operator ==(Object o) => o is Point && …;
  @override int get hashCode => Object.hash(x, y);  // 与 == 成对！
}
```

## 继承 / Mixin / 修饰符（08–09）

| 写法 | 语义 |
|---|---|
| `extends A` | 实现复用，单继承 |
| `implements A, B` | 纯契约（每个类隐式是接口），可多个 |
| `with M1, M2` | mixin 叠加，**后者覆盖前者**（线性化） |
| `mixin Pet on Animal` | 限定混入基类 |
| `sealed class R` | 子类同库封闭 → switch 穷尽检查 |
| `base` / `interface` / `final class X` | 禁 implements / 禁 extends / 都禁 |

## 空安全（10）

```dart
String? s;
s?.length      // null 短路
s ?? '默认'    // 兜底
s ??= 'v'      // 为 null 才赋值
s!.length      // 断言非空（错了运行时抛）
late final c = init();  // 惰性初始化
```

字段不参与类型提升：判空后要 `?.`/`??` 或先拷进局部变量。

## 泛型（11）

```dart
T maxOf<T extends num>(T a, T b) => a > b ? a : b;
List<num> nums = <int>[1];  // 协变：合法，但写入 nums.add(1.5) 运行时抛
ints is List<int>           // reified：运行时类型可判
```

## 异常（12）

```dart
try { risky(); }
on MyException catch (e) { … }
catch (e, stack) { rethrow; }   // rethrow 保留原始栈
finally { … }
class MyError implements Exception { … }  // 自定义（带字段 + toString）
```

Error 族（RangeError/ArgumentError…）= bug 别捕获；Exception 族 = 可预期失败。

## 记录与模式（13）

```dart
var p = (x: 1, y: 2);           // 命名字段；==(结构相等)
var rgb = (255, 0, 0);          // 位置字段：rgb.$1
var (x: a, y: b) = p;           // 命名解构
final (r, g, bl) = rgb;         // 位置解构

String f(Object o) => switch (o) {
  int n when n > 0 => '正数',    // 类型 + when
  int() => '非正整数',            // 空参类型
  'Sat' || 'Sun' => '周末',      // 逻辑模式
  [int first, ...] => '列表',     // 列表模式
  {'name': var n} => '映射',      // 映射模式
  Circle(r: var r) => '圆 $r',    // 对象模式
  _ => '其他',
};
if (v case (int a, int b)) { … } // if-case
```

sealed 层级的 switch 不需要 `_`；新增子类漏分支=编译错误。

## 扩展（14）

```dart
extension StringX on String {
  int get wordCount => …;
}
extension <T> on List<T> { T? get firstOrNull => …; }
extension on String? { String orDash() => this ?? '-'; }
StringX('hi').wordCount();       // 冲突时显式调用

extension type Meters(double value) { … }  // 零开销新类型，不与 double 互通
typedef Mapper<S, T> = T Function(S);      // 纯别名
```

## 异步（15–17）

```dart
Future<String> f() async { return await g(); }      // async/await
await Future.wait([a(), b(), c()]);                 // 并行（耗时≈最长者）
try { await f(); } on StateError catch (e) { … }    // 错误处理同同步

Stream<int> s() async* { yield 1; }                 // 生成器
await for (final x in s()) { … }                    // 消费
Stream.periodic(d, (i) => i).take(3).toList();
final b = s().asBroadcastStream();                  // 单订阅→广播
final c = StreamController<T>(); c.add(v); c.close(); // 手动推送（必须 close）

final r = await Isolate.run(() => heavy(data));     // 一行搬计算
await Isolate.spawn(entry, (data, port.sendPort));  // 手工协议；用完 close 端口
```

事件循环：microtask 队列优先于 event 队列；长计算冻结循环 → Isolate。

## 文件 / JSON / HTTP（18）

```dart
await File(p).writeAsString(s, mode: FileMode.append);
final t = await File(p).readAsString();
final dir = await Directory.systemTemp.createTemp('x_');

final obj = jsonDecode(text) as Map<String, dynamic>;  // 对象→Map<String,dynamic>
final s = jsonEncode(obj);
factory T.fromJson(Map<String, dynamic> j) => …;       // 类型安全模板

final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0); // 0=随机端口
final res = await (await HttpClient().getUrl(uri)).close();
await utf8.decodeStream(res);                          // body 是字节流
await server.close(force: true);                       // 用完必关
```

## 测试（19）

```dart
group('主题', () {
  setUp(() { … });                       // 每用例重建夹具
  test('行为描述', () {
    expect(cart.total, closeTo(105.0, 0.001));   // 浮点用 closeTo
    expect(() => parse(-1), throwsA(isA<ArgumentError>()));
    expect(list, containsAll([1, 2]));
  });
});
// dart test --plain-name "满 100 打九折"
```

## 命令速查

```bash
dart run file.dart              # JIT 运行
dart analyze                    # 静态检查（本教程标准：零告警）
dart format .                   # 官方格式化
dart compile exe file.dart -o out       # AOT（Windows 下产物为 out.exe）
dart pub get / add <pkg>        # 依赖
dart test [--plain-name "…"]    # 测试
dart create -t console name     # 脚手架
```
