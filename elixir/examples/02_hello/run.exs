# 第 02 章驱动脚本：cd examples/02_hello && mix run run.exs

# BEAM 的 :standard_io 编码取自系统 locale；LANG/LC_ALL 未设时退回 latin1，
# 中文会被 IO.puts 打成 \x{7ED3}\x{675F} 这样的字面转义（08 章展开，
# CHEATSheet 有专条）。显式设成 utf8，脚本就与 locale 无关了。
:io.setopts(:standard_io, encoding: :utf8)

# 这里刻意不打印任何「环境相关的数字」（时间戳、pid、版本号），只打印确定性的
# 演示结果 —— run-all.sh 第 5 层会把同一份 BEAM 钉成单调度器
# （ERL_FLAGS="+S 1:1"）再跑一遍，要求 stdout 逐字节一致。

IO.puts("==== 02 第一个程序 ====")

IO.puts("\n-- 1. 最小函数 --")
IO.puts("hello()                => #{inspect(Ex02Hello.hello())}")

IO.puts("\n-- 2. arity 属于函数名：greet/1 与 greet/2 是两个函数 --")
IO.puts(~s|greet("世界")           => #{inspect(Ex02Hello.greet("世界"))}|)
IO.puts(~s|greet("Hi", "world")   => #{inspect(Ex02Hello.greet("Hi", "world"))}|)
IO.puts("greet/1 已导出         => #{inspect(function_exported?(Ex02Hello, :greet, 1))}")
IO.puts("greet/3 已导出         => #{inspect(function_exported?(Ex02Hello, :greet, 3))}")

IO.puts("\n-- 3. {:ok, _} / {:error, _} 返回约定 --")

for text <- ["  42 ", "0", "-1", "12abc", ""] do
  IO.puts("parse_age(#{inspect(text)}) => #{inspect(Ex02Hello.parse_age(text))}")
end

IO.puts("\n-- 4. 插值（String.Chars） vs inspect（Inspect 协议） --")

for value <- ["文本", :ok, nil, 42, 3.5, true, {1, 2}, %{a: 1}, [1, 2, 3], ~c"hi"] do
  {interpolated, inspected} = Ex02Hello.render(value)

  shown =
    cond do
      interpolated == "(不可插值)" -> "(不可插值)"
      interpolated == "" -> "(空串)"
      true -> inspect(interpolated)
    end

  IO.puts("  inspect => #{inspected}")
  IO.puts("  插值   => #{shown}")
end

IO.puts("\n-- 5. 私有函数：外部不可见，模块内部可用 --")
IO.puts("doubled(21)                   => #{inspect(Ex02Hello.doubled(21))}")

IO.puts(
  "internal_only/1 已导出        => #{inspect(function_exported?(Ex02Hello, :internal_only, 1))}"
)

IO.puts("\n-- 6. 模块自省：__info__/1 --")
exports = Ex02Hello.__info__(:functions) |> Enum.sort()
IO.puts("__info__(:functions) => #{length(exports)} 个导出函数")

for {name, arity} <- exports do
  IO.puts("  #{name}/#{arity}")
end

IO.puts("__info__(:module)    => #{inspect(Ex02Hello.__info__(:module))}")
IO.puts("__info__(:macros)    => #{inspect(Ex02Hello.__info__(:macros))}")

IO.puts(
  "module_info(:compile)[:version] 存在 => #{inspect(Keyword.has_key?(Ex02Hello.module_info(:compile), :version))}"
)

IO.puts("\n-- 7. main/1：脚本形态的入口 --")
:ok = Ex02Hello.main(["--verbose", "a.txt"])

IO.puts("\n==== 02 结束 ====")
