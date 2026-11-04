# 81 · 实数子集的正则性：贝尔性质、可测性与完备子集

> 第 80 章回答「实数轴本身有没有洞」；本章把镜头从轴转向轴上的子集。
> 冯琦第一卷 §3.5（书页 233–248；PDF 251–266）依次提出三个正则性问题：
> 一个子集是否几乎等于开集（贝尔性质）、是否几乎等于博雷尔集（勒贝格
> 可测性）、是否只要不可数就含完备子集（完备子集特性）。三个问题在
> ZFC 内对全体子集的回答都是否定的——维塔利集合打击前两者，伯恩斯坦
> 集合打击第三者；而对「简单」子集（博雷尔、解析）答案肯定，这正是
> 描述集合论的入口。马丁公理则把稀疏理想与零测理想的可加性同时推到
> $2^{\aleph_0}$ （Martin–Solovay 定理）。
>
> 回读原页记录两处。其一，书页 240 偏序定义一行 OCR 完全丢失，按原页
> 图像与证明结构重建为「$p$ 比 $q$ 强当且仅当 $q\subseteq p$ 」：
> 强条件是超集，滤子元素有限并的测度上界正依赖这一方向；原书本身
> 无误，只是 OCR 不堪使用。其二，引理 3.8 断言完备集 $p$ 与最左等宽
> 条带之交的上、下确界截出的 $p\cap[a,b]$ 仍是完备集；这在两种边角
> 下都不成立（81.8 给出具体反例），因此定理 3.22 的证明按有理闭区间
> 二叉树重建，不再依赖该引理。七个机器通道只承担有限部分——有限理想、
> 模二余类、康托尔区间的精确算术、完备二叉树的分支计数、有限商上的
> 代表选择与对称差代数；贝尔纲定理、Martin–Solovay 定理与完备集定理
> 的无限本体全部由正文证明。

## 81.1 无处稠密与稀疏：把「薄」变成理想

衡量一个子集有多「薄」，第一个候选是**无处稠密**：$N\subseteq\mathbb R$
无处稠密，是指它的闭包没有内点，即 $\overline N$ 不包含任何非空开
区间。等价地说，每个非空开区间 $(a,b)$ 都含有一个与 $N$ 不相交的
非空开子区间。三个 immediate 样本（例 3.2）：

1. 整数集 $\mathbb Z$ 是闭集且无内点，故无处稠密；于是
   $\mathbb R\setminus\mathbb Z$ 是稠密开集。
2. 有理数集 $\mathbb Q$ 稠密，绝非无处稠密；但它是可数集，而每个
   单点集 $\{q\}$ 都无处稠密，所以 $\mathbb Q$ 是可数个无处稠密
   集合之并。
3. 有限集无处稠密；第 80 章末尾的康托尔三分集（81.7 详谈）是闭且
   无处稠密的无穷集。

单个无处稠密集还不够「理想」：理想的本质是「小集合的并还小」。称
$M\subseteq\mathbb R$ 为**稀疏**（第一纲）集，当且仅当 $M$ 是可数
个无处稠密集之并；非稀疏的集合称为**第二纲**集（定义 3.17）。这样
稀疏子集族 $\mathcal I_c$ 自动满足：含 $\varnothing$ 、对子集封闭、
对**有限**并封闭。真正需要证明的是第四条——对**可数**并封闭，即
$\sigma$ -可加性；这正是贝尔纲定理的内容（推论 3.3）。于是「整个
实数轴是否稀疏」成为第一个必须回答的问题：若 $\mathbb R$ 稀疏，
理想就不真（proper）；若不稀疏，$\mathcal I_c$ 就是包含所有单点集
的非平凡 $\sigma$ -理想。

## 81.2 贝尔纲定理（定理 3.17）

> **定理 3.17（贝尔纲）** 设 $\langle D_n\mid n<\omega\rangle$ 是
> 实数轴上的稠密开集序列，则 $\bigcap_{n<\omega}D_n$ 在实数轴上稠密。

**证明**。先把序列单调化：令 $B_n=\bigcap_{i<n}D_i$ 。有限交保持
「稠密开」，且 $B_{n+1}\subseteq B_n$ ，$\bigcap_n D_n=\bigcap_n B_n$ 。

固定任一非空开区间 $I$ ，要证 $\bigcap_n D_n$ 与 $I$ 相交。取定
全体有理开区间的单一列表 $(J_k=(r_k,q_k)\mid k<\omega)$ 。递归构造
区间套：令 $I_0=I$ 。给定非空开区间 $I_n$ ，$B_n\cap I_n$ 是非空
开集，于是可取有理开区间使其**闭包**整个落在 $B_n\cap I_n$ 内；令

$$m=\min\{k<\omega : \overline{J_k}\subseteq B_n\cap I_n\},\qquad I_{n+1}=J_m .$$

这样 $\overline{I_{n+1}}\subseteq B_n\cap I_n\subseteq I_n$ ，闭包
$\langle\overline{I_n}\mid 1\le n<\omega\rangle$ 构成递降的有界闭
区间套。由第 80 章的区间套定理（定理 3.15），交集
$\bigcap_{1\le n<\omega}\overline{I_n}$ 非空；取其中一点 $x$ 。对每个
$n$ ，$x\in\overline{I_{n+1}}\subseteq B_n\subseteq D_n$ ，且
$x\in I_1\subseteq I$ 。故 $\bigcap_n D_n\cap I\ne\varnothing$ 。∎

证明里唯一的「完备性输入」就是区间套定理；第 80 章已经用 Dedekind
截断把它从序完备性推出来，所以这里没有循环。

> **推论 3.2** 若 $a<b$ ，则开区间 $(a,b)$ 不是稀疏集；从而所有
> 非空开子集都不是稀疏集。

**证明**。反设 $(a,b)=\bigcup_n N_n$ ，各 $N_n$ 无处稠密，则
$D_n=\mathbb R\setminus\overline{N_n}$ 是稠密开集，定理 3.17 给出
$x\in\bigcap_n D_n\cap(a,b)$ 。但 $x\notin\overline{N_n}\supseteq N_n$ 对一切 $n$ 成立，与 $(a,b)=\bigcup_n N_n$ 矛盾。非空开集是
若干构成区间之并，稀疏集的子集稀疏，故结论由区间版本立即放大。∎

> **推论 3.3** 全体稀疏子集之集 $\mathcal I_c$ 是非平凡的、包含
> 所有单点子集的可数可加理想。

**证明**。$\mathbb R$ 本身是非空开集，由推论 3.2 不稀疏，故理想
非平凡。单点集闭且无内点，无处稠密。可数个稀疏集之并是「可数个
（可数个无处稠密集之并）」的并，重排后仍是可数个无处稠密集之并。∎

读者应把「$\mathbb R\notin\mathcal I_c$ 」与测度论里的
「$\mu(\mathbb R)>0$ 」对照：一个理想只要不含全集，就能支撑「几乎
处处」式的推理；本章后面三种正则性全部是「模某理想几乎等于某简单集」
的句式。

## 81.3 马丁公理下的强可加性（定理 3.18、引理 3.5、定理 3.19）

贝尔纲只管可数交。马丁公理把「可数」换成「小于 $2^{\aleph_0}$ 」。

> **定理 3.18** 若 $\mathrm{MA}_\kappa$ 成立，则实数轴上势不超过
> $\kappa$ 的稠密开集族之交仍稠密。

**证明**。完全照抄定理 3.17 的骨架，只是把「在可数多个有理开区间里
取最小者」换成一次力迫论证。固定非空开区间 $(a,b)$ ，取偏序集
$\mathbb P$ 为 $(a,b)$ 的非空闭子区间全体，$q\le p$ 当且仅当
$q\subseteq p$ （小区间是强条件）。$\mathbb P$ 满足可数反链条件：
两两不相容的条件内部互不相交，而互不相交的开区间族经有理数稠密性
可数。对每个给定的稠密开集 $D_\alpha$ ，
$E_\alpha=\{p\in\mathbb P: p\subseteq D_\alpha\}$ 是稠密的（任一
$p$ 的内部与 $D_\alpha$ 相交，从中截一个更小的闭区间）。
$\mathrm{MA}_\kappa$ 给出与所有 $E_\alpha$ 相交的滤子 $G$ ；
滤子元素两两相容，闭区间族 $\{p\in G\}$ 具有有限交性质，由紧致性
（第 80 章定理 3.16）总交非空，取出的一点落在
$\bigcap_{\alpha<\kappa}D_\alpha\cap(a,b)$ 内。∎

稀疏理想版本要多一层包装，因为稀疏集是「无处稠密集的可数并」，而
定理 3.18 只直接处理稠密开集。原书的引理 3.5 把一整个序列压进条件里：

> **引理 3.5（Martin–Solovay 的引擎）** 假设 $\mathrm{MA}_\kappa$
> 成立，$\kappa<2^{\aleph_0}$ 无穷。设
> $\langle A_\alpha\mid\alpha<\kappa\rangle$ 是无处稠密**闭**子集
> 序列，$A=\bigcup_{\alpha<\kappa}A_\alpha$ 。则存在可数个稠密开集
> $\langle H_i\mid i<\omega\rangle$ 见证
> $A\cap\bigcap_{i<\omega}H_i=\varnothing$ 。

**证明**。条件是有限序列
$p=\langle(U_0,E_0),\ldots,(U_n,E_n)\rangle$ ，其中：

- (a) 每个 $U_i$ 是有限个有理端点开区间之并；
- (b) $E_i\in[\kappa]^{<\omega}$ ；
- (c) $U_i\cap\bigcup_{\alpha\in E_i}A_\alpha=\varnothing$ 。

$p'\le p$ （更强）当且仅当 $p'$ 更长，且对 $p$ 的每个坐标
$i\le n$ 有 $U_i\subseteq U_i'$ 与 $E_i\subseteq E_i'$ 。

**可数反链条件**：两个条件若具有相同的开集序列
$(U_0,\ldots,U_n)$ ，则它们相容——公共延拓取
$\langle(U_0,E_0\cup E_0'),\ldots,(U_n,E_n\cup E_n')\rangle$ 。这里
(c) 的验证恰好吃满两个原条件都使用同一 $U_i$ 的事实：$p$ 保证
$U_i$ 避开 $E_i$ 中的 $A_\alpha$ ，$p'$ 保证同一 $U_i$ 避开
$E_i'$ 中的 $A_\alpha$ ，合并后仍避开。有理端点有限并只有可数多种，
故每个反链向可数个开集序列至多各贡献一个条件。

**稠密集**：令 $\langle I_k\rangle$ 为有理开区间列表。

- $D_{i,k}=\{p: i\le\mathrm{dom}(p),\ U_i\cap I_k\ne\varnothing\}$
  稠密：向 $p$ 尾部补上 $(\varnothing,\varnothing)$ 占位坐标，
  再在第 $i$ 位放一个落在 $I_k$ 内的有理开区间即可。
- $C_\alpha=\{p: \exists i\le\mathrm{dom}(p),\ \alpha\in E_i\}$
  稠密：$A_\alpha$ 无处稠密且闭，其补集含非空开区间，从中取有理
  开区间 $U$ ，尾接 $(U,\{\alpha\})$ ，(c) 成立。

$\mathrm{MA}_\kappa$ 给出与全体 $C_\alpha$ 、$D_{i,k}$ 相交的
滤子 $G$ 。令

$$H_i=\bigcup\{U_i : \exists p\in G,\ i\le\mathrm{dom}(p),\ p(i)=(U_i,E_i)\}.$$

由 $D_{i,k}$ ，每个 $H_i$ 与每个 $I_k$ 相交，故稠密开。固定
$\alpha<\kappa$ ，取 $p\in G\cap C_\alpha$ ，设 $\alpha\in E_i$
（$i\le\mathrm{dom}(p)$ ）。对任一 $q\in G$ 且 $i\le\mathrm{dom}(q)$ ，
滤子给出公共延拓 $r\le p,q$ ；由次序定义 $U^q_i\subseteq U^r_i$ ，
由 (c) 有 $U^r_i\cap A_\alpha=\varnothing$ ，故
$U^q_i\cap A_\alpha=\varnothing$ 。对 $q$ 取并得
$H_i\cap A_\alpha=\varnothing$ 。于是

$$A\cap\bigcap_{i<\omega}H_i =\bigcup_{\alpha<\kappa}A_\alpha\cap\bigcap_{i<\omega}H_i =\varnothing.$$

（严格地说应取那个见证 $\alpha$ 的固定 $i$ ；上面已证该
$H_i$ 与 $A_\alpha$ 不交，对 $\alpha$ 求并即得。）∎

> **定理 3.19（Martin–Solovay）** 若 $\mathrm{MA}_\kappa$ 成立
> （$\kappa<2^{\aleph_0}$ ），则 $\kappa$ 个稀疏子集之并仍稀疏；
> 特别地，$\mathrm{MA}$ 之下严格少于 $2^{\aleph_0}$ 个稀疏子集之并
> 仍稀疏。

**证明**。把每个稀疏集拆成可数个无处稠密集之并，全体的并重排为
$\langle A_\alpha\mid\alpha<\kappa\rangle$ （仍是 $\kappa$ 个，因
$\kappa$ 无穷），取其无处稠密**闭**包后应用引理 3.5：得到的
$\langle H_i\rangle$ 是可数个稠密开集，其交与整个并集不相交，故
该并集含于可数个无处稠密闭集 $\mathbb R\setminus H_i$ 之并，稀疏。∎

于是 $\mathrm{MA}$ 之下 $\mathcal I_c$ 的可加性从 $\aleph_0$ 跳到
$2^{\aleph_0}$ ：连续统的「少数派」并进来仍然稀疏。若
$2^{\aleph_0}>\aleph_1$ ，这与 CH 情形形成实质对比。

## 81.4 贝尔性质：模稀疏理想的代数（定义 3.18–3.21）

有了非平凡 $\sigma$ -理想，就能定义「几乎等于」。

> **定义 3.18** $A\subseteq\mathbb R$ 具有**贝尔性质**，当且仅当
> 存在开集 $B$ 使 $A\triangle B=(A\setminus B)\cup(B\setminus A)$
> 是稀疏集。全体贝尔性质子集记为 $\mathcal C$ 。

> **定义 3.19** $\Omega\subseteq\mathcal P(X)$ 是 $X$ 上的
> **代数**，若 $X\in\Omega$ 、对补封闭、对二元并封闭；是
> $\sigma$ -**代数**，若还对可数并封闭。

> **定理 3.20** $\mathcal C$ 是实数轴上包含全体稀疏子集与全体开集
> 的 $\sigma$ -代数。

**证明**。稀疏集 $M$ 与 $\varnothing$ 之差 $M\triangle\varnothing=M$
稀疏，故 $M\in\mathcal C$ 。开集 $O$ 满足
$O\triangle O=\varnothing$ ，故 $O\in\mathcal C$ 。

对补封闭：设 $A\triangle B\in\mathcal I_c$ ，$B$ 开。则

$$(\mathbb R\setminus A)\triangle(\mathbb R\setminus B) =A\triangle B\in\mathcal I_c,$$

而 $\mathbb R\setminus B$ 是闭集。这里「闭集也几乎开」的隐性事实
是：开集 $O$ 满足 $\overline O\setminus O$ 无处稠密，故闭集
$F=\overline F$ 与开集 $\mathbb R\setminus\overline{\mathbb R \setminus F}$ （即 $F$ 的内部之补）之差 $F\setminus \operatorname{int}F$ 是闭无处稠密集。

对可数并封闭：设 $A_n\triangle B_n$ 各稀疏，$B_n$ 开。则

$$\Big(\bigcup_n A_n\Big)\triangle\Big(\bigcup_n B_n\Big) \subseteq\bigcup_n(A_n\triangle B_n)\in\mathcal I_c,$$

且 $\bigcup_n B_n$ 开。∎

> **定义 3.21** $\mathcal B(\mathbb R)$ 为实数轴上包含全体开集的
> 最小 $\sigma$ -代数（博雷尔代数）；其元素称为博雷尔子集。

> **命题 3.3** 每个博雷尔子集都具有贝尔性质。

**证明**。开集全在 $\mathcal C$ 中，$\mathcal C$ 是 $\sigma$ -
代数，而 $\mathcal B(\mathbb R)$ 是包含开集的最小者，故
$\mathcal B(\mathbb R)\subseteq\mathcal C$ 。∎

于是问题 3.2（$\mathcal C$ 是否就是 $\mathcal P(\mathbb R)$ ）成为
自然的下一步。

## 81.5 维塔利集合：选择公理下的第一反例（定义 3.20）

> **定义 3.20** 对 $a,b\in\mathbb R$ 定义 $a\equiv b$ 当且仅当
> $a-b\in\mathbb Q$ 。这是等价关系。$A\subseteq\mathbb R$ 是
> **维塔利集合**，当且仅当 $A$ 与每个等价类恰交一点。

**事实**。假设选择公理，维塔利集合存在；且任何维塔利集合都不具有
贝尔性质。

**存在性**：每个等价类非空，由选择公理同时在所有类中取代表。
（事实上用到的是 $\mathbb R/\mathbb Q$ 上的选择；本章按原书整体
假设 AC。）

**不具有贝尔性质**（原书列为事实，这里补全论证）。设 $A$ 维塔利
且具有贝尔性质：存在开集 $O$ 使 $A\triangle O\in\mathcal I_c$ 。

情形一：$A\in\mathcal I_c$ 。平移是同胚，保持稀疏性；$\mathbb Q$
可数，故

$$\mathbb R=\bigcup_{q\in\mathbb Q}(A+q)\in\mathcal I_c$$

（每个实数都与某个代表同类，故等号成立；可数并封闭即推论 3.3）。
但 $\mathbb R$ 是非空开集，与推论 3.2 矛盾。

情形二：$A\notin\mathcal I_c$ 。由 $A\triangle O\in\mathcal I_c$
且 $A$ 非稀疏，$O$ 必须非空；取非空开区间 $I\subseteq O$ 。在
$I$ 上，$I\setminus A\subseteq O\setminus A\subseteq A\triangle O$
稀疏，即 $A\cap I$ 在 $I$ 中余稀疏。取有理数
$\delta\in(0,\mathrm{diam}\, I)$ 使
$J=I\cap(I+\delta)$ 含非空开区间。$A\cap I$ 在 $I$ 中余稀疏
$\Rightarrow$ $(A+\delta)\cap(I+\delta)$ 在 $I+\delta$ 中
余稀疏 $\Rightarrow$ 两者都在 $J$ 中余稀疏。两个在 $J$ 中余
稀疏的集合必相交：否则
$J\subseteq(J\setminus A)\cup\big(J\setminus(A+\delta)\big)$
稀疏，与推论 3.2 冲突。取交点 $x$ ：$x\in A$ 且
$x=a+\delta$ （$a\in A$ ），于是 $a,x$ 是同类的两个不同元素
（$\delta\ne0$ ），与维塔利性矛盾。∎

于是问题 3.2 的答案是否定的，问题转写为 3.3：是否存在「简单」的不具
贝尔性质的实数子集？原书把它留给最后一章：在第 82 章将看到博雷尔集
全部具有贝尔性质（命题 3.3 已给出），而「解析集也全部具有」是描述
集合论的第一批定理；再往上（射影集）则越出 ZFC，需要大基数或决定性
假设——这正是第三卷 111–122 章的入口。

## 81.6 勒贝格可测性：模零测理想的代数

第二种「几乎」来自长度。若有界开集 $G$ 是**至多可数个互不相交的
构成开区间之并** $G=\bigcup_{n<\beta}I_n$ （$\beta\le\omega$ ），其
长度自然定义为 $\lambda(G)=\sum_n\lambda(I_n)$ 。

**校勘**：原页该行的集合运算符印成了交；构成区间分解当然用并，本
文按并陈述。OCR 对此同样无法辨认，公式一律回读页面图像。

> 对 $X\subseteq\mathbb R$ ，定义**外测度**
> $$\mu^*(X)=\inf\Big\{\sum_{k<\omega}(b_k-a_k) : X\subseteq\bigcup_{k<\omega}(a_k,b_k)\Big\}.$$
>
> 称 $X$ 零测，若 $\mu^*(X)=0$ 。称 $A\subseteq\mathbb R$
> **勒贝格可测**，当且仅当对一切 $X\subseteq\mathbb R$
> $$\mu^*(X)=\mu^*(X\cap A)+\mu^*(X\setminus A)$$
>
> （卡拉泰奥多里判据；原书以全体实数子集为测试集）。可测集的测度
> 取 $\mu(A)=\mu^*(A)$ 。

测度论标准事实一览（原书八条，本文给出要点）：

1. 每个区间可测且测度等于长度：区间拆成可数个开区间覆盖自身的
   下确界恰为长度，卡拉泰奥多里不等式由次可加性的一半与平移不变
   的紧性论证给出。
2. 可测集全体 $\mathcal M$ 是 $\sigma$ -代数：卡拉泰奥多里判据
   对补显然对称，对可数并用「先证二元并、再归纳」的标准路线；由
   此每个博雷尔集可测。
3. $\mu$ 在 $\mathcal M$ 上可数可加：外测度只保证次可加，可测性
   恰好把测试集 $X=\bigcup_n A_n$ 的每个 $A_n$ 切干净，归纳得
   $\sum_n\mu(A_n)\le\mu(\bigcup_n A_n)$ ，反方向是次可加。
4. $\sigma$ -有限：$\mathbb R=\bigcup_n[-n,n]$ 。
5. 零测集可测、单点集零测、零测集成 $\sigma$ -可加理想
   $\mathcal I_m$ ：$\mu^*(\varnothing)=0$ ；单点是长度任意小的
   区间之交；可数个零测集的覆盖拼起来仍任意小。
6. 内正则：$\mu(A)=\sup\{\mu(K):K\subseteq A\text{ 紧}\}$ 。
7. $F_\sigma$ 近似：存在 $F_\sigma$ 集 $B$ 与 $G_\delta$ 集
   $C$ 使 $B\subseteq A\subseteq C$ 且 $\mu^*(C\setminus B)=0$ 。
   （用 (6) 与外测度定义，从内外两侧逼近。）
8. $A$ 可测当且仅当存在博雷尔集 $C$ 使 $\mu^*(A\triangle C)=0$ ：
   由 (7) 取 $C$ 为那个 $F_\sigma$ 或 $G_\delta$ 即可。

令 $\mathcal I_m=\{A:\mu^*(A)=0\}$ 。与稀疏理想完全平行，问题 3.4
（$\mathcal M=\mathcal P(\mathbb R)$ ？）的答案也是否定的：**维塔利
集合不可测**（原书列为练习 3.4，这里给出完整论证；论证不依赖代表
的落点）。设 $A$ 维塔利且可测。先注意维塔利性使**全体**有理平移
两两不交：若 $a+q=a'+q'$ （$q\ne q'$ ），则 $a-a'\in \mathbb Q\setminus\{0\}$ ，同类两代表，矛盾。

若 $\mu(A)=0$ ：$\mathbb R=\bigcup_{q\in\mathbb Q}(A+q)$ 是可数
个零测集之并，于是 $[0,1]$ 零测，与事实 (1)（区间测度等于长度）
矛盾。

若 $\mu(A)>0$ ：由 $\sigma$ -有限性取 $n$ 使
$A_n=A\cap[-n,n]$ 有正测度 $c$ 。对 $q\in\mathbb Q\cap[-1,1]$
（可数集），诸 $A_n+q$ 两两不交、全落在测度 $2n+2$ 的
$[-n-1,n+1]$ 内。可数可加给出
$\sum_q c\le 2n+2$ ，左边是无穷，矛盾。∎

于是问题 3.5 重演 3.3 的句式：是否存在「简单」的不可测集？

与定理 3.19 平行的加强是：

> **定理 3.21（Martin–Solovay，测度版）** 若
> $\mathrm{MA}_\kappa$ 成立（$\kappa<2^{\aleph_0}$ ），则 $\kappa$
> 个零测集之并仍零测；特别地，$\mathrm{MA}$ 之下严格少于
> $2^{\aleph_0}$ 个零测集之并零测。

**证明**。设 $\langle A_\alpha\mid\alpha<\kappa\rangle$ 零测，
$A=\bigcup_\alpha A_\alpha$ ，固定 $\varepsilon>0$ 。取偏序集

$$P=\{p\subseteq\mathbb R : p\text{ 开且}\ \mu(p)<\varepsilon\}, \qquad p\le q \iff q\subseteq p,$$

即 **$p$ 比 $q$ 强当且仅当** $q\subseteq p$ ：强条件是超集。
（书页 240 这一行 OCR 完全丢失；按原页图像与下文「滤子有限并仍在
$\varepsilon$ 内」的需要，方向如上，原书无误。）

**可数反链条件**。令 $\mathcal S$ 为有限个有理端点开区间之并的全
体，可数。对每个 $p\in P$ 取 $p^*\in\mathcal S$ 使
$\mu(p\triangle p^*)<\tfrac13(\varepsilon-\mu(p))$ （有理端点对外
测度的逼近）。若 $W\subseteq P$ 不可数，则 $W$ 到可数集
$\mathcal S$ 的映射 $p\mapsto p^*$ 必有不可数纤维；取其中相异
$p,q$ ，记 $r=p^*=q^*$ 。记 $\delta_p=\tfrac13(\varepsilon-\mu(p))$ ，
$\delta_q$ 同理。由 $\mu(r)\le\mu(p)+\delta_p =\tfrac13\varepsilon+\tfrac23\mu(p)$ 解出
$\mu(p)>\tfrac{3\mu(r)-\varepsilon}{2}$ ，对 $q$ 同理。代回误差
定义：

$$\delta_p=\tfrac13\big(\varepsilon-\mu(p)\big) <\tfrac13\Big(\varepsilon-\tfrac{3\mu(r)-\varepsilon}{2}\Big) =\tfrac{\varepsilon-\mu(r)}{2},$$

$\delta_q$ 同样。于是

$$\mu(p\cup q)\le\mu(r)+\mu(p\setminus r)+\mu(q\setminus r) <\mu(r)+\delta_p+\delta_q<\mu(r)+2\cdot\tfrac{\varepsilon-\mu(r)}{2} =\varepsilon.$$

故 $p\cup q\in P$ 且是 $p,q$ 的公共强条件（它同时是两者的超集）：
$W$ 不是反链。

**稠密集**。$D_\alpha=\{p\in P: A_\alpha\subseteq p\}$ 稠密：
$A_\alpha$ 零测，可取开集 $V\supseteq A_\alpha$ 使
$\mu(V)<\varepsilon-\mu(p)$ ，则 $p\cup V\in D_\alpha$ 且
$p\cup V\le p$ 。

$\mathrm{MA}_\kappa$ 给出与全体 $D_\alpha$ 相交的滤子 $G$ 。令
$U=\bigcup G$ 。$U$ 开且 $A\subseteq U$ 。对有限个
$p_1,\ldots,p_n\in G$ ，滤子的定向性给出 $r\in G$ ，
$r\supseteq p_1\cup\cdots\cup p_n$ ，于是
$\mu(p_1\cup\cdots\cup p_n)\le\mu(r)<\varepsilon$ 。实轴第二可数，
$U$ 可被 $G$ 的可数子族 $H$ 覆盖（林德勒夫性质）；把 $H$
排成序列，由测度的下连续性，

$$\mu(U)=\sup_n\mu\Big(\bigcup_{i\le n}H_i\Big)\le\varepsilon.$$

$\varepsilon$ 任意，故 $\mu^*(A)=0$ 。∎

> **推论 3.4** $\mathrm{MA}_\kappa$ 之下，$\kappa$ 个（不必不交
> 的）可测集之并可测：先令 $B_\alpha=A_\alpha\setminus \bigcup_{\beta<\alpha}A_\beta$ 摘出不交化，其中测度为零者至多
> $\kappa$ 个，由定理 3.21 其并零测、故可测；测度非零者由可数
> 可加性至多可数个，其并可测；两块之并即所求。

## 81.7 完备集与康托尔三分集（定义 3.22、例 3.4）

第三种正则性与理想无关，直接问「不可数能留下什么结构」。

> **定义 3.22** $A\subseteq\mathbb R$ 是**完备集**，当且仅当
> $A$ 非空、闭、且无孤立点（$a\in A$ 孤立指某开区间 $I$ 使
> $I\cap A=\{a\}$ ）。

最著名的完备集是康托尔三分集。用第 79 章的二叉树
$\mathrm{Seq}(\{0,1\})$ 递归定义闭区间 $P_s$ ：$P_{\langle\rangle} =[0,1]$ ；给定 $P_s=[a,b]$ ，令

$$P_{s\frown 0}=\Big[a,\ a+\tfrac{b-a}{3}\Big],\qquad P_{s\frown 1}=\Big[b-\tfrac{b-a}{3},\ b\Big].$$

$F_n=\bigcup\{P_s:s\in 2^n\}$ 是 $2^n$ 个互不相交闭区间之并，
$F_{n+1}\subseteq F_n$ ，闭包套递降。$C=\bigcap_n F_n$ 是闭集。

**事实一：$\operatorname{card}(C)=2^{\aleph_0}$ 。** 对
$f\in 2^\omega$ ，闭区间套 $\langle P_{f\restriction n}\rangle$
长度 $3^{-n}\to0$ ，由区间套定理总交恰一点 $d_f$ 。映射
$f\mapsto d_f$ 单：若 $f,g$ 首次分歧于 $n$ ，则
$d_f\in P_{f\restriction n+1}$ 、$d_g\in P_{g\restriction n+1}$
是两个不交闭区间中的点。它还是满：对 $a\in C$ ，令
$f=\bigcup\{s\in\mathrm{Seq}(\{0,1\}):a\in P_s\}$ ，则每层恰有一个
长度 $n+1$ 的前缀 $s$ 使 $a\in P_s$ （同层区间两两分离），且
$a=d_f$ 。

**事实二：$C$ 是完备集。** 只须验无孤立点。取 $a\in C$ 、
$\varepsilon>0$ ，取 $n$ 使 $3^{-n}<\varepsilon$ 。设
$a=d_f$ ；取 $g$ 与 $f$ 在前 $n$ 位一致而其后不同。则
$d_f,d_g$ 同落于长度 $3^{-n}$ 的区间 $P_{f\restriction n}$ ，
$|d_f-d_g|\le 3^{-n}<\varepsilon$ ，且 $d_g\ne d_f$ 、
$d_g\in C$ 。∎

三个「小」互不包含，值得在此一次说清：

- $C$ 稀疏（闭无处稠密）**且**零测（总长 $(2/3)^n\to0$ ），但
  $\operatorname{card}(C)=2^{\aleph_0}$ ：「小」不等于「可数」。
- 刘维尔数是稠密 $G_\delta$ （余稀疏）而零测：零测 $\nsubseteq$
  稀疏。
- 「胖康托尔集」（挖掉中间 $3^{-k}$ 递减份额）闭无处稠密而测度
  可任意接近 1：稀疏 $\nsubseteq$ 零测。

Julia 通道（81.16）用精确有理数核验前 8 层的计数、长度与总长
$(2/3)^k$ ；「取极限后零测」这一步属于无限论证，机器不参与。

## 81.8 完备集的势：定理 3.22 及引理 3.6–3.8 的账

> **定理 3.22** 每个完备实数集合的势都是 $2^{\aleph_0}$ 。

$\le$ 方向是 $\mathbb R$ 的势。$\ge$ 方向原书用三条引理搭一架
「拆分—收缩」机器：

> **引理 3.6** 若 $F$ 完备，则存在有理数 $r<s$ 使
> $F\cap(-\infty,r]$ 与 $F\cap[s,+\infty)$ 都是完备集。

**证明**。令 $\alpha=\inf F,\ \beta=\sup F$ （允许
$\mp\infty$ ）。若 $(\alpha,\beta)\subseteq F$ ，则 $F$ 是区间型
完备集，任取 $\alpha<r<s<\beta$ 的有理对，两侧切口由区间性完备。
否则取 $x\in(\alpha,\beta)\setminus F$ ；$F$ 闭，故有 $\delta>0$
使 $(x-\delta,x+\delta)\cap F=\varnothing$ ，取有理数
$r<s$ 落在此洞内。验证左侧完备：闭性显然。无孤立点：其上确界
$b'\le r$ ，若 $b'$ 在该侧孤立，则 $F\cap(b'-\eta,b')=\varnothing$
且 $(b',r]\cap F=\varnothing$ （否则与 sup 矛盾），于是 $b'$ 在
$F$ 中左右皆有间隙、孤立，与 $F$ 完备矛盾；其余点的左邻域或
右邻域总有本侧伙伴。右侧对称。∎

> **引理 3.7** 存在 $G_0,G_1:\mathbb P\to\mathbb P$ （$\mathbb P$
> 为完备集全体），使 $G_i(p)\subseteq p$ 且
> $G_0(p)\cap G_1(p)=\varnothing$ 。

**证明**。取 $\{(r_n,s_n)\}$ 为有理数对列表。对 $p\in\mathbb P$
令 $n_p$ 为使引理 3.6 结论成立的最小 $n$ ，并令
$G_0(p)=p\cap(-\infty,r_{n_p}]$ 、$G_1(p)=p\cap[s_{n_p},+\infty)$ 。∎

> **引理 3.8（原书形式）** 存在 $H:\mathbb P\times\mathbb N\to \mathbb P$ 使 $H(p,n)\subseteq p$ 且
> $\operatorname{diam}(H(p,n))\le\frac1{n+1}$ 。

原书证明取**最左**的等宽条带 $\big[\frac{m}{n+1},\frac{m+1}{n+1}\big]$
（最小自然数解，否则最大负整数解）与 $p$ 相交，令 $a,b$ 为交的
下、上确界，断言 $p\cap[a,b]$ 完备。**这一断言在两种边角下失败**：

- 反例一（交为单点）：$p=[1,\tfrac32]$ 完备，$n=0$ ，条带
  $[0,1]$ 与 $p$ 交于 $\{1\}$ ，$a=b=1$ ，$p\cap[a,b]=\{1\}$
  不是完备集。
- 反例二（端点孤立）：$p=[0,\tfrac12]\cup[1,\tfrac32]$ 完备，
  $n=0$ ，条带 $[0,1]$ ，$a=0,b=1$ ，
  $p\cap[0,1]=[0,\tfrac12]\cup\{1\}$ ，$1$ 是孤立点。

（原页该处不等式亦有 OCR 损毁；无论 $\le$ 还是别的写法，完备性
断言本身需要额外假设，例如条带内部与 $p$ 相交且切口两侧有 $p$
的聚点。）因此定理 3.22 本文按下述方式重建，不再依赖 $H$ 。

**定理 3.22 的重建证明（$\ge$ 方向）**。设 $F$ 完备。对每个
$s\in\mathrm{Seq}(\{0,1\})$ 指定一个**有理闭区间** $J_s$ ，满足：

1. $J_{\langle\rangle}$ 任取（其内部与 $F$ 相交即可：取
   $x\in F$ 与很小的有理邻域）；
2. $J_{s\frown 0}$ 与 $J_{s\frown 1}$ 的内部互不相交，都含于
   $J_s$ 的内部，且长度 $\le 2^{-(|s|+1)}$ ；
3. $J_s\cap F\ne\varnothing$ 。

构造可行：给定 $J_s\ni x$ （$x\in F$ ），$F$ 无孤立点使 $x$
是 $F$ 的极限点，于是 $F$ 在 $x$ 的左右两侧任意近处都有点；
在 $J_s$ 内部 $x$ 的左右各取一个 $F$ 的点，再各套一个小的有理
闭区间即得两个子节点（互不相交、长度减半、各交 $F$ ）。

对 $f\in 2^\omega$ ，闭区间套 $\langle J_{f\restriction n}\rangle$
长度趋于 0，由第 80 章区间套定理有唯一交点 $d_f$ ；每层取
$x_n\in J_{f\restriction n}\cap F$ ，则 $x_n\to d_f$ ，而 $F$
闭，故 $d_f\in F$ 。若 $f\ne g$ 首次分歧于 $n$ ，则
$d_f,d_g$ 分别属于内部不交的闭区间 $J_{f\restriction(n+1)}$ 、
$J_{g\restriction(n+1)}$ ，故 $d_f\ne d_g$ 。于是
$f\mapsto d_f$ 是 $2^\omega$ 到 $F$ 的单射。∎

这个证明与事实一（康托尔集）的 $f\mapsto d_f$ 完全同构：任何完备
集内部都藏着一棵「康托尔骨架」。原书的 $G_0/G_1$ 机器（完备集可
拆成两个不相交完备子集）本身成立且常被引用，作为推论保留：

**推论（拆分）**。每个完备集是两个不相交完备子集之并的一部分；
特别地，完备集的任何非空相对开子空间都无穷。

## 81.9 完备集定理：闭集的二分（定理 3.23、引理 3.9–3.12）

> **定义** $a$ 是 $A$ 的**凝聚点**，若对任意 $\varepsilon>0$ ，
> $\{x\in A:|x-a|<\varepsilon\}$ 不可数；全体凝聚点记 $A^*$ 。
> $a$ 是**极限点**，若任意 $\varepsilon>0$ 有 $x\in A$ 使
> $0<|x-a|<\varepsilon$ ；全体极限点 $A'$ 是导出集。

> **引理 3.9** $A$ 闭当且仅当 $A'\subseteq A$ 。
> （$\alpha\notin A$ 时 $\mathbb R\setminus A$ 开，给出隔离邻域；
> 反之每个余集点有隔离邻域即开。）

> **引理 3.10** $A^*$ 闭。
> （设 $\alpha$ 是 $A^*$ 的极限点；对 $\varepsilon>0$ 取
> $\beta\in A^*$ ，$0<|\beta-\alpha|<\varepsilon$ ，令
> $\eta=\varepsilon-|\beta-\alpha|>0$ ，则
> $\{y\in A:|y-\beta|<\eta\}\subseteq\{y\in A:|y-\alpha|<\varepsilon\}$
> 且不可数。）

> **引理 3.11** $F$ 闭则 $F^*\subseteq F$ （引理 3.9：凝聚点是
> 极限点）且 $F\setminus F^*$ 至多可数。
> （$x\in F\setminus F^*$ 有 $\varepsilon$ 使 $F\cap (x-\varepsilon,x+\varepsilon)$ 可数，取有理区间
> $(r,s)\ni x$ 含于其中；把 $x$ 归入可数族
> $\{F\cap(r,s):(r,s)\in\mathbb Q^2,\ r<s,\ F\cap(r,s)\text{ 可数}\}$
> 的并；由可数选择公理，可数个可数集之并可数。）

> **引理 3.12** $F$ 不可数闭则 $F^*$ 是完备集。
> （$F^*$ 闭且非空——否则 $F=F\setminus F^*$ 可数；无孤立点：
> 若 $(\alpha-\delta,\alpha+\delta)\cap F^*=\{\alpha\}$ ，则
> $(\alpha-\delta,\alpha+\delta)\cap F\subseteq\{\alpha\}\cup (F\setminus F^*)$ 可数，与 $\alpha\in F^*$ 矛盾。）

> **定理 3.23（完备集定理）** 每个不可数闭集含完备子集（其凝聚点
> 集）；从而每个闭集或可数或势为 $2^{\aleph_0}$ 。

**证明**。$F$ 不可数闭：$F^*$ 完备且 $F^*\subseteq F$ ；引理
3.11 给出 $F=F^*\cup(F\setminus F^*)$ ，后者可数，故
$\operatorname{card}(F)=\operatorname{card}(F^*)=2^{\aleph_0}$
（定理 3.22）。∎

康托尔**求导**过程把这件事变成超穷迭代：

$$A^{(0)}=A,\qquad A^{(\alpha+1)}=(A^{(\alpha)})',\qquad A^{(\lambda)}=\bigcap_{\alpha<\lambda}A^{(\alpha)}.$$

对闭集 $F$ ，每一步严格下降至少去掉一个孤立点，而 $F\setminus F^*$ 可数，故在某个 $\alpha<\omega_1$ 处稳定：$F^{(\alpha)}= F^{(\alpha+1)}=F^*$ （可数闭集在可数步内耗尽，一般闭集因
$F\setminus F^*$ 可数也不超过 $\omega_1$ 步）。这正是「序数被
发明出来的最初激励」：去掉孤立点的次数本身可以是任何可数序数。

原书随后的加强只陈述不证明，此处同样如实转述并给出出处方向：每个
不可数**博雷尔**集、每个不可数**解析**集都含完备子集（Suslin，
1917；本教程第 82 章将证解析集版本）。这是 ZFC 内对问题 3.6/3.7 的
最好回答；「每个不可数射影集含完备子集」则越出 ZFC，需弱于可测的
大基数（第三卷 111–113 章）。

## 81.10 伯恩斯坦集合（定理 3.24）

> **定理 3.24** 假设选择公理，则存在与 $\mathbb R$ 等势、但不含
> 任何非空完备子集的实数集合。

**证明**。令 $\langle P_\alpha\mid\alpha<2^{\aleph_0}\rangle$ 列出
全体非空完备集，$\langle a^\alpha_\beta\mid\beta<2^{\aleph_0}\rangle$ 列出 $P_\alpha$ 的元素。递归定义两个不相交序列
$\langle b_\alpha,c_\alpha\mid\alpha<2^{\aleph_0}\rangle$ ：

$$\beta_0=\min\{\beta: a^\alpha_\beta\notin \{b_\xi,c_\xi:\xi<\alpha\}\},\qquad b_\alpha=a^\alpha_{\beta_0},$$

$$\beta_1=\min\{\beta: a^\alpha_\beta\notin \{b_\alpha\}\cup\{b_\xi,c_\xi:\xi<\alpha\}\},\qquad c_\alpha=a^\alpha_{\beta_1}.$$

每个 $P_\alpha$ 有 $2^{\aleph_0}$ 个元素（定理 3.22），而已排除
的不足 $2^{\aleph_0}$ 个，故 $\beta_0,\beta_1$ 存在。令
$A=\{b_\alpha\}$ 、$B=\{c_\alpha\}$ ：两集不交、都等势于
$\mathbb R$ ，且都**处处碰**完备集——$b_\alpha,c_\alpha\in P_\alpha$ 。若 $A$ 含非空完备子集 $P$ ，则 $P=P_\alpha$ 对某个
$\alpha$ ，但 $c_\alpha\in P_\alpha\subseteq A$ 与
$c_\alpha\in B$ 、$A\cap B=\varnothing$ 矛盾。∎

于是问题 3.6 的答案是否定的；问题 3.7（「简单」不可数实数集是否都
含完备子集）的答案按复杂度分层：博雷尔、解析——是（ZFC 内）；射影
——需要大基数；全体——在 $\mathrm{AD}$ 下是（第 122 章）。

## 81.11 三种正则性总账

| 正则性 | 「几乎等于」 | 反例（AC 下） | ZFC 内的肯定范围 | 更强假设下 |
|---|---|---|---|---|
| 贝尔性质 | 开集，差稀疏 | 维塔利集 | 全体博雷尔集（命题 3.3） | MA：$<2^{\aleph_0}$ 个稀疏集之并稀疏（定理 3.19）；大基数：射影集 |
| 勒贝格可测 | 博雷尔集，差零测 | 维塔利集 | 全体博雷尔集 | MA：$<2^{\aleph_0}$ 个零测集之并零测（定理 3.21）；AD：全体 |
| 完备子集特性 | 含 $2^{\aleph_0}$ 大的完备闭核 | 伯恩斯坦集 | 不可数博雷尔/解析集 | 大基数：射影集；AD：全体不可数集 |

三个「几乎」共享同一套语法：取一个非平凡 $\sigma$ -理想，问哪些集合
模它等于一个「简单」集合。差异全在理想与简单类的选择上；而三条
反例线（维塔利、伯恩斯坦）都依赖选择公理的程度，本身就指示了
「可定义集合」方向的一切肯定定理为什么可能——可定义集合躲开了
选择公理制造的病理。

## 81.12 机器通道一：Lean——贝尔纲与测度的官方锚点

本章的三个无限定理中，贝尔纲定理是 mathlib 已经完整发展的那一个。
`BaireSpace` 类型类以「可数个稠密开集之交稠密」为公理，而实数通过
「完备可伪度量化空间是贝尔空间」的实例（优先级 100）自动获得该类。
下面第一个声明把这条实例路线显式接出来；注意它没有任何有限退化——
这是货真价实的无限定理的再出口，与后四个声明的「登记接口」性质不同。

`IsMeagre` 是 mathlib 对「稀疏」的编码（可数个无处稠密集之并），
`not_isMeagre_of_isOpen` 正是推论 3.2 的拓扑内核。`Real.volume_Icc`
给出事实 (1) 的区间版本。零测集的可测性 mathlib 走的是「完备测度」
类 `Measure.IsComplete` 与 `Measure.completion`：`volume` 本身是否
完备取决于构造路线，mathlib 没有全局实例，于是我们登记两个总是成立
的接口——任意测度下零测集有**可测零覆盖**，以及完备化必完备。

```lean
import Mathlib

/-!
# 第 81 章 · 实数子集的正则性

登记 mathlib 中真正的贝尔纲定理、非空开集非稀疏、勒贝格区间测度，
以及零测集的两种可测性接口。有限例子只承担离散计算，
不参与这些无限定理的证明。
-/

namespace Settheory.Ch81

open Set MeasureTheory

/-- 实数是贝尔空间：可数个稠密开集的交仍稠密。 -/
theorem real_baire {ι : Type*} [Countable ι] {U : ι → Set ℝ}
    (hopen : ∀ i, IsOpen (U i)) (hdense : ∀ i, Dense (U i)) :
    Dense (⋂ i, U i) :=
  dense_iInter_of_isOpen hopen hdense

/-- 非空开集不能是可数个无处稠密集合的并（第二纲）。 -/
theorem open_not_meagre {s : Set ℝ} (hs : IsOpen s) (hne : s.Nonempty) :
    ¬ IsMeagre s :=
  not_isMeagre_of_isOpen hs hne

/-- 闭区间的勒贝格测度就是区间长度。 -/
example (a b : ℝ) : volume (Icc a b) = ENNReal.ofReal (b - a) :=
  Real.volume_Icc

/-- 零测集总有可测零覆盖：这是「零测集可测」的完备化前形式。 -/
theorem null_has_measurable_cover (s : Set ℝ) (hs : volume s = 0) :
    ∃ t, s ⊆ t ∧ MeasurableSet t ∧ volume t = 0 :=
  exists_measurable_superset_of_null hs

/-- 完备测度上零测集直接可测；这是书中事实 (5) 的 mathlib 对应物。 -/
example (μ : Measure ℝ) [μ.IsComplete] {s : Set ℝ} (hs : μ s = 0) :
    MeasurableSet s :=
  measurableSet_of_null hs

/-- 每个测度的完备化都完备，故完备化上零测集皆可测。 -/
example (μ : Measure ℝ) : μ.completion.IsComplete :=
  inferInstance

end Settheory.Ch81
```

四个要点。其一，`dense_iInter_of_isOpen` 的指标类型只要 `Countable`，
比书里的 $\omega$ 序列更宽，但证明内容相同。其二，`IsMeagre` 与
稀疏理想的对应在 `Mathlib.Topology.Baire.Lemmas`，同一文件里还有
`dense_iInter_of_Gδ` 等一系列 81.2–81.4 用得上的形式。其三，
`null_has_measurable_cover` 对**任意**测度成立——它就是「把零测集
塞进可测零壳」的普遍事实，比勒贝格专属。其四，书中事实 (5) 的完整
表述「零测子集皆可测」在 mathlib 里等于 `volume.IsComplete`；本章
不假设它，而是把完备化路线一并登记，教学上更诚实。

## 81.13 机器通道二：Isabelle/ZF——有限理想与模二余类

ZF 对象逻辑没有实数拓扑，本章取两个最小的集合论影子：两点全集
$2=\{0,1\}$ 的幂集作为理想，以及四元全集上的模二同余作为「实数
模 $\mathbb Q$ 」的商关系替身。

```isabelle
theory Regularity
  imports "ZF.Nat"
begin

text \<open>第 81 章：两点幂集上的一个理想，以及模二余类关系。
这些有限对象只核对理想封闭和商关系，不模拟实数的 σ-理想。\<close>

definition K2 :: "i" where "K2 \<equiv> succ(succ(0))"
definition O3 :: "i" where "O3 \<equiv> succ(2)"
definition K4 :: "i" where "K4 \<equiv> succ(O3)"
definition I2 :: "i" where "I2 \<equiv> Pow(K2)"
definition Mod2 :: "i" where
  "Mod2 \<equiv> {\<langle>0,0\<rangle>, \<langle>0,2\<rangle>, \<langle>2,0\<rangle>, \<langle>2,2\<rangle>,
             \<langle>1,1\<rangle>, \<langle>1,O3\<rangle>, \<langle>O3,1\<rangle>, \<langle>O3,O3\<rangle>}"

lemma I2_empty: "0 \<in> I2"
  by (simp add: I2_def)

lemma I2_downward: "A \<in> I2 \<Longrightarrow> B \<subseteq> A \<Longrightarrow> B \<in> I2"
  by (auto simp add: I2_def K2_def)

lemma I2_union: "A \<in> I2 \<Longrightarrow> B \<in> I2 \<Longrightarrow> A \<union> B \<in> I2"
  by (auto simp add: I2_def K2_def)

lemma Mod2_refl: "x \<in> K4 \<Longrightarrow> \<langle>x,x\<rangle> \<in> Mod2"
  by (auto simp add: Mod2_def K4_def O3_def)

lemma Mod2_sym: "\<langle>x,y\<rangle> \<in> Mod2 \<Longrightarrow> \<langle>y,x\<rangle> \<in> Mod2"
  by (auto simp add: Mod2_def)

lemma Mod2_trans: "\<langle>x,y\<rangle> \<in> Mod2 \<Longrightarrow> \<langle>y,z\<rangle> \<in> Mod2 \<Longrightarrow> \<langle>x,z\<rangle> \<in> Mod2"
  by (auto simp add: Mod2_def O3_def)

end
```

`I2 = Pow(K2)` 恰是两点全集上的最大理想（全幂集）：空集在内、对
子集封闭、对二元并封闭——理想公理的有限层全部核对。它**没有**核对
的是 $\sigma$ -可加性：有限并到可数并的跃迁在有限模型中无从表述，
这正是 81.2 推论 3.3 必须由贝尔纲定理支撑的原因。

`Mod2` 把 $K4=\{0,1,2,3\}$ 分成偶类 $\{0,2\}$ 与奇类
$\{1,3\}$ ，三条引理验证等价关系律。维塔利构造在无限侧的「每个
$\mathbb Q$ -类恰取一代表」在有限侧对应「每类恰取一代表」，而
有限侧的代表集毫无病理（见 81.17 的 Python 对比）。

实现上有一条 ZF 词汇限制要记录：ZF 对象逻辑的内建数字缩写只到
2，`3` 不能直接写在项的位置，必须用 `succ(2)`（即 `O3`）乃至
`succ(O3)`（即 `K4`）展开——第 93 章首次撞上，这里沿用。

## 81.14 机器通道三：Coq——理想封闭律与模 Q 等价

Coq 通道把 81.4 的「新封闭律是旧公理的推论」的推理风格做实：
理想的「对交封闭」**不是**一条公理，而是「交是成员的子集 + 理想
对子集封闭」的一行推论——正文中定理 3.20 对补封闭的证明（差集
平移不改变对称差）用的是同一种「先认出代数恒等式，再引用封闭律」
的两步走。随后用 `Q2R` 嵌入把「实数模 $\mathbb Q$ 」的等价关系律
逐条证掉。

```coq
(* 第 81 章：有限布尔理想与实数模有理数等价关系。 *)
From Coq Require Import QArith Qreals Reals Lra.

Module Ch81.

Definition subset := bool -> Prop.
Definition empty : subset := fun _ => False.
Definition union (A B : subset) : subset := fun x => A x \/ B x.
Definition inter (A B : subset) : subset := fun x => A x /\ B x.

Record Ideal (I : subset -> Prop) : Prop := {
  ideal_empty : I empty;
  ideal_down : forall A B, I A -> (forall x, B x -> A x) -> I B;
  ideal_union : forall A B, I A -> I B -> I (union A B)
}.

(* 理想对交也封闭：交只是任一成员的子集，不需要另加一条公理。 *)
Theorem ideal_inter : forall I (H : Ideal I) A B,
  I A -> I B -> I (inter A B).
Proof.
  intros I H A B HA HB.
  apply (ideal_down I H A); auto.
  intros x Hx. exact (proj1 Hx).
Qed.

Open Scope R_scope.

Definition qmod (x y : R) : Prop := exists q : Q, x - y = Q2R q.

Lemma qmod_refl : forall x, qmod x x.
Proof.
  intro x. exists 0%Q. unfold Q2R. cbn. ring.
Qed.

Lemma qmod_sym : forall x y, qmod x y -> qmod y x.
Proof.
  intros x y [q Hq]. exists (-q)%Q.
  rewrite Q2R_opp. lra.
Qed.

Lemma qmod_trans : forall x y z, qmod x y -> qmod y z -> qmod x z.
Proof.
  intros x y z [q Hq] [r Hr]. exists (q+r)%Q.
  rewrite Q2R_plus. lra.
Qed.

(* 离散样本：4/3 与 1/3 模 Q 同余，差恰为有理数 1。 *)
Example qmod_sample : qmod (Q2R (4#3)) (Q2R (1#3)).
Proof. exists 1%Q. unfold Q2R. cbn. field. Qed.

End Ch81.
```

`qmod` 三律的证明结构值得念一遍：对称律用 `Q2R_opp`（$-q$ 的
像等于像的相反数）把差翻号，传递律用 `Q2R_plus` 拆和，剩下的纯
实数线性等式交给 `lra`。自反律的见证是 `0`，这里有个实测坑：
`Q2R 0` 在 `cbn` 默认力度下不动，`ring` 拒绝；必须 `unfold Q2R`
先显形为 `0 * /1` 之类的原始项再化简。样本 `4/3 - 1/3 = 1` 与
81.17 的 Python 商实验共用同一算术事实。

这组引理是 81.5 维塔利证明的「等价关系律」部分的机器化；至于
「任何维塔利集都不具贝尔性质」，其证明需要 81.2 的无限贝尔纲，
Coq 通道不触碰。

## 81.15 机器通道四：Agda——完备二叉树的分支

定理 3.22 的骨架是「每个节点都能继续分岔」：完备集无孤立点，所以
任何邻域里都有下一个分歧点。Agda 通道把这句话做成一个**依树索引的
分支族**：`Path t` 是树 `t` 的从根到叶的分支，`perfect n` 是深度
$n$ 的满二叉树；「第 $n$ 层有 $2^n$ 条分支，每条深度恰为
$n$ 」就是康托尔映射 $f\mapsto d_f$ 的构造性前半。

```agda
-- 第 81 章：完备二叉树的内在分支及其深度。
module Ch81_regularity where

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

data Tree : Set where
  leaf : Tree
  node : Tree → Tree → Tree

-- Path t 是树 t 的一条从根到叶的分支；构造子保证不会提前停止。
data Path : Tree → Set where
  stop : Path leaf
  left : ∀ {l r} → Path l → Path (node l r)
  right : ∀ {l r} → Path r → Path (node l r)

depth : ∀ {t} → Path t → ℕ
depth stop = 0
depth (left p) = suc (depth p)
depth (right p) = suc (depth p)

perfect : ℕ → Tree
perfect zero = leaf
perfect (suc n) = node (perfect n) (perfect n)

depth-perfect : ∀ {n} (p : Path (perfect n)) → depth p ≡ n
depth-perfect {zero} stop = refl
depth-perfect {suc n} (left p) = cong suc (depth-perfect p)
depth-perfect {suc n} (right p) = cong suc (depth-perfect p)

count : Tree → ℕ
count leaf = 1
count (node l r) = count l + count r

pow2 : ℕ → ℕ
pow2 zero = 1
pow2 (suc n) = pow2 n + pow2 n

count-perfect : ∀ n → count (perfect n) ≡ pow2 n
count-perfect zero = refl
count-perfect (suc n) rewrite count-perfect n = refl

-- 第 3 层有 8 条分支，每条分支的深度都是 3。
eight-branches : count (perfect 3) ≡ 8
eight-branches = refl

sample-path : Path (perfect 2)
sample-path = right (left stop)

sample-depth : depth sample-path ≡ 2
sample-depth = refl
```

`depth-perfect` 的写法记录了 Agda 的一个统一性限制：`Path (perfect n)`
是**依值**族，直接写 `stop` 分支会让统一器面对 `leaf ≟ perfect n`
卡死；必须先把隐式参数 `{zero}` / `{suc n}` 分层，再给构造子模式。
这与第 80 章二分区间「第 n 层分母是 $2^n$ 」的显式分层是同一条
纪律：归纳结构在索引里时，分层责任在证明者。

`count-perfect` 说满二叉树第 $n$ 层恰有 $2^n$ 条分支——
$2^\omega$ 条分支对应康托尔集的势（事实一），而「每层都能再分」
对应完备集无孤立点（事实二）。区间套收敛的那一步（$d_f$ 的存在）
是无限对象，Agda 不做。

## 81.16 机器通道五：Julia——康托尔区间的精确算术

Julia 用 `Rational{BigInt}` 把康托尔构造的前 8 层算成精确有理数：
每层区间个数、单个区间长度、两两分离、总长 $(2/3)^k$ ，全部断言。

```julia
# 第 81 章：Cantor 区间的精确有理数有限层实验。
println("==== 81")

function children(interval)
    a, b = interval
    third = (b-a)//big(3)
    return ((a, a+third), (b-third, b))
end

function cantor_levels(n)
    levels = [[(big(0)//big(1), big(1)//big(1))]]
    for k in 1:n
        previous = levels[end]
        current = Tuple{Rational{BigInt},Rational{BigInt}}[]
        for interval in previous
            left, right = children(interval)
            @assert interval[1] <= left[1] < left[2] <= interval[2]
            @assert interval[1] <= right[1] < right[2] <= interval[2]
            @assert left[2] < right[1]
            push!(current, left, right)
        end
        @assert length(current) == 2^k
        @assert all(b-a == (big(1)//big(3))^k for (a,b) in current)
        @assert all(current[i][2] < current[i+1][1] for i in 1:length(current)-1)
        push!(levels, current)
    end
    return levels
end

levels = cantor_levels(8)
for k in 0:8
    total = sum(b-a for (a,b) in levels[k+1])
    @assert total == (big(2)//big(3))^k
end
@assert length(levels[end]) == 256
@assert levels[5][3] == (big(2)//big(27), big(7)//big(81))
println("Julia：第 8 层有 256 个两两分离的闭区间，每个长 3^-8")
println("第 k 层总长度恰为 (2/3)^k（0≤k≤8）；极限零测与完备性另由正文证明")
println("END ====")
```

`children` 保持三分之一为精确分数而不做除法；每层的四条断言分别
对应正文 81.7 的四条归纳不变量：子区间落在父区间内、左右分离、
个数翻倍、长度 $3^{-k}$ 。总长断言 $\sum=(2/3)^k$ 是「$C$ 零测」
的有限层证据；取极限 $k\to\omega$ 、以及 $C$ 完备（事实二），
属于正文。

样本 `levels[5][3]`（第 $k=4$ 层字典序第 3 个区间）是
$[2/27,\ 7/81]$ ：三进制保留数字串 $0020$ ，左端
$2/27=0.0020_3$ ，右端加一个 $3^{-4}=1/81$ 。核对这类「具体
区间长什么样」的断言，最好先手算再写进断言——本实验最初把
$7/81$ 写成 $1/9$ ，被断言当场抓住。

## 81.17 机器通道六：Python——有限商上的代表选择

维塔利构造的「选代表」一步在任何等价关系上都能走；病理出在
$\mathbb Q$ 平移的无限性。Python 通道在 24 点循环群上完整走一遍：
按 $\tfrac14$ 步长的轨道分类、取代表、四个平移拼回全域。

```python
# 第 81 章：有限循环群上的 Vitali 式商与代表选择。
from fractions import Fraction
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

N = 24
STEP = Fraction(1, 4)
UNIVERSE = {Fraction(j, N) for j in range(N)}
TRANSLATIONS = {k * STEP for k in range(4)}


def orbit(x):
    return frozenset((x+q) % 1 for q in TRANSLATIONS)


def translate(a, q):
    return frozenset((x+q) % 1 for x in a)


def main():
    print("==== 81")
    classes = {orbit(x) for x in UNIVERSE}
    assert len(classes) == 6
    assert all(len(c) == 4 for c in classes)
    assert set().union(*classes) == UNIVERSE
    assert all(c == d or not (c & d) for c in classes for d in classes)
    selector = frozenset(min(c) for c in classes)
    assert len(selector) == 6
    assert all(len(selector & c) == 1 for c in classes)
    pieces = [translate(selector, q) for q in sorted(TRANSLATIONS)]
    assert set().union(*pieces) == UNIVERSE
    assert all(not (pieces[i] & pieces[j])
               for i in range(4) for j in range(i))
    print("Python：24 点按 1/4-平移分成 6 类；代表集 6 点，四个平移恰好分割全域")
    print("这是有限群商实验，不是实数模 Q 的 Vitali 集，也不产生不可测性")
    print("END ====")


if __name__ == "__main__":
    main()
```

结构与 81.5 完全同构：24 点按「差为四分之一整数倍（模 1）」分成
6 个 4 点类；代表集每类取 `min`；四个平移 $\{0,\tfrac14,\tfrac12, \tfrac34\}$ 把代表集拼成全域的不交并。差别在结论：**有限商上这个
代表集没有任何病理**——给它配上均匀计数测度，四个平移块各 6 点，
测度完全可加。不可测性不可能在有限群上发生：有限测度自动完备、
所有子集可测。维塔利病理真正用到的是「不可数多个类 + 平移可任意
接近 + 可数可加」三者的合力，81.5 的两个矛盾情形（测度 0 与测度
正）都消耗这个合力。程序最后一行把这句话印出来，防止误读。

## 81.18 机器通道七：Prolog——对称差代数

定理 3.20 的代数核心是对称差的两条恒等式：
$A\triangle B=(A\setminus B)\cup(B\setminus A)$ 与
$A^\complement\triangle B^\complement=A\triangle B$ （补封闭一步）。
Prolog 在四位全集上把全部 $16\times16$ 对子集穷举核对。

```prolog
:- encoding(utf8).
% 第 81 章：四位全集上的对称差代数。掩码 0..15 穷举全部子集。

symdiff(A, B, S) :- S is (A xor B).
complement4(A, C) :- C is (15 xor A).

symdiff_by_union(A, B, S) :-
    L is A /\ (15 xor B),
    R is B /\ (15 xor A),
    S is L \/ R.

mask(M) :- between(0, 15, M).

main :-
    format("==== 81~n"),
    forall((mask(A), mask(B)),
           (symdiff(A, B, S), symdiff_by_union(A, B, S))),
    forall((mask(A), mask(B)),
           (complement4(A, CA), complement4(B, CB),
            symdiff(CA, CB, S0), symdiff(A, B, S0))),
    forall(mask(A), (symdiff(A, A, 0), symdiff(A, 0, A))),
    symdiff(6, 10, 12),
    writeln("Prolog：256 对掩码均通过 Δ=(差集并)与补集不变式"),
    writeln("样本 {1,2} Δ {1,3} = {2,3}（掩码 6 Δ 10 = 12）✓"),
    writeln("END ====").
```

`symdiff` 用按位异或实现 $\triangle$ ，`symdiff_by_union` 用「差集
之并」独立实现同一个函数；第一条 `forall` 断言两者在全部 256 对上
一致，即恒等式 $A\triangle B=(A\setminus B)\cup(B\setminus A)$ 。
第二条断言补集不变式：先补后差等于先差，这正是 81.4 中
「$(\mathbb R\setminus A)\triangle(\mathbb R\setminus B)=A\triangle B$ 」
的位运算化身。第三条与样本断言核对幂等律与一个具体例子。恒等式
在有限全集上成立当然不证明 $\sigma$ -代数封闭——那是关于可数并的
陈述；但它核实了封闭性证明中用到的每一步代数。

## 81.19 机器的边界：哪些结论永远不出现在 examples 里

本章的七份代码全部是**有限**对象；把它们与正文的无限定理划清界限，
与定理本身同样重要：

1. **贝尔纲定理**（81.2）依赖实数的完备性（经由区间套定理）。任何
   有限全集中「稠密开集」的交当然可以照算，但那只是拓扑公理的平凡
   推论，不含完备性输入；mathlib 的 `dense_iInter_of_isOpen` 是真
   定理，因为 `BaireSpace ℝ` 实例背后是柯西完备性。
2. **Martin–Solovay 定理**（81.3/81.6）是 $\mathrm{MA}$ （独立于
   ZFC）加 $2^{\aleph_0}$ 规模的力迫论证。有限偏序上的滤子构造
   （如 Prolog 第 80 章对 FIP 的做法）可以演示语法，不可能承载
   「$<2^{\aleph_0}$ 个理想元素之并仍在理想内」的语义。
3. **维塔利与伯恩斯坦的反例**（81.5/81.10）需要选择公理作用于
   **不可数**等价类族 / 完备集族。81.17 的有限商实验特意展示同一
   构造在有限侧毫无病理：不可测性、非贝尔性是无限专属现象。
4. **完备集定理与定理 3.22**（81.8/81.9）是关于 $2^{\aleph_0}$
   与 $\omega_1$ 的陈述。Agda/Julia 的二叉树与区间计算给出构造
   的有限层证据；「每个分支收敛到 $F$ 的点」需要区间套定理，
   「导出过程在 $\omega_1$ 内稳定」更是纯超穷陈述。

因此，本章任何断言为 PASS 的实验，都不构成上述四条定理任何形式的
机器证明；它们验证的是定理证明中**可离散化的代数骨架**。

## 81.20 本章要点与检查问题

三个正则性，一套语法：「模某非平凡 $\sigma$ -理想，几乎等于某简单
类」。

- 稀疏理想 $\mathcal I_c$ 与零测理想 $\mathcal I_m$ 都是非平凡
  $\sigma$ -理想；非平凡性分别由贝尔纲定理与「$[0,1]$ 测度为 1」
  支撑。两个理想互不包含（刘维尔数 / 胖康托尔集）。
- 贝尔性质类 $\mathcal C$ 与可测类 $\mathcal M$ 都是包含博雷尔
  代数的 $\sigma$ -代数；$\mathrm{MA}$ 把两个理想的可加性推到
  $2^{\aleph_0}$ （定理 3.19、3.21，共享「可数反链 + 稠密集
  滤子」引擎）。
- 维塔利集合同时否定 $\mathcal C=\mathcal P(\mathbb R)$ 与
  $\mathcal M=\mathcal P(\mathbb R)$ ；伯恩斯坦集合否定「不可数
  ⇒ 含完备子集」。三个反例都用足选择公理。
- 闭集被彻底二分（定理 3.23）：可数或 $2^{\aleph_0}$ ，凝聚点集
  就是那个完备核；康托尔求导在 $\omega_1$ 内稳定。
- 定理 3.22 的机器无关证明按有理闭区间二叉树重建（81.8），原书
  引理 3.8 的完备性断言有两种边角反例；「完备集可拆两个不相交完备
  子集」（引理 3.6/3.7）成立并保留。

检查问题：

1. 把 81.5 情形二的论证里「$A\cap I$ 在 $I$ 中余稀疏」换回
   「$A$ 稀疏」，哪一步会失效？为什么情形一必须用
   $\mathbb Q\cap[-1,1]$ 而不是全体 $\mathbb Q$ ？
2. 定理 3.21 的偏序里，若把「强 = 超集」误写为「强 = 子集」，证明
   中哪一环首先崩溃？（提示：滤子元素的有限并何时仍在 $P$ 内？）
3. 把条带选取从「相交非空」加强为「相交**无穷**」的 最左条带，
   能否救回引理 3.8 的完备性断言？（反例二 $p=[0,\tfrac12]\cup [1,\tfrac32]$ 的 $p\cap[0,1]=[0,\tfrac12]\cup\{1\}$ 本身就是
   无穷交，直接回答。）若再加强为「$p\cap$ 条带不可数」呢？

---

上一章：[80 实数轴、连续统与实数拓扑](80-reals.md) · 下一章：[82 贝尔空间、波兰空间、投影集与博弈](82-polish.md)
