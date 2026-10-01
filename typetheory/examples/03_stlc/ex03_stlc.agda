----------------------------------------------------------------
-- 03 简单类型 λ→（Church 式）—— Agda：内在式（intrinsic）语法
-- 项的上下文与类型长在项的索引上：Tm Γ T 只装得下「Γ 中类型 T 的项」
-- 非法项（x x）不是「被拒绝」，是「无法表示」
----------------------------------------------------------------

open import Data.List using (List; _∷_; [])
open import Data.Nat using (ℕ; zero; suc)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

data Ty : Set where
  ι   : Ty                       -- 基类型
  _⇒_ : Ty → Ty → Ty             -- 函数类型（中缀构造子）

infixr 20 _⇒_

Cx : Set
Cx = List Ty

-- 变量：指标与类型双向绑定
data Var : Cx → Ty → Set where
  vz : ∀ {Γ σ}     → Var (σ ∷ Γ) σ
  vs : ∀ {Γ σ τ} → Var Γ τ → Var (σ ∷ Γ) τ

-- 内在式项：上下文与类型是索引
data Tm : Cx → Ty → Set where
  var : ∀ {Γ τ} → Var Γ τ → Tm Γ τ
  lam : ∀ {Γ σ τ} → Tm (σ ∷ Γ) τ → Tm Γ (σ ⇒ τ)
  app : ∀ {Γ σ τ} → Tm Γ (σ ⇒ τ) → Tm Γ σ → Tm Γ τ

-- ---- 组合子直接是居留项，类型自动长对 ----

I : Tm [] (ι ⇒ ι)
I = lam (var vz)

K : Tm [] (ι ⇒ ι ⇒ ι)
K = lam (lam (var (vs vz)))

S : Tm [] ((ι ⇒ ι ⇒ ι) ⇒ (ι ⇒ ι) ⇒ ι ⇒ ι)
S = lam (lam (lam (app (app (var (vs (vs vz))) (var vz))
                      (app (var (vs vz)) (var vz)))))

-- ---- 「λx. x x 无法表示」的真身 ----
-- app (var v) (var v) 要求同一个 v 既是 Var Γ (σ ⇒ τ) 又是 Var Γ σ，
-- 即解 σ ≡ σ ⇒ τ。而类型上没有不动点（结构归纳一拍即合）：

arrow-arg : ∀ {A B C D} → A ⇒ B ≡ C ⇒ D → A ≡ C
arrow-arg {A} {B} {.A} {D} refl = refl

-- σ ≡ σ ⇒ τ 不可满足：结构归纳两行
¬fixpoint : ∀ σ τ → σ ≡ σ ⇒ τ → ⊥
¬fixpoint ι       τ ()
¬fixpoint (σ ⇒ s) τ p = ¬fixpoint σ s (arrow-arg p)

-- 于是「给 x x 配型」需要 ¬fixpoint 的反例 —— 不存在；
-- 统一器当场报 Cannot solve unification problem。

-- ---- 改名/弱化：结构递归，终止检查器放行 ----
rename : ∀ {Γ Δ} → (∀ {τ} → Var Γ τ → Var Δ τ)
       → ∀ {τ} → Tm Γ τ → Tm Δ τ
rename ρ (var v)   = var (ρ v)
rename ρ (lam b)   = lam (rename (λ { vz → vz ; (vs v) → vs (ρ v) }) b)
rename ρ (app f a) = app (rename ρ f) (rename ρ a)

-- 弱化：封闭项可以放进任何上下文（环境版「裁剪」）
weaken : ∀ {Γ τ} → Tm [] τ → Tm Γ τ
weaken t = rename (λ ()) t

weaken-I : ∀ {Γ} → Tm Γ (ι ⇒ ι)
weaken-I = weaken I

-- ---- 环境求值器：闭包法，de Bruijn 变量 = 查表函数 ----

mutual
  data Val : Ty → Set where
    clos : ∀ {Γ σ τ} → Tm (σ ∷ Γ) τ → Env Γ → Val (σ ⇒ τ)
    bogus : ∀ {τ} → Val τ          -- 燃料耗尽哨兵（良式封闭项上不可达）

  Env : Cx → Set
  Env Γ = ∀ {τ} → Var Γ τ → Val τ

  extend : ∀ {Γ σ} → Val σ → Env Γ → Env (σ ∷ Γ)
  extend v ρ vz     = v
  extend v ρ (vs w) = ρ w

  -- 燃料在 apply/eval 之间严格递减，终止检查器按参数 n 放行
  apply : ℕ → ∀ {σ τ} → Val (σ ⇒ τ) → Val σ → Val τ
  apply zero    (clos b ρ) v = bogus
  apply (suc n) (clos b ρ) v = eval n b (extend v ρ)
  apply _       bogus     v = bogus

  eval : ℕ → ∀ {Γ τ} → Tm Γ τ → Env Γ → Val τ
  eval zero    _         ρ = bogus
  eval (suc n) (var v)   ρ = ρ v
  eval (suc n) (lam b)   ρ = clos b ρ
  eval (suc n) (app f a) ρ = apply n (eval n f ρ) (eval n a ρ)

-- ---- 实测：SKI 恒等式的单态版（环境求值到底） ----
-- 注意：无类型世界里的 S K K = I，在单态 λ→ 里第二个 K 根本无法以
-- K 的类型落位（S 的第二参要 σ⇒σ，而 K 是 σ⇒σ⇒σ）——它只能被写成
-- 一个恒等函数。让一份代码身兼多型，正是 System F 要解决的问题（06 章）。

K₁ : Tm [] ((ι ⇒ ι) ⇒ (ι ⇒ ι) ⇒ (ι ⇒ ι))       -- K 用作 S 的第一参
K₁ = lam (lam (var (vs vz)))

I₂ : Tm [] ((ι ⇒ ι) ⇒ (ι ⇒ ι))                  -- 第二参只能是恒等
I₂ = lam (var vz)

S' : Tm [] (((ι ⇒ ι) ⇒ (ι ⇒ ι) ⇒ (ι ⇒ ι))    -- S 取 σ = ι ⇒ ι 实例化
        ⇒ ((ι ⇒ ι) ⇒ (ι ⇒ ι)) ⇒ (ι ⇒ ι) ⇒ (ι ⇒ ι))
S' = lam (lam (lam (app (app (var (vs (vs vz))) (var vz))
                       (app (var (vs vz)) (var vz)))))

ε : Env []
ε ()

-- S K I x = K x (I x) = x：单态化后依旧成立
ski-is-I : apply 100 (eval 100 (app (app S' K₁) I₂) ε) (eval 100 I ε)
        ≡ eval 100 I ε
ski-is-I = refl

-- 自组合：I₂ : (ι⇒ι)⇒(ι⇒ι) 作用在 I : ι⇒ι 上（参数类型恰好对上）
I2I : apply 100 (eval 100 I₂ ε) (eval 100 I ε) ≡ eval 100 I ε
I2I = refl
