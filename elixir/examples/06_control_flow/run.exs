# 第 06 章驱动脚本：cd examples/06_control_flow && mix run run.exs

# 与 locale 解耦：强制 stdio 按 UTF-8 编码（理由见 02 章坑位 1 / 08 章）。
:io.setopts(:standard_io, encoding: :utf8)

# 纪律：只打印确定性结论；pid/ref/时间戳一律不打印（run-all.sh 第 5 层逐字节比对）。

alias Ex06ControlFlow

IO.puts("==== 06 控制流 ====")

# 同 04 章：让「必然不匹配」在运行时才编译，避开静态告警。
expect_raise = fn code ->
  try do
    Code.eval_string(code)
    :no_raise
  rescue
    error -> error.__struct__
  end
end

IO.puts("\n-- 1. case：对一个值试「模式 + 守卫」，分支自上而下 --")

for v <- [{:ok, 1}, {:error, :x}, 42, [1, 2], [], :atom] do
  IO.puts("describe(#{inspect(v)}) => #{inspect(Ex06ControlFlow.describe(v))}")
end

IO.puts("")

for s <- [95, 70, 30, -5, :x] do
  IO.puts("tier(#{inspect(s)}) => #{inspect(Ex06ControlFlow.tier(s))}")
end

IO.puts("一个分支都对不上：")

IO.puts(
  "case :unmatched do :other -> ... end => #{inspect(expect_raise.("case :unmatched do\n  :other -> :never\nend"))}"
)

IO.puts("\n-- 2. cond：分支不共享同一个值，第一个为真者胜出 --")
IO.puts("fizzbuzz 1..15 =>")
IO.inspect(Enum.map(1..15, &Ex06ControlFlow.fizzbuzz/1), label: "  ")
IO.puts("没有 true 兜底：")

IO.puts(
  "cond do false -> ... end => #{inspect(expect_raise.("cond do\n  false -> :never\nend"))}"
)

IO.puts("\n-- 3. if / unless：都是有返回值的宏；只有 false/nil 为假 --")
IO.puts("greeting(\"Ada\") => #{inspect(Ex06ControlFlow.greeting("Ada"))}")
IO.puts("greeting(\"\")    => #{inspect(Ex06ControlFlow.greeting(""))}")

IO.puts(
  "positive_only(5) / (-1) / (:x) => #{inspect(Ex06ControlFlow.positive_only(5))} / #{inspect(Ex06ControlFlow.positive_only(-1))} / #{inspect(Ex06ControlFlow.positive_only(:x))}"
)

IO.puts("truthy_label(0) => #{inspect(Ex06ControlFlow.truthy_label(0))}（0 是真值！）")

IO.puts(
  "truthy_label(nil) / (false) => #{inspect(Ex06ControlFlow.truthy_label(nil))} / #{inspect(Ex06ControlFlow.truthy_label(false))}"
)

IO.puts("\n-- 4. with：成功形状 <- 串联，失败短路，else 集中处理 --")

IO.puts(
  "register(%{name: \"  Ada  \"})  => #{inspect(Ex06ControlFlow.register(%{name: "  Ada  "}))}"
)

IO.puts("register(%{name: \"\"})          => #{inspect(Ex06ControlFlow.register(%{name: ""}))}")

IO.puts(
  "register(%{name: 纯空格})       => #{inspect(Ex06ControlFlow.register(%{name: "   "}))}（裸原子失败 → other 兜底）"
)

IO.puts(
  "register(%{name: 超长})         => #{inspect(Ex06ControlFlow.register(%{name: "this-name-is-way-too-long"}))}"
)

IO.puts("chain({:ok,1},{:ok,2})  => #{inspect(Ex06ControlFlow.chain({:ok, 1}, {:ok, 2}))}")

IO.puts(
  "chain({:error,:x},_)    => #{inspect(Ex06ControlFlow.chain({:error, :x}, {:ok, 2}))}（无 else，失败值直接返回）"
)

IO.puts("\n-- 5. 作用域：if/case/cond/with 块内赋值不外泄 --")
IO.puts("rebind_inside(10) => #{Ex06ControlFlow.rebind_inside(10)}（块内改成 11，块外仍是 10）")

# if 是表达式，想让块内的计算「带出来」，靠返回值赋值，而不是依赖块内变量外泄：
chosen = if 1 > 0, do: :positive, else: :non_positive
IO.puts("chosen = if 1 > 0, do: ... => #{inspect(chosen)}")

# 下面这段在编译期就会被拒（诊断输出见 ExUnit 测试；run.exs 不能让它进 stderr）：
#
#     if true do
#       y = 1
#     end
#     y + 1
#     # ** (CompileError) undefined variable "y"
IO.puts("块内首次赋值的变量，块外读取 => CompileError（编译期拒绝，示例见测试）")

IO.puts("\n==== 06 结束 ====")
