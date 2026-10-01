----------------------------------------------------------------
-- 16 子集类型与强制子类型 —— Agda 侧
-- Subset = Σ + 证明（stdlib Relation.Unary.Subset 即此思路）；
-- 强制子类型在 Agda 里【不是语言机制】：用普通函数手工喂
----------------------------------------------------------------

open import Data.Nat using (ℕ; zero; suc; _>_; _∸_; _*_; _+_; _⊔_; s≤s; z≤n)

open import Data.List using (List; []; _∷_; length)
open import Data.Product using (Σ; _,_; proj₁; proj₂; Σ-syntax)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---- 一、子集类型：Σ[ n ∈ ℕ ] n > 0 ----

PosSet : Set
PosSet = Σ[ n ∈ ℕ ] n > 0

one : PosSet
one = 1 , s≤s z≤n

-- 模式匹配里证据随值走；重建证据比搬运证据省事
doublePos : PosSet → PosSet
doublePos (suc k , _) = 2 * suc k , s≤s z≤n
  -- 2 * suc k 定义展开后是 suc 打头（+ 递归在第一参数），
  -- 所以 s≤s z≤n 直接居留

_ : proj₁ (doublePos one) ≡ 2
_ = refl

-- 安全前驱：要求 > 0 的分母/输入，规格写在类型里
safePred : Σ[ n ∈ ℕ ] n > 0 → ℕ
safePred (n , _) = n ∸ 1

_ : safePred one ≡ 0
_ = refl

-- ---- 二、extrinsic：裸 List + 谓词（对照 intrinsic 的 Vec） ----

open import Data.Empty using (⊥)
open import Data.Unit using (⊤; tt)

NonEmpty' : ∀ {A : Set} → List A → Set
NonEmpty' []       = ⊥
NonEmpty' (x ∷ xs) = ⊤

nel : Σ[ l ∈ List ℕ ] NonEmpty' l
nel = 1 ∷ 2 ∷ [] , tt

-- ---- 三、强制子类型：Agda 的立场 ----
-- 没有语言级 Coercion。要「把 Box 当 ℕ 用」，写普通函数并显式应用：

record Boxed : Set where
  constructor mkBox
  field unbox : ℕ
open Boxed public

boxed3 : Boxed
boxed3 = mkBox 3

-- Coq 里 boxed3 + 1 自动解箱；Agda 必须手工 unbox：
_ : ℕ
_ = unbox boxed3 + 1

-- 代价换收益：类型流里【没有任何隐式插入】——读到什么就是什么；
-- Luo 强制子类型理论的「展开后无痕」性质在这里是默认真理，
-- 因为根本没有展开这回事

-- ---- 四、Record 字段当「投影强制」的手工版 ----

record Point3 : Set where
  constructor mkPoint
  field px py pz : ℕ
open Point3 public

origin : Point3
origin = mkPoint 0 0 0

-- Coq 会把 px 注册成 Point3 >-> nat 的强制；Agda 里写 px origin
_ : ℕ
_ = px origin


