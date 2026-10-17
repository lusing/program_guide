{-# OPTIONS --cubical #-}
----------------------------------------------------------------
-- 36 路径与同伦 · 深化件 —— cubical Agda（HoTT 书 ch.2 剩余）
--   · 类型族即 fibration（2.3）：transport 是「提升」；路径族
--     的 transport 显式公式；fibration 的「群作用」观点
--   · 型构子的高维群结构（2.5–2.7）：× 的路径=分量对；
--     Σ 的路径=Σ 路径（2.7.2——cubical 里原生分量式）
--   · 结构相等（2.14）：Σ 打包类型的等式=底路经+纤维搬运
--   · 泛性质（2.15）：× 的 UP 即等价（curry 的 qinv 版）
----------------------------------------------------------------
module ex57_fib where

open import Agda.Primitive
open import Agda.Primitive.Cubical renaming
  ( primIMin to _∧_ ; primIMax to _∨_ ; primINeg to ~_ ; itIsOne to 1=1
  ; primTransp to transp ; primHComp to hcomp )
open import Agda.Builtin.Cubical.Path
open import Agda.Builtin.Sigma

-- ============================================================
-- 〇、mini-cubical 前奏（58 章服役版）
-- ============================================================

refl : ∀ {ℓ} {A : Set ℓ} {x : A} → x ≡ x
refl {x = x} = λ _ → x

sym : ∀ {ℓ} {A : Set ℓ} {x y : A} → x ≡ y → y ≡ x
sym p = λ i → p (~ i)

transport : ∀ {ℓ} (A : I → Set ℓ) → A i0 → A i1
transport A = transp A i0

J : ∀ {ℓ ℓ'} {A : Set ℓ} {x : A} (P : ∀ z → x ≡ z → Set ℓ')
  → P x refl → ∀ {y} (p : x ≡ y) → P y p
J P d p = transport (λ i → P (p i) (λ j → p (i ∧ j))) d

cong : ∀ {ℓ ℓ'} {A : Set ℓ} {B : A → Set ℓ'} {x y : A}
     → (f : (a : A) → B a) (p : x ≡ y) → PathP (λ i → B (p i)) (f x) (f y)
cong f p = λ i → f (p i)

Path : ∀ {ℓ} (A : Set ℓ) → A → A → Set ℓ
Path A x y = PathP (λ _ → A) x y

record _×_ {ℓ ℓ'} (A : Set ℓ) (B : Set ℓ') : Set (ℓ ⊔ ℓ') where
  constructor _,_
  field
    fst : A
    snd : B
open _×_ public

-- 族版 transport（书里的 transport P p : P x → P y——沿路径搬族）
transportF : ∀ {ℓ ℓ'} {A : Set ℓ} (P : A → Set ℓ') {x y : A}
           → x ≡ y → P x → P y
transportF P p u = transp (λ i → P (p i)) i0 u

transportRefl : ∀ {ℓ} {A : Set ℓ} (a : A) → transport (λ _ → A) a ≡ a
transportRefl {A = A} a j = transp (λ _ → A) j a

infixl 30 _∙_
_∙_ : ∀ {ℓ} {A : Set ℓ} {x y z : A} → x ≡ y → y ≡ z → x ≡ z
_∙_ {x = x} p q = J (λ z _ → x ≡ z) p q

rUnit : ∀ {ℓ} {A : Set ℓ} {x y : A} (p : x ≡ y) → p ∙ refl ≡ p
rUnit = J (λ z q → q ∙ refl ≡ q) (transportRefl refl)

lUnit : ∀ {ℓ} {A : Set ℓ} {x y : A} (p : x ≡ y) → refl ∙ p ≡ p
lUnit {x = x} = J (λ z q → refl {x = x} ∙ q ≡ q) (transportRefl refl)

-- ============================================================
-- 一、类型族即 fibration（书 2.3）
-- ============================================================

-- 一个「fibration」= 类型族 P : A → Set，全空间 Σ P 投影到基。
-- transport P p : P x → P y 就是「沿 p 的平行移动」。

-- 搬运合成律 transport_{p∙q} = transport_q ∘ transport_p（2.3.11）
-- 的完整机械版需要「随路径变的族」上的双端点归纳——64 章
-- 编码-解码的正题件（彼处作为 decode 的装配件回填）。

-- 路径族的显式公式（书 2.3.10 的实例）：
--   沿 p 搬运「λz → z ≡ c」族 = 先消 p（对齐到 c）
transport-path-fam : ∀ {ℓ} {A : Set ℓ} {x y c : A}
                   → (p : x ≡ y) (q : x ≡ c)
                   → transportF (λ z → z ≡ c) p q ≡ sym p ∙ q
transport-path-fam {x = x} {c = c} p q =
  J {x = x} (λ z r → transportF (λ z₁ → z₁ ≡ c) r q ≡ sym r ∙ q)
            (transportRefl q ∙ sym (lUnit q)) p

-- fibration 视角的一句话总结：ap 与 transport 是同一枚硬币
-- 的两面——cong 把「基空间的路径」推到「全空间」，transport
-- 把「纤维间的数据」沿「基空间的路径」移动。

-- ============================================================
-- 二、型构子的高维群结构（书 2.5–2.7）
-- ============================================================

-- × 的路径（引理 2.6.2）：两分量路径对；cubical 里两个方向
-- 都是定义级的一行（书里需要 2.6.1 的 Sigma 拆解）
×Path-→ : ∀ {ℓ} {A B : Set ℓ} {u v : A × B}
        → (Path (A × B)) u v → (Path A (fst u) (fst v)) × (Path B (snd u) (snd v))
×Path-→ p = (λ i → fst (p i)) , (λ i → snd (p i))

×Path-← : ∀ {ℓ} {A B : Set ℓ} {u v : A × B}
        → (Path A (fst u) (fst v)) × (Path B (snd u) (snd v))
        → (Path (A × B)) u v
×Path-← (p , q) i = (p i , q i)

-- Σ 的路径（定理 2.7.2 的 cubical 化身）：Σ 路径原生分量式——
--   pair-path : (p : x ≡ y) → PathP (λ i → P (p i)) (u) (v) → …
-- 分量式的「存在性」在 cubical 里就是构造；对照书 2.7 的
-- 「≃ Σ(p:x=y). p* u = v」需要一个引理+两个方向。

ΣPath-→ : ∀ {ℓ ℓ'} {A : Set ℓ} {P : A → Set ℓ'}
        → {u v : Σ A P}
        → (Path (Σ A P)) u v
        → Σ (Path A (fst u) (fst v))
            (λ p → PathP (λ i → P (p i)) (snd u) (snd v))
ΣPath-→ p = (λ i → fst (p i)) , (λ i → snd (p i))

ΣPath-← : ∀ {ℓ ℓ'} {A : Set ℓ} {P : A → Set ℓ'}
        → {u v : Σ A P}
        → Σ (Path A (fst u) (fst v))
            (λ p → PathP (λ i → P (p i)) (snd u) (snd v))
        → (Path (Σ A P)) u v
ΣPath-← (p , q) i = (p i , q i)

-- 60 章 isContr-pathFrom 的两行证明正是 ΣPath-← 的实力秀：
--   单端点路径空间 Σ(x:A). a ≡ x 合同（3.11.8）。

-- ============================================================
-- 三、结构相等（书 2.14）的小样本
-- ============================================================

-- 「带结构的类型」= Σ(B : Set). 结构 B。样本：带二元运算。
Op : ∀ {ℓ} → Set ℓ → Set ℓ
Op B = B → B → B

-- 结构相等的最小实例：Σ B Op 的路径 = 底路径 + 运算的搬运
-- （2.14 的完整定理即 SIP 的雏形——66 章范畴论里长成大树）
StructurePath-→ : ∀ {ℓ} {A : Set ℓ}
                 → {s t : Σ (Set ℓ) Op}
                 → (Path (Σ (Set ℓ) Op)) s t
                 → Σ (Path (Set ℓ) (fst s) (fst t))
                     (λ p → PathP (λ i → Op (p i)) (snd s) (snd t))
StructurePath-→ = ΣPath-→
-- 反向同理（ΣPath-←）。泛等之后这条刻画将升级为
-- 「结构相等 ⟺ 结构等价」——那是 59 章 SIP 的正题。

-- ============================================================
-- 四、泛性质即等价（书 2.15）
-- ============================================================

-- × 的 UP：从 A×B 出发的函数 = 从 A 到「从 B 出发」的函数
-- （2.15.5 的样本化——记号 curry/uncurry + 拟逆证据）
record QInv {ℓ ℓ'} {A : Set ℓ} {B : Set ℓ'} (f : A → B) : Set (ℓ ⊔ ℓ') where
  constructor mkQInv
  field
    qinv-g : B → A
    qinv-α : ∀ y → f (qinv-g y) ≡ y
    qinv-β : ∀ x → qinv-g (f x) ≡ x

curry : ∀ {ℓ ℓ₁ ℓ₂} {A : Set ℓ₁} {B : Set ℓ₂} {C : Set ℓ}
      → ((A × B) → C) → (A → B → C)
curry f a b = f (a , b)

uncurry : ∀ {ℓ ℓ₁ ℓ₂} {A : Set ℓ₁} {B : Set ℓ₂} {C : Set ℓ}
        → (A → B → C) → ((A × B) → C)
uncurry g (a , b) = g a b

-- UP 的证据：curry 是（拟）等价
curry-qinv : ∀ {ℓ ℓ₁ ℓ₂} {A : Set ℓ₁} {B : Set ℓ₂} {C : Set ℓ}
           → QInv {A = (A × B) → C} {B = A → B → C} curry
curry-qinv = mkQInv uncurry (λ _ → refl) λ _ → refl
-- 两个方向的同伦都是 refl——eta 展开即定义相等。这正是
-- 「泛性质 = 等价」的第一块样板（书 2.15 的 homotopy 意象：
-- UP 不再是集合的唯一性，而是空间的合同性/等价性）。
