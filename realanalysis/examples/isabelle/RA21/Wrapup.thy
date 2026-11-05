theory Wrapup
  imports "HOL-Analysis.Analysis"
begin

(* 第 21 章 收官：Isabelle 通道。
   三个三分之一、超过 5 的自然数、两半拼回、公比 1/2 的和。 *)

lemma thirds: "(1::real) / 3 + 1 / 3 + 1 / 3 = 1"
  by simp

lemma past_five: "\<exists>n::nat. (5::real) < of_nat n"
  by (rule reals_Archimedean2)

lemma eps_split: "(e::real) / 2 + e / 2 = e"
  by simp

lemma geometric_sum: "suminf (\<lambda>n. ((1::real) / 2) ^ n) = 2"
proof -
  have "suminf (\<lambda>n. ((1::real) / 2) ^ n) = 1 / (1 - 1 / 2)"
    by (rule suminf_geometric) simp
  then show ?thesis by simp
qed

end
