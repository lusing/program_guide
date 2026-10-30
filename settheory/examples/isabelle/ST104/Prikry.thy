theory Prikry
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 104 章：Prikry 条件的纯延长序与事实 2.3.1 的集论核。
证明全用确定性规则链（沿第 103 章 THE-fst 教训，不用 blast/auto）。
判定引理（引理 2.4/2.5）与定理 2.6/2.7/2.8 留在正文。\<close>

text \<open>纯延长：不动 stem，只收窄测度一集。以序对 \<langle>s, A\<rangle> 表示条件。\<close>

definition pleP :: "[i, i] \<Rightarrow> o" where
  "pleP(p, q) \<equiv> fst(p) = fst(q) \<and> snd(p) \<subseteq> snd(q)"

lemma pleP_refl: "pleP(p, p)"
  unfolding pleP_def by (rule conjI, rule refl, rule subset_refl)

lemma pleP_trans:
  assumes h1: "pleP(p, q)" and h2: "pleP(q, r)"
  shows "pleP(p, r)"
proof -
  from h1 have e1: "fst(p) = fst(q)" and s1: "snd(p) \<subseteq> snd(q)"
    unfolding pleP_def by (rule conjunct1, rule conjunct2)
  from h2 have e2: "fst(q) = fst(r)" and s2: "snd(q) \<subseteq> snd(r)"
    unfolding pleP_def by (rule conjunct1, rule conjunct2)
  have e: "fst(p) = fst(r)"
    by (rule trans [OF e1 e2])
  have s: "snd(p) \<subseteq> snd(r)"
    by (rule subset_trans [OF s1 s2])
  show ?thesis unfolding pleP_def by (rule conjI, rule e, rule s)
qed

text \<open>序对投影的显式计算。\<close>

lemma fst_pair_same: "fst(\<langle>s, X\<rangle>) = s"
  by simp

lemma snd_pair_same: "snd(\<langle>X, A\<rangle>) = A"
  by simp

text \<open>事实 2.3.1（前半）：交条件同时纯延长两侧。\<close>

lemma fact231:
  "pleP(\<langle>s, A \<inter> B\<rangle>, \<langle>s, A\<rangle>) \<and> pleP(\<langle>s, A \<inter> B\<rangle>, \<langle>s, B\<rangle>)"
proof (rule conjI)
  show "pleP(\<langle>s, A \<inter> B\<rangle>, \<langle>s, A\<rangle>)"
    unfolding pleP_def
  proof (rule conjI)
    show "fst(\<langle>s, A \<inter> B\<rangle>) = fst(\<langle>s, A\<rangle>)"
      by (simp only: fst_pair_same)
  next
    show "snd(\<langle>s, A \<inter> B\<rangle>) \<subseteq> snd(\<langle>s, A\<rangle>)"
      by (simp only: snd_pair_same, rule Int_lower1)
  qed
next
  show "pleP(\<langle>s, A \<inter> B\<rangle>, \<langle>s, B\<rangle>)"
    unfolding pleP_def
  proof (rule conjI)
    show "fst(\<langle>s, A \<inter> B\<rangle>) = fst(\<langle>s, B\<rangle>)"
      by (simp only: fst_pair_same)
  next
    show "snd(\<langle>s, A \<inter> B\<rangle>) \<subseteq> snd(\<langle>s, B\<rangle>)"
      by (simp only: snd_pair_same, rule Int_lower2)
  qed
qed

text \<open>Prikry 序列的尾核性质（Mathias 定理 2.7 影子）：
若 X 的 m-尾段全部落入 A，则 X - A ⊆ m（余集有前段界）。\<close>

lemma tail_core_diff:
  assumes tail: "\<forall>n \<in> X - m. n \<in> A"
  shows "X - A \<subseteq> m"
proof
  fix x
  assume hx: "x \<in> X - A"
  from hx have hxx: "x \<in> X" by (rule DiffD1)
  from hx have hna: "x \<notin> A" by (rule DiffD2)
  show "x \<in> m"
  proof (rule classical)
    assume contr: "x \<notin> m"
    from hxx contr have hxm: "x \<in> X - m" by (rule DiffI)
    from tail hxm have "x \<in> A" by (rule bspec)
    with hna show "x \<in> m" by (rule notE)
  qed
qed

end
