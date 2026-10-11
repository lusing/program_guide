import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Normed.Operator.Basic

/-!
# 第 07 章 · 有界算子与 B(ℋ)（Conway II.1）

对应 `docs/07-bounded-operators.md`。本章在机器中复现 §II.1 主线：

1. **有界 ⟺ 连续**与算子范数（Conway 1.1）：`E →L[𝕜] F` 即有界算子，
   范数的三重刻画见第 04 章；本章补齐代数层面。
2. **B(ℋ) 是赋范代数**（Conway 1.2）：复合的次乘性
   `‖BA‖ ≤ ‖B‖·‖A‖`，mathlib 甚至直接给了 `NormedRing` 实例。
3. **完备性**：B(ℋ,K) 完备——有界算子空间是 Banach 空间。
4. **例子**（Conway 1.3-1.4）：有限维每个线性算子有界；矩阵表示。
5. **乘法算子**（Conway 1.5）与**积分算子**（Conway 1.6）：
   机器侧给 L² 乘法算子的范数控制（≤ 方向），完整形式化留待
   测度论深化章。
-/

open scoped RealInnerProductSpace InnerProductSpace

/-!
## 1. B(ℋ, K) 与算子范数（Conway 1.1）

`E →L[𝕜] F` = 连续（= 有界）线性算子；范数满足
`‖A h‖ ≤ ‖A‖·‖h‖`（第 04 章已证三重刻画）。
-/

section BOps

variable {E F : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
  [NormedAddCommGroup F] [InnerProductSpace ℝ F]

-- 有界性：‖Ah‖ ≤ ‖A‖·‖h‖（Conway 1.1 (d) 的算子形式）
example (A : E →L[ℝ] F) (h : E) : ‖A h‖ ≤ ‖A‖ * ‖h‖ :=
  A.le_opNorm h

end BOps

/-!
## 2. 复合的次乘性（Conway 1.2 (c)）—— B(ℋ) 是赋范代数

`‖B ∘ A‖ ≤ ‖B‖·‖A‖`：一行引用，但这是整个算子理论的代数基石
（第 29 章 Banach 代数的范数公理正是它）。
-/

section NormedRing

variable {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]

-- 次乘性（Conway 1.2 (c)）
example (A B : E →L[ℝ] E) : ‖B.comp A‖ ≤ ‖B‖ * ‖A‖ :=
  ContinuousLinearMap.opNorm_comp_le B A

-- 由此 E →L[ℝ] E 构成赋范环（mathlib 实例，不可计算）
noncomputable example : NormedRing (E →L[ℝ] E) := by infer_instance

-- 数乘齐性（Conway 1.2 (b)）
example (a : ℝ) (A : E →L[ℝ] E) : ‖a • A‖ = |a| * ‖A‖ := by
  rw [norm_smul, Real.norm_eq_abs]

end NormedRing

/-!
## 3. 完备性：B(ℋ, K) 是 Banach 空间

定义域完备时，有界算子空间完备（逐点极限 + 一致收敛论证）。
这是"取极限"进入算子论的门票（第 10 章紧算子的极限刻画要用）。
-/

example {E F : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    [CompleteSpace E] [NormedAddCommGroup F] [InnerProductSpace ℝ F] [CompleteSpace F] :
    CompleteSpace (E →L[ℝ] F) := by infer_instance

/-!
## 4. 有限维：每个线性算子有界（Conway 1.3）

有限维空间上线性 ⟹ 连续。矩阵 = 算子：mathlib 的
`Matrix.toEuclideanCLM` 把矩阵变成连续线性算子。
-/

section FiniteDim

-- 有限维：线性 ⟹ 连续（Conway 1.3 的核心断言，习题 3）
example {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    [FiniteDimensional ℝ E] {F : Type*} [NormedAddCommGroup F] [InnerProductSpace ℝ F]
    (A : E →ₗ[ℝ] F) : Continuous A :=
  LinearMap.continuous_of_finiteDimensional A

-- 矩阵给算子（Conway 1.3 的坐标化身；有限维自动连续）
noncomputable example (M : Matrix (Fin 2) (Fin 3) ℝ) :
    EuclideanSpace ℝ (Fin 3) →L[ℝ] EuclideanSpace ℝ (Fin 2) :=
  (Matrix.toEuclideanLin M).toContinuousLinearMap

end FiniteDim

/-!
## 5. 乘法算子（Conway 1.5）的范数控制：有限维原型

L²(μ) 上 M_φ f = φ·f，‖M_φ‖ = ‖φ‖_∞（等号需 σ-有限，正文有反例）。
机器侧给"≤ 方向"的有限维化身：对角缩放 (xᵢ ↦ dᵢxᵢ) 满足
`‖dx‖ ≤ (max|dᵢ|)·‖x‖`——逐坐标的平方和估计。
-/

section Multiplication

/-- 对角缩放算子的范数上界（Conway 1.5 的 ≤ 方向，EuclideanSpace 版）。
ℝ 上没有 OrderBot，故用 `Finset.sup'`（非空有限集的上确界）。 -/
example (d : Fin 3 → ℝ) (x : EuclideanSpace ℝ (Fin 3)) :
    ‖WithLp.toLp 2 (fun i => d i * x i)‖ ≤
      (Finset.univ.sup' Finset.univ_nonempty fun i => |d i|) * ‖x‖ := by
  set s : ℝ := Finset.univ.sup' Finset.univ_nonempty fun i => |d i| with hs
  have hdle : ∀ i, |d i| ≤ s :=
    fun i => Finset.le_sup' (fun i => |d i|) (Finset.mem_univ i)
  have hsnn : 0 ≤ s :=
    le_trans (abs_nonneg (d ⟨0, by simp⟩)) (hdle ⟨0, by simp⟩)
  -- 两个范数平方都写成坐标平方和
  have hy : ‖WithLp.toLp 2 (fun i => d i * x i)‖ ^ 2
      = ∑ i, (d i * x i) ^ 2 := by
    rw [EuclideanSpace.norm_sq_eq]
    exact Finset.sum_congr rfl fun i _ => by
      simp only [Real.norm_eq_abs, sq_abs]
  have hx : ‖x‖ ^ 2 = ∑ i, (x i) ^ 2 := by
    rw [EuclideanSpace.norm_sq_eq]
    exact Finset.sum_congr rfl fun i _ => by simp [sq_abs]
  -- 逐项：(|dᵢ|·|xᵢ|)² = dᵢ²xᵢ² ≤ s²xᵢ²
  have hle : ∑ i, (d i * x i) ^ 2 ≤ s ^ 2 * ∑ i, (x i) ^ 2 := by
    have h1 : ∑ i, (d i * x i) ^ 2 ≤ ∑ i, (s * |x i|) ^ 2 :=
      Finset.sum_le_sum fun i _ => by
        have hdi : |d i| * |x i| ≤ s * |x i| :=
          mul_le_mul_of_nonneg_right (hdle i) (abs_nonneg _)
        calc (d i * x i) ^ 2 = (|d i| * |x i|) ^ 2 := by
              rw [← abs_mul, sq_abs]
          _ ≤ (s * |x i|) ^ 2 := by
              have h0 : 0 ≤ |d i| * |x i| :=
                mul_nonneg (abs_nonneg _) (abs_nonneg _)
              have h1 : 0 ≤ s * |x i| :=
                mul_nonneg hsnn (abs_nonneg _)
              nlinarith [hdi, h0, h1]
    calc ∑ i, (d i * x i) ^ 2 ≤ ∑ i, (s * |x i|) ^ 2 := h1
      _ = s ^ 2 * ∑ i, (x i) ^ 2 := by
          rw [Finset.mul_sum]
          exact Finset.sum_congr rfl fun i _ => by rw [mul_pow, sq_abs]
  -- 平方比较后开方
  apply le_of_sq_le_sq _ (mul_nonneg hsnn (norm_nonneg x))
  rw [hy]
  nlinarith [hx, hle]

end Multiplication
