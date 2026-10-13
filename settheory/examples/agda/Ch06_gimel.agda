-- 第 06 章 基数算术：gimel 函数的有限侧影
--
-- ☞(κ) = κ^(cf κ)（gimel 函数）决定连续统函数的三分支行为
-- （Jech (6.15)）。有限序数的 cf 恒为 1（正后继情形），
-- gimel 退化为恒等；无穷域的必然膨胀（κ < κ^cf κ）与
-- 有限域的免费坍缩是 gimel 戏剧的全部所在。

module Ch06_gimel where

open import Data.Nat using (ℕ; zero; suc; _^_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 有限序数的共尾数：0 的约定为 0，正有限序数 = 1（后继序数）
cf-finite : ℕ → ℕ
cf-finite zero = zero
cf-finite (suc n) = 1

gimel : ℕ → ℕ
gimel κ = κ ^ (cf-finite κ)

-- 有限域 gimel 恒等（κ^1 = κ）
gimel-1 : gimel 1 ≡ 1
gimel-1 = refl

gimel-5 : gimel 5 ≡ 5
gimel-5 = refl

gimel-0 : gimel 0 ≡ 1
gimel-0 = refl
-- 0^0 = 1（幂的空积约定；对应 κ^0 = 1 的基数律）

-- 对照（讲义）：κ = ℵ_ω 时 cf κ = ω，gimel = ℵ_ω^ω 不再坍缩
-- ——König 推论 4（κ < κ^cf κ）。有限域坍缩 / 无穷域膨胀的
-- 分界由 König 定理刻画，可计算侧影在 Python/Julia 通道。
