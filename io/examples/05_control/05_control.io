// ============================================================
// 05_control.io —— 第 05 章：控制流
// 运行：io examples/05_control/05_control.io
//
// 核心一句：Io 里 if / while / for / and / or **都不是语法**，是方法。
// 之所以能像语法一样用，是因为消息的参数在 Io 里是**消息树**，
// 而这些方法在实现里选择性地求值参数 —— 于是可以短路、可以少算分支。
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

writeln("==== 05 开始 ====")

sec("5.1 真值：只有 nil 和 false 是假")
show("if(nil,   \"真\", \"假\")", if(nil, "真", "假"))
show("if(false, \"真\", \"假\")", if(false, "真", "假"))
show("if(0,     \"真\", \"假\")", if(0, "真", "假"))
show("if(\"\",    \"真\", \"假\")", if("", "真", "假"))
show("if(空list,\"真\", \"假\")", if(list(), "真", "假"))
chk("0 是真值（C 程序员头号坑）", if(0, "真", "假"), "真")
chk("空串也是真值", if("", "真", "假"), "真")

sec("5.2 if 的三种写法")
x := 7
if(x > 5, writeln("两臂式：x > 5"), writeln("两臂式：x <= 5"))
if(x > 5) then(writeln("then/else 式：大")) else(writeln("then/else 式：小"))
writeln("单臂式没有 else 也合法：", if(x > 5, "ok"))
// if 返回被选中分支的值，所以能当三元表达式用
show("if(cond, a, b) 是表达式", if(x > 5, "yes", "no"))
// 只写 then 时它等价于 cond and(then)：条件为假直接返回假值本身
show("if(true,  \"yes\")", if(true, "yes"))
show("if(false, \"yes\")", if(false, "yes"))
show("if(nil,   \"yes\")", if(nil, "yes"))
chk("if 有返回值", if(x > 5, 1, 2), 1)
chk("两参 if 为假时返回假值本身，不是 nil", if(false, "yes"), false)

sec("5.3 if 只求值被选中的分支")
side := method(tag, writeln("  求值了 ", tag); tag)
writeln("下面只会打印被选中那一边的『求值了':")
if(true, side("then 分支"), side("else 分支"))
chk("未选中的分支不求值", side("唯一被调用的"), "唯一被调用的")

sec("5.4 and / or 短路，not 是槽不是方法")
show("true and false", true and false)
show("true or false", true or false)
show("true not", true not)
show("nil not", nil not)
show("Object not（普通对象取反给 nil）", Object clone not)
// 短路：右边是消息，只有需要时才被求值
show("false and(true)", false and(true))
show("false and(noSuchSlot)", false and(noSuchSlot))
show("true or(noSuchSlot)", true or(noSuchSlot))
chk("and 短路，右边不存在的槽不会报错", false and(noSuchSlot), false)
chk("or 短路", true or(noSuchSlot), true)

sec("5.5 ifTrue / ifFalse / ifNil / ifNilEval")
show("(1 > 0) ifTrue(\"是\")", (1 > 0) ifTrue("是"))
show("(1 < 0) ifTrue(\"是\")", (1 < 0) ifTrue("是"))
show("(1 < 0) ifFalse(\"否\")", (1 < 0) ifFalse("否"))
// 关键区别：ifNil / ifNonNil 只负责「触发/不触发」，返回值恒是接收者；
// 要拿默认值得用 ifNilEval / ifNonNilEval。
show("nil ifNil(\"d\")", nil ifNil("d"))
show("nil ifNilEval(\"d\")", nil ifNilEval("d"))
show("5 ifNilEval(\"d\")", 5 ifNilEval("d"))
show("5 ifNonNilEval(\"d\")", 5 ifNonNilEval("d"))
show("nil ifNonNilEval(\"d\")", nil ifNonNilEval("d"))
v := nil
v ifNilEval(v = "补上的默认值")
show("v ifNilEval(v = ...) 之后", v)
chk("ifNil 返回接收者", nil ifNil("d"), nil)
chk("要默认值只能用 ifNilEval", nil ifNilEval("d"), "d")
chk("非 nil 时 ifNilEval 不碰参数", 5 ifNilEval("d"), 5)

sec("5.6 while / for / loop")
i := 0
while(i < 3, write(i); i = i + 1)
writeln("  ← while 循环体写成一条消息链，多条语句用 ;")
// for 上界是**闭区间**（打到就停，不是 C 的 <）
for(j, 1, 3, write(j, " "))
writeln("  ← for(j, 1, 3) 打了 3 次")
k := 0
loop(k = k + 1; if(k >= 3, break); write("loop", k, " "))
writeln("  ← loop 是无条件循环，靠 break 出来")
chk("while 打到条件不成立", i, 3)
chk("for 上界闭区间，共 3 次", k, 3)

sec("5.7 for 的四参形式与 break / continue")
for(j, 0, 9, 2, write(j, " "))
writeln("  ← for(j, 起点, 终点, 步长)")
acc := List clone
for(j, 0, 5, if(j == 2, continue); if(j == 4, break); acc append(j))
show("跳过 2、遇到 4 就停", acc)
chk("continue / break 都不求值剩余部分", acc asString, "list(0, 1, 3)")

sec("5.8 return 与循环的返回值")
findFirst := method(items, target,
    items foreach(ix, v, if(v == target, return ix))
    -1
)
show("findFirst(list(5,6,7), 6)", findFirst(list(5, 6, 7), 6))
show("findFirst(list(5,6,7), 99)", findFirst(list(5, 6, 7), 99))
// 方法体里最后一个表达式的值就是返回值
last := method(list(1, 2, 3))
show("方法返回值 = 最后一个表达式", last)
chk("return 从方法里跳出", findFirst(list(5, 6, 7), 6), 1)

sec("5.9 switch：接收者为键的查表控制流")
code := "b"
result := code switch(
    "a", "苹果",
    "b", "香蕉",
    "c", "樱桃",
    "未知"
)
show("code switch(...)", result)
chk("switch 命中分支", result, "香蕉")
chk("switch 落空返回兜底值", "z" switch("a", "苹果", "兜底"), "兜底")

sec("5.10 ?消息：能响应才发")
o := Object clone do(greet := method("你好"))
show("o ?greet", o ?greet)
show("o ?noSuchSlot", o ?noSuchSlot)
chk("? 对不存在的槽返回 nil，不报错", o ?noSuchSlot, nil)
chk("? 对存在的槽照常调用", o ?greet, "你好")

sec("5.11 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 05 结束 ====")
if(fails != 0, System exit(1))
