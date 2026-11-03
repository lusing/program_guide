# 95 · 0# 与 Silver 不可辨别元

> 第 94 章证明了：非平凡初等嵌入 $j:V\to M$ 的临界点 $\kappa$
> 在 $L$ 中连拉姆齐基数都不是（Scott 定理的强化方向）。本章取材
> 冯琦第三卷 §1.1.2（书页 24–54；PDF 44–74），沿主线重建这条理论：
> $j:V\to M$ 限制出非平凡的 $j\upharpoonright L:L\to L$（引理 1.7）；
> 这样的自嵌入迫使某个 $(L_\lambda,E)$ 携带**不可数不可辨别元集合**
> （Kunen 构造，定理 1.13）；反过来，拉姆齐基数为任意结构供给不可
> 辨别元（定理 1.14），EM 蓝图把「不可辨别元的真相」压缩成一个自然
> 数集——**0#**；Silver 定理（定理 1.16）说明蓝图唯一，且全部不可数
> 基数都成为 $L$ 的 Silver 不可辨别元。四条等价（定理 1.17）与
> $a\#$ 的相对化完成整个理论。
>
> 一处精细账预先声明：引理 1.12/1.13 中「$M_\alpha$ 在临界点之下
> 的序数经坍缩逐点归位」的记账（书页 30–33）是全章最细的一步，本文
> 给出引擎级的完整证明（$X$-阶梯的逐点固定，95.6）与机制讲解，其余
> 按原书骨架陈述并明确标注。机器通道只承担有限影子：有限染色的齐一
> 集（$R(3,3)=6$，定理 1.14 的有限前身）、不可辨别元的封闭律与
> 平移不变性（定理 1.17 (3)→(1) 的构造种子）；0# 本体是关于
> $(L_{\aleph_\omega},E,\aleph_1,\aleph_2,\ldots)$ 的真实理论，
> 不可机化。

## 95.1 从 $j:V\to M$ 到 $j\upharpoonright L:L\to L$（引理 1.7）

第 94 章的分解定理说明 $j:V\to M$ 给出 $V\ne L\ne M\ne V$。但
$L$ 是**对一切传递类绝对的**最小内模型，于是出现一个漂亮的挤压：

> **引理 1.7** 若 $j:V\to M$ 非平凡初等，则
> $j\upharpoonright L:L\to L$ 非平凡初等。

**证明**。$M$ 是 ZFC 的传递真类模型，故 $M$ 自己算出的可构造
宇宙满足 $(L)^M=L$（最小内模型定理：$L$ 的层级定义对传递类
绝对，且 $M$ 含全体序数）。于是对每个公式 $\varphi$ 与
$\vec a\in L$：

$$
L\models\varphi[\vec a]
\ \Longleftrightarrow\ V\models\varphi^{L}[\vec a]
\ \Longleftrightarrow\ M\models\varphi^{(L)^M}[j\vec a]
\ \Longleftrightarrow\ L\models\varphi[j\vec a],
$$

第一个与第三个等号分别是「$L$ 的定义在 $V$ 与 $M$ 中展开
相同」，中间的等号是 $j$ 的初等性。所以限制映射保持一切一阶
性质；又 $j(\kappa)>\kappa=\operatorname{Crit}(j)$ 且
$\kappa\in L$，限制非平凡。∎

于是 $\kappa$ 上有一切 $L$-内的大基数性质的**下界**问题：由
引理 1.9（95.3）$\kappa$ 在 $L$ 中不可数、正则；由弱紧性质的
继承（第二卷定理 II.2.16）$\kappa$ 在 $L$ 中弱紧；但本章末尾将
看到 $\kappa$ 在 $L$ 中连拉姆齐都不是——不可辨别元理论给出的
精确刻度。

## 95.2 可定义斯科伦函数与交换引理（定义 1.6、引理 1.8）

要把「初等」翻译成「函数」的语言，需要 $L$ 自带的秩序。哥德尔
定理（第一卷定理 I.2.9）给出一个 $\Sigma_1$ 表达式
$\Phi(v_0,v_1)$，在 $L$ 中定义良序 $<_L$：对极限序数
$\alpha>\omega$ 与 $x,y\in L_\alpha$，

$$
x<_L y \iff (L_\alpha,E)\models\Phi[x,y].
$$

> **定义 1.6（典型斯科伦项）** 对每个表达式
> $\beta(v_0,v_1,\ldots,v_n)$，定义典型斯科伦项
> $t_\beta$ 为「在 $<_L$ 下最小的见证」：

$$
t_\beta(v_0,v_1,\ldots,v_n) =
\min{}_{<_L}\{v_0 : \beta(v_0,v_1,\ldots,v_n)\}.
$$

斯科伦项的集合可数、对复合封闭，因此在任何携带 $<_L$ 的结构
$(M,E)$ 中解释为**完备**斯科伦函数集：由 $X\subseteq M$ 生成
的同质子模型是

$$
\mathrm{SH}^{(M,E)}(X)=\{t^{(M,E)}(c_1,\ldots,c_n) :
t\text{ 斯科伦项},\ c_1,\ldots,c_n\in X\}.
$$

> **引理 1.8（交换性）** 设 $k:L_\alpha\to L_\beta$ 非平凡初等
> （$\omega<\alpha<\beta$ 极限），$t$ 是典型斯科伦项。则对
> $\vec a\in L_\alpha$：

$$
t^{L_\beta}(k(a_1),\ldots,k(a_n)) = k\big(t^{L_\alpha}(a_1,\ldots,a_n)\big).
$$

**证明**。$k$ 初等，故 $L_\alpha\models\beta[y,\vec a]$ 当且
仅当 $L_\beta\models\beta[k(y),k\vec a]$；候选集互相对应。又
$<_L$ 由 $\Sigma_1$ 公式 $\Phi$ 定义而 $k$ 初等，最小元的
像是最小元的像。两边是同一个最小见证。∎

于是把斯科伦项符号添进语言后，初等映射仍是增添结构的初等映射。
这是后文一切构造的语法基础。

## 95.3 $M$-超滤子与 $L$-超幂（定义 1.7、引理 1.9、引理 1.10）

$j\upharpoonright L$ 若存在，绝不能是 $L$ 的可定义类（否则
$L$ 能看见它，与后面推出的一切矛盾）。为谈论「外部」的滤子：

> **定义 1.7（$M$-超滤子）** $M\models\mathrm{ZFC}$ 传递，
> $\kappa\in M$ 是 $M$ 中的无穷基数。$D\subseteq(\mathcal P(\kappa))^M$ 是 $\kappa$ 上的 $M$-超滤子，若：
> (a) $\kappa\in D$、$\varnothing\notin D$；(b) 对交封闭；
> (c) $X\in D$、$Y\in M$、$X\subseteq Y\subseteq\kappa$ 时
> $Y\in D$；(d) 对 $M$ 中的子集二分其一。
> **非平凡**：$([\kappa]^{<\kappa})^M\cap D=\varnothing$；
> **$\kappa$-完全**：$M$ 中 $<\kappa$ 个 $D$-元的交仍在
> $D$；**正规**：$M$ 中定义在某个 $X\in D$ 上的选择函数在
> 某个 $Y\in D$ 上恒常。

与第 94 章定义 1.4 逐条对照：唯一的新意是「只在 $M$ 的成员上
说话」。

> **引理 1.9** (1) $j:L\to L$ 非平凡、$\kappa=\mathrm{Crit}(j)$
> 时，
> $$
> D=\{X\subseteq\kappa : X\in L\wedge\kappa\in j(X)\}
> $$
>
> 是非平凡 $\kappa$-完全正规 $L$-超滤子，且 $\kappa$ 在
> $L$ 中不可数、正则。
> (2) 对任意传递模型间的 $j:M\to N$ 同样成立。

**证明**与第 94 章引理 1.6 完全平行（超滤性、非平凡性、正规性都
用 $j$ 的初等性搬运；$\kappa$-完全性给出 $M$ 中的正则性），
只是每个「子集」前加上「$\in M$」。∎

$M$-超滤子 $D$ 构造超幂 $\mathrm{ult}(M,D)$：$f\equiv^* g$
当且仅当 $\{\alpha<\kappa:f(\alpha)=g(\alpha)\}\in D$，
$[f]\in^*[g]$ 当且仅当 $\{\alpha:f(\alpha)\in g(\alpha)\}\in D$。
Łoś 定理照常成立。**新的危险**：$D\notin M$，超幂的 $\in^*$
未必良基——$D$-完全性只保证 $M$-内部的下降链被斩断，而组合
外部函数仍可能造出 $\in^*$-下降链。若 $D$ 由 $j:M\to N$
导出，则因子映射

$$
k:\mathrm{ult}(M,D)\to N,\qquad k([f])=j(f)(\kappa)
$$

良定义且初等（第 94 章因子嵌入的同一构造），于是 $\in^*$ 的下降
链被 $k$ 搬成 $N$ 内序数的真下降链，矛盾。故：

> **引理 1.10** $j:L\to L$ 非平凡、$D$ 为其导出 $L$-超滤子
> 时，$\mathrm{ult}(L,D)$ 良基，传递化为 $L$，且
> $j=k\circ i$，其中 $i:L\to L$ 是 $L$-超幂嵌入，
> $k:L\to L$ 因子嵌入。∎（练习级的综合，与第 94 章 14 节同构。）

## 95.4 片段升格：从 $k:L_\alpha\to L_\beta$ 到 $j:L\to L$（定理 1.12）

初等自嵌入可能先以**片段**形式出现。$\kappa<|\alpha|$ 这个假设
是升格的全部空间来源：

> **定理 1.12** 若 $k:L_\alpha\to L_\beta$ 非平凡初等，
> $\kappa=\mathrm{Crit}(k)<|\alpha|$，则存在非平凡的
> $j:L\to L$。

**证明**。令 $D=\{X\subseteq\kappa : X\in L\wedge\kappa\in k(X)\}$。
与引理 1.9 同法验证它是非平凡 $\kappa$-完全正规 $L$-超滤子
（这里用到 $\kappa<|\alpha|$：凡 $X\in L$、$X\subseteq\kappa$
则 $X\in L_\alpha$，故 $k(X)$ 可用）。

只需证 $\mathrm{ult}(L,D)$ 良基。反设有下降链
$[f_0]\ni^*[f_1]\ni^*\cdots$，各 $f_n\in L$，即
$A_n:=\{s<\kappa : f_{n+1}(s)\in f_n(s)\}\in D$。取极限序数
$\lambda$ 使诸 $f_n\in L_\lambda$。令
$X=\bigcup_n\operatorname{ran}(f_n)$（可数），取

$$
X\cup\kappa\subseteq M\prec L_\lambda,\qquad |M|=\max(\aleph_0,\kappa)=\kappa.
$$

（生成元取全部 $s<\kappa$，故 $M$ 逐点包含 $\kappa$。）由
凝聚化引理（第一卷定理 I.2.10），传递化 $\pi[M]=L_\eta$，且
$|\eta|=|M|=\kappa<|\alpha|$，从而 $\eta<\alpha$（基数随序数
单调）。令 $g_n=\pi(f_n)\in L_\eta\subseteq L_\alpha$。

关键的两点观察：其一，$\pi$ 逐点固定每个 $s\le\kappa$（它们
全是生成元，且 $f_n(s)\in M$——$M\prec L_\lambda$ 对可定义
运算封闭），故

$$
\{s<\kappa : g_{n+1}(s)\in g_n(s)\}=A_n\in D.
$$

其二，$A_n\in L_\eta'\subseteq L_\alpha$（由 $g$'s 经 $\Delta_0$
定义），故 $k(A_n)$ 有意义且 $\kappa\in k(A_n)$。把 $k$ 应用
到陈述「$\forall s\in A_n\ (g_{n+1}(s)\in g_n(s))$」上：

$$
k(g_{n+1})(\kappa)\in k(g_n)(\kappa)\qquad(n<\omega),
$$

这是传递模型 $L_\beta$ 内序数的无穷 $\in$-下降链，矛盾。∎

## 95.5 不动点引理与 $U$-阶梯（引理 1.11）

> **引理 1.11（不动点引理）** 在引理 1.10 的环境中（$i:L\to L$
> 为 $L$-超滤子 $D$ 诱导的嵌入，$\kappa=\mathrm{Crit}(i)$），
> 若 $\lambda$ 是梯度 $\mathrm{cf}(\lambda)>\kappa$ 的极限基数，
> 则 $i(\lambda)=\lambda$。

**证明**。任取 $f\in L$、$f:\kappa\to\lambda$。因
$\mathrm{cf}(\lambda)>\kappa$，$\operatorname{ran}(f)$ 有界
（此论证在 $V$ 中做即可）。于是每个 $[f]<i(\lambda)$ 的代表
都等价于某个常值函数 $[c_\alpha]$，$\alpha<\lambda$：

$$
i(\lambda)=\sup_{\alpha<\lambda}i(\alpha).
$$

再证每个 $i(\alpha)<\lambda$。$L\models\mathrm{GCH}$，故
$\lambda$ 在 $L$ 中是强极限基数；$i(\alpha)$ 的 $L$-基数
至多 $|\mathcal P(\kappa)\cap L|\le\kappa^+$（$<\lambda$），而
$\alpha<\lambda$ 任意，故 $i(\alpha)<\lambda$。合起来
$i(\lambda)=\sup_{\alpha<\lambda}i(\alpha)\le\lambda$，而
$\ge\lambda$ 由单调性（$i(\alpha)\ge\alpha$）立得。∎

由此铺设阶梯：

$$
U_0=\{\lambda : \lambda\text{ 极限基数且}\ \mathrm{cf}(\lambda)>\kappa\},
\qquad U_{\alpha+1}=\{\lambda\in U_\alpha : |\lambda\cap U_\alpha|=\lambda\},
\qquad U_\delta=\bigcap_{\alpha<\delta}U_\alpha.
$$

**阶梯事实**（本文按下游需要重述原书断言一，证明更短）：

1. 每个 $U_\alpha$（$\alpha<\omega_1$）是 Ord 的无界闭类。
   归纳：$U_0$ 无界闭显然；后继步取 $U_\beta$ 的正则枚举
   $\bar T:\mathrm{Ord}\to U_\beta$，其不动点组成无界闭类且
   含于 $U_{\beta+1}$（不动点 $\lambda$ 满足
   $|\lambda\cap U_\beta|=\bar T^{-1}``\lambda...=\lambda$）；
   极限步取 $<\omega_1$ 个闭无界类之交，仍闭无界。
2. 取 $\lambda\in U_{\omega_1}$。则对**一切** $\alpha<\omega_1$
   有 $\lambda\in U_{\alpha+1}$，从而
   $|\lambda\cap U_\alpha|=\lambda.$

第 2 条正是下游构造的燃料：对每个 $\alpha$，
$X_\alpha:=\lambda\cap U_\alpha$ 是 $\lambda$ 中基数为
$\lambda$、序型为 $\lambda$ 的子集。

## 95.6 Kunen 构造：$(L_\lambda,E)$ 的不可数不可辨别元（断言二、引理 1.12–1.14、定理 1.13）

取定 $\lambda\in U_{\omega_1}$。由引理 1.10 取分解
$j=k\circ i$，$i:L\to L$，$\kappa=\mathrm{Crit}(i)$；由
引理 1.11，$i(\lambda)=\lambda$，故限制

$$
h:=i\upharpoonright L_\lambda : (L_\lambda,E)\to(L_\lambda,E)
$$

是初等自嵌入，且由不动点引理，$h$ **逐点固定**每个
$\eta\in U_0\cap\lambda$（都是梯度 $>\kappa$ 的极限基数），
也固定每个 $\eta<\kappa$（临界点下方不动）。

对每个 $\alpha<\omega_1$，令 $X_\alpha=\lambda\cap U_\alpha$，
取同质子模型及其传递化：

$$
M_\alpha=\mathrm{SH}^{L_\lambda}(\{\kappa\}\cup X_\alpha),\qquad
\pi_\alpha[M_\alpha]=L_\lambda,\qquad
h_\alpha:=\pi_\alpha^{-1}:L_\lambda\to L_\lambda,\qquad
K_\alpha:=h_\alpha(\kappa).
$$

$\pi_\alpha[M_\alpha]=L_\lambda$ 的理由：$\mathrm{Ord}\cap M_\alpha\supseteq X_\alpha$ 且 $\operatorname{otp}(X_\alpha)=\lambda$
（基数为 $\lambda$ 的 $\lambda$ 的子集序型恰为 $\lambda$），
故 $\mathrm{Ord}\cap M_\alpha$ 的序型是 $\lambda$。

**逐点固定引擎（完整证明）**。设 $\alpha<\beta<\omega_1$、
$\eta\in X_\beta$。则 $\eta\in U_\beta\subseteq U_{\alpha+1}$，故
$|\eta\cap U_\alpha|=\eta$；又 $\eta\cap U_\alpha=X_\alpha\cap\eta$，
而 $\mathrm{Ord}\cap M_\alpha\cap\eta\supseteq X_\alpha\cap\eta$
的序型已是 $\eta$，被 $\eta$ 界住，故序型恰 $\eta$，即
$\eta$ 是 $\mathrm{Ord}\cap M_\alpha$ 增枚举中第 $\eta$
个元素：

$$
h_\alpha(\eta)=\pi_\alpha^{-1}(\eta)=\eta.
$$

于是 $h_\alpha$ 逐点固定 $X_\beta$ 的每个元素。再由引理 1.8，
对任何以「$\le\kappa$ 的序数与 $X_\beta$ 中元素」为参数的
斯科伦项值 $\xi=t(\vec\eta,\vec s)$，只要 $h_\alpha$ 固定全部
参数，就固定 $\xi$。同一引擎给出：$i$（从而 $h$）固定
$M_\alpha$ 中所有由被固定生成元算出的序数——这正是原书
引理 1.12(i) 证明链条的内容。

> **引理 1.12** (i) $K_\alpha=h_\alpha(\kappa)=\min\{\xi\in \mathrm{Ord}\cap M_\alpha:\xi>\kappa\}$；(ii) $\alpha<\beta$
> 且 $\xi\in\mathrm{Ord}\cap M_\beta$（$\xi>\kappa$）时
> $h_\alpha(\xi)=\xi$，尤其 $h_\alpha(K_\beta)=K_\beta$；
> (iii) $\alpha<\beta\Rightarrow K_\alpha<K_\beta$。

(i) 的机制：$h_\alpha$ 把 $\mathrm{Ord}\cap M_\alpha$ 增枚举为
$\lambda$；被固定生成元占据的位置与数值一致，$\kappa$ 之后
的第一个空位给出 $K_\alpha$。此步的完整记账（$M_\alpha$ 在
$\kappa$ 之下的序数如何逐点归位）是原书书页 30–31 的精细账，
本文按上述引擎陈述其内容。(ii) 由引擎直接得到（$M_\beta$ 的
生成元 $\{\kappa\}\cup X_\beta$ 中，$X_\beta$ 部分被
$h_\alpha$ 逐点固定）。

(iii) 的证明：$M_\alpha\subseteq M_\beta$，两组增枚举
$e_\alpha,e_\beta:\lambda\to\mathrm{Ord}$ 满足
$e_\alpha(\nu)\le e_\beta(\nu)$（序嵌入逐点比较），故
$K_\alpha\le K_\beta$。若相等，则 $K_\beta\in\mathrm{Ord}\cap M_\alpha$ 且 $>\kappa$，由 (i) 有 $K_\beta=K_\alpha$；但
$h_\alpha$ 初等且 $h_\alpha(\kappa)=K_\alpha>\kappa$ 蕴含
$h_\alpha(K_\alpha)>h_\alpha(\kappa)=K_\alpha$，而 (ii) 给出
$h_\alpha(K_\beta)=K_\beta=K_\alpha$，矛盾。∎

> **引理 1.13** 对 $\alpha<\beta<\omega_1$ 存在初等
> $h_{\alpha,\beta}:L_\lambda\to L_\lambda$ 使
> (i) $\gamma<\alpha$ 或 $\gamma>\beta$ 时
> $h_{\alpha,\beta}(K_\gamma)=K_\gamma$；(ii)
> $h_{\alpha,\beta}(K_\alpha)=K_\beta$。

构造：$M_{\alpha,\beta}=\mathrm{SH}^{L_\lambda}(\{K_\alpha\}\cup X_\beta)$，$h_{\alpha,\beta}:=$ 其传递化的逆。引擎照搬：(i)
中对 $\gamma>\beta$ 用 $X_{\beta+1}\subseteq U_{\beta+1}$ 的
逐点固定；对 $\gamma<\alpha$，$K_\gamma<K_\alpha$ 落在临界
区之下，用 (i)-式归位记账。(ii) 的无中项论证：显然
$K_\alpha\le h_{\alpha,\beta}(K_\alpha)\le K_\beta$；若有
$\delta\in\mathrm{Ord}\cap M_{\alpha,\beta}$ 满足
$K_\alpha\le\delta<K_\beta$，写
$\delta=t(\vec s,\vec\eta)$（$\vec s\subset\kappa$、
$\vec\eta\subset X_\beta$），则
$L_\lambda\models\exists\vec s<\kappa\ (K_\alpha\le t[\vec s,\vec\eta]<K_\beta)$。应用 $h_\alpha$（初等；它固定
$\vec\eta$ 与 $K_\beta$，并把 $\kappa$ 送至 $K_\alpha$），
取出见证后得到一个落在 $M_\beta$ 中、介于 $\kappa$ 与
$K_\beta$ 之间的序数，与引理 1.12(i) 冲突。∎

（$\vec s\subset\kappa$ 这一步的完整记账同样依赖临界区归位，
见原书书页 32–33；机制已如上。）

> **引理 1.14** $I=\{K_\alpha:\alpha<\omega_1\}$ 是
> $(L_\lambda,E)$ 的不可辨别元集合。

**证明**。给定表达式 $\varphi(v_1,\ldots,v_n)$ 与两组递增序列
$\{\alpha_1<\cdots<\alpha_n\}$、$\{\beta_1<\cdots<\beta_n\}$
取自 $\omega_1$。先取 $\zeta_1<\cdots<\zeta_n$ 递增且
$\max\{\alpha_n,\beta_n\}<\zeta_1$。逐次应用
$h_{\alpha_n,\zeta_n},h_{\alpha_{n-1},\zeta_{n-1}},\ldots, h_{\alpha_1,\zeta_1}$：第 $l$ 步把 $K_{\alpha_l}$ 换成
$K_{\zeta_l}$ 而固定已换好的与未动的（由引理 1.13(i)），得

$$
(L_\lambda,E)\models\varphi[K_{\alpha_1},\ldots,K_{\alpha_n}]
\iff
(L_\lambda,E)\models\varphi[K_{\zeta_1},\ldots,K_{\zeta_n}].
$$

对 $\beta$'s 同理，两组都化归到公共的 $\zeta$'s。∎

> **定理 1.13（Kunen）** 若存在非平凡 $j:L\to L$，则存在极限
> 序数 $\lambda$ 使 $(L_\lambda,E)$ 携带不可数的不可辨别元
> 序数集合。∎（95.5–95.6 全部装配的总结。）

## 95.7 不可辨别元与拉姆齐供给（定义 1.8、引理 1.15、定理 1.14）

> **定义 1.8（不可辨别元）** $\mathfrak A=(A,\vec P,\vec F,\vec c)$
> 是语言 $\mathcal L$ 的结构，$I\subseteq\lambda\subseteq A$。
> 称 $I$ 为 $\mathfrak A$ 的**不可辨别元集合**，若对每个
> $n<\omega$、每个表达式 $\varphi(v_1,\ldots,v_n)$ 与
> $I$ 中任意两组递增 $n$ 元组：
> $$
> \mathfrak A\models\varphi[\alpha_1,\ldots,\alpha_n]
> \iff \mathfrak A\models\varphi[\beta_1,\ldots,\beta_n].
> $$

「无差别」的字面含义：一阶语言无法区分 $I$ 的成员，只能看见
它们的次序。供给这类集合的通用机器是拉姆齐基数。

> **引理 1.15** $\kappa$ 拉姆齐，$\lambda<\kappa$。则
> $\kappa\to(\kappa)^{<\omega}_\lambda$。

**证明**。设 $f:[\kappa]^{<\omega}\to\lambda$。定义
$F:[\kappa]^{<\omega}\to 2$：

$$
F(\{\alpha_1<\cdots<\alpha_{2k}\})=1 \iff
f(\{\alpha_1,\ldots,\alpha_k\})=f(\{\alpha_{k+1},\ldots,\alpha_{2k}\}),
$$

奇数大小（及空隙情形）一律取 $0$。由拉姆齐性取 $F$ 的齐一
$H\in[\kappa]^\kappa$（每个 $n$ 上各常值）。断言每个偶层
常值必为 $1$：把 $H$ 按序型 $\kappa$ 切成连续的 $k$-块
$\langle B_\xi:\xi<\kappa\rangle$，$\kappa>\lambda$ 个块经
$f$ 染 $\lambda$ 色，必有两块 $B_\xi,B_{\eta}$（$\xi< \eta$）同色且整体分离，其并（按序）是一个 $2k$-元组，见证
$F=1$。

再证 $f$ 在 $[H]^k$ 上齐一。任取两组
$\{\alpha_1<\cdots<\alpha_k\},\{\beta_1<\cdots<\beta_k\}\subseteq H$，取 $\{\xi_1<\cdots<\xi_k\}\subseteq H$ 在两者之上。由
$F(\vec\alpha\!\frown\!\vec\xi)=F(\vec\beta\!\frown\!\vec\xi)=1$：

$$
f(\vec\alpha)=f(\vec\xi)=f(\vec\beta).
$$

对每个 $k$ 如此，得 $<\omega$-齐一。∎

（块切割 + 公共高块见证，是这条证明的两个可移动零件；95.15/95.16
的 Coq/Agda 实验把「公共高块见证」做成传递内核。）

> **定理 1.14** $\kappa$ 拉姆齐、$|\mathcal L|<\kappa$、
> $\mathfrak A$ 是论域包含 $\kappa$ 的 $\mathcal L$-结构。
> 则 $\mathfrak A$ 含势为 $\kappa$ 的不可辨别元序数集合。

**证明**。令 $\Phi$ 为 $\mathcal L$ 的全体表达式，
$|\Phi|=\max(\aleph_0,|\mathcal L|)<\kappa$；由拉姆齐基数的
不可达性（强极限），$|\mathcal P(\Phi)|<\kappa$。定义

$$
f:[\kappa]^{<\omega}\to\mathcal P(\Phi),\qquad
f(\{\alpha_1,\ldots,\alpha_n\})=\{\varphi :
\mathfrak A\models\varphi[\alpha_1,\ldots,\alpha_n]\}.
$$

引理 1.15 给出 $f$-齐一的 $H\in[\kappa]^\kappa$：同长递增
元组有相同 $\Phi$-型，即 $H$ 不可辨别。∎

> **引理 1.16（带参数版）** $\kappa$ 拉姆齐、$\lambda<\kappa$
> 无穷、$|\mathcal L|\le\lambda$、$|P|<\kappa$。则可取同质
> 子模型 $B\prec\mathfrak A$ 使
> $B\cap\kappa\in D$（$\kappa$ 可测、$D$ 正规时）且
> $|P\cap B|\le\lambda$。（斯科伦化 + 常元化后套定理 1.14，
> 取 $B=\mathrm{SH}(I)$。）

引理 1.16 是后文 $L[D]$ 分析（1.1.5 小节）的接口，此处按原书
陈述与思路记录。

## 95.8 EM 蓝图与可实现引理（定义 1.9、引理 1.17）

固定可数个新常元 $\{c_k:k<\omega\}$，语言记 $\mathcal L^*$。
**典型结构**是 $(L_\lambda,E,\alpha_k)_{k<\omega}$：$\lambda> \omega$ 极限、$\alpha_k$ 递增序数、且
$I=\{\alpha_k:k<\omega\}$ 是 $(L_\lambda,E)$ 的不可辨别元
集合。

> **定义 1.9（EM 蓝图）** $\mathcal L^*$ 的理论 $T$ 是一幅
> EM 蓝图，当且仅当 $T$ 是某个典型结构的完全理论。

注意两点。其一，若 $I\subseteq\lambda$ 是任意无穷不可辨别元
集合，则任取 $I$ 的递增 $\omega$-枚举所得典型结构的理论相同
（不可辨别性保证语句值不依赖枚举的选择）——**蓝图由 $I$
唯一确定**。其二，Ehrenfeucht–Mostowski 的经典定理（无限拉姆齐
+ 紧致性）说明任何无穷模型都有携带任意指定序型不可辨别元的初等
扩张；蓝图的存在本身不要大基数。高阶无穷公理的作用在**下一节**：
让蓝图满足三条额外条件。

> **引理 1.17（可实现引理）** $T$ 是 EM 蓝图，$T_0$ 是其无
> 常元语句部分。(1) 对每个极限 $\alpha>\omega$ 存在同构意义下
> 唯一的**基本模型** $M(T,\alpha)=(M,E)$：携带序型 $\alpha$
> 的不可辨别元集合 $X$、$M=\mathrm{SH}^{(M,E)}(X)$，且对
> 递增 $n$ 元组 $\vec a\subseteq X$：
> $$
> (M,E)\models\varphi[\vec a] \iff \varphi(c_0,\ldots,c_{n-1})\in T.
> $$
>
> (2) $\omega<\alpha<\beta$ 极限、$j:\alpha\to\beta$ 单调
> 递增，则 $j$ 延拓为初等嵌入 $M(T,\alpha)\to M(T,\beta)$。

**证明**。(1) 存在性用紧致性：对 $\mathcal L^*$ 再添常元
$\{c_\xi:\xi<\alpha\}$，取语句集 $\Delta$：「$c_\xi$ 是
序数」「$c_\eta\in c_\xi$（$\eta<\xi$）」与全部
「$\varphi(c_{\xi_1},\ldots,c_{\xi_n})$（其中
$\varphi(c_{k_1},\ldots,c_{k_n})\in T$，$\xi_1<\cdots< \xi_n<\alpha$，且 $k_i$ 取前 $n$ 个常元）」。有限子集只
涉及有限多个 $c_\xi$，在典型结构中按不可辨别性解释即满足；紧
致性给出模型，$J=\{c_\xi^M\}$ 是序型 $\alpha$ 的不可辨别元
集合，取 $A=\mathrm{SH}^{(M,E)}(J)$ 即基本模型。

唯一性：任何两个实现由斯科伦项运输——$\pi(t^0[\vec a])= t^1[\pi\vec a]$ 无歧义，因为「$t[\vec a]=t'[\vec a']$」与
「$t[\vec a]\in t'[\vec a']$」都是关于不可辨别元的语句，在两个
模型中同值。(2) 的延拓同此运输，$j(t^M[\vec a])= t^{M'}[j\vec a]$。∎

## 95.9 三条件：有秩、无界、神奇（引理 1.18–1.21，推论 1.2/1.3）

蓝图 $T$ 的基本模型可以「不像 $L$」：$\in^M$ 可能非良基、
不可辨别元可能在 $M$ 的序数中有界、或者前段信息丢失。三条条件
逐条堵住。

> **引理 1.18（有秩条件）** TFAE：(1) 对一切极限 $\alpha>\omega$，
> $M(T,\alpha)$ 良基；(2) 某个 $\alpha\ge\omega_1$ 见证良基；
> (3) 一切可数极限 $\alpha$ 见证良基。

**证明**。(2)⇒(3)：取 $M(T,\alpha)$ 的前 $\beta$ 个不可
辨别元生成的子模型，它是 $M(T,\beta)$。(3)⇒(1)：最小反例
$\alpha\ge\omega_1$ 携带下降链 $\cdots\in a_2\in a_1\in a_0$；
每个 $a_n=t[\vec c\,^{\,n}]$，只用可数多个不可辨别元，整条链落在
一个可数序型的前段子模型内，与 (3) 冲突。∎

> **推论 1.2（第一存在性）** 存在拉姆齐基数 ⟹ 存在满足有秩条件
> 的 EM 蓝图。（取 $(L_\kappa,E)$ 的 $\kappa$-大小不可辨别
> 元集合 $I\subseteq\kappa$（定理 1.14），令 $T$ 为
> $(L_\kappa,E,\alpha_k)_{k<\omega}$ 的理论，$\alpha_k$ 取
> $I$ 的前 $\omega$ 个元素；此时 $\alpha=\kappa\ge\omega_1$
> 见证 (2)。）∎

> **引理 1.19（无界条件）** TFAE：(1) 对一切极限
> $\alpha>\omega$，不可辨别元集合在 $M(T,\alpha)$ 的序数中
> 无界；(2) 某个 $\alpha$ 见证；(3) $T$ 含全部语句：
> 「若 $t(c_1,\ldots,c_n)$ 是序数，则
> $t(c_1,\ldots,c_n)\in c_{n+1}$」（$t$ 取遍典型斯科伦项）。

**证明**。(2)⇒(3)：给定 $t$，序数值 $t[\vec a]$ 被更高的
不可辨别元 $a_{n+1}$ 超过，该事实关于 $\vec a$ 与
$a_{n+1}$ 是语句，进蓝图。(3)⇒(1)：任何序数
$y=t[\vec a]$，取 $a_{n+1}$ 在 $\vec a$ 之上，由语句得
$y\in a_{n+1}$。∎

> **推论 1.3（第二存在性）** 存在拉姆齐基数 ⟹ 存在满足无界条件
> 的 EM 蓝图。∎

> **引理 1.20（神奇性条件）** $T$ 满足无界条件。TFAE：(1)
> 一切 $M(T,\alpha)$ 具备**神奇性**：不可辨别元无界，且对极限
> $\omega\le\xi<\alpha$、$X$ 的第 $\xi$ 个元素 $y_\xi$、
> $Y=$ 前 $\xi$ 个元素之集，每个 $M$ 中 $<y_\xi$ 的序数
> 都在 $\mathrm{SH}^{(M,E)}(Y)$ 中；(3) $T$ 含全部语句：
> 「若 $t(c_1,\ldots,c_{m+n})\in c_{m+1}$ 是序数，则
> $$
> t(c_1,\ldots,c_{m+n}) =
> t(c_1,\ldots,c_m,c_{m+n+1},\ldots,c_{m+2n}).
> $$
> 」
>
> 且此时前 $\xi$ 个不可辨别元生成的子模型就是
> $M(T,\xi)$，其序数构成大模型序数的前段。

**证明**要点。(2)⇒(3)：值 $t[\vec a,\vec y]\in y_1$ 由神奇性
落在 $\mathrm{SH}(Y)$ 中，写成 $s[\vec c\,^{\,\le\omega}]$；
该等式是关于不可辨别元的语句，把 $\vec y$ 平移到任意高块
$\vec z$ 仍成立——这正是 (3) 的语句。(3)⇒(1)：对
$\alpha'=t[\vec a,\vec y]<y_1$，取高块 $\vec w,\vec z$，(3)
的等式把 $\vec y$ 换成 $\vec z$，再用不可辨别性换成
$\vec w$，于是 $\alpha'$ 由前段元素表出。∎

> **引理 1.21（闭特性）** 神奇蓝图的基本模型中，不可辨别元集合
> $X$ 在 $\mathrm{Ord}(M,E)$ 中**闭**：第 $\xi$ 个元素
> $y_\xi=\sup\{x\in X:x\in y_\xi\}$。
> （前段子模型 $\mathrm{SH}(Y)=M(T,\xi)$ 的序数构成前段且
> $Y$ 在其中无界。）∎

## 95.10 极小化与 Silver 定理（引理 1.22、定理 1.15、引理 1.23–1.27、定理 1.16）

> **引理 1.22（极小化）** $\kappa^*$ 不可数。若某
> $(L_\lambda,E)$ 携带序型 $\kappa^*$ 的不可辨别元集合，则
> 存在极限序数 $\bar\lambda$ 与无界
> $I\subseteq\bar\lambda$，序型 $\kappa^*$、
> $L_{\bar\lambda}=\mathrm{SH}^{L_{\bar\lambda}}(I)$，且
> $(L_{\bar\lambda},E)$ 具备神奇性。

**证明**骨架（三个动作）。动作一（最小化高度）：取最小的
$\lambda$，凝聚化把 $\mathrm{SH}^{L_\lambda}(J)$ 传化为
$L_\beta$、$\beta\le\lambda$，由最小性 $\beta=\lambda$。
动作二（无界性）：若 $I$ 在 $\lambda$ 中有上界 $\alpha$，
取 $\alpha=t^{L_\lambda}(\vec\eta)$（$\vec\eta$ 为 $I$ 的
低段），则 $J=I\setminus(\alpha+1)$ 仍不可辨别——任何关于
$\vec\eta$ 与 $J$-元素的语句等式都可改写为只谈 $I$ 的语
句，由 $I$ 的不可辨别性传递——且 $J\subseteq\alpha$，与
$\lambda$ 最小矛盾。动作三（神奇性）：在满足前两条的
$I$ 中取第 $\omega$ 个元素最小者；若不神奇，由引理 1.20(3)
的反例项 $t$ 构造块移动集
$J=\{t^{L_\lambda}(\vec a,u_\alpha):\alpha<\kappa^*\}$
（$\vec a$ 为 $I$ 的前 $m$ 个元、$u_\alpha$ 为按 $n$
个一组切出的块），$J$ 仍是序型 $\kappa^*$ 的不可辨别集，
且其第 $\omega$ 个元素严格更小，矛盾。∎

> **定理 1.15（存在性）** 存在拉姆齐基数 ⟹ 存在满足有秩条件的
> 神奇 EM 蓝图。∎（定理 1.14 供给 $I\subseteq\kappa$，引理
> 1.22 极小化。）

> **引理 1.24** $\lambda$ 不可数基数 ⟹
> $M(T,\lambda)\cong(L_\lambda,E)$。

**证明**。设 $M(T,\lambda)\cong L_\beta$，携带无界闭不可辨别
元集 $I_\lambda\subseteq\beta$、序型 $\lambda$，故
$\beta\ge\lambda$。反设 $\lambda<\beta$：取极限
$\xi<\lambda$ 使第 $\xi$ 个元素 $y_\xi>\lambda$
（$I_\lambda$ 在 $\beta$ 无界）。由神奇性，
$\{\delta\in\beta:\delta<y_\xi\}\subseteq\mathrm{SH}^{L_\beta}(Y)$，
$Y$ 为前 $\xi$ 个元素。于是传递化的高度
$\gamma=\operatorname{otp}(\mathrm{Ord}\cap\mathrm{SH}(Y)) \ge y_\xi>\lambda$，而
$|\mathrm{SH}(Y)|=\max(\aleph_0,\xi)<\lambda$，故
$|\gamma|<\lambda\le\gamma$，矛盾。∎

> **引理 1.25** $\kappa<\lambda$ 不可数基数，则
> $I_\kappa=I_\lambda\cap\kappa$、$\kappa\in I_\lambda$，且
> $L_\kappa=\mathrm{SH}^{L_\lambda}(I_\kappa)\prec L_\lambda$。

**证明**。取 $I_\lambda$ 的前 $\kappa$ 个元素 $J$，
$A=\mathrm{SH}^{L_\lambda}(J)$。由引理 1.17(1) 的唯一性与
引理 1.24，$A$ 的传递化是 $(L_\kappa,E)$ 且 $J$ 对应
$I_\kappa$；无界条件给出 $A$ 的序数构成 $\lambda$ 的前
段，故 $\sup J=\kappa$；$I_\lambda$ 闭，故
$\kappa\in I_\lambda$ 且恰为其第 $\kappa$ 个元素。∎

> **引理 1.26** 至多一幅满足有秩条件的神奇 EM 蓝图。
> （蓝图被 Silver 类 $I$ 与前 $\omega$ 个元素的理论决定。）
> **引理 1.27** 每个不可数正则 $\kappa$ 至多一个无界闭
> $C\subseteq\kappa$ 满足：$C$ 不可辨别且
> $L_\kappa=\mathrm{SH}^{L_\kappa}(C)$。∎（都由引理 1.24/1.25
> 的唯一性立即。）

装配：

> **定理 1.16（Silver）** 存在拉姆齐基数，则：
> (i) $\kappa<\lambda$ 不可数基数 ⟹
> $(L_\kappa,E)\prec(L_\lambda,E)$；
> (ii) 存在唯一的序数无界闭类 $I$，含全部不可数基数，且对每个
> 不可数基数 $\kappa$：(a) $|I\cap\kappa|=\kappa$；(b)
> $I\cap\kappa$ 是 $(L_\kappa,E)$ 的不可辨别元集合；(c) 每个
> $\alpha\in L_\kappa$ 在 $(L_\kappa,E)$ 上以 $I\cap\kappa$
> 中元素为参数可定义。

$I=\bigcup_{\kappa}I_\kappa$。此后 $I$ 的元素称为 **Silver
不可辨别元**。∎

## 95.11 0#：定义、等价刻画与后果（定义 1.10、推论 1.4、定理 1.17、推论 1.5）

> **定义 1.10（0#）** 若存在，**0#**（读「零井号」，Zero Sharp）
> 就是那个唯一的满足有秩条件的神奇 EM 蓝图。

「0# 存在」＝「满足有秩条件的神奇 EM 蓝图存在」。

> **推论 1.4** 0# 存在 ⟺ 某个 $(L_\lambda,E)$ 携带不可数的
> 不可辨别元序数集合。∎（⇒ 由引理 1.24；⇐ 由引理 1.22 极小化
> 出神奇蓝图，有秩条件由实现于 $L$ 层级保证。）

> **定理 1.17** TFAE：(1) 存在非平凡 $j:L\to L$；(2) 某个
> $(L_\lambda,E)$ 携带不可数不可辨别元集合；(3) 0# 存在；
> (4) 存在极限序数 $\alpha<\beta$ 与非平凡初等
> $k:L_\alpha\to L_\beta$，$\mathrm{Crit}(k)<|\alpha|$。

**证明**。(1)⇒(2) 定理 1.13；(2)⇒(3) 推论 1.4；(1)⇔(4)
定理 1.12 及其逆（限制即片段）。(3)⇒(1)：取 Silver 类 $I$
与任一非平凡保序映射 $\sigma:I\to I$（如整体上移一位）。
**定义**

$$
j\big(t^L(\iota_1,\ldots,\iota_m)\big) :=
t^L\big(\sigma(\iota_1),\ldots,\sigma(\iota_m)\big).
$$

良定义：等式 $t[\vec\iota]=t'[\vec\iota'\,]$ 与
$t[\vec\iota]\in t'[\vec\iota'\,]$ 是关于 $I$ 中递增组的
语句，由不可辨别性在 $\sigma$ 平移下不变。初等性同理。非平凡：
$j(\iota_0)=\sigma(\iota_0)\ne\iota_0$。∎

（95.14/95.20 的 Lean/Prolog 通道分别把「平移不变」做成定理与查询。）

> **推论 1.5** 若 0# 存在，则：
>
> (1) $0\#=\mathrm{Th}(L_{\aleph_\omega},E,\aleph_1,\aleph_2, \ldots,\aleph_n,\ldots)$。全体不可数基数都是 Silver 不可辨别
> 元，任何从 $I\cap\aleph_\omega$ 取出的递增 $\omega$-列给出
> 同一典型结构；由蓝图唯一性，其理论就是 0#。
>
> (2) $\min(I)=\iota_0$ 是可数序数，且 $I\cap\omega_1\notin L$。
> 证：取极限 $\xi<\omega_1$，$|I\cap\aleph_1|=\aleph_1$ 给出
> $\iota_0<\omega_1$。若 $I\cap\omega_1\in L$，则其前
> $\omega$ 个元素在 $L$ 中给出典型结构，理论 $0\#\in L$；
> 那么 $L$ 内部可执行定理 1.17 (3)→(1) 的构造，得到
> $L\models$「存在非平凡 $j:V\to V$」，与 Kunen 定理（ZFC
> 定理，在 $L$ 中成立）矛盾。
>
> (3) 在 $L$ 中可定义的每个可构造集合都是彻底可数的；特别地
> $\aleph_1^L$ 可数。证：设 $a\in L$ 由 $\varphi$ 无参可
> 定义。由 Silver 定理 (i) 与 Tarski 判据，$a$ 属于每个
> $L_\kappa$（$\kappa$ 不可数基数）且同样无参可定义；由
> (c)，$a=t^L(\vec\iota)$（$\vec\iota\in I$ 有限）。对
> **下移**保序映射（把 $\iota_{\xi+\omega}$ 送到
> $\iota_\xi$）反复应用 $j_\sigma(a)=a$，把参数压进
> $I\cap\omega_1$ 的前段，得 $a\in L_{\iota_m}$（某
> $\iota_m<\omega_1$），而 $|L_{\iota_m}|=\aleph_0$。
> $\aleph_1^L$ 可数由 $\aleph_1^L\le\iota<\omega_1$（任取
> $\iota\in I\cap\omega_1$：它是 $L$-不可达基数，故
> $\aleph_1^L\le\iota$）。
>
> (4) 每个不可数基数在 $L$ 中不可达。全体不可数基数都在
> $I$ 中，具有相同的一阶性质：$\aleph_1$ 在 $L$ 正则、
> $\aleph_\omega$ 在 $L$ 是极限基数，故每个 Silver 元在
> $L$ 正则且是极限基数；配合 $L\models\mathrm{GCH}$ 得
> $L$-强极限，即 $L$-不可达。∎

0# 也可以定义为纯语言对象：集合论纯语言表达式的极大可满足集

$$
0\#=\bigcup\{\ulcorner\varphi(v_1,\ldots,v_n)\urcorner :
(L_{\aleph_\omega},E)\models\varphi[\aleph_1,\ldots,\aleph_n]\},
$$

即「把递增 $\omega$-列的前 $n$ 个代入 $v_1,\ldots,v_n$ 后
为真」的表达式代码之集。作为自然数子集，0# 是**一个实数**。

## 95.12 $a\#$：从实数到任意集合的相对化

同样的理论可对 $L[a]$（$a\subseteq\omega$）整体重做：语言加
一元谓词解释 $a$，典型结构取 $(L_\lambda[a],E,a,\alpha_k)_{ k<\omega}$，得到**唯一的**满足有秩条件的神奇蓝图 $a\#$、
相对 Silver 类 $I^a$，以及

$$
a\#\text{ 存在} \iff \text{存在非平凡 } j:L[a]\to L[a].
$$

注意两点（原书明示的基础事实）：其一 $a\in L[a]$（因
$a\subseteq\omega$）；其二典型结构不受谓词解释影响，因为
$\omega$ 下方全是嵌入不动点。特别地 $0\#=\varnothing\#= \omega\#$。

对一般集合 $a$ 分两种情形（定义 1.11/1.12）：

- $a\in L[a]$：**$a$ 之上的无差别元类** $C\subseteq L[a]\cap\mathrm{Ord}$ 要求对每组来自 $\mathrm{TC}(\{a\})$
  的参数 $\vec b$、每组递增 $\vec\alpha,\vec\beta\subseteq C$
  与每个表达式 $\varphi$：
  $L[a]\models\varphi[\vec b,\vec\alpha] \iff L[a]\models\varphi[\vec b,\vec\beta].$

  $a\#$ 用哥德尔编码定义在 $\omega\times\mathrm{TC}(\{a\})^{< \omega}$ 上，取 $L_{\nu^+}[a]$（$\nu$ 最小使
  $a\in L_{\nu+1}[a]$）的无界闭不可辨别集做证据。
- $a\notin L[a]$：改用 $L(a)$（第一卷定义 I.2.33 的最小
  内模型含 $a$ 为元素），参数取自 $\mathrm{TC}(\{a\})$，同样
  定义。

> **引理 1.28/1.29** $\kappa$ 可测、$U$ 正规、$a\in V_\kappa$。
> 则 $a\in L[a]$（或 $a\in L(a)$），且 $U$ 中有
> $X\subseteq\kappa$ 是 $L[a]$（或 $L(a)$）的 $a$ 之上
> 的不可辨别元集合。（引理 1.16 的带谓词版：$L_\kappa[a]$ 的
> 测一集内取不可辨别元。）

> **定理 1.18/1.19** $\eta$ 无穷基数、$a\in V_{\eta^+}$。
> TFAE：(1) $a\#$ 存在；(2) 存在正则 $\theta$ 与无界闭
> $C\subseteq\theta$ 是 $a$ 之上的不可辨别元集合；(3) 存在
> 无界闭类 $C_a$ 使
> $L[a]=\mathrm{SH}(C_a\cup\mathrm{TC}(\{a\}))$，且对每个基数
> $\theta\ge\eta^+$、
> $L_\theta[a]=\mathrm{SH}((C_a\cap\theta)\cup\mathrm{TC}(\{a\})) \prec L[a]$。（$a\notin L[a]$ 时把 $L[\cdot]$ 全换
> $L(\cdot)$。）

> **推论 1.6/1.7** (1) $\kappa$ 可测、$a\in V_\kappa$ ⟹
> $a\#$ 存在。(2) $a\#$ 存在、$\theta\le\kappa<\lambda$
> 基数，则 $L_\kappa[a]\prec L_\lambda[a]\prec L[a]$（或
> $L(\cdot)$ 版）。

> **定理 1.20** $\kappa$ 可测、$a\in V_\kappa$，则
> $a\#$ 存在。∎

第二卷的 $L(\mathbb R)$ 线与第三卷末尾的确定性理论将反复使用
$A\#$（$A\subseteq\mathbb R$）——每个实数集合都有自己的
「真相蓝图」，这是覆盖引理之外另一条「内模型接近 $V$」的度量。

## 95.13 与第 94 章的接口及后果总账

| 起点 | 结论 | 机制 |
|---|---|---|
| $\exists\kappa$ 可测 | $j\upharpoonright L:L\to L$ 非平凡 | 引理 1.7 |
| $\exists j:L\to L$ 非平凡 | 0# 存在 | 定理 1.13+1.22 |
| 0# 存在 | $V\ne L$ 的三级强化 | 推论 1.5 |
| $\exists\kappa$ 拉姆齐 | 0# 存在（另一条路） | 定理 1.14+1.15 |
| 0# 存在 | 每个 $a\in V_\kappa$（$\kappa$ 可测）有 $a\#$ | 引理 1.28+定理 1.20 |

「三级强化」具体为：$\aleph_1^L$ 可数；每个不可数基数在
$L$ 中不可达；$0\#\notin L$ 且 $I\cap\omega_1\notin L$。
相反方向是第 96 章的覆盖引理：**0# 不存在** ⟺ $L$ 在「覆盖
每个集合」的意义下与 $V$ 的基数行为完全一致——0# 是 $L$
与 $V$ 之间那条唯一的裂缝。

## 95.14 机器通道一：Lean——框架定理与 $R(3,3)=6$

mathlib 4.33.1 没有无限 Ramsey 定理，也没有不可辨别元的开发——这
两个缺口本身就是本章「机器边界」的一部分。Lean 通道因此做两件真
事：把不可辨别元做成一个可推理的定义框架，并穷举见证有限 Ramsey
种子。

```lean
import Mathlib

/-!
# 第 95 章 · 0# 与 Silver 不可辨别元

不可辨别元的有限框架：封闭律（子集仍是不可辨别元）、保序平移不改变
取值（平移嵌入无歧义性的有限种子），以及 R(3,3)=6 的穷举见证
（定理 1.14 拉姆齐供给的有限前身）。0# 本体是无限对象，不在机器范围内。
-/

namespace Settheory.Ch95

/-- 递增元组：表内每个位置都小于所有靠后的元素。 -/
def Inc {α : Type*} [LT α] (t : List α) : Prop := t.Pairwise (· < ·)

/-- 有限结构的染色：每个「表达式代码」φ 给每个元组一个布尔值。 -/
abbrev Coloring (α Φ : Type*) := Φ → List α → Bool

/-- s 是（关于 f 的）不可辨别元列表：s 自身递增，且 s 中任何两个
等长的递增元组在每个表达式下取值相同。 -/
def IsIndiscernible {α : Type*} [LinearOrder α] {Φ : Type*}
    (f : Coloring α Φ) (s : List α) : Prop :=
  Inc s ∧ ∀ φ {t u : List α}, Inc t → Inc u → t.length = u.length →
    (∀ x ∈ t, x ∈ s) → (∀ x ∈ u, x ∈ s) → f φ t = f φ u

/-- 保序映射保持递增性。 -/
theorem Inc.map {α β : Type*} [LT α] [LT β] {σ : α → β}
    (hmono : ∀ a b, a < b → σ a < σ b) {t : List α} (h : Inc t) :
    Inc (t.map σ) := by
  induction t with
  | nil => exact List.Pairwise.nil
  | cons a t ih =>
      rw [List.map_cons]
      show List.Pairwise (· < ·) (σ a :: List.map σ t)
      rw [List.pairwise_cons]
      refine ⟨fun b hb => ?_, ih h.tail⟩
      rcases List.mem_map.mp hb with ⟨c, hc, rfl⟩
      exact hmono _ _ (List.rel_of_pairwise_cons h hc)

/-- 封闭律：不可辨别元集合的（递增）子列表仍是不可辨别元集合。 -/
theorem IsIndiscernible.sublist {α : Type*} [LinearOrder α] {Φ : Type*}
    {f : Coloring α Φ} {s t : List α} (h : IsIndiscernible f s)
    (ht : Inc t) (hsub : ∀ x ∈ t, x ∈ s) :
    IsIndiscernible f t :=
  ⟨ht, fun φ (_u _v : List α) hu hv hlen h1 h2 =>
    h.2 φ hu hv hlen (fun x hx => hsub x (h1 x hx))
      (fun x hx => hsub x (h2 x hx))⟩

/-- 平移不变性：保序自嵌入 σ 下，任何递增元组的取值不变。
这是「σ:I→I 诱导 j 且无歧义」（定理 1.17 (3)→(1)）的有限种子。 -/
theorem IsIndiscernible.shift {α : Type*} [LinearOrder α] {Φ : Type*}
    {f : Coloring α Φ} {s : List α} (h : IsIndiscernible f s)
    (φ : Φ) (σ : α → α) (hmono : ∀ a b, a < b → σ a < σ b)
    (hmap : ∀ x ∈ s, σ x ∈ s) {t : List α}
    (ht : Inc t) (hsub : ∀ x ∈ t, x ∈ s) :
    f φ (t.map σ) = f φ t :=
  h.2 φ (Inc.map hmono ht) ht (by simp)
    (fun x hx => by
      rcases List.mem_map.mp hx with ⟨c, hc, rfl⟩
      exact hmap c (hsub c hc)) hsub

/-- R(3,3) ≤ 6：六点上任何对染色都有三元齐一集，即单表达式语言下的
三元不可辨别集。这是定理 1.14 的有限前身，由 native_decide 穷举
2^15 种染色见证。 -/
example : ∀ f : Sym2 (Fin 6) → Bool, ∃ x y z : Fin 6,
    x < y ∧ y < z ∧
    f (Sym2.mk x y) = f (Sym2.mk x z) ∧
    f (Sym2.mk x z) = f (Sym2.mk y z) := by
  native_decide

/-- 五边形染色（模 5 相邻为红、对角为蓝）没有齐一三元组：6 不能降为 5。 -/
def red5 (x y : ℕ) : Bool :=
  (x + 5 - y) % 5 == 1 || (x + 5 - y) % 5 == 4

example : ¬ ∃ x y z : Fin 5,
    x.val < y.val ∧ y.val < z.val ∧
    (red5 x.val y.val = red5 x.val z.val ∧
     red5 x.val z.val = red5 y.val z.val) := by
  decide

end Settheory.Ch95
```

四个读点。其一，`IsIndiscernible` 把定义 1.8 的「任意两组递增
n 元组」按长度参数化，正是 95.15/95.16 的 Coq/Agda 版本共享的
形状。其二，`sublist` 是封闭律（Silver 类与任何子类的关系）；其三，
`shift` 的证明一行收口：平移像与原元组都是 $s$ 内等长递增元组，
**取值只依赖长度**——定理 1.17 (3)→(1) 中「$j$ 无歧义」的全部
有限内容就在这一行里。其四，$R(3,3)$ 的 `native_decide` 穷举
$2^{15}$ 种染色；紧随其后的 `decide` 反例给出五边形染色，说明
6 是最优的——有限 Ramsey 数 $R(3,3)=6$ 恰好是定理 1.14 里
$\kappa\to(\kappa)^{<\omega}_{<\kappa}$ 在最小尺度上的影子。

## 95.15 机器通道二：Coq——封闭律与比较引擎

Coq 版把引理 1.15 的证明拆成两半：**传递内核**（同高块见证则同色，
可完全证明）与**无限部分**（齐一集中「任取更高的第三块」，依赖
集合无穷），后者明确留给正文。

```coq
(* 第 95 章：有限不可辨别元的封闭律、配对比较引擎与具体样本。 *)
From Coq Require Import List Arith Bool.
Import ListNotations.

Module Ch95.

Section Finite.

Variable A : Type.
Variable ltA : A -> A -> bool.
Variable Phi : Type.
Variable f : Phi -> list A -> bool.

Fixpoint Incb (t : list A) : bool :=
  match t with
  | [] => true
  | a :: l =>
      match l with
      | [] => true
      | b :: _ => ltA a b && Incb l
      end
  end.

Definition indisc (s : list A) : Prop :=
  Incb s = true /\
  forall phi t u, Incb t = true -> Incb u = true ->
    length t = length u -> incl t s -> incl u s ->
    f phi t = f phi u.

(* 封闭律：不可辨别集的递增子集仍不可辨别。 *)
Theorem sub_indisc : forall s t,
  indisc s -> Incb t = true -> incl t s -> indisc t.
Proof.
  intros s t [Hs Hall] Ht Hincl. split; [exact Ht|].
  intros phi u v Hu Hv Hlen H1 H2.
  apply Hall; try assumption.
  - intros x Hx. apply Hincl. now apply H1.
  - intros x Hx. apply Hincl. now apply H2.
Qed.

End Finite.

(* 配对比较引擎（引理 1.15 的核心等式）：若 t1、t2 与公共高块 t3
   同色配对成功，则 t1 与 t2 同色。原书用「H 中取更高的第三块」，
   这是无限部分；有限侧只保留传递内核。 *)
Section Comparison.

Variable C : Type.
Variable ceq : C -> C -> bool.
Hypothesis ceq_ok : forall x y : C, ceq x y = true <-> x = y.
Variable g : list nat -> C.

Definition cmp (t u : list nat) : bool := ceq (g t) (g u).

Theorem comparison_trans : forall t1 t2 t3,
  cmp t1 t3 = true -> cmp t2 t3 = true -> g t1 = g t2.
Proof.
  intros t1 t2 t3 H1 H2.
  apply ceq_ok in H1. apply ceq_ok in H2.
  now rewrite H1, <- H2.
Qed.

End Comparison.

(* 具体样本：奇偶染色下 {0,2,4} 的全部递增二元组取值一致。 *)
Definition g2 (x y : nat) : bool :=
  Nat.even (x + y).

Definition phi_pair (t : list nat) : bool :=
  match t with
  | [x; y] => g2 x y
  | _ => true
  end.

Example pair_02 : phi_pair [0; 2] = true.
Proof. reflexivity. Qed.

Example pair_24 : phi_pair [2; 4] = true.
Proof. reflexivity. Qed.

Example pair_04 : phi_pair [0; 4] = true.
Proof. reflexivity. Qed.

Example counter_pair : phi_pair [1; 2] = false.
Proof. reflexivity. Qed.

(* {0,2,4} 的蓝图：一元恒真、二元恒真（偶+偶）。 *)
Definition blueprint_024 : list bool :=
  [ true; true; true; true ].

Example blueprint_realized :
  phi_pair [0;2] = nth 1 blueprint_024 false /\
  phi_pair [2;4] = nth 2 blueprint_024 false /\
  phi_pair [0;4] = nth 3 blueprint_024 false.
Proof. repeat split; reflexivity. Qed.

End Ch95.
```

`Incb` 的两层 `match` 是 Coq 结构递归的要求（递归调用必须落在
`l` 上）。`sub_indisc` 是封闭律；`comparison_trans` 是引理 1.15
结尾「$f(\vec\alpha)=f(\vec\xi)=f(\vec\beta)$」的内核——
把它与「在齐一集中任取高块」合起来就是完整的引理，而后半句是
无穷集的属性。样本部分：奇偶染色下 $\{0,2,4\}$ 三对全真
（偶+偶=偶），$\{1,2\}$ 假，蓝图表 `blueprint_024` 把「取值只
依赖长度」物化为一张可核对的长度→值表。

## 95.16 机器通道三：Agda——构造性封闭律

Agda 与 Coq 同构，但一切必须显式构造；`inc-step` 的辅助函数式写法
是为了让终止检查器直接看到结构递减（`with` 抽象会遮住它）。

```agda
-- 第 95 章：有限不可辨别元的封闭律与配对比较引擎（构造性）。
module Ch95_zerosharp where

open import Data.Bool using (Bool; true; false; not; _∨_; if_then_else_)
open import Data.List using (List; []; _∷_; map)
open import Data.Product using (_×_; _,_)
open import Data.Nat using (ℕ; zero; suc; _+_; _≡ᵇ_; _<ᵇ_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; trans; sym)

-- 递增检查：构造性布尔判定。
inc : List ℕ → Bool
inc [] = true
inc (x ∷ l) = inc-step x l
  where
  inc-step : ℕ → List ℕ → Bool
  inc-step x [] = true
  inc-step x (y ∷ r) = if x <ᵇ y then inc-step y r else false

inb : ℕ → List ℕ → Bool
inb x [] = false
inb x (y ∷ ys) = (x ≡ᵇ y) ∨ inb x ys

sub : List ℕ → List ℕ → Set
sub t s = ∀ x → inb x t ≡ true → inb x s ≡ true

agreeing : (List ℕ → Bool) → List ℕ → Set
agreeing f s =
  ∀ t u → inc t ≡ true → inc u ≡ true →
    sub t s → sub u s → f t ≡ f u

indisc : (List ℕ → Bool) → List ℕ → Set
indisc f s = inc s ≡ true × agreeing f s

-- 封闭律：不可辨别集的递增子集仍不可辨别。
sub-closure : ∀ f s t → indisc f s → inc t ≡ true → sub t s → indisc f t
sub-closure f s t (hsorted , hagree) hinc hsub =
  hinc , λ u v hu hv h1 h2 →
    hagree u v hu hv (λ x hx → hsub x (h1 x hx)) (λ x hx → hsub x (h2 x hx))

-- 配对比较引擎（引理 1.15 的核心等式）：t1、t2 各与公共高块 t3
-- 同色，则 t1 与 t2 同色。「取更高的第三块」是无限部分，此处只留内核。
cmp-engine : (g : List ℕ → Bool) (t1 t2 t3 : List ℕ) →
  g t1 ≡ g t3 → g t2 ≡ g t3 → g t1 ≡ g t2
cmp-engine g t1 t2 t3 e1 e2 = trans e1 (sym e2)

-- 具体样本：和的奇偶染色下 {0,2,4} 的全部递增二元组取值一致。
even : ℕ → Bool
even zero = true
even (suc n) = not (even n)

g2 : List ℕ → Bool
g2 (x ∷ y ∷ []) = even (x + y)
g2 _ = true

sample-agree-02 : g2 (0 ∷ 2 ∷ []) ≡ true
sample-agree-02 = refl

sample-agree-24 : g2 (2 ∷ 4 ∷ []) ≡ true
sample-agree-24 = refl

sample-agree-04 : g2 (0 ∷ 4 ∷ []) ≡ true
sample-agree-04 = refl

sample-counter : g2 (1 ∷ 2 ∷ []) ≡ false
sample-counter = refl

-- 平移不变样本：σ = +2 保持偶点上的取值。
shift-same :
  g2 (map (λ x → 2 + x) (0 ∷ 2 ∷ [])) ≡ g2 (0 ∷ 2 ∷ [])
shift-same = refl
```

`sub-closure` 的证明项就是「子集的子集还是子集」的组合，与 Coq
版逐字对应；`shift-same` 用 `refl` 直接算出
$g_2([2,4])=g_2([0,2])=\text{true}$——平移不变性在具体染色上
的计算见证。

## 95.17 机器通道四：Isabelle/ZF——具体染色的齐一三元组

ZF 对象逻辑没有有限 Ramsey 的自动化，本通道做手工见证：固定六点
全集上的一个具体染色，验证 $\{1,3,5\}$ 齐一、$\{0,1,3\}$ 不
齐一。

```isabelle
theory ZeroSharp
  imports "ZF.Nat"
begin

text \<open>第 95 章：六点序上一个具体对染色的齐一三元组（单表达式语言
下的三元不可辨别集）、蓝图取值一致性与一个反例三元组。0# 是无限对象，
这里只核对有限影子。\<close>

definition N3 :: "i" where "N3 \<equiv> succ(2)"
definition N4 :: "i" where "N4 \<equiv> succ(N3)"
definition N5 :: "i" where "N5 \<equiv> succ(N4)"
definition K6 :: "i" where "K6 \<equiv> succ(N5)"

(* 红边恰为 {1,3},{1,5},{3,5},{0,1}；其余对为蓝。 *)
definition red :: "i => i => o" where
  "red(x, y) \<equiv> (x = 1 \<and> y = N3) \<or> (x = 1 \<and> y = N5) \<or>
                  (x = N3 \<and> y = N5) \<or> (x = 0 \<and> y = 1)"

lemma red_13: "red(1, N3)" by (simp add: red_def)
lemma red_15: "red(1, N5)" by (simp add: red_def)
lemma red_35: "red(N3, N5)" by (simp add: red_def)

lemma not_red_03: "\<not> red(0, N3)" by (simp add: red_def N3_def)
lemma not_red_05: "\<not> red(0, N5)" by (simp add: red_def N5_def N4_def N3_def)

(* I = {1,3,5}：所有对同为红，齐一（不可辨别）。 *)
lemma hom_I: "red(1,N3) \<and> red(1,N5) \<and> red(N3,N5)"
  using red_13 red_15 red_35 by blast

(* {0,1,3}：红蓝混合，不齐一。 *)
lemma not_hom_013:
  "red(0,1) \<and> \<not> red(0,N3) \<and> red(1,N3)"
  using red_13 not_red_03 by (simp_all add: red_def N3_def)

(* 元素都属于六点全集 K6。 *)
lemma in_K6:
  "0 \<in> K6 \<and> 1 \<in> K6 \<and> 2 \<in> K6 \<and> N3 \<in> K6 \<and> N4 \<in> K6 \<and> N5 \<in> K6"
  by (auto simp add: K6_def N5_def N4_def N3_def)

end
```

数字缩写沿用第 93/94 章的纪律（ZF 只内置 0/1/2，`3` 必须写成
`succ(2)` 等）。一个实测细节：`red` 用析取式定义而不用有序对集合
的成员关系——后者在 `simp` 下要比较 $\{\{x\},\{x,y\}\}$ 形式的
集合相等，简化器会在数字编码上绕远路；析取式每个分支都有可判定
的假文字，一击即溃。

## 95.18 机器通道五：Julia——$R(3,3)=6$ 穷举

```julia
# 第 95 章：R(3,3)=6 穷举、五边形反例、平移不变性与蓝图一致性。
println("==== 95")

pairs_of(v) = [(v[i], v[j]) for i in 1:length(v) for j in i+1:length(v)]
triples_of(v) = [(v[i], v[j], v[k])
                 for i in 1:length(v) for j in i+1:length(v) for k in j+1:length(v)]

pairs6 = pairs_of(1:6)
idx = Dict(p => k for (k, p) in enumerate(pairs6))
triples6 = triples_of(1:6)

function colors(mask, t)
    i, j, k = t
    ((mask >> (idx[(i, j)] - 1)) & 1, (mask >> (idx[(i, k)] - 1)) & 1,
     (mask >> (idx[(j, k)] - 1)) & 1)
end

function mono_count(mask)
    c = 0
    for t in triples6
        a, b, d = colors(mask, t)
        c += (a == b == d)
    end
    return c
end

counts = [mono_count(mask) for mask in 0:(1 << 15)-1]
@assert all(counts .> 0)
@assert minimum(counts) == 2
first_min = findfirst(==(2), counts) - 1
@assert mono_count(first_min) == 2

c5(i, j) = ((j - i == 1) || (j - i == 4)) ? 1 : 0
c5mask = sum(c5(i, j) << (idx[(i, j)] - 1) for (i, j) in pairs6 if j <= 5)
for t in triples_of(1:5)
    a, b, d = colors(c5mask, t)
    @assert !(a == b == d)
end

parity(i, j) = (i + j) % 2
I7 = [1, 3, 5, 7]
J8 = [2, 4, 6, 8]
@assert all(parity(i, j) == 0 for (i, j) in pairs_of(I7))
@assert all(parity(i, j) == 0 for (i, j) in pairs_of(J8))
@assert all(parity(i + 2, j + 2) == parity(i, j) for (i, j) in pairs_of(I7))
@assert any(parity(i, j) == 1 for (i, j) in pairs_of([1, 2, 3]))

println("Julia：2^15 种六点对染色全部含齐一三元组；最少恰 2 个（经典事实）")
println("五点 C5 染色无齐一三元组 ⇒ 6 不能降为 5；平移 +2 保持偶点蓝图")
println("END ====")
```

三组实验。第一组：全部 $2^{15}$ 种六点对染色逐一统计齐一三元组
个数，断言恒正——这是定理 1.14 在「$\kappa=6$、双色」尺度的
穷举版；顺带验证经典加细「任何染色至少有**两个**单色三角形」。
第二组：五边形染色（相邻红、对角蓝）验证下确界，$R(3,3)=6$
两边同时封死。第三组：奇偶染色上 $\{1,3,5,7\}$ 与 $\{2,4,6,8\}$
两个齐一集**同蓝图**（所有对恒为偶），且 $\sigma:x\mapsto x+2$
保持一切二元取值——推论 1.5(1)「任何递增 $\omega$-列给出同一
理论」的有限影子；对照地 $\{1,2,3\}$ 混色不齐一。

## 95.19 机器通道六：Python——独立对拍

```python
# 第 95 章：与 Julia 独立对拍的 R(3,3)=6 穷举与平移/蓝图核对。
from itertools import combinations
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def main():
    print("==== 95")
    pairs = [(i, j) for i in range(6) for j in range(i + 1, 6)]
    idx = {p: k for k, p in enumerate(pairs)}
    triples = list(combinations(range(6), 3))

    def mono_count(mask):
        c = 0
        for (i, j, k) in triples:
            if ((mask >> idx[(i, j)]) & 1) == ((mask >> idx[(i, k)]) & 1) \
               == ((mask >> idx[(j, k)]) & 1):
                c += 1
        return c

    counts = [mono_count(m) for m in range(1 << 15)]
    assert all(c > 0 for c in counts)
    assert min(counts) == 2
    witness = counts.index(2)
    assert mono_count(witness) == 2

    def c5(i, j):
        d = (i + 5 - j) % 5 if i != j else 0
        return 1 if d in (1, 4) else 0

    mask5 = 0
    for (i, j) in [(i, j) for i in range(5) for j in range(i + 1, 5)]:
        if c5(i, j):
            mask5 |= 1 << idx[(i, j)]
    for t in combinations(range(5), 3):
        i, j, k = t
        vals = ((mask5 >> idx[(i, j)]) & 1,
                (mask5 >> idx[(i, k)]) & 1,
                (mask5 >> idx[(j, k)]) & 1)
        assert len(set(vals)) > 1

    parity = lambda i, j: (i + j) % 2
    A = [0, 2, 4, 6]
    B = [1, 3, 5, 7]
    assert all(parity(i, j) == 0 for i, j in combinations(A, 2))
    assert all(parity(i, j) == 0 for i, j in combinations(B, 2))
    assert all(parity(i + 2, j + 2) == parity(i, j) for i, j in combinations(A, 2))
    assert any(parity(i, j) == 1 for i, j in combinations([0, 1, 2], 2))

    print("Python：32768 种染色全含齐一三元组，最少 2 个；C5 无齐一三元组")
    print("偶点集与奇点集同蓝图（恒 0），平移 +2 保蓝图；混合集 {0,1,2} 不齐一")
    print("END ====")


if __name__ == "__main__":
    main()
```

与 Julia 的分工：枚举机制（`itertools.combinations` 对显式掩码
循环）、坐标约定（0 基对 1 基）、下界反例的模运算写法全部独立；
三组断言数值一致（全正、最小值 2、五点反例、平移不变）。两通道
互为对拍，与第 94 章「Julia/Python 各自穷举有限超滤」的协议相同。

## 95.20 机器通道七：Prolog——蓝图一致性与平移查询

```prolog
:- encoding(utf8).
% 第 95 章：奇偶染色上的齐一三元组搜索、蓝图一致性与平移保持。

color(I, J, C) :-
    I < J, S is (I + J) mod 2,
    (   S =:= 0 -> C = red ; C = blue ).

triple_hom(X, Y, Z) :-
    between(1, 8, X), between(1, 8, Y), between(1, 8, Z),
    X < Y, Y < Z,
    color(X, Y, C), color(X, Z, C), color(Y, Z, C).

% I 的全部递增二元组同色，P 为该共同颜色（蓝图的一元观察）。
pattern(I, P) :-
    findall(C, (member2(I, X, Y), color(X, Y, C)), Cs),
    Cs \= [],
    same_color(Cs, P).

member2(L, X, Y) :-
    append(_, [X | R], L), member(Y, R).

same_color([C], C).
same_color([C | Cs], C) :- same_color(Cs, C).

main :-
    format("==== 95~n"),
    findall(X-Y-Z, (between(1,6,X), triple_hom(X,Y,Z), Y =< 6, Z =< 6), Hom6),
    length(Hom6, N6),
    member(1-3-5, Hom6), member(2-4-6, Hom6),
    pattern([1,3,5], red),
    pattern([2,4,6], red),
    pattern([3,5,7], red),
    \+ pattern([1,2,3], _),
    forall((member2([1,3,5], X, Y), X1 is X+2, Y1 is Y+2),
           (color(X,Y,C), color(X1,Y1,C))),
    format("1..6 内齐一三元组共 ~w 个，含 1-3-5 与 2-4-6~n", [N6]),
    writeln("蓝图：{1,3,5}、{2,4,6}、{3,5,7} 同为恒红；{1,2,3} 红蓝混合不齐一"),
    writeln("平移 +2 保持 {1,3,5} 的全部二元取值（嵌入无歧义的影子）"),
    writeln("END ====").
```

`pattern/2` 是「蓝图提取」的查询化：递增二元组的颜色表全同则
给出共同颜色。三个齐一集 $\{1,3,5\}$、$\{2,4,6\}$、
$\{3,5,7\}$ 查询出**同一**蓝图 `red`，正是引理 1.26「蓝图被
不可辨别集唯一决定」在单公式语言、八点全集上的形态；
`\+ pattern([1,2,3], _)` 的失败查询给出非齐一反例；最后的
`forall` 检查 $\sigma=+2$ 保持全部二元取值——定理 1.17
(3)→(1) 平移构造的「无歧义」一步。注意 $N6=2$：奇偶染色在
1..6 内恰有两个齐一三元组，与 95.18 报告的最小值情形同构。

## 95.21 机器的边界

本章的机器件全部是有限影子，边界比前几章更醒目：

1. **0# 本体不可机化**。0# 是
   $(L_{\aleph_\omega},E,\aleph_1,\aleph_2,\ldots)$ 的完全理论，
   一个定义在不可数结构上的实数。它的存在性等价于非平凡
   $j:L\to L$，超出 ZFC；任何定理证明器中都只能作为公理或
   假设进入。
2. **无限 Ramsey 缺席**。mathlib 4.33.1 无 $\kappa\to(\kappa) ^{<\omega}_{<\kappa}$ 的任何形式；定理 1.14 的穷举替代只覆盖
   $R(3,3)=6$ 这一个数据点。引理 1.15 的「块切割 + 公共高块」
   两个零件中，机器只证明传递内核。
3. **蓝图三条件是语句模式**。有秩、无界、神奇条件都是「对每个
   斯科伦项 $t$，蓝图含语句 $\ldots$」的 schema，其量化域是
   可数无穷的项集与不可数的序型；95.14–95.20 中的「蓝图」只是
   一张有限的长度→值表。
4. **精细账未形式化**。95.6 的坍缩归位记账（引理 1.12(i) 的
   机制）依赖 $L_\lambda$ 层级与凝聚化，全部超出有限模型的
   表达力；正文按引擎 + 骨架给出，机器不碰。

因此任何 `PASS` 只见证：染色齐一性的穷举事实、封闭律与平移不变
性的有限形式、蓝图表的计算一致性。

## 95.22 本章要点与检查问题

- **主线**：$j:V\to M$ ⟹ $j\upharpoonright L:L\to L$ ⟹
  $L_\lambda$ 的不可数不可辨别元（Kunen 构造）⟹ EM 蓝图 ⟹
  0#；拉姆齐基数从另一端供给不可辨别元。四条等价（定理 1.17）把
  嵌入、片段嵌入、不可辨别元、蓝图缝成一个概念。
- **三条管道**：$L$-超滤子与超幂（95.3，外部构造的危险与因子
  映射的救赎）；$U$-阶梯与逐点固定引擎（95.5–95.6，
  $|\lambda\cap U_\alpha|=\lambda$ 是全部燃料）；EM 三条件
  （95.9：有秩管良基、无界管高度、神奇管前段信息）。
- **Silver 定理**：蓝图唯一，Silver 类 $I$ 无界闭、含全部
  不可数基数、每个 $L_\kappa$ 的元素都 $I\cap\kappa$-可定义
  ——$L$ 的「真相」被一个实数 0# 完全记账。
- **后果**：$\aleph_1^L$ 可数；不可数基数在 $L$ 中不可达；
  $0\#\notin L$、$I\cap\omega_1\notin L$；$a\#$ 把理论
  相对化到 $L[a]$ 与 $L(a)$。

检查问题：

1. 定理 1.12 的证明里，为什么取 $M$ 时生成元必须包含**全部**
   $s<\kappa$ 而不只是 $\kappa$？如果只取 $\kappa$，哪一步
   会失去 $g_n$ 与 $f_n$ 在 $\kappa$ 上逐点相等？
2. 引理 1.15 的证明中，「块切割」与「公共高块」分别承担什么？
   把块切割换成「对全体 $k$-子集鸽笼」为什么不够？
3. 推论 1.5(3) 的证明用了**下移**保序映射；定理 1.17(3)→(1)
   只需要上移。为什么压参数进 $I\cap\omega_1$ 必须用下移，
   而构造 $j:L\to L$ 用上移即可？

---

上一章：[94 可测基数、正规超滤子与超幂](94-measurable.md) · 下一章：[96 Jensen 覆盖引理](96-covering.md)
