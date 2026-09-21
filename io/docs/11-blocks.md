# 11 · 块与闭包

> 对应示例：[`examples/11_blocks/11_blocks.io`](../examples/11_blocks/11_blocks.io)

第 08 章讲了方法，本章讲**块**：Io 里 `method(...)` 造出来的东西类型就叫 `Block`，
它既是对象（有槽、能自省），又是**一条还没发出去的消息**。
本章还实测了一条大多数人会写错的事实：**这个构建里 `{ ... }` 根本不能用**。

## 11.1 块就是 `method(...)`：本构建里 `{}` 不是可用的块字面量

先看 `method(...)` 造出来的到底是什么：

```text
-- 11.1 块就是 method(...)：本构建里 {} 不是可用的块字面量
add(2, 3) = 5
getSlot("add") type = Block
getSlot("add") argumentNames = list("a", "b")
getSlot("add") code = method(a, b, a +(b))
Message fromString("{ 1 + 1 }") = curlyBrackets(1 +(1))
try({ 1 + 1 }) 的异常 = Object does not respond to 'curlyBrackets'
```

```io
add := method(a, b, a + b)
show("add(2, 3)", add(2, 3))
show("getSlot(\"add\") type", getSlot("add") type)          // Block
show("getSlot(\"add\") code", getSlot("add") code)          // method(a, b, a +(b))

// 别的 Io 教程里的 { ... } 在这里会变成一条发给接收者的 curlyBrackets(...) 消息
brace := method({ 1 + 1 })
e1 := try(brace)
show("try({ 1 + 1 }) 的异常", e1 error)                      // Object does not respond to 'curlyBrackets'
```

结论分两层。第一层：**`method(...)` 出来的东西官方名字叫 `Block`**，Io 里没有单独的
`Method` 类型（这个构建的 `Core` 里连 `Method` 这个名字都没有）。
第二层：**`{}` 在本构建里不可用**——它只是被解析成 `curlyBrackets(...)`，
而 `Lobby` / `Object` / `Core` 上都没有实现这个槽，于是抛
`Object does not respond to 'curlyBrackets'`。本章后面所有块都用 `method(...)` 写。

> **为什么重要**：Io 的语法糖少得可怜，`{}` 不是关键字而是**约定俗成的消息名**。
> 一旦某个宿主没铺这个槽，语法糖就消失了。遇到「书上能跑、我这跑不了」时，
> 先看 `Message fromString` 的解析树，再看谁的槽表里少了那一条。

## 11.2 块也是对象：`type` / `isActivatable` / `argumentNames` / `code`

块全部能自省的东西：

```text
-- 11.2 块也是对象：type / isActivatable / argumentNames / code
Block slotNames = Formatter, argumentNames, asSimpleString, asString, call, callWithArgList, code, justSerialized, message, passStops, performOn, print, printProfile, println, profilerTime, scope, setArgumentNames, setMessage, setPassStops, setProfilerOn, setScope
getSlot("add") isActivatable = true
getSlot("add") message = a +(b)
setArgumentNames 之后 argumentNames = list("q")
callWithArgList(list(41)) = 1
getSlot("add") call(20, 22) = 42
```

```io
show("Block slotNames", Block slotNames sort join(", "))
show("getSlot(\"add\") isActivatable", getSlot("add") isActivatable)
show("getSlot(\"add\") message", getSlot("add") message)

blks := list(method(1), method(2))          // 用容器装，容器不会激活元素
(blks at(0)) setArgumentNames(list("q"))     // argumentNames 是槽，可以事后改
show("callWithArgList(list(41))", blks at(0) callWithArgList(list(41)))
show("getSlot(\"add\") call(20, 22)", getSlot("add") call(20, 22))
```

`argumentNames` / `code` / `message` 分别是「形参名」「消息树」「自己那条消息」；
`call` / `callWithArgList` 是两种调用形状；`setArgumentNames` / `setMessage` / `setScope`
是可写的那几项。注意 `isActivatable` 打印的是 `true`——这条后面两节会反复咬人。

> **为什么重要**：把一个块存进容器（`list(...)`）之后它还是对象，不会因为
> 「放在别处」而改变语义。想批量操作一组函数，就直接 `list` 装起来当数据用。

## 11.3 槽里的块：读槽就等于调它

```text
-- 11.3 槽里的块：读槽就等于调它
hi（读槽） = hi
getSlot("hi") type = Block
getSlot("hi") code 打出本体 = method("hi")
holder mine（方法里的 self 就是接收者） = true
naive 返回的是 7 而不是块 = 7
naive type = Number
keeper at(0) type = Block
keeper at(0) call = 7
```

```io
hi := method("hi")
show("hi（读槽）", hi)                        // hi —— 不是块，是调用结果
show("getSlot(\"hi\") type", getSlot("hi") type)   // Block
show("getSlot(\"hi\") code 打出本体", getSlot("hi") code)

// 想「返回一个块」时最容易翻车：局部槽里的块同样一读就调
naive := method(
    b := method(7)
    b
)
show("naive 返回的是 7 而不是块", naive)       // 7
show("naive type", naive type)                // Number

// 要留住块本体就用容器装
keeper := method(
    b := list(method(7))
    b
)
show("keeper at(0) type", keeper at(0) type)  // Block
show("keeper at(0) call", keeper at(0) call)  // 7
```

**凡是有块落进槽里，这个槽就变成可激活的**——读它就是零参调用。
要拿本体只有两条路：`getSlot("名字")` 绕过激活，或者一开始就装进 `list`。

> **为什么重要**：这是 Io 里最容易把「函数」和「函数调用的结果」搞混的地方。
> 08 章说「槽里的方法被读出来时自动激活」，这里补上**局部槽同样如此**，
> 所以「返回一个函数」在 Io 里必须显式绕开激活。

### 11.3.1 `method(...)` 与 `block(...)`：`isActivatable` 决定能不能当数据传

上面那句「一开始就装进 `list` 就安全」**只对了一半**。容器确实不激活自己的元素——
但**元素一旦再落进一个槽、又被读出来，照样激活**。真正的判据是块自己的
`isActivatable` 标志，而它由**造块的方式**决定：

| 造法 | `isActivatable` | 进槽后读出来 |
|---|---|---|
| `method(...)` | `true` | **被激活**（调用） |
| `block(...)` | `false` | 原样是块 |

实测（`examples/11_blocks/11_blocks.io` 的 11.3.1 节）：

```text
-- 11.3.1 method(...) 与 block(...)：isActivatable 决定能不能当数据传
getSlot("m") isActivatable = true
getSlot("b") isActivatable = false
容器里第 0 个（method 造的）type = Block
容器里第 1 个（block 造的）type = Block
把 method 造的块交给形参 = Number
把 block  造的块交给形参 = Block
```

```io
m := method(1)
b := block(1)
getSlot("m") isActivatable     // true   —— method 造的块「可激活」
getSlot("b") isActivatable     // false  —— block 造的块不会自己跑起来

pair := list(method(1), block(1))
getSlot("pair") at(0) type     // Block  —— 装在容器里，两个都还完好

// 关键的一步：把它们交给一个「形参」。Io 的形参就是一个槽，
// 所以可激活的块会在这一步被激活，block 造的不会。
echoType := method(x, x type asString)
echoType(method(1))            // "Number" —— 进槽即被调用
echoType(block(1))             // "Block"  —— 过槽仍是块
```

**「交给形参」和「读一个槽」是同一件事**：Io 的形参就是方法帧里的槽，
所以只要一个块经过形参，`isActivatable` 就开始生效。

这条规则解释了一大批看起来莫名其妙的写法：

- **`sortBy(block(a, b, ...))`**：24 章排序时必须用 `block` ——用 `method` 造的比较器
  一进形参就被零参调用，`a + b` 里的 `a` / `b` 是 `nil`，直接炸。
- **`sortBy(a, b, ...)` 也不行**：那会被当成三个普通实参。见 24 章坑位第 8 条。
- **`withHandler(类型, 处理器, 主体)` 的处理器必须用 `block(exc, resume, …)`** ——
  库内部 `_findHandler` 会把处理器取出来放进 `entry := list(...)` 再交给
  `handler call(...)`，中间经过形参；用 `method` 造的处理器会先被零参调用，
  异常对象根本没传到，最后报成 `nil does not respond to 'error'`（13.9）。
- **标准库里 `getSlot("xxx")` 遍地都是**：凡是要把方法当值传的地方，都得先绕过激活。

> **为什么重要**：这是 Io 的「块 = 消息树」模型的一个直接后果，也是本教程里
> 覆盖范围最广的一条规则。判断方法很简单——**只要一个块要「被传递」而不是
> 「被调用」，就用 `block(...)` 造它**。`method(...)` 是给你挂在槽上当方法用的。

## 11.4 闭包捕获的是上下文，不是值

```text
-- 11.4 闭包捕获的是上下文，不是值
n = 1
getN = 1
n = 5 之后 getN = 5
别的帧里有局部 n = 999，getN 仍然给 = 5
```

```io
n := 1
getN := method(n)
show("n", n)
show("getN", getN)
n = 5                      // 改的是 Lobby 上那个 n
show("n = 5 之后 getN", getN)     // 5 —— 块看到的是「现在的 n」，不是建块时的快照

other := method(
    n := 999               // 调用帧里的同名局部
    getN
)
show("别的帧里有局部 n = 999，getN 仍然给", other)   // 5
```

两张图叠在一起看：块**记的是定义处的上下文对象**，不是值（所以 `n` 改了它跟着变），
也不是调用处（所以调用帧里的同名局部完全影响不到它）。Io 不是动态作用域。

> **为什么重要**：正因为捕获的是「那个对象」，闭包才能是靠对象存活而不是靠栈存活。
> 11.6 会看到这条的另一面：**上下文对象一旦走了，块就找不到名字了**。

## 11.5 `=` 改外层，`:=` 造局部；`do` 的槽落在接收者上

```text
-- 11.5 = 改外层，:= 造局部；do 的槽落在接收者上
updateOuter 之后 v = 2
shadow 返回 = 99
shadow 之后 v = 2
cat hasSlot("x") = true
cat x = 5
cat2 x = 6
顶层裸 self = 异常：Object does not respond to 'self'
方法里 self 就是接收者（顶层调用时即 Lobby） = true
Lobby proto type = Object
Protos slotNames = Addons, Core
```

```io
v := 1
updateOuter := method(v = v + 1)      // = 沿着作用域找到那个槽，改它
shadow := method(v := 99; v)          // := 在当前帧里凭空造一个局部
updateOuter
show("updateOuter 之后 v", v)          // 2
show("shadow 返回", shadow)            // 99
show("shadow 之后 v", v)               // 2 —— 外面那个 v 没动

cat := Object clone
cat do(x := 5)                         // do 把目标设成接收者，:= 就落在接收者上
show("cat hasSlot(\"x\")", cat hasSlot("x"))   // true

r := try(self)
show("顶层裸 self", if(r isKindOf(Exception), "异常：" .. r error, r type))
atTop := method(self isIdenticalTo(Lobby))
show("方法里 self 就是接收者（顶层调用时即 Lobby）", atTop)   // true
```

`:=` 永远只落在**当前帧**：在方法里是那一帧的局部，在 `do(...)` 里因为目标换成了接收者，
就落在接收者上。`self` 只在方法里有——顶层直接写 `self` 会报
`Object does not respond to 'self'`。

> **为什么重要**：Io 里没有 `var` / `let` / `global` 三件套，只有 `:=`（造）和 `=`（改）。
> 想把状态挂到某个对象上，就 `obj do(槽 := ...)`；想让状态留在本帧，就直接 `:=`。

## 11.6 有状态的块：maker 的局部槽活不过 maker

先看最直觉的写法怎么死的：

```text
-- 11.6 有状态的块：maker 的局部槽活不过 maker
maker 返回之后再叫这个块 = 异常：Object does not respond to 'c'
c1 第 1 次读 = 1
c1 第 2 次读 = 2
c2 第 1 次读 = 1
c1 第 3 次读 = 3
快照 s1（第 4 次读 c1） = 4
快照 s2（第 2 次读 c2） = 2
box show = n=2
```

```io
makeNaive := method(
    c := 0
    method(c = c + 1)
)
naiveCounter := makeNaive
e2 := try(naiveCounter)                 // Object does not respond to 'c'
show("maker 返回之后再叫这个块", if(e2 isKindOf(Exception), "异常：" .. e2 error, e2 asString))

// 正解一：把块的作用域钉在一个活得够久的对象上
makeCounter := method(
    st := Object clone
    st n := 0
    s := list(method(n = n + 1))
    s at(0) setScope(st)                // ★
    s at(0)
)
c1 := makeCounter
c2 := makeCounter
show("c1 第 1 次读", c1)                 // 1
show("c1 第 2 次读", c1)                 // 2
show("c2 第 1 次读", c2)                 // 1 —— 另一个计数器自己的状态
show("c1 第 3 次读", c1)                 // 3

// 正解二：干脆把状态放在对象的槽里，方法读 self 的槽
makeBox := method(
    b := Object clone
    b n := 0
    b bump := method(n = n + 1)
    b show := method("n=" .. n asString)
    b
)
box := makeBox
box bump
box bump
show("box show", box show)               // n=2
```

三条可以带走的东西：

1. **maker 里 `:=` 造的局部槽，在 maker 返回后就没了**，所以块再被叫起来时找不到 `c`。
2. 想让块有状态，用 `setScope` 把它钉在一个持久对象上——这时候每个 maker 调用
   **各造一个 `st`**，所以两个计数器**不共享状态**（`c1` 累到 3 时 `c2` 还在 1）。
3. 更 Io 的写法是正解二：状态本来就在对象的槽里，方法体里的 `n` 通过对 `self` 的
   槽查找解决，连 `setScope` 都不需要。

还有一条自省的注意点写在这段测试里：`show` / `chk` 的实参是**消息**，
每次引用都会重新求值一次，所以 `chk("...", c1, 3)` 会顺手把计数器推到 4。
测这种「读一次就走一格」的东西，先 `s1 := c1` 取快照再断言。

> **为什么重要**：大多数语言的闭包把变量**拷进一个堆上的环境**；Io 的块拿的是
> **当时那个作用域对象**。作用域对象如果是调用帧，帧一退就没了；
> 想长久就自己造一个对象顶上去。这条决定了 Io 里「闭包」的实际写法。

## 11.7 块 = 一条还没发出的消息：`if` / `and` / `or` 的惰性

```text
-- 11.7 块 = 一条还没发出的消息：if / and / or 的惰性
false and(bump) = false
t = 0
true and(bump) = true
t = 1
true or(bump) = true
t = 1
false or(bump) = true
t = 2
if(false, bump) = false
t = 2
if(true, bump) = 算了
t = 3
and(false, bump)（漏写接收者） = false
t = 4
```

```io
t := 0
bump := method(t = t + 1; "算了")

false and(bump)          // 不调 bump，t 还是 0
true and(bump)           // 调 bump，t 变 1
true or(bump)            // 不调，t 还是 1
false or(bump)           // 调，t 变 2
if(false, bump)          // 不调，t 还是 2
if(true, bump)           // 调，t 变 3

and(false, bump)         // ★ 漏写接收者：成了发给 Lobby 的消息，短路失效，t 变 4
```

`if` / `and` / `or` 都不在调用前求值参数——它们收到的是**消息树**，
由自己决定要不要 `doMessage`。所以说「块就是一条还没发出去的消息」：
`bump` 传进去的时候还是一个待发的消息。

最后一行是坑：`and(false, bump)` 少了接收者，就变成了「给 Lobby 发一条 `and` 消息」，
接收者是 Lobby（真值），语义完全不同——`bump` 被求值了，`t` 从 3 涨到 4。

> **为什么重要**：「宏」和「函数」在 Io 里没有语法差别，只差在**你和不和参数求值商量**。
> 想让调用者省一次计算，就别急着求值参数；代价是传进来的东西可能根本不是值。

## 11.8 调用现场与元数：`call target` / `sender` / `message` / `argCount`

```text
-- 11.8 调用现场与元数：call target / sender / message / argCount
inspect(1, 2) = inspect / 2 / true
普通调用时 call message name = nameOf
getSlot("nameOf") call 时 = call
  这个调用有 3 个实参，a = 1
add2(1, 2) = 3
add2(1, 2, 3)（多传） = 3
add2(1)（少传）的异常 = argument 0 to method '+' must be a Number, not a 'nil'
```

```io
inspect := method(a, b,
    list(call message name, call argCount, call target isIdenticalTo(self)) join(" / ")
)
show("inspect(1, 2)", inspect(1, 2))        // inspect / 2 / true

nameOf := method(call message name)
show("普通调用时 call message name", nameOf)          // nameOf
show("getSlot(\"nameOf\") call 时", getSlot("nameOf") call)   // call

args := method(a, writeln("  这个调用有 ", call argCount, " 个实参，a = ", a))
args(1, 2, 3)                               // argCount 是 3，a 只拿到 1

add2 := method(a, b, a + b)
show("add2(1, 2)", add2(1, 2))              // 3
show("add2(1, 2, 3)（多传）", add2(1, 2, 3)) // 3 —— 多的被丢掉
e3 := try(add2(1))
show("add2(1)（少传）的异常", e3 error)       // 用到 nil 才炸
```

四条读法：`call target` 是接收者（等价于 `self`）、`call sender` 是发消息那一帧、
`call message` 是这条消息本身（用 `.call` 叫起来时它的名字就是 `"call"`）、
`call argCount` / `call argAt(i)` 是实参表——**声明了几个形参不影响你看到几个实参**。

元数不匹配不报错：少传的形参就是 `nil`（用到才炸），多传的静默丢掉。

> **为什么重要**：Io 的方法只有位置参数，没有默认值、没有变参语法，
> 所有「变参 / 默认值 / 具名参数」都要靠 `call argCount` 自己在运行时搭。

## 11.9 坑位清单

1. **把 `{ ... }` 当块字面量写** → 本构建里它只会变成没人实现的 `curlyBrackets(...)` 消息，块一律写 `method(...)`。
2. **把块存进槽后想「读出来看看」** → 读槽就是零参调用，要本体用 `getSlot("名字")`。
3. **把块当数据传给别的函数** → `method(...)` 造的块 `isActivatable` 是 `true`，一进形参（形参就是槽）就被调用；要传的块一律用 `block(...)` 造（11.3.1）。典型受害者：`sortBy` 的比较器、`withHandler` 的处理器。
4. **以为闭包把外层的值拷了一份** → 捕获的是上下文对象，外层 `n = 5` 之后块里读到的就是 5。
5. **以为块里的名字按调用处解析** → 按定义处解析；调用帧里的同名局部完全不算数。
6. **在块里用 `:=` 想改外层变量** → `:=` 只造当前帧的局部，改外层要用 `=`。
7. **在 maker 里 `n := 0` 再 `method(n = n + 1)` 造计数器** → maker 一返回局部槽就没了，报 `Object does not respond to 'n'`；用 `setScope` 钉到持久对象上，或把状态放进对象槽。
8. **在 `show` / `chk` 里反复引用一个可激活的槽** → 实参是消息，每引用一次再调一次，断言会把计数器推着走；先取快照。
9. **写 `and(false, bump)` 忘了接收者** → 成了发给 Lobby 的消息，短路失效、`bump` 照样被求值；`and` / `or` 必须发在真值上。
10. **以为少传实参会报参数缺失** → 少传的形参是 `nil`（用到才炸），多传的被静默忽略但 `call argCount` 仍看得见。

---

上一章：[10 · 映射](10-maps.md) · 下一章：[12 · 迭代与集合遍历](12-iteration.md)
