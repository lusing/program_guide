# 第 18 章 多元变换与 Jacobian

## 18.1 从一元变量变换到多维面积

第 10 章处理一元随机变量变换时，核心是 CDF 法或导数公式。一维公式

\[
f_Y(y)=f_X(g(y))|g'(y)|,\qquad y=T(x),\ x=g(y),
\]

中的 \(|g'(y)|\) 表示微小区间长度的伸缩倍数。多维随机向量变换时，区间长度换成区域面积或体积，线性伸缩倍数换成 **Jacobian 行列式的绝对值**。

设 \(X=(X_1,\dots,X_n)\) 有密度 \(f_X\)，变换 \(T\) 把 \(x\) 映到 \(y=T(x)\)，逆映射为 \(x=G(y)\)。若在一个开区域上：

1. \(T\) 与 \(G\) 连续可微；
2. \(T\) 是一一对应；
3. Jacobian 行列式 \(\det DG(y)\) 不为零；

则

\[
\boxed{
f_Y(y)=f_X(G(y))\left|\det DG(y)\right|.
}
\]

也可以写成正向形式：

\[
f_Y(T(x))=f_X(x)\left|\det DT(x)\right|^{-1}.
\]

边界和零测集不影响密度，可以忽略。若变换不是一一对应，就要把所有原像分区的贡献相加：

\[
f_Y(y)=\sum_{x:T(x)=y}f_X(x)\left|\det DT(x)\right|^{-1}.
\]

这是多元变量变换中最重要的安全规则：**一一映射用一个分支，多对一映射要枚举所有分支。**

## 18.2 行列式是线性变换的面积放大率

对线性变换 \(y=Ax\)，Jacobian 矩阵就是常数矩阵 \(A\)。单位正方形经

\[
A=\begin{pmatrix}2&1\\1&3\end{pmatrix}
\]

映为平行四边形，其面积为

\[
|\det A|=|2\cdot3-1\cdot1|=5.
\]

若连续做两个线性变换 \(A\) 与 \(B\)，则总面积放大率是乘积：

\[
\det(AB)=\det(A)\det(B).
\]

这正是多元链式法则的代数核心：

\[
D(G\circ H)(z)=DG(H(z))DH(z),
\]

所以

\[
\det D(G\circ H)(z)=\det DG(H(z))\det DH(z).
\]

`examples/lean/Probability/Ch18MultivariateTransformations.lean` 在有理数上直接验证乘法恒等式：

```lean
def det2 (a b c d : ℚ) : ℚ := a * d - b * c

example (a b c d e f g h : ℚ) :
    det2 (a * e + b * g) (a * f + b * h)
         (c * e + d * g) (c * f + d * h)
      = det2 a b c d * det2 e f g h := by
  unfold det2; ring
```

Prolog 用整数矩阵做同样的面积账，并额外检查奇异矩阵和旋转矩阵：

```prolog
det2(A, B, C, D, Det) :- Det is A * D - B * C.

check_det :-
    det2(2, 1, 1, 3, 5),
    det2(1, 2, 3, 6, 0),       % 两列线性相关，面积退化为 0
    det2(0, -1, 1, 0, 1).      % 90° 旋转保面积
```

这些是精确代数断言；它们不依赖随机采样。

## 18.3 和、积、商：辅助变量法

要计算两个随机变量的函数 \(Z=h(X,Y)\) 的密度，常构造一个辅助变量，使二维变换一一对应。先求 \((Z,W)\) 的联合密度，再把 \(W\) 积掉得到边际密度。

### 18.3.1 和变换

令

\[
U=X+Y,\qquad W=X.
\]

逆映射为

\[
X=W,\qquad Y=U-W.
\]

Jacobian 矩阵为

\[
\frac{\partial(X,Y)}{\partial(U,W)}
=
\begin{pmatrix}
0&1\\
1&-1
\end{pmatrix},
\qquad
\left|\det\right|=1.
\]

因此

\[
f_{U,W}(u,w)=f_{X,Y}(w,u-w),
\]

从而得到熟悉的卷积公式

\[
f_{X+Y}(u)=\int_{-\infty}^{\infty}f_{X,Y}(w,u-w)\,dw.
\]

独立时就是 \(f_X(w)f_Y(u-w)\)。这说明第 16 章的连续卷积不是孤立公式，而是辅助变量变换的边际化结果。

### 18.3.2 积变换

令

\[
U=XY,\qquad W=X.
\]

当 \(W\ne0\) 时，

\[
X=W,\qquad Y=U/W.
\]

Jacobian 行列式为

\[
\det
\begin{pmatrix}
0&1\\
1/W&-U/W^2
\end{pmatrix}
=-\frac1W.
\]

故

\[
f_{U,W}(u,w)=f_{X,Y}(w,u/w)\frac1{|w|},
\]

边际密度为

\[
f_{XY}(u)=\int\frac1{|w|}f_{X,Y}(w,u/w)\,dw.
\]

若 \(X,Y\) 独立且都在 \((0,1)\) 上均匀，则 \(0<u<1\)、\(u<w<1\)，所以

\[
f_{XY}(u)=\int_u^1\frac{dw}{w}=-\log u.
\]

其归一化为

\[
\int_0^1-\log u\,du=1.
\]

### 18.3.3 商变换

令

\[
U=X/Y,\qquad W=Y.
\]

逆映射为

\[
X=UW,\qquad Y=W.
\]

Jacobian 矩阵为

\[
\begin{pmatrix}
W&U\\0&1
\end{pmatrix},
\qquad \det=W.
\]

若 \(X,Y>0\)，绝对值就是 \(w\)，于是

\[
f_{X/Y}(u)=\int_0^\infty w f_{X,Y}(uw,w)\,dw.
\]

若 \(X,Y\) 独立，分别服从速率 \(\lambda,\mu\) 的指数分布，则

\[
\begin{aligned}
f_Z(z)
&=\int_0^\infty w\,\lambda e^{-\lambda zw}\mu e^{-\mu w}\,dw\\
&=\lambda\mu\int_0^\infty w e^{-(\mu+\lambda z)w}\,dw\\
&=\frac{\lambda\mu}{(\mu+\lambda z)^2},\qquad z>0.
\end{aligned}
\]

这里使用了 \(\int_0^\infty we^{-aw}dw=1/a^2\)。CDF 为

\[
F_Z(z)=P(X\le zY)=\frac{\lambda z}{\mu+\lambda z}.
\]

它对尺度同比缩放不敏感：把 \(\lambda,\mu\) 同时乘以同一个正数，商分布不变。

Python 符号程序逐项核对三个 Jacobian 与指数商密度：

```python
Jprod = sp.Matrix([v, u / v]).jacobian([u, v])
assert sp.simplify(Jprod.det() + 1 / v) == 0
Jquo = sp.Matrix([u * v, v]).jacobian([u, v])
assert sp.simplify(Jquo.det() - v) == 0

fz = sp.integrate(
    vv * lam * sp.exp(-lam * zz * vv) * mu * sp.exp(-mu * vv),
    (vv, 0, sp.oo))
assert sp.simplify(fz - lam * mu / (mu + lam * zz) ** 2) == 0
```

Julia 用中心差分近似 Jacobian，并用固定种子模拟核对指数商 CDF：

```julia
function numjac(f, p; h=1e-6)
    k = length(p); m = length(f(p))
    J = zeros(m, k)
    for j in 1:k
        e = zeros(k); e[j] = h
        J[:, j] = (f(p .+ e) .- f(p .- e)) ./ (2h)
    end
    J
end
@assert abs(abs(det(numjac(prodinv, [0.7, 1.9]))) - 1 / 1.9) < 1e-7
for z in (0.5, 1.0, 3.0)
    @assert abs(mean(Z .<= z) - λ * z / (μ + λ * z)) < 0.005
end
```

数值差分检查的是 Jacobian 代码；模拟检查的是采样分布。指数商密度本身则由上面的积分证明。

## 18.4 正态商为什么是 Cauchy

设 \(X,Y\) 独立且都服从标准正态。令 \(Z=X/Y\)，辅助变量 \(W=Y\)。逆映射为 \(X=ZW,Y=W\)，Jacobian 绝对值为 \(|w|\)。因此

\[
f_Z(z)=\int_{-\infty}^{\infty}|w|
\frac{e^{-(zw)^2/2}}{\sqrt{2\pi}}
\frac{e^{-w^2/2}}{\sqrt{2\pi}}\,dw.
\]

被积函数关于 \(w\) 偶：

\[
f_Z(z)
=\frac{1}{\pi}\int_0^\infty w
\exp\left(-\frac{1+z^2}{2}w^2\right)dw.
\]

令 \(t=(1+z^2)w^2/2\)，则 \(dt=(1+z^2)w\,dw\)，所以

\[
f_Z(z)=\frac1{\pi(1+z^2)}.
\]

这就是标准 Cauchy 密度。这个推导再次解释了第 14 章的结论：两个正态变量的商并不具有正态尾部，而具有 \(1/z^2\) 厚尾，甚至没有有限均值。

Python 用 SymPy 核对闭式：

```python
fc = 2 * sp.integrate(
    vv / (2 * sp.pi) * sp.exp(-(1 + zr**2) * vv**2 / 2),
    (vv, 0, sp.oo))
assert sp.simplify(fc - 1 / (sp.pi * (1 + zr**2))) == 0
```

## 18.5 极坐标与球坐标

二维极坐标为

\[
x=r\cos\theta,\qquad y=r\sin\theta.
\]

Jacobian 行列式为

\[
\det
\begin{pmatrix}
\cos\theta&-r\sin\theta\\
\sin\theta&r\cos\theta
\end{pmatrix}
=r(\cos^2\theta+\sin^2\theta)=r.
\]

所以面积元为 \(dx\,dy=r\,dr\,d\theta\)。单位圆盘面积为

\[
\int_0^{2\pi}\int_0^1r\,dr\,d\theta=\pi.
\]

二维标准高斯归一化也立即得到：

\[
\int_{\mathbb R^2}e^{-(x^2+y^2)/2}\,dx\,dy
=\int_0^{2\pi}\int_0^\infty e^{-r^2/2}r\,dr\,d\theta
=2\pi.
\]

由于二维积分可以写成两个一维高斯积分的平方，

\[
\left(\int_{\mathbb R}e^{-x^2/2}dx\right)^2=2\pi,
\]

故一维标准正态归一化常数为 \(1/\sqrt{2\pi}\)。

三维球坐标按程序中的坐标顺序写为

\[
x=r\sin\phi\cos\theta,\quad
y=r\sin\phi\sin\theta,\quad
z=r\cos\phi,
\]

其中 \(0\le\phi\le\pi\)。Jacobian 行列式为 \(r^2\sin\phi\)，所以单位球体积为

\[
\int_0^{2\pi}\int_0^\pi\int_0^1r^2\sin\phi\,dr\,d\phi\,d\theta
=\frac{4\pi}{3}.
\]

Python 和 Julia 分别用符号 Jacobian、中心差分核对 \(r\) 与 \(r^2\sin\phi\)：

```python
J_polar = sp.Matrix([r * sp.cos(th), r * sp.sin(th)]).jacobian([r, th])
assert sp.simplify(J_polar.det() - r) == 0
J_sph = sp.Matrix([
    r * sp.sin(ph) * sp.cos(th),
    r * sp.sin(ph) * sp.sin(th),
    r * sp.cos(ph)]).jacobian([r, ph, th])
assert sp.simplify(J_sph.det() - r**2 * sp.sin(ph)) == 0
```

## 18.6 Gamma–Beta 变换：和与比例独立

设

\[
X\sim\Gamma(a,1),\qquad Y\sim\Gamma(b,1),
\]

且二者独立。它们的联合密度（速率参数为 1）为

\[
f_{X,Y}(x,y)
=\frac{x^{a-1}e^{-x}}{\Gamma(a)}
 \frac{y^{b-1}e^{-y}}{\Gamma(b)},
\qquad x,y>0.
\]

令

\[
U=X+Y,\qquad V=\frac{X}{X+Y}.
\]

逆映射为

\[
X=UV,\qquad Y=U(1-V),
\]

其中 \(u>0,0<v<1\)。Jacobian 行列式为

\[
\det
\begin{pmatrix}
v&u\\
1-v&-u
\end{pmatrix}
=-u,
\]

绝对值为 \(u\)。于是

\[
\begin{aligned}
f_{U,V}(u,v)
&=f_{X,Y}(uv,u(1-v))u\\
&=\frac{u^{a+b-1}e^{-u}}{\Gamma(a+b)}
 \cdot
 \frac{\Gamma(a+b)}{\Gamma(a)\Gamma(b)}
 v^{a-1}(1-v)^{b-1}.
\end{aligned}
\]

它恰好分解为

\[
f_U(u)=\frac{u^{a+b-1}e^{-u}}{\Gamma(a+b)}
\]

与

\[
f_V(v)=\frac{v^{a-1}(1-v)^{b-1}}{B(a,b)}
\]

的乘积。因此：

1. \(U=X+Y\sim\Gamma(a+b,1)\)；
2. \(V=X/(X+Y)\sim\operatorname{Beta}(a,b)\)；
3. \(U\) 与 \(V\) 独立。

Python 符号程序验证变换后联合密度与目标乘积之比恒为 1：

```python
xx = uu * v01
yy = uu * (1 - v01)
Jgb = sp.Matrix([xx, yy]).jacobian([uu, v01])
assert sp.simplify(Jgb.det() + uu) == 0
fuv = fxy * uu
target = (uu ** (a + b - 1) * sp.exp(-uu) / sp.gamma(a + b)) * (
    v01 ** (a - 1) * (1 - v01) ** (b - 1)
    * sp.gamma(a + b) / (sp.gamma(a) * sp.gamma(b)))
assert sp.simplify(fuv / target) == 1
```

Julia 用整数形状 Gamma 变量（独立指数变量之和）审计 \(V\sim\operatorname{Beta}(2,3)\)：

```julia
Ga = gam(2, 100_000); Gb = gam(3, 100_000)
S = Ga .+ Gb; V = Ga ./ S
@assert abs(mean(V) - 2 / 5) < 0.005
@assert abs(cor(S, V)) < 0.01
@assert abs(var(V) - (2 * 3) / (5^2 * 6)) < 0.003
```

样本相关性接近 0 只是独立性的经验线索；密度因子分解才是证明。

## 18.7 多对一变换：\(U=X^2\) 与 \(\chi^2_1\)

设 \(X\sim N(0,1)\)，令 \(U=X^2\)。对每个 \(u>0\)，有两个原像：

\[
x=\sqrt u,\qquad x=-\sqrt u.
\]

由逆函数 \(x=\pm\sqrt u\) 得

\[
\left|\frac{dx}{du}\right|=\frac1{2\sqrt u}.
\]

两个分支贡献相同，因此

\[
\begin{aligned}
f_U(u)
&=2\frac{e^{-u/2}}{\sqrt{2\pi}}\frac1{2\sqrt u}\\
&=\frac{u^{-1/2}e^{-u/2}}{\sqrt{2\pi}}.
\end{aligned}
\]

因为 \(\Gamma(1/2)=\sqrt\pi\)，这正是

\[
\chi^2_1=\Gamma\left(\frac12,\frac12\right)
\]

的密度。若只取正根一个分支，总质量只有 \(1/2\)。程序明确检查这一点，防止漏掉分支：

```python
fU = sp.simplify(2 * phi(sp.sqrt(uq)) / (2 * sp.sqrt(uq)))
assert sp.simplify(
    fU - uq ** sp.Rational(-1, 2) * sp.exp(-uq / 2) / sp.sqrt(2 * sp.pi)) == 0
assert sp.simplify(sp.integrate(fU / 2, (uq, 0, sp.oo)) - sp.Rational(1, 2)) == 0
```

离散变量没有 Jacobian，但多对一变换同样要把原像质量相加。Prolog 的两骰例子展示了这一原则。

## 18.8 次序统计量与离散 \((\min,\max)\)

### 18.8.1 连续次序统计量

设 \(X_1,\dots,X_n\) iid，具有 CDF \(F\) 和密度 \(f\)。第 \(k\) 次序统计量 \(X_{(k)}\) 的密度为

\[
\boxed{
f_{X_{(k)}}(x)
=
\frac{n!}{(k-1)!(n-k)!}
F(x)^{k-1}(1-F(x))^{n-k}f(x).
}
\]

理由是：在微小区间 \([x,x+dx)\) 中恰有一个观测，\(k-1\) 个观测在 \(x\) 左侧，\(n-k\) 个在右侧；多项式系数给出排列数，三个概率分别为

\[
f(x)\,dx,\quad F(x)^{k-1},\quad (1-F(x))^{n-k}.
\]

若原始分布为 \(U(0,1)\)，则

\[
X_{(k)}\sim\operatorname{Beta}(k,n-k+1),
\]

所以

\[
E[X_{(k)}]=\frac{k}{n+1}.
\]

最小值与最大值的联合密度为

\[
f_{a,b}(a,b)=n(n-1)(b-a)^{n-2}f(a)f(b),\qquad a<b.
\]

对均匀分布，\(f(a)f(b)=1\)。Python 从 CDF

\[
F_{A,B}(a,b)=b^n-(b-a)^n
\]

连续求两个偏导得到 \(n(n-1)(b-a)^{n-2}\)：

```python
Fmm = bb**n - (bb - aa) ** n
assert sp.simplify(
    sp.diff(Fmm, aa, bb) - n * (n - 1) * (bb - aa) ** (n - 2)) == 0
```

对 \(n\) 个独立 \(\operatorname{Exp}(1)\) 变量，最小值的生存函数为

\[
P(\min_iX_i>t)=P(X_1>t,\dots,X_n>t)=e^{-nt},
\]

故 \(\min_iX_i\sim\operatorname{Exp}(n)\)。

### 18.8.2 两骰的离散 \((\min,\max)\)

令两个公平骰子为 \(D_1,D_2\)，变换为

\[
L=\min(D_1,D_2),\qquad H=\max(D_1,D_2).
\]

当 \(l<h\) 时，原像有两个：\((l,h)\) 与 \((h,l)\)，所以概率为 \(2/36\)。当 \(l=h\) 时，原像只有一个，概率为 \(1/36\)。共 21 个像点。

Prolog 枚举 36 个等可能结果：

```prolog
image_mass(Map, Image, Mass) :-
    findall(Image, (pair(X, Y), call(Map, X, Y, Image)), Imgs0),
    sort(Imgs0, Imgs),
    member(Image, Imgs),
    aggregate_all(count, (pair(X, Y), call(Map, X, Y, Image)), Cnt),
    Mass is Cnt rdiv 36.
```

它检查 \((\min,\max)\) 的 21 个像点总质量为 1，而线性变换

\[
(S,D)=(X+Y,X-Y)
\]

在整数骰子空间上是一一对应，所以有 36 个像点，每个质量 \(1/36\)。这个对比清楚显示：Jacobian 处理连续空间的体积，离散变换处理原像个数；两者的共同原则都是“质量守恒”。

## 18.9 Box–Muller 变换

若 \(U_1,U_2\) 独立且均匀于 \((0,1)\)，定义

\[
R=\sqrt{-2\log U_1},\qquad \Theta=2\pi U_2,
\]

\[
X=R\cos\Theta,\qquad Y=R\sin\Theta.
\]

则 \(X,Y\) 是独立标准正态变量。

其证明可用极坐标反向观察。若 \((X,Y)\) 是二维标准正态，则半径平方 \(R^2=X^2+Y^2\) 独立于角度 \(\Theta\)，且

\[
P(R^2>t)=e^{-t/2},\qquad \Theta\sim U(0,2\pi).
\]

因此 \(R^2\) 是速率为 \(1/2\) 的指数变量。逆变换采样给出 \(R^2=-2\log U_1\)，角度给出 \(\Theta=2\pi U_2\)。

Python 检查逆映射的 Jacobian 绝对值如何把均匀密度 \(1\) 变成二维高斯密度：

```python
Jbm = sp.Matrix([ub, vb]).jacobian([xb, yb])
dens = sp.simplify(Jbm.det())
assert sp.simplify(
    dens ** 2 - (sp.exp(-(xb**2 + yb**2) / 2) / (2 * sp.pi)) ** 2) == 0
```

Julia 用固定种子样本核对均值、方差、零相关、四阶矩和径向尾概率：

```julia
R = sqrt.(-2 .* log.(U1)); Θ = 2π .* U2
X = R .* cos.(Θ); Y = R .* sin.(Θ)
@assert abs(mean(X)) < 0.01 && abs(var(X) - 1) < 0.02
@assert abs(cor(X, Y)) < 0.01
@assert abs(mean(X .^ 4) - 3) < 0.1
for t in (1.0, 2.0, 4.0)
    @assert abs(mean(X .^ 2 .+ Y .^ 2 .> t) - exp(-t / 2)) < 0.005
end
```

这里的模拟不是 Box–Muller 的证明；Jacobian 与极坐标分解才是证明。

## 18.10 数值 Jacobian 与符号 Jacobian 的分工

`examples/julia/18_multivariate_transformations.jl` 的中心差分

\[
\frac{\partial f_i}{\partial x_j}(p)
\approx
\frac{f_i(p+he_j)-f_i(p-he_j)}{2h}
\]

是二阶精度近似。它适合检查代码是否把变换写反、变量顺序是否搞错，例如：

- 极坐标应返回 \(r\)；
- 球坐标应返回 \(r^2\sin\phi\)；
- 积变换逆映射应返回 \(1/|v|\)；
- 商变换逆映射应返回 \(|v|\)。

但数值差分不是解析证明。SymPy 的符号 Jacobian、Lean 的行列式恒等式和 Prolog 的离散原像枚举提供精确侧；Julia 模拟提供实现侧。二者结合能同时抓住数学错误和代码错误。

## 18.11 使用定理的条件

使用多元变量变换公式时，应检查以下条件：

1. **维度相同**：变换前后随机向量维度一致；辅助变量法要补满维度。
2. **局部可逆**：连续可微且 Jacobian 行列式非零；行列式为零的低维集通常可单独处理。
3. **分区一一对应**：整体不是一一映射时，划分为若干可逆分支，密度按分支求和。
4. **支撑同步变换**：原变量的合法区域必须映到新变量的支撑；漏掉支撑是变量变换中最常见的错误。
5. **积分换元合法**：密度非负且在新支撑上可积；边界、分段边界通常测度为零。
6. **辅助变量最终积掉**：联合密度中的辅助变量不能残留在边际密度中。

例如商变换要求 \(Y\ne0\)，但连续变量中 \(P(Y=0)=0\)，不影响密度；积变换要在 \(W=0\) 外分区域积分；\(X^2\) 必须加正负两个分支。

## 18.12 本章要点

1. 多元变量变换的密度多一个 Jacobian 行列式绝对值；线性变换时它就是面积或体积放大率。
2. 复合变换的 Jacobian 行列式相乘，这是 \(\det(AB)=\det A\det B\) 的概率版本。
3. 和、积、商变换通过补辅助变量形成一一映射，再积分掉辅助变量。
4. 独立指数变量的商具有 Logistic 型 CDF \(\lambda z/(\mu+\lambda z)\)；独立标准正态变量之商为 Cauchy。
5. Gamma–Beta 变换说明 Gamma 和 \(U=X+Y\) 与 Beta 比例 \(V=X/(X+Y)\) 独立。
6. 多对一变换必须枚举所有原像；\(X^2\) 的两个分支给出 \(\chi^2_1\)。
7. 连续次序统计量用一个观测落入小区间、其余观测分置两边推导；离散变换则累加原像质量。

*对应示例：`examples/lean/Probability/Ch18MultivariateTransformations.lean`、`examples/julia/18_multivariate_transformations.jl`、`examples/python/18_multivariate_transformations.py`、`examples/prolog/18_multivariate_transformations.pl`。*

---

上一章：[17 联合、边际与条件分布](17-joint-distributions.md) · 下一章：[19 协方差、相关与独立](19-covariance.md)
