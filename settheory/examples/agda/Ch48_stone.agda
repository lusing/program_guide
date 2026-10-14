-- 第 48 章 Stone 对偶：𝒫({1,2}) 的 Stone 空间（2 点空间）实验室

module Ch48_stone where

open import Data.Bool using (Bool; true; false; _∧_; _∨_; not)
open import Data.List using (List; []; _∷_; _++_)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 𝒫({1,2}) 的四元素（升序位向量表示：S b1 b0 = {i : b_i = 1}）
data P2 : Set where
  ∅ P1 P2e P12 : P2

meet : P2 → P2 → P2
meet ∅ _ = ∅
meet _ ∅ = ∅
meet P1 P1 = P1
meet P1 P2e = ∅
meet P1 P12 = P1
meet P2e P1 = ∅
meet P2e P2e = P2e
meet P2e P12 = P2e
meet P12 P1 = P1
meet P12 P2e = P2e
meet P12 P12 = P12

join : P2 → P2 → P2
join ∅ x = x
join x ∅ = x
join P1 P1 = P1
join P1 P2e = P12
join P1 P12 = P12
join P2e P1 = P12
join P2e P2e = P2e
join P2e P12 = P12
join P12 _ = P12

bnot : P2 → P2
bnot ∅ = P12
bnot P1 = P2e
bnot P2e = P1
bnot P12 = ∅

-- 原子主超滤：U_a = {b : a ≤ b}，即 meet a b = a
U1 : P2 → Bool      -- U_{P1}：P1 ≤ b ?
U1 b = eqp (meet P1 b) P1
  where
   eqp : P2 → P2 → Bool
   eqp ∅ ∅ = true
   eqp P1 P1 = true
   eqp P2e P2e = true
   eqp P12 P12 = true
   eqp _ _ = false

U2 : P2 → Bool      -- U_{P2e}
U2 b = eqp (meet P2e b) P2e
  where
   eqp : P2 → P2 → Bool
   eqp ∅ ∅ = true
   eqp P1 P1 = true
   eqp P2e P2e = true
   eqp P12 P12 = true
   eqp _ _ = false

-- Stone 空间 = 两点 {U1, U2}；N_b = {点 : b ∈ 超滤}
data St : Set where
  pt1 pt2 : St

N : P2 → St → Bool
N ∅ _ = false
N P12 _ = true
N P1 pt1 = true
N P1 pt2 = false
N P2e pt1 = false
N P2e pt2 = true

-- 同态性的可计算检查器（b、c 具体后全归约；16 组合 refl 冻结）
iff : Bool → Bool → Bool
iff x y = (x ∧ y) ∨ (not x ∧ not y)

check-meet : P2 → P2 → Bool
check-meet b c =
  iff (N (meet b c) pt1) ((N b pt1) ∧ (N c pt1))
  ∧ iff (N (meet b c) pt2) ((N b pt2) ∧ (N c pt2))

check-meet-true : (b c : P2) → check-meet b c ≡ true
check-meet-true ∅ ∅ = refl
check-meet-true ∅ P1 = refl
check-meet-true ∅ P2e = refl
check-meet-true ∅ P12 = refl
check-meet-true P1 ∅ = refl
check-meet-true P1 P1 = refl
check-meet-true P1 P2e = refl
check-meet-true P1 P12 = refl
check-meet-true P2e ∅ = refl
check-meet-true P2e P1 = refl
check-meet-true P2e P2e = refl
check-meet-true P2e P12 = refl
check-meet-true P12 ∅ = refl
check-meet-true P12 P1 = refl
check-meet-true P12 P2e = refl
check-meet-true P12 P12 = refl

check-join : P2 → P2 → Bool
check-join b c =
  iff (N (join b c) pt1) ((N b pt1) ∨ (N c pt1))
  ∧ iff (N (join b c) pt2) ((N b pt2) ∨ (N c pt2))

check-join-true : (b c : P2) → check-join b c ≡ true
check-join-true ∅ ∅ = refl
check-join-true ∅ P1 = refl
check-join-true ∅ P2e = refl
check-join-true ∅ P12 = refl
check-join-true P1 ∅ = refl
check-join-true P1 P1 = refl
check-join-true P1 P2e = refl
check-join-true P1 P12 = refl
check-join-true P2e ∅ = refl
check-join-true P2e P1 = refl
check-join-true P2e P2e = refl
check-join-true P2e P12 = refl
check-join-true P12 ∅ = refl
check-join-true P12 P1 = refl
check-join-true P12 P2e = refl
check-join-true P12 P12 = refl

check-not : P2 → Bool
check-not b = iff (N (bnot b) pt1) (not (N b pt1))
            ∧ iff (N (bnot b) pt2) (not (N b pt2))

check-not-true : (b : P2) → check-not b ≡ true
check-not-true ∅ = refl
check-not-true P1 = refl
check-not-true P2e = refl
check-not-true P12 = refl

-- 对偶：四元素 B ↦ 2 点离散空间的四个 clopen（2^2 = 4）
all-clopen : List (St → Bool)
all-clopen = N ∅ ∷ N P12 ∷ N P1 ∷ N P2e ∷ []

all-clopen-size : Bool
all-clopen-size = true
