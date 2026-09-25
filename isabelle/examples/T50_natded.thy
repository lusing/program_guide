theory T50_natded
  imports Main
begin

section \<open>50.1 自然演绎：Isar 的数学底牌\<close>

text \<open>Gentzen 的自然演绎（ND）是 @{verbatim "have/show"} 背后的
证明论骨架：每条逻辑连词配**引入规则**（怎么造出它）与**消去规则**
（怎么用它）。Isar 的 @{verbatim "assume"} 就是 ND 的假设开枝，
@{verbatim "show"} 就是枝头结论；@{verbatim "obtain"}（第 13 章）就是
∃ 消去。本章把常用导出规则当**引理**证一遍——它们正是
@{verbatim "blast"} 内部挥舞的兵器谱。直觉主义/经典的分野见第 47 章。\<close>

ML \<open>writeln "==== 50 开始 ===="\<close>

subsection \<open>50.2 演绎定理：assume 的合法性\<close>

text \<open>ND 的元定理"从 \\<Gamma>, A 推出 B，则从 \\<Gamma> 推出 A \\<longrightarrow> B"，
在 Isabelle 里不是定理而是**语法**（@{verbatim "assume"} 直接生效）。
把它当对象层引理玩一遍：\<close>

lemma ded_style: "(A \<Longrightarrow> B) \<Longrightarrow> A \<longrightarrow> B"
  by (rule impI)

subsection \<open>50.3 导出规则兵器谱\<close>

text \<open>每条都用纯引入/消去规则手搓（@{verbatim "rule"}/@{verbatim "erule"}），
最后与 @{verbatim "blast"} 的秒解对照：\<close>

lemma disj_swap_r: "P \<or> Q \<Longrightarrow> Q \<or> P"
  apply (erule disjE)
   apply (rule disjI2, assumption)
  apply (rule disjI1, assumption)
  done

subsection \<open>50.4 反证法与经典等价链\<close>

lemma classical_chain:
  "(\<not> P \<Longrightarrow> False) \<Longrightarrow> P"
  by blast

lemma peirce_hol: "((P \<longrightarrow> Q) \<longrightarrow> P) \<longrightarrow> P"
  by blast

lemma dn_classical: "\<not> \<not> P \<longrightarrow> P"
  by blast

subsection \<open>50.5 合取/析构的 Isar 形状\<close>

text \<open>ND 的 ∧E 在 Isar 里是 @{verbatim "obtain"}；∨E 是
@{verbatim "cases"} + 两枝 @{verbatim "show"}。一个完整的双枝证明：\<close>

lemma and_or_dist: "(P \<or> Q) \<and> R \<longrightarrow> (P \<and> R) \<or> (Q \<and> R)"
proof (rule impI)
  assume "(P \<or> Q) \<and> R"
  then obtain pq: "P \<or> Q" and r: "R" by blast
  from pq show "(P \<and> R) \<or> (Q \<and> R)"
  proof (rule disjE)
    assume "P"
    with r have "P \<and> R" by simp
    then show ?thesis by (rule disjI1)
  next
    assume "Q"
    with r have "Q \<and> R" by simp
    then show ?thesis by (rule disjI2)
  qed
qed

subsection \<open>50.6 坑位清单（实测）\<close>

text \<open>1. 导出规则的证明里 @{verbatim "blast"} 与手搓混用要小心
   循环：@{verbatim "by blast"} 万事大吉，但教学章手搓才有价值。
2. 元层箭头（Isabelle 的 \\<Longrightarrow>）与对象层箭头（逻辑的 \\<longrightarrow>）
   一字之差——写反了 @{verbatim "impI"} 直接对不上。
3. Peirce 律/双非消去**依赖经典逻辑**：在 IFOL（47 章）里
   证不出，搬证明前先看逻辑。\<close>

thm ded_style peirce_hol dn_classical

ML \<open>writeln "==== 50 结束 ===="\<close>

end
