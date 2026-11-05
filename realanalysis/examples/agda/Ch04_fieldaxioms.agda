-- 第 04 章 实数域（上）：Agda 通道。
-- 展示“从公理到定理”的纯构造过程：只假设域公理的片段
-- （加法交换群 + 分配律），手工推出 0·x = 0 与 -(-x) = x。
-- 不调用任何现成代数库——每一步都标明所用的公理。

module Ch04_fieldaxioms where

open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong; module ≡-Reasoning)
open ≡-Reasoning

-- 只带加法结构的“类域”：一个类型、两个二元运算、常量 0，
-- 加上加法交换律/结合律/单位元/逆元与乘法对加法的右分配律。
module FieldLaws (F : Set) (0f : F)
    (_+_ _*_ : F → F → F) (neg : F → F)
    (+-comm : ∀ a b → a + b ≡ b + a)
    (+-assoc : ∀ a b c → (a + b) + c ≡ a + (b + c))
    (+-identityˡ : ∀ a → 0f + a ≡ a)
    (+-inverseʳ : ∀ a → a + neg a ≡ 0f)
    (+-inverseˡ : ∀ a → neg a + a ≡ 0f)
    (*-distribʳ : ∀ a b c → (a + b) * c ≡ (a * c) + (b * c))
  where

  -- 右单位元从交换律免费获得。
  +-identityʳ : ∀ a → a + 0f ≡ a
  +-identityʳ a = trans (+-comm a 0f) (+-identityˡ a)

  -- 定理（仅用公理）：0 · x = 0。
  -- 证明思想（原书第 5 章的标准练习）：
  -- 0·x = 0·x + 0 = 0·x + (0·x + (-0·x)) = (0·x + 0·x) + (-0·x)
  --     = (0 + 0)·x + (-0·x) = 0·x + (-0·x) = 0。
  zero-absorbs : ∀ a → 0f * a ≡ 0f
  zero-absorbs a = begin
    0f * a
      ≡⟨ sym (+-identityʳ _) ⟩
    (0f * a) + 0f
      ≡⟨ cong ((0f * a) +_) (sym (+-inverseʳ _)) ⟩
    (0f * a) + ((0f * a) + neg (0f * a))
      ≡⟨ sym (+-assoc _ _ _) ⟩
    ((0f * a) + (0f * a)) + neg (0f * a)
      ≡⟨ cong (_+ neg (0f * a)) (sym (*-distribʳ 0f 0f a)) ⟩
    ((0f + 0f) * a) + neg (0f * a)
      ≡⟨ cong (λ t → (t * a) + neg (0f * a)) (+-identityˡ 0f) ⟩
    (0f * a) + neg (0f * a)
      ≡⟨ +-inverseʳ _ ⟩
    0f
      ∎

  -- 定理（仅用公理）：-(-x) = x。
  -- 证明思想：-(-x) = -(-x) + 0 = -(-x) + ((-x) + x)
  --         = (-(-x) + (-x)) + x = 0 + x = x。
  neg-invol : ∀ a → neg (neg a) ≡ a
  neg-invol a = begin
    neg (neg a)
      ≡⟨ sym (+-identityʳ _) ⟩
    neg (neg a) + 0f
      ≡⟨ cong (neg (neg a) +_) (sym (+-inverseˡ a)) ⟩
    neg (neg a) + (neg a + a)
      ≡⟨ sym (+-assoc _ _ _) ⟩
    (neg (neg a) + neg a) + a
      ≡⟨ cong (_+ a) (+-inverseˡ (neg a)) ⟩
    0f + a
      ≡⟨ +-identityˡ a ⟩
    a
      ∎
