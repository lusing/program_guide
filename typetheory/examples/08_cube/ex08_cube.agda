----------------------------------------------------------------
-- 08 λC（构造演算）—— Agda 侧：顶点的另一种活法
-- Agda 走 MLTT 一系：宇宙塔 Set₀:Set₁:… 是【直谓】的，
-- 不用 λC 的非直谓 Prop。三扇门照样全开，形态不同：
-- 多态=隐式参数与宇宙多态；依赖=索引族；类型算子=Set 上的函数
----------------------------------------------------------------

open import Data.Nat using (ℕ; zero; suc)
open import Data.List using (List; []; _∷_)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---- 门 1（多态）：宇宙多态的恒等 ----
id : ∀ {ℓ}{A : Set ℓ} → A → A
id x = x

-- ---- 类型算子：Set 上的普通函数 ----
Endo : Set → Set
Endo A = A → A

PairOf : Set → Set
PairOf A = A × A

_ : PairOf ℕ
_ = 1 , 2

-- ---- 门 2（依赖）：索引族 ----
data Vec (A : Set) : ℕ → Set where
  []  : Vec A zero
  _∷_ : ∀ {n} → A → Vec A n → Vec A (suc n)

_ : Vec ℕ 3
_ = 1 ∷ 2 ∷ 3 ∷ []

-- ---- 门 3 合体：多态谓词 ----
data All {A : Set} (P : A → Set) : List A → Set where
  []  : All P []
  _∷_ : ∀ {x xs} → P x → All P xs → All P (x ∷ xs)

_ : All (λ n → n ≡ zero) (zero ∷ zero ∷ [])
_ = refl ∷ refl ∷ []

_ : All (λ n → n ≡ suc zero) (suc zero ∷ [])
_ = refl ∷ []

-- ---- 直谓 vs 非直谓：Agda 的立场 ----
-- Coq 的 Prop : Type 且可在 Prop 上再量化（λC 的非直谓）；
-- Agda 的 Set₀ : Set₁，Set₁ 里的东西不能反过来住进 Set₀。
-- 「以【所有】Set₀ 谓词为参数的谓词」在 Agda 里必须升层：
--   BigQuant : (Set₀ → Set₀) → Set₀      -- 可以（参数是函数）
--   impred   : ((A : Set₀) → A → Set₀) → Set₀  -- 结果仍在 Set₀，
-- 量化进来的只是参数，不违反直谓性。真正被禁的是
--   Π (P : Set₀ → Set₀) . Set₀   若要它【本身】在 Set₀ 里
-- （Coq 的 Prop 语义允许——21 章细讲两种立场的代价）

BigQuant : (ℕ → Set) → Set
BigQuant P = P zero
