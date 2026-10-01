----------------------------------------------------------------
-- 15 W 类型与良序 —— Agda 侧（与 Lean/Coq 版同构）
-- Agda 的终止检查器直接接受「经 f 的递归调用」——W 递归
-- 用模式匹配写，观感最接近数学定义
----------------------------------------------------------------

open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.Nat using (ℕ; zero; suc; _+_)
open import Data.Unit using (⊤; tt)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---- W：一个构造子走天下 ----

data W (A : Set) (B : A → Set) : Set where
  sup : (a : A) → (B a → W A B) → W A B

-- ---- 编码一：三标签树 ----

data Tag : Set where
  leaf unary binary : Tag

arity : Tag → Set
arity leaf   = ⊥
arity unary  = ⊤
arity binary = Bool

Tree : Set
Tree = W Tag arity

lf : Tree
lf = sup leaf λ()

nd1 : Tree → Tree
nd1 t = sup unary λ _ → t

nd2 : Tree → Tree → Tree
nd2 l r = sup binary λ b → if b then l else r

-- W 递归：孩子们经 f 喂给递归调用——终止检查器放行
size : Tree → ℕ
size (sup leaf f)   = 1
size (sup unary f)  = 1 + size (f tt)
size (sup binary f) = 1 + size (f true) + size (f false)

_ : size lf ≡ 1
_ = refl

_ : size (nd2 lf lf) ≡ 3
_ = refl

_ : size (nd1 (nd2 lf (nd1 lf))) ≡ 5
_ = refl

-- ---- 编码二：ℕ = W Bool ----

arityN : Bool → Set
arityN true  = ⊤
arityN false = ⊥

NatW : Set
NatW = W Bool arityN

zw : NatW
zw = sup false λ()

sw : NatW → NatW
sw n = sup true λ _ → n

toNat : NatW → ℕ
toNat (sup false _) = 0
toNat (sup true f)  = suc (toNat (f tt))

_ : toNat (sw (sw (sw zw))) ≡ 3
_ = refl

addW : NatW → NatW → NatW
addW (sup false _) n = n
addW (sup true f)  n = sw (addW (f tt) n)

_ : toNat (addW (sw (sw zw)) (sw (sw (sw zw)))) ≡ 5
_ = refl

-- ---- 表达力注记（与 Lean/Coq 版同文） ----
-- List A ≅ W Bool（true→A × ⊤）：标签可带负载；
-- 「归纳定义 = (标签集, 元数函数)」——归纳族的祖先。
