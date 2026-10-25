theory Pcf
  imports ZF
begin

text \<open>第 86 章 · 谢旯 pcf 理论（冯琦第二卷 §1.3）。
有限正则集合上的标尺、主超滤子与传递生成元样品。
（ZF 中自然数须写 succ 链；下面用 a0=0,a1=1,a2=2 作玩具正则集合。
注意：名字 lam 与 ZF 的 lam 常量冲突，生成元参数改用 ell。）\<close>

definition a0 :: i where "a0 \<equiv> 0"
definition a1 :: i where "a1 \<equiv> succ(0)"
definition a2 :: i where "a2 \<equiv> succ(succ(0))"

definition A :: i where "A \<equiv> {a0, a1, a2}"

definition le_pw :: "[i, i] \<Rightarrow> o" where
  "le_pw(f, g) \<equiv> \<forall>n\<in>A. f`n \<le> g`n"

definition scale0 :: i where "scale0 \<equiv> (\<lambda>n\<in>A. 0)"
definition scale1 :: i where "scale1 \<equiv> (\<lambda>n\<in>A. succ(0))"
definition scale2 :: i where "scale2 \<equiv> (\<lambda>n\<in>A. succ(succ(0)))"

lemma A_elems: "a0 \<in> A" "a1 \<in> A" "a2 \<in> A"
  by (simp_all add: A_def)

lemma scale_increasing_01: "le_pw(scale0, scale1)"
  unfolding le_pw_def
proof (rule ballI)
  fix n assume nA: "n \<in> A"
  have "scale0`n = 0" using nA by (simp add: scale0_def beta)
  moreover have "scale1`n = succ(0)" using nA by (simp add: scale1_def beta)
  ultimately show "scale0`n \<le> scale1`n" by simp
qed

lemma scale_increasing_12: "le_pw(scale1, scale2)"
  unfolding le_pw_def
proof (rule ballI)
  fix n assume nA: "n \<in> A"
  have "scale1`n = succ(0)" using nA by (simp add: scale1_def beta)
  moreover have "scale2`n = succ(succ(0))" using nA by (simp add: scale2_def beta)
  ultimately show "scale1`n \<le> scale2`n" by simp
qed

definition principal :: "[i, i] \<Rightarrow> o" where
  "principal(a, X) \<equiv> a \<in> X"

lemma principal_singleton: "a \<in> A \<Longrightarrow> principal(a, {a})"
  by (simp add: principal_def)

definition generator :: "i \<Rightarrow> i" where
  "generator(ell) \<equiv> Collect(A, %x. x \<le> ell)"

lemma generator_mem:
  "x \<in> generator(ell) \<longleftrightarrow> x \<in> A \<and> x \<le> ell"
  by (simp add: generator_def)

lemma generator_a0: "generator(a0) = {a0}"
proof (rule equalityI)
  show "generator(a0) \<subseteq> {a0}"
  proof (rule subsetI)
    fix x assume "x \<in> generator(a0)"
    then have "x \<in> A" "x \<le> a0" by (simp_all add: generator_mem)
    from \<open>x \<in> A\<close> have "x = a0 \<or> x = a1 \<or> x = a2" by (auto simp add: A_def)
    moreover have "\<not> a1 \<le> a0"
      unfolding a0_def a1_def by (simp add: not_le_iff_lt)
    moreover have "\<not> a2 \<le> a0"
      unfolding a0_def a2_def by (simp add: not_le_iff_lt)
    ultimately show "x \<in> {a0}" using \<open>x \<le> a0\<close> by auto
  qed
  show "{a0} \<subseteq> generator(a0)"
  proof (rule subsetI)
    fix x assume "x \<in> {a0}"
    then have x0: "x = a0" by simp
    have "a0 \<in> A" by (rule A_elems)
    moreover have "a0 \<le> a0" unfolding a0_def by simp
    ultimately have "a0 \<in> generator(a0)" by (simp add: generator_mem)
    with x0 show "x \<in> generator(a0)" by simp
  qed
qed

lemma generator_transitive:
  assumes "mu \<in> generator(ell)" and "x \<in> generator(mu)"
  shows "x \<in> generator(ell)"
proof -
  from assms have "mu \<in> A" "mu \<le> ell" "x \<in> A" "x \<le> mu"
    by (simp_all add: generator_mem)
  from \<open>x \<le> mu\<close> \<open>mu \<le> ell\<close> have "x \<le> ell" by (rule le_trans)
  with \<open>x \<in> A\<close> show ?thesis by (simp add: generator_mem)
qed

end
