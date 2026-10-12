# 08 · 伴随算子

> 取伴随之于算子，如同取共轭之于复数。这个类比值得记在心里，
> 但别太虔诚。——Conway §II.2（意译）

伴随是 Hilbert 空间算子理论的核心对称性——Banach 空间没有这么好的
东西（对偶空间跑到了外面）。本章覆盖 Conway §II.2：sesquilinear
形式的表示、伴随的存在与唯一、代数律、C* 恒等式、自伴/正规/酉的
初等理论、ker–range 对偶。

## 8.1 sesquilinear 形式与伴随的存在

**定义（Conway 2.1）**。u: ℋ×K → 𝔽 **sesquilinear**：第一变元线性、
第二变元共轭线性（"sesqui" = 一个半）。**有界**：|u(h,k)| ≤
M‖h‖‖k‖。

**定理（Conway 2.2）**。u 有界 sesquilinear，则存在**唯一**的
A ∈ B(ℋ,K) 与 B ∈ B(K,ℋ) 使 u(h,k) = ⟨Ah, k⟩ = ⟨h, Bk⟩，且
‖A‖, ‖B‖ ≤ M。

**证明**（存在性，A 的构造）：固定 h，k ↦ u(h,k)‾（共轭一下变
第一线性）是有界线性泛函，Riesz 表示给出向量 Ah，‖Ah‖ ≤ M‖h‖。
唯一性：⟨(A−A')h, k⟩ = 0 ∀k ⟹ A = A'。∎

这是 Riesz 定理的第一个大应用：**每个有界双线性形式都来自一个
算子**。谱理论（谱测度）、GNS 构造（第 35 章）都是这个模式的
重演。

**定义（Conway 2.4）**。上述 B 称为 A 的**伴随**，记 A*。

## 8.2 代数律与范数

**命题（Conway 2.6）**。(αA+B)* = ᾱA* + B*；(AB)* = B*A*（反序！）；
A** = A（对合）；A 可逆 ⟹ A* 可逆且 (A*)⁻¹ = (A⁻¹)*。

**命题（Conway 2.7）**。**‖A‖² = ‖A*A‖**，从而 ‖A‖ = ‖A*‖。

**证明**。‖A‖² = ‖A*h‖² 界的两个方向：‖Ah‖² = ⟨A*h, Ah⟩？直接算
‖A*Ah‖ ≤ ‖A*‖‖Ah‖ ≤ ‖A*‖‖A‖‖h‖ 给 ‖A‖² ≤ ‖A*A‖·……完整的环是：
‖A‖² ≤ ‖A*A‖ ≤ ‖A*‖‖A‖ ≤ ‖A‖²。∎

等式 ‖A*A‖ = ‖A‖² 就是 **C\* 恒等式**——它使 B(ℋ) 成为 C\* 代数的
原型（第 34 章），并且把"乘积范数严格小于因子积"的可能性掐死
（次乘性取等的刚性来源）。

## 8.3 自伴、正规、酉

**定义（Conway 2.11）**。A **hermitian/自伴**：A* = A；A **正规**：
AA* = A*A；U **酉**：U*U = UU* = I（等价：满射等距，2.18）。

类比：自伴 ↔ 实数，酉 ↔ 单位模复数，正规 ↔ 一般复数（谱定理
第 37 章的舞台）。

**命题（Conway 2.12）**。ℋ 是**复**Hilbert 空间时：A 自伴 ⟺
⟨Ah,h⟩ ∈ ℝ ∀h。**实**空间上不成立——旋转 90° 的矩阵 A 满足
⟨Ah,h⟩ = 0 ∀h 但 A* = −A ≠ A。（这是"ℝ vs ℂ"差异的第一个深刻
信号；机器通道里 Julia 的实验 4 数值演示了两侧。）

**命题（Conway 2.13-2.15）**。A 自伴时 ‖A‖ = sup_{‖h‖=1}|⟨Ah,h⟩|；
⟨Ah,h⟩ = 0 ∀h ⟹ A = 0（复空间免自伴假设）。

**命题（Conway 2.16-2.18）**。A 正规 ⟺ ‖Ah‖ = ‖A*h‖ ∀h；A 等距
⟺ A*A = I；酉 ⟺ A*A = AA* = I ⟺ 满射等距 ⟺ 正规等距。

**例（Conway 2.8-2.10）**。乘法算子的伴随 = 共轭符号的乘法算子
（于是 M_φ 正规；φ 实 ⟺ 自伴；|φ|=1 a.e. ⟺ 酉）；积分算子的
伴随 = 核转置（k(x,y) ↦ k(y,x) 的共轭）；**单侧移位** S 的伴随
S*(α₁,α₂,…) = (α₂,α₃,…)（后移）：SS* = I − 投影到 e₁ ≠ S*S = I——
S 是等距但**不正规**（第 06 章伏笔的正式结算）。

## 8.4 ker–range 对偶

**定理（Conway 2.19）**。ker A = (ran A*)⊥，且 (ker A*)⊥ = cl(ran A)。

**证明**。h ∈ ker A ⟺ ⟨Ah, g⟩ = 0 ∀g ⟺ ⟨h, A*g⟩ = 0 ∀g ⟺
h ⊥ ran A*。∎

两行证明，但它是**可解性理论的基石**：方程 Ax = b 有（近似）解
当且仅当 b ⊥ ker A*。第 45 章 Fredholm 指标理论的起点。

## 8.5 机器化：Lean 的 adjoint 生态

`examples/lean/Funanalysis/Ch08Adjoint.lean`。mathlib 把伴随做成
共轭线性等距同构 `adjoint : (E →L F) ≃ₗᵢ⋆ (F →L E)`，记号 `†`：

```lean
-- 定义性质（Conway 2.3）：⟪A x, y⟫ = ⟪x, A† y⟫
example (A : E →L[ℝ] F) (x : E) (y : F) : ⟪A x, y⟫_ℝ = ⟪x, (A†) y⟫_ℝ :=
  (ContinuousLinearMap.adjoint_inner_right A x y).symm

-- 对合（Conway 2.6 (c)）
example (A : H →L[ℝ] H) : ((A†)†) = A := ContinuousLinearMap.adjoint_adjoint A

-- 反序（Conway 2.6 (b)）
example (A B : H →L[ℝ] H) : ((B.comp A)†) = ((A†).comp (B†)) :=
  ContinuousLinearMap.adjoint_comp B A
```

注意 v4.33.1 中 `†` 的结合性需要括号——`(A†) y` 而非 `A† y`；
这是 postfix:1000 记号与内积记号的交互习性（实测坑）。

范数与 C\* 恒等式：

```lean
-- ‖A†‖ = ‖A‖（伴随是等距）
example (A : H →L[ℝ] H) : ‖(A†)‖ = ‖A‖ :=
  (ContinuousLinearMap.adjoint (𝕜 := ℝ)).norm_map A

-- 逐点 C* 恒等式：‖A h‖² = ⟪h, A†A h⟫（2.7 证明的内脏）
example (A : H →L[ℝ] H) (h : H) : ‖A h‖ ^ 2 = ⟪h, (A†) (A h)⟫_ℝ := by
  rw [← real_inner_self_eq_norm_sq, ContinuousLinearMap.adjoint_inner_right A h (A h)]
```

全局版 `‖A† ∘ A‖ = ‖A‖ * ‖A‖` 直接是
`ContinuousLinearMap.norm_adjoint_comp_self`。自伴的谓词是
`IsSelfAdjoint`（star A = A；对 CLM 即 A† = A），封闭性一行：

```lean
example (A B : H →L[ℝ] H) (hA : IsSelfAdjoint A) (hB : IsSelfAdjoint B) :
    IsSelfAdjoint (A + B) := hA.add hB
```

ker–range 对偶（Conway 2.19）的 mathlib 形态是
`ContinuousLinearMap.orthogonal_ker`（ker⊥ = ran† 的闭包）。

## 8.6 机器化：Isabelle 的伴随构造

`examples/isabelle/FA08/T08_Adjoint.thy` 在 real^2 上从头构造：
`adj2 A y = χ k. Σⱼ (A (axis k 1)) $ j * y $ j`（第 k 分量 =
⟨A eₖ, y⟩，按标准基转置），然后完整证明**定义性质**：

```isabelle
theorem adj2_inner:
  assumes lin: "linear A"
  shows "inner (A x) y = inner x (adj2 A y)"
```

证明走基展开（Alin.sum / Alin.scale 的线性性），两侧都化为
Σᵢ xᵢ·⟨A eᵢ, y⟩ 后直接合拢——Conway 2.2 存在性证明的有限维直译。
唯一性用 `all_zero_iff`（与所有向量正交者为零）：若 B₁、B₂ 都满足
定义性质，则 B₁y − B₂y 与一切内积为零。

**机器抓错实录**：初版定义把下标写成 `(A (axis j 1)) $ k`
（第 k 分量 = Σⱼ Mₖⱼyⱼ，恰是 **A y 自己**），于是定理变成
⟨Ax, y⟩ = ⟨x, Ay⟩——对非对称 A **为假**。Isabelle 连续两轮
"Failed to finish proof / 栈溢出"，逼出定义级 bug。这与第 03 章
proj_line_unique 陈述漏洞同属"形式化先于证明暴露数学错误"。

## 8.7 数值实验

**Julia**（`08_adjoint.jl`）：(1) 伴随 = 共轭转置（复随机矩阵的
定义性质）；(2) 500 次随机验证；(3) **C\* 恒等式** ‖A'A‖ = ‖A‖²
与 ‖A'‖ = ‖A‖；(4) 实/复差异（2.12）：随机复矩阵的自伴部分
(A+A')/2 二次型全实（|Im| < 1e-10），反自伴部分 (A−A') 二次型
全纯虚——这正是"复空间中 ⟨Ah,h⟩ ∈ ℝ ⟺ 自伴"的数值内容。

**Python**（`08_adjoint.py`）：积分算子版本——(1) 对称核
k(x,y)=k(y,x)：⟨Kf,g⟩ = ⟨f,Kg⟩（自伴，2.8）；(2) 非对称核：
转置核实现 K†（2.9 的数值化身）；(3) 自伴矩阵特征值全实 vs
一般矩阵出现复特征值（谱实性——谱定理的前奏，第 11 章正式化）。

## 8.8 章末对照表

| Conway | 内容 | Lean | Isabelle | Julia/Python |
|---|---|---|---|---|
| 2.1-2.2 | sesquilinear 表示 | — | — | — |
| 2.3-2.4 | 伴随存在唯一 | `adjoint` equiv + `adjoint_inner_*` | ✓ adj2 构造+唯一性 | ✓ 定义性质 |
| 2.6 | 代数律 | `adjoint_adjoint`/`adjoint_comp` | — | — |
| 2.7 | C* 恒等式 | `norm_adjoint_comp_self` + 逐点版 | — | ✓ ‖A'A‖=‖A‖² |
| 2.11-2.15 | 自伴/正规/酉 | `IsSelfAdjoint` | — | ✓ 谱实性 |
| 2.16-2.18 | 等距/酉刻画 | — | — | ✓（06 章 SS*） |
| 2.19 | ker–range 对偶 | `orthogonal_ker` | — | — |

## 8.9 习题

1. **（纸笔）** Conway 2.6 全部四条的证明。
2. **（纸笔）** Conway 2.10：S*S = I 而 SS* = I − P_{e₁}；由此
   S 不正规。
3. **（纸笔）** Conway 2.12 反例：ℝ² 上旋转 90° 矩阵。
4. **（纸笔）** Conway 习题 11：A、B 自伴 ⟹ AB 自伴 ⟺ AB = BA
   （交换性——正规性概念的种子）。
5. **（机器）** Lean：证明自伴算子的乘积在交换时自伴（用
   `adjoint_comp` 与 IsSelfAdjoint 展开）。
6. **（数值）** Volterra 算子 V 与 V*：数值计算 V + V* 的核
   （它是 [0,1] 上的"指示函数核"），验证 ran(V+V*) = 全空间
   （Conway 习题 7）。

---

上一章：[07 bounded-operators](docs/07-bounded-operators.md) · 下一章：[09 projections](docs/09-projections.md)
