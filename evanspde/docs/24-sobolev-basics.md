# 24 Hölder 空间与弱导数

**对应书 §5.1–§5.2（Hölder 空间 C^{k,γ}；弱导数与 Sobolev 空间
W^{k,p}）。**

---

## 24.1 两个函数空间台阶

**Hölder 空间** C^{k,γ}(Ū)：k 次连续可微且 k 阶导数的 γ-次
Hölder 半范数 [u]_{C^{0,γ}} = sup_{x≠y}|u(x)−u(y)|/|x−y|^γ 有限。
幂函数是标尺：**[|x|^γ]_{C^{0,γ}} = 1 恰饱和**。

**弱导数**：v = D^αu 弱意义 ⟺ 对一切 φ ∈ C_c^∞

    ∫ u·D^αφ = (−1)^{|α|}∫vφ（分部积分转移导数）。

W^{k,p}(U) = 弱导数到 k 阶都 L^p 的函数。动机：边值问题的自然解
空间——帽子函数（有限元基函数）不 C¹ 但有弱导数。

## 24.2 机器验证

**Julia**（`24_weak_derivatives.jl`）：

- (a) 帽子 u = (1−|x|)₊ 的弱导数 = ±1 阶跃：对试验 φ 的分部积分
  两边数值相等（2×10⁻³，φ 截断误差）——**对称 φ 使两侧都是 0
  （空测试！）**，补一个平移非对称 φ 再核；
- (b) 光滑函数的弱导数 = 经典导数（残差 10⁻¹⁴）；
- (c) |x| 的弱导数 = sign；
- (d) Hölder 半范数的幂函数标尺：[x^{1/2}]_{C^{0,1/2}} = 1.000000
  **精确饱和**（网格扫描）。

**Lean**（`Ch24WeakDerivatives.lean`）——弱导数定义的**代数本体**：

```lean
theorem discrete_integration_by_parts (u v : ℕ → α) (N : ℕ) :
    ∑ i in range N, u i * (v (i + 1) - v i)
      = u N * v N - u 0 * v 0 - ∑ i in range N, v (i + 1) * (u (i + 1) - u i)
```

离散分部积分（望远镜求和），任意交换群上的逐项 ring——"导数转
移 = 反号 + 边界项"在格点上的全部内容。

## 24.3 要点回顾

1. Hölder 半范数的幂函数标尺（饱和值 1）是检验嵌入是否 sharp 的
   标准样本（26 章复用）。
2. 弱导数 = 分部积分意义下的导数；帽子/|x| 是原型样本。
3. 离散分部积分是弱导数、有限体积、Galerkin 三大方法的共同代数
   地基（Lean 完整证明）。

*本章示例：`examples/julia/24_weak_derivatives.jl`、`examples/lean/
Evanspde/Ch24WeakDerivatives.lean`。*

---

上一章：[23 幂级数与 CK](23-power-series.md) · 下一章：[25 逼近、延拓与迹](25-approximation.md) · [返回目录](../README.md)
