# 第 07 章驱动脚本：cd examples/07_enum && mix run run.exs

# BEAM 的 :standard_io 编码取自系统 locale；LANG/LC_ALL 未设时退回 latin1，
# 中文会被 IO.puts 打成 \x{7ED3}\x{675F} 这样的字面转义（08 章展开，
# CHEATSheet 有专条）。显式设成 utf8，脚本就与 locale 无关了。
:io.setopts(:standard_io, encoding: :utf8)

# 本章的确定性纪律：
#   · map 的遍历顺序不保证 → 一切 map 结果先 Enum.sort/1 再打印（见第 5、6 节）；
#   · shuffle / random 结果每次不同 → 只打印「性质断言」的布尔结论（见第 4 节）；
#   · 不用墙钟时间做结论 → 用「函数求值次数」这种可复现的计数（见第 3、12 节）。

IO.puts("==== 07 Enum 与管道 ====")

IO.puts("\n-- 1. 哪些类型是 Enumerable --")

probes = [
  {"[1, 2]", [1, 2]},
  {"%{a: 1}", %{a: 1}},
  {"1..3", 1..3},
  {"MapSet.new([1])", MapSet.new([1])},
  {"~c\"ab\"（charlist 就是列表）", ~c"ab"},
  {"2-arity 函数（无限流）", fn _, acc -> {:cont, acc} end},
  {"{1, 2}（元组）", {1, 2}},
  {"\"abc\"（二进制）", "abc"},
  {"42（整数）", 42}
]

for {label, term} <- probes do
  impl = Ex07Enum.enumerable_impl(term)
  IO.puts("  #{String.pad_trailing(label, 30)} => #{inspect(impl)}")
end

IO.puts("\n-- 2. reduce 是万物之源：手写 map / filter / take --")

IO.puts(
  "my_map([1,2,3], &(&1 * 2))            => #{inspect(Ex07Enum.my_map([1, 2, 3], &(&1 * 2)))}"
)

IO.puts(
  "my_filter([1,2,3,4], 偶数?)           => #{inspect(Ex07Enum.my_filter([1, 2, 3, 4], &(rem(&1, 2) == 0)))}"
)

IO.puts(
  "my_take([1,2,3,4,5], 2)               => #{inspect(Ex07Enum.my_take([1, 2, 3, 4, 5], 2))}"
)

IO.puts(
  "my_take(无限流 7,7,7…, 3)             => #{inspect(Ex07Enum.my_take(Stream.repeatedly(fn -> 7 end), 3))}"
)

{n_funs, all_equal} = Ex07Enum.equivalence_check()
IO.puts("#{n_funs} 个手写函数 × 5 组输入 与 Enum 版等价 => #{inspect(all_equal)}")

IO.puts("\n-- 3. Enum 立即求值 vs Stream 惰性（数一数 map 函数被求值几次）--")

{stream_res, stream_calls, enum_res, enum_calls} = Ex07Enum.lazy_vs_eager(100)

IO.puts(
  "1..100 |> Stream.map(计数翻倍) |> Enum.take(3) => #{inspect(stream_res)}，求值 #{stream_calls} 次"
)

IO.puts("1..100 |> Enum.map(计数翻倍)   |> Enum.take(3) => #{inspect(enum_res)}，求值 #{enum_calls} 次")
IO.puts("结论：Stream 只在被消费时逐元素拉取；Enum 先全量算完再说")

IO.puts("\n-- 4. 变换类 --")
IO.puts("map(1..4, &(&1 * &1))                 => #{inspect(Enum.map(1..4, &(&1 * &1)))}")

IO.puts(
  "flat_map(1..3, &[&1, &1 * 10])        => #{inspect(Enum.flat_map(1..3, &[&1, &1 * 10]))}"
)

IO.puts(
  "filter(1..10, rem 3 == 0)             => #{inspect(Enum.filter(1..10, &(rem(&1, 3) == 0)))}"
)

IO.puts(
  "reject(1..10, rem 3 == 0)             => #{inspect(Enum.reject(1..10, &(rem(&1, 3) == 0)))}"
)

IO.puts("uniq([1,1,2,1,3])                     => #{inspect(Enum.uniq([1, 1, 2, 1, 3]))}")
IO.puts("dedup([1,1,2,1,3])                    => #{inspect(Enum.dedup([1, 1, 2, 1, 3]))}")
IO.puts("dedup 只压缩**相邻**重复，uniq 全局去重")
IO.puts("reverse([1,2,3])                      => #{inspect(Enum.reverse([1, 2, 3]))}")
IO.puts("sort([3,1,2])                         => #{inspect(Enum.sort([3, 1, 2]))}")

words = ~w(elixir go cplusplus)
IO.puts("sort_by(按长度)                       => #{inspect(Enum.sort_by(words, &String.length/1))}")
IO.puts("shuffle 结果不确定，只断言性质：排序后等于原列表 => #{inspect(Ex07Enum.shuffle_is_permutation?(1..20))}")
IO.puts("random 同理：结果必为成员             => #{inspect(Ex07Enum.random_is_member?(~w(a b c)))}")

IO.puts("\n-- 5. 聚合类 --")
IO.puts("sum(1..10)                            => #{inspect(Enum.sum(1..10))}")
IO.puts("product(1..5)                         => #{inspect(Enum.product(1..5))}")

IO.puts(
  "count(1..10, rem 2 == 0)              => #{inspect(Enum.count(1..10, &(rem(&1, 2) == 0)))}"
)

IO.puts(
  "min/max([3,1,2])                      => #{inspect(Enum.min([3, 1, 2]))} / #{inspect(Enum.max([3, 1, 2]))}"
)

IO.puts(
  "min_by/max_by(按字符串长度)           => #{inspect(Enum.min_by(words, &String.length/1))} / #{inspect(Enum.max_by(words, &String.length/1))}"
)

freq = Ex07Enum.frequencies_sorted(~w(apple fig apple banana apple fig))
IO.puts("frequencies（map 结果已排序）         => #{inspect(freq)}")

halted =
  Enum.reduce_while(1..100, 0, fn x, acc ->
    if acc + x > 50, do: {:halt, acc}, else: {:cont, acc + x}
  end)

IO.puts("reduce_while(累加到超过 50 就停)      => #{inspect(halted)}")

IO.puts("\n-- 6. 分组与切片类 --")
IO.puts("chunk_every(1..5, 2)                  => #{inspect(Enum.chunk_every(1..5, 2))}")
IO.puts("chunk_every(1..5, 2, 2, [nil]) 补余   => #{inspect(Enum.chunk_every(1..5, 2, 2, [nil]))}")

IO.puts(
  "chunk_by(按字符串长度分段)            => #{inspect(Enum.chunk_by(~w(a bb c dd), &String.length/1))}"
)

ascending_runs =
  Enum.chunk_while(
    [1, 2, 3, 1, 2],
    [],
    fn
      x, [] -> {:cont, [x]}
      x, [h | _] = acc when x >= h -> {:cont, [x | acc]}
      x, acc -> {:cont, Enum.reverse(acc), [x]}
    end,
    fn
      [] -> {:cont, []}
      acc -> {:cont, Enum.reverse(acc), []}
    end
  )

IO.puts("chunk_while(切成递增段)               => #{inspect(ascending_runs)}")

grouped = Ex07Enum.group_by_rem_sorted(1..10, 3)
IO.puts("group_by(rem 3)（键已排序）           => #{inspect(grouped)}")
IO.puts("zip([1,2,3], ~w(a b c))               => #{inspect(Enum.zip([1, 2, 3], ~w(a b c)))}")
IO.puts("with_index(~w(a b))                   => #{inspect(Enum.with_index(~w(a b)))}")

into_map = Enum.into(~w(aa b), %{}, fn s -> {s, String.length(s)} end)
IO.puts("into(%{}, 收集成 map)（已排序）       => #{inspect(Enum.sort(into_map))}")
IO.puts("join(~w(Elixir 管道), \" |> \")         => #{inspect(Enum.join(~w(Elixir 管道), " |> "))}")
IO.puts("concat([1,2], [3])                    => #{inspect(Enum.concat([1, 2], [3]))}")
IO.puts("intersperse([1,2,3], 0)               => #{inspect(Enum.intersperse([1, 2, 3], 0))}")
IO.puts("scan([1,2,3,4], &+/2) 前缀和          => #{inspect(Enum.scan([1, 2, 3, 4], &(&1 + &2)))}")
IO.puts("split(1..5, 2)                        => #{inspect(Enum.split(1..5, 2))}")

IO.puts(
  "take(1..10, 3) / drop(1..10, 3)       => #{inspect(Enum.take(1..10, 3))} / #{inspect(Enum.drop(1..10, 3))}"
)

IO.puts("take_while(1..10, &1 < 5)             => #{inspect(Enum.take_while(1..10, &(&1 < 5)))}")
IO.puts("drop_while(1..10, &1 < 5)             => #{inspect(Enum.drop_while(1..10, &(&1 < 5)))}")

IO.puts(
  "slide([1,2,3,4,5], 0..1, 3)           => #{inspect(Enum.slide([1, 2, 3, 4, 5], 0..1, 3))}"
)

IO.puts("\n-- 7. 判定类 --")
IO.puts("any?(1..10, &1 > 9)                   => #{inspect(Enum.any?(1..10, &(&1 > 9)))}")
IO.puts("all?(1..10, &1 > 9)                   => #{inspect(Enum.all?(1..10, &(&1 > 9)))}")
IO.puts("find(1..10, &1 > 4)                   => #{inspect(Enum.find(1..10, &(&1 > 4)))}")

IO.puts(
  "member?(1..10, 5) / member?(…, 11)    => #{inspect(Enum.member?(1..10, 5))} / #{inspect(Enum.member?(1..10, 11))}"
)

IO.puts(
  "empty?(1..0//-1) / empty?([1])            => #{inspect(Enum.empty?(1..0//-1))} / #{inspect(Enum.empty?([1]))}"
)

IO.puts("\n-- 8. 副作用类 --")
IO.puts("each 的返回值                         => #{inspect(Enum.each([1, 2], fn _ -> :ok end))}")

tapped =
  3
  |> tap(fn x -> IO.puts("  tap 看到中间值 #{inspect(x)}，但放行原值") end)
  |> then(&(&1 * 100))

IO.puts("tap + then 之后的值                   => #{inspect(tapped)}")

IO.puts("\n-- 9. 管道的本质：纯语法糖 --")
{before_ast, after_ast} = Ex07Enum.pipe_proof()
IO.puts("展开前 AST                            => #{before_ast}")
IO.puts("宏展开后 AST                          => #{after_ast}")

real_pipeline =
  quote do
    file |> File.read!() |> String.split("\n") |> Enum.map(&String.trim/1)
  end
  |> Macro.prewalk(&Macro.expand(&1, __ENV__))
  |> Macro.to_string()

IO.puts("真实管道展开                          => #{real_pipeline}")

IO.puts(
  "管道写法 == 嵌套写法                  => #{inspect(Ex07Enum.pipe_style("  Hi  ") == Ex07Enum.nested_style("  Hi  "))}"
)

IO.puts("\n-- 10. for 推导式 --")
IO.puts("笛卡尔积                              => #{inspect(Ex07Enum.cartesian())}")
IO.puts("filter：1..10 里 3 的倍数             => #{inspect(for(x <- 1..10, rem(x, 3) == 0, do: x))}")
IO.puts("uniq: true                            => #{inspect(Ex07Enum.comprehension_uniq())}")
IO.puts("into: %{}                             => #{inspect(Ex07Enum.comprehension_into_map())}")
IO.puts("reduce: 0                             => #{inspect(Ex07Enum.comprehension_reduce())}")
IO.puts("二进制推导式（按 4-bit 切 0xDEADBEEF）    => #{inspect(Ex07Enum.binary_comprehension())}")

IO.puts("\n-- 11. 排序细节 --")

for {label, sorted} <- Ex07Enum.sort_stability() do
  IO.puts("  #{Atom.to_string(label) |> String.pad_trailing(18)} => #{inspect(sorted)}")
end

IO.puts("  非严格（<=/>=）稳定，严格（</>）会调换相等元素")
IO.puts("sort(日期, Date)  升序                => #{inspect(Ex07Enum.sort_dates())}")
IO.puts("sort(日期, {:desc, Date})             => #{inspect(Ex07Enum.sort_dates_desc())}")

IO.puts(
  "默认排序 = term 全序                  => #{inspect(Enum.sort([:b, "a", 1, [1], {1}, %{z: 1}]))}"
)

IO.puts("\n-- 12. 性能：多次遍历 vs 单次 reduce / 惰性 vs 全量 --")

IO.puts(
  "multi_pass(1..1000) == single_pass(1..1000) => #{inspect(Ex07Enum.multi_pass(1..1000) == Ex07Enum.single_pass(1..1000))}"
)

{_, s_calls, _, e_calls} = Ex07Enum.lazy_vs_eager(10_000)
IO.puts("take 3：Stream 求值 #{s_calls} 次，Enum 求值 #{e_calls} 次（拿得少、源很大时用 Stream）")

IO.puts("\n==== 07 结束 ====")
