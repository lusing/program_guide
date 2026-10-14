import Mathlib.Data.Finset.Card
import Mathlib.Tactic

/-!
# 第 61 章 · 概率：有限空间、条件、辛普森与贝叶斯（Makinson Ch6）

骰子对的条件概率（整数比精确呈现）、辛普森八比值、贝叶斯
基础率谬误的精确算术（分数）、期望三马例。
-/

namespace Settheory.Ch61

open Finset

-- ---------- 骰子对：条件概率的整数比 ----------

def dice36 : Finset (ℕ × ℕ) :=
  (Finset.range 6).product (Finset.range 6)

def pair (s : ℕ × ℕ) : ℕ := s.1 + 1 + (s.2 + 1)

-- 事件 B：和为 5；事件 A：至少一枚是 3
def B5 : Finset (ℕ × ℕ) := dice36.filter (fun s => pair s = 5)
def A3 : Finset (ℕ × ℕ) := dice36.filter (fun s =>
  (s.1 + 1 = 3) || (s.2 + 1 = 3))

example : B5.card = 4 := by decide
example : A3.card = 11 := by decide
example : (B5 ∩ A3).card = 2 := by decide

-- p(A|B) = 2/4 = 1/2（比 p(A) = 11/36 大）
example : (B5 ∩ A3).card * 2 = B5.card := by decide
-- p(B|A) = 2/11
example : (B5 ∩ A3).card * 11 = A3.card * 2 := by decide

-- ---------- 辛普森八比值（26 名申请者） ----------

-- 女 CS 2/8 > 男 CS 1/5；女数学 4/5 > 男数学 6/8；合计女 6/13 < 男 7/13
example : (2 : ℕ) * 5 > 1 * 8 := by decide
example : (4 : ℕ) * 8 > 6 * 5 := by decide
example : (6 : ℕ) * 13 < 7 * 13 := by decide

-- ---------- 贝叶斯：基础率谬误的精确分数 ----------

-- 癌症例：p(C|P) = 0.01·1/(0.01·1 + 0.2·0.99) = 5/104 ≈ 0.048
example : (5 : ℕ) * 208 = 104 * 10 := by decide

-- HIV 例：0.9·0.15/(0.9·0.15 + 0.03·0.85) = 270/321 ≈ 0.841
example : (270 : ℕ) * 1605 = 1350 * 321 := by decide

-- 接线员例：Clarice 的后验 = 270/(198+259+270) = 270/727
example : (60 : ℕ) * 33 + 70 * 37 + 90 * 30 = 727 * 10 := by decide

-- ---------- 期望三马例：12·0.1 − 1·0.3 − 1·0.6 = 0.3 ----------

-- 以 0.1 为单位：12 − 3 − 6 = 3
example : (12 : ℕ) - 3 - 6 = 3 := by decide

end Settheory.Ch61
