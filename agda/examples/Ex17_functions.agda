------------------------------------------------------------------------
-- 第 17 章配套示例：函数世界——同构与外延
------------------------------------------------------------------------

module Ex17_functions where

open import Level using (Level; 0ℓ; _⊔_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; _≢_; refl; sym; trans; cong; cong₂; subst)
open import Function.Bundles
  using (_↔_; _⇔_; _⟶_; _↩_; mk↔ₛ′; mk⇔; mk⟶; mk↣; mk↩; _⟨$⟩_)
open import Function.Base
  using (id; _∘_; _∘′_; flip; _$_; _|>_; case_of_; const)
open import Function.Related.Propositional as R
  using (_∼[_]_; ↔⇒)
open import Function.Related.TypeIsomorphisms
  using (×-comm; ⊎-comm; Σ-assoc)

-- 数据层
import Data.List.Relation.Binary.Pointwise as PW
open import Data.List.Base using (List; _++_; _∷_; []; map)
open import Data.Nat.Base using (ℕ; zero; suc; _+_; _*_)
open import Data.Bool.Base using (Bool; true; false; not; if_then_else_)
open import Data.Bool.Properties using (_≟_)
open import Data.Product using (Σ; Σ-syntax; _×_; _,_; proj₁; proj₂; curry; uncurry)
open import Data.Sum using (_⊎_; inj₁; inj₂; [_,_]′)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.Unit using (⊤; tt)
open import Relation.Nullary using (Dec; yes; no; ¬_)

------------------------------------------------------------------------
-- 17.1 函数外延：内核只认定义相等
------------------------------------------------------------------------

postulate
  -- stdlib 2.3 不提供 funExt；--cubical 下可证（24 章见）
  funExt : ∀ {a b : Level} {A : Set a} {B : A → Set b}
           {f g : (x : A) → B x} → ((x : A) → f x ≡ g x) → f ≡ g

-- η 与定义相等：三行 refl 全过
η₁ : ∀ (f : Bool → Bool) → f ∘ id ≡ f
η₁ f = refl

η₂ : ∀ (f : Bool → Bool) → (λ x → f x) ≡ f
η₂ f = refl

η₃ : ∀ (f : Bool → Bool) (x : Bool) → (λ x → f x) x ≡ f x
η₃ f x = refl

-- 顺手把 Function.Base 的常用记号各点一次名：
flip-demo : flip _+_ 3 0 ≡ 3
flip-demo = refl

pipe-demo : (3 |> (λ n → n + 4)) ≡ 7
pipe-demo = refl

∘′-demo : ∀ (f : Bool → Bool) → f ∘′ id ≡ f
∘′-demo f = refl

-- 但「逐点命题相等 ⇒ 函数相等」必须外延。先备引理（要归纳）：
n+0≡n : ∀ n → n + zero ≡ n
n+0≡n zero    = refl
n+0≡n (suc n) = cong suc (n+0≡n n)

f₁ f₂ : ℕ → ℕ
f₁ = λ n → n + zero
f₂ = λ n → n

f₁≡f₂ : f₁ ≡ f₂
f₁≡f₂ = funExt λ n → n+0≡n n

-- 反向不需要公理：函数相等 ⇒ 逐点相等，cong 即可
funExt⁻ : ∀ {a b : Level} {A : Set a} {B : A → Set b}
          {f g : (x : A) → B x} → f ≡ g → (x : A) → f x ≡ g x
funExt⁻ p x = cong (λ h → h x) p

------------------------------------------------------------------------
-- 17.2 有限域上的函数相等可判定（判逐点，再外延拼接）
------------------------------------------------------------------------

≟-pointwise : (f g : Bool → Bool) → Dec ((x : Bool) → f x ≡ g x)
≟-pointwise f g with f true ≟ g true | f false ≟ g false
... | yes p₁ | yes p₂ = yes (λ { true → p₁ ; false → p₂ })
... | no ¬p₁ | _      = no λ h → ¬p₁ (h true)
... | _      | no ¬p₂ = no λ h → ¬p₂ (h false)

≟-fun : (f g : Bool → Bool) → Dec (f ≡ g)
≟-fun f g with ≟-pointwise f g
... | yes h = yes (funExt h)
... | no ¬h = no λ eq → ¬h (funExt⁻ eq)

-- 自检：not 与 id 逐点在 true 处分道扬镳，整体也不等
not≢id-pointwise : ¬_ ((x : Bool) → not x ≡ id x)
not≢id-pointwise h = case h true of λ ()

not≢id : not ≢ (λ x → x)
not≢id eq = not≢id-pointwise (funExt⁻ eq)

------------------------------------------------------------------------
-- 17.3 _↔_：互逆对（Function.Bundles；老 Logic / Function.Inverse 已退役）
------------------------------------------------------------------------

-- 例 1：Σ over Bool ≅ ⊎（纯构造子演算，不碰外延）
ΣBool↔⊎ : ∀ {A B : Set} → (Σ[ x ∈ Bool ] (if x then A else B)) ↔ (A ⊎ B)
ΣBool↔⊎ {A = A} {B = B} = mk↔ₛ′ to from
  (λ { (inj₁ a) → refl ; (inj₂ b) → refl })
  (λ { (true , a) → refl ; (false , b) → refl })
  where
  to : (Σ[ x ∈ Bool ] (if x then A else B)) → A ⊎ B
  to (true  , a) = inj₁ a
  to (false , b) = inj₂ b

  from : A ⊎ B → (Σ[ x ∈ Bool ] (if x then A else B))
  from (inj₁ a) = true  , a
  from (inj₂ b) = false , b

-- 例 2：Curry 同构 (Bool → A) ≅ (A × A)——一侧 refl，另一侧必须 funExt
curry↔ : ∀ {A : Set} → (Bool → A) ↔ (A × A)
curry↔ {A = A} = mk↔ₛ′ to from to∘from from∘to
  where
  to : (Bool → A) → A × A
  to f = f true , f false

  from : A × A → Bool → A
  from (x , y) = λ b → if b then x else y

  from∘to : ∀ f → from (to f) ≡ f
  from∘to f = funExt λ { true → refl ; false → refl }

  to∘from : ∀ p → to (from p) ≡ p
  to∘from (x , y) = refl

-- _⇔_（Equivalence）：只要求「来回都有函数」，不带互逆定律
A×B⇔B×A : ∀ {A B : Set} → (A × B) ⇔ (B × A)
A×B⇔B×A = mk⇔ (λ (a , b) → b , a) (λ (b , a) → a , b)

-- _⟶_：带同余证明的函数（setoid 视角），用 _⟨$⟩_ 应用
double⟶ : ℕ ⟶ ℕ
double⟶ = mk⟶ (λ n → n + n)

double-app : double⟶ ⟨$⟩ 3 ≡ 6
double-app = refl

------------------------------------------------------------------------
-- 17.4 Pointwise：容器的逐点等式（2.3 按容器拆分模块）
------------------------------------------------------------------------

pw-list : PW.Pointwise _≡_ (1 ∷ 2 ∷ []) (suc zero ∷ suc (suc zero) ∷ [])
pw-list = refl PW.∷ refl PW.∷ PW.[]

map-preserves-Pointwise : ∀ {A B : Set} (f : A → B) {xs ys : List A} →
                          PW.Pointwise _≡_ xs ys →
                          PW.Pointwise _≡_ (map f xs) (map f ys)

map-preserves-Pointwise f PW.[]       = PW.[]
map-preserves-Pointwise f (r PW.∷ ps) =
  cong f r PW.∷ map-preserves-Pointwise f ps

g : ℕ → ℕ
g n = n + n

_ : map g (1 ∷ 2 ∷ []) ≡ 2 ∷ 4 ∷ []
_ = refl

pw-map-demo : PW.Pointwise _≡_ (map g (1 ∷ 2 ∷ [])) (map g (1 ∷ 2 ∷ []))
pw-map-demo = map-preserves-Pointwise g {xs = 1 ∷ 2 ∷ []} {ys = 1 ∷ 2 ∷ []}
                (refl PW.∷ refl PW.∷ PW.[])

-- 向量版（归纳定义；模块 Data.Vec.Relation.Binary.Pointwise.Inductive）
import Data.Vec.Base as V
import Data.Vec.Relation.Binary.Pointwise.Inductive as VecPW

v₁ v₂ : V.Vec ℕ 3
v₁ = 1 V.∷ 2 V.∷ 3 V.∷ V.[]
v₂ = suc 0 V.∷ suc (suc 0) V.∷ suc (suc (suc 0)) V.∷ V.[]

pw-vec : VecPW.Pointwise _≡_ v₁ v₂
pw-vec = refl VecPW.∷ refl VecPW.∷ refl VecPW.∷ VecPW.[]

------------------------------------------------------------------------
-- 17.5 Function.Related.Propositional：蕴含/注入/双射统一记账
------------------------------------------------------------------------

imp-demo : ∀ {A B : Set} → (A × B) R.∼[ R.implication ] (A ⊎ B)
imp-demo = mk⟶ λ { (a , b) → inj₁ a }

inj-demo : ∀ {A B : Set} → A R.∼[ R.injection ] (A ⊎ B)
inj-demo = mk↣ {to = inj₁} λ { refl → refl }

bij-demo : ∀ {A B : Set} → (A × B) R.∼[ R.bijection ] (B × A)
bij-demo = ↔⇒ (×-comm _ _)

-- 同一 kind 的可传递复合（链条推理的底座）
trans-demo : ∀ {X Y Z : Set} {k : R.Kind} →
             X R.∼[ k ] Y → Y R.∼[ k ] Z → X R.∼[ k ] Z
trans-demo = R.K-trans

------------------------------------------------------------------------
-- 17.6 收缩-扩张：左逆 _↩_（to ∘ from ≡ id 的一侧）
------------------------------------------------------------------------

-- (A × Bool) 缩到 A：to = proj₁ 是收缩/重traction（丢信息），
-- from = λ a → (a , true) 是扩张/截面。from ∘ to ≢ id（Bool 分量被改），
-- to ∘ from ≡ id 成立——↩（LeftInverse）记录的就是这一侧定律。
proj↩ : ∀ {A : Set} → (A × Bool) ↩ A
proj↩ {A = A} = mk↩ {to = proj₁} {from = λ a → (a , true)} λ { refl → refl }
