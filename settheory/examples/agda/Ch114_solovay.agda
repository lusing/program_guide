-- 第 114 章：Solovay 内模型与 HOD(Ω)——参数化定义、群作用、
-- 轨道递归、配对整合与 DC 链（引理 3.22 的机制核；本体留在正文
-- docs/114-solovay.md）。
module Ch114_solovay where

open import Data.Nat using (ℕ; zero; suc; _+_; _*_; _∸_)
open import Data.List using (List; []; _∷_)
open import Data.Product using (_×_; _,_)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Unit using (⊤; tt)
open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ── 零、自建件（沿 110-113 章纪律：方程按构造子保留） ──

eq? : ℕ → ℕ → Bool
eq? zero zero = true
eq? zero (suc _) = false
eq? (suc _) zero = false
eq? (suc m) (suc n) = eq? m n

-- ≥8 判定（八层构造子枚举）。
ge8? : ℕ → Bool
ge8? zero = false
ge8? (suc zero) = false
ge8? (suc (suc zero)) = false
ge8? (suc (suc (suc zero))) = false
ge8? (suc (suc (suc (suc zero)))) = false
ge8? (suc (suc (suc (suc (suc zero))))) = false
ge8? (suc (suc (suc (suc (suc (suc zero)))))) = false
ge8? (suc (suc (suc (suc (suc (suc (suc zero))))))) = false
ge8? (suc (suc (suc (suc (suc (suc (suc (suc _)))))))) = true

-- mod-8 归一（燃料递归——本章「轨道递归」的算术面）。
mod8' : ℕ → ℕ → ℕ
mod8' zero n = n
mod8' (suc f) n = if ge8? n then mod8' f (n ∸ 8) else n

mod8 : ℕ → ℕ
mod8 n = mod8' (suc n) n

-- ── 一、生成元与参数化谓词（OD 的影子） ──

rot : ℕ → ℕ
rot x = mod8 (x + 2)

-- 三点星形谓词的布尔化身：x ∈ {k, k+3, k+5}（mod 8）。
odefB : ℕ → ℕ → Bool
odefB k x =
  if eq? (mod8 x) (mod8 k) then true else
  if eq? (mod8 x) (mod8 (k + 3)) then true else
  eq? (mod8 x) (mod8 (k + 5))

-- ── 二、轨道递归（燃料递归生成 + 定义性方程） ──

orbit : ℕ → ℕ → List ℕ
orbit zero x = []
orbit (suc f) x = x ∷ orbit f (rot x)

-- 定义性方程（unfold 一步）。
orbit-cons : ∀ f x → orbit (suc f) x ≡ x ∷ orbit f (rot x)
orbit-cons f x = refl

-- 成员谓词（自建）。
inL : ℕ → List ℕ → Set
inL x [] = ⊥
inL x (y ∷ t) = (x ≡ y) ⊎ (inL x t)

-- 轨道封闭的种子一步：rot x 是轨道的第二成员。
orbit-step : ∀ f x → inL (rot x) (orbit (suc (suc f)) x)
orbit-step f x = inj₂ (inj₁ refl)

-- ── 三、窗口配对（引理 3.22(1) 的哥德尔对应之有限替身） ──

gpair : ℕ → ℕ → ℕ
gpair m k = m + 8 * k

-- ── 四、DC 链（引理 3.22(2) 机制核——本章 Agda 件旗舰） ──

chain : (ℕ → ℕ) → ℕ → ℕ → List ℕ
chain next a zero = []
chain next a (suc d) = a ∷ chain next (next a) d

-- 逐对检查谓词。
adjAll : (ℕ → ℕ → Set) → List ℕ → Set
adjAll R [] = ⊤
adjAll R (x ∷ []) = ⊤
adjAll R (x ∷ y ∷ t) = R x y × adjAll R (y ∷ t)

-- 全程后继存在（作为函数）⟹ 链的相邻对全部满足 R。
chain-adj : ∀ (R : ℕ → ℕ → Set) (next : ℕ → ℕ) →
  (∀ x → R x (next x)) → ∀ d a → adjAll R (chain next a d)
chain-adj R next h zero a = tt
chain-adj R next h (suc zero) a = tt
chain-adj R next h (suc (suc d)) a = h a , chain-adj R next h (suc d) (next a)

-- ── 五、交接样本（与 Julia/Python/Lean/Coq 同账） ──

rot-0 : rot 0 ≡ 2
rot-0 = refl

rot-6 : rot 6 ≡ 0
rot-6 = refl

orbit-0 : orbit 4 0 ≡ 0 ∷ 2 ∷ 4 ∷ 6 ∷ []
orbit-0 = refl

odef-exchange-sample : odefB (rot 3) (rot 5) ≡ odefB 3 5
odef-exchange-sample = refl

gpair-sample : gpair 3 5 ≡ 43
gpair-sample = refl

gpair-decode-sample : mod8 (gpair 3 5) ≡ 3
gpair-decode-sample = refl

chain-sample : chain rot 0 5 ≡ 0 ∷ 2 ∷ 4 ∷ 6 ∷ 0 ∷ []
chain-sample = refl
