import Mathlib

/-!
# Ch24 Sobolev 空间 I：离散分部积分（弱导数的代数核）

对应书 §5.2（弱导数：分部积分定义）。u 的弱导数 v 满足
∫uφ′ = −∫vφ 对一切试验函数 φ。在**等距格点**上这是纯代数恒等式：

    Σᵢ uᵢ(φᵢ₊₁ − φᵢ₋₁)/(2h) = −Σᵢ ((uᵢ₊₁ − uᵢ₋₁)/(2h))φᵢ + 边界项

本文件对区间 {0,…,N−1} 证明**平移求和恒等式**（无边界项的周期版
与带边界修正版），即弱导数定义的有限差分原型：求和号与差分算子
的"交换 = 反号 + 边界"。
-/

open Finset

namespace Evanspde.Ch24

variable {α : Type*} [CommRing α]

/-- **中心差分的反对称性**：Σ (uᵢ₊₁ − uᵢ₋₁) = u_N − u_{N−1} + u_0 − ... 的
 telescoping。更关键的恒等式：对任意两条序列，
    Σ_{i< N} uᵢ(v_{i+1} − vᵢ) = u_N v_N − u_0 v_0 − Σ_{i<N} vᵢ₊₁(uᵢ₊₁ − uᵢ)
 ——分部积分的代数本体。 -/
theorem discrete_integration_by_parts (u v : ℕ → α) (N : ℕ) :
    ∑ i ∈ range N, u i * (v (i + 1) - v i)
      = u N * v N - u 0 * v 0
        - ∑ i ∈ range N, v (i + 1) * (u (i + 1) - u i) := by
  have key : ∀ i : ℕ,
      u i * (v (i + 1) - v i) + v (i + 1) * (u (i + 1) - u i)
        = u (i + 1) * v (i + 1) - u i * v i := by
    intro i
    ring
  -- 望远镜求和：Σ (u_{i+1}v_{i+1} − u_i v_i) = u_N v_N − u_0 v_0
  have htele : ∑ i ∈ range N, (u (i + 1) * v (i + 1) - u i * v i)
      = u N * v N - u 0 * v 0 := by
    induction N with
    | zero => simp
    | succ n ih =>
      rw [sum_range_succ, ih]
      ring
  rw [← htele, ← sum_sub_distrib]
  exact sum_congr rfl (fun i _ => by linear_combination (key i))

end Evanspde.Ch24


