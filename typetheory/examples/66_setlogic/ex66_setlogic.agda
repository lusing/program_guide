{-# OPTIONS --cubical #-}
----------------------------------------------------------------
-- 39 集合与逻辑 —— cubical Agda 主力（HoTT 书 ch.3）
--   · h-level：isProp / isSet / isContr 与封闭律（Π 族 prop、
--     单端点路径空间合同 3.11.8、isProp(isContr) 3.11.4）
--   · 命题截断 ∥_∥ 是【真 HIT】（squash 路径构造子）——
--     isProp ∥A∥、∥∥-rec、依赖版 ∥∥-elim（3.7）
--   · mere prop 的逻辑记号表（3.7.1）：∨=∥+∥、∃=∥Σ∥
--   · 经典 vs 直觉（3.4）：LEM⇔DNE（含 isProp(A+¬A) 的
--     构造性证明——DNE⇒LEM 的钥匙）
--   · AC（3.8）：免费方向 ∥Π Y∥→Π∥Y∥ 机器化；AC 本身公理级
--   · 合同族的 Π 合同（3.11.6，等价于 funext 的那个）
----------------------------------------------------------------
module ex66_setlogic where

open import Agda.Primitive
open import Agda.Primitive.Cubical renaming
  ( primIMin to _∧ᵢ_ ; primIMax to _∨ᵢ_ ; primINeg to ~_ ; itIsOne to 1=1
  ; primTransp to transp ; primHComp to hcomp )
open import Agda.Builtin.Cubical.Path
open import Agda.Builtin.Sigma
open import Agda.Builtin.Unit using (⊤; tt)
open import Agda.Builtin.Bool

-- ============================================================
-- 〇、mini-cubical 前奏（64 章服役版）
-- ============================================================

refl : ∀ {ℓ} {A : Set ℓ} {x : A} → x ≡ x
refl {x = x} = λ _ → x

sym : ∀ {ℓ} {A : Set ℓ} {x y : A} → x ≡ y → y ≡ x
sym p = λ i → p (~ i)

transport : ∀ {ℓ} (A : I → Set ℓ) → A i0 → A i1
transport A = transp A i0

J : ∀ {ℓ ℓ'} {A : Set ℓ} {x : A} (P : ∀ z → x ≡ z → Set ℓ')
  → P x refl → ∀ {y} (p : x ≡ y) → P y p
J P d p = transport (λ i → P (p i) (λ j → p (i ∧ᵢ j))) d

cong : ∀ {ℓ ℓ'} {A : Set ℓ} {B : A → Set ℓ'} {x y : A}
     → (f : (a : A) → B a) (p : x ≡ y) → PathP (λ i → B (p i)) (f x) (f y)
cong f p = λ i → f (p i)

transportRefl : ∀ {ℓ} {A : Set ℓ} (a : A) → transport (λ _ → A) a ≡ a
transportRefl {A = A} a j = transp (λ _ → A) j a

infixl 30 _∙_
_∙_ : ∀ {ℓ} {A : Set ℓ} {x y z : A} → x ≡ y → y ≡ z → x ≡ z
_∙_ {x = x} p q = J (λ z _ → x ≡ z) p q

rUnit : ∀ {ℓ} {A : Set ℓ} {x y : A} (p : x ≡ y) → p ∙ refl ≡ p
rUnit = J (λ z q → q ∙ refl ≡ q) (transportRefl refl)

lInv : ∀ {ℓ} {A : Set ℓ} {x y : A} (p : x ≡ y) → sym p ∙ p ≡ refl
lInv = J (λ z q → sym q ∙ q ≡ refl) (transportRefl refl)

funext : ∀ {ℓ ℓ'} {A : Set ℓ} {B : A → Set ℓ'} {f g : ∀ x → B x}
       → (∀ x → f x ≡ g x) → f ≡ g
funext h i j = h j i

infixr 9 _∘_
_∘_ : ∀ {ℓ ℓ' ℓ''} {A : Set ℓ} {B : Set ℓ'} {C : Set ℓ''}
    → (B → C) → (A → B) → A → C
(g ∘ h) x = g (h x)

-- ============================================================
-- 一、空与单元；isProp / isSet / isContr
-- ============================================================

data ⊥ : Set where

⊥-elim : ∀ {ℓ} {A : Set ℓ} → ⊥ → A
⊥-elim ()

isProp : ∀ {ℓ} → Set ℓ → Set ℓ
isProp A = (x y : A) → x ≡ y

isSet : ∀ {ℓ} → Set ℓ → Set ℓ
isSet A = (x y : A) → isProp (x ≡ y)

isContr : ∀ {ℓ} → Set ℓ → Set ℓ
isContr A = Σ A (λ c → ∀ x → c ≡ x)

isProp-⊥ : isProp ⊥
isProp-⊥ x y = ⊥-elim x

isProp-⊤ : isProp ⊤
isProp-⊤ x y i = tt

isContr-⊤ : isContr ⊤
isContr-⊤ = tt , λ x i → tt

-- 否定总是 prop（书 3.6.1：⊥ 的唯一性 + funext）
isProp-¬ : ∀ {ℓ} {A : Set ℓ} → isProp (A → ⊥)
isProp-¬ f g = funext λ a → ⊥-elim (f a)

-- Π 的封闭律（例 3.6.2）
isProp-Π : ∀ {ℓ ℓ'} {A : Set ℓ} {P : A → Set ℓ'}
         → (∀ x → isProp (P x)) → isProp (∀ x → P x)
isProp-Π pProps f g = funext λ x → pProps x (f x) (g x)

-- prop 上的依赖路径 = 普通等式（本文件反复用的小引理）
pathOverProp : ∀ {ℓ ℓ'} {A : Set ℓ} {Q : A → Set ℓ'}
             → (pQ : ∀ z → isProp (Q z))
             → ∀ {u v : A} (q : u ≡ v) (pu : Q u) (pv : Q v)
             → PathP (λ i → Q (q i)) pu pv
pathOverProp {Q = Q} pQ {u} q pu pv =
  J (λ v q₀ → (pv₀ : Q v) → PathP (λ i → Q (q₀ i)) pu pv₀)
    (λ pv₀ → pQ u pu pv₀) q pv

-- ============================================================
-- 二、命题截断：真 HIT（书 3.7）
-- ============================================================

data ∥_∥ {ℓ} (A : Set ℓ) : Set ℓ where
  ∣_∣   : A → ∥ A ∥
  squash : (x y : ∥ A ∥) → x ≡ y

isProp-∥∥ : ∀ {ℓ} {A : Set ℓ} → isProp ∥ A ∥
isProp-∥∥ = squash

-- 非依赖消去（3.7.1 记号表的发动机）
∥∥-rec : ∀ {ℓ ℓ'} {A : Set ℓ} {B : Set ℓ'}
       → isProp B → (A → B) → ∥ A ∥ → B
∥∥-rec pB f ∣ a ∣ = f a
∥∥-rec pB f (squash x y i) = pB (∥∥-rec pB f x) (∥∥-rec pB f y) i

-- 依赖消去（3.7.3 的完整版）
∥∥-elim : ∀ {ℓ ℓ'} {A : Set ℓ} (P : ∥ A ∥ → Set ℓ')
        → (∀ z → isProp (P z)) → (∀ a → P ∣ a ∣)
        → ∀ z → P z
∥∥-elim P pP h ∣ a ∣ = h a
∥∥-elim P pP h (squash x y i) =
  pathOverProp pP (squash x y) (∥∥-elim P pP h x) (∥∥-elim P pP h y) i

-- ============================================================
-- 三、单端点路径空间合同（3.11.8）与 isProp(isContr)（3.11.4）
-- ============================================================

-- Σ(x:A). a ≡ x 合同：中心 (a, refl)——「合同数据可忽略」之首例
isContr-pathFrom : ∀ {ℓ} {A : Set ℓ} (a : A) → isContr (Σ A (λ x → a ≡ x))
isContr-pathFrom a .fst = a , refl
isContr-pathFrom a .snd (x , p) i = p i , λ j → p (i ∧ᵢ j)
  -- Σ 路径是分量式的（cubical 红利：无需书 2.7 的拆解引理）：
  --   第一分量 p i : a ≡ x 随 i 走；第二分量方形 λ j → p (i∧j)
  --   连接 refl 与 p

-- isContr ⇒ isProp（3.11.3(i)⇒(ii) 的即时半）：经中心连线
isContr-isProp : ∀ {ℓ} {A : Set ℓ} → isContr A → isProp A
isContr-isProp (c , p) x y i = (sym (p x) ∙ p y) i

-- 3.11.4（isContr A 自己是 prop）完整证明需要「度规恒等式」
-- u ≡ sym (p x) ∙ p y（J 一击）与依赖 funext 的 PathP 化——
-- 与 64 章 4.2.6 同列回填件（67 章 fib 合同性机械就位后）。

-- ============================================================
-- 四、逻辑记号表（3.7.1）与 mere prop 的封闭
-- ============================================================

data _⊎′_ {ℓ} (X Y : Set ℓ) : Set ℓ where
  inj₁ : X → X ⊎′ Y
  inj₂ : Y → X ⊎′ Y

infix  30 ¬_
infixr 26 _∧_
infixr 24 _∨_
infix  22 ∃-syntax

¬_ : ∀ {ℓ} → Set ℓ → Set ℓ
¬ A = A → ⊥

_∧_ : ∀ {ℓ} → Set ℓ → Set ℓ → Set ℓ
A ∧ B = Σ A (λ _ → B)

_∨_ : ∀ {ℓ} → Set ℓ → Set ℓ → Set ℓ
A ∨ B = ∥ A ⊎′ B ∥

∃-syntax : ∀ {ℓ ℓ'} {A : Set ℓ} (P : A → Set ℓ') → Set _
∃-syntax {A = A} P = ∥ Σ A P ∥

syntax ∃-syntax (λ x → B) = ∃ x , B

-- 两个 prop 的合取是 prop；析取（截断后）是 prop
isProp-∧ : ∀ {ℓ} {A B : Set ℓ} → isProp A → isProp B → isProp (A ∧ B)
isProp-∧ pA pB (a , b) (a′ , b′) i = (pA a a′ i , pB b b′ i)

isProp-∨ : ∀ {ℓ} {A B : Set ℓ} → isProp (A ∨ B)
isProp-∨ = squash

-- ============================================================
-- 五、经典 vs 直觉（3.4）：LEM ⇔ DNE
-- ============================================================

-- LEM（-1 版，3.4.1）与 DNE（3.4.2）——作为假设类型
LEM : ∀ {ℓ} → Set (lsuc ℓ)
LEM {ℓ} = (A : Set ℓ) → isProp A → (A ⊎′ ¬ A)

DNE : ∀ {ℓ} → Set (lsuc ℓ)
DNE {ℓ} = (A : Set ℓ) → isProp A → ¬ ¬ A → A

-- DNE ⇒ LEM 的钥匙（书练习 3.18 的核心件）：
-- A prop ⇒ A ⊎′ ¬ A 是 prop——四情形逐一处理，跨侧情形靠 ⊥-elim
isProp-sum¬ : ∀ {ℓ} {A : Set ℓ} → isProp A → isProp (A ⊎′ ¬ A)
isProp-sum¬ pA (inj₁ a) (inj₁ a′) i = inj₁ (pA a a′ i)
isProp-sum¬ pA (inj₁ a) (inj₂ n) = ⊥-elim (n a)
isProp-sum¬ pA (inj₂ n) (inj₁ a) = ⊥-elim (n a)
isProp-sum¬ pA (inj₂ n) (inj₂ n′) i = inj₂ (isProp-¬ n n′ i)

-- ¬¬(A ⊎′ ¬A) 对任意 A 构造性成立（21 章已有同型：nn-or）
nn-sum¬ : ∀ {ℓ} {A : Set ℓ} → ¬ ¬ (A ⊎′ ¬ A)
nn-sum¬ k = k (inj₂ λ a → k (inj₁ a))

-- DNE ⇒ LEM：钥匙一转
DNE→LEM : ∀ {ℓ} → DNE {ℓ} → LEM {ℓ}
DNE→LEM dne A pA = dne (A ⊎′ ¬ A) (isProp-sum¬ pA) nn-sum¬

-- LEM ⇒ DNE（方向二）：经典必经之路
LEM→DNE : ∀ {ℓ} → LEM {ℓ} → DNE {ℓ}
LEM→DNE lem A pA nn with lem A pA
... | inj₁ a = a
... | inj₂ n = ⊥-elim (nn n)

-- 可判定（3.4.3）：不是所有类型可判定——是「某些类型可判定」
Decidable : ∀ {ℓ} → Set ℓ → Set ℓ
Decidable A = A ⊎′ ¬ A

hasDecEq : ∀ {ℓ} → Set ℓ → Set ℓ
hasDecEq A = (x y : A) → Decidable (x ≡ y)

-- Bool 可判定等式：跨侧情形用「谓词分离」——
-- T true = ⊤、T false = ⊥，true≡false 的路径把 tt 搬进 ⊥
sep-Bool : Bool → Set
sep-Bool true = ⊤
sep-Bool false = ⊥

tf-≠ : true ≡ false → ⊥
tf-≠ p = transport (λ i → sep-Bool (p i)) tt

dec-Bool : hasDecEq Bool
dec-Bool true true = inj₁ refl
dec-Bool true false = inj₂ tf-≠
dec-Bool false true = inj₂ (λ p → tf-≠ (sym p))
dec-Bool false false = inj₁ refl

-- ============================================================
-- 六、AC（3.8）与合同族的 Π（3.11.6）
-- ============================================================

-- 免费方向（注 3.8.4 右推左）：∥Π Y∥ → Π ∥Y∥——
-- trunc 一次给全部，逐点 eval 再各包一层
∥Π∥→Π∥ : ∀ {ℓ ℓ'} {X : Set ℓ} {Y : X → Set ℓ'}
        → ∥ ((x : X) → Y x) ∥ → ((x : X) → ∥ Y x ∥)
∥Π∥→Π∥ = λ e x → ∥∥-rec squash (λ g → ∣ g x ∣) e

-- AC 本身（（Πx ∥Y x∥) → ∥Π Y∥）是公理级假设：
AC : ∀ {ℓ ℓ'} → Set (lsuc (ℓ ⊔ ℓ'))
AC {ℓ} {ℓ'} = (X : Set ℓ) (Y : X → Set ℓ') → isSet X → (∀ x → isSet (Y x))
            → ((x : X) → ∥ Y x ∥) → ∥ ((x : X) → Y x) ∥

-- 合同族的 Π 合同（3.11.6——它等价于 funext！）
isContr-Π : ∀ {ℓ ℓ'} {A : Set ℓ} {P : A → Set ℓ'}
          → (∀ x → isContr (P x)) → isContr ((x : A) → P x)
isContr-Π contrs .fst x = contrs x .fst
isContr-Π contrs .snd f i x = contrs x .snd (f x) i
  -- 收缩逐点进行——「funext 一次到位」的 cubical 化身

-- 恰一选择（3.9 的形状）：纤维合同 ⇒ 截断后的选择可兑现——
-- 目标是 prop（Π 的合同族），直接 rec；甚至见证 g 原样可用
uniqueChoice : ∀ {ℓ ℓ'} {A : Set ℓ} {P : A → Set ℓ'}
             → (∀ x → isContr (P x))
             → ∥ ((x : A) → P x) ∥ → ((x : A) → P x)
uniqueChoice contrs e =
  ∥∥-rec (isProp-Π (λ x → isContr-isProp (contrs x))) (λ g → g) e
  -- 「恰一 ⇒ 可选」在 HoTT 里是定理而非公理——与 21 章
  --（λC 编码线）的 ι 需要古典 choice 对照：恰一性把账单清零
