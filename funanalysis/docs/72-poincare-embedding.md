# 72 · Poincaré 不等式与 Sobolev 嵌入

> H¹ 范数里只住着导数；"函数本身多大"要靠零边界条件来补偿——
> 这就是 Friedrichs/Poincaré 不等式。而 Sobolev 嵌入把这句话反过来
> 说：导数足够多，函数自动获得更多正则性——连续、Hölder、更高次
> 可积。紧嵌入再补一刀：这"升级"在极限过程中不丢失质量。
> ——《工科泛函分析基础》第 6 章前半（意译）

本章对应书 6.1 节的等式线（Friedrichs 不等式 6.1.1、密度传递 6.1.6、
列紧性 6.1.7）与 6.2 节的嵌入线（W^{k,p} 范数 6.2.1、Poincaré 6.2.3、
Hölder 空间与嵌入定理 6.2.4-6.2.6、紧嵌入 6.2.7）。71 章定义了
Sobolev 空间；本章回答两个问题：**这些空间里有多少"函数本身的
控制"**（Poincaré），**这些空间之间与向外的映射有多好**（嵌入）。

## 72.1 为什么要边界条件：Friedrichs 不等式

W^{1,2} 的范数是 ‖u‖² + ‖∇u‖²——"函数本身"那一项自带。但变分法
（73 章）真正使用的内积是 ⟨u,v⟩₁ = ∫∇u·∇v（只有导数项）：它只是
半正定（常数函数零范数），不是内积。**Poincaré 不等式说：在零边值
的函数类上，半内积升级为真内积**——函数本身被导数控制。

**定理（Friedrichs/Poincaré，书 6.1.1）**。设

```
B₀ = { u ∈ C¹(Ω) ∩ C(Ω̄) : u 在 ∂Ω 上为零 }
```

则存在只依赖 Ω 的常数 C，使

```
∫_Ω u² dx ≤ C² ∫_Ω |∇u|² dx      对一切 u ∈ B₀
```

**证明（书的零延拓平板论证，完整给出）**。Ω 有界，故可装进平板
{aᵢ < xᵢ < aᵢ + h}（对第一个坐标方向；h 是平板厚度）。u 在边界为零，
故在平板外延拓为零后，对 Ω 内任一点 x：

```
u(x) = u(x) − u(a₁, x₂, …, xₙ) = ∫_{a₁}^{x₁} D₁u(t, x₂, …, xₙ) dt
```

Schwarz 不等式（对积分）：

```
u²(x) ≤ (x₁ − a₁) · ∫_{a₁}^{a₁+h} |D₁u|² dt ≤ h ∫ |D₁u(t, x₂…)² dt
```

对 x 于 Ω 上积分（Fubini 交换次序）：

```
∫_Ω u² dx ≤ h ∫_Ω ∫ |D₁u|² dt dx = h·h ∫_Ω |D₁u|² dx ≤ h² ∫_Ω |∇u|² dx ∎
```

三行证明、零技巧、常数 h²。**密度传递（书 6.1.6）**：C₀¹ 在 W₀^{1,2}
中稠密（71 章的完备化定义），不等式两边对范数连续，故它对整个
W₀^{1,2} 成立——取逼近列 uₖ → u，对 uₖ 用不等式再取极限。W^{k,p}
版本（书 6.2.3）同型。

**常数能有多好？** 初等证明给 C = h（区间长）。一维 (0,d) 上最优
常数是 d/π：Dirichlet 特征值问题 −u″ = λu、u(0)=u(d)=0 的第一特征
函数 sin(πx/d) 恰好取等，λ₁ = (π/d)²，故 ‖u‖ ≤ (d/π)‖u′‖。Julia
实验 1（`examples/julia/72_poincare_embedding.jl`）用离散 Dirichlet
刚度阵的最小特征值数值逼近 π²，并用 sin(πx) 验证最优比值恰 1/π²
（数值 0.1013）；初等常数 1 比它宽 π² 倍——**对变分法任何有限常数
都够用**，最优常数只是美。

**边界条件不可省**。Python 实验 2（`examples/python/72_poincare_embedding.py`）
的对照：常数函数 ‖u‖_{L²}=1 而 ‖∇u‖=0——不等式彻底破产；零边界的
截断函数族恢复不等式。Prolog 通道（`prolog/72_poincare_embedding.pl`）
把"谁满足 Poincaré"做成规则：`poincare(U) :- zero_boundary(U)`，
`poincare_broken(const)`——查询即判例。

## 72.2 一维 Morrey：嵌入定理的入门形态

嵌入定理的一般陈述（书 6.2.6）要到 72.4，但它的**一维形态**只需要
一行分部积分——而且恰好是 Lean 通道全证的那条。

**命题（一维 Morrey）**。f 在 [a,b] 上连续可微，则

```
|f(x) − f(y)| = |∫_x^y f′(t)dt| ≤ ∫_x^y |f′|dt ≤ ‖f′‖_{L¹(a,b)}
```

第一个等号是微积分基本定理，第二个是积分三角不等式，第三个是区间
单调。三步都不超过大一微积分，但结论重大：**W^{1,1}(a,b) 中的函数
自动有界且一致连续**（每个等价类有唯一的连续代表元）——导数可积
就"白送"连续性。更强的 L² 版（Schwarz 代替三角）：|f(x) − f(y)| ≤
√|x−y|·‖f′‖_{L²}——函数自动 Hölder-1/2。Julia 实验 4 与 Python 实验 1
对具体函数两版同时验证。

Lean 通道（`Funanalysis/Ch72Poincare.lean`）把它完整形式化为两层：

```lean
theorem abs_sub_le_integral_abs_deriv {f f' : ℝ → ℝ} {a b : ℝ} (hab : a ≤ b)
    (hderiv : ∀ x, HasDerivAt f (f' x) x) (hint : IntervalIntegrable f' volume a b) :
    |f b - f a| ≤ ∫ x in a..b, |f' x|
```

证明链：`intervalIntegrable_congr` 把 f′ 的可积性搬到 deriv f →
`integral_deriv_eq_sub`（微积分基本定理）→ `abs_integral_le_integral_abs`
（三角）→ `integral_congr`（|deriv f| = |f′|）。第二层 `supnorm_le_l1_deriv`
加零边界条件 f(0)=0，用相邻区间拆分（`integral_add_adjacent_intervals`）
把振幅控制推进到整段：|f t| ≤ ∫₀¹|f′| 对一切 t ∈ [0,1]——上界与 t
无关，这就是"一致有界"的机器形态。一个工程细节值得一提：树的快照
里 `IntervalIntegrable` 没有 abs 传递引理（`f′` 可积 ⟹ `|f′|` 可积
这一标准事实缺失），第二层定理把 |f′| 的可积性作为显式假设——
诚实的接口缺口标注。

## 72.3 平移估计与列紧性：紧嵌入的钥匙

**定理（书 6.1.7）**。W₀^{1,2}(Ω) 中的有界集在 L²(Ω) 中列紧。

**证明（书的平移估计路线）**。列紧性（在 L² 中）由 Kolmogorov-Riesz
判据给出：有界 + 平移一致连续 ⟹ 列紧。核心是平移估计：对
u ∈ C₀¹，x ∉ Ω 处补零，

```
u(x+h) − u(x) = ∫₀¹ ∇u(x + th)·h dt
```

Schwarz（对 t 的积分）：|u(x+h) − u(x)|² ≤ |h| ∫₀¹ |∇u(x+th)|²dt。
对 x 积分并换元 y = x+th：

```
‖u(·+h) − u(·)‖²_{L²} ≤ |h| · ∫₀¹ ∫|∇u(y)|² dy dt = |h|·‖∇u‖²_{L²}
```

即 ‖u(·+h) − u‖ ≤ √|h|·‖∇u‖。有界集的 ‖∇u‖ 一致有界 ⟹ 平移
一致小 ⟹ 列紧（Arzelà-Ascoli 的 L² 版）。密度再传递到 W₀^{1,2}。∎

Julia 实验 2 数值验证 √h 缩放律：h 从 0.1 缩到 0.001，平移范数
按 √h 单调下降且始终在界内。**紧性的数值化身**（Julia 实验 3 /
Python 实验 4）更精彩：W 范数归一的高频振荡列

```
eₙ = sin(nπx) / √(1 + n²π²)，  ‖eₙ‖_{W^{1,2}} = 1 恒定
```

其 L² 范数 ~ 1/(nπ√2) → 0：**强收敛**。对照的 L² 归一列 √2 sin(nπx)
范数恒 1——只弱收敛、不列紧。差别就在导数能量：W 的界"罚掉"了
高频，使序列不可能靠振荡逃出紧性——这就是 Rellich 定理的机制，
73 章弱解的谱方法与 58 章（Friedrichs-Rellich 谱聚 0）在此会师。

## 72.4 嵌入定理：三段式与临界指数

先固定语言。**Hölder 空间（书 6.2.4）**：C^{m,λ}(Ω̄) 是 m 阶导数
满足指数 λ 的 Hölder 条件的函数空间，λ=1 时即 Lipschitz——比
C^m 更细的正则性标尺。**嵌入（书 6.2.5）**：X ⊆ Y 且 ‖x‖_Y ≤ C‖x‖_X，
记 X ↪ Y——集合包含 + 范数控制。

**定理（Sobolev 嵌入，书 6.2.6）**。Ω ⊂ ℝⁿ 有界区域，1 ≤ p，
则对任意正整数 k：

```
W^{k,p}(Ω) ↪ { L^q，任意 q          当 kp > n（Hölder 段：C^{m,λ}，λ = k − n/p − m）
             { L^q，一切 q < ∞      当 kp = n（临界段：不到 L^∞）
             { L^{q*}，q* = np/(n−kp) 当 kp < n（次临界段）
```

书把证明指向文献（Gagliardo-Nirenberg 链），但教程纪律要求自包含
说明——给两层：

**一维完全证明**（kp > 1 ⟹ 连续甚至 Hölder）：72.2 的 Morrey 两行。
Hölder 指数精确算出：|f(x)−f(y)| ≤ ‖f′‖_{L^p}·|x−y|^{1−1/p}（对
∫f′·1 用 Hölder，共轭对 (p, p/(p−1))）。Prolog 通道的
`morrey_holder_exponent(P, Lam)` 直接计算 λ = 1−1/p：p=2 给 1/2、
p=1 给 0（C⁰）。

**一般维数的机制**（Gagliardo 硬不等式的思想）：逐坐标用一维公式
|u(x)| ≤ ‖Dᵢu‖_{L¹}（沿第 i 条线积分），n 个方向的不等式相乘再开
n 次方，得 ‖u‖_{L^{n/(n−1)}} ≤ ∏‖Dᵢu‖^{1/n}_{L¹} ≤ ‖∇u‖_{L¹}——
一阶导数换一次可积性升级；迭代 k 次并配合 Hölder 内插得到三段式。
机器世界里这正是 mathlib 的 `SobolevInequality.lean`（Gagliardo-
Nirenberg-Sobolev 全证明，Lean 锚点 `eLpNorm_le_eLpNorm_fderiv_one`）。

**临界现象的数值体感**（Python 实验 3）：n=3 中 u(r) = r^{−1/2}——
L²(B₁) 成员（∫r⁻¹r²dr < ∞）但 W^{1,2} 破产（导数平方 r^{−3}，
积分 0.25∫r^{−1}dr 对数发散）。它恰好骑在 kp=2·1 < n=3 的临界带
q* = np/(n−kp) = 6 上（W^{1,2}(ℝ³) ↪ L⁶ 的经典情形，Prolog 实验 2
的读表：`embeds(3, 1, 2, lq(6))`）。71 章 ln r 的维数临界（n ≥ 3）
与这里的 r^{−1/2} 是同一枚硬币：**n 出现在分母上，多一个维度就
少一分可积性预算**。

**紧嵌入（书 6.2.7，Rellich-Kondrachov）**：kp < n 时 W^{k,p} ↪↪
L^q 对一切 q < q*（临界指数不可达，q* 处只连续不紧）——72.3 的
平移估计是其证明的核心引擎。Prolog 规则 `compact_embeds(3,1,2,Q)`
对一切 Q < 6 成功。

## 72.5 两层范数的等价（书 6.2.1 注）

W^{k,p} 的范数有两种取法：Σ_{|α|≤k}（全和）与 Σ_{|α|=k}（只最高阶）。
书指出二者等价——后者只是半范数，Poincaré 把它升级：低阶项被
最高阶项控制（反复用 72.1）。数值上（Python 71 章实验 2 已验证
‖u′‖ ≤ ‖u‖_A ≤ C‖u′‖），等价的实质是：**零边界条件下"只有导数"
与"函数加导数"携带相同信息**。这条等价让 73 章可以直接用
⟨u,v⟩ = ∫∇u·∇v 当内积，绕开常数函数的退化。

## 72.6 机器通道全览

**Lean（`Funanalysis/Ch72Poincare.lean`）**：一维 Morrey 两层全证
（72.2）；Gagliardo-Nirenberg-Sobolev 官方锚点巡礼（72.4 的机器
对应）。**Julia**：Poincaré 常数谱逼近与最优取等、√h 平移律、
Rellich 强收敛、双版 Morrey。**Python**：Morrey 数值、Poincaré
边界必要性（常数反例）、n=3 临界带（r^{−1/2} 的 L²✓/W^{1,2}✗ 与
对数发散）、紧性 vs 弱收敛对照。**Prolog**：Poincaré 生效规则、
嵌入三段式读表（含经典 W^{1,2}(ℝ³)→L⁶）、Hölder 指数计算、
紧嵌入规则。

## 72.7 习题

1. **（纸笔）**补全 72.1 的 Fubini 步骤：写出 h²∫_{a₁}^{a₁+h}dt
   到 h²∫_Ω|D₁u|²dx 的显式换序。
2. **（纸笔）**证明一维最优常数：在 (0,d) 上 ‖u‖ ≤ (d/π)‖u′‖ 且
   sin(πx/d) 取等（提示：u 按特征函数展开，Parseval + 每项
   λₖ ≥ (π/d)²）。
3. **（纸笔）**书 6.2.3 的 W^{k,p} 版 Poincaré 用 71 章的密度论证
   从 B₀ 传递到 W₀^{k,p}——写出 ‖·‖_{L^p} 对逼近列的连续性论证。
4. **（机器）**Lean：把 `supnorm_le_l1_deriv` 的假设 `hintabs` 去掉——
   先证 `IntervalIntegrable f' volume a b → IntervalIntegrable
   (fun x => |f' x|) volume a b`（提示：intervalIntegrable_iff 展开
   成 Integrable + |f'| ≤ 可积函数的 control，或 measurable +
   lintegral 有限）。
5. **（数值）**Julia 实验 1 中把区间换成 (0, 2)：最优常数应变为
   2/π。验证谱逼近与 sin(πx/2) 取等。
6. **（数值）**Python 实验 3 中把奇性换成 r^{−α}，扫描 α ∈ (0,1)：
   找出 u ∈ L²(B₁⊂ℝ³) 与 ∇u ∈ L² 的 α 区间，与临界指数 q* = 6
   的预测对照（α < 1/2 ⟹ u ∈ L²；α > 1/2 破产——分界恰在 1/2）。

---

上一章：[71 弱导数：从 δ 到 Sobolev 空间 W^{k,p}](71-weak-derivatives.md) · 下一章：[73 弱解与 Galerkin 误差：边值问题的 Riesz 路线](73-galerkin-cea.md)
