-- ex02 —— 命题逻辑：语法、语义与蛮力判定器（Agda 版）
-- 自带 _∈_ / zipV / all，不依赖 stdlib 的 Any/Properties API——
-- 「自己滚一个成员关系」本身就是教学（它就是 Data.List.Any 的化身）。

module ex02_propsem where

open import Data.Bool using (Bool; true; false; not; _∧_; _∨_; if_then_else_)
open import Data.Nat using (ℕ; _≟_)
open import Data.List using (List; []; _∷_; map; _++_)
open import Data.Product using (_,_; Σ; _×_)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Empty using (⊥; ⊥-elim)
open import Relation.Nullary using (Dec; yes; no)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; sym; trans; cong)

-- ---------- 语法 ----------

data Form : Set where
  fvar : ℕ → Form
  _⟶_  : Form → Form → Form
  _∧f_ : Form → Form → Form
  _∨f_ : Form → Form → Form
  ¬f_  : Form → Form
  ⊥f   : Form

-- ---------- 语义 ----------

eval : (ℕ → Bool) → Form → Bool
eval e (fvar n)  = e n
eval e (a ⟶ b)  = if eval e a then eval e b else true
eval e (a ∧f b)  = eval e a ∧ eval e b
eval e (a ∨f b)  = eval e a ∨ eval e b
eval e (¬f a)    = not (eval e a)
eval e ⊥f        = false

vars : Form → List ℕ
vars (fvar n)   = n ∷ []
vars (a ⟶ b)   = vars a ++ vars b
vars (a ∧f b)   = vars a ++ vars b
vars (a ∨f b)   = vars a ++ vars b
vars (¬f a)     = vars a
vars ⊥f         = []

-- ---------- 自带成员关系（Data.List.Any 的化身） ----------

infix 4 _∈_

data _∈_ {A : Set} (x : A) : List A → Set where
  here  : ∀ {xs} → x ∈ x ∷ xs
  there : ∀ {y xs} → x ∈ xs → x ∈ y ∷ xs

∈-++ˡ : ∀ {A} {x : A} {xs ys} → x ∈ xs → x ∈ xs ++ ys
∈-++ˡ here      = here
∈-++ˡ (there p) = there (∈-++ˡ p)

∈-++ʳ : ∀ {A} {x : A} {xs ys} → x ∈ ys → x ∈ xs ++ ys
∈-++ʳ {xs = []}     p = p
∈-++ʳ {xs = x ∷ xs} p = there (∈-++ʳ p)

∈-map : ∀ {A B} {f : A → B} {y : A} {l} → y ∈ l → f y ∈ map f l
∈-map here      = here
∈-map (there p) = there (∈-map p)

-- ---------- 一致性引理 ----------

agree : (f : Form) (e₁ e₂ : ℕ → Bool) →
        (∀ x → x ∈ vars f → e₁ x ≡ e₂ x) → eval e₁ f ≡ eval e₂ f
agree (fvar n) e₁ e₂ h = h n here
agree (a ⟶ b) e₁ e₂ h
  rewrite agree a e₁ e₂ (λ x x∈ → h x (∈-++ˡ x∈))
        | agree b e₁ e₂ (λ x x∈ → h x (∈-++ʳ x∈)) = refl
agree (a ∧f b) e₁ e₂ h
  rewrite agree a e₁ e₂ (λ x x∈ → h x (∈-++ˡ x∈))
        | agree b e₁ e₂ (λ x x∈ → h x (∈-++ʳ x∈)) = refl
agree (a ∨f b) e₁ e₂ h
  rewrite agree a e₁ e₂ (λ x x∈ → h x (∈-++ˡ x∈))
        | agree b e₁ e₂ (λ x x∈ → h x (∈-++ʳ x∈)) = refl
agree (¬f a) e₁ e₂ h = cong not (agree a e₁ e₂ h)
agree ⊥f e₁ e₂ h = refl

-- ---------- 蛮力判定器 ----------

lookup : ℕ → List (ℕ × Bool) → Bool
lookup n [] = false
lookup n ((x , b) ∷ r) with n ≟ x
... | yes _ = b
... | no _  = lookup n r

lookup-yes : ∀ n b r {x} → n ≡ x → lookup n ((x , b) ∷ r) ≡ b
lookup-yes n b r {x} h with n ≟ x
... | yes _  = refl
... | no n≠x = ⊥-elim (n≠x h)

lookup-no : ∀ n r {x b} → (n ≡ x → ⊥) → lookup n ((x , b) ∷ r) ≡ lookup n r
lookup-no n r {x} h with n ≟ x
... | yes n≡x = ⊥-elim (h n≡x)
... | no _    = refl

-- 非依赖消解子：绕开 with 对目标的吸收（目标保持纯 lookup 形态）
dec-elim : ∀ {A : Set} {P : Set} → (A → P) → ((A → ⊥) → P) → Dec A → P
dec-elim f g (yes a) = f a
dec-elim f g (no ¬a) = g ¬a

zipV : List ℕ → List Bool → List (ℕ × Bool)
zipV [] _              = []
zipV _ []              = []
zipV (x ∷ xs) (b ∷ bs) = (x , b) ∷ zipV xs bs

assignOf : List ℕ → List Bool → ℕ → Bool
assignOf vs v n = lookup n (zipV vs v)

allVectors : List ℕ → List (List Bool)
allVectors []       = [] ∷ []
allVectors (x ∷ xs) = map (false ∷_) (allVectors xs) ++ map (true ∷_) (allVectors xs)

all : (List Bool → Bool) → List (List Bool) → Bool
all p []       = true
all p (v ∷ vs) = p v ∧ all p vs

check : Form → Bool
check f = all (λ v → eval (assignOf (vars f) v) f) (allVectors (vars f))

-- ---------- 辅助引理 ----------

lookup-zip-map : (vs : List ℕ) (e : ℕ → Bool) (x : ℕ) →
                 x ∈ vs → lookup x (zipV vs (map e vs)) ≡ e x
lookup-zip-map [] e x ()
lookup-zip-map (y ∷ ys) e x here = lookup-yes x (e x) _ refl
lookup-zip-map (y ∷ ys) e x (there p) =
  dec-elim (λ (x≡y : x ≡ y) → trans (lookup-yes x (e y) _ x≡y) (sym (cong e x≡y)))
           (λ x≠y → trans (lookup-no x _ x≠y) (lookup-zip-map ys e x p))
           (x ≟ y)

map∈allVectors : (vs : List ℕ) (e : ℕ → Bool) → map e vs ∈ allVectors vs
map∈allVectors [] e = here
map∈allVectors (x ∷ xs) e = helper (e x) (map∈allVectors xs e)
  where
    helper : (b : Bool) → map e xs ∈ allVectors xs → (b ∷ map e xs) ∈ allVectors (x ∷ xs)
    helper true  h = ∈-++ʳ (∈-map h)
    helper false h = ∈-++ˡ (∈-map h)

∧-trueˡ : ∀ {a b : Bool} → a ∧ b ≡ true → a ≡ true
∧-trueˡ {true}  h = refl
∧-trueˡ {false} ()

∧-trueʳ : ∀ {a b : Bool} → a ∧ b ≡ true → b ≡ true
∧-trueʳ {true}  h = h
∧-trueʳ {false} ()

∧-falseˡ : ∀ {a b : Bool} → a ∧ b ≡ false → (a ≡ false) ⊎ (b ≡ false)
∧-falseˡ {true}  h = inj₂ h
∧-falseˡ {false} h = inj₁ refl

all-∈ : (p : List Bool → Bool) (l : List (List Bool)) →
        all p l ≡ true → ∀ v → v ∈ l → p v ≡ true
all-∈ p [] h v ()
all-∈ p (w ∷ ws) h v here       = ∧-trueˡ h
all-∈ p (w ∷ ws) h v (there v∈) = all-∈ p ws (∧-trueʳ h) v v∈

all-witness : (p : List Bool → Bool) (l : List (List Bool)) →
              all p l ≡ false → Σ (List Bool) (λ v → (v ∈ l) × (p v ≡ false))
all-witness p [] ()
all-witness p (w ∷ ws) h with ∧-falseˡ h
all-witness p (w ∷ ws) h | inj₁ pw=false = w , here , pw=false
all-witness p (w ∷ ws) h | inj₂ rest     with all-witness p ws rest
all-witness p (w ∷ ws) h | inj₂ rest | v , v∈ , pv=false = v , there v∈ , pv=false

-- ---------- 旗舰：判定器双向可靠 ----------

check-true-valid : (f : Form) → check f ≡ true → (e : ℕ → Bool) → eval e f ≡ true
check-true-valid f h e
  rewrite agree f e (assignOf (vars f) (map e (vars f)))
            (λ x x∈ → sym (lookup-zip-map (vars f) e x x∈))
        = all-∈ (λ v → eval (assignOf (vars f) v) f) (allVectors (vars f)) h
                 (map e (vars f)) (map∈allVectors (vars f) e)

check-false-counter : (f : Form) → check f ≡ false →
                      Σ (ℕ → Bool) (λ e → eval e f ≡ false)
check-false-counter f h
  with all-witness (λ v → eval (assignOf (vars f) v) f) (allVectors (vars f)) h
... | v , v∈ , pv=false = assignOf (vars f) v , pv=false

-- 坑位速记（Agda 侧）：
-- - 布尔 if 配 with 是死胡同：with 只做语法抽象，钻不进 lookup 的展开；
--   换 Dec 版 lookup（x ≟ y 的 yes/no 自带证明）一步到位；
-- - rewrite 与 with 混用会让 where 作用域失效——map∈allVectors 改走
--   where 辅助函数按 Bool 分派；
-- - ∧-trueˡ/ʳ、∧-falseˡ 三件套 = Data.Bool.Properties 的化身，
--   自带的按隐式 Bool 参数分情况，避开库 API 漂移；
-- - stdlib 的 ≡ᵇ⇒≡ 吃 T-谓词不是布尔相等——涉及 API 一律自造小引理最稳。
