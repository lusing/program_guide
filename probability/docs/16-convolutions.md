# 16 卷积与微分恒等式

卷积回答“独立随机变量之和如何分布”，微分恒等式回答“怎样从一条归一化等式量产整列矩公式”。两者都体现同一策略：不要逐个硬算，而是先找到结构。卷积把独立和变成可分组运算，参数求导则把已知恒等式变成一条生产线。

本章将明确标出换序条件。有限和求导没有分析问题；无穷级数和广义积分则必须有一致收敛、支配函数或其他可交换条件。

## 16.1 离散卷积

设 $X,Y$ 独立且取整数值。事件 $X+Y=z$ 可按 $X=t$ 分解为互斥事件，因此

$$P(X+Y=z)=\sum_tP(X=t,Y=z-t).$$

独立性把联合概率分解为乘积，得到

$$\boxed{ P(X+Y=z)=\sum_tP(X=t)P(Y=z-t). }$$

求和遍历所有使两项有定义的整数 $t$ ；有限支撑时自然只有有限项。这个公式不要求同分布，也不要求支撑从 0 开始。

`examples/python/16_convolutions.py` 把字典中不存在的概率视为 0：

```python
def convolve_discrete(f, g, z):
    return sum(p * g.get(z - t, Fraction(0)) for t, p in f.items())
```

代码逐项实现的就是公式。`Fraction` 保证有限有理概率相加时没有舍入误差。

两枚公平骰子的 pmf 在每个点数上为 $1/6$ ，所以

$$P(X+Y=z)=\frac{\#\{(a,b):1\le a,b\le6,\ a+b=z\}}{36}.$$

例如 $z=8$ 时，可行点为 $(2,6),(3,5),(4,4),(5,3),(6,2)$ ，概率为 $5/36$ 。程序同时做卷积和 36 格全枚举：

```python
f2 = {z: convolve_discrete(die, die, z) for z in range(2, 13)}
...
assert f2 == enum2
assert f2[8] == Fraction(5, 36)
```

两种路径一致，既验证公式实现，也验证枚举实现；任何一个共同总数都不足以替代逐点比较。

## 16.2 连续卷积

设 $X,Y$ 独立，分别有密度 $f_X,f_Y$ 。联合密度为 $f_X(x)f_Y(y)$ 。对和 $Z=X+Y$ ，

$$P(Z\le z)=\iint_{x+y\le z}f_X(x)f_Y(y)\,dx\,dy.$$

先对区域作 $y\le z-x$ 的内层积分：

$$F_Z(z)=\int_{-\infty}^{\infty}f_X(x)F_Y(z-x)\,dx.$$

在允许对 $z$ 求导并交换导数与积分的条件下，

$$\boxed{ f_Z(z)=(f_X*f_Y)(z) =\int_{-\infty}^{\infty}f_X(x)f_Y(z-x)\,dx. }$$

等价地，也可写为 $\int f_X(z-y)f_Y(y)dy$ 。非负性使许多 Tonelli 换序合法，但得到密度时仍需通常的积分求导条件；若只知分布函数，不必强行假设密度存在。

### 两个均匀分布的和

若 $X,Y\sim U[0,1]$ 独立，则被积函数只有在

$$0\le x\le1,\qquad0\le z-x\le1$$

时非零。第二个条件等价于 $z-1\le x\le z$ ，所以实际积分限是

$$\max(0,z-1)\le x\le\min(1,z).$$

当 $0\le z\le1$ 时积分长度为 $z$ ；当 $1\le z\le2$ 时长度为 $2-z$ 。因此

$$f_Z(z)= \begin{cases} z,&0\le z\le1,\\ 2-z,&1\le z\le2,\\ 0,&\text{其他}. \end{cases}$$

直接套“从 0 积到 1”会丢失支撑随 $z$ 改变这一关键。Python 用分段原函数检查区间概率：

```python
def tri_cdf(z):
    if z <= -1:
        return Fraction(0)
    if z < 0:
        return Fraction(1, 2) + z + z * z / 2
    if z <= 1:
        return Fraction(1, 2) + z - z * z / 2
    return Fraction(1)
```

这里的三角密度来自两个 $U[-1/2,1/2]$ ，支撑为 $[-1,1]$ ，密度是 $1-|z|$ 。程序检查 $F(1)=1$ 和 $P(1/4\le Z\le1/2)=5/32$ ，与前一例的平移版本相互一致。

## 16.3 分组：四骰不必直接枚举起手

卷积满足结合律。对独立变量，

$$f_{X_1+\cdots+X_4}=(f_{X_1}*f_{X_2})*(f_{X_3}*f_{X_4}).$$

四骰和因此可以先算两骰分布 $f_2$ ，再计算 $f_4=f_2*f_2$ ，不必一开始处理 $6^4=1296$ 个结果。

代码正是这样分组：

```python
f4 = {z: convolve_discrete(f2, f2, z) for z in range(4, 25)}
...
assert f4 == enum4
assert all(f4[z] == f4[28 - z] for z in range(4, 25))
```

这里 $f_4(6)=10/1296$ 。最后的对称性来自：若单骰点数为 $X$ ，则 $7-X$ 同分布，所以四骰和 $S$ 与 $28-S$ 同分布。

分组的收益不只是减少循环。对于 $2^m$ 个同分布独立变量，可以反复执行 $f_{2n}=f_n*f_n$ ，把卷积层数降为对数级。第 15 章的生成函数乘幂与这里的分组是同一结合结构的两种表示。

Julia 文件 `examples/julia/16_convolutions.jl` 另用固定种子模拟检查频率形状；精确结论来自 `Fraction` 卷积与完整枚举，而不是模拟。两骰的三角形公式与四骰的 $f_2*f_2$ 分别对 50 万次抽样的频率作对拍：

```julia
tri2(z) = 2 <= z <= 7 ? (z - 1) / 36 : (7 < z <= 12 ? (13 - z) / 36 : 0.0)
sums2 = [rand(1:6) + rand(1:6) for _ in 1:500_000]
for z in 2:12
    emp = count(==(z), sums2) / length(sums2)
    @assert abs(emp - tri2(z)) < 0.005
end
```

连续情形同样如此：两个 $U[-1/2,1/2]$ 之和的密度是 $1-|z|$ ，对区间 $[0,\tfrac14],[\tfrac14,\tfrac12],[\tfrac12,\tfrac34]$ 积分 $z-z^2/2$ 的差即理论频率。文件后半的指数商 $Z=X/Y$ 检验两件事：CDF $t/(1+t)$ 与 $\lambda$ 无关（$\lambda=1,5$ 的经验分布重合），而样本均值前后两半相差很大，因为 $E[Z]=\infty$ ，没有大数定律。

## 16.4 微分恒等式：从归一化到矩

设已知一族恒等式

$$\sum_n h(n;\alpha)=g(\alpha).$$

若可在参数 $\alpha$ 下交换求和与求导，则

$$\sum_n\frac{\partial h}{\partial\alpha}(n;\alpha)=g'(\alpha).$$

对积分族 $\int h(x;\alpha)dx=g(\alpha)$ 同理。有限和总是可以直接求导；无穷和常用条件是局部一致收敛或找到与 $n$ 无关的可和支配界；积分常用控制收敛的导数版本，即在参数邻域内用一个可积函数控制差商。

“形式求导后数值看起来对”不是换序合法性的证明。

## 16.5 几何级数：$x\,d/dx$ 保持幂次

从

$$\sum_{n=0}^{\infty}x^n=\frac1{1-x},\qquad|x|<1$$

出发。对任意 $r<1$ ，级数及其导数级数在 $|x|\le r$ 上一致收敛，所以可逐项求导。使用算子 $x\,d/dx$ ，有

$$\sum_{n=1}^{\infty}nx^n=\frac{x}{(1-x)^2}.$$

再作用一次：

$$\sum_{n=1}^{\infty}n^2x^n=\frac{x(1+x)}{(1-x)^3}.$$

代入 $x=1/2$ ，得到

$$\sum_{n=1}^{\infty}\frac n{2^n}=2, \qquad \sum_{n=1}^{\infty}\frac{n^2}{2^n}=6.$$

相比裸算子 $d/dx$ ，$x\,d/dx$ 不把 $x^n$ 降为 $x^{n-1}$ ，账面更整齐。

`examples/python/16_convolutions.py` 的 ⑥–⑩ 节（原先独立的矩脚本已并入）精确检查截断尾：

```python
assert sum(Fraction(n, 2 ** n) for n in range(1, 11)) == Fraction(509, 256)
assert Fraction(2) - Fraction(509, 256) == Fraction(3, 256)
```

前 10 项之和距极限恰为 $3/256$ 。截断等式是有限有理数证明，无穷极限则由上面的级数公式给出。

Lean 文件 `examples/lean/Probability/Ch16Convolutions.lean` 用 `norm_num` 固定同一账目：

```lean
example : (2 : ℚ) - 509 / 256 = 3 / 256 := by norm_num
example : (6 : ℚ) - 717 / 128 = 51 / 128 := by norm_num
```

第二笔是 $n^2/2^n$ 的前 8 项尾差，说明加入更高次多项式权重后，同样项数的尾部衰减会变慢。

## 16.6 二项分布：参数必须保持自由

从二项定理

$$\sum_{k=0}^n\binom nkp^kq^{n-k}=(p+q)^n$$

出发，先**把 $p,q$ 当作独立变量**。作用 $p\,\partial/\partial p$ ，得到

$$\sum_{k=0}^nk\binom nkp^kq^{n-k} =np(p+q)^{n-1}.$$

最后才令 $q=1-p$ ，便有 $E[X]=np$ 。

若一开始就代入 $q=1-p$ ，右侧变成常数 1，左侧也变成归一化常数 1；求导只会得到 $0=0$ ，矩的信息全部消失。

再作用一次该算子：

$$\sum_k k^2\binom nkp^kq^{n-k} =np(p+q)^{n-1}+n(n-1)p^2(p+q)^{n-2}.$$

所以

$$E[X^2]=np+n(n-1)p^2, \qquad \operatorname{Var}(X)=np(1-p).$$

Python 用完整 pmf 独立求和检查 $n=5,p=1/3$ ：

```python
assert E1 == Fraction(5, 3) == n * p
assert E2 == Fraction(35, 9) == n * p + n * (n - 1) * p * p
assert E2 - E1 * E1 == Fraction(10, 9) == n * p * (1 - p)
```

令 $p=q=1/2$ 还能回收组合恒等式

$$\sum_k k\binom nk=n2^{n-1}, \qquad \sum_k k^2\binom nk=n(n+1)2^{n-2}.$$

概率参数求导因此也能证明纯计数命题。

## 16.7 正态偶矩：预补偿求导带下的幂次

对尺度为 $\sigma$ 的中心正态密度，把归一化写成

$$\sigma=\int_{-\infty}^{\infty}\frac1{\sqrt{2\pi}} e^{-x^2/(2\sigma^2)}dx.$$

对 $\sigma$ 求导会在积分内带下 $x^2\sigma^{-3}$ 。因此使用

$$\sigma^3\frac{d}{d\sigma}$$

恰好补偿这个负幂。定义

$$I(2m;\sigma)=\int_{-\infty}^{\infty}x^{2m} \frac1{\sqrt{2\pi}}e^{-x^2/(2\sigma^2)}dx.$$

逐次作用得到

$$I(2;\sigma)=\sigma^3, \qquad I(4;\sigma)=3\sigma^5, \qquad I(6;\sigma)=15\sigma^7,$$

归纳即

$$I(2m;\sigma)=(2m-1)!!\sigma^{2m+1}.$$

除以标准密度归一化中的 $\sigma$ ，得到

$$E[X^{2m}]=(2m-1)!!\sigma^{2m}.$$

这里高斯衰减为积分求导交换提供控制。同文件 ⑨ 节对前六个偶矩用确定性积分审计递推，Lean 则固定

```lean
example : 15 = 5 * 3 ∧ 105 = 7 * 15 ∧ 945 = 9 * 105 := by norm_num
example (σ : ℚ) : 15 * σ ^ 7 = 5 * (3 * σ ^ 5) * σ ^ 2 := by ring
```

第二式直接检查“求导后再乘 $\sigma^3$ ”的幂次补偿。

## 16.8 指数矩：另一组预补偿因子

采用均值尺度 $\lambda>0$ 的指数密度，归一化等价于

$$\lambda=\int_0^\infty e^{-x/\lambda}dx.$$

求导会带下 $x/\lambda^2$ ，故作用 $\lambda^2d/d\lambda$ ：

$$\lambda^2=\int_0^\infty xe^{-x/\lambda}dx.$$

重复这一操作并除以适当的 $\lambda$ ，得到

$$E[X^k]=k!\lambda^k.$$

这与 $\Gamma(k+1)=k!$ 是同一积分的两种记账方式。程序在 $\lambda=2$ 时审计前五阶矩，解析结论则由上述恒等式给出。

## 16.9 Julia：微分恒等式的样本对拍

`examples/julia/16_convolutions.jl` 后半的 ⑥–⑨ 节用模拟核对 16.4–16.8 的矩公式。二项变量用 $n$ 次伯努利试验生成，二阶矩公式 $np(1-p)$ 由方差对拍；正态偶矩用 `cumprod` 生成 $(2k-1)!!$ ：

```julia
B = sim_binom_counts(10, 0.3, 1_000_000)
@assert abs(mean(B) - 3.0) < 0.01
@assert abs(var(B) - 2.1) < 0.015

G = randn(2_000_000)
dfacts = cumprod(2 .* (1:4) .- 1)          # [3, 15, 105, 945]
for k in 1:4
    @assert abs(mean(g -> g^(2k), G) - dfacts[k]) < 0.02 * dfacts[k]
end
```

指数矩 $E[X^k]=k!\lambda^k$ 由逆变换样本 $X=-\lambda\log U$ 检验：

```julia
Xs = -2.0 .* log.(rand(1_000_000))
for k in 1:4
    @assert abs(mean(x -> x^k, Xs) - factorial(k) * 2.0^k) < 0.03 * factorial(k) * 2.0^k
end
```

高阶样本矩的方差很大（$k$ 越高，容差越要放宽），所以这里取相对容差而不是绝对容差；这类对拍只能发现公式错误，不能替代 16.7 的求导交换论证。

## 16.10 本章要点

1. 离散卷积按一个变量取值分解事件；连续卷积由联合密度积分并在合法条件下求导得到。
2. 连续卷积最容易错在支撑：实际积分限是两个约束的交。
3. 卷积可结合、可分组；四骰用 $f_2*f_2$ 与 1296 格全枚举逐点对账。
4. 微分恒等式需要换序条件；有限和免费，无穷级数与积分必须有收敛控制。
5. 二项求导时 $p,q$ 要保持独立到最后；正态和指数分别用 $\sigma^3d/d\sigma$ 、$\lambda^2d/d\lambda$ 补偿幂次。
6. 精确截断、机器算术和数值积分是三种审计方式，不能相互冒充无穷定理的证明。

*对应示例：`examples/lean/Probability/Ch16Convolutions.lean`、`examples/julia/16_convolutions.jl`、`examples/python/16_convolutions.py`。*

---

上一章：[15 母函数、矩生成函数与特征函数](15-generating-functions.md) · 下一章：[17 联合、边际与条件分布](17-joint-distributions.md)
