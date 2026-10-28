theory Higherinfinity
  imports "ZF.Nat" "ZF.Trancl"
begin

text \<open>第 93 章：高阶无穷导引。用 0,1,2,3 编码 ZFC、可测、超紧、
超紧与武丁见证的联合假设。rtrancl 是带零步路径的自反传递闭包；
秩随每条边严格增加，所以不存在返回边。机器证明的是有限图性质，
不是任何集合论理论的相容性。\<close>

definition zfcN :: "i" where "zfcN \<equiv> 0"
definition measurableN :: "i" where "measurableN \<equiv> succ(0)"
definition supercompactN :: "i" where "supercompactN \<equiv> succ(succ(0))"
definition woodinWitnessN :: "i" where "woodinWitnessN \<equiv> succ(succ(succ(0)))"

definition guideEdge :: "i" where
  "guideEdge \<equiv> {\<langle>zfcN,measurableN\<rangle>, \<langle>measurableN,supercompactN\<rangle>,
                  \<langle>supercompactN,woodinWitnessN\<rangle>}"

definition reach :: "[i,i] => o" where
  "reach(a,b) \<equiv> \<langle>a,b\<rangle> \<in> guideEdge^*"

lemma guideEdge_lt: "\<langle>a,b\<rangle> \<in> guideEdge \<Longrightarrow> a < b"
  by (auto simp add: guideEdge_def zfcN_def measurableN_def supercompactN_def
    woodinWitnessN_def intro: ltI)

lemma reach_trans: "\<lbrakk>reach(a,b); reach(b,c)\<rbrakk> \<Longrightarrow> reach(a,c)"
  by (simp add: reach_def, rule rtrancl_trans, assumption+)

lemma reach_le: "a \<in> nat \<Longrightarrow> reach(a,b) \<Longrightarrow> a \<le> b"
  apply (simp add: reach_def)
  apply (erule rtrancl_induct)
   apply (simp add: le_refl nat_into_Ord)
  apply (rule leI)
  apply (rule lt_trans1, assumption)
  apply (rule guideEdge_lt, assumption)
done

lemma no_back:
  assumes e: "\<langle>a,b\<rangle> \<in> guideEdge" and r: "reach(b,a)" and bn: "b \<in> nat"
  shows False
proof -
  have ab: "a < b" by (rule guideEdge_lt [OF e])
  have ba: "b \<le> a" by (rule reach_le [OF bn r])
  have aa: "a < a" by (rule lt_trans2 [OF ab ba])
  show False by (rule lt_irrefl [OF aa])
qed

lemma guide_path: "reach(zfcN,woodinWitnessN)"
proof (unfold reach_def)
  have e01: "\<langle>zfcN,measurableN\<rangle> \<in> guideEdge" by (simp add: guideEdge_def)
  have e12: "\<langle>measurableN,supercompactN\<rangle> \<in> guideEdge" by (simp add: guideEdge_def)
  have e23: "\<langle>supercompactN,woodinWitnessN\<rangle> \<in> guideEdge" by (simp add: guideEdge_def)
  have p01: "\<langle>zfcN,measurableN\<rangle> \<in> guideEdge^*" by (rule r_into_rtrancl [OF e01])
  have p02: "\<langle>zfcN,supercompactN\<rangle> \<in> guideEdge^*" by (rule rtrancl_into_rtrancl [OF p01 e12])
  show "\<langle>zfcN,woodinWitnessN\<rangle> \<in> guideEdge^*" by (rule rtrancl_into_rtrancl [OF p02 e23])
qed

end
