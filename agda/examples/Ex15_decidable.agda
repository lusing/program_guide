------------------------------------------------------------------------
-- 第 15 章示例：可判定性质——Dec、判定族与命题证明的分野
--
-- Dec 的真实结构（2.3：record + yes/no 模式）、≟/≤?/<? 判定族、
-- Bool 版 _≡ᵇ_/<ᵇ_ 与 T? 桥、⌊⌋/True/False/toWitness 全家桶、
-- filter 依赖 Decidable 的实测、¬¬¬P→¬P 与稳定律、停机问题 postulate。
--
-- 类型检查：cd agda && agda examples/Ex15_decidable.agda
------------------------------------------------------------------------

module Ex15_decidable where

open import Data.Bool using (Bool; true; false; not; T; if_then_else_)
open import Data.Nat using (ℕ; zero; suc; _+_; _≤_; _<_; z≤n; s≤s; _≡ᵇ_; _≤ᵇ_)
open import Data.Nat.Properties
  using (_≟_; _≤?_; _<?_; 1+n≢0; ≮⇒≥; ≤∧≢⇒<)
open import Data.Empty using (⊥)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Unit using (⊤; tt)
open import Data.List using (List; []; _∷_)
open import Data.List.Base using (filter; filterᵇ)
open import Data.List.Relation.Unary.Any using (Any; here; there)
open import Data.List.Relation.Unary.All as All using (All)
open import Level using (Level)
open import Function.Base using (_∘_)
open import Relation.Nullary
  using (Dec; yes; no; _because_; Reflects; ofʸ; ofⁿ; of; invert; ¬_;
        decidable-stable; ¬-drop-Dec; T?; ⌊_⌋; isYes; True; False;
        toWitness; fromWitness; toWitnessFalse; ¬?; map′)
open import Relation.Binary.PropositionalEquality
  using (_≡_; _≢_; refl; sym; trans; cong)

------------------------------------------------------------------------
-- 15.1 手写第一个判定过程：yes 带证据，no 也带证据
------------------------------------------------------------------------

-- 概念上的 Dec 是「二选一、两边都带证明」的和类型（老式定义，仅作对照）：
data DecOld (P : Set) : Set where
  yesO : (p :   P) → DecOld P
  noO  : (p : ¬ P) → DecOld P

-- 2.3 实际的 Relation.Nullary.Dec 是 record（源码原文）：
--   record Dec (A : Set) : Set where
--     constructor _because_
--     field does  : Bool
--           proof : Reflects A does
--   pattern yes a = true  because ofʸ  a
--   pattern no ¬a = false because ofⁿ ¬a
-- 用法与和类型几乎一样，差别在布尔部分能脱离证明独立计算（15.4）。

isZero? : (n : ℕ) → Dec (n ≡ zero)
isZero? zero    = yes refl
isZero? (suc n) = no 1+n≢0     -- 1+n≢0 {n} : ¬ (suc n ≡ 0)，n 是隐式参数

-- 「判定跑得出结果」：does（旧名 ⌊_⌋）是可计算的 Bool
_ : ⌊ isZero? 0 ⌋ ≡ true
_ = refl

_ : ⌊ isZero? 3 ⌋ ≡ false
_ = refl

-- with 精化：分哪一支由计算决定，证据就地出现
zeroOrNot : (n : ℕ) → (n ≡ zero) ⊎ ¬ (n ≡ zero)
zeroOrNot n with isZero? n
... | yes p = inj₁ p
... | no ¬p = inj₂ ¬p

------------------------------------------------------------------------
-- 15.2 判定族：_≟_ _≤?_ _<?_——同一配方，三种命题
------------------------------------------------------------------------

-- Data.Nat.Properties 里的实现（三行照抄源码，注意 T? 与 map′）：
--   m ≟ n  = map′ (≡ᵇ⇒≡ m n) (≡⇒≡ᵇ m n) (T? (m ≡ᵇ n))
--   m ≤? n = map′ (≤ᵇ⇒≤ m n) ≤⇒≤ᵇ      (T? (m ≤ᵇ n))
--   m <? n = suc m ≤? n
-- 配方 = 内建 Bool 判定（快）+ T? 桥 + map′ 换命题。

_ : ⌊ 2 ≟ 3 ⌋ ≡ false
_ = refl

_ : ⌊ 2 ≟ 2 ⌋ ≡ true
_ = refl

_ : ⌊ 4 <? 3 ⌋ ≡ false
_ = refl

-- 具体不等式免手数 s≤s 塔（10 章坑位 8 的解药）：
lt35 : 3 < 5
lt35 = toWitness {a? = 3 <? 5} _

le55 : 5 ≤ 5
le55 = toWitness {a? = 5 ≤? 5} _

-- 三岐比较（stdlib 里这条叫 <-cmp，自己走一遍才算数）：
cmp : (m n : ℕ) → (m < n) ⊎ (m ≡ n) ⊎ (n < m)
cmp m n with m ≟ n | m <? n
... | yes p | _      = inj₂ (inj₁ p)
... | no ¬p | yes q  = inj₁ q
... | no ¬p | no ¬q  = inj₂ (inj₂ (≤∧≢⇒< (≮⇒≥ ¬q) (¬p ∘ sym)))

------------------------------------------------------------------------
-- 15.3 Reflects：yes/no 背后的反射关系
------------------------------------------------------------------------

-- Relation.Nullary.Reflects（源码注释原文：Reflects A b is equivalent
-- to `if b then A else ¬ A`）：
--   data Reflects (A : Set) : Bool → Set where
--     ofʸ : (  a : A) → Reflects A true
--     ofⁿ : (¬a : ¬ A) → Reflects A false

-- 反射 ↔ 命题的换算：
reflects-if : ∀ {a : Level} {P : Set a} {b : Bool} → Reflects P b → if b then P else ¬ P
reflects-if (ofʸ p)  = p
reflects-if (ofⁿ ¬p) = ¬p

-- of / invert 互逆（b 具体为 true 时两边都化简）：
invert-of : ∀ {P : Set} (p : P) → invert {b = true} (of p) ≡ p
invert-of p = refl

-- Dec 的 proof 字段就是一个 Reflects——用 _because_ 模式拆出来：
2≡2-reflects : Reflects (2 ≡ 2) true
2≡2-reflects = proof-of (2 ≟ 2)
  where
  proof-of : ∀ {P} (d : Dec P) → Reflects P ⌊ d ⌋
  proof-of (true  because q) = q
  proof-of (false because q) = q

------------------------------------------------------------------------
-- 15.4 Dec → Bool 与 Bool → Dec：两个方向不对称
------------------------------------------------------------------------

-- Dec → Bool：⌊_⌋（= isYes = does）剥掉证明只剩布尔，永远可计算。
-- 这正是 2.3 把 Dec 做成 record 的收益：判定时不算证明，要用才造。

-- Bool → Dec：一座桥 `T? : ∀ b → Dec (T b)`——布尔值 b 反射成命题
-- T b 的判定。一切「Bool 版判定升格为命题版判定」都从这里过。

-- 用 T 把 Bool 谓词写成命题再判定（Data.Nat.Base 的 NonZero 同法）：
nonZero? : (n : ℕ) → Dec (T (not (n ≡ᵇ zero)))
nonZero? n = T? (not (n ≡ᵇ zero))

_ : ⌊ nonZero? 0 ⌋ ≡ false
_ = refl

_ : ⌊ nonZero? 7 ⌋ ≡ true
_ = refl

-- True/False 包装（Relation.Nullary.Decidable.Core 原文）：
--   True  a? = T (isYes a?)     -- 判定为「是」时退化成 ⊤
--   False a? = T (isNo  a?)
-- 注意：这两个 True/False 是 **Dec A → Set** 的包装型，
-- 不是 Agda 早期内置 Reflection 里那两个同名类型（15 章文档有实测）。
_ : True (3 <? 5)
_ = tt

_ : False (5 <? 3)
_ = tt

-- witness 家族：把包装拆成证明 / 把证明装回包装
lt35′ : 3 < 5
lt35′ = toWitness {a? = 3 <? 5} tt

¬lt53 : ¬ (5 < 3)
¬lt53 = toWitnessFalse {a? = 5 <? 3} tt

_ : True (3 <? 5)
_ = fromWitness {a? = 3 <? 5} lt35′

------------------------------------------------------------------------
-- 15.5 实测：Data.List.filter 要的是 Decidable，不是 Bool
-- （08 章的伏笔在这里回收）
------------------------------------------------------------------------

-- Data.List.Base 源码原文：
--   filter  : ∀ {P : Pred A p} → Decidable P → List A → List A
--   filterᵇ : (A → Bool) → List A → List A
--   filterᵇ p = filter (T? ∘ p)
--   （实现内部 with does (P? x)——计算只用布尔部分！）
-- Decidable P（Relation.Unary）= ∀ x → Dec (P x)。
-- 所以「Bool 版 filter」其实是命题版的特例，靠 T? 升格。

ns : List ℕ
ns = 5 ∷ 20 ∷ 8 ∷ 42 ∷ []

evens′ : List ℕ
evens′ = filterᵇ (λ n → n ≤ᵇ 10) ns          -- Bool 谓词版

big : List ℕ
big = filter (λ n → suc 10 ≤? n) ns          -- 命题谓词（_≤_）版

_ : evens′ ≡ 5 ∷ 8 ∷ []
_ = refl

_ : big ≡ 20 ∷ 42 ∷ []
_ = refl

------------------------------------------------------------------------
-- 15.6 自己造判定：Any（存在）与 All（全称）在列表上都可判定
------------------------------------------------------------------------

any? : ∀ {A : Set} (P : A → Set) → (∀ x → Dec (P x)) →
       (xs : List A) → Dec (Any P xs)
any? P P? []       = no λ ()
any? P P? (x ∷ xs) with P? x | any? P P? xs
... | yes p  | _        = yes (here p)
... | no  ¬p | yes q    = yes (there q)
... | no  ¬p | no  ¬q   = no λ { (here p) → ¬p p ; (there q) → ¬q q }

-- 「x 是否在表里」即刻可判定——26 章去重/排序的成员检查原型；
-- 它同时给「在」的证据与「不在」的反证，Bool 版判不出这些。
in? : (x : ℕ) (xs : List ℕ) → Dec (Any (_≡ x) xs)
in? x = any? (_≡ x) (λ y → y ≟ x)

_ : ⌊ in? 8 ns ⌋ ≡ true
_ = refl

_ : ⌊ in? 9 ns ⌋ ≡ false
_ = refl

all? : ∀ {A : Set} (P : A → Set) → (∀ x → Dec (P x)) →
       (xs : List A) → Dec (All P xs)
all? P P? []       = yes All.[]
all? P P? (x ∷ xs) with P? x | all? P P? xs
... | yes p  | yes q      = yes (p All.∷ q)
... | no  ¬p | _          = no λ { (p All.∷ _) → ¬p p }
... | yes _  | no  ¬q     = no λ { (_ All.∷ q) → ¬q q }

-- 「有界穷举」感性的可判定性演示：7 不等于 2..6 中任何一个数。
-- 素性检测（∀ 有界 d. ¬ d ∣ n）就是 all? × _∣?_（Data.Nat.Divisibility）
-- 的组合——∀ 限定在有限表上才可判定，这就是「有界」二字的分量。
noIs7 : All (λ d → ¬ (suc d ≡ 7)) (1 ∷ 2 ∷ 3 ∷ 4 ∷ 5 ∷ [])
noIs7 = toWitness {a? = all? (λ d → ¬ (suc d ≡ 7))
                             (λ d → ¬? (suc d ≟ 7))
                             (1 ∷ 2 ∷ 3 ∷ 4 ∷ 5 ∷ [])}
            tt

_ : ⌊ all? (λ d → ¬ (suc d ≡ 7)) (λ d → ¬? (suc d ≟ 7))
         (1 ∷ 2 ∷ 3 ∷ 4 ∷ 5 ∷ []) ⌋ ≡ true
_ = refl

------------------------------------------------------------------------
-- 15.7 ¬¬¬P → ¬P、稳定律：Dec 是构造性的「排中」
------------------------------------------------------------------------

-- 三重否定化简——直觉主义定理，不需要任何判定
-- （stdlib 里它的名字叫 negated-stable，Relation.Nullary.Negation.Core：
--   Stable (¬ A)，即 ¬ ¬ ¬ A → ¬ A。）
tripleNeg-elim : ∀ {A : Set} → ¬ ¬ ¬ A → ¬ A
tripleNeg-elim h a = h (λ na → na a)

-- 但对可判定命题，两重否定即可消（排中律只在 Dec 世界里成立）：
stable35 : ¬ ¬ (3 < 5) → 3 < 5
stable35 = decidable-stable (3 <? 5)

-- 配套工具 ¬-drop-Dec : Dec (¬ ¬ A) → Dec (¬ A)——
-- 拿到「¬¬A 可判定」就免费得到「¬A 可判定」：
¬3≡4 : 3 ≢ 4
¬3≡4 = toWitness {a? = ¬-drop-Dec (¬? (¬? (3 ≟ 4)))} _

------------------------------------------------------------------------
-- 15.8 不可判定性预告：停机问题只能 postulate
------------------------------------------------------------------------

-- 「可判定」不是免费的。把「机器 n 在输入 n 上停机」记作命题
-- Halts n，则图灵说：不存在 ∀ n → Dec (Halts n)。
-- 这句定理 Agda 内部证不出来（它谈的是所有程序），只能 postulate；
-- 而 postulate 在 --safe 下直接编译失败（SafeFlagPostulate，07 章实测）。
-- 本文件不是 --safe 文件，postulate 在此是「诚实的假设」。

postulate
  Halts : ℕ → Set                       -- 外部的停机命题（仅作逻辑占位）
  noDecider : ¬ (∀ n → Dec (Halts n))   -- 图灵定理（此处为公设）

-- 用它推倒「全量排中律」：若一切命题可判定，停机问题就有判定器：
LEM-false : (lem : ∀ (A : Set) → Dec A) → ⊥
LEM-false lem = noDecider (λ n → lem (Halts n))

-- 结论：Agda 能判定的只是**具体的**类型族（ℕ、Bool、List、Vec……），
-- 「一切命题都可判定」在系统内不成立——本章判定性与 12 章证明的
-- 分野，到此合拢。
