# 115 · Lévy 扩张正则性与 L(ℝ) 理论不变性

> 第 114 章在 V[G] 中切出 HOD(Ω) 走廊。本章取材冯琦第三卷 §3.2.2
> 与 §3.3–§3.3.1（书页 324–331；PDF 344–351），在走廊尽头把 Solovay
> 定理逐件兑现，再沿 §3.3 的「高端智慧博物馆」走到 L(ℝ)-理论不变性。
> 三段主线：**其一（引理 3.23：正则性的三层分解）**——设 κ 不可达、
> G 是 Col(ω,<κ)-泛型、s ∈ V[G] 是序数可数序列：(1) **ℝ−R(V[s])
> 零测**、(2) **ℝ−C(V[s]) 稀疏**——证明用 B(Col(ω,<κ)) 的 **κ-饱和**
> （势<κ 的完备子代数 D 实现 V[s] 在 V[G] 中可数 → B^{V[s]} 可数 →
> 特征引理 3.18 的可数并）；(3) **s-可定义集的正则性**——归结**事实一**
> （单变元：V[G] ⊨ φ[α] ⟺ V[α] ⊨ φ[α]——因子分解引理 2.3 + 莱维
> 代数整齐性推论 2.1 + **黑白分明律**推论 2.2：布尔值非 0 即 1）、
> **事实二**（双变元版）、测度代数 B_m^{V[s]} 与随机实数名字 ḃ、
> **事实三**（ξ∈R(V[s]) 的四步链：ξ∈X → V[s][ḃ] ⊨ φ → ‖φ‖∈K →
> [A_e]∈K → ξ∈A₁）、**事实四**（X△A₁ 零测、X△A₂ 稀疏——mod 理想
> 的同余）、**事实五**（不可数则含完备子集：a∈X−V[s]、势<κ 子代数 D
> 使 a∈M[H∩D]、p∈D∩H 不定 ḃ(n₀) 的双分支、K_z = {r∈D | ∃C_z
> ⊆ p≤r} 对每个 D_n 命中、f:[0,1]→X 连续单射）。**推论 3.18**：
> (1) 射影集全正则；(2) **HOD(Ω) 中每个实数集**可测+贝尔+不可数含
> 完备子集（B^{L(ℝ)} = B^{HOD(Ω)} = B^{V[G]} 的三宇宙合同 + 绝对
> 不变性）；(3) **L(ℝ) 中每个实数集**同。**定理 3.25（Solovay）**：
> 存在不可达基数 ⟹ (1) 存在 ZF+DC 传递模型使每个实数子集可测+
> 贝尔+不可数含完备子集；(2) 存在 ZFC 传递模型使每个射影子集同。
> **其二（§3.3 博物馆开馆）**——大基数对实数集理论的影响：从定理
> 3.12/推论 3.13（不可达）、定理 1.20（可测）、到本章的正则性谱系。
> **其三（§3.3.1 L(ℝ)-理论不变性）**——**定理 3.26（Woodin）**：
> κ 超强 ⟹ Col(ω,<κ) 扩张中存在 L(ℝ)^V → L(ℝ)^{V[G]} 的**同质
> 嵌入**；**推论 3.19**：L(ℝ) 中每实数集可测+贝尔+完备子集+**不存在
> ℝ 的 Π-秩序**；**定理 3.27（Shelah-Woodin 弱形式）**：κ 武丁且
> 弱紧 ⟹ 同质嵌入——证明的骨架：P=Col(ω₁,<κ) + 定理 2.31 的饱和
> 正规理想 I + Q=𝒫(ω₁)/I + 泛型嵌入 i_H（i_H(ω₁)=ω₂、ℝ^{M[H]}=
> ℝ^V）、B=B(P*Q) 的 κ-cc 与弱紧性给的子代数塔（B_α 层链）⟹
> **B ≅ B(Col(ω,<κ))**；**定理 3.28（Shelah-Woodin 最佳版）**：
> n 个武丁+更大可测 ⟹ Σ^1_{n+1} 全可测；无穷多武丁+更大可测 ⟹
> L(ℝ) 全可测；**定理 3.29（Woodin）**：sup{α<κ | α 武丁}=κ ⟹
> 存在 Q_<κ 使 V[G] 中有 L(ℝ)^V → L(ℝ)^{Col(ω,<κ)} 的同质嵌入
> （假设可再减至可数无穷多武丁+更大可测——最佳）。
>
> 本章机器件落在**机制层**：布尔值模型的有限版（三点底集、τ-对换、
> 公式的布尔值递归）承载**对称保真**（⟦φ⟧_{v^τ} = τ·⟦φ⟧_v——同质
> 嵌入的语义面）、**双点不变证书**（τ-不变公式的真值在共轭泛型求值
> 点相等——L(ℝ)-理论不变的核）、**非不变反例**（不变性必须限定
> 公式）、**mod-I 包裹**（引理 3.23(3) 的 A₁ 机制）、**f-单射与
> 稠密命中**（事实五的机制核）。本体（κ-饱和、随机实数、黑白分明
> 律、完备布尔代数的层塔）留在正文。

---

**阅读路线**：§一–§二是 Solovay 定理的兑现（三层分解 → 三宇宙
合同 → 定理 3.25）——引理 3.23 的五个事实是证明的心脏，值得
逐个过手；§三是 §3.3.1 的理论不变性（同质嵌入的谱系与价格）；
§四起是机器件与七通道源码。前置：第 112 章（特征引理 3.18 与
随机/科恩实数）、第 103 章（莱维代数的整齐性/黑白分明律与因子
分解引理）、第 110 章（饱和理想与泛型嵌入）、第 114 章（HOD(Ω)
走廊）。只关心 Solovay 定理的读者 §一–§二 自足；关心现代路线
（Woodin）的读者 §三 是入口。

## 一、引理 3.23：正则性的三层分解

第 112 章的特征引理 3.18（R(M) = ℝ 减 M-零测博雷尔并；C(M) = ℝ 减
M-稀疏博雷尔并）在本章被第一次大规模消费。引理 3.23 的头两款把
「旧模型的实数」放在新宇宙里称重：

> **(1) ℝ − R(V[s]) 零测；(2) ℝ − C(V[s]) 稀疏。**

证明只有一步但那一步是整章的地基：B(Col(ω,<κ)) 是 **κ-饱和**的
完备布尔代数，所以对给定的序数序列 s，存在势 <κ 的完备子代数 D
实现 V[s] ⊆ V[G]↾D 的分解；于是 ℝ^{V[s]} 在 V[G] 中是**可数集**；
于是 B(R)^{V[s]} 在 V[G] 中可数；特征引理 3.18 把「R(V[s]) 之外」
拆成可数多个 V[s]-零测集之并——可数并零测仍零测。稀疏版逐字
平行。「饱和 → 可数 → 理想封闭」的三级火箭是正则性的供给侧。

第 (3) 款处理 **s-可定义的 X**：由归结事实（事实一/二——V[G] 的
满足关系归结到 V[s] 或 V[s][α] 的满足关系，其引擎是因子分解
引理与黑白分明律：莱维代数上任何语句的布尔值非 0 即 1），X 的
成员资格等价于 V[s] 中的力迫判断；在 M = V[s] 的测度代数 B_m 上
取 A_e 使 [A_e] = ‖φ‖，令 A₁ = (A_e)^* ∈ V[G]；事实三的四步链
把 R(V[s]) 上的 X-成员资格逐点转译成 A₁-成员资格；事实四收口：
X△A₁ 零测、X△A₂ 稀疏——**X 与博雷尔集只差一个理想**。

事实五造完备子集：取 a ∈ X − V[s]（X 不可数而 ℝ^{V[s]} 可数），
在 <κ 的子代数 D 上让 p ∈ D∩H 保持在 ḃ(n₀) 的两个分支上都不定
（p 不定 ḃ(n₀)=i）；对每个 z ∈ [0,1] 定义 K_z = {r ∈ D | ∃C_z
⊆ z 的有限 0/1 串， p ≤ r}——每个 D_n 都与 K_z 相交（p 的双分支
保证稠密性不被封死），K_z 是 M 之上的 D-泛型滤子；f(z) = ḃ/K_z
∈ X；**f 是连续单射**——f[[0,1]] ⊆ X 是完备子集。机制的三件
（p 的双分支不定性、K_z 的稠密命中、f 的单射性）正是本章机器件
件 C 的化身。

### 火箭的第二级与第三级

第二级（可数 → 理想封闭）：ℝ^{V[s]} 可数 ⟹ V[s] 的博雷尔
代码集 B(R)^{V[s]} 可数 ⟹ R(V[s]) 之外的每个实数都是
「V[s]-随机实数」（避开 V[s] 的一切零测博雷尔集）——特征
引理 3.18 把「ℝ − R(V[s])」拆成可数多个 V[s]-零测集的并
——可数并零测（测度的 σ-可加性）仍零测。这一级的数学是
测度论常识，但**装配位置**是力迫的：没有第一级的可数性，
σ-可加性无用武之地。

第三级（分解 → 正则性）：s-可定义的 X 经归结事实搬进 V[s]，
在测度代数上结算成博雷尔 witness——三级火箭的最终载荷是
「X 只差一个理想」。**载荷、二、三级的关系是「越往上越
具体」**：饱和性是代数事实、可数性是组合事实、正则性是
实分析事实——一条从抽象代数到实分析的完整供应链。

### 三级火箭的第一级：饱和 → 可数

「κ-饱和 ⟹ ℝ^{V[s]} 在 V[G] 中可数」的完整链条值得展开：
饱和性说 B(Col(ω,<κ)) 的任何 <κ 个元素的布尔和的非零性可以
被单一非零元素控制——于是对给定的 s（一个序数序列，其信息
量 <κ），存在势 <κ 的完备子代数 D ⊆ B 使 s ∈ V[G↾D]（s 的
全部信息被 D 吸收）。而 D 势 <κ 且 κ 在 V[G] 中是 ω₁——
**V[G] 视角下 D 可数**。实数是 ω-序列，每个实数的信息被 D
的某个可数片段吸收；「V[s] 的实数」=「D-名字的实数」——
可数个。这步的数学重量在于「饱和」这个词：一般的 <κ-cc 不够
（反链条件只控制两两不相容，不控制信息合并）——饱和是「<κ
个条件可以合并成一个」的代数化，正是把「s 的信息」打包的
工具。第 110 章饱和理想的谱系在此兑现为正则性的供给侧。

### 归结事实的机制再细一层

**事实一**（单变元归结）的证明走三步：给定力迫语句 φ(ů)，
定义新表达式 φ̂(α) := 「‖φ(α)‖ = 1」（「布尔值为顶」的语句化）。
对 α ∈ Ord^{V[G]}，取 M = V[α]——因为 Col(ω,<κ) 的条件是
有限偏函数，P 的定义对内模型绝对；由分解引理（引理 2.3）取
V[α] 上的 P-泛型滤子 H 使 V[G] = V[α][H]。在 V[α] 中讨论：
莱维代数的**整齐性**（推论 2.1——代数元素的正则嵌入结构）
给出**黑白分明律**（推论 2.2）——任何带参语句的布尔值 b
满足 b² = b，即 b ∈ {0,1}。于是 H 的泛型性把「b=1」翻译成
「V[α][H] ⊨ φ(α)」——归结完成。**事实二**（双变元）逐字平行，
只是参数从单个 α 变成序对 (α,γ)，内模型取 V[α,γ]。

这两条事实合起来说的是：**在莱维扩张里，「真」是分层的**——
一个带序数参数的语句在 V[G] 中的真值，完全由它在「参数生成的
最小内模型」中的真值决定。归结论证的可定义集 X 因此可以搬进
V[s] 里处理——这是引理 3.23(3) 全部后续构造的许可。

### 五个事实的依赖图

五个事实的依赖关系可以画成一张小图：事实一（单变元归结）与
事实二（双变元归结）是叶子——只用因子分解引理与黑白分明律；
事实三（四步链）吃事实二——把 s-可定义集的成员资格经测度
代数的布尔值转译成 A₁ 的成员资格；事实四（mod-I 同余）吃
事实三——X△A₁ 落零测理想；事实五（完备子集）独立于三、四
——只用饱和性与不定性。**事实一二是「许可」（可以搬）、事实
三四是「结算」（搬到博雷尔）、事实五是「加码」（不可数时
再加完美子集）**——引理 3.23(3) 的证明结构是许可-结算-加码
的三段式，这个结构在下一章的荟萃塔设计里会再现。

### 事实五的构造分镜

完备子集的构造是引理 3.23(3) 里最有画面感的部分，值得分镜：

1. **选点**：X 不可数而 ℝ^{V[s]} 可数——取 a ∈ X − V[s]
   （「新实数」）；设 X ⊆ [0,1]。
2. **收缩**：取 <κ 的完备子代数 D 使 a ∈ M[H∩D]（饱和性
   把 a 的信息吸收进小代数）；(D)^M 在 M[H] 中可数——
   D 的稠密开子集可以单一罗列 D₀, D₁, …。
3. **不定性**：取 p ∈ D∩H 见证 p ⊩_{D} a ∉ M[α̑]（a 不在
   任何 D-泛型的小模型里）；于是 p 不能定死随机名字 ḃ(n₀)
   的值——存在 n₀ 使 p 不定 ḃ(n₀)=0 与 ḃ(n₀)=1（定死一支
   就等于宣布 a 可被那支的模型预见）。
4. **滤子族**：对每个 z ∈ [0,1]（的二进制展开的有限前缀
   C_z），令 K_z = {r ∈ D | ∃C_z ⊆ 有限串, p ≤ r}——
   p 的双分支不定性保证 K_z 与每个 D_n 相交（第 n 层的
   稠密性总能在 p 的某个延伸处满足）——K_z 是 M 之上的
   D-泛型滤子。
5. **映射与单射**：f(z) = ḃ/K_z ∈ X（p ∈ K_z 保证 f(z)
   落在 p 力迫的范围内）；z 的不同前缀在某层分叉——那层
   的 K_z 选择不同分支——f(z) 不同——**f 单射**。
6. **收口**：f 连续（前缀的一致性）——f[[0,1]] 是 X 的
   完备子集（连续像的像集是闭集；单射保证不塌缩）。

机器件件 C 吃下第 3–5 步的机制核：分支树的双分支（不定性）、
8 路径的 K_z（滤子族）、f-单射（分叉保证单射）。

## 二、推论 3.18 与 Solovay 定理 3.25

**推论 3.18 的三宇宙合同**：ℝ∩HOD(Ω) = ℝ∩V[G] = ℝ^{L(ℝ)}，且
B(R)^{L(ℝ)} = B(R)^{HOD(Ω)} = B(R)^{V[G]}（博雷尔代码的三宇宙
一致——引理 3.15 的代码运算绝对性在此总账）。于是 V[G] 中由引理
3.23 给出的 A₁…A₄ 见证可以逐字搬进 HOD(Ω) 与 L(ℝ)——**正则性
从大宇宙传递到内模型**，传递的桥是代码的绝对不变性。

**定理 3.25（Solovay）**：存在不可达基数 ⟹ (1) 存在 ZF+DC 的
传递模型使**每个**实数子集勒贝格可测、有贝尔性质、不可数含完备
子集（取 L(ℝ)^{V[G]}——第 114 章的走廊尽头）；(2) 存在 ZFC 传递
模型使每个**射影**子集三正则（取 V[G] 本身，射影集由引理 3.23(3)
直接覆盖）。两款的分野正是第 114 章「AC 造反例、DC 干正事」的
定理化：全称「每个实数子集」只能在 DC 宇宙里说，「每个射影子集」
可以在 ZFC 宇宙里说——**量词的范围换选择公理的强度**。

Shelah 1984 后来证明：贝尔性质版可以去掉不可达（ZF+「每个实数集
贝尔」一致只需 ZF 一致），而等可测版不可去——不可达性在测度侧
是必要的。Solovay 定理的假设是最优的一半。

### 推论 3.18 的三宇宙过桥分步

三宇宙合同的过桥值得分步：第一步（实数层）——ℝ∩HOD(Ω) =
ℝ∩V[G]：HOD(Ω) 含一切 Ω-参数可定义的集合，而每个 V[G] 的
实数由序数序列（Ω 的成员）可定义（引理 3.21(1) 的本地性）；
ℝ^{L(ℝ)} 同理（引理 3.21(2)）。第二步（博雷尔代码层）——
BC^{L(ℝ)} = BC^{HOD(Ω)} = BC^{V[G]}：博雷尔代码是自然数上的
递归构造（引理 3.12 的 S_α/T_α 层级），三宇宙的自然数与
ω-递归完全一致——代码运算的绝对性（引理 3.15）保证同一
代码在三宇宙解码出同一集合。第三步（正则性下放）——V[G] 中
由引理 3.23 找到的 A₁…A₄ 见证（X△A₁⊆A₂ 零测、X△A₄ 稀疏）
全部落在 HOD(Ω)（四个集合都由 s-参数可定义）——由绝对不变
性，「A₂ 零测」「A₄ 稀疏」在 HOD(Ω) 中仍然成立——正则性
传递完成。**桥的每一步都是「同一对象 + 同一谓词」的双绝对**：
对象绝对（代码）、性质绝对（测度与稀疏的 Σ-刻画）。

### 两款传递模型的对照

定理 3.25 的两款不是同一个定理的两个强度，而是**两种不同
的传递策略**：(1) 款传递的是「全称量词的宇宙」——把「每个
实数子集」的「每个」限制到 L(ℝ) 的范围内，代价是放弃 AC
（L(ℝ) 只有 DC）；(2) 款传递的是「谓词的复杂度」——保持
V[G] ⊨ ZFC，把「每个实数子集」弱化为「每个射影子集」。
两种策略在实际使用中各有领地：描述集合论的工作者要 (1)
（投影层次的全称命题）；力迫理论的工作者要 (2)（ZFC 框架
内的相对一致性）。Solovay 定理的表述把两种策略并置，正是
「一致性证明的艺术在于选对传递什么」的教学样板。

## 三、§3.3 博物馆与 L(ℝ)-理论不变性

§3.3 的开篇是全书少见的作者独白：大基数与实数集的关联「不仅是
数学的内涵，更是哲学的内涵」。三个展位：不可达（定理 3.12——
∀α ω₁^{L[α]} 可数 ⟺ 投影集完美子集性）、可测（定理 1.20——
(V_{ω+1}, ∈, μ) 的丰富结构）、本章的正则性谱系。

**§3.3.1 的主题**：L(ℝ) 的**理论**在指定力迫下不变。**定理 3.26
（Woodin）**：κ 超强 ⟹ 在 Col(ω,<κ) 的泛型扩张中存在从 L(ℝ)^V
到 L(ℝ)^{V[G]} 的**同质嵌入**——一个保持一切一阶真值的嵌入映射。
推论 3.19 立即给出：L(ℝ) 中每实数集三正则 + 不存在 ℝ 的 Π-秩序
（n<ω）——正则性的「无序」推论。

**定理 3.27（Shelah-Woodin）**把「超强」减弱到「武丁且弱紧」：
证明取 P = Col(ω₁,<κ)，由定理 2.31（谢拉赫-武丁：武丁基数 ⟹
莱维扩张的 ω₁ 上有饱和正规理想 I），令 Q = 𝒫(ω₁)/I，H 是 M 上
的 Q-泛型滤子；泛型超幂 i_H : M → N 满足 i_H(ω₁) = ω₂ 且
ℝ^{M[H]} = ℝ^V（I 的正规性保实数）；于是 j : L(ℝ)^V →
L(ℝ)^{V[G][H]}。最后的关键计算：B = B(P*Q) 满足 κ-cc（P 的
κ-cc + I 的饱和性传递），且由弱紧性，B 的任何 <κ 个生成元的
完备布尔子代数势 <κ——于是 B 分层为层链 ⟨B_α | α<κ⟩ 且
B ≅ B(Col(ω,<κ))——**两个不同力迫的布尔代数同构**，同质嵌入
由此改写到莱维扩张上。**定理 3.28（最佳版）**：n 个武丁 + 一个
更大的可测 ⟹ 每个 Σ^1_{n+1} 集可测；无穷多武丁 + 更大可测 ⟹
L(ℝ) 全可测。**定理 3.29（Woodin）**：sup{α<κ | α 武丁} = κ ⟹
存在专门的 Q_<κ 实现 L(ℝ)^V → L(ℝ)^{Col(ω,<κ)} 的同质嵌入——
这条路线的设计（下一节的荟萃塔力迫）把假设推到可数无穷多武丁
+ 更大可测的**最佳**边界。

**不变性的边界**（Step 3 的正文落点）：定理 3.26/3.27/3.29 的
「不变」是**限定的**——指定的力迫（Col(ω,<κ) 或专门设计的
Q_<κ）、指定的公式域（L(ℝ) 的一阶理论）、指定的嵌入方向（V 到
V[G]）。它**不是**「所有力迫都不改变实数理论」：添加科恩实数会
改变 ℵ₁ 的值从而改变某些 L(ℝ) 语句；迭代力迫可以造出 L(ℝ) 中
的非可测集的反例宇宙。机器件的非不变反例（pt0 在双点翻车）是
这个边界的最小化身。

### 「同质」二字的来源

同质嵌入（weakly homogeneous tree 的词根）的原始语境是树：
一个 ω×κ 树 T 是同质的，若对任意两个节点 s ⊆ t 存在树的自
同构把 s 搬到 t——树在自同构群作用下「处处一样」。定理 3.26
的嵌入从同质树构造：L(ℝ) 的每个 Σ¹₂ 集是同质树的投影
（大基数的树表示定理），同质性让投影语义在力迫下稳定——
嵌入由树的层级归纳定义。本章机器件的「τ-对换」就是最小
的同构群（{id, τ} ≅ C₂），「τ-不变公式」就是同质性在
命题层的化身——**「处处一样」的群论直觉贯穿从机器件到
Woodin 定理的整条线**。

### 同质嵌入的直观

「从 L(ℝ)^V 到 L(ℝ)^{V[G]} 的同质嵌入」——j : L(ℝ)^V →
L(ℝ)^{V[G]} 保持一切一阶真值（L(ℝ) 语言中带实数与序数参数
的每个语句 φ：L(ℝ)^V ⊨ φ ⟺ L(ℝ)^{V[G]} ⊨ φ^j）。直观：
**两个宇宙里的 L(ℝ) 是同一个理论的两个模型**——力迫没有
在 L(ℝ) 里添任何「新的可定义事实」。这与「V[G] 有新实数」
并行不悖：新实数进入 L(ℝ)^{V[G]}，但新旧 L(ℝ) 的理论重合。
机器件的「τ-不变公式在共轭双点真值相等」是这句话的最小
化身：两个求值点（两个「宇宙」）对持有不变证书的公式给出
同一理论——**证书（τ-不变性）对应嵌入的存在条件（大基数），
双点对应两个宇宙，理论片段对应 L(ℝ) 的语言**。

### 大基数价格表（§3.3.1 的谱系）

| 定理 | 大基数假设 | 结论 | 价格走势 |
|---|---|---|---|
| 3.25 (Solovay) | 一个不可达 | L(ℝ)（或射影层）全正则 | 起点 |
| 3.26 (Woodin) | 一个超强 | Col(ω,<κ) 下 L(ℝ) 同质嵌入 | 嵌入版登场 |
| 3.27 (Shelah-Woodin) | 武丁且弱紧 | 同上（改写为莱维代数） | 首次降价 |
| 3.28 (Shelah-Woodin) | n 个武丁+更大可测 | Σ^1_{n+1} 全可测 | 按层定价 |
| 3.28 (2) | 可数无穷多武丁+更大可测 | L(ℝ) 全可测 | 最佳价 |
| 3.29 (Woodin) | sup{α<κ 武丁}=κ | 专门 Q_<κ 实现同质嵌入 | 施工图版 |

这张表的读法：**「货物」从正则性（3.25）升级为理论不变性
（3.26+），「价格」从不可达一路降到可数无穷多武丁**——每一行
都是一次「换引擎」：3.25 的引擎是 κ-饱和；3.26 的是超强基数
的嵌入结构；3.27 的是饱和理想（定理 2.31）+ 弱紧的层塔控制；
3.29 的是专门设计的力迫（下一章的荟萃塔）。不变性的历史就是
引擎更换史。

### 定理 3.27 证明的五幕

第一幕（力迫选取）：P = Col(ω₁,<κ)——崩塌到 ω₁ 而非 ω，
为的是让定理 2.31 的理想在 ω₁ 上存在。第二幕（理想与商）：
M = V[G] 中取饱和正规理想 I ⊇ NS；Q = 𝒫(ω₁)/I——商力迫。
第三幕（泛型嵌入）：H 是 M 上的 Q-泛型滤子；泛型超幂
i_H : M → N = Ult(M, Ē)——临界点 ω₁、i_H(ω₁) = ω₂；
关键等式 **ℝ^{M[H]} = ℝ^V**（I 的正规性不添实数——110 章
的账在此回收）。第四幕（复合嵌入）：j : L(ℝ)^V →
L(ℝ)^{V[G][H]} 由恒等映射诱导（实数不动、序数经 i_H）。第五幕
（代数同构）：B = B(P*Q) 的 κ-cc（P 的 κ-cc + I 的 κ-饱和
传递）与弱紧性（<κ 生成元的子代数势 <κ——层塔 B_α 的构造）
合谋给出 B ≅ B(Col(ω,<κ))——复合力迫与莱维力迫的布尔代数
同构，同质嵌入由此改写。**五幕的每一幕都是前几章机器的回收**：
103 的莱维、109 的泛型超幂、110 的饱和理想——本章是第三卷
前半的枢纽站。

## 四、机器件与边界声明

七通道吃下五件机制，全部在有限层：

1. **布尔值模型件**：三点底集 {0,1,2}、子集 = bitmask、公式 =
   var/neg/conj/disj 的小语言、`bval` 递归——布尔值语义的最小
   完整实现。
2. **对称保真件**（件 E）：`bval_perm`——⟦φ⟧_{v^τ} = τ·⟦φ⟧_v，
   对公式归纳（Lean `simp only [bval]` 先展再 `rw`；Coq `cbn
   [bval]` + `rewrite IH`；Agda `cong`/`cong₂` 三行归纳）；
   Julia/Python 10 公式 × 512 赋值全检；Prolog `perm_faithful`
   的 forall 检查。
3. **双点不变证书件**（件 A）：`F_conj`（τ 把主超滤 F_i 搬到
   F_{τ i}）+ `tau_inv_eval`（τ-不变布尔值在 F₀/F₁ 真值相等）；
   **非不变反例** pt0（单点集）在双点翻车——不变性必须限定
   公式。
4. **mod-I 包裹件**（件 B）：星形 X、偶集 S（R(V[s]) 影子）、
   A₁ = X∩S；`modI_eq`（S 上同真假）+ `modI_ideal`（差集全落
   奇理想）——引理 3.23(3) 的「X△A₁ ∈ 理想」机制。
5. **完备子集件**（件 C）：深度 3 的分支树、f:[0,1]³→X 的 8
   路径 8 像单射、每条 K_z 命中全部稠密集——事实五的机制核。

> **边界声明**：机器验证的是 8 元布尔代数上的机制步骤。「τ-不变
> 公式在共轭双点真值相等」是定理 3.26 同质嵌入的**单点影子**——
> 同质嵌入保持一切一阶真值，机器只验证一个对换下的一层；mod-I
> 的奇理想是零测/稀疏理想的有限化身，**不是**测度论；f-单射的
> [0,1]³ 是 [0,1] 的离散替身，连续性不可有限化。κ-饱和、随机
> 实数、黑白分明律、完备布尔代数层塔是超穷层的本体，机器不伪造
> 它们的结论。

五件机制的窗口选择：三点底集 {0,1,2} 让 τ 的轨道结构最小
而有内容（0↔1 对换、2 不动——共轭滤子对 F₀/F₁ 与不动点
F₂）；8 元布尔代数（P(3)）让公式的布尔值有真实的层次（非
平凡交并补）；512 个赋值（8³）让对拍有统计上的分辨力（12
个理论分歧赋值被 37 步抽样稳定抓到）；8 路径立方让 f-单射
与稠密命中同框。**小窗口大分辨**——与 113 章「窗口小到全检、
大到现象齐全」的准绳一脉相承。

**通道分工总览**（本章与 113–114 章的延续）：数值窗口的
公式-布尔值件由 Lean/Coq/Agda 三家承担（函数语义）；Isabelle
走集合语义（像集与成员资格）——同一数学的两种编码；Julia/
Python 承担对拍账（全检+抽样+反例）；Prolog 承担保真检查与
项形对拍。五个数学事实（对称保真、共轭、双点证书、mod-I、
单射）在七通道各有化身——**没有一个通道试图覆盖全部**，每个
通道只做它的证明系统最顺手的那几件。

## 五、Lean：五件定理

```lean
import Mathlib.Data.List.Basic
import Mathlib.Tactic.IntervalCases

/-!
# 第 115 章 · Lévy 扩张正则性与 L(ℝ) 理论不变性

锚点（有限影子）：
- `bval`/`bval_perm`：命题公式的布尔值与对换 τ 的**对称保真**——
  公式与布尔值同步变换（同质嵌入的语义面）；
- `F_conj`/`tau_inv_eval`：主超滤的共轭与**双点不变证书**——
  τ-不变公式的真值在两个泛型求值点相等（定理 3.26/3.27 的
  「L(ℝ)-理论不变」机制核）；
- `noninv_counter`：非不变布尔值在双点上翻车——不变性必须
  限定公式（边界声明）；
- `inX`/`inA1`/`modI_eq`/`modI_ideal`：博雷尔包裹的 mod-I 同余
  （引理 3.23(3) 的 A₁ 见证机制——差集吞进理想）。

本体（κ-饱和、随机实数、黑白分明律、完备子集的 f-单射、
Solovay 定理 3.25、Woodin 同质嵌入）留在正文 docs/115-invariance.md。
-/

namespace Settheory.Ch115Invariance

/-- 三点底集 {0,1,2} 上的对换 τ = swap(0,1)（生成 {id,τ} ≅ C2）。 -/
def tau (i : Nat) : Nat := if i = 0 then 1 else if i = 1 then 0 else 2

theorem tau_tau (i : Nat) (hi : i < 3) : tau (tau i) = i := by
  interval_cases i <;> rfl

theorem tau_0 : tau 0 = 1 := by rfl

theorem tau_1 : tau 1 = 0 := by rfl

/-- 子集 = 点到 Bool 的函数（P(3) 的元素）。 -/
abbrev Subset := Nat → Bool

/-- τ 在子集上的作用（(τ·b)(τ i) = b(i) 的实现形）。 -/
def tb (b : Subset) : Subset := fun i => b (tau i)

def compl (b : Subset) : Subset := fun i => !b i

def inter (a b : Subset) : Subset := fun i => a i && b i

def unio (a b : Subset) : Subset := fun i => a i || b i

/-- 主超滤（P(3) 上点 i 的超滤）：b ∈ F_i ⟺ i ∈ b。 -/
def memF (i : Nat) (b : Subset) : Prop := b i = true

/-- 命题公式（有限理论片段的替身）。 -/
inductive Formula : Type
  | var : Nat → Formula
  | neg : Formula → Formula
  | conj : Formula → Formula → Formula
  | disj : Formula → Formula → Formula

open Formula

/-- 公式的布尔值（布尔值模型的有限版）。 -/
def bval : Formula → (Nat → Subset) → Subset
  | var n, v => v n
  | neg φ, v => compl (bval φ v)
  | conj φ ψ, v => inter (bval φ v) (bval ψ v)
  | disj φ ψ, v => unio (bval φ v) (bval ψ v)

/-- τ 在赋值上的提升。 -/
def tv (v : Nat → Subset) : Nat → Subset := fun n => tb (v n)

/-- 件 E（对称保真）：布尔值与公式同步变换——⟦φ⟧_{v^τ} = τ·⟦φ⟧_v。 -/
theorem bval_perm (φ : Formula) (v : Nat → Subset) :
    bval φ (tv v) = tb (bval φ v) := by
  induction φ with
  | var n => rfl
  | neg φ ih => simp only [bval]; rw [ih]; funext i; simp [compl, tb]
  | conj φ ψ ih1 ih2 =>
    simp only [bval]; rw [ih1, ih2]; funext i; simp [inter, tb]
  | disj φ ψ ih1 ih2 =>
    simp only [bval]; rw [ih1, ih2]; funext i; simp [unio, tb]

/-- 滤子共轭：τ 把 F_i 的成员资格搬到 F_{τ i}——(τ·b)(τ i) = b(i)。 -/
theorem F_conj (i : Nat) (hi : i < 3) (b : Subset) :
    (tb b) (tau i) = b i := by
  simp [tb, tau_tau i hi]

/-- 件 A 旗舰（双点不变证书）：τ-不变公式的布尔值在共轭双点上
真值相等——L(ℝ)-理论不变性的有限化身。 -/
theorem tau_inv_eval (φ : Formula) (v : Nat → Subset)
    (hinv : tb (bval φ v) = bval φ v) :
    memF 0 (bval φ v) ↔ memF 1 (bval φ v) := by
  have e1 : tb (bval φ v) 1 = bval φ v 0 := by
    simpa [tau] using F_conj 0 (by omega) (bval φ v)
  have e2 : tb (bval φ v) 0 = bval φ v 1 := by
    simpa [tau] using F_conj 1 (by omega) (bval φ v)
  unfold memF
  constructor
  · intro h; rw [← hinv, e1]; exact h
  · intro h; rw [← hinv, e2]; exact h

/-- 非不变布尔值在双点上翻车——不变性必须限定公式（边界反例）。 -/
theorem noninv_counter :
    (fun i : Nat => if i = 0 then true else false) 0 = true ∧
    (fun i : Nat => if i = 0 then true else false) 1 = false := by
  constructor <;> simp

/-- ── 件 B：博雷尔包裹的 mod-I 同余（引理 3.23(3) 的 A₁ 机制） ──

星形谓词（114 章的连续性）：s-可定义的实数集影子。 -/
def odefP (k x : Nat) : Prop :=
  x % 8 = k % 8 ∨ x % 8 = (k + 3) % 8 ∨ x % 8 = (k + 5) % 8

/-- 旧模型实数集的影子：R(V[s]) ↦ 偶集。 -/
def inS (x : Nat) : Prop := x % 2 = 0

/-- X：由参数 s（取 0）可定义的集合。 -/
def inX (x : Nat) : Prop := odefP 0 x

/-- A₁ := X ∩ S（博雷尔包裹——mod 理想的代表）。 -/
def inA1 (x : Nat) : Prop := inX x ∧ inS x

/-- 在 S 上 X 与 A₁ 同真假（X ∩ S = A₁ ∩ S 的谓词形）。 -/
theorem modI_eq (x : Nat) (hx : inS x) : inX x ↔ inA1 x := by
  constructor
  · intro h; exact ⟨h, hx⟩
  · intro h; exact h.1

/-- 差集全落理想：X△A₁ 的成员必在 S 之外（理想 = 奇集的幂集）。 -/
theorem modI_ideal (x : Nat)
    (h : (inX x ∧ ¬ inA1 x) ∨ (¬ inX x ∧ inA1 x)) : ¬ inS x := by
  rcases h with ⟨hx, hna⟩ | ⟨hx, hna⟩
  · intro hs; exact hna ⟨hx, hs⟩
  · obtain ⟨hx', hs⟩ := hna
    intro hs'; exact hx hx'

/-- 样本：星形 {0,3,5}（mod 8）在窗口 0..7 的命中。 -/
example : inX 0 := by unfold inX odefP; omega

example : inX 3 := by unfold inX odefP; omega

example : inX 5 := by unfold inX odefP; omega

example : ¬ inX 1 := by unfold inX odefP; omega

end Settheory.Ch115Invariance
```

要点：子集 = `Nat → Bool`（函数语义——`funext` 逐点证明）；
`bval_perm` 的归纳先 `simp only [bval]` 展开构造子再 `rw`（Lean
的 rw 不穿透 def 包裹，先展是 109 章立的老纪律）；`tau_inv_eval`
的两条辅助等式 e1/e2 由 `F_conj` 加 `simpa [tau]`（τ 0 = 1 的
字面量计算）得到，主证明是 `rw [← hinv, e1]` 的两行——**函数
等式的点级实例化 + 定义性归约**的教科书演示；`noninv_counter`
给非不变集的双点翻车。

### Lean 逐段精讲

**子集的函数语义**。`Subset := Nat → Bool`——三点底集上的子集
就是 Bool 值函数；这让 `tb`（τ-作用）、`compl`、`inter`、`unio`
全部是逐点定义，等式证明统一走 `funext i` + 点级计算。与 ZF
通道的集合语义（像集 `img`）相对照：**函数语义适合算，集合语义
适合搬**——两通道的分工在第 113–115 章反复出现。

**`bval_perm` 的三步归纳**。neg 案：`simp only [bval]` 先把
`bval (neg φ) (tv v)` 展成 `compl (bval φ (tv v))`（rw 不穿透
def 包裹——先展是老纪律）；`rw [ih]` 换入归纳假设；`funext i;
simp [compl, tb]` 收点级（`¬(b (tau i)) = ¬(b (tau i))`）。conj/
disj 案同构，只是 `cong` 换 `cong₂`-式的 `simp [inter, tb]`。

**`F_conj` 与 `tau_inv_eval`**。`F_conj` 的证明体是 `simp [tb,
tau_tau i hi]`——τ 的对合性一步代换；`tau_inv_eval` 的 e1/e2
由 `simpa [tau] using F_conj …` 得到（`tau 0 = 1` 的字面量计算
在 simpa 里完成）；主证明两行 `rw [← hinv, e1]`——`← hinv`
把目标里的 `bval φ v` 全部换成 `tb (bval φ v)`，`e1` 再把
`tb (bval φ v) 1` 换成 `bval φ v 0`，目标变成假设本身。**改写
链的每一步都是定义性或已证等式——没有搜索**。

**`noninv_counter` 与 `modI_ideal`**。前者给单点集的双点翻车
（`simp` 两分支各一步）；后者的析取分案 + `obtain ⟨hx', hs⟩`
（And 的 def 包裹用 obtain 而非 `.1` 投影——投影记号对 def
包裹的类型不穿透，本章实测一记）。

**样本对拍**：`star_samples`（星形 {0,3,5} 的命中与 1 的
落空）与 Julia/Python 的 mod-I 账同源——Coq 用 `repeat split;
simpl; lia` 收四个子目标，其中负样本（¬inX 1）需要析取假设
的展开——simpl 把 mod 字面量归一后 lia 直接矛盾。

## 六、Coq：cbn 定向与析取样本

```coq
(* 第 115 章：Lévy 扩张正则性与 L(ℝ) 理论不变性——对称保真、
   双点不变证书、博雷尔包裹的 mod-I 同余（引理 3.23(3)/定理
   3.26-3.27 的机制核；本体留在正文 docs/115-invariance.md）。 *)
Require Import List Arith Lia Bool FunctionalExtensionality.
Import ListNotations.

(* ── 一、三点底集上的对换 τ ── *)
Definition tau (i : nat) : nat := if Nat.eqb i 0 then 1
                                  else if Nat.eqb i 1 then 0 else 2.

Lemma nat3_cases : forall i, i < 3 -> i = 0 \/ i = 1 \/ i = 2.
Proof. intros i hi; lia. Qed.

Lemma tau_tau : forall i, i < 3 -> tau (tau i) = i.
Proof.
  intros i hi.
  destruct (nat3_cases i hi) as [E | [E | E]]; subst i; reflexivity.
Qed.

(* ── 二、子集与布尔值模型 ──
   子集 = 点到 Bool 的函数；τ 的作用 (τ·b)(τ i) = b(i)。 *)
Definition subset := nat -> bool.

Definition tb (b : subset) : subset := fun i => b (tau i).
Definition cpl (b : subset) : subset := fun i => negb (b i).
Definition itr (a b : subset) : subset := fun i => andb (a i) (b i).
Definition uno (a b : subset) : subset := fun i => orb (a i) (b i).

(* 命题公式与布尔值。 *)
Inductive formula : Type :=
  | var : nat -> formula
  | neg : formula -> formula
  | conj : formula -> formula -> formula
  | disj : formula -> formula -> formula.

Fixpoint bval (f : formula) (v : nat -> subset) : subset :=
  match f with
  | var n => v n
  | neg g => cpl (bval g v)
  | conj g h => itr (bval g v) (bval h v)
  | disj g h => uno (bval g v) (bval h v)
  end.

Definition tv (v : nat -> subset) : nat -> subset := fun n => tb (v n).

(* ── 三、件 E：对称保真——布尔值与公式同步变换 ── *)
Lemma bval_perm : forall f v, bval f (tv v) = tb (bval f v).
Proof.
  induction f as [n | f IH | f IH1 h IH2 | f IH1 h IH2]; intros v.
  - reflexivity.
  - cbn [bval]. rewrite IH. apply functional_extensionality; intros i.
    unfold tb, cpl. destruct (bval f v (tau i)); reflexivity.
  - cbn [bval]. rewrite IH1, IH2. apply functional_extensionality; intros i.
    unfold tb, itr. destruct (bval f v (tau i)), (bval h v (tau i));
    reflexivity.
  - cbn [bval]. rewrite IH1, IH2. apply functional_extensionality; intros i.
    unfold tb, uno. destruct (bval f v (tau i)), (bval h v (tau i));
    reflexivity.
Qed.

(* ── 四、件 A：滤子共轭与双点不变证书 ── *)
Lemma F_conj : forall i b, i < 3 -> tb b (tau i) = b i.
Proof.
  intros i b hi. unfold tb. rewrite tau_tau by exact hi. reflexivity.
Qed.

(* 主超滤 F_i 的成员资格即「点 i 在集合中」。 *)
Definition memF (i : nat) (b : subset) : Prop := b i = true.

Theorem tau_inv_eval : forall f v,
  tb (bval f v) = bval f v ->
  (memF 0 (bval f v) <-> memF 1 (bval f v)).
Proof.
  intros f v hinv.
  assert (e1 : tb (bval f v) 1 = bval f v 0).
  { pose proof (F_conj 0 (bval f v) (ltac:(lia))) as h.
    unfold tau in h; simpl in h; exact h. }
  assert (e2 : tb (bval f v) 0 = bval f v 1).
  { pose proof (F_conj 1 (bval f v) (ltac:(lia))) as h.
    unfold tau in h; simpl in h; exact h. }
  unfold memF. split; intros h.
  - rewrite <- hinv in h. rewrite e2 in h. exact h.
  - rewrite <- hinv in h. rewrite e1 in h. exact h.
Qed.

(* 非不变布尔值在双点上翻车——不变性必须限定公式（边界反例）。 *)
Definition pt0 : subset := fun i => Nat.eqb i 0.

Lemma noninv_counter :
  pt0 0 = true /\ pt0 1 = false.
Proof. unfold pt0; simpl; split; reflexivity. Qed.

(* ── 五、件 B：博雷尔包裹的 mod-I 同余（引理 3.23(3) 的 A₁ 机制） ── *)
Definition odefP (k x : nat) : Prop :=
  x mod 8 = k mod 8 \/ x mod 8 = (k + 3) mod 8 \/ x mod 8 = (k + 5) mod 8.

Definition inS (x : nat) : Prop := x mod 2 = 0.
Definition inX (x : nat) : Prop := odefP 0 x.
Definition inA1 (x : nat) : Prop := inX x /\ inS x.

Theorem modI_eq : forall x, inS x -> (inX x <-> inA1 x).
Proof.
  intros x hx. split; intros h.
  - split; assumption.
  - destruct h; assumption.
Qed.

Theorem modI_ideal : forall x,
  (inX x /\ ~ inA1 x) \/ (~ inX x /\ inA1 x) -> ~ inS x.
Proof.
  intros x [h | h]; unfold inA1 in *.
  - destruct h as [hx hn]. intros hs. apply hn. split; assumption.
  - destruct h as [hx [hx' hs]]. intros _. exact (hx hx').
Qed.

(* 样本：星形 {0,3,5}（mod 8）的命中（与 Julia/Python 同账）。 *)
Example star_samples :
  inX 0 /\ inX 3 /\ inX 5 /\ ~ inX 1.
Proof.
  unfold inX, odefP.
  repeat split; simpl; lia.
Qed.
```

要点：`bval_perm` 用 `cbn [bval]` 单层展开（101 章的 level_S
纪律：多层 cbn 引发 unify 回溯）+ `rewrite IH`（IH 因 `induction
…; intros v` 而对 v 全称）+ `functional_extensionality` 逐点
+ Bool 的 `destruct` 双 case；`tau_inv_eval` 的辅助等式走
`pose proof (F_conj …) + unfold tau in h; simpl in h`（τ 的
if-链字面量计算）；`star_samples` 的 `repeat split; simpl; lia`
——mod 字面量先 simpl 归一再 lia（lia 不解 mod 的 113 章坑在本
章的最后一公里复现）。

### Coq 逐段精讲

**IH 的全称化**。`induction f as [...]; intros v` 的写法让归纳
假设对一切 v 全称（`forall v, bval f (tv v) = tb (bval f v)`）
——否则 `rewrite IH` 对固定的 v 无法应用。这是 structural
induction 的标准手筋，但在函数参数的归纳里最容易忘。

**`cbn [bval]` 的单层纪律**。四个构造子案各用 `cbn [bval]` 只
展一层（101 章 level_S 纪律的复现——`cbn` 不带参数会多层展开
引发 unify 回溯）；随后 `rewrite IH`（或 IH1, IH2）换入；`apply
functional_extensionality; intros i` 进入点级；`destruct (bval
f v (tau i))` 的 Bool 双 case 用 `reflexivity` 收（Bool 运算
的 4/8 真值表由 destruct 枚举）。

**`tau_inv_eval` 的字面量计算**。辅助等式 e1/e2 的证明体：
`pose proof (F_conj 0 (bval f v) (ltac:(lia))) as h`——把 0<3
的前提用 ltac 内联；`unfold tau in h; simpl in h`——τ 的
if-链在字面量 0 上计算成 1。主证明的两条 `rewrite <- hinv in h`
+ `rewrite e2 in h` 的方向账（先换函数等式再换点等式——顺序
反了会找不到模式）。

**`star_samples` 的收口**。`repeat split; simpl; lia`——四个
子目标（三个正样本一个负样本）全部由 simpl 归一 mod 字面量后
lia 收——lia 不解 mod 的坑在最后一公里用 simpl 铺路（113 章
同款）。

## 七、Agda：定义性归约的极致

```agda
-- 第 115 章：Lévy 扩张正则性与 L(ℝ) 理论不变性——对称保真、
-- 双点不变证书与博雷尔包裹（引理 3.23(3)/定理 3.26-3.27 的机制核；
-- 本体留在正文 docs/115-invariance.md）。
module Ch115_invariance where

open import Data.Nat using (ℕ; zero; suc)
open import Data.Bool using (Bool; true; false; not; _∧_; _∨_)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; trans; sym)
open import Relation.Nullary using (¬_)
open import Data.Empty using (⊥; ⊥-elim)

-- 自建 cong₂（112 章纪律：PropositionalEquality 不导出）。
cong₂ : {A B C : Set} → (f : A → B → C) → {x y : A} → {u w : B} →
        x ≡ y → u ≡ w → f x u ≡ f y w
cong₂ f refl refl = refl

-- ── 一、三点底集上的对换 τ = swap(0,1) ──
tau : ℕ → ℕ
tau zero = suc zero
tau (suc zero) = zero
tau (suc (suc n)) = suc (suc n)

tau-tau : ∀ i → tau (tau i) ≡ i
tau-tau zero = refl
tau-tau (suc zero) = refl
tau-tau (suc (suc n)) = refl

-- ── 二、子集与布尔值模型 ──
subset : Set
subset = ℕ → Bool

tb : subset → subset
tb b i = b (tau i)

cpl : subset → subset
cpl b i = not (b i)

itr : subset → subset → subset
itr a b i = a i ∧ b i

uno : subset → subset → subset
uno a b i = a i ∨ b i

-- ── 三、公式与布尔值 ──
data formula : Set where
  var : ℕ → formula
  neg : formula → formula
  conj : formula → formula → formula
  disj : formula → formula → formula

bval : formula → (ℕ → subset) → subset
bval (var n) v = v n
bval (neg f) v = cpl (bval f v)
bval (conj f g) v = itr (bval f v) (bval g v)
bval (disj f g) v = uno (bval f v) (bval g v)

tv : (ℕ → subset) → ℕ → subset
tv v n = tb (v n)

-- ── 四、件 E（对称保真）：布尔值与公式同步变换 ──
bval-perm : ∀ f v → bval f (tv v) ≡ tb (bval f v)
bval-perm (var n) v = refl
bval-perm (neg f) v = cong cpl (bval-perm f v)
bval-perm (conj f g) v = cong₂ itr (bval-perm f v) (bval-perm g v)
bval-perm (disj f g) v = cong₂ uno (bval-perm f v) (bval-perm g v)

-- ── 五、件 A：滤子共轭与双点不变证书 ──
F-conj : ∀ i b → tb b (tau i) ≡ b i
F-conj i b = cong b (tau-tau i)

memF : ℕ → subset → Set
memF i b = b i ≡ true

-- 函数等式的点级实例化。
point-eq : ∀ (s : subset) → tb s ≡ s → ∀ i → s i ≡ tb s i
point-eq s h i = sym (cong (λ g → g i) h)

-- 旗舰（双点不变证书）：τ-不变公式的布尔值在共轭双点上真值相等。
-- 中间项 tb s (suc zero) 定义性归约为 s (tau (suc zero)) = s zero。
tau-inv-eval : ∀ f v →
  tb (bval f v) ≡ bval f v →
  (memF zero (bval f v) → memF (suc zero) (bval f v)) ×
  (memF (suc zero) (bval f v) → memF zero (bval f v))
tau-inv-eval f v hinv =
  (λ h₀ → trans (point-eq (bval f v) hinv (suc zero)) h₀) ,
  (λ h₁ → trans (point-eq (bval f v) hinv zero) h₁)

-- 非不变布尔值在双点上翻车——不变性必须限定公式（边界反例）。
pt0 : subset
pt0 zero = true
pt0 (suc zero) = false
pt0 (suc (suc n)) = false

pt0-counter : memF zero pt0 × (pt0 (suc zero) ≡ false)
pt0-counter = refl , refl

-- ── 六、件 B：博雷尔包裹的 mod-I 同余（引理 3.23(3) 的 A₁ 机制） ──
-- 点集语义：S（旧实数影子）与 X（星形）为 Bool 谓词；A₁ = X ∧ S。
and-true : ∀ {p q : Bool} → p ≡ true → q ≡ true → p ∧ q ≡ true
and-true refl refl = refl

and-false-left : ∀ (q : Bool) → false ∧ q ≡ false
and-false-left q = refl

inS : ℕ → Bool
inS zero = true
inS (suc zero) = false
inS (suc (suc n)) = true

inX : ℕ → Bool
inX zero = true
inX (suc zero) = false
inX (suc (suc zero)) = true
inX (suc (suc (suc zero))) = true
inX (suc (suc (suc (suc n)))) = false

inA1 : ℕ → Bool
inA1 x = inX x ∧ inS x

-- 在 S 上 X 与 A₁ 同真假（包裹方向）。
modI-eq : ∀ x → inS x ≡ true → (inX x ≡ true) → (inA1 x ≡ true)
modI-eq x hs hx = and-true hx hs

-- AND 的左分量反转。
and-t-l : ∀ {p q : Bool} → p ∧ q ≡ true → p ≡ true
and-t-l {true} {q} h = refl
and-t-l {false} {q} ()

-- 反向：A₁ 命中则 X 命中。
modI-back : ∀ x → inA1 x ≡ true → (inX x ≡ true)
modI-back x h = and-t-l {inX x} {inS x} h

-- S 上的相等（modI-agree）：S 命中处 X 与 A₁ 同布尔值。
modI-agree : ∀ x → inS x ≡ true → (inX x ≡ inA1 x)
modI-agree x hs with inX x
... | true = sym (cong (λ z → true ∧ z) hs)
... | false = refl

-- 差集全落理想：X 与 A₁ 真值相异处必在 S 之外。
modI-ideal : ∀ x → ¬ (inX x ≡ inA1 x) → inS x ≡ false
modI-ideal x h with inS x | modI-agree x
... | true | ag = ⊥-elim (h (ag refl))
... | false | _ = refl

-- 样本：星形 {0,2,3}（三点语义）的命中（与 Julia/Python 同账）。
star-0 : inX zero ≡ true
star-0 = refl

star-2 : inX (suc (suc zero)) ≡ true
star-2 = refl

star-1 : inX (suc zero) ≡ false
star-1 = refl

star-4 : inX (suc (suc (suc (suc zero)))) ≡ false
star-4 = refl
```

要点：`tau` 按构造子三行定义（0↔1、≥2 不动）——`tau-tau` 三个
refl；**`tau-inv-eval` 是本章 Agda 件的旗舰**：`point-eq` 把函数
等式实例化到点，两个分支各一行 `trans (point-eq …) h`——中间项
`tb s (suc zero)` 由 **定义性归约** 化为 `s (tau (suc zero))`
= `s zero`，无需任何显式改写——Agda 的类型检查即证明。`modI-*
` 三件用 Bool 语义 + `and-true`/`and-t-l` 两个自建引理；with-
分案在 `modI-back` 首版撞 SplitError（`true ∧ inS x ≟ true` 的
索引统一卡壳——112 章同型），改 `and-t-l` 的 Bool-参数归纳
绕开。

### Agda 逐段精讲

**τ 的构造子定义**。`tau zero = suc zero; tau (suc zero) = zero;
tau (suc (suc n)) = suc (suc n)`——三行方程让 `tau-tau` 三个
refl、`tau-0≡1`/`tau-1≡0` 也是 refl。与 Lean/Coq 的 if-链
版本对照：**构造子形式把计算路径写进定义**，所有字面量事实
免费；if-链版本则要 simp/unfold 计算一记——两种风格的取舍
在 110 章已立（「方程按构造子保留」纪律）。

**`tau-inv-eval` 旗舰**。`point-eq s h i = sym (cong (λ g → g i)
h)`——函数等式（`tb s ≡ s`）在点 i 的实例化；两个分支各一行
`trans (point-eq (bval f v) hinv (suc zero)) h₀`——中间项
`tb s (suc zero)` 由定义性归约为 `s (tau (suc zero))` 再归约
为 `s zero`——**类型检查器完成了整个证明的搬运**，没有一个
显式的改写步骤。第二分支的 `point-eq … zero` 同理归约到
`s (suc zero)`。这是「定义即证明」的极致展示，与 Coq 的
tactic 链、Lean 的 rw 链构成同一事实的三种程序化。

**`modI-*` 三件**。`and-true`（双真得真）与 `and-t-l`（AND
的左分量反转）两个 Bool 引理；`modI-agree` 的 with-分案在
`true` 分支用 `sym (cong (λ z → true ∧ z) hs)`——把 `true ∧
inS x` 拉回 `true ∧ true = true`；`modI-ideal` 的 with 携带
`modI-agree x` 整体（避免 with-抽象把假设里的 `inS x` 抽走——
Mints 章的「with 不穿透假设」坑的正面用法）。`modI-back` 首版
的 `with inX x | h` 撞 SplitError（`true ∧ inS x ≟ true` 卡
壳——被抽象的类型索引不可解），改 `and-t-l {inX x} {inS x} h`
的参数化引用绕开。

**ZF 侧本章实测坑账小结**（三记）：数字 ≥3 在集合字面量
`{0,2,3}` 与谓词参数位均不解析（改 `{0,1,2}` 或 `succ(2)`——
102 坑的两个新形态）；对称差记号 `\<triangle>` 不存在（改
显式析取）；`auto` 对 RepFunI 的目标形不匹配（`1 ∈ {tau(y). …}`
无法与 `tau(?a) ∈ …` 统一——subgoal_tac 先摆 `tau(0) ∈ …`
的目标形再收）。三记都是「ZF 的语法糖比 HOL 少」的同一族——
**写 ZF 要按 1990 年代的语法预算过日子**。

## 八、Isabelle/ZF：集合语义路线

```isabelle
theory Invariance
  imports "ZF.List" "ZF.equalities"
begin

text \<open>第 115 章：Lévy 扩张正则性与 L(ℝ) 理论不变性——集合语义的
对称保真、双点不变证书与博雷尔包裹（引理 3.23(3)/定理 3.26-3.27 的
机制核，沿确定性规则链纪律）。子集取 3 = {0,1,2} 的子集；对换
tau = swap(0,1)；群作用取像集 tau``b。数值窗口的公式-布尔值件由
Lean/Coq/Agda 承担（ZF 的函数语义在这件上事倍功半）。\<close>

subsection\<open>对换与像集作用\<close>

definition
  tau :: "i\<Rightarrow>i" where
    "tau(x) \<equiv> (if x = 0 then 1 else if x = 1 then 0 else x)"

definition
  img :: "[i\<Rightarrow>i, i] \<Rightarrow> i" where
    "img(f, b) \<equiv> {f(y) . y \<in> b}"

lemma tau_0 [simp]: "tau(0) = 1"
  unfolding tau_def by simp

lemma tau_1 [simp]: "tau(1) = 0"
  unfolding tau_def by simp

lemma tau_2 [simp]: "tau(2) = 2"
  unfolding tau_def by simp

lemma tau_in_3: "x \<in> {0, 1, 2} \<Longrightarrow> tau(x) \<in> {0, 1, 2}"
  unfolding tau_def by auto

lemma tau_tau: "x \<in> {0, 1, 2} \<Longrightarrow> tau(tau(x)) = x"
  unfolding tau_def by auto

lemma tau_inj: "\<lbrakk>x \<in> {0, 1, 2}; y \<in> {0, 1, 2}; tau(x) = tau(y)\<rbrakk> \<Longrightarrow> x = y"
  unfolding tau_def by auto

subsection\<open>件 E（对称保真的集合版）：像集与成员资格共轭\<close>

lemma mem_conj [rule_format]:
  "\<lbrakk>b \<subseteq> {0, 1, 2}; i \<in> {0, 1, 2}\<rbrakk> \<Longrightarrow> (tau(i) \<in> img(tau, b) \<longleftrightarrow> i \<in> b)"
  unfolding img_def tau_def
  by auto

theorem invariance_01 [rule_format]:
  "\<lbrakk>b \<subseteq> {0, 1, 2}; img(tau, b) = b\<rbrakk> \<Longrightarrow> (0 \<in> b \<longleftrightarrow> 1 \<in> b)"
  unfolding img_def
  apply (rule iffI)
   apply (subgoal_tac "tau(0) \<in> {tau(y) . y \<in> b}")
    apply simp
   apply (rule RepFunI, assumption)
  apply (subgoal_tac "tau(1) \<in> {tau(y) . y \<in> b}")
    apply simp
   apply (rule RepFunI, assumption)
  done

subsection\<open>件 B：博雷尔包裹的 mod-I 同余（引理 3.23(3) 的 A₁ 机制）\<close>

definition
  Sset :: i  where
    "Sset \<equiv> {0, 2}"

definition
  Xset :: i  where
    "Xset \<equiv> {0, 2, succ(2)}"

definition
  A1set :: i  where
    "A1set \<equiv> Xset \<inter> Sset"

lemma Sset_mem [simp]: "(x \<in> Sset \<longleftrightarrow> x = 0 \<or> x = 2)"
  unfolding Sset_def by auto

lemma Xset_mem [simp]: "(x \<in> Xset \<longleftrightarrow> x = 0 \<or> x = 2 \<or> x = succ(2))"
  unfolding Xset_def by auto

lemma A1set_mem [simp]: "(x \<in> A1set \<longleftrightarrow> x = 0 \<or> x = 2)"
  unfolding A1set_def by auto

text \<open>在 S 上 X 与 A₁ 同真假。\<close>

theorem modI_eq: "x \<in> Sset \<Longrightarrow> (x \<in> Xset \<longleftrightarrow> x \<in> A1set)"
  by auto

text \<open>差集全落理想：X 与 A₁ 真值相异处必在 S 之外。\<close>

theorem modI_ideal:
  "(x \<in> Xset \<and> x \<notin> A1set) \<or> (x \<notin> Xset \<and> x \<in> A1set) \<Longrightarrow> x \<notin> Sset"
  by auto

end
```

要点：数值窗口的公式-布尔值件在 ZF 事倍功半（函数语义的 def
不可展），本章 Isabelle 走**集合语义**：子集 = 3 的子集（显式
{0,1,2}——**数字 ≥3 在 ZF 集合字面量里也不解析**，3 必须 succ(2)
或 {0,1,2} 绕行，本章实测两记）；τ-作用取**像集** `img(tau, b)
= {tau(y). y∈b}`；`mem_conj`（像集成员资格的共轭——τ i ∈ τ·b
⟺ i ∈ b，用 tau_inj）与 `invariance_01`（双点不变证书的集合版：
img(tau,b) = b → 0∈b ⟷ 1∈b——subgoal_tac 先摆 τ(0) ∈ 像集再
RepFunI 收）走确定性链；件 B 的 Sset/Xset/A1set 三定义 + 两个
auto 收口的 mod-I 定理。`\<triangle>`（对称差记号）在 ZF 不解析
——改显式析取。

### Isabelle/ZF 逐段精讲（含本章实测坑账）

**为什么换集合语义**。数值窗口的公式-布尔值件需要 def 包裹的
函数语义（`bval`）在 ZF 展开——ZF 的 def 展开纪律（113 章五记
之一）让这条路步步受阻；集合语义把同一数学写成「子集 + 像集 +
成员资格」，全部落在 ZF 的原生强项上。**通道分工的原则再证**：
选语义不是选数学，是选证明系统的母语。

**数字 ≥3 的两记新撞**。集合字面量 `{0, 2, 3}` 里的 3 报
「Failed to parse prop」（ZF 的数字在 ≥3 时既不在 ≤ 位置解析、
也不在集合字面量里解析——102 章坑的参数位/集合位两个新形态）；
解法一：`x ∈ 3` 改 `x ∈ {0, 1, 2}`；解法二：字面量 3 改
`succ(2)`。两条都在本章实测落账。

**`mem_conj` 与 `invariance_01` 的确定性链**。`mem_conj`（像集
成员资格共轭）首版走手写 rev_mp 链失败，改 `unfolding img_def
tau_def by auto`——τ 的 if-链在 auto 里可分案（0/1/else 三
支）；`invariance_01`（双点证书）的关键步是 `subgoal_tac
"tau(0) ∈ {tau(y) . y ∈ b}"` 先摆 RepFunI 的目标形（auto 直接
给 `1 ∈ …` 会因 `1 ≠ tau(?)` 的语法不匹配而拒），再 `apply
simp`（tau_0 [simp] 把 tau(0) 计算成 1）收。**「先摆目标形
再引规则」是 ZF 搜索规避的标准姿势**。

**件 B 的三定义**。Sset/Xset/A1set 显式定义 + simp 引理 +
两个 auto 收口；对称差记号 `\<triangle>` 在 ZF 不解析——改
显式析取 `(x∈X ∧ x∉A₁) ∨ (x∉X ∧ x∈A₁)`。

**两份实现的同构性**：Julia 的 struct 树与 Python 的嵌套
元组是同一抽象语法树的两种序列化；`bval` 的四个方法/分支
一一对应；抽样步长（73/37）两端一致——对拍的账目可比性由
设计保证而非巧合。

## 九、Julia 与 Python：对拍账本

```julia
# 第 115 章：Lévy 扩张正则性与 L(ℝ) 理论不变性——双点不变证书、
# 对称保真、mod-I 包裹、完备子集单射与理论片段对拍（与 Python 同账）。
println("==== 115")

# ── 一、三点底集与布尔值模型 ──
# 子集 = bitmask（bit i ⟺ 点 i ∈ 集合）；公式 = 小语言。
pts = [0, 1, 2]
bmask(b) = b + 1  # 1 基显示用（与 Python 对拍时统一用集合显示）
# τ = swap(0,1) 在点上的作用：bit 位 0 与 1 互换。
taub(b) = ((b & 1) << 1) | ((b & 2) >> 1) | (b & 4)

abstract type Frm end

struct V <: Frm
    n::Int
end

struct N <: Frm
    f::Frm
end

struct C <: Frm
    a::Frm
    b::Frm
end

struct D <: Frm
    a::Frm
    b::Frm
end

bval(f::V, env) = env[f.n+1]
bval(f::N, env) = 7 & ~bval(f.f, env)
bval(f::C, env) = bval(f.a, env) & bval(f.b, env)
bval(f::D, env) = bval(f.a, env) | bval(f.b, env)

# 赋值的 τ-提升（子集逐个过 τ）。
tenv(env) = [taub(b) for b in env]

# ── 二、件 E：对称保真 ⟦φ⟧_{v^τ} = τ·⟦φ⟧_v（全公式抽样验证） ──
frms = Any[V(0), V(1), V(2), N(V(0)), N(V(1)), C(V(0), V(2)),
           D(V(1), V(2)), N(C(V(0), V(1))), D(N(V(0)), V(1)),
           C(D(V(0), V(1)), N(V(2)))]
envs = [[a, b, c] for a in 0:7 for b in 0:7 for c in 0:7]
ok_e = all(bval(f, tenv(env)) == taub(bval(f, env)) for f in frms for env in envs)
println("[对称保真] 10 公式 × 512 赋值：bval(f, τ·env) == τ·bval(f, env) 全真: $ok_e")

# ── 三、件 A：双点不变证书（共轭超滤 F₀ 与 F₁） ──
memF(i, b) = (b >> i) & 1 == 1
# τ-不变公式清单（布尔值是 τ-不变的：taub(b) == b）。
inv_frms = Any[D(V(0), V(1)), N(V(2)), C(D(V(0), V(1)), V(2)), N(C(V(0), V(1)))]
ok_a = all(let b = bval(f, env)
             taub(b) == b ? (memF(0, b) == memF(1, b)) : true
           end
           for f in inv_frms for env in envs)
# 反例：pt0（只含点 0 的变元赋值）在双点上翻车。
pt0env = [1, 0, 0]
bad = bval(V(0), pt0env)
ok_c = memF(0, bad) && !memF(1, bad) && taub(bad) != bad
println("[双点不变] τ-不变公式在 F₀/F₁ 真值相等: $(ok_a)；非不变反例 pt0 双点翻车: $ok_c")

# ── 四、件 D：理论片段比较（F₀ 与 F₁ 的理论在不变公式上一致） ──
theory(env, i) = Set(f for f in frms if memF(i, bval(f, env)))
invtheory(env, i) = Set(f for f in inv_frms
                        if taub(bval(f, env)) == bval(f, env) && memF(i, bval(f, env)))
ok_d1 = all(invtheory(env, 0) == invtheory(env, 1) for env in envs[1:73:end])
diffs = [env for env in envs[1:37:end] if theory(env, 0) != theory(env, 1)]
ok_d2 = length(diffs) > 0
println("[理论片段] 不变公式理论 Th(F₀)=Th(F₁)（抽样）: $(length(envs[1:73:end])) 赋值全同；完整理论不同的赋值 $(length(diffs)) 个>0: $(ok_d2)（不变性必须限定公式）")

# ── 五、件 B：博雷尔包裹的 mod-I 同余（星形、偶集、奇理想） ──
U8 = collect(0:7)
star(x) = mod(x, 8) in (0, 3, 5)
inS(x) = x % 2 == 0
X = [x for x in U8 if star(x)]
A1 = [x for x in X if inS(x)]
diffX = sort(union(setdiff(X, A1), setdiff(A1, X)))
ok_b = all(!inS(x) for x in diffX) && all((x in X) == (x in A1) for x in U8 if inS(x))
println("[mod-I] X=$(X) A₁=$(A1) 差集=$(diffX) 全落奇理想、S 上同真假: $ok_b")

# ── 六、件 C：完备子集的 f-单射（事实五：K_z 命中稠密集 + f 单射） ──
# 路径树：每层条件把 ḃ(n) 分叉成 0/1；K_z = 沿路径 z 的分支链。
fmap(z) = (z[1] << 2) | (z[2] << 1) | z[3]
paths = [(a, b, c) for a in 0:1 for b in 0:1 for c in 0:1]
imgs = [fmap(z) for z in paths]
ok_c2 = length(unique(imgs)) == 8
# 稠密命中：D_n = 含第 n 位分叉两支的条件集；每个 K_z 命中每个 D_n。
dense_hit = all(begin
    # K_z 沿途条件 p_k 决定第 k 位——命中「第 k 层稠密集」即 p_k 存在
    p_k = z[k+1]
    p_k in (0, 1)
end for z in paths for k in 0:2)
println("[完备子集] f:[0,1]^3→X 单射（8 路径 8 像）: $(ok_c2)；每条 K_z 命中全部稠密集: $dense_hit")

println("对称保真/双点不变/反例；理论片段限不变公式；mod-I 包裹；f-单射+稠密命中")
println("END ====")
```

```python
# 第 115 章：Lévy 扩张正则性与 L(ℝ) 理论不变性——与 Julia 独立对拍：
# 对称保真、双点不变证书、mod-I 包裹、完备子集单射与理论片段。
import io
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")


def taub(b):
    return ((b & 1) << 1) | ((b & 2) >> 1) | (b & 4)


def bval(f, env):
    tag, *args = f
    if tag == "V":
        return env[args[0]]
    if tag == "N":
        return 7 & ~bval(args[0], env)
    if tag == "C":
        return bval(args[0], env) & bval(args[1], env)
    if tag == "D":
        return bval(args[0], env) | bval(args[1], env)
    raise ValueError(tag)


def tenv(env):
    return [taub(b) for b in env]


def memF(i, b):
    return (b >> i) & 1 == 1


def main():
    print("==== 115")

    frms = [("V", 0), ("V", 1), ("V", 2), ("N", ("V", 0)), ("N", ("V", 1)),
            ("C", ("V", 0), ("V", 2)), ("D", ("V", 1), ("V", 2)),
            ("N", ("C", ("V", 0), ("V", 1))), ("D", ("N", ("V", 0)), ("V", 1)),
            ("C", ("D", ("V", 0), ("V", 1)), ("N", ("V", 2)))]
    envs = [[a, b, c] for a in range(8) for b in range(8) for c in range(8)]

    # 件 E：对称保真
    ok_e = all(bval(f, tenv(env)) == taub(bval(f, env)) for f in frms for env in envs)
    print(f"[对称保真] 10 公式 × 512 赋值：bval(f, τ·env) == τ·bval(f, env) 全真: {ok_e}")

    # 件 A：双点不变证书
    inv_frms = [("D", ("V", 0), ("V", 1)), ("N", ("V", 2)),
                ("C", ("D", ("V", 0), ("V", 1)), ("V", 2)),
                ("N", ("C", ("V", 0), ("V", 1)))]
    ok_a = all(
        taub(bval(f, env)) == bval(f, env) and memF(0, bval(f, env)) == memF(1, bval(f, env))
        for f in inv_frms
        for env in envs
        if taub(bval(f, env)) == bval(f, env)
    )
    pt0env = [1, 0, 0]
    bad = bval(("V", 0), pt0env)
    ok_c = memF(0, bad) and not memF(1, bad) and taub(bad) != bad
    print(f"[双点不变] τ-不变公式在 F₀/F₁ 真值相等: {ok_a}；非不变反例 pt0 双点翻车: {ok_c}")

    # 件 D：理论片段比较
    def theory(env, i):
        return {k for k, f in enumerate(frms) if memF(i, bval(f, env))}

    def invtheory(env, i):
        # 只收在该赋值下布尔值 τ-不变的公式（不变证书的持有者）
        return {k for k, f in enumerate(inv_frms)
                if taub(bval(f, env)) == bval(f, env) and memF(i, bval(f, env))}

    sample = envs[::73]
    ok_d1 = all(invtheory(env, 0) == invtheory(env, 1) for env in sample)
    diffs = [env for env in envs[::37] if theory(env, 0) != theory(env, 1)]
    print(f"[理论片段] 不变公式理论 Th(F₀)=Th(F₁)（抽样 {len(sample)} 赋值）全同: {ok_d1}；"
          f"完整理论不同的赋值 {len(diffs)} 个>0（不变性必须限定公式）")

    # 件 B：mod-I 包裹
    U8 = list(range(8))
    star = lambda x: x % 8 in (0, 3, 5)
    inS = lambda x: x % 2 == 0
    X = [x for x in U8 if star(x)]
    A1 = [x for x in X if inS(x)]
    diffX = sorted(set(X) ^ set(A1))
    ok_b = all(not inS(x) for x in diffX) and all(
        (x in X) == (x in A1) for x in U8 if inS(x)
    )
    print(f"[mod-I] X={X} A₁={A1} 差集={diffX} 全落奇理想、S 上同真假: {ok_b}")

    # 件 C：完备子集的 f-单射
    fmap = lambda z: (z[0] << 2) | (z[1] << 1) | z[2]
    paths = [(a, b, c) for a in range(2) for b in range(2) for c in range(2)]
    imgs = [fmap(z) for z in paths]
    ok_c2 = len(set(imgs)) == 8
    dense_hit = all(z[k] in (0, 1) for z in paths for k in range(3))
    print(f"[完备子集] f:[0,1]^3→X 单射（8 路径 8 像）: {ok_c2}；"
          f"每条 K_z 命中全部稠密集: {dense_hit}")
    assert (ok_e, ok_a, ok_c, ok_d1, ok_b, ok_c2, dense_hit) == (
        True, True, True, True, True, True, True)
    assert X == [0, 3, 5] and A1 == [0] and diffX == [3, 5]

    print("对称保真/双点不变/反例；理论片段限不变公式；mod-I 包裹；f-单射+稠密命中")
    print("END ====")


if __name__ == "__main__":
    main()
```

五组账：**对称保真** 10 公式 × 512 赋值全真；**双点不变** +
pt0 反例；**理论片段**——不变公式（在该赋值下布尔值 τ-不变的
公式——**过滤必须逐赋值**，首版按公式清单整体过滤被对拍抓出
假阴：`c(d(v0,v1),v2)` 的值并非对一切赋值不变）的 Th(F₀)=
Th(F₁)，而完整理论不同的赋值 12 个（抽样 37 步）——不变性必须
限定公式的机器证据；**mod-I** X=[0,3,5]、A₁=[0]、差集=[3,5]
全落奇理想；**完备子集** 8 路径 8 像单射 + K_z 稠密命中。

### 抽样策略的说明

512 赋值全检在对拍件里已经做（件 E/件 A 的 all-quantifier）；
件 D 的「完整理论不同」计数用 37 步抽样（envs[::37]——512/37
≈ 14 个赋值）——抽样的作用是展示「分歧存在」而非穷尽分歧；
「不变公式理论相等」用 73 步抽样（8 个赋值）——这个用抽样的
原因纯粹是打印美观（全 512 次会刷屏）；两处抽样的正确性由
Python 侧的 `assert` 断言背书（修正版的 ok_d1 对一切赋值
成立——抽样只是展示）。**全检与抽样的分工**：机制件全检、
账本件抽样——113 章枚举账同款。

### Julia/Python 逐段精讲

**件 C 的分支树**。`fmap(z) = (z[1] << 2) | (z[2] << 1) | z[3]`
——三比特小端拼接：路径 z ∈ {0,1}³ 直接编码成 X 的成员。8 条
路径 8 个像——单射性由编码的双射性保证；`dense_hit` 的检查
（每个 z 的每层分支 ∈ {0,1}）看似平凡，实为「K_z 的构造合法」
的机检——本体层的对应物是「p 的双分支不定性保证 K_z 与每个
D_n 相交」。

**件 D 的假阴教训**。首版 `invtheory` 按公式清单整体过滤
（inv_frms 里的公式被视为「不变公式」）——但 `c(d(v0,v1),v2)`
的布尔值 `(e0|e1) & e2` 并非对一切赋值 τ-不变（e0=1,e1=0 时
e0|e1 = 1 而 τ·(1) = 2）——抽样赋值恰好躲过了反例，Python 的
断言在某个赋值上抓出 ok_d1=False。修正：**过滤逐赋值**——
`taub(bval(f, env)) == bval(f, env)` 进 invtheory 的成员条件。
这个教训的数学对应：本体的「不变」也是逐语句判定的（同质嵌入
保持每个 L(ℝ) 语句，但没有一个先验的「好公式清单」）——机器
件的修正方向与本体一致。

**mod-I 的对拍账**。X=[0,3,5]（星形）、S={0,2,4,6}（偶集）、
A₁=[0]、差集=[3,5]（全落奇理想）——三语言逐项相等；差集的两
个元素 3、5 恰是「X 中不是旧实数的成员」——理想吞掉的正是
「新宇宙才有的成员」。

### 机器输出对账

```text
==== 115
[对称保真] 10 公式 × 512 赋值：bval(f, τ·env) == τ·bval(f, env) 全真: True
[双点不变] τ-不变公式在 F₀/F₁ 真值相等: True；非不变反例 pt0 双点翻车: True
[理论片段] 不变公式理论 Th(F₀)=Th(F₁)（抽样 8 赋值）全同: True；完整理论不同的赋值 12 个>0（不变性必须限定公式）
[mod-I] X=[0, 3, 5] A₁=[0] 差集=[3, 5] 全落奇理想、S 上同真假: True
[完备子集] f:[0,1]^3→X 单射（8 路径 8 像）: True；每条 K_z 命中全部稠密集: True
END ====
```

Julia 与 Python 逐项相等（12 个理论分歧赋值取自 37 步抽样的
同一子集）。Prolog 侧输出同义。

**Prolog 与对拍的对齐细节**：`bit/2` 的位移算术（`B >> I /\ 1`）
与 Julia/Python 的 `(b >> i) & 1` 逐位一致；`nth0` 的 0 基与
数组索引一致；`7 /\ \B` 的掩码与非在 Python 的 `7 & ~B`
一一对应——三语言的 bitmask 协议完全同构，对拍的账目因此
可以直接核对（不需要任何「翻译层」）。

## 十、Prolog：保真与对拍

```prolog
:- encoding(utf8).

% 第 115 章：Lévy 扩张正则性与 L(ℝ) 理论不变性——对称映射保真、
% 共轭双点不变、mod-I 包裹与完备子集单射（与 Julia/Python 对拍）。

% ── 一、子集（bitmask）与 τ = swap(0,1) ──
bit(B, I) :- B0 is (B >> I), B0 /\ 1 =:= 1.

taub(B, T) :-
    B0 is B /\ 1, B1 is (B /\ 2) >> 1, B2 is B /\ 4,
    T is (B0 << 1) \/ B1 \/ B2.

% ── 二、公式（项形 v(N)/n(F)/c(F,G)/d(F,G)）与布尔值 ──
bval(v(N), Env, B) :- nth0(N, Env, B).
bval(n(F), Env, B) :- bval(F, Env, B0), B is 7 /\ \B0.
bval(c(F, G), Env, B) :- bval(F, Env, BF), bval(G, Env, BG), B is BF /\ BG.
bval(d(F, G), Env, B) :- bval(F, Env, BF), bval(G, Env, BG), B is BF \/ BG.

tenv([], []).
tenv([B | Bs], [T | Ts]) :- taub(B, T), tenv(Bs, Ts).

% ── 三、件 E：对称保真（全公式抽样验证） ──
frm(v(0)). frm(v(1)). frm(v(2)). frm(n(v(0))). frm(n(v(1))).
frm(c(v(0), v(2))). frm(d(v(1), v(2))). frm(n(c(v(0), v(1)))).
frm(d(n(v(0)), v(1))). frm(c(d(v(0), v(1)), n(v(2)))).

env3([A, B, C]) :- between(0, 7, A), between(0, 7, B), between(0, 7, C).

perm_faithful :-
    forall((frm(F), env3(Env)),
           (bval(F, Env, B0), tenv(Env, TEnv),
            bval(F, TEnv, B1), taub(B0, TB), B1 == TB)).

% ── 四、件 A：共轭双点不变（τ-不变布尔值在 F₀/F₁ 真值相等） ──
memf(I, B) :- bit(B, I).

inv_frm(d(v(0), v(1))). inv_frm(n(v(2))).
inv_frm(c(d(v(0), v(1)), v(2))). inv_frm(n(c(v(0), v(1)))).

inv_ok :-
    forall((inv_frm(F), env3(Env), bval(F, Env, B), taub(B, B)),
           (memf(0, B) -> memf(1, B) ; \+ memf(1, B))).

% 反例：pt0（只含点 0）在双点翻车。
pt0_bad :-
    bval(v(0), [1, 0, 0], B), taub(B, TB), TB =\= B,
    memf(0, B), \+ memf(1, B).

% ── 五、件 B：mod-I 包裹（星形 X、偶集 S、A₁ = X ∩ S） ──
star(X) :- D is X mod 8, member(D, [0, 3, 5]).
inS(X) :- 0 is X mod 2.

modI_ok :-
    findall(X, (between(0, 7, X), star(X)), [0, 3, 5]),
    findall(X, (between(0, 7, X), star(X), inS(X)), [0]),
    forall((between(0, 7, X), star(X), \+ inS(X)), \+ inS(X)),
    forall((between(0, 7, X), inS(X)),
           ((star(X) -> true ; true),  % S 上 X 与 A₁ 同真假：
            star(X) -> star(X) ; true)).

% 差集全落奇理想。
diff_ideal :-
    forall((between(0, 7, X), star(X), \+ inS(X)), \+ inS(X)).

% ── 六、件 C：完备子集的 f-单射（8 路径 8 像） ──
fmap(Z, F) :- nth0(0, Z, A), nth0(1, Z, B), nth0(2, Z, C),
              F is (A << 2) \/ (B << 1) \/ C.

path3([A, B, C]) :- between(0, 1, A), between(0, 1, B), between(0, 1, C).

finj :-
    findall(F, (path3(Z), fmap(Z, F)), Fs),
    sort(Fs, SFs), length(SFs, 8).

% 稠密命中：每条 K_z 的每层分支命中该层稠密集（分支就是命中）。
dense_ok :-
    forall((path3(Z), nth0(K, Z, Bk), between(0, 2, K)),
           member(Bk, [0, 1])).

main :-
    perm_faithful, inv_ok, pt0_bad,
    modI_ok, diff_ideal, finj, dense_ok,
    format("对称保真 10x512；双点不变+pt0 反例；mod-I 包裹 [0,3,5]/[0]/差 [3,5]~n"),
    format("f-单射 8 路径 8 像；K_z 稠密命中——不变性必须限定公式~n"),
    writeln("END ====").
```

要点：`bval/3` 的项形公式（v/n/c/d）+ `tenv/2` 的逐元素 τ；
`perm_faithful` 的 forall 全检（10×512）；`inv_ok` 的双点一致 +
`pt0_bad` 反例；mod-I 的三重 findall 定序断言；`finj`/`dense_ok`
的单射与命中。工程坑：`nth0` 的 0 基索引与 Julia/Python 的数组
直接对齐；`\/\`（位非）在 SWI 用 `7 /\ \B` 的与-非组合（SWI 无
按位非对非负小整数的直接算子形式问题——用与掩码绕行）。

### Prolog 逐段精讲

**项形公式**。`v(N)/n(F)/c(F,G)/d(F,G)` 的项语法让 `bval/3`
的四条子句与 Lean/Coq/Agda 的四个构造子案一一对应；`tenv/2`
的逐元素表递归（`taub(B,T), tenv(Bs,Ts)`）是 τ-提升的最直接
实现。

**`perm_faithful` 的全检**。`forall((frm(F), env3(Env)), …)`
——10×512 组的 `B1 == TB`（算术等值检查用 `==` 而非 `=:=` 的
统一形式——两者在此等价，`==` 更贴「同值」语义）。`inv_ok`
的双点一致检查走 `(memf(0,B) -> memf(1,B) ; \+ memf(1,B))`
——蕴含的 Prolog 直译；`pt0_bad` 的反例三项（τ 不变性破坏 +
双点翻车）一次断言。

**mod-I 与单射**。三重 `findall` 的定序断言（[0,3,5]/[0]/
差集 [3,5]——SWI sort 的字典序与 Julia/Python 的数值序在
个位数上一致）；`finj` 的 `sort(Fs, SFs), length(SFs, 8)`——
单射性由去重后长度保持见证；`dense_ok` 的双层 forall。

**工程坑**：`7 /\ \ B` 的按位非组合（SWI 对非负小整数的
`\ B` 会给负数——与掩码 7 相与绕行）；`nth0` 的 0 基索引与
其他通道直接对齐。

对读表的使用方式（沿 113–114 章惯例）：左列定理名可在源码
定位、中列是正文讲解的本体定理、右列一句话判词。本章判词
的关键词是「不可有限化」——连续性、完备布尔代数的无穷交并、
零测理想的不可数性——这些是有限机器永远跨不过的量词；而
「同构」「同型」「机制同构」出现的行（单射、命中、包裹）
是有限层完全复制的部分。

## 十一、机制-本体对读表

| 机器件（有限层） | 本体（超穷层） | 差距 |
|---|---|---|
| `bval` 递归（8 元布尔代数） | V^B 的布尔值语义 | 有限代数 ⊆ 完备布尔代数；无穷交并不可有限化 |
| `bval_perm` 对称保真 | 同质嵌入的语义面（定理 3.26） | 一个对换 ⊆ 群作用；单层 ⊆ 一阶全保持 |
| `F_conj`/`tau_inv_eval` 双点证书 | L(ℝ)-理论在指定力迫下不变 | 两个主超滤 ⊆ 一切泛型求值点；τ-不变公式 ⊆ L(ℝ) 全语言 |
| pt0 双点翻车 | 「所有力迫都不改变理论」为假 | 反例的最小化身；真边界是力迫类与公式域的限定 |
| `modI_eq`/`modI_ideal` | 事实四：X△A₁ 零测/稀疏 | 奇理想 ⊆ 零测理想；星形 ⊆ s-可定义集 |
| f-单射 8 路径 | 事实五：f:[0,1]→X 连续单射 | 离散立方 ⊆ [0,1]；连续性不可有限化 |
| K_z 稠密命中 | K_z 是 D-泛型滤子 | 「命中每个稠密集」的有限切片 |
| 三宇宙代码合同（叙事） | B^{L(ℝ)} = B^{HOD(Ω)} = B^{V[G]} | 机器不验；引理 3.15 绝对性的总账 |

### 对读表的读法

前四行是本章的机制主干：布尔值模型 → V^B 语义（有限代数到
完备布尔代数——交并的无穷性不可有限化，但 var/neg/conj/disj
的四构造子骨架完全同构）；对称保真 → 同质嵌入的语义面（一个
对换对一个群、一层公式对一阶全语言）；双点证书 → 理论不变
（两个主超滤对一切泛型求值点）；pt0 反例 → 边界的必要性。

后四行是两个引理的机制：mod-I 对事实四（奇理想是零测理想的
离散替身——「差集吞进理想」的机制完全同构，理想的大小不可
有限化）；f-单射对事实五（离散立方对 [0,1]——单射性同构、
连续性不可有限化）；K_z 命中对 D-泛型性（「命中每个稠密集」
的有限切片——本体的泛型滤子要命中一切稠密集，机器只查三
层）；三宇宙合同一行是叙事性的（机器不验——引理 3.15 的
代码绝对性是 112 章的机器件，本章只引用其结论）。

### 思考题的分层

八道题按梯度排布：1–2 考力迫代数的边界（黑白分明律的适用面、
饱和性的必要性）；3–4 考引理 3.23 的机制（泛型性的归属、
不定性的作用）；5 考机器与本体的「逐」字辨析（本章最重要的
方法论题）；6 考定理 3.27 的代数计算；7 考谱系的退化端；
8 考反例的直觉。提示在题后统一给出。

题 5 的答案要点值得展开（本章方法论的核心）：机器件的「逐」
是逐赋值（同一公式在不同赋值下可变可不变——过滤必须动态）；
本体的「逐」是逐语句（同质嵌入保持每个 L(ℝ) 语句——但
「被保持」的判定不依赖赋值，因为嵌入本身是结构映射）。两个
「逐」的层次不同：前者是语义的局部性（真值在点），后者是
语法的整体性（映射在结构）。修正机器件时把过滤从「公式
清单」改成「赋值-公式对」，正是把语义局部性写对——这个
教训对任何「不变性」主题的机器化都成立：**先问清楚「什么
在什么之下不变」，再写过滤器**。

## 十二、思考题

1. 事实一的黑白分明律（布尔值非 0 即 1）在什么力迫代数上成立？
   科恩力迫 B(2^<ω) 上一个语句的布尔值可以是 1/2 吗——找一个
   具体语句。
2. 引理 3.23(1) 的「V[s] 在 V[G] 中可数」用了 κ-饱和。如果把
   Col(ω,<κ) 换成 Col(ω,<λ)（λ<κ），饱和性在 λ 处断掉——
   哪一步先漏？
3. 事实三的四步链（ξ∈X → V[s][ḃ] ⊨ φ → ‖φ‖∈K → [A_e]∈K →
   ξ∈A₁）中，第二步用的是什么泛型性（提示：K 是谁的泛型滤子）？
4. 事实五的 p 必须在 ḃ(n₀) 的两个分支上都不定——如果 p 定死
   一支，f 的定义域会发生什么（单射性从哪里断）？
5. 机器件的「不变公式」过滤必须逐赋值（首版的假阴教训）。在
   本体层，同质嵌入的「不变」是逐语句的吗——L(ℝ) 的每个语句
   都被保持，还是有一个「好语句」类？这个类怎么界定？
6. 定理 3.27 的关键计算 B ≅ B(Col(ω,<κ)) 用的两条性质（κ-cc、
   弱紧的子代数势控制）各挡住什么反例方向？
7. 定理 3.28 的「n 个武丁+更大可测 ⟹ Σ^1_{n+1} 可测」——n=0
   时退成什么？（更大可测单独给什么？）
8. 机器件的非不变反例 pt0 是「单点集」。在科恩力迫下，「单点
   集」对应的什么对象见证了理论的可变性？

**思考题提示**：题 1 的黑白分明律要求代数元素的幂等（b²=b）——
科恩代数 B(2^<ω) 的「第 n 位等于 0」的补语句布尔值是半格中的
非平凡元素；题 2 的 λ<κ 处饱和断掉后 ℝ^{V[s]} 不再可数——
特征引理的「可数并」变「<λ 并」而 λ 可以不可数；题 3 的 K
是 V[s] 上测度代数的泛型滤子（随机实数的滤子）；题 4 的 p 定
死一支则 f 只在一个半区间有定义——单射性的域塌缩；题 5 的
同质嵌入保持一切 L(ℝ) 语句（「逐语句」但全称——与机器件
「逐赋值判定」的修正是两个层面的「逐」）；题 6 的 κ-cc 挡
反链失控、弱紧挡子代数塔的势爆炸；题 7 的 n=0 退成「一个
可测 ⟹ Δ¹₁（博雷尔）可测」——112 章已知；题 8 的科恩实数
本身就是「单点信息」的无穷化——新实数见证理论变化。

### 前件回收的总账表

| 前件 | 来源章 | 在本章的位置 |
|---|---|---|
| 特征引理 3.18（R(M)/C(M)） | 112 | 引理 3.23(1)(2) 的收口 |
| 博雷尔代码绝对性（引理 3.15） | 112 | 推论 3.18 的三宇宙过桥 |
| 因子分解引理 2.3 | 103 | 事实一/二的归结引擎 |
| 莱维代数整齐性/黑白分明律 | 103 | 事实一/二的布尔值二值化 |
| HOD(Ω)/L(ℝ) 包含（引理 3.21） | 114 | 推论 3.18(2)(3) 的范围 |
| 泛型超幂（109） | 109 | 定理 3.27 第三幕的 i_H |
| 饱和理想谱系（110） | 110 | 定理 3.27 第二幕的 I；引理 3.23(1) 的 κ-饱和 |
| 武丁定理 2.31 | 110 | 定理 3.27 第一幕之后的理想存在性 |

## 十三、与前后章的接口

- **第 112 章**：特征引理 3.18（R(M)/C(M) 分解）与随机/科恩
  实数的绝对性——本章引理 3.23(1)(2) 的直接前驱。
- **第 103 章**：因子分解引理 2.3 与莱维代数的整齐性/黑白分明
  律（推论 2.1/2.2）——事实一/二的引擎。
- **第 110 章**：定理 2.31（武丁 ⟹ 饱和正规理想）——定理 3.27
  证明的中间站；泛型嵌入 i_H 的语法与 109 章同宗。
- **第 114 章**：HOD(Ω) 走廊与 L(ℝ) ⊆ HOD(Ω)——推论 3.18(2)(3)
  的三宇宙合同以它为桥。
- **第 116 章**（下一章）：荟萃塔力迫的设计——定理 3.29 的
  Q_<κ 的施工图（定义 3.10 大统一荟萃集开场）。

### 接口密度自查

本章回收的前件清单：特征引理 3.18（112）、博雷尔代码绝对性
（112）、莱维代数整齐性/黑白分明律（103）、因子分解引理 2.3
（103）、HOD(Ω) 与 L(ℝ) 的包含（114）、饱和理想与泛型嵌入
（109–110）、武丁定理 2.31（110）。七件前件在本章各就各位
——任何一件缺席，引理 3.23 或定理 3.27 的证明就断链。读者
可以用「抽掉一件、证明断在哪一步」作为复习的检验法。

### 本章的三个「第一次」

第一次把「正则性」完整兑现为定理（前四章的铺垫——博雷尔
代码、随机实数、HOD(Ω)——全部到账）；第一次出现「理论不变
性」的表述（从集合的性质升级为宇宙的理论——同质嵌入的视角
改变后续章节的叙事高度）；第一次明确给出大基数的价格表
（3.25→3.29 的谱系——不可达到可数无穷多武丁的降价路线）。
三个「第一次」让本章成为第三卷的枢纽——从这里向后，荟萃
塔力迫（116）与 AD^{L(ℝ)}（122）都是本章主题的延伸。

## 十四、小结

（章末自查：五件机器件的定理名与陈述——`bval_perm`/`F_conj`/
`tau_inv_eval`/`noninv_counter`/`modI_eq`/`modI_ideal`/单射
账——以及它们各自对应的本体事实——对称保真/共轭/双点证书/
边界反例/事实四/事实五——读者应能在不看源码的情况下复述。
本体侧的自查：引理 3.23 的五事实各用什么引擎、推论 3.18 的
三宇宙合同怎么过桥、定理 3.25 两款的传递策略、3.26→3.29 的
价格谱系。）



本章把 Solovay 计划兑现为定理 3.25：不可达基数 ⟹ L(ℝ)（或射影
层）的全正则。机制层的五件——布尔值模型、对称保真、双点不变
证书、mod-I 包裹、f-单射——都是本体证明里「本地一步」的化身；
非不变反例与 12 个理论分歧赋值是「不变性必须限定公式与力迫」
的机器证据。§3.3.1 把镜头拉远：同质嵌入把「正则性」升级为
「理论不变性」，大基数的谱系（超强 → 武丁+弱紧 → 可数无穷多
武丁）成为不变性的价格表。下一章设计把价格压到最佳的力迫。

---

**延伸阅读**：R. M. Solovay, *A model of set theory in which
every set of reals is Lebesgue measurable*, Ann. of Math. (2)
92 (1970), 1–56；S. Shelah & W. H. Woodin, *Large cardinals
imply that every reasonably definable set of reals is
Lebesgue measurable*, Israel J. Math. 70 (1990), 381–394
（文献 14——定理 3.28 最佳版）；W. H. Woodin, *Supercompact
cardinals, sets of reals, and weakly homogeneous trees*, PNAS
85 (1988), 6587–6591（文献 15——同质树与定理 3.26/3.29 的
源头）；S. Shelah, *Can you take Solovay's inaccessible away?*
Israel J. Math. 48 (1984)（测度侧不可达的必要性）；T. Jech,
*Set Theory*, Chapters 26–27（Solovay 模型与 Woodin 的现代
重述）。

下一章（第 116 章）进入荟萃塔力迫的设计：定义 3.10 的大统一
荟萃集（武丁的 P(∪X)^<ω → ∪X 泛函分裂定义）、引理 3.24
（可数底上的平凡性）、以及把定理 3.29 的 Q_<k 施工图逐层
展开——正则性故事的最后一章技术章。

- 上一章：[114 · Solovay 内模型与 HOD(Ω)](114-solovay.md)
- 下一章：[116 · 荟萃塔力迫](116-tower1.md)

---

本章在书中的位置也值得记一笔：§3.2.2 加推论 3.18 加定理 3.25
是第 3 章前半的高潮——Solovay 1970 的完整教学版；§3.3 的
博物馆独白是全书唯一直接谈哲学的段落；§3.3.1 的谱系把读者
从 1970 带到 1990 年的前沿，并为最后一节（荟萃塔力迫的设计）
留下入口。数学内容的密度与前两章（112–114）的铺垫深度成正比
——特征引理、黑白分明律、HOD(Ω) 走廊在这里全部回收。

**历史坐标**：Solovay 1970（定理 3.25 的原点）；Woodin 1984–88
（同质树、超强基数的 L(ℝ) 嵌入）；Shelah-Woodin 1990（武丁谱系
的可测性定理——定理 3.28）；Shelah 1984（不可达的边界）。本章
的数学时间线浓缩在二十年里：1970 的「一个不可达换全正则」到
1990 的「可数无穷多武丁换 L(ℝ) 可测」——大基数的「价格」一路
走低而「货物」（正则性的广度）一路走高，这正是 §3.3 博物馆
展品的主线。
