# 第 15 章驱动脚本：cd examples/15_genservers && mix run --no-compile run.exs
:io.setopts(:standard_io, encoding: :utf8)

# 本章故意制造 call 超时退出；关闭崩溃报告，保证输出确定性。
Logger.configure(level: :none)

alias Ex15Genservers.KeyStore

IO.puts("==== 15 GenServer：API/回调两段式、call/cast/info、init 与空闲超时 ====")

# ------------------------------------------------------------
# 1. 两段式结构 + init：start_link(name:, idle_ms:, initial:)
# ------------------------------------------------------------
IO.puts("\n-- 1. 客户端 API 只发消息；init/1 把启动参数变成初始状态 --")

{:ok, s} = KeyStore.start_link(initial: %{seed: 0})
IO.puts("  initial 注入 seed=0，get => #{KeyStore.get(s, :seed)}")

# ------------------------------------------------------------
# 2. call：同步请求—回复
# ------------------------------------------------------------
IO.puts("\n-- 2. call：handle_call 必须 {:reply, 答案, 新状态} --")
IO.puts("  put(:a, 1) => #{inspect(KeyStore.put(s, :a, 1))}")
IO.puts("  get(:a)    => #{inspect(KeyStore.get(s, :a))}")
IO.puts("  snapshot   => #{inspect(KeyStore.snapshot(s))}（map 一律排序）")

# ------------------------------------------------------------
# 3. cast 与 info：异步写与普通 send 消息
# ------------------------------------------------------------
IO.puts("\n-- 3. cast 火并忘；普通 send/2 走 handle_info --")
KeyStore.put_cast(s, :b, 2)
IO.puts("  cast 写 :b=2 后 get => #{inspect(KeyStore.get(s, :b))}（同发送方有序）")
KeyStore.bump(s)
KeyStore.bump(s)
KeyStore.bump(s)
send(s, :totally_unknown)
IO.puts("  bump 三次 + 一条未知消息后 stats {bump, clears} => #{inspect(KeyStore.stats(s))}")
KeyStore.stop(s)

# ------------------------------------------------------------
# 4. 空闲超时：回调第四项武装计时器，:timeout 由 handle_info 接
# ------------------------------------------------------------
IO.puts("\n-- 4. 闲置 40ms 自动清空；每次活动重置计时器 --")
IO.puts("  idle_clear_demo => #{inspect(Ex15Genservers.idle_clear_demo())}")

# ------------------------------------------------------------
# 5. call 超时：杀调用方，不杀服务端
# ------------------------------------------------------------
IO.puts("\n-- 5. GenServer.call 超时只杀调用方进程，服务端照常存活 --")
IO.puts("  call_timeout_demo => #{inspect(Ex15Genservers.call_timeout_demo())}")

# ------------------------------------------------------------
# 6. 命名进程：监督树下按名字访问
# ------------------------------------------------------------
IO.puts("\n-- 6. name: 注册：调用方拿名字即可，不必传递 pid --")
name = :"ex15_run_store_#{:erlang.unique_integer([:positive])}"
{:ok, named_pid} = KeyStore.start_link(name: name, initial: %{who: "named"})
IO.puts("  whereis 命中？ => #{Process.whereis(name) == named_pid}")
IO.puts("  按名字 get(:who) => #{inspect(KeyStore.get(name, :who))}")
KeyStore.stop(name)
IO.puts("  stop 后 whereis => #{inspect(Process.whereis(name))}")

# ------------------------------------------------------------
# 7. 选型
# ------------------------------------------------------------
IO.puts("""
-- 7. GenServer 模式与边界 --
  客户端 API 做参数校验和发消息；状态逻辑只写在 handle_* 回调里
  call  需要回复/序列化写操作；cast 只管通知（丢了也无所谓的那种）
  普通 send/2 的消息一律在 handle_info 接，未知消息子句兜底防崩
  回调返回值第四项 -> 空闲超时；周期任务用 Process.send_after/3
  别在回调里做长 IO/重 CPU：服务进程一个，堵住所有客户端
  只需要 get/set 状态 -> 第 14 章 Agent；要自定义消息词汇表才用 GenServer
""")

IO.puts("==== 15 结束 ====")
