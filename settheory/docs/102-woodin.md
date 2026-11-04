# 102 · 武丁基数

> 第 101 章把「嵌入装下 $V_\lambda$ 」参数化为强性，并造出张子
> 这个一阶化容器。本章取材冯琦第三卷 §1.2.4（书页 134–139；
> PDF 154–159）把容器**当定义用**：定义 1.24 直接以
> $(\kappa,V_{\lambda+1})$ -张子书写武丁基数——对每个 $A \subseteq V_\delta$ 、每个 $\beta<\delta$ ，存在 $\kappa\ge \beta$ 使对一切 $\kappa\le\lambda<\delta$ 有张子 $\varepsilon$
> 满足**等式** $A\cap V_\lambda=j_\varepsilon(A)\cap V_\lambda$
> （$A$ 在 $V_\lambda$ 层被「照原样搬进」目标模型）。引理
> 1.60 给不可达性。定义 1.25 换一套语汇：对每个 $f:\delta\to \delta$ 存在 $\kappa<\delta$ 对 $f$ 封闭且有临界点 $\kappa$
> 的嵌入满足 $V_{j(f)(\kappa)}\subseteq M$ 。定理 1.36 缝合四种
> 说法（局部见证族 / 荟萃 / 函数版嵌入 / 函数版张子）。定理
> 1.37/1.38 完成三级跳：超强 ⟹ 谢拉赫 ⟹ 武丁（且下方武丁荟萃），
> 推论 1.13 由 $2^\kappa$ -超紧一步到位。事实 1.2.2 给出可测 ×
> 武丁 ⟹ 弱紧 × 武丁荟萃，并注明**最小武丁基数不是弱紧**。
>
> 机器边界：武丁本体（四款等价的 (c)→(b) 反射论证、M 内自举）
> 在超穷高度；七个通道做「**每个函数都有足够强见证**」这一全称
> 量词的有限面——f-闭包点 `closed f κ` 的判定与枚举（256 个
> 函数全扫描）、**见证必须随函数变化**的分离对（c1/c13 与
> 后继型敌人）、f-谢拉赫型条款与失败原因二分类（闭包位 /
> 捕获位）。

## 102.1 定义 1.24：张子语法成为定义本身

> **定义 1.24** 称一个正则基数 $\delta$ 为一个**武丁基数**
> 当且仅当对于每一个 $A\subseteq V_\delta$ ，以及每一个
> $\beta<\delta$ ，一定存在一个具备下述特性的基数
> $\kappa\ge\beta$ ：对于任意基数 $\kappa\le\lambda<\delta$ ，
> 在 $V$ 中存在一个 $(\kappa,V_{\lambda+1})$ -张子
> $\varepsilon$ 以至于由 $\varepsilon$ 所确定的超幂嵌入映射
> $j_\varepsilon:V\to M_\varepsilon$ 满足等式
> $$A\cap V_\lambda \;=\; j_\varepsilon(A)\cap V_\lambda.$$

先读懂量词的形状。外层是对 $A$ 与 $\beta$ 的全称（「无论
你给哪块 $V_\delta$ 的子集、无论你把下界抬多高」），中层是
对 $\kappa$ 的存在（「总有一个够高的候选」），内层又是对
$\lambda\in[\kappa,\delta)$ 的全称（「这个候选对**一切**塔高
都工作」）。三层量词的顺序 $\forall A\,\forall\beta\,\exists \kappa\,\forall\lambda\,\exists\varepsilon$ 刻画了「局部见证族」：
见证 $\kappa$ 允许依赖 $A$ 与 $\beta$ ，但不允许依赖
$\lambda$ ——**同一个 $\kappa$ 要管住整段塔高**。这一点
是武丁基数与「$\delta$ 下方有不可数多可测」的本质区别，
也是 102.6 节「单一嵌入不够」的量词根源。

核心等式 $A\cap V_\lambda=j_\varepsilon(A)\cap V_\lambda$ 是
本章的心脏。它不是说 $j_\varepsilon$ 固定 $A$ （那要求
$A\in M_\varepsilon$ 且逐点不动——太强），而是说**在
$V_\lambda$ 这一层以下，$A$ 与它的像无差别**：任何
$\rho<\lambda$ 、任何 $x\in V_\rho$ ，$x\in A\iff x\in j_\varepsilon(A)$ 。张子的坐标网恰好够细，能把 $j$ 对
$A$ 的「外科手术」全部推到 $V_\lambda$ 之外。第 101 章
引理 1.59 说支撑 $Y=V_{\lambda+1}$ 整块进入 $M_\varepsilon$
——等式的左边 $A\cap V_\lambda$ 因此是 $M_\varepsilon$
看得见的对象，等式本身在 $M_\varepsilon$ 内可陈述。

一阶化三步史的第三步在此落位：可测性用**超滤子**替换嵌入
量词（第 94 章），强性用**张子族**替换（第 101 章定理 1.32），
武丁性则**直接用张子书写定义**——不先说嵌入再等价翻译，
而是把「$A$ 在 $\lambda$ 层被原样搬运」作为第一条款。
原因在第 93 章的两条问题线已埋下：实数正则性需要的不是「某个
塔高被装下」，而是「**每个参数集**各自被某段塔高装下」——
参数 $A$ 必须进入定义的语法。

再掂一下「参数 $A\subseteq V_\delta$ 」的信息量：
$V_\delta$ 有 $2^{|V_\delta|}$ 个子集，定义 1.24 要求
对**每一个**都有见证族——这是对整个幂集的均匀性要求，
也是武丁性「难以被单点构造满足」的根源（第 93 章的强度
谱系里，武丁的一致性强度严格高于「存在任意大的强」）。
对照练习 1.11（可测基数上 $\langle A_\alpha\rangle$
型的序列可被单一 $A$ 编码到荟萃），武丁性对 $A$ 的
全称使这种「编码捷径」失效——每个 $A$ 都要自己的
$\kappa$ 。机器面（102.6 节）正是把这一点做成了可枚举的
账本。

## 102.2 引理 1.60：武丁基数不可达

> **引理 1.60** 如果 $\delta$ 是一个武丁基数，那么 $\delta$
> 是一个不可达基数。

**证明**分两笔。**强极限**：取 $A=\emptyset$ ，定义 1.24 给出
任意大的 $\kappa<\delta$ 对一切 $\lambda<\delta$ 是
$\lambda$ -强（保持 $\emptyset$ 作用）；取 $\lambda=\kappa$
得 $(\kappa,\kappa+1)$ -强，即 $\kappa$ 可测（第 101 章的
观察）。于是 $\delta$ 之下有任意大的可测基数，每个可测
$\kappa$ 是强极限之上的不可达，故 $\delta$ 是强极限的极限
——强极限。

**正则性（书 p135 的反证）**：设 $\mathrm{cf}(\delta)<\delta$
（定义虽预设正则，此账说明见证性本身已把 $\delta$ 的共尾度
顶满）。令 $A$ 为从 $\mathrm{cf}(\delta)$ 到 $\delta$ 的
单调递增连续收敛列（作为序对集 $A\subseteq V_\delta$ ）。取
$\beta>\mathrm{cf}(\delta)$ 与见证 $\kappa\ge\beta$ 。取
$\alpha<\mathrm{cf}(\delta)$ 使 $A(\alpha)>\kappa$ （收敛列
共尾）；取基数 $\lambda$ 满足 $A(\alpha)<\lambda<\delta$ ；
取 $(\kappa,\lambda)$ -强嵌入 $j$ 使 $A\cap V_\lambda= j(A)\cap V_\lambda$ 且 $j(\kappa)>\lambda$ 。现在看序对
$(\alpha,A(\alpha))\in A$ ：两坐标都 $<\lambda$ ，故
$(\alpha,A(\alpha))\in A\cap V_\lambda$ 。但
$$j(A)(\alpha)=j(A)(j(\alpha))=j(A(\alpha))>A(\alpha)$$

（$A(\alpha)>\kappa=\mathrm{Crit}(j)$ ，故 $j(A(\alpha))> A(\alpha)$ ；而 $\alpha<\mathrm{cf}(\delta)<\kappa$ 被 $j$
固定）。于是 $(\alpha,A(\alpha))\notin j(A)\cap V_\lambda$ ——
与等式矛盾。∎

反证的机关：**收敛列的图（graph）把「$j$ 在临界点下方不动、
在临界点上方跳升」这两种行为挤压到同一个序对上**。这一招在
定理 1.36 的 (a)→(d) 里原样重演（$A=f$ 的情形），值得记住
名字：**图挤压**。

引理 1.60 的两笔账还可以对读出「武丁 ⟹ $\delta$ 是可测
基数的极限」的加强事实：强极限一笔实际证明了下方有任意大
的可测（取 $A=\emptyset$ 、$\lambda=\kappa$ ），所以
$\delta$ 不但是不可达，还是**可测基数的极限**——比
「$\delta$ 不可达」更强的下方结构。第 101 章定理 1.35
（超紧下方超强荟萃）与本章推论 1.13 沿同一方向走得更远：
假设越强，下方「成片出现」的基数等级越高。这条「上方假设
换下方景象」的汇率表是阅读第三卷后半的钥匙。

## 102.3 定义 1.25 与「保持 A 作用」语汇

> **定义 1.25** 称一个正则基数 $\delta$ 为一个武丁基数当且
> 仅当对于每一个函数 $f:\delta\to\delta$ 而言，一定存在一个
> $\kappa<\delta$ 以及存在一个同质嵌入映射 $j:V\to M$ 来
> 见证下述事实：
>
> (i) $\forall\alpha<\kappa\;(f(\alpha)<\kappa)$ （$\kappa$
> 对 $f$ **封闭**）；
>
> (ii) $V_{j(f)(\kappa)}\subseteq M$ 。

书中先引入一个接口名词（p135–136）：设 $\kappa\le\lambda$
为基数、$A$ 任意集合。称 $\kappa$ 是一个**保持 $A$
作用的 $\lambda$ -强基数**，当且仅当存在 $j:V\to M$ ：
(i) $\mathrm{Crit}(j)=\kappa$ 、$\lambda<j(\kappa)$ ；
(ii) $V_\lambda\subseteq M$ ；(iii) $A\cap V_\lambda=j(A)\cap V_\lambda$ 。于是：$\lambda$ -强 = 保持 $\emptyset$ 作用的
$\lambda$ -强；$\delta$ 武丁 ⟺ 对每个 $A\subseteq V_\delta$ 、每个 $\beta<\delta$ ，有 $\kappa\in(\beta, \delta)$ 对**一切** $\lambda<\delta$ 都是保持 $A$
作用的 $\lambda$ -强。

定义 1.25 的两个新要素各自的功能：**闭包条款 (i)** 保证
$f``\kappa\subseteq\kappa$ ——$\kappa$ 是 $f$ 的「不动
区间」，于是 $j(f)\upharpoonright\kappa=f\upharpoonright\kappa$
（临界点下方逐点不动），$j(f)(\kappa)$ 才是「$\kappa$
之外 $f$ 的延长」的像值；**高度条款 (ii)** 用 $j(f)(\kappa)$
本身当塔高——嵌入的像函数值决定目标模型要装多高，$f$ 越
「爬升」，$j(f)(\kappa)$ 越高，$M$ 越大。两条款合读：
**武丁性 = 「任何爬升函数都有自己的高塔」**。

> **定理 1.36** 设 $\delta$ 是一个不可数的正则基数。下述
> 命题对等：
>
> (a) 对每个 $A\subseteq V_\delta$ 有 $\kappa<\delta$ 对
> 一切 $\kappa\le\lambda<\delta$ 保持 $A$ 作用地
> $\lambda$ -强；
>
> (b) 对每个 $A\subseteq V_\delta$ ，集合
> $\{\kappa<\delta\mid\kappa\text{ 对一切 }\lambda<\delta \text{ 保持 }A\text{ 作用地 }\lambda\text{-强}\}$ 是
> $\delta$ 的**荟萃**子集；
>
> (c) 对任意 $f:\delta\to\delta$ 有 $\kappa<\delta$ ：
> $\forall\alpha<\kappa(f(\alpha)<\kappa)$ ，且存在临界点
> $\kappa$ 的嵌入 $j:V\to M$ 使 $V_{j(f)(\kappa)} \subseteq M$ ；
>
> (d) 对任意 $f:\delta\to\delta$ 有 $\kappa<\delta$ ：
> 闭包条款，且存在长度 $\lambda<\delta$ 的 $(\kappa, \lambda)$ -张子 $\varepsilon\in V_\delta$ 使
> $j_\varepsilon(f)(\kappa)=f(\kappa)$ 且
> $V_{j(f)(\kappa)}\subseteq M_\varepsilon$ 。

书中策略「只需证明 (a)→(d) 与 (c)→(b)」——其余蕴含是定义
的直译或第 101 章机器的复用。(b) 与 (a) 的差是「**一个见证**
」到「**荟萃多见证**」，(c) 与 (d) 的差是「嵌入版」到「张子
版」（$j_\varepsilon(f)(\kappa)=f(\kappa)$ 是闭包条款的像侧
对偶：像函数在 $\kappa$ 处也不动）。

**(a)→(d) 的三步账**（书 p136）：设 $f:\delta\to\delta$
（$\delta$ 由 (a) 已不可达）。视 $A=f$ （函数是其图的
子集，$\subseteq V_\delta$ ）。取见证 $\kappa$ ，选
$\lambda<\delta$ 足够大：
$$\lambda \;>\; |V_{j(f)(\kappa)}|+\kappa^+ + \sup\{f(\alpha)\mid\alpha\le\kappa\}$$

（由 $\delta$ 不可达，这样的 $\lambda$ 存在）。取
$(\kappa,\lambda)$ -强嵌入 $j$ 使 $V_{j(f)(\kappa)} \subseteq M$ 且 $A\cap V_\lambda=j(A)\cap V_\lambda$ 。

- **闭包反证**：若有 $\alpha<\kappa$ 使 $f(\alpha)\ge \kappa$ ，则 $j(f)(\alpha)=j(f(\alpha))\ge j(\kappa)> \lambda>f(\alpha)$ ，序对 $(\alpha,f(\alpha))$ 在
  $A\cap V_\lambda$ 而不在 $j(A)\cap V_\lambda$ ——图挤压
  矛盾。故 $\kappa$ 对 $f$ 封闭。
- **像侧不动**：$\kappa<\lambda$ 且 $A\cap V_\lambda= j(A)\cap V_\lambda$ ，故 $j(f)(\kappa)=f(\kappa)$ （$\kappa$
  处的图在两边一致）。
- **张子化**：取 $j$ 导出的 $(\kappa,\lambda)$ -张子
  $\varepsilon$ ——由 $\lambda<\delta$ 与 $|V_\lambda|< \delta$ ，$\varepsilon\in V_\delta$ ，且 (d) 全款成立。∎

**(c)→(b) 的反射论证**（书 p136–137）是本章最深的一块：
设 $A\subseteq V_\delta$ 、$C\subseteq\delta$ 无界闭。
要找 $\kappa\in C$ 保持 $A$ 作用地全域 $\lambda$ -强。
先由 (c) 推 $\delta$ 是正则极限基数（两个反例函数：共尾
列的整合、后继基数的指示——它们都没有闭包点）。然后定义
**反射函数**：$f(\alpha)=$ 「$C$ 中最小的极限序数
$\beta$ 使『$\alpha'\le\alpha$ 都不是保持 $A$ 作用的
$\alpha'$ -强』这段失败在 $\beta$ 以下已经定型」，否则
$\min(C-\alpha)$ 。(c) 给出对 $f$ 封闭的 $\kappa$ 与
$V_{j(f)(\kappa)}\subseteq M$ ；由 $C$ 对 $f$ 封闭得
$C\cap\kappa$ 无界于 $\kappa$ 、$\kappa\in j(C)$ 。
**M 内自举**：反设在 $M$ 中有最小反例 $\lambda$ ；由
$f$ 的定义 $\lambda\le j(f)(\kappa)$ ；取 $j$ 导出的
$(\kappa,\lambda)$ -张子 $\varepsilon$ ——关键三连：
$\varepsilon\in M$ （编码序列被 $V_{j(f)(\kappa)} \subseteq M$ 装下）；在 $M$ 中 $\varepsilon$ 是
$(\kappa,\lambda)$ -张子且 $(V_\lambda)^M=V_\lambda \subseteq\mathrm{ult}(M,\varepsilon)$ ；核心等式链
$$j_\varepsilon^M(j(A))\cap V_\lambda \overset{引理1.59}{=}(j(A)\cap V_\lambda)^M = j(A\cap V_\lambda) = \cdots = j(A)\cap V_\lambda$$

把 $M$ 内的「$\kappa$ 保持 $j(A)$ 作用」拉回 $V$ 中
「$\kappa$ 保持 $A$ 作用」。矛盾于反例最小性，断言得证，
初等性把 $\kappa\in C$ 与全域强性拉回 $V$ 。∎

这条证明的发动机仍是第 100/101 章的四步模板（**序列/塔封闭
⟹ 见证对象落入 $M$ ⟹ $M$ 内自举 ⟹ 拉回**），新配料是
**反射函数** $f$ ——把「荟萃性」编码成「函数的闭包点」，
让 (c) 的机器接手。反射函数的设计（失败定型于极限点）值得
细读：它把全称量词「对一切 $\alpha'\le\alpha$ 」折叠进一个
序数值。

四款等价各自的用途可以点名：(a) 是**验证版**（拿到具体
$A$ 时检查 $\kappa$ 的工作范围最直接）；(b) 是**分布版**
（给后续的测度/理想论证供料——「荟萃多」意味着任何俱乐部
都能取到见证）；(c) 是**机器版**（只用函数与嵌入，张子隐身
——定理 1.38 与第 103 章以后力迫论证的主用形态）；(d) 是
**一阶版**（$\varepsilon\in V_\delta$ 使整个见证落在
$V_\delta$ **内部**——实数正则性论证只需要 $V_\delta$
内的账目，这正是 Woodin 原始动机的形状）。等价定理的价值
不在「四选一」，而在**随用取形**：内模型理论用 (d)，决定性
论证用 (c)，荟萃反射用 (b)。

## 102.4 三级跳：超强 ⟹ 谢拉赫 ⟹ 武丁

> **定理 1.37** 如果 $\kappa$ 是一个超强基数，那么 $\kappa$
> 是一个**谢拉赫**（Shelah）基数，即对于每一个函数
> $f:\kappa\to\kappa$ 都有一个以 $\kappa$ 为临界点的
> 同质嵌入映射 $j:V\to M$ 以至于 $V_{j(f)(\kappa)} \subseteq M$ 。且 $\{\alpha<\kappa\mid\alpha\text{ 谢拉赫}\}$
> 荟萃于 $\kappa$ 。

**证明**一行见底：$V_{j(\kappa)}\subseteq M$ （超强）且对
任意 $f:\kappa\to\kappa$ 有 $j(f)(\kappa)<j(\kappa)$ （像
函数在 $j(\kappa)$ 处取值必 $<j(\kappa)$ ，因为 $j(f): j(\kappa)\to j(\kappa)$ ），故
$$V_{j(f)(\kappa)}\subseteq V_{j(\kappa)}\subseteq M.$$

荟萃部分照抄第 101 章定理 1.35 的三行账：导出张子
$\varepsilon(\kappa,Y)\in V_{j(\kappa)}\subseteq M$ ，
$M$ 内自举「$\kappa$ 是 $f$ -谢拉赫」，拉回正规测度。∎

> **定理 1.38** 如果 $\kappa$ 是一个谢拉赫基数，那么
> $\kappa$ 是一个武丁基数，且 $\{\alpha<\kappa\mid \alpha\text{ 武丁}\}$ 荟萃于 $\kappa$ 。

**证明**的妙笔是**换函数**：设 $f:\delta\to\delta$ （要证
武丁的那个 $\delta=\kappa$ ）。定义
$$g(\alpha)=\text{最小的严格大于 }f(\alpha)+\alpha\text{ 的不可达基数}.$$

取 $g$ -谢拉赫嵌入 $j$ （$V_{j(g)(\kappa)}\subseteq M$ ）。
由 $g``\kappa\subseteq\kappa$ 型的闭包（$g(\alpha)>\alpha$
且不可达，序列爬升不过 $\kappa$ ——精确地，$\kappa$ 对
$g$ 封闭因 $g(\alpha)<\kappa$ 对 $\alpha<\kappa$ ，由
$g$ -谢拉赫见证的闭包款），导出张子
$\varepsilon(\kappa,Y)\in V_{j(g)(\kappa)}\subseteq M$ ，且
$$j_\varepsilon(f)(\kappa)=j(f)(\kappa)$$

（因子映射 $k_\varepsilon$ 固定 $j(f)(\kappa)$ ——第 101
章的账）。于是 $M\models$ 「$\varepsilon(\kappa,Y)$ 见证
$\kappa$ 是 $f$ -武丁」，初等性拉回 $V$ ：$\kappa$
$f$ -武丁。$f$ 任意，故 $\kappa$ 武丁。荟萃部分：令
$U=\{X\subseteq\kappa\mid\kappa\in j(X)\}$ （$g$ -谢拉赫
嵌入给出的正规测度），$V_{\kappa+1}\subseteq M$ 使
$M\models\kappa$ 武丁，拉回 $\{\alpha\mid\alpha\text{ 武丁}\}\in U$ 。∎

为什么要把 $f$ 抬成 $g$ ？武丁见证需要的目标塔高是
$V_{j(f)(\kappa)}$ ，而张子要「住在」$V_{j(g)(\kappa)}$
里；$g$ 的每个值都是不可达基数保证塔高有足够的余量装下
编码。**换函数 = 给机器留余量**——同一招在定理 1.36(a)→(d)
的 $\lambda$ 选取处已经用过（$\lambda>|V_{j(f)(\kappa)}|+ \cdots$ ）。

> **推论 1.13** 如果 $\kappa$ 是 $2^\kappa$ -超紧基数，
> 那么 $\{\alpha<\kappa\mid\alpha\text{ 武丁}\}$ 是 $\kappa$
> 的一个荟萃集合。

由定理 1.35（超紧 ⟹ 超强荟萃）+ 定理 1.37 + 定理 1.38 竖着
串起来即可。

> **事实 1.2.2** 如果一个可测基数 $\kappa$ 还是武丁基数，
> 那么 $\{\alpha<\kappa\mid\alpha\text{ 既武丁又弱紧}\}$
> 是 $\kappa$ 的荟萃子集。

**证明**：取 $\kappa$ 上正规超滤子 $U$ 、$j=\mathrm{ult} (V,U)$ 。超幂对 $\kappa$ -序列封闭（${}^\kappa M\subseteq M$ ，第 94 章），故 $V_{\kappa+1}^{M}=V_{\kappa+1}$ ，
$M\models$ 「$\kappa$ 既武丁又弱紧」（武丁性是
$V_{\kappa+1}$ 上可表达的？——由定理 1.36(d)，武丁性经由
「对每个 $f$ 有张子 $\varepsilon\in V_\delta$ 」表达，
$\delta=\kappa$ 的版本在 $M$ 中与 $V$ 中一致），拉回
$U$ 。∎ 书中随后给出结构性注记：**最小的武丁基数一定不是
弱紧基数**；若 $\kappa$ 既武丁又弱紧，则 $\kappa$ 之下
有任意大的武丁基数（$\kappa$ 是武丁基数的极限）。机制：
正规测度 $U$ 的拉回只给「$U$ -测一地反射」（$\kappa$
**之上**看下来的像），而弱紧性对 $\Pi^1_1$ 语句的紧致性
反射把「下方武丁无界」顶出来——两条反射通道（测度论与
紧致性论）在 $\kappa$ 处交汇时的合成效应。这个注记也给出
谱系定位：**武丁严格弱于超紧**（推论 1.13 里超紧是「上方
假设」），且武丁与弱紧的交叠已有结构约束——第 111 章投影
集与第 113 章普遍 Baire 将反复引用这两条反射通道。

## 102.5 与 Laver 函数的镜像对照

定义 1.25 的形状值得与第 100 章定理 1.30（Laver 函数）并排
看——两者都处理「预测函数值的嵌入」但**方向相反**：

| | Laver（定理 1.30） | 武丁（定义 1.25） |
|---|---|---|
| 量词 | $\exists f\,\forall x\,\exists j$ （一个函数预测一切目标） | $\forall f\,\exists\kappa\,\exists j$ （一切函数各有见证） |
| $f$ 的角色 | 被嵌入读取的**日程表**（$j(f)(\kappa)=x$ 命中目标） | 被嵌入超越的**爬升者**（$V_{j(f)(\kappa)}\subseteq M$ 装下其像） |
| 见证结构 | 超紧嵌入族，目标 $x$ 可控 | 局部见证族 $\kappa(f)$ ，塔高由 $j(f)(\kappa)$ 定 |
| 强度背景 | 超紧 | 武丁（严格弱于超紧：可测 × 武丁才够弱紧反射） |

一句话：**Laver 是「以一驭万」，武丁是「万各有驭」**。第
110 章马丁极大原理与第 113 章普遍 Baire 会各取一种方向——
这个对照表在全谱里反复回来。

还有一层结构对照：Laver 函数 $f:\kappa\to V_\kappa$ 的值
域是整个 $V_\kappa$ （「预测任意集合」），而武丁量词里的
$f:\delta\to\delta$ 只是序数函数（「爬升者」）。值域的
大小反映两个概念对嵌入的**用途**不同：Laver 要嵌入把
$f(\kappa)$ 槽位**填进**目标（预测），武丁要嵌入把
$f$ 的像**装进**目标（容纳）。第 120–121 章投影决定性
的 Martin–Steel 证明里，两种用途会在树参数（tree argument）
的构造中同时出场。

## 102.6 全称量词的机器面：每个函数都要有自己的见证

Task 17 Step 3 的教学要点：**「每个函数都有足够强见证」是
对 $f$ 的全称量词，单一嵌入/单一 $\kappa$ 不够**。机器
通道把这句话拆成三个可验算件：

1. **闭包点依赖** $f$ ：函数 $f:\delta\to\delta$ 的闭包点
   集 $\{\kappa\mid f``\kappa\subseteq\kappa\}$ 随 $f$ 变化。
   常值函数 $c_1$ 的闭包点从 2 起；抬高单点的 $c_{13}$
   （$f(1)=3$ ）从 4 起；**后继型** $f(i)=i+1$ （共尾爬升）
   在有限层**没有**非零闭包点——共尾函数把见证逼到 $\delta$
   边界之外，这正是真实武丁性要求 $\delta$ 正则的原因
   （$\omega$ 型函数在正则 $\delta$ 下爬不到顶）。
2. **敌人存在**：对每个固定 $\kappa$ ，常值函数
   $\kappa$ （$f(0)=\kappa$ ）在 $\kappa$ 处闭包失败——
   「单一 $\kappa$ 服务一切 $f$ 」被逐点证伪。
3. **失败原因二分类**：一个伪见证 $(\kappa,j(f)(\kappa), \mathrm{cap})$ 的失败要么在**闭包位**（某 $i<\kappa$ 使
   $f(i)\ge\kappa$ ），要么在**捕获位**（层 $j(f)(\kappa)$
   不在 cap 中）——两条款独立记账，与定义 1.25(i)(ii) 逐条
   对应。

Julia/Python 的 256 函数全枚举还核出一笔**组合账**：
$\delta=4$ 上恰有 **144** 个函数在 $[1,4)$ 内有闭包点
（容斥 $108+16+20$ ）。初版我曾断言「闭包点集上闭」——
**错账**：$[2,2,2,2]$ 的闭包点集恰为 $\{3\}$ 而无 2
（闭包于 $\kappa$ 不蕴含闭包于更大的 $\kappa'$ ，因为新
坐标 $i\in[\kappa,\kappa')$ 的值可以是 $\kappa'$ ）——
机器枚举当场抓获，容斥账重做。这条错账与真实数学的呼应：
**闭包不是单调条款，是逐点条款**——每个 $\kappa$ 各自
面对 $f\upharpoonright\kappa$ 的全部值。

回到量词账本的全景。定义 1.25 的全称「$\forall f\, \exists\kappa,\exists j$ 」在有限层被替换成「$\forall f\, \exists\kappa$ （数据位）」——$j$ 被约减成
$(j(f)(\kappa),\mathrm{cap})$ 两个数据。这样替换后，
「$\forall f\exists\kappa$ 」在有限层**可以**为真（144
个函数各自配见证），但**见证必须随 $f$ 变化**这一点
不随约减而消失——敌人函数族（常值 $\kappa$ ）对每个
固定 $\kappa$ 都在场。也就是说，机器件证伪的不是
「全称量词本身」，而是「全称量词可被**单一**见证满足」
这个更强的（且直觉上诱人的）命题——恰好是 Step 3 教学
要点的精确化。真实武丁性中，$f\mapsto\kappa(f)$ 的
**选择函数**不可定义（见证只有存在性没有唯一性），这是
它作为「局部见证族」概念的本色；第 110 章 NS_饱和与
第 113 章普遍 Baire 的 $V_\delta$ 版证明会再次用到
「见证族不可均匀化」这件事实。

## 102.7 选定练习（§1.3）

书 p139–142 的练习 1.1–1.15+ 回收全章（乃至全 §1.1–1.2）
的机器。选录与本教程主线相关者（前六条已在正文各章消化，
后两条留作读者的自检题）：

- **练习 1.1**：$U$ 是 $\alpha$ -完全 ⟺ 超幂
  $\mathrm{ult}(V,U)$ 有秩——良基性与完全性的第一根线
  （第 94 章正文的脚注级事实）。
- **练习 1.5**：$B=\triangle_{s\in[\kappa]^{<\omega}}B_s$
  型对角线交在正规超滤子 $D$ 中——**已机器化**于第 100 章
  Prolog/Julia/Python 的对角线交三通道。
- **练习 1.7**：非平凡 $j:V\to M$ 的三条基本账
  （$\alpha<\kappa\Rightarrow j(\alpha)=\alpha$ ；
  $X\subseteq V_\kappa\Rightarrow X=j(X)\cap V_\kappa$ ；
  $V_\kappa=V_\kappa\cap M$ 的层账）——第 94/101 章反复
  使用的三件套，值得作为「嵌入算术」默写。
- **练习 1.8**：$\lambda=\sup_n j^n(\kappa)$ 时
  ${}^\lambda$...（Kunen 边界的精确形状：$V_{\lambda+2}$ 型条款与第 101 章定义 1.21 后的讨论衔接）。
- **练习 1.13**：$\kappa$ 可测 $\iff$ 存在
  $j:V_{\kappa+1}\to N$ （$N$ 传递）——「一层塔就够」
  的可测性刻画，与第 101 章「可测 = $(\kappa,\kappa+1)$ -
  强」互为表里。
- **练习 1.14**：可测 $\kappa$ 上存在正规 $D$ 使
  $\kappa$ 在 $\mathrm{ult}(V,D)$ 中**不是**可测——
  「最小性自毁」构造，内模型侧（$L[U]$ 唯一性）的伏笔。

## 102.8 机器通道一：Lean——闭包点与见证分离

七个通道共享同一组样本函数（$c_1$ 、$c_{13}$ 、后继型
$f_{\mathrm{succ}}$ 与敌人常值族），但各自的证明形态不同：
Lean 用算术收口（$\kappa-1<\mathrm{fsucc}(\kappa-1)<\kappa$
无整数解）、Coq 用归纳结构、Agda 用构造子分案——三份证明
对同一命题的独立到达构成跨通道对拍，与 Julia/Python 的
枚举对拍互补。

```lean
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Card

/-!
# 第 102 章 · 武丁基数

锚点（有限影子）：
- 闭包点 `closed f κ`（∀ i<κ, f i<κ）——定义 1.25/定理 1.36(c)(d)
  中「κ 对 f 封闭」条款的可判定影子；
- 见证依赖函数：后继型 f 在有限层无非零闭包点——
  「每个函数都有足够强见证」是全称量词，见证必须随 f 变化；
- `FWit` 见证与 f-谢拉赫型条款（闭包 + 层捕获）。
武丁本体（定义 1.24/1.25、定理 1.36-1.38）留在正文。
-/

namespace Settheory.Ch102

/-- f-闭包：∀ i<κ, f i<κ（定义 1.25(i) 的有限影子）。 -/
def closed (f : ℕ → ℕ) (κ : ℕ) : Prop :=
  ∀ i < κ, f i < κ

/-- 后继型函数：i≤3 时 i+1，否则 5。在 [1,5] 内无闭包点——
「共尾爬升」的函数把见证逼到边界之外。 -/
def fsucc : ℕ → ℕ := fun i => if i ≤ 3 then i + 1 else 5

theorem fsucc_gt (i : ℕ) (h : i < 5) : i < fsucc i := by
  by_cases h4 : i ≤ 3
  · simp [fsucc, h4]
  · simp only [fsucc, if_neg h4]
    omega

/-- 后继函数在 1..5 处闭包全部失败：fsucc(κ-1) 恰落在
κ-1 与 κ 之间——整数无此空隙。 -/
theorem fsucc_no_closed : ∀ κ, 1 ≤ κ → κ ≤ 5 → ¬ closed fsucc κ := by
  intro κ h1 h5 hcl
  have hi : κ - 1 < κ := Nat.sub_lt (by omega) (by omega)
  have hlt : fsucc (κ - 1) < κ := hcl (κ - 1) hi
  have hgt : κ - 1 < fsucc (κ - 1) := fsucc_gt (κ - 1) (by omega)
  omega

/-- 常值函数 c1 的闭包点：一切 κ≥2。 -/
def c1 : ℕ → ℕ := fun _ => 1

theorem c1_closed (κ : ℕ) (h : 2 ≤ κ) : closed c1 κ := by
  intro i hi
  simp only [c1]
  omega

/-- 见证记录：临界点、j(f)(κ) 层号、捕获的层集。 -/
structure FWit where
  κ : ℕ
  jfκ : ℕ
  cap : Finset ℕ

/-- f-谢拉赫型条款：闭包 + j(f)(κ)>κ + 第 j(f)(κ) 层被捕获
（V_{j(f)(κ)}⊆M 的影子）。 -/
def fShelah (f : ℕ → ℕ) (w : FWit) : Prop :=
  closed f w.κ ∧ w.κ < w.jfκ ∧ w.jfκ ∈ w.cap

/-- 伪见证样本：c1 在 (κ=2, j(f)(κ)=3, cap={3}) 处成立。 -/
example : fShelah c1 { κ := 2, jfκ := 3, cap := {3} } := by
  show closed c1 2 ∧ 2 < 3 ∧ 3 ∈ ({3} : Finset ℕ)
  exact ⟨c1_closed 2 (by omega), by omega, by simp⟩

/-- 同一条款对后继函数失败——闭包一款就断了。 -/
example : ¬ fShelah fsucc { κ := 2, jfκ := 3, cap := {3} } := by
  intro h
  exact fsucc_no_closed 2 (by omega) (by omega) h.1

/-- 抬高单点：f(1)=3、其余为 1。 -/
def c13 : ℕ → ℕ := fun i => if i = 1 then 3 else 1

/-- c13 在 κ=2 处闭包失败（f(1)=3 ≮ 2）。 -/
example : ¬ closed c13 2 := by
  intro hcl
  have h2 := hcl 1 (by omega)
  simp [c13] at h2

/-- c13 在 κ=4 处闭包成立。 -/
theorem c13_closed_4 : closed c13 4 := by
  intro i _hi
  by_cases h : i = 1
  · simp [c13, h]
  · simp [c13, h]

/-- 见证必须随函数变化：c1 的闭包见证含一切 κ≥2，
而 c13 的闭包见证从 κ=4 才开始——「单一 κ 对一切函数
都够格」在有限层已被 c1/c13 分离证伪。 -/
theorem witnesses_depend :
    (∀ κ, 2 ≤ κ → κ ≤ 4 → closed c1 κ) ∧
    (∀ κ, 1 ≤ κ → κ ≤ 3 → ¬ closed c13 κ) := by
  constructor
  · intro κ h2 _; exact c1_closed κ h2
  · intro κ h1 h3 hcl
    by_cases hκ : κ = 1
    · subst hκ
      have h0 := hcl 0 (by omega)
      simp [c13] at h0
    · have h1' := hcl 1 (by omega)
      simp [c13] at h1'
      omega

end Settheory.Ch102
```

`fsucc_no_closed` 的机关是纯算术：$\kappa-1<\mathrm{fsucc} (\kappa-1)<\kappa$ 在整数里无解（`omega` 一笔收口）。实测
坑三笔：`norm_num` 不在 `Data.Finset.Basic` 的战术集（数字
比较全用 `omega`）；结构字面量的投影（`{κ := 2, ...}.κ`）
对 `omega` 是原子——先 `show` 展开再分治；`intro ⟨hcl, _, _⟩`
对右嵌合取 $A\wedge(B\wedge C)$ 字段数不匹配（改 `h.1`）。

## 102.9 机器通道二：Coq——见证表与共尾反例

```coq
(* 第 102 章：f-闭包点、见证依赖函数与 f-谢拉赫型条款的有限影子。 *)
From Coq Require Import List Arith Bool Lia.
Import ListNotations.

Module Ch102.

(* ── 一、f-闭包：∀ i<κ, f i<κ（定义 1.25(i) 影子）── *)

Definition closed (f : nat -> nat) (k : nat) : Prop :=
  forall i, i < k -> f i < k.

Definition fsucc (i : nat) : nat := if i <=? 3 then i + 1 else 5.

Lemma fsucc_gt : forall i, i < 5 -> i < fsucc i.
Proof.
  intros i Hi. unfold fsucc.
  destruct (Nat.leb_spec i 3) as [H3|H3].
  - assert (i < i + 1) by lia. lia.
  - lia.
Qed.

(* 后继函数在 [1,5] 内无闭包点：fsucc(κ-1) 落在 κ-1 与 κ 之间。 *)
Theorem fsucc_no_closed :
  forall k, 1 <= k -> k <= 5 -> ~ closed fsucc k.
Proof.
  intros k H1 H5 Hcl.
  assert (Hi : k - 1 < k) by lia.
  specialize (Hcl (k - 1) Hi).
  pose proof (fsucc_gt (k - 1) ltac:(lia)) as Hgt.
  lia.
Qed.

(* ── 二、见证依赖函数：c1 与 c13 的见证集分离 ── *)

Definition c1 (_ : nat) : nat := 1.
Definition c13 (i : nat) : nat := if i =? 1 then 3 else 1.

Lemma c1_closed : forall k, 2 <= k -> closed c1 k.
Proof. intros k Hk i Hi. unfold c1. lia. Qed.

(* c13 的最小闭包点是 4：[1,3] 内全部失败。 *)
Theorem c13_no_closed :
  forall k, 1 <= k -> k <= 3 -> ~ closed c13 k.
Proof.
  intros k H1 H3 Hcl.
  destruct (Nat.eq_dec k 1) as [E|NE].
  - subst k. assert (Hb : closed c13 1 -> False).
    { intro H. specialize (H 0 ltac:(lia)). unfold c13 in H.
      destruct (Nat.eqb_spec 0 1); simpl in H; lia. }
    apply Hb; exact Hcl.
  - assert (Hb : closed c13 k -> False).
    { intro H. specialize (H 1 ltac:(lia)). unfold c13 in H.
      destruct (Nat.eqb_spec 1 1); simpl in H; lia. }
    apply Hb; exact Hcl.
Qed.

Lemma c13_closed_4 : closed c13 4.
Proof.
  intros i Hi. unfold c13.
  destruct (Nat.eqb_spec i 1) as [E|NE].
  - subst i; lia.
  - lia.
Qed.

(* 见证必须随函数变化：单一 κ 无法同时服务两个函数。 *)
Corollary witnesses_depend :
  (forall k, 2 <= k -> k <= 4 -> closed c1 k) /\
  (forall k, 1 <= k -> k <= 3 -> ~ closed c13 k).
Proof.
  split.
  - intros k H2 _. apply c1_closed. exact H2.
  - exact c13_no_closed.
Qed.

(* ── 三、f-谢拉赫型条款（闭包 + j(f)(κ)>κ + 层捕获）── *)

Record FWit := mkFWit {kappa_ : nat; jfk : nat; cap : list nat}.

Definition fShelah (f : nat -> nat) (w : FWit) : Prop :=
  closed f (kappa_ w) /\ kappa_ w < jfk w /\ In (jfk w) (cap w).

Example c1_witness : fShelah c1 (mkFWit 2 3 [3]).
Proof.
  split; [|split].
  - simpl. apply (c1_closed 2). lia.
  - simpl. lia.
  - simpl. left; reflexivity.
Qed.

Example fsucc_not_witness : ~ fShelah fsucc (mkFWit 2 3 [3]).
Proof.
  intros [Hcl _]. simpl in Hcl.
  apply (fsucc_no_closed 2); [lia|lia|exact Hcl].
Qed.

(* ── 四、有限见证表：对 δ=4 上的全函数枚举闭包点 ── *)

Definition funcs4 : list (list nat) :=
  (* 四个小样本 + 一个共尾型（无闭包点） *)
  [[1;1;1;1]; [2;2;2;2]; [1;3;1;1]; [1;2;3;3]; [3;3;3;3]].

Definition nthf (l : list nat) (i : nat) : nat := nth i l 0.

Definition closedL (l : list nat) (k : nat) : Prop :=
  forall i, i < k -> nthf l i < k.

(* 表的前两行有闭包点（κ=2 与 κ=3），第三行 κ=4，
   第四五行（共尾型）在 [1,4) 内无闭包点。 *)
Example table_row1 : closedL [1;1;1;1] 2.
Proof. intros i Hi. unfold nthf.
  destruct i as [|[|[|[|i]]]]; simpl; lia. Qed.

Example table_row2 : closedL [2;2;2;2] 3.
Proof. intros i Hi. unfold nthf.
  destruct i as [|[|[|i]]]; simpl; lia. Qed.

Example table_row3 : closedL [1;3;1;1] 4.
Proof. intros i Hi. unfold nthf.
  destruct i as [|[|[|[|i]]]]; simpl; lia. Qed.

(* 共尾型 [1;2;3;3]：κ∈[1,4) 全部失败。 *)
Example table_row4_fail : forall k, 1 <= k -> k <= 3 -> ~ closedL [1;2;3;3] k.
Proof.
  intros k H1 H3 Hcl.
  destruct k as [|[|[|[|k]]]]; try lia.
  - specialize (Hcl 0 ltac:(lia)). unfold nthf in Hcl. simpl in Hcl. lia.
  - specialize (Hcl 1 ltac:(lia)). unfold nthf in Hcl. simpl in Hcl. lia.
  - specialize (Hcl 2 ltac:(lia)). unfold nthf in Hcl. simpl in Hcl. lia.
Qed.

End Ch102.
```

Coq 版贡献**有限见证表**：五行样本的闭包点逐行核算，共尾型
`[1;2;3;3]` 在 $[1,4)$ 全灭。实测坑两笔：record 字面量的
投影（`kappa_ (mkFWit 2 3 [3])`）对 `apply`/`lia` 是黑盒——
`simpl` 先行或 `apply (c1_closed 2)` 显式给参；`destruct k`
后逐 bullet 特化（`try lia` 收 $k=0$ 与 $k\ge4$ 的边角）。

## 102.10 机器通道三：Agda——构造性闭包判定

```agda
-- 第 102 章：f-闭包点的构造性判定、见证依赖函数与
-- f-谢拉赫型条款（闭包 + 层捕获）。
module Ch102_woodin where

open import Data.Nat using (ℕ; zero; suc; _<_; _≤_; z≤n; s≤s)
open import Data.Nat.Properties using (≤-refl; ≤-trans)
open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.List using (List; []; _∷_)
open import Data.Product using (_×_; _,_)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)
open import Relation.Nullary using (¬_)

-- ── 零、自建件 ──

leq : ℕ → ℕ → Bool
leq zero b = true
leq (suc a) zero = false
leq (suc a) (suc b) = leq a b

eq1 : ℕ → Bool
eq1 zero = false
eq1 (suc zero) = true
eq1 (suc (suc i)) = false

z<s : ∀ {n} → zero < suc n
z<s = s≤s z≤n

n≰sucn : ∀ n → ¬ (suc n ≤ n)
n≰sucn zero ()
n≰sucn (suc n) (s≤s p) = n≰sucn n p

-- ── 一、f-闭包（定义 1.25(i) 影子）与函数样本 ──

closed : (ℕ → ℕ) → ℕ → Set
closed f k = ∀ i → i < k → f i < k

fsucc : ℕ → ℕ
fsucc i = if leq i 3 then suc i else 5

c1 : ℕ → ℕ
c1 i = 1

c13 : ℕ → ℕ
c13 i = if eq1 i then 3 else 1

-- ── 二、样本函数的具体闭包事实 ──

-- c1 在一切 κ≥2 处闭包：目标 c1 i < k 即 1<k 即 2≤k——同一事实。
c1-closed : ∀ k → 2 ≤ k → closed c1 k
c1-closed k h i hi = h

-- c13 在 κ=4 处闭包。
c13-closed-4 : closed c13 4
c13-closed-4 zero hi = s≤s (s≤s z≤n)
c13-closed-4 (suc zero) hi = ≤-refl
c13-closed-4 (suc (suc zero)) hi = s≤s (s≤s z≤n)
c13-closed-4 (suc (suc (suc zero))) hi = s≤s (s≤s z≤n)
c13-closed-4 (suc (suc (suc (suc i)))) (s≤s (s≤s (s≤s (s≤s ()))))

-- c13 在 κ=2 处闭包失败：f(1)=3 ≮ 2。
¬c13-2 : ¬ closed c13 2
¬c13-2 h with h (suc zero) ≤-refl
... | s≤s (s≤s ())

-- ── 三、后继型函数：[1,5] 内无闭包点（核心反例） ──

fsucc-gt : ∀ i → i < 5 → i < fsucc i
fsucc-gt zero hi = ≤-refl
fsucc-gt (suc zero) hi = ≤-refl
fsucc-gt (suc (suc zero)) hi = ≤-refl
fsucc-gt (suc (suc (suc zero))) hi = ≤-refl
fsucc-gt (suc (suc (suc (suc i)))) hi = hi

no-gap : ∀ m v → suc m ≤ v → suc v ≤ suc m → ⊥
no-gap m v q (s≤s p) = n≰sucn m (≤-trans q p)

fsucc-not-closed : ∀ k → 1 ≤ k → k ≤ 5 → ¬ closed fsucc k
fsucc-not-closed (suc m) h1 (s≤s h4) hcl =
  no-gap m (fsucc m) (fsucc-gt m (s≤s h4)) (hcl m ≤-refl)

-- ── 四、f-谢拉赫型条款与见证分离 ──

data _∈L_ : ℕ → List ℕ → Set where
  here  : ∀ {x xs} → x ∈L (x ∷ xs)
  there : ∀ {y x xs} → x ∈L xs → x ∈L (y ∷ xs)

record FWit : Set where
  constructor fwit
  field
    κ    : ℕ
    jfκ  : ℕ
    cap  : List ℕ

fShelah : (ℕ → ℕ) → FWit → Set
fShelah f w =
  closed f (FWit.κ w) × (FWit.κ w < FWit.jfκ w × FWit.jfκ w ∈L FWit.cap w)

-- 见证样本：c1 在 (2,3,[3]) 处 f-谢拉赫成立。
c1-wit : FWit
c1-wit = fwit 2 3 (3 ∷ [])

c1-fShelah : fShelah c1 c1-wit
c1-fShelah = c1-closed 2 (s≤s (s≤s z≤n)) , (≤-refl , here)

fsucc-not-fShelah : ¬ fShelah fsucc c1-wit
fsucc-not-fShelah (hcl , _) =
  fsucc-not-closed 2 (s≤s z≤n) (s≤s (s≤s z≤n)) hcl

-- 见证分离：c1 的闭包见证含 κ=2，c13 到 κ=4 才开始——
-- 单一 κ 无法同时服务两个函数。
witnesses-depend :
  (closed c1 2 × closed c13 4) × (¬ closed c13 2 × ¬ closed fsucc 2)
witnesses-depend =
  (c1-closed 2 (s≤s (s≤s z≤n)) , c13-closed-4) ,
  (¬c13-2 , fsucc-not-closed 2 (s≤s z≤n) (s≤s (s≤s z≤n)))
```

Agda 版最甜的一笔是 `c1-closed k h i hi = h`——目标
$f(i)<k$ 即 $1<\kappa$ 即 $2\le\kappa$ ，**与假设同型**，
证明就是假设本身（定义等式 $1<\kappa\equiv 2\le\kappa$ ）。
实测坑三笔：**`1 < 2` 的证明是 `≤-refl` 不是 `s≤s z≤n`**
（$m<n$ 展开为 $\mathrm{suc}\,m\le n$ ，$1<2=2\le2$ ）；
荒谬模式要**剥到空层**（`4 ≤ 2` 需 `(s≤s (s≤s ()))`——一层
`s≤s` 仍合法）；`fsucc-gt` 的 `with leq i 3` 抽象后目标中的
`fsucc i` 不再约简（with 只抽象语法出现处）——改**按 i 分
五案**全部走定义化简，零反思引理。

## 102.11 机器通道四：Julia——256 函数全枚举

```julia
# 第 102 章：f-闭包点枚举、见证依赖函数与伪见证失败原因分类。
println("==== 102")

const DELTA = 4  # 有限论域 {0,1,2,3}：κ 的候选范围 [1,4)

closed(f, κ) = all(f[i+1] < κ for i in 0:κ-1)

# ── 一、全函数枚举：每个 f:4→4 的闭包点集合 ──
allfs = [collect(t) for t in Iterators.product(fill(0:3, DELTA)...)]
@assert length(allfs) == 256

witnesses(f) = [κ for κ in 1:DELTA-1 if closed(f, κ)]

# 手写期望（对拍孤本）：闭包点集合的非空函数恰有几类。
w11 = [1,1,1,1]   # κ=2,3
@assert witnesses(w11) == [2, 3]
w22 = [2,2,2,2]   # κ=3
@assert witnesses(w22) == [3]
w13 = [1,3,1,1]   # κ∈{2,4}\[1,4) → 只有 4 之外；实际 [1,4) 内空
@assert witnesses(w13) == Int[]
cofinal = [1,2,3,3]  # 共尾型：无闭包点
@assert witnesses(cofinal) == Int[]

# 统计对拍：256 个函数中恰有 N 个在 [1,4) 内有闭包点。
n_with = count(f -> !isempty(witnesses(f)), allfs)
# 孤本账（容斥；初版以为「闭包点集上闭」——错账：[2,2,2,2]
# 的见证集恰是 {3} 而无 2，闭包于 κ 不蕴含闭包于更大的 κ'，
# 因为新坐标 i∈[κ,κ') 的值 f(i) 可以 =κ'。正确账）：
#   |A3| = 3³·4 = 108；|A2∖A3| = 2²·4² - 2²·3·4 = 16；
#   |A1∖(A2∪A3)| = 64 - 32 - 36 + 24 = 20；合计 144。
@assert n_with == 108 + 16 + 20
@assert n_with == 144

# ── 二、见证必须随函数变化（单一 κ 不够）──
# 对每个 κ∈[1,4) 找一个在该 κ 处闭包失败的函数：
adversary(κ) = [κ; κ; κ; κ]  # f(0)=κ ≥ κ → 闭包败
for κ in 1:DELTA-1
    @assert !closed(adversary(κ), κ)
end
# 于是「∀f∃κ」的 κ 必须依赖 f：常值 κ 函数把每个固定 κ 都打死。

# ── 三、f-谢拉赫型条款与失败原因分类 ──
struct FWit
    κ::Int
    jfκ::Int
    cap::Vector{Int}
end

fShelah(f, w) = closed(f, w.κ) && w.κ < w.jfκ && w.jfκ in w.cap

# 失败原因：返回 (closure_fail_at, capture_fail)。
function reasons(f, w)
    c = findfirst(i -> f[i+1] >= w.κ, 0:w.κ-1)
    return (c === nothing ? nothing : c - 1,
            !(w.jfκ in w.cap))
end

w = FWit(2, 3, [3])
@assert fShelah([1,1,1,1], w)
@assert reasons([1,1,1,1], w) == (nothing, false)
r = reasons([2,2,2,2], w)          # κ=2 处 f(0)=2 ≥ 2：闭包败于 i=0
@assert r == (0, false)
r2 = reasons([1,1,1,1], FWit(2, 4, [3]))  # 层 4 未捕获：捕获败
@assert r2 == (nothing, true)

println("Julia：256 函数全枚举，有闭包点者 $n_with 个；每个固定 κ 都有敌人；")
println("失败原因二分类（闭包位 / 捕获位）——见证必须随 f 变化")
println("END ====")
```

三条断言线（样本见证集 / 144 容斥 / 敌人）各自独立；**144
容斥账是本章的数学错账现场**——初版「上闭」断言被
`[2,2,2,2]→{3}` 当场推翻，重做容斥 $108+16+20$ 。这也是
有限枚举通道的分工价值：组合断言（「多少函数有见证」）比
存在断言更容易暴露直觉错账。

## 102.12 机器通道五：Python——独立对拍

```python
# 第 102 章：与 Julia 独立对拍——闭包点枚举、容斥总数与失败原因。
import io
import sys
from itertools import product

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

DELTA = 4


def closed(f, k):
    return all(f[i] < k for i in range(k))


def witnesses(f):
    return [k for k in range(1, DELTA) if closed(f, k)]


def main():
    print("==== 102")
    allfs = list(product(range(DELTA), repeat=DELTA))
    assert len(allfs) == 256
    assert witnesses((1, 1, 1, 1)) == [2, 3]
    assert witnesses((2, 2, 2, 2)) == [3]
    assert witnesses((1, 3, 1, 1)) == []
    assert witnesses((1, 2, 3, 3)) == []

    n_with = sum(1 for f in allfs if witnesses(f))
    # 独立容斥（与 Julia 硬编码 144 双账核对）。
    a3 = 3 ** 3 * 4
    a2_only = 2 ** 2 * 4 ** 2 - 2 ** 2 * 3 * 4
    a1_only = 64 - 32 - 36 + 24
    assert n_with == a3 + a2_only + a1_only == 144

    # 见证必须随函数变化：对每个固定 κ 造敌人（常值 κ）。
    for k in range(1, DELTA):
        assert not closed((k, k, k, k), k)

    # f-谢拉赫型条款与失败原因二分类。
    def fshelah(f, kap, jfk, cap):
        return closed(f, kap) and kap < jfk and jfk in cap

    def reasons(f, kap, jfk, cap):
        cf = next((i for i in range(kap) if f[i] >= kap), None)
        return cf, jfk not in cap

    assert fshelah((1, 1, 1, 1), 2, 3, {3})
    assert reasons((1, 1, 1, 1), 2, 3, {3}) == (None, False)
    assert reasons((2, 2, 2, 2), 2, 3, {3}) == (0, False)
    assert reasons((1, 1, 1, 1), 2, 4, {3}) == (None, True)

    # 「每个函数都有见证」的有限核查：只要 cap 覆盖到位、
    # j(f)(κ) 选得高，144 个有闭包点的函数各自可配见证——
    # 但敌人函数（112 个无闭包点者）无 κ 可选：全称量词
    # 的边界在闭包一款就断。
    assert 256 - 144 == 112

    print("Python：256 函数独立枚举 144；容斥双账 108+16+20；")
    print("每个固定 κ 都有敌人；失败原因二分类——与 Julia 对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
```

Python 侧把容斥**展开成三项算式**（Julia 侧只断言总值 144），
两侧独立到达同值——对拍的孤本纪律（82 章确立）。112 个
「无闭包点函数」的清点给全称量词画了精确边界：**任何
$(\mathrm{cap},j(f)(\kappa))$ 配置都救不了闭包失败**——
条款 (i) 是 (ii) 的先决门。

## 102.13 机器通道六：Isabelle——闭包的迭代传递

```isabelle
theory Woodin
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 102 章：f-闭包点（定义 1.25(i) 影子）、闭包的迭代传递性
与「见证必须随函数变化」的分离对（c1/c2）。后继函数无闭包点的
核心反例由 Lean/Coq/Agda 通道承载；武丁本体（定义 1.24/1.25、
定理 1.36-1.38）留在正文。\<close>

definition closedpt :: "[i\<Rightarrow>i, i] \<Rightarrow> o" where
  "closedpt(f, k) \<equiv> \<forall>i. i < k \<longrightarrow> f(i) < k"

text \<open>闭包的迭代传递性：闭包点对 f 的迭代也闭包
（f``k \<subseteq> k ⟹ f\<circ>f``k \<subseteq> k）。\<close>

lemma closedpt_iter:
  assumes "closedpt(f, k)" shows "closedpt(\<lambda>x. f(f(x)), k)"
  using assms unfolding closedpt_def by auto

text \<open>分离对：常值函数 c1 与 c2。\<close>

definition c1 :: "i\<Rightarrow>i" where "c1 \<equiv> \<lambda>i. 1"
definition c2 :: "i\<Rightarrow>i" where "c2 \<equiv> \<lambda>i. 2"

lemma c1_closedpt: "2 \<le> k \<Longrightarrow> closedpt(c1, k)"
  unfolding closedpt_def c1_def by auto

lemma c2_closedpt: "succ(2) \<le> k \<Longrightarrow> closedpt(c2, k)"
  unfolding closedpt_def c2_def by auto

text \<open>c2 在 k=2 处闭包失败：c2(1) = 2 不小于 2。\<close>

lemma c2_not_closed_2: "\<not> closedpt(c2, 2)"
proof -
  have "c2(1) = 2" unfolding c2_def by simp
  moreover have "1 < 2" by simp
  ultimately show ?thesis unfolding closedpt_def by force
qed

text \<open>见证分离：同一 k=2 对 c1 成立、对 c2 失败——
「每个函数都有足够强见证」的全称量词要求见证随函数变化。\<close>

corollary witnesses_depend:
  "closedpt(c1, 2) \<and> \<not> closedpt(c2, 2)"
proof
  show "closedpt(c1, 2)" by (rule c1_closedpt) simp
next
  show "\<not> closedpt(c2, 2)" by (rule c2_not_closed_2)
qed

end
```

Isabelle 版独占**迭代传递**（`closedpt_iter`：闭包点对
$f\circ f$ 也闭包——对 $\delta$ 正则性下「闭包点的爬升
阶梯」的一步）与 ZF 量纲的分离对。实测坑四笔：ZF 的函数
应用是**并置**（`f i`/`f(i)`），反引号 `` ` `` 与复合 `O`
都只对**集合函数**（`f :: i`）可用——`f O f` 须写
`\<lambda>x. f(f(x))`；**`3 \<le> k` 不解析而 `2 \<le> k`、
`succ(2) \<le> k` 解析**（数字字面量 ≥3 在 ZF 序数 `\<le>`
位置的实测怪癖——写 `succ(2)` 绕开）；文本 cartouche 里
手滑的未知控制符号（`\<notmoreless>`）会污染后续解析——
注释里只用中文与已定义符号；`(rule r1 r2 | simp)+` 的多
规则交替对双目标失效——拆 `proof`/`show` 显式两步。

## 102.14 机器通道七：Prolog——局部见证族查询

```prolog
:- encoding(utf8).
% 第 102 章：局部见证族查询——f-闭包点、f-谢拉赫条款与
% 「每个函数都有足够见证」的全称量词检查。

% f 以表表示：nthf(I, F, V)。（整数下标——succ/1 模式不匹配
% 整数，首版只查了 i=0 被对拍抓获。）
nthf(0, [H|_], H).
nthf(I, [_|T], V) :- I > 0, I1 is I - 1, nthf(I1, T, V).

% f-闭包：∀ i<κ, f(i)<κ（定义 1.25(i) 影子）。
closedL(_, 0).
closedL(F, K) :- K > 0, K1 is K - 1, closed_upto(F, K1).

closed_upto(F, MaxI) :- forall((between(0, MaxI, I), nthf(I, F, V)), V < MaxI + 1).

% f-谢拉赫型条款：闭包 + κ<j(f)(κ) + 层捕获。
%（member 先行：Jfk 未绑定时 K < Jfk 会炸 < /2。）
f_shelah(F, K, Jfk, Cap) :-
    closedL(F, K),
    member(Jfk, Cap),
    K < Jfk.

% 局部见证族：对每个函数 f 找一个见证（伍丁型全称量词的有限面）。
has_witness(F, K, Jfk, Cap) :-
    between(1, 3, K),
    f_shelah(F, K, Jfk, Cap).

% 敌人造法：常值 κ 函数在任何 ≥κ 处…… 精确说：
% constant(κ) 在 κ 处闭包失败。
constant(K, F) :- length(F, 4), maplist(=(K), F).

main :-
    format("==== 102~n"),
    % 样本函数的见证集。
    findall(K, (between(1,3,K), closedL([1,1,1,1], K)), W11),
    W11 == [2, 3],
    findall(K, (between(1,3,K), closedL([2,2,2,2], K)), W22),
    W22 == [3],
    \+ closedL([1,3,1,1], 2),
    \+ closedL([1,3,1,1], 3),
    % 敌人：每个固定 κ 被常值 κ 打死。
    forall(between(1,3,K),
           (constant(K, F), \+ closedL(F, K))),
    % f-谢拉赫正反样本。
    f_shelah([1,1,1,1], 2, 3, [3]),
    \+ f_shelah([2,2,2,2], 2, 3, [3]),
    \+ f_shelah([1,1,1,1], 2, 4, [3]),
    % 局部见证族存在性（cap=[2,3,4] 宽捕获下三类函数各有见证）。
    has_witness([1,1,1,1], _, _, [2,3,4]),
    has_witness([2,2,2,2], _, _, [2,3,4]),
    \+ has_witness([1,3,1,1], _, _, [2,3,4]),
    format("见证集 [1,1,1,1]→[2,3]、[2,2,2,2]→[3]；常值 κ 敌人；~n"),
    format("f-谢拉赫正反样本；无闭包点者无见证——全称量词边界在闭包款~n"),
    writeln("END ====").
```

Prolog 版的**局部见证族**查询（`has_witness/4` 双向：给定
$f$ 找见证、给定见证集反查函数族）直接对位定义 1.24 的
量词形状。实测坑两笔：**`nthf(succ(I), ...)` 的 `succ/1`
模式不匹配整数**（`between` 产出整数——首版只检查了
$i=0$ 一项，幸而样本 `[1,3,1,1]` 的期望值 `[]` 把它暴露
成假阳性前的失败）；`K < Jfk` 在 `Jfk` 未绑定时抛
`< /2: Arguments are not sufficiently instantiated`——
`member` 先行绑定。

## 102.15 机器的边界

1. **定理 1.36 的 (c)→(b) 反射论证不可机化**：反射函数
   $f$ （「失败定型于极限点」）的设计、俱乐部 $C$ 的
   封闭性账、$\varepsilon\in M$ 的自举——三件都在超穷
   高度。
2. **图挤压机关只留影子**：引理 1.60 与 (a)→(d) 的反证
   都用「序对 $(\alpha,f(\alpha))$ 在图的一侧不在另一
   侧」——有限版的 `closed` 判定查的只是数值不等，挤压
   的**几何**（图作为集合横跨临界点两侧）不可见。
3. **换函数留余量不可见**：定理 1.38 的 $g$ （抬到不可
   达）与 (a)→(d) 的大 $\lambda$ 选择都是「为机器留空间」
   的超穷操作；有限版 $j(f)(\kappa)$ 只是数据位。
4. **144/112 的边界是组合边界不是强度边界**：112 个无闭包
   点函数在有限层永远救不回，但真实武丁性中「共尾函数无
   闭包点」恰是 $\delta$ 正则性要挡的事——有限层没有
   正则性，边界现象形状相同而机制不同。
5. **张子条款 (d) 的** $j_\varepsilon(f)(\kappa)=f(\kappa)$
   在有限层无从表达（像函数不是数据变换）；机器只核
   (i) 闭包与捕获两端。
6. **七通道的分工图**：Lean/Coq/Agda 证「后继型无闭包点
   + 见证分离」（命题级，三份独立证明互为对拍）；Julia/
   Python 枚举全函数空间（组合级，容斥孤本）；Prolog 做
   见证族的**双向查询**（逻辑级，正反向枚举）；Isabelle
   补迭代传递（$f\circ f$ 的闭包——真实层面对应
   「$\kappa$ 的 $f$ -闭包阶梯」，$\sup_n f^n(\kappa)$
   仍是闭包点，正是引理 1.60 反证里收敛列的角色）。四层
   分工覆盖了定义 1.25 的 (i)(ii) 两条款的有限面，本体
   留正文。

## 102.16 本章要点与检查问题

- **定义 1.24**：$\forall A\subseteq V_\delta\,\forall\beta< \delta\,\exists\kappa\ge\beta\,\forall\lambda\in[\kappa, \delta)\,\exists\varepsilon$ ：$(\kappa,V_{\lambda+1})$ -
  张子使 $A\cap V_\lambda=j_\varepsilon(A)\cap V_\lambda$ ——
  三层量词「见证 $\kappa$ 依赖 $A,\beta$ 、不依赖
  $\lambda$ 」。
- **引理 1.60**：武丁 ⟹ 不可达（强极限由下方任意大可测；
  正则性由**图挤压**反证——收敛列的序对被临界点两侧的
  $j$ -行为撕裂）。
- **定义 1.25/定理 1.36**：函数版（闭包 + $V_{j(f)(\kappa)} \subseteq M$ ）与见证族版等价，四款 (a)(b)(c)(d) 闭环；
  (a)→(d) 三步（图挤压证闭包、层一致证 $j(f)(\kappa)= f(\kappa)$ 、张子化）；(c)→(b) 反射函数 + M 内自举 +
  等式链。
- **三级跳**：超强 ⟹ 谢拉赫（一行账：$j(f)(\kappa)< j(\kappa)$ ）⟹ 武丁（换函数 $g$ 抬到不可达留余量）
  ⟹ 推论 1.13（$2^\kappa$ -超紧 ⟹ 下方武丁荟萃）。
- **事实 1.2.2 与最小性**：可测 × 武丁 ⟹ 弱紧 × 武丁荟萃；
  最小武丁不是弱紧；既武丁又弱紧 ⟹ 下方武丁无界。
- **Laver 对照**：以一驭万 vs 万各有驭——两种「函数-嵌入」
  方向在全谱中反复出现；Laver 值域 $V_\kappa$ （预测）与
  武丁值域 $\delta$ （容纳）的差是用途差。
- **练习回收**：1.1（完全性⟺有秩）、1.5（对角线交——已
  机器化于第 100 章）、1.7（嵌入三事实）、1.8（Kunen 边界
  形状）、1.13（可测 ⟺ $j:V_{\kappa+1}\to N$ ）、1.14
  （最小性自毁）——六条已在正文消化，余者留自检。
- **全称量词的机器面**：闭包点集随 $f$ 变化、常值敌人、
  失败二分类（闭包位/捕获位）、144 = 108+16+20 容斥（初版
  上闭断言是数学错账，被 $[2,2,2,2]\to\{3\}$ 当场抓获）。
- **实测账**：Lean `norm_num` 缺位（用 omega）、结构字面量
  投影原子化（show 展开）、右嵌合取 intro 模式；Coq record
  投影黑盒（simpl 先行）、destruct 后逐 bullet；Agda `1<2`
  是 `≤-refl`、荒谬模式剥层、with 不穿透定义展开（分案替代）；
  Isabelle 并置应用（`` ` ``/`O` 只收集合函数）、**数字 ≥3
  在 ZF `≤` 位置不解析**（`succ(2)` 绕开）、cartouche 未知
  符号污染、多规则交替失效；Prolog `succ/1` 不匹配整数
  （首版只查 i=0）、`<` 未绑定爆炸（member 先行）；
  Julia 侧初版「闭包点集上闭」数学错账（`[2,2,2,2]\to\{3\}`
  查获，容斥重做 144 = 108+16+20）。

检查问题：

1. 定义 1.24 的内层量词「$\forall\lambda\in[\kappa,\delta)$
   存在 $\varepsilon$ 」若改成「$\exists\varepsilon$
   $\forall\lambda$ 」（一个张子管所有塔高），概念变强还是
   变弱？它与「$\kappa$ 是保持 $A$ 作用的 $\delta$ -强」
   （一次性封顶）有什么关系？
2. 引理 1.60 的图挤压反证中，如果 $A$ 换成**递减**的
   $\mathrm{cf}(\delta)$ -长序列（不存在——为什么？），
   论证在哪里失效？共尾性与单调性各贡献了什么？
3. 定理 1.38 的换函数 $g$ 若只抬到「大于 $f(\alpha)+ \alpha$ 的基数」而不要求**不可达**，哪一步要用不可达性？
   （提示：$\kappa$ 对 $g$ 的闭包 + $\lambda$ 的选取。）
4. Julia/Python 枚举中，`adversary(κ)`（常值 κ）证明
   「每个固定 κ 有敌人」。构造一个 $\delta=4$ 上的函数
   $f$ ，使它的闭包点集恰为 $\{3\}$ ；再构造一个使闭包
   点集恰为 $\{1,3\}$ 。两者容斥计数各落在哪一项
   （108/16/20）？
5. 定义 1.25 的条款 (ii) 用 $V_{j(f)(\kappa)}\subseteq M$
   而非 $V_{f(\kappa)^+}\subseteq M$ 。给出一个理由说明
   为什么必须用**像**函数值：若只用 $V$ 侧的 $f(\kappa)$ ，
   $f$ 的哪些行为会逃出检查？（联系 102.11 的 144 边界。）

---

上一章：[101 强基数与超强基数](101-strong.md) · 下一章：[103 小型扩张与 Lévy 崩塌](103-levy.md)
