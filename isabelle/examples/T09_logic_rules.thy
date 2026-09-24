theory T09_logic_rules
  imports Main
begin

section \<open>9.1 逻辑规则的手动档\<close>

text \<open>自动化方法背后是几十条自然演绎规则。本章手动用一遍，
理解 @{verbatim "rule"} @{verbatim "erule"} @{verbatim "drule"}
三兄弟，以及"引入/消去"规则命名规律。\<close>

ML \<open>writeln "==== 09 开始 ===="\<close>

subsection \<open>9.2 引入规则（intro）与消去规则（elim）\<close>

lemma conj_demo: "A \<longrightarrow> B \<longrightarrow> A \<and> B"
  apply (rule impI)
  apply (rule impI)
  apply (rule conjI)
   apply assumption
  apply assumption
  done

text \<open>@{verbatim "impI"} @{verbatim "conjI"} 都是引入规则：
目标形如"要证 A⟷B"，引入规则把目标变成子目标。
@{verbatim "assumption"} 表示"当前目标已在前提里"。\<close>

lemma disj_demo: "(A \<or> B) \<and> (A \<longrightarrow> C) \<and> (B \<longrightarrow> C) \<longrightarrow> C"
proof
  assume h: "(A \<or> B) \<and> (A \<longrightarrow> C) \<and> (B \<longrightarrow> C)"
  from h have hAB: "A \<or> B" by blast
  from h have hAC: "A \<longrightarrow> C" by blast
  from h have hBC: "B \<longrightarrow> C" by blast
  from hAB show C
  proof (rule disjE)
    assume "A"
    from hAC and \<open>A\<close> show C by (rule mp)
  next
    assume "B"
    from hBC and \<open>B\<close> show C by (rule mp)
  qed
qed

text \<open>逐行看：@{verbatim "proof"} 后先 @{verbatim "assume"} 引入前提；
@{verbatim "from h have …"} 用自动化从合取里拆出三件事实；
@{verbatim "from hAB show C proof (rule disjE)"} 把析取分成两支，
两支里各自用 @{verbatim "rule mp"} 做肯定前件式。
这里刻意不用 @{verbatim "erule"}：当存在多条可匹配的前提时，
@{verbatim "erule"} 的挑选顺序不直观，显式 @{verbatim "from … show"}
比它可靠得多——这是第 13 章 Isar 的核心卖点。\<close>

subsection \<open>9.3 rule / erule / drule 的区别\<close>

text \<open>
@{verbatim "rule"}：与目标结论统一，把规则前提变成新子目标。
@{verbatim "erule"}：先吃掉一个前提，再与目标统一（消去规则专用）。
@{verbatim "drule"}：拿一个前提推出新事实再放回前提（正向推理）。
三者的区别只在于"用哪个边做匹配、怎么用前提"。\<close>

lemma modus_ponens: "A \<longrightarrow> B \<Longrightarrow> A \<Longrightarrow> B"
  by (drule mp) assumption

lemma spec_demo: "(\<forall>x. P x) \<Longrightarrow> P a"
  by (drule spec)

lemma all_demo: "(\<forall>x::nat. P x) \<Longrightarrow> (\<exists>x. P x)"
  apply (drule spec[where x = "0::nat"])
  apply (rule exI)
  apply assumption
  done

subsection \<open>9.4 反证法与经典逻辑\<close>

lemma classical_demo: "(\<not> A \<longrightarrow> A) \<longrightarrow> A"
  by blast

lemma "A \<or> \<not> A"
  by auto

text \<open>HOL 是经典逻辑（排中律可用），不是 Coq/Lean 式的构造逻辑。
@{verbatim "ccontr"} 与 @{verbatim "by_contra"} 把结论取反当假设，
第 14 章的集合等式常用这招。\<close>

lemma "(\<exists>x::nat. x = x) \<and> \<not> (\<forall>x::nat. x \<noteq> x)"
  by auto

subsection \<open>9.5 把规则打印出来看\<close>

ML \<open>
  writeln (@{make_string} @{thm impI});
  writeln (@{make_string} @{thm conjE});
  writeln (@{make_string} @{thm disjE})
\<close>

ML \<open>writeln "==== 09 结束 ===="\<close>

end
