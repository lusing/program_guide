theory Nssaturation
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 110 章：投影、核刻画与鸽笼（确定性规则链，沿 103-109 章纪律）。
投影 ProjI(X) = X - {0} 是光影原理 N \<mapsto> N\<inter>\<omega>1 的有限影子
（坐标 0 是被理想抹平的部分）。本体（定理 2.20-2.34 Mitchell-Magidor-
FMS-Woodin-冯-Jech）留在正文。\<close>

definition ProjI :: "i \<Rightarrow> i" where
  "ProjI(X) \<equiv> X - {0}"

text \<open>投影与交交换。\<close>

lemma proj_inter: "ProjI(A \<inter> B) = ProjI(A) \<inter> ProjI(B)"
proof (rule equalityI)
  show "ProjI(A \<inter> B) \<subseteq> ProjI(A) \<inter> ProjI(B)"
  proof (rule subsetI)
    fix x
    assume hx: "x \<in> ProjI(A \<inter> B)"
    then have h1: "x \<in> A \<inter> B" unfolding ProjI_def by (rule DiffD1)
    from hx have hn: "x \<notin> {0}" unfolding ProjI_def by (rule DiffD2)
    from h1 have hA: "x \<in> A" by (rule IntD1)
    from h1 have hB: "x \<in> B" by (rule IntD2)
    show "x \<in> ProjI(A) \<inter> ProjI(B)"
    proof (rule IntI)
      from hA hn show "x \<in> ProjI(A)" unfolding ProjI_def by (rule DiffI)
    next
      from hB hn show "x \<in> ProjI(B)" unfolding ProjI_def by (rule DiffI)
    qed
  qed
next
  show "ProjI(A) \<inter> ProjI(B) \<subseteq> ProjI(A \<inter> B)"
  proof (rule subsetI)
    fix x
    assume hx: "x \<in> ProjI(A) \<inter> ProjI(B)"
    from hx have hA: "x \<in> ProjI(A)" by (rule IntD1)
    from hx have hB: "x \<in> ProjI(B)" by (rule IntD2)
    from hA have hA1: "x \<in> A" unfolding ProjI_def by (rule DiffD1)
    from hA have hn: "x \<notin> {0}" unfolding ProjI_def by (rule DiffD2)
    from hB have hB1: "x \<in> B" unfolding ProjI_def by (rule DiffD1)
    show "x \<in> ProjI(A \<inter> B)" unfolding ProjI_def
    proof (rule DiffI)
      from hA1 hB1 show "x \<in> A \<inter> B" by (rule IntI)
    next
      from hn show "x \<notin> {0}" .
    qed
  qed
qed

text \<open>核刻画：理想 {0, {0}} 的元素投影为空。\<close>

lemma kernel: assumes hC: "C \<in> {0, {0}}" shows "ProjI(C) = 0"
proof -
  from hC have hdisj: "C = 0 \<or> C = {0}" by simp
  from hdisj show ?thesis
  proof (rule disjE)
    assume h0: "C = 0"
    from h0 show ?thesis unfolding ProjI_def by simp
  next
    assume h1: "C = {0}"
    show ?thesis unfolding ProjI_def
    proof (rule trans)
      from h1 show "C - {0} = {0} - {0}" by simp
    next
      show "{0} - {0} = 0" by (rule Diff_cancel)
    qed
  qed
qed

text \<open>模 I 不相容（交在理想中）⟹ 投影不交。\<close>

lemma incompat_proj: assumes hAB: "A \<inter> B \<in> {0, {0}}"
  shows "ProjI(A) \<inter> ProjI(B) = 0"
proof -
  have h1: "ProjI(A) \<inter> ProjI(B) = ProjI(A \<inter> B)" by (rule sym [OF proj_inter])
  have h2: "ProjI(A \<inter> B) = 0" by (rule kernel [OF hAB])
  from h1 h2 show ?thesis by (rule trans)
qed

text \<open>鸽笼：{1, 2} 中任取三元必有两者相等——
饱和界（反链至多 2）的组合内核。\<close>

lemma pigeon3: assumes ha: "a \<in> {1, 2}" and hb: "b \<in> {1, 2}" and hc: "c \<in> {1, 2}"
  shows "a = b \<or> a = c \<or> b = c"
proof -
  from ha have hA: "a = 1 \<or> a = 2" by simp
  from hb have hB: "b = 1 \<or> b = 2" by simp
  from hc have hC: "c = 1 \<or> c = 2" by simp
  from hA show ?thesis
  proof (rule disjE)
    assume a1: "a = 1"
    from hB show ?thesis
    proof (rule disjE)
      assume b1: "b = 1"
      from a1 b1 show ?thesis by simp
    next
      assume b2: "b = 2"
      from hC show ?thesis
      proof (rule disjE)
        assume c1: "c = 1"
        from a1 c1 show ?thesis by simp
      next
        assume c2: "c = 2"
        from b2 c2 show ?thesis by simp
      qed
    qed
  next
    assume a2: "a = 2"
    from hB show ?thesis
    proof (rule disjE)
      assume b1: "b = 1"
      from hC show ?thesis
      proof (rule disjE)
        assume c1: "c = 1"
        from b1 c1 show ?thesis by simp
      next
        assume c2: "c = 2"
        from a2 c2 show ?thesis by simp
      qed
    next
      assume b2: "b = 2"
      from a2 b2 show ?thesis by simp
    qed
  qed
qed

text \<open>提升：楼下集合（Y \<subseteq> {1,2}）是自己的原像——
0 不在 Y 中，抹 0 不动 Y。\<close>

lemma subset_lift: assumes hY: "Y \<subseteq> {1, 2}" shows "Y - {0} = Y"
proof (rule Diff_triv)
  show "Y \<inter> {0} = 0"
  proof (rule equalityI)
    show "Y \<inter> {0} \<subseteq> 0"
    proof (rule subsetI)
      fix y
      assume hy: "y \<in> Y \<inter> {0}"
      then have hyY: "y \<in> Y" by (rule IntD1)
      then have hy12: "y \<in> {1, 2}" by (rule subsetD [OF hY])
      from hy have hy0: "y \<in> {0}" by (rule IntD2)
      from hy12 have "y = 1 \<or> y = 2" by simp
      then show "y \<in> 0"
      proof (rule disjE)
        assume h1: "y = 1"
        from hy0 have "y = 0" by simp
        with h1 show "y \<in> 0" by simp
      next
        assume h2: "y = 2"
        from hy0 have "y = 0" by simp
        with h2 show "y \<in> 0" by simp
      qed
    qed
  next
    show "0 \<subseteq> Y \<inter> {0}" by (rule empty_subsetI)
  qed
qed

end
