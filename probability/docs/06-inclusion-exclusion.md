# 06 容斥与组合恒等式

容斥原理处理“至少有一个发生”的重叠账目。若直接把若干事件的概率相加，
重叠部分会被重复计算；容斥通过单交、双交、三交的交错加减，保证每个样本
点最终恰好被计算一次。本章先证明一般容斥公式，再把它用于错排和占位数问题，
最后把 Vandermonde、曲棍球棒和几个常用组合恒等式统一到“同一对象两种
计数”的方法中。

## 06.1 两个事件和三个事件

对两个事件，

\[
P(A\cup B)=P(A)+P(B)-P(A\cap B).
\]

只属于 \(A\) 或只属于 \(B\) 的点被计算一次，同时属于二者的点先被计算两次，
再减去一次。

对三个事件，公式变成

\[
\begin{aligned}
P(A\cup B\cup C)
={}&P(A)+P(B)+P(C)\\
&-P(A\cap B)-P(A\cap C)-P(B\cap C)\\
&+P(A\cap B\cap C).
\end{aligned}
\]

为什么三重交最后又要加回来？一个属于三个事件的点在第一行被加了三次，在
第二行被减了三次，总贡献暂时为零；它本来应贡献一次，所以最后要加一次。

本章的 Julia/Python 示例使用两骰空间的三个事件：

- \(A\)：第一枚骰子为 6；
- \(B\)：第二枚骰子为 6；
- \(C\)：两枚点数相同。

三个事件各含 6 个有序结果，三个双交各含 1 个结果，三重交也含 1 个结果，
所以

\[
|A\cup B\cup C|
=6+6+6-1-1-1+1=16,
\]

概率为 \(16/36\)。

## 06.2 一般容斥公式

设 \(A_1,\ldots,A_m\) 是同一有限样本空间中的事件。记

\[
S_r=\sum_{1\le i_1<\cdots<i_r\le m}
\left|A_{i_1}\cap\cdots\cap A_{i_r}\right|.
\]

则

\[
\left|A_1\cup\cdots\cup A_m\right|
=S_1-S_2+S_3-\cdots+(-1)^{m+1}S_m.
\]

概率版本为

\[
P\left(\bigcup_{i=1}^m A_i\right)
=
\sum_{r=1}^m(-1)^{r+1}
\sum_{1\le i_1<\cdots<i_r\le m}
P(A_{i_1}\cap\cdots\cap A_{i_r}).
\]

### 逐点覆盖次数证明

取一个样本点 \(\omega\)，假设它恰好属于 \(t\) 个事件。

- 若 \(t=0\)，它不出现在任何交中，右端贡献为 \(0\)。
- 若 \(t\ge1\)，在计算所有 \(r\) 重交时，包含 \(\omega\) 的 \(r\) 个事件
  组合共有 \(\binom tr\) 个。因此右端给它的总系数是

\[
\binom t1-\binom t2+\binom t3-\cdots+(-1)^{t+1}\binom tt.
\]

由二项定理，

\[
(1-1)^t
=\sum_{r=0}^t(-1)^r\binom tr
=1-\sum_{r=1}^t(-1)^{r+1}\binom tr.
\]

因为 \(t\ge1\) 时 \((1-1)^t=0\)，所以

\[
\sum_{r=1}^t(-1)^{r+1}\binom tr=1.
\]

于是每个属于并集的点恰好计算一次，不属于并集的点计算零次，公式成立。

这个证明的重要性不只在得到公式，还在于展示了一种通用账法：**当整体直接
分区困难时，先按“被覆盖了几次”给每个点过账，再用交错和校正权重。**

## 06.3 补事件形式

若想计算“所有坏事件都不发生”的概率，容斥常写成补事件形式。令

\[
N_0=\left|A_1^c\cap\cdots\cap A_m^c\right|,
\]

则

\[
N_0=N-S_1+S_2-\cdots+(-1)^mS_m.
\]

除以 \(N=|\Omega|\) 得

\[
P(A_1^c\cap\cdots\cap A_m^c)
=
1-\sum_iP(A_i)
+\sum_{i<j}P(A_i\cap A_j)
-\cdots+(-1)^mP(A_1\cap\cdots\cap A_m).
\]

生日问题中“至少一对生日相同”的补事件是“所有人生日互不相同”；占位数
问题中“至少一个空桶”的补事件是“所有桶都非空”。这类存在性问题往往先
取补，再用容斥。

## 06.4 错排

\(n\) 封信和 \(n\) 个写好地址的信封随机配对。若没有任何一封信进入正确
信封，称为一个错排。错排数记作 \(D_n\)。

令 \(A_i\) 表示第 \(i\) 封信进入正确信封。指定某 \(r\) 封信都正确时，其余
\(n-r\) 封可任意排列，所以

\[
|A_{i_1}\cap\cdots\cap A_{i_r}|=(n-r)!.
\]

这样的 \(r\) 重交有 \(\binom nr\) 个。由补事件形式，

\[
\begin{aligned}
D_n
&=\sum_{r=0}^n(-1)^r\binom nr(n-r)!\\
&=n!\sum_{r=0}^n\frac{(-1)^r}{r!}.
\end{aligned}
\]

因此

\[
\frac{D_n}{n!}
=1-\frac1{1!}+\frac1{2!}-\cdots+\frac{(-1)^n}{n!}.
\]

前几个值为

\[
D_0=1,\quad D_1=0,\quad D_2=1,\quad D_3=2,\quad
D_4=9,\quad D_5=44,\quad D_6=265,\quad D_7=1854.
\]

当 \(n\to\infty\) 时，由指数函数的 Taylor 展开，

\[
\lim_{n\to\infty}\frac{D_n}{n!}
=\sum_{r=0}^{\infty}\frac{(-1)^r}{r!}
=e^{-1}.
\]

所以随机排列没有一个固定点的概率约为 \(36.79\%\)，至少有一个固定点的概率
约为 \(63.21\%\)。这个极限收敛很快；例如 \(D_4/4!=9/24=0.375\)，已经接近
\(e^{-1}\)。

`examples/python/06_inclusion_exclusion.py` 同时用闭式、递推和小宇宙
枚举检查错排。核心闭式如下：

```python
def derangement_closed(n):
    """D_n = n! sum_{k=0}^n (-1)^k / k!."""
    return factorial(n) * sum(
        Fraction((-1) ** k, factorial(k)) for k in range(n + 1)
    )

enum4 = sum(1 for p in product(range(4), repeat=4)
            if len(set(p)) == 4 and all(p[i] != i for i in range(4)))
assert enum4 == derangement_closed(4) == 9
```

`product(range(4), repeat=4)` 先生成 \(4^4=256\) 个四元组，再筛出其中
真正的排列；这不如直接生成排列高效，但它把“四个位置分别取值”和“无重复
且无固定点”两个条件显式分开，适合教学审计。

## 06.5 占位数：球进入篮子

\(n\) 个可辨球独立等概率地进入 \(r\) 个可辨篮。所有篮子都非空的分配有
多少种？

总分配数为 \(r^n\)。令 \(A_j\) 表示第 \(j\) 个篮子为空。指定 \(s\) 个篮子
为空时，每个球只能进入其余 \(r-s\) 个篮子，所以

\[
|A_{j_1}\cap\cdots\cap A_{j_s}|=(r-s)^n.
\]

空篮集合有 \(\binom rs\) 种。由补事件形式，全非空分配数为

\[
N_{r,n}^{\mathrm{full}}
=\sum_{s=0}^r(-1)^s\binom rs(r-s)^n,
\]

概率为

\[
P(\text{所有篮非空})
=\frac1{r^n}\sum_{s=0}^r(-1)^s\binom rs(r-s)^n.
\]

例如 \(r=3,n=4\)：

\[
3^4-\binom31 2^4+\binom32 1^4
=81-48+3=36.
\]

所以概率为 \(36/81=4/9\)。这也是满射函数的个数：从 \(n\) 个球组成的集合
到 \(r\) 个篮子组成的集合，共有多少个函数把每个篮子都覆盖到。

Prolog 文件枚举全部 81 个分配：

```prolog
findall(Assign, (between(1,3,A), between(1,3,B),
                 between(1,3,C), between(1,3,D),
                 Assign = [A,B,C,D]), All),
length(All, 81),
include(all_bins, All, Full), length(Full, 36),
IE is 81 - 3 * 16 + 3 * 1.
```

枚举值 `36` 与容斥计数相同。Julia 通道再用固定随机种子模拟 4 球进 3 篮；
模拟值接近 \(36/81\)，但只是大数定律下的数值直觉，不是公式证明。

## 06.6 Vandermonde 恒等式

Vandermonde 恒等式为

\[
\sum_{j=0}^k\binom mj\binom n{k-j}=\binom{m+n}{k}.
\]

### 组合证明

一个集合有 \(m+n\) 人，其中前 \(m\) 人属于甲组，后 \(n\) 人属于乙组。从
全部 \(m+n\) 人中选 \(k\) 人，总数为 \(\binom{m+n}{k}\)。

若选出的 \(k\) 人中恰有 \(j\) 人来自甲组，则另外 \(k-j\) 人来自乙组，方案
数为

\[
\binom mj\binom n{k-j}.
\]

不同 \(j\) 对应互斥情况，对 \(j\) 求和即得恒等式。

例如 \(m=3,n=2,k=2\)：

\[
\binom30\binom22+\binom31\binom21+\binom32\binom20
=1+6+3=10=\binom52.
\]

### 生成函数证明

由二项定理，

\[
(1+x)^m(1+x)^n=(1+x)^{m+n}.
\]

左端 \(x^k\) 的系数是所有次数组合 \(j+(k-j)=k\) 的系数之和：

\[
\sum_j\binom mj\binom n{k-j}.
\]

右端 \(x^k\) 的系数是 \(\binom{m+n}{k}\)。同一形式幂级数中的系数相等，
故恒等式成立。

## 06.7 曲棍球棒恒等式

曲棍球棒（hockey-stick）恒等式为

\[
\sum_{i=r}^{n}\binom ir=\binom{n+1}{r+1}.
\]

它的组合证明盯住“最大元素”。从

\[
\{0,1,\ldots,n\}
\]

中选 \(r+1\) 个元素，共有 \(\binom{n+1}{r+1}\) 种。设选出的最大元素为
\(i\)。因为最大元素是 \(i\)，其余 \(r\) 个元素必须从 \(\{0,\ldots,i-1\}\)
中选择，共有 \(\binom ir\) 种。最大元素可取 \(r,r+1,\ldots,n\)，故

\[
\binom{n+1}{r+1}=\sum_{i=r}^{n}\binom ir.
\]

例如

\[
\binom22+\binom32+\binom42+\binom52+\binom62
=1+3+6+10+15=35=\binom73.
\]

Prolog 枚举 \(\{0,\ldots,6\}\) 的全部 35 个三元子集，再按最大元素分类：

```prolog
findall(S, combo([0,1,2,3,4,5,6], 3, S), Subs),
length(Subs, 35),
findall(M, (between(2, 6, I),
            findall(S, (member(S, Subs), max_list(S, I)), Ss),
            length(Ss, M)), Counts),
Counts = [1, 3, 6, 10, 15].
```

这里的保序组合谓词 `combo` 只生成递增列表，因此不会把同一个集合按不同
排列重复枚举。

## 06.8 加权子集与两阶段选择

### 全体子集的总大小

对 \(n\) 元素集合的所有子集求大小之和：

\[
\sum_{k=0}^n k\binom nk=n2^{n-1}.
\]

第一种证明是代数求导：由

\[
(1+x)^n=\sum_{k=0}^n\binom nkx^k
\]

两边求导并令 \(x=1\)，得到

\[
n2^{n-1}=\sum_{k=0}^nk\binom nk.
\]

第二种证明是双计数。考虑“选一个子集，再在该子集中指定一个特殊元素”的
有序对。若子集大小为 \(k\)，有 \(k\) 种指定方式，左端为
\(\sum_k k\binom nk\)。反过来，先指定特殊元素，有 \(n\) 种；其余 \(n-1\)
个元素各自可在或不在子集中，有 \(2^{n-1}\) 种，所以右端为 \(n2^{n-1}\)。

### 交换记账顺序

常用恒等式

\[
\binom nk\binom kj=\binom nj\binom{n-j}{k-j}.
\]

左端表示先从 \(n\) 人中选 \(k\) 人，再从这 \(k\) 人中选 \(j\) 个核心成员。
右端先直接选出 \(j\) 个核心成员，再从剩余 \(n-j\) 人中选 \(k-j\) 个普通
成员。两种过程描述同一组对象。

这个恒等式在条件概率、超几何分布和分层抽样中经常出现。它提醒我们：一个
联合计数可以按信息到达顺序拆开，但最终总数不应随记账顺序改变。

## 06.9 机器通道

Python 文件 `examples/python/06_inclusion_exclusion.py` 负责精确有理数账。
骰子空间上的容斥代码为

```python
rhs = P(A) + P(B) + P(C) \
    - P(lambda w: A(w) and B(w)) \
    - P(lambda w: A(w) and C(w)) \
    - P(lambda w: B(w) and C(w)) \
    + P(lambda w: A(w) and B(w) and C(w))
assert P(lambda w: A(w) or B(w) or C(w)) == rhs == Fraction(16, 36)
```

同一文件还检查 Vandermonde、曲棍球棒、\(\sum_k k\binom nk=n2^{n-1}\) 和
两阶段选择恒等式。所有结果都使用整数或 `Fraction`，没有浮点误差。

Julia 文件 `examples/julia/06_inclusion_exclusion.jl` 用固定种子模拟错排
和篮子问题，并用 `Rational{BigInt}` 审计错排序列及组合恒等式：

```julia
for (m, n, k) in ((3, 2, 2), (5, 4, 3), (8, 7, 6))
    lhs = sum(binomial(m, j) * binomial(n, k - j) for j in 0:k)
    @assert lhs == binomial(m + n, k)
end
```

Prolog 文件 `examples/prolog/06_inclusion_exclusion.pl` 全枚举 \(4!=24\)
个排列、\(3^4=81\) 个球篮分配、8 点三事件空间和 35 个三元子集。它提供的
是“每个结果都被检查”的有限模型证据。

Lean 文件 `examples/lean/Probability/Ch06InclusionExclusion.lean` 登记
mathlib 的 Vandermonde 锚点 `Nat.add_choose_eq`，并用 `norm_num`、
`decide` 和 `native_decide` 固定骰子容斥、错排序列、曲棍球棒和两阶段选择
的关键数值：

```lean
example : Nat.choose 2 2 + Nat.choose 3 2 + Nat.choose 4 2
    + Nat.choose 5 2 + Nat.choose 6 2 = Nat.choose 7 3 := by decide
```

四条通道分工明确：证明器锚定一般引理和关键数值，有理数计算核对闭式，
Prolog 在小宇宙中全枚举，Julia 模拟只用于建立频率直觉。

## 06.10 本章要点

1. 容斥的交错符号不是任意规定；它保证每个属于恰好 \(t\) 个事件的点总系数
   为 \(\sum_{r=1}^t(-1)^{r+1}\binom tr=1\)。
2. “至少一个”常取补为“一个也没有”，补事件形式尤其适合生日、空篮和
   固定点问题。
3. 错排数为 \(D_n=n!\sum_{k=0}^n(-1)^k/k!\)，且
   \(D_n/n!\to e^{-1}\)。
4. \(n\) 球进 \(r\) 篮且全篮非空的方案数为
   \(\sum_{j=0}^r(-1)^j\binom rj(r-j)^n\)。
5. Vandermonde 可通过“从两个组共选 \(k\) 人”双计数，也可通过比较
   \((1+x)^{m+n}\) 的系数证明。
6. 曲棍球棒恒等式通过最大元素分类得到。
7. \(\sum_k k\binom nk=n2^{n-1}\) 和
   \(\binom nk\binom kj=\binom nj\binom{n-j}{k-j}\)
   都是同一对象的两种记账法。

*对应示例：`examples/lean/Probability/Ch06InclusionExclusion.lean`、
`examples/julia/06_inclusion_exclusion.jl`、
`examples/python/06_inclusion_exclusion.py`、
`examples/prolog/06_inclusion_exclusion.pl`。*

---

上一章：[05 计数原理、排列与组合](05-counting.md) · 下一章：[07 计数实验：扑克、生日与著名问题](07-counting-lab.md)
