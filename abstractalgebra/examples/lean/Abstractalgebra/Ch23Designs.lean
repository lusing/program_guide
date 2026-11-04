/-
! # 第 23 章 · 一个数学旅程

对应原书 §3.9。机器验证：
1. 幻和 n(n²+1)/2 的整性（n 与 n²+1 一奇一偶）；
2. ℤ_n 型拉丁方的可解性（每行完备剩余系）；
3. Fano 平面（7 点 7 线每线 3 点）的差集构造。
-/

import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Finset.Card
import Mathlib.Tactic.Ring
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Linarith

namespace Abstractalgebra.Ch23

/-! ## 幻和的整性 -/

-- n(n²+1) 恒被 2 整除：n 偶则积偶；n 奇则 n²+1 偶（奇²=奇）
example (n : ℕ) : 2 ∣ n * (n ^ 2 + 1) := by
  rcases Nat.even_or_odd n with ⟨k, hk⟩ | ⟨k, hk⟩
  · rw [hk]; exact ⟨k * ((k + k) ^ 2 + 1), by ring⟩
  · rw [hk]; exact ⟨(2 * k + 1) * (2 * k * k + 2 * k + 1), by ring⟩

/-! ## ℤ_n 型拉丁方的行结构 -/

-- 循环群表 L(i,j) = i + j (mod 5)：每行每列可解
example : ∀ r s : ZMod 5, ∃ c : ZMod 5, r + c = s := by
  intro r s
  exact ⟨s - r, by rw [add_comm]; exact sub_add_cancel s r⟩

/-! ## Fano 平面：差集 {0,1,3} 构造 -/

def fano_line (i : ZMod 7) : Finset (ZMod 7) := {i, i + 1, i + 3}

-- 每条线恰 3 点（7 条线全查）
example : ∀ i : ZMod 7, (fano_line i).card = 3 := by decide

-- 任两点恰共一线（STS(7)：42 对点全查）
example : ∀ p q : ZMod 7, p ≠ q →
    1 = (Finset.univ.filter (fun l => p ∈ fano_line l ∧ q ∈ fano_line l)).card := by
  decide

end Abstractalgebra.Ch23
