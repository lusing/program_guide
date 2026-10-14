import Mathlib.Order.BooleanAlgebra.Basic
import Mathlib.Data.Nat.Basic

/-!
# 第 55 章 · 绝对性补篇：Lévy 层级与反射

自建 Σ₁ 层级谓词 + 向上保持的逻辑骨架 + HF 的 Δ₀ 绝对性样本。
-/

namespace Settheory.Ch55

/-! ## 一、Σ₁ 公式的语法谓词（Lévy 层级的骨架） -/

/-- 一阶公式的简化 AST（命题骨架——只跟踪量词层数） -/
inductive Form where
  | atom : Form                     -- Δ₀ 原子
  | ex : Form → Form                -- ∃ 量词（+1 层）
  | all : Form → Form               -- ∀ 量词（+1 层）

/-- Lévy 层数 -/
def depth : Form → Nat
  | .atom => 0
  | .ex φ => depth φ + 1
  | .all φ => depth φ + 1

/-- Σ₁ 判定：层数恰 1 -/
def IsSigma1 (φ : Form) : Prop := depth φ = 1

/-- Δ₀ 判定 -/
def IsDelta0 (φ : Form) : Prop := depth φ = 0

/-! ## 二、Δ₀ 的传递绝对性（样本形式） -/

/-- 传递宇宙对的骨架（M ⊆ N 且 M 的元素都在 N 的秩内） -/
def Delta0Absolute (M N : Type) (P : M → Prop) (Q : N → Prop)
    (emb : M → N) : Prop :=
  ∀ m : M, P m ↔ Q (emb m)

/-- Δ₀ 绝对性的逻辑骨架：原子在嵌入下不变 ⟹ 绝对 -/
theorem delta0_absolute_trivial {M N : Type} (emb : M → N)
    (P : M → Prop) (Q : N → Prop)
    (h : ∀ m, P m ↔ Q (emb m)) :
    Delta0Absolute M N P Q emb := h

/-! ## 三、Σ₁ 向上保持（Viale A.1 Prop 的逻辑形态） -/

/-- Σ₁ 的向上方向：σ = ∃x ψ(x)；M ⊆ N、参数在 M、
    M ⊨ σ ⟹ N ⊨ σ（见证留在 M） -/
theorem sigma1_upward {M N : Type} (emb : M → N)
    (ψ : M → M → Prop) (ψ' : N → N → Prop)
    (hcompat : ∀ a w : M, ψ a w ↔ ψ' (emb a) (emb w))
    (a : M) (w : M) (hw : ψ a w) :
    ∃ w' : N, ψ' (emb a) w' := by
  exact ⟨emb w, (hcompat a w).mp hw⟩

end Settheory.Ch55
