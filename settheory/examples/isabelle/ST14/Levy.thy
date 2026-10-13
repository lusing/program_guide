theory Levy
  imports "ZF-Constructible.AC_in_L" "ZF.Ordinal"
begin

text \<open>
第 14 章 Lévy 层级：Σₙ/Πₙ 的语义框架。

公式按量词交替分层：Σ₀=Π₀=Δ₀（受限）；Σ_{n+1}=∃...Πₙ。
引理 14.2 的九条封闭规则与引理 14.4 的非 Σ₁ 结果
（基数概念是 Π₁）是第 15 章（OD/HOD）与第 30 章（0#）
的语法底座。Isabelle/ZF 未形式化 Lévy 层级——本章以
Formula 的 satisfies 语义为锚，层级判定器由计算通道承载。
\<close>

section \<open>受限公式（Σ₀）的地位\<close>

text \<open>第 10 章的 sats 语义给出 Σ₀ 的机器形态；受限公式
对传递类绝对（引理 10.1）。Lévy 层级的完整形式化
（Σₙ/Πₙ 的归纳定义与封闭规则）不在 ZF 库——由计算通道
的层级判定器承载。\<close>

section \<open>良基性的 Δ₁ 地位（引理 14.3 讲义）\<close>

text \<open>"E 良基" 同时 Σ₁（∃秩函数）与 Π₁（无下降列），
故 Δ₁——对传递 ZF 模型绝对（引理 12.6 的精细版）。\<close>

section \<open>一个小验证：受限公式的传递绝对性（引理 10.1 回响）\<close>

lemma restricted_transitivity:
  assumes "Transset(M)" "x \<in> M"
  shows "x \<subseteq> M"
  using assms unfolding Transset_def by blast

end
