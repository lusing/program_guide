# 101 · 强基数与超强基数

> 第 100 章把超紧性缝在「正规精良测度 ⟷ 序列封闭嵌入」上；本章沿
> 另一条轴爬升：不要求嵌入对序列封闭，而要求目标模型包含越来越
> 高的累积层次 $V_\lambda$ 。取材冯琦第三卷 §1.2.3（书页 113–133；
> PDF 133–153）。定义 1.18 给出 $(\kappa,\lambda)$ -**强嵌入**
> （$\kappa=\mathrm{Crit}(j)$ 、$j(\kappa)>\lambda$ 、
> $V_\lambda\subseteq M$ ）；命题 1.4 把「强」翻译成「任何集合
> 都落入某个目标模型」。为了把这个二阶概念压回 ZFC 纯语言，书
> 中走完了一条完整的工程线：**导出张子**（从嵌入提取超滤子系统
> $\varepsilon=\{E_a\mid a\in[\lambda]^{<\omega}\}$ 、$X\in E_a \iff a\in j(X)$ ）→ 四条公理（κ-完全、协调性、正规性、
> ω-完全性）→ **张子超幂**（定向极限 + 有秩性两证）→ 定理 1.31
> 的四条嵌入性质 → 定理 1.32：强基数 ⟺ 对每个 $\lambda$ 有
> $(\kappa,V_{\lambda+1})$ -张子——一阶表达达成。然后定义 1.21
> 把目标推到 $V_{j(\kappa)}\subseteq M$ （**超强**），广义张子
> （定义 1.22/1.23，支撑 $Y$ 为传递集合）接住它；定理 1.35
> 收官：$2^\kappa$ -超紧之下超强基数**荟萃**。
>
> 机器边界：张子本体（$\varepsilon$ -超幂、Łoś 定理 1.33）在
> 超穷高度；七个通道做它的地基与账本——位编码有限累积层次
> $V_n$ （beth 尺寸 1,2,4,16 的精确复现，Lean/Coq/Agda/Julia/
> Python/Prolog）、层包含链（Coq/Agda/Isabelle 证明）、导出
> 超滤子对交封闭的记账（Lean `Finset.image_inter`/Coq
> `in_map_inter`）、见证条款检查器（Julia/Python 有限强度矩阵、
> Prolog 反向查询）与「有限捕获不承载全域量词」的鸽笼定理
> （Lean/Coq/Agda 三证明）。

阅读路线图：§101.1–101.2 是概念的提出（定义 1.18 与命题
1.4，可独立阅读）；§101.3–101.5 是本章的技术主体（导出张子
→四公理→张子超幂→特征定理 1.32），建议先通读证明骨架再回
读公理的动机；§101.6–101.7 把支撑推广到传递集合并冲线定理
1.35；§101.8 的三本账表是全章的「防混淆疫苗」，值得在读完
机器通道后重读一遍。机器通道（§101.9–101.15）按「证明三
件套（Lean/Coq/Agda）→计算两件套（Julia/Python）→查询
一件套（Prolog）→真定理一件套（Isabelle）」排列，每个通道
前有任务定位、后有实测坑与设计账。

## 101.1 从可测到强：把目标模型变成塔

先校准本章在整个大基数谱系中的位置。第 94 章的可测基数把
「无穷公理的强度」装进**一个超滤子**：κ-完全非主超滤子的
存在等价于临界点为 κ 的初等嵌入的存在。第 99/100 章把测度
从 κ 搬到 $\mathcal P_\kappa(\lambda)$ ，用**正规精良**换取
序列封闭。本章反其道而行：不动测度的论域，而是不断抬高**目标
模型必须包含的秩层**——「$M$ 里装了多少 $V$ 」成为新的
量纲。这条轴的终点不是超紧（那要序列封闭），而是「强」与
「超强」：强说**每一层**都装得下，超强说连 $j(\kappa)$ 层
（嵌入自己创造的塔顶）都装得下。三条轴（测度论域、序列
封闭、秩层包含）相互独立地度量嵌入的三种「大小」，本章
把第三条轴走到底，也为第 102 章（武丁基数 = 第三条轴上的
局部化 + 参数保持）备好全部机器。

> **定义 1.18** 设 $\kappa\le\lambda$ 是两个序数。称同质嵌入
> 映射 $j:V\to M$ 是一个 $(\kappa,\lambda)$ -**强嵌入**当且
> 仅当
>
> (i) $\kappa=\mathrm{Crit}(j)$ ，并且 $j(\kappa)>\lambda$ ；
>
> (ii) $V_\lambda\subseteq M$ 。
>
> 称 $\kappa$ 为一个 $\lambda$ -**强基数**当且仅当存在一个
> $(\kappa,\lambda)$ -强嵌入映射；称 $\kappa$ 是一个**强基数**
> 当且仅当对于每一个 $\lambda\ge\kappa$ 而言，$\kappa$ 都是
> 一个 $\lambda$ -强基数。

第 94 章的可测基数给出临界点为 $\kappa$ 的嵌入，其目标模型
自动含 $V_{\kappa+1}$ （$j``V_\kappa\subseteq M$ 且临界点下方
逐点不动）。定义 1.18 做的事是把「自动含的那一层」改成**要价**：
$\lambda$ 是参数，$V_\lambda\subseteq M$ 是条款，$\lambda$
要多高有多高。两个直接观察（书 p113）：

- $\kappa$ 可测 $\iff$ $\kappa$ 是 $(\kappa,\kappa+1)$ -
  强基数——可测性恰好是「塔高一层」的强性；
- 超紧 $\Longrightarrow$ 强——${}^\lambda M\subseteq M$ 远强于
  $V_\lambda\subseteq M$ （前者说 $M$ 含一切 $\lambda$ -序列，
  后者只说含一个集合）。

条款 (i) 里 $j(\kappa)>\lambda$ 不是装饰：若 $j(\kappa)\le \lambda$ ，则 $V_{j(\kappa)}\subseteq V_\lambda\subseteq M$ ，而
$M\models V_{j(\kappa)}$ "是最大的层"，与 $j``V_{j(\kappa)} \subseteq M$ 且 $j``V_{j(\kappa)}\notin V_{j(\kappa)}$ 相碰。
临界点的像必须**越过**目标塔顶，嵌入才有提升的空间。

> **命题 1.4** 设 $\kappa$ 是一个序数。下述两个命题对等：
>
> (i) $\kappa$ 是一个强基数；
>
> (ii) 对于任意一个集合 $x$ 都必有一个以 $\kappa$ 为临界点
> 的同质嵌入映射 $j:V\to M$ 以至于 $x\in M$ 。

**证明**。(i)⟹(ii)：任给集合 $x$ ，令 $\lambda> \max\{\mathrm{rk}(x)+1,\kappa\}$ 。取 $(\kappa,\lambda)$ -强嵌入
$j$ ，则 $x\in V_\lambda\subseteq M$ 。(ii)⟹(i)：任给
$\lambda\ge\kappa$ ，令 $x=V_\lambda$ 。取 $j$ 使 $x\in M$ 。
则 $V_\lambda\in M$ 且 $M$ 传递 ⟹ $V_\lambda\subseteq M$ 。∎

命题 1.4 是第 100 章 Laver 定理 1.30 的直接推论：超紧基数的
通用反转函数把**任何**集合 $x$ 送进某个 $j$ 的目标模型，
所以超紧 ⟹ 强有了第二条（更概念化的）证明路线。它同时揭示了
强基数的「形态」：**目标模型是一座可以任意加高的塔**，塔的
高度参数就是强性的量纲。

## 101.2 为什么需要张子：ZFC 纯语言的挑战

定义 1.18 与命题 1.4(ii) 都量词化了**类**（$j:V\to M$ 、
「任意集合都落入某模型」），不是 ZFC 纯语言（一阶、仅量词化
集合）的命题。书中点破的挑战：这种自然概念提升的结果**是否
可以在集合论的纯语言之中得到合适的表达**？

路线是把第 94/97 章的「超滤子表示嵌入」升级为「超滤子**系统**
表示嵌入」。单个超滤子太粗（它只记得 $j$ 在一个坐标上的行为）
或太细（可测以上的嵌入需要无穷多坐标），所以要一整族
$\{E_a\mid a\in[\lambda]^{<\omega}\}$ ——每个 $E_a$ 记住
$j$ 在「坐标 $a$ 」上的一个截面，整族合起来恢复 $j$ 的
足够多行为来重建 $V_\lambda\subseteq M$ 。这就是**张子**
（extender，书中译名「张子」）。

这个一阶化策略值得放回历史脉络看三步。**第一步（可测）**：
「存在临界点 κ 的嵌入」是类量词陈述，但等价的「存在 κ-完全
非主超滤子」是集合陈述——超滤子是 $\mathcal P(\kappa)$ 的
元素，ZFC 纯语言可以谈。第 94 章的Scott 定理（$V\ne L$ ）
恰恰消费了这个一阶化：超滤子作为集合可以问「$L$ 里有没有」。
**第二步（本节）**：强基数的嵌入量词化为张子——一个真类大小
的嵌入被压缩成一个**集合**（坐标域 $[\lambda]^{<\omega}$
是集合、每个 $E_a$ 是集合、全体构成集合大小的族），于是
「κ 是强基数」变成「对每个 λ 存在一个集合满足四条一阶公理」。
**第三步（第 102 章预告）**：武丁基数的定义本身就用张子语言
书写（定义 1.24 直接说「存在 $(\kappa,V_{\lambda+1})$ -张子
使 $A\cap V_\lambda=j_\varepsilon(A)\cap V_\lambda$ 」）——
一阶化不再只是表达工具，而成为**定义本身**的语法。

压缩为什么可能？直观账：嵌入 $j$ 在 $V_\lambda$ 上的全部
行为，由「$X\mapsto a\in j(X)$ 」这些**是/否回答**决定，其中
坐标 $a$ 取遍 $[\lambda]^{<\omega}$ 。要恢复 $V_\lambda \subseteq M_\varepsilon$ ，只需要每个 $\alpha<\lambda$ 有
典型代表（引理 1.56 的恒等函数账）加上超幂的传递化——四条
公理恰好保证这两件事（正规性管代表、ω-完全性管良基）。换句话说，
**张子是嵌入的「截面无损压缩」**：丢掉 $j$ 在 $\lambda$
以上的行为（那是嵌入的「私人领地」），保住 $\lambda$ 以下的
全部（那是强性条款要检查的领地）。

**导出张子**（书 p114）。设 $j:V\to M$ 以 $\kappa$ 为临界
点，$\kappa\le\lambda\le j(\kappa)$ 。对每个 $a\in [\lambda]^{<\omega}$ （$\lambda$ 的非空有限子集），定义
$[k]^{|a|}$ （即 $[\kappa]^{|a|}$ ）上的超滤子：

$$X\in E_a \iff a\in j(X),\qquad X\subseteq[\kappa]^{|a|}.$$

记 $\varepsilon=\{E_a\mid a\in[\lambda]^{<\omega}\}$ 。直观：
$j(X)$ 是 $X$ 在 $M$ 中的像，而 $a$ 是 $\lambda$ 中
的有限点列；$a\in j(X)$ 说的是「把 $a$ 的每个坐标 $\alpha \in a$ 换成 $j(\alpha)$ 后落进 $j(X)$ 的原始版本」。每个
$E_a$ 都是一次**截面采样**：它测量「$X$ 在 $j$ 眼中含
$a$ 的原像」这件事。

## 101.3 张子四公理：从导出过程提炼

书 p114–117 分析导出张子满足的四条性质，然后把它们**独立
出来**作为张子的公理（定义 1.19）。逐条：

**(a) κ-完全超滤子系**。每个 $E_a$ 是 $[\kappa]^{|a|}$ 上的
$\kappa$ -完全超滤子（$j$ 保布尔运算 + 临界点下方不动）；但
$E_{\{\kappa\}}$ 不是 $\kappa^+$ -完全的；且对每个
$\alpha<\kappa$ ，令 $a=\{\alpha,\kappa\}$ ，则
$$\{\beta\;:\;\alpha<\beta<\kappa\}\text{ 型尾段}\in E_a$$

—— $E_a$ 能「看见」$\kappa$ 的尾段，保证后续超幂的临界点
恰为 $\kappa$ 而非更低。（书中还注记 $a=\{\kappa\}$ 时
$E_a$ 是平凡超滤子，它确定的自同构超幂就是 $V$ 自身——
平凡坐标不贡献信息。）

**(b) 协调性**。$a\subseteq b$ 时，按单调排列写出投影
$\pi_{b,a}:[\kappa]^{|b|}\to[\kappa]^{|a|}$ （从 $b$ 的
枚举中挑出 $a$ 的位置）。则
$$X\in E_a \iff \pi_{b,a}^{-1}(X)\in E_b.$$

即**低坐标的测量与高坐标的测量一致**：在 $E_b$ 中测「投
影回 $a$ 后落进 $X$ 」等价于在 $E_a$ 中直接测 $X$ 。这
条是超滤子系统「拼合无矛盾」的胶水（书中注明与迭代超幂表示
部分的引理 1.42 值得对照——同一个投影机制在第 97 章管超滤子
的换坐标，在这里管嵌入的截面）。

**(c) 正规性**。对非空 $a\in[\lambda]^{<\omega}$ 、
$f:[\kappa]^{|a|}\to\kappa$ ，若
$$A_0=\{s : f(s)\in\max(s)\}\in E_a,$$

则存在 $b\supseteq a$ （$\max(a)<\min(b\setminus a)$ 型的
**加高**）使
$$\{t\in[\kappa]^{|b|} : (f\circ\pi_{b,a})(t)\in t\}\in E_b.$$

证明一行见底蕴：令 $b=a\cup\{j(f)(a)\}$ 。由 $\max(a)< \lambda<j(\kappa)$ 有 $b\in[\lambda]^{<\omega}$ ；由
$(f\circ\pi_{b,a})(b)=j(f)(a)\in b$ 立得测一。**正规性 = 「回归
函数可以在加高一个坐标后变成恒同命中」**——第 100 章 P_κ(λ)
正规性的有限坐标版，而加高的那个新坐标恰是 $j(f)(a)$ 本身：
嵌入把自己的函数值递回来当见证。

**(d) ω-完全性**。对任意序列 $a_n\in[\lambda]^{<\omega}$ 、
$X_n\in E_{a_n}$ （$n<\omega$ ），存在保序映射
$g:\bigcup_n a_n\to\kappa$ 使
$$\forall n<\omega\;(g``a_n\in X_n).$$

证明是本章的**树论证**（书 p116–117）：令 $A=\bigcup_n a_n$
（$\subseteq\lambda$ ，序型 $\alpha<\omega_1$ ——$\lambda$
的有限子集的可数并是可数的），传递化 $p:A\cong\alpha$ ，令
$e_m=p``a_m$ ，双射 $s:\omega\to\alpha$ 。造树 $T$ ：
节点是有限保序映射 $t$ （定义域 $s[n]$ 、值域 $\subseteq \kappa$ 、且凡 $e_m\subseteq\mathrm{dom}(t)$ 则 $t`` e_m\in X_m$ ），序为反包含。**关键一步**：在 $M$ 中看
$j(T)$ 。注意 $j(p^{-1}\circ s)=j(p^{-1})\circ j(s)$ 型的
组合给出 $j(T)$ 的一根无穷降树枝——因为 $j(s[n])\supseteq e_m$ 处的检查条件 $j(t)``e_m\in j(X_m)$ 对 $t=p^{-1}$
恒成立（$e_m\subseteq\alpha<\kappa$ 下方 $j$ 不动，
$p^{-1}``e_m=a_m$ 、$a_m\in j(X_m)$ 正是 $X_m\in E_{a_m}$
的定义）。传递模型的有秩关系绝对（树在 $M$ 中有秩函数 ⟹
该函数在 $V$ 中仍是秩函数），初等性把「$j(T)$ 有无穷降
链」拉回「$T$ 有无穷降链」，取树枝 $h:\alpha\to\kappa$ ，
令 $g=p^{-1}\circ h$ 。∎

**ω-完全性的本质是有秩性（良基性）的绝对性**：树在传递模型
$M$ 中有秩 ⟹ 在 $V$ 中有秩。这个论证模式在本教程已经
是第三次出场——第 83 章（超幂 $\mathbb N^\omega/U$ 的
$\in^*$ 传递性用余有限滤子的有限交）、第 97 章（Gaifman
定理：迭代超幂的良基性由单步良基性归纳，树论证管极限步），
本章是它的**对偶使用**：前两次用「良基性可遗传/可提升」造
模型，这次用「良基性绝对」从 $M$ 内的树枝**提取**$V$
中的协调见证 $g$ 。三处共用一个朴素事实：良基性不是一阶
性质，但对**传递**模型是绝对的——这正是超幂传性化（π）在
整个大基数机器里反复出现的原因。

四条公理的分工总结成一句话：**(a) 让每个坐标各自是测度，
(b) 让坐标之间不吵架，(c) 让支撑有典型代表，(d) 让整体良
基**。第 94 章单个超滤子的「κ-完全 + 非主」两条件是 (a)(d)
在单坐标情形的退化版；(b)(c) 是**系统**特有的新税——协调
性税（投影一致性）与正规性税（恒同表示），它们正是「测度
搬家」从 $\mathcal P(\kappa)$ 到 $[\kappa]^{|a|}$ 族时
必须缴纳的。

## 101.4 张子超幂：定向极限与两证有秩性

**(e) 因子分解**（书 p117–118）。每个 $E_a$ 单独可用：
$\mathrm{ult}(V,E_a)$ 、传递化 $N_a$ 、因子映射
$$k_a([f]_{E_a})=j(f)(a)$$

满足 $j=k_a\circ\pi_a\circ i_a$ 。协调性 (b) 保证 $a\subseteq b$ 时有 $i_{a,b}:N_a\to N_b$ 架起**定向系统**
$\langle N_a,i_{a,b}\mid a\subseteq b\in[\lambda]^{<\omega} \rangle$ ，其定向极限嵌入 $M$ （经 $k_\varepsilon=\lim_a k_a$ ）。于是 $j=k_\varepsilon\circ\pi_\varepsilon\circ j_\varepsilon$ ——第 100 章末尾因子分解的**系统版**：不是
一次分解，而是一整张交换图。

**张子超幂的显式构造**（定义 1.20，书 p122）。论域
$$\mathcal D=\{(a,f)\mid a\in[\lambda]^{<\omega},\; f:[\kappa]^{|a|}\to V\},$$

$$(a,f)\equiv(b,g) \iff \{s\in[\kappa]^{|a\cup b|} : (f\circ\pi)(s)=(g\circ\pi)(s)\}\in E_{a\cup b},$$

$\in_\varepsilon$ 同理。核心断言（书 p119）：
$$[(a,f)]\in_\varepsilon[(b,g)] \iff j(f)(a)\in j(g)(b).$$

这个断言把**抽象商结构与嵌入的具体行为**焊接——它是后面一切
（因子映射良定义、Łoś、典型表示）的单点锚。

**有秩性两证**（书 p119–120）。第一证（依赖 $j$ ）：由核心
断言，$(\mathcal D/{\equiv},\in_\varepsilon)$ 经
$k_\varepsilon$ 嵌入传递模型 $(M,\in)$ ，良基性遗传。第二证
（**放弃** $j$ ——为独立公理化而战）：反设有降链
$[(a_{n+1},f_{n+1})]\in_\varepsilon[(a_n,f_n)]$ ，令
$$X_n=\{s\in[\kappa]^{|a_n\cup a_{n+1}|} : (f_n\circ\pi)(s)\in(f_{n+1}\circ\pi)(s)\}\in E_{a_n\cup a_{n+1}},$$

由 (d) 取保序 $g:\bigcup a_n\to\kappa$ 使 $g``(a_n\cup a_{n+1})\in X_n$ 一切 $n$ 。矛盾：$g$ 把无穷降链压成自然
数上的严格降列
$$\cdots (f_{n+1}\circ\pi)(g``a_{n+1})\in (f_n\circ\pi)(g``a_n)\in\cdots$$

（每项是 $V$ 中真实的集合，因为 $g``a_n\in[\kappa]^{|a_n|} =\mathrm{dom}(f_n)$ ）。**ω-完全性 ⟹ 有秩性**的因果链在此
完全显形：公理 (d) 的树论证保证「有限段可协调」，协调的极限
存在性就是良基性。

> **定义 1.19（张子）** 设 $\kappa\le\lambda$ 为不可数基数。
> 函数 $\varepsilon=\{E_a\mid a\in[\lambda]^{<\omega}\}$ 是一个
> $(\kappa,\lambda)$ -**张子**当且仅当它具备上述 (1)–(4) 四条
> 性质（κ-完全超滤子系、协调性、正规性、ω-完全性）。
>
> **定义 1.20（张子超幂）** 如上构造
> $\mathrm{ult}(V,\varepsilon)=(\mathcal D/\equiv,\in_\varepsilon)$ ；
> 若有秩，传递化为 $M_\varepsilon$ ，典型嵌入 $j_\varepsilon: V\to M_\varepsilon$ （$j_\varepsilon(x)=[(\{0\},c_x)]$ ）。
> **张子的强度** $\mathrm{QiangDu}(\varepsilon)$ = 满足
> $V_\eta\subseteq M_\varepsilon$ 的最大序数 $\eta$ 。

引理 1.55 验证 $\equiv$ 是等价关系且 $\in_\varepsilon$ 与
代表元选取无关（传递性证明是三坐标 $a\cup b\cup c$ 上的一次
交集账——$\kappa$ -完全性的典型消费；(3) 的证明在书 p123–124
完整展开：取 $X_2,Y_2,Z_2,W_2$ 四个换代表集，用 (b) 的投影
把它们压到公共坐标 $e=a_1\cup a_2\cup b_1\cup b_2$ 上，交
一次，再投回去——「换代表」的代数与第 97 章引理 1.42 的超滤子
乘积表示是同一台投影机器）。

定向极限的**定向性**值得点破：$([\lambda]^{<\omega}, \subseteq)$ 是有向集（任何两坐标有公共上界 $a\cup b$ ），
所以系统 $\langle N_a,i_{a,b}\rangle$ 不需要链条件就有极限。
这与第 97 章线性迭代（按序数索引、链式）形成对照：**张子
超幂是「同时超幂」**——把迭代该做的无穷步压缩成一张有限
坐标网上的极限，一步到位。代价是公理 (b)(c) 的技术税；收益
是有界高度（$\lambda$ 以下）的嵌入可以**有限刻画**。Martin
的原始动机（书 p114 点破的「表达力挑战」）正是要这个有限
刻画——把「强」从类论拉回集论。

## 101.5 正规性的用途：λ 的典型表示与特征定理

> **引理 1.56** 设 $\varepsilon=\{E_a\}$ 为正规 ω-完全
> $(\kappa,\lambda)$ -张子，$f:[\kappa]^1\to\kappa$ 为
> $f(\{\alpha\})=\alpha$ 。那么 $(\lambda,\in)$ 是
> $\{[(\{\alpha\},f)]\mid \alpha\in\lambda\}$ 的传递化；且
> 每 $\alpha<\lambda$ 有 $[(\{\alpha\},f)]\in_\varepsilon [(\{0\},c_\kappa)]$ 。

证明用公理 (c) 的正规性（书 p125 留作练习并注明「这是应用
张子的正规性条件的地方」，引理 1.59 给一般支撑版本）。意义：
**恒等函数 $f$ 在每个单点坐标上的类就是 $\alpha$ 本身的
代表**——支撑集合 $\lambda$ 被「装进」超幂，这是
$V_\lambda\subseteq M_\varepsilon$ 的第一块砖。

> **定理 1.31** 设 $\varepsilon=\{E_a\}$ 为 $(\kappa, \lambda)$ -张子。那么
>
> (1) $\mathrm{ult}(V,\varepsilon)$ 是自同一的有秩结构；
>
> (2) $j_\varepsilon:V\to M_\varepsilon$ ，并且
>
> (a) $\kappa=\mathrm{Crit}(j_\varepsilon)$ ，$j_\varepsilon( \kappa)\ge\lambda$ ；
>
> (b) $a\in[\lambda]^{<\omega},\,X\subseteq[\kappa]^{|a|}:\; X\in E_a\Rightarrow a\in j_\varepsilon(X)$ ；
>
> (c) $M_\varepsilon=\{j_\varepsilon(f)(a)\mid a\in[ \lambda]^{<\omega},f:[\kappa]^{|a|}\to V\}$ ；
>
> (d) 如果 $|V_\alpha|<\lambda$ ，那么 $V_\alpha\subseteq M_\varepsilon$ 。

(2)(b) 是「张子忠实于嵌入」：超滤子的成员关系原样反映到
$j_\varepsilon$ 的像中。(2)(d) 把强度与支撑挂钩：支撑
$\lambda$ 越大，被捕获的 $V_\alpha$ 层越高——$|V_\alpha| <\lambda$ 的层全部进 $M_\varepsilon$ 。与引理 1.56 合起来，
张子的**强度下界由支撑直接读出**。

(2)(d) 的证明思路（书 p125 留作练习）是归纳 + 编码账：对
$|V_\alpha|<\lambda$ 归纳。每个 $x\in V_\alpha$ 有
$|\mathrm{TC}(x)|\le|V_\alpha|<\lambda$ ，取双射
$e:\mu\to\mathrm{TC}(\{x\})$ （$\mu<\lambda$ ）；由引理
1.56 每个 $\xi<\mu\subseteq\lambda$ 在 $M_\varepsilon$
中有典型代表，且代表由**一个**函数 $f$ （把 $\xi$ 映到
$\mathrm{TC}$ 编码）在坐标 $\{\xi\}$ 处给出——于是
$x=j_\varepsilon(f)(a)$ 型（$a$ 是编码 $x$ 所需的有限
坐标集），落入 (2)(c) 的值域表示。归纳地基是 $V_0=\emptyset \in M_\varepsilon$ （$j_\varepsilon(\emptyset)=\emptyset$ ）。
注意 (2)(c) 在这里的角色：**值域表示是收据**——「$M_\varepsilon =\{j_\varepsilon(f)(a)\}$ 」把「$x\in M_\varepsilon$ 」这
个抽象归属转化为「存在函数与坐标」的组合陈述，归纳才走得动。
这与第 94 章超幂的 $M=\{j(f)([\mathrm{id}])\}$ 同构——
所有超幂构造的值域表示都是「成员资格的组合化」。

> **定理 1.32** 一个基数 $\kappa$ 是一个强基数当且仅当对于
> 每一个 $\lambda\ge\kappa$ 都存在一个 $(\kappa,V_{\lambda+1})$
> -张子。

这就是挑战的答案：**强基数是 ZFC 纯语言可表达的**。注意支撑
是 $V_{\lambda+1}$ （一个传递集合，广义张子的支撑——定义
1.22 在后面补上一般框架）；由定理 1.34 型的论证，
$(\kappa,Y)$ -张子给出 $Y\subseteq M_\varepsilon$ ，故
$(\kappa,V_{\lambda+1})$ -张子给 $V_{\lambda+1}\subseteq M_\varepsilon$ ，即 $(\kappa,\lambda)$ -强嵌入；反向，强嵌入
的导出张子（支撑取 $V_{\lambda+1}$ ）满足四公理。命题 1.4 的
类量词被**集合大小的超滤子系统**替换——表达力无损，对象从
类降为集合。

两个方向的不对称值得记：⟸ 方向（张子 ⟹ 强嵌入）消费的
全部是四公理（良基性用 (d)、临界点用 (a) 的尾段账、塔包含
用引理 1.56/1.59）；⟹ 方向（强嵌入 ⟹ 张子）消费的只是
「导出过程」的机械验证（四条公理都是 $a\in j(X)$ 定义式
的直译）。**公理恰好穷尽了导出过程的全部性质**——这是定义
1.19 作为「独立公理化」成功的判据：既无冗余（每条公理在
某个反例构造中不可省——协调性去掉则坐标网崩坏、正规性
去掉则 $\lambda$ 无典型代表、ω-完全性去掉则超幂可不良基），
也无缺口（导出张子满足它们全部）。

与第 94 章 Scott 定理的接口：Scott 的 $V\ne L$ 论证用
「可测 ⟹ 超滤子存在 ⟹ $L$ 中亦可定义 ⟹ 矛盾」。定理
1.32 之后同款论证升级：**强基数 ⟹ 张子存在 ⟹ 对每个
$\lambda$ ，「$\lambda$ 高度的 $L$ 层」被嵌入搬动 ⟹
$L$ 的可构造序在 $\kappa$ 以上不是$V$ 的骨架**。第 98
章的 $L[U]$ 唯一性定理在这个背景下读作「内模型最多装下
**一个**可测的账本」，而强基数要求 $\kappa$ 以上**每层**
都有见证——$L[U]$ 装不下，这正是 Vopěnka 定理（第 99 章
定理 1.27：强紧杀死一切 $L[A]$ ）的内模型侧伏笔。

## 101.6 超强基数：λ = j(κ) 的禁区与广义张子

定义 1.18 把 $\lambda<j(\kappa)$ 钉死。书中 p126 澄清了
为什么这不是 Kunen 定理（第 94 章定理 1.11）的警示：Kunen
排除的是
$$j:V\to M,\quad\kappa=\mathrm{Crit}(j),\quad \lambda\ge\sup_n j^n(\kappa),\quad V_{\lambda+3}\subseteq M,$$

而 $\lambda=j(\kappa)$ 、$V_{j(\kappa)}\subseteq M$ 型嵌入
**不在被排除之列**——避开 $j(\kappa)$ 纯粹是**技术原因**：
普通张子的坐标取自 $[\lambda]^{<\omega}$ （序数有限列），而
表示 $j(\kappa)$ -高度的嵌入需要坐标取自 $V_{j(\kappa)}$
的有限**序列**——序数坐标不够用了。

> **定义 1.21** 称 $\kappa$ 是**超强基数**当且仅当存在
> $j:V\to M$ ，$\kappa=\mathrm{Crit}(j)$ 且
> $V_{j(\kappa)}\subseteq M$ 。

超强导出张子（书 p126–129）：令 $Y=V_{j(\kappa)}$ （传递、
含 $\kappa$ ）。坐标改为 $a\in Y^{<\omega}$ （$Y$ 中元素
的有限**序列**），配三个运算：延长序 $a\le b$ （$b$ 限制
到 $\mathrm{dom}(a)$ 恰为 $a$ ）、拼接 $a+b$ 、投影
$\pi_{b,a}$ （经 $\mathrm{dom}(b)$ 的置换）。对
$X\subseteq V_{\mathrm{dom}(a)}$ 定义
$$X\in E_a \iff a\in j(X).$$

命题 1.5 逐条验证 (a)–(d) 的序列版：超滤子性（$j$ 保布尔
运算 + $j(V_\kappa)$ 与 $j$ 值域不交的非平凡性论证）、
协调性（投影换序）、正规性（两个条款：单点等同与「$f\circ \pi$ 的常值化」，加高坐标 $a+(y)$ 中的 $y=j(f)(a)$ 又是
嵌入递回来的见证）、ω-完全性（树论证平移：$M$ 中
$j(T)$ 的降树枝由 $f\in Y^\omega$ 直接给出）。

> **定义 1.22（广义张子）** $\kappa$ 不可数正则、$Y$
> 传递、$\kappa\in Y$ 。$(\kappa,Y)$ -张子
> $\varepsilon=\{E_a\mid a\in Y^{<\omega}\}$ ：(a) 每个
> $E_a$ 是 $V_{\mathrm{dom}(a)}$ 上的 $\kappa$ -完全
> 超滤子；(b) 协调性（投影 $\pi_{b,a}$ 版）。**正规**
> $(\kappa,Y)$ -张子：再加 (c)(i)(ii)；**ω-完全**：再加 (d)。
>
> **定义 1.23（广义张子超幂）** $(a,f)$ （$f: V_{\mathrm{dom}(a)}\to V$ ）、$\equiv$ 经 $E_{a+b}$ 、
> $j_\varepsilon(x)=[(\{0\},c_x)]$ ——与定义 1.20 同构，只是
> 「并」换成「拼接」。

引理 1.57/1.58 平移引理 1.55/1.58（等价关系、有秩性）；
**引理 1.59** 是引理 1.56 的支撑一般化（书 p131–132 完整
证明）：正规性 (c)(i) 处理单点层（$y\in z$ 的双向），(c)(ii)
把 $[ (a,g)]\in_\varepsilon[(\langle y\rangle,f)]$ 常值化为
某个 $z\in y$ 的代表——结论
$$(Y,\in)\cong\{[(\langle z\rangle,f)]\mid z\in Y\},\qquad Y\subseteq M_\varepsilon.$$

**支撑集合整块进入超幂**——这就是「正规性是为了保证张子的
支撑集合的每一个元素在超幂中都有非常典型的表示」（书 p124
原话）的精确含义。定理 1.33 给 Łoś 定理（证明同第 94 章定理
1.8 的模式）；定理 1.34 汇总：$\kappa=\mathrm{Crit}(j_\varepsilon)$ 、
$Y\subseteq V^{M_\varepsilon}_{j_\varepsilon(\kappa)}$ 、
$M_\varepsilon=\{j_\varepsilon(f)(a)\}$ 。

广义张子的坐标运算（$a\le b$ 、$a+b$ 、$\pi_{b,a}$ 经
$\mathrm{dom}(b)$ 的**置换**）与普通张子的（$a\subseteq b$ 、
$a\cup b$ 、投影经**位置选取**）是同构的两套语法：序列版
把「位置」外化为定义域（$\mathrm{dom}(a)=n$ 型的自然数），
集合版把位置藏在单调排列里。序列版的额外能力是坐标可以取
**任意集合**（$Y$ 的元素）而非序数——这正是接住
$V_{j(\kappa)}$ 支撑所必需的：$V_{j(\kappa)}$ 的元素是
$\kappa$ 以上的任意秩层对象，序数坐标网装不下它们。一句话：
**普通张子量序数坐标，广义张子量集合坐标**；强基数住在前者
的世界，超强基数住在后者的世界。

还要与第 83 章（超实数）的**序列超幂**对照一次：那里的坐标
是 $\omega$ （自然数位置）、滤子是余有限、函数是数列
$\mathbb N\to\mathbb N$ ；这里坐标是 $Y^{<\omega}$ 、滤子
族是张子、函数是 $V_{\mathrm{dom}(a)}\to V$ 。同构的骨架
（函数/等价/成员关系三件套 + Łoś）完全一致，差别的只是
「论域大小 × 滤子强度」的两个旋钮。整个大基数机器到本章
为止的全部构造——超滤子超幂、迭代超幂、张子超幂——都是
**同一个 ultraprototype 的三次工业化改造**。

## 101.7 定理 1.35：超紧之下超强荟萃

> **定理 1.35** 设 $\kappa$ 是 $2^\kappa$ -超紧基数。则
> $\{\alpha<\kappa\mid \alpha\text{ 是超强基数}\}$ 是
> $\kappa$ 的一个荟萃子集。

**证明**（书 p133–134，M 内自举——本章最漂亮的三行账）。
取 $(\kappa,2^\kappa)$ -超紧嵌入 $j:V\to M$ （${}^{2^\kappa} M\subseteq M$ ），令 $Y=V_{j(\kappa)}$ 。导出 $(\kappa,Y)$ -
张子 $\varepsilon=\{E_a\}$ ：$X\in E_a\iff a\in j(X)$ 。

第一行（**张子是集合**）：$\varepsilon$ 的每个坐标 $E_a$
由「$X\mapsto a\in j(X)$ 」决定；书 p134 的精确账把 $\mathcal I$ 型的分层有穷坐标域组装起来，全族是集合大小的对象，且其
编码序列的长度被 $2^\kappa$ 封顶——故 $\varepsilon\in M$ ——
序列封闭性把导出过程**装进** $M$ 。

第二行（**M 内部自举**）：在 $M$ 中用 $\varepsilon$ 造
$M$ 的超幂（$\equiv$ 、$\in_\varepsilon$ 、传递化对 $M$
绝对，定义全程可在 $M$ 内复演），得超强嵌入
$j_\varepsilon^M:M\to N$ （临界点 $\kappa$ 、
$V_{j(\kappa)}^M\subseteq N$ ）。于是 $M\models$ 「$\kappa$
是超强基数」。

第三行（**拉回测一**）：令 $T=\{\alpha<\kappa\mid\alpha$
超强\}（可定义类）。$M\models\kappa\in j(T)$ （初等性 +
$\kappa$ 在 $M$ 中超强），故 $T\in D$ （$D=\{X\subseteq \kappa:\kappa\in j(X)\}$ ，正规测度），正规测度成员荟萃。∎

与第 100 章命题 1.2（$2^\kappa$ -超紧 ⟹ 第 $\kappa$ 个
可测）对照：那里说「可测基数多到 $\kappa$ 层」（下方基数
的**数量**账），这里说「超强基数**荟萃**」（与一切俱乐部相
交的**分布**账）——后者严格强于前者：$\kappa$ 个点的集合
可以躲开某支俱乐部，荟萃集必然打穿每一支。结构上，两个证明
的发动机是同一个：**序列封闭 ⟹ 见证对象落入 $M$ ⟹ $M$
内部自举 ⟹ 拉回测一**。这个四步模板在大基数论的反射型定理
中反复出现；第 102 章武丁基数（定理 1.36 的 (c)(d) 款：「对
任意 $f:\delta\to\delta$ 存在 $\kappa<\delta$ 与嵌入使
$V_{j(f)(\kappa)}\subseteq M$ 」）把它用在**函数层**——同一
发动机的第三次工业化。

方向性注记：定理 1.35 的结论「$T\in D$ 」比「荟萃」更强——
是**特定的**正规测度包含 $T$ 。这给出超紧之下超强基数的
**测度论指纹**（不只是分布论指纹）；内模型理论沿这种指纹
反推公理的形状（$L[E]$ 序列的骨架），第 110 章 NS 饱和
还会回收这个视角。

## 101.8 三本账：单 λ 见证 / 全 λ 见证 / 目标闭包

Task 要求的对照表——三种「强度陈述」的真值条件与结构后果
完全不同，混淆它们是初学大基数最常见的错误：

| 账本 | 陈述形态 | 强度量纲 | 反例/边界 |
|---|---|---|---|
| **单个 λ 的见证** | 存在 $j$ ：$\kappa=\mathrm{Crit}$ 、$j(\kappa)>\lambda$ 、$V_\lambda\subseteq M$ | 一个序数 $\lambda$ | 可测 = $(\kappa,\kappa+1)$ -强；单 λ 见证**不是**大基数假设的严格增长（$\lambda$ 可以为 $\kappa+1$ ） |
| **对所有 λ 有见证** | $\forall\lambda\ge\kappa\,\exists j_\lambda$ | 类量词（ZFC 外）或张子族（ZFC 内，定理 1.32） | 这才是「强基数」；有限影子**恒假**（鸽笼：captured 有限而 $\lambda$ 无界） |
| **目标模型闭包** | ${}^\lambda M\subseteq M$ / $V_{j(\kappa)}\subseteq M$ 等 | 嵌入本身的内部结构 | 超紧用序列封闭；超强用 $V_{j(\kappa)}$ ；两者与「全 λ 强」不可比（超强 ⟸ $2^\kappa$ -超紧荟萃地下方，但单个超强 $\not\Rightarrow$ 强） |

三行强度阶梯（严格递增）：

$$\text{可测} \;\xrightarrow{\;V_{\kappa+1}\;}\; (\kappa,\kappa{+}1)\text{-强} \;\xrightarrow{\;\forall\lambda\;}\; \text{强} \;\xrightarrow[\text{定理 1.35}]{\text{下方荟萃}}\; 2^\kappa\text{-超紧（且强）},$$

而**超强**在另一根轴上（$\lambda=j(\kappa)$ 一次性封顶）：
单个超强基数的下方未必有可测基数之外的任何东西；但定理 1.35
说超紧之下它**成片出现**。Julia/Python 通道的有限强度矩阵把
这张表搬进有限层：每行（见证）只在有限列（$\lambda$ ）点亮，
「对所有 λ」那一行**永不出场**——这不是矩阵的缺陷，而是强
基数定义中类量词的忠实投影（三证明通道的鸽笼定理：Lean
`Wit.not_strong_finite`、Coq `not_strong_finite`、Agda
`not-strong-finite`）。

三本账在**独立性谱系**上的位置也各不相同：单 λ 见证对每个
固定的 $\lambda$ 是一个集合大小的陈述（张子存在性），
一致性强度随 $\lambda$ 连续爬升但在 $\lambda=\kappa^{+n}$
的低段只与可测相当；「全 λ 强」的一致性强度跳到可测之上
一个完整层级（Martin 定理语境）；目标闭包条款（序列封闭 /
$V_{j(\kappa)}$ ）与「全 λ 强」**不可比**——超强的存在
不蕴含强（超强嵌入的 $j(\kappa)$ 可以是第一个被捕获的
塔顶），强也不蕴含超强（强嵌入的塔包含可以在每个 $j(\kappa) \lambda$ 处恰好止步于 $\lambda$ ）。只有超紧把两根轴
同时拉满。**读表纪律**：任何「X 基数 ⟹ Y 基数」的断言都
要先问 X 与 Y 各在哪根轴上——量纲不同则蕴含方向往往出人
意料，第 102 章武丁基数（第三轴的**局部化**版本）会再把
这张表撑开一格。

## 101.9 机器通道一：Lean——有限秩层与鸽笼

```lean
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Card
import Mathlib.Data.Finset.Image
import Mathlib.Order.Interval.Finset.Nat

/-!
# 第 101 章 · 强基数与超强基数

锚点（有限影子）：
- 位编码有限累积层次 `level`：|V₁|=1、|V₂|=2、|V₃|=4、|V₄|=16
  （beth 递归在有限层的精确复现）与层包含链；
- 单射保交 `Finset.image_inter`——导出张子记账
  「X∈E_a ⟺ a∈j(X)」中超滤子对交封闭的内核；
- `Wit` 见证结构与 `not_strong_finite`：有限捕获集上
  「对所有 λ 都有见证」恒假——不把有限矩阵当强度证明。
张子本体（定义 1.19-1.23、定理 1.31-1.35）留在正文。
-/

namespace Settheory.Ch101

open Finset

section FiniteV

/-- 位编码成员表：x 的元素 = 使 x 的第 i 位为 1 的 i。
宇宙取 Fin 16（编码 0..15），足以承载前四层。 -/
def elems (x : Fin 16) : Finset (Fin 16) :=
  Finset.univ.filter (fun i => x.val.testBit i.val)

/-- 有限累积层次：level 0 = ∅，level (n+1) = {x : elems x ⊆ level n}。
这就是 V_{n+1} = P(V_n) 的位编码影子。 -/
def level : ℕ → Finset (Fin 16)
  | 0 => ∅
  | n + 1 => Finset.univ.filter (fun x => elems x ⊆ level n)

/-- 第一层恰为 {∅}（编码 0）。 -/
theorem level_one : level 1 = {0} := by decide

/-- 第二层 = {∅, {∅}}（编码 0, 1）。 -/
theorem level_two : level 2 = {0, 1} := by decide

/-- 第三层有四个元素——V₃ = P(V₂)。 -/
theorem level_three : level 3 = {0, 1, 2, 3} := by decide

/-- 第四层填满整个 16 编码宇宙——|V₄| = 2^4 = 16。 -/
theorem level_four : level 4 = Finset.univ := by decide

/-- beth 尺寸链的有限复现：1, 2, 4, 16。 -/
theorem level_card_chain :
    (level 1).card = 1 ∧ (level 2).card = 2 ∧
    (level 3).card = 4 ∧ (level 4).card = 16 := by decide

/-- 层包含链 V_n ⊆ V_{n+1} 的前四环。 -/
theorem level_mono_chain :
    level 0 ⊆ level 1 ∧ level 1 ⊆ level 2 ∧
    level 2 ⊆ level 3 ∧ level 3 ⊆ level 4 := by decide

end FiniteV

section DerivedBookkeeping

/-- 导出记账内核：单射保持交。
张子公理 (a) 中「E_a 是超滤子」的对交封闭部分
正是 j 单射 + j``(X∩Y) = j``X ∩ j``Y。 -/
example (j : ℕ → ℕ) (hj : Function.Injective j) (X Y : Finset ℕ) :
    Finset.image j (X ∩ Y) = Finset.image j X ∩ Finset.image j Y :=
  Finset.image_inter X Y hj

/-- 单条目记账：a ∈ j``(X∩Y) ⟺ a∈j``X ∧ a∈j``Y——
导出族 {X : a ∈ j``X} 对交封闭的直接形式。 -/
example (j : ℕ → ℕ) (hj : Function.Injective j) (a : ℕ) (X Y : Finset ℕ)
    (hX : a ∈ Finset.image j X) (hY : a ∈ Finset.image j Y) :
    a ∈ Finset.image j (X ∩ Y) := by
  rw [Finset.image_inter X Y hj]
  exact mem_inter.2 ⟨hX, hY⟩

end DerivedBookkeeping

section Witness

/-- 有限见证：临界点、j(κ)、目标模型捕获的秩层号集合。 -/
structure Wit where
  crit : ℕ
  jk : ℕ
  captured : Finset ℕ

/-- λ-强见证条款：j(κ) > λ 且第 λ 层被捕获。 -/
def Wit.lamStrong (w : Wit) (l : ℕ) : Prop :=
  w.crit ≤ l ∧ l < w.jk ∧ l ∈ w.captured

/-- 超强见证条款：第 j(κ) 层被捕获（V_{j(κ)} ⊆ M 的影子）。 -/
def Wit.superstrong (w : Wit) : Prop :=
  w.jk ∈ w.captured

/-- 强见证条款：对所有 λ ≥ κ 都 λ-强。 -/
def Wit.isStrong (w : Wit) : Prop :=
  ∀ l ≥ w.crit, w.lamStrong l

/-- 有限捕获集不可能承载「对所有 λ 的见证」——
鸽笼：captured 有限而 {l : l ≥ crit} 无穷。 -/
theorem Wit.not_strong_finite (w : Wit) : ¬ w.isStrong := by
  intro hstr
  have hsub : Finset.Ico w.crit (w.crit + w.captured.card + 1) ⊆ w.captured := by
    intro l hl
    simp only [Finset.mem_Ico] at hl
    exact (hstr l (by omega)).2.2
  have hcard : (Finset.Ico w.crit (w.crit + w.captured.card + 1)).card ≤
      w.captured.card := Finset.card_le_card hsub
  rw [Nat.card_Ico w.crit (w.crit + w.captured.card + 1)] at hcard
  omega

/-- 单 λ 见证可成：临界 2、j(κ)=5、捕获 {3} 是 λ=3 的强见证。 -/
example : Wit.lamStrong { crit := 2, jk := 5, captured := {3} } 3 := by
  simp [Wit.lamStrong]

/-- 同一见证不是 λ=4 的强见证（j(κ) ≤ 4 一款失败）。 -/
example : ¬ Wit.lamStrong { crit := 2, jk := 5, captured := {3} } 4 := by
  simp [Wit.lamStrong]

/-- 该见证也非超强（j(κ)=5 未被捕获）。 -/
example : ¬ Wit.superstrong { crit := 2, jk := 5, captured := {3} } := by
  simp [Wit.superstrong]

/-- 超强见证样本：临界 2、j(κ)=4、捕获 {4}。 -/
example : Wit.superstrong { crit := 2, jk := 4, captured := {4} } := by
  simp [Wit.superstrong]

end Witness

end Settheory.Ch101
```

位编码是本章的机器地基：编码 $x\in\{0..15\}$ 的元素表
`elems x` = 置位位号集合，于是 `level (n+1) = {x | elems x ⊆
level n}` 就是 $V_{n+1}=\mathcal P(V_n)$ 的可判定影子，
`decide` 直接核对前四层与 beth 尺寸链 1,2,4,16。实测坑四
笔：`Finset.image_inter` 的假设在**集合之后**（`image_inter
X Y hj` 非 `hj X Y`）；`Finset.map` 收 `↪` 嵌入而非普通函数
（改用 `Finset.Ico` + `Nat.card_Ico`，后者藏在
`Order.Interval.Finset.Nat` 且命名空间是 **Nat** 非 Finset）；
`Finset.card`/`card_le_card` 不在 `Finset.Basic` 里（须
`Data.Finset.Card`）；`Fin 16` 上没有 `testBit` 域记号（须
`x.val.testBit i.val`）。

设计说明两笔。**为什么用位编码而不是嵌套集合类型**：Lean 里
「集合的集合的集合」在 `Set (Set (Set ∅))` 型上无 nivel 可
递归——位编码把整个有限累积层次压进 `Fin 16`，`elems` 是
解码器、`level` 是层级构造器，一切 `decide` 可判（16 元宇宙
上滤子与包含都是有限搜索）。beth 尺寸链 $1,2,4,16$ 是这条
编码的**自检**：$V_{n+1}=\mathcal P(V_n)$ 在位码世界里就是
「元素表的元素表」，尺寸 $2^{|V_n|}$ 逐层翻倍翻四——若
`elems`/`level` 任一实现有 off-by-one，链条立刻在
`level_card_chain` 上断裂。**鸽笼定理为什么用 `Finset.Ico` 而
不是 `Finset.map`**：`Ico w.crit (w.crit + card + 1)` 的势
恰为 `card + 1`（`Nat.card_Ico` 一笔），比「映射后数数」少
一次单射性论证——`w.isStrong` 把整个区间塞进 `captured`，
势不等式直接矛盾。

## 101.10 机器通道二：Coq——反射引理与单调链

```coq
(* 第 101 章：有限秩层 V_n、层包含链、导出超滤子记账与见证条款。 *)
From Coq Require Import List Arith Bool Lia.
Import ListNotations.

Module Ch101.

(* ── 一、位编码有限累积层次 ──
   编码 x ∈ {0..15}，元素表 = 使第 i 位为 1 的 i 全体。
   level 0 = []，level (n+1) = {x | elems x ⊆ level n}。 *)

Definition universe := seq 0 16.

Definition elems (x : nat) : list nat :=
  filter (fun i => Nat.testbit x i) (seq 0 16).

Definition memb (x : nat) (l : list nat) : bool :=
  existsb (fun y => Nat.eqb y x) l.

Definition sublb (l1 l2 : list nat) : bool :=
  forallb (fun x => memb x l2) l1.

Fixpoint level (n : nat) : list nat :=
  match n with
  | 0 => []
  | S m => filter (fun x => sublb (elems x) (level m)) universe
  end.

(* 前四层的精确内容：∅；{∅}；{∅,{∅}}；四元；十六元满宇宙。
   注意 vm_compute：reflexivity 的内核转换对 level 4 的无共享
   重复展开会爆炸（level 3 在每个成员检查里重算），VM 求值瞬间。 *)
Example level_1 : level 1 = [0].
Proof. vm_compute. reflexivity. Qed.

Example level_2 : level 2 = [0; 1].
Proof. vm_compute. reflexivity. Qed.

Example level_3 : level 3 = [0; 1; 2; 3].
Proof. vm_compute. reflexivity. Qed.

Example level_4 : level 4 = universe.
Proof. vm_compute. reflexivity. Qed.

(* beth 尺寸链：1, 2, 4, 16。 *)
Example level_card_chain :
  length (level 1) = 1 /\ length (level 2) = 2 /\
  length (level 3) = 4 /\ length (level 4) = 16.
Proof. repeat split; vm_compute; reflexivity. Qed.

(* ── 二、反射引理与层包含链 V_n ⊆ V_{n+1} ── *)

Lemma memb_true_in : forall x l, memb x l = true -> In x l.
Proof.
  intros x l. induction l as [|a t IH]; simpl.
  - discriminate.
  - destruct (Nat.eqb_spec a x) as [E|NE].
    + intros _. left. exact E.
    + simpl. intros H. right. apply IH. exact H.
Qed.

Lemma in_memb_true : forall x l, In x l -> memb x l = true.
Proof.
  intros x l. induction l as [|a t IH]; simpl.
  - intros [].
  - intros [E|H].
    + subst. rewrite Nat.eqb_refl. reflexivity.
    + apply orb_true_intro. right. apply IH. exact H.
Qed.

(* 点级包含：布尔版为真 ⟹ 点级包含。 *)
Lemma sublb_subl : forall l1 l2, sublb l1 l2 = true ->
  forall x, In x l1 -> In x l2.
Proof.
  intros l1 l2 H x Hx. unfold sublb in H.
  rewrite forallb_forall in H. specialize (H x Hx).
  apply memb_true_in. exact H.
Qed.

(* 单层展开方程：避免 cbn [level] 多层展开触发 unify 指数爆炸。 *)
Lemma level_S : forall n,
  level (S n) = filter (fun x => sublb (elems x) (level n)) universe.
Proof. intros n. reflexivity. Qed.

(* 关键单调引理：x ∈ level n ⟹ x ∈ level (n+1)。 *)
Lemma level_mono_step : forall n x, In x (level n) -> In x (level (S n)).
Proof.
  induction n as [|n IH]; intros x H.
  - cbn [level] in H. destruct H.
  - rewrite level_S in H. apply filter_In in H. destruct H as [Hin Hsub].
    rewrite level_S. apply filter_In. split.
    + exact Hin.
    + unfold sublb. rewrite forallb_forall. intros i Hi.
      apply in_memb_true. apply IH.
      apply (sublb_subl (elems x) (level n) Hsub i Hi).
Qed.

(* 前四环包含链。 *)
Example level_chain :
  (forall x, In x (level 0) -> In x (level 1)) /\
  (forall x, In x (level 1) -> In x (level 2)) /\
  (forall x, In x (level 2) -> In x (level 3)) /\
  (forall x, In x (level 3) -> In x (level 4)).
Proof.
  repeat split; intros x Hx; eapply level_mono_step; eassumption.
Qed.

(* ── 三、导出超滤子记账：单射保交 ──
   张子公理 (a)：E_a = {X | a ∈ j``X} 对交封闭。
   「X∩Y」以 filter (memb · Y) X 表示。 *)

Lemma in_map_inter : forall (f : nat -> nat) (Hinj : forall u v, f u = f v -> u = v)
                         (X Y : list nat) (a : nat),
  In a (map f X) -> In a (map f Y) ->
  In a (map f (filter (fun z => memb z Y) X)).
Proof.
  intros f Hinj X Y a HX HY.
  apply in_map_iff in HX. destruct HX as [x [Hfx Hxin]].
  apply in_map_iff in HY. destruct HY as [y [Hfy Hyin]].
  assert (Hxy : x = y) by (apply Hinj; congruence).
  subst y. apply in_map_iff. exists x. split.
  - exact Hfx.
  - apply filter_In. split.
    + exact Hxin.
    + apply in_memb_true. exact Hyin.
Qed.

Example derived_inter_sample :
  forall (X Y : list nat),
  In 5 (map (fun z => z) X) -> In 5 (map (fun z => z) Y) ->
  In 5 (map (fun z => z) (filter (fun z => memb z Y) X)).
Proof. intros X Y HX HY. apply in_map_inter; auto. Qed.

(* ── 四、见证条款记账 ── *)

Record Wit := mkWit {crit : nat; jk : nat; captured : list nat}.

Definition lam_strong (w : Wit) (l : nat) : Prop :=
  crit w <= l /\ l < jk w /\ In l (captured w).

Definition superstrong (w : Wit) : Prop := In (jk w) (captured w).

Definition is_strong (w : Wit) : Prop :=
  forall l, crit w <= l -> lam_strong w l.

Definition maxl (l : list nat) : nat := fold_right Nat.max 0 l.

Lemma maxl_ge : forall l y, In y l -> y <= maxl l.
Proof.
  induction l as [|a t IH]; simpl; intros y Hy.
  - destruct Hy.
  - destruct Hy as [->|Hy].
    + apply Nat.le_max_l.
    + apply Nat.max_le_iff. right. apply IH. exact Hy.
Qed.

(* 有限捕获表不可能承载「对所有 λ 的见证」：
   取 L = crit + (maxl + 1) 超出表内一切元素。 *)
Theorem not_strong_finite : forall w : Wit, ~ is_strong w.
Proof.
  intros w H.
  assert (Hle : crit w <= crit w + S (maxl (captured w))) by lia.
  destruct (H (crit w + S (maxl (captured w))) Hle) as [_ [_ Hmem]].
  apply maxl_ge in Hmem. lia.
Qed.

(* 单 λ 见证样本与两个否定。 *)
Example wit_lam3 : lam_strong (mkWit 2 5 [3]) 3.
Proof. simpl. repeat split; simpl; lia. Qed.

Example wit_not_lam4 : ~ lam_strong (mkWit 2 5 [3]) 4.
Proof.
  intro H. destruct H as [_ [_ [E|F]]].
  - lia.
  - destruct F.
Qed.

Example wit_not_superstrong : ~ superstrong (mkWit 2 5 [3]).
Proof.
  intro H. simpl in H. destruct H as [E|F].
  - discriminate E.
  - destruct F.
Qed.

Example wit_superstrong : superstrong (mkWit 2 4 [4]).
Proof. simpl. left. reflexivity. Qed.

End Ch101.
```

Coq 版把「布尔反射 + 单调链」做成完整证明：`memb_true_in`/
`in_memb_true` 双向反射、`level_mono_step` 归纳（关键的
`sublb_subl` 把布尔包含还原成点级包含）、`not_strong_finite`
的 maxl 鸽笼。实测坑四笔：**`reflexivity` 在 `level_4` 上内核
爆炸**（无共享重复展开 level 3——`vm_compute` 用 VM 求值瞬间，
这是本章最重的实测账）；**`cbn [level]` 多层展开使 `apply IH`
的 unify 指数回溯**（改单层方程引理 `level_S` + `rewrite`）；
filter 的谓词须 Bool（`In z Y` 是 Prop——用 `memb` 布尔化）；
合取上的 `reflexivity` 非法（`repeat split; reflexivity`）。

两笔设计账值得展开。**vm_compute vs reflexivity 的性能差**
是本章最重要的工程教训：`level 4` 的求值树里，每个成员检查
`sublb (elems x) (level 3)` 都会**重新展开** `level 3`（Coq
的转换检查不共享子项），于是 `level 4` 的开销是
$|V_4|\times|V_3|$ 次 `level 3` 重算的复合——指数级。VM
（`vm_compute`）是按值调用带共享的字节码机，`level 3` 算一次
缓存，整棵树线性走完。这与数学上的「分层定义天然记忆化」
对应：**定义的书写方式决定了求值图的共享结构**。**单层方程
`level_S` 的作用**：`rewrite level_S` 每次只剥一层 Fixpoint
外衣，证明中 `apply IH` 面对的 `level (S n)` 保持折叠形态，
unify 一步命中；而 `cbn [level]` 会连剥两层并把 `filter`
应用到具体列表上，unifier 在 16 元列表的谓词回溯里爆炸。
「重写引理保持折叠」是 Coq 处理 Fixpoint 的通用纪律（第 70
章 HF 编码、第 78 章 SCH 机器件都是同款）。

## 101.11 机器通道三：Agda——构造性层次与证书链

```agda
-- 第 101 章：有限秩层的构造性递归、beth 尺寸链、
-- 层包含证书与见证条款记账（有限捕获不承载全域见证）。
module Ch101_strong where

open import Data.List using (List; []; _∷_; length)
open import Data.Nat using (ℕ; zero; suc; _+_; _≤_; _<_; z≤n; s≤s)
open import Data.Nat.Properties using (≤-refl; ≤-trans; m≤m+n; +-comm)
open import Data.Bool using (Bool; true; false; _∧_; _∨_; if_then_else_)
open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)
open import Relation.Nullary using (¬_)

-- ── 零、自建件：相等、成员、包含（沿 99 章 anyb/allb 范式）──

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

data _∈L_ : ℕ → List ℕ → Set where
  here  : ∀ {x xs} → x ∈L (x ∷ xs)
  there : ∀ {y x xs} → x ∈L xs → x ∈L (y ∷ xs)

inL : ℕ → List ℕ → Bool
inL x [] = false
inL x (y ∷ ys) = nat-eq y x ∨ inL x ys

-- 反演件（模式变量是构造子，类型可约简——99 章已验证的范式）。
∨-inv : ∀ a b → (a ∨ b) ≡ true → (a ≡ true) ⊎ (b ≡ true)
∨-inv true b H = inj₁ refl
∨-inv false b H = inj₂ H

∨-trueʳ : ∀ a → (a ∨ true) ≡ true
∨-trueʳ false = refl
∨-trueʳ true = refl

inL-sound : ∀ x ys → inL x ys ≡ true → x ∈L ys
inL-sound x [] ()
inL-sound x (y ∷ ys) p with ∨-inv (nat-eq y x) (inL x ys) p
... | inj₁ q rewrite nat-eq-≡ y x q = here
... | inj₂ q = there (inL-sound x ys q)

inL-complete : ∀ x ys → x ∈L ys → inL x ys ≡ true
inL-complete x [] ()
inL-complete .y (y ∷ ys) here rewrite nat-eq-refl y = refl
inL-complete x (y ∷ ys) (there m)
  rewrite inL-complete x ys m = ∨-trueʳ (nat-eq y x)

-- 布尔包含：subL xs ys = true ⟺ xs 的元素都在 ys 中。
subL : List ℕ → List ℕ → Bool
subL [] ys = true
subL (x ∷ xs) ys = inL x ys ∧ subL xs ys

∧-true-left : ∀ a b → (a ∧ b) ≡ true → a ≡ true
∧-true-left false b H = H
∧-true-left true b H = refl

∧-true-right : ∀ a b → (a ∧ b) ≡ true → b ≡ true
∧-true-right false b ()
∧-true-right true b H = H

subL-sound : ∀ xs ys → subL xs ys ≡ true →
  ∀ x → x ∈L xs → x ∈L ys
subL-sound [] ys p x ()
subL-sound (z ∷ zs) ys p x here =
  inL-sound x ys (∧-true-left (inL z ys) (subL zs ys) p)
subL-sound (z ∷ zs) ys p x (there m) =
  subL-sound zs ys (∧-true-right (inL z ys) (subL zs ys) p) x m

subL-complete : ∀ xs ys → (∀ x → x ∈L xs → x ∈L ys) → subL xs ys ≡ true
subL-complete [] ys p = refl
subL-complete (z ∷ zs) ys p
  rewrite inL-complete z ys (p z here)
        | subL-complete zs ys (λ x m → p x (there m)) = refl

-- 点级包含（证书式，沿 100 章 ⊆L 模式）。
data _⊆L_ : List ℕ → List ℕ → Set where
  nil⊆ : ∀ {ys} → [] ⊆L ys
  cons : ∀ {z zs ys} → z ∈L ys → zs ⊆L ys → (z ∷ zs) ⊆L ys

-- ── 一、位编码有限累积层次（宇宙 {0..15}；beth 尺寸 1,2,4,16）──

half : ℕ → ℕ
half zero = zero
half (suc zero) = zero
half (suc (suc n)) = suc (half n)

oddb : ℕ → Bool
oddb zero = false
oddb (suc n) = if oddb n then false else true

testbit : ℕ → ℕ → Bool
testbit x zero = oddb x
testbit x (suc i) = testbit (half x) i

-- 元素表：使第 i 位为 1 的 i 全体（四位宇宙只需前四个位号）。
elems : ℕ → List ℕ
elems x = filter-true (0 ∷ 1 ∷ 2 ∷ 3 ∷ [])
  where
  filter-true : List ℕ → List ℕ
  filter-true [] = []
  filter-true (i ∷ is) with testbit x i
  ... | true = i ∷ filter-true is
  ... | false = filter-true is

universe : List ℕ
universe = 0 ∷ 1 ∷ 2 ∷ 3 ∷ 4 ∷ 5 ∷ 6 ∷ 7 ∷
            8 ∷ 9 ∷ 10 ∷ 11 ∷ 12 ∷ 13 ∷ 14 ∷ 15 ∷ []

-- 秩层递归（§1.2.3 定义 1.18 的 V_λ ⊆ M 在有限层的地基）：
-- level 0 = []，level (suc n) = {x ∈ universe | elems x ⊆ level n}。
keep-if : List ℕ → List ℕ → List ℕ
keep-if cur [] = []
keep-if cur (u ∷ us) with subL (elems u) cur
... | true = u ∷ keep-if cur us
... | false = keep-if cur us

level : ℕ → List ℕ
level zero = []
level (suc n) = keep-if (level n) universe

level-1 : level 1 ≡ 0 ∷ []
level-1 = refl

level-2 : level 2 ≡ 0 ∷ 1 ∷ []
level-2 = refl

level-3 : level 3 ≡ 0 ∷ 1 ∷ 2 ∷ 3 ∷ []
level-3 = refl

level-4-full : level 4 ≡ universe
level-4-full = refl

size-chain : (length (level 1) ≡ 1) × (length (level 2) ≡ 2) ×
             (length (level 3) ≡ 4) × (length (level 4) ≡ 16)
size-chain = refl , refl , refl , refl

-- 层包含证书链：V₀⊆V₁⊆V₂⊆V₃⊆V₄（前四环）。(nil⊆/cons 逐点给出。)
chain-1 : (0 ∷ []) ⊆L (0 ∷ 1 ∷ [])
chain-1 = cons here nil⊆

chain-2 : (0 ∷ 1 ∷ []) ⊆L (0 ∷ 1 ∷ 2 ∷ 3 ∷ [])
chain-2 = cons here (cons (there here) nil⊆)

chain-3 : (0 ∷ 1 ∷ 2 ∷ 3 ∷ []) ⊆L universe
chain-3 = cons here
  (cons (there here)
    (cons (there (there here))
      (cons (there (there (there here))) nil⊆)))

-- ── 二、见证条款记账 ──

max2 : ℕ → ℕ → ℕ
max2 zero b = b
max2 (suc a) zero = suc a
max2 (suc a) (suc b) = suc (max2 a b)

max2-ˡ : ∀ a b → a ≤ max2 a b
max2-ˡ zero b = z≤n
max2-ˡ (suc a) zero = ≤-refl
max2-ˡ (suc a) (suc b) = s≤s (max2-ˡ a b)

max2-ʳ : ∀ a b → b ≤ max2 a b
max2-ʳ zero b = ≤-refl
max2-ʳ (suc a) zero = z≤n
max2-ʳ (suc a) (suc b) = s≤s (max2-ʳ a b)

maxl : List ℕ → ℕ
maxl [] = zero
maxl (x ∷ xs) = max2 x (maxl xs)

maxl-ge : ∀ y xs → y ∈L xs → y ≤ maxl xs
maxl-ge y [] ()
maxl-ge .y (y ∷ xs) here = max2-ˡ y (maxl xs)
maxl-ge y (z ∷ xs) (there m) =
  ≤-trans (maxl-ge y xs m) (max2-ʳ z (maxl xs))

n≰sucn : ∀ n → ¬ (suc n ≤ n)
n≰sucn zero ()
n≰sucn (suc n) (s≤s p) = n≰sucn n p

-- 右加保序（经交换律）：a ≤ b + a。
≤-swap : ∀ a b → a ≤ b + a
≤-swap a b rewrite +-comm b a = m≤m+n a b

-- 见证记录：临界点、j(κ)、捕获的秩层号表。
record Wit : Set where
  constructor wit
  field
    crit : ℕ
    jk   : ℕ
    cap  : List ℕ

LamStrong : Wit → ℕ → Set
LamStrong w l = (Wit.crit w ≤ l) × (l < Wit.jk w) × (l ∈L Wit.cap w)

Superstrong : Wit → Set
Superstrong w = Wit.jk w ∈L Wit.cap w

IsStrong : Wit → Set
IsStrong w = ∀ l → Wit.crit w ≤ l → LamStrong w l

-- 有限捕获表不可能承载「对所有 λ 的见证」——
-- 取 L = crit + (maxl + 1)，超出表内一切层号。
not-strong-finite : ∀ w → ¬ IsStrong w
not-strong-finite w h = goal
  where
  open Wit w
  l : ℕ
  l = crit + suc (maxl cap)
  dec : LamStrong w l
  dec = h l (m≤m+n crit (suc (maxl cap)))
  mem : l ∈L cap
  mem = proj₂ (proj₂ dec)
  goal : ⊥
  goal = n≰sucn (maxl cap)
    (≤-trans (≤-swap (suc (maxl cap)) crit) (maxl-ge l cap mem))

-- 单 λ 见证样本：临界 2、j(κ)=5、捕获 [3] 是 λ=3 的强见证。
w0 : Wit
w0 = wit 2 5 (3 ∷ [])

lam3 : LamStrong w0 3
lam3 = s≤s (s≤s z≤n) ,
       s≤s (s≤s (s≤s (s≤s z≤n))) ,
       here

not-lam4 : ¬ LamStrong w0 4
not-lam4 (_ , _ , there ())

not-superstrong-w0 : ¬ Superstrong w0
not-superstrong-w0 (there ())

-- 超强见证样本：临界 2、j(κ)=4、捕获 [4]。
w1 : Wit
w1 = wit 2 4 (4 ∷ [])

superstrong-w1 : Superstrong w1
superstrong-w1 = here
```

Agda 版的三件特色：`keep-if` 把 filter 的 `if` 分支做成**可
匹配的 with 构造子**（消费方无须反演 Bool——与 99 章
`sat-subset` 同源）；`_⊆L_` 证书链（`chain-1/2/3` 是
`cons here (cons (there here) ...)` 的逐点证明项）；
`not-strong-finite` 的 where 块程序化风格（`l`/`dec`/`mem`/
`goal` 四步，最后 `n≰sucn` 收口）。实测坑三笔：**`with` 抽象
不穿透假设的类型**（初版 `with nat-eq y x` 后假设 `p : inL x
(y∷ys) ≡ true` 不被 refine——改 `∨-inv` 把假设变成可分解的
`⊎` 数据）；本版 stdlib 无 `n≤m+n`（近名 `m≤m+n`/`n≤m⊔n`/
`n≤1+n`——自造 `≤-swap` 经 `+-comm` 换边）；`s≤s` 计数账
（`2 ≤ 3` 是**两**层 `s≤s`——`z≤n` 已覆盖 `0 ≤ 1`，首版数
错三层被类型检查当场抓获）。

Agda 版的位置感：本章七个通道里只有 Agda 把**布尔反射的
完整双向桥**（`inL-sound`/`inL-complete`、`subL-sound`/
`subL-complete` 四件套）全部构造出来——因为 Agda 的 `Set`
与 `Bool` 两个世界没有 Coq 的 `Prop` 那层统一语法糖，桥必须
显式修。代价是 ~80 行基建；收益是**每一步可约简性都经过
检查**（`∨-inv` 的两个分支里 `(a ∨ b) ≡ true` 真的归约到
`false ≡ true` 或 `b ≡ true`——Coq 的 `simpl` 不会告诉你它
为什么工作，Agda 的模式匹配会）。`keep-if` 与 stdlib
`filter` 的取舍同理：自造 with-版本让「谓词为真」成为可
模式匹配的构造子信息，消费侧（`level-1` 等 `refl` 证明）
不再需要反演 Bool 的引理——这是 99 章 `anyb/allb` 决策的
延续：**在依赖类型里，定义的形状就是证明的难度**。

## 101.12 机器通道四：Julia——有限强度矩阵

```julia
# 第 101 章：位编码有限秩层、beth 尺寸链与有限强度矩阵。
println("==== 101")

# ── 一、有限累积层次（宇宙 {0..15}，四层）──
const U = collect(0:15)
elems(x) = [i for i in 0:3 if (x >> i) & 1 == 1]

function level(n::Int)
    n == 0 && return Int[]
    cur = level(n - 1)
    [x for x in U if issubset(Set(elems(x)), Set(cur))]
end

@assert level(0) == Int[]
@assert level(1) == [0]
@assert level(2) == [0, 1]
@assert level(3) == [0, 1, 2, 3]
@assert level(4) == U
# beth 尺寸链：|V_{n+1}| = 2^{|V_n|} 在有限层的精确复现。
@assert length.(level.(1:4)) == [1, 2, 4, 16]
# 层包含链 V_n ⊆ V_{n+1}。
for n in 0:3
    @assert issubset(Set(level(n)), Set(level(n + 1)))
end

# ── 二、见证条款：λ-强 / 超强 / 强 ──
# Wit = (crit, jκ, captured)：临界点、j(κ)、目标模型捕获的秩层号集合。
struct Wit
    crit::Int
    jk::Int
    captured::Set{Int}
end

# (κ,λ)-强条款：κ ≤ λ、λ < j(κ)、V_λ ⊆ M（第 λ 层被捕获）。
lam_strong(w, l) = w.crit <= l && l < w.jk && l in w.captured
# 超强条款：V_{j(κ)} ⊆ M。
superstrong(w) = w.jk in w.captured
# 强条款：对所有 λ ≥ κ 都 λ-强（有限 captured 上恒假）。
is_strong(w, maxλ) = all(lam_strong(w, l) for l in w.crit:maxλ)

# ── 三、有限强度矩阵：行 = 见证，列 = λ ──
witnesses = [
    Wit(2, 3, Set([2])),   # 恰好捕获第 2 层：可测类似物（κ=2、j(κ)=3）
    Wit(2, 5, Set([3])),   # 单 λ 见证：λ=3
    Wit(2, 5, Set([2, 3, 4])),  # λ=2,3,4 三点见证
    Wit(2, 6, Set([2, 3, 4, 5])),  # 四点见证，λ=5 处断
    Wit(2, 4, Set([4])),   # 超强见证：j(κ)=4 被捕获
]
println("有限强度矩阵（行 = 见证 (κ,jκ,cap)，列 = λ = 2..6）：")
print("            ")
for l in 2:6; print("λ=$l  "); end
println()
for w in witnesses
    print("($(w.crit),$(w.jk),$(sort(collect(w.captured))))  ")
    for l in 2:6
        print(lam_strong(w, l) ? " ✓   " : " ·   ")
    end
    println("  | 超强:$(superstrong(w) ? "✓" : "·")")
end

# 矩阵断言：每行只在有限列点亮——「对所有 λ 的见证」永不出场。
@assert all(any(!lam_strong(w, l) for l in 2:20) for w in witnesses)
# 有限捕获集上的强条款恒假（鸽笼：captured 有限而 λ 无穷）。
for w in witnesses
    L = w.crit + maximum(w.captured) + 1   # 超出捕获集的层号
    @assert !lam_strong(w, L)
    @assert !is_strong(w, L)
end
# 超强 ≠ 任意单 λ 强：超强见证 (2,4,[4]) 在 λ=4 处并非 λ-强？
# λ=4：crit=2≤4 ✓、4<4 ✗ —— j(κ) 本身不能作为自己的 λ（j(κ)>λ 要求）。
w_ss = witnesses[5]
@assert superstrong(w_ss)
@assert !lam_strong(w_ss, 4)
@assert lam_strong(w_ss, 3) == false   # 3 ∉ captured
# 可测类似物：(κ, κ+1)-强 = 捕获第 κ 层（定义 1.18 之后的观察）。
w_meas = witnesses[1]
@assert lam_strong(w_meas, 2)
@assert !lam_strong(w_meas, 3)

println("Julia：V 层尺寸 1,2,4,16 与包含链；强度矩阵每行有限点亮；")
println("有限捕获恒非强；超强条款与 λ-强条款互不蕴含（j(κ)>λ 边界）")
println("END ====")
```

矩阵五行对五条款：可测类似物只点亮 $\lambda=\kappa$ 列、
单 λ 见证只点亮一列、三点/四点见证点亮区间、超强见证的
$\checkmark$ 在矩阵**外**（$j(\kappa)$ 列）——「目标闭包是
另一根轴」的可视化。边界断言 $\lambda=j(\kappa)$ 处条款失败
（$j(\kappa)>\lambda$ 是严格不等式）对应正文 101.6 的技术
禁区讨论。

矩阵怎么读：**列扫描**给出「哪个见证够到这个 λ」（λ=4 列
只有 three_points 与 four_points 点亮——捕获集要含 4 且
jκ>4）；**行扫描**给出「这个见证的强度轮廓」（four_points
的轮廓是区间 [2,5)——恰好是 captured∩(crit,jκ) 的形状）；
**对角线之外**（超强列）是另一根轴——只有 jκ 落进自身
captured 的行点亮。`is_strong(w, maxλ)` 的取值在有限 maxλ
内可以真（four_points 在 maxλ=5 内「强」）——但鸽笼断言用
`L = crit + max(captured) + 1` 精确给出断点：**任何有限
maxλ 的「强」都是截断幻觉**，这正是 101.8 第二本账的机器
面。`wit_lam3`（Coq）/`lam3`（Agda）的样本见证 (2,5,{3})
横跨三通道同型——三个证明器各自验证「λ=3 处成立、λ=4 处
jκ 边界失败、超强失败」三件事，构成跨通道的交叉对拍。

## 101.13 机器通道五：Python——独立对拍

```python
# 第 101 章：与 Julia 独立对拍——递归秩层、强度矩阵与条款穷举。
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

U = tuple(range(16))


def elems(x):
    return frozenset(i for i in range(4) if (x >> i) & 1)


def level(n):
    if n == 0:
        return ()
    cur = set(level(n - 1))
    return tuple(x for x in U if elems(x) <= cur)


def main():
    print("==== 101")
    assert level(1) == (0,)
    assert level(2) == (0, 1)
    assert level(3) == (0, 1, 2, 3)
    assert level(4) == U
    assert [len(level(n)) for n in (1, 2, 3, 4)] == [1, 2, 4, 16]
    for n in range(4):
        assert set(level(n)) <= set(level(n + 1))

    # 见证条款（frozenset 对拍 Julia 的 Set）。
    def lam_strong(crit, jk, cap, l):
        return crit <= l and l < jk and l in cap

    def superstrong(jk, cap):
        return jk in cap

    witnesses = [
        (2, 3, frozenset({2})),
        (2, 5, frozenset({3})),
        (2, 5, frozenset({2, 3, 4})),
        (2, 6, frozenset({2, 3, 4, 5})),
        (2, 4, frozenset({4})),
    ]
    # 矩阵对拍：每行恰在与 Julia 相同的列点亮。
    expected = [
        [True, False, False, False, False],
        [False, True, False, False, False],
        [True, True, True, False, False],
        [True, True, True, True, False],
        [False, False, False, False, False],
    ]
    for (crit, jk, cap), row in zip(witnesses, expected):
        got = [lam_strong(crit, jk, cap, l) for l in range(2, 7)]
        assert got == row, (crit, jk, sorted(cap), got)
    assert superstrong(4, frozenset({4}))
    assert not any(superstrong(w[1], w[2]) for w in witnesses[:4])

    # 有限捕获恒非强（鸽笼）。
    for crit, jk, cap in witnesses:
        L = crit + max(cap) + 1
        assert not lam_strong(crit, jk, cap, L)
        assert not all(lam_strong(crit, jk, cap, l)
                       for l in range(crit, L + 1))
    # 边界账：超强见证在 λ=j(κ) 处非 λ-强（j(κ)>λ 是严格不等式）。
    assert not lam_strong(2, 4, frozenset({4}), 4)
    # 可测类似物：(κ,κ+1)-强 ⟺ 捕获第 κ 层且 j(κ)>κ。
    assert lam_strong(2, 3, frozenset({2}), 2)
    assert not lam_strong(2, 3, frozenset({2}), 3)

    print("Python：V 层尺寸 1,2,4,16、包含链、矩阵逐格对拍一致、")
    print("鸽笼断言、j(κ)>λ 边界与可测类似物——与 Julia 独立对拍通过")
    print("END ====")


if __name__ == "__main__":
    main()
```

与 Julia 的分工：`expected` 矩阵**手写硬编码**在 Python 侧，
Julia 侧由条款函数动态计算——两侧一致才是对拍（任何一侧的
条款实现错位都会撞断言）。frozenset 的 `<=` 与 Julia 的
`issubset` 对位；`level` 的递归 + 元组实现与 Julia 的向量
实现互为独立重构。

对拍的故障检出面：Julia 的 `elems` 用位移掩码 `x >> i & 1`、
Python 用同式；`level` 一侧是「向量 + Set 判包含」、一侧是
「元组 + frozenset 判包含」——若两侧的 `elems` 有位宽差异
（例如 Julia 的 `0:3` vs Python 的 `range(4)`），`level 4`
会先在尺寸断言（16 vs 少了高位码）炸开。`expected` 矩阵的
**手写硬编码**是防「两侧共享同一个条款实现 bug」的孤本
见证：条款函数若在两侧被同样地写错（比如 `<` 写成 `<=`），
动态对拍永远一致——硬编码期望值是对拍机制的最后防线。这条
纪律在 82 章（策略查询位）、96 章（四件套对拍）已经立过，
本章的 λ 列硬编码是它在「矩阵」维度上的推广。

## 101.14 机器通道六：Isabelle——真 V_n 层级

```isabelle
theory Strong
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 101 章：秩层 V_n 的递归、包含链与前两层精确内容（真集合论定理，
非有限影子），以及导出超滤子对交封闭的记账。张子本体（定义 1.19-1.23、
定理 1.31-1.35）留在正文。\<close>

definition vlevel :: "i \<Rightarrow> i" where
  "vlevel(n) \<equiv> nat_rec(n, 0, \<lambda>m A. Pow(A))"

lemma vlevel_0 [simp]: "vlevel(0) = 0"
  unfolding vlevel_def by (rule nat_rec_0)

lemma vlevel_succ: "n \<in> nat \<Longrightarrow> vlevel(succ(n)) = Pow(vlevel(n))"
  unfolding vlevel_def by (simp add: nat_rec_succ)

text \<open>前两层精确内容：V_1 = {0}、V_2 = {0, {0}}。\<close>

lemma vlevel_1: "vlevel(1) = {0}"
  by (simp add: vlevel_succ)

lemma vlevel_2: "vlevel(2) = {0, {0}}"
  by (simp add: vlevel_succ vlevel_1 Pow_insert Un_cons)

lemma vlevel_1_sub_2: "vlevel(1) \<subseteq> vlevel(2)"
  by (simp add: vlevel_1 vlevel_2)

text \<open>层包含链 V_n \<subseteq> V_{n+1}：归纳，Pow 的单调性逐环传递。\<close>

lemma vlevel_mono: "n \<in> nat \<Longrightarrow> vlevel(n) \<subseteq> vlevel(succ(n))"
  apply (induct rule: nat_induct)
   apply (simp add: vlevel_succ)
  apply (simp add: vlevel_succ)
  apply (blast intro: Pow_mono)
  done

text \<open>成员版账目：x \<in> V_{n+1} \<longleftrightarrow> x \<subseteq> V_n。\<close>

lemma mem_vlevel_succ_iff:
  "n \<in> nat \<Longrightarrow> x \<in> vlevel(succ(n)) \<longleftrightarrow> x \<subseteq> vlevel(n)"
  by (simp add: vlevel_succ Pow_iff)

text \<open>导出记账（恒等嵌入版）：U = {X \<in> Pow(A). a \<in> X} 对交封闭。
正文中的完整版把 X 换成 j-像，封闭性来自单射的
j``(X\<inter>Y) = j``X \<inter> j``Y（Lean 通道已证有限影子）。\<close>

definition derivedU :: "i \<Rightarrow> i" where
  "derivedU(a) \<equiv> {X \<in> Pow(cons(a, 0)). a \<in> X}"

lemma derivedU_inter:
  "X \<in> derivedU(a) \<Longrightarrow> Y \<in> derivedU(a) \<Longrightarrow> X \<inter> Y \<in> derivedU(a)"
  unfolding derivedU_def by auto

lemma derivedU_nonempty: "derivedU(a) \<noteq> 0"
  unfolding derivedU_def by auto

end
```

Isabelle 版独占一份**真集合论**内容：`vlevel` 是 ZF 里的
$V_n=\mathcal P^n(0)$ （经 `nat_rec` 递归子），`vlevel_mono`
是**全 n 的定理**而非有限影子（Pow 单调 + 归纳）。实测坑四
笔：`iterates`/`rec` 都不在 `ZF.Nat` 的辖域（「Extra variables
on rhs」——`nat_rec(k,a,b)` **k 在首位**、方程
`nat_rec_succ` 带 `m ∈ nat` 前提）；`Pow(0)={0}` 与
`Pow_insert` 藏在 **`ZF.equalities`**（须显式导入）；
`{0}∪{{0}}={0,{0}}` 须补 `Un_cons` 才归一；`hence IH: ... .`
的裸 `this` 收尾对多事实上下文失效（改 apply 脚本 +
`blast intro: Pow_mono`）。

为什么这章的 Isabelle 反而做「真定理」：Lean/Coq/Agda 的
位编码是 16 元宇宙的**影子**，而 ZF 的 `Pow` 是真幂集——
`vlevel_mono` 对一切 $n\in\omega$ 成立，不是有限核查。
四个通道证明同一个方向性事实（层包含链），Isabelle 的版本
量纲最高；三个构造性通道的版本量纲低但**可计算**（能对
16 元宇宙枚举核查）。这是七通道设计里常见的「量纲交换」
分工：Isabelle 管无界的真命题，构造通道管有界的可验算例，
Julia/Python 管组合对拍——同一数学对象在不同量纲上的
投影互相印证。`mem_vlevel_succ_iff`（$x\in V_{n+1}\iff x\subseteq V_n$ ）是唯一在四个证明通道都有对应物的定理：
Lean/Coq/Agda 的 `level_mono_step` 是它的点态方向，
Isabelle 的 `Pow_iff` 版是它的双方向等价——命名空间的
差异（`Nat.card_Ico` vs `Pow_iff`）背后是同一数学句。

## 101.15 机器通道七：Prolog——条款反向查询

```prolog
:- encoding(utf8).
% 第 101 章：有限秩层递归与见证条款查询器。

% ── 一、位编码有限秩层（宇宙 0..15，元素 = 置位位号）──
elems(X, Es) :- findall(I, (between(0, 3, I), X /\ (1 << I) =\= 0), Es).

subsetL([], _).
subsetL([H|T], L) :- member(H, L), subsetL(T, L).

level(0, []).
level(N, L) :-
    N > 0,
    N1 is N - 1,
    level(N1, Cur),
    findall(X, (between(0, 15, X), elems(X, E), subsetL(E, Cur)), L).

% ── 二、见证条款：查询某见证满足哪些条款 ──
% wit(名, crit, jκ, captured)
wit(measurable_like, 2, 3, [2]).
wit(lam3,            2, 5, [3]).
wit(three_points,    2, 5, [2, 3, 4]).
wit(four_points,     2, 6, [2, 3, 4, 5]).
wit(superstrong_w,   2, 4, [4]).

% (κ,λ)-强条款：κ≤λ、λ<j(κ)、λ 被捕获。
clause_lam_strong(W, L) :-
    wit(W, K, J, Cap),
    K =< L, L < J,
    member(L, Cap).

% 可测类似物条款：(κ,κ+1)-强。
clause_measurable_like(W) :-
    wit(W, K, J, Cap),
    J is K + 1,
    member(K, Cap).

% 超强条款：j(κ) 被捕获。
clause_superstrong(W) :-
    wit(W, _, J, Cap),
    member(J, Cap).

% 见证在 maxλ 以内是否「强」（所有 λ≥κ 都 λ-强）。
is_strong_upto(W, MaxL) :-
    wit(W, K, _, _),
    forall(between(K, MaxL, L), clause_lam_strong(W, L)).

% 反向查询：哪些见证满足给定条款。
satisfies(W, lam_strong(L))   :- clause_lam_strong(W, L).
satisfies(W, measurable_like) :- clause_measurable_like(W).
satisfies(W, superstrong)     :- clause_superstrong(W).

main :-
    format("==== 101~n"),
    level(1, L1), L1 == [0],
    level(2, L2), L2 == [0, 1],
    level(3, L3), L3 == [0, 1, 2, 3],
    level(4, L4), L4 == [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15],
    length(L1, 1), length(L2, 2), length(L3, 4), length(L4, 16),
    % 层包含链 V_n ⊆ V_{n+1}。
    forall((between(0, 3, N), succ(N, N1), level(N, A), level(N1, B)),
           subsetL(A, B)),
    % 逐条查询五个见证的条款满足表。
    findall(W-3, clause_lam_strong(W, 3), L3s),
    L3s == [lam3-3, three_points-3, four_points-3],
    findall(W, clause_superstrong(W), SS), SS == [superstrong_w],
    findall(W, clause_measurable_like(W), ML), ML == [measurable_like],
    % 有限捕获恒非强：每个见证都在某层断。
    forall(wit(W, K, _, _),
           (J is K + 20, \+ is_strong_upto(W, J))),
    format("层尺寸 1,2,4,16；λ=3 见证 {lam3,three_points,four_points}；超强 {superstrong_w}；~n"),
    format("可测类似物 {measurable_like}；每见证有限点亮——恒非强~n"),
    writeln("END ====").
```

Prolog 版做**双向查询**：正向 `clause_lam_strong(W, L)` 判定
条款、反向 `findall(W, ...)` 枚举满足者——这正是「查询某见证
满足哪些条款」的 Task 要求。实测坑一笔：`is_strong_upto` 的
否定查询（`\+ is_strong_upto`）依赖 forall 内变量不外泄
（`between(K, MaxL, L)` 的 L 被 forall 封住——若去掉 `forall`
包裹让 L 外泄，`\+` 会在第一个失败点静默返回真，恒非强断言
变成假绿）。

Prolog 的反向查询还有一个教学面：`?- clause_lam_strong(W, L)`
以**两个自由变量**询问时，回溯枚举出整个「见证 × λ」满足
关系——这就是强度矩阵的生成程序（Julia 手写五行、Prolog
一条规则）；`?- satisfies(W, superstrong)` 则把「条款」本身
作为参数（`lam_strong(L)`/`measurable_like`/`superstrong`
是一阶项），查询的**维度**可以翻转。`wit` 事实库的五个样本
与 Julia/Python 的五行见证严格同构——三通道共享同一数据
的不同表示（闭包/元组/事实），任何一侧改条款语义都会在
`L3s == [lam3-3, ...]` 的期望列表上炸开。

## 101.16 机器的边界

1. **张子超幂不可机化**：$(\mathcal D/\equiv,\in_\varepsilon)$
   的论域是真类商、核心断言 $[(a,f)]\in_\varepsilon[(b,g)] \iff j(f)(a)\in j(g)(b)$ 把类嵌入焊进结构——任何有限替身
   都自动丢失「商」与「传递化」两步。
2. **四公理的有限影子退化**：κ-完全在有限层自动真（有限滤子
   皆主）；ω-完全性在有限层自动真（有限序列必有极大协调
   扩张）；协调性与正规性只剩投影一致性与常值化的有限痕迹。
   机器件锚定的是**公理的语法件**，不是它们的超穷内容。
3. **定理 1.32 的表达力跃迁不可见**：从类量词到集合对象的
   「压缩」发生在 $[\lambda]^{<\omega}$ 的真类坐标上；有限
   版 $2^{16}$ 个坐标可以对拍语法，测不出表达力。
4. **定理 1.35 的 M 内自举**消费「${}^{2^\kappa}M\subseteq M$
   ⟹ $\varepsilon\in M$ 」——序列封闭性的账单在有限层永远
   零元（有限结构对一切序列封闭）。
5. **有限强度矩阵不是强度证明**：三证明通道的鸽笼定理
   （`not_strong_finite` ×3）从**内部**钉死这件事——任何有限
   captured 结构都造不出「全 λ 点亮」的行，与 101.8 的三本账
   表互为印证。
6. **分层边界的分工**：四条公理在有限层的退化程度不同——
   (a) 与 (d) 完全退化（自动真），(b) 只剩投影的位置一致性
   （Lean/Coq 的 `image_inter` 记账是其极小内核），(c) 只剩
   单点常值化（`fHead` 型样本）。所以本章机器件的重心天然
   落在**地基**（V 层结构）与**账本**（条款检查）两侧，
   公理本体留在正文——这与 99 章（紧致性三面孔，机器件落
   在有限可满足性）、100 章（正规性，机器件落在锥代数）的
   重心分布各不相同，反映了各章数学内核的可有限化部位
   不同。
7. **beth 尺寸链的地位**：1,2,4,16 的核查看似平凡，实则是
   全章唯一「超穷内容可完整投影到有限层」的命题——
   $V_{n+1}=\mathcal P(V_n)$ 的尺寸律 $2^{|V_n|}$ 在
   有限层与超穷层**同构成立**（不依赖任何不可达性）。对照
   定理 1.32 的表达力跃迁（有限层不可见）、定理 1.35 的
   反射（有限层自动真），beth 链是「量纲恰好对齐」的稀有
   样本，值得在检查问题里追问它与第 71 章累积层次构造的
   关系。

## 101.17 与前后章的接口

- **向前收账**：第 94 章的超滤子超幂是张子在 $|a|=1$ 、
  $\lambda=\kappa$ 的退化情形；第 97 章迭代超幂的投影机制
  （引理 1.42）被公理 (b) 吸收为「协调性」；第 99 章
  $\mathcal P_\kappa(\lambda)$ 测度与张子的关系是「单坐标
  vs 坐标网」——正规精良测度是一个 $E_a$ （全体坐标共享
  一个滤子），张子是坐标分立的一族；第 100 章的因子分解
  $j=k\circ j_U$ 在本章升级为定向系统版 $j=k_\varepsilon \circ\pi_\varepsilon\circ j_\varepsilon$ 。
- **向后供货**：第 102 章武丁基数的定义 1.24 直接用
  $(\kappa,V_{\lambda+1})$ -张子书写，定理 1.36 的四款等价
  （(a) 局部见证族 / (b) 荟萃 / (c)(d) 函数版嵌入）全部
  消费本章的广义张子机器；「保持 $A$ 作用的 $\lambda$ -
  强」条款 (iii)（$A\cap V_\lambda=j(A)\cap V_\lambda$ ）
  是引理 1.59（支撑整块进入超幂）的**相对化**版本。第 104
  章 Prikry 力迫的超滤子背景、第 109 章泛型超幂的表示问题、
  第 110 章 NS 饱和的马丁极大原理，都以本章的「坐标网表示
  嵌入」为语法基础。
- **内模型侧的悬念**：第 98 章证明了 $L[U]$ 的唯一性——
  单个可测的账本独一份。本章的强/超强要求任意高度的塔
  包含，$L[U]$ 型单序列内模型显然装不下；「能装下强基数
  的内模型长什么样」正是 $L[\vec E]$ （张子序列模型）的
  动机，也在 123 章六书总表的强度轴上标出下一段旅程。

## 101.18 本章要点与检查问题

把全章收进五句话：**强基数把「目标模型装下 $V_\lambda$ 」
参数化**（定义 1.18），**张子把类嵌入压缩成集合**（导出过程
+四公理，定理 1.32 达成一阶表达），**超强把塔顶推到**
$j(\kappa)$ （广义张子接住序列坐标），**超紧之下超强
荟萃**（定理 1.35 的三行自举账），**三本账（单 λ / 全 λ /
目标闭包）量纲不同不可互推**（鸽笼定理的机器面）。

- **定义 1.18**：$(\kappa,\lambda)$ -强嵌入 = 临界点 $\kappa$
  + $j(\kappa)>\lambda$ + $V_\lambda\subseteq M$ ；可测 =
  $(\kappa,\kappa+1)$ -强；超紧 ⟹ 强。命题 1.4：强 ⟺ 任意
  集合落入某目标模型（Laver 定理的推论、强基数形态的刻画）。
- **导出张子与四公理**：$X\in E_a\iff a\in j(X)$ ；κ-完全
  （超滤子系）、协调性（投影一致）、正规性（加高坐标
  $b=a\cup\{j(f)(a)\}$ 的恒同命中）、ω-完全性（树论证——
  有秩性绝对性）。
- **张子超幂**：定向系统 $\langle N_a,i_{a,b}\rangle$ 的极限；
  有秩性两证（依赖 $j$ 的嵌入版 + 独立的 ω-完全性反证版）；
  引理 1.56（恒等函数给 $\lambda$ 的典型表示）。
- **定理 1.31/1.32**：张子嵌入四条性质（临界点、忠实性
  $X\in E_a\Rightarrow a\in j_\varepsilon(X)$ 、值域表示、
  $|V_\alpha|<\lambda\Rightarrow V_\alpha\subseteq M_\varepsilon$ ）；
  强基数 ⟺ $\forall\lambda\exists(\kappa,V_{\lambda+1})$ -张子
  ——ZFC 纯语言表达达成。
- **超强与广义张子**：定义 1.21（$V_{j(\kappa)}\subseteq M$ ，
  Kunen 不排除、纯技术回避）；$Y=V_{j(\kappa)}$ 序列坐标、
  $a+b$ 拼接、引理 1.59（支撑整块 $Y\subseteq M_\varepsilon$ ）。
- **定理 1.35**：$2^\kappa$ -超紧 ⟹ 超强荟萃——三行账
  （张子是集合 $\varepsilon\in M$ / $M$ 内自举 / 拉回
  测一），与第 100 章命题 1.2 同一发动机。
- **三本账**：单 λ 见证（序数量纲）/ 全 λ 见证（类量词→张子
  族）/ 目标闭包（嵌入内部结构，另一根轴）——有限矩阵每行
  有限点亮，「全 λ」永不出场（鸽笼 ×3）。
- **实测账**：Lean `image_inter` 假设后置、`Nat.card_Ico`
  命名空间、`↪` vs 普通函数、`x.val.testBit`；Coq
  `vm_compute` 救 reflexivity 内核爆炸、`level_S` 单层方程
  防 cbn unify 指数回溯、filter 谓词布尔化；Agda with 不穿
  透假设类型（∨-inv 范式）、无 `n≤m+n` 自造 `≤-swap`、
  `s≤s` 计数账；Isabelle `nat_rec` 首参 + 前提、
  `ZF.equalities` 显式导入、`Un_cons` 归一、裸 `this` 收尾
  失效；Prolog forall 封变量。

检查问题：

1. 定义 1.18 的条款 (i) 中 $j(\kappa)>\lambda$ 若放宽为
   $j(\kappa)\ge\lambda$ ，命题 1.4 的 (ii)⟹(i) 方向会在
   哪一步仍然成立、哪一步失去内容？（提示：$x=V_\lambda\in M$
   与 $M$ 传递已给 $V_\lambda\subseteq M$ ；但 $\lambda= j(\kappa)$ 时 $V_\lambda\subseteq M$ 正是超强条款——
   「λ-强」与「超强」的命名边界在哪里？）
2. 张子公理 (c) 正规性的证明取 $b=a\cup\{j(f)(a)\}$ 。若
   $j(f)(a)\in a$ （回归值已在坐标内），证明在哪一步失效？
   这与第 100 章 P_κ(λ) 正规性中选择函数值 $<$ 坐标最大值
   的「回归」条件如何对照？
3. 定理 1.35 的第一行「$\varepsilon\in M$ 」若只有
   ${}^{<\lambda}M\subseteq M$ （强紧嵌入的封闭度）而无
   ${}^{2^\kappa}M\subseteq M$ ，账单差在哪？（$\varepsilon$
   的坐标域 $V_{j(\kappa)}^{<\omega}$ 需要多长的序列编码？）
4. Julia/Python 强度矩阵中，超强见证 (2,4,{4}) 在所有
   $\lambda$ 列都是 ·。给出一个 captured 集与 jκ 的组合，
   使某行同时点亮「λ=2,3 列」与「超强列」；再说明为什么有限
   矩阵永远点不亮「λ=j(κ) 列」。
5. beth 尺寸链 1,2,4,16 在六个通道上被核验。它与第 71 章
   累积层次 $V_\alpha=\bigcup_{\beta<\alpha}\mathcal P (V_\beta)$ 的定义在后继步上有什么不同？这个不同为什么
   让尺寸律在有限层可核验，而极限步（$V_\omega$ 型）在
   本章的 16 元宇宙里无法表达？
6. 张子四公理中，(b) 协调性说 $E_a$ 是 $E_b$ 的投影
   （$a\subseteq b$ ）。若去掉 (b) 但保留其余三条，构造
   一个「两坐标矛盾」的具体反例形态（提示：让 $E_{\{0\}}$
   含 $X$ 、$E_{\{1\}}$ 含 $Y$ ，而 $E_{\{0,1\}}$ 对
   $\pi^{-1}(X)\cap\pi^{-1}(Y)$ 的判决与二者都相反）——
   这样的系统在超幂构造的哪一步崩溃？

---

上一章：[100 超紧基数](100-supercompact.md) · 下一章：[102 武丁基数](102-woodin.md)
