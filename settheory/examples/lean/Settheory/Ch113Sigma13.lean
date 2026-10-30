import Mathlib.Data.List.Basic

/-!
# 第 113 章 · Σ¹₃ 集合与广泛贝尔特性

锚点（有限影子）：
- `bkLT`/`bk_snoc`/`bk_take_step`/`bk_nil_max`：布劳威尔-克林序
  （引理 3.20 的机制核）——延伸者更小，树枝即严格递降链，ε 是最大元
  （定理 3.15(3)(a)）；
- `caught`/`pT`/`pS`/`catch_pT_of_zero`/`catch_pS_of_one`：双树互补
  （定理 3.19）——首位分裂对在一切深度全覆盖：「广泛」的有限影子；
- `no_dual_catch`：根部独占交（T ∩ T* = {ε}）⟹ 投影不交；
- `catch_shrink`：外延稳定性——细化实数被接住 ⟹ 截断（旧实数）仍被接住。

本体（Martin-Solovay 树、Magidor 定理、Silver 定理、Oxtoby 赛事、
FMW 三等价）留在正文 docs/113-sigma13.md。
-/

namespace Settheory.Ch113Sigma13

/-- 布劳威尔-克林序 s <_BK t：递归扫描双表头——右表先尽（t ⊏ s）为真；
表头相等则下移一位；表头相异则比大小（首异位 s(k) < t(k)）。 -/
def bkLT : List Nat → List Nat → Bool
  | [], _ => false
  | _ :: _, [] => true
  | s₀ :: s', t₀ :: t' => if s₀ = t₀ then bkLT s' t' else decide (s₀ < t₀)

/-- 引理 3.20 的核心一步：s ++ [a] <_BK s（延伸者更小）。 -/
theorem bk_snoc (s : List Nat) (a : Nat) : bkLT (s ++ [a]) s = true := by
  induction s with
  | nil => simp [bkLT]
  | cons b s' ih =>
    have e1 : (b :: s') ++ [a] = b :: (s' ++ [a]) := by simp
    rw [e1]
    have e2 : bkLT (b :: (s' ++ [a])) (b :: s') = bkLT (s' ++ [a]) s' := by
      simp only [bkLT, reduceIte]
    rw [e2]
    exact ih

/-- 自建方程（108 章纪律：不依赖外部 take 引理形态）：
k < x.length 时 take (k+1) x = take k x ++ [x.getD k 0]。 -/
theorem take_step (x : List Nat) : ∀ k < x.length,
    x.take (k + 1) = x.take k ++ [x.getD k 0] := by
  induction x with
  | nil => intro k hk; simp at hk
  | cons a t ih =>
    intro k hk
    match k with
    | 0 => simp
    | m + 1 =>
      have hm : m < t.length := by simpa using hk
      have e := ih m hm
      show a :: t.take (m + 1) = (a :: t.take m) ++ [t.getD m 0]
      rw [List.cons_append, e]

/-- 沿实数前缀链每步严格递降：take (k+1) x <_BK take k x。 -/
theorem bk_take_step (x : List Nat) (k : Nat) (hk : k < x.length) :
    bkLT (x.take (k + 1)) (x.take k) = true := by
  rw [take_step x k hk, bk_snoc]

/-- ε 是布劳威尔-克林序下的最大元（定理 3.15(3)(a)）。 -/
theorem bk_nil_max (s : List Nat) (hs : s ≠ []) : bkLT s [] = true := by
  match s with
  | [] => exact absurd rfl hs
  | b :: t => rfl

/-- caught p x：实数 x 的每一段前缀都被树 p 接住（π[p] 的有限替身）。 -/
def caught (p : List Nat → Bool) (x : List Nat) : Prop :=
  ∀ k ≤ x.length, p (x.take k) = true

/-- 稳定对之一：首位 0 树（T = {ε} ∪ 0⌢2^<ω）。 -/
def pT : List Nat → Bool
  | [] => true
  | b :: _ => decide (b = 0)

/-- 稳定对之二：首位 1 树（T* = {ε} ∪ 1⌢2^<ω）。 -/
def pS : List Nat → Bool
  | [] => true
  | b :: _ => decide (b = 1)

/-- 定理 3.19 的「广泛」面：首位 0 的实数在一切深度都被 pT 接住。 -/
theorem caught_pT_of_zero (t : List Nat) : caught pT (0 :: t) := by
  intro k _
  match k with
  | 0 => rfl
  | m + 1 => rfl

/-- 同上：首位 1 的实数在一切深度都被 pS 接住。 -/
theorem caught_pS_of_one (t : List Nat) : caught pS (1 :: t) := by
  intro k _
  match k with
  | 0 => rfl
  | m + 1 => rfl

/-- 根部独占交（T ∩ T* = {ε}）⟹ 投影不交：首位不可能既是 0 又是 1。 -/
theorem no_dual_catch (b : Nat) (t : List Nat) :
    ¬ (caught pT (b :: t) ∧ caught pS (b :: t)) := by
  intro ⟨h1, h2⟩
  have e1 : pT [b] = true := h1 1 (by simp)
  have e2 : pS [b] = true := h2 1 (by simp)
  simp only [pT, pS] at e1 e2
  rw [decide_eq_true_iff] at e1 e2
  omega

/-- 自建方程：k ≤ x.length 时 take k (x ++ [a]) = take k x
（细化的前段仍是原前段）。 -/
theorem take_append_le (x : List Nat) : ∀ (a : Nat) (k : Nat), k ≤ x.length →
    (x ++ [a]).take k = x.take k := by
  induction x with
  | nil => intro a k hk; match k with
    | 0 => rfl
    | m + 1 => simp at hk
  | cons b t ih =>
    intro a k hk
    match k with
    | 0 => rfl
    | m + 1 =>
      have hm : m ≤ t.length := Nat.le_of_succ_le_succ hk
      show b :: (t ++ [a]).take m = b :: t.take m
      rw [ih a m hm]

/-- 外延稳定性（力迫扩张影）：新实数 x ++ [a] 被接住 ⟹ 旧实数 x 仍被接住。
有限影子中「扩张」即细化一层——定理 3.19 (3) 的 ⊩ 面。 -/
theorem caught_shrink (p : List Nat → Bool) (x : List Nat) (a : Nat)
    (h : caught p (x ++ [a])) : caught p x := by
  intro k hk
  rw [← take_append_le x a k hk]
  exact h k (Nat.le_trans hk (by simp))

/-- 交接样本：bkLT 在二元窗口上的取值（0 < 1 决定首异位方向）。 -/
example : bkLT [0, 1] [1, 0] = true := by rfl

example : bkLT [1, 0] [0, 1] = false := by rfl

example : bkLT [0, 0, 1] [0, 0] = true := by rfl

end Settheory.Ch113Sigma13
