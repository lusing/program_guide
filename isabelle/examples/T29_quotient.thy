theory T29_quotient
  imports Main
begin

section \<open>29.1 为什么需要商类型\<close>

text \<open>第 28 章的 @{verbatim "typedef"} 是"**在底层类型里挑一个子集**"当作新类型。
还有一类常见需求："把**等价的**底层元素合并成同一个抽象元素"。典型场景：
有理数是 @{verbatim "int \<times> nat"} 按 @{verbatim "(a,b) \<sim> (c,d) \<equiv> a*d = b*c"}
折叠；模 @{verbatim "n"} 剩余类是 @{verbatim "nat"} 按
@{verbatim "x \<sim> y \<equiv> x mod n = y mod n"} 折叠。这就是
@{verbatim "quotient_type"}。\<close>

ML \<open>writeln "==== 29 开始 ===="\<close>

subsection \<open>29.2 关系 @{verbatim "eq3"}：模 3 同余\<close>

text \<open>先给底层 @{verbatim "nat"} 定一个等价关系 @{verbatim "eq3"}，
再用 @{verbatim "quotient_type"} 沿它折叠成类型 @{verbatim "three"}。\<close>

definition eq3 :: "nat \<Rightarrow> nat \<Rightarrow> bool" (infixl "\<cong>" 50) where
  "m \<cong> n \<longleftrightarrow> m mod 3 = n mod 3"

lemma eq3_equivp: "equivp (\<cong>)"
  by (rule equivpI) (auto simp: eq3_def reflp_def symp_def transp_def)

subsection \<open>29.3 @{verbatim "quotient_type"}：折叠 @{verbatim "nat"} 得 @{verbatim "three"}\<close>

text \<open>语法 @{verbatim "quotient_type T = A / r"}。Isabelle 内部把 T 建成
"底层 @{verbatim "A"} 上 @{verbatim "r"}-闭集"的子类型（用 @{verbatim "typedef"} 实现），
然后送两条视图：
@{verbatim "Abs_three :: A set \<Rightarrow> T"} 是"给一个 @{verbatim "r"}-闭集，抽象成一个元素"；
@{verbatim "Quotient_three"} 里的 @{verbatim "abs_three :: A \<Rightarrow> T"} 是"给一个代表元，抽象成一个元素"。
日常使用的是小写的 @{verbatim "abs_three"} 与 @{verbatim "rep_three"}。\<close>

quotient_type three = "nat" / "(\<cong>)"
  by (auto intro!: equivpI reflpI sympI transpI simp: eq3_def)

term abs_three
term rep_three

thm type_definition_three
thm Quotient_three

subsection \<open>29.4 @{verbatim "lift_definition"}：在商类型上定义运算\<close>

text \<open>提升底层函数到 @{verbatim "three"} 需要**兼容性**：等价元的像仍等价。
先证 @{verbatim "eq3_plus"} 一条兼容引理：
@{verbatim "a \<cong> b \<Longrightarrow> c \<cong> d \<Longrightarrow> a + c \<cong> b + d"}，
再让 @{verbatim "lift_definition"} 用它。\<close>

lemma eq3_plus: "a \<cong> b \<Longrightarrow> c \<cong> d \<Longrightarrow> a + c \<cong> b + d"
  unfolding eq3_def by (rule mod_add_cong) blast+

lift_definition plus_three :: "three \<Rightarrow> three \<Rightarrow> three" is "(+)"
  by (rule eq3_plus)

lift_definition zero_three :: "three" is "0::nat" .

subsection \<open>29.5 @{verbatim "transfer"}：把商层目标下沉到 @{verbatim "nat"}\<close>

text \<open>@{verbatim "transfer"} 依赖 @{verbatim "Quotient_three"}（@{verbatim "quotient_type"}
自动登记，不需 @{verbatim "setup_lifting"}）。它把 @{verbatim "three"} 层
目标换成底层 @{verbatim "nat"} 上的条件版本，前提自动是等价关系 @{verbatim "\<cong>"}。\<close>

lemma plus_three_zero [simp]: "plus_three zero_three x = x"
  apply transfer
  unfolding eq3_def by simp

lemma plus_three_comm: "plus_three x y = plus_three y x"
  apply transfer
  unfolding eq3_def by (simp add: algebra_simps)

subsection \<open>29.6 @{verbatim "abs_three"} 上具体元素相等\<close>

text \<open>抽象层元素相等：底层 @{verbatim "x"}、@{verbatim "y"} 的抽象像相等当且仅当
@{verbatim "x \<cong> y"}。用 @{verbatim "transfer"} 一步下沉：\<close>

lemma "abs_three 5 = abs_three 2"
  apply transfer
  unfolding eq3_def by simp

lemma "abs_three (4::nat) \<noteq> abs_three 2"
  apply transfer
  unfolding eq3_def by simp

subsection \<open>29.7 与 @{verbatim "typedef"} 的分界\<close>

text \<open>两条命令都在"底层类型到抽象类型"这一层做事，区别在**映射形状**：

  - @{verbatim "typedef T = S"}：@{verbatim "S"} 是子集，@{verbatim "Rep"} 是**单射**，
    抽象值与底层 @{verbatim "S"} 中元素一一对应；
  - @{verbatim "quotient_type T = A / r"}：@{verbatim "A"} 全用，@{verbatim "abs"}
    是**满射**且把 @{verbatim "r"}-等价的底层元素映到同一抽象值。

商类型对**等价关系**敏感，@{verbatim "r"} 一变抽象就变；子集类型对
@{verbatim "S"} 敏感。\<close>

subsection \<open>29.8 常见坑：兼容性证明\<close>

text \<open>若想把 @{verbatim "even"} 提升到 @{verbatim "three"} 作为
@{verbatim "three \<Rightarrow> bool"}，@{verbatim "even"} 在 @{verbatim "eq3"} 下
**不保持等价**（@{verbatim "0 \<cong> 3"} 却 @{verbatim "even 0"} 且
@{verbatim "\<not> even 3"}）。这条 @{verbatim "lift_definition"} 会被 Isabelle
拒绝。\<close>

lemma eq3_0_3: "0 \<cong> (3::nat)" unfolding eq3_def by simp
lemma not_even_3: "\<not> even (3::nat)" by simp

text \<open>这就是 @{verbatim "quotient_type"} 相比 @{verbatim "typedef"} **多出来**的
证明义务：@{verbatim "typedef"} 只要闭合到子集，@{verbatim "quotient_type"}
还要**与等价关系相容**。\<close>

ML \<open>writeln "==== 29 结束 ===="\<close>

end
