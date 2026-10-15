theory Prop
  imports "ZF.EquivClass"
begin

text \<open>第 63 章：命题逻辑（Makinson Ch8）。二值函数的布尔代数骨架：
De Morgan 双律与双重否定的谓词级验证。\<close>

definition meetB :: "[i,i] \<Rightarrow> i" where
  "meetB(x,y) \<equiv> if x = 0 then 0 else if y = 0 then 0 else 1"

definition joinB :: "[i,i] \<Rightarrow> i" where
  "joinB(x,y) \<equiv> if x = 1 then 1 else if y = 1 then 1 else 0"

definition negB :: "i \<Rightarrow> i" where
  "negB(x) \<equiv> if x = 0 then 1 else 0"

lemma negB_invol:
  "negB(negB(0)) = 0"
  "negB(negB(1)) = 1"
  unfolding negB_def by simp_all

lemma demorgan_join_00:
  "negB(meetB(0,0)) = joinB(negB(0), negB(0))"
  unfolding meetB_def joinB_def negB_def by simp

lemma demorgan_join_01:
  "negB(meetB(0,1)) = joinB(negB(0), negB(1))"
  unfolding meetB_def joinB_def negB_def by simp

lemma demorgan_join_10:
  "negB(meetB(1,0)) = joinB(negB(1), negB(0))"
  unfolding meetB_def joinB_def negB_def by simp

lemma demorgan_join_11:
  "negB(meetB(1,1)) = joinB(negB(1), negB(1))"
  unfolding meetB_def joinB_def negB_def by simp

text \<open>四行全验 = De Morgan 律的完整真值表机器版。\<close>

lemma demorgan_meet_00:
  "negB(joinB(0,0)) = meetB(negB(0), negB(0))"
  unfolding meetB_def joinB_def negB_def by simp

lemma demorgan_meet_01:
  "negB(joinB(0,1)) = meetB(negB(0), negB(1))"
  unfolding meetB_def joinB_def negB_def by simp

lemma demorgan_meet_10:
  "negB(joinB(1,0)) = meetB(negB(1), negB(0))"
  unfolding meetB_def joinB_def negB_def by simp

lemma demorgan_meet_11:
  "negB(joinB(1,1)) = meetB(negB(1), negB(1))"
  unfolding meetB_def joinB_def negB_def by simp

end
