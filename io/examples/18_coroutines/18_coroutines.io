// ============================================================
// 18_coroutines.io —— 第 18 章：协程与 Future
// 运行：io examples/18_coroutines/18_coroutines.io
//
// Io 的并发原语是「协作式协程」：一个 Coroutine 有一条自己的求值栈，
// 调度器就是一张 List（Coroutine yieldingCoros），yield 把控制权交给队首。
// 本章最要紧的一条纪律：**任何可能挂住的调用都必须丢进子进程 + 超时**，
// 因为队列耗尽时 Io 不是抛异常，而是死循环（18.7 实测）。
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

// ---- 子进程脚手架：找解释器 / 找超时工具 / 写临时子脚本 ----
pickExecutable := method(cands,
    found := nil
    cands foreach(c,
        if(found isNil,
            if(c isNil not,
                if(c != "",
                    if(System runCommand("test -x " .. c) exitStatus == 0, found = c)
                )
            )
        )
    )
    found
)
home := System getEnvironmentVariable("HOME")
if(home isNil, home = "")
ioBin := pickExecutable(list(
    System getEnvironmentVariable("IO_BIN"),
    home .. "/.workbuddy/binaries/io/bin/io_static",
    "/opt/local/bin/io_static",
    "/usr/local/bin/io_static"
))
timeoutBin := pickExecutable(list(
    "/opt/local/bin/gtimeout",
    "/usr/local/bin/gtimeout",
    "/usr/bin/timeout"
))
writeChildScript := method(path, lines,
    f := File with(path)
    f remove
    f setContents(lines join("\n") asUTF8)
    path
)

writeln("==== 18 开始 ====")

sec("18.1 协程与调度器：Coroutine / Scheduler / yieldingCoros")
c := Coroutine currentCoroutine
show("Coroutine currentCoroutine 的 type", c type)
show("isCurrent", c isCurrent)
show("isYielding", c isYielding)
show("Scheduler currentCoroutine 就是同一个", Scheduler currentCoroutine isIdenticalTo(c))
show("Coroutine yieldingCoros 就是 Scheduler yieldingCoros",
     Coroutine yieldingCoros isIdenticalTo(Scheduler yieldingCoros))
show("此刻队列 size", Scheduler yieldingCoros size)
show("实现方式", c implementation)
show("Scheduler hasSlot(\"waitForCorosToComplete\")", Scheduler hasSlot("waitForCorosToComplete"))
chk("yieldingCoros 只有一份", Coroutine yieldingCoros isIdenticalTo(Scheduler yieldingCoros), true)
chk("调度器是帧式实现", c implementation, "frame-based")
chk("主协程就是当前协程", Scheduler currentCoroutine isIdenticalTo(c), true)

sec("18.2 coroDo：创建即开跑，跑到第一个 yield 才回来")
trace := List clone
coro := coroDo(
    trace append("子1")
    writeln("  子协程跑到第一个 yield")
    yield
    trace append("子2")
)
trace append("主1")
show("coroDo 返回值的 type", coro type)
show("coroDo 之后 trace", trace join(" "))
show("coroDo 之后队列 size", Scheduler yieldingCoros size)
yield
trace append("主2")
show("yield 之后 trace", trace join(" "))
show("yield 之后队列 size", Scheduler yieldingCoros size)
show("队首就是创建者自己", (Scheduler yieldingCoros at(0)) isIdenticalTo(Coroutine currentCoroutine))
chk("coroDo 创建即开跑，跑到第一个 yield 才回到调用者", trace join(" "), "子1 主1 子2 主2")
chk("coroDo 结束时会把创建者留在队列里",
    (Scheduler yieldingCoros at(0)) isIdenticalTo(Coroutine currentCoroutine), true)

sec("18.3 yield 与 pause：队列里没有别人时什么都不发生")
// 上一节 coroDo 把创建者塞进队列了，先手动清掉
Coroutine yieldingCoros remove(Coroutine currentCoroutine)
show("清过之后队列 size", Scheduler yieldingCoros size)
yield
show("空队列上 yield 之后队列 size", Scheduler yieldingCoros size)
e := try(Coroutine currentCoroutine pause)
show("空队列上 pause 的异常消息", e error)
show("pause 之后队列 size", Scheduler yieldingCoros size)
chk("空队列上 yield 是空操作", Scheduler yieldingCoros size, 0)
chk("空队列上 pause 会直接炸", e error, "Scheduler: nothing left to resume so we are exiting")

sec("18.4 协程的槽：没有 status，label 是地址")
writeln("Coroutine slotNames sort = ", Coroutine slotNames sort join(","))
show("hasSlot(\"status\")", Coroutine hasSlot("status"))
show("hasSlot(\"isYielding\")", Coroutine hasSlot("isYielding"))
show("hasSlot(\"isCurrent\")", Coroutine hasSlot("isCurrent"))
show("hasSlot(\"result\")", Coroutine hasSlot("result"))
show("hasSlot(\"ioStack\")", Coroutine hasSlot("ioStack"))
show("hasSlot(\"callStack\")", Coroutine hasSlot("callStack"))
show("hasSlot(\"stack\")", Coroutine hasSlot("stack"))
show("当前协程 ioStack 是个非空 List", (Coroutine currentCoroutine ioStack size) > 0)
c4 := coroDo(writeln("  打个卡就结束"))
c4 setLabel("worker")
show("setLabel(\"worker\") 之后 label 的前 7 个字符", c4 label exSlice(0, 7))
show("label 比 8 个字符长（后面跟的是 uniqueId）", (c4 label size) > 8)
writeln("uniqueId 是地址那类东西，所以 label 永远不要整条打进输出")
chk("没有 status 这个槽", Coroutine hasSlot("status"), false)
chk("状态只能问 isYielding / isCurrent", Coroutine hasSlot("isYielding"), true)
chk("没有 stack 槽，栈叫 ioStack / callStack", Coroutine hasSlot("stack"), false)
chk("setLabel 只是给 label 加前缀", c4 label exSlice(0, 7), "worker_")
chk("result 是协程的一个普通槽", Coroutine hasSlot("result"), true)

sec("18.5 Coroutine clone：手工搭协程，局部状态自己给")
box := Object clone do(v := 0)
cc := Coroutine clone
cc setSlot("runTarget", box)
cc setSlot("runLocals", box)
cc setSlot("runMessage", Message fromString("v := v + 100"))
show("runMessage 的 type", (cc getSlot("runMessage")) type)
show("run 之前 box v", box v)
cc run
show("run 之后 box v", box v)
show("协程结束时的 result", cc result)
show("cc isYielding", cc isYielding)
// coroDo 的 runLocals 是 call sender：跟创建者是同一套 locals
x := 0
sharer := coroDo(x = x + 1)
show("coroDo 里改过之后，创建者这边的 x", x)
show("coroDo 之后队列 size", Scheduler yieldingCoros size)
// 想要独立状态，就自己 clone 一个协程、自己排进队列
Coroutine yieldingCoros remove(Coroutine currentCoroutine)
box2 := Object clone do(v := 0)
cc2 := Coroutine clone
cc2 setSlot("runTarget", box2)
cc2 setSlot("runLocals", box2)
cc2 setSlot("runMessage", Message fromString("v := v + 5"))
Coroutine yieldingCoros append(cc2)
show("排入 cc2 之后队列 size", Scheduler yieldingCoros size)
yield
show("yield 之后 box2 v", box2 v)
chk("Coroutine clone + run 会立刻切过去跑", box v, 100)
chk("result 收的是 runMessage 的值", cc result, 100)
chk("coroDo 和创建者共用 locals", x, 1)
chk("自己给 runLocals 就是独立状态", box2 v, 5)

sec("18.6 Future 与 FutureProxy：@ 不是协程的字面量")
show("@ 是二元运算符，优先级", OperatorTable operators at("@"))
show("@@ 的优先级", OperatorTable operators at("@@"))
show("Object hasSlot(\"@\")", Object hasSlot("@"))
show("futureSend 就是 @", Object getSlot("futureSend") isIdenticalTo(Object getSlot("@")))
show("asyncSend 就是 @@", Object getSlot("asyncSend") isIdenticalTo(Object getSlot("@@")))
writeln("Future slotNames sort = ", Future slotNames sort join(","))
show("Future hasSlot(\"result\")", Future hasSlot("result"))
show("Future hasSlot(\"setValue\")", Future hasSlot("setValue"))
show("Future hasSlot(\"setResult\")", Future hasSlot("setResult"))
show("Future hasSlot(\"waitOnResult\")", Future hasSlot("waitOnResult"))
f := Future clone
pr := f futureProxy
prTypeBefore := pr type
f setResult(42)
show("futureProxy 一开始的 type", prTypeBefore)
show("setResult(42) 之后 pr 的 type", pr type)
show("setResult(42) 之后 pr 的值", pr)
chk("Io 没有 Future result / setValue", Future hasSlot("result"), false)
chk("生产者的接口叫 setResult", Future hasSlot("setResult"), true)
chk("futureProxy 起初是一个 FutureProxy", prTypeBefore, "FutureProxy")
chk("setResult 让 proxy become 成结果本身", pr, 42)

sec("18.7 实测能力边界：队列耗尽是死循环，只能被外部强杀")
show("找到了可用的解释器", ioBin isNil not)
show("找到了可用的超时工具", timeoutBin isNil not)
tmpDir := System getEnvironmentVariable("TMPDIR")
hangDone := Path with(tmpDir, "io_ch18_hang_done.txt")
File with(hangDone) remove
hangChild := Path with(tmpDir, "io_ch18_hang_child.io")
writeChildScript(hangChild, list(
    "// 队列里只剩自己：yield 立刻返回，loop 就成了死循环",
    "coroDo(loop(yield))",
    "Coroutine currentCoroutine pause",
    "File with(\"" .. hangDone .. "\") setContents(\"done\")"
))
writeln("子命令形状：<timeout> --foreground -s KILL 3 <io> <child>")
rHang := System runCommand(timeoutBin .. " --foreground -s KILL 3 " .. ioBin .. " " .. hangChild)
show("挂死子进程的退出码（137 = 被 SIGKILL 强杀）", rHang exitStatus)
show("挂死子进程跑到最后一行了吗", File with(hangDone) exists)
show("挂死子进程 stderr 的字节数", (rHang stderr) size)
chk("队列耗尽 = 死循环，只能被外部强杀", rHang exitStatus, 137)
chk("最后一行永远到不了", File with(hangDone) exists, false)

futDone := Path with(tmpDir, "io_ch18_future_done.txt")
File with(futDone) remove
futChild := Path with(tmpDir, "io_ch18_future_child.io")
writeChildScript(futChild, list(
    "// Future 没有被 setResult，访问它的 proxy 就等于 pause 自己",
    "f := Future clone",
    "p := f futureProxy",
    "p anything(1)",
    "File with(\"" .. futDone .. "\") setContents(\"done\")"
))
rFut := System runCommand(timeoutBin .. " --foreground -s KILL 3 " .. ioBin .. " " .. futChild)
show("未设值的 Future 被访问后的退出码", rFut exitStatus)
show("子进程 stdout 里有 nothing left to resume",
     (rFut stdout) containsSeq("nothing left to resume"))
show("未设值的 Future 子进程跑到最后了吗", File with(futDone) exists)
chk("未设值就访问 FutureProxy 会中断脚本", rFut exitStatus, 0)
chk("中断原因是没有协程可恢复", (rFut stdout) containsSeq("nothing left to resume"), true)
chk("中断之后的行不会执行", File with(futDone) exists, false)
File with(hangChild) remove
File with(futChild) remove
File with(hangDone) remove
File with(futDone) remove

sec("18.8 确定性交替：两个协程 + 一份共享 List")
// 前面几节在队列里攒了几笔（coroDo 会留下创建者），先清干净再演示
Coroutine yieldingCoros remove(Coroutine currentCoroutine)
show("清过之后队列 size", Scheduler yieldingCoros size)
order := List clone
a := coroDo(
    order append("A1"); yield
    order append("A2"); yield
    order append("A3")
)
b := coroDo(
    order append("B1"); yield
    order append("B2"); yield
    order append("B3")
)
order append("M1")
yield
order append("M2")
yield
order append("M3")
yield
order append("M4")
yield
order append("M5")
show("交替顺序", order join(" "))
chk("yield 是显式的，交替顺序完全确定", order join(" "), "A1 B1 M1 A2 B2 M2 A3 M3 B3 M4 M5")

sec("18.9 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 18 结束 ====")
if(fails != 0, System exit(1))
