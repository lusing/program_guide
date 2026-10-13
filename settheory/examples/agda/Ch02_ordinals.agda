-- 第 02 章 序数：von Neumann 有限序数
--
-- n = {0, 1, ..., n-1}：每个自然数是其所有前驱的集合。
-- ∈ 即 <；∈ 的传递性（Transset 的核心）逐字验证。

module Ch02_ordinals where

open import Data.Empty using (⊥)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Relation.Nullary using (¬_)

-- ---------- 一、von Neumann 序数：递归定义 ----------

data VNO : Set where
  oz   : VNO                             -- 0 = ∅
  osuc : VNO -> VNO                      -- n+1 = n ∪ {n}

-- 隶属：n+1 = n ∪ {n} 的元素侧——x ∈ (n ∪ {n}) ⟺ x = n ∨ x ∈ n
infix 4 _∈o_

_∈o_ : VNO -> VNO -> Set
x ∈o oz     = ⊥
x ∈o osuc n = (x ≡ n) ⊎ (x ∈o n)

-- ---------- 二、∈ 的传递性：Transset 的核心 ----------

-- x ∈ y 且 y ∈ z 蕴含 x ∈ z。
-- 归纳于 z；osuc 的 inj₁ 分支上 refl 会把统一变量粘合，
-- 这正是 "n+1 的元素都是 n 的子集成员" 的构造性内容。

∈-trans : ∀ x y z → x ∈o y → y ∈o z → x ∈o z
∈-trans x y oz     x∈y ()
∈-trans x y (osuc n) x∈y (inj₁ refl) = inj₂ x∈y
∈-trans x y (osuc n) x∈y (inj₂ y∈n) = inj₂ (∈-trans x y n x∈y y∈n)

-- ---------- 三、有限序数的具体事实 ----------

one two three : VNO
one   = osuc oz
two   = osuc one
three = osuc two

-- 2 ∈ 3（osuc 的"新元素"入场券）与 0 ∈ 3（深层传递）
2∈3 : two ∈o three
2∈3 = inj₁ refl

0∈3 : oz ∈o three
0∈3 = inj₂ (inj₂ (inj₁ refl))

-- ∈ 的非自反：0 ∉ 0
irrefl-zero : ¬ (oz ∈o oz)
irrefl-zero ()

-- 传递性的实例：0 ∈ 1 且 1 ∈ 3，经由 ∈-trans 得 0 ∈ 3
trans-instance : oz ∈o three
trans-instance = ∈-trans oz one three (inj₁ refl) (inj₂ (inj₁ refl))
