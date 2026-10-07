# 06 矢列演算 G：双向上下文与经典性

> 对书：Ben-Ari 3e §3.2 / EFT IV / Mints §8（LJ 对照）
> 通道：C/A/L/I（可靠性旗舰，零公理）

03 章 ND 把推理组织成「假设的进与出」；本章的矢列演算
（sequent calculus）换成另一种组织：**前提与结论都是公式表**，
推理规则把公式在左右两侧搬来搬去。这是 Gentzen 与 ND 同年
（1934）发明的孪生演算——ND 模仿人类证明，G 服务**机器搜索**：
规则自下而上读就是证明搜索算法（07 章表列、26 章归结都是它
的后代）。

## 矢列怎么读

矢列 `Γ ⊢ Δ` 读作：「Γ 全真 ⟹ Δ 至少一真」。注意三个要点：

1. **左边是合取，右边是析取**——不对称是本质的。右表有多项
   意味着「结论可以分叉」，这正是经典逻辑的特征（直觉主义
   矢列 LJ 把右边限成至多一项，本章末尾对照）。
2. **逗号在两边含义不同**：左逗号=且，右逗号=或。
3. 空左表=「真」（没有前提），空右表=「假」（析取零项）。

机器语义把这三点写成定义（`examples/06_sequent/ex06_sequent.v`）：

```coq
Definition allTrue (G : list sform) (e : nat -> bool) : Prop :=
  forall f, In f G -> seval e f = true.

Definition someTrue (D : list sform) (e : nat -> bool) : Prop :=
  exists f, In f D /\ seval e f = true.

Definition seqValid (G D : list sform) : Prop :=
  forall e, allTrue G e -> someTrue D e.
```

`seqValid` 就是矢列的语义：任何赋值下，前提全真则结论有真。
它就是可靠性定理要证的目标形态。

## 九条规则：每个连接词，左右各一条

公理 `gAx`（Γ 与 Δ 有公共公式即成立）之外，五个连接词
（¬ ∧ ∨ →，¬ 算一个）各配左右两条——左规则管「这个连接词
当前提怎么用」，右规则管「这个连接词当结论怎么证」：

```coq
Inductive gProv : list sform -> list sform -> Prop :=
| gAx    : forall G D p, In p G -> In p D -> gProv G D
| gLNeg  : forall G D p, gProv G (p :: D) -> gProv (SNeg p :: G) D
| gRNeg  : forall G D p, gProv (p :: G) D -> gProv G (SNeg p :: D)
| gLAnd  : forall G D a b, gProv (a :: b :: G) D -> gProv (SAnd a b :: G) D
| gRAnd  : forall G D a b,
    gProv G (a :: D) -> gProv G (b :: D) -> gProv G (SAnd a b :: D)
| gLOr   : forall G D a b,
    gProv (a :: G) -> gProv (b :: G) D -> gProv (SOr a b :: G) D
| gROr   : forall G D a b, gProv G (a :: b :: D) -> gProv G (SOr a b :: D)
| gLImp  : forall G D a b,
    gProv G (a :: D) -> gProv (b :: G) D -> gProv (SImp a b :: G) D
| gRImp  : forall G D a b, gProv (a :: G) (b :: D) -> gProv G (SImp a b :: D).
```

逐个读三条代表：

- **gRNeg**（右 ¬）：要证 ¬p（在右边），把 p 挪到左边去证——
  「假设 p，推出（其余结论之一）」。这正是 03 章 ¬i 的矢列版：
  假设开框变成了**跨逗号移动**。
- **gLImp**（左 →，全场唯一「两前提反向」规则）：前提里有
  a→b，拆成两条路——要么用 a 在右边被证出（于是 a→b 的前件
  兑现），要么 b 进左边继续用。「蕴含当前提」天然要分情况。
- **gRAnd** vs **gLOr**：两条分叉规则对照——右 ∧ 分叉（两边
  都要证）、左 ∨ 分叉（两种情形都要能续）。对偶得整齐。

读规则的秘诀：**自上而下读是「怎么用/证」，自下而上读是
「怎么搜」**。自下而上，每条规则把头部连接词拆掉、矢列变简单
——这就是可判定搜索的雏形（07 章表列把这条路走到底）。

## 一个完整推导：亲手走一遍

证 `⊢ (p ∧ q) → p`——把规则自下而上串起来（证明搜索视角）：

```text
目标      ⊢ (p ∧ q) → p          右表只有它，先拆 →
gRImp   p ⊢ p                    a=p 进左表头、b=p 留在右表头？——
                                 不：gRImp 要求 (a::G) ⊢ (b::D)，
                                 即 p :: [] ⊢ p :: []
gAx     收工                     左表含 p、右表含 p，公共命中
```

自上而下读回「证明」：gAx 给 p⊢p，gRImp 放电成 ⊢ p→p……等等，
目标是 (p∧q)→p 不是 p→p——gRImp 的左表头必须是**前提公式本身**，
所以先要在左表把 p∧q 拆掉：完整推导是 gAx（p,q ⊢ p）→
gLAnd（p∧q ⊢ p）→ gRImp（⊢ (p∧q)→p）。三层，每层拆掉一个
连接词。**自下而上每步唯一**（看头部连接词选规则）——这就是
G 的搜索友好性：没有 ND 那种「什么时候开 →i 框」的自由度焦虑。

## 结构规则与 cut：本章没写的三条腿

完整的 LK 还有三条**结构规则**：弱化（thinning：两边随意加公式）、
收缩（contraction：重复公式合并）、交换（exchange：顺序无关）。
本教程用**列表+成员关系 In** 把弱化吸进了 gAx（命中任意成员即
可，不要求表头）；收缩被「规则不消耗原公式」的读法吸收；交换
留作导出规则。还有第四条——**cut**（切割规则：「Γ ⊢ Δ,a 且
a,Γ' ⊢ Δ' 则 Γ,Γ' ⊢ Δ,Δ'」，即引理拼接）：它是演算的「模块性」，
也是唯一一条自下而上会**引入新公式**的规则（破坏子公式性质）。
Gentzen 的 Hauptsatz（cut elimination：任何用 cut 的证明都能
消除 cut）是 20 世纪证明论的第一座高峰——本教程不机器化它
（工作量是单独一本书），但它的推论天天在用：**无 cut 系统的
证明搜索才终止**，07 章表列的全部正确性论证暗中都站在它肩上。

## G 天生经典：LEM 三步

G 的经典性不需要任何额外公理——它长在**双向右表**上：

```coq
Theorem g_lem_var : forall n, gProv [] [SOr (SNeg (SVar n)) (SVar n)].
```

推导三步：gROr 把 ¬p∨p 拆成右表两项 `⊢ ¬p, p`；gRNeg 把 ¬p
的 p 挪到左边 `p ⊢ p`；gAx 收工。关键的第二步：右表的 p
**在 ¬p 移走之后还活着**——右表多项允许「给自己留后路」。
直觉主义矢列 LJ 砍掉这条后路（右表至多一项），LEM 立刻不可证。

顺序注记：规则只在**表头**引入，所以最先出来的是 `¬p ∨ p`
而不是 `p ∨ ¬p`——后件交换性是条导出规则（可以用 gROr 的
实例化顺序证明）。H&R 的 LK 变体用多重集合（multi-set）代替
列表，交换/收缩/弱化作为结构规则明写，绕开了顺序烦恼；本教程
用列表，把交换留作练习式导出——代价是证明里到处是「成员关系
In 的挪动」，坑位速记里有实录。

## 旗舰：可靠性（零公理，九个分支）

```coq
Theorem gProv_sound : forall G D, gProv G D -> seqValid G D.
```

「可推的矢列皆有效」——对推导归纳，九个分支。每个分支的骨架
是同一套四拍（以 gLImp 为例，它最绕）：

1. 从 `Hall : allTrue (SImp a b :: G) e` 抽出 `seval e (SImp a b)
   = true`，`implb_sem` 把布尔蕴含分解成「a 假或 b 真」；
2. 布尔三分（`seval e a = true ∨ = false`）定 witness 方向：
   a 假走 IH₁（a 在右边被排除），b 真走 IH₂（b 进左边）；
3. `inversion Heq; subst f` 把 witness 统一到具体公式——
   someTrue 给的存在见证此时还只是「Δ 里某个公式」，
   inversion 把它钉成 b；
4. 见证输出：给 someTrue 提供具体公式与真值证据。

九分支里没有一条用到经典公理——**G 的经典性全部来自右表结构**，
可靠性证明因此零公理干净通过（`Print Assumptions`：Closed）。
这给了「G 天生经典」一个精确的机器含义：不是「加了经典规则」，
而是「结构本身就允许多结论」。

## 从 G 到 LJ：直觉主义只差一个约束

把九条规则里的右表全部限成**至多一个公式**：gRNeg 变成
「`p :: G ⊢ []` 得 `G ⊢ ¬p`」（空右表=矛盾，这就是 ¬i），
gRImp 变成「`a :: G ⊢ b` 得 `G ⊢ a→b`」（就是 →i）——
ND 的规则一条条从 LJ 里长出来。这就是为什么 Mints 把 LJ 放在
ND 之后讲：**LJ 是 ND 的「矢列化」，G 是 LJ 的「右表解禁」**。
三个演算的关系一张表：

| 演算 | 右表 | 经典性来源 | 搜索友好 |
|---|---|---|---|
| NJp（03 章） | 单结论 | ⊥e+额外经典规则 | 差（→i 不可逆） |
| LJ | 至多一项 | 无（直觉主义） | 好 |
| G/LK（本章） | 任意多项 | 结构自带 | 好（自下而上收缩） |

## 深浅之别

- Coq/Lean/Agda/Isabelle：`gProv` 是归纳谓词——推导本身是数据，
  可靠性是普通定理，九分支逐个过；
- HOL4：深嵌入同样可行但本章未做（05 章浅嵌入已展示差异；
  HOL4 的 `prove` 本身就是经典 sequent 风格战术的内核化）。

## 演算的变体形式（Ben-Ari §3.9\*）

同一套命题逻辑有三副骨架，互译是理解「演算=数据结构」的捷径：
**G**（本章的矢列）把推理做成自底向上的**搜索**——规则倒着
用就是分解目标，这是表列（07 章）与 DPLL（09 章）的祖先；
**H**（05 章 Hilbert）把推理做成公理的**组合**——紧凑但搜索
不友好，元定理（演绎定理）的舞台；**ND**（03 章）把推理做成
假设的**生灭**——最贴数学实践，对应 16 章 FOL 消去的框。三者
证明同一集合的公式且互相翻译，Ben-Ari 3e 的 ch3/ch8 对 PL/FOL
各自给 G 与 H 并证等价。选型直觉：要**证明**用 ND、要**证明论**
用 H、要**算法**用 G——本教程三件全装，正是让每章挑趁手的兵器。
## 本章小结

- 矢列 Γ ⊢ Δ：左合取右析取；空左=真，空右=假。读法一句话：
  「前提全真时，结论至少一真」。
- 九规则=五连接词×左右+公理；自下而上读=证明搜索，每步看
  头部连接词唯一选规则——这是 G 区别于 ND 的工程优势。
- 结构规则（弱化/收缩/交换）被列表+In 吸收；cut 是模块性
  规则，cut elimination 是表列方法终止性的幕后靠山。
- G 的经典性长在右表多项上：LEM 三步免费；LJ 限右表一项
  立刻回到直觉主义。
- 可靠性旗舰九分支零公理——经典性在结构里，不在公理里。
- ND/LJ/G 三演算：同一件事的三种组织方式；07 章表列是 G 的
  「反向执行」，26 章归结是它的 CNF 特化。

## 坑位速记（本章实测）

- **Coq/Rocq**：`apply (proj1 (implb_true_iff …)) in H` 会把前提
  目标 **shelve**——表面看 H 直接变成结论，Qed 时爆
  「remaining open goals」；解法：`destruct (implb_true_iff …)
  as [Fwd _]` + `pose proof (Fwd H)`；`implb_true_iff` 是函数
  形态（`a=true → b=true`）而非析取；witness 目标要 `simpl`
  先打开 `seval` 的 match，`rewrite` 才看得见子项。
- **Lean**：`apply GProv.gROr (a := …) (b := …)` 带命名参数
  固定实例化方向——`:: Δ` 模式全靠统一，方向不定会选错公式。
- **Agda**：构造子的公式参数用 `_` 占位，目标形状反推。
- **Isabelle**：`inductive` 的双表都是索引（两个都变，`for`
  钉不了）——归纳时两表同时泛化，IH 形态要写全。

---

上一章：[05 Hilbert 系统与演绎定理](docs/05-hilbert.md) · 下一章：[07 语义表列：反向搜索的判定程序](docs/07-tableau.md)
