// ============================================================
// 02_hello.io —— 第 02 章：第一个程序
//
// 运行（二进制路径按你的安装位置调整；本机在 $HOME/.workbuddy/binaries/io/bin）：
//   io        examples/02_hello/02_hello.io
//   io_static examples/02_hello/02_hello.io
//   io -e '"hello" println'        ← 一行版，REPL 里也是这句
//
// 判定区间在 "==== 02 开始 ====" 与 "==== 02 结束 ====" 之间；
// 区间内只放确定性输出（不打印路径、对象地址、时间、进程号）。
// ============================================================

fails := 0
// 方法参数用「,」分隔，方法体里的多条语句用「;」分隔 —— 二者不能混。
chk := method(tag, got, want,
    if(got asString != want asString,
        fails = fails + 1
        writeln("  [FAIL] ", tag, " 得到 ", got asString, "，期望 ", want asString)
    )
)
sec := method(title, writeln(""); writeln("-- ", title))

writeln("==== 02 开始 ====")

sec("2.1 两个输出原语：writeln(x) 与 x println")
// writeln / write 是原语：写**参数**，可一次写多个（各自 asString 后拼接）
writeln("writeln 写参数，可多个：", 1, " + ", 2, " = ", 1 + 2)
write("write 不换行|")
write("write 第二段|")
writeln("")
// print / println 是消息：写**接收者**，参数被静默丢掉
42 println
"print 不换行|" print
"print 同一行续上" println
writeln("writeln 自带换行")
chk("println 返回接收者", ("x" println), "x")

sec("2.2 陷阱：println(x) 里的 x 是装饰品")
// Object println 的定义就是 method(self print; write("\n"); self) —— 一个参数都不读。
// 于是 obj println(42) 打印的是 obj 自己，42 无声消失。
// 这里把 obj 的 asString 换成固定串，好让输出不含对象地址。
probe := Object clone do(asString := "「被打印的是接收者」")
probe println(42)
chk("println 忽略参数", (probe println(42)), probe)
// 唯一正解：writeln(42)（写参数）或 42 println（把 42 当接收者）
writeln(42)
42 println

sec("2.3 字符串字面量与显式插值")
name := "Io"
// 关键：Io **不做隐式插值**，必须显式调 interpolate
writeln("hello #{name}")
writeln("hello #{name}" interpolate)
writeln("1 + 2 = #{1 + 2}" interpolate)
writeln("((1 + 2) * 3) = #{(1 + 2) * 3}" interpolate)
chk("插值区里可以有括号（但整串必须是纯 ASCII）", "((1 + 2) * 3) = #{(1 + 2) * 3}" interpolate, "((1 + 2) * 3) = 9")
// 三引号是多行字面量，里面的 #{...} 同样不会自动展开
multi := """第一行
第二行 #{name}"""
writeln(multi)
chk("三引号串不插值", multi size, 15)
// 注意：含非 ASCII 的串上调 interpolate 有严重缺陷，见 04 章 4.7 节

sec("2.4 转义与看不见的字符")
writeln("tab:[", "\t", "]")
writeln("引号：\"x\"，反斜杠：\\")
writeln("换行：\n（上一行到此结束）")
// 不支持 \xNN：反斜杠会被吃掉，字面留下 xNN
writeln("本构建没有 \\xNN 转义：", "\x41")
chk("\\x41 不是字节转义", "\x41", "x41")

sec("2.5 注释与语句分隔")
/* 块注释，可以跨行 */
// 行注释
a := 1; b := 2; writeln("分号压行：a + b = ", a + b)
chk("语句分隔不是逗号", a + b, 3)

sec("2.6 中文字面量：size 数的是字符，不是字节")
s := "你好"
writeln("「你好」size = ", s size, "，sizeInBytes = ", s sizeInBytes,
        "，encoding = ", s encoding, "，itemType = ", s itemType)
chk("UCS4 字面量按码点计数", s size, 2)
chk("UCS4 下每码点 4 字节", s sizeInBytes, 8)
chk("转 UTF-8 才是 6 字节", s asUTF8 size, 6)
chk("纯 ASCII 字面量是 1 字节/字符", "hello" sizeInBytes, 5)
writeln("第一个码点：", s at(0), "（就是「你」的 Unicode 码位）")

sec("2.7 脚本自己的身份与参数")
writeln("launchScript 文件名：", System launchScript fileName)
// System args 与 C 的 argv 同形：args[0] 是脚本路径，用户参数从 1 开始
writeln("System args 的长度（本示例没带参数，所以是 1）：", System args size)
writeln("args[0] 是脚本路径，args at(0) fileName = ", (System args at(0)) asFile name)
chk("args[0] 是脚本本体", System args size, 1)
writeln("isLaunchScript（Io 版的 __main__）：", isLaunchScript)

sec("2.8 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 02 结束 ====")
if(fails != 0, System exit(1))
