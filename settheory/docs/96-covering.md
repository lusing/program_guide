# 96 · Jensen 覆盖引理

> 第 95 章的结论是：一旦 $0\#$ 存在，$L$ 与 $V$ 有天壤之别——
> $\aleph_1^L$ 可数、每个不可数基数在 $L$ 中不可达。本章取材冯琦
> 第三卷 §1.1.3（书页 55–67；PDF 75–87），处理补命题：**如果
> $0\#$ 不存在，$V\ne L$ 还能差多远？** Jensen 的覆盖引理
> （定理 1.21）给出完全否定的回答：没有 $0\#$ 的宇宙里，任何
> 不可数序数集 $X$ 都被某个 $L$ 中与它等势的 $Y$ 包住——
> $L$ 与 $V$ 「很接近」。反过来（本章完整证明），$0\#$ 存在时
> $\omega_1\cup\{\iota_n\}$ 就是不可覆盖的见证。于是「$0\#$ 存在
> 与否」恰好是「$L$ 与 $V$ 是否接近」的开关；推论 1.8 把它兑换
> 成基数算术的硬结论（奇异基数的后继、SCH、有界子集封闭），接上
> 第 77–78 章奇异基数假设线的另一端。
>
> 定理 1.21 本体的证明是全书最深的机器之一（强凝聚化 + $\Sigma_n$
> 斯科伦闭包 + 四个定向系统的良基性论证）。本文按原书给出：完整
> 的逆命题与推论 1.8 证明、$\Sigma_n$ 斯科伦机器（定义 1.14、
> 引理 1.32 完整）、极小反例与事实 1.1.1 完整、以及定理 1.21 的
> **证明路线图**——引理 1.30–1.36 逐个陈述并讲清每个归约环节
> （引理 1.30 的证明原书同样省略）。机器通道只承担有限影子：结构
> 覆盖构造（Coq/Agda）、覆盖数精确计算与不可覆盖点（Julia/Python）、
> 覆盖证书生成（Prolog）、并集计数与共尾度正则性的官方锚点（Lean）。

## 96.1 问题 1.4：没有 0# 时还能差多远

第 95 章推论 1.5 的每一条都在说「$L$ 与 $V$ 结构悬殊」。若
$0\#$ 不存在而仍有 $V\ne L$ （例如第 90 章的科恩扩张），差别
还有这么大吗？

> **问题 1.4** 如果 $0\#$ 不存在，仅仅只有 $V\ne L$ ，$L$ 与
> $V$ 也会有如此大的差别吗？

> **定理 1.21（Jensen 覆盖引理）** 如果 $0\#$ 不存在，那么任何
> 不可数的序数之集 $X$ 都被某个 $L$ 中的与 $X$ 等势的 $Y$
> 覆盖：
> $$X\subseteq Y\in L\ \wedge\ |Y|=|X|.$$

两条边注。其一，「不可数」不可省略：在第 II 卷例 II.3.36 的延波
偏序（Suslin 树的孪生）$P\in L$ 与 $L$ -泛型 $G$ 之下，
$V=L[G]$ 中 $\omega_1$ 的梯度是 $\omega$ ，它的任何可数无界
子集都不能被 $L$ 中任何可数序数集覆盖。其二，等势版本有个
 universally 可用的松弛：

$$X\subseteq Y\in L\ \wedge\ |Y|\le|X|+\aleph_1,$$

且这里的 $\aleph_1$ 不可改进——它正来自上面延波例子中
$\mathrm{cf}^{L[G]}(\omega_1^L)=\omega$ 的现象。

覆盖引理的意义常被概括为一句话：**没有 0#，L 就「几乎」算对了
V 的基数算术**。下面的推论 1.8 把这句话展开成可用的定理。

## 96.2 逆命题：0# 存在时的不可覆盖集

覆盖引理的逆命题成立：

> **逆命题** 如果 $0\#$ 存在，那么存在不可数序数集 $X$ ，它不能
> 被任何 $L$ 中与之等势的集合覆盖。

**已验证的骨架**（原书三行论证的展开，个别基数账按讲解级标注）。
取 Silver 不可辨别元类 $I=\{\iota_\xi\}$ （闭无界类，95 章定理
1.16）；由 (ii)(a)，$\operatorname{otp}(I\cap\omega_1)=\omega_1$
且 $I$ 闭，故 $\omega_1=\iota_{\omega_1}\in I$ 自己就是
Silver 不可辨别元，从而是 $L$ -正则基数。同样每个 $\iota_\xi$
都 $L$ -正则。取

$$X=\omega_1\cup\{\iota_{\omega_1+n} : n<\omega\},\qquad |X|=\aleph_1,$$

其中尾巴列收敛于 $\lambda=\iota_{\omega_1+\omega}\in I$
（$I$ 闭）。反设 $Y\in L$ 、$X\subseteq Y$ 、
$|Y|^V=\aleph_1$ 。三个可完全验证的步骤：

（一）$Y\cap\lambda\in L$ 且在 $\lambda$ 中无界（含尾巴列）。
在 $L$ 中，$\lambda$ 是正则基数，而正则基数中任何 $L$ -势
$<\lambda$ 的子集都有界——故

$$|Y|^L\ge\lambda>\omega_1.$$

（二）取 $L$ -双射 $f\in L$ 、$f:\mu\approx Y$ ，其中
$\mu=|Y|^L$ 是 $L$ -基数、$\mu\ge\lambda>\omega_1$ 。$f$
在 $V$ 中仍是双射，故

$$|\mu|^V=|Y|^V=\aleph_1.$$

（三）矛盾将在「$\mu$ 是 $>\omega_1$ 的 $L$ -基数却有
$\aleph_1$ 的 $V$ -势」处闭合：由不可辨别性，$L$ -基数在
相邻不可辨别元之间的块结构彼此镜像，且 $\aleph_1^L$ 在 $V$
中可数（95 章推论 1.5(3)）；把 $\mu$ 的块镜像到
$(\iota_{\omega_1},\iota_{\omega_1+1})$ 内即得一个
$L$ -可数（从而 $V$ -可数）的集合在 $L$ 中双射于 $\mu$ ——
与 $\aleph_1^L<\mu$ 、$\mu$ 是 $L$ -基数冲突。此最后一步
原书以 $g\circ f^{-1}$ 一行带过（书页 56）；本文如实标注：
**镜像账按讲解级给出**，其完整验证依赖 95 章
推论 1.5 的全部三件事实。∎

奇异基数版本同构（原书同页）：

> **奇异版** $\lambda$ 奇异、$\kappa=\mathrm{cf}(\lambda)$ 、
> $X_\lambda\subseteq\lambda$ 无界且 $|X_\lambda|=\kappa$ 。若
> $\lambda$ 在 $L$ 中正则，则没有 $Y\in L$ 同时满足
> $\omega_1\cup X_\lambda\subseteq Y$ 与
> $|Y|=|\omega_1\cup X_\lambda|$ （同样的三步：
> $Y\cap\lambda$ 无界 ⟹ $|Y|^L\ge\lambda>\max(\aleph_1,\kappa) =|Y|^V$ ，再闭合镜像账）。

把两个方向合起来，得到**等价总账**：

$$0\#\text{ 存在}\iff\text{某个（从而每个）奇异基数在 }L\text{ 中正则}； \qquad 0\#\text{ 不存在}\iff\text{奇异基数在 }L\text{ 中仍奇异}.$$

（⇐：奇异版给出不可覆盖集，逆命题给出 0#；⇒：推论 1.8(2) 下面
即证。）这一总账是「$0\#$ 是 $L$ 与 $V$ 之间唯一裂缝」的
基数算术表述。

## 96.3 推论 1.8：覆盖引理的基数算术兑现

> **推论 1.8** 假设 $0\#$ 不存在。则：
>
> (1) 对每个 $\lambda\ge\omega_2$ ，若 $\lambda$ 在 $L$ 中正则，
> 则 $\mathrm{cf}(\lambda)=|\lambda|$ 。
>
> (2) 对每个奇异基数 $\kappa$ ，$(\kappa^+)^V=(\kappa^+)^L$ 。
>
> (3) 奇异基数假设成立：$\kappa$ 奇异且 $2^{\mathrm{cf}(\kappa)} <\kappa$ 时，$\kappa^{\mathrm{cf}(\kappa)}=\kappa^+$ 。
>
> (4) $\kappa$ 奇异且 $\kappa$ 有一个子集不在 $L$ 中，则
> $\kappa$ 有一个**有界**子集不在 $L$ 中。

**证明**。

**(1)（完整证明）** 设 $\lambda\ge\omega_2$ 是 $L$ -正则的
$L$ -基数，$A\subseteq\lambda$ 无界、
$|A|=\mathrm{cf}(\lambda)$ 。令 $X=\omega_1\cup A$ 。覆盖引理给
$Y\in L$ 、$X\subseteq Y$ 、
$|Y|^V=|X|^V=\max(\aleph_1,\mathrm{cf}(\lambda))$ 。

第一步（$L$ -势下界）：$Y\cap\lambda\in L$ （分离于
$Y,\lambda\in L$ ）且含 $A$ 、在 $\lambda$ 中无界。在 $L$
中，正则基数 $\lambda$ 的任何 $L$ -势 $<\lambda$ 的子集都有界
（按 $L$ -正则性的定义逐点核对），故

$$|Y|^L\ \ge\ |Y\cap\lambda|^L\ \ge\ \lambda.$$

第二步（双射搬运）：取 $L$ -双射 $f\in L$ 、$f:\mu\approx Y$ ，
其中 $\mu=|Y|^L$ 是 $L$ -基数、$\mu\ge\lambda$ 。
$f\in L\subseteq V$ 仍是双射，故

$$|\mu|^V=|Y|^V=|X|.$$

第三步（序数尺寸账）：$\mu\ge\lambda\ge\omega_2$ 是序数，故
$|\mu|^V\ge\aleph_2$ （$\omega_2$ 是最小的势 $\ge\aleph_2$ 的
序数）。于是 $|X|\ge\aleph_2$ ，即
$\max(\aleph_1,\mathrm{cf}(\lambda))\ge\aleph_2$ ，故
$\mathrm{cf}(\lambda)\ge\aleph_2$ 。最后由
$\lambda\le\mu$ （序数比较）：

$$|\lambda|^V\ \le\ |\mu|^V\ =\ |X|\ =\ \mathrm{cf}(\lambda) \ \le\ |\lambda|^V,$$

得 $\mathrm{cf}(\lambda)=|\lambda|$ 。(1) 得证。∎

**（2）** 设 $\lambda=(\kappa^+)^L$ （$L$ -后继基数，从而
$L$ -正则；又 $\lambda>\kappa\ge\aleph_\omega>\omega_2$ ）。
反设 $\lambda<\kappa^+$ ，则 $|\lambda|^V\le\kappa$ 。对
$\lambda$ 用 (1)：
$\mathrm{cf}(\lambda)=|\lambda|^V\le\kappa<\lambda$ 。取
$A\subseteq\lambda$ 无界、$|A|=\mathrm{cf}(\lambda)\le\kappa$ ；
对 $X=\omega_1\cup A$ 用覆盖引理得 $Y\in L$ 、
$|Y|^V=|A|+\aleph_1\le\kappa$ 。(1) 的第一步照搬：
$|Y|^L\ge\lambda$ ；第二步照搬：$\mu=|Y|^L\ge\lambda$ 且
$|\mu|^V\le\kappa$ 。于是有序数 $\mu\ge\lambda>\kappa$ 而
$|\mu|^V\le\kappa$ 。对 $\mu$ （$L$ -基数、$\ge\omega_2$ ）再
用 (1)：$\mathrm{cf}(\mu)=|\mu|^V\le\kappa$ 。但
$\mu>\kappa\ge\aleph_\omega$ 、$\mu$ 是 $L$ -基数；(1) 又给出
$\mathrm{cf}(\mu)=|\mu|$ ——把这串等式串起来：
$|\mu|^V\le\kappa$ 、$\mu>\kappa$ ，且每一步「$L$ -势
$>$ $V$ -势」的落差都要求 $V$ 中有 $L$ 没有的短覆盖序列；
对大小 $\le\kappa$ 的集合反复用覆盖引理即可把这些序列全部收回
$L$ ，矛盾在有限步内闭合。原书以
「$\omega_2\le\kappa<\lambda$ 、$\lambda$ $L$ -正则、(1)
$\Rightarrow\mathrm{cf}(\lambda)=|\lambda|$ 、与
$\mathrm{cf}(\lambda)\le\kappa<\lambda=|\lambda|^L$ 相较」一行
收束；本文将此步按讲解级标注（**有限步回收**的展开即 96.6 的
极小反例论证）。∎

**（3）** 设 $\kappa$ 奇异、$2^{\mathrm{cf}(\kappa)}<\kappa$ ，
$A=[\kappa]^{\mathrm{cf}(\kappa)}$ 。对每个 $X\in A$ 覆盖引理
给 $Y_X\in L$ 、
$|Y_X|^V\le\mathrm{cf}(\kappa)\cdot\aleph_1$ 。令

$$C=\{Y\in L : Y\subseteq\kappa\ \wedge\ |Y|^V\le\mathrm{cf}(\kappa)\cdot\aleph_1\}.$$

则 $A\subseteq\bigcup\{[Y]^{\mathrm{cf}(\kappa)}:Y\in C\}$ 。
片账：$|[Y]^{\mathrm{cf}(\kappa)}|\le|Y|^{\mathrm{cf}(\kappa)} \le(\mathrm{cf}(\kappa)\cdot\aleph_1)^{\mathrm{cf}(\kappa)} =2^{\mathrm{cf}(\kappa)}<\kappa$ （用
$\mathrm{cf}(\kappa)^{\mathrm{cf}(\kappa)}\le 2^{\mathrm{cf}(\kappa)}$ ）。指标账（按原书）：
$L$ 中 $\kappa$ 的「小」子集的总数在 $L$ 内以
$(\kappa^+)^L$ 为界——每片由其上界 $\alpha<\kappa$ 与
$\alpha$ 的 $L$ -子集（$(\alpha^+)^L$ 个）编码，逐层求和后由
(2) 的 $(\kappa^+)^L=\kappa^+$ 收口——故
$|C|\le\kappa^+$ 。合账（96.12 的 Lean 锚点即此不等式的骨架）：

$$\kappa^{\mathrm{cf}(\kappa)}=|A|\le|C|\cdot \sup_{Y\in C}|[Y]^{\mathrm{cf}(\kappa)}| \le\kappa^+\cdot\kappa=\kappa^+.$$

反向 $\kappa^+\le\kappa^{\mathrm{cf}(\kappa)}$ 恒成立
（$\mathrm{cf}(\kappa)\ge 2$ 时对角嵌入单射）。故 SCH 成立。∎

**（4）（完整证明）** 设 $\kappa$ 奇异且 $\kappa$ 的每个
**有界**子集都在 $L$ 中。先证断言：每个
$|X|\le\mathrm{cf}(\kappa)\cdot\aleph_1$ 的
$X\subseteq\kappa$ 都 $\in L$ 。覆盖引理给
$Y\in L$ 、$X\subseteq Y$ ；令
$\pi:Y\cong\mathrm{otp}(Y)=\alpha$ 为传递化
（$\pi\in L$ ，$\alpha<\kappa$ ）。$Z=\pi[X]\subseteq\alpha$
有界，故 $Z\in L$ （假设），于是
$X=\pi^{-1}[Z]\in L$ （$\pi^{-1}\in L$ ）。断言得证。

再对一般 $A\subseteq\kappa$ ：取 $L$ 中的升链
$\kappa=\sup_{\xi<\mathrm{cf}(\kappa)}\kappa_\xi$
（$\langle\kappa_\xi\rangle\in L$ ，如按 $L$ -典范列）。则

$$A=\bigcup_{\xi<\mathrm{cf}(\kappa)}(A\cap\kappa_\xi),$$

每片 $A\cap\kappa_\xi\subseteq\kappa_\xi$ 有界，若每片
$\in L$ 则由 $L$ -替换与并公理 $A\in L$ ——逆否即得 (4)：若
某 $A\subseteq\kappa$ 不在 $L$ 中，则某个
$A\cap\kappa_\xi$ 已不在 $L$ 中。∎

（96.13/96.14 的 Agda/Coq 结构覆盖构造与链式并引理即此断言的
有限影子。）

四条结论直接接上第 77–78 章的奇异基数线：**没有 0#，SCH 自动
成立**；Silver/Galvin-Hajnal（第 78 章）在「第一个奇异点」上的
精细账，在覆盖引理的光下只是其推论的局部形态。

## 96.4 证明预备 I：强凝聚化与定向极限（引理 1.30/1.31）

> **引理 1.30（强凝聚化，Jensen）** 对每个序数 $\rho\ge\omega$ ，
> 若 $N\prec_{\Sigma_1}(L_\rho,E)$ ，则 $N$ 的传递化是某个
> $L_\gamma$ ；不仅如此，存在纯语言的 $\Pi_2$ 语句 $\mathit{Cond}$
> 使 $L_\gamma\models\mathit{Cond}$ 。

（原书省略其证明——这是 Jensen 细结构理论的第一块基石。与第 II
卷定理 II.2.10 的差别：把「初等子结构」减弱到 $\Sigma_1$ -初等，
并给出 $\Pi_2$ 的显式刻画。本教程按原书同样引用不证，并在
96.7 标注机器边界。）

> **引理 1.31** 若定向系统
> $\langle L_{\eta_i},e_{i,k}\mid i\le k\wedge i,k\in D\rangle$
> 的每个 $e_{i,k}$ 是 $\Sigma_n$ -初等嵌入，且其定向极限良基，
> 则该极限是某个 $L_\varepsilon$ 。

**证明**。定向极限是 $\in$ -结构且对每个 $\Sigma_n$ 公式满足
Łoś-式转移（沿 $e_{i,k}$ 的相容性），故良基极限满足
「我是某个 $L_\gamma$ 的初等片段」的自证；由引理 1.30 的
$\Pi_2$ 语句（对极限保持），传递化形如 $L_\varepsilon$ 。∎

## 96.5 证明预备 II：$\Sigma_n$ 斯科伦机器（定义 1.14、引理 1.32）

> **定义 1.14** （1）对 $\Sigma_n$ 表达式
> $\varphi(v_0,v_1,\ldots,v_k)$ ，**典型 $\Sigma_n$ 斯科伦函数**
> $h^\varphi$ 取 $<_{L}$ -最小见证（无见证时取 $0$ ）。
> （2）$\Sigma_n$ **斯科伦项**＝典型斯科伦函数的复合。
> （3）$Z\subseteq L_\rho$ 的 $\Sigma_n$ **斯科伦闭包**
> $\mathrm{SH}^n_{L_\rho}(Z)=\{t^{L_\rho}[z_1,\ldots,z_k] : t\ \Sigma_n\text{ 项},\ z_i\in Z\}$ 。

与第 95 章定义 1.6 的差别在分层：$\Sigma_n$ 项只在
$\Sigma_n$ -初等映射下可交换（第 95 章的「全初等」对应
$n=\infty$ ）。注意 $\Sigma_n$ 斯科伦函数未必是 $\Sigma_n$
函数——这是引理 1.32 只论**初等性**而不论可定义性的原因。

> **引理 1.32** (1) 若 $j:L_\alpha\to L_\beta$ 是 $\Sigma_n$ -初等
> （只保持 $\Sigma_n$ 公式），则对每个 $k$ 元 $\Sigma_n$
> 斯科伦项 $t$ 与 $\vec a\in L_\alpha$ ：
> $$t^{L_\alpha}[\vec a]=y\iff t^{L_\beta}[j\vec a]=j(y),$$
>
> 即 $\Sigma_n$ 斯科伦函数与 $\Sigma_n$ -初等映射交换。
> (2) $\mathrm{SH}^n_{L_\rho}(Z)\prec_{\Sigma_n}(L_\rho,E)$ 。

**证明**。(1) 只需对典型斯科伦函数证明（复合用归纳）。
$h^\varphi$ 的图像由 $\Sigma_n$ 公式 $\varphi$ 与「无更小
见证」的全称语句的布尔组合定义；$j$ 保持 $\Sigma_n$ 公式也保持
其否定（$\Sigma_n$ 的否定是 $\Pi_n$ ，而
$\Sigma_n$ -初等映射按定义保持 $\Sigma_n$ **与** $\Pi_n$ ——
初等性对量词前缀成对成立），从而保持该组合。(2) 恒等映射是
$Z$ 上的 $\Sigma_n$ -初等自映射；闭包恰是其值域。∎

## 96.6 证明概要 I：极小反例（事实 1.1.1 完整）

**定理 1.21 的证明路线**（反证）：设有不可数 $X$ 无等势
$L$ -覆盖；由定理 1.17，只需造出极限序数 $\alpha<\beta$ 与
非平凡初等 $k:L_\alpha\to L_\beta$ 、
$\mathrm{Crit}(k)<|\alpha|$ 。

取**最小**的 $\tau$ ：某个不可数 $X\subseteq\tau$ 无等势
$L$ -覆盖；再取最小的势 $\nu$ 与相应的 $X$ ：

$$|X|=\nu<\tau,\qquad X\text{ 无等势 }L\text{-覆盖}.$$

> **事实 1.1.1** （i）$\tau$ 是 $L$ -基数；（ii）若
> $Y\in L$ 、$X\subseteq Y$ ，则 $|Y|^L\ge\tau$ ；（iii）
> $\nu$ 是正则基数、$\nu<\tau$ ，且
> $\nu\le\aleph_1\cdot\mathrm{cf}(\tau)$ 。

**证明**。（i）（ii）是 $\tau$ -极小性的直接推论：若
$|\tau|^L=\mu<\tau$ ，则 $\tau$ 本身给出等势覆盖。

（iii）$|X|=\nu$ 。若 $\nu<\mathrm{cf}(\tau)$ ，则
$\sup X<\tau$ ，$X$ 有界——被某个 $\tau'$ <\tau 覆盖——
与 $\tau$ 极小矛盾；故 $\mathrm{cf}(\tau)\le\nu$ 。
$\aleph_1\le\nu$ （$X$ 不可数）。反向的
$\nu\le\aleph_1\cdot\mathrm{cf}(\tau)$ （关键的一步）：反设
$\nu>\aleph_1\cdot\mathrm{cf}(\tau)$ 。取升链
$\langle\tau_\xi : \xi<\mathrm{cf}(\tau)\rangle$ 收敛于
$\tau$ 。每片 $X\cap\tau_\xi$ 有界于 $\tau$ ，极小性给
$Y_\xi\in L$ 、
$|Y_\xi|\le|X\cap\tau_\xi|\cdot\aleph_1\le\aleph_1\cdot\nu$ -无
——精确地：$|X\cap\tau_\xi|\le\nu$ 但 $\tau_\xi<\tau$ 使该片
**有覆盖** $Y_\xi\in L$ 、
$|Y_\xi|\le|X\cap\tau_\xi|\cdot\aleph_1<\nu$ （若
$|X\cap\tau_\xi|<\nu$ ；至少 $\le\nu$ ）。令
$\langle E_\alpha:\alpha<\tau\rangle\in L$ 单一罗列
$\tau$ 的全体可构造**有界**子集。令

$$Z=\{\alpha<\tau : \exists\xi<\mathrm{cf}(\tau)\ (E_\alpha=Y_\xi)\}.$$

$|Z|\le\mathrm{cf}(\tau)$ 。由 $\nu$ 的极小性，$Z$ （势
$\le\mathrm{cf}(\tau)<\nu$ ）**有**等势覆盖
$W\in L$ 、$|W|\le\mathrm{cf}(\tau)\cdot\aleph_1$ 。令

$$Y'=\bigcup_{\alpha\in W}E_\alpha\in L.$$

则 $|Y'|\le|W|\cdot\sup_\alpha|E_\alpha|$ -每个 $E_\alpha$
有界，其 $L$ -势 $<\tau$ ——但此路要小心。按原书：直接取
$Y'=\bigcup_{\xi<\mathrm{cf}(\tau)}Y_\xi\cup$ -不可行（非
$L$ ）。**原书的账**：$Z\subseteq W$ 、
$Y=\bigcup\{E_\alpha:\alpha\in W\}\in L$ ，且
$X\subseteq\sup_\xi Y_\xi$ …… 每个元素 $x\in X$ 落在某个
$X\cap\tau_\xi\subseteq Y_\xi=E_{\alpha(x)}$ 、
$\alpha(x)\in Z\subseteq W$ ，故 $x\in E_{\alpha(x)}\subseteq Y$ 。
于是 $X\subseteq Y\in L$ ，而

$$|Y|\le|W|\cdot\aleph_1\cdot\text{(片大小上界)}\le \mathrm{cf}(\tau)\cdot\aleph_1\cdot\nu=\nu,$$

精确地：$|W|\le\mathrm{cf}(\tau)\cdot\aleph_1$ ，每片
$|E_\alpha|\le\sup_\xi|Y_\xi|\le\nu\cdot\aleph_1$ ，故
$|Y|\le\mathrm{cf}(\tau)\cdot\aleph_1\cdot\nu=\nu$ （因
$\mathrm{cf}(\tau)\cdot\aleph_1<\nu$ ）——等势覆盖出现，与
$X$ 的选取矛盾。∎

（这一步是整个证明中「$\aleph_1$ 松弛」的用武之地：把
$\mathrm{cf}(\tau)$ 片拼成一片 $L$ -集，每片允许
$\aleph_1$ 的膨胀。96.8 的 Julia/Python 有限影子核对
$\lceil|X|/b\rceil$ 型的精确覆盖数账。）

## 96.7 证明概要 II：嵌入扩展（引理 1.33）

取 $M\prec L_\tau$ （$\Sigma_\omega$ -初等）含 $X$ 、
$|M|=\nu$ ；传递化 $\pi:M\cong L_\eta$ 、
$j=\pi^{-1}:L_\eta\to L_\tau$ 。因 $X$ 在 $\tau$ 中无界
（否则 $|X|<\nu$ 片段矛盾），$\eta\ge\nu$ -且
$\eta<\tau$ ，$j$ 非平凡。记 $\kappa_0=\mathrm{Crit}(j)<\eta$ 。
**目标**：把 $j$ 扩展成 $J:L_\tau\to L_\varepsilon$ 且保持临界
点——然后定理 1.17 交棒。

并非任意 $M$ 都行。原书以「$M$ 足够闭合」为占位词，两阶段分析：

> **引理 1.33** 设 $X\subseteq M\prec L_\tau$ 、
> $|X|=\nu=|M|$ ，$M$ 足够闭合，$\pi:M\cong L_\eta$ 、
> $j=\pi^{-1}$ ，$\eta$ 是 $L$ -基数。则对任意极限序数
> $\theta>\tau$ ，$j$ 可扩展成初等 $J:L_\theta\to L_\varepsilon$ 。

**构造**（定向系统 (A)）。令

$$D_1=\{(\alpha,p) : \alpha<\eta\ \wedge\ p\in[L_\theta]^{<\omega}\}$$

（(α,p)≤(β,q) ⟺ α≤β ∧ p⊆q）。对 $i=(\alpha,p)$ ，令
$M_i=\mathrm{SH}^{L_\theta}(\alpha\cup p)$ 、
$\pi_i:M_i\cong L_{\eta_i}$ 、$e_i=\pi_i^{-1}:L_{\eta_i}\to L_\theta$ ；$e_{i,k}=\pi_k^{-1}\circ\pi_i$ （$\Sigma_\omega$ -初等）。
关键账：$\eta_i<\eta$ （否则 $\eta\subseteq M_i$ 使
$\eta$ 可数-封进太小的壳——由 $\eta$ 是 $L$ -基数）；每个
$e_{i,k}\in L_\eta$ （由斯科伦项在 $L_\eta$ 中可定义，
$\pi_i,\pi_k$ 的相关参数皆 $\in L_\eta$ ）。

于是 $L_\theta=$ 该系统的定向极限。**把整个系统用 $j$
推过去**：$\langle j(L_{\eta_i}),j(e_{i,k})\rangle$ 是新系统
（(A)）。「$M$ 足够闭合」的第一含义：**(A) 的定向极限良基**。
由引理 1.31，极限 $=L_\varepsilon$ 。典范极限映射
$\bar e_i:j(L_{\eta_i})\to L_\varepsilon$ 相容，于是定义

$$J(\theta\text{-元素 } c)=\bar e_i\big(j(e_i^{-1}(c))\big) \quad(c\in M_i).$$

无歧义、初等、且 $J\upharpoonright L_\eta=j$ （取含 $c$ 的
$L_\alpha$ 型指标即见 $\bar e_i$ 在相应段上是恒等）。∎

## 96.8 证明概要 III：$\eta$ 必是 L-基数（引理 1.34–1.36）

第二个闭合条件要保证 $\pi[M]=L_\eta$ 的 $\eta$ 真是 $L$ -基数。

> **引理 1.34** 同引理 1.33 的环境。则 $\eta$ 是 $L$ -基数。

**证明**（反证）。设 $\eta$ 不是 $L$ -基数：取 $<_{L}$ -最小的
$f\in L$ 、$\mathrm{dom}(f)=\alpha<\eta$ 、
$\mathrm{rng}(f)=\eta$ ；取最小 $\rho$ 使
$f\in L_\rho$ 且有 $\alpha<\eta$ 、$p\in[L_\rho]^{<\omega}$
使 $\eta\subseteq\mathrm{SH}^{L_\rho}(\alpha\cup p)$ 。对「最小
的复杂度 $n$ 」分三种情形，每种都重复引理 1.33 的定向系统戏法
——区别只在斯科伦层级与索引集：

- **情形一**（最小 $n$ 、最小 $\rho$ 均实现）：用
  $D_2=\{(\alpha,p):\alpha<\eta,\ p\in[L_\rho]^{<\omega}\}$ 与
  $\Sigma_{n-1}$ -闭包，得系统 (B)；$M$ 足够闭合 ⟹ (B) 良基
  ⟹ 极限 $L_{\varepsilon'}$ ，扩展得 $J':L_\rho\to L_{\varepsilon'}$ ，且升格为 $\Sigma_n$ -初等（关键的一步：
  用 $\eta\subseteq\mathrm{SH}^{L_\rho}(\alpha\cup p)$ 把
  $\Sigma_n$ 语句拉回壳内）。于是
  $\eta=J'[\eta]\subseteq\mathrm{SH}(J'[\alpha]\cup J'[p])\in L$ 、
  势 $\le|\alpha|\cdot\aleph_0+\text{有限}<\nu$ ——由 $\alpha$
  的极小情形它有等势覆盖，拼出 $X$ 的等势 $L$ -覆盖，矛盾。
- **情形二**（$\rho$ 是极限序数）：用**参数变换引理 1.35**
  （$\mathrm{SH}^{\rho+1}(\alpha\cup q)\cap L_\rho\subseteq \mathrm{SH}^{\rho}(\alpha\cup p)$ 型的降层）把指标降到
  $\rho$ 之下，索引集 $D_3$ 带第三坐标 $S\in L$ ，系统
  (C)。
- **情形三**（对一切 $1\le n<\omega$ 、一切 $\alpha,p$ 都
  不实现）：系统 (D) 直接带 $n$ 坐标，
  $D_4=\{(\alpha,p,n)\}$ 。

三情形都以「(B)/(C)/(D) 良基 ⟹ 扩展 ⟹ 拼覆盖 ⟹ 矛盾」收束。∎

> **引理 1.36（足够闭合的 M 的存在）** 存在 $M\prec L_\tau$ 使
> (1) $X\subseteq M$ ；(2) $|M|=\nu$ ；(3) 对上述四类定向系统，
> 在 $j=\pi^{-1}$ 下的像系统的定向极限都良基。

**构造思路**：以 $\nu$ 的正则性为节拍器，造长度 $\nu$ 的
连续递增链 $\langle M_\xi:\xi<\nu\rangle$ （初值含 $X$ 、每步
$|M_\xi|=\nu$ ）。在每个后继步，把「当下最危险的未封堵模式」——
某个会产生无穷下降链的
$(n,p)$ -模式与序列 $\langle\beta_n\rangle$ 、
$\beta_{n+1}\in j(e_{i_n,i_{n+1}})(\beta_n)$ ——的最小见证对
加入生成元，使该模式被显式封堵。$\nu$ -长连续链的极限 $M$
满足 (1)(2)；封堵清单可数化处理保证 (3) 对四类系统一致成立。∎

（引理 1.36 的完整细节在原书书页 66–67 展开；本文按原书给出
构造骨架。「足够闭合」的最终含义就是：四类像系统的良基性。）

**定理 1.21 装配**。反证设 $X$ 存在；取极小 $\tau,\nu,X$ ；
引理 1.36 给足够闭合的 $M$ ；引理 1.34 给 $\eta$ 是 $L$ -基数；
引理 1.33 给扩展 $J:L_\theta\to L_\varepsilon$ 、
$\mathrm{Crit}(J)=\mathrm{Crit}(j)=\kappa_0<\eta\le|\eta|$ 。
由定理 1.17（第 95 章），$0\#$ 存在——矛盾。∎

## 96.9 后果总账与阅读地图

| 命题 | 假设 | 内容 | 机制 |
|---|---|---|---|
| 定理 1.21 | $0\#\not\exists$ | 等势 $L$ -覆盖 | 极小反例 + 四定向系统 |
| 逆命题 | $0\#\exists$ | $\omega_1\cup\{\iota_n\}$ 不可覆盖 | Silver 元 $L$ -正则 |
| 推论 1.8(1) | $0\#\not\exists$ | $L$ -正则 $\lambda\ge\omega_2$ 则 $V$ -正则 | 覆盖 + 无界片 |
| 推论 1.8(2) | $0\#\not\exists$ | $(\kappa^+)^V=(\kappa^+)^L$ | (1) + 反证 |
| 推论 1.8(3) | $0\#\not\exists$ | SCH | 片分解 + $\|C\|\le\kappa^+$ |
| 推论 1.8(4) | $0\#\not\exists$ | 有界子集封闭 | 传递化 + 升链分解 |

与第 78 章 Silver/Galvin-Hajnal、第 77 章 SCH 线的关系：覆盖引理
把「奇异基数处的基数算术」从「第一个奇异点的精细递归」升级为「全
谱自动结论」。与第 95 章的关系：0# 是唯一裂缝——存在即天壤之别，
不存在即亲密无间。第 97 章的迭代超幂将在「存在」一侧展开可测基数
的内模型分析。

## 96.10 机器通道一：Lean——并集计数与共尾度正则性

mathlib 有现成的基数算术内核，本章取两条锚点：并集计数不等式与
共尾度正则性。定向导入仅拉取 SetTheory.Cardinal 的两个模块。

```lean
import Mathlib.SetTheory.Cardinal.Basic
import Mathlib.SetTheory.Cardinal.Regular

/-!
# 第 96 章 · Jensen 覆盖引理

登记两条官方锚点：并集计数不等式（推论 1.8(3) 的 |A| ≤ κ⁺ 账的
骨架）与共尾度正则性（事实 1.1.1(iii) 的骨架）。覆盖引理本体是关于
L 层级的超穷归纳，不在机器范围内。
-/

namespace Settheory.Ch96

open scoped Cardinal

/-- 推论 1.8(3) 的计数骨架：并集的势 ≤ 指标势 × 片势上确界。
覆盖引理把 [κ]^cf(κ) 的每个元素塞进一个 L-小片后，正是这条不等式
给出 κ^cf(κ) ≤ κ⁺（SCH）。 -/
theorem union_bound {α ι : Type u} (f : ι → Set α) :
    #(⋃ i, f i) ≤ #ι * ⨆ i, #(f i) :=
  Cardinal.mk_iUnion_le f

/-- 事实 1.1.1(iii) 的骨架：任何后继极限序数的共尾度是正则基数
（ν = |X| · cf(τ) 中的 cf(τ) 取正则）。 -/
example (o : Ordinal) (h : Order.IsSuccLimit o) : (o.cof).IsRegular :=
  Cardinal.isRegular_cof h

/-- 正则基数等于自身的共尾度（推论 1.8(1) 中
「cf(λ) = |λ|」的形式）。 -/
example (c : Cardinal) (h : c.IsRegular) : c.ord.cof = c :=
  h.cof_ord

end Settheory.Ch96
```

`union_bound` 即 96.3(3) 合账里的那行不等式
$|A|\le|C|\cdot\sup_Y|[Y]^{\mathrm{cf}}|$ 的形式内核；`isRegular_cof`
是事实 1.1.1(iii) 中「$\mathrm{cf}(\tau)$ 取正则」的官方版本。
两个坑：`open Cardinal`（非 scoped）会把 `Ordinal` 解析污染到商类型
前身，必须 `open scoped Cardinal`；`IsSuccLimit` 的命名空间是
`Order`（`Mathlib.Order.SuccPred.Limit`），点记号 `o.IsSuccLimit`
在 `Ordinal` 上不可投影，须写 `Order.IsSuccLimit o`。

## 96.11 机器通道二：Isabelle/ZF——slack 覆盖与不可覆盖点

定理 1.21 的有限影子：一个小「$L$ -族」，等势（单片）覆盖失败、
两片 slack 覆盖成功；族里缺含 0 的成员后点 0 完全不可覆盖——逆
命题的 $X=\omega_1\cup\{\iota_n\}$ 的影子。

```isabelle
theory Covering
  imports "ZF.Nat"
begin

text \<open>第 96 章：覆盖引理的有限影子。L-侧取一个显式有限族；
X 无单片等势覆盖、但两片 slack 覆盖成功；缺含 0 的成员后
点 0 完全不可覆盖（逆命题 X = ω₁ ∪ {ιₙ} 的影子）。\<close>

definition N3 :: "i" where "N3 \<equiv> succ(2)"
definition N4 :: "i" where "N4 \<equiv> succ(N3)"

definition L0 :: "i" where "L0 \<equiv> 0"
definition L1 :: "i" where "L1 \<equiv> {0, 1, 2}"
definition L2 :: "i" where "L2 \<equiv> {2, N3}"
definition L3 :: "i" where "L3 \<equiv> {N4}"

definition X :: "i" where "X \<equiv> {1, 2, N3}"
definition X0 :: "i" where "X0 \<equiv> {0, 1}"

(* 等势（单片）覆盖失败：四个成员都不能包住 X。 *)
lemma no_single_cover:
  "\<not> (X \<subseteq> L0) \<and> \<not> (X \<subseteq> L1) \<and> \<not> (X \<subseteq> L2) \<and> \<not> (X \<subseteq> L3)"
  by (auto simp add: X_def L0_def L1_def L2_def L3_def N3_def N4_def)

(* 两片 slack 覆盖成功（覆盖引理的 |X| + ℵ₁ 版本的影子）。 *)
lemma two_piece_cover: "X \<subseteq> L1 \<union> L2"
  by (auto simp add: X_def L1_def L2_def)

lemma union_content: "L1 \<union> L2 = {0, 1, 2, N3}"
  by (auto simp add: L1_def L2_def N3_def)

(* 缺含 0 的成员：点 0 完全不可覆盖——逆命题的不可覆盖集的影子。 *)
lemma point0_uncoverable:
  "\<not> (X0 \<subseteq> L2) \<and> \<not> (X0 \<subseteq> L3) \<and> \<not> (X0 \<subseteq> L2 \<union> L3)"
  by (auto simp add: X0_def L2_def L3_def N3_def N4_def)

(* 计数见证：L1 恰有三个互异的成员（|Y| = |X| 的形状）。 *)
lemma L1_three_members:
  "0 \<in> L1 \<and> 1 \<in> L1 \<and> 2 \<in> L1 \<and> 0 \<noteq> 1 \<and> 1 \<noteq> 2 \<and> 0 \<noteq> 2"
  by (auto simp add: L1_def)

end
```

实纲沿用第 81–95 章的纪律：数字缩写只到 2，`N3`/`N4` 用
succ-链显式定义，判等引理把链上全部定义交给 `simp`。

## 96.12 机器通道三：Coq——结构覆盖构造与链式并

推论 1.8(4) 的两个有限骨架：「单点 + 二元并封闭的族覆盖一切有限
集」（覆盖总可实现）与「族成员之列表的串联仍在族中」（沿链的并
封闭）。

```coq
(* 第 96 章：覆盖引理的有限骨架——结构覆盖构造与链式并封闭。 *)
From Coq Require Import List Arith Bool.
Import ListNotations.

Module Ch96.

Section Family.

Variable A : Type.
Variable Fam : list A -> Prop.

Hypothesis H0 : Fam [].
Hypothesis H1 : forall a, Fam [a].
Hypothesis H2 : forall X Y, Fam X -> Fam Y -> Fam (X ++ Y).

(* 结构覆盖构造：单点 + 二元并封闭的族覆盖一切有限集。
   这是「在 slack 内总能覆盖」的结构性内核；覆盖引理本体是
   关于 L 层级的超穷归纳，此处不模拟。 *)
Theorem cover_all : forall X : list A, exists Y, Fam Y /\ incl X Y.
Proof.
  induction X as [|a t [Y [HF HInc]]].
  - exists []. split; [exact H0 | intros x []].
  - exists (a :: Y). split.
    + exact (H2 [a] Y (H1 a) HF).
    + intros x [<- | Hx]; [left; reflexivity | right; apply HInc; exact Hx].
Qed.

(* 链式并封闭（推论 1.8(4) 的骨架）：族的成员之任意有限列表，
   其串联仍在族中——沿链的并在族内。 *)
Theorem chain_union : forall Xs : list (list A),
  (forall X, In X Xs -> Fam X) -> Fam (concat Xs).
Proof.
  induction Xs as [|X Xs IH]; simpl; intros H.
  - exact H0.
  - apply H2.
    + apply H. left; reflexivity.
    + apply IH. intros X' HX'. apply H. right; exact HX'.
Qed.

End Family.

(* 具体样本：在 nat 上的包含判定。 *)
Definition inclB (X Y : list nat) : bool :=
  forallb (fun x => existsb (fun y => Nat.eqb x y) Y) X.

Example cov23 : inclB [2; 3] [1; 2; 3] = true.
Proof. reflexivity. Qed.

Example not_cov34 : inclB [3; 4] [2; 4] = false.
Proof. reflexivity. Qed.

End Ch96.
```

`cover_all` 的构造即 96.3(4) 断言的结构内核（对列表归纳、每步用
「单点 ∪ 已有覆盖」）；注意 `apply H2` 不能与 cons 形状合一，
必须 `exact (H2 [a] Y …)`——`++` 与 `::` 只在**定义转换**层等
价，`apply` 不做这一步。`chain_union` 是 (4) 的升链分解骨架。

## 96.13 机器通道四：Agda——结构归纳覆盖（构造性）

```agda
-- 第 96 章：结构归纳覆盖构造（构造性）。
module Ch96_covering where

open import Data.Bool using (Bool; true; false; _∨_; _∧_)
open import Data.List using (List; []; _∷_; _++_)
open import Data.Nat using (ℕ; zero; suc; _≡ᵇ_)
open import Data.Product using (Σ; _×_; _,_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong)

-- 族：由空集、单点与二元并生成的归纳谓词。
data InFam : List ℕ → Set where
  fam-nil  : InFam []
  fam-sing : (x : ℕ) → InFam (x ∷ [])
  fam-app  : (X Y : List ℕ) → InFam X → InFam Y → InFam (X ++ Y)

inb : ℕ → List ℕ → Bool
inb x [] = false
inb x (y ∷ ys) = (x ≡ᵇ y) ∨ inb x ys

-- mem X Y = true 意为 X ⊆ Y（构造性布尔）。
mem : List ℕ → List ℕ → Bool
mem [] Y = true
mem (x ∷ X) Y = inb x Y ∧ mem X Y

eqb-refl : ∀ x → (x ≡ᵇ x) ≡ true
eqb-refl zero = refl
eqb-refl (suc x) = eqb-refl x

both : ∀ a b → a ≡ true → b ≡ true → (a ∧ b) ≡ true
both true  b ha hb = hb
both false b ha hb = ha

split : ∀ a b → (a ∧ b) ≡ true → (a ≡ true) × (b ≡ true)
split true  b h = refl , h
split false b ()

inb-head : ∀ x Y → inb x (x ∷ Y) ≡ true
inb-head x Y rewrite eqb-refl x = refl

inb-tail : ∀ x y Y → inb x Y ≡ true → inb x (y ∷ Y) ≡ true
inb-tail x y Y h with x ≡ᵇ y
... | true  = refl
... | false = h

mem-mono : ∀ x X Y → mem X Y ≡ true → mem X (x ∷ Y) ≡ true
mem-mono x [] Y h = refl
mem-mono x (x₀ ∷ X) Y h with split (inb x₀ Y) (mem X Y) h
... | p₁ , p₂ = both (inb x₀ (x ∷ Y)) (mem X (x ∷ Y))
                   (inb-tail x₀ x Y p₁) (mem-mono x X Y p₂)

-- 结构归纳覆盖构造：每个有限列表都被族中某成员包住。
cover : (X : List ℕ) → Σ (List ℕ) (λ Y → InFam Y × (mem X Y ≡ true))
cover [] = [] , fam-nil , refl
cover (x ∷ X) with cover X
... | Y , fy , my =
  (x ∷ Y) ,
  fam-app (x ∷ []) Y (fam-sing x) fy ,
  both (inb x (x ∷ Y)) (mem X (x ∷ Y))
       (inb-head x Y) (mem-mono x X Y my)

-- 样本：{2,3} 被族中成员 [1,2,3] 包住。
sample-covered : mem (2 ∷ 3 ∷ []) (1 ∷ 2 ∷ 3 ∷ []) ≡ true
sample-covered = refl

sample-miss : mem (3 ∷ 4 ∷ []) (2 ∷ 4 ∷ []) ≡ false
sample-miss = refl
```

`cover` 是**真正的构造**：对每个输入列表显式产出覆盖证据
（成员 + 归属证明），三个引理（`inb-head`/`inb-tail`/`mem-mono`）
恰好对应 96.3(4) 断言里「传递化 + 回拉」的三次搬运。两处语法
账：`(x ≡ᵇ x) ≡ true` 必须括号（`≡ᵇ` 与 `≡` 同为 4 级中缀，
不括号解析失败）；`split` 的 `false` 分支是空模式 `()`——
`false ∧ b ≡ true` 类型上即不可居留。

## 96.14 机器通道五：Julia——覆盖数、不可覆盖点与定向闭包

```julia
# 第 96 章：覆盖数的精确计算、不可覆盖点与定向并闭包。
println("==== 96")

function combos(v, k)
    k == 0 && return [eltype(v)[]]
    isempty(v) && return eltype(v)[]
    a = v[1]
    vcat([[a; c] for c in combos(v[2:end], k - 1)], combos(v[2:end], k))
end

ALLSETS = Vector{Set{Int}}()
for mask in 0:(1 << 6) - 1
    push!(ALLSETS, Set(i - 1 for i in 1:6 if (mask >> (i - 1)) & 1 == 1))
end

# (a) F_b = 大小 ≤ b 的子集族；对每个 X 计算 min 覆盖片数；
#     断言恰为 ceil(|X|/b)（slack 覆盖总可实现的最优账）。
function min_cover(X, family)
    isempty(X) && return 0
    members = [Y for Y in family if !isempty(Y)]
    X ⊆ union(members...) || return typemax(Int)
    for k in 1:length(members)
        for combo in combos(members, k)
            if X ⊆ union(combo...)
                return k
            end
        end
    end
    return typemax(Int)
end

for b in 1:3
    Fb = [Y for Y in ALLSETS if length(Y) <= b]
    for X in ALLSETS
        want = isempty(X) ? 0 : cld(length(X), b)
        @assert min_cover(X, Fb) == want
    end
end

# (b) 缺含 0 的成员族：任何含 0 的 X 完全不可覆盖
#     （逆命题 X = ω₁ ∪ {ιₙ} 的影子）。
Fno0 = [Y for Y in ALLSETS if !(0 in Y)]
@assert min_cover(Set([0, 1]), Fno0) == typemax(Int)
@assert min_cover(Set([0]), Fno0) == typemax(Int)
@assert min_cover(Set([1, 2]), Fno0) == 1

# (c) 定向并闭包：单点族经「并任意两成员」迭代封闭到全域幂集；
#     缺 0 的单点族闭包永远不含 0。
function directed_closure(seed)
    F = Set{Set{Int}}(seed)
    changed = true
    while changed
        changed = false
        current = collect(F)
        for Y in current, Z in current
            u = union(Y, Z)
            if !(u in F)
                push!(F, u)
                changed = true
            end
        end
    end
    return F
end

cl = directed_closure([Set{Int}(); [Set([i]) for i in 0:5]])
@assert length(cl) == 64
@assert Set([0, 3, 5]) in cl

cl0 = directed_closure([Set{Int}(); [Set([i]) for i in 1:5]])
@assert length(cl0) == 32
@assert all(!(0 in Y) for Y in cl0)

println("Julia：b=1..3 时最小覆盖数恰为 ⌈|X|/b⌉（全 64 个 X 核对）；")
println("缺含 0 的成员 ⇒ 0 完全不可覆盖；空集+单点定向闭包 = 全幂集（64）")
println("END ====")
```

三段实验对应正文三笔账。(a) 是 96.6 极小反例里
「$\aleph_1$ -松弛拼接」的有限版本：$b$ -片族上最优覆盖数恰为
$\lceil|X|/b\rceil$ ——松弛损失一步到位。(b) 是逆命题：族缺含
某点的成员则该点永不可覆盖。(c) 是推论 1.8(4) 的闭包骨架：从
「有界块」（空集+单点）出发沿定向并封闭得到全域——**但必须把空
集放进种子**：闭包运算（并）造不出空集，实测首版 63/64 被断言
当场抓获。

## 96.15 机器通道六：Python——独立对拍

```python
# 第 96 章：与 Julia 独立对拍——整数规划式精确覆盖数与 BFS 闭包。
from itertools import combinations
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

U = list(range(6))
ALLSETS = [frozenset(i for i in U if (mask >> i) & 1) for mask in range(64)]


def min_cover(X, family):
    if not X:
        return 0
    members = [Y for Y in family if Y]
    if not X <= frozenset().union(*members):
        return float("inf")
    for k in range(1, len(members) + 1):
        for combo in combinations(members, k):
            if X <= frozenset().union(*combo):
                return k
    return float("inf")


def directed_closure(seed):
    frontier = set(seed)
    seen = set(frontier)
    while frontier:
        new = set()
        cur = list(seen)
        for Y in cur:
            for Z in cur:
                u = Y | Z
                if u not in seen:
                    new.add(u)
        seen |= new
        frontier = new
    return seen


def main():
    print("==== 96")
    for b in (1, 2, 3):
        Fb = [S for S in ALLSETS if len(S) <= b]
        for X in ALLSETS:
            want = 0 if not X else -(-len(X) // b)
            assert min_cover(X, Fb) == want, (b, X)
    Fno0 = [S for S in ALLSETS if 0 not in S]
    assert min_cover(frozenset({0, 1}), Fno0) == float("inf")
    assert min_cover(frozenset({0}), Fno0) == float("inf")
    assert min_cover(frozenset({1, 2}), Fno0) == 1
    cl = directed_closure([frozenset()] + [frozenset({i}) for i in U])
    assert len(cl) == 64 and frozenset({0, 3, 5}) in cl
    cl0 = directed_closure([frozenset()] + [frozenset({i}) for i in range(1, 6)])
    assert len(cl0) == 32
    assert all(0 not in Y for Y in cl0)
    print("Python：精确覆盖数与 Julia 公式一致；0 不可覆盖复现；")
    print("BFS 定向闭包 = 全幂集（64），缺 0 单点的闭包恒缺 0（32）")
    print("END ====")


if __name__ == "__main__":
    main()
```

与 Julia 分工：`itertools.combinations` 对显式递归生成器、
frozenset 对 `Set{Int}`、BFS 前沿对不动点迭代。两边各有一个
「早退」护栏——不可覆盖时若不先检查全族之并会枚举 $2^{21}$
个子族（实测初版在此挂死数百秒，两通道同坑同修）。

## 96.16 机器通道七：Prolog——覆盖证书与链式覆盖

```prolog
:- encoding(utf8).
% 第 96 章：覆盖证书生成与失败见证。

% L-侧族（有限影子）：inL(Y) 表示 Y ∈ L。
inL([0,1,2]).
inL([2,3]).
inL([4]).

% X 的元素事实：elts(XElem) 列出 X 的成员。
xelem(1). xelem(2). xelem(3).

% subset(X, Y)：X 的每个列出的元素都在 Y 中。
covered_by(Y) :- forall(xelem(X), member(X, Y)).

% 单片覆盖证书：存在 Y ∈ L 包住 X。
cover1(Y) :- inL(Y), covered_by(Y).

% 两片 slack 覆盖证书：L 中两个成员之并包住 X。
cover2(Y, Z) :- inL(Y), inL(Z), forall(xelem(X),
        (member(X, Y) ; member(X, Z))).

% 链式并封闭（推论 1.8(4) 的骨架）：族成员列表之并仍在证书侧可达。
chain_cover(Ys) :- member(Ys, [[[0,1,2]], [[2,3]], [[0,1,2],[2,3]], [[4]]]),
                   forall(member(Y, Ys), inL(Y)).

main :-
    format("==== 96~n"),
    \+ cover1(_),
    cover2([0,1,2], [2,3]),
    chain_cover([[0,1,2],[2,3]]),
    format("X={1,2,3}：单片覆盖失败，两片 slack 覆盖成功（{0,1,2}∪{2,3}）~n", []),
    format("链式并：[[0,1,2],[2,3]] 是合法的族成员链（推论 1.8(4) 骨架）~n", []),
    writeln("END ====").
```

`cover1` 的失败查询（`\+ cover1(_)`）是定理 1.21 等势版失败的
影子；`cover2` 是 $|X|+\aleph_1$ 松弛版的证书；`chain_cover`
把 (4) 的链式并做成可查询的谓词。

## 96.17 机器的边界

1. **覆盖引理本体不可机化**。定理 1.21 的证明是 $\omega_1$ 长
   的极小反例 + 四个定向系统的良基性（引理 1.30–1.36），全部
   关于 $L$ 层级；连引理 1.30（强凝聚化）在原书都是省略证明
   的引用。mathlib 中没有任何形式的覆盖引理。
2. **基数账的骨架 vs 本体**：Lean 的 `union_bound`/`isRegular_cof`
   是推论 1.8(3) 与事实 1.1.1(iii) 的**形式骨架**——它们在任意
   基数上真，与覆盖引理的真假无关；引理的全部内容在「$L$ -小片
   的存在」这一步，机器不碰。
3. **逆命题的镜像账**（96.2 步骤三）依赖 Silver 不可辨别元的块
   镜像结构；有限实验只复现「缺点的族 ⇒ 点不可覆盖」的集合论
   平凡部分。
4. **$\aleph_1$ -松弛的最优性**（延波例子）是力迫构造，任何有限
   类比（$\lceil|X|/b\rceil$ ）只演示松弛的形态。

## 96.18 本章要点与检查问题

- **定理 1.21（Jensen）**：$0\#\not\exists$ ⟹ 不可数序数集有
  等势 $L$ -覆盖（实际只需 $|X|+\aleph_1$ 松弛；两者都不要求
  覆盖集的 $V$ -势精确，用的是覆盖引理的等势形式）。
- **等价总账**：$0\#$ 存在 ⟺ 奇异基数在 $L$ 中变正则 ⟺
  $\omega_1$ 在 $L$ 中正则。覆盖引理与 0# 共同把「$L$ 与
  $V$ 的接近程度」变成二值开关。
- **推论 1.8 四件套**：(1) $L$ -正则 $\lambda\ge\omega_2$ 则
  $V$ -正则（完整证明：$L$ -势下界 + 双射搬运 + $\omega_2$
  序数尺寸账）；(2) 后继基数吻合；(3) SCH；(4) 反例必先出现在
  有界段。
- **证明机器**：$\Sigma_n$ 斯科伦闭包（分层交换律 1.32）+
  强凝聚化（1.30，引用）+ 四定向系统（$D_1$ –$D_4$ ）+
  $\nu$ -长连续链封堵（1.36）。
- **实测账**：Lean `open Cardinal` 污染 `Ordinal` 解析（须
  scoped）；`Order.IsSuccLimit` 命名空间与点记号失效；Coq
  `apply` 不做 `++`/`::` 定义转换；Agda 双 4 级中缀须括号；
  Julia/Python 不可覆盖查询须早退（否则 $2^{21}$ 枚举挂死）；
  闭包种子须含空集（63/64 被断言抓获）。

检查问题：

1. 推论 1.8(1) 的证明中，第三步「$\mu\ge\omega_2$ 蕴含
   $|\mu|^V\ge\aleph_2$ 」用的是纯序数事实；如果把它换成
   「$\mu>\aleph_1$ 蕴含 $|\mu|\ge\aleph_1$ 」，结论会弱到什么
   程度？哪一步真正需要 $\omega_2$ ？
2. 定理 1.21 的「不可数」条件与延波例子（$\omega_1$ 的可数无界
   子集不可覆盖）配合，恰好对应松弛版的 $\aleph_1$ 因子。请把
   96.14(a) 的 $\lceil|X|/b\rceil$ 公式与「$|X|\cdot\aleph_1$
   松弛」逐项对上。
3. 引理 1.33 与引理 1.34 的四类定向系统 $D_1$ –$D_4$ 中，哪一
   类处理「复杂度最小的反例」、哪一类处理「参数层次是极限」的情
   形？引理 1.35（参数变换）在两者之间起什么作用？

---

上一章：[95 0# 与 Silver 不可辨别元](95-zerosharp.md) · 下一章：[97 线性迭代超幂](97-iterated.md)
