/-
文件: 05_propositions/quantifiers.lean
描述: Lean 4 量词：∀ 和 ∃
编译: lake build Lean4Tutorial.Examples.Propositions.Quantifiers
-/

namespace Lean4Tutorial.Examples.Propositions.Quantifiers

/-! # 全称量词（Universal Quantifier）∀ -/

-- ∀ x : α, P x 表示"对于所有 x : α，P(x) 成立"
-- 在 Lean 中，∀ 就是依赖函数类型 (x : α) → P x
-- 证明 ∀ x, P x 就是构造一个函数，将任意 x 映射为 P x 的证明

-- 证明：对于所有自然数 n，n + 0 = n
theorem all_nat_add_zero : ∀ (n : Nat), n + 0 = n :=
  fun n => by simp

-- 等价的写法
theorem all_nat_add_zero' (n : Nat) : n + 0 = n := by simp

-- 带条件的全称命题
-- 证明：对于所有自然数 n，如果 n > 0，则 n - 1 + 1 = n
theorem all_pos_nat_pred_succ : ∀ (n : Nat), n > 0 → n - 1 + 1 = n :=
  fun n h => by
    cases n with
    | zero => contradiction
    | succ n' => simp <;> omega

/-! # 存在量词（Existential Quantifier）∃ -/

-- ∃ x : α, P x 表示"存在某个 x : α，使得 P(x) 成立"
-- 证明 ∃ x, P x 需要提供一个见证（witness）x 和 P x 的证明
-- 使用 ⟨witness, proof⟩ 构造

-- 证明：存在一个自然数 n，使得 n > 5
theorem exists_gt_five : ∃ (n : Nat), n > 5 :=
  ⟨6, by decide⟩

-- 证明：对于任何自然数 n，存在 m 使得 m > n
theorem exists_gt (n : Nat) : ∃ (m : Nat), m > n :=
  ⟨n + 1, by omega⟩

-- 使用 Exists.intro
theorem exists_gt' (n : Nat) : ∃ (m : Nat), m > n :=
  Exists.intro (n + 1) (by omega)

/-! # 存在量词的消除 -/

-- 如果我们知道 ∃ x, P x，并且知道 ∀ x, P x → Q，那么可以推出 Q
-- 这就是存在量词的消除规则

theorem exists_elim (P : Nat → Prop) (Q : Prop)
  (h1 : ∃ x, P x) (h2 : ∀ x, P x → Q) : Q :=
  Exists.elim h1 (fun x hPx => h2 x hPx)

-- 另一个例子
theorem exists_example :
  (∃ x : Nat, x > 0 ∧ x < 5) → ∃ y : Nat, y > 0 :=
  fun h =>
    Exists.elim h
      (fun x hx =>
        ⟨x, hx.1⟩)

/-! # 量词的否定 -/

-- ¬∀ x, P x 不等价于 ∃ x, ¬P x（在直觉主义逻辑中）
-- 但 ∃ x, ¬P x → ¬∀ x, P x 是成立的

theorem exists_not_imp_not_all (P : Nat → Prop) :
  (∃ x, ¬ P x) → ¬ (∀ x, P x) :=
  fun h1 =>
    Exists.elim h1
      (fun x hnPx =>
        fun hAll =>
          hnPx (hAll x))

-- 另一个方向需要经典逻辑（排中律）
-- ¬∀ x, P x → ∃ x, ¬P x  （需要经典逻辑）

-- ¬∃ x, P x ↔ ∀ x, ¬P x（直觉主义成立）
theorem not_exists_iff_all_not (P : Nat → Prop) :
  ¬ (∃ x, P x) ↔ ∀ x, ¬ P x :=
  Iff.intro
    (fun h x hPx => h ⟨x, hPx⟩)
    (fun h hEx =>
      Exists.elim hEx
        (fun x hPx => h x hPx))

/-! # 量词的交换 -/

-- ∀ x, ∀ y, P x y  ↔  ∀ y, ∀ x, P x y
theorem all_swap (P : Nat → Nat → Prop) :
  (∀ x y, P x y) ↔ (∀ y x, P x y) :=
  Iff.intro
    (fun h y x => h x y)
    (fun h x y => h y x)

-- ∃ x, ∃ y, P x y  ↔  ∃ y, ∃ x, P x y
theorem exists_swap (P : Nat → Nat → Prop) :
  (∃ x y, P x y) ↔ (∃ y x, P x y) :=
  Iff.intro
    (fun h =>
      Exists.elim h
        (fun x h1 =>
          Exists.elim h1
            (fun y h2 => ⟨y, x, h2⟩)))
    (fun h =>
      Exists.elim h
        (fun y h1 =>
          Exists.elim h1
            (fun x h2 => ⟨x, y, h2⟩)))

-- ∃ x, ∀ y, P x y → ∀ y, ∃ x, P x y
-- （反过来不成立！）
theorem exists_all_imp_all_exists (P : Nat → Nat → Prop) :
  (∃ x, ∀ y, P x y) → (∀ y, ∃ x, P x y) :=
  fun h =>
    Exists.elim h
      (fun x hAll =>
        fun y => ⟨x, hAll y⟩)

-- 反向不成立的例子：
-- 对于每个数 y，存在数 x 使得 x > y（对的，x = y + 1）
-- 但是不存在一个数 x，使得对于所有 y，x > y（不对，没有最大的数）

/-! # 有界量词 -/

-- ∀ x < n, P x 表示"对于所有小于 n 的 x，P(x) 成立"
-- ∃ x < n, P x 表示"存在小于 n 的 x，使得 P(x) 成立"

theorem bounded_all_example : ∀ n < 3, n + n < 7 :=
  fun n hn =>
    have h : n < 3 := hn
    interval_cases n <;> decide

theorem bounded_exists_example : ∃ n < 5, n * n = 9 :=
  ⟨3, by decide, by decide⟩

/-! # 唯一存在性 ∃! -/

-- ∃! x, P x 表示"存在唯一的 x 使得 P(x) 成立"
-- 即：存在 x 满足 P x，且任何满足 P 的 y 都等于 x

-- 证明唯一存在
theorem exists_unique_zero : ∃! n : Nat, n = 0 :=
  ⟨0, by rfl, fun y hy => by simp [hy]⟩

-- 另一个例子：方程 2 * x = 4 有唯一解
theorem exists_unique_solution : ∃! x : Nat, 2 * x = 4 := by
  refine' ⟨2, by decide, _⟩
  intro y hy
  omega

-- 唯一存在的分解
-- ∃! x, P x ↔ (∃ x, P x) ∧ (∀ x y, P x → P y → x = y)
theorem exists_unique_iff (P : Nat → Prop) :
  (∃! x, P x) ↔ (∃ x, P x) ∧ (∀ x y, P x → P y → x = y) :=
  Iff.intro
    (fun h =>
      ExistsUnique.elim h
        (fun x hPx hUniq =>
          ⟨⟨x, hPx⟩, fun y z hy hz => hUniq y hy ▸ hUniq z hz ▸ rfl⟩))
    (fun h =>
      Exists.elim h.1
        (fun x hPx =>
          ⟨x, hPx, fun y hy => h.2 y x hy hPx⟩))

/-! # 选择公理（Choice）-/

-- 在 Lean 中，选择公理是可用的
-- 如果 ∀ x, ∃ y, R x y，那么存在函数 f 使得 ∀ x, R x (f x)

-- 经典选择公理
theorem choice_example (R : Nat → Nat → Prop) (h : ∀ x, ∃ y, R x y) :
  ∃ (f : Nat → Nat), ∀ x, R x (f x) :=
  ⟨fun x => Classical.choose (h x), fun x => Classical.choose_spec (h x)⟩

/-! # 自然数性质的例子 -/

-- 每个正自然数都有前驱
theorem pos_has_pred : ∀ n : Nat, n > 0 → ∃ m : Nat, n = m + 1 :=
  fun n hn =>
    match n with
    | 0 => by contradiction
    | m + 1 => ⟨m, by rfl⟩

-- 偶数的存在性
theorem exists_even_gt : ∀ n : Nat, ∃ m : Nat, m > n ∧ m % 2 = 0 :=
  fun n =>
    if n % 2 = 0 then
      ⟨n + 2, by omega, by omega⟩
    else
      ⟨n + 1, by omega, by omega⟩

-- 最大公约数的存在性
theorem gcd_exists (a b : Nat) (h : a > 0 ∨ b > 0) :
  ∃ d : Nat, d > 0 ∧ d ∣ a ∧ d ∣ b :=
  ⟨1, by decide, by simp, by simp⟩

/-! # 嵌套量词的例子 -/

-- 极限的定义（简化版）
-- lim_{n→∞} a_n = L 当且仅当：
--   ∀ ε > 0, ∃ N, ∀ n ≥ N, |a_n - L| < ε

-- 序列 a_n = 1/n 的极限是 0（简化为自然数版本）
-- 这里我们用"1/(n+1) < ε"的直觉，但用自然数表述
def sequence_limit_zero_prop : Prop :=
  ∀ ε : Nat, ε > 0 → ∃ N : Nat, ∀ n : Nat, n ≥ N → 1 < ε * (n + 1)

-- 证明上面的命题
theorem seq_limit : sequence_limit_zero_prop := by
  intro ε hε
  refine' ⟨1, _⟩
  intro n hn
  omega

/-! # 使用归纳法证明全称命题 -/

-- 证明：对于所有自然数 n，0 + n = n
theorem zero_add_all : ∀ n : Nat, 0 + n = n := by
  intro n
  induction n with
  | zero => rfl
  | succ n ih =>
    simp [Nat.add_succ, ih] <;> rfl

-- 证明：对于所有自然数 n，n ≤ 2^n
theorem pow_ge_self : ∀ n : Nat, n ≤ 2 ^ n := by
  intro n
  induction n with
  | zero => decide
  | succ n ih =>
    simp [pow_succ] at *
    <;> omega

/-! # 构造性证明 vs 经典证明 -/

-- 在直觉主义/构造性逻辑中：
-- 要证明 ∃ x, P x，必须显式构造出 x
-- 不能通过反证法证明存在性

-- 在经典逻辑中（使用排中律）：
-- 可以通过反证法证明存在性：
-- 假设 ¬∃ x, P x 推出矛盾，则 ∃ x, P x

-- 使用经典逻辑的例子
theorem classic_exists (P : Nat → Prop) (h : ¬ (∀ n, ¬ P n)) :
  ∃ n, P n := by
  by_contra h'
  have h'' : ∀ n, ¬ P n := by
    intro n hn
    exact h' ⟨n, hn⟩
  exact h h''

end Lean4Tutorial.Examples.Propositions.Quantifiers
