----------------------------------------------------------------
-- 30 归纳类型族（Nordström ch.9–13）—— Agda 侧
-- 与 Lean/Coq 版同构；Agda 的归纳原理 = 模式匹配本身
----------------------------------------------------------------

open import Data.Product using (_×_; _,_; proj₁; proj₂; Σ)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

-- ---- 自然数 ----

data N : Set where
  z : N
  s : N → N

add : N → N → N
add z     m = m                 -- 递归在第一参数
add (s n) m = s (add n m)

add-z : ∀ n → add n z ≡ n
add-z z     = refl
add-z (s n) = cong s (add-z n)

add-s : ∀ n m → add n (s m) ≡ s (add n m)
add-s z     m = refl
add-s (s n) m = cong s (add-s n m)

add-comm : ∀ n m → add n m ≡ add m n
add-comm z     m = sym (add-z m)          -- add z m = m；add m z → m
  where open import Relation.Binary.PropositionalEquality using (sym)
add-comm (s n) m = trans (cong s (add-comm n m)) (sym (add-s m n))
  where open import Relation.Binary.PropositionalEquality using (trans; sym)

-- ---- 列表 ----

data Lst (A : Set) : Set where
  []  : Lst A
  _∷_ : A → Lst A → Lst A

infixr 5 _∷_

app : ∀ {A : Set} → Lst A → Lst A → Lst A
app []       ys = ys
app (x ∷ xs) ys = x ∷ app xs ys

app-nil-r : ∀ {A : Set} (xs : Lst A) → app xs [] ≡ xs
app-nil-r []       = refl
app-nil-r (x ∷ xs) = cong (x ∷_) (app-nil-r xs)

app-assoc : ∀ {A : Set} (xs ys zs : Lst A) →
  app (app xs ys) zs ≡ app xs (app ys zs)
app-assoc []       ys zs = refl
app-assoc (x ∷ xs) ys zs = cong (x ∷_) (app-assoc xs ys zs)

-- ---- Σ：依赖对（标准库版本即正文讲的对象） ----

sigEx : Σ N (λ _ → Lst N)
sigEx = s z , z ∷ []

_ : proj₁ sigEx ≡ s z
_ = refl

-- ---- 不交和 ----

decEx : N ⊎ Lst N → N
decEx (inj₁ n)    = n
decEx (inj₂ _)    = z

_ : decEx (inj₁ (s z)) ≡ s z
_ = refl

-- Agda 的「归纳原理」即模式匹配的完备性检查——没有独立的
-- N-ind / N-rect：add-z 的两行就是归纳原理的两次应用

-- ---- 30.3 Peano 第三公设：前驱 + succ 单射（书 9 章例） ----
pred : N → N
pred z     = z
pred (s n) = n

-- 命题版：对 refl 匹配即把两侧统一——单射是模式匹配的赠品
peano3 : ∀ m n → s m ≡ s n → m ≡ n
peano3 m n refl = refl

-- Peano 第五公设 = N-消去的命题化（归纳即消去）
peano5 : (C : N → Set) → C z → (∀ n → C n → C (s n)) → ∀ n → C n
peano5 C c step z     = c
peano5 C c step (s n) = step n (peano5 C c step n)
