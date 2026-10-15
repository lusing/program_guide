theory Quant
  imports "ZF.EquivClass"
begin

text \<open>第 64 章：量词逻辑（Makinson Ch9）。量词互换的集合级骨架。
  De Morgan 对广义并的推广。\<close>

lemma quant_interchange_union:
  "T - (\<Union>x\<in>A. f(x)) = {y\<in>T . \<forall>x\<in>A. y \<notin> f(x)}"
  by blast

text \<open>量词分配：全称对合取的分配。\<close>

lemma quant_dist_conj:
  "(\<Union>x\<in>A. f(x) \<inter> g(x)) \<subseteq> (\<Union>x\<in>A. f(x)) \<inter> (\<Union>x\<in>A. g(x))"
  by blast

end
