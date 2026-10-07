(* ex21 —— 可判定性与 SMT（Isabelle/HOL 版：现场） *)
theory ex33_decidability
  imports Main
begin

lemma prop_decidable_demo:
  "(P \<or> Q) \<and> (\<not> P \<or> R) \<and> (\<not> Q \<or> R) \<longrightarrow> R"
  by blast

lemma presburger_demo:
  "\<forall>x::int. \<exists>y. 2 * y \<le> x \<and> x < 2 * y + 2"
  by presburger

lemma presburger_mod:
  "\<forall>x::int. x mod 2 = 0 \<or> x mod 2 = 1"
  by presburger

end
