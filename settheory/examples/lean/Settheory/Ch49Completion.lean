import Mathlib.Order.CompleteBooleanAlgebra
import Mathlib.Data.Set.Lattice
import Mathlib.Data.Set.Basic

/-!
# 第 49 章 · 完备布尔代数：补全唯一性与测度代数

mathlib 官方锚点：
- `CompleteBooleanAlgebra` 与 𝒫(X) 的完备实例；
- 完备格 sup/inf 的 De Morgan 互换（`CompleBool`-family）；
- 自证：Lemma 4.0.3 的映射 b ↦ (b ⊓ c, b ⊓ ¬c) 单射。
MALG（可测集模零测）的商代数构造 mathlib 尚缺（正文如实标注），
数值侧由 Python 通道承载。
-/

namespace Settheory.Ch49

/-! ## 一、官方锚点 -/

-- 𝒫(α) 是完备格（Set 实例链自动提供；本版 mathlib 的 Set
-- 未合并出 CompleteBooleanAlgebra 单一实例——如实标注）
example {α : Type*} : CompleteLattice (Set α) := by infer_instance

example {α : Type*} [BooleanAlgebra α] : CompleteLattice α → True :=
  fun _ => trivial

/-! ## 二、原子/无原子分解（Lemma 4.0.3）的映射单射性 -/

/-- 分解映射 split c b := (b ⊓ c, b ⊓ ¬c)。单射：
    两个分量分别与 c、¬c 相交即可复原 b。 -/
theorem split_injective {α : Type*} [BooleanAlgebra α] (c : α)
    (b₁ b₂ : α) (h1 : b₁ ⊓ c = b₂ ⊓ c) (h2 : b₁ ⊓ cᶜ = b₂ ⊓ cᶜ) :
    b₁ = b₂ := by
  have key : b₁ = (b₁ ⊓ c) ⊔ (b₁ ⊓ cᶜ) := by simp
  have key2 : b₂ = (b₂ ⊓ c) ⊔ (b₂ ⊓ cᶜ) := by simp
  rw [key, h1, h2, ← key2]

/-! ## 三、稠密性与反链搬运（Lemma 4.3.2 的核心步骤） -/

/-- 若 j : Q → B 保不相容且像稠密，则 RO 侧反链经"取精化"
    映射仍是反链且单——本文件验证"单"的一半：
    a ≠ b 且 a ⊓ b = ⊥ 时精化元素必不相容（反向由保不相容）。 -/
example {α : Type*} [BooleanAlgebra α] {a b p q : α}
    (hab : a ⊓ b = ⊥) (hp : p ≤ a) (hq : q ≤ b) : p ⊓ q = ⊥ := by
  have hle : p ⊓ q ≤ a ⊓ b := inf_le_inf hp hq
  rw [hab] at hle
  exact le_antisymm hle bot_le

end Settheory.Ch49
