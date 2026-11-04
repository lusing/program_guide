# 26 线性变换

**对应原书 §4.3（pp. 367-384）。**

---

## 26.1 保结构的映射（第三次）

群同态保运算、环同态保两种运算；线性变换保加法与数乘——同一个
"保持结构"思想的第三次登场。

> **定义** T : V → W **线性**若 T(v + u) = Tv + Tu、T(av) = aTv。
> 等价地 T(av + bu) = aTv + bTu（"线性"= 保线性组合）。

**核与像**：ker T = {v : Tv = 0} 是 V 的子空间；im T 是 W 的子空间；
T 单 ⟺ ker T = {0}（与群/环论完全平行）。

> **定理（秩-零化度定理）** dim V = dim ker T + dim im T。
> 线性代数版的拉格朗日定理：定义域的大小 = 单射部分 + 满射部分。

**证明** 取 ker T 的基 v₁..v_r，扩充为 V 的基（补基定理），则
Tv_{r+1},…,Tv_n 是 im T 的基——两段各数各的。∎

## 26.2 矩阵表示：坐标化

固定 V 的基 B 与 W 的基 B′ 后，每个线性变换 T 对应唯一矩阵 A
（列 = T(基向量) 的坐标）。**换基 = 矩阵相似**：B 与 C 两组基下
T 的矩阵 A 与 A′ = P⁻¹AP，其中 P 是换基矩阵（C 坐标到 B 坐标）。

> **定义** 矩阵 A, B **相似**（A ~ B）若 B = P⁻¹AP。
> **不变量**：rank、det、trace、特征多项式——相似矩阵共享
> （"换基不改变算子的本性"，矩阵只是算子的坐标快照）。

**转置与行秩 = 列秩**：rank A = rank Aᵀ（行空间与列空间同维）——
秩-零化度定理的对称版。

## 26.3 线性变换的运算

(T+S)v = Tv + Sv、(aT)v = aTv、(TS)v = T(Sv)——线性变换构成
**域上的代数**（向量空间 + 乘法）。复合不交换（除法就是求逆：
可逆 T ⟺ 双射 ⟺ det ≠ 0）。多项式 f(T) = a₀I + a₁T + ⋯ + aₖTᵏ
良定义——为第 27 章（特征多项式 = det(xI − A)）搭好舞台。

## 26.4 有限域上的线性变换

GF(q) 上 V 的每个线性变换是 V 到自身的函数——可枚举！dim n 时
|V| = qⁿ，双射个数 (qⁿ)!…太多；但 GL(n, q)（可逆变换群）的阶恰为
∏_{i=0}^{n-1}(qⁿ − qⁱ)（第 24 章有序基计数）：可逆线性变换 ↔
把基映为基。GL(2,2) 的阶 = (4−1)(4−2) = 6——**GL(2,2) ≅ S₃**！
（三元域上 2×2 可逆矩阵 6 个，同构于三阶对称群——有限群的线性
实现第一次亮相。）

## 26.5 机器验证一：Lean——LinearMap 与秩-零化度

**文件：`examples/lean/Abstractalgebra/Ch26LinearMaps.lean`。**

```lean
-- 线性变换的基本律（LinearMap 类型类层）
example {F V W : Type*} [Field F] [AddCommGroup V] [Module F V]
    [AddCommGroup W] [Module F W] (T : V →ₗ[F] W) (v u : V) :
    T (v + u) = T v + T u := T.map_add v u

example {F V W : Type*} [Field F] [AddCommGroup V] [Module F V]
    [AddCommGroup W] [Module F W] (T : V →ₗ[F] W) (a : F) (v : V) :
    T (a • v) = a • T v := T.map_smul a v

-- 单 ⟺ 核平凡（与群/环论平行）
example {F V W : Type*} [Field F] [AddCommGroup V] [Module F V]
    [AddCommGroup W] [Module F W] (T : V →ₗ[F] W) :
    Function.Injective T ↔ LinearMap.ker T = ⊥ :=
  LinearMap.ker_eq_bot
```

（秩-零化度：mathlib 的 `LinearMap.rank_range_add_rank_ker`；
具体算例：ℚ³ 上投影与切剪矩阵的 rank + nullity = 3 以 `Matrix.rank`
的 decide 呈现。）矩阵相似侧：相似不变量 det/trace 的
`Matrix.det_similar`? 与 `Matrix.trace_similar`? 以实际引理名引用，
配 ℚ 上 2×2 的相似对实例。

## 26.6 机器验证二：Julia——有限域上的 GL 与秩-零化度

**文件：`examples/julia/26_linear_maps.jl`**：

```julia
"""GF(p) 上 n×n 矩阵乘法与行列式（Laplace 展开或消元）。"""
function det_gf(A, p)
    A = mod.(BigInt.(A), p); n = size(A, 1); det = 1
    for c in 1:n
        piv = findfirst(!iszero, A[c:n, c]); piv === nothing && return 0
        piv += c - 1
        if piv != c; A[c, :], A[piv, :] = A[piv, :], A[c, :]; det = -det; end
        det = mod(det * A[c, c], p)
        for r in c+1:n
            fac = A[r, c] * modinv(A[c, c], p) % p
            A[r, :] = mod.(A[r, :] .- fac .* A[c, :], p)
        end
    end
    mod(det, p)
end
```

断言组：(1) **秩-零化度**：GF(5) 上随机 3×4 矩阵 100 组，
rank + nullity = 3（rank 由 rref，nullity 由齐次解空间维数）；
(2) **|GL(2,2)| = 6**：枚举 GF(2) 上全部 16 个 2×2 矩阵，可逆恰
6 个，且乘法表与 S₃ 同构（复用第 09 章表比对器——GL(2,2) ≅ S₃
的完整验证）；(3) **|GL(2,3)| = (9−1)(9−3) = 48**（枚举计数验证）；
(4) 相似不变量：随机 P（det ≠ 0）下 trace(P⁻¹AP) = trace(A)、
det(P⁻¹AP) = det(A)（GF(7)，mod 意义下逐对）；(5) 行秩 = 列秩
（rref 与 ccref 双跑）。

## 26.7 机器验证三：Python 与 Prolog

**文件：`examples/python/26_linear_maps.py`**：sympy `Matrix.rank()`
与自实现 GF(2)/GF(3) 消元对拍；GL(2,2) 的 6 元群表打印与 S₃ 表
比对；`nullspace` 维数 + rank = n 的全量断言；trace/det 相似不变性
（sympy `similar_to` 或手动构造 P）。

**文件：`examples/prolog/26_linear_maps.pl`**：

```prolog
% GF(2) 上 2×2 矩阵：16 个，可逆 ⟺ det = 1
mat2([A,B,C,D]) :- member(A,[0,1]), member(B,[0,1]),
                   member(C,[0,1]), member(D,[0,1]).
det2([A,B,C,D], Det) :- Det is (A * D - B * C) mod 2.
invertible2(M) :- det2(M, 1).
```

文件断言：GF(2) 的 2×2 可逆矩阵恰 6 个；乘法封闭性与逆存在
（6×6 全对）；与 S₃ 群表（第 09 章口径）同构映射命中；
秩-零化度在 GF(2) 的 3×3 子集上抽查。

## 26.8 要点回顾

1. 线性变换 = 保加法与数乘；ker/im 是子空间；单 ⟺ 核零——
   结构保持理论的第三乐章。
2. 秩-零化度 dim V = rank + nullity：线性代数的"拉格朗日"。
3. 矩阵 = 算子的坐标快照；换基即相似 P⁻¹AP；rank/det/trace/特征
   多项式是不变量。
4. GF(q) 上 GL(n,q) = ∏(qⁿ−qⁱ)；GL(2,2) ≅ S₃——有限群的线性
   实现。
5. 线性变换构成代数：f(T) 良定义——下一章特征值的舞台。

*对应示例：`examples/lean/Abstractalgebra/Ch26LinearMaps.lean`、
`examples/julia/26_linear_maps.jl`、`examples/python/26_linear_maps.py`、
`examples/prolog/26_linear_maps.pl`。*

---

上一章：[25 欧氏作图](25-constructions.md) · 下一章：[27 特征值](27-eigenvalues.md)
