import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Card
import Mathlib.Data.Fintype.Basic
import Mathlib.Data.List.Basic

/-!
# 第 112 章 · Σ¹₂ 集合

锚点（有限影子）：
- `Sec`/`SecBranch`：两层树 T ⊆ 2^≤2 × Ω^≤2 的截面与树枝
  （定义 3.8 的 κ-Souslin 形态：ω×ω₁ 树的有限替身——
  第一层走实数前段、第二层走序数值前段）；
- `rho2` + `rho2_le`：截面无树枝时的赋秩函数与秩 ≤ 燃料
  （定理 3.7 的机关「良基 ⟺ 保序映射到序数」+ 引理 3.8
  高度比较的数值面）；
- `compl_inter_empty`/`compl_union_full`：补集之交空、并全
  （博雷尔代码补运算的核——引理 3.15/3.16 绝对性的基件）；
- 样本账：两层树 T_b 的截面/投影/秩的决定性核算。
本体（定理 3.7-3.14、引理 3.8-3.19、推论 3.6-3.12）留在正文。
-/

namespace Settheory.Ch112

open Finset List

/-! ## 一、两层树：截面与树枝（定义 3.8 的有限替身） -/

/-- 截面：T(α) = {h | (α↾|h|, h) ∈ T}——第二层（序数值前段）的树。 -/
def Sec (T : Finset (List ℕ × List ℕ)) (a : List ℕ) : Finset (List ℕ) :=
  (T.filter (fun p => p.1 = a.take p.2.length)).image Prod.snd

/-- 截面有全长树枝（长度 2：前段与全长两层都在截面中；
序数值自有限供给 {0,1}——「分支坐标跑遍 ω₁」的影子，
显式枚举四种组合）。 -/
def SecBranch (T : Finset (List ℕ × List ℕ)) (a : List ℕ) : Prop :=
  ([0] ∈ Sec T a ∧ [0, 0] ∈ Sec T a) ∨ ([0] ∈ Sec T a ∧ [0, 1] ∈ Sec T a) ∨
  ([1] ∈ Sec T a ∧ [1, 0] ∈ Sec T a) ∨ ([1] ∈ Sec T a ∧ [1, 1] ∈ Sec T a)

/-- 截面无树枝 ⟺ 良基（Π¹₁ 内核）。 -/
def SecWF (T : Finset (List ℕ × List ℕ)) (a : List ℕ) : Prop :=
  ¬ SecBranch T a

/-! ## 二、赋秩机关（定理 3.7：良基 ⟹ 秩函数） -/

/-- 秩：叶 0、内点 = 子最大 + 1；燃料封顶（沿 111 章 rho）。 -/
def rho2 (S : Finset (List ℕ)) : ℕ → List ℕ → ℕ
  | 0, _ => 0
  | f + 1, s =>
      if (s ++ [0] ∈ S) || (s ++ [1] ∈ S) then
        (max (rho2 S f (s ++ [0])) (rho2 S f (s ++ [1]))) + 1
      else 0

/-- 秩永不超过燃料（有限宇宙的「秩落在可数序数中」影子：
可数树的秩有界——Shoenfield 绝对性的资源账）。 -/
theorem rho2_le : ∀ (S : Finset (List ℕ)) (f : ℕ) (s : List ℕ), rho2 S f s ≤ f := by
  intro S f
  induction f with
  | zero => intro s; simp [rho2]
  | succ f ih =>
      intro s
      simp only [rho2]
      split
      · next hc =>
          have h0 := ih (s ++ [0])
          have h1 := ih (s ++ [1])
          omega
      · omega

/-! ## 三、补集之交空、并全（博雷尔代码补运算的核） -/

/-- 有限宇宙（Fintype）上的补：交空、并全——引理 3.15 的
补运算 A_{c'}=R−A_c 在两个模型中同样成立的核。 -/
theorem compl_inter_empty {n : ℕ} (A : Finset (Fin n)) :
    A ∩ (Finset.univ \ A) = ∅ := by
  ext x; simp

theorem compl_union_full {n : ℕ} (A : Finset (Fin n)) :
    A ∪ (Finset.univ \ A) = Finset.univ := by
  ext x; simp

/-! ## 四、样本账（决定性核算） -/

/-- 样本两层树 T_b：α=00 处截面有树枝、其余截面良基。 -/
def Tb : Finset (List ℕ × List ℕ) :=
  {([], []), ([0], [0]), ([0], [1]), ([0, 0], [0, 0]), ([0, 0], [1, 0])}

/-- T_b(00) 的截面恰为五元素（含全长 (0,0)、(1,0)）。 -/
example : Sec Tb [0, 0] = {[], [0], [1], [0, 0], [1, 0]} := by decide

/-- T_b(00) 有树枝（00 ∈ p[T_b]）。 -/
example : SecBranch Tb [0, 0] := by simp [SecBranch, Sec, Tb]

/-- T_b(01) 无树枝（良基）。 -/
example : SecWF Tb [0, 1] := by simp [SecWF, SecBranch, Sec, Tb]

/-- T_b(01) 的截面 = {[],[0],[1]}：根秩 1。 -/
example : Sec Tb [0, 1] = {[], [0], [1]} := by decide

example : rho2 (Sec Tb [0, 1]) 2 [] = 1 := by decide
example : rho2 (Sec Tb [0, 1]) 2 [0] = 0 := by decide

/-- 截面良基 ⟹ 秩有界（ρ ≤ 2 ≤ 燃料 3）。 -/
example : rho2 (Sec Tb [0, 1]) 3 [] ≤ 2 := by decide
example : rho2 (Sec Tb [1, 0]) 3 [] ≤ 2 := by decide
example : rho2 (Sec Tb [1, 1]) 3 [] ≤ 2 := by decide
example : SecWF Tb [1, 0] := by simp [SecWF, SecBranch, Sec, Tb]
example : SecWF Tb [1, 1] := by simp [SecWF, SecBranch, Sec, Tb]

end Settheory.Ch112
