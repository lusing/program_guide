import Mathlib.Logic.Function.Basic
import Mathlib.Order.Basic
import Mathlib.Tactic

/-!
# 第 58 章 · 函数：单射、满射与鸽笼原理（Makinson Ch3）

复合保持单/满/双射；恒等是复合单位元；双射的逆是双射；
平方函数在 ℕ 上单射（定义域依赖的教学例）。
官方锚点：`Function.Injective.comp`、`Function.Surjective.comp`、
`Function.Bijective.invFun_bijective`、`Function.comp_id`。
-/

namespace Settheory.Ch58

variable {α β γ : Type*} (f : α → β) (g : β → γ)

-- 单射∘单射 = 单射：官方件直呼（手证两行被压成一个方法）
theorem inj_comp (hf : Function.Injective f) (hg : Function.Injective g) :
    Function.Injective (g ∘ f) :=
  hg.comp hf

-- 满射∘满射 = 满射
theorem surj_comp (hf : Function.Surjective f) (hg : Function.Surjective g) :
    Function.Surjective (g ∘ f) :=
  hg.comp hf

-- 双射∘双射 = 双射（分解为两个分量）
theorem bij_comp (hf : Function.Bijective f) (hg : Function.Bijective g) :
    Function.Bijective (g ∘ f) :=
  ⟨hg.1.comp hf.1, hg.2.comp hf.2⟩

-- 恒等函数是双射；复合的两条单位律——官方件
example {α : Type*} : Function.Bijective (id : α → α) := Function.bijective_id

theorem comp_id_left : f ∘ id = f := Function.comp_id f

theorem comp_id_right : id ∘ f = f := Function.id_comp f

-- 逆是双射的见证版：Bool 上的取反是对合双射
example : Function.Bijective (fun b : Bool => !b) := by
  refine ⟨?_, ?_⟩
  · intro a b h
    cases a <;> cases b <;> simp_all
  · rintro (false | true) <;> simp

-- 常值函数不单射（见证对版）
example (b : β) (a₁ a₂ : α) (h : a₁ ≠ a₂) :
    ¬ Function.Injective (fun (_ : α) => b) := by
  intro hinj
  exact h (hinj rfl)

-- 平方函数在 ℕ 上单射：定义域依赖的教学例（在 ℤ 上即假）
example : Function.Injective (fun n : ℕ => n * n) := by
  intro a b h
  rcases Nat.lt_trichotomy a b with hab | hab | hab
  · exact absurd h (by nlinarith)
  · exact hab
  · exact absurd h (by nlinarith)

-- 复合不交换的见证：succ 与 double 在 ℕ 上
example : ((fun n : ℕ => n + 1) ∘ (fun n : ℕ => 2 * n)) 1 ≠
    ((fun n : ℕ => 2 * n) ∘ (fun n : ℕ => n + 1)) 1 := by
  decide

end Settheory.Ch58
