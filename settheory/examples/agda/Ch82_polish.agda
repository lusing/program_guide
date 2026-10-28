-- 第 82 章：有限 Gale–Stewart 逆向归纳（构造性）与对偶定理。
module Ch82_polish where

open import Data.Bool using (Bool; true; false; not; _∨_; _∧_; if_then_else_)
open import Data.List using (List; []; _∷_)
open import Data.Nat using (ℕ; zero; suc)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong₂; trans)

-- 深度 n 的交替博弈；zs=true 轮张三（∨ 节点），否则轮李四（∧ 节点）。
zwins : (List Bool → Bool) → ℕ → Bool → List Bool → Bool
zwins A zero _ p = A p
zwins A (suc n) zs p =
  if zs
  then zwins A n false (true ∷ p) ∨ zwins A n false (false ∷ p)
  else zwins A n true (true ∷ p) ∧ zwins A n true (false ∷ p)

not-or : (a b : Bool) → not a ∧ not b ≡ not (a ∨ b)
not-or true true = refl
not-or true false = refl
not-or false true = refl
not-or false false = refl

not-and : (a b : Bool) → not a ∨ not b ≡ not (a ∧ b)
not-and true true = refl
not-and true false = refl
not-and false true = refl
not-and false false = refl

-- 对偶定理：补赛事 + 互换行棋方 = 原赛局的否定（有限确定性）。
zwins-dual : (A : List Bool → Bool) (n : ℕ) (zs : Bool) (p : List Bool) →
  zwins (λ q → not (A q)) n (not zs) p ≡ not (zwins A n zs p)
zwins-dual A zero zs p = refl
zwins-dual A (suc n) true p =
  trans (cong₂ _∧_ (zwins-dual A n false (true ∷ p))
                   (zwins-dual A n false (false ∷ p)))
        (not-or (zwins A n false (true ∷ p)) (zwins A n false (false ∷ p)))
zwins-dual A (suc n) false p =
  trans (cong₂ _∨_ (zwins-dual A n true (true ∷ p))
                   (zwins-dual A n true (false ∷ p)))
        (not-and (zwins A n true (true ∷ p)) (zwins A n true (false ∷ p)))

-- 深度 2 的具体赛局（叶上序列为 [y;x]）。
A-and : List Bool → Bool
A-and (y ∷ x ∷ _) = x ∧ y
A-and _ = false

A-or : List Bool → Bool
A-or (y ∷ x ∷ _) = x ∨ y
A-or _ = false

and-game : zwins A-and 2 true [] ≡ false
and-game = refl

or-game : zwins A-or 2 true [] ≡ true
or-game = refl

-- 对偶应用：补赛局换先手，张三（原来的李四）稳赢。
and-dual : zwins (λ q → not (A-and q)) 2 false [] ≡ true
and-dual = refl
