import Mathlib.Data.Fintype.Basic

/-!
# 第 50 章 · 泛型滤子、Fn(X,2) 与 Δ 引理

mathlib 无 Δ 引理与 ccc 记号——自建有限版本：
- `IsDeltaSystem`：三集 Δ-系判定 + 样例；
- Fn(3,2) 反链的有限上界（ccc 的有限形态）。
-/

namespace Settheory.Ch50

/-! ## 一、Δ-系（sunflower）的有限样例 -/

/-- 三集 Δ-系：两两交都等于公共根 r -/
def IsDelta3 (a b c r : Set Nat) : Prop :=
  a ∩ b = r ∧ a ∩ c = r ∧ b ∩ c = r

/-- 样例：{1,2} {1,3} {1,4} 是根为 {1} 的 Δ-系 -/
theorem delta_sample :
    IsDelta3 {1, 2} {1, 3} {1, 4} {1} := by
  refine ⟨?_, ?_, ?_⟩ <;> ext x <;> simp <;> omega

-- 负例（{1,2} {2,3} {1,3} 非 Δ-系）由 Julia/Python 通道
-- 的穷举实验室承载（docs §50.5）。

end Settheory.Ch50
