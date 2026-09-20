# 第 18 章驱动脚本：cd examples/18_streams && mix run --no-compile run.exs
:io.setopts(:standard_io, encoding: :utf8)

alias Ex18Streams

IO.puts("==== 18 Stream 惰性流：配方、无限源、resource 生命周期、分块、恒定内存 ====")

# ------------------------------------------------------------
# 1. 惰性：组合流不执行；终点操作找到答案即停
# ------------------------------------------------------------
IO.puts("\n-- 1. Stream 操作只是配方；Enum.find 在无限流上找到即停 --")
IO.puts("  构造不求值 => #{inspect(Ex18Streams.build_untouched())}")
IO.puts("  第一个平方>100 => #{Ex18Streams.first_square_over(100)}（源只拉到 11）")

# ------------------------------------------------------------
# 2. map/filter/take 融合
# ------------------------------------------------------------
IO.puts("\n-- 2. 惰性管道：翻倍→筛 3 的倍数→取 3 个，不产生中间列表 --")
IO.puts("  结果 => #{inspect(Ex18Streams.take_doubles())}")

# ------------------------------------------------------------
# 3. Stream.iterate/2
# ------------------------------------------------------------
IO.puts("\n-- 3. iterate(初值, 下一步)：无限等比，take 截断 --")
IO.puts("  2 的幂前 6 个 => #{inspect(Ex18Streams.powers_of_two(6))}")

# ------------------------------------------------------------
# 4. Stream.cycle/1
# ------------------------------------------------------------
IO.puts("\n-- 4. cycle：有限列表无限轮转，跨边界继续 --")
IO.puts("  [1,2,3] 取 7 => #{inspect(Ex18Streams.cycle_take([1, 2, 3], 7))}")

# ------------------------------------------------------------
# 5. Stream.unfold/2
# ------------------------------------------------------------
IO.puts("\n-- 5. unfold：{吐出值, 下一状态}，相邻两项生成斐波那契 --")
IO.puts("  fib(10) => #{inspect(Ex18Streams.fib(10))}")

# ------------------------------------------------------------
# 6. Stream.resource/3 与 Stream.run/0
# ------------------------------------------------------------
IO.puts("\n-- 6. resource 三段式（打开/批量产出/清理）；run 只为跑完副作用 --")
IO.puts("  {值, 生命周期} => #{inspect(Ex18Streams.resource_demo())}")
IO.puts("  each+run 的副作用顺序 => #{inspect(Ex18Streams.run_each())}")

# ------------------------------------------------------------
# 7. chunk 家族与无限流
# ------------------------------------------------------------
IO.puts("\n-- 7. chunk_every 定长 / chunk_by 边界 / chunk_while 累加；无限流取前几个 --")
IO.puts("  pairs(5) => #{inspect(Ex18Streams.pairs(5))}")
IO.puts("  奇偶游程 => #{inspect(Ex18Streams.parity_runs([1, 3, 2, 4, 5]))}")
IO.puts("  和达到 5 成组 => #{inspect(Ex18Streams.running_groups(1..6, 5))}")
IO.puts("  无限奇数前 5 个 => #{inspect(Ex18Streams.odds(5))}")

IO.puts("""
-- Stream 要点 --
  Stream 是「拉取配方」：组合不执行，Enum.to_list/take/find/run 才求值
  无限源（iterate/cycle/unfold/resource）必须配 take/find/take_while 等短路终点
  map/filter 融合：源头按需拉取，不构建中间列表，内存与产出无关
  unfold 吐 {值, 下一状态}；resource 管 {打开, 批量产出, 清理}
  resource/transform 的 after 回调只做释放：会被调用但返回值被丢弃
  chunk_while 是跨元素的有状态缓冲：解析流式记录、按条件成组用它
""")

IO.puts("==== 18 结束 ====")
