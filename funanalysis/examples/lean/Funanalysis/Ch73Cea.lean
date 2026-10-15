import Mathlib.Analysis.InnerProductSpace.LaxMilgram

/-!
# 第 73 章 · 弱解与 Galerkin 误差（工科篇 6.4 + Céa 引理）

书 6.4 的狄氏边值问题弱解存在唯一性走 Riesz 路线：Poincaré 把
∫∇u·∇v 造就成 H₀¹ 的内积，Hölder 把 l(v) = ∫fv 造就成连续泛函，
Riesz 表示定理收尾（全证明在文档正文）。

本章 Lean 通道机器化其**数值分析续篇**——Céa 引理：Galerkin 投影的
误差被最优逼近误差控制（常数 = 连续性/强制性）。这是有限元的
收敛性基石，证明是三条不等式的焊接：

```
b‖e‖²  ≤  B e e           （强制性）
B e e  =  B e (u − v)      （Galerkin 正交性：e 的 vₕ-分量消失）
|B e (u − v)| ≤ c‖e‖‖u − v‖（连续性）
```

三式相除即得。mathlib 的 LaxMilgram.lean 提供强制性的全部原料。
-/

open InnerProductSpace
open scoped RealInnerProductSpace InnerProductSpace

variable {V : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V]

/-- **Céa 引理**：B 强制（常数 b > 0）且连续（常数 c），u 是变分问题
的解，uₕ ∈ Vₕ 是 Galerkin 投影（正交性：对 Vₕ 中一切 w 有
B w (u − uₕ) = 0），则对一切 v ∈ Vₕ：

    ‖u − uₕ‖ ≤ (c / b) · ‖u − v‖

——Galerkin 解在 Vₕ 中是**拟最优**（quasi-optimal）的。 -/
theorem cea_lemma (B : V →L[ℝ] V →L[ℝ] ℝ)
    (b : ℝ) (hb : 0 < b) (hcoe : ∀ v, b * ‖v‖ * ‖v‖ ≤ B v v)
    (c : ℝ) (hc : 0 ≤ c) (hcont : ∀ x y, |B x y| ≤ c * ‖x‖ * ‖y‖)
    (Vh : Submodule ℝ V) {u uh : V} (huh : uh ∈ Vh)
    (horth : ∀ w ∈ Vh, B w (u - uh) = 0) {v : V} (hv : v ∈ Vh) :
    ‖u - uh‖ ≤ (c / b) * ‖u - v‖ := by
  -- 第一步：e = u − uₕ 的第一槽分解 u − uₕ = (u − v) + (v − uₕ)
  have hsplit : u - uh = (u - v) + (v - uh) := by abel
  have horth2 : B (v - uh) (u - uh) = 0 := by
    refine horth (v - uh) (Submodule.sub_mem Vh hv huh)
  -- 第二步：强制性 + 分解 + 连续性
  have hkey : b * ‖u - uh‖ * ‖u - uh‖ ≤ |B (u - v) (u - uh)| := by
    have h1 : b * ‖u - uh‖ * ‖u - uh‖ ≤ B (u - uh) (u - uh) := hcoe _
    have h2 : B (u - uh) (u - uh) = B (u - v) (u - uh) := by
      calc B (u - uh) (u - uh)
          = B ((u - v) + (v - uh)) (u - uh) := by rw [hsplit]
        _ = B (u - v) (u - uh) + B (v - uh) (u - uh) := by simp
        _ = B (u - v) (u - uh) := by rw [horth2, add_zero]
    exact h1.trans (h2 ▸ le_abs_self (B (u - v) (u - uh)))
  have h3 : |B (u - v) (u - uh)| ≤ c * ‖u - v‖ * ‖u - uh‖ := hcont _ _
  -- 第三步：相除（‖e‖ = 0 平凡；否则用乘法消去）
  rcases eq_or_ne (u - uh) 0 with he0 | hne
  · have : 0 ≤ (c / b) * ‖u - v‖ := by positivity
    rw [he0, norm_zero]
    exact this
  · have hnpos : 0 < ‖u - uh‖ := norm_pos_iff.mpr hne
    have hle : b * ‖u - uh‖ * ‖u - uh‖ ≤ c * ‖u - v‖ * ‖u - uh‖ :=
      hkey.trans h3
    have hdiv : b * ‖u - uh‖ ≤ c * ‖u - v‖ :=
      (mul_le_mul_iff_of_pos_right hnpos).mp hle
    have hbne : b ≠ 0 := ne_of_gt hb
    have hbc : b * ((c / b) * ‖u - v‖) = c * ‖u - v‖ := by
      rw [← mul_assoc, mul_div_cancel₀ _ hbne]
    have hfinal : b * ‖u - uh‖ ≤ b * ((c / b) * ‖u - v‖) := by
      rw [hbc]; exact hdiv
    exact (mul_le_mul_iff_of_pos_left hb).mp hfinal

/-- Céa 引理的 Lax-Milgram 链接：强制双线性形式的表示算子是同构，
变分问题的解 u 由 `IsCoercive.continuousLinearEquivOfBilin` 给出，
其 Galerkin 投影满足引理的正交性假设（这一例展示接口衔接）。 -/
example [CompleteSpace V] (B : V →L[ℝ] V →L[ℝ] ℝ) (hcoe : IsCoercive B) (v w : V) :
    ⟪hcoe.continuousLinearEquivOfBilin v, w⟫_ℝ = B v w :=
  hcoe.continuousLinearEquivOfBilin_apply v w
