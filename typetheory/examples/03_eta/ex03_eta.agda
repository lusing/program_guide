----------------------------------------------------------------
-- 03 η、βη 与 λI —— Agda 镜像实现（与 ex03_eta.lean 同构）
-- η-步进（occurs 检查 + 出绑定器平移）+ βη 两阶段 + λI 谓词
-- 依 Hindley BSTT 1C–1D
----------------------------------------------------------------

open import Data.Nat using (ℕ; zero; suc; _≤?_; _≟_) renaming (_+_ to _+ℕ_)
open import Data.Bool using (Bool; true; false; if_then_else_; _∧_; _∨_)
open import Data.Maybe using (Maybe; just; nothing; map)
open import Data.Integer using (ℤ; +_; -[1+_]; _+_; ∣_∣)
open import Relation.Nullary.Decidable using (⌊_⌋)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---- 项与 β 机器：与 02 章同一套（自包含复制） ----
data Term : Set where
  var : ℕ → Term
  lam : Term → Term
  app : Term → Term → Term

zToN : ℤ → ℕ
zToN z = ∣ z ∣      -- 只在结果非负处调用（机器口径保证）

shift : ℤ → ℕ → Term → Term
shift d c (var k) = if ⌊ c ≤? k ⌋ then var (zToN (+ k + d)) else var k
shift d c (lam b) = lam (shift d (suc c) b)
shift d c (app f a) = app (shift d c f) (shift d c a)

subst : ℕ → Term → Term → Term
subst j s (var k) = if ⌊ k ≟ j ⌋ then s else var k
subst j s (lam b) = lam (subst (suc j) (shift (+ 1) zero s) b)
subst j s (app f a) = app (subst j s f) (subst j s a)

step : Term → Maybe Term
step (app (lam b) a) =
  just (shift -[1+ 0 ] zero (subst zero (shift (+ 1) zero a) b))
step (app f a) with step f
... | just f′ = just (app f′ a)
... | nothing = map (λ a′ → app f a′) (step a)
step (lam b) = map lam (step b)
step (var _) = nothing

nfBeta : ℕ → Term → Term
nfBeta zero    t = t
nfBeta (suc n) t with step t
... | nothing = t
... | just t′ = nfBeta n t′

-- ---- η 层 ----
-- occurs：指标 k 是否出现（进绑定器 +1 补偿）
occurs : ℕ → Term → Bool
occurs k (var j) = ⌊ j ≟ k ⌋
occurs k (lam b) = occurs (suc k) b
occurs k (app f a) = occurs k f ∨ occurs k a

-- η 单步（最左外）。contractum 是 shift -1 0 t：t 的自由指标全体 ≥ 1，
-- 出绑定器后降 1——漏 shift 会把 f 认成隔壁变量。
etaStep : Term → Maybe Term
-- 先看整体是否 η-redex；不是（或 occurs 拦下）再递归进体内。
-- 递归参数必须是【子项变量】 b：Agda/Coq 终止检查都不认
-- 嵌套模式里「重建出来」的 app t (var zero)。
etaStep (lam b) with b
... | app t (var zero) =
    if occurs zero t then map lam (etaStep b)
    else just (shift -[1+ 0 ] zero t)
... | _ = map lam (etaStep b)
etaStep (app f a) with etaStep f
... | just f′ = just (app f′ a)
... | nothing = map (λ a′ → app f a′) (etaStep a)
etaStep (var _) = nothing

nfEta : ℕ → Term → Term
nfEta zero    t = t
nfEta (suc n) t with etaStep t
... | nothing = t
... | just t′ = nfEta n t′

-- βη 两阶段（1C9.5）：先 β 后 η
nfBetaEta : ℕ → Term → Term
nfBetaEta fuel t = nfEta fuel (nfBeta fuel t)

size : Term → ℕ
size (var _) = 1
size (lam b) = suc (size b)
size (app f a) = suc (size f +ℕ size a)

-- ---- λI 谓词 ----
isLI : Term → Bool
isLI (var _) = true
isLI (lam b) = occurs zero b ∧ isLI b
isLI (app f a) = isLI f ∧ isLI a

-- ---- 名角 ----
I : Term
I = lam (var 0)

K : Term
K = lam (lam (var 1))

S : Term
S = lam (lam (lam (app (app (var 2) (var 0)) (app (var 1) (var 0)))))

omega : Term
omega = lam (app (var 0) (var 0))

iter : ℕ → Term → Term → Term
iter zero    s z = z
iter (suc n) s z = app s (iter n s z)

cnum : ℕ → Term
cnum n = lam (lam (iter n (var 1) (var 0)))

-- ---- 实测一：η 基本功 ----
eta-basic : etaStep (lam (app (var 1) (var 0))) ≡ just (var 0)
eta-basic = refl

omega-eta-nf : etaStep omega ≡ nothing
omega-eta-nf = refl

K-not-LI : isLI K ≡ false
K-not-LI = refl

S-is-LI : isLI S ≡ true
S-is-LI = refl

omega-is-LI : isLI omega ≡ true
omega-is-LI = refl

cnum3-is-LI : isLI (cnum 3) ≡ true
cnum3-is-LI = refl

cnum0-not-LI : isLI (cnum 0) ≡ false
cnum0-not-LI = refl

-- ---- 实测二：β/η 两条路在 F 汇合 ----
F : Term
F = lam (app (var 1) (var 0))

N2 : Term
N2 = lam (app (shift (+ 1) zero F) (var 0))

eta-first : etaStep N2 ≡ just F
eta-first = refl

beta-first : step N2 ≡ just F
beta-first = refl

eta-F : etaStep F ≡ just (var 0)
eta-F = refl

nf-N2 : nfBetaEta 50 N2 ≡ var 0
nf-N2 = refl

nf-Ix : nfBetaEta 50 (lam (app I (var 0))) ≡ I
nf-Ix = refl

-- ---- 实测三：λI 不消元 / λK 消元 ----
selfApp : Term
selfApp = app (lam (app (var 0) (var 0))) (var 1)

selfApp-step : step selfApp ≡ just (app (var 1) (var 1))
selfApp-step = refl

selfApp-keep : occurs 1 (app (var 1) (var 1)) ≡ true
selfApp-keep = refl

swallow : Term
swallow = app (lam (lam (var 0))) (var 3)

swallow-step : step swallow ≡ just (lam (var 0))
swallow-step = refl

swallow-loses : occurs 3 (lam (var 0)) ≡ false
swallow-loses = refl

swallow-not-LI : isLI (lam (lam (var 0))) ≡ false
swallow-not-LI = refl

-- ---- 实测四：λI 对 βη 封闭（实例账） ----
SII-reduces : nfBetaEta 100 (app (app S I) I) ≡ omega
SII-reduces = refl

SII-stays-LI : isLI (nfBetaEta 100 (app (app S I) I)) ≡ true
SII-stays-LI = refl
