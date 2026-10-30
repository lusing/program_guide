theory Projective
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 111 章：良基关系的无下降链判定（确定性规则链，沿 103-110 章纪律）。
这是引理 3.4 的核心：α 记录有秩关系 ⟺ 不存在下降链
f: nat → field 使 (f(n+1), f(n)) ∈ E_α——WF 的对偶刻画。
本体（定义 3.1-3.6、引理 3.1-3.7、定理 3.1-3.6）留在正文。\<close>

text \<open>hmin 是 wf_on 的 B-刻画（ZF 的 wf_on_def2）：每个非空子集有极小元。\<close>

lemma minimal_no_descending:
  assumes hmin: "\<forall>B. B \<subseteq> A \<and> B \<noteq> 0 \<longrightarrow>
      (\<exists>x\<in>B. \<forall>y. <y, x> \<in> r \<longrightarrow> y \<notin> B)"
    and hf: "f \<in> nat -> A"
    and hchain: "\<forall>n \<in> nat. <f ` succ(n), f ` n> \<in> r"
  shows "False"
proof -
  let ?B = "Replace(nat, \<lambda>n y. y = f ` n)"
  have hsub: "?B \<subseteq> A"
  proof (rule subsetI)
    fix y
    assume hy: "y \<in> ?B"
    then obtain n where hn: "n \<in> nat" and hye: "y = f ` n"
      by (rule ReplaceE)
    from hf hn have "f ` n \<in> A" by (rule apply_type)
    with hye show "y \<in> A" by simp
  qed
  have hne: "?B \<noteq> 0"
  proof (rule notI)
    assume h0: "?B = 0"
    have hf0: "f ` 0 \<in> ?B"
    proof (rule ReplaceI [of _ 0])
      show "0 \<in> nat" by (rule nat_0I)
    next
      show "f ` 0 = f ` 0" by (rule refl)
    qed
    from h0 hf0 have "f ` 0 \<in> 0" by simp
    then show "False" by (rule emptyE)
  qed
  from hmin have hinst: "?B \<subseteq> A \<and> ?B \<noteq> 0 \<longrightarrow>
      (\<exists>x\<in>?B. \<forall>y. <y, x> \<in> r \<longrightarrow> y \<notin> ?B)"
    by (rule spec)
  from hinst hsub hne obtain x where
    hx: "x \<in> ?B" and hmin0: "\<forall>y. <y, x> \<in> r \<longrightarrow> y \<notin> ?B"
    by auto
  from hx obtain k where hk: "k \<in> nat" and hxe: "x = f ` k"
    by (rule ReplaceE)
  from hchain hk have hstep: "<f ` succ(k), f ` k> \<in> r" by (rule bspec)
  from hxe have hfk: "f ` k = x" by simp
  from hfk hstep have hstepx: "<f ` succ(k), x> \<in> r" by simp
  from hmin0 have hinst2: "<f ` succ(k), x> \<in> r \<longrightarrow> f ` succ(k) \<notin> ?B"
    by (rule spec [where x = "f ` succ(k)"])
  from hinst2 hstepx have hnot: "f ` succ(k) \<notin> ?B" by (rule mp)
  have hmem: "f ` succ(k) \<in> ?B"
  proof (rule ReplaceI [of _ "succ(k)"])
    from hk show "succ(k) \<in> nat" by (rule nat_succ_iff [THEN iffD2])
  next
    show "f ` succ(k) = f ` succ(k)" by (rule refl)
  qed
  from hnot hmem show "False" by (rule notE)
qed

end
