# 19 · Actor 与并发

> 对应示例：[`examples/19_actors/19_actors.io`](../examples/19_actors/19_actors.io)
>
> **本章部分是实测的能力边界**：本机这份构建里没有 `Actor` 这个 proto，
> 也没有任何 addon（`Addon exists("Actor")` / `("IoServer")` / `("IoClient")` 全是 false）。
> Actor 机制本身是全的，只是挂在 `Object` 上；这一章按实测写，不补任何「应该有」的 API。

## 19.1 本机的 Actor 面貌：Actor proto 不在，机制挂在 Object 上

先老实说清楚有什么、没有什么。`Lobby hasSlot("Actor")` 是 `false`，`Addon exists("Actor")` 也是 `false`；但 `actorRun` / `actorProcessQueue` / `handleActorException` / `@` / `@@` 一个不缺，全在 `Object` 上。

```text
-- 19.1 本机的 Actor 面貌：Actor proto 不在，机制挂在 Object 上
Lobby hasSlot("Actor") = false
Object hasSlot("actorRun") = true
Object hasSlot("actorProcessQueue") = true
Object hasSlot("handleActorException") = true
Object hasSlot("@") = true
Object hasSlot("@@") = true
Object hasSlot("futureSend") = true
Object hasSlot("asyncSend") = true
Addon exists("Actor") = false
取 Actor 这个全局名的报错 = Object does not respond to 'Actor'
```

```io
show("Lobby hasSlot(\"Actor\")", Lobby hasSlot("Actor"))
show("Object hasSlot(\"actorRun\")", Object hasSlot("actorRun"))
e := try(Lobby Actor)
show("取 Actor 这个全局名的报错", e error)
```

`Actor` 不是一个「类」，而是 Io 给每个对象都装好的一套能力：任何对象都能 `actorRun`，任何对象都能收 `@` 消息。

> **为什么重要**：Io 的 Actor 是「每个对象都能变成 actor」，没有单独的 Actor 类型。找 API 时不要 `Lobby Actor`，直接看 `Object` 的槽。

## 19.2 actorRun：把对象变成一个跑消息队列的协程

`actorRun` 第一次被调用时才给接收者装上 `actorQueue`（一个 `List`）和 `actorCoroutine`（一个 `Coroutine`），并把这个协程塞进调度队列；队列空的时候它就静静停在那儿。

```text
-- 19.2 actorRun：把对象变成一个跑消息队列的协程
actorRun 之前 hasLocalSlot("actorQueue") = false
actorRun 之前 hasLocalSlot("actorCoroutine") = false
actorRun 之后 hasLocalSlot("actorQueue") = true
actorQueue 的 type = List
actorQueue 的 size = 0
actorCoroutine 的 type = Coroutine
actorCoroutine 就是当前协程吗 = false
actorRun 之后调度队列 size = 1
yield 之后调度队列 size = 0
yield 之后 actorQueue 的 size = 0
```

```io
w := Object clone do(n := 0)
w actorRun
show("actorQueue 的 type", (w getSlot("actorQueue")) type)
show("actorCoroutine 就是当前协程吗",
     (w getSlot("actorCoroutine")) isIdenticalTo(Coroutine currentCoroutine))
yield
```

`actorCoroutine` 就是 18 章那个协程；它的 `runMessage` 是 `actorProcessQueue`，一个「取队首 Future → 执行 → `yield` → 空了就 `pause`」的循环。

> **为什么重要**：Actor 与协程不是两套东西——**Actor 就是一个跑消息队列的协程**。理解了 18 章，19 章只剩「消息从哪来、结果往哪去」。

## 19.3 @ 与 @@：异步投递，立刻返回

`obj @someMethod(args)` 把消息打包成一个 `Future` 塞进 `actorQueue`，启动 actor 协程，然后**立刻**返回一个 `FutureProxy`；`@@` 做同样的事但返回 `nil`。

```text
-- 19.3 @ 与 @@：异步投递，立刻返回
@ 返回值的 type = FutureProxy
派发之后 actorQueue 的 size = 1
派发之后 total（还没跑） = 0
派发之后调度队列 size = 1
跑完之后 total = 5
跑完之后 actorQueue 的 size = 0
跑完之后调度队列 size = 0
@@ 的返回值 = nil
两次 @@ 之后 n = 2
```

```io
w2 := Object clone do(
    total := 0
    add := method(n, total = total + n; total)
    value := method(total)
)
pr := w2 @add(5)
show("派发之后 total（还没跑）", w2 value)
Scheduler waitForCorosToComplete
show("跑完之后 total", w2 value)
```

注意「派发之后 total 还是 0」——`@` 只是入队。要在主协程里等结果，`Scheduler waitForCorosToComplete` 是最省事的抽干方式（`while(yieldingCoros size > 0, yield)`）。

> **为什么重要**：`@` 返回的是 **proxy 而不是值**。忘了这一点，`@` 的返回值会在不知不觉中被当成结果用，直到某次类型报错才暴露。

## 19.4 单生产者单消费者流水线：顺序是确定的

一个生产者、一个消费者、队列里排着 4 条消息——这种形状下顺序完全可预测，可以做严格断言。

```text
-- 19.4 单生产者单消费者流水线：顺序是确定的
派发完 actorQueue 的 size = 4
派发完 total（还没跑） = 0
跑完 total = 10
处理顺序 = 1,2,3,4
跑完 actorQueue 的 size = 0
```

```io
worker := Object clone do(
    total := 0
    seen := List clone
    push := method(n, total = total + n; seen append(n))
    value := method(total)
    order := method(seen join(","))
)
list(1, 2, 3, 4) foreach(n, worker @push(n))
Scheduler waitForCorosToComplete
show("处理顺序", worker order)
```

`@` 在投递时就把实参求值好（`asMessageWithEvaluatedArgs`），所以 `n` 抓的是**投递那一刻**的值，不是执行那一刻的——这正是它顺序确定的原因。

> **为什么重要**：写并发测试不要靠 sleep 或运气。只要「一个生产者 + 一个队列 + 显式抽干」，结果就是确定的，可以像普通单元测试一样断言。

## 19.5 actor 里的异常：handleActorException 兜底

actor 处理每条消息时都包在 `try` 里，炸了就交给 `handleActorException`。默认实现是 `e showStack`（往 stdout 打栈），覆盖它就能自己接住。

```text
-- 19.5 actor 里的异常：handleActorException 兜底
抓到的异常条数 = 1
异常消息 = 炸了
跑完 actorQueue 的 size = 0
```

```io
bad := Object clone do(
    caught := List clone
    handleActorException := method(e, caught append(e error))
    boom := method(Exception raise("炸了"))
    fine := method("ok")
)
bad @@ boom
bad @@ fine
Scheduler waitForCorosToComplete
```

两条消息一条炸一条正常，队列照样被抽干——**异常不会卡住队列**，但默认实现会把栈打到 stdout，污染示例输出。

> **为什么重要**：想写「不吐任何杂音的示例」，actor 里的异常必须显式覆盖 `handleActorException`；否则一次 `Exception: ...` 横幅就会让整个脚本的可复现性判定失败。

## 19.6 yield / pause / System sleep 在并发里的角色

Actor 的「让出」靠 `yield` / `pause`（在 `Object` 上）；真正要睡觉的是 `System sleep`，它在 `System` 上而不是 `Object` 上；`Object wait(s)` 则是「队列里有人就 `yield` 等着、没人就 `System sleep`」。

```text
-- 19.6 yield / pause / System sleep 在并发里的角色
Object hasSlot("yield") = true
Object hasSlot("pause") = true
Object hasSlot("wait") = true
Object hasSlot("sleep") = false
System hasSlot("sleep") = true
两次 tick 之后 n = 2
System sleep(0.001) 之后脚本还在往下走 = true
```

```io
w4 := Object clone do(n := 0; tick := method(n = n + 1))
w4 @@ tick
w4 @@ tick
Scheduler waitForCorosToComplete
System sleep(0.001)
```

`actorProcessQueue` 处理完一条消息会 `yield` 一次再处理下一条，所以消息之间是「可交错的」；但也正因为这样，不要用 `sleep` 去「等消息跑完」——用 `waitForCorosToComplete`，它是确定性的。

> **为什么重要**：`System sleep` 出现在并发代码里，通常意味着在拿时间当同步手段。Io 的队列有确定的抽干方式，别把时间塞进逻辑，更别把时间写进输出。

## 19.7 本机没有的字面 API：一条条实测

把「看起来应该有」的名字挨个试一遍，看解释器怎么说。结论贴在下面，都是实测输出。

```text
-- 19.7 本机没有的字面 API：一条条实测
Lobby hasSlot("Actor") = false
appendMessage 的报错 = Object does not respond to 'appendMessage'
isRunning 的报错 = Object does not respond to 'isRunning'
proxy 的报错 = Object does not respond to 'proxy'
Object 上 run 的报错（run 只属于 Coroutine） = Object does not respond to 'run'
Coroutine hasSlot("run") = true
setThreadMode 的报错 = Object does not respond to 'setThreadMode'
stop 的报错 = Object does not respond to 'stop'
Lobby hasSlot("IoServer") = false
Addon exists("IoServer") = false
Addon exists("IoClient") = false
本机一个 addon 都没装（Addon exists 全 false），所以分布式 IoServer / IoClient
本章不覆盖：它们不是「用法不同」，而是根本没有编译进来。
```

```io
e1 := try(Object clone appendMessage(1))
e5 := try(Object clone setThreadMode("threaded"))
show("Addon exists(\"IoServer\")", Addon exists("IoServer"))
```

| 你在别处可能见过的名字 | 本机实测 |
|---|---|
| `Actor clone` / `Actor proxy` | 没有 `Actor` proto |
| `appendMessage` | `Object does not respond to 'appendMessage'` |
| `isRunning` / `stop` | 都没有 |
| `main` / `setThreadMode` | 都没有（`main` 只在 `Coroutine` 上） |
| `run` | 只在 `Coroutine` 上 |
| `IoServer` / `IoClient` | `Addon exists` 全是 false，本章不覆盖 |

> **为什么重要**：Io 的 addon 是**编译期决定**的。同一份教程在另一台装齐 addon 的机器上，这些名字可能真的存在。所以在任何示例里都先 `hasSlot` / `Addon exists` 探一下，再决定走哪条路。

## 19.8 用子进程 + 超时自证「不挂」

本机没有第三方并发验证器，所以这一章的判定做成自包含：把同一段流水线丢进子进程，用硬超时兜底，再用「是否跑到最后一行」当作完成证据。

```text
-- 19.8 用子进程 + 超时自证「不挂」
找到了可用的解释器 = true
找到了可用的超时工具 = true
流水线子进程的退出码 = 0
流水线子进程跑到最后一行了吗 = true
子进程 stdout 里有 SUM=10 = true
流水线子进程 stderr 的字节数 = 0
不支持 API 子进程的退出码 = 0
不支持 API 子进程跑到最后一行了吗 = true
```

```io
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
```

判定用三样东西，都不依赖时间：退出码 `0`、stdout 里出现了 `SUM=10`、「最后一行」的标记文件存在。超时工具一律加 `--foreground -s KILL`——不带 `--foreground` 时 gtimeout 会杀掉自己的进程组，父进程 stderr 里会多出一行 `Killed: 9`，把「stderr 必须为空」这条纪律毁掉。

> **为什么重要**：在协作式并发里，「没挂」本身就是一条需要被证明的性质；而唯一安全的证明方式是把不确定的部分（是否会挂）丢给一个确定的外部观察者（子进程 + 硬超时）。

## 19.9 坑位清单

1. **`Actor` 这个 proto 本机不存在** → 别写 `Actor clone`；actor 能力挂在 `Object` 上，入口是 `actorRun` / `@` / `@@`。
2. **本机一个 addon 都没装** → `Addon exists("Actor")` / `("IoServer")` / `("IoClient")` 全是 false，分布式那部分本章不覆盖。
3. **`@` 返回的是 `FutureProxy` 不是结果** → 结果要靠 `Scheduler waitForCorosToComplete` 抽干队列后再读接收者，「派发完 total 还是 0」是正常的。
4. **`@@` 返回 `nil`** → 两者功能相同，只差「要不要那个 proxy」；`futureSend` 是 `@` 的别名，`asyncSend` 是 `@@` 的别名。
5. **`actorQueue` / `actorCoroutine` 要等第一次 `actorRun` 才出现** → 之前 `hasLocalSlot` 是 false，直接读会拿到 `nil`。
6. **actor 里的异常默认会 `e showStack` 打到 stdout** → 想干净就覆盖 `handleActorException`，否则一条异常横幅就能毁掉示例的可复现性。
7. **`yield` / `pause` / `wait` 在 `Object` 上，`sleep` 在 `System` 上** → `Object clone sleep(0.001)` 会报 `Object does not respond to 'sleep'`。
8. **别用 `System sleep` 当同步手段** → 用 `Scheduler waitForCorosToComplete`，它是确定性的；时间既不能进逻辑也不能进输出。
9. **`run` / `main` 是 `Coroutine` 的槽，不是对象的** → `Object clone run` 报 `Object does not respond to 'run'`。
10. **子进程超时必须带 `--foreground -s KILL`** → 不带 `--foreground` 时 gtimeout 会连自己的进程组一起杀，父进程 stderr 会多出 `Killed: 9` 一行。

---

上一章：[18 · 协程与 Future](18-coroutines.md) · 下一章：[20 · 单元测试](20-testing.md)
