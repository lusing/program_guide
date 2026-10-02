theory Test
  imports Main
begin

lemma trivial_add: "1 + (1::nat) = 2"
  by simp

lemma nd_demo: "\<lbrakk> P \<longrightarrow> Q; P \<rbrakk> \<Longrightarrow> Q"
  by (drule mp, assumption)

end
