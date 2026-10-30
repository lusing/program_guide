theory Silver
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 105 章：Silver 条件（有限部分函数）的偏序律与定向下界
（引理 2.6 大拿/master condition 影子）。确定性规则链，不用 blast/auto。
Easton 支撑迭代与定理 2.10 留在正文。\<close>

text \<open>反向包含序：q \<le> p \<equiv> p \<subseteq> q（条件层，以集合表示部分函数的图）。\<close>

definition extP :: "[i, i] \<Rightarrow> o" where
  "extP(p, q) \<equiv> p \<subseteq> q"

lemma extP_refl: "extP(p, p)"
  unfolding extP_def by (rule subset_refl)

lemma extP_trans:
  assumes h1: "extP(p, q)" and h2: "extP(q, r)"
  shows "extP(p, r)"
proof -
  from h1 have s1: "p \<subseteq> q" unfolding extP_def .
  from h2 have s2: "q \<subseteq> r" unfolding extP_def .
  from s1 s2 have s: "p \<subseteq> r" by (rule subset_trans)
  show ?thesis unfolding extP_def by (rule s)
qed

text \<open>两两相容族的并是公共下界（定向完全性的最小情形）。\<close>

lemma union_lower_left:
  assumes sub: "\<forall>d\<in>D. d \<subseteq> A"
  shows "\<forall>d\<in>D. extP(d, A)"
proof
  fix d
  assume hd: "d \<in> D"
  from sub hd have hsub: "d \<subseteq> A" by (rule bspec)
  show "extP(d, A)" unfolding extP_def by (rule hsub)
qed

text \<open>定向族的并：D 定向且 D 的元素两两有公共延展（以 A 为上界）
则 A 是 D 的下界——引理 2.6(a) 的两条件版本。\<close>

lemma directed_bound:
  assumes dir: "\<forall>d1\<in>D. \<forall>d2\<in>D. d1 \<union> d2 \<in> D"
    and cup: "\<Union>D = A"
  shows "\<forall>d\<in>D. extP(d, A)"
proof
  fix d
  assume hd: "d \<in> D"
  have hsub: "d \<subseteq> \<Union>D"
  proof
    fix x
    assume hx: "x \<in> d"
    from hd have hmem: "d \<in> D" .
    show "x \<in> \<Union>D"
    proof (rule UnionI [of d D])
      show "x \<in> d" by (rule hx)
    qed (rule hmem)
  qed
  from cup have hDA: "\<Union>D \<subseteq> A" by (rule equalityD1)
  from hsub hDA show "extP(d, A)" unfolding extP_def
    by (rule subset_trans)
qed

end
