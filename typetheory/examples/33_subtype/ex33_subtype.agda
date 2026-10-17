----------------------------------------------------------------
-- 33 子集类型与强制子类型 —— Agda 侧
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



-- ---- 33.3 子集合理论 (A′,A″) 语义的最小模型（书 18 章） ----
-- 集合 = 载体 + 成员谓词的配对；相等只看载体（不带谓词）
open import Data.Empty using (⊥)
open import Data.Unit using (⊤; tt)

-- 偶数谓词（概括子集的 ″ 换岗——书 18.5/18.6）
mutual
  IsEven : ℕ → Set
  IsEven zero    = ⊤
  IsEven (suc n) = OddE n
  OddE : ℕ → Set
  OddE zero    = ⊥
  OddE (suc n) = IsEven n

record SSet : Set₁ where
  field carrier : Set
        mem : carrier → Set
open SSet public

-- 自然数的翻译：N′ = ℕ，N″ = (z)⊤（全员通过——书 18.6.3）
NatS : SSet
NatS = record { carrier = ℕ ; mem = λ _ → ⊤ }

-- 偶数的翻译：概括 {x∈ℕ|Even} 的 ″ 换岗为谓词（书 18.5）
EvenS : SSet
EvenS = record { carrier = ℕ ; mem = IsEven }

-- 成员判断：载体元素 + 谓词证据
_∈ₛ_ : (S : SSet) → carrier S → Set
S ∈ₛ a = mem S a

-- 相等只看载体：谓词不进相等判断（书 18.2.4 的语义）
EqS : (S : SSet) → carrier S → carrier S → Set
EqS S a b = a ≡ b

-- 见证：2 是偶数（证据随值走）；0 是自然数（⊤ 直接 tt）
two-even : EvenS ∈ₛ 2
two-even = tt

zero-nat : NatS ∈ₛ zero
zero-nat = tt

-- 谓词证据不进相等：EqS EvenS 2 2 用 refl 即居留（mem 不出场）
eq-carrier-only : EqS EvenS 2 2
eq-carrier-only = refl
