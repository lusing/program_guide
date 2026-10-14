theory Absoluteness
  imports "ZF-Constructible.AC_in_L"
begin

text \<open>第 55 章 H_χ 定义骨架 + Σ₁ 向上保持的一阶引理。\<close>

definition
  Hchi :: "[i, i] \<Rightarrow> i" where
  "Hchi(A0, chi) \<equiv> {x \<in> A0 . \<exists>n \<in> chi . x \<subseteq> n}"

text \<open>骨架版：H_χ 的元素有 <χ 大小的传递闭包。\<close>

text \<open>Σ₁ 向上保持（Viale A.1 Prop 的一阶骨架）：
       M \<subseteq> N、a \<in> M、\<exists>w \<in> M . \<psi>(a,w) \<Longrightarrow> \<exists>w \<in> N . \<psi>(a,w)\<close>

lemma sigma1_upward:
  assumes "M \<subseteq> N" and "a \<in> M" and "w \<in> M" and "\<psi>(a, w)"
  shows "\<exists>u \<in> N . \<psi>(a, u)"
proof -
  from assms(3) assms(1) have "w \<in> N" by auto
  with assms(4) show ?thesis by blast
qed

end
