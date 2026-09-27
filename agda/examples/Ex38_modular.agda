-- Ex38_modular：instance 参数与模算术
-- 复刻 Maguire《Getting Started with Agda》第 5 章 Modular Arithmetic，
-- 但把书中自定义 prelude 全部换成 stdlib 3.0 的现成语法（≡-Reasoning、
-- Setoid、Data.Fin、Data.Nat.Properties 的代数引理）。
-- 所有 ⚠ 标注的报错均为 2.9.0 + stdlib 3.0 实测文案（复现探针已删）。
module Ex38_modular where

open import Agda.Primitive using (Level)
open import Level using (0ℓ)
open import Data.Bool using (Bool; true; false)
open import Data.Nat
  using (ℕ; zero; suc; _+_; _*_; _≤_; z≤n; s≤s; _%_; NonZero; nonZero)
open import Data.Nat.Properties
  using (+-assoc; +-comm; +-identityʳ; +-suc; *-comm; *-distribʳ-+; suc-injective)
open import Data.String using (String)
open import Relation.Binary using (Setoid; IsEquivalence)
open import Relation.Binary.Core using (Rel)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; trans; cong; module ≡-Reasoning)
import Relation.Binary.Reasoning.Setoid as SetoidReasoning

------------------------------------------------------------------------
-- 38.1  instance 参数与搜索算法
------------------------------------------------------------------------

-- default：把「想要什么类型」交给实例搜索去填。
-- 2.9.0 的 ⦃ ⦄ 只是旧 {{ }} 的 Unicode 皮，语义完全一致。
default : {ℓ : Level} {A : Set ℓ} → ⦃ a : A ⦄ → A
default ⦃ val ⦄ = val

-- instance 块：声明「哪些类型有现成的默认值」。放进独立模块，
-- 免得裸类型 ℕ 的实例泄漏到全局，与后面 OldSyntax 的 ℕ 实例抢目标。
module InstanceBasics where
  private instance
    default-ℕ : ℕ
    default-ℕ = 0
    default-Bool : Bool
    default-Bool = false

  -- 于是 default 会被自动填成对应类型的实例：
  _ : default ≡ 0
  _ = refl

  _ : default ≡ false
  _ = refl

  -- ⚠ 若填错值，报错（探针实测）：
  --   _ : default ≡ 1
  --   _ = refl
  -- → The terms 0 and 1 are not equal at type ℕ
  --   when checking that the expression refl has type default ≡ 1
  -- （2.8 的老文案是 `0 != 1 of type ℕ`，2.9 改成整句自然语言。）

-- 旧语法 {{ }} 在 2.9.0 仍然合法（放进独立模块，免得它的 ℕ 实例与
-- 上面的 default-ℕ 抢同一目标，触发多实例冲突）：
module OldSyntax where
  it-old : {ℓ : Level} {A : Set ℓ} → {{ a : A }} → A
  it-old {{ val }} = val

  private instance
    it-old-ℕ : ℕ
    it-old-ℕ = 5

  _ : it-old {A = ℕ} ≡ 5
  _ = refl

------------------------------------------------------------------------
-- 38.2  record 当「命名空间」：HasDefault 路线
------------------------------------------------------------------------

-- 把默认值装进参数化 record，避免把 0/false 直接灌进全局 instance 环境
-- （否则 10 ≤ 20 这类要「推导」的实例会和它们抢 default）。
record HasDefault (A : Set) : Set where
  constructor default-of
  field
    the-default : A

defaultʳ : {A : Set} → ⦃ HasDefault A ⦄ → A
defaultʳ ⦃ default-of val ⦄ = val

private instance
  _ = default-of 0
  _ = default-of false

_ : defaultʳ {A = ℕ} ≡ 0
_ = refl

-- open 记录 + ⦃ ... ⦄ 会自动生成了一个「查实例再取字段」的函数，
-- 等价于手写 defaultʳ，但不用自己写模式匹配。
open HasDefault ⦃ ... ⦄

_ : the-default {A = ℕ} ≡ 0
_ = refl

-- ⚠ 对没有实例的类型用 defaultʳ（探针实测）：
--   data Color : Set where red green blue : Color
--   _ : Color
--   _ = defaultʳ
-- → No instance of type HasDefault Color was found in scope.
--   when checking that the expression defaultʳ has type Color

------------------------------------------------------------------------
-- 38.3  手写 typeclass：Show + 泛型函数
------------------------------------------------------------------------

record Show (A : Set) : Set where
  field show : A → String

open Show ⦃ ... ⦄

instance
  showℕ : Show ℕ
  showℕ .Show.show zero    = "zero"
  showℕ .Show.show (suc _) = "suc _"

  showBool : Show Bool
  showBool .Show.show true  = "true"
  showBool .Show.show false = "false"

-- 泛型函数：签名里带 ⦃ Show A ⦄，调用时实例被自动补齐。
display : {A : Set} → ⦃ Show A ⦄ → A → String
display ⦃ s ⦄ a = Show.show s a

_ : String
_ = display 3        -- 自动挑 showℕ，无需手写 {⦃ showℕ ⦄}

_ : String
_ = display true     -- 自动挑 showBool

-- 手动传实例（把自动搜索关掉看看长什么样）：
_ : String
_ = display {A = ℕ} ⦃ showℕ ⦄ 7

-- 加一个「可折叠」的加法幺半群 record，示范实例上下文里的通用函数。
record AdditiveMonoid (A : Set) : Set where
  field
    _⊕_ : A → A → A
    ε   : A

open AdditiveMonoid ⦃ ... ⦄

instance
  ℕ-add : AdditiveMonoid ℕ
  ℕ-add = record { _⊕_ = _+_; ε = zero }

double : {A : Set} → ⦃ AdditiveMonoid A ⦄ → A → A
double a = a ⊕ a

_ : double 21 ≡ 42
_ = refl

-- ⚠ 同类型多实例冲突（探针实测）：若再声明一个
--   instance showℕ′ : Show ℕ ; showℕ′ .Show.show = λ _ → "two"
--   则 display 3 报：
-- → Failed to solve the following constraints:
--     Resolve instance argument _r_6 : Show ℕ
--     Candidates
--       showℕ₁ : Show ℕ
--       showℕ₂ : Show ℕ
--       (stuck)
--   光靠 OVERLAPPABLE/OVERLAPPING 消解不了「同型两实例」，只有 INCOHERENT 能压。

------------------------------------------------------------------------
-- 38.4  用实例搜索「自动」推 ≤
------------------------------------------------------------------------

-- 书中 find-z≤n / find-s≤n：把 ≤ 的两个构造子写成实例，
-- find-s≤n 又反过来请求实例搜索帮它找子证明，形成递归求解。
private instance
  find-z≤n : {n : ℕ} → zero ≤ n
  find-z≤n = z≤n

  find-s≤n : {m n : ℕ} → ⦃ m ≤ n ⦄ → suc m ≤ suc n
  find-s≤n ⦃ m≤n ⦄ = s≤s m≤n

_ : 10 ≤ 20
_ = default          -- default 只做一件事：把搜到的实例原样返回

------------------------------------------------------------------------
-- 38.5  ℤ/nℕ：商模型（record 携带见证元）
------------------------------------------------------------------------

module ℕ/nℕ (n : ℕ) where

  -- a ≈ b 当且仅当存在见证元 x y，使 a + x·n ≡ b + y·n。
  -- 这个 record 本身就是「∃ x y. …」的 Σ 型：模式匹配即抽取见证元。
  record _≈_ (a b : ℕ) : Set where
    constructor ≈-mod
    field
      x y : ℕ
      is-mod : a + x * n ≡ b + y * n
  infix 4 _≈_

  ≈-refl : ∀ {a} → a ≈ a
  ≈-refl = ≈-mod 0 0 refl

  ≈-sym : ∀ {a b} → a ≈ b → b ≈ a
  ≈-sym (≈-mod x y p) = ≈-mod y x (sym p)

  -- 「Deriving Transitivity」：两条形如 a+xn=b+yn、b+zn=c+wn 的等式，
  -- 要拼出 a+pn=c+qn，纸面解得 p=x+z、q=w+y。
  lemma₁ : (a x z : ℕ) → a + (x + z) * n ≡ (a + x * n) + z * n
  lemma₁ a x z = begin
    a + (x + z) * n  ≡⟨ cong (a +_) (*-distribʳ-+ n x z) ⟩
    a + (x * n + z * n) ≡⟨ sym (+-assoc a _ _) ⟩
    (a + x * n) + z * n ∎
    where open ≡-Reasoning

  lemma₂ : (i j k : ℕ) → (i + j) + k ≡ (i + k) + j
  lemma₂ i j k = begin
    (i + j) + k   ≡⟨ +-assoc i j k ⟩
    i + (j + k)   ≡⟨ cong (i +_) (+-comm j k) ⟩
    i + (k + j)   ≡⟨ sym (+-assoc i k j) ⟩
    (i + k) + j   ∎
    where open ≡-Reasoning

  -- 见证元 (x+z)、(w+y) 直接由 record 模式匹配从两条证明里「抠」出来。
  ≈-trans : ∀ {a b c} → a ≈ b → b ≈ c → a ≈ c
  ≈-trans {a} {b} {c} (≈-mod x y pxy) (≈-mod z w pzw) =
    ≈-mod (x + z) (w + y)
      (begin
        a + (x + z) * n          ≡⟨ lemma₁ a x z ⟩
        (a + x * n) + z * n      ≡⟨ cong (_+ z * n) pxy ⟩
        (b + y * n) + z * n      ≡⟨ lemma₂ b (y * n) (z * n) ⟩
        (b + z * n) + y * n      ≡⟨ cong (_+ y * n) pzw ⟩
        c + w * n + y * n        ≡⟨ sym (lemma₁ c w y) ⟩
        c + (w + y) * n          ∎)
      where open ≡-Reasoning

  ≈-isEq : IsEquivalence _≈_
  ≈-isEq = record
    { refl  = ≈-refl
    ; sym   = ≈-sym
    ; trans = ≈-trans
    }

  -- 把 _≈_ 打包成 Setoid，就能套用 stdlib 的 Setoid 推理链。
  mod-setoid : Setoid 0ℓ 0ℓ
  mod-setoid = record
    { Carrier       = ℕ
    ; _≈_           = _≈_
    ; isEquivalence = ≈-isEq
    }

  -- Mod-Reasoning 同时给出 _≈⟨_⟩_（模等式步）和 _≡⟨_⟩_/_≡⟨⟩_（命题等式步），
  -- 正好对应书中 Preorder-Reasoning 的混合链。
  module ModReasoning where
    open SetoidReasoning mod-setoid public

  open ModReasoning

  -- 0 ≈ n：取 x=1, y=0，则 0 + 1·n ≡ n + 0·n，两侧都化简到 n。
  0≈n : 0 ≈ n
  0≈n = ≈-mod 1 0 refl

  -- suc 保 ≈：注意 _≈_ 没有通用 cong，只能手抠见证元。
  suc-cong-mod : ∀ {a b} → a ≈ b → suc a ≈ suc b
  suc-cong-mod (≈-mod x y p) = ≈-mod x y (cong suc p)

  suc-injective-mod : ∀ {a b} → suc a ≈ suc b → a ≈ b
  suc-injective-mod (≈-mod x y p) = ≈-mod x y (suc-injective p)

  -- a ≈ 0 ⟹ a + b ≈ b（对 b 归纳，混合 ≡/≈ 链）
  +-zero-mod : (a b : ℕ) → a ≈ 0 → a + b ≈ b
  +-zero-mod a zero    a≈0 = begin
    a + zero  ≡⟨ +-identityʳ a ⟩
    a         ≈⟨ a≈0 ⟩
    zero      ∎
  +-zero-mod a (suc b) a≈0 = begin
    a + suc b      ≡⟨ +-suc a b ⟩
    suc a + b      ≡⟨⟩
    suc (a + b)    ≈⟨ suc-cong-mod (+-zero-mod a b a≈0) ⟩
    suc b          ∎

  -- + 保 ≈（对两边的零/suc 分情形）
  +-cong₂-mod : ∀ {a b c d} → a ≈ b → c ≈ d → a + c ≈ b + d
  +-cong₂-mod {zero} {b} {c} {d} pab pcd = begin
    c          ≈⟨ pcd ⟩
    d          ≈⟨ ≈-sym (+-zero-mod b d (≈-sym pab)) ⟩
    b + d      ∎
  +-cong₂-mod {suc a} {zero} {c} {d} pab pcd = begin
    suc a + c  ≈⟨ +-zero-mod (suc a) c pab ⟩
    c          ≈⟨ pcd ⟩
    d          ∎
  +-cong₂-mod {suc _} {suc _} {c} {d} pab pcd =
    suc-cong-mod (+-cong₂-mod (suc-injective-mod pab) pcd)

  -- · 保 ≈：先证 a·0 ≈ 0，再证 *-cong₂。
  *-zero-mod : (a b : ℕ) → b ≈ 0 → a * b ≈ 0
  *-zero-mod zero    b b≈0 = ≈-refl
  *-zero-mod (suc a) b b≈0 = begin
    suc a * b   ≡⟨⟩
    b + a * b   ≈⟨ +-cong₂-mod b≈0 (*-zero-mod a b b≈0) ⟩
    0           ∎

  *-cong₂-mod : ∀ {a b c d} → a ≈ b → c ≈ d → a * c ≈ b * d
  *-cong₂-mod {zero} {b} {c} {d} a≈b c≈d = begin
    zero * c   ≡⟨⟩
    zero       ≈⟨ ≈-sym (*-zero-mod d b (≈-sym a≈b)) ⟩
    d * b      ≡⟨ *-comm d b ⟩
    b * d      ∎
  *-cong₂-mod {suc a} {zero} {c} {d} a≈b c≈d = begin
    suc a * c  ≡⟨ *-comm (suc a) c ⟩
    c * suc a  ≈⟨ *-zero-mod c (suc a) a≈b ⟩
    zero       ≡⟨⟩
    zero * d   ∎
  *-cong₂-mod {suc a} {suc b} {c} {d} a≈b c≈d = begin
    suc a * c  ≡⟨⟩
    c + a * c  ≈⟨ +-cong₂-mod c≈d
                       (*-cong₂-mod (suc-injective-mod a≈b) c≈d) ⟩
    d + b * d  ≡⟨⟩
    suc b * d  ∎

------------------------------------------------------------------------
-- 38.6  ℤ/n 的 Fin 模型（计算友好，refl 直接算平）
------------------------------------------------------------------------

module ClockArithmetic where

  open import Data.Fin using (Fin; toℕ; fromℕ<; #_)
  open import Data.Nat.DivMod using (m%n<n)
  open import Data.Fin.Properties using (toℕ-fromℕ<)

  -- 模 n+1 的加法：先把 toℕ 相加取模，再用 fromℕ< 装回 Fin。
  -- _%_ 的 NonZero 参数由 stdlib 的 instance nonZero 自动补齐。
  +Mod : ∀ {n} → Fin (suc n) → Fin (suc n) → Fin (suc n)
  +Mod {n} i j =
    fromℕ< {m = (toℕ i + toℕ j) % (suc n)} (m%n<n (toℕ i + toℕ j) (suc n))

  ·Mod : ∀ {n} → Fin (suc n) → Fin (suc n) → Fin (suc n)
  ·Mod {n} i j =
    fromℕ< {m = (toℕ i * toℕ j) % (suc n)} (m%n<n (toℕ i * toℕ j) (suc n))

  toℕ-+Mod : ∀ {n} (i j : Fin (suc n)) →
             toℕ (+Mod {n} i j) ≡ (toℕ i + toℕ j) % (suc n)
  toℕ-+Mod {n} i j = toℕ-fromℕ< (m%n<n (toℕ i + toℕ j) (suc n))

  -- 12 小时制时钟。#_ 的界由期望类型决定，所以用具名载体算子。
  infixl 8 _⊕₁₂_ _⊗₁₂_
  _⊕₁₂_ : Fin 12 → Fin 12 → Fin 12
  _⊕₁₂_ = +Mod

  _⊗₁₂_ : Fin 12 → Fin 12 → Fin 12
  _⊗₁₂_ = ·Mod

  -- 「10 点过 3 小时是 1 点」，直接 refl 算平：
  10+3≡1 : # 10 ⊕₁₂ # 3 ≡ # 1
  10+3≡1 = refl

  7·7≡1 : # 7 ⊗₁₂ # 7 ≡ # 1
  7·7≡1 = refl

  -- 对照：stdlib 的 Fin._+_ 不做取模，而是把上界一起加——
  -- 10 +F 3 落在 Fin 22，根本不是时钟算术。
  open import Data.Fin using () renaming (_+_ to _+F_)

  ten : Fin 12
  ten = # 10

  three : Fin 12
  three = # 3

  越界 : Fin 22
  越界 = ten +F three

  越界-值 : toℕ 越界 ≡ 13
  越界-值 = refl

------------------------------------------------------------------------
-- 38.7  自动化：ring solver 两条路径
------------------------------------------------------------------------

module Automation where

  open import Data.Nat.Tactic.RingSolver using (solve-∀)

  -- 3.0 的 tactic 路线（对照 34 章）：目标摆出来，solve-∀ 一键收工。
  -- 坑：solve-∀ 只能当「裸右侧」用，左边不能带模式变量。
  gnarly : (a c n x z : ℕ) →
           a * c + (c * x + a * z + x * z * n) * n
           ≡ c * (a + x * n) + z * n * (a + x * n)
  gnarly = solve-∀

  -- 书中附录的旧式语法树路线：手动把两侧写成 :* :+ := 的词。
  open import Data.Nat.Solver
  open +-*-Solver

  gnarly′ : (a c n x z : ℕ) →
            a * c + (c * x + a * z + x * z * n) * n
            ≡ c * (a + x * n) + z * n * (a + x * n)
  gnarly′ = solve 5
    (λ a c n x z →
       a :* c :+ (c :* x :+ a :* z :+ x :* z :* n) :* n
       := c :* (a :+ x :* n) :+ z :* n :* (a :+ x :* n))
    refl

  -- 2.9 内置的 `instance refl : x ≡ x`：平凡等式可被实例搜索直接解决，
  -- 于是 it（把搜到的实例返回）也能一键收平凡等式。
  it : ∀ {a} {A : Set a} → ⦃ A ⦄ → A
  it ⦃ x ⦄ = x

  _ : 3 ≡ 3
  _ = it

------------------------------------------------------------------------
-- 38.8  IsEquivalence 的实例化重载（对照书中 refl/sym/trans 抢名字）
------------------------------------------------------------------------

module Overloaded-≈ where

  postulate
    _~_ : Rel ℕ 0ℓ
    isEq-~ : IsEquivalence _~_

  private instance
    ~-is-eq : IsEquivalence _~_
    ~-is-eq = isEq-~

  -- 书中办法：open IsEquivalence ⦃ ... ⦄ 把字段 refl/sym/trans 变成
  -- 「按实例自动重载」的顶层函数。但本文件顶层已 import 了 ≡ 的 refl/sym/trans，
  -- 二者会同名冲突（实测），所以这里改用限定访问 record 字段。
  -- 「字段即重载函数」的机制，已由 §38.3 的 open Show ⦃ ... ⦄ 与 §38.2 的
  -- open HasDefault ⦃ ... ⦄ 现场演示（show、the-default 都是自动重载出来的）。
  _ : 4 ~ 4
  _ = IsEquivalence.refl ~-is-eq     -- 由实例 ~-is-eq 提供的 refl

  _ : ∀ {x y} → x ~ y → y ~ x
  _ = IsEquivalence.sym ~-is-eq


------------------------------------------------------------------------
-- 38.9  构造子即实例：证明塔（需 --backtracking-instance-search）
------------------------------------------------------------------------

-- 下面这段复刻用户手册：data 的构造子标 instance 后，
-- it 能顺着 hereX/thereX 逐层回溯，把「1 是否在表里」搜出来。
-- 需要文件级 {-# OPTIONS --backtracking-instance-search #-}，
-- 这里以注释保留，避免给整个示例改编译选项（正文探针已实测可过）。
--
--   open import Data.List using (List; _∷_; [])
--   infix 4 _∈_
--   data _∈_ {A : Set} (x : A) : List A → Set where
--     instance
--       hereX  : ∀ {xs} → x ∈ x ∷ xs
--       thereX : ∀ {y xs} → ⦃ x ∈ xs ⦄ → x ∈ y ∷ xs
--
--   ex₁ : 1 ∈ 1 ∷ 2 ∷ 3 ∷ 4 ∷ []
--   ex₁ = it          -- 默认搜索会 (stuck)；开回溯后 it 直接解出
--
-- ⚠ 坑：忘了写 infix 4 _∈_，默认结合强度 20 比 _∷_(5) 更紧，
--   类型 List A → Set 会被解析成畸形应用，报
--   ShouldBeASort: List _A_ should be a sort。
