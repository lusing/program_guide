theory Itertree2 imports "ZF.List" "ZF.equalities" begin

text \<open>第 119 章：六步目标选择策略与有限终止证书。\<close>
definition N1 where "N1 \<equiv> 1"
definition N2 where "N2 \<equiv> 2"
definition N3 where "N3 \<equiv> succ(2)"
definition N4 where "N4 \<equiv> succ(N3)"
definition N5 where "N5 \<equiv> succ(N4)"
definition N6 where "N6 \<equiv> succ(N5)"

definition cStrategy where
  "cStrategy(k) \<equiv> (if k = 0 then 0 else if k = 1 then 0 else
    if k = 2 then 1 else if k = N3 then 2 else
    if k = N4 then N3 else N4)"

definition LegalTarget where
  "LegalTarget(k,p) \<equiv> p \<le> k \<and> p = cStrategy(k)"

definition scheduled where
  "scheduled \<equiv> [cStrategy(0),cStrategy(1),cStrategy(2),
    cStrategy(N3),cStrategy(N4),cStrategy(N5)]"

definition Finished where "Finished(k) \<equiv> k = N6"

lemma scheduled_targets:
  "scheduled = [0,0,1,2,N3,N4]"
  by (simp add: scheduled_def cStrategy_def N3_def N4_def N5_def)

lemma comparison_terminates:
  "length(scheduled) = N6 \<and> Finished(N6)"
  by (simp add: scheduled_targets Finished_def N6_def N5_def N4_def N3_def)

lemma legal_e0: "LegalTarget(0,cStrategy(0))"
  by (simp add: LegalTarget_def cStrategy_def)
lemma legal_e1: "LegalTarget(1,cStrategy(1))"
  by (simp add: LegalTarget_def cStrategy_def N1_def)
lemma legal_e2: "LegalTarget(2,cStrategy(2))"
  by (simp add: LegalTarget_def cStrategy_def N2_def)
lemma legal_e3: "LegalTarget(N3,cStrategy(N3))"
  by (simp add: LegalTarget_def cStrategy_def N3_def)
lemma legal_e4: "LegalTarget(N4,cStrategy(N4))"
  by (simp add: LegalTarget_def cStrategy_def N3_def N4_def)
lemma legal_e5: "LegalTarget(N5,cStrategy(N5))"
  by (simp add: LegalTarget_def cStrategy_def N3_def N4_def N5_def)

end
