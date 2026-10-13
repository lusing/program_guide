-- 第 19 章 CH 独立性：ccc 条件（骨架）
module Ch19_ccc where

open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Nat using (ℕ; zero; suc)
open import Data.Product using (_×_; _,_; ∃)

-- Cohen 条件：(域点, 值) 的有限列表
data Cond : Set where
  cnil  : Cond
  ccons : (ℕ × ℕ × Bool) → Cond → Cond

-- 简化版相容性骨架（完整版需 lookup 与等号判定）
-- ccc 的构造性证明见 docs 讲义。

-- 泛型实数的名字
Name : Set
Name = Cond

-- ccc 保持基数（引理 19.2 的语义声明）
postulate
  ccc-preserves : ∀ (P : Set) → Set
