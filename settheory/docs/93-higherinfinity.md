# 第 93 章 · 高阶无穷导引：无穷公理的层次

> 对应原书：冯琦《集合论导引（第三卷）高阶无穷》引言。
> 前置：[第 28-34 章的大基数与超幂](28-measurable.md)、[第 84-89 章的内模型](84-admissible.md)、[第 90-92 章的力迫](90-forcing2.md)。
> 本章给出第十二篇的概念地图。有限 DAG 只组织阅读与假设依赖，不是大基数相容性的机器证明。

## 93.1 ZFC 为什么不是无穷理论的终点

前两卷已经展示了 ZFC 的解释力。

自然数、实数、函数空间、拓扑空间、代数结构，都可以编码为集合。

序数给出超穷过程的坐标，基数给出无穷集合的大小。

可构造宇宙 L 说明 ZFC 加上 V=L 相容于广义连续统假设；力迫则给出另一种模型，使连续统假设失败。

因此，ZFC 并不是一套会把所有集合论问题都回答完的公理。

连续统的大小、奇异基数假设、某些实数子集是否具有正则性，都会把 ZFC 推到它的边界之外。

哥德尔第一不完全性定理给出了更一般的警告。

只要一套理论足够强、可有效公理化而且相容，它就仍会有不能决定的语句。

给 ZFC 增添一条新公理，可以解决某些旧问题，却不会造出一劳永逸的终点。

新理论又会拥有自己的未决语句。

这正是“高阶无穷”问题的逻辑背景：我们不是寻找最后一条公理，而是在研究一层层可比较、可检验、能产生数学后果的新存在性假设。

大基数公理是这类假设中最有组织的一支。

它们通常断言：存在某个基数 κ，使 κ 以上的集合宇宙在反射、闭包、测度或初等嵌入方面表现出很强的整体性质。

“不可达基数”已经是一个入口。

若 κ 不可达，则 V_κ 是 ZFC 的模型。

于是，在假定不可达基数存在之后，我们得到 Con(ZFC)。

弱紧基数又强于不可达基数；弱紧 κ 下方还有 κ 个不可达基数。

所以新的假设不仅说“一个更大的集合存在”，还会为旧理论的相容性提供模型论资源。

这里必须注意转嫁的方向。

由不可达基数得到 Con(ZFC)，并没有无假设地证明 ZFC 相容。

我们只是证明了：如果“ZFC＋存在不可达基数”有足够的基础，那么较弱的 ZFC 也相容。

第二不完全性定理解释了为什么这种向上转嫁不能在本理论内部随便逆转。

一条足够强的相容理论通常不能在自身内部证明自己的相容性，更不能因此免费证明更强理论的相容性。

## 93.2 一致性强度不是基数大小，也不是真值概率

设 T 是在算术或集合论中可以形式化的理论，Con(T) 表示“T 无矛盾”的形式语句。

如果在约定的弱基础理论中有

  T₂ ⊢ Con(T₁)，

就说 T₂ 在可证的相容性强度意义上至少不弱于 T₁。

若还知道反向结果不能成立，才说强度严格增加。

“尚不知道反向证明”不等于“已经证明严格增加”。

严格性需要独立的结果，而不是从教科书的排列顺序里读出来。

这一概念与基数大小有关，却不是同一件事。

基数 κ<λ 是集合论内部两个对象的大小比较。

Con(T₁) 与 Con(T₂) 的比较则是关于形式理论可证性或模型存在的命题。

一个理论可以使用比另一个理论更大的基数，却不能仅凭“数字更大”推出相容性强度关系。

真正有效的是构造模型、解释理论、建立初等嵌入或给出相对一致性证明。

它也不是“真值概率”。

说某公理的一致性强度更高，不是说它为真的概率更低，更不是说数学家给每条公理分配了一个百分比。

概率语言需要样本空间与测度；这里没有这样的天然结构。

大基数公理的合理性讨论可以引用后果、统一性、内模型、反射、可迭代性与解释力，但这些不是频率估计。

还要区分三个方向：

1. **逻辑蕴涵**：T 是否证明语句 φ。
2. **相对一致性**：若 T₂ 相容，能否构造或证明 T₁ 的模型。
3. **公理合理性**：为何把某条新假设当作值得研究的无穷原则。

三者经常互相支持，却不能彼此替换。

例如，一个有限图搜索程序成功找到路径，只说明路径定义允许这次搜索成功。

它既没有构造集合论模型，也没有形式化 Con(T)，因此不构成相对一致性证明。

本章后面的七个机器件会把这条边界保持得非常清楚。

## 93.3 组合、逻辑与哲学：同一条公理的三面

冯琦把大基数理论放在组合分析与逻辑分析的交汇处。

组合面问：一个很大的集合能承载怎样的染色、划分、树、滤子和闭无界结构？

弱紧基数的划分性质就是典型例子。

可测基数的 κ-完全非主超滤子，则把“几乎所有”组织成一个极强的二值滤子。

超紧基数进一步使用精细超滤子，把大量小集合的选择协调起来。

逻辑面问：这些组合对象能否产生初等嵌入、超幂、内模型和绝对性？

从可测基数上的正规超滤子出发，可以构造超幂。

超幂良基后，经 Mostowski 坍缩得到传递内模型 M 与非平凡初等嵌入 j:V→M。

临界点 crit(j)=κ 把“哪一个对象第一次被移动”变成精确的不变量。

超幂中元素的身份由 Łoś 定理逐公式核对，因此组合滤子变成了模型论机器。

哲学面问：为什么宇宙应当支持这样的整体闭包或反射？

这里没有一个可以代替证明的口号。

可构造宇宙 L 很窄，却提供精细的凝聚性；大基数宇宙更宽，能够容纳 L 所没有的初等嵌入与实数正则性后果。

研究内模型并不是预先断言 V=L，研究泛型扩张也不是预先断言某个外部宇宙已经给出。

它们首先是构造与比较理论的方法。

三种视角会在后文反复换位。

武丁基数的定义带有局部嵌入见证族；它经过荟萃塔和迭代树技术，最终影响投影集的决定性。

如果只记住“武丁基数位于某个强度位置”，就会错过这条从技术到后果的主线。

## 93.4 内模型与外模型：两种相反相成的探测法

**内模型方法**是在给定宇宙内部寻找传递、包含全部序数并满足目标理论的类模型。

L 是最小的 ZF 内模型。

L[A] 允许相对一个谓词或集合 A 构造，L[U] 则用超滤信息研究可测基数的规范内模型。

内模型的价值在于精细。

层级可以逐层检查，定义复杂度和可构造顺序可以追踪，理论之间的偏差也能定位。

0# 正是 L 的非刚性所对应的组合信息。

若 L 存在合适的非平凡初等自嵌入，就说明 L 不可能只是一个毫无对称性的刚性宇宙。

覆盖引理从相反方向说：在没有 0# 的情况下，V 中的集合可以被 L 中受控大小的集合覆盖。

于是，“V 离 L 有多远”不再只是比喻，而有了可证明的分水岭。

迭代超幂和 L[U] 继续追问：大基数见证能否被组织成规范、可比较、可迭代的内模型？

**外模型方法**则从地基模型出发，通过泛型对象增加新集合。

偏序力迫 P 的条件给出有限或局部信息，泛型滤子 G 同时遇到足够多稠密集，名字经 G 求值形成 M[G]。

布尔值模型 V^B 把这件事改写成当前论域中的代数计算。

语句的布尔值 ⟦φ⟧ 记录它在扩张中的真值强度，ZFC 公理的值都是 1。

这让我们不必把“存在外部泛型滤子”当成每次论证的语言前提。

内模型与外模型不是两个互不相干的工具箱。

泛型超幂把力迫与超幂合并：先扩张，再在扩张中取超幂。

Solovay 模型与对称子模型把力迫、滤子和可定义性结合起来。

荟萃塔与迭代树更把内模型比较、外模型泛型性和大基数见证编进同一个证明。

阅读后续章节时，应始终问三个问题：

- 当前对象属于哪个模型？
- 哪个语句在模型之间绝对，哪个不绝对？
- 初等嵌入、泛型滤子或超幂分别移动了什么、保留了什么？

不标模型就谈“所有实数”或“所有集合”，是高阶无穷论证中最容易制造假矛盾的省略。

## 93.5 两条牵引线：连续统问题与可定义实数正则性

第十二篇有两条互相牵引、却不能混为一谈的问题线。

### 第一条：连续统函数与独立性的精细控制

经典 Cohen 力迫已经说明 CH 不能被 ZFC 决定。

新问题是：在大基数附近，连续统函数还能怎样变化？

奇异基数假设 SCH 对奇异 κ 的幂集行为施加强约束。

Prikry 力迫可以改变可测基数的共尾度，同时通过 Prikry 性质控制新有界集合。

Silver 力迫构思与后续迭代则用于控制连续统函数，最终形成 SCH 最小反例的完整账目。

这里的“最小”指基数位置上的最小反例，不是证明代码最短，也不是说有限实验找到一个最小模型。

恰当力迫与恰当力迫公理 PFA 把另一条独立性路线推进到 ω₁ 和非荟萃理想。

主条件、可数模型与泛型条件负责保持 ω₁；可数支撑迭代负责把一步性质传到长迭代。

泛型超幂再把理想饱和性翻译为嵌入性质。

这些结果说明，大基数并不自动回答 CH。

许多大基数在小力迫下保持，而小力迫可以改变连续统的大小。

因此“接受大基数，所以 CH 就有唯一答案”是错误的推论。

大基数在这里提供的是可保持、可反射、可泛型化的结构，而非一句未经证明的连续统数值。

### 第二条：可定义实数子集的正则性

实数子集的三类经典正则性是：

1. **Lebesgue 可测性**：能否由开集与零测集控制，使测度有定义；
2. **Baire 特性**：能否与一个开集只差一个稀疏集；
3. **完备子集特性**：集合是否可数，或包含一个非空完备子集。

ZFC 的选择公理可以构造 Vitali 集等反例，所以不能期待“所有实数子集”在完整 V 中自动正则。

问题于是应当精确到点类与模型。

Borel 集、解析集、余解析集、投影集 Σ¹ₙ/Π¹ₙ，是一层层的可定义实数集。

Solovay 的内模型构造则在特定扩张与可定义性范围内讨论所有实数集的正则性。

大基数的高阶后果会从投影层底部逐步向上推进。

可测基数影响低层投影集；更强的武丁资源通过广泛 Baire 特性、泛型不变性、荟萃塔和迭代树连接到更高层。

Martin–Steel 的决定性定理把足够的武丁假设转成投影决定性。

在投影决定性下，投影集的 Lebesgue 可测性、Baire 特性与完备子集特性得到统一回答。

最终，AD^{L(ℝ)} 把舞台移到由全部实数生成的内模型 L(ℝ)。

这里的决定性语句不是关于一个任意有限博弈程序，而是关于长度 ω 的实数博弈及整个 L(ℝ) 的集合论。

这条线的重点不是“所有语句都变真”，而是：可定义性越明确，大基数给出的结构结论越系统。

## 93.6 “假设—技术—实数后果”总表

下表是全篇的阅读索引，不是一条可反读的等价链。

每一行都要保留自己的假设范围；不能把末行结论倒灌给首行的弱假设。

| 假设或资源 | 核心技术 | 主要目标或后果 |
|---|---|---|
| 不可达、弱紧 | V_κ 模型、无穷语言与划分 | 相对一致性入口、组合紧性 |
| 可测基数、正规测度 | 超幂、Łoś、初等嵌入 | 可测内模型、低层投影集后果 |
| `0#` 或其缺失 | Silver 不可辨别元、覆盖 | L 的非刚性与 V/L 距离分水岭 |
| 迭代正规测度 | 线性迭代超幂、L[U] | 可测内模型的比较与规范分析 |
| 强紧、超紧、强与超强 | 精细测度、目标模型闭包、嵌入见证 | 反射、力迫保持与更强内模型资源 |
| 武丁见证 | 局部嵌入族、广泛 Baire、荟萃塔 | 高阶投影正则性与决定性接口 |
| 可测或奇异化资源 | Lévy 崩塌、Prikry、Silver 力迫 | 共尾度与连续统函数控制、SCH 反例 |
| 恰当迭代与饱和理想 | 主条件、泛型超幂、非荟萃理想 | 保持 ω₁、PFA、理想的嵌入刻画 |
| 无穷武丁资源及相应上方测度 | 迭代树、比较、Martin–Steel 分析 | 投影决定性与 `AD^{L(ℝ)}` 路线 |

“相应上方测度”不可随手删掉。

投影决定性与 `AD^{L(ℝ)}` 的标准假设有精确的强度和排列，后文会在主定理处逐项写出，而不是用“很多大基数”代替。

## 93.7 同一份有限 DAG：定义与无环证明

为了检验七种实现是否真的在谈同一件事，本章选用一个刻意很小的有向无环图。

四个节点依次是：

- `zfc`：基础理论 ZFC；
- `measurable`：加入可测基数假设；
- `supercompact`：加入超紧基数假设；
- `woodinWitness`：**同时采用超紧与武丁见证的联合假设**。

三条边是

  zfc → measurable → supercompact → woodinWitness。

末节点特意不是“裸武丁基数”。

这样可以避免把“武丁基数与超紧基数的完整强弱谱系”压缩成一句有误导性的边。

图中的边只表示本书选用的阅读与相对强度组织，不声称列出全部大基数，也不声称每条边都是最紧的严格强度分离。

形式定义有两层。

`Step x y` 是三条直接边之一。

`Reach x y` 是零步或有限多步的可达关系：零步给 `Reach x x`，尾部追加一条边给传递闭包。

每个节点再配一个自然数秩 0、1、2、3。

每条直接边都使秩严格增加，每条可达路径都使秩不下降。

若有直接边 `Step x y` 与返回路径 `Reach y x`，就有

  rank(x) < rank(y) ≤ rank(x)，

矛盾。

这证明的是有限图没有非空回边。

零步自反路径仍然合法，所以 `Reach x x` 并不会被误判成环。

### Lean：把可达关系作为归纳命题

文件 `examples/lean/Settheory/Ch93Higherinfinity.lean` 先声明四个构造子与三条边。

秩是按构造子模式匹配的普通自然数函数。

```lean
inductive Node where
  | zfc | measurable | supercompact | woodinWitness
  deriving DecidableEq, Repr

def Node.rank : Node → ℕ
  | .zfc => 0
  | .measurable => 1
  | .supercompact => 2
  | .woodinWitness => 3

inductive Step : Node → Node → Prop where
  | zfcMeasurable : Step .zfc .measurable
  | measurableSupercompact : Step .measurable .supercompact
  | supercompactWoodin : Step .supercompact .woodinWitness
```

`Reach` 的 `tail` 构造子把已有路径延长一步。

传递性对第二条路径归纳：零步时直接返回第一条路径，尾部步时先递归再接边。

```lean
inductive Reach : Node → Node → Prop where
  | refl (x : Node) : Reach x x
  | tail {x y z : Node} : Reach x y → Step y z → Reach x z

theorem Reach.trans {x y z : Node} (hxy : Reach x y) : Reach y z → Reach x z
  | .refl _ => hxy
  | .tail hyz hstep => (Reach.trans hxy hyz).tail hstep
```

秩证明与阅读路径分别是：

```lean
theorem Step.rank_lt {x y : Node} (h : Step x y) : x.rank < y.rank := by
  cases h <;> decide

theorem Reach.rank_le {x y : Node} (h : Reach x y) : x.rank ≤ y.rank := by
  induction h with
  | refl => exact Nat.le_refl _
  | tail _ hs ih => exact Nat.le_trans ih (Nat.le_of_lt hs.rank_lt)

theorem Step.not_reach_back {x y : Node} (h : Step x y) : ¬ Reach y x := by
  intro back
  exact (Nat.not_lt_of_ge back.rank_le) h.rank_lt

theorem guidePath : Reach .zfc .woodinWitness :=
  (((Reach.refl .zfc).tail .zfcMeasurable).tail
    .measurableSupercompact).tail .supercompactWoodin
```

`cases h <;> decide` 只判定三个有限秩不等式。

`guidePath` 则把路径的三个构造步骤显式写出。

Lean 编译通过意味着这些归纳类型、证明项与结论通过内核检查，不意味着 Lean 证明了任何大基数理论的 Con 语句。

### Coq：同一证明的归纳脚本

文件 `examples/coq/Ch93_higherinfinity.v` 使用同一结构。

`reach_trans` 的证明有一个值得学习的依赖管理细节。

对 `Hyz` 归纳以前，先把外部前提 `Hxy` 与起点 `x` 撤回目标，使归纳假设对任意前接路径都可用。

```coq
Lemma reach_trans : forall x y z, reach x y -> reach y z -> reach x z.
Proof.
  intros x y z Hxy Hyz. revert x Hxy. induction Hyz; intros a Ha.
  - exact Ha.
  - apply reach_tail with (y := y).
    + apply IHHyz; exact Ha.
    + exact H.
Qed.
```

秩引理用构造子分情形和 `lia` 完成自然数算术。

```coq
Lemma step_rank : forall x y, step x y -> rank x < rank y.
Proof. intros x y H; destruct H; simpl; lia. Qed.

Lemma reach_rank : forall x y, reach x y -> rank x <= rank y.
Proof.
  intros x y H. induction H.
  - lia.
  - apply step_rank in H0. lia.
Qed.

Lemma no_back : forall x y, step x y -> reach y x -> False.
Proof.
  intros x y Hs Hr. apply step_rank in Hs. apply reach_rank in Hr. lia.
Qed.
```

Coq 的 `guide_path` 与 `no_return` 分别构造正向路径、排除末节点返回超紧节点。

这里的 `lia` 只处理自然数不等式，不会替我们搜索或发明集合论模型。

### Agda：无战术的证明项

文件 `examples/agda/Ch93_higherinfinity.agda` 把同样的证明写成依赖类型程序。

`z≤n` 是 0≤n，`s≤s` 把 m≤n 提升为 suc m≤suc n。

因此三条直接边的秩增加都有显式证书。

```agda
step-rank : ∀ {x y} → Step x y → rank x < rank y
step-rank zm = s≤s z≤n
step-rank ms = s≤s (s≤s z≤n)
step-rank sw = s≤s (s≤s (s≤s z≤n))

reach-rank : ∀ {x y} → Reach x y → rank x ≤ rank y
reach-rank refl = ≤-refl
reach-rank (tail r s) = ≤-trans (reach-rank r) (<⇒≤ (step-rank s))
```

`<⇒≤` 把严格不等式 weaken 成非严格不等式。

`no-back` 先串联 `rank x < rank y` 与 `rank y ≤ rank x`，再用 `<-irrefl refl` 排除 `rank x < rank x`。

```agda
no-back : ∀ {x y} → Step x y → Reach y x → ⊥
no-back s r = <-irrefl refl (≤-trans (step-rank s) (reach-rank r))

guide-path : Reach zfc woodinWitness
guide-path = tail (tail (tail refl zm) ms) sw

no-return : Reach woodinWitness supercompact → ⊥
no-return = no-back sw
```

Agda 文件没有运行时打印；成功类型检查并生成接口文件就是这条证明通道的验收结果。

### Isabelle/ZF：用库中的自反传递闭包

文件 `examples/isabelle/ST93/Higherinfinity.thy` 不再归纳定义 `Reach`，而直接使用 ZF 库的 `guideEdge^*`。

四个节点编码成 von Neumann 自然数。

```isabelle
definition zfcN :: "i" where "zfcN \<equiv> 0"
definition measurableN :: "i" where "measurableN \<equiv> succ(0)"
definition supercompactN :: "i" where "supercompactN \<equiv> succ(succ(0))"
definition woodinWitnessN :: "i" where
  "woodinWitnessN \<equiv> succ(succ(succ(0)))"

definition guideEdge :: "i" where
  "guideEdge \<equiv> {\<langle>zfcN,measurableN\<rangle>, \<langle>measurableN,supercompactN\<rangle>,
                  \<langle>supercompactN,woodinWitnessN\<rangle>}"

definition reach :: "[i,i] => o" where
  "reach(a,b) \<equiv> \<langle>a,b\<rangle> \<in> guideEdge^*"
```

这里的 `3` 不能按普通整数记号直接写入当前 ZF 项语法。

`0`、`1`、`2` 有现成缩写，而末节点必须写成 `succ(succ(succ(0)))`。

这是对象语言的语法事实，不是数学上把 3 换成了别的对象。

传递性由 `rtrancl_trans` 给出。

`reach_le` 对 `rtrancl_induct` 归纳：零步由序数自反性，延步由 `a≤y`、`y<z` 和 `lt_trans1` 串联。

```isabelle
lemma reach_le: "a \<in> nat \<Longrightarrow> reach(a,b) \<Longrightarrow> a \<le> b"
  apply (simp add: reach_def)
  apply (erule rtrancl_induct)
   apply (simp add: le_refl nat_into_Ord)
  apply (rule leI)
  apply (rule lt_trans1, assumption)
  apply (rule guideEdge_lt, assumption)
done
```

`no_back` 把 `a<b` 与 `b≤a` 合成 `a<a`，再由 `lt_irrefl` 排除。

`guide_path` 则逐次使用 `r_into_rtrancl` 和 `rtrancl_into_rtrancl`，构造从 `zfcN` 到 `woodinWitnessN` 的闭包成员证。

这条通道额外说明：库已经提供的闭包归纳原则可以替代手写路径类型，但证明义务没有改变。

## 93.8 两种独立拓扑排序与一条 Prolog 路径查询

证明助手直接证明传递性与无回边。

计算通道改用算法读取同一份节点、边表，从数据结构上核对顺序。

这不是重复劳动：Kahn 算法看入度，深度优先算法看递归栈，Prolog 看带访问表的路径搜索。

三种失败方式不同，能防止把同一条边抄错后又在所有断言中自洽地放过。

### Julia：Kahn 入度算法

文件 `examples/julia/93_higherinfinity.jl` 先统计每个节点的入度，再把入度为零的节点放入 `ready`。

每输出一个节点，就删除它的出边效果；后继入度降为零时入队。

```julia
nodes = [:zfc, :measurable, :supercompact, :woodinWitness]
edges = [(:zfc, :measurable), (:measurable, :supercompact),
         (:supercompact, :woodinWitness)]

function topo_sort(nodes, edges)
    indegree = Dict(n => 0 for n in nodes)
    outgoing = Dict(n => Symbol[] for n in nodes)
    for (a, b) in edges
        indegree[b] += 1
        push!(outgoing[a], b)
    end
    ready = [n for n in nodes if indegree[n] == 0]
    order = Symbol[]
    while !isempty(ready)
        a = popfirst!(ready)
        push!(order, a)
        for b in outgoing[a]
            indegree[b] -= 1
            indegree[b] == 0 && push!(ready, b)
        end
    end
    @assert length(order) == length(nodes) "存在有向环"
    return order
end
```

若有环，环上节点始终有未消除的入度，最终输出长度就小于节点总数。

运行得到

  Kahn 拓扑排序：zfc → measurable → supercompact → woodinWitness

程序还断言每条边在输出中从前向后，最后打印 `END ====` 供章级构建核对。

### Python：DFS 三色状态

文件 `examples/python/93_higherinfinity.py` 不计算入度，而为每个节点保存状态 0、1、2。

0 表示未访问，1 表示仍在当前递归栈上，2 表示已经完成。

```python
def topo_sort(nodes, edges):
    outgoing = {n: [] for n in nodes}
    for a, b in edges:
        outgoing[a].append(b)
    state = {n: 0 for n in nodes}
    result = []

    def visit(a):
        assert state[a] != 1, "发现回边，图有环"
        if state[a] == 2:
            return
        state[a] = 1
        for b in outgoing[a]:
            visit(b)
        state[a] = 2
        result.append(a)

    for n in nodes:
        if state[n] == 0:
            visit(n)
    result.reverse()
    return result
```

再次访问状态 1 的节点就是回到当前祖先链，因而发现环。

节点在后序位置加入 `result`，最后反转，得到与 Julia 相同的四节点顺序。

随后用位置字典断言每条边的起点位置小于终点位置。

“与 Julia 一致”只是两种实现对同一有限输入的交叉核对，不是把计算结果升级成 Con 证明。

### Prolog：查询显式路径

文件 `examples/prolog/93_higherinfinity.pl` 把边和秩写成事实。

`walk` 的第三个参数保存反向累积路径；进入后继前用 `\+ member(Next, Acc)` 排除重复访问。

```prolog
path(Start, Goal, Path) :- walk(Start, Goal, [Start], Rev), reverse(Rev, Path).
walk(Goal, Goal, Acc, Acc).
walk(Current, Goal, Acc, Path) :-
    edge(Current, Next),
    \+ member(Next, Acc),
    walk(Next, Goal, [Next|Acc], Path).
```

主查询要求路径恰好是四节点链，同时逐边检查秩增加，并要求末节点不能返回超紧节点。

```prolog
main :-
    format("==== 93~n"),
    path(zfc, woodin_witness, Path),
    Path = [zfc, measurable, supercompact, woodin_witness],
    forall((edge(A,B), rank(A,RA), rank(B,RB)), RA < RB),
    \+ path(woodin_witness, supercompact, _),
    format("查询路径：~w~n", [Path]),
    writeln("END ====").
```

查询输出为

  [zfc,measurable,supercompact,woodin_witness]

Prolog 的失败否定 `\+` 在这里用于一个有限、可终止且边表封闭的小图。

不能把它随意读成一般逻辑中的“绝对不存在证明”。

它只表示在当前有限关系和搜索规则下没有路径。

## 93.9 三条证明链阅读地图

下面三条链对应第三卷的三大思想板块。

箭头表示“阅读时先准备什么、后消费什么”，不全是单向逻辑蕴涵，也不表示可以跳过各定理自己的假设。

### 链一：可测、L 的非刚性与规范内模型

  可测基数与正规超滤子
  → 超幂、良基坍缩与初等嵌入
  → Silver 不可辨别元与 `0#`
  → Jensen 覆盖引理
  → 迭代超幂
  → 可测基数内模型 `L[U]`。

对应第 94-98 章。

第 94 章先建立 Łoś 定理和超幂良基性，因为这是后面所有嵌入语言的入口。

第 95 章把“L 是否有非平凡初等自嵌入”翻译为不可辨别序列、EM 蓝图与 `0#` 的组合问题。

第 96 章走反方向：无 `0#` 时，覆盖引理限制 V 与 L 的差异。

第 97 章把一次超幂改成线性迭代，检查每一步像测度和良基性怎样传递。

第 98 章再把测度信息放入相对可构造层级，研究 `L[U]` 的唯一性思想。

这条链的核心不是背名词，而是学会在“原宇宙—超幂—坍缩模型—迭代像”之间保持公式与参数的账目。

### 链二：大基数上的力迫与理想

  强紧、超紧、强/超强与武丁资源
  → 小型扩张和 Lévy 崩塌
  → Prikry 与 Silver 力迫
  → SCH 最小反例
  → 恰当力迫、恰当迭代与 PFA
  → 泛型超幂与非荟萃理想饱和。

对应第 99-110 章。

前四章扩充嵌入与闭包资源。

小型扩张回答为什么某些大基数能在力迫后保持，Lévy 崩塌则负责把指定对象可数化并分析因子结构。

Prikry 力迫的关键不是“改变共尾度”一句结果，而是 Prikry 性质怎样排除不必要的新有界集合。

Silver 构思和最小反例证明要继续跟踪连续统函数、基数保持和迭代长度。

恰当力迫把“保持 ω₁”改写成可数子模型中的主条件问题；迭代定理再把这些局部条件组织成长链。

最后的泛型超幂把理想性质翻译为扩张中的初等嵌入。

这条链始终要记录：力迫在哪一个模型进行，泛型对象在哪一个模型取，超幂又在哪一个模型求值。

### 链三：投影层、泛型不变性与决定性

  投影精细分层与余解析集
  → `Σ¹₂`、`Σ¹₃` 与广泛 Baire 特性
  → Solovay 内模型和 `HOD(Ω)`
  → Lévy 扩张正则性及 `L(ℝ)` 理论不变性
  → 荟萃塔与泛型超幂
  → 非线性迭代树与可迭代性
  → Martin–Steel 投影决定性
  → `AD^{L(ℝ)}`。

对应第 111-122 章。

投影层先把“可定义实数集”按量词与投影复杂度分层。

广泛 Baire 特性不是普通的拓扑 Baire 特性；前者是一类实数集的力迫不变表示性质，后者是集合与开集模稀疏差的正则性。

二者中文名字相近，论证时绝不可混用。

Solovay 模型线展示在恰当内模型中怎样统一获得正则性。

理论不变性线追问：经过指定 Lévy 扩张后，哪些关于实数的理论保持不变？

荟萃塔提供泛型嵌入，迭代树提供非线性比较与可迭代性，两者最后服务于决定性证明。

第 122 章的 `AD^{L(ℝ)}` 不是把 ZFC 全盘替换成 AD。

选择公理与 AD 在整个 V 中存在根本冲突；结论必须精确落在 L(ℝ) 这个模型及其语言范围内。

## 93.10 机器能证明什么，不能证明什么

本章机器件共同确认了三件有限事实：

1. 四条零步/多步构造规则给出的可达关系具有传递性；
2. 三条直接边严格增加秩，因而不存在沿直接边再返回的路径；
3. 从 `zfc` 到联合见证节点的指定路径存在，两种拓扑排序给出同一顺序。

它们没有确认以下任何命题：

- ZFC 相容；
- 可测、超紧或武丁假设相容；
- 某个大基数公理为真；
- 四个节点构成完整或严格的大基数谱系；
- 投影决定性或 `AD^{L(ℝ)}` 已由本章证明。

这些否定不是谦虚套话，而是类型层面的边界。

机器件的语言里根本没有集合论公式编码、可证性谓词、模型类或 Con 语句。

输入只有四个构造子、三条边和自然数秩。

即使换成百万节点并运行更久，结论仍然只是关于那个有限图的结论。

真正的大基数证明需要在正文中构造超滤子、验证 Łoś、证明超幂良基、追踪初等性，或执行力迫与内模型论证。

有限 DAG 的作用是防止阅读地图本身写错、边表在七种语言中漂移，以及给“路径—传递闭包—无环”提供完整的小证明样本。

后续章节中的有限实验也采用同一纪律。

有限超滤子可以核对定义，不能证明可测基数存在。

有限力迫偏序可以核对稠密性，不能证明 SCH 的独立反例。

有限博弈可以核对胜负策略，不能证明投影决定性。

## 93.11 后续章节的阅读与验账方法

读一个大基数定义时，先找见证对象。

它可能是一个超滤子、一族测度、一个初等嵌入，或一族带闭包条件的目标模型。

然后找临界点、闭包长度和参数范围。

这些量词的位置往往决定定义强度。

读一个超幂定理时，先写清等价类和 Łoś 的方向。

再检查关系是否良基，只有良基且满足相应条件时才能做 Mostowski 传递化。

最后才说 j:V→M，并逐项计算 crit(j)、j(κ) 与 M 的闭包。

读一个力迫定理时，先列保持清单。

哪些基数、共尾度、实数、有界子集、大基数见证被保持？

哪些对象被有意改变？

“不加实数”“不加有界集”“保持基数”“保持 ω₁”是四个不同断言，不能互相代用。

读一个正则性定理时，先圈定点类。

“所有投影集”“所有 Σ¹₂ 集”“L(ℝ) 中所有实数集”“V 中所有实数集”是完全不同的范围。

再圈定工作模型和所用大基数假设。

最后才陈述 Lebesgue、Baire、完备子集或决定性结论。

读一个机器实验时，则按本章 DAG 的方式做输入审计。

程序究竟表示了全部对象，还是只表示一个有限影子？

断言是否独立构造了反例，还是仅把定义重写一遍？

若删去无穷假设，实验是否照样运行？若照样运行，它就不可能单独证明那个无穷假设。

## 93.12 本章要点

- ZFC 的未决问题促使我们研究新存在性公理；不完全性说明这个过程没有一劳永逸的终点。
- 一致性强度比较的是形式理论的相容性后果，不是基数数字的大小，也不是公理为真的概率。
- 大基数的组合面给出滤子、划分和闭包，逻辑面给出超幂、嵌入与内模型；合理性讨论不能替代证明。
- 内模型通过精细层级限制宇宙，外模型通过泛型对象扩展宇宙；泛型超幂等技术把两者结合。
- 连续统线研究独立性与连续统函数控制，正则性线研究可定义实数集；大基数不会仅凭自身自动决定 CH。
- 可定义性范围必须写清：投影层、Solovay 内模型、`L(ℝ)` 与整个 V 不能混为一谈。
- 三条阅读链分别是可测/`0#`/覆盖/`L[U]`，大基数力迫/恰当迭代/泛型超幂，以及投影层/荟萃塔/迭代树/决定性。
- 四节点 DAG 的末节点是超紧与武丁见证的联合假设，不是对裸武丁基数强度位置的简化断言。
- 七通道验证了同一份有限图的传递、无回边、拓扑排序和路径查询；它们没有证明任何集合论理论的相容性。

| 通道 | 正文所引文件 | 本章验收内容 |
|---|---|---|
| Lean 4 + mathlib4 | `examples/lean/Settheory/Ch93Higherinfinity.lean` | `Reach.trans`、秩单调、`Step.not_reach_back`、`guidePath` |
| Isabelle/ZF | `examples/isabelle/ST93/Higherinfinity.thy` | `rtrancl` 传递闭包、`reach_le`、`no_back`、`guide_path` |
| Coq | `examples/coq/Ch93_higherinfinity.v` | 同一归纳关系及完整证明脚本 |
| Agda | `examples/agda/Ch93_higherinfinity.agda` | 无战术依赖类型证明项 |
| Julia | `examples/julia/93_higherinfinity.jl` | Kahn 入度拓扑排序 |
| Python | `examples/python/93_higherinfinity.py` | DFS 三色拓扑排序 |
| SWI-Prolog | `examples/prolog/93_higherinfinity.pl` | 精确路径查询、逐边秩检查与无返回路径 |

章级验证命令为：

```pwsh
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 93'
```

它包含七个章通道单元和一次整个 Lean 项目的构建单元；真实结果写入 PLAN 后才记为全绿。

---

上一章：[第 92 章 布尔值模型](92-boolval.md) · 下一章：[第 94 章 可测基数、正规超滤子与超幂](94-measurable.md)
