/-!
# 第 88 章 · L 中的组合原理与弱紧基数（冯琦第二卷 §2.1.4-2.1.5）

两件与 §2.1.4 同构的事实：

1. 定理 2.12（Jensen 苏斯林树）构造的核心归纳：在「封口层」让每个
   新节点延拓指定反链的成员，则该反链在一切更高层保持极大（性质 (4)）。
2. 定理 2.14（Jensen 钻石原理）的调度引擎：一个时刻表序列猜中每个
   目标集合无穷多次——◇_ω 的显式构造。
-/

namespace Settheory.Ch88

open List

/-! ## 一、封口引擎（定理 2.12 性质 (4) 的核心归纳） -/

/-- 反链 A 在层 T 上「封口」：每个节点延拓 A 的某个成员。
被封口的反链在该层之上自动保持极大性。 -/
def sealed (A T : List (List Bool)) : Prop :=
  ∀ t ∈ T, ∃ a ∈ A, a <+: t

/-- 定理 2.12 性质 (4)：封口一旦完成便永久保持。
封口层每个节点延拓 A 的成员；此后每层节点都延拓前层节点，
前缀关系传递（IsPrefix.trans），于是 A 在所有更高层保持极大。 -/
theorem sealed_persists {A : List (List Bool)} {T : Nat → List (List Bool)}
    {k : Nat} (h0 : sealed A (T (k + 1)))
    (hstep : ∀ n ≥ k + 1, ∀ t ∈ T (n + 1), ∃ s ∈ T n, s <+: t) :
    ∀ n, k + 1 ≤ n → sealed A (T n) := by
  intro n
  induction n with
  | zero => intro h; omega
  | succ n ih =>
    intro hn
    have hnk : k + 1 ≤ n ∨ n + 1 = k + 1 := by omega
    rcases hnk with hle | heq
    · have base := ih hle
      intro t ht
      obtain ⟨s, hs, hsp⟩ := hstep n hle t ht
      obtain ⟨a, ha, hap⟩ := base s hs
      exact ⟨a, ha, hap.trans hsp⟩
    · have hnk : n = k := by omega
      subst hnk
      exact h0

/-! ## 二、钻石时刻表（定理 2.14 的 ω-影子） -/

/-- 2-进赋值：n = 2^{v₂ n}·(奇数)。 -/
def vtwo : Nat → Nat
  | 0 => 0
  | n + 1 => if (n + 1) % 2 = 0 then vtwo ((n + 1) / 2) + 1 else 0

theorem vtwo_double_pos (x : Nat) (hx : 1 ≤ x) : vtwo (2 * x) = vtwo x + 1 := by
  cases x with
  | zero => omega
  | succ y =>
  have h0 : 2 * (y + 1) = 2 * y + 2 := by omega
  have h1 : (2 * y + 2) % 2 = 0 := by omega
  have h2 : (2 * y + 2) / 2 = y + 1 := by omega
  rw [h0]
  simp [vtwo, h1, h2]

theorem vtwo_pow_mul_odd (i m : Nat) :
    vtwo (2 ^ i * (2 * m + 1)) = i := by
  induction i generalizing m with
  | zero =>
    have hod : (2 * m + 1) % 2 = 1 := by omega
    have hmul : (2:Nat) ^ 0 * (2 * m + 1) = 2 * m + 1 := by simp
    simp [hmul, vtwo, hod]
  | succ i ih =>
    have hsplit : (2:Nat) ^ (i + 1) * (2 * m + 1) = 2 * (2 ^ i * (2 * m + 1)) := by
      rw [Nat.pow_succ, Nat.mul_assoc, Nat.mul_left_comm]
    have hpos : 1 ≤ 2 ^ i * (2 * m + 1) :=
      Nat.succ_le_of_lt (Nat.mul_pos (Nat.two_pow_pos i) (by omega : (0:Nat) < 2 * m + 1))
    rw [hsplit, vtwo_double_pos _ hpos, ih]

/-- 时刻表：第 n 步的猜测是第 v₂ n 个目标集合的初始段。 -/
def S (X : Nat → Nat → Bool) (n j : Nat) : Bool :=
    decide (j < n) && X (vtwo n) j

/-- ◇_ω 的调度定理：对每个目标集合 X_i 与每个界 K，存在时刻 n > K
使猜测恰好命中（S 的第 n 行 = X_i ∩ n 的特征函数）。
时刻表的每个 2^i·(奇数) 时刻都留给 X_i——「猜中无穷多次」的显式安排。 -/
theorem diamond_hit (X : Nat → Nat → Bool) (i K : Nat) :
    ∃ n, K < n ∧ vtwo n = i ∧ ∀ j < n, S X n j = X i j := by
  have hv3 : vtwo (2 ^ i * (2 * K + 3)) = i := by
    have hprev := vtwo_pow_mul_odd i (K + 1)
    have hnum : 2 * (K + 1) + 1 = 2 * K + 3 := by omega
    rwa [hnum] at hprev
  refine ⟨2 ^ i * (2 * K + 3), ?_, hv3, ?_⟩
  · have h1 : (1:Nat) ≤ 2 ^ i := Nat.succ_le_of_lt (Nat.two_pow_pos i)
    exact Nat.lt_of_lt_of_le (show K < 2 * K + 3 by omega)
      (show 2 * K + 3 ≤ 2 ^ i * (2 * K + 3) by
        have hm := Nat.mul_le_mul_right (2 * K + 3) h1
        rwa [Nat.one_mul] at hm)
  · intro j hj
    simp [S, hv3, hj]

end Settheory.Ch88
