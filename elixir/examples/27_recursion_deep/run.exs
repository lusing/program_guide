# 第 27 章驱动脚本：cd examples/27_recursion_deep && mix run --no-compile run.exs
:io.setopts(:standard_io, encoding: :utf8)

alias Ex27RecursionDeep

IO.puts("==== 27 递归进阶：减治、分治、无界递归、匿名函数自递归 ====")

# ------------------------------------------------------------
# 1. 有界递归：终止子句在前
# ------------------------------------------------------------
IO.puts("\n-- 1. 有界递归：up_to(5) = 5 + (4 + (3 + (2 + (1 + 0)))) = 15 --")

IO.puts("  up_to(5)      => #{Ex27RecursionDeep.up_to(5)}")
IO.puts("  up_to_tail(5) => #{Ex27RecursionDeep.up_to_tail(5)}")
IO.puts("  up_to_tail(1_000_000) => #{Ex27RecursionDeep.up_to_tail(1_000_000)}（尾递归百万级不爆栈）")

# ------------------------------------------------------------
# 2. cons 构建新列表：魔法商店
# ------------------------------------------------------------
IO.puts("\n-- 2. 魔法商店：cons 逐头构建 + 子图匹配跳过已施法物品 --")

items = Ex27RecursionDeep.enchant_for_sale(Ex27RecursionDeep.test_data())

IO.puts("  施法后标题 => #{inspect(Enum.map(items, & &1.title))}")
IO.puts("  施法后价格 => #{inspect(Enum.map(items, & &1.price))}（已施法的 60/100 原样保留）")

IO.puts(
  "  与 Enum.map 版一致 => #{items == Ex27RecursionDeep.enchant_enum(Ex27RecursionDeep.test_data())}"
)

# ------------------------------------------------------------
# 3. 减治法：从手写答案发现递归模式
# ------------------------------------------------------------
IO.puts("\n-- 3. 减治法：手写 0..4 的阶乘 → 发现 n! = n * (n-1)! → 两条子句收工 --")

IO.puts("  naive_factorial(4) => #{Ex27RecursionDeep.naive_factorial(4)}")
IO.puts("  factorial(4)       => #{Ex27RecursionDeep.factorial(4)}")
IO.puts("  factorial_tail(4)  => #{Ex27RecursionDeep.factorial_tail(4)}")

# ------------------------------------------------------------
# 4. 分治法：归并排序
# ------------------------------------------------------------
IO.puts("\n-- 4. 分治法：对半切、各自排、按序合并（merge [5,9] [1,4,5] → [1,4,5,5,9]）--")

IO.puts("  ascending([9,5,1,5,4])  => #{inspect(Ex27RecursionDeep.ascending([9, 5, 1, 5, 4]))}")
IO.puts("  descending([9,5,1,5,4]) => #{inspect(Ex27RecursionDeep.descending([9, 5, 1, 5, 4]))}")

IO.puts(
  "  与 Enum.sort 一致       => #{Ex27RecursionDeep.ascending([9, 5, 1, 5, 4]) == Enum.sort([9, 5, 1, 5, 4])}"
)

# ------------------------------------------------------------
# 5. 无界递归：虚拟文件系统 + 深度界限 + 防环
# ------------------------------------------------------------
IO.puts("\n-- 5. 无界递归：深度不可预测的目录树——加界限、跳过符号链接 --")

IO.puts(
  "  walk(test_fs(), 1) => #{inspect(Ex27RecursionDeep.walk(Ex27RecursionDeep.test_fs(), 1))}"
)

IO.puts(
  "  walk(test_fs(), 2) => #{inspect(Ex27RecursionDeep.walk(Ex27RecursionDeep.test_fs(), 2))}"
)

IO.puts(
  "  walk(test_fs(), 3) => #{inspect(Ex27RecursionDeep.walk(Ex27RecursionDeep.test_fs(), 3))}"
)

IO.puts("  （deeper 里的 x.ex 只有 max_depth >= 3 才被数到；loop -> lib 是环，一律跳过）")

# ------------------------------------------------------------
# 6. 匿名函数的自递归
# ------------------------------------------------------------
IO.puts("\n-- 6. 匿名函数自递归：me.(me) 自应用；实战请用具名函数 + & 引用 --")

IO.puts("  make_factorial().(5)  => #{Ex27RecursionDeep.make_factorial().(5)}")
IO.puts("  named_factorial().(5) => #{Ex27RecursionDeep.named_factorial().(5)}")

# ------------------------------------------------------------
# 7. 体递归 vs 尾递归：十万级的答案一致性
# ------------------------------------------------------------
IO.puts("\n-- 7. 体递归 vs 尾递归：100_000! 两种写法答案逐位一致 --")

body = Ex27RecursionDeep.factorial(100_000)
tail = Ex27RecursionDeep.factorial_tail(100_000)
IO.puts("  factorial(100_000) == factorial_tail(100_000) => #{body == tail}")
IO.puts("  位数 => #{body |> Integer.to_string() |> String.length()}（BEAM 大整数无上限）")

IO.puts("\n==== 27 结束 ====")
