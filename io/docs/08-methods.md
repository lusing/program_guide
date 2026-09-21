# 08 · 方法：参数、作用域与 return

> 对应示例：[`examples/08_methods/08_methods.io`](../examples/08_methods/08_methods.io)

方法在 Io 里是**带作用域的可调用对象**。它的参数只有位置：没有默认值、没有变参、
没有重载；缺参数不会报错，等真正用到那个 `nil` 时才炸。这一章除了把这些基础讲清，
还要解释两个本教程最值钱的发现——**内联方法后面跟括号会被整个丢掉**，
以及 **`method(a, b := 10, ...)` 里的 `:=` 会被解析成一条 `setSlot` 消息**。

章节末尾那个 `自检` 小节是示例的回归脚手架（它把本章的结论汇总成断言，跑完打印 `自检：全部通过`），属于逐字节比对的一部分，这里不重复。

## 8.1 定义与调用：位置参数，没有默认值

```text
-- 8.1 定义与调用：位置参数，没有默认值
add(2, 3) = 5
方法体是最后一个表达式的值 = 3
try(add(2)) 的异常消息 = argument 0 to method '+' must be a Number, not a 'nil'
把形参直接返回出来才看得见 nil：second(1) = nil
```

```io
add := method(a, b, a + b)
show("add(2, 3)", add(2, 3))
show("方法体是最后一个表达式的值", getSlot("add") call(1, 2))
e := try(add(2))
show("try(add(2)) 的异常消息", e error)
second := method(a, b, b)
show("把形参直接返回出来才看得见 nil：second(1)", second(1))
chk("少传参数不报参数缺失，形参就是 nil", second(1), nil)
chk("用到 nil 才炸", e error, "argument 0 to method '+' must be a Number, not a 'nil'")
```

结论：`method(形参..., 方法体)` 里，**最后一项是方法体，前面所有项都是形参名**。
调用按**位置**绑定实参；方法体是最后一个表达式的值。

关键在「少传参数」：`add(2)` **不会**报「参数缺失」。形参 `b` 就是 `nil`，
只有在方法体真的用到它时才炸——`a + b` 把 `nil` 喂给了 `+`，
于是抛 `argument 0 to method '+' must be a Number, not a 'nil'`。
想「看见 `nil`」，就像 `second` 那样把形参直接当返回值。

> **为什么重要**：Io 的方法没有签名校验，所以「参数个数错」不会在调用点暴露，
> 而是在方法体深处以「某某不响应」的形式炸出来。看到 `nil does not respond to ...`
> 或 `argument N to method ... must be a X, not a 'nil'`，第一反应应该是
> **回去数实参个数**，而不是怀疑库。

## 8.2 陷阱：内联方法后面直接跟括号，方法会被整个丢掉

```text
-- 8.2 陷阱：内联方法后面直接跟括号，方法会被整个丢掉
(1 + 1)(5) = 5
(method(a, b, b))(1) 的结果 = 1
它的解析树 = (method(a, b, b)) (1)
(method(a, b, b)) call(1) = nil
```

```io
show("(1 + 1)(5)", (1 + 1)(5))
show("(method(a, b, b))(1) 的结果", (method(a, b, b))(1))
show("它的解析树", Message fromString("(method(a, b, b))(1)"))
show("(method(a, b, b)) call(1)", (method(a, b, b)) call(1))
chk("两个相邻括号组，值取后一个", (1 + 1)(5), 5)
chk("内联方法被丢掉，结果就是实参本身", (method(a, b, b))(1), 1)
chk("加 .call 才是真的在调它", (method(a, b, b)) call(1), nil)
```

结论：`(method(a, b, b))(1)` **不是**「调用这个内联方法」。看这条实测输出里的解析树
就明白了：

```text
它的解析树 = (method(a, b, b)) (1)
```

这是**两个相邻的括号组**，Io 把它解析成一条**名字由前一组算出来**的消息：
前一组照常求值（方法对象确实被创建出来了），但它的值不会被当成「要调用的方法」，
整条表达式的值等于最后一组的值 `(1)`，也就是 `1`。同理 `(1 + 1)(5)` 给 `5`。

所以那个内联方法是「造出来又扔掉」的。要真的调用它，只有两条路：

- **先绑到槽上**再调：`f := method(a, b, b)`，然后 `f(1)`；
- 或者 **`.call(...)`**：`(method(a, b, b)) call(1)` 会给 `b`，即 `nil`
  （`a` 拿到 1、`b` 是 `nil`，方法体返回 `b`）。

单独实测还可以确认前一组真的会求值（副作用会跑），只是值被丢弃：
`(writeln("第一组求值了吗") ; 42)(5)` 会打印那一行，然后整条表达式的值仍是 `5`。

> **为什么重要**：这条坑的可怕之处是**它不报错**：`(method(...))(x)` 看起来像
> 立即调用（IIFE），实际得到的是 `x`，于是「回调返回值」变成「实参本身」，
> bug 会以完全无关的形态出现在下游。写完内联方法立刻要调用时，
> 先问自己一句：我是先绑槽了吗？还是写了 `.call`？

## 8.3 Io 没有默认参数：自己判 nil

```text
-- 8.3 Io 没有默认参数：自己判 nil
messageTree = method(a, setSlot("b", 10), a +(b))
withDefault argumentNames = list("a", "setSlot")
withDefault(1, 2) 的异常消息 = Object does not respond to 'b'
greet = 你好，匿名
greet("Io") = 你好，Io
```

```io
show("messageTree", Message fromString("method(a, b := 10, a + b)"))
withDefault := method(a, b := 10, a + b)
show("withDefault argumentNames", getSlot("withDefault") argumentNames)
e3 := try(withDefault(1, 2))
show("withDefault(1, 2) 的异常消息", e3 error)
chk(":= 变成了一个假的形参名", getSlot("withDefault") argumentNames asString,
    "list(\"a\", \"setSlot\")")
chk("调用时就找不到 b 了", e3 error, "Object does not respond to 'b'")
greet := method(name, if(name == nil, name = "匿名"); "你好，" .. name)
show("greet", greet)
show("greet(\"Io\")", greet("Io"))
```

结论：`method(a, b := 10, a + b)` 看起来像「默认参数」，其实是解析层面的错觉。
示例把这条消息重新解析了一遍，真相直接摊在输出里：

```text
messageTree = method(a, setSlot("b", 10), a +(b))
```

`b := 10` 在解析时被改写成了一整条 **`setSlot("b", 10)` 消息**。于是 `method` 看到的
是三个实参：`a`、`setSlot(...)`、`a + b`。按 8.1 的规则，最后一项是方法体，
**前两项都成了形参名**——第二个形参的名字就是那条消息的**名字** `setSlot`。

后果是：

- `argumentNames` 变成 `list("a", "setSlot")`：形参叫 `setSlot`，`b` 这个形参
  **根本不存在**。
- `withDefault(1, 2)` 里 `a` 拿到 1，`setSlot` 拿到 2，方法体 `a + b` 里的 `b`
  在 `self` 上找不到，于是抛 `Object does not respond to 'b'`。

正解就是**自己判 `nil`**：

```io
greet := method(name, if(name == nil, name = "匿名"); "你好，" .. name)
```

不传参数时 `name` 是 `nil`，`if` 里给它补上默认值；传了就原样用。
`greet` 给 `你好，匿名`，`greet("Io")` 给 `你好，Io`。

> **为什么重要**：这是「`:=` 不是语法关键字，而是一条消息（`setSlot`）」的
> 最直接证据——它连形参表都能污染。记住这个模式：
> **Io 的「默认参数」= 形参判 `nil` 后赋值**，没有别的写法。

## 8.4 变参：用 call 现场取

```text
-- 8.4 变参：用 call 现场取
sum = 0
sum(1, 2, 3, 4) = 10
sum argumentNames（声明了 0 个形参） = list()
```

```io
sum := method(
    n := call argCount
    if(n == 0, return 0)
    total := 0
    for(i, 0, n - 1, total = total + call evalArgAt(i))
    total
)
show("sum", sum)
show("sum(1, 2, 3, 4)", sum(1, 2, 3, 4))
show("sum argumentNames（声明了 0 个形参）", getSlot("sum") argumentNames)
chk("变参求和", sum(1, 2, 3, 4), 10)
chk("零个参数也安全", sum, 0)
```

结论：变参不需要语法支持，因为**实参本来就都在调用现场里**：

- `call argCount` 拿实参个数；
- `call evalArgAt(i)` 求值第 `i` 个实参（`i` 从 0 起）；
- 形参表写成空（`method(...)` 只有方法体），`argumentNames` 就是 `list()`。

`sum` 因此对 0 个到任意多个参数都成立：0 个走 `return 0` 提前退出，
4 个则累加 `10`。

> **为什么重要**：`call evalArgAt` 是按需求值——**没被取用的实参不会被求值**。
> 这既是性能开关（日志/断言可以跳过昂贵实参），也是语义开关
> （错误处理函数可以只求值需要的那一支）。Io 的很多库函数就是这么省掉开销的。

## 8.5 声明形参后仍能摸到多余实参

```text
-- 8.5 声明形参后仍能摸到多余实参
tail(1, 2, 3) = 1|2,3
tail(1) = 1|
```

```io
tail := method(first,
    parts := List clone
    for(i, 1, call argCount - 1, parts append(call evalArgAt(i)))
    first .. "|" .. parts join(",")
)
show("tail(1, 2, 3)", tail(1, 2, 3))
show("tail(1)", tail(1))
chk("第 2 个起算多余实参", tail(1, 2, 3), "1|2,3")
chk("没有多余实参时拼接后是空串", tail(1), "1|")
```

结论：声明了 `first` 之后，**多出来的实参照样能被 `call evalArgAt` 取到**：
从下标 1 开始就是「多余实参」。`tail(1, 2, 3)` 得到 `1|2,3`；
只有 1 个实参时循环一次都不跑，`parts` 是空表，拼接结果是 `1|`。

也就是说 Io 的方法可以**同时**有「命名参数」和「变参尾巴」，不需要 `...` 或 `*args`。

> **为什么重要**：这条让「主参数 + 可选选项」这种 API（`f(x, key, value, ...)`）
> 不需要任何特殊语法。代价是所有人都得记住：多出来的实参不会报错，只会静静躺在
> `call` 里。

## 8.6 call 给的是调用现场的全部信息

```text
-- 8.6 call 给的是调用现场的全部信息
inspect(1, 2) = inspect / 2 / Object / Object
接收者就是 self = true
自己问出自己的名字 = nameOf
```

```io
inspect := method(a, b,
    list(call message name, call argCount, call target type, call sender type) join(" / ")
)
show("inspect(1, 2)", inspect(1, 2))
holder := Object clone do(
    v := 5;
    whoami := method(call target isIdenticalTo(self))
)
nameOf := method(call message name)
show("接收者就是 self", holder whoami)
show("自己问出自己的名字", nameOf)
chk("call target 是接收者", holder whoami, true)
chk("call message name 就是被调用时的名字", nameOf, "nameOf")
```

结论：`call` 里最常用的四个槽可以一次拼出来看：
**消息名 / 实参个数 / 接收者类型 / 调用者类型**，即
`inspect / 2 / Object / Object`。

此外还有两条恒等式值得记住：`call target` 就是 `self`（接收者本身），
以及 `call message name` 就是**被调用时用的那个名字**——所以方法可以「问出自己的名字」，
不用把名字硬编码进去。

> **为什么重要**：`call message name` 是写「通用包装」「自动日志」「按名字分发的
> 转发器」的基石。任何需要「我现在是以什么名字被调用的」的元编程，
> 都在这个槽上。

## 8.7 return 与提前退出

```text
-- 8.7 return 与提前退出
classify(-1) / classify(0) / classify(1) = list("负数", "零", "正数")
find(list(1,2,3), 2) = true
find(list(1,2,3), 9) = false
```

```io
classify := method(n,
    if(n < 0, return "负数")
    if(n == 0, return "零")
    "正数"
)
show("classify(-1) / classify(0) / classify(1)",
     list(classify(-1), classify(0), classify(1)) asString)
find := method(items, target, items foreach(v, if(v == target, return true)); false)
show("find(list(1,2,3), 2)", find(list(1, 2, 3), 2))
show("find(list(1,2,3), 9)", find(list(1, 2, 3), 9))
```

结论：`return` 是**方法级**跳转，两条用法：

- 「多分支提前退出」：`classify` 用两次 `if(..., return ...)` 把负数和零先挑出去，
  走到最后一行才轮到「正数」。
- 「从块里穿出来」：`find` 在 `foreach` 的块里 `return true`，
  直接结束**整个方法**（不是只结束这一次迭代）。所以第 2 个元素命中时立刻返回 `true`；
  走完整条路才落到方法体最后一句 `false`。

> **为什么重要**：Io 里没有 `break` 之外的循环控制（[5.7](05-control.md)），
> 「在嵌套块里提前退出整个方法」只能靠 `return`——它穿得比 `break` 远。
> 写搜索/校验类方法时，`return` 是最短的写法。

## 8.8 陷阱：槽里的方法被「读出来」时自动激活

```text
-- 8.8 陷阱：槽里的方法被「读出来」时自动激活
try(double) 的异常消息 = nil does not respond to '*'
getSlot("double") asSimpleString = method(n, ...)
isActivatable = true
apply(getSlot("double")) = 42
```

```io
double := method(n, n * 2)
e4 := try(double)
show("try(double) 的异常消息", e4 error)
show("getSlot(\"double\") asSimpleString", getSlot("double") asSimpleString)
show("isActivatable", getSlot("double") isActivatable)
apply := method(f, f(21))
show("apply(getSlot(\"double\"))", apply(getSlot("double")))
chk("槽里的方法默认可激活", getSlot("double") isActivatable, true)
chk("拿本体要 getSlot 绕过激活", apply(getSlot("double")), 42)
chk("直接读 slot 等于零参调用", e4 error, "nil does not respond to '*'")
```

结论：**写 `double` 不是「取出这个方法」，而是「调用这个方法」**——形参 `n` 是 `nil`，
方法体 `n * 2` 于是抛 `nil does not respond to '*'`。这是 Io 的方法激活规则：
槽里存的是可激活对象时，**读槽即调用**。

要拿**方法本体**当值传，必须显式绕过激活：`getSlot("double")`。
拿到之后 `apply(getSlot("double"))` 就能把它交给别的方法调用（结果 `42`）。
`asSimpleString` 打印出 `method(n, ...)`，`isActivatable` 是 `true`——
这两条也解释了为什么标准库里到处是 `getSlot("...")`。

> **为什么重要**：这条规则决定了 Io 的「函数是一等值」要怎么表达：
> **值传递一律 `getSlot("名字")`**。忘了它会得到「莫名其妙的 `nil does not respond`」，
> 因为方法已经被空参调用过一次了。
>
> 规则的完整形态（`isActivatable` 由**造块的方式**决定、`method(...)` 与
> `block(...)` 的分工）在 11.3.1：**要当数据传的块用 `block(...)` 造，
> 要挂在槽上当方法用的才用 `method(...)`**。本节讲的是「已经挂在槽上了怎么办」。

## 8.9 方法是一等值：可以装进容器、当参数传

```text
-- 8.9 方法是一等值：可以装进容器、当参数传
fns size = 2
按顺序调用 = list(20, 11)
用 perform 调对象上的方法 = 7
```

```io
double2 := method(n, n * 2)
inc := method(n, n + 1)
fns := list(getSlot("double2"), getSlot("inc"))
show("fns size", fns size)
show("按顺序调用", list(fns at(0) call(10), fns at(1) call(10)) asString)
show("用 perform 调对象上的方法", (Object clone do(m := method(7))) perform("m"))
chk("方法能装进 List", fns size, 2)
chk("取出来还能调", fns at(1) call(10), 11)
chk("perform 按名字发消息", (Object clone do(m := method(7))) perform("m"), 7)
```

结论：`getSlot("double2")` 拿到的方法可以放进 `List`、从 `List` 取出来再 `call(10)`
（得到 `20` 和 `11`）。这是 Io 的「函数是一等值」——只是每次传递都要显式 `getSlot`
绕过激活（8.8），取出来调用用 `call(...)`。

按名字调用对象上的方法则用 `perform("m")`（[6.3](06-messages.md) 的同一套机制）。

> **为什么重要**：高阶函数在 Io 里就是「用 `List` 装 `getSlot` 出来的方法」，
> 不需要额外的函数指针类型。反过来，`perform` 是按名字调用的唯一入口，
> 也是回调/插件式设计的基础。

## 8.10 方法体语句分隔符：逗号和分号不是一回事

```text
-- 8.10 方法体语句分隔符：逗号和分号不是一回事
twoArgs argumentNames = list("a", "b")
twoArgs(1, 2) = 3
twoStmts(1, 2) = 6
```

```io
twoArgs := method(a, b, a + b)
twoStmts := method(a, b, x := a + b; x * 2)
show("twoArgs argumentNames", getSlot("twoArgs") argumentNames)
show("twoArgs(1, 2)", twoArgs(1, 2))
show("twoStmts(1, 2)", twoStmts(1, 2))
chk("逗号进的是形参表", getSlot("twoArgs") argumentNames asString, "list(\"a\", \"b\")")
chk("分号才是语句分隔，返回值是最后一条", twoStmts(1, 2), 6)
```

结论：`method(a, b, a + b)` 与 `method(a, b, x := a + b; x * 2)` 的差别不在风格：

- `a`、`b` 虽然也写成「值」，但它们在**形参表**里，被当成形参名；
- 方法体里的多条语句必须用 **`;`（或换行）** 分隔，`x := a + b; x * 2` 是先算再乘，
  返回值是最后一条 `x * 2` = `6`；
- 把方法体里的分隔符写成逗号，就变成「又多了几个形参」（[7.9](07-prototypes.md)
  的 `do(...)` 是同一件事）。

> **为什么重要**：「逗号 = 参数、分号/换行 = 语句」这一条贯穿全语言
> （`do(...)`、`method(...)`、`while(...)` 全都一样）。它是 Io 里
> 最高频、最不易察觉的语法错误来源，值得单独记一条。

## 8.11 code / argumentNames：方法能自省出自己的消息树

```text
-- 8.11 code / argumentNames：方法能自省出自己的消息树
double argumentNames = list("n")
double code = method(n, n *(2))
把 code 重新解析回来再调 = 21
```

```io
show("double argumentNames", getSlot("double") argumentNames)
show("double code", getSlot("double") code)
show("把 code 重新解析回来再调",
     (Message fromString("method(n, n * 3)")) doInContext(Lobby) call(7))
chk("code 打印的是消息树", getSlot("double") code asString, "method(n, n *(2))")
chk("消息树可以被重新解析", (Message fromString("method(n, n * 3)")) doInContext(Lobby) call(7), 21)
```

结论：方法能自省出自己的两样东西：

- `argumentNames`：形参名列表（`list("n")`）。
- `code`：**方法体的消息树**——注意打印出来是 `method(n, n *(2))`，
  是消息树形式（`*(2)` 而不是 `n * 2` 的源码文本），因为源码早就解析成树了。

既然是消息树，就能把它**重新解析**（`Message fromString("method(n, n * 3)")`）并调用
（`call(7)` 给 `21`）——这就是运行时构造/改写方法的基础。

> **为什么重要**：`code` 是「看清自己长什么样」的镜子，也是 8.2 与 8.3 那两条发现的
> 取证工具：把 `Message fromString(...)` 打出来，解析树的形状一目了然。
> 遇到任何「为什么这样解析」的疑问，先 `show(Message fromString("..."))`。

## 8.12 坑位清单

1. **调用时少传参数就以为会报错** → 形参拿到 `nil`，直到被用到才炸，报错信息里只有下游痕迹。
2. **写 `(method(...))(x)` 当立即调用** → 那是两个相邻括号组，方法被丢弃，结果是 `x`。
3. **用 `method(a, b := 10, ...)` 当默认参数** → `:=` 解析成 `setSlot` 消息，`b` 不是形参，改成判 `nil` 后赋值。
4. **以为 `argumentNames` 里只有你写的形参** → 假默认参数会让它变成 `list("a", "setSlot")`。
5. **想写变参却找不到 `*args`** → 形参表留空，用 `call argCount` 与 `call evalArgAt(i)` 现场取。
6. **忘了多出来的实参仍在 `call` 里** → 声明形参后，从下标 1 起就是多余实参，静默可用。
7. **在块里 `return` 以为只结束本次迭代** → `return` 是方法级跳转，会穿出整个方法。
8. **直接把方法名当值传** → 读槽即调用，要本体必须 `getSlot("名字")`。
9. **用逗号分隔方法体里的多条语句** → 逗号进的是形参表，语句分隔一律用 `;` 或换行。
10. **想知道某段代码被解析成什么却不打印消息树** → `show(Message fromString("..."))`，它是最便宜的取证手段。

---

上一章：[07 · 原型：克隆、槽与 proto 链](07-prototypes.md) · 下一章：[09 · 列表](09-lists.md)
