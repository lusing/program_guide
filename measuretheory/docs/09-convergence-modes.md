# 09 可测函数序列的收敛

**对应严书 §2.3（pp. 37-44；其中 pp. 43-44 的 Riesz 定理部分按
标准理论重建，扫描对页缺失）。**

---

## 9.1 四种收敛：定义先行

设 (Ω, 𝓕, μ) 为测度空间，fₙ、f 为实值可测函数。

1. **逐点收敛**：∀ω, fₙ(ω) → f(ω)。
2. **几乎处处收敛（a.e.）**：存在零测集 N 使 fₙ → f 在 Nᶜ 上
   逐点成立（严书 2.3.1(1)）。
3. **几乎一致收敛（a.un.）**：∀ε > 0，存在 N ∈ 𝓕，μ(N) < ε，
   使 fₙ → f 在 Nᶜ 上**一致**成立（严书 2.3.1(2)）。
4. **依测度收敛**：∀ε > 0，μ([|fₙ − f| ≥ ε]) → 0（严书 2.3.1(3)；
   μ 为概率时称**依概率收敛**）。

a.un. 的定义姿态值得咀嚼：它是"Egorov 定理的结论侧"直接定义成
收敛方式——先定义目标，再问谁能到达。第 04 章的 Carathéodory
判据同款思路：把想证明的结构性写成可检验的定义。

依测度收敛的直观：**误差集的测度消失**。它不关心误差在**哪里**，
只关心多大——误差可以到处漂移。这个"宽容"正是它弱于 a.e. 的
地方，也是它对不可控振荡更有韧性的地方。

## 9.2 蕴含矩阵与两个招牌反例

不含测度条件时唯一的免费蕴含：**逐点 ⟹ a.e.**（取 N = ∅）。
其余方向各需条件，两个反例撑起整张矩阵的"否"栏。

**反例一（滑动脊，无穷测度）**：μ(Ω) = ∞（如 ℝ 上 Lebesgue），
fₙ = I_{[n, n+1]}。则 fₙ → 0 **逐点**（每点至多被一节脊背压住），
但不依测度：μ([|fₙ| ≥ 1/2]) = 1 ↛ 0。结论：**a.e. ⇏ 依测度**
（μ 无限时）；同时也破坏 a.un.（任何有限测度补集上的一致收敛
都会被无穷远处滑走的脊背打破）。μ(Ω) < ∞ 时此反例死亡——
下节 Egorov 修补此桥。

**反例二（打字机序列，有限测度）**：[0,1] 上依次点亮
[0,1]，[0,1/2]，[1/2,1]，[0,1/4]，[1/4,1/2]，…（第 k 层把
[0,1] 切成 2^k 段逐段点亮）。fₙ = 对应区间的示性。则：

- **依测度 → 0**：第 k 层每段长 2⁻ᵏ，μ([|fₙ| ≥ 1/2]) = 当前段
  长 ≤ 2⁻ᵏ → 0；
- **任何点都不收敛**：每个 x 被无穷多个层的光柱反复扫中，
  fₙ(x) 沿 0/1 两值振荡——a.e. 收敛彻底失败。

结论：**依测度 ⇏ a.e.**（任何测度下都可能失败）。同时它是
"逐点有界 + 依测度收敛"共存的标本身：‖fₙ‖∞ = 1 恒定，收敛全靠
**误差搬家**而非**误差变小**。Julia/Python 实验把这台打字机
数值复刻，脊背漂移与光柱扫描一目了然。

矩阵总结（详细证明后续各节）：

| 从 \ 到 | a.e. | a.un. | 依测度 |
|---|---|---|---|
| 逐点 | 免费 | 需 μ 有限（Egorov） | 需 μ 有限 |
| a.e. | — | 需 μ 有限（Egorov） | 需 μ 有限 |
| a.un. | 免费（Nᶜ 上收敛） | — | 免费（μ(N)<ε 摊派） |
| 依测度 | 子列成立（Riesz） | 子列成立 | — |

## 9.3 Egorov 定理：有限测度下的升降机

**定理（严书 2.3.5，Egorov）** μ(Ω) < ∞ 且 fₙ → f a.e. ⟹
fₙ → f a.un.。

**证明骨架**（下界集的尾和估计）：固定 k，令
U_{n,k} = ⋃_{i≥n} [|fᵢ − f| ≥ 1/k]（第 k 档误差的尾集）。a.e.
收敛 ⟹ 对每个 k，⋂ₙ U_{n,k} 含于零测集（好点上误差最终小于
1/k），故由**上方连续**（μ 有限！此处收费）μ(U_{n,k}) → 0。
取 n(k) 使 μ(U_{n(k),k}) < ε·2⁻ᵏ，令
N = ⋃_k U_{n(k),k}，则 μ(N) < ε，且 Nᶜ 上：∀k，∀i ≥ n(k)，
|fᵢ − f| < 1/k——恰是 Nᶜ 上的一致收敛。

上方连续需要有限性：μ(U_{n,k}) ↓ μ(⋂U_{n,k}) = 0 只有当某个
μ(U_{n,k}) < ∞ 时才成立——滑动脊反例中 U_{n,k} 测度恒为 1，
链条恰好断在这里。**Egorov 的 ε 换来的是"挖掉一小块后的一致"，
代价是 μ 有限**；σ-有限不够（滑动脊在 ℝ 上 σ-有限）。

## 9.4 依测度收敛的三张面孔

**尾测度刻画（严书 2.3.4）** fₙ → f 依测度 ⟺ 对每个 k ≥ 1：

  μ( ⋂ₙ ⋃_{i≥n} [|fᵢ − f| ≥ 1/k] ) = 0。

右端集合是"|fᵢ − f| ≥ 1/k 发生无穷多次"的点集（lim sup 型）。
对照：a.e. 收敛 ⟺ **每个** k 档的 lim sup 集都是零测（Borel-
Cantelli 语言：误差 ≥ 1/k 只发生有限次）。于是三者关系一眼看穿：
依测度收敛 = "误差无穷多次发生的**测度**消失"，a.e. 收敛 =
"误差无穷多次发生的**点集**为空"——前者允许坏点漂移。

**Riesz 子列定理** fₙ → f 依测度 ⟹ 存在子列 f_{n_k} → f
a.e.（甚至 a.un.）。构造：取 n(k) 使 μ([|f_{n(k)} − f| ≥
2⁻ᵏ]) ≤ 2⁻ᵏ，对角线打包后 Borel-Cantelli 引理（第 35 章正式
出场）收割：误差 ≥ 2⁻ᵏ 发生无穷次的点集零测，并起来仍零测，
好点集上收敛。**依测度收敛序列的"可提取骨架"是本章最重要的
技术工具**——它把"测度陈述"折算成"逐点陈述"，几乎所有
"依测度 + 传性质"的定理都经它中转。

**子列刻画（严书 2.3.6）** μ 有限时：

  fₙ → f 依测度 ⟺ (**fₙ 的任一子列**都有子列 a.e. 收敛于 f)。

⟸ 方向用反证 + Riesz：若不依测度收敛，存在 ε、δ 与子列使
μ([|f_{n_k} − f| ≥ ε]) ≥ δ 恒成立，但此子列仍依测度收敛于
某 g（若 Cauchy）……与"有子列 a.e. 收敛于 f"矛盾。这个刻画
是"几乎一致 = 依测度 + 提子列"（2.3.4(3)）的推论，也是数学
分析里"数列收敛 ⟺ 每个子列有收敛于同一极限的子列"的测度版
平移。**依测度 Cauchy**：μ([|fₙ − fₘ| ≥ ε]) → 0 (n, m → ∞)；
完备测度空间上依测度 Cauchy ⟺ 依测度收敛到某个可测 f
（Cauchy 列先由 Riesz 提取 a.e. 收敛骨架，极限回填）。

## 9.5 连续传递与随机 Bolzano-Weierstrass

**定理（连续传递，严书 2.3.7）** g : ℝᵐ ⊇ D → ℝ Borel 可测，
fₙ⁽ⁱ⁾ → f⁽ⁱ⁾ 依测度（值在 D 中），则：

- g 在 D 上**一致连续** ⟹ g(fₙ) → g(f) 依测度；
- g 在 D 上连续且 μ 有限 ⟹ 同样成立。

证明用 Riesz 骨架 + 对角线（m 个坐标各提一次子列）。应用：
依测度收敛序列可做算术（+、×、max…），因为 (f,g) ↦ f+g 一致
连续——**依测度收敛是个"运算友好"的收敛**，比 a.e. 温顺得多
（a.e. 收敛对加法封闭但对极限交换没有一般保证，第 11 章 Fatou
的反例即将展示）。

**随机 Bolzano-Weierstrass（严书 2.3.8，Föllmer-Schied）**
Rᵈ 值可测列满足 liminf |fₙ| < ∞ a.e. ⟹ 存在**可测的整值严格
增** αₙ 与 Rᵈ 值可测 f 使 f_{αₙ} → f a.e.。

与经典 Bolzano-Weierstrass 的对照：有界数列有收敛子列 ↔
"liminf 有限"的可测函数列有 a.e. 收敛的可测子列。**子列标号
αₙ 本身可测**是定理的全部难度——选择子列时必须躲开不可测的
上帝选择。它为第 42 章下鞅收敛定理提供标准动作（先抽紧骨架再
取极限），也是第 31 章讨论分布收敛稳定性的底牌之一。

## 9.6 Lean：mathlib 的三件套

`Ch09ConvergenceModes.lean` 对齐 mathlib 三个文件
（`Function/Egorov.lean`、`Function/ConvergenceInMeasure.lean`）：

```lean
/-- 依测度收敛的机器定义（注意右端是 edist 的测度趋于 0）。 -/
def MeasureTheory.TendstoInMeasure (μ : Measure α)
    (f : ι → α → E) (l : Filter ι) (g : α → E) : Prop :=
  ∀ ε, 0 < ε → Tendsto (fun i => μ {x | ε ≤ edist (f i x) (g x)}) l (𝓝 0)

/-- Riesz 子列定理（ConvergenceInMeasure.lean:279）。 -/
theorem TendstoInMeasure.exists_seq_tendsto_ae
    (hfg : TendstoInMeasure μ f atTop g) :
    ∃ ns : ℕ → ℕ, StrictMono ns ∧
      ∀ᵐ x ∂μ, Tendsto (fun i => f (ns i) x) atTop (𝓝 (g x))

/-- 子列刻画（ConvergenceInMeasure.lean:341，需 IsFiniteMeasure）。 -/
theorem MeasureTheory.exists_seq_tendstoInMeasure_atTop_iff :
    TendstoInMeasure μ f atTop g ↔
      ∀ ns, StrictMono ns → ∃ ns', StrictMono ns' ∧
        ∀ᵐ ω ∂μ, Tendsto (fun i => f (ns (ns' i)) ω) atTop (𝓝 (g ω))

/-- Egorov（Egorov.lean:211）：有限测度集上 a.e. 收敛 ⟹
    挖去 ε-小集后一致收敛。 -/
theorem MeasureTheory.tendstoUniformlyOn_of_ae_tendsto
    (hf : ∀ n, StronglyMeasurable (f n)) (hg : StronglyMeasurable g)
    (hsm : MeasurableSet s) (hs : μ s ≠ ∞)
    (hfg : ∀ᵐ x ∂μ, x ∈ s → Tendsto (fun n => f n x) atTop (𝓝 (g x)))
    (hε : 0 < ε) :
    ∃ t ⊆ s, MeasurableSet t ∧ μ t ≤ ENNReal.ofReal ε ∧
      TendstoUniformlyOn f g atTop (s \ t)
```

实弹两发：[0,1] 上 fₙ(x) = xⁿ（a.e. → 0，唯 x=1 例外）经 Egorov
产出挖集 t 与 [0,1]∖t 上的一致收敛；狄拉克测度上常值列 (1/2)ⁿ
经 `tendstoInMeasure_of_tendsto_ae`（严书 2.3.5(1) 机器版）直接
落地"a.e. ⟹ 依测度"。踩坑记要三条：Egorov 的假设是
`StronglyMeasurable`（非 `Measurable`）——Borel 可测实值函数两者
一致，但类型类不同，混用会卡在实例搜索；裸写 `Tendsto`/`atTop`
要 `open Filter`、`𝓝` 更要 `open scoped Topology`，否则 autoImplicit
把未知记号静默吞成哑变量；ℝ 上 volume 有两副实例面孔
（MeasureSpace 派生 vs `Real.measurableSpace`），a.e. 陈述改带
自由测度参数 + 零点集假设（μ {1} = 0），调用处再喂 volume，
绕开实例打架；`AEStronglyMeasurable` 是 ∃ 定义
（∃ g, StronglyMeasurable g ∧ f =ᵐ g），证据直接给三元组。

## 9.7 数值与逻辑实验

**Julia（`09_convergence_modes.jl`）**造三台机器：

- **滑动脊（ℝ，截断窗口 [0, M]）**：fₙ = I_{[n,n+1]}，窗口内
  采样估计 μ([|fₙ| ≥ 1/2]) ——截断口径下恒为 min(1, 窗口覆盖)，
  数值上验证"脊背滑出任何固定窗口"的同时记录逐点收敛：固定
  x 的轨迹 fₙ(x) 至多一节为 1 后归零——a.e. 成立、依测度失败，
  一屏对照。
- **打字机（[0,1]）**：实现层-段索引换算（n ↦ (k, j)），
  依测度偏差 μ([|fₙ| ≥ 1/2]) 的解析值 = 当前段长 2⁻ᵏ⁺¹ → 0，
  采样版本在容差内吻合；取定 x = 0.3 与 x = 0.7 的轨迹各被
  无穷次扫中（前 16383 项命中计数均 > 100）——依测度成立、
  逐点失败。
- **逃逸尖峰 + Egorov 数值版**：fₙ = n·I_{(0,1/n)}（a.e. → 0、
  逐点不单调），按证明构造挖集：n(k) = ⌈2^k/ε⌉，t = ⋃ₖ 尾集，
  补集 [1/n(1), 1] 上从 n(1) 起 sup-误差**精确为 0**——把
  Egorov 证明的常数选择（ε·2⁻ᵏ 摊派）变成可运行的数字。

**Python（`09_convergence_modes.py`）**对拍：打字机偏差用**解析**
段长（不经采样），命中计数用层-段索引直接换算；逃逸尖峰的
Egorov 挖集用 `Fraction` 精确核对 μ(t) ≤ ε 与补集 sup-误差 = 0。
浮点与精确、采样与解析两轴对拍，是该实验的门禁。

**Prolog（`09_convergence_modes.pl`）**在 Ω = {1,…,6} 均匀测度上
检验有限模型的**退化定理**：最小原子 1/6 > 0 逼迫"依测度收敛
⟺ 终归取值 ∅ ⟺ a.e. 收敛"——穷举全部 63 个非空示性函数，每个
的测度 ≥ 1/6，故示性序列若依测度收敛于 0 则有限步后必恒空，
打字机式振荡在有限空间**无法**依测度收敛。反例（依测度 ⇏ a.e.）
天然需要无穷空间——有限模型的"处处受阻"，正是无限定理的
边界线本身。

## 9.8 要点回顾

1. 四种收敛的定义姿态：a.un. 是"Egorov 结论侧"先行的定义。
2. 两反例定全局：滑动脊（无穷测度，a.e. ⇏ 依测度）、打字机
   （有限测度，依测度 ⇏ a.e.）。矩阵的其余箭头由 Egorov 与
   Riesz 补齐。
3. Egorov：μ 有限 + a.e. ⟹ a.un.；上方连续在证明中的收费点。
4. 依测度三面孔：尾测度刻画（lim sup 集零测）、Riesz 子列
   （对角线 + Borel-Cantelli）、子列刻画（有限测度）。依测度
   Cauchy ⟺ 依测度收敛（完备空间）。
5. 连续传递 + 随机 Bolzano-Weierstrass（可测子列标号）——
   第 42 章鞅收敛的标准前置件。

*对应示例：`examples/lean/Measuretheory/Ch09ConvergenceModes.lean`、
`examples/julia/09_convergence_modes.jl`、`examples/python/09_convergence_modes.py`、
`examples/prolog/09_convergence_modes.pl`。*

---

上一章：[08 函数形式的单调类定理](08-functional-monotone-class.md) · 下一章：[10 积分的构造与基本性质](10-integral.md)
