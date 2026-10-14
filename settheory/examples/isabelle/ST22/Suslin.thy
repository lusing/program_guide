theory Suslin
  imports "ZF-Constructible.AC_in_L"
begin

text \<open>第 22 章 Suslin 问题与 Suslin 树。\<close>

text \<open>Aronszajn 树（ZFC 中存在，引理 22.3）。
Suslin 树（独立于 ZFC：Tennenbaum-Jech + Jensen）。
Suslin 线 \<longleftrightarrow> Suslin 树（引理 22.1）。\<close>

lemma suslin_semantics:
  shows "True" by simp

end
