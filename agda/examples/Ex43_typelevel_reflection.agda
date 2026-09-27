-- 第 43 章 · 类型层计算与证明反射
-- 主题：类型层整数 Z（零无符号）；Setω 把类型「降维」成数据；
-- 格式化打印的失败尝试与可用解；证明的反射（list 化简器 + 保语义）。
-- 所有代码在 Agda 2.9.0 + stdlib 3.0 下真实类型检查通过；
-- 反面写法的报错原文见 docs/43-typelevel-reflection.md（探针已删除）。

module Ex43_typelevel_reflection where

open import Agda.Primitive using (Setω)
open import Data.Nat using (ℕ; zero; suc; _+_; _≤ᵇ_; _≟_)
open import Data.Nat.Properties using (≤ᵇ⇒≤; ≤-antisym)
open import Data.Bool using (Bool; true; false; not; T; if_then_else_)
open import Data.List using (List; _∷_; []; [_]; _++_; map)
open import Data.List.Properties using (map-++; map-∘; ++-identityʳ; ++-assoc)
open import Data.Unit using (⊤; tt)
open import Data.String using (String; toList; fromList)
  renaming (_++_ to _++ˢ_)
open import Data.Char using (Char)
open import Data.Nat.Show using (show)
open import Function using (_∘_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong; cong₂)

------------------------------------------------------------------------
-- 1. 类型层整数：零没有符号（Stump 7.1）
------------------------------------------------------------------------

-- 单点类型：J 只有一个居民 triv——「有一个 J 什么信息都不带」
data J : Set where
  triv : J

-- 类型层函数：从「值」算出「类型」。零的符号位类型是 J，非零是 Bool。
Sign : ℕ → Set
Sign zero    = J
Sign (suc _) = Bool

-- 整数 = 幅度 + 「由幅度决定类型」的符号位。
-- 2.2 老写法 `mkZ : n : N → Z-pos-t n → Z`（参数不带括号）今为 ParseError。
data ℤt : Set where
  mkZ : (n : ℕ) → Sign n → ℤt

0Z : ℤt
0Z = mkZ zero triv            -- 零不带符号：triv 是 J 的唯一居民

1Z : ℤt
1Z = mkZ (suc zero) true      -- 非零带 Bool 符号位

-1Z : ℤt
-1Z = mkZ (suc zero) false

2Z : ℤt
2Z = mkZ (suc (suc zero)) true

-2Z : ℤt
-2Z = mkZ (suc (suc zero)) false

3Z : ℤt
3Z = mkZ 3 true               -- 数字字面量在 ℕ 上照常可用

-- 值层补一个「正号」供应器：类型层算不出符号位时手工供货
sgn : (n : ℕ) → Sign n
sgn zero    = triv
sgn (suc _) = true

-- 自然数差落成整数：纯结构递归，逐层销掉公共的 suc。
-- Stump 用三岐判定 + Σ 证明（<⊍suc）走这条路；2.9 + stdlib 3.0 里
-- 依赖模式让结构递归直接可用。
diffN : (n m : ℕ) → ℤt        -- 结果 = 整数 (n − m)
diffN zero    zero    = mkZ zero triv
diffN zero    (suc m) = mkZ (suc m) false
diffN (suc n) zero    = mkZ (suc n) true
diffN (suc n) (suc m) = diffN n m

_Z+_ : ℤt → ℤt → ℤt
mkZ zero _       Z+ z                    = z
z                Z+ mkZ zero _           = z
mkZ (suc n) true  Z+ mkZ (suc m) true    = mkZ (suc (suc (n + m))) true
mkZ (suc n) false Z+ mkZ (suc m) false   = mkZ (suc (suc (n + m))) false
mkZ (suc n) true  Z+ mkZ (suc m) false   = diffN n m
mkZ (suc n) false Z+ mkZ (suc m) true    = diffN m n

-- 类型层保证的「0 无符号」在这里兑现：以下算式全部 refl（纯计算）。
+Z-1 : 1Z Z+ -1Z ≡ 0Z
+Z-1 = refl

+Z-2 : -2Z Z+ 3Z ≡ 1Z
+Z-2 = refl

+Z-3 : 0Z Z+ -2Z ≡ -2Z
+Z-3 = refl

------------------------------------------------------------------------
-- 2. ≤Z 与反对称性：唯一表示的回报（Stump 7.1.3）
------------------------------------------------------------------------

_≤Z_ : ℤt → ℤt → Bool
mkZ zero _        ≤Z mkZ zero _          = true
mkZ zero _        ≤Z mkZ (suc _) pos     = pos
mkZ (suc _) pos   ≤Z mkZ zero _          = not pos
mkZ (suc x) true  ≤Z mkZ (suc y) true    = x ≤ᵇ y
mkZ (suc x) true  ≤Z mkZ (suc y) false   = false
mkZ (suc x) false ≤Z mkZ (suc y) true    = true
mkZ (suc x) false ≤Z mkZ (suc y) false   = y ≤ᵇ x

≤Z-1 : (1Z ≤Z 2Z) ≡ true
≤Z-1 = refl

≤Z-2 : (-2Z ≤Z 1Z) ≡ true
≤Z-2 = refl

-- Bool 判定与命题之间的一座桥（15 章 Reflects/T? 的手搓替身）
ᵇ≡true⇒T : (b : Bool) → b ≡ true → T b
ᵇ≡true⇒T true  _ = tt
ᵇ≡true⇒T false ()

≤ᵇ-antisym : ∀ a b → (a ≤ᵇ b) ≡ true → (b ≤ᵇ a) ≡ true → a ≡ b
≤ᵇ-antisym a b h₁ h₂ =
  ≤-antisym (≤ᵇ⇒≤ a b (ᵇ≡true⇒T _ h₁)) (≤ᵇ⇒≤ b a (ᵇ≡true⇒T _ h₂))

-- 反对称：x ≤Z y 且 y ≤Z x 则 x ≡ y。
-- 若 0 有正负两副面孔（Bool 符号走天下），这条从根上就断了。
≤Z-antisym : ∀ x y → (x ≤Z y) ≡ true → (y ≤Z x) ≡ true → x ≡ y
≤Z-antisym (mkZ zero triv)    (mkZ zero triv)     _  _          = refl
≤Z-antisym (mkZ zero triv)    (mkZ (suc b) true)  _  ()
≤Z-antisym (mkZ zero triv)    (mkZ (suc b) false) () _
≤Z-antisym (mkZ (suc a) true) (mkZ zero triv)     () _
≤Z-antisym (mkZ (suc a) false) (mkZ zero triv)    _  ()
≤Z-antisym (mkZ (suc a) true) (mkZ (suc b) false) () _
≤Z-antisym (mkZ (suc a) false) (mkZ (suc b) true) _  ()
≤Z-antisym (mkZ (suc a) true) (mkZ (suc b) true) h₁ h₂
  rewrite ≤ᵇ-antisym a b h₁ h₂ = refl
≤Z-antisym (mkZ (suc a) false) (mkZ (suc b) false) h₁ h₂
  rewrite ≤ᵇ-antisym b a h₁ h₂ = refl

------------------------------------------------------------------------
-- 3. Setω：把「类型」降维成数据（书中类型转换技巧的 2.9 写法）
------------------------------------------------------------------------

-- Set 自己住在 Set₁，装不进任何 Set₀ 的 datatype（实测报错见正文），
-- 只有 Setω 这层「上界宇宙」塞得下「类型的代码」。
data Ty : Setω where
  ℕ̂C     : Ty
  Bool̂C  : Ty
  Unit̂C  : Ty
  StrinĝC : Ty
  List̂C  : Ty → Ty

-- 语义函数：代码 → 真类型
⟦_⟧ᵗ : Ty → Set
⟦ ℕ̂C ⟧ᵗ      = ℕ
⟦ Bool̂C ⟧ᵗ   = Bool
⟦ Unit̂C ⟧ᵗ   = ⊤
⟦ StrinĝC ⟧ᵗ = String
⟦ List̂C t ⟧ᵗ = List ⟦ t ⟧ᵗ

-- Sign 的代码版：与 Sign 并排写，闭项上两者算法一致
signTy : ℕ → Ty
signTy zero    = Unit̂C
signTy (suc _) = Bool̂C

-- 类型层结果与代码层解释来回搬运（依赖模式让两边同步归约）
toSign : (n : ℕ) → ⟦ signTy n ⟧ᵗ → Sign n
toSign zero    tt = triv
toSign (suc n) b  = b

fromSign : (n : ℕ) → Sign n → ⟦ signTy n ⟧ᵗ
fromSign zero    triv = tt
fromSign (suc n) b    = b

roundTrip : (n : ℕ) (s : ⟦ signTy n ⟧ᵗ) → fromSign n (toSign n s) ≡ s
roundTrip zero    tt = refl
roundTrip (suc n) b  = refl

-- 类型可以「算出来再比」——宇宙账记对了才写得出（这条命题住 Set₁）
_ : Sign 5 ≡ Bool
_ = refl

_ : ⟦ signTy (2 + 3) ⟧ᵗ ≡ Sign (2 + 3)
_ = refl

-- 变量情形 Sign n 是卡住的正规式：想「看」它只能先拆 n——
-- 类型层计算的惰性在此现形（反面写法实测见正文坑位）。
peek : (n : ℕ) → Sign n → Bool
peek zero    s = false
peek (suc n) b = b

------------------------------------------------------------------------
-- 4. 格式化打印：失败尝试（Stump 7.2.1）与可用解（7.2.2）
------------------------------------------------------------------------

{-  失败尝试（探针 TmpProbe43c 实测；卡死在第三条子句）：

    format-th : List Char → Set
    format-th ('%' ∷ 'n' ∷ f) = ℕ → format-th f
    format-th ('%' ∷ 's' ∷ f) = String → format-th f
    format-th (c ∷ f)         = format-th f
    format-th []              = String

    format-h : List Char → (f : List Char) → format-th f
    format-h s ('%' ∷ 'n' ∷ f) = λ n → format-h (s ++ toList (show n)) f
    format-h s ('%' ∷ 's' ∷ f) = λ s′ → format-h (s ++ toList s′) f
    format-h s (c ∷ f)         = format-h s f     ← 报错：
      The terms f and c ∷ f are not equal at type List Char
      when checking that the expression format-h s f has type
      format-th (c ∷ f)

    死因：format-th (c ∷ f) 归约到一半卡住——c 是变量，Agda 部分求值
    时不记得「前两条子句已经匹配失败」这笔账，不敢跳到默认子句。
-}

-- 可用解：把格式串先「反射」成数据类型，类型只在构造子手上算
data Fmt : Set where
  FmtNat : Fmt → Fmt
  FmtStr : Fmt → Fmt
  FmtChr : Char → Fmt → Fmt
  FmtEnd : Fmt

⟦_⟧ᶠ : Fmt → Set
⟦ FmtNat v ⟧ᶠ   = ℕ → ⟦ v ⟧ᶠ
⟦ FmtStr v ⟧ᶠ   = String → ⟦ v ⟧ᶠ
⟦ FmtChr _ v ⟧ᶠ = ⟦ v ⟧ᶠ
⟦ FmtEnd ⟧ᶠ     = String

-- 值层的默认模式没有原罪：这里产出的是数据，不是类型
cover : List Char → Fmt
cover ('%' ∷ 'n' ∷ s) = FmtNat (cover s)
cover ('%' ∷ 's' ∷ s) = FmtStr (cover s)
cover (c ∷ s)         = FmtChr c (cover s)
cover []              = FmtEnd

fmtH : String → (f : Fmt) → ⟦ f ⟧ᶠ
fmtH acc (FmtNat v)   = λ n → fmtH (acc ++ˢ show n) v
fmtH acc (FmtStr v)   = λ s → fmtH (acc ++ˢ s) v
fmtH acc (FmtChr c v) = fmtH (acc ++ˢ fromList [ c ]) v
fmtH acc FmtEnd       = acc

format : (f : String) → ⟦ cover (toList f) ⟧ᶠ
format f = fmtH "" (cover (toList f))

-- 类型算对了：Stump 原例 "%n% of the %ss are in the %s %s"
fmt-类型 : Set
fmt-类型 = ⟦ cover (toList "%n% of the %ss are in the %s %s") ⟧ᶠ

_ : fmt-类型 ≡ (ℕ → String → String → String → String)
_ = refl

-- 值也算对了（注意串里那个孤立的 %，不是格式符）
_ : format "%n% of the %ss are in the %s %s" 25 "dog" "toasty" "doghouse"
      ≡ "25% of the dogs are in the toasty doghouse"
_ = refl

-- 语义函数能把格式串原样吐回来（cover 在「规范串」上可逆）
render : Fmt → String
render (FmtNat v)   = "%n" ++ˢ render v
render (FmtStr v)   = "%s" ++ˢ render v
render (FmtChr c v) = fromList [ c ] ++ˢ render v
render FmtEnd       = ""

rt : render (cover (toList "%n cats")) ≡ "%n cats"
rt = refl

------------------------------------------------------------------------
-- 5. 证明的反射：Expr——List A 表达式语言的小语义（Stump 7.3）
------------------------------------------------------------------------

-- ∀ {A : Set} 量词逼着 Expr 升一层：Set → Set₁（对应 Stump 的 lone；
-- 写 Set → Set 实测 ConstructorDoesNotFitInData，报错见正文）。
data Expr : Set → Set₁ where
  lit   : ∀ {A : Set} → List A → Expr A          -- 嵌入真实列表（Stump 的 _r，
                                                 -- 充当「变量/常量」：不可再拆的原子）
  _++ᵣ_ : ∀ {A : Set} → Expr A → Expr A → Expr A -- 表示 _++_
  mapᵣ  : ∀ {A B : Set} → (A → B) → Expr A → Expr B
  _∷ᵣ_  : ∀ {A : Set} → A → Expr A → Expr A      -- 表示 _∷_
  nilᵣ  : ∀ {A : Set} → Expr A                    -- 表示 []

infixr 5 _++ᵣ_ _∷ᵣ_

-- 语义：表示 → 真值。反射的全部意义：能对「表示」模式匹配——
-- (t₁ ++ t₂) 这种非构造子模式在 Agda 里根本写不出来。
⟦_⟧ : ∀ {A : Set} → Expr A → List A
⟦ lit l ⟧      = l
⟦ t₁ ++ᵣ t₂ ⟧  = ⟦ t₁ ⟧ ++ ⟦ t₂ ⟧
⟦ mapᵣ f t ⟧   = map f ⟦ t ⟧
⟦ x ∷ᵣ t ⟧     = x ∷ ⟦ t ⟧
⟦ nilᵣ ⟧       = []

-- 「t 是不是空表表示」做成 Bool 判定（Stump 的 is-emptyr）。
-- 为什么不用模式匹配直接写 `lit l ++ᵣ nilᵣ` 收口？——正文 43.4：化简器
-- 子句一旦依赖「上一个模式没匹配上」这笔账，保语义证明里的 refl 就卡死
-- （与 43.3 格式化打印的死因是同一笔糊涂账）。
is-nil? : ∀ {A : Set} → Expr A → Bool
is-nil? nilᵣ       = true
is-nil? (lit l)    = false
is-nil? (_ ++ᵣ _)  = false
is-nil? (mapᵣ _ _) = false
is-nil? (_ ∷ᵣ _)   = false

is-nil?⇒nil : ∀ {A : Set} (t : Expr A) → is-nil? t ≡ true → t ≡ nilᵣ
is-nil?⇒nil nilᵣ       _       = refl
is-nil?⇒nil (lit l)    ()
is-nil?⇒nil (t₁ ++ᵣ t₂) ()
is-nil?⇒nil (mapᵣ f t) ()
is-nil?⇒nil (x ∷ᵣ t)   ()

-- 单步化简：重结合、提出 ∷、消灭 nil、分配 map、合并 map……
-- 本身不递归（一张规则表）。
simp-step : ∀ {A : Set} → Expr A → Expr A
simp-step ((t₁a ++ᵣ t₁b) ++ᵣ t₂) = t₁a ++ᵣ (t₁b ++ᵣ t₂)
simp-step ((x ∷ᵣ t₁) ++ᵣ t₂)     = x ∷ᵣ (t₁ ++ᵣ t₂)
simp-step (nilᵣ ++ᵣ t₂)          = t₂
simp-step (lit l ++ᵣ t₂)         = if is-nil? t₂ then lit l else lit l ++ᵣ t₂
simp-step (mapᵣ f t₁ ++ᵣ t₂)     = if is-nil? t₂ then mapᵣ f t₁ else mapᵣ f t₁ ++ᵣ t₂
simp-step (mapᵣ f (t₁ ++ᵣ t₂))   = mapᵣ f t₁ ++ᵣ mapᵣ f t₂
simp-step (mapᵣ f (lit l))       = lit (map f l)
simp-step (mapᵣ f (mapᵣ g t))    = mapᵣ (f ∘ g) t
simp-step (mapᵣ f (x ∷ᵣ t))      = f x ∷ᵣ mapᵣ f t
simp-step (mapᵣ f nilᵣ)          = nilᵣ
simp-step (lit l)                = lit l
simp-step (x ∷ᵣ t)               = x ∷ᵣ t
simp-step nilᵣ                   = nilᵣ

-- 超展开（superdevelopment）：先化简子表示，再对产物补一步
sdev : ∀ {A : Set} → Expr A → Expr A
sdev (lit l)     = lit l
sdev (t₁ ++ᵣ t₂) = simp-step (sdev t₁ ++ᵣ sdev t₂)
sdev (mapᵣ f t)  = simp-step (mapᵣ f (sdev t))
sdev (x ∷ᵣ t)    = simp-step (x ∷ᵣ sdev t)
sdev nilᵣ        = nilᵣ

-- 化简器本体：迭代 N 次超展开。终止检查不肯收「化到不动点」的写法
-- （Stump：让 Agda 相信化简终止花的功夫比化简本身大），
-- 于是把迭代次数交给用户——N 也是证据的一部分。
simpl : ∀ {A : Set} → ℕ → Expr A → Expr A
simpl zero    t = t
simpl (suc k) t = sdev (simpl k t)

-- 保语义（单步）：化简不动含义。每条规则后面站着一条引理。
simp-step-sound : ∀ {A : Set} (t : Expr A) → ⟦ t ⟧ ≡ ⟦ simp-step t ⟧
simp-step-sound ((t₁a ++ᵣ t₁b) ++ᵣ t₂) =
  ++-assoc ⟦ t₁a ⟧ ⟦ t₁b ⟧ ⟦ t₂ ⟧
simp-step-sound ((x ∷ᵣ t₁) ++ᵣ t₂)     = refl
simp-step-sound (nilᵣ ++ᵣ t₂)          = refl
simp-step-sound (lit l ++ᵣ nilᵣ)       = ++-identityʳ l
simp-step-sound (lit l ++ᵣ lit l₂)     = refl
simp-step-sound (lit l ++ᵣ (t₁ ++ᵣ t₂)) = refl
simp-step-sound (lit l ++ᵣ (mapᵣ f t)) = refl
simp-step-sound (lit l ++ᵣ (x ∷ᵣ t))   = refl
simp-step-sound (mapᵣ f t₁ ++ᵣ nilᵣ)   = ++-identityʳ (map f ⟦ t₁ ⟧)
simp-step-sound (mapᵣ f t₁ ++ᵣ lit l₂) = refl
simp-step-sound (mapᵣ f t₁ ++ᵣ (t₂ ++ᵣ t₃)) = refl
simp-step-sound (mapᵣ f t₁ ++ᵣ (mapᵣ g t)) = refl
simp-step-sound (mapᵣ f t₁ ++ᵣ (x ∷ᵣ t))   = refl
simp-step-sound (mapᵣ f (t₁ ++ᵣ t₂))   = map-++ f ⟦ t₁ ⟧ ⟦ t₂ ⟧
simp-step-sound (mapᵣ f (lit l))       = refl
simp-step-sound (mapᵣ f (mapᵣ g t))    = sym (map-∘ {g = f} {f = g} ⟦ t ⟧)
simp-step-sound (mapᵣ f (x ∷ᵣ t))      = refl
simp-step-sound (mapᵣ f nilᵣ)          = refl
simp-step-sound (lit l)                = refl
simp-step-sound (x ∷ᵣ t)               = refl
simp-step-sound nilᵣ                   = refl

sdev-sound : ∀ {A : Set} (t : Expr A) → ⟦ t ⟧ ≡ ⟦ sdev t ⟧
sdev-sound (lit l)     = refl
sdev-sound (t₁ ++ᵣ t₂) =
  trans (cong₂ _++_ (sdev-sound t₁) (sdev-sound t₂))
        (simp-step-sound (sdev t₁ ++ᵣ sdev t₂))
sdev-sound (mapᵣ f t)  =
  trans (cong (map f) (sdev-sound t))
        (simp-step-sound (mapᵣ f (sdev t)))
sdev-sound (x ∷ᵣ t)    =
  trans (cong (x ∷_) (sdev-sound t))
        (simp-step-sound (x ∷ᵣ sdev t))
sdev-sound nilᵣ        = refl

-- 主定理：simpl 保语义——这就是「反射」换来的可证性
simpl-sound : ∀ {A : Set} (t : Expr A) (n : ℕ) → ⟦ t ⟧ ≡ ⟦ simpl n t ⟧
simpl-sound t zero    = refl
simpl-sound t (suc n) =
  trans (simpl-sound t n) (sdev-sound (simpl n t))

-- 使用示范：Stump test2 的分配律，一行实例化换整个证明
module 分配律 {A : Set} (f : A → A) (l₁ l₂ l₃ : List A) where

  lhs : Expr A
  lhs = mapᵣ f ((lit l₁ ++ᵣ lit l₂) ++ᵣ lit l₃)

  -- 单步的样子（对照 Stump test2.one-step）
  一步 : simp-step lhs ≡ mapᵣ f (lit l₁ ++ᵣ lit l₂) ++ᵣ mapᵣ f (lit l₃)
  一步 = refl

  -- 三迭代落到不动点（次数不够会报 UnequalTerms，实测见正文）
  三次 : simpl 3 lhs ≡
         lit (map f l₁) ++ᵣ (lit (map f l₂) ++ᵣ lit (map f l₃))
  三次 = refl

  -- 重头戏：目标命题一行「算」出来
  分配 : map f ((l₁ ++ l₂) ++ l₃) ≡ map f l₁ ++ (map f l₂ ++ map f l₃)
  分配 = simpl-sound lhs 3

-- 同一手法再赚一条：map ∘ map 合并（对照 13 章手搓归纳的日子）
module 合并 {A : Set} (f g : A → A) (l : List A) where

  lhs₂ : Expr A
  lhs₂ = mapᵣ f (mapᵣ g (lit l))

  合并 : map f (map g l) ≡ map (f ∘ g) l
  合并 = simp-step-sound lhs₂

------------------------------------------------------------------------
-- 6. 与教程既有内容对照：Dec（15 章）、quote（23 章）、求解器（34 章）
------------------------------------------------------------------------

-- 15 章：Bool 判定 vs 命题证明。本章两处「反射」分工一致：
-- cover/simp-step 负责算（像 Dec 的 does 字段），⟦_⟧ᶠ/⟦_⟧ 加
-- soundness 引理负责讲理（像 proof 字段）。Dec 本身是带 η 的 record
-- （η 与 no-eta-equality 的实测差异见正文坑位）。
open import Relation.Nullary using (Dec; yes; no)

3≡3? : Dec (3 ≡ 3)
3≡3? = yes refl

-- 23 章的 quote：反射世界的「全语言版」数据类型 Term。
-- 区别：Term 的语义是整个 Agda，无法在 Agda 内理化；
-- Expr 是我们自选的小语言，才能把 ⟦_⟧ 与保语义都写成程序。
open import Reflection using (Term)
open import Reflection.AST.Show using (showTerm)

真项 : Term
真项 = quoteTerm ((1 ∷ []) ++ (2 ∷ []))

打印 : String
打印 = showTerm 真项

-- 34 章 ring solver：证明反射工业化的成品（目标形态必须是 ∀）
open import Data.Nat.Tactic.RingSolver using (solve-∀)

环-交换 : ∀ (x y : ℕ) → x + y ≡ y + x
环-交换 = solve-∀
