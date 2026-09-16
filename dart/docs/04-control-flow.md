# 04 · 控制流：从语句到表达式

> 对应示例：examples/04_control_flow.dart

## 4.1 解决什么问题

传统 C 系 switch 有三个老毛病：**忘写 break 就贯穿**、**switch 是语句不是表达式**（不能直接赋值）、**漏了 default 编译器不吭声**。Dart 3 用 switch 表达式 + 模式匹配把三个一起解决——但先从最基础的 if 说起，因为 Dart 的 if 有一条 JS 背景的人最容易踩的规矩。

```dart
  // ═══ 4.1 if：条件必须是 bool，没有 truthy ═══
  int score = 88;
  if (score >= 90) {
    print('A');
  } else if (score >= 80) {
    print('B');
  } else {
    print('C');
  }
  var list = [1, 2, 3];
  if (list.isNotEmpty) {
    print('list 非空，长度 ${list.length}');
  }
```

**条件必须是 bool**：`if (name)` 在 name 是字符串时直接编译错误——Dart 没有 truthy，空串、0、空集合都不等于 false。判空集合用 `isEmpty/isNotEmpty`（不是 `length > 0`），这是社区惯用法。

## 4.2 循环四件套

```dart
  // ═══ 4.2 for / for-in / while / do-while ═══
  var sum = 0;
  for (var i = 1; i <= 10; i++) {
    sum += i;
  }
  print('sum(1..10) = $sum');

  for (final fruit in ['apple', 'banana', 'cherry']) {
    print('fruit: $fruit');
  }

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
```

选择顺序：**遍历集合首选 for-in**（没有越界、没有索引变量）；需要索引或复杂步进才用经典 for；while/do-while 与其他语言语义一致。注意 for-in 的循环变量写 `final`——它每轮是新绑定，这关系到第 05 章说的闭包捕获行为。

## 4.3 break 与 continue

```dart
  // ═══ 4.3 break 与 continue ═══
  for (var i = 0; i < 10; i++) {
    if (i.isOdd) continue;
    if (i > 6) break;
    print('even i = $i');
  }
```

`continue` 跳过本轮进入下一轮，`break` 直接结束循环——行为与 C/Java 一致。Dart 还支持 `outer:` 标签配合 `break outer;` 跳出多层循环，但真实代码里更常见的做法是把内层循环提成函数用 return 代替。

## 4.4 switch 语句：Dart 3 的样子

```dart
// ═══ 4.4 switch 语句：case 体非空必须以 break/return/throw 结束（Dart 3） ═══
String grade(int score) {
  switch (score) {
    case >= 90:
      return 'A';
    case >= 80:
      return 'B';
    case >= 60:
      return 'C';
    default:
      return '不及格';
  }
}
```

两个新规矩：**空 case 体不再需要 break**（隐式结束，历史上那个"忘写 break"的 bug 类型被整个消灭）；非空 case 体必须以 break/return/continue/throw 收尾。还有个新能力——case 里能用**关系模式** `>= 90`，以前这种"区间判断"只能写成 if-else 链。

## 4.5 switch 表达式：Dart 3 的主角

```dart
// ═══ 4.5 switch 表达式：Dart 3 的核心新语法 ═══
// 支持模式组合（||）、关系模式与 => 返回值，可直接参与赋值
String dayType(String weekday) => switch (weekday) {
      'Sat' || 'Sun' => '周末',
      'Mon' || 'Tue' || 'Wed' || 'Thu' || 'Fri' => '工作日',
      _ => '未知',
    };
```

与 switch 语句的差别是本质性的：

| | switch 语句 | switch 表达式 |
|---|---|---|
| 产出 | 执行分支动作 | **有值**，可赋值/返回/嵌进表达式 |
| 分支写法 | `case X: …; break;` | `模式 => 值` |
| 组合力 | 单个常量为主 | `\|\|`、关系、类型、解构…（第 13 章族谱） |
| 穷尽性 | 有 default 即可 | **必须穷尽**，否则编译错误 |

穷尽性检查是这里最值钱的部分：`weekday` 是 String，不可能枚举完，所以末尾用 `_` 兜底；将来第 13 章配 sealed 类时，连 `_` 都不用——编译器替你数清所有分支，新增子类忘了处理会直接编译失败。这就是"重构安全网"。

## 4.6 三元 ?: ——另一个"表达式级"分支

```dart
  // ═══ 4.6 条件表达式：?: 是表达式，if 不是 ═══
  var parity = sum.isEven ? '偶' : '奇';
  print('55 是$parity数');
```

Dart 的 if **是语句不是表达式**（不能 `var x = if …`），要"就地按条件取值"有两个选择：简单的二选一用 `?:`；分支逻辑复杂或涉及模式匹配用 switch 表达式。这条边界记住：`?:` 管小，switch 表达式管大。

## 坑位清单

- **switch 表达式忘兜底**：值类型是 String 这类开放集合时必须 `_ => …`，否则编译错误（这不是警告，是错误——好事）。
- **关系模式写法**：`case >= 90` 合法，但 `case n >= 90` 在 switch 表达式里要改用 when 卫兵写常量比较；区间语义优先用关系模式。
- **循环里建闭包**：`for (var i …)` 里生成闭包捕获的是同一个 i 的最终值；`for (final i …)` 每轮新绑定才是想要的快照（连第 05 章闭包）。
- **do-while 至少执行一次**：把"先斩后奏"留给确实需要的场景（重试、菜单），别拿它当 while 的别名。
