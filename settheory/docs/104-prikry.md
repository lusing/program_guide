# 104 · Prikry 力迫

> 第 103 章的两台机器各管一头：小型力迫全保（定理 2.1），Lévy
> 崩塌定向破坏（κ 变 ω₁）。本章取材冯琦第三卷 §2.3（书页
> 156–160；PDF 176–181）展示第三种格：**保基数、改共尾度、
> 不加有界子集**——Prikry 力迫把可测基数 $\kappa$ 的共尾度
> 改成 $\omega$ 而不添任何 $<\kappa$ 的新子集、不动任何
> $\ge\kappa$ 的基数。条件是序对 $(s,A)$ ：stem $s\in[ \kappa]^{<\omega}$ + 测度一集 $A\in D$ （定义 2.6）；
> $(s,A)\le(t,B)$ 当且仅当 $t$ 是 $s$ 的初始段、
> $A\subseteq B$ 、$s\setminus t\subseteq B$ 。机器的
> 心脏是**判定引理**（引理 2.4/2.5）：任何语句可被**不动
> stem** 的条件判定——证明把 $[\kappa]^{<\omega}$ 三染色
> 后用可测基数的拉姆齐性（第 94 章定理 1.6）取**整齐集**
> $A$ 。定理 2.6 给出三款后果（κ⁺-cc 保上、cf(κ)=ω、无新
> 有界子集）；Mathias 定理 2.7 把泛型滤子与**Prikry 序列**
> （序型 ω、无界、几乎含于每个测度一集）互相确定；定理 2.8
> 合拢迭代超幂线：$\omega$ 次迭代超幂的**临界点序列恰是
> $M_\omega$ 中的 Prikry 序列**，且 $M_{\omega}[G(X)]= N$ ——第 97 章的「无差别元序列」在此获得力迫论身份。
>
> 机器边界：判定引理的拉姆齐取整、泛型性、迭代超幂全在
> 超穷层；七个通道做**条件层**——stem 递增序（Lean/Coq/
> Agda/Prolog 四套 stem 良形与初始段判定）、纯延长的自反/
> 传递（Task 19 Step 2 指定件，七通道各一份）、事实 2.3.1
> 交条件双侧纯延长、**R(3,3)=6 全染色穷举**（判定性的拉姆齐
> 内核：Julia/Python 各 32768 例）、Prikry 序列候选生成与
> G(X) 成员判定（Mathias 定理的有限影子）。

## 104.1 动机与条件：第四种力迫格

第 103 章末尾立了三本账：保基数（组合论）、可数化（稠密性
工程）、保见证（嵌入代数）。Prikry 1970 的问题是：**能否
只改共尾度而不付前两本账的代价**？动机直指奇异基数假设
（书 p156）：若 $\kappa$ 可测被改成 cf(κ)=ω 的强极限
奇异基数且 $2^\kappa$ 超标，SCH 在 $\kappa$ 处失败——
这需要「保基数（不塌）、改共尾度（到 ω）、不加有界子集
（保强极限）」三件同时成立，此前没有任何力迫能做到。根据
Jensen 覆盖引理（第 96 章），没有 $0^\#$ 就没有这种可能
——Prikry 力迫正是「可测基数 ⟹ 可能」的构造性见证。

> **定义 2.6** 设 $\kappa$ 可测，$D$ 是 $\kappa$ 上
> 非平凡 $\kappa$ -完全正规超滤子。令
> $$\mathbb P=\{(s,A)\mid s\in[\kappa]^{<\omega},\,A\in D\},$$
>
> $(s,A)\le(t,B)\iff$ ($t=s\cap\alpha$ 型初始段)$\wedge A\subseteq B\wedge(s\setminus t)\subseteq B$ 。

读法：条件 $(s,A)$ 承诺两件事——**stem** $s$ 是泛型
序列的确定前段；**测度一集** $A$ 是「未来的元素只会从
这里来」的约束。扩展有两条路：**stem 延长**（往 $s$ 里
从 $A$ 添新元素）与**纯延长**（不动 $s$ 、只把 $A$
收窄成子集 $A'\subseteq A$ ）。整个理论的张力就在这两条
路的分工：stem 延长改变泛型序列的内容，纯延长只改变约束
——判定引理说**任何语句的裁决只须用纯延长**。

这个条件设计的「分权」值得与此前两种力迫对照。**Lévy
力迫**（第 103 章）的条件是纯「占位表」——信息只有一种
（坐标-值对），扩展只有一条路（加对），冲突与稠密都发生
在同一个维度上；**Cohen/Martin 型**（第 89/91 章）加实数
的条件是有限部分函数，冲突来自坐标占位但**没有**测度一
集那种「未来约束」。Prikry 的两部件设计把「已确定」与
「待约束」**显式分离**：stem 是已确定层，$A$ 是约束层，
两者的动力学完全不同（前者有限增长、后者纯收窄）。这种
分离正是判定引理能成立的先决条件——裁决只依赖 stem 层，
所以能用纯延长（只动约束层）来达成裁决。第 105 章 Silver
力迫的 Easton 支撑、第 107 章恰当力迫的可数条件，都是
这种「分层条件」哲学的后裔。

数值感受一笔：stem 的可能形态只有 $\kappa^{<\omega}= \kappa$ 个（每个有限长选递增列），测度一集有 $2^\kappa$
个——**条件的「宽度」几乎全在测度一集层**，而「冲突层」
却全在 stem 层。这个不对称是 κ⁺-cc 的来源（每个 stem 类
内部两两相容，类间冲突由 stem 决定，故反链至多 $\kappa^+$ 长——精确地：每个反链的 stems 两两冲突，而两两冲突的
递增列族在 $\kappa$ 上至多 $\kappa$ 大？不——需要
Δ-系统式的论证？不需要：书 p156 的事实 2.3.1 直接断言
「不相容一定源于 stem 冲突」，而 stem 冲突的组合账在
$\kappa^{<\omega}=\kappa$ 内封顶，故 $\mathbb P$ 的
反链被 stem 的冲突族计数**一维化**——这正是 κ⁺-cc）。

> **事实 2.3.1** (i) $(s,A\cap B)\le(s,A)$ 且 $(s,A\cap B)\le(s,B)$ ；(ii) 若 $(s,A)$ 与 $(t,B)$ 不相容，则
> $s$ 与 $t$ 冲突（无公共延展的初始段）。故 $\mathbb P$
> 满足 $\kappa^+$ -链条件。

(i) 是交的纯延长性（机器通道 `fact231` 七份）；(ii) 说
**不相容只能来自 stem**——测度一集层面永远可以取交调和
（$D$ 对交封闭）。这与 Lévy 力迫的「冲突来自坐标占位」
（第 103 章）不同：Prikry 的冲突判据**一维化**到 stem
上，cc 证明因此只要数 stem 的可能冲突——每个 stem $s$
决定一个「stem-类」，类内全部相容（纯延长永不相冲突），
而互冲突的 stem 类的代表元只有 $\kappa^{<\omega}=\kappa$
个选择——$\kappa^+$ -cc。

## 104.2 判定引理：不动 stem 的裁决

> **引理 2.4（Prikry 性质）** 设 $\varphi$ 是力迫语言的
> 一个语句。那么一定存在 $A\in D$ 使 $(\emptyset,A)\Vdash \varphi$ 或 $(\emptyset,A)\Vdash\neg\varphi$ 。

**证明**（书 p157）的机制值得逐帧。把 $[\kappa]^{<\omega}$
三染色：
$$T^+=\{s\mid\exists B\in D\,((s,B)\Vdash\varphi)\},\quad T^-=\{s\mid\exists B\in D\,((s,B)\Vdash\neg\varphi)\},$$

$$T^0=[\kappa]^{<\omega}\setminus(T^+\cup T^-).$$

由第 94 章定理 1.6（可测 ⟹ $\kappa$ -拉姆齐：$\kappa$
的任何有限维染色有测一整齐集），取 $A\in D$ 使每个
$[A]^n$ 单色。反设两侧都不判定：$(s,X)\Vdash\varphi$ 、
$(t,Y)\Vdash\neg\varphi$ 且都 $\le(\emptyset,A)$ 。不妨
$|s|=|t|=n$ ，则 $s,t\in[A]^n$ 同色——同为 $T^+$ 与
$t\in T^-$ 矛盾。∎

三件机制各值一笔。**(1) 染色的对象是 stem 而非点**：
$T^\pm$ 按「stem 能否带出裁决」染色，$[\kappa]^{<\omega}$
的层次结构让拉姆齐性按维数 $n$ 分别取整——这是「可测
基数 = 有限维全拉姆齐」的逐维消费。**(2) 裁决与约束分离**：
$(s,B)\Vdash\varphi$ 的信息全部装进 stem 色（存在某 $B$
即可），纯延长方向（收窄 $B$ ）不干扰裁决——**裁决是
stem 的函数**。**(3) 空 stem 起点不损一般性**：引理 2.5
把起点推广到任意 $(s_0,A_0)$ （取 $A\subseteq A_1\subseteq A_0$ 且 $\min A_1>\max s_0$ ，在 $[A_1]^{<\omega}$ 上
重演）——「不动 stem」的精确定义。

> **引理 2.5** 设 $\varphi$ 是语句、$(s_0,A_0)\in \mathbb P$ 。那么存在 $A\subseteq A_0$ （$A\in D$ ）
> 使 $(s_0,A)\Vdash\varphi$ 或 $(s_0,A)\Vdash\neg \varphi$ 。

**有限拉姆齐内核**：机器通道把「可测 ⟹ 拉姆齐」的有限
影子做成 R(3,3)=6 的全染色穷举——$\{0..5\}$ 的 15 个
递增对 2-染色共 $2^{15}=32768$ 种，每种都有同色三元组。
这正是引理 2.4 证明中「$[A]^n$ 单色」的 $n=2$ 维情形：
三染色 $\to$ 同色对（二维情形的拉姆齐数是 3——「3 个
点 2 色必有同色对」）。**判定性 = 拉姆齐性**这个等式在
有限层完全可验算，是本章机器件与数学本体最紧的一处对接
（第 95 章的 R(3,3)=6 native_decide 样本在此第二次出场）。

本章在全教程力迫线上的位置可以用一句话钉住：**第 89–92
章造语法，第 103 章定规矩（小力迫全保/Lévy 定向破坏），
本章开「外科手术」时代**——此后 Silver（105）、SCH 反例
（106）、恰当力迫（107–108）的全部精细技术都以「分层
条件 + 判定性引擎」为模板。

再拆一层：为什么「可测 ⟹ κ-拉姆齐」恰好够用？第 94 章
定理 1.6 的证明用超滤子的**正规性**（对角交封闭）把
$\kappa$ 上的任何 $f:[\kappa]^{<\omega}\to\theta$
（$\theta<\kappa$ ）统一取整——注意是**所有维数同时**
取整（一个 $A\in D$ 对一切 $n$ 给出 $[A]^n$ 单色）。
引理 2.4 只用到「每维分别单色」的弱版，但引理 2.5 的
一般化（起点 $(s_0,A_0)$ ）与定理 2.6(3)（α-多个裁决
的合并）都要**跨维协调**——统一取整正是为此准备的。换
句话说，判定引理的完整形态（对一切语句、一切起点）消费
的正是定理 1.6 的完整强度（统一整齐集），**机器穷举
（单维）只是它的一维截面**——这层差距在 104.8 的边界
清单里立案。

裁决函数的**单调性**也值得一笔：若 $(s,B)\Vdash\varphi$
则任意 $(s,B')\subseteq B$ （同 stem）仍裁决 $\varphi$
（力迫的单调引理——纯延长方向保裁决）。这使 $T^+$ （
$T^-$ ）在 stem 维上是「向上的」：一旦某 stem 进入
$T^+$ ，它的所有后继 stem（延长的）也进入。染色因此
不是任意的——它自带单调结构，拉姆齐取整实际上是在
**单调染色**上做的。这个观察把「为什么三染色会有单色
大集」的直觉再推深一步：单调性 + 拉姆齐性 = 判定性，
两个条件缺一不可（无单调性时裁决可能在 stem 延长中
「翻转」；无拉姆齐性时单色集可能测零）。

## 104.3 定理 2.6：三款后果

> **定理 2.6（Prikry）** $G$ 为 $V$ 之上 $\mathbb P$
> 泛型。那么 (1) $\lambda>\kappa$ 的基数性与共尾度全保；
> (2) $\mathrm{cf}^{V[G]}(\kappa)=\omega$ ；(3) $X\in V[G]$ 、$X\subseteq\alpha<\kappa$ ⟹ $X\in V$ 。

**(1)** 由 $\kappa^+$ -cc 直接给出（事实 2.3.1 + 第 103
章引理 I.3.34 的复用）。**(2)** 令 $X=\bigcup\{s\mid \exists A\,((s,A)\in G)\}$ 。稠密集 $W_\alpha=\{(s,A)\mid \alpha<\min A\}$ （「未来元素全在 $\alpha$ 之上」）保证
$X$ 无界；滤子方向性使 stems 两两可比较——链并——故
$\mathrm{ot}(X)=\omega$ 。**(3)** 无新有界子集：设
$\dot X$ 是 $X\subseteq\alpha<\kappa$ 的名字、$p_0\in G$ 力迫 $\dot X\subseteq\check\alpha$ 。断言：存在 $q \le p_0$ 使每个 $\check\beta\in\dot X$ 的裁决被 $q$
**同时**判定——对每个 $\beta<\alpha$ 用引理 2.5 得
$A_\beta$ ，取 $B=\bigcap_{\beta<\alpha}A_\beta\in D$
（$\kappa$ -完全性消费在正处：$\alpha<\kappa$ ），则
$q=(s_0,B)$ 对一切 $\beta$ 判定。于是 $Z=\{\beta\mid q\Vdash\beta\in\dot X\}\in V$ 且 $Z=\dot X_G$ 。∎

(3) 的证明是**判定引理 + 完全性的合奏**：单点裁决（引理
2.5）+ $\kappa$ -完全交（把 $\alpha$ -多个裁决压回一个
条件）+ 名字-集合等式。对比第 103 章定理 2.1(f) 的名字账
（可能值集有界）：那边用小性数可能值，这边用判定性**消灭**
可能值——同一个「无新小集」结论的两种引擎。

三款后果的联合效果值得合读成一句话：**$V[G]$ 与 $V$
「在 $\kappa$ -高度以下完全相同」，但 $\kappa$ 的共尾
结构被外科手术式地改写**。这种「局部手术」的精确性在
力迫论中前所未有——Cohen 力迫加实数（动了 $2^\omega$ ）、
Lévy 崩塌塌下方（动了整个 $\kappa$ -层）、小力迫保一切
（什么都没动），而 Prikry 恰好只动「共尾度」这一个组合
不变量。第 105 章 Silver 力迫将在「不动 $\kappa$ -层」
的同一舞台上给 $2^\kappa$ 装上 Easton 式的值——两章
合起来就是 SCH 反例的全套零件。

$W_\alpha$ 的稠密性（(2) 的引擎）值得展开一行：
$$W_\alpha=\{(s,A)\in\mathbb P\mid\alpha<\min A\}$$

「未来全在 $\alpha$ 之上」的条件稠密——给定任何 $(t,B)$ ，
由 $D$ 的非主性取 $A\subseteq B\setminus(\alpha+1)$
（$B\setminus(\alpha+1)\in D$ ，因 $\alpha+1<\kappa$
是小集而 $D$ 是 $\kappa$ -完全非主的），则 $(t,A)\le (t,B)$ 且 $(t,A)\in W_\alpha$ 。泛型相遇后 stems 的并
$X$ 在每个 $\alpha$ 之上都有元素——无界性来自**测度
一集可以避开任何有界段**。这与 (3) 的「无新有界子集」
形成精确的对偶：**有界的信息全部留在 $V$ （(3)），而
无界的推进只沿测度一集的方向（(2)）**——两句合起来即
「$X$ 是把 $\kappa$ 的共尾度『切』成 ω 的刀」。

**第四格合拢**：定理 2.6 三款正是三本账之外的第四种组合
——保基数（κ⁺-cc 但**不保 $\kappa$ 的基数层位**：cf 变
ω 后 $\kappa$ 成奇异）、改共尾度（泛型序列的构造性来源）、
不加有界子集（判定性引擎）。$V[G]$ 中 $\kappa$ 是
cf=ω 的强极限奇异基数——SCH 反例的坯子（第 105 章 Silver
力迫在此坯上加工）。

## 104.4 Prikry 序列与 Mathias 定理

泛型相遇后，stems 的并 $X$ 具有**三重身份**：
$$X=\bigcup\{s\mid\exists A\,((s,A)\in G)\}$$

是 (i) 序型 ω 的递增列；(ii) $\kappa$ 的无界子集；(iii)
对每个 $B\in D$ ，$|X\setminus B|<\omega$ （几乎含于每个
测度一集——第三个身份来自 $\{(t,C)\mid C\subseteq B\}$
在每点之下的稠密性）。称这样的 $X$ 为 **Prikry 序列**。

> **定理 2.7（Mathias）** $X\subseteq\kappa$ 序型 ω。
> 令 $G(X)=\{(s,A)\mid\exists\alpha(s=X\cap\alpha)\wedge (X\setminus s)\subseteq A\}$ 。则 $G(X)$ 是 $M$
> 之上的 $\mathbb P$ -泛型滤子 $\iff\forall A\in D\, (|X\setminus A|<\omega)$ 。

证明（书 p158–159）的「⟸」方向是构造泛型性的教科书样本：
对 $M$ 中每个稠密开集 $W$ ，定义 $f_s(t)=1\iff\max s<\min t\wedge\exists A\,((s\cup t,A)\in W)$ ，取拉姆齐
整齐集 $H_s$ ，交出 $A=\triangle_s B_s\in D$ （对角交，
练习 1.5——第 94/100 章的正规性对角交在此第三次消费）；
由 $X$ 几乎含于 $A$ 取最小 $\alpha$ 使 $X\cap\alpha$
「超出」前段，用 $W$ 的开性把 $(s\cup u,\cdot)\in W$
翻译进 $G(X)$ ——**序列的测度一性质反过来生成泛型性**。
机器通道的 `in_GX`（成员判定 $s=X\cap\alpha\wedge X \setminus s\subseteq A$ ）与 `is_prikry_candidate`（尾段
入核）正是这条双命题的有限影子。

「⟸」方向的证明（书 p158–159）是全章最长的一段，骨架五步：

1. **逐 stem 编码**：$f_s(t)=1\iff\max s<\min t\wedge \exists A\,((s\cup t,A)\in W)$ ——把「稠密开集 $W$ 对
   延长后 stem 的态度」编成 $[\kappa]^{<\omega}\to 2$ 。
2. **拉姆齐取整**：每个 $f_s$ 取整齐集 $H_s\in D$
   （定理 1.6 再次出场——这次按 $s$ 索引地用）。
3. **对角交**：$B_s$ （若 $s$ 已可裁决取见证、否则
   $H_s$ ）作对角交 $A=\triangle_{s\in[\kappa]^{<\omega}} B_s$ ——练习 1.5 的对角交封闭性（正规性）保证
   $A\in D$ 。
4. **开性收尾**：稠密**开**使「$(s,A-(\max s+1))\in W$ 」
   可从「某延伸在 $W$ 」下推——开性在这里才被消费。
5. **序列-条件翻译**：由 $X$ 几乎含于 $A$ 取最小
   $\alpha$ ，令 $s=X\cap\alpha$ ，选 $u\subseteq X \setminus s$ （与 $t\setminus s$ 等长）——$s\cup u$
   是「$X$ 的真实前段」，其裁决由整齐性保证落在 $W$
   里，且 $(s\cup u,\cdot)\in G(X)$ 。

五步的分工：1–2 是编码+取整（拉姆齐机器）、3 是滤子代数
（正规性）、4 是序结构（开性=向上封闭）、5 是序列论（
几乎包含）。**一台「泛型性证明」的全部标准部件**在此
各就各位——第 105 章 Silver 力迫与第 107 章恰当迭代都会
按同样的五步谱式演奏。

## 104.5 定理 2.8：迭代超幂的临界点序列 = Prikry 序列

> **定理 2.8** $M=M_\omega$ （$\omega$ 次迭代超幂）、
> $\kappa_n=\mathrm{Crit}(j_{n,n+1})$ 的序列 $X=\{ \kappa_n\mid n<\omega\}$ 、$\mathbb P\in M$ 是 $M$
> 中依 $D=U_\omega$ 定义的 Prikry 力迫。则 $G(X)$
> 是 $M$ 之上的泛型滤子且 $N=M_{\omega+1}\cdots$ ——
> 精确地：$N=M[G(X)]$ ，其中 $N$ 是沿 $X$ 的自然
> 扩张模型（书 p160 的构造）。

证明的两半：泛型性由 Mathias 定理给出（关键引理 1.38：
$A\in U_\omega\iff\exists n\,(\kappa_n\in A)$ ——迭代
超幂中 $\omega$ -层超滤子的**序列判据**，第 97 章的账）；
$N=M[G(X)]$ 由序数都在 $M[G(X)]$ 中的论证给出（表示
定理 + 断言「$j_{n,\omega}$ 的像在 $\omega$ 步后稳定」）。

「序列判据」$A\in U_\omega\iff\exists n(\kappa_n\in A)$
值得单独放大——它是**迭代超幂与 Prikry 力迫的焊点**。
$U_\omega$ 是 $M_\omega$ 中的超滤子，其成员判定竟然
只看「是否含某个临界点」：这是因为 $U_\omega$ 的元素
经表示定理（第 97 章）对应 $j_{0,\omega}$ -像下的函数，
而 $\omega$ -层函数的「极小代表」恰在某个有限层被
$\kappa_n$ 判定。于是「$X=\{\kappa_n\}$ 几乎含于每个
$A\in U_\omega$ 」自动成立（$A$ 含某 $\kappa_n$ ，
之后的一切 $\kappa_m$ 呢？——需要引理 1.38 的另一半：
$U_\omega$ 测一的集**尾段全含**，正规性给出）。这条
判据使 Mathias 定理的前提免费获得——**定理 2.8 的泛型性
半边因此只需一行**。$N=M[G(X)]$ 半边的「稳定断言」
（$\forall\zeta\,\exists m\,\forall n>m\,(j_{n,\omega} (\zeta)=j_{\omega,\omega+\omega}(\zeta))$ ）则是第 97 章
「迭代像的连续轨迹」的 $\omega$ -层特写。

反过来读更有味：把定理 2.8 当**定义**——「在 $M_\omega$
中沿 $U_\omega$ 做 Prikry 力迫」**就是**「继续迭代到
$M_{\omega+\omega}$ 的另一种方式」。力迫扩张与超幂
迭代这两种看似正交的构造（一个向外加泛型、一个向内取
商）在 $\omega$ -层完全交织——这是「力迫 = 迭代超幂的
横向切片」这一深层对偶的最小实例。

这条定理合拢了两条主线：**第 97 章迭代超幂**（临界点序列
作为「无差别元」的动力学来源）与**本章力迫论**（泛型序列
的组合学来源）。$M_\omega$ 的视角同时解释了 Prikry 序列
的三个深层性质：几乎含于一切测度一集（因为 $U_\omega$
的成员判据是序列式的）、不添加有界子集（因为一切都在
$M_\omega$ 的内部账目里）、与 $0^\#$ 构造的同构性
（第 95 章的 Silver 不可辨别元序列恰是 $L$ 的 Prikry
序列——书的练习线）。

**与 $0^\#$ 的同构线**值得再压一笔，因为它是全教程最长
的一条暗线。第 95 章的 Kunen 构造给出 $0^\#$ 型的不可辨别
元序列 $\langle i_n\rangle$ ——「EM 蓝图 + 银色序对」的
组合见证；第 97 章的迭代超幂把序列升级为**临界点轨迹**
$\langle\kappa_n\rangle$ （每次超幂吃掉一个临界点）；本章
定理 2.8 给出第三个身份——**Prikry 序列**（力迫论的泛型
对象）。三个身份共享同一组组合性质（递增、无界、对「测度
一」型集合几乎全含），而各自的「宿主」不同（蓝图 / 迭代
模型 / 力迫扩张）。**同一序列的三重化身**是「大基数现象
在内模型与外扩张两个方向的对称性」的最纯样本——第 105
章 Silver 力迫、第 110 章 NS 饱和都会回看这张三身图。

Prikry 序列的**刚性**也值得点名：书 p158 的断言（我们的
104.4 节）说明 $X$ 被 $G(X)$ 反向唯一确定（滤子的 stem
并），且 $V[X]=V[G]$ （测度一集的信息可由序列复原——
$A\in D$ ⟺ $X$ 几乎含于 $A$ 的 Mathias 方向）。于是
「加一个 Prikry 序列」=「加一个泛型滤子」=「力迫扩张」，
三者是同一件事的三种说法。这与 Cohen 实数（实数 ↔ 滤子）
同构，但多出一层：**序列的「几乎包含」性质本身就是泛型
性的组合刻画**——Mathias 定理因此成为「不用力迫语言谈
力迫」的入口（Mathias 1977 的 happy family 理论由此发端，
第 107 章恰当力迫的「Mathias 条件」是其直系后裔）。

## 104.6 三本账 + 第四格的完整表

| | Prikry 力迫 | Lévy 崩塌（103 章） | 小型力迫（103 章定理 2.1） |
|---|---|---|---|
| 保基数 | $\ge\kappa^+$ 保；$\kappa$ 保基数但变奇异 | $\ge\kappa$ 保；$\kappa$ 变 $\omega_1$ | 全保 |
| 改共尾度 | $\mathrm{cf}(\kappa):\ \kappa\to\omega$ | $\kappa$ 之下全塌可数 | 不改 |
| 加子集 | **不加任何 $<\kappa$ 的子集** | 加大量子集（可数化见证） | 可加（但保见证） |
| 引擎 | 判定引理（拉姆齐取整） | 逐值稠密性 | $j^*$ 提升 |
| cc | $\kappa^+$ -cc（stem 冲突一维化） | $\kappa$ -cc（荟萃 Δ-账） | 无要求（$\lvert \mathbb P\rvert<\kappa$ ） |

第四格的独立意义：「改共尾度而不加子集」在覆盖引理语境
（第 96 章）下**等价于**大基数的存在——Prikry 力迫把这个
等价做成了显式构造。

阅读路线图：§104.1 是概念与第四格的定位（先读三本账回顾
再读本表）；§104.2 判定引理是全章技术心脏（三染色 + 拉姆齐
取整的逐帧账 + R(3,3)=6 的机器对接）；§104.3 定理 2.6 三款
各吃一台机器；§104.4–104.5 是两条接口（Mathias 的序列-
滤子等价、迭代超幂的三身图）；§104.6 总表防混淆；机器通道
按「四套 stem 编码 → 两组穷举对拍 → 一份集论核」排列，
其中 Julia/Python 的 R(3,3)=6 穷举与判定引理的关系值得
优先对读。

历史三笔收束：Prikry 1970 的原始动机是「可测变可达的
反问题」（把可测基数变成奇异但保持其余一切）；Mathias
1977 把序列性质提炼成独立理论（happy family / Mathias
 forcing——第 107 章的正主之一）；迭代超幂的临界点视角
（定理 2.8 的证明线）来自书中第 97 章的自建机器。三笔
分别对应本章的三条主线：**构造（力迫）、刻画（组合）、
解释（内模型）**——大基数论的三板斧在同一对象上合拢。

## 104.7 机器通道

七通道共享同一组数据件：条件 = $(s,A)$ （stem 严格递增
列表 + 测度一集，有限影子 = 含尾核 $\{5..9\}$ 的集合）；
`ple`（纯延长）/`prikryLe`（全序）/stem 良形与初始段判定
在七个语言里各有一份。分工四层：**stem 编码层**（Lean
存在式 / Coq 归纳谓词 / Agda 归纳族 / Prolog 同步递归——
同一「初始段」关系的四种编码，互相之间可直接翻译）；
**序律层**（纯延长的自反/传递 + 事实 2.3.1 前半——七份
独立实现）；**穷举层**（Julia/Python 的 R(3,3)=6 全染色
与序列候选对拍）；**集论核层**（Isabelle 的序对投影 +
尾核引理）。三层各自的「机器-数学对接度」不同：序律层
是定义直译、穷举层是定理内核（拉姆齐性）的完全有限化、
集论核层是构造骨架。

### 通道一：Lean——stem 序与纯延长

Lean 版是四套编码中「最薄」的：`IsPrefix` 用存在式（存在
余段 $r$ 使 $t{+}{+}r=s$ ），自反/传递各一行；良形直接
借 stdlib 的 `List.Pairwise`——不需要自建归纳谓词。这份
「薄」是双向的：好处是引理零成本（Pairwise 的子列表封闭
性由 stdlib 提供），代价是构造子信息被封装（无法像 Coq/
Agda 那样 inversion 出 `a<b` 见证）。四通道正好构成
「库依赖谱」的两端——Lean 全借库、Agda 全自建。

```lean
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Card

/-!
# 第 104 章 · Prikry 力迫

锚点（有限影子）：
- `stem`：严格递增的有限序列（Pairwise (·<·)）；
- `isPrefix`：stem 之间的初始段序（t ++ r = s）——自反/传递；
- `ple`：纯延长（同一 stem 上 A ⊆ B）——自反/传递
  （「不动 stem」的序结构，Task 19 Step 2 指定件）；
- `prikryLe`：定义 2.6 的全序 (s,A) ≤ (t,B)
  （t 是 s 的初始段 ∧ A ⊆ B ∧ 新增元素 ⊆ B）；
- `fact231`：事实 2.3.1 的 (s,A∩B) ≤ (s,A) ∧ ≤ (s,B)。
本体（引理 2.4/2.5 判定性、定理 2.6/2.7/2.8）留在正文。
-/

namespace Settheory.Ch104

open Finset

/-- stem：严格递增的有限序列。 -/
def Stem (l : List ℕ) : Prop := l.Pairwise (· < ·)

/-- 初始段序：t 是 s 的前段。 -/
def IsPrefix (t s : List ℕ) : Prop := ∃ r, t ++ r = s

theorem isPrefix_refl (s : List ℕ) : IsPrefix s s :=
  ⟨[], by simp⟩

theorem isPrefix_trans {t s u : List ℕ}
    (h₁ : IsPrefix t s) (h₂ : IsPrefix s u) : IsPrefix t u := by
  obtain ⟨r₁, rfl⟩ := h₁
  obtain ⟨r₂, rfl⟩ := h₂
  exact ⟨r₁ ++ r₂, by simp⟩

/-- Prikry 条件：stem + 测度一集（有限影子：Finset）。 -/
structure PCond where
  stem : List ℕ
  big : Finset ℕ

/-- 纯延长：不动 stem，只收窄测度一集。 -/
def ple (p q : PCond) : Prop :=
  p.stem = q.stem ∧ p.big ⊆ q.big

theorem ple_refl (p : PCond) : ple p p :=
  ⟨rfl, subset_refl _⟩

theorem ple_trans {p q r : PCond} (h₁ : ple p q) (h₂ : ple q r) :
    ple p r :=
  ⟨h₁.1.trans h₂.1, h₁.2.trans h₂.2⟩

/-- 定义 2.6 全序：(s,A) ≤ (t,B) ⟺ t 初始段于 s ∧ A ⊆ B
∧ s∖t 的元素都在 B 中。 -/
def prikryLe (p q : PCond) : Prop :=
  IsPrefix q.stem p.stem ∧ p.big ⊆ q.big ∧
    ∀ x ∈ p.stem.drop q.stem.length, x ∈ q.big

theorem prikryLe_refl (p : PCond) : prikryLe p p := by
  refine ⟨isPrefix_refl _, subset_refl _, ?_⟩
  simp

/-- 事实 2.3.1（前半）：(s,A∩B) 同时纯延长 (s,A) 与 (s,B)。 -/
theorem fact231 (s : List ℕ) (A B : Finset ℕ) :
    ple ⟨s, A ∩ B⟩ ⟨s, A⟩ ∧ ple ⟨s, A ∩ B⟩ ⟨s, B⟩ :=
  ⟨⟨rfl, Finset.inter_subset_left⟩, ⟨rfl, Finset.inter_subset_right⟩⟩

/-- 样本：stem [2,5] 是 [2,5,7] 的初始段。 -/
example : IsPrefix [2, 5] [2, 5, 7] :=
  ⟨[7], by simp⟩

/-- 冲突 stem：[2,5] 与 [2,6] 互非初始段（事实 2.3.1 的
不相容来源只在 stem）。 -/
example : ¬ IsPrefix [2, 6] [2, 5, 7] := by
  intro ⟨r, hr⟩
  simp only [List.cons_append] at hr
  cases hr

/-- 相容判定：同 stem 的两条件以 stem 为公共前段
（可比较性的最小样本）。 -/
example (A B : Finset ℕ) : prikryLe ⟨[2, 5], A⟩ ⟨[2, 5], B⟩ ↔ A ⊆ B := by
  constructor
  · intro h; exact h.2.1
  · intro h
    exact ⟨isPrefix_refl _, h, by simp⟩

end Settheory.Ch104
```

Lean 版四件：`Stem`（`List.Pairwise (·<·)`——stdlib 的全
对严格递增）、`IsPrefix` 的存在式定义（$\exists r, t{+}{+} r=s$ ——自反取 `[]`、传递用 `simp` 的结合律一击）、`ple`
（纯延长：stem 相等 + Finset 包含）、`prikryLe`（全序的
第三款用 `List.drop` 表「新增元素」）。实测坑两笔：
`ple_trans` 首版签名手误（`(h₂ : ple r q)` 写反——
unusedVariables 警告当场暴露）；`¬ IsPrefix [2,6]` 的反证
用 `simp only [List.cons_append]` 后 `cases` 直接收口
（`(2∷(6∷r)) = [2,5,7]` 展开到 `6∷r = [5,7]` 即矛盾）。

### 通道二：Coq——stem 归纳与全序

（Task 19 Step 2 指定件「stem 序与纯延长自反传递」的
归纳实现主通道。）

Coq 版的独占件是 `stem` 归纳谓词与 `prefix_stem`（初始段
继承良形）——这条引理在四套编码里证法各异：Coq 走「对头部
归纳 + inversion 反演局部递增」，Agda 走「对 IsPrefix 归纳
的五案覆盖」，Lean 的 `Stem`（Pairwise 版）下它自动成立
（Pairwise 的 sublist 封闭是 stdlib 引理），Prolog 版由
`stemOK` 的邻对定义直接兼容。**同一引理的四种证明难度
完全不同**——这是「编码选择决定证明成本」的又一实例（与第 101 章
位编码、103 章滤子编码同谱）。

```coq
(* 第 104 章：Prikry 条件的 stem 序、纯延长与相容判定。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

Module Ch104.

(* ── 一、stem：严格递增有限序列（归纳谓词） ── *)

Inductive stem : list nat -> Prop :=
| stem_nil : stem []
| stem_one : forall a, stem [a]
| stem_cons : forall a b l,
    a < b -> stem (b :: l) -> stem (a :: b :: l).

(* ── 二、初始段序与其反射/传递（Task 19 Step 2 指定件） ── *)

Definition isPrefix (t s : list nat) : Prop := exists r, t ++ r = s.

Lemma isPrefix_refl : forall s, isPrefix s s.
Proof. intros s. exists []. rewrite app_nil_r. reflexivity. Qed.

Lemma isPrefix_trans : forall t s u,
  isPrefix t s -> isPrefix s u -> isPrefix t u.
Proof.
  intros t s u [r1 E1] [r2 E2]. exists (r1 ++ r2).
  rewrite app_assoc, E1. exact E2.
Qed.

(* stem 的初始段仍是 stem（对头部归纳）。 *)
Lemma prefix_stem : forall t r, stem (t ++ r) -> stem t.
Proof.
  induction t as [|c t' IH]; intros r H.
  - constructor.
  - destruct r as [|d r'].
    + rewrite app_nil_r in H. exact H.
    + simpl in H.
      destruct t' as [|e t''].
      * (* H : stem (c :: d :: r')；目标 stem [c] *)
        constructor.
      * (* H : stem (c :: e :: (t'' ++ d :: r')) *)
        inversion H; subst.
        apply stem_cons with (l := t''); [assumption |].
        apply (IH (d :: r')). assumption.
Qed.

(* ── 三、Prikry 条件、纯延长与全序 ── *)

Definition inclL (l1 l2 : list nat) : Prop :=
  forall x, In x l1 -> In x l2.

Record PCond := mkP {ps : list nat; pb : list nat}.

(* 纯延长：不动 stem，只收窄测度一集。 *)
Definition ple (p q : PCond) : Prop :=
  ps p = ps q /\ inclL (pb p) (pb q).

Lemma ple_refl : forall p, ple p p.
Proof. intros p. split; [reflexivity|]. intros x Hx. exact Hx. Qed.

Lemma ple_trans : forall p q r, ple p q -> ple q r -> ple p r.
Proof.
  intros p q r [E1 H1] [E2 H2]. split; [congruence|].
  intros x Hx. apply H2, H1, Hx.
Qed.

(* 定义 2.6 全序：stem 初始段 + 测度一集收窄 + 新增元素入集。 *)
Definition prikryLe (p q : PCond) : Prop :=
  isPrefix (ps q) (ps p) /\ inclL (pb p) (pb q) /\
    inclL (skipn (length (ps q)) (ps p)) (pb q).

Lemma prikryLe_refl : forall p, prikryLe p p.
Proof.
  intros p. split; [apply isPrefix_refl|]. split.
  - intros x Hx; exact Hx.
  - intros x Hx. rewrite skipn_all in Hx. destruct Hx.
Qed.

(* 事实 2.3.1（前半）：交条件同时纯延长两侧（交 = filter 实现）。 *)
Lemma fact231 : forall s A B,
  ple (mkP s (filter (fun x => existsb (fun y => Nat.eqb x y) B) A)) (mkP s A) /\
  ple (mkP s (filter (fun x => existsb (fun y => Nat.eqb x y) B) A)) (mkP s B).
Proof.
  intros s A B. split; split; try reflexivity; intros x Hx;
    apply filter_In in Hx; destruct Hx as [Hx Hin];
    [ exact Hx
    | apply existsb_exists in Hin; destruct Hin as [y [Hy Hxy]];
      apply Nat.eqb_eq in Hxy; subst y; exact Hy ].
Qed.

(* ── 四、相容判定：不相容只能来自 stem 冲突（事实 2.3.1 后半） ── *)

(* 两个 stem 可比较 ⟺ 有公共延展（同向初始段）。 *)
Lemma prefix_or_disjoint_sample :
  isPrefix [2;5] [2;5;7] /\ ~ isPrefix [2;6] [2;5;7].
Proof.
  split.
  - exists [7]. reflexivity.
  - intros [r E]. simpl in E. discriminate.
Qed.

(* 相容样本：同 stem 条件的序归结为测度一集包含。 *)
Lemma same_stem_le : forall A1 A2,
  prikryLe (mkP [2;5] A1) (mkP [2;5] A2) <-> inclL A1 A2.
Proof.
  intros A1 A2. split.
  - intros [[r E] [H1 H2]]. destruct r as [|w r'].
    + exact H1.
    + simpl in E. discriminate.
  - intros H. split; [apply isPrefix_refl|]. split; [exact H|].
    intros x Hx. rewrite skipn_all in Hx. destruct Hx.
Qed.

(* stem 样本与泛型序列候选（Prolog/Julia 通道承载全枚举）。 *)
Example stem_sample : stem [2;5;7].
Proof. repeat (constructor || lia). Qed.

End Ch104.
```

Coq 版独占 `stem` 的**归纳谓词**定义（三构造子 nil/one/
cons——`cons` 携带 `a<b` 见证）与 `prefix_stem`（初始段
继承 stem 性：对头部归纳、`inversion` 反演出局部递增）。
实测坑三笔：`app_assoc` 的 rewrite 方向（目标 `t++(r1++r2)
=u` 须**正向** rewrite 成 `(t++r1)++r2` 再代换）；`stem_cons
with (l := t'')` 的 l 参数是**剩余尾**（首版误填 `e::t''`
被 unify 拒）；`skipn (length l) l` 用 **`skipn_all`** 直接
归一为 `[]`（`skipn_length` 是 length 等式不是成员消去——
且 8.20 起弃用）。

### 通道三：Agda——stem 列表递归

Task 19 Step 2 指定件「stem 列表递归和相容判定」的构造
性主通道：`Stem`
与 `IsPrefix` 双归纳族给出最细的构造子信息——`p-extend`
同步延伸两侧的形状让「前段继承 stem 性」的五案证明完全
机械（每案恰好消费一个构造子）。`with … in eq` 保留判别
等式的写法值得收藏：它解决了「with 分支内丢失原等式」的
通用痛点（99 章 ∨-inv 是对同一问题的另一解法，两条路
都应入个人工具箱）。

```agda
-- 第 104 章：stem 列表递归、初始段序与纯延长/相容判定。
module Ch104_prikry where

open import Data.Nat using (ℕ; zero; suc; _<_; _≤_; z≤n; s≤s)
open import Data.Nat.Properties using (≤-refl; ≤-trans)
open import Data.List using (List; []; _∷_)
open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Product using (_×_; _,_)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; trans; cong; sym)
open import Relation.Nullary using (¬_)

-- ── 零、自建件：相等、成员、包含 ──

nat-eq : ℕ → ℕ → Bool
nat-eq zero zero = true
nat-eq zero (suc _) = false
nat-eq (suc _) zero = false
nat-eq (suc m) (suc n) = nat-eq m n

nat-eq-refl : ∀ n → nat-eq n n ≡ true
nat-eq-refl zero = refl
nat-eq-refl (suc n) = nat-eq-refl n

nat-eq-≡ : ∀ y x → nat-eq y x ≡ true → y ≡ x
nat-eq-≡ zero zero q = refl
nat-eq-≡ zero (suc x) ()
nat-eq-≡ (suc y) zero ()
nat-eq-≡ (suc y) (suc x) q = cong suc (nat-eq-≡ y x q)

data _∈L_ {A : Set} : A → List A → Set where
  here  : ∀ {x xs} → x ∈L (x ∷ xs)
  there : ∀ {y x xs} → x ∈L xs → x ∈L (y ∷ xs)

inL : ℕ → List ℕ → Bool
inL x [] = false
inL x (y ∷ ys) = if nat-eq y x then true else inL x ys

inL-sound : ∀ x ys → inL x ys ≡ true → x ∈L ys
inL-sound x [] ()
inL-sound x (y ∷ ys) p with nat-eq y x in eq
... | true rewrite sym (nat-eq-≡ y x eq) = here
... | false = there (inL-sound x ys p)

inL-complete : ∀ x ys → x ∈L ys → inL x ys ≡ true
inL-complete x [] ()
inL-complete .y (y ∷ ys) here rewrite nat-eq-refl y = refl
inL-complete x (y ∷ ys) (there m) with nat-eq y x
... | true = refl
... | false = inL-complete x ys m

inclL : List ℕ → List ℕ → Set
inclL xs ys = ∀ x → x ∈L xs → x ∈L ys

-- ── 一、stem 递归与初始段序（Task 19 Step 2 指定件） ──

data Stem : List ℕ → Set where
  s-nil  : Stem []
  s-one  : ∀ {a} → Stem (a ∷ [])
  s-cons : ∀ {a b l} → a < b → Stem (b ∷ l) → Stem (a ∷ b ∷ l)

data IsPrefix : List ℕ → List ℕ → Set where
  p-nil    : ∀ {s} → IsPrefix [] s
  p-refl   : ∀ {s} → IsPrefix s s
  p-extend : ∀ {t x s} → IsPrefix t s → IsPrefix (x ∷ t) (x ∷ s)

isPrefix-trans : ∀ {t s u} → IsPrefix t s → IsPrefix s u → IsPrefix t u
isPrefix-trans p-nil _ = p-nil
isPrefix-trans p-refl h = h
isPrefix-trans (p-extend k) p-refl = p-extend k
isPrefix-trans (p-extend k) (p-extend k') = p-extend (isPrefix-trans k k')

-- stem 的初始段仍是 stem（对 IsPrefix 归纳 + Stem 反演）。
prefix-stem : ∀ {t s} → IsPrefix t s → Stem s → Stem t
prefix-stem p-nil _ = s-nil
prefix-stem p-refl hs = hs
prefix-stem (p-extend p-nil) hs = s-one
prefix-stem (p-extend p-refl) hs = hs
prefix-stem (p-extend (p-extend k)) (s-cons x<y hs') =
  s-cons x<y (prefix-stem (p-extend k) hs')

-- ── 二、Prikry 条件、纯延长与全序 ──

record PCond : Set where
  constructor pc
  field
    ps : List ℕ
    pb : List ℕ

ple : PCond → PCond → Set
ple p q =
  PCond.ps p ≡ PCond.ps q × inclL (PCond.pb p) (PCond.pb q)

ple-refl : ∀ p → ple p p
ple-refl p = refl , (λ x h → h)

ple-trans : ∀ p q r → ple p q → ple q r → ple p r
ple-trans p q r (e₁ , h₁) (e₂ , h₂) =
  trans e₁ e₂ , (λ x h → h₂ x (h₁ x h))

prikryLe : PCond → PCond → Set
prikryLe p q =
  IsPrefix (PCond.ps q) (PCond.ps p) × inclL (PCond.pb p) (PCond.pb q)

prikryLe-refl : ∀ p → prikryLe p p
prikryLe-refl p = p-refl , (λ x h → h)

-- 同 stem 的序归结为包含。
same-stem-le : ∀ s A B → prikryLe (pc s A) (pc s B) → inclL A B
same-stem-le s A B (_ , h) = h

-- ── 三、样本 ──

2<5 : 2 < 5
2<5 = s≤s (s≤s (s≤s z≤n))

5<7 : 5 < 7
5<7 = s≤s (s≤s (s≤s (s≤s (s≤s (s≤s z≤n)))))

sample-stem : Stem (2 ∷ 5 ∷ 7 ∷ [])
sample-stem = s-cons 2<5 (s-cons 5<7 s-one)

sample-prefix : IsPrefix (2 ∷ 5 ∷ []) (2 ∷ 5 ∷ 7 ∷ [])
sample-prefix = p-extend (p-extend p-nil)

-- 前段继承 stem 性。
sample-prefix-stem : Stem (2 ∷ 5 ∷ [])
sample-prefix-stem = prefix-stem sample-prefix sample-stem
```

Agda 版三笔特色：`Stem`/`IsPrefix` 双**归纳族**（索引上
的递归——`p-extend : IsPrefix t s → IsPrefix (x∷t) (x∷s)`
同步延伸两侧，`prefix-stem` 五案覆盖）；`inL-sound` 的
**`with … in eq`**（保留判别等式供 `nat-eq-≡` 使用——首版
丢失 eq 后 `here` 无法闭合）；record 投影须全限定
`PCond.ps`（裸 `ps` 不在顶层作用域）。

### 通道四：Julia——R(3,3)=6 全染色与序列候选

（Task 19 Step 2 指定件「穷举有限纯决策」的计算主通道，
含 Mathias 定理影子的序列候选。）

本章机器-数学最紧的对接：**判定引理（引理 2.4）的证明把
语句的裁决三染色到 $[\kappa]^{<\omega}$ ，用可测 ⟹ 拉姆齐
（第 94 章定理 1.6）取整齐集**；有限影子恰好是 R(3,3)=6
——$\{0..5\}$ 上 15 对的 2-染色（= 语句在「二维 stem」上
的裁决模式）共 32768 种，每种都有同色三元组（= 整齐集的
二维情形）。Julia 侧手写三重循环搜同色组；这个穷举在
Lean 95 章已用 `native_decide` 验过（同一数学事实的
三种机器见证）。

```julia
# 第 104 章：Prikry 条件的纯延长序与有限纯决策穷举。
println("==== 104")

# ── 一、条件与序（定义 2.6 的有限影子）──
# stem = 严格递增有限序列；big = 测度一集的影子（含尾核 CORE 的集合）。
const CORE = Set(5:9)
isbig(A) = CORE ⊆ A

isPrefix(t, s) = length(t) <= length(s) && t == s[1:length(t)]

# 纯延长（更强方向）：不动 stem、收窄测度一集——p ≤ q 要求 p.big ⊆ q.big。
ple(p, q) = p[1] == q[1] && issubset(p[2], q[2])

prikryLe(p, q) =
    isPrefix(q[1], p[1]) &&
    issubset(p[2], q[2]) &&
    issubset(Set(p[1][length(q[1])+1:end]), q[2])

# 纯延长的自反/传递（Task 19 Step 2 指定件）。
for A in [Set(5:9), Set(4:9)]
    @assert ple(("s", A), ("s", A))
end
p = ("s", Set(5:9)); q = ("s", Set(4:9)); r = ("s", Set(3:9))
@assert ple(p, q) && ple(q, r) && ple(p, r)   # 传递样本（5:9 ⊆ 4:9 ⊆ 3:9）

# 全序自反 + 事实 2.3.1 前半（交条件双侧纯延长）。
s = [2, 5, 7]
for A in [Set(5:9), Set(3:9)]
    @assert prikryLe((s, A), (s, A))
end
A, B = Set(5:9), Set([3, 5, 6, 7, 8, 9])
@assert ple((s, intersect(A, B)), (s, A)) && ple((s, intersect(A, B)), (s, B))

# ── 二、有限纯决策穷举：Prikry 判定性的 Ramsey 内核 ──
# 引理 2.4 的证明用「可测 ⟹ κ-Ramsey」（定理 1.6）取整齐集。
# 有限影子 = R(3,3)=6：对 {0..5} 的递增对 2-染色穷举，
# 每个染色都有同色三元组——「不动 stem 地判定语句」的组合内核。
const U6 = collect(0:5)
pairs = [(i, j) for i in U6, j in U6 if i < j]   # 15 对

function homo_triple(color)
    for a in 0:3, b in (a+1):4, c in (b+1):5
        if color[(a,b)] == color[(b,c)] == color[(a,c)]
            return (a, b, c)
        end
    end
    return nothing
end

n_homo6 = 0
for mask in 0:(2^15 - 1)
    global n_homo6
    color = Dict(pairs[k] => (mask >> (k-1)) & 1 for k in 1:15)
    ht = homo_triple(color)
    ht !== nothing || error("R(3,3)=6 失败于 mask=$mask")
    n_homo6 += 1
end
@assert n_homo6 == 2^15

# ── 三、泛型序列候选（Mathias 定理 2.7 的影子）──
# 测度一集 = 含尾核 CORE 的集合；X 是 Prikry 序列候选 ⟺
# X 递增无界且对一切 A ⊇ CORE 有 |X∖A| < ω（影子：尾段落入 CORE）。
function is_prikry_candidate(X)
    all(X[i] < X[i+1] for i in 1:length(X)-1) || return false
    k = findlast(x -> !(x in CORE), X)
    return k === nothing || k <= 4   # 非核元素至多出现在前 4 位
end

@assert is_prikry_candidate([1, 2, 5, 6, 7, 8, 9])
@assert !is_prikry_candidate([5, 1, 6, 7, 8])          # 非递增
@assert is_prikry_candidate([3, 4, 5, 6, 7, 8, 9])     # 前段非核、尾段入核
@assert !is_prikry_candidate([5, 6, 7, 8, 9, 2])       # 非递增（尾混低值）

# G(X) 的成员判定（定理 2.7）：(s,A) ∈ G(X) ⟺ s = X∩α ∧ X∖s ⊆ A。
function in_GX(s, A, X)
    α = length(s)
    s == X[1:α] && issubset(setdiff(Set(X), Set(s)), A)
end
X = [1, 2, 5, 6, 7, 8, 9]
@assert in_GX([1, 2], Set(5:9), X)          # s = X∩2, 尾在核中
@assert !in_GX([1, 5], Set(5:9), X)         # s ≠ X∩α（跳过 2）
@assert !in_GX([1, 2], Set([6,7,8,9]), X)   # A 缺 5：X∖s ⊄ A
@assert in_GX(X, Set(5:9), X)               # 整序列即 stem

println("Julia：纯延长自反/传递、事实 2.3.1、R(3,3)=6 全染色穷举（$n_homo6 例）；")
println("Prikry 序列候选与 G(X) 成员判定——判定性 Ramsey 内核 + Mathias 影子")
println("END ====")
```

三条线：序样本（`ple`/`prikryLe`/`fact231` 与证明通道同构）、
**R(3,3)=6 全染色**（32768 例逐一验同色三元组——判定引理
的拉姆齐内核在 $n=2$ 维的完全穷举）、序列候选与 $G(X)$
成员判定（Mathias 双命题的影子）。实测坑：**顶层 for 循环
内计数器须 `global n_homo6`**（软作用域歧义——首版
UndefVarError）。

### 通道五：Python——独立对拍

与 Julia 的分工：`homo_triple` 用 `itertools.combinations`
枚举 20 个三元组（Julia 手写三重循环）；序关系用 frozenset
的 `<=`（Julia `issubset`）。两侧独立到达同值——染色穷举的
32768 例逐格对拍；序列候选的「尾段入核」两侧不同实现
（`findlast` vs 下标推导），对拍保证「几乎含于」语义一致。

```python
# 第 104 章：与 Julia 独立对拍——纯延长序、R(3,3)=6 穷举与 Mathias 影子。
import io
import sys
from itertools import combinations

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

CORE = frozenset(range(5, 10))


def is_prefix(t, s):
    return len(t) <= len(s) and list(t) == list(s)[: len(t)]


def ple(p, q):
    return p[0] == q[0] and p[1] <= q[1]


def prikry_le(p, q):
    return (
        is_prefix(q[0], p[0])
        and p[1] <= q[1]
        and set(p[0][len(q[0]):]) <= q[1]
    )


def homo_triple(color):
    for a, b, c in combinations(range(6), 3):
        if color[(a, b)] == color[(b, c)] == color[(a, c)]:
            return (a, b, c)
    return None


def is_prikry_candidate(x):
    if any(x[i] >= x[i + 1] for i in range(len(x) - 1)):
        return False
    bad = [i for i, v in enumerate(x) if v not in CORE]
    return not bad or bad[-1] <= 3   # 非核元素至多前 4 位


def in_gx(s, a, x):
    alpha = len(s)
    return list(s) == list(x)[:alpha] and set(x) - set(s) <= a


def main():
    print("==== 104")
    # 纯延长自反/传递（与 Julia 同款样本）。
    assert ple(("s", CORE), ("s", CORE))
    p, q, r = ("s", CORE), ("s", frozenset(range(4, 10))), ("s", frozenset(range(3, 10)))
    assert ple(p, q) and ple(q, r) and ple(p, r)

    s = [2, 5, 7]
    assert prikry_le((s, CORE), (s, CORE))
    a, b = CORE, frozenset({3} | set(range(5, 10)))
    assert ple((s, a & b), (s, a)) and ple((s, a & b), (s, b))

    # R(3,3)=6 全染色穷举（32768 例）。
    pairs = list(combinations(range(6), 2))
    assert len(pairs) == 15
    n_homo = 0
    for mask in range(2 ** 15):
        color = {pairs[k]: (mask >> k) & 1 for k in range(15)}
        ht = homo_triple(color)
        assert ht is not None, f"R(3,3)=6 fails at mask={mask}"
        n_homo += 1
    assert n_homo == 2 ** 15

    # Prikry 序列候选与 G(X) 成员判定。
    assert is_prikry_candidate([1, 2, 5, 6, 7, 8, 9])
    assert not is_prikry_candidate([5, 1, 6, 7, 8])
    assert is_prikry_candidate([3, 4, 5, 6, 7, 8, 9])
    assert not is_prikry_candidate([5, 6, 7, 8, 9, 2])

    x = [1, 2, 5, 6, 7, 8, 9]
    assert in_gx([1, 2], CORE, x)
    assert not in_gx([1, 5], CORE, x)
    assert not in_gx([1, 2], frozenset({6, 7, 8, 9}), x)
    assert in_gx(x, CORE, x)

    print("Python：纯延长序、事实 2.3.1、R(3,3)=6 全染色（32768 例）、")
    print("Prikry 候选与 G(X) 判定——与 Julia 独立对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
```

与 Julia 的分工：`homo_triple` 用 `itertools.combinations`
枚举 20 个三元组（Julia 手写三重循环）；序关系用 frozenset
的 `<=`（Julia `issubset`）。两侧独立到达同值——染色穷举的
32768 例逐格对拍。

### 通道六：Prolog——stem 序查询与候选生成

Task 19 Step 2 指定件「生成泛型候选」主通道：`prikry_
candidate/1` 可正向验证（给定序列判候选）也可反向枚举
（配合 length 约束生成一切有限候选）；`in_gx/2` 同理
双向。`compat_stems` 把事实 2.3.1 后半做成可查询的判据
——stem 冲突是**唯一的**不相容来源。

```prolog
:- encoding(utf8).
% 第 104 章：Prikry 条件的序查询、泛型序列候选生成与 G(X) 判定。

% ── 一、初始段序与纯延长（Task 19 Step 2 指定件） ──
isPrefix([], _).
isPrefix([H|T], [H|S]) :- isPrefix(T, S).

% 事实 2.3.1 前半：交条件双侧纯延长（测度一集以列表表示）。
inclL([], _).
inclL([H|T], L) :- member(H, L), inclL(T, L).

ple(s(S,A), s(S,B)) :- inclL(A, B).

% 定义 2.6 全序。
prikryLe(s(S,A), s(T,B)) :-
    isPrefix(T, S),
    inclL(A, B),
    append(T, Rest, S),
    inclL(Rest, B).

% ── 二、stem 良形（严格递增）与相容判定 ──
stemOK([]).
stemOK([_]).
stemOK([A,B|T]) :- A < B, stemOK([B|T]).

% 相容：stem 可比较（有公共延展）——事实 2.3.1 的不相容来源只在 stem。
compat_stems(S, T) :- isPrefix(S, T) ; isPrefix(T, S).

% ── 三、泛型序列候选生成（Mathias 定理 2.7 影子） ──
% 测度一集 = 含尾核 [5..9]；候选 X ⟹ 递增且尾段入核。
in_core(X) :- between(5, 9, X).

tail_in_core(Xs) :-
    ( append(_, T, Xs), maplist(in_core, T), length(T, L), L >= 3 ).

prikry_candidate(Xs) :-
    stemOK(Xs),
    tail_in_core(Xs).

% G(X) 成员判定：s = X∩α ∧ X∖s ⊆ A。
prefix_at(Xs, N, S) :- length(S, N), append(S, _, Xs).

in_gx(s(S,A), Xs) :-
    length(S, N),
    prefix_at(Xs, N, S),
    append(S, Rest, Xs),
    inclL(Rest, A).

main :-
    format("==== 104~n"),
    % 初始段序样本。
    isPrefix([2,5], [2,5,7]),
    \+ isPrefix([2,6], [2,5,7]),
    isPrefix([2,5,7], [2,5,7]),
    % stem 良形与相容。
    stemOK([2,5,7]),
    \+ stemOK([2,2,5]),
    compat_stems([2,5], [2,5,7]),
    \+ compat_stems([2,5], [2,6]),
    % 纯延长与全序样本。
    ple(s([2,5],[5,6,7,8,9]), s([2,5],[4,5,6,7,8,9])),
    \+ ple(s([2,5],[4,5,6,7,8,9]), s([2,5],[5,6,7,8,9])),
    prikryLe(s([2,5,7],[5,6,7,8,9]), s([2,5],[4,5,6,7,8,9])),
    \+ prikryLe(s([2,6],[5,6,7,8,9]), s([2,5],[4,5,6,7,8,9])),
    % 泛型序列候选生成：枚举几个候选与反例。
    prikry_candidate([1,2,5,6,7,8,9]),
    prikry_candidate([3,4,5,6,7]),
    \+ prikry_candidate([5,1,6,7,8]),
    \+ prikry_candidate([1,2,3,4,6,7,8,4]),
    % G(X) 判定（定理 2.7 影子）。
    X = [1,2,5,6,7,8,9],
    in_gx(s([1,2],[5,6,7,8,9]), X),
    \+ in_gx(s([1,5],[5,6,7,8,9]), X),
    \+ in_gx(s([1,2],[6,7,8,9]), X),
    in_gx(s(X,[5,6,7,8,9]), X),
    format("初始段/纯延长/全序样本；相容=stem 可比较；候选生成与 G(X) 判定~n"),
    writeln("END ====").
```

Prolog 版的 `isPrefix/2` 是**同步递归**（两侧列表同步剥头
——与 Agda `p-extend` 同构的 Prolog 表达）；`compat_stems`
实现「不相容只能来自 stem」（事实 2.3.1 后半）；候选生成
与成员判定支持**双向查询**（给定 X 判候选/给前缀枚举）。

### 通道七：Isabelle——纯延长序的集论核

沿第 103 章验证的确定性规则链风格（零 auto/blast），秒级
构建。独占件 `tail_core_diff`：Mathias 定理的「尾段 ⟹
余集有界」方向在纯集论层的骨架——`(∀n∈X−m. n∈A) ⟹
X−A ⊆ m`，经典反证 + `bspec` + `notE` 五步收口。

```isabelle
theory Prikry
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 104 章：Prikry 条件的纯延长序与事实 2.3.1 的集论核。
证明全用确定性规则链（沿第 103 章 THE-fst 教训，不用 blast/auto）。
判定引理（引理 2.4/2.5）与定理 2.6/2.7/2.8 留在正文。\<close>

text \<open>纯延长：不动 stem，只收窄测度一集。以序对 \<langle>s, A\<rangle> 表示条件。\<close>

definition pleP :: "[i, i] \<Rightarrow> o" where
  "pleP(p, q) \<equiv> fst(p) = fst(q) \<and> snd(p) \<subseteq> snd(q)"

lemma pleP_refl: "pleP(p, p)"
  unfolding pleP_def by (rule conjI, rule refl, rule subset_refl)

lemma pleP_trans:
  assumes h1: "pleP(p, q)" and h2: "pleP(q, r)"
  shows "pleP(p, r)"
proof -
  from h1 have e1: "fst(p) = fst(q)" and s1: "snd(p) \<subseteq> snd(q)"
    unfolding pleP_def by (rule conjunct1, rule conjunct2)
  from h2 have e2: "fst(q) = fst(r)" and s2: "snd(q) \<subseteq> snd(r)"
    unfolding pleP_def by (rule conjunct1, rule conjunct2)
  have e: "fst(p) = fst(r)"
    by (rule trans [OF e1 e2])
  have s: "snd(p) \<subseteq> snd(r)"
    by (rule subset_trans [OF s1 s2])
  show ?thesis unfolding pleP_def by (rule conjI, rule e, rule s)
qed

text \<open>序对投影的显式计算。\<close>

lemma fst_pair_same: "fst(\<langle>s, X\<rangle>) = s"
  by simp

lemma snd_pair_same: "snd(\<langle>X, A\<rangle>) = A"
  by simp

text \<open>事实 2.3.1（前半）：交条件同时纯延长两侧。\<close>

lemma fact231:
  "pleP(\<langle>s, A \<inter> B\<rangle>, \<langle>s, A\<rangle>) \<and> pleP(\<langle>s, A \<inter> B\<rangle>, \<langle>s, B\<rangle>)"
proof (rule conjI)
  show "pleP(\<langle>s, A \<inter> B\<rangle>, \<langle>s, A\<rangle>)"
    unfolding pleP_def
  proof (rule conjI)
    show "fst(\<langle>s, A \<inter> B\<rangle>) = fst(\<langle>s, A\<rangle>)"
      by (simp only: fst_pair_same)
  next
    show "snd(\<langle>s, A \<inter> B\<rangle>) \<subseteq> snd(\<langle>s, A\<rangle>)"
      by (simp only: snd_pair_same, rule Int_lower1)
  qed
next
  show "pleP(\<langle>s, A \<inter> B\<rangle>, \<langle>s, B\<rangle>)"
    unfolding pleP_def
  proof (rule conjI)
    show "fst(\<langle>s, A \<inter> B\<rangle>) = fst(\<langle>s, B\<rangle>)"
      by (simp only: fst_pair_same)
  next
    show "snd(\<langle>s, A \<inter> B\<rangle>) \<subseteq> snd(\<langle>s, B\<rangle>)"
      by (simp only: snd_pair_same, rule Int_lower2)
  qed
qed

text \<open>Prikry 序列的尾核性质（Mathias 定理 2.7 影子）：
若 X 的 m-尾段全部落入 A，则 X - A ⊆ m（余集有前段界）。\<close>

lemma tail_core_diff:
  assumes tail: "\<forall>n \<in> X - m. n \<in> A"
  shows "X - A \<subseteq> m"
proof
  fix x
  assume hx: "x \<in> X - A"
  from hx have hxx: "x \<in> X" by (rule DiffD1)
  from hx have hna: "x \<notin> A" by (rule DiffD2)
  show "x \<in> m"
  proof (rule classical)
    assume contr: "x \<notin> m"
    from hxx contr have hxm: "x \<in> X - m" by (rule DiffI)
    from tail hxm have "x \<in> A" by (rule bspec)
    with hna show "x \<in> m" by (rule notE)
  qed
qed

end
```

Isabelle 版纯走第 103 章验证过的**确定性规则链**风格
（`conjI`/`conjunct1`/`trans`/`subset_trans`/`Int_lower1/2`
/`DiffD1/D2`/`DiffI`/`bspec`/`notE`——零 auto/blast），构建
秒级。实测坑两笔：`unfolding pleP_def` 后第二分量是
**`snd(⟨s,A⟩) ⊆ snd(⟨s,A⟩)`**（不是裸 `A ⊆ A`）——须
`snd_pair_same` 归一后再 `Int_lower1`（首版直接给 `A∩B⊆A`
被 refine 拒）；`bspec [OF tail h]` 的双参 OF 在带引号名
假设时失效——改 `from tail hxm have … by (rule bspec)`。

### 四套 stem 编码的对照表

| 通道 | IsPrefix 编码 | 良形编码 | 特有件 |
|---|---|---|---|
| Lean | 存在式 $\exists r, t{+}{+}r=s$ | `List.Pairwise (·<·)` | `List.drop` 表新增元素 |
| Coq | 存在式（`exists r`） | 归纳谓词 `stem`（三构造子） | `prefix_stem` 对头归纳 + inversion |
| Agda | 归纳族（`p-nil/p-refl/p-extend`） | 归纳族 `Stem` | `prefix-stem` 五案覆盖 |
| Prolog | 同步递归 `isPrefix/2` | `stemOK/1`（邻对递增） | 双向查询 + 候选生成 |

四套编码证明的定理集合相同（自反/传递/前段继承良形），
但**可扩展方向**不同：Lean 的存在式最利于 `simp`（结合律
一击）、Coq 的归纳谓词最利于 inversion（构造子信息完整）、
Agda 的归纳族最利于依类型区分（p-nil 与 p-refl 分案）、
Prolog 的子句式天然支持反向查询。这正是「同一数学对象
选不同编码适配不同任务」的范本——第 100 章的 $j``\lambda$
（三种语法对应）与本章的 stem（四种编码）一脉相承。

值得注意的是四套编码里**没有一套**直接给出书 p156 的
「$t=s\cap\alpha$ 」形式——书中用「截到某序数」定义初始
段，机器版统一换成「列表前段/余段分解」。两种定义在
严格递增列上等价（$\alpha$ 可取 $|t|$ 或 $\max t+1$ ），
但机器版的列表分解对递归友好得多——这是「书本定义 →
机器定义」翻译中**等价改形**的常态（第 103 章的
「max → sum」同例）。

## 104.8 机器的边界与工程账

数学边界五条之外，本章的工程线也值得记一笔——七通道
共 ~690 行源码，其中四套 stem 编码（Lean/Coq/Agda/Prolog）
证明的定理集合完全相同（自反/传递/前段继承良形/同 stem
序归结为包含），但证明的「费力点」各异：Lean 费在反证
收口（`simp only [List.cons_append]` 的展开方向）、Coq
费在 inversion 的假设命名、Agda 费在覆盖完备（五案缺一
即 CoverageIssue）、Prolog 几乎免费（声明式定义即程序）。
**同一数学的四种实现成本谱**——这份数据对「证明工程学」
（证明的可移植性/可维护性研究）是现成素材。

Isabelle 通道的「零 auto/blast」纪律（第 103 章立的）在
本章再次验证：Prikry.thy 全部用 `rule`/`from…by` 链，构建
秒级。值得注意的是 `snd_pair_same` 的教训——`unfolding
pleP_def` 暴露的目标是投影形式（`snd(⟨s,A⟩)`）而非裸集
（`A`），给引理前必须先归一投影。这类「定义展开后的形状
管理」是确定性风格的主要成本，换来的是零搜索循环风险。

数学边界五条（工程账见上）：

1. **判定引理的拉姆齐取整不可机化**：$T^\pm$ 的染色对象
   是真类片段 $[\kappa]^{<\omega}$ ，整齐集的取用消费可测
   性；有限层的 R(3,3)=6 穷举只是它的 $n=2$ 维影子。
2. **泛型性与 Mathias 定理的双向**：「对一切稠密开集相遇」
   与「几乎含于一切测度一集」的等价消费 $\omega$ -长的
   对角交构造；机器件只核成员判定的语法。
3. **定理 2.8 的迭代超幂**：$M_\omega$ 、临界点序列、
   $j_{n,\omega}$ 的稳定断言全在类论层。
4. **七通道分工**：Lean/Coq/Agda/Prolog 四套 stem 序
   （存在式/归纳谓词/归纳族/同步递归——同一关系的四种
   编码）；Julia/Python R(3,3)=6 + 候选对拍；Isabelle
   纯延长集论核。stem 冲突一维化（事实 2.3.1 后半）在
   四种编码里各有样本。
5. **穷举层的双重身份**：R(3,3)=6 的 32768 例穷举既是
   判定引理在二维的完全验证，也是可测性拉姆齐内核的
   可计算见证——同一穷举在第 95 章（native_decide）与
   本章（枚举循环）以两种机器形态出场，「组合事实的
   多通道复用」建档。

## 104.9 本章要点与检查问题

（要点八条对应书的五个编号结果 + 机器对接层。）

全章一句话总括：**定义 2.6 的两部件条件（stem + 测度一集）
把「确定」与「约束」分离，判定引理用拉姆齐性把裁决权全部
划给 stem 层，于是纯延长足以裁决一切——「不动 stem 地决定
语句」就是 Prikry 力迫的全部秘密**。三款后果、Mathias
等价、迭代超幂合拢都是这台引擎的下游。

本章与前后章的三条缆绳：(i) **向上**——第 94 章定理 1.6
（可测 ⟹ κ-拉姆齐）是判定引理的直接供能者，第 97 章的
迭代超幂与表示定理供能定理 2.8；(ii) **横向**——第 103
章的三本账表由本章补上第四格，「分层条件」哲学（104.1）
是第 105–108 章全部力迫的模板；(iii) **向下**——Mathias
定理的序列-滤子等价是第 107 章 Mathias 条件、第 110 章
NS 理论的组合原型。读者若只带走一件东西，带「判定性 =
拉姆齐性」这个等式——它是大基数论「组合化」纲领的微缩
胶片。

- **定义 2.6**：$(s,A)$ （stem + 测度一集）；扩展 = stem
  延长 ∨ 纯延长；不相容只能来自 stem（κ⁺-cc 的来源）。
- **判定引理（2.4/2.5）**：任何语句可被不动 stem 的条件
  裁决——$[\kappa]^{<\omega}$ 三染色 + 可测基数的拉姆齐
  性（第 94 章定理 1.6）取整齐集。**判定性 = 拉姆齐性**。
- **定理 2.6**：(1) κ⁺-cc 保上方基数与共尾度；(2) cf(κ)
  =ω（stems 链并）；(3) 无新有界子集（判定引理 + κ-完全
  交把 α-多个裁决压回一个条件）。**第四格**：保基数/改
  共尾度/不加子集。
- **Prikry 序列与 Mathias 定理 2.7**：X 序型 ω、无界、
  几乎含于一切测度一集；$G(X)$ 泛型 ⟺ 序列性质——
  对角交（练习 1.5）第三次消费。
- **定理 2.8**：迭代超幂临界点序列 = Prikry 序列、
  $N=M[G(X)]$ ——第 97 章迭代线与力迫论线的合拢。
- **实测账**：本章源码 ~690 行中四套 stem 编码证明同一
  定理集，实现成本谱从「全借库」（Lean/Pairwise）到「全
  自建」（Agda/五案覆盖）——编码选择决定证明成本的又一
  实证。具体坑位：Lean ple_trans 签名手误由 unusedVariables
  抓获、`List.cons_append`+`cases` 收冲突样本；Coq
  `app_assoc` 正向 rewrite、`stem_cons with (l := 尾)`、
  `skipn_all` 归一；Agda `with … in eq` 保留判别等式、
  record 投影全限定、IsPrefix 构造子须**同步延伸两侧**
  （`IsPrefix t s → IsPrefix (x∷t) (x∷s)`，首版单侧延伸
  编码错误被样本击中）；Julia 顶层循环计数器 `global`；
  Isabelle `snd_pair_same` 归一后才 `Int_lower1`、带引号
  假设的 `bspec [OF _ h]` 失效改 from/by。

检查问题：

（做题前的路标：第 1 题查定义 2.6 第三款的功能——stem 延长
的新元素为什么要进 $B$ ；第 2 题把染色降到一维并对照
「3 点 2 色必有同色对」；第 3 题查 κ-完全交对 $\alpha$
长度的承受力；第 4 题构造含两个互不包含的「核」的族——
有限层滤子性不足正是真值层需要正规超滤子的原因。）

1. 事实 2.3.1 的 (ii) 说不相容只能来自 stem 冲突。若把
   定义 2.6 的第三款 $(s\setminus t)\subseteq B$ 删去，
   (ii) 仍成立吗？哪一款定理会最先崩溃？（提示：stem
   延长后的元素需要落在延长侧的测度一集里。）
2. 引理 2.4 的证明把 $[\kappa]^{<\omega}$ 三染色后按维数
   取整。若语句 $\varphi$ 的裁决只依赖 stem 的**首元素**
   而非全长，证明可以简化到几维？这与 R(3,3)=6 的穷举
   （二维染色）对应哪一层？
3. 定理 2.6(3) 的证明把 $\alpha$ 个单点裁决用 κ-完全交
   压成一个条件。若 $\alpha=\kappa$ （不是 $\alpha< \kappa$ ），哪一步失效？由此说明「无新有界子集」的
   「有界」为何不可去。
4. Julia/Python 通道的 `is_prikry_candidate` 用「尾段入核」
   作为「几乎含于一切测度一集」的影子。构造一个有限宇宙
   $\{0..9\}$ 上的「测度一集族」使「尾段入单核」与
   「几乎含于族中每个集」**不再等价**——并说明真值层为何
   不会发生这种分歧（提示：D 的滤子性与对角交）。

5. 定理 2.8 说临界点序列 $\{\kappa_n\}$ 是 $M_\omega$
   中的 Prikry 序列。由引理 1.38 的序列判据直接验证：
   对每个 $A\in U_\omega$ ，$|\{\kappa_n\}\setminus A| <\omega$ 。这用到了 $U_\omega$ 的哪一条性质（正规性
   还是 κ-完全性）？若只保留另一条，验证在哪里断？

6. 四套 stem 编码（Lean 存在式 / Coq 归纳谓词 / Agda
   归纳族 / Prolog 同步递归）都证了「前段继承良形」。
   把 Agda 的 `prefix-stem` 五案证明翻译成 Lean 的存在式
   版本（用 `List.Pairwise` 的哪条 stdlib 引理？），并
   比较两版证明的行数与依赖深度。

---

收束一行：Prikry 力迫是「大基数假设兑换组合奇迹」的第一
台兑换机——一个可测基数（正规超滤子）兑换出「共尾度手术
而不留疤痕」（无新有界子集）。兑换的汇率表就是判定引理：
拉姆齐性（大基数侧）= 判定性（力迫侧）。第 105 章 Silver
力迫将把兑换物换成「$2^\kappa$ 跳过 $\kappa^+$ 」——
同一家兑换机，不同的币种。

上一章：[103 小型扩张与 Lévy 崩塌](103-levy.md) · 下一章：[105 Silver 力迫](105-silver.md)
