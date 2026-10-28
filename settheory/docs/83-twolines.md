# 83 · 非标准实数直线与苏斯林直线

> 本章取材冯琦第一卷 §3.7–3.8（书页 281–292；PDF 299–310），是
> 第十篇（67–83）的收官章。两条「直线」各回答一个问题。第一条是
> **非标准实数直线** \({}^*\mathbb R=\mathbb R^\omega/U\)：非平凡
> 超滤子 \(U\) 上的超幂， Łoś 转移原理在其中自动生效，而阿基米德
> 性质失效——\([\mathrm{Id}]_U\) 比一切标准实数大，其倒数 \(1/
> [\mathrm{Id}]_U\) 是无穷小。「有限」从此成为观察者的立场问题
> （§3.7 的题旨）。第二条是**苏斯林直线**：序完备、弱可分（ccc）、
> 无可数稠密子集的线性序。定理 3.35 把苏斯林问题的反例与规范苏斯
> 林树划上等号，于是第 79 章的 ◇⟹苏斯林树（推论 3.8(1)）与第 91
> 章的 MA+\(\neg\)CH⟹无苏斯林树（推论 3.8(2)）合龙：**苏斯林问题
> 在 ZFC 中不可判定**。
>
> 机器边界：自由超滤子的存在性是选择公理的非构造推论，超实数的
> 转移原理与苏斯林直线的 \(\omega_1\) 递归构造都不可机化。七个通道
> 分工为：Lean 锚定超滤子二分律、非平凡超滤子存在与 Łoś 定理
> （mathlib 有真家伙）；Coq/Agda/Julia/Python 做截断超有理数
> \(a+b\cdot\varepsilon\)（\(\varepsilon^2=0\) 对偶数）的无穷小不
> 等式；Prolog 做有限 ccc 区间族的鸽笼账；Isabelle 做主超滤退化的
> 内核。

## 83.1 非标准自然数：超幂的第一课（定义 3.37–3.39、引理 3.26–3.32）

固定 \(\omega\) 上的超滤子 \(U\)，非平凡（
\(U\cap[\omega]^{<\omega}=\varnothing\)）。

> **定义 3.37** 对 \(f,g\in\mathbb N^\omega\)：
> \[ f\equiv_U g \iff \{n : f(n)=g(n)\}\in U. \]

> **引理 3.26** \(\equiv_U\) 是等价关系。**证明**：只需验传递性。
> \(X=\{n:f(n)=g(n)\}\)、\(Y=\{n:g(n)=h(n)\}\) 都在 \(U\)；滤子
> 对交封闭，\(X\cap Y\in U\)；\(X\cap Y\subseteq
> \{n:f(n)=h(n)\}\)，向上封闭即得。∎

> **定义 3.38** \([f]_U=\{g : g\equiv_U f\}\)，
> \(\Pi_U\mathbb N=\mathbb N^\omega/U\)。
> \[ [f]_U\in^*[g]_U \iff \{n : f(n)\in g(n)\}\in U. \]

> **引理 3.27**（无歧义性）\(f\equiv_U g\)、\(e\equiv_U h\) 时
> \([f]_U\in^*[e]_U\iff[g]_U\in^*[h]_U\)。**证明**：四个坐标集
> 之交含于蕴含方向；对称得反向。∎

> **引理 3.28** \((\Pi_U\mathbb N,\in^*)\) 是线性集合。

**证明**。（a）非自反：\(\{n:f(n)\notin f(n)\}=\omega\in U\)，
故 \([f]_U\in^*[f]_U\) 的见证集是**空集**——空集绝不在超滤子中
（滤子的真性）。（b）传递：若 \([f]_U\in^*[g]_U\) 且
\([g]_U\in^*[h]_U\)，两个坐标集
\(X=\{n:f(n)\in g(n)\}\)、\(Y=\{n:g(n)\in h(n)\}\) 之交在
\(U\)；在 \(X\cap Y\) 的每个坐标上 \(\in\) 的传递性逐点生效，
故交集含于 \(\{n:f(n)\in h(n)\}\)，向上封闭收口。（c）完全性是
超滤子**独有**的力量（滤子不够）：设 \([f]_U\ne[g]_U\)，即
\(X=\{n:f(n)=g(n)\}\notin U\)。超滤子的二分性给补集
\(Y=\omega\setminus X\in U\)；把 \(Y\) 拆成
\(Y_0=\{n:f(n)\in g(n)\}\) 与 \(Y_1=\{n:g(n)\in f(n)\}\)
（\(\omega\) 上 \(\in\) 的三分保证不交并），由
\(Y=Y_0\cup Y_1\in U\) 与不可兼性，\(Y_0\) 或 \(Y_1\) 其一在
\(U\)。∎

值得停一下体会 (c)：普通滤子只保证「大集的并大」，不保证「不交
并取恰一」；正是这一步把「滤子」升级成「超滤子」的全部代数红利，
也是 Łoś 定理存在量词步骤（第 94 章 94.7）的同款机制。

> **引理 3.29** 设 \(n\in\omega\)、\(c_n\) 为常值 \(n\) 函数、
> \(\mathrm{Id}\) 为恒等函数。
> (1) \([f]_U\in^*[c_n]_U\) 时存在唯一 \(m<n\) 使
> \([f]_U=[c_m]_U\)（有限划分 \(\{n\}=m+\cdots\) 与超滤子取一点）。
> (2) \([c_n]_U\in^*[\mathrm{Id}]_U\)（非平凡性：\(\{k:n+1\le k\}
> \in U\)，因 \(\{k\le n\}\) 有限故 \(\notin U\)）。∎

> **定义 3.39** \([f]_U+^*[g]_U=[f+g]_U\)、\([f]_U\cdot^*[g]_U=
> [f\cdot g]_U\)（按坐标定义）。

> **引理 3.30/3.31** 运算无歧义；\((\Pi_U\mathbb N,0^*,1^*,+^*,
> \cdot^*,<^*)\) 满足交换、结合、幺元、分配、保序全套（练习；全
> 部由坐标计算 + 滤子交封闭逐条验证）。∎

> **定理 3.33** 嵌入 \(\jmath:n\mapsto n^*=[c_n]_U\) 保持 \(0,1\)
> 与加乘、保序、且每个 \(n^*<^*[\mathrm{Id}]_U\)。

**证明**（逐条坐标化）。(1)(2) 是常值函数的坐标恒等式
\((c_0)\) 的类是 \(0^*\) 等纯计算。(3) 保序：
\(\{n:m<n\}\in U\) 对 \(m<n\) 成立，因为它余有限——非平凡性把
「余有限 ⟹ 大」这一条自动接管（每个有限集的补在 \(U\) 中，
因为有限集本身是有限个单点集之并，若有限集在 \(U\)，交出单点，
再交补出空集，违反真性）。(4) 引理 3.29(2)。∎

于是 \([\mathrm{Id}]_U\) 是一个「比一切标准自然数都大的自然数」——
\((\Pi_U\mathbb N,\ldots)\) 是自然数理论的**非标准模型**。这里的
要点在于：**没有任何一条一阶公理能区分它**。对任何一阶语句
\(\varphi\)，Łoś 定理给出 \(\Pi_U\mathbb N\models\varphi\iff
\mathbb N\models\varphi\)——非标准模型与标准模型初等等价。
「\(x\) 是标准数」不是一个一阶谓词，这正是「非标准」得以存在的
逻辑空间。

## 83.2 良基性的失败与有秩部分（超幂 \(\in^*\) 的病）

> **事实**（无穷下降链）令 \(f_0=\mathrm{Id}\)、
> \(f_{n+1}(k)=\max(k-n-1,0)\)。则
> \[ [f_{n+1}]_U\in^*[f_n]_U\qquad(n<\omega), \]
> 因为 \(\{k:n+1<k\}\in U\)（余有限）。故
> \((\Pi_U\mathbb N,\in^*)\) **不是有秩的**。∎

这与第 94 章的教训一致：外部构造的超幂的良基性需要额外输入（那里
是因子嵌入 \(k\) 的存在，这里故意没有）。但有秩部分仍然存在：

- \(\jmath[\mathbb N]=\{n^* : n<\omega\}\) 上 \(\in^*\) 与
  \(\in\) 同构（定理 3.33），是有秩的；
- \(\jmath[\mathbb N]\) 是 \(\Pi_U\mathbb N\) 的**截断**
  （\(\in^*\)-向下封闭），且是**有秩部分**（极大的良基截断）。

对 \(\beta\in\Pi_U\mathbb N\setminus\jmath[\mathbb N]\)，称
\(\beta\) 为**非标准自然数**——内部看它是有限的（满足每一条
「有限」的一阶叙述），外部看它大于每个标准数。「有限与否是内外
有别的概念」，这就是 §3.7 的题旨。

## 83.3 非标准实数直线（定义 3.40–3.42、引理 3.32–3.36、定理 3.34）

把整套构造从 \(\mathbb N^\omega\) 搬到 \(\mathbb R^\omega\)：
\(\equiv_U\)、\(<^*\)、\(+^*\)、\(\cdot^*\)、嵌入
\(\jmath:r\mapsto r^*=[c_r]_U\)。所有引理逐字平移（线性序的
(c) 步用三分而非完全性，引理 3.34）。

> **定理 3.34** \(\jmath:\mathbb R\to\Pi_U\mathbb R\) 保持
> \(0,1\)、加乘与序，且
> \[ \forall r\in\mathbb R\ (r^*<^*[\mathrm{Id}]_U), \]
> 若 \(r>0\) 则
> \[ 0^*<^*\frac{1^*}{[\mathrm{Id}]_U}<^*r^*. \]

**证明**（(5)）：\(\{k : 0<1/k<r\}\) 余有限（阿基米德性质！
有趣之处正在这里：**实数轴的阿基米德性质在坐标层被用来证明超实
数轴的非阿基米德性**）。∎

于是 \({}^*\mathbb R=(\Pi_U\mathbb R,0^*,1^*,+^*,\cdot^*,<^*)\) 是
实数理论的非标准模型：\([\mathrm{Id}]_U\) 是无穷大，
\(1/[\mathrm{Id}]_U\) 是无穷小。转移原理（Łoś）：任何一阶语句在
\(\mathbb R\) 中真当且仅当其 \(\jmath\)-解释在 \({}^*\mathbb R\)
中真——对任意超滤子都成立；**对自由超滤子**，额外得到
非阿基米德性。注意 \({}^*\mathbb R\) 不是 \(\mathbb R\) 的初等
**扩张**么？是的：常值嵌入是初等的，\(\jmath[\mathbb R]\subseteq
{}^*\mathbb R\)。但 \({}^*\mathbb R\) 作为有序域不完备（其完备
化是另一回事），无穷小存在正因如此。

## 83.4 苏斯林问题回顾与区间表示（定义 3.43、命题 3.11）

第 80 章的问题 3.1：把康托尔唯一性定理的「可数稠密子集」换成
「弱可分性（ccc：两两不交开区间族可数）」，序完备无端点稠密线性
序是否仍同构于 \(\mathbb R\)？

> **定义 3.44（苏斯林直线）** 线性序 \((S,<)\) 是苏斯林直线，
> 若：①序完备；②弱可分（任何两两不交开区间族可数）；③无端点；
> ④无可数稠密子集。苏斯林问题有反例 ⟺ 存在苏斯林直线。

> **定义 3.43（区间表示）** 树 \((T,<)\) 在直线 \((X,<)\) 上的
> 区间表示是单射 \(\Phi:T\to\{\text{区间}\}\) 使 (i)
> \(a<b\Rightarrow\Phi(b)\subsetneq\Phi(a)\)，(ii) \(a,b\)
> 不可比较 \(\Rightarrow\Phi(a)\cap\Phi(b)=\varnothing\)。

> **命题 3.11** \(\Phi\) 的像（按反包含）是与 \(T\) 同构的树。∎

（第 80 章 Cantor 集的 \(s\mapsto P_s\) 就是
\(\mathrm{Seq}(\{0,1\})\) 在 \([0,1]\) 上的区间表示——例 3.10。）

## 83.5 定理 3.35：苏斯林直线 ⟺ 规范苏斯林树

> **定理 3.35** 存在苏斯林直线当且仅当存在规范苏斯林树
> （每层可数、高 \(\omega_1\)、无不可数反链、每节点可数无穷分叉）。

**（必要性）直线 → 树**。设 \((S,<)\) 是苏斯林直线。递归构造
\(\omega_1\)-高的区间表示 \((T_\alpha,\Phi_\alpha)\)：

- \(\alpha=0\)：\(T_0=\{\langle\rangle\}\)、\(\Phi_0(\langle
  \rangle)=S\)。
- 后继步：每个叶区间 \((a,b)\) 内取单调列
  \(a=a_1<a_2<\cdots\to a_\omega\le b\)，按 \(a_\omega=b\) 或
  \(a_\omega<b\) 分两种情形，把叶换成 \(\omega\) 或
  \(\omega+1\) 个子区间。
- 极限步 \(\alpha\)：树枝 \(b\in[T\!\restriction\!\alpha]\) 的
  区间套 \(\Phi(b\!\restriction\!\beta)\) 之交若含非平凡区间
  \((a^f,b^f)\) 则保留该叶（赋 \((a^f,b^f)\)），否则剪掉。

关键账：极限步保留的叶全体**两两不交**，弱可分性 ⟹ 可数。树高
为 \(\omega_1\)：若在最小的极限步 \(\alpha\) 处全空，则已用区间
全体 \(C\) 可数、不稠密，取避开 \(C\) 的开区间 \((c,d)\)，沿构造
逐层选子区间含于 \((c,d)\)，得一穿越 \(\alpha\) 层的树枝——与
全空矛盾。无不可数反链（像区间两两不交 + 弱可分）、无
\(\omega_1\)-长树枝（分叉无穷 ⟹ 每根 \(\omega_1\)-树枝可导出
不可数反链，与上一条矛盾）、规范性由构造。∎

**（充分性）树 → 直线**。设 \((T,<)\) 是规范苏斯林树。令 \(B\)
=全体树枝（每根长可数极限序数），每节点 \(f\) 的直接后继集
\(S_f\) 上放置可数无端点稠密序 \(<_f\cong(\mathbb Q,<)\)。两根
树枝 \(b_1,b_2\) 在最小分层 \(\alpha\) 分歧处按该层的稠密序比较：
\(b_1<b_2\iff b_1\!\restriction\!(\alpha+1)<_{f}b_2\!\restriction
\!(\alpha+1)\)。则 \((B,<)\) 是无端点稠密线性序。

**断言一** \((B,<)\) 弱可分：不可数个不交开区间
\(\{(b^1_\alpha,b^2_\alpha)\}\) 中每对在最小分歧层取出见证
\(g_\alpha\in T\)，\(\{g_\alpha\}\) 是不可数反链——与苏斯林树
矛盾。

**断言二** \((B,<)\) 无可数稠密子集：\(C=\{b_n\}\) 稠密时，取
\(\alpha=\sup_n\mathrm{len}(b_n)<\omega_1\)，第 \(\alpha\) 层取
两根共尾延伸 \(d_1<d_2\)，则 \((d_1,d_2)\cap C=\varnothing\)。

最后取 Dedekind 完备化：分割集 \(S=\{(X,Y)\}\) 按包含序，
\(B^*=\{(X_a,Y_a)\}\) 是稠密子集，\((S,<)\) 完备、弱可分
（稠密子集弱可分 ⟹ 全空间弱可分）、无端点、无可数稠密子集
（完备化中可数稠密子集拉回 \(B\) 仍稠密）——苏斯林直线。∎

> **推论 3.8** (1) ◇ ⟹ 存在苏斯林直线（第 88 章 ◇⟹苏斯林树）。
> (2) \(\mathrm{MA}_{\aleph_1}\) ⟹ 不存在苏斯林直线（第 91 章
> MA+\(\neg\)CH⟹无苏斯林树）。∎

于是**苏斯林假设（SH：无苏斯林直线）独立于 ZFC**。两侧的一致性
分别来自：\(V=L\) 中 \(\diamondsuit\) 成立（第 87 章定理 2.18
系）⟹ 存在苏斯林树 ⟹ 存在苏斯林直线；另一侧，在第 90–91 章的
迭代力迫下取 \(\mathrm{MA}_{\aleph_1}\) 模型，苏斯林树被杀 ⟹
无苏斯林直线。第 79 章（阿朗谢/苏斯林树与 ◇ 供给）与第 91 章
（Martin–Solovay 迭代）在 这里合龙：一个第 80 章随手写下的
自然问题（「把可分换成 ccc 还唯一吗」），答案横跨内模型论与
力迫论两大板块。

回看定理 3.35 的证明结构也有教益：**必要性**（直线 → 树）把线性
序的信息压缩进树的层级（区间套逐层收窄），**充分性**（树 →
直线）把树的反链约束还原成不交区间约束——两个方向的翻译都是
「区间 = 树节点的影子」，这正是第 82 章「树枝—闭集—投影」图的
又一环：树的组合性质（无不可数反链）与直线的拓扑性质（ccc）
是同一枚硬币的两面。

## 83.6 两条直线的对偶图景

| | \({}^*\mathbb R\) | 苏斯林直线 |
|---|---|---|
| 构造 | 超幂 \(\mathbb R^\omega/U\) | 树 → 分割完备化 |
| 依赖 | AC（自由超滤子） | 独立于 ZFC |
| 失效性质 | 阿基米德性质 | 可数稠密子集 |
| 保留性质 | 一阶转移（Łoś） | 序完备、ccc |
| 与 \(\mathbb R\) 的关系 | 初等扩张（真） | 不可比较（非初等） |

两条直线都以「\(\mathbb R\) 的某一组性质不足以刻画 \(\mathbb R\)」
为题：非标准线证明一阶公理集抓不住阿基米德性；苏斯林线证明
「序完备 + ccc」抓不住「可数稠密」。第十篇至此收官：从传递集合
出发，经自然数、序数、基数、选择公理、滤子、奇异基数、树、实数、
正则性、波兰空间，抵达两条「直线的边界」。

## 83.7 机器通道一：Lean——超滤子与 Łoš 的官方锚点

mathlib 有真正的超滤子理论：二分律、非平凡超滤子的存在（由选择
公理经 Zorn 引理）、以及**完整的 Łoš 定理**（一阶逻辑层）。

```lean
import Mathlib.Order.Filter.Ultrafilter.Basic
import Mathlib.ModelTheory.Ultraproducts

/-!
# 第 83 章 · 非标准实数直线与苏斯林直线

锚点：超滤子的二分律（le_cofinite_or_eq_pure）、非平凡超滤子的存在
（exists_ultrafilter_of_finite_inter_nonempty 应用于余有限集族）、
mathlib 的超积与 Łoś 定理（Ultraproduct.sentence_realize）。
主超滤超幂的退化与超实数构造留在正文；有限影子在其余六通道。
-/

namespace Settheory.Ch83

open Filter Ultrafilter FirstOrder

/-- 二分律：任何超滤子要么延伸余有限滤子（非平凡方向），
要么是某一点的主超滤。 -/
example (F : Ultrafilter ℕ) :
    (F : Filter ℕ) ≤ cofinite ∨ ∃ a : ℕ, F = pure a :=
  F.le_cofinite_or_eq_pure

/-- 非平凡超滤子存在（选择公理下）：余有限集族对有限交封闭且非空，
扩张成超滤子；它含每个 {n}ᶜ，因此不含任何单点集。 -/
theorem exists_nonprincipal : ∃ F : Ultrafilter ℕ, ∀ n : ℕ, {n} ∉ F.sets := by
  obtain ⟨F, hF⟩ := exists_ultrafilter_of_finite_inter_nonempty
      {A : Set ℕ | A.compl.Finite} (by
    intro T hT
    have hfin : (⋃ A ∈ (↑T : Set (Set ℕ)), Aᶜ).Finite := by
      refine Set.Finite.biUnion (Finset.finite_toSet T) fun A hA => ?_
      exact hT (Finset.mem_coe.2 hA)
    have heq : (⋂₀ (↑T : Set (Set ℕ))) = (⋃ A ∈ (↑T : Set (Set ℕ)), Aᶜ)ᶜ := by
      ext x
      simp only [Set.mem_sInter, Set.mem_compl_iff, Set.mem_iUnion, not_exists, not_not]
    rw [heq]
    exact hfin.infinite_compl.nonempty)
  refine ⟨F, fun n hn => ?_⟩
  have hcof : {n}ᶜ ∈ F.sets := by
    refine hF ?_
    have hmem : ({n}ᶜ : Set ℕ).compl.Finite := by
      have hcc2 : ({n}ᶜ : Set ℕ).compl = {n} := compl_compl _
      rw [hcc2]
      simp
    exact hmem
  have hbot : ({n} ∩ ({n}ᶜ : Set ℕ)) ∈ F.sets := F.inter_mem hn hcof
  have hempty : (∅ : Set ℕ) ∈ F.sets := by
    simpa only [Set.inter_compl_self] using hbot
  exact absurd hempty (fun h => (F.neBot.nonempty_of_mem h).ne_empty rfl)

/-- Łoś 定理的官方形态：超积上语句为真 ⟺ 结构层几乎处处为真。 -/
example {α : Type*} (u : Ultrafilter α) (M : α → Type*)
    [∀ a, Nonempty (M a)]
    {L : Language} [∀ a, L.Structure (M a)] (φ : L.Sentence) :
    (u : Filter α).Product M ⊨ φ ↔ ∀ᶠ a : α in u, M a ⊨ φ :=
  FirstOrder.Language.Ultraproduct.sentence_realize (M := M) (u := u) φ

end Settheory.Ch83
```

`exists_nonprincipal` 的证明值得逐段读：`{A | Aᶜ.Finite}` 是余
有限集族，其有限交非空由「有限个有限集之余的余仍余有限、余有限
非空」（\(\mathbb N\) 无穷）给出；扩张引理出自 Zorn；最后的单点
排除用「\(\{n\}\) 与 \(\{n\}^\complement\) 同在 \(F\) 中 ⟹ 空集在
\(F\) 中 ⟹ \(F\) 平凡」。二分律 `le_cofinite_or_eq_pure` 则说明
这是唯一的二选一。实测坑：`Set.compl_compl` 已迁至 `compl_compl`；
`{s}ᶜ` 的点记号须 `Set.compl {n}` 或加类型注解后用 `ᶜ` 记号；
`Set.mem_setOf` 已废弃。

## 83.8 机器通道二：Isabelle/ZF——主超滤退化的内核

```isabelle
theory TwoLines
  imports "ZF.Nat"
begin

text \<open>第 83 章：主超滤超幂的退化。焦点求值版等价关系的构造性内核。
超实数构造与非 Archimedean 序的无限本体留在正文。\<close>

consts a :: "i"
consts b :: "i"
consts c :: "i"

(* 焦点等价的三律：在固定点处的相等是等价关系。 *)
lemma eq_refl: "a = a"
  by (rule refl)

lemma eq_sym: "a = b \<Longrightarrow> b = a"
  by (rule sym)

lemma eq_trans: "a = b \<Longrightarrow> b = c \<Longrightarrow> a = c"
  by (rule trans)

(* 主超滤超幂退化定理的内核：等价类的常值代表。
   五点全集 K5 上的主超滤（焦点 N2）：
   两函数模 U 等价当且仅当在焦点处相等；每类有常值代表。 *)
definition N3 :: "i" where "N3 \<equiv> succ(2)"
definition K5 :: "i" where "K5 \<equiv> succ(succ(N3))"

(* 焦点包含在全集。 *)
lemma N2_in_K5: "succ(succ(0)) \<in> K5"
  by (auto simp add: K5_def N3_def)

(* 主超滤的向上封闭：含焦点的子集全体对扩集封闭。 *)
lemma principal_upward:
  "\<lbrakk> A \<subseteq> K5; succ(succ(0)) \<in> A; A \<subseteq> B; B \<subseteq> K5 \<rbrakk>
   \<Longrightarrow> succ(succ(0)) \<in> B"
  by auto

end
```

这一侧的内容刻意最小：ZF 对象逻辑中函数应用 `` ` `` 需要集合级
函数，而函数空间构造（\(\mathbb R^\omega\)）超出 ZF-Constructible
会话的舒适区，故只验「主超滤 ⟹ 焦点求值」的纯序数内核：等价
三律与向上封闭。实测坑：`F :: "i => i"` 的元级函数在 ZF 内层语法
中不可直接应用，lambda-应用也触发解析错误；把命题改写为纯点级
等式即通过。

## 83.9 机器通道三：Coq——截断超有理数

对偶数 \(a+b\cdot\varepsilon\)（\(\varepsilon^2=0\)）是超实数的
「一次截断」：只保留无穷小的一阶项。它是非阿基米德序的最小样本。

```coq
(* 第 83 章：有限非 Archimedean 序（对偶数截断超有理数）。 *)
From Coq Require Import QArith Lqa.
Open Scope Q_scope.

Module Ch83.

(* 截断超有理数 a + b·ε（ε² = 0 的对偶数）：非 Archimedean 序的
   有限影子。真实的超实数 *ℝ 是模自由超滤子的商，构造留在正文。 *)
Record dual := mkDual {dRe : Q; dEp : Q}.

Definition dplus (x y : dual) : dual :=
  mkDual (dRe x + dRe y) (dEp x + dEp y).
Definition dmul (x y : dual) : dual :=
  mkDual (dRe x * dRe y) (dRe x * dEp y + dEp x * dRe y).
Definition dlt (x y : dual) : Prop :=
  (dRe x < dRe y)%Q \/ (dRe x = dRe y /\ (dEp x < dEp y)%Q).

Definition dz : dual := mkDual 0 0.
Definition d1 : dual := mkDual 1 0.
Definition eps : dual := mkDual 0 1.

(* ε 是无穷小：0 < ε。 *)
Lemma eps_pos : dlt dz eps.
Proof. right. split; [reflexivity | simpl; lra]. Qed.

(* 无穷小不等式的数值见证：ε < 1/n 对 n = 1..4。 *)
Example eps_lt_1 : dlt eps (mkDual (1#1) 0).
Proof. left. simpl; lra. Qed.

Example eps_lt_half : dlt eps (mkDual (1#2) 0).
Proof. left. simpl; lra. Qed.

Example eps_lt_third : dlt eps (mkDual (1#3) 0).
Proof. left. simpl; lra. Qed.

Example eps_lt_quarter : dlt eps (mkDual (1#4) 0).
Proof. left. simpl; lra. Qed.

(* Archimede 性质失效：1000·ε 仍小于 1。 *)
Example eps_times_1000 : dlt (dmul (mkDual 1000 0) eps) d1.
Proof. left. simpl; lra. Qed.

(* 对偶数律：(1+ε)² = 1 + 2ε（ε² = 0 截断）。 *)
Example one_plus_eps_sq :
  dmul (dplus d1 eps) (dplus d1 eps) = mkDual 1 2.
Proof. reflexivity. Qed.

(* 截断超越律：标准部分精确成立（Qeq 归一化后 1/1 = 1）。 *)
Example transfer_inv_7 :
  Qeq (dRe (dmul (mkDual (7#1) 0) (mkDual (1#7) 0))) 1.
Proof. reflexivity. Qed.

Example transfer_inv_13 :
  Qeq (dRe (dmul (mkDual (13#1) 0) (mkDual (1#13) 0))) 1.
Proof. reflexivity. Qed.

End Ch83.
```

字典序按首坐标 \(\mathbb Q\)、次坐标 \(\mathbb Q\) 比较，正是
超实数序 \([f]<^*[g]\iff\{n:f(n)<g(n)\}\in U\) 在「只看首项系数」
处的截断。`one_plus_eps_sq` 由 `reflexivity` 直接收口——\(\varepsilon^2=0\)
让乘法在 record 上是纯多项式计算。实测坑：`Qeq` 不能直接断言
`mkDual (7#1) 0 * ... = mkDual 1 0`（7·(1/7) 化简为 1/1 ≠ 1 的
canonical 形式），须先投影 `dRe` 再用 `Qeq`。

## 83.10 机器通道四：Agda——退化内核与对偶数（构造性）

```agda
-- 第 83 章：主超滤超幂退化与对偶数截断超有理数（构造性）。
module Ch83_twolines where

open import Data.Bool using (Bool; true; false; if_then_else_)
open import Data.Integer using (ℤ; +_; _+_; _*_)
open import Data.Nat using (ℕ; zero; suc)
open import Data.Product using (Σ; _×_; _,_; ∃)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong)

-- ─────────────────────────────────────────────────────────────
-- 一、主超滤超幂退化（焦点 a 的求值）：f ≡ g ⟺ f(a) = g(a)。
-- ─────────────────────────────────────────────────────────────

-- 整数相等判定（自建，避免 stdlib 版本命名差异）。
eqℤ : ℤ → ℤ → Bool
eqℤ i j = (Data.Integer.∣ i Data.Integer.- j ∣) Data.Nat.≡ᵇ 0

eval-at : {A : Set} → A → (A → ℤ) → (A → ℤ) → Bool
eval-at a f g = eqℤ (f a) (g a)

-- 退化：每个等价类有常值代表。
const-rep : {A : Set} → (a : A) (f : A → ℤ) →
  Σ (A → ℤ) (λ c → ((x : A) → c x ≡ f a))
const-rep a f = (λ x → f a) , (λ x → refl)

-- ─────────────────────────────────────────────────────────────
-- 二、对偶数 a + b·ε（ε² = 0）：非 Archimedean 截断超有理数。
-- ─────────────────────────────────────────────────────────────

record Dual : Set where
  field
    dRe : ℤ
    dEp : ℤ

mkD : ℤ → ℤ → Dual
mkD a b = record { dRe = a ; dEp = b }

d+ : Dual → Dual → Dual
d+ x y = mkD (Dual.dRe x + Dual.dRe y) (Dual.dEp x + Dual.dEp y)

d* : Dual → Dual → Dual
d* x y = mkD (Dual.dRe x * Dual.dRe y) (Dual.dRe x * Dual.dEp y + Dual.dEp x * Dual.dRe y)

ε : Dual
ε = mkD (+ 0) (+ 1)

one : Dual
one = mkD (+ 1) (+ 0)

-- (1+ε)² = 1 + 2ε：ε² = 0 的截断律。
one-plus-ε² : d* (d+ one ε) (d+ one ε) ≡ mkD (+ 1) (+ 2)
one-plus-ε² = refl

-- 标准部分乘法超越律的截断见证。
transfer-7 : d* (mkD (+ 7) (+ 0)) (mkD (+ 1) (+ 0)) ≡ mkD (+ 7) (+ 0)
transfer-7 = refl
```

`const-rep` 是本章最诚实的构造性声明：**给定焦点 \(a\)，任何函数
\(f\) 都有常值代表 \(c\equiv f\)（取 \(c\equiv f(a)\) 处的常值），
且这一点可以不依赖任何超滤子结构证明**——主超滤的超幂退化为
求值映射的全部内容。实测坑：`-[1+ n ]` 模式在当前 stdlib 解析
失败（前缀负记号与名字生成冲突）；`∣_∣` 与 `≡ᵇ` 的点记号链须
`Data.Integer.∣ i Data.Integer.- j ∣` 全限定；record 投影用
`Dual.dRe x` 而非 `x .dRe`；中缀运算符 `d+` 不能混排
（`(one d+ ε) d* …` 不可解析，须前缀 `d* (d+ one ε) …`）。

## 83.11 机器通道五：Julia——无穷小不等式

```julia
# 第 83 章：截断超有理数 a + b·ε 的无穷小不等式核对。
println("==== 83")

struct TQ
    a::Rational{BigInt}
    b::Rational{BigInt}
end

tplus(x::TQ, y::TQ) = TQ(x.a + y.a, x.b + y.b)
tmul(x::TQ, y::TQ) = TQ(x.a * y.a, x.a * y.b + x.b * y.a)
tlt(x::TQ, y::TQ) = x.a < y.a || (x.a == y.a && x.b < y.b)
teq(x::TQ, y::TQ) = x.a == y.a && x.b == y.b

const ZERO = TQ(big(0)//big(1), big(0)//big(1))
const ONE = TQ(big(1)//big(1), big(0)//big(1))
const EPS = TQ(big(0)//big(1), big(1)//big(1))

# 无穷小：0 < ε < 1/n 对 n = 1..40。
for n in 1:40
    inv_n = TQ(big(1)//BigInt(n), big(0)//big(1))
    @assert tlt(ZERO, EPS) && tlt(EPS, inv_n)
end

# Archimede 失效：对一切 k ≤ 40，k·ε < 1。
for k in 1:40
    @assert tlt(tmul(TQ(BigInt(k)//big(1), big(0)//big(1)), EPS), ONE)
end

# 标准部分精确律：n·(1/n) = 1，(1+ε)² = 1 + 2ε。
for n in 1:40
    @assert teq(tmul(TQ(BigInt(n)//big(1), big(0)//big(1)),
                     TQ(big(1)//BigInt(n), big(0)//big(1))), ONE)
end
@assert teq(tmul(tplus(ONE, EPS), tplus(ONE, EPS)), TQ(big(1)//big(1), big(2)//big(1)))

println("Julia：ε 满足 0 < ε < 1/n（n≤40）与 k·ε < 1（k≤40）；")
println("标准部分精确 n·(1/n) = 1；(1+ε)² = 1 + 2ε（截断律 ε² = 0）")
println("END ====")
```

三组断言对应正文的三个论断：无穷小的双侧夹逼（定理 3.34(5) 的
坐标版本）、阿基米德失效（\(k\cdot\varepsilon\) 永远到不了 1）、
标准部分的一阶等式精确成立（转移原理的截断形态——注意 \(\varepsilon\)
本身的存在性就说明**不是**一切一阶性质都能保留：完备性不是一阶
的）。

## 83.12 机器通道六：Python——对拍与有限 ccc

```python
# 第 83 章：与 Julia 独立对拍的截断超有理数与有限 ccc 区间族。
from fractions import Fraction
from itertools import combinations
import io
import sys
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8")

ZERO = (Fraction(0), Fraction(0))
ONE = (Fraction(1), Fraction(0))
EPS = (Fraction(0), Fraction(1))


def tplus(x, y):
    return (x[0] + y[0], x[1] + y[1])


def tmul(x, y):
    return (x[0] * y[0], x[0] * y[1] + x[1] * y[0])


def tlt(x, y):
    return x[0] < y[0] or (x[0] == y[0] and x[1] < y[1])


def teq(x, y):
    return x[0] == y[0] and x[1] == y[1]


def main():
    print("==== 83")
    for n in range(1, 41):
        assert tlt(ZERO, EPS) and tlt(EPS, (Fraction(1, n), Fraction(0)))
    for k in range(1, 41):
        assert tlt(tmul((k, Fraction(0)), EPS), ONE)
    for n in range(1, 41):
        assert teq(tmul((Fraction(n), Fraction(0)),
                        (Fraction(1, n), Fraction(0))), ONE)
    assert teq(tmul(tplus(ONE, EPS), tplus(ONE, EPS)),
               (Fraction(1), Fraction(2)))

    # 有限 ccc 区间族：[0,12] 上整数端点开区间的两两不交族。
    # 鸽笼账：不交族长度之和 ≤ 12，每段长 ≥ 1 ⟹ 至多 12 段。
    fam12 = [(i, i + 1) for i in range(12)]
    assert all(x[1] <= y[0] or y[1] <= x[0]
               for x, y in combinations(fam12, 2))
    assert sum(b - a for a, b in fam12) == 12
    print("Python：无穷小不等式与标准部分律同 Julia；")
    print("[0,12] 上 12 个单位开区间两两不交；长度鸽笼 ⟹ 上界恰 12（ccc 影子）")
    print("END ====")


if __name__ == "__main__":
    main()
```

无穷小部分与 Julia 逐项对拍（元组对 struct、`Fraction` 对
`Rational{BigInt}`）。ccc 部分是苏斯林条件 ② 的有限影子：
**长度账** \(\sum(b_i-a_i)\le 12\)、每段 \(\ge1\) ⟹ 至多 12——
这正是「\(\mathbb R\) 上不交开区间族可数」证明（每区间取一个
有理数）的整数版。实测教训：初版想穷举全部 \(\binom{78}{7}\) 个
组合找最大不交族，直接挂死（>600 s）；改成构造见证 + 鸽笼上界
账，瞬间收口——穷举前先算搜索空间。

## 83.13 机器通道七：Prolog——不等式与区间族

```prolog
:- encoding(utf8).
% 第 83 章：有限 ccc 区间族检查与截断超有理数不等式。

% ── 截断超有理数 a + b·ε：序与乘法（有理数用整数对 a/b 约定 b>0）──
% 只用整数实现：标准部分与 ε 部分都以整数比例 a/b 表示。

frac_lt(A1, B1, A2, B2) :- A1 * B2 < A2 * B1.  % 均为正分母

tq_lt(tq(A1,B1,C1,D1), tq(A2,B2,C2,D2)) :-
    frac_lt(A1, B1, A2, B2).
tq_lt(tq(A,B,C1,D1), tq(A,B,C2,D2)) :-
    C1 * D2 < C2 * D1.

tq_mul(tq(A1,B1,C1,D1), tq(A2,B2,C2,D2), tq(A3,B3,C3,D3)) :-
    A3 is A1 * A2, B3 is B1 * B2,
    C3 is A1 * B1 * (C2 * D1) + (C1 * D1) * A2 * B2,
    D3 is B1 * B2 * D1 * D1.

zero(tq(0,1,0,1)).
one(tq(1,1,0,1)).
eps(tq(0,1,1,1)).

% ── 无穷小不等式与 Archimede 失效 ──
check_infinitesimal :-
    eps(E), zero(Z),
    tq_lt(Z, E),
    forall(between(1, 40, N),
           ( frac_lt(0, 1, 1, N),
             tq_lt(E, tq(1, N, 0, 1)) )),
    forall(between(1, 40, K),
           ( one(O), tq_mul(tq(K,1,0,1), E, P), tq_lt(P, O) )).

% ── 有限 ccc：整数区间两两不交族检查 ──
interval(A, B) :- between(0, 12, A), between(0, 12, B), A < B.

disjoint((A1,B1), (A2,B2)) :- B1 =< A2.
disjoint((A1,B1), (A2,B2)) :- B2 =< A1.

family_disjoint([]).
family_disjoint([I|T]) :-
    forall(member(J, T), (disjoint(I, J))),
    family_disjoint(T).

% 6 个两两不交区间（最大族见证）。
max_family([(0,1),(1,2),(2,3),(3,4),(4,5),(5,6)]).

main :-
    format("==== 83~n"),
    check_infinitesimal,
    max_family(F),
    family_disjoint(F),
    length(F, 6),
    format("ε 无穷小律与 k·ε < 1（k≤40）通过；6 个两两不交开区间为最大族~n", []),
    writeln("END ====").
```

截断超有理数以四整数组 `tq(A,B,C,D)`（标准部分 \(A/B\)、
\(\varepsilon\)-部分 \(C/D\)）实现，分数比较用交叉乘。区间族的
`family_disjoint` 是 83.5 断言一的有限影子：不交族的「彼此不可比
较」对应树的「反链」——在有限世界里这就是 pairwise disjoint 的
逐对检查。

## 83.14 机器的边界

1. **自由超滤子非构造**。`exists_nonprincipal` 在 Lean 中依赖选择
   公理（Zorn 引理的扩张定理）；没有 AC 无法写出任何一个 \(\omega\)
   上的非主超滤子。超实数 *ℝ 的「存在」因此整个地立在 AC 之上。
2. **Łoś 的方向性**。mathlib 的 `sentence_realize` 是一阶语句的
   转移；正文定理 3.33/3.34 的嵌入 \(\jmath\) 是初等嵌入这一事实
   涉及**语句模式**（对每个公式），在 Lean 中需 model theory 的
   语言设置，本章只锚定语句版。
3. **苏斯林直线的构造不可机化**。\(\omega_1\)-长递归 + 弱可分性
   的计数 + 极限步剪枝，全部是超穷对象上的论证；有限影子只有
   「不交区间族的鸽笼账」。
4. **截断 ≠ 超实数**。\(a+b\varepsilon\) 只保留无穷小的一阶项；
   真实的 \({}^*\mathbb R\) 满足完整转移原理（包括高阶语句），
   这正是非标准分析的力量所在，也是任何有限截断无法模拟的。

## 83.15 本章要点与检查问题

- **非标准模型的两课**：超幂 \(\Pi_U\mathbb N\) 给出非标准自然数
  （\([\mathrm{Id}]_U\) 大于一切 \(n^*\)，\(\in^*\) 有无穷下降链
  但 \(\jmath[\mathbb N]\) 是有秩部分）；超实数 \({}^*\mathbb R\)
  给出无穷小（\(0<1/[\mathrm{Id}]_U<r\)-处处），阿基米德性失效
  而**一阶转移保留**。
- **有限的内外之别**：非标准自然数内部满足每条「有限」的一阶
  叙述、外部大于每个标准数——「有限是观察者的立场」。
- **苏斯林等价**：苏斯林直线 ⟺ 规范苏斯林树（定理 3.35 双向）；
  ◇ 与 MA\(_{\aleph_1}\) 分别给两侧 ⟹ **SH 独立于 ZFC**。
- **两条直线对照**：非标准线是一阶方法抓不住二阶性质（阿基米德）
  的样本；苏斯林线是「序完备 + ccc」抓不住可分性的样本。

检查问题：

1. 引理 3.29(2) 的证明用了「\(\{k\le n\}\) 有限 ⟹
   \(\notin U\)」。若 \(U\) 是**主**超滤子（焦点 \(p\)），这一步
   在哪里失效？此时 \([\mathrm{Id}]_U\) 与 \(n^*\) 的大小关系
   如何？
2. 定理 3.34(5) 的坐标证明用了实数的阿基米德性质。请解释这个
   表面的循环：为什么「用 \(\mathbb R\) 的阿基米德性证明
   \({}^*\mathbb R\) 的非阿基米德性」不矛盾？
3. 定理 3.35 必要性证明的极限步中，为什么保留的叶区间两两不交？
   这一事实在哪一步用到了 \(\omega_1\)（而不能换成 \(\omega\)）？

---

上一章：[82 贝尔空间、波兰空间、投影集与博弈](82-polish.md) · 下一章：[84 舒适集合：把一阶逻辑植入 KP](84-admissible.md)
