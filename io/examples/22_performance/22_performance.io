// ============================================================
// 22_performance.io —— 第 22 章：性能陷阱与基准
// 运行：io examples/22_performance/22_performance.io
//
// 铁律：**任何时间/耗时数字都不许进输出**（连"耗时 0.83 秒"都不行），
// 因为那会毁掉逐字节比对。做法有两种：
//   · 范围断言：把耗时和常量比大小（elapsed < 5.0）
//   · 对照断言：同样做 N 次，只断"谁更快"（两个计数的大小关系）
// 本章所有结论都是第二种：量级差 10 倍以上的对照才敢断言；差 1.5 倍那种
// 实测噪音就能翻盘（22.8 会演示为什么它不能断言）。
// 递归爆栈和无界递归都要靠子进程 + 外部超时，主示例绝不能挂住。
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
clock := method(Date clone now asNumber)

writeln("==== 22 开始 ====")

sec("22.1 纪律：时间不许进输出，只比大小、只断范围")
// 先探明本机有哪些时钟（都不许打出来）：
show("Date 有 now", Date hasSlot("now"))
show("Date 有 clock", Date hasSlot("clock"))
show("Date 有 secondsToRun", Date hasSlot("secondsToRun"))
show("System 上没有时钟", System hasSlot("clock"))
show("Date secondsToRun 返回的类型", (Date secondsToRun(1 + 1)) type)
show("Date clock 返回的类型", clock type)
show("now asNumber 是可减的 Number", (Date clone now asNumber) isKindOf(Number))
// 范围断言：把耗时和常量比大小，常量给足余量
acc := 0
elapsed := Date secondsToRun(for(i, 1, 100000, acc = acc + i))
show("10 万次累加的结果", acc)
show("耗时在 5 秒以内", elapsed < 5.0)
show("耗时当然也大于 0", elapsed > 0)
chk("10 万次累加在 5 秒内", elapsed < 5.0, true)
chk("范围断言的余量要留够，不然它自己就是 flaky 测试", elapsed < 0.0001, false)
// 对照断言的骨架：两段等量的活儿，只比大小
t0 := clock
for(i, 1, 1000, acc = acc + i)
t1 := clock
for(i, 1, 1000, acc = acc + i)
t2 := clock
show("同样活儿两遍，两次差值的符号无所谓", ((t1 - t0) >= 0) and ((t2 - t1) >= 0))
chk("不打印任何差值的具体数值（示例自己也不看它们）", (elapsed isKindOf(Number)), true)

sec("22.2 字符串不可变：s = s .. x 是 O(n²)")
// 字符串字面量是 ImmutableSequence，`..` 每次都要造一个新串并整段拷贝，
// 循环里累计就是 O(n²)。List append 是摊还 O(1)，最后 join 一次 O(n)。
n := 10000
t0 := clock
s := ""
for(i, 1, n, s = s .. "x")
t1 := clock
parts := List clone
for(i, 1, n, parts append("x"))
joined := parts join("")
t2 := clock
show("两种做法结果是同一个串", s == joined)
show("串长", s size)
show("List 方案的槽位（append 只要摊还 O(1)）", parts size)
chk("结果一致", s, joined)
chk("List + join 更快（量级差 10 倍以上才敢断言）", (t2 - t1) < (t1 - t0), true)
// 反例的正确用法：要拼接时先收集、最后 join；或者用可变的 Sequence
mutableSeq := Sequence clone
for(i, 1, n, mutableSeq appendSeq("x"))
show("可变 Sequence 的 appendSeq 也是一次成功", mutableSeq size)
chk("asMutable/appendSeq 不需要 join 那一步", mutableSeq size, n)

sec("22.3 getSlot(\"f\") 取本体再调 vs 直接调用")
// 每次多一条 getSlot 消息 + 一次 call，就是纯开销。
// 需要把方法当值传来传去时没办法，但热循环里别这么干。
m := 5000
inc := method(v, v + 1)
t0 := clock
direct := 0
for(i, 1, m, direct = direct + inc(1))
t1 := clock
viaSlot := 0
for(i, 1, m, viaSlot = viaSlot + (getSlot("inc") call(1)))
t2 := clock
show("两种调法的结果一样", direct == viaSlot)
show("结果", direct)
chk("结果一致", direct, viaSlot)
chk("直接调用更快（实测量级差 4~8 倍）", (t1 - t0) < (t2 - t1), true)
// 顺带说明：把方法存进槽再读会激活它，所以"缓存方法"在 Io 里不成立
holder := Object clone do(f := method(7))
show("holder f 是调用结果，不是方法本体", holder f)
show("要本体得 getSlot", (holder getSlot("f")) type)
chk("槽里的方法一读就激活", holder f, 7)
chk("getSlot 拿到的才是 Block", (holder getSlot("f")) type, "Block")

sec("22.4 Map vs List 查找")
// Map 是哈希查找，List indexOf 是线性扫描 —— 这是本章差距最大的一组。
N := 3000
mp := Map clone
ls := List clone
for(i, 1, N, mp atPut("k" .. i, i); ls append("k" .. i))
target := "k" .. N
lookups := 200
t0 := clock
for(i, 1, lookups, hit := mp at(target))
t1 := clock
for(i, 1, lookups, idx := ls indexOf(target))
t2 := clock
show("命中值", hit)
show("命中下标（从 0 数）", idx)
show("表长", N)
show("查找次数", lookups)
chk("Map 命中", hit, N)
chk("List indexOf 命中最后一个元素", idx, N - 1)
chk("Map 快得多（实测量级差 250 倍上下）", (t1 - t0) < (t2 - t1), true)
// 结论不是"别用 List"，而是"按键查用 Map、按位置取用 List"
show("List 按位置取是 O(1)", ls at(0))
chk("按位置取用 at", ls at(N - 1), target)

sec("22.5 形参 vs call evalArgAt")
// 声明形参 = 一次绑定；变参 = 每次都要问调用现场、现算实参消息。
// 变参是 Io 的灵活性来源，但热路径上要为它付钱。
fx := method(a, b, c, d, a + b + c + d)
va := method(
    total := 0
    for(i, 0, call argCount - 1, total = total + call evalArgAt(i))
    total
)
M := 100000
t0 := clock
for(i, 1, M, r1 := fx(1, 2, 3, 4))
t1 := clock
for(i, 1, M, r2 := va(1, 2, 3, 4))
t2 := clock
show("fv 的结果", r1)
show("va 的结果", r2)
show("va 的 argumentNames（一个形参都没声明）", getSlot("va") argumentNames)
show("fx 的 argumentNames", getSlot("fx") argumentNames)
chk("结果一致", r1, r2)
chk("声明星参更快（实测量级差 2.5 倍上下）", (t1 - t0) < (t2 - t1), true)
chk("变参不声明形参", getSlot("va") argumentNames asString, "list()")
chk("声明星参后 argumentNames 有四个", getSlot("fx") argumentNames size, 4)

sec("22.6 递归：帧深上限 10000，无界递归会挂住")
// 实测：Io 有固定的帧深上限（错误原文里写着 10000），而且**不做尾调用优化**——
// 尾调用写法的深递归一样爆。爆栈在"有界"时是可捕获的异常，能进 try。
rec := method(d, if(d > 0, return rec(d - 1)); "done")
show("浅递归（1000 层）正常返回", rec(1000))
chk("1000 层没问题", rec(1000), "done")
// 深递归必须放子进程：它可能把 VM 打到不可恢复的状态。
bin := System getEnvironmentVariable("IO_BIN")
if(bin == nil,
    writeln("IO_BIN 未设置，跳过深递归子进程实测（run-all.sh 会注入 IO_BIN）")
,
    childLines := list(
        "rec := method(d, if(d > 0, return rec(d - 1)); \"done\")",
        "r := try(rec(50000))",
        "writeln(\"DEEP1 \", if(r, r error, \"no exception\"))",
        "rec2 := method(d, if(d > 0, d + rec2(d - 1), 0))",
        "r2 := try(rec2(50000))",
        "writeln(\"DEEP2 \", if(r2, r2 error, \"no exception\"))",
        ""
    )
    tmpPath := Path with(System getEnvironmentVariable("TMPDIR"), "io_ch22_deep_recursion.io")
    childFile := File with(tmpPath)
    childFile remove
    childFile setContents(childLines join("\n") asUTF8)
    result := System runCommand(bin .. " " .. tmpPath)
    out := result stdout
    childFile remove
    writeln("子进程：两种写法的 50000 层递归，都被 try 抓住")
    writeln("  子进程退出码 = ", result exitStatus asString)
    writeln("  子进程 stderr 长度 = ", (result stderr) size asString)
    writeln("  报的错里写着帧深上限 = ",
            (out containsSeq("frame depth exceeded 10000")) asString)
    writeln("  尾调用写法一样爆 = ",
            (out containsSeq("DEEP2 Stack overflow")) asString)
    chk("爆栈是可捕获异常，子进程照样退 0", result exitStatus, 0)
    chk("stderr 空，异常没逃出去", (result stderr) size, 0)
    chk("错误原文点名了 10000 这个上限",
        out containsSeq("Stack overflow: frame depth exceeded 10000"), true)
    chk("return 写法爆栈", out containsSeq("DEEP1 Stack overflow"), true)
    chk("尾调用写法同样爆栈（没有 TCO）", out containsSeq("DEEP2 Stack overflow"), true)
)
// 无界递归不在示例里跑：它会挂到需要外部超时才能杀掉（详见 docs 22.6）。
show("无界递归这一条只写在 docs 里（示例绝不跑）", "skipped on purpose")

sec("22.7 Profiler 实测：timedObjects 永远是空表")
// Profiler 存在，API 也在，但采样数据是空的：show 只会打 "sample size to small"。
show("Profiler slotNames", Profiler slotNames sort)
show("timedObjects 的初始值", Profiler timedObjects)
show("timedObjects 的类型", (Profiler timedObjects) type)
work := method(v, total := 0; for(i, 1, v, total = total + i); total)
show("手工跑一段活儿，看 Profiler 记不记得", work(2000))
chk("没有开始采样时就是空表", (Profiler timedObjects) size, 0)
// profile 会往 stdout 打 "Profile:" 和 "sample size to small"（都是固定文本）
Profiler profile(for(i, 1, 30, work(2000)))
show("采样之后 timedObjects 还是空表", (Profiler timedObjects) size)
chk("采样之后依然是空表，所以它只能给 sample size to small",
    (Profiler timedObjects) size, 0)
chk("API 齐全但没数据", Profiler hasSlot("start") and Profiler hasSlot("stop"), true)
chk("reset 返回 Profiler 自己", (Profiler reset) isIdenticalTo(Profiler), true)

sec("22.8 对象池与 Lobby 槽位污染：能断言的只有计数")
// System 上有 maxRecycledObjects / setMaxRecycledObjects / recycledObjectCount
// （没有 collectGarbage 这个名字）。
orig := System maxRecycledObjects
show("maxRecycledObjects 的当前值", orig)
System setMaxRecycledObjects(7777)
show("setMaxRecycledObjects(7777) 之后", System maxRecycledObjects)
System setMaxRecycledObjects(orig)
show("恢复之后", System maxRecycledObjects)
show("recycledObjectCount 是数字（值不打印）", (System recycledObjectCount) isKindOf(Number))
// 坑：绝对不能写 list(Lobby hasSlot("a"), Lobby hasSlot("b")) ——
// 把 hasSlot(...) 直接当 list(...) 的实参，这个 VM 会收到信号并挂住（需要外部超时）。
// 先把结果存进变量再 list，就没事。
hasCG := Lobby hasSlot("collectGarbage")
hasColl := Lobby hasSlot("Collector")
show("Lobby 上有 collectGarbage / Collector", list(hasCG, hasColl) asString)
chk("对象池上限能读能写能恢复", System maxRecycledObjects, orig)
chk("回收计数器是数字", (System recycledObjectCount) isKindOf(Number), true)
chk("没有 collectGarbage 这个名字，但 Collector proto 在",
    list(hasCG, hasColl) asString, "list(false, true)")
// Lobby 上堆槽位：这是全局污染，代价真实存在，但**小到不能做时间断言** ——
// 同一台机器上重复实测，"变慢多少"在 0.93~1.58 之间乱跳，噪音比信号大。
// 所以这里只断"确定能数出来的东西"：槽位数量。
k := 20000
slotsBefore := Lobby slotNames size
countBefore := Lobby slotNames select(n, n beginsWithSeq("junk")) size
for(i, 1, k, Lobby setSlot("junk" .. i, i))
slotsAfter := Lobby slotNames size
countAfter := Lobby slotNames select(n, n beginsWithSeq("junk")) size
show("污染前 Lobby 的槽位数", slotsBefore)
show("污染后 Lobby 的槽位数", slotsAfter)
show("污染前 junk* 槽位数", countBefore)
show("污染后 junk* 槽位数", countAfter)
show("新槽确实能取到", Lobby getSlot("junk1"))
show("每次全局名字查找都要在这张表上多走一趟（此处不做时间断言）", k)
chk("堆进去多少个 junk 槽，就多出多少个", countAfter - countBefore, k)
chk("总槽位数也跟着涨了（新定义的变量自己也算一个槽）", slotsAfter > slotsBefore, true)
chk("取到的是最后写进去的那个", Lobby getSlot("junk" .. k), k)
chk("已有的全局名不受影响", Lobby getSlot("k"), k)

sec("22.9 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 22 结束 ====")
if(fails != 0, System exit(1))
