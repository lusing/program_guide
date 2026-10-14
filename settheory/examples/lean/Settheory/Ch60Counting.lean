import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Data.Finset.Card
import Mathlib.Tactic

/-!
# 第 60 章 · 计数：四式选取、排列组合与重排（Makinson Ch5）

组合的对称律与帕斯卡递推（官方锚点）、杨辉三角第 6 行证书、
banana 重排公式证书、容斥的数值例。
-/

namespace Settheory.Ch60

-- 组合的对称律：官方锚点（注意方向与前提 k ≤ n）
example {n k : ℕ} (hk : k ≤ n) : Nat.choose n (n - k) = Nat.choose n k :=
  Nat.choose_symm hk

-- 帕斯卡递推 C(n+1,k+1) = C(n,k) + C(n,k+1)：官方锚点
example (n k : ℕ) :
    Nat.choose (n + 1) (k + 1) = Nat.choose n k + Nat.choose n (k + 1) :=
  Nat.choose_succ_succ' n k

-- 杨辉三角第 6 行：1 6 15 20 15 6 1
example : [Nat.choose 6 0, Nat.choose 6 1, Nat.choose 6 2, Nat.choose 6 3,
    Nat.choose 6 4, Nat.choose 6 5, Nat.choose 6 6] = [1, 6, 15, 20, 15, 6, 1] := by
  decide

-- P(6,k) 全表：1 6 30 120 360 720 720
def P (n k : ℕ) : ℕ := Nat.factorial n / Nat.factorial (n - k)

example : [P 6 0, P 6 1, P 6 2, P 6 3, P 6 4, P 6 5, P 6 6]
    = [1, 6, 30, 120, 360, 720, 720] := by
  decide

-- banana 重排：6!/(3!·2!) = 60
example : Nat.factorial 6 / (Nat.factorial 3 * Nat.factorial 2) = 60 := by
  decide

-- Turramurra：10!/(1!·2!·4!·2!·1!) = 37800
example : Nat.factorial 10 / (Nat.factorial 1 * Nat.factorial 2 *
    Nat.factorial 4 * Nat.factorial 2 * Nat.factorial 1) = 37800 := by
  decide

-- Woolloomooloo（书本数值 13!/6!·2! = 4324320；实拼写的字母账见
-- Julia/Python 通道的复核——书本自己的字母计数有出入，机器捉虫一例）
example : Nat.factorial 13 / (Nat.factorial 6 * Nat.factorial 2)
    = 4324320 := by
  decide

-- 容斥电话例：5+10+7−3−2−2+1 = 16
example : (5 : ℕ) + 10 + 7 - 3 - 2 - 2 + 1 = 16 := by
  decide

-- 重复组合：C(k+n−1, k)；10 人 6 任务 = C(15,6) = 5005 = C(15,9)
example : Nat.choose 15 6 = 5005 := by
  decide

example : Nat.choose 15 9 = 5005 := by
  decide

end Settheory.Ch60
