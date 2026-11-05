# 60 布朗运动：构造、反射与重对数律

**对应胡晓予《高等概率论》§8.2（pp. 166-168，含 §8.3 前半的 Fourier
构造）。数学上接第 59 章（随机游动极限）、第 21 章（相容性定理）、
第 47 章（Gauss 测度）与第 56 章（重对数律）。**

---

## 60.1 从格子到直线：$\sqrt n$ 尺度的极限

第 59 章的简单对称游动 $S_n$ 每步方差 1 ，由中心极限定理
$S_n/\sqrt n\Rightarrow N(0,1)$ 。把时间也缩放：令

$$X^{(n)}(t)=\frac{S_{\lfloor nt\rfloor}}{\sqrt n}\qquad(t\in[0,1]),$$

则每个固定 $t$ 有 $X^{(n)}(t)\Rightarrow N(0,t)$ （方差 $\lfloor nt\rfloor/n\to t$ ），
任意有限维向量 $(X^{(n)}(t_1),\dots,X^{(n)}(t_k))$ 联合收敛到协方差
$\min(t_i,t_j)$ 的中心高斯向量（增量独立 + CLT）。**极限过程**——
如果存在——就是布朗运动：连续时间的独立平稳高斯增量。这是一维
Donsker 不变原理的朴素形态（书 §8.2 开篇的推导；完整的不变原理
"$X^{(n)}\Rightarrow B$ 于路径空间"超出本书范围，第 22 章的投影极限
机器给出其测度论骨架）。

物理侧写（Einstein 1905）：微粒位移 $\Delta a$ 在时间 $\Delta t$ 内
的方差 $(\Delta a)^2\propto\Delta t$ ——要极限非退化必须
$\Delta a\sim\sqrt{\Delta t}$ （书 p167 的 $\mathrm{var}D^2(t)$ 计算）。
金融侧写（Bachelier 1900）：价格 = 布朗运动；现代版本把"价格"换成
"对数收益"（几何布朗），是 Black–Scholes 期权定价的动力学地基。

## 60.2 定义与第一性质

**定义 8.2.1** $\{X_t:t\ge0\}$ 是 $(\Omega,\mathcal F,P)$ 上取值于
$\mathbb R$ 的随机过程，若：

1. $X_0=0$ ；
2. 对任意 $0=t_0<t_1<\cdots<t_n$ ，增量 $X_{t_1}-X_{t_0},\dots,
   X_{t_n}-X_{t_{n-1}}$ 独立，且 $X_{t_k}-X_{t_{k-1}}\sim N(0,t_k-t_{k-1})$ ；

则称 $\{X_t\}$ 为（直线上的标准）**布朗运动**（Wiener 过程）。
mathlib 的对应物：`IsPreBrownianReal`（有限维分布正确）加连续轨道
`IsBrownianReal`——把"增量条件"与"协方差条件"打包成
`HasIndepIncrements.isPreBrownianReal_of_hasLaw` 与
`IsGaussianProcess.isPreBrownianReal_of_covariance` 两条等价入口。

**协方差**：$X_t=(X_t-X_s)+X_s$ 与增量独立，故

$$\boxed{\ E[X_sX_t]=\min(s,t)\ }$$

（$s\le t$ 时 $E[X_sX_t]=E[X_s^2]+E[X_s\,E[X_t-X_s\mid X_s]]=s+0$ 。）
协方差决定中心高斯过程的全部有限维分布——于是**布朗运动 = 协方差
核 $\min(s,t)$ 的中心高斯族**，是第 47 章无穷维 Gauss 测度在核
$\min(s,t)$ 下的具体化。三个立即的对称性（mathlib 逐一登记）：

- **镜像**：$-B$ 是布朗运动（`IsBrownianReal.neg`）；
- **尺度**：$c\,B(\cdot/c^2)$ 是布朗运动——等价地
  $B_t\sim t^{1/2}B_1$ （**乘量性质**，书性质 (3)；`smul`）；
- **时间反演**：$t\mapsto t\,B(1/t)$ 是布朗运动（`inv`）——
  $t\to0^+$ 的微观振荡与 $t\to\infty$ 的宏观振荡同构。

## 60.3 存在性的两条路

### 60.3.1 Kolmogorov 相容性 + 连续修正

有限维分布族（协方差 $\min$ 的高斯族）显然相容：边缘积分消掉最后
一个坐标。第 21 章的 Kolmogorov 定理给出乘积空间上的过程
$\{X_t\}$ ，满足一切有限维分布——**pre-Brownian** 。剩下的裂缝：
轨道未必连续。**Kolmogorov 连续性定理**（陈述）：若
$E|X_t-X_s|^\alpha\le C|t-s|^{1+\beta}$ （某 $\alpha,\beta>0$ ），
则存在连续修正。布朗增量 $X_t-X_s\sim N(0,|t-s|)$ 给
$E|X_t-X_s|^4=3|t-s|^2$ （$\alpha=4,\beta=1$ ✓）——修正后得到
**连续轨道的布朗运动**。mathlib 走的就是这条路（`projectiveFamily`
+ 连续性），Wiener 1933 的原始构造。

### 60.3.2 Fourier/Karhunen–Loève 级数：书 §8.3 的构造

胡书的构造更具操作性（式 8.3.2，第 61 章将从同一台机器造出高斯
自由场）。设 $Z_0,X_1,Y_1,\dots$ iid $N(0,1)$ ，令

$$\boxed{\ W(t)=Z_0\,t+\sqrt2\sum_{n=1}^{\infty}\frac{X_n\sin 2\pi nt+Y_n(1-\cos 2\pi nt)}{2\pi n}\ }$$

则 $\{W(t):t\in[0,1]\}$ 是布朗运动。验证协方差：

$$E[W(s)W(t)]=\sum(\text{基函数系数积})=\langle\mathbf 1_{(0,s]},\mathbf 1_{(0,t]}\rangle_{L^2}=\min(s,t),$$

因为指示函数的 Fourier 系数恰是级数中的 $\sin,\cos$ 项，Parseval
等式把协方差折叠成内积——**等距构造**：$W(t)=T(\mathbf 1_{(0,t]})$ ，
$T:L^2[0,1]\to$ 高斯希尔伯特空间是线性等距（第 61 章的主角）。
级数的第 $n$ 项幅度 $\sim1/n$ ，一致收敛 a.s.（径向收敛判别），给出
连续轨道。这条路的算法价值：**截断级数 = 布朗轨道的可控逼近**
（Karhunen–Loève 展开，特征值 $1/(n^2\pi^2)$ 是核 $\min(s,t)$ 的
谱）——本章 Julia 通道直接实现它。

## 60.4 轨道的两副面孔：连续但无处可微

布朗轨道的两个"病态"事实界定了一类全新的函数（书性质 (1)(2)）：

1. **几乎每条轨道连续**（存在性构造的附赠品）；
2. **几乎每条轨道处处不可微**。直觉账：增量方差 $=h$ ，典型幅度
   $\sqrt{h}$ ，差商 $|B_{t+h}-B_t|/h\sim h^{-1/2}\to\infty$ 。
   Paley–Wiener–Zygmund 的严格论证用增量独立与 Borel–Cantelli
   （第 35 章）在可数网格上排除"存在一点可微"。

把两者放在一起看：**连续模恰是 $\sqrt{h}$** ——既不更平滑（可微需要
$O(h)$ ），也不更粗糙（连续）。精确的刻画是两条模定理（书定理
8.2.1/8.2.2，证明引文献 [23]，即第 56 章同源的 LIL 技术）：

$$\limsup_{h\downarrow0}\frac{|B(t+h)-B(t)|}{\sqrt{2h\log\log(1/h)}}=1\qquad\text{a.s.（局部重对数律）}$$

$$\limsup_{h\downarrow0}\ \sup_{t\in[0,1]}\frac{|B(t+h)-B(t)|}{\sqrt{2h\log(1/h)}}=1\qquad\text{a.s.（一致连续模）}$$

与第 56 章的离散 LIL $\limsup S_n/\sqrt{2n\log\log n}=1$ 对读：
分子同源（增量幅度）、分母的 $\log\log$ 换成 $\log(1/h)$ 是因为
**一致上确界**在 $1/h$ 个独立块上取最大——极值把重对数压成单对数。
布朗运动是"把第 56 章的包络律在连续时间里重写一遍"。

## 60.5 强马氏性与反射原理

**强马氏性**（书性质 (4)）：对滤流 $\mathcal F_t=\sigma(B_s,s\le t)$
的停时 $T$ ，过程 $\{\tilde B_t:=B_{T+t}-B_T\}$ 仍是布朗运动，且与
$\mathcal F_T$ 独立。有限步版本就是第 59 章定理 8.1.2 的游动强马氏
性；连续时间需要 $\mathcal F_T$ 的构造与逼近（mathlib 的
`IsPreBrownianReal.indepFun_shift` 是弱马氏版本：平移 $t_0$ 后的
增量过程独立于过去）。

反射原理是强马氏性最锋利的应用。固定水平 $\lambda>0$ ，首中时
$T_\lambda=\inf\{t:B_t=\lambda\}$ 。把 $T_\lambda$ 之后的轨道关于
水平 $\lambda$ 镜像，由对称性与强马氏性，这是一条保持概率的路径
变换：终点在 $\lambda$ 之上的路径与"曾经触到 $\lambda$ 但终点在
$\lambda$ 之下"的路径一一配对。合并成**极大不等式**（书定理
8.2.3，书用 $2^n$ 网格 $A_n\uparrow$ + Lévy 不等式证）：

$$\boxed{\ P\Big(\max_{0\le s\le t}B_s\ge\lambda\Big)=2P(B_t\ge\lambda)\ }$$

直觉账：触顶后对称下落的概率与继续上行各半，触顶事件的概率被
"终值超 $\lambda$"双倍镜像。**推论——首中时分布**：
$\{T_\lambda\le t\}=\{\max_{s\le t}B_s\ge\lambda\}$ ，故

$$P(T_\lambda\le t)=2\Big(1-\Phi(\lambda/\sqrt t)\Big),\qquad
f_{T_\lambda}(t)=\frac{\lambda}{\sqrt{2\pi t^3}}e^{-\lambda^2/(2t)} .$$

$t^{-3/2}$ 的重尾给出一个反直觉的账目：$E[T_\lambda]=\infty$ ——
**必然击中、平均永不到达**（与第 59 章对称游动常返但
$E[T_0^{(\text{回返})}]=\infty$ 同构：$f^{(2k)}\sim k^{-3/2}$ ）。

**反正弦律**（同族推论）：轨道在 $[0,1]$ 内最后一次过零的时刻
$L$ 与停留在正侧的时间比例 $A$ 都服从反正弦分布
$P(A\le x)=\frac2\pi\arcsin\sqrt x$ ——集中在两端：**长期单边霸占
比"公平对半分"更常见**，这是均值回归直觉的著名陷阱（赌徒"该
翻身了"的错觉在数学上恰好相反）。

## 60.6 机器通道

### 60.6.1 Lean：`IsBrownianReal` 的 API 锚点

mathlib 已收录布朗运动（`Probability/BrownianMotion/Basic.lean`），
本章锚定其核心：定义结构（有限维分布 + 连续轨道）、协方差
`covariance_eval`（$=\min(s,t)$ 的正式陈述）、独立增量、弱马氏
`indepFun_shift`、三大对称性（`neg`/`smul` 乘量/`inv` 时间反演）。
反射原理与 LIL 未收录——前者由离散版（Prolog 双射 + Python 精确
计数）承载，后者已在第 56 章由数值包络账承载。

### 60.6.2 Julia：K-L 级数与反射的模拟对账

两线（固定种子）：(1) **Fourier 构造实弹**——截断级数
$W_n(t)=Z_0t+\sqrt2\sum_{k\le n}(X_k\sin 2\pi kt+Y_k(1-\cos 2\pi kt))/(2\pi k)$
在 $n=10,100,1000$ 三档采样 $10^4$ 条轨道，验证
$\widehat{\mathrm{cov}}(W(1/4),W(3/4))\approx\min=1/4$ 、
$\operatorname{var}W(1)\approx1$ 、轨道连续模随 $n$ 收敛；
(2) **反射原理**——网格化布朗（$2^{12}$ 步），经验
$P(\max_{s\le1}B_s\ge\lambda)$ 对比 $2(1-\Phi(\lambda))$ 在
$\lambda\in\{0.5,1,1.5,2\}$ 的四点对账。

### 60.6.3 Python：离散反射原理的精确计数

对称游动上反射原理是**精确组合等式**：$n$ 步路径中

$$\#\{\max_{k\le n}S_k\ge a\}=\#\{S_n\ge a\}+\#\{S_n>a\}$$

（触顶后镜像给出 $\{S_n<a\}\cap\{\text{触顶}\}$ 到 $\{S_n>a\}$ 的
双射）。Python 用 `Fraction` 与二项系数精确核验
$n=4,\dots,16$ 、$a=2,3$ 的所有情形（左端枚举计数或闭式
$\sum_{j\ge a}\binom nj+\sum_{j>a}\binom nj$ ），连续版的原子修正
项（$=a$ 处的 $\binom nj$）单独列账——**布朗版 $2P(B_t\ge\lambda)$
恰是原子消失后的极限**。

### 60.6.4 Prolog：反射双射的路径级验证

$n\le12$ 的全部 $2^n$ 条路径上，Prolog 枚举"触 $a$ 后终点在 $a$
下方"的路径，逐条执行镜像变换（首触 $a$ 后每步取反），验证像恰为
"终点在 $a$ 上方"的路径集合、变换为对合（双射性）——反射原理在
有限世界的**结构性**验证（不只是计数相等，而是映射本身的构造与
可逆性）。

## 60.7 与全书的接口

- 第 21 章：布朗运动是相容性定理最重要的应用；
- 第 47 章：协方差核的谱理论（K-L 展开）是 Gauss 测度的一般机器；
- 第 56 章：离散 LIL 与本章连续 LIL 同技术同包络；
- 第 61 章：等距构造 $W(t)=T(\mathbf 1_{(0,t]})$ 把 $\mathbb R_+$
  换成任意域 $D\subseteq\mathbb R^2$ ，就是高斯自由场。

## 60.8 要点回顾

1. 布朗运动 = 独立平稳高斯增量；协方差 $\min(s,t)$ 决定一切有限
   维分布；镜像/乘量/时间反演三对称。
2. 存在性两路：Kolmogorov 相容性 + 连续性定理（$\alpha=4$ 矩条件）；
   Fourier 级数构造（等距 $T$ + Parseval 折叠协方差）。
3. 轨道连续但处处不可微；连续模精确为 $\sqrt{h}$：局部 LIL 与一致
   连续模分别刻画单点与整体包络（$\log\log$ vs $\log$）。
4. 强马氏性 + 对称 ⇒ 反射原理：$P(\max\ge\lambda)=2P(B_t\ge\lambda)$ ，
   首中时密度 $\lambda t^{-3/2}\varphi(\lambda/\sqrt t)$ ，
   $E[T_\lambda]=\infty$ 。
5. 反正弦律：正侧时长比例 $\mathrm{Beta}(1/2,1/2)$——均值回归
   直觉的反面。
6. 离散反射是精确组合双射（Python/Prolog 完全验证），连续版是其
   无原子极限。

*对应示例（可选）：`examples/lean/Measuretheory/Ch60BrownianMotion.lean`、
`examples/julia/60_brownian_motion.jl`、`examples/python/60_brownian_motion.py`、
`examples/prolog/60_brownian_motion.pl`。*

---

上一章：[59 随机游动与马氏链](59-random-walks.md) · 下一章：[61 高斯自由场](61-gaussian-free-field.md)
