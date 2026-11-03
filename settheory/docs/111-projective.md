# 111 · 投影精细分层与余解析集合

> 第 110 章把 $\mathrm{NS}_{\omega_1}$ 的饱和性做实，第三卷的镜头
> 从「大基数上的力迫」转向「$V_{\omega+2}$ 的内涵」——描述集合
> 论的主战场。本章取材冯琦第三卷 §3.1.1–§3.1.2（书页 251–271；
> PDF 272–292），两条主线：
>
> **其一（精细分层）**：把古典的投影集层次 $\boldsymbol\Sigma^1_n$ /
> $\boldsymbol\Pi^1_n$ 按「定义式中实数参数的有无」精细分层——
> 定义 3.1 的简体 $\Sigma^1_n(\alpha)$ /$\Pi^1_n(\alpha)$ /
> $\Delta^1_n(\alpha)$ （黑体 = 允许任意实参数、简体 = 递归无参
> 数；$\Sigma^1_1(\alpha)$ 是「存在实数 y 使递归谓词 R 对
> $(\alpha{\upharpoonright}n,y{\upharpoonright}n)$ 全 n 成立」
> ——$\omega$ 上的存在量词接 $\omega^\omega$ 上的存在量词）。
> 引理 3.1 记录各层的封闭性：布尔组合、数词与实词的交换与融合
> ——证明的三件融合兵器是**位串分流**（u±：奇偶位拆两个实数）、
> **后继配对**（h：m 与尾部 y 拼一个实数）与**选择交换**
> （$\forall m\exists z\to\exists u\forall m$ ，依赖 $\mathrm{AC}_\omega$
> 的递归同胚 H）——量词工程的全套工具。引理 3.2 给通用集。
>
> **其二（余解析集的树表示）**：定义 3.2 把树推广到 k-维
> （$\mathrm{Seq}^k$ 等长序列组、前段封闭序 $\le_k$ 、
> $[T]$ = 无穷树枝全体），引理 3.3 整合闭集树表示（第一卷
> 定理 I.3.26）与解析集特征（引理 I.3.17）：**A 解析 ⟺ A =
> $\pi[T]$ （某二维树的投影）⟺ $\alpha\in A$ 当且仅当
> T(α) 无秩**。由此立即得**定理 3.1（Π₁¹-规范形式）**：A 余
> 解析 ⟺ A = {α | T(α) 有秩}，与**定理 3.2（绝对性）**：
> 足够强的理论下 Π₁¹(α) 性质对传递模型内外一致（有秩树有
> 赋秩函数是全部机关）。作为应用：解析集开区分特性的第二个
> 证明（Mansfield–Solovay 型：T′ 剪枝 + 断言二的**双子延伸**
> 造完美子树）与完全集：**定义 3.3 的 WF/ZX/LO**（记录良基
> 关系/良序/线序的实数编码集）——引理 3.4（WF、ZX ∈ Π₁¹）、
> 引理 3.5（**秩有界部分 WF_α、ZX_α 是博雷尔集**——对 α 归纳）、
> 定理 3.3（**完全性**：一切黑体 Π₁¹ 集连续归结到 WF/ZX——
> f(α) 编码树 T(α)）、推论 3.2（WF、ZX 不是 Σ₁¹——非博雷尔）、
> **推论 3.3（有界性引理）**：可数的 $B\subseteq\mathrm{ZX}$
> 秩有界（否则 ZX 的秩无界切片写成 Σ₁¹ 与推论 3.2 矛盾）、
> 推论 3.4/引理 3.6（每个 Π₁¹/Σ₁¹ 集是 $\aleph_1$ 个博雷尔
> 集之并）、推论 3.5（余解析集之势三歧）。**准秩序与标尺**：
> 定义 3.4（范数与准秩序：传递 + 可比较 + 有秩）、定理 3.4
> （**Π₁¹-准秩序性质**：每个 Π₁¹ 集有 Π₁¹-范数——Q 用
> 「存在保序映射 f: T(α)→T(y)」、P 用「T(α) 有秩且
> $\lVert T(y)\rVert\nless\lVert T(α)\rVert$ 」）；换视角
> （U(α) 有秩 ⟺ 存在降到 ω₁ 的**降秩函数** g；ω×ω₁ 上的树
> T 有**最小无穷树枝** g_α = 秩函数）引出**定义 3.5 标尺**
> （范数序列 + 强制收敛性）与**定理 3.5（Π₁¹-标尺性质）**；
> 由此得**定义 3.6/定理 3.6（近藤展示函数定理）**与命题 3.1
> （非空 Π₁¹ 集有 Π₁¹ 单点子集——交替取范数最小与坐标最小，
> 标尺的强制收敛性保证极限落回集合中）。最后**引理 3.7** 把
> 简体层次与 $(V_{\omega_1},\in)$ 的可定义性接通（传递闭包
> 的真值绝对性 + WF 编码）——拓扑概念与逻辑概念之桥。
>
> 机器边界：本体（无穷位串、超穷归纳、连续归结）全在无穷层；
> 七个通道做**秩递归层**——①有限树与树枝判定（HasBranch/
> has_branch：深度上限 D 的全长路径——引理 3.3 良基判定的
> 有限替身）；②**赋秩函数**（ρ 燃料递归：叶 0、内部点 = 子
> 最大 + 1）与**秩 ≤ 剩余深度**（Lean `rho_le_fuel`/Coq
> `rho_le`/Agda `rho≤fuel` 定理件——引理 3.5「秩有界部分
> 博雷尔」的机制件）；③**完美子树构造**（Julia/Python：
> 双子延伸的递归抽取——开区分特性断言二的有限替身）；④
> **截面投影**（Julia/Python/Prolog：二维树 S 的截面 S(α)
> 与投影 $\pi[S]$ ——对角树全域投影、单侧树半域投影）；⑤
> **下降链**（Isabelle `minimal_no_descending`：极小元性质
> ⟹ 无下降链——引理 3.4 的 WF 对偶刻画；Prolog desc/loop
>
_witness 查询）。特别声明（Task 26 Step 3）：**余解析集 =
> 解析集的补**（定义 3.1(2)），树表示把「补」翻译成
> 「有秩 ↔ 无秩」的对偶（定理 3.1）；机器的秩计算只验证
> **有限树**的引理（ρ ≤ 深度、叶零、完美抽取），无穷树的
> 赋秩函数、博雷尔复杂性、连续归结全不在有限宇宙。

## 111.1 精细分层：从黑体到简体

第 110 章的投影集层次用黑体 $\boldsymbol\Sigma^1_n$ /
$\boldsymbol\Pi^1_n$ 标识；本章（书 p252–254）按定义式的
**参数与量词复杂度**精细分层。

先交代舞台（书 p251–252 的开场白）：描述集合论的几乎全部
内容都发生在贝尔空间 $\mathcal N=\omega^\omega$ （及其乘积）
上；实数以 $\mathcal P(\omega)$ 即 $V_\omega$ 的子集
呈现，$\mathbb R\subseteq V_{\omega+1}$ 、
$\mathcal N\subseteq V_{\omega+1}$ ——按可定义性分析，
它们都是传递模型 $(V_{\omega+1},\in)$ 上的可定义子集，
从而都在 $V_{\omega+2}$ 之中。「分析 $V_{\omega+2}$ 的
内涵」= 用集合论的工具审查实数子集的可定义性分层——
这是第三卷章名的由来，也是本章记号系统的坐标系。

记号总纲：

- **黑体** $\boldsymbol\Sigma^1_n(\alpha)$ ：定义式允许任意
  实参数 α；**简体** $\Sigma^1_n(\alpha)$ ：以 α 为**唯一**
  参数、其余部分递归；
- **上标 1**：定义式涉及实数变元的量词；**下标 n**：实数
  量词交错的次数（Σ 从 ∃ 开始、Π 从 ∀ 开始）；
- 上标 0（$\Sigma^0_1$ /$\Pi^0_1$ ）：只涉及自然数变元的
  量词——恰好是拓扑的开/闭（博雷尔层次的起点）。

**定义 3.1**（书 p252–253，要点）设 $1\le k\in\omega$ ：

1. $A\subseteq\mathcal N$ 是 $\Sigma^1_k(\alpha)$ 集合
   ⟺ 存在（相对于 α 的）递归集 $R\subseteq\bigcup_n (\omega^n\times\omega^n)$ 使
   $\beta\in A\iff\exists y\in\mathcal N\ \forall n\in\omega\ (R(\beta{\upharpoonright}n,y{\upharpoonright}n)).$

   ——实数存在量词 $\exists y$ 后接一个 $\Pi^0_1$ 型
   算术条件。
2. $A$ 是 $\Pi^1_k(\alpha)$ ⟺ $\mathcal N-A$ 是
   $\Sigma^1_k(\alpha)$ 。**这就是「余解析 = 解析的补」的
   精确形式**；树表示将把它翻译成「有秩 ↔ 无秩」的对偶。
3. $A$ 是 $\Sigma^1_{k+1}(\alpha)$ ⟺ A 是某
   $\Pi^1_k(\alpha)$ （乘积空间上的）集合的投影。
4. $\Delta^1_k(\alpha)=\Sigma^1_k(\alpha)\cap\Pi^1_k(\alpha)$ 。

观察 $\Sigma^1_1$ 的形状（书 p253）：
$$
B=\{(\beta,y)\mid\forall n\ R(\beta{\upharpoonright}n,
y{\upharpoonright}n)\}
$$

的补是开的（反例 n 即开邻域），故 B 闭、A = π[B] 是闭集的
投影——解析集的经典定义自动浮现。这段「观察」值得慢读：
它把**逻辑复杂度**（量词前缀）与**拓扑复杂度**（开/闭/投影）
在同一行内焊接——∀n 的算术量词对应闭性（每个 n 的条件
只看有限前段，否定是开邻域），∃y 的实数量词对应投影。
从此每个投影层都有两张名片：逻辑的（量词前缀形状）与
拓扑的（闭集投影、余解析、……）。精细分层据此展开：
$$
\boldsymbol\Sigma^1_1=\bigcup_{\alpha\in\mathcal N}
\Sigma^1_1(\alpha),\qquad\boldsymbol\Pi^1_1=
\bigcup_{\alpha}\Pi^1_1(\alpha),
$$

更一般地对每个 n：
$$
\boldsymbol\Sigma^1_n=\bigcup_\alpha\Sigma^1_n(\alpha),
\qquad\boldsymbol\Pi^1_n=\bigcup_\alpha\Pi^1_n(\alpha).
$$

精细分层的本义：**各层恰与「固定参数下定义式的复杂度」
吻合**——黑体记号、上标、下标的含义全部落实；而「黑体
= 允许实参数、简体 = 递归」的对照也解释了博雷尔层为什么
用 $\Sigma^0_n$ /$\Pi^0_n$ 起步（上标 0 = 定义式不涉及
实数变元的量词——只涉及自然数）。

**引理 3.1（封闭性）** $\Sigma^1_k(\alpha)$ /$\Pi^1_k(\alpha)$ /
$\Delta^1_k(\alpha)$ 对布尔组合、数词（∃m/∀m）、实词
（∃β/∀β）封闭（$\Delta$ 还对否定封闭）。证明（书
p255–258，n=1 情形）展示了**量词工程三兵器**：

- **位串分流** u±（$\lambda n.\ u(2n)$ 与 $\lambda n. u(2n+1)$ ）：把 $\exists z_1\exists z_2$ 融合成
  $\exists u$ ——$\mathcal N\to\mathcal N\times\mathcal N$
  的递归同胚；
- **后继配对** h（$h(u)=(u(0),u\circ S)$ ）：把数词 ∃m 与
  实词 ∃z 融合成实词 ∃u；
- **选择交换** H（$H(u)(m)(n)=u(g(m,n))$ ，g 递归配对）：
  在 $\mathrm{ZF}+\mathrm{AC}_\omega$ 中把 $\forall m \exists z$ 交换成 $\exists u\forall m$ （u 记录整列选择
  函数），再配左右逆 $\alpha,\beta$ 把 $\forall m\forall n$
  融合成 $\forall k$ 。

这三件兵器在 108 章引理 2.27（名字链下钻）与 110 章定理 2.32
（断言二的递归构造）都曾以变体出场；此处是它们的家谱源头。

把三件兵器各慢放一遍，因为它们是本章全部「封闭性」的齿轮：

- **位串分流 u±** 的用法总是成对的：先把两个实数存在量词
  $\exists z_1\exists z_2$ 合成一个 $\exists u$ （u 的
  偶数位给 z₁、奇数位给 z₂），递归谓词 R′ 按「第 n 位看
  u 的奇偶分流」重新定义——A∧B 的证明里两个 ∀n 合成
  一个 ∀n 正是用它。注意 u± 是**递归同胚**（不止是归约），
  所以它把 Σ¹₁(α) 关系映到 Σ¹₁(α) 关系而不升层。
- **后继配对 h** 处理「数词混在实词旁边」的脏前缀：
  $(\exists m\in\omega\ \exists z\in\mathcal N)\ \varphi$
  变成 $\exists u\ \varphi'(u)$ ，其中 u(0) 承担 m、
  u∘S 承担 z。A∨B 的证明用它把「选哪个析取支」的 ∃m
  织进实数 u 的首位。
- **选择交换 H** 是最强的一件：$\forall m\exists z\varphi$
  换成 $\exists u\forall m\varphi''$ ——u 把整列选择函数
  $m\mapsto z_m$ 打包成一个实数（g(m,n) 配对后 u 逐位
  记录）。这一步**依赖 AC_ω**（每次选择一个自然数函数）；
  书 p257 特意注明「在理论 ZF+AC_ω 的基础上」——选择公理
  的这一小片在描述集合论里是免费的，但记账不能省。

引理 3.2：每层有简体通用集——层次非平凡的种子（第一卷
引理 1.3.19 的加强：通用集本身取简体形态）。通用集配合
对角化立即给出层次的严格性——$\Sigma^1_n\ne\Pi^1_n$ 、
$\Delta^1_n\subsetneq\Sigma^1_n$ ；这正是 112 章以后一切
「升层」论证的模板。

## 111.2 树表示：从闭集到解析与余解析

**定义 3.2**（书 p258–259）$\mathrm{Seq}^k$ = 各分量等长的
k 元有限序列组；$\vec s\le_k\vec t$ ⟺ 逐分量前段；T ⊆
$\mathrm{Seq}^k$ 是 **k-维树** ⟺ 前段封闭；
$[T]=\{\vec\alpha\in\mathcal N^k\mid\forall n(\vec\alpha {\upharpoonright}n\in T)\}$ （无穷树枝全体）；T **有秩**
（良基）⟺ $[T]=\varnothing$ ，**无秩** ⟺ $[T]\ne \varnothing$ ；截面 $T(\alpha)=\{\vec s\mid(\alpha{\upharpoonright} \mathrm{dom},\vec s)\in T\}$ 。

**引理 3.3（解析集树表示）** (1) $[T]$ 是 $\mathcal N^k$
的闭子集；反之每个闭集 F 有树 T 使 F=[T]。(2) $A\subseteq \mathcal N$ 解析 ⟺ 存在二维树 T 使 A = π[T]，即
$$
\forall\alpha\ (\alpha\in A\iff T(\alpha)\ \text{无秩});
$$

更一般地 A 是 $\Sigma^1_1(\alpha)$ ⟺ 有 α-递归二维树 T
实现上式。（练习——整合第一卷 I.3.26 与 I.3.17。）

**定理 3.1（Π₁¹-规范形式）** A 是简体 Π₁¹ ⟺ 存在递归二维
树 T 使映射 α ↦ T(α) 递归且
$$
\forall\alpha\ (\alpha\in A\iff T(\alpha)\ \text{有秩}).
$$

（乘积版本与参数化版本同理。）——**解析集的补 = 树的良基化**：
余解析集正是「让树失去无穷树枝」的那些 α。这是本章全部
后续内容的规范出发点。

**定理 3.2（绝对性）** 设 T₀ 足够强使「每个有秩树有赋秩函数」
为其定理。若 P 是 $\Pi^1_1(\alpha)$ 性质、M ⊨ T₀ 传递、
$\alpha\in M$ ，则 P 对 M 内外一致。**证明两行**（书 p262）：
M 中无秩（有树枝）则在 V 中依旧有树枝——树枝是绝对的；
M 中有秩则在 M 中有赋秩函数 ρ（T₀ 保证），ρ 在 V 中依旧是
赋秩函数。——**良基性的半边（有树枝）向下绝对，另半边
（有秩函数）由理论提供**。

值得把这两行展开成「绝对性的不对称账」：Σ 方向（有树枝）
的见证是一个实数（ω-长序列）——它在 M 中存在就在 V 中
存在，**存在性沿包含方向单调**；Π 方向（有秩）的见证是
一个定义在整棵树上的秩函数——它的**存在性不是绝对的**
（V 中可能有 M 看不见的树枝！），要靠 T₀ 在 M 内部制造
秩函数来堵这个缝。「每个有秩树有赋秩函数」恰好是超穷
归纳的最小包装（KP 加一点即可；书 p262 的 T₀ 泛指一切
含此定理的理论）——第 112 章 Shoenfield 绝对性把这套
账目推到 Σ¹₂，用的正是这里种下的「树 + 秩」二重奏。

另一点值得点破：定理 3.2 是**引理 2.30 三等价（109 章）的
镜子**。那边在理想层问「泛型超幂良基吗」，这边在实数层问
「表示树良基吗」——良基性都是分水岭，而两处的「不绝对」
都源自同一件事：无穷下降链的**不存在**是对全体实数/全体
函数的全程量词，模型之间不可比。109 章用峭壁理想给良基性
立力迫刻画的工程，与本章用赋秩函数给良基性立组合刻画
（引理 3.4 的 WF 编码）的工程，是同一块石头的两面刻。

## 111.3 应用一：开区分特性的第二个证明

作为树表示的热身（书 p260–261），重证解析集的**开区分特性**
（定理 I.3.32）：解析 A 对任何相对开 $K\subseteq[A]^2$ ，
要么 A 含完美子集、要么 A 是可数个闭整齐子集之并。设 T 为
A 的表示树、K 相对开、A 非可数并。对 $(s,t)\in T$ 令
T(s,t) 为节点生成的子树；剪枝 $T'=\{(s,t)\mid\pi[T(s,t)]$
不是可数闭整齐并\}。**断言一**（剪枝封闭）：若 (s,t) ∈ T′
而某子节点 (σ,τ) ∉ T′，则 $\pi[T(s,t)]$ 是可数并——与
(s,t) ∈ T′ 矛盾。**断言二（双子延伸）**：(s,t) ∈ T′ ⟹
存在 T(s,t) 中两个节点 $(s_0,t_0),(s_1,t_1)$ 使
$s_0\perp s_1$ 且 $\pi[T(s_0,t_0)]\times\pi[T(s_1,t_1)] \subseteq K$ ——由 K 开取足够大的 n 分离 $\alpha_0,\alpha_1$
的邻域。递归应用断言二得完美子树 T*，$[T^*]^2\subseteq K$ 。
机器件③（双子延伸的完美子树抽取）正是断言二的有限替身。

## 111.4 完全余解析集：WF 与 ZX

**定义 3.3**（书 p262）固定递归配对双射 $\Gamma:\omega\times \omega\to\omega$ 。对 $\alpha\in\mathcal N$ 令
$$
E_\alpha=\{(m,n)\mid\alpha(\Gamma(m,n))=0\}
$$

——α **记录**关系 E_α。则：

- $\mathrm{WF}=\{\alpha\mid E_\alpha\ \text{有秩}\}$ ，
  $\lVert\alpha\rVert$ = E_α 的高度；
- $\mathrm{ZX}=\{\alpha\mid E_\alpha\ \text{是}\ \omega\ \text{上的良序}\}$ ，$\lVert\alpha\rVert=\mathrm{ot} (\omega,E_\alpha)$ ；$\mathrm{LO}$ （线序）是算术集。

**引理 3.4** WF、ZX ∈ Π₁¹。**证明**（书 p263）：E_α 有秩
⟺ 不存在 $f:\omega\to\omega$ 使 $\forall n((f(n+1), f(n))\in E_\alpha)$ ——**下降链的否定**：
$$
\alpha\in\mathrm{WF}\iff\forall z\in\mathcal N\ \exists
k\in\omega\ \big(\alpha(\Gamma(z(k+1),z(k)))\ne0\big).
$$

内层是 Σ⁰₁（算术），整体是 Π₁¹ 型。

这条刻画把「良基」翻译成「**每个实数 z 都在有限步内摔出
E_α**」——下降链的否定按第一卷的良基等价形式（I.2 的
Dependent Choice 对照）逐字对齐。机器件⑤（Isabelle
`minimal_no_descending` + Prolog desc/loop_witness）验证的
正是这条对偶的两面：**极小元性质 ⟹ 无 ω-长下降链**（ZF
内的方向——值域的非空子集取极小元，链的下一步撞上极小性）
与**环状关系的直接环见证**（X、Y 互为下元——无穷下降的
最小种子）。两个 Ω 型性质（线序 LO 与良序 ZX）之差恰好是
「无环」对「良基」——差一层 Π₁¹ 的厚度。

还要给 ||·|| 的取值范围记一笔（书 p263）：$\mathrm{ZX} \subseteq\mathrm{WF}$ ，且
$$
\forall\omega\le\alpha<\omega_1\ \exists\alpha\in
\mathrm{ZX}(\lVert\alpha\rVert=\alpha),\qquad
\forall\alpha\in\mathrm{WF}(\lVert\alpha\rVert<\omega_1)
$$

——良序编码的秩**恰好**跑遍 $[\omega,\omega_1)$ ：每个
可数序数都有一个编码（按序型直接造 E_α），而编码的秩至多
是可数序数（E_α 定义在 ω 上）。「‖·‖: ZX → [ω,ω₁) 满」
这行账是引理 3.5 与有界性推论的取值基础。

**引理 3.5（秩有界部分博雷尔）** 对每个 $\alpha<\omega_1$ ：
$$
\mathrm{WF}_\alpha=\{\alpha\in\mathrm{WF}\mid\lVert\alpha
\rVert\le\alpha\},\qquad\mathrm{ZX}_\alpha=\{\cdots\}
$$

都是博雷尔集。**证明**（书 p263–264）对 α 归纳：$(\alpha,n)\in B_\alpha$ ⟺ E_α 限制在 {m | (m,n) ∈ E_α}
上是序型 ≤ α 的良序；归纳步把 $B_\alpha$ 写成
$\bigcup_{\beta<\alpha}B_\beta$ 的前驱条件——**每固定一层
秩，复杂性降回博雷尔**。机器件②的「秩 ≤ 剩余深度」定理
是这条归纳的有限影子：ρ(s) ≤ D − |s|——深度封顶使秩有界，
有界秩的部分是「简单」的。

**定理 3.3（完全性）** 每个黑体 Π₁¹ 集连续归结到 ZX（与
WF）：设 C 由树 T 表示，$\langle t_m\rangle$ 为 Seq 的
递归单一列表，令 f(α) 记录与 (T(α),≤) 同构的关系——则
$\alpha\in C\iff f(\alpha)\in\mathrm{WF}$ ，且 f 连续
（T(α) 的成员资格只依赖 α 的有限前段）。**推论 3.2**：
WF、ZX 不是 Σ₁¹（否则一切 Π₁¹ 连续前像解析——与「存在
非解析的余解析集」矛盾），故非博雷尔。**推论 3.3（有界性
引理）**：可数 $B\subseteq\mathrm{ZX}$ ⟹
$\exists\gamma<\omega_1\forall\alpha\in B(\lVert\alpha \rVert<\gamma)$ ——否则 ZX 的秩切片写成 Σ₁¹，与推论 3.2
矛盾。**推论 3.4/引理 3.6**：Π₁¹/Σ₁¹ 集都是 $\aleph_1$
个博雷尔集之并（C = ∪f⁻¹[WF_α]；A 侧对树的高度归纳）。
**推论 3.5**：余解析集之势 ∈ {≤ℵ₀, ℵ₁, 2^ℵ₀}。

这一串推论的**依赖链**值得画出来（每一环都吃上一环的肉）：

| 步 | 结论 | 吃的是 |
|---|---|---|
| 1 | 引理 3.5：WF_α 博雷尔 | 对 α 的超穷归纳（每层只动博雷尔运算） |
| 2 | 定理 3.3：连续归结 f | 引理 3.3 的树编码 + f 的连续性 |
| 3 | 推论 3.2：WF 非 Σ₁¹ | 2 + 「解析集的连续前像解析」+ 存在非解析的余解析集 |
| 4 | 推论 3.3：有界性 | 3 + 「‖α‖ ≤ ‖β‖ 是 Σ₁¹ 关系」 |
| 5 | 推论 3.4：ℵ₁ 并 | 1 + 2（C = ∪ f⁻¹[WF_α]，α<ω₁） |
| 6 | 推论 3.5：势三歧 | 5 + 完美集定理（解析集版） |

第 4 步的有界性引理在后续章节（112 章的 Σ¹₂ 分析、113 章
的广泛贝尔）将反复被调用——「可数族的秩必整体有界」是
树界一切紧性论证之源。它的反证值得记牢：若 B ⊆ ZX 可数
而秩无界，则 ZX 的成员资格可写成「∃β∈B 使 ‖α‖ ≤ ‖β‖」
——外层 ∃β 跑一个可数集，而可数枚举本身把 ∃β 换成一个
**实数**（枚举函数的编码），内层「‖α‖ ≤ ‖β‖」是 Σ₁¹
关系——整体 Σ₁¹，与推论 3.2 矛盾。**枚举函数编码成实数**
——这就是「可数」在投影层次里被消费的标准方式。

再看完全性定理 3.3 的构造细节（书 p265）：把 Seq 的元素
排成递归单列 $\langle t_m\rangle$ ，对每个 α 令 y = f(α)
在坐标 $\Gamma(m,n)$ 上记录「$t_m,t_n\in T(\alpha)$
且 $t_m<t_n$ 」的 0/1——y 编码的关系 E_y 与 (T(α),≤)
同构，于是 y ∈ WF ⟺ T(α) 良基 ⟺ α ∈ C。**f 的连续性**
由 T(α) 的成员资格只依赖 α 的有限前段给出：要决定
f(α) 在坐标 Γ(m,n) 的值，只需知道 T(α) 是否包含长度
至多 max(m,n) 的两个节点——而这只读 α 的前 max 层。
「逐坐标有限依赖」= 连续——贝尔空间的基本事实，但在这
里它是整个归结工程的粘合剂。

## 111.5 范数、准秩序与标尺

**定义 3.4** A 上的**范数** φ: A → Ord；A 上的**准秩序**
≼（传递 + 可比较 + 「严格部分是有秩关系」）。练习 3.1 记录
无选择公理世界里二者的换算。

**定理 3.4（Π₁¹-准秩序性质）** 每个 Π₁¹ 集有 Π₁¹-范数：
存在 Π₁¹ 关系 P 与 Σ₁¹ 关系 Q 使
$$
\alpha,\beta\in A:\quad\varphi(\alpha)\le\varphi(\beta)
\iff P(\alpha,\beta)\iff Q(\alpha,\beta).
$$

**证明**（书 p268）：φ(α) = $\lVert T(\alpha)\rVert$ 。
Q(α,β) := 存在保序映射 f: T(α)→T(β)（Σ₁¹：f 是实数，
保序是算术条件；练习：「f 存在 ⟺ T(β) 有树枝 或
$\lVert T(\alpha)\rVert\le\lVert T(\beta)\rVert$ 」——在
A 上只剩第二支）。P(α,β) := T(α) 有秩 且 并非
$\lVert T(\beta)\rVert<\lVert T(\alpha)\rVert$ （存在
降秩函数 g: T(β)→T(α) 严格反映序——Π₁¹ 型）。P 与 Q 在
A×A 上重合 ⟺ 秩序条件——**范数的 Π₁¹-可定义性**。

**标尺**（书 p269–270）：换视角——U(α) 有秩 ⟺ 存在
g: U(α)→ω₁ 使 s ⊂ t ⟹ g(s) > g(t)（**降秩函数**）。在
ω×ω₁ 上定义树 T（h 记录每层 u_n 的秩上界）；对
$\alpha\in\pi[T]$ ，截面 $T(\alpha)$ 有**最小无穷树枝**
$$
g_\alpha(n)=\rho_{U(\alpha)}(u_n)
$$

（ρ 最小赋秩函数；其余树枝逐点 ≥ g_α）。令
$\beta_n(\alpha)=g_\alpha(n)$ 得范数序列 ⟨β_n⟩。

**定义 3.5** A 上的**标尺**是具备**强制收敛性**的范数序列
⟨β_n⟩：若 $\langle\alpha_i\rangle\subseteq A$ 收敛于 α
且每个 n 的 ⟨β_n(α_i)⟩ 最终常值 α_n，则 $\alpha\in A$ 且
$\beta_n(\alpha)\le\alpha_n$ 。——收敛保成员资格 + 范数
下半连续。

**定理 3.5（Π₁¹-标尺性质）** 每个 Π₁¹ 集有 Π₁¹-标尺
（P、Q 三元关系版本）。**定义 3.6/定理 3.6（近藤展示函数
定理）**：每个 Π₁¹ 关系 $A\subseteq\mathcal N\times\mathcal N$
有 Π₁¹ 展示函数 F ⊆ A（函数、同定义域）。**命题 3.1**
（非空 Π₁¹ 集有 Π₁¹ 单点子集）的证明是标尺的标准消费：
交替收缩 $A_{2n+1}=\{\beta_n\ \text{最小}\}$ 与
$A_{2n+2}=\{\beta(n)\ \text{最小}\}$ ，极限点 α 由强制
收敛性落回 A，$\{\alpha\}=\bigcap A_n$ 是 Π₁¹。标尺
与展示函数在第 113 章（Σ₁₃ 与广泛贝尔）将反复出场——
这里是它们的出生地。

**标尺的「最小树枝」视角**（书 p269）值得单独停留，因为
它是后续大量论证的母版。把 A 的表示树 U 换到 ω×ω₁ 上
（h 分量记录秩上界）之后，截面的无穷树枝全体 $[T(\alpha)]$
里有一根**逐点最小**的 g_α = ρ_{U(α)}∘列表——任何其他
树枝 f 满足 ∀n(g_α(n) ≤ f(n))，因为 ρ 是最小赋秩函数
（对每点取「下方无路可走」的高度，天然最小）。于是范数
序列 β_n(α) = g_α(n) 不只是任意的范数列——它继承了最小
性，**这就是强制收敛性的来源**：当 α_i → α 且各 β_n
稳定于 α_n 时，最小树枝的下半连续性保证极限树枝不超过
稳定的上界。「标尺」的物理图像：一列范数像一把带刻度的
尺子竖在 A 上，点列收敛到边界时读数不跳变——集合的
边界行为被刻度序列管住。

**双轨收缩的理由**也值得点破：命题 3.1 的两轨各管一件事
——范数轨保证极限点**还在 A 里**（强制收敛性唯一管的
就是这件事），坐标轨保证极限点**唯一**（第 n 位被压到
最小后，两个不同点必在某位分叉）。抽掉任何一轨都撑不住：
只收缩范数，同范数的整块点可能存活到极限；只收缩坐标，
极限点可能滑出 A（范数在边界跳变）。展示函数定理 3.6 的
一般形式用同一套双轨——对每个 x 在截片 A_x 上跑收缩，
F(x) := 唯一幸存者；「F 是 Π₁¹ 图形」逐条吃标尺的
P、Q 定义式。

## 111.6 可定义性之桥：引理 3.7

**引理 3.7**（书 p271）$A\subseteq\mathcal N$ 是简体
Σ₁¹ ⟺ A 在 $(V_{\omega_1},\in)$ 上 Σ₁-可定义；从而
$\Sigma^1_{n+1}$ ⟺ 在 $(V_{\omega_1},\in)$ 上 Σ_n-可
定义。**骨架**：Σ₁¹ 的存在量词 ∃y 的见证可换成「可数传递
模型 M ∋ y」（相关选择原理），而「M 是可数传递集合」逻辑
等价于「E 自同一、有秩、π_E 是传递化」——WF 的编码再次
出场；表达式的复杂性逐层对齐。这座桥把**拓扑量词层级**
（投影层次）与**逻辑量词层级**（结构可定义性）焊接——
第 112 章 Shoenfield 绝对性将沿这座桥走到 Σ¹₂。

## 111.7 与前章的对照总表

| 维度 | 110 饱和与光影 | 111 精细分层与余解析 |
|---|---|---|
| 主对象 | 商代数 P(ω₁)/NS、[λ]^ω | 投影层次 Σ¹ₙ(α)/Π¹ₙ(α) |
| 核心定理 | PSRP ⟹ 四重馈赠 | 规范形式 + Π₁¹-范数/标尺 |
| 树的角色 | E-序列（同质模型链） | 表示树 T 与良基性 |
| 秩的角色 | Skolem 壳的 club 账 | ρ_T 赋秩函数与 ||α|| |
| 绝对性 | 传递模型内外一致（引理 3.2 的雏形） | 定理 3.2：Π₁¹(α) 绝对 |
| 机器影子 | π/核/反链/反射对 | ρ 递归/完美子树/截面/下降链 |

两章共用「树 + 秩」的骨架但方向相反：110 章在超穷层用
E-序列**反射**（楼上照亮楼下），111 章在可数层用表示树
**编码**（实数 α 折叠成树 T(α)、树论性质回读集合论性质）。
WF 作为两线的交点：它既是 Π₁¹-完全集（本章），又是
$(V_{\omega_1},\in)$ 的 Σ₁-理论的家（引理 3.7）——
第 112–113 章的所有正则性定理都要经过它。

再往深一层看，「秩」这个对象在本教程的三个抽象层各有一
副面孔，对照着读能看清描述集合论的纵贯线：

| 层 | 秩的形态 | 消费者 |
|---|---|---|
| 序数层（94/100 章） | j 的临界点账：crit(j)、j(κ) | 嵌入的像 |
| 理想层（109/110 章） | ‖α‖：E_α 的高度；引理 3.5 的 WF_α 分层 | 有界性、饱和 |
| 实数层（本章） | ρ_T：表示树的赋秩函数；φ(α)=‖T(α)‖ | Π¹¹-范数、标尺 |

三层的秩都是「良基性的度量」：序数层量嵌入崩塌的深度、
理想层量编码关系的序型、实数层量树的「无路可走」的高度。
**有界性引理在每一层都有化身**——序数层的「j 的临界序列
有界」、理想层的「可数族秩有界」、实数层的推论 3.3——
而它们的证明全靠同一个反证形状：「无界的秩允许把 Π 型
性质改写成 Σ 型，与既有的非对称矛盾」。这个反证形状
会在 112 章（Shoenfield 绝对性的高度计算）第四次出场。

## 111.8 机器通道

七个通道做**秩递归层**，五件机器：

1. **树与树枝判定**：有限树（深度上限 D=2，堆编码：根 1、
   子点 2c/2c+1）的**全长树枝** = 从根逐层下行的 D-长路径
   ——HasBranch/have_branch/branch1（引理 3.3 的良基判定：
   有秩 ⟺ 无全长树枝）；
2. **赋秩函数**（ρ 燃料递归：叶 0、内部点 = 子最大秩 + 1）
   与**秩 ≤ 剩余深度**定理件（Lean `rho_le_fuel`（归纳 +
   `split`/`omega` 收口）、Coq `rho_le`（归纳 + lia）、Agda
   `rho≤fuel`（s≤s + 自建 ⊔-le）——引理 3.5 的机制件：
   深度封顶使秩有界）；另有**叶零**引理（双子皆不在树中 ⟹
   ρ=0：Coq `not_in_child`、Agda `not-in-child`）；
3. **完美子树构造**（Julia/Python `perfect_subtree`：双子
   延伸的递归抽取——T2 全二叉、T0 根层即叶——断言二的
   有限替身）；
4. **截面投影**（Julia/Python `projection`/`section_has_
   branch`、Prolog `wit3`/`in_proj`：二维树 S 的截面 S(α)
   有全长见证 y ⟺ α ∈ π[S]——对角树 S_diag 全域投影、
   单侧树 S_side 只投 x 首位 0 的两条 α）；
5. **下降链**（Isabelle `minimal_no_descending`：极小元
   性质（wf_on 的 B-刻画）⟹ 无 ω-长下降链——Replace 造
   值域、极小元反制、确定性规则链收口；Prolog `desc`
   （燃料版下降链 + 极小终点 `all_end_minimal`）与
   `loop_witness`（直接环见证：良基 R_wf 无环、环状 R_cyc
   有环）——引理 3.4 的 WF 对偶）。

先看 Lean 版（`examples/lean/Settheory/Ch111Projective.lean`）：

```lean
import Mathlib.Data.Finset.Basic
import Mathlib.Data.List.Basic

/-!
# 第 111 章 · 投影精细分层与余解析集合

锚点（有限影子）：
- `HasBranch`：全长树枝——定义 3.2 的 [T] 非空的替身；
  有秩树 = 无全长树枝（引理 3.3/定理 3.1 的良基判定）；
- `rho`：赋秩函数的燃料递归（叶 0、内部点 = 子最大 + 1）
  ——秩递归的机制件；
- `rho_le_fuel`：秩不超过燃料（有限树的秩 ≤ 深度——引理 3.5
  「秩有界部分是博雷尔集」的机制件）；
- `branch_imp`：有树枝 ⟺ 树中有全长节点——良基判定的引理；
- 样本账：有秩树 T₀/T₂ 的秩表、无秩树 T₁ 的对照
  （ρ = D 恰是树枝存在的数值影子）。
本体（定义 3.1-3.6、引理 3.1-3.7、定理 3.1-3.6、
推论 3.1-3.5）留在正文。
-/

namespace Settheory.Ch111

open Finset List

/-! ## 一、树与树枝（定义 3.2 的有限替身） -/

/-- 全长树枝：长度恰为深度 D 的路径（[T] 非空的替身）。 -/
def HasBranch (T : Finset (List ℕ)) (D : ℕ) : Prop :=
  ∃ b : List ℕ, b.length = D ∧ ∀ k ≤ D, (b.take k) ∈ T

/-- 有树枝 ⟹ 树中有全长节点（良基判定的桥梁）。 -/
theorem branch_imp (T : Finset (List ℕ)) {D : ℕ} (h : HasBranch T D) :
    ∃ s ∈ T, s.length = D := by
  obtain ⟨b, hb, hmem⟩ := h
  refine ⟨b.take D, hmem D (Nat.le_refl D), ?_⟩
  rw [List.length_take, hb]
  simp

/-! ## 二、赋秩函数（燃料递归） -/

/-- 秩：叶为 0，内部点 = 子点最大秩 + 1；燃料 f 封顶。 -/
def rho (T : Finset (List ℕ)) : ℕ → List ℕ → ℕ
  | 0, _ => 0
  | f + 1, s =>
      if (s ++ [0] ∈ T) || (s ++ [1] ∈ T) then
        (max (rho T f (s ++ [0])) (rho T f (s ++ [1]))) + 1
      else 0

/-- 秩永不超过燃料（有限树的秩 ≤ 深度——秩有界的机制件）。 -/
theorem rho_le_fuel (T : Finset (List ℕ)) :
    ∀ (f : ℕ) (s : List ℕ), rho T f s ≤ f := by
  intro f
  induction f with
  | zero => intro s; simp [rho]
  | succ f ih =>
      intro s
      simp only [rho]
      split
      · next hc =>
          have h0 := ih (s ++ [0])
          have h1 := ih (s ++ [1])
          omega
      · omega

/-! ## 三、样本账（决定性核查） -/

/-- 样本树 T₀：深度 2 的有秩树（无全长树枝）。 -/
def T₀ : Finset (List ℕ) := {[], [0], [1]}

example : ¬ HasBranch T₀ 2 := by
  intro h
  obtain ⟨s, hs, hlen⟩ := branch_imp T₀ h
  simp only [T₀, Finset.mem_insert, Finset.mem_singleton] at hs
  rcases hs with rfl | rfl | rfl <;> exact absurd hlen (by decide)

/-- T₀ 的秩账：根秩 1（两个子点都是叶）。 -/
example : rho T₀ 2 [] = 1 := by decide

/-- 样本树 T₁：无秩树（含全长树枝）。 -/
def T₁ : Finset (List ℕ) := {[], [0], [1], [0, 0]}

example : HasBranch T₁ 2 := by
  refine ⟨[0, 0], rfl, ?_⟩
  intro k _
  cases k with
  | zero => simp [T₁]
  | succ k =>
    cases k with
    | zero => simp [T₁]
    | succ k =>
      cases k with
      | zero => simp [T₁]
      | succ k => omega

/-- ρ = D 恰是树枝存在的数值影子。 -/
example : rho T₁ 2 [] = 2 := by decide

/-- 深度 3 的有秩树 T₂：秩表（根 2、中层 1、叶 0）。 -/
def T₂ : Finset (List ℕ) := {[], [0], [1], [0, 0], [0, 1]}

example : ¬ HasBranch T₂ 3 := by
  intro h
  obtain ⟨s, hs, hlen⟩ := branch_imp T₂ h
  simp only [T₂, Finset.mem_insert, Finset.mem_singleton] at hs
  rcases hs with rfl | rfl | rfl | rfl | rfl <;> exact absurd hlen (by decide)

example : rho T₂ 3 [] = 2 := by decide
example : rho T₂ 3 [0] = 1 := by decide
example : rho T₂ 3 [0, 0] = 0 := by decide

/-- 秩 ≤ 燃料（定理应用于样本）。 -/
example : ∀ s ∈ T₂, rho T₂ 3 s ≤ 3 := by
  intro s _
  have := rho_le_fuel T₂ 3 s
  omega

end Settheory.Ch111
```

`rho_le_fuel` 的 succ 步用 `simp only [rho]` + `split`：
if-分支的 Bool 条件 `(s++[0]∈T) || (s++[1]∈T)` 被 split
分成两支，真支的 `max … + 1 ≤ f+1` 由两个归纳假设交给
omega（omega 认识 max——这条比 110 章的 min'-嵌入省事）。
样本账里三个 decide 是 ρ 的字面核算；`branch_imp` 把
「树枝存在」翻译成「有全长节点」，配合 T 的字面展开 +
`absurd hlen (by decide)` 关闭一切反例分支——**良基判定
的数值面（无全长节点）与结构面（无树枝）在有限宇宙内
等价**，这是引理 3.3(2) 对偶的可判定内核。

Coq 版（`examples/coq/Ch111_projective.v`）：

```coq
(* 第 111 章：有限树良基判定与秩递归——余解析集树表示的影子。 *)
From Coq Require Import List Arith Lia.
Import ListNotations.

Module Ch111.

(* ── 一、树与树枝（定义 3.2 的有限替身） ── *)

(* 全长树枝 = 长度 D 的路径。 *)
Definition has_branch (T : list (list nat)) (D : nat) : Prop :=
  exists b, length b = D /\ forall k, k <= D -> In (firstn k b) T.

(* 有树枝 ⟹ 树中有全长节点。 *)
Lemma branch_imp : forall T D,
    has_branch T D -> exists s, In s T /\ length s = D.
Proof.
  intros T D [b [hb hmem]].
  exists (firstn D b). split.
  - apply hmem; lia.
  - rewrite length_firstn, hb, Nat.min_id. reflexivity.
Qed.

(* ── 二、赋秩函数（燃料递归：叶 0、内部点 = 子最大 + 1） ── *)

Fixpoint rho (T : list (list nat)) (f : nat) (s : list nat) : nat :=
  match f with
  | 0 => 0
  | S f' =>
      if orb (if in_dec (list_eq_dec Nat.eq_dec) (s ++ [0]) T
              then true else false)
             (if in_dec (list_eq_dec Nat.eq_dec) (s ++ [1]) T
              then true else false)
      then S (max (rho T f' (s ++ [0])) (rho T f' (s ++ [1])))
      else 0
  end.

(* 秩不超过燃料（引理 3.5「秩有界」的机制件）。 *)
Lemma rho_le : forall T f s, rho T f s <= f.
Proof.
  intros T f. induction f as [|f ih]; intros s.
  - reflexivity.
  - simpl. destruct (orb _ _).
    + assert (h0 := ih (s ++ [0])). assert (h1 := ih (s ++ [1])).
      lia.
    + lia.
Qed.

(* 双子皆不在树中 ⟹ 秩为 0（叶判定的数值面）。 *)
Lemma not_in_child : forall T f s,
    ~ In (s ++ [0]) T -> ~ In (s ++ [1]) T -> rho T (S f) s = 0.
Proof.
  intros T f s H0 H1. simpl.
  destruct (in_dec (list_eq_dec Nat.eq_dec) (s ++ [0]) T) as [Hi|Ni0];
  destruct (in_dec (list_eq_dec Nat.eq_dec) (s ++ [1]) T) as [Hj|Ni1];
  try reflexivity.
  - exfalso; exact (H0 Hi).
  - exfalso; exact (H0 Hi).
  - exfalso; exact (H1 Hj).
Qed.

(* ── 三、样本账（决定性核查） ── *)

Definition T0 : list (list nat) := [[]; [0]; [1]].
Definition T1 : list (list nat) := [[]; [0]; [1]; [0; 0]].
Definition T2 : list (list nat) := [[]; [0]; [1]; [0; 0]; [0; 1]].

(* T0 无长度 2 的树枝（有秩树）。 *)
Example no_branch_T0 : ~ has_branch T0 2.
Proof.
  intros H. apply branch_imp in H. destruct H as [s [Hs Hlen]].
  simpl in Hs. destruct Hs as [Heq|[Heq|[Heq|[]]]];
    subst s; simpl in Hlen; discriminate.
Qed.

(* T1 有全长树枝（无秩树）。 *)
Example branch_T1 : has_branch T1 2.
Proof.
  exists [0; 0]. split; [reflexivity|].
  intros k Hk. destruct k as [|[|[|k]]]; simpl; auto.
Qed.

(* 秩账：有秩 T0 根秩 1；无秩 T1 根秩 2（= 深度）。 *)
Example rho_T0 : rho T0 2 [] = 1.
Proof. reflexivity. Qed.

Example rho_T1 : rho T1 2 [] = 2.
Proof. reflexivity. Qed.

(* T2 的秩表：根 2、中层 1、叶 0。 *)
Example rho_T2 : rho T2 3 [] = 2 /\ rho T2 3 [0] = 1 /\ rho T2 3 [0;0] = 0.
Proof. repeat split; reflexivity. Qed.

End Ch111.
```

Coq 侧两坑：`if in_dec … then true else false` 的桥（Prop 到
Bool——in_dec 的 sumbool 直接做 if 条件会被 orb 拒绝，须先转
Bool）；`not_in_child` 的三分案里 Hi/Hj 的出现顺序——四个
destruct 分支中三个不闭，剩下的用 H0/H1 直接反证（`try
reflexivity` 先吃掉全 Negative 的那一支）。

Agda 版（`examples/agda/Ch111_projective.agda`）：

```agda
-- 第 111 章：有限树良基判定与秩递归——余解析集树表示的影子。
module Ch111_projective where

open import Data.Nat using (ℕ; zero; suc; _⊔_; _≤_; z≤n; s≤s)
open import Data.Nat.Properties using (≤-trans)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

cong₂ : {A B C : Set} (f : A → B → C) {x y : A} {u v : B} →
         x ≡ y → u ≡ v → f x u ≡ f y v
cong₂ f refl refl = refl
open import Data.List using (List; []; _∷_; _++_)
open import Data.List.Relation.Unary.Any using (Any; here; there)
open import Data.Product using (_×_; _,_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)
open import Relation.Nullary using (Dec; yes; no; ¬_)
open import Data.Empty using (⊥; ⊥-elim)

-- ── 零、自建件（沿 109/110 章 Dec 路线） ──

pred : ℕ → ℕ
pred zero = zero
pred (suc k) = k

nat-eq-dec : (x y : ℕ) → Dec (x ≡ y)
nat-eq-dec zero zero = yes refl
nat-eq-dec zero (suc _) = no (λ ())
nat-eq-dec (suc _) zero = no (λ ())
nat-eq-dec (suc m) (suc n) with nat-eq-dec m n
... | yes e = yes (cong suc e)
... | no ne = no (λ se → ne (cong pred se))

inL-dec : (x : List ℕ) (l : List (List ℕ)) → Dec (Any (x ≡_) l)
inL-dec x [] = no (λ ())
inL-dec x (y ∷ ys) with nat-eq-head x y
  where
  nat-eq-head : (a b : List ℕ) → Dec (a ≡ b)
  nat-eq-head [] [] = yes refl
  nat-eq-head [] (z ∷ _) = no (λ ())
  nat-eq-head (w ∷ _) [] = no (λ ())
  nat-eq-head (w ∷ ws) (z ∷ zs) with nat-eq-dec w z
  ... | no nwz = no (λ e → nwz (cong hd e))
    where
    hd : List ℕ → ℕ
    hd [] = zero
    hd (h ∷ _) = h
  ... | yes ewz with nat-eq-head ws zs
  ...   | no nws = no (λ e → nws (cong tl e))
    where
    tl : List ℕ → List ℕ
    tl [] = []
    tl (_ ∷ t) = t
  ...   | yes ews = yes (cong₂ _∷_ ewz ews)
inL-dec x (y ∷ ys) | yes exy = yes (here exy)
inL-dec x (y ∷ ys) | no nxy with inL-dec x ys
... | yes e = yes (there e)
... | no ne = no nd
  where
  nd : Any (x ≡_) (y ∷ ys) → ⊥
  nd (here e) = nxy e
  nd (there e) = ne e

-- ── 一、赋秩函数（燃料递归：叶 0、内部点 = 子最大 + 1） ──

rho : List (List ℕ) → ℕ → List ℕ → ℕ
rho T zero _ = zero
rho T (suc f) s with inL-dec (s ++ zero ∷ []) T | inL-dec (s ++ suc zero ∷ []) T
rho T (suc f) s | yes _ | yes _ = suc (rho T f (s ++ zero ∷ []) ⊔ rho T f (s ++ suc zero ∷ []))
rho T (suc f) s | yes _ | no _  = suc (rho T f (s ++ zero ∷ []) ⊔ rho T f (s ++ suc zero ∷ []))
rho T (suc f) s | no _  | yes _ = suc (rho T f (s ++ zero ∷ []) ⊔ rho T f (s ++ suc zero ∷ []))
rho T (suc f) s | no _  | no _  = zero

-- ── 二、秩不超过燃料（引理 3.5「秩有界」的机制件） ──

⊔-le : ∀ {a b f : ℕ} → a ≤ f → b ≤ f → a ⊔ b ≤ f
⊔-le z≤n hb = hb
⊔-le {suc a} {zero} ha z≤n = ha
⊔-le {suc a} {suc b} {suc f} (s≤s ha) (s≤s hb) = s≤s (⊔-le ha hb)

rho≤fuel : (T : List (List ℕ)) (f : ℕ) (s : List ℕ) → rho T f s ≤ f
rho≤fuel T zero s = z≤n
rho≤fuel T (suc f) s with inL-dec (s ++ zero ∷ []) T | inL-dec (s ++ suc zero ∷ []) T
rho≤fuel T (suc f) s | yes _ | yes _ = s≤s (⊔-le (rho≤fuel T f (s ++ zero ∷ []))
                                                   (rho≤fuel T f (s ++ suc zero ∷ [])))
rho≤fuel T (suc f) s | yes _ | no _  = s≤s (⊔-le (rho≤fuel T f (s ++ zero ∷ []))
                                                   (rho≤fuel T f (s ++ suc zero ∷ [])))
rho≤fuel T (suc f) s | no _ | yes _ = s≤s (⊔-le (rho≤fuel T f (s ++ zero ∷ []))
                                                   (rho≤fuel T f (s ++ suc zero ∷ [])))
rho≤fuel T (suc f) s | no _ | no _ = z≤n
-- ── 三、叶判定（双子皆不在树中 ⟹ 秩为 0） ──

not-in-child : (T : List (List ℕ)) (f : ℕ) (s : List ℕ) →
               ¬ (Any (s ++ zero ∷ [] ≡_) T) → ¬ (Any (s ++ suc zero ∷ [] ≡_) T) →
               rho T (suc f) s ≡ zero
not-in-child T f s n0 n1 with inL-dec (s ++ zero ∷ []) T | inL-dec (s ++ suc zero ∷ []) T
not-in-child T f s n0 n1 | yes h0 | _ = ⊥-elim (n0 h0)
not-in-child T f s n0 n1 | no _ | yes h1 = ⊥-elim (n1 h1)
not-in-child T f s n0 n1 | no _ | no _ = refl

-- ── 四、样本账（决定性核查） ──

T₀ : List (List ℕ)
T₀ = [] ∷ (zero ∷ []) ∷ (suc zero ∷ []) ∷ []

T₁ : List (List ℕ)
T₁ = [] ∷ (zero ∷ []) ∷ (suc zero ∷ []) ∷ (zero ∷ zero ∷ []) ∷ []

T₂ : List (List ℕ)
T₂ = [] ∷ (zero ∷ []) ∷ (suc zero ∷ []) ∷ (zero ∷ zero ∷ []) ∷ (zero ∷ suc zero ∷ []) ∷ []

-- T₀ 根秩 1（两子皆叶）；T₁ 根秩 2（= 深度，无秩树的数值影子）。
rho-T₀ : rho T₀ (suc (suc zero)) [] ≡ suc zero
rho-T₀ = refl

rho-T₁ : rho T₁ (suc (suc zero)) [] ≡ suc (suc zero)
rho-T₁ = refl

-- T₂ 的秩表：根 2、中层 1、叶 0。
rho-T₂-root : rho T₂ (suc (suc (suc zero))) [] ≡ suc (suc zero)
rho-T₂-root = refl

rho-T₂-mid : rho T₂ (suc (suc (suc zero))) (zero ∷ []) ≡ suc zero
rho-T₂-mid = refl

rho-T₂-leaf : rho T₂ (suc (suc (suc zero))) (zero ∷ zero ∷ []) ≡ zero
rho-T₂-leaf = refl
```

Agda 本章两坑：`cong₂` 的自建（PropositionalEquality 不导出
双参 congr，`_∷_` 的等式传递要 `cong₂ _∷_ ewz ews`）；
`⊔-le` 的模式必须**显式分层**——`⊔-le ha z≤n` 在 a 未定形时
`a ⊔ zero` 不定义性归一到 a（首版被 UnequalTerms 抓），改按
a/二进制首构造子分案（zero 行吃 z≤n、suc/zero 行直通、
suc/suc 行 s≤s 递归）。

Isabelle 版（`examples/isabelle/ST111/Projective.thy`）走
**引理 3.4 的 WF 对偶**：

```isabelle
theory Projective
  imports "ZF.Nat" "ZF.equalities"
begin

text \<open>第 111 章：良基关系的无下降链判定（确定性规则链，沿 103-110 章纪律）。
这是引理 3.4 的核心：α 记录有秩关系 ⟺ 不存在下降链
f: nat → field 使 (f(n+1), f(n)) ∈ E_α——WF 的对偶刻画。
本体（定义 3.1-3.6、引理 3.1-3.7、定理 3.1-3.6）留在正文。\<close>

text \<open>hmin 是 wf_on 的 B-刻画（ZF 的 wf_on_def2）：每个非空子集有极小元。\<close>

lemma minimal_no_descending:
  assumes hmin: "\<forall>B. B \<subseteq> A \<and> B \<noteq> 0 \<longrightarrow>
      (\<exists>x\<in>B. \<forall>y. <y, x> \<in> r \<longrightarrow> y \<notin> B)"
    and hf: "f \<in> nat -> A"
    and hchain: "\<forall>n \<in> nat. <f ` succ(n), f ` n> \<in> r"
  shows "False"
proof -
  let ?B = "Replace(nat, \<lambda>n y. y = f ` n)"
  have hsub: "?B \<subseteq> A"
  proof (rule subsetI)
    fix y
    assume hy: "y \<in> ?B"
    then obtain n where hn: "n \<in> nat" and hye: "y = f ` n"
      by (rule ReplaceE)
    from hf hn have "f ` n \<in> A" by (rule apply_type)
    with hye show "y \<in> A" by simp
  qed
  have hne: "?B \<noteq> 0"
  proof (rule notI)
    assume h0: "?B = 0"
    have hf0: "f ` 0 \<in> ?B"
    proof (rule ReplaceI [of _ 0])
      show "0 \<in> nat" by (rule nat_0I)
    next
      show "f ` 0 = f ` 0" by (rule refl)
    qed
    from h0 hf0 have "f ` 0 \<in> 0" by simp
    then show "False" by (rule emptyE)
  qed
  from hmin have hinst: "?B \<subseteq> A \<and> ?B \<noteq> 0 \<longrightarrow>
      (\<exists>x\<in>?B. \<forall>y. <y, x> \<in> r \<longrightarrow> y \<notin> ?B)"
    by (rule spec)
  from hinst hsub hne obtain x where
    hx: "x \<in> ?B" and hmin0: "\<forall>y. <y, x> \<in> r \<longrightarrow> y \<notin> ?B"
    by auto
  from hx obtain k where hk: "k \<in> nat" and hxe: "x = f ` k"
    by (rule ReplaceE)
  from hchain hk have hstep: "<f ` succ(k), f ` k> \<in> r" by (rule bspec)
  from hxe have hfk: "f ` k = x" by simp
  from hfk hstep have hstepx: "<f ` succ(k), x> \<in> r" by simp
  from hmin0 have hinst2: "<f ` succ(k), x> \<in> r \<longrightarrow> f ` succ(k) \<notin> ?B"
    by (rule spec [where x = "f ` succ(k)"])
  from hinst2 hstepx have hnot: "f ` succ(k) \<notin> ?B" by (rule mp)
  have hmem: "f ` succ(k) \<in> ?B"
  proof (rule ReplaceI [of _ "succ(k)"])
    from hk show "succ(k) \<in> nat" by (rule nat_succ_iff [THEN iffD2])
  next
    show "f ` succ(k) = f ` succ(k)" by (rule refl)
  qed
  from hnot hmem show "False" by (rule notE)
qed

end
```

证明的骨架就是正文 WF 刻画的 ZFC 版：**值域 Replace(nat, f)
是非空子集 → 极小元 x = f`k → 链的下一步 f`succ(k) 落在值域
→ 与极小性矛盾**。三处确定性细节：Replace 的双参谓词形态
（`λn y. y = f`n`——单参版本会被 ZF 的 Replace 算子拒绝）；
`spec [where x = …]` 的显式实例化（链式事实毒化第四记：
from + 带参规则必须让前提可消费）；`nat_succ_iff [THEN iffD2]`
供给 succ(k) ∈ nat。

Julia 版（`examples/julia/111_projective.jl`）：

```julia
# 第 111 章：有限树秩递归、完美子树与截面投影——余解析集树表示的影子。
println("==== 111")

# ── 一、树（堆编码：根 1，子点 2c / 2c+1；深度上限 2） ──
child(c::Int, b::Int) = 2c + b
parent(c::Int) = c ÷ 2
depthd(c::Int) = (d = 0; cc = c; while cc > 1; cc ÷= 2; d += 1; end; d)
const MAXD = 2

# 秩：叶 0、内部点 = 子最大 + 1（引理 3.5 的赋秩机制）。
function rho(T::Set{Int}, c::Int = 1)
    c ∈ T || return 0
    depthd(c) >= MAXD && return 0
    c0, c1 = 2c, 2c + 1
    c0 ∉ T && c1 ∉ T && return 0
    return 1 + max(c0 ∈ T ? rho(T, c0) : 0, c1 ∈ T ? rho(T, c1) : 0)
end

# 有树枝（无秩）⟺ 存在长度 MAXD 的路径（引理 3.3 的良基判定）。
has_branch(T::Set{Int}, c::Int = 1, d::Int = 0) =
    c ∈ T && (d == MAXD || has_branch(T, 2c, d + 1) || has_branch(T, 2c + 1, d + 1))

# ── 二、三棵样本树的秩账 ──
const T0 = Set([1, 2, 3])          # 根+两子：有秩，根秩 1
const T1 = Set([1, 2, 3, 4])       # 左枝到底：无秩，根秩 2 = 深度
const T2 = Set([1, 2, 3, 4, 5])    # 左右皆底：无秩，根秩 2

@assert rho(T0) == 1 && !has_branch(T0)
@assert rho(T1) == MAXD && has_branch(T1)
@assert rho(T2) == MAXD && has_branch(T2)

# 秩 ≤ 剩余深度（秩有界部分博雷尔的机制件）。
for T in (T0, T1, T2), c in collect(T)
    @assert rho(T, c) <= MAXD - depthd(c)
end

# ── 三、完美子树构造（开区分特性断言二：双子延伸） ──
function perfect_subtree(T::Set{Int}, c::Int = 1, d::Int = 0)
    c ∈ T || return Set{Int}()
    d >= MAXD && return Set{Int}([c])
    c0, c1 = 2c, 2c + 1
    if c0 ∈ T && c1 ∈ T
        return union(Set{Int}([c]),
                     perfect_subtree(T, c0, d + 1),
                     perfect_subtree(T, c1, d + 1))
    end
    return Set{Int}([c])           # 此处不再二叉分裂：子树在此封顶
end

P2 = perfect_subtree(T2)
@assert P2 == Set([1, 2, 3, 4, 5]) # 全树都是完美二叉（到深度 2）
P0 = perfect_subtree(T0)
@assert 2 in P0 && 3 in P0         # 根层分裂
@assert !(4 in P0)                 # 深度 1 层无分裂（叶）

# ── 四、二维树与截面投影（引理 3.3：A = p[S] ⟺ S(α) 无秩） ──
# 二维树 S：等长位串对（xs, ys）的前段封闭集。
# 截面 S(α) = {ys | (α[1:len(ys)], ys) ∈ S}；截面有树枝 ⟺
# ∃ y（全长）使一切前段对都在 S。
branches2() = [[a, b] for a in 0:1 for b in 0:1]

function section_has_branch(S::Set{Tuple{Vector{Int},Vector{Int}}}, α::Vector{Int})
    for y in branches2()
        ok = all((α[1:k], y[1:k]) in S for k in 0:MAXD)
        ok && return true
    end
    return false
end

projection(S) = Set(α for α in branches2() if section_has_branch(S, α))

# 对角二维树：xs = ys 的全部前段对——每个 α 都有树枝（对角线见证）。
S_diag = Set{Tuple{Vector{Int},Vector{Int}}}()
for n in 0:MAXD
    for (a, b) in ((0, 0), (0, 1), (1, 0), (1, 1))
        p = [a, b][1:n]
        push!(S_diag, (p, copy(p)))
    end
end
@assert length(S_diag) == 1 + 2 + 4    # n=0 一个、n=1 两个、n=2 四个
@assert projection(S_diag) == Set(branches2())

# 单侧二维树：只允许 x 首位为 0 的 α 有见证。
S_side = Set{Tuple{Vector{Int},Vector{Int}}}([(Int[], Int[])])
push!(S_side, ([0], [0]))
push!(S_side, ([0], [1]))
push!(S_side, ([1], [0]))
for b in 0:1, c in 0:1
    push!(S_side, ([0, b], [c, b]))
end
@assert projection(S_side) == Set([[0, 0], [0, 1]])
@assert !([1, 0] in projection(S_side))

println("Julia：三树秩账（1/2/2）+树枝判定；秩≤剩余深度；")
println("完美子树（T2 全二叉/T0 根层即叶）；对角与单侧二维树的投影账")
println("END ====")
```

三处实现账：has_branch 的合取形态（首版先判 d==MAXD 再查
成员——节点 4 ∉ T₀ 也会因 d 封顶而误报树枝，被 `rho(T0)==1
&& !has_branch(T0)` 联合断言击中后改为 `c∈T && (d==MAXD ∨ …)`）；
`projection` 的成员测试必须写成**元组** `(α[1:k], y[1:k]) in S`
（首版误写为数组字面量 `[α[1:k], y[1:k]] in S`——类型不匹配
静默全 false，投影恒空）；S_diag 的类账 1+2+4（n=1 层的四个
对中 ([0],[0]) 与 ([1],[1]) 去重后恰两个）。

Python 版（`examples/python/111_projective.py`）同账对拍
（元组路径版）：

```python
# 第 111 章：与 Julia 独立对拍——秩递归、完美子树与截面投影。
import io
import sys

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

MAXD = 2


def child(c, b):
    return 2 * c + b


def parent(c):
    return c // 2


def depthd(c):
    d = 0
    while c > 1:
        c //= 2
        d += 1
    return d


def rho(T, c=1):
    if c not in T:
        return 0
    if depthd(c) >= MAXD:
        return 0
    c0, c1 = 2 * c, 2 * c + 1
    if c0 not in T and c1 not in T:
        return 0
    return 1 + max(rho(T, c0) if c0 in T else 0,
                   rho(T, c1) if c1 in T else 0)


def has_branch(T, c=1, d=0):
    if c not in T:
        return False
    if d == MAXD:
        return True
    return has_branch(T, 2 * c, d + 1) or has_branch(T, 2 * c + 1, d + 1)


def perfect_subtree(T, c=1, d=0):
    if c not in T:
        return frozenset()
    if d >= MAXD:
        return frozenset({c})
    c0, c1 = 2 * c, 2 * c + 1
    if c0 in T and c1 in T:
        return frozenset({c}) | perfect_subtree(T, c0, d + 1) | perfect_subtree(T, c1, d + 1)
    return frozenset({c})


def branches2():
    return [(a, b) for a in range(2) for b in range(2)]


def section_has_branch(S, alpha):
    # alpha 是长度 MAXD 的元组；截面有树枝 ⟺ ∃ y 全长使前段对全在 S。
    for y in branches2():
        if all((alpha[:k], y[:k]) in S for k in range(MAXD + 1)):
            return True
    return False


def projection(S):
    return frozenset(a for a in branches2() if section_has_branch(S, a))


def main():
    print("==== 111")
    T0 = frozenset({1, 2, 3})
    T1 = frozenset({1, 2, 3, 4})
    T2 = frozenset({1, 2, 3, 4, 5})
    assert rho(T0) == 1 and not has_branch(T0)
    assert rho(T1) == MAXD and has_branch(T1)
    assert rho(T2) == MAXD and has_branch(T2)
    for T in (T0, T1, T2):
        for c in T:
            assert rho(T, c) <= MAXD - depthd(c)

    assert perfect_subtree(T2) == frozenset({1, 2, 3, 4, 5})
    P0 = perfect_subtree(T0)
    assert 2 in P0 and 3 in P0 and 4 not in P0

    # 对角二维树：每个 α 都有对角线见证。
    S_diag = set()
    for n in range(MAXD + 1):
        for a in branches2():
            p = a[:n]
            S_diag.add((p, p))
    assert len(S_diag) == 1 + 2 + 4
    assert projection(S_diag) == frozenset(branches2())

    # 单侧二维树：只允许 x 首位为 0 的 α 有见证。
    S_side = {((), ())}
    S_side.add(((0,), (0,)))
    S_side.add(((0,), (1,)))
    S_side.add(((1,), (0,)))
    for b in range(2):
        for c in range(2):
            S_side.add(((0, b), (c, b)))
    assert projection(S_side) == frozenset({(0, 0), (0, 1)})
    assert (1, 0) not in projection(S_side)

    print("Python：三树秩账（1/2/2）+树枝判定；秩≤剩余深度；")
    print("完美子树（T2 全二叉/T0 根层即叶）；对角与单侧二维树的投影账——与 Julia 对拍一致")
    print("END ====")


if __name__ == "__main__":
    main()
```

Prolog 版（`examples/prolog/111_projective.pl`）：

```prolog
:- encoding(utf8).
% 第 111 章：有限树秩递归、下降链搜索与截面投影见证查询。

% ── 一、树（堆编码：根 1，子点 2c/2c+1；深度上限 2） ──
depthd(1, 0) :- !.
depthd(C, D) :- C > 1, P is C // 2, depthd(P, D0), D is D0 + 1.

% 秩：叶 0、内部点 = 子最大 + 1（引理 3.5 的赋秩机制）。
rho(T, C, 0) :- \+ member(C, T), !.
rho(T, C, 0) :- depthd(C, 2), !.
rho(T, C, R) :-
    C0 is 2 * C, C1 is 2 * C + 1,
    ( member(C0, T) -> rho(T, C0, R0) ; R0 = 0 ),
    ( member(C1, T) -> rho(T, C1, R1) ; R1 = 0 ),
    ( ( \+ member(C0, T), \+ member(C1, T) ) -> R = 0
    ; R is 1 + max(R0, R1) ), !.

% 树枝（无秩）：从根逐层下行的全长路径（显式深度推进）。
branch(T, P) :- branch1(T, 1, 0, P).
branch1(T, C, 2, [C]) :- !, member(C, T).
branch1(T, C, D, [C | Rest]) :-
    D < 2, member(C, T),
    ( CC is 2 * C ; CC is 2 * C + 1 ),
    D1 is D + 1, branch1(T, CC, D1, Rest).

has_branch(T) :- branch(T, _).

% ── 二、下降链搜索（引理 3.4 的 WF 对偶） ──
% 关系 R 上的下降链：member((Y,X),R) 读作 Y 在 X 下方。
% 带燃料的有限链 + 极小终点 + 直接环见证。
desc(R, [X], _) :- \+ (member((Y, X), R), Y \= X).
desc(R, [X | T], N) :-
    N > 1, member((Y, X), R), Y \= X,
    N1 is N - 1, desc(R, T, N1).

% 直接环见证：X、Y 互相在对方下方（无穷下降的种子）。
loop_witness(R, X, Y) :- member((Y, X), R), member((X, Y), R), X \= Y.

all_end_minimal(R) :-
    forall(desc(R, C, 3), (append(_, [M], C), \+ member((Y, M), R), Y \= M)).

% ── 三、截面投影见证（引理 3.3：α ∈ p[S] ⟺ S(α) 有全长见证 y） ──
% 二维树 S 的对以等长表给出；见证 = 三层前段对全在 S。
wit3(S, [A, B], [C, D]) :-
    member(([], []), S),
    member(([A], [C]), S),
    member(([A, B], [C, D]), S).

in_proj(S, Alpha) :- length(Alpha, 2), wit3(S, Alpha, _).

% ── 四、主查询 ──
main :-
    format("==== 111~n"),
    % 三树秩账。
    T0 = [1,2,3], T1 = [1,2,3,4], T2 = [1,2,3,4,5],
    rho(T0, 1, 1), rho(T1, 1, 2), rho(T2, 1, 2),
    \+ has_branch(T0),
    has_branch(T1), has_branch(T2),
    branch(T1, [1,2,4]),
    % 下降链：良基关系一切链终于极小元、无环；环状关系有环见证。
    R_wf = [(1,2),(2,3)],
    R_cyc = [(1,2),(2,1)],
    all_end_minimal(R_wf),
    \+ (loop_witness(R_wf, _, _)),
    loop_witness(R_cyc, 1, 2),
    desc(R_wf, [3,2,1], 3),
    % 截面投影：对角树全域投影；单侧树只投 x 首位 0。
    S_diag = [([],[]),([0],[0]),([1],[1]),
              ([0,0],[0,0]),([0,1],[0,1]),([1,0],[1,0]),([1,1],[1,1])],
    forall((between(0,1,A), between(0,1,B)),
           in_proj(S_diag, [A,B])),
    S_side = [([],[]),([0],[0]),([0],[1]),([1],[0]),
              ([0,0],[0,0]),([0,0],[1,0]),([0,1],[0,1]),([0,1],[1,1])],
    in_proj(S_side, [0,0]), in_proj(S_side, [0,1]),
    \+ in_proj(S_side, [1,0]), \+ in_proj(S_side, [1,1]),
    wit3(S_diag, [0,1], [0,1]),             % 对角见证可查
    wit3(S_side, [0,1], [1,1]),             % 单侧见证（x=0 允许 y 双选）
    format("三树秩账（1/2/2）；树枝见证；良基无环/环状有环；对角/单侧投影账~n"),
    writeln("END ====").
```

Prolog 本章两坑：`depthd` 的**缺守卫死循环**（C=0 时
`P is 0//2 = 0` 递归自身——加 `C > 1` 守卫后 0 与 1 都被封）；
`branch` 的**尾继承错误**（首版 `[CC|Rest]` 把查询尾原样下传
——[2,4] 递归成 [4,4]，改为 branch1 显式深度推进 + 路径逐步
消费）。`wit3` 以三层前段对直陈「见证」——非确定性见证
（S_side 在 α=[0,1] 处 y 可取 [0,1] 或 [1,1]）由回溯枚举。

七份源码的**分工总账**（件号对应 111.8 开头的清单）：

| 件 | Lean | Coq | Agda | Isabelle | Julia/Py | Prolog |
|---|---|---|---|---|---|---|
| ① 树枝判定 | HasBranch + branch_imp | has_branch ± | —（由 ρ refl 承担） | — | has_branch | branch1 |
| ② ρ 递归 + 界 | rho_le_fuel | rho_le + not_in_child | rho≤fuel + not-in-child | — | rho + 界断言 | rho |
| ③ 完美子树 | — | — | — | — | perfect_subtree | — |
| ④ 截面投影 | — | — | — | — | projection | wit3/in_proj |
| ⑤ 下降链 | — | — | — | minimal_no_descending | — | desc/loop_witness |

分工的原则沿第七–十二章的惯例：**定理件给最强的证明助理**
（Lean 拿 ρ 的归纳界；Isabelle 拿最贴 ZF 风格的极小元–无链
对偶——Replace 造值域是 ZF 特有的形态）；**数值件给可执行
的语义面**（Julia/Python 的完美子树与截面投影是纯构造性
算法，Prolog 的回溯见证体现存在量词的非确定性）。每件
机器至少出现在两个通道（对拍或定理+数值双证），没有孤件。

## 111.9 机器的边界

**覆盖**（秩递归层，全部有限可判定）：

- 有限树的全长树枝判定（有秩 ⟺ 无树枝——引理 3.3 的内核）；
- ρ 燃料递归 + 秩 ≤ 剩余深度定理件（四助理）+ 叶零引理
  （Coq/Agda）；
- 完美子树的双子延伸抽取（Julia/Python——断言二的替身）；
- 二维树截面与投影（对角全域、单侧半域——引理 3.3(2) 的
  「α ∈ A ⟺ T(α) 无秩」语义演算）；
- 下降链对偶（Isabelle 极小元 ⟹ 无链定理 + Prolog 燃料链/
  环见证——引理 3.4 的 WF 刻画）。

**不覆盖**（本体，无穷层）：

- **无穷位串与 [T]**：树枝是 ω-长对象；有限宇宙只有 D-长
  路径，「有秩 ⟺ 无全长路径」是引理 3.3 的可判定内核，不是
  良基性本身（良基性在无穷树上需要赋秩函数的存在性——
  定理 3.2 的理论依赖）；
- **博雷尔复杂性**：引理 3.5 的对 α<ω₁ 超穷归纳（WF_α 的
  层级）在有限层退化为「ρ ≤ D」一行——博雷尔 σ-代数的
  结构完全不可见；
- **完全性与归结**：定理 3.3 的连续归结 f（α 编码 T(α)）与
  推论 3.2（非 Σ₁¹）都是无穷对象的存在性论证；
- **有界性引理**：可数集的秩上确界 < ω₁ 依赖推论 3.2 反证
  ——「可数」与「ω₁」都不可有限化；
- **范数/标尺/展示函数**：定理 3.4/3.5/3.6 的 P、Q 定义式
  涉及实数存在量词与保序映射——秩的数值面（ρ 表）只是
  φ(α) = ||T(α)|| 的最浅一层。
- **引理 3.7 的桥面**：(V_ω₁,∈) 的可定义性要穿越「可数
  传递模型」的全体——传递闭包的真值绝对性在有限宇宙
  没有任何对应物。

补一条「机器↔本体」的对读表，作为边界清单的索引：

| 正文定理 | 用的无穷结构 | 机器影子 | 影子缺什么 |
|---|---|---|---|
| 引理 3.3 良基判定 | ω-长树枝 | D-长路径枚举 | ω |
| 引理 3.5 WF_α 博雷尔 | 对 α<ω₁ 超穷归纳 | ρ ≤ D 一行 | 归纳的层积 |
| 定理 3.3 完全性 | f 的逐坐标连续性 | projection 查询 | 递归性与归结 |
| 推论 3.3 有界性 | 可数枚举编码成实数 | max(R)（显然有界） | 「可数」的消费 |
| 定理 3.4/3.5 范数标尺 | 保序映射 ∃ 与最小树枝 | ρ 的数值表 | P/Q 的层次定义 |
| 定理 3.6 展示函数 | 截片上的双轨收缩 | —（无对应件） | 全部 |

一处口径钉死：机器的「截面投影」演算的是**引理 3.3(2) 的
语义等价**（α ∈ π[S] ⟺ 截面有全长见证 y），这是定义层的
账；正文用它推出的一切（解析性、Π₁¹ 性、绝对性）都还要
**无穷侧的结构**（递归性、传递模型、赋秩函数）——正如
108 章的 32×32 穷举之于 PFA，截面账是引擎的点火件，不是
行程本身。

「有秩/无秩」在有限宇宙与无穷宇宙的**语义差**也要说透。
有限宇宙里，「有秩 ⟺ 无 D-长路径」是**可判定的**——
枚举一切路径即可（机器件①照此实现）；无穷宇宙里，
「T(α) 有秩」是 Π₁¹ 性质（对全体实数 y 的全程量词），
**不可判定**——而且它的否定（无秩）才是 Σ₁¹（存在一根
ω-长树枝）。换言之：机器里「良基」是构造性的（找不找
得到路径），正文里「良基」是反构造的（**一切**实数都不
是树枝）——有限影子里 Σ 与 Π 的不对称完全消失（两条
都是枚举），这正是无穷描述集合论的全部张力所在。定理
3.2 的绝对性之所以要 T₀ 出面，正是因为 Π 侧（无树枝）
的「对一切 y」在模型之间不可比；而 Σ 侧（有树枝）的
见证一旦存在就随处存在。**不对称是绝对的、对称是构造
的**——这句话可以作为 112–113 章一切绝对性讨论的钥匙。

## 111.10 本章要点与检查问题

**要点**：

一句话总结本章：**把实数折叠成树，把「属于余解析集」翻译
成「树良基」，于是补集运算变成对偶、绝对性变成秩函数的
存在性、正则性变成范数的标尺刻度——描述集合论的整台
机器都挂在这棵树上。**

1. 精细分层：黑体（任意实参数）↔ 简体（递归 + 单参数 α）；
   Σ¹ₙ(α) 从 ∃实数 开头、Π¹ₙ(α) 是补；$\boldsymbol\Sigma^1_1 =\bigcup_\alpha\Sigma^1_1(\alpha)$ （111.1）。
2. 封闭性的量词工程三兵器：位串分流 u±、后继配对 h、选择
   交换 H（依赖 AC_ω）（111.1）。
3. 树表示：闭集 = [T]；解析 = π[T]（α ∈ A ⟺ T(α) 无秩）；
   **Π₁¹-规范形式**：A 余解析 ⟺ A = {α | T(α) 有秩}
   （引理 3.3/定理 3.1）（111.2）。
4. 绝对性（定理 3.2）：有树枝向下绝对、赋秩函数由理论提供
   ——Π₁¹(α) 性质对足够强的传递模型内外一致（111.2）。
5. 开区分特性第二证明：T′ 剪枝 + **双子延伸**断言造完美子树
   （111.3）。
6. WF/ZX 完全集：定义 3.3 的编码；引理 3.4（Π₁¹ + 下降链
   对偶）；引理 3.5（秩有界部分博雷尔——对 α 归纳）；定理
   3.3（完全性：连续归结）；推论 3.2（非 Σ₁¹）、3.3（有界性）、
   3.4/3.6（ℵ₁ 个博雷尔并）、3.5（势三歧）（111.4）。
7. 范数/准秩序/标尺：定义 3.4；定理 3.4（Π₁¹-准秩序性质——
   Q = 保序映射存在、P = 有秩且非严格小于）；最小树枝
   g_α = 降秩函数；定义 3.5 标尺（强制收敛）；定理 3.5；
   近藤展示函数定理 3.6 与命题 3.1（交替收缩 + 标尺收口）
   （111.5）。
8. 引理 3.7：Σ¹ₙ ⟺ (V_ω₁,∈) 上 Σₙ₋₁-可定义——拓扑层级与
   逻辑层级之桥（111.6）。
9. 机器五件：树枝判定、ρ 递归 + 秩 ≤ 深度、完美子树、截面
   投影、下降链对偶（111.8）。

**检查问题**：

（建议顺序：1–3 打牢树表示，4–6 走完全集与有界性，
7–9 走范数与标尺，10–12 对照机器边界自查。）

1. 定义 3.1(2) 说 Π¹₁(α) = Σ¹₁(α) 的补——用定理 3.1 说明
   这个「补」如何变成「有秩 ↔ 无秩」的对偶。为什么这个
   翻译对 Σ¹₂ 就不再直接可用？
2. 引理 3.1 证明中三个融合兵器各解决什么形状的量词前缀？
   选择交换那一步为什么需要 AC_ω 而其余两步不需要？
3. 定理 3.2 的证明里，「M 中有秩 ⟹ V 中有秩」用了 T₀ 的
   哪条定理？如果 T₀ 只保证「无树枝是 Π₁¹ 性质」而不管
   赋秩函数，绝对性会断在哪一边？
4. 断言二（双子延伸）中 K 的开性用在哪里？如果 K 只是
   F_σ，构造会在哪一步失效？
5. 引理 3.5 的归纳步把 WF_α 写成前驱条件之并——这个「并」
   的长度是多少？为什么它保持博雷尔性而 ∪_{α<ω₁}WF_α
   （= WF 本身）不是博雷尔？
6. 定理 3.3 的归结映射 f 为什么连续？（提示：T(α) 的成员
   资格依赖 α 的哪一段？）连续性在推论 3.2 的证明中扮演
   什么角色？
7. 有界性引理（推论 3.3）的反证中，表达式「‖α‖ ≤ ‖β‖」
   为什么是 Σ₁¹ 关系？由此填出 ZX 是 Σ₁¹ 的矛盾链。
8. 定理 3.4 的 Q 用「存在保序映射」，P 用「有秩且非严格
   小于」——练习中那个命题（f 存在 ⟺ T(β) 有树枝 或
   秩 ≤ 秩）的「或 T(β) 有树枝」一支为什么在 A 上消失？
9. 最小无穷树枝 g_α 为什么逐点 ≤ 一切其他树枝？它与秩函数
   ρ_{U(α)} 的关系说明「标尺」这个命名贴在哪里？
10. 命题 3.1 的交替收缩为什么必须「范数最小 + 坐标最小」
    双轨并进？只用范数最小收缩，极限点会出什么问题？
    （提示：强制收敛性的两个条件各管哪一轨？）
11. 机器件②的「秩 ≤ 剩余深度」对应引理 3.5 的哪一层结构？
    为什么说它是「秩有界部分博雷尔」的机制件而不是结论件？
12. Isabelle 的 `minimal_no_descending` 与正文引理 3.4 的
    方向关系是什么？Prolog 的 `loop_witness` 检测的直接环
    与「无穷下降链」的蕴含方向是哪边？

---

**延伸阅读**：Y. N. Moschovakis, *Descriptive Set Theory*,
North-Holland (1980)——范数与标尺理论的标准参考；近藤
(M. Kondo) 的展示函数定理原文 1938；M. Mansfield & G. Weitkamp,
*Recursive Aspects of Descriptive Set Theory*, Oxford (1985)
——简体层次的递归论读本。

- 上一章：[110 · NS 峭壁、饱和与投影光影原理](110-nssaturation.md)
- 下一章：[112 · Σ¹₂ 集合](112-sigma12.md)
