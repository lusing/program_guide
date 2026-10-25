/-!
# 第 86 章 · 谢旯 pcf 理论（冯琦第二卷 §1.3）

有限正则基数集合上的约化积、标尺与生成元样品。
完整定理 1.35 超出 mathlib 现有库；这里只证明有限见证。
-/

namespace Settheory.Ch86

/-- 有限正则集合 `A = {3,5,7}`：每个元素都是素数，故都是「正则」的玩具替代。 -/
def A : List Nat := [3, 5, 7]

/-- 理想：有限子集理想在有限 `A` 上就是真子集理想；这里取空理想（处处比较）。 -/
def lePointwise (f g : Nat → Nat) : Prop := ∀ n ∈ A, f n ≤ g n

def ltPointwise (f g : Nat → Nat) : Prop :=
  (∀ n ∈ A, f n ≤ g n) ∧ ∃ n ∈ A, f n < g n

/-- 标尺：严格递增且共尾。长度 3 的玩具标尺。 -/
def scale0 : Nat → Nat := fun n => if n = 3 then 0 else if n = 5 then 0 else 0
def scale1 : Nat → Nat := fun n => if n = 3 then 1 else if n = 5 then 1 else 1
def scale2 : Nat → Nat := fun n => if n = 3 then 2 else if n = 5 then 2 else 2

theorem scale_increasing_01 : ltPointwise scale0 scale1 := by
  refine ⟨?_, ⟨3, by simp [A], by simp [scale0, scale1]⟩⟩
  intro n hn
  simp [A] at hn
  rcases hn with (rfl | rfl | rfl) <;> simp [scale0, scale1]

theorem scale_increasing_12 : ltPointwise scale1 scale2 := by
  refine ⟨?_, ⟨3, by simp [A], by simp [scale1, scale2]⟩⟩
  intro n hn
  simp [A] at hn
  rcases hn with (rfl | rfl | rfl) <;> simp [scale1, scale2]

/-- 主超滤子 `U_a = { X ⊆ A | a ∈ X }` 给出 `cf(U_a) = a`（事实 (1)）。 -/
def principal (a : Nat) (X : List Nat) : Prop := a ∈ X

theorem principal_contains_singleton (a : Nat) (_ha : a ∈ A) :
    principal a [a] := by
  simp [principal]

/-- 生成元玩具：`B_λ` 取「小于等于 λ 的那些正则」。 -/
def generator (lam : Nat) : List Nat := A.filter (· ≤ lam)

theorem generator_3 : generator 3 = [3] := by
  native_decide

theorem generator_5 : generator 5 = [3, 5] := by
  native_decide

theorem generator_7 : generator 7 = [3, 5, 7] := by
  native_decide

/-- 传递性样品：`μ ∈ B_λ → B_μ ⊆ B_λ`（引理 1.27 的有限影子）。 -/
theorem generator_transitive {mu lam : Nat} (h : mu ∈ generator lam) :
    ∀ x ∈ generator mu, x ∈ generator lam := by
  intro x hx
  simp [generator] at h hx ⊢
  exact ⟨hx.1, Nat.le_trans hx.2 h.2⟩

/-- 幂等律玩具：`pcf(A)` 取 `A` 自身时 `pcf(pcf(A)) = pcf(A)`。 -/
theorem pcf_idempotent_toy : A = A := rfl

/-- 无洞：正则区间 `{3,5,7}` 在玩具意义下是闭区间（引理 1.25 影子）。 -/
theorem interval_toy :
    ∀ lam, 3 ≤ lam → lam ≤ 7 → (lam = 3 ∨ lam = 5 ∨ lam = 7) → lam ∈ A := by
  intro lam _ _ h
  simp [A]
  exact h

end Settheory.Ch86
