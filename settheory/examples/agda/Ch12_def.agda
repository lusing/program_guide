-- 第 12 章 可构造层级：def 的构造性形态
--
-- def(U) = 受限公式可定义的子集族。有限论域上谓词=布尔函数，
-- 原子（u ∈ a / u = a）的布尔组合给出 def 的成员。

module Ch12_def where

open import Data.Nat using (ℕ; zero; suc)
open import Data.Bool using (Bool; true; false; not; _∧_; _∨_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 论域接口：有限论域（用 ℕ 界）+ ∈ 解释
record FiniteU : Set where
  field
    bound  : ℕ                       -- 论域 {0..bound-1}
    member : ℕ → ℕ → Bool            -- member u a = "u ∈ a"

open FiniteU

-- 自然数相等判定（教学版）
eqb : ℕ → ℕ → Bool
eqb zero zero = true
eqb zero (suc _) = false
eqb (suc _) zero = false
eqb (suc x) (suc y) = eqb x y

-- 受限公式（原子 + 布尔组合）
data Δ : Set where
  a-mem : ℕ → Δ                     -- u ∈ aₖ
  a-eq  : ℕ → Δ                     -- u = aₖ
  ∨-f   : Δ → Δ → Δ
  ¬-f   : Δ → Δ

eval : (U : FiniteU) → Δ → ℕ → Bool
eval U (a-mem a) u = member U u a
eval U (a-eq k)  u = eqb u k
eval U (∨-f p q) u = eval U p u ∨ eval U q u
eval U (¬-f p)   u = not (eval U p u)

-- ---------- 示例论域：V₂ = {∅, {∅}} ----------
-- 点 0 = ∅（无成员）；点 1 = {∅}（成员 0）
U2 : FiniteU
U2 = record { bound = 2 ; member = λ { u a → eqb u zero ∧ eqb a (suc zero) } }
-- member 0 1 = true（0 ∈ 1）；其余 false

-- {u : u = 1} 在点 1 处为真
eval-eq1 : eval U2 (a-eq (suc zero)) (suc zero) ≡ true
eval-eq1 = refl

-- {u : u ∈ 1} 在点 0 处为真（0 ∈ {∅}）
eval-mem1-0 : eval U2 (a-mem (suc zero)) zero ≡ true
eval-mem1-0 = refl

-- ¬(u ∈ ∅) 恒真（∅ 无成员）
eval-notmem : eval U2 (¬-f (a-mem zero)) (suc zero) ≡ true
eval-notmem = refl

-- def(U₂) 的成员候选：{0}、{1}、{0}（∈1 给 {0}）、全集——
-- 布尔组合覆盖 P(V₂)（习题 12.6 的语义基线）。
