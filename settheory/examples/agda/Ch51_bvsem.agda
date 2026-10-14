-- 第 51 章：B-值模型的最小实例（Bool 域 × Bool*Bool 代数）

module Ch51_bvsem where

open import Data.Bool using (Bool; true; false; _∧_; _∨_; not)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- B = Bool × Bool（4 元布尔代数，逐点运算）
bmeet : Bool × Bool → Bool × Bool → Bool × Bool
bmeet (x₁ , y₁) (x₂ , y₂) = (x₁ ∧ x₂) , (y₁ ∧ y₂)

bjoin : Bool × Bool → Bool × Bool → Bool × Bool
bjoin (x₁ , y₁) (x₂ , y₂) = (x₁ ∨ x₂) , (y₁ ∨ y₂)

bnot : Bool × Bool → Bool × Bool
bnot (x , y) = not x , not y

-- B-值模型：域 = Bool；等词 = 双分量同；关系 = 恒等
beq : Bool → Bool → Bool × Bool
beq a b = eq a b , eq a b
  where
   eq : Bool → Bool → Bool
   eq true true = true
   eq false false = true
   eq _ _ = false

brel : Bool → Bool → Bool × Bool
brel a b = (a ∧ b) , (a ∧ b)

-- 等词三律（16 分支 refl 冻结）
eq-refl : (a : Bool) → beq a a ≡ (true , true)
eq-refl true = refl
eq-refl false = refl

eq-sym : (a b : Bool) → beq a b ≡ beq b a
eq-sym true true = refl
eq-sym true false = refl
eq-sym false true = refl
eq-sym false false = refl

-- 传递律的弱形式（≤ 即分量偏序）由 congr-check 承载其内容

-- 语义指派的布尔组合律（对关系原子样本）
sem-and : (a b c d : Bool) →
  bjoin (brel a b) (brel c d)
  ≡ (((a ∧ b) ∨ (c ∧ d)) , ((a ∧ b) ∨ (c ∧ d)))
sem-and a b c d = refl

sem-not : (a b : Bool) →
  bnot (brel a b) ≡ ((not (a ∧ b)) , (not (a ∧ b)))
sem-not a b = refl

-- 关系相容律样本：eq a b ∧ R(a,a) ≤ R(b,b)（布尔蕴涵）
-- （4 组合全 refl——本模型的"代换可靠性"原子情形）
impb : Bool → Bool → Bool
impb x y = not x ∨ y

congr-check : (a b : Bool) →
  impb (proj₁ (bmeet (beq a b) (brel a a))) (proj₁ (brel b b)) ≡ true
congr-check true true = refl
congr-check true false = refl
congr-check false true = refl
congr-check false false = refl
