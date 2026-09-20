# 第 23 章驱动脚本：cd examples/23_macros_types && mix run --no-compile run.exs
:io.setopts(:standard_io, encoding: :utf8)

require Ex23Macros
alias Ex23MacrosTypes

IO.puts("==== 23 宏与元编程 / 类型检查：AST、unquote、宏、卫生性、use、类型、编译期诊断 ====")

# ------------------------------------------------------------
# 1. quote：代码即三元素组数据
# ------------------------------------------------------------
IO.puts("\n-- 1. AST 三元素组 {名, 元数据, 参数}；变量参数为 nil --")

for code <- ["1 + 2", "foo(1)", "x", "[1, 2]"] do
  IO.puts("  #{code} => #{inspect(Ex23MacrosTypes.ast_shape(code))}")
end

# ------------------------------------------------------------
# 2. unquote / unquote_splicing：造代码并执行
# ------------------------------------------------------------
IO.puts("\n-- 2. quote 造 AST，unquote 注入运行值，eval_quoted 执行 --")
IO.puts("  run_quoted(41) => #{Ex23MacrosTypes.run_quoted(41)}")
IO.puts("  splice_sum([1,2,3]) => #{Ex23MacrosTypes.splice_sum([1, 2, 3])}")

# ------------------------------------------------------------
# 3. 自定义宏：my_unless 与 debug
# ------------------------------------------------------------
IO.puts("\n-- 3. 宏在编译期展开；下面一行是 debug 的输出 --")
IO.puts("  unless => #{inspect(Ex23MacrosTypes.unless_demo())}")
Ex23Macros.debug(1 + 2)

# ------------------------------------------------------------
# 4. 卫生性：默认隔离；var! 才能逃逸
# ------------------------------------------------------------
IO.puts("\n-- 4. 宏内变量默认与调用方隔离 --")
IO.puts("  卫生 => #{inspect(Ex23MacrosTypes.hygiene_demo())}")
IO.puts("  var! 逃逸 => #{inspect(Ex23MacrosTypes.escape_demo())}")

# ------------------------------------------------------------
# 5. use：展开目标模块的 __using__
# ------------------------------------------------------------
IO.puts("\n-- 5. use 是「调用 __using__ 并内联其返回的 AST」的语法糖 --")
IO.puts("  greet => #{Ex23Macros.Greeting.greet("世界")}")

# ------------------------------------------------------------
# 6. @type / @spec：给人和检查器看的契约
# ------------------------------------------------------------
IO.puts("\n-- 6. @spec 不做运行时检查；跨币种返回 tag 而非静默换算 --")

{:ok, money} =
  Ex23Macros.Money.add(
    %Ex23Macros.Money{amount: 100, currency: :CNY},
    %Ex23Macros.Money{amount: 50, currency: :CNY}
  )

IO.puts("  同币种 => #{inspect(money)}")

# ------------------------------------------------------------
# 7. 1.20 类型检查器：编译期诊断在运行时被捕获与归一化
# ------------------------------------------------------------
IO.puts("\n-- 7. 「恒为 :a」在编译期就被告警；诊断可捕获、不污染 stderr --")
IO.puts("  标签 => #{inspect(Ex23MacrosTypes.checker_demo())}")

IO.puts("""
-- 宏与类型要点 --
  代码即数据：quote 得 AST，unquote 注入，Code.eval_quoted 执行
  宏在编译期展开，生成代码；普通函数在运行期调用
  卫生性默认隔离变量；var! 是显式逃逸口，慎用
  use Module = 展开 Module.__using__/1，是「批量注入」的约定入口
  @type/@spec 是契约：给读代码的人和类型检查器，不做运行时校验
  1.20 类型检查器编译期抓「恒真恒假/不可达」；字面量别乱写，演示用 term 包装
""")

IO.puts("==== 23 结束 ====")
