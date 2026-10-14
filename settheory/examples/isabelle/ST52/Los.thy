theory Los
  imports "ZF-Constructible.AC_in_L"
begin

text \<open>第 52 章 Łoś 定理的谓词式骨架：满性定义 + 主超滤商的
       原子情形（正向 blast 纪律）。\<close>

definition
  full_on :: "[i, i] \<Rightarrow> o" where
  "full_on(A0, Val) \<equiv> Val \<subseteq> Pow(A0) \<and>
     (\<forall>S \<in> Pow(Val). S \<noteq> 0 \<longrightarrow>
        (\<exists>x \<in> S. \<forall>y \<in> S. y \<subseteq> x \<or> x = y))"

text \<open>本骨架把"满性"读作：任何非空值族有最大元（有限 sup 达到）。
       这是 Prop 6.3.14 的有限化身；真正的无穷满性需要混合性质。\<close>

text \<open>主超滤商的原子情形：真值 ∈ G_a ⟺ a ∈ 真值。\<close>

lemma principal_atom_los:
  assumes "a \<in> A0" and "V \<in> Pow(A0)"
  shows "(a \<in> V) \<longleftrightarrow> (V \<in> {W \<in> Pow(A0) . a \<in> W})"
proof
  assume "a \<in> V"
  with assms(2) show "V \<in> {W \<in> Pow(A0) . a \<in> W}"
    unfolding Collect_def by blast
next
  assume "V \<in> {W \<in> Pow(A0) . a \<in> W}"
  then have "V \<in> Pow(A0)" and "a \<in> V"
    unfolding Collect_def by blast+
  thus "a \<in> V" by simp
qed

end
