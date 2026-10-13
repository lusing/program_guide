import Mathlib.SetTheory.Ordinal.Basic
import Mathlib.SetTheory.Cardinal.Basic

/-!
# 基础模块：mathlib 钉版连通性检查
-/

/-- 基数通道可达 -/
example : Cardinal.mk (Fin 3) = 3 := by simp
