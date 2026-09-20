# 第 13 章驱动脚本：cd examples/13_tasks && mix run --no-compile run.exs
:io.setopts(:standard_io, encoding: :utf8)

# 本章故意制造任务崩溃/超时；关闭 OTP 崩溃报告，保证输出确定性。
Logger.configure(level: :none)

alias Ex13Tasks

IO.puts("==== 13 Task 并发：async/await、超时传播、async_stream、Task.Supervisor ====")

# ------------------------------------------------------------
# 1. fork/join：async 分叉、await 汇合、结果保序
# ------------------------------------------------------------
IO.puts("\n-- 1. async/await：分叉—汇合，await 按任务顺序保序 --")
IO.puts("  pmap(1..4, slow_square) => #{inspect(Ex13Tasks.pmap(1..4, &Ex13Tasks.slow_square/1))}")

tasks =
  Enum.map(1..3, fn n ->
    Task.async(fn ->
      Process.sleep(100 - n * 20)
      n
    end)
  end)

# 3 号最先完工，但 await 按任务列表顺序取，输出仍是 1,2,3
ordered = Enum.map(tasks, &Task.await(&1, 1_000))
IO.puts("  3 号最先完工，按 await 顺序汇合 => #{inspect(ordered)}（默认保序）")

# ------------------------------------------------------------
# 2. 失败传播：1.20 语义——任务崩 = 调用方进程 exit（不是 raise！）
# ------------------------------------------------------------
IO.puts("\n-- 2. 失败传播：任务异常死亡会连坐杀死 await 的调用方进程 --")
IO.puts("  safe_await 成功   => #{inspect(Ex13Tasks.safe_await(fn -> 7 * 6 end))}")

IO.puts(
  "  safe_await 异常   => #{inspect(Ex13Tasks.safe_await(fn -> raise RuntimeError, "boom" end))}（trap_exit + yield 收口）"
)

IO.puts("  safe_await 退出   => #{inspect(Ex13Tasks.safe_await(fn -> exit(:gone) end))}")

IO.puts(
  "  不防护地 await 崩溃任务，runner 死因 => #{inspect(Ex13Tasks.await_exit_reason(fn -> raise RuntimeError, "boom" end))}"
)

# ------------------------------------------------------------
# 3. 超时：yield 温和、await 致命
# ------------------------------------------------------------
IO.puts("\n-- 3. 超时：yield 返回 nil 可 shutdown；await 超时直接杀调用方 --")

IO.puts(
  "  yield 慢任务 20ms => #{inspect(Ex13Tasks.try_await(fn -> Process.sleep(60_000) end, 20))}"
)

IO.puts("  yield 快任务      => #{inspect(Ex13Tasks.try_await(fn -> :ready end, 1_000))}")
IO.puts("  await 超时的 runner 死因 => #{inspect(Ex13Tasks.await_timeout_kills_caller?())}")

# ------------------------------------------------------------
# 4. async_stream：流内建并发，默认保序
# ------------------------------------------------------------
IO.puts("\n-- 4. async_stream：每个元素一个任务，默认按输入顺序产出 --")
IO.puts("  stream_squares(1..4) => #{inspect(Ex13Tasks.stream_squares(1..4))}")

# ------------------------------------------------------------
# 5. 流式任务的超时与崩溃
# ------------------------------------------------------------
IO.puts("\n-- 5. 流的边界：坏任务默认杀死整个 stream；超时可选只杀任务 --")
IO.puts("  kill_task 逐元素隔离 => #{inspect(Ex13Tasks.stream_timeouts([1, 2]))}")
IO.puts("  任务 raise 的 stream 死因 => #{inspect(Ex13Tasks.stream_failure_reason())}")

# ------------------------------------------------------------
# 6. Task.Supervisor：任务挂在监督者下面
# ------------------------------------------------------------
IO.puts("\n-- 6. Task.Supervisor：受监督任务，崩溃不拖垮监督者 --")
IO.puts("  supervised_value => #{inspect(Ex13Tasks.supervised_value())}")
IO.puts("  子任务崩溃后 {监督者存活?, 活跃子任务数} => #{inspect(Ex13Tasks.supervisor_demo())}")
IO.puts("  （Task 默认 :temporary——崩了不重启，只摘除；要重启需自己包 GenServer）")

# ------------------------------------------------------------
# 7. 选型
# ------------------------------------------------------------
IO.puts("""
-- 7. Task 选型 --
  每个元素都要做、最后收结果   -> Task.async_stream（背压+保序+并发上限）
  分叉若干异构任务再逐个汇合   -> Task.async + Task.await（保序）
  超时了还想自己决定怎么办     -> Task.yield（nil）+ Task.shutdown，别用 await
  fire-and-forget 的副作用     -> Task.start（没人 await，崩了没人知道）
  任务需要被监督/动态启停      -> Task.Supervisor.start_child/async
  长生命周期、多条消息的服务    -> Task 不合适，用第 15 章的 GenServer
""")

IO.puts("==== 13 结束 ====")
