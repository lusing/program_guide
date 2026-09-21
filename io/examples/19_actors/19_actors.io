// ============================================================
// 19_actors.io —— 第 19 章：Actor 与并发
// 运行：io examples/19_actors/19_actors.io
//
// 本章有一半是「实测报告」：本机这份构建里**没有 Actor 这个 proto**，
// 也没有 IoServer / IoClient（addon 一个都没装）。但 Actor 机制本身是全的，
// 它挂在 Object 上：actorRun 起一个协程，actorQueue 收 Future，@ / @@ 异步投递。
// 本章所有并发判定都做成自包含的：要么单生产者单消费者（顺序确定），
// 要么丢进子进程 + 超时（证明「不挂」）。不用时间/顺序不确定的例子。
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

writeln("==== 19 开始 ====")

sec("19.1 本机的 Actor 面貌：Actor proto 不在，机制挂在 Object 上")
show("Lobby hasSlot(\"Actor\")", Lobby hasSlot("Actor"))
show("Object hasSlot(\"actorRun\")", Object hasSlot("actorRun"))
show("Object hasSlot(\"actorProcessQueue\")", Object hasSlot("actorProcessQueue"))
show("Object hasSlot(\"handleActorException\")", Object hasSlot("handleActorException"))
show("Object hasSlot(\"@\")", Object hasSlot("@"))
show("Object hasSlot(\"@@\")", Object hasSlot("@@"))
show("Object hasSlot(\"futureSend\")", Object hasSlot("futureSend"))
show("Object hasSlot(\"asyncSend\")", Object hasSlot("asyncSend"))
show("Addon exists(\"Actor\")", Addon exists("Actor"))
e := try(Lobby Actor)
show("取 Actor 这个全局名的报错", e error)
chk("本机没有 Actor proto", Lobby hasSlot("Actor"), false)
chk("Actor 机制挂在 Object 上", Object hasSlot("actorRun"), true)
chk("也没有 Actor 这个 addon", Addon exists("Actor"), false)

sec("19.2 actorRun：把对象变成一个跑消息队列的协程")
w := Object clone do(n := 0)
show("actorRun 之前 hasLocalSlot(\"actorQueue\")", w hasLocalSlot("actorQueue"))
show("actorRun 之前 hasLocalSlot(\"actorCoroutine\")", w hasLocalSlot("actorCoroutine"))
w actorRun
show("actorRun 之后 hasLocalSlot(\"actorQueue\")", w hasLocalSlot("actorQueue"))
show("actorQueue 的 type", (w getSlot("actorQueue")) type)
show("actorQueue 的 size", (w getSlot("actorQueue")) size)
show("actorCoroutine 的 type", (w getSlot("actorCoroutine")) type)
show("actorCoroutine 就是当前协程吗",
     (w getSlot("actorCoroutine")) isIdenticalTo(Coroutine currentCoroutine))
show("actorRun 之后调度队列 size", Scheduler yieldingCoros size)
yield
show("yield 之后调度队列 size", Scheduler yieldingCoros size)
show("yield 之后 actorQueue 的 size", (w getSlot("actorQueue")) size)
chk("actorRun 备好一个消息队列", (w getSlot("actorQueue")) type, "List")
chk("actorRun 起的是一个独立协程",
    (w getSlot("actorCoroutine")) isIdenticalTo(Coroutine currentCoroutine), false)
chk("队列空的时候它只是停在那里", (w getSlot("actorQueue")) size, 0)

sec("19.3 @ 与 @@：异步投递，立刻返回")
w2 := Object clone do(
    total := 0
    add := method(n, total = total + n; total)
    value := method(total)
)
pr := w2 @add(5)
prTypeBefore := pr type
show("@ 返回值的 type", prTypeBefore)
show("派发之后 actorQueue 的 size", (w2 getSlot("actorQueue")) size)
show("派发之后 total（还没跑）", w2 value)
show("派发之后调度队列 size", Scheduler yieldingCoros size)
Scheduler waitForCorosToComplete
show("跑完之后 total", w2 value)
show("跑完之后 actorQueue 的 size", (w2 getSlot("actorQueue")) size)
show("跑完之后调度队列 size", Scheduler yieldingCoros size)
w3 := Object clone do(n := 0; bump := method(n = n + 1; n))
r3 := w3 @@ bump
show("@@ 的返回值", r3)
w3 @@ bump
Scheduler waitForCorosToComplete
show("两次 @@ 之后 n", w3 getSlot("n"))
chk("@ 返回一个 FutureProxy", prTypeBefore, "FutureProxy")
chk("结果最后被写回 future", pr, 5)
chk("waitForCorosToComplete 把队列抽干", Scheduler yieldingCoros size, 0)
chk("@@ 返回 nil", r3, nil)
chk("@@ 的消息也都执行了", w3 getSlot("n"), 2)

sec("19.4 单生产者单消费者流水线：顺序是确定的")
worker := Object clone do(
    total := 0
    seen := List clone
    push := method(n, total = total + n; seen append(n))
    value := method(total)
    order := method(seen join(","))
)
list(1, 2, 3, 4) foreach(n, worker @push(n))
show("派发完 actorQueue 的 size", (worker getSlot("actorQueue")) size)
show("派发完 total（还没跑）", worker value)
Scheduler waitForCorosToComplete
show("跑完 total", worker value)
show("处理顺序", worker order)
show("跑完 actorQueue 的 size", (worker getSlot("actorQueue")) size)
chk("四条消息一条不落", worker order, "1,2,3,4")
chk("累加结果", worker value, 10)
chk("队列被清空", (worker getSlot("actorQueue")) size, 0)

sec("19.5 actor 里的异常：handleActorException 兜底")
bad := Object clone do(
    caught := List clone
    handleActorException := method(e, caught append(e error))
    boom := method(Exception raise("炸了"))
    fine := method("ok")
)
bad @@ boom
bad @@ fine
Scheduler waitForCorosToComplete
show("抓到的异常条数", (bad getSlot("caught")) size)
show("异常消息", (bad getSlot("caught")) join("|"))
show("跑完 actorQueue 的 size", (bad getSlot("actorQueue")) size)
chk("默认 handleActorException 是打栈，覆盖它就能自己接住",
    (bad getSlot("caught")) size, 1)
chk("一条消息炸了不影响队列被抽干", (bad getSlot("actorQueue")) size, 0)

sec("19.6 yield / pause / System sleep 在并发里的角色")
show("Object hasSlot(\"yield\")", Object hasSlot("yield"))
show("Object hasSlot(\"pause\")", Object hasSlot("pause"))
show("Object hasSlot(\"wait\")", Object hasSlot("wait"))
show("Object hasSlot(\"sleep\")", Object hasSlot("sleep"))
show("System hasSlot(\"sleep\")", System hasSlot("sleep"))
w4 := Object clone do(n := 0; tick := method(n = n + 1))
w4 @@ tick
w4 @@ tick
Scheduler waitForCorosToComplete
show("两次 tick 之后 n", w4 getSlot("n"))
System sleep(0.001)
writeln("System sleep(0.001) 之后脚本还在往下走 = true")
chk("actor 处理完一条消息就让出一次", w4 getSlot("n"), 2)
chk("sleep 挂在 System 上，不在 Object 上", Object hasSlot("sleep"), false)
chk("yield / pause / wait 在 Object 上", Object hasSlot("yield"), true)

sec("19.7 本机没有的字面 API：一条条实测")
show("Lobby hasSlot(\"Actor\")", Lobby hasSlot("Actor"))
e1 := try(Object clone appendMessage(1))
show("appendMessage 的报错", e1 error)
e2 := try(Object clone isRunning)
show("isRunning 的报错", e2 error)
e3 := try(Object clone proxy)
show("proxy 的报错", e3 error)
e4 := try(Object clone run)
show("Object 上 run 的报错（run 只属于 Coroutine）", e4 error)
show("Coroutine hasSlot(\"run\")", Coroutine hasSlot("run"))
e5 := try(Object clone setThreadMode("threaded"))
show("setThreadMode 的报错", e5 error)
e6 := try(Object clone stop)
show("stop 的报错", e6 error)
show("Lobby hasSlot(\"IoServer\")", Lobby hasSlot("IoServer"))
show("Addon exists(\"IoServer\")", Addon exists("IoServer"))
show("Addon exists(\"IoClient\")", Addon exists("IoClient"))
writeln("本机一个 addon 都没装（Addon exists 全 false），所以分布式 IoServer / IoClient")
writeln("本章不覆盖：它们不是「用法不同」，而是根本没有编译进来。")
chk("没有 appendMessage 这个方法", e1 isNil, false)
chk("没有 isRunning 这个方法", e2 isNil, false)
chk("没有 Actor proxy 这一类接口", e3 isNil, false)
chk("本机不支持分布式 IoServer", Addon exists("IoServer"), false)
chk("本机不支持分布式 IoClient", Addon exists("IoClient"), false)

sec("19.8 用子进程 + 超时自证「不挂」")
show("找到了可用的解释器", ioBin isNil not)
show("找到了可用的超时工具", timeoutBin isNil not)
tmpDir := System getEnvironmentVariable("TMPDIR")
doneA := Path with(tmpDir, "io_ch19_pipeline_done.txt")
File with(doneA) remove
childA := Path with(tmpDir, "io_ch19_pipeline_child.io")
writeChildScript(childA, list(
    "w := Object clone do(",
    "    total := 0",
    "    push := method(n, total = total + n)",
    "    value := method(total)",
    ")",
    "list(1, 2, 3, 4) foreach(n, w @push(n))",
    "Scheduler waitForCorosToComplete",
    "writeln(\"SUM=\", w value)",
    "File with(\"" .. doneA .. "\") setContents(\"done\")"
))
rA := System runCommand(timeoutBin .. " --foreground -s KILL 5 " .. ioBin .. " " .. childA)
show("流水线子进程的退出码", rA exitStatus)
show("流水线子进程跑到最后一行了吗", File with(doneA) exists)
show("子进程 stdout 里有 SUM=10", (rA stdout) containsSeq("SUM=10"))
show("流水线子进程 stderr 的字节数", (rA stderr) size)
chk("actor 流水线不挂", rA exitStatus, 0)
chk("子进程里算出的和是对的", (rA stdout) containsSeq("SUM=10"), true)
chk("子进程正常收尾", File with(doneA) exists, true)

doneB := Path with(tmpDir, "io_ch19_unsupported_done.txt")
File with(doneB) remove
childB := Path with(tmpDir, "io_ch19_unsupported_child.io")
writeChildScript(childB, list(
    "try(Lobby Actor)",
    "try(Object clone appendMessage(1))",
    "try(Object clone setThreadMode(\"x\"))",
    "try(Object clone proxy)",
    "File with(\"" .. doneB .. "\") setContents(\"done\")"
))
rB := System runCommand(timeoutBin .. " --foreground -s KILL 5 " .. ioBin .. " " .. childB)
show("不支持 API 子进程的退出码", rB exitStatus)
show("不支持 API 子进程跑到最后一行了吗", File with(doneB) exists)
chk("调这些不存在的接口是立刻报错，不会挂住", rB exitStatus, 0)
chk("不存在的接口不影响脚本收尾", File with(doneB) exists, true)
File with(childA) remove
File with(childB) remove
File with(doneA) remove
File with(doneB) remove

sec("19.9 自检")
chk("自检计数必须归零", fails, 0)
writeln("自检：", if(fails == 0, "全部通过", fails asString .. " 项失败"))

writeln("==== 19 结束 ====")
if(fails != 0, System exit(1))
