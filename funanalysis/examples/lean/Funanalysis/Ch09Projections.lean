import Mathlib.Analysis.InnerProductSpace.Adjoint
import Mathlib.Analysis.InnerProductSpace.Projection.Basic
import Mathlib.Algebra.Star.StarProjection

/-!
# 第 09 章 · 投影、幂等与不变子空间（Conway II.3）

对应 `docs/09-projections.md`。本章在机器中复现 §II.3 主线：

1. **幂等**（Conway 3.1-3.2）：E² = E；I - E 幂等；ran E = ker(I-E)。
2. **投影 = 正交幂等**（Conway 3.3）：六条件等价（投影 ⟺ 正交投影
   ⟺ ‖E‖ ∈ {0,1} ⟺ 自伴 ⟺ 正规 ⟺ 二次型非负）——机器侧取主干：
   自伴幂等即 `IsStarProjection`。
3. **不变与约化子空间**（Conway 3.5-3.7）：M 不变 ⟺ P A P = A P；
   M 约化 ⟺ P A = A P ⟺ M 与 M⊥ 都不变。
-/

open scoped RealInnerProductSpace InnerProduct InnerProductSpace

/-!
## 1. 幂等算子（Conway 3.1-3.2）

E² = E。I - E 也是幂等；ran E = ker(I-E)，ker E = ran(I-E)。
-/

section Idempotent

variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H] [CompleteSpace H]

-- I - E 幂等（Conway 3.2 (a) 的计算：(I-E)² = I - 2E + E² = I - E）
example (E : H →L[ℝ] H) (hE : E.comp E = E) :
    (1 - E).comp (1 - E) = 1 - E := by
  ext x
  have hEE : E (E x) = E x := by
    have := congrArg (fun (T : H →L[ℝ] H) => T x) hE
    simpa using this
  simp only [ContinuousLinearMap.coe_comp, Function.comp_apply,
    sub_apply, one_apply_eq_self]
  rw [map_sub, hEE, sub_self]
  simp

end Idempotent

/-!
## 2. ran E = ker(I - E)（Conway 3.2 (b)）

E h = h ⟺ (I - E) h = 0——幂等的像恰是 I - E 的核。
-/

section RanKer

variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H] [CompleteSpace H]

-- ran E ⊆ ker (I - E)：幂等不动自己的像
example (E : H →L[ℝ] H) (hE : E.comp E = E) (h : H)
    (hh : h ∈ LinearMap.range (E : H →ₗ[ℝ] H)) :
    (1 - E) h = 0 := by
  obtain ⟨g, rfl⟩ := hh
  have hEE : ∀ y, E (E y) = E y := fun y => by
    have h2 := congrArg (fun (T : H →L[ℝ] H) => T y) hE
    simpa using h2
  simp only [sub_apply, one_apply_eq_self, ContinuousLinearMap.coe_coe]
  rw [hEE, sub_self]

end RanKer

/-!
## 3. 投影 = 自伴幂等（Conway 3.3）

正交投影的代数本质：P² = P 且自伴。mathlib 的 `IsStarProjection`
在星代数层面把这两条打包；对 CLM，乘法 = 复合、star = 伴随。
机器侧分别验证两个成分。
-/

section StarProjection

variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H] [CompleteSpace H]

-- IsStarProjection 的两个字段：幂等 + 自伴（Conway 3.3 (a)↔(d)）
example (P : H →L[ℝ] H) :
    IsStarProjection P ↔ P.comp P = P ∧ IsSelfAdjoint P := by
  constructor
  · intro h; exact ⟨h.1, h.2⟩
  · intro h; exact ⟨h.1, h.2⟩

-- 幂等性：P² = P（唯一性刻画的直接推论；第 03 章的算子版回声）
example (K : Submodule ℝ H) [K.HasOrthogonalProjection] :
    (K.starProjection : H →L[ℝ] H).comp (K.starProjection : H →L[ℝ] H)
      = K.starProjection := by
  ext x
  simp only [ContinuousLinearMap.coe_comp, Function.comp_apply]
  exact K.eq_starProjection_of_mem_of_inner_eq_zero (K.starProjection_apply_mem x)
    (fun _ _ => by rw [sub_self, inner_zero_left])

-- 自伴性：⟪P u, v⟫ = ⟪u, P v⟫（Conway 3.3 (a)↔(d) 的内积形态）
example (K : Submodule ℝ H) [K.HasOrthogonalProjection] (u v : H) :
    ⟪K.starProjection u, v⟫_ℝ = ⟪u, K.starProjection v⟫_ℝ :=
  K.inner_starProjection_left_eq_right u v

end StarProjection

/-!
## 4. 不变子空间（Conway 3.5-3.7）

M ≤ H 对 A 不变：A(M) ⊆ M。刻画：P A P = A P。
约化：M 与 M⊥ 都不变 ⟺ P A = A P ⟺ A 与 P 交换。
-/

section Invariant

variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H] [CompleteSpace H]
  {K : Submodule ℝ H} [K.HasOrthogonalProjection]

-- 不变子空间的谓词形态：A 把 M 送进 M
example (A : H →L[ℝ] H) (hinv : ∀ x ∈ K, A x ∈ K) :
    ∀ x ∈ K, (K.starProjection : H →L[ℝ] H) (A x)
      = A x := by
  intro x hx
  exact K.eq_starProjection_of_mem_of_inner_eq_zero (hinv x hx)
    (fun _ _ => by rw [sub_self, inner_zero_left])

-- 方向一：M 不变 ⟹ P∘A∘P = A∘P（Conway 3.7 (a)⟹(b) 的核心计算）
example (A : H →L[ℝ] H) (hinv : ∀ x ∈ K, A x ∈ K) :
    (K.starProjection : H →L[ℝ] H).comp
        (A.comp (K.starProjection : H →L[ℝ] H))
      = A.comp (K.starProjection : H →L[ℝ] H) := by
  ext x
  simp only [ContinuousLinearMap.coe_comp, Function.comp_apply]
  rw [K.eq_starProjection_of_mem_of_inner_eq_zero
    (hinv _ (K.starProjection_apply_mem x))
    (fun _ _ => by rw [sub_self, inner_zero_left])]

end Invariant

/-!
## 5. 约化子空间（Conway 3.7 (d)-(g)）

M 约化 A ⟺ A 与投影 P 交换。机器侧验证交换方向的直接计算，
完整六条件等价的证明见 docs 正文。
-/

section Reducing

variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℝ H] [CompleteSpace H]
  {K : Submodule ℝ H} [K.HasOrthogonalProjection]

-- P_K + P_{K⊥} = I（第 03 章 Conway 2.9 的算子形态）
example : ContinuousLinearMap.id ℝ H =
    (K.starProjection : H →L[ℝ] H) + (Kᗮ.starProjection : H →L[ℝ] H) :=
  K.id_eq_sum_starProjection_self_orthogonalComplement

/-- A 与 P 交换 ⟹ K⊥ 也不变（Conway 3.7 (e)⟹(g) 方向）。 -/
example (A : H →L[ℝ] H)
    (hcomm : A.comp (K.starProjection : H →L[ℝ] H) =
      (K.starProjection : H →L[ℝ] H).comp A) :
    ∀ x ∈ Kᗮ, A x ∈ Kᗮ := by
  -- x ∈ K⊥ ⟹ P x = 0（零向量是 x 在 K 上的正交投影）
  have hPx : ∀ x ∈ Kᗮ, K.starProjection x = 0 := by
    intro x hx
    exact K.eq_starProjection_of_mem_of_inner_eq_zero (K.zero_mem (R := ℝ))
      (fun w hw => by
        have h0 := hx w hw
        rw [sub_zero]
        exact real_inner_comm w x ▸ h0)
  intro x hx
  -- 关键计算：(I - P)(A x) = A((I - P) x) = A x
  have key : (Kᗮ.starProjection : H →L[ℝ] H) (A x) = A x := by
    have hsum : ContinuousLinearMap.id ℝ H =
        (K.starProjection : H →L[ℝ] H) + (Kᗮ.starProjection : H →L[ℝ] H) :=
      K.id_eq_sum_starProjection_self_orthogonalComplement
    have hperp : (Kᗮ.starProjection : H →L[ℝ] H)
        = ContinuousLinearMap.id ℝ H - (K.starProjection : H →L[ℝ] H) := by
      rw [eq_sub_iff_add_eq']
      exact hsum.symm
    rw [hperp]
    have hPA : K.starProjection (A x) = A (K.starProjection x) :=
      congrArg (fun (T : H →L[ℝ] H) => T x) hcomm.symm
    simp only [sub_apply, ContinuousLinearMap.id_apply, hPA, hPx x hx, map_zero,
      sub_zero]
  have hmem : (Kᗮ.starProjection : H →L[ℝ] H) (A x) ∈ Kᗮ :=
    Kᗮ.starProjection_apply_mem (A x)
  rw [key] at hmem
  exact hmem

end Reducing
