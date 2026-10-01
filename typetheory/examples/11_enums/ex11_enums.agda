----------------------------------------------------------------
-- 11 Π 与枚举集合 —— Agda 侧（与 Lean/Coq 版同构）
-- 荒谬模式 () 是空集合消去子的语法化身
----------------------------------------------------------------

open import Data.Empty using (⊥; ⊥-elim)
open import Data.Unit using (⊤; tt)
open import Data.Bool using (Bool; true; false; not; _∧_; _∨_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

-- ---- 空集合：无构造子，荒谬模式消去 ----
Not2 : Set → Set
Not2 A = A → ⊥

-- 从 ⊥ 到任何东西：模式匹配穷尽（无构造子）——
-- 荒谬模式 () 就是「这里没有东西可匹配」的证据语法
absurd-any : {A : Set} → ⊥ → A
absurd-any ()

-- ---- 单元素集合 ----
unit-any : {A : Set} → A → ⊤ → A
unit-any a tt = a

-- ---- Bool：if 即消去子 ----
if2 : {A : Set} → Bool → A → A → A
if2 true  t e = t
if2 false t e = e

not' : Bool → Bool
not' b = if2 b false true

and' : Bool → Bool → Bool
and' a b = if2 a b false

or' : Bool → Bool → Bool
or' a b = if2 a true b

_ : not' true ≡ false
_ = refl

-- 德摩根：四行 case，每行 refl
demorgan : ∀ a b → not' (and' a b) ≡ or' (not' a) (not' b)
demorgan true  true  = refl
demorgan true  false = refl
demorgan false true  = refl
demorgan false false = refl

-- ---- 构造子互斥：refl 的模式直接荒谬 ----
true≢false : true ≡ false → ⊥
true≢false ()

-- ---- Π on Bool：依赖函数 = 两行填表 ----
bothCases : (P : Bool → Set) → P true → P false → ∀ b → P b
bothCases P pt pf true  = pt
bothCases P pt pf false = pf

-- 用例：类型随 b 变的选择函数（族先立，再填表）
Sel : Bool → Set
Sel true  = ⊤
Sel false = Bool

sel : (b : Bool) → Sel b
sel = bothCases Sel tt false

