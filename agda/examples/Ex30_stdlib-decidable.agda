module Ex30_stdlib-decidable where

-- 第 30 章配套示例：Relation.Nullary / Dec / ⌊_⌋ / 判定式组合子（3.0 `_≡?_` 新名）。

open import Data.List using (List; []; _∷_)
open import Data.List.Base using (filter)
open import Data.Nat using (ℕ; zero; suc; _+_; _≤_)
open import Data.Nat.Properties using (_≡?_; _≤?_)
open import Data.Product using (_×_)
open import Relation.Nullary using (Dec; yes; no)
open import Relation.Nullary.Decidable.Core using (_×?_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 件 1：Dec 是 record（does + proof）。拿到一个 yes 判定：
two-plus-three : Dec (2 + 3 ≡ 3 + 2)
two-plus-three = (2 + 3) ≡? (3 + 2)

-- 件 2：filter 要的是 Decidable 谓词（30 章坑 6）。拿 `5 ≤? n : Dec (5 ≤ n)` 直接当谓词。
filtered : List ℕ
filtered = filter (λ n → 5 ≤? n) (3 ∷ 7 ∷ 9 ∷ [])

-- 件 3：判定式组合子 _×?_（逻辑且）：两个判定合成一个对子的判定。
both : Dec ((1 ≤ 2) × (3 ≤ 4))
both = (1 ≤? 2) ×? (3 ≤? 4)

-- 件 4：Recomputable —— 有判定就能把擦除证据重建出来。
open import Relation.Nullary.Recomputable using (Recomputable)
recompute-demo : .(0 ≤ 1) → 0 ≤ 1
recompute-demo erased = recompute (0 ≤? 1) erased
  where open import Relation.Nullary.Decidable.Core using (recompute)