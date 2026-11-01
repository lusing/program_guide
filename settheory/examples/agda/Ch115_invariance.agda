-- 第 115 章：Lévy 扩张正则性与 L(ℝ) 理论不变性——对称保真、
-- 双点不变证书与博雷尔包裹（引理 3.23(3)/定理 3.26-3.27 的机制核；
-- 本体留在正文 docs/115-invariance.md）。
module Ch115_invariance where

open import Data.Nat using (ℕ; zero; suc)
open import Data.Bool using (Bool; true; false; not; _∧_; _∨_)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; trans; sym)
open import Relation.Nullary using (¬_)
open import Data.Empty using (⊥; ⊥-elim)

-- 自建 cong₂（112 章纪律：PropositionalEquality 不导出）。
cong₂ : {A B C : Set} → (f : A → B → C) → {x y : A} → {u w : B} →
        x ≡ y → u ≡ w → f x u ≡ f y w
cong₂ f refl refl = refl

-- ── 一、三点底集上的对换 τ = swap(0,1) ──
tau : ℕ → ℕ
tau zero = suc zero
tau (suc zero) = zero
tau (suc (suc n)) = suc (suc n)

tau-tau : ∀ i → tau (tau i) ≡ i
tau-tau zero = refl
tau-tau (suc zero) = refl
tau-tau (suc (suc n)) = refl

-- ── 二、子集与布尔值模型 ──
subset : Set
subset = ℕ → Bool

tb : subset → subset
tb b i = b (tau i)

cpl : subset → subset
cpl b i = not (b i)

itr : subset → subset → subset
itr a b i = a i ∧ b i

uno : subset → subset → subset
uno a b i = a i ∨ b i

-- ── 三、公式与布尔值 ──
data formula : Set where
  var : ℕ → formula
  neg : formula → formula
  conj : formula → formula → formula
  disj : formula → formula → formula

bval : formula → (ℕ → subset) → subset
bval (var n) v = v n
bval (neg f) v = cpl (bval f v)
bval (conj f g) v = itr (bval f v) (bval g v)
bval (disj f g) v = uno (bval f v) (bval g v)

tv : (ℕ → subset) → ℕ → subset
tv v n = tb (v n)

-- ── 四、件 E（对称保真）：布尔值与公式同步变换 ──
bval-perm : ∀ f v → bval f (tv v) ≡ tb (bval f v)
bval-perm (var n) v = refl
bval-perm (neg f) v = cong cpl (bval-perm f v)
bval-perm (conj f g) v = cong₂ itr (bval-perm f v) (bval-perm g v)
bval-perm (disj f g) v = cong₂ uno (bval-perm f v) (bval-perm g v)

-- ── 五、件 A：滤子共轭与双点不变证书 ──
F-conj : ∀ i b → tb b (tau i) ≡ b i
F-conj i b = cong b (tau-tau i)

memF : ℕ → subset → Set
memF i b = b i ≡ true

-- 函数等式的点级实例化。
point-eq : ∀ (s : subset) → tb s ≡ s → ∀ i → s i ≡ tb s i
point-eq s h i = sym (cong (λ g → g i) h)

-- 旗舰（双点不变证书）：τ-不变公式的布尔值在共轭双点上真值相等。
-- 中间项 tb s (suc zero) 定义性归约为 s (tau (suc zero)) = s zero。
tau-inv-eval : ∀ f v →
  tb (bval f v) ≡ bval f v →
  (memF zero (bval f v) → memF (suc zero) (bval f v)) ×
  (memF (suc zero) (bval f v) → memF zero (bval f v))
tau-inv-eval f v hinv =
  (λ h₀ → trans (point-eq (bval f v) hinv (suc zero)) h₀) ,
  (λ h₁ → trans (point-eq (bval f v) hinv zero) h₁)

-- 非不变布尔值在双点上翻车——不变性必须限定公式（边界反例）。
pt0 : subset
pt0 zero = true
pt0 (suc zero) = false
pt0 (suc (suc n)) = false

pt0-counter : memF zero pt0 × (pt0 (suc zero) ≡ false)
pt0-counter = refl , refl

-- ── 六、件 B：博雷尔包裹的 mod-I 同余（引理 3.23(3) 的 A₁ 机制） ──
-- 点集语义：S（旧实数影子）与 X（星形）为 Bool 谓词；A₁ = X ∧ S。
and-true : ∀ {p q : Bool} → p ≡ true → q ≡ true → p ∧ q ≡ true
and-true refl refl = refl

and-false-left : ∀ (q : Bool) → false ∧ q ≡ false
and-false-left q = refl

inS : ℕ → Bool
inS zero = true
inS (suc zero) = false
inS (suc (suc n)) = true

inX : ℕ → Bool
inX zero = true
inX (suc zero) = false
inX (suc (suc zero)) = true
inX (suc (suc (suc zero))) = true
inX (suc (suc (suc (suc n)))) = false

inA1 : ℕ → Bool
inA1 x = inX x ∧ inS x

-- 在 S 上 X 与 A₁ 同真假（包裹方向）。
modI-eq : ∀ x → inS x ≡ true → (inX x ≡ true) → (inA1 x ≡ true)
modI-eq x hs hx = and-true hx hs

-- AND 的左分量反转。
and-t-l : ∀ {p q : Bool} → p ∧ q ≡ true → p ≡ true
and-t-l {true} {q} h = refl
and-t-l {false} {q} ()

-- 反向：A₁ 命中则 X 命中。
modI-back : ∀ x → inA1 x ≡ true → (inX x ≡ true)
modI-back x h = and-t-l {inX x} {inS x} h

-- S 上的相等（modI-agree）：S 命中处 X 与 A₁ 同布尔值。
modI-agree : ∀ x → inS x ≡ true → (inX x ≡ inA1 x)
modI-agree x hs with inX x
... | true = sym (cong (λ z → true ∧ z) hs)
... | false = refl

-- 差集全落理想：X 与 A₁ 真值相异处必在 S 之外。
modI-ideal : ∀ x → ¬ (inX x ≡ inA1 x) → inS x ≡ false
modI-ideal x h with inS x | modI-agree x
... | true | ag = ⊥-elim (h (ag refl))
... | false | _ = refl

-- 样本：星形 {0,2,3}（三点语义）的命中（与 Julia/Python 同账）。
star-0 : inX zero ≡ true
star-0 = refl

star-2 : inX (suc (suc zero)) ≡ true
star-2 = refl

star-1 : inX (suc zero) ≡ false
star-1 = refl

star-4 : inX (suc (suc (suc (suc zero)))) ≡ false
star-4 = refl
