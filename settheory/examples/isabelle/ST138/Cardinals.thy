theory Cardinals imports ZF "ZF.CardinalArith" begin

text \<open>基数的 ZF 官方定义：初始序数（书 5.1.2-5.1.3）。Card_iff_initial
就是书 5.1.3 命题(1)⟷(5)的逐字形态。\<close>
thm Card_iff_initial
thm Card_cardinal_eq      (* 基数 K 的"基数"就是 K 自己 *)
thm Card_is_Ord
thm Card_0

text \<open>ℵ 记号的起点（书 5.1.10）：nat = ω 是第一个无穷基数。\<close>
thm Card_nat

text \<open>后继基数（书 5.1.8 的 κ⁺）：csucc(K) 是大于 K 的最小基数。\<close>
thm csucc_basic
thm Card_csucc
thm lt_csucc

text \<open>自己动手：0 是基数，且 1 = succ(0) 也是——有限基数即自然数
（书 5.1.5(1)）。\<close>
lemma one_is_card: "Card(1)"
  unfolding Card_iff_initial
  by (auto simp: lt_def eqpoll_def bij_def surj_def)

end
