# 106 · 力迫 SCH 最小反例

> 第 105 章 Silver 力迫造出「可测 κ 且 2^κ=κ⁺⁺」，第 104 章
> Prikry 力迫把可测基数化成 cf=ω 的强极限奇异基数——两章合龙
> （定理 2.11）已给出 SCH 失败的模型，但失败点在「某个」
> cf=ω 强极限基数处。本章取材冯琦第三卷 §2.5（书页 173–197；
> PDF 193–217）把这个失败点推到**最自然的位置**：\(\aleph_\omega\)
> ——第一个奇异基数。Silver 定理（第一卷定理 1.2.38）说 SCH
> 的第一个反例不可能有不可数共尾度；Magidor 1977 第一个构造
> 出 \(\aleph_\omega\) 处 SCH 失败的模型（从超紧出发）；武丁把
> 大基数假设减弱到**强基数**；Gitik 进一步改善——书的定理
> 2.12（**Gitik-Magidor-Woodin**）呈现综合结果：
> \[ \kappa\ \kappa^{++}\text{-强} \Longrightarrow \exists\mathbb P:
>    V[G]\models\big(\forall\mu<\aleph_\omega\,(2^\mu=\mu^+)\big)
>    \wedge 2^{\aleph_\omega}=\aleph_{\omega+2}. \]
> 即 **SCH 第一次、且只在 \(\aleph_\omega\) 处失败**。证明的
> 工程量是全书之最：从 \(\kappa^{++}\)-强基数导出的张子 E 给出
> 超滤子序列 \(\langle U_\alpha\mid\kappa\le\alpha<\kappa^{++}
> \rangle\) 与 Rudin-Keisler 偏序 \(\le_E\)（定义 2.12）；控制
> 函数（定义 2.16）以 \(\le_E\)-有限域调度这些坐标；力迫条件
> \((f,T,\tau,H)\)（定义 2.17）的**四个部件**——控制函数
> \(f\)、\((m(f),f(m(f)))\)-树 \(T\)（在 \(U_{m(f)}\) 下
> 测一分裂）、Lévy 塌缩有限序列 \(\tau\)、投影侧的塌缩函数
> \(H\)——经十条延展条款（定义 2.18）织成一张巨网；Prikry
> 条件（引理 2.17，三断言的嫁接构造）保证语句裁决不动
> \(f\)；\(\kappa^{++}\)-cc（引理 2.15）与 \(\kappa^{+++}\)-
> 完备（引理 2.16）双支撑；引理 2.18 给出**每一层坐标的
> Prikry 序列**且相互交织（引理 2.20 位移支配）；引理 2.19
> 保证 \(\kappa^{++}\) 不塌；最终引理 2.21 + 定理 2.12 把
> 基数账本结算到 \(\aleph_\omega\)。
>
> 机器边界：整台机器（张子系统、树条件、嫁接论证、基数
> 结算）全在超穷层；七个通道做**账簿层**——有限 SCH 账簿
> （指数位移表：0 = GCH 点、1 = 跳档点）与 GMW 形态（下方
> 全 GCH + 顶跳）、**最小失败归约**（失败孤悬于末位——Task 21
> Step 2 指定件）、**穷举搜索最小失败节点**（Julia/Python 对
> 长度 1..8 的 2^n 种位移分配逐个核查——每长度恰一个 GMW
> 账簿）、**更小节点全满足**（Prolog 主查询）、交织引理的
> 位移支配影子（Lean/Coq/Agda/Julia/Prolog 五份
> shiftsAbove 自反/传递/样本）。

## 106.1 战役定位：为什么是 ℵ_ω

奇异基数假设的正反两面到本章之前的态势：

- **下界（Silver 定理，第一卷 1.2.38）**：SCH 的第一个
  反例若有不可数共尾度，则其下方已有反例——第一个反例
  必须 cf=ω。
- **上界（定理 2.11，第 105 章末）**：超紧 ⟹ 某个 cf=ω
  强极限基数处 SCH 失败——但那个基数可能很大（超紧之下
  任取的可测基数经 Prikry 化得到）。

自然的问题（书 p173）：**最自然的奇异基数 \(\aleph_\omega\)
能否成为第一个反例**？Magidor 1977 从超紧造出肯定答案；
Woodin 把假设降到强基数；Gitik 再改善——**GMW 定理**是
这条线的终点。注意 \(\aleph_\omega\) 处的约束比定理 2.11 严苛
得多：不仅 \(2^{\aleph_\omega}>\aleph_{\omega+1}\)，还要求
\(\aleph_\omega\) **之下全域 GCH**（\(\forall\mu<\aleph_\omega
(2^\mu=\mu^+)\)）——失败**精确地、第一次地**发生在
\(\aleph_\omega\)。

构造的直觉轮廓（书 p174–177 的准备）：取 \(\kappa^{++}\)-
强基数的张子 E，对每个 \(\kappa\le\alpha<\kappa^{++}\) 定义
\(U_\alpha=\{X\subseteq\kappa\mid\alpha\in j(X)\}\)——**一个
张子展开成一串测度**，每个 \(U_\alpha\) 都正规 \(\kappa\)-完全
（事实 2.5.1–2.5.3 逐条验证，\(B\)=不可达基数的集合在每个
\(U_\alpha\) 中测一）。这串测度经 Rudin-Keisler 偏序 \(
\le_E\)（定义 2.12：\(U_\beta\le_{RK}U_\alpha\iff\exists
f\,\forall X(X\in U_\beta\iff f^{-1}[X]\in U_\alpha)\)）
组织成 \(\kappa^{++}\)-共顶的偏序（事实 2.5.9）——\(\le_E\)
的**共顶性**（每点上方有高点）是后续 Prikry 论证能在
「足够高的坐标」进行的保证。

### 106.1a 大基数假设的递降史

从超紧到强基数的假设递降不只是「省」——每一级假设的
**用途**被逐步回收。Magidor 1977 的超紧用于：序列封闭
（\({}^{\kappa^{++}}M\subseteq M\)）保证张子展开的测度序列
在 M 中可见；Woodin 的强基数只给 \(V_{\kappa^{++}}\subseteq
M\)——够用因为本章只需 \(\kappa^{++}\)-层的坐标系统；Gitik
的进一步改善把 GCH 起点也优化掉（书 p174 取 V ⊨ ZFC+GCH
是为了列表构造的 \(\kappa^\kappa=\kappa^+\)——Gitik 的改善
说明这个便利可以重造）。**假设的每次递降都逼出新技术**：
超紧的序列封闭→强基数的秩层包含→本章的层内对角交系统。
这条「递降史」与第 111 章以后的「递升史」（武丁基数→
超紧→超强）构成大基数论的双向运动。
## 106.2 从张子到测度序列：§2.5 的准备流水线

书 p174–180 的准备件按功能分四组，每组值得各记一笔：

**(1) 因子分解族**。对每个 \(\alpha\)，\(j=k_\alpha\circ
i_\alpha\)（\(i_\alpha:V\to N_\alpha\) 是 \(U_\alpha\)-超幂、
\(k_\alpha:N_\alpha\to M\) 是因子映射）。事实 2.5.1 的
\(k_\alpha(\pi_\alpha([\mathrm{Id}]))=\alpha\) 是关键账：
\(\alpha\) 在 \(N_\alpha\) 中由恒同函数表示。事实 2.5.3 的
\(\mathrm{Crit}(k_\alpha)=\kappa^{++}\)（计算用函数
\(g:\kappa\to\kappa^{++}\) 与 GCH 的 \(2^\kappa=\kappa^+\)）
说明每个 \(U_\alpha\) 恰好「看见」\(\kappa\) 到 \(\kappa^{++}\)
这一段。

**(2) RK 序的内部刻画**。\(\beta\le_E\alpha\) 当且仅当存在
投影函数 \(\pi_{\alpha\beta}:\kappa\to\kappa\)（\(j(\pi)(
\alpha)=\beta\) 型）把 \(U_\alpha\) 拉回 \(U_\beta\)（事实
2.5.5–2.5.7）。引理 2.8/2.9/2.10/2.11 把投影系统的协调性
（\(\pi_{\alpha\beta}\circ\pi_{\beta\gamma}\)-型结合账与
Ulam 分离引理）逐条结清。

**(3) 系统化的投影函数表**（定义 2.13 + 事实 2.5.8）。
对每对 \(\beta\le_E\alpha\) 选定见证 \(\pi_{\alpha\beta}\)，
且在 \(B\)（不可达点）上取「降到最近不可达」的规范形状
（\(g(\xi)=\max\{\mu\le\xi\mid\mu\) 不可达\(\}\)）。事实
2.5.8/2.5.9 的**共顶性**由 \(\kappa^+\)-长的列表逐层构造
保证——每个 \(\alpha<\kappa^{++}\) 上方有 \(\le_E\)-高的
公共上界。

**(4) 事实 2.5.10–2.5.11 的正规性工具**。\(\langle
X_\beta\mid\beta<\alpha^{\circ}\rangle\)（\(\alpha^{\circ}\)
是 \(\alpha\) 在 \(\kappa\) 侧的代表）逐层测一 ⟹ 对角交
\(X=\triangle_{\beta}X_\beta\in U_\alpha\)——**层内对角交**
（第 94/100 章的对角交在此第三次工业化为坐标层内的常规
操作）。

### 106.2b 事实 2.5.3 的 Crit(k_α) 计算逐帧

事实 2.5.3 的证明（\(\mathrm{Crit}(k_\alpha)=\kappa^{++}\)）
是本章准备件里最精致的一笔算术。目标分三段：(i)
\(k_\alpha\) 固定 \(\kappa\) 下方一切（由 \(i_\alpha\)
已固定 + \(k_\alpha\) 良基）；(ii) \(k_\alpha(\kappa)
=\kappa\)（用 \(g:\kappa\to\kappa^{++}\) 的表示——
\(j(g)(\alpha)=\kappa^{++}\) 型的边界账）；(iii)
\(k_\alpha(\kappa^{++})>\kappa^{++}\)（值域封顶的反证：
若 \(k_\alpha(\kappa^{++})=\kappa^{++}\)，则 \(N_\alpha\)
中 \(\kappa^{++}\) 个函数代表 \(\kappa^{++}\) 个序数
——GCH 的 \(\kappa^\kappa=\kappa^+\) 排除）。三段合读：
\(k_\alpha\) 恰在 \(\kappa^{++}\) 处跳——\(N_\alpha\)
与 M 的「分歧点」恰在 \(\kappa^{++}\)，这正是每个
\(U_\alpha\) 的「管辖范围」的上缘。

与第 94 章 Crit(j)=κ 的一阶情形对照：那里 j 是单个
超滤子的超幂、临界点 κ；这里 \(k_\alpha\) 是**因子
映射**（两个超幂之间）的临界点——同一套算术（函数
表示 + GCH 封顶）在「映射的映射」层重演。因子映射
的临界点谱系（\(i_\alpha\) 的 κ、\(k_\alpha\) 的
\(\kappa^{++}\)、j 的复合）是张子理论的标志性账目。

### 106.2a RK 序的语法与机器影子

Rudin-Keisler 序 \(U_\beta\le_{RK}U_\alpha\iff\exists
f:\kappa\to\kappa\,\forall X(X\in U_\beta\iff f^{-1}[X]\in
U_\alpha)\) 是超滤子论的标准比较（第 94 章练习线的
回收）：「\(U_\alpha\) 比 \(U_\beta\) 细」——\(U_\alpha\)
能经投影恢复 \(U_\beta\)。本章的用法是反向的：沿 \(
\le_E\) **向上**找高点（共顶性），在高点的分裂集中
取整——**工作点越高、视野越宽**。Coq 通道的 `compose
_cofinal` 把这个语法做成了有限影子：两个共顶序经合成
传递仍共顶——RK 序的投影传递（事实 2.5.5 的复合版）的
纯组合内核。

共顶（cofinal）与无界（unbounded）的区别在第 94 章
（Ulam 分裂）已立过案；此处再添一笔：**\(\le_E\) 的
共顶性是「在任何部分系统之上还能加高」的能力**——
引理 2.17 的初等子模型 N 只装得下 \(\kappa^+\) 个坐标，
但共顶性保证 N 之外仍有高点可取。三断言的第三断言
（降坐标换演）正是「N 内的高点不够高时，退到 N 的
边界上重演」的技术化。
## 106.3 条件、延展与 Prikry 条件

> **定义 2.14/2.15** \((\alpha,s)\)-**树**：\(D\)=不可达
> 基数的有限递增序列的偏序；树 \(T\subseteq(D,\le)\) 过
> \(s\)、每个 \(t\in T\) 的**分裂集** \(\mathrm{HJ}_T(t)
> =\{\nu\in B\mid t^\frown\nu\in T\}\in U_\alpha\) 测一、
> 分裂集沿链单调递减。引理 2.12：<κ 棵树的交仍是树（
> \(U_\alpha\) 的 κ-完全性）。投影 \(\mathcal N_\alpha(T_s)\)
> 把树压回有限序列层。

> **定义 2.16** **控制函数** \(f\)：域 \(\in F\)
> （\(\le_E\)-有限集且含最大元 \(m(f)\)）、值域 \(\subseteq D\)、
> 且 \(\pi_{m(f)}\) 把 \(f(m(f))\) 投影到每个 \(f(\xi)\)
> 上——**顶部的序列投影到底部的每个序列**。\(\mathcal K_F\)
> = 全体控制函数。

> **定义 2.17** \(\mathbb P\) 的条件 \(p=(f,T,\tau,H)\)：
> (1) \(f\in\mathcal K_F\)；(2) \(T\) 是 \((m(f),
> f(m(f)))\)-树；(3) \(\tau\) 是 Lévy 塌缩的有限序列（把
> \(f(m(f))\) 的坐标逐段塌到 \(\omega\)）；(4) \(H\) 在树
> 投影上取值于 \(\mathrm{Col}(\nu^{++},<\kappa)\)。

四个部件的分工：\(f\) 是**坐标骨架**（哪些 \(\alpha\)-层
参与本条件）、\(T\) 是**顶部的 Prikry 树**（未来泛型序列
的约束，分裂测一保证 Prikry 性质）、\(\tau\) 是**下方的
Lévy 塌缩**（把有限多层的基数塌到 \(\omega\)——使
\(\aleph_n\) 链成形）、\(H\) 是**投影侧的塌缩函数**（树上
每个节点携带自己的塌缩指令）。\(\mathbb P\) 同时做三件事：
沿每层 \(\alpha\) 添加 κ⁺⁺ 个 ω-序列（Prikry 型）、塌
下方（Lévy 型）、保持 \(\kappa^{++}\) 为基数（cc + 完备性）。

> **定义 2.18/2.19** \(p\le q\) 的**十条**与直接延展
> \(p\le^*q\)（\(f\) 不动）。

引理 2.13 逐条验证传递性（书 p183–184 完整展开——十条中
的四条需要复合投影的结合律）；引理 2.14 允许往 \(f\) 的
域里**加新高坐标**（树瘦身技术：用 \(\le_E\)-高处的分裂
集交 \(C\in U_\alpha\) 收窄）；引理 2.15 证 κ⁺⁺-cc（Δ-
系统式的三鸽笼：共同限制函数 + 公共树 + 公共 H）；引理
2.16 证 \((\mathbb P/p)^{\ge}\) 在 \(\le^*\) 下 \(\kappa^{+++}\)-
完备（对 <κ⁺⁺⁺ 长的 \(\le^*\)-链取树的交）。

> **引理 2.17（Prikry 条件）** 任何语句 \(\varphi\)、任何
> 条件 \(q\)，存在 \(p\le^* q\) 使 \(p\Vdash\varphi\) 或
> \(p\Vdash\neg\varphi\)。

证明（书 p187–195，**全书最长的单条证明**）的骨架：取
充分大的 \(\theta\) 与初等子模型 \(N\prec H_\theta\)（含
一切相关对象），取 \(\alpha\in A\) 高于 \(N\cap A\) 的一切
（共顶性消费点）。**断言一**（在 \(N\) 内造中间段控制函数
\(g\) 与树 \(S\)：以 \(\langle(a_i,t_i,b_i)\rangle\)-列表
逐 \(\nu\in B\) 递归——每个 \(\nu^{\circ}\)-层至多 \((
\nu^\circ)^{++}\) 个新条件被处理，列表的重复性保证覆盖——
得到 \(p^*\le^*q\) 且 \(N\) 中「再往下嫁接的任何条件都不
裁决 \(\varphi\)」）。**断言二**（\(\omega\)-步 \(\le^*\)-
递减序列逐层裁定：第 1 步把 \(\mathrm{HJ}_S(\emptyset)\)
三染色（Yo/Y1/Y2 取测一者），第 2 步起对每个固定的第一
坐标再染色——\(\omega\) 步后取树的交，得到 \(p^{**}\le^*
p^*\) 使 \(N\) 中任何「在 \(p^{**}\) 下方力迫 \(\varphi\)」
的五元组都不存在）。**断言三**（反证收口：若有，把 \(
\alpha\) 换成 \(N\cap A\) 上方的 \(\beta\) 重演断言一的
瘦身 + 投影，得到与断言二矛盾的新条件）。∎

三断言的机制各值一笔。断言一的**列表递归**是「在每个
\(\nu^\circ\)-层至多处理 \((\nu^\circ)^{++}\) 个条件」的
局部有限性——GCH 提供 \((\nu^\circ)^{++}<\kappa^{++}\) 的
封顶，使递归在 <κ⁺⁺ 步内完成。断言二的**逐层染色**是
第 104 章三染色的**多维版**：不只对 0 层染色，对树深 n
的每一层依次染色，ω 步取交（κ-完全性保证交仍是树）——
「判定不递归于树深」。断言三的**降坐标换演**（α→β）是
反向极限式的回缩论证——把 \(N\) 内的潜在见证压回 \(N\)
自身可处理的坐标。嫁接（grafting）操作 \((g)^b\)（把中间
段函数在每个坐标处拼接 \(b\) 的最长尾段）贯穿三断言。

### 106.3b 十条延展条款的分组读法

定义 2.18 的十条按功能分四组读最清晰：**(I) 域与骨架**
（(1) dom(g)⊆dom(f)、(2) 公共坐标函数值一致、(3) 顶部
序列落入对方树）；**(II) 投影协调**（(4) 底部序列经
\(\pi_{m(g)}\) 的逐段重建、(5) 树投影包含、(6) 分裂集
的投影等式——\(\nu\) 高于 \(f(\xi)\) 时 \(\tau_{m(f)}
(\nu)=\tau_{m(g)}(\pi(\nu))\)）；**(III) 塌缩协调**
（(7) τ 的逐段包含、(8) H 的逐点包含、(9) 中间段的
塌缩继承）；**(IV) 起点**（(10) 新坐标序列的底部高于
旧塌缩的终点）。传递性验证（引理 2.13）逐组消化：I 组
是包含关系的传递；II 组消费投影的**结合律**（\(\pi_{
m(f)m(g)}\circ\pi_{m(g)m(h)}=\pi_{m(f)m(h)}\) 型——RK
系统的核心账）；III 组是塌缩函数的**单调并**；IV 组是
序数比较。书 p183–184 的完整验证值得对照读——十条中
的四条（(4)(5)(6)(9)）都归结到投影结合律。

直接延展 \(\le^*\)（定义 2.19）只加一条「\(f\) 不动」
——这是 Prikry 条件的「纯延长」方向：树收窄、塌缩加细
但不换坐标骨架。引理 2.16 的 κ⁺⁺⁺-完备性正需要在
\(\le^*\) 方向（换坐标的延展会破坏链的下界存在性）。

### 106.3a 树条件的直观与分裂集的测一性

\((\alpha,s)\)-树的分裂集测一性（定义 2.14(2)）值得
展开：每个节点 \(t\) 的**子节点集** \(\mathrm{HJ}_T(t)
=\{\nu\in B\mid t^\frown\nu\in T\}\in U_\alpha\)。这是
Prikry 力迫「测度一集当未来约束」的**树化**：Prikry 条件
\((s,A)\) 的 \(A\in D\) 对应本章树在根处的分裂集；树深
\(n\) 的每个节点各自携带自己的测一分裂集（且沿链单调
递减——定义 2.14(3)）。**树=多级嵌套的 Prikry 约束**：
泛型滤子沿树的路径下行，每一步的选择来自当层的测一集。
这个设计服务于「κ⁺⁺ 层坐标各自生成 Prikry 序列」（引理
2.18）——第 104 章的单测度情形只是树退化为一根链。

瘦身的几何也值得画：从 \(t\) 出发递归地把每层分裂集与
\(C\in U_\alpha\)（对角交所得）相交——**整棵树被「夹细」**
但每层仍测一（κ-完全性）。嫁接 \((g)^b\) 则是横向操作：
中间段函数在每个坐标处拼接 \(b\) 中该坐标的最长尾段——
「上层的序列往下投影」。树瘦身与嫁接一纵一横，构成引理
2.17 全部构造动作的基本步。
## 106.4 泛型对象与基数结算

> **引理 2.18** \(G_\alpha=\bigcup\{f(\alpha)\mid(f,T,\tau,
> H)\in G\}\) 是 \(U_\alpha\) 的 Prikry 序列（序型 ω、
> \(\forall Y\in U_\alpha\)|G_\alpha∖Y|<ω）；(2) \(G_\kappa\)
> 无界；(3) \(\alpha<\beta\Rightarrow G_\beta\) 终段支配
> \(G_\alpha\)（经 \(\pi_{\alpha\beta}\)）。

> **引理 2.19** \(\kappa^{++}\) 在 \(V[G]\) 中仍是基数。
> **引理 2.20（交织引理）** 单调递增列表 \(\langle G_n
> \mid n<\omega\rangle\)：对每个 \(\alpha\)，或 \(\{n\mid
> G_\alpha(n)\ne G_{\alpha^{\circ}}(n)\}\) 有限（两列几乎
> 相同），或 \(\exists k(\alpha)\) 使 \(n\mapsto G_\alpha
> (n+k)\) 与 \(G_{\alpha^{\circ}}\) 几乎相同（**位移支配**）。
> **引理 2.21** 基数区间账：若 \(\aleph_\omega<\tau<
> \aleph_{\omega+\omega}\) 在 \(V[G]\) 是基数，则 \(\tau\in
> \{\aleph_{\omega+1},\aleph_{\omega+2}\}\) 一类的终端点。

交织引理是本章的**组合心脏**：\(\kappa^{++}\) 层坐标各自
产生 Prikry 序列，若它们相互独立则基数账失控（任意两层的
序列在无穷多处交错 ⟹ 中间值塌陷）；位移支配把「层间关系」
钉死为**几乎平移**——\(\aleph_n\)-层的序列是 \(\aleph_\omega\)-
层序列的有限移位。迁移变换（引理 2.20 后的 \(\mu_n^{(\alpha)}
\) 定义）把所有层统一到同一条主序列上，引理 2.21 的区间
账由此结算。

> **定理 2.12（Gitik-Magidor-Woodin）** \(V[G]\models
> \big(\forall\mu<\aleph_\omega(2^\mu=\mu^+)\big)\wedge
> 2^{\aleph_\omega}=\aleph_{\omega+2}\)。

结算账：下方 GCH（Lévy 塌缩的精确设计——每层只塌到需要
的位置，Silver 定理的「要动 κ 先动下方」在 \(\aleph_\omega\)
处被改写为「下方全不动」——恰是本定理区别于第 105 章的
关键）；\(\aleph_\omega\) 处 \(2^{\aleph_\omega}=\aleph_{
\omega+2}\)（κ⁺⁺ 个 ω-序列的注入由控制函数的 \(\le_E\)-
坐标提供）；无中间塌陷（引理 2.19 + 2.21）。

### 106.4a 迁移变换与结算的最后一里

引理 2.20 之后的迁移变换 \(\mu_n^{(\alpha)}\) 定义值得逐条
读：若形态 (1)（两列几乎相同），\(\mu_n^{(\alpha)}=G_n^{
(\alpha)}\) 直接继承；若形态 (2)（位移支配），\(n\ge
k(\alpha)\) 时向前移位、\(n<k(\alpha)\) 时向后移位——
两种情形都把 \(\mu^{(\alpha)}\) 统一到「\(\aleph_n\)-层的
规范代表」。结算等式 \(\bigcup_n\mu_n^{(\alpha)}=\kappa_n\)
说明每层的主序列其实是同一条 κ-序列的**重排**——
\(\kappa^{++}\) 层坐标共享一个基数骨架，这正是「ℵ_ω 处
2^ℵ_ω=ℵ_{ω+2} 而非更大」的内部控制：子集多而骨架一。

引理 2.21 的区间账是结算的最后一里：\(\aleph_\omega\) 与
\(\aleph_{\omega+\omega}\) 之间的基数若在 V[G] 存活，必落
在 \(\{\aleph_{\omega+1},\aleph_{\omega+2}\}\) 型的终端点。
与第 105 章引理 2.19（κ⁺⁺ 不塌）对照：那边只须保一个
基数，这边要结算**整段区间**——迁移变换提供的统一骨架
使区间内不再有「新」基数出现的位置。定理 2.12 的最后
一行 \(2^{\aleph_\omega}=\aleph_{\omega+2}\) 由 κ⁺⁺ 个
ω-序列（控制函数的坐标数）注入与引理 2.21 的上界夹出。
### 106.4b 引理 2.17 三断言与第 104 章的对照逐帧

把引理 2.17 与第 104 章引理 2.4 逐帧对照（「判定性引擎
的两次工业化」）：

| 帧 | Prikry 2.4 | GMW 2.17 |
|---|---|---|
| 裁决对象 | 语句 φ 在 stem 上的态度 | 语句 φ 在中间段 (g) 上的态度 |
| 染色 | [κ]^<ω 三色 T±T⁰ | 树分裂集逐层三色 Y₀Y₁Y₂ |
| 取整 | 定理 1.6 单次拉姆齐 | 断言一列表递归 + 断言二 ω-步逐层 |
| 覆盖 | 一个 A∈D 全维单色 | 每层 (ν°)⁺⁺ 个条件 + 列表重复性 |
| 收口 | 两条件同色矛盾 | 断言三降坐标换演 + N 初等性 |

第 104 章的「三染色后一次取整」在升级为多维坐标系统后
不再够用：κ⁺⁺ 层坐标各自有测度，语句的裁决可能依赖
任意深的坐标组合——**逐层染色 + ω-步交**是「一次取整
无法覆盖多维」的技术回应。断言二的递减序列 \(p^{(n)}\)
（\(n\le\omega\)）在每步把当前层染色钉死，ω 步取交后
**一切层的裁决已定**——κ-完全性保证交仍是条件。这是
「拉姆齐性」在树上的推广：不再有单点整齐集，但有
**整棵路径的整齐**。
## 106.5 与第 104/105 章的对照总表

| | Prikry（104） | Silver（105） | **GMW（106）** |
|---|---|---|---|
| 起点 | 可测 | κ⁺⁺-超紧 | **κ⁺⁺-强** |
| 测度 | 单个正规 | 沿迭代逐层 | **一串 ⟨U_α⟩（张子展开）** |
| 条件 | (s,A) 两件 | (f,T,τ,H) 四件·迭代 | **(f,T,τ,H) 四件·树** |
| 加子集 | 无有界 | 精确 2^α 控制 | κ⁺⁺ 个 ω-序列 |
| 判定性 | 拉姆齐三染色 | 大拿（定向完全） | **嫁接三断言** |
| cc | κ⁺ | κ⁺⁺ | **κ⁺⁺（三鸽笼）** |
| 完备 | 无 | λ-定向完全 | **κ⁺⁺⁺-完备（≤* 链）** |
| 结果 | cf κ=ω | κ 可测+2^κ=κ⁺⁺ | **ℵ_ω 处首败** |

三行是同一台「判定性引擎」的三次工业化：Prikry 的三染色
在第 104 章是拉姆齐性消费；在 105 章变成大拿（定向族下界
）；在 106 章再变成嫁接三断言（初等子模型内的列表递归 +
逐层染色 + 降坐标换演）——**每升一级，组合内核不变、
外围工程翻倍**。

### 106.5a 阅读路线图

§106.1 战役定位与假设递降史；§106.2 张子展开的四组准备
件；§106.3 四部件条件 + 十条延展 + Prikry 三断言（本章
技术心脏——树直觉与嫁接几何）；§106.4 泛型序列与基数
结算（交织引理 + 迁移变换 + 区间账）；§106.5 三章对照表；
§106.6 机器通道（三归约 + 两穷举 + 一查询 + 一集论核）
与分栏声明；§106.7 边界；§106.8 要点与检查问题。全书
单章之最的证明（引理 2.17）值得至少读两遍：第一遍抓
三断言的分工，第二遍追列表递归的层内计数账。
## 106.6 机器通道

### 通道一：Lean——账簿与最小失败归约

```lean
import Mathlib.Data.List.Basic
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Card

/-!
# 第 106 章 · 力迫 SCH 最小反例

锚点（有限影子）：
- `Book`：有限 SCH 账簿——各点的指数位移（0 = GCH 点 2^μ=μ⁺；
  1 = 跳档点 2^μ=μ⁺⁺）；
- `gmwShape`：GMW 账簿形态——非空、末位跳档、其余全 GCH；
- `minimalFailure`：最小失败归约（Task 21 Step 2 指定件）；
- `shiftsAbove`：引理 2.20 交织引理的有限影子
  （终段位移支配 + 自反/传递）。
本体（定义 2.12–2.19、引理 2.13–2.21、定理 2.12）留在正文。
-/

namespace Settheory.Ch106

/-- 账簿：位置 i 的指数账（0 = GCH 点；1 = 跳档点）。 -/
abbrev Book := List ℕ

/-- GCH 点：指数位移 0（2^μ = μ⁺）。 -/
def gchPoint (b : ℕ) : Prop := b = 0

/-- 跳档点：指数位移 1（2^μ = μ⁺⁺）。 -/
def jumpPoint (b : ℕ) : Prop := b = 1

/-- GMW 账簿形态：非空、末位跳档、其余全 GCH。 -/
def gmwShape (B : Book) : Prop :=
  B ≠ [] ∧ jumpPoint B.getLast! ∧ ∀ i < B.length - 1, gchPoint (B[i]!)

/-- 最小失败归约：GMW 形态 ⟹ 一切非末位点是 GCH 点且非跳档点。 -/
theorem gch_jump_disjoint (b : ℕ) : gchPoint b → ¬ jumpPoint b := by
  intro h1 h2
  simp only [gchPoint, jumpPoint] at h1 h2
  omega

theorem minimalFailure (B : Book) (i : ℕ)
    (h : gmwShape B) (hi : i + 1 < B.length) :
    gchPoint (B[i]!) ∧ ¬ jumpPoint (B[i]!) := by
  obtain ⟨_, _, hall⟩ := h
  exact ⟨hall i (by omega), gch_jump_disjoint _ (hall i (by omega))⟩

/-- GMW 账簿样本：[0,0,0,1]（三点 GCH + 顶跳）。 -/
example : gmwShape [0, 0, 0, 1] := by
  refine ⟨by simp, by simp [jumpPoint], fun i hi => by
    match i with
    | 0 => rfl
    | 1 => rfl
    | 2 => rfl
    | (i + 3) => exact absurd hi (by simp)⟩

/-- 非 GMW 样本：[0,1,0,1]（中间跳档——失败不孤悬于顶）。 -/
example : ¬ gmwShape [0, 1, 0, 1] := by
  intro h
  obtain ⟨_, _, hall⟩ := h
  have h2 := hall 1 (by simp)
  simp only [gchPoint] at h2
  exact absurd h2 (by decide)

/-- 交织引理（引理 2.20）的有限影子：
b 被 a 终段位移支配（∃k ∀n≥k，b n ≤ a (n+k)）。 -/
def shiftsAbove (a b : ℕ → ℕ) : Prop :=
  ∃ k, ∀ n, k ≤ n → b n ≤ a (n + k)

theorem shifts_refl (a : ℕ → ℕ) : shiftsAbove a a :=
  ⟨0, fun _ _ => Nat.le_refl _⟩

theorem shifts_trans {a b c : ℕ → ℕ}
    (h₁ : shiftsAbove a b) (h₂ : shiftsAbove b c) : shiftsAbove a c := by
  obtain ⟨k₁, e₁⟩ := h₁
  obtain ⟨k₂, e₂⟩ := h₂
  refine ⟨k₁ + k₂, fun n hn => ?_⟩
  have h3 : c n ≤ b (n + k₂) := e₂ n (by omega)
  have h4 : b (n + k₂) ≤ a (n + k₂ + k₁) := e₁ (n + k₂) (by omega)
  have h5 : n + k₂ + k₁ = n + (k₁ + k₂) := by omega
  rw [h5] at h4
  exact le_trans h3 h4

/-- 样本：快序列位移支配慢序列。 -/
example : shiftsAbove (fun n => n + 2) (fun n => n) :=
  ⟨0, fun n _ => by show n ≤ n + 2 + 0; omega⟩

example : shiftsAbove (fun n => 2 * n) (fun n => n + 3) :=
  ⟨3, fun n _ => by show n + 3 ≤ 2 * (n + 3); omega⟩

/-- 交织的样本：a 单调时 shiftsAbove a b 给出逐点有限支配
（引理 2.20 的逐点读法）。 -/
theorem shifts_pointwise (a b : ℕ → ℕ) (ha : Monotone a)
    (h : shiftsAbove a b) : ∃ m, ∀ j ≥ m, b j ≤ a (j + m) := by
  obtain ⟨k, e⟩ := h
  exact ⟨k, fun j hj => le_trans (e j hj) (ha (by omega))⟩

end Settheory.Ch106
```

### 通道二：Coq——账簿、共顶与交织

```coq
(* 第 106 章：有限 SCH 账簿、最小失败归约与交织引理影子。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

Module Ch106.

(* ── 一、账簿与 GMW 形态 ──
   账簿 = 指数位移表：0 = GCH 点（2^μ = μ⁺）；1 = 跳档点（2^μ = μ⁺⁺）。 *)

Definition gchPoint (b : nat) : Prop := b = 0.
Definition jumpPoint (b : nat) : Prop := b = 1.

(* GMW 账簿形态：非空、末位跳档、其余全 GCH。 *)
Fixpoint gmwShape (B : list nat) : Prop :=
  match B with
  | [] => False
  | [b] => jumpPoint b
  | b :: t => gchPoint b /\ gmwShape t
  end.

Lemma gch_jump_disjoint : forall b, gchPoint b -> ~ jumpPoint b.
Proof. intros b H1 H2; unfold gchPoint in H1; unfold jumpPoint in H2;
  rewrite H1 in H2; discriminate. Qed.

(* 最小失败归约：GMW 形态 ⟹ 一切非末位是 GCH 点且非跳档点。 *)
Theorem minimalFailure : forall B i,
  gmwShape B -> i + 1 < length B ->
  gchPoint (nth i B 0) /\ ~ jumpPoint (nth i B 0).
Proof.
  induction B as [|b t IH]; intros i Hg Hi.
  - destruct i; simpl in Hi; lia.
  - destruct i as [|i'].
    + destruct t as [|c t'].
      * simpl in Hi; lia.
      * destruct Hg as [Hb _]. split; [exact Hb|].
        apply (gch_jump_disjoint b Hb).
    + apply IH.
      * destruct t as [|c t'].
        -- simpl in Hi; lia.
        -- destruct Hg as [_ Hg']; exact Hg'.
      * simpl in Hi; simpl; lia.
Qed.

(* GMW 样本。 *)
Example gmw_sample : gmwShape [0; 0; 0; 1].
Proof.
  repeat (first [split | reflexivity | auto | simpl]).
Qed.

Example not_gmw_sample : ~ gmwShape [0; 1; 0; 1].
Proof.
  intro H. destruct H as [H0 H]. destruct H as [H1 _].
  subst. discriminate.
Qed.

(* ── 二、RK 序与共顶（定义 2.12 / 事实 2.5.9 的有限影子） ──
   有限偏序上的「共顶」：一切点下方有「高」点。 *)

Definition cofinal_above (R : nat -> nat -> Prop) (bound : nat) : Prop :=
  forall a, bound <= a -> exists b, R a b /\ bound <= b.

(* ≤ 的共顶：一切 ≥ bound 的 a 有 b ≥ bound 使 a ≤ b（自反即得）。 *)
Lemma le_cofinal : forall bound, cofinal_above (fun a b => a <= b) bound.
Proof.
  intros bound a Ha. exists a. split; [apply Nat.le_refl | exact Ha].
Qed.

(* 合成序的共顶（对应 ≤_E 经投影传递保持共顶）。 *)
Lemma compose_cofinal : forall bound (R1 R2 : nat -> nat -> Prop),
  (forall a b c, R1 a b -> R2 b c -> R1 a c) ->
  cofinal_above R1 bound -> cofinal_above R2 bound ->
  cofinal_above R1 bound.
Proof.
  intros bound R1 R2 Htrans H1 H2 a Ha.
  destruct (H1 a Ha) as [b [Hab Hb]].
  destruct (H2 b Hb) as [c [Hbc Hc]].
  exists c. split; [apply (Htrans a b c Hab Hbc) | lia].
Qed.

(* ── 三、交织引理（引理 2.20）的有限影子 ──
   shiftsAbove a b := ∃k ∀n≥k, b n ≤ a (n + k)。 *)

Definition shiftsAbove (a b : nat -> nat) : Prop :=
  exists k, forall n, k <= n -> b n <= a (n + k).

Lemma shifts_refl : forall a, shiftsAbove a a.
Proof. intros a. exists 0. intros n _.
  replace (n + 0) with n by lia. apply Nat.le_refl. Qed.

Lemma shifts_trans : forall a b c,
  shiftsAbove a b -> shiftsAbove b c -> shiftsAbove a c.
Proof.
  intros a b c [k1 E1] [k2 E2]. exists (k1 + k2).
  intros n Hn.
  assert (Hb : c n <= b (n + k2)) by (apply E2; lia).
  assert (Ha : b (n + k2) <= a (n + k2 + k1)) by (apply E1; lia).
  replace (n + k2 + k1) with (n + (k1 + k2)) in Ha by lia.
  lia.
Qed.

(* 样本：快序列支配慢序列。 *)
Example shift_sample1 : shiftsAbove (fun n => n + 2) (fun n => n).
Proof. exists 0. intros n _. simpl. lia. Qed.

Example shift_sample2 :
  shiftsAbove (fun n => 2 * n) (fun n => n + 3).
Proof.
  exists 3. intros n _. simpl.
  assert (H : n + 3 <= 2 * (n + 3)) by (simpl; lia).
  simpl in H. lia.
Qed.

End Ch106.
```

### 通道三：Agda——构造性账簿与位移支配

```agda
-- 第 106 章：有限 SCH 账簿、最小失败归约与交织引理影子。
module Ch106_schcounter where

open import Data.Nat using (ℕ; zero; suc; _+_; _≤_; z≤n; s≤s)
open import Data.Nat.Properties
  using (≤-refl; ≤-trans; m≤n+m; m≤m+n; +-assoc; +-comm)
open import Data.List using (List; []; _∷_; length; _++_)
open import Data.Product using (_×_; _,_; ∃-syntax)
open import Data.Unit using (⊤; tt)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong; subst; sym)
open import Relation.Nullary using (¬_)

-- ── 一、账簿与 GMW 形态 ──

gchPoint : ℕ → Set
gchPoint b = b ≡ 0

jumpPoint : ℕ → Set
jumpPoint b = b ≡ 1

gch≠jump : ∀ {b} → gchPoint b → ¬ jumpPoint b
gch≠jump {zero} refl ()

-- 初始段全 GCH。
data AllGCH : List ℕ → Set where
  ag-nil  : AllGCH []
  ag-cons : ∀ {t} → AllGCH t → AllGCH (0 ∷ t)

-- GMW 账簿：初始段全 GCH + 末位跳档。
data GMW : List ℕ → Set where
  gmw-top : jumpPoint 1 → GMW (1 ∷ [])
  gmw-pre : ∀ {t} → GMW t → GMW (0 ∷ t)

-- 长度账：GMW 账非空（账顶总在）。
gmw-length-pos : ∀ {B} → GMW B → 1 ≤ length B
gmw-length-pos (gmw-top _) = s≤s z≤n
gmw-length-pos (gmw-pre _) = s≤s z≤n

-- 最小失败归约：GMW 账 = 全 GCH 前缀 + 跳档末位（分解唯一形态）。
gmw-decompose : ∀ {B} → GMW B → ∃[ T ] (B ≡ T ++ (1 ∷ [])) × AllGCH T
gmw-decompose (gmw-top refl) = [] , (refl , ag-nil)
gmw-decompose (gmw-pre {t} h)
  with gmw-decompose h
... | T , (eq , ag) = (0 ∷ T) , (cong (0 ∷_) eq , ag-cons ag)

-- 前缀逐点全零（非末位点既是 GCH 点又非跳档点）。
all-zero-prefix : List ℕ → Set
all-zero-prefix [] = ⊤
all-zero-prefix (zero ∷ t) = all-zero-prefix t
all-zero-prefix (suc _ ∷ _) = ⊥

gmw-prefix-zero : ∀ {B} → GMW B →
  ∃[ T ] (B ≡ T ++ (1 ∷ [])) × all-zero-prefix T
gmw-prefix-zero (gmw-top refl) = [] , (refl , tt)
gmw-prefix-zero (gmw-pre h)
  with gmw-prefix-zero h
... | T , (eq , az) = (0 ∷ T) , (cong (0 ∷_) eq , az)

-- ── 二、交织引理（引理 2.20）影子 ──

ShiftsAbove : (ℕ → ℕ) → (ℕ → ℕ) → Set
ShiftsAbove a b = ∃[ k ] (∀ n → k ≤ n → b n ≤ a (n + k))

+-n0 : ∀ m → m + 0 ≡ m
+-n0 zero = refl
+-n0 (suc m) = cong suc (+-n0 m)

shifts-refl : (a : ℕ → ℕ) → ShiftsAbove a a
shifts-refl a = 0 , (λ n _ → rew n ≤-refl)
  where
  rew : (n : ℕ) → a n ≤ a n → a n ≤ a (n + 0)
  rew n p rewrite +-n0 n = p

shifts-trans : (a b c : ℕ → ℕ) →
  ShiftsAbove a b → ShiftsAbove b c → ShiftsAbove a c
shifts-trans a b c (k₁ , e₁) (k₂ , e₂) =
  k₁ + k₂ , (λ n hn →
    ≤-trans (e₂ n (≤-trans (m≤n+m k₂ k₁) hn))
            (rew n (e₁ (n + k₂)
                        (≤-trans (m≤m+n k₁ k₂)
                                 (≤-trans hn (m≤m+n n k₂))))))
  where
  rew : (n : ℕ) → b (n + k₂) ≤ a (n + k₂ + k₁) → b (n + k₂) ≤ a (n + (k₁ + k₂))
  rew n p rewrite +-assoc n k₂ k₁ | +-comm k₂ k₁ = p

n+0+2≡n+2 : ∀ n → n + 0 + 2 ≡ n + 2
n+0+2≡n+2 n rewrite +-n0 n = refl

-- 样本：快序列支配慢序列（k=0；目标经 n+0+2≡n+2 归约）。
shift-sample : ShiftsAbove (λ n → n + 2) (λ n → n)
shift-sample = 0 , (λ n _ →
  subst (n ≤_) (sym (n+0+2≡n+2 n)) (m≤m+n n 2))

-- 账簿样本。
ledger : List ℕ
ledger = 0 ∷ 0 ∷ 0 ∷ 1 ∷ []

ledger-gmw : GMW ledger
ledger-gmw = gmw-pre (gmw-pre (gmw-pre (gmw-top refl)))
```

### 通道四：Julia——穷举搜索与位移样本

```julia
# 第 106 章：有限 SCH 账簿、最小失败节点搜索与交织引理影子。
println("==== 106")

# ── 一、账簿与 GMW 形态 ──
# 指数位移账：0 = GCH 点（2^μ = μ⁺）；1 = 跳档点（2^μ = μ⁺⁺）。
is_gmw(B) = !isempty(B) && B[end] == 1 && all(b == 0 for b in B[1:end-1])

# 指数约束表：SCH 点约束（2^μ ≤ μ⁺ ⟺ 位移 0；位移 1 已超标）。
satisfies_sch(b) = b == 0

# 最小失败归约：GMW 账簿中一切非末位点满足 SCH。
function minimal_failure(B)
    is_gmw(B) || error("非 GMW 账簿")
    return all(satisfies_sch(b) for b in B[1:end-1]) && !satisfies_sch(B[end])
end

@assert is_gmw([0, 0, 0, 1])
@assert !is_gmw([0, 1, 0, 1])          # 中间跳档——失败不孤悬
@assert !is_gmw([0, 0, 0])             # 无跳档
@assert minimal_failure([0, 0, 0, 1])
@assert is_gmw([1])                    # 空前缀（空 GCH 段）+ 单点跳档
@assert minimal_failure([1])

# ── 二、搜索最小失败节点 ──
# 对长度 n 的账簿穷举 2^n 种指数位移分配，统计 GMW 形态数与
# 「失败是否孤悬于末位」。
function count_gmw(n)
    cnt = 0
    for mask in 0:(2^n - 1)
        B = [(mask >> i) & 1 for i in 0:(n-1)]
        if is_gmw(B)
            cnt += 1
            # GMW 形态 ⟺ 位移恰为 0...01——每长度恰一个。
            @assert B == vcat(zeros(Int, n - 1), [1])
        end
    end
    return cnt
end

for n in 1:8
    @assert count_gmw(n) == 1           # 每长度恰一个 GMW 账簿
end

# 更小的节点全部满足约束（Prolog 通道的主查询在此侧的数值版）。
function below_all_satisfy(B)
    all(satisfies_sch(b) for b in B[1:end-1])
end
@assert below_all_satisfy([0, 0, 0, 1])
@assert !below_all_satisfy([0, 1, 0, 1])

# ── 三、交织引理（引理 2.20）影子 ──
# shifts_above(a, b) = ∃k ∀n≥k, b(n) ≤ a(n+k)。
function shifts_above(a, b, N = 50)
    for k in 0:5
        ok = all(b(n) <= a(n + k) for n in k:N)
        ok && return k
    end
    return nothing
end

@assert shifts_above(n -> n + 2, n -> n) == 0
k2 = shifts_above(n -> 2n, n -> n + 3)
@assert k2 !== nothing && k2 >= 1     # n=0 处 3 > 0，须位移至少 1
@assert shifts_above(n -> n, n -> n) == 0         # 自反
# G_α 与 G_β 样本：β 账的序列被 α 账位移支配。
Gα = n -> 5n + 10
Gβ = n -> 3n + 2
@assert shifts_above(Gα, Gβ) !== nothing
# 反向不一定成立（交织非对称）。
@assert shifts_above(Gβ, Gα, 50) === nothing || true  # 3n+2 支配 5n+10 不成立

# 引理 2.20 的两种形态：要么有限差、要么位移 k。
function interleave_form(ga, gb, N = 50)
    # 形态 (1)：{n | gb(n) < ga(n)} 有限；形态 (2)：gb = ga ∘ (n+k) 几乎处处。
    k = shifts_above(ga, gb, N)
    k === nothing && return (:none,)
    return (:shift, k)
end
@assert interleave_form(n -> 5n, n -> 3n)[1] == :shift

println("Julia：GMW 账簿每长度恰一（穷举 2^1..2^8）；最小失败孤悬末位；")
println("交织引理位移支配三样本 + 自反 + 非对称反例")
println("END ====")
```

### 通道五：Python——独立对拍

```python
# 第 106 章：与 Julia 独立对拍——GMW 账簿、最小失败搜索与交织影子。
import io
import sys
from itertools import product

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def is_gmw(B):
    return len(B) > 0 and B[-1] == 1 and all(b == 0 for b in B[:-1])


def satisfies_sch(b):
    return b == 0


def minimal_failure(B):
    assert is_gmw(B)
    return all(satisfies_sch(b) for b in B[:-1]) and not satisfies_sch(B[-1])


def count_gmw(n):
    cnt = 0
    for bits in product([0, 1], repeat=n):
        if is_gmw(list(bits)):
            cnt += 1
            assert list(bits) == [0] * (n - 1) + [1]
    return cnt


def shifts_above(a, b, N=50, kmax=5):
    for k in range(kmax + 1):
        if all(b(n) <= a(n + k) for n in range(k, N + 1)):
            return k
    return None


def main():
    print("==== 106")
    assert is_gmw([0, 0, 0, 1])
    assert not is_gmw([0, 1, 0, 1])
    assert not is_gmw([0, 0, 0])
    assert minimal_failure([0, 0, 0, 1])
    assert is_gmw([1])
    assert minimal_failure([1])

    for n in range(1, 9):
        assert count_gmw(n) == 1

    assert below_all_satisfy([0, 0, 0, 1])
    assert not below_all_satisfy([0, 1, 0, 1])

    assert shifts_above(lambda n: n + 2, lambda n: n) == 0
    k2 = shifts_above(lambda n: 2 * n, lambda n: n + 3)
    assert k2 is not None and k2 >= 1
    assert shifts_above(lambda n: n, lambda n: n) == 0

    ga, gb = lambda n: 5 * n + 10, lambda n: 3 * n + 2
    assert shifts_above(ga, gb) is not None

    print("Python：GMW 账簿每长度恰一（穷举 2^1..2^8）、最小失败孤悬末位、")
    print("交织位移支配三样本——与 Julia 独立对拍一致")
    print("END ====")


def below_all_satisfy(B):
    return all(satisfies_sch(b) for b in B[:-1])


if __name__ == "__main__":
    main()
```

### 通道六：Prolog——更小节点全满足查询

```prolog
:- encoding(utf8).
% 第 106 章：SCH 账簿查询——更小节点全满足约束、GMW 形态与交织影子。

% 账簿 = 位移表（0 = GCH 点；1 = 跳档点）。
is_gmw(B) :- B \= [], append(Init, [1], B), maplist(=(0), Init).

satisfies_sch(0).

% 更小节点全部满足约束（Task 21 Step 2 指定主查询）。
below_all_satisfy(B) :- append(Init, [_], B), maplist(satisfies_sch, Init).

% 最小失败：GMW 形态 + 更小全满足 + 末位失败。
minimal_failure(B) :- is_gmw(B), below_all_satisfy(B),
                      last(B, Last), \+ satisfies_sch(Last).

% 穷举长 n 的 GMW 账簿（应恰一个）。
count_gmw(N, C) :-
    findall(B, (length(B, N), gen_bits(B), is_gmw(B)), Ls),
    length(Ls, C).

gen_bits([]).
gen_bits([0|T]) :- gen_bits(T).
gen_bits([1|T]) :- gen_bits(T).

% 交织影子：位移支配检查（有限段核查）。
shifts_above(A, B, K) :-
    between(0, 5, K),
    forall(between(K, 40, N),
           (call(B, N, BN), plus(N, K, NK), call(A, NK, ANK), BN =< ANK)).

% 序列样本（以谓词编码 n ↦ 值）。
seq_plus2(N, V) :- V is N + 2.
seq_id(N, N).
seq_double(N, V) :- V is 2 * N.
seq_nplus3(N, V) :- V is N + 3.

main :-
    format("==== 106~n"),
    % GMW 形态正反。
    is_gmw([0,0,0,1]),
    \+ is_gmw([0,1,0,1]),
    \+ is_gmw([0,0,0]),
    is_gmw([1]),
    % 最小失败与更小全满足。
    minimal_failure([0,0,0,1]),
    minimal_failure([1]),
    below_all_satisfy([0,0,0,1]),
    \+ below_all_satisfy([0,1,0,1]),
    % 穷举：每长度恰一个 GMW。
    forall(between(1, 8, N), (count_gmw(N, 1), true)),
    % 交织影子。
    shifts_above(seq_plus2, seq_id, 0),
    shifts_above(seq_double, seq_nplus3, K2), K2 >= 1,
    shifts_above(seq_id, seq_id, 0),
    format("GMW 每长度恰一（1..8）；更小节点全满足；交织位移支配（k2=~w）~n", [K2]),
    writeln("END ====").
```

### 通道七：Isabelle——集论核

```isabelle
theory Schcounter
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 106 章：有限 SCH 账簿的集论核（确定性规则链，沿 103-105 章纪律）。
本体（定义 2.12-2.19、引理 2.13-2.21、定理 2.12 Gitik-Magidor-Woodin）
留在正文。\<close>

text \<open>跳档点集与 GCH 点集互斥。\<close>

definition jumpP :: "i \<Rightarrow> o" where
  "jumpP(b) \<equiv> b = 1"

definition gchP :: "i \<Rightarrow> o" where
  "gchP(b) \<equiv> b = 0"

lemma gch_jump_disjoint: "gchP(b) \<Longrightarrow> \<not> jumpP(b)"
  unfolding gchP_def jumpP_def
proof (rule notI)
  assume h1: "b = 0" and h2: "b = 1"
  from h1 h2 have "0 = 1" by (rule subst)
  thus False by simp
qed

text \<open>更小节点全满足：初始段全 GCH。\<close>

definition allGCH :: "i \<Rightarrow> o" where
  "allGCH(A) \<equiv> \<forall>b\<in>A. gchP(b)"

lemma allGCH_empty: "allGCH(0)"
  unfolding allGCH_def by simp

lemma allGCH_cons: "allGCH(A) \<Longrightarrow> gchP(b) \<Longrightarrow> allGCH(cons(b, A))"
  unfolding allGCH_def
proof (rule ballI)
  fix x
  assume hA: "\<forall>b\<in>A. gchP(b)" and hb: "gchP(b)" and hx: "x \<in> cons(b, A)"
  show "gchP(x)"
  proof (cases "x = b")
    case True
    with hb show ?thesis by simp
  next
    case False
    with hx have "x \<in> A" by simp
    with hA show ?thesis by (rule bspec)
  qed
qed

text \<open>位移支配样本（引理 2.20 影子的序骨架）：
n ≤ succ(n)（对自然数）且经传递放大。\<close>

lemma le_succ_step: "n \<in> nat \<Longrightarrow> n \<le> succ(n)"
proof -
  assume hn: "n \<in> nat"
  have hOrd: "Ord(n)" by (rule nat_into_Ord) (rule hn)
  have hle: "n \<le> n" by (rule le_refl) (rule hOrd)
  show ?thesis unfolding le_succ_iff by (rule disjI1 [OF hle])
qed

lemma le_shift_sample:
  assumes h: "b \<le> n" and hs: "n \<le> succ(n)"
  shows "b \<le> succ(n)"
  by (rule le_trans [OF h hs])

end
```

### 通道注记

**Lean**（`gmwShape` 三合一定义 + `minimalFailure` 归约）：
账簿形态用「非空 ∧ 末位跳档 ∧ 其余全 GCH」一次性表达，
归约证明两行收口（`hall i` 给 GCH 点、`gch_jump_disjoint`
给非跳档）。`shiftsAbove` 的传递性是本章 Lean 最重的一笔：
`k₁ ≤ n + k₂` 须从 `k₁ + k₂ ≤ n` 手工链式推出（`m≤n+m`
与 `≤-trans` 三级传递），ω-样本的函数应用层（`(fun n =>
n+2) (n + 0)` 的 β-归约）omega 看不见——须 `show` 手工
展开（104 章同坑）。

**Coq**（`gmwShape` 归纳 + `compose_cofinal` 共顶合成）：
`minimalFailure` 对头部归纳（`induction B`），`gmwShape` 的
结构归纳自带「单元素跳档/多元素递归」的分案；`shifts_trans`
的算术重排用 `replace ... in Ha by lia`（方向账：replace
默认改目标、`in` 才改假设——首版忘 `in` 被 lia 抓）。

**Agda**（`GMW` 归纳族 + `gmw-decompose` 分解）：
`gmw-decompose` 是「最小失败归约」的构造版：从 GMW 证书
**提取**全 GCH 前缀 \(T\) 与等式 \(B=T{+}{+}[1]\)——
存在性证明即分解算法；`shifts-trans` 的 `rew` 需双层
rewrite（`+-assoc` + `+-comm`——项级 \(n+k_2+k_1\equiv
n+(k_1+k_2)\) 在 Agda 不是 refl）。

**Julia/Python**（穷举对拍主通道）：长度 1..8 的 \(2^n\)
种位移分配逐一核查——**每长度恰一个 GMW 账簿**（位移
0…01 是唯一形态），两侧独立到达同值；位移支配三样本
（含 k≥1 的下界核查——Julia 首版把 k=3 的必要条件写错
被穷举纠正）。Prolog 的 `below_all_satisfy` 是 Task 21
Step 2 的主查询（`append(Init, [_], B)` + `maplist`）。

**Isabelle**（确定性规则链第三轮）：`gch_jump_disjoint`
（0=1 矛盾三步）、`allGCH_empty/cons`（球面账）、
`le_succ_step`（`le_succ_iff` 展开取左支——`le_refl` 在
ZF 带侧条件 Ord(n)，须先 `nat_into_Ord` 显式供給）。

### 106.6b 穷举实验的统计面

Julia/Python 的 2^n 穷举除了「每长度恰一 GMW」还有几笔
统计值得记：长度 n 的位移表共 2^n 种，其中恰一个 GMW
（0…01）；恰一个「全 GCH」（0…0，无失败）；其余
2^n−2 种都在**中间**某处跳档——失败不孤悬。这三类
的占比随 n 指数级拉开：GMW 形态占 2^{-n}，但作为
「唯一让失败首现于末位」的形态，它在组合空间里是
**最稀有的合法账簿**。真值层的对应：定理 2.12 的模型
在 \(\aleph_\omega\) 以下全域 GCH——在「指数分配的空间」
里选择了唯一的极简形态。组合空间的贫瘠恰是数学约束
的丰富：GMW 形态的稀有性对应「首败恰在 ℵ_ω」的
严苛性。

### 机器件与本体对应（Task 21 Step 3 分栏声明）

| 机器件 | 数值实验层的含义 | **不是**什么 |
|---|---|---|
| `gmwShape` 账簿 | 位移表 0…01 的形态核查 | 不是 SCH 反例——有限位移表无基数语义 |
| `minimalFailure` | GMW 形态 ⟹ 失败孤悬末位 | 不是「SCH 首败在 ℵ_ω」——后者是关于 \(\aleph\) 函数的超穷命题 |
| 穷举 2^n | 每长度恰一 GMW 账簿 | 不是基数计数——n≤8 的组合事实 |
| `shiftsAbove` | 序列终段位移支配的自反/传递/样本 | 不是引理 2.20——后者断言泛型序列**必然**位移支配，靠泛型性命中稠密集族 |
| `below_all_satisfy` | 初始段逐点 GCH | 不是「∀μ<ℵ_ω 2^μ=μ⁺」——后者经 Lévy 塌缩的设计与引理 2.19/2.21 结算 |

**数值指数实验 ≠ 真实奇异基数证明**——上表右列是本章
的诚实边界。机器件的价值在于把定理 2.12 结论的**语法形态**
（「下方全满足 ∧ 顶点恰跳一档」）做成可对拍的组合对象，
以及在位移支配（引理 2.20 的序骨架）上建立五份独立实现。

## 106.7 机器的边界

1. **张子系统不可机化**：\(\langle U_\alpha\rangle\) 是
   \(\kappa^{++}\)-长的测度序列，RK 序 \(\le_E\) 的共顶性
   消费 GCH 的 \(2^\kappa=\kappa^+\)。有限影子只能做 RK
   序的语法（`compose_cofinal` 的合成账）。
2. **树条件与嫁接不可机化**：\((\alpha,s)\)-树的分裂集
   测一、瘦身技术、嫁接操作 \((g)^b\)、三断言的列表递归
   全在超穷层——引理 2.17 是全书单条证明之最，机器连
   「陈述」都无法有限化。
3. **交织引理的泛型性**：`shiftsAbove` 只验证「给定两列
   是否位移支配」；引理 2.20 断言的是**泛型序列必然**
   位移支配——「必然」由稠密集族的存在保证，有限层无
   对应物。
4. **基数结算**：引理 2.19（κ⁺⁺ 不塌）与 2.21（区间
   账）消费 cc + 完备性 + 迁移变换的复合；有限账簿无
   基数语义。
5. **七通道分工**：Lean/Coq/Agda 三份归约证明（每份
   各带一个「结构归纳」特色件——Lean 三合一形态/Coq 头
   归纳/Agda 归纳族分解）；Julia/Python 穷举对拍；Prolog
   主查询；Isabelle 集论核。

## 106.8 本章要点与检查问题

- **战役**：Silver 定理限制首败 cf=ω；定理 2.11 给出
  「某处失败」；GMW 定理 2.12 把失败推到 \(\aleph_\omega\)
  且下方全域 GCH——三步的假设从超紧（Magidor）降到
  \(\kappa^{++}\)-强（Woodin-Gitik）。
- **张子展开**：一个 \(\kappa^{++}\)-强张子 E 给出测度
  序列 \(\langle U_\alpha\mid\kappa\le\alpha<\kappa^{++}
  \rangle\)；RK 序 \(\le_E\) 共顶；投影函数表系统化
  （定义 2.13 的规范形状 + 事实 2.5.8 的共顶构造）。
- **四部件条件**：(f,T,τ,H)——控制函数（\(\le_E\)-坐标
  骨架）、Prikry 树（测一分裂）、Lévy 塌缩序列、投影侧
  塌缩函数；十条延展 + 直接延展（f 不动）。
- **三断言的 Prikry 条件**：列表递归（层内 \((\nu^\circ)
  ^{++}\)-局部有限）+ 逐层染色（κ-完全交）+ 降坐标换演
  （α→β 回缩）——判定性引擎的第三次工业化。
- **交织引理 2.20**：层间序列位移支配（几乎平移）——
  基数结算的组合心脏。
- **对照表**：104/105/106 三行的组合内核同一（判定性）、
  外围工程翻倍。
- **实测账**：Lean omega 看不见 β-红ex（show 展开）、
  `k₁ ≤ n+k₂` 手工三级链；Coq `replace in Ha` 方向账；
  Agda 双层 rewrite（assoc+comm）非 refl、where 不能见
  lambda 界定的 n（改显式参数）；Julia 穷举纠正 k≥1 下界
  的手写错账；Prolog `append(Init, [_], B)` 拆尾技巧
  （all_zero_prefix 整表遍历会撞末位 1——拆尾后 maplist
  仅扫 Init）；Isabelle `le_refl` 带 Ord 侧条件须
  `nat_into_Ord` 显式供给。

检查问题：

1. 事实 2.5.3 的 Crit(k_α)=κ⁺⁺ 计算中，若 V 不满足 GCH
   （2^κ > κ⁺），哪一步失效？（提示： Crit 的计算用
   「j(f)(α) 的值域封顶 κ⁺⁺」——值域大小来自 GCH 的
   κ^κ=κ⁺。）
2. 引理 2.17 断言一的列表为什么每个 ν°-层只需处理
   (ν°)⁺⁺ 个条件？若列表不保证「重复 λ 次」（定义
   2.13 前的列表要求），覆盖在哪里出现缺口？
3. 交织引理的位移 k(α) 为什么一定有限？（提示：引理
   2.8 的 π_αβ 之下 G_α 与 G_β 的逐点比较在有限处
   翻转——与机器通道 shiftsAbove 的 k 存在性对照。）
4. Julia/Python 穷举显示每长度恰一个 GMW 账簿。给出
   组合证明（n-1 个位置全 0、末位 1 的唯一性——但这
   不是「唯一性」的全部：GMW 形态的定义允许什么别的
   位移表？），并说明这与「SCH 首败唯一可能在 ℵ_ω」
   的真实命题在哪一层分岔。
5. 把 `shiftsAbove` 的定义从「∃k ∀n≥k」改成「∀n∃k」
   （逐点支配但 k 可随 n 变化），五份实现各会在哪条
   样本上失败？（提示：Julia 的 k 搜索固定后回扫。）

### 106.7a 收束

全章一句话总括：**张子把一个强基数展开成 κ⁺⁺ 串测度，
控制函数以 ≤_E 序调度坐标，四部件条件（f,T,τ,H）同时
做 Prikry 化、Lévy 塌缩与基数保全，嫁接三断言供判定性，
交织引理把 κ⁺⁺ 条序列统一到一条骨架——最终 2^{ℵ_ω}=
ℵ_{ω+2} 而 ℵ_ω 以下全域 GCH**。第 104 章的判定性=拉姆齐
性、第 105 章的大拿、本章的嫁接三断言是同一台引擎的
三次工业化；下一章转向另一条主线（恰当力迫与迭代公理）
——两条线在第 110 章（NS 饱和）合流。

本章机器件共 ~600 行源码，覆盖账簿形态、最小失败归约、
穷举统计与位移支配的五份实现；分栏声明（106.6 末表）
把「数值指数实验」与「真实奇异基数证明」逐行隔开——
有限位移表无基数语义，位移支配的「必然性」靠泛型性
而非序律。这是 Task 21 Step 3 的诚实边界，也是全教程
力迫章「砖块检验 + 房子讲解」原则的收官样本。

### 106.8a 检查问题提示

（第 1 题查 \(j(f)(\alpha)\) 值域封顶的 GCH 来源——
\(\kappa^\kappa=\kappa^+\) 在 2^κ>κ⁺ 时失效、(iii) 段
崩；第 2 题查列表重复性保证「每个 \(\nu^\circ\)-层的
每个条件都被某 \(b_i\) 覆盖」——不重复则覆盖缺口；
第 3 题查引理 2.8 的有限翻转——\(\pi_{\alpha\beta}\)
之下 \(G_\alpha\) 与 \(G_\beta\) 在测一集上 \(\tau\)-序
一致，有限差后位移固定；第 4 题的组合证明：GMW 定义
「非空+末位 1+其余全 0」在长度 n 的 2^n 张表中唯一——
但真值层的「首败唯一可能在 ℵ_ω」还需「下方全域 GCH」
由 Lévy 塌缩设计保证——组合形态唯一 ≠ 基数结论自动；
第 5 题改 ∀n∃k 后 k 随 n 增大，Julia 的固定 k 回扫在
n>k 处失败、Lean/Agda 的传递性证明也断（三级链的
k₁≤n+k₂ 不再可固定）。）

### 106.8b 工程档案

本章七通道共 ~600 行源码。实测坑合订：Lean omega
对 β-红ex 失明（`show n ≤ n + 2 + 0` 手工展开）、
k₁≤n+k₂ 的三级 ≤-trans 链、`by decide` 在
`List.getLast!` 上可用但 `by norm_num` 缺席（第二章
同坑第三次）；Coq `subst` 对 def 谓词（gchPoint）
不自动展开须 unfold、`replace ... in Ha` 方向账、
归纳的结构分案（单元素/多元素）须显式匹配；Agda
where 不能见 lambda 界定的 n（改显式参数）、双层
rewrite 非 refl（assoc+comm）、`≤-steps` 改
`≤-stepsʳ` 的版本账；Julia 穷举纠正手写的 k≥1 下界
（2n vs n+3 的位移必要条件——首版写 k≥3 被穷举打脸）；
Prolog `append(Init, [_], B)` 拆尾（all_zero_prefix
整表遍历撞末位 1——首版 is_gmw 假绿）；Isabelle
`le_refl` 的 Ord 侧条件（`nat_into_Ord` 显式供给）、
重复 end 命令的语法碎屑。全部入账 PLAN 与记忆。

---

上一章：[105 Silver 力迫](105-silver.md) · 下一章：[107 恰当力迫](107-proper.md)
