# 第 25 章驱动脚本：cd examples/25_thinking && mix run --no-compile run.exs
:io.setopts(:standard_io, encoding: :utf8)

alias Ex25Thinking

IO.puts("==== 25 函数式思维：不可变数据、纯函数、声明式 ====")

# ------------------------------------------------------------
# 1. 不可变数据：操作返回新值，原值不动
# ------------------------------------------------------------
IO.puts("\n-- 1. 不可变数据：删尾/追加都产生新值，原列表纹丝不动 --")

list = [1, 2, 3, 4]
IO.puts("  without_last([1,2,3,4]) => #{inspect(Ex25Thinking.without_last(list))}")
IO.puts("  append([1,2,3,4], 5)   => #{inspect(Ex25Thinking.append(list, 5))}")
IO.puts("  原列表 => #{inspect(list)}")

# ------------------------------------------------------------
# 2. 结构共享：不可变不等于全量复制
# ------------------------------------------------------------
IO.puts("\n-- 2. 结构共享：cons 出的新列表，尾部就是旧列表本身 --")

base = Ex25Thinking.runtime_list()
newer = Ex25Thinking.cons_ahead(base)
copy = Ex25Thinking.append_copy(base)

IO.puts("  cons 出的新列表，尾部与旧列表同一对象 => #{:erts_debug.same(tl(newer), base)}")

IO.puts(
  "  ++ 复制左表：前 3 个内容相等 => #{Enum.take(copy, 3) == base}，尾部同一对象 => #{:erts_debug.same(tl(copy), tl(base))}"
)

IO.puts("  （cons O(1) 共享；++ O(n) 复制——不可变的代价远小于全量拷贝）")

# ------------------------------------------------------------
# 3. 纯函数：同参同果、引用透明
# ------------------------------------------------------------
IO.puts("\n-- 3. 纯函数：tax(100, 8) 调两次结果一致，可被 8.0 原样替换 --")

IO.puts("  tax(100, 8) 第一次 => #{Ex25Thinking.tax(100, 8)}")
IO.puts("  tax(100, 8) 第二次 => #{Ex25Thinking.tax(100, 8)}")

# ------------------------------------------------------------
# 4. MySet：状态显式流动，push 幂等
# ------------------------------------------------------------
IO.puts("\n-- 4. MySet：状态在返回值里流动；重复 push 幂等 --")

IO.puts("  myset_demo() => #{inspect(Ex25Thinking.myset_demo())}")

set0 = %Ex25Thinking.MySet{}
set1 = Ex25Thinking.MySet.push(set0, "apple")
set2 = Ex25Thinking.MySet.push(set1, "apple")
IO.puts("  重复 push 后 set2 == set1 => #{set2 == set1}")

# ------------------------------------------------------------
# 5. 声明式三写法：手写递归 / Enum.map / 命令式对照
# ------------------------------------------------------------
IO.puts("\n-- 5. 声明式：递归两子句与 Enum.map 描述「要什么」，不说「怎么改」 --")

words = ["dogs", "hot dogs", "bananas"]
IO.puts("  upcase_rec => #{inspect(Ex25Thinking.upcase_rec(words))}")
IO.puts("  upcase_map => #{inspect(Ex25Thinking.upcase_map(words))}")
IO.puts("  两种写法同结果 => #{Ex25Thinking.upcase_rec(words) == Ex25Thinking.upcase_map(words)}")

# ------------------------------------------------------------
# 6. 管道：数据从上向下流动
# ------------------------------------------------------------
IO.puts("\n-- 6. 管道：capitalize_words(\"the dark tower\") --")

IO.puts("  管道版   => #{inspect(Ex25Thinking.capitalize_words("the dark tower"))}")
IO.puts("  嵌套版   => #{inspect(Ex25Thinking.capitalize_words_nested("the dark tower"))}")

IO.puts(
  "  两版一致 => #{Ex25Thinking.capitalize_words("the dark tower") == Ex25Thinking.capitalize_words_nested("the dark tower")}"
)

IO.puts("\n==== 25 结束 ====")
