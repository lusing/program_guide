# 第 05 章驱动脚本：cd examples/05_functions && mix run run.exs

# 与 locale 解耦：强制 stdio 按 UTF-8 编码（理由见 02 章坑位 1 / 08 章）。
:io.setopts(:standard_io, encoding: :utf8)

# 纪律：只打印确定性结论；pid/ref/时间戳一律不打印（run-all.sh 第 5 层逐字节比对）。

alias Ex05Functions

IO.puts("==== 05 函数与递归 ====")

IO.puts("\n-- 1. 多子句分派 + 守卫：同一函数名，按形状和条件选子句 --")

for x <- [5, 0, -3, 3.14, -3.14, "x", :atom] do
  IO.puts("sign(#{inspect(x)}) => #{inspect(Ex05Functions.sign(x))}")
end

IO.puts("")

for code <- [204, 301, 404, 503, 600] do
  IO.puts("http_label(#{code}) => #{inspect(Ex05Functions.http_label(code))}")
end

IO.puts("")
IO.puts("守卫是安全的：hd([]) 放在守卫里出错只让子句落选，不抛异常")
IO.puts("first_is_ok?([:ok, 1]) => #{inspect(Ex05Functions.first_is_ok?([:ok, 1]))}")
IO.puts("first_is_ok?([])       => #{inspect(Ex05Functions.first_is_ok?([]))}")

IO.puts("\n-- 2. 默认参数写在「函数头」里：同时得到 join/2 与 join/3 --")
IO.puts("join(\"a\", \"b\")        => #{inspect(Ex05Functions.join("a", "b"))}")
IO.puts("join(\"a\", \"b\", \"-\")   => #{inspect(Ex05Functions.join("a", "b", "-"))}")
IO.puts("join(1, 2, \"-\")        => #{inspect(Ex05Functions.join(1, 2, "-"))}")

IO.puts("\n-- 3. 递归：没有循环，遍历靠自己调自己 --")
IO.puts("fact(10)      = #{Ex05Functions.fact(10)}（体递归：n * fact(n-1)）")
IO.puts("fact_tail(10) = #{Ex05Functions.fact_tail(10)}（尾递归+累加器）")
IO.puts("sum(1..100)      = #{Ex05Functions.sum(Enum.to_list(1..100))}")
IO.puts("sum_tail(1..100) = #{Ex05Functions.sum_tail(Enum.to_list(1..100))}")
IO.puts("my_length([:a,:b,:c]) = #{Ex05Functions.my_length([:a, :b, :c])}")
IO.puts("my_reverse([1,2,3])   = #{inspect(Ex05Functions.my_reverse([1, 2, 3]))}")

IO.puts("\n-- 4. 函数是值：匿名函数要用 .() 调用；& 是捕获操作符 --")
square = fn x -> x * x end
IO.puts("square = fn x -> x*x end；square.(8) = #{square.(8)}（注意那个点）")

add10 = Ex05Functions.adder(10)
IO.puts("adder(10) 返回闭包；.(5) = #{add10.(5)}")
IO.puts("twice(fn x -> x+1 end, 40) = #{Ex05Functions.twice(fn x -> x + 1 end, 40)}")

nums = [1, 2, 3, 4, 5, 6]

IO.puts("my_map(1..6, &(&1*&1))   = #{inspect(Ex05Functions.my_map(nums, &(&1 * &1)))}")

IO.puts("my_filter(1..6, 偶数?)  = #{inspect(Ex05Functions.my_filter(nums, &(rem(&1, 2) == 0)))}")

IO.puts("my_reduce(1..6, 0, &+/2) = #{Ex05Functions.my_reduce(nums, 0, &+/2)}")
IO.puts("my_take(1..6, 3)         = #{inspect(Ex05Functions.my_take(nums, 3))}")
IO.puts("my_take(1..6, -1)        = #{inspect(Ex05Functions.my_take(nums, -1))}")
IO.puts("&Ex05Functions.fact/1 捕获命名函数：.(6) = #{(&Ex05Functions.fact/1).(6)}")

IO.puts("\n-- 5. 嵌套递归：结构有多深，递归就有多深 --")
tree = [1, [2, [3]], 4, [5, [6]]]
IO.puts("deep_sum(#{inspect(tree)}) = #{Ex05Functions.deep_sum(tree)}")

IO.puts("\n-- 6. TCO：尾调用复用栈帧，深度只受内存限制 --")
IO.puts("count_down(2_000_000) => #{inspect(Ex05Functions.count_down(2_000_000))}（尾递归，栈不增长）")

big = Enum.to_list(1..1_000_000)
IO.puts("百万列表：体递归 sum = #{Ex05Functions.sum(big)}")
IO.puts("百万列表：尾递归 sum_tail = #{Ex05Functions.sum_tail(big)}（答案相同，栈帧恒定）")

IO.puts(
  "相互尾递归 even?(1_000_000) => #{inspect(Ex05Functions.even?(1_000_000))}（even? 调 odd? 也算尾调用）"
)

IO.puts("\n==== 05 结束 ====")
