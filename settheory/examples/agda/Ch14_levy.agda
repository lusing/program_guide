-- 第 14 章 Lévy 层级：量词形状的层级判定器
--
-- lev = L0 | Sg n | Pi n；判定规则：对偶翻转、量词提升。

module Ch14_levy where

open import Data.Nat using (ℕ; zero; suc)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

data lev : Set where
  L0 : lev
  Sg : ℕ → lev
  Pi : ℕ → lev

-- 对偶（引理 14.2 iii）：¬ 翻转 Σ↔Π
dual : lev → lev
dual L0 = L0
dual (Sg n) = Pi n
dual (Pi n) = Sg n

dual-involutive : ∀ l → dual (dual l) ≡ l
dual-involutive L0 = refl
dual-involutive (Sg n) = refl
dual-involutive (Pi n) = refl

-- 存在提升：Σₙ 上 ∃ 同层吸收；Πₙ 上 ∃ 升 Σ_{n+1}
ex-over : lev → lev
ex-over L0 = Sg 1
ex-over (Sg n) = Sg n
ex-over (Pi n) = Sg (suc n)

-- 全称 = 对偶的存在
all-over : lev → lev
all-over l = dual (ex-over (dual l))

all-over-pi : ∀ n → all-over (Pi n) ≡ Pi n
all-over-pi n = refl

all-over-sg : ∀ n → all-over (Sg n) ≡ Pi (suc n)
all-over-sg n = refl

-- Δₙ 判定：同为 Σₙ 与 Πₙ（语法上除 L0 外永假——真正的 Δ
-- 由"等价改写"定义，见讲义）
data is-Δ (n : ℕ) : lev → Set where
  ΔL0 : (n ≡ 0) → is-Δ n L0
