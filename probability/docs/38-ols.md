# 第 38 章 经典线性回归与普通最小二乘

## 38.1 回归问题：用线性模型逼近条件均值

前两章的检验与区间针对单个参数或矩条件。

计量经济学的核心对象往往是一族关系：工资如何依赖教育与经验，消费如何依赖收入。

回归分析把这个一般问题化为参数模型：

$$E(Y|X_1,\ldots,X_{k-1}) \approx \beta_1+\beta_2X_1+\cdots+\beta_kX_{k-1}.$$

本章起把样本写成矩阵形式，研究经典线性回归模型

$$\boxed{ y=X\beta+\varepsilon }$$

的最小二乘估计。

这里 $y\in\mathbb R^n$ 是被解释变量向量，$X\in\mathbb R^{n\times k}$ 是回归矩阵（通常第一列为常数列），$\beta\in\mathbb R^k$ 是待估参数，$\varepsilon$ 是不可观测扰动。

普通最小二乘（OLS）只做一件事：

$$\hat\beta=\arg\min_{b\in\mathbb R^k}\|y-Xb\|^2.$$

它不假设正态，不假设独立，甚至暂时不假设任何分布。

统计性质在假设逐层加入后才出现；代数性质则立刻就有。

这一分层是本章的主线。

## 38.2 数据矩阵与记号

第 $t$ 个观测写作

$$Y_t=\beta_1+\beta_2X_{t1}+\cdots+\beta_kX_{t,k-1}+\varepsilon_t.$$

按行堆叠成矩阵：

$$y=\begin{pmatrix}Y_1\\\vdots\\Y_n\end{pmatrix}, \qquad X=\begin{pmatrix} 1&X_{11}&\cdots&X_{1,k-1}\\ \vdots&\vdots&&\vdots\\ 1&X_{n1}&\cdots&X_{n,k-1} \end{pmatrix}, \qquad \varepsilon=\begin{pmatrix}\varepsilon_1\\\vdots\\\varepsilon_n\end{pmatrix}.$$

约定：

- $n$ 为样本量，$k$ 为参数个数，含常数项；
- $X$ 的列张成子空间记 $\operatorname{col}(X)\subset\mathbb R^n$ ；
- 拟合值向量 $\hat y=X\hat\beta$ ，残差向量 $e=y-\hat y$ ；
- 洪书及多数计量教材用 $X'$ 表示转置，本章沿用。

$X$ 既可以视为固定设计（实验设计），也可以视为随机实现。

这会影响条件期望写在哪一层，但不改变下面的任何代数。

## 38.3 经典假设清单

以下五条假设按加入顺序编号。

**假设 A1（线性于参数）。**
模型为 $y=X\beta+\varepsilon$ ，即 $Y_t$ 是参数的线性函数加扰动。

线性是对参数说的，不是对变量说的。

$\log Y=\beta_1+\beta_2\log X+\varepsilon$ 仍是线性回归；多项式、交互项、虚拟变量也一样，只要把它们当成 $X$ 的列。

**假设 A2（无完全多重共线）。**
$\operatorname{rank}(X)=k$ ，等价于 $X'X$ 可逆。

它保证正规方程有唯一解。

若某列是其他列的精确线性组合，$X'X$ 奇异，参数没有唯一的最小二乘解——尽管拟合值仍唯一（投影到同一个子空间）。

近似共线不违反 A2，但会使 $(X'X)^{-1}$ 的元素很大，方差急剧膨胀，这是第 41 章的话题。

**假设 A3（严格外生性）。**

$$E(\varepsilon|X)=0.$$

解释变量包含了扰动的全部条件均值信息。

它是 OLS 无偏性的来源，也是计量经济学中最常被攻击的假设：遗漏变量、测量误差、联立性都会破坏它。

**假设 A4（球形扰动）。**

$$E(\varepsilon\varepsilon'|X)=\sigma^2I_n.$$

对角线给出同方差 $E(\varepsilon_t^2|X)=\sigma^2$ ，非对角线给出不自相关 $E(\varepsilon_s\varepsilon_t|X)=0$ （$s\ne t$ ）。

它不进入无偏性，但决定协方差矩阵的形状和 Gauss–Markov 最优性。

异方差或序列相关下 OLS 仍无偏，但不再是 BLUE，标准公式也会错。

**假设 A5（正态扰动）。**

$$\varepsilon|X\sim N(0,\sigma^2I_n).$$

正态性用于第 40 章的精确 $t$ 、$F$ 推断，本章与第 39 章完全不需要它。

## 38.4 假设分层：哪些性质用哪条

把假设和结论对应起来，可以避免两类常见错误：把代数恒等式当成“检验通过”，或把需要外生性的结论当成纯计算。

| 结论 | 需要的假设 |
|---|---|
| $\hat\beta$ 存在、拟合值唯一 | A1 |
| $\hat\beta$ 唯一 | A1 + A2 |
| $X'e=0$ 、$P+M=I$ 、勾股分解 | 纯代数，无需任何随机假设 |
| $E(\hat\beta\mid X)=\beta$ | A1 + A2 + A3 |
| $\operatorname{Var}(\hat\beta\mid X)=\sigma^2(X'X)^{-1}$ | A3 + A4 |
| Gauss–Markov（BLUE） | A3 + A4 |
| $\hat\beta$ 与 $s^2$ 独立、精确 $t/F$ | 再加 A5（第 40 章） |

特别要注意第一组：残差正交是构造的直接后果。

任何数据、任何生成机制下，OLS 残差都满足 $X'e=0$ 。

“残差与解释变量不相关”因此不能当作外生性的证据。

第 38.16 节会用数值实验展示：内生性破坏无偏性，但 $X'e=0$ 逐样本成立。

## 38.5 为什么是平方损失：三种度量的对质

最小二乘选择 $\|y-Xb\|^2$ 作为目标，但“最佳拟合”的度量并非唯一。

继承旧章的三种候选（固定斜率 $a=1$ ，数据 $x=0,1,2,3$ ，$y=0.8,1.9,2.95,6.0$ ，残差 $r=(0.8,0.9,0.95,3.0)$ 偏斜）：

**E1：残差之和** $\sum_t(Y_t-aX_t-b)$ 。

它是 $b$ 的线性函数，而且对 $b$ 无下界：把 $b$ 取得足够大，和可以任意负。

也可以精确取零——取 $b=\bar r$ 即可。

符号相消使它完全不能识别截距，作为损失函数失效。

**E2：绝对损失** $\sum_t|Y_t-aX_t-b|$ 。

对固定斜率，最优截距是残差的中位数（这里是最优区间 $[0.9,0.95]$ 内任一点）。

不可微使闭式解与微分工具失效，最优区间甚至不唯一。

**E3：平方损失** $\sum_t(Y_t-aX_t-b)^2$ 。

可微、凸、有唯一解，闭式公式由线性代数给出。

代价是大误差被平方放大：例中残差 3.0 的那个点把 E3 的最优截距（均值 $1.4125$ ）拉离了 E2 的选择。

三种度量给出三个不同的“最佳”——**选度量即选价值观**。

E3 胜出的原因是数学便利与第 40 章将看到的与正态理论的契合，不是因为它是唯一合理的误差观。

## 38.6 几何路线：投影与勾股

把 OLS 问题读成几何问题：在子空间 $\operatorname{col}(X)$ 中找离 $y$ 最近的点。

**断言：** 若 $\hat y=X\hat\beta\in\operatorname{col}(X)$ 满足 $y-\hat y\perp\operatorname{col}(X)$ ，即

$$X'(y-X\hat\beta)=0,$$

则 $\hat y$ 是 $\operatorname{col}(X)$ 中到 $y$ 的最近点。

**证明。** 对任意 $Xb\in\operatorname{col}(X)$ ，拆

$$y-Xb=(y-\hat y)+(\hat y-Xb).$$

第一项与 $\operatorname{col}(X)$ 中每个向量正交，第二项在 $\operatorname{col}(X)$ 中，故两项正交。

勾股定理给出

$$\|y-Xb\|^2=\|y-\hat y\|^2+\|\hat y-Xb\|^2\ge\|y-\hat y\|^2,$$

等号当且仅当 $Xb=\hat y$ 。证毕。

这个证明没有用到导数。

“垂线最短”把存在性、唯一性（拟合值层面）和最优性一并给出。

## 38.7 正规方程路线：微分与展开

同一条结论也可由微分得到。

目标函数

$$S(b)=(y-Xb)'(y-Xb)=y'y-2b'X'y+b'X'Xb$$

是 $b$ 的二次凸函数。

一阶条件

$$\frac{\partial S}{\partial b}=-2X'y+2X'Xb=0$$

给出**正规方程**

$$\boxed{X'X\hat\beta=X'y.}$$

A2 下 $X'X$ 可逆，解为

$$\boxed{\hat\beta=(X'X)^{-1}X'y.}$$

也可用配方法直接写出：

$$S(b)=S(\hat\beta)+(\hat\beta-b)'X'X(\hat\beta-b),$$

展开即验。

右端第二项非负且仅由 $X'X$ 的正定性保证为零当 $b=\hat\beta$ 。

三条路线——投影、微分、配方——是同一个事实的三种语言。

几何路线在概念上最有用：它把 OLS 定位为**正交投影**。

## 38.8 一元回归的闭式：均值与协方差

$k=2$ （常数加一个解释变量）时，记 $\bar x,\bar y$ 为样本均值，

$$S_{xx}=\sum_t(X_t-\bar x)^2,\qquad S_{xy}=\sum_t(X_t-\bar x)(Y_t-\bar y).$$

解正规方程给出教科书公式

$$\boxed{ \hat\beta_2=\frac{S_{xy}}{S_{xx}}, \qquad \hat\beta_1=\bar y-\hat\beta_2\bar x. }$$

斜率是样本协方差与样本方差之比。

旧章的行列式身份在此重现：

$$N\sum_tX_t^2-\Big(\sum_tX_t\Big)^2=N^2\hat\sigma_x^2,$$

其中 $\hat\sigma_x^2=S_{xx}/N$ 。

只要 $x$ 不全相等（$S_{xx}>0$ ，即 A2 的一元版），正规方程就可解。

本章固定三点例的账：$x=0,1,2$ ，$y=1,2,4$ ，$\bar x=1$ ，$\bar y=7/3$ ，

$$S_{xx}=(0-1)^2+0+(2-1)^2=2,$$

$$S_{xy}=(-1)\Big(1-\frac73\Big)+0+(1)\Big(4-\frac73\Big) =\frac43+\frac53=3,$$

$$\hat\beta_2=\frac32, \qquad \hat\beta_1=\frac73-\frac32\cdot1=\frac56.$$

下面所有机器单元都围绕这组数。

## 38.9 拟合值、残差与两个投影矩阵

把解代入定义：

$$\hat y=X\hat\beta=X(X'X)^{-1}X'y\equiv Py, \qquad e=y-\hat y=(I-P)y\equiv My.$$

矩阵

$$\boxed{ P=X(X'X)^{-1}X', \qquad M=I_n-P }$$

分别称为帽子矩阵（$P$ 给 $y$ 戴上帽子）与残差制造矩阵（$M$ 造出残差）。

它们把 $\mathbb R^n$ 分解为两个正交的部分：

$$\operatorname{col}(P)=\operatorname{col}(X), \qquad \operatorname{col}(M)=\operatorname{col}(X)^\perp, \qquad \mathbb R^n=\operatorname{col}(X)\oplus\operatorname{col}(X)^\perp.$$

## 38.10 P 与 M 的性质清单及证明

以下各条除最后一条外均为初等矩阵代数的直接推论。

**(1) 对称。** $(X'X)^{-1}$ 是对称矩阵的逆，故对称；于是 $P'=P$ ，$M'=M$ 。

**(2) 幂等。**

$$P^2=X(X'X)^{-1}X'X(X'X)^{-1}X'=X(X'X)^{-1}X'=P,$$

$M^2=(I-P)^2=I-2P+P^2=I-P=M$ 。

**(3) 互补与正交。** $P+M=I_n$ ，$PM=P-P^2=0$ 。

**(4) 残差正交。**

$$X'e=X'My=X'(I-P)y=X'y-X'X(X'X)^{-1}X'y=0.$$

这就是“残差与每个解释变量（含常数列）的样本内积为零”。

特别地，常数列给出 $\sum_te_t=0$ ，第 39 章的平方和分解要用它。

**(5) 拟合与残差正交。**

$$\hat y'e=(Py)'(My)=y'PMy=0.$$

**(6) P 不动列空间中的向量。** $PX=X$ ：已经在 $\operatorname{col}(X)$ 中的向量投影后不变。

**(7) 秩等于迹。** 幂等矩阵特征值只能是 0 或 1，故

$$\operatorname{rank}(P)=\operatorname{tr}(P) =\operatorname{tr}\big((X'X)^{-1}X'X\big) =\operatorname{tr}(I_k)=k,$$

$$\operatorname{rank}(M)=\operatorname{tr}(M)=n-\operatorname{tr}(P)=n-k.$$

迹的轮换性质 $\operatorname{tr}(AB)=\operatorname{tr}(BA)$ 用了一次。

自由度 $n-k$ 在这里第一次以纯代数身份出现；第 39 章它将成为 $s^2$ 的分母。

**(8) 勾股分解。**

$$\boxed{ \|y\|^2=\|\hat y\|^2+\|e\|^2. }$$

**(9) 杠杆值。** 对角元 $P_{tt}\in[0,1]$ ，$\sum_tP_{tt}=k$ ，且 $\operatorname{Var}(e_t|X)=\sigma^2M_{tt}=\sigma^2(1-P_{tt})$ 。

$P_{tt}$ 度量第 $t$ 个观测在决定自身拟合值时的权重，称为杠杆值；经验上警惕 $P_{tt}>2k/n$ 的点。

**(10) 随机性质分界。** (1)–(9) 全部不需要 A3、A4、A5。

外生性或同方差从不改变这些等式——它们是算法的输出，不是模型的检验。

## 38.11 三点例的完整手算

固定设计

$$X=\begin{pmatrix}1&0\\1&1\\1&2\end{pmatrix}, \qquad y=\begin{pmatrix}1\\2\\4\end{pmatrix}.$$

逐步计算：

$$X'X=\begin{pmatrix}3&3\\3&5\end{pmatrix}, \qquad X'y=\begin{pmatrix}7\\10\end{pmatrix}, \qquad \det(X'X)=6,$$

$$(X'X)^{-1}=\frac16\begin{pmatrix}5&-3\\-3&3\end{pmatrix}, \qquad \hat\beta=\frac16\begin{pmatrix}5\cdot7-3\cdot10\\-3\cdot7+3\cdot10\end{pmatrix} =\begin{pmatrix}5/6\\3/2\end{pmatrix}.$$

拟合值与残差：

$$\hat y=\begin{pmatrix}5/6\\7/3\\23/6\end{pmatrix}, \qquad e=\begin{pmatrix}1/6\\-1/3\\1/6\end{pmatrix}, \qquad e'e=\frac16+\frac19+\frac1 6=\frac16.$$

验证 $X'e$ ：

$$\sum_te_t=\frac16-\frac13+\frac16=0, \qquad \sum_tX_te_t=0\cdot\frac16+1\cdot\Big(-\frac13\Big)+2\cdot\frac16=0.$$

投影矩阵：

$$P=X(X'X)^{-1}X'=\frac16 \begin{pmatrix}5&2&-1\\2&2&2\\-1&2&5\end{pmatrix},$$

$$M=I-P=\frac16 \begin{pmatrix}1&-2&1\\-2&4&-2\\1&-2&1\end{pmatrix}.$$

核对：$\operatorname{tr}(P)=(5+2+5)/6=2=k$ ，$\operatorname{tr}(M)=(1+4+1)/6=1=n-k$ 。

杠杆值 $P_{11}=P_{33}=5/6$ 高、$P_{22}=1/3$ 低——端点观测把直线拉向自己。

一个巧合值得单独指出：对这个设计

$$\hat\beta_2=\frac{(Y_3-Y_1)}{2},$$

因为 $(X'X)^{-1}X'$ 的第二行是 $\frac16(-3,0,3)$ 。

第 39 章会用它构造 Gauss–Markov 的对照估计。

## 38.12 Python：精确分数与库对拍

文件 `examples/python/38_ols.py` 先用 `Fraction` 把整条计算链走一遍。

矩阵运算不借助任何库，用三重循环显式实现：

```python
def matmul(A, B):
    return [[sum(A[i][k] * B[k][j] for k in range(len(B)))
             for j in range(len(B[0]))] for i in range(len(A))]
```

`solve2` 按克莱姆法则解 $2\times2$ 方程组，行列式非零用断言钉住：

```python
def inv2(S):
    det = S[0][0] * S[1][1] - S[0][1] * S[1][0]
    assert det != 0
    return [[S[1][1] / det, -S[0][1] / det],
            [-S[1][0] / det, S[0][0] / det]]
```

核心断言链与手算一一对应：

```python
beta = solve2(XtX, Xty)
assert beta == [F(5, 6), F(3, 2)]
Xte = [row[0] for row in matmul(transpose(X), [[v] for v in resid])]
assert Xte == [F(0), F(0)]
P = matmul(X, matmul(inv2(XtX), transpose(X)))
assert matmul(P, P) == P
assert trace(P) == 2 and trace(M) == 1
```

每一项都是精确分数，没有浮点参与。

随后同一组数换浮点通道对拍：

```python
coef, _, _, _ = np.linalg.lstsq(Xf, yf, rcond=None)
assert np.allclose(coef, [5 / 6, 1.5])
```

两条通道结果一致，输出为

```
exact OLS: beta = (5/6, 3/2); e = (1/6, -1/3, 1/6); X'e = 0; rank P = tr P = 2
numpy cross-check: [0.83333333 1.5]
```

误差度量小节复现第 38.5 节的对照：

```python
b3 = sum(r) / N                                    # E3：残差均值
b2 = min((i * 0.001 for i in range(0, 2001)), key=E2)
assert 0.89 < b2 < 0.96                            # E2：落在中位数区间内
assert abs(e1(b3)) < 1e-12 and e1(10.0) < 0 < e1(-10.0)   # E1 无下界
assert E2(b2) < E2(b3) - 0.9 and E3(b3) < E3(b2) - 1.0
```

网格搜索把 $b2$ 定在中位数区间 $0.902$ ，与 E3 的 $1.4125$ 相差超过 $0.4$ ：

```
metric choice: E1 unbounded; E2 intercept 0.902 differs from E3 1.4125
```

## 38.13 Julia：有理数矩阵的独立实现

`examples/julia/38_ols.jl` 用 Julia 的 `Rational{Int}` 矩阵独立复算。

`//` 字面量让整个矩阵类型提升为有理数，`\` 与 `inv` 在该类型上精确工作：

```julia
X = [1 0; 1 1; 1 2] .// 1
beta = XtX \ Xty
@assert beta == [5 // 6, 3 // 2]
@assert X' * resid == [0, 0]
P = X * inv(XtX) * X'
@assert P == (1 // 6) .* [5 2 -1; 2 2 2; -1 2 5]
@assert tr(P) == 2 && tr(M) == 1
```

注意 `Matrix{Rational{Int}}(I, 3, 3)` 构造单位阵时必须显式给类型，否则整数单位阵与有理数 $P$ 相减会报类型错。

浮点对拍用 `Xf \ yf`，得到 `[0.8333333333333333, 1.5]`。

固定设计的 Monte Carlo 部分（第 38.15 节详述）把重复实验封进循环，输出

```
MC unbiased: mean = [1.0054, 1.9999]; cov diag = [0.31391, 0.001]
endogeneity: mean slope = 2.5002 (plim 2.5); X'e = 0 holds anyway
```

Julia 与 Python 的随机数实现不同，经验数字不必逐位一致；理论值一致才是对账目标。

## 38.14 Lean：投影代数的形式化

`examples/lean/Probability/Ch38OLS.lean` 把固定例的全部代数断言交给编译执行精确判定：

```lean
def X : Matrix (Fin 3) (Fin 2) ℚ := !![(1 : ℚ), 0; 1, 1; 1, 2]
def yVec : Fin 3 → ℚ := ![(1 : ℚ), 2, 4]
def betaHat : Fin 2 → ℚ := ![(5 : ℚ) / 6, 3 / 2]
def resid : Fin 3 → ℚ := ![(1 : ℚ) / 6, -1 / 3, 1 / 6]
def P : Matrix (Fin 3) (Fin 3) ℚ :=
  !![(5 : ℚ) / 6, 2 / 6, -1 / 6; 2 / 6, 2 / 6, 2 / 6; -1 / 6, 2 / 6, 5 / 6]
def M : Matrix (Fin 3) (Fin 3) ℚ :=
  !![(1 : ℚ) / 6, -2 / 6, 1 / 6; -2 / 6, 4 / 6, -2 / 6; 1 / 6, -2 / 6, 1 / 6]
```

元素直接写成显式有理数（首个元素加类型标注锚定 `ℚ`），而不是用 `(1/6) • !![…]` 数乘——后者会让矩阵字面量先按整数定型，触发跨类型数乘的实例失败。

正规方程、残差正交、幂等、互补、秩迹和勾股分解全部由 `native_decide` 判定：

```lean
example : (Xᵀ * X) *ᵥ betaHat = Xᵀ *ᵥ yVec := by native_decide
example : Xᵀ *ᵥ resid = ![(0 : ℚ), 0] := by native_decide
example : P * P = P := by native_decide
example : P + M = 1 := by native_decide
example : Matrix.trace P = 2 := by native_decide
```

两处细节值得说明。

其一，正规方程必须写成 `(Xᵀ * X) *ᵥ betaHat`：记号 `*ᵥ` 的结合力高于 `*`，不加括号会被解析成 `Xᵀ * (X *ᵥ betaHat)`，维度错乱；而且 `Xᵀ *ᵥ betaHat` 本身就是类型错误——$X'$ 是 $2\times3$ 矩阵，只能右乘 3 维向量。

其二，这里用 `native_decide` 而非 kernel `decide`：kernel 对有理数链式求和的归约会停滞在 `Rat` 分子比较的 match 上（实测同一批断言 `decide` 全部超时），而编译执行通道把同样的精确算术交给 GMP，10 秒内完成整文件。

勾股分解也是一个整体判定：

```lean
example : yVec ⬝ᵥ yVec =
    (P *ᵥ yVec) ⬝ᵥ (P *ᵥ yVec) + (M *ᵥ yVec) ⬝ᵥ (M *ᵥ yVec) := by
  native_decide
```

编译执行算出两边都是 $21=125/6+1/6$ 。

最后，矩阵公式与闭式的巧合被单独核对：

```lean
example : betaHat 1 = (yVec 2 - yVec 0) / 2 := by native_decide
```

形式化文件锚定的是**代数层**。

它验证每一步计算，但不证明无偏性或 Gauss–Markov——那些属于随机层，由第 39 章的推导和模拟共同支撑。

## 38.15 固定设计下的无偏性与协方差：Monte Carlo 审计

在 A1–A4 下有（第 39 章证明）

$$E(\hat\beta|X)=\beta, \qquad \operatorname{Var}(\hat\beta|X)=\sigma^2(X'X)^{-1}.$$

Python 单元用固定设计 $x=1,\ldots,30$ 、真值 $\beta=(1,2)$ 、$\sigma=1.5$ 、20,000 次重复审计：

```python
Y = Xd @ beta0 + rng.normal(0.0, sigma, (reps, n))
B = Y @ Xd @ XtXi
assert np.allclose(B.mean(axis=0), beta0, atol=0.02)
assert np.allclose(np.cov(B.T), sigma ** 2 * XtXi, atol=0.02)
```

理论协方差：$\det(X'X)=67425$ ，

$$(X'X)^{-1}=\frac1{67425}\begin{pmatrix}9455&-465\\-465&30\end{pmatrix},$$

对角元乘 $\sigma^2=2.25$ 得 $(0.31550,\ 0.001001)$ 。

经验值：Python $(0.31538,\ 0.001)$ ，Julia $(0.31391,\ 0.001)$ ，均值两通道都贴近 $(1,2)$ 。

模拟审计的是这个固定设计的频率行为；等式本身由第 39 章的两行推导给出。

## 38.16 内生性：代数不变，统计失效

现在故意破坏 A3。

设真实模型仍是 $Y=1+2X+\varepsilon$ ，但让解释变量与扰动相关：

$$X=\varepsilon+v,\qquad \varepsilon,v\ \text{独立标准正态}.$$

代入斜率公式：

$$\hat\beta_2 =2+\frac{\sum_t(X_t-\bar X)(\varepsilon_t-\bar\varepsilon)} {\sum_t(X_t-\bar X)^2},$$

由大数定律（第 26 章），第二项依概率收敛到

$$\frac{\operatorname{Cov}(X,\varepsilon)}{\operatorname{Var}(X)} =\frac{1}{2},$$

故

$$\operatorname{plim}\hat\beta_2=2.5\ne\beta_2.$$

OLS 不再一致。

经典解释是“遗漏变量”：$X$ 里混着一个既影响 $Y$ （通过 $\varepsilon$ ）又与 $X$ 同源的成分。

Python 单元（$n=200$ ，5,000 次重复）：

```python
x2 = eps + v
y2 = 1.0 + 2.0 * x2 + eps
slopes = (xc * yc).sum(axis=1) / (xc * xc).sum(axis=1)
assert abs(slopes.mean() - 2.5) < 0.05
```

经验均值斜率 2.4989，Julia 得 2.5002，均贴住 2.5。

与此同时，每个样本内部的代数恒等式完好无损：

```python
e_first = y2[0] - X_first @ np.linalg.lstsq(X_first, y2[0], rcond=None)[0]
assert np.abs(X_first.T @ e_first).max() < 1e-8
```

输出行明确写着 `X'e = 0 holds anyway`。

这正是第 38.4 节分层表的数值版：**残差正交验证的是算法，外生性失灵藏在算法看不到的地方。**

## 38.17 常见误区

### 误区一：残差不相关说明模型设定正确

$X'e=0$ 对任何数据自动成立，不检验任何假设。

### 误区二：线性回归只能拟合直线

线性是对参数的；取对数、多项式、虚拟变量后仍是线性回归。

### 误区三：多重共线使 OLS 有偏

完全共线使解不唯一（代数问题）；近似共线使方差膨胀（精确性问题）。

无偏性只依赖外生性。

### 误区四：加入变量越多拟合越好，所以模型越好

样本内 $R^2$ 必不降（第 39 章证明），这不代表样本外预测更好。

### 误区五：OLS 需要正态误差

估计与 Gauss–Markov 都不需要；正态只在精确 $t/F$ 推断中出现。

### 误区六：$\hat\beta$ 无偏需要同方差

无偏只需要 A3；A4 影响的是方差公式与最优性。

### 误区七：杠杆值高的点一定有问题

高杠杆点未必影响系数（它可能恰好落在拟合面上）；它只是拥有把直线拉向自己的**潜力**，需要结合残差判断。

## 38.18 本章要点

1. 经典线性模型 $y=X\beta+\varepsilon$ 的假设应分层：A1–A2 是代数与识别，A3 给无偏，A4 给方差形状与 BLUE，A5 留给精确推断。
2. 投影、微分、配方三条路线给出同一解 $\hat\beta=(X'X)^{-1}X'y$ ；几何语言把它定位为正交投影。
3. $P=X(X'X)^{-1}X'$ 与 $M=I-P$ 对称、幂等、互补；$\operatorname{tr}P=k$ ，$\operatorname{tr}M=n-k$ 。
4. $X'e=0$ 、勾股分解 $\|y\|^2=\|\hat y\|^2+\|e\|^2$ 是纯代数，对任何数据成立。
5. 一元回归斜率 $S_{xy}/S_{xx}$ 是协方差/方差之比；可逆性由 $S_{xx}>0$ 保证。
6. 三点固定例给出全有理数账：$\hat\beta=(5/6,3/2)$ ，$e=(1/6,-1/3,1/6)$ ，$e'e=1/6$ ，$\operatorname{tr}P=2$ 。
7. 误差度量的选择（E1 失效、E2 中位数、E3 均值）本身就是建模决策，平方损失的胜利是数学便利而非唯一合理。
8. 外生性失灵时 $\operatorname{plim}\hat\beta_2=\beta_2+\operatorname{Cov}(X,\varepsilon)/\operatorname{Var}(X)$ ，但 $X'e=0$ 逐样本成立——检验代数不能替代假设论证。

---

上一章：[37 Wald、LM、LR 检验与置信区间](37-asymptotic-tests.md) · 下一章：[39 拟合优度与 Gauss–Markov](39-ols-properties.md)
