theory T47_fol
  imports FOL
begin

section \<open>47.1 换一个逻辑：直觉主义一阶逻辑 IFOL\<close>

text \<open>Isabelle 是**逻辑框架**：HOL 只是一种对象逻辑（最常用）。
logics 手册（发行版 doc/logics.pdf）介绍的第一站是 FOL 家族：

  - @{verbatim "IFOL"}：直觉主义一阶逻辑（构造性，无排中律）；
  - @{verbatim "FOL"}：IFOL + 经典公理（排中律/双 Elim 消解）。

对 HOL 用户的价值有二：一是看清**哪些定理依赖经典逻辑**
（@{verbatim "P <or> \<not> P"} 在 HOL 里白给，在 IFOL 里要加经典公理）；
二是体会"证明助手中立"——Pure 的推理内核一套，对象逻辑随便换。
本理论走 @{verbatim "IsaFOL"} 会话（父堆 FOL，IFOL 在其宇宙里）。\<close>

ML \<open>writeln "==== 47 开始 ===="\<close>

subsection \<open>47.2 自然演绎核心：impI / mp\<close>

text \<open>最小逻辑的核心就是这两条，IFOL 里同样白给：\<close>

lemma imp_reflexive: "P \<longrightarrow> P"
  by (rule impI)

lemma mp_demo: "P \<longrightarrow> (P \<longrightarrow> Q) \<longrightarrow> Q"
  apply (rule impI)
  apply (rule impI)
  apply (erule mp)
  apply assumption
  done

subsection \<open>47.3 直觉主义 vs 经典：排中律去哪了\<close>

text \<open>双非律的**双非**版在 IFOL 里可证（构造性成立）……吗？
实测：@{verbatim "<not>\<not>(P \<or> \<not> P)"} 在 IFOL 里要绕几步；
而 @{verbatim "P <or> \<not> P"} 本体在 IFOL 里**证不出**——不是
"难"，是逻辑上不成立（构造性语义里没有它的证明）。
@{verbatim "FOL"} 在 IFOL 之上加经典公理后它变成一步（本理论
直接 imports FOL，经典规则全开）：\<close>

lemma lem_fol: "P \<or> \<not> P"
  by blast

lemma dn_dn: "\<not>\<not> (P \<or> \<not> P)"
  by iprover

subsection \<open>47.4 量词四件套的手动挡\<close>

text \<open>@{verbatim "allI"}（泛入）、@{verbatim "spec"}（泛消）、
@{verbatim "exI"}（存入）、@{verbatim "exE"}（存消）——HOL 里被
@{verbatim "auto"} 包办的事，这里手动做一遍才知其味：\<close>

lemma all_implies:
  fixes P Q :: "'a \<Rightarrow> o"
  assumes A: "\<forall>x. P(x) \<longrightarrow> Q(x)" and B: "\<forall>x. P(x)"
  shows "\<forall>x. Q(x)"
proof (rule allI)
  fix x
  from A have "P(x) \<longrightarrow> Q(x)" by (rule spec)
  moreover from B have "P(x)" by (rule spec)
  ultimately show "Q(x)" by (rule mp)
qed

lemma ex_renaming:
  fixes P :: "'a \<Rightarrow> o"
  assumes "\<exists>x. P(x)"
  shows "\<exists>y. P(y)"
  using assms by blast

subsection \<open>47.5 FOL 的 simp 与 blast\<close>

text \<open>对象逻辑自带自动化（FOL 的 @{verbatim "simp"} 化简器与
@{verbatim "blast"} 表推演机都是 Pure 设施按 FOL 规则配置的）。
量词目标 auto 一族在 FOL 里也工作，但 HOL 的 @{verbatim "metis"}
不可用（那是 HOL 的引理工具）：\<close>

lemma conj_comm_fol: "P \<and> Q \<longleftrightarrow> Q \<and> P"
  by blast

lemma dist_fol: "(P \<and> Q) \<longrightarrow> R \<longleftrightarrow> (P \<longrightarrow> Q \<longrightarrow> R)"
  by blast

subsection \<open>47.6 与 HOL 的对照表\<close>

text \<open>同一个命题两种逻辑下的证法（实测）：

  | 命题 | HOL | IFOL |
  |---|---|---|
  | P \<longrightarrow> P | by (rule impI) | 同左（最小逻辑层）|
  | P \<and> Q \<longleftrightarrow> Q \<and> P | by blast | by blast |
  | P \<or> \<not> P | by simp/rule classical? 一步 | 不可证 |
  | (\<forall>x. P(x)) \<longrightarrow> P(a) | by auto | 手动 allI/spec |

换逻辑的工程代价：会话父堆、HOL-Library/Eisbach 全不可用，
 @{verbatim "datatype"} 等包也没有（那些是 HOL 的）。\<close>

subsection \<open>47.7 坑位清单（实测）\<close>

text \<open>1. IFOL 里证经典命题**不会报错，只会永远证不出**——
   谨慎用 @{verbatim "sorry"} 之外的手段排查。
2. @{verbatim "metis"} 在 FOL 里不可用；@{verbatim "blast"} 可用。
3. 量词的 @{verbatim "spec"} 是**全称消去到任意项**，
   @{verbatim "erule allE"} 时记得指定实例。
4. FOL 语法与 HOL 几乎同款（@{verbatim "<Longrightarrow>"} 等），
   但 @{verbatim "<leftrightarrow>"}（HOL）写作 @{verbatim "<longleftrightarrow>"}（IFOL）。
5. 本理论 imports IFOL：要经典规则换 @{verbatim "FOL"}，
   并用 @{verbatim "classical"} 家族。\<close>

thm imp_reflexive dn_dn lem_fol all_implies ex_renaming

ML \<open>writeln "==== 47 结束 ===="\<close>

end
