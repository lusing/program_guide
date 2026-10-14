theory Functions
  imports "ZF.EquivClass"
begin

text \<open>第 58 章：函数三性与复合（Makinson Ch3）。ZF Perm 库的
inj/surj/bij 谓词与复合保持律全套官方件。\<close>

subsection \<open>复合保持三性：官方锚点\<close>

lemma comp_inj_example:
  assumes "g \<in> inj(B,C)" "f \<in> inj(A,B)" shows "g O f \<in> inj(A,C)"
  using assms by (blast intro: comp_inj)

lemma comp_surj_example:
  assumes "g \<in> surj(B,C)" "f \<in> surj(A,B)" shows "g O f \<in> surj(A,C)"
  using assms by (blast intro: comp_surj)

lemma comp_bij_example:
  assumes "g \<in> bij(B,C)" "f \<in> bij(A,B)" shows "g O f \<in> bij(A,C)"
  using assms by (blast intro: comp_bij)

subsection \<open>恒等与逆\<close>

lemma id_bij_example: "id(A) \<in> bij(A,A)"
  by (rule id_bij)

lemma id_unit_left: "r \<subseteq> A*B \<Longrightarrow> id(B) O r = r"
  by (rule left_comp_id)

lemma id_unit_right: "r \<subseteq> A*B \<Longrightarrow> r O id(A) = r"
  by (rule right_comp_id)

text \<open>双射的逆是双射（Exercise 3.3.3 (2) 的官方化身）。\<close>

lemma bij_conv_bij: "f \<in> bij(A,B) \<Longrightarrow> converse(f) \<in> bij(B,A)"
  by (rule bij_converse_bij)

subsection \<open>具体小函数的判读\<close>

text \<open>常值函数在多点源上不单射：见证式论证。\<close>

lemma const_not_inj:
  assumes "a\<^sub>1 \<in> A" "a\<^sub>2 \<in> A" "a\<^sub>1 \<noteq> a\<^sub>2" "b \<in> B"
  shows "(\<lambda>x\<in>A. b) \<notin> inj(A,B)"
proof
  assume h: "(\<lambda>x\<in>A. b) \<in> inj(A,B)"
  have hb: "(\<lambda>x\<in>A. b) ` a\<^sub>1 = (\<lambda>x\<in>A. b) ` a\<^sub>2"
    using assms(1) assms(2) by simp
  from h hb assms(1) assms(2) have "a\<^sub>1 = a\<^sub>2" by (rule inj_apply_equality)
  with assms(3) show False by simp
qed

end
