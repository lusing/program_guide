// ============================================================
// observe_15_relpath.io —— 第 15 章的**观察项**（不是普通示例）
//
// 待观察的行为：
//   System launchPath 与 System launchScript 是**两个不同来源**的路径：
//     · launchPath    —— 被规范化过的**绝对路径**（并且去掉了扩展名）
//     · launchScript  —— 命令行里**原样**传进来的那个串
//   因为一个是「规范化后的」、一个是「原样保留的」，所以
//   **「launchScript 是不是绝对路径」完全取决于你怎么调用它**。
//
//   这一条不能写进普通示例的判定区间：run-all.sh 用绝对路径调脚本，
//   人手在仓库根目录用相对路径调，同一个断言会得到 true / false 两个结果。
//   所以按本仓库的约定，把「差异」本身拿出来做成可观察的对照。
//
// 做法：把子脚本写进临时目录，分两次启动它，只改变**调用方式**：
//   第 1 次：先 cd 进临时目录，再用**相对路径**调用 → launchScript 是相对的
//   第 2 次：用**绝对路径**调用                      → launchScript 是绝对的
//   两次的 launchPath 都是绝对路径。
//
// 解释器路径由 run-all.sh 通过 IO_BIN 环境变量注入。
// 子脚本只打印**形状**（是不是绝对路径、basename 是什么），不打印路径本身——
// 真实路径是机器相关的，打出来就不是确定性输出了。
// ============================================================

writeln("==== 15 观察 开始 ====")

// 解释器路径：优先用 run-all.sh 注入的 IO_BIN，没有就按安装前缀回落，
// 最后一条兜底是交给 sh 从 PATH 里找（这条分支没法提前判存在性）。
bin := System getEnvironmentVariable("IO_BIN")
list(System installPrefix .. "/bin/io_static",
     System installPrefix .. "/bin/io") foreach(c,
    if(bin == nil and File with(c) exists, bin = c)
)
if(bin == nil, bin = "io_static")
writeln("被观察的解释器 = ", bin asString)

// 子脚本的四行内容。用 list(...) join("\n") 组装，不要把 ".." 写到行尾——
// 二元运算符后面换行，Io 会当成「右操作数缺失」补个 nil（第 04 章坑位清单第 6 条）。
probeLines := list(
    "writeln(\"  launchPath   是绝对路径 = \", (System launchPath beginsWithSeq(\"/\")) asString)",
    "writeln(\"  launchScript 是绝对路径 = \", (System launchScript beginsWithSeq(\"/\")) asString)",
    "writeln(\"  launchScript 原样等于 argv[0] = \", (System launchScript == System args at(0)) asString)",
    "writeln(\"  launchPath 的 basename = \", File with(System launchPath) name asString)",
    "writeln(\"  launchScript 的 basename = \", File with(System launchScript) name asString)",
    "\n"
)
probeSource := probeLines join("\n")

tmpDir := Path with(System getEnvironmentVariable("TMPDIR"), "io_observe_15_relpath")
Directory with(tmpDir) createIfAbsent
probePath := tmpDir .. "/rel_probe.io"
probeFile := File with(probePath)
probeFile remove
// 必须 asUTF8：含中文的串内部是 UCS4，setContents 会把内部表示原样倒进文件，
// 子进程读到的就是一串 \0（第 14 章坑位清单）。本文件里子脚本内容是纯 ASCII，
// 但这条纪律不能因为「这次恰好是 ASCII」就省掉。
probeFile setContents(probeSource asUTF8)
writeln("临时子脚本字节数 = ", probeFile size asString)

writeln("--- 第 1 次：先 cd 进临时目录，再用相对路径调用 ---")
r1 := System runCommand("cd " .. tmpDir .. " && " .. bin .. " rel_probe.io")
write(r1 stdout)
writeln("  子进程退出码 = ", r1 exitStatus asString)

writeln("--- 第 2 次：用绝对路径调用 ---")
r2 := System runCommand(bin .. " " .. probePath)
write(r2 stdout)
writeln("  子进程退出码 = ", r2 exitStatus asString)

o1 := r1 stdout
o2 := r2 stdout

// 关键的一步转换，两个坑叠在一起：
//   · `System runCommand` 返回的 stdout 是「把子进程输出原样读回来的字节串」
//     —— `type` 是 Sequence，`size` 数字节（一个中文 3 字节）。
//   · 源码里含中文的字面量会被升成 UCS4 —— `size` 数码点。
//   两种序列元素宽度不同，`containsSeq` **不会报错，只会安静地给 false**。
//   两边都 `asUTF8` 才是同一把尺子。
has := method(hay, needle, hay asUTF8 containsSeq(needle asUTF8))

writeln("判 1：相对调用时 launchScript 不是绝对路径 = ",
        has(o1, "launchScript 是绝对路径 = false") asString)
writeln("判 2：绝对调用时 launchScript 是绝对路径 = ",
        has(o2, "launchScript 是绝对路径 = true") asString)
writeln("判 3：两次的 launchPath 都是绝对路径 = ",
        (has(o1, "launchPath   是绝对路径 = true") and(
             has(o2, "launchPath   是绝对路径 = true"))) asString)
writeln("判 4：launchScript 始终逐字等于 argv[0] = ",
        (has(o1, "launchScript 原样等于 argv[0] = true") and(
             has(o2, "launchScript 原样等于 argv[0] = true"))) asString)

probeFile remove
Directory with(tmpDir) remove

writeln("==== 15 观察 结束 ====")
