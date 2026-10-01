----------------------------------------------------------------
-- 06 System F —— Agda 侧：多态 Church 数实例化到【真 ℕ】上跑
-- Agda 的宇宙多态（Set ℓ）比 F 的 ∀X 更强，但 F 的精神
-- 「一份代码 N 种类型」在这里是日常
----------------------------------------------------------------

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Data.Bool using (Bool; not; true; false)
open import Data.List using (List; []; _∷_; map)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---- 多态恒等：一份代码，处处可用 ----
id : {A : Set} → A → A
id x = x

-- 同一个 id 出现在两种类型下（03 章 I I 的翻案）
_ : ℕ
_ = id (id 3)

_ : ℕ → ℕ
_ = id (λ n → n + 1)

-- ---- 多态 Church 数：∀X. (X→X)→X→X ----
Ch : Set → Set
Ch X = (X → X) → X → X

cn : ℕ → ∀ {X : Set} → Ch X
cn zero    f x = x
cn (suc n) f x = f (cn n f x)

-- 实例化到 ℕ：f := suc，x := zero —— 真算出来
_ : cn 5 (suc) zero ≡ 5
_ = refl

-- 实例化到 Bool：奇偶次翻转
_ : cn 5 not true ≡ false
_ = refl

_ : cn 4 not true ≡ true
_ = refl

-- 实例化到 List ℕ：迭代 map suc（从 [0] 起步，三次 +1）
_ : cn 3 (map suc) (zero ∷ []) ≡ suc (suc (suc zero)) ∷ []
_ = refl

-- ---- 运算符多态 ----
cadd : ∀ {X : Set} → Ch X → Ch X → Ch X
cadd m n f x = m f (n f x)

cmul : ∀ {X : Set} → Ch X → Ch X → Ch X
cmul m n f = m (n f)

_ : cadd (cn 2) (cn 3) suc zero ≡ 5
_ = refl

_ : cmul (cn 2) (cn 3) suc zero ≡ 6
_ = refl

-- ---- 指数：m 的 n 次复合，结果就是 X→X ----
cexp : ∀ {X : Set} → (X → X) → Ch X → (X → X)
cexp m n = n m

_ : cexp suc (cn 5) zero ≡ 5
_ = refl
