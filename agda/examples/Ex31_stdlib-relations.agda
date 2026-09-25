module Ex31_stdlib-relations where

-- 第 31 章配套示例：Relation.Binary 的 Definitions / Structures / Bundles /
-- Construct 四层，以及 Reasoning 挂接。

open import Data.Nat using (ℕ; _+_; _≤_; _<_)
open import Relation.Binary.PropositionalEquality using (_≡_)

-- ── 件 1：Definitions 层：一阶性质只是『类型别名』，可当作类型拿在手里。
open import Relation.Binary.Definitions using (Transitive; Reflexive; Antisymmetric)

-- ── 件 2：Structures 层：性质被封装进记录。ℕ 上标准库给好现货：
open import Data.Nat.Properties using (≤-trans; ≤-isPreorder; <-isStrictTotalOrder)

-- 抽取一条性质：≤ 有传性。
≤-transitive : Transitive _≤_
≤-transitive = ≤-trans

-- ── 件 3：Bundles 层：带上 Carrier 的标准整包（这里只用类型占位说明）。
open import Relation.Binary.Bundles using (Poset; DecTotalOrder)
open import Relation.Binary.Structures using (IsDecTotalOrder)

-- ── 件 4：Construct 层：严格序 < 自动长出非严格序 _≤ₘ_。
--   StrictToNonStrict 把 (x < y) ⊎ (x ≈ y) 打包成一个新 _≤_，并自带动一棵
--   IsTotalOrder / IsDecTotalOrder 树。
import Relation.Binary.Construct.StrictToNonStrict _≡_ _<_ as STNS

-- 用 < 的严格全序翻出『判定版非严格全序』，不用手写任何一列字段。
<-decTotalOrder : IsDecTotalOrder _≡_ STNS._≤_
<-decTotalOrder = STNS.isDecTotalOrder <-isStrictTotalOrder

-- ── 件 5：Reasoning 挂接：PartialOrder 走 Base.Triple，同时备好
--   begin_（证 ≤ / <）与 begin-equality_（证 ≈）两条起跑线。
open import Data.Nat.Properties using (≤-poset)
open import Relation.Binary.Reasoning.PartialOrder ≤-poset

-- 一条 ≤ 链：把 n ≤ n + 1 用 ≤-Reasoning 写出来。注意必须用 begin_ 起步：
-- ∎ 产出 equals，但每经过一步 ≤⟨⟩（≤-go）就被降为 nonstrict，链值最终是
-- nonstrict；begin-equality 的 IsEquality? 只认 equals，证 ≤ 的链编不过。
open import Data.Nat.Properties using (≤-refl; m≤n⇒m≤n+o)

mixed : ∀ n → n ≤ n + 1
mixed n = begin
  n        ≤⟨ ≤-refl ⟩
  n        ≤⟨ m≤n⇒m≤n+o 1 ≤-refl ⟩
  n + 1    ∎