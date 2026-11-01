# 105 · Silver 力迫

> 第 104 章 Prikry 力迫把可测基数的共尾度改成 ω 而不留痕迹；
> 本章取材冯琦第三卷 §2.4（书页 161–172；PDF 181–192）搭起
> SCH 反例的另一半：**在超紧基数 κ 上添加足够多子集使
> \(2^\kappa=\kappa^{++}\) 而 κ 仍可测**（定理 2.10 Silver）。
> 与第 103 章 Lévy 崩塌「一击塌方」不同，Silver 力迫是**迭代
> 工程**：沿 κ 之下的一切不可达基数 α 逐个添加 \(\alpha^{++}\)
> 个子集（\(\mathbb Q_\alpha=\mathrm{Add}(\alpha,\alpha^{++})\)，
> 条件是大小 \(<\alpha\) 的部分函数 \(f:\alpha\times\alpha^{++}
> \to 2\)），极限步的取舍由**Easton 支撑**（定义 2.10：正则基数
> 处取正向极限、奇异处取反向极限——定义 2.8 两种极限的混合）
> 统一调度。技术地基三件套：**链条件**（定理 2.9：正向极限 +
> 荟萃多个正向极限点 ⟹ κ-cc 保持）、**λ-定向完全性**（定义
> 2.11 + 引理 2.6 三款：乘积/正向极限/Easton 迭代下封闭）、
> **分解引理**（引理 2.7：\(\mathbb P_{\alpha+\beta}=\mathbb
> P_\alpha*\mathbb P^{(\alpha)}\)）。定理 2.10 的证明是全书
> 嵌入提升机的集大成：取 \((\kappa,\kappa^{++})\)-超紧 \(j\)，
> 在 M 中用分解引理切出 \(j(\mathbb P)=\mathbb P*\mathbb Q\)，
> 用 M[G] 的 λ-封闭性造出**大拿**（master condition——D 的
> 定向下界 \(a\in\mathbb Q\)，书 p171 原词「大拿」），据此把
> \(j\) 提升成 \(j^*:V[G]\prec M[K]\)，\(U=\{X\mid\kappa\in
> j^*(X)\}\) 即 \(V[G]\) 中的可测性见证。与定理 2.6（Prikry）
> 组合即得 cf(κ)=ω 的强极限基数处 SCH 失败（定理 2.11 的前奏）。
>
> 机器边界：迭代、Easton 调度、嵌入提升全在超穷层；七个通道做
> **条件层**——Silver 条件（有限部分函数 (α,ξ)↦b∈{0,1}）的
> 偏序律（反向包含的自反/传递——Task 20 Step 2 指定件）、相容
> 合并、**Easton 支撑**（|spt∩μ|<μ 的正反样本）、贪心泛型搜索
> 与相遇稠密集的**条件链输出**（Prolog）、两两相容族的并是
> 公共下界（**大拿的有限影子**——引理 2.6 定向完全性）。

### 105.0 阅读路线图

§105.1 战役地图（两步走 + 为什么必须迭代）；§105.2 迭代
定义与两种极限（融合/截断几何 + Easton 调度）；§105.3
链条件与定向完全性（三款分工 + λ 的选取）；§105.4 分解
引理与定理 2.10 四幕（大拿机制逐帧）；§105.5 与 Prikry
合龙 + Easton 三点差异 + 谱系表；§105.6–105.7 机器通道
（四证明 + 两计算 + 一查询 + 一集论核）与诚实边界；
§105.8 要点与检查问题。Isabelle 通道最少（3 个引理）但
每条都是确定性规则链的模板样本；Coq 通道坑最重（布尔键
相等 + 双引理显式参）。
## 105.1 战役地图：从超紧到 SCH 反例的两步走

书 p161–162 的战役部署值得先看全貌。**目标**：造一个模型，
其中 κ 是 cf(κ)=ω 的强极限基数且 \(2^\kappa=\kappa^{++}\)——
SCH 在 κ 处失败的最小可能形态（第 78 章 Silver 定理已排除
不可数共尾度；Jensen 覆盖引理把「无大基数」情形也排除）。
**两步走**：

- **第一步（本章）**：从 κ++-超紧出发，Easton 支撑迭代使
  \(2^\kappa=\kappa^{++}\) 且 κ 仍可测——**先造出「违背 GCH
  的可测基数」**。
- **第二步（第 104 章已备好）**：Prikry 力迫把该可测基数化成
  cf=ω 的强极限奇异基数——**可测性携 \(2^\kappa=\kappa^{++}\)
  一起度过共尾度手术**（定理 2.6 三款保证 κ 以下无新子集、
  \(2^\kappa\) 不变）。

为什么必须迭代而不能一击？**Silver 定理（第 78 章定理 1.2.38）
的自然启示**（书 p162）：在可测 κ 上破坏 GCH 之前，必须在 κ
之下的不可数多个正则基数上破坏 GCH——一击式 Add(κ,κ⁺⁺) 会让
κ 的可测性立即失效（超滤子的种子集被打乱）。迭代工程沿 κ 之下
的每个不可达 α 逐点加工，每步只动 α 处的 \(2^\alpha\)，最终
在 κ 处「凑齐」\(2^\kappa=\kappa^{++}\)。

### 105.1b 超紧预算：为什么起点是 κ⁺⁺-超紧而不是可测

定理 2.10 的起点 κ⁺⁺-超紧看似过高（结论只要 κ 可测），
实则每一级超紧性都有指定用途：**κ⁺⁺-超紧给 \({}^{
\kappa^{++}}M\subseteq M\)**——第三幕用它证 P∈M 与
G 的 M-泛型性（P 的定义在 V 与 M 中一致），第四幕用
它证 λ-封闭断言（M[G] 的 λ-序列封闭回收 U 入 V[G]）。
若只取 κ⁺⁺-强（或 λ-强），\({}^{\kappa^{++}}M\subseteq
M\) 换成 V_{\kappa^{++}}^M⊆M——名字编码账断在「g:λ×P
→ Ord 是类大小对象」这一步（P 不是 V_{\kappa^{++}} 的
元素）。**超紧的序列封闭在力迫工程中的角色恰是「让 V
与 M 对 |P|-大小的对象达成一致」**——第 100 章定理
1.29 的「像集进 M」在此换装成「整个迭代工程进 M」。

### 105.1a 迭代力迫 vs 一击式：为什么必须迭代

一击式 Add(κ,κ⁺⁺) 的失败机制值得点破：它的条件直接以
κ×κ⁺⁺ 为域，κ-cc 仍在（Add(κ,λ) 总是 κ-cc），但
**可测性的提升论证断裂**——取 j:V→M 后 j(Add(κ,κ⁺⁺))=
Add(j(κ),j(κ⁺⁺))，其条件域 j(κ)×j(κ⁺⁺) 远大于 M 中
「Add(κ,κ⁺⁺) 的尾巴」；G 的 j-像不再有任何公共下界
（大拿不存在——D 的下界需要落在 j(κ) 以下的坐标全兼容，
而一击式的条件在 j(κ) 以上还有大量坐标）。Silver 迭代
的解法：**把 κ 以上的坐标留给 M 侧的尾巴迭代 Q，让
j(P)=P*Q 的分解恰好把这些坐标装进 Q**；Q 的 λ-定向完全
性（Easton 调度在 cf≤λ 处取反向极限——引理 2.6(c) 的
条件）回收大拿。「迭代不是权宜，是大拿存在性的结构保证」。
## 105.2 迭代力迫的一般定义与两种极限

> **定义 2.7** 长度 α 的迭代力迫 \(\mathbb P_\alpha\)：
> (a) α=1 时 \(\mathbb P_1=\mathbb Q_0\) 的条件单序列；(b)
> 后继步 \(\mathbb P_{\alpha+1}=\mathbb P_\alpha*\dot{\mathbb
> Q}_\alpha\)（条件 \(p\) 满足 \(p\upharpoonright\alpha\in
> \mathbb P_\alpha\) 且 \(1\Vdash p(\alpha)\in\dot{\mathbb
> Q}_\alpha\)）；(c) 极限步：常值序列 \(\langle1,1,\dots
> \rangle\in\mathbb P_\alpha\)，且 \(p,q\) 的**融合**
> \(r(p,q)\)（β 前取 q、β 后取 p）仍在 \(\mathbb P_\alpha\)，
> 并且限制映射 \(\pi_\beta\) 保序。

定义 2.7 把第 91 章（马丁公理线）的有限支撑迭代推广到任意
长度与任意极限方式。两个新部件：**融合**（fusion——两条条件
「前半取一条后半取另一条」的缝合，是极限步封闭性的最低要求）
与**限制映射族** \(\pi_\beta:\mathbb P_\alpha\to\mathbb
P_\beta\)（截断）——后者保证迭代「越往后越长」的相容性。

> **定义 2.8** 设 \(\mathbb P_\alpha\) 是长度为极限序数 α
> 的迭代力迫。
> (1) **正向极限**（direct limit）：\(p\in\mathbb P_\alpha
> \iff\exists\beta<\alpha\,\forall\gamma\ge\beta\,(p(\gamma)=1)\)
> ——每条条件** eventual 平坦**（某点之后全取 1）。
> (2) **反向极限**（inverse limit）：\(p\in\mathbb P_\alpha
> \iff\forall\beta<\alpha\,(p\upharpoonright\beta\in\mathbb
> P_\beta)\) ——一切截断都合法，**直取整个无穷乘积**。

两种极限的几何：正向极限是「**平坦极限**」（条件最终睡着
了——只有有限/有界多的活跃坐标），反向极限是「**极端极限**」
（条件可以在每个坐标都有内容，只要求逐段合法）。第 91 章的
有限支撑迭代 = 一切极限步取正向极限（事实 2.4.1(1)）；可数
支撑迭代 = cf(δ)>ω 处正向、cf(δ)=ω 处反向（(2)——下一节
恰当力迫的主角）。

> **定义 2.9/2.10** 条件 p 的**支撑** spt(p) = 非平凡坐标
> 全体。\(\mathbb P_\alpha\) 是 **I-支撑**迭代 iff 一切
> spt(p)∈I。**Easton 支撑**：对每个正则 \(\mu\le\alpha\)，
> \(|\mathrm{spt}(p)\cap\mu|<\mu\)。等价刻画（事实 2.4.2）：
> cf(δ) 正则处正向极限、cf(δ)<（相应正则基数的）处反向极限。

Easton 支撑是**「在正则基数处吝啬、在奇异处慷慨」**的混合
调度——正则 μ 处只允许 <μ 个活跃坐标（保证 μ-cc 与 μ-封闭
的兼容），奇异极限处全取反向（保证长度不塌）。机器通道的
`easton_ok`（|spt∩μ|<μ）正是这个条款的正反样本：支撑
{0,1} 在 μ=2 处**不**合法（2 ≮ 2）、μ=3 处合法（2<3）。

### 105.2a 融合与截断的几何

融合 r(p,q) 的定义值得画一张图：条件是 α-长序列，融合在
β 前取 q、β 后取 p——**一条条件的前段换成另一条**。这与
第 104 章 Prikry 的 stem 延长（往尾部添新元素）方向相反：
Prikry 的信息向前生长，融合的信息**横向嫁接**。迭代力迫
的极限步封闭性（定义 2.7(c)）要求融合封闭——「两条合法
条件的任何前/后段拼接仍合法」——这是比「链并封闭」弱但
比「任意并封闭」强的中间要求，恰好与支撑条款配合：支撑
有限的条件下融合不增支撑，支撑 <μ 的条件下融合后仍 <μ。

截断映射 π_β 的单调性（(c)(iii)）是「迭代=反向系统」的
精确表述：\(\langle\mathbb P_\beta,\pi_{\beta,\gamma}\rangle\)
构成以 \([\alpha]\) 为索引的反向系统，正向极限是它的**归纳
极限**（colimit）、反向极限是**投射极限**（limit）——
范畴论的两个 universal 构造在力迫论里各领一种支撑调度。
第 46–52 章 Viale 布尔值线的定向极限（第 100 章末的
系统版因子分解）与此同构：**超幂迭代与力迫迭代是同一台
「沿序数生长的机器」的两种燃料**（测度 vs 偏序）。
### 105.2b 支撑速查表

| 支撑 | 定义 | 极限调度 | 代表应用 |
|---|---|---|---|
| 有限支撑 | spt(p) 有限 | 一切极限步正向 | 东极限=平坦；第 91 章 MA 迭代 |
| 可数支撑 | \|spt(p)\|≤ℵ₀ | cf(δ)>ω 正向、cf(δ)=ω 反向 | 第 107 章恰当迭代 |
| Easton 支撑 | 正则 μ 处 \|spt∩μ\|<μ | cf(δ) 正则正向、否则反向 | 本章 Silver 迭代 |

三行的递进：有限支撑的正向极限使迭代「有界活跃」（每条
条件只记有限个坐标的改动），可数支撑在 ω-共尾处放行反向
（允许条件携带 ω-长信息——恰当力迫的可数条件须如此），
Easton 支撑把「放行阈值」从固定 ω 改为「逐点正则基数」
（每个 μ 处 <μ 个活跃坐标——既保 μ-cc 又保足够封闭）。
**支撑=活跃坐标的预算制度**——预算越紧越安全（cc 好证）、
越松越强大（封闭性强）；Easton 是「按基数分级预算」。

### 105.2c 两种极限的模型论面孔

正向/反向极限在模型论中各有旧名字：正向极限是**Fraïssé
式构造**的极限（每结构在足够远处「稳定」——一切元素在某
个有限阶段已出生），反向极限是**逆极限**（inverse
limit/profinite 构造——p-进整数与 Cantor 空间的标准生成
方式）。力迫论借用这对范畴构造时注入了序数层的裁量：在
哪个 cf(δ) 处切换两种极限，决定了迭代的「预算制度」（支
撑）——这正是定义 2.10 的内容。有趣的对照：反向极限保持
一切投影信息（条件可以在每个坐标都有内容），因此**封闭性
强**（引理 2.6(c) 只能在反向步缝合）；正向极限砍掉「无穷
纠缠」的条件（eventual 平坦），因此**组合性好**（cc 定理
2.9 只在正向步结算）。**封闭性与组合性在两种极限上的分配
是零和的**——Easton 调度的全部艺术就是在正确的位置切换。

## 105.3 链条件与 λ-定向完全性

> **定理 2.9** κ 不可数正则、α 极限、\(\mathbb P_\alpha\)
> 正向极限，且 \(\mathrm{cf}(\alpha)=\kappa\Rightarrow
> \{\beta<\alpha\mid\mathbb P_\beta\) 正向极限\(\}\) 在 α
> 荟萃。若每个 \(\mathbb P_\beta\) 满足 κ-cc，则
> \(\mathbb P_\alpha\) 也满足。

证明（练习，参照有限支撑迭代的链条件定理）的关键新情形：
cf(α)=κ 时，κ 个截断的「平坦化点」由 cf(α)=κ 的正则性选出
无界列，两条件的平坦段在某个共同 β 之后全取 1，截断到 β 用
归纳假设相容，再拼回。**荟萃多个正向极限点**是 Easton 支撑
在不可达基数处自动提供的（不可达基数的正则性 + 定义 2.10
的调度）。

> **定义 2.11** \((\mathbb P,\le)\) 是 **λ-定向完全**的 iff
> 每个大小 ≤λ 的定向子集 D（任意 \(p_1,p_2\in D\) 有公共
> 延展）都有下界。

> **引理 2.6** (a) \(\mathbb P\) 与 \(\Vdash\dot{\mathbb Q}\)
> 都 λ-定向完全 ⟹ \(\mathbb P*\dot{\mathbb Q}\) 也是；
> (b) cf(α)>λ 且 \(\mathbb P_\alpha\) 正向极限、每段 λ-定向
> 完全 ⟹ \(\mathbb P_\alpha\) λ-定向完全；(c) Easton 支撑
> 迭代、每步的 \(\dot{\mathbb Q}_\beta\) λ-定向完全、且凡
> cf(β)≤λ 的极限步取反向极限 ⟹ 全程 λ-定向完全。

三款的机制：(a) 是**两条件缝合**——D 在 \(\mathbb P\) 侧的
投影有下界 p，D 中以 p 为投影的 \(\dot{\mathbb Q}\)-侧元素
（λ 个名字）用 \(\Vdash\)-侧的定向完全性取下界名字；(b) 是
**平坦段统一**——λ 个条件在 cf(α)>λ 下有共同平坦化点 β，
截断到 β 用归纳，再平坦延伸到 α；(c) 是**反向极限处的逐段
缝合**——沿 β 递归定义下界函数 \(p=\langle p_\beta\rangle\)，
每步在 \(\mathbb P_\beta\) 内取当前段的下界；cf(β)≤λ 的极限
步反向极限**保证任意逐段合法的函数都在迭代中**。机器通道的
「两两相容族的并是公共下界」是 (a) 在有限层、值域 {0,1} 的
最小样本。

### 105.3b 链条件证明的荟萃账逐帧

定理 2.9 的证明（练习，参照有限支撑版）在 cf(α)=κ 时的
关键账：设 \(\langle p_\xi\mid\xi<\kappa\rangle\) 是
\(\mathbb P_\alpha\) 的 κ-长序列。每个 \(p_\xi\) 的
支撑有界（正向极限 ⟹ eventual 平坦），平坦化点 \(\beta_
\xi<\alpha\)；κ 个点的上界由 cf(α)=κ 的正则性给出 δ<
α。**正向极限点集在 α 荟萃**（假设）⟹ δ 之下有正向极限
点 δ′——截断到 δ′（归纳假设 \(\mathbb P_{\delta′}\)
κ-cc）取相容对 \((p_\xi\!\upharpoonright\delta′,
p_\eta\!\upharpoonright\delta′)\)，再在 δ′ 处融合（两条
平坦条件在共同平坦点之后全取 1，拼接仍 eventual 平坦）。
**荟萃性的消费点恰在「κ 个有界支撑的公共上界不保证落在
正向极限点」**——需要荟萃（而非无界）才能在任意 δ 之下
找到极限点。这是第 94 章以来「无界不够、荟萃才够」的第
五次出场（Ulam 分裂、可测保持、图挤压、反射函数、本章）。

### 105.3a 定向完全性的三款分工与「λ」的选取

引理 2.6 三款在定理 2.10 中的分工：(a) 管**每一步**的
乘积（P_β * Q_β——Q_β=Add(α,α⁺⁺) 是 <α-封闭的，取
λ=κ⁺⁺ 时每步都 λ-定向完全，因为 α<κ 的条件的域 <α≤κ
远小于 λ）；(b) 管**正向极限步**（cf(δ)>λ 的极限——由
λ 个条件的平坦化点统一）；(c) 管**反向极限步**（cf(δ)≤λ
的极限——逐段缝合，下界函数逐坐标构造）。三款的「λ」统一
取 κ⁺⁺：恰好等于 |P|（第三幕 D 的大小账）与 j(κ) 下方
第一个 M-不可达的余量。

「λ-定向完全」与第 104 章的「判定引理」对照：Prikry 的
裁决不动 stem（信息只增不减的结构保证），Silver 的下界
不丢信息（定向族的公共延展在完全性下有界）。两个「不变
量」都是「纯延长方向的封闭性」——Prikry 封闭于 stem 不动
的收窄，Silver 封闭于 ≤λ 个方向的合并。**力迫工程的安心
感来自一个封闭性条款**——这句话可以刻在第三卷第 2 章的
扉页上。
## 105.4 分解引理与 Silver 定理

> **引理 2.7（分解引理）** \(\mathbb P_{\alpha+\beta}\)
> 在 Easton 支撑与一致的极限调度下分解为
> \(\mathbb P_{\alpha+\beta}=\mathbb P_\alpha*\mathbb
> P^{(\alpha)}\)——后者是 \(V^{\mathbb P_\alpha}\) 中从 α
> 起算的同款迭代。

分解引理（证明对 β 归纳造同构 π，书 p167–168）与第 97 章
迭代超幂的结合律、第 103 章定理 2.3 因子分解同一家族：
**「先走 α 步再走 β 步 = 一次走 α+β 步」**。定理 2.10 的
证明在 M 中于 \(j(\kappa)\) 处用它切出 \(j(\mathbb P)=
\mathbb P*\mathbb Q\)——\(\mathbb Q\) 是 M 中从 κ⁺¹ 到
\(j(\kappa)^{+1}\) 的尾巴迭代。

> **定理 2.10（Silver）** κ 是 κ⁺⁺-超紧 ⟹ 存在 \(\mathbb
> P\) 使 \(V[G]\models\)「κ 可测且 \(2^\kappa=\kappa^{++}\)」。

**证明骨架**（书 p168–172，四幕）：

- **第一幕（工程）**：Easton 支撑迭代至 κ+1，每个不可达
  \(\alpha<\kappa\) 处放 \(\dot{\mathbb Q}_\alpha=
  \mathrm{Add}(\alpha,\alpha^{++})^{\,V^{\mathbb
  P_\alpha}}\)。κ-cc 由定理 2.9（T = 不可达基数的荟萃集
  提供正向极限点）；\(|\mathbb P|=\kappa^{++}\)。
- **第二幕（κ 侧）**：\(\mathbb P=\mathbb P_\kappa*
  \dot{\mathbb Q}_\kappa\)，最后一步在 κ 处 Add(κ,κ⁺⁺)
  ——保基数、\(2^\kappa=\kappa^{++}\)。到此只知道 κ 正则。
- **第三幕（提升与大拿）**：取 \((\kappa,\kappa^{++})\)-超紧
  \(j:V\to M\)（\({}^{\kappa^{++}}M\subseteq M\)）。M 中
  分解 \(j(\mathbb P)=\mathbb P*\mathbb Q\)；\(\mathbb Q\)
  在 M 中 λ-定向完全（引理 2.6(c)，λ=\(\kappa^{++}\)）。
  关键一步：对每个 \(p\in G\)，\(j(p)\upharpoonright(
  \kappa+1)=p\)（p 的支撑有界，κ⁺¹ 处已平坦）——于是
  \(D=\{j(p)\upharpoonright\text{尾}\mid p\in G\}\) 在 M[G]
  中是 \(\mathbb Q/G\) 的定向子集，大小 \(\le|\mathbb P|=
  \kappa^{++}=\lambda\)；**定向完全性给 D 一个下界 a——
  大拿**。含 a 的 \(\mathbb Q\)-泛型 H 使 \(M[G][H]=M[K]\)，
  \(j^*(\tau_G)=(j(\tau))_K\) 良定义（名字无关性由 a 保证：
  \(p\in G\Rightarrow j(p)\in K\)）。
- **第四幕（可测性）**：\(U=\{X\subseteq\kappa\mid\kappa\in
  j^*(X)\}\) 是 \(V[G]\) 中的 κ-完全超滤子。最后一个障碍：
  U 要落在 \(V[G]\) 里——断言 \((M[G])^{\lambda}\cap V[G]
  \subseteq M[G]\)（λ-封闭账：\(V[G]\) 的每个 λ-长序数函数
  的名字被 \(|\mathbb P|=\lambda\) 个条件逐点编码，编码函数
  \(g\in M\)，故 f∈M[G]）。U 由 \(j^*\) 与 \(\kappa\) 定义，
  势 λ ⟹ \(U\in V[G]\)。∎

**大拿（master condition）**是本章的明星概念：D 的下界 a
「接管」了 G 中一切条件的 j-像，使 \(K=\{(r,q)\mid r\in G,
q/G\in H\}\) 对 \(j[\mathbb P]\) 泛型。**没有 a，j-像们只是
一堆两两相容的条件；有了 a，它们被缝成一个泛型滤子**。与第
103 章 \(j^*\) 提升机对照：那边 \(j(p)=p\)（小性免费），
这边 \(j(p)\neq p\)（长度变了），必须用定向完全性**手工缝**
——「大拿是定向完全性的消费凭证」。

### 105.4d 第一幕的工程细节：迭代在不可达点之外全是平凡步

迭代定义中「α 不是不可达基数则 Q_α={1}」不是偷懒——它是
Easton 调度的**关键设计**。若在每个后继基数处也放非平凡
力迫，迭代长度 κ+1 内会有 κ 个活跃步，支撑条件（正则 μ
处 <μ）被后继步的密集活跃冲垮。只在不可达点施工使活跃点
的分布自动稀疏（不可达点之间的间隔 ≥ 其下方全部基数），
「正则 μ 处至多 <μ 个活跃坐标」因此由**间距**而非计数保
证。这正是 Silver 定理（78 章）「要动 κ 先动下方多个正则
基数」的工程化表述：下方的施工点恰好取在不可达处，每点
拉高自己的 2^α，κ 处的最后一步 Add(κ,κ⁺⁺) 才有安全的
地基。T（不可达基数的荟萃集）在定理 2.9 的链条件论证中
再次出场——「施工点荟萃」与「正向极限点荟萃」是同一张
地图的两种读法。

### 105.4a 大拿机制的逐帧补充

第三幕的「D 定向」验证值得展开（书 p171）：设 q₁,q₂∈D，
取 (pᵢ,rᵢ)∈G 见证 qᵢ=(j(pᵢ)↾尾)/G。由 G 是滤子取公共
p∈G、p≤pᵢ（并 rᵢ 的对应方），令 j(p)=(r,q)。则 q≤qᵢ
（i=1,2）——q 就是 D 内两元的公共延展。这段论证消费的
全部是：G 的滤子性 + j 的保序 + 分解形状。**定向性是 G
与 j 的合成性质**，不依赖 Q 本身的任何组合学——组合学
（λ-定向完全性）只在「取下界 a」那一步进场。

λ-封闭断言（第四幕）的编码账也值得放大：V[G] 的序数函数
f:λ→Ord 的名字 τ 被某个 p₀∈G 绑定「τ 是 λ 上的函数」。
对每个 α<λ，A_α={p≤p₀ | ∃β, p⊩τ(ᾰ)=β} 在 p₀ 下方稠密
——遇 G 得值。**编码函数** g(α,p)=「p 见证的 β」定义在
λ×P 上，|λ×P|=λ ⟹ g∈V⊆M。于是 M[G] 能算出
f(α)=min{β | ∃p∈G, g(α,p)=β}——f∈M[G]。与第 103 章
定理 2.1(f) 的名字账（|A_α|≤|P|）对照：那边数可能值、
这边数编码对——**同一枚「名字有界性」硬币的两次投掷**，
一次给小力迫的保持律、一次给大迭代的封闭断言。
### 105.4c 第三幕的困难逐项与解法对照

第三幕（提升与大拿）的四个困难及本章解法，与第 103 章
定理 2.1 的免费情形对照成表：

| 困难 | 103 章（小力迫） | 本章（大迭代） |
|---|---|---|
| j(P) 与 P 的关系 | j(P)=P（秩低被固定） | j(P)=P*Q（长度从 κ+1 变 j(κ)+1） |
| G 的 j-像 | G 直接是 M-泛型 | 须经 Q/G 的泛型 H 缝成 K |
| j-像们的相容 | 平凡（就是 G 自己） | D 定向性（滤子性+保序的合成） |
| 下界的来源 | 不需要（j(p)=p） | Q 的 λ-定向完全性 ⟹ 大拿 a |

最右列的每一条都指向本章独有的技术投资——分解引理切尾巴、
引理 2.6(c) 的封闭性、D 的构造。第四幕的 λ-封闭断言则是
「收尾账」：U 的定义用了 j*（V[G] 外的对象），要把它收回
V[G] 就须证 M[G] 对 λ-序列封闭——这个名字编码账是整台
机器的最后一颗螺丝。

### 105.4b 历史注记：Silver 1971 与「大拿」的出处

Jack Silver 1971 年的原始证明（在伦敦模型论会议发表）处
理的是「超紧之下 2^κ 可以超过 κ⁺」——当时 Easton 工具书
（1970）刚建立正则基数的自由度，Silver 定理第一次把它与
大基数保全结合。「master condition」一词据传出自
Solovay——引理 2.6 的 λ-定向完全性正是他手中「可数封闭
力迫」的迭代版。书 p171 用「大拿」翻译 master condition
是全教程最传神的译名之一：**大拿接管一切 j-像的缝合**，
如同班组长把工地上各自的进度统一成一个可交付的整体。

与第 103 章 Lévy–Solovay（1967）的对照：四年之间，力迫
从「小扰动不伤大基数」（被动保全）进化到「定向施工仍保
大基数」（主动施工）——分水岭正是「j(P)≠P 时如何提升」
这个问题。大拿是它的答案，也是此后一切迭代力迫保大基数
论证（第 107 章恰当迭代、109 泛型超幂、110 NS 饱和）的
标准部件。

## 105.5 与 Prikry 的合龙及三本账的更新

> **定理 2.11（前奏，书 p173）** κ⁺⁺-超紧 ⟹ 存在力迫使
> \(V[G]\models\)「κ 是 cf=ω 的强极限基数，\(2^{\aleph_0}=
> \aleph_1\)，且 \(2^\kappa=\kappa^{++}\)」——SCH 在 κ 处
> 失败。

组合：先小力迫成 CH（定理 2.1 保护超紧性），再 Silver 力迫
（本章），再 Prikry 力迫（第 104 章）。三步各自独立无害，
合起来兑现奇异基数假设的最小反例——第 106 章的起点。

本章在力迫谱系中的位置（三本账 + 两个新维度）：

| | 保基数 | 加子集 | 引擎 | 新维度 |
|---|---|---|---|---|
| 小力迫（103） | 全保 | 随意 | \(j^*\) 提升 | — |
| Lévy（103） | ≥κ 保 | 塌下方 | 逐值稠密 | — |
| Prikry（104） | ≥κ⁺ 保 | 无有界 | 判定引理 | 改共尾度 |
| **Silver（105）** | 全保 | **精确控制 \(2^\alpha\)** | **迭代 + 大拿** | **Easton 调度** |

「精确控制连续统函数」是 Easton 工具书（第 89–91 章）在大
基数环境下的复活：Easton 乘积只能动正则基数且要求 GCH 起点
预设；Silver 迭代**边加工边保持**（每步的可测性由下一步的大
拿论证回收）——「在飞行中修理飞机」。

### 105.5a 与 Easton 定理的三点差异

本章迭代与第 89–91 章的 Easton 乘积虽同以「Easton」为名，
差异有三。**(1) 起点**：Easton 乘积要求 GCH 预设（连续统
函数从 GCH 的骨架上拉开）；Silver 迭代从超紧基数出发，
不预设 GCH——必要时先小力迫成 CH（定理 2.1 保护超紧性），
这是定理 2.11 证明的第一句。**(2) 终点**：Easton 只动正则
基数且只能「拉高」2^α；Silver 迭代在 κ 处的取值 κ⁺⁺ 恰是
Easton 约束下的第一个合法值（κ 可测 ⟹ κ 强极限 ⟹ Easton
允许 2^κ 任意大，但 Silver 定理（78 章）要求下方先拉——
迭代自动满足）。**(3) 保全**：Easton 乘积保全 GCH 之下的
一切（相对温和）；Silver 迭代保全的恰是**κ 的可测性**——
一个 Easton 语境里根本不出现的量。三点合读：Easton 工具
书造「连续统函数的形状」，Silver 工程造「形状+大性同时
成立」——后者是前者的**带约束优化版**。
## 105.6 机器通道

### 105.6a 通道导言

七通道共享同一数据件：Silver 条件 = 有限部分函数（键 (α,ξ)、
值 b∈{0,1}——Add(α,α⁺⁺) 的影子），五种操作（偏序律/相容/
合并/支撑/贪心）在七个语言里各有一份。Task 20 Step 2 的
四个指定件全数落地：偏序律（四证明通道各一份自反/传递证
明）、条件延长的偏序律（Coq/Agda 证明主通道）、泛型滤子
搜索（Julia/Python 贪心对拍）、相遇稠密集的条件链输出
（Prolog `chain_meet`）。
### 通道一：Lean——偏序律、合并与 Easton 支撑

```lean
import Mathlib.Data.List.Basic
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Card

/-!
# 第 105 章 · Silver 力迫

锚点（有限影子）：
- `SCond`：Silver 型条件——有限部分函数（坐标 (α,ξ)、值 0/1，
  Add(α,α⁺⁺) 的影子），键无重复；
- `extC`：反向包含序（q ≤ p ⟺ p ⊆ q）——自反/传递
  （Task 20 Step 2 指定件：条件延长的偏序律）；
- `agree`/`unionC`：相容条件的合并；
- `support`/`easton_ok`：Easton 支撑（|spt ∩ μ| < μ）；
- `master_bound`：两两相容族的并是其下界——引理 2.6 定向
  完全性（大拿/master condition）的有限影子。
本体（定义 2.7–2.11、引理 2.6/2.7、定理 2.10）留在正文。
-/

namespace Settheory.Ch105

abbrev Triple : Type := ((ℕ × ℕ) × ℕ)

def wfT (x : Triple) : Prop := x.2 < 2

def keysOf (p : List Triple) : List (ℕ × ℕ) := p.map Prod.fst

def SCond (p : List Triple) : Prop :=
  (∀ x ∈ p, wfT x) ∧ (keysOf p).Nodup

/-- 反向包含：q ≤ p ⟺ p 的键值都在 q 中。 -/
def extC (p q : List Triple) : Prop := ∀ x ∈ p, x ∈ q

theorem extC_refl (p : List Triple) : extC p p :=
  fun _ hx => hx

theorem extC_trans {p q r : List Triple}
    (h₁ : extC p q) (h₂ : extC q r) : extC p r :=
  fun x hx => h₂ x (h₁ x hx)

/-- 相容：公共键上取值一致。 -/
def agree (p q : List Triple) : Prop :=
  ∀ x ∈ p, ∀ y ∈ q, x.1 = y.1 → x.2 = y.2

def unionC (p q : List Triple) : List Triple :=
  p ++ q.filter (fun y => ¬ (y.1 ∈ keysOf p))

theorem unionC_left (p q : List Triple) : extC p (unionC p q) :=
  fun _ hx => List.mem_append_left _ hx

theorem unionC_cond {p q : List Triple}
    (hp : SCond p) (hq : SCond q) :
    SCond (unionC p q) := by
  obtain ⟨hwf, hnd⟩ := hp
  obtain ⟨hwf', hnd'⟩ := hq
  refine ⟨?_, ?_⟩
  · intro x hx
    rcases List.mem_append.1 hx with h | h
    · exact hwf x h
    · exact hwf' x (List.mem_filter.1 h).1
  · unfold keysOf unionC
    rw [List.map_append]
    refine List.nodup_append.2 ⟨hnd, ?_, ?_⟩
    · exact List.Nodup.sublist
        (List.Sublist.map Prod.fst (List.filter_sublist)) hnd'
    · intro k hk j hjmem hkj
      obtain ⟨y, hy, hyj⟩ := List.mem_map.1 hjmem
      have hneg : ¬ y.1 ∈ keysOf p := by
        simpa using (List.mem_filter.1 hy).2
      rw [hyj, ← hkj] at hneg
      exact hneg hk

/-- 支撑：条件中出现的 α-坐标全体（定义 2.9 影子）。 -/
def support (p : List Triple) : List ℕ :=
  (keysOf p).map Prod.fst

/-- Easton 支撑条款：|spt(p) ∩ μ| < μ（正则 μ）。 -/
def easton_ok (p : List Triple) (μ : ℕ) : Prop :=
    (List.filter (fun a => a < μ) (support p)).length < μ

/-- 键数不超过支撑数——|dom| ≤ 2 ⟹ |spt ∩ 3| < 3。 -/
theorem easton_small_sample {p : List Triple} (h : p.length ≤ 2) :
    easton_ok p 3 := by
  have hfil : (List.filter (fun a => a < 3) (support p)).Sublist (support p) :=
    List.filter_sublist
  have hsub : (List.filter (fun a => a < 3) (support p)).length
      ≤ (support p).length := List.Sublist.length_le hfil
  have hmap : (support p).length ≤ p.length := by
    simp [support, keysOf]
  have h2 : (support p).length ≤ 2 := Nat.le_trans hmap h
  have h3 : (List.filter (fun a => a < 3) (support p)).length ≤ 2 :=
    Nat.le_trans hsub h2
  unfold easton_ok
  omega

/-- 两两相容族的并是公共下界（引理 2.6 定向完全性的有限影子：
大拿/master condition）。 -/
theorem master_bound (p q : List Triple) (ha : agree p q) :
    extC p (unionC p q) ∧ extC q (unionC p q) := by
  constructor
  · exact unionC_left p q
  · intro y hy
    by_cases hkey : y.1 ∈ keysOf p
    · obtain ⟨x, hx, hxy⟩ := List.mem_map.1 hkey
      have hyx : y = x := Prod.ext hxy.symm (ha x hx y hy hxy).symm
      rw [hyx]
      exact List.mem_append_left _ hx
    · exact List.mem_append_right _ (List.mem_filter.2 ⟨hy, by simp [hkey]⟩)

end Settheory.Ch105
```

### 通道二：Coq——布尔合并与 Easton 小条件

```coq
(* 第 105 章：Silver 条件（有限部分函数）的偏序律、合并与定向下界。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

Module Ch105.

(* 条件 = 三元组表 ((α,ξ),b)：b∈{0,1}（Add(α,α++) 的影子）。 *)
Definition wfT (x : (nat * nat) * nat) : Prop := snd x < 2.

Definition keysOf (p : list ((nat * nat) * nat)) : list (nat * nat) :=
  map fst p.

Definition SCond (p : list ((nat * nat) * nat)) : Prop :=
  (forall x, In x p -> wfT x) /\ NoDup (keysOf p).

(* 反向包含：q ≤ p ⟺ p ⊆ q。 *)
Definition extC (p q : list ((nat * nat) * nat)) : Prop :=
  forall x, In x p -> In x q.

Lemma extC_refl : forall p, extC p p.
Proof. intros p x Hx. exact Hx. Qed.

Lemma extC_trans : forall p q r,
  extC p q -> extC q r -> extC p r.
Proof.
  intros p q r H1 H2 x Hx. apply H2, H1, Hx.
Qed.

(* 偏序的反对称（列表层面：互相包含 ⟹ 同为成员集——以键值集等价计）。 *)
Lemma extC_antisym_mem : forall p q,
  extC p q -> extC q p -> forall x, In x p <-> In x q.
Proof.
  intros p q H1 H2 x. split; [apply H1 | apply H2].
Qed.

(* 相容：公共键上取值一致。 *)
Definition agree (p q : list ((nat * nat) * nat)) : Prop :=
  forall x y, In x p -> In y q -> fst x = fst y -> snd x = snd y.

(* 键相等（点级）。 *)
Definition key_eqb (k1 k2 : nat*nat) : bool :=
  andb (Nat.eqb (fst k1) (fst k2)) (Nat.eqb (snd k1) (snd k2)).

(* 合并。 *)
Definition unionC (p q : list ((nat * nat) * nat)) :=
  p ++ filter (fun y : (nat*nat)*nat =>
    negb (existsb (fun k : (nat*nat)*nat => key_eqb (fst y) (fst k)) p)) q.

(* 键成员的布尔判别与命题互译。 *)
Lemma eq_fst_eq_key : forall (y k : (nat*nat)*nat),
  fst y = fst k -> (fst y) = (fst k).
Proof. intros y k H. exact H. Qed.

Lemma key_eqb_iff : forall k1 k2, key_eqb k1 k2 = true <-> k1 = k2.
Proof.
  intros [a b] [c d]. unfold key_eqb. simpl.
  destruct (Nat.eqb_spec a c) as [E1|E1];
    destruct (Nat.eqb_spec b d) as [E2|E2]; simpl.
  - split; [intros _; f_equal; auto | reflexivity].
  - split; [discriminate | intros H; injection H; auto].
  - split; [discriminate | intros H; injection H; auto].
  - split; [discriminate | intros H; injection H; auto].
Qed.

Lemma existsb_key_iff : forall (q : list ((nat*nat)*nat)) (y : (nat*nat)*nat),
  existsb (fun k => key_eqb (fst y) (fst k)) q = true <->
  In (fst y) (keysOf q).
Proof.
  intros q y. induction q as [|a t IH].
  - simpl. split; [discriminate | contradiction].
  - split.
    + cbn [existsb]. intros H.
      apply Bool.orb_true_iff in H. destruct H as [H|H].
      * left. apply (proj1 (key_eqb_iff _ _)) in H.
        symmetry. exact H.
      * right. apply (proj1 IH). exact H.
    + unfold keysOf. rewrite map_cons. cbn [In].
      intros [H|H].
      * apply Bool.orb_true_intro. left.
        apply (proj2 (key_eqb_iff (fst y) (fst a))).
        symmetry. exact H.
      * apply Bool.orb_true_intro. right.
        apply (proj2 IH). exact H.
Qed.

Lemma unionC_left : forall p q, extC p (unionC p q).
Proof.
  intros p q x Hx. apply in_or_app. left. exact Hx.
Qed.

Lemma nodup_map_filter : forall (f : (nat*nat)*nat -> bool) l,
  NoDup (keysOf l) -> NoDup (keysOf (filter f l)).
Proof.
  intros f l. induction l as [|a t IH]; intros H; simpl.
  - constructor.
  - unfold keysOf in *. simpl.
    destruct (f a) eqn:E; simpl.
    + inversion H as [|x l' Hnotin Hnd]; subst.
      constructor; [| apply IH; assumption].
      intros Hin.
      apply (proj1 (in_map_iff fst (filter f t) (fst a))) in Hin.
      destruct Hin as [z [Hfz Hz]].
      apply (proj1 (filter_In f z t)) in Hz. destruct Hz as [Hz _].
      apply Hnotin. rewrite <- Hfz. apply in_map. exact Hz.
    + apply IH. inversion H; assumption.
Qed.

Lemma unionC_cond : forall p q,
  SCond p -> SCond q -> SCond (unionC p q).
Proof.
  intros p q (hw & hnd) (hw' & hnd'). split.
  - intros x Hx. apply in_app_or in Hx.
    destruct Hx as [H|H].
    + apply hw, H.
    + apply hw'. apply filter_In in H. destruct H as [H _]; exact H.
  - unfold unionC, keysOf. rewrite map_app.
    apply NoDup_app.
    + exact hnd.
    + apply nodup_map_filter. exact hnd'.
    + intros a Ha Hb.
      apply (proj1 (in_map_iff fst
        (filter (fun y => negb (existsb (fun k => key_eqb (fst y) (fst k)) p)) q) a)) in Hb.
      destruct Hb as [y [Hfy Hy]].
      apply (proj1 (filter_In _ y q)) in Hy.
      destruct Hy as [Hy Hb'].
      simpl in Hb'.
      apply Bool.negb_true_iff in Hb'.
      apply Bool.not_true_iff_false in Hb'.
      assert (Hne : ~ In (fst y) (keysOf p)).
      { intros Hky. apply (proj2 (existsb_key_iff p y)) in Hky.
        congruence. }
      apply Hne. unfold keysOf in Ha. rewrite Hfy. exact Ha.
Qed.

(* 两两相容族的并是公共下界（引理 2.6 定向完全性/大拿的有限影子）。 *)
Lemma master_bound : forall p q,
  agree p q ->
  extC p (unionC p q) /\ extC q (unionC p q).
Proof.
  intros p q Hag. split; [apply unionC_left|].
  intros y Hy.
  destruct (existsb (fun k => key_eqb (fst y) (fst k)) p) eqn:E.
  - apply (proj1 (existsb_key_iff p y)) in E.
    apply (proj1 (in_map_iff fst p (fst y))) in E.
    destruct E as [x [Hfx Hx]].
    assert (Hex : y = x).
    { destruct y as [[a b] c]. destruct x as [[d e] f].
      simpl in Hfx. injection Hfx as Hd He.
      subst d. subst e.
      assert (Hcf : c = f).
      { assert (Hfc := Hag (a, b, f) (a, b, c) Hx Hy (eq_refl (a, b))).
        simpl in Hfc. symmetry. exact Hfc. }
      rewrite Hcf. reflexivity. }
    rewrite Hex. apply in_or_app. left. exact Hx.
  - apply in_or_app. right. apply filter_In. split; [exact Hy|].
    apply Bool.negb_true_iff. rewrite E. reflexivity.
Qed.

(* 支撑与 Easton 条款（定义 2.9/2.10 影子）。 *)
Definition support (p : list ((nat * nat) * nat)) : list nat :=
  map (fun x => fst (fst x)) p.

Definition easton_ok (p : list ((nat * nat) * nat)) (mu : nat) : Prop :=
  length (filter (fun a => a <? mu) (support p)) < mu.

Lemma easton_small : forall p,
  length p <= 2 -> easton_ok p 3.
Proof.
  intros p H.
  assert (Hf : forall (f : nat -> bool) l, length (filter f l) <= length l).
  { intros f. induction l as [|a t IH]; simpl.
    - reflexivity.
    - destruct (f a); simpl.
      + apply le_n_S. exact IH.
      + apply Nat.le_le_succ_r. exact IH. }
  unfold easton_ok, support.
  pose proof (Hf (fun a => a <? 3) (map (fun x => fst (fst x)) p)) as H1.
  rewrite length_map in H1.
  lia.
Qed.

End Ch105.
```

### 通道三：Agda——构造性偏序律与支撑

```agda
-- 第 105 章：Silver 条件（有限部分函数）的偏序律、合并与支撑。
module Ch105_silver where

open import Data.Nat using (ℕ; zero; suc; _<_; _≤_; z≤n; s≤s; _<ᵇ_)
open import Data.Nat.Properties using (≤-refl; ≤-trans; m≤n⇒m≤1+n)
open import Data.List using (List; []; _∷_; _++_; filterᵇ; length)
open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong; trans)
open import Relation.Nullary using (¬_)

-- ── 零、自建件 ──

nat-eq : ℕ → ℕ → Bool
nat-eq zero zero = true
nat-eq zero (suc _) = false
nat-eq (suc _) zero = false
nat-eq (suc m) (suc n) = nat-eq m n

key-eq : ℕ × ℕ → ℕ × ℕ → Bool
key-eq (a , b) (c , d) = if nat-eq a c then nat-eq b d else false

data _∈L_ {A : Set} : A → List A → Set where
  here  : ∀ {x xs} → x ∈L (x ∷ xs)
  there : ∀ {y x xs} → x ∈L xs → x ∈L (y ∷ xs)

∈-++₁ : ∀ {A : Set} (x : A) (l r : List A) →
  (x ∈L l) ⊎ (x ∈L r) → x ∈L (l ++ r)
∈-++₁ x [] r (inj₁ ())
∈-++₁ x (y ∷ l) r (inj₁ here) = here
∈-++₁ x (y ∷ l) r (inj₁ (there h)) =
  there (∈-++₁ x l r (inj₁ h))
∈-++₁ x [] r (inj₂ h) = h
∈-++₁ x (y ∷ l) r (inj₂ h) =
  there (∈-++₁ x l r (inj₂ h))

Triple : Set
Triple = (ℕ × ℕ) × ℕ

-- ── 一、Silver 条件与偏序律（Task 20 Step 2 指定件） ──

-- 反向包含：q ≤ p ⟺ p ⊆ q。
extC : List Triple → List Triple → Set
extC p q = ∀ x → x ∈L p → x ∈L q

extC-refl : ∀ p → extC p p
extC-refl p x h = h

extC-trans : ∀ p q r → extC p q → extC q r → extC p r
extC-trans p q r h₁ h₂ x hx = h₂ x (h₁ x hx)

keys : List Triple → List (ℕ × ℕ)
keys [] = []
keys ((k , _) ∷ t) = k ∷ keys t

inKeys : ℕ × ℕ → List (ℕ × ℕ) → Bool
inKeys k [] = false
inKeys k (k' ∷ t) = if key-eq k k' then true else inKeys k t

-- 合并：q 中去掉已覆盖键。
splice : List (ℕ × ℕ) → List Triple → List Triple
splice ks [] = []
splice ks (x@((k , n) , _) ∷ t) =
  if inKeys (k , n) ks then splice ks t else x ∷ splice ks t

unionC : List Triple → List Triple → List Triple
unionC p q = p ++ splice (keys p) q

unionC-left : ∀ p q x → x ∈L p → x ∈L (unionC p q)
unionC-left p q x hx =
  ∈-++₁ x p (splice (keys p) q) (inj₁ hx)

-- ── 二、支撑与 Easton 条款（定义 2.9/2.10 影子） ──

support : List Triple → List ℕ
support [] = []
support (((a , _) , _) ∷ t) = a ∷ support t

below : ℕ → List ℕ → List ℕ
below mu l = filterᵇ (λ a → a <ᵇ mu) l

easton-ok : List Triple → ℕ → Set
easton-ok p mu = length (below mu (support p)) < mu

-- filter 长度不超过原表（自证）。
below-length : ∀ mu l → length (below mu l) ≤ length l
below-length mu [] = z≤n
below-length mu (a ∷ t) with a <ᵇ mu
... | true = s≤s (below-length mu t)
... | false = m≤n⇒m≤1+n (below-length mu t)

support-length : ∀ p → length (support p) ≤ length p
support-length [] = z≤n
support-length (((a , _) , _) ∷ t) = s≤s (support-length t)

-- |dom| ≤ 2 ⟹ |spt ∩ 3| < 3（Easton 小条件样本）。
easton-small : ∀ p → length p ≤ 2 → easton-ok p 3
easton-small p h =
  s≤s (≤-trans (below-length 3 (support p))
    (≤-trans (support-length p) h))

-- ── 三、相容（键不相交 ⟹ 相容）与大拿影子样本 ──

agree : List Triple → List Triple → Set
agree p q = ∀ x y → x ∈L p → y ∈L q →
  proj₁ x ≡ proj₁ y → proj₂ x ≡ proj₂ y

-- 样本：键不相交时相容性空洞成立（键等式不可满足）。
key-disjoint-agree :
  agree (((0 , 0) , 0) ∷ []) (((1 , 0) , 1) ∷ [])
key-disjoint-agree _ _ here here hkey = cong proj₁ hkey
key-disjoint-agree _ _ here (there ())
key-disjoint-agree _ _ (there ()) _

-- 合并是两侧的下界（大拿/master condition 的双元样本）。
unionC-master-left : ∀ p q → extC p (unionC p q)
unionC-master-left p q x hx =
  ∈-++₁ x p (splice (keys p) q) (inj₁ hx)
```

### 通道四：Julia——贪心搜索与定向下界

```julia
# 第 105 章：Silver 条件（有限部分函数）、Easton 支撑与贪心泛型搜索。
println("==== 105")

# ── 一、条件与偏序律（Add(α,α⁺⁺) 的影子：坐标 (α,ξ)、值 0/1）──
# 条件 = Dict{(Int,Int) => Int}，值域 {0,1}。
is_cond(p) = all(0 ≤ v ≤ 1 for v in values(p))

# 反向包含：q ≤ p ⟺ p ⊆ q（更强的条件信息更多）。
extC(p, q) = all(haskey(q, k) && q[k] == v for (k, v) in p)

agree(p, q) = all(p[k] == q[k] for k in keys(p) if haskey(q, k))

function merge(p, q)
    r = copy(p)
    for (k, v) in q
        if !haskey(r, k); r[k] = v; end
    end
    r
end

# 偏序律样本（Task 20 Step 2 指定件）。
p0 = Dict((0, 0) => 1)
q0 = Dict((0, 0) => 1, (1, 2) => 0)
r0 = Dict((0, 0) => 1, (1, 2) => 0, (3, 5) => 1)
@assert extC(p0, p0)                       # 自反
@assert extC(p0, q0) && extC(q0, r0) && extC(p0, r0)  # 传递
@assert is_cond(q0) && agree(p0, q0)
@assert merge(p0, q0) == q0                # 合并 = 下确界

# 冲突样本：公共键值不同 ⟹ 不相容。
c1 = Dict((0, 0) => 1); c2 = Dict((0, 0) => 0)
@assert !agree(c1, c2)

# ── 二、Easton 支撑（定义 2.9/2.10 影子）──
# spt(p) = 出现的 α-坐标全体；Easton：|spt ∩ μ| < μ（正则 μ）。
support(p) = Set(k[1] for k in keys(p))
easton_ok(p, μ) = count(a -> a < μ, support(p)) < μ

@assert support(q0) == Set([0, 1])
@assert !easton_ok(q0, 2)                  # {0,1} ∩ [0,2) 计 2 ≮ 2 → 假
@assert easton_ok(q0, 3)                   # 2 < 3 ✓
@assert !easton_ok(p0, 1)                  # 1 ≮ 1 → 假
@assert easton_ok(p0, 2)                   # 1 < 2 ✓

# ── 三、贪心泛型搜索（有限稠密族相遇）──
# D(α,ξ,b) = {p | p(α,ξ) = b}——每个坐标-值对都可被击中。
function greedy(targets)
    p = Dict{Tuple{Int,Int},Int}()
    for ((α, ξ), b) in targets
        if !haskey(p, (α, ξ)); p[(α, ξ)] = b; end
    end
    p
end

targets = [((α, ξ), b) for α in 0:2, ξ in 0:1, b in 0:1]
g = greedy(targets)
@assert is_cond(g)
@assert g[(0, 0)] == 0                     # b=0 先到先占
@assert all(g[(α, ξ)] == 0 for α in 0:2, ξ in 0:1)   # 每坐标首个值获胜

# ── 四、定向下界（引理 2.6 大拿/master condition 影子）──
# 定向族：两两有公共延展 ⟹ 并是下界。有限层两两相容即定向。
D = [Dict((0,0)=>1), Dict((1,1)=>0), Dict((0,0)=>1, (1,1)=>0)]
@assert all(agree(D[i], D[j]) for i in 1:3, j in 1:3)
master = merge(merge(D[1], D[2]), D[3])
@assert extC(D[1], master) && extC(D[2], master) && extC(D[3], master)
@assert is_cond(master)

println("Julia：偏序律（自反/传递）、Easton 支撑正反样本、贪心相遇、")
println("定向族的并是下界（大拿影子）——合并=下确界")
println("END ====")
```

### 通道五：Python——独立对拍

```python
# 第 105 章：与 Julia 独立对拍——偏序律、Easton 支撑、贪心相遇与定向下界。
import io
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def is_cond(p):
    return all(0 <= v <= 1 for v in p.values())


def ext_c(p, q):
    return all(k in q and q[k] == v for k, v in p.items())


def agree(p, q):
    return all(p[k] == q[k] for k in p.keys() & q.keys())


def merge(p, q):
    r = dict(p)
    for k, v in q.items():
        if k not in r:
            r[k] = v
    return r


def support(p):
    return {k[0] for k in p}


def easton_ok(p, mu):
    return sum(1 for a in support(p) if a < mu) < mu


def greedy(targets):
    p = {}
    for (k, b) in targets:
        if k not in p:
            p[k] = b
    return p


def main():
    print("==== 105")
    p0 = {(0, 0): 1}
    q0 = {(0, 0): 1, (1, 2): 0}
    r0 = {(0, 0): 1, (1, 2): 0, (3, 5): 1}
    assert ext_c(p0, p0)
    assert ext_c(p0, q0) and ext_c(q0, r0) and ext_c(p0, r0)
    assert is_cond(q0) and agree(p0, q0)
    assert merge(p0, q0) == q0

    c1 = {(0, 0): 1}
    c2 = {(0, 0): 0}
    assert not agree(c1, c2)

    # Easton 支撑正反样本（与 Julia 逐条对拍）。
    assert support(q0) == {0, 1}
    assert not easton_ok(q0, 2)
    assert easton_ok(q0, 3)
    assert not easton_ok(p0, 1)
    assert easton_ok(p0, 2)

    # 贪心相遇：先到先占。
    targets = [((a, x), b) for a in range(3) for x in range(2)
               for b in range(2)]
    g = greedy(targets)
    assert is_cond(g)
    assert g[(0, 0)] == 0
    assert all(g[(a, x)] == 0 for a in range(3) for x in range(2))

    # 定向下界（大拿影子）：两两相容族的并是公共延展。
    d = [{(0, 0): 1}, {(1, 1): 0}, {(0, 0): 1, (1, 1): 0}]
    assert all(agree(d[i], d[j]) for i in range(3) for j in range(3))
    master = merge(merge(d[0], d[1]), d[2])
    assert all(ext_c(di, master) for di in d)
    assert is_cond(master)

    print("Python：偏序律、Easton 支撑、贪心相遇、定向下界——与 Julia 对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
```

### 通道六：Prolog——条件链输出

```prolog
:- encoding(utf8).
% 第 105 章：Silver 条件的偏序查询、Easton 支撑与相遇稠密集的条件链。

% 条件 = 三元组表 ((α,ξ),b)：b∈{0,1}。
lookup((A, X), [((A, X), B)|_], B) :- !.
lookup(K, [_|T], B) :- lookup(K, T, B).

has_key(K, [(K, _)|_]) :- !.
has_key(K, [_|T]) :- has_key(K, T).

% 反向包含：q ≤ p ⟺ p ⊆ q。
extC([], _).
extC([(K, B)|T], Q) :- lookup(K, Q, B), extC(T, Q).

% 相容。
agree(P, Q) :-
    forall((member((K, B1), P), lookup(K, Q, B2)), B1 == B2).

% 合并：q 中去掉已覆盖键后拼接。
merge(P, Q, R) :- include(not_covered(P), Q, Q1), append(P, Q1, R).
not_covered(P, (K, _)) :- \+ has_key(K, P).

% 支撑：α-坐标全体（去重）。
support(P, S) :-
    findall(A, member(((A, _), _), P), S0),
    remove_dup(S0, S).
remove_dup([], []).
remove_dup([H|T], [H|R]) :- exclude(=(H), T, T1), remove_dup(T1, R).

% Easton 条款：|spt ∩ μ| < μ。
easton_ok(P, Mu) :-
    support(P, S),
    findall(A, (member(A, S), A < Mu), Sub),
    length(Sub, N), N < Mu.

% 相遇稠密集的条件链（Task 20 Step 2 指定件：输出链）。
chain_meet([], P, P).
chain_meet([K-B|Ts], P, R) :-
    ( has_key(K, P) -> P1 = P
    ; append(P, [(K, B)], P1) ),
    chain_meet(Ts, P1, R).

main :-
    format("==== 105~n"),
    % 偏序律样本。
    extC([((0,0),1)], [((0,0),1), ((1,2),0)]),
    extC([((0,0),1), ((1,2),0)],
         [((0,0),1), ((1,2),0), ((3,5),1)]),
    extC([((0,0),1)], [((0,0),1), ((1,2),0), ((3,5),1)]),
    \+ extC([((0,0),1), ((9,9),0)], [((0,0),1)]),
    % 相容与合并。
    agree([((0,0),1)], [((1,2),0)]),
    \+ agree([((0,0),1)], [((0,0),0)]),
    merge([((0,0),1)], [((1,2),0)], R1),
    R1 == [((0,0),1), ((1,2),0)],
    % Easton 支撑正反样本。
    easton_ok([((0,0),1), ((1,2),0)], 3),
    \+ easton_ok([((0,0),1), ((1,2),0)], 2),
    easton_ok([((0,0),1)], 2),
    \+ easton_ok([((0,0),1)], 1),
    % 相遇条件链：目标序列逐个击中。
    findall(((A, X)-0), (between(0, 2, A), between(0, 1, X)), Ts),
    chain_meet(Ts, [], R),
    length(R, 6),
    forall((between(0, 2, A), between(0, 1, X)), lookup((A, X), R, 0)),
    format("偏序律/相容/合并/Easton 支撑正反；条件链相遇 6 目标~n"),
    writeln("END ====").
```

### 通道七：Isabelle——集论层的定向下界

```isabelle
theory Silver
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 105 章：Silver 条件（有限部分函数）的偏序律与定向下界
（引理 2.6 大拿/master condition 影子）。确定性规则链，不用 blast/auto。
Easton 支撑迭代与定理 2.10 留在正文。\<close>

text \<open>反向包含序：q \<le> p \<equiv> p \<subseteq> q（条件层，以集合表示部分函数的图）。\<close>

definition extP :: "[i, i] \<Rightarrow> o" where
  "extP(p, q) \<equiv> p \<subseteq> q"

lemma extP_refl: "extP(p, p)"
  unfolding extP_def by (rule subset_refl)

lemma extP_trans:
  assumes h1: "extP(p, q)" and h2: "extP(q, r)"
  shows "extP(p, r)"
proof -
  from h1 have s1: "p \<subseteq> q" unfolding extP_def .
  from h2 have s2: "q \<subseteq> r" unfolding extP_def .
  from s1 s2 have s: "p \<subseteq> r" by (rule subset_trans)
  show ?thesis unfolding extP_def by (rule s)
qed

text \<open>两两相容族的并是公共下界（定向完全性的最小情形）。\<close>

lemma union_lower_left:
  assumes sub: "\<forall>d\<in>D. d \<subseteq> A"
  shows "\<forall>d\<in>D. extP(d, A)"
proof
  fix d
  assume hd: "d \<in> D"
  from sub hd have hsub: "d \<subseteq> A" by (rule bspec)
  show "extP(d, A)" unfolding extP_def by (rule hsub)
qed

text \<open>定向族的并：D 定向且 D 的元素两两有公共延展（以 A 为上界）
则 A 是 D 的下界——引理 2.6(a) 的两条件版本。\<close>

lemma directed_bound:
  assumes dir: "\<forall>d1\<in>D. \<forall>d2\<in>D. d1 \<union> d2 \<in> D"
    and cup: "\<Union>D = A"
  shows "\<forall>d\<in>D. extP(d, A)"
proof
  fix d
  assume hd: "d \<in> D"
  have hsub: "d \<subseteq> \<Union>D"
  proof
    fix x
    assume hx: "x \<in> d"
    from hd have hmem: "d \<in> D" .
    show "x \<in> \<Union>D"
    proof (rule UnionI [of d D])
      show "x \<in> d" by (rule hx)
    qed (rule hmem)
  qed
  from cup have hDA: "\<Union>D \<subseteq> A" by (rule equalityD1)
  from hsub hDA show "extP(d, A)" unfolding extP_def
    by (rule subset_trans)
qed

end
```


### 105.6b Julia/Python 对拍详注

Julia/Python 的对拍面比前几章更宽（五组断言族）：

1. **偏序律族**：自反（extC(p,p)）、传递（p⊆q⊆r ⟹ p⊆r
   三样本链）、反对称的成员集版本（Coq 证，脚本层两侧只
   核包含）；
2. **Easton 族**：同一条件 q₀（支撑 {0,1}）在 μ=2 处假、
   μ=3 处真；p₀（支撑 {0}）在 μ=1 假、μ=2 真——**边界值
   恰在 |S∩μ|=μ 处翻转**，两侧逐条对拍；
3. **贪心族**：6 坐标 × 2 值的目标序列先到先占（含同键
   双值时首个获胜——与 Prolog chain_meet 的 has_key 截断
   同构）；
4. **下界族**：三个两两相容条件（其中第三个已是前两个的
   并）的 master 合并后仍是条件且包含每一个——**双重检验**
   （是条件 + 是下界）。

对拍纪律的价值在本章两次兑现：Julia 首版 Easton 断言方向
反写（把 2≮2 的假断言写成真）——AssertionError 第一时间
抓获；master 包含方向反写两处——对拍逐条比对面暴露。数学
方向题（「谁包含谁」是序方向的纯语法）在对拍层最易翻车，
因为两侧各自「自洽地错」不会报警——**硬编码期望值**（
Python 侧的手写 expect）是最后一道网。

### 105.6c Prolog 条件链的输出形态

`chain_meet` 的输出链（六个目标逐个击中后的 R）值得逐元
素读一遍：

    R = [((0,0),0), ((0,1),0), ((1,0),0), ((1,1),0), ((2,0),0), ((2,1),0)]

每个元素 ((α,ξ),b) 是「条件链在第 (α,ξ) 坐标处落子 0」。
链的构造完全由目标序列的顺序决定（findall 的枚举序：
α 外层、ξ 内层），同键双值目标（若把 B 也枚举进 findall）
只消耗第一击——has_key 截断。**这与 Julia 贪心的「先到先占」
在语义上完全同构**，但形态不同：Prolog 输出的是**链本身**
（可继续查询——如「哪个目标被第 k 步击中」），Julia 输出
的是**终点条件**。查询能力与计算能力的取舍在力迫章的
机器层也成立：条件链是泛型滤子的「骨架」（G = 一切与链
相容的条件），骨架可查询 ⟹ 可以问「D_β 在第几步被击中」
——这正是书 p152 稠密性论证的执行序。

### 通道注记

**Lean**（证明三件套最全）：`extC` 偏序律一行一件；`unionC_cond`
的 NoDup 第三段用 `intro k hk j hjmem hkj` 四参形状（nodup_
append 的第三分量在 4.33 是五段 intro——k∈l₁、j∈l₂、k=j 的
**等式**而非不等式：`rw [hyj, ← hkj] at hneg` 的方向账是本
章 Lean 最重的一笔）；`easton_small_sample` 用 Sublist 长度
单调 + `simp [support, keysOf]` 收口。

**Coq**（布尔键相等主通道）：复合键 (α,ξ) 不能直接 Nat.eqb
（类型不匹配——首版当场炸），自建 `key_eqb`（双分量 andb）+
`key_eqb_iff` 互译；`existsb_key_iff` 的两个方向各需一次
`symmetry` 摆位（In-cons 的等式方向与 key_eqb 的方向相反）；
`filter_In` 与 `in_map_iff` 都须**显式全参**（y 给全、组件序
f x = y 在前——103 章同坑重演）；filter 长度引理在 8.20 下
用 stdlib 的会触发 setoid rewrite 的 UNDEFINED EVARS——自证
两行归纳代替。

**Agda**（构造性偏序律 + 支撑）：本版 stdlib 的 Data.List.
**filter 是 Dec 版**（Bool 版叫 `filterᵇ`——首版类型不匹配
三次才定位）；`≤-step` 已弃用（改 `m≤n⇒m≤1+n`）；
`_<?_` 返回 Dec 不是 Bool（比较谓词须用 `<ᵇ`）；easton-small
的三步长度链（filter ≤ 原 ≤ dom ≤ 2 ⟹ < 3）全部构造性。

**Julia/Python**（对拍三线）：偏序律样本（自反/传递/合并=
下确界）、Easton 支撑正反（**Julia 首版把 2≮2 的假断言写成
真断言——AssertionError 当场抓获**，改向后与 Python 逐条
对拍）、贪心搜索（先到先占——目标含同键两值时首个获胜）与
定向下界（**master 的包含方向首版写反两处**：d ⊆ master 是
extC(d, master)，master ≤ d 的「≤」是反向包含序的「被包含」）。

**Prolog**（条件链输出主通道）：`chain_meet/3` 逐目标扩展
输出链——**findall 模板 (A-X)-0 造出的是中缀复合项 -(A,X)
而不是二元组 (A,X)**，lookup 键不匹配静默假绿（逐段 bisect
定位后改 ((A, X)-0)）；这正是「项的形状即类型」的 Prolog 版
教训（与 Agda 构造子形状、Coq implicit 推断并列）。

**Isabelle**（集论层定向下界）：`directed_bound` 用
`equalityD1`（单链使用——from 双事实时多余事实阻断 apply，
首版炸）、`UnionI` 二参显式；确定性规则链风格第 103 章起
已是本工程 ZF 通道的默认。

### 机器件与引理对应总表（Task 20 Step 3）

| 机器件 | 对应力迫引理 | 声明边界 |
|---|---|---|
| `extC` 自反/传递 | 定义 2.7(c)(iii) 的语法前提 | 定义公理，无引理内容 |
| `agree`/`unionC`/`merge` | 引理 2.6(a) 两条件情形的有限退化 | 有限层「定向=两两相容」；不声称 λ 无穷层 |
| `easton_ok` 正反 | 定义 2.10 条款核查 | 纯定义；不声称 Easton 调度 |
| `greedy`/`chain_meet` | 第 103 章定理 2.2 稠密机制复演 | 不涉及本章新引理 |
| `master_bound`/`directed_bound` | 引理 2.6 定向完全性有限影子 | 大拿存在性语法；不声称第三幕构造 |
## 105.7 机器的边界与对应力迫引理清单

Task 20 Step 3 的要求逐条兑现——每个机器件对应哪条引理、
不声称验证了什么：

1. **偏序律（七通道 `extC` 自反/传递）** ⟷ 迭代力迫定义
   2.7(c)(iii) 的「限制映射保序」条款的**语法前提**。对应
   引理：无——这是定义的公理部分。不声称：任何迭代层面的
   性质。
2. **相容合并（`agree`/`unionC`/`merge`）** ⟷ 引理 2.6(a)
   的两条件情形（P 与 Q 各 λ-定向完全 ⟹ 乘积也然）的
   **有限退化版**：有限层「定向」退化为「两两相容」、
   「下界」退化为「并」。不声称：λ 无穷层的封闭性。
3. **Easton 支撑样本（`easton_ok` 正反各二）** ⟷ 定义
   2.10 的条款核查——**纯定义核查**，无引理内容。不声称：
   Easton 调度（事实 2.4.2 的正则/反向取舍）的任何部分。
4. **贪心搜索与条件链（Julia `greedy`/Prolog `chain_meet`）**
   ⟷ 第 103 章定理 2.2 的稠密性机制（每个坐标-值对可被
   击中）在 Silver 条件上的复演——**不涉及**本章任何新
   引理（定理 2.9 的荟萃账不可见）。
5. **定向下界（`master_bound`/`unionC-master`/Isabelle
   `directed_bound`）** ⟷ 引理 2.6 定向完全性的有限影子：
   有限族的两两相容 ⟹ 并是公共下界。这是「大拿」的**存在
   性语法**，不声称：大拿在无穷迭代中的构造（第三幕）。
6. **不可机化清单**：迭代定义 2.7 的融合与截断族、两种
   极限（2.8）的正则/奇异调度、链条件定理 2.9 的荟萃账、
   分解引理 2.7 的归纳同构、定理 2.10 四幕全部（提升、
   大拿、λ-封闭断言、U 的落地）。

### 105.7a 有限实验的诚实边界（Step 3 核心声明）

本章机器件**只验证条件层的语法事实**：偏序律、合并律、
支撑核查、贪心机制、定向下界的有限形态。以下诸项**一律
不声称**：

- 「2^κ=κ⁺⁺ 在任何意义下被验证」——连续统函数的取值是
  基数算术命题，有限宇宙的 |dom|≤2 与 κ⁺⁺ 无任何关系；
- 「κ 的可测性被保持」——大拿在有限层退化成「两两相容族
  的并」，与 λ-定向完全性的差距是整个第三幕；
- 「Easton 调度被模拟」——正则/反向极限的取舍是关于 cf(δ)
  的超穷陈述，有限宇宙没有奇异极限步；
- 「迭代被实现」——七通道的条件都是**单步** Silver 条件，
  迭代（定义 2.7 的序列结构）完全留在正文。

机器件的真实价值：把定理 2.10 证明中**可有限化的语法件**
（偏序律=定义 2.7(c)(iii) 前提、合并=引理 2.6(a) 退化、
支撑=定义 2.10 条款、下界=大拿存在性语法）做成可执行对
拍——它们是证明的「砖块」，砖块合法不等于房子盖成，但
砖块非法则房子必塌。**「砖块检验 + 房子讲解」的分工**是
本教程力迫章机器设计的统一原则。
### 105.7b 七通道的实测坑合订（工程档案）

本章 Coq 是全教程单章 Coq 坑密度之最（十四轮修复）：复合
键布尔相等（key_eqb 自建）、existsb_key_iff 双方向 symmetry
摆位、in_map_iff/filter_In 显式参、filter 长度 setoid 炸、
map_length 弃用、prod 相等的 f_equal 不可用（变量不透明时
f_equal 不分解——改 destruct 到分量级 + injection）、
Hag 应用需显式全参（Hag (a,b,f) (a,b,c) Hx Hy eq_refl）。
Julia 的两处方向错账（Easton 断言反写、master 包含反写）
都被 AssertionError 当场抓获——**对拍纪律的价值在方向题上
最亮**。Prolog 的中缀项静默假绿（(A-X)-0 vs (A,X)）是
「形状即类型」教训的 Prolog 版。这些全部入账 PLAN 与记忆。
## 105.8 本章要点与检查问题

- **战役**：超紧 κ ⟹（Silver 迭代）可测 κ + 2^κ=κ⁺⁺ ⟹
  （Prikry）cf=ω 强极限 + 2^κ=κ⁺⁺——SCH 最小反例的两步走。
- **迭代三件套**：定义 2.7（融合 + 截断族）、定义 2.8
  （正向=平坦极限/反向=极端极限）、定义 2.9/2.10（支撑；
  Easton=正则处吝啬奇异处慷慨）。
- **封闭性**：定理 2.9（κ-cc 在正向极限 + 荟萃正向点下
  保持）；引理 2.6 三款（乘积/正向/Easton 迭代下 λ-定向
  完全）。
- **分解引理 2.7**：P_{α+β} = P_α * P^(α)——第 97/103 章
  结合律家族的力迫版。
- **定理 2.10 四幕**：工程（Easton 迭代 + 不可达荟萃）→
  κ 侧（最后一步 Add(κ,κ⁺⁺)）→ 提升与大拿（j(P)=P*Q、
  D 定向、a 下界、j* 良定义）→ 可测性（U 落地，λ-封闭
  断言）。**大拿 = 定向完全性的消费凭证**。
- **三本账更新**：Silver 增加两个新维度——连续统函数的
  精确控制与 Easton 调度；「在飞行中修理飞机」。
- **实测账**：Lean extends 保留字冲突（改 extC）、
  nodup_append 第三分量四参形状（intro k hk j hjmem hkj
  + rw [hyj, ← hkj] at hneg 的方向账）、List.filter 构造侧
  decide 桥；Coq key_eqb 双分量布尔键相等（Nat.eqb 直接
  比较复合键类型不匹配——首版炸）、existsb_key_iff 的
  Bool.orb_true_intro 方向账（⟸ 侧 symmetry 摆位）、
  in_map_iff **显式给 y** 且组件序 f x = y 在前、
  filter_In 显式三参、filter 长度引理自证（8.20 的
  filter_length_le 需 setoid rewrite 炸 UNDEFINED EVARS）、
  map_length 弃用改 length_map；Agda Data.List.filter 是
  **Dec 版**（Bool 版叫 filterᵇ——首版类型不匹配）、
  ≤-step 弃用改 m≤n⇒m≤1+n、_<?_ 是 Dec 不是 Bool（用
  <ᵇ）；Julia 首版 Easton 正反断言方向写反（2 ≮ 2 的假
  断言当场被 AssertionError 抓获）、master 下界的包含方向
  （d ⊆ master 是 extC(d, master)——首版写反两处）、
  贪心目标含 (0,0) 时 b=0 先到先占；Prolog findall 模板
  (A-X)-0 造出的是中缀复合项不是 (A,X) 对——lookup 键
  不匹配静默假绿（bisect 定位后改 ((A, X)-0)）；Isabelle
  equalityD1 单链使用（from 双事实时多余事实阻断 apply）、
  UnionI 二参显式。

检查问题：

1. 定义 2.8 的正向极限要求「某点之后全取 1」。在 Easton
   支撑迭代中，为什么恰好是**正则基数处**取正向极限保证
   κ-cc（定理 2.9 的荟萃账用在哪一步）？若在某个正则 μ
   处误取反向极限，cc 会在哪里断？
2. 引理 2.6(c) 要求 cf(β)≤λ 的极限步取**反向**极限。把
   「≤λ」改成「<λ」会破坏哪一款应用（提示：定理 2.10 的
   λ=κ⁺⁺ 与哪些极限步的共尾度相撞）？
3. 大拿 a 的定义域为什么恰是 D={j(p)↾尾 | p∈G} 而不是
   {j(p) | p∈G} 全体？（j(p) 的长度是 j(κ)+1 ≠ κ+1，
   前者根本不是 Q 的条件。）
4. Julia/Python 的 easton_ok 样本中断言 !easton_ok(q0, 2)
   与 easton_ok(q0, 3)。给出一个有限宇宙中支撑 S 与 μ 的
   组合使「|S∩μ|<μ 对一切正则 μ 成立但对某个奇异 μ′ 失败」，
   并说明真值层 Easton 条款为何只查正则 μ（提示：反向
   极限在奇异处的角色）。
5. Prolog 通道的 chain_meet 输出了一条 6 目标条件链。
   把目标序列改成先全 (α,1) 后全 (α,0)（同键两值），链
   的形态如何变化？这与贪心（Julia）的「先到先占」在
   哪一点上等价、在哪一点上分流（提示：has_key 的截断）。


## 105.9 与前后章的缆绳

- **向上（机器地基）**：第 89–91 章 Easton 工具书（正则基数
  上连续统函数的自由度）是本章迭代的原型——Easton 乘积要求
  GCH 预设、一次成型；Silver 迭代**边加工边保持**，每步的
  安全性由下一步回收（大拿论证）。第 103 章三本表 +
  \(j^*\) 提升机是本章第四幕的模板——差别只在 \(j(p)\neq
  p\)（长度变了），须用定向完全性手工缝合。
- **横向（力迫谱系）**：Prikry（104）改共尾度不加子集；
  Silver（105）加子集保基数——两者**正交**，组合（定理
  2.11）得 cf=ω 强极限 + 2^κ=κ⁺⁺ 的 SCH 最小反例。第
  107 章恰当力迫（可数支撑迭代）是 Easton 支撑的姊妹
  调度（事实 2.4.1(2) 已把两种支撑的极限公式并列）。
- **向下（消费方）**：第 106 章把定理 2.11 做成完整模型并
  讨论 SCH 反例的谱系；第 109–110 章泛型超幂与 NS 饱和
  会回收「λ-定向完全性 + 封闭账」这套技术（引理 2.6 的
  三款在饱和理想的原型论证中原样重演）。
### 105.9a 收束

全章一句话总括：**Easton 支撑迭代是「按基数分级预算」的
施工制度，λ-定向完全性是预算下的安全承诺，大拿是承诺的
兑现凭证——三件套让 κ⁺⁺-超紧兑换出「可测 κ 且 2^κ=
κ⁺⁺」**。与 Prikry（判定性=拉姆齐性）合龙即得 SCH 的
最小反例。读者若只带走一件东西：带走「大拿」——定向族
的下界这个概念，它是此后三章（恰当迭代、泛型超幂、NS
饱和）反复出场的通用零件。

本章机器件共 ~714 行源码（全教程力迫章第二大），覆盖条件
层五件套（偏序律/合并/支撑/贪心/下界）的全部语法验证；
不可机化的四幕工程（迭代调度、提升、大拿构造、封闭断言）
以讲解承重。「砖块检验 + 房子讲解」的分工在本章边界节
（105.7a）逐条立案——这也是 Task 20 Step 3 的诚实声明。

---

### 105.8a 检查问题提示

（第 1 题查「κ 个有界支撑的公共上界落在正向极限点」需要
荟萃而非无界；第 2 题查 cf(β)=λ 的极限步在「≤λ」与
「<λ」两个版本下的归属；第 3 题查 j(p) 的长度与 Q 的
条件域——p 的支撑在 κ+1 以下，j(p) 在 j(κ)+1 以下，
「尾巴」的切点在 κ+1；第 4 题构造支撑 {0,1,2,3,4} 在
奇异 μ′=5 处 |S∩5|=5 ≮ 5——真值层不查奇异 μ 因为反向
极限在奇异处的封闭性补偿了支撑的宽松；第 5 题查
has_key 的截断与贪心的首值获胜的同构点（同一键的后续
目标被忽略）与分流点（Prolog 可回溯查询链的中间形态、
Julia 只得终点）。）

上一章：[104 Prikry 力迫](104-prikry.md) · 下一章：[106 SCH 最小反例](106-schcounter.md)
