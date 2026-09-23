------------------------------------------------------------------------
-- 第 06 章示例：数据类型与模式匹配
--
-- data 声明解剖、参数 vs 索引、模式家族（构造子/通配符/变量/荒谬/点模式）、
-- 重叠分支按序匹配、with 抽象、字面量模式与 suc 展开。
--
-- 类型检查：cd agda && agda examples/Ex06_patterns.agda
------------------------------------------------------------------------

module Ex06_patterns where

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Data.Bool using (Bool; true; false)
open import Data.Empty using (⊥; ⊥-elim)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

------------------------------------------------------------------------
-- 6.1 data 声明解剖：参数与索引
------------------------------------------------------------------------

-- 最简单的「枚举」：类型名、冒号、它的宇宙、where、构造子列表。
data Ordering : Set where
  lt eq gt : Ordering

-- 参数（parameter）：出现在「数据名」的应用中、每个构造子都一样——
-- 这里 A 是参数，Option 对「装什么」多态。
data Option (A : Set) : Set where
  some : A → Option A
  none : Option A

-- 索引（index）：构造子结果类型里数据名的「参数位置」会变——
-- Mixed 按 (n : ℕ, b : Bool) 两路索引细分成一族类型：
--   Mixed zero true  有 here；Mixed (suc n) false 有 there；
--   其余组合（如 Mixed zero false）是空类型。
data Mixed : ℕ → Bool → Set where
  here  : Mixed zero true
  there : ∀ {n : ℕ} → Mixed (suc n) false

-- 区分口诀：在「所有构造子」的返回类型里位置固定的是参数，
-- 会变形（zero / suc n / true / false）的是索引。
-- 索引会变的字段自动成为构造子的隐式参数：there {n} 的 n 不用传。

------------------------------------------------------------------------
-- 6.2 模式家族
------------------------------------------------------------------------

-- (a) 具体构造子模式 + (b) 变量模式 + (c) 通配符 _
flipO : Ordering → Ordering
flipO lt = gt
flipO eq = eq
flipO gt = lt

fromSome : Option ℕ → ℕ
fromSome (some n) = n
fromSome none     = 0

-- 通配符匹配一切但不绑定；多个 _ 互不相同。
const₀ : ℕ → Ordering → ℕ
const₀ x _ = x

_ : const₀ 7 gt ≡ 7
_ = refl

-- 变量模式：绑定到匹配上的值本身
idPat : ℕ → ℕ
idPat n = n

-- 嵌套模式：一层套一层，最深可到字面量形状的 suc 链
second : ℕ → Bool
second zero        = false
second (suc zero)  = false
second (suc (suc n)) = true

_ : second 0 ≡ false
_ = refl
_ : second 1 ≡ false
_ = refl
_ : second 5 ≡ true
_ = refl

------------------------------------------------------------------------
-- 6.3 荒谬模式：() ——「这一分支不可能发生」
------------------------------------------------------------------------

-- 情形一：类型根本没有构造子（空类型 ⊥，逻辑上的「假」）。
from⊥ : ⊥ → ℕ
from⊥ ()

--  Curry–Howard：⊥ → ℕ 是「假蕴含一切」（爆炸原理），
--  而 () 声明「此位置无可匹配的值」，分支自动消失，证明完成。

-- 情形二：索引不相容，分支自己消失。Mixed 只有「(zero,true)」「(suc n,false)」
-- 两种居民，probe 的另外两个组合写 () 即可——检查器自己验证「真的没有构造子」：
probe : (n : ℕ) (b : Bool) → Mixed n b → Bool
probe zero    true  here  = true
probe zero    false ()
probe (suc n) true  ()
probe (suc n) false there = false

_ : probe 0 true here ≡ true
_ = refl
_ : probe 3 false there ≡ false
_ = refl

-- 单独声明一个 Bool 索引族，把「分支消失」看得更细：
data IsTrue : Bool → Set where
  it : IsTrue true

needTrue : (b : Bool) → IsTrue b → ℕ
needTrue true  it = 1
needTrue false ()        -- IsTrue false 无构造子：分支不存在

-- 如果偏要写一个不可能的正常模式（实测报错，值得背下来）：
--   needTrue false it = 1
-- --> error: [ImpossibleConstructor.UnifyConflict]
--     The case for the constructor it is impossible
--     because unification ended with a conflicting equation
--       true ≟ false
--     Possible solution: remove the clause, or use an absurd pattern ().
-- 报错直接教你改成 ()。

-- 提醒：「索引不相容」必须是检查器**算得出来**的不相容
-- （构造子冲突、或规约后可判）。像 suc n ≟ zero 这种它秒懂；
-- 依赖算术等式（如 n + m ≡ 0 ⇒ n ≡ 0）就不显然了——10 章 Fin 实战见分晓。

------------------------------------------------------------------------
-- 6.4 点模式 .pat：被等式钉死的变量
------------------------------------------------------------------------

-- 现象一：同一变量写两遍、而两者其实各自自由（非线性模式）报错：
--   j : ℕ → ℕ → ℕ
--   j n n = n
-- --> error: [UnequalTerms]
--     n != n₁ of type ℕ
--     when checking that all occurrences of pattern variable n have the
--     same value
-- 要点：Agda 的点模式 .pat 不是「等式约束」，而是「断言这一位的值
-- 已被同一条目里别的模式算出」。两个互相独立的输入没有这种等式，
-- 想在函数里「分相等情况」得靠判定函数（6.6 的 _≟ℕ_），不是模式。

-- 现象二：值确实被钉住时，打点（或用同一变量、由 Agda 自动补点）。
-- Pair2 的构造子 pr 把两个索引焊死成同一个 b：
data Pair2 : Bool → Bool → Set where
  pr : (b : Bool) → Pair2 b b

e : (x y : Bool) → Pair2 x y → Bool
e .b .b (pr b) = b     -- pr b : Pair2 b b 同时钉住 x 和 y，两处都是「推论」

_ : e true true (pr true) ≡ true
_ = refl
-- （写 e b b (pr b) = b 也通过——第 2、3 位的 b 会被自动打点。）

-- 现象三：带显式字段的索引构造子——字段决定索引时，
-- 索引位写具体模式若与已钉死的值冲突会报错（同 6.3 的 UnifyConflict），
-- 一致时 Agda 允许；打 .值 则显式声明「这是等式的推论」。
data Box : ℕ → Set where
  bx : (n : ℕ) → Box n

copy : (n : ℕ) → Box n → ℕ
copy n (bx .n) = n     -- 内层 .n：显式复用到外层 n

box3 : Box 3
box3 = bx 3

_ : copy 3 box3 ≡ 3
_ = refl

------------------------------------------------------------------------
-- 6.5 重叠分支：按书写顺序，第一条能匹配的赢
------------------------------------------------------------------------

-- 1 被 (suc n) 「抢先」覆盖——顺序决定语义：
firstWins : ℕ → Bool
firstWins (suc n) = false
firstWins zero    = true

-- 把更具体的分支往前挪，结果就不同：
specificFirst : ℕ → Bool
specificFirst 1       = true
specificFirst (suc n) = false
specificFirst zero    = true

_ : firstWins 1 ≡ false
_ = refl
_ : specificFirst 1 ≡ true
_ = refl
_ : firstWins 0 ≡ true
_ = refl
_ : specificFirst 0 ≡ true
_ = refl

-- 如果 firstWins 后面再多写一条被完全覆盖的分支（实测）：
--   g : ℕ → Bool
--   g (suc n) = false
--   g 1 = true
--   g zero = true
-- --> warning: -W[no]UnreachableClauses
--     Unreachable clause
--     when checking the definition of g
-- （只警告不报错，退出码仍是 0——但别把「没报错」当「没白写」。）
-- 兜底分支的正确姿势是通配符放最后：
catchAll : ℕ → Bool
catchAll zero    = false
catchAll (suc n) = true

------------------------------------------------------------------------
-- 6.6 with 抽象：对「中间计算结果」再分情况
------------------------------------------------------------------------

-- 自然数相等判定：递归结果本身还要 case，就得 with。
infix 4 _≟ℕ_
_≟ℕ_ : (m n : ℕ) → Bool
zero   ≟ℕ zero    = true
zero   ≟ℕ suc n   = false
suc m  ≟ℕ zero    = false
suc m  ≟ℕ suc n   with m ≟ℕ n
... | true  = true
... | false = false

_ : (2 ≟ℕ 2) ≡ true
_ = refl
_ : (2 ≟ℕ 5) ≡ false
_ = refl

-- `...` 表示「沿用上一行等号左边整串模式」；也可以重写完整左部。
-- with 可以一次抽象多个值，用 | 分隔：
_andB_ : (x y : Bool) → Bool
x andB y with x | y
... | true  | b = b
... | false | _ = false

_ : (true andB false) ≡ false
_ = refl

-- with 的杀手锏——精化（refinement）：抽象出的值携带等式信息，
-- 反过来钉住原参数（配合索引族看）：
witness : (b : Bool) → IsTrue b → ℕ
witness b t with t
witness .true it | it = 1
-- 上一行也可写 witness b t | it = 1——Agda 对「被 forced 的变量」
-- 会自动打点；显式 .true/it 是把等式写出来给人看。

-- 预告：15 章的 Dec/Σ 组合拳让「with 一个判定 + 按 true/false 精化」
-- 成为 Agda 证明工作流的日常主食。

------------------------------------------------------------------------
-- 6.7 字面量模式：数字是 suc 链的糖
------------------------------------------------------------------------

-- 模式里可以直接写数字字面量：0 → zero，2 → suc (suc zero)。
f : ℕ → ℕ
f 0       = 1
f 2       = 3
f (suc n) = n

_ : f 0 ≡ 1
_ = refl
_ : f 2 ≡ 3        -- 字面量分支在 (suc n) 之前，先匹配先得
_ = refl
_ : f 5 ≡ 4
_ = refl

-- 等价写法（完全展开成构造子）：
f′ : ℕ → ℕ
f′ zero              = 1
f′ (suc (suc zero))  = 3
f′ (suc n)           = n

_ : f 5 ≡ f′ 5
_ = refl

-- 数字模式只是「该类型恰好有 ℕ 的构造子形状」才可用——
-- 换掉类型（即便注册过字面量实例，见 03 章）照样炸（实测）：
--   data Parity : Set where
--     even odd : Parity
--   h : Parity → ℕ
--   h 7 = 0
-- --> error: [ConstructorPatternInWrongDatatype]
--     ℕ.suc is not a constructor of the datatype Parity
--     when checking that the pattern 7 has type Parity
-- 报错文案 ℕ.suc 泄露了天机：字面量模式 = suc 链模式。

------------------------------------------------------------------------
-- 6.8 组合练习：混合 Bool/ℕ 索引的「符号检查」小函数
------------------------------------------------------------------------

-- signMixed：给 Mixed 的四种索引组合各回一个标记；
-- 空组合仍由荒谬模式零成本处理——索引即文档、索引即证明。
signMixed : (n : ℕ) (b : Bool) → Mixed n b → ℕ
signMixed zero    true  here          = 0
signMixed (suc n) false (there {n})   = 1
signMixed zero    false ()
signMixed (suc n) true  ()

_ : signMixed 0 true here ≡ 0
_ = refl
