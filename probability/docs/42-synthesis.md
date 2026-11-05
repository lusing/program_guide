# 第 42 章 综合案例与概率证明方法

## 42.1 收官案例：一条合成数据的全程

前四十一章各自修好了一件兵器：公理与计数（第 1 篇）、分布族（第 2–3 篇）、多元与抽样（第 4–5 篇）、极限定理（第 6–7 篇）、估计与检验（第 8–9 篇）、回归（第 10 篇）。

本章用一个完整的合成劳动力市场把它们串成一次实战：从数据生成过程出发，经描述统计、遗漏变量的回归、极大似然与模型选择、内生性与工具变量，到异方差下的加权最小二乘。

**全部生成参数公开**——这既是模拟实验的诚实性要求，也让每一个估计量都有精确的理论值可以对账。

随后本章完成第二件事：把全书用过的证明方法收进一张地图（反例、归纳、变换、生成函数、渐近展开、机器审计），并复盘两个校准直觉的名题。

## 42.2 数据生成过程与总体账

**DGP（全部公开）。**
四个相互独立的标准正态源 $A,D,U,\varepsilon'$ ，$\varepsilon=\tfrac12\varepsilon'$ ：

$$\boxed{ \begin{aligned} \text{能力 }&A\sim N(0,1),\\ \text{教育 }&E=10+2A+1.0\,D+U,\\ \text{对数工资 }&W=4.6+0.1\,E+0.3\,A+\varepsilon, \qquad \varepsilon\sim N(0,\tfrac14). \end{aligned}}$$

读法：能力既直接提高工资（系数 0.3），又推高教育（系数 2）；学校距离 $D$ 只影响教育（系数 1），不影响工资——这是工具变量的原型。

**总体量（精确分数）。**

$$\operatorname{Var}(E)=4+1+1=6, \qquad \operatorname{Cov}(E,A)=2, \qquad \operatorname{Cov}(D,E)=1, \qquad \operatorname{Cov}(D,W)=0.1.$$

三个关键估计量的总体身份，全部可写成精确分数：

**（1）短回归（遗漏能力）的概率极限。**
由第 41 章偏误公式：

$$\operatorname{plim}\hat\beta_E^{\text{短}} =0.1+0.3\cdot\frac{\operatorname{Cov}(E,A)}{\operatorname{Var}(E)} =0.1+0.3\cdot\frac{2}{6} =\frac1{10}+\frac1{10} =\boxed{\frac15}.$$

教育回报被高估一倍——0.2 里有一半是能力的功劳。

**（2）工具变量估计量的识别。**
恰好识别的 IV（第 38/41 章的矩条件 $E[D(W-\beta_1-\beta_2E)]=0$ ）：

$$\beta_{IV}=\frac{\operatorname{Cov}(D,W)}{\operatorname{Cov}(D,E)} =\frac{0.1}{1} =\boxed{\frac1{10}}.$$

距离只通过教育影响工资，于是"距离造成的工资差异 ÷ 距离造成的教育差异"恰好剥离了能力的污染。

**（3）长回归无偏。**
正确设定的 OLS/MLE 均值就是 $(4.6,\ 0.1,\ 0.3)$ 。

三行分数是本章全部模拟的对账基准。

## 42.3 一次抽样：描述统计与四种估计

固定种子生成 $n=500$ 的单样本（第 38 章的固定设计精神，只是设计也随机）。

样本矩贴住总体：$\bar E\approx10$ 、$\hat{\operatorname{Var}}(E)\approx6$ ；工资均值满足线性性账 $E[\bar W]=4.6+0.1\,E[\bar E]+0.3\,E[\bar A]$ （注意是**均值层面**的等式——单样本里 $\bar\varepsilon\ne0$ ，差值容差按 $\sigma/\sqrt n\approx0.022$ 放宽到 0.1）。

四种估计同台（Python 种子 42 / Julia 种子 42，随机数实现不同故数值略异）：

| 估计量 | Python | Julia | 总体目标 |
|---|---:|---:|---:|
| 短回归斜率 | 0.1812 | 0.2032 | 0.2（偏） |
| 长回归 $\hat\beta_E$ | 0.0789 | 0.0919 | 0.1 |
| 长回归 $\hat\beta_A$ | 0.3178 | 0.3187 | 0.3 |
| IV | 0.0622 | 0.0612 | 0.1 |

一次抽样自带的噪声 $\approx0.02$ 量级，四条线各就各位。

长模型的 t 检验（第 40 章）：

$$t_{\text{educ}}\approx5.0,\qquad t_{\text{ability}}\approx7.9,$$

教育与能力都高度显著——$n=500$ 足以让 0.1 的系数从 $0.5/\sqrt{1000}\approx0.016$ 的标准误里站起来。

## 42.4 Monte Carlo：三个估计量的概率极限

4,000 次重复、每次 $n=500$ （Python 向量化、Julia 循环封装）：

| 估计量 | 理论 plim | Python 均值 | Julia 均值 |
|---|---:|---:|---:|
| 短回归 | 0.2 | 0.2000 | 0.1999 |
| 长回归 | 0.1 | 0.1001 | 0.0999 |
| IV | 0.1 | 0.0992 | 0.0987 |

三个估计量各奔自己的概率极限，误差在 $10^{-3}$ 量级——与重复次数的 $1/\sqrt{4000}$ 法则一致。

更细的一层账是**偏差—方差权衡的现场**：

$$\operatorname{Var}(\hat\beta^{\text{短}})\approx9\times10^{-5} < \operatorname{Var}(\hat\beta_E^{\text{长}})\approx2.5\times10^{-4},$$

短回归确实更"稳"（它把能力塞进残差，斜率的条件方差更小）；但围绕真值的均方误差

$$\mathrm{MSE}^{\text{短}}\approx0.0101 \gg \mathrm{MSE}^{\text{长}}\approx2.5\times10^{-4}$$

偏误 $0.1^2=0.01$ 主宰一切——**稳定的有偏估计毫无用处**，这是第 41 章遗漏变量理论的频率版铁证。

（实现细节：长模型斜率用 Frisch–Waugh 残差化——先把 $E$ 对 $(1,A)$ 回归取残差，再用它回归 $W$ ；机器实现里这是唯一无需显式构造 $3\times3$ 矩阵的路线。）

## 42.5 极大似然、AIC 与 BIC

正态线性模型里 MLE 与 OLS 是同一个数（第 32 章）。

机器单元不重复解优化，而是**验证峰**：在长模型 OLS 解附近扰动斜率 $\pm0.01,\pm0.02$ ，对数似然逐点更低——

```python
ll_hat = loglik(X_long, W0, b_long)
for delta in (0.01, -0.01, 0.02):
    pert = b_long.copy()
    pert[1] += delta
    assert ll_hat > loglik(X_long, W0, pert)
```

模型比较（第 39 章）用同一次抽样：

$$\mathrm{AIC}^{\text{长}}=730.6<\mathrm{AIC}^{\text{短}}=788.5, \qquad \mathrm{BIC}^{\text{长}}=743.2<\mathrm{BIC}^{\text{短}}=796.9.$$

两个准则同向：能力变量值得纳入——这与 t 检验（7.95）的判断一致，但出发点是预测质量而非显著性。

## 42.6 异方差收官：WLS 的理论方差

最后一段数据把第 41 章收口：固定设计 $x=1,\ldots,100$ ，前 50 个观测 $\operatorname{Var}(\varepsilon)=1$ 、后 50 个 $=4$ ，真实斜率 0.5。

理论（$\sigma^2=1$ ）：

$$\operatorname{Var}(\hat\beta^{\text{OLS}}_2)= \left[(X'X)^{-1}X'\Omega X(X'X)^{-1}\right]_{22} =3.0\times10^{-5},$$

$$\operatorname{Var}(\hat\beta^{\text{WLS}}_2)= \left[(X'\Omega^{-1}X)^{-1}\right]_{22} =2.6\times10^{-5}.$$

4,000 次 Monte Carlo：Python 经验方差 $2.9\times10^{-5}$ 对 $2.5\times10^{-5}$ ，Julia $3.0$ 对 $2.6$ ，双双贴住理论、WLS 稳定胜出约 13%。

Aitken 定理从第 41 章的五点小账走到了百点设计——结论没变：**知道方差结构就按方差结构加权**。

## 42.7 Python：全程一条线

`examples/python/42_synthesis.py` 的骨架是"精确账 → 单样本 → MC → WLS"四段，每段自带断言。

精确账全部用 `Fraction`：

```python
bias = F(3, 10) * cov_EA / var_E
assert bias == F(1, 10)
plim_short = F(1, 10) + bias
assert plim_short == F(1, 5)
iv_estimand = F(1, 10) / F(1)
assert iv_estimand == F(1, 10)
```

MC 的长模型斜率走残差化，按行求和必须 `keepdims` 保持广播形状：

```python
def rcol(M):
    return M.sum(axis=1, keepdims=True)


Ea = Ec - Ac * (rcol(Ac * Ec) / rcol(Ac * Ac))
long_slopes = (Ea * Wc).sum(axis=1) / (Ea * Ea).sum(axis=1)
```

MSE 必须围绕**真值**而非样本均值计算——

```python
mse_short = ((short_slopes - 0.1) ** 2).mean()
mse_long = ((long_slopes - 0.1) ** 2).mean()
assert mse_long < mse_short / 10
```

初版误用 `.var()`（围绕自身均值），偏误被悄悄扣掉、比率反向——又一次"断言抓出统计口径错误"的现场。

WLS 的批量求解用行向量约定 $\hat\beta_r'=y_r'X(X'X)^{-1}$ ，避免 `solve` 的核心维度错位：

```python
B_ols = (Yw @ Xw @ np.linalg.inv(Xw.T @ Xw))[:, 1]
B_wls = (Yw @ (Winv @ Xw) @ np.linalg.inv(Xw.T @ Winv @ Xw))[:, 1]
```

## 42.8 Julia：独立复算

`examples/julia/42_synthesis.jl` 用 `MersenneTwister` 独立复现全流程。

总体账直接写有理数：

```julia
@assert 3 // 10 * 2 // 6 == 1 // 10
@assert 1 // 10 + 1 // 10 == 1 // 5
@assert (1 // 10) / 1 == 1 // 10
```

MC 与 WLS 分别封装为 `estimator_audit` 与 `wls_audit`（Julia 顶层循环的作用域纪律），断言与 Python 同构：

```julia
short_s, long_s, iv_s = estimator_audit(4000)
@assert abs(mean(short_s) - 0.2) < 0.01
@assert abs(mean(long_s) - 0.1) < 0.01
@assert abs(mean(iv_s) - 0.1) < 0.01
```

两通道的随机数实现不同，单样本数值自然不同（短回归 0.1812 对 0.2032）；对账的对象是理论值与收敛方向，不是逐位一致。

## 42.9 Lean：总体账与证明方法锚

`examples/lean/Probability/Ch42Synthesis.lean` 先把三行总体分数交给 `norm_num`：

```lean
example : ((3 : ℚ) / 10) * (2 / 6) = 1 / 10 := by norm_num
example : ((1 : ℚ) / 10) + 1 / 10 = 1 / 5 := by norm_num
example : ((1 : ℚ) / 10) / 1 = 1 / 10 := by norm_num
example : ((1 : ℚ) / 10) < 1 / 5 := by norm_num
```

最后一行是"短回归不一致"的代数形态：偏误 $1/10$ 严格小于概率极限 $1/5$ 。

文件其余部分是证明方法章的机器锚（承自旧编号的证明十一式章），归并在下面的方法地图中逐一说明。

## 42.10 证明方法地图：六族策略各自能证明什么

全书用过的证明手法可以收进六族。
每族回答一个不同的问题，**互相不可替代**。

### 一、反例：杀命题

一个反例终结一条命题，是检验定义边界最快的刀。

- 零协方差不独立（$X$ 均匀取 $\{\pm1,\pm2\}$ 、$Y=X^2$ ：$\operatorname{Cov}=0$ 但 $Y$ 完全由 $X$ 决定）——Lean 文件用四点表 `decide` 判决 $E[X]=0$ 、$E[X^3]=0$ 、$\operatorname{Var}(Y)=9/4$ ；
- 均值可以不存在（Cauchy 的路径依赖、$E[1/X]$ 在 0 端爆破）；
- 两两独立不等于相互独立（$\varepsilon_1,\varepsilon_2$ 与"两 bit 相同"）。

**能证明**：某命题为假。**不能证明**：任何肯定性结论。

### 二、归纳与递推：序列上的一致性

基底 + 归纳步覆盖全体自然数。

- $\sum k=\frac{n(n+1)}2$ 、$\sum k^2$ 、Nicomachus 立方和——Lean 文件三个 `norm_num [Finset.sum_range_succ]` 实例；
- 容斥公式的归纳证明（第 06 章）；差分方程与 Markov 链的递推本质（第 24 章）。

警示：假归纳（"所有马同色"）断在 $n=1$ 的空集边界——**检查小基底**。

### 三、变换与重写：加零、乘一、配方

不改变对象，只改变写法，直到结构现身。

- 方差分解 $(x-\mu)=(x-\bar x)+(\bar x-\mu)$ 的平方展开（第 22 章 Helmert 的种子）——Lean 里 `rw [h]; ring` 一行；
- 配方法 $2t^2-6t+9=2(t-\tfrac32)^2+\tfrac92$ （第 34 章完全平方最优性的骨架）；
- 乘一拆项（German Tank 的 $\frac{k}{N+1}\cdot\frac{N+1}{1}$ ）。

### 四、生成函数与一题两算：免费恒等式

用两种方法算同一个量，差就是恒等式。

- Vandermonde 的分组故事（第 06 章）——Lean 的玩具例 $1\cdot1+3\cdot2+3\cdot1=\binom52$ 两路会师；
- $\sum k\binom nk=n2^{n-1}$ （对每个子集数主席）；
- 母函数把计数变成系数读取（第 15 章）、特征函数把卷积变成乘法（第 28 章）。

### 五、渐近展开与不等式：从精确到近似要带账

Stirling、Taylor、Chebyshev/Markov——每一个近似都注明误差阶（第 27–30 章）；不等式链给界（第 11 章）。

**能证明**：极限行为、误差上界。**不能证明**：任何有限样本的精确值。

### 六、机器审计：穷举、模拟与形式判决

- 小宇宙穷举（Prolog 的全枚举、有限样本空间）——反例的批量生产线；
- 固定种子模拟——频率审计理论值，**永不冒充证明**；
- Lean `norm_num`/`native_decide`——把代数恒等式变成 kernel 判决。

本教程四十多批的实测反复证明一件事：**手算滑数是常态，精确断言是审计**——仅本章之前的三批就被机器抓出六处手算错误。

## 42.11 两个名题的复训：校准直觉

（承自旧编号的著名问题章，此处保留其灵魂。）

**秘书问题（最优停止）。**
只能看相对排名、当场拍板。最优策略：前 $k$ 人纯观察，此后录用第一个超过前 $k$ 最佳者。成功概率

$$P(k)=\frac kn\sum_{m=k}^{n-1}\frac1m\approx\frac kn\log\frac nk,$$

对 $x=n/k$ 最大化 $\log x/x$ 得 $x=e$ ：**观察 $n/e\approx37\%$ ，命中概率** $1/e\approx36.8\%$ ，且 $n\to\infty$ 不衰减。条件概率 $k/m$ （最优在 $m+1$ 时赢当且仅当前 $m$ 的最佳落在前 $k$ ）是全部精巧所在——一题两算的典范。

**Monty Hall 与百万门。**
主持人知情且不开车门是隐藏假设；换门 $2/3$ 。极限直觉：$10^6$ 扇门你选一扇（$10^{-6}$ ），主持人开掉 999,998 扇羊——剩下那扇吸收全部剩余概率。**识别本质量（换不换），剥离标签（哪扇门）**，与秘书问题的相对排名同一堂课。

**加倍赌注法必死。**
翻倍下注"稳赚"死于赌桌上限：100 局内出现 5 连黑的概率约 81%（补事件递推 $b_n=\sum b_{n-k}/2^k$ ）——第 24 章的递推与本章第六族机器审计（精确递推 + 分块下界）联手处决了它。

## 42.12 常见误区

### 误区一：合成数据太假没有意义

公开 DGP 的价值恰在"假"：理论值精确已知，估计量的偏差与方差可以逐位对账；真实数据永远给不了这个锚。

### 误区二：IV 天然正确

IV 的代价是换一组更强的假设（外生性 + 相关性）；弱工具（$\operatorname{Cov}(D,E)$ 小）方差爆炸。本例 $\operatorname{Cov}=1$ 是舒适的设定。

### 误区三：AIC/BIC 与 t 检验等价

同向时居多，但目标不同（预测质量 vs 参数显著性）；大样本里 BIC 一致、AIC 偏大（第 39 章）。

### 误区四：机器审计可以替代证明

模拟审计频率、穷举审小宇宙、Lean 判代数——各管一段；渐近定理的证明永远在推导里。

### 误区五：方法清单越全越好

六族策略的价值在于**选对**：证明极限用展开、杀命题用反例、验恒等式用机器——拿错工具是初学者最大的时间黑洞。

## 42.13 本章要点

1. 合成 DGP 公开全部参数：$\operatorname{plim}\hat\beta^{\text{短}}=1/5$ 、$\beta_{IV}=1/10$ 、长回归无偏，三行精确分数是全部模拟的锚。
2. MC 4,000 次三估计量各达其 plim（0.2000/0.1001/0.0992）；短回归方差更小但 MSE 大 40 倍——偏误主导。
3. MLE=OLS 由"峰验证"核对；AIC/BIC 与 t 检验同向支持长模型。
4. WLS 在百点异方差设计上把方差从 $3.0\times10^{-5}$ 压到 $2.6\times10^{-5}$ ，理论与 MC 双确认。
5. 证明方法六族：反例（杀命题）、归纳（序列一致性）、变换重写（加零乘一）、生成函数（一题两算）、渐近展开（带误差账的近似）、机器审计（穷举/模拟/形式判决）——各证其所能，互不替代。
6. 名题复训：秘书 $1/e$ 法则、Monty Hall 百万门极限、加倍赌注必死——识别本质量、校准直觉。

---

上一章：[41 误设、受约束回归与 GLS](41-gls.md) · 下一章：[43 Lindeberg 条件：中心极限定理的充要边界](43-lindeberg.md)
