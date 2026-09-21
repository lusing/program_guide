# 04 · 序列：字节串、码点串与不可变字面量

> 对应示例：[`examples/04_sequences/04_sequences.io`](../examples/04_sequences/04_sequences.io)

一条主线贯穿全章：**`Sequence` 是可变容器，字符串字面量是它的不可变特例**，
所有「就地修改」的方法都只认可变序列。围绕这条线还要回答三个具体问题：
「长度」到底在数什么（码点还是字节）、编码为什么会自己升级、
以及为什么 `interpolate` 一遇到中文就会错位。

章节末尾那个 `自检` 小节是示例的回归脚手架（它把本章的结论汇总成断言，跑完打印 `自检：全部通过`），属于逐字节比对的一部分，这里不重复。

## 4.1 不可变字面量：type 都是 Sequence，不可变是个对象标志

```text
-- 4.1 不可变字面量：type 都是 Sequence，不可变是个对象标志
"abc" type = Sequence
Sequence clone type = Sequence
"abc" asMutable type = Sequence
"abc" isMutable = false
"abc" asMutable isMutable = true
String isIdenticalTo(ImmutableSequence) = true
ImmutableSequence slotNames = list("type")
"abc" isKindOf(ImmutableSequence) = false
try("  pad  " strip) 的异常类型 = Exception
异常消息 = 'strip' cannot be called on an immutable Sequence
"  pad  " asMutable strip = pad
```

```io
show("\"abc\" type", "abc" type)
show("Sequence clone type", Sequence clone type)
show("\"abc\" asMutable type", "abc" asMutable type)
show("\"abc\" isMutable", "abc" isMutable)
show("\"abc\" asMutable isMutable", "abc" asMutable isMutable)
show("String isIdenticalTo(ImmutableSequence)", String isIdenticalTo(ImmutableSequence))
show("ImmutableSequence slotNames", ImmutableSequence slotNames sort)
show("\"abc\" isKindOf(ImmutableSequence)", "abc" isKindOf(ImmutableSequence))
e := try("  pad  " strip)
show("try(\"  pad  \" strip) 的异常类型", e type)
show("异常消息", e error)
chk("type 区分不出可变性", "abc" type asString, (Sequence clone) type asString)
chk("不可变是挂在对象上的标志", "abc" isMutable, false)
chk("asMutable 给的是同一个 proto 上的可变副本", "abc" asMutable isMutable, true)
chk("ImmutableSequence 是个空壳 proto", ImmutableSequence slotNames sort asString, "list(\"type\")")
chk("就地方法拒绝不可变串", e error, "'strip' cannot be called on an immutable Sequence")
show("\"  pad  \" asMutable strip", "  pad  " asMutable strip)
```

结论要分三层看，**别指望用 `type` 把可变性问出来**：

- 字面量、`Sequence clone`、`asMutable` 三者的 `type` **完全一样**，都是 `Sequence`。
  可变性不是类型，而是**挂在对象上的一个标志**：`isMutable` 才是唯一的权威判据。
- **`String` 是 `ImmutableSequence` 的别名**（`list("type")` 说明这个原型几乎是个空壳），
  它和字面量**没有** proto 关系——`"abc" isKindOf(ImmutableSequence)` 是 `false`。
  想用 `isKindOf` 区分「字符串字面量」会一直失败。
- 因此准确的说法是「字面量是一个**不可变的** `Sequence`」。凡是就地方法
  （`strip`、`replaceSeq`、`appendSeq`…）落到它身上，就抛
  `'strip' cannot be called on an immutable Sequence`；要改就先 `asMutable`
  或在 `Sequence clone` 上做（最后一行输出）。

> **为什么重要**：Io 把「值语义的字符串」实现成「被冻住的容器」，而不是另立一个类型。
> 所以字符串方法与序列方法**是同一套**——学会了 `Sequence` 就学会了字符串，
> 反过来说：任何 `Sequence` 方法写坏了，也会以字符串错误的形式爆出来。
> 判断能不能就地改，永远问 `isMutable`，不要问 `type`。

## 4.2 size 数的是码点，sizeInBytes 才是字节

```text
-- 4.2 size 数的是码点，sizeInBytes 才是字节
a size / sizeInBytes / encoding = list(5, 5, "ascii")
b size / sizeInBytes / encoding = list(5, 10, "ucs2")
c size / sizeInBytes / encoding = list(2, 8, "ucs4")
c asUTF8 size = 6
```

```io
a := "hello"
b := "héllo"
c := "你好"
show("a size / sizeInBytes / encoding", list(a size, a sizeInBytes, a encoding) asString)
show("b size / sizeInBytes / encoding", list(b size, b sizeInBytes, b encoding) asString)
show("c size / sizeInBytes / encoding", list(c size, c sizeInBytes, c encoding) asString)
show("c asUTF8 size", c asUTF8 size)
chk("纯 ASCII 一字节一码点", a sizeInBytes, a size)
chk("带重音字母升到 ucs2", b itemType, "uint16")
chk("汉字升到 ucs4", c itemType, "uint32")
chk("UTF-8 下汉字 3 字节", c asUTF8 size, 6)
```

结论：**编码按内容自动升级**，字面量自己选最省的那一档：

| 串 | `encoding` | `itemType` | `size`（码点） | `sizeInBytes`（内部） |
|---|---|---|---|---|
| `"hello"` | `ascii` | `uint8` | 5 | 5 |
| `"héllo"` | `ucs2` | `uint16` | 5 | 10 |
| `"你好"` | `ucs4` | `uint32` | 2 | 8 |

三个「长度」的语义完全不同，必须分清：

- `size`：**码点数**（`"你好"` 是 2）——切片、判等、索引都用这个口径。
- `sizeInBytes`：**内部表示**的字节数（`"你好"` 是 8，每码点 4 字节）。
- `asUTF8 size`：真正落盘/发给别的程序时的 UTF-8 字节数（`"你好"` 是 6）。

升级只升不降：往 `"你好"` 上 `appendSeq("a")`，整个容器仍然是 `ucs4`。

> **为什么重要**：`sizeInBytes` 是「内存里多大」，不是「文件里多大」。写文件、
> 算协议长度、跟外部程序对话，一律用 `asUTF8 size`；`sizeInBytes` 只在关心
> 内存布局或做底层拷贝时才有意义。

## 4.3 at 给码点，asCharacter 才给字符

```text
-- 4.3 at 给码点，asCharacter 才给字符
"Hello" at(1) = 101
"Hello" at(1) asCharacter = e
"你好" at(0) = 20320
65 asCharacter = A
"A" at(0) = 65
```

```io
show("\"Hello\" at(1)", "Hello" at(1))
show("\"Hello\" at(1) asCharacter", "Hello" at(1) asCharacter)
show("\"你好\" at(0)", "你好" at(0))
show("65 asCharacter", 65 asCharacter)
show("\"A\" at(0)", "A" at(0))
chk("ASCII 下码点就是字节值", "A" at(0), 65)
chk("汉字给的是 Unicode 码位", "你好" at(0), 20320)
```

结论：`at(i)` 返回的是**码点数值**，不是字符。ASCII 下码点恰好等于字节值
（`"A" at(0)` = `65`），所以这个区别容易被 ASCII 掩盖；一旦是汉字就会露出真面目
（`"你好" at(0)` = `20320`）。要一个能打印、能拼接的字符，得再 `asCharacter`。
反向的 `65 asCharacter` 给 `A`。

> **为什么重要**：索引访问返回数字、字符串比较却按码点——这套设计让
> 「遍历字符串」变成「遍历码点序列」。凡是要对文本做逐字符处理，
> 先决定你要的是码点还是字符，再决定加不加 `asCharacter`。

## 4.4 切片 exSlice：左闭右开，支持负索引

```text
-- 4.4 切片 exSlice：左闭右开，支持负索引
s exSlice(1, 3) = bc
s exSlice(1) = bcdef
s exSlice(-2) = ef
s exSlice(0, -1) = abcde
s exSlice(2, 4) == s at(2)..at(3) = true
```

```io
s := "abcdef"
show("s exSlice(1, 3)", s exSlice(1, 3))
show("s exSlice(1)", s exSlice(1))
show("s exSlice(-2)", s exSlice(-2))
show("s exSlice(0, -1)", s exSlice(0, -1))
show("s exSlice(2, 4) == s at(2)..at(3)", s exSlice(2, 4) == (s at(2) asCharacter .. s at(3) asCharacter))
chk("exSlice 左闭右开", s exSlice(1, 3), "bc")
chk("负索引从尾部算", s exSlice(-2), "ef")
```

结论：`exSlice(start, end)` **左闭右开**：`exSlice(1, 3)` 给 `bc`，不含下标 3。
省略 `end` 就切到末尾（`exSlice(1)` 给 `bcdef`）。**负索引从尾部算**：
`exSlice(-2)` 给最后两个字符 `ef`，`exSlice(0, -1)` 给 `abcde`（-1 指向最后一个字符，
但它是右开边界，所以不包含）。

`slice` 是它的旧名，调用会往 **stdout** 打一行
`Warning in <脚本名>: 'slice' is deprecated.  Use 'exSlice' instead.`——
在别的项目里无害，在本教程里是致命的：这行会污染判定区间。

> **为什么重要**：区间端点是「闭还是开」是切片 API 的头号混乱源。`exSlice` 统一成
> 左闭右开，正好与 `size` 的口径配套：`exSlice(0, s size)` 就是整串。

## 4.5 就地方法的正确姿势：先 asMutable 或 clone

```text
-- 4.5 就地方法的正确姿势：先 asMutable 或 clone
asMutable + appendSeq = abcdef
原字面量不受影响 = abc
Sequence clone 也是可变序列 = pad
n size = 3
```

```io
m := "abc" asMutable
m appendSeq("def")
show("asMutable + appendSeq", m)
show("原字面量不受影响", "abc")
n := Sequence clone appendSeq("  pad  ")
n strip
show("Sequence clone 也是可变序列", n)
show("n size", n size)
chk("asMutable 返回可变副本", ("abc" asMutable isMutable), true)
chk("字面量本身不可变", ("abc" isMutable), false)
```

结论：想做就地修改，有两条等价的路：

- `"abc" asMutable`：把不可变串**复制**成可变序列，原字面量不动（第 2 行仍是 `abc`）。
- `Sequence clone`：从一个空的 `Sequence` 原型开始自己拼（`Sequence clone appendSeq(...)`）。

有了可变序列，`appendSeq`、`strip`、`replaceSeq` 这些方法才生效；
它们通常**返回自己**，所以可以继续接方法调用（第 1 行就是链式写法）。

> **为什么重要**：「就地方法只认可变序列」这条规则同时解决两个问题：
> 字符串字面量天然可以安全共享（不可变 = 不会被别人改），而需要累积拼接的
> 场景又有可变容器可用。代价是你必须显式选择——Io 不会替你复制。

## 4.6 切分与拼接

```text
-- 4.6 切分与拼接
split(",") = list("a", "b", "", "c")
splitNoEmpties(",") = list("a", "b", "c")
"a b  c" split = list("a", "b", "", "c")
list 的 join = 1-2-3
"1,2".asList = list("1", "2")
两段拼接用 .. = abcdef
.. 的右侧会被 asString = n=7
```

```io
csvLine := "a,b,,c"
show("split(\",\")", csvLine split(","))
show("splitNoEmpties(\",\")", csvLine splitNoEmpties(","))
show("\"a b  c\" split", "a b  c" split)
show("list 的 join", list(1, 2, 3) join("-"))
show("\"1,2\".asList", "1,2" split(","))
show("两段拼接用 ..", "abc" .. "def")
show(".. 的右侧会被 asString", "n=" .. 7)
chk("split 保留空段", csvLine split(",") size, 4)
chk("splitNoEmpties 去掉空段", csvLine splitNoEmpties(",") size, 3)
chk("不传分隔符按空白切，但空段照留", "a b  c" split size, 4)
chk("split() 与 splitNoEmpties() 的差别就在空段", "a b  c" splitNoEmpties size, 3)
```

结论：切分有两个孪生方法，差别只在**空段**：

- `split(sep)`：**保留**空段。`"a,b,,c" split(",")` 给 `list("a", "b", "", "c")`，长度 4。
- `splitNoEmpties(sep)`：丢掉空段，长度 3。
- 不传分隔符时按**空白**切，但空段照留：`"a b  c" split` 长度是 4（连着两个空格
  会产生一个空段）。

拼接用 `..`，它会把右侧 `asString` 后接上（`"n=" .. 7` 得 `n=7`），所以 `..` 对
普通对象会调出「槽位摘要 + 地址」（见 [6.9](06-messages.md)）。`List` 侧的对应物是
`join(sep)`。

> **为什么重要**：CSV 解析的头号 bug 就是空字段被吃掉。Io 要求你显式选
> `split` 还是 `splitNoEmpties`——这个选择本身就是「空字段有没有意义」的文档。

## 4.7 查找、替换、大小写、对齐

```text
-- 4.7 查找、替换、大小写、对齐
findSeq("Io") = 7
findSeq("zz") = nil
occurrencesOfSeq("o") = 2
beginsWithSeq("Hello") = true
endsWithSeq("Io") = true
containsSeq("lo,") = true
asUppercase = HELLO, IO
asLowercase = hello, io
repeated(2) = abab
alignRight(8, ".") = ......ab
alignLeft(8, ".") = ab......
replaceSeq 需要可变串 = a+b+c
```

```io
t := "Hello, Io"
show("findSeq(\"Io\")", t findSeq("Io"))
show("findSeq(\"zz\")", t findSeq("zz"))
show("occurrencesOfSeq(\"o\")", t occurrencesOfSeq("o"))
show("beginsWithSeq(\"Hello\")", t beginsWithSeq("Hello"))
show("endsWithSeq(\"Io\")", t endsWithSeq("Io"))
show("containsSeq(\"lo,\")", t containsSeq("lo,"))
show("asUppercase", t asUppercase)
show("asLowercase", t asLowercase)
show("repeated(2)", "ab" repeated(2))
show("alignRight(8, \".\")", "ab" alignRight(8, "."))
show("alignLeft(8, \".\")", "ab" alignLeft(8, "."))
show("replaceSeq 需要可变串", "a-b-c" asMutable replaceSeq("-", "+"))
chk("找不到返回 nil", t findSeq("zz"), nil)
chk("replaceSeq 返回可变串自己", "a-b-c" asMutable replaceSeq("-", "+"), "a+b+c")
```

结论：这一族方法的命名都带 `Seq` 后缀（`findSeq` / `occurrencesOfSeq` /
`beginsWithSeq` / `endsWithSeq` / `containsSeq`），因为同一批操作在别的类型上
也有实现（列表、映射），后缀区分**按序列语义**操作。

- 查找类：`findSeq` 给**下标**（`"Hello, Io"` 里 `Io` 在下标 7），找不到给 `nil`
  （不是 -1，也不是异常）；`occurrencesOfSeq` 给出现次数。
- 变换类：`asUppercase` / `asLowercase` / `repeated(n)` / `alignRight(width, pad)` /
  `alignLeft(width, pad)` 都**返回新串**；只有 `replaceSeq` 是就地方法，
  所以必须 `asMutable` 之后调，且返回的是那个可变串自己。
- `alignRight(8, ".")` 用 `.` 补到宽度 8；做表格输出时比手算空格省事。

> **为什么重要**：`findSeq` 找不到给 `nil` 而不是 `-1`，与 C 系语言的直觉相反。
> 好处是 `if(x findSeq(...), ...)` 可以直接拿来找「不存在」（`nil` 是假值）；
> 坏处是把返回值当下标用时忘了判空会得到 `nil` 参与的运算。

## 4.8 陷阱：interpolate 只对纯 ASCII 安全

```text
-- 4.8 陷阱：interpolate 只对纯 ASCII 安全
"1 + 2 = #{1 + 2}" interpolate = 1 + 2 = 3
中文文案改用多参数：值 = 3
中文文案改用 ..：值 = 3
```

```io
show("\"1 + 2 = #{1 + 2}\" interpolate", "1 + 2 = #{1 + 2}" interpolate)
writeln("中文文案改用多参数：", "值 = ", 1 + 2)
writeln("中文文案改用 ..：", "值 = " .. (1 + 2) asString)
chk("多参数形式可以安全带中文", "值 = " .. 3 asString, "值 = 3")
```

纯 ASCII 串上插值完全正常（第 1 行）。但只要串里有非 ASCII 字节，
本构建的 `#{}` 定位就会错位——示例里那三行**故意被注释掉**，因为它们会以三种
不同的方式破坏示例的判定：把结果改错、把脚本打断、或把进程带走。

单独跑（不在示例的判定区间内）实测如下：

```text
"中文#{1 + 2}" interpolate            → 中文1                 （丢了 " + 2"，退出码 0）
"中文#{list(1,2) size}" interpolate   → Object does not respond to 'l'（chunk 被截成 l）
"中文#{(1 + 2)}" interpolate          → 段错误，退出码 139，无任何输出
```

- 第一种：插值区被**按字节**截断，`1 + 2` 只剩 `1`，于是安静地给出错的结果——
  最危险的一种，因为它不报错。
- 第二种：chunk 被截成 `l`，抛未捕获异常。Io 的未捕获异常**打到 stdout 并中断脚本，
  退出码仍然是 0**，属于典型的假阳性（本仓库的 `run-all.sh` 专门防这个）。
- 第三种：直接段错误，进程连结束标记都打不出来，整个判定区间丢失。

所以第三条注释里写着「第三句会直接段错误，把整个进程带走」——**注释不是保守，
是必须**。中文文案一律改用 `writeln` 的多参数形式或 `..` 拼接（第 2、3 行输出）。

> **为什么重要**：这条缺陷的形态是「按字节数下标，遇上变宽编码就错位」。
> 它同时解释了 4.2 为什么要把 `size` 与 `sizeInBytes` 分开：谁混用口径，谁就会写出
> 这类 bug。带中文的输出，永远不要用 `interpolate`。

## 4.9 坑位清单

1. **在字面量上调 `strip` / `replaceSeq` / `appendSeq`** → 抛 `cannot be called on an immutable Sequence`，先 `asMutable` 或 `Sequence clone`。
2. **以为字面量的 proto 是 `ImmutableSequence`** → 它的 `type` 就是 `Sequence`，只读是因为带不可变标志（问 `isMutable`，别问 `type`），`isKindOf(ImmutableSequence)` 为 false。
3. **把 `size` 当字节数** → `size` 数码点，内部字节看 `sizeInBytes`，UTF-8 字节看 `asUTF8 size`。
4. **用 `sizeInBytes` 算文件长度** → 含中文时它是「每码点 4 字节」，写文件要用 `asUTF8 size`。
5. **`at(i)` 当字符用** → 它给的是码点数值，要字符得再 `asCharacter`。
6. **把 `exSlice` 的右边界当闭区间** → 它是左闭右开，`exSlice(0, s size)` 才是整串。
7. **调用旧名 `slice`** → 会往 stdout 打废弃警告污染判定区间，改用 `exSlice`。
8. **用 `split` 解析 CSV 后抱怨多出空字段** → `split` 保留空段，去空段要用 `splitNoEmpties`。
9. **以为 `findSeq` 找不到时给 -1** → 它给 `nil`，当下标用之前先判空。
10. **对含中文的文案用 `interpolate`** → 会错位、抛异常甚至段错误，改用 `writeln` 多参数或 `..`。

---

上一章：[03 · 数字：只有一种 Number](03-numbers.md) · 下一章：[05 · 控制流：没有 if，只有消息](05-control.md)
