import Mathlib.Tactic

/-!
# 第 128 章 自然数与递归定理（Lean）

递归定理（书 3.2.1）在 Lean 里不是定理而是**语言原语**：`Nat.rec`
就是它。本单元用 `Nat.rec` 从零重造加法与乘法（书 3.2.4/3.2.5 的
定义原样），再按书的证明结构重演交换律的双重归纳；最后点出
第二归纳原理与良序原理的机器化身。
-/

/-! ## 递归定理的双实例 -/

/-- 加法（书 3.2.6）：m + 0 = m；m + (n+1) = (m+n)+1。
递归变量是第二个参数——`Nat.rec m Nat.succ` 逐字翻译。 -/
def add' (m : ℕ) : ℕ → ℕ :=
  Nat.rec (motive := fun _ => ℕ) m (fun _ acc => Nat.succ acc)

theorem add'_zero (m : ℕ) : add' m 0 = m := rfl

theorem add'_succ (m n : ℕ) : add' m (n + 1) = (add' m n) + 1 := rfl

/-- 乘法（书 3.2.6）：m · 0 = 0；m·(n+1) = m·n + m。 -/
def mul' (m : ℕ) : ℕ → ℕ :=
  Nat.rec (motive := fun _ => ℕ) 0 (fun _ acc => add' acc m)

theorem mul'_zero (m : ℕ) : mul' m 0 = 0 := rfl

theorem mul'_succ (m n : ℕ) : mul' m (n + 1) = add' (mul' m n) m := rfl

/-! ## 交换律：书 3.2.7(1) 证明结构的重演 -/

/-- 内层引理：0 是左单位——书证明中"0+m=m+0=m"的第一步。 -/
theorem add'_zero_left (n : ℕ) : add' 0 n = n := by
  induction n with
  | zero => rfl
  | succ n ih => rw [add'_succ, ih]

/-- 内层引理：递归变量换侧的账——add' (m+1) n = (add' m n)+1。
这正是书 3.2.7(1) 证明里对 m 的里层归纳。 -/
theorem add'_succ_left (m n : ℕ) : add' (m + 1) n = (add' m n) + 1 := by
  induction n with
  | zero => rfl
  | succ n ih => rw [add'_succ, add'_succ, ih]

/-- 加法交换律：外层对 m 归纳，结构与书 3.2.7 的示例证明一致。 -/
theorem add'_comm (m n : ℕ) : add' m n = add' n m := by
  induction m with
  | zero => rw [add'_zero, add'_zero_left]
  | succ m ih => rw [add'_succ_left, add'_succ, ih]

/-- m · 1 = m：乘法定义与左单位引理的合成。 -/
theorem mul'_one (m : ℕ) : mul' m 1 = m := by
  rw [mul'_succ, mul'_zero, add'_zero_left]

/-! ## 归纳原理的两副面孔 -/

/-- 第二归纳原理（书 3.1.9）：∀k<n φ(k) → φ(n) 蕴涵 ∀n φ(n)。
mathlib 的 Nat.strongRecOn 就是它。 -/
example (p : ℕ → Prop) (h : ∀ n, (∀ k, k < n → p k) → p n) : ∀ n, p n :=
  fun n => Nat.strongRecOn n h

/- 良序原理（书 3.1.10）的可计算化身：Nat.find 返回满足
可判定谓词的最小自然数——"每个非空子集有最小元"的算法形态。 -/
#check @Nat.find

example : Nat.find (p := fun n => 6 ≤ n) ⟨6, le_refl 6⟩ ≤ 6 :=
  Nat.find_min' _ (le_refl 6)

/- 归纳原理的原语：Nat.rec 的类型就是书 (3.5) 的依赖形态。 -/
#check @Nat.rec
