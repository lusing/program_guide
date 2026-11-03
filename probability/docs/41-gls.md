# 第 41 章 误设、受约束回归与广义最小二乘

## 41.1 本章的三个问题

第 40 章在正态假设下完成了精确推断。

本章回到模型本身，处理三类更贴近实践的问题：

1. 参数满足线性约束时，估计与检验如何利用约束；
2. 解释变量选错（遗漏或多余）时，代价是什么；
3. 扰动不球形（异方差、相关）时，估计量如何改造。

三条线索在固定五点数据上全部给出精确有理数账。

## 41.2 受约束最小二乘的闭式解

在约束 \(R\beta=r\) 下最小化 \(\|y-X\beta\|^2\)。

Lagrange 函数

\[
\mathcal L(\beta,\lambda)=\|y-X\beta\|^2+2\lambda'(R\beta-r)
\]

的一阶条件

\[
-2X'y+2X'X\beta+2R'\lambda=0,\qquad R\beta=r.
\]

无约束解 \(\hat\beta=(X'X)^{-1}X'y\) 已知，把第一式改写为

\[
X'X(\beta-\hat\beta)=-R'\lambda.
\]

左乘 \((X'X)^{-1}\) 再左乘 \(R\)，用 \(R\beta=r\) 解出乘子，代回得

\[
\boxed{
\tilde\beta=\hat\beta-(X'X)^{-1}R'
\left[R(X'X)^{-1}R'\right]^{-1}(R\hat\beta-r).
}
\]

调整量完全由“无约束解违反约束多少”与“参数协方差的几何”决定。

## 41.3 受约束残差恒等式：完整证明

**命题。**
\[
\mathrm{RSS}_R=\mathrm{RSS}_U+(R\hat\beta-r)'
\left[R(X'X)^{-1}R'\right]^{-1}(R\hat\beta-r).
\]

**证明。**
记 \(e=y-X\hat\beta\)，\(\delta=\tilde\beta-\hat\beta\)。受约束残差

\[
y-X\tilde\beta=e-X\delta.
\]

展开范数平方：

\[
\mathrm{RSS}_R=\|e\|^2-2e'X\delta+\delta'X'X\delta.
\]

交叉项 \(e'X\delta=(X'e)'\delta=0\)（第 38 章残差正交）。故

\[
\mathrm{RSS}_R-\mathrm{RSS}_U=\delta'X'X\delta.
\]

代入 41.2 的 \(\delta=-\left(X'X\right)^{-1}R'\left[R(X'X)^{-1}R'\right]^{-1}(R\hat\beta-r)\)：

\[
\delta'X'X\delta=(R\hat\beta-r)'\left[R(X'X)^{-1}R'\right]^{-1}
\left[R(X'X)^{-1}R'\right]^{-1}R(X'X)^{-1}X'X(X'X)^{-1}R'
\left[R(X'X)^{-1}R'\right]^{-1}(R\hat\beta-r),
\]

中间连乘恰好收缩回一个逆。证毕。

这个恒等式把第 40 章 F 的两种算法焊接在一起：

\[
F=\frac{(\mathrm{RSS}_R-\mathrm{RSS}_U)/q}{\mathrm{RSS}_U/(n-k)}.
\]

约束越被数据反对，残差上升越多，F 越大。

## 41.4 五点例：约束 β₂ = 1 的完整账

沿用 \(x=(0,1,2,3,4)\)、\(y=(1,3,2,5,4)\)，取 \(R=(0,1)\)、\(r=1\)。

无约束解 \(\hat\beta=(7/5,4/5)\)，违反约束

\[
R\hat\beta-r=-\frac15.
\]

\[
(X'X)^{-1}R'=\begin{pmatrix}-1/5\\1/10\end{pmatrix},
\qquad
R(X'X)^{-1}R'=\frac1{10}.
\]

代入闭式：

\[
\tilde\beta=\begin{pmatrix}7/5\\4/5\end{pmatrix}
-\begin{pmatrix}-1/5\\1/10\end{pmatrix}\cdot10\cdot\Big(-\frac15\Big)
=\begin{pmatrix}1\\1\end{pmatrix}.
\]

受约束拟合为 \(1+x\)，残差 \((0,1,-1,1,-1)\)：

\[
\mathrm{RSS}_R=4,\qquad
\mathrm{RSS}_R-\mathrm{RSS}_U=4-\frac{18}5=\frac25,
\]

二次型核对：

\[
\frac{(-1/5)^2}{1/10}=\frac{2}{5}\quad\checkmark.
\]

约束 F：

\[
F=\frac{(2/5)/1}{(18/5)/3}=\boxed{\frac13}\approx0.33,
\]

远低于 \(F_{0.95}(1,3)=10.128\)——数据与 \(\beta_2=1\) 高度相容，拒绝它毫无道理。

## 41.5 遗漏变量：偏误公式与方向

真实模型（长模型）

\[
y=X_1\beta_1+X_2\beta_2+\varepsilon,
\qquad
E(\varepsilon|X)=0,
\]

却估计了短模型（只用 \(X_1\)）。

短模型 OLS 为 \(\hat\beta_s=(X_1'X_1)^{-1}X_1'y\)，代入真模型：

\[
E(\hat\beta_s|X)=\beta_1+(X_1'X_1)^{-1}X_1'X_2\,\beta_2.
\]

第二项即**遗漏变量偏误**：

\[
\boxed{
\operatorname{bias}=(X_1'X_1)^{-1}X_1'X_2\,\beta_2.
}
\]

三个因素共同决定偏误：遗漏变量的真实作用 \(\beta_2\)、它与已包含变量的样本相关性 \(X_1'X_2\)、已包含变量的散布 \((X_1'X_1)^{-1}\)。

经典读法是工资回归：遗漏“能力”时，若能力同时正向影响工资并与教育正相关，教育系数被**高估**——偏误符号 \(=\operatorname{sign}(\text{相关性})\times\operatorname{sign}(\beta_2)\)。

### 五点例的偏误账

取遗漏变量 \(z=(0,0,1,1,2)\)，真实 \(\beta_3=2\)：

\[
(X_1'X_1)^{-1}X_1'z=\begin{pmatrix}3/5&-1/5\\-1/5&1/10\end{pmatrix}
\begin{pmatrix}4\\13\end{pmatrix}
=\begin{pmatrix}-1/5\\1/2\end{pmatrix},
\]

\[
\operatorname{bias}=2\begin{pmatrix}-1/5\\1/2\end{pmatrix}
=\begin{pmatrix}-2/5\\1\end{pmatrix}.
\]

短模型斜率的期望是 \(1+1=2\) 而非 1：z 与 x 正相关且 \(\beta_3>0\)，斜率被抬高一整截。

Monte Carlo（50,000 次重复，\(\sigma=1\)）：

- 短模型均值 \((0.5955,\ 2.0005)\)，贴住理论 \((0.6,\ 2)\)；
- 长模型均值 \((0.9996,\ 0.9901,\ 2.0206)\)，贴住 \((1,1,2)\)（长模型无偏，\(\beta_3\) 方差大故波动略明显）。

### 正交的遗漏变量不偏系数

若遗漏变量 \(z^\perp\) 与常数列及 \(x\) 都样本正交（本例取 \((0,1,-2,1,0)\)），则 \(X_1'z^\perp=0\)，偏误为零：短模型系数恰为长模型前两个系数 \((7/5,4/5)\)。

机器单元验证长模型解为 \((7/5,\ 4/5,\ 2/3)\)，第三个系数 \(=\sum z_t y_t/\sum z_t^2=4/6\)。

但“不偏系数”不等于“无代价”：z 携带的信号全部被挤进残差，\(s^2\) 高估 \(\sigma^2\)，标准误随之虚胖。

## 41.6 加入无关变量：无偏但方差膨胀

反过来，把真实系数为零的变量 \(z\) 加进模型：估计仍无偏，但系数方差一般上升。

分块逆的标准结果（Frisch–Waugh 的推论）：长模型中 \(\hat\beta_x\) 的方差

\[
\operatorname{Var}(\hat\beta_x^{\text{长}})=
\sigma^2\left[(X_1'X_1)^{-1}+(X_1'X_1)^{-1}X_1'z\big(M_1z\big)^{-1}z'X_1(X_1'X_1)^{-1}\right],
\]

第二项半正定——**多余变量的代价以方差计价**。

五点例：加入 \(z=(0,0,1,1,2)\)（其真实系数为零）后

\[
[(X'X)^{-1}]_{22}=\frac{14}{15},
\qquad
\text{短模型 }[(X_1'X_1)^{-1}]_{22}=\frac1{10},
\]

方差膨胀

\[
\frac{14/15}{1/10}=\frac{28}{3}\approx9.33
\]

倍——z 与 x 高度相关，等于让 x 的信息被分走一大半。

而正交的无关变量 \((0,1,-2,1,0)\) 不膨胀任何方差：正规方程分块对角，各系数互不干扰。

这解释了实验设计的黄金法则：**正交地安排实验无需付出方差代价；观测数据里的相关变量则是零和博弈。**

结合 41.5：遗漏相关变量牺牲无偏，纳入相关多余变量牺牲效率——变量选择的两个方向都有价格标签。

## 41.7 一般协方差结构：OLS 仍无偏但不再有效

放松 A4：

\[
\operatorname{Cov}(\varepsilon|X)=\sigma^2\Omega,\qquad \Omega\ \text{已知、对称正定}.
\]

OLS 的位置：

\[
E(\hat\beta|X)=\beta+ (X'X)^{-1}X'E(\varepsilon|X)=\beta
\]

——外生性未动，无偏仍在。

但真实方差变成

\[
\operatorname{Var}(\hat\beta|X)=\sigma^2(X'X)^{-1}X'\Omega X(X'X)^{-1},
\]

且 Gauss–Markov 的球形条件失效：OLS 在线性无偏类中不再最小方差（第 39 章证明里 \(a'y\) 的方差 \(\sigma^2a'a\) 这一步不再成立）。

## 41.8 GLS：换一个度量做投影

\(\Omega\) 正定故存在对称可逆的 \(\Omega^{-1/2}\)。变换

\[
y^*=\Omega^{-1/2}y,\qquad X^*=\Omega^{-1/2}X,\qquad \varepsilon^*=\Omega^{-1/2}\varepsilon.
\]

新扰动的协方差

\[
\operatorname{Cov}(\varepsilon^*|X)=\Omega^{-1/2}\sigma^2\Omega\,\Omega^{-1/2}=\sigma^2I.
\]

对变换后模型做 OLS，得到**广义最小二乘**：

\[
\boxed{
\hat\beta_{GLS}=(X'\Omega^{-1}X)^{-1}X'\Omega^{-1}y,
\qquad
\operatorname{Var}(\hat\beta_{GLS}|X)=\sigma^2(X'\Omega^{-1}X)^{-1}.
}
\]

**Aitken 定理。** 外生性 + \(\operatorname{Cov}(\varepsilon|X)=\sigma^2\Omega\) 下，GLS 在线性无偏估计类中方差最小。

证明无需新机器：变换把模型带回球形世界，对 \((y^*,X^*)\) 套用第 39 章的 Gauss–Markov 即可——线性性与无偏性在可逆线性变换下保持。

几何语言：OLS 在欧氏度量下找最近点，GLS 在 \(\Omega^{-1}\) 度量下找最近点。度量由扰动的协方差决定——**用数据的可信度加权**，方差大的观测少说话。

## 41.9 WLS：对角权重的特例

\(\Omega=\operatorname{diag}(w_1,\ldots,w_n)\)（异方差、无自相关）时

\[
\hat\beta_{WLS}=\arg\min_b\sum_t\frac{(y_t-x_t'b)^2}{w_t},
\]

权重 \(1/w_t\) 直接进入目标函数；等价地，把每个观测除以 \(\sqrt{w_t}\)（**常数列也要除**）再做 OLS。

### 五点例的 GLS 全账

取 \(w=(1,1,1,4,4)\)（后两个观测方差是前面的四倍），\(\sigma^2=1\)。

加权正规方程的元素（\(w_t^{-1}=(1,1,1,\tfrac14,\tfrac14)\)）：

\[
X'\Omega^{-1}X=\begin{pmatrix}7/2&19/4\\19/4&45/4\end{pmatrix},
\qquad
X'\Omega^{-1}y=\begin{pmatrix}33/4\\59/4\end{pmatrix}.
\]

行列式

\[
\det=\frac{7}{2}\cdot\frac{45}4-\Big(\frac{19}4\Big)^2=\frac{269}{16}.
\]

解：

\[
\hat\beta_{GLS}=\left(\frac{364}{269},\ \frac{199}{269}\right)\approx(1.353,\ 0.740).
\]

（无约束 OLS 为 \((1.4,0.8)\)：低方差的前三个点把直线拉向自己。）

变换路线核对：\(\sqrt w=(1,1,1,2,2)\)，变换后设计 \(X^*\) 的两列与 \(y^*\) 的正规方程逐元素等于上面的加权方程，OLS 解相同——机器单元以精确分数断言两路一致。

方差对照（\(\sigma^2=1\)）：

\[
\operatorname{Var}(\hat\beta_{OLS,2})=(X'X)^{-1}X'\Omega X(X'X)^{-1}\Big|_{22}
=\frac14=0.25,
\]

其中 \(X'\Omega X=\begin{pmatrix}11&31\\31&105\end{pmatrix}\)；

\[
\operatorname{Var}(\hat\beta_{GLS,2})=\left[(X'\Omega^{-1}X)^{-1}\right]_{22}
=\frac{7/2}{269/16}=\frac{56}{269}\approx0.208.
\]

\[
\frac{56}{269}<\frac14\quad\checkmark
\]

Aitken 的数值现场。

Monte Carlo（20,000 次重复，真值 0）：

| 通道 | 经验方差 OLS | 经验方差 GLS |
|---|---:|---:|
| 理论 | 0.250 | 0.2082 |
| Python | 0.2477 | 0.2071 |
| Julia | 0.2475 | 0.2081 |

两条通道独立贴住理论值，GLS 稳定地省下约 17% 的方差。

## 41.10 Ω 未知：可行 GLS 的一瞥

实践里 \(\Omega\) 几乎从不已知。

可行 GLS（FGLS）用两步：先 OLS 拿残差，再估计 \(\Omega\)（例如对 \(\log e_t^2\) 回归得权重的雏形），最后 WLS。

要点与警示：

- 估计 \(\Omega\) 引入额外的有限样本不确定性，FGLS 的协方差公式是近似的；
- \(\Omega\) 估计严重错误时，FGLS 可以比 OLS 更差——加权错比不加权糟；
- 正确设定下 FGLS 渐近有效，两步之间还可以迭代（不应改变概率极限）。

异方差稳健标准误（第 35、40 章的 sandwich）走的是另一条路：**保留 OLS 估计、只修方差**——牺牲效率换取对方差结构的免疫。两种策略的选择取决于对 \(\Omega\) 的信心。

## 41.11 Python：受约束、偏误与 GLS 的精确实现

`examples/python/41_gls.py` 提供两个可复用的精确工具。

分数高斯消元：

```python
def solve_exact(A, b):
    m = len(A)
    aug = [row[:] + [b[i]] for i, row in enumerate(A)]
    for col in range(m):
        piv = next(r for r in range(col, m) if aug[r][col] != 0)
        ...
    return [aug[i][m] for i in range(m)]
```

正规方程组装：

```python
def normal_solve(Xcols, yv):
    XtX = [[sum(c1 * c2 for c1, c2 in zip(Xcols[i], Xcols[j]))
            for j in range(kk)] for i in range(kk)]
    ...
    return solve_exact(XtX, Xty)
```

受约束账逐项断言：

```python
beta_tilde = [beta_hat[i] - adjust[i] for i in range(2)]
assert beta_tilde == [F(1), F(1)]
assert RSS_R - RSS_U == scalar ** 2 / XtX_inv[1][1] == F(2, 5)
F_stat = ((RSS_R - RSS_U) / 1) / (RSS_U / 3)
assert F_stat == F(1, 3)
```

GLS 一节的三个交叉验证：

```python
beta_trans = normal_solve([c1, c2], y_star)
assert beta_trans == beta_gls                       # 变换 OLS = GLS
assert var_ols == F(1, 4)
assert var_gls == F(56, 269)
```

本章写作中两处手算滑数（\(S_{wx}\)、\(S_{wxy}\)）都是被这些断言当场纠正后重推的——交叉验证的价值不在最后一行绿字，而在它抓住错误的那一次。

## 41.12 Julia：有理数矩阵的同一套账

`examples/julia/41_gls.jl` 用 `Rational{Int}` 矩阵直接解正规方程：

```julia
X3 = reshape([ones5; x .// 1; z2], 5, 3)
beta_long = (X3' * X3) \ (X3' * y)
@assert beta_long == [11 // 15, 37 // 15, -10 // 3]
```

长模型的精确解 \((11/15,\ 37/15,\ -10/3)\) 与 Python 的高斯消元、numpy 的浮点最小二乘三方一致。

正交性检查一行内完成：

```julia
@assert sum(z_orth) == 0 && dot(x .- 2, z_orth) == 0
```

（\(\bar x=2\)，中心化后正交即与 x 正交且与常数正交。）

偏误与 Aitken 的模拟分别封装为 `omission_audit` 与 `aitken_audit`：

```julia
B_short, B_long = omission_audit(50_000)
@assert all(abs.(vec(mean(B_short, dims=1)) .- [0.6, 2.0]) .< 0.02)
```

输出：

```
omitted variable: short mean = [0.6, 2.0002] (theory 0.6, 2)
Aitken MC: var OLS = 0.2475, var GLS = 0.2081
```

## 41.13 Lean：闭式与恒等式的锚

`examples/lean/Probability/Ch41GLS.lean` 判决本章全部代数。

受约束闭式（分量相减）：

```lean
example : (7 : ℚ) / 5 - (-1 / 5) * (-1 / 5) / (1 / 10) = 1 := by norm_num
example : (4 : ℚ) / 5 - (1 / 10) * (-1 / 5) / (1 / 10) = 1 := by norm_num
```

残差恒等式的两端：

```lean
example : (4 : ℚ) - 18 / 5 = 2 / 5 := by norm_num
example : ((4 : ℚ) / 5 - 1) ^ 2 / (1 / 10) = 2 / 5 := by norm_num
```

偏误的三个分量、方差膨胀比、GLS 解与 Aitken 不等式：

```lean
example : ((30 : ℚ) * 4 - 10 * 13) / 50 = -1 / 5 := by norm_num
example : ((14 : ℚ) / 15) / (1 / 10) = 28 / 3 := by norm_num
example : ((45 : ℚ) / 4 * 33 / 4 - 19 / 4 * 59 / 4) /
    ((7 / 2) * (45 / 4) - (19 / 4) ^ 2) = 364 / 269 := by norm_num
example : ((56 : ℚ) / 269) < 1 / 4 := by norm_num
```

一般层面锚定两个恒等式。

WLS 变换的代数内核：

```lean
theorem weighted_square (v y xb : ℚ) :
    v ^ 2 * (y - xb) ^ 2 = (v * (y - xb)) ^ 2 := by
  ring
```

权 \(v^2\)（即 \(1/w\)，\(w\) 为有理平方时）下的加权平方等于缩放 \(v\) 后的普通平方——41.9 节“除以 \(\sqrt w\) 再 OLS”的形式化版本。

加权距离非负：

```lean
theorem weighted_distance_nonneg (w y xb : ℚ) (hw : 0 ≤ w) :
    0 ≤ w * (y - xb) ^ 2 :=
  mul_nonneg hw (sq_nonneg _)
```

GLS 目标函数逐项非负，保证最小化问题良定义。

## 41.14 常见误区

### 误区一：约束总是该施加

受约束估计在约束为真时更有效，为假时**有偏**——约束是押上无偏换效率的赌注，F 检验（如 41.4 的 1/3）是下注前的尽调。

### 误区二：遗漏变量必然造成大偏误

偏误 = 相关性 × \(\beta_2\)；正交的遗漏变量不偏系数（只毁 \(s^2\)）。

### 误区三：加入变量“总是更稳妥”

无偏换来方差膨胀（本例 28/3 倍），预测与解释都要付价。

### 误区四：GLS 永远优于 OLS

前提是 \(\Omega\)（或其估计）正确；错的权重可以让 FGLS 输给 OLS。

### 误区五：WLS 变换只缩放解释变量

常数列同样要除以 \(\sqrt{w_t}\)，否则正规方程对不上。

### 误区六：稳健标准误与 GLS 是同一件事

稳健路线保 OLS 估计、只修推断；GLS 连估计一起改。目标不同，代价不同。

### 误区七：受约束与无约束的 RSS 差可以任意小又可以任意大

下界为零（约束恰好无约束解也满足时），上界由二次型给出——它是 \(R\hat\beta-r\) 的二次函数，恒等式 41.3 就是全部答案。

## 41.15 本章要点

1. 受约束解 \(\tilde\beta=\hat\beta-(X'X)^{-1}R'[R(X'X)^{-1}R']^{-1}(R\hat\beta-r)\)，由 Lagrange 一阶条件直接解出。
2. \(\mathrm{RSS}_R=\mathrm{RSS}_U+\)(约束离距二次型)：证明用 \(e'X=0\) 一步消掉交叉项；它 unify 了 F 的两种算法。
3. 五点例约束 \(\beta_2=1\)：\(\tilde\beta=(1,1)\)、\(\mathrm{RSS}_R=4\)、\(F=1/3\)，约束与数据相容。
4. 遗漏偏误 \((X_1'X_1)^{-1}X_1'X_2\beta_2\)：方向 = 相关性符号 × \(\beta_2\) 符号；正交遗漏不偏系数但污染 \(s^2\)。
5. 无关变量以方差计价：相关时膨胀（本例 28/3 倍），正交时免费。
6. \(\operatorname{Cov}(\varepsilon)=\sigma^2\Omega\) 下 OLS 无偏但失有效；\(\Omega^{-1/2}\) 变换回到球形世界，GLS \((X'\Omega^{-1}X)^{-1}X'\Omega^{-1}y\) 由 Aitken 定理（= 变换模型上的 Gauss–Markov）最优。
7. WLS 是对角特例：目标 \(\sum(y_t-x_t'b)^2/w_t\)，实现上全体列除以 \(\sqrt{w_t}\)。
8. 五点例 GLS 账：\(\hat\beta_{GLS}=(364/269,199/269)\)，方差 \(56/269<1/4\)，MC 双通道贴住理论。

---

上一章：[40 OLS 抽样分布、t 检验与 F 检验](40-ols-inference.md) · 下一章：[42 综合案例与概率证明方法](42-synthesis.md)
