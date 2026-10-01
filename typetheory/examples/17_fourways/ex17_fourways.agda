----------------------------------------------------------------
-- 17 四大助手对照 —— Agda 版：reverse (reverse xs) = xs
-- 没有 tactic 与 simp：全部证据手写，cong 是唯一传送带
----------------------------------------------------------------

open import Data.List.Base using (List; []; _∷_; _++_)
open import Data.List.Properties using (++-identityʳ; ++-assoc)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong; sym; trans; module ≡-Reasoning)

-- 自造 reverse（append 版，与 Lean/Coq 版同构）
rev : ∀ {A : Set} → List A → List A
rev []       = []
rev (x ∷ xs) = rev xs ++ (x ∷ [])

-- 关键引理：rev (xs ++ ys) ≡ rev ys ++ rev xs
-- 两步组合：归纳假设顶着尾巴 ++ [x]，再右移括号
rev-append : ∀ {A : Set} (xs ys : List A) →
  rev (xs ++ ys) ≡ rev ys ++ rev xs
rev-append []       ys = sym (++-identityʳ (rev ys))
rev-append (x ∷ xs) ys =
  trans (cong (_++ (x ∷ [])) (rev-append xs ys))
        (++-assoc (rev ys) (rev xs) (x ∷ []))

-- 主定理：反转两次回到自身
rev-rev : ∀ {A : Set} (xs : List A) → rev (rev xs) ≡ xs
rev-rev []       = refl
rev-rev (x ∷ xs) =
  trans (rev-append (rev xs) (x ∷ []))
        (cong (x ∷_) (rev-rev xs))

-- 实测（refl 即执行）
_ : rev (1 ∷ 2 ∷ 3 ∷ []) ≡ 3 ∷ 2 ∷ 1 ∷ []
_ = refl

_ : rev (rev (1 ∷ 2 ∷ 3 ∷ [])) ≡ 1 ∷ 2 ∷ 3 ∷ []
_ = rev-rev (1 ∷ 2 ∷ 3 ∷ [])

-- 与另两家的差异速记：
-- ① 无 tactic：rev-append 是两条 trans/cong 的【组合子拼装】，
--   证明即程序，可以 #eval 式检验（上面的 refl）；
-- ② 引理方向要自己挑（sym 转向）；
-- ③ 没有 simp 的「全家桶」——但也没有 simp 的「黑盒时刻」。
