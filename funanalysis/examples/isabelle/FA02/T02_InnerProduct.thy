theory T02_InnerProduct
  imports "HOL-Analysis.Inner_Product"
begin

text \<open>
  第 02 章（Isabelle 通道）：内积空间初步，Conway I.1。
  与 Lean 通道 Ch02InnerProduct.lean 平行：极化恒等式、
  CBS 不等式的判别式证明、三角不等式，全部用 Isar 手工写。
\<close>

section \<open>极化恒等式（Conway I.1.5 前的注记）\<close>

lemma fa_polar:
  fixes x y :: "'a::real_inner"
  shows "(norm (x + y))\<^sup>2 = (norm x)\<^sup>2 + 2 * inner x y + (norm y)\<^sup>2"
proof -
  have "(norm (x + y))\<^sup>2 = inner (x + y) (x + y)"
    by (simp add: power2_norm_eq_inner)
  also have "\<dots> = inner x x + inner x y + inner y x + inner y y"
    by (simp add: inner_add_left inner_add_right)
  also have "\<dots> = (norm x)\<^sup>2 + 2 * inner x y + (norm y)\<^sup>2"
    by (simp add: power2_norm_eq_inner inner_commute)
  finally show ?thesis .
qed

section \<open>CBS 不等式：Conway I.4 的判别式路线\<close>

text \<open>
  对每个实数 t，q(t) = (norm x)^2 - 2*t*inner x y + t^2*(norm y)^2
  是 inner (x - t*y) (x - t*y) 的展开（非负）；
  在顶点 t0 = inner x y / (norm y)^2 处取值非负即得结论。
\<close>

lemma fa_cbs:
  fixes x y :: "'a::real_inner"
  shows "(inner x y)\<^sup>2 \<le> (norm x)\<^sup>2 * (norm y)\<^sup>2"
proof (cases "y = 0")
  case True
  then show ?thesis by simp
next
  case False
  define q where "q = (\<lambda>t::real. inner x x - 2 * t * inner x y + t * t * inner y y)"
  have qpos: "0 \<le> q t" for t
  proof -
    have "0 \<le> inner (x - t *\<^sub>R y) (x - t *\<^sub>R y)"
      using inner_ge_zero by blast
    moreover have "inner (x - t *\<^sub>R y) (x - t *\<^sub>R y) = q t"
      unfolding q_def
      by (simp add: inner_diff_left inner_diff_right inner_scaleR_left
          inner_scaleR_right inner_commute algebra_simps)
    ultimately show "0 \<le> q t" by simp
  qed
  have nn: "inner y y > 0"
    using False by simp
  define t0 where "t0 = inner x y / inner y y"
  have ct0: "inner y y * t0 = inner x y"
    unfolding t0_def using nn by (simp add: field_simps False)
  have key: "(inner x y)\<^sup>2 \<le> inner x x * inner y y"
  proof -
    have h0: "0 \<le> q t0" by (simp add: qpos)
    have "q t0 * inner y y = (inner x x - 2 * t0 * inner x y + t0 * t0 * inner y y)
        * inner y y"
      unfolding q_def by (rule refl)
    also have "\<dots> = inner x x * inner y y
        - 2 * (inner y y * t0) * inner x y
        + (inner y y * t0) * (inner y y * t0)"
      by (simp add: algebra_simps power2_eq_square)
    also have "\<dots> = inner x x * inner y y - (inner x y)\<^sup>2"
      using ct0 by (simp add: algebra_simps power2_eq_square)
    finally have hq: "q t0 * inner y y = inner x x * inner y y - (inner x y)\<^sup>2" .
    have hp: "0 \<le> q t0 * inner y y"
      by (rule mult_nonneg_nonneg[OF h0 nn[THEN less_imp_le]])
    with hq have "0 \<le> inner x x * inner y y - (inner x y)\<^sup>2"
      by simp
    then show ?thesis by simp
  qed
  then show ?thesis
    by (simp add: power2_norm_eq_inner)
qed

section \<open>三角不等式（Conway I.1.5 (a)）\<close>

lemma fa_triangle:
  fixes x y :: "'a::real_inner"
  shows "norm (x + y) \<le> norm x + norm y"
proof -
  have hle: "inner x y \<le> norm x * norm y"
    using norm_cauchy_schwarz by blast
  have "(norm (x + y))\<^sup>2 = (norm x)\<^sup>2 + 2 * inner x y + (norm y)\<^sup>2"
    by (rule fa_polar)
  also have "\<dots> \<le> ((norm x) + (norm y))\<^sup>2"
    by (simp add: power2_sum algebra_simps hle)
  finally have h2: "(norm (x + y))\<^sup>2 \<le> ((norm x) + (norm y))\<^sup>2" .
  then show ?thesis
    by (blast intro: power2_le_imp_le add_nonneg_nonneg norm_ge_zero)
qed

end
