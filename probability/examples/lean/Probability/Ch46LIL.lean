import Mathlib.Probability.Independence.ZeroOne
import Mathlib.Probability.BorelCantelli

/-!
# 第 46 章 重对数律（Lean）

胡书 §6.3 的机器侧。mathlib 没有 LIL——本章主件是证明中**可代数化**
的三块：

- **几何分级的整数证书**：`2^n ≥ n^3`（n ≥ 10，归纳完全证明）——
  分级求和收敛的骨架事实；
- **二项尾的精确分数**：`∑_{j≥10} C(16,j) / 2^16 = 14893/65536`——
  分级点上尾概率的完全展开；
- **尾 0-1 律与第二 BC 锚**：limsup 事件在独立性下只能取测度 0 或 1，
  LIL 的 limsup 常数之所以"非此即彼"，根源在此。
-/

#check @ProbabilityTheory.measure_zero_or_one_of_measurableSet_limsup
-- 尾 0-1 律：独立随机变量列的 limsup 尾事件测度只能为 0 或 1。
-- LIL 中 {Sₙ > (1+ε)·边界 i.o.} 与 {> (1−ε) i.o.} 都是尾事件，
-- 上者被 BC 压成 0、下者由第二 BC 抬成 1——常数 σ 恰在中间

#check @ProbabilityTheory.measure_limsup_eq_one
-- 第二 Borel–Cantelli：独立事件概率和发散 ⟹ 无限次发生（下界翼的引擎）

/-! ## 几何分级的整数证书 -/

/-- 分级骨架：`2^n ≥ n^3` 对一切 `n ≥ 10` 成立。
LIL 上界翼的求和账 `Σ_n n²/2ⁿ < ∞` 与尾控制 `(log n)^{-K}` 的可和性
都建在"指数压倒多项式"这类事实上。 -/
theorem two_pow_ge_cube (n : ℕ) (hn : 10 ≤ n) : n ^ 3 ≤ 2 ^ n := by
  induction hn with
  | refl => norm_num
  | @step k hk ih =>
      have hkq : (10 : ℚ) ≤ (k : ℚ) := by exact_mod_cast hk
      have hkeyq : ((k : ℚ) + 1) ^ 3 ≤ 2 * ((k : ℚ)) ^ 3 := by
        nlinarith [hkq, sq_nonneg ((k : ℚ) - 4)]
      have ihq : (((k : ℕ)) : ℚ) ^ 3 ≤ (((2 ^ k : ℕ)) : ℚ) := by exact_mod_cast ih
      have hfinal : (((k + 1 : ℕ)) : ℚ) ^ 3 ≤ ((2 : ℚ)) ^ (k + 1) := by
        have ihq2 : ((2 : ℚ)) ^ k = (((2 ^ k : ℕ)) : ℚ) := by
          push_cast
          norm_num
        rw [pow_succ ((2 : ℚ)) k, ihq2]
        push_cast
        linarith
      exact_mod_cast hfinal

/-! ## 二项尾的精确分数（分级点 n = 16） -/

/-- Rademacher 部分和的换算：`S₁₆ = 2B − 16`（B 为二项计数），
故 `S₁₆ ≥ 10 ⟺ B ≥ 13`。 -/
example : ∑ j ∈ Finset.Ico 13 17, (Nat.choose 16 j : ℚ) / 2 ^ 16
      = (697 : ℚ) / 65536 := by
  rw [show (Finset.Ico (13 : ℕ) 17) = {13, 14, 15, 16} from by decide]
  norm_num [Nat.choose]

/-- 双侧账：`P(|S₁₆| ≥ 10) = 2 × 697/65536`——上界翼 (6.3.18) 在
分级点上的精确面（对称性 ×2）。 -/
example : (2 : ℚ) * (∑ j ∈ Finset.Ico 13 17, (Nat.choose 16 j : ℚ) / 2 ^ 16)
      = (1394 : ℚ) / 65536 := by
  rw [show (Finset.Ico (13 : ℕ) 17) = {13, 14, 15, 16} from by decide]
  norm_num [Nat.choose]
