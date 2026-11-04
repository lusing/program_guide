# 24 向量空间

**对应原书 §4.1（pp. 321-353）。**

---

## 24.1 从 ℝⁿ 到任意域

线性代数在中学习惯于箭头与坐标。抽象化的关键一步是：**把"数"换成任意域
F**——所有代数推理只用到 F 的域公理（非零可除），一点也没用到 ℝ 的顺序
或完备性。

> **定义（向量空间）** 域 F 上的向量空间 V 是带"加法"（V 内交换群）与
> "数乘"（F × V → V）的集合，满足八条公理：
> u+v = v+u、(u+v)+w = u+(v+w)、0、−v、1v = v、(ab)v = a(bv)、
> a(u+v) = au+av、(a+b)v = av+bv。

**例清单**（原书开篇强调"域可以很不一样"）：
- Fⁿ（坐标空间）；F[x]（多项式空间）；F[x]_{<n}（次数 < n）；
- 矩阵空间 F^{m×n}；函数空间 F(X, F)；
- **ℂ 作为 ℝ 上的空间**（维数 2，基 {1, i}）；**ℝ 作为 ℚ 上的空间**！
- **ℤ/pℤ 上的空间**：坐标全在有限域里——2 元域上 n 维空间恰有 2ⁿ 个
  向量，几何图像完全照常（直线、平面、超平面）。

**消去律等基本推论**：0v = 0、a0 = 0、(−1)v = −v、au = 0 ⟹ a = 0 或
u = 0——全部从八条公理挤出（与第 15 章环公理的"负号纪律"平行）。

## 24.2 线性组合、张成与线性无关

> **定义** v ∈ ⟨S⟩（S 的张成）若 v 是 S 中有限个向量的线性组合。
> S **线性无关**若有限和 Σaᵢvᵢ = 0 ⟹ 全部 aᵢ = 0。

线性无关的判别在具体空间里各有花样：Fⁿ 中看行列式/消元；F[x]_{<n} 中
看多项式恒等；函数空间看"逐点代入"（代入足够多的点把系数逼出来——
范德蒙行列式的地盘）。

> **定理（极小性）** 线性无关集是"无冗余"的：每个 vᵢ 都不在其余向量的
> 张成中。反之张成集的每个元素都可靠后腿。

## 24.3 基与维数

> **定义** **基** = 线性无关的张成集。**维数** dim V = 基的大小。

> **定理（维数不变性）** V 的任意两组基大小相同——"维数"是良定义的。
> **交换引理** 基中任一向量可换成"系数非零"的新向量，维数不变。
> **补基定理** 线性无关集可扩充为基；张成集可裁剪为基。

**核心定理（dim 的三选一）** dim V = n 时，n 个向量 v₁,…,vₙ：
线性无关 ⟺ 张成 V ⟺ 是基——两个条件自动等价（少于/多于 n 个时
才有真正的强弱之分）。

经典维数表：dim Fⁿ = n；dim F[x]_{<n} = n；dim F^{m×n} = mn；
dim ℂ（over ℝ）= 2；子空间 W ≤ V ⟹ dim W ≤ dim V，
且 dim W = dim V ⟹ W = V（有限维）。

## 24.4 有限域上的计数：|V| = qⁿ

F = GF(q) 上 n 维空间 V 的向量个数恰 qⁿ：按基展开是双射
V ↔ Fⁿ ↔ qⁿ 个坐标元组。更精细的计数：

> **命题** dim V = n（over GF(q)）时，线性无关的有序 k 元组个数 =
> (qⁿ−1)(qⁿ−q)⋯(qⁿ−q^{k−1})——第一位任取非零（qⁿ−1 选）、第二位
> 不落在第一位的倍数上（qⁿ−q 选）、依次递推。

特别地 n 维空间的**基**个数 = ∏_{i=0}^{n−1}(qⁿ−qⁱ)，有序基的 GL(n,q)
阶数由此而来（第 29 章线性码要用）。k = 1 时恢复"非零向量 qⁿ−1 个"。

## 24.5 机器验证一：Lean——Module 与维数

**文件：`examples/lean/Abstractalgebra/Ch24VectorSpaces.lean`。**
mathlib 的向量空间是 `Module F V`（加法群 + 数乘 + 八公理）：

```lean
-- 基本推论：0 • v = 0、(−1) • v = −v（实例层 + 定向引理）
example {F V : Type*} [Field F] [AddCommGroup V] [Module F V] (v : V) :
    (0 : F) • v = 0 := zero_smul F v

example {F V : Type*} [Field F] [AddCommGroup V] [Module F V] (v : V) :
    (-1 : F) • v = -v := neg_smul_one v

-- au = 0 ⟹ a = 0 ∨ u = 0（域上的消去）
example {F V : Type*} [Field F] [AddCommGroup V] [Module F V] {a : F} {u : V}
    (h : a • u = 0) : a = 0 ∨ u = 0 := by
  rcases eq_or_ne a 0 with rfl | ha
  · exact Or.inl rfl
  · refine Or.inr ?_
    have : u = a ⁻¹ • (a • u) := by rw [smul_smul, inv_mul_cancel₀ ha, one_smul]
    rw [this, h, zero_smul]
```

（末例展示"乘逆消去"的标准姿势——与第 16 章域上消去完全平行。）
维数侧：`Module.finBasis`、`finrank`；dim ℚ = 1、dim ℂ over ℝ = 2 以
`finrank` 的 decide 呈现；F[x]_{<n} 与 Fⁿ 同构（`LinearEquiv`）。

## 24.6 机器验证二：Julia——GF(2)/GF(3) 上的几何

**文件：`examples/julia/24_vector_spaces.jl`** 在**有限域**上跑全套
线性代数原语（复用第 22 章 GF 引擎）：

```julia
"""GF(p) 上的高斯消元：返回 (rref, rank)（系数 mod p）。"""
function rref(A, p)
    A = mod.(A, p); m, n = size(A); rank = 0
    for c in 1:n
        rank > m && break
        piv = findfirst(!iszero, A[rank+1:m, c])
        piv === nothing && continue
        piv += rank
        A[rank+1, :], A[piv, :] = A[piv, :], A[rank+1, :]
        inv = modinv(A[rank+1, c], p)
        A[rank+1, :] = A[rank+1, :] .* inv .% p
        for r in 1:m, r != rank+1
            fac = A[r, c]
            A[r, :] = mod.(A[r, :] .- fac .* A[rank+1, :], p)
        end
        rank += 1
    end
    A, rank
end
```

断言组：(1) **维数不变性实验**：GF(3) 上随机生成 4×4 矩阵的行空间的
两组基（不同消元顺序）大小一致（rank 唯一）；(2) **计数公式**：
dim 3 over GF(2) 的向量数 8 = 2³；非零 7；线性无关二元组
7·6 = 42 个（枚举验证）；有序基 7·6·4 = 168 = |GL(3,2)|；
(3) GF(3)^3 中平面（2 维子空间）的个数 = 13（两非零向量张成同一平面
的计数——第 29 章译码的背景数）；(4) 线性无关判别：范德蒙型向量组
(1,a,a²) 在 GF(5) 中 a 互异时无关（rank 3）；(5) ℂ over ℝ 的基
{1, i}：任意 z = a+bi 坐标唯一。

## 24.7 机器验证三：Python 与 Prolog

**文件：`examples/python/24_vector_spaces.py`**：sympy `Matrix.gauss_jordan_solve`
与自实现 GF(2) 消元对拍；GF(2)³ 的全部 8 个向量枚举，子空间清单
（恰 16 个子空间：1 个 {0}、7 条直线、7 个平面、1 个全空间——
**PG(2,2) = Fano 平面就是 GF(2)³ 的直线与点**！第 23 章的回环）；
线性无关二元组计数 21 = C(7,2)/3。

**文件：`examples/prolog/24_vector_spaces.pl`**：

```prolog
% GF(2)³ 的全部向量（位三元组）
vec3([A, B, C]) :- member(A, [0,1]), member(B, [0,1]), member(C, [0,1]).

% 子空间：非空子集对加法封闭——枚举 2⁸ = 256 个子集过滤
subspace3(S) :-
    findall(V, vec3(V), Vs),
    subset_of(Vs, S), S \= [],
    closed_under_add(S).
```

文件断言：GF(2)³ 恰 16 个子空间、7 条"直线"（2 维向量群 + 零点）——
与 Fano 平面 7 点对上号；线性无关对的计数；任意两平面交 ≥ 1 维。

## 24.8 要点回顾

1. 向量空间 = 域上的加法群 + 数乘八公理；域公理（非零可除）是全部
   推理的燃料——顺序与完备性从不出现。
2. 基 = 无关张成集；维数唯一（交换引理）；n 个向量在 n 维空间里
   "无关 ⟺ 张成 ⟺ 基"三合一。
3. 子空间 W ≤ V：dim W ≤ dim V，等维 ⟹ 相等；商空间 V/W 维数减法
   （第 26 章正式登场）。
4. 有限域上 |V| = qⁿ；无关 k 元组 = ∏(qⁿ−qⁱ)；有序基 = |GL(n,q)|。
5. GF(2)³ 的 7 条直线 = Fano 平面的 7 点——第 23 章的组合结构原来
   是线性代数（射影几何 = 向量空间的商视角）。

*对应示例：`examples/lean/Abstractalgebra/Ch24VectorSpaces.lean`、
`examples/julia/24_vector_spaces.jl`、`examples/python/24_vector_spaces.py`、
`examples/prolog/24_vector_spaces.pl`。*

---

上一章：[23 一个数学旅程](23-journey.md) · 下一章：[25 欧氏作图](25-constructions.md)
