# 04 · Riesz 表示定理

> 本章标题有些含混——至少有两个"Riesz 表示定理"。——Conway §I.3 开篇

Conway 风趣地提醒读者：这个名字被复用太多次（另一个在 C(X) 的对偶
表示，第 17 章）。本节的主角是：**Hilbert 空间上每个连续线性泛函都是
内积**。这是 Hilbert 空间自对偶性的精确表述，也是全书后文一切"对偶"
论证的 Hilbert 侧基石。

## 4.1 有界线性泛函

**命题（Conway 3.1）**。L : ℋ → 𝔽 线性。以下等价：

- (a) L 连续；
- (b) L 在 0 处连续；
- (c) L 在某点连续；
- (d) ∃c > 0, ∀h, |L(h)| ≤ c‖h‖。

**证明**。(a)⟹(b)⟹(c) 显然；(d)⟹(b)：‖h‖ < 1/c ⟹ |L(h)| < 1。
(c)⟹(a)：L 在 h₀ 连续且 hₙ → h，则 hₙ - h + h₀ → h₀，故
L(hₙ) = L(hₙ - h + h₀) + L(h) - L(h₀) → L(h₀) + L(h) - L(h₀) = L(h)。
(b)⟹(d)：连续性给出 δ > 0 使 ‖h‖ < δ ⟹ |L(h)| < 1；对任意 h ≠ 0，
取 h' = δ/(2‖h‖)·h（‖h'‖ < δ），则 |L(h')| < 1 即 |L(h)| < 2‖h‖/δ。∎

**定义（Conway 3.2）**。满足 (d) 的 L 称**有界线性泛函**。定义范数

‖L‖ = sup{|L(h)| : ‖h‖ ≤ 1}。

**命题（Conway 3.3）**。‖L‖ = sup_{‖h‖=1} |L(h)| = sup_{h≠0} |L(h)|/‖h‖
= inf{c : ∀h, |L(h)| ≤ c‖h‖}，且 |L(h)| ≤ ‖L‖‖h‖。

（证明是 ε-管理练习；线性性把单位球上的上确界放大到全空间。）

**观察**。固定 h₀，则 L(h) := ⟨h, h₀⟩ 是有界线性泛函（CBS 给界
‖h₀‖），且 ‖L‖ = ‖h₀‖：上界由 CBS，下界取 h = h₀/‖h₀‖ 时 L(h) 恰为
‖h₀‖。**内积泛函保范**。Riesz 定理说这就是全部。

## 4.2 Riesz 表示定理

**定理（Conway 3.4）**。L : ℋ → 𝔽 有界线性泛函。则存在**唯一** h₀ ∈ ℋ
使 L(h) = ⟨h, h₀⟩ 对一切 h；且 ‖L‖ = ‖h₀‖。

**证明**。ℳ = ker L：连续性 ⟹ ℳ 闭。若 ℳ = ℋ 则 L = 0，取 h₀ = 0。
否则 ℳ⊥ ≠ {0}（正交分解定理：ℋ = ℳ ⊕ ℳ⊥），取 f₀ ∈ ℳ⊥ 使
L(f₀) = 1（缩放任意非零元）。对任意 h：h - L(h)f₀ ∈ ℳ，因为
L(h - L(h)f₀) = L(h) - L(h)·1 = 0。于是

0 = ⟨h - L(h)f₀, f₀⟩ = ⟨h, f₀⟩ - L(h)‖f₀‖²，

故 **h₀ := f₀/‖f₀‖² 满足 L(h) = ⟨h, h₀⟩**。

唯一性：若 ⟨h, h₀⟩ = ⟨h, h₁⟩ 对一切 h，取 h = h₀ - h₁ 得
‖h₀ - h₁‖² = 0。

范数等式已含在观察中。∎

**推论（Conway 3.5）**。L²(μ) 上的有界线性泛函都是 F(h) = ∫ h h₀ dμ，
h₀ ∈ L²(μ) 唯一。

注意这个推论通常被当作 L^p 对偶（p = 2 情形）的特例，但 Conway 指出
它是**纯 Hilbert 空间事实**——不需要 Radon-Nikodym 机器。

**应用一览**（后文展开）：弱收敛的可判定性（ℋ* = ℋ 使弱拓扑可用内积
描述）；谱测度的构造（第 36 章：表示论的核心引理就是 Riesz）；共轭
线性同构 J : ℋ → ℋ* 称为对偶映射，它是等距**反**同构（𝔽 = ℂ 时
h ↦ ⟨·, h⟩ 共轭线性——约定差异再次现身）。

## 4.3 机器化：mathlib 的 toDual

mathlib 的 `Mathlib.Analysis.InnerProductSpace.Dual` 把上面的观察与
定理组织成三步：`toDualMap`（等距嵌入）⟶ 完备性 ⟶ `toDual`（等距
同构）。定义：

```lean
/-- Fréchet-Riesz 表示：完备时 toDualMap 满射，升级为等距同构 -/
def toDual : E ≃ₗᵢ⋆[𝕜] StrongDual 𝕜 E :=
  LinearIsometryEquiv.ofSurjective (toDualMap 𝕜 E) (by ...)
```

`≃ₗᵢ⋆` 的 `⋆` 表示**共轭**线性等距同构——mathlib 诚实编码了
"h ↦ ⟨·, h⟩ 是反线性"这一事实（在它的第一变元共轭约定下是 h ↦ ⟪h, ·⟫
线性……两个约定绕一圈，数学内容一致：**对偶映射是半线性等距**）。

mathlib 自己的满射性证明**就是 Conway 的核-正交补路线**，源码值得
直接读（这里摘录骨架，见 `Dual.lean`）：

```lean
    intro ℓ
    set Y := ℓ.ker
    by_cases htriv : Y = ⊤
    · -- ℓ = 0 情形，表示向量取 0
      exact ⟨0, by simp [hℓ]⟩
    · -- 核非全空间：取 z ∈ Yᗮ 非零
      rw [← Submodule.orthogonal_eq_bot_iff] at htriv
      obtain ⟨z, hz, z_ne_0⟩ := (Submodule.ne_bot_iff).mp htriv
      -- 表示向量：⟨z, z⟩⁻¹ • z 的共轭倍
      refine ⟨(conj (ℓ z) / ⟪z, z⟫) • z, ?_⟩
      -- 关键一步：ℓ z • x - ℓ x • z ∈ ker（⟨z, ·⟩ 与 ℓ 平行的代数心脏）
      ...
```

与我们 4.2 的证明逐行对应：核、正交补取向量、构造 h₀、验证。**数学
共同体与形式化社区独立收敛到了同一个证明**——这大概是"标准证明"
最严格的定义。

我们的 `examples/lean/Funanalysis/Ch04Riesz.lean` 把满射性展开成书上的
陈述：

```lean
theorem fa_riesz_repr (L : E →L[ℂ] ℂ) :
    ∃ x₀ : E, ∀ y, L y = ⟪x₀, y⟫ := by
  obtain ⟨x₀, hx₀⟩ := (InnerProductSpace.toDual ℂ E).surjective L
  exact ⟨x₀, fun y => by
    have h1 : (InnerProductSpace.toDual ℂ E) x₀ y = L y := by
      rw [hx₀]
      rfl
    rw [← InnerProductSpace.toDual_apply_apply]
    exact h1⟩
```

（`toDual_apply_apply : toDual 𝕜 E x y = ⟪x, y⟫` 是 `rfl`——表示公式
在定义层就是恒等式。）唯一性按书的正交论证手工做：

```lean
theorem fa_riesz_unique {x₀ x₁ : E}
    (h : ∀ y, ⟪x₀, y⟫ = ⟪x₁, y⟫) : x₀ = x₁ := by
  have hdiff : ∀ y, ⟪x₀ - x₁, y⟫ = 0 := by
    intro y
    rw [inner_sub_left, h y, sub_self]
  have hself := hdiff (x₀ - x₁)
  rw [inner_self_eq_zero] at hself
  exact sub_eq_zero.mp hself
```

范数等式（`fa_riesz_norm`）由 `toDual` 的等距性一步：同构保持范数，
而表示向量在等距下正好对应 L。文件末尾还有 `innerSL` 的观察侧：
`‖(InnerProductSpace.toDualMap 𝕜 E x)‖ = ‖x‖`——保范嵌入。

## 4.4 机器化：Isabelle 的有限维全文

HOL-Analysis 没有一般 Hilbert 空间的 Riesz 定理（这是 Lean 通道更强
的又一个例子）。`examples/isabelle/FA04/T04_Riesz.thy` 在 real^2 上把
定理证到底。表示向量按"基值拼装"：

```isabelle
definition rep_vec :: "(real^2 \<Rightarrow> real) \<Rightarrow> real^2" where
  "rep_vec L = (\<chi> i. L (axis i 1))"

lemma rep_vec_works:
  fixes L :: "real^2 \<Rightarrow> real"
  assumes "bounded_linear L"
  shows "L y = inner y (rep_vec L)"
```

证明的骨架是两条求和：`L y` 沿基展开（`basis_expansion` + 线性性），
`inner y (rep_vec L)` 按定义就是同一组系数的内积展开，逐项相等。然后
**范数等式**：

```isabelle
lemma onorm_eq_rep_vec:
  fixes L :: "real^2 \<Rightarrow> real"
  assumes "bounded_linear L"
  shows "onorm L = norm (rep_vec L)"
```

双向：≤ 用 CBS（onorm_le 路线），≥ 用测试向量 h 本身
（L h = ‖h‖² ⟹ ‖h‖² ≤ onorm·‖h‖ ⟹ 消去正因子）。`onorm` 是
Isabelle 对谓词式 `bounded_linear` 泛函的算子范数——有限维的"每个
线性泛函有界"隐含在 rep_vec 构造的自由性里（构造本身不需要 L 有界；
有界性只进范数部分）。

## 4.5 数值实验

**实验 1（表示向量构造）**：L(y) = 3y₁ + 4y₂ - y₃ 的表示向量就是
(3,4,-1)：`examples/python/04_riesz.py` 随机验证 L(y) = ⟨y, h₀⟩ 精确
成立（同表达式），且在 h₀/‖h₀‖ 方向 L 取满范数 ‖h₀‖ = √50。

**实验 2（Riesz 逆问题）**：只给泛函的 7 个采样值（随机向量上的 L 值），
最小二乘恢复 h₀ 到 1e-10——**Riesz 定理是良定的逆问题**：泛函的采样
唯一决定表示向量（在采样张成 h₀ 的前提下）。

**实验 3（L² 的 Parseval 预告）**：g(t) = sin 2πt + ½cos 6πt 在
L²[0,1] 的范数平方 = 5/8 = ½ + ⅛（正交频率的能量相加——勾股定理的
函数版）。蒙特卡洛 4×10⁵ 点对上解析值。第 05-06 章（正交基与 Fourier）
将把"能量按频率分解"变成系统的理论。

## 4.6 章末对照表

| Conway | 内容 | Lean | Isabelle | Julia/Python |
|---|---|---|---|---|
| 3.1/3.3 | 有界 ⟺ 连续、范数 | `E →L[𝕜] 𝕜` 类型即有界 | `bounded_linear` + `onorm` | — |
| 3.4 前观察 | ‖⟨·, h₀⟩‖ = ‖h₀‖ | `toDualMap` 等距 | `Cauchy_Schwarz_ineq2` 双向 | 实验 1 |
| 3.4 存在 | Riesz 表示 | `fa_riesz_repr`（经 toDual 满射） | `rep_vec_works`（real^2） | — |
| 3.4 唯一 | 正交论证 | `fa_riesz_unique` 手工 | — | — |
| 3.4 范数 | ‖L‖ = ‖h₀‖ | `fa_riesz_norm` | `onorm_eq_rep_vec` | 实验 1 |
| 3.5 | L² 对偶 | `MeasureTheory.innerProductSpace` 实例 | — | 实验 3 |

## 4.7 习题

1. **（纸笔）** Conway 练习 5：𝔍 = 例 1.8 的空间（⟨f,g⟩ = ∫f'ḡ'），
   求值泛函 L(h) = h(t) 的表示向量（提示：Green 函数
   h₀(s) = min(s, t)）。
2. **（纸笔）** Conway 练习 6：证明 L²[0,1] 上不存在有界泛函与
   C¹ 函数的求导运算一致（求导无界）。
3. **（机器）** Lean：把 `fa_riesz_repr` 强化为 `∃!`（存在唯一）版本，
   唯一性部分直接调用 `fa_riesz_unique`。
4. **（机器）** Isabelle：real^3 上重做 `rep_vec_works`（改动类型与
   axis 指标即可——体会"维数在类型里"的含义）。
5. **（数值）** Hilbert 矩阵 H₅（病态矩阵）作为 L² 离散内积：数值上
   求泛函 L(x) = e₁ᵀx 的表示向量，与解析解 H⁻¹e₁ 对照，观察病态性
   放大（这预告了第 12 章 Sturm-Liouville 数值的稳定性问题）。

---

上一章：[03 orthogonality](docs/03-orthogonality.md) · 下一章：[05 orthonormal-bases](docs/05-orthonormal-bases.md)
