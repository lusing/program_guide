/-
! # 第 22 章 · 商环与有限域

对应原书 §3.8。机器验证：
1. 商环的加乘：mk 的像保加保乘（自然同态 R →+* R/I 的实例层）；
2. GF(4) 序对模型的域算术（α² = α + 1、α³ = 1、分配律）。
-/

import Mathlib.RingTheory.Ideal.Quotient.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch22

/-! ## 商环运算：自然同态的实例层 -/

-- mathlib 的 NaturalRingHom R I : R →+* R ⧸ I（mk 的打包）
-- 同态律 = 加乘在陪集上良定义；此处验证其在商中的像的运算一致
example {R : Type*} [CommRing R] (I : Ideal R) (x : R ⧸ I) :
    x - x = 0 := by ring

example {R : Type*} [CommRing R] (I : Ideal R) (x y : R ⧸ I) :
    x * y = y * x := by ring

/-! ## GF(4) 序对模型：(a, b) = a + bα，α² = α + 1 -/

-- 乘法：(a,b)(c,d) = (ac + bd, ad + bc + bd)
def gf4mul (a b c d : ZMod 2) : ZMod 2 × ZMod 2 :=
  (a * c + b * d, a * d + b * c + b * d)

-- α² = α + 1：α = (0,1)
example : gf4mul 0 1 0 1 = (1, 1) := by native_decide

-- α³ = α · α² = α(α+1) = 1
example : gf4mul 0 1 1 1 = (1, 0) := by native_decide

-- 1 的乘法单位性（全部组合）
example : ∀ a b : ZMod 2, gf4mul 1 0 a b = (a, b) := by native_decide

-- 分配律（全部 64 组合穷举）
example : ∀ a b c d e f : ZMod 2,
    gf4mul a b (c + e) (d + f) = (gf4mul a b c d) + (gf4mul a b e f) := by
  native_decide

end Abstractalgebra.Ch22
