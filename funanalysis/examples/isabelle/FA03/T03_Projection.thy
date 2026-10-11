theory T03_Projection
  imports "HOL-Analysis.Cartesian_Euclidean_Space"
begin

text \<open>
  第 03 章（Isabelle 通道）：正交性与投影，Conway I.2。
  勾股定理、平行四边形恒等式手工 Isar；然后把"投影到直线"
  在 real^2（二维欧氏空间）上算到底——这是 Lean 通道（抽象形式）与数值通道
  （浮点形式）之外的第三种视角：具体向量、精确推理。
\<close>

section \<open>极化恒等式（两式，本章自足）\<close>

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

lemma fa_polar_sub:
  fixes x y :: "'a::real_inner"
  shows "(norm (x - y))\<^sup>2 = (norm x)\<^sup>2 - 2 * inner x y + (norm y)\<^sup>2"
proof -
  have "(norm (x - y))\<^sup>2 = inner (x - y) (x - y)"
    by (simp add: power2_norm_eq_inner)
  also have "\<dots> = inner x x - inner x y - inner y x + inner y y"
    by (simp add: inner_diff_left inner_diff_right)
  also have "\<dots> = (norm x)\<^sup>2 - 2 * inner x y + (norm y)\<^sup>2"
    by (simp add: power2_norm_eq_inner inner_commute algebra_simps)
  finally show ?thesis .
qed

section \<open>勾股定理（Conway I.2.2）与平行四边形（Conway I.2.3）\<close>

lemma fa_pythagoras:
  fixes x y :: "'a::real_inner"
  assumes "orthogonal x y"
  shows "(norm (x + y))\<^sup>2 = (norm x)\<^sup>2 + (norm y)\<^sup>2"
proof -
  have "(norm (x + y))\<^sup>2 = (norm x)\<^sup>2 + 2 * inner x y + (norm y)\<^sup>2"
    by (rule fa_polar)
  also have "\<dots> = (norm x)\<^sup>2 + (norm y)\<^sup>2"
    using assms by (simp add: orthogonal_def)
  finally show ?thesis .
qed

lemma fa_parallelogram:
  fixes x y :: "'a::real_inner"
  shows "(norm (x + y))\<^sup>2 + (norm (x - y))\<^sup>2 = 2 * ((norm x)\<^sup>2 + (norm y)\<^sup>2)"
  by (simp add: fa_polar fa_polar_sub)

section \<open>直线投影：正交性与唯一性\<close>

text \<open>v 在直线 span{w} 上的正交投影系数是 inner v w / inner w w。\<close>

lemma proj_line_orthogonal:
  fixes v w :: "real^2"
  assumes "w \<noteq> 0"
  shows "orthogonal (v - (inner v w / inner w w) *\<^sub>R w) w"
proof -
  have nnz: "inner w w \<noteq> 0"
    using assms by (simp add: inner_eq_zero_iff)
  have "inner (v - (inner v w / inner w w) *\<^sub>R w) w
      = inner v w - (inner v w / inner w w) * (inner w w)"
    by (simp add: inner_diff_left inner_scaleR_left)
  also have "\<dots> = 0"
    by (simp add: nnz field_simps)
  finally show ?thesis
    by (simp add: orthogonal_def)
qed

text \<open>
  唯一性：非零的、满足正交性的 t 必须是那个系数（Conway I.2.6 的刻画）。
  注意 t = 0 平凡满足 orthogonal 0 v——所以唯一性陈述必须排除 t = 0。
  （机器在验证最初不加排除的版本时直接给出了反例方向：任何与 w 不正交
  的 v 取 t = 0 都满足正交假设却不满足结论。这正是 Conway 2.5 的唯一性
  要走平行四边形路线、而非仅靠正交性的原因。）
\<close>

lemma proj_line_unique:
  fixes v w :: "real^2"
  assumes "w \<noteq> 0" and "t \<noteq> 0" and "orthogonal (t *\<^sub>R w) (v - t *\<^sub>R w)"
  shows "t *\<^sub>R w = (inner v w / inner w w) *\<^sub>R w"
proof -
  have h: "inner (t *\<^sub>R w) (v - t *\<^sub>R w) = 0"
    using assms by (simp add: orthogonal_def)
  have expand: "inner (t *\<^sub>R w) (v - t *\<^sub>R w)
      = t * (inner w v) - t * t * (inner w w)"
    by (simp add: inner_diff_right inner_scaleR_left inner_scaleR_right
        power2_eq_square algebra_simps)
  have nnz: "inner w w \<noteq> 0"
    using assms by (simp add: inner_eq_zero_iff)
  have teq: "t * (inner w v - t * (inner w w)) = 0"
  proof -
    have eq1: "t * (inner w v - t * (inner w w))
        = inner (t *\<^sub>R w) (v - t *\<^sub>R w)"
      by (simp add: inner_diff_right inner_scaleR_left inner_scaleR_right
          algebra_simps)
    also have "\<dots> = 0" by (rule h)
    finally show ?thesis .
  qed
  have hsplit: "t = 0 \<or> inner w v - t * (inner w w) = 0"
    using teq by (simp only: mult_eq_0_iff)
  then have eq: "inner w v = t * (inner w w)"
  proof (rule disjE)
    assume t0: "t = 0"
    from assms(2) t0 have False by simp
    then show ?thesis by simp
  next
    assume h0: "inner w v - t * (inner w w) = 0"
    then show ?thesis by simp
  qed
  then have "t = inner v w / inner w w"
    by (simp add: field_simps inner_commute nnz assms(1))
  then show ?thesis by simp
qed

text \<open>勾股分解：v = 投影 + 正交误差，范数平方恰为两段之和。\<close>

lemma proj_line_pythagoras:
  fixes v w :: "real^2"
  assumes "w \<noteq> 0"
  defines "p \<equiv> (inner v w / inner w w) *\<^sub>R w"
  shows "(norm v)\<^sup>2 = (norm p)\<^sup>2 + (norm (v - p))\<^sup>2"
proof -
  have orthvw: "inner (v - p) w = 0"
  proof -
    have ho: "orthogonal (v - (inner v w / inner w w) *\<^sub>R w) w"
      using assms(1) by (rule proj_line_orthogonal)
    then show ?thesis
      unfolding p_def by (simp add: orthogonal_def)
  qed
  have "inner p (v - p) = 0"
  proof -
    have hz: "inner w (v - p) = 0"
      using orthvw by (simp add: inner_commute)
    have "inner p (v - p) = (inner v w / inner w w) * (inner w (v - p))"
      by (simp add: p_def inner_scaleR_left)
    also have "\<dots> = (inner v w / inner w w) * 0"
      by (simp only: hz)
    also have "\<dots> = 0"
      by (rule mult_zero_right)
    finally show ?thesis .
  qed
  then have horth2: "orthogonal p (v - p)"
    by (simp add: orthogonal_def)
  have hv: "v = p + (v - p)" by simp
  have "(norm v)\<^sup>2 = (norm (p + (v - p)))\<^sup>2"
    using hv by simp
  also have "\<dots> = (norm p)\<^sup>2 + (norm (v - p))\<^sup>2"
    by (rule fa_pythagoras[OF horth2])
  finally show ?thesis .
qed

end
