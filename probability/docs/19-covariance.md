# 第 19 章 协方差、相关与独立

## 19.1 从相依到线性相依

第 17 章说明联合分布决定变量之间的全部相依关系。联合分布很丰富，也很复杂。协方差不试图概括全部相依，而只测量一种最常用的结构：两个变量围绕各自均值共同波动的方向和强度。

设 \(X,Y\) 的二阶矩有限，记

\[
\mu_X=E[X],\qquad \mu_Y=E[Y].
\]

协方差定义为

\[
\boxed{\operatorname{Cov}(X,Y)
=E[(X-\mu_X)(Y-\mu_Y)].}
\]

利用期望的线性性，

\[
\begin{aligned}
E[(X-\mu_X)(Y-\mu_Y)]
&=E[XY-\mu_XY-X\mu_Y+\mu_X\mu_Y]\\
&=E[XY]-\mu_X\mu_Y.
\end{aligned}
\]

所以常用的等价公式是

\[
\operatorname{Cov}(X,Y)=E[XY]-E[X]E[Y].
\]

若协方差为正，\(X\) 高于均值时 \(Y\) 也倾向于高于均值；若为负，则倾向反向波动；若为零，只说明二者**没有线性共同波动**，不说明它们独立。

## 19.2 协方差的基本代数

协方差对两个参数都是线性的：

\[
\operatorname{Cov}(aX+b,cY+d)=ac\,\operatorname{Cov}(X,Y).
\]

常数平移不影响协方差，尺度相乘。更一般地，

\[
\operatorname{Cov}\left(\sum_i a_iX_i,\sum_j b_jY_j\right)
=\sum_{i,j}a_ib_j\operatorname{Cov}(X_i,Y_j).
\]

同一变量的协方差就是方差：

\[
\operatorname{Cov}(X,X)=\operatorname{Var}(X).
\]

因此两个变量和的方差为

\[
\boxed{
\operatorname{Var}(X+Y)
=\operatorname{Var}(X)+\operatorname{Var}(Y)
+2\operatorname{Cov}(X,Y).
}
\]

独立时协方差为零，于是回到第 16 章用过的方差可加性。但反向不成立：零协方差只代表线性不相关。

Python 程序用一张四点有限表精确比较定义式与捷径公式：

```python
pmf = {(0, 1): F(1, 8), (1, 0): F(3, 8),
       (1, 2): F(1, 4), (2, 1): F(1, 4)}
ex = E(pmf, lambda a, b: a); ey = E(pmf, lambda a, b: b)
c_def = E(pmf, lambda a, b: (a - ex) * (b - ey))
c_short = E(pmf, lambda a, b: a * b) - ex * ey
assert c_def == c_short
vx = E(pmf, lambda a, b: (a - ex) ** 2)
vy = E(pmf, lambda a, b: (b - ey) ** 2)
vsum = E(pmf, lambda a, b: (a + b - ex - ey) ** 2)
assert vsum == vx + vy + 2 * c_def
```

Prolog 对同一张表给出精确分数：

\[
\operatorname{Cov}(X,Y)=\frac1{64},\quad
\operatorname{Var}(X)=\frac{23}{64},\quad
\operatorname{Var}(Y)=\frac{39}{64}.
\]

Lean 则只保留证明中真正需要的代数骨架：

```lean
example (a b c d μ ν m : ℚ) :
    (a * c * m + a * d * μ + b * c * ν + b * d)
      - (a * μ + b) * (c * ν + d)
    = a * c * (m - μ * ν) := by ring
```

这里 \(m=E[XY]\)、\(\mu=E[X]\)、\(\nu=E[Y]\)。把统计语言翻译成期望后，双线性公式只是 `ring` 能判决的恒等式。

## 19.3 相关系数与 Cauchy–Schwarz

若 \(\operatorname{Var}(X)>0\)、\(\operatorname{Var}(Y)>0\)，定义相关系数

\[
\boxed{
\rho_{X,Y}
=\frac{\operatorname{Cov}(X,Y)}
{\sqrt{\operatorname{Var}(X)\operatorname{Var}(Y)}}.
}
\]

标准化变量

\[
U=\frac{X-\mu_X}{\sigma_X},\qquad
V=\frac{Y-\mu_Y}{\sigma_Y}
\]

都有方差 1，且 \(\rho=\operatorname{Cov}(U,V)\)。

### 19.3.1 \(|\rho|\le1\) 的证明

对任意实数 \(t\)，

\[
\operatorname{Var}(t(X-\mu_X)+(Y-\mu_Y))\ge0.
\]

展开得到二次函数

\[
q(t)=\operatorname{Var}(X)t^2
+2\operatorname{Cov}(X,Y)t+\operatorname{Var}(Y)\ge0.
\]

一个恒非负的二次多项式 \(at^2+2ct+b\) 在 \(a>0\) 时判别式非正，所以

\[
4c^2-4ab\le0.
\]

即

\[
\operatorname{Cov}(X,Y)^2
\le \operatorname{Var}(X)\operatorname{Var}(Y).
\]

这就是概率中的 Cauchy–Schwarz 不等式。除以两个方差得

\[
\rho^2\le1,\qquad -1\le\rho\le1.
\]

Lean 用代换 \(t=-c/v_a\) 的方式构造证明，而不是调用二次方程结论：

```lean
example (va vb c : ℚ) (hva : 0 < va)
    (h : ∀ t : ℚ, 0 ≤ va * t ^ 2 + 2 * c * t + vb) :
    c ^ 2 ≤ va * vb := by
  have := h (-c / va)
  have key : va * (-c / va) ^ 2 + 2 * c * (-c / va) + vb
      = (va * vb - c ^ 2) / va := by field_simp; ring
  rw [key] at this
  -- 由分母 va>0 与商非负推出 va*vb-c^2 ≥ 0
```

取等时，存在 \(t\) 使一个非负随机变量的方差为 0，于是它几乎处处为常数。也就是说，在二阶矩有限且两方差异格为正的条件下，\(|\rho|=1\) 等价于 \(Y\) 是 \(X\) 的仿射函数：

\[
Y=aX+b,\qquad a\ne0,
\]

且 \(\rho=\operatorname{sign}(a)\)。

Python 程序用四张等概率点分别检查 \(Y=2X+1\) 给出 \(\rho=1\)、\(Y=-3X+1\) 给出 \(\rho=-1\)：

```python
pm = {(x, 2 * x + 1): F(1, 4) for x in (0, 1, 2, 3)}
assert cov(pm) ** 2 == vx_ * vy_ and cov(pm) > 0
pm2 = {(x, -3 * x + 1): F(1, 4) for x in (0, 1, 2, 3)}
assert cov(pm2) ** 2 == vx_ * vy2 and cov(pm2) < 0
```

Julia 的 200 组随机样本只用于检查样本相关系数数值上不超过 1；定理本身来自上面的二次型证明。

## 19.4 独立与不相关不是同义词

若 \(X,Y\) 独立且二阶矩可积，则

\[
E[XY]=E[X]E[Y],
\]

所以 \(\operatorname{Cov}(X,Y)=0\)。但零协方差只排除线性关系，不排除非线性函数关系。

### 19.4.1 离散反例：\(Y=X^2\)

令 \(X\) 在 \(\{-1,0,1\}\) 上均匀，令 \(Y=X^2\)。则

\[
E[X]=0,\qquad E[XY]=E[X^3]=0,
\]

故

\[
\operatorname{Cov}(X,Y)=0.
\]

但 \(Y\) 完全由 \(X\) 决定，显然不独立。例如

\[
P(X=0,Y=0)=\frac13,
\]

而

\[
P(X=0)P(Y=0)=\frac13\cdot\frac13=\frac19.
\]

Prolog 的表 A 精确记录这一反例：

```prolog
joint(a, -1, 1, 1 rdiv 3).
joint(a,  0, 0, 1 rdiv 3).
joint(a,  1, 1, 1 rdiv 3).
```

Lean 使用同一组三点分布，并把关键违例化为有理数算术：

```lean
def cex : ℤ → ℤ → ℚ
  | -1, 1 => 1 / 3
  | 0, 0 => 1 / 3
  | 1, 1 => 1 / 3
  | _, _ => 0

example : cex 0 0 ≠ (1 / 3) * (1 / 3) := by
  simp [cex]
```

### 19.4.2 连续反例：\(X\sim U(-1,1)\)，\(Y=X^2\)

连续情形同样成立：

\[
E[XY]=E[X^3]=\frac12\int_{-1}^1x^3dx=0.
\]

但事件 \(\{|X|<1/2\}\) 与 \(\{Y>1/2\}\) 不可能同时发生，因为 \(|X|<1/2\) 时 \(Y<1/4\)。另一方面，

\[
P(|X|<1/2)P(X^2>1/2)
=\frac12\left(1-\frac1{\sqrt2}\right)>0.
\]

联合概率为 0、概率积为正，因此不独立。

Julia 对固定种子样本计算：

```julia
U = 2 .* rand(N) .- 1; V = U .^ 2
@assert abs(cor(U, V)) < 0.01
pj = mean((abs.(U) .< 0.5) .& (V .> 0.5))
pp = mean(abs.(U) .< 0.5) * mean(V .> 0.5)
@assert pj == 0.0 && pp > 0.1
```

注意样本相关接近 0 并不是证明；连续积分和事件概率才是证明。

## 19.5 Bernoulli 对的特殊情形

对一般随机变量，零协方差不意味着独立；但当 \(X,Y\) 都只取 0、1 两个值时，结论会增强。

设

\[
p_1=P(X=1),\qquad p_2=P(Y=1),\qquad
c=\operatorname{Cov}(X,Y).
\]

由于 \(XY=1\) 当且仅当 \(X=Y=1\)，

\[
P(X=1,Y=1)=E[XY]=p_1p_2+c.
\]

其余三个格点概率由边际约束唯一确定：

\[
\begin{aligned}
p_{10}&=p_1(1-p_2)-c,\\
p_{01}&=(1-p_1)p_2-c,\\
p_{00}&=(1-p_1)(1-p_2)+c.
\end{aligned}
\]

当 \(c=0\) 时，四个格点全部等于边际概率乘积，因此两个 Bernoulli 变量独立。

Prolog 对两组具体边际概率检查这个结论：

```prolog
forall(member(P1-P2, [(1 rdiv 2)-(1 rdiv 3),
                      (1 rdiv 4)-(3 rdiv 5)]),
       ( P11 is P1 * P2,
         P10 is P1 - P11,
         P01 is P2 - P11,
         P00 is 1 - P1 - P2 + P11,
         P10 =:= P1 * (1 - P2),
         P00 =:= (1 - P1) * (1 - P2) ))
```

这个特例提醒我们：定理结论依赖变量的取值范围。把“零相关不意味着独立”和“Bernoulli 对零相关等价独立”同时记住，才不会过度推广。

## 19.6 协方差矩阵与半正定性

对随机向量 \(X=(X_1,\dots,X_d)^T\)，均值向量和协方差矩阵为

\[
\mu=E[X],\qquad
\Sigma=E[(X-\mu)(X-\mu)^T].
\]

矩阵元素为

\[
\Sigma_{ij}=\operatorname{Cov}(X_i,X_j).
\]

对任意固定权重向量 \(w\)，线性组合 \(w^TX\) 的方差为

\[
\boxed{\operatorname{Var}(w^TX)=w^T\Sigma w.}
\]

因为方差非负，所以

\[
w^T\Sigma w\ge0\qquad\text{对所有 }w\in\mathbb R^d.
\]

这就是协方差矩阵半正定。若存在 \(w\ne0\) 使 \(w^T\Sigma w=0\)，则 \(w^TX\) 几乎处处为常数，随机向量被约束在一个低维仿射子空间上。

例如 \(Y=2X+1\) 时，

\[
\Sigma=
\begin{pmatrix}
v&2v\\
2v&4v
\end{pmatrix},
\qquad \det\Sigma=0,
\]

且向量 \((2,-1)\) 满足

\[
(2,-1)\Sigma(2,-1)^T=0.
\]

Python 对三维二次型展开做符号核对：

```python
Sig = sp.Matrix([[s1**2, r12*s1*s2, r13*s1*s3],
                 [r12*s1*s2, s2**2, r23*s2*s3],
                 [r13*s1*s3, r23*s2*s3, s3**2]])
w = sp.Matrix(sp.symbols("w1 w2 w3"))
quad = sp.expand((w.T * Sig * w)[0])
expected = sum(w[i]**2 * Sig[i, i] for i in range(3)) + \
           2 * sum(w[i] * w[j] * Sig[i, j]
                   for i in range(3) for j in range(i + 1, 3))
assert sp.expand(quad - expected) == 0
```

Julia 从 Cholesky 型因子 \(X=ZL^T\) 生成三维高斯向量，并检查样本协方差矩阵的特征值非负：

```julia
L = [1.0 0 0; 0.6 0.8 0; -0.3 0.5 0.9]
X = Z * L'
Σhat = cov(X)
@assert all(eigvals(Symmetric(Σhat)) .>= -1e-12)
```

模拟中的小负特征值若出现，只是浮点误差；数学上样本协方差矩阵也是半正定的。

### 19.6.1 不是任意相关数都能组成相关矩阵

三维相关矩阵必须半正定。其行列式条件为

\[
1+2r_{12}r_{13}r_{23}
-r_{12}^2-r_{13}^2-r_{23}^2\ge0.
\]

若取

\[
r_{12}=0.9,\qquad r_{23}=0.9,\qquad r_{13}=-0.9,
\]

则前两对高度正相关、第三对高度负相关，结构互相矛盾，行列式为负。这样的“相关矩阵”不可能由任何随机向量产生。Python 精确计算该行列式并断言其小于 0。

## 19.7 投资组合：最小方差权重

考虑两个资产收益率 \(R_1,R_2\)，参数为

\[
\sigma_1^2=\operatorname{Var}(R_1),\quad
\sigma_2^2=\operatorname{Var}(R_2),\quad
\rho=\operatorname{Corr}(R_1,R_2).
\]

若把财富比例 \(w\) 投资于资产 1、\(1-w\) 投资于资产 2，则组合收益率为

\[
R_w=wR_1+(1-w)R_2,
\]

方差为

\[
V(w)=w^2\sigma_1^2+(1-w)^2\sigma_2^2
+2w(1-w)\rho\sigma_1\sigma_2.
\]

令 \(c=\rho\sigma_1\sigma_2\)。求导 \(V'(w)=0\) 得

\[
\boxed{
w^*=\frac{\sigma_2^2-c}{\sigma_1^2+\sigma_2^2-2c}.
}
\]

当 \(\rho<1\) 且分母为正时，最小方差为

\[
V(w^*)=
\frac{\sigma_1^2\sigma_2^2(1-\rho^2)}
{\sigma_1^2+\sigma_2^2-2\rho\sigma_1\sigma_2}.
\]

程序取

\[
\sigma_1=0.2,\qquad \sigma_2=0.3,\qquad \rho=0.5.
\]

于是 \(c=0.03\)，

\[
w^*=\frac{0.09-0.03}{0.04+0.09-0.06}=\frac67,
\]

且

\[
V(w^*)=\frac{27}{700}\approx0.03857.
\]

它比单独持有资产 1 的方差 0.04 还小，说明分散化可以降低风险。

Lean 不用求导，而用完全平方恒等式证明全局最小：

\[
V(w)-V(w^*)
=(\sigma_1^2+\sigma_2^2-2c)(w-w^*)^2.
\]

```lean
example (s1 s2 c w : ℚ) (hd : s1 + s2 - 2 * c ≠ 0) :
    portVar s1 s2 c w
      - portVar s1 s2 c ((s2 - c) / (s1 + s2 - 2 * c))
    = (s1 + s2 - 2 * c)
      * (w - (s2 - c) / (s1 + s2 - 2 * c)) ^ 2 := by
  unfold portVar
  field_simp
  ring
```

Lean 中的 `s1,s2` 表示方差而不是标准差；与正文的 \(\sigma_1^2,\sigma_2^2\) 对应。

### 19.7.1 完全负相关与完全正相关

若 \(\rho=-1\)，两个风险可以完全对冲。最小方差可为 0，权重为

\[
w^*=\frac{\sigma_2}{\sigma_1+\sigma_2}.
\]

若 \(\rho=1\)，则

\[
\operatorname{Var}(wR_1+(1-w)R_2)
=(w\sigma_1+(1-w)\sigma_2)^2,
\]

分散化不再降低风险。等相关 \(n\) 资产组合的平均方差为

\[
\frac{\sigma^2}{n}+\left(1-\frac1n\right)\rho\sigma^2,
\]

当 \(n\to\infty\) 时趋于 \(\rho\sigma^2\)。第一项是可分散的个体风险，剩余项是不能靠分散化消除的共同风险。

## 19.8 超几何抽样：负协方差与有限总体修正

从容量为 \(N\) 的总体中不放回抽取 \(n\) 次，总体中有 \(K\) 个成功。令

\[
p=\frac KN,
\]

并令 \(I_i=1\) 表示第 \(i\) 次抽到成功。单个指示变量满足

\[
E[I_i]=p,\qquad \operatorname{Var}(I_i)=p(1-p).
\]

但不同次抽取不独立：

\[
E[I_iI_j]=P(I_i=1,I_j=1)=\frac{K(K-1)}{N(N-1)}.
\]

因此

\[
\operatorname{Cov}(I_i,I_j)
=\frac{K(K-1)}{N(N-1)}-p^2
=-\frac{p(1-p)}{N-1}.
\]

负号来自不放回抽样：第一次抽走成功后，第二次抽到成功的概率略降。把 \(n\) 项方差和两两协方差相加，得到

\[
\operatorname{Var}\left(\sum_{i=1}^nI_i\right)
=np(1-p)\frac{N-n}{N-1}.
\]

因子 \((N-n)/(N-1)\) 称为有限总体修正。当 \(N\to\infty\) 而抽样比例很小，它趋于 1，超几何分布接近二项分布。

Python 对 \(N=7,K=3,n=4\) 枚举全部超几何概率，并精确断言方差为

\[
4\cdot\frac37\cdot\frac47\cdot\frac{3}{6}.
\]

```python
pmf_h = {k: F(comb(Kv, k) * comb(Nv - Kv, nv - k), comb(Nv, nv))
         for k in range(0, min(Kv, nv) + 1)
         if nv - k <= Nv - Kv}
var_enum = sum(k * k * p for k, p in pmf_h.items()) - mean_h**2
assert var_enum == nv * pv * (1 - pv) * F(Nv - nv, Nv - 1)
```

这个例子展示了协方差项不能随手丢掉：同一总体中的抽样指标通常不独立。

## 19.9 多元 Chebyshev 与 Mahalanobis 距离

若随机向量 \(X\) 的均值为 \(\mu\)、协方差矩阵 \(\Sigma\) 正定，定义 Mahalanobis 平方距离

\[
D^2=(X-\mu)^T\Sigma^{-1}(X-\mu).
\]

令 \(Z=\Sigma^{-1/2}(X-\mu)\)，则 \(\operatorname{Cov}(Z)=I\)，且 \(D^2=Z^TZ\)。因此

\[
E[D^2]=\sum_{j=1}^dE[Z_j^2]=d.
\]

对 \(D^2\) 使用 Markov 不等式，得到多元 Chebyshev 界：

\[
\boxed{
P(D^2\ge t)\le\frac dt.
}
\]

Python 在一个六点离散分布上精确计算 \(E[D^2]=2\)，并对多个 \(t\) 检查尾概率：

```python
def D2(a, b):
    v = sp.Matrix([a, b])
    return (v.T * Sinv * v)[0]

ED2 = sum(sp.Rational(p.numerator, p.denominator) * D2(*k)
          for k, p in pts.items())
assert ED2 == 2
for t in (F(1), F(2), F(4), F(6)):
    tail = sum(p for k, p in pts.items() if D2(*k) >= t)
    assert tail <= ED2 / t
```

Julia 对三维高斯模拟检查 \(E[D^2]\approx3\)。在真正的联合正态中还有更强结论 \(D^2\sim\chi^2_d\)，但上面的期望和 Markov 界只需要二阶矩和正定协方差，适用于更广的分布。

## 19.10 相关系数能说什么、不能说什么

相关系数在经济统计中很常用，但必须注意其边界：

1. \(\rho\) 只测线性关系。\(Y=X^2\) 可以在对称分布下与 \(X\) 零相关。
2. \(\rho\) 对异常值敏感。少数极端点可能显著改变样本相关。
3. 相关不是因果。两个变量可能因共同原因而相关，也可能因选择样本而产生虚假相关。
4. \(\rho=0\) 在一般情形下只意味着不相关；在联合正态分布中，它才等价于独立。第 21 章会精确说明“联合正态”这个条件为何关键。
5. 相关性必须有合法的协方差矩阵。若干两两相关数单独看都在 \([-1,1]\) 内，合起来仍可能违反半正定性。

本章机器示例的分工也反映这种差别：Prolog 和 Lean 处理有限反例与代数不等式，Python 做符号矩阵和精确分数，Julia 做固定种子模拟。模拟可以提示结构，但不能证明独立或半正定。

## 19.11 本章要点

1. 协方差是中心化乘积的期望，也等于 \(E[XY]-E[X]E[Y]\)。
2. 方差和必须包含交叉项；矩阵形式为 \(\operatorname{Var}(w^TX)=w^T\Sigma w\)。
3. \(|\rho|\le1\) 来自 \(L^2\) 空间的 Cauchy–Schwarz 不等式或二次型判别式。
4. 独立推出不相关，但不相关一般不推出独立；\(Y=X^2\) 是基本反例。
5. 对两个 Bernoulli 变量，零协方差足以推出独立，因为四个联合格点由两个边际和协方差唯一确定。
6. 协方差矩阵必须半正定；奇异协方差对应随机向量中的仿射约束。
7. 投资组合公式给出最小方差权重；等相关组合说明分散化只能消除个体风险，不能消除共同风险。
8. 不放回抽样的指示变量具有负协方差，产生有限总体修正。

*对应示例：`examples/lean/Probability/Ch19Covariance.lean`、`examples/julia/19_covariance.jl`、`examples/python/19_covariance.py`、`examples/prolog/19_covariance.pl`。*

---

上一章：[18 多元变换与 Jacobian](18-multivariate-transformations.md) · 下一章：[20 条件期望与条件方差](20-conditional-expectation.md)
