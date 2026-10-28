# 第 94 章 · 可测基数、正规超滤子与超幂

> 对应原书：冯琦《集合论导引（第三卷）高阶无穷》第 1 章 §1.1 中可测基数、超幂与初等嵌入部分。
> 前置：[第 7 章 滤子与理想](07-filters.md)、[第 28 章 大基数与超幂](28-measurable.md)、[第 89 章 内模型](89-innermodel.md)、[第 93 章 高阶无穷导引](93-higherinfinity.md)。
> 本章在 ZFC 中工作。有限超滤实验只解释有限幂集代数与主超幂的退化，不证明任何大基数存在命题。

## 94.1 从超滤子到可测基数

先固定一个集合 X。

X 上的一个滤子 U 是幂集 P(X) 的非空子族，并满足以下条件。

1. 空集不属于 U。
2. 若 A、B 属于 U，则 A∩B 属于 U。
3. 若 A 属于 U 且 A⊆B⊆X，则 B 属于 U。

把 A 属于 U 读作“A 很大”，这三条规则就很自然。

两个大集合的公共部分仍大。

包含大集合的集合仍大。

空集不能大。

由有限交封闭性与非空性可知 X 本身属于 U。

超滤子再增加一条二分性。

对任意 A⊆X，A 与 X−A 恰有一个属于 U。

“恰有一个”中的不能同时成立，已经由空集不属于 U 以及交封闭性保证。

因此，超滤子给每个子集作出非此即彼的“大或小”判断。

若 a∈X，定义

  U_a = {A⊆X : a∈A}。

这就是由 a 生成的主超滤子。

它把“大”完全等同于“含有焦点 a”。

主超滤子在有限与无限集合上都存在，却并不提供可测基数所要求的新无穷强度。

可测基数的定义要求排除这种退化情形。

定义中的非平凡性写作

  [κ]^{<κ} ∩ U = ∅。

也就是说，κ 的任何势小于 κ 的子集都不测一。

特别地，所有单点集和它们的补集行为都不会像主超滤子那样。

κ-完全性说：若 γ<κ，且 A_α∈U（α<γ），则

  ⋂_{α<γ} A_α ∈ U。

有限交封闭被提升为少于 κ 个集合的交封闭。

这里的长度 γ 必须严格小于 κ，不能把定义偷换成任意交封闭。

正规性使用选择函数语言。

设 A∈U，函数 f 在 A 上满足 f(α)<α。

这样的 f 称为 A 上的选择函数，也叫回归函数。

正规性要求存在 B∈U，使 B⊆A 且 f 在 B 上为常值。

换言之，在一个测一集合上逐点向下的选择，必能在一个测一子集上压成同一个值。

现在给出核心定义。

基数 κ 是可测基数，当且仅当 κ 上存在非平凡、κ-完全的正规超滤子。

这样的超滤子也称为 κ 上的正规测度。

这里的“测度”是二值的：集合或者测一，或者测零。

它不是取实数值的测度，也不要求可数可加性以实数加法来表达。

本章后面将看到，非平凡性与 κ-完全性已经足以推出正规测度的存在。

所以“正规”主要是给出一个特别好用的代表，而不是增加可测性的存在强度。

## 94.2 可测基数必为不可达基数

第一个目标是证明：可测 κ 不可数、正则而且是强极限基数。

先看不可数性。

若 κ=ω，非平凡性使尾段 A=ω−{0} 测一。

在 A 上定义 f(n+1)=n。

这是选择函数。

若正规性给出常值 γ，则相应测一集合只能是单点集 {γ+1}。

但单点集不能测一，矛盾。

这个论证也提示了一条更一般的事实。

对可测 κ 的正规测度 U，所有后继序数组成的集合不测一。

因为在前驱函数 α+1↦α 上若测一常值化，就会再次得到单点集。

再证正则性。

反设 κ 奇异。

取 γ=cf(κ)<κ，并把 κ 写成

  κ = ⋃_{ξ<γ} A_ξ，

其中每个 |A_ξ|<κ。

非平凡性给出 κ−A_ξ∈U。

γ<κ，所以 κ-完全性给出

  ⋂_{ξ<γ}(κ−A_ξ) ∈ U。

可是这个交集是空集。

这与滤子的第一条公理矛盾。

因此 κ 必须正则。

最后证强极限性。

取无穷基数 λ<κ，反设 2^λ≥κ。

选取 X⊆{}^λ{0,1}，使 |X|=κ。

用一个双射把 κ 上的超滤子搬运到 X 上。

搬运后的超滤子仍是 κ-完全且非平凡的。

对每个 ξ<λ，把 X 按第 ξ 个坐标分成两部分：

  X_ξ^0 = {f∈X : f(ξ)=0}，

  X_ξ^1 = {f∈X : f(ξ)=1}。

超滤二分性为每个 ξ 选出唯一 ε(ξ)∈{0,1}，使 X_ξ^{ε(ξ)} 测一。

因为 λ<κ，交集

  Y = ⋂_{ξ<λ} X_ξ^{ε(ξ)}

仍测一。

若 f∈Y，则对每个 ξ<λ 都有 f(ξ)=ε(ξ)。

所以 Y 至多含一个函数。

这与非平凡性矛盾。

故对一切 λ<κ 都有 2^λ<κ。

不可数、正则、强极限三项合起来，正是不可达基数。

这也解释了可测性为什么远超“一个很大的基数”的口号。

它自动携带着 κ-完全超滤子的组合闭包，并由此强迫整个幂集层级在 κ 以下保持低势。

## 94.3 正规测度看到下方的不可达基数

定理不仅说 κ 自己不可达。

若 U 是 κ 上的正规测度，则

  {λ<κ : λ 是不可达基数} ∈ U。

证明分四层筛去不测一的例外集合。

每一层都使用同一个策略。

若例外集测一，就在它上面定义一个回归函数。

正规性把回归函数压成常值。

κ-完全性与非平凡性随后把“常值”变成“测一集合有界”或“测一集合是单点集”，从而矛盾。

第一层，证明下方基数集合 A_0 测一。

若不然，则非基数集合 B 测一。

对 α∈B 定义 g(α)=|α|。

因为 α 不是基数，所以 |α|<α。

若 g 在 B_0∈U 上恒等于 λ，则 B_0 中所有 α 的势都是 λ。

这样的 α 全部小于 λ^+<κ，故 B_0 有界。

而非平凡 κ-完全超滤子中的集合不能有界。

否则，把它的每个点补集相交，就会得到空集测一。

第二层，在 A_0 中筛出正则基数 A_1。

若奇异基数例外集测一，令 g(α)=cf(α)<α。

正规性给出 B_1∈U 和固定 λ，使每个 α∈B_1 都有 cf(α)=λ。

对每个 α，固定一条长度为 λ、递增且收敛于 α 的序列 ⟨α_ξ:ξ<λ⟩。

固定 ξ<λ，函数 h_ξ(α)=α_ξ 仍是回归函数。

正规性给出 C_ξ∈U，使 h_ξ 在 C_ξ 上恒等于 η_ξ。

由 λ<κ，集合 C=⋂_{ξ<λ}C_ξ 仍测一。

但在 C 上，每个 α 都是同一组 η_ξ 的上确界。

因此 C 至多含一个 α，仍与非平凡性矛盾。

第三层，在正则基数中筛出正则极限基数 A_2。

若例外集测一，其中每个 α 都是后继基数。

令 g(α) 为 α 的基数前驱，则 g(α)<α。

若 g 在某个测一 B_1 上恒等于 λ，那么 B_1 中每个 α 都等于 λ^+。

B_1 又成为单点集，矛盾。

第四层，在正则极限基数中筛出强极限基数 A_3。

若例外集测一，则对每个其中的 α，存在 λ<α 使 2^λ≥α。

令 g(α) 取最小的这种 λ。

正规性把 g 常值化为某个 λ。

于是相应测一集合中的 α 全部满足 α≤2^λ。

这个集合有界，矛盾。

四层交集都属于 U，所以所求集合测一。

这个结论有一致性强度上的直接后果。

V_κ 不仅给出 ZFC 的模型，还能在 κ 下方找到无界多个不可达基数。

因此，可测基数假设足以保证“ZFC＋存在无界多个不可达基数”的相容性。

这句话仍以可测基数假设为前提，绝不是无条件的相容性证明。

## 94.4 正规测度包含所有无界闭集

正规性还有一条常用的几何后果。

若 C⊆κ 是无界闭集，则 C∈U。

这里 U 仍是 κ 上的非平凡正规测度。

先注意极限序数集合测一，因为后继序数集合被前驱回归函数排除。

反设 C 不测一。

删去 C 的最小元以下的无害部分后，可以在一个测一集合 T 上考虑大于 min(C) 的极限序数 α。

若 α∈T 且 α∉C，则 C∩α 是有界闭集。

它有最大元，定义

  f(α)=max(C∩α)<α。

正规性给出 T_0∈U，使 f 在 T_0 上恒等于 γ。

因为 T_0 无界而 C 也无界，可以取 β∈C 与 α∈T_0，使 γ<β<α。

但 f(α)=γ 是 C∩α 的最大元，不可能再有 β∈C∩α 大于 γ。

矛盾，所以每个无界闭集都测一。

两个测一集合的交仍测一，因而正规测度中的每个集合都与每个无界闭集相交。

这正是荟萃性。

所以正规测度中的集合全是 κ 的荟萃子集。

反命题不成立：荟萃集合很多，并不因此自动属于某个指定测度。

## 94.5 完全超滤子的正规化

定义可测性时要求正规性，并非遗漏了一种更弱的“完全但不可正规化”情形。

定理说：若 κ>ω 上存在非平凡 κ-完全超滤子 V，则 κ 上存在非平凡 κ-完全正规超滤子 U。

证明的钥匙已经是超幂语言。

令 X={}^κκ。

对 f,g∈X 定义

  f=_V g ⇔ {α<κ:f(α)=g(α)}∈V，

  [f]∈_V[g] ⇔ {α<κ:f(α)∈g(α)}∈V。

由于这里坐标值都是序数，∈_V 是一个线性次序。

κ-完全性排除长度为 ω 的无穷下降链。

若 [f_{n+1}]∈_V[f_n] 对一切 n 成立，把各个测一见证集相交。

可数交集仍测一，任取其中一个坐标就得到序数的无穷 ∈-下降链，矛盾。

所以这个次序是良序。

令 π 把它坍缩为序数，并取满足 π([h])=κ 的函数 h:κ→κ。

然后定义

  U = {A⊆κ : h^{-1}[A]∈V}。

逆像保持交、并、补与包含，因此 U 继承超滤子公理。

少于 κ 个逆像的交，就是交集的逆像，所以 U 继承 κ-完全性。
这里实际使用的等式是

  h^{-1}[⋂_{α<γ}A_α] = ⋂_{α<γ}h^{-1}[A_α]。

校勘说明：原书第 8 页“断言四”对应行印成并集的包含式；逆像保持并当然不错，但那一步不能证明这里所需的交封闭。
本文按 κ-完全性的证明目标使用上述交集等式，而不是把 OCR 或原页符号直接照抄。

证明 π([h])=κ 的关键，是先确认良序中确有第 κ 层，而不是预设恒等函数一定落在这一层。

对每个 β<κ，令常值函数 c_β(ξ)=β。

非平凡性保证任意两个不同常值函数只在一个小于 κ 的坐标集上一致，所以它们代表不同的等价类。

这些常值类还构成良序的初始段。

若 [f]∈_V[c_β]，就在一个 V-测一集合上有 f(ξ)<β；把它按函数值分成 β 个纤维。

因为 β<κ，V 的 κ-完全性迫使某个纤维属于 V，所以 f 与某个 c_γ 在 V-测一集合上相等。

对 β 作归纳便得 π([c_β])=β。

于是这个良序至少有 κ 个元素，其序型大于或等于 κ；坍缩映射 π 的值域因此包含 κ。

取任意满足 π([h])=κ 的函数 h:κ→κ。

若 [g]∈_V[h]，则 π([g])=β<κ。

坍缩在第 κ 层以下的逆像正是常值函数的等价类，所以 [g]=[c_β]。

也就是说，h 是模 V 意义下第一个位于所有常值函数之后的函数。

h 的非平凡性可以直接验证。

若某个 A⊆κ 满足 |A|<κ 而 h^{-1}[A]∈V，就把这个原像分成 |A| 个常值纤维。

由 V 的 κ-完全性，至少一个纤维属于 V，这与 h 在 V-测一集合上不等于任何常值函数矛盾。

因此小于 κ 的集合经 h 取逆像后都不属于 V，故所得 U 非平凡。

最后验证正规性。

设 A∈U，f:A→κ 满足 f(α)<α。

在 h 的相应原像上令 g=f∘h。

则 [g]∈_V[h]。

由于 π([h])=κ，[g] 下方对应某个 β<κ，使 g 在 V-测一集合上恒等于 β。

把这个集合经 h 推回，就得到 f 在 U-测一集合上恒等于 β。

因此 U 正规。

这个正规化定理也解释了后文为什么总可以直接取正规测度。

正规性让恒等函数 id(α)=α 成为 κ 的最自然代表。

## 94.6 超幂：把函数按测一一致关系商掉

现在把构造从序数值函数推广到整个集合宇宙。

给定 κ 上的超滤子 U，考虑所有定义域为 κ 的函数。

对 f,g 定义

  f=_U g ⇔ {α<κ:f(α)=g(α)}∈U，

  [f]∈_U[g] ⇔ {α<κ:f(α)∈g(α)}∈U。

所得结构记作 Ult(V,U)。

每个 [f] 可直观理解为“U-几乎处处由 f 给出的对象”。

常值函数 c_a(α)=a 给出原对象 a 的自然副本。

非恒等函数则可能给出新对象。

例如正规测度下的恒等函数 id 将在坍缩后表示 κ 自己。

在整个 V 上直接取等价类有一个集合论技术问题。

与 f 等价的所有函数可能构成真类，而不是集合。

解决办法是 Scott trick。

对给定 f，只保留所有与 f 等价且秩最小的函数。

固定 f 后，这个秩界确保这些代表落在一个 V_α 中，因此构成集合。

这些最小秩代表组成的集合仍记作 [f]。

定义有意不保证 f 自己一定属于 [f]，但这没有关系。

真正需要的是：

  f=_U g ⇔ [f]=[g]。

若 f=_U g，最小秩条件与等价关系传递性给出相同的代表集合。

反过来，若两个最小秩代表集合相等，取其中一个公共代表，就由等价关系传递性得到 f=_U g。

成员关系也与代表选择无关。

若 f_1=_U f_2、g_1=_U g_2，把两个等式见证集与 f_1(α)∈g_1(α) 的见证集相交。

交集中的坐标直接见证 f_2(α)∈g_2(α)。

向上封闭便给出同一成员判定。

所以商结构的相等与成员关系都定义良好。

## 94.7 Łoś 超幂基本定理

Łoś 定理把商结构中的真值完全还原为坐标上的测一真值。

对集合论语言的任意公式 φ(v_1,…,v_n)，以及任意函数 f_1,…,f_n，有

  Ult(V,U) ⊨ φ([f_1],…,[f_n])

当且仅当

  {α<κ : V⊨φ(f_1(α),…,f_n(α))}∈U。

证明按公式复杂度归纳。

原子公式 x=y 与 x∈y 就是商结构的定义。

否定步使用超滤二分性。

若坐标真集不测一，它的补集便测一，而补集正是否定公式的坐标真集。

合取步使用交封闭与向上封闭。

析取步先由两个坐标真集之并向上得到析取真集，反向再由二分性把测一的并拆回至少一个测一支。

关键是存在量词步。

若超幂中存在 [g] 使 ψ 成立，归纳假设直接给出一组测一坐标，故 ∃yψ 在这些坐标为真。

反过来，设 A={α:存在 y 使 ψ(f_1(α),…,f_n(α),y)} 属于 U。

对每个 α∈A，选择一个见证 y_α。

在 A 外把 g(α) 定义为任意固定集合。

于是 g:κ→V，并且

  {α:V⊨ψ(f_1(α),…,f_n(α),g(α))}

包含 A，因而测一。

归纳假设给出 [g] 作为超幂中的存在见证。

这里使用了选择原则来同时选取坐标见证。

Łoś 定理不是逐坐标有限验证，而是关于所有一阶公式的严格等价。

它同时解释了超幂为什么保持集合论语句，以及为什么常值函数给出初等嵌入。

## 94.8 良基性、坍缩与自然嵌入

若 U 非平凡且 κ-完全，则商成员关系 ∈_U 良基。

反设有 [f_{n+1}]∈_U[f_n]（n<ω）。

每个关系都有测一见证集 A_n。

因 κ 不可数且 U 是 κ-完全的，⋂_n A_n∈U。

任取该交集中的 α，就得到

  …∈f_2(α)∈f_1(α)∈f_0(α)，

违反集合宇宙的良基性。

商关系还具有外延性。

若 [f] 与 [g] 的 ∈_U-前件完全相同而 f≠_U g，则差异集测一。

可在一个测一部分上选取 h(α)∈f(α)−g(α)，或反向选取。

所得 [h] 就成为两个前件集合的差别，矛盾。

于是可对 (Ult(V,U),∈_U) 作 Mostowski 坍缩。

得到唯一传递内模型 M 与同构 π。

定义自然映射

  j_U:V→M，  j_U(a)=π([c_a])。

由 Łoś 定理，对任意公式 φ 与参数 a_1,…,a_n，

  V⊨φ(a_1,…,a_n)

当且仅当

  M⊨φ(j_U(a_1),…,j_U(a_n))。

因为各常值函数在每个坐标都重复同一个参数，坐标真集不是 κ 就是空集。

所以 j_U 是初等嵌入。

“初等”比“单射且保持 ∈”强得多。

它保持全部一阶可表达性质，包括“是基数”“是可测基数”“是某函数的全域”等经过参数解释后的语句。

## 94.9 正规测度下临界点与恒等函数

现在取 U 为正规测度，并简写 j=j_U。

对每个 α<κ，有 j(α)=α。
固定 β<κ，并考察常值函数 c_β 的超幂前件。
若 [f]∈_U[c_β]，则 A={ξ<κ:f(ξ)<β}∈U。
把 A 按函数值分成 A_γ={ξ∈A:f(ξ)=γ}（γ<β）。
若所有 A_γ 都不测一，则所有补集测一；由于 β<κ，它们的交仍测一，却是空集。
故必有某个 A_γ 测一，从而 [f]=[c_γ]。
因此 [c_β] 下方恰是常值 c_γ（γ<β）所代表的序数。
按 β 归纳，j(β)=β。

而 κ<j(κ)。

因此 κ 是 j 的临界点，记作 crit(j)=κ。

正规性把恒等函数的位置说得非常精确：

  π([id])=κ。

一方面，若 [f]∈_U[id]，则 f(α)<α 在测一集合上成立。

正规性使 f 在某个测一子集上恒等于 β<κ。

故 [id] 的下方恰是各常值 β 所代表的序数，坍缩后就是 κ。

另一方面，每个常值 β<κ 都满足 c_β(α)<id(α) 在无界集上成立，因此 β<π([id])。

同时 id(α)<κ 处处成立，所以 κ∈j(κ)，从而 κ<j(κ)。

恒等函数还给出一个极其方便的测度判据。

对任意 A⊆κ，

  A∈U ⇔ κ∈j(A)。

证明只需展开：

  κ∈j(A)

等价于 [id]∈_U[c_A]，

又等价于 {α<κ:α∈A}=A∈U。

这个等价把“超滤子的外延知识”改写成“初等嵌入在一个新序数处的取值”。

它还是后文从任意初等嵌入反取测度的模板。

正规超幂还有一个标准表示：

  M = {j(f)(κ) : f 是定义域为 κ 的函数}。

事实上，[f]=[c_f]([id]) 的函数求值关系在测一坐标上成立。

坍缩后即为 π([f])=j(f)(κ)。

因此 M 中每个元素都能用 V 中一个函数与特殊点 κ 表示。

这个表示既用于计算势的上界，也用于构造嵌入之间的因子映射。

## 94.10 超幂模型的闭包与全局估计

正规超幂模型 M 对长度为 κ 的序列封闭。

若 ⟨x_α:α<κ⟩ 是 M 中元素的 κ-序列，则这条序列本身属于 M。

证明思路是把每个 x_α 写成某个 [h_α]，再把 h_α 编成一个二层的函数 F。

Łoś 定理把 F 解释为 M 中长度为 j(κ) 的序列。

在 κ 处取这一段，就依次恢复全部 x_α。

这里不能把结论误写为 M 对所有外部长度的序列封闭。

闭包长度与测度的完全性、临界点紧密相关。

同一框架还给出 U∉M。

若 U∈M，则 M 能定义从 {}^κκ 到 j(κ) 的代表求值映射。

在 M 看来，这会把 j(κ) 压成至多 2^κ 的大小。

但初等性使 M 认为 j(κ) 是不可达基数，并且 κ<j(κ)，产生矛盾。

因此测度自身被留在外部。

正规超幂还给出常用估计：

  2^κ ≤ (2^κ)^M < j(κ) < (2^κ)^+。

左边来自 M 的闭包及其幂集计算。

中间严格不等式来自 M 中 j(κ) 的不可达性。

右边来自 M={j(f)(κ):f∈V^κ} 的表示，序数 j(κ) 下方至多由 2^κ 个函数代表。

这些估计表明 j(κ) 很大，却不是任意无法描述的大。

它被原宇宙中的函数数量严格控制。

若 λ 是极限序数，还可按 cf(λ) 与 κ 的关系分析 j(λ)。

当 cf(λ)=κ 时，典型现象是 j(λ)>sup{j(α):α<λ}。

当 cf(λ)≠κ 时，κ-完全性帮助把任意代表 f:κ→λ 压到某个固定 α<λ 以下，于是

  j(λ)=sup{j(α):α<λ}。

特别地，若 λ 是强极限基数且 cf(λ)≠κ，则 j(λ)=λ。

这类不动点计算是后面迭代超幂与内模型分析的基本功。

## 94.11 可测基数带来拉姆齐性质

可测性还有强划分后果。

记号 κ→(κ)^{<ω}_2 表示：任意给 κ 的所有有限子集二染色，都存在势为 κ 的 H⊆κ，使每个固定有限长度的子集在 H 上同色。

不同长度可以对应不同颜色。

具有这一性质的不可数基数称为拉姆齐基数。

可测基数 κ 具有这一性质。

对固定 n，先对 A∈U 上的任意 f:[A]^{n+1}→2，在 U 中寻找齐一测一集。

n=0 时，超滤二分性直接选出颜色测一的一支。

归纳步对每个 α 定义尾部染色 f_α，把 α 加到已经选出的尾部前面。

对各个 f_α 使用归纳假设，再取对角交，使所选尾部与前驱 α 相容。

超滤二分性再统一这些 α 所选择的颜色。

最后把各有限 n 的测一齐一集相交。

因为每个 U-集合都无界且势为 κ，所得 H 仍符合要求。

正规超幂进一步给出：

  {λ<κ : λ 是拉姆齐基数}∈U。

理由是 V_κ 与 M 的适当闭包使 M 能看到同样的有限染色齐一见证，从而 M 认为 κ 是拉姆齐基数。

再用 π([id])=κ 与 Łoś 定理反读到坐标层，就得到上述测一集合。

这条链条示范了超幂证明的典型节奏。

先在外部证明 κ 的某性质。

再确认该性质及其见证对 M 可见。

最后用 Łoś 定理把“M 认为 κ 有性质”翻译成“U-几乎每个 λ 有性质”。

## 94.12 Scott：可测基数存在则 V≠L

Scott 定理的证明现在非常短。

反设 V=L，并且存在可测 κ 及其正规测度 U。

令 j:V→M 为相应超幂嵌入。

M 是传递内模型且与 V 有相同序数。

由 L 的最小性，L⊆M。

但假设 V=L 又给出 M⊆V=L。

所以 M=L=V。

另一方面，上一节证明了 U∉M。

然而 U 是 V 中的一个集合，而 V=M，故 U∈M。

矛盾。

因此，只要存在可测基数，就有 V≠L。

这不是说 L 中完全没有大基数的影子。

κ 在 L 中仍可能保留某些较弱的组合性质。

结论只是：整个真实宇宙 V 不能等于可构造宇宙 L。

也不能把证明缩写为“大基数定义超出 L，所以显然”。

真正不可缺少的是超幂模型的闭包、U∉M 与 L 的最小性。

## 94.13 从初等嵌入反取正规测度

可测性不仅产生初等嵌入，也可以从非平凡初等嵌入的临界点读回。

设 j:V→M 是非平凡初等嵌入，crit(j)=κ。

定义

  D = {A⊆κ : κ∈j(A)}。

D 称为由 j 在 κ 处导出的测度。

先验证它是超滤子。

空集不属于 D，因为 κ∉j(∅)=∅。

全集 κ 属于 D，因为 κ<j(κ)。

若 A,B∈D，则

  κ∈j(A)∩j(B)=j(A∩B)，

所以 A∩B∈D。

若 A∈D 且 A⊆B，则 κ∈j(A)⊆j(B)，所以 B∈D。

对任意 A⊆κ，j(κ−A)=j(κ)−j(A)。

κ∈j(κ) 恰好落在 j(A) 或它的补集之一，因此 D 有二分性。

每个 α<κ 都被 j 固定，所以 κ∉j({α})={α}。

故 D 不含单点集。
若 |A|<κ，取 γ<κ 和从 γ 到 A 的满射 e。
因为 j 固定 γ、每个下标以及 e 的每个值，初等性给出 j(A)=A。
所以 κ∉j(A)，即 A∉D。
因此 D 具有可测定义所要求的非平凡性；这里不会把“非主”误当成已经足够，而是明确排除所有小集。

再验证 κ-完全性。

设 γ<κ，且 A_α∈D（α<γ）。

由于 γ<κ，j 固定长度 γ 及序列各下标。

于是

  j(⋂_{α<γ}A_α)=⋂_{α<γ}j(A_α)。

右边每一项都含 κ，所以交集也属于 D。

最后验证正规性。

设 A∈D，f:A→κ 是选择函数。

初等性使 j(f) 在 j(A) 上仍为选择函数。

因 κ∈j(A)，可令

  β=j(f)(κ)<κ。

定义 B={α∈A:f(α)=β}。

β<κ 被 j 固定，因此 j(B) 正好是 j(A) 中 j(f) 取 β 的点集。

而 κ 正是这样一个点，所以 B∈D。

f 在 B 上恒等于 β，正规性得证。

临界点是基数与正则性的论证也使用初等性。

若 κ 与某个更小序数等势，相应双射的 j-像会迫使 κ 进入原像值域，与 κ<j(κ) 的临界位置矛盾。

若 κ 奇异，一条长度小于 κ 的共尾序列会被 j 固定，却同时被初等性说成在 j(κ) 中共尾，也产生矛盾。

因此，非平凡初等嵌入的临界点必为可测基数。

“可测”与“成为初等嵌入临界点”在这个意义上完全接通。

## 94.14 因子嵌入与交换图

上一节从 j 得到 D 后，还可以用 D 再作超幂。

令 j_D:V→N 为正规超幂嵌入。

定义 k:N→M：

  k(π_D([f]))=j(f)(κ)。

首先，这一定义与代表无关。

若 [f]=[g]，则 {α<κ:f(α)=g(α)}∈D。

按 D 的定义，这等价于 κ∈j({α:f(α)=g(α)})。

也就是 j(f)(κ)=j(g)(κ)。

所以 k 定义良好。

若 a∈V，取常值函数 c_a，则

  k(j_D(a))=k(π_D([c_a]))=j(c_a)(κ)=j(a)。

故有交换关系

  j = k∘j_D。

Łoś 定理还用同一次坐标翻译证明 k 是初等嵌入。

N 中关于 [f_1],…,[f_n] 的公式为真，

当且仅当相应坐标真集属于 D，

当且仅当 M 中关于 j(f_1)(κ),…,j(f_n)(κ) 的公式为真。

这正等于说 k 的像满足原公式。

因此，任何以 κ 为临界点的初等嵌入，都经过一个由导出正规测度作出的超幂嵌入来分解。

这个因子定理把“任意嵌入”与“标准超幂嵌入”连接起来。

它也说明恒等函数代表 κ 并非技术装饰，而是整个交换图运转的轴心。

## 94.15 Kunen：ZFC 中没有非平凡 j:V→V

初等嵌入可以进入真内模型 M，却不能在选择公理下以整个 V 自身为目标。

Kunen 定理断言：若 j:V→M 非平凡初等，则 M≠V。

反设 M=V。

令 κ=crit(j)，递归写 κ_0=κ、κ_{n+1}=j(κ_n)。

令 λ=sup_n κ_n。

则 j(λ)=λ，并且 j 也固定 λ^+。

考虑

  E = {α<λ^+ : cf(α)=ω}。

E 是 λ^+ 的荟萃子集。

用荟萃集分裂定理，把 E 分成 κ 个互不相交的荟萃集 F(α)（α<κ）。

于是 j(F) 的定义域为 j(κ)，而 κ<j(κ)，所以 j(F)(κ) 有定义。

初等性说明 j(F)(κ)⊆E 仍荟萃，并且 j(F) 的各项仍互不相交。

把 j(F)(κ) 写成它与各 F(α)（α<κ）的交集之并。

λ^+ 上非荟萃理想是 λ^+-完全的，而 κ<λ^+。

若每个交集都非荟萃，则整个并也非荟萃。

故存在 α_0<κ，使

  j(F)(κ) ∩ F(α_0)

仍荟萃。

再令

  C = {ξ<λ^+ : j(ξ)=ξ 且 cf(ξ)=ω}。

C 是 λ^+ 中的无界 ω-闭集。
先看无界性。
给定 η<λ^+，递归取 ξ_0>η 与 ξ_{n+1}>j(ξ_n)，各项仍小于 λ^+。
令 ξ=sup_nξ_n。
因为 λ^+ 正则，ξ<λ^+，并且 cf(ξ)=ω。
由于 cf(ξ)≠κ，j 在 ξ 处连续，故

  j(ξ)=sup_n j(ξ_n)=sup_n ξ_{n+1}=ξ。

所以 ξ∈C 且 ξ>η。
再看 ω-闭性：若 α<λ^+、cf(α)=ω，且 C∩α 在 α 中无界，取 C 中一列 ξ_n 收敛于 α。
每项都满足 j(ξ_n)=ξ_n，而 j 在共尾度 ω≠κ 的 α 处连续，因此 j(α)=α，故 α∈C。

因此 C 与上述共尾 ω 点组成的荟萃集相交。

取

  ξ_0=min(C∩j(F)(κ)∩F(α_0))。

由 ξ_0∈C，直接得到 j(ξ_0)=ξ_0。
又因为 ξ_0∈F(α_0)，所以

  ξ_0=j(ξ_0)∈j(F(α_0))=j(F)(j(α_0))=j(F)(α_0)，

其中最后一个等号使用 α_0<κ，故 j 固定 α_0。

但 κ≠α_0，而 j(F) 的各项互不相交，所以

  j(F)(κ)∩j(F)(α_0)=∅。

ξ_0 同时属于这个交集的两边，矛盾。

故 M 不可能等于 V。

这个结论的准确形式非常重要。

它不是“不存在任何非平凡初等嵌入”，因为可测基数恰好给出 j:V→M。

它说的是：在 ZFC 中，目标不能就是整个 V。

原书随后把无选择公理时的相应问题列为公开问题；本章不把它与上述 ZFC 定理混为一谈。

## 94.16 有限模型的任务与边界

接下来的七份代码处理一个刻意缩小的问题。

在有限集合 I 上，所有超滤子都是主超滤子。

这个命题可以真正证明，而不只是枚举几个例子。

设 I={a_1,…,a_n}，U 是超滤子。

沿列表逐个询问单点集 {a_i} 是否属于 U。

若某个答案为是，则对任意 A⊆I，

  A∈U ⇔ a_i∈A。

左到右是因为若 a_i∉A，则 {a_i} 与 A 的交为空，不能同属 U。

右到左是因为 {a_i}⊆A，再使用向上封闭。

若所有单点集都不属于 U，则每个补集 I−{a_i} 都属于 U。

它们的有限交仍属于 U，却是空集，矛盾。

因此至少一个单点集属于 U，超滤子必为主超滤子。

Coq 与 Agda 把这段论证写成对任意有限覆盖列表的一般定理。

Lean 与 Isabelle 检查主超滤的公理及三元素样本。

Julia 与 Python 独立穷举二、三元素集合上的全部子集族。

Prolog 检查主超滤下函数一致关系怎样划分有限函数空间。

主超幂也有一条精确的退化定理。

若 U=U_a 是焦点 a 的主超滤，则

  f=_U g ⇔ f(a)=g(a)。

因此映射 [f]↦f(a) 把主超幂与原坐标值结构同一起来。

每个 [f] 都含常值函数 c_{f(a)}，所以主超幂没有新元素。

这与可测基数上的非主超幂形成鲜明对照。

有限计算不能模拟 κ-完全性所施加的无限交条件，也不能模拟临界点是不可达基数。

更不能从“有限超滤皆主”推出“无限超滤皆主”；无限集合上非主超滤的存在正是另一层理论。

## 94.17 Lean：有限幂集代数中的主超滤

Lean 文件先把幂集代数表示成 `Finset (Finset α)`。

`principal a` 筛选所有含 a 的有限子集。

`IsFiniteUF` 明写空集、全集、有限交、向上封闭与超滤二分五条。

这里没有加入无限完全性或正规性，名字中的 `Finite` 就是在提醒语义边界。

`agreeSet f g` 是两个函数的一致坐标集合。

核心定理 `agree_mem_principal` 把它属于主超滤的命题化简为 `f a = g a`。

随后 `principal_ultrapower_degenerates` 给出常值代表。

完整文件如下。

```lean
import Mathlib

/-!
# 第 94 章 · 可测基数、正规超滤子与超幂

有限幂集代数与主超滤求值。`principal` 是具体的主超滤；有限模型只用于
核对定义和商退化，不提供可测基数的非平凡 κ-完全超滤。
-/

namespace Settheory.Ch94

open Finset

variable {α β : Type*}

/-- 有限类型幂集代数中，坐标 `a` 的主超滤。 -/
def principal [Fintype α] [DecidableEq α] (a : α) : Finset (Finset α) :=
  Finset.univ.filter (fun s => a ∈ s)

/-- 本书使用的五条有限超滤公理（不包含无限完全性、正规性）。 -/
def IsFiniteUF [Fintype α] [DecidableEq α]
    (U : Finset (Finset α)) : Prop :=
  ∅ ∉ U ∧ Finset.univ ∈ U ∧
  (∀ A ∈ U, ∀ B ∈ U, A ∩ B ∈ U) ∧
  (∀ A ∈ U, ∀ B : Finset α, A ⊆ B → B ∈ U) ∧
  (∀ A : Finset α, A ∈ U ∨ Aᶜ ∈ U)

/-- 两函数在 `a` 的主超滤意义下相等，当且仅当在 `a` 处相等。 -/
def agreeSet [Fintype α] [DecidableEq β] (f g : α → β) : Finset α :=
  Finset.univ.filter (fun x => f x = g x)

theorem mem_principal [Fintype α] [DecidableEq α]
    (a : α) {s : Finset α} : s ∈ principal a ↔ a ∈ s := by
  simp [principal]

theorem agree_mem_principal [Fintype α] [DecidableEq α] [DecidableEq β]
    (a : α) (f g : α → β) :
    agreeSet f g ∈ principal a ↔ f a = g a := by
  simp [agreeSet, mem_principal]

/-- 主超幂没有新元素：每个函数都等价于取值处的常值函数。 -/
theorem principal_ultrapower_degenerates [Fintype α] [DecidableEq α]
    [DecidableEq β] (a : α) (f : α → β) :
    agreeSet f (fun _ => f a) ∈ principal a := by
  rw [agree_mem_principal]

example : IsFiniteUF (principal (2 : Fin 3)) := by
  unfold IsFiniteUF
  native_decide

example : (principal (2 : Fin 3)).card = 4 := by
  native_decide

end Settheory.Ch94
```

最后两个 `example` 是有限判定。

三元素集合有八个子集，其中含固定焦点的恰有四个，所以主超滤族大小为 4。

`native_decide` 验证的是这个具体有限命题。

它既没有构造非主超滤，也没有证明可测基数存在。

## 94.18 Isabelle/ZF：三元素集上的主超滤

Isabelle 文件在同一个 ZF 集合论对象语言中定义 `K3` 与 `P0`。

`K3=succ(succ(succ(0)))` 是三元素冯·诺依曼序数。

`P0` 收集所有含 0 的 `K3` 子集。

各引理分别对应全集、空集、交封闭、向上封闭、补集二分和单点集。

完整文件如下。

```isabelle
theory Measurable
  imports "ZF.Nat"
begin

text \<open>第 94 章：三元素集上的主超滤。这里的 principal 是有限退化
模型，不具有可测基数定义中的非平凡性、κ-完全性和正规性。\<close>

definition K3 :: "i" where "K3 \<equiv> succ(succ(succ(0)))"
definition P0 :: "i" where "P0 \<equiv> {A \<in> Pow(K3). 0 \<in> A}"

lemma P0_mem: "A \<in> Pow(K3) \<Longrightarrow> A \<in> P0 \<longleftrightarrow> 0 \<in> A"
  by (simp add: P0_def)

lemma P0_full: "K3 \<in> P0"
  by (auto simp add: P0_def K3_def)

lemma P0_empty: "0 \<notin> P0"
  by (simp add: P0_def)

lemma P0_inter: "A \<in> P0 \<Longrightarrow> B \<in> P0 \<Longrightarrow> A \<inter> B \<in> P0"
  by (auto simp add: P0_def)

lemma P0_upward: "A \<in> P0 \<Longrightarrow> A \<subseteq> B \<Longrightarrow> B \<subseteq> K3 \<Longrightarrow> B \<in> P0"
  by (auto simp add: P0_def)

lemma P0_decides: "A \<subseteq> K3 \<Longrightarrow> A \<in> P0 \<or> (K3-A) \<in> P0"
  by (auto simp add: P0_def K3_def)

lemma P0_singleton: "{0} \<in> P0"
  by (auto simp add: P0_def K3_def)

end
```

`P0_decides` 的补集是 `K3-A`，不是宇宙中的绝对补集。

这与超滤子定义始终相对于底集 X 一致。

该证明说明有限主超滤满足五条代数要求。

开头的 `text` 则明确排除了把这个模型误称为可测基数模型的解释。

## 94.19 Coq：构造性证明有限超滤皆主

Coq 文件不满足于三元素样本。

它把子集编码为 `A -> bool`，并用 `eqb` 与 `eqb_eq` 表示可判定的点相等。

`Ultrafilter` 是五条公理组成的 record。

`no_both` 排除一个子集与其补集同属 U。

`principal_of_single` 证明：只要单点集属于 U，整个 U 就由该点决定。

`complements xs` 是列表各点单点补集的交。

`complements_false` 证明这个交在列表中的任一点都取假。

`find_singleton_or_complements` 给出构造性二分：或者找到测一单点，或者整个补集交测一。

总定理用列表覆盖全部 A，排除第二种可能。

完整文件如下。

```coq
(* 第 94 章：有限幂集代数、有限超滤皆主、主超幂退化。 *)
From Coq Require Import List Bool.
Import ListNotations.

Module Ch94.

Section Finite.

Variable A : Type.
Variable eqb : A -> A -> bool.
Hypothesis eqb_eq : forall x y, eqb x y = true <-> x = y.

Definition subset := A -> bool.
Definition empty : subset := fun _ => false.
Definition full : subset := fun _ => true.
Definition inter (s t : subset) : subset := fun x => s x && t x.
Definition comp (s : subset) : subset := fun x => negb (s x).
Definition single (a : A) : subset := fun x => eqb a x.

Record Ultrafilter (U : subset -> Prop) : Prop := {
  uf_empty : ~ U empty;
  uf_full : U full;
  uf_inter : forall s t, U s -> U t -> U (inter s t);
  uf_up : forall s t, U s -> (forall x, s x = true -> t x = true) -> U t;
  uf_decide : forall s, U s \/ U (comp s)
}.

Lemma no_both : forall U (H : Ultrafilter U) s, U s -> U (comp s) -> False.
Proof.
  intros U H s Hs Hcs. destruct H as [He _ Hi Hu _].
  apply He. eapply (Hu (inter s (comp s))).
  - now apply Hi.
  - intros x Hx. unfold inter, comp, empty in *. simpl in Hx.
    destruct (s x); discriminate.
Qed.

Lemma principal_of_single : forall U (H : Ultrafilter U) a,
  U (single a) -> forall s, U s <-> s a = true.
Proof.
  intros U H a Ha s. split.
  - intro Hs. destruct (s a) eqn:E; auto.
    exfalso. apply (no_both U H s Hs).
    destruct H as [_ _ _ Hu _].
    eapply (Hu (single a)); auto.
    intros x Hx. unfold single, comp in *.
    apply eqb_eq in Hx. subst x. now rewrite E.
  - intro E. destruct H as [_ _ _ Hu _].
    eapply (Hu (single a)); auto.
    intros x Hx. unfold single in *.
    apply eqb_eq in Hx. now subst x.
Qed.

Definition complements (xs : list A) : subset :=
  fold_right (fun a rest => inter (comp (single a)) rest) full xs.

Lemma complements_false : forall xs x, In x xs -> complements xs x = false.
Proof.
  induction xs as [|a xs IH]; simpl; intros x Hx.
  - contradiction.
  - destruct Hx as [->|Hx].
    + unfold inter, comp, single.
      replace (eqb x x) with true by (symmetry; now apply eqb_eq).
      reflexivity.
    + unfold inter in *. now rewrite IH, andb_false_r.
Qed.

Lemma find_singleton_or_complements : forall U (H : Ultrafilter U) xs,
  (exists a, In a xs /\ U (single a)) \/ U (complements xs).
Proof.
  intros U H xs. induction xs as [|a xs IH]; simpl.
  - right. apply (uf_full _ H).
  - destruct (uf_decide _ H (single a)) as [Ha|Ha].
    + left. exists a. auto.
    + destruct IH as [(b & Hb & HU)|Hrest].
      * left. exists b. auto.
      * right. apply (uf_inter _ H); assumption.
Qed.

Theorem finite_ultrafilter_principal : forall U (H : Ultrafilter U) xs,
  (forall x, @In A x xs) -> exists a, forall s, U s <-> s a = true.
Proof.
  intros U H xs Hcover.
  destruct (find_singleton_or_complements U H xs) as [(a & _ & Ha)|HC].
  - exists a. now apply principal_of_single.
  - exfalso. apply (uf_empty _ H).
    destruct H as [_ _ _ Hu _].
    eapply (Hu (complements xs)); eauto.
    intros x Hx. rewrite (complements_false xs x (Hcover x)) in Hx.
    discriminate.
Qed.

(* 主超幂的相等判据：一致集属于主超滤，当且仅当两函数在焦点相等。 *)
Definition principal (U : subset -> Prop) (a : A) : Prop :=
  forall s, U s <-> s a = true.

Theorem principal_agreement : forall U a f g,
  principal U a -> (U (fun x => eqb (f x) (g x)) <-> eqb (f a) (g a) = true).
Proof. intros U a f g H. apply H. Qed.

End Finite.

End Ch94.
```

这里没有使用排他律来决定任意无限子集。

`uf_decide` 是被证明对象的超滤公理，不是 Coq 对整个 Prop 默认加入经典逻辑。

列表归纳则完全构造性地找到焦点。

因此这份证明准确对应有限性：有限次二分与有限次交封闭足以完成论证。

## 94.20 Agda：同一定理的依赖类型版本

Agda 文件保留同一证明结构，但把逻辑命题显式表示为类型。

`U s` 是一个 `Set`，`decide` 返回和类型 `_⊎_`。

`principal-of-single` 的两个方向组成乘积。

`In` 是自定义列表成员证据，`here` 与 `there` 指明焦点位置。

`find-singleton` 的返回值直接携带“找到单点”或“补集交属于 U”的计算证据。

最终 `theorem` 返回焦点 a 以及主超滤判定的双向函数。

完整文件如下。

```agda
-- 第 94 章：有限超滤皆主的构造性证明。
module Ch94_measurable where

open import Data.Bool using (Bool; true; false; _∧_; not)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.List using (List; []; _∷_)
open import Data.Product using (Σ; _×_; _,_)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

module FiniteUF {A : Set} (eqb : A → A → Bool)
  (eqb-eq : ∀ {x y} → eqb x y ≡ true → x ≡ y)
  (eqb-refl : ∀ x → eqb x x ≡ true) where

  Sub : Set
  Sub = A → Bool

  empty full : Sub
  empty _ = false
  full _ = true

  inter : Sub → Sub → Sub
  comp : Sub → Sub
  inter s t x = s x ∧ t x
  comp s x = not (s x)

  single : A → Sub
  single a x = eqb a x

  record Ultrafilter (U : Sub → Set) : Set where
    field
      empty-not : U empty → ⊥
      full-in : U full
      inter-in : ∀ {s t} → U s → U t → U (inter s t)
      upward : ∀ {s t} → U s → (∀ x → s x ≡ true → t x ≡ true) → U t
      decide : ∀ s → U s ⊎ U (comp s)

  open Ultrafilter

  bool-no : false ≡ true → ⊥
  bool-no ()

  no-both : ∀ {U} → Ultrafilter U → ∀ {s} → U s → U (comp s) → ⊥
  no-both {U} H {s} Us Ucs =
    empty-not H (upward H (inter-in H Us Ucs) bad)
    where
      bad : ∀ x → inter s (comp s) x ≡ true → empty x ≡ true
      bad x hx with s x
      ... | true = ⊥-elim (bool-no hx)
      ... | false = ⊥-elim (bool-no hx)

  principal-of-single : ∀ {U} → Ultrafilter U → ∀ {a} → U (single a) →
    ∀ s → (U s → s a ≡ true) × (s a ≡ true → U s)
  principal-of-single {U} H {a} Ha s = forward , backward
    where
      forward : U s → s a ≡ true
      forward Us with s a in eq
      ... | true = refl
      ... | false = ⊥-elim (no-both H Us (upward H Ha smaller))
        where
          smaller : ∀ x → single a x ≡ true → comp s x ≡ true
          smaller x hx with eqb-eq hx
          ... | refl rewrite eq = refl
      backward : s a ≡ true → U s
      backward sa = upward H Ha (λ x hx → aux x hx)
        where
          aux : ∀ x → single a x ≡ true → s x ≡ true
          aux x hx with eqb-eq hx
          ... | refl = sa

  data In (x : A) : List A → Set where
    here : ∀ {xs} → In x (x ∷ xs)
    there : ∀ {y xs} → In x xs → In x (y ∷ xs)

  complements : List A → Sub
  complements [] = full
  complements (a ∷ xs) = inter (comp (single a)) (complements xs)

  complements-false : ∀ xs {x} → In x xs → complements xs x ≡ false
  complements-false (a ∷ xs) here rewrite eqb-refl a = refl
  complements-false (a ∷ xs) {x} (there p)
    rewrite complements-false xs {x} p with eqb a x
  ... | false = refl
  ... | true = refl

  find-singleton : ∀ {U} → Ultrafilter U → ∀ xs →
    (Σ A (λ a → In a xs × U (single a))) ⊎ U (complements xs)
  find-singleton H [] = inj₂ (full-in H)
  find-singleton {U} H (a ∷ xs) with decide H (single a)
  ... | inj₁ Ha = inj₁ (a , here , Ha)
  ... | inj₂ Hca with find-singleton H xs
  ...   | inj₁ (b , p , Hb) = inj₁ (b , there p , Hb)
  ...   | inj₂ Hrest = inj₂ (inter-in H Hca Hrest)

  theorem : ∀ {U} → Ultrafilter U → ∀ xs → (∀ x → In x xs) →
    Σ A (λ a → ∀ s → (U s → s a ≡ true) × (s a ≡ true → U s))
  theorem {U} H xs cover with find-singleton H xs
  ... | inj₁ (a , _ , Ha) = a , principal-of-single H Ha
  ... | inj₂ HC = ⊥-elim (empty-not H (upward H HC bad))
    where
      bad : ∀ x → complements xs x ≡ true → empty x ≡ true
      bad x hx rewrite complements-false xs (cover x) = ⊥-elim (bool-no hx)
```

`complements-false` 的尾分支需要检查 `eqb a x`。

这是布尔归约的实际细节：中立左操作数与 `false` 的合取不会在所有情形下自动化简成目标形式。

显式分支后，两种情形都由归纳重写得到 `refl`。

这个实现细节不改变数学内容，却说明机器证明必须把“显然的布尔等式”落实到类型检查器接受的归约路径。

## 94.21 Julia：位掩码穷举有限超滤

Julia 通道用布尔向量表示子集，用整数位掩码枚举子集族。

二元素集合有 4 个子集，因此有 16 个候选子集族。

三元素集合有 8 个子集，因此有 256 个候选子集族。

这个规模足以无筛选地全部检查。

`is_ultrafilter` 逐条实现五条公理。

主程序先验证超滤数量恰为底集大小，再逐一验证每个焦点生成的主超滤都确实出现在枚举结果里。

完整文件如下。

```julia
# 第 94 章：有限超滤穷举与主超幂退化（位掩码实现）。
println("==== 94")

function subsets(n)
    return [[((mask >> (i-1)) & 1) == 1 for i in 1:n]
            for mask in 0:(2^n-1)]
end

function is_ultrafilter(family, ss, n)
    empty = first(ss)
    full = last(ss)
    empty ∉ family || return false
    full ∈ family || return false
    for a in family, b in family
        (a .& b) ∈ family || return false
    end
    for a in family, b in ss
        all(.!a .| b) || continue
        b ∈ family || return false
    end
    for a in ss
        (a ∈ family || .!a ∈ family) || return false
    end
    return true
end

function ultrafilters(n)
    ss = subsets(n)
    result = Vector{Vector{Vector{Bool}}}()
    for mask in 0:(2^length(ss)-1)
        family = [ss[i] for i in eachindex(ss) if ((mask >> (i-1)) & 1) == 1]
        is_ultrafilter(family, ss, n) && push!(result, family)
    end
    return result
end

for n in (2, 3)
    ufs = ultrafilters(n)
    ss = subsets(n)
    @assert length(ufs) == n
    for focus in 1:n
        principal = [s for s in ss if s[focus]]
        @assert length(principal) == 2^(n-1)
        @assert principal ∈ ufs
    end
end

# 坐标 2 的主超幂：一致类由函数在坐标 2 的值唯一决定。
functions = [[x, y, z] for x in (false,true) for y in (false,true) for z in (false,true)]
classes = Dict{Bool,Vector{Vector{Bool}}}()
for f in functions
    push!(get!(classes, f[2], Vector{Vector{Bool}}()), f)
end
@assert length(classes) == 2 && all(length(v) == 4 for v in values(classes))
@assert all(all(f[2] == value for f in fs) for (value,fs) in classes)
println("Julia：2/3 元素集的有限超滤数恰为 2/3，全部为主超滤")
println("主超幂：8 个二值函数按焦点值分成 2 类，每类 4 个代表 ✓")
println("END ====")
```

八个三坐标二值函数按第二坐标的值分为两类。

每类四个函数，因为另外两个坐标可自由取值。

这正是一个具体的主超幂商。

它验证的是商计数与焦点求值，不是非主超幂产生新序数的过程。

## 94.22 Python：递归包含/不包含搜索

Python 使用 `frozenset`，使子集本身可以再作为集合族的元素。

与 Julia 预先生成所有族不同，这里递归地对每个子集选择“包含”或“不包含”。

叶子处再调用独立的公理检查器。

两种搜索组织方式得到相同计数，可用来发现枚举或成员判断中的实现错误。

完整文件如下。

```python
# 第 94 章：有限超滤递归穷举与主超幂求值（独立于 Julia）。
from itertools import product
import sys
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def subsets(n):
    return [frozenset(i for i in range(n) if mask & (1 << i))
            for mask in range(1 << n)]


def is_ultrafilter(family, ss):
    family = set(family)
    if frozenset() in family or ss[-1] not in family:
        return False
    if any(a & b not in family for a in family for b in family):
        return False
    if any(a <= b and b not in family for a in family for b in ss):
        return False
    return all(a in family or ss[-1] - a in family for a in ss)


def ultrafilters(n):
    ss = subsets(n)
    answer = []

    def visit(i, chosen):
        if i == len(ss):
            if is_ultrafilter(chosen, ss):
                answer.append(tuple(chosen))
            return
        visit(i + 1, chosen)
        visit(i + 1, chosen + [ss[i]])

    visit(0, [])
    return answer


def main():
    print("==== 94")
    for n in (2, 3):
        ufs = ultrafilters(n)
        assert len(ufs) == n
        for a in range(n):
            principal = tuple(s for s in subsets(n) if a in s)
            assert sum(set(principal) == set(u) for u in ufs) == 1
    functions = list(product((0, 1), repeat=3))
    focus = 1
    classes = {v: [f for f in functions if f[focus] == v] for v in (0, 1)}
    assert [len(classes[v]) for v in (0, 1)] == [4, 4]
    assert all(tuple([f[focus]] * 3) in classes[f[focus]] for f in functions)
    assert sorted(classes[0] + classes[1]) == sorted(functions)
    print("Python 递归穷举：有限超滤族恰为各点主超滤；n=2,3 对账 ✓")
    print("主超幂商等价于焦点求值：两个等价类，各 4 个布尔函数")
    print("END ====")


if __name__ == "__main__":
    main()
```

最后三个断言分别检查类大小、常值代表和完备划分。

特别地，`tuple([f[focus]] * 3)` 是该函数所在类中的常值代表。

这就是有限函数层面的 `principal_ultrapower_degenerates`。

输出中的“对账”只指 n=2、3 的穷举结果一致。

一般性定理由 Coq 与 Agda 给出，而不是由两个有限样本外推。

## 94.23 Prolog：主超滤商的逻辑查询

Prolog 通道集中表达函数一致关系。

`binary_function` 生成所有三坐标二值函数。

`agree_at(F,G,I)` 表示两函数在焦点 I 一致。

`quotient_class` 用 `setof` 收集在焦点取指定值的函数类。

`forall` 中的合取被显式加括号，保证两个检查目标都属于同一个全称量词作用域。

完整文件如下。

```prolog
:- encoding(utf8).
% 第 94 章：主超滤上函数一致关系的有限商。

binary_function(F) :-
    F = [A,B,C],
    member(A, [0,1]), member(B, [0,1]), member(C, [0,1]).

agree_at(F, G, I) :- nth0(I, F, X), nth0(I, G, X).

quotient_class(I, V, Class) :-
    setof(F, (binary_function(F), nth0(I, F, V)), Class).

all_same_at(Class, I, V) :-
    forall(member(F, Class), nth0(I, F, V)).

main :-
    format("==== 94~n"),
    findall(F, binary_function(F), Fs),
    length(Fs, 8),
    quotient_class(1, 0, C0), quotient_class(1, 1, C1),
    length(C0, 4), length(C1, 4),
    all_same_at(C0, 1, 0), all_same_at(C1, 1, 1),
    append(C0, C1, All), sort(All, Sorted), Sorted == Fs,
    forall((member(F, Fs), member(G, Fs), agree_at(F, G, 1)),
           (nth0(1, F, V), nth0(1, G, V))),
    writeln("Prolog：坐标 1 的主超滤商有两类，各 4 个函数，并集穷尽 8 个函数 ✓"),
    writeln("一致关系按焦点值划分；有限主超幂退化为求值，不模拟可测基数"),
    writeln("END ====").
```

这里坐标使用 Prolog 的零基索引，所以焦点 1 对应 Julia 的坐标 2、Python 的 `focus=1`。

两个商类各含四个函数，排序后并集穷尽全部八个函数。

`agree_at` 只表达焦点一致，不声称已形式化任意集合论公式的 Łoś 定理。

真正的 Łoś 定理需要按所有公式作归纳，远不是有限二值函数的等价类枚举。

## 94.24 七通道对账与常见误读

七份实现围绕同一个有限核心，却有不同证明职责。

| 通道 | 主要对象 | 实际验证内容 |
|---|---|---|
| Lean | `Finset (Finset α)` | 主超滤成员判定、五条公理样本、常值代表 |
| Isabelle/ZF | `K3`、`P0` | 三元素幂集代数中的主超滤六条事实 |
| Coq | 布尔子集与有限列表 | 任意有限覆盖列表上的“超滤皆主”一般定理 |
| Agda | 依赖类型证据与和类型 | 同一构造性定理及可计算的焦点证据 |
| Julia | 位掩码与布尔向量 | n=2、3 全穷举及主超幂商计数 |
| Python | `frozenset` 递归搜索 | 独立实现的全穷举、常值代表、完备划分 |
| Prolog | 关系与 `setof` | 焦点一致关系、两类各四个函数 |

它们相互支持的结论只有有限部分。

Coq 与 Agda 的一般定理证明有限集上每个超滤都是主超滤。

Julia 与 Python 给出两种实现一致的小规模计数。

Lean 与 Isabelle 把主超滤定义放在各自集合数据结构中核对。

Prolog 用逻辑查询复核商类关系。

这些结果不能证明以下任何命题。

- 某个不可数 κ 上存在非主 κ-完全超滤子。
- 可测基数与 ZFC 相容。
- 超幂 Ult(V,U) 的良基性可以由有限枚举代替。
- 初等嵌入、Scott 定理或 Kunen 定理已经被这七份有限代码形式化。
- 主超幂退化也适用于可测基数上的非主正规测度。

还应区分三个“完全性”层次。

普通滤子的有限交封闭，对任意有限集合上的超滤证明已经足够。

可数交封闭与 κ-完全性涉及无限交，不能由有限循环程序验证。

正规性的“回归函数测一常值化”又是另一条性质，不等于单纯 κ-完全性。

同样，主超滤虽然在有限集上满足有限交等公理，却被可测定义的非平凡性明确排除。

把“主超滤是超滤子”误读成“有限主超滤见证可测基数”，会同时丢掉定义中最重要的一条限制。

## 94.25 本章要点

- 可测 κ 上存在非平凡、κ-完全、正规的超滤子；三个修饰语各有独立内容。
- 非平凡 κ-完全性强迫 κ 不可数、正则且强极限，因此可测基数不可达。
- 正规性通过回归函数测一常值化，证明下方不可达基数集合测一，也证明每个无界闭集测一。
- 非平凡 κ-完全超滤子可正规化，因此正规性不增加可测性的存在强度。
- 超幂按测一一致关系商掉函数；整个 V 上的等价类用 Scott trick 截成集合。
- Łoś 定理把超幂真值等价于坐标真集测一；存在量词反向步需要选择见证函数。
- κ-完全性保证超幂良基，Mostowski 坍缩给出传递内模型 M 与初等嵌入 j:V→M。
- 正规测度下 crit(j)=κ，π([id])=κ，且 A∈U 当且仅当 κ∈j(A)。
- M={j(f)(κ):f∈V^κ}，并具有 κ-序列闭包；同时 U∉M，j(κ) 受到函数数量的上界控制。
- 可测基数具有拉姆齐性质，且正规测度认为下方拉姆齐基数集合测一。
- Scott 定理由 L 的最小性与 U∉M 联合推出：可测基数存在则 V≠L。
- 任意非平凡初等嵌入在临界点导出正规测度，并可分解为超幂嵌入后接因子嵌入。
- Kunen 定理不排除 j:V→M，而排除 ZFC 中非平凡 j:V→V。
- 有限集上所有超滤都是主超滤，主超幂退化为焦点求值；这只是有限代数定理，不是大基数证据。

本章所引代码文件为：

- `examples/lean/Settheory/Ch94Measurable.lean`
- `examples/isabelle/ST94/Measurable.thy`
- `examples/coq/Ch94_measurable.v`
- `examples/agda/Ch94_measurable.agda`
- `examples/julia/94_measurable.jl`
- `examples/python/94_measurable.py`
- `examples/prolog/94_measurable.pl`

章级验证命令为：

```pwsh
pwsh -NoProfile -Command '& ./build.ps1 -Chapter 94'
```

它包含七个章通道单元和一次整个 Lean 项目的构建单元；只有真实结果通过后才在 PLAN 中记为全绿。

---

上一章：[第 93 章 高阶无穷导引](93-higherinfinity.md) · 下一章：[第 95 章 0# 与 Silver 不可辨别元](95-zerosharp.md)
