theory Boolean
  imports "ZF-Constructible.AC_in_L"
begin

text \<open>第 17 章 完备布尔代数：分离性与 r.o.(P) 的骨架。\<close>

text \<open>分离性 (17.20)：p\<perp>q 时下方有 r\<le>p 且 r\<perp>q。\<close>

definition separative :: "i \<Rightarrow> o" where
  "separative(P) \<equiv> \<forall>p\<in>P. \<forall>q\<in>P. p\<noteq>q \<longrightarrow>
    (\<exists>r\<in>P. r\<le>p \<and> r\<inter>q = 0)"

text \<open>r.o.(P) = P 上正则开集的完备布尔代数（Lemma 17.2）。
完备化 = 正则割（Dedekind 割法）——docs 讲义。\<close>

end
