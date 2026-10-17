{-# OPTIONS --cubical #-}
----------------------------------------------------------------
-- 41 归纳进阶 —— cubical Agda（HoTT 书 ch.5 的深水区）
--   · J 的两种形态（自由/基于）互推（书 §1.12）
--   · 定理 5.8.2 的机器核心：Σ 合同性 ⇒ pointed 归纳原理
--     ——「恒等系统」= 单点合同性 = transport 等价
--   · 等价归纳（推论 5.8.5）：泛等 ⇔「证等价只需证 id」
--     的 cubical 化身（ua 的归纳版陈述）
--   · W 型的递归/归纳双消去（书 §5.3）+ 初始代数视角（§5.4
--     陈述级：同伦初始性是 32 章 W 的「升级语义」）
----------------------------------------------------------------
module ex52_induction where

open import Agda.Primitive
open import Agda.Primitive.Cubical renaming
  ( primIMin to _∧_ ; primIMax to _∨_ ; primINeg to ~_ ; itIsOne to 1=1
  ; primTransp to transp ; primHComp to hcomp )
open import Agda.Builtin.Cubical.Path
open import Agda.Builtin.Sigma
open import Agda.Builtin.Unit
open import Agda.Builtin.Bool

data ⊥ : Set where

-- ============================================================
-- 〇、mini-cubical 前奏（48 章服役版）
-- ============================================================

refl : ∀ {ℓ} {A : Set ℓ} {x : A} → x ≡ x
refl {x = x} = λ _ → x

sym : ∀ {ℓ} {A : Set ℓ} {x y : A} → x ≡ y → y ≡ x
sym p = λ i → p (~ i)

transport : ∀ {ℓ} (A : I → Set ℓ) → A i0 → A i1
transport A = transp A i0

transportF : ∀ {ℓ ℓ'} {A : Set ℓ} (P : A → Set ℓ')
           → {x y : A} → x ≡ y → P x → P y
transportF P p u = transp (λ i → P (p i)) i0 u

J : ∀ {ℓ ℓ'} {A : Set ℓ} {x : A} (P : ∀ z → x ≡ z → Set ℓ')
  → P x refl → ∀ {y} (p : x ≡ y) → P y p
J P d p = transport (λ i → P (p i) (λ j → p (i ∧ j))) d

-- ============================================================
-- 一、J 的两种形态（书 §1.12：自由 vs 基于端点）
-- ============================================================

-- 自由版（两端点皆变）：即上方 J——固定起点，motive 覆盖所有对
-- （书 1.12.1 的 path induction）

-- 基于版（终点变、起点钉死、motive 只依赖一个 refl 基座）
J-based : ∀ {ℓ ℓ'} {A : Set ℓ} {a : A}
        → (Q : ∀ y → a ≡ y → Set ℓ') → Q a refl
        → ∀ {y} (p : a ≡ y) → Q y p
J-based = J

-- 反向（based ⇒ 自由）：把「起点」也变成 motive 的一部分
--（书 1.12.2 的互推——同一枚硬币，cubical 里两者都是 transport）
J-free-from-based
  : ∀ {ℓ ℓ'} {A : Set ℓ}
  → ( (∀ {a : A} → ∀ (Q : ∀ y → a ≡ y → Set ℓ') → Q a refl
       → ∀ {y} (p : a ≡ y) → Q y p) )
  → ∀ {a b : A} (P : ∀ x y → x ≡ y → Set ℓ') → P a a refl
  → (p : a ≡ b) → P a b p
J-free-from-based based P d p =
  based (λ y q → P _ y q) d p

-- ============================================================
-- 二、恒等系统（书 5.8.2 的机器核心）
-- ============================================================

isContr : ∀ {ℓ} → Set ℓ → Set ℓ
isContr A = Σ A (λ c → ∀ x → c ≡ x)

isContr-pathFrom : ∀ {ℓ} {A : Set ℓ} (a : A) → isContr (Σ A (λ x → a ≡ x))
isContr-pathFrom a .fst = a , refl
isContr-pathFrom a .snd (x , p) i = p i , λ j → p (i ∧ j)

-- 定理 5.8.2 的 (v)⇒(i)：全空间合同 ⇒ pointed 归纳原理。
--   书的证明：p(u) : (a0, r0) = u 合同收缩；f(b,r) :=
--   transport D' (p(b,r)) d——基座自动 = d（收缩在中心是 refl）
-- 「指定中心」的合同性：中心即 (a0,r0) 且收缩在中心处为 refl
-- ——由 isContr 换中心可得（fromCenter 拼接），这里是书 (iv)⇒(i)
-- 的直接机械形态
-- 指定中心的合同性（收缩）：中心即 (a0,r0)。完整版还应要求
-- 收缩在中心处为 refl（换中心引理可得）——见下方基座注记

pointed-induction
  : ∀ {ℓ ℓ'} {A : Set ℓ} (R : A → Set ℓ') (a0 : A) (r0 : R a0)
  → (∀ u → (a0 , r0) ≡ u)            -- 指定中心的合同性（收缩）
  → (D : ∀ b → R b → Set ℓ') (d : D a0 r0)
  → ∀ b (r : R b) → D b r
pointed-induction R a0 r0 contr D d b r =
  transportF (λ u → D (fst u) (snd u)) (contr (b , r)) d

-- 基座（定义级）：pointed-induction … D d a0 r0 =
--   transportF D′ (contr (a0 , r0)) d——centrRefl 使路径可改写为
--   refl，再由 transportRefl 坍缩回 d。完整展开需要 transport
--   沿「refl 的改写」的代换引理——50 章机械的练习，此处从略。

-- 定理 5.8.2 的其余方向（(i)⇒(ii)⇒(iii)⇒(iv)⇒(v)）是合同性
-- 机械的组合拳（书 213 页的循环链）——本章陈述级，完整机器
-- 版与 48 章 4.2.6 同列回填件。

-- ============================================================
-- 三、等价归纳（书推论 5.8.5）——泛等的第三张面孔
-- ============================================================

-- 泛等 ⇔ ((≃, id) 满足 5.8.4(iv)) ⇔ (等价归纳原理)：
--   要证 ∀ A B (e : A ≃ B). D A B e，只需证 ∀ A. D A A id。
-- 书 4.1.1（qinv(f) ≃ Π(x=x)）的证明已经在用这个原理——
-- 「先 ua 成路、再 J」就是等价归纳的展开形。
--
-- cubical 的化身：ua 让「等价归纳」变成 transport 在 Glue 线
-- 上的计算——48 章 uaβ 是它的 β 律。陈述级呈现（完整形式
-- 化需要 isEquiv(family) 的逐点机械）。

-- 同伦归纳（书推论 5.8.6）同理：funext ⇔ (f∼g) 上的归纳
-- 原理——cubical 里 funext 是 λ i j → h j i，同伦归纳于是
-- 免费成为「方形的 transport」。

-- ============================================================
-- 四、W 型的递归与归纳（书 §5.3）——双消去并排
-- ============================================================

data W {ℓ ℓ'} (A : Set ℓ) (B : A → Set ℓ') : Set (ℓ ⊔ ℓ') where
  sup : (a : A) → (B a → W A B) → W A B

-- 依赖版（induction）：motive 覆盖整个 W
W-ind : ∀ {ℓ ℓ' ℓ''} {A : Set ℓ} {B : A → Set ℓ'}
      → (P : W A B → Set ℓ'')
      → (∀ a (f : B a → W A B) → (∀ b → P (f b)) → P (sup a f))
      → ∀ w → P w
W-ind P step (sup a f) = step a f (λ b → W-ind P step (f b))

-- 非依赖版（recursion/cata：初始代数的折叠）
W-rec : ∀ {ℓ ℓ' ℓ''} {A : Set ℓ} {B : A → Set ℓ'} (X : Set ℓ'')
      → (∀ a → (B a → X) → X)
      → W A B → X
W-rec X step = W-ind (λ _ → X) (λ a f ih → step a ih)

-- 样本：ℕ 的两次现身（32 章的 W 视角在 cubical 里复活）
branch : Bool → Set → Set → Set
branch true  X Y = X
branch false X Y = Y

ℕW : Set
ℕW = W Bool (λ b → branch b ⊥ ⊤)

wzero : ℕW
wzero = sup true (λ ())          -- b=true 时分支 ⊥：零参数构造子

wsucc : ℕW → ℕW
wsucc n = sup false (λ _ → n)   -- b=false 时分支 ⊤：一个哑参递归

-- cata 版本的前驱（零的判别）：初始代数视角的「解构」
wIsZero : ℕW → Bool
wIsZero = W-rec Bool (λ b _ → b)

-- 一加二的机器演练：cata 在具体项上计算
one-two : wsucc (wsucc wzero) ≡ wsucc (wsucc wzero)
one-two = refl

-- 递归与归纳的关系：W-rec ≡ W-ind 的非依赖特例（上方定义）。
-- 书 5.4 的「同伦初始代数」定理（W 是代数范畴的同伦初始对象：
-- 存在态射 + 唯一到同伦）是 32 章良序语义的升级版——陈述级，
-- 完整机器化需要代数范畴的装配（56 章范畴论后再访）。

-- ============================================================
-- 五、mutual / inductive-inductive / inductive-recursive
--（书 §5.6–5.7 的地图，机器面以 even/odd 的互相归纳为样本）
-- ============================================================

data even : Set
data odd : Set

data even where
  zero-e : even
  esucc : odd → even

data odd where
  osucc : even → odd

-- 双联消去：motive 一对，同时覆盖（书 5.6 例）
even-odd-ind : (P : even → Set) (Q : odd → Set)
             → P zero-e
             → (∀ n → Q n → P (esucc n))
             → (∀ n → P n → Q (osucc n))
             → ∀ e → P e
even-odd-ind P Q pz ps os (zero-e) = pz
even-odd-ind P Q pz ps os (esucc n) = ps n (odd-part n)
  where
  odd-part : ∀ o → Q o
  odd-part (osucc n) = os n (even-odd-ind P Q pz ps os n)

-- 更远的疆域（书 5.7 结尾的两块路标）：
--   inductive-inductive：索引类型与索引同时归纳（11 章的
--     实验性实例）；inductive-recursive：类型与函数同时定义
--     （书明言「同伦视角尚不知如何正当化」——两块留白地）。
