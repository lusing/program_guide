theory T00_Overview
  imports "HOL-Analysis.Cartesian_Euclidean_Space"
begin

text \<open>
  第 00 章（Isabelle 通道）：机器已经知道哪些泛函分析。
  与 Lean 通道的 Ch00Intro.lean 呼应，我们在这里用 Isabelle 的
  \<open>real_inner\<close> 类型类（带范数的实内积空间）确认 Cauchy-Schwarz，
  并在一开始做一个完全具体的计算：real^2（二维欧氏空间）上的投影预览。
\<close>

text \<open>Cauchy-Schwarz 不等式（Conway I.4.1 的 Isabelle 形态）\<close>
thm Cauchy_Schwarz_ineq2
thm norm_cauchy_schwarz

text \<open>极化恒等式（Conway I.1.5 之前的注记）\<close>
thm power2_norm_eq_inner

text \<open>
  热身：一个具体到数字的证明。
  取 x = (3,4)、y = (1,1)，验证 CBS 不等式两边。
\<close>

lemma cbs_concrete:
  fixes x y :: "real^2"
  defines "x \<equiv> 3 *\<^sub>R axis 0 1 + 4 *\<^sub>R axis 1 1"
    and "y \<equiv> axis 0 1 + axis 1 1"
  shows "(inner x y)\<^sup>2 \<le> (norm x)\<^sup>2 * (norm y)\<^sup>2"
proof -
  have ixy: "inner x y = 7"
    unfolding x_def y_def
    by (simp add: inner_add_left inner_add_right inner_scaleR_left
        inner_scaleR_right inner_axis_axis)
  have inx: "inner x x = 25"
    unfolding x_def
    by (simp add: inner_add_left inner_add_right inner_scaleR_left
        inner_scaleR_right inner_axis_axis)
  have iny: "inner y y = 2"
    unfolding y_def
    by (simp add: inner_add_left inner_add_right inner_scaleR_left
        inner_scaleR_right inner_axis_axis)
  show ?thesis
    unfolding power2_norm_eq_inner ixy inx iny by simp
qed

end
