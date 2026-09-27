-- 第 40 章 · monoid 与折叠：单子折纸（monoidal origami）
-- 主题：手搓 monoid record；任何 monoid 都给出一个折叠（monoids as queries）；
--       fold∘map 融合与 foldr/foldMap 等价；乘积 monoid 一次折叠多路统计；
--       monoid 同态搬运计算（等价计算链）；pointwise monoid 与函数外延；
--       Foldable：折叠离开列表。
-- 所有代码在 Agda 2.9.0 + stdlib 3.0 下真实类型检查通过。

module Ex40_monoids where

open import Level using (0ℓ)
open import Data.Nat.Base using (ℕ; zero; suc; _+_; _*_; _^_)
open import Data.Nat.Properties
  using (+-assoc; +-identityˡ; +-identityʳ; +-comm
        ; *-assoc; *-identityˡ; *-identityʳ; ^-distribˡ-+-*)
open import Data.Bool.Base using (Bool; true; false; not; _∨_; _∧_)
open import Data.Bool.Properties
  using (∨-assoc; ∨-identityˡ; ∨-identityʳ; ∧-assoc; ∧-identityˡ; ∧-identityʳ)
open import Data.List.Base
  using (List; _∷_; []; _++_; map; foldr; concat; length; [_])
open import Data.List.Properties using (++-assoc; ++-identityˡ; ++-identityʳ)
open import Data.Maybe.Base using (Maybe; just; nothing)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Function.Base using (id; const; _∘_; flip)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong; cong₂; _≗_)
import Relation.Binary.PropositionalEquality as Eq
open import Axiom.Extensionality.Propositional using (Extensionality)

------------------------------------------------------------------------
-- 1. 手搓 monoid：载集 + 二元运算 + 单位元 + 三条定律
------------------------------------------------------------------------

-- mad-libs 模板逐字翻译：「A monoid is a set equipped with an associative
-- binary operation _∙_ and an identity element ε」。

Op₂ : Set → Set
Op₂ A = A → A → A

-- 裸公理记录：不打包载集，_∙_ 与 ε 作 record 参数（书中 IsMonoid）
record IsMonoid {A : Set} (_∙_ : Op₂ A) (ε : A) : Set where
  field
    assoc     : (x y z : A) → (x ∙ y) ∙ z ≡ x ∙ (y ∙ z)
    identityˡ : (x : A) → ε ∙ x ≡ x
    identityʳ : (x : A) → x ∙ ε ≡ x

open IsMonoid public

-- 打包记录：把载集也装进箱子，整个结构当一个值传递（书中 Monoid）
record Monoid : Set₁ where
  field
    Carrier   : Set
    _∙_       : Op₂ Carrier
    ε         : Carrier
    is-monoid : IsMonoid _∙_ ε

open Monoid public

-- bundle：裸 IsMonoid 装箱成 Monoid（书中 bundle 函数）
bundle : ∀ {A : Set} {_∙_ : Op₂ A} {e : A} → IsMonoid _∙_ e → Monoid
bundle {A} {∙} {e} m = record
  { Carrier   = A
  ; _∙_       = ∙
  ; ε         = e
  ; is-monoid = m
  }

-- 例一：(ℕ, +, 0) 与 (ℕ, *, 1)——定律从 stdlib 直接取货
+-0 : IsMonoid _+_ 0
assoc     +-0 = +-assoc
identityˡ +-0 = +-identityˡ
identityʳ +-0 = +-identityʳ

*-1 : IsMonoid _*_ 1
assoc     *-1 = *-assoc
identityˡ *-1 = *-identityˡ
identityʳ *-1 = *-identityʳ

-- 例二：布尔的两副面孔——or/带 false 与 and/带 true
∨-false : IsMonoid _∨_ false
assoc     ∨-false = ∨-assoc
identityˡ ∨-false = ∨-identityˡ
identityʳ ∨-false = ∨-identityʳ

∧-true : IsMonoid _∧_ true
assoc     ∧-true = ∧-assoc
identityˡ ∧-true = ∧-identityˡ
identityʳ ∧-true = ∧-identityʳ

-- 例三：同一载集、同一 ε，还能再开一个 monoid——xor（书中手案，逐情形 refl）
_xor_ : Bool → Bool → Bool
false xor y = y
true  xor y = not y

xor-false : IsMonoid _xor_ false
assoc     xor-false false y z         = refl
assoc     xor-false true  false z     = refl
assoc     xor-false true  true  false = refl
assoc     xor-false true  true  true  = refl
identityˡ xor-false x                 = refl
identityʳ xor-false false             = refl
identityʳ xor-false true              = refl

-- 例四：列表拼接
++-[] : ∀ {A : Set} → IsMonoid {A = List A} _++_ []
assoc     ++-[] = ++-assoc
identityˡ ++-[] = ++-identityˡ
identityʳ ++-[] = ++-identityʳ

-- 例五：Maybe 的「取第一个有值」
_<|>_ : ∀ {A : Set} → Maybe A → Maybe A → Maybe A
just x  <|> my = just x
nothing <|> my = my

<|>-nothing : ∀ {A : Set} → IsMonoid {A = Maybe A} _<|>_ nothing
assoc     <|>-nothing (just x) y z = refl
assoc     <|>-nothing nothing  y z = refl
identityˡ <|>-nothing x            = refl
identityʳ <|>-nothing (just x)     = refl
identityʳ <|>-nothing nothing      = refl

-- 对偶 monoid：把运算参数翻个面，三定律全部免费——
-- 「左偏 <|>」翻成「右偏」，最后一个有值白送。
-- flip 用 stdlib Function.Base 的（非依赖用法与书中手写版逐字一致）。
dual : ∀ {A : Set} {_∙_ : Op₂ A} {e : A} →
       IsMonoid _∙_ e → IsMonoid (flip _∙_) e
assoc     (dual m) x y z = sym (assoc m z y x)
identityˡ (dual m)       = identityʳ m
identityʳ (dual m)       = identityˡ m

-- 例六：自映射（endomap）复合 monoid——三定律全是 definitional 的 refl。
-- 用局部非依赖组合（stdlib _∘_ 是依赖版，隐式参数塞不进 Op₂ 的位置）。
∘-id : ∀ {A : Set} → IsMonoid {A = A → A} (λ f g x → f (g x)) id
assoc     ∘-id = λ _ _ _ → refl
identityˡ ∘-id = λ _ → refl
identityʳ ∘-id = λ _ → refl

-- 装箱全家桶（后文统一用 bundle 版）。列表/Maybe monoid 的载集随元素类型
-- 变，显式做成参数化的，避免顶层悬空 metavariable。
+-0-m = bundle +-0
*-1-m = bundle *-1
∨-m   = bundle ∨-false
∧-m   = bundle ∧-true
xor-m = bundle xor-false

++-m : ∀ {A : Set} → Monoid
++-m {A = A} = bundle (++-[] {A = A})

<|>-m : ∀ {A : Set} → Monoid
<|>-m {A = A} = bundle (<|>-nothing {A = A})

------------------------------------------------------------------------
-- 2. 与 stdlib Algebra.Structures.IsMonoid 对照
------------------------------------------------------------------------

-- stdlib 的 IsMonoid（29 章三层结构）：载集 A 与等式 _≈_ 是**模块参数**、
-- ∙ 与 ε 是 **record 参数**，落在 Set (a ⊔ ℓ)；比手搓版多一桩义务
-- ∙-cong（对 _≈_ 的同余性）。_≈_ 取 _≡_ 时 cong₂ ∙ 白送。
import Algebra.Structures as AlgStr

naive→std : ∀ {A : Set} {_∙_ : Op₂ A} {e : A} →
            IsMonoid _∙_ e → AlgStr.IsMonoid {A = A} _≡_ _∙_ e
naive→std {_∙_ = ∙} m = record
  { isSemigroup = record
      { isMagma = record
          { isEquivalence = Eq.isEquivalence
          ; ∙-cong        = cong₂ ∙
          }
      ; assoc = assoc m
      }
  ; identity = identityˡ m , identityʳ m
  }

-- 反向：stdlib 版拆开就是手搓三字段——assoc/identityˡ/identityʳ
-- 都是它的派生投影（29 章「别在 IsMonoid 上直接找 assoc」的路标）。
std→naive : ∀ {A : Set} {_∙_ : Op₂ A} {e : A} →
            AlgStr.IsMonoid {A = A} _≡_ _∙_ e → IsMonoid _∙_ e
std→naive m = record
  { assoc     = AlgStr.IsMonoid.assoc m
  ; identityˡ = AlgStr.IsMonoid.identityˡ m
  ; identityʳ = AlgStr.IsMonoid.identityʳ m
  }

-- 验收：+-0 交给 stdlib 版类型、再捞回手搓版，原样成立。
+-0-std : AlgStr.IsMonoid {A = ℕ} _≡_ _+_ 0
+-0-std = naive→std +-0

+-0-back : IsMonoid _+_ 0
+-0-back = std→naive +-0-std

-- stdlib 现货对账：Data.Nat.Properties 焊好的 +-0-isMonoid 塞进手搓
-- record 严丝合缝——「同型同证」。
open import Data.Nat.Properties using () renaming (+-0-isMonoid to std-+-0-isMonoid)

+-0-stdlib-supplied : IsMonoid _+_ 0
+-0-stdlib-supplied = std→naive std-+-0-isMonoid

------------------------------------------------------------------------
-- 3. 任何 monoid 都给出一个折叠：monoids as queries
------------------------------------------------------------------------

-- 「Monoids generate summaries」：载集 = 答案类型，ε = 默认答案，
-- ∙ = 合并两份答案。foldList 把 List A 逐元素摘要再合并：
foldList : (M : Monoid) {A : Set} (f : A → Carrier M) → List A → Carrier M
foldList M f []       = ε M
foldList M f (x ∷ xs) = Monoid._∙_ M (f x) (foldList M f xs)

-- foldL = 不做映射的折叠（列表里已经是要合并的数据；fold 一名让给 Foldable）
foldL : (M : Monoid) → List (Carrier M) → Carrier M
foldL M = foldList M id

-- 同一枚 foldList，换一个 monoid 实例就换一个「查询」：
sum : List ℕ → ℕ
sum = foldList +-0-m id

product : List ℕ → ℕ
product = foldList *-1-m id

any? : ∀ {A : Set} → (A → Bool) → List A → Bool
any? = foldList ∨-m

all? : ∀ {A : Set} → (A → Bool) → List A → Bool
all? = foldList ∧-m

-- 奇偶校验（parity/checksum，书中：噪声信道传数据的古老把戏）
parity : List Bool → Bool
parity = foldList xor-m id

-- 列表相关：拍平、取头、取尾、反转
flatten : ∀ {A : Set} → List (List A) → List A
flatten = foldList ++-m id

head : ∀ {A : Set} → List A → Maybe A
head = foldList <|>-m just

foot : ∀ {A : Set} → List A → Maybe A
foot = foldList (bundle (dual <|>-nothing)) just

reverse : ∀ {A : Set} → List A → List A
reverse = foldList (bundle (dual ++-[])) (λ x → x ∷ [])

-- 不关心元素、只关心结构的：数长度、判空
size : ∀ {A : Set} → List A → ℕ
size = foldList +-0-m (const 1)

empty? : ∀ {A : Set} → List A → Bool
empty? = foldList ∧-m (const false)

-- 算例：全部 refl 直算——抽象折叠零代价（_∙_ 字段存的就是真运算）
_ : sum (1 ∷ 20 ∷ 300 ∷ []) ≡ 321
_ = refl

_ : product (2 ∷ 3 ∷ 5 ∷ []) ≡ 30
_ = refl

_ : any? not (true ∷ true ∷ []) ≡ false
_ = refl

_ : all? not (false ∷ false ∷ []) ≡ true
_ = refl

_ : parity (true ∷ true ∷ true ∷ []) ≡ true    -- 奇数个 true
_ = refl

_ : head (1 ∷ 2 ∷ []) ≡ just 1
_ = refl

_ : foot (1 ∷ 2 ∷ []) ≡ just 2                 -- dual monoid 白送「最后一个」
_ = refl

_ : reverse (1 ∷ 2 ∷ 3 ∷ []) ≡ 3 ∷ 2 ∷ 1 ∷ []
_ = refl

_ : size (1 ∷ 2 ∷ 3 ∷ []) ≡ 3
_ = refl

_ : empty? {A = ℕ} [] ≡ true
_ = refl

------------------------------------------------------------------------
-- 4. 折纸主线：fold-++、foldr 等价、fold∘map 融合
------------------------------------------------------------------------

-- 折纸第一折：折叠是 ++ 的同态——「切两块分别算再合并」= 一次算完。
-- 这条等式就是 map-reduce 可分块/可并行的数学本体；基例恰吃 identityˡ
-- （ε 存在的理由），步例恰吃 assoc（括号随便挪）。
fold-++ : (M : Monoid) {A : Set} (f : A → Carrier M)
          (xs ys : List A) →
          foldList M f (xs ++ ys)
          ≡ Monoid._∙_ M (foldList M f xs) (foldList M f ys)
fold-++ M f []       ys = sym (identityˡ (is-monoid M) (foldList M f ys))
fold-++ M f (x ∷ xs) ys rewrite fold-++ M f xs ys
  = sym (assoc (is-monoid M) (f x) (foldList M f xs) (foldList M f ys))

-- 折纸第二折：本书 foldList 与 stdlib foldr 一一对应
-- foldList M f ≡ foldr _∙_ ε ∘ map f——纯定义展开，每步一条 cong。
fold-is-foldr : (M : Monoid) {A : Set} (f : A → Carrier M) (xs : List A) →
                foldList M f xs ≡ foldr (Monoid._∙_ M) (Monoid.ε M) (map f xs)
fold-is-foldr M f []       = refl
fold-is-foldr M f (x ∷ xs) =
  cong (Monoid._∙_ M (f x)) (fold-is-foldr M f xs)

-- 折纸第三折（融合律）：先 map 后 fold ≡ 直接带 f 的 fold——
-- 两条流水并成一条，中间列表根本不生成（fusion 的原型）。
fold-map : (M : Monoid) {A : Set} (f : A → Carrier M) (xs : List A) →
           foldList M f xs ≡ foldL M (map f xs)
fold-map M f []       = refl
fold-map M f (x ∷ xs) rewrite fold-map M f xs = refl

------------------------------------------------------------------------
-- 5. 乘积 monoid：一次折叠多路统计（Composition of Monoids）
------------------------------------------------------------------------

-- 逐分量运算、分量单位元配对，三条定律 cong₂ _,_ 一次装箱——
-- 「两个 monoid 并行跑」免费得。
_⊗_ : (M N : Monoid) → Op₂ (Carrier M × Carrier N)
_⊗_ M N (a₁ , b₁) (a₂ , b₂) = (Monoid._∙_ M a₁ a₂ , Monoid._∙_ N b₁ b₂)

×-monoid : (M N : Monoid) → Monoid
×-monoid M N = record
  { Carrier   = Carrier M × Carrier N
  ; _∙_       = _⊗_ M N
  ; ε         = Monoid.ε M , Monoid.ε N
  ; is-monoid = go M N
  }
  where
  go : (M N : Monoid) → IsMonoid (_⊗_ M N) (Monoid.ε M , Monoid.ε N)
  assoc (go M N) (a₁ , b₁) (a₂ , b₂) (a₃ , b₃) =
    cong₂ _,_ (assoc (is-monoid M) a₁ a₂ a₃) (assoc (is-monoid N) b₁ b₂ b₃)
  identityˡ (go M N) (a , b) =
    cong₂ _,_ (identityˡ (is-monoid M) a) (identityˡ (is-monoid N) b)
  identityʳ (go M N) (a , b) =
    cong₂ _,_ (identityʳ (is-monoid M) a) (identityʳ (is-monoid N) b)

-- 融合定律到 pair 上：分开折再配对 = 配对折一趟。
fold-pair : (M N : Monoid) {A : Set}
            (f : A → Carrier M) (g : A → Carrier N) (xs : List A) →
            foldList (×-monoid M N) (λ x → (f x , g x)) xs
            ≡ (foldList M f xs , foldList N g xs)
fold-pair M N f g []       = refl
fold-pair M N f g (x ∷ xs) rewrite fold-pair M N f g xs = refl

-- 应用：sum 与 size 一趟算完（两趟变一趟，且 fold-pair 就是并行的凭据）
stats : List ℕ → ℕ × ℕ
stats = foldList (×-monoid +-0-m +-0-m) (λ n → (n , 1))

stats-correct : ∀ xs → stats xs ≡ (sum xs , size xs)
stats-correct xs = fold-pair +-0-m +-0-m id (const 1) xs

_ : stats (1 ∷ 2 ∷ 3 ∷ []) ≡ (6 , 3)
_ = refl

------------------------------------------------------------------------
-- 6. monoid 同态：证一次，搬运计算终身免费
------------------------------------------------------------------------

-- 保单位元 + 保乘法（书中 MonHom 的 f-cong 字段在 _≡_ 下白送，删）。
record MonHom {M N : Monoid} (f : Carrier M → Carrier N) : Set where
  field
    preserves-ε : f (Monoid.ε M) ≡ Monoid.ε N
    preserves-∙ : (x y : Carrier M) →
                  f (Monoid._∙_ M x y) ≡ Monoid._∙_ N (f x) (f y)

open MonHom public

-- 核心定理：同态可以把 f 从折叠结果上「挤」进每个元素——
-- 先折后 f = 先 f 后折。哪侧贵就挪哪侧，本章全部性能话术的根。
hom-fold : ∀ {M N : Monoid} {f : Carrier M → Carrier N} →
           MonHom {M = M} {N = N} f →
           ∀ {A : Set} (g : A → Carrier M) (xs : List A) →
           f (foldList M g xs) ≡ foldList N (λ x → f (g x)) xs
hom-fold {M} {N} h g []       = preserves-ε h
hom-fold {M} {N} h g (x ∷ xs)
  rewrite preserves-∙ h (g x) (foldList M g xs) | hom-fold h g xs = refl

-- 同态例一（书中）：not 是 ∧-true → ∨-false 的同态，
-- preserves-∙ 展开就是 De Morgan 定律 ¬(a∧b) ≡ ¬a∨¬b——
-- 著名定理原来是「找同态」时撞出来的。
not-hom : MonHom {M = ∧-m} {N = ∨-m} not
preserves-ε not-hom          = refl
preserves-∙ not-hom false y  = refl
preserves-∙ not-hom true  y  = refl

-- 另一半 De Morgan（∨-false → ∧-true）同样一行一案：
not-hom′ : MonHom {M = ∨-m} {N = ∧-m} not
preserves-ε not-hom′         = refl
preserves-∙ not-hom′ false y = refl
preserves-∙ not-hom′ true  y = refl

-- 同态例二：sum 是 (List ℕ, ++, []) → (ℕ, +, 0) 的同态。
-- 先证 sum 对 ++ 分配律（对 xs 归纳；基例连 rewrite 都不要——
-- 0 + n 是定义式归约，08 章「左单位白送」的还魂；步例把归纳假设
-- 塞进 x +_ 的上下文里，再用 +-assoc 将括号挪回目标形状）。
sum-++ : ∀ xs ys → sum (xs ++ ys) ≡ sum xs + sum ys
sum-++ []       ys = refl
sum-++ (x ∷ xs) ys =
  trans (cong (x +_) (sum-++ xs ys)) (sym (+-assoc x (sum xs) (sum ys)))

sum-hom : MonHom {M = ++-m} {N = +-0-m} sum
preserves-ε sum-hom = refl
preserves-∙ sum-hom = sum-++

-- 「Finding equivalent computations」实例一（推理链版，14 章记号）：
-- 先拍平再求和 / 先逐表求和再合并，两条算法由同态判成同一计算。
sum-flatten : ∀ xss → sum (flatten xss) ≡ sum (map sum xss)
sum-flatten xss = begin
  sum (flatten xss)                          ≡⟨⟩
  sum (foldList ++-m id xss)                 ≡⟨ hom-fold sum-hom id xss ⟩
  foldList +-0-m (λ xs → sum (id xs)) xss    ≡⟨⟩
  foldList +-0-m sum xss                     ≡⟨ fold-map +-0-m sum xss ⟩
  foldL +-0-m (map sum xss)                   ≡⟨⟩
  sum (map sum xss)                          ∎
  where open Eq.≡-Reasoning

-- 实例二（书中 2^n 把戏）：x ↦ 2^x 是 (+,0) → (*,1) 的同态——
-- 保单位元 2^0 ≡ 1 是 refl，保乘法就是现成引理 ^-distribˡ-+-*。
-- 于是一次求和可搬成一趟求积：2 ^ sum xs ≡ product (map (2 ^_) xs)。
^-hom-2 : MonHom {M = +-0-m} {N = *-1-m} (2 ^_)
preserves-ε ^-hom-2     = refl
preserves-∙ ^-hom-2 m n = ^-distribˡ-+-* 2 m n

pow-sum≡prod : ∀ xs → 2 ^ sum xs ≡ product (map (2 ^_) xs)
pow-sum≡prod xs = begin
  2 ^ sum xs                             ≡⟨⟩
  2 ^ foldList +-0-m id xs               ≡⟨ hom-fold ^-hom-2 id xs ⟩
  foldList *-1-m (λ x → 2 ^ (id x)) xs   ≡⟨⟩
  foldList *-1-m (2 ^_) xs               ≡⟨ fold-map *-1-m (2 ^_) xs ⟩
  foldL *-1-m (map (2 ^_) xs)             ≡⟨⟩
  product (map (2 ^_) xs)                ∎
  where open Eq.≡-Reasoning

------------------------------------------------------------------------
-- 7. pointwise monoid 与函数外延：本章唯一「不免费」的地方
------------------------------------------------------------------------

-- 把 (B, ∙, ε) 逐点上提到 A → B：运算逐点、单位元常值。
_⊙_ : (A : Set) (M : Monoid) → Op₂ (A → Carrier M)
_⊙_ A M f g = λ x → Monoid._∙_ M (f x) (g x)

εᵖ : (A : Set) (M : Monoid) → A → Carrier M
εᵖ _ M = const (Monoid.ε M)

-- 数学上这当然是 monoid；Agda 里 assoc 要证
--   (λ x → (f x ∙ g x) ∙ h x) ≡ (λ x → f x ∙ (g x ∙ h x))
-- 两个 lambda 的**命题等式**，refl 卡死（实测报错见教程 40.7 正文）。
-- 逐点版（≗，外延相等）没有障碍：每取一点 x 两边各自归约，
-- 剩下就是 M 自己的 assoc——「逐点证」全是计算。
⊙-assoc-≗ : ∀ {A : Set} (M : Monoid) (f g h : A → Carrier M) →
            _⊙_ A M (_⊙_ A M f g) h ≗ _⊙_ A M f (_⊙_ A M g h)
⊙-assoc-≗ M f g h x = assoc (is-monoid M) (f x) (g x) (h x)

⊙-identityˡ-≗ : ∀ {A : Set} (M : Monoid) (f : A → Carrier M) →
                _⊙_ A M (εᵖ A M) f ≗ f
⊙-identityˡ-≗ M f x = identityˡ (is-monoid M) (f x)

⊙-identityʳ-≗ : ∀ {A : Set} (M : Monoid) (f : A → Carrier M) →
                _⊙_ A M f (εᵖ A M) ≗ f
⊙-identityʳ-≗ M f x = identityʳ (is-monoid M) (f x)

-- 从 ≗ 升级到 ≡：这就是函数外延公理。教程只 import 记录
-- （Axiom.Extensionality.Propositional，32 章：3.0 里没有
-- Function.Extensionality），pointwise 做成**外延参数化**的构造——
-- 不假设可证，谁有 ext 谁实例化。
module _ {A : Set} (M : Monoid) (ext : Extensionality 0ℓ 0ℓ) where
  pointwise : IsMonoid (_⊙_ A M) (εᵖ A M)
  assoc     pointwise f g h = ext (⊙-assoc-≗ M f g h)
  identityˡ pointwise f     = ext (⊙-identityˡ-≗ M f)
  identityʳ pointwise f     = ext (⊙-identityʳ-≗ M f)

-- 外延的另一张熟面孔（书中 Sandbox-Extensionality）：x + 2 与 2 + x。
f₁ : ℕ → ℕ
f₁ x = x + 2

f₂ : ℕ → ℕ
f₂ x = 2 + x

f₁≗f₂ : f₁ ≗ f₂
f₁≗f₂ zero    = refl
f₁≗f₂ (suc x) = cong suc (+-comm x 2)

-- refl 证 f₁ ≡ f₂？过不了（逐点 ≗ 与整体 ≡ 的落差，实测见正文 40.7）。
-- 外延在手才能一步到位：
module _ (ext : Extensionality 0ℓ 0ℓ) where
  f₁≡f₂ : f₁ ≡ f₂
  f₁≡f₂ = ext f₁≗f₂

------------------------------------------------------------------------
-- 8. Foldable：折叠离开列表（书中 Monoidal Origami 的收尾）
------------------------------------------------------------------------

-- 列表没什么特别——任何「容器」都能折。Container : Set → Set。
record Foldable (Container : Set → Set) : Set₁ where
  field
    fold : (M : Monoid) {A : Set} → (A → Carrier M) → Container A → Carrier M

fold-list : Foldable List
fold-list = record { fold = foldList }

data BinTree (A : Set) : Set where
  empty  : BinTree A
  branch : BinTree A → A → BinTree A → BinTree A

-- 中序折叠：左子树 ∙ 根 ∙ 右子树
fold-bintree : Foldable BinTree
Foldable.fold fold-bintree M f empty         = Monoid.ε M
Foldable.fold fold-bintree M f (branch l x r) =
  Monoid._∙_ M (Foldable.fold fold-bintree M f l)
    (Monoid._∙_ M (f x) (Foldable.fold fold-bintree M f r))

fold-maybe : Foldable Maybe
Foldable.fold fold-maybe M f (just x) = f x
Foldable.fold fold-maybe M f nothing  = Monoid.ε M

-- 容器无关的两条通用摘要（+·0 数元素、++-[] 收元素）：
size∀ : ∀ {C : Set → Set} (F : Foldable C) {A : Set} → C A → ℕ
size∀ F {A} = Foldable.fold F +-0-m (const 1)

elems∀ : ∀ {C : Set → Set} (F : Foldable C) {A : Set} → C A → List A
elems∀ F {A} = Foldable.fold F ++-m (λ x → x ∷ [])

-- 书中算例逐字复现：branch (leaf true) false (leaf true) 有 3 个元素
leaf : ∀ {A : Set} → A → BinTree A
leaf x = branch empty x empty

_ : size∀ fold-bintree (branch (leaf true) false (leaf true)) ≡ 3
_ = refl

_ : elems∀ fold-bintree (branch (leaf 1) 2 (leaf 3)) ≡ 1 ∷ 2 ∷ 3 ∷ []
_ = refl

_ : elems∀ fold-maybe (just 7) ≡ 7 ∷ []
_ = refl

_ : elems∀ fold-maybe {A = ℕ} nothing ≡ []
_ = refl
