# 第 12 章驱动脚本：cd examples/12_processes && mix run --no-compile run.exs
# 纪律：全程不打印 pid/reference/时间——只打印性质标签与确定性数据。
:io.setopts(:standard_io, encoding: :utf8)

# 本章会故意让子进程异常退出做 link/monitor 演示；OTP 默认会把进程崩溃
# 报告经 Logger 打出（带时间戳和 pid，且走 group leader 污染 stdout）。
# 第 12 章不教 Logger，直接在演示前把主日志级别关到 :none。
Logger.configure(level: :none)

alias Ex12Processes

IO.puts("==== 12 进程与消息：spawn / send / receive / link / monitor / 命名 ====")

# ------------------------------------------------------------
# 1. spawn / send / receive：裸三原语
# ------------------------------------------------------------
IO.puts("\n-- 1. spawn / send / receive：进程靠异步消息通信 --")

me = self()

echoer =
  spawn(fn ->
    receive do
      {:ping, from} -> send(from, :pong)
    end
  end)

IO.puts("  spawn 返回 pid？ => #{is_pid(echoer)}（pid 每次都变，不打印）")
send(echoer, {:ping, me})

receive do
  :pong -> IO.puts("  发出 {:ping, self()}，收到 :pong")
after
  1_000 -> IO.puts("  超时未收到回复")
end

# 库里封装好的 echo 循环：不认识的消息不会弄崩它
echo = Ex12Processes.start_echo()
send(echo, :unknown_message)
IO.puts("  call_echo(echo, \"hi\") => #{inspect(Ex12Processes.call_echo(echo, "hi"))}")
Ex12Processes.stop(echo)

# ------------------------------------------------------------
# 2. 状态 loop：递归参数就是进程的私有状态
# ------------------------------------------------------------
IO.puts("\n-- 2. 状态藏在递归 loop 的参数里 --")

c = Ex12Processes.start_counter(10)
Ex12Processes.increment(c)
Ex12Processes.increment(c)
Ex12Processes.add(c, 5)
IO.puts("  初始 10，两次 inc，一次 +5 => #{Ex12Processes.get_count(c)}")

c2 = Ex12Processes.start_counter(100)
IO.puts("  另一个计数器从 100 起 => #{Ex12Processes.get_count(c2)}（状态互不共享）")
Ex12Processes.stop_counter(c)
Ex12Processes.stop_counter(c2)

# ------------------------------------------------------------
# 3. 邮箱：选择性 receive 与到达顺序
# ------------------------------------------------------------
IO.puts("\n-- 3. 邮箱不按 FIFO 弹出，而是按模式扫描 --")
IO.puts("  子进程先发 :b 再发 :a，父进程先等 :a => #{inspect(Ex12Processes.selective_receive())}")

send(me, :mail_one)
send(me, :mail_two)
{:messages, waiting} = Process.info(me, :messages)
IO.puts("  自投两条后邮箱长度 => #{length(waiting)}")
IO.puts("  flush_mailbox 按到达顺序排空 => #{inspect(Ex12Processes.flush_mailbox())}")

# 8 个进程并发完工，到达顺序不保证，收齐后排序才是确定输出
IO.puts("  8 个进程并发，收齐排序 => #{inspect(Ex12Processes.parallel_work(8))}")

# ------------------------------------------------------------
# 4. link 与 trap_exit：生要同衾，死要连坐
# ------------------------------------------------------------
IO.puts("\n-- 4. link：默认连坐；trap_exit 后退出信号变成邮箱消息 --")
IO.puts("  子进程 exit(:boom)   => #{inspect(Ex12Processes.linked_exit(fn -> exit(:boom) end))}")

IO.puts(
  "  子进程 raise 异常     => #{inspect(Ex12Processes.linked_exit(fn -> raise RuntimeError, "kaboom" end))}"
)

IO.puts("  子进程正常返回       => #{inspect(Ex12Processes.linked_exit(fn -> :done end))}")

IO.puts("  不 trap_exit 的监控者 => #{inspect(Ex12Processes.link_propagates?())}（被异常子进程连坐杀死）")

# ------------------------------------------------------------
# 5. monitor：单向观察，必有一条 DOWN
# ------------------------------------------------------------
IO.puts("\n-- 5. monitor：单向监控，被监控者不受影响，死亡给一条 {:DOWN,...} --")

IO.puts(
  "  monitored_exit(:gone) => #{inspect(Ex12Processes.monitored_exit(fn -> exit(:gone) end))}"
)

IO.puts("  demonitor(:flush) 后  => #{inspect(Ex12Processes.demonitor_demo())}（无 DOWN 进邮箱）")

# 展示 DOWN 元组的形状（ref/pid 位置只标注，不打印具体值）
gone =
  spawn(fn ->
    receive do
      :die -> exit(:shutdown)
    end
  end)

ref = Process.monitor(gone)
send(gone, :die)

receive do
  {:DOWN, down_ref, :process, down_pid, :shutdown}
  when down_ref == ref and down_pid == gone ->
    IO.puts("  实测收到 {:DOWN, ref, :process, pid, :shutdown}，ref/pid 与监控时一致")
after
  1_000 -> IO.puts("  未等到 DOWN")
end

# ------------------------------------------------------------
# 6. 命名进程：用 atom 名字代替 pid
# ------------------------------------------------------------
IO.puts("\n-- 6. 命名进程：注册后可以按 atom 名字发消息 --")
IO.puts("  with_named_counter => #{inspect(Ex12Processes.with_named_counter())}")
IO.puts("  给未注册名字发消息 => #{inspect(Ex12Processes.send_to_missing_name())}")

# 自己注册一个名字，演示 send/2 两边都能用名字
fn_name = :"ex12_run_named_echo_#{:erlang.unique_integer([:positive])}"

me2 =
  spawn(fn ->
    receive do
      {:hello, from} -> send(from, :named_pong)
    end
  end)

Process.register(me2, fn_name)
send(fn_name, {:hello, self()})

receive do
  :named_pong -> IO.puts("  send(注册名, msg) 投递成功，收到回复 :named_pong")
after
  1_000 -> IO.puts("  超时")
end

# ------------------------------------------------------------
# 7. 选型要点
# ------------------------------------------------------------
IO.puts("""
-- 7. 进程与消息选型 --
  私有状态、串行化访问   -> 一个进程 + 递归 loop，外部只能发消息
  需要结果              -> 消息里带回调用方 pid，receive 等回复（call 模式）
  我死它也要死          -> spawn_link（同生共死的监督关系）
  只想知道它死没死       -> Process.monitor（单向，收 {:DOWN,...}，可 demonitor）
  不想被连坐            -> Process.flag(:trap_exit, true)，退出信号变消息
  长期、多处引用的进程   -> Process.register 起 atom 名字；临时进程别注册
""")

IO.puts("==== 12 结束 ====")
