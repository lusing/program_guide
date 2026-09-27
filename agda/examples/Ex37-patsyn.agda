-- 第 37 章 · pattern 同义词与差分整数
-- 主题：monus 的代数坑；整数建模的三次弯路；差分整数 (a ⊖ b) 的记录式定义与
--       约分（规范化）；唯一表示与荒谬模式/dot pattern；pattern 同义词的
--       语法与「规范形别名」手法；差分整数加法的良定义性（先约后加 = 先加后约）；
--       与 stdlib Data.Integer（3.0）的对照。
-- 所有代码在 Agda 2.9.0 + stdlib 3.0 下真实类型检查通过。
-- 取材：Sandy Maguire《Certainty by Construction》第 2 章
--       （2.10 Semi-subtraction / 2.11 Inconvenient Integers / 2.12 Difference
--        Integers / 2.13 Unique Integer Representations / 2.14 Pattern Synonyms /
--        2.15 Integer Addition）与第 4 章「Overconstrained by Dot Patterns」节。

module Ex37-patsyn where

open import Data.Nat using (ℕ; zero; suc; _∸_)
          renaming (_+_ to _+ℕ_; _*_ to _*ℕ_)
open import Data.Nat.Properties using (+-suc)
open import Data.Bool using (Bool; true; false)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; sym; cong; trans; _≢_; module ≡-Reasoning)
open ≡-Reasoning
open import Relation.Nullary using (¬_)

------------------------------------------------------------------------
-- 1. 自然数减法的坑：monus（截断减法）的代数不漂亮
------------------------------------------------------------------------

-- stdlib 的 _∸_（monus，\.-）：x ∸ zero = x；zero ∸ suc y = zero；
-- suc x ∸ suc y = x ∸ y。结果永远截到 0，负数无处可去。
-- 于是「减法该满足的方程」一条都撑不住：

-- (2 ∸ 3) 先归零，加回来的 3 补不回 2：消去律 (m ∸ n) + n ≡ m 失效。
∸-cancel-fail : (2 ∸ 3) +ℕ 3 ≡ 3
∸-cancel-fail = refl

-- 结合律？两种括号给出两种答案：
∸-assoc-fail₁ : (3 ∸ 2) ∸ 5 ≡ 0
∸-assoc-fail₁ = refl
∸-assoc-fail₂ : 3 ∸ (2 ∸ 5) ≡ 3
∸-assoc-fail₂ = refl

-- 左单位元压根不存在：没有任何 e 能让 e ∸ n ≡ n 对一切 n 成立。
-- （拿 0 试：0 ∸ 1 = 0 ≠ 1；拿任何正数试：e ∸ 0 = e ≠ 0。）
-- 下面用「奇偶判别器」把它证死：假设 h : ∀ n → e ∸ n ≡ n，
-- e = 0 时对 n = 1 导出 true ≡ false；e = suc k 时对 n = 0 导出 true ≡ false。
isZero? : ℕ → Bool
isZero? zero        = true
isZero? (suc n)     = false

-- 荒谬模式的第一次出手：true ≡ false 无构造子可造，零条子句即可。
true≢false : ¬ (true ≡ false)
true≢false ()

∸-no-left-unit : (e : ℕ) → ¬ ((n : ℕ) → e ∸ n ≡ n)
∸-no-left-unit zero h = true≢false (cong isZero? (h 1))
∸-no-left-unit (suc e) h = true≢false (sym (cong isZero? (h 0)))

-- 对比 _+_（13 章）：零是双侧单位元，群结构完好；(ℕ, ∸) 什么都不是。
-- 出路：给负结果一个家——把「差」直接做成数据。先走三条弯路。

------------------------------------------------------------------------
-- 2. 弯路一：给 ℕ 加一个 pred 构造子（Maguire 2.11）
------------------------------------------------------------------------

-- 照着 ℕ = zero | suc 的样，加一枚「往回数一个」的 pred。
-- 书里构造子就叫 zero/suc/pred；这里为避免与 ℕ 的零散名撞车，加下标 ₁。
data ℤ₁ : Set where
  zero₁ : ℤ₁
  suc₁  : ℤ₁ → ℤ₁
  pred₁ : ℤ₁ → ℤ₁

-- 病根：0 有无穷多种写法——zero₁、pred₁ (suc₁ zero₁)、
-- suc₁ (pred₁ zero₁)、pred₁ (suc₁ (pred₁ (suc₁ zero₁)))……
-- 想做的是写一个 normalize 把 suc/pred 对消。Maguire 给出了一个
-- 「诚实的尝试」（逐字搬来）：
normalize₁ : ℤ₁ → ℤ₁
normalize₁ zero₁                  = zero₁
normalize₁ (suc₁ zero₁)           = suc₁ zero₁
normalize₁ (suc₁ (suc₁ x))        = suc₁ (normalize₁ (suc₁ x))
normalize₁ (suc₁ (pred₁ x))       = normalize₁ x
normalize₁ (pred₁ zero₁)          = pred₁ zero₁
normalize₁ (pred₁ (suc₁ x))       = normalize₁ x
normalize₁ (pred₁ (pred₁ x))      = pred₁ (normalize₁ (pred₁ x))

-- 它对了吗？书里的反例（refl 直接验算）：
norm₁-counterexample :
  normalize₁ (suc₁ (suc₁ (pred₁ (pred₁ zero₁)))) ≡ suc₁ (pred₁ zero₁)
norm₁-counterexample = refl

-- normalize₁ 交回了一个**自己还没被算到底**的结果：再约一轮还能约！
norm₁-not-fixpoint :
  normalize₁ (normalize₁ (suc₁ (suc₁ (pred₁ (pred₁ zero₁))))) ≡ zero₁
norm₁-not-fixpoint = refl

-- 病理解剖：suc 与 pred 可以任意交错，消对时不知道「该先配哪一对」。
-- 只要正负计数被压进同一条构造链，规范化就说不清自己「约到不动点」。

------------------------------------------------------------------------
-- 3. 差分整数：记录式 (a ⊖ b)（Maguire 2.12）
------------------------------------------------------------------------

-- 正负计数分开记账：一个数 = (多出来的正, 多出来的负)。
record ℤdiff : Set where
  constructor mkℤdiff
  field
    pos : ℕ
    neg : ℕ

-- 书写手感靠 pattern 同义词找回（第 5 节正式展开，先给结论）：
-- 「p ⊖ q」读作「p 个正方块减去 q 个负方块」。
pattern _⊖_ p q = mkℤdiff p q
infixl 6 _⊖_

-- 约分 = 两边同时摘掉一个 suc，摘到任何一侧见底为止。
-- 注意它与 2.12 的 normalize₁ 的本质区别：这里每一步都成对消去，
-- 且「先约哪一侧」根本不产生歧义——pos/neg 各管各的。
normalize : ℤdiff → ℤdiff
normalize (zero ⊖ q)      = zero ⊖ q
normalize (suc p ⊖ zero)  = suc p ⊖ zero
normalize (suc p ⊖ suc q) = normalize (p ⊖ q)

-- 「同一个整数」的等价类直觉：(a ⊖ b) 与 (a′ ⊖ b′) 表示同一整数，
-- 当且仅当交叉相加相等 a +ℕ b′ ≡ a′ +ℕ b（即 a − b = a′ − b′ 的移项版）。
-- 同一个 0 的无穷多种记账：
0⊖0-many : (0 ⊖ 0) ≡ normalize (5 ⊖ 5)
0⊖0-many = refl

-- 但注意：不同记账是**不同的值**，命题等式里它们不相等（cong 摘出 pos 即可证）。
posOf : ℤdiff → ℕ
posOf (p ⊖ q) = p

1≢0 : ¬ (1 ≡ 0)
1≢0 q = true≢false (sym (cong isZero? q))

1⊖1≢0⊖0 : 1 ⊖ 1 ≢ 0 ⊖ 0
1⊖1≢0⊖0 p = 1≢0 (cong posOf p)

-- Maguire 2.12 的三枚运算：先在两条道上各自相加，再总约分。
-- ⊞ 是「不约分」的原料；加减乘一律以 normalize 收尾。
_⊞_ : ℤdiff → ℤdiff → ℤdiff
(a ⊖ b) ⊞ (c ⊖ d) = (a +ℕ c) ⊖ (b +ℕ d)

_+_ : ℤdiff → ℤdiff → ℤdiff
x + y = normalize (x ⊞ y)
infixl 6 _+_

_-_ : ℤdiff → ℤdiff → ℤdiff
(a ⊖ b) - (c ⊖ d) = normalize ((a +ℕ d) ⊖ (b +ℕ c))
infixl 6 _-_

_*_ : ℤdiff → ℤdiff → ℤdiff
(a ⊖ b) * (c ⊖ d) =
  normalize ((a *ℕ c +ℕ b *ℕ d) ⊖ (a *ℕ d +ℕ b *ℕ c))
infixl 7 _*_

-- Maguire 式单元测试：refl 即断言，规范化即执行。
test₀ : (1 ⊖ 3) + (2 ⊖ 0) ≡ 0 ⊖ 0
test₀ = refl                              -- 1−3+2 = 0

test₁ : (3 ⊖ 1) - (1 ⊖ 4) ≡ 5 ⊖ 0
test₁ = refl                              -- 2 − (−3) = 5

test₂ : (3 ⊖ 1) * (0 ⊖ 2) ≡ 0 ⊖ 4
test₂ = refl                              -- 2 × (−2) = −4

-- Maguire 的抱怨（2.12 末）：每条运算末尾都拖着一次 normalize，
-- 像根「计算拐杖」——它算什么很明白，但它**在问题域里 meaning 什么**？
-- 而且证明里处处要带着它。出路：让表示本身唯一，拐杖就断了。
-- 这正是 37.4 的事；37.6 则先把 normalize 的「约分次序无关性」证掉。

------------------------------------------------------------------------
-- 4. 唯一表示：两块零、一枚修直、以及荒谬/dot 模式（Maguire 2.13）
------------------------------------------------------------------------

-- 弯路三：给 ℕ 贴正负标签。书里构造子叫 +_/_-_；下标 ₃ 防撞车。
data ℤ₃ : Set where
  +₃_ : ℕ → ℤ₃
  -₃_ : ℕ → ℤ₃

-- 语法上很香，但 0 还是两副面孔：+₃ zero 与 -₃ zero。
-- 要命的是它们**算不相等**（判别器一秒证伪）：
isPos₃ : ℤ₃ → Bool
isPos₃ (+₃ n) = true
isPos₃ (-₃ n) = false

two-zero-clash : ¬ (+₃ zero ≡ -₃ zero)
two-zero-clash p = true≢false (cong isPos₃ p)

-- 偏偏数学上又**要求**它们是同一个数——映射到差分整数立刻现形：
to⊖ : ℤ₃ → ℤdiff
to⊖ (+₃ n) = n ⊖ zero
to⊖ (-₃ n) = zero ⊖ n

two-zero-agree : to⊖ (+₃ zero) ≡ to⊖ (-₃ zero)
two-zero-unit : to⊖ (+₃ zero) ≡ 0 ⊖ 0
two-zero-agree = refl
two-zero-unit = refl

-- 「相等却算不等」＝需要商集（把等价类做成值）。Agda 不爱商集，
-- Maguire 的招法更省事：**改构造子的名，让坏记法根本无法书写**——
-- 把 -_ 改成 -[1+_]，负零失去合法性，唯一表示达成：
data ℤfin : Set where
  +_     : ℕ → ℤfin
  -[1+_] : ℕ → ℤfin

-- 读法：+ n 表示 n ⊖ 0；-[1+ n ] 表示 0 ⊖ suc n。
-- 于是「正的不可能是负的」是荒谬模式直接排除的：
isPos : ℤfin → Bool
isPos (+ n)     = true
isPos -[1+ n ]  = false

pos≢neg : (m n : ℕ) → + m ≢ -[1+ n ]
pos≢neg m n p = true≢false (cong isPos p)

-- Maguire 的 suc/pred（2.13 末）：跨零各管各的。
sucℤ : ℤfin → ℤfin
sucℤ (+ x)        = + suc x
sucℤ -[1+ zero ]  = + zero
sucℤ -[1+ suc x ] = -[1+ x ]

predℤ : ℤfin → ℤfin
predℤ (+ zero)    = -[1+ zero ]
predℤ (+ suc x)   = + x
predℤ -[1+ x ]    = -[1+ suc x ]

suc-pred-id : (x : ℤfin) → sucℤ (predℤ x) ≡ x
suc-pred-id (+ zero)  = refl
suc-pred-id (+ suc x) = refl
suc-pred-id -[1+ x ]  = refl

-- 把「规范形」做成命题：差分整数的不动点族，索引在 ℤdiff 上。
-- 两个构造子恰是 normalize 的两类不动点，缺口 (suc p ⊖ suc n) 无人认领。
data IsCanon : ℤdiff → Set where
  posForm : (p : ℕ) → IsCanon (p ⊖ zero)
  negForm : (n : ℕ) → IsCanon (zero ⊖ suc n)

-- 「两侧同时非零」不是任何规范形——荒谬模式三行证死：
noCanon : (p n : ℕ) → ¬ IsCanon (suc p ⊖ suc n)
noCanon p n ()

-- 约分必落进规范形（对照 13 章：这就是对本 p/q 双参数的归纳）：
norm-IsCanon : (x : ℤdiff) → IsCanon (normalize x)
norm-IsCanon (zero ⊖ zero)    = posForm zero
norm-IsCanon (zero ⊖ suc n)   = negForm n
norm-IsCanon (suc p ⊖ zero)   = posForm (suc p)
norm-IsCanon (suc p ⊖ suc n)  = norm-IsCanon (p ⊖ n)

-- 消费 IsCanon 时，dot pattern 把「证明逼出的索引等式」如实写回左边：
whichSide : (x : ℤdiff) → IsCanon x → Bool
whichSide .(p ⊖ zero)       (posForm p) = true
whichSide .(zero ⊖ suc n)   (negForm n) = false

-- ℤfin 与「约到底的 ℤdiff」互译，两边都是计算（refl 白送）：
fromDiff : ℤdiff → ℤfin
fromDiff (a ⊖ b) = go a b
  where
  go : (a b : ℕ) → ℤfin
  go zero zero      = + zero
  go zero (suc n)   = -[1+ n ]
  go (suc p) zero   = + suc p
  go (suc p) (suc n) = go p n

toDiff : ℤfin → ℤdiff
toDiff (+ n)      = n ⊖ zero
toDiff -[1+ n ]   = zero ⊖ suc n

from-to⁺ : (n : ℕ) → fromDiff (toDiff (+ n)) ≡ + n
from-to⁺ zero     = refl
from-to⁺ (suc n)  = refl

from-to⁻ : (n : ℕ) → fromDiff (toDiff -[1+ n ]) ≡ -[1+ n ]
from-to⁻ n        = refl

to-from : (a b : ℕ) → toDiff (fromDiff (a ⊖ b)) ≡ normalize (a ⊖ b)
to-from zero zero       = refl
to-from zero (suc n)    = refl
to-from (suc p) zero    = refl
to-from (suc p) (suc n) = to-from p n

-- 解读：fromDiff ∘ toDiff = id（ℤfin 的每个数原样往返），
-- toDiff ∘ fromDiff = normalize（差分整数的每条纤维被折到规范代表元）。
-- 这正是「唯一表示」的范畴式证词：ℤfin ≅ ℤdiff 的像。

------------------------------------------------------------------------
-- 5. pattern 同义词：语法、red/blue/black 与「规范形」别名（Maguire 2.14）
------------------------------------------------------------------------

-- pattern 声明 = 「给模式匹配造别名」。左右两边都必须是模式
-- （只有红字构造子与黑字变量，禁止蓝函数——报错实测见教程 37.5），
-- 且左边的每个变量都要在右边登场。
--
-- Maguire 的名句翻译：数据类型的构造子只是名字，语义可以靠
-- **另一套名字**重新组织。ℤfin 永远由 +_ 与 -[1+_] 构成，
-- 但用差分记号「ℤ⊖」重述规范形，正负两侧立刻对称：

pattern ℤ⊖0 n     = + n          -- 规范形：n ⊖ 0（含零）
pattern 0ℤ⊖ n     = -[1+ n ]     -- 规范形：0 ⊖ suc n（严格负）

-- 有了别名，取反函数从「四处补 suc」变成三行对照表（Maguire 2.14 原文）：
infix 8 -_
-_ : ℤfin → ℤfin               -- 前缀取反（stdlib 同款拼写 `-_`，与二元 `_-_` 两名并存）
- (ℤ⊖0 zero)      = ℤ⊖0 zero     -- 0 的镜像还是 0
- (ℤ⊖0 (suc n))   = 0ℤ⊖ n        -- +(n+1) ↦ 0⊖(n+1)
- (0ℤ⊖ n)         = ℤ⊖0 (suc n)  -- 0⊖(1+n) ↦ +(n+1)

-- 对合性零证明：三条子句每条都是「算两步回到原形」。
neg-involutive : (x : ℤfin) → - (- x) ≡ x
neg-involutive (ℤ⊖0 zero)     = refl
neg-involutive (ℤ⊖0 (suc n))  = refl
neg-involutive (0ℤ⊖ n)         = refl

-- 别名还能出现在**右边**（右值里它就是普通的应用缩写）：
one : ℤfin
one = ℤ⊖0 1

minus-one : ℤfin
minus-one = 0ℤ⊖ 0

-- Maguire 2.15：真减法（输入 ℕ、输出 ℤ），就是差分记号的可计算版。
-- 名字 _⊖ℤ_：书里叫 _⊖_，这里 _⊖_ 已被第 3 节的记录模式占用——
-- 一个作用域里一个名只许一个定义（28 章老坑），后缀区分。
infixl 6 _⊖ℤ_
_⊖ℤ_ : ℕ → ℕ → ℤfin
zero  ⊖ℤ zero     = ℤ⊖0 zero
zero  ⊖ℤ suc n    = 0ℤ⊖ n
suc m ⊖ℤ zero     = ℤ⊖0 (suc m)
suc m ⊖ℤ suc n    = m ⊖ℤ n

-- 它与差分记录精确互洽：m ⊖ℤ n 正是差分 (m ⊖ n) 的规范代表元。
⊖ℤ-normalize : (m n : ℕ) → fromDiff (m ⊖ n) ≡ m ⊖ℤ n
⊖ℤ-normalize zero zero      = refl
⊖ℤ-normalize zero (suc n)   = refl
⊖ℤ-normalize (suc m) zero   = refl
⊖ℤ-normalize (suc m) (suc n) = ⊖ℤ-normalize m n

-- 整数加法四行（Maguire 2.15：同号直接加，异号化归为真减法）：
infixl 6 _+ℤ_
_+ℤ_ : ℤfin → ℤfin → ℤfin
+ x +ℤ + y        = + (x +ℕ y)
+ x +ℤ -[1+ y ]   = x ⊖ℤ suc y
-[1+ x ] +ℤ + y   = y ⊖ℤ suc x
-[1+ x ] +ℤ -[1+ y ] = -[1+ x +ℕ suc y ]

-- 乘法：Maguire 按「乘数形状」分派，仍是纯计算。
infixl 7 _×ℤ_
_×ℤ_ : ℤfin → ℤfin → ℤfin
x ×ℤ ℤ⊖0 zero         = ℤ⊖0 zero
x ×ℤ ℤ⊖0 (suc zero)   = x
x ×ℤ 0ℤ⊖ zero         = - x
x ×ℤ ℤ⊖0 (suc (suc y)) = (ℤ⊖0 (suc y) ×ℤ x) +ℤ x
x ×ℤ 0ℤ⊖ (suc y)      = (0ℤ⊖ y ×ℤ x) +ℤ (- x)

-- 书末的两枚测试（Maguire 2.15），照搬改写：
test₃ : (- (ℤ⊖0 2)) ×ℤ (- (ℤ⊖0 6)) ≡ ℤ⊖0 12
test₃ = refl                              -- (−2)×(−6)=12

test₄ : (ℤ⊖0 3) +ℤ (- (ℤ⊖0 10)) ≡ 0ℤ⊖ 6
test₄ = refl                              -- 3−10=−7

-- Maguire 划的重点：模式匹配只认红字（构造子/同义词）；
-- 等号左边冒生的标识符一律是黑字新变量，绝不会引用到蓝函数。
-- 所以 pattern 同义词右边只许「红+黑」——这不是风味，是安全闸门。

------------------------------------------------------------------------
-- 6. 良定义性：(a ⊖ b) + (c ⊖ d) 的两条约分路径殊途同归
------------------------------------------------------------------------

-- 差分加法的「两步走」：x + y =.normalize (x ⊞ y)。
-- 于是给定 (a ⊖ b) 与 (c ⊖ d)，有两种约分日程：
--   路径一（先加后约）：normalize ((a⊖b) ⊞ (c⊖d))——全部堆到最后总约分；
--   路径二（先约后加）：normalize (normalize (a⊖b) ⊞ normalize (c⊖d))。
-- 良定义性 = 两条路径的终点是**同一个值**。这在 2.12 的「拐杖时代」
-- 是没法开口的承诺，在这里是一行可证等式。
--
-- 证明机器需要三对搬运引理。先手搓 stdlib 里没有的「suc 挪到 + 外面（左）」：

suc-plus : (m n : ℕ) → suc m +ℕ n ≡ suc (m +ℕ n)
suc-plus zero n = refl
suc-plus (suc m) n = cong suc (suc-plus m n)

-- 引理 A（消一步）：原料里两侧各多一个 suc，对消它不改变「加完再约」的结果。
step-ˡ : (y : ℤdiff) (p q : ℕ) →
  normalize ((suc p ⊖ suc q) ⊞ y) ≡ normalize ((p ⊖ q) ⊞ y)
step-ˡ (a ⊖ b) p q rewrite suc-plus p a | suc-plus q b = refl

step-ʳ : (x : ℤdiff) (p q : ℕ) →
  normalize (x ⊞ (suc p ⊖ suc q)) ≡ normalize (x ⊞ (p ⊖ q))
step-ʳ (a ⊖ b) p q rewrite +-suc a p | +-suc b q = refl

-- 引理 B（一侧提前约分无关紧要）：
plus-ˡ : (y : ℤdiff) (a b : ℕ) →
  normalize (normalize (a ⊖ b) ⊞ y) ≡ normalize ((a ⊖ b) ⊞ y)
plus-ˡ y zero b = refl
plus-ˡ y (suc a) zero = refl
plus-ˡ y (suc a) (suc b) = begin
  normalize (normalize (suc a ⊖ suc b) ⊞ y)  ≡⟨⟩
  normalize (normalize (a ⊖ b) ⊞ y)          ≡⟨ plus-ˡ y a b ⟩
  normalize ((a ⊖ b) ⊞ y)                    ≡⟨ sym (step-ˡ y a b) ⟩
  normalize ((suc a ⊖ suc b) ⊞ y)            ∎

plus-ʳ : (x : ℤdiff) (a b : ℕ) →
  normalize (x ⊞ normalize (a ⊖ b)) ≡ normalize (x ⊞ (a ⊖ b))
plus-ʳ x zero b = refl
plus-ʳ x (suc a) zero = refl
plus-ʳ x (suc a) (suc b) = begin
  normalize (x ⊞ normalize (suc a ⊖ suc b))  ≡⟨⟩
  normalize (x ⊞ normalize (a ⊖ b))          ≡⟨ plus-ʳ x a b ⟩
  normalize (x ⊞ (a ⊖ b))                    ≡⟨ sym (step-ʳ x a b) ⟩
  normalize (x ⊞ (suc a ⊖ suc b))            ∎

-- 约分是幂等的（normalize 的输出确实是不动点）：
norm-norm : (a b : ℕ) → normalize (normalize (a ⊖ b)) ≡ normalize (a ⊖ b)
norm-norm zero b = refl
norm-norm (suc a) zero = refl
norm-norm (suc a) (suc b) = norm-norm a b

-- 定理（两种约分路径同归）：
two-paths : (a b c d : ℕ) →
  normalize ((a ⊖ b) ⊞ (c ⊖ d))
    ≡ normalize (normalize (a ⊖ b) ⊞ normalize (c ⊖ d))
two-paths a b c d = begin
  normalize ((a ⊖ b) ⊞ (c ⊖ d))
    ≡⟨ sym (plus-ˡ (c ⊖ d) a b) ⟩
  normalize (normalize (a ⊖ b) ⊞ (c ⊖ d))
    ≡⟨ sym (plus-ʳ (normalize (a ⊖ b)) c d) ⟩
  normalize (normalize (a ⊖ b) ⊞ normalize (c ⊖ d)) ∎

-- 换个读法：加法与约分可交换——先把 operands 折成规范代表元再相加，
-- 和直接把账本并起来再折，答案相同。这就是「(a⊖b) 的加法在等价类上
-- 良定义」的计算内容。
plus-respects-normalize : (x y : ℤdiff) →
  x + y ≡ normalize x + normalize y
plus-respects-normalize (a ⊖ b) (c ⊖ d) = two-paths a b c d

------------------------------------------------------------------------
-- 7. stdlib 对照：Data.Integer（3.0）就是这么造的
------------------------------------------------------------------------

-- stdlib 3.0 的 ℤ 是编译器内建 Agda.Builtin.Int，由 Data.Integer.Base
-- 改名导出：Int → ℤ，构造子 pos → +_（读作「+ n」）、
-- negsuc → -[1+_]（读作「−(1+n)」）——与本章 ℤfin **逐字同名**！
-- 也就是说：Maguire 的「弯路三→修直」正是 stdlib 的历史注脚。
-- 更妙的是 Base.agda 第 46–47 行就用 pattern 同义词造对称记号：
--   pattern +0 = + 0
--   pattern +[1+_] n = + (ℕ.suc n)
-- 而 stdlib 的取反 `-_` 恰好就是用这三枚模式写成的三行表。

import Data.Integer as ℤS

fin→int : ℤfin → ℤS.ℤ
fin→int (+ n)       = ℤS.+ n
fin→int -[1+ n ]    = ℤS.-[1+ n ]

int→fin : ℤS.ℤ → ℤfin
int→fin (ℤS.+ n)        = + n
int→fin (ℤS.-[1+ n ])   = -[1+ n ]

-- 双向都是纯计算：两条 round-trip 全部 refl 过关。
fin→int→fin : (x : ℤfin) → int→fin (fin→int x) ≡ x
fin→int→fin (+ n)     = refl
fin→int→fin -[1+ n ]  = refl

int→fin→int : (i : ℤS.ℤ) → fin→int (int→fin i) ≡ i
int→fin→int (ℤS.+ n)      = refl
int→fin→int (ℤS.-[1+ n ]) = refl

-- 同号相加子句与本章 _+ℤ_ 完全同形（stdlib Data.Integer.Base:231）：
+-same-sign : (m n : ℕ) →
  fin→int (+ (m +ℕ n)) ≡ ℤS.+ m ℤS.+ ℤS.+ n
+-same-sign m n = refl

-- 闭算测试：stdlib 的加/减/乘/⊖ 都算得动。
int-test₀ : (ℤS.+ 3) ℤS.+ (ℤS.-[1+ 1 ]) ≡ ℤS.+ 1
int-test₀ = refl                          -- 3 + (−2) = 1

int-test₁ : (ℤS.+ 3) ℤS.- (ℤS.+ 5) ≡ ℤS.-[1+ 1 ]
int-test₁ = refl                          -- 3 − 5 = −2

int-test₂ : (ℤS.-[1+ 1 ]) ℤS.* (ℤS.-[1+ 2 ]) ≡ ℤS.+ 6
int-test₂ = refl                          -- (−2)×(−3) = 6

-- 有趣的差异：stdlib 的 ℕ 真减法 _⊖_（Base.agda:224）**不是**本章
-- ⊖ℤ 这样的结构递归，而是借 monus 与判等走快路：
--   m ⊖ n with m ℕ.<ᵇ n
--   ... | true  = - + (n ℕ.∸ m)
--   ... | false = + (m ℕ.∸ n)
-- 源码注释原话：不用归纳定义是为了「backed by builtin operations,
-- much faster」。语义上两个定义一致（闭算逐项相同）：
int-test₃ : 3 ℤS.⊖ 5 ≡ ℤS.-[1+ 1 ]
int-test₃ = refl

-- 至于差分记录 ℤdiff：stdlib 没有给它留门（唯一表示赢了），
-- 但它的等价类灵魂活在 Data.Integer 的同构故事里——
-- 想走商集路线的读者，可对照本章 norm-IsCanon 与 17 章 _↔_。
