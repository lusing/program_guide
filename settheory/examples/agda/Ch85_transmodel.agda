-- 第 85 章 · 传递模型与内在模型论（冯琦第二卷 §1.2）
-- 例 1.7 与定理 1.22。相等用命题相等；环境更新按两个下标同时递归。
module Ch85_transmodel where

open import Data.Nat using (ℕ; zero; suc)
open import Data.Empty using (⊥)
open import Data.Product using (_×_; _,_; proj₁; proj₂; ∃)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; sym; cong)

module Semantics (S : Set) (mem : S → S → Set) where

  Transitive : (S → Set) → Set
  Transitive M = ∀ {x y} → M x → mem y x → M y

  Extensional : Set
  Extensional = ∀ {a b} → (∀ x → mem x a → mem x b) → (∀ x → mem x b → mem x a) → a ≡ b

  trans-ext : Extensional → (M : S → Set) → Transitive M →
      ∀ {a b} → M a → M b →
      (∀ x → M x → (mem x a → mem x b) × (mem x b → mem x a)) → a ≡ b
  trans-ext ext M tr {a} {b} ha hb h =
    ext
      (λ x hxa → proj₁ (h x (tr ha hxa)) hxa)
      (λ x hxb → proj₂ (h x (tr hb hxb)) hxb)

  data Fm : Set where
    eq   : ℕ → ℕ → Fm
    neg  : Fm → Fm
    conj : Fm → Fm → Fm
    ex   : ℕ → Fm → Fm

  Env : Set
  Env = ℕ → S

  update : Env → ℕ → S → Env
  update e zero    x zero    = x
  update e zero    x (suc k) = e (suc k)
  update e (suc i) x zero    = e zero
  update e (suc i) x (suc k) = update (λ n → e (suc n)) i x k

  val : Env → Fm → (S → Set) → Set
  val e (eq i j)   R = e i ≡ e j
  val e (neg p)    R = val e p R → ⊥
  val e (conj p q) R = val e p R × val e q R
  val e (ex i p)   R = ∃ λ x → R x × val (update e i x) p R

  envIn : (S → Set) → Env → Set
  envIn B e = ∀ k → B (e k)

  envIn-update : ∀ {B e i x} → envIn B e → B x → envIn B (update e i x)
  envIn-update {B} {e} {zero} {x} he hx zero = hx
  envIn-update {B} {e} {zero} {x} he hx (suc k) = he (suc k)
  envIn-update {B} {e} {suc i} {x} he hx zero = he zero
  envIn-update {B} {e} {suc i} {x} he hx (suc k) =
    envIn-update {B} {λ n → e (suc n)} {i} {x} (λ n → he (suc n)) hx k

  -- 定理 1.22。closed 把 A 中的存在见证收进 B。
  tarski : (A B : S → Set) → (∀ {x} → B x → A x) →
      (∀ p e i → envIn B e → val e (ex i p) A →
         ∃ λ x → B x × val (update e i x) p A) →
      ∀ p e → envIn B e →
      (val e p B → val e p A) × (val e p A → val e p B)
  tarski A B sub closed (eq i j) e he = (λ h → h) , (λ h → h)
  tarski A B sub closed (neg p) e he =
    (λ h hA → h (proj₂ (tarski A B sub closed p e he) hA)) ,
    (λ h hB → h (proj₁ (tarski A B sub closed p e he) hB))
  tarski A B sub closed (conj p q) e he =
    (λ h → proj₁ (tarski A B sub closed p e he) (proj₁ h) ,
           proj₁ (tarski A B sub closed q e he) (proj₂ h)) ,
    (λ h → proj₂ (tarski A B sub closed p e he) (proj₁ h) ,
           proj₂ (tarski A B sub closed q e he) (proj₂ h))
  tarski A B sub closed (ex i p) e he =
    (λ h → let x = proj₁ h
               hx = proj₂ h
           in x , sub (proj₁ hx) ,
              proj₁ (tarski A B sub closed p (update e i x)
                       (envIn-update {B = B} {e = e} {i = i} {x = x} he (proj₁ hx)))
                    (proj₂ hx)) ,
    (λ h → let w = closed p e i he h
               x = proj₁ w
               hx = proj₂ w
           in x , proj₁ hx ,
              proj₂ (tarski A B sub closed p (update e i x)
                       (envIn-update {B = B} {e = e} {i = i} {x = x} he (proj₁ hx)))
                    (proj₂ hx))

open Semantics
