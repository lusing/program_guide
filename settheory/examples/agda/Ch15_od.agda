-- 第 15 章 OD/HOD：可定义性的参数安全检查
--
-- od_ok 的构造性骨架：定义模板的参数必须是序数。

module Ch15_od where

open import Data.Nat using (ℕ)
open import Data.List using (List; []; _∷_)

open import Data.Bool using (Bool; true; false; _∧_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Data.Product using (_×_; _,_)

-- 参数：序数（安全）或集合（越界）
data Param : Set where
  ord : ℕ → Param
  set : ℕ → Param        -- 集合参数（超出 OD 的形态）

is-safe : Param → Bool
is-safe (ord _) = true
is-safe (set _) = false

allB : (Param → Bool) → List Param → Bool
allB f [] = true
allB f (p ∷ ps) = f p ∧ allB f ps

params-ok : List Param → Bool
params-ok = allB is-safe

-- OD 成员的形态：定义 + 安全参数
record ODef : Set where
  field
    formula : ℕ
    params  : List Param

in-OD : ODef → Bool
in-OD d = params-ok (ODef.params d)

-- 示例：φ(u, ω, 17)（全序数参数）∈ OD
def1 : ODef
def1 = record { formula = 42; params = ord 7 ∷ ord 17 ∷ [] }

def1-in-OD : in-OD def1 ≡ true
def1-in-OD = refl

-- 反例：ψ(u, x)（集合参数）∉ OD
def2 : ODef
def2 = record { formula = 43; params = set 0 ∷ [] }

def2-not-OD : in-OD def2 ≡ false
def2-not-OD = refl

-- HOD 的语义（讲义）：TC({x}) ⊆ OD 的全体——传递 ZFC 内模型。
