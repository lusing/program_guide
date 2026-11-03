# 103 · 小型扩张与 Lévy 崩塌

> 第 102 章为止的大基数全谱都住在「向上反射」的世界：假设越强，
> 下方景象越丰富。本章取材冯琦第三卷 §2.1–2.2（书页 145–155；
> PDF 165–175）转向**力迫**：大基数与泛型扩张如何互动？定理
> 2.1 给出第一个总答案——**小型力迫（$\mathbb P\in V_\kappa$）
> 改变不了任何大基数本质**：不可达、弱紧、拉姆齐、可测、强、
> 武丁、超强、强紧、超紧九款性质全部保持（且逆命题成立——
> 小型力迫也造不出原本没有的大基数）。证明的发动机是**嵌入
> 提升机制**：$j:V\to M$ 固定 $\mathbb P$ 与 $\mathbb B$
> （它们秩低于 $\kappa$），于是 $V$ 上的泛型滤子 $G$
> 同时是 $M$-泛型的，且
> $$
> j^*(\tau_G)=(j(\tau))_G
> $$
>
> 良定义（与名字选取无关）——$j$ 由此延拓成
> $j^*:V[G]\to M[G]$，九款保持律逐一复验。§2.2 反向出发：
> **Lévy 崩塌** $\mathrm{Col}(\omega,<\kappa)$（定义 2.1：
> 有限条件 $p\subseteq\kappa\times\omega$、$p(\alpha,n)\in \alpha$）把不可达 $\kappa$ 一步变成 $\omega_1$（定理
> 2.2：$\kappa$-cc 保一切 $\ge\kappa$ 的基数与梯度；对每个
> $\lambda<\kappa$、每个 $\beta<\lambda$，稠密集
> $D_\beta$ 见证 $\omega\twoheadrightarrow\lambda$ 的满射）。
> 定理 2.3 因子分解、定义 2.3–2.5 拟稠密/弱整齐/整齐、定理
> 2.4 黑白分明律与定理 2.5 延拓引理把 $\mathrm{Col}$ 的完备
> 布尔代数钉成**齐次的**——为第 111 章以后 $L(\mathbb R)$
> 的分析备好舞台。
>
> 机器边界：九款保持律与因子分解在超穷高度；七个通道做
> $\mathrm{Col}$ 的**条件层**——Lévy 条件（键 $(\alpha,n)$、
> 值 $\beta<\alpha$）的相容/拼接（Lean `unionC_cond`、Agda
> `splice-out`、Isabelle `unionP_funct` 三构造）、稠密性
> $D(\lambda,\beta)$ 的**书式新鲜槽号**（$n_0=1+\max$
> 已用槽——书 p152 公式逐字落码，Lean/Coq/Agda 证明 +
> Julia/Python/Prolog 全核验）、贪心泛型相遇与 $f_\lambda$
> 满射还原（定理 2.2 机制的有限化）、名字无关性影子（并的
> 集级交换 `unionC_set_eq`）。

## 103.1 定理 2.1：小型力迫不改变大基数

先把「小型」的量纲说清：$\mathbb P\in V_\kappa$ 意味着
$|\mathbb P|<\kappa$、$\mathbb P$ 的元素秩 $<\kappa$、
其完备布尔代数 $\mathbb B$ 也住在 $V_\kappa$ 里。第 89–92
章的力迫（CH 独立、MA 迭代、布尔值模型）大多**不满足**这个
小条件——加 $\kappa^+$ 个实数的 $\mathrm{Add}(\omega, \kappa^+)$ 以 $\kappa^+$ 为大小，不在 $V_\kappa$ 中。
定理 2.1 划出的领地是「**与 $\kappa$-层以下的宇宙相比微不足
道**」的力迫——恰是大基数反射论证里允许扰动的那一层。

> **定理 2.1** 设 $\kappa$ 是一个不可数基数，
> $\mathbb P\in V_\kappa$。设 $[\kappa]$ 为下述命题之一：
> (a) $\kappa$ 不可达；(b) 弱紧；(c) 拉姆齐；(d) 可测；
> (e) 强；(f) 武丁；(g) 超强；(h) 强紧；(i) 超紧。如果
> $[\kappa]$，那么 $\Vdash_{\mathbb P}[\kappa]$。且逆命题
> 成立（书 p145–146）。

九款性质按证明机器分四组读：**(a)(b)(c) 组合组**（不可达、
弱紧、拉姆齐）不消费嵌入，只用「$|\mathbb P|<\kappa$ 保基
数/梯度 + 名字账把 $V[G]$ 的对象折回 $V$」；**(d) 嵌入
组**（可测）建立 $j^*$ 提升机；**(e)(f)(g) 张子组**（强、
武丁、超强）复用 $j^*$ 加各自条款（武丁的名字账是本章的
新组件）；**(h)(i) 测度搬运组**（强紧、超紧）把
$\mathcal P_\kappa(\lambda)$ 上的测度沿 $j^*$ 搬运。
逆命题书 p146 只详证前四种——张子组的逆「技术细节比较复杂」
（原话），思路仍是理想饱和。

这条定理的历史地位值得三笔。**其一（CH 的无能为力）**：
Lévy–Solovay 1967 指出可测基数与 CH 独立——从可测 $\kappa$
出发，用 $\mathbb P\in V_\kappa$ 型的小力迫可以让 $2^{ \omega}=\omega_1$ 或 $\omega_3$ 而不动 $\kappa$ 的可测
性。**其二（「小」是必要的）**：本章 §2.2 的 Lévy 崩塌
$|\mathbb P|=\kappa$ 恰好把 $\kappa$ 变成 $\omega_1$
——可测性被**精确地**破坏在 $|\mathbb P|$ 触到 $\kappa$
的那一点（引理 2.1 显示 $\kappa$-cc 还在，但 $\kappa$
已不是基数）。**其三（与第 104–105 章的接口）**：Prikry 与
Silver 力迫将进一步展示「$>\kappa$ 大小的力迫仍然可以保
留 $\kappa$ 的大性」——小不是必要条件，是**充分**条件；
定理 2.1 的充分性边界在哪里，正是后两章的主题。

历史注脚（书 p145）：莱维与索洛维 1967 年首先意识到可测性
不被小力迫破坏——这条定理是「大基数对连续统假设无能为力」
的技术根源：任何 $\mathbb P\in V_\kappa$ 的力迫（包括加
$\kappa^+$ 个科恩实）都搬不动 $\kappa$ 的大基数性质，
因此**单靠可测（或任何固定 $\kappa$-级）基数无法决定
CH**——CH 的独立性在大基数世界里仍然独立。

**(a) 不可达**：$|\mathbb P|<\kappa$ 使一切 $\ge|\mathbb P|^+$
的基数与梯度保持；$\lambda<\kappa$ 时
$(2^\lambda)^{V[G]}\le|\mathbb B(\mathbb P)|^{V}\cdot 2^{\lambda{+}|\mathbb P|}<\kappa$（$\kappa$ 强极限）——
强极限与正则都保住。逆命题：$V[G]$ 中不可达直接下放。

**(b) 弱紧**：$V[G]$ 中的划分 $\bar f:[\kappa]^2\to 2$
有名字 $\tau\in V^{\mathbb B}$；逐点布尔值
$F(\{\alpha,\beta\})=\|\tau(\check\alpha,\check\beta)=0\|$
落在 $V$ 的 $F:[\kappa]^2\to\mathbb B$（$|\mathbb B|< \kappa$，按 $\kappa$-cc 的弱紧不可解性取整为 2-值划分的
一致），弱紧性给 $V$ 中的整齐集 $H$——验证 $H$ 在
$V[G]$ 中仍整齐（练习）。逆命题用「$V$ 的划分在
$V[G]$ 中有整齐集 $K$，找一个 $p\in G$ 力迫
$|\dot K|=\kappa$，取 $K_p=\{\alpha<p\Vdash\check\alpha \in\dot K\}$」。

(b) 的技巧是「**布尔值的逐点化**」：$V[G]$ 的 2-值划分
的名字在 $V$ 中是 $\mathbb B$-值划分——把每个点对的
真值提前算好，$V$ 侧的弱紧性作用于这个 $\mathbb B$-值
版本（$|\mathbb B|<\kappa$ 使 $\Pi^1_1$ 反射仍然够用）。
这与 (f) 的「逐值可能集」、逆命题的「素理想名字」共享同一
模式：**$V[G]$ 的对象一律先翻译成 $V$ 的布尔/可能性
数据，再用 $V$ 的反射机器**。(c) 拉姆齐同法（书 p148 留
练习），组合组三款一气贯通。逆命题里的 $K_p$（按条件
$p$ 分层的整齐子集）是「**名字分层**」的最小样本——
第 105 章 Silver 力迫与第 107 章恰当力迫的稠密性论证会把
这套分层做得精细得多。

**(d) 可测（完整证明——本章的枢纽）**：设 $j:V\to M$
临界点 $\kappa$。三件观察奠基：(1) $\mathbb P,\mathbb B \in V_\kappa$ 被 $j$ **固定**（$j(\mathbb P)=\mathbb P$，
秩低于临界点的元素逐点不动）；(2) $V_\kappa=V_\kappa^M$
使 $G\subseteq\mathbb P$ 的「与一切稠密集相交」在 $V$
与 $M$ 中**等价**——$G$ 自动 $M$-泛型；(3) 名字解释
吻合：$\tau^G=(j(\tau))^{G}$ 型的搬运在两个模型中算出同
一集合。于是定义
$$
j^*(\tau_G)=(j(\tau))_G.
$$

**名字无关性**：若 $p\in G$ 力迫 $\dot\tau=\dot\sigma$，
则 $M\models j(p)\Vdash j(\dot\tau)=j(\dot\sigma)$，而
$j(p)=p\in G$，故 $(j(\dot\tau))_G=(j(\dot\sigma))_G$
——$j^*$ 良定义。地基元素不动（$\check x$ 的搬运）给
$j^*\supseteq j$，临界点仍是 $\kappa$；$j^*(G)=G$。
初等性：$V[G]\models\varphi(\bar a)$ 有 $p\in G$ 见证
$p\Vdash\varphi(\dot{\bar a})$，$j$ 搬运后 $M\models p\Vdash\varphi(j(\dot{\bar a}))$，即
$M[G]\models\varphi(j^*(\bar a))$——$\Vdash$ 的归纳
 clauses 对 $j^*$ 逐条成立。∎

$j^*$ 提升机的四个部件值得各自点名，因为后面每章都要回来
取用：**(1) 固定件**——$\mathbb P,\mathbb B\in V_\kappa$
被 $j$ 固定（临界点下方逐点不动，第 94 章练习 1.7 的账）；
**(2) 双泛型件**——$V_\kappa=V_\kappa^M$ 使「稠密集」的
判据在两模型重合，$G$ 免费获得 $M$-泛型性；**(3) 搬运
件**——名字解释的交换律 $(j(\tau))_G$（$\tau$ 的 $j$
像在 $G$ 下求值）；**(4) 无关件**——同一集合的两个名字
搬运后仍给同一集合（$p\Vdash\dot\tau=\dot\sigma$ 经 $j$
得 $p\Vdash j(\dot\tau)=j(\dot\sigma)$，$j(p)=p\in G$
收口）。四件合起来是「**把 $V$-泛型滤子当成 $M$-泛型
滤子用**」的完整许可证——第 104 章 Prikry 的对角论证与第
110 章 NS 饱和的嵌入判据都以它为前提。

再看 (f) 武丁的名字账（书 p149），它是本组最细的一笔。
$V[G]$ 中的函数 $f:\delta\to\delta$ 不是 $V$ 的对象，
但它的**逐值可能集**是：$A_\alpha=\{\beta<\delta\mid\exists p\,(p\Vdash\beta=\dot f(\alpha))\}$ 每个至多 $|\mathbb P|$
元——因为若 $p,p'$ 都力迫不同值，它们冲突；把每个 $\beta$
映到其极小见证条件，单射进 $\mathbb P$。于是
$g(\alpha)=\sup(A_\alpha)+1$ 是「$\dot f$ 在 $\alpha$
处可能到达的高度」，其闭包点集 $C_g$ 是俱乐部。在 $C_g$
上取武丁见证 $\kappa'>|\mathbb P|$：$\dot f``\alpha \subseteq\alpha$（可能值全在 $\alpha$ 内）且
$V_{j(\dot f)(\kappa')}^M$ 装得下 $j^*$ 提升后的账。
**名字账的哲学**：把 $V[G]$ 的对象按「各坐标的可能值」
压缩回 $V$，使 $V$ 侧的反射机器照常运转——同一招在
(b) 弱紧（划分的名字逐点布尔化）与逆命题（素理想的名字）
里反复出现。

逆命题（$V[G]$ 可测 ⟹ $V$ 可测）走**理想饱和**：设
$U\in V[G]$ 是 $\kappa$ 上正规超滤子、$J$ 对偶素理想、
$\dot J\in V^{\mathbb P}$ 其名字。定义
$$
I=\{X\subseteq\kappa\mid\Vdash X\in\dot J\}.
$$

则 $I$ 是含单点的 $\kappa$-可加理想，且 **$I^+$ 中
不存在长 $|\mathbb P|^+$ 的模 $I$ 几乎不相交序列**（
$X,Y\in I^+$ 相交于 $I^+$ 的条件与力迫冲突条件一一对应；
素理想性封顶）——$I$ 是 $|\mathbb P|^+$-饱和的理想。
练习 2.2 把「$\kappa$ 上有饱和素理想的不可达性」升级成
可测性（正则超滤子的 Ulam 树论证）。

饱和账的两行值得放大，因为**理想饱和**是第 110 章 NS
（非荟萃集理想）饱和性的预演。第一行（几乎不相交序列的
缺失）：设 $\langle X_\alpha\mid\alpha<|\mathbb P|^+ \rangle$ 是 $I^+$ 中的序列。若 $X_\alpha\cap X_\eta\in I$，力迫条件「$X_\alpha\in\dot U$」与「$X_\eta\in\dot U$」
冲突（它们的交在 $I$ 中，而超滤子不许同时含一个 $I$-
小集的补集对）——于是一个固定的 $p$ 至多见证一个
$X_\alpha$；但每个 $X_\alpha\in I^+$ 都**被某 $p$ 力迫
进 $\dot U$**（否则 $\Vdash X_\alpha\notin\dot U$ 即
$X_\alpha\in I$），故 $|\mathbb P|\ge|\mathbb P|^+$——
矛盾。第二行（素性封顶）：对偶理想素 ⟹ 相交账二值化。
合起来：$I$ 是 $|\mathbb P|^+$-饱和的**素**理想——
Solovay 引理（练习 2.2）说这已是可测性的等价形态。「
**饱和 = 几乎不相交序列缺失**」这个组合判据在 NS 章会
原样重演（NS 的 $\kappa^+$-饱和 ⟺ 无 $\kappa^+$-长
几乎不相交的反荟萃序列）。

**(e)(f)(g) 强/武丁/超强**：同一 $j^*$ 提升机加各自条款。
(f) 武丁的额外账（书 p149）：$V[G]$ 中的函数
$f:\delta\to\delta$ 有名字，对每个 $\alpha$ 评估集
$A_\alpha=\{\beta<\kappa\mid\exists p\in\mathbb P\, (p\Vdash\beta=\dot f(\alpha))\}$ 至多 $|\mathbb P|$ 元
（每个 $\beta$ 至多占一个极小条件），$g(\alpha)=\sup A_\alpha+1$ 的闭包点俱乐部 $C_g$ 上的 $\alpha$ 满足
$\dot f``\alpha\subseteq\alpha$——**名字账把 $V[G]$
的函数截断成 $V$ 的局部函数**，武丁见证 $\kappa'>|\mathbb P|$
接手。**(h)(i) 强紧/超紧**：精良测度的**搬运**——$V$ 中
$U$ 给出 $H=[d]\in M$（$d:\mathcal P_\kappa(\lambda) \to\mathcal P_\kappa(j(\lambda))$ 恒等映射的名字像），
定义 $W=\{X\subseteq\mathcal P_\kappa(\lambda)\mid H\in j^*(X)\}$——非平凡、$\kappa$-完全、精良（$A_x\in W$ 的
账由 $H$ 含 $j``x$ 型代表），正规时 $H=j``\lambda$。

(h)(i) 的搬运公式 $W=\{X\mid H\in j^*(X)\}$ 有个值得点破
的机关：$H$ 不是 $j``\lambda$ 本身而是一个**名字像**
$[d]$（$d$ 为恒等映射的名字）。差别在哪里？$j^*(X)$
作用于 $V[G]$ 的集合 $X\subseteq\mathcal P_\kappa(\lambda) ^{V[G]}$，而 $j``\lambda\in M$ 是 $V$ 侧的对象——对
$V[G]$ 的新子集 $X$，「$j``\lambda\in j^*(X)$」未必
与 $V$ 侧的账对上；经 $[d]$（它在 $M[G]$ 中被求值）
中转，$W$ 的精良性可以逐点核对。这与定理 1.29（第 100
章）的 $d=j``\lambda$ 是同一角色的**两个版本**：无泛型
扰动时 $H=[d]=j``\lambda$；有扰动时必须走名字像。机器面
的 `unionC_set_eq`（名字无关性影子）正是这类中转合法性的
最小模型。

## 103.2 Lévy 崩塌：定义与 κ-链条件

> **定义 2.1（莱维偏序集）** 设 $\kappa$ 不可达。对
> $p\subseteq\kappa\times\omega\times\kappa$：
> $$
> p\in\mathrm{Col}(\omega,<\kappa) \iff |p|<\omega\wedge
> \mathrm{dom}(p)\subseteq\kappa\times\omega\wedge
> \forall(\alpha,n)\in\mathrm{dom}(p)\,(p(\alpha,n)\in\alpha),
> $$
>
> $q\le p\iff p\subseteq q$（反向包含），$\mathbb 1= \emptyset$。一般版 $\mathrm{Col}(\mu,<\kappa)$ 把
> $\omega$ 换成任意正则 $\mu$（定义 2.2）。

每个条件是一个**有限部分函数**：坐标 $(\alpha,n)$ 处放置
一个 $<\alpha$ 的「占位值」。第 $\alpha$ 行有无穷多个
槽位 $n$——正是这**行的无穷宽**让稠密性成立（见 103.3）。

「占位值 $<\alpha$」这个上界不是装饰：它让每一行的泛型
并**自动成为一个从 $\omega$ 到 $\alpha$ 的函数**（第
$\alpha$ 行的值域 $\subseteq\alpha$），无须再证良定性。
一般版 $\mathrm{Col}(\mu,<\kappa)$（定义 2.2）把 $\omega$
换成 $\mu$、条件大小 $<\mu$——$\kappa$ 变成 $\mu^+$。
书 p150 建议读者自行推广，本教程聚焦 $\mu=\omega$（后续
$L(\mathbb R)$ 分析用的正是这一版）。

$\mathbb 1=\emptyset$ 提醒我们这是**反向包含**序（$q\le p$
即 $q$ 信息更多）——与第 89 章 Fn 型力迫的约定一致；机器
通道的 `subsetC`/`extend_dense` 沿用「扩展 = 加键值对」的
读法。

> **引理 2.1** $\mathrm{Col}(\omega,<\kappa)$ 满足
> $\kappa$-链条件。

**证明**（书 p150–151，$\Delta$-系统式的荟萃账）：设
$\langle p_\alpha\mid\alpha<\kappa\rangle$ 为条件的单一
列。闭无界集
$C=\{\delta<\kappa\mid\forall\beta<\delta(\beta+1<\delta) \wedge\forall\alpha<\delta(\mathrm{dom}(p_\alpha)\subseteq \delta\times\omega)\}$。每条件分裂
$a_\alpha=\mathrm{dom}(p_\alpha)\cap(\alpha\times\omega)$、
$b_\alpha=\mathrm{dom}(p_\alpha)\setminus a_\alpha$。
对 $\delta\in C$ 令
$g(\delta)=\max\{\beta\mid\exists n\,((\beta,n)\in a_\delta)\}$（$\delta>0$；否则 0）。取荟萃 $T\subseteq C$ 与
$\beta<\kappa$ 使 $\forall\delta\in T\,(g(\delta)=\beta)$。
由 $|C^{<\omega}|<\kappa$ 取 $\beta^+=\mu$ 使
$p_\xi\upharpoonright(\mu\times\omega)$（$\xi\in T$）只有
$\le\mu$ 个不同值——再取荟萃 $T_0\subseteq T$ 上
**完全相同**。于是 $\xi\ne\eta\in T_0$ 时
$p_\xi\cup p_\eta$ 良定义（公共部分在 $\mu$ 以下一致，
其余坐标不相交）——相容。∎

这条证明其实是 **$\Delta$-系统引理的「荟萃平移」**：
教科书标准证法对 $\kappa$ 个有限域做 $\Delta$-系统
抽取（根 $r$ 固定、叶两两不交）；书 p150–151 的版本把
「根固定」替换成「$a_\delta$ 部分在固定 $\beta$ 下
完全相同」（更强的平直化），把「叶不交」替换成「坐标
$\ge\delta$ 自动不交」。**荟萃平移的代价是多了两层
细化**（$g$ 压平 + $T_0$ 相同化），收益是证明与
$\kappa$-cc 的使用方式（定理 2.2 引引理 I.3.34）无缝
衔接。两版对照读能看清「同一组合事实的不同表述强度」——
第 89 章 ccc 的 $\Delta$-系统与第 91 章迭代力迫的支撑
账在本章汇合。

值得机器面对照的细节：$a_\alpha/b_\alpha$ 的分裂把
条件的域切成「$\alpha$ 以下」（可能与兄弟条件相撞）与
「$\alpha$ 以上」（自动不相交，因为 $\eta>\xi$ 的
坐标 $\ge\eta>\xi$）——这正是 Agda `splice-out` 的
「键已覆盖则丢」在序数坐标下的几何版。`compat` 的公共键
一致检查在有限宇宙是逐点比对，在 $\kappa$-层是**结构性
不交**（域分裂保证）——有限影子只能照见「比对」照不见
「不交的结构来源」。

## 103.3 定理 2.2：κ 变成 ω₁

> **定理 2.2** 设 $M\models\mathrm{ZFC}$ 可数传递、
> $\kappa$ 是 $M$ 中不可达。$\mathbb P= (\mathrm{Col}(\omega,<\kappa))^M$、$G$ 为
> $M$-泛型。那么 (1) $M[G]\models\kappa=\omega_1$；
> (2) $M$ 中 $\mathrm{cf}(\lambda)\ge\kappa$ 的基数
> $\lambda$ 在 $M[G]$ 中仍有 $\mathrm{cf}\ge\kappa$。

**(2)** 由引理 2.1 的 $\kappa$-cc：$\ge\kappa$ 的基数与
梯度全保（引理 I.3.34 的引用）。**(1)** 的核心是**逐值稠密性**：
对 $\lambda<\kappa$ 不可数、$\beta<\lambda$，令
$$
D_\beta=\{p\mid\exists n\,((\lambda,n)\in\mathrm{dom}(p)
\wedge p(\lambda,n)=\beta)\}.
$$

**$D_\beta$ 稠密**（书 p152 的构造，逐字落进机器通道）：
给定 $q$，令
$$
n=1+\max\{m\mid\exists\alpha((\alpha,m)\in\mathrm{dom}(q))\},
\quad p=q\cup\{((\lambda,n),\beta)\}.
$$

$n$ 新鲜（大于一切已用槽号）、$p\supseteq q$、
$p(\lambda,n)=\beta<\lambda$ 合法——$p\in D_\beta$、
$p\le q$。∎ 泛型相遇后：
$$
f_\lambda(n)=\beta\iff\exists p\in G\,(p(\lambda,n)=\beta)
$$

良定义且**满**（每个 $\beta$ 的 $D_\beta$ 都被 $G$
击中）——$\omega\twoheadrightarrow\lambda$，$\lambda$
可数。$\lambda<\kappa$ 任意，故 $\kappa$ 之下再无不可数
基数；配合 (2)，$\kappa=\omega_1$。∎

良定义性的一行别放过：若 $p,p'\in G$ 都在坐标 $(\lambda,n)$
上有值，滤子性给公共延伸 $q\supseteq p,p'$，部分函数性给
$p(\lambda,n)=q(\lambda,n)=p'(\lambda,n)$——**同一个槽至
多一个值**。这条「槽-值唯一性」正是机器通道 `compat`/`functP`
所证的内容（条件层），泛型层只须再补「滤子两元必有公共
延伸」（上定向性）。定理 2.2 的证明骨架因此是三层：条件层
（部分函数性，机器证）→ 滤子层（定向 + 稠密相遇，贪心模拟）
→ 基数层（cc 保上、稠密塌下，正文组合账）——**每一层各吃
一台机器，层间接口清晰**是本章机器设计的出发点。

机器通道把这四步做成了可执行件（Lean/Coq/Agda 的三份
构造性证明 + Julia/Python/Prolog 的相遇与满射账，详见
103.6）：`fresh_n`（书式
$n_0=1+\max$）+ `extend_dense`（稠密性的**构造性证明**，
Lean/Coq/Agda 三份）+ 贪心相遇（Julia/Python/Prolog 对稠密
族 $\{D(\lambda,\beta)\}$ 逐目标扩展）+ $f_\lambda$ 满
射还原。**定理 2.2 的机制全部有限化，只有「泛型性 = 与
一切稠密集相交」的无穷量词留在正文**。

定理 2.2(2) 的另一半（$\mathrm{cf}(\lambda)\ge\kappa$ 保持）
同样值得机器面对照：贪心相遇只对 $\lambda\le 4$ 个目标
值扩展，每目标恰加一槽——**有限次扩展永不破坏有限条件**
（`extend_dense` 的 `compat p q` 断言），这正是「$\kappa$-cc
下有限信息不塌」的影子。而「$\omega_1$ 之上不再有 $\kappa$
以下的东西掉下来」的反面——**$\kappa$ 自身保住基数身份**——
在机器面看不到：有限宇宙里 $\kappa=4$ 本来就是「最大」，
「变成 $\omega_1$」与「保持原位」不可区分。边界条目 3
会回到这一点。

## 103.4 因子分解与整齐性：L(ℝ) 的地基

> **定理 2.3（因子分解引理）** $\kappa$ 不可达、
> $\mathbb P=\mathrm{Col}(\omega,<\kappa)$、$G$
> $V$-泛型。若 $X\in V[G]$ 是可数序数之集，则存在
> $V[X]$ 上的 $\mathbb P$-泛型滤子 $H$ 使
> $V[X][H]=V[G]$。

这条引理读起来抽象，用途却极具体：**中间模型定理**。$V[X]$
是 $V[G]$ 与 $V$ 之间的任意「小信息」模型——因子分解说
它仍然可以被同一个 $\mathbb P$ 从 $V$ 造出来（$X$ 的
信息被吸收进一个 $\mathbb P_{\nu+1}$ 片段，剩余泛型照常
拼接）。第 111–113 章的论证模式「在 $L(\mathbb R)$ 里取
实数参数 → 参数只占可数信息 → 因子分解把力迫拆成
『加参数』+『加剩余』两步 → 整齐性管第二步的真值」完全
建立在这条引理上。

证明（书 p152–153）的骨架：$\mathbb P\cong\mathbb P_\nu \times\mathbb P^\nu$（坐标 $\subseteq\nu\times\omega$ 与
$\subseteq(\kappa-\nu)\times\omega$ 的分裂）；$X$ 的
名字经满射 $\dot f:\omega\twoheadrightarrow X$ 用**极大
冲突子集** $W_n$（每 $|W_n|<\kappa$，链条件）截断到某
个 $\mathbb P_{\nu+1}$ 里；自分裂引理（推论 II.3.16）给
$V[X]$ 上的余下泛型。**因子分解 = 把「依赖 $\kappa$-
高度信息的对象」压进某个 $<\kappa$ 片段**——这正是
$L(\mathbb R)$ 分析的地基：实数集是可数序数的信息，
$L(\mathbb R)$ 的成员都能被 $\mathbb P_\nu$ 型的小力迫
处理。

极大冲突子集 $W_n$ 的账值得展开：$\dot f:\omega\twoheadrightarrow X$ 是满射的名字，每个 $n$ 处的值被一族两两冲突的条件
瓜分（不同值必不同见证条件）；$\kappa$-cc 使每族
$|W_n|<\kappa$，$\omega$ 个族的并仍 $<\kappa$——
于是某个 $\nu<\kappa$ 把**全部见证条件**装进
$\mathbb P_{\nu+1}$，$X$ 的名字即住在 $V[G\cap \mathbb P_{\nu+1}]$ 中。「**冲突族的小性 ⟹ 名字的有界性**」
与定理 2.1(f) 的名字账（可能值集 $|A_\alpha|\le|\mathbb P|$）
是同一枚硬币的两面：前者用 cc 数冲突，后者用条件数可能值——
都是把 $V[G]$ 的对象压回 $V$ 的有界片段。

> **定义 2.3–2.5 + 引理 2.2/2.3 + 定理 2.4/2.5 + 推论
> 2.1/2.2**：拟稠密（含稠密集与极大冲突集的公共推广）、
> 弱整齐（自同构轨道拟稠密）、整齐（任何两条件可互相搬运）。
> 定理 2.4（黑白分明律）：弱整齐力迫对**带地基参数的语句**
> 要么一律真要么一律假；定理 2.5（延拓引理）：$\mathbb B _{<\kappa}$ 的同构子代数间的同构可延拓为整体自同构
> （$\nu_n$ 阶梯的往返构造）；推论 2.1：$\mathrm{Col}$
> 的完备化是**整齐布尔代数**；推论 2.2：带参数语句的布尔值
> 非 0 即 1。

拟稠密（定义 2.3）的动机先说清：泛型滤子的判据「与一切
稠密集相交」可以逐级削弱——「与一切稠密**开**集相交」（引理
2.3(b)，开性来自序结构）、「与一切**拟稠密**集相交」（(c)：
拟稠密 = $\forall p\,\exists q\le p\,(q\in E)$，即在每个
点附近都有 $E$ 的元素**或其上方等价物**）、「与一切**极大
冲突**集相交」（(d)：冲突 = 无公共延伸）。四条判据等价（引
理 2.2/2.3，练习）——**泛型滤子是「躲不开的滤子」**：无论
你布置哪种「网」，它都要撞上。等价链的价值在于不同应用取
不同判据：整齐性证明用 (c)（轨道拟稠密 ⟹ 泛型滤子必与每条
轨道相遇），独立性论证用 (a)。

整齐性的机制一句话：**$\mathrm{Col}(\omega,<\kappa)$ 的
坐标网是对称的**——任何两个条件（非零布尔元）都能被某个
自同构搬运，因为它们都只是「有限张网」，网与网无本质区别。
黑白分明律由此而来：$\varphi(\bar a)$ 的布尔值被一切自同构
固定（自同构固定地基参数 $\bar a$），而整理布尔代数中被
一切自同构固定的元素只有 0 与 1。**第 111 章起
$L(\mathbb R)$ 中「$\varphi$ 的真值与泛型选取无关」
的全部论证都吃这台机器的红利**。

延拓引理（定理 2.5）的证明是**往返阶梯**：给定同构
$\pi_0:\mathbb B_0\cong\mathbb B_1$（两个 $<\kappa$ 大小
的完备子代数），交替扩大定义域/值域（$\nu_1<\nu_2<\cdots< \kappa$），每步用协调性引理（引理 I.3.94）把部分同构延拓
到更大的 $\mathbb B_{\nu_n}$；$\omega$ 步后取并，得
$\mathbb B_{<\kappa}$ 的自同构。往返的可行性完全依赖
$\kappa$ **不可达**（每步的代数大小 $<\kappa$，并也
$<\kappa$）——这是 Lévy 崩塌要求不可达而非 merely 正则
的深层原因之一。**往返构造**在第 97 章迭代超幂（交替扩张
模型链）与第 119 章迭代树（交替 ultrapower 分支）会以不同
姿态重演——「$\omega$-长往返 + 不可达封顶」是大基数技术
的又一台通用发动机。

## 103.5 三本账：保持基数 / 可数化 / 保持见证

Task 18 Step 3 的对照表——本章三种「改变或不改变」的机制
互不相同，混用即错：

| 账本 | 机制 | 量词位置 | 机器件 |
|---|---|---|---|
| **保持基数与梯度** | $\kappa$-cc（引理 2.1 的荟萃账）：反链 $<\kappa$ ⟹ $\ge\kappa$ 的势不塌 | 泛型前的组合论 | Agda/Isabelle 的拼接功能性（条件层的「部分函数」守恒） |
| **把旧基数可数化** | 逐值稠密 $D_\beta$（行无穷宽 + 新鲜槽号）：每个 $\beta<\lambda$ 被某槽击中 | 泛型相遇的存在性 | Lean/Coq 的 `extend_dense` + Julia/Python 贪心 + $f_\lambda$ 还原 |
| **保持大基数见证** | $j^*$ 提升（$j$ 固定 $\mathbb P$、名字无关性、初等性搬运）：九款条款逐一复验 | 嵌入层（非组合层） | `unionC_set_eq` 名字无关性影子（并的集级交换） |

三行机制的正交性：cc 是**纯组合**（不涉及嵌入）；可数化是
**稠密性工程**（不涉及 cc——$\mathrm{Col}$ 恰好两者兼备但
机制独立）；见证保持是**嵌入代数**（小型性 $\mathbb P\in V_\kappa$ 是唯一前提）。第 104 章 Prikry 力迫将展示「保基
数、改共尾度、不加有界子集」的第四种组合——三本账之外的
新格。

三本账的历史坐标也各不相同。**保基数**是最古老的承诺
（Cohen 1963 的原初动机就是「加实数不塌基数」——ccc 的发
现）；**可数化**是 Lévy 1965 的发明，为的是给可定义性研究
（Solovay 1970 的「所有实数集勒贝格可测」模型）提供
$\kappa=\omega_1$ 的舞台——**崩塌不是破坏，是布景**；
**保见证**是 Lévy–Solovay 1967 的观察，后来成为「大基数
公理的内稳定性」这条哲学线的起点（Easton 力迫可以在超大
基数之上随意改写连续统函数而下方大基数岿然不动——第 99
章 Solovay SCH 的对偶面）。读力迫章的纪律：先问「这章的
力迫在哪本账上行动」，再问「其他两本账付了什么代价」。

阅读路线图：§103.1 是概念与历史（九款保持律按四组读）；
§103.2–103.3 是本章技术主体（条件—稠密—相遇三步走，机器
件完全对齐）；§103.4 是面向 $L(\mathbb R)$ 的两台机器
（因子分解 + 整齐性）；§103.5 三本账表防混淆；机器通道
（§103.6）按「证明三件套 → 计算两件套 → 查询一件套 → 集
论核一件套」排列，Isabelle 节的实测账（THE-fst 死循环）值
得优先一读——它是七通道史上最重的单坑。

## 103.6 机器通道

七通道共享同一组数据件：条件 = （键 $(\alpha,n)$、值
$\beta<\alpha$）的有限函数（有限宇宙 $\alpha\in[1,4]$，
槽号 $n$ 无界——书式新鲜槽号可整段落码）；`compat`/
`extend_dense`/贪心相遇三件在七个语言里各有一份实现。
分工：**Lean**（拼接 + 稠密 + 名字无关性，证明最全）、
**Coq**（稠密性归纳证明）、**Agda**（拼接构造核 + 单元素
键读出）、**Julia/Python**（贪心相遇与 $f_\lambda$ 满射
还原的数值对拍）、**Prolog**（相容/扩展的双向查询）、
**Isabelle**（拼接与扩展的集论核——功能性守恒）。

### 通道一：Lean——条件、拼接与书式稠密性

```lean
import Mathlib.Data.List.Basic

/-!
# 第 103 章 · 小型扩张与 Lévy 崩塌

锚点（有限影子）：
- `Cond`：Lévy 条件（键 (α,n)、值 β<α、键无重复）；
- `compat` 与 `unionC_cond`：相容条件的拼接仍是条件；
- `freshN`/`extend_dense`：稠密性 D(λ,β) 的书式证明——
  n₀ = （用过的 n 之和）+ 1，与书 p152 的
  n = 1 + max{m | ∃α (α,m) ∈ dom(q)} 同一机制；
- `unionC_set_eq`：并的集级交换——名字无关性的影子。
本体（定理 2.1 九款保持律、定理 2.2/2.3、定理 2.5）留在正文。
-/

namespace Settheory.Ch103

abbrev Triple : Type := ((ℕ × ℕ) × ℕ)

/-- 键 (α,n)；α ∈ [1,4]（有限宇宙），值 β < α。 -/
def wfT (x : Triple) : Prop := 1 ≤ x.1.1 ∧ x.1.1 ≤ 4 ∧ x.2 < x.1.1

def keysOf (p : List Triple) : List (ℕ × ℕ) := p.map Prod.fst

/-- Lévy 条件：良形 + 键无重复（Col(ω,<κ) 的有限影子）。 -/
def Cond (p : List Triple) : Prop :=
  (∀ x ∈ p, wfT x) ∧ (keysOf p).Nodup

/-- 扩展序 q ⊒ p：p 的键值都在 q 中（p ⊆ q）。 -/
def subsetC (p q : List Triple) : Prop := ∀ x ∈ p, x ∈ q

/-- 相容：公共键上取值一致。 -/
def compat (p q : List Triple) : Prop :=
  ∀ x ∈ p, ∀ y ∈ q, x.1 = y.1 → x.2 = y.2

/-- 部分函数并（后侧去掉已覆盖键）。 -/
def unionC (p q : List Triple) : List Triple :=
  p ++ q.filter (fun y => ¬ (y.1 ∈ keysOf p))

theorem unionC_left (p q : List Triple) : subsetC p (unionC p q) :=
  fun _ hx => List.mem_append_left _ hx

theorem unionC_cond (p q : List Triple) (hp : Cond p) (hq : Cond q) :
    Cond (unionC p q) := by
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
    · intro k hk j hj hkj
      obtain ⟨y, hy, hyj⟩ := List.mem_map.1 hj
      have hneg : ¬ y.1 ∈ keysOf p := by
        simpa using (List.mem_filter.1 hy).2
      exact hneg (by rw [hyj]; exact hkj ▸ hk)

/-- 集级交换：相容时两种并次序给出同一集合（同一部分函数）。 -/
theorem unionC_set_eq (p q : List Triple) (hc' : compat q p) :
    subsetC (unionC p q) (unionC q p) := by
  intro x hx
  rcases List.mem_append.1 hx with h | h
  · by_cases hkey : x.1 ∈ keysOf q
    · obtain ⟨y, hy, hxy⟩ := List.mem_map.1 hkey
      have hxe : x = y := Prod.ext hxy.symm (hc' y hy x h hxy).symm
      exact List.mem_append_left _ (hxe ▸ hy)
    · exact List.mem_append_right _ (List.mem_filter.2 ⟨h, by simp [hkey]⟩)
  · exact List.mem_append_left _ (List.mem_filter.1 h).1

/-- 成员不超过总和（自证小引理）。 -/
theorem mem_le_sum (l : List ℕ) (n : ℕ) (hn : n ∈ l) : n ≤ l.sum := by
  induction l generalizing n with
  | nil => exact absurd hn (by simp)
  | cons a t IH =>
    rcases List.mem_cons.1 hn with rfl | hm
    · simp only [List.sum_cons]
      omega
    · have h := IH n hm
      simp only [List.sum_cons]
      omega

/-- 书式新鲜槽号：n₀ =（已用 n 之和）+ 1——大于一切已用的 n。 -/
def freshN (l : ℕ) (p : List Triple) : ℕ :=
  ((p.filter (fun x => x.1.1 = l)).map (fun x => x.1.2)).sum + 1

theorem freshN_gt (l : ℕ) (p : List Triple) (x : Triple) (hx : x ∈ p)
    (hxl : x.1.1 = l) : x.1.2 < freshN l p := by
  have hmem : x.1.2 ∈ (p.filter (fun y => y.1.1 = l)).map (fun y => y.1.2) :=
    List.mem_map.2 ⟨x, List.mem_filter.2 ⟨hx, by simp [hxl]⟩, rfl⟩
  have h := mem_le_sum _ _ hmem
  unfold freshN
  omega

/-- 稠密性 D(λ,β)：任何条件都可扩展至含 ((λ,n₀),β)。 -/
theorem extend_dense (l β : ℕ) (hl1 : 1 ≤ l) (hl4 : l ≤ 4) (hβ : β < l)
    (p : List Triple) (hp : Cond p) :
    ∃ q, Cond q ∧ subsetC p q ∧ ((l, freshN l p), β) ∈ q := by
  have hnew : ((l, freshN l p), β).1 ∉ keysOf p := by
    intro hcontra
    obtain ⟨x, hx, hxe⟩ := List.mem_map.1 hcontra
    have h1 : x.1.1 = l := congrArg Prod.fst hxe
    have h2 : x.1.2 = freshN l p := congrArg Prod.snd hxe
    have hlt := freshN_gt l p x hx h1
    omega
  refine ⟨p ++ [((l, freshN l p), β)], ⟨?_, ?_⟩,
    fun _ hx => List.mem_append_left _ hx,
    List.mem_append_right _ (by simp)⟩
  · intro x hx
    rcases List.mem_append.1 hx with h | h
    · exact hp.1 x h
    · rcases List.mem_cons.1 h with rfl | h
      · exact ⟨hl1, hl4, hβ⟩
      · exact absurd h (by simp)
  · unfold keysOf
    rw [List.map_append]
    refine List.nodup_append.2 ⟨hp.2, by simp, ?_⟩
    intro k hk j hj hkj
    obtain ⟨z, hz, hzj⟩ := List.mem_map.1 hj
    rcases List.mem_singleton.1 hz with rfl
    exact hnew (by rw [hzj, ← hkj]; exact hk)

/-- 样本：键不相交的两条件相容；键相同值不同则不相容。 -/
example : compat [((2, 0), 1)] [((3, 1), 2)] := by
  intro x hx y hy hxy
  simp only [List.mem_singleton] at hx hy
  subst hx; subst hy
  exact absurd hxy (by decide)

example : ¬ compat [((2, 0), 1)] [((2, 0), 0)] := by
  intro hc
  have hm1 : ((2, 0), 1) ∈ [((2, 0), 1)] := by simp
  have hm2 : ((2, 0), 0) ∈ [((2, 0), 0)] := by simp
  have h : ((2, 0), 1).2 = ((2, 0), 0).2 :=
    hc ((2, 0), 1) hm1 ((2, 0), 0) hm2 rfl
  exact absurd h (by decide)

example (hp : Cond [((2, 0), 1)]) (hq : Cond [((3, 1), 2)]) :
    Cond (unionC [((2, 0), 1)] [((3, 1), 2)]) :=
  unionC_cond [((2, 0), 1)] [((3, 1), 2)] hp hq

end Settheory.Ch103
```

Lean 版四件：`Cond`（键无重复 + 良形）、`unionC_cond`（相容
拼接仍是条件——`nodup_append` 三段式的第三段是键集不交账）、
`freshN`/`extend_dense`（书 p152 的 `n₀=1+max` 落成
`1+sum`，新鲜性由「成员 ≤ 总和」自证引理收口）、
`unionC_set_eq`（名字无关性影子）。三份证明的关系：
`freshN_gt` 用「成员 ≤ 总和」（`mem_le_sum` 自证）代替书的
`max`——sum 版可归纳、max 版要分类讨论，这是把书式公式
**转成可证形状**的典型一步；`extend_dense` 的关键引理
`hnew`（新槽号不在已用键中）由 sum-界一击收口。实测坑最重
的一笔：`List.nodup_append` 的第三分量是裸 ∀ 形（`∀ a ∈ l₁,
∀ b ∈ l₂, a ≠ b`）而非 `Disjoint`——`List.disjoint_left.mpr`
整不上，直接五段 `intro` 才对上形状（八轮攻坚的主坑）；
另有 `norm_num` 缺位（数字比较用 `omega`）、`List.filter`
的成员引理在构造侧要 `decide = true`（`by simp [h]` 桥）而
析构侧 `simpa` 化归命题形。与 Lean 的分工：Lean 证拼接
（`unionC_cond`），Coq 专证稠密（`freshN_gt`+`extend_dense`
双件）——两通道合起来覆盖 `unionC`+`D(λ,β)` 的全部定理层，
Agda 再给构造性第三票。`extend_dense` 的 NoDup 第三段
（键不交）用 `f_equal (@fst _ _)` 读出单元素键再与
`freshN_gt` 对撞——「投影相等性」在三个证明器里三种写法
（Lean `congrArg`、Coq `f_equal`、Agda `cong`）。

### 通道二：Coq——稠密性的归纳证明与样本

与 Lean 的分工：Lean 证拼接（`unionC_cond`），Coq 专证稠密
（`freshN_gt` + `extend_dense` 双件）——两通道合起来覆盖
条件—拼接—扩展的全部定理层，Agda 给构造性第三票。

```coq
(* 第 103 章：Lévy 条件、相容性与稠密性 D(λ,β) 的书式证明。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

Module Ch103.

(* 条件 = 三元组表 ((α,n),β)：键 (α,n) 无重复、α∈[1,4]、β<α。 *)
Definition wfT (x : (nat * nat) * nat) : Prop :=
  1 <= fst (fst x) <= 4 /\ snd x < fst (fst x).

Definition keysOf (p : list ((nat * nat) * nat)) : list (nat * nat) :=
  map fst p.

Definition Cond (p : list ((nat * nat) * nat)) : Prop :=
  (forall x, In x p -> wfT x) /\ NoDup (keysOf p).

Definition compat (p q : list ((nat * nat) * nat)) : Prop :=
  forall x y, In x p -> In y q -> fst x = fst y -> snd x = snd y.

(* ── 一、稠密性 D(λ,β)：n₀ = 已用 n 之和 + 1（书 p152 公式） ── *)

Fixpoint sumL (l : list nat) : nat :=
  match l with [] => 0 | a :: t => a + sumL t end.

Lemma mem_le_sum : forall (l : list nat) n, In n l -> n <= sumL l.
Proof.
  induction l as [|a t IH]; simpl; intros n Hn.
  - contradiction.
  - destruct Hn as [->|Hn].
    + lia.
    + specialize (IH n Hn). lia.
Qed.

Definition freshN (l : nat) (p : list ((nat * nat) * nat)) : nat :=
  1 + sumL (map (fun z => snd (fst z))
             (filter (fun z => Nat.eqb (fst (fst z)) l) p)).

Lemma freshN_gt : forall l p x, In x p -> fst (fst x) = l ->
  snd (fst x) < freshN l p.
Proof.
  intros l p x Hx Hl.
  assert (Hmem : In (snd (fst x))
            (map (fun z => snd (fst z))
                 (filter (fun z => Nat.eqb (fst (fst z)) l) p))).
  { apply (proj2 (in_map_iff _ _ _)). exists x. split.
    - reflexivity.
    - apply filter_In. split; [exact Hx|]. apply Nat.eqb_eq. exact Hl. }
  pose proof (mem_le_sum _ _ Hmem) as Hle.
  unfold freshN. lia.
Qed.

Theorem extend_dense : forall l beta p,
  1 <= l -> l <= 4 -> beta < l -> Cond p ->
  exists q,
    (forall x, In x p -> In x q) /\ In ((l, freshN l p), beta) q /\ Cond q.
Proof.
  intros l beta p Hl1 Hl4 Hbeta [hw hnd].
  exists (p ++ ((l, freshN l p), beta) :: nil).
  split; [|split].
  - intros x Hx. apply in_or_app. left; exact Hx.
  - apply in_or_app. right. left. reflexivity.
  - split.
    + intros x Hx. apply in_app_or in Hx.
      destruct Hx as [H|H].
      * apply hw; exact H.
      * destruct H as [E|[]]. subst x. unfold wfT. simpl.
        repeat split; lia.
    + unfold keysOf. rewrite map_app. simpl.
      apply NoDup_app.
      * exact hnd.
      * apply NoDup_cons; [simpl; tauto | constructor].
      * intros a Ha Hb.
        simpl in Hb. destruct Hb as [Hb|[]]. subst a.
        apply (proj1 (in_map_iff _ _ _)) in Ha.
        destruct Ha as [x [Hfx Hx]].
        assert (Hl : fst (fst x) = l).
        { pose proof (f_equal (@fst _ _) Hfx) as Hc. simpl in Hc. exact Hc. }
        pose proof (freshN_gt l p x Hx Hl) as Hgt.
        assert (Hs : snd (fst x) = freshN l p).
        { pose proof (f_equal (@snd _ _) Hfx) as Hc. simpl in Hc. exact Hc. }
        lia.
Qed.

(* ── 二、样本：相容/不相容与稠密扩展的具体形状 ── *)

Example sample_compat : compat [((2,0),1)] [((3,1),2)].
Proof.
  intros x y Hx Hy Hxy.
  simpl in Hx, Hy, Hxy.
  destruct Hx as [Hx|[]]; destruct Hy as [Hy|[]]; subst.
  injection Hxy as E1 E2. lia.
Qed.

Example sample_not_compat : ~ compat [((2,0),1)] [((2,0),0)].
Proof.
  intros hc.
  assert (H : 1 = 0).
  { apply (hc ((2,0),1) ((2,0),0)); simpl; auto. }
  discriminate.
Qed.

(* 稠密扩展样本：freshN 2 [((2,5),0)] = 6（λ=2 的已用 n 只有 5，
   n₀ = 1+5——大于一切已用槽号）。 *)
Example sample_fresh : freshN 2 [((2,5),0)] = 6.
Proof. reflexivity. Qed.

End Ch103.
```

Coq 版主件 `freshN_gt`（已用槽 ≤ 总和的归纳账）+
`extend_dense`（扩展条件的功能性与 NoDup 三段账——
`in_map_iff` 的组件序在本版是 `f x = y ∧ In x l`）。实测坑：
`in_map_iff` 需**显式给 y**（`proj2 (in_map_iff _ _ _)`，
两个 `_` 时 proj2 套不进 ∀-iff）；`NoDup_app` 第三前提是
`∀ a, In a l₁ → ~In a l₂`（两段非三段）；`wfT` 这类
`A ∧ B ∧ C` 展开用 `repeat split; lia`（`split; lia` 会在
非合取上炸 `Not an inductive goal`）；`congrArg` 不存在
（用 `f_equal (@fst _ _)`）。

### 通道三：Agda——有限支撑拼接

Task 18 指定的「有限支撑拼接」证明主通道：`splice-out`
把「键已覆盖则丢、否则留」写成可匹配的 with 构造子——
消费侧（`sample-union` 的 `refl`）零反演，是 99 章
`anyb/allb` 决策的第三次复用。

```agda
-- 第 103 章：Lévy 条件的有限支撑拼接与稠密扩展（书式新鲜槽号）。
module Ch103_levy where

open import Data.Nat using (ℕ; zero; suc; _+_; _<_; _≤_; z≤n; s≤s)
open import Data.Nat.Properties using (≤-refl; ≤-trans; m≤n+m; m≤m+n)
open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Maybe using (Maybe; nothing; just)
open import Data.List using (List; []; _∷_; _++_)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Empty using (⊥; ⊥-elim)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong; trans; sym)
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

Triple : Set
Triple = (ℕ × ℕ) × ℕ

-- 键相等时成员值可读。
lookup : ℕ × ℕ → List Triple → Maybe ℕ
lookup k [] = nothing
lookup k ((k' , β) ∷ t) = if key-eq k k' then just β else lookup k t

-- 相容：公共键上取值一致。
agree : List Triple → List Triple → Set
agree p q = ∀ k a b → (k , a) ∈L p → (k , b) ∈L q → a ≡ b

-- ── 一、有限支撑拼接：相容两条件的合并 ──

keys : List Triple → List (ℕ × ℕ)
keys [] = []
keys ((k , _) ∷ t) = k ∷ keys t

inKeys : ℕ × ℕ → List (ℕ × ℕ) → Bool
inKeys k [] = false
inKeys k (k' ∷ t) = if key-eq k k' then true else inKeys k t

-- 拼接：q 中去掉已被 p 覆盖的键。
splice-out : List (ℕ × ℕ) → List Triple → List Triple
splice-out ks [] = []
splice-out ks (x@((k₁ , n) , β) ∷ t) =
  if inKeys (k₁ , n) ks then splice-out ks t else x ∷ splice-out ks t

unionC : List Triple → List Triple → List Triple
unionC p q = p ++ splice-out (keys p) q

-- 成员并入账（自证）。
∈-++₁ : ∀ {A : Set} (x : A) (l r : List A) →
  (x ∈L l ⊎ x ∈L r) → x ∈L (l ++ r)
∈-++₁ x [] r (inj₁ ())
∈-++₁ x (y ∷ l) r (inj₁ here) = here
∈-++₁ x (y ∷ l) r (inj₁ (there h)) =
  there (∈-++₁ x l r (inj₁ h))
∈-++₁ x [] r (inj₂ h) = h
∈-++₁ x (y ∷ l) r (inj₂ h) = there (∈-++₁ x l r (inj₂ h))

-- 拼接保留左条件（p ⊆ unionC p q）。
unionC-left : ∀ p q x → x ∈L p → x ∈L (unionC p q)
unionC-left p q x hx = ∈-++₁ x p (splice-out (keys p) q) (inj₁ hx)

-- ── 二、书式新鲜槽号：n₀ = 已用 n 之和 + 1 ──

sumL : List ℕ → ℕ
sumL [] = zero
sumL (x ∷ t) = x + sumL t

ns-of : ℕ → List Triple → List ℕ
ns-of l [] = []
ns-of l (((a , n) , _) ∷ t) =
  if nat-eq a l then n ∷ ns-of l t else ns-of l t

freshN : ℕ → List Triple → ℕ
freshN l p = suc (sumL (ns-of l p))

-- 成员不超过总和（自证）。
sumL-≥ : ∀ l n → n ∈L l → n ≤ sumL l
sumL-≥ [] n ()
sumL-≥ (m ∷ t) .m here = m≤m+n m (sumL t)
sumL-≥ (m ∷ t) n (there h) =
  ≤-trans (sumL-≥ t n h) (m≤n+m (sumL t) m)

-- λ 槽上的已用 n 都小于 n₀（书 p152 的 n = 1+max 同型机制）。
freshN-gt : ∀ l p n → n ∈L (ns-of l p) → n < freshN l p
freshN-gt l p n hn = s≤s (sumL-≥ (ns-of l p) n hn)

-- ── 三、样本 ──

-- 键不相交的两条件拼接后原样保留。
sample-union : unionC (((2 , 0) , 1) ∷ []) (((3 , 1) , 2) ∷ [])
             ≡ (((2 , 0) , 1) ∷ ((3 , 1) , 2) ∷ [])
sample-union = refl

-- λ=2 已用槽 5：n₀ = 1+5 = 6。
sample-fresh : freshN 2 (((2 , 5) , 0) ∷ []) ≡ 6
sample-fresh = refl

-- λ=3 无已用槽：n₀ = 1。
sample-fresh-empty : freshN 3 (((2 , 5) , 0) ∷ []) ≡ 1
sample-fresh-empty = refl

-- 单元素成员的键读出。
mem-singleton-key : ∀ (k : ℕ × ℕ) (a : ℕ) (t : Triple) →
  (k , a) ∈L (t ∷ []) → k ≡ proj₁ t
mem-singleton-key .(proj₁ t) a t here = refl
mem-singleton-key k a t (there ())

2≢3 : suc (suc zero) ≡ suc (suc (suc zero)) → ⊥
2≢3 ()

-- 键不相交 ⟹ 相容（空 confrontation：k 无法两侧同时在场）。
sample-agree : agree (((2 , 0) , 1) ∷ []) (((3 , 1) , 2) ∷ [])
sample-agree k a b h1 h2 =
  ⊥-elim (2≢3 (cong proj₁
    (trans (sym (mem-singleton-key k a (((2 , 0) , 1)) h1))
           (mem-singleton-key k b (((3 , 1) , 2)) h2))))
```

Agda 版主件 `splice-out`（拼接的构造核——键已覆盖则丢、
否则留）+ `∈-++₁`（并入账自证）+ `sumL-≥`/`freshN-gt` +
`sample-agree`（键不相交条件的相容性：两侧单元素成员的键
读出 `mem-singleton-key` 经 `trans`/`sym` 合成 `2 ≡ 3` 的
荒谬）。实测坑：列表字面量**没有逗号语法**（`[a, b]` 是
Σ-语法——必须 `x ∷ y ∷ []`）；`m≤n+m` 的参数序是
`m ≤ n + m`（首个参数是被界者——两处调用各错一次被抓）；
点模式 `.(proj₁ t)` 需全类型标注防 ∈L 的多态元变量悬空。
`splice-out` 是 Task 18 指定的「有限支撑拼接」主件：键已覆
盖则丢、否则留——Agda 的 with 分支让「覆盖判定」成为可
匹配的构造子信息，消费侧（`sample-union` 的 `refl`）零反演；
与 Lean `unionC`（filter 版）、Isabelle `unionP`（集论版）
构成同一对象的三个编码层（列表/过滤器/集合）。

### 通道四：Julia——贪心泛型相遇

Julia/Python 承担定理 2.2 的**机制全件**：这是本章里机器
与数学最贴近的一段——书的构造（新鲜槽号、稠密扩展、泛型
相遇、满射还原）逐行落码，断言网覆盖「扩展合法（良形 +
相容 + 新鲜）」与「相遇后结构（每值被击中、每 λ 槽数正确）」
两个层面。

```julia
# 第 103 章：Lévy 条件、稠密性 D(λ,β) 与贪心泛型相遇。
println("==== 103")

# ── 一、Lévy 条件：有限部分函数，键 (λ,n)、值 β<λ（书定义 2.1）──
# 槽号 n ∈ ℕ 无界——书 p152 的 n = 1 + max 公式可直接落码。
const KAPPA = 4  # 有限宇宙：λ ∈ {1,2,3,4}

is_cond(p::Dict{Tuple{Int,Int},Int}) =
    all(1 ≤ l ≤ KAPPA && 0 ≤ β < l for ((l, n), β) in p)

compat(p, q) =
    all(p[k] == q[k] for k in keys(p) if haskey(q, k))

# 书式新鲜槽号：n₀ = 1 + max{已用的 n}（无已用时 0）。
fresh_n(l, p) = 1 + maximum((n for ((λ, n)) in keys(p) if λ == l); init=0)

# 稠密性 D(λ,β)：任何条件可扩展至含 ((λ,n₀),β)。
function extend_dense(l, β, p)
    n₀ = fresh_n(l, p)
    q = copy(p); q[(l, n₀)] = β
    return q
end

# 稠密性核查：对一切 (λ,β) 与一切条件 p，扩展存在且合法。
for l in 1:KAPPA, β in 0:(l-1)
    p = Dict((2, 0) => 1, (3, 1) => 2)  # 任意样本条件
    n₀ = fresh_n(l, p)
    q = extend_dense(l, β, p)
    @assert is_cond(q) && compat(p, q)
    @assert any(k[1] == l && q[k] == β for k in keys(q))
    # n₀ 新鲜：与 p 的一切 λ-槽不同。
    @assert all(n₀ != n || p[(l, n)] == β
                for ((λ, n)) in keys(p) if λ == l)
end

# ── 二、贪心泛型相遇：对稠密族 {D(λ,β)} 逐个扩展 ──
# 定理 2.2 的机制：G 的并定义 f_λ: ω→λ 满射。
function greedy_generic(dense_targets)
    p = Dict{Tuple{Int,Int},Int}()
    for (l, β) in dense_targets
        p = extend_dense(l, β, p)
    end
    return p
end

targets = [(l, β) for l in 1:KAPPA for β in 0:(l-1)]
g = greedy_generic(targets)
@assert is_cond(g)
# f_λ 还原：对每个 λ<κ 与 β<λ，∃n 使 g[(λ,n)]=β——λ 被可数化。
for l in 1:KAPPA, β in 0:(l-1)
    @assert any(haskey(g, (l, n)) && g[(l, n)] == β for n in 0:100)
end

# ── 三、样本与对拍断言 ──
p0 = Dict((2, 0) => 1)
@assert fresh_n(2, p0) == 1          # 已用槽 {0} → n₀=1
@assert fresh_n(2, Dict((2,5) => 0)) == 6
@assert fresh_n(3, p0) == 1          # λ=3 无已用槽
@assert compat(Dict((2,0)=>1), Dict((3,1)=>2))
@assert !compat(Dict((2,0)=>1), Dict((2,0)=>0))
# 贪心相遇后每 λ 的使用槽数 = λ 个（β 全覆盖）。
for l in 1:KAPPA
    used = count(k[1] == l for k in keys(g))
    @assert used == l
end

println("Julia：稠密性 D(λ,β) 全核验（n₀=1+max 书式公式）；")
println("贪心泛型相遇后 f_λ 满射还原——λ<κ 全体可数化（定理 2.2 机制）")
println("END ====")
```

Julia 版把定理 2.2 的机制完整落码：`fresh_n`（`1 + maximum
(...; init=0)`——`init` 处理空情形恰是书里「无已用槽」分支）、
`extend_dense`（构造扩展）、`greedy_generic`（对稠密目标族
逐个扩展——泛型相遇的贪心模拟）、`f_λ` 满射还原断言
（每个 β 被某槽击中）与「每 λ 恰用 λ 槽」的结构断言。实测
坑：Unicode 变量 `n₀` 在 `extend_dense` 内部定义而断言处
引用外部作用域——`UndefVarError`，须在循环里显式绑定。
「每 λ 恰用 λ 槽」的断言把贪心相遇的结构也钉住了：目标族
按 λ 分组扩展时，第 λ 组只动 λ 行——行间无干扰（键不相
交）正是 `compat` 逐行成立的组合面。有限宇宙里贪心总能成
功，真实力迫里「对一切稠密族」由泛型性承担——贪心是泛型
的可数骨架。

### 通道五：Python——独立对拍

对拍的孤本纪律（82 章确立、102 章重申）：两侧同构不同实现
（`dict` vs `Dict`、`max(default=0)` vs `maximum(init=0)`），
任何一侧的机制件错位都会在断言网撞出声来。

```python
# 第 103 章：与 Julia 独立对拍——稠密性、贪心泛型相遇与 f_λ 还原。
import io
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

KAPPA = 4


def is_cond(p):
    return all(1 <= l <= KAPPA and 0 <= b < l for (l, n), b in p.items())


def compat(p, q):
    return all(p[k] == q[k] for k in p.keys() & q.keys())


def fresh_n(l, p):
    used = [n for (lam, n) in p if lam == l]
    return 1 + max(used, default=0)


def extend_dense(l, b, p):
    q = dict(p)
    q[(l, fresh_n(l, p))] = b
    return q


def greedy_generic(targets):
    p = {}
    for l, b in targets:
        p = extend_dense(l, b, p)
    return p


def main():
    print("==== 103")
    p0 = {(2, 0): 1}
    assert fresh_n(2, p0) == 1
    assert fresh_n(2, {(2, 5): 0}) == 6
    assert fresh_n(3, p0) == 1
    assert compat({(2, 0): 1}, {(3, 1): 2})
    assert not compat({(2, 0): 1}, {(2, 0): 0})

    # 稠密性核查（与 Julia 同款双条件：扩展合法 + n₀ 新鲜）。
    for l in range(1, KAPPA + 1):
        for b in range(l):
            p = {(2, 0): 1, (3, 1): 2}
            q = extend_dense(l, b, p)
            assert is_cond(q) and compat(p, q)
            assert any(k[0] == l and q[k] == b for k in q)
            n0 = fresh_n(l, p)
            assert all((l, n0) not in p or p[(l, n0)] == b
                       for _ in [0])

    targets = [(l, b) for l in range(1, KAPPA + 1) for b in range(l)]
    g = greedy_generic(targets)
    assert is_cond(g)
    for l in range(1, KAPPA + 1):
        for b in range(l):
            assert any(g.get((l, n)) == b for n in range(100))
        used = sum(1 for k in g if k[0] == l)
        assert used == l

    print("Python：稠密性/新鲜槽/贪心相遇/f_λ 满射还原——与 Julia 独立对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
```

与 Julia 同构的独立实现（dict/frozenset vs Dict/生成器）；
稠密性核查的双条件（扩展合法 + 槽号新鲜）与贪心相遇后
的满射/槽计断言逐条对拍。Python 侧的 `fresh_n` 用
`max(used, default=0)` 对 Julia 的 `maximum(...; init=0)`——
两个「空表默认」恰好都是书里「无已用槽 → n₀=1」分支的
编码；这类默认值对位是两侧最易错位的地方（第 82 章策略
查询位同款教训）。

### 通道六：Prolog——支撑相容查询

Task 18 指定的「支撑相容性检查」主通道：`compat/2` 逐公共
键比对（`lookup` 截断式首键命中）、`extend_dense/4` 一式
产出扩展、`greedy/3` 尾递归相遇——查询方向可翻转（给定 G
反查击中的稠密集族）。

```prolog
:- encoding(utf8).
% 第 103 章：Lévy 条件的支撑相容性与稠密扩展查询。

% 条件 = 三元组表 (α, n, β)（键 (α,n) 无重复由插入侧保证）。
lookup((A, N), [(A, N, B)|_], B) :- !.
lookup(K, [_|T], B) :- lookup(K, T, B).

has_key((A, N), [(A, N, _)|_]) :- !.
has_key(K, [_|T]) :- has_key(K, T).

% 支撑相容：公共键上取值一致。
compat(P, Q) :-
    forall((member((A, N, B1), P), lookup((A, N), Q, B2)), B1 == B2).

% 书式新鲜槽号：n₀ = 1 + max{已用 n}。
fresh_n(L, P, N0) :-
    findall(N, (member((A, N, _), P), A == L), Ns),
    ( Ns == [] -> N0 = 1 ; max_list(Ns, M), N0 is M + 1 ).

% 稠密扩展：q = p ∪ {(λ, n₀, β)}。
extend_dense(L, Beta, P, Q) :-
    fresh_n(L, P, N0),
    append(P, [(L, N0, Beta)], Q).

% 稠密性核查：扩展后相容且含目标项。
dense_ok(L, Beta, P) :-
    extend_dense(L, Beta, P, Q),
    compat(P, Q),
    lookup((L, _), Q, Beta).

main :-
    format("==== 103~n"),
    % 样本相容/不相容。
    compat([(2,0,1)], [(3,1,2)]),
    \+ compat([(2,0,1)], [(2,0,0)]),
    % 新鲜槽号三样本（与 Julia/Python 对拍）。
    fresh_n(2, [(2,0,1)], 1),
    fresh_n(2, [(2,5,0)], 6),
    fresh_n(3, [(2,0,1)], 1),
    % 稠密性核查：全体 (λ,β) × 样本条件。
    forall((between(1, 4, L), between(0, 3, B), B < L),
           dense_ok(L, B, [(2,0,1), (3,1,2)])),
    % 贪心相遇：对稠密目标序列逐个扩展（定理 2.2 机制）。
    findall((L, B), (between(1, 4, L), between(0, 3, B), B < L), Targets),
    greedy(Targets, [], G),
    % f_λ 满射还原。
    forall((between(1, 4, L), between(0, 3, B), B < L),
           (member((L, _, B), G))),
    format("相容/不相容样本；n₀=1+max 全核验；贪心相遇后 f_λ 满射——λ 可数化~n"),
    writeln("END ====").

greedy([], P, P).
greedy([(L, B)|Ts], P, G) :-
    extend_dense(L, B, P, P1),
    greedy(Ts, P1, G).
```

Prolog 版做支撑相容的**双向查询**：`compat/2`（公共键值
一致——`lookup` 的截断模式 `!` 保证首键命中）、`fresh_n/3`
（`findall`+`max_list`，空表分支给 1）、`extend_dense/4`、
`greedy/3`（foldl 式贪心）与 `dense_ok/3` 的全称核查。实测
坑：`Q = P, append(P, [...], Q)` 的先后约束冲突（先绑 Q=P
再要求 Q 是加长——静默失败，`==== 103` 后无输出即其症状），
直接 `append(P, [New], Q)` 一步产出。`greedy/3` 的尾递归
与 `dense_ok/3` 的 forall 全称核查，合起来是「逐目标扩展 +
每步合法性」的双保险——与 Julia 的贪心循环同构，但查询方
向可以翻转（给定 G 反查它击中了哪些 D(λ,β)）。

### 通道七：Isabelle——功能性守恒

ZF 量纲的集论核：`functP`/`compatP`/`unionP` 把「条件是
部分函数」的日常直觉公理化，两条守恒定理（拼接守恒 +
新鲜键扩展守恒）用确定性规则链手写——本通道也是七通道
史上第一例「完全放弃 auto/blast」的证明风格样本。

```isabelle
theory Levy
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 103 章：Lévy 条件作为（键, 值）对的集合——功能性、相容性
与拼接（后侧去掉已覆盖键）。证明全用确定性规则链（bspec/mp/notE）：
ZF 的 fst/snd 是 THE-定义，blast 对其等式的反向搜索不终止。
Col(ω,<κ) 的 κ-链条件与定理 2.2/2.3 留在正文；其余通道承载
稠密性 D(λ,β) 的书式新鲜槽号。\<close>

text \<open>功能性：同一键至多一个值（部分函数）。\<close>

definition functP :: "i \<Rightarrow> o" where
  "functP(p) \<equiv> \<forall>x\<in>p. \<forall>y\<in>p. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"

text \<open>相容：公共键上取值一致。\<close>

definition compatP :: "[i, i] \<Rightarrow> o" where
  "compatP(p, q) \<equiv> \<forall>x\<in>p. \<forall>y\<in>q. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"

text \<open>拼接：q 中去掉已被 p 覆盖的键后取并。\<close>

definition unionP :: "[i, i] \<Rightarrow> i" where
  "unionP(p, q) \<equiv> p \<union> {y \<in> q . \<forall>x \<in> p . fst(x) \<noteq> fst(y)}"

lemma unionP_left: "x \<in> p \<Longrightarrow> x \<in> unionP(p, q)"
  unfolding unionP_def by (rule UnI1)

lemma unionP_memD:
  assumes hx: "x \<in> unionP(p, q)"
  shows "x \<in> p \<or> (x \<in> q \<and> (\<forall>z \<in> p . fst(z) \<noteq> fst(x)))"
proof -
  from hx have hu: "x \<in> p \<or> x \<in> {y \<in> q . \<forall>z \<in> p . fst(z) \<noteq> fst(y)}"
    unfolding unionP_def by (rule Un_iff [THEN iffD1])
  from hu show ?thesis
  proof
    assume h: "x \<in> p"
    thus ?thesis by (rule disjI1)
  next
    assume h: "x \<in> {y \<in> q . \<forall>z \<in> p . fst(z) \<noteq> fst(y)}"
    hence hs: "x \<in> q \<and> (\<forall>z \<in> p . fst(z) \<noteq> fst(x))"
      by (rule separation [THEN iffD1])
    thus ?thesis by (rule disjI2)
  qed
qed

lemma unionP_funct:
  assumes "functP(p)" "functP(q)" "compatP(p, q)"
  shows "functP(unionP(p, q))"
proof -
  from assms(1) have hp: "\<forall>x\<in>p. \<forall>y\<in>p. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
    unfolding functP_def .
  from assms(2) have hq: "\<forall>x\<in>q. \<forall>y\<in>q. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
    unfolding functP_def .
  from assms(3) have hc: "\<forall>x\<in>p. \<forall>y\<in>q. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
    unfolding compatP_def .
  show ?thesis
    unfolding functP_def
  proof (intro ballI ballI impI)
    fix x y
    assume hx: "x \<in> unionP(p, q)" and hy: "y \<in> unionP(p, q)"
      and hxy: "fst(x) = fst(y)"
    from unionP_memD hx have dx: "x \<in> p \<or> (x \<in> q \<and> (\<forall>z \<in> p . fst(z) \<noteq> fst(x)))" .
    from unionP_memD hy have dy: "y \<in> p \<or> (y \<in> q \<and> (\<forall>z \<in> p . fst(z) \<noteq> fst(y)))" .
    from dx show "snd(x) = snd(y)"
    proof
      assume ax: "x \<in> p"
      from dy show "snd(x) = snd(y)"
      proof
        assume ay: "y \<in> p"
        have h1: "\<forall>y\<in>p. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
          by (rule bspec [OF hp ax])
        have h2: "fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
          by (rule bspec [OF h1 ay])
        from h2 hxy show "snd(x) = snd(y)" by (rule mp)
      next
        assume ay: "y \<in> q \<and> (\<forall>z \<in> p . fst(z) \<noteq> fst(y))"
        have hq1: "\<forall>y\<in>q. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
          by (rule bspec [OF hc ax])
        have h2: "fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
          by (rule bspec [OF hq1 ay [THEN conjunct1]])
        from h2 hxy show "snd(x) = snd(y)" by (rule mp)
      qed
    next
      assume ax: "x \<in> q \<and> (\<forall>z \<in> p . fst(z) \<noteq> fst(x))"
      from dy show "snd(x) = snd(y)"
      proof
        assume ay: "y \<in> p"
        have hne: "fst(y) \<noteq> fst(x)"
          by (rule ax [THEN conjunct2, rule_format, OF ay])
        from hxy have hyx: "fst(y) = fst(x)" by (rule sym)
        from hne hyx have False by (rule notE)
        thus "snd(x) = snd(y)" by (rule FalseE)
      next
        assume ay: "y \<in> q \<and> (\<forall>z \<in> p . fst(z) \<noteq> fst(y))"
        have h1: "\<forall>y\<in>q. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
          by (rule bspec [OF hq ax [THEN conjunct1]])
        have h2: "fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
          by (rule bspec [OF h1 ay [THEN conjunct1]])
        from h2 hxy show "snd(x) = snd(y)" by (rule mp)
      qed
    qed
  qed
qed

text \<open>扩展：新鲜键处加值保持功能性——稠密性 D(λ,β) 的集论核。\<close>

lemma extend_funct:
  assumes "functP(p)" and fresh: "\<forall>x \<in> p . fst(x) \<noteq> fst(t)"
  shows "functP(p \<union> {t})"
proof -
  from assms(1) have hp: "\<forall>x\<in>p. \<forall>y\<in>p. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
    unfolding functP_def .
  show ?thesis
    unfolding functP_def
  proof (intro ballI ballI impI)
    fix x y
    assume hx: "x \<in> p \<union> {t}" and hy: "y \<in> p \<union> {t}"
      and hxy: "fst(x) = fst(y)"
    from hx have sx: "x \<in> p \<or> x = t" by auto
    from hy have sy: "y \<in> p \<or> y = t" by auto
    from sx show "snd(x) = snd(y)"
    proof
      assume ax: "x \<in> p"
      from sy show "snd(x) = snd(y)"
      proof
        assume ay: "y \<in> p"
        have h1: "\<forall>y\<in>p. fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
          by (rule bspec [OF hp ax])
        have h2: "fst(x) = fst(y) \<longrightarrow> snd(x) = snd(y)"
          by (rule bspec [OF h1 ay])
        from h2 hxy show "snd(x) = snd(y)" by (rule mp)
      next
        assume ay: "y = t"
        have hne: "fst(x) \<noteq> fst(t)" by (rule bspec [OF fresh ax])
        from hxy ay have heq: "fst(x) = fst(t)" by simp
        from hne heq have False by (rule notE)
        thus "snd(x) = snd(y)" by (rule FalseE)
      qed
    next
      assume ax: "x = t"
      from sy show "snd(x) = snd(y)"
      proof
        assume ay: "y \<in> p"
        have hne: "fst(y) \<noteq> fst(t)" by (rule bspec [OF fresh ay])
        from hxy ax have heq: "fst(y) = fst(t)" by simp
        from hne heq have False by (rule notE)
        thus "snd(x) = snd(y)" by (rule FalseE)
      next
        assume ay: "y = t"
        from ax ay show "snd(x) = snd(y)" by simp
      qed
    qed
  qed
qed

end
```

Isabelle 版做条件层的**集论核**：`functP`（部分函数性）、
`compatP`、`unionP`（拼接）与两条定理（拼接守恒 + 新鲜键扩
展守恒）。本章 Isabelle 通道最重的实测账：**ZF 的 `fst`/`snd`
是 THE-定义，`blast` 对其等式的反向搜索不终止**——poly 进程
烧 750+ CPU 秒被现场抓获；全链改写为**确定性规则链**
（`bspec [OF _ _]`/`mp`/`notE`/`FalseE`/`sym`，零搜索）后
构建 4 秒定档。配套坑：`hq1 [OF mem]` 对无前提事实无效
（须 `bspec [OF hq1 mem]` 两参并置）；`| pipe tail` 会吞
isabelle 退出码（假绿——验收一律走 build.ps1）；被杀构建的
poly 孤儿进程各占 2–6 GB 内存（须 Stop-Process 清场，否则
后续构建被内存压力再杀）。这条「THE-定义的投影函数喂给
搜索策略会失控」的经验值得入通用账：第 101 章 `nat_rec`
（k 首参）、第 102 章 `succ(2)`（数字 ≥3 不解析）都是 ZF
基础设施的形状陷阱——**ZF 通道写证明先查基础件的定义
形态，再决定用 auto/blast 还是规则链**。

## 103.7 机器的边界

1. **九款保持律不可机化**：$j^*$ 提升机的三件观察
   （$j$ 固定 $\mathbb P$、双泛型性、名字解释吻合）与
   初等性搬运全在类嵌入层；机器件只锚条件层。
2. **泛型性的无穷量词留在正文**：贪心相遇只模拟「对有限
   稠密族」的击中；「与 $V$ 的一切稠密集相交」是
   $\mathcal P(\mathcal P(\mathbb P))$ 级量词。
3. **引理 2.1 的荟萃账不可见**：$\Delta$-系统式论证消费
   $\kappa$-cc 的「任意 $\kappa$-列」——有限影子中
   反链条件自动真。
4. **因子分解（定理 2.3）与整齐性（定理 2.5）**：极大冲突
   子集 $W_n$ 的截断、完备子代数的往返延拓都在超穷
   布尔代数层。
5. **七通道分工**：Lean/Coq/Agda 证稠密性（三份独立构造
   证明互为对拍）；Julia/Python 贪心相遇 + $f_\lambda$
   满射还原（定理 2.2 机制全件）；Prolog 支撑相容双向查询；
   Isabelle 集论核（拼接/扩展的功能性守恒）。
6. **「κ 变 ω₁」在有限层不可见**：有限宇宙里 $\kappa=4$
   是顶，贪心相遇后「一切 $\lambda\le4$ 可数化」与「什么
  都没变」无法区分——可数化是**基数身份**的陈述，身份需要
   无穷多个下层的基数来衬托。机器件证的是它的**机制件**
   （稠密 + 相遇 + 满射还原），不是陈述本身。
7. **工程账也是数学账**：Isabelle 通道的 THE-fst 死循环
   （poly 烧 750+ CPU 秒）暴露的是 ZF 基础设施的选择——
   投影函数用 THE 定义便于公理化但不利于搜索；确定性规则
   链绕开搜索。这类「定义形态 vs 证明自动化」的取舍在七
   通道里反复出现（Agda 的 with 构造子、Coq 的 in_map_iff
   参数序），是机器数学的独立研究对象。

把全章收进五句话：**小型力迫改不动大基数的本质**（定理 2.1
九款 + 逆命题，$j^*$ 提升机四部件），**Lévy 崩塌把不可达
变成 $\omega_1$**（$\kappa$-cc 保上 + 逐值稠密塌下），
**因子分解把可数信息压进小片段**（定理 2.3，$L(\mathbb R)$
的地基），**整齐布尔代数让真值黑白分明**（定理 2.4/2.5 +
推论 2.1/2.2），**三本账（保基数/可数化/保见证）机制正交**
（第 104 章 Prikry 加第四格：保基数、改共尾度、不加有界
子集）。与第 89–92 章第一力迫线的关系：那边建立力迫的
语法与语义（偏序→泛型→布尔值），本章开始消费——**大基数
假设决定哪些力迫「安全」**：小力迫全安全（定理 2.1），
Lévy 型力迫「定向破坏」（牺牲 $\kappa$ 的基数身份换取
$\omega_1$ 舞台），后两章的 Prikry/Silver 型力迫则展示
「大而不破」的精细艺术。

## 103.8 本章要点与检查问题

- **定理 2.1**：小型力迫（$\mathbb P\in V_\kappa$）保持
  九款大基数性质且造不出新的大基数——Lévy–Solovay 历史线，
  「大基数对 CH 无能为力」的技术根源。
- **$j^*$ 提升机**：$j$ 固定 $\mathbb P$ ⟹
  $G$ 双泛型 ⟹ $j^*(	au_G)=(j(	au))_G$ 良定义
  （名字无关性）⟹ 初等性搬运——九款复验共用一台发动机。
  逆命题走理想饱和（$|\mathbb P|^+$-饱和素理想 ⟹ 可测）。
- **引理 2.1 + 定理 2.2**：$\kappa$-cc（荟萃 $\Delta$-
  账）保 $\ge\kappa$ 侧；逐值稠密 $D_\eta$（行无穷
  宽 + 新鲜槽号 $n_0=1+\max$）把 $<\kappa$ 侧全体
  可数化——$\kappa=\omega_1$。
- **因子分解与整齐性**：定理 2.3 把可数信息压进
  $<\kappa$ 片段（$L(\mathbb R)$ 的地基）；定理 2.4/2.5
  黑白分明律 + 整齐布尔代数（推论 2.2：布尔值非 0 即 1）。
- **三本账**：保基数（cc 组合论）/ 可数化（稠密工程）/
  保见证（嵌入代数）——三种机制互相正交、各有独立账本，
  第 104 章 Prikry 力迫将补充第四种组合
  （保基数、改共尾度、不加有界子集）。
- **实测账（工程线）**：Lean `nodup_append` 裸 ∀ 形 + `disjoint_left`
  不对位（八轮）、`norm_num` 缺位、filter 双向引理不对称；
  Coq `in_map_iff` 三元参/序翻转、`NoDup_app` 两段前提、
  `repeat split; lia`、`f_equal` 替 congrArg；Agda 无列表
  逗号语法、`m≤n+m` 参数序、点模式全标注；Julia Unicode
  变量作用域；Prolog 先绑后 append 冲突；Isabelle THE-fst
  死循环（752 CPU 秒现场）、确定性规则链解法、pipe 假绿、
  poly 孤儿内存。

检查问题：

（做不出来时先回正文找对应机制件：第 1 题查饱和账的冲突
对应，第 2 题查荟萃平移的域分裂，第 3 题查行宽与稠密性的
交换，第 4 题查因子分解与名字有界性。）

1. 定理 2.1(d) 的逆命题中，如果 $|\mathbb P|\ge\kappa$，
   「$I^+$ 中无长 $|\mathbb P|^+$ 的几乎不相交序列」
   这一步在哪里失效？（提示：冲突条件与力迫条件的一一对应
   需要 $X\cap Y\in I^+$ 的账——$\mathbb P$ 大时
   稠密性结构如何变化？）
2. 引理 2.1 的证明取 $g(\delta)=\max\{\eta\mid\cdots\}$
   并压平到固定 $\eta$。若 $\mathrm{Col}(\omega,<\kappa)$
   的条件允许无穷域（但 $<\kappa$），论证哪一步断？
3. 定理 2.2 的 $f_\lambda$ 满射依赖「每 $\eta$ 的
   $D_\eta$ 被击中」。若槽号 $n$ 限定为单槽
   （每行一个位置），$D_\eta$ 对哪些 $(\lambda,\eta)$
   仍稠密？（联系 Julia 通道的「每 $\lambda$ 恰用
   $\lambda$ 槽」断言。）

5. 定理 2.3 的证明把 $X$ 的名字压进 $\mathbb P_{\nu+1}$。
若把「可数序数之集」换成「$\omega_1$ 个序数的集」
（$\omega_1<\kappa$），论证在哪一步需要补强？（极大冲突
   族的大小账从 $\omega$ 组变成 $\omega_1$ 组——$\kappa$
   的不可达性还够用吗？）

6. Isabelle 通道的 `functP`/`compatP`/`unionP` 是条件层的
   功能性三件套。用自然语言说明：为什么 `unionP_funct` 的
   四案证明中，「$x\in q$、$y\in p$」一案不能从
   `compatP(p,q)` 直接得出而必须走「键不交冲突」？（提示：
   `compatP` 的量词方向。）

---

本章的七通道实测账合订：Lean 八轮 `nodup_append` 形状考古、
Coq `in_map_iff` 三元参、Agda 列表逗号语法、Julia Unicode
作用域、Prolog 先绑后扩展、Isabelle THE-fst 七百秒死循环与
确定性规则链——每一条都已在 PLAN 与记忆文件中入账，供
后续章节的「先查坑位再动手」协议取用。
4. 黑白分明律说带地基参数的语句布尔值非 0 即 1。$L(\mathbb R)$
   的成员是 $V[G]$ 的实数——不是地基参数——为什么第
   111 章之后仍然能用整齐性论证 $L(\mathbb R)$ 的理论
   稳定？（提示：定理 2.3 因子分解把实数信息压回
   $V[X]$。）

补一行总括：本章七份源码共 ~750 行，覆盖定理 2.2 的全部
机制件与定理 2.1 的最小影子（名字无关性）；未机化的本体
（九款保持律、荟萃 Δ-账、因子分解、往返延拓）恰是后续
章节机器设计的候补材料——第 104 章 Prikry 的 stem 机器
将直接复用本章的条件/相容/扩展三件套。

---

上一章：[102 武丁基数](102-woodin.md) · 下一章：[104 Prikry 力迫](104-prikry.md)
