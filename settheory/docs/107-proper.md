# 107 · 恰当力迫

> 自马丁公理被提炼出来之后，人们自然希望得到作用范围更广的
> 「公理」。本章取材冯琦第三卷 §2.6（书页 197–205；PDF
> 218–225）：谢拉赫（S. Shelah, *Proper Forcing*, LNM 940,
> 1982）为回答「什么样的力迫经可数支撑迭代后不会把
> $\omega_1$ 可数化」而引进**恰当力迫**，鲍姆嘎特勒
> （J. Baumgartner, 1984）在此之上提炼**恰当力迫公理 PFA**。
> 谢拉赫的识别标准是一句话：**保持所有可数范围上的荟萃集
> 特性**。路线图：命题 2.1 先证明两条古典充分类——κ-链
> 条件与 <κ-闭包——都保 κ 上的荟萃集；引理 2.22 把结论从
> $\kappa$ 推广到可数范围 $[\kappa]^{\omega}$ ；定义 2.20
> 把「保一切 $[\kappa]^\omega$ 荟萃」立为恰当性的定义；
> 引理 2.23 给出可数覆盖性质（恰当力迫不把 $\omega_1$
> 可数化）；定义 2.21 + 引理 2.24 把恰当性翻译成**局部
> 证书**语言——$(M,\mathbb P)$ -泛型条件及其三等价刻画；
> 定理 2.13/2.14 把局部证书装配成**全局主条件刻画**（恰
> 当 ⟺ 泛型条件在可数同质子模型的无界闭类上、甚至处处
> 存在）；引理 2.25/2.26 与定理 2.15 预告恰当性对迭代封闭
> ——下一章 PFA 的引擎。
>
> 机器边界：本体（club 论证、名字演算、超穷递归链）全在
> 超穷层；七个通道做**证书层**——四件套定义（相容
> Compat / 冲突子集 Antichain / 准稠密 PredenseBelow /
> 泛型条件证书 GenericCond）、**证书下放**
> `generic_strengthen`（Task 22 Step 2 指定件：更强的条件
> 保持证书）、泛型条件搜索与极大反链规模（cc 影子）、以及
> Isabelle 的**链样本** `chain_predense`（命题 2.1(2) 闭包
> 论证的有限影子：链上自动准稠密）。样本宇宙是全书最小的
> ——根 0 分叉到终端 1、2 的三点偏序——但反链、准稠密、
> 证书、下放四层结构俱全。

## 107.1 动机：荟萃性为何脆弱

第 105、106 两章的力迫（Silver 力迫、GMW 力迫）关心的
是**基数账本**——造出 $2^\kappa$ 的特定值。本章回到一个
更早就浮出的问题（书 p198）：**什么样的力迫构思会保持什么
样的子集合的荟萃特性**？

对于不可数正则基数 $\kappa$ ，我们关心两类子集合：无界闭
子集（club）与荟萃子集（stationary）。两者的根本差别在于
逻辑复杂度：

- 「$C$ 是 $\kappa$ 的无界闭子集」是 $\kappa$ 上的
  一阶 $\Pi_1$ 性质——
  $(\kappa,\in)\models\forall\alpha\big((\beta\in C\to \alpha\le\beta)\wedge(\forall_{\xi<\alpha}\beta\in C\to \alpha\in C)\big)$ ；
- 「$S$ 是 $\kappa$ 的荟萃子集」则本质上是二阶性质——
  它要求 $S$ 与**每一个**无界闭子集相交，而量化「每一个
  无界闭子集」就是量化 $\kappa$ 的子集的子集。

$\Pi_1$ 性质对传递模型是绝对的：若 $N\subseteq M$ 都
传递，则 $\Pi_1$ 性质从 $N$ 到 $M$ 不变。所以 club
性从 $V$ 到 $V[G]$ **自动保持**——即使在 $V[G]$ 中
$\kappa$ 的梯度（共尾度或基数身份）发生变化。但荟萃性
**没有**这道保险：力迫可能添进一个全新的无界闭子集 $C$ ，
而 $C\cap S=\varnothing$ ——第一卷例 II.3.13 正是这样的
例子。于是自然要问：**哪些力迫保证旧荟萃集不被新 club 回避**？

谢拉赫展开分析之前，两条古典答案早已为人所知（书 p198）：
链条件与闭包。本章从这两条出发。

一个记号约定（全书力迫章通用，本章反复使用）：条件序
$r\le q$ 读作「$r$ **强于** $q$ 」（$r$ 延展 $q$ ）；
「$r$ 与 $p$ 有公共下界」指存在 $s$ 同时 $s\le r$ 、
$s\le p$ ——两条件**相容**。机器通道的偏序数据以**延展集**
$\mathrm{ext}(q)=\{r\mid r\le q\}$ （含 $q$ 自身）给出，
与这个约定严格对齐。

## 107.2 命题 2.1：cc 与闭包的荟萃保持

**命题 2.1**（书 p198–200） 设 $\kappa$ 是不可数正则基数。

**(1)** 若 $\mathbb P=(P,\le)$ 满足 $\kappa$ -链条件，
$\dot C$ 是 $\kappa$ 的无界闭子集的名字（即
$1\mathbb{1}\Vdash\dot C$ 是 $\kappa$ 的无界闭子集），
则对任意条件 $p\in P$ ，存在 $V$ 中 $\kappa$ 的无界闭
子集 $D\subseteq\kappa$ 使 $p\Vdash D\subseteq\dot C$ 。
从而若 $S\subseteq\kappa$ 荟萃，则
$1\mathbb{1}\Vdash S$ 依旧荟萃。

**(2)** 若 $\mathbb P$ 是 **<κ-闭合**的（任何长度 <κ 的
单调递减条件序列必有下界），$S\subseteq\kappa$ 荟萃，则
$1\mathbb{1}\Vdash S$ 依旧荟萃。

两半的策略截然不同，值得并排细看。

**(1) 的证明骨架（压回去）**：给定 $\dot C$ 与 $p$ ，令

$$
D=\{\alpha<\kappa\mid\forall q\le p\,
\exists\beta\ge\alpha\,(q\Vdash\beta\in\dot C)\}
$$

$D$ 自然是闭的（对上确界封闭）；关键是证 $D$ 无界。
给定 $\alpha_0<\kappa$ ，注意
$p\Vdash\exists\beta>\alpha_0(\beta\in\dot C)$ ，取极大
冲突子集 $W_0$ （势 <κ，由 κ-链条件）见证这一语句的稠密
性，令 $\alpha_1=\sup\{\beta\mid q\in W_0\ \text{且}\ q\Vdash\beta\in\dot C\}$ ，则 $\alpha_0<\alpha_1<\kappa$
且 $1\mathbb{1}\Vdash\dot C\cap(\alpha_0,\alpha_1]\neq \varnothing$ 。对 $\alpha_1$ 重复得 $W_1,\alpha_2,\dots$ ；
$\omega$ 步后 $\alpha_\omega=\sup_n\alpha_n\in D$ 且
$\alpha_\omega>\alpha_0$ 。**链条件的作用**是把「无数个
承诺的 $\beta$ 」装进 <κ 的上确界里——每一步的冲突子集
只有 <κ 个成员，sup 才不会越过 $\kappa$ 。

**(2) 的证明骨架（钻下去）**：设 $p\Vdash\dot f:\kappa\to \kappa$ 是Normal函数（无界闭集的特征：连续严格递增）。递归
构造长度 κ 的单调递增连续序数序列 $\langle\alpha_\xi\mid \xi<\kappa\rangle$ 与单调递减条件序列
$\langle p_\xi\mid\xi<\kappa\rangle$ ：$p_0=p$ ；每步
$p_{\xi+1}\Vdash\alpha_{\xi+1}\in\dot C$ （用稠密性换强
条件）；极限步 $\xi$ 取 $\alpha_\xi=\sup_{\beta<\xi} \alpha_\beta$ ，用 <κ-闭包取 $p_\xi$ 为
$\langle p_\beta\mid\beta<\xi\rangle$ 的下界。序数序列
的值域是 club，与 $S$ 相交；取极限点 $\alpha_\xi\in S$ ，
则 $p_\xi\Vdash\alpha_\xi\in\dot C$ 。**闭包的作用**是在
极限步续命——没有下界，递减链在第一个极限序数处就断了。

两个证明一压一钻：链条件把新 club **压**进旧集合的骨架，
闭包让旧荟萃集在极限点**钻**进新 club。本章七通道的机器里
各有一个影子：Julia/Python 的 `max_antichain_size`
（反链规模受限 = cc 影子）与 Isabelle 的 `chain_predense`
（链上自动准稠密 = 闭包影子）。

两条策略的互补性值得单独强调。链条件是**组合性**的：它约
束偏序的形状（无大反链），与力迫的内容无关——第七章的
Cohen 力迫与 Lévy 塌缩都靠它保基数；它对**方向**没有要求，
递增递减都行。闭包是**序论性**的：它约束偏序的完备程度
（链有下界），对反链规模不设限——一个 σ-闭偏序完全可以有
巨大的反链；它只对**递减**方向负责，因为「取下界」只在递
减链的端点才有意义。两条合起来仍留下大片空地：既不 ccc
也不闭的偏序（比如下一章将反复出场的各种「恰当但不闭」的
偏序）是否保荟萃，命题 2.1 说不了——这正是定义 2.20 要立
新判据的原因。

## 107.3 引理 2.22：推广到 [κ]^ω

可数范围 $[\kappa]^{\omega}$ （$\kappa$ 的可数无穷子集
全体）上的 club 与荟萃结构是第一卷 §I.2.4 的主题（提升与
降落定理 I.2.35 反复被引用）。命题 2.1 可以整体搬到
$[\kappa]^\omega$ 上：

**引理 2.22**（书 p200–201） 设 $\kappa$ 是不可数基数。

**(1)** 若 $\mathbb P$ 满足**可数链条件**，$G$ 是
$V$ 上的泛型滤子，$C$ 是 $V[G]$ 中 $[\kappa]^\omega$
的无界闭子集，则 $V$ 中有 $[\kappa]^\omega$ 的无界闭
子集 $D$ 满足 $D\subseteq C$ 。从而
$S\subseteq[\kappa]^\omega$ 荟萃 ⟹ $S$ 在 $V[G]$ 中
依旧荟萃。

**(2)** 若 $\mathbb P$ 是 **σ-闭合**的（可数递减链有下
界），$S\subseteq[\kappa]^\omega$ 荟萃，则 $S$ 在
$V$ 的 $\mathbb P$ -力迫扩张中依旧荟萃。

**(1) 的骨架**：$[\kappa]^\omega$ 上 club 的标准生成元
是函数 $f:[\kappa]^{<\omega}\to[\kappa]^\omega$ ——
$C_f=\{x\in[\kappa]^\omega\mid\forall\epsilon\in[x]^{<\omega} (f(\epsilon)\subseteq x)\}$ 是 club，且每个 club 包含某个
$C_f$ 。对 $f$ 的名字 $\dot f$ 与 $p\Vdash \dot f$ 见证 club，定义（在 $V$ 中）
$g(\epsilon)=\{\alpha\mid$ 某个 $q$ 力迫
$\dot f(\epsilon)=\alpha$ 加一$\}$ ——**ccc 保证
$g(\epsilon)$ 可数**（至多 $|P|$ 个条件、每个至多承诺
一个 $\alpha$ 的一点点穷尽，可数并仍可数），故
$g:[\kappa]^{<\omega}\to[\kappa]^\omega$ 真是 $V$ 中
的函数。取 $D=C_g$ ：若 $x\in D$ ，则对每个
$\epsilon\in[x]^{<\omega}$ ，$p\Vdash\dot f(\epsilon) \subseteq g(\epsilon)\subseteq x$ ，即 $p\Vdash x\in C_{\dot f}\subseteq C$ 。

**(2) 的骨架**：设 $p\Vdash\dot f:[\kappa]^{<\omega}\to [\kappa]^\omega$ 见证 club，要找 $q\le p$ 与 $x\in S$
使 $q\Vdash x\in C_{\dot f}$ 。取足够大的正则基数
$\lambda\ge\max((2^\kappa)^+,(2^{|P|})^+)$ ，令
$M\prec(H_\lambda,\in,\Delta,\dots)$ 可数（$\Delta$
是 $H_\lambda$ 上的一个固定秩序，由此 $M$ 有可定义的
斯科伦函数；相关参数都在 $M$ 中）。令 $\alpha=M\cap \kappa$ 。把 $[\kappa]^{<\omega}$ 的元素罗列为
$\langle\epsilon_n\mid n<\omega\rangle$ ，用
$M\prec H_\lambda$ 递归定义单调递减链
$p_0=p\ge p_1\ge\cdots$ 使 $p_{n+1}$ 决定
$\dot f(\epsilon_n)$ 的值属于 $M\cap\kappa=\alpha$ ；
令 $q$ 为链的下界（σ-闭合！），$x=\alpha\cup\{\alpha\}$
型的可数集落在 $S$ 的某个提升里（定理 I.2.35），则
$q\Vdash x\in C_{\dot f}$ 。

注意 (2) 的骨架正是本章机器里 `generic_strengthen` 的
「递归换强条件」直觉：**泛型条件 = 一条能对所有要求递归
下降并保持相容性的条件**。

## 107.4 定义 2.20 与引理 2.23：恰当性与可数覆盖

两条充分类到手，立定义的时机成熟：

**定义 2.20**（书 p201） 称力迫构思 $\mathbb P=(P,\le)$
为**恰当力迫构思**（proper）当且仅当对每一个不可数基数
$\kappa$ ，可数范围 $[\kappa]^\omega$ 上的任何一个荟萃
子集 $S$ 在基础模型 $V$ 上经 $\mathbb P$ 的力迫扩张
模型 $V^{\mathbb P}$ 中依旧是荟萃集。

由引理 2.22 立得两个充分类：**一切 ccc 力迫与一切 σ-闭合
力迫都是恰当力迫**。这两个类在第七、八章反复出场（Cohen
力迫 ccc；Lévy 塌缩列在适当位置 σ-闭），本章把它们与迭代
封闭性接通。

恰当力迫不会把 $\omega_1$ 可数化——事实上有更强、更
有趣的**可数覆盖性质**：

**引理 2.23**（书 p201） 设 $\mathbb P$ 恰当，$G$ 是
$V$ 上的 $\mathbb P$ -泛型滤子。则 $V[G]$ 中任何序数
的可数集合一定被 $V$ 中序数的可数集合所覆盖：
$$
\forall X\in([\mathrm{Ord}]^\omega)^{V[G]}\,
\exists Y\in([\mathrm{Ord}]^\omega)^V\,(X\subseteq Y).
$$

**证明骨架**：设 $X$ 是 $V[G]$ 中序数的可数集，令
$\lambda>\sup X$ 为不可数基数。由恰当性，
$[\lambda]^\omega$ 的 club 全体在 $V[G]$ 中依旧生成
同样的滤子骨架，特别地 $[\lambda]^\omega$ **本身**依旧
荟萃（全集是 club）。而集合
$$
\{Y\in[\lambda]^\omega\mid X\subseteq Y\}
$$

在 $V[G]$ 中是无界闭集（闭：递增链的并仍盖 $X$ 的
可数枚举；无界：往任何 $x$ 里逐个添 $X$ 的元素）。荟萃
集与 club 相交，取交点 $Y$ 即为所求——$Y\in V[G]$ 但
$Y\in[\lambda]^\omega$ 且 $X\subseteq Y$ ，配合
$[\lambda]^\omega\cap V$ 在恰当力迫下的覆盖论证（对
$[\lambda]^\omega$ 的 club 取交）给出 $Y$ 可取自
$V$ 。

这句话读起来平淡，威力在下一章：**PFA 下每个「新」可数
序数集都装在某个「旧」可数集里**，这使得
$\omega_1$ -保持的论证成为例行公事。

## 107.5 定义 2.21 与引理 2.24：(M,P)-泛型条件

恰当性的定义是对**一切** $[\kappa]^\omega$ 荟萃集的全程
量词，直接验证几乎不可能。谢拉赫的核心贡献是把它翻译成
**局部证书**：只需在每个可数同质子模型里找到一条好条件。

固定语言装置（书 p201–202）：$\chi>2^{|P|}$ 正则，
$H_\chi$ 是遗传势 $\le\chi$ 的集合全体；$\Delta$ 是
$H_\chi$ 上的一个固定秩序，由此每个
$M\prec(H_\chi,\in,\Delta,\dots)$ 都有按 $\Delta$
可定义的斯科伦函数。**可数**同质子模型 $M$ 的全体记
$C[\chi]$ （这是 $[H_\chi]^\omega$ 的 club 子集，第一
卷定理 I.2.34/2.35 的标准对象）。

**定义 2.21**（书 p201） 设 $\mathbb P=(P,\le)$ 是力迫
构思，$\lambda>2^{|P|}$ 正则，$M\prec(H_\lambda,\in, \Delta,\dots)$ 可数且 $P\in M$ 。称条件 $q\in P$ 为一个
**$(M,\mathbb P)$ -泛型条件**当且仅当：对于 $M$ 中任何
一个 $\mathbb P$ 的**极大冲突子集**（极大反链）$A$ 而
言，子集合 $A\cap M$ 都在 $q$ 之下是**准稠密**的：
对于 $\mathbb P$ 中的任何 $r\le q$ ，都有一个
$p\in A\cap M$ 来保证 $r$ 与 $p$ 有公共下界。

三个角色的分工值得咀嚼：

- **$A\in M$ 是** $M$ **看得见的**极大反链——泛型滤子
  遇见 $A$ 时选出的那个元素 $q_A$ 是 $M$ 可定义的；
- **$A\cap M$ 只保留** $M$ 内的候选——绝大多数成员被
  截掉，剩下的部分只在 $q$ **下方**稠密，不再全域稠密；
- **$q$ 是证书持有人**——它承诺：任何往下的细化 $r$
  都还能跟 $M$ 内的某个候选会合。

准稠密（predense below q）弱于稠密（dense）：全域稠密要求
每个 $r\in P$ 都相容于 $A$ ；准稠密只要求 $q$ 下方的
$r$ 。**$q$ 越强（延展集越小），准稠密越容易满足**——
这正是机器通道 `generic_strengthen` 证书下放的方向：条件
复合（取更强的条件）不会丢失证书。反过来，$q$ 弱到域底
时准稠密退化成全域稠密——大多数反链做不到，所以泛型条件
是稀有的、结构性的。

把定义与定理 2.14 连读还能读出一层「义务账」：要证明
$\mathbb P$ 恰当，(i) 对每个**给定的**可数 $M$ 与
$p$ ，要**造出**一条 $q\le p$ 并对 $M$ 的**每一个**
极大反链验证准稠密——义务在构造方；而应用 PFA 时方向反过
来：(ii) 泛型滤子 $G$ 遇见 $M$ 的每个极大反链 $A$
后，交点 $G\cap A$ 的那个元素自动落进 $M$ 可定义的
位置——义务由证书代偿。引理 2.24 的三个等价形态正是这两种
义务的记账语言互换。

1. $q$ 是 $(M,\mathbb P)$ -泛型条件；
2. 对每个序数的名字 $\dot\alpha\in M$ ：
   $q\Vdash_M\dot\alpha\in M$ （记号：$q\Vdash \dot\alpha\in\tilde M$ ——名字在 $M$ 内，则其力迫值
   被 $M$ 的序数界定）；
3. $q\Vdash\dot G\cap M$ 是 $M$ 之上的一个
   $\mathbb P$ -泛型滤子（即与 $P\cap M$ 的每个
   $M$ -内稠密集相交）。

**证明骨架**：

**(1)→(2)** 设 $\dot\alpha\in M$ 是序数的名字。令
$D=\{r\mid\exists\beta\, r\Vdash\dot\alpha=\beta\}\in M$
（由 $\Delta$ -可定义性），$D$ 稠密。令 $A\supseteq D$
为秩序 $\Delta$ 之下的**最小**极大冲突子集——最小性保证
$A\in M$ 。由 (1)，$A\cap M$ 在 $q$ 之下准稠密：任取
$r\le q$ ，有 $p\in A\cap M$ 与公共下界
$s\le r,\ s\le p$ 。$p\in A\cap M$ 力迫
$\dot\alpha=\beta$ （$A$ 的成员都决定 $\dot\alpha$
的值）于某个 $\beta$ ；由 $p,\dot\alpha\in M$ 与
$\Delta$ -可定义性，$\beta\in M$ 。于是
$s\Vdash\dot\alpha=\beta\in M$ 。这些 $s$ 在 $q$
下方稠密，得 $q\Vdash\dot\alpha\in\tilde M$ 。

**(2)→(1)** 练习（对偶地把极大反链的「被选中者」当作名字
处理）。

**(1)→(3)** 设 $A\in M$ 是 $P\cap M$ 的准稠密子集。
由 $M\prec H_\lambda$ 与 $P,A\in M$ ，「$A$ 在
$P\cap M$ 中准稠密」这一性质反射进 $M$ ：
$M\models$ 「$A$ 是 $P$ 的准稠密子集」。于是 $A$
可扩成 $M$ 中的极大冲突子集
$A'\supseteq A,\ A'\in M$ （$\Delta$ -最小扩法）。由
(1)，$A'\cap M$ 在 $q$ 之下准稠密；若 $q\in G$ ，
则 $G\cap A'\cap M\neq\varnothing$ ，特别地
$G\cap A\neq\varnothing$ 。

**(3)→(1)** 练习（把极大反链的准稠密性翻译成 $M$ -内
稠密集的相交要求）。

(2) 是「泛型条件 = 名言录」的形态：$M$ 内名字的值逃不出
$M$ 。107.6 主条件刻画的充分性证明用的正是这一形态。

## 107.6 定理 2.13/2.14：主条件刻画

**定理 2.13**（书 p203） $\mathbb P$ 恰当的充要条件是：
对任意足够大（$>2^{|P|}$ ）的正则基数 $\lambda$ ，由所有
满足
$$
|M|=\omega\ \wedge\ \forall p\in M\cap P\,\exists q\le p
\ (q\ \text{是}(M,\mathbb P)\text{-泛型条件})
$$

的 $M\prec(H_\lambda,\in,\Delta,\dots)$ 组成的集合
$C_\lambda$ 包含 $C[\lambda]$ 的一个无界闭子集。

**必要性（反证骨架）**：设 $\mathbb P$ 恰当而 $C_\lambda$
不含 club，则补集荟萃。由无界闭子集滤子的正则性，取
$p\in P$ 与荟萃集 $S\subseteq C[\lambda]$ 使
$$
\forall M\in S\ (p\in M\ \wedge\ \forall q\le p\
(q\ \text{不是}(M,\mathbb P)\text{-泛型条件})).
$$

取 $V$ 上的泛型滤子 $G\ni p$ ，在 $V[G]$ 中讨论：
对 $p$ 之下的每个极大冲突子集 $A\in V$ ，$A\cap G$
恰有一个元素 $q_A$ 。令
$D=\{M\mid A\in M\ \text{是}p\text{之下极大冲突子集}\Rightarrow q_A\in M\}$ ——这是 $V[G]$ 中的 club（每条要求都反射）。
取 $M\in D\cap S$ （$S$ 在 $V[G]$ 中依旧荟萃——恰当
性！）。对 $M$ 中 $p$ 之下的每个极大反链 $A$ ：
$q_A\in M$ ，且 $q_A\le\bigwedge(A\cap M)$ 型的下达条件
使 $\Sigma(A\cap M)\in G$ 。令
$q\le p$ 强于所有这些 $\Sigma(A\cap M)$ （$M$ 可数，
有限特征足够），则 $q$ 就是 $(M,\mathbb P)$ -泛型条件
——与 $M\in S$ 矛盾。

**充分性（反射骨架）**：设每个 $C_\lambda$ 含 club。取
不可数 $\kappa$ 与荟萃 $S\subseteq[\kappa]^\omega$ ，
$\dot f$ 名字，$p\Vdash\dot f:[\kappa]^{<\omega}\to [\kappa]^\omega$ 。取 $\lambda>\kappa$ 足够大正则；由
假设与提升降落定理（I.2.35），
$\{M\mid M\cap\kappa\in S\ \wedge\ M\in C_\lambda\}$ 在
$[\lambda]^\omega$ 中荟萃，取出这样的 $M$ 。令
$\alpha=M\cap\kappa$ ，取 $q\le p$ 为 $(M,\mathbb P)$ -
泛型条件。断言 $q\Vdash\mathrm{ran}(\dot f)\!\upharpoonright\! [\alpha]^{<\omega}\subseteq\alpha$ 的封套型语句：对
$\epsilon\in[\alpha]^{<\omega}$ ，$M$ 内有极大反链
$A$ 完全确定 $\dot f(\epsilon)$ 的取值；由 $A\cap M$
在 $q$ 之下准稠密，任何 $r\le q$ 与某个
$s\in A\cap M$ 相容，$s$ 力迫 $\dot f(\epsilon)=x_s$ ，
而 $x_s$ 由 $s,f,\epsilon\in M$ 可定义，故
$x_s\in M$ 、$x_s\subseteq\alpha$ 。于是
$q\Vdash\alpha\cup\{\alpha\}$ 型封套落在 $C_{\dot f}$
中，即 $q$ 力迫 $S$ 的某点进入 club——荟萃性保持。

定理 2.13 的 club 形态在应用中还不顺手（要验证一个 club），
谢拉赫把它加强成**处处存在**的形态：

**定理 2.14**（书 p204） $\mathbb P$ 恰当的充要条件是：
对任意 $p\in P$ 、任意足够大的正则 $\lambda$ 、任意包含
$\{p,P\}$ 的可数 $M\prec(H_\lambda,\in,\Delta,\dots)$ ，
都存在 $q\le p$ 是 $(M,\mathbb P)$ -泛型条件。

**证明骨架**：充分性显然——
$\{M\prec(H_\lambda,\dots)\mid p,P\in M\ \wedge\ |M|=\omega\}$
本来就是无界闭集。必要性：令
$C_\mu=\{M\mid M\cap\mu\in C_\lambda\}$ （$\mu= (2^{|P|})^+$ ），由定理 2.13 与提升降落定理，$C_\mu$ 包含
$[\mu]^\omega$ 的 club。于是存在 $f:[\mu]^{<\omega}\to\mu$
使 $C_f\subseteq C_\mu$ ；在 $\Delta$ 下**最小的**这样
的 $f$ 必属于每个可数同质子模型 $M$ 。于是若
$\{p,P\}\subseteq M$ ，则 $M$ 关于 $f$ 封闭，
$M\in C_\mu$ ，即存在 $q\le p$ 泛型。

定理 2.14 就是 PFA 的直接工作形态：**泛型条件不仅存在，
而且在每个条件下方都存在**——「求一条好条件」成为可以
逐点执行的操作。

## 107.7 迭代封闭：引理 2.25/2.26 与定理 2.15 预告

**引理 2.25**（书 p204） 设 $\mathbb P$ 恰当，$\dot Q$
是名字且 $1\mathbb{1}\Vdash\dot Q$ 恰当。则两步迭代
$\mathbb P*\dot Q$ 也恰当。

**证明骨架**：设 $\kappa$ 不可数，$S\subseteq [\kappa]^\omega$ 荟萃。设 $G$ 是 $V$ 上 $\mathbb P$ -
泛型滤子、$H$ 是 $V[G]$ 上 $\dot Q/G$ -泛型滤子。由
$\mathbb P$ 恰当，$S$ 在 $V[G]$ 中依旧荟萃；由
$1\Vdash\dot Q$ 恰当，$S$ 在 $V[G][H]$ 中依旧荟萃。
两步荟萃保持串联即得。

更进一步的分析需要**复合证书**——把 $(M,\mathbb P)$ -
泛型条件与 $(M,\mathbb P*\dot Q)$ -泛型条件焊接起来：

**引理 2.26**（书 p205） 设 $\mathbb P$ 恰当，
$1\mathbb{1}\Vdash\dot Q$ 恰当，$\mathbb R=\mathbb P* \dot Q$ ，$\lambda$ 足够大正则，$M\prec(H_\lambda,\dots)$
可数。则对每个 $(M,\mathbb P)$ -泛型条件 $q_0$ 、每个
满足 $q_0\Vdash\dot p\in(\mathbb R\cap M)[\dot G]$ 的
$\dot p$ ，存在 $(M,\mathbb R)$ -泛型条件
$(q_0,q_1)\in\mathbb R$ 使 $(q_0,q_1)\Vdash\dot p\in \dot G*\dot H$ 。

**骨架**：设 $G\ni q_0$ ，在 $V[G]$ 中解析
$\dot p$ ：$p_1=\dot p/G$ ，$\mathbb Q=\dot Q/G$ 。由
$\mathbb Q$ 在 $V[G]$ 中恰当，取 $q_1\le p_1$ 为
$(M[G],\mathbb Q)$ -泛型条件（其中
$M[G]=\{\dot\tau/G\mid\dot\tau\in M\}$ ）。为 $q_1$
取名字 $\dot q_1$ ，则 $(q_0,\dot q_1)$ 即所求：$q_0$
的证书管第一步的极大反链，$q_1$ 的证书管第二步——
**证书的复合**。机器通道的 `generic_strengthen` 下放核查
（Julia/Python 全域穷举「$p$ 泛型 ∧ $q$ 强于 $p$
⟹ $q$ 泛型」）正是这一复合保持的有限影子。

**定理 2.15（Shelah，书 p205，下一章主角）** 若
$\langle\mathbb P_\alpha,\dot{\mathbb Q}_\beta\mid \beta<\alpha\rangle$ 是可数支撑迭代且每一步
$1\Vdash_{\mathbb P_\beta}\dot{\mathbb Q}_\beta$ 恰当，
则 $\mathbb P_\alpha$ 恰当。

引理 2.25 处理一步，定理 2.15 处理超穷步——可数支撑
（countable support）的取法正是为了在极限步维持证书：每个
泛型条件只需与可数多个先前坐标的信息会合。这是谢拉赫
引进恰当性的**根本动机**，也是下一章 PFA 相对超紧基数
合理性的引擎。PFA 本身（Baumgartner 1984）：**对每个恰当
力迫 $\mathbb P$ 与每个至多 $\aleph_1$ 个稠密集的族，
存在滤子与每个稠密集相交**——MA 把「ccc」放宽到「恰当」，
代价是相容性证明需要超紧基数与超长的可数支撑迭代。

## 107.8 与前章的对照总表

| 维度 | 105 Silver | 106 GMW | 107 恰当 |
|---|---|---|---|
| 目标 | $2^\kappa=\kappa^{++}$ | $\aleph_\omega$ 处首败 | 保 $[\kappa]^\omega$ 荟萃 |
| 力迫类型 | Easton 支撑迭代 | $(f,T,\tau,H)$ 四部件 | 全类（抽象性质） |
| 关键引理 | λ-定向完全 2.6 | Prikry 条件 2.17 | 主条件刻画 2.13/2.14 |
| 基数账本 | κ 处跳档 | $\aleph_{\omega+2}$ | 不动 $\omega_1$ |
| 迭代封闭 | — | — | 可数支撑（定理 2.15） |
| 机器影子 | 序函数账簿 | 位移支配 | 证书四件套 + 下放 |

三条线的分野在于**力迫对象**：105/106 造一个特定偏序来
改写连续统函数；107 不造偏序，而是给「不破坏荟萃性」的
偏序划类——本章的定理都是**类层面的判据**，这就是为什么
机器通道只做证书的有限影子而不模拟任何具体力迫。

## 107.9 机器通道

七个通道共享一个三层设计：

1. **偏序数据**：延展集 $\mathrm{ext}:q\mapsto\{r\mid r\le q\}$ （含 $q$ 自身）。样本宇宙 `extT` 取根 0 分叉到
   终端 1、2 的三点偏序：`extT(0)={0,1,2}`、`extT(1)={1}`、
   `extT(2)={2}`、其余为空。反链 $\{1,2\}$ 是这个宇宙
   里唯一的 2 元冲突对。
2. **四件套定义**（严格对齐正文）：
   - `Compat r p`：相容——有公共延展
     $\exists s\,(s\in\mathrm{ext}\,r\wedge s\in \mathrm{ext}\,p)$ ；
   - `Antichain A`：冲突子集——两两不相容；
   - `PredenseBelow A q`：准稠密——$\forall r\in \mathrm{ext}\,q,\ \exists p\in A,\ \mathrm{Compat}\ r\ p$ （定义 2.21 的内核）；
   - `GenericCond 𝒜 q`：证书——对反链族里每个 $A$ 都
     准稠密。
3. **两个定理件**：
   - `generic_strengthen`（Task 22 Step 2 指定件）：
     $\mathrm{ext}\,q'\subseteq\mathrm{ext}\,q$
     （$q'$ 强于 $q$ ）⟹ 证书下放——引理 2.26 复合
     证书的有限影子；
   - 泛型条件搜索（Julia/Python）与链样本
     `chain_predense`（Isabelle）——命题 2.1(2) 的闭包
     影子。

表示层的选型在七个文化里各取所长，但映射关系是固定的：
Lean 用 `Finset ℕ`（成员可判定、`decide` 一键关账）、Coq
与 Agda 用 `list nat`（结构归纳一等公民、Agda 配 Bool
成员 `inL` 走可判定路线）、Julia/Python 用集合类型（交并
包含直接写）、Prolog 用表加 `member/2` 回溯、Isabelle 干脆
用 ZF 集合本体（`⊆`、`∩` 直接来自 `ZF.equalities`）。无论
表示如何，「$q$ 的延展集」这一**偏序数据**与四件套的
**量词形状**逐字一致——这正是跨通道对拍有意义的前提：七
份代码证的是同一个数学命题，而不是七个相似的程序。

先看 Lean 版（`examples/lean/Settheory/Ch107Proper.lean`）。
定义层用 `Finset ℕ` 承载延展集，四件套各占一个 `def`：

```lean
import Mathlib.Data.List.Basic
import Mathlib.Data.Finset.Basic

/-!
# 第 107 章 · 恰当力迫

锚点（有限影子）：
- `Antichain`：M 内已知极大冲突子集（两两不相容）；
- `PredenseBelow`：A 在 q 之下准稠密——一切 r ≤ q 与 A
  中某元素相容（定义 2.21 主条件证书的内核）；
- `GenericCond`：(M,P)-泛型条件证书——对每个已知极大
  冲突子集都准稠密；
- `generic_strengthen`：更强的条件保持证书（Task 22
  Step 2 指定件：条件复合保持证书）；
- 三点样本宇宙：根 0 分叉到终端 1、2——反链 {1,2} 是
  M={0,1,2} 内唯一极大冲突子集，0 与 1 都是泛型条件。
本体（命题 2.1、引理 2.22-2.24、定理 2.13/2.14）留在正文。
-/

namespace Settheory.Ch107

open Finset

/-- 相容：两条件有公共延展。 -/
def Compat (ext : ℕ → Finset ℕ) (r p : ℕ) : Prop :=
  ∃ s, s ∈ ext r ∧ s ∈ ext p

/-- 冲突子集：两两不相容。 -/
def Antichain (ext : ℕ → Finset ℕ) (A : Finset ℕ) : Prop :=
  ∀ p ∈ A, ∀ q ∈ A, p ≠ q → ¬ Compat ext p q

/-- A 在 q 之下准稠密：一切 r ≤ q（r 延展 q）与 A 中
某元素相容。 -/
def PredenseBelow (ext : ℕ → Finset ℕ) (A : Finset ℕ) (q : ℕ) : Prop :=
  ∀ r ∈ ext q, ∃ p ∈ A, Compat ext r p

/-- (M,P)-泛型条件证书：对 M 的每个已知极大冲突子集
都准稠密（定义 2.21）。 -/
def GenericCond (ext : ℕ → Finset ℕ) (𝒜 : Finset (Finset ℕ)) (q : ℕ) : Prop :=
  ∀ A ∈ 𝒜, PredenseBelow ext A q

/-- 更强的条件保持证书（条件复合保持证书）：q' 延展 q
（q' 的一切延展也是 q 的延展）⟹ q 的证书下放给 q'。 -/
theorem generic_strengthen {ext : ℕ → Finset ℕ}
    {𝒜 : Finset (Finset ℕ)} {q q' : ℕ}
    (hsub : ext q' ⊆ ext q)
    (h : GenericCond ext 𝒜 q) : GenericCond ext 𝒜 q' := by
  intro A hA r hr'
  exact h A hA r (hsub hr')

/-- 样本宇宙：根 0 分叉到终端 1、2（0 可延展到 0/1/2，
1、2 各自终端）。 -/
def extT : ℕ → Finset ℕ
  | 0 => {0, 1, 2}
  | 1 => {1}
  | 2 => {2}
  | _ => ∅

theorem extT_mono_10 : extT 1 ⊆ extT 0 := by decide
theorem extT_mono_20 : extT 2 ⊆ extT 0 := by decide

theorem compat_10 : Compat extT 0 1 := ⟨1, by decide, by decide⟩
theorem compat_02 : Compat extT 0 2 := ⟨2, by decide, by decide⟩
theorem compat_11 : Compat extT 1 1 := ⟨1, by decide, by decide⟩
theorem compat_22 : Compat extT 2 2 := ⟨2, by decide, by decide⟩

/-- {1,2} 是反链（终端 1 与 2 不相容）。 -/
theorem antichain_12 : Antichain extT {1, 2} := by
  intro p hp q hq hpq hcp
  simp only [mem_insert, mem_singleton] at hp hq
  rcases hp with rfl | rfl <;> rcases hq with rfl | rfl
  · exact hpq rfl
  · obtain ⟨s, hs, hs'⟩ := hcp
    simp only [extT, mem_singleton] at hs hs'
    omega
  · obtain ⟨s, hs, hs'⟩ := hcp
    simp only [extT, mem_singleton] at hs hs'
    omega
  · exact hpq rfl

/-- {1,2} 在 q=0 之下准稠密。 -/
theorem predense_12_0 : PredenseBelow extT {1, 2} 0 := by
  intro r hr
  simp only [extT, mem_insert, mem_singleton] at hr
  rcases hr with rfl | rfl | rfl
  · exact ⟨1, by decide, compat_10⟩
  · exact ⟨1, by decide, compat_11⟩
  · exact ⟨2, by decide, compat_22⟩


/-- 0 是 (M,P)-泛型条件。 -/
theorem generic_0 : GenericCond extT {{1, 2}} 0 := by
  intro A hA
  simp only [mem_singleton] at hA
  rw [hA]
  exact predense_12_0

/-- 证书下放：1（强于 0）也是泛型条件。 -/
example : GenericCond extT {{1, 2}} 1 :=
  generic_strengthen extT_mono_10 generic_0

/-- 2 同样继承。 -/
example : GenericCond extT {{1, 2}} 2 :=
  generic_strengthen extT_mono_20 generic_0

end Settheory.Ch107
```

注意 `generic_strengthen` 的证明只有两行：证书下放的本质
就是「延展集的包含关系顺着量词传递」——`hsub hr'` 把
$r\in\mathrm{ext}\,q'$ 转成 $r\in\mathrm{ext}\,q$ ，旧
证书直接可用。 Lean 里 `example` 两条见证了定理 2.14 的
有限形态：**强条件处泛型条件存在**（1、2 都是 0 的细化，
都继承证书）。

Coq 版（`examples/coq/Ch107_proper.v`）用 `list nat` 承载
延展集，同样的四件套；反链证明把两个方向拆成
`not_compat_12/21` 两条引理（Coq 的 `In` 双向不对称）：

```coq
(* 第 107 章：主条件证书、准稠密与 (M,P)-泛型条件的有限影子。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

Module Ch107.

(* 偏序数据：ext q = q 的延展（含自身）。样本宇宙：三点分叉。 *)
Definition extT (q : nat) : list nat :=
  match q with
  | 0 => [0; 1; 2]
  | 1 => [1]
  | 2 => [2]
  | _ => []
  end.

(* 相容：有公共延展。 *)
Definition Compat (ext : nat -> list nat) (r p : nat) : Prop :=
  exists s, In s (ext r) /\ In s (ext p).

(* 冲突子集：两两不相容。 *)
Definition Antichain (ext : nat -> list nat) (A : list nat) : Prop :=
  forall p, In p A -> forall q, In q A -> p <> q -> ~ Compat ext p q.

(* A 在 q 之下准稠密。 *)
Definition PredenseBelow (ext : nat -> list nat)
  (A : list nat) (q : nat) : Prop :=
  forall r, In r (ext q) -> exists p, In p A /\ Compat ext r p.

(* (M,P)-泛型条件证书。 *)
Definition GenericCond (ext : nat -> list nat)
  (As : list (list nat)) (q : nat) : Prop :=
  forall A, In A As -> PredenseBelow ext A q.

(* 更强的条件保持证书（条件复合保持证书）。 *)
Lemma generic_strengthen : forall ext As q q',
  incl (ext q') (ext q) ->
  GenericCond ext As q -> GenericCond ext As q'.
Proof.
  intros ext As q q' Hsub H A HA r Hr'.
  apply (H A HA r).
  apply Hsub. exact Hr'.
Qed.

(* {1,2} 是反链。 *)
Lemma not_compat_12 : ~ Compat extT 1 2.
Proof.
  intros [s [Hs Hs']].
  unfold extT in Hs, Hs'.
  simpl in Hs, Hs'.
  destruct Hs as [E1|[]]; destruct Hs' as [E2|[]].
  rewrite <- E1 in E2. discriminate.
Qed.

Lemma not_compat_21 : ~ Compat extT 2 1.
Proof.
  intros [s [Hs Hs']].
  unfold extT in Hs, Hs'.
  simpl in Hs, Hs'.
  destruct Hs as [E1|[]]; destruct Hs' as [E2|[]].
  rewrite <- E2 in E1. discriminate.
Qed.

Lemma antichain_12 : Antichain extT [1; 2].
Proof.
  intros p Hp q Hq Hne Hcp.
  simpl in Hp, Hq.
  destruct Hp as [Ep|[Ep|[]]]; destruct Hq as [Eq|[Eq|[]]]; subst.
  all: try (exfalso; apply Hne; reflexivity).
  - exact (not_compat_12 Hcp).
  - exact (not_compat_21 Hcp).
Qed.

(* {1,2} 在 q=0 之下准稠密。 *)
Lemma predense_12_0 : PredenseBelow extT [1; 2] 0.
Proof.
  intros r Hr. simpl in Hr.
  destruct Hr as [Er|[Er|[Er|[]]]]; subst r.
  - exists 1. split; [left; reflexivity|].
    exists 1. simpl. auto.
  - exists 1. split; [left; reflexivity|].
    exists 1. simpl. auto.
  - exists 2. split; [right; left; reflexivity|].
    exists 2. simpl. auto.
Qed.

(* 0 是 (M,P)-泛型条件。 *)
Lemma generic_0 : GenericCond extT [[1; 2]] 0.
Proof.
  intros A HA. destruct HA as [HA|[]]. subst A.
  apply predense_12_0.
Qed.

(* 证书下放：1 与 2 也泛型。 *)
Lemma extT_mono_10 : incl (extT 1) (extT 0).
Proof. intros x Hx. simpl in *. destruct Hx; auto. Qed.

Lemma extT_mono_20 : incl (extT 2) (extT 0).
Proof. intros x Hx. simpl in *. destruct Hx; auto. Qed.

Example generic_1 : GenericCond extT [[1; 2]] 1.
Proof. apply (generic_strengthen extT [[1;2]] 0 1 extT_mono_10 generic_0). Qed.

Example generic_2 : GenericCond extT [[1; 2]] 2.
Proof. apply (generic_strengthen extT [[1;2]] 0 2 extT_mono_20 generic_0). Qed.

End Ch107.
```

`generic_strengthen` 在 Coq 里是四行战术：`apply (H A HA r)`
把目标交给旧证书，`apply Hsub. exact Hr'.` 完成延展集的
转递。注意 `generic_1/generic_2` 的应用必须**显式给全参**
`(generic_strengthen extT [[1;2]] 0 1 …)`——Coq 的
`apply` 无法从目标反向推断 `q`（目标里只出现 `q'`）。

Agda 版（`examples/agda/Ch107_proper.agda`）沿 103/105 章
验证过的 **Bool 成员路线**：`inL : ℕ → List ℕ → Bool` 加
真值族 `T : Bool → Set`，把「可判定的成员关系」与「命题
层」焊接；反链族的成员关系用单层归纳族 `_∈F_`：

```agda
-- 第 107 章：主条件证书与 (M,P)-泛型条件（有限影子）。
module Ch107_proper where

open import Data.Nat using (ℕ; zero; suc)
open import Data.List using (List; []; _∷_)
open import Data.Bool using (Bool; true; false; if_then_else_; _∨_)
open import Data.Product using (_×_; _,_; ∃-syntax)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Relation.Nullary using (¬_)
open import Data.Unit using (⊤; tt)

-- ── 零、自建件：Bool 成员与真值族（沿 103/105 章 inKeys 路线） ──

nat-eq : ℕ → ℕ → Bool
nat-eq zero zero = true
nat-eq zero (suc _) = false
nat-eq (suc _) zero = false
nat-eq (suc m) (suc n) = nat-eq m n

inL : ℕ → List ℕ → Bool
inL x [] = false
inL x (y ∷ ys) = if nat-eq y x then true else inL x ys

T : Bool → Set
T true = ⊤
T false = ⊥

-- ── 一、相容、反链、准稠密（定义 2.21 的内核） ──

Compat : (ℕ → List ℕ) → ℕ → ℕ → Set
Compat ext r p = ∃[ s ] ((inL s (ext r) ≡ true) × (inL s (ext p) ≡ true))

Antichain : (ℕ → List ℕ) → List ℕ → Set
Antichain ext A = ∀ p → T (inL p A) → ∀ q → T (inL q A) →
  ¬ (p ≡ q) → ¬ (Compat ext p q)

PredenseBelow : (ℕ → List ℕ) → List ℕ → ℕ → Set
PredenseBelow ext A q = ∀ r → T (inL r (ext q)) →
  ∃[ p ] (T (inL p A) × Compat ext r p)

-- 反链族的成员（单层用归纳族即可——无荒谬模式需求）。
data _∈F_ : List ℕ → List (List ℕ) → Set where
  fhere  : ∀ {A Fs} → A ∈F (A ∷ Fs)
  fthere : ∀ {B A Fs} → A ∈F Fs → A ∈F (B ∷ Fs)

GenericCond : (ℕ → List ℕ) → List (List ℕ) → ℕ → Set
GenericCond ext 𝒜 q = ∀ A → A ∈F 𝒜 → PredenseBelow ext A q

-- ── 二、条件复合保持证书（Task 22 Step 2 指定件） ──

inL-mono : (xs ys : List ℕ) → (∀ x → inL x xs ≡ true → inL x ys ≡ true) →
  ∀ x → inL x xs ≡ true → inL x ys ≡ true
inL-mono xs ys h x hx = h x hx

generic-strengthen : (ext : ℕ → List ℕ) →
  (𝒜 : List (List ℕ)) → (q q' : ℕ) →
  (∀ r → T (inL r (ext q')) → T (inL r (ext q))) →
  GenericCond ext 𝒜 q → GenericCond ext 𝒜 q'
generic-strengthen ext 𝒜 q q' hsub h A hA r hr' =
  h A hA r (hsub r hr')

-- ── 三、样本宇宙：根 0 分叉到终端 1、2 ──

extT : ℕ → List ℕ
extT zero = zero ∷ suc zero ∷ suc (suc zero) ∷ []
extT (suc zero) = suc zero ∷ []
extT (suc (suc zero)) = suc (suc zero) ∷ []
extT _ = []

A12 : List ℕ
A12 = suc zero ∷ suc (suc zero) ∷ []

-- {1,2} 是反链。
antichain-12 : Antichain extT A12
antichain-12 (suc zero) hp (suc zero) hq hne
  ((suc zero) , refl , refl) = hne refl
antichain-12 (suc zero) hp (suc (suc zero)) hq hne
  ((suc zero) , refl , ())
antichain-12 (suc zero) hp (suc (suc zero)) hq hne
  ((suc (suc zero)) , () , refl)
antichain-12 (suc (suc zero)) hp (suc zero) hq hne
  ((suc zero) , () , refl)
antichain-12 (suc (suc zero)) hp (suc zero) hq hne
  ((suc (suc zero)) , refl , ())
antichain-12 (suc (suc zero)) hp (suc (suc zero)) hq hne
  ((suc (suc zero)) , refl , refl) = hne refl
antichain-12 (suc (suc (suc p))) () q hq hne hcp
antichain-12 p hp (suc (suc (suc q))) () hne hcp

-- {1,2} 在 q=0 之下准稠密。
predense-12-0 : PredenseBelow extT A12 zero
predense-12-0 zero hr =
  suc zero , tt , ((suc zero) , refl , refl)
predense-12-0 (suc zero) hr =
  suc zero , tt , ((suc zero) , refl , refl)
predense-12-0 (suc (suc zero)) hr =
  suc (suc zero) , tt , ((suc (suc zero)) , refl , refl)
predense-12-0 (suc (suc (suc r))) ()

-- 0 是 (M,P)-泛型条件。
generic-0 : GenericCond extT (A12 ∷ []) zero
generic-0 A fhere = predense-12-0

-- 证书下放：1 也泛型。
extT-mono-10 : ∀ x → T (inL x (extT (suc zero))) →
               T (inL x (extT zero))
extT-mono-10 (suc zero) h = tt

generic-1 : GenericCond extT (A12 ∷ []) (suc zero)
generic-1 = generic-strengthen extT (A12 ∷ []) zero (suc zero)
  extT-mono-10 generic-0

-- 2 同样继承。
extT-mono-20 : ∀ x → T (inL x (extT (suc (suc zero)))) →
               T (inL x (extT zero))
extT-mono-20 (suc (suc zero)) h = tt

generic-2 : GenericCond extT (A12 ∷ []) (suc (suc zero))
generic-2 = generic-strengthen extT (A12 ∷ []) zero (suc (suc zero))
  extT-mono-20 generic-0
```

`antichain-12` 的七个子句值得读一遍：前六个按 $p,q\in \{1,2\}$ 的具体值分案——对角情形（$p=q$ ）由 `hne refl`
（矛盾于 $p\ne q$ ）关闭；非对角情形的相容见证 $s$ 只能
是 1 或 2，而 `extT` 里 1 与 2 的延展集不相交，两个子句各
用一个**荒谬模式** `()` 关闭。末两个子句处理 $p$ 或 $q$
≥3（不在 `A12` 中）的荒谬。这是索引族成员证明在 Agda 里的
标准形状：**先具体化、再荒谬化**。

Isabelle 版（`examples/isabelle/ST107/Proper.thy`）是七份
中最「纯集论」的一份：不用延展集函数，直接以集合运算陈述
证书（$q$ 本身就是延展集），全部证明走 103 章立下的
**确定性规则链**纪律（`rule`/`OF`/`THEN` 零搜索），并附
上命题 2.1(2) 的闭包影子 `chain_predense`：

```isabelle
theory Proper
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 107 章：主条件证书的集论核（确定性规则链，沿 103-106 章纪律）。
本体（命题 2.1、引理 2.22-2.24、定理 2.13/2.14）留在正文。\<close>

text \<open>相容：两条件有公共延展（以延展集给出的偏序数据）。\<close>

definition CompatP :: "[i, i] \<Rightarrow> o" where
  "CompatP(r, p) \<equiv> r \<inter> p \<noteq> 0"

text \<open>A 在 q 之下准稠密：一切 r 延展 q 与 A 中某元素相容。\<close>

definition PredenseBelowP :: "[i, i] \<Rightarrow> o" where
  "PredenseBelowP(A, q) \<equiv> \<forall>r\<in>q. \<exists>p\<in>A. CompatP(r, p)"

text \<open>(M,P)-泛型条件证书（定义 2.21 的集论核）。\<close>

definition GenericCondP :: "[i, i] \<Rightarrow> o" where
  "GenericCondP(AA, q) \<equiv> \<forall>A\<in>AA. PredenseBelowP(A, q)"

lemma predenseI:
  assumes h: "\<And>r. r \<in> q \<Longrightarrow> \<exists>p\<in>A. CompatP(r, p)"
  shows "PredenseBelowP(A, q)"
  unfolding PredenseBelowP_def
proof (rule ballI)
  fix r
  assume hr: "r \<in> q"
  from h [OF hr] show "\<exists>p\<in>A. CompatP(r, p)" .
qed

lemma genericI:
  assumes h: "\<And>A. A \<in> AA \<Longrightarrow> PredenseBelowP(A, q)"
  shows "GenericCondP(AA, q)"
  unfolding GenericCondP_def
proof (rule ballI)
  fix A
  assume hA: "A \<in> AA"
  from h [OF hA] show "PredenseBelowP(A, q)" .
qed

text \<open>更强的条件保持证书：q' 延展 q（延展集含于）⟹ 证书下放
（Task 22 Step 2：条件复合保持证书）。\<close>

lemma generic_strengthen:
  assumes hsub: "q' \<subseteq> q"
    and h: "GenericCondP(AA, q)"
  shows "GenericCondP(AA, q')"
proof (rule genericI)
  fix A
  assume hA: "A \<in> AA"
  from h hA have hP: "PredenseBelowP(A, q)" unfolding GenericCondP_def by (rule bspec)
  show "PredenseBelowP(A, q')"
  proof (rule predenseI)
    fix r
    assume hr: "r \<in> q'"
    from hsub hr have hrq: "r \<in> q" by (rule subsetD)
    from hP [unfolded PredenseBelowP_def] hrq show "\<exists>p\<in>A. CompatP(r, p)"
      by (rule bspec)
  qed
qed

text \<open>链样本（确定性链）：q 的每个延展都含 p（链）
\<Longrightarrow> {p} 在 q 之下准稠密。\<close>

lemma chain_predense:
  assumes hchain: "\<forall>r\<in>q. p \<subseteq> r" and hp0: "p \<noteq> 0"
  shows "PredenseBelowP({p}, q)"
proof (rule predenseI)
  fix r
  assume hr: "r \<in> q"
  from hchain hr have hpr: "p \<subseteq> r" by (rule bspec)
  show "\<exists>p'\<in>{p}. CompatP(r, p')"
  proof (rule bexI [where x = p])
    show "CompatP(r, p)" unfolding CompatP_def
    proof (rule notI)
      assume hempty: "r \<inter> p = 0"
      have hsub1: "p \<subseteq> r \<inter> p"
        by (rule Int_greatest [OF hpr subset_refl])
      from hempty hsub1 have hsub2: "p \<subseteq> 0" by (rule subst)
      then have "p = 0" by (rule subset_empty_iff [THEN iffD1])
      from hp0 this show False by (rule notE)
    qed
  next
    show "p \<in> {p}" by (rule singletonI)
  qed
qed

end
```

`chain_predense` 的假设是「$q$ 的每个延展都包含 $p$ 」
——一条以 $p$ 为底部的链——结论是 $\{p\}$ 在 $q$
之下准稠密。证明是命题 2.1(2) 的浓缩：若 $r$ 与 $p$
不相容（$r\cap p=0$ ），则 $p\subseteq r\cap p=0$ 与
$p\neq 0$ 矛盾。**链条件自动制造准稠密**——闭包论证的
有限替身。注意 `hsub1` 一行用 `Int_greatest [OF hpr
subset_refl]` 直接合成而不能写成 `from hpr … proof` 块再
内层 `by (rule hpr)`：带链式事实的 `by (rule thm)` 要求
`thm` 有前提可被链式事实消费，前提已被 `OF` 消光的定理
会报「Failed to apply initial proof method」——这是本章
实测踩出的规则链新坑（详见 PLAN H15）。

Julia 版（`examples/julia/107_proper.jl`）是可执行账本：
证书查询、泛型搜索、反链规模穷举三件事——

```julia
# 第 107 章：主条件证书、(M,P)-泛型条件搜索与准稠密核查。
println("==== 107")

# ── 一、样本宇宙：根 0 分叉到终端 1、2（extT 表）──
const EXT = Dict{Int,Set{Int}}(
    0 => Set([0, 1, 2]),
    1 => Set([1]),
    2 => Set([2]),
)

compat(r, p) = !isempty(EXT[r] ∩ EXT[p])
ext_of(q) = get(EXT, q, Set{Int}())

# ── 二、反链与准稠密（定义 2.21 内核）──
is_antichain(A) = all(!compat(p, q) for p in A, q in A if p != q)

# A 在 q 之下准稠密：一切 r ≤ q 与 A 中某元素相容。
predense_below(A, q) = all(any(compat(r, p) for p in A) for r in ext_of(q))

# (M,P)-泛型条件证书。
generic_cond(As, q) = all(predense_below(A, q) for A in As)

# ── 三、正反样本 ──
A12 = Set([1, 2])
@assert is_antichain(A12)                    # 终端 1、2 不相容
@assert !is_antichain(Set([0, 1]))           # 0 与 1 相容
@assert predense_below(A12, 0)               # 根下准稠密
@assert predense_below(A12, 1)               # 终端下也准稠密
@assert !predense_below(Set([2]), 1)         # 单点 {2} 在 1 下不稠（2∉ext 1 且不相容）
@assert generic_cond([A12], 0)
@assert generic_cond([A12], 1)
@assert generic_cond([A12], 2)
@assert !generic_cond([Set([2])], 1)

# ── 四、泛型条件搜索（Task 22 Step 2：Julia/Python 独立搜索）──
function search_generic(As, universe)
    return sort(collect(q for q in universe if generic_cond(As, q)))
end

@assert search_generic([A12], 0:2) == [0, 1, 2]
@assert search_generic([A12], 0:5) == [0, 1, 2, 3, 4, 5]  # 空 extT 下平凡泛型
@assert search_generic([Set([1])], 0:2) == [1]        # 单点反链 {1} 下仅 1 泛型
@assert search_generic([Set([1]), A12], 0:2) == [1]   # 合取收紧到 1

# 更强条件保持证书（数值核查：q 强于 p ⟹ extT q ⊆ extT p）。
stronger(q, p) = ext_of(q) ⊆ ext_of(p)
@assert stronger(1, 0) && stronger(2, 0)
@assert !stronger(0, 1)
# 证书下放核查：p 泛型 ∧ q 强于 p ⟹ q 泛型。
for p in 0:2, q in 0:2
    if generic_cond([A12], p) && stronger(q, p)
        @assert generic_cond([A12], q)
    end
end

# ── 五、cc 与闭包的样本对照（命题 2.1 的影子）──
# cc 力迫保荟萃（链宇宙）；闭合力迫保荟萃（有下界）。
# 有限影子：cc ⟺ 无 3-反链（本宇宙反链至多 2 元）；闭包 ⟺ 每 2-链有下界。
function max_antichain_size(universe)
    us = collect(universe)
    best = 0
    for mask in 0:(2^length(us) - 1)
        A = Set(us[i] for i in 1:length(us) if (mask >> (i - 1)) & 1 == 1)
        if is_antichain(A)
            best = max(best, length(A))
        end
    end
    return best
end
@assert max_antichain_size(0:2) == 2
# 闭包：{1,1} 型 2-链有下界 1。
@assert 1 ∈ ext_of(1)   # 自反

println("Julia：主条件证书 4+2 正反；泛型搜索三例；更强条件保持证书全核查；")
println("极大反链规模 2（cc 影子）")
println("END ====")
```

三个搜索结果各有教益：`[A12]` 下 0..2 全泛型（反链足够
「宽」——每个 $r$ 都与 1 或 2 相容）；把宇宙扩到 0:5
后 3..5 也泛型——它们的延展集为空，量词空真，这是
**平凡泛型**（有限替身：闭包取到底部的条件）；单点反链
$\{1\}$ 下只有 1 泛型——准稠密要求 $\mathrm{ext}(0)= \{0,1,2\}$ 里的每个 $r$ 与 1 相容，而 2 与 1 不相容。
`max_antichain_size == 2` 是 cc 影子：这个宇宙里**没有
3-元反链**。

Python 版（`examples/python/107_proper.py`）与 Julia 独立
对拍（frozenset 实现、断言同套账）：

```python
# 第 107 章：与 Julia 独立对拍——主条件证书、泛型搜索与反链规模。
import io
import sys
from itertools import combinations, product  # noqa: F401

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

EXT = {0: frozenset({0, 1, 2}), 1: frozenset({1}), 2: frozenset({2})}


def compat(r, p):
    return bool(EXT.get(r, frozenset()) & EXT.get(p, frozenset()))


def ext_of(q):
    return EXT.get(q, frozenset())


def is_antichain(A):
    return all(not compat(p, q) for p, q in combinations(sorted(A), 2))


def predense_below(A, q):
    return all(any(compat(r, p) for p in A) for r in ext_of(q))


def generic_cond(As, q):
    return all(predense_below(A, q) for A in As)


def search_generic(As, universe):
    return [q for q in universe if generic_cond(As, q)]


def max_antichain_size(universe):
    us = sorted(universe)
    best = 0
    for mask in range(2 ** len(us)):
        A = frozenset(us[i] for i in range(len(us)) if (mask >> i) & 1)
        if is_antichain(A):
            best = max(best, len(A))
    return best


def main():
    print("==== 107")
    A12 = frozenset({1, 2})
    assert is_antichain(A12)
    assert not is_antichain(frozenset({0, 1}))
    assert predense_below(A12, 0)
    assert predense_below(A12, 1)
    assert not predense_below(frozenset({2}), 1)
    assert generic_cond([A12], 0) and generic_cond([A12], 1) and generic_cond([A12], 2)
    assert not generic_cond([frozenset({2})], 1)

    assert search_generic([A12], range(3)) == [0, 1, 2]
    assert search_generic([A12], range(6)) == [0, 1, 2, 3, 4, 5]
    assert search_generic([frozenset({1})], range(3)) == [1]
    assert search_generic([frozenset({1}), A12], range(3)) == [1]

    # 更强条件保持证书。
    def stronger(q, p):
        return ext_of(q) <= ext_of(p)

    assert stronger(1, 0) and stronger(2, 0)
    assert not stronger(0, 1)
    for p, q in product(range(3), repeat=2):
        if generic_cond([A12], p) and stronger(q, p):
            assert generic_cond([A12], q)

    assert max_antichain_size(range(3)) == 2
    assert 1 in ext_of(1)

    print("Python：证书正反、泛型搜索三例、证书下放全核查、")
    print("极大反链规模 2——与 Julia 独立对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
```

对拍的独立性体现在数据结构（frozenset vs Set）、穷举方式
（itertools.combinations vs 双层生成器）都不同，账目
（反链规模 2、搜索结果三例、下放全核查）完全一致。

Prolog 版（`examples/prolog/107_proper.pl`）把证书做成
可查询的谓词族；`ext_of` 的前三条子句带截断 `!`——没有
截断的话 catch-all 空表子句会让 `predense_below` 在空
延展上空真成假绿（104 章之后的老坑，这里主动设防）：

```prolog
:- encoding(utf8).
% 第 107 章：(M,P)-泛型条件查询——反链、准稠密与相容性检查。

% 样本宇宙：extT 表（根 0 分叉到终端 1、2；3+ 空延展）。
ext_of(0, [0,1,2]) :- !.
ext_of(1, [1]) :- !.
ext_of(2, [2]) :- !.
ext_of(_, []).

% 相容：有公共延展。
compat(R, P) :- ext_of(R, ER), ext_of(P, EP), member(S, ER), member(S, EP).

% 反链：两两不相容。
is_antichain(A) :- forall((member(P,A), member(Q,A), P \= Q), \+ compat(P, Q)).

% A 在 q 之下准稠密。
predense_below(A, Q) :-
    ext_of(Q, EQ),
    forall(member(R, EQ), (member(P, A), compat(R, P))).

% (M,P)-泛型条件证书。
generic_cond(As, Q) :- forall(member(A, As), predense_below(A, Q)).

% 更强条件：q 的延展含于 p 的延展（q 强于 p）。
stronger(Q, P) :- ext_of(Q, EQ), ext_of(P, EP), subsetL(EQ, EP).

subsetL([], _).
subsetL([H|T], L) :- member(H, L), subsetL(T, L).

% 泛型搜索。
search_generic(As, Max, Qs) :-
    findall(Q, (between(0, Max, Q), generic_cond(As, Q)), Qs).

main :-
    format("==== 107~n"),
    % 反链正反。
    is_antichain([1,2]),
    \+ is_antichain([0,1]),
    % 准稠密正反。
    predense_below([1,2], 0),
    predense_below([1,2], 1),
    predense_below([1,2], 2),
    \+ predense_below([2], 1),
    \+ predense_below([1], 2),
    % 泛型条件正反。
    generic_cond([[1,2]], 0),
    generic_cond([[1,2]], 1),
    \+ generic_cond([[2]], 1),
    % 泛型搜索。
    search_generic([[1,2]], 2, [0,1,2]),
    search_generic([[1]], 2, [1]),
    search_generic([[1],[1,2]], 2, [1]),
    % 更强条件与证书下放。
    stronger(1, 0), stronger(2, 0),
    \+ stronger(0, 1),
    forall((between(0,2,P), between(0,2,Q),
            generic_cond([[1,2]], P), stronger(Q, P)),
           generic_cond([[1,2]], Q)),
    % 相容性样本（泛型性与相容性双查）。
    compat(0, 1), compat(0, 2), compat(1, 1), compat(2, 2),
    \+ compat(1, 2), \+ compat(2, 1),
    format("反链/准稠密/泛型正反；搜索三例；更强条件保持；相容六样本~n"),
    writeln("END ====").
```

七份源码的**定义层逐字对齐**（`Compat`/`Antichain`/
`PredenseBelow`/`GenericCond` 四件套）、**定理层同构**
（`generic_strengthen` 在七个证明助理里是同一棵证明树：
延展集包含 ⟹ 量词单向传递），样本宇宙 `extT` 三点分叉
全域共享——这是「一个数学件、七个文化照一次相」的章级
惯例。

## 107.10 机器的边界

七通道覆盖与不覆盖的清单：

**覆盖**（证书层，全部有限可判定）：

- 四件套定义的**可满足性正反样本**（反链/非反链、准稠密/
  不稠、泛型/不泛型）；
- 证书下放（`generic_strengthen`）的**定理件**（Lean/Coq/
  Agda/Isabelle 四份机器证明 + Julia/Python/Prolog 全域
  穷举核查）；
- 泛型条件搜索（平凡泛型、单点反链收紧、合取收紧三形态）；
- 极大反链规模（cc 影子：本宇宙无 3-反链）；
- 链样本（Isabelle：链上自动准稠密——命题 2.1(2) 闭包
  论证的有限替身）。

**不覆盖**（本体，超穷层）：

- 命题 2.1/引理 2.22 的**超穷递归**（长度 κ 的递减链、
  极大冲突子集的 sup 装箱）——有限宇宙里没有 κ；
- 定义 2.20 的**全程量词**（对一切 $[\kappa]^\omega$ 荟萃
  集）——机器只查固定反链族的证书；
- 引理 2.24 的**名字演算**（$q\Vdash\dot\alpha\in\tilde M$
  的力迫语义）——机器没有力迫语言；
- 定理 2.13 的 **club 论证**与提升降落（I.2.35）——同态
  子模型的荟萃层结构不在有限宇宙里；
- 定理 2.15 的**超穷迭代**（可数支撑在极限步的会合）。

特别说明：Julia/Python 里「空延展集 ⟹ 平凡泛型」是有限
宇宙的边缘效应，**不是**正文任何定理的对应物——恰当力迫
宇宙的底部条件（最大条件 1）延展集是全域而非空集；机器
把它列为搜索结果的一条账目，正文不为此立命题。

## 107.11 本章要点与检查问题

**要点**：

1. 荟萃性是二阶性质，对力迫扩张**不**绝对；club 性是
   $\Pi_1$ 的，自动绝对（107.1）。
2. 命题 2.1：κ-链条件把新 club **压**回旧骨架；<κ-闭包
   让旧荟萃集在极限点**钻**进新 club（107.2）。
3. 引理 2.22 把两条充分类整体搬到 $[\kappa]^\omega$
   （107.3）；定义 2.20 立「保一切可数范围荟萃」为恰当性
   （107.4）；ccc 与 σ-闭是两个直接充分类。
4. 引理 2.23 可数覆盖：恰当力迫下每个新可数序数集装在
   旧可数集里——$\omega_1$ 不被可数化（107.4）。
5. 定义 2.21 $(M,\mathbb P)$ -泛型条件把恰当性翻译成局部
   证书：$M$ -内极大反链截断后仍在 $q$ 下方准稠密
   （107.5）；引理 2.24 给出名字形态与滤子形态两个等价
   刻画。
6. 定理 2.13/2.14：恰当 ⟺ 泛型条件在 club 上/处处存在
   ——PFA 的直接工作形态（107.6）。
7. 引理 2.25/2.26 + 定理 2.15：恰当性对两步合成与可数
   支撑迭代封闭——下一章 PFA 的引擎（107.7）。

**检查问题**：

1. 为什么「club 性是 $\Pi_1$ 」蕴涵它对力迫扩张绝对，
   而「荟萃性」没有这道保险？
2. 命题 2.1(1) 的证明里，κ-链条件在哪一步被用到？换成
   σ-闭条件还能这么证吗？
3. 写出 $[\kappa]^\omega$ 上由 $f:[\kappa]^{<\omega}\to [\kappa]^\omega$ 生成的 club $C_f$ 的定义，并验证
   每个 club 包含某个 $C_f$ 。
4. $(M,\mathbb P)$ -泛型条件定义里，「$A\in M$ 」和
   「$A\cap M$ 只在 $q$ 之下准稠密」两个限定各挡住
   什么反例？
5. 用引理 2.24(2) 的名字形态直接说明：恰当力迫不添加
   「逃逸」$M$ 的可数序数序列。
6. 定理 2.14 与定理 2.13 的差别为什么在应用上至关重要
   （提示：PFA 的稠密集大小是 $\aleph_1$ ）？
7. 机器通道里 `generic_strengthen` 的假设是
   $\mathrm{ext}\,q'\subseteq\mathrm{ext}\,q$ 。它与正文
   「$q'$ 强于 $q$ 」的对应关系是什么？为什么下放方向
   只有一边成立？

---

- 上一章：[106 · 力迫 SCH 最小反例](106-schcounter.md)
- 下一章：[108 · 恰当迭代与 PFA](108-pfa.md)
