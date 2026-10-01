----------------------------------------------------------------
-- 02 无类型 λ 演算 —— Agda 镜像实现（与 ex02_lambda.lean 同构）
-- 终止检查器视角：shift/subst 是结构递归，normalizeFuel 靠燃料
----------------------------------------------------------------

open import Data.Nat using (ℕ; zero; suc; _≤?_; _≟_)
open import Data.Bool using (if_then_else_)
open import Data.Maybe using (Maybe; just; nothing; map)
open import Data.Integer using (ℤ; +_; -[1+_]; _+_; ∣_∣)
open import Relation.Nullary.Decidable using (⌊_⌋)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---- 项 ----
data Term : Set where
  var : ℕ → Term
  lam : Term → Term
  app : Term → Term → Term

-- ℤ → ℕ：只在结果非负处调用（β 的良构性保证）
zToN : ℤ → ℕ
zToN z = ∣ z ∣

-- ---- 平移：结构递归，终止检查器直接放行 ----
shift : ℤ → ℕ → Term → Term
shift d c (var k) = if ⌊ c ≤? k ⌋ then var (zToN (+ k + d)) else var k
shift d c (lam b) = lam (shift d (suc c) b)
shift d c (app f a) = app (shift d c f) (shift d c a)

-- ---- 代换：进入绑定器时 j+1 且整体上移 s ----
subst : ℕ → Term → Term → Term
subst j s (var k) = if ⌊ k ≟ j ⌋ then s else var k
subst j s (lam b) = lam (subst (suc j) (shift (+ 1) zero s) b)
subst j s (app f a) = app (subst j s f) (subst j s a)

-- ---- β 单步（normal order）：递归只在直接子项上，结构终止 ----
step : Term → Maybe Term
step (app (lam b) a) =
  just (shift -[1+ 0 ] zero (subst zero (shift (+ 1) zero a) b))
step (app f a) with step f
... | just f′ = just (app f′ a)
... | nothing = map (λ a′ → app f a′) (step a)
step (lam b) = map lam (step b)
step (var _) = nothing

-- ---- 带燃料规范化：燃料参数让终止检查器满意（step 的不变式由人保证）----
normalizeFuel : ℕ → Term → Term
normalizeFuel zero    t = t
normalizeFuel (suc n) t with step t
... | nothing = t
... | just t′ = normalizeFuel n t′

-- ---- Church 数 ----
iter : ℕ → Term → Term → Term
iter zero    s z = z
iter (suc n) s z = app s (iter n s z)

cnum : ℕ → Term
cnum n = lam (lam (iter n (var 1) (var 0)))

-- λm n f x. ((m f) ((n f) x))
cplus : Term
cplus = lam (lam (lam (lam (app (app (var 3) (var 1))
                               (app (app (var 2) (var 1)) (var 0))))))

-- λm n f. (m (n f))
cmul : Term
cmul = lam (lam (lam (app (var 2) (app (var 1) (var 0)))))

-- λm n. (n m)
cexp : Term
cexp = lam (lam (app (var 0) (var 1)))

-- ---- 解码 ----
countApps : Term → Maybe ℕ
countApps (app (var 1) (var 0)) = just 1
countApps (app (var 1) rest) = map suc (countApps rest)
countApps _ = nothing

decodeCnum : Term → Maybe ℕ
decodeCnum (lam (lam b)) = countApps b
decodeCnum _ = nothing

-- ---- 实测：与 Lean/Coq 版同一批 ----
add23 : decodeCnum (normalizeFuel 200 (app (app cplus (cnum 2)) (cnum 3))) ≡ just 5
add23 = refl

mul23 : decodeCnum (normalizeFuel 200 (app (app cmul (cnum 2)) (cnum 3))) ≡ just 6
mul23 = refl

exp23 : decodeCnum (normalizeFuel 500 (app (app cexp (cnum 2)) (cnum 3))) ≡ just 8
exp23 = refl

-- ---- S K K = I ----
K : Term
K = lam (lam (var 1))

S : Term
S = lam (lam (lam (app (app (var 2) (var 0)) (app (var 1) (var 0)))))

skk-is-I : normalizeFuel 100 (app (app S K) K) ≡ lam (var 0)
skk-is-I = refl

-- ---- Ω：发散 ----
omega : Term
omega = lam (app (var 0) (var 0))

Omega : Term
Omega = app omega omega

omega-step : step Omega ≡ just Omega
omega-step = refl

-- ---- 无捕获代换的经典现场：(λx. λy. x) z → λw. z ----
-- 自由变量 z（指标 0）移进 λy 时 shift 到 1；不做 shift 会被误捕获成 λy. y
capture-demo : step (app (lam (lam (var 1))) (var 0)) ≡ just (lam (var 1))
capture-demo = refl
