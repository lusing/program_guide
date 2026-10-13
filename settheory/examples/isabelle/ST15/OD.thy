theory OD
  imports "ZF-Constructible.AC_in_L" "ZF.Ordinal"
begin

text \<open>
第 15 章 相对可构造性与序数可定义。

L[A] 的层级（def_A 带谓词）、OD（序数参数可定义）、
HOD（遗传 OD，定理 38：ZFC 的内模型）。ZF-Constructible
未形式化 OD/HOD（它们是力迫篇的词汇）；本章以讲义+
绝对性验证承载。
\<close>

section \<open>序数集决定模型（引理 15.1 的语义）\<close>

text \<open>传递 ZFC 模型由其序数集族决定（AC 给出"集合→序数
编码"，坍缩绝对性回收）。技术核：良基+外延关系的坍缩
对两个模型同时可用（引理 14.3 的 Δ₁ 绝对性）。\<close>

section \<open>一个验证：序数编码的传递性（(15.2) 的基线）\<close>

lemma ordinal_codes_absorb:
  assumes "Transset(M)"
  shows "\<And>x. x \<in> M \<Longrightarrow> x \<subseteq> M"
  using assms unfolding Transset_def by blast

section \<open>HOD 的语义（定理 38 讲义）\<close>

text \<open>HOD = {x : TC({x}) \<subseteq> OD}。传递、含全序数、
Gödel 封闭（可定义运算保可定义性）；几乎通用性来自
V_\<alpha> \<inter> HOD 本身序数可定义。AC 在 HOD 中：
OD 的可定义良序（引理 15.8）限制到 V_\<alpha> \<inter> HOD。\<close>

end
