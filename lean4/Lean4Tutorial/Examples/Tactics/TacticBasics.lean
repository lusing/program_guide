/-
文件: 06_tactics/tactics.lean
描述: 第8章 战术基础（与教程同步，Lean 4.34.0 验证）
编译: lake build Lean4Tutorial.Examples.Tactics.TacticBasics
-/

namespace Lean4Tutorial.Examples.Tactics.Ch8

variable {P Q R : Prop}

/-! # 核心战术 -/

theorem t1 : P → P := by
  intro h
  exact h

theorem t2 : P ∧ Q → Q ∧ P := by
  intro ⟨hp, hq⟩
  exact ⟨hq, hp⟩

theorem t3 (h1 : P → Q) (h2 : P) : Q := by
  apply h1
  exact h2

theorem t4 (h : P ∧ Q) : Q ∧ P := by
  refine ⟨?_, ?_⟩
  · exact h.2
  · exact h.1

theorem t5 (h1 : P) (h2 : P → Q) (h3 : Q → R) : R := by
  have hq : Q := h2 h1
  have hr : R := h3 hq
  exact hr

theorem t6 (h1 : P) (h2 : P → Q) (h3 : Q → R) : R := by
  suffices hq : Q from h3 hq
  exact h2 h1

/-! # 解构战术 -/

theorem t7 (h : P ∨ Q) : Q ∨ P := by
  cases h with
  | inl hp => exact Or.inr hp
  | inr hq => exact Or.inl hq

theorem t8 (h : P ∧ (Q ∨ R)) : (P ∧ Q) ∨ (P ∧ R) := by
  rcases h with ⟨hp, hq | hr⟩
  · exact Or.inl ⟨hp, hq⟩
  · exact Or.inr ⟨hp, hr⟩

theorem t9 (h : ∃ n : Nat, n > 5) : ∃ m : Nat, m > 4 := by
  obtain ⟨n, hn⟩ := h
  exact ⟨n, by omega⟩

/-! # 归纳证明 -/

-- n + 0 = n 是定义相等（Nat.add 对第二参数递归），改用真正需要归纳的 0 + n = n
theorem zero_add' : ∀ n : Nat, 0 + n = n := by
  intro n
  induction n with
  | zero => rfl
  | succ n ih =>
    -- 目标 0 + succ n = succ n；由 add 定义 0 + succ n ≡ succ (0 + n)
    rw [show 0 + Nat.succ n = Nat.succ (0 + n) from rfl, ih]

inductive Even : Nat → Prop where
  | zero : Even 0
  | add2 : Even n → Even (n + 2)

theorem even_add_even (hm : Even m) (hn : Even n) : Even (m + n) := by
  induction hm with
  | zero => simpa using hn
  | add2 k ih =>
    -- add2 的隐式 Nat 参数不出现在 with 绑定里；用 add_right_comm 作 simp 规则重排
    simp only [Nat.add_right_comm]
    exact ih.add2

/-! # 重写与化简 -/

theorem rw_demo (x y z : Nat) (h1 : x = y) (h2 : y = z) : x + 0 = z := by
  rw [Nat.add_zero]
  rw [h1, h2]

example (x y : Nat) (h : x = y) (h' : x + 1 = 3) : y + 1 = 3 := by
  rw [h] at h'
  exact h'

example (n : Nat) : n + 0 = 0 + n := by simp

example (n : Nat) : n + 0 = 0 + n := by
  simp only [Nat.add_zero, Nat.zero_add]

example (l : List Nat) (h : l ++ [] = [1]) : l = [1] := by
  simpa using h

/-! # 组合子 -/

-- 注意：simp 引理清单里放 Nat.add_comm 会循环（x+y → y+x → x+y）
example (n : Nat) : 0 + n = n + 0 := by
  induction n with
  | zero => rfl
  | succ n ih => simp only [Nat.add_succ, Nat.succ_add, ih, Nat.add_zero]

example : (1 + 1 = 2) ∧ (2 + 2 = 4) := by
  constructor
  · rfl
  · rfl

example : (1 + 1 = 2) ∧ (2 + 2 = 4) := by
  constructor <;> all_goals rfl

example (n : Nat) : n + 0 = n := by
  try rw [Nat.add_succ]
  rfl

/-! # ext / by_cases -/

example (f g : Nat → Nat) (h : ∀ x, f x = g x) : f = g := by
  ext x
  exact h x

example (P Q : Prop) [Decidable P] : (P → Q) → (¬P → Q) → Q := by
  intro h1 h2
  by_cases h : P
  · exact h1 h
  · exact h2 h

end Lean4Tutorial.Examples.Tactics.Ch8
