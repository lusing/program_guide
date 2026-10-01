----------------------------------------------------------------
-- 07 依赖类型（λP）—— Agda 侧
-- 03 章的内在式（intrinsic）写法在这里开花：索引族 + 谓词
-- Agda 的 _+_ 在【第一】参数上递归——defeq 缝隙的位置
-- 与 Coq/Lean 不同，缝合用 +-suc 的 rewrite
----------------------------------------------------------------

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Data.Nat.Properties using (+-suc)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; sym)

-- ---- ① 索引族：Vec ----

infixr 5 _∷_
infixr 5 _++_

data Vec (A : Set) : ℕ → Set where
  []  : Vec A zero
  _∷_ : ∀ {n} → A → Vec A n → Vec A (suc n)

_++_ : ∀ {n m}{A : Set} → Vec A n → Vec A m → Vec A (n + m)
[]          ++ ys = ys
(x ∷ xs) ++ ys = x ∷ (xs ++ ys)

-- 头部只对 suc n 索引开放；对 [] 调用【无法表示】
head : ∀ {n}{A : Set} → Vec A (suc n) → A
head (x ∷ _) = x

replicate : ∀ {A : Set} → (n : ℕ) → A → Vec A n
replicate zero    a = []
replicate (suc n) a = a ∷ replicate n a

-- 类型检查器替我们算 2 + 3 = 5（+ 在第一参数上递归，
-- 2 + 3 折叠到 5 一路畅通）
_ : replicate 2 7 ++ replicate 3 7 ≡ replicate 5 7
_ = refl

-- ---- ② 谓词即类型 ----

data Even : ℕ → Set where
  zero : Even zero
  ss   : ∀ {n} → Even n → Even (suc (suc n))

four-even : Even 4
four-even = ss (ss zero)

-- ---- ③ 全称量词即 Π ----

-- 注意方向 2 + n：Agda 的 _+_ 递归在【第一】参数，
-- 2 + n 折叠为 suc (suc n)，与 ss 的索引无缝
even-ss : ∀ n → Even n → Even (2 + n)
even-ss n h = ss h

-- 归纳 + rewrite 缝合：
-- Agda 的 suc n + suc n 折叠为 suc (n + suc n)（+ 递归在左），
-- 而 ss 需要双层 suc —— 用 +-suc : m + suc n ≡ suc (m + n) 换形
even-double : ∀ n → Even (n + n)
even-double zero    = zero
even-double (suc n) rewrite +-suc n n = ss (even-double n)

-- ---- ④ 内在式的极致：类型即规格，非法状态即不可表示 ----

-- 「非空向量」不是一个布尔标记，是索引里的 suc：
-- head [] 不是异常、不是 nothing，是【语法错误】。

-- λP 的弱 Π 规则在 Agda 里就是 (n : ℕ) → Vec A n 的语法：
++-type : Set → Set
++-type A = ∀ {n m} → Vec A n → Vec A m → Vec A (n + m)
