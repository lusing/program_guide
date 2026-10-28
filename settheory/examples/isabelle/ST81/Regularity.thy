theory Regularity
  imports "ZF.Nat"
begin

text \<open>第 81 章：两点幂集上的一个理想，以及模二余类关系。
这些有限对象只核对理想封闭和商关系，不模拟实数的 σ-理想。\<close>

definition K2 :: "i" where "K2 \<equiv> succ(succ(0))"
definition O3 :: "i" where "O3 \<equiv> succ(2)"
definition K4 :: "i" where "K4 \<equiv> succ(O3)"
definition I2 :: "i" where "I2 \<equiv> Pow(K2)"
definition Mod2 :: "i" where
  "Mod2 \<equiv> {\<langle>0,0\<rangle>, \<langle>0,2\<rangle>, \<langle>2,0\<rangle>, \<langle>2,2\<rangle>,
             \<langle>1,1\<rangle>, \<langle>1,O3\<rangle>, \<langle>O3,1\<rangle>, \<langle>O3,O3\<rangle>}"

lemma I2_empty: "0 \<in> I2"
  by (simp add: I2_def)

lemma I2_downward: "A \<in> I2 \<Longrightarrow> B \<subseteq> A \<Longrightarrow> B \<in> I2"
  by (auto simp add: I2_def K2_def)

lemma I2_union: "A \<in> I2 \<Longrightarrow> B \<in> I2 \<Longrightarrow> A \<union> B \<in> I2"
  by (auto simp add: I2_def K2_def)

lemma Mod2_refl: "x \<in> K4 \<Longrightarrow> \<langle>x,x\<rangle> \<in> Mod2"
  by (auto simp add: Mod2_def K4_def O3_def)

lemma Mod2_sym: "\<langle>x,y\<rangle> \<in> Mod2 \<Longrightarrow> \<langle>y,x\<rangle> \<in> Mod2"
  by (auto simp add: Mod2_def)

lemma Mod2_trans: "\<langle>x,y\<rangle> \<in> Mod2 \<Longrightarrow> \<langle>y,z\<rangle> \<in> Mod2 \<Longrightarrow> \<langle>x,z\<rangle> \<in> Mod2"
  by (auto simp add: Mod2_def O3_def)

end
