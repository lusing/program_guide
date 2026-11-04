import Mathlib.Tactic
import Mathlib.SetTheory.ZFC.Rank

/-!
# 第 144 章 基础公理与良基归纳（Lean）

良基归纳/递归在 Lean 中是核心原语（`Acc`/`WellFounded.fix`），
∈-良基性由 rank 的严格下降保证——书 7.5-7.6 的机器化。
-/

/-! ## 良基归纳 = 语言原语 -/

/- `WellFounded.fix`：对任意良基关系 r 的递归算子——书 7.6.6
（良基递归定理）的 Lean 形态。 -/
#check @WellFounded.fix

/- 良基归纳原理： -/
#check @WellFounded.induction

example (α : Type) (r : α → α → Prop) (hwf : WellFounded r)
    (P : α → Prop) (h : ∀ a, (∀ b, r b a → P b) → P a) : ∀ a, P a :=
  fun a => WellFounded.induction hwf a h

/-! ## ∈ 的良基性（书 7.2.10/7.5.3） -/

/- rank 的严格下降（第 143 章 ZFSet.rank_lt_of_mem）给出 ∈-良基：
若 x ∈ x 或存在 ∈-无穷下降链，则秩严格下降的无穷链——矛盾。 -/
#check @ZFSet.rank_lt_of_mem

/- Con(ZF−) → Con(ZF)（书 7.5.3 相对一致性）——mathlib 不直接
陈述此元定理（元理论机器化边界），但 ∈-良基在 ZFSet 内按构造
成立。 -/

/-! ## 传递闭包（书 7.2.12-7.2.14） -/

/- mathlib 的 ZFSet 没有直接的 trcl——但 PSet→ZFSet 的商构造
天然传递（rank 沿 ∈ 下降即 trcl 的良基性）。 -/
#check @ZFSet.rank

/-! ## Mostowski 塌缩预告（书 7.6.15） -/

/- 良基外延关系 (X,R) ≅ (M,∈) 的唯一同构——PSet 到 ZFSet 的
商映射就是它的实例：把"树形前置集"塌成"传递集合"。 -/
#check @Quot.mk
