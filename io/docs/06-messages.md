# 06 · 消息：三种形状与优先级

> 对应示例：[`examples/06_messages/06_messages.io`](../examples/06_messages/06_messages.io)

Io 里没有「表达式」，只有**消息**：一个接收者、一个名字、若干实参，
而实参本身又是消息。运算符只是名字特殊的消息，它们的结合力由 `OperatorTable`
这张运行时可查的**表**决定。把这张表和三种消息形状搞清楚，
后面所有「为什么这样解析」的问题都会变成查表题。

章节末尾那个 `自检` 小节是示例的回归脚手架（它把本章的结论汇总成断言，跑完打印 `自检：全部通过`），属于逐字节比对的一部分，这里不重复。

## 6.1 三种消息形状

```text
-- 6.1 三种消息形状
一元消息（无参，优先级最高）：3
二元消息（操作符）：5
关键字消息（带参数）：2
1 + 2 max(3) 的解析 = 4
1 + (2 max(3)) = 4
(1 + 2) max(3) = 3
```

```io
writeln("一元消息（无参，优先级最高）：", list(1, 2, 3) size)
writeln("二元消息（操作符）：", 2 + 3)
writeln("关键字消息（带参数）：", 1 max(2))
show("1 + 2 max(3) 的解析", 1 + 2 max(3))
show("1 + (2 max(3))", 1 + (2 max(3)))
show("(1 + 2) max(3)", (1 + 2) max(3))
chk("带参消息比 + 绑得紧", 1 + 2 max(3), 4)
chk("要改结合顺序只能加括号", (1 + 2) max(3), 3)
```

结论：消息有三种形状，**结合力从紧到松**是：

| 形状 | 例子 | 结合力 |
|---|---|---|
| 一元消息（无参） | `list(1, 2, 3) size` | 最紧 |
| 关键字消息（带参） | `1 max(2)` | 居中 |
| 二元消息（操作符） | `2 + 3` | 最松 |

所以 `1 + 2 max(3)` 解析成 `1 + (2 max(3))`，结果 `4`——它**不是** `(1 + 2) max(3)` 的
`3`。最后两行输出就是这个对比：想改成「先加再取大」，必须显式加括号。

> **为什么重要**：这条优先级顺序与 Smalltalk **正好相反**（Smalltalk 里二元
> 运算符比关键字消息绑得紧）。凡是从 Smalltalk / Objective-C 那一脉过来的经验，
> 在 Io 上要用之前先验一遍。记法：**「一元最紧、带参居中、操作符最松」**。

## 6.2 消息链是左结合的

```text
-- 6.2 消息链是左结合的
obj add(1) add(2) value = 8
链的写法等价于 ((obj add(1)) add(2)) value = 8
```

```io
obj := Object clone do(
    a := 5
    add := method(n, self a = self a + n; self)
    value := method(a)
)
show("obj add(1) add(2) value", obj add(1) add(2) value)
show("链的写法等价于 ((obj add(1)) add(2)) value", obj value)
chk("链式调用靠返回 self 串起来", obj value, 8)
```

结论：一串消息**从左往右**依次发送，每一次的返回值就是下一次的接收者：
`obj add(1) add(2) value` 等价于 `((obj add(1)) add(2)) value`。

链式风格能成立的前提是**方法返回 `self`**——示例里 `add` 最后一句就是 `self`，
所以 `add(1) add(2)` 能接着往同一个对象上发消息。`value` 不是链的一环，
它是链尾的取值方法。

> **为什么重要**：链式调用是 Io 里最舒服的写法（本教程后面几乎所有示例都用
> `list sort join` 这种句子），但它**完全靠约定**：任何一环忘了 `return self`，
> 链就断在那里。调试链式表达式时，先看是哪一环把自己的返回值漏掉了。

## 6.3 操作符就是消息：可以 perform 出来

```text
-- 6.3 操作符就是消息：可以 perform 出来
2 + 3 = 5
(2) perform("+", 3) = 5
performWithArgList("max", list(9)) = 9
自定义名字也能 perform = abcd
```

```io
show("2 + 3", 2 + 3)
show("(2) perform(\"+\", 3)", 2 perform("+", 3))
show("performWithArgList(\"max\", list(9))", 2 performWithArgList("max", list(9)))
listOps := Object clone do(cat := method(a, b, a .. b))
show("自定义名字也能 perform", listOps perform("cat", "ab", "cd"))
chk("+ 与 perform(\"+\") 完全等价", 2 perform("+", 3), 5)
```

结论：`2 + 3` 与 `2 perform("+", 3)` 是**同一条消息**的两种写法：
前者由解析器按优先级表生成消息，后者由你在运行时按名字发出去。
`performWithArgList(name, list(...))` 是「实参已经在列表里」时的形式；
任何槽都能这么发，包括你自己定义的方法名（`perform("cat", ...)`）。

> **为什么重要**：`+` 是消息而不是编译器内建运算，这句话的实际后果是
> 「运算符可以被 `perform`、可以被覆盖、可以按名字拼出来」。
> 需要写「按名字分发」的框架时，这就是唯一的入口。

## 6.4 优先级表：数字越小绑得越紧

```text
-- 6.4 优先级表：数字越小绑得越紧
全部运算符（字母序）：
  != % %= & && &= * ** *= + += - -= .. / /= < << <<= <= == > >= >> >>= ? @ @@ ^ ^= and or return | |= ||
优先级层数：32
常用运算符的优先级：
  **  1
  %   2
  *   2
  +   3
  ..  12
  ==  6
  and 10
  or  11
  ?   0
```

```io
ops := OperatorTable operators
writeln("全部运算符（字母序）：")
writeln("  ", ops keys sort join(" "))
writeln("优先级层数：", OperatorTable precedenceLevelCount)
writeln("常用运算符的优先级：")
list("**", "%", "*", "+", "..", "==", "and", "or", "?") foreach(op,
    writeln("  ", op alignLeft(4), ops at(op)))
chk("** 比 * 紧", ops at("**") < ops at("*"), true)
chk("== 比 and 紧", ops at("==") < ops at("and"), true)
chk("赋值运算符不在优先级表里", OperatorTable assignOperators keys sort join(" "), "::= := =")
```

结论：`OperatorTable operators` 是一张可运行时读取的表，**数字越小绑得越紧**：

| 运算符 | 优先级 | 说明 |
|---|---|---|
| `?` | 0 | 最松（所以 `o ?x y` 这类写法要小心） |
| `**` | 1 | 幂 |
| `%` `*` | 2 | 乘除模同级 |
| `+` | 3 | 加减 |
| `==` | 6 | 比较 |
| `and` `or` | 10 / 11 | 逻辑 |
| `..` | 12 | 拼接，比逻辑还松 |

表里还能看到两个「意外成员」：`return` 也在表里（它是二元前缀消息，不是关键字），
`?` 也在表里（见 [5.10](05-control.md)）。另外 **赋值运算符不在表里**：
`OperatorTable assignOperators keys sort` 给的是 `::= := =`，它们是语法层面的
消息形态，不参与优先级比较。

> **为什么重要**：`..` 的优先级是 12——比 `and`/`or` 都松。所以
> `"a" .. 1 + 2` 会先算加法再拼接，而 `cond and "x" .. "y"` 会先拼接再短路判断。
> 拼接长的表达式时加括号不是洁癖，是必需的。

## 6.5 自定义运算符：注册管不到同一个编译单元

```text
-- 6.5 自定义运算符：注册管不到同一个编译单元
同文件里 Comparable <=> Comparable 的结果是不是接收者 = true
Lobby doString("... <=> ...") = 比较结果
```

```io
OperatorTable addOperator("<=>", 4)
Comparable := Object clone do(<=> := method(o, "比较结果"))
r := Comparable <=> Comparable
show("同文件里 Comparable <=> Comparable 的结果是不是接收者", r isIdenticalTo(Comparable))
chk("同文件内注册的运算符不生效", r isIdenticalTo(Comparable), true)
show("Lobby doString(\"... <=> ...\")", Lobby doString("Comparable clone <=> Comparable clone"))
chk("换编译单元后运算符生效", Lobby doString("Comparable clone <=> Comparable clone"), "比较结果")
```

结论：`OperatorTable addOperator("<=>", 4)` 确实把 `<=>` 加进了表，但在**同一个文件**里
它**不生效**。原因是编译单元的粒度：一个文件是**一次性解析**完的，解析这句
`Comparable <=> Comparable` 时，`addOperator` 那行还没执行（注册发生在运行时，
解析发生在更早）。于是 `<=>` 被当成一个**普通一元消息**、`Comparable` 被当成另一个
一元消息，串起来的结果就是接收者本身——所以第 1 行输出是 `true`（`r` 就是 `Comparable`）。

换成**另一个编译单元**（`Lobby doString("...")` 会重新解析一遍字符串）就生效了，
于是第 2 行输出是 `"比较结果"`。

> **为什么重要**：这是「运行时的表 vs 解析时的语法」这条分界线最直观的例子。
> 注册自定义运算符后，**必须在新文件里使用**（或者用 `doString` / `doFile` 重新解析
> 一段源码），否则你写的是消息串、不是运算符。

## 6.6 call 与消息对象：在方法里看清自己是怎么被调的

```text
-- 6.6 call 与消息对象：在方法里看清自己是怎么被调的
  被调用的消息名：spy
  参数个数：2
  接收者类型：Object
  调用者上下文里有 spy 吗：true
spy(2, 3) = 5
```

```io
spy := method(a, b,
    writeln("  被调用的消息名：", call message name)
    writeln("  参数个数：", call argCount)
    writeln("  接收者类型：", call target type)
    writeln("  调用者上下文里有 spy 吗：", call sender hasSlot("spy"))
    a + b
)
show("spy(2, 3)", spy(2, 3))
arity := method(a, b, c, call argCount)
chk("call argCount 是实参个数", arity(1, 2, 3), 3)
```

结论：`call` 是「当前这次调用」的现场对象，四件常用信息各自有明确的槽：

- `call message`：被发送的那条**消息对象**；`.name` 是名字（`spy`）。
- `call argCount`：**实参个数**（不是形参个数）。
- `call target`：接收者（这里是一个普通对象，`type` 是 `Object`）。
- `call sender`：调用方的上下文（所以能查它有没有 `spy` 这个槽）。

> **为什么重要**：Io 没有「函数签名」这种东西，方法拿到的形参只是「前几个实参的
> 求值结果」。`call` 是唯一的元数据来源——变参、参数校验、错误信息、装饰器式包装
> 全靠它（[8.4](08-methods.md) 的变参会直接用 `call evalArgAt(i)`）。

## 6.7 Message 对象：消息可以被构造、被存下来、被重新发一次

```text
-- 6.7 Message 对象：消息可以被构造、被存下来、被重新发一次
手工构造的消息 doMessage 到对象上 = hi
从字符串解析一条消息再求值 = 7
把已有消息的 next 摘下来看名字 = greet
```

```io
o := Object clone do(greet := method("hi"))
m := Message clone setName("greet")
show("手工构造的消息 doMessage 到对象上", o doMessage(m))
show("从字符串解析一条消息再求值", (Message fromString("1 + 2 * 3")) doInContext(Lobby))
show("把已有消息的 next 摘下来看名字", m name)
chk("doMessage 触发的是普通消息发送", o doMessage(m), "hi")
chk("Message fromString 走完整解析", (Message fromString("1 + 2 * 3")) doInContext(Lobby), 7)
```

结论：消息本身是**一等对象**，三条路都能得到它：

- `Message clone setName("greet")`：手工造一条只有一个名字的消息，`o doMessage(m)`
  等价于对 `o` 发 `greet`。
- `Message fromString("1 + 2 * 3")`：**走完整的解析流程**（包括优先级表），
  所以结果是 `7` 而不是 `(1 + 2) * 3 = 9`；`doInContext(ctx)` 决定在哪求值。
- 已经存在的消息（`m`）可以直接问它的 `name`。

> **为什么重要**：`Message fromString` 是本教程最常用的「显微镜」：
> 想知道某段代码**到底被解析成什么样**，就把它塞进 `fromString` 再 `show` 出来
> （[8.2](08-methods.md) 与 [8.3](08-methods.md) 的两条关键发现都是这么挖出来的）。
> 它同时也是一个元编程入口：能在运行时拼代码、能改写消息树。

## 6.8 resend 与 super：调用被覆盖的实现

```text
-- 6.8 resend 与 super：调用被覆盖的实现
Child describe（resend） = Child(Base)
Child describeViaSuper（super） = Child(Base)
Base describe 不受影响 = Base
```

```io
Base := Object clone do(describe := method("Base"))
Child := Base clone do(
    describe := method("Child(" .. resend .. ")");
    describeViaSuper := method("Child(" .. super(describe) .. ")")
)
show("Child describe（resend）", Child describe)
show("Child describeViaSuper（super）", Child describeViaSuper)
show("Base describe 不受影响", Base describe)
```

结论：子对象覆盖了 `describe` 之后，想调用「被覆盖掉的那一份」有两个入口：

- `resend`：**按当前消息的名字**回到父实现（`describe` 调 `resend` 就跑 `Base` 的
  `describe`）。
- `super(describe)`：显式指定消息名回父实现，适合「名字与当前方法不同」的场合。

`Child describe` 输出 `Child(Base)`，说明父实现被正常调用了；而 `Base describe`
仍然是 `Base`——覆盖只发生在 `Child` 这一层。

顺带记一个写法规矩：`do(...)` 里定义**多个槽**必须用 **`;` 或换行**分隔
（示例里 `describe := ...;` 末尾那个分号就是干这个的）。用逗号会被解析成
`do` 的**第二个实参**，而多出来的实参**根本不会被求值**——槽静默消失
（详见 [7.9](07-prototypes.md)）。

> **为什么重要**：`resend` 是原型链上的「`super` 调用」，也是 Io 实现
> 「在父行为上叠加」的标准手段。搞不清 `resend` / `super(name)` 的差别，
> 就无法安全地重写库里的方法。

## 6.9 陷阱：.. 会调 asString，普通对象给的是地址

```text
-- 6.9 陷阱：.. 会调 asString，普通对象给的是地址
obj2 .. "x" 的长度大于 0 = true
(obj2 asString) 的槽位摘要里有地址 = true
所以拼接前一定要自己控制 asString 的内容（见 07 章的 asString 覆盖）
```

```io
obj2 := Object clone
show("obj2 .. \"x\" 的长度大于 0", (obj2 .. "x") size > 0)
show("(obj2 asString) 的槽位摘要里有地址", obj2 asString size > 0)
writeln("所以拼接前一定要自己控制 asString 的内容（见 07 章的 asString 覆盖）")
chk(".. 走的是 asString", "n=" .. 7, "n=7")
```

结论：`..` 对右侧做的是 `asString`，而**没有覆盖 `asString` 的对象，其 `asString`
形如 `Object_0x7f...`——里面是一个每次运行都不同的地址**。所以
`obj2 .. "x"` 拼出来的东西长度确实大于 0（断言为真），但内容完全不可控。

示例里之所以只断言 `size > 0` 而不打印那个串，就是为了避免把地址写进判定区间。
要参与输出就两种办法：覆盖 `asString`（[7.8](07-prototypes.md) 给出写法），
或者拼接时显式 `asString` 成你自己控制的文本。

> **为什么重要**：这是「确定性纪律」在语言层面的一次现身：
> 任何依赖 `asString` 的拼接（`..`、`join`、`writeln` 多参数、`interpolate`）
> 只要落到未覆盖 `asString` 的对象上，输出就带上了地址。

## 6.10 坑位清单

1. **以为 `1 + 2 max(3)` 是 3** → 带参消息比二元操作符绑得紧，结果是 4，要改顺序得加括号。
2. **按 Smalltalk 的优先级直觉写代码** → Io 的顺序是一元 > 关键字 > 二元，与 Smalltalk 相反。
3. **链式调用中途断链** → 只返回值的最后一环必须返回 `self`，否则后续消息发不到对象上。
4. **把 `+` 当编译器内建** → 它就是消息，`2 perform("+", 3)` 与 `2 + 3` 完全等价。
5. **忘了 `..` 优先级是 12** → 它比 `and`/`or` 还松，长表达式拼接要加括号。
6. **写了 `addOperator` 就在同文件里用** → 一个文件是一次性解析的，注册只对之后的编译单元生效。
7. **以为 `call argCount` 是形参个数** → 它给的是实参个数，变参实现全靠这个。
8. **手工造消息拼错名字** → `Message clone setName` 造的是空参数消息，参数要用 `setArguments` 或直接 `fromString`。
9. **拿 `..` 拼未覆盖 `asString` 的对象** → 得到带地址的槽位摘要，输出不再逐字节稳定。
10. **覆盖方法后忘了怎么调父实现** → 用 `resend`（同名字）或 `super(名字)`（显式指定）。

---

上一章：[05 · 控制流：没有 if，只有消息](05-control.md) · 下一章：[07 · 原型：克隆、槽与 proto 链](07-prototypes.md)
