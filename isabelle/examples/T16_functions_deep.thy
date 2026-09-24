theory T16_functions_deep
  imports Main
begin

section \<open>16.1 function：非结构递归的全套流程\<close>

text \<open>@{verbatim "fun"} 摆不平的递归要用 @{verbatim "function"}：
先给方程（配 @{verbatim "pat_completeness"} 证明模式穷尽），
再给 @{verbatim "termination"}。本章走一遍完整流程，
并演示"真的不终止"时的 @{verbatim "partial_function"}。\<close>

ML \<open>writeln "==== 16 开始 ===="\<close>

subsection \<open>16.2 快排：两次递归 + 度量\<close>

function qsort :: "nat list \<Rightarrow> nat list" where
  "qsort [] = []"
| "qsort (x # xs) = qsort (filter (\<lambda>y. y \<le> x) xs) @ [x] @ qsort (filter (\<lambda>y. x < y) xs)"
  by pat_completeness auto
termination
  by (relation "measure length")
     (auto intro: le_less_trans length_filter_le lessI)

text \<open>终止性目标里出现
@{verbatim "length (filter P xs) < length (x # xs)"}：
一次 @{verbatim "simp"} 不够（它只做重写，不做"传递"），
要让 @{verbatim "auto"} 把 @{verbatim "length_filter_le"} 与
@{verbatim "length xs < Suc (length xs)"} 接起来。\<close>

value "qsort [3::nat, 1, 2]"
value "qsort ([]::nat list)"

subsection \<open>16.3 欧几里得算法：用条件写度量\<close>

function gcd1 :: "nat \<Rightarrow> nat \<Rightarrow> nat" where
  "gcd1 m n = (if n = 0 then m else gcd1 n (m mod n))"
  by pat_completeness auto
termination
  by (relation "measure (\<lambda>(m, n). n)") (auto simp: mod_less_divisor)

text \<open>这里的度量是"第二个参数"。@{verbatim "m mod n < n"} 只在
@{verbatim "n > 0"} 时成立，所以 @{verbatim "termination"} 的证明里
要靠 @{verbatim "mod_less_divisor"} 这条库引理。\<close>

value "gcd1 1071 462"
value "gcd1 462 1071"

subsection \<open>16.4 partial_function：不要求终止\<close>

partial_function (option) find1 :: "(nat \<Rightarrow> bool) \<Rightarrow> nat \<Rightarrow> nat option" where
  "find1 P n = (if P n then Some n else find1 P (n + 1))"

text \<open>@{verbatim "partial_function"} 生成的方程带 @{verbatim "dom"} 前提，
所以它不能被求值器直接算；使用它的每一步都要自己证明"这次调用会停"。
因此在教程里，凡是能给出度量的函数，一律优先
@{verbatim "function"} + @{verbatim "termination"}。\<close>

subsection \<open>16.5 改写成结构递归：让性质可证\<close>

text \<open>下面这个"往下找"的版本用 @{verbatim "fun"} 就能定义，
因为它是结构递归。结构递归的化简规则有终止性保证，
@{verbatim "simp"} 可以放心展开——这是它比 @{verbatim "function"}
版本更适合做性质证明的原因。\<close>

fun find3 :: "(nat \<Rightarrow> bool) \<Rightarrow> nat \<Rightarrow> nat option" where
  "find3 P 0 = (if P 0 then Some 0 else None)"
| "find3 P (Suc n) = (if P (Suc n) then Some (Suc n) else find3 P n)"

value "find3 (\<lambda>n::nat. n = 3) (5::nat)"
value "find3 (\<lambda>n::nat. n = 9) (5::nat)"

lemma find3_hit: "P n \<Longrightarrow> find3 P n = Some n"
  by (induction n) simp_all

lemma find3_returns: "find3 P n = Some k \<Longrightarrow> P k"
  by (induction n) (simp_all split: if_split_asm)

text \<open>反面经验：如果把它换成"往上找"的 @{verbatim "n + 1"} 版本
（参数不下降），@{verbatim "simp"} 展开它的方程时会无限循环，
任何含它的证明都会卡死。遇到"证明卡住不动"，
先怀疑这一类无条件展开的递归方程。\<close>

subsection \<open>16.6 观察 function 送出来的定理清单\<close>

ML \<open>
  writeln (@{make_string} (hd @{thms find3.simps}));
  writeln (@{make_string} @{thm find3.induct})
\<close>

ML \<open>writeln "==== 16 结束 ===="\<close>

end
