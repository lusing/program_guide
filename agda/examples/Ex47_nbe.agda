------------------------------------------------------------------------
-- 第 47 章配套示例：完全性定理与 normalization by evaluation
--
-- 承接 46 章（Ex46_ppil_kripke 提供公式、证明、结构、⊩ 语义、单调性、
-- 可靠性），这一章走完原书第 10 章的后半（10.5 节）：
--   ① 上下文扩张 Γ ¤ Γ′ 与它的传递性、随之而来的 weaken¤；
--   ② **通用结构 U**：世界就是上下文，未来就是扩张，变量为真就是可证；
--   ③ SoundnessU / CompletenessU 互归纳（U 上的 adequacy）；
--   ④ ctxt-id → Completeness（语义推论 ⟹ 句法证明）→ 两条 universality；
--   ⑤ nbe = Completeness ∘ Soundness：**把可靠性+完全性两次证明合起来跑，
--      得到一个 PPIL 证明的归一化器**，六个算例全部由 refl 接住。
--
-- 移植说明（原书 Agda 2.2.14 + IAL → 本机 2.9.0 + stdlib 3.0）：
--  * 原书 `struct`/`W`/`R`/`V` 全部复用 46 章的定义，只是 record 字段少了
--    preorder 打包；
--  * 通用结构 U 的 `V = λ Γ x → Γ ⊢ var x`、`monoV = λ d th → weaken¤ d th`
--    这两行的**类型推断**边界，原书专门提醒过：写 lambda 能过、直接写
--    `monoV = weaken¤` 不过。2.9.0 行为一致（实测，见本章坑位清单）。
--  * 46 章把可靠性写成 `soundness`（量词展开）+ 一行 `Soundness = soundness`
--    （换回 `⊨` 记号）两步；本章的完全性只有一条子句，直接写在 `⊨` 上即可，
--    但**用**它的时候撞上另一道坎：闭合的 `¬ ([] ⊨ Peirce)` 在子句里会被
--    展开到见骨，隐式参数对不上，只能点对面写（见坑位清单）。
--
-- 类型检查：cd agda && ./build.sh Ex47_nbe
------------------------------------------------------------------------

module Ex47_nbe where

open import Data.Bool using (true; false)
open import Data.List using (List; []; _∷_)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Unit using (⊤; tt)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Relation.Nullary using (¬_)

open import Ex46_ppil_kripke

-- struct 是 46 章的 record；重新 open 一次才拿得到字段投影 W / V / …
open struct

------------------------------------------------------------------------
-- ① 上下文扩张：Γ ¤ Γ′
------------------------------------------------------------------------

-- 读作「Γ′ 是 Γ 的一次扩张」——往左边陆续加假设得到的上下文。原书给它的
-- 两条规则（自反 + 左加一条假设）照做成构造子（规则即数据，35、46 章同款）。
data _¤_ : Ctxt → Ctxt → Set where
  ¤-refl : ∀ {Γ} → Γ ¤ Γ
  ¤-cons : ∀ {Γ Γ′ A} → Γ ¤ Γ′ → Γ ¤ (A ∷ Γ′)

infix 1 _¤_

¤-trans : ∀ {Γ Γ′ Γ″} → Γ ¤ Γ′ → Γ′ ¤ Γ″ → Γ ¤ Γ″
¤-trans u ¤-refl = u
¤-trans u (¤-cons d) = ¤-cons (¤-trans u d)

-- 逻辑上的 weakening 换一副面孔：可证性对**上下文扩张**单调。
weaken¤ : ∀ {Γ Γ′ A} → Γ ¤ Γ′ → Γ ⊢ A → Γ′ ⊢ A
weaken¤ ¤-refl th = th
weaken¤ (¤-cons d) th = wk (weaken¤ d th)

------------------------------------------------------------------------
-- ② 通用结构 U：把证明本身当世界
------------------------------------------------------------------------

-- 这是整个完全性证明的枢纽，也是原书 10.5.1 节所谓「看似更强的构造」：
--   · 世界 = 上下文 Γ（所有可能的假设表都是世界）；
--   · 未来关系 = 扩张关系 ¤（未来的世界就是「知道得更多」的假设表）；
--   · 赋值：变量 x 在世界 Γ 为真 ⟺ Γ ⊢ var x **可证**。
-- 最后一条是把句法塞进语义里做锚点：正因为这样，后面 adequacy 的
-- 变量分支才会「逐字相等」，两边都不用证。
U : struct
U = record { W = Ctxt
           ; R = _¤_
           ; reflR = ¤-refl
           ; transR = ¤-trans
           ; V = λ Γ x → Γ ⊢ var x
           ; monoV = λ d th → weaken¤ d th }

-- 两处类型推断的细节（原书特别提醒，2.9.0 实测一致）：
--  * `reflR = ¤-refl` 能过，因为 `Reflexive _¤_` 展开就是 `∀ {Γ} → Γ ¤ Γ`；
--  * `monoV` 必须写成 lambda `λ d th → weaken¤ d th`，直接给 `weaken¤`
--    会卡在隐式参数上（weaken¤ 的量化顺序是 {Γ Γ′ A}，monoV 要的是
--    {w w′} … {x}，Agda 推不出这个特化）。

------------------------------------------------------------------------
-- ③ Adequacy：U 上「可证 ⟺ 为真」，两条互归纳
------------------------------------------------------------------------

mutual
  -- 为真 ⟹ 可证（完全性的核心）
  CompletenessU : ∀ {A : Formula} {Γ : W U} → U , Γ ⊩ A → Γ ⊢ A
  -- 可证 ⟹ 为真（相对 U 的可靠性，比 46 章的 Soundness 更「贴脸」）
  SoundnessU : ∀ {A : Formula} {Γ : W U} → Γ ⊢ A → U , Γ ⊩ A

  CompletenessU {A = var x} u = u
  CompletenessU {A = Top} u = ⊤I
  CompletenessU {A = B ∧ C} u =
    ∧I (CompletenessU {A = B} (proj₁ u)) (CompletenessU {A = C} (proj₂ u))
  CompletenessU {A = B ⇒ C} {Γ} u =
    ⇒I (CompletenessU {A = C}
          (u (¤-cons ¤-refl) (SoundnessU {A = B} (id {Γ} {B}))))

  SoundnessU {A = var x} th = th
  SoundnessU {A = Top} th = tt
  SoundnessU {A = B ∧ C} th =
    SoundnessU {A = B} (∧E true th) , SoundnessU {A = C} (∧E false th)
  SoundnessU {A = B ⇒ C} th r u =
    SoundnessU (⇒E (weaken¤ r th) (CompletenessU {A = B} u))

-- 为什么非要**互相**归纳？两个 ⇒ 分支各调用对方一次：
--  * CompletenessU 的 ⇒ 分支要往未来世界 `B ∷ Γ` 递推，可那里能用的信息是
--    「U , B ∷ Γ ⊩ B」，而 u 要的正是这个——手上只有证明 `B ∷ Γ ⊢ B`（id），
--    得先用 SoundnessU 翻成语义侧的证据；
--  * SoundnessU 的 ⇒ 分支反过来：手上的 u 是语义侧的「B 在未来世界为真」，
--    要和句法的 `Γ ⊢ B ⇒ C` 做 ⇒E，就得先用 CompletenessU 把它翻回句法侧。
-- 换句话说：**每一次跨越句法/语义边界，都要借对方一次力**。这正是
-- normalization by evaluation 的机械内核：先把证据搬到语义域里求值，
-- 再反射回句法。下面 ⑤ 把它单独拆成一个函数 nbe。
--
-- 变量分支两边都是「同一句话」：`U , Γ ⊩ var x` 按定义就是 `Γ ⊢ var x`，
-- 所以 `u = u`、`th = th`——赋值 V 那样设计，全是为了这一刻。
--
-- 归纳指标都是隐式的公式 A（46 章已实测 2.9.0 接受这种写法）；两个函数在
-- mutual 块里彼此调用，终止检查同样只看 A 是否在变小。

------------------------------------------------------------------------
-- ④ 完全性定理与 U 的普遍性
------------------------------------------------------------------------

-- 先证一条小引理：在 U 里，每个世界 Γ 都满足它自己的全部假设。
ctxt-id : ∀ {Γ : Ctxt} → U , Γ ⊩ctxt Γ
ctxt-id {[]} = tt
ctxt-id {A ∷ Γ} = SoundnessU {A = A} id , mono⊩ctxt (¤-cons ¤-refl) ctxt-id

-- 合取支用 `SoundnessU id` 拿到（`A ∷ Γ ⊢ A` 翻成 `U , A ∷ Γ ⊩ A`），尾巴
-- 用单调性从 Γ 搬到 A ∷ Γ——46 章可靠性里那唯一一处搬运，在这里复用了。

-- 完全性：语义推论 ⟹ 句法证明。
Completeness : ∀ {Γ A} → Γ ⊨ A → Γ ⊢ A
Completeness {Γ} h = CompletenessU (h {U} {Γ} ctxt-id)

-- 读法：h 对**所有**结构成立，那就专门喂给它一个结构——U，和世界 Γ。
-- 看起来是「更强的要求」被我们**主动削弱**成一次性实例，代价只是补一个
-- `ctxt-id`。完全性证明的全部技巧就在这一步选材。

-- 完全性立刻给出「反否」形态：不可证 ⟹ 不是语义推论。它的用处是**造反
-- 模型**——手上有一个「不可证」的否定证明，就得到一个「在某个世界不为真」
-- 的语义事实。
Not-valid : ∀ {Γ A} → ¬ (Γ ⊢ A) → ¬ (Γ ⊨ A)
Not-valid np h = np (Completeness h)

-- `¬ (Γ ⊨ A)` 敢这么写，是因为 stdlib 3.0 的 `¬_` 是**层级多态**的
-- （Relation.Nullary.Negation.Core 第 26 行：`¬_ : Set a → Set a`），
-- 住在 Set₁ 的 `Γ ⊨ A` 照样能被否定（2.9.0 实测；若写成 `Set → Set`
-- 的老式否定就得手挖箭头了）。

-- U 的普遍性：在 U 里为真 ⟺ 处处为真。
Universality1 : ∀ {Γ A} → Γ ⊨ A → U , Γ ⊩ A
Universality1 {Γ} {A} h = SoundnessU (Completeness {Γ} {A} h)

Universality2 : ∀ {Γ A} → U , Γ ⊩ A → Γ ⊨ A
Universality2 {Γ} {A} u = Soundness (CompletenessU {A = A} {Γ} u)

-- 于是「在 U 这一个结构里为真」与「在所有结构里为真」等价：通用结构
-- 名副其实。

-- 46 章那台反模型机器现在双向可用了。Peirce 律不可证（46 章靠 P 那台
-- 反模型 + 可靠性拿到），套上 Not-valid 就得到「Peirce 律不是语义推论」。
-- 这一句必须**点对面**写。η-展开成 `peirce-not-valid h = Not-valid not-Peirce h`
-- 会挂：子句的假设类型是**闭合**的 `¬ ([] ⊨ Peirce)`，Agda 2.9.0 在进入
-- 子句时把它一路展开成 `∀ {k} {w} → k , w ⊩ctxt [] → k , w ⊩ Peirce`，
-- 于是 `Not-valid` 那对隐式参数 `?Γ ⊨ ?A` 再也对不上（实测报
-- `_k.V_176 w′ "p" =< V k w′ "p" (blocked on _k.V_176)` +
-- UnsolvedMetaVariables）。点对面写时两边都还是折叠形态的 `Γ ⊨ A`，一步
-- 对上。详见本章坑位清单。
peirce-not-valid : ¬ ([] ⊨ Peirce)
peirce-not-valid = Not-valid not-Peirce

-- 同一条否定，换成语义侧**小类型**上的形态就没有上面那笔账要算：
-- `U , [] ⊩ Peirce` 住在 Set，展开后不含 record 字段，点对点写照常通过。
peirce-not-⊩-at-U : ¬ (U , [] ⊩ Peirce)
peirce-not-⊩-at-U h = not-Peirce (CompletenessU {A = Peirce} {[]} h)

------------------------------------------------------------------------
-- ⑤ nbe：把两条定理合成一台归一化器
------------------------------------------------------------------------

-- 类型上看毫无信息：`Γ ⊢ A → Γ ⊢ A`。可它是**计算**：Soundness 把证明
-- 编译成 Agda 函数（⇒I 变 λ、⇒E 变应用、id 变「取上下文里的证据」），
-- Agda 自己把这些 β-红约化掉，Completeness 再把结果读回证明。
nbe : ∀ {Γ A} → Γ ⊢ A → Γ ⊢ A
nbe {Γ} th = Completeness (Soundness th)

-- 下面六个算例 a–f 取自原书，全部由 refl 验收。

-- 例 a：绕了一圈的 ⊤（先合取引入再消去）。归一化 ⟹ ⊤I。
ex-a : [] ⊢ Top
ex-a = ∧E true (∧I ⊤I ⊤I)

ex-a-nbe : nbe ex-a ≡ ⊤I
ex-a-nbe = refl

-- 例 b：两次蕴含「自我应用」的 ⊤。同样塌回 ⊤I——原书指出，对**任何**
-- ⊤ 的证明，nbe 都返回 ⊤I（因为 CompletenessU 的 Top 分支压根不看输入）。
ex-b : [] ⊢ Top
ex-b = ⇒E (⇒E (⇒I (⇒I id)) ⊤I) ⊤I

ex-b-nbe : nbe ex-b ≡ ⊤I
ex-b-nbe = refl

-- 「任何 ⊤ 的证明都归一成 ⊤I」不止是观察，它可以做成定理（实测 refl 直接
-- 接住）：原因就在 CompletenessU 的 Top 分支不看输入，所以 th 连用都不用上。
top-all-nbe : ∀ {Γ} (th : Γ ⊢ Top) → nbe th ≡ ⊤I
top-all-nbe th = refl

-- 例 c：p ⇒ p 的啰嗦证明（引入又消去同一个蕴含）。
ex-c : [] ⊢ p ⇒ p
ex-c = ⇒I (⇒E (⇒I id) id)

ex-c-nbe : nbe ex-c ≡ ⇒I id
ex-c-nbe = refl

-- 例 d：要用到假设的证明——q ⊢ p ⇒ q。归一化后剩下的正是 `⇒I (wk id)`：
-- 跳过 p 去拿假设 q（weaken 在这里就是「de Bruijn 位移」）。
ex-d : q ∷ [] ⊢ p ⇒ q
ex-d = ⇒I (⇒E (wk (⇒I (wk id))) id)

ex-d-nbe : nbe ex-d ≡ ⇒I (wk id)
ex-d-nbe = refl

-- 例 e：**变长**的反例。假设本身是复合公式（p ∧ q），SoundnessU 会按公式
-- 结构把 id 拆开重装，于是 nbe 输出比输入更长。
ex-e : [] ⊢ (p ∧ q) ⇒ p ∧ q
ex-e = ⇒I id

ex-e-nbe : nbe ex-e ≡ ⇒I (∧I (∧E true id) (∧E false id))
ex-e-nbe = refl

-- 例 f：同一现象的蕴含版——假设是 p ⇒ q，被展开成一次 ⇒E。
ex-f : [] ⊢ (p ⇒ q) ⇒ (p ⇒ q)
ex-f = ⇒I id

ex-f-nbe : nbe ex-f ≡ ⇒I (⇒I (⇒E (wk id) id))
ex-f-nbe = refl

-- 归一化器是**投影**，不是幂等之外的什么魔法：对 e 的结果再跑一次 nbe，
-- 不动了。
ex-e-nbe-nbe : nbe (nbe ex-e) ≡ nbe ex-e
ex-e-nbe-nbe = refl

-- 顺带一条：已经是正规式的证明，nbe 保持原样（对照 45 章 `run ... ≡ ...`
-- 那条 refl：定理算出来的东西，可以在类型层面被验收）。这里必须给
-- `⇒I id` 起一个**带类型标注**的名字再喂给 nbe——裸写 `nbe (⇒I id)` 会留下
-- 一个推不出来的隐式参数：`⇒I id` 对**任何**公式 A 都是 `A ⇒ A` 的证明，
-- 而 nbe 恰恰要按 A 的结构来归一化（详见本章坑位清单）。
th-c-normal : [] ⊢ p ⇒ p
th-c-normal = ⇒I id

ex-c-idem : nbe th-c-normal ≡ ⇒I id
ex-c-idem = refl

-- Curry–Howard 的最后一层窗户纸：PPIL 的证明 = 简单类型 λ 演算的项，
-- ⇒I 是 λ、⇒E 是应用、id 是变量、wk 是变量位移。于是 nbe 不是一个「证明
-- 化简玩具」，它是一台**用真值语义写出来的 λ 演算求值器**：先求值（到
-- 语义域里的 Agda 函数），再反射回语法。这就是 normalization by evaluation。

