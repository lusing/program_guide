// ============================================================
// 06_messages.io —— 第 06 章：消息、运算符与内省
// 运行：io examples/06_messages/06_messages.io
//
// Io 里没有表达式，只有**消息**：接收者 + 名字 + 参数（参数本身也是消息）。
// 操作符只是名字特殊的消息，优先级由 OperatorTable 这张表决定。
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

writeln("==== 06 开始 ====")

sec("6.1 三种消息形状")
writeln("一元消息（无参，优先级最高）：", list(1, 2, 3) size)
writeln("二元消息（操作符）：", 2 + 3)
writeln("关键字消息（带参数）：", 1 max(2))
// 混合时的绑定顺序：一元 > 关键字 > 二元操作符（**与 Smalltalk 相反**）
show("1 + 2 max(3) 的解析", 1 + 2 max(3))
show("1 + (2 max(3))", 1 + (2 max(3)))
show("(1 + 2) max(3)", (1 + 2) max(3))
chk("带参消息比 + 绑得紧", 1 + 2 max(3), 4)
chk("要改结合顺序只能加括号", (1 + 2) max(3), 3)

sec("6.2 消息链是左结合的")
obj := Object clone do(
    a := 5
    add := method(n, self a = self a + n; self)
    value := method(a)
)
show("obj add(1) add(2) value", obj add(1) add(2) value)
show("链的写法等价于 ((obj add(1)) add(2)) value", obj value)
chk("链式调用靠返回 self 串起来", obj value, 8)

sec("6.3 操作符就是消息：可以 perform 出来")
show("2 + 3", 2 + 3)
show("(2) perform(\"+\", 3)", 2 perform("+", 3))
show("performWithArgList(\"max\", list(9))", 2 performWithArgList("max", list(9)))
listOps := Object clone do(cat := method(a, b, a .. b))
show("自定义名字也能 perform", listOps perform("cat", "ab", "cd"))
chk("+ 与 perform(\"+\") 完全等价", 2 perform("+", 3), 5)

sec("6.4 优先级表：数字越小绑得越紧")
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

sec("6.5 自定义运算符：注册管不到同一个编译单元")
// 优先级 4 左右是常规二元运算符的位置
OperatorTable addOperator("<=>", 4)
Comparable := Object clone do(<=> := method(o, "比较结果"))
// 本行与上面的 addOperator 属于**同一个编译单元**（同一个文件一次性解析），
// 解析时表里还没有 <=>，所以它被当成一连串普通消息，结果就是接收者本身。
r := Comparable <=> Comparable
show("同文件里 Comparable <=> Comparable 的结果是不是接收者", r isIdenticalTo(Comparable))
chk("同文件内注册的运算符不生效", r isIdenticalTo(Comparable), true)
// 换个编译单元（doString 会重新解析）就生效了
show("Lobby doString(\"... <=> ...\")", Lobby doString("Comparable clone <=> Comparable clone"))
chk("换编译单元后运算符生效", Lobby doString("Comparable clone <=> Comparable clone"), "比较结果")

sec("6.6 call 与消息对象：在方法里看清自己是怎么被调的")
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

sec("6.7 Message 对象：消息可以被构造、被存下来、被重新发一次")
o := Object clone do(greet := method("hi"))
m := Message clone setName("greet")
show("手工构造的消息 doMessage 到对象上", o doMessage(m))
show("从字符串解析一条消息再求值", (Message fromString("1 + 2 * 3")) doInContext(Lobby))
show("把已有消息的 next 摘下来看名字", m name)
chk("doMessage 触发的是普通消息发送", o doMessage(m), "hi")
chk("Message fromString 走完整解析", (Message fromString("1 + 2 * 3")) doInContext(Lobby), 7)

sec("6.8 resend 与 super：调用被覆盖的实现")
Base := Object clone do(describe := method("Base"))
// 注意：do(...) 里定义多个槽要用 **分号或换行** 分隔。
// 逗号是实参分隔符，do 只求值第一个实参，第二个槽定义会被静默丢掉（见 7.9）。
Child := Base clone do(
    describe := method("Child(" .. resend .. ")");
    describeViaSuper := method("Child(" .. super(describe) .. ")")
)
show("Child describe（resend）", Child describe)
show("Child describeViaSuper（super）", Child describeViaSuper)
show("Base describe 不受影响", Base describe)
chk("resend 回到父实现", Child describe, "Child(Base)")
chk("super 显式指定消息名", Child describeViaSuper, "Child(Base)")

sec("6.9 陷阱：.. 会调 asString，普通对象给的是地址")
obj2 := Object clone
// obj2 .. "x" 会拼出 Object_0x... 这样的地址 —— 地址每次都变，绝不能进判定区间
show("obj2 .. \"x\" 的长度大于 0", (obj2 .. "x") size > 0)
show("(obj2 asString) 的槽位摘要里有地址", obj2 asString size > 0)
writeln("所以拼接前一定要自己控制 asString 的内容（见 07 章的 asString 覆盖）")
chk(".. 走的是 asString", "n=" .. 7, "n=7")

sec("6.10 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 06 结束 ====")
if(fails != 0, System exit(1))
