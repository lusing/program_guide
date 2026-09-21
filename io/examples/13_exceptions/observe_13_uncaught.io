// ============================================================
// observe_13_uncaught.io —— 第 13 章的**观察项**（不是普通示例）
//
// 观察项只验证语言的一个客观行为，不参与「跨通道逐字节比对」，
// 因为它要展示的恰恰是「一个脚本中途死掉」这件事。
//
// 待观察的行为：
//   Io 的**未捕获异常**会
//     · 把异常横幅打到 **stdout**（不是 stderr）
//     · 中断脚本，异常之后的行永远不执行
//     · **进程退出码仍然是 0**
//   最后一条是回归脚本必须用「结束标记」而不是退出码来判定的根本原因：
//   只看退出码，一个跑到一半就死了的示例会被当成通过。
//
// 做法：本文件本身必须活到最后（要打印观察结束标记），所以把「会死的脚本」
// 写进临时文件、用子进程跑，再把子进程的 stdout/退出码原样搬回来。
// 解释器路径由 run-all.sh 通过 IO_BIN 环境变量注入。
// ============================================================

writeln("==== 13 观察 开始 ====")

// 解释器路径：优先用 run-all.sh 注入的 IO_BIN，没有就按安装前缀回落，
// 最后一条兜底是交给 sh 从 PATH 里找（这条分支没法提前判存在性）。
bin := System getEnvironmentVariable("IO_BIN")
list(System installPrefix .. "/bin/io_static",
     System installPrefix .. "/bin/io") foreach(c,
    if(bin == nil and File with(c) exists, bin = c)
)
if(bin == nil, bin = "io_static")
writeln("被观察的解释器 = ", bin asString)

// 子脚本的三行内容。注意这里用 list(...) join("\n") 而不是把 ".." 写到行尾——
// 二元运算符后面换行，Io 会把它当成「右操作数缺失」直接补个 nil（第 04 章坑位清单
// 第 6 条：`"a" ..<换行>"b"` 得到的是 "anil"）。要跨行拼接必须加括号。
childLines := list(
    "writeln(\"子进程：第一行\")",
    "Object clone boom",
    "writeln(\"==== 13 观察 之后 ====\")\n"
)
childSource := childLines join("\n")

tmpPath := Path with(System getEnvironmentVariable("TMPDIR"), "io_observe_13_uncaught.io")
childFile := File with(tmpPath)
childFile remove
// 必须 asUTF8：Io 的字符串含中文时内部升成 UCS4（每码点 4 字节），
// setContents 原样把**内部表示**倒进文件，写出的是 4 字节一码点的鬼东西，
// 子进程再按 ASCII 读就是一堆 \0。第 14 章的坑位清单里专门讲这条。
childFile setContents(childSource asUTF8)
writeln("临时子脚本字节数 = ", childFile size asString)

result := System runCommand(bin .. " " .. tmpPath)
childOut := result stdout
childErr := result stderr
childRc := result exitStatus

writeln("子进程退出码 = ", childRc asString)
writeln("子进程 stderr 长度 = ", childErr size asString)
writeln("--- 子进程 stdout 原文开始 ---")
write(childOut)
writeln("--- 子进程 stdout 原文结束 ---")

writeln("判 1：异常横幅出现在 stdout 里 = ",
        (childOut containsSeq("Exception: Object does not respond to 'boom'")) asString)
writeln("判 2：异常之后那一行没被执行 = ",
        (childOut containsSeq("观察 之后") not) asString)
writeln("判 3：脚本中断了，退出码却仍是 0 = ", (childRc == 0) asString)

childFile remove

writeln("==== 13 观察 结束 ====")
