import Mathlib.Tactic

/-!
# 第 132 章 良序集（Lean）

良序的 typeclass 形态、增函数引理 4.1.4（f(a) ≥ a）、以及良序集
"和与积"的字典序原型（书 4.1.7/4.1.8）。
-/

/-! ## 良序的机器形态 -/

/- `IsWellOrder α r` 打包了良序的全部条件（线序 + 良基）；
ℕ 上的 < 自动满足。 -/
example : IsWellOrder ℕ (· < ·) := inferInstance

#check @IsWellOrder
#check @WellFounded

/-! ## 增函数引理 4.1.4：良序集到自身的严格递增函数 f(a) ≥ a -/

/-- 书 4.1.4 的自然数版：严格递增的 f : ℕ → ℕ 满足 n ≤ f n。
证明即书中的"最小反例"论证：若 X = {x | f(x) < x} 非空取最小元
a，则 f(f(a)) < f(a) 给出更小的反例——在机器上是第二归纳原理
（Nat.strongRecOn）的一次调用。 -/
theorem increasing_ge_self (f : ℕ → ℕ) (hf : ∀ a b, a < b → f a < f b) :
    ∀ n, n ≤ f n :=
  fun n =>
    Nat.strongRecOn n fun m ih => by
      rcases m with _ | k
      · exact Nat.zero_le _
      · exact
          Nat.succ_le_of_lt
            (lt_of_le_of_lt (ih k (Nat.lt_succ_self k))
              (hf k (k + 1) (Nat.lt_succ_self k)))

/-- 推论 4.1.5(1) 的影子：不存在 ℕ 到真前段 {n | n < m} 的同构——
这里以"严格递增 + 映入 {0,1}"必退化呈现（鸽笼与 4.1.4 的合流）。 -/
example (f : ℕ → ℕ) (hf : ∀ a b, a < b → f a < f b)
    (hr : ∀ n, f n < 2) : False := by
  have h1 := increasing_ge_self f hf 2
  have h2 := hr 2
  exact absurd h2 (not_lt.mpr h1)

/-! ## 和与积：字典序的原型（书 4.1.7/4.1.8） -/

/- 良序集的"积"（书 4.1.8）：第二坐标优先、同层比第一坐标。
mathlib 的字典序 `Prod.Lex` 是**首**坐标优先
（x < y ⟺ x.1 < y.1 ∨ x.1 = y.1 ∧ x.2 < y.2，见 `Prod.lex_def`）——
书的积序正是同一构造用在交换乘积 W₂×W₁ 上的形态。
`Prod.lex` 另把它打包成 WellFoundedRelation。 -/
#check @Prod.lex_def
#check @Prod.lex

/-- 首坐标优先：(1,0) < (5,2)。 -/
example : Prod.Lex (· < ·) (· < ·) (1, 0) (5, 2) := by
  rw [Prod.lex_def]
  exact Or.inl (by decide)

/-- 同层才比次坐标：(3,1) < (3,2)。 -/
example : Prod.Lex (· < ·) (· < ·) (3, 1) (3, 2) := by
  rw [Prod.lex_def]
  exact Or.inr ⟨rfl, by decide⟩

/- 良序集的"和"（书 4.1.7）：左块全排在前——`Sum.Lex` 的不交并
字典序，左元素一律小于右元素。 -/
#check @Sum.Lex

example : Sum.Lex (· < ·) (· < ·) (Sum.inl 3 : ℕ ⊕ ℕ) (Sum.inr 0) := by
  simp
