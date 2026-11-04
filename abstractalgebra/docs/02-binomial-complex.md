# 02 二项式定理与复数

**对应原书 §1.2（pp. 16-33）。**

---

## 2.1 阶乘与二项式系数：一个归纳定义

上一章末尾出现了第一个"用归纳法给出的定义"：0! = 1，(n+1)! = (n+1)·n!。
这类**递归定义**与归纳证明是同一枚硬币的两面——定义告诉你如何算出下一项，
归纳法证明"关于所有项的断言"。二项式系数也用递归定义最干净：

> C(n, k) = n! / (k!(n−k)!)　（读作"n 选 k"）。

它数的是"n 元集合的 k 元子集个数"——这句组合解释是后面一切恒等式的
意义来源。C(n, k) 满足**帕斯卡恒等式**（原书引理 1.14 / 命题 1.15 的核心）：

  C(n+1, k) = C(n, k−1) + C(n, k)，　1 ≤ k ≤ n。

代数证明是通分；组合证明更有味道：从 n+1 个人里选 k 个，按"含不含
指定的小明"分成两案——含小明则其余 k−1 人来自另外 n 人（C(n, k−1) 种），
不含则 k 人全部来自另外 n 人（C(n, k) 种）。两案不重不漏。这条恒等式就是
帕斯卡三角形的构造法则：每个数等于肩上两数之和。

## 2.2 二项式定理

> **推论 1.17（二项式定理）** 对一切 n ≥ 0 与交换环中的 a, b：
> (a + b)ⁿ = Σ_{k=0}^{n} C(n, k) a^k b^{n−k}。

**证明（归纳法）** n = 0 时两边都是 1。归纳步骤用帕斯卡恒等式：
(a+b)^{n+1} = (a+b)·Σ_k C(n,k)a^k b^{n−k}，把乘积按 k 重新收拢，
a^{k+1}b^{n−k} 项的系数是 C(n, k) + C(n, k+1) = C(n+1, k+1)。∎

原书先证 a = 0 的特殊版本（推论 1.16：(1 + x)ⁿ = Σ C(n,k) xᵏ）再推广，
每一步都可用帕斯卡恒等式顶住。取 a = b = 1 得到常用的推论：

  Σ_{k=0}^{n} C(n, k) = 2ⁿ。

组合读法：n 元集合的子集总数（左边按大小分类数，右边直接数）。
二项式系数于是同时活在三个世界里：**代数**（展开系数）、**计数**（子集个数）、
**递归**（帕斯卡三角）。三角不平衡的世界观是后面多项式章（第 17 章）的先声。

## 2.3 复数：从"不可能"到代数封闭

复数 ℂ = {a + bi : a, b ∈ ℝ}，i² = −1。本教程只假定四则运算，但有两个
几何事实贯穿全场：**模** |z| = √(a² + b²) 是到原点的距离，**辐角** arg z
是实轴正方向到向量 (a, b) 的转角。

> **命题 1.18（极分解）** 每个复数 z 可写为 z = r(cos θ + i sin θ)，
> 其中 r = |z| ≥ 0。r = 0 时 θ 任取；r > 0 时 θ 在模 2π 意义下唯一。

> **命题 1.19（加法定理）**
> cos(θ+φ) = cos θ cos φ − sin θ sin φ，
> sin(θ+φ) = sin θ cos φ + cos θ sin φ。

> **推论 1.20** |zw| = |z|·|w|；arg(zw) = arg z + arg w（模 2π）。

推论 1.20 的证明就是把两个极分解相乘并用加法定理——**乘复数 = 模相乘、
辐角相加**。这句口诀是本节的全部灵魂：它把 ℂ 的乘法群变成"伸缩 × 旋转"。
顺带一提，|zw| = |z||w| 用代数证明是恒等式
(a²+b²)(c²+d²) = (ac−bd)² + (ad+bc)²——它是"两平方数之积仍是平方数之和"，
在第 22 章有限域里会以 x²+1 的身影回归。

> **定理 1.21（棣莫弗）** (cos θ + i sin θ)ⁿ = cos nθ + i sin nθ。

对 n 归纳，每步用加法定理。它让"开 n 次方"变成初等除法：想找 zⁿ = w 的
解，把 w 的辐角除以 n 即可。特别地 w = 1：

> **推论 1.25（n 次单位根）** 方程 zⁿ = 1 恰有 n 个根
> ζ⁰, ζ¹, …, ζ^{n−1}，其中 ζ = cos(2π/n) + i sin(2π/n)。

这 n 个根均匀分布在单位圆上，构成一个**正 n 边形**——这是本教程遇到的
第一个"隐藏的群"：n 个单位根在乘法下封闭、有单位元 1、每个元素有逆
（ζᵏ 的逆是 ζ^{n−k}）。第 09 章给这个现象正式命名。

## 2.4 本原根与分圆分解

单位根 ζ^k 的**阶**是使 (ζ^k)^m = 1 的最小正 m。直接计算给出：
ζ^k 的阶是 n / gcd(n, k)。阶恰为 n 的根（等价地，gcd(n,k) = 1 的那些）
称为 **n 次本原单位根**。它们共有 φ(n) 个，其中 φ 是欧拉函数
（与 n 互素的数的个数；第 05 章正式登场）。

原书命题 1.27 把 xⁿ − 1 的因式分解按"根的阶"分类重组，得到本教程中
第一个非平凡的多项式恒等式：

> **命题 1.27（分圆分解）** 在 ℂ（事实上在任何特征 0 域）上
> xⁿ − 1 = Π_{d ∣ n} Φ_d(x)，
> 其中 Φ_d(x) = Π_{ord(ζ)=d} (x − ζ) 是 **d 次分圆多项式**。

乘积只跑 n 的**因子** d 而不是 1..n——因为 zⁿ = 1 的根的阶必整除 n
（原书引理 1.26：若 ζ 是 d 次本原根且 ζⁿ = 1，则 d ∣ n。证明是除法算式：
n = qd + r，0 ≤ r < d，则 ζ^r = 1，由 d 最小得 r = 0——这是第 03 章
带余除法的预告）。比较两边次数立即得到：

> **推论 1.28** Σ_{d ∣ n} φ(d) = n。

一个纯数论恒等式，证明却借道复数——这正是"结构互通"的第一次演示。
几个小例子值得手算：Φ₁ = x − 1，Φ₂ = x + 1，Φ₃ = x² + x + 1，
Φ₄ = x² + 1，Φ₅ = x⁴+x³+x²+x+1，Φ₆ = x² − x + 1，Φ₈ = x⁴ + 1，
Φ₁₂ = x⁴ − x² + 1。注意 Φ₆ 出现了负系数——"分圆多项式系数全是 1"
只对素数 n 成立。分圆多项式全部有整系数（原书命题 3.47 在第 21 章
用模算术证明），这为有限域、五次方程两条线都埋了伏笔。

## 2.5 切比雪夫多项式：cos nθ 的代数化

原书命题 1.24 观察到 cos nθ 可以写成 cos θ 的多项式：f₁(x) = x，
f₂(x) = 2x² − 1，f_{n+1}(x) = 2x·f_n(x) − f_{n−1}(x)（由 cos(n+1)θ +
cos(n−1)θ = 2 cos θ cos nθ）。f_n 就是**切比雪夫多项式**。它首项系数为
2^{n−1}，这一事实在判别三角多项式能否"降次"时有用。棣莫弗公式给出
cos nθ = Re((cos θ + i sin θ)ⁿ) = Σ_{j} C(n, 2j) cos^{n−2j}θ ·(±(1−cos²θ)^j)
——把超越函数折叠成代数多项式，是"代数化"精神的又一次亮相。

## 2.6 机器验证一：Lean——系数的机器证明

**文件：`examples/lean/Abstractalgebra/Ch02Binomial.lean`。**
四组内容：帕斯卡恒等式与行和、二项式定理、分圆分解、欧拉函数恒等式。

```lean
-- 帕斯卡恒等式：mathlib 以此为 choose 的递归定义
example (n k : ℕ) : (n + 1).choose (k + 1) = n.choose k + n.choose (k + 1) :=
  Nat.choose_succ_succ n k

/-- 帕斯卡行和：n 元集合的子集总数 = 2ⁿ。 -/
theorem row_sum_eq_two_pow (n : ℕ) :
    ∑ m ∈ Finset.range (n + 1), Nat.choose n m = 2 ^ n :=
  Nat.sum_range_choose n
```

mathlib 已经替我们完成了行和的归纳证明（`Nat.sum_range_choose` 的证明
正是"裂项 + 帕斯卡恒等式"的机器版），我们的文件引用它并在 Julia/Prolog
通道里重演计算。二项式定理同样直接调 `add_pow`（对任意交换半环成立）：

```lean
/-- 二项式定理（ℚ 系数版）：(x+y)ⁿ = Σ C(n,k)·xᵏ·yⁿ⁻ᵏ。 -/
theorem binomial_rat (n : ℕ) (x y : ℚ) :
    (x + y) ^ n = ∑ m ∈ Finset.range (n + 1),
      x ^ m * y ^ (n - m) * (Nat.choose n m : ℚ) := by
  simpa using add_pow x y n
```

分圆分解与推论 1.28 各一行（`Polynomial.prod_cyclotomic_eq_X_pow_sub_one`
与 `Nat.sum_totient`）。具体分圆多项式则有一段小插曲：mathlib 的
`cyclotomic` 标记为 `noncomputable`，`decide` 无法求值，于是 Φ₅ 走
素数公式 `cyclotomic_prime`（p 素时 Φ_p = Σ_{i<p} Xⁱ），Φ₁₂ 走
"手算分解 + 次数对账"双证：

```lean
-- X¹² − 1 的六个因子（ring 展开验证）：
example : (Polynomial.X ^ 12 - 1 : Polynomial ℤ)
      = (Polynomial.X - 1) * (Polynomial.X + 1) * (Polynomial.X ^ 2 + 1)
        * (Polynomial.X ^ 2 + Polynomial.X + 1)
        * (Polynomial.X ^ 2 - Polynomial.X + 1)
        * (Polynomial.X ^ 4 - Polynomial.X ^ 2 + 1) := by
  ring

-- Φ₁₂ 的次数 = φ(12) = 4：剩下的因子恰是那个四次多项式
example : (Polynomial.cyclotomic 12 ℤ).natDegree = 4 := by
  rw [Polynomial.natDegree_cyclotomic 12 ℤ]
  decide
```

由 ℤ[x] 分解的唯一性（第 20 章证明），"剩下的因子" X⁴ − X² + 1 就是
Φ₁₂——机器与手算一致，且它确实带负系数。

## 2.7 机器验证二：Julia——整系数多项式上的分圆分解

**文件：`examples/julia/02_binomial.jl`。** 这个文件手工实现一套
`Rational{BigInt}` 系数的一元多项式运算（加、乘、带余除法），然后用
**递归定义** Φ_n = (xⁿ − 1) ÷ Π_{d∣n, d<n} Φ_d 计算分圆多项式：

```julia
"""Φ_n = (xⁿ − 1) ÷ Π_{d∣n, d<n} Φ_d（命题 1.27 的构造性读法）。"""
function cyclotomic(n::Integer)::Poly
    n == 1 && return Rational{BigInt}[-1, 1]    # x − 1
    rest = foldl(polymul, (cyclotomic(d) for d in divisors(n) if d < n);
                 init=Rational{BigInt}[1])
    polydivexact(px_pow(n) - Rational{BigInt}[1], rest)
end
```

由于每一步除法都整除（在 ℚ[x] 中验证、在 ℤ 中收尾），计算全程**精确**。
文件断言：对 n = 1..12，(1) `cyclotomic(n)` 的系数全是整数；
(2) Π_{d∣n} Φ_d = xⁿ − 1 逐系数相等；(3) deg Φ_n = φ(n)（φ 用定义
直数 gcd(k,n)=1）。这三条断言合起来就是命题 1.27 + 推论 1.28 的
计算版。同文件还验证帕斯卡三角前 20 行的行和恰为 2ⁿ
（用 `binomial` 递推 `C(n,k) = C(n-1,k-1) + C(n-1,k)`，BigInt 无溢出）。

## 2.8 机器验证三：Python（sympy 符号印证）与 Prolog（帕斯卡记忆化）

**文件：`examples/python/02_binomial.py`** 用 sympy 做符号对照：
`expand((x + y)^n)` 与二项式定理右端逐系数比较（n ≤ 8 全部吻合）；
"定义式除法"算出的 Φ_n 与 `sympy.cyclotomic_poly` 逐系数比较（n ≤ 12）；
`chebyshevt` 验证 f_n 首项系数 = 2^{n−1}、T_m∘T_n = T_{mn}
（切比雪夫的半群性质，也是 2.5 节递推的副产品）。核心片段：

```python
from sympy import symbols, expand, binomial, cyclotomic_poly, divisors, Poly
x, y = symbols('x y')
for n in range(0, 9):
    lhs = expand((x + y) ** n)
    rhs = expand(sum(binomial(n, k) * x**k * y**(n - k) for k in range(n + 1)))
    assert lhs == rhs

def cyclotomic_def(n):
    """手算路径：Φ_n = (xⁿ−1) ÷ Π_{d∣n,d<n} Φ_d。"""
    if n == 1:
        return Poly(x - 1, x)
    rest = Poly(1, x)
    for d in divisors(n):
        if d < n:
            rest = rest * cyclotomic_def(d)
    q, r = divmod(Poly(x**n - 1, x), rest)
    assert r.is_zero
    return q

for n in range(1, 13):
    assert cyclotomic_def(n) == Poly(cyclotomic_poly(n, x), x)
```

**文件：`examples/prolog/02_binomial.pl`** 的主角是帕斯卡三角的**表驱动
记忆化**：`ch(N, K, C)` 用 `:- table ch/3.` 声明缓存，避免指数级重复计算
（斐波那契式陷阱——不记忆化的帕斯卡递归在第 30 行就会卡死）：

```prolog
:- table ch/3.

% 帕斯卡恒等式直译（表驱动记忆化）
ch(0, 0, 1) :- !.
ch(N, 0, 1) :- !, N > 0.
ch(N, N, 1) :- !, N > 0.
ch(N, K, C) :-
    N > 0, K > 0, K < N,
    N1 is N - 1, K1 is K - 1,
    ch(N1, K1, C1),
    ch(N1, K, C2),
    C is C1 + C2.
```

四条子句就是帕斯卡三角的三条边界加一条递推——**记忆化交给 SWI 的
tabling 机制**，程序本体与数学定义逐字对应。文件断言前 20 行行和等于
2ⁿ、帕斯卡恒等式 n ≤ 15 全数对成立，并枚举 n ≤ 60 验证
Σ_{d∣n} φ(d) = n——欧拉函数 φ 用"数互素个数"的直译定义（`aggregate_all
(count, …)`），整条推论 1.28 在整数世界严格复核。

## 2.9 要点回顾

1. 帕斯卡恒等式 C(n+1,k) = C(n,k−1) + C(n,k) 有代数与计数两张面孔，
   是二项式定理归纳证明的引擎。
2. 复数乘法 = 模相乘 + 辐角相加（推论 1.20）；棣莫弗是它的 n 次幂版本；
   n 次单位根是单位圆上的正 n 边形，暗中构成一个群。
3. xⁿ − 1 = Π_{d∣n} Φ_d 按根的阶重组因式；比较次数得 Σ_{d∣n} φ(d) = n。
4. 分圆多项式整系数、φ(n) 次；Φ₆ = x² − x + 1 提醒"素数的美好不可外推"。
5. 计算通道里"精确"由三层保证：Lean 的类型化证明、Julia 的 BigInt/分数
   多项式、sympy 的符号展开；浮点从未参与任何等式断言。

*对应示例：`examples/lean/Abstractalgebra/Ch02Binomial.lean`、
`examples/julia/02_binomial.jl`、`examples/python/02_binomial.py`、
`examples/prolog/02_binomial.pl`。*

---

上一章：[01 数学归纳法与良序](01-induction.md) · 下一章：[03 最大公因子](03-gcd.md)
