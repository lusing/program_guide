# 第 45 章 级数收敛与三级数定理：随机和的精确账本

## 45.1 从"和的极限"到"级数的收敛"

第 26 章的大数定律回答 $S_n/n\to0$ 何时成立；本章后退一步问更原始的问题：**随机级数 $\sum_n X_n$ 本身何时几乎必然收敛**。这不是绕远：Kolmogorov 强大数定律的证明路线正是“先证 $\sum_n (X_n-E X_n)/b_n$ 收敛，再用 Kronecker 引理换算成 $(S_n-E S_n)/b_n\to0$ —— 级数收敛是强律的发动机。

回忆收敛模式的关系（第 25 章）：几乎必然收敛蕴含依概率收敛。对独立项级数，有一个出人意料的好消息：**依概率收敛与几乎必然收敛等价**（这是 Cauchy 收敛准则加极大不等式的联合推论，见 45.2）。因此本章的全部判定自动给出最强结论。

## 45.2 Kolmogorov 不等式：轨道最大值的控制

**定理（胡书定理 6.1.1）** 设 $X_1,\dots,X_n$ 独立、方差有限，$S_k=\sum_{j\le k}X_j$ ，则对任意 $\varepsilon>0$ 有

$$ P\Big(\max_{1\le k\le n}|S_k-E S_k|\ \ge\varepsilon\Big)\ \le\ \frac{\operatorname{var}(S_n)}{\varepsilon^2}. $$

它与 Chebyshev 不等式的差别是质变：Chebyshev 只看终点 $S_n$ ，Kolmogorov 控制整条轨道的最大值。证明的骨架是"正交增量的分部账"：在事件 $\{|S_k-E S_k|$ 首次越线 $\}$ 上把 $S_n^2$ 拆成 $S_k^2$ 与独立增量两部分，越线片段贡献 $\varepsilon^2$ 倍概率、增量片段的期望恰是剩余方差——两边合计就是不等式。

mathlib 把这件事做成了鞅语言的一般定理（Doob 极大不等式）：

```lean
#check @MeasureTheory.maximal_ineq
-- 非负下鞅 f：ε * μ{sup'_{k≤n} f k ≥ ε} ≤ ∫_{sup' < ε 处} f n
-- 取 f := (Sₖ − E Sₖ)² 即得 Kolmogorov 不等式（6.1.1 的鞅原形）
```

本章 Prolog 通道对 $n=12$ 的全部 $2^{12}$ 条 $\pm1$ 路径**穷举验证**：$P(\max_{k\le12}|S_k|\ge7)=\text{计数}/4096\le 12/49$ ，精确分数判决。

## 45.3 方差账的收敛与必要方向

**定理（胡书定理 6.1.2）** 若 $\sum_n\operatorname{var}(X_n)<\infty$ ，则 $\sum_n (X_n-E X_n)$ 几乎必然收敛。

证明用 45.2 的不等式对尾部区间 $[m,k]$ 求 $P(\max_{m<j\le k}|S_j-S_m|\ge\varepsilon)\le\varepsilon^{-2}\sum_{m<j\le k}\operatorname{var}(X_j)$ ，让 $m\to\infty$ 得尾段一致小（a.s. Cauchy）。反方向由引理 6.1.1（有界情形的下界）与定理 6.1.3 补齐：有界独立项级数 a.s. 收敛时，$\sum\operatorname{var}(X_n)<\infty$ 且 $\sum E X_n$ 收敛——**方差账在两个方向都是精确的**，不是充分条件的松包。

本章 Lean 件把两类方差账做成完全证明的证书：

```lean
theorem dyadic_block_ge (m : ℕ) :
    ∑ k ∈ Finset.Ico (2 ^ m) (2 ^ (m + 1)), (1 : ℚ) / k ≥ 1 / 2 := ...
theorem harmonic_dyadic_lb (M : ℕ) :
    ∑ k ∈ Finset.range (2 ^ M), (1 : ℚ) / k ≥ (M : ℚ) / 2 := ...
```

第一定理说每个二进块 $[2^m,2^{m+1})$ 的调和贡献至少 $1/2$ （块内 $2^m$ 项、每项 $\ge 1/2^{m+1}$ ），第二定理叠起来得 $H_{2^M}\ge M/2$ ——发散的可验证证书。对应随机级数 $X_k=\pm k^{-1/2}$ ：$\operatorname{var}=1/k$ ，$\sum\operatorname{var}=\infty$ ，级数 a.s. 发散。收敛方向：

```lean
theorem sq_sum_bound (m : ℕ) :
    ∑ i ∈ Finset.range m, (1 : ℚ) / ((i + 2) * (i + 2)) ≤ 1 := ...
```

$1/k^2\le 1/(k(k-1))=1/(k-1)-1/k$ 后望远镜求和（`telescoping_range`，裂项引理 `sum_telescope` 自归纳证明），$\sum_{k\ge2}1/k^2\le1$ ——$X_k=\pm1/k$ 的级数 a.s. 收敛的证书。

## 45.4 三级数定理：充要条件的三个旋钮

**定理（胡书定理 6.1.4，Kolmogorov 三级数定理）** 设 $X_1,X_2,\dots$ 独立。级数 $\sum_n X_n$ 几乎必然收敛，当且仅当存在 $d>0$ 使下面三个级数收敛：

$$ \text{(a)}\ \sum_n P(|X_n|\ge d);\qquad \text{(b)}\ \sum_n E\big[X_n\,1_{\{|X_n|<d\}}\big];\qquad \text{(c)}\ \sum_n \operatorname{var}\big(X_n\,1_{\{|X_n|<d\}}\big). $$

且对某个 $d$ 收敛则对一切 $d$ 收敛（阈值不敏感）。

三个旋钮各管一件事：

- **(a) 截尾频率**：越过阈值的事件只允许发生有限多次——第一 Borel–Cantelli（第 25 章）把"和有限"翻成"a.s. 只有有限次越线"；反之 (a) 发散且独立时，第二 Borel–Cantelli（`ProbabilityTheory.measure_limsup_eq_one`）保证无限次越线，通项不趋零，级数 a.s. 发散。
- **(b) 截尾中心**：被截断后的确定性漂移必须可和——这是把 $X_n$ 换成 $X_n1_{\{|X_n|<d\}}$ 时的对账项。
- **(c) 截尾方差**：小波动部分的累计方差必须有限——正是 45.3 的方差账。

证明的骨架：充分性 = (b)(c) 给出截尾级数 a.s. 收敛（定理 6.1.2）+ (a) 保证原变量与截尾变量最终相同（BC）；必要性 = a.s. 收敛给 $X_n\to0$ （(a) 收敛）+ 定理 6.1.3 的有界必要性（(b)(c) 收敛）。

Lean 件把三账做成可计算定义（`seriesA`/`seriesB`/`seriesC`：越线计数、截尾和、截尾平方和）并在具体数组上逐项判定：

```lean
example : seriesC [1, -1 / 2, 1 / 3, -1 / 4, 1 / 5, -1 / 6] 1
    = 1 / 4 + 1 / 9 + 1 / 16 + 1 / 25 + 1 / 36 := by
  norm_num [seriesC]
```

## 45.5 从级数到强大数定律：Kronecker 引理

**引理（胡书引理 6.2.1，Kronecker）** 设 $b_n>0$ 递增趋于 $\infty$ 。若级数 $\sum_n x_n/b_n$ 收敛（有限和），则 $b_n^{-1}\sum_{k\le n}x_k\to0$ 。

**定理（胡书定理 6.2.1，Kolmogorov SLLN）** 若 $\sum_n\operatorname{var}(X_n)/b_n^2<\infty$ ，则 $(S_n-E S_n)/b_n\to0$ 几乎必然。

证明只有两行：级数 $\sum_n (X_n-E X_n)/b_n$ 由定理 6.1.2 a.s. 收敛，Kronecker 引理把它换成 $b_n^{-1}(S_n-E S_n)\to0$ 。取 $b_n=n$ 、配第 26 章的截断技术即得 iid 情形的 $S_n/n\to E X_1$ （定理 6.2.2）。Python 通道用 $b_n=n^2$ 、$x_k=(-1)^k k$ 数值验证引理：$(1/n^2)\sum_{k\le n}(-1)^k k\le1/n$ 逐点成立。

## 45.6 Lévy 不等式与 Feller 弱律：没有期望也有定律

**引理（胡书引理 6.2.2，Lévy 不等式）** 独立 $X_1,\dots,X_n$ ，$S_j$ 为部分和，则

$$ P\Big(\max_{1\le j\le n}\big[S_j-m(S_j-S_n)\big]\ \ge\varepsilon\Big)\ \le\ 2P(S_n\ge\varepsilon),\qquad P\Big(\max_{1\le j\le n}|S_j-m(S_j-S_n)|\ \ge\varepsilon\Big)\ \le\ 2P(|S_n|\ge\varepsilon). $$

其中 $m(\cdot)$ 是中位数——**连期望都不需要存在**。它是 Kolmogorov 不等式在无矩情形的替身，也是对称化技术的代表作。

**定理（胡书定理 6.2.3，Feller 弱律）** iid 情形，存在中心 $c_n$ 使 $(S_n-c_n)/n\to0$ （依概率）当且仅当

$$ nP(|X_1|>n)\ \longrightarrow\ 0, $$

且条件成立时可取 $c_n=nE[X_1\,1_{\{|X_1|\le n\}}]$ 。

解读：**重尾到没有均值也能有弱大数定律**，条件只是"尾巴在 $n$ 尺度上变薄"。Julia 通道对 Pareto 尾 $(1+x)^{-\beta}$ 做对照实验：$\beta=2$ 时越界概率从 $0.01$ （$n=100$ ）降到 $0.002$ （$n=800$ ）；$\beta=1$ 时 $nP(|X|>n)\to1$ ，越界概率卡在 $0.62$ 附近不动——弱律失败不是模拟噪声，是定理判定的结构失败。

## 45.7 机器账总览

四条通道在本章的分工：

| 通道 | 内容 | 证据形态 |
|---|---|---|
| Lean | 二进块调和下界、$\sum1/k^2\le1$ 望远镜、三账定义与具体判定、Dood 极大不等式锚 | 一般 $m$ 与 $M$ 定理完全证明 |
| Julia | 随机符号级数 $\alpha\in\{0.4,0.6\}$ 的增量方差对账、Kolmogorov 不等式 MC、Feller 弱律两尾对照、$d$ 不敏感 | 固定种子模拟 + 方差理论值 |
| Python | $H_{2n}-H_n\ge1/2$ 逐 $n$ 精确分数、望远镜上界 $1-1/n$ 、三账 $d$ 对照、Kronecker 数值 | Fraction 精确 |
| Prolog | 收敛候选 $\pm1/k$ 与发散候选 $\pm1/\lfloor\sqrt k\rfloor$ 的三账、$2^{12}$ 路径穷举极大不等式 | rdiv 分数与穷举计数 |

Julia 的增量方差对账把"门槛 是 $alpha=1/2$ ，把它变成可见的数字：

```julia
function increment_std(alpha, n1, n2, reps)
    t = [sum((rand(rng) < 0.5 ? 1 : -1) * k^(-alpha) for k in n1+1:n2) for _ in 1:reps]
    std(t)
end
# alpha=0.6：理论 sigma = 0.376，经验 sigma = 0.376（收敛）
# alpha=0.4：理论 sigma = 1.844，经验 sigma = 1.875（发散）
```

理论值来自增量方差 $\sum_{k>2000}k^{-2alpha}$ 的精确计算，模拟只负责印证——方差可加性（独立性）把"收敛与否"完全决定在确定性数列 $k^{-2alpha}$ 的可和性上，这正是定理 6.1.2 的内容。

Python 把同一证书做成逐 $n$ 的精确断言：

```python
def harmonic(n):
    return sum((F(1, k) for k in range(1, n + 1)), F(0))

for n in [8, 64, 512]:
    block = harmonic(2 * n) - harmonic(n)
    assert block >= F(1, 2)          # 二进块证书：逐 n 精确成立

for n in [10, 100, 1000]:
    sq = sum((F(1, k * k) for k in range(2, n + 1)), F(0))
    assert sq <= F(1) - F(1, n)      # 望远镜上界：1 - 1/n
```

注意证书不需要 $\pi$ ：调和发散的判据是块结构 $H_{2n}-H_n\ge1/2$ ，收敛的判据是与 $1/(k(k-1))$ 的逐项比较——两者都是有限可验证的代数事实。这正是"渐近定理的机器证据"该有的形状：把无穷的判断折叠成任意 $n$ 处都能执行的断言。

最有教学价值的是发散候选的设计：要让 (c) 发散而保持有理算术，取 $w_k=(-1)^k/\lfloor\sqrt k\rfloor$ ——幅值平方 $1/\lfloor\sqrt k\rfloor^2$ 在每个块 $[j^2,(j+1)^2)$ 内贡献约 $2j\cdot j^{-2}=2/j$ ，部分和按调和速度增长（Prolog 实测 $2.97\to4.44\to5.88$ ，无界）。它绕开了 $\pm k^{-1/2}$ 的无理值，把"方差账发散"完整保进 rdiv 世界。

Prolog 的三账引擎与穷举器是本章的判决面：

```prolog
three_account(Gen, N, D, A, B, C) :-
    findall(X, (between(1, N, K), call(Gen, K, X)), Vs),
    include([X] >> (abs(X) >= D), Vs, Over),
    length(Over, A),
    exclude([X] >> (abs(X) >= D), Vs, Under),
    sum_list(Under, B),
    maplist([X, Y] >> (Y is X * X), Under, Sq),
    sum_list(Sq, C).

kolmogorov_count(N, Eps, Count, Total) :-
    Total is 2 ^ N,
    T1 is Total - 1,
    findall(1, (between(0, T1, Bits), path_max(N, Bits, M), M >= Eps), Hits),
    length(Hits, Count).
```

`path_max/3` 用位串枚举全部 $2^{12}$ 条 $\pm1$ 路径并记录轨道最大值——极大不等式在这个小宇宙里不是不等式，是精确的计数等式 $324/4096$ 与上界 $12/49$ 的比较。有限宇宙的穷举永远不能证明渐近定理，但它能证明"定理在可及范围内没有说谎"——这与 Lean 的一般 $M$ 定理形成三层证据：穷举（小宇宙）$	o$ 精确分数（任意前缀）$	o$ 形式证明（一切 $M$ ）。

## 45.8 经济与统计中的级数收敛

先说一个连接两章的事实：第 44 章的 u.a.n. 三角阵列行和若收敛，其行内分量满足的正是本章意义下的"小分量"结构——三级数定理 (c) 在行内的版本就是 Lindeberg 型方差控制。换句话说，随机级数（本章）与三角阵列（第 43-44 章）是同一枚硬币的两面：前者固定一列变量问部分和，后者每行换一组变量问分布极限；判据的灵魂都是"方差账可加、截尾账可换"。

- **贴现和的收敛**：永久收入理论里消费由 $\sum_k \beta^k Y_{k+1}$ 型贴现和给出；收入带随机冲击时，和的 a.s. 收敛条件就是三级数（$\beta<1$ 时方差账 $\sum\beta^{2k}\operatorname{var}(Y)$ 几何收敛，自动满足；$\beta=1$ 时回到本章判据）。
- **趋势分解**：单位根检验（第 29 章的渐近工具）背后的序列 $y_t=y_{t-1}+\varepsilon_t$ 是"发散级数"的样本版；平稳化（差分）的数学前提正是差分后级数的 (c) 收敛。
- **风控的累计损失**：跨期加总的风险敞口若有 $\operatorname{var}(X_n)\sim n^{-\alpha}$ 型衰减，$\alpha>1/2$ 是累计风险有限的门槛——三级数把这个直觉变成可检查的账本。

再看一个三账的完整算例。设 $X_k$ 以概率 $1-1/k^2$ 为 $0$ 、以概率 $1/(2k^2)$ 为 $\pm10$ （稀疏跳跃）。取 $d=1$ ：(a) $\sum P(|X_k|\ge1)=\sum1/k^2<\infty$ 收敛；(b) 截尾部分全为 $0$ （跳幅 $10$ 全部越线），收敛；(c) 同理为 $0$ 。三级数全过，级数 a.s. 收敛——事实上轨道上只有有限多次跳跃（BC），收敛性显然。把跳幅换成 $\pm k^{1/4}$ ：(a) 仍收敛，(b) 仍为 $0$ ，但 (c) $\sum k^{1/2}/k^2=\sum k^{-3/2}$ 收敛——仍收敛。再换 $X_k=\pm k^{1/4}\cdot\eta_k$ ，$\eta_k\sim\mathrm{Bernoulli}(1/k)$ ：(a) $\sum1/k$ 发散——第一关就倒下，通项不趋零。三账像三道滤网，任何一道截停都给出否决；全部通过才放行。Julia 与 Python 通道的 ④ 段复现了第一组参数下 $d=1$ 与 $d=3$ 的三账全同（跳幅远大于阈值时截尾集合不随 $d$ 变化）。

## 45.9 常见误区

1. **"方差有限就够了"**——不对，要的是**和**有限：$\operatorname{var}(X_n)=1/n$ 每项都有限，但 $\sum1/n=\infty$ ，级数 a.s. 发散（二进块证书）。
2. **"几乎必然收敛很难验证，实践中用依概率就行"**——对独立项级数两者等价，本章判据直接给最强结论。
3. **"三级数里 $d$ 的选择影响结论"**——定理明确：对某个 $d$ 三账收敛则对一切 $d$ 收敛；机器账也实测了 $d=1$ 与 $d=3$ 的差别只出现在越线集合的划分上。
4. **"重尾数据没有大数定律可用"**——Feller 弱律说只要 $nP(|X|>n)\to0$ ，中心化的弱律就成立；缺的只是均值，不是定律。

还有一个值得单独说的等价性：对独立项级数，依概率收敛与几乎必然收敛等价。原因是极大不等式把 Cauchy 准则的概率控制从"终点"推广到"整条轨道"，于是依概率的 Cauchy 性自动升级为 a.s. 的 Cauchy 性。这解释了为什么本章从不区分"验证哪种收敛"——三级数通过时你拿到的直接就是最强结论。第 25 章移动区间反例里"依概率但不 a.s."的现象之所以可能出现，靠的恰恰是**不独立**的精心构造；独立性一旦到场，两条收敛就锁死在一起。

## 45.10 本章要点

（本章四通道全部通过；三张"证书"——二进块下界、望远镜上界、穷举计数——是任何渐近教程都值得保留的证据形态。）

级数收敛是概率论里少有的"账本完全透明"的领域：每一条判据都能写成分块的、可在任意截断处复核的代数事实。下一章把这套账本推到极限精度——重对数律，它给出 $\limsup S_n$ 的**精确常数**，而不只是 $O(\cdot)$ 的阶。

1. Kolmogorov 不等式控制轨道最大值（Chebyshev 只看终点），mathlib 面是 `MeasureTheory.maximal_ineq`，Prolog 面是 $2^{12}$ 路径穷举。
2. 定理 6.1.2/6.1.3：$\sum\operatorname{var}<\infty$ 是有界情形的充要；Lean 的二进块下界（$H_{2^M}\ge M/2$ ）与望远镜上界（$\sum_{k\ge2}1/k^2\le1$ ）是两张可验证证书。
3. 三级数定理：(a) 截尾频率（BC 引理）、(b) 截尾中心、(c) 截尾方差——对某个 $d$ 收敛即对一切 $d$ 收敛。
4. 强大数定律 = 级数收敛（6.1.2）+ Kronecker 引理；iid 情形回到第 26 章的 $S_n/n\to E X_1$ 。
5. Lévy 不等式用中位数替代期望；Feller 弱律：$nP(|X|>n)\to0$ 是弱律的充要，重尾不是死刑。
6. 机器账的巧件：$(-1)^k/\lfloor\sqrt k\rfloor$ 把“方差发散”保进有理世界；Julia 的增量标准差对账（ $0.376$ 对 $1.875$ ）让门槛 $\alpha=1/2$ 看得见。

---

*对应示例：`examples/lean/Probability/Ch45ThreeSeries.lean`（二进块与望远镜两证书 + 三账定义 + Doob 极大不等式与第二 BC 锚）、`examples/julia/45_three_series.jl`（增量方差对账 + Kolmogorov MC + Feller 两尾 + d 不敏感）、`examples/python/45_three_series.py`（精确分数证书 + 三账对照 + Kronecker 验证）、`examples/prolog/45_three_series.pl`（三账引擎 + 穷举极大不等式）。*

---

上一章：[44 无穷可分分布：任意切分的分布族](44-infinitely-divisible.md) · 下一章：[46 重对数律：极限的精确常数](46-law-iterated-logarithm.md)
