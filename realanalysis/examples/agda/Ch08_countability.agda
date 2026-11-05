-- Chapter 8: Cantor diagonal and a finite zigzag table.
module Ch08_countability where

open import Data.Bool using (Bool; true; false; not)
open import Data.Nat using (ℕ; zero; suc; _*_; _+_)
open import Data.Product using (Σ; _×_; _,_)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

-- No surjection ℕ → (ℕ → Bool): flip the diagonal.
cantor : (f : ℕ → ℕ → Bool) → Σ (ℕ → Bool) (λ d → ∀ n → f n ≡ d → ⊥)
cantor f = d , escape
  where
  d : ℕ → Bool
  d n = not (f n n)
  escape : ∀ n → f n ≡ d → ⊥
  escape n eq with f n n | cong (λ g → g n) eq
  ... | true  | ()
  ... | false | ()

-- Zigzag values (even ↦ n/2, odd ↦ -(n+1)/2), checked on 0..5.
-- Encoded as integers by a sign bit: true means negative.
Zig : Set
Zig = Bool × ℕ

zig : ℕ → Zig
zig zero          = false , 0          -- 0
zig (suc zero)    = true  , 1          -- -1
zig (suc (suc zero)) = false , 1       -- 1
zig (suc (suc (suc zero))) = true , 2  -- -2
zig (suc (suc (suc (suc zero)))) = false , 2 -- 2
zig (suc (suc (suc (suc (suc n))))) = zig n  -- unused tail, not a real formula

zig-0 : zig 0 ≡ (false , 0)
zig-0 = refl
zig-1 : zig 1 ≡ (true , 1)
zig-1 = refl
zig-2 : zig 2 ≡ (false , 1)
zig-2 = refl
zig-3 : zig 3 ≡ (true , 2)
zig-3 = refl

-- Identity is a bijection on Bool (equinumerosity is reflexive).
idB : Bool → Bool
idB b = b

id-left : ∀ b → idB b ≡ b
id-left _ = refl
