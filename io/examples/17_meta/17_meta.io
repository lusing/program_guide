// ============================================================
// 17_meta.io —— 第 17 章：元编程与反射
// 运行：io examples/17_meta/17_meta.io
//
// Io 的对象就是「一堆槽 + 一条 proto 链」，所以元编程不是高级技巧，
// 而是唯一的手法：读槽、写槽、删槽、把消息树当数据、把字符串当代码。
// 本章的坑几乎都在作用域与编译单元上：do(...) 里看不到外层方法的形参、
// OperatorTable 只对新编译单元生效、槽里的 Block 一读出来就自动激活。
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

writeln("==== 17 开始 ====")

sec("17.1 槽的内省：slotNames / hasSlot / hasLocalSlot")
o := Object clone do(
    zeta := 1
    alpha := 2
    mid := 3
    beta := 4
)
writeln("slotNames 原样（哈希序）= ", o slotNames join(","))
writeln("sort 之后 = ", o slotNames sort join(","))
chk("slotNames 是哈希序，比较前必须 sort", o slotNames sort join(","), "alpha,beta,mid,zeta")
p := Object clone
q := p clone
q setSlot("x", 1)
show("p hasSlot(\"x\")", p hasSlot("x"))
show("q hasSlot(\"x\")", q hasSlot("x"))
show("q hasLocalSlot(\"x\")", q hasLocalSlot("x"))
show("q hasSlot(\"slotNames\") 命中的是继承来的槽", q hasSlot("slotNames"))
show("q hasLocalSlot(\"slotNames\")", q hasLocalSlot("slotNames"))
chk("hasSlot 沿 proto 链找", q hasSlot("slotNames"), true)
chk("hasLocalSlot 只看自己这一层", q hasLocalSlot("slotNames"), false)
chk("clone 出来的槽各管各的", p hasSlot("x"), false)

sec("17.2 槽的读写删：getSlot / setSlot / removeSlot / isActivatable")
t := Object clone
t setSlot("data", 5)
t setSlot("double", method(n, n * 2))
show("t getSlot(\"data\")", t getSlot("data"))
show("t getSlot(\"double\") asSimpleString", t getSlot("double") asSimpleString)
show("数据槽 isActivatable", t getSlot("data") isActivatable)
show("方法槽 isActivatable", t getSlot("double") isActivatable)
e := try(t double)
show("直接读 double（等价零参调用）的报错", e error)
show("getSlot 绕过激活拿到本体再 call(21)", (t getSlot("double")) call(21))
show("setSlot 之前 hasLocalSlot(\"brand\")", t hasLocalSlot("brand"))
t setSlot("brand", "io")
show("setSlot 凭空造槽之后的值", t getSlot("brand"))
t removeSlot("data")
show("removeSlot 之后 hasLocalSlot(\"data\")", t hasLocalSlot("data"))
show("getSlot 问不存在的槽", t getSlot("nope"))
chk("isActivatable 区分数据与代码", t getSlot("data") isActivatable, false)
chk("getSlot 绕过激活", (t getSlot("double")) call(21), 42)
chk("setSlot 可以凭空造槽", t getSlot("brand"), "io")
chk("removeSlot 真的删掉了", t hasLocalSlot("data"), false)
chk("getSlot 对不存在的槽给 nil，不报错", t getSlot("nope"), nil)

sec("17.3 proto 链：proto / protos / appendProto / setProto / ancestors")
A := Object clone do(who := method("A"))
B := Object clone do(who := method("B"))
show("B who（自己的槽先命中）", B who)
show("B protos size", B protos size)
show("B proto isIdenticalTo(Object)", B proto isIdenticalTo(Object))
show("B ancestors size", B ancestors size)
B appendProto(A)
show("appendProto(A) 之后的 protos size", B protos size)
show("B who 还是自己的那一个", B who)
B removeProto(A)
show("removeProto(A) 之后的 protos size", B protos size)
C := Object clone do(who := method("C"))
C setProto(A)
show("setProto(A) 之后 protos size", C protos size)
show("C proto isIdenticalTo(A)", C proto isIdenticalTo(A))
show("setProto 是替换不是追加，C who 仍是自己的", C who)
writeln("同一性：== 与 isIdenticalTo")
show("  A isIdenticalTo(A)", A isIdenticalTo(A))
show("  A isIdenticalTo(A clone)", A isIdenticalTo(A clone))
show("  A == (A clone)", A == (A clone))
show("  \"ab\" == \"ab\"", "ab" == "ab")
show("  list(1,2) == list(1,2)", list(1, 2) == list(1, 2))
show("  1 == 1.0", 1 == 1.0)
chk("appendProto 之后是两个 proto", B protos size, 1)
chk("setProto 是替换", C protos size, 1)
chk("对象的 == 就是同一性", A == (A clone), false)
chk("序列的 == 比内容", list(1, 2) == list(1, 2), true)
// removeAllProtos 会把 Object 一起摘掉，对象从此什么消息都不响应
Frame := Object clone
show("Frame hasSlot(\"appendProto\") 之前", Frame hasSlot("appendProto"))
Frame removeAllProtos
e2 := try(Frame hasSlot("protos"))
show("removeAllProtos 之后连 hasSlot 都不响应", e2 error)
chk("removeAllProtos 会摘掉 Object", e2 isNil, false)

sec("17.4 运行时造方法：Message fromString / doInContext / setSlot")
bb := Message fromString("method(n, n * 3)") doInContext(Lobby)
show("解出来的 type", getSlot("bb") type)
show("它的形参表", getSlot("bb") argumentNames)
show("它自己 isActivatable", getSlot("bb") isActivatable)
show("getSlot 拿本体再 call(7)", getSlot("bb") call(7))
e0 := try(bb)
show("直接写 bb（等价零参调用）的报错", e0 error)
writeln("注意：下面凡是碰 bb 的地方都写 getSlot(\"bb\")——槽里装着 Block，直接读 bb 就是调用它")
target := Object clone do(n := 0)
target setSlot("triple", Message fromString("method(n, n * 3)") doInContext(target))
show("setSlot 装进去之后 target triple(6)", target triple(6))
tm := Message fromString("n := 41")
target doMessage(tm)
show("doMessage 执行 n := 41 之后 target n", target getSlot("n"))
show("Message fromString 也认得未注册的运算符名", Message fromString("a <=> b"))
chk("doInContext 解出的就是 Block", getSlot("bb") type, "Block")
chk("直接读槽得到的是「调用结果」不是方法本体", e0 error, "nil does not respond to '*'")
chk("getSlot 绕过激活才是调用", getSlot("bb") call(7), 21)
chk("动态装进对象槽的方法能正常调", target triple(6), 18)
chk("doMessage 在接收者上下文里执行消息树", target getSlot("n"), 41)

sec("17.5 把字符串当编译单元：Lobby doString / Lobby doFile")
// 注意：doString 的源码串必须是纯 ASCII。串里混进非 ASCII，内部会升成 UCS4，
// 词法器按字节读就错位了（见下面的实测）。
Lobby doString("Chapter17Made := Object clone do(tag := method(\"from doString\"))")
show("纯 ASCII 源码：doString 造出的 proto", Chapter17Made tag)
show("doString 的返回值就是最后一个表达式的值", Lobby doString("1 + 2"))
show("纯 ASCII 源码的 sizeInBytes", "Chapter17Made := Object clone do(tag := method(\"from doString\"))" sizeInBytes)
badSrc := "Chapter17Bad := Object clone do(tag := method(\"" .. "中" .. "\"))"
show("含非 ASCII 的源码 size / sizeInBytes", badSrc size asString .. " / " .. badSrc sizeInBytes asString)
try(Lobby doString(badSrc))
show("含非 ASCII 的 doString 之后 Chapter17Bad 有没有被定义", Lobby hasSlot("Chapter17Bad"))
writeln("含非 ASCII 的源码内部是 UCS4（每码点 4 字节），词法器按字节读就错位了；")
writeln("它有时抛异常、有时静默执行成一段完全不相干的东西，总之不可依赖。")
tmpDir := System getEnvironmentVariable("TMPDIR")
tmpFile := Path with(tmpDir, "io_ch17_meta_tmp.io")
f := File with(tmpFile)
f remove
// 必须 asUTF8：含非 ASCII 的串内部是 UCS4，setContents 会原样倒出 4 字节一码点
f setContents("Chapter17FromFile := Object clone do(tag := method(\"from doFile\"))\n")
show("临时文件的 basename", tmpFile lastPathComponent)
show("临时文件的字节数", f size)
Lobby doFile(tmpFile)
show("doFile 之后文件里定义的 proto 能用", Chapter17FromFile tag)
f remove
show("删掉之后文件还在吗", File with(tmpFile) exists)
chk("doString 返回最后一个表达式的值", Lobby doString("1 + 2"), 3)
chk("纯 ASCII 的 doString 能定义槽", Lobby hasSlot("Chapter17Made"), true)
chk("含非 ASCII 的 doString 定义不出槽", Lobby hasSlot("Chapter17Bad"), false)
chk("doFile 里 do(...) 的槽能装好", Chapter17FromFile tag, "from doFile")
chk("临时文件已清理", File with(tmpFile) exists, false)

sec("17.6 OperatorTable：注册只对新编译单元生效")
ops := OperatorTable operators
show("注册前 operators 里有 <=> 吗", ops hasKey("<=>"))
OperatorTable addOperator("<=>", 4)
show("注册后 operators 里有 <=> 吗", OperatorTable operators hasKey("<=>"))
show("注册后的优先级", OperatorTable operators at("<=>"))
Comparable := Object clone do(<=> := method(o, "比较结果"))
// 本行与上面的 addOperator 在**同一个编译单元**（整个文件一次性解析），
// 解析时表里还没有 <=>，于是它被拆成一串普通消息，结果是接收者本身。
r := Comparable <=> Comparable
show("同一编译单元里 Comparable <=> Comparable 是不是接收者", r isIdenticalTo(Comparable))
// 换个编译单元（doString 会重新解析）就生效
show("Lobby doString 里就认了", Lobby doString("Comparable clone <=> Comparable clone"))
show("Message fromString 也是新编译单元", Message fromString("Comparable clone <=> Comparable clone"))
show("赋值运算符表（注意不在 operators 里）", OperatorTable assignOperators keys sort join(" "))
OperatorTable addAssignOperator("__=", "setMeta")
show("addAssignOperator 之后", OperatorTable assignOperators keys sort join(" "))
show("addAssignOperator 会进 operators 表吗", OperatorTable operators hasKey("__="))
show("优先级层数", OperatorTable precedenceLevelCount)
chk("同编译单元内注册的运算符不生效", r isIdenticalTo(Comparable), true)
chk("换编译单元后生效", Lobby doString("Comparable clone <=> Comparable clone"), "比较结果")
chk("赋值运算符单独一张表", OperatorTable operators hasKey("="), false)

sec("17.7 forward：接管未定义消息，手写一个委托 proto")
plain := Object clone
e3 := try(plain noSuchThing(1, 2))
show("没有 forward 时的报错", e3 error)
Delegator := Object clone do(
    target := nil
    forward := method(
        t := self getSlot("target")
        if(t == nil, Exception raise("还没绑定 target"))
        t doMessage(call message, call sender)
    )
)
real := Object clone do(
    greet := method(n, "你好 " .. n)
    hello := method("大家好")
    total := method(a, b, a + b)
)
d := Delegator clone
d setSlot("target", real)
show("d hasLocalSlot(\"greet\")", d hasLocalSlot("greet"))
show("委托一元消息 d greet(\"Io\")", d greet("Io"))
show("委托带参消息 d total(2, 3)", d total(2, 3))
show("perform 也走 forward", d perform("hello"))
e4 := try(Delegator clone greet("x"))
show("没绑 target 时的报错", e4 error)
chk("forward 接住未定义消息", d greet("Io"), "你好 Io")
chk("参数一起带过去", d total(2, 3), 5)
chk("委托对象自己没有那个槽", d hasLocalSlot("greet"), false)
chk("Object 上确实有 forward 这个槽", Object hasSlot("forward"), true)

sec("17.8 perform 与一个 DSL 小例")
o8 := Object clone do(add := method(a, b, a + b); zero := method(0))
show("perform(\"add\", 1, 2)", o8 perform("add", 1, 2))
show("performWithArgList(\"add\", list(3, 4))", o8 performWithArgList("add", list(3, 4)))
show("零参 perform(\"zero\")", o8 perform("zero"))
e5 := try(o8 perform("nope"))
show("perform 一个不存在的名字", e5 error)
Person := Object clone do(
    name := "无名"
    age := 0
    named := method(n, a,
        p := self clone
        p setSlot("name", n)
        p setSlot("age", a)
        p
    )
    sayHello := method("你好，我是 " .. name)
    describe := method(name .. "（" .. age asString .. " 岁）")
)
alice := Person named("阿艾", 3)
show("alice sayHello", alice sayHello)
show("alice describe", alice describe)
alice setSlot("shout", method(sayHello .. "！"))
show("动态加了一个 shout 之后", alice shout)
show("alice slotNames sort", alice slotNames sort join(","))
makeGetter := method(obj, field,
    obj setSlot("get_" .. field, obj doString("method(" .. field .. ")"))
)
makeGetter(alice, "age")
show("代码生成的 getter：alice get_age()", alice get_age)
shoutValue := alice shout
alice removeSlot("shout")
show("removeSlot 之后 hasLocalSlot(\"shout\")", alice hasLocalSlot("shout"))
chk("perform 与直接发消息等价", o8 perform("add", 1, 2), 3)
chk("performWithArgList 用 List 传参", o8 performWithArgList("add", list(3, 4)), 7)
chk("DSL 风格的构造器", alice describe, "阿艾（3 岁）")
chk("运行时加的方法能调", shoutValue, "你好，我是 阿艾！")
chk("生成的 getter 能读到数据槽", alice get_age, 3)
chk("数据槽本身没有被覆盖", alice getSlot("age") isActivatable, false)
chk("removeSlot 之后方法真的没了", alice hasLocalSlot("shout"), false)

sec("17.9 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 17 结束 ====")
if(fails != 0, System exit(1))
