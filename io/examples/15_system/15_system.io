// ============================================================
// 15_system.io —— 第 15 章：系统、进程与环境
// 运行：io examples/15_system/15_system.io
//
// System 上的三件事：查平台/版本、拿参数与环境变量、跑子进程。
//
// 两条纪律：
//   · 路径类信息（ioPath / installPrefix / launchPath / launchScript）
//     一律只断言「非空 / 是绝对路径」，输出里绝不出现绝对路径；
//   · 退出码这种东西不能靠猜——`System exit(3)` 会直接把本进程干掉，
//     所以要开一个临时子脚本去跑它，再把子进程的退出码搬回来。
//     解释器路径优先取 IO_BIN（run-all.sh 注入），退化取 installPrefix。
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
// escape / strip 这类是**就地**方法：runCommand 结果里的 stdout 是同一块字符串，
// 直接 escape 会把字段自己改掉（后面再拿它比较就对不上了），所以先 clone 再转义。
esc := method(s, s clone escape)

writeln("==== 15 开始 ====")

sec("15.1 平台、版本与 CPU")
show("System platform", System platform)
show("System version（固定字符串，可以打）", System version)
show("System iospecVersion", System iospecVersion)
show("System iovmName", System iovmName)
// platformVersion 里塞着内核版本和构建日期，本机虽然稳定，但它是「环境信息」，
// 只断言形状、不打内容——这是示例不依赖机器细节的通用做法。
show("platformVersion 非空", System platformVersion size > 0)
show("platformVersion 以 platform 开头", System platformVersion beginsWithSeq(System platform))
show("activeCpus 的类型", System activeCpus type)
show("activeCpus >= 1", System activeCpus >= 1)
show("System symbols 的类型", System symbols type)
show("symbols 非空", System symbols size > 0)
show("symbols 里有 println", System symbols contains("println"))
show("sleep / exit 都是 CFunction", System getSlot("sleep") type asString .. " / " .. System getSlot("exit") type)

sec("15.2 路径类信息：只断言，不打内容")
show("ioPath 非空", System ioPath size > 0)
show("ioPath 是绝对路径", System ioPath beginsWithSeq("/"))
show("installPrefix 非空", System installPrefix size > 0)
show("installPrefix 是绝对路径", System installPrefix beginsWithSeq("/"))
show("launchPath 是绝对路径（已被规范化）", System launchPath beginsWithSeq("/"))
show("launchPath 的 basename（能打的部分）", File with(System launchPath) name)
show("launchScript 非空", System launchScript size > 0)
// 两个槽不是一个东西：launchPath 是被**规范化**过的绝对路径，launchScript 是
// 命令行里**原样**传进来的那个串。
//
// ⚠️ 这里**不能**断言「launchScript 是不是绝对路径」——那取决于你怎么调用本脚本：
//    run-all.sh 用绝对路径调（得 true），人手在仓库根目录用相对路径调（得 false）。
//    同一个断言两种结果，那就不是确定性输出了。
// 能确定性断言的是「launchScript 逐字等于 argv[0]」，以及「launchPath 一定是绝对的」。
// 「同一份脚本换个调用方式，两个槽会怎么变」这件事由观察项专门演示：
//    examples/15_system/observe_15_relpath.io
show("launchScript 逐字等于 argv[0]（原样保留）", System launchScript == System args at(0))
show("launchPath 的 basename 去掉了扩展名", File with(System launchPath) name)

sec("15.3 命令行参数：System args 是 C 风格 argv")
show("System args 的类型", System args type)
show("args size（脚本自己算一格）", System args size)
show("args[0] 的 basename（argv[0] 是脚本路径）", File with(System args at(0)) name)
show("args at(0) 和 launchScript 同一个", File with(System args at(0)) name == File with(System launchScript) name)
show("System isLaunchScript", System isLaunchScript)
show("脚本名叫 15_system.io", File with(System launchScript) name == "15_system.io")

sec("15.4 环境变量：get / set")
envName := "IO_TUTORIAL_15"
before := System getEnvironmentVariable(envName)
show("设之前读过吗（没设过就是 nil）", before == nil)
System setEnvironmentVariable(envName, "hello")
show("设完读回来", System getEnvironmentVariable(envName))
show("读回来的长度", System getEnvironmentVariable(envName) size)
show("TMPDIR 非空", System getEnvironmentVariable("TMPDIR") size > 0)
// 注意：Io 没有「unset」的用法。setEnvironmentVariable(name, nil) 会直接段错误
// （rc=139，两个二进制都一样），所以「复原」只能置成空串，见 15.9 坑位清单。
System setEnvironmentVariable(envName, "")
show("复原成空串后长度", System getEnvironmentVariable(envName) size)
show("复原成空串后还是 nil 吗", System getEnvironmentVariable(envName) == nil)

sec("15.5 System system：返回值就是退出码，不是 wait status 原始值")
show("system(\"exit 0\")", System system("exit 0"))
show("system(\"exit 1\")", System system("exit 1"))
show("system(\"exit 3\")", System system("exit 3"))
show("system(\"true\")", System system("true"))
show("system(\"false\")", System system("false"))
show("若是 wait status 原始值，exit 3 会是 3*256", 3 * 256)
chk("system 给的是退出码：exit 3 → 3", System system("exit 3"), 3)
chk("system 给的是退出码：exit 0 → 0", System system("exit 0"), 0)

sec("15.6 System runCommand：抓子进程的 stdout / stderr / 退出码")
r := System runCommand("echo hello")
show("stdout（escape）", esc(r stdout))
show("stderr 长度", r stderr size)
show("exitStatus", r exitStatus)
show("succeeded", r succeeded)
bad := System runCommand("exit 4")
show("失败命令的 exitStatus", bad exitStatus)
show("失败命令的 succeeded", bad succeeded)
show("stdout 的类型", r stdout type)
// 命令串里有多条命令、或者同时写两个流时，只有最后一条的输出能稳定拿到；
// 要精确分离就显式写 /bin/sh -c "..."。
both := System runCommand("/bin/sh -c \"echo O; echo E 1>&2\"")
show("显式 sh -c：stdout", esc(both stdout))
show("显式 sh -c：stderr", esc(both stderr))
show("显式 sh -c：exitStatus", both exitStatus)

// ── 两个编码坑，都在「字符串怎么进 / 怎么出子进程」上 ──────────────
//
// 坑一（这里只给正解）：命令串里含非 ASCII 时**必须先 asUTF8**。
// 不 asUTF8，Io 会把 UCS4 的内部表示直接当命令行交给 shell，shell 收到的是
// 被 0 字节切碎的乱码 —— 它会在一个**别的命令名**上失败，往 stderr 吐
//     sh: e: command not found
// 而 r stdout 是空的。那行会污染父进程的 stderr，所以这条不给反例，
// 免得把一个「stderr 必须为空」的示例搞挂。
rCn := System runCommand("echo 中文 ok" asUTF8)
show("命令串 asUTF8 后 stdout", esc(rCn stdout))
//
// 坑二：拿回来的 stdout 是**按字节**的序列，而源码里含中文的字面量内部是
// UCS4、**按码点**。两者元素宽度不同，`containsSeq` 不会报错，
// 只会安静地给 false。判据看 `encoding` / `itemType` / `size` 三个槽
// （第 04 章 4.2 讲过这三兄弟）。
show("stdout 的 encoding / itemType", rCn stdout encoding .. " / " .. rCn stdout itemType)
show("字面量 \"中文 ok\" 的 encoding / itemType", "中文 ok" encoding .. " / " .. "中文 ok" itemType)
show("stdout 的 size / sizeInBytes", list(rCn stdout size, rCn stdout sizeInBytes) asString)
show("字面量 \"中文 ok\" 的 size / sizeInBytes", list("中文 ok" size, "中文 ok" sizeInBytes) asString)
show("直接 containsSeq（尺子不一样）", rCn stdout containsSeq("中文 ok"))
show("两边 asUTF8 后 containsSeq", (rCn stdout asUTF8) containsSeq("中文 ok" asUTF8))

chk("成功命令 succeeded", r succeeded, true)
chk("失败命令 succeeded", bad succeeded, false)
chk("失败命令的退出码", bad exitStatus, 4)
chk("sh -c 能把两条命令的输出都收全", both stdout, "O" .. "\n")
chk("子进程输出按字节返回（一个中文 3 字节）", rCn stdout size, 10)
chk("源码字面量按码点（一个中文 1 个 size）", "中文 ok" size, 5)
chk("元素宽度不同时 containsSeq 静默给 false", rCn stdout containsSeq("中文 ok"), false)
chk("两边 asUTF8 才比得对", (rCn stdout asUTF8) containsSeq("中文 ok" asUTF8), true)
chk("子进程输出是 ascii/uint8", rCn stdout encoding .. "/" .. rCn stdout itemType, "ascii/uint8")
chk("含中文的字面量是 ucs4/uint32", "中文 ok" encoding .. "/" .. "中文 ok" itemType, "ucs4/uint32")

sec("15.7 用子进程实测 System exit(3) 的退出码")
bin := ""
rawBin := System getEnvironmentVariable("IO_BIN")
if(rawBin != nil, bin = rawBin)
if(bin size == 0, bin = System installPrefix .. "/bin/io_static")
tmp := System getEnvironmentVariable("TMPDIR")
childPath := Path with(tmp, "io_tut_15_exit.io")
childFile := File with(childPath)
childFile remove
// 子脚本只有一行，且必须是纯 ASCII：含中文的串内部是 UCS4，
// setContents 会把内部表示原样倒进文件（第 14 章的坑）。
childFile setContents(list("System exit(3)", "") join("\n") asUTF8)
show("子脚本字节数", (File clone setPath(childPath)) size)
show("解释器可用", (bin size > 0) and (File clone setPath(bin) exists))
res := System runCommand(bin .. " " .. childPath)
show("子进程退出码", res exitStatus)
show("子进程 stdout 长度（不该有东西）", res stdout size)
show("子进程 succeeded", res succeeded)
childFile remove
chk("System exit(3) 真的让进程以 3 退出", res exitStatus, 3)
chk("System exit 是 CFunction", System getSlot("exit") type asString, "CFunction")

sec("15.8 sleep 与收尾")
show("System sleep 的类型", System getSlot("sleep") type)
System sleep(0.01)
show("sleep(0.01) 之后脚本还活着", true)
show("子脚本删干净了吗", (File clone setPath(childPath)) exists == false)
chk("sleep 是 CFunction", System getSlot("sleep") type asString, "CFunction")

sec("15.9 自检")
chk("15 自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 15 结束 ====")
if(fails != 0, System exit(1))
