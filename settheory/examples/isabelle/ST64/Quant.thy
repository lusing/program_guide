theory Quant
  imports "ZF.EquivClass"
begin

text \<open>第 64 章：量词逻辑（Makinson Ch9）。量词互换等式的骨架。\<close>

text \<open>量词互换：$\<^bold>\<not>\<forall>x(a) \<^equiv> \<^exists>x(\<^bold>\<not>a)$ 的集合级类比
  ——De Morgan 对广义并/交的推广（书 9.2.1）。\<close>

lemma quant_interchange_set:
  "T - (\<Union>x\<in>A. f(x)) = (\<Inter>x\<in>A. T - f(x))"
  by blast

lemma quant_interchange_set2:
  "T - (\<Inter>x\<in>A. f(x)) = (\<Union>x\<in>A. T - f(x))"
  by blast

end
