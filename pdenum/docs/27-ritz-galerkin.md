# 27 Ritz、Galerkin 与权余量方法

**对应书第 6 章 §4–§5（Ritz 方法、Galerkin 方法、数值例子、权余量
方法及其他方法）。**

---

## 27.1 Ritz 方法：变分问题的有限维化

取有限维子空间 S_h = span{φ₁,…,φₙ}（基函数满足本质边界条件），
把 Ritz 问题限制到 S_h：v = Σc_jφ_j，J(v) 对 c_i 求导为零给出
**系数方程**（书 §4.1）：

    **Σ_j c_j D(φ_j, φ_i) = F(φ_i)，i = 1..n** ——线性方程组 Ac = b。

- 正交基（如 sin jπx）：A 对角，系数解耦 c_j = F(φ_j)/d_j——
  **谱方法**的雏形；
- hat 基：A 稀疏三对角——**有限元**的雏形（第 28 章）。

## 27.2 Galerkin 方法与权余量家族

**Galerkin 方法**：残差 R = Lu − f 与全部基函数正交（∫R·φ_i = 0）。
D 对称正定时与 Ritz 给出**同一个**方程组——两条路线（虚功/最小
势能）在代数上汇合。

书 §5 把两者放进**权余量法**（weighted residuals）的一般框架：
近似解的残差以权 w_i 加权积分为零，∫R·w_i = 0。权的取法给出一族
方法（书表）：

| 权 w_i | 方法 |
|---|---|
| δ(x − x_i) | 配点法（collocation） |
| 子域特征函数 χ_i | 子域法 |
| ∂R/∂c_i | 最小二乘法 |
| xⁱ | 矩法 |
| φ_i（基函数本身） | **Galerkin** |

只有 Galerkin（权 = 试探函数族）给出对称矩阵与能量范数最优性。

## 27.3 机器验证

### 正弦基 Ritz：谱收敛

−u″ + u = x、零边界、精确解 u* = x − sinh(x)/sinh(1)。
正弦基 D(φ_j,φ_k) = δ_jk(j²π²+1)/2 对角、F(φ_j) = (−1)^{j+1}/(jπ)——
系数**闭式** c_j = (−1)^{j+1}/(jπ((j²π²+1)/2))（Julia，
`examples/julia/27_ritz_galerkin.jl`）：

```julia
c = [((j % 2 == 1 ? 1.0 : -1.0) / (j * pi)) / ((j^2 * pi^2 + 1) / 2) for j in 1:n]
u_ritz(x) = sum(c[j] * sin(j * pi * x) for j in 1:n)
@assert err < 5e-5 "正弦基 Ritz 应谱收敛"
```

n = 40 时最大误差 1.5×10⁻⁵；截断误差 n = 2/4/8 给
3.8×10⁻³/1.2×10⁻³/3.4×10⁻⁴——系数 ~1/j³（f 不光滑端点效应），
收敛速率 1/n²。

### hat 基 Galerkin：与 Ritz 同一解

用 25 章装配的 D、F（闭式三对角 + 数值载荷），N = 40 hat 基
Galerkin 解误差 7.7×10⁻⁵——与正弦基 Ritz 同一精度量级、同一解
（D 对称正定 ⟹ 两法等价的数值版）。

### 配点法

同一正弦基 + 配点（残差在等距点为零）：误差 5.9×10⁻⁵——收敛但
矩阵不对称（权是 δ 而非 φ_i）。

Lean（`Ch27RitzGalerkin.lean`）：配方恒等式 + 能量最优性
`ritz_minimal`（J(c) − J(c*) = (a/2)(c−c*)² ≥ 0 的单变量版——
配方法 `linear_combination` 一步）。Prolog：权余量家族表、Ritz/
Galerkin 同一性规则、对称矩阵直觉。

坑账：Prolog 文件经 PowerShell 正则改写后多字节序列损坏导致子句
静默失效（listing 定位）——重写文件修复；`x^i` 应写 `x_pow_i`
（`^` 在 Prolog 是原子）；小写原子变量再犯两次（lift 子句头）。

## 27.4 要点回顾

1. Ritz 系数方程 Ac = b：A_ij = D(φ_j, φ_i)、b_i = F(φ_i)；正交基
   对角化、hat 基稀疏化。
2. Galerkin 与 Ritz 在对称正定时同一；权余量家族统一视角里 Galerkin
   = "权取基函数"。
3. 收敛速率由两部分决定：基的逼近阶（对角化的谱收敛 vs hat 的
   O(h²)）与解/载荷的光滑性（系数 1/j³ 来自 f 的端点跳跃）。
4. `linear_combination` 是配方类恒等式的自动化武器。

*本章示例：`examples/julia/27_ritz_galerkin.jl`、`examples/python/
27_ritz_galerkin.py`、`examples/prolog/27_ritz_galerkin.pl`、
`examples/lean/Pdenum/Ch27RitzGalerkin.lean`。*

---

上一章：[26 高维变分问题](26-multidim-variational.md) · 下一章：[28 一维有限元：线性元](28-fem-1d.md)
