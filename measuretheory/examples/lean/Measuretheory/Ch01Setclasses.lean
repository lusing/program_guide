import Mathlib.MeasureTheory.PiSystem
import Mathlib.MeasureTheory.Measure.MeasureSpace

/-!
# 第 01 章 集合运算与集类（Lean）

严书 §1.1。手工给出集环/集代数/半环的谓词定义并证明其蕴含关系，
再用 mathlib 的 `IsPiSystem` 与 `MeasurableSpace.generateFrom`
锚定"生成 σ-代数"的最小性。有限宇宙上的枚举实验交给
julia/python/prolog 通道，这里做一般定理。
-/

open MeasureTheory

section HandClasses

variable {α : Type*}

/-- 集环（ring of sets）：含空集，对差与并封闭。 -/
def IsSetRing (C : Set (Set α)) : Prop :=
  ∅ ∈ C ∧ ∀ A ∈ C, ∀ B ∈ C, A \ B ∈ C ∧ A ∪ B ∈ C

/-- 集代数（algebra of sets）：含全集，对补与并封闭。 -/
def IsSetAlgebra (C : Set (Set α)) : Prop :=
  Set.univ ∈ C ∧ (∀ A ∈ C, Aᶜ ∈ C) ∧ (∀ A ∈ C, ∀ B ∈ C, A ∪ B ∈ C)

/-- 半环（semiring of sets，严书定义）：∅ 属于 C；A, B ∈ C 蕴含
A ∩ B ∈ C；A, B ∈ C 时 A \ B 可写成 C 中有限个两两不交集合之并。 -/
def IsSetSemiring (C : Set (Set α)) : Prop :=
  ∅ ∈ C ∧ ∀ A ∈ C, ∀ B ∈ C, A ∩ B ∈ C ∧
    ∃ (n : ℕ) (D : Fin n → Set α), (∀ i, D i ∈ C) ∧ (∀ i j, i ≠ j → Disjoint (D i) (D j)) ∧
      A \ B = ⋃ i, D i

/-- 集代数必是集环：∅ = Ωᶜ；A \ B = (Aᶜ ∪ B)ᶜ；并由定义直接有并封闭。 -/
theorem setAlgebra_isRing {C : Set (Set α)} (h : IsSetAlgebra C) : IsSetRing C := by
  obtain ⟨huniv, hcomp, hunion⟩ := h
  have hempty : ∅ ∈ C := by
    have : (∅ : Set α) = Set.univᶜ := Set.compl_univ.symm
    rw [this]
    exact hcomp _ huniv
  refine ⟨hempty, fun A hA B hB => ⟨?_, hunion A hA B hB⟩⟩
  have hAc : Aᶜ ∈ C := hcomp A hA
  have hunion2 : Aᶜ ∪ B ∈ C := hunion _ hAc _ hB
  have heq : A \ B = (Aᶜ ∪ B)ᶜ := by
    ext x; simp
  rw [heq]
  exact hcomp _ hunion2

end HandClasses

section GenerateFrom

variable {α : Type*}

/-- 生成 σ-代数的最小性：若集类 S 的每个成员都在可测空间 m 中可测，
则 σ(S) ⊆ m。 -/
example (S : Set (Set α)) (m : MeasurableSpace α)
    (h : ∀ t ∈ S, m.MeasurableSet' t) :
    MeasurableSpace.generateFrom S ≤ m :=
  MeasurableSpace.generateFrom_le h

/-- 集类中的集合当然在它生成的 σ-代数中可测。 -/
example (S : Set (Set α)) (t : Set α) (ht : t ∈ S) :
    MeasurableSet[@MeasurableSpace.generateFrom α S] t :=
  MeasurableSpace.measurableSet_generateFrom ht

/-- 区间族 {(a, b]} 是 π-系（对交封闭）——Lebesgue-Stieltjes 理论的起点集类。

注意：2026 版 mathlib 的 `IsPiSystem` 采用"非空交封闭"约定
（`(s ∩ t).Nonempty → s ∩ t ∈ C`），比严书的标准 π-系定义弱；
下例证的是标准版本，Nonempty 前提直接丢弃。 -/
example : IsPiSystem {s : Set ℝ | ∃ a b : ℝ, s = Set.Ioc a b} := by
  intro s hs t ht _
  obtain ⟨a, b, rfl⟩ := hs
  obtain ⟨c, d, rfl⟩ := ht
  show ∃ a' b' : ℝ, Set.Ioc a b ∩ Set.Ioc c d = Set.Ioc a' b'
  exact ⟨max a c, min b d, Set.Ioc_inter_Ioc⟩

end GenerateFrom
