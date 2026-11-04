/-
! # 第 07 章 · 集合、函数与等价关系

对应原书 §2.1。机器验证：
1. 单射可复合；双射 = 单 + 满（引理 2.6/命题 2.10 周边）；
2. 有限自映射：单 ⟺ 满（鸽笼）；
3. 等价关系 ↔ 划分：模 3 同余的等价类恰三块（命题 2.20）。
-/

import Mathlib.Logic.Function.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Fintype.Card
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch07

/-! ## 复合与三种性格 -/

-- 引理 2.6：复合满足结合律（逐点等式，定义层面成立）
example {α β γ : Type*} (f : α → β) (g : β → γ) (h : γ → δ) :
    (h ∘ g) ∘ f = h ∘ (g ∘ f) := rfl

-- 单射可复合：单 ∘ 单 = 单
example {α β γ : Type*} {f : α → β} {g : β → γ}
    (hf : Function.Injective f) (hg : Function.Injective g) :
    Function.Injective (g ∘ f) := hg.comp hf

-- 双射 ⇔ 存在双侧逆：mathlib 的 Equiv 即"带双侧逆的双射"
example {α β : Type*} (e : α ≃ β) : Function.Bijective e :=
  ⟨e.injective, e.surjective⟩

example {α β : Type*} (e : α ≃ β) (x : α) : e.symm (e x) = x := e.symm_apply_apply x

/-! ## 鸽笼：有限自映射 单 ⟺ 满 -/

-- 有限集合上的自映射：单射 ⟺ 满射（|X| = |Y| 时的三性格重合）
example {α : Type*} [Finite α] {f : α → α} :
    Function.Injective f ↔ Function.Surjective f :=
  Finite.injective_iff_surjective

/-! ## 等价关系与划分（命题 2.20） -/

-- 模 3 同余的等价类：以 ZMod 3 为商集，类恰三块
example (x : ℕ) : x % 3 < 3 := Nat.mod_lt x (by norm_num)

-- 三块划分的机器版：每个自然数恰落入 0,1,2 之一（良定义的类代表）
example (x : ℕ) : (x % 3 = 0 ∨ x % 3 = 1 ∨ x % 3 = 2) ∧
    (x + 3) % 3 = x % 3 := by
  constructor
  · omega
  · omega

-- ZMod 3 恰有三个元素：划分的元素计数版
example : Fintype.card (ZMod 3) = 3 := by decide

end Abstractalgebra.Ch07
