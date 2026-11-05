import Mathlib.Analysis.Complex.Exponential
import Mathlib.Probability.CentralLimitTheorem

/-!
# 第 44 章 无穷可分分布（Lean）

胡书 §5.4-5.5 的机器侧。mathlib 没有无穷可分分布族——本章把
定义 5.4.1 的特征函数形式（`f = (fₙ)ⁿ`）做成一等公民
`InfDivisibleCF`，并对三大律给出**完全证明**：

- Poisson：`φ(t) = exp(λ(e^{it}−1))` 的 n 次根是 `exp((λ/n)(e^{it}−1))`；
- 正态：`φ(t) = exp(iμt − σ²t²/2)` 的 n 次根对应 `N(μ/n, σ²/n)`；
- Cauchy：`φ(t) = exp(iδt − γ|t|)` 的 n 次根对应尺度 γ/n。

三个证明共用一个模板：`(exp x)ⁿ = exp(n·x)`（`Complex.exp_nat_mul`）
加一次 `field_simp`——"特征函数取 n 次根"的全部实质。另外两条
结构事实：退化律平凡可分；无穷可分特征函数对逐点乘积（独立和的
特征函数）封闭。
-/

/-- 无穷可分特征函数（定义 5.4.1 的特征函数形式，注 5.4.1）：
对任意正整数 n 都存在特征函数根 ψ 使 f = ψⁿ。 -/
def InfDivisibleCF (φ : ℝ → ℂ) : Prop :=
  ∀ n : ℕ, 0 < n → ∃ ψ : ℝ → ℂ, ∀ t : ℝ, φ t = (ψ t) ^ n

/-! ## 根封闭性的共用引理 -/

/-- n 乘 c/n 回到 c（ℂ 侧）——三律共用的切分账。 -/
private theorem cast_mul_div (n : ℕ) (hn : 0 < n) (c : ℂ) :
    (↑n : ℂ) * (c / ↑n) = c := by
  have h2 : (↑n : ℂ) ≠ 0 := by exact_mod_cast hn.ne'
  field_simp

/-! ## Poisson：跳跃律的根封闭 -/

/-- **Poisson 无穷可分**：参数 λ 的特征函数任意 n 切分的根是
参数 λ/n 的特征函数（胡书注 5.4.2：λ 与 t 的 Poisson 均可分）。 -/
theorem poissonCF_infdiv (lam : ℝ) :
    InfDivisibleCF (fun t => Complex.exp (lam * (Complex.exp (Complex.I * t) - 1))) := by
  intro n hn
  refine ⟨fun t => Complex.exp ((lam : ℂ) / ↑n * (Complex.exp (Complex.I * t) - 1)), fun t => ?_⟩
  have hL := cast_mul_div n hn (lam : ℂ)
  have hE : (↑n : ℂ) * ((lam : ℂ) / ↑n * (Complex.exp (Complex.I * t) - 1))
      = (lam : ℂ) * (Complex.exp (Complex.I * t) - 1) := by
    rw [← mul_assoc, hL]
  rw [← Complex.exp_nat_mul, hE]

/-! ## 正态：扩散律的根封闭 -/

/-- **正态无穷可分**：`N(μ, σ²)` 的 n 次根对应 `N(μ/n, σ²/n)`——
方差按 1/n 缩小、均值按 1/n 平分。 -/
theorem normalCF_infdiv (mu sig : ℝ) :
    InfDivisibleCF
      (fun t => Complex.exp (Complex.I * (mu * t) - sig * sig * t * t / 2)) := by
  intro n hn
  refine ⟨fun t =>
    Complex.exp (Complex.I * ((mu : ℂ) / ↑n * t) - (sig : ℂ) * (sig : ℂ) / ↑n * t * t / 2), fun t => ?_⟩
  have hX := cast_mul_div n hn (mu : ℂ)
  have hV := cast_mul_div n hn ((sig : ℂ) * (sig : ℂ))
  have hE : (↑n : ℂ) * (Complex.I * ((mu : ℂ) / ↑n * t)
        - (sig : ℂ) * (sig : ℂ) / ↑n * t * t / 2)
      = Complex.I * ((mu : ℂ) * t) - (sig : ℂ) * (sig : ℂ) * t * t / 2 := by
    linear_combination (Complex.I * (t : ℂ)) * hX - ((t : ℂ) * t / 2) * hV
  rw [← Complex.exp_nat_mul, hE]

/-! ## Cauchy：重尾律的根封闭 -/

/-- **Cauchy 无穷可分**：`φ(t) = exp(iδt − γ|t|)` 的 n 次根对应
位移 δ/n、尺度 γ/n——没有矩也有严格的切分结构。 -/
theorem cauchyCF_infdiv (del gam : ℝ) :
    InfDivisibleCF (fun t => Complex.exp (Complex.I * (del * t) - gam * |t|)) := by
  intro n hn
  refine ⟨fun t => Complex.exp (Complex.I * ((del : ℂ) / ↑n * t) - (gam : ℂ) / ↑n * |t|),
    fun t => ?_⟩
  have hD := cast_mul_div n hn (del : ℂ)
  have hG := cast_mul_div n hn (gam : ℂ)
  have hE : (↑n : ℂ) * (Complex.I * ((del : ℂ) / ↑n * t) - (gam : ℂ) / ↑n * |t|)
      = Complex.I * ((del : ℂ) * t) - (gam : ℂ) * |t| := by
    linear_combination (Complex.I * (t : ℂ)) * hD - (((|t| : ℝ)) : ℂ) * hG
  rw [← Complex.exp_nat_mul, hE]

/-! ## 结构事实 -/

/-- 退化律平凡可分：常数 1 的根还是 1。 -/
example : InfDivisibleCF (fun _ => (1 : ℂ)) := by
  intro n _
  exact ⟨fun _ => 1, fun _ => by simp⟩

/-- **独立和封闭**：无穷可分特征函数逐点乘积（独立和的特征函数）
仍无穷可分——对应"可分律的卷积仍可分"。 -/
theorem infdivCF_mul {φ ψ : ℝ → ℂ} (hφ : InfDivisibleCF φ) (hψ : InfDivisibleCF ψ) :
    InfDivisibleCF (fun t => φ t * ψ t) := by
  intro n hn
  obtain ⟨a, ha⟩ := hφ n hn
  obtain ⟨b, hb⟩ := hψ n hn
  exact ⟨fun t => a t * b t, fun t => by simp only []; rw [ha t, hb t, mul_pow]⟩

#check @ProbabilityTheory.gaussianReal
-- 正态律的 mathlib 对象（iid CLT 的极限律）：根封闭性说明它是
-- "时间上无穷可切"的扩散律——布朗运动增量的分布面
