------------------------------------------------------------------------
-- 第 46 章配套示例：直觉主义逻辑的 Kripke 语义与可靠性定理
--
-- 主线（Aaron Stump《Verified Functional Programming in Agda》第 10 章
-- 10.1–10.4 节的全部核心内容，自包含重写）：
--   ① 语法：正命题直觉主义逻辑 PPIL 的公式（var/Top/⇒/∧）；
--   ② 证明：自然推演的 7 条规则做成一个**索引数据类型** `_⊢_`（规则即构造子，
--      与 35 章 SK 组合子的 `_↝_` 同一手法）；
--   ③ 语义：Kripke 结构（世界 + 预序 + 单凋赋值）做成 record，
--      满足关系 `_⊩_` 由**类型层计算**给出（一个返回 Set 的函数）；
--   ④ 元定理：单调性 → 可靠性（Soundness），证明可计算、可实例化；
--   ⑤ 反例机器：给 Peirce 律造一个 Kripke 反模型，从而**证明它在 PPIL
--      里不可证**——14 章只能「写不出」，这一章能「证明写不出」。
--
-- 移植说明（原书 Agda 2.2.14 + 自带 IAL 库 → 本机 2.9.0 + stdlib 3.0）：
--  * 原书跑在 `--no-universe-polymorphism` 下，所有类型层级写死；本版按现代
--    写法把 `struct` 放在 `Set₁`（世界住在 `Set`），`_⊨_` 因此是 `Set₁`；
--  * IAL 的 `J`/`K`/`^`/`L`/`B`/`N` → stdlib 的 `⊤`/`⊥`/`_×_`/`List`/`Bool`/`ℕ`；
--    注意 3.0 的 `Data.Unit` 只导出 `⊤` 与 **`tt`**（不叫 `unit`，实测）；
--  * IAL 的 `preorder R = reflexive × transitive` → stdlib 的 `Reflexive`/
--    `Transitive`（Relation.Binary.Definitions 第 41/72 行）；原书把两者打包在
--    一个 `preorderR` 字段里再投影，本版直接放两个字段，少一层投影；
--  * 原书 `AndE` 用一个 Bool 参数选合取支（依赖 `if _ then _ else _` 抬到
--    类型层）——这个巧技 3.0 依旧可用，但 `if` 是 prefix 算子（level 0），
--    写在 `Γ ⊢ if b then A else B` 里必须加括号（实测 NoParseForApplication）；
--  * 原书的可靠性定理直接在 `Γ ⊨ A` 记号上写子句（原书那行
--    `Soundness (ImpliesE p p') {k} g = ...` 里，`{k}` 来自 `⊨` 展开出来的
--    隐式量化，不属于 ImpliesE）。照抄形态 2.9.0 **也**能过（实测），但
--    `{k}` 挂错位置就立刻 WrongHidingInLHS。本版本先把量词写开成
--    `soundness`，再用一行 `Soundness = soundness` 换回 `⊨` 记号，两条路
--    各干什么一眼可见，47 章也更方便直接对 `soundness` 动手。
--
-- 类型检查：cd agda && ./build.sh Ex46_ppil_kripke
------------------------------------------------------------------------

module Ex46_ppil_kripke where

open import Agda.Builtin.String using (String)
open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.List using (List; []; _∷_)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Unit using (⊤; tt)
open import Level using (0ℓ)
open import Relation.Binary.Core using (Rel)
open import Relation.Binary.Definitions using (Reflexive; Transitive)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Relation.Nullary using (¬_)

------------------------------------------------------------------------
-- ① 公式：正命题直觉主义逻辑（PPIL）
------------------------------------------------------------------------

-- 只有四类公式：命题变量、真、蕴含、合取。没有 ∨，也没有 ¬（¬A 是
-- A ⇒ ⊥，而 ⊥ 是「否定性」构造——原书 10.1 节把它们排除在 PPIL 之外，
-- 理由到 47 章才会显出分量：加了 ∨ 或 ⊥，完全性证明里的 NBE 会显著变复杂）。
data Formula : Set where
  var : String → Formula
  Top : Formula
  _⇒_ : Formula → Formula → Formula
  _∧_ : Formula → Formula → Formula

infixr 2 _⇒_
infixr 3 _∧_

-- 命题变量用字符串命名（原书同样如此：`$ "p"`）。这里不需要字符串相等
-- 判定——赋值关系 V 是「列出成正构造子」的索引类型，不做计算。
p q r : Formula
p = var "p"
q = var "q"
r = var "r"

-- 后面要用到的两个公式
Peirce : Formula
Peirce = ((p ⇒ q) ⇒ p) ⇒ p

dup : Formula
dup = p ⇒ p ∧ p

------------------------------------------------------------------------
-- ② 证明：自然推演，规则即构造子
------------------------------------------------------------------------

-- 上下文（假设表）就是公式表。原书往**右**追加（Γ , f），Agda 的 cons 习惯
-- 往**左**追加（f ∷ Γ）；两边只是镜像，所有规则照抄。
Ctxt = List Formula

-- 「Γ ⊢ A」读作：在假设 Γ 下，A 是可证的。它是一个**索引数据类型**：
-- 构造子 = 推导规则，构造子的参数 = 前提。与 35 章 `_↝_`（一步归约规则
-- 直接做成构造子）是同一手法；Curry–Howard 下它同时也是简单类型 λ 演算的
-- 项（⇒I 是 λ，⇒E 是应用，id 是公理）。
data _⊢_ : Ctxt → Formula → Set where
  id : ∀ {Γ A} → A ∷ Γ ⊢ A
  wk : ∀ {Γ A B} → Γ ⊢ A → B ∷ Γ ⊢ A
  ⇒I : ∀ {Γ A B} → (A ∷ Γ) ⊢ B → Γ ⊢ A ⇒ B
  ⇒E : ∀ {Γ A B} → Γ ⊢ A ⇒ B → Γ ⊢ A → Γ ⊢ B
  ⊤I : ∀ {Γ} → Γ ⊢ Top
  ∧I : ∀ {Γ A B} → Γ ⊢ A → Γ ⊢ B → Γ ⊢ A ∧ B
  ∧E : ∀ (b : Bool) {Γ A B} → Γ ⊢ A ∧ B → Γ ⊢ (if b then A else B)

infix 1 _⊢_

-- `id`（identity/公理）：右边第一个假设可以直接引用；`wk`（weakening，
-- 结构规则）：多加一个假设不削弱结论。原书把合取的两条消去规则压成一条，
-- 用 Bool 参数 `b` 选支：`if true then A else B` 在类型位置照样约简——
-- 这是「类型层计算」（11、31 章）在索引里的又一次出场。

-- 原书 10.1 节的样例推导：⊢ p ⇒ (p ∧ p)
--   p ⊢ p    p ⊢ p
--   ---------------- ∧I
--   p ⊢ p ∧ p
--   -------------- ⇒I
--   ⊢ p ⇒ p ∧ p
th-dup : [] ⊢ dup
th-dup = ⇒I (∧I id id)

-- 只用一条公理加一次 weaken 就能证的东西：假设里有 p，就能在任意多的
-- 额外假设下拿到 p。
th-wk : ∀ {Γ} → Γ ⊢ p → q ∷ r ∷ Γ ⊢ p
th-wk th = wk (wk th)

-- 合取的结合律（10.7 节练习 1 的那类题目，全部由 id + ∧I/∧E 拼出）
th-assoc : [] ⊢ (p ∧ q) ∧ r ⇒ p ∧ (q ∧ r)
th-assoc = ⇒I (∧I (∧E true (∧E true id))
                  (∧I (∧E false (∧E true id)) (∧E false id)))

-- 蕴含的「自我转发」：从 A⇒B 和 B⇒C 造 A⇒C，只用了 ⇒E 与 ⇒I。
th-chain : [] ⊢ (p ⇒ q) ⇒ (q ⇒ r) ⇒ p ⇒ r
th-chain = ⇒I (⇒I (⇒I (⇒E (wk id) (⇒E (wk (wk id)) id))))

-- 读法：进入三层 ⇒I 后，上下文是 p ∷ (q⇒r) ∷ (p⇒q) ∷ []，目标是 r。
-- ⇒E 的两条前提各自数需要几次 weaken 才够到假设：q⇒r 在第 2 位（一次），
-- p⇒q 在第 3 位（两次），p 在第 1 位（id 直接拿）。

------------------------------------------------------------------------
-- ③ Kripke 结构：世界 + 未来预序 + 单调赋值
------------------------------------------------------------------------

-- 一个结构 = 一个世界集合 W、一个「w′ 是 w 的未来可能世界」的二元关系 R
-- （要求预序：自反 + 传递）、一个赋值 V（哪个世界里哪些命题变量为真，
-- 要求对 R 单调）。
--
-- 层级交代（原书靠 --no-universe-polymorphism 免掉了这一整层）：世界住在
-- `Set`，所以 `struct` 本身住在 `Set₁`。后面 `_⊨_` 要对**所有**结构量化，
-- 其类型因此也在 `Set₁`——这是量词「对模型量化」的必要代价。
record struct : Set₁ where
  field
    W : Set
    R : Rel W 0ℓ
    reflR : Reflexive R
    transR : Transitive R
    V : W → String → Set
    monoV : ∀ {w w′} → R w w′ → ∀ {x} → V w x → V w′ x

open struct

-- 注意 V 与 monoV 的形状：`V : W → String → Set` 不是 W × String → Bool，
-- 而是「证据类型」——某个变量在某个世界里为真，当且仅当**存在**一个
-- `V w x` 的值。这就是 35 章「关系即数据类型」的负信息约定：没有构造子
-- 就是「不成立」，不需要显式写 false。monoV 则把「真了就一直是真」写进
-- 结构的要求里。

------------------------------------------------------------------------
-- ④ 满足关系 `_⊩_`：一个返回类型的函数
------------------------------------------------------------------------

-- `k , w ⊩ A` 读作「在结构 k 的世界 w 里 A 为真」。它是对 A 的**类型层
-- 递归**（11 章 `_⊩_` 同款思路：函数返回 Set）。
_,_⊩_ : (k : struct) → W k → Formula → Set
k , w ⊩ var x = V k w x
k , w ⊩ Top = ⊤
k , w ⊩ A ⇒ B = ∀ {w′ : W k} → R k w w′ → k , w′ ⊩ A → k , w′ ⊩ B
k , w ⊩ A ∧ B = (k , w ⊩ A) × (k , w ⊩ B)

infix 1 _,_⊩_

-- 唯一用到 R 的是蕴含那行，也是整个语义的**全部要害**：
-- 「w ⊩ A ⇒ B」不是「w ⊩ A 蕴含 w ⊩ B」，而是
-- 「对 w 的**每一个**未来世界 w′，只要那里 A 真，那里 B 也真」。
-- 加上 R 自反，w 自己也在量化范围内。直觉：断言一个蕴含，是断言它在所有
-- 后续认知状态下都不被推翻——今天的我不知道 p⇒q 会不会成立没关系，只要
-- 无论知识怎么增长，一旦 p 冒头 q 就必须跟着冒头。
--
-- 合取就是逐点配对（积类型），真就是 ⊤（永远有证据）。变量交给赋值 V。

-- 把语义从公式抬到上下文：Γ 为真 = Γ 里每条公式都为真（右折叠成积）。
_,_⊩ctxt_ : (k : struct) → W k → Ctxt → Set
k , w ⊩ctxt [] = ⊤
k , w ⊩ctxt (A ∷ Γ) = (k , w ⊩ A) × (k , w ⊩ctxt Γ)

infix 1 _,_⊩ctxt_

------------------------------------------------------------------------
-- ⑤ 一个具体结构 K（原书图 10.8–10.10）
------------------------------------------------------------------------

--      1          2
--    w0 ────→ w1     w2      （w1、w2 极大；p、q 只在 w1、w2 为真）
--        └────────→ w2

data world : Set where
  w0 w1 w2 : world

-- 未来关系：只列出成立的正例（自反边 r00/r11/r22 也在内）。不成立的边
-- 没有构造子，即自动为假——这正是 29 章归纳谓词的「负信息靠缺席」读法。
data rel : world → world → Set where
  r00 : rel w0 w0
  r11 : rel w1 w1
  r22 : rel w2 w2
  r01 : rel w0 w1
  r02 : rel w0 w2

refl-rel : Reflexive rel
refl-rel {w0} = r00
refl-rel {w1} = r11
refl-rel {w2} = r22

-- 传递性：对两个证明做模式匹配，能列出几个可行组合就写几行——
-- 不可能的组合（比如 r11 r01）根本不成类型，不需要写「 absurd 分支」。
trans-rel : Transitive rel
trans-rel r00 r00 = r00
trans-rel r00 r01 = r01
trans-rel r00 r02 = r02
trans-rel r11 r11 = r11
trans-rel r22 r22 = r22
trans-rel r01 r11 = r01
trans-rel r02 r22 = r02

-- 赋值：w1、w2 里 p、q 都为真；w0 里什么都没有。
data val : world → String → Set where
  v1p : val w1 "p"
  v1q : val w1 "q"
  v2p : val w2 "p"
  v2q : val w2 "q"

-- 单调性：从 r00/r11/r22 走一步什么也不变；从 r01/r02 走一步要求
-- 「w0 里为真的变量」——一个构造子都没有，于是 () 吸收（35 章同款）。
mono-val : ∀ {w w′} → rel w w′ → ∀ {x} → val w x → val w′ x
mono-val r00 u = u
mono-val r11 u = u
mono-val r22 u = u
mono-val r01 ()
mono-val r02 ()

K : struct
K = record { W = world; R = rel; reflR = refl-rel; transR = trans-rel
           ; V = val; monoV = mono-val }

-- 语义是**算出来的**，不是猜出来的：以下三条等式都由 refl 接住。
⊩-∧-computes : (K , w1 ⊩ p ∧ q) ≡ (val w1 "p" × val w1 "q")
⊩-∧-computes = refl

⊩-⇒-computes : (K , w0 ⊩ p ⇒ q) ≡
              (∀ {w′ : world} → rel w0 w′ → val w′ "p" → val w′ "q")
⊩-⇒-computes = refl

⊩-ctxt-computes : (K , w1 ⊩ctxt p ∷ q ∷ []) ≡
                 (val w1 "p" × (val w1 "q" × ⊤))
⊩-ctxt-computes = refl

-- 原书 10.3 节的样例：`p ⇒ q` 在 w0 为真。整个证明就是对「w0 到哪些世界」
-- 做模式匹配：r00 那条分支里假设 `val w0 "p"` 是空的，直接 ()。
test-⊩-⇒ : K , w0 ⊩ p ⇒ q
test-⊩-⇒ r00 ()
test-⊩-⇒ r01 _ = v1q
test-⊩-⇒ r02 _ = v2q

-- 反过来的三件事，都是「没有构造子所以不可能」：
no-p-at-w0 : ∀ {A : Set} → K , w0 ⊩ p → A
no-p-at-w0 ()

no-q-at-w0 : ∀ {A : Set} → K , w0 ⊩ q → A
no-q-at-w0 ()

-- w0 里连 p 都没有，但 w1 里有：说明「现在不真」不等于「永远不真」，
-- 这正是直觉主义拒绝排中律的语义空间（14 章那个写不出的 p ⊎ ¬ p，
-- 在这里可以明确地在某个世界里失败）。
p-arrives-later : K , w1 ⊩ p
p-arrives-later = v1p

------------------------------------------------------------------------
-- ⑥ 单调性：真理在未来不消失
------------------------------------------------------------------------

-- 赋值单调（结构要求）→ **任意公式**单调。证明对公式归纳，四个构造子
-- 四个分支；关键是蕴含分支**不递归**。
mono⊩ : ∀ {k : struct} {w w′ : W k} {A : Formula} →
       R k w w′ → k , w ⊩ A → k , w′ ⊩ A
mono⊩ {k = k} {A = var x} r u = monoV k r u
mono⊩ {A = Top} r u = tt
mono⊩ {k = k} {A = A ⇒ B} r u r′ u′ = u (transR k r r′) u′
mono⊩ {A = A ∧ B} r (u₁ , u₂) = mono⊩ {A = A} r u₁ , mono⊩ {A = B} r u₂

-- 变量：直接用结构的 monoV。真：⊤ 白送。合取：拆成两支各自递归。
-- 蕴含：手上是 `u : ∀ {x} → R k w x → k , x ⊩ A → k , x ⊩ B`，目标是
-- `k , w′ ⊩ A ⇒ B`，即对 w′ 的每个未来 w″ 交出 B。已知 R k w w′ 和
-- R k w′ w″，用传递性拼出 R k w w″，再喂给 u。**语义定义里已经把单调性
-- 内置在蕴含的含义中**，所以这一支不需要递归——原书 10.4.1 特别点出这一点。
--
-- 递归只发生在隐式参数 A 上（子句用 `{A = …}` 匹配它）。2.9.0 的终止检查
-- 接受这种写法（实测），因为被模式匹配的隐式参数照样算「可用参数」。

mono⊩ctxt : ∀ {k : struct} {Γ : Ctxt} {w w′ : W k} →
            R k w w′ → k , w ⊩ctxt Γ → k , w′ ⊩ctxt Γ
mono⊩ctxt {Γ = []} r u = tt
mono⊩ctxt {Γ = A ∷ Γ} r (u₁ , u₂) =
  mono⊩ {A = A} r u₁ , mono⊩ctxt {Γ = Γ} r u₂

------------------------------------------------------------------------
-- ⑦ 可靠性定理：可证 ⟹ 在所有 Kripke 结构的所有世界里为真
------------------------------------------------------------------------

-- 语义推论（entailment）：Γ 的每条假设在**任意**结构**任意**世界为真时，
-- 结论也在。注意量词跨越所有 struct，所以 `_⊨_` 在 Set₁。
_⊨_ : Ctxt → Formula → Set₁
Γ ⊨ A = ∀ {k : struct} {w : W k} → k , w ⊩ctxt Γ → k , w ⊩ A

infix 1 _⊨_

-- 证明对**推导**归纳（7 个规则 7 个分支）。这一节是全教程第一次把
-- 「对证明对象归纳」写成完整定理——35 章已经练过规则即构造子，这里加上
-- 语义解释，两侧一夹就是元定理。
soundness : ∀ {Γ A} → Γ ⊢ A →
            ∀ {k : struct} {w : W k} → k , w ⊩ctxt Γ → k , w ⊩ A
soundness id g = proj₁ g
soundness (wk th) g = soundness th (proj₂ g)
soundness (⇒I {Γ} {A} th) g r u = soundness th (u , mono⊩ctxt r g)
soundness (⇒E th₁ th₂) {k} g = soundness th₁ g (reflR k) (soundness th₂ g)
soundness ⊤I g = tt
soundness (∧I th₁ th₂) g = soundness th₁ g , soundness th₂ g
soundness (∧E true th) g = proj₁ (soundness th g)
soundness (∧E false th) g = proj₂ (soundness th g)

-- 逐支读法：
--  * id：假设表里第一个就是 A，而 g 正好是 `(A 真) × (Γ 真)`，取 proj₁。
--  * wk：新假设 B 的证据在 g 的第一支，剩下的第二支喂给递归。
--  * ⇒I：**这里用到单调性**。递归调用要求 `k , w′ ⊩ctxt (A ∷ Γ)`，
--    手上有 `u : k , w′ ⊩ A`（前提：w′ 是 w 的未来）和
--    `g : k , w ⊩ctxt Γ`——Γ 的真只在 **w** 成立，得靠 `mono⊩ctxt r g`
--    把它搬到 w′。这正是可靠性证明唯一一处「非平凡搬运」。
--  * ⇒E：递归得到的 `soundness th₁ g` 是个「对所有未来世界」的函数，
--    用自反性 `reflR k` 把当前世界喂回去，再喂 `soundness th₂ g`。
--  * ∧E：`if true/false then …` 已在类型里约简掉，取投影即可。

-- 用 ⊨ 记号重新陈述同一条定理（类型逐字相等，所以一行就够）。原书把七条
-- 子句直接写在 `Γ ⊨ A` 上；照抄形态在 2.9.0 也过（实测），但那条 ⇒E 子句
-- 里的 `{k}` 是 ⊨ 展开出来的隐式参数，一旦误挂到 ⇒E 自己身上就报
-- WrongHidingInLHS。先写开量词、再一行换名，这笔隐式参数的账就不用猜了。
Soundness : ∀ {Γ A} → Γ ⊢ A → Γ ⊨ A
Soundness = soundness

-- 定理是可以**跑**的：把 ② 的 th-assoc 送进去，在世界 w0 处实例化，
-- 得到一个具体的满足证据（Agda 自己按结构算出来）。
assoc-at-w0 : K , w0 ⊩ (p ∧ q) ∧ r ⇒ p ∧ (q ∧ r)
assoc-at-w0 = Soundness th-assoc {K} {w0} tt

dup-at-w0 : K , w0 ⊩ dup
dup-at-w0 = Soundness th-dup {K} {w0} tt

------------------------------------------------------------------------
-- ⑧ 反模型：Peirce 律在 PPIL 里不可证
------------------------------------------------------------------------

-- 可靠性反过来用就是**不可证性机器**：找一个 Kripke 结构、一个世界，
-- 使公式在那里不为真，则它不可能有证明。经典逻辑的招牌公理 Peirce 律
-- ((p⇒q)⇒p)⇒p 正好只用到 ⇒——PPIL 的语言完全够用。
--
-- 反模型：一条链 p0 ≤ p1 ≤ p2；p 从 p1 起为真，q 处处不为真。
--   · w0 处 (p⇒q) 不为真：往后看 p1，那里 p 真而 q 假。
--   · 于是 (p⇒q)⇒p 在 p0 **意外地**为真：三个未来世界里没有谁满足 (p⇒q)，
--     前件全空转。
--   · 但 p 在 p0 不为真，所以 ((p⇒q)⇒p)⇒p 在 p0 崩掉。

data pworld : Set where
  z0 z1 z2 : pworld

data prel : pworld → pworld → Set where
  t00 : prel z0 z0
  t11 : prel z1 z1
  t22 : prel z2 z2
  t01 : prel z0 z1
  t12 : prel z1 z2
  t02 : prel z0 z2

prefl-prel : Reflexive prel
prefl-prel {z0} = t00
prefl-prel {z1} = t11
prefl-prel {z2} = t22

ptran-prel : Transitive prel
ptran-prel t00 u = u
ptran-prel t11 t11 = t11
ptran-prel t11 t12 = t12
ptran-prel t12 t22 = t12
ptran-prel t22 t22 = t22
ptran-prel t01 t11 = t01
ptran-prel t01 t12 = t02
ptran-prel t02 t22 = t02

-- p 在 z1、z2 为真；q 一个构造子都没有。
data pval : pworld → String → Set where
  u1p : pval z1 "p"
  u2p : pval z2 "p"

pmono-pval : ∀ {w w′} → prel w w′ → ∀ {x} → pval w x → pval w′ x
pmono-pval t00 ()
pmono-pval t11 u = u
pmono-pval t22 u = u
pmono-pval t01 ()
pmono-pval t12 u1p = u2p
pmono-pval t02 ()

P : struct
P = record { W = pworld; R = prel; reflR = prefl-prel; transR = ptran-prel
           ; V = pval; monoV = pmono-pval }

-- 空类型的通用消去：形如 `∀ {A : Set} → 空类型 → A`，零条子句即可
-- （Agda 认出值域没有构造子）。这是「证明某类型无元素」的标准写法。
p-not-at-z0 : ∀ {A : Set} → P , z0 ⊩ p → A
p-not-at-z0 ()

p-not-q-at-z1 : ∀ {A : Set} → P , z1 ⊩ q → A
p-not-q-at-z1 ()

-- 第一步：(p⇒q)⇒p 在 z0 确实为真（前件在所有未来世界里都落空）。
peirce-antecedent : P , z0 ⊩ (p ⇒ q) ⇒ p
peirce-antecedent t00 u = p-not-q-at-z1 (u t01 u1p)
peirce-antecedent t01 u = u1p
peirce-antecedent t02 u = u2p

-- 第二步：把它递到最外层，z0 处要求 p——拿不到，于是 Peirce 在 z0 不为真。
peirce-not-⊩ : ¬ (P , z0 ⊩ Peirce)
peirce-not-⊩ h = p-not-at-z0 (h t00 peirce-antecedent)

-- 第三步：可靠性定理收尾。若有证明，则在 P 的 z0 为真；矛盾。
not-Peirce : ¬ ([] ⊢ Peirce)
not-Peirce h = peirce-not-⊩ (Soundness h {P} {z0} tt)

-- 14 章的对照：那里「DNE / Peirce 写不出来」只能靠 Agda 报
-- UnsolvedMetaVariables 当证据；现在证据是一条**构造出来的反模型**，
-- 外加一个类型检查通过的定理。负元数学结果也可以是机器验证的。
