# 26 Sobolev 不等式：GNS 与 Morrey

**对应书 §5.6（Gagliardo-Nirenberg-Sobolev 不等式、Morrey 不等式、
一般 Sobolev 不等式）。**

---

## 26.1 两条核心不等式

**GNS**（1 < p < n）：‖u‖_{L^{p*}} ≤ C‖∇u‖_{L^p}，临界指数

    **1/p\* = 1/p − 1/n**

（零边值或 ℝⁿ；常数只依赖 n、p）。它把"导数的可积性"兑换成
"函数本身更高的可积性"——W^{1,p} ⊂ L^{p*}。

**Morrey**（p > n）：u ∈ W^{1,p} ⟹ Hölder 连续 C^{0, 1−n/p}，且

    |u(x) − u(y)| ≤ C‖∇u‖_p|x−y|^{1−n/p}。

**临界情形 p = n**：不嵌入 L^∞——反例 log log(e/|x|) ∈ W^{1,n}
但无界。

## 26.2 机器验证（Julia `26_sobolev_inequalities.jl`）

- (a) 1D GNS（p = 1，p* = ∞）：帐篷族 ‖u‖_∞ = h ≤ 2h = ‖u′‖_1；
- (b) 2D GNS（p = 2，p* = 4）：离散网格上 ‖u‖₄/‖∇u‖₂ 的比值在
  N = 16/32 两级网格一致有界（≈0.49）——**常数不随网格爆炸**是
  嵌入成立的数值签名；

> 坑账（Julia 作用域再现）：顶层嵌套 for 里累计变量报
> "local variable in its enclosing scope"——B 批以来第 N 次，
> **循环体重写为函数**是一劳永逸的解。

- (c) Morrey 样本：x^{3/4} ∈ W^{1,2}（u′ ∝ x^{−1/4} 平方可积），
  其 C^{0,1/4} 半范数恰 1（幂函数标尺，24 章的复用）；
- (d) 临界样本：log log(e/r) 在 r = 10⁻⁶ 处值 2.70——W^{1,2} 函数
  可以无界的活体。

## 26.3 要点回顾

1. GNS：导数换积分指数（1/p\* = 1/p − 1/n）；Morrey：p > n 换
   Hölder 连续性。
2. 幂函数 x^a 是所有不等式的**饱和样本**（半范数恰 1）。
3. 临界 p = n 的对数反例与 p = ∞ 的失败是嵌入表的边界。

*本章示例：`examples/julia/26_sobolev_inequalities.jl`。*

---

上一章：[25 逼近与延拓](25-approximation.md) · 下一章：[27 紧性与 Poincaré](27-compactness.md) · [返回目录](../README.md)
