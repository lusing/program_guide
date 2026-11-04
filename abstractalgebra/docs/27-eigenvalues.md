# 27 特征值

**对应原书 §4.4（pp. 385-399）。**

---

## 27.1 不动方向

> **定义** A 是域 F 上的 n×n 矩阵。λ ∈ F 是 A 的**特征值**，若存在
> 非零 v（**特征向量**）使 Av = λv。特征值的集合 = 谱 σ(A)。

特征向量是"不被 A 推歪"的方向——A 在这些直线上退化为纯伸缩。
**判别**：Av = λv ⟺ (λI − A)v = 0 有非零解 ⟺ det(λI − A) = 0。

> **定义** **特征多项式** p_A(x) = det(xI − A)（n 次首一）。
> 特征值 = p_A 的根；λ 的**重数**（代数）= 根重数；λ 的**特征空间**
> E_λ = ker(λI − A)，其维数 = **几何重数** ≤ 代数重数。

## 27.2 谱定理族（本节的主菜）

> **定理（对角化判别）** A 可对角化（相似于对角阵）⟺ 特征多项式
> 在 F 上**完全分裂** 且 每个特征值几何重数 = 代数重数。
> 互异特征值的特征向量线性无关——n 个互异特征值 ⟹ 可对角化。

**对角化的收益**：A = PDP⁻¹ ⟹ Aᵏ = PDᵏP⁻¹（幂计算 = 坐标化 +
逐项幂）；f(A) = Pf(D)P⁻¹——线性递推（Fibonacci！）、矩阵函数、
微分方程组全部流水线化。

> **定理（实对称谱定理）** A 实对称 ⟹ 特征值全实、且**正交**
> 对角化（QᵀAQ = D，Q 正交）。证明依赖内积正交性（本节原书用
> 施密特正交化路线），是"实数域的礼物"。

**凯莱–哈密顿**：A 满足自己的特征多项式 p_A(A) = 0——矩阵版
"代入自身"。用途：高次幂的递推约简（Aⁿ 用低次幂线性表出）。

## 27.3 有限域上的特征值奇观

特征多项式在 F 上可能**不分裂**：GF(2) 上 A = [[0,1],[1,1]] 的
特征多项式 x² + x + 1 无根（GF(2) 中无）——特征值"住"在扩张
GF(4) 中！**谱依系数域而变**：ℝ 矩阵可有一对复特征值（旋转矩阵），
GF(2) 矩阵可有一对 GF(4) 特征值——同一台机器，换个域就换套谱。

**Frobenius 的轨道**：GF(2) 上不可约二次的根 α, α² 共轭——
trace(A) = α + α² = 1（系数和），det(A) = α·α² = α³——特征值的
对称函数落回基域！这是第 29-30 章（伽罗瓦）的先声：**对称函数
不经扩张就能看见**。

## 27.4 机器验证一：Lean——特征多项式

**文件：`examples/lean/Abstractalgebra/Ch27Eigenvalues.lean`。**

```lean
-- 凯莱–哈密顿的 mathlib 正式化（Matrix.aeval_self_charpoly）
example {R : Type*} [CommRing R] [IsDomain R] (M : Matrix n n R) :
    Polynomial.aeval M M.charpoly = 0 := M.aeval_self_charpoly

-- 迹与行列式 = 特征多项式的系数（根的对称函数）
example (A : Matrix (Fin 2) (Fin 2) ℚ) :
    A.charpoly = Polynomial.X ^ 2 - Polynomial.C (A.trace) * Polynomial.X
      + Polynomial.C A.det := by ext i; simp [Matrix.charpoly]; ring
```

（实际引理名以编译为准；文件以 2×2 的特征多项式系数核对
p(x) = x² − tr(A)x + det(A) 与 3×3 的 x³ − tr x² + … − det 为主，
凯莱–哈密顿以 mathlib 现成定理引用。具体算例：[[2,1],[1,2]] 的
谱 {1,3} 与对角化 P；Fibonacci 矩阵 [[1,1],[1,0]] 的谱
{(1±√5)/2}。）

## 27.5 机器验证二：Julia——谱计算与幂流水线

**文件：`examples/julia/27_eigenvalues.jl`**（精确有理数通道 +
GF 通道双跑）：

```julia
"""2×2 特征多项式：x² − tr·x + det（有理数精确）。"""
charpoly2(A) = (1, -tr(A), det(A))     # (首一系数, 一次系数, 常数)

"""整数二次求根：有理根判别（D = b²−4ac 是完全平方且根整/半整）。"""
rat_roots2(a, b, c) = begin
    D = b * b - 4 * a * c
    D < 0 && return nothing
    s = isqrt(D); s * s == D || return :irrational
    d1 = gcd(gcd(-b, s), 2 * a)
    (BigInt(-b + s) ÷ d1, BigInt(-b - s) ÷ d1)
end
```

断言组：(1) **谱计算**：[[2,1],[1,2]] → {1, 3}，特征向量 (1,−1)/
(1,1)，Aᵏ = PDᵏP⁻¹ 与直接矩阵幂对拍（k = 1..10）；(2) **Fibonacci
流水线**：Fₖ = (φᵏ − ψᵏ)/√5，用矩阵幂精确对拍 fib(k)（BigInt，
k ≤ 50——比第 01 章的迭代又快又直白）；(3) **凯莱–哈密顿**：随机
3×3 整数矩阵代入 p_A(A) = 0 逐元素验证；(4) **GF(2) 上的迁移**：
[[0,1],[1,1]] 在 GF(2) 特征多项式 x²+x+1 无根（谱搬到 GF(4)），
但 trace = 1、det = 1（对称函数落回 GF(2)）；A³ = I（阶 3——与
GF(4) 循环群对上）；(5) **实对称谱定理抽查**：随机对称 3×3 的
特征多项式判别式分析 + 数值 eig 全实断言（容差仅用于报告，
对拍走解析判别式）。

## 27.6 机器验证三：Python 与 Prolog

**文件：`examples/python/27_eigenvalues.py`**：sympy
`Matrix.charpoly()`、`.eigenvects()` 与自实现 rat_roots2 对拍
（随机 2×2 整数矩阵 500 组）；Fibonacci 幂流水线（sympy `Matrix**k`
精确值）；凯莱–哈密顿 3×3/4×4 验证；GF(2) 迁移案例的
`Poly(..., modulus=2)` 分解（x²+x+1 不可约）；对称矩阵谱全实
（4×4，sympy 精确 eigenvals）。

**文件：`examples/prolog/27_eigenvalues.pl`**：

```prolog
% 2×2 特征多项式 x² − tr·x + det 的系数
charpoly2(A, B, C, D, NegTr, Det) :-
    NegTr is -(A + D),
    Det is A * D - B * C.

% 特征值 = 二次 x² + NegTr·x + Det 的根（GF(p) 中穷举）
eigen2_p(P, A, B, C, D, Lam) :-
    charpoly2(A, B, C, D, NegTr, Det),
    between(0, P-1, L0), Lam is L0 mod P,
    V is (Lam * Lam + NegTr * Lam + Det) mod P, V =:= 0.
```

文件断言：GF(3) 上全部 81 个 2×2 矩阵的谱枚举——可对角化 /
不可分裂（特征多项式 = 不可约二次，判别式 = 非平方）分类统计
（可对角化 33 个，不可约判别式 24 个……机器给出精确计数）；
[[0,1],[1,1]] 在 GF(2) 无特征值但 A³ = I。

## 27.7 要点回顾

1. 特征值 = p_A(x) = det(xI − A) 的根；特征向量 = 不动方向；
   几何重数 ≤ 代数重数。
2. 可对角化 ⟺ 完全分裂 + 重数相等；互异谱 ⟹ 可对角化。
3. 对角化 = 幂的流水线（Aᵏ = PDᵏP⁻¹）：Fibonacci、递推、矩阵
   函数一站解决。
4. 实对称 ⟹ 正交对角化、谱全实——实数域的专属礼物。
5. 凯莱–哈密顿 p_A(A) = 0；GF(2) 矩阵的谱可住 GF(4)，但 trace/det
   （对称函数）落回基域——伽罗瓦的前奏。

*对应示例：`examples/lean/Abstractalgebra/Ch27Eigenvalues.lean`、
`examples/julia/27_eigenvalues.jl`、`examples/python/27_eigenvalues.py`、
`examples/prolog/27_eigenvalues.pl`。*

---

上一章：[26 线性变换](26-linear-maps.md) · 下一章：[28 码：分组码、线性码与译码](28-codes.md)
