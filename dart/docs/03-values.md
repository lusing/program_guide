# 03 · 变量与内置类型：一切皆对象

> 对应示例：examples/03_variables.dart

## 3.1 解决什么问题

多数语言把类型分成"原始类型 + 对象"两层（Java 的 int/Integer、C# 的值/装箱）。Dart 不要这一层：**int、double、bool、String 全是对象**，`42.isEven` 是合法调用——数字自己带着方法。这带来的直接后果是：集合能装任何值而不需要装箱拆箱，泛型（第 11 章）也没有特例。

先看变量怎么声明：

```dart
  // ═══ 3.1 var 与类型推断 ═══
  var city = 'Beijing'; // 推断为 String
  // city = 42; // 编译错误：推断后类型固定，不能改放 int
  String explicit = '显式标注也可以';
  print('$city / $explicit');
```

`var` 是"推断类型"，**不是"任意类型"**——推断完成那一刻类型就钉死了，第二行想塞 `int` 直接编译错误。什么时候写显式类型？公共 API 的签名（读的人没有推断上下文）和推断有歧义的地方；局部变量用 `var` 是主流风格。

## 3.2 内置类型与 num 家族

```dart
  // ═══ 3.2 内置类型 ═══
  int count = 42;
  double ratio = 0.75;
  num anyNumber = count; // num 是 int/double 的共同父类
  anyNumber = ratio; // num 变量既能装 int 也能装 double
  bool ok = true;
  print('int=$count double=$ratio num=$anyNumber bool=$ok');
  // ignore: unnecessary_type_check
  print('int 是 num 的子类：${count is num}');
```

几个与直觉有关的点：

| 类型 | 说明 |
|---|---|
| `int` | 64 位整数（原生平台），没有 32/16/8 位变体 |
| `double` | 64 位浮点，Dart **没有单独的 float** |
| `num` | int 与 double 的父类：`num x = 1; x = 1.5;` 合法 |
| `String` | UTF-16 code unit 序列，不可变（见 3.3） |
| `bool` | 只有 `true`/`false`，没有 truthy（第 04 章） |

`num` 的价值在"数值通吃"的 API：接受 `num` 的函数 int/double 都能传。示例里那行 `is num` 恒为 true 还触发了 lint 的抱怨——分析器都"知道"得太清楚，这正是静态类型工作的样子。

## 3.3 字符串：插值、多行与 raw

```dart
  // ═══ 3.3 字符串 ═══
  var adjacent = '相邻''字面量''自动拼接';
  var multi = '''三引号
可以换行''';
  var raw = r'$name 不插值（raw 字符串）';
  var text = '  Dart Guide  ';
  print('${text.trim()} / ${text.toUpperCase()}');
  print('split: ${'a,b,c'.split(',')}');
  print("padLeft: ${'7'.padLeft(3, '0')}");
  print('$adjacent / ${multi.length} 字 / $raw');
```

一张表收全常用能力：

| 能力 | 写法 | 备注 |
|---|---|---|
| 插值 | `'$x'` / `'${e}'` | 见第 02 章 |
| 相邻拼接 | `'a' 'b'` → `'ab'` | 编译期拼接，多行字符串排版的利器 |
| 多行 | `'''…'''` | 换行原样保留 |
| raw | `r'$x'` | 不插值；正则、路径首选 |
| 常用方法 | `trim/split/padLeft/replaceAll` | 全部返回新串 |

**字符串不可变**：所有"修改"操作都返回新字符串，原串不动。这是与 C++/Rust 语言的 `String` 语义不同的设计选择，换来的是值语义的安心——传给任何人都不会被改。

## 3.4 解析与转换

字符串 ↔ 数字的桥就两对 API：

```dart
  // ═══ 3.4 数字解析与转换 ═══
  var parsed = int.parse('42'); // 失败抛 FormatException
  var safe = int.tryParse('4x'); // 失败返回 null（配合 ?? 给默认值）
  print('parsed=$parsed safe=${safe ?? -1}');
  print('3.7 round=${3.7.round()} truncate=${3.7.truncate()}');
```

- `parse` 抛异常（第 12 章），适合"格式由我方保证"的场景；
- `tryParse` 返回 `int?`（第 10 章空安全），配合 `??` 给默认值，适合外部输入。

浮点取整有三个方向：`round()`（四舍五入）、`truncate()`（向零截断）、`toInt()`（同 truncate）。int 与 double 之间**没有隐式转换**：`1 + 1.5` 合法（int 会参与提升），但 `int x = 1.9` 不行，要 `1.9.toInt()`。

## 3.5 const 与 final：两种"不可变"

Dart 把"不可变"拆成两档，很多人在这里混乱，一张表说清：

```dart
// ═══ 3.5 const 与 final：两种"不可变" ═══
const double pi = 3.14159; // 编译期常量：值必须在编译时确定
final DateTime bootTime = DateTime.now(); // 运行期一次性赋值
```

以及 const 的隐藏大招——**深度不可变**：

```dart
  // ═══ 3.5（续）const 的"深度不可变" ═══
  const rates = [0.1, 0.2]; // const 列表：整个字面量编译期固化，元素也不可变
  final list = [1, 2]; // final 只锁"引用"，列表本身仍可 add
  list.add(3);
  print('rates=$rates list=$list');
```

| | `const` | `final` |
|---|---|---|
| 赋值时机 | 编译期 | 运行期，且只能一次 |
| 值的要求 | 字面量/常量表达式 | 任意表达式 |
| 集合语义 | 整棵冻结（元素也不可变） | 只锁引用，内容可变 |
| 额外福利 | 相同字面量**规范化为同一实例**（identical 为 true） | 无 |

选择顺序：**能用 const 就 const**（编译器优化 + 深度冻结），要运行期值（`DateTime.now()`、函数结果）就用 final。

## 3.6 dynamic：逃生舱，以及为什么别上车

```dart
// ═══ 3.6 dynamic：静态检查的逃生舱（尽量别用） ═══
dynamic anything = 42;
// …
  anything = '现在装字符串';
  print('anything.length = ${anything.length}'); // 静态检查完全放行
```

`dynamic` 关闭静态检查，一切错误推迟到运行时。合理场景几乎只剩两类：与动态数据（如裸 JSON）打交道的**中间态**、以及反射式 API。即便前者，第 18 章会示范"尽早 cast 成具体类型"的写法把 dynamic 圈起来。注意区分：`Object?` 是"任何类型但保留检查"，`dynamic` 是"放弃检查"——前者几乎总是更好的选择。

## 坑位清单

- **`var x;` 是 dynamic 不是报错**：没有初始化值就没有推断依据，x 成了 dynamic——多数时候这是笔误，值得警惕。
- **const 里装运行期值是编译错**：`const t = DateTime.now();` 不行，退到 final。
- **`==` 比较字符串内容**：与 Java 不同，Dart 的 `==` 对 String 按内容比较；要判"同一实例"用 `identical(a, b)`。
- **int/double 混算看清结果类型**：`5 / 2` 是 `2.5`（double！），要整除用 `5 ~/ 2`。
