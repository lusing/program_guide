-- Chapter 18: 1/11^2 is already smaller than 1/10, and (1/2)^10 = 1/1024
-- is smaller than 1/100. The binomial comparison is 9/4 > 8/4.
module Ch18_special where

open import Data.Nat using (ℕ; suc; _<_; _+_; _*_; _^_)
open import Data.Nat.Properties using (n<1+n; <-trans; m<m*n; *-monoʳ-<; ^-monoʳ-<)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; subst; subst₂; sym)

-- 11² = 121。10 < 11 < 11*11，所以 10 < 121，也就是 1/121 < 1/10。
eleven-sq : 11 * 11 ≡ 121
eleven-sq = refl

one-lt-11 : 1 < 11
one-lt-11 =
  <-trans (n<1+n 1)
    (<-trans (n<1+n 2)
      (<-trans (n<1+n 3)
        (<-trans (n<1+n 4)
          (<-trans (n<1+n 5)
            (<-trans (n<1+n 6)
              (<-trans (n<1+n 7)
                (<-trans (n<1+n 8)
                  (<-trans (n<1+n 9) (n<1+n 10)))))))))

ten-lt-sq : 10 < 121
ten-lt-sq = subst (10 <_) eleven-sq (<-trans (n<1+n 10) (m<m*n 11 11 one-lt-11))

-- (3/2)² = 9/4，1 + 2*(1/2) = 2 = 8/4。9 > 8。
three-sq : 3 * 3 ≡ 9
three-sq = refl

eight-lt-nine : 8 < 9
eight-lt-nine = n<1+n 8

-- 2^10 = 1024。100 < 4*32 = 128 = 2^7 < 2^10，所以 100 < 1024。
two-seven : 2 ^ 7 ≡ 128
two-seven = refl

two-ten : 2 ^ 10 ≡ 1024
two-ten = refl

twentyfive-lt-thirtytwo : 25 < 32
twentyfive-lt-thirtytwo =
  <-trans (n<1+n 25)
    (<-trans (n<1+n 26)
      (<-trans (n<1+n 27)
        (<-trans (n<1+n 28)
          (<-trans (n<1+n 29)
            (<-trans (n<1+n 30) (n<1+n 31))))))

four-twentyfive : 4 * 25 ≡ 100
four-twentyfive = refl

four-thirtytwo : 4 * 32 ≡ 128
four-thirtytwo = refl

hundred-lt-128 : 100 < 128
hundred-lt-128 =
  subst₂ _<_ four-twentyfive four-thirtytwo (*-monoʳ-< 4 twentyfive-lt-thirtytwo)

seven-lt-ten : 7 < 10
seven-lt-ten = <-trans (n<1+n 7) (<-trans (n<1+n 8) (n<1+n 9))

pow-gap : 2 ^ 7 < 2 ^ 10
pow-gap = ^-monoʳ-< 2 (n<1+n 1) seven-lt-ten

hundred-lt-1024 : 100 < 1024
hundred-lt-1024 =
  subst (100 <_) two-ten
    (<-trans (subst (100 <_) (sym two-seven) hundred-lt-128) pow-gap)
