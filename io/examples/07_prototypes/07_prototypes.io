// ============================================================
// 07_prototypes.io —— 第 07 章：原型、槽与克隆
// 运行：io examples/07_prototypes/07_prototypes.io
//
// Io 没有类：对象由**克隆**已有对象产生，行为放在**槽**里，
// 查找沿 proto 链向上走，写入落在最近的那个副本上。
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

writeln("==== 07 开始 ====")

sec("7.1 从 Object clone 出一个对象")
Dog := Object clone
Dog name := "未命名"
Dog speak := method("汪汪，" .. name)
show("Dog name", Dog name)
show("Dog speak", Dog speak)
// clone 出来的副本各有各的槽空间
d1 := Dog clone
d1 name = "阿黄"
show("d1 name", d1 name)
show("Dog name 不受影响", Dog name)
chk("写副本不污染原型", Dog name, "未命名")
chk("副本读得到原型的方法", d1 speak, "汪汪，阿黄")

sec("7.2 三种槽操作符")
o := Object clone
o x := 1
show(":= 定义后 o x", o x)
o x = 2
show("= 更新后 o x", o x)
o y ::= 0
show("::= 生成的 setter 名单", o slotNames select(name, name beginsWithSeq("set")) sort)
o setY(9)
show("setY 之后 o y", o y)
o newSlot("z", 3)
show("newSlot(\"z\", 3) 之后", list(o z, o hasSlot("setZ")) asString)
o setZ(77)
show("setZ(77) 之后 o z", o z)
show(":= 定义过的 x 有 setter 吗", o hasSlot("setX"))
chk(":= 定义", o x, 2)
chk("::= 自动配 setter", o hasSlot("setY"), true)
// ⚠️ newSlot **也**会配 setter —— Io 自己的 Object.io 里就是这么写的：
//    newSlot("foo", 1) would create slot named foo ... as well as a setter method setFoo().
chk("newSlot 同样自动配 setter", o hasSlot("setZ"), true)
chk("newSlot 配的 setter 真能写进去", o z, 77)
// 反过来，:= 不配 setter —— 这一条才是三者里唯一的「只造槽」写法
chk(":= 不配 setter", o hasSlot("setX"), false)

sec("7.3 陷阱：= 不能凭空造槽")
e := try(o w = 1)
show("try(o w = 1) 的异常消息", e error)
chk("未定义的槽不能用 = 赋值", e error, "Slot w not found. Must define slot using := operator before updating.")
// 反过来说：链上有这个槽（继承来的）时，= 会在自己身上生成一个遮蔽副本
Child := Dog clone
Child name = "小白"
show("Child name", Child name)
show("Dog name", Dog name)
chk("= 写在自己的副本上", Dog name, "未命名")

sec("7.4 proto 链：读向左、写在本地")
A := Object clone
A v := 1
B := A clone
show("B v（继承）", B v)
show("B hasLocalSlot(\"v\")", B hasLocalSlot("v"))
show("B hasSlot(\"v\")", B hasSlot("v"))
show("B isKindOf(A)", B isKindOf(A))
show("A isKindOf(B)", A isKindOf(B))
show("B protos size（proto 链的第一个环节）", B protos size)
chk("读走链", B v, 1)
chk("写之前没有本地槽", B hasLocalSlot("v"), false)

sec("7.5 clone 会自动跑 init —— 不想跑就用 cloneWithoutInit")
Counter := Object clone
Counter n := 0
Counter init := method(n = n + 1)
c1 := Counter clone
c2 := Counter clone
c3 := Counter cloneWithoutInit
show("Counter n（原型自己）", Counter n)
show("c1 n / c2 n", list(c1 n, c2 n) asString)
show("c3 n（cloneWithoutInit，没跑 init）", c3 n)
show("c3 hasLocalSlot(\"n\")", c3 hasLocalSlot("n"))
chk("clone 会调用 init", c1 n, 1)
chk("每次 clone 各自跑一次", c2 n, 1)
chk("cloneWithoutInit 不跑 init", c3 hasLocalSlot("n"), false)

sec("7.6 self 与 do：do 临时把 self 换成接收者")
Box := Object clone
Box v := 10
Box describe := method("v = " .. v asString)
show("Box describe（方法里的 v 走 self）", Box describe)
// do 把一段代码块的 self 指到接收者上，所以块里的 := 落在对象上
Box do(u := 99)
show("do 之后 Box slotNames 含 u", Box slotNames contains("u"))
show("Box u", Box u)
chk("do 里的赋值落在对象上", Box u, 99)
// 不用 do 时，:= 落在当前上下文，而不是 Box
Other := Object clone
Other u := 1
show("Other u 仍是自己的 1", Other u)
chk("do 不是可有可无的糖", Other u, 1)

sec("7.7 removeSlot / slotNames 排序")
t := Object clone
t a := 1
t b := 2
t c := 3
show("槽名（排序后）", t slotNames sort)
t removeSlot("b")
show("removeSlot(\"b\") 之后", t slotNames sort)
show("hasSlot(\"b\")", t hasSlot("b"))
chk("槽名顺序在 Io 里是哈希序，比较前必须 sort", t slotNames sort asString, "list(\"a\", \"c\")")

sec("7.8 asString 覆盖：让对象能安全地拼进字符串")
pt := Object clone
pt x := 3
pt y := 4
pt asString := method("(" .. x asString .. "," .. y asString .. ")")
show("pt 直接拼", "pt = " .. pt)
// 没覆盖 asString 的对象，拼出来是「槽位摘要 + 地址」，而地址每次运行都不同
show("未覆盖 asString 的对象拼出来含地址", (Object clone) asString containsSeq("0x"))
writeln("所以只要输出要进判定区间，就必须覆盖 asString 或改用显式 asString")
chk("覆盖 asString 后 .. 得到可控文本", "pt = " .. pt, "pt = (3,4)")
chk("未覆盖时 asString 里是地址", (Object clone) asString containsSeq("0x"), true)

sec("7.9 陷阱：do(...) 里的槽定义不能用逗号分隔")
// 逗号在 Io 里是「实参分隔符」，do(m := 1, n := 2) 会被解析成
//   do(setSlot("m", 1), setSlot("n", 2))
// 也就是**两个实参**。而 do 只求值第一个实参（C 源码里 Object 的 do 注册时
// 调了 IoState_markSlotLazyArgs_，第二个起的实参连求值都不会发生）。
show("do(m := 1, n := 2) 的解析树", Message fromString("do(m := 1, n := 2)"))
Bad := Object clone do(m := 1, n := 2)
Good := Object clone do(m := 1; n := 2)
show("用逗号：Bad 有 m", Bad hasSlot("m"))
show("用逗号：Bad 有 n", Bad hasSlot("n"))
show("用分号：Good 有 m", Good hasSlot("m"))
show("用分号：Good 有 n", Good hasSlot("n"))
// 第二个实参不是「跑到别处去了」，而是**根本没被求值**：给它塞个副作用就知道
Lobby removeSlot("dummyProbe")
Side := Object clone do(k := 1, Lobby dummyProbe := 5)
show("第二个实参里的副作用发生了吗", Lobby hasLocalSlot("dummyProbe"))
chk("逗号版本丢了一个槽", Bad hasSlot("n"), false)
chk("分号版本两个都在", Good hasSlot("n"), true)
chk("多出来的实参连求值都不会发生", Lobby hasLocalSlot("dummyProbe"), false)

sec("7.10 陷阱：do 只接得到 Lobby 的槽，看不到本方法的局部槽")
// do(...) 把作用域切到接收者：里面能看见 <接收者> 和 Lobby，
// 但**看不见定义它的那个方法的局部槽**。要在词法环境里求值必须 lexicalDo。
Lobby globalProbe := 9
probeFactory := method(
    localProbe := 8
    r := Object clone
    fromDo := Object clone do(p := globalProbe)
    r setSlot("doSawGlobal", fromDo p)
    e := try(Object clone do(p := localProbe))
    r setSlot("doLocalError", e error)
    fromLexical := Object clone lexicalDo(p := localProbe)
    r setSlot("lexicalSawLocal", fromLexical p)
    r
)
probe := probeFactory
show("do 里读 Lobby 槽", probe doSawGlobal)
show("do 里读方法局部槽的异常", probe doLocalError)
show("lexicalDo 里读方法局部槽", probe lexicalSawLocal)
// 老实用 setSlot 把值送出去也行，只是不如 lexicalDo 顺手
setSlotFactory := method(
    localProbe := 7
    o := Object clone
    o setSlot("p", localProbe)
    o
)
show("显式 setSlot 也读得到局部槽", setSlotFactory p)
chk("do 里能看见 Lobby 槽", probe doSawGlobal, 9)
chk("do 里看不见方法局部槽", probe doLocalError, "Object does not respond to 'localProbe'")
chk("lexicalDo 才读得到局部槽", probe lexicalSawLocal, 8)
chk("显式 setSlot 同样可行", setSlotFactory p, 7)

sec("7.11 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 07 结束 ====")
if(fails != 0, System exit(1))
