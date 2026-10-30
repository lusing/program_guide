-- 第 113 章：Σ¹₃ 集合与广泛贝尔——布劳威尔-克林序、双树互补、
-- 外延稳定性（定理 3.19 的机制核；本体留在正文 docs/113-sigma13.md）。
module Ch113_sigma13 where

open import Data.Nat using (ℕ; zero; suc; _≤_; z≤n; s≤s)
open import Data.Nat.Properties using (≤-refl; ≤-trans; m≤n⇒m≤1+n)
open import Data.List using (List; []; [_]; _∷_; _++_; take; length)
open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; sym; cong; trans)
open import Relation.Nullary using (¬_)
open import Data.Empty using (⊥; ⊥-elim)

-- ── 零、自建件（沿 110-112 章纪律：方程自建、不依赖外部形态） ──

-- 自建相等/小于判定：方程按构造子保留。
eq? : ℕ → ℕ → Bool
eq? zero zero = true
eq? zero (suc _) = false
eq? (suc _) zero = false
eq? (suc m) (suc n) = eq? m n

lt? : ℕ → ℕ → Bool
lt? zero zero = false
lt? zero (suc _) = true
lt? (suc _) zero = false
lt? (suc m) (suc n) = lt? m n

eq?-refl : ∀ n → eq? n n ≡ true
eq?-refl zero = refl
eq?-refl (suc n) = eq?-refl n

-- ── 一、布劳威尔-克林序（引理 3.20 机制核） ──
-- s <_BK t ⟺ t ⊏ s（真前段）∨ 首异位 s(k) < t(k)。
-- 递归扫描：右表先尽为真；表头相等下移；表头相异比大小。
bkLT : List ℕ → List ℕ → Bool
bkLT [] _ = false
bkLT (_ ∷ _) [] = true
bkLT (s₀ ∷ s') (t₀ ∷ t') = if eq? s₀ t₀ then bkLT s' t' else lt? s₀ t₀

-- 延伸者更小：s ++ [a] <_BK s（树枝的每一步都是递降）。
bkLT-app : ∀ (s : List ℕ) (a : ℕ) → bkLT (s ++ [ a ]) s ≡ true
bkLT-app [] a = refl
bkLT-app (b ∷ s') a rewrite eq?-refl b = bkLT-app s' a

-- ε 是最大元（定理 3.15(3)(a)）。
bkLT-[]-max : ∀ s → ¬ (s ≡ []) → bkLT s [] ≡ true
bkLT-[]-max [] h = ⊥-elim (h refl)
bkLT-[]-max (b ∷ t) h = refl

-- ── 二、双树互补（定理 3.19 机制核） ──
-- caught p x：x 的每一段前缀都被树 p 接住（π[p] 的有限替身）。
caught : (List ℕ → Bool) → List ℕ → Set
caught p x = ∀ k → k ≤ length x → p (take k x) ≡ true

-- 首位分裂对：T = {ε} ∪ 0⌢ω^<ω，T* = {ε} ∪ 1⌢ω^<ω（T ∩ T* = {ε}）。
pT : List ℕ → Bool
pT [] = true
pT (b ∷ _) = eq? b 0

pS : List ℕ → Bool
pS [] = true
pS (b ∷ _) = eq? b 1

-- 「广泛」面：首位 0 的实数在一切深度都被 pT 接住。
caught-pT-zero : ∀ t → caught pT (0 ∷ t)
caught-pT-zero t zero h = refl
caught-pT-zero t (suc m) h = refl

caught-pS-one : ∀ t → caught pS (1 ∷ t)
caught-pS-one t zero h = refl
caught-pS-one t (suc m) h = refl

-- 根部独占交（T ∩ T* = {ε}）⟹ 投影不交（π[T] ∩ π[T*] = ∅）。
eq?-0-true : ∀ b → eq? b 0 ≡ true → b ≡ 0
eq?-0-true zero h = refl
eq?-0-true (suc b) ()

eq?-1-true : ∀ b → eq? b (suc zero) ≡ true → b ≡ suc zero
eq?-1-true zero ()
eq?-1-true (suc zero) h = refl
eq?-1-true (suc (suc b)) ()

0≢1 : zero ≡ suc zero → ⊥
0≢1 ()

no-dual-caught : ∀ b t → ¬ (caught pT (b ∷ t) × caught pS (b ∷ t))
no-dual-caught b t (h1 , h2) =
  0≢1 (trans (sym (eq?-0-true b e1)) (eq?-1-true b e2))
  where
  e1 : pT (take (suc zero) (b ∷ t)) ≡ true
  e1 = h1 (suc zero) (s≤s z≤n)
  e2 : pS (take (suc zero) (b ∷ t)) ≡ true
  e2 = h2 (suc zero) (s≤s z≤n)

-- ── 三、外延稳定性（定理 3.19 (3) 的 ⊩ 面） ──

-- 自建方程：k ≤ length x 时 take k (x ++ [a]) = take k x。
take-snoc≤ : ∀ (x : List ℕ) (a k : ℕ) → k ≤ length x →
  take k (x ++ [ a ]) ≡ take k x
take-snoc≤ [] a zero h = refl
take-snoc≤ [] a (suc k) ()
take-snoc≤ (b ∷ t) a zero h = refl
take-snoc≤ (b ∷ t) a (suc k) (s≤s h) =
  cong (_∷_ b) (take-snoc≤ t a k h)

-- 自建方程：snoc 后长度恰加一。
length-snoc : ∀ (x : List ℕ) (a : ℕ) → length (x ++ [ a ]) ≡ suc (length x)
length-snoc [] a = refl
length-snoc (b ∷ t) a = cong suc (length-snoc t a)

-- 新实数 x ++ [a] 被接住 ⟹ 旧实数 x 仍被接住。
caught-shrink : ∀ p x a → caught p (x ++ [ a ]) → caught p x
caught-shrink p x a h k hk =
  trans (cong p (sym (take-snoc≤ x a k hk))) (h k (≤snoc x a k hk))
  where
  ≤snoc : ∀ y a j → j ≤ length y → j ≤ length (y ++ [ a ])
  ≤snoc y a j hj rewrite length-snoc y a = ≤-trans hj (m≤n⇒m≤1+n ≤-refl)

-- ── 四、样本对拍（与 Julia/Python/Lean/Coq 同账） ──

bk-sample-01 : bkLT (0 ∷ 1 ∷ []) (1 ∷ 0 ∷ []) ≡ true
bk-sample-01 = refl

bk-sample-10 : bkLT (1 ∷ 0 ∷ []) (0 ∷ 1 ∷ []) ≡ false
bk-sample-10 = refl

bk-sample-prefix : bkLT (0 ∷ 0 ∷ 1 ∷ []) (0 ∷ 0 ∷ []) ≡ true
bk-sample-prefix = refl

branch-chain-sample :
  (bkLT (0 ∷ 1 ∷ 1 ∷ []) (0 ∷ 1 ∷ []) ≡ true)
  × ((bkLT (0 ∷ 1 ∷ []) (0 ∷ []) ≡ true)
  × (bkLT (0 ∷ []) [] ≡ true))
branch-chain-sample = refl , refl , refl
