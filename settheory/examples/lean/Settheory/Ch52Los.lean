import Mathlib.Order.BooleanAlgebra.Basic
import Mathlib.Data.Set.Basic
import Mathlib.Tactic

/-!
# 第 52 章 · 商、满性与 Łoś 定理

自建满性骨架与两个有限形态定理：
- Bool 上一切（有限）B-值模型满；
- 混合性质的最小实例（钻石代数 2 元反链拼装）。
-/

namespace Settheory.Ch52

/-! ## 一、Bool 上的满性（有限 sup = max） -/

/-- 有限布尔值模型的"存在见证"：sup 被某个元素达到 -/
theorem bool_full {M : Type*} (f : M → Bool) (h : ∃ m, f m = true) :
    ∃ m, f m = true ∧ ∀ m', (f m' = true → f m = true) := by
  obtain ⟨m, hm⟩ := h
  exact ⟨m, hm, fun _ _ => hm⟩

/-! ## 二、混合性质的最小实例（钻石代数） -/

/-- 钻石代数：0 < u, v < 1，u ⊥ v -/
inductive Dia
  | bot | u | v | top

def dmeet : Dia → Dia → Dia
  | .bot, _ => .bot
  | _, .bot => .bot
  | .u, .u => .u
  | .v, .v => .v
  | .top, x => x
  | x, .top => x
  | _, _ => .bot

/-- 混合见证选择器：按 (u-分量模式, v-分量模式) 选 b -/
def mixb : Dia → Dia → Dia
  | .bot, .bot => .bot
  | .u, .bot => .u
  | .bot, .v => .v
  | _, _ => .top

theorem mix_dia (a_u a_v : Dia) :
    ∃ b : Dia, dmeet b .u = dmeet a_u .u ∧ dmeet b .v = dmeet a_v .v := by
  refine ⟨mixb (dmeet a_u .u) (dmeet a_v .v), ?_, ?_⟩ <;>
    cases a_u <;> cases a_v <;> rfl

end Settheory.Ch52
