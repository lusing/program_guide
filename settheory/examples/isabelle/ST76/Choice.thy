theory Choice
  imports "ZF.Cardinal_AC"
begin

text \<open>
第 76 章：选择公理与无穷和积不等式（冯琦 §2.1–2.2）。

ZF 的 AC 通道把选择公理作为显式公理记账：AC_Pi0 是“非空集族的
笛卡尔积非空”，AC_func_Pow 是幂集上的选择函数，AC_well_ord 是
良序定理，Zorn_po 是偏序形式的佐恩引理。Cardinal_AC 则在 AC 下
给出 |A|≈A、势比较与单射比较互译，以及无穷基数的乘法坍缩。
\<close>

subsection \<open>选择函数、非空积与良序化\<close>

text \<open>非空集族的积非空：定理 2.5(6) 的官方形式。\<close>
thm AC_Pi0

lemma nonempty_product:
  "0 \<notin> A \<Longrightarrow> \<exists>f. f \<in> (\<Prod>X \<in> A. X)"
  by (rule AC_Pi0)

text \<open>幂集选择函数：对 C 的每个非空子集 X，f(X)∈X。\<close>
thm AC_func_Pow

lemma powerset_choice:
  "\<exists>f \<in> (Pow(C)-{0}) -> C. \<forall>X \<in> Pow(C)-{0}. f`X \<in> X"
  by (rule AC_func_Pow)

text \<open>良序化原理与偏序版佐恩引理：定理 2.3、2.4。\<close>
thm AC_well_ord
thm Zorn_po

lemma every_set_well_orderable: "\<exists>r. well_ord(A,r)"
  by (rule AC_well_ord)

subsection \<open>AC 下的基数算术\<close>

text \<open>每个集合都和自己的初始序数等势：定理 2.3(3) 的库形态。\<close>
thm cardinal_eqpoll
thm cardinal_eqpoll_iff

lemma own_cardinal_eqpoll: "|A| \<approx> A"
  by (rule cardinal_eqpoll)

text \<open>在 AC 下，势的 ≤ 与存在单射完全互译。\<close>
thm lepoll_imp_cardinal_le
thm Card_le_imp_lepoll
thm le_Card_iff

text \<open>不交并的基数和与无穷基数的乘法坍缩：引理 2.1、74 章
基数平方定理在 AC 下的使用形态。\<close>
thm cardinal_disjoint_Un
thm InfCard_cmult_eq
thm InfCard_square_eq

lemma aleph0_square_eqpoll: "InfCard(|A|) \<Longrightarrow> A*A \<approx> A"
  by (rule InfCard_square_eq)

end
