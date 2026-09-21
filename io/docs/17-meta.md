# 17 · 元编程与反射

> 对应示例：[`examples/17_meta/17_meta.io`](../examples/17_meta/17_meta.io)

## 17.1 槽的内省：slotNames / hasSlot / hasLocalSlot

先看清对象身上有什么。`slotNames` 给的是**本地**槽名，顺序是哈希序（每次运行都一样，但不是字典序），要比较必须先 `sort`；`hasSlot` 沿 proto 链找，`hasLocalSlot` 只看这一层。

```text
-- 17.1 槽的内省：slotNames / hasSlot / hasLocalSlot
slotNames 原样（哈希序）= mid,alpha,zeta,beta
sort 之后 = alpha,beta,mid,zeta
p hasSlot("x") = false
q hasSlot("x") = true
q hasLocalSlot("x") = true
q hasSlot("slotNames") 命中的是继承来的槽 = true
q hasLocalSlot("slotNames") = false
```

```io
o := Object clone do(
    zeta := 1
    alpha := 2
    mid := 3
    beta := 4
)
writeln("slotNames 原样（哈希序）= ", o slotNames join(","))
writeln("sort 之后 = ", o slotNames sort join(","))
p := Object clone
q := p clone
q setSlot("x", 1)
show("p hasSlot(\"x\")", p hasSlot("x"))
show("q hasLocalSlot(\"slotNames\")", q hasLocalSlot("slotNames"))
```

`slotNames` 只数本地槽，但 `hasSlot` 会命中从 `Object` 继承来的 `slotNames`——把这两个搞混，写断言时就会得到「明明没有却返回 true」。

> **为什么重要**：Io 没有 `respondsTo`，判断「能不能发这条消息」的唯一手段就是 `hasSlot`；而要判断「这个槽是不是我自己定义的」，只能用它的小弟 `hasLocalSlot`。

## 17.2 槽的读写删：getSlot / setSlot / removeSlot / isActivatable

`setSlot` 可以凭空造槽，`removeSlot` 真的删掉，`getSlot` 对不存在的槽给 `nil` 而不报错。真正容易踩的是**激活**：槽里装的是 Block 时，读出来等于调用它。

```text
-- 17.2 槽的读写删：getSlot / setSlot / removeSlot / isActivatable
t getSlot("data") = 5
t getSlot("double") asSimpleString = method(n, ...)
数据槽 isActivatable = false
方法槽 isActivatable = true
直接读 double（等价零参调用）的报错 = nil does not respond to '*'
getSlot 绕过激活拿到本体再 call(21) = 42
setSlot 之前 hasLocalSlot("brand") = false
setSlot 凭空造槽之后的值 = io
removeSlot 之后 hasLocalSlot("data") = false
getSlot 问不存在的槽 = nil
```

```io
t := Object clone
t setSlot("data", 5)
t setSlot("double", method(n, n * 2))
show("数据槽 isActivatable", t getSlot("data") isActivatable)
e := try(t double)
show("直接读 double（等价零参调用）的报错", e error)
show("getSlot 绕过激活拿到本体再 call(21)", (t getSlot("double")) call(21))
```

`isActivatable` 就是「这个槽读出来会不会被调用」的判定；`getSlot` 读出来不激活，所以标准库源码里到处是 `getSlot("...")`。

> **为什么重要**：元编程的第一条反射纪律——**要拿方法本体，一律走 `getSlot`**。直接写名字就是调用，形参全是 `nil`，报出来的错离现场十万八千里。

## 17.3 proto 链与同一性：proto / protos / appendProto / setProto / ancestors

一个对象可以有多条 proto。`appendProto` 追加、`removeProto` 摘掉、`setProto` **替换**（不是追加）；`ancestors` 给出整条链；`removeAllProtos` 会把 `Object` 一起摘掉，对象从此什么消息都不响应。

```text
-- 17.3 proto 链：proto / protos / appendProto / setProto / ancestors
B who（自己的槽先命中） = B
B protos size = 1
B proto isIdenticalTo(Object) = true
B ancestors size = 5
appendProto(A) 之后的 protos size = 2
B who 还是自己的那一个 = B
removeProto(A) 之后的 protos size = 1
setProto(A) 之后 protos size = 1
C proto isIdenticalTo(A) = true
setProto 是替换不是追加，C who 仍是自己的 = C
同一性：== 与 isIdenticalTo
  A isIdenticalTo(A) = true
  A isIdenticalTo(A clone) = false
  A == (A clone) = false
  "ab" == "ab" = true
  list(1,2) == list(1,2) = true
  1 == 1.0 = true
Frame hasSlot("appendProto") 之前 = true
removeAllProtos 之后连 hasSlot 都不响应 = 'Frame' does not respond to message 'hasSlot'
```

```io
B := Object clone do(who := method("B"))
B appendProto(A)
B removeProto(A)
C := Object clone do(who := method("C"))
C setProto(A)
show("C proto isIdenticalTo(A)", C proto isIdenticalTo(A))
Frame := Object clone
Frame removeAllProtos
e2 := try(Frame hasSlot("protos"))
show("removeAllProtos 之后连 hasSlot 都不响应", e2 error)
```

`==` 对普通对象就是同一性（`A == (A clone)` 是 false），对序列/数字才是比内容；要判「是不是同一个对象」用 `isIdenticalTo`，语义最直白。

> **为什么重要**：`removeAllProtos` 之后对象连 `hasSlot` 都发不出去，调试时会以为解释器坏了。改 proto 链之前先想清楚要不要留 `Object`。

## 17.4 运行时造方法：Message fromString / doInContext / setSlot

把 `method(...)` 写成字符串、解析成消息树、在某上下文里求值，就得到一个 Block；再 `setSlot` 装进对象槽，就凭空长出一个方法。

```text
-- 17.4 运行时造方法：Message fromString / doInContext / setSlot
解出来的 type = Block
它的形参表 = list("n")
它自己 isActivatable = true
getSlot 拿本体再 call(7) = 21
直接写 bb（等价零参调用）的报错 = nil does not respond to '*'
注意：下面凡是碰 bb 的地方都写 getSlot("bb")——槽里装着 Block，直接读 bb 就是调用它
setSlot 装进去之后 target triple(6) = 18
doMessage 执行 n := 41 之后 target n = 41
Message fromString 也认得未注册的运算符名 = a <=> b
```

```io
bb := Message fromString("method(n, n * 3)") doInContext(Lobby)
show("getSlot 拿本体再 call(7)", getSlot("bb") call(7))
target := Object clone do(n := 0)
target setSlot("triple", Message fromString("method(n, n * 3)") doInContext(target))
show("setSlot 装进去之后 target triple(6)", target triple(6))
tm := Message fromString("n := 41")
target doMessage(tm)
```

`doMessage(消息, 上下文)` 是「在某个接收者上重放一条消息」，`doInContext(上下文)` 是「把这棵消息树求值」。

> **为什么重要**：`Message` 是**一等数据**——可以构造、存进容器、事后重放。所有 Io 的 DSL 与代码生成都建立在这一个事实上。

## 17.5 把字符串当编译单元：Lobby doString / Lobby doFile

`Lobby doString(s)` 把字符串当一整个新编译单元解析并求值，返回最后一个表达式的值；`Lobby doFile(p)` 同理，只不过源码来自文件。

```text
-- 17.5 把字符串当编译单元：Lobby doString / Lobby doFile
纯 ASCII 源码：doString 造出的 proto = from doString
doString 的返回值就是最后一个表达式的值 = 3
纯 ASCII 源码的 sizeInBytes = 64
含非 ASCII 的源码 size / sizeInBytes = 51 / 204
含非 ASCII 的 doString 之后 Chapter17Bad 有没有被定义 = false
含非 ASCII 的源码内部是 UCS4（每码点 4 字节），词法器按字节读就错位了；
它有时抛异常、有时静默执行成一段完全不相干的东西，总之不可依赖。
临时文件的 basename = io_ch17_meta_tmp.io
临时文件的字节数 = 67
doFile 之后文件里定义的 proto 能用 = from doFile
删掉之后文件还在吗 = false
```

```io
Lobby doString("Chapter17Made := Object clone do(tag := method(\"from doString\"))")
show("doString 的返回值就是最后一个表达式的值", Lobby doString("1 + 2"))
// 含非 ASCII 的源码：词法器按字节读 UCS4，直接错位
badSrc := "Chapter17Bad := Object clone do(tag := method(\"" .. "中" .. "\"))"
try(Lobby doString(badSrc))
show("含非 ASCII 的 doString 之后 Chapter17Bad 有没有被定义", Lobby hasSlot("Chapter17Bad"))
```

**doString 的源码串必须是纯 ASCII**：串里混进非 ASCII，Io 会把字符串内部升级成 UCS4（每码点 4 字节），而词法器按字节读，于是整段源码被切碎。实测里它有时抛异常、有时静默执行成完全不相干的东西。

> **为什么重要**：`doString` 是 Io 里「重新开一次编译」的最短路径，也是绕过 `OperatorTable` 注册时效的官方姿势（见 17.6）。但它对编码极其敏感，中文注释/字符串一律别放进去。

## 17.6 OperatorTable：注册只对新编译单元生效

`OperatorTable addOperator(name, precedence)` 改的是解析器要用的表。**当前文件已经解析过了**，所以在同一个文件里写的 `a <=> b` 不会被当成运算符；换个编译单元（`doString`、`Message fromString`）才认。

```text
-- 17.6 OperatorTable：注册只对新编译单元生效
注册前 operators 里有 <=> 吗 = false
注册后 operators 里有 <=> 吗 = true
注册后的优先级 = 4
同一编译单元里 Comparable <=> Comparable 是不是接收者 = true
Lobby doString 里就认了 = 比较结果
Message fromString 也是新编译单元 = Comparable clone <=>(Comparable clone)
赋值运算符表（注意不在 operators 里） = ::= := =
addAssignOperator 之后 = ::= := = __=
addAssignOperator 会进 operators 表吗 = false
优先级层数 = 32
```

```io
OperatorTable addOperator("<=>", 4)
Comparable := Object clone do(<=> := method(o, "比较结果"))
r := Comparable <=> Comparable            // 同一编译单元 → 不生效
show("同一编译单元里 Comparable <=> Comparable 是不是接收者", r isIdenticalTo(Comparable))
show("Lobby doString 里就认了", Lobby doString("Comparable clone <=> Comparable clone"))
OperatorTable addAssignOperator("__=", "setMeta")
```

赋值运算符（`:=` / `=` / `::=`）在**另一张表** `OperatorTable assignOperators` 里，`addAssignOperator` 只往那张表加，不会出现在 `operators` 里。

> **为什么重要**：想在脚本里自定义运算符，就得接受「本文件的其余部分用不了它」。要么把注册放进配置文件、让业务代码在别的编译单元里，要么用 `doString` 现解析现用。

## 17.7 forward：接管未定义消息，手写一个委托 proto

消息找不到槽时会退回 `forward`。给它换一个实现，就得到一个能接管任意消息的转发器。

```text
-- 17.7 forward：接管未定义消息，手写一个委托 proto
没有 forward 时的报错 = Object does not respond to 'noSuchThing'
d hasLocalSlot("greet") = false
委托一元消息 d greet("Io") = 你好 Io
委托带参消息 d total(2, 3) = 5
perform 也走 forward = 大家好
没绑 target 时的报错 = 还没绑定 target
```

```io
Delegator := Object clone do(
    target := nil
    forward := method(
        t := self getSlot("target")
        if(t == nil, Exception raise("还没绑定 target"))
        t doMessage(call message, call sender)
    )
)
d := Delegator clone
d setSlot("target", real)
show("委托带参消息 d total(2, 3)", d total(2, 3))
```

`forward := method(...)` 确实能接管未定义消息，而且**参数一起带过来**（`call message` 就是原消息本身，用 `doMessage` 原样转投）。`perform` 走的也是同一条路。

> **为什么重要**：`forward` 是 Io 唯一的「方法缺失」钩子，也是 `FutureProxy` 能拦截任意槽访问的底层机制（见 18.6、19.3）。写委托/代理/模拟对象全靠它。

## 17.8 perform 与一个 DSL 小例

`perform(name, args...)` 与 `performWithArgList(name, list(...))` 把「方法名」当数据用；再配合 `setSlot` 和 `doString`，就能运行时给对象长出方法。

```text
-- 17.8 perform 与一个 DSL 小例
perform("add", 1, 2) = 3
performWithArgList("add", list(3, 4)) = 7
零参 perform("zero") = 0
perform 一个不存在的名字 = Object does not respond to 'nope'
alice sayHello = 你好，我是 阿艾
alice describe = 阿艾（3 岁）
动态加了一个 shout 之后 = 你好，我是 阿艾！
alice slotNames sort = age,name,shout
代码生成的 getter：alice get_age() = 3
removeSlot 之后 hasLocalSlot("shout") = false
```

```io
alice := Person named("阿艾", 3)
alice setSlot("shout", method(sayHello .. "！"))
makeGetter := method(obj, field,
    obj setSlot("get_" .. field, obj doString("method(" .. field .. ")"))
)
makeGetter(alice, "age")
show("代码生成的 getter：alice get_age()", alice get_age)
```

注意生成的 getter 名字叫 `get_age` 而不是 `age`——直接覆盖数据槽，方法体里的 `age` 会解析到方法自己，变成无限递归。

> **为什么重要**：`Person clone do(name := ...; sayHello := ...)` 这种写法之所以看着像 DSL，就是因为它真的只是「克隆 + 往槽里塞东西」。理解了这一点，配置式代码就不再神秘。

## 17.9 坑位清单

1. **`slotNames` 是哈希序** → 拿它做断言前必须先 `sort`，否则两个内容相同的对象比不过。
2. **`hasSlot` 沿 proto 链找，`hasLocalSlot` 只看本层** → 判断「是不是继承来的」要用后者。
3. **`clone` 出来的对象不共享槽** → `q := p clone; q x := 1` 之后 `p hasSlot("x")` 仍是 false。
4. **槽里的 Block 一读出来就激活** → 要拿方法本体必须 `getSlot("名字")`，否则等于零参调用。
5. **`getSlot` 对不存在的槽给 `nil` 不报错** → 它不会替你发现拼错的名字，别把 `nil` 当「槽存在」。
6. **`setProto` 是替换不是追加** → 想保留原来的 proto 要用 `appendProto`。
7. **`removeAllProtos` 会把 `Object` 一起摘掉** → 之后连 `hasSlot` 都发不出去，报 `'X' does not respond to message 'hasSlot'`。
8. **`do(...)` 里看不到外层方法的形参** → `Object clone do(x := v)` 在方法体内会报 `Object does not respond to 'v'`；改成先 `clone` 再 `setSlot`。
9. **`doString` 的源码必须纯 ASCII** → 混进非 ASCII 会因 UCS4 内部表示被按字节读取而错位，可能抛异常也可能静默执行成别的东西。
10. **`OperatorTable addOperator` 只对新编译单元生效** → 同一文件里注册完立刻用会走样（实测返回的是接收者）；要现注册现用就走 `Lobby doString` 或 `Message fromString`。

---

上一章：[16 · 文本处理](16-text.md) · 下一章：[18 · 协程与 Future](18-coroutines.md)
