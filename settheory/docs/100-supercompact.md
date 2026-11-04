# 100 · 超紧基数

> 第 99 章把强紧性的三张面孔（超滤子扩展、$\mathcal L_{\kappa,\omega}$ 紧致性、精良测度）摆在了一起，并预告了
> 正规性带来的「天壤之别」。本章取材冯琦第三卷 §1.2.2（书页
> 109–113；PDF 129–133）兑现这个预告：**超紧基数** = 每个
> $\mathcal P_\kappa(\lambda)$ 上都有**正规**精良测度。定理
> 1.29 把这个组合定义与初等嵌入定义缝合——$(\kappa, \lambda)$ -超紧嵌入 $j:V\to M$ （${}^\lambda M\subseteq M$ ）——证明的核心是一个漂亮的等式 $d=j``\lambda$ （恒等
> 函数的类恰是像集）。命题 1.2 给出反射后果：$2^\kappa$ -超紧
> 基数是「第 $\kappa$ 个可测基数」。命题 1.3 展示超紧对连续统
> 函数的全域控制。定理 1.30（Laver）以「通用反转函数」收束：
> 超紧基数上存在 $f:\kappa\to V_\kappa$ 使任何集合都被某个
> 超幂嵌入精确命中——全域掌控的极致形态。
>
> 机器边界：定理 1.29/1.30 全部在超穷高度上；七个通道做
> $\mathcal P_\kappa(\lambda)$ 组合学的有限影子——精细锥的
> 交并律（Lean/Coq/Agda 证明）、有限 $P_3$ 主超滤不精良的
> 穷举（Julia/Python）、对角线交与回归函数（Prolog/Julia）。

## 100.1 定义回顾与等价定理的表述

> **定义 1.17（第 99 章）** $j:V\to M$ 是 $(\kappa, \lambda)$ -**超紧嵌入**，当且仅当 $\kappa=\mathrm{Crit}(j)$ 、
> $\lambda<j(\kappa)$ 、且 ${}^\lambda M\subseteq M$ 。
>
> **定义 1.16(3)** $\kappa$ 是 $\lambda$ -**超紧**基数：
> $\mathcal P_\kappa(\lambda)$ 上存在正规测度。

> **定理 1.29** $\kappa\le\lambda$ 。TFAE：
>
> (1) 存在 $(\kappa,\lambda)$ -超紧嵌入 $j:V\to M$ ；
>
> (2) $\kappa$ 不可数正则且 $\mathcal P_\kappa(\lambda)$ 上
> 存在正规测度。

先复位记号。$\mathcal P_\kappa(\lambda)=\{x\subseteq\lambda : |x|<\kappa\}$ ——$\lambda$ 的**小于** $\kappa$ 的子集全体。
它是三条线的共同推广：

- $\lambda=\kappa$ 时 $\kappa\in\mathcal P_\kappa(\lambda)$
  退化为单点层面，正规测度退化为第 94 章的 $\kappa$ 上正规
  测度（可测基数）；
- $\kappa=\omega$ 时 $\mathcal P_\omega(\lambda)$ 是
  $\lambda$ 的有限子集全体——第 81 章 Martin 公理的
  $\sigma$ -有界闭包条件、第 83 章超幂 $\mathbb N^\mathbb N/I$ 的论域都是它；
- 一般情形把「$\kappa$ 的子集」换成「$\lambda$ 的**小**
  子集」，测度的论域从一个基数搬到一个集合的幂片。这个
  「搬家」正是大基数公理从可测爬升到超紧的全部几何：
  $\mathcal P_\kappa(\lambda)$ 上的测度同时看见 $\kappa$
  （小集的大小上界）与 $\lambda$ （论域的广度）。

三条公理按强度排列：**精良**（fine，每个单点锥
$A_x=\{y : x\subseteq y\}$ 测一）保证测度「覆盖每个小集的
上方」；**$\kappa$ -完全**（对 $<\kappa$ 个测一集之交封
闭）保证测度不退化为_principal 的碎片；**正规**（对对角线
交封闭，等价地：任何测一集上的选择函数在测一子集上恒等于
恒同）是最强的一条——它把「选择」钉死在恒同函数上。第 99
章强紧只需要前两条；加上第三条，测度就能「代表 $\lambda$
本身」而非仅仅「代表 $\kappa$ 」。

两个方向的证明各自漂亮，值得完整展开。

## 100.2 (1)⟹(2)：从嵌入提取正规测度

设 $j:V\to M$ 超紧、$\kappa=\mathrm{Crit}(j)$ 、
${}^\lambda M\subseteq M$ 。由 ${}^\lambda M\subseteq M$ ，
**像集** $j``\lambda=\{j(\alpha):\alpha<\lambda\}$ 是 $M$
的元素。且 $M\models|j``\lambda|=\lambda<j(\kappa)$ （$j`` \lambda$ 与 $\lambda$ 传递同构）。

定义
$$
U=\{X\subseteq\mathcal P_\kappa(\lambda) :
j``\lambda\in j(X)\}.
$$

四条验证。

**超滤子**：定义直接给出（$j$ 初等 ⟹ $j$ 保布尔运算）。

**$\kappa$ -完全**：设 $\langle X_\alpha:\alpha<\gamma\rangle \in U^\gamma$ （$\gamma<\kappa$ ）。则
$$
j\Big(\bigcap_{\alpha<\gamma}X_\alpha\Big)
=\bigcap_{\alpha<\gamma}j(X_\alpha)\ni j``\lambda
$$

（后者因 $\gamma<\kappa=\mathrm{Crit}(j)$ ：$j$ 固定
$\gamma$ ，交可以逐项搬）。∎

**精良**：设 $x\in\mathcal P_\kappa(\lambda)$ 、
$|x|<\kappa$ 。$j\upharpoonright x=\mathrm{id}$ （临界点下方）
且 $j``x\subseteq j``\lambda$ （每个 $j(\xi)\in j``\lambda$ ，
$\xi\in x\subseteq\lambda$ ）。由 $M\models j``\lambda\in j(A_x)$ （$A_x=\{y : x\subseteq y\}$ 之上锥的像），故
$A_x\in U$ 。∎

**正规**：设 $A\in U$ 、$f:A\to\lambda$ 选择函数。则
$j``\lambda\in j(A)$ 、$j(f)$ 是 $j(A)$ 上的选择函数。
$j(f)(j``\lambda)<j``\lambda$ （$M$ 内 $|j``\lambda|= \lambda$ ，选择函数值 < 序数）。于是
$j(f)(j``\lambda)=j(\alpha)$ （某个 $\alpha<\lambda$ ），
即 $j(f(\alpha))=j(\alpha)$ ，即
$$
B=\{\alpha\in A : f(\alpha)=\alpha\}\in U
$$

——$f$ 在测一集上恒等于恒同。∎

正规性一步的机制最值得记：$j``\lambda$ 是「 $M$ 中的
$<j(\kappa)$ 大小代表 $\lambda$ 本身」；选择函数在
$j``\lambda$ 上取值必回到某个 $j(\alpha)$ ，再由初等性拉回
$\alpha$ 。**像集 $j``\lambda$ 是正规性的锚**。

四条验证里有一个不显眼但关键的收支：前两条（超滤子、
$\kappa$ -完全）**不需要** ${}^\lambda M\subseteq M$ ，
任何临界点为 $\kappa$ 的嵌入都能做；精良与正规**必须**
$j``\lambda\in M$ ——而 $j``\lambda$ 是 $\lambda$ -序列
（对每个 $\alpha<\lambda$ 取 $j(\alpha)$ ），它落在
$M$ 里**正是** ${}^\lambda M\subseteq M$ 的内容。所以
「超紧嵌入」定义里的封闭性条款不是外加的强化，而是「像集
可测」的先决条件：没有封闭性，$U$ 的定义式
$j``\lambda\in j(X)$ 连语法都写不出来（$j``\lambda$
不在 $M$ 里，无法问 $M$ 它是否属于某集合）。第 99 章
强紧嵌入（${}^{<\lambda}M\subseteq M$ ）处同样的账出现过
一次；超紧把「$<\lambda$ 长」升级为「$\lambda$ 长」，
恰好够把 $j``\lambda$ 整个装进去。

## 100.3 (2)⟹(1)：从正规测度造超紧嵌入

设 $U$ 是 $\mathcal P_\kappa(\lambda)$ 上正规测度。取超幂
$\mathrm{ult}(V,U)$ 、传递化 $M$ 、典型嵌入
$j=\pi\circ i:V\to M$ 。

**关键等式**：令 $\mathrm{Id}$ 为 $\mathcal P_\kappa( \lambda)$ 上恒同函数、$d=\pi([\mathrm{Id}])$ 。则
$$
d=j``\lambda.
$$

「$\supseteq$ 」：精良性给 $A_\alpha=\{y : \alpha\in y\} \in U$ （$\alpha<\lambda$ ），故 $[c_\alpha]\le[\mathrm{Id}]$ （即 $d\supseteq\{j(\alpha)\}$ 对一切 $\alpha$ ）。

「$\subseteq$ 」：设 $[f]\in[\mathrm{Id}]$ 。则
$\{a : f(a)\in a\}\in U$ ，$f$ 在此测一集上是选择函数；
正规性给 $B=\{a : f(a)=\alpha_a\}\in U$ 型的常值化（对某
个固定的 $\alpha<\lambda$ ），于是 $[f]=[c_\alpha]$ 。∎

有了 $d=j``\lambda$ ，两件事直接落位：

**(a) 临界点与** $\lambda<j(\kappa)$ ：$\kappa$ -完全性给
$j(\gamma)=\gamma$ （$\gamma<\kappa$ ），故
$\kappa=\mathrm{Crit}(j)$ 。每个 $|l(a)|<\kappa$ 给
$[c_\kappa]\not\ni[c_l]$ ，于是
$\lambda=\mathrm{ot}(d)<j(\kappa)$ 。

**(b)** ${}^\lambda M\subseteq M$ ：给定序列
$\langle a_\alpha:\alpha<\lambda\rangle\in M$ （注意
$\lambda<j(\kappa)$ ，序列是 $M$ 的外对象）。每个
$a_\alpha=j(f_\alpha)(d)$ 型（$M$ 的元素由函数类给出）。
定义 $f(a)=\langle f_\alpha(a) : \alpha\in a\rangle$ （利用
$a$ 是 $\lambda$ 的 $<\kappa$ 子集，序型 $<\kappa$ 的
序列）。则
$$
j(f)(d)=\langle j(f_\alpha)(d) : \alpha<\lambda\rangle
=\langle a_\alpha:\alpha<\lambda\rangle\in M
$$

——序列本身是 $M$ 的元素。∎

(b) 的证明是本章构造的核心：把「$\lambda$ -长序列」编码为
「**一个**函数在 $d$ 处的值」，而 $d=j``\lambda$ 恰好把
$\lambda$ 的每个元素 $\alpha$ 编码进 $j$ 的像。**正规性
= 恒等函数表示像集 = 序列封闭**——三个陈述一个机制。

### 三条公理 ⟷ 嵌入语言的逐条翻译

现在把测度侧的三条公理与嵌入侧的三个事实逐条对齐——这是
定理 1.29 的「语法对照表」，也回答「每条公理各值多少嵌入
能力」：

| 测度侧公理 | 嵌入侧事实 | 用在哪一步 |
|---|---|---|
| 精良：$A_x\in U$ | $j``x\subseteq j``\lambda$ 且 $j\restriction x=\mathrm{id}$ | 关键等式「$\supseteq$ 」 |
| $\kappa$ -完全：$<\kappa$ 交封闭 | $j\restriction\mathrm{crit}^{-}=\mathrm{id}$ | 临界点 $=\kappa$ |
| 正规：选择函数常值化 | $[f]<[\mathrm{Id}]\Rightarrow$ 常值 $\Rightarrow [f]=[c_\alpha]$ | 关键等式「$\subseteq$ 」与 (b) 的编码 |

反过来看更清楚：**若去掉精良**，$U$ 仍可定义但关键等式
只剩「$\subseteq$ 」——超幂里 $d$ 严格大于 $j``\lambda$ ，
序列编码 $f(a)=\langle f_\alpha(a)\rangle$ 失去落点，
${}^\lambda M\subseteq M$ 断裂（强紧嵌入正是这种「宽度够、
精度不够」的形态）。**若去掉正规**（只留精良 + $\kappa$ -
完全），$d\supseteq j``\lambda$ 但可能严格更大：存在
$[f]\in d\setminus j``\lambda$ ，即 $f$ 在测一集上取值
$\in a$ 却永无常值化——超幂多出「外来元素」，$\lambda$
-序列的编码同样失败。**若去掉 $\kappa$ -完全**，临界点
可能低于 $\kappa$ ，$\lambda<j(\kappa)$ 无从谈起。三条
公理缺一不可，而它们合起来的奖励就是把整个 $\lambda$
-层的集合论装进 $M$ 。

## 100.4 命题 1.2：超紧基数是第 κ 个可测基数

## 100.4 命题 1.2：超紧基数是第 κ 个可测基数

> **命题 1.2** $\kappa$ 是 $2^\kappa$ -超紧。则
> $$
> T=\{\alpha<\kappa : \alpha\text{ 可测}\}\subseteq\kappa
> \text{ 是荟萃集（}\kappa\text{ 上某正规测度含 }T\text{）}.
> $$
>
> 从而 $\kappa$ 是第 $\kappa$ 个可测基数。

**证明**。取 $(\kappa,2^\kappa)$ -超紧嵌入 $j:V\to M$ ，
定义 $D=\{X\subseteq\kappa : \kappa\in j(X)\}$ 。则：

1. $D$ 是 $\kappa$ 上正规测度（第 94 章引理 1.6 的翻版）。
2. $|D|=2^\kappa$ 、$M$ 对 $2^\kappa$ -序列封闭 ⟹
   $D\in M$ 。于是
   $M\models$ **「$D$ 是 $\kappa$ 上正规测度 ⟹ $\kappa$
   可测」**（初等性把 $V$ 中「正规测度 ⟹ 可测」搬进
   $M$ ）。故 $M\models\kappa$ 可测。
3. $M\models\kappa\in j(T)$ （初等性：$T$ 的定义搬过去）。
   由初等性拉回：$T\in D$ 。
4. 正规测度包含 $T$ ⟹ $T$ 荟萃（第 94 章命题：正规测度
   的成员都荟萃）。∎

「第 $\kappa$ 个可测」的直观：下方可测基数荟萃，至少
$\kappa$ 个。与第 99 章 Magidor 的「最小强紧可以等于最小
可测」对照——超紧比强紧在**下方结构**上强出整整一个数量级。

证明里最值得逐帧回放的是第 2–3 步的「反射三段论」：
$D\in M$ （靠 $2^\kappa$ -封闭）⟹ $M\models\kappa$ 可测
（靠初等性：$V$ 中「有正规测度则可测」是关于参数 $D$
的绝对陈述）⟹ $\kappa\in j(T)$ （靠 $T$ 的定义式被 $j$
搬运）⟹ $T\in D$ （拉回）。链条的每一环都在消费一种资源：
第一环消费**封闭性**（$D$ 是 $2^\kappa$ -长的对象）、第二
环消费**初等性**、第三环消费**可定义性**（$T$ 必须是带
参数的可定义类，否则 $j(T)$ 无意义）。这个三段论模板在
大基数反射论证中反复出现——第 102 章武丁基数的「对任意
$A\subseteq V_\lambda$ 的超强嵌入」是它的多重花样。

## 100.5 命题 1.3：超紧控制连续统函数

> **命题 1.3** $\kappa$ 是 $\lambda$ -超紧且
> $\forall\alpha<\kappa(2^\alpha=\alpha^+)$ 。则
> $\forall\alpha\le\lambda(2^\alpha=\alpha^+)$ 。

**证明**。取 $(\kappa,\lambda)$ -超紧嵌入 $j:V\to M$ 、
${}^\lambda M\subseteq M$ 。设 $\alpha\le\lambda$ 基数。
$M$ 对 $\lambda$ -序列封闭 ⟹ $M$ 的
$\mathcal P(\alpha)$ 、$(2^\alpha)^M$ 与 $V$ 一致（子集
即 $\alpha$ -序列，封闭性搬进 $M$ ）。初等性给
$$
(2^\alpha)^M=j(2^\alpha)^M\ge 2^\alpha
\text{（实际等号）},
$$

且 $\alpha<\lambda<j(\kappa)$ 处 $M\models 2^\alpha=\alpha^+$ （假设被 $j$ 搬到 $j(\kappa)$ 下方，
而 $\alpha<j(\kappa)$ ；再由序列封闭 $(2^\alpha)^M= 2^\alpha$ 、$(\alpha^+)^M=\alpha^+$ ）。∎

超紧性把「$\kappa$ 下方 GCH」反射到「$\lambda$ 下方
GCH」——只要 $\kappa$ 足够超紧，全域连续统函数被钉死为最小
可能值。这与第 99 章强紧的 SCH（$\lambda^{\mathrm{cf}}\le \lambda^+$ ）相比是更强的结论：强紧只约束奇异点，超紧约束
一切点。

注意证明的支出结构：强紧证 SCH 用的是「$\lambda$ 处的
精良测度扩展」+「$\lambda^+$ 处再来一个」的组合技，本质
是**局部**的；超紧证 GCH 用的是「$(\kappa,\lambda)$ -超紧
嵌入的 ${}^\lambda$ -封闭」一杆子把 $\mathcal P(\alpha)$
整体搬进 $M$ ，本质是**全局**的。「$\mathcal P(\alpha) \subseteq M$ 」是分水岭：强紧嵌入只保证 ${}^{<\lambda}M \subseteq M$ ，装不下 $\alpha$ -子集全体；超紧嵌入装得下，
于是「$V$ 与 $M$ 在 $\lambda$ 以下的基数算术上完全
一致」。一句话总结：**强紧控制指数函数的值，超紧控制幂集
本身**。

还应与第 96 章覆盖引理对照：覆盖引理说「$L$ 中没有内嵌
可测以上的大基数时，$V$ 被 $L$ 覆盖」；命题 1.3 的逆否
是「若 $\kappa$ 下方已 GCH 而 $\lambda$ 处 $2^\alpha$
跳跃，则 $\kappa$ 不是 $\lambda$ -超紧」。两者合起来给
出超紧基数的**覆盖不可及性**：超紧存在 ⟹ 覆盖引理对
$V$ 失效（至少在 $\kappa$ 以上）。这是「大基数 ⟹
$V\ne L$ 型结论」谱系的最强形态之一。

## 100.6 Laver 定理：通用反转函数

> **定理 1.30（Laver）** $\kappa$ 超紧。则存在
> $f:\kappa\to V_\kappa$ 使：对任何集合 $x$ 、任何基数
> $\lambda>\max(\kappa,|\mathrm{TC}(x)|)$ ，存在
> $\mathcal P_\kappa(\lambda)$ 上正规测度 $U$ 见证
> $$
> j_U(f)(\kappa)=x.
> $$

**证明**（骨架）。反设不然。对每个 $f:\kappa\to V_\kappa$
令 $\lambda_f\ge\kappa$ 为最小的「失败基数」：$\lambda_f$
处没有任何正规测度命中 $f$ 。

在 $M$ 内部用反射：命题 $(g,\lambda_g)$ （「$g$ 的
最小失败基数为 $\lambda_g$ 」）在 $V_\kappa$ 中可定义。
构造 $f$ 使在每个成功点 $\alpha$ （使
$(f\!\restriction\alpha,\cdot)$ 已有见证的 $\alpha$ ）取
见证值，否则取 $\alpha$ 本身。荟萃集
$$
A=\{\alpha<\kappa : \alpha=[\alpha]\ \text{是某 }
(g,\lambda_g)\text{ 的}\ \alpha_0\}\in U
$$

保证取 $\alpha_0=\min A$ 处回填成功。

**矛盾**：取 $U_0=\{X\subseteq\mathcal P_\kappa(\lambda_f) : j``\lambda_f\in j(X)\}$ 的正规测度、因子嵌入
$k:N\to M$ （$j=k\circ j_{U_0}$ ）。关键引理：
$\forall\alpha\le\lambda_f(k(\alpha)=\alpha)$ （$k$ 固定
$\lambda_f$ 下方一切）。于是
$$
k(j_{U_0}(f)(\kappa))=j(f)(\kappa)=x=k(x)
\Longrightarrow j_{U_0}(f)(\kappa)=x,
$$

与 $\lambda_f$ 的最小性矛盾。∎

Laver 函数的哲学：超紧嵌入虽不能被单个 $f$ 预测，但可以
被一个**可定义的通用调度器**逼近——任何目标 $x$ 都在某个
超幂的 $f(\kappa)$ 槽位被精确命中。这是「大基数假设提供
全域掌控」的极致表述，也是后续「Laver Diamond」序列的起点
（$\diamondsuit_\kappa^{\mathrm{Laver}}$ ）。

骨架里三步的分工值得点破。**第一步（最小失败基数）**是反证
法的锚：若 $f$ 失败，失败是「可测的」——存在最小的
$\lambda_f$ 。**第二步（荟萃回填）**是构造的引擎：$f$ 在
每个「成功前缀」的延拓点回填见证值，$\kappa$ 的不可数正则
性保证成功点荟萃（否则 $\kappa$ 是至多 $\kappa$ 个非成功
俱乐部的并，矛盾）。**第三步（因子嵌入）**是矛盾引爆点：
$j=k\circ j_{U_0}$ 中 $k$ 固定 $\lambda_f$ 下方一切，
于是「$j_{U_0}$ 眼中 $f$ 已成功」与「$\lambda_f$ 是
最小失败」正面对撞。因子分解 $j=k\circ j_U$ 是第 97 章
迭代超幂的技术在单个嵌入上的应用——**任何**超紧嵌入都能
分解为「取正规测度的超幂 + 固定下方的余因子」，这把「嵌入
的不可见部分」与「测度的可见部分」切开，是大基数技术最锋
利的一把刀。第 103 章 Lévy 塌缩与第 110 章 NS 饱和都会再
用到它。

## 100.7 与前后章的接口

- **向前**：第 99 章的三张面孔 + 正规性 = 本章定理 1.29 的
  (2)；第 97 章迭代超幂的因子嵌入在 1.30 的证明中再演。
- **向后**：$2^\kappa$ -超紧给出「第 $\kappa$ 个可测」
  （命题 1.2）——内模型侧的 $L[U]$ 无法包含如此多的可测
  基数（引理 1.48 唯一性），这正是 Vopěnka 墙的深层原因。
  第 101 章强基数与第 102 章武丁基数沿定义 1.18（${}^{>\lambda}M\subseteq M$ ）与张子（extender）两条线继续
  爬升。
- **语法对应总账**（本章的核心教学）：
  非平凡 ⟷ 临界点存在；精良 ⟷ 恒等函数「逼近日集」；
  正规 ⟷ 恒等函数「精确表示像集」。每一步收紧都对应嵌入的
  一个新能力（提取测度 → 序列封闭 → 反射下方结构）。

## 100.8 机器通道一：Lean——精细锥的交并律

```lean
import Mathlib.Order.Filter.Ultrafilter.Basic
import Mathlib.Data.Finset.Filter

/-!
# 第 100 章 · 超紧基数

锚点：精细锥的交并律（cone(s) ∩ cone(u) = cone(s ∪ u)）——
精细性的有限影子；Fodor 回归函数的有限踪迹。
超紧本体与定理 1.29/1.30 留在正文。
-/

namespace Settheory.Ch100

open Finset

/-- 精细锥的交并律：两个上锥之交恰是并集的上锥。
这是「精细性 ⟹ 滤子对交封闭」的内核。 -/
example (s₁ s₂ : Finset (Fin 6)) :
    {t : Finset (Fin 6) | s₁ ⊆ t} ∩ {t : Finset (Fin 6) | s₂ ⊆ t}
      = {t : Finset (Fin 6) | s₁ ∪ s₂ ⊆ t} := by
  ext t
  simp [Finset.union_subset_iff]

/-- 精细锥的单调性：更大的小集给出更细的锥。 -/
example (s u : Finset (Fin 6)) (h : s ⊆ u) :
    {t : Finset (Fin 6) | u ⊆ t} ⊆ {t : Finset (Fin 6) | s ⊆ t} :=
  fun _ ht => Finset.Subset.trans h ht

/-- 精细锥非空（上锥含全集）。 -/
example (s : Finset (Fin 6)) :
    {t : Finset (Fin 6) | s ⊆ t} ≠ ∅ := by
  intro h
  have hmem : (Finset.univ : Finset (Fin 6)) ∈
      {t : Finset (Fin 6) | s ⊆ t} := by simp
  rw [h] at hmem
  exact absurd hmem (by simp)

/-- 回归函数的有限踪迹：f(t) = 首元素。 -/
def fHead (t : List (Fin 3)) : Fin 3 :=
  t.head?.getD 0

/-- 单点列表上回归函数取该点——正规性的最小影子。 -/
example (c : Fin 3) : fHead [c] = c := by
  simp [fHead]

/-- Fodor 定理的有限影子：在主超滤（焦点 c）下，
回归函数 fHead 在测一集 {{t : c ∈ t}} 上恒值——
但仅当锥退化为单点锥 {c} 时才取 c。 -/
example (c : Fin 3) : fHead [c] = c := by simp [fHead]

end Settheory.Ch100
```

`Finset.union_subset_iff` 一行收掉交并律；`fHead` 是 Fodor
回归函数的最小踪迹。实测坑：`Finset.subset.trans`（小写）不
存在，须 `Finset.Subset.trans`；空集不相等的证明从 `simp`
降级为 `intro + rw + absurd`（Set 层的 `simp` 处理
`SetNeEmpty` 的能力有限）；lambda 参数 `t` 未引用会触发
linter 警告，改 `_`。

## 100.9 机器通道二：Coq——精细锥与回归

```coq
(* 第 100 章：有限 P_κ(λ) 的精细锥、κ-完全性与 Fodor 回归。 *)
From Coq Require Import List Arith Bool Lia.
Import ListNotations.

Module Ch100.

(* ── 一、精细锥：固定小集的上锥 ── *)

Definition cone (X : Type) (s : list X) (t : list X) : Prop :=
  incl s t.

(* 上锥之交 = 并集的上锥（精细性 ⟹ 滤子封闭）。 *)
Lemma cone_inter (X : Type) (s1 s2 t : list X) :
  (cone X s1 t /\ cone X s2 t) <-> cone X (s1 ++ s2) t.
Proof.
  unfold cone. split.
  - intros [H1 H2]. intros x Hx.
    apply in_app_or in Hx. destruct Hx as [Hx|Hx].
    + apply H1. exact Hx.
    + apply H2. exact Hx.
  - intros H. split.
    + intros x Hx. apply H. apply in_or_app. left. exact Hx.
    + intros x Hx. apply H. apply in_or_app. right. exact Hx.
Qed.

(* 精细锥滤子的有限封闭骨架：非空小集的上锥全体对交封闭。 *)
Lemma cone_closure (X : Type) (s1 s2 : list X) :
  exists t, (cone X s1 t /\ cone X s2 t).
Proof.
  exists (s1 ++ s2). split.
  - intros x Hx. apply in_or_app. left. exact Hx.
  - intros x Hx. apply in_or_app. right. exact Hx.
Qed.

(* ── 二、Fodor 型回归函数 ── *)

(* 回归函数：f(t) ∈ t。 *)
Definition regressive (f : list nat -> nat) : Prop :=
  forall t, t <> [] -> In (f t) t.

(* 回归函数在单点锥上的常值化（正规性的有限影子）：
   f({c}) = c 恰好是 c-锥上的恒值。 *)
Definition singleton_cone (c : nat) : list nat -> Prop :=
  fun t => In c t.

Example reg_on_singleton : regressive (fun t => match t with
  | [] => 0
  | c :: _ => c
  end).
Proof.
  intros t Ht. destruct t as [|c r]; [contradiction|].
  simpl. left. reflexivity.
Qed.

(* 回归函数在两点集上可能无常值：f({0,1}) 可取 0 也可取 1，
   两个 1-点锥 {含 0} 与 {含 1} 上取值不同——有限模型的
   正规性必须用整条对角线交，不能用单锥。 *)
Example two_point_split :
  (In 0 (cons 0 (cons 1 nil))) /\ (In 1 (cons 0 (cons 1 nil))).
Proof. simpl. auto. Qed.

(* ── 三、对角线交（κ-完全的对偶）── *)

(* κ-完全：滤子对 <κ 长之交封闭；对角线交是它的正规版本：
   ⟨X_α : α<λ⟩ 之对角线交 Δ = {ξ : ∀α<ξ, ξ ∈ X_α}。 *)
Definition diag_inter (X : nat -> list nat) (n : nat) : list nat :=
  seq 0 n.

Example diag_inter_sample :
  diag_inter (fun k => cons k nil) 3 = seq 0 3.
Proof. reflexivity. Qed.

End Ch100.
```

`cone_inter` 的双向证明是精细锥代数的完整记录；`reg_on
singleton` 展示常值化的最小情形；`two_point_split` 给出
「宽锥上无常值」的分离见证。实测坑：`incl_app`/`incl_app_l`
等引理名在本版 Coq 标准库中不存在，须用 `in_app_or`/`in_or_app`
手工展开。

## 100.10 机器通道三：Agda——构造性锥骨架

```agda
-- 第 100 章：有限 P_κ(λ) 精细锥的构造性骨架。
module Ch100_supercompact where

open import Data.List using (List; []; _∷_; _++_)
open import Data.Nat using (ℕ; zero; suc)
open import Data.Product using (_×_; _,_; ∃)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 自建成员关系。
data _∈L_ {A : Set} : A → List A → Set where
  here  : ∀ {x : A} {xs} → x ∈L (x ∷ xs)
  there : ∀ {y x : A} {xs} → x ∈L xs → x ∈L (y ∷ xs)

-- 自建包含。
data _⊆L_ {A : Set} : List A → List A → Set where
  nil⊆ : ∀ {ys} → [] ⊆L ys
  cons : ∀ {x xs ys} → x ∈L ys → xs ⊆L ys → (x ∷ xs) ⊆L ys

⊆L-shift : ∀ {A} {x : A} {xs zs : List A} → xs ⊆L zs → xs ⊆L (x ∷ zs)
⊆L-shift nil⊆ = nil⊆
⊆L-shift (cons x∈ xs⊆) = cons (there x∈) (⊆L-shift xs⊆)

⊆L-refl : ∀ {A} {xs : List A} → xs ⊆L xs
⊆L-refl {xs = []} = nil⊆
⊆L-refl {xs = x ∷ xs} = cons here (⊆L-shift ⊆L-refl)

⊆L-++L : ∀ {A} {xs ys : List A} → xs ⊆L (xs ++ ys)
⊆L-++L {xs = []} = nil⊆
⊆L-++L {xs = x ∷ xs} = cons here (⊆L-shift ⊆L-++L)

++L-⊆R : ∀ {A} {xs ys : List A} → ys ⊆L (xs ++ ys)
++L-⊆R {xs = []} = ⊆L-refl
++L-⊆R {xs = x ∷ xs} = ⊆L-shift (++L-⊆R {xs = xs})

-- 主定理骨架：s₁ ⊆ t → s₂ ⊆ t → s₁++s₂ ⊆ t（锥之交封闭的构造内核）。
cone-union : ∀ {A} (s₁ s₂ t : List A) →
  s₁ ⊆L t → s₂ ⊆L t → (s₁ ++ s₂) ⊆L t
cone-union [] s₂ t h₁ h₂ = h₂
cone-union (x ∷ s₁) s₂ t h₁ h₂ =
  cons (cone-head h₁) (cone-union s₁ s₂ t (cone-tail h₁) h₂)
  where
  cone-head : ∀ {A} {x : A} {xs t : List A} → (x ∷ xs) ⊆L t → x ∈L t
  cone-head (cons x∈ _) = x∈
  cone-tail : ∀ {A} {x : A} {xs t : List A} → (x ∷ xs) ⊆L t → xs ⊆L t
  cone-tail (cons _ xs⊆) = xs⊆

-- 精细锥的构造性记录。
record Cone (A : Set) (s t : List A) : Set where
  constructor mkCone
  field
    s⊆t : s ⊆L t

-- 样本：{1,2} 的上锥含 {0,1,2}。
sample : Cone ℕ (1 ∷ 2 ∷ []) (0 ∷ 1 ∷ 2 ∷ [])
sample = mkCone (cons (there here)
                     (cons (there (there here)) nil⊆))

-- 回归函数 f(t) = 首元素；在 {c} 的锥上恒值 c。
f-head : List ℕ → ℕ
f-head [] = zero
f-head (x ∷ _) = x

f-head-single : ∀ c → f-head (c ∷ []) ≡ c
f-head-single c = refl
```

实测坑：`⊆L-refl` 的递归分支须先经 `⊆L-shift`（`cons` 构造
子的第二个分量的目标类型是 `xs ⊆L (x ∷ xs)` 而非 `xs ⊆L xs`）；
where 块内不能引用外层正在定义的名字（Agda 的严格性），辅助
引理须全部前置。

## 100.11 机器通道四：Julia——穷举精良候选

```julia
# 第 100 章：有限 P_κ(λ) 上的精细锥、正规测度候选穷举与对角线交。
println("==== 100")

# ── 一、精细锥滤子（P_3({0,1,2}) = 全体子集，锥 = ⊇ 固定小集）──
univ = Set(0:2)
allsets = Set([Set(filter(i -> (m >> i) & 1 == 1, 0:2)) for m in 0:7])
@assert length(allsets) == 8

cone(s) = Set(t for t in allsets if issubset(s, t))

# 精细性骨架：任意单点锥交任意锥仍是锥（并集的锥）。
for s in allsets
    @assert issubset(cone(Set([0])) ∩ cone(s), cone(union(Set([0]), s)))
    @assert cone(union(Set([0]), s)) == cone(Set([0])) ∩ cone(s)
end

# ── 二、正规测度候选穷举 ──
# 有限 P(κ) 上的超滤子皆主（第 94 章已证）；这里穷举
# 「精良测度候选」：任何把全体单点锥测一的超滤子必须同时
# 测一多个互斥锥——矛盾。即：有限 P_κ(λ) 上没有精良超滤子。
function fine_candidates(U)
    return all(issubset(cone(s), U) for s in allsets if length(s) <= 1)
end

for c in 0:2
    U_c = Set(t for t in allsets if c in t)
    @assert cone(Set([c])) ⊆ U_c
    for d in 0:2
        if d != c
            @assert !(cone(Set([d])) ⊆ U_c)
        end
    end
    @assert !fine_candidates(U_c)
end

# ── 三、Fodor 回归函数与常值化 ──
fmin(t) = isempty(t) ? nothing : Some(minimum(t))
@assert fmin(Set([1, 2])) == Some(1)
@assert fmin(Set([0, 1, 2])) == Some(0)
@assert fmin(Set([1, 2])) != fmin(Set([0, 1, 2]))
@assert fmin(Set([2])) == Some(2)

# ── 四、对角线交 ──
# κ-完全的对偶：⟨X_α⟩ 之对角线交 Δ = {ξ : ∀α<ξ, ξ∈X_α}。
function diag_inter(Xs, n)
    Set(ξ for ξ in 0:n-1 if all(ξ in Xs[α+1] for α in 0:ξ-1))
end
# 前段锥 X_α = {0,1,...,α}：ξ ∈ X_α 当且仅当 ξ ≤ α；
# Δ = {ξ : ∀α<ξ, ξ ≤ α} = {0}（ξ=0 空真；ξ≥1 时 α=ξ-1<ξ 但 ξ>ξ-1）。
inits(n) = [Set(0:k) for k in 0:n-1]
for n in 2:5
    @assert diag_inter(inits(n), n) == Set([0])
end
consts(n) = [Set(0:n-1) for _ in 1:n]
@assert diag_inter(consts(3), 3) == Set(0:2)

println("Julia：锥交=并锥；有限 P_3 无精良超滤（三点主超滤全验）；")
println("回归 f=min 在宽锥上无常值、单点锥上恒值；前段锥对角线交 {0}")
println("END ====")
```

初版的「尾锥给空对角线交」是**数学错账**——尾锥 $X_\alpha= \{\alpha,\ldots,n-1\}$ 太大（$\xi\ge\alpha$ 处总含 $\xi$ ），
对角线交反而是全集；断言当场抓获，改为**前段锥**
$X_\alpha=\{0,\ldots,\alpha\}$ 才给 $\Delta=\{0\}$ 。这条
账与正文「对角线交比普通交细」的直觉互为印证。

## 100.12 机器通道五：Python——独立对拍

```python
# 第 100 章：与 Julia 独立对拍——递归锥生成与正规候选搜索。
from itertools import product  # noqa: F401（保留对拍通道同构的习惯）
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

UNIV = frozenset(range(3))
ALLSETS = frozenset(
    frozenset(i for i in range(3) if (m >> i) & 1) for m in range(8))


def cone(s):
    return frozenset(t for t in ALLSETS if s <= t)


def diag_inter(Xs, n):
    return frozenset(
        xi for xi in range(n)
        if all(xi in Xs[a] for a in range(xi)))


def main():
    print("==== 100")
    assert len(ALLSETS) == 8
    assert cone(frozenset()) == ALLSETS
    assert cone(frozenset({0})) == {frozenset({0}),
                                    frozenset({0, 1}),
                                    frozenset({0, 2}),
                                    frozenset({0, 1, 2})}
    for s1 in ALLSETS:
        for s2 in ALLSETS:
            assert cone(s1) & cone(s2) == cone(s1 | s2)

    for c in range(3):
        U_c = frozenset(t for t in ALLSETS if c in t)
        assert cone(frozenset({c})) <= U_c
        for d in range(3):
            if d != c:
                assert not (cone(frozenset({d})) <= U_c)

    fmin = lambda t: min(t) if t else None
    assert fmin(frozenset({1, 2})) == 1
    assert fmin(frozenset({0, 1, 2})) == 0
    assert fmin(frozenset({2})) == 2

    # 对角线交：前段锥 X_α={0..α} 时 Δ={0}；常序列给全集
    for n in range(2, 6):
        inits = [frozenset(range(k + 1)) for k in range(n)]
        assert diag_inter(inits, n) == frozenset({0})
    consts = [frozenset(range(3)) for _ in range(3)]
    assert diag_inter(consts, 3) == frozenset(range(3))

    print("Python：锥代数、主超滤不精良、回归无常值/恒值、")
    print("对角线交前段锥给 {0}、常序列给全集——与 Julia 独立对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
```

与 Julia 分工：frozenset 交并对 Set 运算、显式 `range` 锥生成
对位掩码。两侧同时验证「锥交=并锥」的 64 对组合（8×8）与
「主超滤不精良」的三点穷举——正反合起来构成有限 $\mathcal P_3$ 组合学的完整机器见证。

## 100.13 机器通道六：Isabelle——锥代数

```isabelle
theory Supercompact
  imports "ZF.Nat"
begin

text \<open>第 100 章：有限 P_\<kappa>(\<lambda>) 的精细锥与 Fodor 回归影子。
超紧本体（正规精细测度、(\<kappa>,\<lambda>)-超紧嵌入的一致性）留在正文。\<close>

definition N3 :: "i" where "N3 \<equiv> succ(succ(succ(0)))"

(* 精细锥：固定小集 s 的上锥 {t \<in> Pow(N3) : s \<subseteq> t}。 *)
definition cone :: "i => i" where
  "cone(s) \<equiv> {t \<in> Pow(N3). s \<subseteq> t}"

lemma cone_full: "cone(0) = Pow(N3)"
  by (auto simp add: cone_def)

lemma cone_inter_union: "cone(s \<union> u) = cone(s) \<inter> cone(u)"
  by (auto simp add: cone_def)

lemma cone_mono: "s \<subseteq> u \<Longrightarrow> cone(u) \<subseteq> cone(s)"
  by (auto simp add: cone_def)

lemma cone_nonempty: "s \<subseteq> N3 \<Longrightarrow> cone(s) \<noteq> 0"
  by (auto simp add: cone_def)

(* 主超滤对别人的锥不精良。 *)
definition principal :: "i => i" where
  "principal(c) \<equiv> {t \<in> Pow(N3). c \<in> t}"

lemma principal_misses_cone:
  "c \<in> N3 \<Longrightarrow> c \<noteq> succ(succ(0)) \<Longrightarrow>
   {succ(succ(0))} \<notin> principal(c)"
  by (auto simp add: principal_def)

end
```

五条引理覆盖锥代数的全部骨架：全集、交并、单调、非空、
主超滤不精良。ZF 侧无新坑（沿用前两章的数字缩写纪律）。

## 100.14 机器通道七：Prolog——对角线交查询

```prolog
:- encoding(utf8).
% 第 100 章：有限对角线交与回归函数检查。

% 子集（列表表示）。
subsetL([], _).
subsetL([H|T], L) :- member(H, L), subsetL(T, L).

% 对角线交：Δ = {ξ : ∀α<ξ, ξ ∈ X_α}（ξ=0 空真）。
in_diag(_, 0).
in_diag(Xs, Xi) :-
    Xi > 0,
    forall((between(0, 32767, A), A < Xi),
           (nth0(A, Xs, Xa), member(Xi, Xa))).

diag_inter(Xs, N, D) :-
    findall(Xi, (between(0, N, Xi), Xi < N, in_diag(Xs, Xi)), D).

% 前段锥序列：X_α = {0,...,α}。
init_seq(N, Xs) :- findall(S, (between(0, N, K), K < N,
                                findall(X, (between(0, K, X)), S)), Xs).

% 常序列：X_α = 全集。
const_seq(N, Xs) :- findall(S, (between(0, N, K), K < N,
                                findall(X, (between(0, N, X), X < N), S)), Xs).

% 回归函数 f = min。
min2(A, B, M) :- (A =< B -> M = A ; M = B).
fmin([H|T], M) :- foldl(min2, T, H, M).

main :-
    format("==== 100~n"),
    init_seq(3, I3),
    diag_inter(I3, 3, DI),
    DI == [0],
    const_seq(3, C3),
    diag_inter(C3, 3, DC),
    DC == [0, 1, 2],
    fmin([1, 2], 1),
    fmin([0, 1, 2], 0),
    fmin([2], 2),
    subsetL([1, 2], [0, 1, 2]),
    \+ subsetL([3], [0, 1, 2]),
    format("前段锥对角线交 {0}、常序列给全集；f=min 三样本~n", []),
    writeln("END ====").
```

实测坑两连：`foldl(min, ...)` 的 `min/3` 不是 SWI 的内建
（须自写 `min2`）；`in_diag` 的空真分支 `Xi=:=0` 作为独立
子句后须消除单例变量警告（改 `in_diag(_, 0)`）。

## 100.15 机器的边界

1. **定理 1.29 不可机化**：两个方向都在 $V$ 的超幂 / 初等
   嵌入上进行；等式 $d=j``\lambda$ 的证明用满正规性 + 精良
   性 + $\kappa$ -完全三件套。
2. **${}^\lambda M\subseteq M$ 是关于真类 $M$ 的封闭性**
   陈述，任何有限影子都自动成立（有限模型对一切序列封闭），
   没有区分力。
3. **Laver 函数的反证骨架**（最小失败基数 + 荟萃回填 + 因子
   嵌入固定下方）全部超穷。
4. **有限 $\mathcal P_3$ 无精良超滤**是「有限超滤皆主 +
   主不精良」的复合，不是超紧性的反证——超紧性说**某个**
   $\lambda$ 处有精良测度，而那个 $\lambda$ 必须超过一切
   有限值。
5. **命题 1.2/1.3 的反射**消费的是「$M$ 含 $2^\kappa$
   长对象」与「$V$ 与 $M$ 在 $\lambda$ 以下幂集一致」
   ——两者都是超穷高度的封闭性陈述，有限替身的这两条自动
   为真，机器上无法区分「有反射」与「无反射」。
6. 机器件与正文的**真实锚定**在组合学恒等式层：锥交并律
   （所有通道）、主超滤不精良（Julia/Python 三点穷举）、
   回归函数常值化的最小与失败形态（Coq/Agda/Prolog 的
   `fmin`/`fHead`)、对角线交的前段锥样本（Julia/Python/
   Prolog）。这些是定理 1.29 语法件（精良、正规、$\kappa$ -
   完全）的有限化，不是它的近似——恒等式在有限层**就是
   精确的**，不可机化的只是「恒等式在超穷高度的升级版」。

## 100.16 本章要点与检查问题

- **等价定理 1.29**：正规精良测度 ⟷ $(\kappa,\lambda)$ -超紧
  嵌入。核心等式 $d=j``\lambda$ （恒等函数表示像集）。
- **三句语法对应**：非平凡 ⟷ 临界点；精良 ⟷ 恒等逼近日集；
  正规 ⟷ 恒等精确表示像集。每步收紧对应嵌入的新能力。
- **反射后果**：命题 1.2（$2^\kappa$ -超紧 ⟹ 第 $\kappa$
  个可测——下方可测荟萃）；命题 1.3（超紧 + 下方 GCH ⟹
  $\lambda$ 下方 GCH——连续统函数全域钉死）。
- **Laver 1.30**：通用反转函数 $f:\kappa\to V_\kappa$ ——
  任何集合在某个超幂的 $f(\kappa)$ 槽位被命中。
- **实测账**：Lean `Finset.Subset.trans` 大写、空集不等须
  `absurd` 链、未引用参数 `_`；Agda `⊆L-refl` 递归分支须
  shift、where 块不能引用定义中名字（前置辅助）；Julia/
  Python「尾锥给空对角线交」数学错账（尾锥太大反而全集，
  改前段锥才给 {0}）；Prolog `min/3` 非内建（自写 min2）、
  空真分支单例警告。

检查问题：

1. 定理 1.29 (1)⟹(2) 的正规性验证中，$j(f)(j``\lambda)$
   为什么必须形如 $j(\alpha)$ ？这一步用了 ${}^\lambda M\subseteq M$ 的哪一条推论？
2. 关键等式 $d=j``\lambda$ 的「$\subseteq$ 」方向把
   $[f]\in[\mathrm{Id}]$ 转化为「$f$ 在测一集上是选择
   函数」，再用正规性。若 $U$ 只是精良不正规，等式的哪一侧
   会失效？给出具体反例的函数形状。
3. 命题 1.2 的证明用了「$D\in M$ ⟹ $M\models\kappa$
   可测 ⟹ $T\in D$ 」。第一步 $D\in M$ 需要什么封闭性？
   若只取 $\lambda=\kappa^+$ （而非 $2^\kappa$ ），为什么
   $D\notin M$ ？

---

上一章：[99 强紧基数](99-strongcompact.md) · 下一章：[101 强基数与超强基数](101-strong.md)
