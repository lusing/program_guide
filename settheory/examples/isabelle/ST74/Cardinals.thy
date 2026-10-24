theory Cardinals
  imports "ZF.CardinalArith" "ZF.Nat" "ZF.Epsilon"
begin

text \<open>
第 74 章：基数：和、积与典型秩序（冯琦 §1.9）。

ZF 的 CardinalArith 是本章的官方影子：Card（初始序数，命题 1.27）、
csucc（α⁺，定义 1.90）、csquare_rel（序数乘积空间的典型秩序，
定义 1.97——well_ord_csquare 正是定理 1.92 的前半）、
InfCard_square_eqpoll（ℵ·ℵ = ℵ 的官方等势形态，定理 1.93）。
ZF 无 aleph 构造——用 transrec2（定理 1.56 的化身）自建 ℵ 序列
（定义 1.93 三条款），并证有限段的 InfCard 性质。
\<close>

subsection \<open>库锚点：初始序数、α⁺ 与典型秩序\<close>

text \<open>Card(K) ⟺ K 是自己的初始序数（命题 1.27(5)：比 K 小的序数
势严格更小）。\<close>
thm Card_iff_initial
thm Card_nat            \<comment> \<open>ω 是第一个无穷基数（命题 1.27(2)）\<close>
thm InfCard_nat

text \<open>α⁺ = csucc(α)：比 α 强势的最小基数（定义 1.90 / 定理 1.86）。\<close>
thm Card_csucc          \<comment> \<open>csucc(K) 总是基数\<close>
thm lt_csucc            \<comment> \<open>K < csucc(K)：严格更强\<close>
thm csucc_le            \<comment> \<open>最小性：Card(L) ∧ K<L ⟹ csucc(K) ≤ L\<close>

text \<open>ω₁ := csucc(nat)——第一个不可数基数（定义 1.89 的库形态）。\<close>

definition omega1 :: "i" where
  "omega1 \<equiv> csucc(nat)"

lemma Card_omega1: "Card(omega1)"
  unfolding omega1_def by (rule Card_csucc [OF Ord_nat])

lemma uncountable_omega1: "nat < omega1"
  unfolding omega1_def by (rule lt_csucc [OF Ord_nat])

text \<open>典型秩序 csquare_rel：K×K 上的 max-方-位三键良序
（定义 1.97 与定理 1.92 前半的官方化身）。\<close>
thm well_ord_csquare
thm csquareD

text \<open>定理 1.93（ℵ·ℵ = ℵ）的官方等势形态。\<close>
thm InfCard_square_eqpoll

subsection \<open>自建 ℵ 序列（定义 1.93 三条款）\<close>

text \<open>ℵ₀ = nat；ℵ_{α+1} = csucc(ℵ_α)；λ 极限时 ℵ_λ = ⋃{ℵ_α | α<λ}
——transrec2 的第三款自动取并。\<close>

definition aleph :: "i \<Rightarrow> i" where
  "aleph(a) \<equiv> transrec2(a, nat, \<lambda>j r. csucc(r))"

lemma aleph_0 [simp]: "aleph(0) = nat"
  by (simp add: aleph_def)

lemma aleph_succ [simp]: "aleph(succ(i)) = csucc(aleph(i))"
  by (simp add: aleph_def)

lemma aleph_Limit: "Limit(i) \<Longrightarrow> aleph(i) = (\<Union>j<i. aleph(j))"
  apply (simp add: aleph_def)
  apply (rule transrec2_Limit)
  apply assumption
  done

text \<open>ℵ₁ 现形：ℵ₁ = csucc(ℵ₀) = csucc(nat) = ω₁（定义 1.93 与
定义 1.89 在第一步合流）。\<close>

lemma aleph_1: "aleph(1) = omega1"
  by (simp add: omega1_def)

text \<open>有限段的无穷基数性：nat 归纳 + InfCard_csucc。\<close>

lemma InfCard_aleph_nat: "n \<in> nat \<Longrightarrow> InfCard(aleph(n))"
  apply (erule nat_induct)
   apply (simp add: InfCard_nat)
  apply (simp add: InfCard_csucc)
  done

text \<open>定理 1.93 的 ℵ_n 实例：ℵ_n × ℵ_n ≈ ℵ_n（n 有限）。\<close>

lemma aleph_square_eqpoll: "n \<in> nat \<Longrightarrow> aleph(n) \<times> aleph(n) \<approx> aleph(n)"
  apply (rule InfCard_square_eqpoll)
  apply (rule InfCard_aleph_nat)
  apply assumption
  done

end
