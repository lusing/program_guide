// ============================================================
// 08_methods.io —— 第 08 章：方法
// 运行：io examples/08_methods/08_methods.io
//
// 方法 = 带作用域（self）的可调用对象；参数只有位置，没有默认值、没有变参，
// 缺什么就用 call 去问调用现场。方法体里的多条语句用 **分号或换行** 分隔。
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

writeln("==== 08 开始 ====")

sec("8.1 定义与调用：位置参数，没有默认值")
add := method(a, b, a + b)
show("add(2, 3)", add(2, 3))
show("方法体是最后一个表达式的值", getSlot("add") call(1, 2))
// 少传参数不会报「参数缺失」：形参就是 nil，等真正用到它时才炸
e := try(add(2))
show("try(add(2)) 的异常消息", e error)
second := method(a, b, b)
show("把形参直接返回出来才看得见 nil：second(1)", second(1))
chk("少传参数不报参数缺失，形参就是 nil", second(1), nil)
chk("用到 nil 才炸", e error, "argument 0 to method '+' must be a Number, not a 'nil'")

sec("8.2 陷阱：内联方法后面直接跟括号，方法会被整个丢掉")
// (method(...))(x) 不是「调用这个内联方法」，而是「两个相邻的括号组」
show("(1 + 1)(5)", (1 + 1)(5))
show("(method(a, b, b))(1) 的结果", (method(a, b, b))(1))
show("它的解析树", Message fromString("(method(a, b, b))(1)"))
show("(method(a, b, b)) call(1)", (method(a, b, b)) call(1))
chk("两个相邻括号组，值取后一个", (1 + 1)(5), 5)
chk("内联方法被丢掉，结果就是实参本身", (method(a, b, b))(1), 1)
chk("加 .call 才是真的在调它", (method(a, b, b)) call(1), nil)

sec("8.3 Io 没有默认参数：自己判 nil")
// 写 method(a, b := 10, ...) 不会得到默认值，而是把 := 解析成一条 setSlot 消息
show("messageTree", Message fromString("method(a, b := 10, a + b)"))
withDefault := method(a, b := 10, a + b)
show("withDefault argumentNames", getSlot("withDefault") argumentNames)
e3 := try(withDefault(1, 2))
show("withDefault(1, 2) 的异常消息", e3 error)
chk(":= 变成了一个假的形参名", getSlot("withDefault") argumentNames asString,
    "list(\"a\", \"setSlot\")")
chk("调用时就找不到 b 了", e3 error, "Object does not respond to 'b'")
// 正确写法：形参用 nil 兜底
greet := method(name, if(name == nil, name = "匿名"); "你好，" .. name)
show("greet", greet)
show("greet(\"Io\")", greet("Io"))
chk("nil 兜底才是 Io 的「默认参数」", greet, "你好，匿名")
chk("传了就不覆盖", greet("Io"), "你好，Io")

sec("8.4 变参：用 call 现场取")
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

sec("8.5 声明形参后仍能摸到多余实参")
tail := method(first,
    parts := List clone
    for(i, 1, call argCount - 1, parts append(call evalArgAt(i)))
    first .. "|" .. parts join(",")
)
show("tail(1, 2, 3)", tail(1, 2, 3))
show("tail(1)", tail(1))
chk("第 2 个起算多余实参", tail(1, 2, 3), "1|2,3")
chk("没有多余实参时拼接后是空串", tail(1), "1|")

sec("8.6 call 给的是调用现场的全部信息")
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

sec("8.7 return 与提前退出")
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
chk("return 直接离开方法", classify(-1), "负数")
chk("块里的 return 一样能穿出来", find(list(1, 2, 3), 2), true)
chk("走完整条路才落到最后一句", find(list(1, 2, 3), 9), false)

sec("8.8 陷阱：槽里的方法被「读出来」时自动激活")
double := method(n, n * 2)
// 直接写 double 不是「取这个方法」，而是「调用这个方法」——形参 n 是 nil
e4 := try(double)
show("try(double) 的异常消息", e4 error)
// 要拿方法本体必须走 getSlot（标准库源码里到处是 getSlot("...") 就是这个原因）
show("getSlot(\"double\") asSimpleString", getSlot("double") asSimpleString)
show("isActivatable", getSlot("double") isActivatable)
apply := method(f, f(21))
show("apply(getSlot(\"double\"))", apply(getSlot("double")))
chk("槽里的方法默认可激活", getSlot("double") isActivatable, true)
chk("拿本体要 getSlot 绕过激活", apply(getSlot("double")), 42)
chk("直接读 slot 等于零参调用", e4 error, "nil does not respond to '*'")

sec("8.9 方法是一等值：可以装进容器、当参数传")
double2 := method(n, n * 2)
inc := method(n, n + 1)
fns := list(getSlot("double2"), getSlot("inc"))
show("fns size", fns size)
show("按顺序调用", list(fns at(0) call(10), fns at(1) call(10)) asString)
show("用 perform 调对象上的方法", (Object clone do(m := method(7))) perform("m"))
chk("方法能装进 List", fns size, 2)
chk("取出来还能调", fns at(1) call(10), 11)
chk("perform 按名字发消息", (Object clone do(m := method(7))) perform("m"), 7)

sec("8.10 方法体语句分隔符：逗号和分号不是一回事")
// 逗号是「形参分隔符」：下面两个写法形参个数不同
twoArgs := method(a, b, a + b)
twoStmts := method(a, b, x := a + b; x * 2)
show("twoArgs argumentNames", getSlot("twoArgs") argumentNames)
show("twoArgs(1, 2)", twoArgs(1, 2))
show("twoStmts(1, 2)", twoStmts(1, 2))
chk("逗号进的是形参表", getSlot("twoArgs") argumentNames asString, "list(\"a\", \"b\")")
chk("分号才是语句分隔，返回值是最后一条", twoStmts(1, 2), 6)

sec("8.11 code / argumentNames：方法能自省出自己的消息树")
show("double argumentNames", getSlot("double") argumentNames)
show("double code", getSlot("double") code)
show("把 code 重新解析回来再调",
     (Message fromString("method(n, n * 3)")) doInContext(Lobby) call(7))
chk("code 打印的是消息树", getSlot("double") code asString, "method(n, n *(2))")
chk("消息树可以被重新解析", (Message fromString("method(n, n * 3)")) doInContext(Lobby) call(7), 21)

sec("8.12 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 08 结束 ====")
if(fails != 0, System exit(1))
