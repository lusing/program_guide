-- 第 59 章：归纳与递归的构造性面貌（Makinson Ch4）
-- 结构递归是 Agda 的原生范式：List、length、append、length-append 定理；
-- Fibonacci；燃料版 Ackermann（良基递归的可判替身）。
module Ch59_induction where

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong)

-- ---------- 结构递归的原生地 ----------

data List (A : Set) : Set where
  []   : List A
  cons : A → List A → List A      -- 头-尾唯一分解 → length 合法

length : List ℕ → ℕ
length [] = zero
length (cons _ xs) = suc (length xs)

append : List ℕ → List ℕ → List ℕ
append [] ys = ys
append (cons x xs) ys = cons x (append xs ys)

-- ---------- 结构归纳：length (xs ++ ys) = length xs + length ys ----------

-- 唯一可分解性（cons 的头-尾分解唯一）使这个定义合法；
-- 证明对 xs 结构归纳：cons 情形 suc (a + b) 与目标定义相等。
length-append : (xs ys : List ℕ) → length (append xs ys) ≡ length xs + length ys
length-append [] ys = refl
length-append (cons x xs) ys = cong suc (length-append xs ys)

-- ---------- Fibonacci（累积递归，结构终止自动通过） ----------

fib : ℕ → ℕ
fib zero = zero
fib (suc zero) = suc zero
fib (suc (suc k)) = fib (suc k) + fib k

w-fib10 : fib 10 ≡ 55
w-fib10 = refl

w-fib15 : fib 15 ≡ 610
w-fib15 = refl

-- ---------- 燃料版 Ackermann（每次递归都耗一份燃料 → 终止可判） ----------

ackf : ℕ → ℕ → ℕ → ℕ
ackf f zero n = suc n
ackf (suc f) (suc m) zero = ackf f m (suc zero)
ackf (suc f) (suc m) (suc n) = ackf f m (ackf f (suc m) n)
ackf zero (suc m) n = zero        -- 燃料尽：哑值（足够燃料时到不了这行）

w-ack23 : ackf 20 2 3 ≡ 9
w-ack23 = refl

w-ack33 : ackf 120 3 3 ≡ 61
w-ack33 = refl

-- ---------- 非法递归的现场（59.4.2 的反例） ----------

-- 若用拼接定义 length（length (xs ++ ys) = length xs + length ys 作为
-- **定义**），终止检查器当场拒绝：xs ++ ys 的分解不唯一。
-- Agda 的终止检查器就是"唯一可分解性"的日常机器裁判。
