------------------------------------------------------------------------
-- 第 05 章示例：类型系统与宇宙
--
-- 宇宙阶梯 Set₀/Set₁/…/Setω、非累积性、Π 类型与依赖函数、
-- 宇宙多态（Level）、显式与隐式参数、Lift、以及「公理必须 postulate」。
--
-- 类型检查：cd agda && agda examples/Ex05_universes.agda
------------------------------------------------------------------------

module Ex05_universes where

open import Agda.Primitive using (Level; _⊔_; lsuc; lzero; Setω)
open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Nat using (ℕ; zero; suc; _+_)
open import Data.Product using (_×_; _,_)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Empty using (⊥; ⊥-elim)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Level using (Lift; lift; lower)

-- 让 Set a、Set ℓ 里的 a/ℓ 自动上升为隐式 Level 参数（需要 variable 块）
variable
  a b ℓ : Level

------------------------------------------------------------------------
-- 5.1 类型检查即证明：一句话回顾
-- 下面每个「定义」同时是一条逻辑定理：
------------------------------------------------------------------------

-- 假言三段论： (B ⇒ C) ⇒ (A ⇒ B) ⇒ (A ⇒ C)
trans′ : ∀ {A B C : Set} → (B → C) → (A → B) → A → C
trans′ g f x = g (f x)

-- A ⇒ A ∨ B（∨ 引入左规则）
or-intro₁ : ∀ {A B : Set} → A → A ⊎ B
or-intro₁ = inj₁

-- 反证的最小片段：⊥ 什么都没有，所以能变出任何命题（爆炸原理）
ex-falso : ∀ {A : Set} → ⊥ → A
ex-falso ()

------------------------------------------------------------------------
-- 5.2 宇宙阶梯：Set 的「类型」是谁
------------------------------------------------------------------------

-- Bool 是普通类型： inhabits Set（即 Set₀）
B₀ : Set
B₀ = Bool

-- 「所有类型的集合」住在上一层：Set 的类型是 Set₁
T₁ : Set₁
T₁ = Set

-- 阶梯一路向上：Set₁ : Set₂，下标记法 Set₀/Set₃ 都合法
T₂ : Set₂
T₂ = Set₁

T₃ : Set₄
T₃ = Set₃

B₀′ : Set₀
B₀′ = Bool

-- 「以类型为值的函数」——谓词的整体——落在 Set₁：
Predicate : Set₁
Predicate = ℕ → Set

-- 注意：宇宙不累积。Bool : Set₀ 但 Bool ∉ Set₂——
-- 若把上面 T₁ 换成
--   V : Set₂
--   V = Bool
-- 实测报错：
--   error: [UnequalSorts]
--   Set != Set₂
--   when checking that the expression Bool has type Set₂

------------------------------------------------------------------------
-- 5.3 Setω：所有 Set 之上的「排序」，不是普通宇宙
------------------------------------------------------------------------

-- Setω 必须显式导入（Agda.Primitive 导出；不带 IMPORT 直接写会 NotInScope）。
-- 用途一：声明「装得下大参数」的数据类型/族。
data Largeω : Setω where
  packω : Set → Largeω

-- 用途二：它自己的类型再往上——实测 Setω : Setω 报错：
--   error: [UnequalSorts]
--   Setω₁ != Setω
--   when checking that the expression Setω has type Setω
-- 而正确的写法是：
Sω₁ : Setω₁
Sω₁ = Setω

-- 同样实测被拒的还有 T : Setω; T = Set ——报错 Set₁ != Setω。
-- 结论：Setω 只是给 datatype 排序用的上界，不能拿来「容纳大值」。

------------------------------------------------------------------------
-- 5.4 Π 类型：参数类型依赖一个「值」
------------------------------------------------------------------------

-- 非依赖的函数类型只是 Π 的退化情形：
const₂ : ℕ → Bool → ℕ
const₂ n _ = n

-- 依赖：返回类型随参数的「值」变化。
-- if _ then _ else _ 在类型位置照样工作：
pick : (b : Bool) → if b then ℕ else Bool
pick true  = 3
pick false = true

-- 于是下面的调用各自只有唯一合理的返回值类型：
_ : pick true ≡ 3
_ = refl

_ : pick false ≡ true
_ = refl

-- 招牌预告（16 章主角）：向量的长度是类型的一部分。
-- Vec 是「从 ℕ 到类型」的函数（type family）：
infixr 5 _∷_
data Vec (A : Set) : ℕ → Set where
  []  : Vec A zero
  _∷_ : ∀ {n : ℕ} → A → Vec A n → Vec A (suc n)

-- 依赖消除的雏形：长度不够的向量根本造不出这种调用——
vhead : ∀ {A : Set} {n : ℕ} → Vec A (suc n) → A
vhead (x ∷ xs) = x

-- 字面量长度 2 让类型检查器自己算 out 的索引：
v2 : Vec ℕ 2
v2 = 1 ∷ 2 ∷ []

_ : vhead v2 ≡ 1
_ = refl

-- 如果写 vhead ([] ∷ []?)——空向量的 head？
-- 类型 Vec A zero 与 Vec A (suc n) 无法 unify，调用在「编译期」就被拒。
-- 这就是「程序即证明」：vhead 本身就是一条定理的证明。

-- 乘积上的隐式参数（09 章细讲 Σ/×）：
swap : ∀ {A B : Set} → A × B → B × A
swap (x , y) = (y , x)

_ : swap (1 , true) ≡ (true , 1)
_ = refl

------------------------------------------------------------------------
-- 5.5 多态与 Level：宇宙多态 = 对「层级」也参数化
------------------------------------------------------------------------

-- 普通多态（隐式类型参数，固定在最底层）：
id₀ : ∀ {A : Set} → A → A
id₀ x = x

-- 宇宙多态（Level 也当参数）：一个 id 通吃所有层。
id : ∀ {ℓ} {A : Set ℓ} → A → A
id x = x

-- 用 id 搬运「类型本身」——它活在 Set₁，得实例化 ℓ := lsuc lzero：
S₁ : Set₁
S₁ = id {A = Set₁} Set

-- 显式 vs 隐式：显式参数在调用处必给，隐式由类型反推：
idE : ∀ (A : Set) → A → A
idE A x = x

n₁ : ℕ
n₁ = idE ℕ 3

n₂ : ℕ
n₂ = id 3

n₃ : ℕ
n₃ = id {A = ℕ} 3      -- 需要时仍可显式实例化隐式参数

-- 隐式参数推理翻车现场（实测，写进注释）：
--   1) 隐式参数 A 不在（可见的）类型中出现，调用处无从反推：
--        f : ∀ {A : Set} → ℕ → ℕ
--        f n = n
--        y = f 3
--      --> error: [UnsolvedMetaVariables]
--          Unsolved metas at the following locations: ...:5.5-6
-- 2) 期望类型不唯一时，构造子「多选一」直接卡死：
--        open import Data.List using (List; [])
--        bad = id []
--      --> error: [UnsolvedConstraints]
--          Failed to solve the following constraints:
--            _15 := ambiguous constructor [] : _3 (blocked on _3)
-- 解法：调用处补 {A = …}，或给结果写类型标注。

------------------------------------------------------------------------
-- 5.6 Lift：把低层的类型搬进高层
------------------------------------------------------------------------

-- Set₀ 的东西塞不进 Set₁ 的「值位」？可以用 Lift 人为抬高一层：
Bigℕ : Set₁
Bigℕ = Lift (lsuc lzero) ℕ

bv : Bigℕ
bv = lift 3

_ : lower bv ≡ 3
_ = refl

-- 数据/函数的「层级记账」用 ⊔（取最大）：
data _×⊔_ (A : Set a) (B : Set b) : Set (a ⊔ b) where
  _,⊔_ : A → B → A ×⊔ B

fst⊔ : ∀ {A : Set a} {B : Set b} → A ×⊔ B → A
fst⊔ (x ,⊔ _) = x

p₁ : ℕ ×⊔ Bool
p₁ = 2 ,⊔ false

_ : fst⊔ p₁ ≡ 2
_ = refl

------------------------------------------------------------------------
-- 5.7 判定性内核：没有免费的排中律
------------------------------------------------------------------------

-- Agda 的内核是构造性的：排中律不是定理，想用就得 postulate（引入公理）。
-- 这里把「用了公理」和「纯构造推理」分得清清楚楚：

-- 构造可证的半边：A → ¬¬A 不需要任何公理：
¬¬-intro : ∀ {A : Set} → A → ((A → ⊥) → ⊥)
¬¬-intro a ¬a = ¬a a

-- ¬¬A → A 则等价于消耗排中律——下面把它作为公理显式引入：
postulate
  em : ∀ (A : Set) → A ⊎ (A → ⊥)

-- 排中律「当参数用」：构造部分只是普通的 ⊎ 模式匹配（06 章展开）
¬¬-elim : ∀ {A : Set} → (A ⊎ (A → ⊥)) → ((A → ⊥) → ⊥) → A
¬¬-elim (inj₁ p)  _  = p
¬¬-elim (inj₂ ¬p) nn = ⊥-elim (nn ¬p)

-- 真正「吃公理」的只有这一行：把 em 递进去
dn : ∀ {A : Set} → ((A → ⊥) → ⊥) → A
dn {A = A} nn = ¬¬-elim (em A) nn

-- 对照实验：agda --safe 本文件 →
--   error: [SafeFlagPostulate]
--   Cannot postulate em with safe flag
-- 即 --safe 模式下一切 postulate 被禁止，「证明里有没有借公理」
-- 是机器可检查的元性质，不靠自觉。
