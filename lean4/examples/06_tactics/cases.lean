/-
文件: 06_tactics/cases.lean
描述: Lean 4 cases 分情况讨论
编译: lake build Lean4Tutorial.Examples.Tactics.Cases
-/

namespace Lean4Tutorial.Examples.Tactics.Cases

/-! # cases 战术简介 -/

-- cases 战术用于对归纳类型的值进行分情况讨论
-- 它将一个目标根据归纳类型的构造子分解为多个子目标
-- 与 induction 不同，cases 不生成归纳假设

/-! # 对布尔值的 cases -/

-- 证明：排中律的一个特例（对可判定命题）
theorem cases_bool (b : Bool) : b = true ∨ b = false := by
  cases b with
  | true =>
    left
    rfl
  | false =>
    right
    rfl

-- 使用 cases 证明德摩根定律的一个特例
theorem demorgan_bool (a b : Bool) :
  ¬ (a && b) = (¬a || ¬b) := by
  cases a <;> cases b <;> simp <;> decide

/-! # 对自然数的 cases -/

-- 每个自然数要么是 0，要么是某个数的后继
theorem nat_cases (n : Nat) : n = 0 ∨ ∃ m : Nat, n = m + 1 := by
  cases n with
  | zero =>
    left
    rfl
  | succ m =>
    right
    refine' ⟨m, _⟩
    rfl

-- 另一个例子
theorem nat_even_or_odd (n : Nat) : n % 2 = 0 ∨ n % 2 = 1 := by
  have h : n % 2 < 2 := Nat.mod_lt n (by decide)
  interval_cases h' : n % 2 <;> tauto

/-! # 对 Option 的 cases -/

-- 从 Option 中提取值，带默认值
theorem option_cases {α : Type} (default : α) (opt : Option α) :
  ∃ x : α, (opt = none → x = default) ∧ (∀ y, opt = some y → x = y) := by
  cases opt with
  | none =>
    refine' ⟨default, _⟩
    constructor
    · intro _
      rfl
    · intro y h
      contradiction
  | some y =>
    refine' ⟨y, _⟩
    constructor
    · intro h
      contradiction
    · intro z hz
      injection hz with hz'
      rw [hz']

/-! # 对列表的 cases -/

-- 列表要么是空列表，要么是 head :: tail
theorem list_cases {α : Type} (xs : List α) :
  xs = [] ∨ ∃ (h : α) (t : List α), xs = h :: t := by
  cases xs with
  | nil =>
    left
    rfl
  | cons h t =>
    right
    refine' ⟨h, t, rfl⟩

-- 列表的 head 的性质
theorem list_head_cases {α : Type} (default : α) (xs : List α) :
  (xs.head? = none ↔ xs = []) ∧
  (∀ x, xs.head? = some x → ∃ t, xs = x :: t) := by
  cases xs with
  | nil =>
    simp
    <;> tauto
  | cons x t =>
    simp
    <;> tauto

/-! # cases 与假设 -/

-- cases 也可以对假设使用（cases h）
-- 如果假设是一个析取或存在量词，可以分解它

theorem cases_or (P Q : Prop) (h : P ∨ Q) : Q ∨ P := by
  cases h with
  | inl hP =>
    right
    exact hP
  | inr hQ =>
    left
    exact hQ

theorem cases_exists (P : Nat → Prop) (h : ∃ n, P n) :
  ∃ m, P m := by
  cases h with
  | intro n hn =>
    refine' ⟨n, hn⟩

/-! # 对合取的 cases -/

-- 如果假设是 P ∧ Q，cases 可以把它分解为两个假设
theorem cases_and (P Q : Prop) (h : P ∧ Q) : Q ∧ P := by
  cases h with
  | intro hP hQ =>
    exact ⟨hQ, hP⟩

-- 更常用的是 h.1 和 h.2
theorem and_simple (P Q : Prop) (h : P ∧ Q) : Q ∧ P :=
  ⟨h.2, h.1⟩

/-! # 对等价的 cases -/

-- 等价可以分解为两个蕴含
theorem cases_iff (P Q : Prop) (h : P ↔ Q) : (P → Q) ∧ (Q → P) := by
  cases h with
  | intro hPQ hQP =>
    exact ⟨hPQ, hQP⟩

/-! # 嵌套 cases -/

-- 可以嵌套使用 cases
theorem nested_cases (P Q R : Prop) (h : P ∨ (Q ∧ R)) : (P ∨ Q) ∧ (P ∨ R) := by
  cases h with
  | inl hP =>
    constructor
    · left; exact hP
    · left; exact hP
  | inr hQR =>
    cases hQR with
    | intro hQ hR =>
      constructor
      · right; exact hQ
      · right; exact hR

/-! # case 战术 -/

-- case 战术可以聚焦某个特定的分支
-- 当有很多分支时很有用

inductive Weekday where
  | monday | tuesday | wednesday | thursday | friday | saturday | sunday
deriving Repr

open Weekday

def isWeekend (d : Weekday) : Bool :=
  match d with
  | saturday => true
  | sunday => true
  | _ => false

theorem weekend_or_weekday (d : Weekday) :
  isWeekend d = true ∨ isWeekend d = false := by
  cases d with
  | monday => simp [isWeekend] <;> tauto
  | tuesday => simp [isWeekend] <;> tauto
  | wednesday => simp [isWeekend] <;> tauto
  | thursday => simp [isWeekend] <;> tauto
  | friday => simp [isWeekend] <;> tauto
  | saturday => simp [isWeekend] <;> tauto
  | sunday => simp [isWeekend] <;> tauto

-- 更简洁的方式
theorem weekend_or_weekday' (d : Weekday) :
  isWeekend d = true ∨ isWeekend d = false := by
  cases d <;> simp [isWeekend] <;> tauto

/-! # rcases 战术 -/

-- rcases 可以同时分解多个假设，支持更复杂的模式

theorem rcases_example (P Q R : Prop) (h : P ∧ (Q ∨ R)) : (P ∧ Q) ∨ (P ∧ R) := by
  rcases h with ⟨hP, hQ | hR⟩
  · left
    exact ⟨hP, hQ⟩
  · right
    exact ⟨hP, hR⟩

-- 更复杂的 rcases
theorem rcases_complex (P Q R S : Prop) (h : (P → Q) ∧ (R → S) ∧ (P ∨ R)) : Q ∨ S := by
  rcases h with ⟨hPQ, hRS, hP | hR⟩
  · left; exact hPQ hP
  · right; exact hRS hR

/-! # rcases 对存在量词的使用 -/

theorem rcases_exists (P Q : Nat → Prop)
  (h1 : ∃ n, P n) (h2 : ∀ n, P n → Q n) : ∃ m, Q m := by
  rcases h1 with ⟨n, hn⟩
  refine' ⟨n, h2 n hn⟩

-- 嵌套存在量词
theorem rcases_nested_exists (R : Nat → Nat → Prop)
  (h : ∃ m n, R m n) : ∃ n m, R m n := by
  rcases h with ⟨m, n, hmn⟩
  refine' ⟨n, m, hmn⟩

/-! # cases 对等式的使用 -/

-- injection 战术可以用于构造子的等式
-- 但 cases 也可以对等式使用

theorem cases_eq (m n : Nat) (h : m + 1 = n + 1) : m = n := by
  injection h

-- 或者使用 cases
theorem cases_eq' (m n : Nat) (h : m + 1 = n + 1) : m = n := by
  cases h
  <;> rfl

/-! # 分情况讨论的其他方式 -/

-- 使用 by_cases 对任意命题分情况
-- 要求命题是可判定的（Decidable）

theorem by_cases_example (n : Nat) :
  n % 2 = 0 ∨ n % 2 = 1 := by
  by_cases h : n % 2 = 0
  · left; exact h
  · right
    have h' : n % 2 < 2 := Nat.mod_lt n (by decide)
    omega

-- 对条件命题分情况
theorem by_cases_cond (P : Prop) [Decidable P] (Q : Prop) :
  P ∨ ¬P := by
  by_cases h : P
  · left; exact h
  · right; exact h

/-! # interval_cases 战术 -/

-- interval_cases 可以对有限范围内的自然数分情况讨论
theorem interval_cases_example (n : Nat) (h : n ≤ 3) :
  n = 0 ∨ n = 1 ∨ n = 2 ∨ n = 3 := by
  interval_cases n <;> tauto

-- 更实用的例子
theorem small_nat_even (n : Nat) (h : n ≤ 5) :
  n % 2 = 0 → n = 0 ∨ n = 2 ∨ n = 4 := by
  intro h2
  interval_cases n <;> norm_num at h2 ⊢ <;> tauto

/-! # cases 与归纳的对比 -/

-- cases 只是分情况，没有归纳假设
-- induction 有归纳假设，可以证明递归性质

-- 对于不需要归纳的证明，用 cases
-- 对于需要归纳假设的证明，用 induction

-- 例子：cases 足够
theorem bool_eq_or_ne (b : Bool) : b = true ∨ b = false := by
  cases b <;> simp <;> tauto

-- 例子：需要 induction
theorem need_induction : ∀ n : Nat, n + 0 = n := by
  intro n
  -- cases n 不行，因为后继情况无法证明
  induction n with
  | zero => rfl
  | succ n ih => simp [ih] <;> rfl

/-! # 更多示例 -/

-- 对 Either 类型的 cases
inductive Either (α β : Type) : Type where
  | left : α → Either α β
  | right : β → Either α β

def eitherMap {α β γ : Type} (f : α → γ) (g : β → γ)
  (e : Either α β) : γ :=
  match e with
  | Either.Left a => f a
  | Either.Right b => g b

theorem either_cases {α β γ : Type} (f : α → γ) (g : β → γ)
  (e : Either α β) :
  (∃ a : α, e = Either.left a ∧ eitherMap f g e = f a) ∨
  (∃ b : β, e = Either.right b ∧ eitherMap f g e = g b) := by
  cases e with
  | left a =>
    left
    refine' ⟨a, rfl, rfl⟩
  | right b =>
    right
    refine' ⟨b, rfl, rfl⟩

end Lean4Tutorial.Examples.Tactics.Cases
