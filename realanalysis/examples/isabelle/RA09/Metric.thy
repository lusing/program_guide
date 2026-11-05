theory Metric
  imports "HOL-Analysis.Analysis"
begin

(* 第 09 章 拓扑定义：Isabelle 通道。
   实直线上的距离、开球、有界、开闭区间、有理数稠密。
   源码约定：数学符号用 Isabelle 实体写法。 *)

lemma dist_abs: "dist (x::real) y = \<bar>x - y\<bar>"
  by (simp add: dist_real_def)

lemma dist_zero: "dist (x::real) x = 0"
  by simp

lemma dist_sym: "dist (x::real) y = dist y x"
  by (simp add: dist_commute)

lemma dist_tri: "dist (x::real) z \<le> dist x y + dist y z"
  by (simp add: dist_triangle)

(* 例 9.8：半径 3、中心 0 的邻域是 (-3,3)。 *)
lemma ball_03: "ball (0::real) 3 = {-3<..<3}"
  by (simp add: ball_eq_greaterThanLessThan)

lemma endpoint_not_in_ball: "(3::real) \<notin> ball 0 3"
  by simp

(* 定理 9.23：邻域是开集。 *)
lemma ball_open: "open (ball (p::real) r)"
  by simp

lemma open_interval: "open {(-3::real)<..<3}"
  by simp

lemma closed_interval: "closed {(-3::real)..3}"
  by simp

lemma empty_open_closed: "open ({} :: real set)" "closed ({} :: real set)"
  by simp_all

(* 例 9.4：[-3,3] 有界；(−∞,3] 无界。 *)
lemma bounded_interval: "bounded {(-3::real)..3}"
  by simp

lemma unbounded_ray: "\<not> bounded {..(3::real)}"
proof
  assume b: "bounded {..(3::real)}"
  have "\<exists>a. \<forall>x\<in>{..(3::real)}. norm x \<le> a"
    using b bounded_iff by blast
  then obtain a where a: "\<forall>x\<in>{..(3::real)}. norm x \<le> a" by blast
  have "norm (- (\<bar>a\<bar> + 1)) \<le> a"
  proof -
    have "- (\<bar>a\<bar> + 1) \<in> {..(3::real)}" by simp
    with a show ?thesis by blast
  qed
  then have "\<bar>a\<bar> + 1 \<le> a" by simp
  moreover have "a \<le> \<bar>a\<bar>" by simp
  ultimately show False by simp
qed

(* 有限集是闭集。 *)
lemma finite_closed: "closed {0::real, 1}"
  by simp

(* 3 是 (-3,3) 的极限点，故开区间不闭。 *)
lemma three_in_closure: "(3::real) \<in> closure {-3<..<3}"
  by (simp add: closure_greaterThanLessThan)

lemma open_interval_not_closed: "\<not> closed {(-3::real)<..<3}"
proof
  assume cl: "closed {(-3::real)<..<3}"
  from cl have "closure {(-3::real)<..<3} \<subseteq> {(-3::real)<..<3}"
    by (metis closure_subset_eq)
  with three_in_closure have "(3::real) \<in> {(-3::real)<..<3}" by blast
  then show False by simp
qed

(* 定理 9.18：任意开区间里都有有理数。 *)
lemma rats_between:
  fixes x y :: real
  assumes "x < y"
  shows "\<exists>q\<in>\<rat>. x < q \<and> q < y"
  using Rats_dense_in_real assms by blast

end
