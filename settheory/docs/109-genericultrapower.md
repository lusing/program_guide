# 109 · 非荟萃理想与泛型超幂

> 第 108 章铸成 PFA，本章翻开第三卷第二章的最后一段主线：**围绕
> 问题 1.2.3 否定答案的合理性探索**（书 p210）——它曾是实数正则性
> 研究的一大转折点。§2.7 的目标有二：用大基数上的力迫构造证实
> $\omega_1$ 上**非荟萃集理想 $\mathrm{NS}_{\omega_1}$ 的饱和
> 性**是合理的；为后面的荟萃塔力迫铺垫。起点是一个自然的问题：
> 布尔代数 $\mathcal P(\omega_1)/\mathrm{NS}_{\omega_1}$ 能带给
> 我们什么样的泛型扩张？本章取材 §2.7.1（书页 210–219；PDF
> 231–239）：由理想 $I$ 诱导的力迫构思 $\mathbb P(I)=(I^+,\le)$
>（正测集、$C\le D\iff C-D\in I$ ）；泛型滤子 $G$ 在扩张中
> 成为 $\bigcup A$ 上的 **V-超滤子**（四公理 (a)–(d)）；用 G 与
> V 的函数造**泛型超幂** $\Pi(V,E)$ （Solovay 引入）；**定理
> 2.18（Łoś）**；精良与正规（定义 2.23/2.24）；**引理 2.29**
>（$\pi_G([\mathrm{Id}])=i_G''\bigcup A$ ——恒等函数点名临界
> 序列）；**峭壁理想**（定义 2.25，precipitous，Jech–Prikry
> 1976）与分割/泛函（定义 2.26）；**引理 2.30** 三等价刻画；
> 例 2.2（有界理想非峭壁）、例 2.3（$\omega_2$ -饱和 ⟹ 峭壁）、
> **定理 2.19**（饱和理想的三重馈赠）；例 2.4 用泛型超幂重证
> Silver 定理；§2.7.2 的两个可能性定理（Mitchell 的 Lévy 塌塌法）
> 预告下一章。
>
> 机器边界：本体（超滤子不可数性、良基性、大基数构造）全在超穷
> 层；七个通道做**代数层**——样本理想 $I_0=\{\varnothing,\{0\}\}$
> 在 $U=\{0,1,2\}$ 上：①序代数（`Forces` 自反/传递——四助理
> 定理件）；②商关系（$X\equiv Y\iff X\vartriangle Y\in I$ 的
> 自反/传递 + $\mathcal P(U)/I\cong$ **4 元布尔代数**的类账）；
> ③泛型超滤子候选（主滤子 $G(a)$ 的四公理 (a)–(d) 逐条核查 +
> **稠密集全相遇**——有限宇宙里「遇遍一切稠密集」可穷举）；
> ④**有限 Łoś**（Lean 定理件 `los_order`：代表换元不改变
> $[f]<_G[g]$ 的裁决 + Julia/Python 的 27×27×2 全量真值集对拍
> + $[\mathrm{Id}]$ 取值样本）；⑤下降链（严格链至多 2 级——
> 引理 2.30(3)「无严格下降泛函序列」的有限影子）。特别声明
> （Task 24 Step 3）：**普通超幂与泛型超幂的分野不能在有限实验
> 中复现**——普通超幂的滤子是 V 的居民，泛型超幂的滤子先要在
> 扩张 $V[G]$ 中取得（见 109.3b）；机器里的「候选滤子」是
> 主滤子，只是 P(I) 机制的替身，不是任何 $\mathbb P(I)$ -
> 泛型对象的复现。

## 109.1 动机：从布尔代数商到泛型扩张

第七、八章反复使用的手法是：取一个偏序/布尔代数 $\mathbb B$ ，
取泛型滤子，得到扩张 $V[G]$ 。现在把镜头对准一类特殊的布尔
代数——**幂集对理想的商**。设 A 是一个集合（后面多是「集合的
集合」，如 $A=[\kappa]^\omega$ 或 $A=\omega_1$ 的子集族），
$I$ 是 $\bigcup A$ 上的理想；商代数
$\mathcal P(\bigcup A)/I$ 的「正测元」是 $I^+=\{X\subseteq \bigcup A\mid X\notin I\}$ ，序为
$$C\le D\iff C-D\in I.$$

书 p210 的开篇问题因此是：$\mathcal P(\omega_1)/\mathrm{NS} _{\omega_1}$ 的泛型扩张长什么样？其中 $\mathrm{NS}_{\omega_1}$
是 $\omega_1$ 上的**非荟萃集理想**（全体非荟萃子集）——它的
正测集恰是荟萃集。这个商代数的泛型滤子将在扩张中把「荟萃性」
拧成一个超滤子，由此产生的超幂是第 110–113 章整套实数正则性
技术的发动机。

本章先把一般理论立好（§2.7.1 的定义与定理链条），饱和性构造
（§2.7.2 的 Mitchell 定理）留给下一章。书 p210 申明的两个
目标在此可拆读：**其一**（证实 $\mathrm{NS}_{\omega_1}$
饱和性的合理性）是相容性工程——先证明「饱和理想 + ZFC」
不爆炸（Mitchell：可测基数塌塌后 $\omega_1$ 上有峭壁理想；
再迭代消除荟萃性逼近饱和），本书到 110 章兑现；**其二**
（为荟萃塔力迫铺垫）是工具准备——泛型超幂的整套机制
（真值集、嵌入、临界点）将在第 111 章起的实数正则性战场
上火力全开。理论链的骨架：

1. **$\mathbb P(I)$ 的泛型滤子 = 扩张中的 V-超滤子**（四公理）；
2. 用它做**泛型超幂**，Łoś 成立（定理 2.18），于是有同质嵌入
   $i_G:V\to\Pi(V,E)$ ；
3. 良基性与否是分水岭：**峭壁理想**（定义 2.25）保证超幂可
   传递化——引理 2.30 给出组合等价刻画；
4. 饱和（$\omega_2$ -cc 的商）⟹ 峭壁（例 2.3），且送出三重
   馈赠（定理 2.19）：名字可被单函数表示、超幂封闭、
   $\omega_1=\mathrm{crit}(i_G)$ ；
5. 例 2.4 展示战斗力：泛型超幂一遍重证 Silver 定理。

历史坐标放稳再出发（书 p213、p219 的脚注）：泛型超幂由
**Solovay** 在 1971 年引入（Real-valued measurable cardinals，
Proc. Sympos. Pure Math. XIII）——动机正是实值可测与实数
正则性；**峭壁理想**由 **Jech–Prikry** 1976 年命名研究（Bull.
AMS 82）；两个可能性模型（§2.7.2）出自 **Jech–Magidor–
Mitchell–Prikry** 1980（JSL 45）。例 2.4 的泛型超幂证法就是
**Silver 1974**（Vancouver ICM）的原始证明。这条线上每个人名
都对应一处本章用到的技术：Solovay 的构造、Jech–Prikry 的
组合刻画、Mitchell 的塌塌构造、Silver 的账本——第三卷在此把
1970 年代前半叶的一整段前沿压缩成二十页。

## 109.2 理想力迫 P(I) 与泛型超滤子

固定记号（书 p210–211）：理想 $I$ 放在 $\bigcup A$ 上
（当 $A$ 是无穷基数时 $\bigcup A=A$ ，无冲突）；
$\mathbb P(I)=(I^+,\le)$ 严格说是商空间 $I^+/I$ 上的偏序，
但书 p210 注明「混淆两者只有记号简便的收益」。

**泛型超滤子**。设 $G$ 是 $V$ 上的 $\mathbb P(I)$ -泛型
滤子。则在 $V[G]$ 中，$G$ 包含 $I$ 的对偶滤子，而且是
$\bigcup A$ 上的 **V-超滤子**（书 p211 四公理）：

- (a) $\bigcup A\in G$ 且 $\varnothing\notin G$ ；
- (b) $B,C\in G\to B\cap C\in G$ ；
- (c) $B\in G\wedge B\subseteq C\subseteq\bigcup A\to C\in G$ ；
- (d) $B\subseteq\bigcup A\to B\in G\vee(\bigcup A)-B\in G$ 。

四公理里最值得注意的是 (d)：**超**性来自力迫的泛型性——「B
或其余集」的分割在 $\mathbb P(I)$ 中是极大反链，泛型滤子必须
与它相遇。这正是「泛型 ⟹ 超」的机关：有限宇宙里它成为可穷举
的核查（机器件三的 (d) 行）；超穷层面它依赖「每个二分割都是
稠密要求」这一事实。相容性同样是模 I 的：$C\perp D\iff C\cap D\in I$ ，而 $\mathbb P(I)$ 的反链就是商代数里的反链
——**饱和性**（$\mathbb P(I)$ 满足 $\omega_2$ -cc）因此是
关于理想本身的组合性质，110 章的主角。

把 $\mathbb P(I)$ 与已见过的两类力迫并排，能看清它「一半
组合一半理想论」的性格：

| 维度 | Cohen 型 $\mathrm{Fn}$ | 迭代型（108 章） | 理想型 $\mathbb P(I)$ |
|---|---|---|---|
| 条件 | 有限偏函数 | 支撑坐标序列 | 正测集 |
| 序 | 反向包含 | 坐标延展 | 模 I 包含（$C-D\in I$ ） |
| 相容 | 并置 | 坐标逐点相容 | 交为正测 |
| 泛型滤子给出 | 新实数/新子集 | 各步的泛型序列 | **V-超滤子** |
| 结构遗产 | 独立性 | 迭代封闭性 | 超幂 + 嵌入 |

「模 I 包含」这个序是全章计算的枢纽——它是**前序**（自反
传递、但 $X\equiv Y$ 时 $X\le Y\le X$ 双向成立），严格说
偏序活在商 $I^+/I$ 上；机器件一的传递定理与件二的商关系
分别核算这两层（序的传递在前提「理想并闭 + 向下闭」下成立；
商的传递再把双向差拼在一起）。Cohen 力迫的条件问「写了什
么」，理想力迫的条件问「有多大」——条件的信息被压进一个
测度论式的不变量，这正是它能与超滤子/超幂对接的原因。

四公理的清单还藏着一条伏笔：(b) 交封闭说的是「G 中元素两两
相容且交仍正测」——在一般力迫里这只保证相容性，而在理想
力迫里**交本身就是 G 的候选新成员**，于是滤子的代数闭包
在 $\mathbb P(I)$ 内部完成，不必外求；同样，(c) 向上闭包
把一切模 I 包含 $G$ -成员的正测集吸入。换句话说，理想力迫
的泛型滤子不是一个「碰巧相容的条件的塔」，而是**幂集代数
的完整切片**——这正是它在扩张中升格为超滤子的内部原因。
机器件三按 (a)–(d) 逐条核查时，(b)/(c) 两行的实现
（`all((C & D) in G …)`、`all(E in G … if le(C, E))`）因此
不仅是公理的翻译，而是「切片性」的两个侧面。

## 109.3 泛型超幂与 Łoś 定理

**构造**（书 p211）：在 $V[G]$ 中，对 V 中定义在 $\bigcup A$
上的函数 $f,g$ ：

$$f\sim_G g\iff\{\alpha\in\textstyle\bigcup A\mid f(\alpha)=g(\alpha)\}\in G,$$

$[f]_G$ 取等价类中秩最小的代表；
$[f]_G\ E_G\ [g]_G\iff\{\alpha\mid f(\alpha)\in g(\alpha)\}\in G$ 。
泛型超幂
$$\Pi(V,E)=\big([f]_G,\ E_G\big)_{f\in V,\ f:\bigcup A\to V},$$

常值函数给出同质嵌入 $i_G:V\to\Pi(V,E)$ 。

**定理 2.18（Łoś）** 对集合论纯语言的公式
$\varphi(v_1,\dots,v_n)$ ：
$$\Pi(V,E)\models\varphi([f_1],\dots,[f_n])\iff \{\alpha\mid(V,\in)\models\varphi(f_1(\alpha),\dots,f_n(\alpha))\}\in G.$$

从而 $i_G$ 同质（书 p212 证明从略——按原子公式的真值集
定义加上对逻辑连接词与量词的归纳；机器件四核查的正是原子
公式层的**良定义性**：真值集不依赖代表选取）。

Łoś 的归纳结构值得拆开看，因为每一层用到滤子的不同公理：

| 公式形态 | 归纳步 | 用到的滤子性质 |
|---|---|---|
| 原子 $x\in y$ 、$x=y$ 、$x<y$ | 真值集**良定义**（换代表不变） | 交封闭 + 向上闭包 |
| $\neg\psi$ | 补集：$\{\neg\psi\}=\bigcup A-\{\psi\}$ | **超**性 (d) |
| $\psi_1\wedge\psi_2$ | 交：$\{\psi_1\wedge\psi_2\}=\{\psi_1\}\cap\{\psi_2\}$ | 交封闭 (b) |
| $\exists x\,\psi$ | 投影：$\{\exists x\psi(x)\}\supseteq$ 「某代表见证」 | 完全性（$\sigma$ -完全理想） |

第四行是唯一一处需要「理想的完全性」而不只是「滤子」的：
存在量词的选择函数可能在可数多个代表间切换，把真值集写成
可数并后要它仍在 G 中——$\sigma$ -完全理想的场合这才成立。
机器件四只核第一行（原子层），原因见 109.10 的边界清单：
有限主滤子上后三行平凡，而第一行的良定义性机制恰恰是整台
归纳的齿轮。

### 109.3b 普通超幂与泛型超幂的分野

这是本章必须点明的一处概念分水岭（Task 24 Step 3）。
**普通超幂**（第 94、100、101 章反复使用）：超滤子 $U$ 是
$V$ 的居民，超幂 $\mathrm{ult}(V,U)$ 也在 $V$ 中构造、
$V$ 中检验。**泛型超幂**：滤子 $G$ 是
$V^{\mathbb P(I)}$ 的新对象——V 里根本没有这个超滤子
（否则 $\mathbb P(I)$ 就不是非平凡力迫了）；超幂
$\Pi(V,E)$ 的元素是 V 的函数的类，但「按 G 取等价」这个
等价关系只在 $V[G]$ 中可定义，于是超幂整体是扩张的居民，
良基性要在 $V[G]$ 中检验，传递化也在那里进行。一句话：
**普通超幂在 V 内自产自销；泛型超幂要先到扩张中借滤子，再
回头看 V 的影子**。这条分野是峭壁理想定义（「$\Vdash$ 良基」
——力迫语句，本身就是关于扩张的断言）的来源，也是例 2.4 里
「$N$ 未必有秩」要专门处理的根源。

用一张对照表把两边钉死：

| 维度 | 普通超幂 $\mathrm{ult}(V,U)$ | 泛型超幂 $\Pi(V,E)$ |
|---|---|---|
| 滤子来源 | V 中的超滤子 U（大基数） | 扩张 $V[G]$ 中的 G |
| 构造地点 | V 内 | $V[G]$ 内 |
| 良基性 | 由 U 的完全性保证（可测） | **不保证**——峭壁性是额外公理 |
| 临界点 | $\kappa$ （可测基数） | $\omega_1$ （饱和情形，定理 2.19(3)） |
| 典型用途 | 大基数结构、正规精细 | 实数正则性、SCH 反射 |

这张表也是「大基数 ⟹ 小基数理想」整套纲领的缩影：把可测
基数 $\kappa$ 上的超滤子经力迫塌塌/搬运，降到 $\omega_1$
的位置成为理想，再用泛型超幂把大基数的反射机制复用在小基数
上——§2.7.2 的两个可能性定理（Mitchell 与 JMM 迭代）正是
这个纲领的两次落地，110 章见。

## 109.4 精良、正规与恒等函数：引理 2.29

两个性质把 $\bigcup A$ 是「集合的集合」的结构接进超幂（书
p212）：

**定义 2.23（精良）** 滤子 F 精良（fine）⟺
$\forall a\in\bigcup A\ (\{Y\in A\mid a\in Y\}\in F)$ 。
理想精良 ⟺ 对偶滤子精良。

**定义 2.24（正规）** 滤子 F 正规（normal）⟺ 每个 F-正测集
上的选择函数都在某 F-正测子集上常值。理想正规 ⟺ 对偶滤子
正规。

**引理 2.29** 设 $I$ 是 $\sigma$ -完全非平凡精良正规理想，
G 泛型，$\Pi(V,E)$ 有秩。则
$$\pi_G([\mathrm{Id}]_G)=i_G''\bigcup A.$$

**证明骨架**：$\supseteq$ ——对 $a\in\bigcup A$ ，精良性给
$\{Y\mid a\in Y\}\in G$ ，于是 $[c_a]_G\ E_G\ [\mathrm{Id}]_G$ ，
即 $i_G(a)\in\pi_G([\mathrm{Id}])$ 。$\subseteq$ ——设
$[f]_G\ E_G[\mathrm{Id}]_G$ ，即
$E=\{Y\mid f(Y)\in Y\}\in G$ （f 是 G-大集上的选择函数）；
证 $\{B\in I^+\mid\exists\alpha\ B\subseteq\{Y\mid f(Y)=\alpha\}\}$
在 E 下方稠密：对 $D\subseteq E$ 正测，f 在 D 上是选择函数，
**正规性**给 $\alpha$ 使 $\{Y\in D\mid f(Y)=\alpha\}\in I^+$
——于是 $[f]_G=[c_\alpha]_G=i_G(\alpha)$ 。

恒等函数由此成为超幂中「被穷举的 $\bigcup A$ 」的替身：
临界点的计算（定理 2.19(3)）正是让 $[\mathrm{Id}]$ 与
$[c_{\omega_1}]$ 对峙——$[g]:[c_\omega]\twoheadrightarrow [\mathrm{Id}]$ 的满射把 $\omega_1^V$ 在超幂内部变成可数序。
机器件四的 $[\mathrm{Id}]$ 样本（$\{a\mid\mathrm{Id}(a)=1\} =\{1\}\in G(1)$ ）是这条引理在主滤子下的最小影子。

两个性质的实际检验也各有窍门。**精良**几乎免费：非平凡理想
的正测集族本身对「含某点」的过滤就产生主集族型的元素——
饱和理想天然精良。**正规**则是组合内容：对对角交的封闭性
（等价表述），或如定义 2.24 的选择函数版——「压平选择函数」
的能力。荟萃集理想 $\mathrm{NS}_\kappa$ 的正规性来自
club 集对对角交封闭（第一卷 II 的标准账），这也是例 2.4
选它做主角的深层原因：正规性在步 4（b 的上界断言）里是
不可替换的弹药。

## 109.5 峭壁理想：定义 2.25/2.26 与引理 2.30

**定义 2.25（峭壁，precipitous；Jech–Prikry 1976）**
理想 $I$ 峭壁 ⟺
$$\bigcup A\Vdash_{\mathbb P(I)}\ \Pi(V,E)\ \text{有秩}.$$

（书 p213 的译名脚注即 precipitous——「峭壁」取「越坠越深而
不回弹」的意象：良基即无 $\in$ -下降链。）

**定义 2.26（分割与泛函）** 设 $X\in I^+$ ：

1. $W$ 是 X 的 **I-分割** ⟺ W 是 $X$ 的 I-正测子集的极大
   几乎无交族——即商代数中 $[X]$ 下极大反链的代表元集；
2. $W_1$ 是 $W_2$ 的**细分**（$W_1\preceq W_2$ ）⟺ 每个
   $B\in W_1$ 含于某 $C\in W_2$ ；
3. **泛函** F：序数函数的集合，定义域族 $W(F)$ 是分割、两两
   定义域不同；
4. $F_1<F_2$ ⟺ $W(F_1)\preceq W(F_2)$ 且定义域相含处
   逐点 $f(\alpha)<g(\alpha)$ 。

书 p214 解释了这些名词的来源：**泛函就是布尔值模型里名字的
组合表示**——名字 $\dot X$ （「序数函数」的名字）对应分割 W
与每片 $B\in W$ 上的函数 $f_B$ ，见证 $B\Vdash\dot X=f_B$ ；
名字间的 < 关系翻译成泛函的 <。于是：

**(1)⟺(3) 的骨架**：下降泛函序列 ⟺ 下降的名字链 ⟺ 超幂中的
$\in$ -下降链（$[f_{n+1}]_G\ E_G\ [f_n]_G$ 对一切 G 成立）。
**(2)→(3)**：若有 (3) 的反例，其定义域分割序列违反 (2)——
任何中心化选取 $\cap X_n=\varnothing$ ，否则交点 α 给出
$\forall n(f_{n+1}(\alpha)<f_n(\alpha))$ ，nat 上下坠矛盾。
**(3)→(2)**：若 (2) 反例，把分割树
$T=\bigcup W_n$ 按包含关系往上长成树；每棵 $T_\alpha$
（α 处的祖先链）无无穷枝 ⟹ **有秩**；取赋秩函数
$\rho_\alpha$ ，令 $f_B(\alpha)=\rho_\alpha(B)$ ——包含
降一级秩降一层，得下降泛函序列。

把「名字–泛函–下降链」的词典列成表（书 p214 的翻译关系的
总结），它是引理 2.30 三个命题各自的地基：

| 布尔值层 | 组合层（泛函） | 超幂层 |
|---|---|---|
| 名字 $\dot X$ （序数函数的名字） | 泛函 F（分割 W + 各片函数 $f_B$ ） | 类 $[f]_G$ |
| $B\Vdash\dot X=f_B$ | $B=\mathrm{dom}(f_B)\in W(F)$ | 真值集含 B |
| $\dot X<\dot Y$ （名字序） | $F_1<F_2$ （细分 + 逐点 <） | $[f_1]_G E_G [f_2]_G$ |
| 无穷下降名字链 | 无穷下降泛函序列 | $\in$ -下降链（非良基） |

三列在引理 2.30 里被「(1) ⟺ (3)」一次接通：良基性（右列的
否定）等价于组合层无下降。这个词典也解释了定义 2.26 的措辞
为何「似乎有些人为」（书 p214 自注）——它不是为组合而组合，
而是**把布尔值模型的名字结构搬运到纯集合论语言**的桥板；
一旦词典在手，峭壁性的组合刻画（无下降泛函）与力迫刻画
（超幂良基）就是同一句话的两种拼法。

1. I 峭壁；
2. 对任意 $X\in I^+$ 与 X 上满足 $\bigcup W_n$ 覆盖性质
   （$\bigcup W_{n+1}$ 模 I 覆盖 $\bigcup W_n$ 的每个成员）
   的可数分割序列 $\langle W_n\rangle$ ，存在中心化选取序列
   $\langle X_n\rangle$ （$X_{n+1}\subseteq X_n$ 、
   $X_n\in W_n$ ）且 $\bigcap X_n\neq\varnothing$ ；
3. 不存在 $X\in I^+$ 与泛函序列 $\langle F_n\rangle$ 使
   $\forall n(F_{n+1}<F_n)$ ——**无严格下降泛函序列**。

下降链无——这正是「良基」的组合替身。机器件五在有限宇宙核查
其**集合版**：$(I^+,\le)$ 中严格链至多 2 级（商代数只有
$1>$ 原子 两层）。注意集合链与泛函链是两个层面：泛函的下降
逐点发生在序数上，其有限影子是「序数值函数在有限域上无严格
下降」（nat 上自动成立）；集合链的影子捕捉的是商代数的层级
结构。两者在正文里由引理 2.30 打通（树的赋秩），机器各取其
可穷举的一侧。

## 109.6 例 2.2/2.3 与定理 2.19：饱和的三重馈赠

**例 2.2（有界理想不峭壁）** $I=\mathcal P_{\omega_1}(\omega_1)$
（有界子集理想）：对 $X\in I^+$ 取传递化（坍塌）映射
$f_X:X\to\omega_1$ ，则 $B(X)=\{\alpha\mid f_{B(X)}(\alpha) <f_X(\alpha)\}$ 仍正测——每个 X 的分割里都有「严格更小」的
成员；迭代造出 $F_n>F_{n+1}$ 的无穷下降。**坍塌函数自己
就是下降泛函**——不峭壁。

这个反例的直觉值得多停一拍：有界理想把「几乎所有」（模 I）
理解为「余有界」，而坍塌映射在每个无界集上都能找到「把
序数压矮」的层——每压一层就是一个更小的泛函。峭壁性要求
的恰是**无处理降层的机制**：正测集族里没有系统性的「更矮
代表」。例 2.3 将从反方向给出保障机制：饱和性禁止分割长出
太细的层叠。一反一正夹出峭壁性的位置——它介于「理想的
正测集足够粗」（有界理想太细：每个正测集都能切出更细的
正测层）与「分割的极大反链不够长」（饱和：反链 $\le\omega_1$ ）
之间。

**例 2.3（$\omega_2$ -饱和 ⟹ 峭壁）** 设 I 是 $\omega_1$
上 $\sigma$ -完全、含单点、$\omega_2$ -饱和的理想。对分割
序列做**不交化改造**（书 p216–217）：利用饱和性把每个分割
$\{B_\alpha\}$ 换成几乎不交的 $\{A_\alpha\}$ ，且
$\bigcup A_\alpha$ 模 I 覆盖；$\sigma$ -完全性保证
$\bigcap_n D_n\neq\varnothing$ （$D_n=\bigcup W_n$ 的不交
化并）；取 $\alpha\in\bigcap D_n$ ，逐层取出含 α 的成员
$X_n\in W_n$ 得中心化选取、交非空——引理 2.30(2) 成立。
**饱和 ⟹ 每层分割可数化成不交骨架 ⟹ 交点存活**。

**定理 2.19（饱和理想的三重馈赠）** 设 I 是 $\omega_1$ 上
非平凡 $\sigma$ -完全正规饱和理想：

1. （名字表示）每个 $\dot\tau$ （$\omega_1$ 上函数的名字）
   被单个 $f:\omega_1\to V$ 表示：
   $1\Vdash\exists A\in G\ \forall\alpha\in A(\dot\tau(\alpha) =f(\alpha))$ ——饱和给极大反链 $\{S_\alpha\}$ ，不交化后
   拼一个 f；
2. （封闭性）G 泛型 ⟹ $\Pi(V,E)$ 有秩，且 $V[G]$ 中每个
   $f:\omega_1\to\mathrm{ult}(V,G)$ 都在 M 中——名字表示 +
   嵌套函数编码 $\langle f_\beta\mid\beta<\alpha\rangle\mapsto f(\alpha)$ ；
3. （临界点）$\omega_1^V=\mathrm{crit}(i_G)$ ，且在
   $\mathrm{ult}(V,G)$ 中 $\omega_1^V$ 可数：
   $[g]:[c_\omega]\twoheadrightarrow[\mathrm{Id}]$ 是满射
   （$g(\alpha)=f_\alpha$ ：$\omega\twoheadrightarrow\alpha$
   的枚举表），$\pi_G([\mathrm{Id}])=i_G''\omega_1^V=\omega_1^V$
   在超幂内部可数，故 $i_G(\omega_1^V)>\omega_1^V$ 。
   饱和 ⟹ $\mathbb P(I)$ 满足 $\omega_2$ -cc ⟹ $\ge\omega_2$
   的基数保持。

三重馈赠各自解决了泛型超幂的一处「先天不便」，值得逐款
咀嚼：

- **款 1 解决「名字太多」**。一般情况下 $\omega_1$ -函数的
  名字有 $2^{\omega_1}$ 种自由度，操作起来笨重；饱和性把
  极大反链压到 $\omega_1$ 长、不交化成几乎划分，于是**一张
  表** f 就能代表任何名字——这是后续一切「函数式操作」的
  前提（例 2.4 的截痕函数全部受益）。
- **款 2 解决「超幂太瘦」**。普通超幂 $\mathrm{ult}(V,U)$
  对 $\omega$ -序列封闭是可测性的标准礼包；泛型超幂一般
  **不**封闭（它只是扩张中的一个类）。饱和性把 $V[G]$ 的
  每个 $\omega_1$ -序列装回 M——「泛型超幂接近内模型」的
  感觉由此而来，也是实数正则性章节里「M 含足够多实数」的
  技术源头。
- **款 3 解决「临界点在哪」**。引理 2.29 说
  $\pi_G([\mathrm{Id}])=i_G''\omega_1^V$ ；款 3 的满射论证
  再补一刀：这个像在超幂内部**可数**（枚举表 $g(\alpha)= f_\alpha$ 把 $[c_\omega]$ 满射到 $[\mathrm{Id}]$ 上）。
  像可数而原基数不可数 ⟹ $i_G(\omega_1^V)$ 严格更高——
  临界点恰在 $\omega_1$ 。对照 94 章可测基数的
  $\mathrm{crit}(j)=\kappa$ ：饱和理想让**第一个不可数基数**
  拿到了可测基数的入场券。

三重馈赠合起来就是「饱和理想把 $\omega_1$ 变成可测基数的
影子」：扩张里有嵌入、嵌入的临界点是 $\omega_1^V$ 、嵌入还
封住 $\omega_1$ 的像。下一章的饱和性构造（Mitchell）正是
把这个影子从可测基数搬来。

## 109.7 例 2.4：泛型超幂证 Silver 定理

Solovay 引入泛型超幂后，它成为一套标准武器；书 p219 用最小
的弹头展示——Silver 定理（第一卷定理 1.2.38，也是第 106 章
SCH 战役的第一块界碑）：设 κ 是 cf=$\omega_1$ 的奇异基数、
$\forall\lambda<\kappa(2^\lambda=\lambda^+)$ ，则
$2^\kappa=\kappa^+$ 。**且这正是 Silver 本人的原始证明**。

**骨架**（书 p219–220）：取 $I=\mathrm{NS}_{\omega_1}$ 、
$\mathbb P$ =$\omega_1$ 的荟萃子集力迫、G 泛型。$V$ 中
$|\mathbb P|=2^{\omega_1}=\omega_2<\kappa$ ，故 $\ge\omega_3$
……一切 $\ge\omega_2$ 的基数保持。在 $V[G]$ 中 G 是正规的
$\sigma$ -完全 V-超滤子；$N=\Pi(V,E)$ 、同质嵌入
$i:V\to N$ （**未必有秩**——$\mathrm{NS}_{\omega_1}$ 的
峭壁性未定！但论证只用同质性不落传递化）。取递增序列
$\kappa_\alpha\uparrow\kappa$ ，令 $b=[f]$ （$f(\alpha)= \kappa_\alpha$ ）、$b^+=[f^+]$ （$=\kappa_\alpha^+$ ）——
由 Łoś，N 中 b 是基数、$b^+$ 是后继，且
$N\models 2^b=b^+$ 。对每个 $X\subseteq\kappa$ ，截痕函数
$f_X(\alpha)=X\cap\kappa_\alpha$ 的类 $[f_X]\in^N b$ ，
且不同 X 给不同类——$|\mathcal P(\kappa)^V|\le|(2^b)^N|$ 。
再估上界：**断言** $b=\sup\{i(\alpha)\mid\alpha<\omega_1\}$
（正规性：任何 $[h]\in b$ 的代表在 G-大集上被某固定
$\beta<\omega_1$ 压住）；于是
$|\{\xi\mid\xi\in_N i(\alpha)\}|\le(\kappa)^V$ 级别的账目
（$\omega_1$ 层每层 $<\kappa$ ），线性序 $(A,E_G)$ 的
每个真前段 $\le\kappa$ ⟹ $|A|\le\kappa^+$ 。合账：
$(2^\kappa)^V\le(\kappa^+)^{V[G]}=\kappa^+$ 。

这个证明展示了泛型超幂的全部招牌动作：真值集裁决（Łoś）、
截痕函数的注入（$\mathcal P(\kappa)$ 进超幂）、正规性断言
（b 的上界）、基数账的逐层结算。它也点出 N **未传递化**时
如何绕行——线性序 $(A,E_G)$ 直接做组合，不问良基。

把 Silver 证明的账目列表化（对照第 106 章开篇对 Silver
定理的定位——那里它是 SCH 首反例的「共尾度限制」，这里它
是泛型超幂的热身）：

| 步 | 断言 | 依据 |
|---|---|---|
| 1 | G 是 $\omega_1$ 上正规 $\sigma$ -完全 V-超滤子 | 荟萃力迫 + 泛型性 |
| 2 | b=[f]、b⁺=[f⁺] 在 N 中是基数与后继 | Łoś + V 中逐点 $2^{\kappa_\alpha}=\kappa_\alpha^+$ |
| 3 | $X\mapsto[f_X]$ 注入 $\mathcal P(\kappa)^V\to(2^b)^N$ | 截痕函数 + 不同 X 分离 |
| 4 | $b=\sup\{i(\alpha)\mid\alpha<\omega_1\}$ | G 的**正规性**（选择函数压平） |
| 5 | $(A,E_G)$ 每真前段 $\le\kappa$ | 步 4 + 逐层 $<\kappa$ 账（GCH 下方） |
| 6 | $(2^\kappa)^V\le\lvert A\rvert\le\kappa^+=\kappa^{+V[G]}$ | 步 3+5 + $\lvert \mathbb P\rvert=\omega_2<\kappa$ 保基数 |

第 4 步是全证明的枢纽：没有正规性，b 的上界无从谈起，
第 5 步的「每层 $<\kappa$ 」就会失去分层结构——这解释了
为什么荟萃力迫（而非任意 $\mathbb P(\omega_1)$ ）被选为主
角：**荟萃集恰是正规滤子的正测集**，$\mathrm{NS}_{\omega_1}$
的对偶天然正规。第 3 步的截痕注入则是泛型超幂方法论的标准
一击：把 V 的幂集「编码」进超幂的小基数幂集，再在扩张的
基数账上夹逼。

**§2.7.2 预告（下一章入口）**：两个可能性定理——
**定理 2.20（Mitchell）**：κ 可测，取 Lévy 塌塌
$\mathrm{Col}(\omega,<\kappa)$ ，则扩张中 $\omega_1$ 上存在
$\sigma$ -完全非平凡正规**峭壁**理想（可测超滤子的对偶理想
在塌塌后的残余，由 κ-cc 与超滤子的完全性逐条验证非平凡/
$\sigma$ -完全/正规）；第二个模型在其上用可数支撑迭代消除
一切荟萃集的荟萃性（Jech–Magidor–Mitchell–Prikry 1980）。
峭壁先行、饱和随后——110 章把 $\mathrm{NS}_{\omega_1}$
的饱和性本身造出来。

Mitchell 构造的直觉可以先用一句话预支：可测基数 κ 上的
正规超滤子 U 是「最强的收敛装置」；Lévy 塌塌把 κ 以下的
基数全部打乱重排成 $\omega_1$ 段，U 对 κ-cc 力迫的残余
（$X\subseteq\kappa$ 属于理想 ⟺ 某个 U-大集与 X 无交）
继承 $\sigma$ -完全与正规，而**峭壁性**由「超幂对塌塌的
交换」保证——塌塌后 U 的泛型超幂同构于先取超幂再塌塌，
后者良基（可测超滤子的普通超幂良基），故前者良基。这个
「先塌后拧还是先拧后塌」的交换图是下一章的核心机器，也是
「大基数 ⟹ 小理想」纲领最干净的一次执行。

## 109.8 与前章的对照总表

| 维度 | 108 迭代与 PFA | 109 泛型超幂 |
|---|---|---|
| 偏序来源 | 拉弗调度的可数支撑迭代 | 幂集对理想的商 $\mathcal P(\bigcup A)/I$ |
| 泛型对象 | 融合滤子（PFA 的见证） | V-超滤子（四公理） |
| 核心定理 | 2.15 迭代保持 | 2.18 Łoś + 2.30 三等价 |
| 分水岭性质 | 恰当（保荟萃） | 峭壁（超幂良基） |
| 大基数接口 | 超紧 + 拉弗 | 可测 + Lévy 塌塌（预告） |
| 机器影子 | 支撑账 + RS 构造 | 序/商代数 + 主滤子 + 真值集 |

两章合读还能看到一个漂亮的对称：108 章用「$\aleph_1$ 个稠密集
相遇」造公理模型，109 章研究「一个稠密集族被相遇后剩什么」——
理想商的泛型学。荟萃塔力迫（第 111 章起）把两者拧在一起。

更细地看，「泛型」一词在两章里的含义也有微差：PFA 的融合
滤子只须遇遍**给定的** $\aleph_1$ 个稠密集（一个偏序一册
清单）；$\mathbb P(I)$ -泛型滤子须遇遍**一切**稠密集（全域
泛型），后者因此获得超性 (d) 与 $\sigma$ -完全性这些「免费
礼包」，代价是滤子只能活在扩张里。108 章的机器把「清单」
做成 32×32 穷举，本章的机器把「全域」做成 64 个子集全查——
同一个词的两种量词强度，在有限宇宙里都退化为「全部核查」，
但正文里它们的形而上身份完全不同。

## 109.9 机器通道

七个通道共享**位掩码宇宙**：$U=\{0,1,2\}$ （bit i = 元素 i），
理想 $I_0=\{\varnothing,\{0\}\}$ （掩码 {0,1}），正测集
$I^+=\{\{1\},\{2\},\{0,1\},\{0,2\},\{1,2\},U\}$ （6 个）。
位掩码的选择不是图省事：差集 $C-D$ 变成 `C & ~D`、对称差
变成按位异或、主滤子成员变成「位测试」——三件核心运算都
落成一次机器指令，穷举（64 个子集、27 个函数表）因此零负担。
四助理走各自的集合本体（Finset/List/ZF-集合），数值三通道走
整数——「同一份数学、两种表示」再次兑现七通道横评的意义。

五件机器：

1. **序代数**：`Forces`/`le`（C ≤ D ⟺ C−D ∈ I）自反（C−C=∅）
   与传递（C−E ⊆ (C−D)∪(D−E) + 理想并闭向下闭）——四个证明
   助理的定理件；
2. **商关系**：$X\equiv Y\iff X\vartriangle Y\in I$ 自反/传递
   （Coq/Agda/Isabelle），$\mathcal P(U)/I\cong$ 4 元布尔代数
   的类账（$\{0\}\equiv\varnothing$ 归零类；$\{1,2\}\equiv U$
   归单位；$\{1\}$ 、$\{2\}$ 为原子）——Julia/Python；
3. **泛型超滤子候选**：主滤子 $G(a)=\{X\in I^+\mid a\in X\}$
   （a=1、2——单点不在理想中的两点），四公理 (a)–(d) 逐条核查，
   并**穷举一切稠密集** $D\subseteq I^+$ （64 个子集）验证
   「遇遍每个稠密集」——有限宇宙里泛型性是可判定的；
4. **有限 Łoś**：Lean 定理件 `los_order`（滤子证书六公理下，
   代表换元保持 < 裁决：$\{f=f'\}\cap\{g=g'\}\cap\{f<g\} \subseteq\{f'<g'\}$ + 超滤子的向上闭包）；数值通道对
   **27×27 个函数对 × 2 个滤子**全量对拍：
   $\{f<g\}\in G(a)\iff f(a)<g(a)$ （主滤子下真值集裁决
   = 主点取值）；$[\mathrm{Id}]$ 样本：$\{a\mid\mathrm{Id}(a) =1\}=\{1\}\in G(1)$ ——引理 2.29 的影子；
5. **下降链**：$(I^+,\le)$ 严格链 DFS——至多 2 级
   （商代数 $1>$ 原子两层），引理 2.30(3) 的集合层影子。

先看 Lean 版（`examples/lean/Settheory/Ch109Genericultrapower.lean`）。
`FilterCert` 结构体把书 p211 四公理（加「不含 ∅」与「限制在 U
内」）立为证书，`los_order` 是本章旗舰定理：

```lean
import Mathlib.Data.Finset.Basic

/-!
# 第 109 章 · 非荟萃理想与泛型超幂

锚点（有限影子）：
- `Forces`：理想力迫的序——C ≤ D ⟺ C − D ∈ I；
  `forces_refl`/`forces_trans`：自反与传递（理想向下/并闭）；
- `FilterCert` + `los_order`：滤子四公理下的**有限 Łoś**
  （原子公式的良定义性）：代表换元不改变 [f] <_G [g] 的裁决；
- 样本理想 I₀ = {∅, {0}} 与主滤子 G₁：真值集、商关系
  （X ≡ Y ⟺ X△Y ∈ I）与 [Id] 的取值（引理 2.29 的影子）。
本体（定义 2.23–2.26、引理 2.29/2.30、定理 2.18/2.19、
例 2.2–2.4）留在正文。
-/

namespace Settheory.Ch109

open Finset

/-! ## 一、理想力迫的序（正测集代数） -/

/-- 理想力迫 P(I) 的序：C ≤ D ⟺ C − D ∈ I。 -/
abbrev Forces (I : Finset (Finset ℕ)) (C D : Finset ℕ) : Prop :=
  C \ D ∈ I

theorem forces_refl {I : Finset (Finset ℕ)}
    (h0 : ∅ ∈ I) (C : Finset ℕ) : C \ C ∈ I := by
  rw [Finset.sdiff_self]
  exact h0

theorem forces_trans {I : Finset (Finset ℕ)}
    (hdown : ∀ X ∈ I, ∀ Y ⊆ X, Y ∈ I)
    (hun : ∀ X ∈ I, ∀ Y ∈ I, X ∪ Y ∈ I)
    {C D E : Finset ℕ}
    (h1 : C \ D ∈ I) (h2 : D \ E ∈ I) : C \ E ∈ I := by
  apply hdown _ (hun _ h1 _ h2)
  intro x hx
  simp only [Finset.mem_sdiff, Finset.mem_union] at hx ⊢
  obtain ⟨hC, hE⟩ := hx
  by_cases hD : x ∈ D
  · exact Or.inr ⟨hD, hE⟩
  · exact Or.inl ⟨hC, hD⟩

/-! ## 二、滤子四公理与有限 Łoś（原子公式的良定义性） -/

/-- 滤子证书：G 是 U 上的（超）滤子——书 p211 的 (a)–(d)。 -/
structure FilterCert (G : Finset ℕ → Prop) (U : Finset ℕ) : Prop where
  up : ∀ X, G X → X ⊆ U
  top : G U
  inter : ∀ X Y, G X → G Y → G (X ∩ Y)
  mono : ∀ X Y, G X → X ⊆ Y → Y ⊆ U → G Y
  ultra : ∀ X, X ⊆ U → G X ∨ G (U \ X)
  nempty : ¬ G ∅

/-- 有限 Łoś（原子公式的良定义性）：代表换元不改变 < 的裁决——
[f] <_G [g] 由 {a | f a < g a} ∈ G 定义，而等价的代表给同一裁决。 -/
theorem los_order {G : Finset ℕ → Prop} {U : Finset ℕ} (hc : FilterCert G U)
    (f g f' g' : ℕ → ℕ)
    (h1 : G {a ∈ U | f a = f' a})
    (h2 : G {a ∈ U | g a = g' a})
    (h3 : G {a ∈ U | f a < g a}) :
    G {a ∈ U | f' a < g' a} := by
  have hS : G ({a ∈ U | f a = f' a} ∩ {a ∈ U | g a = g' a} ∩ {a ∈ U | f a < g a}) :=
    hc.inter _ _ (hc.inter _ _ h1 h2) h3
  have hsub : ({a ∈ U | f a = f' a} ∩ {a ∈ U | g a = g' a} ∩ {a ∈ U | f a < g a})
      ⊆ {a ∈ U | f' a < g' a} := by
    intro x hx
    simp only [Finset.mem_inter, Finset.mem_filter] at hx ⊢
    obtain ⟨⟨⟨hu, heq1⟩, ⟨_, heq2⟩⟩, ⟨_, hlt⟩⟩ := hx
    refine ⟨hu, ?_⟩
    rw [← heq1, ← heq2]
    exact hlt
  refine hc.mono _ _ hS hsub ?_
  intro x hx
  exact (Finset.mem_filter.mp hx).1

/-! ## 三、样本理想与主滤子（决定性核查） -/

def U₀ : Finset ℕ := {0, 1, 2}

def I₀ : Finset (Finset ℕ) := {{}, {0}}

/-- 主滤子（在 1 处）：泛型超滤子候选。 -/
abbrev G₁ (X : Finset ℕ) : Prop := 1 ∈ X ∧ X ⊆ U₀

theorem filtercert_G₁ : FilterCert G₁ U₀ := by
  constructor
  · intro X hX; exact hX.2
  · show 1 ∈ U₀ ∧ U₀ ⊆ U₀
    exact ⟨by decide, subset_refl _⟩
  · intro X Y hX hY
    show 1 ∈ X ∩ Y ∧ X ∩ Y ⊆ U₀
    refine ⟨?_, subset_trans Finset.inter_subset_left hX.2⟩
    simp only [Finset.mem_inter]
    exact ⟨hX.1, hY.1⟩
  · intro X Y hX hXY hYU
    show 1 ∈ Y ∧ Y ⊆ U₀
    exact ⟨hXY hX.1, hYU⟩
  · intro X hXU
    by_cases h1 : 1 ∈ X
    · exact Or.inl ⟨h1, hXU⟩
    · exact Or.inr ⟨Finset.mem_sdiff.mpr ⟨by decide, h1⟩, Finset.sdiff_subset⟩
  · intro h
    exact absurd h.1 (by decide)

/-- 样本函数（U₀ → ℕ 的表）。 -/
def f₁ : ℕ → ℕ := fun a => if a = 0 then 3 else if a = 1 then 1 else 4
def g₁ : ℕ → ℕ := fun a => if a = 0 then 2 else if a = 1 then 2 else 0

/-- 真值集：{a | f₁ a < g₁ a} = {1}——同一份数据在 G₁ 下裁决为真。 -/
example : {a ∈ U₀ | f₁ a < g₁ a} = {1} := by decide

example : G₁ {a ∈ U₀ | f₁ a < g₁ a} := by decide

/-- 换元样本：f₂ 与 f₁ 只在 G₁-零测点 0 上不同。 -/
def f₂ : ℕ → ℕ := fun a => if a = 0 then 5 else if a = 1 then 1 else 4

/-- 有限 Łoś 的应用：等价代表换元后裁决保持（两边都由 decide 核账）。 -/
example : G₁ {a ∈ U₀ | f₂ a < g₁ a} := by
  have heq : G₁ {a ∈ U₀ | f₁ a = f₂ a} := by decide
  have hid : G₁ {a ∈ U₀ | g₁ a = g₁ a} := by decide
  have hlt : G₁ {a ∈ U₀ | f₁ a < g₁ a} := by decide
  exact los_order filtercert_G₁ f₁ g₁ f₂ g₁ heq hid hlt

/-- 引理 2.29 的影子：主滤子下 [Id] 的取值是那一点。 -/
example : G₁ {a ∈ U₀ | (fun x => x) a = 1} := by decide

/-- 商关系样本：U₀ ≡ {1, 2}（mod I₀），对称差 {0} ∈ I₀。 -/
example : (U₀ \ {1, 2}) ∪ ({1, 2} \ U₀) ∈ I₀ := by decide

/-- 序样本：{1} ≤ {0,1}（差 ∅），U₀ ≰ {0,1}（差 {2} 为正）。 -/
example : Forces I₀ {1} {0, 1} := by decide
example : ¬ Forces I₀ U₀ {0, 1} := by decide

end Settheory.Ch109
```

`los_order` 的证明树是 Łoś 良定义性的最小完整标本：三个真值
集之交（交封闭）在 G 中，该交**含于**目标真值集（逐点核对：
$f=f'$ 、$g=g'$ 、$f<g$ ⟹ $f'<g'$ ），滤子向上闭包完成
收口。注意 `Forces`/`G₁` 用 `abbrev`（可规约定义）——Lean 的
匿名构造器与 Decidable 实例搜索不穿透普通 def 的 delta 展开层
（`by decide` 需要 `Decidable (G₁ …)` 实例），这是本章实测
第一坑。

`filtercert_G₁` 的六个构造子分支各对应一条公理，其中两处
细节值得慢读：交封闭分支里 `Finset.mem_inter` 把 $1\in X\cap Y$
拆成两个成员资格（mathlib 4.33 的该引理分量序以**右侧集合
在前**统一——首版按直觉写序被类型错抓）；超性分支的余集
成员 `Finset.mem_sdiff.mpr ⟨by decide, h1⟩` 把「$1\in U_0$
且 $1\notin X$ 」一步装进 $U_0\setminus X$ 。`los_order` 的
应用样本（`f₂` 与 `f₁` 只在零测点 0 上不同）把定理真正跑通
一遍：三个 decide 供真值集，定理收口裁决——「代表换元不改
裁决」由机器执行而非人工目测。

Coq 版（`examples/coq/Ch109_genericultrapower.v`）自建 `diffL`
并证明成员刻画 `in_diffL`，商关系三定理全上：

```coq
(* 第 109 章：理想力迫的序、商关系与真值集——泛型超幂的有限影子。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

Module Ch109.

(* ── 一、理想力迫的序：C ≤ D ⟺ C − D ∈ I（正测集代数） ── *)

Fixpoint diffL (C D : list nat) : list nat :=
  match C with
  | [] => []
  | a :: C' => if in_dec Nat.eq_dec a D then diffL C' D else a :: diffL C' D
  end.

Lemma in_diffL : forall C D x, In x (diffL C D) <-> In x C /\ ~ In x D.
Proof.
  induction C as [|a C' IH]; intros D x; simpl.
  - split; [intros H; contradiction | intros [HC _]; contradiction].
  - destruct (in_dec Nat.eq_dec a D) as [Hin|Hnin]; simpl.
    + rewrite IH. split.
      * intros [H1 H2]. split; [right; exact H1 | exact H2].
      * intros [H1 H2]. split.
        -- destruct H1 as [Heq|H1].
           ++ subst x. exfalso. apply H2, Hin.
           ++ exact H1.
        -- exact H2.
    + rewrite IH. split.
      * intros [H | [H1 H2]].
        -- split; [left; exact H | subst x; exact Hnin].
        -- split; [right; exact H1 | exact H2].
      * intros [H1 H2]. destruct H1 as [Heq|H1].
        -- left; exact Heq.
        -- right. split; [exact H1 | exact H2].
Qed.

Lemma diffL_id : forall C, diffL C C = [].
Proof.
  intros C.
  assert (hnil : forall x, ~ In x (diffL C C)).
  { intros x Hx. apply in_diffL in Hx. destruct Hx as [H1 H2]. contradiction. }
  destruct (diffL C C) as [|b L] eqn:E.
  - reflexivity.
  - exfalso. apply (hnil b). left. reflexivity.
Qed.

Definition forces (I : list (list nat)) (C D : list nat) : Prop :=
  In (diffL C D) I.

Lemma forces_refl : forall I C,
  In ([] : list nat) I -> forces I C C.
Proof.
  intros I C h0. unfold forces.
  rewrite diffL_id. exact h0.
Qed.

Lemma forces_trans : forall I C D E,
  (forall X Y, In X I -> In Y I -> In (X ++ Y) I) ->
  (forall X Y, In X I -> incl Y X -> In Y I) ->
  forces I C D -> forces I D E -> forces I C E.
Proof.
  intros I C D E hun hdown h1 h2. unfold forces in *.
  apply (hdown (diffL C D ++ diffL D E)).
  - apply hun; assumption.
  - intros x hx. apply in_diffL in hx. destruct hx as [H1 H2].
    apply in_or_app.
    destruct (in_dec Nat.eq_dec x D) as [Hin|Hnin].
    + right. apply in_diffL. split; assumption.
    + left. apply in_diffL. split; assumption.
Qed.

(* ── 二、商关系：X ≡ Y（mod I）⟺ X△Y ∈ I ── *)

Definition eqv (I : list (list nat)) (X Y : list nat) : Prop :=
  In (diffL X Y ++ diffL Y X) I.

Lemma eqv_refl : forall I X, In ([] : list nat) I -> eqv I X X.
Proof.
  intros I X h0. unfold eqv.
  rewrite diffL_id. rewrite app_nil_l. exact h0.
Qed.

Lemma eqv_trans : forall I X Y Z,
  (forall X Y, In X I -> In Y I -> In (X ++ Y) I) ->
  (forall X Y, In X I -> incl Y X -> In Y I) ->
  eqv I X Y -> eqv I Y Z -> eqv I X Z.
Proof.
  intros I X Y Z hun hdown hxy hyz. unfold eqv in *.
  apply (hdown (diffL X Y ++ diffL Y X ++ (diffL Y Z ++ diffL Z Y))).
  - rewrite app_assoc. apply hun; assumption.
  - intros x hx. apply in_app_or in hx. destruct hx as [hx|hx].
    + (* hx : In x (diffL X Z)：x ∈ X ∧ x ∉ Z *)
      apply in_diffL in hx. destruct hx as [H1 H2].
      apply in_or_app.
      destruct (in_dec Nat.eq_dec x Y) as [Hin|Hnin].
      * right. apply in_or_app. right. apply in_or_app. left.
        apply in_diffL. split; assumption.
      * left. apply in_diffL. split; assumption.
    + (* hx : In x (diffL Z X)：x ∈ Z ∧ x ∉ X *)
      apply in_diffL in hx. destruct hx as [H1 H2].
      apply in_or_app. right. apply in_or_app.
      destruct (in_dec Nat.eq_dec x Y) as [Hin|Hnin].
      * left. apply in_diffL. split; assumption.
      * right. apply in_or_app. right. apply in_diffL. split; assumption.
Qed.

(* ── 三、样本理想与真值集（决定性核查） ── *)

Definition U0 : list nat := [0; 1; 2].
Definition I0 : list (list nat) := [[]; [0]].

(* 序样本：{1} ≤ {0,1}（差 ∅），U0 ≰ {0,1}（差 [2] 为正）。 *)
Example forces_sample1 : forces I0 [1] [0; 1].
Proof. vm_compute. auto. Qed.

Example forces_sample2 : ~ forces I0 U0 [0; 1].
Proof.
  unfold forces.
  assert (hd : diffL U0 [0; 1] = [2]) by reflexivity.
  rewrite hd. simpl. intros [H|[H|H]]; [discriminate | discriminate | contradiction].
Qed.

(* 商关系样本：U0 ≡ {1,2}（对称差 [0] ∈ I0）。 *)
Example eqv_sample : eqv I0 U0 [1; 2].
Proof. vm_compute. auto. Qed.

(* 主滤子 G1（在 1 处）的样本。 *)
Definition G1 (X : list nat) : Prop := In 1 X /\ incl X U0.

(* 样本函数（U0 → ℕ 的表）。 *)
Definition f1 (a : nat) : nat := match a with 0 => 3 | 1 => 1 | _ => 4 end.
Definition g1 (a : nat) : nat := match a with 0 => 2 | 1 => 2 | _ => 0 end.

(* 真值集：{a | f1 a < g1 a} = [1]——在 G1 下裁决为真。 *)
Example truth_set : filter (fun a => f1 a <? g1 a) U0 = [1].
Proof. reflexivity. Qed.

Example los_sample : G1 (filter (fun a => f1 a <? g1 a) U0).
Proof.
  assert (hf : filter (fun a => f1 a <? g1 a) U0 = [1]) by reflexivity.
  rewrite hf. split.
  - left. reflexivity.
  - intros x [Hx|[]]. subst x. right. left. reflexivity.
Qed.

(* 引理 2.29 的影子：主滤子下 [Id] 的取值是那一点。 *)
Example id_sample : G1 (filter (fun a => a =? 1) U0).
Proof.
  assert (hf : filter (fun a => a =? 1) U0 = [1]) by reflexivity.
  rewrite hf. split.
  - left. reflexivity.
  - intros x [Hx|[]]. subst x. right. left. reflexivity.
Qed.

End Ch109.
```

Coq 侧两个实测坑：`in_dec` 的 `destruct` 对其 delta-展开后的
match 不生效（`diffL_id` 首版因此卡壳——改走 `in_diffL` 的
「无元素 ⟹ 空表」路线）；`eqv_trans` 的四段 append 中每个
元素要按「x∈Y 与否」再分案放入正确的对称差段（第三段
`diffL Y Z` 收「x∈Y∧x∉Z」与「x∈Z∧x∉Y」两种来客——首版
把第二来客错放到 `left`）。

样本账三连的战术分工也值得记：正样本（`forces_sample1`、
`eqv_sample`、`truth_set`）走 `vm_compute`/`reflexivity`——
内核直接算值；负样本 `forces_sample2` 需要先把 `diffL` 的值
`assert … by reflexivity` 钉死再 `intros [H|[H|H]]` 三分支
（空表头、`[0]` 头、False 尾——`discriminate` × 2 +
`contradiction`），因为 `vm_compute` 在目标上只归约不分解
析取；`los_sample`/`id_sample` 则先以 `reflexivity` 算出
`filter … = [1]` 再手工拆 `In 1 [1]` 与 `incl` 两半。三种
姿势对应三种命题形态（纯等式、否定、合取），是 Coq 处理
「决定性样本」的常用三件套。

Agda 版（`examples/agda/Ch109_genericultrapower.agda`）走
**Dec 路线**（yes/no 模式自带方程，绕开 Bool `with`-抽象的
统一卡壳）：

```agda
-- 第 109 章：理想力迫的序与商关系——泛型超幂的有限影子。
module Ch109_genericultrapower where

open import Data.Nat using (ℕ; zero; suc; _<ᵇ_)
open import Data.List using (List; []; _∷_; _++_; filter; filterᵇ)
open import Data.List.Relation.Unary.Any using (Any; here; there; map)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; sym; trans)
open import Relation.Nullary using (Dec; yes; no; ¬_; ¬?)
open import Data.Bool using (Bool; true; false; if_then_else_; T)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.Unit using (⊤; tt)

pred : ℕ → ℕ
pred zero = zero
pred (suc k) = k

-- ── 零、自建件：可判定的成员关系（Dec 路线——方程随 yes/no 保留） ──

nat-eq-dec : (x y : ℕ) → Dec (x ≡ y)
nat-eq-dec zero zero = yes refl
nat-eq-dec zero (suc _) = no (λ ())
nat-eq-dec (suc _) zero = no (λ ())
nat-eq-dec (suc m) (suc n) with nat-eq-dec m n
... | yes e = yes (cong suc e)
... | no ne = no (λ se → ne (cong pred se))

inL-dec : (x : ℕ) (l : List ℕ) → Dec (Any (x ≡_) l)
inL-dec x [] = no (λ ())
inL-dec x (y ∷ ys) with nat-eq-dec x y
... | yes e = yes (here e)
... | no ne with inL-dec x ys
...   | yes e2 = yes (there e2)
...   | no ne2 = no nd
  where
  nd : Any (x ≡_) (y ∷ ys) → ⊥
  nd (here e) = ne e
  nd (there e) = ne2 e

-- ── 一、理想力迫的序：C ≤ D ⟺ C − D ∈ I（差集的成员刻画） ──

diffL : List ℕ → List ℕ → List ℕ
diffL C D = filter (λ z → ¬? (inL-dec z D)) C

diffL-any : (C D : List ℕ) (x : ℕ) →
            Any (x ≡_) (diffL C D) → Any (x ≡_) C × ¬ (Any (x ≡_) D)
diffL-any [] D x ()
diffL-any (y ∷ C) D x h with inL-dec y D
... | yes yd = let ih = diffL-any C D x h in there (proj₁ ih) , proj₂ ih
... | no nyd with h
...   | here eq = here eq ,
                 (λ ad → nyd (map (λ xw → trans (sym eq) xw) ad))
...   | there h' = let ih = diffL-any C D x h' in there (proj₁ ih) , proj₂ ih

no-elem-nil : {A : Set} (l : List A) → (∀ x → ¬ (Any (x ≡_) l)) → l ≡ []
no-elem-nil [] _ = refl
no-elem-nil (x ∷ l) h = ⊥-elim (h x (here refl))

diffL-id : (C : List ℕ) → diffL C C ≡ []
diffL-id C = no-elem-nil (diffL C C) hnil
  where
  hnil : ∀ x → ¬ (Any (x ≡_) (diffL C C))
  hnil x h with diffL-any C C x h
  ... | h1 , h2 = ⊥-elim (h2 h1)

-- ── 二、商关系：X ≡ Y（mod I）⟺ X△Y ∈ I ──

nat-eq : ℕ → ℕ → Bool
nat-eq zero zero = true
nat-eq zero (suc _) = false
nat-eq (suc _) zero = false
nat-eq (suc m) (suc n) = nat-eq m n

list-eq : List ℕ → List ℕ → Bool
list-eq [] [] = true
list-eq [] (_ ∷ _) = false
list-eq (_ ∷ _) [] = false
list-eq (x ∷ xs) (y ∷ ys) = if nat-eq x y then list-eq xs ys else false

inLL : List ℕ → List (List ℕ) → Bool
inLL X [] = false
inLL X (Y ∷ I) = if list-eq X Y then true else inLL X I

eqv : List (List ℕ) → List ℕ → List ℕ → Set
eqv I X Y = T (inLL (diffL X Y ++ diffL Y X) I)

++-nil : (l : List ℕ) → l ++ [] ≡ l
++-nil [] = refl
++-nil (x ∷ l) = cong (x ∷_) (++-nil l)

eqv-refl : (I : List (List ℕ)) (X : List ℕ) →
           T (inLL [] I) → eqv I X X
eqv-refl I X h rewrite diffL-id X = h

-- ── 三、样本理想与真值集（决定性核查） ──

U0 : List ℕ
U0 = 0 ∷ 1 ∷ 2 ∷ []

I0 : List (List ℕ)
I0 = [] ∷ (0 ∷ []) ∷ []

-- 序样本：{1} ≤ {0,1}（差 ∅ ∈ I0）。
forces-sample : T (inLL (diffL (1 ∷ []) (0 ∷ 1 ∷ [])) I0)
forces-sample = tt

-- 商关系样本：U0 ≡ {1,2}（对称差 [0] ∈ I0）。
eqv-sample : eqv I0 U0 (1 ∷ 2 ∷ [])
eqv-sample = tt

-- 样本函数（U0 → ℕ 的表）。
f1 g1 : ℕ → ℕ
f1 zero = 3
f1 (suc zero) = 1
f1 _ = 4
g1 zero = 2
g1 (suc zero) = 2
g1 _ = 0

-- Bool 成员（样本核查用）。
inLb : ℕ → List ℕ → Bool
inLb x [] = false
inLb x (y ∷ ys) = if nat-eq y x then true else inLb x ys

-- 真值集：{a | f1 a < g1 a} = {1}——在主滤子 G1 下裁决为真。
truth-sample : inLb 1 (filterᵇ (λ a → f1 a <ᵇ g1 a) U0) ≡ true
truth-sample = refl

-- 引理 2.29 的影子：主滤子下 [Id] 的取值是那一点。
id-sample : inLb 1 (filterᵇ (λ a → nat-eq a 1) U0) ≡ true
id-sample = refl
```

Agda 本章的最大坑是 **Bool `with`-抽象的统一卡壳**：对
`inL x D`（Bool）做 with，分支里既拿不到 `inL y D ≡ false`
的方程、也无法把新造的 `inL y D ≡ true` 与分支字面量对立——
stdlib `filter` 内部又把 `¬? (inL-dec …)` 分解成
`not (does …)`，抽不对层就 SplitError.UnificationStuck。改走
**Dec/yes-no** 路线后方程随构造子保留，`diffL-any` 的三个分案
一遍过。另两处小坑：using 导入表 `_++_` 尾下划线吞字（108 章
同族）；`( [] : List ℕ )` 项内类型标注不合法（改为裸 `[]` 由
后参推断）。

`diffL-any` 的 `no nyd` 分支里那句
`nyd (map (λ xw → trans (sym eq) xw) ad)` 是本章 Agda 的
技术亮点：头部成员 `x ≡ y`（eq）与 D-成员 `x ≡ w`（ad 的
证据）拼成 `y ≡ w`——`Any.map` 把 $(x\equiv\_)$ -证据整族
搬到 $(y\equiv\_)$ 上，正好喂给 nyd。这条「等式沿成员关系
重命名」的小管道是商关系证明里反复出现的手势，值得在
读码时停留半分钟。`diffL-id` 走「无元素列表即空表」的
`no-elem-nil` 通道，与 Coq 侧同思路但少一层 destruct——
Agda 的模式匹配直接把「有头元素」分支反证在
`⊥-elim (h x (here refl))` 里。

Isabelle 版（`examples/isabelle/ST109/Genericultrapower.thy`）
以 ZF 本体的集合运算 + 确定性规则链覆盖序与商关系的定理面：

```isabelle
theory Genericultrapower
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 109 章：理想力迫的序与商关系（确定性规则链，沿 103-108 章纪律）。
理想以集合族 I 给出（含 0、向下闭、二元并闭）；正测 = 不在 I 中。
本体（定义 2.23-2.26、引理 2.29/2.30、定理 2.18/2.19、例 2.2-2.4）留在正文。\<close>

definition ForcesP :: "[i, i, i] \<Rightarrow> o" where
  "ForcesP(I, C, D) \<equiv> C - D \<in> I"

text \<open>自反：C - C = 0。\<close>

lemma forces_refl:
  assumes h0: "0 \<in> I"
  shows "ForcesP(I, C, C)"
  unfolding ForcesP_def using h0 by (simp add: Diff_cancel)

text \<open>传递（理想公理形态）：C - D \<in> I、D - E \<in> I、
并闭、向下闭 ⟹ C - E \<in> I——关键包含
C - E \<subseteq> (C - D) \<union> (D - E)。\<close>

lemma forces_trans_raw:
  assumes hun: "\<forall>X\<in>I. \<forall>Y\<in>I. X \<union> Y \<in> I"
    and hdown: "\<forall>X\<in>I. \<forall>Y. Y \<subseteq> X \<longrightarrow> Y \<in> I"
    and h1: "C - D \<in> I" and h2: "D - E \<in> I"
  shows "C - E \<in> I"
proof -
  from hun h1 have hall: "\<forall>Y\<in>I. (C - D) \<union> Y \<in> I" by (rule bspec)
  from hall h2 have hunion: "(C - D) \<union> (D - E) \<in> I" by (rule bspec)
  from hdown hunion have hdownall: "\<forall>Y. Y \<subseteq> (C - D) \<union> (D - E) \<longrightarrow> Y \<in> I"
    by (rule bspec)
  from hdownall have hmp: "C - E \<subseteq> (C - D) \<union> (D - E) \<longrightarrow> C - E \<in> I"
    by (rule spec)
  have hsub: "C - E \<subseteq> (C - D) \<union> (D - E)"
  proof (rule subsetI)
    fix x
    assume hx: "x \<in> C - E"
    then have hxC: "x \<in> C" by (rule DiffD1)
    from hx have hxne: "x \<notin> E" by (rule DiffD2)
    show "x \<in> (C - D) \<union> (D - E)"
    proof (rule disjE [OF excluded_middle])
      assume hxD: "x \<in> D"
      from hxD hxne have "x \<in> D - E" by (rule DiffI)
      thus "x \<in> (C - D) \<union> (D - E)" by (rule UnI2)
    next
      assume hxnd: "x \<notin> D"
      from hxC hxnd have "x \<in> C - D" by (rule DiffI)
      thus "x \<in> (C - D) \<union> (D - E)" by (rule UnI1)
    qed
  qed
  from hmp hsub show ?thesis by (rule mp)
qed

text \<open>商关系：X \<equiv> Y（mod I）⟺ X\<triangle>Y \<in> I（对称差 = 双向差的并）。\<close>

definition SymDiffI :: "[i, i] \<Rightarrow> i" where
  "SymDiffI(X, Y) \<equiv> (X - Y) \<union> (Y - X)"

definition EqvP :: "[i, i, i] \<Rightarrow> o" where
  "EqvP(I, X, Y) \<equiv> SymDiffI(X, Y) \<in> I"

lemma eqv_refl:
  assumes h0: "0 \<in> I"
  shows "EqvP(I, X, X)"
  unfolding EqvP_def SymDiffI_def using h0 by (simp add: Diff_cancel)

end
```

Isabelle 侧值得记一手的是 `excluded_middle`——ZF（FOL 底座）
自带排中律规则，`proof (rule disjE [OF excluded_middle])` 是
成员二分的确定性用法，不必绕道序数引理（108 章用
`Ord_linear_lt` 分案是因为那边需要的是三分案；这里纯二分，
排中律直接了当）。

`forces_trans_raw` 的六步链条（bspec 取并闭的偏应用 → bspec
取 hdown 的全称实例 → spec 取 C−E 特例 → subsetI 内含证明 →
mp 收口）是确定性规则链纪律的又一次完整演出：全程没有一步
搜索，每条规则的名字都写在源码里。内含证明的三分案里，
`DiffD1/DiffD2` 拆差集成员、`DiffI` 重装、`UnI1/UnI2` 选边——
这五条集合运算规则覆盖了理想力迫序传递性的全部集合论内容。
`eqv_refl` 一行收尾（`simp add: Diff_cancel` 归零双向差）则
展示「simp 只做定向重写」的边界用法：它解方程，不做搜索。

Julia 版（`examples/julia/109_genericultrapower.jl`）是五件
的全量账本：

```julia
# 第 109 章：理想力迫、泛型超滤子候选与有限 Łoś——泛型超幂的有限影子。
println("==== 109")

# ── 一、样本理想 I = {∅, {0}}（位掩码：bit i = 元素 i）与正测集 ──
const IDEAL = Set([0b000, 0b001])
pos(m) = !(m in IDEAL)
const IPOS = collect(filter(pos, 0:7))          # 6 个正测集

le(C, D) = (C & ~D) in IDEAL                    # C ≤ D ⟺ C − D ∈ I

@assert le(0b010, 0b011)                        # {1} ≤ {0,1}（差 ∅）
@assert !le(0b111, 0b011)                       # U ≰ {0,1}（差 {2} 正测）
@assert all(le(C, C) for C in IPOS)             # 自反
for C in IPOS, D in IPOS, E in IPOS             # 传递全量核查
    if le(C, D) && le(D, E)
        @assert le(C, E)
    end
end

# ── 二、商关系与商代数 P(U)/I ──
eqv(X, Y) = xor(X, Y) in IDEAL                  # X ≡ Y ⟺ X△Y ∈ I
@assert eqv(0b111, 0b110)                       # U ≡ {1,2}
@assert eqv(0b011, 0b010)                       # {0,1} ≡ {1}
classes = Set{Int}()
for m in 0:7
    bits12 = m & 0b110                          # 类由 {1,2} 上的截痕决定
    push!(classes, bits12 == 0b110 ? 7 : bits12)
end
@assert classes == Set([0, 2, 4, 7])            # P(U)/I ≅ 4 元布尔代数

# ── 三、泛型超滤子候选：主滤子 G(a)（位 a 非零的正测集） ──
G(a) = Set(m for m in IPOS if (m & (1 << a)) != 0)
@assert G(1) == Set([0b010, 0b011, 0b110, 0b111])
@assert G(2) == Set([0b100, 0b101, 0b110, 0b111])

# 超滤子四公理 (a)-(d) 的核查（书 p211）。
function ultra(G)
    (7 in G && !(0 in G)) &&                         # (a) 顶与不含底
    all((C & D) in G for C in G, D in G) &&          # (b) 交闭
    all(E in G for C in G for E in IPOS if le(C, E)) &&  # (c) 向上（C ≤ E）
    all((C in G) || ((7 & ~C) in G) for C in IPOS)   # (d) 超
end
@assert ultra(G(1)) && ultra(G(2))

# ── 四、稠密集与相遇（泛型性核查） ──
dense(Ds) = all(any(le(Y, X) for Y in Ds) for X in IPOS)
denses = Set{Set{Int}}()
for mask in 0:63
    D = Set(IPOS[i] for i in 1:6 if (mask >> (i - 1)) & 1 == 1)
    if dense(D)
        push!(denses, D)
    end
end
@assert length(denses) > 0 && all(dense, denses)
for a in (1, 2)
    for D in denses
        @assert !isempty(intersect(G(a), D))     # 候选滤子遇遍每个稠密集
    end
end

# ── 五、有限 Łoś：全函数对 × 双滤子（真值集裁决） ──
funcs = vec([(x, y, z) for x in 0:2, y in 0:2, z in 0:2])   # 27 个表
fval(f, a) = (a == 0 ? f[1] : (a == 1 ? f[2] : f[3]))
truth_lt(f, g) = (fval(f,0) < fval(g,0)) | ((fval(f,1) < fval(g,1)) << 1) | ((fval(f,2) < fval(g,2)) << 2)
truth_eq(f, g) = (fval(f,0) == fval(g,0)) | ((fval(f,1) == fval(g,1)) << 1) | ((fval(f,2) == fval(g,2)) << 2)

for a in (1, 2), f in funcs, g in funcs
    @assert ((truth_lt(f, g) & (1 << a)) != 0) == (fval(f, a) < fval(g, a))
    @assert ((truth_eq(f, g) & (1 << a)) != 0) == (fval(f, a) == fval(g, a))
end

# 引理 2.29 的影子：主滤子下 [Id] 的取值是那一点（eval 同构）。
for a in (1, 2)
    idtruth = (a == 1 ? 0b010 : 0b100)
    @assert idtruth in G(a)
    for f in funcs
        @assert fval(f, a) == (a == 0 ? f[1] : (a == 1 ? f[2] : f[3]))  # 代表即取值
    end
end

# ── 六、下降链（引理 2.30(3) 的有限影子：无严格下降链超过 2 级） ──
function max_desc_len()
    best = 1
    for m in 0:63                      # 枚举链的起点集——直接 DFS
        stack = [(c, 1) for c in IPOS]
        while !isempty(stack)
            c, n = pop!(stack)
            best = max(best, n)
            for d in IPOS
                if d != c && le(d, c) && !le(c, d)   # d 严格强于 c
                    push!(stack, (d, n + 1))
                end
            end
        end
    end
    return best
end
@assert max_desc_len() == 2            # 商代数 4 元：1 > 原子，无更长链

println("Julia：序自反/传递全量；商代数 4 元；超滤子四公理；")
println("稠密集全相遇；有限 Łoś 27×27×2 双滤子；严格下降链至多 2 级")
println("END ====")
```

穷举账的三处看点：**商代数 4 元**——$\{0\}$ 与 ∅ 同类（位 0
被理想抹平）、$\{1,2\}$ 与 U 同类，类由 $\{1,2\}$ 上的截痕
唯一决定；**稠密集全相遇**——有限宇宙里「泛型」可判定，两个
候选主滤子遇遍全部稠密集（实测方向坑：滤子的向上闭包是
「C ∈ G ∧ C ≤ E ⟹ E ∈ G」，首版把 `le` 写反被样本击中）；
**Łoś 全量对拍**——同一对函数在 G(1) 与 G(2) 下可以给出相反
裁决（真值集含 1 不含 2 时），这正是「裁决属于滤子不属于数据」
的机制演示。

件五的 DFS 有个值得一提的细节：严格链的判定用了
`le(d, c) && !le(c, d)`（强于且不等价），因为 ≤ 是模 I 的
前序——$\{0,1\}$ 与 $\{1\}$ 双向 ≤（同商类），若只判
单向会把等价对误计为下降步。这个「前序 vs 偏序」的分寸在
四助理的定理层由商关系（eqv）显式处理，在数值层就落成
一行双重判定；两侧共同钉住「严格下降只能在商代数的层级间
发生」——而商代数只有两层，链长 2 由此成为**结构性事实**
而非巧合。

Python 版（`examples/python/109_genericultrapower.py`）同账
独立实现（frozenset、原生 `^`、迭代器栈）：

```python
# 第 109 章：与 Julia 独立对拍——理想力迫、泛型超滤子候选与有限 Łoś。
import io
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

IDEAL = frozenset({0b000, 0b001})        # I = {∅, {0}}（位掩码）


def pos(m):
    return m not in IDEAL


IPOS = [m for m in range(8) if pos(m)]   # 6 个正测集


def le(C, D):
    return (C & ~D) in IDEAL             # C ≤ D ⟺ C − D ∈ I


def eqv(X, Y):
    return (X ^ Y) in IDEAL              # X ≡ Y ⟺ X△Y ∈ I


def G(a):
    return frozenset(m for m in IPOS if (m & (1 << a)) != 0)


def dense(Ds):
    return all(any(le(Y, X) for Y in Ds) for X in IPOS)


def fval(f, a):
    return f[a]


def truth_lt(f, g):
    return (fval(f, 0) < fval(g, 0)) | ((fval(f, 1) < fval(g, 1)) << 1) | ((fval(f, 2) < fval(g, 2)) << 2)


def truth_eq(f, g):
    return (fval(f, 0) == fval(g, 0)) | ((fval(f, 1) == fval(g, 1)) << 1) | ((fval(f, 2) == fval(g, 2)) << 2)


def main():
    print("==== 109")
    # 序：自反 + 传递全量 + 样本。
    assert le(0b010, 0b011)              # {1} ≤ {0,1}
    assert not le(0b111, 0b011)          # U ≰ {0,1}
    assert all(le(C, C) for C in IPOS)
    for C in IPOS:
        for D in IPOS:
            for E in IPOS:
                if le(C, D) and le(D, E):
                    assert le(C, E)

    # 商关系与商代数。
    assert eqv(0b111, 0b110)             # U ≡ {1,2}
    assert eqv(0b011, 0b010)             # {0,1} ≡ {1}
    classes = set()
    for m in range(8):
        bits12 = m & 0b110
        classes.add(7 if bits12 == 0b110 else bits12)
    assert classes == {0, 2, 4, 7}       # P(U)/I ≅ 4 元布尔代数

    # 泛型超滤子候选与四公理 (a)-(d)。
    assert G(1) == frozenset({0b010, 0b011, 0b110, 0b111})
    assert G(2) == frozenset({0b100, 0b101, 0b110, 0b111})
    for a in (1, 2):
        g = G(a)
        assert 7 in g and 0 not in g                       # (a)
        assert all((C & D) in g for C in g for D in g)     # (b)
        assert all(E in g for C in g for E in IPOS if le(C, E))  # (c)
        assert all((C in g) or ((7 & ~C) in g) for C in IPOS)    # (d)

    # 稠密集全相遇（泛型性）。
    denses = []
    for mask in range(64):
        D = frozenset(IPOS[i] for i in range(6) if (mask >> i) & 1)
        if dense(D):
            denses.append(D)
    assert denses and all(dense(D) for D in denses)
    for a in (1, 2):
        for D in denses:
            assert G(a) & D                # 候选滤子遇遍每个稠密集

    # 有限 Łoś：27×27 函数对 × 双滤子。
    funcs = [(x, y, z) for x in range(3) for y in range(3) for z in range(3)]
    for a in (1, 2):
        for f in funcs:
            for g in funcs:
                assert ((truth_lt(f, g) & (1 << a)) != 0) == (fval(f, a) < fval(g, a))
                assert ((truth_eq(f, g) & (1 << a)) != 0) == (fval(f, a) == fval(g, a))

    # 引理 2.29 的影子：主滤子下 [Id] 的取值是那一点。
    for a in (1, 2):
        assert (1 << a) in G(a)

    # 下降链：严格链至多 2 级（引理 2.30(3) 的有限影子）。
    best = 1
    stack = [(c, 1) for c in IPOS]
    while stack:
        c, n = stack.pop()
        best = max(best, n)
        for d in IPOS:
            if d != c and le(d, c) and not le(c, d):
                stack.append((d, n + 1))
    assert best == 2

    print("Python：序自反/传递全量；商代数 4 元；超滤子四公理；")
    print("稠密集全相遇；有限 Łoś 27×27×2 双滤子；严格下降链至多 2 级——与 Julia 对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
```

对拍独立性：Julia 用 `xor`/`~`/元组索引三目，Python 用 `^`/
`~`/列表索引，商代数类账一个走 Set{Int} 一个走 set——五件账
（序、类、四公理、全相遇、Łoś 全量、链长 2）两侧完全吻合。

Python 侧一处实现细节值得点名：`le` 里的 `~C` 对 Python 整数
是无限位补（$-C-1$ ），`C & ~D` 因此天然是正确的有限差
——与 Julia 同构但语义路径不同（Julia 的 `Int64` 补码有
位数上限，靠 `C & ~D` 的与运算截回非负）。两侧若有一处把
`& ~D` 误写成 `| ~D`，商代数类账（4 元）会立刻崩成 8 类——
穷举账的价值正在于此：**实现层的手抖无处藏身**。

Prolog 版（`examples/prolog/109_genericultrapower.pl`）把全部
查询做成可回溯谓词，下降链与 Łoś 样本尤其体现非确定性见证：

```prolog
:- encoding(utf8).
% 第 109 章：理想力迫、泛型超滤子候选、稠密集相遇与下降链查询。

% ── 一、样本理想（位掩码）与正测集 ──
ideal(M) :- member(M, [0, 1]).            % I = {∅, {0}}
pos(M) :- between(0, 7, M), \+ ideal(M).
ipos(M) :- pos(M).

% C ≤ D ⟺ C − D ∈ I。
le(C, D) :- Dg is C /\ (\D), ideal(Dg).

% ── 二、泛型超滤子候选：主滤子 ──
gmem(a1, M) :- pos(M), M /\ 2 > 0.        % G(1)：含 1 的正测集
gmem(a2, M) :- pos(M), M /\ 4 > 0.        % G(2)：含 2 的正测集

% 超滤子四公理 (a)-(d)。
ultra(A) :-
    gmem(A, 7), \+ gmem(A, 0),
    forall((gmem(A, C), gmem(A, D)), (I is C /\ D, gmem(A, I))),
    forall((gmem(A, C), ipos(E), le(C, E)), gmem(A, E)),
    forall(ipos(C), (gmem(A, C) ; Uc is 7 /\ (\C), gmem(A, Uc))).

% ── 三、稠密集与相遇（去重子集枚举） ──
all_ipos(I) :- findall(M, ipos(M), I).

sub_ipos([], []).
sub_ipos([H|T], [H|S]) :- sub_ipos(T, S).
sub_ipos([_|T], S) :- sub_ipos(T, S).

dense(Ds) :- forall(ipos(X), (member(Y, Ds), le(Y, X))).

meets(A, Ds) :- member(Y, Ds), gmem(A, Y).

% ── 四、下降链（引理 2.30(3) 的有限影子） ──
desc_chain([C]) :- ipos(C).
desc_chain([C, D|Rest]) :-
    ipos(C), ipos(D), D \= C, le(D, C), \+ le(C, D),
    desc_chain([D|Rest]).

% ── 五、有限 Łoś 样本（真值集裁决） ──
fval(f, 0, 3). fval(f, 1, 1). fval(f, 2, 4).
fval(g, 0, 2). fval(g, 1, 2). fval(g, 2, 0).

truth_lt(N1, N2, M) :-
    ( fval(N1, 0, A), fval(N2, 0, B), A < B -> B1 = 1 ; B1 = 0 ),
    ( fval(N1, 1, A2), fval(N2, 1, B2), A2 < B2 -> B2v = 1 ; B2v = 0 ),
    ( fval(N1, 2, A3), fval(N2, 2, B3), A3 < B3 -> B3v = 1 ; B3v = 0 ),
    M is B1 + (B2v << 1) + (B3v << 2).

main :-
    format("==== 109~n"),
    % 序正反 + 自反 + 传递。
    le(2, 3),                                 % {1} ≤ {0,1}
    \+ le(7, 3),                              % U ≰ {0,1}
    forall(ipos(C), le(C, C)),
    forall((ipos(C), ipos(D), ipos(E), le(C, D), le(D, E)), le(C, E)),
    % 超滤子四公理。
    ultra(a1), ultra(a2),
    % 稠密集全相遇（泛型性）。
    all_ipos(IP),
    findall(D, (sub_ipos(IP, D), D \= [], dense(D)), Ds),
    Ds \= [],
    forall((member(A, [a1, a2]), member(D, Ds)), meets(A, D)),
    % 有限 Łoś 样本：{a | f < g} = {1}——G(1) 下为真、G(2) 下为假。
    truth_lt(f, g, M), M == 2,
    gmem(a1, M), \+ gmem(a2, M),
    % 引理 2.29 影子：{a | Id a = 1} = {1} ∈ G(1)。
    gmem(a1, 2),
    % 下降链：最长严格链 2 级。
    findall(L, (desc_chain(Ch), length(Ch, L)), Ls),
    max_list(Ls, Max), Max == 2,
    format("序正反+自反传递；超滤子四公理；稠密集全相遇；Łoś 样本双向；下降链至多 2 级~n"),
    writeln("END ====").
```

Prolog 侧一个工程坑：首版子集枚举用「逐元素重复选择」的
`subset_ipos([H|T]) :- ipos(H), subset_ipos(T)`——允许重复
选元，findall 直接发散（实测卡满 180 秒超时）；改为标准的
**保留/跳过双子句**（`sub_ipos/2`）后 64 个子集一次枚举完。
Łoś 样本的双向查询（`gmem(a1, M)` 与 `\+ gmem(a2, M)` 同一
真值集）是「裁决属于滤子」的最短现场。

## 109.10 机器的边界

**覆盖**（代数层，全部有限可判定）：

- 序 `le` 的自反/传递（四助理定理件 + 数值全量）；
- 商关系的自反/传递与 $\mathcal P(U)/I\cong$ 4 元布尔代数的
  类账；
- 主滤子候选的四公理 (a)–(d) 逐条核查 + 遇遍全部稠密集
  （有限宇宙的「泛型性」）；
- 有限 Łoś：原子公式（=、<）的真值集裁决对代表换元的稳定性
  （Lean 定理件）与 27×27×2 全量对拍；
- $[\mathrm{Id}]$ 的主滤子取值（引理 2.29 的影子）；
- 严格下降链 ≤ 2 级（引理 2.30(3) 的集合层影子）。

**不覆盖**（本体，超穷层）：

- **泛型超滤子本身**：主滤子是平凡替身——$\mathbb P(I)$ 的
  真泛型滤子在有限宇宙不存在（有限偏序的泛型对象可被枚举
  决定，无新意）；「V-超滤子在扩张中诞生」这一分野（109.3b）
  不可复现。
- **$\sigma$ -完全、正规、饱和**：全部是不可数组合性质；
  机器宇宙的理想天然 $\sigma$ -完全（有限），正规与饱和
  无从谈起。
- **峭壁性（良基性）**：引理 2.30 的三等价在超穷层才分真伪
  ——有限宇宙的超幂恒良基（同构于 $\mathbb N$ 的截段），
  「不峭壁」的反例（例 2.2）需要 $\omega_1$ -长的坍塌函数。
- **Łoś 的量词条款**：定理 2.18 对 $\forall$ 的归纳需要
  「大并集在 G 中」——超滤子完全性的用法，有限主滤子下
  平凡化；机器只核原子层。
- **例 2.4 的基数账**：截痕注入、正规性断言、$\kappa^+$
  结算——全部在 $\omega_1$ /κ 层。

一处口径要钉死：机器里「候选滤子遇遍全部稠密集」与正文的
「泛型」在**有限宇宙里重合**（枚举一切稠密集），但正文泛型
滤子的存在性依赖力迫定理（ZFC 不可内部见证），两者是
「机制替身」而非「实例复现」。

最后把「为什么主滤子是唯一可选的候选」讲透。有限集合 U 上的
每个超滤子都是主滤子（$\{X\mid a\in X\}$ ，由「有限族有
$\subseteq$ -极小元」一句话证明）；于是「泛型超滤子候选」
在 8 元幂集宇宙里只有两个非理想点（1 与 2——点 0 的主滤子
含理想成员 $\{0\}$ ，不合法）。这不是样本选择的贫乏，而是
**有限性的必然**：非主超滤子的存在性本身等价于无穷性
（需要 $\omega$ 上的自由超滤子型论证）。正文的全部张力
——「G 是新对象」「超幂在扩张中」「峭壁性成谜」——都以
非主性为前提；机器宇宙从根上没有这个前提，所以它核查的是
P(I) 的**机制层**（序、商、公理、真值集、链）而非**存在层**。
这与 107/108 章的边界声明一脉相承：有限影子永远只替身
「结构」，不替身「存在」。

## 109.11 本章要点与检查问题

**要点**：

一句话总结本章：**把「理想」当作力迫的原料，泛型滤子把
正测集拧成扩张中的超滤子，超幂与 Łoś 把 V 的结构折进一张
由 G 裁决的真值表——峭壁与否决定这张表能否塌回传递集合，
饱和则把 $\omega_1$ 推上可测基数的影位。**

1. 理想力迫 $\mathbb P(I)=(I^+,\le)$ ：正测集、序
   $C\le D\iff C-D\in I$ ；泛型滤子在扩张中成为 V-超滤子
   （四公理，(d) 来自二分割的极大反链性）（109.2）。
2. 泛型超幂 $\Pi(V,E)$ 与 Łoś（定理 2.18）；
   **普通超幂在 V 内、泛型超幂先借扩张中的滤子**——峭壁性
   因此是力迫语句（109.3/109.3b）。
3. 精良（每点的主集族在滤子中）与正规（选择函数在大集上
   常值）；引理 2.29：$\pi_G([\mathrm{Id}])=i_G''\bigcup A$
   ——恒等函数点名像序列（109.4）。
4. 峭壁理想（定义 2.25）⟺ 无严格下降泛函序列（引理 2.30(3)）
   ⟺ 分割序列的中心化选取交非空（(2)）——泛函是布尔值名字
   的组合表示，赋秩函数把树翻译回下降链（109.5）。
5. 有界理想不峭壁（坍塌函数自造下降）；$\omega_2$ -饱和 ⟹
   峭壁（不交化改造 + $\sigma$ -完全的交存活）（109.6）。
6. 定理 2.19 三重馈赠：名字可单函数表示、超幂封闭、
   $\omega_1^V=\mathrm{crit}(i_G)$ 且在超幂内可数——
   饱和理想把 $\omega_1$ 变成可测基数的影子（109.6）。
7. 例 2.4：泛型超幂重证 Silver 定理（截痕注入 + 正规性上界
   + 前段账）；§2.7.2 的 Mitchell 定理预告（可测 + Lévy
   塌塌 ⟹ $\omega_1$ 上峭壁理想）（109.7）。
8. 机器五件：序代数、商代数、主滤子四公理+全相遇、有限
   Łoś（定理件+全量对拍）、下降链 ≤2（109.9）。

**检查问题**：

（建议顺序：先做 1–4 打牢机制，再做 5–8 走通定理链，最后
用 9–10 对照机器边界自查。）

1. $\mathbb P(I)$ 的条件为什么取 $I^+$ 而不是全幂集？
   若允许 $I$ 中成员为条件，泛型滤子会怎样？
2. 四公理 (d)（超性）的证明里，泛型性用在哪个极大反链上？
   由此说明：为什么普通滤子只需三条公理而泛型滤子免费获得
   第四条。
3. 普通超幂与泛型超幂的分野（109.3b）：哪三个对象「搬家」
   到了扩张中？峭壁理想的定义为什么必须写成力迫语句？
4. 引理 2.29 的两个方向分别用到精良与正规——各自在哪一步？
   把 $\bigcup A$ 换成基 κ、A 换成 $[\kappa]^\omega$ ，
   这条引理如何变成「$[\kappa]^\omega$ 的超幂里
   $j''\kappa$ 被 $[\mathrm{Id}]$ 点名」？
5. 泛函 F 为什么是「布尔值名字的组合表示」？引理 2.30 的
   (3)→(2) 方向中，赋秩函数 $\rho_\alpha$ 起什么作用？
6. 例 2.2 的坍塌函数 $f_X$ 为什么给出下降泛函序列？
   它违反了引理 2.30 的哪一条？
7. 例 2.3 的不交化改造为什么需要饱和性？$\sigma$ -完全性
   用在哪一步（提示：$\bigcap_n D_n$ ）？
8. 定理 2.19(3) 的满射 $[g]:[c_\omega]\twoheadrightarrow [\mathrm{Id}]$ 为什么说明 $\omega_1^V$ 在超幂内可数？
   这与 $i_G(\omega_1^V)>\omega_1^V$ 如何相容？
9. 机器件三的「候选滤子」为什么只能是主滤子？由此说明
   「遇遍全部稠密集」在有限宇宙的可判定性来自哪里。
10. 机器件五的下降链是集合链（商代数层级）而引理 2.30(3)
    是泛函链（序数逐点）——正文用哪座桥把两者连通？机器
    为什么只做集合侧？

---

**延伸阅读**：R. M. Solovay, *Real-valued measurable cardinals*,
Proc. Sympos. Pure Math. XIII (1971)——泛型超幂的出生地；
T. J. Jech & K. Prikry, *On ideals of sets and the power set
operation*, Bull. AMS 82 (1976)——峭壁理想的命名研究；
T. J. Jech, M. Magidor, W. Mitchell, K. Prikry, *Precipitous
ideals*, JSL 45 (1980)——两个可能性模型；J. H. Silver,
Vancouver ICM 1974——例 2.4 的原始证明。

- 上一章：[108 · 恰当迭代与 PFA](108-pfa.md)
- 下一章：[110 · NS 峭壁、饱和与投影光影原理](110-nssaturation.md)
