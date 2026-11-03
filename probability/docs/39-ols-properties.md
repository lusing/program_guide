# 第 39 章 拟合优度、模型选择与 Gauss–Markov

## 39.1 拟合优度想度量什么

第 38 章解决了“如何计算 \(\hat\beta\)”。

应用者接着要问两个更深的问题：

1. 这条回归线把 \(y\) 的变异解释了多少？
2. 在所有可用的估计量中，OLS 凭什么说是好的？

第一个问题通向平方和分解与 \(R^2\)，以及为什么“样本内拟合更好”不等于“模型更好”。

第二个问题通向 Gauss–Markov 定理：在线性无偏估计类内、在球形扰动下，OLS 方差最小。

两条线索都需要第 38 章的投影代数，且都不需要正态性。

## 39.2 平方和分解的推导

设模型含常数项（\(X\) 第一列为全 1 向量 \(\mathbf 1\)）。

定义三个平方和：

\[
\mathrm{TSS}=\sum_t(Y_t-\bar Y)^2=\|y-\bar Y\mathbf 1\|^2
\quad\text{（总平方和）},
\]

\[
\mathrm{ESS}=\sum_t(\hat Y_t-\bar Y)^2=\|\hat y-\bar Y\mathbf 1\|^2
\quad\text{（解释平方和）},
\]

\[
\mathrm{RSS}=\sum_te_t^2=\|e\|^2
\quad\text{（残差平方和）}.
\]

**分解定理。** \(\mathrm{TSS}=\mathrm{ESS}+\mathrm{RSS}\)。

**证明。** 拆

\[
y-\bar Y\mathbf 1=(\hat y-\bar Y\mathbf 1)+e.
\]

取范数平方后交叉项为 \((\hat y-\bar Y\mathbf 1)'e=\hat y'e-\bar Y\mathbf 1'e\)。

第 38 章已证 \(\hat y'e=0\)；而 \(\mathbf 1'e=0\) 正是 \(X'e=0\) 的第一行——**常数列在这里不可缺席**。

交叉项为零，分解成立。证毕。

含常数项时 \(\bar Y\mathbf 1\) 恰是“只用均值预测”的拟合，故 TSS 也可以读作常数模型的 RSS。

\(R^2\) 因此度量的是相对均值基线的改进。

### 没有常数项时的警告

若回归不含常数列，\(\mathbf 1'e=0\) 不再免费成立，分解失效。

此时直接使用 \(1-\mathrm{RSS}/\mathrm{TSS}\) 可能得到负的或大于 1 的“\(R^2\)”。

两种诚实做法：改用非中心化版本 \(\mathrm{RSS}/\|y\|^2\) 并明确标注口径，或者不报告 \(R^2\) 而报告 RSS 本身。

软件默认行为各异，比较不同模型前必须先统一口径。

## 39.3 R² 的性质

定义

\[
\boxed{
R^2=\frac{\mathrm{ESS}}{\mathrm{TSS}}=1-\frac{\mathrm{RSS}}{\mathrm{TSS}}.
}
\]

由分解定理，含常数项时 \(0\le R^2\le1\)。

三种读法：

- 拟合优度：变异被解释的比例；
- 相关性：\(R^2\) 等于 \(y\) 与 \(\hat y\) 的样本相关系数的平方（含常数项时）；
- 改进率：相对均值预测的 RSS 下降比例。

第三种读法最有用，因为它直接连接模型选择。

注意 \(R^2\) 没有天然的时间维度与因果含义。

高 \(R^2\) 可以来自伪回归（两个趋势序列），低 \(R^2\) 也可以伴随非常好的预测（金融收益率预测）。

## 39.4 嵌套模型：加变量 R² 必不降

设 \(X_2\) 的列是 \(X_1\) 列的子集（嵌套），则

\[
\operatorname{col}(X_1)\subseteq\operatorname{col}(X_2).
\]

投影到更大子空间只会更近：

\[
\mathrm{RSS}_2\le\mathrm{RSS}_1.
\]

TSS 与模型无关，故

\[
\boxed{R_2^2\ge R_1^2.}
\]

这是纯几何事实，与新增变量是否有用无关——即使加入一列纯噪声，样本内 \(R^2\) 也不降。

于是 \(R^2\) 不能直接用于变量选择。

本章机器单元用一个 8 点设计演示：加入一列与数据生成无关的随机列 \(z\) 后，RSS 从 4.8419 降到 4.6528，\(R^2\) 从 0.7941 升到 0.8022。

方向由代数保证，幅度由这列噪声与 \(y\) 的偶然相关决定。

## 39.5 调整 R²：自由度惩罚

\(R^2\) 的缺陷源于它不为新参数付代价。

调整 \(R^2\) 把每消耗一个自由度计入：

\[
\boxed{
\bar R^2=1-\frac{\mathrm{RSS}/(n-k)}{\mathrm{TSS}/(n-1)}.
}
\]

分母换成了各自的自由度均值。

与 \(R^2\) 不同，\(\bar R^2\) 可以下降，也可以为负（模型比均值还差时）。

### |t| > 1 判据

加入一个变量时 \(\bar R^2\) 上升，当且仅当该变量系数的 \(t\) 统计量绝对值大于 1。

推导：记小模型残差自由度 \(n-k\)、大模型 \(n-k-1\)，\(\bar R^2\) 上升等价于

\[
\frac{\mathrm{RSS}_2}{n-k-1}<\frac{\mathrm{RSS}_1}{n-k}
\iff
\frac{\mathrm{RSS}_1-\mathrm{RSS}_2}{\mathrm{RSS}_2/(n-k-1)}=\ t^2>1.
\]

这解释了机器单元的两个方向：Python 的随机列 \(t^2\approx0.20\)，\(\bar R^2\) 从 0.7598 降到 0.723；Julia 的随机列恰与 \(y\) 相关较强，\(t^2\approx4.15\)，\(\bar R^2\) 反而从 0.7549 升到 0.8392。

两列噪声在数据生成意义上同样“无关”，但样本内表现由实现值决定——这正是样本内准则的不可靠之处。

## 39.6 信息准则一瞥

预测导向的模型选择常用信息准则：

\[
\mathrm{AIC}=n\log\frac{\mathrm{RSS}}n+2k,
\qquad
\mathrm{BIC}=n\log\frac{\mathrm{RSS}}n+k\log n,
\]

取最小者。

两者都以对数似然为底、以参数个数罚项为校正，目标都是预测或 KL 意义下的近似质量，而非“找到真模型”。

BIC 的罚项随 \(n\) 增长，倾向选更简模型且有一致性；AIC 罚项固定，倾向选偏大模型但对预测渐近有效。

它们与 \(\bar R^2\) 的差别在于罚项来自理论推导而非自由度直觉。

深入的讨论属于模型选择专题；本章记住：**样本内 RSS 单调下降是几何事实，任何可用的选择准则都必须为此付费。**

## 39.7 样本内拟合与样本外预测

把同一数据既用于估计又用于评估，拟合优度必然随复杂度上升——过拟合。

评估预测能力应使用未参与估计的数据（留出集、交叉验证），或对样本内指标施加理论惩罚（上述准则）。

一句话总结分层：

- RSS/\(R^2\)：样本内，几何上随加变量单调改进；
- \(\bar R^2\)：样本内 + 自由度罚；
- AIC/BIC：似然 + 理论罚，预测导向；
- 留出集误差：样本外，预测的直接证据。

## 39.8 OLS 的无偏性：外生性怎么用

现在转入统计性质。

把第 38 章的解代入模型：

\[
\hat\beta=(X'X)^{-1}X'(X\beta+\varepsilon)
=\beta+(X'X)^{-1}X'\varepsilon.
\]

在 A2、A3 下取条件期望：

\[
E(\hat\beta|X)=\beta+(X'X)^{-1}X'E(\varepsilon|X)=\beta.
\]

两行就完成证明——**无偏性的全部代价是外生性**。

不需要同方差，不需要正态，不需要独立样本。

反过来，内生性下

\[
E(\hat\beta|X)=\beta+(X'X)^{-1}X'E(\varepsilon|X)\ne\beta,
\]

偏差项是可计算的；第 38.16 节的 \(2+1/2=2.5\) 是其一元版本。

无条件期望由重期望公式得到：

\[
E(\hat\beta)=E[E(\hat\beta|X)]=\beta.
\]

## 39.9 协方差矩阵：球形扰动怎么用

由 \(\hat\beta-\beta=(X'X)^{-1}X'\varepsilon\)，固定 \(X\) 并用 A4：

\[
\operatorname{Var}(\hat\beta|X)
=(X'X)^{-1}X'\,\sigma^2I_n\,X(X'X)^{-1}
=\sigma^2(X'X)^{-1}.
\boxed{
\operatorname{Var}(\hat\beta|X)=\sigma^2(X'X)^{-1}.
}
\]

分解到单个系数：

\[
\operatorname{Var}(\hat\beta_j|X)=\sigma^2[(X'X)^{-1}]_{jj}
=\frac{\sigma^2}{(1-R_j^2)\sum_t(X_{t,j}-\bar X_j)^2},
\]

其中 \(R_j^2\) 是第 \(j\) 个解释变量对其余变量回归的 \(R^2\)（方差膨胀因子的来源，第 41 章展开）。

若 A4 破坏（异方差或序列相关），此式不再成立，须换稳健或 GLS 口径（第 35、41 章）。

三点例的账（把第 38 章的 \((X'X)^{-1}\) 代入）：

\[
\operatorname{Var}(\hat\beta_1|X)=\sigma^2\cdot\frac56,
\qquad
\operatorname{Var}(\hat\beta_2|X)=\sigma^2\cdot\frac3 6=\frac{\sigma^2}{2}.
\]

## 39.10 s² 的无偏性：迹账

\(\sigma^2\) 未知，用残差估计。

定义

\[
\boxed{s^2=\frac{e'e}{n-k}=\frac{\mathrm{RSS}}{n-k}.}
\]

分母为什么是 \(n-k\) 而不是 \(n\)？迹账给出答案。

由 \(MX=0\)（第 38 章 \(PX=X\) 的对偶）：

\[
e=My=M(X\beta+\varepsilon)=M\varepsilon,
\qquad
e'e=\varepsilon'M\varepsilon.
\]

对固定对称矩阵 \(A\)，\(E(\varepsilon'A\varepsilon|X)=\sigma^2\operatorname{tr}(A)\)（用 \(E(\varepsilon\varepsilon'|X)=\sigma^2I\) 与迹的轮换性）。

于是

\[
E(e'e|X)=\sigma^2\operatorname{tr}(M)=\sigma^2(n-k),
\]

\[
\boxed{E(s^2|X)=\sigma^2.}
\]

第 38 章的 \(\operatorname{tr}(M)=n-k\) 在这里从代数身份变成统计内容：**\(n-k\) 正是数据里剩下的独立信息量**——\(k\) 个参数的估计已经消耗了 \(k\) 个自由度。

直观对应：残差满足 \(X'e=0\) 的 \(k\) 个线性约束。

## 39.11 Gauss–Markov 定理：陈述

**定理。** 在 A1–A4 下，对任意固定向量 \(c\in\mathbb R^k\)，在所有满足无偏性的线性估计量

\[
c'\tilde\beta=a'y
\]

中，OLS 泛函 \(c'\hat\beta=c'(X'X)^{-1}X'y\) 的条件方差最小：

\[
\operatorname{Var}(c'\hat\beta|X)\le\operatorname{Var}(c'\tilde\beta|X).
\]

“线性”指估计量是 \(y\) 的线性函数（系数可依赖 \(X\)）；“无偏”对一切 \(\beta\) 成立。

取 \(c\) 为单位向量，结论覆盖每个系数。

BLUE（Best Linear Unbiased Estimator）即由此得名。

注意定理不需要 A5：正态性与之无关。

## 39.12 Gauss–Markov 定理：完整证明

**第一步：无偏性的矩阵刻画。**

\(E(c'\tilde\beta|X)=a'E(y|X)=a'X\beta\)。

对一切 \(\beta\) 无偏当且仅当

\[
a'X=c'.
\]

OLS 对应 \(a_0=X(X'X)^{-1}c\)，验证 \(a_0'X=c'(X'X)^{-1}X'X=c'\)。✓

**第二步：分解竞争者。**

令 \(d=a-a_0\)，则 \(d'X=0\)，且 \(a=a_0+d\)。

**第三步：方差展开。**

\[
\operatorname{Var}(a'y|X)=\sigma^2a'a
=\sigma^2(a_0'a_0+2a_0'd+d'd).
\]

交叉项

\[
a_0'd=c'(X'X)^{-1}X'd=c'(X'X)^{-1}(X'd)=0.
\]

故

\[
\operatorname{Var}(c'\tilde\beta|X)
=\sigma^2a_0'a_0+\sigma^2d'd
=\operatorname{Var}(c'\hat\beta|X)+\sigma^2\|d\|^2.
\]

**第四步：结论。**

\(\|d\|^2\ge0\) 给出不等式；等号当且仅当 \(d=0\)，即竞争者与 OLS 相同。证毕。

证明只用了三件事：无偏刻画 \(a'X=c'\)、球形方差 \(\sigma^2I\)、平方和的非负性。

第 39.9 节的 \(a_0'a_0=c'(X'X)^{-1}c\) 与方差公式一致，自洽。

几何读法：估计 \(c'\beta\) 只需要 \(y\) 在一个特定方向上的信息；OLS 恰好只取该方向的分量，任何无偏竞争者都额外混入了纯噪声方向 \(\operatorname{col}(X)^\perp\) 中的分量。

## 39.13 等号条件与 BLUE 的边界

等号 \(\operatorname{Var}(c'\tilde\beta|X)=\operatorname{Var}(c'\hat\beta|X)\) 当且仅当 \(d=0\)。

即：在线性无偏类内，达到 OLS 方差的估计量就是 OLS 自身。

这把“最优”钉死在类边界上——类外的情况完全不同：

- 有偏估计量（岭回归、预检估计量）方差可以更小，MSE 也可能更小；
- 非线性估计量（第 31 章 LAD、M 估计）在厚尾误差下可能优于 OLS；
- A4 破坏时，GLS（第 41 章）优于 OLS——OLS 仍是线性无偏，但不再是“B”。

Gauss–Markov 的正确读法是**条件性陈述**：在给定类与给定扰动结构内，OLS 无法被超越。

## 39.14 三点例的方差账与对照估计

沿用第 38 章 \(x=0,1,2\) 的设计，取 \(\sigma^2=1\)。

OLS 斜率方差：

\[
\operatorname{Var}(\hat\beta_2|X)=\sigma^2(X'X)^{-1}_{22}=\frac12.
\]

竞争者利用该设计的巧合 \(\hat\beta_2=(Y_3-Y_1)/2\)，考虑只用两个观测的估计量

\[
\tilde\beta_2=Y_2-Y_1.
\]

无偏性：\(E(Y_2-Y_1)=(\beta_1+\beta_2)-\beta_1=\beta_2\)。✓

线性性显然。

方差：

\[
\operatorname{Var}(Y_2-Y_1)=\sigma^2+\sigma^2=2.
\]

对照：

\[
2=4\times\frac12,
\]

竞争者方差是 OLS 的四倍——Gauss–Markov 不等式的具体现场。

它丢弃了 \(Y_3\) 的信息却仍要为两个观测的噪声付费，而 OLS 以最优权重 \(\frac16(-3,0,3)\) 用满全部三个观测。

## 39.15 Python：分解账与 Monte Carlo

文件 `examples/python/39_ols_properties.py` 先把三点例的拟合优度账全部精确化：

```python
TSS = sum((t - ybar) ** 2 for t in y)
ESS = sum((f - ybar) ** 2 for f in fitted)
RSS = sum(e * e for e in resid)
assert (TSS, ESS, RSS) == (F(14, 3), F(9, 2), F(1, 6))
assert TSS == ESS + RSS
assert ESS / TSS == F(27, 28)
adj = 1 - (RSS / (3 - 2)) / (TSS / (3 - 1))
assert adj == F(13, 14)
```

数值读法：

| 量 | 精确值 | 十进制 |
|---|---:|---:|
| TSS | \(14/3\) | 4.6667 |
| ESS | \(9/2\) | 4.5 |
| RSS | \(1/6\) | 0.1667 |
| \(R^2\) | \(27/28\) | 0.9643 |
| \(\bar R^2\) | \(13/14\) | 0.9286 |
| \(s^2\) | \(1/6\) | 0.1667 |

嵌套模型部分复现第 39.4–39.5 节的演示：

```python
X3 = np.column_stack([np.ones(n), xd, z])
rss2, rss3 = ols_rss(X2), ols_rss(X3)
assert rss3 <= rss2 + 1e-12
assert r2_3 >= r2_2 - 1e-12
```

输出：

```
nested fit: RSS 4.8419 -> 4.6528 ; R2 0.7941 -> 0.8022 ; adj 0.7598 -> 0.723
```

Gauss–Markov 与 \(s^2\) 的 Monte Carlo 用同一三点设计、\(\sigma^2=1\)、20,000 次重复：

```python
B = Eps @ Xf @ XtXi
slope = B[:, 1]
simple = Eps[:, 1] - Eps[:, 0]
assert np.allclose(slope, (Eps[:, 2] - Eps[:, 0]) / 2)
assert abs(slope.var(ddof=1) - 0.5) < 0.02
assert abs(simple.var(ddof=1) - 2.0) < 0.08
s2_all = (resid_mat ** 2).sum(axis=1) / (3 - 2)
assert abs(s2_all.mean() - 1.0) < 0.05
```

`allclose` 一行同时验证了矩阵公式与 \((Y_3-Y_1)/2\) 巧合的等价。

结果：

```
Gauss-Markov MC: var(beta2) = 0.499 vs var(y2-y1) = 2.0078 ; mean s2 = 0.9974
```

经验方差 0.499 贴住理论 1/2，竞争者 2.0078 贴住 2，\(s^2\) 均值 0.9974 贴住 1。

## 39.16 Julia：独立通道的相同结论

`examples/julia/39_ols_properties.jl` 用有理数复算分解账：

```julia
@assert (TSS, ESS, RSS) == (14 // 3, 9 // 2, 1 // 6)
@assert TSS == ESS + RSS
@assert ESS / TSS == 27 // 28
adj = 1 - (RSS / (3 - 2)) / (TSS / (3 - 1))
@assert adj == 13 // 14
```

嵌套模型的随机列与 Python 不同源，结果方向也不同：

```
nested fit: RSS 4.0329 -> 2.2051 ; R2 0.7899 -> 0.8851 ; adj 0.7549 -> 0.8392
```

RSS 依然下降、\(R^2\) 依然上升（几何必然），而这列噪声恰与 \(y\) 相关较强（\(|t|>1\)），调整 \(R^2\) 也上升。

两个方向合起来正好演示第 39.5 节的判据：加无关变量后 \(\bar R^2\) 升降皆有可能，分界在 \(|t|=1\)。

Monte Carlo 部分把循环封装为函数（Julia 顶层循环的作用域纪律），断言与 Python 相同：

```julia
@assert abs(var(slopes, corrected=true) - 0.5) < 0.02
@assert abs(var(simples, corrected=true) - 2.0) < 0.08
@assert abs(mean(s2s) - 1.0) < 0.05
```

结果 `var(beta2) = 0.4993 vs var(y2-y1) = 1.9935; mean s2 = 0.991`。

两通道随机数实现不同，结论在容差内一致。

## 39.17 Lean：分解与方差差的锚

`examples/lean/Probability/Ch39OLSProperties.lean` 用 `norm_num` 判决分解与所有拟合账：

```lean
example : ((1 - 7 / 3) ^ 2 + (2 - 7 / 3) ^ 2 + (4 - 7 / 3) ^ 2 : ℚ)
    = (5 / 6 - 7 / 3) ^ 2 + (7 / 3 - 7 / 3) ^ 2 + (23 / 6 - 7 / 3) ^ 2
      + (1 / 6) ^ 2 + (-1 / 3) ^ 2 + (1 / 6) ^ 2 := by norm_num

example : ((9 : ℚ) / 2) / (14 / 3) = 27 / 28 := by norm_num
example : (1 : ℚ) - ((1 / 6) / (3 - 2)) / ((14 / 3) / (3 - 1)) = 13 / 14 := by
  norm_num
```

第一个例子把 TSS 写成三点的中心化平方和、把 ESS 与 RSS 的六项全部展开——分解定理在该数据上的实例由 kernel 逐项核对。

Gauss–Markov 的核心形状被抽象为一般定理：

```lean
theorem gm_gap_nonneg (sigma : ℚ) (v : Fin 3 → ℚ) :
    0 ≤ sigma ^ 2 * (v ⬝ᵥ v) := by
  have h0 : 0 ≤ v ⬝ᵥ v := by
    simp only [dotProduct]
    exact Finset.sum_nonneg fun i _ => mul_self_nonneg (v i)
  exact mul_nonneg (sq_nonneg sigma) h0
```

它对应证明第四步：方差差 \(\sigma^2\|d\|^2\) 是两个非负量之积。

内层先把点积展开为逐项平方和（mathlib 4.33 中 `dotProduct` 已移出 `Matrix` 命名空间，记号 `⬝ᵥ` 不变），每一项 \(v_i^2\ge0\)，求和保持非负；外层是平方与正数的乘积。

数值对照 `1/2 < 2` 同样由 `norm_num` 判决。

迹账 \((3:\mathbb Q)-2=1\) 把 \(n-k\) 的自由度身份钉在固定例上。

## 39.18 常见误区

### 误区一：R² 高说明模型设定正确

\(R^2\) 只度量样本内拟合；伪回归、遗漏变量都可以有高 \(R^2\)。

### 误区二：调整 R² 总是比 R² 小

含常数项时通常更小，但加入强相关变量后可以上升，且 \(\bar R^2\) 本身可为负。

### 误区三：无常数回归也能用同一个 R²

分解依赖 \(\mathbf 1'e=0\)；去常数列后公式口径必须重选。

### 误区四：s² 分母用 n 更“有效”

\(n\) 分母给出 \(\frac{n-k}{n}\sigma^2\) 的有偏估计；无偏性的代价恰是 \(n-k\)。

### 误区五：Gauss–Markov 说 OLS 一切最优

只在线性无偏类内、A3+A4 下成立；类外或扰动非球时有更好选择。

### 误区六：无偏与最小方差可以分别削弱假设

无偏性用 A3，方差公式与 BLUE 用 A3+A4；各结论各付各的账。

### 误区七：模拟方差接近理论值证明定理

模拟审计固定设计；定理对所有满足假设的设计成立，证明在推导里。

## 39.19 本章要点

1. 含常数项时 \(\mathrm{TSS}=\mathrm{ESS}+\mathrm{RSS}\)，交叉项为零用到 \(\hat y'e=0\) 与 \(\mathbf 1'e=0\)。
2. \(R^2=1-\mathrm{RSS}/\mathrm{TSS}\in[0,1]\)；嵌套加变量必不降——纯几何，与变量价值无关。
3. 调整 \(R^2\) 换成自由度均值；加单变量时上升当且仅当 \(|t|>1\)。
4. AIC/BIC 以似然加罚项服务预测目标；样本内准则都须为复杂度付费。
5. \(E(\hat\beta|X)=\beta\) 只需外生性；\(\operatorname{Var}(\hat\beta|X)=\sigma^2(X'X)^{-1}\) 需再加球形扰动。
6. \(E(s^2|X)=\sigma^2\) 的证明是迹账：\(e=M\varepsilon\)，\(E(\varepsilon'M\varepsilon)=\sigma^2\operatorname{tr}(M)=\sigma^2(n-k)\)。
7. Gauss–Markov：无偏刻画 \(a'X=c'\)，交叉项 \(a_0'd=0\)，方差差 \(\sigma^2\|d\|^2\ge0\)；不需要正态。
8. 三点例完整账：\(R^2=27/28\)，\(\bar R^2=13/14\)，\(s^2=1/6\)，OLS 斜率方差 \(\sigma^2/2\) 对竞争者的 \(2\sigma^2\)。

---

上一章：[38 经典线性回归与普通最小二乘](38-ols.md) · 返回[教程目录](../README.md)
