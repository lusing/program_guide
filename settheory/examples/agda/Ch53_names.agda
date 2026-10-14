-- 第 53 章：check 名的构造与 G-读出复原

module Ch53_names where

open import Data.Bool using (Bool; true; false; _∧_; _∨_; not)
open import Data.List using (List; []; _∷_; map)
open import Data.Nat using (ℕ; zero; suc)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 名字（非索引结构递归——Coq 通道同款设计）
data Name : Set where
  nempty : Name
  ncons : Name → Bool → Name → Name

-- B = Bool；G = ↑true（主超滤：含 true 标签）
inG : Bool → Bool
inG b = b

-- G-读出：真值在 G 中的子名读出
open import Data.List using (_++_)

readout : Name → List Bool
readout nempty = []
readout (ncons σ b r) with inG b
... | true = b ∷ (readout σ ++ readout r)
... | false = readout σ ++ readout r

-- check 名：ǔ（本 toy 用 Bool 标签，即 B = 2——V^2 ≅ V）
check : ℕ → Name
check zero = nempty
check (suc n) = ncons (check n) true nempty

-- 读出复原：ǔ_G = u（在此 toy 上 = 标签表长度守恒）
readout-check-1 : readout (check 1) ≡ true ∷ []
readout-check-1 = refl

readout-check-2 : readout (check 2) ≡ true ∷ true ∷ []
readout-check-2 = refl

-- 空名读出为空
readout-empty : readout nempty ≡ []
readout-empty = refl

-- 换超滤 G = ↑false：check 名的 true 标签全部被剔除
inG' : Bool → Bool
inG' b = not b

readout' : Name → List Bool
readout' nempty = []
readout' (ncons σ b r) with inG' b
... | true = b ∷ (readout' σ ++ readout' r)
... | false = readout' σ ++ readout' r

-- 同一名字、不同 G：双读性（泛型多读性的最小剧场）
readout'-check-1 : readout' (check 1) ≡ []
readout'-check-1 = refl
