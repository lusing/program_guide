{-# OPTIONS --cubical #-}
----------------------------------------------------------------
-- 37 等价论 —— cubical Agda 主力（HoTT 书 ch.4）
--   · mini-cubical 前奏：J 是两行程序（不是公理）、
--     transportRefl 用 φ=i1 的定义归约、路径群律七条 J-归纳
--   · 等价的四定义：qinv / ishae（半伴随）/ biinv（双可逆）/
--     contrFib（合同纤维）——等价网络：qinv→ishae（4.2.3 的
--     ε′-重构）、ishae→biinv、biinv→qinv（2.4.10）
--   · ua 手造（Glue 原语）；funext 免费：λ i j → h j i
----------------------------------------------------------------
module ex48_equivalence where

open import Agda.Primitive
open import Agda.Primitive.Cubical renaming
  ( primIMin to _∧_ ; primIMax to _∨_ ; primINeg to ~_ ; itIsOne to 1=1
  ; primTransp to transp ; primHComp to hcomp )
open import Agda.Builtin.Cubical.Path
open import Agda.Builtin.Cubical.Glue
open import Agda.Builtin.Sigma
open import Agda.Builtin.Bool using (Bool; true; false)

-- ============================================================
-- 〇、mini-cubical 前奏
-- ============================================================

infixr 9 _∘_
_∘_ : ∀ {ℓ ℓ' ℓ''} {A : Set ℓ} {B : Set ℓ'} {C : Set ℓ''}
    → (B → C) → (A → B) → A → C
(g ∘ h) x = g (h x)

refl : ∀ {ℓ} {A : Set ℓ} {x : A} → x ≡ x
refl {x = x} = λ _ → x

sym : ∀ {ℓ} {A : Set ℓ} {x y : A} → x ≡ y → y ≡ x
sym p = λ i → p (~ i)

transport : ∀ {ℓ} (A : I → Set ℓ) → A i0 → A i1
transport A = transp A i0

-- J：路径归纳在 cubical 里是一个 transport——公理变程序
J : ∀ {ℓ ℓ'} {A : Set ℓ} {x : A} (P : ∀ z → x ≡ z → Set ℓ')
  → P x refl → ∀ {y} (p : x ≡ y) → P y p
J P d p = transport (λ i → P (p i) (λ j → p (i ∧ j))) d

cong : ∀ {ℓ ℓ'} {A : Set ℓ} {B : A → Set ℓ'} {x y : A}
     → (f : (a : A) → B a) (p : x ≡ y) → PathP (λ i → B (p i)) (f x) (f y)
cong f p = λ i → f (p i)

-- 常族传输计算律：transp 在 φ=i1 处定义归约为恒等
transportRefl : ∀ {ℓ} {A : Set ℓ} (a : A) → transport (λ _ → A) a ≡ a
transportRefl {A = A} a j = transp (λ _ → A) j a

infixl 30 _∙_
_∙_ : ∀ {ℓ} {A : Set ℓ} {x y z : A} → x ≡ y → y ≡ z → x ≡ z
_∙_ {x = x} p q = J (λ z _ → x ≡ z) p q

-- ---- 路径群律（J-归纳；基座全部依赖 transportRefl） ----
rUnit : ∀ {ℓ} {A : Set ℓ} {x y : A} (p : x ≡ y) → p ∙ refl ≡ p
rUnit = J (λ z q → q ∙ refl ≡ q) (transportRefl refl)

lUnit : ∀ {ℓ} {A : Set ℓ} {x y : A} (p : x ≡ y) → refl ∙ p ≡ p
lUnit {x = x} = J (λ z q → refl {x = x} ∙ q ≡ q) (transportRefl refl)

symInv : ∀ {ℓ} {A : Set ℓ} {x y : A} (p : x ≡ y) → sym (sym p) ≡ p
symInv = J (λ z q → sym (sym q) ≡ q) refl

rInv : ∀ {ℓ} {A : Set ℓ} {x y : A} (p : x ≡ y) → p ∙ sym p ≡ refl
rInv = J (λ z q → q ∙ sym q ≡ refl) (transportRefl refl)

lInv : ∀ {ℓ} {A : Set ℓ} {x y : A} (p : x ≡ y) → sym p ∙ p ≡ refl
lInv = J (λ z q → sym q ∙ q ≡ refl) (transportRefl refl)

assoc : ∀ {ℓ} {A : Set ℓ} {x y z w : A} (p : x ≡ y) (q : y ≡ z) (r : z ≡ w)
      → p ∙ (q ∙ r) ≡ (p ∙ q) ∙ r
assoc p q = J (λ w r₀ → p ∙ (q ∙ r₀) ≡ (p ∙ q) ∙ r₀)
              (cong (λ h → p ∙ h) (rUnit q) ∙ sym (rUnit (p ∙ q)))

-- ---- 同伦与自然性（书 2.4.1–2.4.4） ----
infix 4 _∼_
_∼_ : ∀ {ℓ ℓ'} {A : Set ℓ} {B : A → Set ℓ'} → (∀ x → B x) → (∀ x → B x) → Set _
_∼_ {B = B} f g = ∀ x → f x ≡ g x

-- cong 在 refl 上计算掉（定义性——cubical 的红利）
congRefl : ∀ {ℓ ℓ'} {A : Set ℓ} {B : A → Set ℓ'} (f : (a : A) → B a) {x : A}
         → cong f refl ≡ refl {x = f x}
congRefl f = refl

-- 引理 2.4.3：同伦的自然性（基座 p=refl 时两侧都剥掉 cong）
natH : ∀ {ℓ ℓ'} {A : Set ℓ} {B : Set ℓ'} {f g : A → B}
     → (H : f ∼ g) → ∀ {x y : A} (p : x ≡ y)
     → H x ∙ cong g p ≡ cong f p ∙ H y
natH {f = f} {g = g} H {x = x} =
  J (λ y p → H x ∙ cong g p ≡ cong f p ∙ H y)
    (cong (λ k → H x ∙ k) (congRefl g)
      ∙ rUnit (H x)
      ∙ sym (lUnit (H x))
      ∙ cong (λ k → k ∙ H x) (sym (congRefl f)))

-- 系 2.4.4：到恒等的同伦满足 H(h x) ≡ cong h (H x)——取消律链
hdistr : ∀ {ℓ} {A : Set ℓ} {h : A → A} (H : h ∼ (λ x → x)) (x : A)
       → H (h x) ≡ cong h (H x)
hdistr {h = h} H x =
    sym (rUnit (H (h x)))
  ∙ cong (λ k → H (h x) ∙ k) (sym (rInv (H x)))
  ∙ assoc (H (h x)) (H x) (sym (H x))
  ∙ cong (λ k → k ∙ sym (H x)) (natH H (H x))
  ∙ sym (assoc (cong h (H x)) (H x) (sym (H x)))
  ∙ cong (λ k → cong h (H x) ∙ k) (rInv (H x))
  ∙ rUnit (cong h (H x))

-- ============================================================
-- 一、等价的四定义（书 4.1–4.4）
-- ============================================================

-- 定义 2.4.6：拟逆——「教科书同构」，问题：不是命题
record QInv {ℓ ℓ'} {A : Set ℓ} {B : Set ℓ'} (f : A → B) : Set (ℓ ⊔ ℓ') where
  constructor mkQInv
  field
    qinv-g : B → A
    qinv-α : (f ∘ qinv-g) ∼ (λ y → y)
    qinv-β : (qinv-g ∘ f) ∼ (λ x → x)

-- 定义 4.2.1：半伴随等价——多一条 2-维相干 τ
record IshaE {ℓ ℓ'} {A : Set ℓ} {B : Set ℓ'} (f : A → B) : Set (ℓ ⊔ ℓ') where
  constructor mkIshaE
  field
    ishae-g : B → A
    ishae-η : (ishae-g ∘ f) ∼ (λ x → x)
    ishae-ε : (f ∘ ishae-g) ∼ (λ y → y)
    ishae-τ : ∀ x → cong f (ishae-η x) ≡ ishae-ε (f x)

-- 定义 4.3.1：双可逆——左逆与右逆，两个独立的口袋
record BiInv {ℓ ℓ'} {A : Set ℓ} {B : Set ℓ'} (f : A → B) : Set (ℓ ⊔ ℓ') where
  constructor mkBiInv
  field
    biinv-gl : B → A
    biinv-ηl : (biinv-gl ∘ f) ∼ (λ x → x)     -- 左逆（linv）
    biinv-gr : B → A
    biinv-εr : (f ∘ biinv-gr) ∼ (λ y → y)     -- 右逆（rinv）

-- 定义 4.4.1：合同纤维（contrFib）——fib 的合同性
isContr : ∀ {ℓ} (A : Set ℓ) → Set ℓ
isContr A = Σ A (λ c → ∀ y → c ≡ y)

fib : ∀ {ℓ ℓ'} {A : Set ℓ} {B : Set ℓ'} (f : A → B) (y : B) → Set (ℓ ⊔ ℓ')
fib f y = Σ _ (λ x → f x ≡ y)

ContrFib : ∀ {ℓ ℓ'} {A : Set ℓ} {B : Set ℓ'} (f : A → B) → Set (ℓ ⊔ ℓ')
ContrFib f = ∀ y → isContr (fib f y)

-- ============================================================
-- 二、等价网络（每个箭头一段可计算程序）
-- ============================================================

-- qinv → ishae（书 4.2.3）：ε 不能照抄——ε′ 要「预制」得能被
-- τ 拆回 f(η x)。ε′(y) := sym(α(f(g y))) ∙ (cong f (β (g y)) ∙ α y)
qinv→ishae : ∀ {ℓ ℓ'} {A : Set ℓ} {B : Set ℓ'} {f : A → B}
           → QInv f → IshaE f
qinv→ishae {f = f} (mkQInv g α β) = mkIshaE g β ε′ τ where
  ε′ : (f ∘ g) ∼ (λ y → y)
  ε′ y = sym (α (f (g y))) ∙ (cong f (β (g y)) ∙ α y)
  -- τ(x) : cong f (β x) ≡ ε′(f x) —— 由 2.4.4（βg ≡ cong (g∘f) βx）
  -- 与 2.4.3（α 的自然性：α₂ ∙ fb ≡ cong (f∘g) fb ∙ α₁）装配
  τ : ∀ x → cong f (β x) ≡ ε′ (f x)
  τ x = chain where
    βg  = β (g (f x))                    -- g(f(g(f x))) ≡ g(f x)
    α₁  = α (f x)                        -- f(g(f x)) ≡ f x
    α₂  = α (f (g (f x)))                -- f(g(f(g(f x)))) ≡ f(g(f x))
    fb  = cong f (β x)                   -- f(g(f x)) ≡ f x（= f(η x)）
    -- 2.4.4：βg ≡ cong (g∘f) (β x)，两边套 cong f
    step₁ : cong f βg ≡ cong (f ∘ (g ∘ f)) (β x)
    step₁ = cong (λ k → cong f k) (hdistr β x)
    -- 2.4.3（α 的自然性，p := fb）：α₂ ∙ fb ≡ cong (f∘g) fb ∙ α₁
    step₂ : α₂ ∙ fb ≡ cong (f ∘ (g ∘ f)) (β x) ∙ α₁
    step₂ = natH α fb
    chain = -- fb ≡ refl ∙ fb ≡ (sym α₂ ∙ α₂) ∙ fb ≡ sym α₂ ∙ (α₂ ∙ fb)
      sym (lUnit fb)
      ∙ cong (λ k → k ∙ fb) (sym (lInv α₂))
      ∙ sym (assoc (sym α₂) α₂ fb)
      -- ≡ sym α₂ ∙ (cong (f∘g∘f) (β x) ∙ α₁)     [step₂]
      ∙ cong (λ k → sym α₂ ∙ k) step₂
      -- ≡ sym α₂ ∙ (cong f βg ∙ α₁)              [step₁ 反向]
      ∙ cong (λ k → sym α₂ ∙ (k ∙ α₁)) (sym step₁)

-- ishae → biinv：把 g+η 与 g+ε 分装两个口袋（忘却 τ）
ishae→biinv : ∀ {ℓ ℓ'} {A : Set ℓ} {B : Set ℓ'} {f : A → B}
            → IshaE f → BiInv f
ishae→biinv (mkIshaE g η ε τ) = mkBiInv g η g ε

-- biinv → qinv（书 2.4.10 方向二）：γ : gᵣ ∼ gₗ 把两个逆缝合，
-- β′(x) : gᵣ(f x) ≡ x := γ(f x) ∙ ηₗ(x)（右逆点先跳到左逆点再回家）
biinv→qinv : ∀ {ℓ ℓ'} {A : Set ℓ} {B : Set ℓ'} {f : A → B}
           → BiInv f → QInv f
biinv→qinv {f = f} (mkBiInv gl ηl gr εr) = mkQInv gr εr β′ where
  -- γ(y) : gr y ≡ gl y ——经 gl(f(gr y)) 中转：ηₗ 的逆搭桥、εᵣ 上 cong
  γ : ∀ y → gr y ≡ gl y
  γ y = sym (ηl (gr y)) ∙ cong gl (εr y)
  -- β′(x) : gr(f x) ≡ x
  β′ : (gr ∘ f) ∼ (λ x → x)
  β′ x = γ (f x) ∙ ηl x

-- ============================================================
-- 三、样本（Bool 取反是最小的非平凡自等价）
-- ============================================================

idIshaE : ∀ {ℓ} (A : Set ℓ) → IshaE (λ (x : A) → x)
idIshaE A = mkIshaE (λ x → x) (λ x → refl) (λ y → refl) (λ x → refl)

not : Bool → Bool
not true = false
not false = true

negbIshaE : IshaE not
negbIshaE = mkIshaE not η ε τ where
  η : (not ∘ not) ∼ (λ (b : Bool) → b)
  η true = refl
  η false = refl
  ε : (not ∘ not) ∼ (λ (b : Bool) → b)
  ε true = refl
  ε false = refl
  τ : ∀ b → cong not (η b) ≡ ε (not b)
  τ true = refl
  τ false = refl

-- ============================================================
-- 四、ua 手造（Glue 原语）——泛等不是公理是程序
-- ============================================================

open import Agda.Builtin.Cubical.Equiv public
  renaming (isEquiv to IsEquivB; _≃_ to _≃b_; equivFun to equivFunB)

-- builtin isEquiv 的 field equiv-proof : (y : B) → isContr (fiber f y)
-- 与本章 ContrFib 同一个定义（书 4.4 的「合同纤维」即 cubical
-- 库的正统 isequiv），桥是一个 record 包装：
contrFib→builtin : ∀ {ℓ ℓ'} {A : Set ℓ} {B : Set ℓ'} {f : A → B}
                 → ContrFib f → IsEquivB f
contrFib→builtin cf .IsEquivB.equiv-proof = cf

-- 恒等等价（copattern 展开：纤维合同性的两块数据）
idEquiv′ : ∀ {ℓ} (B : Set ℓ) → Σ (B → B) (λ f → IsEquivB f)
idEquiv′ B .fst y = y
idEquiv′ B .snd .IsEquivB.equiv-proof y .fst = y , refl
idEquiv′ B .snd .IsEquivB.equiv-proof y .snd (z , p) i =
  sym p i , (λ j → p (~ i ∨ j))

-- ua：两端分别粘（A 经 e）与（B 经恒等）——一条 I 上的 Glue 线
ua : ∀ {ℓ} {A B : Set ℓ} → Σ (A → B) (λ f → IsEquivB f) → A ≡ B
ua {A = A} {B = B} e i =
  primGlue B
    (λ { (i = i0) → A ; (i = i1) → B })
    (λ { (i = i0) → e ; (i = i1) → idEquiv′ B })

-- ua 的 β 计算律（cubical 招牌：可证，非公理）：
uaβ : ∀ {ℓ} {A B : Set ℓ} (e : Σ (A → B) (λ f → IsEquivB f)) (a : A)
    → transport (λ i → ua e i) a ≡ e .fst a
uaβ e a = transportRefl (e .fst a)

-- ============================================================
-- 五、funext 免费版——cubical 的另一张招牌
-- ============================================================

-- 函数外延：同伦 → 相等，一行（方形的转置）
funext : ∀ {ℓ ℓ'} {A : Set ℓ} {B : A → Set ℓ'} {f g : ∀ x → B x}
       → f ∼ g → f ≡ g
funext h i j = h j i

-- 对照（书 4.9）：公理化世界里 funext 是公理、UA⇒funext 是定理；
-- cubical 里 funext 是 λ i j → h j i——而 UA 也不需要（ua 是程序）。

-- ============================================================
-- 六、qinv 的病：恒等函数的拟逆 ≃「全员自环」（书 4.1.1 方向一）
-- ============================================================

-- qinv(id) 里藏着 Π(x:A).x≡x：两个同伦的「错位差」就是自环
qinv-id→loops : ∀ {ℓ} {A : Set ℓ} → QInv (λ (x : A) → x) → ∀ x → x ≡ x
qinv-id→loops (mkQInv g α β) x = sym (β x) ∙ α x

-- 反方向（loops → qinv(id)）：环 r 变成 α := r、β := refl 的拟逆
loops→qinv-id : ∀ {ℓ} {A : Set ℓ} → (∀ x → x ≡ x) → QInv (λ (x : A) → x)
loops→qinv-id r = mkQInv (λ x → x) r (λ x → refl)

-- 于是当 A 有非平凡自环（53 章的 S¹：loop ≠ refl）时，
-- qinv(id_A) 至少有两个不同元素——「f 是等价」不是命题（书 4.1.3）。
-- 完整的 qinv(f) ≃ Π(x:A).x≡x（UA 下的满等价，书引理 4.1.1）
-- 需要 mere prop 与合同性机械（39/51 章）——彼处回填。
