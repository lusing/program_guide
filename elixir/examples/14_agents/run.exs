# 第 14 章驱动脚本：cd examples/14_agents && mix run --no-compile run.exs
:io.setopts(:standard_io, encoding: :utf8)

# 本章故意让 Agent 崩溃以演示监督重启；关闭崩溃报告，保证输出确定性。
Logger.configure(level: :none)

alias Ex14Agents

IO.puts("==== 14 Agent 状态：start_link / get / update / cast / get_and_update ====")

# ------------------------------------------------------------
# 1. start_link / update / get：状态住在 Agent 进程里
# ------------------------------------------------------------
IO.puts("\n-- 1. update 同步写、get 同步读；cast 异步写但同发送方消息有序 --")

{:ok, a} = Ex14Agents.start_link(5)
IO.puts("  初始值        => #{Ex14Agents.current(a)}")
Ex14Agents.increment(a)
Ex14Agents.increment(a, 10)
IO.puts("  +1、+10 后    => #{Ex14Agents.current(a)}")
Ex14Agents.cast_add(a, 100)
IO.puts("  cast +100 后  => #{Ex14Agents.current(a)}（get 一定看得到前一条 cast）")
Ex14Agents.stop(a)
IO.puts("  stop 后进程消失（监督树下不要手动 stop）")

# ------------------------------------------------------------
# 2. get_and_update：一次往返的原子读改写
# ------------------------------------------------------------
IO.puts("\n-- 2. get_and_update：读-改-写在 Agent 进程一次执行，天然原子 --")

{:ok, b} = Ex14Agents.start_link(10)
IO.puts("  add_and_get(8) => #{Ex14Agents.add_and_get(b, 8)}（返回值与新状态一致）")
IO.puts("  当前值        => #{Ex14Agents.current(b)}")
Ex14Agents.stop(b)

# ------------------------------------------------------------
# 3. 结构化状态：map 注册表（输出排序）与纯函数对照组
# ------------------------------------------------------------
IO.puts("\n-- 3. map 状态跨请求累积；map 输出一律排序 --")

{:ok, r} = Ex14Agents.start_registry()
Ex14Agents.reg_put(r, :z, 1)
Ex14Agents.reg_put(r, :a, 2)
Ex14Agents.reg_put(r, :m, 3)
IO.puts("  乱序写入 z/a/m，排序读出 => #{inspect(Ex14Agents.reg_sorted(r))}")
IO.puts("  reg_get(:x, :缺省)       => #{inspect(Ex14Agents.reg_get(r, :x, :缺省))}")
Ex14Agents.stop(r)

# 同一类累积，不引入 Agent：纯函数 + 管道，状态只随数据流动
counts = Ex14Agents.word_count(%{}, ~w(a b a c a b))
IO.puts("  纯函数词频 word_count   => #{inspect(counts |> Map.to_list() |> Enum.sort())}")

# ------------------------------------------------------------
# 4. 崩溃：回调 raise 杀死 Agent；监督重启 = 状态归零；死后 get 给 noproc
# ------------------------------------------------------------
IO.puts("\n-- 4. 回调在 Agent 进程执行，回调崩 = Agent 崩 --")
IO.puts("  监督重启 {崩前值, 重启后值} => #{inspect(Ex14Agents.crash_resets_state?())}")
IO.puts("  Agent 已死后 get 的死因    => #{inspect(Ex14Agents.dead_agent_reason())}")

# ------------------------------------------------------------
# 5. 选型：什么时候才该用 Agent
# ------------------------------------------------------------
IO.puts("""
-- 5. Agent 选型边界 --
  单一进程内的状态传递      -> 变量/递归参数/Map.update，不要上 Agent
  多进程共享、需要串行化    -> Agent（消息队列把并发读写排成串行）
  需要原子读改写           -> get_and_update，别用 get 后再 update（中间有窗口）
  回调里做重活/睡眠/IO     -> 不要：所有其他客户端都被这一个回调堵住
  需要崩溃不丢状态         -> 监督重启会归零，init 回调里自己加载/持久化
  消息不止 :get/:set       -> Agent 到头了，用第 15 章的 GenServer
""")

IO.puts("==== 14 结束 ====")
