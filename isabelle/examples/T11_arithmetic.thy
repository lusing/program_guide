theory T11_arithmetic
  imports Main
begin

section \<open>11.1 nat 算术：归纳与化简的练兵场\<close>

text \<open>nat 是最小的归纳类型，因此算术引理几乎都用归纳证。
本章把加、乘、序、奇偶过一遍，并指出 nat 与 int 的差异。\<close>

ML \<open>writeln "==== 11 开始 ===="\<close>

subsection \<open>11.2 加法与乘法的标准引理\<close>

lemma add_assoc_demo: "(m + n) + k = m + (n + (k::nat))"
  by simp

lemma add_comm_demo: "m + n = n + (m::nat)"
  by simp

lemma mult_assoc_demo: "(m * n) * k = m * (n * (k::nat))"
  by simp

text \<open>标准引理大多已在 @{verbatim "[simp]"} 里，直接 @{verbatim "simp"}
就能过。自己证的要点是"知道归纳长什么样"：\<close>

lemma add_0_demo: "n + (0::nat) = n"
  by (induction n) simp_all

lemma add_suc_demo: "n + Suc m = Suc (n + (m::nat))"
  by (induction n) simp_all

subsection \<open>11.3 序关系\<close>

lemma le_trans_demo: "a \<le> (b::nat) \<Longrightarrow> b \<le> c \<Longrightarrow> a \<le> c"
  by (rule le_trans)

lemma le_antisym_demo: "a \<le> (b::nat) \<Longrightarrow> b \<le> a \<Longrightarrow> a = b"
  by (rule le_antisym)

lemma add_le_demo: "a \<le> (b::nat) \<Longrightarrow> a + c \<le> b + c"
  by simp

lemma "a < (b::nat) \<Longrightarrow> a + 1 \<le> b"
  by simp

subsection \<open>11.4 奇偶性：一个自建递归谓词\<close>

fun even_n :: "nat \<Rightarrow> bool" where
  "even_n 0 = True"
| "even_n (Suc n) = (\<not> even_n n)"

value "even_n (0::nat)"
value "even_n (1::nat)"
value "even_n (2::nat)"

lemma even_add: "even_n (m + n) = (even_n m \<longleftrightarrow> even_n n)"
proof (induction m)
  case 0
  then show ?case by simp
next
  case (Suc m)
  then show ?case by (simp; blast)
qed

lemma even_double: "even_n (n + n)"
  by (induction n) simp_all

subsection \<open>11.5 nat 的减法陷阱\<close>

value "(5::nat) - 3"
value "(3::nat) - 5"

text \<open>nat 的减法是截断的：@{verbatim "3 - 5 = 0"}，
而不是 -2。需要负数时用 @{verbatim "int"}：\<close>

value "(3::int) - 5"

lemma nat_sub_absorb: "n - n = (0::nat)"
  by simp

lemma "a \<le> (b::nat) \<Longrightarrow> a + (b - a) = b"
  by simp

subsection \<open>11.6 整数与自然数的桥\<close>

value "int (3::nat)"
value "nat ((3::int) - 5)"

lemma "nat (int n) = n"
  by simp

ML \<open>writeln "==== 11 结束 ===="\<close>

end
