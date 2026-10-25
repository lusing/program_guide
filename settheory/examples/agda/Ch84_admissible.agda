-- 第 84 章 · KP 与可采纳集合（冯琦第二卷 §1.1）——Agda 通道
-- 在抽象集合论签名 (A, mem) 上定义 Δ₀ 公式，证明：传递载体 M 上
-- 「相对化语义」与「全宇宙语义」等价。证明对公式结构归纳，只有有界量词
-- 一支需要传递性；这与 Coq、Lean、Isabelle 四通道是同一个定理。
module Ch84_admissible where

open import Data.Nat using (ℕ; zero; suc)
open import Data.Nat.Properties using (_≟_)
open import Data.Unit using (⊤; tt)
open import Data.Empty using (⊥)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Relation.Nullary using (¬_; yes; no)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

module Semantics (A : Set) (mem : A → A → Set) where

  -- Δ₀（有界）公式。ball i j p 读作 ∀v_i∈v_j, p。
  data Fm : Set where
    atom-mem : ℕ → ℕ → Fm
    atom-eq  : ℕ → ℕ → Fm
    neg      : Fm → Fm
    conj     : Fm → Fm → Fm
    ball     : ℕ → ℕ → Fm → Fm

  Env : Set
  Env = ℕ → A

  Carrier : Set₁
  Carrier = A → Set

  Transitive : Carrier → Set
  Transitive M = ∀ {x y} → M x → mem y x → M y

  -- 环境更新：对两个下标同时递归，避免布尔判等在证明里留下反射残渣。
  update : Env → ℕ → A → Env
  update e zero    x zero    = x
  update e zero    x (suc k) = e (suc k)
  update e (suc i) x zero    = e zero
  update e (suc i) x (suc k) = update (λ n → e (suc n)) i x k

  -- M-相对语义：量词变元先由 M 守卫。成员与相等沿用外界的真实关系。
  eval : (M : Carrier) → Env → Fm → Set
  eval M e (atom-mem i j) = mem (e i) (e j)
  eval M e (atom-eq i j)  = e i ≡ e j
  eval M e (neg p)        = ¬ eval M e p
  eval M e (conj p q)     = eval M e p × eval M e q
  eval M e (ball i j p)   =
    ∀ x → M x → mem x (e j) → eval M (update e i x) p

  -- 全宇宙语义：载体守卫退化为 ⊤。
  evalV : Env → Fm → Set
  evalV = eval (λ _ → ⊤)

  -- 更新后的环境仍全在 M 中。
  update-M : (M : Carrier) (e : Env) →
    (∀ i → M (e i)) → ∀ i x → M x → ∀ k → M (update e i x k)
  update-M M e he zero    x hx zero    = hx
  update-M M e he zero    x hx (suc k) = he (suc k)
  update-M M e he (suc i) x hx zero    = he zero
  update-M M e he (suc i) x hx (suc k) =
    update-M M (λ n → e (suc n)) (λ n → he (suc n)) i x hx k

  -- Δ₀-绝对性，两个方向打包为一对函数。
  -- toV：M 真 ⇒ 全宇宙真；toM：全宇宙真 ⇒ M 真。
  absolute : (M : Carrier) → Transitive M →
    (e : Env) → (∀ i → M (e i)) → (p : Fm) →
    (eval M e p → evalV e p) × (evalV e p → eval M e p)
  absolute M tr e he (atom-mem i j) = (λ h → h) , (λ h → h)
  absolute M tr e he (atom-eq i j)  = (λ h → h) , (λ h → h)
  absolute M tr e he (neg p) =
    (λ hn hv → hn (proj₂ ih hv)) , (λ hn hm → hn (proj₁ ih hm))
    where ih = absolute M tr e he p
  absolute M tr e he (conj p q) =
    (λ h → proj₁ ihp (proj₁ h) , proj₁ ihq (proj₂ h)) ,
    (λ h → proj₂ ihp (proj₁ h) , proj₂ ihq (proj₂ h))
    where
      ihp = absolute M tr e he p
      ihq = absolute M tr e he q
  absolute M tr e he (ball i j p) = toV , toM
    where
      toV : eval M e (ball i j p) → evalV e (ball i j p)
      toV h x _ hx = proj₁ ih (h x xM hx)
        where
          xM : M x
          xM = tr (he j) hx
          he' : ∀ k → M (update e i x k)
          he' = update-M M e he i x xM
          ih = absolute M tr (update e i x) he' p

      toM : evalV e (ball i j p) → eval M e (ball i j p)
      toM h x xM hx = proj₂ ih (h x tt hx)
        where
          he' : ∀ k → M (update e i x k)
          he' = update-M M e he i x xM
          ih = absolute M tr (update e i x) he' p

  -- Δ₀-分离的绝对性：在传递 M 中，「t 内满足 p 的元素」与外界一致。
  separation-absolute : (M : Carrier) → Transitive M →
    (e : Env) → (∀ i → M (e i)) → ∀ {t} → M t →
    (p : Fm) → ∀ x → mem x t →
    (eval M (update e 0 x) p → evalV (update e 0 x) p) ×
    (evalV (update e 0 x) p → eval M (update e 0 x) p)
  separation-absolute M tr e he ht p x hx =
    absolute M tr (update e 0 x) (update-M M e he 0 x (tr ht hx)) p
