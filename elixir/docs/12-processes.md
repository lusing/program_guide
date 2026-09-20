# 12 · 进程与消息

> 对应示例：`examples/12_processes/`（独立 mix 工程，含 ExUnit 测试、doctest 与 `run.exs` 驱动脚本）

BEAM 的并发单元是**进程**：由虚拟机调度的轻量执行流（不是操作系统线程），
创建成本微秒级、内存 KB 级，单机可以开几十万个。它们之间**不共享内存**，
唯一的通信方式是消息。三原语是：

- `spawn(fun)`：拉起一个进程跑 `fun`，立即返回 pid；
- `send(pid_or_name, msg)`：把消息**异步**投进对方邮箱（发了就返回，不等处理）；
- `receive`：在自己的邮箱里**按模式**挑消息，没挑到就阻塞。

本章所有对外函数和脚本输出都**不含 pid/reference**：它们每次运行都变，
不能写进确定性断言，只断言性质（`is_pid/1`、计数、退出原因标签）。

## 12.1 spawn / send / receive

裸三原语的一次往返：父进程 spawn 一个 echo 子进程，发 `{:ping, self()}`，
子进程回复 `:pong`：

```elixir
me = self()

echoer =
  spawn(fn ->
    receive do
      {:ping, from} -> send(from, :pong)
    end
  end)

send(echoer, {:ping, me})

receive do
  :pong -> IO.puts("收到 :pong")
after
  1_000 -> IO.puts("超时")
end
```

两个要点：

1. **要回复就把调用方 pid 一起发过去**。子进程不知道消息是谁发的，
   消息里带 `from`（call 模式）是约定俗成；
2. **`receive` 永远要考虑 `after`**。没有超时分支的 receive 会永久阻塞，
   在脚本里就是挂死；本章库代码统一用 1 秒超时。

库里的 `echo_loop/0` 是一个**长生命周期循环**：回完一条后递归调用自己继续等下一条，
收到不认识的消息也不崩（没有匹配的消息会留在邮箱里，而 `:stop` 才退出）：

```text
-- 1. spawn / send / receive：进程靠异步消息通信 --
  spawn 返回 pid？ => true（pid 每次都变，不打印）
  发出 {:ping, self()}，收到 :pong
  call_echo(echo, "hi") => {:ok, "hi"}
```

## 12.2 状态藏在递归 loop 的参数里

Elixir 没有可变变量，那进程怎么持有状态？——**递归参数**。
计数器进程把当前值 `n` 绑在 loop 参数上，每收到 `:inc` 就用 `n + 1` 递归：

```elixir
defp counter_loop(n) do
  receive do
    :inc -> counter_loop(n + 1)
    {:add, x} -> counter_loop(n + x)
    {:get, caller} ->
      send(caller, {:count, n})
      counter_loop(n)
    :stop -> {:stopped, n}
  end
end
```

这就是一切 BEAM 状态服务的原型（下一章的 Agent、再后面的 GenServer，
内部都是这个模式）。状态只存在于进程自己的递归栈里，**外部无法直接触碰**，
想读想改都只能发消息——天然串行化，没有锁也没有竞态。注意 `:get` 处理完
还要带着同一个 `n` 继续递归，否则进程读完就退出了。

```text
-- 2. 状态藏在递归 loop 的参数里 --
  初始 10，两次 inc，一次 +5 => 17
  另一个计数器从 100 起 => 100（状态互不共享）
```

测试还断言了两个计数器进程状态互不影响（一个 +1，另一个仍是 100）。

## 12.3 邮箱与选择性 receive

邮箱不是 FIFO 队列——**receive 是拿模式去整个邮箱里扫描**：第一条匹配的消息
被取出，其余的（包括更早到达的）继续留在邮箱。子进程故意先发 `:b` 再发 `:a`，
父进程先等 `:a`，`:b` 就被跳过、暂存：

```elixir
receive do: (:a -> :a)   # 即使 :b 先到，也只取 :a
receive do: (:b -> :b)   # 这时才取 :b
```

配套工具：

- `Process.info(self(), :messages)` 查看邮箱里排队的消息（调试用）；
- `receive ... after 0 -> []` 配合递归可以**非阻塞地排空邮箱**（`flush_mailbox/0`）；
- 并发收集时**到达顺序不保证**：8 个工作进程谁先完工取决于调度，
  要确定性输出必须收齐后自己 `Enum.sort/1`（这也是第 5 层单调度器重跑
  逐字节一致的前提——顺序只能来自数据，不能来自调度时序）。

```text
-- 3. 邮箱不按 FIFO 弹出，而是按模式扫描 --
  子进程先发 :b 再发 :a，父进程先等 :a => {:a, :b}
  自投两条后邮箱长度 => 2
  flush_mailbox 按到达顺序排空 => [:mail_one, :mail_two]
  8 个进程并发，收齐排序 => [1, 2, 3, 4, 5, 6, 7, 8]
```

## 12.4 link 与 trap_exit：进程的生死连接

`spawn_link/1` 在父子之间建一条**双向链接**，默认规则是「连坐」：

- 子进程**异常**退出（`exit(:boom)`、raise、未捕获错误）→ 父进程收到退出信号，
  没 trap 的话自己也以同样原因死掉；
- 子进程**正常**结束（函数返回、`exit(:normal)`）→ 不连坐。

`run.exs` 里的 `link_propagates?/0` 实证了这一点：一个不 trap_exit 的监控进程
`spawn_link` 了立即 `exit(:boom)` 的子进程，主进程用 monitor 盯着它，
收到的结论是 `:watcher_died_from_link`。

不想被连坐，就在接收方进程里开 **`Process.flag(:trap_exit, true)`**：
退出信号不再杀人，而是变成邮箱里的普通消息 `{:EXIT, pid, reason}`：

```elixir
Process.flag(:trap_exit, true)
pid = spawn_link(fun)
receive do
  {:EXIT, ^pid, reason} -> reason
end
```

异常退出时 reason 是 `{异常结构体, 栈迹}`，本章的 `normalize_reason/1` 把它压成
`{:error_exit, 类型模块, 消息}`——栈迹含文件路径与行号，不能进确定性输出。

```text
-- 4. link：默认连坐；trap_exit 后退出信号变成邮箱消息 --
  子进程 exit(:boom)   => {:exit, :boom}
  子进程 raise 异常     => {:error_exit, RuntimeError, "kaboom"}
  子进程正常返回       => {:exit, :normal}
  不 trap_exit 的监控者 => :watcher_died_from_link（被异常子进程连坐杀死）
```

一个容易忽略的细节：本章的 `linked_exit/1` 在结束时把 `:trap_exit` 恢复成
`false`——进程标志是**进程级长期状态**，不恢复会改变后续所有行为，测试里专门断言了这一点。

## 12.5 monitor：单向观察，必有一条 DOWN

`Process.monitor/1` 建立的是**单向监控**：

- 被监控进程死了，监控者收到**恰好一条** `{:DOWN, ref, :process, pid, reason}`；
- 监控本身**不影响**被监控者（监控者死了，被监控者照常运行，测试里有实证）；
- 可以监控已经死掉的进程，仍会收到一条 DOWN；
- `Process.demonitor(ref, [:flush])` 撤销监控，`:flush` 顺带丢弃已排队的 DOWN。

`ref` 是 monitor 返回的唯一引用，DOWN 里用它配对「这是哪次监控的通知」，
所以 receive 时要 `{:DOWN, ^ref, :process, ^pid, reason}` 用 pin 匹配。

```text
-- 5. monitor：单向监控，被监控者不受影响，死亡给一条 {:DOWN,...} --
  monitored_exit(:gone) => {:exit, :gone}
  demonitor(:flush) 后  => {true, false}（无 DOWN 进邮箱）
  实测收到 {:DOWN, ref, :process, pid, :shutdown}，ref/pid 与监控时一致
```

link vs monitor 一句话：**同生共死的协作关系用 link（监督树内部）；
只想旁观别人的死活用 monitor**。

## 12.6 命名进程

pid 是临时的，想长期引用一个进程（或者根本拿不到它的 pid）时，
用 **`Process.register(pid, :atom名字)`** 给它注册一个全局 atom 名：
此后 `send(:名字, msg)` 等价于发给那个 pid，`Process.whereis(:名字)` 反查。

```text
-- 6. 命名进程：注册后可以按 atom 名字发消息 --
  with_named_counter => {true, 2, true}
  给未注册名字发消息 => :argument_error
  send(注册名, msg) 投递成功，收到回复 :named_pong
```

三个事实：

- 名字全局唯一：重复注册抛 `ArgumentError`（测试有断言）；
- 给**没注册过的名字** `send/2` 也**立刻抛 ArgumentError**——不会静默丢消息，
  因为名字是发送目标的一部分，无法投递就是调用方错误（对比：给**死 pid**
  send 不报错，消息直接消失）；
- atom 不回收，名字只能来自代码里写死的 atom 或安全来源，
  **绝不能拿用户输入 `String.to_atom/1` 造注册名**（原子表耗尽会让 VM 不可恢复）。
  本章生成临时唯一名字用的是 `:erlang.unique_integer/1` 拼进固定前缀。

## 12.7 选型要点

```text
  私有状态、串行化访问   -> 一个进程 + 递归 loop，外部只能发消息
  需要结果              -> 消息里带回调用方 pid，receive 等回复（call 模式）
  我死它也要死          -> spawn_link（同生共死的监督关系）
  只想知道它死没死       -> Process.monitor（单向，收 {:DOWN,...}，可 demonitor）
  不想被连坐            -> Process.flag(:trap_exit, true)，退出信号变消息
  长期、多处引用的进程   -> Process.register 起 atom 名字；临时进程别注册
```

## 12.8 坑位清单

1. **`spawn(Mod, Fun, Args)` 要求函数被导出**。私有 loop 要么 `def` 公开，
   要么用闭包 `spawn(fn -> loop(state) end)`；用 MFA 传 `defp` 函数会在运行时
   报 UndefinedFunctionError，而且编译期毫无提示。
2. **receive 必须想清楚超时**。漏掉 `after` 的 receive 在等不到消息时永久挂起，
   在测试里是 60 秒超时，在生产里是悄悄堆积的活死进程。
3. **call 模式消息里必须带回程 pid**。`from = self()` 要在 spawn 外面取，
   子进程里的 `self()` 是子进程自己。
4. **状态 loop 处理完只读消息后要继续递归**，忘了就是「查一次进程就没了」。
5. **并发收集的消息到达顺序不是业务顺序**。多发送方场景必须收齐排序或用
   引用配对，不能依赖「谁先发谁先到」（单调度器与多调度器下顺序可能不同）。
6. **`:trap_exit` 是进程级开关且不会自己复位**。临时打开后要记得恢复，
   否则同进程后续的 link 语义全变。
7. **link 默认连坐、:normal 例外**。「我 spawn 的进程怎么自己也死了」
   九成是子进程异常退出而你没 trap_exit。
8. **DOWN/EXIT 里的 pid、ref 要用 `^` pin 配对**，裸变量会收到**任何**进程的
   通知；监控多个目标时尤其重要。
9. **不要用用户输入造 atom 注册名**（`String.to_atom/1` 不回收）；
   给未注册名 send 会抛 ArgumentError，给死 pid send 则静默。
10. **故意制造进程崩溃的测试/脚本要处理崩溃报告**：OTP 默认经 Logger 打出
    带时间戳/pid 的报告。本章在 run.exs 与 test_helper 里
    `Logger.configure(level: :none)` 关掉它，否则第 5 层逐字节比对必然失败。

---

下一章把这些裸原语工程化：[13 · Task 并发](13-task.md)——`async/await`、
`async_stream`、超时与失败传播，看看「spawn + monitor + receive」如何被
封装成安全好用的并发任务。
