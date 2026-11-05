import Mathlib.Probability.Martingale.Basic
import Mathlib.Probability.Martingale.Convergence
import Mathlib.Probability.Martingale.Upcrossing
import Mathlib.Probability.Martingale.OptionalStopping

/-!
# 第 47 章 离散鞅 I：概念、鞅变换与收敛（Lean）

胡书 §7.1-7.2 的机器侧。mathlib 有完整的鞅套件——本章前半是**锚墙**，
把胡书每条定理对应到 mathlib 的真名；后半是两个纯代数主件：

- **上穿计数状态机**（`upcrossCount`）：具体有理路径的上穿次数逐条判定，
  以及命题 7.2.1（鞅变换/赌博系统）的路径版增益账；
- **首中时穷举**（`firstHit` + `partSums`）：3 步 ±1 全部 8 条路径上
  `P(τ₁ ≤ 3) = 7/8` 的精确计数。
-/

/-! ## 锚墙：胡书定理 ↔ mathlib 真名 -/

#check @MeasureTheory.Martingale
-- 定义 7.1.1：E[X_{n+1} | F_n] = X_n（鞅）；上/下鞅是 ≤/≥ 版本

#check @MeasureTheory.martingale_condExp
-- 例 7.1.2（Doob 鞅）：Y 可积 ⟹ E[Y | F_n] 关于上升滤流是鞅

#check @MeasureTheory.Martingale.add
-- 注 7.1.4：鞅对加法封闭（neg/sub/smul 同族）

#check @MeasureTheory.Submartingale.mul_integral_upcrossingsBefore_le_integral_pos_part
-- 定理 7.2.1（上穿不等式）：b·∫U ≤ ∫(X_n − a)⁺——Doob 收敛定理的引擎

#check @MeasureTheory.Submartingale.exists_ae_tendsto_of_bdd
-- 定理 7.2.5（Doob 收敛定理）：sup E(X_n⁺) < ∞ ⟹ a.s. 收敛

#check @MeasureTheory.maximal_ineq
-- 定理 7.2.2/7.2.3 面向（Doob 极大不等式的鞅原形，Kolmogorov 不等式是特例）

#check @MeasureTheory.IsStoppingTime
-- 定义 7.4.1（停时）：{T ≤ n} ∈ F_n——第 48 章选样定理的主角

/-! ## 上穿计数状态机 -/

/-- 上穿状态机：`false` 相位 = 等「跌到 a 以下」，`true` 相位 = 等「升到 b 以上」。
每次完整往返计一次上穿（定义同胡书定理 7.2.1 中的 T₁ < T₂ < ⋯）。 -/
def upcrossSt (a b : ℤ) (phase : Bool) : List ℤ → ℕ
  | [] => 0
  | v :: vs =>
      match phase with
      | false => if v ≤ a then upcrossSt a b true vs else upcrossSt a b false vs
      | true => if b ≤ v then 1 + upcrossSt a b false vs else upcrossSt a b true vs
  termination_by xs => xs

/-- 路径 `x` 向上穿越区间 `(a, b)` 的次数。 -/
def upcrossCount (x : List ℤ) (a b : ℤ) : ℕ := upcrossSt a b false x

/-- 振荡路径 `[0,1,0,1]` 对 (3/10, 7/10) 恰有 2 次上穿。 -/
example : upcrossCount [0, 1, 0, 1] 0 1 = 2 := by
  native_decide

/-- 高位悬停 `[1,1,1]` 从未跌到 a 以下——0 次上穿（上穿必须从下往上走完全程）。 -/
example : upcrossCount [1, 1, 1] 0 1 = 0 := by
  native_decide

/-- 半途而废 `[0, 1/2, 1]`：升到 1/2 不算（未过 b 线），继续持有到 1 才计 1 次。 -/
example : upcrossCount [0, 0, 1] 0 1 = 1 := by
  native_decide

/-- **命题 7.2.1 的路径版增益账**：只在「下待发 → 上待收」持有 1 单位的策略，
收益 = (X_{T₂} − X_{T₁}) + (X_{T₄} − X_{T₃}) = 2 ≥ b·U = 7/5——
赌博系统的增益由上穿次数下界控制。 -/
example : (2 : ℤ) ≥ 1 * (upcrossCount [0, 1, 0, 1] 0 1) := by
  native_decide

/-! ## 首中时与停时的穷举账 -/

/-- 部分和：步长列表 → 位置列表。 -/
def partSums : List ℤ → List ℤ
  | [] => []
  | v :: vs => v :: (partSums vs).map (· + v)

/-- 首中时（1 基）：第一个使部分和 ≥ t 的下标；不存在则 none。 -/
def firstHit : List ℤ → ℤ → Option ℕ
  | [], _ => none
  | v :: vs, t => if t ≤ v then some 0 else (firstHit vs t).map (· + 1)

/-- `+1 −1 +1` 首步即中：τ₁ = 1。 -/
example : firstHit (partSums [1, -1, 1]) 1 = some 0 := by
  native_decide

/-- `−1 +1 +1`：S = (−1, 0, 1)，τ₁ = 3。 -/
example : firstHit (partSums [-1, 1, 1]) 1 = some 2 := by
  native_decide

/-- `−1 −1 −1`：始终未中——τ₁ = none（P = 1/8，即 7/8 的来历）。 -/
example : firstHit (partSums [-1, -1, -1]) 1 = none := by
  native_decide

/-- **穷举账**：8 条 3 步 ±1 路径中恰有 5 条的 τ₁ ≤ 3——P(τ₁ ≤ 3) = 5/8
的完全计数证明（与反射原理 P(max ≥ λ) = 2P(S₃ ≥ λ) − P(S₃ = λ) 一致）。 -/
example : (([[-1, -1, -1], [-1, -1, 1], [-1, 1, -1], [-1, 1, 1],
    [1, -1, -1], [1, -1, 1], [1, 1, -1], [1, 1, 1]] : List (List ℤ)).filter
      (fun s => (firstHit (partSums s) 1).isSome)).length = 5 := by
  native_decide
