# 第 04 章驱动脚本：cd examples/04_pattern_matching && mix run run.exs

# 与 locale 解耦：强制 stdio 按 UTF-8 编码（理由见 02 章坑位 1 / 08 章）。
:io.setopts(:standard_io, encoding: :utf8)

# 纪律：只打印确定性结论；pid/ref/时间戳一律不打印（run-all.sh 第 5 层逐字节比对）。

alias Ex04PatternMatching

IO.puts("==== 04 模式匹配 ====")

# 1.20 的类型检查器会把「静态可判定必然失败」的匹配直接判为编译告警（且未绑定的变量
# 还会报 unused），所以要演示 MatchError，得让代码在**运行时**才被编译——Code.eval_string
# 吃一个字符串，外层编译器不分析其内部。测试里则改走参数为 term() 的 force_key!/1。
expect_match_error = fn code ->
  try do
    Code.eval_string(code)
    :no_raise
  rescue
    MatchError -> {:raised, MatchError}
  end
end

eval_value = fn code ->
  {value, _binding} = Code.eval_string(code)
  value
end

IO.puts("\n-- 1. = 是匹配，不是赋值：对不上就 MatchError --")
{x, y} = {1, 2}
IO.puts("{x, y} = {1, 2}  => x=#{inspect(x)}, y=#{inspect(y)}")
IO.puts("{a, b} = {1,2,3} => #{inspect(expect_match_error.("{a, b} = {1, 2, 3}"))}（形状不同，崩）")
IO.puts(":ok = :error     => #{inspect(expect_match_error.(":ok = :error"))}（值不同，崩）")

IO.puts("\n-- 2. 变量首次出现=绑定；同模式里再次出现=要求相等 --")
{z, z} = {5, 5}
IO.puts("{z, z} = {5, 5}  => z=#{inspect(z)}（两个位置相等才匹配）")
IO.puts("{z, z} = {5, 6}  => #{inspect(expect_match_error.("{z, z} = {5, 6}"))}")

IO.puts(
  "same_pair({1,1})=#{inspect(Ex04PatternMatching.same_pair({1, 1}))}，same_pair({1,2})=#{inspect(Ex04PatternMatching.same_pair({1, 2}))}"
)

IO.puts("\n-- 3. pin（^）：匹配变量已有的值，而不是重新绑定 --")
expected = 200
{^expected, body} = {200, "OK"}
IO.puts("expected=200；{^expected, body} = {200, \"OK\"} => body=#{inspect(body)}")
IO.puts("不用 ^ 会被重新绑定：v=1; v=2 => #{inspect(eval_value.("v = 1\nv = 2"))}")
IO.puts("用 ^ 才是比较：v=2; ^v=3 => #{inspect(expect_match_error.("v = 2\n^v = 3"))}")
IO.puts("match_status(200,200) => #{inspect(Ex04PatternMatching.match_status(200, 200))}")
IO.puts("match_status(404,200) => #{inspect(Ex04PatternMatching.match_status(404, 200))}")

IO.puts("\n-- 4. 元组解构：{:ok,_}/{:error,_} 通用返回形状 --")

for t <- [{:ok, 42}, {:error, :oops}, {:other, 1}] do
  IO.puts("classify(#{inspect(t)}) => #{inspect(Ex04PatternMatching.classify(t))}")
end

IO.puts("ok_value({:ok, \"hi\"}) => #{inspect(Ex04PatternMatching.ok_value({:ok, "hi"}))}")
IO.puts("ok_value({:error, :x}) => #{inspect(Ex04PatternMatching.ok_value({:error, :x}))}")

IO.puts("\n-- 5. 列表：头尾、精确长度、嵌套解构 --")
IO.puts("head_tail([1,2,3]) => #{inspect(Ex04PatternMatching.head_tail([1, 2, 3]))}")
IO.puts("head_tail([])      => #{inspect(Ex04PatternMatching.head_tail([]))}")

IO.puts(
  "pair?([:a,:b])=#{inspect(Ex04PatternMatching.pair?([:a, :b]))}，pair?([:a,:b,:c])=#{inspect(Ex04PatternMatching.pair?([:a, :b, :c]))}"
)

nested = {:user, "Ada", %{city: "London"}}
IO.puts("city(#{inspect(nested)}) => #{inspect(Ex04PatternMatching.city(nested))}")

IO.puts(
  "city({:user, \"Ada\", %{}}) => #{inspect(Ex04PatternMatching.city({:user, "Ada", %{}}))}"
)

IO.puts("\n-- 6. map 部分匹配：只要求键存在；动态键用 ^key => value --")

IO.puts(
  "has_name?(%{name: \"x\", age: 1}) => #{inspect(Ex04PatternMatching.has_name?(%{name: "x", age: 1}))}"
)

IO.puts(
  "has_name?(%{age: 1})               => #{inspect(Ex04PatternMatching.has_name?(%{age: 1}))}"
)

IO.puts("get_key(%{a:1,b:2}, :b) => #{inspect(Ex04PatternMatching.get_key(%{a: 1, b: 2}, :b))}")
IO.puts("get_key(%{a:1}, :b)     => #{inspect(Ex04PatternMatching.get_key(%{a: 1}, :b))}")

IO.puts(
  "get_key(%{\"name\" => \"Ada\"}, \"name\") => #{inspect(Ex04PatternMatching.get_key(%{"name" => "Ada"}, "name"))}"
)

IO.puts(
  "force_key!(%{a:1}, :missing) => #{inspect(expect_match_error.("Ex04PatternMatching.force_key!(%{a: 1}, :missing)"))}"
)

IO.puts("\n-- 7. 二进制前缀匹配：字面量用 <>，变量前缀用 <<^p::binary, rest::binary>> --")

IO.puts(
  "strip_prefix(\"Hello, world\", \"Hello, \") => #{inspect(Ex04PatternMatching.strip_prefix("Hello, world", "Hello, "))}"
)

IO.puts(
  "strip_prefix(\"goodbye\", \"Hello, \")       => #{inspect(Ex04PatternMatching.strip_prefix("goodbye", "Hello, "))}"
)

IO.puts(
  "split_32(<<1,0,0,0,9,8>>) => #{inspect(Ex04PatternMatching.split_32(<<1, 0, 0, 0, 9, 8>>))}（前 4 字节当大端 32 位）"
)

IO.puts("split_32(<<1,2>>)         => #{inspect(Ex04PatternMatching.split_32(<<1, 2>>))}")

IO.puts("\n-- 8. match?/2：只问对不对得上，永不崩 --")
IO.puts("ok?({:ok, 1})  => #{inspect(Ex04PatternMatching.ok?({:ok, 1}))}")
IO.puts("ok?(:nope)     => #{inspect(Ex04PatternMatching.ok?(:nope))}")

IO.puts(
  "select_ok([{:ok,1},{:error,:x},{:ok,3}]) => #{inspect(Ex04PatternMatching.select_ok([{:ok, 1}, {:error, :x}, {:ok, 3}]))}"
)

IO.puts("\n==== 04 结束 ====")
