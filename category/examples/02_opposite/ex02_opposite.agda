------------------------------------------------------------------------
-- ex02 —— 反范畴与对偶原理
-- 三书对位：贺伟《范畴论》1.4 前置 /《高级范畴论》1.5 / Simmons 2.8
------------------------------------------------------------------------

open import Level using (Level; _⊔_; 0ℓ) renaming (suc to lsuc)
open import Data.Nat using (ℕ; suc)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

------------------------------------------------------------------------

record Category (o ℓ : Level) : Set (lsuc (o ⊔ ℓ)) where
  field
    Obj : Set o
    Hom : Obj → Obj → Set ℓ
    idn : ∀ {a} → Hom a a
    comp : ∀ {a b c} → Hom a b → Hom b c → Hom a c
    idL : ∀ {a b} (f : Hom a b) → comp (idn {a}) f ≡ f
    idR : ∀ {a b} (f : Hom a b) → comp f (idn {b}) ≡ f
    assoc : ∀ {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d)
          → comp (comp f g) h ≡ comp f (comp g h)

open Category

------------------------------------------------------------------------
-- 反范畴构造：箭头掉头、复合倒序。
-- C 的 idR 定律变成 C^op 的 idL 定律——「对偶原理」的机器版本。

opposite : ∀ {o ℓ} → Category o ℓ → Category o ℓ
opposite C = record
  { Obj = Obj C
  ; Hom = λ a b → Hom C b a
  ; idn = idn C
  ; comp = λ f g → comp C g f
  ; idL = λ f → idR C f            -- C 的右单位 = C^op 的左单位
  ; idR = λ f → idL C f            -- 反之亦然
  ; assoc = λ f g h → sym (assoc C h g f)
  }
  where open Relation.Binary.PropositionalEquality using (sym)

-- 三条定律的搬运方向（逐条对读）：
-- C^op 的 idL 目标 comp_op (idn) f ≡ f 展开 = comp C f (idn C) ≡ f，
-- 恰是 C 的 idR；assoc 展开后是 assoc C h g f 的对称。

------------------------------------------------------------------------
-- 例子：预序范畴（瘦范畴）
-- 预序 (ℕ, ≤)：对象 = ℕ，Hom a b := Le a b，至多一条态射。

data Le : ℕ → ℕ → Set where
  lerefl : ∀ {n} → Le n n
  lestep : ∀ {m n} → Le m n → Le m (suc n)

-- le-trans 递归在第二参数：q 为 lerefl 时直接返回 p
le-trans : ∀ {a b c} → Le a b → Le b c → Le a c
le-trans p lerefl = p
le-trans p (lestep q) = lestep (le-trans p q)

-- 右单位定义成立（match 分支直接折叠）；左单位要归纳
-- ——「方向」决定哪条免费（与 typetheory 加法方向学同理）。
le-idL : ∀ {a b} (f : Le a b) → le-trans lerefl f ≡ f
le-idL lerefl = refl
le-idL (lestep f) = cong lestep (le-idL f)

le-assoc : ∀ {a b c d} (f : Le a b) (g : Le b c) (h : Le c d)
         → le-trans (le-trans f g) h ≡ le-trans f (le-trans g h)
le-assoc f g lerefl = refl
le-assoc f g (lestep h) = cong lestep (le-assoc f g h)

LeCat : Category 0ℓ 0ℓ
LeCat = record
  { Obj = ℕ
  ; Hom = Le
  ; idn = lerefl
  ; comp = le-trans
  ; idL = le-idL
  ; idR = λ f → refl               -- 免费
  ; assoc = le-assoc
  }

-- 对偶预序：LeCat^op 里 Hom a b = Le b a——「≥」范畴
geCat : Category 0ℓ 0ℓ
geCat = opposite LeCat

-- 具体：LeCat 里 3 → 5 有态射，5 → 3 没有；geCat 里恰好反过来
le35 : Hom LeCat 3 5
le35 = lestep (lestep lerefl)

ge53 : Hom geCat 5 3
ge53 = lestep (lestep lerefl)
-- geCat 5→3 与 LeCat 3→5 是同一棵证明树，方向掉了头

------------------------------------------------------------------------
-- 对偶翻译的实感：FinCat
-- FinCat^op 的态射 m → n 就是 FinCat 的函数 Fin n → Fin m。

open import Data.Fin using (Fin)

FinCat : Category 0ℓ 0ℓ
FinCat = record
  { Obj = ℕ
  ; Hom = λ m n → Fin m → Fin n
  ; idn = λ x → x
  ; comp = λ f g x → g (f x)
  ; idL = λ f → refl
  ; idR = λ f → refl
  ; assoc = λ f g h → refl
  }

-- FinCat^op 的 3 → 2 = FinCat 的 2 → 3 = Fin 2 → Fin 3
check-opp : Fin 2 → Fin 3
check-opp = λ x → Fin.suc x    -- 嵌入：Fin n → Fin (suc n)

opp-check : Hom (opposite FinCat) 3 2
opp-check = check-opp

------------------------------------------------------------------------
-- 坑位速记：
-- 1. opposite 的定律搬运要看清展开：写反了（idL 填 idL C）类型对不上。
-- 2. le-trans 递归在第二参数 ⇒ idR 定义成立（refl）、idL 要归纳
--    ——assoc 的归纳也在第三参数（同为「复合的第二因子」）。
-- 3. 模式匹配族（lestep 隐式 m n）比 Coq 的索引 match 省心：
--    Agda 自动处理索引约束（Coq 里同一定义要 revert+induction）。
-- 4. record 之间没有「相等」：op (op C) 只在字段层面还原 C。
------------------------------------------------------------------------
