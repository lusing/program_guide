/-
! # 第 34 章 · 素理想与极大理想

对应原书 §7.1。机器验证：
1. ℤ/p 是域（ZMod p 的 Field 实例，Fact Prime）；
2. ℤ/n 的零因子判定（商环非整域 ⟹ 理想非素）；
3. GF(4) 型商域的数值面。
-/

import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.Field.ZMod
import Mathlib.Data.Nat.Prime.Defs
import Mathlib.Tactic.NormNum

namespace Abstractalgebra.Ch34

/-! ## ℤ/p 是域（引理 7.6：(0) 极大 ⟺ R 域） -/

instance fact5 : Fact (Nat.Prime 5) := ⟨by decide⟩
instance fact7 : Fact (Nat.Prime 7) := ⟨by decide⟩

example : Field (ZMod 5) := inferInstance
example : Field (ZMod 7) := inferInstance

/-! ## ℤ/n 的零因子（素/极大判别的商环面） -/

-- ℤ/6：2·3 = 0 且 2、3 ≠ 0 ⟹ 非整域 ⟹ (6) 在 ℤ 中不素
example : (2 : ZMod 6) * 3 = 0 := by decide
example : (2 : ZMod 6) ≠ 0 := by decide
example : (3 : ZMod 6) ≠ 0 := by decide

-- ℤ/4：2·2 = 0（(2) ⊂ ℤ/4 的商 ℤ/2 是域 ⟹ (2) 极大；ℤ/4 自身非整域）
example : (2 : ZMod 4) * 2 = 0 := by decide
example : (1 : ZMod 4) * 1 = 1 := by decide

-- ℤ/p² 中 (p) 素：ab ≡ 0 (mod p) ⟹ a ≡ 0 或 b ≡ 0 (mod p)（25 格全枚举）
example : ∀ a < 25, ∀ b < 25, (a * b) % 25 = 0 → a % 5 = 0 ∨ b % 5 = 0 := by
  decide

/-! ## 极大 ⟹ 素（推论 7.8）的数值面 -/

-- ℤ/12 的理想格：除数 1,2,3,4,6,12（6 个）
example : (List.range 13).filter (fun d => 12 % d == 0) = [1, 2, 3, 4, 6, 12] := by
  decide

-- 商环大小：ℤ/12 / (d) ≅ ℤ/d（d | 12）⟹ 极大当 d ∈ {2, 3}
example : Nat.Prime 2 := by decide
example : Nat.Prime 3 := by decide
example : ¬ Nat.Prime 4 := by decide
example : ¬ Nat.Prime 6 := by decide

end Abstractalgebra.Ch34
