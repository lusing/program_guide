-- 第 13 章 AC 与 GCH 在 L：<_L 的构造性骨架
--
-- 每个可构造集的出生证 =（层号， Gödel 分解序）。
-- <_L = 字典序；它的存在即 AC 在 L 中（定理 33）。

module Ch13_Lorder where

open import Data.Nat using (ℕ; zero; suc; _<_; _≤_; _⊔_; z≤n; s≤s)
open import Data.List using (List; []; _∷_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Data.Nat.Properties using (m≤m⊔n)
open import Data.Product using (_×_; _,_)

-- 集合编码与出生证（第 12 章的延续）
data HFL : Set where
  hfl : List HFL → HFL

-- 层号（对结构归纳；与列表辅助互递归）
mutual
  birth : HFL → ℕ
  birth (hfl []) = zero
  birth (hfl (x ∷ xs)) = suc (birth x ⊔ birth-list xs)

  birth-list : List HFL → ℕ
  birth-list [] = zero
  birth-list (y ∷ ys) = birth y ⊔ birth-list ys

-- 成员层号严格更小（构造层的控制）
birth-mem< : (x : HFL) (xs : List HFL) → birth x < birth (hfl (x ∷ xs))
birth-mem< x xs = s≤s (m≤m⊔n (birth x) (birth-list xs))

-- 配对运算的层号控制（精确等式版由 Coq 通道 birth_pair 承载：
--   birth(S f, pair) = 1 + max(birth f x, birth f y)）。

-- <_L 的第一坐标：层号比较
infix 4 _<L¹_

_<L¹_ : HFL → HFL → Set
x <L¹ y = birth x < birth y

-- 具体例：∅ < {∅} < {∅,{∅}}（层 0 < 1 < 2）
∅ᴴ oneᴴ twoᴴ : HFL
∅ᴴ   = hfl []
oneᴴ = hfl (∅ᴴ ∷ [])
twoᴴ = hfl (∅ᴴ ∷ oneᴴ ∷ [])

layer-0<1<2 : birth ∅ᴴ ≡ zero × birth oneᴴ ≡ suc zero × birth twoᴴ ≡ suc (suc zero)
layer-0<1<2 = refl , refl , refl
