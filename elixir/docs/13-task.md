# 13 · Task 并发

> 对应示例：`examples/13_tasks/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

第 12 章的 spawn/send/receive 是裸原语，每一步都要自己约定消息格式、配对引用、
处理超时与死亡。`Task` 把最常见的模式——**分叉—汇合（fork/join）**：把活儿拆给
N 个进程，稍后收结果——封装成两个调用：`Task.async/1` 与 `Task.await/2`。

```text
Task.async(fun)  ≈  spawn 一个进程跑 fun + 与调用方 link + 约定把结果作为回复
Task.await(task) ≈  receive 等这条约定的回复 + 失败/超时自动传播
```

## 13.1 async/await 与保序的 pmap

经典并行 map 只有三行：先把所有任务**分叉**出去，再按任务列表顺序逐个**汇合**：

```elixir
def pmap(enumerable, fun) do
  enumerable
  |> Enum.map(&Task.async(fn -> fun.(&1) end))
  |> Enum.map(&Task.await(&1, 5_000))
end
```

关键性质：**结果顺序等于输入顺序，与完成先后无关**。await 是逐个等的——
第一个任务没回来时，即使第三个早做完了，结果也在邮箱里排队。run.exs 让
3 号任务最先完工，汇合顺序仍是 `[1, 2, 3]`：

```text
-- 1. async/await：分叉—汇合，await 按任务顺序保序 --
  pmap(1..4, slow_square) => [1, 4, 9, 16]
  3 号最先完工，按 await 顺序汇合 => [1, 2, 3]（默认保序）
```

await 的第二个参数是超时毫秒（默认 5000）。测试还断言了每个任务跑在
**独立进程**里（收集到两个互不相同、且不是调用方的 pid）。

## 13.2 失败传播（1.20 最重要的语义）

**`Task.await/2` 在任务崩溃时不是「重抛异常」，而是让调用方进程 exit。**
这是本章开发时实测出来、且与很多教程旧描述不同的事实：`Task.async` 与调用方
之间有 link，任务以 `{异常, 栈迹}` 异常死亡时，退出信号沿 link 抵达调用方，
调用方进程以同样原因退出——`try/rescue` 根本接不住（rescue 只接 raise/error，
不接 exit 信号）：

```elixir
try do
  Task.async(fn -> raise RuntimeError, "x" end) |> Task.await()
rescue
  RuntimeError -> :never_happens   # 1.20 实测：进程直接 EXIT
end
```

想在边界安全收口，要用三件套：**`trap_exit` + `yield` + 排空信号**：

```elixir
task = Task.async(fun)
Process.flag(:trap_exit, true)          # 退出信号变成邮箱消息，不杀人

result =
  case Task.yield(task, 1_000) do       # yield 不杀人：{:ok,v} / {:exit,r} / nil
    {:ok, value} -> {:ok, value}
    {:exit, {exception, stacktrace}} when is_exception(exception) ->
      {:error, {exception.__struct__, Exception.message(exception)}}
    {:exit, reason} -> {:exit, reason}
    nil -> Task.shutdown(task, :brutal_kill); :timeout
  end

drain_exit(task.pid)                    # 收掉 link 投递的 {:EXIT,...}
Process.flag(:trap_exit, false)         # 复位进程级标志
result
```

`yield/2` 的文档明确说：只有「任务正常退出 `:normal`、调用方 trap_exit、
或任务与调用方没有 link」三种情况下才可能返回 `{:exit, reason}`，
否则任务失败会照常杀死拥有者进程。

不做防护时，死因可以由**另一个进程** monitor 观察到（本章的
`await_exit_reason/1`）：

```text
-- 2. 失败传播：任务异常死亡会连坐杀死 await 的调用方进程 --
  safe_await 成功   => {:ok, 42}
  safe_await 异常   => {:error, {RuntimeError, "boom"}}（trap_exit + yield 收口）
  safe_await 退出   => {:exit, :gone}
  不防护地 await 崩溃任务，runner 死因 => {:exc, RuntimeError, "boom"}
```

## 13.3 超时：yield 温和，await 致命

两种等待对超时的态度截然不同：

- `Task.yield(task, ms)`：到期返回 **`nil`**，任务和调用方都活着。
  你可以 `Task.shutdown(task, :brutal_kill)` 收掉任务防止泄漏，
  也可以再次 yield 继续等；
- `Task.await(task, ms)`：到期**让调用方进程退出**，退出原因形如
  `{:timeout, {Task, :await, [task, 毫秒数]}}`（同时杀掉超时任务）。
  本章用 monitor 盯着一个 runner 进程做 await，拿到的规范化死因就是
  `{:timeout, :await}`。

```text
-- 3. 超时：yield 返回 nil 可 shutdown；await 超时直接杀调用方 --
  yield 慢任务 20ms => :timeout
  yield 快任务      => {:ok, :ready}
  await 超时的 runner 死因 => {:timeout, :await}
```

经验法则：**调用方应该比任务活得久、需要自己决定超时策略 → yield；
「任务必须成，不成大家一起崩」→ await。**

## 13.4 async_stream：把并发塞进流式管线

对集合里的**每个元素**起一个任务，用 `Task.async_stream/2`：
它返回一个惰性流，每个结果包成 `{:ok, value}`，默认**按输入顺序**产出
（内部会为保序做缓冲），并用 `max_concurrency` 限制并发度，天然带背压：

```text
-- 4. async_stream：每个元素一个任务，默认按输入顺序产出 --
  stream_squares(1..4) => [ok: 1, ok: 4, ok: 9, ok: 16]
```

注意 1.20 的选项事实（本章查了本机 beam 文档确认）：

- `ordered: false` 关掉保序缓冲，谁先完成谁先出列（也适合只做副作用的场景）；
- **没有「任务失败后逐元素继续」的选项**：任一任务异常退出，正在枚举整个
  stream 的进程会以同样原因退出——和 await 是同一套连坐语义；
- `on_timeout: :exit`（默认）→ 超时杀死调用方；
  `on_timeout: :kill_task` → **只杀那一个任务**，该位置产出
  `{:exit, :timeout}`，调用方存活。

```text
-- 5. 流的边界：坏任务默认杀死整个 stream；超时可选只杀任务 --
  kill_task 逐元素隔离 => [ok: 10, exit: :timeout]
  任务 raise 的 stream 死因 => {:exc, RuntimeError, "boom"}
```

要让单个元素的失败不炸掉全流，标准做法是在**任务函数内部**自己 try/rescue，
统一返回 `{:ok, v}` / `{:error, reason}`，让异常永远不穿出任务边界。

## 13.5 Task.Supervisor：受监督的临时任务

裸 `Task.async` 的任务挂在调用方身上（调用方死，任务也被清理）。
想让任务接受监督树管理，用 `Task.Supervisor`：

- `Task.Supervisor.start_child(sup, fun)`：fire-and-forget 受监督任务；
- `Task.Supervisor.async(sup, fun)` + await：受监督的可汇合任务；
- 任务默认重启策略是 **`:temporary`——崩了不重启，只从监督者处摘除**，
  监督者本身毫发无损。

```text
-- 6. Task.Supervisor：受监督任务，崩溃不拖垮监督者 --
  supervised_value => 42
  子任务崩溃后 {监督者存活?, 活跃子任务数} => {true, 1}
  （Task 默认 :temporary——崩了不重启，只摘除；要重启需自己包 GenServer）
```

最后一行的 `{true, 1}` 是关键证据：起了一个常驻任务和一个必崩任务，
崩溃通知后监督者存活，名下只剩 1 个活跃子任务。（想要「崩了自动重启」
不能靠 Task——那是第 16 章 Supervisor + GenServer 的职责。）
本章实现时还处理了一个竞态：monitor 的 DOWN 到达时，监督者可能尚未完成
子进程摘除，所以活跃计数用轮询等到稳定值再读。

## 13.6 选型

```text
  每个元素都要做、最后收结果   -> Task.async_stream（背压+保序+并发上限）
  分叉若干异构任务再逐个汇合   -> Task.async + Task.await（保序）
  超时了还想自己决定怎么办     -> Task.yield（nil）+ Task.shutdown，别用 await
  fire-and-forget 的副作用     -> Task.start（没人 await，崩了没人知道）
  任务需要被监督/动态启停      -> Task.Supervisor.start_child/async
  长生命周期、多条消息的服务    -> Task 不合适，用第 15 章的 GenServer
```

Task 的边界要划清：它解决的是「**一次性**并行计算的分叉汇合」。
一旦你需要进程长期存活、处理多条不同消息、被外部按名字引用、崩了自动重启，
就进入了 Agent/GenServer/Supervisor 的世界——接下来三章依次展开。

## 13.7 坑位清单

1. **1.20 里任务崩溃 = 调用方进程 exit，不是 raise**。`try/rescue` 接不住
   `Task.await` 的失败；要在同一进程收口，必须 `trap_exit` + `yield`
   并排空 `{:EXIT}` 信号、复位标志。
2. **`trap_exit` 打开后必须复位**，否则同一进程后续所有 link 语义全变；
   trap 期间 link 信号进邮箱，用完要 drain，否则污染后续 receive。
3. **await 超时同样杀调用方**，原因 `{:timeout, {Task, :await, [task, ms]}}`；
   温和等待用 `yield`（返回 `nil`），并记得 `shutdown` 泄漏的慢任务。
4. **`yield` 返回 `{:exit, reason}` 有前提**（`:normal` / trap_exit / nolink），
   不满足时任务异常照样杀死拥有者——不要以为用了 yield 就天然安全。
5. **async_stream 没有「逐元素容错继续」选项**：一个任务异常默认杀死枚举
   整个流的进程；要容错就在任务函数内部自己 rescue 成 `{:error, _}`。
   只有超时能用 `on_timeout: :kill_task` 做逐元素隔离，得到
   `{:exit, :timeout}`。
6. **保序不等于按时**：默认 `ordered: true` 会缓冲先完成的结果，慢元素会
   拖住它之后所有元素的交付；只做副作用时用 `ordered: false`。
7. **Task 默认 `:temporary`，崩了不重启**。期待「任务挂了自动拉起」会落空，
   那是 Supervisor + GenServer 的功能。
8. **异步任务里别返回不可确定的值**（pid、时间、ref），或在汇合后排序/规范化；
   跨调度器（`+S 1:1`）完成顺序会变，顺序只能来自数据本身。
9. **故意制造任务崩溃的脚本/测试要关崩溃报告**
   （`Logger.configure(level: :none)`），否则带时间戳/pid 的报告会破坏
   输出的确定性（本章 test_helper 与 run.exs 都这么做）。
10. **别用 Task 表达长生命周期服务**：一个 Task 只对应一次计算、一条结果；
    需要「服务进程」时从第 14 章的 Agent 开始。

---

下一章：[14 · Agent 状态](14-agent.md)——把第 12 章手写的「递归参数状态
loop」封装成 `start/get/update/get_and_update`，看看它的便利与适用边界。
