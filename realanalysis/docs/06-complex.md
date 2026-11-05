# 第 06 章 复数与欧几里得空间

> 对应原书第 6 章。上一章把实数立成有序完备域。本章把舞台从直线
> 拉到平面：复数是带特殊乘法的二维实向量；同一套内积与范数再推广到
> 任意维欧几里得空间 $\mathbb{R}^k$ ，并给出 Cauchy–Schwarz。
> 后面拓扑与序列，很多命题会先在 $\mathbb{R}$ 上写一遍，再原样搬到
> $\mathbb{R}^k$ 或 $\mathbb{C}$ 。

## 6.1 为什么要在实分析里谈复数

复数名字里带着“虚”，另有一门叫复分析的学科——为什么实分析还要
管它？答案很朴素：若忘掉乘法，全体复数就是平面 $\mathbb{R}^2$ 。乘法
只是在这对有序对上额外规定的一种运算。一旦证明 $\mathbb{C}$ 是域、
摸清共轭与模，就会发现任意维实向量也有一套平行的内积与范数；那正是
欧几里得空间。

## 6.2 定义 6.1–6.2：$k$ 向量与复数

**定义 6.1.** 一个 $k$ 维向量是有序数组 $(x_1,\ldots,x_k)$ 。顺序要紧：
除非 $x_1=x_2$ ，否则 $(x_1,x_2)\ne(x_2,x_1)$ 。两个二维向量相等，当且
仅当对应分量都相等。

**定义 6.2.** 复数就是二维实向量，加法和乘法规定为

$$(a,b)+(c,d)=(a+c,\,b+d),\qquad (a,b)(c,d)=(ac-bd,\,ad+bc).$$

全体复数记作 $\mathbb{C}$ 。若暂时不管这两种运算，同一集合就是
$\mathbb{R}^2$ 。

与有理数的对比值得记住：有理数也常写成有序对，但 $(a,b)$ 与
$(c,d)$ 可以代表同一个数（通分）；复数则严格按分量相等来判等。
记号上还要和开区间划清：复数 $(-3,3)$ 是两个实数的对，开区间
$(-3,3)$ 是其间全体实数——上下文通常足够分辨。

乘法公式看起来突兀，动机来自 $a+bi$ 写法。令 $i=(0,1)$ ，则

$$i^2=(0,1)(0,1)=(-1,0)=-1,$$

于是

$$(a+bi)(c+di)=ac+adi+bci+bd\,i^2=(ac-bd)+(ad+bc)i,$$

恰好就是定义里的分量公式。形式为 $(a,0)$ 的复数在加减乘上与实数
$a$ 一致，所以 $\mathbb{R}$ 可以看成 $\mathbb{C}$ 的子域。

Lean（`examples/lean/Realanalysis/Ch06Complex.lean`）里 `Complex`
就是带实部、虚部的结构包装；`I` 是虚数单位：

```lean
example (z : ℂ) : Complex.mk z.re z.im = z := Complex.ext rfl rfl
example : I = Complex.mk 0 1 := rfl
example : I * I = -1 := I_mul_I
```

乘法展开用 `mul_re` / `mul_im`：

```lean
example (a b c d : ℝ) :
    (a + b * I) * (c + d * I) = (a * c - b * d) + (a * d + b * c) * I := by
  apply Complex.ext
  · simp [mul_re]
  · simp [mul_im]
```

Isabelle（`examples/isabelle/RA06/ComplexEuclidean.thy`）的
`i_sq`、`complex_mul_formula` 是同一组事实；Coq 通道因 Rocq 9.1
标准库删掉了 `Complex`，于是手工定义 `Record C`，用

```coq
Definition cmul (z w : C) : C :=
  mkC (cre z * cre w - cim z * cim w)
      (cre z * cim w + cim z * cre w).
```

再证 `c_i_squared : cmul cI cI = copp c1`。Agda 用 $\mathbb{Z}\times\mathbb{Z}$
作可计算的离散替身：`cmul` 同一公式，`i-squared` 与
`mul-example`（$(1+2i)(3+4i)=-5+10i$ ）都是定义性等式。

Julia / Python / Prolog 三条计算通道同样从有序对起步，全程
`Rational` 或精确整数，再与语言内置复数对照：

```python
assert cmul(C(0, 1), C(0, 1)) == C(-1, 0)
assert cmul(C(1, 2), C(3, 4)) == C(-5, 10)
assert (1 + 2j) * (3 + 4j) == -5 + 10j
```

## 6.3 定理 6.3：$\mathbb{C}$ 是域，但不是有序域

**定理。** $\mathbb{C}$ 是域。加法单位元 $(0,0)$ ，乘法单位元 $(1,0)$ ；
$(a,b)$ 的加法逆是 $(-a,-b)$ ；若 $(a,b)\ne(0,0)$ ，乘法逆是

$$\frac{1}{(a,b)}=\Bigl(\frac{a}{a^2+b^2},\,-\frac{b}{a^2+b^2}\Bigr).$$

证明逐条核验十一条域公理，每一步都把问题归结到 $\mathbb{R}$ 上同一
公理。乘法逆元那条展开后，实部变成 $(a^2+b^2)/(a^2+b^2)=1$ ，虚部
变成 $(-ab+ab)/(a^2+b^2)=0$ 。

Lean 直接声明 `Field ℂ` 实例（依赖实数的非可计算构造，故
`noncomputable`）。Coq 把逆元写出来并证 `c_mul_inv`：先由
`cnorm2_zero` 保证分母非零，再用 `field` 完成分量计算。计算通道的
`cinv` 断言 `z * (1/z) = 1`，例如 $1/(1+2i)=1/5-(2/5)i$ 。

$\mathbb{C}$ **不是**有序域：公理 O2 要求非零元的平方为正，但取
$x=(0,1)=i$ 时

$$x^2=(-1,0)=-1<0.$$

所以第 04、05 章里依赖序结构的推论（阿基米德、稠密、正根）不能原样
搬到 $\mathbb{C}$ ；后面用的是模与内积，而不是全序。

## 6.4 共轭、模与三角不等式

**定义 6.4.** $z=a+bi$ 的实部、虚部分别是 $\operatorname{Re}z=a$ 、
$\operatorname{Im}z=b$ ；共轭 $\overline{z}=a-bi$ 。

**定理 6.5** 给出四条：共轭对加法和乘法分配；
$z+\overline{z}=2\operatorname{Re}z$ ，
$z-\overline{z}=2i\operatorname{Im}z$ ；
$z\overline{z}=a^2+b^2\in\mathbb{R}$ ，且 $z\ne0$ 时为正。最后一条正是
逆元公式的来源：$z^{-1}=\overline{z}/(z\overline{z})$ 。

Lean：

```lean
example : conj I = -I := conj_I
example (z : ℂ) : z * conj z = normSq z := mul_conj z
example (a b : ℝ) : normSq (Complex.mk a b) = a ^ 2 + b ^ 2 := by
  rw [normSq_mk]; ring
```

Isabelle 的 `conj_norm_sq`、Coq 的 `c_mul_conj` 同一内容。

**定义 6.6.** $|z|$ 是 $z\overline{z}$ 的正平方根。对实数 $x$ ，共轭就是
自身，于是 $|x|=\sqrt{x^2}$ ，与第 05 章的绝对值一致。存在性依赖正数
有唯一正平方根（定理 5.8）。

**定理 6.7** 的五条里，最常用的是三角不等式
$|z+w|\le|z|+|w|$ 。证明先写

$$|z+w|^2=|z|^2+2\operatorname{Re}(\overline{z}w)+|w|^2 \le|z|^2+2|z||w|+|w|^2=(|z|+|w|)^2,$$

两端非负再开方。勾股样例 $|3+4i|=5$ 在各通道都有：Lean 用模平方
$25$ 与范数非负推出范数是 $5$ ；Isabelle `norm_3_4i`；Coq
`cnorm_34`；计算通道断言模平方等于 $25$ 。

## 6.5 定义 6.9–6.10：向量空间与欧几里得空间

**定义 6.9.** $\mathbb{R}^k$ 由全体 $k$ 维实向量构成，分量加法和数乘

$$x+y=(x_1+y_1,\ldots,x_k+y_k),\qquad \alpha x=(\alpha x_1,\ldots,\alpha x_k),$$

零向量 $(0,\ldots,0)$ 。它对这两种运算封闭，满足结合、交换、分配——
这是向量空间，不是域（两个向量一般不能相乘）。

**定义 6.10.** 内积与范数

$$x\cdot y=\sum_{i=1}^k x_i y_i,\qquad |x|=\Bigl(\sum_{i=1}^k x_i^2\Bigr)^{1/2}.$$

配上内积与范数的 $\mathbb{R}^k$ 叫 $k$ 维欧几里得空间。$\mathbb{R}$ 是实线，
$\mathbb{R}^2$ 是实平面；复数的模正是平面向量的欧氏范数。

Lean 用 `EuclideanSpace ℝ (Fin k)`（带 $2$ -范数的有限函数类型）：

```lean
abbrev R2 := EuclideanSpace ℝ (Fin 2)
example (x y : R2) : ⟪x, y⟫_ℝ = ∑ i : Fin 2, x i * y i := by
  simp only [PiLp.inner_apply, Real.inner_apply]
```

具体向量 $x=(1,2)$ 、$y=(3,4)$ 用 `WithLp.toLp 2 ![1, 2]` 装入；内积
$11$ ，范数平方 $5$ 与 $25$ 。Isabelle 的类型同义词 `R2 = real^2`，坐标
用 $\chi$ ，有限求和必须写 `(\<Sum>i\<in>(UNIV::2 set). …)`——裸的
`(\<Sum>i. …)` 会被解析成无限级数。Coq 用 `Record V2` 与 `dot2` /
`n2`；计算通道对列表做 `dot` / `n2`。

## 6.6 定理 6.8：Cauchy–Schwarz

对复数序列，原书写法带共轭：

$$\Bigl|\sum_{j=1}^n a_j\overline{b_j}\Bigr|^2 \le\Bigl(\sum_{j=1}^n |a_j|^2\Bigr) \Bigl(\sum_{j=1}^n |b_j|^2\Bigr).$$

把每个 $b_j$ 换成 $\overline{b_j}$ （仍任意），就得到不含共轭的常见形状。
实向量情形正是

$$|\langle x,y\rangle|^2\le|x|^2\,|y|^2.$$

### 二维：Lagrange 恒等式把缺口钉死

对 $u=(a,b)$ 、$v=(c,d)$ ，

$$|u|^2|v|^2-\langle u,v\rangle^2=(ad-bc)^2\ge0,$$

所以 $\langle u,v\rangle^2\le|u|^2|v|^2$ 。缺口是一个平方，不可能为负——
这就是二维 C-S 的全部几何：平行时行列式为零，等式成立。

样本 $(1,2)$ 与 $(3,4)$ ：$11^2=121\le5\cdot25=125$ ，差
$(1\cdot4-2\cdot3)^2=4$ 。Lean / Isabelle / Coq 都有 `lagrange_gap`；
Agda 用自然数样本 `sample-inner * sample-inner ≤ sample-nx * sample-ny`，
缺口 `125-121=4` 由 `m≤m+n` 给出。Julia / Python / Prolog 还验证一般
$n$ 维恒等式

$$|x|^2|y|^2-\langle x,y\rangle^2 =\sum_{i<j}(x_i y_j-x_j y_i)^2$$

（全体 $2\times2$ 子式平方和），并在五维向量上核对。

### 一般维：二次式非负

Coq 的 `cauchy_schwarz` 走分析教材常见路线：对任意实数 $t$ ，

$$\sum_i(a_i+t b_i)^2=A+2tC+t^2 B\ge0.$$

若 $B>0$ ，取 $t=-C/B$ ，最小值 $A-C^2/B\ge0$ ，即 $C^2\le AB$ ；若
$B=0$ ，则每个 $b_i=0$ ，从而 $C=0$ 。Lean / Isabelle 则直接调用库定理
`real_inner_mul_inner_self_le` / `Cauchy_Schwarz_ineq`。

三角不等式 $\|u+v\|\le\|u\|+\|v\|$ 是 C-S 的推论：展开
$\|u+v\|^2=\|u\|^2+2\langle u,v\rangle+\|v\|^2$ ，再用
$\langle u,v\rangle\le\|u\|\|v\|$ 。Lean 的 `norm_add_le`、Isabelle 的
`norm_triangle_ineq`、Coq 的 `triangle2d`、以及计算通道在 $\mathbb{R}^5$
上的数值断言，都是这件事。

## 6.7 七通道对照

| 主题 | Lean | Isabelle | Coq | Agda | 计算三通道 |
|------|------|----------|-----|------|------------|
| $i^2=-1$ 、乘法公式 | `I_mul_I`、分量 `ext` | `i_sq`、`complex_mul_formula` | 手工 `C` / `cmul` | $\mathbb{Z}\times\mathbb{Z}$ | 有序对 + 内置对照 |
| 共轭与模、$|3+4i|=5$ | `conj`、`normSq` | `cnj`、`norm_3_4i` | `cconj`、`cnorm_34` | — | `cnorm2==25` |
| 域 / 逆元 | `Field ℂ` | 库实例 | `cinv`、`c_mul_inv` | — | `cinv` 断言 |
| $\mathbb{R}^2$ 内积范数 | `EuclideanSpace` | `real^2` | `V2` | 样本点积 | 列表 `dot`/`n2` |
| C-S / Lagrange | 库定理 + 数值缺口 | 同上 | 二次式证明 + `cs2d` | 自然数缺口 | 二维与五维恒等式 |

## 6.8 本章验证清单

- `examples/lean/Realanalysis/Ch06Complex.lean`：$\mathbb{C}$ 的构造与
  乘法、共轭与模、$\mathbb{R}^2$ 内积范数、C-S、Lagrange 缺口、三角不等式。
- `examples/isabelle/RA06/ComplexEuclidean.thy`：同上，类型为
  `complex` 与 `real^2`。
- `examples/coq/Ch06_complex.v`：手工复数域片段、任意有限维
  `cauchy_schwarz`、二维 Lagrange 与三角不等式。
- `examples/agda/Ch06_complex.agda`：整数有序对乘法与自然数 C-S 样本。
- `examples/julia/06_complex.jl`、`examples/python/06_complex.py`、
  `examples/prolog/06_complex.pl`：精确有序对、内置对照、二维与五维
  Lagrange、三角不等式。

复验：`pwsh -NoProfile -Command '& ./build.ps1 -Chapter 06'`。

## 6.9 接下来

复数与 $\mathbb{R}^k$ 提供了后面度量与拓扑的舞台。但在谈开集、紧集之
前，先要能比较无限集的“大小”——下一章建立函数的单射、满射与双射，
为可数性做准备。

上一章：[05 实数域：完备性](05-completeness.md) · 下一章：[07 双射](07-bijections.md) · [返回目录](../README.md)
