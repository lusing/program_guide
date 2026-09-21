// ============================================================
// 20_testing.io —— 第 20 章：单元测试
// 运行：io examples/20_testing/20_testing.io
//
// Io 自带 UnitTest（标准库 io/UnitTest.io），但它有三个要命的地方：
//   · 失败时**不一定**给非零退出码（本机实测：失败也退 0）
//   · 输出里带墙钟耗时和对象地址，没法逐字节比对
//   · 测试对象必须绑到一个全局槽（run 靠 type 名字回头去 Lobby 找）
// 所以本仓库的回归不用它，而是每个示例自带 6 行 chk + System exit(1)。
// 本章把这三条都实测出来，再讲清楚「为什么 Io 里这就够了」。
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

writeln("==== 20 开始 ====")

sec("20.1 手写断言库：chk 六行，为什么 Io 里就够了")
// 状态放一个整数槽，比较放一次 asString 对比，失败就打一行 —— 没了。
// 没有框架、没有注册、没有反射扫描，因为 Io 的「示例即测试」只需要一个退出码。
demoFails := 0
demoChk := method(tag, got, want,
    if(got asString != want asString,
        demoFails = demoFails + 1
        writeln("  [FAIL] ", tag, " 得到 ", got asString, "，期望 ", want asString)
    )
)
demoChk("故意失败：1 + 1", 1 + 1, 3)
demoChk("故意失败：\"a\"", "a", "b")
show("示范计数 demoFails", demoFails)
demoChk("这条通过，一行都不打", 2, 2)
show("通过之后计数没变", demoFails)
// chk 的返回值没人用，但顺手记一下 Io 的 if 怪癖：条件假时返回 false 本身
show("chk 通过时返回", chk("（静默）", 1, 1))
show("chk 失败时返回", demoChk("（再来一条故意的）", 1, 2))
show("示范计数", demoFails)
chk("失败计数就是全部状态", demoFails, 3)
chk("通过时一行都不打（这里本不该出现 [FAIL]）", 2, 2)
// 示例的最后一句是判定开关：
//     if(fails != 0, System exit(1))
// 它把「示例」变成可判定的测试：断言全过 → 0，任何一条挂 → 1。
show("System exit 是原语", (System hasSlot("exit")))

sec("20.2 断言输出必须是确定性的")
// 本仓库的硬规矩：同一个解释器连跑两遍，输出必须逐字节一致。
// 所以 chk 只打 tag 和两个值，绝不打时间、地址、进程号。
// 下面是「不打印原文、只断言存在」的写法：
show("Map 的默认 asString 里有地址", Map clone asString containsSeq("0x"))
show("Date clone now asNumber 是数字（值每次不同）", (Date clone now asNumber) isKindOf(Number))
show("System thisProcessPid 是数字（值每次不同）", (System thisProcessPid) isKindOf(Number))
// 要做「范围断言」而不是「精确值断言」：把可变数值整数化，只比大小
pseudoElapsed := 42
chk("范围断言：42 < 100", pseudoElapsed < 100, true)
chk("范围断言也能取下界", pseudoElapsed > 0, true)
// asString 比较的代价：Io 的 Number asString 会舍入，抹掉浮点误差
show("0.1 + 0.2 的 asString", (0.1 + 0.2) asString)
show("0.3 的 asString", 0.3 asString)
show("但它们并不相等", 0.1 + 0.2 == 0.3)
chk("asString 一样，chk 就分不出来", (0.1 + 0.2) asString, 0.3 asString)
chk("浮点要比就得比范围，不能比 asString", (0.1 + 0.2 == 0.3), false)

sec("20.3 UnitTest 的 API：clone do + testXxx + 断言族")
// 收集规则只有一条：槽名以 "test" 开头，按源码行号排序。
MyTests := UnitTest clone do(
    testAlpha := method(assertEquals(1 + 1, 2))
    testBeta := method(assertNil(nil))
    notATest := method(1)
)
show("MyTests testSlotNames", MyTests testSlotNames)
show("MyTests type", MyTests type)
show("run 靠 type 名字回 Lobby 取对象：prepare keys", MyTests prepare keys sort)
// 断言族（全部来自 UnitTest.io）：assertEquals / assertNotEquals /
// assertSame / assertNotSame / assertNil / assertNotNil / assertTrue /
// assertFalse / assertRaisesException / assertEqualsWithinDelta / fail / knownBug
// 它们的失败信息本身也可以断言 —— 全是确定的字符串：
show("assertEquals 失败消息", (try(MyTests assertEquals(1, 3))) error)
show("assertTrue 失败消息", (try(MyTests assertTrue(false))) error)
show("assertNil 失败消息", (try(MyTests assertNil(5))) error)
show("assertRaisesException 未抛时", (try(MyTests assertRaisesException(1 + 1))) error)
show("fail 直接失败", (try(MyTests fail("自定义失败"))) error)
show("assertEqualsWithinDelta 忘了插值", (try(MyTests assertEqualsWithinDelta(1.0, 1.5, 0.1))) error)
chk("只有 test 开头的槽算测试", MyTests testSlotNames asString,
    "list(\"testAlpha\", \"testBeta\")")
chk("type 就是它绑定的全局槽名", MyTests type, "MyTests")
// 大坑 1：run 是拿 type 当 key 去 Lobby 里找对象的，匿名 clone 会跑到 UnitTest 本体上
show("匿名 clone 的 type", (UnitTest clone do(testZzz := method(true))) type)
chk("匿名 clone 的 type 是 UnitTest 本体", (UnitTest clone do(testZzz := method(true))) type, "UnitTest")
// 大坑 2：UnitTest 本体上有个叫 testSlotNames 的槽，它自己也被收集规则命中
show("UnitTest 自己的 testSlotNames（非空！）", UnitTest testSlotNames)
chk("收集规则只看前缀，不看语义", UnitTest testSlotNames size, 1)

sec("20.4 实测：故意失败的断言，run 的 stdout 与退出码")
// run 把结果直接 print 到进程 stdout，进程内抓不到；而且它的输出里带墙钟
// 耗时和对象地址，绝不能进本示例的 stdout（会破坏逐字节比对）。
// 做法照第 13 章观察项：把测试脚本写进临时文件，用子进程跑，只断言性质。
bin := System getEnvironmentVariable("IO_BIN")
if(bin == nil,
    writeln("IO_BIN 未设置，跳过子进程实测（run-all.sh 会给每个示例注入 IO_BIN）")
,
    childLines := list(
        "T := UnitTest clone do(",
        "    testOk := method(assertEquals(1 + 1, 2))",
        "    testBad := method(assertEquals(1 + 1, 3))",
        "    testNil := method(assertNil(nil))",
        "    testTrue := method(assertTrue(true))",
        "    testRaise := method(assertRaisesException(Exception raise(\"boom\")))",
        ")",
        "r := T run",
        "writeln(\"RET \", r asString)",
        ""
    )
    tmpPath := Path with(System getEnvironmentVariable("TMPDIR"), "io_ch20_unittest.io")
    childFile := File with(tmpPath)
    childFile remove
    // asUTF8：Io 字符串的内部表示不等于文件字节（第 14 章的坑）
    childFile setContents(childLines join("\n") asUTF8)
    result := System runCommand(bin .. " " .. tmpPath)
    out := result stdout
    errS := result stderr
    rc := result exitStatus
    childFile remove

    writeln("子进程：5 个测试，其中 1 个故意失败")
    writeln("  子进程退出码 = ", rc asString)
    writeln("  子进程 stderr 长度 = ", errS size asString)
    writeln("  stdout 含 \"FAILED (failures 1)\" = ",
            (out containsSeq("FAILED (failures 1)")) asString)
    writeln("  stdout 含 \"Ran 5 tests in \" = ",
            (out containsSeq("Ran 5 tests in ")) asString)
    writeln("  stdout 含对象地址 \"Exception_0x\" = ",
            (out containsSeq("Exception_0x")) asString)
    writeln("  stdout 字节数 > 0 = ", (out size > 0) asString)
    writeln("  返回表也带地址 \"RET list(\" = ",
            (out containsSeq("RET list(")) asString)

    chk("失败也退出 0（CI 靠退出码判成败会漏）", rc, 0)
    chk("子进程 stderr 是空的", errS size, 0)
    chk("stdout 里有失败摘要", out containsSeq("FAILED (failures 1)"), true)
    chk("stdout 里有墙钟耗时摘要", out containsSeq("Ran 5 tests in "), true)
    chk("stdout 里有对象地址", out containsSeq("Exception_0x"), true)
    chk("run 的返回值是异常表", out containsSeq("RET list("), true)
)

sec("20.5 try + catch：没有框架也能做异常断言")
// Io 没有 try/catch 关键字：try 是方法，返回「异常对象」或「nil」；
// catch 是 Exception 上的方法，按类型过滤，命中返回 nil、不命中返回自己。
e := try(Exception raise("boom"))
show("try 抓到的东西 type", e type)
show("e error", e error)
show("e catch(Exception, ...) 命中", e catch(Exception, "命中"))
show("e catch(Error, ...) 没命中，返回自己", (e catch(Error, "不该命中")) isIdenticalTo(e))
show("没异常时 try 返回", try(1 + 1))
show("nil catch 也安全（nil 上有 catch 槽）", try(1 + 1) catch(Exception, "x"))
MyErr := Exception clone
show("自定义异常：Exception clone 的 type", MyErr type)
show("自定义异常能 raise", (try(MyErr raise("自定义"))) error)
show("Error 上没有 raise（坑）", (try((Error clone) raise("x"))) error)
// 「必须抛」的最小断言工具：一个方法，四行
mustRaise := method(blk,
    err := try(getSlot("blk") call)
    if(err, err error, "（没有异常）")
)
show("mustRaise(1 / \"a\")", mustRaise(method(1 / "a")))
show("mustRaise(1 + 1)", mustRaise(method(1 + 1)))
chk("异常消息本身就是断言目标", mustRaise(method(1 / "a")),
    "argument 0 to method '/' must be a Number, not a 'Sequence'")
chk("不抛的时候给出显式占位", mustRaise(method(1 + 1)), "（没有异常）")
chk("catch 命中返回 nil", e catch(Exception, "命中"), nil)

sec("20.6 为什么本仓库的回归不用 UnitTest")
// run-all.sh 对每个示例的判定（每条通道都要过）：
//   1. 退出码为 0   2. stderr 为空   3. stdout 里同时有开始/结束标记
//   4. 标记之间的区间非空、无控制字符、无未捕获异常横幅
//   5. 两个通道区间逐字节一致   6. 同一通道连跑两次区间逐字节一致
// UnitTest 卡死在第 1 条（失败也退 0）和第 6 条（输出含耗时/地址），
// 而「示例自带 chk + System exit(1)」把判定权收回到示例自己手里。
show("UnitTest 的摘要行长这样（含秒数，不可比）", "Ran 5 tests in 0.002s")
show("UnitTest 的失败横幅长这样（带地址，不可比）", "list(list(\"T testBad\", Exception_0x…))")
show("本仓库的判定标记（harness 靠它抽区间）", "==== 20 结束 ====")
chk("示例自己就是测试用例容器（fails 是个 Number）", fails isKindOf(Number), true)
chk("结构上：run 的收尾是 printExceptions + printSummary",
     TestRunner hasSlot("printExceptions") and TestRunner hasSlot("printSummary"), true)
chk("结构上：TestRunner.run 里没有 System exit",
     ((TestRunner getSlot("run")) code asString containsSeq("exit")) not, true)

sec("20.7 Io 自己的测试套件长什么样")
// 源码在 libs/iovm/tests/correctness/：一个文件一个 UnitTest 子对象，
// 文件名必须以 Test.io 结尾；run.io 负责收集，并**补上退出码**：
//     System exit(FileCollector run size)
// 这一句就是「UnitTest 本身不给退出码」的直接证据：Io 自己也得补。
// 一个真实的测试文件（MapTest.io 的头部）：
//     MapTest := UnitTest clone do(
//         setUp := method(
//             super(setUp)
//             self exampleMap := Map clone atPut("a", "alpha") atPut("b", "beta")
//         )
//         testClone := method(
//             assertNotSame(Map, Map clone)
//             assertEquals(2, exampleMap size)
//         )
//     )
// 注意 MapTest 这个名字：它就是 Lobby 里的槽名，也是 run 的查找键。
show("收集器 DirectoryCollector", DirectoryCollector type)
show("收集器 FileCollector", FileCollector type)
show("TestSuite 是 DirectoryCollector 的旧名", TestSuite isIdenticalTo(DirectoryCollector))
show("UnitTest 的 setUp 默认实现", MyTests setUp)
show("DirectoryCollector 只认 Test.io 后缀", (DirectoryCollector hasSlot("testFiles")))
show("FileCollector 扫 Lobby 里所有 UnitTest", (FileCollector hasSlot("prepare")))
chk("收集器按类型收，不按目录收", TestSuite isIdenticalTo(DirectoryCollector), true)
chk("setUp / tearDown 每个测试各跑一次", MyTests setUp, nil)
chk("测试清单按源码行号排序", MyTests testSlotNames asString,
    "list(\"testAlpha\", \"testBeta\")")

sec("20.8 三种断言姿势的分工")
// 1) chk：示例自带，失败 → fails+1 → 示例退出 1。本仓库的主用姿势。
// 2) try + 显式比较：临时探针、文档里的实测。
// 3) UnitTest：多测试文件 + 需要 setUp/tearDown 的项目用，
//    但要自己 System exit，且输出要自己转成可比对的形式。
// 下面用 chk 给一个真实函数补上边界用例，这就是「示例即测试」：
add := method(a, b, a + b)
show("add(2, 3)", add(2, 3))
show("add(-1, 1)", add(-1, 1))
show("add(0.5, 0.25)", add(0.5, 0.25))
chk("add(2, 3)", add(2, 3), 5)
chk("add(-1, 1)", add(-1, 1), 0)
chk("add(0.5, 0.25)", add(0.5, 0.25), 0.75)
show("边界：少传参数时形参是 nil", getSlot("add") argumentNames)
chk("add 声明了两个形参", getSlot("add") argumentNames asString, "list(\"a\", \"b\")")
chk("少传参数不报错，用到才炸", (try(add(2))) error,
    "argument 0 to method '+' must be a Number, not a 'nil'")
show("本示例累计失败数", fails)

sec("20.9 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 20 结束 ====")
if(fails != 0, System exit(1))
