# 02 · 第一行输出与最小心智模型

> 对应示例：[`examples/02_hello/02_hello.io`](../examples/02_hello/02_hello.io)

这一章不铺语法体系，只把「第一分钟」要用的四件事钉死：输出怎么发、字符串字面量是什么、
脚本怎么知道自己的身份、文本与字节的边界在哪。Io 的怪异几乎全部从这里长出来——
**没有语句，只有消息**；`writeln(1, 2)` 与 `42 println` 看着像一对孪生兄弟，
其实一条走原语、一条走消息，参数还被丢了一个。

本章所有引用块都是「会反复用到、值得背下来」的规则；所有输出都是从示例 stdout 的判定
区间里原样剪下来的。

章节末尾那个 `自检` 小节是示例的回归脚手架（它把本章的结论汇总成断言，跑完打印 `自检：全部通过`），属于逐字节比对的一部分，这里不重复。

## 2.1 两个输出原语：writeln(x) 与 x println

先把两族输出的行为一次看全：

```text
-- 2.1 两个输出原语：writeln(x) 与 x println
writeln 写参数，可多个：1 + 2 = 3
write 不换行|write 第二段|
42
print 不换行|print 同一行续上
writeln 自带换行
x
```

代码：

```io
writeln("writeln 写参数，可多个：", 1, " + ", 2, " = ", 1 + 2)
write("write 不换行|")
write("write 第二段|")
writeln("")
42 println
"print 不换行|" print
"print 同一行续上" println
writeln("writeln 自带换行")
chk("println 返回接收者", ("x" println), "x")
```

结论：**两族输出的分工是「写参数」还是「写接收者」**。

- `writeln` / `write` 是**原语**（`CFunction`）。它们吃**参数**：可以一次给任意多个值，
  Io 把每个值各自 `asString` 后首尾拼接；`write` 不加换行，`writeln` 结尾加一个。
  返回值为 `nil`。
- `print` / `println` 是**消息**（`Object` 上的方法），写在**接收者**上。`42 println`
  打印 `42`；返回值是**接收者本身**——所以 `("x" println)` 既可以打印又能当值传给别人，
  实测输出里那个孤零零的 `x` 就是它干的副作用，`chk` 只是顺手调了一次。

注意最后一行 `x` 的位置：它出现在 `writeln 自带换行` 之后，因为
`chk("println 返回接收者", ("x" println), "x")` 的参数求值发生在断言之前。

> **为什么重要**：这两族的返回值不一样——`writeln` 给 `nil`，`println` 给接收者。
> 「要拼多个值」用 `writeln(...)`，「只打一个值」用 `x println`；把两者混写成
> `println(多个值)` 就是 2.2 的坑。

## 2.2 陷阱：println(x) 里的 x 是装饰品

```text
-- 2.2 陷阱：println(x) 里的 x 是装饰品
「被打印的是接收者」
「被打印的是接收者」
42
42
```

```io
probe := Object clone do(asString := "「被打印的是接收者」")
probe println(42)
chk("println 忽略参数", (probe println(42)), probe)
writeln(42)
42 println
```

`Object println` 的职责只有三件事：打印 `self`、写一个换行、返回 `self`。
它**一个参数都不读**。`probe println(42)` 里的 `42` 被求值之后没人接收，静默消失；
输出第 1 行与第 2 行一模一样，是因为断言里的 `(probe println(42))` **又调了一次**，
副作用照跑，而断言通过只是因为返回值确实是 `probe` 自己。

要真打印 42 只有两条正路，就是最后两行输出：`writeln(42)`（写参数）或 `42 println`
（把 42 当接收者）。

> **为什么重要**：Io 的消息协议**没有签名校验**：多给的实参没人管、不给的形参拿 `nil`
> 顶上。所以「写错了不报错、只是结果不对」是常态。凡输出不对，先数一数实参到底被谁吃了。

## 2.3 字符串字面量与显式插值

```text
-- 2.3 字符串字面量与显式插值
hello #{name}
hello Io
1 + 2 = 3
((1 + 2) * 3) = 9
第一行
第二行 #{name}
```

```io
name := "Io"
writeln("hello #{name}")
writeln("hello #{name}" interpolate)
writeln("1 + 2 = #{1 + 2}" interpolate)
writeln("((1 + 2) * 3) = #{(1 + 2) * 3}" interpolate)
chk("插值区里可以有括号（但整串必须是纯 ASCII）", "((1 + 2) * 3) = #{(1 + 2) * 3}" interpolate, "((1 + 2) * 3) = 9")
multi := """第一行
第二行 #{name}"""
writeln(multi)
chk("三引号串不插值", multi size, 15)
```

结论：**Io 不做隐式插值**。`#{...}` 只是一段普通文本，直到你显式调用 `interpolate`，
Io 才会把 `#{}` 里的内容当成一条消息去求值再替换。所以第 1 行原样打印 `#{name}`，
第 2 行才是 `hello Io`。插值区里可以放算式，也可以放带括号的算式（第 4 行）。

三引号是**多行字面量**，不是「会插值的模板」：`multi` 里的 `#{name}` 同样保持原样，
它的 `size` 是 15（3 + 1 + 4 + 7 个码点，注意 `第二行` 是非 ASCII）。

> **为什么重要**：`interpolate` 是方法，所以在非 ASCII 串上它**会坏**（错位甚至段错误，
> 见 [4.8](04-sequences.md)）。写日志、拼中文文案时用 `writeln` 的多参数形式或 `..`
> 拼接；`interpolate` 只留给纯 ASCII 的模板串。

## 2.4 转义与看不见的字符

```text
-- 2.4 转义与看不见的字符
tab:[	]
引号："x"，反斜杠：\
换行：
（上一行到此结束）
本构建没有 \xNN 转义：x41
```

```io
writeln("tab:[", "\t", "]")
writeln("引号：\"x\"，反斜杠：\\")
writeln("换行：\n（上一行到此结束）")
writeln("本构建没有 \\xNN 转义：", "\x41")
chk("\\x41 不是字节转义", "\x41", "x41")
```

结论：反斜杠转义表很薄：`\t` 是制表符（输出第 1 行方括号里就是一个真的 TAB，
所以对不齐是正常的）、`\"` 是引号、`\\` 是反斜杠、`\n` 是换行。
**没有 `\xNN` 这种十六进制字节转义**：`"\x41"` 被吃掉的只有反斜杠，留在串里的是 `x41`，
而不是 `A`。

> **为什么重要**：这条限制决定了「二进制字面量」不能直接写在源码里。要造非文本字节，
> 得先 `asMutable`，再用 `Sequence` 的逐字节手法去拼（见 [4.5](04-sequences.md)）。

## 2.5 注释与语句分隔

```text
-- 2.5 注释与语句分隔
分号压行：a + b = 3
```

```io
/* 块注释，可以跨行 */
// 行注释
a := 1; b := 2; writeln("分号压行：a + b = ", a + b)
chk("语句分隔不是逗号", a + b, 3)
```

结论：注释两种（`//` 到行尾、`/* ... */` 可跨行）；**语句之间用分号或换行**。

这条看似废话，其实是 Io 最容易踩的语法分野：**逗号是「参数分隔符」，不是「语句分隔符」**。
`s := "abc" asMutable` 里没有逗号什么事；但写成 `do(a := 1, b := 2)` 时，逗号会把
第二个赋值变成「第二个实参」，而多出来的实参会被静默丢掉（[7.9](07-prototypes.md)）。
方法体里的最后一条语句就是返回值，分号写作 `method(a, b, x := a + b; x * 2)`
与换行写作完全等价（[8.10](08-methods.md)）。

> **为什么重要**：把 `;` 和 `,` 的分工背下来，能一次消掉本教程里至少五处「看着没错、
> 结果少东西」的 bug。

## 2.6 中文字面量：size 数的是字符，不是字节

```text
-- 2.6 中文字面量：size 数的是字符，不是字节
「你好」size = 2，sizeInBytes = 8，encoding = ucs4，itemType = uint32
第一个码点：20320（就是「你」的 Unicode 码位）
```

```io
s := "你好"
writeln("「你好」size = ", s size, "，sizeInBytes = ", s sizeInBytes,
        "，encoding = ", s encoding, "，itemType = ", s itemType)
chk("UCS4 字面量按码点计数", s size, 2)
chk("UCS4 下每码点 4 字节", s sizeInBytes, 8)
chk("转 UTF-8 才是 6 字节", s asUTF8 size, 6)
chk("纯 ASCII 字面量是 1 字节/字符", "hello" sizeInBytes, 5)
writeln("第一个码点：", s at(0), "（就是「你」的 Unicode 码位）")
```

结论：字符串字面量内部是**码点序列**，而且**编码按内容自动升级**：

| 内容 | `encoding` | `itemType` | 每码点字节数 | `sizeInBytes` |
|---|---|---|---|---|
| 纯 ASCII `"hello"` | `ascii` | `uint8` | 1 | 5 |
| 带重音 `"héllo"` | `ucs2` | `uint16` | 2 | 10 |
| 含汉字 `"你好"` | `ucs4` | `uint32` | 4 | 8 |

于是「长度」有三个完全不同的答案：`size` 数码点（`"你好"` 是 2）、`sizeInBytes`
数**内部表示**的字节（8）、`asUTF8 size` 才是真正 UTF-8 字节数（6，每个汉字 3 字节）。
`at(0)` 给的是码点数值（`20320`），要字符得再 `asCharacter`。

> **为什么重要**：Io 的长度没有「唯一正确答案」，只有「你问的是哪一种」。凡是涉及
> `size` 的比较、切片、对齐，先确认是码点口径还是字节口径；判等、取子串一律用码点口径。

## 2.7 脚本自己的身份与参数

```text
-- 2.7 脚本自己的身份与参数
launchScript 文件名：02_hello
System args 的长度（本示例没带参数，所以是 1）：1
args[0] 是脚本路径，args at(0) fileName = 02_hello.io
isLaunchScript（Io 版的 __main__）：true
```

```io
writeln("launchScript 文件名：", System launchScript fileName)
writeln("System args 的长度（本示例没带参数，所以是 1）：", System args size)
writeln("args[0] 是脚本路径，args at(0) fileName = ", (System args at(0)) asFile name)
chk("args[0] 是脚本本体", System args size, 1)
writeln("isLaunchScript（Io 版的 __main__）：", isLaunchScript)
```

结论：`System launchScript` 是被执行的脚本对象；`System args` 与 C 的 `argv` 同形，
`args[0]` 是脚本路径、用户参数从 `at(1)` 开始（本示例没带参数，所以长度是 1）。
`isLaunchScript` 是 Io 版的 `if __name__ == "__main__"`：当文件被直接执行（而不是被
`doFile` 载入）时为 `true`。

注意这里刻意只打 `fileName`（`02_hello`）而不是完整路径，也没打印 `System args` 整体。

> **为什么重要**：绝对路径、对象地址、时间、进程号、`Map` 的迭代序——这些每次都不同的
> 东西**绝不能进输出**。本仓库的回归脚本会把同一份示例连跑两次、跨两个二进制各跑一次，
> 逐字节比对区间；一旦把这类值打进去，示例就永远不可能稳定。

## 2.8 坑位清单

1. **`obj println(x)` 里的 x 被丢弃** → `println` 写的是接收者，要打印 x 就用 `writeln(x)` 或 `x println`。
2. **以为字符串会自动插值** → `#{...}` 只是普通文本，必须显式接 `interpolate`。
3. **把三引号当模板串** → 三引号只是多行字面量，里面的 `#{}` 同样不会展开。
4. **写 `"\x41"` 想得到 `A`** → 本构建没有 `\xNN` 转义，结果串是 `x41`。
5. **用逗号分隔语句** → 逗号是参数分隔符，多余实参被静默丢掉，语句分隔一律用 `;` 或换行。
6. **拿 `size` 当字节数** → `size` 数的是码点；内部字节看 `sizeInBytes`，UTF-8 字节看 `asUTF8 size`。
7. **对中文串用 `interpolate`** → 非 ASCII 上会错位甚至段错误，改用 `writeln` 多参数或 `..`。
8. **把 `0`、`""`、空列表当真值之外的东西** → 它们全是真值；只有 `nil` 和 `false` 为假（[5.1](05-control.md)）。
9. **在输出里打路径、地址、时间、进程号** → 这些值每次运行都不同，会毁掉逐字节比对；只打 `basename`。
10. **靠退出码判断脚本是否跑完** → 未捕获异常会中断脚本却仍退出 0，必须同时检查结束标记。

---

上一章：[01 · 全景：Io 是什么、这门课怎么走](01-overview.md) · 下一章：[03 · 数字：只有一种 Number](03-numbers.md)
