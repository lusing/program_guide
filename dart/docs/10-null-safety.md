# 10 · 空安全：把 null 关进类型系统

> 对应示例：examples/10_null_safety.dart

## 10.1 解决什么问题

null 引用被称作"十亿美元错误"——一个世纪以来最多的运行时崩溃由它引发。Dart 2.12 起的 sound null safety 把 null 从"任何类型的隐形成员"变成"一种必须显式声明的类型"：**默认不可空，想要可空必须写 `?`**。这不是语法糖，是类型系统的承诺：不可空类型的变量里永远不会出现 null，编译器替你保证。

```dart
  // ═══ 10.1 默认不可空 ═══
  String title = 'Dart';
  // title = null; // 编译错误：String 不能装 null
  String? subtitle; // 加 ? 才可空，默认值就是 null
  print('title=$title subtitle=$subtitle');
```

理解 `String?` 的正确姿势：它是 `String | null` 的联合类型，是**另一个类型**——`String?` 能干的事（可空操作）`String` 干不了，反之亦然。

## 10.2 四件套操作符：?. ?? ??= 与 !

```dart
  // ═══ 10.2 ?. 与 ?? ═══
  subtitle = fetchSubtitle(); // 换成"运行时才知道"的来源，下面几个操作符才有悬念
  print('len=${subtitle?.length}'); // null 时短路，整个表达式为 null
  print('len=${subtitle?.length ?? 0}'); // 给空值兜底
  subtitle ??= '默认副标题'; // 为 null 才赋值
  print('subtitle=$subtitle');
```

| 操作符 | 名字 | 行为 |
|---|---|---|
| `a?.b` | 条件成员访问 | a 为 null 整个表达式为 null，不抛错 |
| `a ?? b` | 空值合并 | a 为 null 取 b |
| `a ??= b` | 空值赋值 | a 为 null 才把 b 赋给它 |
| `a!` | 非空断言 | 断言 a 非 null；错了**运行时当场抛错** |

前三个是"优雅共存"工具——把 null 当正常情况流过管道。`!` 性质完全不同：

## 10.3 ! 断言：每次使用都要过一遍良心

```dart
  // ═══ 10.3 ! 断言：我知道它不是 null（错了运行时抛错） ═══
  subtitle = fetchLocal(); // 换个来源：类型上仍可空、运行时非空，! 才有意义
  int len = subtitle!.length; // 若这里拿到 null，! 处当场抛错
  print('len=$len');
```

`!` 把检查责任从编译器转到你身上：判错就是运行时崩溃。每写一个 `!` 都该自问"我凭什么知道它非空"——有证据（刚检查过、刚赋值）才用；拿不出证据就用 `?.`/`??`，或者改造数据流让证据出现在类型里（比如把"可空参数"变成"必填 + 默认值"）。

## 10.4 类型提升：编译器也在帮你记判空

这是空安全里最微妙的一块，也是示例特意设计的对照：

```dart
  // ═══ 10.4（续）局部变量才会被提升 ═══
  String? local = fetchLocal(); // 运行时非空，但类型系统不知道
  if (local != null) {
    print('local 提升：${local.toUpperCase()}'); // 局部变量判空后自动窄化
  }
```

局部变量一旦判过空，后面编译器自动把它当非空用（提升/promotion）。**但字段不享受提升**：

```dart
class Profile {
  String? nickname; // 可空字段

  String display() {
    // if (nickname != null) { return nickname.toUpperCase(); } // 编译错误：
    // 提升只对局部变量生效，字段可能被其他代码改回 null
    return nickname?.toUpperCase() ?? '（匿名）';
  }
}
```

为什么？判空和取值之间，字段可能被别的方法（甚至别的 isolate 里的逻辑）改回 null——编译器不敢打包票。两条出路：**先拷进局部变量再判空**（提升生效），或直接用 `?.`/`??` 链。这是从其他语言迁来的人最高频的"为什么这里报错"。

## 10.5 late：先声明、后初始化

```dart
  // ═══ 10.5 late：先声明后初始化，首次访问才求值 ═══
  late final String config = loadConfig();
  print('访问 config 之前不会触发 loadConfig');
  print('config=$config');
```

```dart
String loadConfig() {
  print('>> loadConfig 执行（惰性求值的证据）');
  return 'dev';
}
```

`late` 解决"构造时还拿不到值"的场景：声明与初始化分离，**首次访问才执行**初始化（输出顺序就是证据）。`late final` 组合 = "只算一次、之后不变"。代价：初始化逻辑若真的没跑过就访问，抛 `LateInitializationError`——late 是把检查推迟，不是取消检查；对象字段"一定会在某个生命周期回调里初始化"时它最顺手（Flutter 的 initState 场景）。

## 10.6 可空参数的设计惯例

```dart
String greet(String? who) => '你好，${who ?? '游客'}';
```

```dart
  // ═══ 10.6 可空参数与默认值 ═══
  print(greet(null));
  print(greet('小李'));
```

对外 API 收可空参数时，惯例是**在函数边界就把 null 化解掉**（`??` 默认值 / 转成错误），函数体内部保持非空世界——null 停留的范围越小，心智负担越轻。

## 坑位清单

- **滥用 `!`**：每个 `!` 都是一次"运行时见"的赌博；能用 `?.`/`??`/提升化解的都别用断言。
- **字段判空后仍报错**：提升只对局部变量；字段请先 `final v = field;` 再判，或用 `?.`。
- **`??` 的优先级错觉**：`a ?? b ?? c` 从左到右取第一个非空，别与 `?:` 混写进复杂表达式而不加括号。
- **late 忘初始化就访问**：抛 `LateInitializationError`，且在 release 模式同样会抛——它不是调试期专用检查。
- **`?` 只能标在类型上**：`String? s` 合法；局部 `var s? = …` 不存在这种语法。
