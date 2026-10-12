# 56 · 迹类算子与 Lidskii 迹公式

> 方阵的迹等于特征值之和——线性代数的一句话，在 Hilbert 空间里
> 变成了 Lidskii 1959 年的深刻定理。它的证明动用了 Fredholm 行列式、
> Weyl 不等式和整函数因子分解的全套兵器。——Lax 第 30 章（意译）

本章覆盖 Lax 第 30 章的主干：极分解与奇异值（30.1）、迹类与迹范数
的理想性质（30.2，含双基刻画 (6) 的全证明）、迹的基底无关性
（30.3 定理 3）、Weyl 不等式 (20)(21) 与 **Lidskii 迹公式**
（Gohberg-Krein 证明）、行列式（30.4）、Mercer 定理与"迹 = 对角
积分"（30.5–30.6），Hilbert-Schmidt 类（30.8）。

## 56.1 极分解与奇异值

**定理 1（极分解）**。紧算子 T = U·A，A = (T*T)^{1/2} ≥ 0 正，
U 在 A 的值域上等距。构造：‖Tu‖ = ‖Au‖ 使 U(Au) := Tu 良定义；
U*U = I 于 ran A（保内积论证 + 正交补上置零）。∎

A 的非零特征值按降序排成 **奇异值** sⱼ(T) > 0，sⱼ → 0。

## 56.2 迹类与迹范数

**定义**。T 紧且 Σsⱼ(T) < ∞ 称**迹类**；Σsⱼ = ‖T‖_tr（迹范数）。

**定理 2（理想性质）**：

1. ‖T*‖_tr = ‖T‖_tr（T*T 与 TT* 的正特征值相同：Az = λz ⟹
   Tz 是 TT* 的特征向量）；
2. ‖BT‖_tr ≤ ‖B‖·‖T‖_tr（二次型比较 (BT)*BT ≤ ‖B‖²T*T ⟹ 特征值
  单调 sⱼ(BT) ≤ ‖B‖sⱼ(T)——第 28 章的单调性定理）；
3. 同理 ‖TB‖_tr ≤ ‖T‖_tr‖B‖；
4. 三角不等式。

(4) 的证明经**双基刻画**——迹类的本质结构：

```
‖T‖_tr = sup{ Σ|(Tfₙ, eₙ)| : (fₙ), (eₙ) 任意两组正交基 }      (6)
```

**证明**：≥ 方向：取 fₙ = A 的特征向量 zₙ、eₙ = Uzₙ（polar 结构
Tf = Σsⱼ(f,zⱼ)wⱼ），逐项给 Σsⱼ 取等；≤ 方向：对一般基，双重
Schwarz + Parseval（‖(fₙ,zⱼ)‖_ℓ² = ‖zⱼ‖ = 1 型）给 Σ|(Tfₙ,eₙ)| ≤
Σsⱼ。(6) 右边是 T 的次可加凸函数 ⟹ 三角不等式。∎

## 56.3 迹：基底无关的求和

**定理 3**。迹类 T 上 Σ(Tfₙ, fₙ) 绝对收敛且**与正交基无关**；
这个数称为 **tr T**。

**证明**：代入 (6) 的结构：Σ(Tfₙ,fₙ) = Σⱼ sⱼΣₙ(fₙ,zⱼ)(wⱼ,fₙ)，内层
绝对收敛（Schwarz + Parseval 两次），故可换序；换序后用 Parseval
恒等式 Σₙ(fₙ,zⱼ))(wⱼ,fₙ) = (wⱼ,zⱼ) —— **fₙ 从公式中消失**：
tr T = Σⱼ sⱼ(wⱼ, zⱼ)，只依赖 T。∎

**定理 4**：|tr T| ≤ ‖T‖_tr；线性；tr T* = conj(tr T)；
**tr TB = tr BT**（B 有界——"迹在交换下不变"，Lidskii 的基石）。

## 56.4 Weyl 不等式与 Lidskii 迹公式

**Weyl 引理 7/8（对数优化不等式）**：对特征值 λⱼ 与奇异值 sⱼ
（都按模排序）：

```
Π_{j≤m} |λⱼ| ≤ Π_{j≤m} sⱼ     （一切 m）                      (15)
```

由 (15) 经凸性引理 8（极值射线分解）推出两条求和型：

```
Σ|λⱼ(T)| ≤ Σsⱼ(T) = ‖T‖_tr                        (20)
Π|1 + rλⱼ| ≤ Π(1 + rsⱼ)     （一切 r > 0）          (21)
```

**定理（Lidskii 迹公式，Lax 定理 8）**。迹类的特征值（按代数重数）：

```
tr T = Σλⱼ(T)。
```

**证明骨架**（Gohberg-Krein；本书第一次同时动用三件重武器）：

1. **有限维逼近**：P₊ 到前 N 个基向量的投影，T_N = P₅T P₅ → T
   （范数）；tr T_N → tr T；若 T 无非零特征值，则 T_N 的谱半径
   ρ_N → 0（引理 9：(T−λ)⁻¹ 的一致估计 + Neumann）。
2. **整函数极限**：有限维特征多项式 D_N(λ) = Π(1 + λλⱼ^{(N)}) →
   e^{−λ·trT}（对数导数 + 引理 9 的谱半径塌陷）。
3. **Weyl 上界 + 多项式 vs 指数**：(21) 给 |D_N(λ)| ≤ Π(1+|λ|sⱼ)，
   取 N → ∞ 与 M 截断：|e^{−λα}| ≤ P_M(|λ|)e^{|λ|ε_M}，其中 α
   是"特征和与迹之差"、ε_M → 0。取 arg α 使 −λα > 0 且 |λ| → ∞：
   **指数吃掉多项式** ⟹ |α| ≤ e^{ε_M} → 0。∎

（"The proof presented above is due to Gohberg and Krein. Lidskii's
proof relied on the Hadamard factorization theorem."——Lax 原注。
书中还有轶闻：Dunford-Schwartz 的书里有此公式却没引 Lidskii，
"Jack Schwartz admitted that he discovered and proved the trace
formula independently."）

## 56.5 迹类行列式

退化算子 G（有限维值域）：det(I+G) = 线性代数；性质：

```
det((I+G)(I+F)) = det(I+G)·det(I+F)                (27a)
det(I+G) = Π(1 + λⱼ)                              (27b)
```

一般迹类 T 用迹范数下的退化逼近定义 det(I+T)，两条性质保持。
第 54 章的 Fredholm 行列式是其特例（且能超出迹类——Lax 30.6 的
反例）。

## 56.6 Mercer 定理与"迹 = 对角积分"

**定理（Mercer，Lax 30.6）**。K 连续、对称、**正**（作为算子
qu ≥ 0）：
```
K(s,t) = Σⱼ κⱼeⱼ(s)eⱼ(t)     （绝对一致收敛）
```
沿对角积分（Dini 定理保证交换合法）：

```
∫K(s,s)ds = Σⱼκⱼ = tr K。                              (32)
```

**定理 12**。迹类 + 连续核 ⟹ tr K = ∫K(s,s)ds（光滑核先证
（Lagrange 基展开系数 = 对角），连续核用软化子逼近；**光滑核迹类**
（定理 13：Courant 原理 + 多项式逼近给 sₙ(K) ≤ Cn^{−b/4}））。∎

**反例（Hilbert 矩阵）**：K(s,t) = 1/(s+t)（对称正），tr 意义下
∫₁⁰K(s,s)ds = ∫ds/2s = ∞——1/(s+t) **不是迹类**（52 章已证它有
界、范数 π）。迹公式的边界在此显形。

**Hilbert-Schmidt 类（30.8）**：Σsⱼ² < ∞ ⟺ 核平方可积
（∫∫|K|² = Σsⱼ²）。HS = 迹类 × 迹类的乘积（反之迹类 = 两个 HS
算子的积）。HS 是 Hilbert 空间（核内积），迹类是其乘法对偶。

## 56.7 Lean 机器化

文件 `examples/lean/Funanalysis/Ch56TraceClass.lean`。mathlib 无
迹类理论（v4.33 树无 `TraceClass`），但**有限维影子**有两条关键
锚点（Analysis/InnerProductSpace/Trace.lean）：

```lean
-- 迹 = 对角内积和（tr T = Σ⟨Teⱼ, eⱼ⟩；命名空间是 LinearMap）
#check @LinearMap.trace_eq_sum_inner
-- T.trace 𝕜 E = ∑ i, ⟪b i, T (b i)⟫_𝕜

-- Lidskii 的有限维版：对称算子的迹 = 特征值和
-- （LinearMap.IsSymmetric.trace_eq_sum_eigenvalues，带维数参数 hn）
#check @LinearMap.IsSymmetric.trace_eq_sum_eigenvalues
-- hT.trace 𝕜 E = ∑ i, hT.eigenvalues hn i

-- 秩一算子 tr(x ⊗ y) = ⟪y, x⟫——54 章秩一行列式的伴生
#check @InnerProductSpace.trace_rankOne
```

## 56.8 Julia 数值实验

实验文件 `examples/julia/56_trace_class.jl`。

**实验 1：Weyl 不等式 (20)(21)**。随机非对称矩阵（谱 vs 奇异值）：
Σ|λ| ≤ Σs 与 Π|1+rλ| ≤ Π(1+rs)（r = 0.1..10 四档）逐个断言；
正交矩阵情形取等（|λⱼ| = sⱼ）。

**实验 2：Hilbert 矩阵反例**。H_{jk} = 1/(j+k+1)：特征值全正、
Σλₙ 数值发散（部分和随 n 增长 ~ log）；奇异值部分和同样发散
——**有界、对称、正，但非迹类**，迹公式在此失效（∫对角 = ∞）。

**实验 3：min(x,y) 核的全套**。（同 54 章实验 4 深化）Mercer 展开
数值收敛（部分和重构 K(s,t) 误差 → 0）；tr = ∫对角 = 1/2 =
Σκⱼ（解析 1/((j−1/2)²π²) 之和）；det(I+tK) = Π(1+tκⱼ) 三方
（级数/离散 det/乘积）一致。

**实验 4：迹的交换不变性**。迹类离散化 T 与随机 B：|tr(BT) −
tr(TB)| < 1e-12（定理 4(iv)），且 |tr(T)| ≤ ‖T‖_tr（奇异值和）。

## 56.9 Python 数值实验

实验文件 `examples/python/56_trace_class.py`。

**实验 1：非正规算子的 Lidskii**。随机三角矩阵（对角 = 特征值）：
tr = Σλ（Lidskii 的直接验证：代数重数计入）；‖T‖_tr = Σs ≥ Σ|λ|
（Weyl (20) 的严格不等号情形：非正规性使奇异值大于特征值模）。

**实验 2：双基刻画 (6)**。迹类矩阵 T：随机正交基对 (F, E) 上
Σ|(Tfₙ,eₙ)| ≤ Σsⱼ（= 极基取等）——(6) 的两方向数值验证。

**实验 3：HS 类的核恒等式**。∫∫|K|²dtds = Σsⱼ²（离散 + 符号
计算对照）对 min(x,y) 与 e^{−|x−y|} 两核；后者 HS 但迹性
（Σsⱼ < ∞?）数值检查——e^{−|x−y|} 的 sⱼ ~ 1/j ⟹ **HS 而非
迹类**（sⱼ² 求和收敛、sⱼ 求和发散），两类分界的数值标本。

## 56.10 章末对照表

| Lax | 内容 | Lean | Isabelle | Julia/Python |
|---|---|---|---|---|
| 30.1 Th1 | 极分解 | — | — | （实验 1 隐含 svd） |
| 30.2 Th2 | 迹范数理想性 | — | — | ✓ 数值采样 |
| 30.2 (6) | 双基刻画 | — | — | ✓ 两方向 |
| 30.3 Th3 | 迹基底无关 | ✓ 有限维 trace | — | ✓（实验 4） |
| 30.3 | Weyl (20)(21) | — | — | ✓ 四档 r |
| 30.3 Th8 | **Lidskii** | ✓ 对称情形 | — | ✓ 非正规 |
| 30.5–6 | Mercer + tr=∫对角 | — | — | ✓ min 核全套 |
| 30.6 | Hilbert 反例 | — | — | ✓ Σλ 发散 |
| 30.8 | HS 类 | — | — | ✓ 两类分界 |

## 56.11 习题

1. **（纸笔）**证明 TT* 与 T*T 有相同的非零特征值（相同重数）。
2. **（纸笔，Lax 习题 2）**‖T‖ ≤ ‖T‖_tr（第一奇异值 ≤ 和）。
3. **（纸笔）**完成 (6) 的 ≤ 方向：双重 Schwarz + 两组 Parseval。
4. **（纸笔，Lax 习题 4）**迹类在迹范数下完备。
5. **（机器）**Lean：把 `trace_eq_sum_inner` 推广到两组不同基的
   迹相等（基底无关性的直接形式）。
6. **（数值）**实验 2 中部分和 Σ_{n≤N}λ(Hilbert) 随 N 的增长拟合
   log 律（理论上 ~ γ + log N 的谐波型），报告拟合斜率。

---

上一章：[55 Toeplitz 与 Hankel 算子](docs/55-toeplitz-hankel.md) · 下一章：[57 Herglotz 表示与自伴谱](docs/57-herglotz-spectral.md)
