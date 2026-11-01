[上一章：迭代树 I](118-itertree1.md) · [目录](../README.md) · [下一章：投影集合稳赢性 I](120-pd1.md)

# 第 119 章　迭代树 II：可迭代性与武丁表示

## 1. 本章要区分哪两件事

第 118 章已经把一棵有限双链树的节点、父边、张子所属模型和超幂作用目标分开。
本章先沿原书继续研究保持型、单步引理和交错链，再单独讨论“选枝策略”的有限计算模型。
这两条线在概念上相关，却不能混为一个定理。
原书在这里给出了构造特定交错链并证明 Even 枝无秩的详细论证。
这不是一个“所有相应迭代树都可迭代”的一般定理。
我们的七通道程序也只验证六步目标选择和有限证书。
它们不验证真实 ZFC 模型，不验证无限树，更不验证武丁基数或 Martin–Steel 定理。
读完本章，应能说明单步构造为何在无限延伸时遇到序数下降障碍。
也应能说明无差别元怎样消除这个障碍。
最后还要能准确区分“某棵树上存在一根良枝”与“存在一个系统在每棵相应树上选良枝”。

## 2. 从比较法到选枝策略

比较两个准模块时，双方轮流拿出张子，以消除已有模型之间的差异。
每一步必须检查张子的临界点、强度和模型间吻合度。
新模型是某个较早模型的超幂，而不必是上一步模型的超幂。
因此比较过程天然形成迭代树，而不是一条预先规定的直线。
当长度达到极限序数时，要继续比较就必须选一根树枝并取直接极限。
若所选枝的直接极限有秩，比较才有继续下去的通常意义。
这里把“直接极限有秩的枝”简称为良枝。
有限阶段的选择通常由当前张子及其合法作用目标决定。
极限阶段的选择则是另一种数据：它依赖整棵已构造的树。
一个迭代策略必须把这两种选择组织成对合法位置的统一回答。
所以“每一步都能找到某个张子”还不等于“已经有完整策略”。
同样，“某个极限存在一根良枝”也不等于“策略已经指定了它”。

## 3. 定理 3.50：把保持作用移到张子超幂

先回顾保持谓词作用的强基数。
若 \(A\) 是一个类，\(\delta<\eta\)，则 \(\delta\) 是保持 \(A\) 作用的 \(\eta\)-强基数，意味着有嵌入 \(j:V\to M\) 满足以下条件。
临界点是 \(\delta\)，并且 \(\eta<j(\delta)\)。
模型包含所需层级，即 \(V_\eta\subset M\)。
最关键的是吻合等式
\[
j(A)\cap V_\eta=A\cap V_\eta.
\]
定理 3.50 把由一般嵌入给出的见证改写成由张子给出的见证。
在 \(\kappa\) 为强极限基数、\(A\subset V_\kappa\) 的假设下，可以在 \(V_\kappa\) 内找到这样的张子 \(E\)。
证明取 \(j\) 诱导的适当 \((\delta,|V_{\eta+1}|)\)-张子，并分解 \(j=k\circ i_E\)。
由于关键层级在两个超幂中吻合，因子映射 \(k\) 在该层级上不再改变所需信息。
于是由 \(j\) 得到的 \(A\)-吻合等式可以逐项转移到 \(i_E\)。
这一步很重要：后续构造需要的是模型内部的张子，而不是只有外部描述的总嵌入。

## 4. 定义 3.34：保持一个参数的型

“保持型”把保持谓词作用应用到参数的完整类型上。
设 \(\beta\) 是序数，\(\gamma\) 是极限序数，\(\delta<\gamma\) 是基数。
取有限参数序列 \(z\in V_{\gamma+\beta}^{<\omega}\)。
记号 \(\operatorname{tp}^{\gamma}_{(\gamma,\beta)}(z)\) 记录相应结构中关于 \(z\) 的类型信息。
定义要求对每个满足 \(\delta<\eta<\gamma\) 的 \(\eta\)，\(\delta\) 都是保持该类型作用的 \(\eta\)-强基数。
因此保持型不是只保持一条公式。
它要求在整个指定高度上，参数的可表达性质都被相应嵌入保持。
这也解释了为什么引理 3.84 和 3.85 要把“型”和“保持型”翻译为集合论语言。
只有把要求写进类型本身，后续才能通过类型相等把见证从一侧搬到另一侧。

## 5. 定理 3.51：武丁基数的保持型刻画

定理 3.51 给出武丁基数的等价刻画。
对固定的 \(\beta\) 和 \(z\in V_{\kappa+\beta}^{<\omega}\)，定义
\[
X(\beta,z)=\{\delta<\kappa:\delta\text{ 保持 }z\text{ 在 }(\kappa+\beta)\text{ 上的型}\}.
\]
第一个方向说，若 \(\kappa\) 是武丁基数，则每个这样的 \(X(\beta,z)\) 都在 \(\kappa\) 中无界。
最弱的反向假设只说：对每个 \(z\in V_{\kappa+1}^{<\omega}\)，集合 \(X(1,z)\) 非空。
定理证明这个看似很弱的存在性条件已经足以推出武丁性。
反向证明把函数 \(f:\kappa\to\kappa\) 编码为参数 \(\langle f\rangle\)。
再选取保持其类型的强基数见证，使临界点以下关于 \(f\) 的等式被完整保存。
由这些等式可推出临界点对 \(f\) 封闭，并得到武丁定义所需的强度。
这里的力量来自“整个类型”，不是来自某一条任意选取的公式。

## 6. 定理 3.52：丰富张子的四个指标

定理 3.52 将保持型条件改写为逐层存在张子的条件。
对每个开区间 \((\delta,\kappa)\) 中的 \(\alpha\)，都有 \(V_\kappa\) 中的张子 \(E\) 满足四项要求。
第一，\(\operatorname{Crit}(i_E)=\delta\)。
第二，\(E\) 的强度至少达到 \(\alpha\)，也就是 \(V_\alpha\subset\operatorname{Ult}(V,E)\)。
第三，\(\alpha<i_E(\delta)\)。
第四，原参数与像参数在相应高度具有相同类型：
\[
\operatorname{tp}^{\alpha}_{(\kappa,\beta)}(z)
=
\left(\operatorname{tp}^{\alpha}_{(i_E(\kappa),i_E(\beta))}\right)^{\operatorname{Ult}(V,E)}(i_E(z)).
\]
临界点决定哪些小对象不动。
强度决定超幂能看到多少集合。
\(\alpha<i_E(\delta)\) 保证新临界点把所需高度推到上方。
类型等式则负责把原公式和见证翻译到新模型。
后续单步引理正是同时使用这四项，而不是只使用“张子足够强”。

## 7. 引理 3.84 与 3.85：让类型可以携带构造任务

引理 3.84 的 `LeiXing_n` 把有限序列在指定高度上的类型形式化。
引理 3.85 的 `BaoXing_n` 把“某基数保持该序列的型”形式化。
这些公式允许使用类型、序数和基数作为参数。
于是“存在一个序数和一个有限序列，满足所需类型、保持型以及给定公式”本身也能成为类型中的一条语句。
如果两侧类型相同，一侧存在这样的见证，另一侧也就存在相应见证。
这就是单步引理后半部分的运输机制。
没有这层形式化，仅仅说两个参数“性质相同”不足以保证能取得新序数和新有限序列。
本章不把这两个元语言翻译展开成七通道代码。
它们属于原书的集合论语法与超幂语义论证，不是有限数字表能表达的对象。

## 8. 引理 3.86：单步引理的输入

单步引理从两个 ZFC 传递类模型 \(M,N\) 开始。
它们先在某个 \(\delta+1\) 高度吻合。
有限序列 \(x\) 与 \(x'\) 在两侧具有相应的相同类型。
在 \(M\) 中，\(\delta\) 保持 \(x\) 在指定高度上的型。
另有一个序数 \(\xi\) 使给定公式 \(\varphi(\xi)\) 在 \(M\) 的相应层级成立。
这些假设分别负责不同任务。
吻合度保证同一张子可以在另一侧使用。
类型相等负责把公式从一侧传到另一侧。
保持型负责产生足够丰富的新张子。
原公式中的 \(\xi\) 则提供下一步需要运输的存在见证。
把它们压成一句“两个模型很像”会丢失证明真正使用的结构。

## 9. 单步引理的输出

引理首先产出 \(\lambda<\kappa\) 和张子 \(E\in M\)。
当相应超幂有秩时，还产出 \(\delta^*\)、\(\xi^*\) 和有限序列 \(y^*\)。
新的 \(\delta^*\) 位于给定下界 \(\eta\) 与 \(i_E^N(\delta)\) 之间。
新模型与原模型在 \(\delta^*+1\) 高度重新吻合。
扩展后的序列 \(x+y\) 与 \(i_E^N(x')+y^*\) 具有相应相同类型。
在新超幂中，\(\delta^*\) 保持新序列的型。
同时，新层级的相应序数继续满足公式 \(\varphi\)。
所以一次调用不仅“再走一步”，还完整恢复下一次调用所需的全部归纳假设。
这就是它被称为单步引理的原因。
有限交错链可以反复调用它，但无限延伸还需要解决一个额外障碍。

## 10. 单步引理的证明骨架

证明先利用保持型条件选出足够强的张子。
吻合度引理保证同一 \(E\) 作用于 \(N\) 后，所得超幂与 \(M\) 仍有足够高的吻合度。
随后用超幂基本定理把类型中的公式改写成张子的大集条件。
由于大集属于同一 \(E\)，而两侧原类型相等，公式可以在两个超幂之间往返翻译。
接着把“存在新序数和新有限序列”的要求编码进一个类型公式。
原侧的 \(y\) 与 \(\xi\) 给出这条存在语句的见证。
类型运输后，在新超幂中取得 \(y^*\) 与 \(\xi^*\)。
引理的最后一部分还用同样方法处理额外的 \(z\)，取得相应的 \(\hat y,\hat\xi\)。
因此证明的核心不是任意挑选，而是把要挑选的对象写进可运输的类型。

## 11. 引理 3.87：任意有限长度的交错链

在武丁 \(\kappa\) 下，引理 3.87 为每个有限 \(n\) 构造长度 \(n+1\) 的交错链。
整条链仍属于 \(V_\kappa\)。
归纳构造保持模型间吻合、类型一致和保持型三组条件。
每次应用单步引理，新张子和新参数都把链条延长一步。
超幂有秩性则由已有的有限树结果和临界点—强度关系保证。
这里“任意有限长度”是对所有 \(n<\omega\) 的全称命题。
它不等于已经构造出一个属于 \(V_\kappa\) 的长度 \(\omega\) 的完整序列。
有限构造在每一步都可能依赖前一步的新参数。
要把这些选择组成一个无限序列，必须确保参数不会被迫无限下降。

## 12. 无限延伸的真正障碍

单步引理要求某些序数参数满足 \(\xi<\beta\)。
若机械地反复延伸，参数会形成严格递减趋势。
序数中不存在无限严格递降序列。
所以不能简单地对单步引理做无限次重复并声称构造完成。
这个障碍不是编程上的燃料不足。
即使允许任意大的有限燃料，也不能靠有限逼近拼出违反序数良基性的参数链。
原书的解决办法不是取消不等式，而是寻找两个在所需类型上无差别的参数。
它们作为序数可以不同，但在当前构造能看见的语言中不可区分。
这样，实际序数位置可以交替变化，而类型和保持型条件保持不变。

## 13. 引理 3.88：从整齐苏斯林树取得无差别元

设 \((T,\langle U_p:p\in\mathbb N^{<\omega}\rangle)\) 是一棵 \(\kappa^+\)-整齐苏斯林树。
引理 3.88 给出四个序数 \((\nu,\xi_0,\xi_1,\rho)\)。
它们满足
\[
\nu<\xi_0<\xi_1<\rho.
\]
四个参数都是梯度严格大于 \(\kappa\) 的强极限基数。
树本身满足 \(T\in V_\nu\)。
最关键的类型等式是
\[
\operatorname{tp}^{\nu}_{(\rho,0)}(\langle\xi_0\rangle)
=
\operatorname{tp}^{\nu}_{(\rho,0)}(\langle\xi_1\rangle).
\]
证明使用类型数量的上界。
在足够多的强极限基数中，不可能每个候选都占有不同类型。
鸽巢原理因此给出两个不同序数 \(\xi_0<\xi_1\)，它们在该高度具有相同类型。
“无差别”总是相对于指定语言和高度而言，并非两个序数绝对不可区分。

## 14. 引理 3.89：不动点与类型等价

引理 3.89 首先指出，对 \(V_\kappa\) 中的相关张子，四元组中的每个序数都是 \(i_E\) 的不动点。
这使嵌入不会破坏刚选好的无差别环境。
接着，对 \(z\in V_\nu^{<\omega}\) 和 \(\alpha<\kappa\)，有
\[
\operatorname{tp}^{\alpha}_{(\kappa,\xi_0)}(z)
=
\operatorname{tp}^{\alpha}_{(\kappa,\xi_1)}(z).
\]
证明把“某序列属于该类型”的语句交给 `LeiXing_n` 表达。
再利用引理 3.88 中关于 \(\xi_0,\xi_1\) 的类型等式完成替换。
同样的翻译也适用于 `BaoXing_n`。
所以保持 \(z\) 在 \((\kappa+\xi_0)\) 上的型，等价于保持它在 \((\kappa+\xi_1)\) 上的型。
这一步使构造可以在两个高度之间切换，而不丢失下一次单步应用所需的假设。

## 15. 引理 3.90：长度 \(\omega\) 的交错链

现在从 \(V\) 出发构造长度 \(\omega\) 的交错链 \(\mathcal C\)。
链及其张子仍被控制在 \(V_\kappa\) 内。
归纳状态记录模型 \(M_{2k}\)、前一模型 \(M_{2k\ominus1}\)、临界点参数 \(\delta_{2k}\) 和序数 \(\beta_k\)。
它同时保持吻合度、空参数的类型、保持型以及沿 Even 方向的嵌入不等式。
第一段延伸从 \(M_{2k}\) 与 \(M_{2k\ominus1}\) 的吻合状态出发。
单步引理产生 \(E_{2k}\) 和新参数，把链条延长到 \(2k+1\)。
无差别元允许把高度从 \(\xi_0\) 换成 \(\xi_1\)，同时保留类型和保持型。
第二段延伸再应用单步引理，把链条延长到 \(2k+2\)。
于是一个完整的两段循环恢复了下一轮的归纳状态。

## 16. Even 枝为何无秩

构造不只是让链条无限延长，还刻意在 Even 方向制造下降。
关键不等式为
\[
\beta_{k+1}=\xi^*
<
i_E^{M_{2k}}(\beta_k)
=
j_{2k,2k+2}(\beta_k).
\]
这里左边是下一阶段选出的参数，右边是旧参数沿 Even 边嵌入后的像。
把这一不等式运输到 Even 枝的直接极限后，后一阶段的像严格小于前一阶段的像。
无限多个阶段便给出无限严格递降的序数序列。
若该直接极限有秩，其序数应当良基，不可能容纳这样的序列。
因此 Even 枝没有有秩极限。
这是原书关于特定交错链的完整构造，不是对任意迭代树的否定性结论。

## 17. 引理 3.91：交错链足够强

引理 3.91 说明，每根按前述意义构成的交错链都是足够强的迭代树。
足够强要求当前张子的强度覆盖与较早节点比较时所需的吻合高度。
在交错树序中，相关指标的集合会退化为容易计算的单点情形。
于是所需临界点严格小于当前张子的强度，定义中的关键不等式得到满足。
这一结论把第 118 章的“足够强”接口与本章的具体构造接起来。
引理 3.91 的完整证明续到下一页；本章只使用其陈述和证明接口。
后续投影集合稳赢性将在此基础上继续展开。
本章不提前宣称已经完成后续的 Martin–Steel 表示定理。

## 18. “存在良枝”与“策略系统选良枝”

先看存在性说法：对已经给出的某棵树 \(T\)，存在一根共尾枝 \(b\)，其直接极限有秩。
这是一个关于单棵树的存在命题。
证明可以只分析这棵树，也可以使用一个不可统一选择的全局见证。
再看策略说法：存在一个函数 \(\Sigma\)，对每个合法部分树和每个极限位置，都给出下一根枝。
并且只要对局双方都按规则行动，\(\Sigma\) 选择的枝就满足所需良基性。
这是跨所有相应树的统一函数命题，强度显然更高。
存在性甚至不给出可计算的选枝过程。
策略则必须在每个历史到达时作出一致回答。
因此本章机器件中的有限 `select_good_branch` 只是在两根已给证书之间选择。
它不是一般迭代策略，也不证明任何无限可迭代性。

## 19. 正规化与唯一性接口

比较证明还需要若干 bookkeeping 结论。
同一有限树上，由根到节点的合法路径必须唯一，否则“树枝”和“直接极限”会失去确定含义。
第 118 章已在 Coq 和 Agda 中用终点索引路径证明了这一有限唯一性。
本章的六步目标表则保证每个新节点只有一个预定父节点。
对一般迭代树，还需要追踪嵌入复合、极限嵌入以及不同书写顺序下的正规化。
这些结果保证比较过程中“同一个模型”不会因表示方式不同而被重复计算。
但本章取材段没有给出一个可独立声称的一般正规化定理。
所以这里只列出后续所需接口，不把它伪装成已经机器证明的结论。

## 20. 武丁表示接口与 Martin–Steel 边界

本章的武丁内容提供丰富张子、保持型参数和可无限延伸的交错链。
这些是后续研究整齐树、苏斯林表示和投影集合稳赢性的技术基础。
粗略地说，后续表示定理会用树及其纤维描述实数集，再利用迭代树论证比较不同表示。
武丁基数保证所需张子在各个高度足够丰富。
但“有这些接口”不等于已经证明投影集合的稳赢性或 Martin–Steel 定理。
本章没有形式化实数集、投影层级、无限博弈或齐次树测度。
七通道源码也没有表示任何武丁基数。
这一边界对理解代码和原书都同样重要。

## 21. 有限机器模型：策略到底选择什么

第 \(k\) 步把当前节点记为 \(M_k\)，其中 \(0\le k<6\)。
策略选择一个目标 \(p\)，新节点 \(M_{k+1}\) 就记录父节点 \(p\)。
合法目标必须满足 \(p\le k\)，并通过本章给定的有限吻合表。
吻合表只允许 \(p=c(k)\)，其中
\[
c(0)=0,\qquad c(k)=k-1\quad(k>0).
\]
因此六个目标依次是
\[
[0,0,1,2,3,4].
\]
这正好恢复第 118 章的交错链父表。
第一个张子作用于根，第二个也作用于根，第三个作用于 \(M_1\)，依此类推。
程序中的 `cStrategy`、`c_strategy` 和 `cStrategy(k)` 都是这个有限函数。
它们只返回数字目标，不返回真实张子。

## 22. 三种运行结果

有限运行器同时接收策略和燃料。
若燃料耗尽而尚未到第六步，结果为 `outOfFuel` 或 `out_of_fuel`。
若已经到第六步，结果为 `done`。
若策略在某步给出不合法目标，结果为 `illegal`。
这三种结果不能合并成简单的真假值。
短燃料不是策略错误，非法目标也不是正常运行完成。
`runWith cStrategy 6 0` 正常完成。
`runWith cStrategy 5 0` 在第五步之前耗尽燃料。
恒返回 \(6\) 的坏策略在第零步就违反 \(p\le k\)，所以被拒绝。
Lean、Coq 和 Agda 的递归都直接消耗燃料。
Agda 因而由结构递归保证总函数性，六步等式则给出具体终止证书。

## 23. 为什么穷举 \(7^6\) 个策略表

只测试一个好策略和一个坏策略，不能排除其他六步表意外完成。
所以 Julia 和 Python 各自枚举每个位置取 \(0,\ldots,6\) 的所有策略表。
表的总数是
\[
7^6=117649.
\]
在每个位置，吻合表只允许唯一目标。
因此完整运行到 `done` 的表必须逐项等于 \((0,0,1,2,3,4)\)。
两个实现都独立算出完整策略数恰为 \(1\)。
Julia 用显式循环推进状态。
Python 用递归调用推进状态，并用元组保存历史。
它们不互相调用，也不共享枚举结果。
这个对拍只覆盖有限策略表，不覆盖依赖无限历史的策略。

## 24. 坏枝搜索与有限选枝

Prolog 额外保存 Even 枝的三段下降样本。
每段都检查玩具嵌入后的值满足 \(j(s)=s+1>t\)。
`bad_branch(B)` 因而能搜索出 `B=even`。
另一个有限证书谓词把 Odd 标为良枝，`select_good_branch` 返回 Odd。
这里的“坏枝”只是第 118 章有限算术证书的简称。
它并不直接构造真实 Even 直接极限。
Even 无秩的数学理由仍是第 16 节的原书无限递降论证。
Prolog 的搜索只是把已有证书组织成可查询形式。
这样可以清楚地区分原书定理、有限证书和系统选枝三个层次。

## 25. Lean：可判定合法性与递归运行器

Lean 文件先定义三构造子的 `Result`。
`LegalTarget` 使用 `abbrev` 展开为可判定命题，使运行器和 `by decide` 都能直接计算。
`runWith` 的递归参数是燃料，每次合法移动都将 `fuel + 1` 改为 `fuel`。
四个定理分别检查父表、正常完成、短燃料和坏目标。
最后的全称命题检查六个预定目标全部合法。
这些证明都是有限计算，不依赖 mathlib，也不引入任何集合论公理。

```lean
/- 第 119 章：有限目标选择策略与燃料终止证书。
   这里只检查六步数字表，不构造真实模型、超幂或无限迭代策略。 -/
inductive Result where
  | done | outOfFuel | illegal
  deriving DecidableEq, Repr

open Result

def cStrategy : Nat → Nat
  | 0 => 0
  | k + 1 => k

abbrev LegalTarget (k p : Nat) : Prop := p ≤ k ∧ p = cStrategy k

def runWith (strategy : Nat → Nat) : Nat → Nat → Result
  | 0, k => if 6 ≤ k then .done else .outOfFuel
  | fuel + 1, k =>
      if 6 ≤ k then .done
      else if LegalTarget k (strategy k) then runWith strategy fuel (k + 1)
      else .illegal

def badStrategy (_ : Nat) : Nat := 6

def scheduled : List Nat := (List.range 6).map cStrategy

theorem scheduled_is_alternating_chain :
    scheduled = [0, 0, 1, 2, 3, 4] := by decide

theorem comparison_terminates : runWith cStrategy 6 0 = done := by decide

theorem short_budget_is_detected : runWith cStrategy 5 0 = outOfFuel := by decide

theorem bad_target_is_detected : runWith badStrategy 6 0 = illegal := by decide

theorem every_scheduled_target_is_legal :
    ∀ k < 6, LegalTarget k (cStrategy k) := by decide
```

上面的 `comparison_terminates` 只说明这个具体递归在六步后返回 `done`。
它没有证明“对任意策略都有良枝”，因为坏策略本来就会返回 `illegal`。
这一区别正是本章反复强调的可迭代性边界。

## 26. Coq：同一证书的布尔检查

Coq 用两个布尔条件拼接 `legal_target`。
第一个条件检查 `p <=? k`，第二个检查目标是否等于 `c_strategy k`。
`run_with` 对 `fuel` 做结构递归。
六个目标的检查写成对 `k` 的有限分情况，超出范围由 `lia` 排除。
所有运行等式都可由 `reflexivity` 直接求得。

```coq
Require Import List Lia.
Import ListNotations.

(* 第 119 章：有限策略表。done 不是大基数可迭代性定理。 *)
Inductive result : Type := Done | OutOfFuel | Illegal.

Definition c_strategy (k : nat) : nat :=
  match k with 0 => 0 | S q => q end.

Definition bad_strategy (_ : nat) : nat := 6.

Definition legal_target (k p : nat) : bool :=
  Nat.leb p k && Nat.eqb p (c_strategy k).

Fixpoint run_with (strategy : nat -> nat) (fuel k : nat) : result :=
  match fuel with
  | 0 => if Nat.leb 6 k then Done else OutOfFuel
  | S f =>
      if Nat.leb 6 k then Done
      else if legal_target k (strategy k)
           then run_with strategy f (S k)
           else Illegal
  end.

Definition scheduled : list nat := map c_strategy (seq 0 6).

Lemma scheduled_is_alternating_chain :
  scheduled = [0;0;1;2;3;4].
Proof. reflexivity. Qed.

Lemma comparison_terminates : run_with c_strategy 6 0 = Done.
Proof. reflexivity. Qed.

Lemma short_budget_is_detected : run_with c_strategy 5 0 = OutOfFuel.
Proof. reflexivity. Qed.

Lemma bad_target_is_detected : run_with bad_strategy 6 0 = Illegal.
Proof. reflexivity. Qed.

Lemma every_scheduled_target_is_legal :
  forall k, k < 6 -> legal_target k (c_strategy k) = true.
Proof.
  intros k H.
  destruct k as [|[|[|[|[|[|k]]]]]]; try reflexivity; lia.
Qed.
```

Coq 的 `Done` 只是枚举类型的一个构造子。
它没有附带真实模型或直接极限，所以不能被读成一般比较终止定理。
真正的数学结论是：这张有限表中的非法选择会被确定地拒绝。

## 27. Agda：结构递归给出总运行器

Agda 版本把递归结构写得最直接。
`run-with strategy zero k` 在尚未到终点时返回燃料耗尽，在已经到第六步时返回完成。
在 `suc fuel` 分支中，下一次递归只能使用 `fuel`。
因此类型检查器接受它是总函数，不需要额外的终止度量。
`comparison-terminates` 再由 `refl` 验证六燃料恰好走到完成状态。

```agda
module Ch119_itertree2 where

open import Data.Nat using (ℕ; zero; suc; _<ᵇ_; _≡ᵇ_)
open import Data.Bool using (if_then_else_; _∧_)
open import Data.List using (List; []; _∷_; map)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 有限数字策略；Agda 只验证六步燃料证书，不验证一般可迭代性。
data Result : Set where done out-of-fuel illegal : Result

c-strategy : ℕ → ℕ
c-strategy zero = 0
c-strategy (suc k) = k

bad-strategy : ℕ → ℕ
bad-strategy _ = 6

legal-target : ℕ → ℕ → Data.Bool.Bool
legal-target k p = (p <ᵇ suc k) ∧ (p ≡ᵇ c-strategy k)

-- 递归参数是 fuel；每次合法移动都严格消耗一份燃料。
run-with : (ℕ → ℕ) → ℕ → ℕ → Result
run-with strategy zero k = if 5 <ᵇ k then done else out-of-fuel
run-with strategy (suc fuel) k =
  if 5 <ᵇ k then done
  else if legal-target k (strategy k)
       then run-with strategy fuel (suc k)
       else illegal

scheduled : List ℕ
scheduled = map c-strategy (0 ∷ 1 ∷ 2 ∷ 3 ∷ 4 ∷ 5 ∷ [])

scheduled-is-alternating-chain : scheduled ≡ (0 ∷ 0 ∷ 1 ∷ 2 ∷ 3 ∷ 4 ∷ [])
scheduled-is-alternating-chain = refl

comparison-terminates : run-with c-strategy 6 0 ≡ done
comparison-terminates = refl

short-budget-is-detected : run-with c-strategy 5 0 ≡ out-of-fuel
short-budget-is-detected = refl

bad-target-is-detected : run-with bad-strategy 6 0 ≡ illegal
bad-target-is-detected = refl
```

这里不能只用 `5 <ᵇ k` 判断真实迭代是否终止。
它只是数字标签达到 \(6\) 的测试。
Agda 证明的是有限程序总能给出三种结果之一，而不是无限比较过程必在有限步结束。

## 28. Isabelle/ZF：父表与长度证书

Isabelle 文件把 `cStrategy` 写成有限条件函数。
`scheduled` 逐项应用该函数，得到与 Lean、Coq、Agda 相同的六项目标表。
`comparison_terminates` 检查表长为 \(6\)，并检查终点标签为 `Finished`。
六条 `legal_e0` 至 `legal_e5` 分别验证目标合法。
这避免了在 ZF 会话中为一个小例子引入复杂的自然数递归函数定义。

```isabelle
theory Itertree2 imports "ZF.List" "ZF.equalities" begin

text \<open>第 119 章：六步目标选择策略与有限终止证书。\<close>
definition N1 where "N1 \<equiv> 1"
definition N2 where "N2 \<equiv> 2"
definition N3 where "N3 \<equiv> succ(2)"
definition N4 where "N4 \<equiv> succ(N3)"
definition N5 where "N5 \<equiv> succ(N4)"
definition N6 where "N6 \<equiv> succ(N5)"

definition cStrategy where
  "cStrategy(k) \<equiv> (if k = 0 then 0 else if k = 1 then 0 else
    if k = 2 then 1 else if k = N3 then 2 else
    if k = N4 then N3 else N4)"

definition LegalTarget where
  "LegalTarget(k,p) \<equiv> p \<le> k \<and> p = cStrategy(k)"

definition scheduled where
  "scheduled \<equiv> [cStrategy(0),cStrategy(1),cStrategy(2),
    cStrategy(N3),cStrategy(N4),cStrategy(N5)]"

definition Finished where "Finished(k) \<equiv> k = N6"

lemma scheduled_targets:
  "scheduled = [0,0,1,2,N3,N4]"
  by (simp add: scheduled_def cStrategy_def N3_def N4_def N5_def)

lemma comparison_terminates:
  "length(scheduled) = N6 \<and> Finished(N6)"
  by (simp add: scheduled_targets Finished_def N6_def N5_def N4_def N3_def)

lemma legal_e0: "LegalTarget(0,cStrategy(0))"
  by (simp add: LegalTarget_def cStrategy_def)
lemma legal_e1: "LegalTarget(1,cStrategy(1))"
  by (simp add: LegalTarget_def cStrategy_def N1_def)
lemma legal_e2: "LegalTarget(2,cStrategy(2))"
  by (simp add: LegalTarget_def cStrategy_def N2_def)
lemma legal_e3: "LegalTarget(N3,cStrategy(N3))"
  by (simp add: LegalTarget_def cStrategy_def N3_def)
lemma legal_e4: "LegalTarget(N4,cStrategy(N4))"
  by (simp add: LegalTarget_def cStrategy_def N3_def N4_def)
lemma legal_e5: "LegalTarget(N5,cStrategy(N5))"
  by (simp add: LegalTarget_def cStrategy_def N3_def N4_def N5_def)

end
```

ZF 自然数在这里仍只是标签。
`length(scheduled)=N6` 不表示真实迭代树的高度被证明为某个集合论序数。
它是一个明确的有限列表等式，与原书无限构造分开记账。

## 29. Julia：循环实现与全表枚举

Julia 的 `choice` 对函数策略和表策略分别取值。
表策略索引写成 `k + 1`，因为数学步骤从 \(0\) 开始，而 Julia 数组从 \(1\) 开始。
`run_with` 用 `while true` 循环，但三个返回分支都严格受燃料和步骤界控制。
随后 `Iterators.product` 生成全部六步策略表。
只有目标表完全等于 `C_PARENTS` 时才增加完成计数。

```julia
# 第 119 章：有限目标选择策略；不是无限迭代树的可迭代性证明。
c_strategy(k) = k == 0 ? 0 : k - 1
bad_strategy(_) = 6
legal_target(k, p) = 0 <= p <= k && p == c_strategy(k)

# 函数与六步策略表统一分派；策略表使用 Julia 的 1 基索引。
choice(strategy, k) = strategy isa Function ? strategy(k) : strategy[k + 1]

function run_with(strategy, fuel)
    parents = Int[]
    k = 0
    while true
        k >= 6 && return (:done, Tuple(parents))
        fuel == 0 && return (:out_of_fuel, Tuple(parents))
        p = choice(strategy, k)
        legal_target(k, p) || return (:illegal, Tuple(parents))
        push!(parents, p)
        k += 1
        fuel -= 1
    end
end

const C_PARENTS = (0, 0, 1, 2, 3, 4)
@assert run_with(c_strategy, 6) == (:done, C_PARENTS)
@assert run_with(c_strategy, 5)[1] == :out_of_fuel
@assert run_with(bad_strategy, 6)[1] == :illegal

# 穷举 7^6 个策略表；吻合表恰允许唯一的完整六步策略。
function count_complete_strategies()
    total = 0
    done_count = 0
    for table in Iterators.product(ntuple(_ -> 0:6, 6)...)
        status, parents = run_with(table, 6)
        total += 1
        if status == :done
            done_count += 1
            @assert parents == C_PARENTS
        end
    end
    return total, done_count
end

total, done_count = count_complete_strategies()
@assert total == 7^6
@assert done_count == 1

# 有限二选一证书：存在良枝不等于已有跨所有树的系统选枝策略。
good = Dict(:even => false, :odd => true)
exists_good = any(values(good))
selected = Symbol[]
for branch in (:even, :odd)
    good[branch] && push!(selected, branch)
end
@assert exists_good
@assert selected == [:odd]

println("==== 119")
println("六步策略完成；短燃料与非法目标均被拒绝")
println("穷举策略表=", total, "；完整策略数=", done_count)
println("有限存在见证与选枝函数均选 Odd；不声称一般可迭代性")
println("END ====")
```

最后的 `good` 字典是有限良枝证书表。
`any(values(good))` 表达“存在良证书”，`selected` 表达“把良证书列出”。
两者在这个例子中同时成立，却不能据此推出它们在任意无限树中等价。

## 30. Python：独立递归对拍

Python 不调用 Julia 的结果，而是重新实现运行器。
函数策略通过 `callable` 识别，表策略直接按下标读取。
每进行一次合法移动，递归参数 `fuel - 1` 减小，历史元组增加一个目标。
`product(range(7), repeat=6)` 独立生成相同的 \(117649\) 个表。
断言要求完成表列表恰为 `[C_PARENTS]`，比只检查计数更强。

```python
# 第 119 章：独立递归实现有限策略，并穷举策略表对拍。
from itertools import product


def c_strategy(k):
    return 0 if k == 0 else k - 1


def bad_strategy(_k):
    return 6


def legal_target(k, p):
    return 0 <= p <= k and p == c_strategy(k)


def run_with(strategy, fuel, k=0, parents=()):
    """递归消耗燃料；表策略和函数策略走不同取值接口。"""
    if k >= 6:
        return "done", parents
    if fuel == 0:
        return "out_of_fuel", parents
    p = strategy(k) if callable(strategy) else strategy[k]
    if not legal_target(k, p):
        return "illegal", parents
    return run_with(strategy, fuel - 1, k + 1, parents + (p,))


C_PARENTS = (0, 0, 1, 2, 3, 4)
assert run_with(c_strategy, 6) == ("done", C_PARENTS)
assert run_with(c_strategy, 5)[0] == "out_of_fuel"
assert run_with(bad_strategy, 6)[0] == "illegal"

total = 0
done_tables = []
for table in product(range(7), repeat=6):
    status, parents = run_with(table, 6)
    total += 1
    if status == "done":
        done_tables.append(parents)
assert total == 7**6
assert done_tables == [C_PARENTS]

# 这只是两根已给证书之间的选择，不是适用于每棵无限树的策略。
good = {"even": False, "odd": True}
exists_good = any(good.values())
selected = [branch for branch in ("even", "odd") if good[branch]]
assert exists_good
assert selected == ["odd"]

print("==== 119")
print("六步策略完成；短燃料与非法目标均被拒绝")
print(f"穷举策略表={total}；完整策略={done_tables}")
print("有限存在见证与选枝函数均选 Odd；不声称一般可迭代性")
print("END ====")
```

由于 Python 使用递归而 Julia 使用循环，两边对状态推进的实现路径不同。
相同的唯一完成结果构成有意义的有限对拍。
它仍不覆盖可依赖任意长历史的策略空间。

## 31. Prolog：搜索坏枝与拒绝坏目标

Prolog 的 `run/5` 把状态写成关系。
燃料为零、已经到第六步、合法前进一步和非法目标分别占不同子句。
主测试要求正常策略得到精确父表，短燃料和坏策略得到各自状态。
`bad_branch` 对 Even 的三段下降事实做全称检查。
`select_good_branch` 则查询有限的 Odd 良证书。

```prolog
:- encoding(utf8).
% 第 119 章：有限策略、坏目标搜索与有限良枝证书。
c_strategy(0,0).
c_strategy(K,P) :- K > 0, P is K-1.
bad_strategy(_,6).

legal_target(K,P) :- K < 6, P >= 0, P =< K, c_strategy(K,P).

% run(Strategy,Fuel,K,Parents,Status)：Parents 按时间正序累积。
run(_,0,K,[],done) :- K >= 6.
run(_,0,K,[],out_of_fuel) :- K < 6.
run(Strategy,Fuel,K,Parents,Status) :-
    Fuel > 0, K >= 6, Parents = [], Status = done.
run(Strategy,Fuel,K,[P|Rest],Status) :-
    Fuel > 0, K < 6,
    ( Strategy = c -> c_strategy(K,P) ; bad_strategy(K,P) ),
    legal_target(K,P),
    F1 is Fuel-1, K1 is K+1,
    run(Strategy,F1,K1,Rest,Status).
run(Strategy,Fuel,K,[],illegal) :-
    Fuel > 0, K < 6,
    ( Strategy = c -> c_strategy(K,P) ; bad_strategy(K,P) ),
    \+ legal_target(K,P).

% Even 的有限坏证书逐项下降；Odd 在此有限证书表中为良枝。
bad_step(even,(0,2,5,4)).
bad_step(even,(2,4,4,3)).
bad_step(even,(4,6,3,2)).
descending_step(S,T) :- J is S+1, J > T.
bad_branch(B) :-
    B = even,
    forall(bad_step(B,(_,_,S,T)),descending_step(S,T)).
good_branch(odd).
select_good_branch(B) :- good_branch(B).

must(G) :- (G -> true ; throw(verification_failed(G))).
main :-
    format('==== 119~n'),
    must(run(c,6,0,Parents,done)), must(Parents == [0,0,1,2,3,4]),
    must(run(c,5,0,_,out_of_fuel)),
    must(run(bad,6,0,_,illegal)),
    must(bad_branch(Bad)), must(Bad == even),
    must(select_good_branch(Good)), must(Good == odd),
    format('六步策略完成；短燃料与非法目标均被拒绝~n'),
    format('坏枝搜索=~w；有限选枝证书=~w~n',[Bad,Good]),
    format('END ====~n').
```

Prolog 的否定只用于当前有限 `legal_target` 关系的失败检查。
它不是对无限数学对象做封闭世界否定。
`bad_branch(even)` 也只是有限证书查询，不替代第 16 节的序数论证。

## 32. 七通道共同验证清单

四种证明通道共同检查预定目标表和有限终止行为。
Lean、Coq、Agda 还直接运行正常、短燃料和坏策略。
Agda 的运行器由燃料上的结构递归保证终止。
Isabelle 用六项目标表、表长和六个合法目标引理给出同型证书。
Julia 与 Python 独立穷举策略表，并确认唯一完整策略。
Prolog 搜索有限坏枝证书，同时验证三种运行状态。
七份源码全部逐字嵌入本章，便于读者从正文直接复查。
这些测试彼此补充，但没有一个测试跨越有限模型的边界。

## 33. 本章结论与下一章接口

原书主线从保持谓词作用推进到保持型，再推进到单步引理。
有限交错链由反复应用单步引理得到。
无限交错链则需要无差别元来避免参数无限下降。
最终的 Even 枝无秩性来自沿该枝运输后的严格递降序数序列。
策略主线则必须把单树存在性与跨树统一选择分开。
本章的有限程序只验证后一区别所需的最小目标选择机制。
它没有证明一般比较终止、一般可迭代性或武丁表示定理。
下一章将从投影集合稳赢性继续，把这些迭代树接口用于实数集表示问题。

[上一章：迭代树 I](118-itertree1.md) · [目录](../README.md) · [下一章：投影集合稳赢性 I](120-pd1.md)
