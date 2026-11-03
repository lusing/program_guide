# 10 一元随机变量变换

已知 $X$ 的分布，真正关心的往往是收益率 $e^X-1$ 、损失 $|X|$ 、平方风险 $X^2$ 或标准化变量 $(X-\mu)/\sigma$ 。
本章从 CDF 出发推导一元变换公式，重点处理减函数的端点翻转、非单调函数的多支原像，以及原子在变换后的保留。

## 10.1 推前分布：先写事件，再谈密度

若 $Y=g(X)$ ，其分布由

$$
P(Y\in B)=P(X\in g^{-1}(B))
$$

决定，称为 $X$ 分布在 $g$ 下的推前。
CDF 因而为

$$
F_Y(y)=P(g(X)\le y).
$$

变换计算的第一步永远是把右边的不等式解成关于 $X$ 的事件。
不要一上来背密度公式；离散变量、混合变量和非单调情形下，CDF 法都更可靠。

例如 $X\sim U[0,2]$ ，$Y=X^2$ 。对 $0\le y\le4$ ，

$$
F_Y(y)=P(X^2\le y)=P(0\le X\le\sqrt y)=\frac{\sqrt y}{2}.
$$

所以

$$
f_Y(y)=F_Y'(y)=\frac1{4\sqrt y},\qquad0<y<4.
$$

密度在 0 附近发散并不矛盾，因为

$$
\int_0^4\frac1{4\sqrt y}\,dy=1.
$$

这是可积奇点：密度无限，面积仍有限。

## 10.2 严格增函数：直接复合 CDF

设 $g$ 在 $X$ 的支撑上严格增，反函数为 $h=g^{-1}$ 。
则

$$
F_Y(y)=P(X\le h(y))=F_X(h(y)).
$$

若 $X$ 有密度且 $h$ 可微，求导得

$$
\boxed{f_Y(y)=f_X(h(y))h'(y)}.
$$

这里 $h'(y)>0$ 。也可以写成

$$
f_Y(y)=\frac{f_X(h(y))}{|g'(h(y))|},
$$

因为 $g'(h(y))h'(y)=1$ 。

例：$X\sim U[0,1]$ ，$Y=a+bX$ ，其中 $b>0$ 。
反函数 $h(y)=(y-a)/b$ ，所以 $Y$ 在 $[a,a+b]$ 上密度为 $1/b$ 。
线性变换只移动和缩放坐标，概率密度按尺度倒数变化。

## 10.3 严格减函数：绝对值来自事件翻转

若 $g$ 严格减，则 $g(X)\le y$ 等价于 $X\ge h(y)$ ，因此

$$
F_Y(y)=P(X\ge h(y))=1-F_X(h(y))+P(X=h(y)).
$$

若 $X$ 有密度，单点项为零，求导得

$$
f_Y(y)=-f_X(h(y))h'(y).
$$

减函数的 $h'(y)<0$ ，所以与增函数统一为

$$
\boxed{f_Y(y)=f_X(h(y))\,|h'(y)|}.
$$

绝对值不是形式修补，而是区间端点翻转的结果。

例：$X\sim U[0,1]$ ，$Y=3-2X$ 。
反函数 $h(y)=(3-y)/2$ ，支撑变为 $[1,3]$ ，且

$$
f_Y(y)=1\cdot\left|-\frac12\right|=\frac12.
$$

直接看 CDF 也一样：

$$
P(Y\le2)=P(3-2X\le2)=P(X\ge1/2)=1/2.
$$

若忘了翻转，会把左尾误写成右尾，甚至得到负密度。

## 10.4 非单调变换：每个原像都要贡献

若同一个 $y$ 有多个原像 $x_i=h_i(y)$ ，且在每个分支上满足单调可微条件，则

$$
\boxed{f_Y(y)=\sum_i f_X(h_i(y))\,|h_i'(y)|}.
$$

求和对应互斥事件 $\{X\text{ 落在第 }i\text{ 支}\}$ 的概率相加。
只取正根或只取一支，通常会丢掉一半质量。

例：$X\sim U[-1,1]$ ，$Y=X^2$ 。
对 $0<y<1$ ，原像为 $\pm\sqrt y$ ，故

$$
F_Y(y)=P(-\sqrt y\le X\le\sqrt y)=\sqrt y.
$$

于是

$$
f_Y(y)=\frac1{2\sqrt y}.
$$

两个分支各贡献 $1/(4\sqrt y)$ 。
这与 10.1 的例子不同：那里 $X$ 只取非负值，只有一支。

离散非单调变换更简单，直接合并值即可。
若 $X$ 等可能取 $-2,-1,0,1,2$ ，则 $Y=X^2$ 的 pmf 为

$$
P(Y=0)=1/5,\quad P(Y=1)=2/5,\quad P(Y=4)=2/5.
$$

这里不存在“密度乘 Jacobian”的必要；把同一像的原像概率相加就是全部。

## 10.5 原子和混合型：密度公式只管连续部分

若 $P(X=x_0)>0$ ，则

$$
P(Y=g(x_0))\ge P(X=x_0)>0.
$$

因此变换后的分布仍可能有原子。
例如第 08 章的混合型 $X$ 在 0 有质量 $1/2$ ，令 $Y=X^2$ ，则

$$
P(Y=0)=P(X=0)=1/2.
$$

连续部分仍可逐支使用密度公式，但原子必须单独列出。
若在 0 的奇异点附近只对连续密度求导，再把结果当成整个分布，就会丢失一半总质量。

同理，把绝对连续变量通过分段常数函数压缩成离散值，会产生新的原子。
例如 $Y=\mathbf1_{\{X>0\}}$ 只取 0、1，其 pmf 由两个尾部概率给出。
推前分布可以改变命运类型，不必保持“连续”或“离散”。

## 10.6 逆变换采样与广义逆

设 $U\sim U[0,1]$ 。若 $F$ 严格增且连续，令 $X=F^{-1}(U)$ ，则对 $0<u<1$ ，

$$
P(X\le F^{-1}(u))=P(U\le u)=u,
$$

所以 $X$ 的 CDF 就是 $F$ 。
更一般地，使用左连续广义逆

$$
F^-(u)=\inf\{x:F(x)\ge u\},
$$

同一结论仍成立。跳点会对应一段 $u$ 都映到同一个原子，平坦段则对应值域空隙。

对 $F(x)=x^2$ （$0\le x\le1$ ），有 $X=\sqrt U$ 。
这给出密度 $2x$ 的采样器。
对第 08 章混合 CDF，广义逆可写成

$$
F^-(u)=
\begin{cases}
0,&0<u\le1/2,\\
2(u-1/2),&1/2<u<1.
\end{cases}
$$

前半段均匀随机数全部映到 0，恰好生成质量 $1/2$ 的原子。
逆变换不仅是采样技巧，也是“任意 CDF 都能实现为随机变量”的构造工具。

## 10.7 与 LOTUS 的对账

变换密度和原空间期望必须一致。
对 $X\sim U[0,2]$ 、$Y=X^2$ ，原空间 LOTUS 给出

$$
E[Y]=E[X^2]=\int_0^2x^2\frac12\,dx=\frac43.
$$

变换侧则为

$$
E[Y]=\int_0^4y\frac1{4\sqrt y}\,dy
=\left.\frac{y^{3/2}}6\right|_0^4=\frac43.
$$

若两条路结果不同，通常不是期望出了问题，而是变换时漏分支、漏绝对值或写错支撑。
这个对账习惯在多元 Jacobian 中更加重要。

## 10.8 机器通道：精确 CDF 与固定种子对拍

Python 文件 `examples/python/10_transformations.py` 用完全平方点避免浮点误判：

```python
for y, root in ((Fraction(1, 4), Fraction(1, 2)),
                (Fraction(1), Fraction(1)),
                (Fraction(9, 4), Fraction(3, 2)),
                (Fraction(4), Fraction(2))):
    assert root * root == y
```

这些断言固定 $F_Y(y)=\sqrt y/2$ 在四个点的值。
完全平方选择让平方根账保持有理数，不把数值舍入当成数学等式。

多支反函数的检查为：

```python
y = Fraction(1, 4)
branch = Fraction(1, 2) / (4 * Fraction(1, 2))
assert 2 * branch == Fraction(1, 2) / (2 * Fraction(1, 2))
```

`branch` 是 $1/(4\sqrt y)$ 在 $y=1/4$ 的值；乘 2 明确记录两个原像。
文件还检查减函数端点和混合原子。

Julia 文件 `examples/julia/10_transformations.jl` 固定种子生成样本，并以精确 CDF 为目标：

```julia
S = 2 .* rand(400_000) .- 1
Q = S .^ 2
for y in (0.04, 0.25, 0.64)
    empirical = count(<=(y), Q) / length(Q)
    @assert abs(empirical - sqrt(y)) < 0.005
end
```

`S` 均匀于 $[-1,1]$ ，`Q` 是平方变换。
目标 $\sqrt y$ 来自两分支 CDF；模拟频率只是复现性数值审计。

Lean 文件 `examples/lean/Probability/Ch10Transformations.lean` 证明关键平方根和分支算术：

```lean
example : Real.sqrt (1 / 4 : ℝ) = 1 / 2 := by
  rw [show (1 / 4 : ℝ) = (1 / 2) ^ 2 by norm_num]
  exact Real.sqrt_sq (by norm_num)
```

证明先把 $1/4$ 重写为 $(1/2)^2$ ，再使用非负数的平方根定理。
另一组 `norm_num` 定理固定两个密度分支之和，防止只算正根。

## 10.9 本章要点

1. 变换分布首先由 $P(Y\le y)=P(g(X)\le y)$ 决定，CDF 法最通用。
2. 单调可微时 $f_Y(y)=f_X(h(y))|h'(y)|$ ，绝对值处理减函数翻转。
3. 非单调变换必须对所有原像分支求和，支撑也要同步改变。
4. 原子在推前后仍是原子；普通密度公式只处理绝对连续部分。
5. 广义逆 $F^-(U)$ 同时适用于连续、离散和混合 CDF。
6. 变换后的期望应与原空间 LOTUS 对账；模拟不替代公式推导。

*对应示例：`examples/lean/Probability/Ch10Transformations.lean`、
`examples/julia/10_transformations.jl`、
`examples/python/10_transformations.py`。*

---

上一章：[09 数学期望、矩、分位数与风险](09-expectation.md) · 下一章：[11 概率不等式与矩的界限](11-inequalities.md)
