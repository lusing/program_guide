-- 第 87 章 · 可构造宇宙 L 与一般连续统假设（冯琦第二卷 §2.1）
-- 两件样品：有限载体全可定义引擎（引理 2.1(3) 的 L_n = V_n）、
-- 公式可数 vs 子集更多的对角线（L_{ω+1} ⊊ V_{ω+1} 的有限影子）。
module Ch87_constructible where

open import Data.Nat using (ℕ; zero; suc; _*_)
open import Data.Nat.Base using (_≡ᵇ_)
open import Data.Bool using (Bool; true; false; not; _∨_)
open import Data.List using (List; []; _∷_; length; map; _++_; foldr; concatMap)
open import Data.List.Membership.Propositional using (_∈_)
open import Data.List.Relation.Unary.Any using (here; there)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; subst; cong)
open import Relation.Nullary using (¬_)
open import Relation.Nullary.Negation using (contradiction)

-- 布尔等式的三件手卷工具（绕开 stdlib 的 T-类型形态）。
≡ᵇ-refl : ∀ n → (n ≡ᵇ n) ≡ true
≡ᵇ-refl zero = refl
≡ᵇ-refl (suc n) = ≡ᵇ-refl n

≡ᵇ⇒≡ : ∀ {m n : ℕ} → (m ≡ᵇ n) ≡ true → m ≡ n
≡ᵇ⇒≡ {zero} {zero} h = refl
≡ᵇ⇒≡ {zero} {suc n} ()
≡ᵇ⇒≡ {suc m} {zero} ()
≡ᵇ⇒≡ {suc m} {suc n} h = cong suc (≡ᵇ⇒≡ h)

≡⇒≡ᵇ : ∀ {m n : ℕ} → m ≡ n → (m ≡ᵇ n) ≡ true
≡⇒≡ᵇ {m} {n} e rewrite e = ≡ᵇ-refl n

-- ---------- 公式：参数内嵌的原子 + 布尔骨架 ----------

data Fm : Set where
  ftt fff : Fm
  feq : ℕ → Fm                 -- 自由变元 x = 参数
  fmem : ℕ → Fm                -- x * 参数 = 3（固定的可判定属于关系）
  fneg : Fm → Fm
  fOr : Fm → Fm → Fm

sat : Fm → ℕ → Bool
sat ftt _ = true
sat fff _ = false
sat (feq p) x = x ≡ᵇ p
sat (fmem p) x = (x * p) ≡ᵇ 3
sat (fneg φ) x = not (sat φ x)
sat (fOr φ ψ) x = sat φ x ∨ sat ψ x

-- ---------- 一、有限载体全可定义引擎（L_n = V_n） ----------

∨-cases : ∀ {b c : Bool} → b ∨ c ≡ true → (b ≡ true) ⊎ (c ≡ true)
∨-cases {true} h = inj₁ refl
∨-cases {false} h = inj₂ h

∨-introʳ : ∀ {b c : Bool} → c ≡ true → b ∨ c ≡ true
∨-introʳ {true} h = refl
∨-introʳ {false} h = h

-- 由参数表生成析取式：x = a₁ ∨ ⋯ ∨ x = a_k。
disj : List ℕ → Fm
disj = foldr (λ a r → fOr (feq a) r) fff

sat-disj : ∀ l x → sat (disj l) x ≡ true → x ∈ l
sat-disj [] x ()
sat-disj (a ∷ l) x h with ∨-cases h
... | inj₁ b = here (≡ᵇ⇒≡ b)
... | inj₂ c = there (sat-disj l x c)

disj-sat : ∀ l x → x ∈ l → sat (disj l) x ≡ true
disj-sat [] x ()
disj-sat (a ∷ l) x (here e) rewrite ≡⇒≡ᵇ e = refl
disj-sat (a ∷ l) x (there m) = ∨-introʳ (disj-sat l x m)

-- 引理 2.1(3) 的引擎：有限载体的每个子表由一个带参数公式定义。
definable→ : ∀ B x → sat (disj B) x ≡ true → x ∈ B
definable→ = sat-disj

definable← : ∀ B x → x ∈ B → sat (disj B) x ≡ true
definable← = disj-sat


-- 手卷布尔版 filter（本版 stdlib 的 Data.List.filter 吃 Dec 而非 Bool）。
bfilter : ∀ {A : Set} → (A → Bool) → List A → List A
bfilter f [] = []
bfilter f (x ∷ xs) with f x
... | true  = x ∷ bfilter f xs
... | false = bfilter f xs

-- ---------- 二、对角线：公式可数，子集更多 ----------

L4 : List ℕ
L4 = 0 ∷ 1 ∷ 2 ∷ 3 ∷ []

-- 深度 ≤ 1、参数取自 0..3 的公式全体（原子 + 原子否定 + 原子析取）。
atoms : List Fm
atoms = ftt ∷ fff ∷ map feq L4 ++ map fmem L4

Fs : List Fm
Fs = atoms ++ map fneg atoms ++ concatMap (λ p → map (λ q → fOr p q) atoms) atoms

-- 位置到公式的指派（对角线用）。
F : ℕ → Fm
F zero = ftt
F (suc zero) = fneg ftt
F (suc (suc zero)) = fOr (feq zero) (feq (suc zero))
F (suc (suc (suc zero))) = fmem (suc (suc zero))
F _ = fff

-- 对角线集合：第 k 个位置上的元素 x 恰好躲开第 k 个公式。
D : List ℕ
D = bfilter (λ x → not (sat (F x) x)) L4

ext : Fm → List ℕ
ext φ = bfilter (sat φ) L4

-- filter 成员刻画（两侧，手卷）。
∈-filter₁ : ∀ {A : Set} {f : A → Bool} {xs} {x : A} →
           x ∈ bfilter f xs → x ∈ xs × f x ≡ true
∈-filter₁ {xs = []} ()
∈-filter₁ {f = f} {xs = y ∷ xs} m with f y in eq | m
... | true  | here h rewrite h = here refl , eq
... | true  | there m′ = let p , q = ∈-filter₁ m′ in there p , q
... | false | m′ = let p , q = ∈-filter₁ m′ in there p , q

∈-filter₂ : ∀ {A : Set} {f : A → Bool} {xs} {x : A} →
           x ∈ xs → f x ≡ true → x ∈ bfilter f xs
∈-filter₂ {xs = []} () h
∈-filter₂ {f = f} {xs = y ∷ xs} m h with f y in eq | m
... | true  | here e = here e
... | true  | there m′ = there (∈-filter₂ m′ h)
... | false | here e = contradiction (trans (sym h) (trans (cong f e) eq)) (λ ())
... | false | there m′ = ∈-filter₂ m′ h

Bool-elim : ∀ (P : Bool → Set) → P true → P false → (b : Bool) → P b
Bool-elim P pt pf true = pt
Bool-elim P pt pf false = pf

not-true→false : ∀ {b : Bool} → not b ≡ true → b ≡ false
not-true→false {true} ()
not-true→false {false} _ = refl

-- D 侧与 ext 侧的成员刻画（类型全部钉死，不给元变量留活动空间）。
k∈D-iff : ∀ k → k ∈ D → k ∈ L4 × not (sat (F k) k) ≡ true
k∈D-iff k kD = ∈-filter₁ {f = λ x → not (sat (F x) x)} {xs = L4} {x = k} kD

k∈D-mk : ∀ k → k ∈ L4 → not (sat (F k) k) ≡ true → k ∈ D
k∈D-mk k k∈ h = ∈-filter₂ {f = λ x → not (sat (F x) x)} {xs = L4} {x = k} k∈ h

k∈E-mk : ∀ k → k ∈ L4 → sat (F k) k ≡ true → k ∈ ext (F k)
k∈E-mk k k∈ h = ∈-filter₂ {f = sat (F k)} {xs = L4} {x = k} k∈ h

k∈E-iff : ∀ k → k ∈ ext (F k) → sat (F k) k ≡ true
k∈E-iff k kE = proj₂ (∈-filter₁ {f = sat (F k)} {xs = L4} {x = k} kE)

-- 真分支：k ∈ ext(F k)，经 h 送回 D 侧，而 D 的谓词在 k 处为 not true。
contra-true : ∀ k → k ∈ L4 → D ≡ ext (F k) → sat (F k) k ≡ true → ⊥
contra-true k k∈ h sk =
  let kE = k∈E-mk k k∈ sk
      kD = subst (λ l → k ∈ l) (sym h) kE
      (_ , nk) = k∈D-iff k kD
  in contradiction (trans (sym sk) (not-true→false nk)) (λ ())

-- 假分支：k ∈ D，经 h 送到 ext 侧，即 sat (F k) k ≡ true。
contra-false : ∀ k → k ∈ L4 → D ≡ ext (F k) → sat (F k) k ≡ false → ⊥
contra-false k k∈ h sf =
  let kD = k∈D-mk k k∈ (cong not sf)
      kE = subst (λ l → k ∈ l) h kD
      tk = k∈E-iff k kE
  in contradiction (trans (sym tk) sf) (λ ())

-- 对角线定理：D 不等于任何被枚举公式的扩张。纯逻辑：无论第 k 个
-- 公式在 k 处取真还是取假，D = ext(F k) 都在 k 处自相矛盾。
diagonal : ∀ k → k ∈ L4 → ¬ (D ≡ ext (F k))
diagonal k k∈ h =
  Bool-elim (λ b → sat (F k) k ≡ b → ⊥)
            (contra-true k k∈ h) (contra-false k k∈ h)
            (sat (F k) k) refl

-- 规模：10 个原子、120 个深度 ≤ 1 的公式 vs 16 个 4 元子集。
atoms-length : length atoms ≡ 10
atoms-length = refl

Fs-length : length Fs ≡ 120
Fs-length = refl
