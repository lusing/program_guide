theory Covering
  imports "ZF.Nat"
begin

text \<open>第 96 章：覆盖引理的有限影子。L-侧取一个显式有限族；
X 无单片等势覆盖、但两片 slack 覆盖成功；缺含 0 的成员后
点 0 完全不可覆盖（逆命题 X = ω₁ ∪ {ιₙ} 的影子）。\<close>

definition N3 :: "i" where "N3 \<equiv> succ(2)"
definition N4 :: "i" where "N4 \<equiv> succ(N3)"

definition L0 :: "i" where "L0 \<equiv> 0"
definition L1 :: "i" where "L1 \<equiv> {0, 1, 2}"
definition L2 :: "i" where "L2 \<equiv> {2, N3}"
definition L3 :: "i" where "L3 \<equiv> {N4}"

definition X :: "i" where "X \<equiv> {1, 2, N3}"
definition X0 :: "i" where "X0 \<equiv> {0, 1}"

(* 等势（单片）覆盖失败：四个成员都不能包住 X。 *)
lemma no_single_cover:
  "\<not> (X \<subseteq> L0) \<and> \<not> (X \<subseteq> L1) \<and> \<not> (X \<subseteq> L2) \<and> \<not> (X \<subseteq> L3)"
  by (auto simp add: X_def L0_def L1_def L2_def L3_def N3_def N4_def)

(* 两片 slack 覆盖成功（覆盖引理的 |X| + ℵ₁ 版本的影子）。 *)
lemma two_piece_cover: "X \<subseteq> L1 \<union> L2"
  by (auto simp add: X_def L1_def L2_def)

lemma union_content: "L1 \<union> L2 = {0, 1, 2, N3}"
  by (auto simp add: L1_def L2_def N3_def)

(* 缺含 0 的成员：点 0 完全不可覆盖——逆命题的不可覆盖集的影子。 *)
lemma point0_uncoverable:
  "\<not> (X0 \<subseteq> L2) \<and> \<not> (X0 \<subseteq> L3) \<and> \<not> (X0 \<subseteq> L2 \<union> L3)"
  by (auto simp add: X0_def L2_def L3_def N3_def N4_def)

(* 计数见证：L1 恰有三个互异的成员（|Y| = |X| 的形状）。 *)
lemma L1_three_members:
  "0 \<in> L1 \<and> 1 \<in> L1 \<and> 2 \<in> L1 \<and> 0 \<noteq> 1 \<and> 1 \<noteq> 2 \<and> 0 \<noteq> 2"
  by (auto simp add: L1_def)

end
