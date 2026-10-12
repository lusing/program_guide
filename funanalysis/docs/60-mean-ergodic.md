# 60 · Stone 定理、平均遍历定理与 Koopman 群

> 酉群 = 自伴算子的指数；酉群的时间平均 = 不动点投影；测度保持
> 流的 Koopman 群把这两条接通——"时间平均 = 空间平均"就是
> 平均遍历定理的一句话。Boltzmann 1871 年的梦想，von Neumann
> 1932 年的定理。——Lax 第 35 章（意译）

本章覆盖 Lax 第 35.1–35.3 节：**Stone 定理**（两方向全证明 +
Bochner 正定函数路线）、**von Neumann 平均遍历定理**（定理 4 全
证明）、**Koopman 群**与度量传递性、"时间平均 = 空间平均"。
第 35.4–35.5 节（波动方程与平移表示）是 Lax-Phillips 散射理论的
入口，概览留给 61 章。

## 60.1 Stone 定理

**定理 1**。(i) 自伴 A 生成强连续酉群 U(t)（生成元 iA）；
(ii) 每个强连续酉群由唯一的自伴 A 生成。

**(i) 的证明**是 Hille-Yosida 的应用：‖R(z)‖ ≤ 1/|Im z|（57 章
(13)）⟹ iA 与 −iA 都生成压缩半群 U(t)、V(t)；恒等式
d/dt[U(t)V(t)x] = 0 ⟹ U(t)V(t) = I ⟹ 互逆；乘积 I + 各自压缩
⟹ 都是等距 ⟹ 酉。∎

**(ii) 的证明**三步：酉 ⟹ (Gx, x) + (x, Gx) = 0（微分范数）⟹ G
反对称（G* ⊇ −G）；ℝ∖{0} ⊂ res(G)（Hille-Yosida 双向）⟹ res(G*)
= conj res(G) 与 res(−G) 都含非零实数 ⟹ G* 与 −G 互为扩张不可能
⟹ **G* = −G** ⟹ iG 自伴。∎

**Bochner 路线**（引理 2–3）：a(t) = (U(t)u, u) 是正定函数
（(2) 的二次型 = ‖ΣφⱼU(tⱼ)u‖² ≥ 0，群律 + U(−t) = U(t)*）；
Bochner 定理（第一卷 21 章）给测度表示 (3)；极化 + 半双线性型
表示给 **E(S)**——第三条谱分解路线（57 章 Herglotz、42 章 Cayley
之后的 Stone/Bochner 路线）。

## 60.2 von Neumann 平均遍历定理

**定理 4**。U(t) 强连续酉群（只需群 + 强连续，不必酉）。F = 不动
向量集（闭子空间）。时间平均

```
M(T) = (1/T)∫₀^T U(s)ds
```

则 **s-lim_{T→∞} M(T) = P_F**（到 F 的正交投影）。

**证明**（Lax 原文的三段结构）：

1. **分解**：任取 r > 0，记 E = ker(U(r) − I)。恒等式
   U(s)x = x + ∫₀^s U(t)Gx dt 类型的差分给

   ```
   g = e + z，  z = (U(r) − I)y，                 (7)
   ```

   即 H = E + ran(U(r) − I)。理由：g − U(r)g = (U(r) − I)(−...)
   型的 telescoping 积分：g = (1/r)∫₀^r[U(s)g]ds + (差项)。
2. **ran 部分平均消失**：M(T) 作用在 z = (U(r)−I)y 上：

   ```
   ‖M(T)z‖ = ‖(U(T+r) − U(T))/(T·…)‖ 型 → 0    (T → ∞)，
   ```

   分子有界（酉）、分母 T → ∞。
3. **E 部分不动 + 正交补**：M(T)e = e；(8) 的极限属于每个
   ker(U(r)−I) ⟹ 属于 F；U(s) 与 F、F⊥ 的双方不变性 ⟹ 极限
   是到 F 的投影。∎

**评注**：这是**不需要任何谱定理**的遍历定理——只用群结构 +
一致有界。Birkhoff 的逐点遍历定理（时间平均对 a.e. x 收敛）深
得多，Lax 在注记中对照。

## 60.3 Koopman 群与度量传递性

**设定**：紧流形 M + 体积 V，保持体积的流 x(y; t)（Hamilton 流
是原型，(9″)：x(y(z;s), t) = x(z; s+t)）。**Koopman 群**：

```
(U(t)g)(y) = g(x(y; t))                        (10)
```

——复合算子；保体积 ⟹ 一切 Lᵖ 范数不变（酉）。

**F 是什么？**：U(t)g = g 对一切 t ⟺ g 沿轨道恒定。若 g 非常数
实值，则 {g < c} 是**非平凡不变集**；反之不变集的特征函数不动。
于是：

```
F = 常数函数 ⟺ 流度量传递（无非平凡可测不变集）。
```

**时间平均 = 空间平均**：度量传递时，对一切 g ∈ L²(M)：

```
lim_{T→∞} (1/T)∫₀^T g(x(y;t))dt = (1/Vol M)∫_M g dV。       (11)
```

左边是"沿轨道的时间平均"（实验测得的量），右边是"相空间平均"
（系综计算）。**Boltzmann 的各态历经假说**（ergodic hypothesis）
由此有了精确的数学形式：对 L² 函数的均方意义下成立。

Lax 的两段精彩注记（书中原话的转述）：统计力学中 N ~ 10²³ 个
粒子，时间平均 = 空间平均意味着**不必解 10²³ 维微分方程，只须算
一个积分**；Jack Schwartz 指出，有热力学意义的观察量是高度对称
的函数，其时间/空间平均相等可能有遍历定理之外的原因——遍历
定理是充分框架而非唯一解释。

## 60.4 Lean 机器化

文件 `examples/lean/Funanalysis/Ch60MeanErgodic.lean`。本树
mathlib 有 `Mathlib.Analysis.InnerProductSpace.MeanErgodic.lean`
（L2 批侦察时发现的宝藏）：

```lean
-- 平均遍历定理（birkhoffAverage 形式）：
theorem LinearMap.tendsto_birkhoffAverage_of_ker_subset_closure
    (f : E →ₗ[𝕜] E) (k : E →ₗ[𝕜] E) ...
    : ∀ x, Tendsto (fun n => birkhoffAverage 𝕜 f n x) atTop (𝓝 (k x))

-- 正交投影形式：
theorem ContinuousLinearMap.tendsto_birkhoffAverage_orthogonalProjection
    (f : E →L[𝕜] E) (hf : f² = f) ...
```

本章文件实例化这两个定理的锚点，并给一个有限维具体例：幂等
矩阵的 birkhoffAverage 显式收敛。

## 60.5 Julia 数值实验

实验文件 `examples/julia/60_mean_ergodic.jl`。

**实验 1：圆周旋转群的三态**。M(T) = (1/N)Σ_{j<N}U(jh)，U =
旋转 (irrational angle α 的酉复合)：(a) g = 常数：平均不动；
(b) g = e^{ikθ}（k ≠ 0）：平均 → 0（模 |几何和| → 0，速率
|sin(Nkα/2)|/N·…）；(c) 随机 g：平均 → 均值（空间平均）。无理
旋转度量传递的数值形态。

**实验 2：倍增映射（离散 Koopman）**。 doubling map D(x) = 2x
mod 1（保 Lebesgue，混合但 Kolmogorov）：KoP 氏复合算子的
时间平均对 5 个测试函数都 → 空间均值（速率 1/N vs 实验 1 的
振荡余项对比）。

**实验 3：非传递流的反例**。流分裂成两个不变区（区间 [0,1/2) 与
[1/2,1) 各自的旋转）：时间平均依赖初值 y（两个不同的值），不等于
全局空间平均——**度量传递性必要**的数值形态。

**实验 4：酉群的 Stone 生成元**。圆周旋转群的生成元 = id/dθ：
数值差商 ‖(U(h)g − g)/h − iGg‖ → 0（光滑 g）；对角化酉矩阵群
（离散谱 λ = e^{itθⱼ}）的特征相位速度 θⱼ = 生成元特征值——
Stone 定理的数值双向。

## 60.6 Python 数值实验

实验文件 `examples/python/60_mean_ergodic.py`。

**实验 1：收敛速率谱**。无理旋转：‖M_N g − ∫g‖~ |e^{iNkα}−1|/(N|e^{ikα}−1|)
型的 Fourier 求和公式逐 k 验证（理论 vs 实测，k = 1..5）。

**实验 2：混合性对比**。倍增映射 vs 旋转：相关函数
⟨g∘Dⁿ, h⟩ → ⟨g⟩⟨h⟩（混合）vs 不衰减仅振荡（传递非混合）——
遍历阶梯两级差的数值。

**实验 3：不变集探测**。非传递流：用时间平均的方差（对初值采样）
作为传递性检验统计量：传递流方差 → 0，非传递流方差 → 正值——
数据驱动的度量传递性判据的雏形。

## 60.7 章末对照表

| Lax | 内容 | Lean | Isabelle | Julia/Python |
|---|---|---|---|---|
| 35.1 Th1 | Stone 定理 | — | — | ✓ 生成元数值 |
| 35.1 引理 2/3 | Bochner 路线 | — | — | （52 章相关） |
| 35.2 Th4 | **平均遍历定理** | ✓ mathlib MeanErgodic | — | ✓ 三态全表 |
| 35.3 | Koopman 群 | — | — | ✓ 复合酉性 |
| 35.3 | 度量传递 ⟺ F=常数 | — | — | ✓ 反例对照 |
| 35.3 (11) | 时间 = 空间平均 | — | — | ✓ 速率谱 |

## 60.8 习题

1. **（纸笔）**补全定理 4 第 1 步的分解 (7)（telescoping 积分）。
2. **（纸笔）**证明 Koopman 算子保一切 Lᵖ 范数（换元公式 +
   保体积）。
3. **（纸笔）**证明无理旋转的 F = 常数（用 Fourier 系数逐个追踪）。
4. **（纸笔）**证明倍增映射是混合的（对 Fourier 基 e^{2πikx} 直接
   计算相关衰减）。
5. **（机器）**Lean：把 mathlib 的 birkhoffAverage 收敛定理实例化
   到 2×2 投影矩阵，数值与机器双验。
6. **（数值）**实验 2 中换成 Arnold 猫映射（矩阵 [[2,1],[1,1]]
   mod 1）：验证混合速率的指数性（与倍增映射的 2⁻ⁿ 对比）。

---

上一章：[59 半群与 Hille-Yosida 定理](docs/59-semigroups.md) · 下一章：[61 Weyl 交换关系与散射理论](docs/61-weyl-scattering.md)
