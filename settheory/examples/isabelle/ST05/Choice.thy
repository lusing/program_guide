theory Choice
  imports "ZF.Zorn" "ZF-AC.WO1_WO7" "ZF-AC.DC"
begin

text \<open>
第 05 章 选择公理：ZF 库的 AC 会话全家桶。

Isabelle/ZF 的 AC 目录形式化了 Rubin 夫妇《Equivalents of the
Axiom of Choice, II》的大批等价形式（WO1-WO7、AC1-AC19 等），
Zorn 引理在 Zorn.thy。本章抽取锚点并完成引理 5.2 的机器化。
\<close>

section \<open>等价形式锚点\<close>

text \<open>Zorn 引理（ZF 库版）：链并封闭的族有极大成员。\<close>
thm Zorn

text \<open>依赖选择 DC 的等价链：\<close>
thm DC0_imp_DC_nat

section \<open>引理 5.2：下降序列破坏良序\<close>

text \<open>Jech 引理 5.2 的 (b) 方向（不需要 DC）：无穷下降序列
    的值域没有 r-极小元，破坏良序。\<close>

lemma descending_breaks_wellorder:
  assumes wo: "\<forall>A. A \<noteq> 0 \<longrightarrow> (\<exists>m \<in> A. \<forall>x \<in> A. \<langle>x, m\<rangle> \<notin> r)"
    and seq: "f: nat \<rightarrow> field(r)"
    and desc: "\<forall>n \<in> nat. \<langle>f`succ(n), f`n\<rangle> \<in> r"
  shows "False"
proof -
  let ?A = "{f`n . n \<in> nat}"
  have Ane: "?A \<noteq> 0"
    by blast
  from wo Ane obtain m where "m \<in> ?A"
    and min: "\<forall>x \<in> ?A. \<langle>x, m\<rangle> \<notin> r" by blast
  then obtain n where m: "m = f`n" and "n \<in> nat" by blast
  from desc have step: "\<langle>f`succ(n), f`n\<rangle> \<in> r"
    using \<open>n \<in> nat\<close> by blast
  have "f`succ(n) \<in> ?A" by (blast intro: \<open>n \<in> nat\<close>)
  with min m step show False by blast
qed

end
