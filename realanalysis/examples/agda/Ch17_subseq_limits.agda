-- Chapter 17: 4^2 has already passed 10, and the even indices 2, 4, 6
-- keep moving forward.
module Ch17_subseq_limits where

open import Data.Nat using (ℕ; suc; _<_; _+_; _*_)
open import Data.Nat.Properties using (n<1+n; <-trans)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 4² = 16，已经严格大于 10。平方序列会越过任意固定的界。
four-sq : 4 * 4 ≡ 16
four-sq = refl

ten-lt-sixteen : 10 < 16
ten-lt-sixteen =
  <-trans (n<1+n 10)
    (<-trans (n<1+n 11)
      (<-trans (n<1+n 12)
        (<-trans (n<1+n 13)
          (<-trans (n<1+n 14) (n<1+n 15)))))

-- 偶数下标 2, 4, 6 严格递增，用来抽出发散到正无穷的子序列。
even-step : 2 < 4
even-step = <-trans (n<1+n 2) (n<1+n 3)

even-next : 4 < 6
even-next = <-trans (n<1+n 4) (n<1+n 5)
