{-# OPTIONS --guardedness #-}
----------------------------------------------------------------
-- 18 程序即证明：编译与运行 —— Agda 侧（MAlonzo → GHC）
-- 文件名以 _run.agda 结尾：build.ps1 会 --compile 并执行 main
-- 证明在类型层干活，main 只跑【程序】那半边
----------------------------------------------------------------

open import Data.Nat using (ℕ; suc; _*_)
open import Data.Nat.Show using (show)
open import Data.List using (List; []; _∷_; length; map)
open import Data.String using (String; _++_)
open import Function using (_$_)
open import IO using (putStrLn; Main; run; _>>_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; trans)

-- 带证明的程序：插入（教学简化版：恒插队首）+ 长度保持
insert : ℕ → List ℕ → List ℕ
insert x []       = x ∷ []
insert x (y ∷ ys) = x ∷ y ∷ ys

sort : List ℕ → List ℕ
sort []       = []
sort (x ∷ xs) = insert x (sort xs)

-- 长度保持：证明本身是程序（refl 可检）
length-insert : ∀ x ys → length (insert x ys) ≡ suc (length ys)
length-insert x []       = refl
length-insert x (y ∷ ys) = refl

sort-length : (xs : List ℕ) → length (sort xs) ≡ length xs
sort-length []       = refl
sort-length (x ∷ xs) = trans (length-insert x (sort xs)) (cong suc (sort-length xs))

square : ℕ → ℕ
square n = n * n

_ : map square (1 ∷ 2 ∷ 3 ∷ []) ≡ 1 ∷ 4 ∷ 9 ∷ []
_ = refl

showList : List ℕ → String
showList []       = "[]"
showList (x ∷ xs) = show x ++ " ∷ " ++ showList xs

main : Main
main = run $ do
  putStrLn $ "sort (3 ∷ 1 ∷ 2 ∷ []) = " ++ showList (sort (3 ∷ 1 ∷ 2 ∷ []))
  putStrLn $ "map square 1..3 = " ++ showList (map square (1 ∷ 2 ∷ 3 ∷ []))
  putStrLn "length proof: refl-checkable, erased at runtime"
