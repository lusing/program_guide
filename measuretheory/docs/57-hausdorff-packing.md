# 57 Hausdorff 测度、填充测度与分形维数

**对应胡晓予《高等概率论》§1.5（pp. 16-20）。数学上紧接第 04 章（外测度
与测度的扩张）与第 05 章（Lebesgue–Stieltjes 测度）——本章是测度构造
流水线的第三条支线。**

---

## 57.1 当 Lebesgue 测度失明

第 05 章的 Cantor 集留下一笔未结的账：它是不可数集、是完备集、是
完美集，但 Lebesgue 测度为零——第 $n$ 阶覆盖的总长 $(2/3)^n\to0$ 。
从 Lebesgue 测度的视角，Cantor 集与一个单点没有区别。"不可数"的丰富
结构在长度账本里完全隐形。

问题出在**计账单位**：Lebesgue 测度只用一种尺度（长度，幂次 1）称量
一切集合。Carathéodory（1914）提出、Hausdorff（1919）系统使用的想法
是：**用一族连续变化的尺度 $r^s$（$s>0$）称量同一个集合，再问在哪个
临界幂次上集合的"质量"从 $\infty$ 跌落到 $0$**。这个临界幂次就是
Hausdorff 维数——Cantor 集在 $s=\log 2/\log 3\approx0.6309$ 处相变，
既不是零维的点，也不是一维的线段。

本章按胡书 §1.5 的路线展开：先给出"预测度 → 外测度"的一般机器
（比第 04 章的版本更通用），再定义 Hausdorff 测度与**填充测度**
（packing measure，维数的"上界对偶"），最后把 Cantor 集的维数账
算到分毫不差——机器通道用精确整数证书把维数夹在 $3/5$ 与 $7/10$
之间。

经济与数据科学的落点：资产价格的"粗糙度"（实现波动率的标度指数）、
交易时间的分形结构、网络流量的自相似性，理论上都以 Hausdorff 维数
（及其数值代理——盒计数维数）为刻度。

## 57.2 预测度到外测度：一般机器

第 04 章从半环上的预测度出发造外测度。胡书 §1.5 把这一步抽象成
更一般的形式，允许覆盖族来自**任意集族**。

**预测度**：设 $\mathcal G$ 是一个集族，$t:\mathcal G\to[0,\infty]$
满足 $t(\varnothing)=0$ 。称 $t$ 为 $\mathcal G$ 上的预测度（预测度
不要求可加性——可加性会在覆盖账里自动出现）。

**定理 1.5.1（覆盖外测度）** 定义

$$\mu(E)=\inf\Big\{\sum_{i=1}^\infty t(C_i):\ C_i\in\mathcal G,\ \ E\subseteq\bigcup_{i=1}^\infty C_i\Big\},$$

则 $\mu$ 是 $\Omega$ 全体子集上的**外测度**：$\mu(\varnothing)=0$ 、
单调、可数次可加。

证明的骨架与第 04 章相同，值得再看一遍的是**对角线技巧**：证
$\mu(\bigcup_i E_i)\le\sum_i\mu(E_i)$ 时，对每个 $E_i$ 选覆盖使
$\sum_j t(C_j^{(i)})\le\mu(E_i)+\varepsilon 2^{-i}$ ，把双重序列
$\{C_j^{(i)}\}$ 重排为单序列 $\{D_k\}$ ，则

$$\sum_k t(D_k)=\sum_{i,j}t(C_j^{(i)})\le\sum_i\big(\mu(E_i)+\varepsilon 2^{-i}\big)\le\sum_i\mu(E_i)+\varepsilon .$$

$\varepsilon$ 的指数分配 $2^{-i}$ 保证扰动项求和收敛——这个手法在
Fatou 引理、控制收敛定理的证明里反复出现（第 11 章），现在提前
在集合层面看清。

**定理 1.5.2（上确界保持外测度性）** 若每个 $\mu_i$ 是外测度，则

$$\mu(E):=\sup_i \mu_i(E)$$

仍是外测度。逐条验证即可（sup 保持单调与次可加）。这两个定理是
Hausdorff 测度的全部引擎：**先 inf 后 sup 的双层构造**。

## 57.3 Carathéodory 切割判据：夹逼版

第 04 章的概率版判据用补集：$\mu^*(H)+\mu^*(H^c)=1$ 。一般外测度
没有"总质量 1"，胡书给出**夹逼形式**。

**定义 1.5.3** 称 $E$ 是 $\mu$-可测的，若对任意 $A\subseteq E$ 与
$B\subseteq E^c$ ，

$$\mu(A\cup B)=\mu(A)+\mu(B).$$

即 $E$ 与其补集"背靠背"时，测度精确可加——$E$ 的边界不产生切割
损耗。这与第 04 章的补集判据等价（在有限测度下互相推导），只是
把"与全空间比较"换成了"任意夹逼比较"，更适合无限测度。

**定理 1.5.3** $\mu$-可测集全体 $\mathcal F$ 是 σ 代数；$\mu$ 在
$\mathcal F$ 上可数可加；零测集的任何子集属于 $\mathcal F$ （完备性，
注 1.5.2）。

证明是第 04 章定理 1.3.1 的移植：先证两个可测集之并仍可测（把
$A\cup B$ 沿 $E_1$ 切一刀再用 $E_2$ 补刀，两次切割等式相加减得到
目标等式），再用不交化 $F_i=E_i\setminus\bigcup_{j<i}E_j$ 把可数并
化为可数不交并，有限切割等式取极限。我们不再重复，只强调一个
新观察：**定理 1.5.3(c) 对交也成立**——可测集的可数交可测，这使
$\mathcal F$ 真正是 σ 代数而不只是代数。

## 57.4 测度函数与 Hausdorff 测度

现在装配双层机器。**测度函数**（定义 1.5.4）：$\varphi:(0,\infty)\to[0,\infty]$ ，
右连续，$\varphi(0+)=0$ 。典型选择是幂函数 $\varphi(r)=r^s$ （$s>0$ ），
但也允许 $r^s(\log 1/r)^{-1}$ 这类"带修正的幂"——维数理论里它们
用来分辨临界幂次处的精细结构。

**Hausdorff 外测度**（定义 1.5.4）：

$$\varphi\text{-}m(E)=\sup_{\delta>0}\ \inf\Big\{\sum_i\varphi\big(d(C_i)\big):\ E\subseteq\bigcup_i C_i,\ d(C_i)\le\delta\Big\},$$

其中 $d(C)=\sup\{|x-y|:x,y\in C\|$ 是直径（空集直径取 0 ）。逐层
解读：

- **内层 inf**：用直径不超过 $\delta$ 的集合覆盖 $E$ ，取 $\varphi$
  直径账的最小值——$\delta$ 是"放大镜的分辨率"；
- **外层 sup**：分辨率无限提高（$\delta\downarrow0$ ），覆盖被迫
  越来越精细，账单调上升（覆盖族随 $\delta$ 减小而缩小，inf 变大），
  取极限。

双层构造 = 定理 1.5.1（内层 inf 造外测度，对每个固定 $\delta$ ）
+ 定理 1.5.2（外层 sup 保持外测度性）。限制在 Borel σ 代数上
（区间都是可测的，定理 1.5.3），得到 **Hausdorff 测度**。

特例 $\varphi(r)=r^1$ 在 $\mathbb R$ 上：直径就是区间长，$H^1$ 恰是
Lebesgue 测度（无常数因子）。在 $\mathbb R^n$ 上 $H^n=c_n\cdot\lambda$ ，
$c_n=\pi^{n/2}/(2^n\Gamma(n/2+1))$ ——球对其外接立方体的体积比。
**维度不是整数时**，$H^s$ 是全新的测度，Lebesgue 语言里没有对应物。

## 57.5 Hausdorff 维数：临界指数

固定集合 $E$ ，看 $\mu H[s](E)$ 随 $s$ 的变化。若 $s<t$ ，则对
$d\le1$ 的覆盖单元有 $d^t\le d^s$ ，于是

$$\boxed{\ s<t\ \Longrightarrow\ \mu H[s](E)=\infty\ \text{或}\ \mu H[t](E)=0\ }$$

（mathlib：`hausdorffMeasure_zero_or_top`。）账本在临界处从 $\infty$
跳到 $0$ ——除了临界点本身可能取有限正值外（区间在 $s=1$ 处 $H^1$
= 长度），没有中间地带。**Hausdorff 维数**定义为相变点：

$$\dim_H E:=\inf\{s:\mu H[s](E)=0\}=\sup\{s:\mu H[s](E)=\infty\}.$$

基本性质（mathlib `dimH` API 一一对应）：

1. **单调**：$E\subseteq F\Rightarrow\dim_HE\le\dim_HF$ （`dimH_mono`）；
2. **可数稳定**：$\dim_H\big(\bigcup_n E_n\big)=\sup_n\dim_HE_n$
   （`dimH_iUnion`）——可数集维数为零（单点维数零 + 可数并），
   Cantor 集"不可数才可能有正维数"由此量化；
3. **单点零维**（`dimH_singleton`）；**空集零维**（`dimH_empty`）；
4. $\mathbb R^n$ 中有内点的集合维数为 $n$
   （`Real.dimH_of_nonempty_interior`）——光滑对象回到欧氏维数；
5. **Lipschitz 不变**：$f$ Lipschitz 则 $\dim_Hf(E)\le\dim_HE$ ——
   维数在双 Lipschitz 变换下不变，是"分形"的真正不变量。

## 57.6 Cantor 集的完整账

现在兑现本章开头的承诺：$\dim_HC=\log2/\log3$ 。Cantor 集 $C$
（第 05 章、mathlib `cantorSet`）第 $n$ 阶近似 $C_n$ 是 $2^n$ 个长
$3^{-n}$ 的闭区间之并。

**上界（覆盖账）**：用 $C_n$ 的 $2^n$ 段作覆盖（直径 $\le3^{-n}$ ，
$\delta=3^{-n}$ 足够）：

$$\mu H[s](C)\ \le\ \lim_{n\to\infty}2^n\cdot(3^{-n})^s=\lim_{n\to\infty}\big(2\cdot 3^{-s}\big)^n .$$

当 $2\cdot3^{-s}<1$ 即 $s>\log2/\log3$ 时右边趋于 $0$ ，故
$\mu H[s](C)=0$ ，$\dim_HC\le\log2/\log3$ 。

**下界（质量分布原理）**：在第 05 章造过 Cantor 分布 $\nu$ ——每个
第 $n$ 阶区间（长 $3^{-n}$ ）恰有质量 $2^{-n}$ 。若能找到常数 $c$
使每个区间 $I$ 满足 $\nu(C\cap I)\le c\cdot d(I)^s$ ，则任何覆盖
$\{C_i\}$ 满足

$$1=\nu(C)\le\sum_i\nu(C\cap C_i)\le c\sum_i d(C_i)^s\ \Longrightarrow\ \mu H[s](C)\ge 1/c>0 .$$

对 $s<\log2/\log3$ ：任取区间 $I$ ，若 $I$ 与某个第 $n$ 阶区间 $J$
相交（$n$ 取到使 $3^{-n}\le d(I)<3^{-(n-1)}$ ），则 $I$ 至多跨 $2$
个相邻的 $n+1$ 阶区间... 仔细的账给出 $\nu(C\cap I)\le 2^{-n+1}\le
2\,(3^{-(n+1)})^s\cdot$常数，整理后 $c<\infty$ 当且仅当
$2^{-n}\lesssim(3^{-n})^s$ ，即 $s\le\log2/\log3$ 。于是
$\dim_HC\ge\log2/\log3$ ，两端夹出**精确等式**。

本章机器通道不模拟极限，而是用**整数证书**把维数夹逼：

- 取 $s=3/5$ ：$2^n\le 3^{3n/5}\iff 2^5\le 3^3$ ？—— $32>27$ ，
  否。反向：$2^{-n}\le 3^{-3n/5}\iff 27\le32$ 成立，故质量分布
  原理的常数取 $c=1$ 就通过，$\mu H[3/5](C)>0$ ；
- 取 $s=7/10$ ：$2\cdot3^{-7/10}<1\iff 2^{10}<3^7$ ？—— $1024<2187$
  成立，故覆盖账 $2^n(3^{-n})^{7/10}=(2^{10}/3^7)^{n/10}\to0$ ，
  $\mu H[7/10](C)=0$ 。

$$\boxed{\ \frac35\ <\ \dim_HC\ \le\ \frac7{10},\qquad \dim_HC=\frac{\log2}{\log3}\approx0.6309\ }$$

全部证书只用到两个整数不等式 $27<32$ 与 $1024<2187$ ——机器通道
把它们判成精确等式（Python `Fraction` / Julia `//` / Prolog `rdiv`），
不浮点、不模拟。这是"渐近定理的有限证书"方法的又一次演练（同第
56 章 LIL 的包络账）。

## 57.7 填充测度：维数的上界对偶

Hausdorff 测度从**覆盖**（外逼近）计账。对偶的想法是从**填充**
（内部互不相交的球族）计账——它给出集合"占领空间能力"的上侧度量
（Tricot 1982）。

**填充预测度**（定义 1.5.4 后半）：

$$\varphi\text{-}P_0(E)=\lim_{\delta\downarrow0}\ \sup\Big\{\sum_i\varphi\big(d(B_i)\big):\ \{B_i\}\ \text{球心在}\ E\ \text{中}、\text{半径}\le\delta\ \text{的两两不交球族}\Big\}.$$

球心必须在 $E$ 里，不交性逼着球族"散布"在 $E$ 上——$\sup$ 选出
最会占地的摆法。$\varphi$-$P_0$ 只是预测度（一般不可次可加），再
用定理 1.5.1 正则化一次：

$$\varphi\text{-}P(E)=\inf\Big\{\sum_i \varphi\text{-}P_0(E_i):\ E\subseteq\bigcup_iE_i\Big\}$$

得到**填充测度**。胡书注 1.5.4 记录关键的两侧关系：

$$\varphi\text{-}m(E)\ \le\ \varphi\text{-}P(E)\qquad(\forall E,\ \forall\varphi)$$

——覆盖账永远不超过填充账（覆盖可以取"最优分工"，填充受不交性
约束），对偶地得到维数不等式

$$\dim_HE\ \le\ \dim_PE .$$

两个维数可以严格分离。经典例子（Tricot）：$E=\{1/n:n\ge1\}\cup\{0\}$
可数，$\dim_HE=0$ ；但填充维数 $\dim_PE=1/2$ ——不相交球的摆法
要利用点的间距 $1/n-1/(n+1)\approx1/n^2$ ，在尺度 $\delta$ 附近
能摆 $\approx\delta^{-1/2}$ 个球，恰好半维。**同一个集合，覆盖侧
看见可数的贫瘠，填充侧看见间距的丰饶**——维数不是一个数，而是一
对数。

盒计数维数（数值工作里的标准代理）介于两者之间：
$\dim_H\le\underline{\dim}_B\le\overline{\dim}_B\le\dim_P$ ，对"正则"
分形（如 Cantor 集）全部相等，于是数值斜率 $\log N(\varepsilon)/\log(1/\varepsilon)$
才能合法代言 Hausdorff 维数——本章 Julia 通道的盒计数实验正是
依赖这层夹逼。

## 57.8 机器通道

### 57.8.1 Lean：`dimH` 的 API 与可数集维数零

mathlib 的 Hausdorff 机器在 `MeasureTheory.Measure.Hausdorff`
（测度 $\mu H[s]$，`mkMetric` 双层构造即 57.4 的直译）与
`Topology.MetricSpace.HausdorffDimension`（`dimH` 及其性质）。
本章 Lean 示例锚定关键 API 并完整证明两件事：**可数集维数为零**
（`dimH_singleton` + `dimH_iUnion` 的组合——正是"不可数才可能有
正维数"的机器版）与**有内点集维数为全维**（`Real.dimH_of_nonempty_
interior`，区间 $[0,1]$ 的维数为 1 ）。零或顶二分法
（`hausdorffMeasure_zero_or_top`）作为定理锚点登记——它是 57.5
相变论证的机器化身。Cantor 集本身的维数等式 mathlib 未收录，按
通道分工纪律交给精确证书通道，不硬造形式化。

### 57.8.2 Julia：盒计数斜率与覆盖账

三个确定性实验（无随机）：其一，Cantor 阶段集 $C_n$ 的盒计数
$N(\varepsilon=3^{-n})=2^n$ ，斜率序列 $\log_3 2^n/n\to\log2/\log3$ ，
10 个数量级的账一次打表；其二，覆盖账 $2^n(3^{-n})^s$ 在
$s\in\{0.5,\,0.6309,\,0.7\}$ 三档的走向（发散 / 临界 / 衰减到零）；
其三，阶段集上的填充预测度：贪心摆不交球，对
$s$ 求和，与覆盖侧并排打印——`φ-m ≤ φ-P` 的数值对照。

### 57.8.3 Python：整数证书的精确夹逼

`Fraction` 全程：$27<32$ 与 $1024<2187$ 两个整数不等式驱动
$\mu H[3/5](C)\ge1$ （质量分布常数 $c=1$ 的逐阶段验证：每个第 $n$
阶区间 $\nu=2^{-n}\le(3^{-n})^{3/5}$ ）与 $\mu H[7/10](C)=0$
（覆盖和 $(2^{10}/3^7)^{n/10}$ 的精确指数衰减）。Tricot 集
$\{1/n\}$ 的盒维数有限截断斜率一并向 $1/2$ 对账。

### 57.8.4 Prolog：Cantor 地址树与填充穷举

Cantor 集的地址表示（0/2 三进制数字串）天然是 Prolog 列表：递归
谓词把地址翻译成区间端点（`rdiv` 精确），验证每阶段 $2^k$ 段、
总长 $(2/3)^k$ ；成员判定（有限深度）；最后在阶段 2 的 8 点集上
**穷举**互不相交球族的全部极大摆法，验证填充预测度的 sup 值——
"sup-inf 双层构造"在 8 个点的世界里被完全展开。

## 57.9 要点回顾

1. 预测度 → 外测度的一般机器（定理 1.5.1/1.5.2）= inf 覆盖账
   + sup 保持；对角线 $\varepsilon2^{-i}$ 技巧贯穿全书。
2. 夹逼版 Carathéodory 判据与第 04 章补集版等价，适配无限测度。
3. Hausdorff 测度 $=\sup_\delta\inf$ 双层构造；幂次 $s$ 是称量
   尺度，$H^n$ 与 Lebesgue 差常数，非整数幂全是新测度。
4. 零或顶二分法定义维数相变点；维数单调、可数稳定、Lipschitz
   不变；可数集维数为零。
5. Cantor 集维数 $\log2/\log3$：覆盖账给上界、质量分布原理给
   下界；整数证书 $27<32$ 、$1024<2187$ 把它夹在 $(3/5,\,7/10]$。
6. 填充测度从互不相交球族计账，$\varphi$-$m\le\varphi$-$P$ ，
   $\dim_H\le\dim_P$ ；$\{1/n\}$ 是两侧分离的经典标本。
7. 盒计数维数夹在两者之间——数值代理的合法性来自这层不等式链。

*对应示例（可选）：`examples/lean/Measuretheory/Ch57Hausdorff.lean`、
`examples/julia/57_hausdorff.jl`、`examples/python/57_hausdorff.py`、
`examples/prolog/57_hausdorff.pl`。*

---

上一章：[56 重对数律](56-lll.md) · 下一章：[58 测度的导数：Lebesgue 微分定理、有界变差与绝对连续](58-differentiation.md)
