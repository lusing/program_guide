# 45 · Fredholm 算子与指标

> 可逆性太奢侈；"差有限维可逆"的算子撑起了指标理论。

本章覆盖 Conway §XI.1–§XI.3：Fredholm 算子、
Atkinson 定理（Calkin 代数刻画）、指标的稳定性与同伦不变性。

## 45.1 Fredholm 算子

**定义**。T ∈ B(H)（或 Banach）是 **Fredholm 算子**，若
- dim ker T < ∞；
- ran T 闭且 codim ran T < ∞。

**指标**：index(T) = dim ker T - dim coker T。

**例子**。
- 可逆算子：index 0；
- 单侧移位 S：ker = 0，ran 缺 e₁：**index = -1**
  ——指标非零的第一个例子，纯无穷维现象；
- S* ：index = +1；S ⊕ S*：index = 0（不可逆但指标零）；
- 紧摄动 I + K（K 紧）：Fredholm 且 index 0
  （Fredholm 二择一，第 32 章）。

有限维空间上一切算子都 Fredholm 且 index = 0
（rank-nullity）——**指标是无穷维的示性数**。
数值化身：秩一摄动的行列式引理
det(I + t·uv') = 1 + t⟨v,u⟩ 精确到 10⁻⁸；
奇异情形（⟨v,u⟩ = -1）dim ker = dim coker = 1。

## 45.2 Atkinson 定理

**定理**。T Fredholm ⟺ T 在 **Calkin 代数** B(H)/K(H)
中可逆 ⟺ 存在 S 使 ST - I 与 TS - I 都**紧**。

**意义**：把"差有限维"的可逆性塞进一个**商代数**的
可逆性——第 29 章的理想/商机器在此兑现。
Fredholm 理论 = 商代数 B(H)/K(H) 的谱论。

**伴随**：T Fredholm ⟺ T* Fredholm，且
index(T*) = -index(T)——对偶翻转指标。

## 45.3 指标的基本性质

**定理**。
1. **乘法**：index(ST) = index(S) + index(T)
   （乘法态射到 ℤ——指标是"到整数的连续同态"）；
2. **紧摄动不变**：index(T + K) = index(T)；
3. **同伦不变**：t ↦ Tₜ 连续路径 ⟹ 指标常数；
4. **扰动稳定**：‖S‖ 小 ⟹ index(T+S) = index(T)。

**证明骨架（3）**：指标在开集 {Fredholm} 上局部常数
（小摄动不改核与余核维数——有限维扰动理论），
连通路径上积不出跳跃。∎

**指标 = 拓扑不变量**：同伦类 → ℤ 的完全不变量
（在 B(H) 上）。数值化身：I + t·Hilbert 的谱
全部锁在 1 的 t‖H‖ 邻域内——紧摄动把谱"钉"在
本质谱附近，这正是指标稳定性的谱侧写。

## 45.4 解析指标与几何

指标的三大出场地：
- **泛函分析**：本章的 dim ker - dim coker；
- **几何**：椭圆算子的指标（Atiyah-Singer）：
  ∫示性类 —— 分析指标 = 拓扑指标，
  二十世纪数学的最高峰之一；
- **拓扑**：映射度、绕数（winding number）：
  圆周到自身的映射 f ↦ (1/2πi)∮f'/f——
  Toeplitz 算子的指标恰是符号的绕数（第 46 章）。

单侧移位的 index -1 = 单位圆绕一圈的负向计数：
**指标把分析量翻译成拓扑计数**。

## 45.5 Fredholm 二择一（再访）

第 32 章的定理在 Fredholm 框架里重述：
K 紧 ⟹ I + K Fredholm 且 index 0 ⟹
要么 (I+K)x = y 处处可解，要么齐次有非零解。
指标零 + 核空 ⟹ 满射——有限维直觉的完整存活。

数值化身（第 32 章实验的补完）：
奇异秩一摄动的核与余核都是一维，指标 0；
非奇异参数下可逆性沿参数路径保持（除穿越奇异点）。

## 45.6 机器化与数值实验

**Lean**：Fredholm/指标理论超出 mathlib 现有基础设施
（Calkin 代数未形式化），由数值通道承载。

**Julia/Python**（`45_fredholm.*`）：
- 行列式引理 det(I + t·uv') = 1 + t⟨v,u⟩（4 点对照）；
- 奇异秩一摄动：dim ker = dim coker = 1，指标 0；
- 截断前移：ker = 1、coker = 1（有限维恒零指标），
  无穷维极限 index(S) = -1 的解析对照；
- I + t·Hilbert 谱聚于 1（指标稳定性的谱面）。

## 45.7 习题

1. **（纸笔）** 证明 S 的指标 = -1
   （ker S = 0、ran S = {e₁}⊥）。
2. **（纸笔）** 证明 index(ST) = index(S) + index(T)
   （用核/余核的六项精确列）。
3. **（数值）** 沿 t ∈ [0,1] 扫描 det(I + t·uv')，
   观察指标只在穿越 t = -1/⟨v,u⟩ 时跳变。
4. **（纸笔）** 证明 Fredholm 集是 B(H) 的开集。

---

上一章：[44 Fourier 变换与矩问题](docs/44-fourier-moments.md) · 下一章：[46 本质谱](docs/46-essential-spectrum.md)
