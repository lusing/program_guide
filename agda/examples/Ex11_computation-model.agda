-- 第 11 章 · Agda 的计算模型：规范化、卡住项与 copattern
-- 主题：求值 = 规范化；模式匹配何时算得动/算不动；卡住（stuck）的三种来源；
--       record 的构造/投影三件套与 η；函数外延为什么「算不动」。
-- 所有代码在 Agda 2.9.0 + stdlib 3.0 下真实类型检查通过。
-- 取材：Sandy Maguire《Certainty by Construction》第一章 1.8/1.9/1.13–1.16 节。

module Ex11_computation-model where

open import Data.Bool using (Bool; true; false; not; if_then_else_)
open import Data.Nat using (ℕ; zero; suc; _+_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

------------------------------------------------------------------------
-- 1. 求值 = 规范化：定义就是重写规则
------------------------------------------------------------------------

-- Maguire 的心智模型：Agda 没有「运行」这回事。每个函数定义都是
-- 一组「左边形 → 右形」的重写规则，求值就是把外层能匹配的规则
-- 一路代入（normalize），直到无规则可套。
-- 交互式操作：Emacs/VSCode 里 C-c C-n（Normalise）吃一个表达式，
-- 吐出它的正规形。命令行下没有这个菜单，但可以用 refl 断言
-- 「两边算到同形」——03 章就见过的「单元测试」写法：

_ : not (not false) ≡ false
_ = refl
-- 写成 ≡ true 则整个文件不过检查，报错（实测，探针 TmpProbe36f）：
--   The terms false and true are not equal at type Bool
--   when checking that the expression refl has type
--   not (not false) ≡ true
-- 即「测试挂了 = 编译挂了」：Agda 的单元测试只在失败时开口。

-- 手工追踪 not (not false) 的规范化：
--   not (not false) → not true → false
-- 外层 not 一开始匹配不上（参数 not false 既不是 true 也不是 false
-- 的「语法原形」），内层先动——重写只能匹配「构造子」。

------------------------------------------------------------------------
-- 2. 两个 _∨_ 定义：分支因子与「算得动」的距离
------------------------------------------------------------------------

-- 版本一（真值表流）：对两个参数都分情况，四行。
_∨₁_ : Bool → Bool → Bool
false ∨₁ false = false
false ∨₁ true  = true
true  ∨₁ false = true
true  ∨₁ true  = true

-- 版本二（Maguire 推荐流）：只查第一个参数，两行。
_∨₂_ : Bool → Bool → Bool
false ∨₂ other = other
true  ∨₂ other = true

-- 语义完全等价（穷举 4 种组合即可 refl 验证），计算性质天差地别。
∨-equiv : (a b : Bool) → (a ∨₁ b) ≡ (a ∨₂ b)
∨-equiv false false = refl
∨-equiv false true  = refl
∨-equiv true  false = refl
∨-equiv true  true  = refl

-- 差别在「偏应用」时看得见。算子留空（section）的写法是下划线**紧贴**
-- 算子（`∨₂_`）；写成 `true ∨₂ _`（带空格）时 `_` 被当成隐式元变量，
-- 整个式子退化成 Bool（实测报错见文档 11.2）。
-- `true ∨₂_` 展开即 λ other → true ∨₂ other。第一个参数已是构造子
-- true，规则 `true ∨₂ other = true` 直接套上：
section₂ : (true ∨₂_) ≡ (λ _ → true)
section₂ = refl

-- 而 `true ∨₁_`：_∨₁_ 对第二个参数也要看，第二个参数是变量，
-- 没有规则可套——整个 λ 卡住，与常函数 (λ _ → true) 算不同形：
--   section₁-bad : (true ∨₁_) ≡ (λ _ → true)
--   section₁-bad = refl        -- ← 实测不过（探针 TmpProbe36a）
-- 「少分支 = 在信息不足时仍能推进」——这句话以后每个证明都受用。

------------------------------------------------------------------------
-- 3. 卡住项（stuck）：算不动的三种姿势
------------------------------------------------------------------------

-- 定义：既不是构造子、其最外层也没有可套用的规则 → stuck（正规式里的
-- 「中性项 neutral」）。类型检查器只认「两边正规形同语法」，
-- 所以卡住 = refl 无能为力。

-- 姿势一：等一个没给到的参数（上一节 true ∨₁_ 的元凶是变量 other）。

-- 姿势二：postulate 永远卡住。postulate 进作用域的变量没有任何
-- 计算信息，永远停在自己身上：
postulate always-stuck : Bool

stuck-not : not always-stuck ≡ not always-stuck
stuck-not = refl          -- 两边同形，唯一能算的只有「自己 = 自己」

-- 下面两条都因 always-stuck 卡死（实测报错见文档 11.3，探针 36c/36i）：
--   _ : not always-stuck ≡ false      -- The terms not always-stuck and false …
--   _ : true ∨₁ always-stuck ≡ true   -- 同上：∨₁ 需要看第二个参数
-- 但 ∨₂ 不需要看第二个参数，照算不误：
_ : true ∨₂ always-stuck ≡ true
_ = refl

-- 姿势三：被索引/参数顶住的递归函数。Data.Nat 的 _+_ 在左参数上递归，
-- 于是 n + zero 对变量 n 卡住（15 章开篇的旧账）：
plus-stuck : (n : ℕ) → (n + zero) + n ≡ (n + zero) + n
plus-stuck n = refl       -- 左右同为卡住项，语法同形，仍然 refl
-- 想化简卡住的 n + zero？只能归纳（15 章），不能硬算。

-- Maguire 的金句：实现里少一次模式匹配，后续每个证明就少一次
-- 「对该函数分情况」的义务——「三行证明 vs 八十一行证明」的差距。
-- 对 if_then_else_ 同样成立：它对条件分完情况，对两个分支值
-- 绝不多看一眼，所以 true ∨₂ b 那种「只查一个参数」的定义
-- 在嵌套使用时照样推进：

and-then-or : (b : Bool) → ((true ∨₂ b) ∨₂ (false ∨₂ b)) ≡ true
and-then-or b = refl      -- 两处 ∨₂ 各自立刻算成 true，b 全程没被看

------------------------------------------------------------------------
-- 4. record：构造、投影三件套与 copattern
------------------------------------------------------------------------

-- 手搓一个积类型（stdlib 的 _×_ 在 Data.Product，结构相同）。
record _⊗_ (A B : Set) : Set where
  field
    fst : A
    snd : B

open _⊗_ public   -- 把 fst/snd 拉进作用域：可作投影函数，也可作 copattern 头

pair₁ : Bool ⊗ ℕ
pair₁ = record { fst = true ; snd = 3 }        -- 写法一：record 字面量

pair₂ : Bool ⊗ ℕ                                -- 写法二：copattern——
fst pair₂ = not true ∨₂ false                   --   按字段分别给定义
snd pair₂ = (1 + 2) + zero

-- 投影三种姿势：
p2a : Bool
p2a = fst pair₁                 -- 选择器函数（字段本来就是函数！）

p2b : Bool
p2b = pair₁ .fst                -- 点投影（把字段名放调用者后面）

p2c : Bool
p2c = unpack pair₁                      -- 模式匹配（record 模式）
  where unpack : (r : Bool ⊗ ℕ) → Bool
        unpack record { fst = x ; snd = y } = x
-- 其中 record { fst = x } 就够（用不到的字段可不绑）。

-- copattern 可以嵌套（对 stdlib 的 _×_ 演示，方便与后文对照）：
open import Data.Product using (_×_; proj₁; proj₂; _,_)
nested : Bool × (Bool × ℕ)
proj₁ nested = true
proj₁ (proj₂ nested) = false
proj₂ (proj₂ nested) = 7

-- record 的 η 规则：构造与投影互为逆，**定义级**成立——
eta-⊗ : (r : Bool ⊗ ℕ) → r ≡ record { fst = fst r ; snd = snd r }
eta-⊗ r = refl

eta-× : (p : Bool × ℕ) → p ≡ ((proj₁ p) , (proj₂ p))
eta-× p = refl
-- `,` 与 `≡` 同为 level 4，`p ≡ a , b` 直接 parse 不过（坑位实测，见 11.8）。

-- 对照下一节：函数就没有这等好事。

------------------------------------------------------------------------
-- 5. 函数没有 η：外延性是算不动的
------------------------------------------------------------------------

-- 两个「行为一致」的函数：
f₁ : Bool → Bool
f₁ b = b ∨₂ true

f₂ : Bool → Bool
f₂ b = true

-- 逐点等（对每个输入 refl 可证）：
pointwise : (b : Bool) → f₁ b ≡ f₂ b
pointwise false = refl
pointwise true  = refl

-- 但「函数本身相等」refl 给不出（实测，探针 TmpProbe36b）：
--   bad : f₁ ≡ f₂
--   bad = refl     -- The terms x ∨₂ true and true are not equal at type Bool
--                  -- when checking that the expression refl has type f₁ ≡ f₂
-- 原因回到本节主题：f₁ 是 λ b → b ∨₂ true，b 是**变量**，
-- ∨₂ 要查 b，规则套不上——函数体外层的卡住项是「跨不过的鸿沟」，
-- 除非要么分情况（∀ 引入后再归纳/匹配），要么请出外延公理：
postulate
  funext : {A : Set} {B : A → Set}
           {f g : (x : A) → B x} → ((x : A) → f x ≡ g x) → f ≡ g

f₁≡f₂ : f₁ ≡ f₂
f₁≡f₂ = funext pointwise
-- 3.0 里这条公理的「类型」叫 Axiom.Extensionality.Propositional 里的
-- Extensionality a b（库本身不给证明；40 章实测：没有 Function.Extensionality
-- 这个模块）——这里 postulate 只为演示。

-- η 对函数是**定义级成立**的另一件事：λ x → f x 与 f 同形
-- （η-展开），所以：
eta-λ : (f₁ ≡ (λ b → f₁ b))
eta-λ = refl
-- 卡住的不是 η，是「两个不同函数体逐点相同 ⇒ 相等」这一步外延。

------------------------------------------------------------------------
-- 6. 类型检查器与求值器是同一台机器
------------------------------------------------------------------------

-- 依赖类型里，类型位置也参与计算。下面的类型别名里塞了一串布尔运算，
-- 类型检查器会把它规范化后再比较：
len₊ : Set
len₊ = if (not (false ∨₂ true)) ∨₂ false then Bool else ℕ
-- 整串条件算成 false → 走 else 分支。等等——那 len₊ 该是 ℕ？
-- 手工追一下：false ∨₂ true → true；not true → false；
-- false ∨₂ false → false；if false then Bool else ℕ → ℕ。
same-type : len₊ ≡ ℕ
same-type = refl          -- 左边整串算成 ℕ，类型也是表达式


-- 终止性检查与求值的关系：Agda 的类型检查要求所有函数强归一
-- （否则假命题也能「算」出来，见 07 章）；卡住项永远是过程，
-- postulate 是永久卡住。实测：postulate 混进程序**照样通过**
-- --compile（27 章流水线），但可执行文件一求值到它就当场崩溃：
--   MAlonzo Runtime Error: postulate evaluated: TmpProbe36j.mystery
-- （探针见文档 11.6——编译期不问、运行时才爆，这正是「卡住」的代价。）

------------------------------------------------------------------------
-- 7. 小结断言（把本章要点各钉一枚 refl）
------------------------------------------------------------------------

-- ① 少分支的定义推进更快
sum1 : (b : Bool) → (false ∨₂ b) ≡ b
sum1 false = refl
sum1 true  = refl

-- ② 卡住项之间也能自反
sum2 : (n : ℕ) → (n + zero) ≡ (n + zero)
sum2 n = refl

-- ③ record 有 η，函数外延没有
sum3 : (r : Bool ⊗ ℕ) → record { fst = fst r ; snd = snd r } ≡ r
sum3 r = refl
