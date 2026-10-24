import Mathlib.SetTheory.Ordinal.Arithmetic
import Mathlib.SetTheory.Ordinal.FixedPoint
import Mathlib.SetTheory.Ordinal.Veblen
import Mathlib.Tactic

open scoped Ordinal

/-!
# 第 73 章 · 快速增长数论函数层次（冯琦 §1.8.4）

两台发动机：**ε₀ 的官方锚点**（`Ordinal.epsilon_zero_eq_nfp`——
定义 1.82 的塔式 sup 与 mathlib 的不动点定义互认）与 **F_α 层次
的有限段**（mathlib 无 `fastGrowing`，自建：`F_{k+1} = F_k^[·]` 迭代，
极限步对角线 `Fω n = Fk n n`）。F₁、F₂ 的闭式（F₁ n = 2n、
F₂ n = n·2ⁿ）完整归纳证明（定理 1.81(2) 的解析式见证）；F₃ 2 = 2048、
Fω 2 = 8 等样例用 `native_decide`（内核十进制大数运算，F₂ 24 =
402653184 秒出——对照 Coq/Agda 一元 nat 的物理不可行，这是
Lean Nat 的 GMP 字面量红利）。古德斯坦剧场由 Julia/Python/Prolog/
Coq 四通道承载，这里只立层次本身。
-/

namespace Settheory.Ch73

-- ---------- 定义 1.82：ε₀ 的塔式 sup 与官方不动点互认 ----------

/-- 定义 1.82 的塔：0 ↦ 1 ↦ ω ↦ ω^ω ↦ …（`f^[n] 0`，f = ω^·）。
mathlib 的 ε₀ 定义为该迭代列的 sup（`iSup_iterate_eq_nfp`）
经不动点语言（`epsilon_zero_eq_nfp`）的官方化身。 -/
theorem eps0_eq_iSup : (⨆ n : ℕ, (fun x : Ordinal => ω ^ x)^[n] 0) = ε₀ :=
  (Ordinal.iSup_iterate_eq_nfp _ _).trans (Ordinal.epsilon_zero_eq_nfp).symm

/-- 塔的每一项都是序数幂的形式：前两项现形（ω^0 = 1、ω^1 = ω）。 -/
example : (fun x : Ordinal => ω ^ x)^[1] 0 = 1 := by
  rw [Function.iterate_succ_apply', Function.iterate_zero_apply,
    Ordinal.opow_zero]

example : (fun x : Ordinal => ω ^ x)^[2] 0 = ω := by
  rw [Function.iterate_succ_apply', Function.iterate_succ_apply',
    Function.iterate_zero_apply, Ordinal.opow_zero, Ordinal.opow_one]

-- ---------- 定义 1.84：F 层次（有限段） ----------

/-- F₀(n) = n+1（ successor 是整条楼梯的第一级）。 -/
def F0 : ℕ → ℕ := (· + 1)

/-- F_{k+1}(n) = F_kⁿ(n)——n 次迭代（`Function.iterate` 即 f^[n]）。 -/
def F1 (n : ℕ) : ℕ := F0^[n] n

def F2 (n : ℕ) : ℕ := F1^[n] n

def F3 (n : ℕ) : ℕ := F2^[n] n

/-- 可变层数：Fk (k+1) n = (Fk k)^[n] n；极限步的对角线化身
Fω n = Fk n n（定义 1.84(c) 的有限段投影）。 -/
def Fk : ℕ → ℕ → ℕ
  | 0 => F0
  | k + 1 => fun n => (Fk k)^[n] n

def Fω (n : ℕ) : ℕ := Fk n n

-- ---------- 闭式：F₁ n = 2n、F₂ n = n·2ⁿ ----------

/-- F₀ 的 k 次迭代 = 加 k。 -/
theorem F0_iter (k x : ℕ) : F0^[k] x = x + k := by
  induction k generalizing x with
  | zero => rfl
  | succ k ih =>
    rw [Function.iterate_succ_apply, ih, show F0 x = x + 1 from rfl]
    omega

/-- F₁ 的一步闭式：F1 x = 2x（由 F0_iter 直接读出）。 -/
theorem F1_step (x : ℕ) : F1 x = x * 2 := by
  rw [show F1 x = F0^[x] x from rfl, F0_iter]
  omega

/-- F₁ 的 k 次迭代 = 乘 2^k——层次第二层是"反复翻倍"。 -/
theorem F1_iter (k x : ℕ) : F1^[k] x = x * 2 ^ k := by
  induction k generalizing x with
  | zero => simp
  | succ k ih =>
    rw [Function.iterate_succ_apply, ih, F1_step]
    ring

/-- 定理 1.81(2) 的解析式见证一：F₁ n = 2n。 -/
theorem F1_closed (n : ℕ) : F1 n = 2 * n := by rw [F1_step, mul_comm]

/-- 定理 1.81(2) 的解析式见证二：F₂ n = n·2ⁿ。 -/
theorem F2_closed (n : ℕ) : F2 n = n * 2 ^ n := F1_iter n n

-- ---------- <* 见证（定义 1.85 的有限截面） ----------

/-- F₀ <\* F₁：从 n = 2 起 F₁ 全灭 F₀。 -/
theorem F0_lt_F1 {n : ℕ} (h : 2 ≤ n) : F0 n < F1 n := by
  rw [show F0 n = n + 1 from rfl, F1_closed]
  omega

/-- F₁ <\* F₂：从 n = 5 起 F₂ 全灭 F₁（2ⁿ ≥ 4 已够，n ≥ 2 即真，
取 5 与计算通道的样本表对齐）。 -/
theorem F1_lt_F2 {n : ℕ} (h : 5 ≤ n) : F1 n < F2 n := by
  rw [F1_closed, F2_closed]
  have hn : 0 < n := by omega
  have h4 : 4 ≤ 2 ^ n :=
    le_trans (by norm_num : 4 ≤ 2 ^ 2) (Nat.pow_le_pow_right (by norm_num) (by omega))
  calc 2 * n = n * 2 := by rw [mul_comm]
    _ < n * 4 := by rw [Nat.mul_lt_mul_left hn]; norm_num
    _ ≤ n * 2 ^ n := Nat.mul_le_mul_left n h4

-- ---------- 数值样例（native_decide：GMP 字面量红利） ----------

/-- F₃(2) = F₂(F₂(2)) = F₂(8) = 8·2⁸ = 2048。 -/
example : F3 2 = 2048 := by native_decide

/-- F_ω(1) = F₁(1) = 2。 -/
example : Fω 1 = 2 := by native_decide

/-- F_ω(2) = F₂(2) = 8。 -/
example : Fω 2 = 8 := by native_decide

/-- F_ω(3) 的最外层自变量：F₂(24) = 402653184（native_decide 毫秒级；
对照 Coq/Agda 一元 nat 的物理不可行）。再外层 F₂(402653184) =
402653184·2^402653184——约 1.2 亿位十进制，连 native 也物理不可行，
层次在第三层就把一切求值器顶穿（定理 1.81(1) 的张力，正文详解）。 -/
example : F2 24 = 402653184 := by native_decide

end Settheory.Ch73
