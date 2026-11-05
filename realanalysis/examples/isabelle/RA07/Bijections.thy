theory Bijections
  imports "HOL-Analysis.Analysis"
begin

(* 第 07 章 双射：Isabelle 通道。
   函数、像/原像、inj/surj/bij、双射⇔可逆、复合。
   源码约定：数学符号一律用 Isabelle 实体写法。 *)

(* ---------------- 7.1 像与原像 ---------------- *)

lemma const_image:
  "(\<lambda>_::nat. (1::nat)) ` {1, 2, 3} = {1}"
  by auto

lemma sq_preimage_16:
  "(\<lambda>x::int. x^2) -` {16} = {4, -4}"
proof
  show "(\<lambda>x::int. x^2) -` {16} \<subseteq> {4, -4}"
  proof
    fix x :: int
    assume "x \<in> (\<lambda>x::int. x^2) -` {16}"
    hence "x^2 = 16" by simp
    hence "x^2 = 4^2" by simp
    hence "x = 4 \<or> x = -4"
      using power2_eq_iff[of x 4] by auto
    thus "x \<in> {4, -4}" by auto
  qed
next
  show "{4, -4} \<subseteq> (\<lambda>x::int. x^2) -` {16}"
    by auto
qed

(* ---------------- 7.2 单射 / 满射 / 双射 ---------------- *)

lemma mul2_inj: "inj (\<lambda>x::real. 2 * x)"
  by (simp add: inj_def)

lemma sq_not_inj: "\<not> inj (\<lambda>x::real. x^2)"
proof
  assume h: "inj (\<lambda>x::real. x^2)"
  have "(2::real)^2 = (-2)^2" by simp
  from h this have "(2::real) = -2" by (rule injD)
  thus False by simp
qed

(* bool → unit 常值：满射非单射（原书 {1,2}→{1}）。 *)
lemma const_surj_not_inj:
  "surj (\<lambda>_::bool. ()) \<and> \<not> inj (\<lambda>_::bool. ())"
proof
  show "surj (\<lambda>_::bool. ())"
    by (simp add: surj_def)
  show "\<not> inj (\<lambda>_::bool. ())"
  proof
    assume "inj (\<lambda>_::bool. ())"
    hence "True = False" by (simp add: inj_def)
    thus False by simp
  qed
qed

(* unit → bool，* ↦ False：单射非满射（原书 {1}→{1,2}）。 *)
lemma inj_not_surj_unit:
  "inj (\<lambda>_::unit. False) \<and> \<not> surj (\<lambda>_::unit. False)"
proof
  show "inj (\<lambda>_::unit. False)"
    by (simp add: inj_def)
  show "\<not> surj (\<lambda>_::unit. False)"
  proof
    assume "surj (\<lambda>_::unit. False)"
    then obtain u :: unit where "True = False"
      unfolding surj_def by auto
    thus False by simp
  qed
qed

lemma mul2_bij: "bij (\<lambda>x::real. 2 * x)"
  unfolding bij_def inj_def surj_def
  by (auto intro: exI[of _ "y/2" for y])

lemma mul2_inv: "inv (\<lambda>x::real. 2 * x) = (\<lambda>y::real. y / 2)"
  by (rule inv_equality) auto

(* ---------------- 7.3 双射 ⇔ 可逆；复合 ---------------- *)

lemma mul2_left_right_inv:
  "(\<forall>x::real. (2*x)/2 = x) \<and> (\<forall>y::real. 2*(y/2) = y)"
  by simp

lemma bij_imp_inv:
  assumes "bij (f :: 'a \<Rightarrow> 'b)"
  shows "(\<forall>x. inv f (f x) = x) \<and> (\<forall>y. f (inv f y) = y)"
  using assms by (simp add: bij_is_inj bij_is_surj inv_f_f surj_f_inv_f)

lemma comp_example:
  "(\<lambda>x::real. x^2) \<circ> (\<lambda>x::real. 2 * x) = (\<lambda>x::real. 4 * x^2)"
  by (simp add: fun_eq_iff)

lemma bij_comp_closed:
  assumes "bij (f :: 'a \<Rightarrow> 'b)" "bij (g :: 'b \<Rightarrow> 'c)"
  shows "bij (g \<circ> f)"
  using assms by (rule bij_comp)

lemma mul2_inv_id:
  "(\<lambda>y::real. y/2) \<circ> (\<lambda>x::real. 2*x) = id"
  "(\<lambda>x::real. 2*x) \<circ> (\<lambda>y::real. y/2) = id"
  by (simp_all add: fun_eq_iff)

end
