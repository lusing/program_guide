theory Itertree1 imports "ZF.List" "ZF.equalities" begin

text \<open>第 118 章：六节点边的有限交错树。自然数仅是节点和数值标签。\<close>
definition N0 where "N0 \<equiv> 0"
definition N1 where "N1 \<equiv> 1"
definition N2 where "N2 \<equiv> 2"
definition N3 where "N3 \<equiv> succ(2)"
definition N4 where "N4 \<equiv> succ(N3)"
definition N5 where "N5 \<equiv> succ(N4)"
definition N6 where "N6 \<equiv> succ(N5)"

definition parent where
  "parent(x) \<equiv> (if x = N0 then N0 else if x = N1 then N0 else
    if x = N2 then N0 else if x = N3 then N1 else
    if x = N4 then N2 else if x = N5 then N3 else N4)"

definition child where
  "child(e) \<equiv> succ(e)"
definition source where
  "source(e) \<equiv> e"
definition target where
  "target(e) \<equiv> (if e = 0 then N0 else
    if e = 1 then N0 else if e = 2 then N1 else
    if e = N3 then N2 else if e = N4 then N3 else N4)"
definition LegalApplication where
  "LegalApplication(e) \<equiv> parent(child(e)) = target(e)"

lemma legal_e0: "LegalApplication(0)"
  by (simp add: LegalApplication_def child_def parent_def target_def N0_def N1_def)
lemma legal_e1: "LegalApplication(1)"
  by (simp add: LegalApplication_def child_def parent_def target_def N0_def N1_def N2_def)
lemma legal_e2: "LegalApplication(2)"
  by (simp add: LegalApplication_def child_def parent_def target_def N0_def N1_def N2_def N3_def)
lemma legal_e3: "LegalApplication(N3)"
  by (simp add: LegalApplication_def child_def parent_def target_def N0_def N1_def N2_def N3_def N4_def)
lemma legal_e4: "LegalApplication(N4)"
  by (simp add: LegalApplication_def child_def parent_def target_def N0_def N1_def N2_def N3_def N4_def N5_def)
lemma legal_e5: "LegalApplication(N5)"
  by (simp add: LegalApplication_def child_def parent_def target_def N0_def N1_def N2_def N3_def N4_def N5_def N6_def)

lemma external_e1: "source(1) = N1 \<and> target(1) = N0"
  by (simp add: source_def target_def N0_def N1_def)
lemma cross_branch: "parent(N3) = N1 \<and> parent(N4) = N2"
  by (simp add: parent_def N0_def N1_def N2_def N3_def N4_def)

definition crit where "crit(e) \<equiv> succ(e)"
definition strength where "strength(e) \<equiv> succ(crit(e))"
definition toyEmbed where
  "toyEmbed(e,x) \<equiv> (if x < crit(e) then x else succ(x))"
lemma toy_below: "toyEmbed(2,1) = 1"
  by (simp add: toyEmbed_def crit_def)
lemma toy_moves: "toyEmbed(2,N3) = N4"
  by (simp add: toyEmbed_def crit_def N3_def N4_def)

end
