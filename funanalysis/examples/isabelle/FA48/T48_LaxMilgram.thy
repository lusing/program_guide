theory T48_LaxMilgram
  imports "HOL-Analysis.Cartesian_Euclidean_Space"
begin

text \<open>
  第 48 章（Isabelle 通道）：Lax-Milgram 引理在 real^2 的化身。
  强制矩阵（inner x (M *v x) \<ge> b * inner x x，b>0）的核平凡
  ——这是 Lax 证明第二步核心不等式 (21) 的转置版本；
  再由有限维『线性单射 = 满射』，表示方程 M *v y = f 对一切右端
  f 存在唯一解，即 Lax-Milgram 的有限维全文。

  实测坑：shows 里的未标注类型的全称变量（如 \<forall>f. ... M *v y = f）
  若类型重建失败，Isabelle 会以 "Malformed command syntax" 的
  外层语法错误伪装报告——必须写 \<forall>(f::real^2) 显式定型。
\<close>

section \<open>第一步：强制性 ⟹ 核平凡（(21) 的对偶形式）\<close>

lemma ker_trivial:
  fixes M :: "real^2^2"
  assumes hb : "0 < b"
      and hcoe: "\<forall>x. b * inner x x \<le> inner x (M *v x)"
      and hz  : "M *v x = 0"
  shows "x = 0"
proof -
  have step1: "b * inner x x \<le> inner x (M *v x)"
    using hcoe by simp
  have step2: "inner x (M *v x) = 0"
    using hz by simp
  have hle: "b * inner x x \<le> 0"
    using step1 step2 by simp
  have npos: "\<not> (0 < inner x x)"
  proof
    assume "0 < inner x x"
    then have "0 < b * inner x x"
      using hb by simp
    then show False
      using hle by simp
  qed
  have eq0: "inner x x = 0"
    using npos inner_ge_zero by (simp add: le_less)
  then show "x = 0"
    by (simp add: inner_eq_zero_iff)
qed

section \<open>第二步：有限维收尾——单射即满射，表示方程总可解\<close>

theorem lax_milgram_real2:
  fixes M :: "real^2^2"
  assumes hb : "0 < b"
      and hcoe: "\<forall>x. b * inner x x \<le> inner x (M *v x)"
  shows "\<forall>(f::real^2). \<exists>!y. M *v y = f"
proof -
  have lin: "linear (\<lambda>x. M *v x)"
    using matrix_vector_mul_linear by blast
  have hker: "M *v x = 0 \<Longrightarrow> x = 0" for x
    using ker_trivial [OF hb hcoe] .
  have hinj: "inj (\<lambda>x. M *v x)"
  proof (rule injI)
    fix x y assume "(\<lambda>x. M *v x) x = (\<lambda>x. M *v x) y"
    then have heq: "M *v x = M *v y" by simp
    have hdiff: "M *v (x - y) = M *v x - M *v y"
      by (vector matrix_vector_mult_def sum.distrib algebra_simps)+
    then have "M *v (x - y) = 0"
      using heq by simp
    then have "x - y = 0"
      by (rule hker)
    then show "x = y"
      by simp
  qed
  have hsurj: "surj (\<lambda>x. M *v x)"
    by (rule linear_inj_imp_surj [OF lin hinj])
  show ?thesis
  proof
    fix f :: "real^2"
    obtain y where hy: "M *v y = f"
      by (metis hsurj surj_def)
    have uniq: "\<And>z. M *v z = f \<Longrightarrow> z = y"
    proof -
      fix z assume hz: "M *v z = f"
      have "M *v (z - y) = M *v z - M *v y"
        by (vector matrix_vector_mult_def sum.distrib algebra_simps)+
      then have "M *v (z - y) = 0"
        using hz hy by simp
      then have "z - y = 0"
        by (rule hker)
      then show "z = y"
        by simp
    qed
    then show "\<exists>!y. M *v y = f"
      using hy by blast
  qed
qed

end
