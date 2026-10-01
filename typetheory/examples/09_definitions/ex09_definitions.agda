----------------------------------------------------------------
-- 09 定义与证明工程（λD 精神）—— Agda 侧
-- Agda 的立场：定义永远透明（δ 无墙），组织靠 module 体系：
-- 参数化模块 ≈ Coq 的 Section + Variables；private ≈ 局部；
-- where ≡ 定义尾部的辅助块
----------------------------------------------------------------

open import Data.Nat using (ℕ; zero; suc; _+_; _*_)
open import Data.List using (List; []; _∷_; _++_; length)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

-- ---- ① 全局定义：透明 δ ----
twice : (ℕ → ℕ) → ℕ → ℕ
twice f n = f (f n)

_ : twice (λ n → n + 3) 1 ≡ 7
_ = refl                              -- refl 直接穿透定义（无墙可设）

-- ---- ② 局部：let 与 where ----
local-demo : ℕ
local-demo = let x = 2; y = 40 in x + y

-- where 块：辅助函数挂在尾部
length² : ∀ {A : Set} → List A → ℕ
length² xs = sq (length xs)
  where
    sq : ℕ → ℕ
    sq n = n * n

-- ---- ③ private：模块内的私有定义 ----
module Sort (A : Set) (_≤_ : A → A → Set) where

  private
    -- 只在本模块可见
    insert : A → List A → List A
    insert x [] = x ∷ []
    insert x (y ∷ ys) with x ≤ y
    ... | _ = x ∷ y ∷ ys              -- 教学占位：真实现要依赖 ≤ 的全序性

  insert-sort : List A → List A
  insert-sort [] = []
  insert-sort (x ∷ xs) = insert x (insert-sort xs)

-- 参数化模块 ≈ Coq Section：一次声明，多处开箱
open Sort ℕ (λ m n → m + n ≡ n + m)   -- 「≤」配一个二元关系（教学占位）

-- 排序正确性（插入位置由 ≤ 的证明形状决定）需要全序公理才可证；
-- 本文件只把 Sort 用作【模块机制】演示，不算序。
_ : ℕ
_ = length (insert-sort (3 ∷ 1 ∷ 2 ∷ []))

-- ---- ④ 记法 ----
infixr 5 _⨯_
_⨯_ : ℕ → ℕ → ℕ
m ⨯ n = m * n + m + n

_ : 2 ⨯ 3 ≡ 11
_ = refl

-- ---- ⑤ λD 视角：Agda 的「无墙」哲学 ----
-- Coq 的 Qed / Lean 的 opaque 把引理变不透明；Agda 没有这个开关：
-- 一切定义皆可 δ 展开。代价：性能敏感处要靠编译器旗标
-- 与抽象（不导出实现）控制；收益：refl 的「按定义成立」
-- 永远是全功率的——本章 twice 的 refl 就是活例。
