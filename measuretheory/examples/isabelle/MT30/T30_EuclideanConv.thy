theory T30_EuclideanConv
  imports "HOL-Probability.Helly_Selection"
begin

section \<open>第 30 章：欧氏空间上的测度收敛（Helly 选择）\<close>

text \<open>对应严书 6.1 / 袁上册 12.3。Isabelle 锚点：
Helly_Selection.thy 的 Helly_selection（右连续单调有界函数列
的对角线子列存在性——分布函数列的紧性源头）与
tight_imp_convergent_subsubsequence（胎紧 ⟹ 收敛子列，32 章
的一维预告）。实弹：δ_{1/(n+1)} 漂移族的逐点账——跳点 0 的
失败现场与负半轴的常值收敛。\<close>

thm Helly_selection
thm tight_imp_convergent_subsubsequence

subsection \<open>离散漂移族的逐点账\<close>

definition F_n :: "nat \<Rightarrow> real \<Rightarrow> real" where
  "F_n n x = (if 1 / (n + 1) \<le> x then 1 else 0)"

lemma F_n_neg_half:
  fixes x :: real
  assumes "x < 0"
  shows "(\<lambda>n. F_n n x) \<longlonglongrightarrow> 0"
proof -
  have "\<And>n. F_n n x = 0"
  proof -
    fix n :: nat
    have pos: "(0::real) < 1 / (1 + real n)" by simp
    show "F_n n x = 0"
    proof (cases "1 / (1 + real n) \<le> x")
      case True
      with assms pos show ?thesis by simp
    next
      case False
      then show ?thesis by (simp add: F_n_def)
    qed
  qed
  then show ?thesis by simp
qed

lemma F_n_jump_zero:
  shows "\<And>n. F_n n 0 = (0::real)"
  by (simp add: F_n_def)

end
