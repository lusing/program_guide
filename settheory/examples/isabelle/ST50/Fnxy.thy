theory Fnxy
  imports "ZF-Constructible.AC_in_L"
begin

text \<open>第 50 章 Fn(X,2) 的骨架：条件 = 有限部分函数；
       两条件相容 ⟺ 并仍是函数。谓词式 + 正向 blast 纪律。\<close>

definition
  fn_cond :: "[i, i, i] \<Rightarrow> o" where
  "fn_cond(X, Y, s) \<equiv> s \<in> Pow(X*Y) \<and> function(s)"

text \<open>相容性：s 与 t 的并可扩张为函数（无坐标冲突）。\<close>

definition
  fn_compat :: "[i, i, i] \<Rightarrow> o" where
  "fn_compat(s, t, u) \<equiv> function(s \<union> t) \<and> s \<union> t \<subseteq> u"

text \<open>自身相容：函数并自身是函数。\<close>

lemma fn_self_compat:
  assumes "fn_cond(X, Y, s)"
  shows "function(s \<union> s)"
  using assms unfolding fn_cond_def by simp

text \<open>相容的对称性：并的交换律一行。\<close>

lemma fn_compat_sym:
  "fn_compat(s, t, u) \<longleftrightarrow> fn_compat(t, s, u)"
  unfolding fn_compat_def by (simp add: Un_commute)

text \<open>公共精化：相容的两个条件有共同延拓（其并）。\<close>

lemma fn_common_extension:
  assumes "fn_cond(X, Y, s)" and "fn_cond(X, Y, t)"
    and "fn_compat(s, t, X*Y)"
  shows "fn_cond(X, Y, s \<union> t)"
proof -
  have "s \<union> t \<in> Pow(X*Y)"
    using assms(1,2) unfolding fn_cond_def by auto
  moreover have "function(s \<union> t)"
    using assms(3) unfolding fn_compat_def by simp
  ultimately show ?thesis unfolding fn_cond_def by simp
qed

end
