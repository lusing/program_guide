# 58 测度的导数：Lebesgue 微分定理、有界变差与绝对连续

**对应胡晓予《高等概率论》§2.3（pp. 42-46）。数学上紧接第 12 章
（符号测度与 Radon–Nikodym 定理）——本章是 RN 定理在实分析里的全部
兑现。**

---

## 58.1 RN 定理欠我们一个"算法"

第 12 章的 Radon–Nikodym 定理说：$\lambda\ll\mu$ 且 σ-有限时，存在
密度 $f=d\lambda/d\mu$ 。但定理没说**怎么算** $f$ ——它是存在性声明，
像"方程有根"而不像"求根公式"。本章补上求根公式：

$$\frac{d\lambda}{d\mu}(x)=\lim_{r\downarrow0}\frac{\lambda(I_r)}{\mu(I_r)}\qquad(\mu\text{-a.e. }x)$$

其中 $I_r$ 是含 $x$ 、长度（$\mu$-质量）趋于零的区间。**导数 = 局部
质量比的极限**。这是 Newton–Leibniz 公式的测度论形态：对
$\lambda(A)=\int_Af\,dm$ ，上式说 $f(x)=\lim\lambda(I)/m(I)$ ——密度
在几乎每点被局部平均值恢复。

三条应用线索随之兑现：

1. **微积分基本定理的 Lebesgue 版**：$f$ 绝对连续 $\iff$
   $f(x)-f(a)=\int_a^xf'$ （定理 2.3.5）——Riemann 时代"可微 ⟹
   可积回代"只对绝对连续函数成立，Cantor 函数是边界标本；
2. **单调函数几乎处处可微**（定理 2.3.4）：单调性抑制振荡，可微性
   在零测集外免费获得；
3. **密度定理**：集合在自己几乎每点处"密度为 1"——经验分布、核密度
   估计合法性的理论根基。

统计与经济中的落点：直方图/核密度估计是 $\mu(I_r)/m(I_r)$ 的样本版；
"条件期望 = 局部平均"的 dyadic 鞅证明（第 36、42 章）是本章定理的
孪生兄弟。

## 58.2 测度的上、下导数

设 $\mu$ 是 $\mathbb R$ 上的 Lebesgue–Stieltjes 测度（每个有界区间
质量有限），$m$ 为 Lebesgue 测度。对 $a\in\mathbb R$ ，令
$\mathcal G_r(a)=\{C\ni a: C$ 开区间，$m(C)\le r\}$ ，定义（书式
2.3.1）：

$$\bar D\mu(a)=\lim_{r\downarrow0}\ \sup_{C\in\mathcal G_r(a)}\frac{\mu(C)}{m(C)},\qquad \underline D\mu(a)=\lim_{r\downarrow0}\ \inf_{C\in\mathcal G_r(a)}\frac{\mu(C)}{m(C)} .$$

sup 与 inf 随 $r$ 单调（$\mathcal G_r$ 缩小），极限总存在
（$\underline D\le\bar D$ ）。若两者相等且有限，称 $\mu$ 在 $a$
**可微**，记公共值为 $D\mu(a)$ 。

为什么用"任意含 $a$ 的区间"而不是对称球？一维区间有方向，上导数
捕捉最坏的逼近方向——这让"几乎处处可微"更强也更难，覆盖引理必须
顶上（58.3）。高维时改用球或方体，Besicovitch 覆盖接替 5R 引理
（58.7）。

## 58.3 覆盖引理：唯一的引擎

**5-区间引理（书式 2.3.2 的选择程序）** 设 $C_1,\dots,C_n$ 是开区间，
按长度不增排列：$m(C_{i+1})\ge m(C_i)$ 。贪心地取 $i_1=1$ ，
$i_s=\inf\{k>i_{s-1}: C_k$ 与 $C_{i_1}\cup\cdots\cup C_{i_{s-1}}$
不相交$\}$ ，得到两两不交子族 $\{C_{i_1},\dots,C_{i_t}\}$ 。则每个
$C_j$ 落在某个选出的 $C_{i_s}$ 的**3 倍膨胀**里：

$$C_j\subseteq B_s:=3\,m(C_{i_s})\text{ 长的同心开区间},\qquad \text{且}\ m(C_{i_s})\ge m(C_j).$$

证明只有一行的几何：取最小的 $s$ 使 $i_s>j$ （即 $C_j$ 与
$C_{i_{s-1}}$ 之前的并相交——否则 $j$ 自己会被选中）；由长度排序
$m(C_{i_s})\ge m(C_{j'})\ge$ 与 $C_j$ 相交的更长区间... 直接的包含
论证给出 $C_j\subseteq B_s$ 。**推论**（本书反复使用的形状）：

$$m\Big(\bigcup_{j\le n}C_j\Big)\ \le\ \sum_s 3\,m(C_{i_s})\ \le\ \frac{3}{a}\sum_s\mu(C_{i_s})\ \le\ \frac{3}{a}\,\mu\Big(\bigcup_j C_j\big),$$

第三个不等号用了不交性与单调性（把每个 $C_{i_s}$ 扩大成 3 倍后
$\mu(B_s)\le3\mu(C_{i_s})$ 在 $\mu=m$ 的长度账里精确；对一般测度
$\mu(B_s)\le 3\mu(\text{3 倍壳})$ 需要一点平移论证——书 p43 直接在
长度侧使用）。**覆盖引理把"局部比值大"翻译成"整体质量大"**——
这是本章所有归谬法论证的传动装置。

## 58.4 三个定理：从奇异到导数

### 58.4.1 奇异部分导数为零

**引理 2.3.1** $\mu(A)=0$ （$A$ 有界 Borel）$\Rightarrow$ 在 $A$
上 $\bar D\mu<a$ 对 $m$-几乎处处的 $a$ 成立（任意 $a>0$ ），从而
$\bar D\mu=0$ $m$-a.e. 于 $A$ 。

证明是 58.3 的直接应用：$T=\{a\in A:\bar D\mu(a)>a\}$ （$a>0$ 为
阈值），紧子集 $K\subseteq T$ 被有限个"坏区间"（$\mu(C)>a\cdot m(C)$ ，
$m(C)<r$ ）覆盖，5R 引理选出不交子族，则

$$m(K)\le\sum_s3m(C_{i_s})\le\frac{3}{a}\mu(K_r)\le\frac{3}{a}\mu(A)=0 .$$

内正则性（$m$ 的逼近，第 25 章）把 $m(T)=0$ 从紧子集上传到全 set。
**直觉**：$\mu$ 在 $A$ 上没有质量，若 $\mu/m$ 在 $A$ 的一片正 $m$-测度
区域上比值超过 $a$ ，覆盖账就会逼出 $\mu(A)\ge a\cdot m/3>0$ ——矛盾。

mathlib 的对应物：`MeasureTheory.ae_eventually_measure_zero_of_singular`
（$\rho\perp\mu\Rightarrow$ 密度比趋于 0 a.e.）。

### 58.4.2 导数的存在与识别

**定理 2.3.1** $\mu$ 是 $\mathbb R$ 上的 L-S 测度且 $|\mu|$ σ-有限，
则 $D\mu$ 关于 $m$ 几乎处处存在，且

$$D\mu=\frac{d\mu_{ac}}{dm}\qquad(m\text{-a.e.}),$$

其中 $\mu_{ac}$ 是 Lebesgue 分解（第 12 章定理）中绝对连续的部分。

证明组装：$\mu=\mu_1+\mu_2$ ，$\mu_1\ll m$ 有密度 $g$ ，
$\mu_2$ 集中在 $m$-零集 $A$ 上。$\mu_2$ 部分由引理 2.3.1 清零。绝对
连续部分证两条不等式：$\bar D\mu_1\le g$ 与 $\underline D\mu_1\ge g$
（a.e.）。前者的证明是**有理数阈值扫描**：$E_a=\{x:g(x)<a<\bar D\mu_1(x)\}$
必须 $m$-零集（用 5R 引理 + 在 $g<a$ 的区域上 $\mu_1$ 的质量被
$a\cdot m$ 控制），对所有有理 $a$ 取并。后者以 $-\mu_1,-g$ 代入。
这套"有理阈值 + 可数并"的扫描技术同 Fatou 引理的证明（第 11 章）
是一个模子。

### 58.4.3 分布函数的绝对连续性

**定义 2.3.1** $f:[a,b]\to\mathbb R$ **绝对连续**（AC），若对任意
$\varepsilon>0$ 存在 $\delta>0$ ：任何有限个不相交子区间
$(a_i,b_i)$ 只要 $\sum(b_i-a_i)\le\delta$ 就有
$\sum|f(b_i)-f(a_i)|\le\varepsilon$ 。

AC 显然强于连续（取 $n=1$ ）；它说的是**总扰动控制总波动**——
$f$ 把零测集映成零测集（把"长度小"翻译成"振幅小"的可数版）。

**定理 2.3.2** $f$ 是 $[a,b]$ 上的分布函数，$\mu_f$ 为对应 L-S 测度，
则 $\ \mu_f\ll m\iff f$ 绝对连续。

方向一用第 12 章命题 2.2.2（$\lambda\ll\mu\iff\lambda(A)\to0$ 当
$\mu(A)\to0$ ，即**ε-δ 化的绝对连续**）；方向二反证 + 开集分解为
不交区间并（每个有界开集是可数不交开区间之并——第 05 章的账）。
**RN 定理与 AC 函数从此互为字典**：

$$\mu_f\ll m\ \Longleftrightarrow\ f\ \text{AC}\ \Longleftrightarrow\ f(x)=f(a)+\int_a^x g\,dm .$$

## 58.5 有界变差与 Jordan 分解

**变差**：对分割 $P:a=t_0<\cdots<t_n=b$ ，
$V(P)=\sum|f(t_i)-f(t_{i-1})|$ ，全变差 $V_f(a,b)=\sup_PV(P)$ 。
$V_f<\infty$ 称**有界变差**（BV）。立即的可加性：$V_f(a,b)=V_f(a,c)+V_f(c,b)$ 。

**引理 2.3.2（Jordan 分解）** $f$ BV $\Rightarrow$ $f=H-G$ ，其中
$H(x)=V_f(a,x)$ 单调增，$G=H-f$ 也单调增。$f$ AC 时 $H,G$ 可取成
AC 单调函数（用 AC 的 $\varepsilon$-$\delta$ 账逐段加总）。
BV = 两个单调函数之差——**振荡被单调性吸收**。

**定理 2.3.3** AC $\Rightarrow$ BV 。证明是把 AC 的 $\delta$ 取成
$(b-a)/M$ 的整分格：任何分割的变差不超过 $M$ 个"半格段"的振幅和，
每段 $\le\varepsilon$ ，总变差 $\le M\varepsilon$ 。注意**逆命题
不成立**：Cantor 函数连续、BV（$V=1$ ）、非常数，却不 AC（58.6）。

**定理 2.3.4（Lebesgue）** BV 函数（特别地，单调函数）在 $[a,b]$
上关于 $m$ 几乎处处可微，且 $f'=D\mu_f$ a.e.。

证明的巧妙处：把"函数的差商"换成"测度的区间比"。对单调 $f$ ，
$\mu_f$ 是 L-S 测度，定理 2.3.1 给出 $D\mu_f=g$ a.e. ；再证
$f'(a)=D\mu_f(a)$ 在 $f$ 的连续点（单调函数至多可数个间断——第 05
章）成立：若差商沿子列偏离 $c=D\mu_f(a)$ ，对称化区间
$(a-k_n,a+h_n)$ 的质量比也偏离（书式 2.3.4），矛盾。**单调函数的
可微性是测度导数的改装**——这就是把分析问题翻译进测度论的收益。

## 58.6 微积分基本定理：Lebesgue 版

**定理 2.3.5** $f$ 在 $[a,b]$ 上绝对连续 $\iff$

$$f(x)-f(a)=\int_a^xf'(t)\,dm(t)\qquad\forall x\in[a,b].$$

（$\Leftarrow$ 由积分的绝对连续性（第 10 章）直接给出；$\Rightarrow$
组装已备零件：AC ⟹ $\mu_f\ll m$（定理 2.3.2）⟹ $\mu_f=g\,dm$ 且
$f'=g$ a.e.（定理 2.3.4 与 2.3.1）⟹ 积分表示。）

**Cantor 函数的判决**：$F$ = Cantor 阶梯连续、$V_F=1$ 、$F'=0$
a.e.（支撑集零测，导数在余集——开集——上为零）。若 $F$ AC 则
$F(x)-F(0)=\int F'=0$ ，但 $F(1)-F(0)=1$ 。矛盾。于是：

| 性质 | 单调 | BV | 连续 | AC |
|---|---|---|---|---|
| ⟹ 几乎处处可微 | ✓（定理 2.3.4） | ✓ | ✗（Weierstrass 函数） | ✓ |
| ⟹ 牛顿–莱布尼茨 | ✗（Cantor 阶梯） | ✗ | ✗ | ✓（定理 2.3.5） |
| ⟹ 映零测为零测 | ✗（Cantor 阶梯映零测集到正测集） | ✗ | ✗ | ✓ |

第一行第三列的 Weierstrass 处处不可微函数与第 57 章 Hausdorff 维数
（其图像维数 $\ge1$ ，对三角级数 $>\,1$ ）连成一条"病态函数"风景线；
第二行的失败者全部由 Cantor 阶梯统一示范——它是本章的"万能反例"。

## 58.7 密度定理与函数版：一般度量空间

一维区间的角色在度量空间里由球担任，5R 引理由 **Vitali 覆盖定理**
（存在不交球族覆盖到剩余零测）或 **Besicovitch 覆盖定理**（有界重数
的不交分解）接替。mathlib 在 `MeasureTheory.Covering` 里实现了完整
机器，三个定理直接可用作锚点：

- **Lebesgue 密度定理**（`ae_tendsto_measure_inter_div`）：σ-紧度量
  空间上，对 $m$-a.e. $x\in S$ ，

$$\frac{m(S\cap B(x,r))}{m(B(x,r))}\longrightarrow1\qquad(r\downarrow0).$$

  几乎每点都是所在集合的"密度点"。经验分布语境：样本落在固定邻域的
  频率 → 该点的局部密度——直方图收敛的理论骨架。

- **Lebesgue 微分定理**（`ae_tendsto_average_norm_sub`）：局部可积
  $f$ 在 a.e. $x$ 处，

$$\frac{1}{m(B(x,r))}\int_{B(x,r)}|f(y)-f(x)|\,dm(y)\longrightarrow0 .$$

  平均值把函数值"洗回"原点值。Hardy–Littlewood 极大函数（第 48 章
  工具箱）控制收敛的速度与失败的集合大小。

- **鞅证明的预告**：把 $B(x,r)$ 换成包含 $x$ 的 dyadic 方体，平均值
  序列恰是条件期望链 $E[f\mid\mathcal F_n]$ （$\mathcal F_n$ =
  dyadic σ-代数）——Lévy 鞅收敛定理（第 42 章）给出另一条证明路。
  "局部平均 = 条件期望"是概率论与实分析的又一座双向桥。

## 58.8 机器通道

### 58.8.1 Lean：mathlib 三锚点 + 反例的精确侧影

登记 `ae_tendsto_measure_inter_div`（密度定理）、
`ae_tendsto_average_norm_sub`（微分定理）、
`ae_eventually_measure_zero_of_singular`（引理 2.3.1 的一般形式）
三个定理名，并证两条精确侧影：其一，**区间账的可加侧影**——L-S
测度在区间上的账 $\mu(a,b]=F(b)-F(a)$ 与微分定理的一致性（对阶梯
$F$ ，在跳点处导数密度是原子，区间比值收敛到原子质量——有限空间上
用 `Fraction` 型精确判决）；其二，**Cantor 阶梯的牛顿–莱布尼茨
失败账**：$F(1)-F(0)=1$ 与 $\int F'=0$ 的不等——数值侧影交给计算
通道，Lean 侧登记结构。

### 58.8.2 Julia：局部比值的三张表

固定网格上的确定性三表：(1) 混合测度 $\mu=\tfrac12m+\tfrac12\nu_C$
（$\nu_C$ = Cantor 测度）在**缺口中点**的比值恒为 $1/2$ （精确），
在 Cantor 端点 0 处沿 $r=3^{-n}$ 的比值为 $\tfrac12(1+(3/2)^n)$
发散——奇异部分的上导数无穷（$\nu_C$-典型点局部维数 $\log2/\log3<1$
的直接体现）；(2) 密度定理：$S=[0,1/3]$ 在内点处密度比 → 1 ，在
边界 $1/3$ 处 → 1/2 ；(3) 变差账：分段线性函数的 $V(P)$ 在加密分割
下的收敛，与转折点求和公式对账。

### 58.8.3 Python：Fraction 下的精确比值

混合测度在缺口的比值**精确等于** 1/2（缺口区间 $\nu_C$ 质量为零，
`Fraction` 判决）；端点 0 的比值序列 $\tfrac12+\tfrac12(3/2)^n$ 用
精确分数表出并判发散（相邻比恒 3/2）；Cantor 阶梯 $F$ 在第 $n$ 阶
区间端点的取值 $k/2^n$ 精确生成，验证 $F'=0$ 侧影（余集为开集稠密
并）与 $F(1)-F(0)=1\ne0=\int F'$ 的失败判决。

### 58.8.4 Prolog：贪心覆盖与变差穷举

5R 引理的贪心程序完全可判定化：给定按长度排序的区间表，选择程序
每步取"下一个与已选不交者"，穷举验证两件事——已选族两两不交、
每个未选区间被某已选区间的 3 倍膨胀包含（对 $n\le6$ 的全部随机
排列逐一检查）。变差侧：给定 7 点采样函数值，穷举全部 $2^5$ 个
分割，验证 $V$ 的上确界在"转折点分割"处取得——Jordan 分解的有限
投影。

## 58.9 要点回顾

1. 测度导数 = 局部质量比极限；RN 密度被局部平均恢复——RN 定理的
   "求根公式"。
2. 5-区间覆盖引理是唯一引擎：贪心不交子族 + 3 倍膨胀，把"局部
   比值大"翻译成"整体质量矛盾"。
3. 引理 2.3.1：$\mu(A)=0\Rightarrow\bar D\mu=0$ 于 $A$ （$m$-a.e.）；
   定理 2.3.1：$D\mu=d\mu_{ac}/dm$ a.e. ——奇异部分对 $m$-导数
   不可见。
4. $\mu_f\ll m\iff f$ 绝对连续——测度语言与函数语言的字典。
5. BV = 单调差（Jordan）；AC ⟹ BV ⟹ a.e. 可微；反向全不成立，
   Cantor 阶梯是统一反例。
6. 牛顿–莱布尼茨的 Lebesgue 版：$f$ AC $\iff f(x)-f(a)=\int f'$ 。
7. 密度定理与微分定理在一般度量空间由 Vitali/Besicovitch 覆盖
   支撑；dyadic 平均 = 条件期望，给出鞅证明的第二条路。

*对应示例（可选）：`examples/lean/Measuretheory/Ch58Differentiation.lean`、
`examples/julia/58_differentiation.jl`、`examples/python/58_differentiation.py`、
`examples/prolog/58_differentiation.pl`。*

---

上一章：[57 Hausdorff 测度、填充测度与分形维数](57-hausdorff-packing.md) · 下一章：[59 随机游动与马氏链](59-random-walks.md)
