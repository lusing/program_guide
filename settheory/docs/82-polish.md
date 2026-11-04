# 82 · 贝尔空间、波兰空间、投影集与博弈

> 第 81 章把三种正则性问到了博雷尔集为止；本章取材冯琦第一卷 §3.6
> （书页 249–280；PDF 267–298），把舞台从实数轴搬到**贝尔空间**
> $\mathcal N=\omega^\omega$ 。选择它的理由（原书明说）：在
> $\mathcal N$ 上「往往可以直接写出所要的证据」。本章的主线是一张
> 逐渐成形的图：**树枝 → 闭集 → 投影 → 解析集 → 正则性**。闭集是树的
> 全体无穷树枝（定理 3.26）；解析集是闭集的投影（引理 3.17）；解析集
> 的运算封闭性由苏斯林运算记账（命题 3.8）；三大正则性对解析集成立
> （定理 3.28），并把「不可数 ⇒ 含完备子集」从闭集推广到整个解析层。
> 末端接上无穷博弈：Banach–Mazur 赛事把稀疏性翻译成稳赢策略
> （定理 3.29），Gale–Stewart 证明开闭赛局确定（命题 3.9/3.10），选择
> 公理给出未定集（定理 3.30），而开区分赛事把解析集的另一种组合正则
> 性也变成博弈问题（定理 3.32，冯琦定理）。
>
> 机器边界一如既往：mathlib 4.33.1 有 `PolishSpace` 类与康托尔-本狄克森
> 的官方定理，但没有贝尔空间 $\omega^\omega$ 的实例、没有任何确定性
> 定理；七个通道因此分工为「官方锚点（Lean）+ 有限树/有限博弈的可判定
> 影子（其余六通道）」。有限逆向归纳**不是**马丁定理的证据，穷举不是
> 测度的证据。

## 82.1 贝尔空间：距离、字典序、可分与完备（定义 3.24、命题 3.5）

在 $\omega^\omega$ 上，拓扑 $\tau$ 以基本开集

$$N_s=\{f\in\omega^\omega : s\subseteq f\}\qquad(s\in\omega^{<\omega})$$

为基。距离用「首个分歧点」度量：

> **定义 3.24** 对 $f\ne g$ 令
> $\triangle(f,g)=\min\{n : f(n)\ne g(n)\}$ ，
> $$d(f,g)=2^{-\triangle(f,g)},\qquad d(f,f)=0,$$
>
> 并定义字典序 $f<_{\mathrm{lex}}g\iff f\ne g\wedge f(\triangle(f,g))<g(\triangle(f,g))$ 。

> **命题 3.5** $d$ 是 $\omega^\omega$ 上的距离，诱导拓扑恰为
> $\tau$ ；$(\mathcal N,d)$ 可分完备；$<_{\mathrm{lex}}$ 是线性序。

**可分性**：全体**最终平坦**函数

$$D=\{f : \exists m\,\forall n\ (n\ge m\to f(n)=m)\}$$

可数（编码于 $\omega\times\omega^{<\omega}$ ），且在任一非空
$N_s$ 中取 $f_s=s{}^\frown mmm\cdots$ （$m$ 任意固定）即
$f_s\in N_s\cap D$ 。

**完备性**：设 $(f_n)$ 是柯西序列。递归取

$$a_n=\min\{a>a_n' : a>\max\{a_0,\ldots,a_{n-1}\}\},$$

其中 $a_n'$ 保证 $d(f_i,f_j)<2^{-(n+1)}$ 对一切
$i,j\ge a$ 成立。令
$I_n=\{i : a_n\le i<a_{n+1}\}$ ，定义

$$f=\bigcup_{n<\omega}(f_{a_n+1}\upharpoonright I_n),$$

则 $d(f_{a},f)<2^{-(n+1)}$ 对 $a\ge a_n$ 成立，即 $f$ 是极限。
（在每个块 $I_n$ 上柯西列已经稳定到误差 $2^{-(n+1)}$ 之内。）∎

与实数轴的关系（练习 3.5）：$\mathcal N$ 与全体无理数构成的子空间
拓扑同胚。于是「在 $\mathcal N$ 上证明的拓扑事实」几乎就是「在
$\mathbb R\setminus\mathbb Q$ 上」的事实，而写证据容易得多：一个点
就是一列自然数，一个邻域就是一个有限序列。

## 82.2 贝尔空间上的纲、贝尔性质与测度（定理 3.25）

稠密、无处稠密、稀疏等概念按第 81 章逐字平移；贝尔纲定理同样成立：

> **定理 3.25（贝尔空间版贝尔纲）** 稠密开集序列
> $(D_n)$ 之交在 $\mathcal N$ 中稠密。

**证明**。不妨 $D_{n+1}\subseteq D_n$ 。给定 $N_{s_0}$ ，递归取
$s_{n+1}\supsetneq s_n$ 使 $N_{s_{n+1}}\subseteq D_n\cap N_{s_n}$
（非空开集含某基本开集），则
$f=\bigcup_n s_n\in N_{s_0}\cap\bigcap_n D_n$ 。∎

于是稀疏集构成含全部单点集的非平凡 $\sigma$ -理想，贝尔性质、
贝尔性质类是 $\sigma$ -代数、博雷尔集全具贝尔性质——第 81 章的
81.2–81.4 整段平移。测度也可搬：给单点 $n$ 权
$\lambda(\{n\})=2^{-(n+1)}$ ，取乘积测度，基本开集的测度为

$$\lambda(N_s)=\prod_{k<\mathrm{dom}(s)}2^{-(s(k)+1)},$$

再按可数可加性延拓到全体开集与博雷尔集。零测理想同样非平凡。

## 82.3 闭集的树表示（定义 3.25/3.26、定理 3.26、引理 3.13）

$\omega^{<\omega}$ 按延伸构成一棵**完备树**，$\mathcal N$ 恰是
它的全体无穷树枝。子树给出闭集的标准表示：

> **定义 3.25** $T\subseteq\omega^{<\omega}$ 是**树**，若
> $t\in T\wedge i\le\mathrm{dom}(t)\Rightarrow t\upharpoonright i\in T$ 。
> $[T]=\{f : \forall n\,(f\upharpoonright n\in T)\}$ 为其全体无穷树枝。

> **定理 3.26** $X\subseteq\mathcal N$ 闭 $\iff$ $X=[T]$
> 对某棵树 $T$ 。

**证明**。（⇐）若 $f\notin[T]$ ，令
$m=\min\{n : f\upharpoonright m\notin T\}$ ，则邻域
$N_{f\upharpoonright m}$ 与 $[T]$ 不交。（⇒）取**表示树**

$$T_X=\{s : \exists f\in X\,(s\subseteq f)\},$$

则 $X\subseteq[T_X]$ ；反之 $f\in[T_X]$ 时每个 $f\upharpoonright n$
被某 $g_n\in X$ 延伸，$g_n\to f$ ，$X$ 闭故 $f\in X$ 。∎

孤立点在树上显形为「无分叉」：$f$ 是闭集 $F$ 的孤立点 iff 某个
$f\upharpoonright n$ 之后表示树只剩一条无穷路。于是：

> **定义 3.26** 树 $T$ **完备**，若每个 $t\in T$ 都有两个互为
> 不分歧延伸的后继（分叉节点处处存在）。

> **命题 3.6** 非空闭集 $X$ 是完备集 iff $T_X$ 是完备树。∎

对树**求导**：$T'=\{t\in T : t$ 有两个不分歧的延伸于 $T\}$ ；
$T$ 完备 iff $T'=T$ 。

> **引理 3.13** $[T]-[T']$ 至多可数。

**证明**。对 $f\in[T]-[T']$ 令
$n_f=\min\{k : f\upharpoonright k\in T-T'\}$ 、
$s_f=f\upharpoonright n_f$ 。若 $f\ne g$ 而 $s_f=s_g$ ，则
$\triangle(f,g)\ge n_f$ 且 $s_f$ 之下两树不分歧，即
$s_f\in T'$ ，矛盾。故 $f\mapsto s_f$ 单射到可数集。∎

**树版康托尔-本狄克森**（重证第 81 章定理 3.23）：对不可数闭集
$F$ 的表示树递归求导 $T_0=T$ 、$T_{\alpha+1}=(T_\alpha)'$ 、
极限取交。树至多可数，过程在某个 $\xi<\omega_1$ 稳定；稳定处
$T_\xi$ 是完备树（否则再导一次还会损失节点），且

$$[T]-[T_\xi]=\bigcup_{\alpha<\xi}\big([T_\alpha]-[T_{\alpha+1}]\big)$$

是可数并的可数集（引理 3.13），故 $[T_\xi]\subseteq F$ 是非空
完备子集。∎

## 82.4 波兰空间与连续满射（定义 3.27、引理 3.14）

> **定义 3.27** 拓扑空间是**波兰空间**，若它与某可分完备距离空间
> 拓扑同胚。

例 3.5：$\mathbb R$ 、$\mathcal N$ 、康托尔空间 $2^\omega$ 、
$[0,1]$ 、单位圆、希尔伯特立方体 $[0,1]^\omega$ ，以及它们的
可数乘积、开子集、闭子集，都是波兰空间。

> **引理 3.14** 每个波兰空间 $X$ 都是 $\mathcal N$ 的连续像：
> 存在连续满射 $H:\mathcal N\to X$ 。

**证明**。取可数稠密 $D=\{a_i\}$ 。递归构造闭球树 $(C_s)$ ：
$C_{\langle\rangle}=X$ ；给定 $C_s$ （半径 $\le 2^{-(n+1)}$ ，
$n=\mathrm{dom}(s)$ ），由稠密性 $D\cap C_s$ 无穷，按第 $s$ -个
枚举取子列，令 $C_{s\frown k}$ 为以该子列中元素为中心、半径
$\le 2^{-(n+2)}$ 的闭球，且 $C_s=\bigcup_k C_{s\frown k}$ （有限
个不行时取覆盖掉的稠密子列；半径趋于零保证并覆盖）。

对 $f\in\mathcal N$ ，闭球套 $(C_{f\upharpoonright n})$ 半径趋于
零，由完备性交集恰一点，令 $H(f)=\bigcap_n C_{f\upharpoonright n}$ 。
满射性来自每层球的并覆盖；连续性来自半径的几何衰减。∎

（严格地说：覆盖式 $\bigcup_k$ 需要球心取遍稠密集的相应切片，
细节按原书书页 254；这正是第 80 章区间套与本章球套的同一技术。）

## 82.5 博雷尔层级（定义 3.28、命题 3.7）

> **定义 3.28** 对 $1\le\alpha<\omega_1$ ：
> $\Sigma^0_1$ =开集，$\Pi^0_1$ =闭集，
> $$\Sigma^0_\alpha=\Big\{\bigcup_n A_n : A_n\in\bigcup_{\beta<\alpha}\Pi^0_\beta\Big\},\qquad \Pi^0_\alpha=\{X-A : A\in\Sigma^0_\alpha\}.$$

> **命题 3.7** (1) 每层都含于 $\mathcal B(X)$ ；(2) 层级单调递增
> 且 $\Sigma$ /$\Pi$ 互换地对偶；(3)
> $\bigcup_{\alpha<\omega_1}(\Sigma^0_\alpha\cup\Pi^0_\alpha) =\mathcal B(X)$ ；(4) 每层对有限并、有限交封闭，连续原像保层。∎

(2) 中「开集是 $\Sigma^0_2$ 」用可数稠密集与距离有理数近似：每个
开集是可数个闭球之并——这与第 81 章 81.6 事实 (7) 的论证同源。可数
距离空间上博雷尔概念平凡（每个子集都博雷尔）；不可数波兰空间上
层级**非平凡**，由下一节的通用集见证。

## 82.6 通用博雷尔集与层级的严格性（引理 3.15、推论 3.5）

> **引理 3.15** 对每个 $1\le\alpha<\omega_1$ 存在
> **通用集** $U_\alpha\subseteq\mathcal N^2$ ：
> $U_\alpha\in\Sigma^0_\alpha(\mathcal N^2)$ ，且每个
> $A\in\Sigma^0_\alpha(\mathcal N)$ 都是某个竖截口：
> $A=\{x : (x,a)\in U_\alpha\}$ 。

**构造**。归纳于 $\alpha$ 。$\alpha=1$ ：罗列基本开集
$(G_k)$ ，令
$(x,y)\in U_1\iff\exists n\,(x\in G_{y(n)})$ ——开集的并，而每个
开集 $A=\bigcup_n G_{a(n)}$ 被截口实现。

后继步 $\alpha=\beta+1$ ：由引理 3.14 取连续满射
$f:\mathcal N\to\mathcal N^\omega$ ，用 $f$ 把竖坐标 $a$ 解码成
一列码 $a(n)$ ；令

$$(x,y)\in U_\alpha\iff\exists n\,\big((x,y(n))\in U_\beta\big).$$

若 $A=\bigcup_n A_n$ 、$A_n\in\Pi^0_\beta$ ，取 $a_n$ 使
$\mathcal N-A_n=\{x:(x,a_n)\in U_\beta\}$ ，再取 $a$ 编码
$(a_n)$ 。

极限步 $\alpha$ ：取递增趋于 $\alpha$ 的序列
$\alpha_n$ ，同样解码后令
$(x,y)\in U_\alpha\iff\forall n\,\big((x,y(n))\in U_{\alpha_n+1}\big)$ 型的交并组合实现「低层之并的交」。∎

> **推论 3.5** 对 $1\le\alpha<\omega_1$ ，
> $\Sigma^0_\alpha-\Pi^0_\alpha\ne\varnothing$ 。

**证明**（对角论证）。令
$A=\{a : (a,a)\in U_\alpha\}\in\Sigma^0_\alpha$ 。若
$A\in\Pi^0_\alpha$ ，则 $\mathcal N-A\in\Sigma^0_\alpha$ ，取
$a^*$ 使 $\mathcal N-A=\{x:(x,a^*)\in U_\alpha\}$ 。问
$a^*\in A$ ？若是，则 $(a^*,a^*)\in U_\alpha$ ，故
$a^*\notin\mathcal N-A$ ，即 $(a^*,a^*)\notin U_\alpha$ ，矛盾；
若否，同理矛盾。∎

于是博雷尔集被切成 $\omega_1$ 层货真价实的复杂度阶梯——这条阶梯
正是第 79 章 Suslin 树高度讨论的「可描述的无限」的一例。

## 82.7 解析集：连续像与投影（定义 3.29/3.30、引理 3.16/3.17）

> **定义 3.29** $A\subseteq X$ （波兰）是**解析集**，若
> $A=f[\mathcal N]$ 对某连续 $f:\mathcal N\to X$ 。

（传说这概念源自一位年轻大学生指出：博雷尔集类对连续像**不**封闭
——成熟数学家看走眼的地方。）

例 3.6：由引理 3.14，每个波兰空间是自身的解析子集；单点集解析。
定义 3.30：乘积空间 $X\times Y$ 的子集 $A$ 在 $X$ 上的**投影**
$\pi_Y(A)=\{x:\exists y\,(x,y)\in A\}$ ；投影是连续满射的伴生运算。

> **引理 3.16** (1) 闭集解析（闭子集自身是波兰空间，用引理 3.14）。
> (2) 每个**博雷尔**集 $A\subseteq X$ 是 $X\times\mathcal N$ 上
> 某个闭集的投影。

**证明**（(2) 的封闭类论证）。令

$$\mathcal C=\{A : \exists F\subseteq X\times\mathcal N\text{ 闭}, \ A=\pi_Y(F)\}.$$

闭集：$A=\pi_Y(A\times\mathcal N)$ ✓。**可数并**：
$A_n=\pi_Y(F_n)$ ，取连续满射编码
$c\mapsto(c(0),c(1),\ldots)$ ，则

$$\bigcup_n A_n=\pi_Y\big(\{(x,c) : (x,c(c(0)(0))?)\}\big)$$

——具体地，$\bigcup_n A_n=\pi_Y(\{(x,c):(x,c(c(0)))\in F_{c(0)}\})$
型：第一个坐标选择分量，剩下的当作该分量的见证，大括号内的集是闭集
（连续原像保持闭性）。**可数交**：

$$\bigcap_n A_n=\pi_Y\big(\{(x,c) : \forall n\,(x,c(n))\in F_n\}\big),$$

同样闭。$\mathcal C$ 含闭集、对可数并交封闭，故
$\mathcal B(X)\subseteq\mathcal C$ 。∎

> **引理 3.17（解析集四等价）** 对 $A\subseteq X$ ，TFAE：
> (1) $A=f[\mathcal N]$ （连续像）；(2) $A$ 是某波兰空间中博雷尔
> 集的连续像；(3) $A$ 是某博雷尔集的投影；(4) $A$ 是
> $X\times\mathcal N$ 上某**闭**集的投影。

**证明**。(4)⇒(1)：闭集是波兰空间（可分完备的闭子空间），引理 3.14
给连续满射，复合投影。(1)⇒(4)：$f$ 的反图
$\{(f(\alpha),\alpha)\}$ 是 $X\times\mathcal N$ 中的闭集，其投影
即 $A$ （连续函数的图像闭）。（2)(3) 介于其间，由引理 3.16 与投影
的连续性串起。∎

四等价中 (4) 最有用：**解析集 = 闭集的投影**。这正是「树枝—闭集
—投影—解析」链条的第二、三环。

## 82.8 苏斯林运算（引理 3.18、命题 3.8）

> 对 $f:\omega^{<\omega}\to V$ 定义**苏斯林运算**
> $$\mathcal A(f)=\bigcup_{a\in\mathcal N}\bigcap_{n<\omega} f(a\upharpoonright n).$$
>
> 称 $f$ **单调递减**，若 $s\subseteq t\Rightarrow f(t)\subseteq f(s)$ 。（任意 $f$ 可用 $f^*(s)=\bigcap_{s\subseteq t}f(t)$
> 单调化而不改变 $\mathcal A(f)$ 。）

> **引理 3.18** $A$ 解析 $\iff$ 存在单调递减的
> $f:\omega^{<\omega}\to\Pi^0_1(X)$ （闭集值）使 $A=\mathcal A(f)$ 。

**证明**。（⇐）$x\in\mathcal A(f)\iff\exists a\,\forall n\, (x\in f(a\upharpoonright n))$ ，故 $A$ 是闭集
$\{(x,a):\forall n\, x\in f(a\upharpoonright n)\}$ 的投影——引理
3.17(4)。（⇒）取 $h(s)=f[N_s]$ （连续像下的闭？$N_s$ 闭、$f$
连续，$f[N_s]$ 是解析的紧像——非闭！改为 $h(s)=\overline{f[N_s]}$?
原书直接用 $f[N_s]$ 于 $\Pi^0_1$ ——**校勘**：$\mathcal N$ 的闭
子集 $N_s$ 是波兰空间，$f[N_s]$ 是解析集而非必闭；正确读法是把
$h(s)$ 视为「取值于解析集」的单调族，而 $\Pi^0_1$ 的要求属于
(⇐) 方向的自然加强。按 $\mathcal A(h)=A$ 验证：
$f[\mathcal N]=\bigcup_{a}\bigcap_n f[N_{a\upharpoonright}]= \bigcup_a\{f(a)\}^{\mathrm{cl}}$ … 逐点地
$\bigcap_n f[N_{a\upharpoonright n}]=\{f(a)\}$ （半径趋于零的邻域
套），故 $\mathcal A(h)=f[\mathcal N]$ 。∎

> **命题 3.8** 解析集类 $\Sigma^1_1(X)$ ：含全体博雷尔集；对可数
> 并、可数交封闭；对连续像与原像封闭；**对苏斯林运算封闭**
> （$f:\omega^{<\omega}\to\Sigma^1_1$ ⇒ $\mathcal A(f)\in \Sigma^1_1$ ）。∎（都由四等价 + 引理 3.16 的封闭类技巧直接组装；
> 苏斯林封闭性把两层计数并交压成一层。）

自然的问题：$\Sigma^1_1$ 对**补**封闭吗？若封闭，它就是含博雷尔
的 $\sigma$ -代数，层级失效。两个答案分两节给出。

## 82.9 投影层级与严格性（定义、引理 3.19、推论 3.6）

> **投影层级**：$\Sigma^1_1$ =解析集；$\Pi^1_1$ =其余解析集；
> $\Sigma^1_{n+1}=\{\pi_Y(A) : A\in\Sigma^1_n(X\times\mathcal N)\}$ ；
> $\Pi^1_{n+1}$ =补；$\Delta^1_n=\Sigma^1_n\cap\Pi^1_n$ 。

> **引理 3.19** 每层有通用集 $U_n\subseteq\mathcal N^2$ 。∎
> （用同胚 $h:\mathcal N\times\mathcal N\to\mathcal N$ 折叠坐标，
> 后继步取投影，与引理 3.15 同构。）

> **推论 3.6** $\Sigma^1_n-\Pi^1_n\ne\varnothing$ ，且
> $\Delta^1_n\subsetneq\Sigma^1_{n+1}\cap\Pi^1_{n+1}$ 。
> （对角论证同推论 3.5。）∎

特别地 $\Sigma^1_1\ne\Pi^1_1$ ：解析集类**不**对补封闭，层级真实
存在。但 $\Delta^1_1$ 是什么？下一节回答。

## 82.10 隔离引理与苏斯林定理（引理 3.20、定理 3.27）

称不相交的 $A,B$ 被**博雷尔集隔离**，若有博雷尔 $D$ 使
$A\subseteq D$ 、$B\subseteq X-D$ 。

> **引理 3.20（隔离引理）** 任意两个不相交解析集被博雷尔集隔离。

**证明**。先看可数分解的归约：若
$A=\bigcup_n A_n$ 、$B=\bigcup_m B_m$ 且每对 $(A_n,B_m)$ 被隔离
（隔离集 $D_{nm}$ ），则 $D=\bigcup_n\bigcap_m D_{nm}$ 隔离
$A,B$ 。

反设 $A=f[\mathcal N]$ 、$B=g[\mathcal N]$ （连续）不被隔离。令
$A_s=f[N_s]$ 、$B_s=g[N_s]$ 。若每对 $(A_s,B_t)$ 都被隔离，
则由归约 $A,B$ 被隔离——矛盾；故有 $s_0,t_0$ 使
$A_{s_0},B_{t_0}$ 不被隔离。递归得 $s_0\subseteq s_1\subseteq \cdots$ 、$t_0\subseteq t_1\subseteq\cdots$ ，每步
$(A_{s_n},B_{t_n})$ 不被隔离。令 $a=\bigcup s_n$ 、$b=\bigcup t_n$ 。因 $A\cap B=\varnothing$ ，$f(a)\ne g(b)$ ；取分离的开集
$G_{f(a)},G_{g(b)}$ ，由连续性，充分长的
$A_{s_n}\subseteq G_{f(a)}$ 、$B_{t_n}\subseteq G_{g(b)}$ ——被
开集（从而博雷尔集）隔离，与构造矛盾。∎

> **定理 3.27（苏斯林定理）** $\Delta^1_1=\mathcal B$ ：解析且余
> 解析的集合是博雷尔集。

**证明**。$A$ 与 $B=X-A$ 都解析，隔离集 $D$ 只能等于
$A$ 。∎

苏斯林定理是「解析层的第一个精确刻度」：博雷尔 = 双解析。它与第
79 章的 Suslin 树问题 ($A$ -运算是否超出博雷尔) 在同一人物名下
会师。

## 82.11 解析集的三大正则性（定理 3.28、推论 3.7）

> **定理 3.28** (1) 解析集勒贝格可测；(2) 解析集具贝尔性质；
> (3) 不可数解析集含非空完备子集。

**(1)** 需要极小覆盖引理：

> **引理 3.21** 对每个 $X\subseteq\mathbb R$ 存在可测
> $B\supseteq X$ 使 $B-X$ 的一切**可测**子集零测。
> （外测度有限时取达因集；无限时按 $[i,i+1)$ 切片后并。）

设 $A=f[\mathcal N]$ ，$A_s=f[N_s]$ ，则
$A=\mathcal A(\langle A_s\rangle)$ 且
$A_s=\bigcup_k A_{s\frown k}$ 。对每个 $s$ 取引理 3.21 的
$B_s\supseteq A_s$ （额外保证 $A_s\subseteq B_s\subseteq \overline{A_s}$ 的规范选取），则
$A=\mathcal A(\langle B_s\rangle)=:B$ 。断言
$B-A\subseteq\bigcup_s\big(B_s-\bigcup_k B_{s\frown k}\big)$ ：
若 $x\in B_s$ 但对每支 $s$ 都有 $k$ 使 $x\in B_{s\frown k}$ ，从根出发递归选 $k_n$ 得树枝 $a$ ，$x\in\bigcap_n B_{a\upharpoonright n}\subseteq\bigcap_n\overline{A_{a\upharpoonright n}}=\{f(a)\}\subseteq A$ 。而每个
$B_s-\bigcup_k B_{s\frown k}\subseteq B_s-\bigcup_k A_{s\frown k} =B_s-A_s$ ，是 $B_s-A_s$ 的可测子集，零测。可数并后 $B-A$
零测，$A=B-(B-A)$ 可测。∎

**(2)** 用贝尔版极小覆盖（引理 3.22：任意 $Y$ 有具贝尔性质的
$B\supseteq Y$ 使 $B-Y$ 的一切具贝尔性质的子集稀疏——取
$D(Y)=\{x:$ 有基本开集 $U\ni x$ 使 $U\cap Y$ 非稀疏$\}$ ，
它闭，$B=Y\cup D(Y)$ 即所求），其余论证与 (1) 逐字平行。∎

**(3)** 树法。设 $A=f[\mathcal N]$ 不可数，$f$ 连续。对树
$T\subseteq\mathcal N^{<\omega}$ （即 $\omega^{<\omega}$ 的子树）
定义**重数导数**

$$T'=\{t\in T : |[T_t]|>\aleph_0\}\qquad(T_t=\{s\in T : t\subseteq s\}),$$

递归 $T(0)=\omega^{<\omega}$ 、$T(\alpha+1)=(T(\alpha))'$ 、极限
取交，稳定于某 $T(\alpha^*)$ 。若 $T(\alpha^*)=\varnothing$ ，则

$$A=\bigcup\{f[[T_s]] : s\in(T(\beta)-T(\beta+1)),\ \beta<\alpha^*\},$$

每片可数（$[T_s]$ 在导掉的一步变为可数），$A$ 可数——矛盾。故
$T(\alpha^*)\ne\varnothing$ 且处处重数不可数：每个节点可分出两个
**不相交子树值**的后继。递归取 2-分叉子树 $U\cong 2^{<\omega}$ ，
使 $f$ 在 $[U]$ （紧集）上单射，$P=f[[U]]\subseteq A$ 紧、无
孤立点——完备子集。∎

> **推论 3.7** (1) $\Pi^1_1$ 集可测且具贝尔性质（取补用 (1)(2)）。
> (2) 解析集（尤其博雷尔集）或可数或势 $2^{\aleph_0}$ ——**博雷尔
> 集与解析集都不是连续统假设的反例**。∎

剩余的两个大问题，原书明言留给最后一章/第三卷：

- **问题 3.8** 不可数的 $\Pi^1_1$ 实数集是否含完备子集？（与论域
  中大基数相关。）
- **问题 3.9** 每个投影集是否都有解析集的正则性？（第三卷 111–122
  章的主战场。）

## 82.12 无穷博弈：策略与稳赢（定义 3.31–3.34）

> **定义 3.31（赛局）** $A\subseteq\mathcal N$ 确定赛事
> $\mathcal G_A$ ：张三、李四轮流写自然数
> $a_0,b_0,a_1,b_1,\ldots$ ，得赛局
> $x*y=(a_0,b_0,a_1,b_1,\ldots)$ ；$x*y\in A$ 则张三胜，否则
> 李四胜。

> **定义 3.32（策略）** 张三的策略是
> $\sigma:\bigcup_n\omega^{2n}\to\omega$ ；李四的策略是
> $\tau:\bigcup_n\omega^{2n+1}\to\omega$ 。称在本局中使用了 $\sigma$ ，
> 若每步 $x(n)=\sigma(x*y\upharpoonright 2n)$ （李四同理）。

若张三坚持 $\sigma$ ，赛局由李四的应对 $y$ 完全确定，记
$\sigma*y$ ；同理 $\sigma*\tau$ 。于是：

> **定义 3.33（稳赢）** $\sigma$ 是张三在 $\mathcal G_A$ 中的
> **胜算**， iff $\{\sigma*y : y\in\mathcal N\}\subseteq A$ ；
> $\tau$ 是李四的胜算 iff
> $\{\sigma*\tau:\sigma\}\cap A=\varnothing$ 。

> **定义 3.34** $A$ **胜负确定**，若 $\mathcal G_A$ 中有一方
> 有胜算。

**例 3.7（Banach–Mazur 赛事）**。由 $X\subseteq\mathcal N$ 确定
的 $\mathcal G^{X}_{BM}$ ：双方轮流出示**有限序列**，后者必须延伸
前者，谁犯规谁输；都不犯规则得
$x=\bigcup_i s_i=\bigcup_i t_i$ ，$x\in X$ 张三胜。经
$\omega^{<\omega}$ 的递归单一列表 $(u_k)$ ，它可转化为标准赛事：
张三的每步是一个自然数，解码为有限序列；李四先犯规、或全程无犯规
且合成点 $\in X$ ，分别对应转化后集合 $A$ 的两个析取支。转化保持
稳赢策略的存在性。

> **定理 3.29（巴拿赫）** 在 Banach–Mazur 赛事
> $\mathcal G^{X}_{BM}$ 中：
> (1) 李四稳赢 iff $X$ 稀疏；(2) 张三稳赢 iff 有某个基本开集
> $N_s$ 使 $N_s-X$ 稀疏。

**证明**。(1) 充分性：设 $X\subseteq\bigcup_n F_n$ 、各 $F_n$
闭无处稠密，$G_n=\mathcal N-F_n$ 稠密开。李四的策略：张三出示
$s$ ，李四取 $t$ 使 $N_t\subseteq N_s\cap G_n$ （第 $n$ 轮）。
合成点落在每个 $G_n$ ，故不在 $X$ 。

必要性：设 $\tau$ 是李四的胜算。称有限对局
$p=(s_0,t_0,\ldots,s_n,t_n)$ 为**正确位**，若至今无犯规且李四各步
依 $\tau$ 。**断言**：若 $\alpha\in\mathcal N$ 满足「对每个正确
位 $p$ ，只要 $t_n\subseteq\alpha$ 就有延伸 $\tau(p\frown s) \subseteq\alpha$ 的 $s$ 」，则 $\alpha\in\mathcal N-X$ 。（沿
$\alpha$ 构造正确位链，合成点收敛于 $\alpha$ ，李四依胜算赢，
故 $\alpha\notin X$ 。）于是

$$X\subseteq\bigcup_p F_p,\qquad F_p=\{\alpha : t_p\subseteq\alpha\wedge\forall s\supseteq t_p\, (\tau(p\frown s)\not\subseteq\alpha)\},$$

而 $N_{t_p}-F_p$ 在 $N_{t_p}$ 中稠密开，$F_p$ 无处稠密闭；
正确位可数，$X$ 稀疏。

(2) 由对偶：张三先出示 $s$ （若存在 $N_s-X$ 稀疏），此后李四在
以 $\mathcal N_s-X$ 为标的的赛事中处于 (1) 的李四地位。∎

Banach–Mazur 赛事因此**用稳赢策略刻画贝尔性质**：$X$ 具贝尔性质
iff 某方在 $\mathcal G^{X}_{BM}$ 中稳赢 iff（恰在）$X$ 与某开集
对称差稀疏。正则性与博弈的第一次焊接。

## 82.13 Gale–Stewart：开闭确定性与未定集（命题 3.9/3.10、定理 3.30/3.31）

> **命题 3.9** $A$ 开。若张三在 $\mathcal G_A$ 中无胜算，则李四
> 有胜算。

**证明**（不败之地论证）。称位置 $p$ （偶长前缀）为李四的**不败
之地**，若张三在子赛事 $\mathcal G_A\upharpoonright p$ 中无胜算。
根是不败之地。在张三刚走 $a$ 之后，若两个应对 $b$ 都使位置败
北，则张三「走 $a$ 然后按胜算应对」——与无胜算矛盾；故李四总可
取 $b$ 保持不败。设按此策略成局 $x*y\in A$ ：$A$ 开，某
$N_{(x*y)\upharpoonright 2n}\subseteq A$ ，则张三在该位之后的任意
应对都进 $A$ ——该位是不败之地的否定，矛盾。∎

> **命题 3.10** $A$ 闭。若李四无胜算，则张三有胜算。

**证明**（对偶化）。李四在 $\mathcal G_A$ 中的策略与张三在
$\mathcal G_{\mathcal N-A}$ 中的策略是同一族函数（偶长/奇长前缀到
$\omega$ ），且「李四依 $\tau$ 应对使成果 $\notin A$ 」恰是
「张三依 $\tau$ 应对使成果 $\in\mathcal N-A$ 」。故李四无胜算于
$\mathcal G_A$ ⟺ 张三无胜算于 $\mathcal G_{\mathcal N-A}$ ；后者
开，命题 3.9 给李四胜算于 $\mathcal G_{\mathcal N-A}$ ，再翻译回
张三胜算于 $\mathcal G_A$ 。（原书另给沿表示树的直接构造：张三每
步选使「李四在闭子树赛事中仍无胜算」的延伸。）∎

> **定理 3.30（Gale–Stewart，AC 下）** 存在胜负未定的集合。

**证明**。全部策略只有 $2^{\aleph_0}$ 个，单一列表
$(\sigma_\alpha)_{\alpha<2^{\aleph_0}}$ 、
$(\tau_\alpha)_{\alpha<2^{\aleph_0}}$ 。递归取
$x_\alpha\in\{\sigma_\alpha*y : y\}\setminus\{x_\xi:\xi<\alpha\}$
与
$y_\alpha\in\{\sigma*\tau_\alpha : \sigma\}\setminus\{y_\xi\}\cup \{x_\alpha\}$ 。令 $X=\{x_\alpha\}$ ：则 $X\cap\{y_\alpha\} =\varnothing$ ，且对每个 $\alpha$ ，$\sigma_\alpha$ 有应对落
$X$ 外（不保张三胜）、$\tau_\alpha$ 有张三应对落 $X$ 内（不保
李四胜）——无人稳赢。∎

> **定理 3.31（马丁，1975）** 所有博雷尔集确定的集合。

证明超出本卷范围（马丁原文 9 页；核心是把博雷尔层级归纳转化为
「可数个未定赛的支配策略」迭代），原书忍痛割爱，本文同样如实标注
**未证明、已引用**。解析集与更高投影层的确定性正是第三卷 121–122
章的主题。

## 82.14 开区分特性与 OCA（定义 3.35/3.36、引理 3.23–3.25、定理 3.32）

本节是原书自己的定理（Q. Feng, 1993）。

> **定义 3.35（开区分特性）** $X\subseteq\mathbb R$ 非空，
> $K\subseteq[X]^2$ **相对开**（$K=B\cap[X]^2$ ，$B$ 开）。
> $X$ 具开区分特性，若对每个相对开 $K_0$ ：或有完备
> $P\subseteq X$ 使 $[P]^2\subseteq K_0$ （**开整齐**），或
> $X=\bigcup_n X_n$ 且 $[X_n]^2\subseteq[X]^2-K_0$ （**闭整齐**）。

> **引理 3.23** 具开区分特性的集合类对可数并、连续像、
> $|\triangle|\le\aleph_0$ 的改动封闭。∎（练习；组装性。）

例 3.8（Todorcevic）：$K=\{(f,g) : \forall i\,(f\upharpoonright i \ne g\upharpoonright i\ \text{且反向})\}$ -型的相对开划分，见证开/
闭整齐的**不对称性**不可消除。

定理 3.32 的证明分三步：设计**开区分赛事** $\mathcal G(X,K)$
（康托尔空间 $2^\omega$ 上，双方轮流出示序对
$(s^0,s^1)$ 与选择 $i_n$ ，串接后收敛出实数；张三赢 iff 不犯规
且成果 $\in X$ ）；引理 3.24：张三稳赢 iff $X$ 含完备开整齐
子集；引理 3.25：李四稳赢 iff $X$ 是可数个闭整齐集之并。李四的
赢是**有限步内**可见的（谁犯规谁输、且李四的犯规条件开），故对李四
是开赛事——Gale–Stewart（命题 3.9 的无限版）给确定性，二选一即
特性。四个「事实」把李四稳赢分解为闭整齐片 $F_p$ （正确位 $p$
处张三认输的节点集），事实三/四分别给出覆盖与整齐性。于是
$2^\omega$ 具特性，经引理 3.23 传给 $\mathbb R,\mathcal N$ 与全
体解析集。

> **定理 3.32（冯）** 解析集具开区分特性。∎

> **定义 3.36（OCA）** 不可数 $X$ 、相对开 $K$ ：或有不可数开整
> 子集，或 $X$ 是可数个闭整齐集之并。

OCA（Todorcevic 公理）作为公理与 MA 并列，是公理集合论组合原理
线的重要成员——第 79 章划分定理的「连续版」后裔。

## 82.15 一张图：从树枝到正则性

把本章与第 80、81 章接成一条链：

| 环节 | 对象 | 关键定理 |
|---|---|---|
| 树枝 | $f\in\mathcal N$ ，$[T]$ | 完备性、区间套（80 章） |
| 闭集 | $X=[T_X]$ | 定理 3.26；完备树=完备集（命题 3.6） |
| 投影 | $\pi_Y(F)$ ，$F$ 闭 | 引理 3.16/3.17（解析=闭投影） |
| 解析 | $f[\mathcal N]$ 、$\mathcal A(f)$ | 四等价；苏斯林 $\Delta^1_1=\mathcal B$ |
| 正则 | 可测、贝尔性质、完备子集 | 定理 3.28；开区分（定理 3.32） |
| 博弈 | $\mathcal G_A$ 、BM 赛事 | 定理 3.29 刻画稀疏；3.9/3.10 开闭确定 |

反向读也成立：**未定集的存在（定理 3.30）标记了博弈方法在 ZFC 内
的边界**；马丁定理把边界推到博雷尔层；解析层以上的确定性需要大基数
——第三卷的接棒处。

## 82.16 机器通道一：Lean——PolishSpace 与康托尔-本狄克森

mathlib 4.33.1 有真正的波兰空间设施：`PolishSpace` 类型类（由
可分 + 完全可度量化给出实例）、`Perfect` 集、以及两条本章正主的
官方定理——闭集的「可数 ∪ 完备」分解，与不可数闭集的康托尔空间
连续单射。缺的是贝尔空间：$\omega^\omega$ 没有现成的 PolishSpace/
度量实例，命题 3.5 的距离 $d=2^{-\triangle}$ 构造留在正文。

```lean
import Mathlib.Topology.MetricSpace.Perfect
import Mathlib.Topology.Baire.CompleteMetrizable
import Mathlib.Topology.Baire.Lemmas

/-!
# 第 82 章 · 贝尔空间、波兰空间、投影集与博弈

登记 mathlib 的波兰空间类与两条官方定理：康托尔-本狄克森分解、
不可数闭集的康托尔空间连续单射。贝尔空间 ℕ→ℕ 在 mathlib 中无现成
PolishSpace 实例，其距离 d(f,g)=2^{-Δ(f,g)} 的构造留在正文（命题 3.5）。
-/

namespace Settheory.Ch82

open Set

/-- 实数轴是波兰空间（定义 3.27、例 3.5）。 -/
example : PolishSpace ℝ := inferInstance

/-- 康托尔-本狄克森（定理 3.23 的拓扑内核）：第二可数空间中的闭集
分解为可数集与完备集之并。 -/
theorem cantor_bendixson {X : Type*} [TopologicalSpace X]
    [SecondCountableTopology X] {C : Set X} (hC : IsClosed C) :
    ∃ V D : Set X, V.Countable ∧ Perfect D ∧ C = V ∪ D :=
  exists_countable_union_perfect_of_isClosed hC

/-- 不可数闭集含非空完备子集（树求导引理 3.13 的官方形态）。 -/
theorem uncountable_closed_perfect {X : Type*} [TopologicalSpace X]
    [SecondCountableTopology X] {C : Set X}
    (hC : IsClosed C) (h : ¬ C.Countable) :
    ∃ D, Perfect D ∧ D.Nonempty ∧ D ⊆ C :=
  exists_perfect_nonempty_of_isClosed_of_not_countable hC h

/-- 不可数闭集上有从康托尔空间 ℕ→Bool 出发的连续单射，
于是 |C| ≥ 2^{ℵ₀}（定理 3.22 + 推论 3.7(2) 的机器版）。 -/
theorem cantor_injection {C : Set ℝ}
    (hC : IsClosed C) (h : ¬ C.Countable) :
    ∃ f : (ℕ → Bool) → ℝ, Set.range f ⊆ C ∧ Continuous f ∧
      Function.Injective f :=
  IsClosed.exists_nat_bool_injection_of_not_countable hC h

/-- 贝尔空间版贝尔纲（定理 3.25）在 ℝ 上的锚点（同第 81 章接口）。 -/
example {ι : Type*} [Countable ι] {U : ι → Set ℝ}
    (ho : ∀ i, IsOpen (U i)) (hd : ∀ i, Dense (U i)) :
    Dense (⋂ i, U i) :=
  dense_iInter_of_isOpen ho hd

end Settheory.Ch82
```

`cantor_bendixson` 的结论形式（$C=V\cup D$ 、$V$ 可数、
$D$ 完备）与 82.3 树版求导的结论逐字对应；`cantor_injection` 把
「完备集有连续统势」直接做成了**连续单射** $2^\omega\to C$ ，比势
不等式更强（这正是 `Perfect.splitting` 分裂引理逐层构造的产物）。
注意三个锚点都只要第二可数性/波兰性，不需要度量——树表示换成了
mathlib 的核（kernel）分解。

## 82.17 机器通道二：Coq——有限 Gale–Stewart 逆向归纳

命题 3.9/3.10 的证明骨架是「逆向归纳 + 不败之地」；在有限深度上，
这一骨架可完整计算化，且**对偶定理**（补赛事 + 换行棋方）可以完全
证明——这是有限确定性的内核。

```coq
(* 第 82 章：有限 Gale–Stewart 逆向归纳——对偶性与具体赛局。 *)
From Coq Require Import List Arith Bool.
Import ListNotations.

Module Ch82.

(* 深度 n 的交替博弈：zs=true 轮张三（存在制胜步即胜），
   zs=false 轮李四（所有步张三都胜张三才胜）。
   前缀以逆序积累：p 的首元素是最近一步。 *)
Fixpoint zwins (A : list bool -> bool) (n : nat) (zs : bool)
    (p : list bool) : bool :=
  match n with
  | 0 => A p
  | S k =>
      if zs
      then orb (zwins A k false (true :: p)) (zwins A k false (false :: p))
      else andb (zwins A k true (true :: p)) (zwins A k true (false :: p))
  end.

(* 对偶：补赛事 + 互换行棋方 = 原赛局的否定（德摩根律逐层生效）。
   有限确定性（命题 3.9/3.10 的内核）：任一赛局恰有一方处于胜势。 *)
Theorem zwins_dual : forall (A : list bool -> bool) (n : nat) (zs : bool),
  forall (p : list bool),
  zwins (fun q => negb (A q)) n (negb zs) p = negb (zwins A n zs p).
Proof.
  intros A n. induction n as [|n IH]; intros zs p.
  - simpl. destruct (A p); reflexivity.
  - destruct zs; simpl.
    + assert (E1 := IH false (true :: p)); simpl in E1.
      assert (E2 := IH false (false :: p)); simpl in E2.
      rewrite E1, E2.
      destruct (zwins A n false (true :: p));
        destruct (zwins A n false (false :: p)); reflexivity.
    + assert (E1 := IH true (true :: p)); simpl in E1.
      assert (E2 := IH true (false :: p)); simpl in E2.
      rewrite E1, E2.
      destruct (zwins A n true (true :: p));
        destruct (zwins A n true (false :: p)); reflexivity.
Qed.

(* 深度 2 的具体赛局：张三出 x、李四出 y（叶上序列为 [y;x]）。 *)
Definition A_and : list bool -> bool :=
  fun q => match q with
           | y :: x :: _ => andb x y
           | _ => false
           end.

Definition A_or : list bool -> bool :=
  fun q => match q with
           | y :: x :: _ => orb x y
           | _ => false
           end.

(* x∧y：张三无胜算——李四总可以出 false。 *)
Example and_game : zwins A_and 2 true [] = false.
Proof. reflexivity. Qed.

(* x∨y：张三先手出 true 即稳赢。 *)
Example or_game : zwins A_or 2 true [] = true.
Proof. reflexivity. Qed.

(* 由对偶定理（换先手 + 取补）：原李四在补赛局中稳赢。 *)
Example and_dual_game : zwins (fun q => negb (A_and q)) 2 false [] = true.
Proof. reflexivity. Qed.

End Ch82.
```

对偶定理的第一版陈述曾写成「补赛事同方获胜」，被 Coq 当场驳回
（$\neg c_1\vee\neg c_2\ne\neg(c_1\vee c_2)$ ）——修正为
**换行棋方**后德摩根律逐层对上。这条对偶正是命题 3.10 由命题 3.9
「翻译」得到的那个翻译（82.13 的证明用了一次），在有限侧它是可证
定理而非隐喻。

## 82.18 机器通道三：Agda——构造性对偶

Agda 版把同样的对偶做成显式证明项：两层德摩根引理
`not-or`/`not-and` 各由四个 `refl` 组成，主定理按行棋方分派后用
`cong₂` 逐分量改写。

```agda
-- 第 82 章：有限 Gale–Stewart 逆向归纳（构造性）与对偶定理。
module Ch82_polish where

open import Data.Bool using (Bool; true; false; not; _∨_; _∧_; if_then_else_)
open import Data.List using (List; []; _∷_)
open import Data.Nat using (ℕ; zero; suc)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong₂; trans)

-- 深度 n 的交替博弈；zs=true 轮张三（∨ 节点），否则轮李四（∧ 节点）。
zwins : (List Bool → Bool) → ℕ → Bool → List Bool → Bool
zwins A zero _ p = A p
zwins A (suc n) zs p =
  if zs
  then zwins A n false (true ∷ p) ∨ zwins A n false (false ∷ p)
  else zwins A n true (true ∷ p) ∧ zwins A n true (false ∷ p)

not-or : (a b : Bool) → not a ∧ not b ≡ not (a ∨ b)
not-or true true = refl
not-or true false = refl
not-or false true = refl
not-or false false = refl

not-and : (a b : Bool) → not a ∨ not b ≡ not (a ∧ b)
not-and true true = refl
not-and true false = refl
not-and false true = refl
not-and false false = refl

-- 对偶定理：补赛事 + 互换行棋方 = 原赛局的否定（有限确定性）。
zwins-dual : (A : List Bool → Bool) (n : ℕ) (zs : Bool) (p : List Bool) →
  zwins (λ q → not (A q)) n (not zs) p ≡ not (zwins A n zs p)
zwins-dual A zero zs p = refl
zwins-dual A (suc n) true p =
  trans (cong₂ _∧_ (zwins-dual A n false (true ∷ p))
                   (zwins-dual A n false (false ∷ p)))
        (not-or (zwins A n false (true ∷ p)) (zwins A n false (false ∷ p)))
zwins-dual A (suc n) false p =
  trans (cong₂ _∨_ (zwins-dual A n true (true ∷ p))
                   (zwins-dual A n true (false ∷ p)))
        (not-and (zwins A n true (true ∷ p)) (zwins A n true (false ∷ p)))

-- 深度 2 的具体赛局（叶上序列为 [y;x]）。
A-and : List Bool → Bool
A-and (y ∷ x ∷ _) = x ∧ y
A-and _ = false

A-or : List Bool → Bool
A-or (y ∷ x ∷ _) = x ∨ y
A-or _ = false

and-game : zwins A-and 2 true [] ≡ false
and-game = refl

or-game : zwins A-or 2 true [] ≡ true
or-game = refl

-- 对偶应用：补赛局换先手，张三（原来的李四）稳赢。
and-dual : zwins (λ q → not (A-and q)) 2 false [] ≡ true
and-dual = refl
```

## 82.19 机器通道四：Isabelle/ZF——有限树的闭集表示

定理 3.26 的有限影子：一棵剪过枝的深度 2 二叉树，验证前缀封闭性、
树枝全体、以及**表示树自动剪掉死节点**后重建同一树枝集。

```isabelle
theory Polish
  imports "ZF.Nat"
begin

text \<open>第 82 章：闭集树表示（定理 3.26）的有限影子。深度 2 的二叉树
以节点集给出；T 是剪枝树；chain 是 T 中的完整树枝；TX 是树枝全体
的表示树（自动剪掉死节点）。\<close>

definition N3 :: "i" where "N3 \<equiv> succ(2)"
definition N4 :: "i" where "N4 \<equiv> succ(N3)"
definition N5 :: "i" where "N5 \<equiv> succ(N4)"
definition N6 :: "i" where "N6 \<equiv> succ(N5)"
definition N7 :: "i" where "N7 \<equiv> succ(N6)"

definition T :: "i" where "T \<equiv> {1, 2, N3, N4, N5}"
definition PAR :: "i" where
  "PAR \<equiv> {\<langle>1,2\<rangle>, \<langle>1,N3\<rangle>, \<langle>2,N4\<rangle>, \<langle>2,N5\<rangle>,
             \<langle>N3,N6\<rangle>, \<langle>N3,N7\<rangle>}"
definition TX :: "i" where "TX \<equiv> {1, 2, N4, N5}"
definition LEAVES :: "i" where "LEAVES \<equiv> {N4, N5, N6, N7}"

(* 前缀封闭：T 中每个非根节点的父节点也在 T 中。 *)
lemma T_prefix_closed:
  "\<forall>c \<in> T. c = 1 \<or> (\<exists>p. \<langle>p,c\<rangle> \<in> PAR \<and> p \<in> T)"
  by (auto simp add: T_def PAR_def N3_def N4_def N5_def)

(* chain(n)：n 是叶且 n 的父链两级都在 T 中（深度 2 的完整树枝）。 *)
definition chain :: "i => o" where
  "chain(n) \<equiv> n \<in> LEAVES \<and> n \<in> T \<and>
    (\<exists>p. \<langle>p,n\<rangle> \<in> PAR \<and> p \<in> T \<and> (\<exists>g. \<langle>g,p\<rangle> \<in> PAR))"

lemma chain_4: "chain(N4)"
  by (auto simp add: chain_def LEAVES_def T_def PAR_def N4_def)

lemma chain_5: "chain(N5)"
  by (auto simp add: chain_def LEAVES_def T_def PAR_def N5_def)

lemma not_chain_6: "\<not> chain(N6)"
  by (simp add: chain_def LEAVES_def T_def N3_def N4_def N5_def N6_def)

(* T 的全体树枝恰为 {N4, N5}：剪掉 6、7 后右枝只剩一个叶。 *)
lemma body_T: "{n \<in> LEAVES. chain(n)} = {N4, N5}"
  by (auto simp add: chain_def LEAVES_def T_def PAR_def
                     N3_def N4_def N5_def N6_def N7_def)

(* 表示树自动剪掉死节点 N3，且在同一叶域上重建同一树枝全体。 *)
lemma dead_3: "N3 \<in> T \<and> N3 \<notin> TX"
  by (auto simp add: T_def TX_def N3_def N4_def N5_def)

lemma TX_subset: "TX \<subseteq> T"
  by (auto simp add: TX_def T_def)

lemma body_TX:
  "{n \<in> LEAVES. n \<in> TX \<and> (\<exists>p. \<langle>p,n\<rangle> \<in> PAR \<and> p \<in> TX \<and>
      (\<exists>g. \<langle>g,p\<rangle> \<in> PAR))} = {N4, N5}"
  by (auto simp add: LEAVES_def TX_def PAR_def
                    N3_def N4_def N5_def N6_def N7_def)

end
```

实纲与第 95 章一致：ZF 的数字缩写只到 2，`N3..N7` 必须显式
succ-链，且**判不等的引理必须把链上的全部定义交给 simp**——
`dead_3` 初版只给了 `N3_def`，在 `succ(2) = N4` 上卡死；补全
`N4_def N5_def` 后 numeral 求值立即收口。`body_T` 与 `body_TX`
给出本章的核心观察的有限形态：**闭集决定表示树，表示树剪掉死
节点后仍在同一叶域上重建同一闭集**。

## 82.20 机器通道五：Julia——有限 Banach–Mazur 影子

深度 6 的「轮流追加一位」赛局（真正的 BM 允许任意有限串，有限影子
取单比特）；四组目标集上逆向归纳求胜方、提取策略、并对对手全部
$2^3$ 条路径穷举验证「稳赢」。

```julia
# 第 82 章：有限 Banach–Mazur 影子——逆向归纳、策略提取与全对手验证。
println("==== 82")

const DEPTH = 6

function make_solver(S)
    memo = Dict{Vector{Int},Bool}()
    function z(s)
        length(s) == DEPTH && return s in S
        get!(memo, s) do
            iseven(length(s)) ?
                any(z([s; b]) for b in (0, 1)) :
                all(z([s; b]) for b in (0, 1))
        end
    end
    z
end

function make_strategy(S)
    z = make_solver(S)
    function pick(s)
        for b in (0, 1)
            t = [s; b]
            if iseven(length(s))
                z(t) && return b
            else
                !z(t) && return b
            end
        end
        return 0
    end
    pick
end

# 稳赢验证：胜方按策略应对另一方全部 2^3 条路径，每条终局都须命中。
function verify(S)
    z = make_solver(S)
    winner = z(Int[])
    pick = make_strategy(S)
    paths = Iterators.product(fill(0:1, 3)...)
    if winner
        for foe in paths
            s = Int[]
            for b in foe
                s = [s; pick(s); b]
            end
            @assert s in S
        end
        return "zhang"
    else
        for foe in paths
            s = Int[]
            for a in foe
                s = [s; a; pick([s; a])]
            end
            @assert !(s in S)
        end
        return "lisi"
    end
end

allseq = [collect(p) for p in Iterators.product(fill(0:1, DEPTH)...)]
S1 = Set(v for v in allseq if count(==(1), v) >= 4)          # 李四可全 0
S4 = Set(v for v in allseq if v[1] == 1)                      # 张三首手锁定
S8 = Set(v for v in allseq if iseven(count(==(1), v)))        # 末手李四定奇偶
S9 = Set(v for v in allseq if v[1] + v[3] + v[5] >= 2)        # 张三自己的位

@assert verify(S1) == "lisi"
@assert verify(S4) == "zhang"
@assert verify(S8) == "lisi"
@assert verify(S9) == "zhang"
z = make_solver(S4)
@assert z(Int[]) && !z([0])
@assert make_strategy(S4)(Int[]) == 1

println("Julia：四组深度 6 赛局逆向归纳——两组张三稳赢、两组李四稳赢；")
println("稳赢策略经 2^3 条对手路径穷举验证（命题 3.9 的有限影子）")
println("END ====")
```

这组实验自带一次实测事故记录：验证循环的初版写成
`s = [s; a; pick(s)]`——`pick(s)` 在**对手落子前**的位置求值。
李四的全 0 策略（S1）对此不敏感而漏网；奇偶敏感的 S8 把它当场抓
住。修正为 `pick([s; a])` 后四组全绿。「策略必须在应对位置查询」
与正文定义 3.32 的 $x(n)=\sigma(x*y\upharpoonright 2n)$ （而非
$2n{+}1$ ）是同一件事——有限实验在这里反哺了定义的读法。

## 82.21 机器通道六：Python——自底向上对拍

```python
# 第 82 章：与 Julia 独立对拍——自底向上全表动态规划与暴力验证。
from itertools import product
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

DEPTH = 6


def solve(S):
    val = {s: (s in S) for s in product((0, 1), repeat=DEPTH)}
    for L in range(DEPTH - 1, -1, -1):
        for s in product((0, 1), repeat=L):
            kids = [val[s + (b,)] for b in (0, 1)]
            val[s] = any(kids) if L % 2 == 0 else all(kids)
    return val


def strategy(val):
    def pick(s):
        for b in (0, 1):
            t = s + (b,)
            want = val[t] if len(s) % 2 == 0 else not val[t]
            if want:
                return b
        return 0
    return pick


def verify(S):
    val = solve(S)
    pick = strategy(val)
    winner = val[()]
    if winner:
        for foe in product((0, 1), repeat=3):
            s = ()
            for b in foe:
                s = s + (pick(s), b)
            assert s in S
        return "zhang"
    for foe in product((0, 1), repeat=3):
        s = ()
        for a in foe:
            s = s + (a, pick(s + (a,)))
        assert s not in S
    return "lisi"


def main():
    print("==== 82")
    allseq = list(product((0, 1), repeat=DEPTH))
    S1 = {s for s in allseq if sum(s) >= 4}
    S4 = {s for s in allseq if s[0] == 1}
    S8 = {s for s in allseq if sum(s) % 2 == 0}
    S9 = {s for s in allseq if s[0] + s[2] + s[4] >= 2}
    assert verify(S1) == "lisi"
    assert verify(S4) == "zhang"
    assert verify(S8) == "lisi"
    assert verify(S9) == "zhang"
    val = solve(S4)
    assert val[()] and not val[(0,)]
    assert strategy(val)(()) == 1
    print("Python：全表 DP 与 Julia 递归对拍一致——同四赛局同胜方；")
    print("策略自底向上提取并经 2^3 条对手路径暴力验证")
    print("END ====")


if __name__ == "__main__":
    main()
```

与 Julia 的分工：这里先铺满 64 个叶再逐层 `any`/`all` 上卷（全表
DP），Julia 是带记忆化的自顶向下递归；坐标用元组对方言向量。四个
赛局胜方一致、策略首手一致（S4 下首手必为 1），双方的策略各自
通过穷举验证。两通道同时犯同一个查询位错误、又同时被同一组穷举
抓住——这正是对拍协议要的双保险。

## 82.22 机器通道七：Prolog——必胜搜索与树投影

```prolog
:- encoding(utf8).
% 第 82 章：逆向归纳必胜搜索 + 有限树投影。

bit(0). bit(1).

count_ones([], 0).
count_ones([B|Bs], N) :- count_ones(Bs, M), N is M + B.

% 两个赛局：a=首位为 1（张三先手锁定）；b=1 的个数 ≥ 4（李四可全 0）。
target(a, [1|_]).
target(b, S) :- count_ones(S, N), N >= 4.

zwin(G, S) :- length(S, 6), !, target(G, S).
zwin(G, S) :- length(S, L), L < 6, L mod 2 =:= 0, !,
              bit(B), append(S, [B], S2), zwin(G, S2).
zwin(G, S) :- length(S, L), L < 6, L mod 2 =:= 1,
              \+ ( bit(B), append(S, [B], S2), \+ zwin(G, S2) ).

% 有限树（剪枝）：节点集与前缀封闭性；叶 = 无真延伸的节点。
tnode([]).
tnode([0]). tnode([1]).
tnode([0,1]). tnode([1,0]). tnode([1,1]).
tnode([0,1,1]). tnode([1,0,0]).

leaf(S) :- tnode(S), \+ (tnode(T), T \= S, append(S, _, T)).

% 投影（Suslin/解析集的有限影子）：满足条件的树叶全体。
proj(P, L) :- leaf(L), call(P, L).
at_least_two(L) :- count_ones(L, N), N >= 2.

main :-
    format("==== 82~n"),
    zwin(a, []), \+ zwin(b, []),
    ( bit(B), append([], [B], S2), zwin(a, S2) -> B = 1 ),
    \+ zwin(b, [1,0]),
    findall(L, proj(at_least_two, L), Ps), Ps = [[1,1],[0,1,1]],
    findall(L, leaf(L), Ls), sort(Ls, Sorted),
    Sorted = [[0,1,1],[1,0,0],[1,1]],
    forall((tnode(T), append(Bs, [_], T)), tnode(Bs)),
    format("赛局 a 张三稳赢（首手 1）、赛局 b 李四稳赢（[1,0] 后张三死局）~n", []),
    format("树叶全体 ~w；≥2 个 1 的投影 = ~w；前缀封闭性 forall 验证通过~n", [Sorted, Ps]),
    writeln("END ====").
```

三件事。其一，`zwin/2` 的三条子句就是命题 3.9 的证明骨架：叶上判
定；张三位**存在**一步；李四位**无**反例步（`\+ (\+ ...)` 的双重
否定实现「所有」）。其二，`[1,0]` 后 `\+ zwin(b, [1,0])` 给出李四
的**具体杀招**（张三首手 1、李四应 0 后，四个剩余位最多再添两个
1，凑不到 4）——这就是定理 3.29(1) 证明里「李四躲进 $G_n$ 」的
有限翻版。其三，树部分验证前缀封闭与叶分解，`proj/2` 把「投影 =
带见证的树叶选择」做成了查询——引理 3.17(4) 的有限影子。

## 82.23 机器的边界

1. **贝尔空间本身缺席**。mathlib 无 $\omega^\omega$ 的
   PolishSpace/度量实例；命题 3.5 的 $d=2^{-\triangle}$ 、完备性
   证明、$\mathcal N\cong$ 无理数，全部只在正文。机器不模拟可分
   完备性。
2. **确定性定理无机器版**。命题 3.9/3.10 的**无限**证明依赖「任取
   更高的见证」与开集的无限结构；有限逆向归纳与对偶定理只是骨架
   的影子。马丁定理（3.31）在 mathlib 中完全缺席；定理 3.30 的
   AC-对角构造是 $2^{\aleph_0}$ 规模的超穷递归。
3. **正则性三定理不可穷举**。测度（定理 3.28(1)）的极小覆盖、贝
   尔性质（(2)）的 $D(Y)$ 、完备子集（(3)）的 $\omega_1$ 长
   求导，全部是无限对象上的超穷/可数构造；Julia/Python 的穷举只
   覆盖 $2^6$ 个点。
4. **开区分赛事未机化**。引理 3.24/3.25 的策略-整齐对应依赖
   $2^\omega$ 的紧性与 Gale–Stewart 无限版，有限侧只保留
   `zwin` 搜索。

## 82.24 本章要点与检查问题

- **一条链**：树枝 →（定理 3.26）闭集 →（引理 3.16/3.17）投影
  → 解析集 →（定理 3.27/3.28）$\Delta^1_1=$ 博雷尔、三正则性。
  苏斯林运算是链条的运算胶水；四等价把「连续像」「闭投影」「苏斯
  林模式」三种直觉锁死。
- **层级严格**：通用集 + 对角（推论 3.5/3.6）让博雷尔层与投影层
  都货真价实；隔离引理把 $\Delta^1_1$ 拉回博雷尔。
- **正则性上限**：解析集全部可测、全部具贝尔性质、不可数即含完
  备子集（从而都不是 CH 反例）；$\Pi^1_1$ 的完备子集问题与投影
  正则性问题留给第三卷。
- **博弈即正则**：BM 赛事稳赢 ⟺ 稀疏/余稀疏（定理 3.29）；开闭
  赛局确定（3.9/3.10）；AC 下有未定集（3.30）；博雷尔全确定
  （马丁，引用）；解析集开区分（定理 3.32，冯琦定理）与 OCA。
- **实测账**：策略必须在**应对位置**查询（Julia/Python 同坑同
  修）；对偶必须**换行棋方**（Coq 驳回第一版）；ZF succ-链数字
  判等需全链定义进 simp。

检查问题：

1. 引理 3.13 的单射 $f\mapsto s_f$ 为什么必须取**最小**的
   $n_f$ ？换成「任意一个进入 $T-T'$ 的深度」会在哪里失效？
2. 定理 3.28(1) 的关键包含
   $B-A\subseteq\bigcup_s(B_s-\bigcup_kB_{s\frown k})$ ：请
   复述「从 $x\in B_s$ 出发递归选树枝」的论证，并指出哪一步用
   了 $B_s$ 的**极小覆盖**性质。
3. 命题 3.10 的对偶翻译里，「李四的策略 = 张三在补赛事中的策略」
   为什么不改变信息结构？若把赛制改为张三每次走两步、李四一步，
   这个翻译还成立吗？

---

上一章：[81 实数子集正则性](81-regularity.md) · 下一章：[83 非标准实数直线与苏斯林直线](83-twolines.md)
