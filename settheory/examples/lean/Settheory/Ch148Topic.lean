import Mathlib.Data.Fintype.Card

/-!
# 第 148 章 · 收官：有限三轴对照表

这里只证明教程索引中的有限关系，不声称形式化大基数、力迫或决定性定理。
-/

/-- 三轴使用同一组六个索引；数学内容见第 148 章正文。 -/
structure AxisEntry where
  strength : Fin 6
  forcing : Fin 6
  regularity : Fin 6
  deriving DecidableEq, Repr

/-- 第 i 行把三个轴的第 i 个教学阶段对齐。 -/
def closingAxis (i : Fin 6) : AxisEntry := ⟨i, i, i⟩

theorem closingAxis_coherent (i : Fin 6) :
    (closingAxis i).strength = i ∧
    (closingAxis i).forcing = i ∧
    (closingAxis i).regularity = i := by
  exact ⟨rfl, rfl, rfl⟩

theorem six_axis_rows : Fintype.card (Fin 6) = 6 := by
  decide

theorem first_and_last_rows :
    closingAxis 0 = ⟨0, 0, 0⟩ ∧ closingAxis 5 = ⟨5, 5, 5⟩ := by
  decide
