------------------------------------------------------------------------
-- ex04 —— 图与交换图
-- 三书对位：《高级范畴论》1.2（图、图同态）/ Simmons 2.1
------------------------------------------------------------------------

open import Level using (Level; _⊔_; 0ℓ) renaming (suc to lsuc)
open import Data.Unit using (⊤; tt)
open import Data.Bool using (Bool; true; false)
open import Data.Nat using (ℕ; zero; suc; _+_; _*_)
open import Data.Product using (Σ; _×_; _,_)
open import Relation.Binary.PropositionalEquality as Eq using (_≡_; refl; cong)
open Eq.≡-Reasoning

------------------------------------------------------------------------
-- 图 = 点 + 边 + 两个端点函数

record Graph : Set₁ where
  field
    V : Set
    E : Set
    src : E → V
    tgt : E → V

open Graph

-- 图同态：点映射 + 边映射，保端点——两条「小交换图」方程
record GraphHom (G H : Graph) : Set₁ where
  field
    vmap : V G → V H
    emap : E G → E H
    sq-src : ∀ e → vmap (src G e) ≡ src H (emap e)
    sq-tgt : ∀ e → vmap (tgt G e) ≡ tgt H (emap e)

------------------------------------------------------------------------
-- 路：图上的自由范畴

data Path (G : Graph) : V G → V G → Set where
  pid : ∀ {v} → Path G v v
  pcat : ∀ {e w} → Path G (tgt G e) w → Path G (src G e) w

-- 复合：递归在第一条路（Agda 的模式匹配自动处理索引约束）
_∙_ : ∀ {G u v w} → Path G u v → Path G v w → Path G u w
pid ∙ q = q
pcat p ∙ q = pcat (p ∙ q)

path-idR : ∀ {G u v} (p : Path G u v) → p ∙ pid ≡ p
path-idR pid = refl
path-idR (pcat p) = cong pcat (path-idR p)

path-assoc : ∀ {G u v w x} (p : Path G u v) (q : Path G v w) (r : Path G w x)
           → (p ∙ q) ∙ r ≡ p ∙ (q ∙ r)
path-assoc pid q r = refl
path-assoc (pcat p) q r = cong pcat (path-assoc p q r)

record Category (o ℓ : Level) : Set (lsuc (o ⊔ ℓ)) where
  field
    Obj : Set o
    Hom : Obj → Obj → Set ℓ
    idn : ∀ {a} → Hom a a
    comp : ∀ {a b c} → Hom a b → Hom b c → Hom a c
    idL : ∀ {a b} (f : Hom a b) → comp (idn {a}) f ≡ f
    idR : ∀ {a b} (f : Hom a b) → comp f (idn {b}) ≡ f
    assoc : ∀ {a b c d} (f : Hom a b) (g : Hom b c) (h : Hom c d)
          → comp (comp f g) h ≡ comp f (comp g h)

open Category

-- 任意图生成自由范畴
freeCat : Graph → Category 0ℓ 0ℓ
freeCat G = record
  { Obj = V G
  ; Hom = Path G
  ; idn = pid
  ; comp = _∙_
  ; idL = λ q → refl                    -- pid ∙ q 直接折叠
  ; idR = path-idR
  ; assoc = path-assoc
  }

------------------------------------------------------------------------
-- 一个具体的小图：true --e--> false

gArrow : Graph
gArrow = record { V = Bool; E = ⊤; src = λ _ → true; tgt = λ _ → false }

-- true → false 的路只有一条：直接走边
pDirect : Path gArrow true false
pDirect = pcat pid

plen : ∀ {G u v} → Path G u v → ℕ
plen pid = zero
plen (pcat p) = suc (plen p)

plen-direct : plen pDirect ≡ 1
plen-direct = refl

-- 抽象定律版：只用三条定律推图
laws-only : ∀ {o ℓ} (C : Category o ℓ) (a b c : Obj C)
          (f : Hom C a b) (g : Hom C b c)
          → comp C (comp C f (idn C {b})) g ≡ comp C f g
laws-only C a b c f g = cong (λ X → comp C X g) (idR C f)

------------------------------------------------------------------------
-- TyCat 里的交换方块

postulate
  funext : ∀ {ℓ ℓ′} {A : Set ℓ} {B : Set ℓ′}
             {f g : A → B} → (∀ x → f x ≡ g x) → f ≡ g

TyCat : Category (lsuc 0ℓ) 0ℓ
TyCat = record
  { Obj = Set
  ; Hom = λ A B → A → B
  ; idn = λ x → x
  ; comp = λ f g x → g (f x)
  ; idL = λ f → refl
  ; idR = λ f → refl
  ; assoc = λ f g h → refl
  }

-- 退化方格：恒等边——βη 折叠成同一函数，refl 白送
square-refl : comp TyCat (λ x → x) (λ n → 2 * n)
            ≡ comp TyCat (λ n → 2 * n) (λ x → x)
square-refl = refl

-- 真方格：suc;double = double;(+2)，逐点 2* suc n = 2n+2
open import Data.Nat.Properties using (*-suc; +-comm)

suc-double : ∀ n → 2 * suc n ≡ 2 * n + 2
suc-double n = begin
  2 * suc n   ≡⟨ *-suc 2 n ⟩
  2 + 2 * n   ≡⟨ +-comm 2 (2 * n) ⟩
  2 * n + 2   ∎
  where open Eq.≡-Reasoning

square-commutes : comp TyCat (λ n → suc n) (λ n → 2 * n)
                ≡ comp TyCat (λ n → 2 * n) (λ n → n + 2)
square-commutes = funext pointwise
  where
    pointwise : ∀ n → (λ n → 2 * n) (suc n) ≡ (λ n → n + 2) (2 * n)
    pointwise n = suc-double n

------------------------------------------------------------------------
-- 坑位速记：
-- 1. Graph 的 V/E : Set ⇒ record 落 Set₁——TyCat 的 Obj = Set 同层。
-- 2. Path 的 pcat 构造子隐式收 e w；模式 pcat p 即递归子结构。
-- 3. 2 * suc n = n + 2 + n 要按 stdlib 的 +/* 定义方向手推归纳
--    （Data.Nat.Properties 有 suc-double 但方向未必合用，自证更稳）。
-- 4. 交换图两层：退化 refl 白送；一般 funext + 逐点算术。
------------------------------------------------------------------------
