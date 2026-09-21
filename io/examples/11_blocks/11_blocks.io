// ============================================================
// 11_blocks.io —— 第 11 章：块与闭包
// 运行：io examples/11_blocks/11_blocks.io
//
// Io 里没有「函数」也没有独立的「闭包」类型：两者都是 Block。
// Block 既是对象（有槽、能自省），又是消息（一条还没发出的消息）。
// 最要命的一条：槽里放着块，**读这个槽就等于调它**，想拿本体得 getSlot。
// 本章所有结论都在本机 io_static (Io 20260302) 上实测过，
// 包括「这个构建根本没有 {} 块字面量」这条。
// ============================================================

fails := 0
chk := method(tag, got, want,
    if(got asString != want asString,
        fails = fails + 1
        writeln("  [FAIL] ", tag, " 得到 ", got asString, "，期望 ", want asString)
    )
)
sec := method(title, writeln(""); writeln("-- ", title))
show := method(label, value, writeln(label, " = ", value asString))

writeln("==== 11 开始 ====")

sec("11.1 块就是 method(...)：本构建里 {} 不是可用的块字面量")
add := method(a, b, a + b)
show("add(2, 3)", add(2, 3))
show("getSlot(\"add\") type", getSlot("add") type)
show("getSlot(\"add\") argumentNames", getSlot("add") argumentNames)
show("getSlot(\"add\") code", getSlot("add") code)
// 书上常写的 { ... } 在解析层是给接收者发一条 curlyBrackets(...) 消息，
// 而本构建的 Lobby / Object / Core 上都没有这个槽
brace := method({ 1 + 1 })
e1 := try(brace)
show("Message fromString(\"{ 1 + 1 }\")", Message fromString("{ 1 + 1 }"))
show("try({ 1 + 1 }) 的异常", e1 error)
chk("块字面量落到 curlyBrackets 消息上", Message fromString("{ 1 + 1 }") name, "curlyBrackets")
chk("本构建没人实现它", e1 error, "Object does not respond to 'curlyBrackets'")
chk("所以块一律用 method(...) 写", getSlot("add") type, "Block")

sec("11.2 块也是对象：type / isActivatable / argumentNames / code")
show("Block slotNames", Block slotNames sort join(", "))
show("getSlot(\"add\") isActivatable", getSlot("add") isActivatable)
show("getSlot(\"add\") message", getSlot("add") message)
blks := list(method(1), method(2))
(blks at(0)) setArgumentNames(list("q"))
show("setArgumentNames 之后 argumentNames", blks at(0) argumentNames)
show("callWithArgList(list(41))", blks at(0) callWithArgList(list(41)))
show("getSlot(\"add\") call(20, 22)", getSlot("add") call(20, 22))
chk("method(...) 造出来的就是 Block", getSlot("add") type, "Block")
chk("块可以自省出自己的形参名", getSlot("add") argumentNames asString, "list(\"a\", \"b\")")
chk("argumentNames 是槽，可以改", blks at(0) argumentNames asString, "list(\"q\")")
chk("callWithArgList 用表传参", blks at(0) callWithArgList(list(41)), 1)

sec("11.3 槽里的块：读槽就等于调它")
hi := method("hi")
show("hi（读槽）", hi)
show("getSlot(\"hi\") type", getSlot("hi") type)
show("getSlot(\"hi\") code 打出本体", getSlot("hi") code)
holder := Object clone
holder mine := method(call target isIdenticalTo(self))
show("holder mine（方法里的 self 就是接收者）", holder mine)
// 想「返回一个块」时最容易被这条咬到：局部槽里的块同样一读就调
naive := method(
    b := method(7)
    b
)
show("naive 返回的是 7 而不是块", naive)
show("naive type", naive type)
// 要留住块本体，就用容器装（容器不会激活自己的元素）
keeper := method(
    b := list(method(7))
    b
)
show("keeper at(0) type", keeper at(0) type)
show("keeper at(0) call", keeper at(0) call)
chk("读一个普通槽 = 零参调用", hi, "hi")
chk("返回块要绕开激活", naive, 7)
chk("装进 List 就不会被激活", keeper at(0) type, "Block")

sec("11.3.1 method(...) 与 block(...)：isActivatable 决定能不能当数据传")
// 上面那条「装进 List 就不会被激活」只对了一半：容器确实不激活元素，
// 但**元素一旦落进一个槽再被读出来，照样激活**。真正的判据是 isActivatable：
//   method(...) 造的块 → isActivatable = true  → 进槽即被激活
//   block(...)  造的块 → isActivatable = false → 可以安全地当数据传
m := method(1)
b := block(1)
show("getSlot(\"m\") isActivatable", getSlot("m") isActivatable)
show("getSlot(\"b\") isActivatable", getSlot("b") isActivatable)
pair := list(method(1), block(1))
show("容器里第 0 个（method 造的）type", (getSlot("pair")) at(0) type)
show("容器里第 1 个（block 造的）type", (getSlot("pair")) at(1) type)
// 关键的一步：把它取出来交给一个「形参」。形参在 Io 里就是一个槽，
// 所以可激活的块会在这一步被激活，block 造的不会。
echoType := method(x, x type asString)
show("把 method 造的块交给形参", echoType(method(1)))
show("把 block  造的块交给形参", echoType(block(1)))
chk("method 造的块可激活", getSlot("m") isActivatable, true)
chk("block 造的块不可激活", getSlot("b") isActivatable, false)
chk("进容器本身不激活", (getSlot("pair")) at(0) type asString, "Block")
chk("交给形参（= 进槽）就激活了", echoType(method(1)), "Number")
chk("block 造的块过形参仍是块", echoType(block(1)), "Block")

sec("11.4 闭包捕获的是上下文，不是值")
n := 1
getN := method(n)
show("n", n)
show("getN", getN)
n = 5
show("n = 5 之后 getN", getN)
// 换个帧，给一个同名局部，看 getN 听谁的
other := method(
    n := 999
    getN
)
show("别的帧里有局部 n = 999，getN 仍然给", other)
chk("块记的是定义处的上下文", getN, 5)
chk("不是动态作用域：调用处的同名局部不算数", other, 5)

sec("11.5 = 改外层，:= 造局部；do 的槽落在接收者上")
v := 1
updateOuter := method(v = v + 1)
shadow := method(v := 99; v)
updateOuter
show("updateOuter 之后 v", v)
show("shadow 返回", shadow)
show("shadow 之后 v", v)
cat := Object clone
cat do(x := 5)
show("cat hasSlot(\"x\")", cat hasSlot("x"))
show("cat x", cat x)
cat2 := Object clone
cat2 x := 6
show("cat2 x", cat2 x)
r := try(self)
show("顶层裸 self", if(r isKindOf(Exception), "异常：" .. r error, r type))
atTop := method(self isIdenticalTo(Lobby))
show("方法里 self 就是接收者（顶层调用时即 Lobby）", atTop)
show("Lobby proto type", Lobby proto type)
show("Protos slotNames", Protos slotNames sort join(", "))
chk("= 改的是查到的那个槽", v, 2)
chk(":= 造的是自己那一帧的局部，外面看不见", v, 2)
chk("do 把槽定义落在接收者上", cat hasSlot("x"), true)
chk("顶层没有 self，self 只在方法里有", r error, "Object does not respond to 'self'")

sec("11.6 有状态的块：maker 的局部槽活不过 maker")
makeNaive := method(
    c := 0
    method(c = c + 1)
)
naiveCounter := makeNaive
e2 := try(naiveCounter)
show("maker 返回之后再叫这个块", if(e2 isKindOf(Exception), "异常：" .. e2 error, e2 asString))
// 正解一：把块的作用域钉在一个活得够久的对象上
makeCounter := method(
    st := Object clone
    st n := 0
    s := list(method(n = n + 1))
    s at(0) setScope(st)
    s at(0)
)
c1 := makeCounter
c2 := makeCounter
show("c1 第 1 次读", c1)
show("c1 第 2 次读", c1)
show("c2 第 1 次读", c2)
show("c1 第 3 次读", c1)
// 注意：chk 的实参是消息，会在 chk 里再求值一次；
// 对「可激活的槽」来说，断言本身就会推进计数器，所以先取一次快照
s1 := c1
s2 := c2
show("快照 s1（第 4 次读 c1）", s1)
show("快照 s2（第 2 次读 c2）", s2)
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
show("box show", box show)
chk("maker 的 := 局部槽出了 maker 就没了", e2 error, "Object does not respond to 'c'")
chk("两个计数器各有各的状态，没有互相污染", s2, 2)
chk("同一个计数器自己累加", s1, 4)
chk("状态挂对象上也一样", box show, "n=2")

sec("11.7 块 = 一条还没发出的消息：if / and / or 的惰性")
t := 0
bump := method(t = t + 1; "算了")
show("false and(bump)", false and(bump))
show("t", t)
show("true and(bump)", true and(bump))
show("t", t)
show("true or(bump)", true or(bump))
show("t", t)
show("false or(bump)", false or(bump))
show("t", t)
show("if(false, bump)", if(false, bump))
show("t", t)
show("if(true, bump)", if(true, bump))
show("t", t)
// 不写接收者就成了一条发给 Lobby 的消息，短路规则随之消失
show("and(false, bump)（漏写接收者）", and(false, bump))
show("t", t)
chk("and 短路：bump 只在需要时才被求值", t, 4)
chk("参数是消息树，不用就不求值", if(false, bump), false)

sec("11.8 调用现场与元数：call target / sender / message / argCount")
inspect := method(a, b,
    list(call message name, call argCount, call target isIdenticalTo(self)) join(" / ")
)
show("inspect(1, 2)", inspect(1, 2))
nameOf := method(call message name)
show("普通调用时 call message name", nameOf)
show("getSlot(\"nameOf\") call 时", getSlot("nameOf") call)
args := method(a, writeln("  这个调用有 ", call argCount, " 个实参，a = ", a))
args(1, 2, 3)
add2 := method(a, b, a + b)
show("add2(1, 2)", add2(1, 2))
show("add2(1, 2, 3)（多传）", add2(1, 2, 3))
e3 := try(add2(1))
show("add2(1)（少传）的异常", e3 error)
chk("call target 就是接收者", inspect(1, 2), "inspect / 2 / true")
chk("多传实参被静默忽略", add2(1, 2, 3), 3)
chk("少传不报参数缺失，形参是 nil，用到才炸", e3 error,
    "argument 0 to method '+' must be a Number, not a 'nil'")

sec("11.9 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 11 结束 ====")
if(fails != 0, System exit(1))
