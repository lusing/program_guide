# 16 · 文本处理

> 对应示例：[`examples/16_text/16_text.io`](../examples/16_text/16_text.io)

字符串就是第 04 章那个按内容自动升级编码的 Sequence。本章把「不可变 + 就地方法」「码点 vs 字节」
「`interpolate` 的三种死法」和日常的切分/查找/对齐一起过一遍，并给出实测的中文排序结论。

## 16.1 字面量不可变：asMutable 与就地方法

```text
-- 16.1 字面量不可变：asMutable 与就地方法
字面量的类型 = Sequence
isMutable = false
直接 strip 抛异常 = true
异常消息原文 = 'strip' cannot be called on an immutable Sequence
Sequence 有 asImmutable 吗（没有） = false
asMutable 之后 isMutable = true
就地 strip 的返回值 = [Io Text]
同一个对象已经被改掉了 = [Io Text]
```

```io
s := "  Io Text  "
s strip                 // 抛：'strip' cannot be called on an immutable Sequence
m := s asMutable
m strip                 // 就地剥空白，返回的是 m 自己（现在内容是 "Io Text"）
```

`strip`、`lstrip`、`rstrip`、`replaceSeq`、`uppercase`、`escape` 这一批都是**就地**方法，
字面量上直接调必然抛异常。反过来，带 `as` 前缀的（`asUppercase`、`asCapitalized`）和 `align*` 才是不改原串的。
另外：**没有 `asImmutable`**，所以"先 asMutable 改完再冻回去"这条路在 Io 里不存在。

> **为什么重要**：把「就地」和「返回新值」分清，能省掉一大半诡异 bug——
> 尤其是 `escape`/`replaceSeq` 这种看起来像纯函数的，它会改掉你的原串（连别人的字段也可能改掉，见第 15 章坑位 5）。

## 16.2 编码三件套与 at(i)：码点、字节、字符

```text
-- 16.2 编码三件套与 at(i)：码点、字节、字符
itemType（含中文 → uint32） = uint32
size（数的是码点） = 6
sizeInBytes = 24
asUTF8 size（才是 UTF-8 字节数） = 10
asUTF8 之后的 itemType = uint8
纯 ASCII 的 itemType = uint8
纯 ASCII 的 size == sizeInBytes = true
s at(0) 的类型 = Number
s at(0) 的值（Unicode 码点） = 20013
s at(0) asCharacter = 中
asUTF8 之后 at(0) 给的是一个字节 = 228
```

```io
s := "中文 abc"
s itemType      // uint32：含中文 → 每个码点 4 字节
s size          // 6   —— 数的是码点
s sizeInBytes   // 24  —— 4 * 6
(s asUTF8) size // 10  —— 才是 UTF-8 字节数

s at(0)              // 20013 —— Number，不是字符
s at(0) asCharacter  // "中"
(s asUTF8) at(0)     // 228 —— 对字节串取下标，拿到的是一个字节
```

三个数（`size` / `sizeInBytes` / `asUTF8 size`）分别回答三个不同的问题，别混。
`at(i)` 给的是**码点（Number）**，要字符得再过一道 `asCharacter`。

**这一节真正的坑是：两种宽度的序列做比较，不会报错，只会给错答案。**
`type` 对两者**都**报 `Sequence`，所以看不出区别。把第 15 章
`System runCommand` 拿回来的子进程输出（`ascii`/`uint8`）和源码里的字面量
（`ucs4`/`uint32`）放在一起，实测是这样：

```text
stdout 的 encoding / itemType = ascii / uint8
字面量 "中文 ok" 的 encoding / itemType = ucs4 / uint32
stdout 的 size / sizeInBytes = list(10, 10)
字面量 "中文 ok" 的 size / sizeInBytes = list(5, 20)
直接 containsSeq（尺子不一样） = false
两边 asUTF8 后 containsSeq = true
```

（这几行是第 15 章 15.6.1 的实测输出，完整上下文见那边。
`"中文 ok\n"` 在字节串里 `size` 是 10，在 UCS4 字面量里 `size` 是 5——
**同一串文字，两个长度**。）

判据是 `encoding` / `itemType` 这两个槽，**不是 `type`**。
碰到「明明看着一样的两个串，比较却是 `false`」时，先打这两个槽。
比较前把两边都 `asUTF8`，就落到同一把尺子上。

> **为什么重要**：第 14 章那个「写文件 56 还是 18」的问题，根子就在这里。
> 记住一句话：**`size` 数码点，`sizeInBytes` 数内部字节，`asUTF8 size` 才是落盘字节**；
> 再加一句：**跨边界的字符串一律先 `asUTF8`，比较前两边都换算**。

## 16.3 interpolate 的三个坑（段错误那条只写在注释里）

`interpolate` 是把 `#{…}` 里的表达式求值后填回字符串，**但它只对纯 ASCII 安全**。

```text
-- 16.3 interpolate 的三个坑（段错误那条只写在注释里）
纯 ASCII 模板正常 = n = 3
只含 ASCII 的模板 + .. 拼接，也正常 = n = 3
中文前缀：结果尾巴被吃掉 = [中文1]
它只返回了 3 个字符 = 3
非 ASCII 前缀 + 标识符 → 抛异常 = true
异常消息原文 = Object does not respond to 'l'
替代写法：.. 接 asString = n = 3
```

```io
"n = #{1 + 2}" interpolate            // "n = 3"       —— 纯 ASCII，安全
"中文#{1 + 2}" interpolate            // "中文1"       —— 尾巴被吃掉，长度只有 3
"中文#{list(1,2) size}" interpolate   // Exception: Object does not respond to 'l'
"中文#{(1 + 2)}" interpolate          // 段错误 rc=139，什么都不打（示例里不跑这一条）

"n = " .. 3 asString                  // 安全的替代写法
```

三种坏法按严重程度排：非 ASCII 前缀会**丢尾巴**（`中文#{1 + 2}` 只给你 `中文1`）；
表达式里出现标识符会抛 `Object does not respond to 'l'`（它把 `list` 的 `l` 当成了什么东西）；
表达式里带括号则直接**段错误**——`"中文#{(1 + 2)}"` 那个字面量只要被求值就挂，rc=139，没有任何输出。
所以示例里那条只以注释形式存在，绝不真跑。

> **为什么重要**：`interpolate` 在非 ASCII 上是**未定义行为**，不是「有时不准」而是「会崩」。
> 中文文案里的值一律用 `..` 拼或多参数 `writeln`，这是全教程的硬规矩。

## 16.4 切分：split 保留空段，splitNoEmpties 不保留

```text
-- 16.4 切分：split 保留空段，splitNoEmpties 不保留
"a,b,,c" split(",") 的元素数 = 4
内容（空段被保留） = list("a", "b", "", "c")
splitNoEmpties(",") 的元素数 = 3
内容 = list("a", "b", "c")
"a b  c" split（按空白切，空段照留） = list("a", "b", "", "c")
它的元素数 = 4
splitNoEmpties 的元素数 = 3
按换行切 = list("l1", "l2", "l3")
"上" 的码位与低字节 = list(19978, 10)
"上" split（低字节 0x0A 被当成换行） = list("")
"ab上cd" split（在 上 中间被切开） = list("ab", "cd")
"字段不够" split（不 的低字节是 0x0D） = list("字段", "够")
"上" split(" ")（显式给分隔符就没事） = list("上")
```

```io
"a,b,,c" split(",")          // list("a", "b", "", "c")  —— 两个逗号中间留一个空段
"a,b,,c" splitNoEmpties(",") // list("a", "b", "c")
"a b  c" split               // list("a", "b", "", "c")  —— 不传分隔符按空白切，空段照留
"a b  c" splitNoEmpties      // list("a", "b", "c")
"l1\nl2\nl3" split("\n")     // list("l1", "l2", "l3")
"上" split                   // list("")      ← 灾难
"上" split(" ")              // list("上")    ← 显式给分隔符就正常
```

注意 `"a b  c"`（两个空格）`split` 出来是 **4** 段，不是 3 段——这是最容易少算的地方。

**但这一节真正的雷在下面那三行。** 不传分隔符时 `split` 是按**字节**扫空白的，
不是按码点：只要某个码位的低位字节落在 `\t`、`\n`、`\v`、`\f`、`\r` 或空格里，
它就会被当成一个分隔符切开。

`上` 是 U+4E0A，低位字节正好是 `0x0A`（换行），所以单独一个 `"上"` 切出来是
`list("")`；`"ab上cd"` 被从 `上` 中间劈成两段；`"字段不够"` 里 `不` 是 U+4E0D、
低位字节 `0x0D`（回车），于是切成 `list("字段", "够")`。
换成 `"你好"`（U+4F60 / U+597D）就一点事没有——**所以这个坑是间歇性出现的**，
输入换一批字就复现不了，特别难查。

> **为什么重要**：这是「Io 标准库在非 ASCII 上按字节干活」这一家族里最隐蔽的一种
> （同族的还有 `interpolate`）。**处理外部文本时，`split` 一律显式写分隔符**
> ——`split(" ")`、`split(",")`、`split("\n")` 都安全，只有光秃秃的 `split` 会踩雷。
> 同样的雷也在 `splitNoEmpties` 上：`"上" splitNoEmpties` 得到空表。

## 16.5 查找与替换

```text
-- 16.5 查找与替换
findSeq("a") 给第一个下标 = 1
reverseFindSeq("a") 给最后一个（没有 findLastSeq） = 5
Sequence 有 findLastSeq 吗（没有） = false
找不到给 nil = true
occurrencesOfSeq("a") = 3
containsSeq("nan") = true
beginsWithSeq("ban") = true
endsWithSeq("na") = true
Sequence 有 replaceSeqInPlace 吗（没有，replaceSeq 本身就是就地） = false
对字面量调 replaceSeq 抛异常 = true
异常消息原文 = 'replaceSeq' cannot be called on an immutable Sequence
asMutable 之后再 replaceSeq = bonono
replaceFirstSeq 只换第一个 = bonana
```

```io
w := "banana"
w findSeq("a")          // 1（找不到给 nil）
w reverseFindSeq("a")   // 5 —— Io 没有 findLastSeq
w occurrencesOfSeq("a") // 3
w containsSeq("nan")    // true
w beginsWithSeq("ban")  // true
w endsWithSeq("na")     // true

"banana" asMutable replaceSeq("a", "o")       // "bonono"（就地）
"banana" asMutable replaceFirstSeq("a", "o")  // "bonana"
```

名字对不上是这一节的重点：**没有 `findLastSeq`**（用 `reverseFindSeq`），
**也没有 `replaceSeqInPlace`**——`replaceSeq` 本身就是就地的，所以字面量上直接调会抛异常。

> **为什么重要**：Io 的 API 命名在「就地 vs 新建」上不统一（`replaceSeq` 就地、`asUppercase` 新建），
> 猜名字一定会踩；遇到想当然的方法先 `Sequence hasSlot("名字")` 问一句。

## 16.6 切片、大小写、对齐

```text
-- 16.6 切片、大小写、对齐
exSlice(1, 3)（左闭右开） = bc
exSlice(0, -1) = abcde
exSlice(-3, -1) = de
exSlice(2, 2) 是空串 = []
asUppercase（非就地） = ABC
asLowercase = abc
中文不受大小写影响 = 中文ABC
reverse（按码点整体反转） = cba
中文也一起反转 = cba文中
strip 家族：strip / lstrip / rstrip（没有 stripLeft/stripRight） = false
strip = [ab]
lstrip = [ab  ]
rstrip = [  ab]
alignLeft(5) = [ab   ]
alignRight(5) = [   ab]
alignCenter(6) = [  ab  ]
asCapitalized = Hello world
```

```io
"abcdef" exSlice(1, 3)     // "bc"    —— 左闭右开
"abcdef" exSlice(0, -1)    // "abcde" —— 负索引从尾巴数
"abcdef" exSlice(-3, -1)   // "de"

"AbC" asUppercase          // "ABC"（新建，不改原串）
"中文abc" asUppercase      // "中文ABC" —— 中文没有大小写，原样保留
"中文abc" reverse          // "cba文中" —— 按码点整体反转

"  ab  " asMutable strip   // "ab"（就地）
"  ab  " asMutable lstrip  // "ab  "
"  ab  " asMutable rstrip  // "  ab"
"ab" alignLeft(5)          // "ab   "
"ab" alignRight(5)         // "   ab"
"ab" alignCenter(6)        // "  ab  "
"hello world" asCapitalized // "Hello world"
```

两个名字上的坑：去空白叫 `strip` / `lstrip` / `rstrip`（**没有** `stripLeft`/`stripRight`），
大小写转换要 `asUppercase` / `asLowercase`（裸的 `uppercase` 是就地版本）。
`slice` 已经废弃会打 `deprecatedWarning`，一律用 `exSlice`。

> **为什么重要**：`exSlice` 的左闭右开和负索引跟 Python 一样，但 `slice` 那个废弃别名会往
> stdout 打一行带脚本路径的警告——又一个「输出被环境细节污染」的典型，所以示例里只用 `exSlice`。

## 16.7 与 List / Number 互转

```text
-- 16.7 与 List / Number 互转
asList = list("a", "b", "c")
asList 的类型 = List
List asString = list(1, 2, 3)
List join("-") = a-b-c
字符串 asNumber = 42
带 0x 前缀也认 = 16
Number asString = 42
小数 asString = 3.5
中文 asNumber 给 nan，不抛异常 = nan
```

```io
"abc" asList              // list("a", "b", "c")
list(1, 2, 3) asString    // "list(1, 2, 3)"
list("a", "b") join("-")  // "a-b-c"
"42" asNumber             // 42
"0x10" asNumber           // 16
42 asString               // "42"
"中文" asNumber           // nan —— 不抛异常，给一个 nan
```

`asList` 拿到的是真正的 `List`，之后就能用第 09/12 章那套 `map`/`select`/`join`。
反方向 `List asString` 会带上 `list(...)` 外壳，想要干净文本用 `join(sep)`。

> **为什么重要**：文本 ↔ 容器的边界要清楚：`asList` 是**元素级**切分（不是按分隔符），
> 按分隔符切要用 `split`。两者结果都是 List，但语义完全不同。

## 16.8 中文的排序与比较

```text
-- 16.8 中文的排序与比较
sort 之后的顺序 = list("1", "A", "b", "中", "啊")
逐个看它们的码点 = list(49, 65, 98, 20013, 21834)
"中" > "啊" = false
结论：按 Unicode 码点排，不是拼音 = true
```

```io
words := list("中", "啊", "b", "A", "1") sort
// list("1", "A", "b", "中", "啊") —— 就是码点从小到大
words map(c, c at(0))    // list(49, 65, 98, 20013, 21834)
"中" > "啊"              // false：0x4E2D < 0x554A
```

别猜「中文按拼音排」——实测就是**按 Unicode 码点**排：`1`(49) < `A`(65) < `b`(98) < `中`(20013) < `啊`(21834)。
`"中" > "啊"` 也是 `false`，跟排序结果自洽。

> **为什么重要**：需要拼音序 / 笔画序就得自己建映射表或做一次显式重排，
> 不能指望语言默认的字符串比较。跨语言教程里这一点经常被写成「按本地排序规则」，在 Io 里不是。

## 16.9 坑位清单

1. **字面量不可变** → `strip`/`lstrip`/`rstrip`/`replaceSeq`/`uppercase`/`escape` 都是就地方法，抛 `'xxx' cannot be called on an immutable Sequence`，先 `asMutable`。
2. **没有 `asImmutable`，也没有 `findLastSeq` / `replaceSeqInPlace`** → 反向查找用 `reverseFindSeq`，替换直接用 `replaceSeq`（它本身就就地）。
3. **编码按内容自动升级，跨宽度比较会静默出错** → 纯 ASCII 是 `uint8`、含中文是 `uint32`；`size` 数码点、`sizeInBytes` 数字节、`asUTF8 size` 才是 UTF-8 字节数。**两种宽度的序列做 `containsSeq`/`==` 不报错，只给错答案**（详见 16.2 末段与第 15 章 15.6.1）。
4. **`at(i)` 给的是码点 Number** → `20013` 而不是字符，要 `asCharacter`；对 `asUTF8` 的结果取下标拿到的才是一个字节。
5. **`interpolate` 在非 ASCII 前缀上丢尾巴** → `"中文#{1 + 2}"` 得到 `中文1`、长度只有 3，中文文案改用 `..` 拼接或纯 ASCII 模板。
6. **`interpolate` 表达式带括号 + 非 ASCII 前缀直接段错误** → `"中文#{(1 + 2)}"` 是 rc=139 且无任何输出，永远不要在中文串上用 `#{}`。
7. **`interpolate` 表达式里出现标识符** → `#{list(1,2) size}` 报 `Object does not respond to 'l'`，只能放最简表达式。
8. **不传分隔符的 `split`** → 按**字节**扫空白，码位低字节是 `0x0A`/`0x0D`/`0x20` 的汉字会被劈开（`"上" split` 得 `list("")`）；外部文本一律用 `split(" ")` 这样的显式分隔符。顺带：`split` 保留空段（`"a,b,,c"` 给 4 段），不想要空段就 `splitNoEmpties`。
9. **去空白 / 大小写的名字不是想当然的那些** → 用 `strip`/`lstrip`/`rstrip`、`asUppercase`/`asLowercase`，没有 `stripLeft`/`stripRight`/`upper`/`lower`。
10. **中文比较与排序按 Unicode 码点** → `"中" > "啊"` 为 false，要拼音序只能自己建映射表。

---

上一章：[15 · 系统、进程与环境](15-system.md) · 下一章：[17 · 元编程与反射](17-meta.md)
