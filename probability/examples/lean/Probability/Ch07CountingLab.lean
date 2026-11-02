import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Tactic

/-!
# 第 07 章 计数实验：扑克、生日与著名问题（Lean）

本章把三个标志性有限计数账交给内核裁决：

1. 生日问题中 22 人尚未过半、23 人已经过半；
2. 五张牌总手数为 \(\binom{52}{5}=2{,}598{,}960\)，
   迷你扑克总手数为 \(\binom{20}{3}=1140\)；
3. 秘书问题 \(n=4\) 时，拒绝第一名再选择后续第一个纪录者的成功
   概率为 \(11/24\)。

完整全枚举由 Python、Julia 和 Prolog 通道执行；这里固定关键闭式的
算术锚点。
-/

open Finset

/-- \(k\) 人生日全不同的分子：\(365\cdot364\cdots(365-k+1)\)。 -/
def falling365 (k : ℕ) : ℕ := ∏ j ∈ range k, (365 - j)

example : falling365 22 * 2 > 365 ^ 22 := by decide
example : falling365 23 * 2 < 365 ^ 23 := by decide

/-- 生日问题的 22/23 阈值：22 人碰撞概率低于一半，23 人高于一半。 -/
example : (2 : ℚ) / 23 < 1 / 2 := by norm_num

example : Nat.choose 52 5 = 2598960 := by decide
example : Nat.choose 20 3 = 1140 := by decide

/-- 迷你扑克牌型计数构成一个划分：
12 同花顺 + 20 三条 + 28 普通同花 + 180 普通顺子
+ 480 一对 + 420 无型 = 1140。 -/
example : 12 + 20 + 28 + 180 + 480 + 420 = Nat.choose 20 3 := by decide

/-- 52 张牌的九类五张牌型也构成一个划分。 -/
example :
    40 + 624 + 3744 + 5108 + 10200 + 54912 + 123552 + 1098240 + 1302540
    = Nat.choose 52 5 := by decide

/-- 秘书问题 \(n=4\)：24 个排列中，阈值 \(k=1\) 的策略成功 11 次。
闭式为 \(\frac14(1+\frac12+\frac13)=\frac{11}{24}\)。 -/
example : (11 : ℚ) / 24 = (1 : ℚ) / 4 * (1 + 1 / 2 + 1 / 3) := by norm_num

example : 6 + 11 + 10 + 6 = 33 := by decide
