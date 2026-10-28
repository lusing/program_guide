theory ZeroSharp
  imports "ZF.Nat"
begin

text \<open>第 95 章：六点序上一个具体对染色的齐一三元组（单表达式语言
下的三元不可辨别集）、蓝图取值一致性与一个反例三元组。0# 是无限对象，
这里只核对有限影子。\<close>

definition N3 :: "i" where "N3 \<equiv> succ(2)"
definition N4 :: "i" where "N4 \<equiv> succ(N3)"
definition N5 :: "i" where "N5 \<equiv> succ(N4)"
definition K6 :: "i" where "K6 \<equiv> succ(N5)"

(* 红边恰为 {1,3},{1,5},{3,5},{0,1}；其余对为蓝。 *)
definition red :: "i => i => o" where
  "red(x, y) \<equiv> (x = 1 \<and> y = N3) \<or> (x = 1 \<and> y = N5) \<or>
                  (x = N3 \<and> y = N5) \<or> (x = 0 \<and> y = 1)"

lemma red_13: "red(1, N3)" by (simp add: red_def)
lemma red_15: "red(1, N5)" by (simp add: red_def)
lemma red_35: "red(N3, N5)" by (simp add: red_def)

lemma not_red_03: "\<not> red(0, N3)" by (simp add: red_def N3_def)
lemma not_red_05: "\<not> red(0, N5)" by (simp add: red_def N5_def N4_def N3_def)

(* I = {1,3,5}：所有对同为红，齐一（不可辨别）。 *)
lemma hom_I: "red(1,N3) \<and> red(1,N5) \<and> red(N3,N5)"
  using red_13 red_15 red_35 by blast

(* {0,1,3}：红蓝混合，不齐一。 *)
lemma not_hom_013:
  "red(0,1) \<and> \<not> red(0,N3) \<and> red(1,N3)"
  using red_13 not_red_03 by (simp_all add: red_def N3_def)

(* 元素都属于六点全集 K6。 *)
lemma in_K6:
  "0 \<in> K6 \<and> 1 \<in> K6 \<and> 2 \<in> K6 \<and> N3 \<in> K6 \<and> N4 \<in> K6 \<and> N5 \<in> K6"
  by (auto simp add: K6_def N5_def N4_def N3_def)

end
