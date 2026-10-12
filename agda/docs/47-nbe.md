# 47 · 完全性定理与 normalization by evaluation：把两条元定理合成一台机器

> **第十部分 · 元理论（46–47）** ｜ 全书结构与阅读路线见 [README](../README.md)

46 章证的是可靠性：`Γ ⊢ A → Γ ⊨ A`——句法不会说谎。本章证反方向：

> **完全性**（Completeness）：`Γ ⊨ A → Γ ⊢ A`——语义不会说谎。
> 如果 A 在**所有** Kripke 结构、**所有**世界里都成立（只要假设成立），
> 那 A 一定有推导。

两侧夹起来，中间掉出一台机器。这是全教程唯一一处「定理证明本身算出了
东西」的场合：`Completeness ∘ Soundness` 的类型是 `Γ ⊢ A → Γ ⊢ A`，看着
像恒等函数，实际是**证明的归一化器**（normalization by evaluation）——
把推导编译成 Agda 函数、让 Agda 做完 β-约简、再把结果读回推导。六个算例
全部用 `refl` 验收，包括两条「输出比输入更长」的反直觉例子。

对应示例：`../examples/Ex47_nbe.agda`（复用 `../examples/Ex46_ppil_kripke.agda`）

**实测口径**：本章代码与报错原文均为 **Agda 2.9.0 + stdlib 3.0** 本机实测
（复现：`cd agda && ./build.sh Ex47_nbe`；报错来自写完示例后逐条改坏的临时
探针，跑完即删）。内容取材 Aaron Stump《Verified Functional Programming in
Agda》第 10 章后半（通用结构、完全性、NBE 那一节），已重写为自包含叙述，
读完本章不需要再翻原书。

## 47.1 完全性为什么难：全称量词在假设里

先看清对手的形状。要证的是一条 `∀`：

```text
Γ ⊨ A  =  ∀ {k : struct} {w : W k} → k , w ⊩ctxt Γ → k , w ⊩ A
            ↑ 量词跨过所有 Kripke 结构
```

手上有一个**对一切结构都成立**的事实，要造一个**句法**对象（证明）。常规
打法立刻碰壁：语义那侧的量化范围太大，而证明必须是有限项。逻辑课本的
标准答案在这里同样适用，但要花点力气看清它在 Agda 里长什么样：

- 经典逻辑的完全性：挑那个「一切」里最有代表性的模型（真值表全体赋值）。
- 直觉主义逻辑的完全性（本章）：**自己造一个结构**，让它的每个世界
  「知道的东西恰好是它能证明的东西」。这个结构叫**通用结构** U。

选 U 的理由是它满足一个更强的假设（对所有结构成立 ⟹ 对 U 成立是白送的），
而代价只有一个小的技术引理（U 里每个世界满足自己的假设，47.5 的
`ctxt-id`）。看起来是「更强的要求」被我们**主动削弱**成一次性实例——
完全性证明的全部技巧就在这一步选材。

本章的路线：

```text
① Γ ¤ Γ′  上下文扩张关系（未来的句法化身）
② U       通用结构：世界 = 上下文，未来 = ¤，赋值 = 可证
③ adequacy：U 上「可证 ⟺ 为真」，两条互归纳 SoundnessU / CompletenessU
④ ctxt-id → Completeness → Not-valid / Universality
⑤ nbe = Completeness ∘ Soundness：一台真的归一化器，refl 验收
```

## 47.2 开场：把 46 章全部搬进来

跨示例复用文件在本教程有先例（16 章 import 15 章）。本章的 import 只补
46 章没暴露的部分：

```agda
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
```

`Formula`、`_⊢_`、`struct`、`_,_⊩_`、`mono⊩ctxt`、`_⊨_`、`Soundness`、
`Peirce`、`not-Peirce` 全部来自 46 章——注意 `open import` 只把**定义**带进来，
record 的字段投影不跟着走：不补最后一行 `open struct`，第一次写 `W U` 就报
`Not in scope: W`（原文见坑位 1）。`true`/`false` 也得重新 import，因为
46 章 `open import Data.Bool using (…)` 的结果同样不外传（坑位 2）。

## 47.3 上下文扩张：`Γ ¤ Γ′`

Kripke 结构需要「未来」关系。U 的世界是上下文，未来就该是「假设变多」：

```agda
data _¤_ : Ctxt → Ctxt → Set where
  ¤-refl : ∀ {Γ} → Γ ¤ Γ
  ¤-cons : ∀ {Γ Γ′ A} → Γ ¤ Γ′ → Γ ¤ (A ∷ Γ′)

infix 1 _¤_
```

读作「Γ′ 是 Γ 的一次扩张」——从 Γ 出发往左陆续加假设能到达 Γ′。两条规则
做成两个构造子（35、46 章同款的老手艺）：`¤-refl` 说原地不动也算，
`¤-cons` 说加一条假设仍是扩张。`infix 1`：和三个 turnstile 一样，级别要比
连接词松。

预序的两条要求各自一句话：

```agda
¤-trans : ∀ {Γ Γ′ Γ″} → Γ ¤ Γ′ → Γ′ ¤ Γ″ → Γ ¤ Γ″
¤-trans u ¤-refl = u
¤-trans u (¤-cons d) = ¤-cons (¤-trans u d)
```

对第二个证明归纳：`¤-refl` 什么都不加，原样给回；`¤-cons` 剥一层再递归。
注意 `u` 在两支里都被重复使用——它是「Γ 到中间点」的那段扩张，被完整搬到
结果里。

然后是 46.4 那条 `wk` 换一副面孔：

```agda
weaken¤ : ∀ {Γ Γ′ A} → Γ ¤ Γ′ → Γ ⊢ A → Γ′ ⊢ A
weaken¤ ¤-refl th = th
weaken¤ (¤-cons d) th = wk (weaken¤ d th)
```

「可证性对上下文扩张单调」。递归走完 `¤` 有几步，就给 `th` 套几层 `wk`。
`¤-refl` 那支一步不加，`th` 原样交。这条引理马上要去做 U 的 `monoV`——
**同一个 weakening 事实在 46 章是逻辑侧的结构规则，在这里是语义侧的单调性
公理**，一副内容的两张面孔，这正是「通用结构」的构造逻辑。

## 47.4 通用结构 U：把证明当世界

U 是整个证明的枢纽，五行 record：

```agda
U : struct
U = record { W = Ctxt
           ; R = _¤_
           ; reflR = ¤-refl
           ; transR = ¤-trans
           ; V = λ Γ x → Γ ⊢ var x
           ; monoV = λ d th → weaken¤ d th }
```

三条设计决定：

- **世界 = 上下文**（`W = Ctxt`）。所有可能的假设表都是世界。
- **未来 = 扩张**（`R = _¤_`）。未来的世界就是「知道得更多」的假设表；
  预序两条直接由 `¤-refl`/`¤-trans` 交出来——`reflR = ¤-refl` 能过，是因为
  `Reflexive _¤_` 展开就是 `∀ {Γ} → Γ ¤ Γ`，逐字同一个类型。
- **赋值 = 可证性**（`V = λ Γ x → Γ ⊢ var x`）：变量 x 在世界 Γ 为真
  **当且仅当** `Γ ⊢ var x` 可证。

最后一条是把句法塞进语义里做锚点，它是 47.5 那两条互归纳的变量分支能
「逐字相等、两边都不证」的唯一原因。这也是完全性证明最反直觉的一处：
语义结构里混进了句法。原书为此特别叮嘱过，值得实测一下边界：

```text
U = record { … ; monoV = weaken¤ }        -- 不过
U = record { … ; monoV = λ d th → weaken¤ d th }   -- 过（示例采用）
```

直接给 `weaken¤` 报（原文见坑位 3）：

```text
error: [UnequalTypes]
The function type
  w ⊢ _A_51 → w′ ⊢ _A_51
is not a subtype of
  {x : Agda.Builtin.String.String} → w ⊢ var x → w′ ⊢ var x
because:
  one takes a visible argument, while the other takes a hidden
  argument.
```

差异的根源：`weaken¤` 的隐式参数组是 `∀ {Γ Γ′ A}`，而 `monoV` 要的形状是
`∀ {w w′} → R w w′ → ∀ {x} → V w x → V w′ x`——`x` 藏在**后半段**，而且
`V w x` 得先算出 `Γ ⊢ var x` 才能对齐 `Γ ⊢ A`。包一层 lambda 相当于把
「按 monoV 的形状逐段接收参数」这件事写明，Agda 于是把 `A` 特化成
`var x`。这是 2.9.0 的推断边界，不是逻辑边界。

## 47.5 Adequacy：两条互归纳

U 建好了，正式定理的形状是「在 U 里，可证 ⟺ 为真」。两个方向都要，而且
**互相递归**：

```agda
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
```

`mutual` 块的写法照例是「两条签名先写全，再写两组子句」，因为彼此递归时
对方的类型必须已知。归纳指标都是**隐式**的公式 `A`（子句用 `{A = …}` 匹配
它），46.9 已实测 2.9.0 接受这种写法；两个函数在 mutual 块里互相调用，
终止检查同样只看 `A` 是否在变小。

先看两个**变量**分支：

```agda
CompletenessU {A = var x} u = u
SoundnessU {A = var x} th = th
```

`u = u`、`th = th`——不是偷懒，是 `U , Γ ⊩ var x` 按 47.4 的 `V` 定义**就是**
`Γ ⊢ var x`，两侧是同一个类型，所以两条互逆函数都是恒等。赋值 `V` 那样设计，
全是为了这一刻。这是通用结构技巧的全部红利：把最基础的一层（变量的真假）
做成定义上重合，剩下三层才需要真正干活。

`Top` 分支：`CompletenessU u = ⊤I`——不看 `u`，直接给公理证明（`U , Γ ⊩ Top`
按定义就是 `⊤`，输入身上本来就没有信息可挖）。`SoundnessU th = tt` 同理。
这两行在后面 47.7 的算例里造成一条反直觉现象（例 b：任何 `Γ ⊢ Top` 的证明
都归一化成同一个 `⊤I`）。

`∧` 分支是纯粹的机械拆解：一边把积拆开各自递归再 `∧I` 装回，另一边把
`∧E true/false` 分头送出再配对。两边都是「按公式结构走」。

真正需要读三个分支的是两个蕴含。先看 `SoundnessU` 的 ⇒（可证 ⟹ 为真）：

```agda
  SoundnessU {A = B ⇒ C} th r u =
    SoundnessU (⇒E (weaken¤ r th) (CompletenessU {A = B} u))
```

目标 `U , Γ ⊩ B ⇒ C`，按 46.6 的定义，就是要吃一个未来地址 `r : Γ ¤ Γ′`
和 `u : U , Γ′ ⊩ B`，吐出 `U , Γ′ ⊩ C`。手上有 `th : Γ ⊢ B ⇒ C`。要把它
用 ⇒E 消掉，第二前提得是**句法侧**的 `Γ′ ⊢ B`，而 `u` 是语义侧的
`U , Γ′ ⊩ B`——于是先 `CompletenessU {A = B} u` 翻回句法。第一前提
`th : Γ ⊢ B ⇒ C` 活在 Γ，得沿 `r : Γ ¤ Γ′` 抬到 Γ′，这就是 47.3 的
`weaken¤ r th`。`⇒E` 得到 `Γ′ ⊢ C`，最后再 `SoundnessU` 送回来（递归指标
`C` 比 `B ⇒ C` 小）。

`CompletenessU` 的 ⇒ 反过来：

```agda
  CompletenessU {A = B ⇒ C} {Γ} u =
    ⇒I (CompletenessU {A = C}
          (u (¤-cons ¤-refl) (SoundnessU {A = B} (id {Γ} {B}))))
```

目标 `Γ ⊢ B ⇒ C`，用 `⇒I`：进到 `B ∷ Γ` 里证 `C`。手上的 `u` 是
`U , Γ ⊩ B ⇒ C`，即「对 Γ 的每个未来，若 B 真则 C 真」。要触发它，得给它
两样东西：

- 一个未来地址：`¤-cons ¤-refl : Γ ¤ (B ∷ Γ)`——从 Γ 走 `¤-refl` 原地不动，
  再 `¤-cons` 左加 `B`。**这一项就是「把 B 挂进假设表」这句法的语义化身**，
  它正是 ⇒I 引入的那个新世界的地址。
- B 在那个世界里为真：手上只有证明 `B ∷ Γ ⊢ B`（公理 `id`），要翻成语义侧，
  所以是 `SoundnessU {A = B} (id {Γ} {B})`。

于是 `u … : U , B ∷ Γ ⊩ C`，递归 `CompletenessU {A = C}` 得到
`B ∷ Γ ⊢ C`，外面套 `⇒I`。`{Γ}` 必须留在左端，因为右端 `id {Γ} {B}` 要
**提名**这个上下文（实测去掉报 `Not in scope: Γ`，坑位 4）；而 `id` 身上那对
钉参数 `{Γ} {B}` 是给读者看的，Agda 自己推得出来（实测去掉照样过）。

**为什么非要互相归纳？** 把两个 ⇒ 分支并排看就清楚了：它们各自调用对方
一次——`CompletenessU` 的 ⇒ 要用 `SoundnessU` 把 `id` 送到语义侧，
`SoundnessU` 的 ⇒ 要用 `CompletenessU` 把 `u` 送回句法侧。换句话说：

> 每一次跨越句法/语义边界，都要借对方一次力。

这条「借一次力」的递归，正是 47.7 那台归一化器的机械内核：先把证据搬到
语义域（Agda 函数），在那里计算（β-约简自动发生），再反射回句法。

## 47.6 完全性定理

 Adequacy 是「U 上可证 ⟺ 为真」，而完全性要的是「处处为真 ⟹ 可证」，中间
还差一步：**每个世界都满足它自己的假设**。

```agda
ctxt-id : ∀ {Γ : Ctxt} → U , Γ ⊩ctxt Γ
ctxt-id {[]} = tt
ctxt-id {A ∷ Γ} = SoundnessU {A = A} id , mono⊩ctxt (¤-cons ¤-refl) ctxt-id
```

对上下文归纳。空的给 `tt`；非空的是个积：第一支 `A 在 A ∷ Γ 里为真`，由
公理 `id : A ∷ Γ ⊢ A` 过 `SoundnessU` 翻译而来；第二支「Γ 的其余假设在
A ∷ Γ 里为真」，递归给的证据只活在**Γ**（旧世界），要靠 46.9 的
`mono⊩ctxt` 沿 `¤-cons ¤-refl` 搬到新未来。46 章可靠性里那唯一一处非平凡
搬运，在这里原样复用了一次。

定理本体一行：

```agda
Completeness : ∀ {Γ A} → Γ ⊨ A → Γ ⊢ A
Completeness {Γ} h = CompletenessU (h {U} {Γ} ctxt-id)
```

读法：`h` 对**所有**结构、所有世界成立，那就专门喂给它一个结构——`{U}`，
和世界 `{Γ}`，再交出「Γ 在 Γ 里为真」的 `ctxt-id`。`h {U} {Γ} ctxt-id`
的类型是 `U , Γ ⊩ A`，`CompletenessU` 把它翻译成 `Γ ⊢ A`。整条完全性定理
就是这么一点代码：选材（U）+ 一句实例化 + adequacy。

完全性立刻给出「反否」形态：不可证 ⟹ 不是语义推论。它的用处是**造反模型**——
手上有一个「不可证」的否定证明，就得到一个「在某个世界不为真」的语义事实：

```agda
Not-valid : ∀ {Γ A} → ¬ (Γ ⊢ A) → ¬ (Γ ⊨ A)
Not-valid np h = np (Completeness h)
```

`¬ (Γ ⊨ A)` 敢这么写，是因为 stdlib 3.0 的 `¬_` 是**层级多态**的
（`Relation/Nullary/Negation/Core.agda` 第 26 行：`¬_ : Set a → Set a`），
住在 Set₁ 的 `Γ ⊨ A` 照样能被否定（实测；换成只吃 `Set` 的老式否定就得手挖
箭头了）。

两条 universality 说明 U 确实是「通用」的：在 U 里为真与处处为真等价。

```agda
Universality1 : ∀ {Γ A} → Γ ⊨ A → U , Γ ⊩ A
Universality1 {Γ} {A} h = SoundnessU (Completeness {Γ} {A} h)

Universality2 : ∀ {Γ A} → U , Γ ⊩ A → Γ ⊨ A
Universality2 {Γ} {A} u = Soundness (CompletenessU {A = A} {Γ} u)
```

两条都是「先穿过句法一次再出来」：`Universality1` 用完全性把处处为真变成
证明，再用 U 上的可靠性变成 U 里为真；`Universality2` 反过来，用
`CompletenessU` 把 U 里为真变成证明，再用 46 章的全称可靠性 `Soundness`
散开到所有结构。**跨层必须走句法**这件事本身就是元定理的构造性特征。

46 章那台反模型机器现在双向可用了。Peirce 律不可证（46 章靠 P 那台反模型
+ 可靠性拿到），套上 `Not-valid` 就得到「Peirce 律不是语义推论」：

```agda
peirce-not-valid : ¬ ([] ⊨ Peirce)
peirce-not-valid = Not-valid not-Peirce
```

这一句必须**点对面**写。`peirce-not-valid h = Not-valid not-Peirce h`
（η-展开）实测**不过**：子句的假设类型是**闭合**的 `¬ ([] ⊨ Peirce)`，
Agda 2.9.0 进入子句时把它一路展开到见骨（`∀ {k} {w} → k , w ⊩ctxt [] →
k , w ⊩ Peirce`），`Not-valid` 那对隐式参数 `?Γ ⊨ ?A` 就再也对不上了，报
`_k.V_176 w′ "p" =< V k w′ "p" (blocked on _k.V_176)` +
UnsolvedMetaVariables（原文见坑位 5）。点对面写时两边都还是折叠形态的
`Γ ⊨ A`，一步对上；显式钉 `{Γ = []} {A = Peirce}` 也救不回来（同一条实测
结论，坑位 5）。这种「同一个定理，η-展开后过不了类型检查」的现象在Agda 里
是**推断层面**的，不是逻辑层面的——两个写法说的是同一件事。

麻烦只属于 `⊨`（它量化在所有 struct 上，因而住在 Set₁）。把同一条否定落到
**小类型**上——「Peirce 在 U 的空世界里不为真」——点对点写就毫无障碍：

```agda
peirce-not-⊩-at-U : ¬ (U , [] ⊩ Peirce)
peirce-not-⊩-at-U h = not-Peirce (CompletenessU {A = Peirce} {[]} h)
```

`U , [] ⊩ Peirce` 展开后不含任何 record 字段（`V U Γ x` 就是 `Γ ⊢ var x`，
一个纯句法类型），所以 `CompletenessU` 的隐式参数一眼就能对上；这条定义
既是「η-展开写法」的可行样本，也把 46 章那台反模型的结论搬进了通用结构。

## 47.7 nbe：把两条定理合成一台归一化器

现在到本章真正想去的地点。把 46 章与 47 章的两条定理前后接起来：

```agda
nbe : ∀ {Γ A} → Γ ⊢ A → Γ ⊢ A
nbe {Γ} th = Completeness (Soundness th)
```

类型上看毫无信息：`Γ ⊢ A → Γ ⊢ A`。可它是**计算**。拆开看这三步在做什么：

1. `Soundness th`：把推导**编译**成 Agda 函数。`⇒I` 变成 λ、`⇒E` 变成应用、
   `id` 变成「从上下文取证据」（`proj₁ g`）、`wk` 变成丢证据（`proj₂ g`）。
   于是 46.3 那句「这些值同时也是简单类型 λ 演算的项」在这里兑现成真——
   一个 `Γ ⊢ A` 的值被送到语义域，成了 Agda 自己的函数。
2. Agda 求值：所有 β-红约在类型检查器的规范化里**自动**被约掉。我们不写
   任何约简逻辑。
3. `Completeness`（即 `CompletenessU`）：**读回**（quote/read-back）。把
   语义域里算好的东西按公式结构重新拼成推导。

这就是 normalization by evaluation：**先求值（evaluate），再反射回语法
（reflect/quote）**。它和 35 章那台 SK 组合子规范化器是同一目标的两条路：
35 章靠**显式的归约关系 + 良基递归**驱动，这里靠**语义函数的自动约简**驱动，
代码量小一个数量级——代价是需要一整套元定理才说得清它为什么对。

六个算例逐条验收。每条都由 `refl` 接住，也就是「nbe 的输出**定义上**就是
我手写的这个证明」（对照 45 章 `run … ≡ …` 那条 refl：定理算出来的东西可以
在类型层面被验收）。

**例 a：合取绕了一圈的 `⊤`。**

```agda
ex-a : [] ⊢ Top
ex-a = ∧E true (∧I ⊤I ⊤I)

ex-a-nbe : nbe ex-a ≡ ⊤I
ex-a-nbe = refl
```

`∧I` 刚把两份 `⊤I` 配成积，`∧E true` 立刻 `proj₁` 取回来。语义侧
`proj₁ (tt , tt)` 约简成 `tt`，读回时 `CompletenessU` 的 `Top` 分支不看输入、
直接给 `⊤I`。这是最标准的一对红约。

**例 b：两次蕴含自我应用的 `⊤`。**

```agda
ex-b : [] ⊢ Top
ex-b = ⇒E (⇒E (⇒I (⇒I id)) ⊤I) ⊤I

ex-b-nbe : nbe ex-b ≡ ⊤I
ex-b-nbe = refl
```

`(λx. λy. y) tt tt` 两次 β-约简塌成 `tt`，读回 `⊤I`。注意 47.5 里
`CompletenessU {A = Top} u = ⊤I` **压根不看 `u`**，于是可以下一句更狠的结论，
而且它可以直接做成定理（`refl` 一行接住）：

```agda
top-all-nbe : ∀ {Γ} (th : Γ ⊢ Top) → nbe th ≡ ⊤I
top-all-nbe th = refl
```

对**任何**上下文、任何 `Γ ⊢ Top` 的证明，`nbe` 都返回 `⊤I`——`th` 连用都
用不上，因为读回那一步（47.5 的 `CompletenessU {A = Top} u = ⊤I`）压根不
看输入。换句话说：`Top` 这一类公式的正规式在构造上就被写死了，不需要
求值来决定。

**例 c：`p ⇒ p` 的啰嗦证明。**

```agda
ex-c : [] ⊢ p ⇒ p
ex-c = ⇒I (⇒E (⇒I id) id)

ex-c-nbe : nbe ex-c ≡ ⇒I id
ex-c-nbe = refl
```

`(λf. f x)` 型的那个内部红约 `(⇒E (⇒I id) id)` 被约掉，剩下 `⇒I id`，
即 λ 项 `λx. x`。

**例 d：要用到假设的证明。**

```agda
ex-d : q ∷ [] ⊢ p ⇒ q
ex-d = ⇒I (⇒E (wk (⇒I (wk id))) id)

ex-d-nbe : nbe ex-d ≡ ⇒I (wk id)
ex-d-nbe = refl
```

进 `⇒I` 后上下文是 `p ∷ q ∷ []`，目标 `q`。输入在里面造了一个
`p ⇒ q`（`⇒I (wk id)`：无视 p，直接引用 q）又立刻 `⇒E` 用掉。语义侧就是
`(λz. q) x ⟶ q`，而 `q` 在归一化后的上下文里仍是「跳过 p」的那条假设，
所以读回成 `wk id`。`weaken` 在这里显出它的真面目：**de Bruijn 位移**。

**例 e：nbe 会让证明变长（合取版）。**

```agda
ex-e : [] ⊢ (p ∧ q) ⇒ p ∧ q
ex-e = ⇒I id

ex-e-nbe : nbe ex-e ≡ ⇒I (∧I (∧E true id) (∧E false id))
ex-e-nbe = refl
```

输入是一个字母的 `⇒I id`（η-最短形态），输出反而长。原因在 47.5：读回时
`CompletenessU` 按**公式结构**走，假设 `B = p ∧ q` 是复合公式，于是
`SoundnessU {A = p ∧ q} id` 先把 `id` 沿积拆成
`SoundnessU (∧E true id) , SoundnessU (∧E false id)`，再被
`CompletenessU {A = p ∧ C}` 用 `∧I` 装回来。这是 nbe 的固有性格：它产出的是
**按类型结构展开的（η-long）正规式**，不是「最短的那个」。

**例 f：同一现象的蕴含版。**

```agda
ex-f : [] ⊢ (p ⇒ q) ⇒ (p ⇒ q)
ex-f = ⇒I id

ex-f-nbe : nbe ex-f ≡ ⇒I (⇒I (⇒E (wk id) id))
ex-f-nbe = refl
```

`λf. f` 被读成 `λf. λx. f x`——把函数类型的假设展开成「应用于参数」的形态，
正是 η-展开。输出长了一句，但它是 `U , (p ⇒ q) ∷ [] ⊩ p ⇒ q` 那个函数
按结构读回的唯一形态。

再补两条小定理，把 nbe 的性格钉牢：

```agda
ex-e-nbe-nbe : nbe (nbe ex-e) ≡ nbe ex-e
ex-e-nbe-nbe = refl

th-c-normal : [] ⊢ p ⇒ p
th-c-normal = ⇒I id

ex-c-idem : nbe th-c-normal ≡ ⇒I id
ex-c-idem = refl
```

`ex-e-nbe-nbe` 说 nbe 是**投影**（跑两次与跑一次一样），不是幂等之外的什么
魔法。`ex-c-idem` 说已经是正规式的证明，nbe 保持原样。

`ex-c-idem` 这里有个非踩不可的坑，必须交代：不能写
`ex-c-idem : nbe (⇒I id) ≡ ⇒I id`。裸的 `⇒I id` 对**任何**公式 A 都是
`A ⇒ A` 的证明，隐式参数 `A` 悬空，而 `nbe` 要按 A 的结构来决定怎么归一化，
于是类型检查在 `refl` 处报 UnsolvedMetaVariables（坑位 6）。给 `⇒I id` 起
一个带类型标注的名字 `th-c-normal` 再喂进去，A 就被钉成 `p`。这个坑很典型：
**在依赖类型里，「输入不唯一决定归一化方式」的项必须显式标注。**

Curry–Howard 的最后一层窗户纸可以捅破了：PPIL 的证明 = 简单类型 λ 演算的
项，`⇒I` 是 λ、`⇒E` 是应用、`id` 是变量、`wk` 是变量位移、`∧I`/`∧E` 是
配对/投影。于是 `nbe` 不是一个「证明化简玩具」，而是一台**用真值语义写出来
的 λ 演算求值器**。它之所以能工作，全靠 46.6 那一行把蕴含定义成「对所有
未来世界的函数」——语义与函数空间同构，是 Kripke 语义给计算带来的红利。

## 47.8 这两章在全书里的位置

第十部分到此收束。回头看这两章做了什么：

- **元语言与对象语言分离**：`Formula`/`_⊢_` 是被研究的语言，Agda 的
  `Set`/函数/归纳是研究它的元语言。46.6 那一行 `⊩ A ⇒ B = ∀ {w′} → …` 正是
  把对象语言的蕴含交给元语言的函数来解释——这是所有「给语言做模型」工作的
  第一步，也是 Tarski 语义在本教程里唯一一次完整登场。
- **负元数学结果可验证**：`¬ ([] ⊢ Peirce)`（46 章）与
  `¬ ([] ⊨ Peirce)`（本章）都是机器验收的定理，不是「试过了没写出来」。
- **定理即程序**：`nbe` 的三条成分（Soundness、求值、Completeness）全是
  证明函数，它们的合成本身是一台归一化器，输出由 `refl` 验收。这是本教程
  「类型即命题，程序即证明」那句口号能给出的最强样本。
- **层级不是装饰**：`struct : Set₁` ⟹ `Γ ⊨ A : Set₁` ⟹ 对模型的量化必须
  抬一层。46.5、47.6 两次撞上这件事，stdlib 3.0 的层级多态 `¬_` 让最后一次
  不至于绕路。

如果要去往别处：Lean/Coq 里同一条完全性证明会用到商/选择公理一类的额外
机械（Agda 这边因为语义直接落在函数空间上，一行 `V = λ Γ x → Γ ⊢ var x`
就锚住了），而 cubical 版本（32 章）会把「结构之间的同构」变成可计算的路径；
至于把 47.7 这台机器接上真实优化，那是 45 章 `Memoizes` 的世界——两章合起来
正好是「元理论」与「应用」的两端。

本章之后还有两章收尾。**48 章**回到语言防线：这一章和 46 章的所有构造都是
strictly positive 的，正因如此 `--safe` 一路绿灯；48 章实测「如果允许数据类型
出现在箭头左边」会发生什么——三行代码造出 `⊥` 的居民。**49 章**给 35 章的
组合子语言补上变量，用 `λ*` 把 λ 抽象编译成纯 `S`/`K`，并证明它行为等同
代入：那台机器与本章 `nbe` 走的是两条相反路线（一边消语法，一边给语义），
目的地都是正规形。

## 47.9 坑位清单（实测）

1. **record 字段投影不随 `open import` 传播**：47.2 少了 `open struct` 这行，
   第一次写 `W U` 就报
   `Not in scope: W … (did you mean 'Ex46_ppil_kripke.struct.W' or 'struct.W'?)`。
   被 import 的模块内部 `open` 过的名字不算它定义的名字，所以不会外传
   （09 章「record 字段住在同名模块」的跨文件版本）。
2. **`true`/`false` 也要在本地 import**：`open import Ex46_ppil_kripke` 之后
   直接写 `∧E true th` 报 `Not in scope: true (did you mean
   'Relation.Nullary.True'?)`——46 章 import 的 `Data.Bool` 同样不外传。
   跨示例复用只复用**定义**，不复用 import 表。
3. **`monoV = weaken¤` 过不了类型推断，必须包 lambda**：直接给报

   ```text
   error: [UnequalTypes]
   The function type
     w ⊢ _A_51 → w′ ⊢ _A_51
   is not a subtype of
     {x : Agda.Builtin.String.String} → w ⊢ var x → w′ ⊢ var x
   because:
     one takes a visible argument, while the other takes a hidden
     argument.
   when checking that the expression weaken¤ has type
   w ¤ w′ → {x : String} → w ⊢ var x → w′ ⊢ var x
   ```

   写成 `λ d th → weaken¤ d th` 即过（示例采用）。`reflR = ¤-refl` 却不用包，
   因为 `Reflexive _¤_` 展开后与 `∀ {Γ} → Γ ¤ Γ` 逐字相同，没有需要特化的
   隐式参数。同一条叮嘱在 IAL 原书里也有，2.9.0 的边界一模一样。
4. **`mutual` 块里左端要提名上下文**：`CompletenessU {A = B ⇒ C} {Γ} u` 的
   `{Γ}` 不能省，因为右端 `id {Γ} {B}` 提到它，删掉报
   `Not in scope: Γ`。反过来，`id` 身上的钉参数 `{Γ} {B}` 是**可选**的
   （实测写成 `SoundnessU {A = B} id` 也能过），留着只为读者着想。
5. **闭合的 `⊨` 类型在子句里会被展开到见骨**：`peirce-not-valid h =
   Not-valid not-Peirce h` 报

   ```text
   error: [UnsolvedConstraints]
   Failed to solve the following constraints:
     _k.V_176 w′ "p" =< V k w′ "p" (blocked on _k.V_176)
     V k w′₁ "p" =< _k.V_176 w′₁ "p" (blocked on _k.V_176)
     _k.V_176 w′₂ "q" =< _k.V_176 w′₂ "q" (blocked on _k.V_176)
     V k w′₂ "p" =< _k.V_176 w′₂ "p" (blocked on _k.V_176)
   error: [UnsolvedMetaVariables]
   Unsolved metas at the following locations: …:176.43-44
   ```

   报错里那些 `w′₁ / w′₂ / "p" / "q"` 正是 Peirce 公式的三层量化。修法只有
   一条：点对面写 `peirce-not-valid = Not-valid not-Peirce`。显式钉参数
   （`Not-valid {Γ = []} {A = Peirce} not-Peirce h`）**不能**解决，因为问题
   出在 `h` 的类型已被展开，不在被调用方。同一条定理落到小类型上就没有这个
   麻烦——示例里的 `peirce-not-⊩-at-U : ¬ (U , [] ⊩ Peirce)` 用的正是点对点
   写法（`h` 明写在左端），因为 `U , [] ⊩ Peirce` 展开后不含 record 字段。
6. **`nbe` 的输入必须能定出公式**：`nbe (⇒I id)` 里 `⇒I id` 对任何 A 都是
   `A ⇒ A` 的证明，隐式 `A` 悬空，`refl` 那一行报 UnsolvedMetaVariables
   （多处，全在 `nbe` 与 `≡` 的隐式参数上）。给带类型标注的名字
   （`th-c-normal : [] ⊢ p ⇒ p`）即可。归一化器按公式结构工作，所以公式
   必须是已知量。
7. **`¬_` 是层级多态的**（正面事实，不是坑，但它推翻了「大类型不能被否定」
   这个直觉）：`¬ ([] ⊨ Peirce)` 里 `[] ⊨ Peirce : Set₁`，照样通过——
   stdlib 3.0 的定义是 `¬_ : Set a → Set a`。46 章那种「`⊨` 在 Set₁ 所以
   不能套 ¬」的担心是多余的，实测两处（`Not-valid` 与 `peirce-not-valid`）
   都用了 `¬`。
8. **跨示例 import 的模块名要用全名**：`open import Ex46_ppil_kripke` 依赖
   `AgdaTutorial.agda-lib` 的 `include: examples`，所以 `build.sh` 必须在
   `agda/` 目录下跑；在别处（例如 `/tmp`）写探针文件会先撞
   `FileDoesNotExist`（找不到库），再撞
   `ModuleNameDoesntMatchFileName`——模块名必须与文件名逐字相同。

---

上一章：[46 · Kripke 语义与可靠性定理：给直觉主义逻辑一个「真值」](46-ppil-kripke.md) ｜ 下一章：[48 · 负类型与 strict positivity：Agda 的第二道守门检查](48-negative-datatypes.md) ｜ 返回：[README](../README.md)
