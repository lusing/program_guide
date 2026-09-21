// ============================================================
// 12_iteration.io —— 第 12 章：迭代与集合遍历
// 运行：io examples/12_iteration/12_iteration.io
//
// 遍历在 Io 里也是一条消息：集合收到 foreach(...)，体是消息树，
// 集合决定怎么解释那几个名字。没有 Iterator 接口，只有「回不回得了 foreach」。
// 最值钱的一条：foreach 的体跑在你的帧里（赋值看得见），
// map / select / detect / reduce 的体跑在一个临时 context 上（赋值看不见）。
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

writeln("==== 12 开始 ====")

sec("12.1 foreach 的三种形状：名字绑的是值还是下标")
list(10, 20, 30) foreach(v, show("  foreach(v, ...) 的 v", v))
list(10, 20, 30) foreach(i, v, show("  foreach(i, v, ...) 的 i / v", i asString .. " / " .. v asString))
tick := List clone
list(10, 20, 30) foreach(tick append("t"))
show("foreach(只有体) 触发次数", tick size)
show("map(v, v)", list(10, 20, 30) map(v, v) asString)
show("map(i, v, i)", list(10, 20, 30) map(i, v, i) asString)
show("map(i, v, v)", list(10, 20, 30) map(i, v, v) asString)
show("list(...) foreach 的返回值", list(10, 20, 30) foreach(v, nil) asString)
chk("2 参时那个名字绑的是值", list(10, 20, 30) map(v, v) asString, "list(10, 20, 30)")
chk("3 参时第一个名字才是下标", list(10, 20, 30) map(i, v, i) asString, "list(0, 1, 2)")
chk("靠 argCount 区分形状，不是靠名字", list(10, 20, 30) map(i, v, v) asString, "list(10, 20, 30)")
chk("foreach 自己不返回值", list(10, 20, 30) foreach(v, nil) asString, "nil")

sec("12.2 while / for / loop 与 break / continue")
i := 0
while(i < 3, writeln("  while i = ", i); i = i + 1)
for(j, 0, 2, writeln("  for j = ", j))
for(j, 0, 6, 2, writeln("  for 带步长 j = ", j))
k := 0
loop(
    k = k + 1
    if(k >= 3, break)
    writeln("  loop k = ", k)
)
m := 0
while(m < 5,
    m = m + 1
    if(m == 3, continue)
    writeln("  continue 跳过了 3，m = ", m)
)
broken := List clone
list(1, 2, 3, 4) foreach(v, if(v == 3, break); broken append(v))
skipped := List clone
list(1, 2, 3, 4) foreach(v, if(v == 2, continue); skipped append(v))
show("foreach + break 收到", broken asString)
show("foreach + continue 收到", skipped asString)
show("Break / Continue 的 type", Break type .. " / " .. Continue type)
show("Break hasSlot(\"isBreak\")", Break hasSlot("isBreak"))
show("Continue hasSlot(\"isContinue\")", Continue hasSlot("isContinue"))
show("while 返回最后一轮体的值", while(m < 7, m = m + 1))
show("for 不带步长时返回", (for(q, 0, 1, nil)) asString)
chk("break 是对象，不是关键字", Break type, "Break")
chk("continue 也是对象，靠它自己知道是不是 continue", Continue type, "Continue")
chk("break 提前收工", broken asString, "list(1, 2)")
chk("continue 只跳这一轮", skipped asString, "list(1, 3, 4)")

sec("12.3 map / select / detect / reduce：语义与返回类型")
src := list(1, 2, 3, 4)
show("src", src asString)
show("map(v, v * 2)", src map(v, v * 2) asString)
show("select(v, v % 2 == 0)", src select(v, v % 2 == 0) asString)
show("detect(v, v > 2)", src detect(v, v > 2))
show("detect(v, v > 9)", src detect(v, v > 9) asString)
show("reduce(+)", src reduce(+))
show("reduce(a, b, a - b)", src reduce(a, b, a - b))
show("reduce(a, b, a .. b)", list("x", "y", "z") reduce(a, b, a .. b) asString)
show("reverseReduce(a, b, a - b)", src reverseReduce(a, b, a - b))
show("调用一圈之后 src 还是", src asString)
show("空表 map", list() map(v, v) asString)
show("空表 select", list() select(v, true) asString)
show("空表 detect", list() detect(v, true) asString)
show("空表 reduce(+)", list() reduce(+) asString)
chk("map 返回新 List", src map(v, v * 2) asString, "list(2, 4, 6, 8)")
chk("select 返回新 List，原表不动", src select(v, v % 2 == 0) asString, "list(2, 4)")
chk("detect 返回命中的那个元素", src detect(v, v > 2), 3)
chk("detect 没命中就是 nil", src detect(v, v > 9) asString, "nil")
chk("reduce(+) 从第二个元素起往累加器里折", src reduce(+), 10)
chk("reduce(a, b, 体) 才能用任意二元运算", src reduce(a, b, a - b), -8)
chk("reverseReduce 就是 reverse 之后 reduce", src reverseReduce(a, b, a - b), -2)
chk("空表 detect / reduce 都给 nil，不报错", list() reduce(+) asString, "nil")

sec("12.4 大坑：foreach 的体改得了外层变量，map 的体改不了")
sa := 0
list(10, 20, 30) foreach(v, sa = sa + v)
show("foreach 跑完之后 sa", sa)
sb := 0
folded := list(10, 20, 30) map(v, sb = sb + v)
show("map 跑完之后 sb", sb)
show("而 map 的结果本身是", folded asString)
sc := 0
list(10, 20, 30) select(v, sc = sc + v; true)
show("select 跑完之后 sc", sc)
sd := 0
list(10, 20, 30) foreach(sd = sd + 1)
show("连 1 参的 foreach(体) 也一样看不见", sd)
chk("foreach 的体在自己的帧里跑，赋值看得见", sa, 60)
chk("map 的体跑在一个临时 context 上，外层看不到", sb, 0)
chk("那个临时 context 在 map 内部是共享的，于是结果是累加和", folded asString, "list(10, 30, 60)")
chk("select / detect / reduce 的体同病相怜", sc, 0)
chk("只有写成 foreach(v, 体) / foreach(i, v, 体) 才绑进调用帧", sd, 0)

sec("12.5 遍历时改集合会怎样")
l := list(1, 2, 3, 4, 5)
seen := List clone
l foreach(i, v,
    seen append(v)
    if(v == 3, l removeAt(i))
)
show("删掉 3 之后 l", l asString)
show("这一轮实际访问到的元素", seen asString)
grow := list(1, 2, 3)
steps := 0
grow foreach(v,
    steps = steps + 1
    if(steps > 8, break)
    grow append(v + 100)
)
show("一边遍历一边 append 之后的 grow", grow asString)
show("迭代了多少次", steps)
chk("遍历中删除会让下标错位，元素 4 被跳过", seen asString, "list(1, 2, 3, 5)")
chk("遍历中追加会被这一轮循环看见，必须自己加护栏", steps, 9)

sec("12.6 造序列：List with / Number repeat / 游标")
show("List with(1, 2, 3)", List with(1, 2, 3) asString)
show("List hasSlot(\"range\")", List hasSlot("range"))
show("List 上带生成意味的槽", list("with", "fill", "range", "repeat") select(n, List hasSlot(n)) asString)
show("Number 上带生成意味的槽", list("repeat", "to", "range") select(n, Number hasSlot(n)) asString)
3 repeat(i, writeln("  3 repeat i = ", i))
total := 0
5 repeat(i, total = total + i)
show("5 repeat 之后 total", total)
cur := list(10, 20, 30) cursor
show("cursor type", cur type)
show("一开始 cur value", cur value)
show("next 一次之后 cur value", (cur next; cur value))
show("再 next 一次之后 cur value", (cur next; cur value))
show("走到头的 next", cur next)
chk("这个构建没有 List range，要自己用 repeat / with 造", List hasSlot("range"), false)
chk("Number repeat 是 0 起、开区间", total, 10)
chk("游标走不动时 next 返回 false", cur next, false)

sec("12.7 Sequence 的遍历：split 拿到什么，foreach 给的是什么")
parts := "a,b,c" split(",")
show("split 的返回类型", parts type)
show("split(\",\") 的结果", parts asString)
parts foreach(p, show("  一个 part", p))
show("\"a,,c\" split(\",\")", "a,,c" split(",") asString)
show("\"a,,c\" splitNoEmpties(\",\")", "a,,c" splitNoEmpties(",") asString)
chars := List clone
"abc" foreach(i, c, chars append(c))
show("逐个遍历 \"abc\" 收到的东西", chars asString)
show("它们的 type", (chars at(0)) type)
show("要字符得自己转", (chars at(0)) asCharacter)
chk("split 返回的是 List", parts type, "List")
chk("split 保留空段", "a,,c" split(",") size, 3)
chk("splitNoEmpties 才丢空段", "a,,c" splitNoEmpties(",") asString, "list(\"a\", \"c\")")
chk("Sequence 的 foreach 给的是码点，不是字符", chars asString, "list(97, 98, 99)")

sec("12.8 自定义可迭代对象：协议靠消息，不靠接口")
// 只要回得了 foreach(v, 体) / foreach(i, v, 体) / foreach(体) 这三个形状，
// 它就和 List 一样能被同一段代码遍历 —— Io 里没有 Interface 这种东西。
Bag := Object clone do(
    items := nil
    init := method(items = List clone; self)
    add := method(x, items append(x); self)
    size := method(items size)
    foreach := method(
        n := call argCount
        ctx := Object clone prependProto(call sender)
        if(n == 1,
            body := call argAt(0)
            items foreach(x, ctx doMessage(body))
        ,
            if(n == 2,
                eName := call argAt(0) name
                body := call argAt(1)
                items foreach(x, ctx setSlot(eName, x); ctx doMessage(body))
            ,
                iName := call argAt(0) name
                eName := call argAt(1) name
                body := call argAt(2)
                idx := -1
                items foreach(x,
                    idx = idx + 1
                    ctx setSlot(iName, idx)
                    ctx setSlot(eName, x)
                    ctx doMessage(body)
                )
            )
        )
        self
    )
)
bag := Bag clone init
bag add("甲")
bag add("乙")
bag add("丙")
show("bag size", bag size)
bagOut := List clone
bag foreach(v, bagOut append(v))
listOut := List clone
list("甲", "乙", "丙") foreach(v, listOut append(v))
show("bag foreach(v, ...) 收到", bagOut asString)
show("list(...) foreach(v, ...) 收到", listOut asString)
idxOut := List clone
bag foreach(i, v, idxOut append(i asString .. ":" .. v asString))
show("bag foreach(i, v, ...) 收到", idxOut asString)
tick := List clone
bag foreach(tick append("tick"))
show("bag foreach(只有体) 触发次数", tick size)
// 手写的 Io 级 foreach 和 map 一样把体放在临时 context 上跑，赋值出不去
acc := 0
bag foreach(v, acc = acc + 1)
show("在自定义 foreach 里给外层变量赋值之后 acc", acc)
list(1, 2) foreach(v, acc = acc + 1)
show("换成 List foreach 同样写法之后 acc", acc)
// 预告：块 + 协程 = 惰性序列，yield 让出一个值后还能原地接着跑（第 18 章）
show("Coroutine hasSlot(\"yield\")", Coroutine hasSlot("yield"))
show("File hasSlot(\"foreachLine\")（逐行读，见第 14 章）", File hasSlot("foreachLine"))
chk("自定义对象和 List 用同一个 foreach(v, ...) 形状", bagOut asString, listOut asString)
chk("三个形状都实现了", idxOut asString, "list(\"0:甲\", \"1:乙\", \"2:丙\")")
chk("1 参形式只提供体，不绑名字", tick size, 3)
chk("手写 foreach 的体和 map 一样，赋值落不到外层", acc, 2)

sec("12.9 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 12 结束 ====")
if(fails != 0, System exit(1))
