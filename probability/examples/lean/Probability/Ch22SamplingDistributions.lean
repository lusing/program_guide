import Mathlib.Tactic

/-!
# 第 22 章 随机样本与抽样分布（Lean）

本文件只验证第 22 章里"纯代数"的骨架（自洽、无 sorry）：

* Helmert 变换的行正交性：未归一的行向量两两内积为 0、模方分别为 n, 2, 6, 12；
* 平方和分解：Σ(x-μ)² = Σ(x-x̄)² + n(x̄-μ)²；
  Σ(x-x̄)² = y₂²/2 + y₃²/6 (+ y₄²/12)，其中 y_k 是 Helmert 行与 x 的内积
  ——这就是"自由度损失 1"的代数来源；
* χ² 的常数：Γ(1/2)=√π 与正态常数会师、矩账 (ν, 2ν)、自由度相加；
* t² = F 的代数恒等式 (z/√(v/ν))² = z²/(v/ν)；
* 合并方差权重：凸组合且权重 = 自由度占比。
旧 Ch17ChiSquare 的 χ² 常数账并入此处。
-/

/-! ## Helmert 矩阵（未归一）的行正交 -/

/-- n = 3 的 Helmert 行（未归一）：全 1、(1,-1,0)、(1,1,-2)。 -/
def helmert3 : Matrix (Fin 3) (Fin 3) ℚ :=
  !![1, 1, 1; 1, -1, 0; 1, 1, -2]

/-- H Hᵀ = diag(3, 2, 6)：各行两两正交，模方依次为 n, 2, 6。 -/
example : helmert3 * helmert3.transpose = Matrix.diagonal ![3, 2, 6] := by
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [helmert3, Matrix.mul_apply, Fin.sum_univ_three, Matrix.diagonal] <;> norm_num

/-- n = 4 的 Helmert 行（未归一）。 -/
def helmert4 : Matrix (Fin 4) (Fin 4) ℚ :=
  !![1, 1, 1, 1; 1, -1, 0, 0; 1, 1, -2, 0; 1, 1, 1, -3]

/-- H Hᵀ = diag(4, 2, 6, 12)。 -/
example : helmert4 * helmert4.transpose = Matrix.diagonal ![4, 2, 6, 12] := by
  ext i j
  fin_cases i <;> fin_cases j <;>
    simp [helmert4, Matrix.mul_apply, Fin.sum_univ_four, Matrix.diagonal] <;> norm_num

/-- 归一化后的行列式平方：det(H)² = det(H Hᵀ) = 3·2·6 = 36，
所以归一化矩阵 |det| = 36/36 = 1。 -/
example : helmert3.det ^ 2 = 36 := by
  have h : helmert3.det * helmert3.transpose.det = (Matrix.diagonal ![(3 : ℚ), 2, 6]).det := by
    rw [← Matrix.det_mul]
    congr 1
    ext i j
    fin_cases i <;> fin_cases j <;>
      simp [helmert3, Matrix.mul_apply, Fin.sum_univ_three, Matrix.diagonal] <;> norm_num
  rw [Matrix.det_transpose, Matrix.det_diagonal] at h
  simp [Fin.prod_univ_three] at h
  nlinarith [h]

/-! ## 平方和分解与自由度损失 -/

/-- 方差分解：Σ(x-μ)² = Σ(x-x̄)² + n(x̄-μ)²（n = 3，x̄ = (x₁+x₂+x₃)/3）。 -/
example (x₁ x₂ x₃ μ : ℚ) :
    (x₁ - μ) ^ 2 + (x₂ - μ) ^ 2 + (x₃ - μ) ^ 2 =
      ((x₁ - (x₁ + x₂ + x₃) / 3) ^ 2 + (x₂ - (x₁ + x₂ + x₃) / 3) ^ 2 +
        (x₃ - (x₁ + x₂ + x₃) / 3) ^ 2) + 3 * ((x₁ + x₂ + x₃) / 3 - μ) ^ 2 := by
  ring

/-- Σ(x-x̄)² = y₂²/2 + y₃²/6：两个 Helmert 坐标恰好吃掉全部离差平方和。
n = 3 个观测只剩 n-1 = 2 个独立平方项 → 自由度 n-1。 -/
example (x₁ x₂ x₃ : ℚ) :
    (x₁ - (x₁ + x₂ + x₃) / 3) ^ 2 + (x₂ - (x₁ + x₂ + x₃) / 3) ^ 2 +
        (x₃ - (x₁ + x₂ + x₃) / 3) ^ 2 =
      (x₁ - x₂) ^ 2 / 2 + (x₁ + x₂ - 2 * x₃) ^ 2 / 6 := by
  ring

/-- n = 4：增加第三个坐标 y₄²/12。 -/
example (x₁ x₂ x₃ x₄ : ℚ) :
    (x₁ - (x₁ + x₂ + x₃ + x₄) / 4) ^ 2 + (x₂ - (x₁ + x₂ + x₃ + x₄) / 4) ^ 2 +
        (x₃ - (x₁ + x₂ + x₃ + x₄) / 4) ^ 2 + (x₄ - (x₁ + x₂ + x₃ + x₄) / 4) ^ 2 =
      (x₁ - x₂) ^ 2 / 2 + (x₁ + x₂ - 2 * x₃) ^ 2 / 6 +
        (x₁ + x₂ + x₃ - 3 * x₄) ^ 2 / 12 := by
  ring

/-- 第一个坐标 y₁ = (x₁+x₂+x₃)/√3，所以 y₁² = 3 x̄²：均值部分占掉第 1 个自由度。 -/
example (x₁ x₂ x₃ : ℚ) :
    (x₁ + x₂ + x₃) ^ 2 / 3 = 3 * ((x₁ + x₂ + x₃) / 3) ^ 2 := by
  ring

/-! ## χ² 的常数与矩账（并入旧 Ch17ChiSquare） -/

/-- χ²(1) 的分母 2^{1/2}Γ(1/2) = √2·√π，平方是 2π：Γ(1/2)=√π 与正态常数会师。 -/
example : (Real.sqrt 2 * Real.sqrt Real.pi) ^ 2 = 2 * Real.pi := by
  rw [mul_pow, Real.sq_sqrt (by positivity), Real.sq_sqrt (by positivity)]

/-- χ²(ν) 的矩账：E[Y]=ν，E[Y²]=ν²+2ν，故 Var=2ν（ν = 3：E[Y²] = 15，Var = 6）。 -/
example : ((3 : ℚ)) ^ 2 + 2 * 3 = 15 ∧ (15 : ℚ) - 3 ^ 2 = 6 := by norm_num

/-- 任意 ν 的方差账：(ν²+2ν) - ν² = 2ν。 -/
example (ν : ℚ) : (ν ^ 2 + 2 * ν) - ν ^ 2 = 2 * ν := by ring

/-- 自由度相加：Γ(a, ·) 形状参数 a = ν/2 相加 ⇔ ν 相加（3/2 + 4/2 = 7/2）。 -/
example : (3 : ℚ) / 2 + 4 / 2 = 7 / 2 := by norm_num

/-- 同常数巧合：2^{3/2}Γ(3/2) = 2√2·(√π/2) = √2·√π，系数账 8·(1/2)² = 2。 -/
example : ((8 : ℚ)) * (1 / 2) ^ 2 = 2 ∧ ((2 : ℚ)) * (1 / 2) = 1 := by norm_num

/-- χ²(2) 的密度常数 1/(2^{1}Γ(1)) = 1/2。 -/
example : ((1 : ℚ)) / (2 * 1) = 1 / 2 := by norm_num

/-- χ²(4) 的密度常数 1/(2²Γ(2)) = 1/4。 -/
example : ((1 : ℚ)) / (4 * 1) = 1 / 4 := by norm_num

/-! ## t² = F 与合并方差 -/

/-- t² 的代数形式：(z/√(v/ν))² = z²/(v/ν)（v > 0）。z² ~ χ²(1) 与 v ~ χ²(ν) 独立时，
右端就是 (z²/1)/(v/ν) ~ F(1,ν)。 -/
example (z v ν : ℝ) (hv : 0 < v) (hν : 0 < ν) :
    (z / Real.sqrt (v / ν)) ^ 2 = z ^ 2 / (v / ν) := by
  rw [div_pow, Real.sq_sqrt (by positivity)]

/-- 合并方差的权重：(m-1)/(m+n-2) + (n-1)/(m+n-2) = 1，因此是凸组合。 -/
example (m n : ℚ) (h : m + n - 2 ≠ 0) :
    (m - 1) / (m + n - 2) + (n - 1) / (m + n - 2) = 1 := by
  field_simp
  ring

/-- 数值例：m = 5, n = 11：权重 4/14 = 2/7 与 10/14 = 5/7。 -/
example : (5 - 1 : ℚ) / (5 + 11 - 2) = 2 / 7 ∧ (11 - 1 : ℚ) / (5 + 11 - 2) = 5 / 7 := by
  norm_num

/-- 合并方差 = 合并平方和 / 总自由度：
((m-1)s₁² + (n-1)s₂²)/(m+n-2) = (SS₁ + SS₂)/(m+n-2)，其中 SS = (自由度)·s²。 -/
example (m n s₁ s₂ : ℚ) (h : m + n - 2 ≠ 0) :
    ((m - 1) * s₁ + (n - 1) * s₂) / (m + n - 2) =
      (m - 1) / (m + n - 2) * s₁ + (n - 1) / (m + n - 2) * s₂ := by
  field_simp
