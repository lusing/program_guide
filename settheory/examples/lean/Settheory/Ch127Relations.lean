import Mathlib.Tactic

/-!
# 第 127 章 关系与函数（Lean）

有序对的刻画、关系代数（逆与复合）、像的并/交/差律、函数三性
与左右逆的账。mathlib 把关系当作谓词 `α → β → Prop`，与书
"关系是有序对的集合"是同一件事的两种编码；复合与逆用库里的
`Relation.Comp`（记号 `∘r`）与 `flip`，dom/ran/像在本文件显式定义——
这样每条定律的证明都落在读者看得见的定义上。
-/

/-! ## 有序对 -/

/-- 书 2.1.3：有序对相等等价于坐标分别相等（mathlib 的 `Prod`
以结构体直接实现有序对，刻画定理就是 `Prod.ext_iff`）。 -/
example (a a' b b' : ℕ) : (a, b) = (a', b') ↔ a = a' ∧ b = b' :=
  Prod.ext_iff

/-! ## 关系代数（习题 2.5.8、2.5.9） -/

section Relations

variable {α β γ : Type}

/-- 关系即谓词；定义域、值域、像都按书 2.1.8/2.1.11 定义。 -/
def dom (R : α → β → Prop) : Set α := {x | ∃ y, R x y}

def ran (R : α → β → Prop) : Set β := {y | ∃ x, R x y}

def rimage (R : α → β → Prop) (A : Set α) : Set β := {y | ∃ x ∈ A, R x y}

local infixr:80 " ∘r " => Relation.Comp

open Relation

/-- 结合律（书 2.5.8）：(T∘S)∘R = T∘(S∘R)。`r ∘r p` 先施 r。 -/
example (R : α → β → Prop) (S : β → γ → Prop)
    (T : γ → γ → Prop) : (R ∘r S) ∘r T = R ∘r (S ∘r T) := comp_assoc

/-- 逆的复合律（书 2.5.9）：(S∘R)⁻¹ = R⁻¹ ∘ S⁻¹。 -/
example (R : α → β → Prop) (S : β → γ → Prop) :
    flip (R ∘r S) = flip S ∘r flip R := flip_comp

/-- 逆的逆还原。 -/
example (R : α → β → Prop) : flip (flip R) = R := flip_flip

/-- dom(R⁻¹) = ran(R)。 -/
example (R : α → β → Prop) : dom (flip R) = ran R := by
  ext x
  exact Iff.rfl

/-- ran(R⁻¹) = dom(R)。 -/
example (R : α → β → Prop) : ran (flip R) = dom R := by
  ext y
  exact Iff.rfl

end Relations

section Image

variable {α β : Type}

/-- R[A ∪ B] = R[A] ∪ R[B]（书 2.5.2(1)）：双向。 -/
example (R : α → β → Prop) (A B : Set α) :
    rimage R (A ∪ B) = rimage R A ∪ rimage R B := by
  ext y
  constructor
  · rintro ⟨x, hx | hx, hR⟩
    · exact Or.inl ⟨x, hx, hR⟩
    · exact Or.inr ⟨x, hx, hR⟩
  · rintro (⟨x, hx, hR⟩ | ⟨x, hx, hR⟩)
    · exact ⟨x, Or.inl hx, hR⟩
    · exact ⟨x, Or.inr hx, hR⟩

/-- R[A ∩ B] ⊆ R[A] ∩ R[B]（书 2.5.2(2)）：单向，一般取不到等号。 -/
example (R : α → β → Prop) (A B : Set α) :
    rimage R (A ∩ B) ⊆ rimage R A ∩ rimage R B := by
  rintro y ⟨x, hx, hR⟩
  exact ⟨⟨x, hx.1, hR⟩, ⟨x, hx.2, hR⟩⟩

/-- 严格单向的见证（习题 2.5.2）：R 把 0、1 都映到 3，
则交像为空而像之交集含 3。 -/
private def R0 : ℕ → ℕ → Prop := fun x y => (x = 0 ∧ y = 3) ∨ (x = 1 ∧ y = 3)

example : (3 : ℕ) ∈ rimage R0 ({0} : Set ℕ) ∩ rimage R0 ({1} : Set ℕ) ∧
    rimage R0 ({0} ∩ {1} : Set ℕ) = ∅ := by
  refine ⟨⟨⟨0, by simp, Or.inl ⟨rfl, rfl⟩⟩, ⟨1, by simp, Or.inr ⟨rfl, rfl⟩⟩⟩, ?_⟩
  ext y
  simp [R0, rimage]

end Image

/-! ## 函数：外延、三性、复合 -/

/-- 函数的外延判定（书 2.2.3）：处处相等即相等。 -/
example (f g : ℕ → ℕ) (h : ∀ x, f x = g x) : f = g := funext h

/-- 左逆存在则单射（书 2.5.12(1) 的可逆方向）。 -/
example (f : ℕ → ℕ) (h : ℕ → ℕ) (hh : h ∘ f = id) : Function.Injective f := by
  have key : ∀ x, h (f x) = x := fun x => congrFun hh x
  intro x y hxy
  calc x = h (f x) := (key x).symm
    _ = h (f y) := by rw [hxy]
    _ = y := key y

/-- 单射保持：复合单则前段单。 -/
example (f g : ℕ → ℕ) (h : Function.Injective (g ∘ f)) :
    Function.Injective f := fun x y hxy =>
      h (show g (f x) = g (f y) from congrArg g hxy)

/-- 逆像保交（书 2.5.11(2)）：f⁻¹[A ∩ B] = f⁻¹[A] ∩ f⁻¹[B] 双向。 -/
example (f : ℕ → ℕ) (A B : Set ℕ) :
    f ⁻¹' (A ∩ B) = f ⁻¹' A ∩ f ⁻¹' B := by
  ext x
  exact ⟨fun hx => ⟨hx.1, hx.2⟩, fun hx => ⟨hx.1, hx.2⟩⟩

/-! ## 回到 2.2.2 例：幂和三兄弟的机器判定 -/

/-- S₁(n) = n(n+1)/2 的 n = 5 实例。 -/
example : ∑ k ∈ Finset.range 5, (k + 1) = 5 * 6 / 2 := by
  norm_num [Finset.sum_range_succ]

/-- S₂(n) = n(n+1)(2n+1)/6 的 n = 4 实例。 -/
example : ∑ k ∈ Finset.range 4, (k + 1) ^ 2 = 4 * 5 * 9 / 6 := by
  norm_num [Finset.sum_range_succ]
