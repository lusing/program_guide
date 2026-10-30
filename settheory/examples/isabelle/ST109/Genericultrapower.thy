theory Genericultrapower
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 109 章：理想力迫的序与商关系（确定性规则链，沿 103-108 章纪律）。
理想以集合族 I 给出（含 0、向下闭、二元并闭）；正测 = 不在 I 中。
本体（定义 2.23-2.26、引理 2.29/2.30、定理 2.18/2.19、例 2.2-2.4）留在正文。\<close>

definition ForcesP :: "[i, i, i] \<Rightarrow> o" where
  "ForcesP(I, C, D) \<equiv> C - D \<in> I"

text \<open>自反：C - C = 0。\<close>

lemma forces_refl:
  assumes h0: "0 \<in> I"
  shows "ForcesP(I, C, C)"
  unfolding ForcesP_def using h0 by (simp add: Diff_cancel)

text \<open>传递（理想公理形态）：C - D \<in> I、D - E \<in> I、
并闭、向下闭 ⟹ C - E \<in> I——关键包含
C - E \<subseteq> (C - D) \<union> (D - E)。\<close>

lemma forces_trans_raw:
  assumes hun: "\<forall>X\<in>I. \<forall>Y\<in>I. X \<union> Y \<in> I"
    and hdown: "\<forall>X\<in>I. \<forall>Y. Y \<subseteq> X \<longrightarrow> Y \<in> I"
    and h1: "C - D \<in> I" and h2: "D - E \<in> I"
  shows "C - E \<in> I"
proof -
  from hun h1 have hall: "\<forall>Y\<in>I. (C - D) \<union> Y \<in> I" by (rule bspec)
  from hall h2 have hunion: "(C - D) \<union> (D - E) \<in> I" by (rule bspec)
  from hdown hunion have hdownall: "\<forall>Y. Y \<subseteq> (C - D) \<union> (D - E) \<longrightarrow> Y \<in> I"
    by (rule bspec)
  from hdownall have hmp: "C - E \<subseteq> (C - D) \<union> (D - E) \<longrightarrow> C - E \<in> I"
    by (rule spec)
  have hsub: "C - E \<subseteq> (C - D) \<union> (D - E)"
  proof (rule subsetI)
    fix x
    assume hx: "x \<in> C - E"
    then have hxC: "x \<in> C" by (rule DiffD1)
    from hx have hxne: "x \<notin> E" by (rule DiffD2)
    show "x \<in> (C - D) \<union> (D - E)"
    proof (rule disjE [OF excluded_middle])
      assume hxD: "x \<in> D"
      from hxD hxne have "x \<in> D - E" by (rule DiffI)
      thus "x \<in> (C - D) \<union> (D - E)" by (rule UnI2)
    next
      assume hxnd: "x \<notin> D"
      from hxC hxnd have "x \<in> C - D" by (rule DiffI)
      thus "x \<in> (C - D) \<union> (D - E)" by (rule UnI1)
    qed
  qed
  from hmp hsub show ?thesis by (rule mp)
qed

text \<open>商关系：X \<equiv> Y（mod I）⟺ X\<triangle>Y \<in> I（对称差 = 双向差的并）。\<close>

definition SymDiffI :: "[i, i] \<Rightarrow> i" where
  "SymDiffI(X, Y) \<equiv> (X - Y) \<union> (Y - X)"

definition EqvP :: "[i, i, i] \<Rightarrow> o" where
  "EqvP(I, X, Y) \<equiv> SymDiffI(X, Y) \<in> I"

lemma eqv_refl:
  assumes h0: "0 \<in> I"
  shows "EqvP(I, X, X)"
  unfolding EqvP_def SymDiffI_def using h0 by (simp add: Diff_cancel)

end
