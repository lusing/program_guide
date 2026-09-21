# 18 · 协程与 Future

> 对应示例：[`examples/18_coroutines/18_coroutines.io`](../examples/18_coroutines/18_coroutines.io)
>
> 本章 18.7 是**实测的能力边界**：队列耗尽时 Io 不是抛异常，而是死循环，
> 只能用子进程 + 硬超时把现象测出来。示例里的这一段必须靠外部超时工具跑。

## 18.1 协程与调度器：Coroutine / Scheduler / yieldingCoros

`Coroutine currentCoroutine` 拿到当前协程；调度器就是 `Scheduler` 上的一个 `List`，`Coroutine yieldingCoros` 和 `Scheduler yieldingCoros` 是**同一个对象**。

```text
-- 18.1 协程与调度器：Coroutine / Scheduler / yieldingCoros
Coroutine currentCoroutine 的 type = Coroutine
isCurrent = true
isYielding = false
Scheduler currentCoroutine 就是同一个 = true
Coroutine yieldingCoros 就是 Scheduler yieldingCoros = true
此刻队列 size = 0
实现方式 = frame-based
Scheduler hasSlot("waitForCorosToComplete") = true
```

```io
c := Coroutine currentCoroutine
show("Coroutine currentCoroutine 的 type", c type)
show("Coroutine yieldingCoros 就是 Scheduler yieldingCoros",
     Coroutine yieldingCoros isIdenticalTo(Scheduler yieldingCoros))
show("此刻队列 size", Scheduler yieldingCoros size)
show("实现方式", c implementation)
```

这份构建是**帧式**实现（`implementation` 返回 `"frame-based"`），不是早期 Io 的 C-stack 切换版本，所以协程就是「一条自己的求值栈 + 队列里的一个位置」。

> **为什么重要**：Io 没有抢占式线程，也没有锁。所谓「并发」全部由 `yield` 这一个显式动作驱动；想清楚「谁在队列里排队、谁在跑」，比记 API 重要得多。

## 18.2 coroDo：创建即开跑，跑到第一个 yield 才回来

`coroDo(块)` 做的事是：新建一个协程 → 把**创建者**插到 `yieldingCoros` 队首 → `run`。所以子协程的代码**立刻**开始跑，一直跑到它的第一个 `yield` 才把控制权还给你。

```text
-- 18.2 coroDo：创建即开跑，跑到第一个 yield 才回来
  子协程跑到第一个 yield
coroDo 返回值的 type = Coroutine
coroDo 之后 trace = 子1 主1
coroDo 之后队列 size = 1
yield 之后 trace = 子1 主1 子2 主2
yield 之后队列 size = 1
队首就是创建者自己 = true
```

```io
trace := List clone
coro := coroDo(
    trace append("子1")
    writeln("  子协程跑到第一个 yield")
    yield
    trace append("子2")
)
trace append("主1")
yield
trace append("主2")
```

第二个要点在最后一行：**`coroDo` 会把创建者留在队列里**。如果你以后再往队列里塞别的协程，`yield` 先轮到的可能还是自己，那个协程就永远不动。

> **为什么重要**：`coroDo` 不是「注册回调」，它是「立刻切过去」。把 `coroDo` 当异步注册用，就会得到「代码顺序和我写的不一样」的错觉。

## 18.3 yield 与 pause：队列里没有别人时什么都不发生

`yield` 遇到空队列直接返回；`pause` 遇到空队列（而且自己就是当前协程）会抛异常——它认为「没人可恢复，整个程序没法继续」。

```text
-- 18.3 yield 与 pause：队列里没有别人时什么都不发生
清过之后队列 size = 0
空队列上 yield 之后队列 size = 0
空队列上 pause 的异常消息 = Scheduler: nothing left to resume so we are exiting
pause 之后队列 size = 0
```

```io
Coroutine yieldingCoros remove(Coroutine currentCoroutine)
yield
e := try(Coroutine currentCoroutine pause)
show("空队列上 pause 的异常消息", e error)
```

| 方法 | 语义 |
|---|---|
| `yield` | 把控制权交给队首；队列空则什么都不做 |
| `resume` | 切到接收者（没跑过就启动它） |
| `resumeLater` | 把自己挪到队首，但不立即切过去 |
| `pause` | 把自己从队列里摘掉再让出；没人可恢复就抛异常 |

> **为什么重要**：`yield` 是「温和」的（空队列也不炸），`pause` 是「严格」的。在有可能空队列的地方用 `pause`，等于给脚本埋了一颗随时引爆的雷。

## 18.4 协程的槽：没有 status，label 是地址

Io 的协程**没有** `status` 这个槽，状态只能拆成几个布尔去问：`isCurrent`、`isYielding`；`label` 默认返回 `uniqueId`（地址那类东西），千万别整条打进输出。

```text
-- 18.4 协程的槽：没有 status，label 是地址
Coroutine slotNames sort = backTraceString,callStack,currentCoroutine,currentFrame,debugWriteln,exception,freeStack,handlerStack,ignoredCoroutineMethodNames,implementation,inException,init,ioStack,isCurrent,isYielding,label,main,parentCoroutine,pause,pauseCurrentAndResumeSelf,raiseException,rawSignalException,recentInChain,result,resume,resumeLater,resumeParentCoroutine,run,runLocals,runMessage,runTarget,setException,setHandlerStack,setInException,setLabel,setMessageDebugging,setParentCoroutine,setRecentInChain,setResult,setRunLocals,setRunMessage,setRunTarget,setStackSize,setYieldingCoros,showStack,showYielding,stackSize,typeId,yield,yieldCurrentAndResumeSelf,yieldingCoros
hasSlot("status") = false
hasSlot("isYielding") = true
hasSlot("isCurrent") = true
hasSlot("result") = true
hasSlot("ioStack") = true
hasSlot("callStack") = true
hasSlot("stack") = false
当前协程 ioStack 是个非空 List = true
  打个卡就结束
setLabel("worker") 之后 label 的前 7 个字符 = worker_
label 比 8 个字符长（后面跟的是 uniqueId） = true
uniqueId 是地址那类东西，所以 label 永远不要整条打进输出
```

```io
show("hasSlot(\"status\")", Coroutine hasSlot("status"))
c4 := coroDo(writeln("  打个卡就结束"))
c4 setLabel("worker")
show("setLabel(\"worker\") 之后 label 的前 7 个字符", c4 label exSlice(0, 7))
```

`label` 的完整形态是 `"worker_" .. uniqueId`，`uniqueId` 每次都变。栈也不叫 `stack`，而是 `ioStack` / `callStack`。

> **为什么重要**：任何拿 `label` / `uniqueId` / `typeId` 当输出的调试代码都会破坏可复现性。要区分协程，用自己的计数器，不要用引擎给的 id。

## 18.5 Coroutine clone：手工搭协程，局部状态自己给

`coroDo` 的 `runLocals` 是 `call sender`——**和创建者共用一套 locals**。要真正的独立状态，就自己 `Coroutine clone`、自己给三个槽（`runTarget` / `runLocals` / `runMessage`）、自己排进队列。

```text
-- 18.5 Coroutine clone：手工搭协程，局部状态自己给
runMessage 的 type = Message
run 之前 box v = 0
run 之后 box v = 100
协程结束时的 result = 100
cc isYielding = false
coroDo 里改过之后，创建者这边的 x = 1
coroDo 之后队列 size = 2
排入 cc2 之后队列 size = 1
yield 之后 box2 v = 5
```

```io
box := Object clone do(v := 0)
cc := Coroutine clone
cc setSlot("runTarget", box)
cc setSlot("runLocals", box)
cc setSlot("runMessage", Message fromString("v := v + 100"))
cc run
show("协程结束时的 result", cc result)

box2 := Object clone do(v := 0)
cc2 := Coroutine clone
cc2 setSlot("runTarget", box2)
cc2 setSlot("runLocals", box2)
cc2 setSlot("runMessage", Message fromString("v := v + 5"))
Coroutine yieldingCoros append(cc2)
yield
```

`run` 会立刻切过去跑到底（没有 `yield` 就一路跑完），跑完把 `runMessage` 的值放进 `result`；`yield` 则只交给队首。

> **为什么重要**：`coroDo` 的便利是拿作用域换来的。需要隔离状态的协程，一律用 `Coroutine clone` 把 `runLocals` 指到一个新对象上。

## 18.6 Future 与 FutureProxy：@ 不是协程的字面量

Io 里**没有** `@(...)` 这种协程字面量。`@` 和 `@@` 是 `Object` 上的两个二元运算符（优先级 0），作用是「把消息异步投给一个 actor，立刻返回」。`Future` 也没有 `result` / `setValue`，生产者的接口叫 `setResult`。

```text
-- 18.6 Future 与 FutureProxy：@ 不是协程的字面量
@ 是二元运算符，优先级 = 0
@@ 的优先级 = 0
Object hasSlot("@") = true
futureSend 就是 @ = true
asyncSend 就是 @@ = true
Future slotNames sort = futureProxy,runMessage,runTarget,setResult,setRunMessage,setRunTarget,setWaitingCoros,type,waitOnResult,waitingCoros
Future hasSlot("result") = false
Future hasSlot("setValue") = false
Future hasSlot("setResult") = true
Future hasSlot("waitOnResult") = true
futureProxy 一开始的 type = FutureProxy
setResult(42) 之后 pr 的 type = Number
setResult(42) 之后 pr 的值 = 42
```

```io
f := Future clone
pr := f futureProxy
prTypeBefore := pr type
f setResult(42)
show("futureProxy 一开始的 type", prTypeBefore)
show("setResult(42) 之后 pr 的 type", pr type)
```

`FutureProxy` 的 `forward` 会先 `waitOnResult` 再转发，所以**访问一个还没有结果的 proxy 会把当前协程 pause 掉**；`setResult` 则让 proxy 直接 `become` 成结果本身——类型都会变。

> **为什么重要**：`@`/`@@` 是 Actor 的入口而不是协程语法糖。它们的返回值是 `FutureProxy`，`@@` 返回 `nil`；两者只差「要不要那个 proxy」。

## 18.7 实测能力边界：队列耗尽是死循环，只能被外部强杀

**这一类调用必须放进子进程 + 外部超时**，因为 Io 在这里不抛异常。做法照 `examples/13_exceptions/observe_13_uncaught.io`：解释器路径由 `IO_BIN` 注入，没有就退回常见安装位置；超时工具用 `/opt/local/bin/gtimeout`，并且要 `--foreground -s KILL`（否则 gtimeout 会连自己的进程组一起杀，父进程的 stderr 会被污染）。

```text
-- 18.7 实测能力边界：队列耗尽是死循环，只能被外部强杀
找到了可用的解释器 = true
找到了可用的超时工具 = true
子命令形状：<timeout> --foreground -s KILL 3 <io> <child>
挂死子进程的退出码（137 = 被 SIGKILL 强杀） = 137
挂死子进程跑到最后一行了吗 = false
挂死子进程 stderr 的字节数 = 0
未设值的 Future 被访问后的退出码 = 0
子进程 stdout 里有 nothing left to resume = true
未设值的 Future 子进程跑到最后了吗 = false
```

```io
hangChild := Path with(tmpDir, "io_ch18_hang_child.io")
writeChildScript(hangChild, list(
    "// 队列里只剩自己：yield 立刻返回，loop 就成了死循环",
    "coroDo(loop(yield))",
    "Coroutine currentCoroutine pause",
    "File with(\"" .. hangDone .. "\") setContents(\"done\")"
))
rHang := System runCommand(timeoutBin .. " --foreground -s KILL 3 " .. ioBin .. " " .. hangChild)
show("挂死子进程的退出码（137 = 被 SIGKILL 强杀）", rHang exitStatus)
```

实测结论有两条，都是负面的：

1. **队列里只剩自己时 `yield` 是空操作**，`loop(yield)` 于是变成 100% CPU 的死循环。退出码是 `137`（被 `SIGKILL` 强杀），最后一行永远执行不到。
2. **访问一个没人 `setResult` 的 `FutureProxy`** 会走 `pause`，空队列时抛 `Scheduler: nothing left to resume so we are exiting`；这条是**未捕获异常**，脚本中断、退出码仍是 `0`。

> **为什么重要**：Io 的挂死不带任何提示——没有 watchdog、没有超时、没有异常。任何可能进入 `loop(yield)` / `waitForCorosToComplete` / `waitOnResult` 的路径，都要么保证队列里始终有别人，要么从外面套超时。

## 18.8 确定性交替：两个协程 + 一份共享 List

协程是协作式的，`yield` 写在哪里就在哪里切，所以交替顺序**完全可预测**——这让协程的测试可以像普通代码一样断言。

```text
-- 18.8 确定性交替：两个协程 + 一份共享 List
清过之后队列 size = 0
交替顺序 = A1 B1 M1 A2 B2 M2 A3 M3 B3 M4 M5
```

```io
Coroutine yieldingCoros remove(Coroutine currentCoroutine)
order := List clone
a := coroDo(order append("A1"); yield; order append("A2"); yield; order append("A3"))
b := coroDo(order append("B1"); yield; order append("B2"); yield; order append("B3"))
order append("M1"); yield
order append("M2"); yield
order append("M3"); yield
order append("M4"); yield
order append("M5")
```

每次 `yield` 都做同一件事：把当前协程追加到队尾、取出队首、切过去。于是顺序是 `A1 B1 M1 A2 B2 M2 A3 M3 B3 M4 M5`，一次不差。

> **为什么重要**：并发代码难测，是因为很多运行时把「什么时候切」交给调度器。Io 把这件事交给源码里的 `yield`——所以要写可测的并发，就把 `yield` 显式写出来。

## 18.9 坑位清单

1. **`coroDo` 是「立刻切过去跑」不是「注册」** → 它会跑到子协程第一个 `yield` 才返回。
2. **`coroDo` 会把创建者留在 `yieldingCoros` 里** → 之后再排队别的协程，`yield` 可能先轮到自己，那个协程永远不动；先 `Coroutine yieldingCoros remove(Coroutine currentCoroutine)`。
3. **`coroDo` 的 `runLocals` 是 `call sender`** → 子协程和创建者共用 locals，改一个看得见另一个；要隔离就用 `Coroutine clone` 自己给 `runLocals`。
4. **空队列上 `yield` 什么都不做，`pause` 却会抛异常** → `pause` 报 `Scheduler: nothing left to resume so we are exiting`，且它是未捕获异常（脚本中断、退出码仍 0）。
5. **队列里只剩自己时 `yield` 立刻返回** → `loop(yield)` 是 100% CPU 死循环，只能被外部强杀（退出码 137）；这类调用必须放进子进程 + 超时。
6. **访问没人 `setResult` 的 `FutureProxy` 会挂起当前协程** → 空队列时变成未捕获异常并中断脚本，子进程退出码是 0，属假阳性。
7. **Io 没有 `Coroutine status` 这个槽** → 状态拆成 `isCurrent` / `isYielding` 问，存在性用 `hasSlot` 先确认。
8. **`Coroutine label` 默认是 `uniqueId`（地址）** → `setLabel("x")` 也只是拼成 `"x_" + uniqueId`，整条打进输出会破坏可复现性。
9. **`@` / `@@` 不是协程字面量** → 它们是 `Object` 上的二元运算符（`futureSend` / `asyncSend` 的别名），只有 Actor 语境里才有意义。
10. **`Future` 没有 `result` / `setValue`** → 生产者写 `setResult`；`setResult` 会让 `FutureProxy` 直接 `become` 成结果，读出来类型都变了。

---

上一章：[17 · 元编程与反射](17-meta.md) · 下一章：[19 · Actor 与并发](19-actors.md)
