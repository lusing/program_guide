theory Pfa
  imports "ZF.Nat" "ZF.Ordinal" "ZF.equalities"
begin

text \<open>第 108 章：可数支撑迭代的集论核（确定性规则链，沿 103-107 章纪律）。
条件 = nat 上的坐标函数（0 = 平凡坐标）；支撑 = 非平凡坐标集。
本体（引理 2.27/定理 2.15、定义 2.22 PFA、定理 2.16/2.17、
引理 2.28 的拉弗提升）留在正文。\<close>

definition SuppQ :: "i \<Rightarrow> i" where
  "SuppQ(f) \<equiv> {i\<in>nat. f`i \<noteq> 0}"

text \<open>限制：q \<upharpoonright> k（前 k 个坐标保留，其余置平凡）。\<close>

definition RestrictQ :: "[i, i] \<Rightarrow> i" where
  "RestrictQ(k, f) \<equiv> \<lambda>i\<in>nat. if i < k then f`i else 0"

text \<open>拼接：前 k 个坐标取 f，其余取 g（引理 2.27 极限步的
递归构造在有限步的替身）。\<close>

definition GlueQ :: "[i, i, i] \<Rightarrow> i" where
  "GlueQ(f, g, k) \<equiv> \<lambda>i\<in>nat. if i < k then f`i else g`i"

text \<open>分支方程（四个，全部零搜索）。\<close>

lemma restrict_less:
  assumes hin: "i \<in> nat" and hik: "i < k"
  shows "RestrictQ(k, f) ` i = f ` i"
  unfolding RestrictQ_def using hin hik by simp

lemma restrict_ge:
  assumes hin: "i \<in> nat" and hik: "\<not> (i < k)"
  shows "RestrictQ(k, f) ` i = 0"
  unfolding RestrictQ_def using hin hik by simp

lemma glue_less:
  assumes hin: "i \<in> nat" and hik: "i < k"
  shows "GlueQ(f, g, k) ` i = f ` i"
  unfolding GlueQ_def using hin hik by simp

lemma glue_ge:
  assumes hin: "i \<in> nat" and hik: "\<not> (i < k)"
  shows "GlueQ(f, g, k) ` i = g ` i"
  unfolding GlueQ_def using hin hik by simp

text \<open>限制只缩不小支撑。\<close>

lemma restrict_supp:
  assumes hkn: "k \<in> nat"
  shows "SuppQ(RestrictQ(k, f)) \<subseteq> SuppQ(f)"
proof (rule subsetI)
  fix i
  assume hi: "i \<in> SuppQ(RestrictQ(k, f))"
  hence hin: "i \<in> nat" unfolding SuppQ_def by (rule CollectD1)
  from hi have hneq: "RestrictQ(k, f) ` i \<noteq> 0" unfolding SuppQ_def by (rule CollectD2)
  show "i \<in> SuppQ(f)"
  proof (rule Ord_linear_lt [OF nat_into_Ord [OF hin] nat_into_Ord [OF hkn]])
    assume hik: "i < k"
    from hneq restrict_less [OF hin hik] have hf0: "f ` i \<noteq> 0" by simp
    from hin hf0 show ?thesis unfolding SuppQ_def by (rule CollectI)
  next
    assume heq: "i = k"
    have hnf: "\<not> (i < k)"
    proof (rule notI)
      assume hik: "i < k"
      from hik heq have "k < k" by simp
      thus False by (rule lt_irrefl)
    qed
    from hneq restrict_ge [OF hin hnf] have hz: "0 \<noteq> 0" by simp
    from hz show ?thesis by (rule notE) (rule refl)
  next
    assume hki: "k < i"
    have hnf: "\<not> (i < k)"
    proof (rule notI)
      assume hik: "i < k"
      from hik hki have "i < i" by (rule lt_trans)
      thus False by (rule lt_irrefl)
    qed
    from hneq restrict_ge [OF hin hnf] have hz: "0 \<noteq> 0" by simp
    from hz show ?thesis by (rule notE) (rule refl)
  qed
qed

text \<open>拼接的支撑含于两段支撑之并（支撑并集仍有限——
可数支撑迭代在极限步的支撑账）。\<close>

lemma glue_supp:
  assumes hkn: "k \<in> nat"
  shows "SuppQ(GlueQ(f, g, k)) \<subseteq> SuppQ(f) \<union> SuppQ(g)"
proof (rule subsetI)
  fix i
  assume hi: "i \<in> SuppQ(GlueQ(f, g, k))"
  hence hin: "i \<in> nat" unfolding SuppQ_def by (rule CollectD1)
  from hi have hneq: "GlueQ(f, g, k) ` i \<noteq> 0" unfolding SuppQ_def by (rule CollectD2)
  show "i \<in> SuppQ(f) \<union> SuppQ(g)"
  proof (rule Ord_linear_lt [OF nat_into_Ord [OF hin] nat_into_Ord [OF hkn]])
    assume hik: "i < k"
    from hneq glue_less [OF hin hik] have hf0: "f ` i \<noteq> 0" by simp
    from hin hf0 have hsf: "i \<in> SuppQ(f)" unfolding SuppQ_def by (rule CollectI)
    show ?thesis by (rule UnI1 [OF hsf])
  next
    assume heq: "i = k"
    have hnf: "\<not> (i < k)"
    proof (rule notI)
      assume hik: "i < k"
      from hik heq have "k < k" by simp
      thus False by (rule lt_irrefl)
    qed
    from hneq glue_ge [OF hin hnf] have hg0: "g ` i \<noteq> 0" by simp
    from hin hg0 have hsg: "i \<in> SuppQ(g)" unfolding SuppQ_def by (rule CollectI)
    show ?thesis by (rule UnI2 [OF hsg])
  next
    assume hki: "k < i"
    have hnf: "\<not> (i < k)"
    proof (rule notI)
      assume hik: "i < k"
      from hik hki have "i < i" by (rule lt_trans)
      thus False by (rule lt_irrefl)
    qed
    from hneq glue_ge [OF hin hnf] have hg0: "g ` i \<noteq> 0" by simp
    from hin hg0 have hsg: "i \<in> SuppQ(g)" unfolding SuppQ_def by (rule CollectI)
    show ?thesis by (rule UnI2 [OF hsg])
  qed
qed

text \<open>拼接协调（点态形式）：Restrict(k, Glue(f,g,k)) 与
Restrict(k,f) 逐点相等——引理 2.27 的协调条款
q_{n+1} \<upharpoonright> \<alpha>_n = q_n。\<close>

lemma restrict_glue_coherent:
  assumes hkn: "k \<in> nat" and hin: "i \<in> nat"
  shows "RestrictQ(k, GlueQ(f, g, k)) ` i = RestrictQ(k, f) ` i"
proof (rule Ord_linear_lt [OF nat_into_Ord [OF hin] nat_into_Ord [OF hkn]])
  assume hik: "i < k"
  have h1a: "RestrictQ(k, GlueQ(f, g, k)) ` i = GlueQ(f, g, k) ` i"
    by (rule restrict_less [OF hin hik])
  have h1b: "GlueQ(f, g, k) ` i = f ` i"
    by (rule glue_less [OF hin hik])
  from h1a h1b have h1: "RestrictQ(k, GlueQ(f, g, k)) ` i = f ` i" by simp
  have h2: "RestrictQ(k, f) ` i = f ` i"
    by (rule restrict_less [OF hin hik])
  from h1 h2 show ?thesis by simp
next
  assume heq: "i = k"
  have hnf: "\<not> (i < k)"
  proof (rule notI)
    assume hik: "i < k"
    from hik heq have "k < k" by simp
    thus False by (rule lt_irrefl)
  qed
  have h1: "RestrictQ(k, GlueQ(f, g, k)) ` i = 0"
    by (rule restrict_ge [OF hin hnf])
  have h2: "RestrictQ(k, f) ` i = 0"
    by (rule restrict_ge [OF hin hnf])
  from h1 h2 show ?thesis by simp
next
  assume hki: "k < i"
  have hnf: "\<not> (i < k)"
  proof (rule notI)
    assume hik: "i < k"
    from hik hki have "i < i" by (rule lt_trans)
    thus False by (rule lt_irrefl)
  qed
  have h1: "RestrictQ(k, GlueQ(f, g, k)) ` i = 0"
    by (rule restrict_ge [OF hin hnf])
  have h2: "RestrictQ(k, f) ` i = 0"
    by (rule restrict_ge [OF hin hnf])
  from h1 h2 show ?thesis by simp
qed

end
