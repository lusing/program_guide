theory T47_fol
  imports FOL
begin

section \<open>47.1 FOL：一阶逻辑对象逻辑\<close>

text \<open>Isabelle 是**逻辑框架**（第 56 章）：HOL 只是它最常用的一种
对象逻辑。FOL 家族展示了 Isabelle 的核心设计哲学——**同一套推理内核，
可以搭载不同的对象逻辑**。

FOL 会话包含两个理论：

  - @{verbatim "IFOL"}：直觉主义一阶逻辑（构造性，无排中律）；
  - @{verbatim "FOL"}：IFOL + 经典公理（排中律、双非消去）。

本理论 @{verbatim "imports FOL"}，经典规则全开。对 HOL 用户的价值：

  1. 看清哪些定理依赖经典逻辑（@{verbatim "P \<or> \<not> P"} 在 HOL 里白给，
     在 IFOL 里**不存在**证明）；
  2. 手动做一遍自然演绎，理解 @{verbatim "auto"} 在 HOL 里到底包办了哪些事；
  3. 体会 FOL 的语法与 HOL 的微妙差异（谓词类型、函数式应用、可用工具）。

FOL 的库索引见发行版 @{verbatim "FOL"} 会话目录。\<close>

ML \<open>writeln "==== 47 开始 ===="\<close>


subsection \<open>47.2 FOL 的类型系统：@{verbatim "o"} 与 @{verbatim "'a \<Rightarrow> o"}\<close>

text \<open>FOL 没有 HOL 的丰富类型系统。只有两种类型：

  - @{verbatim "o"}：命题类型（真值）；
  - @{verbatim "'a \<Rightarrow> o"}：谓词类型（从个体到真值的函数）。

个体变量用类型变量 @{verbatim "'a"} 表示（多态），没有 @{verbatim "i"} 类型
（老教程里的 @{verbatim "i"} 在 Isabelle2026 里已经不存在，实测报
@{verbatim "Undefined type name"}）。

声明谓词变量的正确写法：\<close>

text \<open>@{verbatim "fixes P Q :: \"'a \<Rightarrow> o\""}\<close>

text \<open>这意味着 @{verbatim "P"} 和 @{verbatim "Q"} 是从任意类型 @{verbatim "'a"}
到命题 @{verbatim "o"} 的函数。写 @{verbatim "P(x)"} 时 @{verbatim "x"} 的类型
自动推断为 @{verbatim "'a"}。\<close>


subsection \<open>47.3 合取（conjunction）\<close>

text \<open>合取 @{verbatim "P \<and> Q"} 有三条核心规则：

  - @{verbatim "conjI"}：引入——从 @{verbatim "P"} 和 @{verbatim "Q"} 得到 @{verbatim "P \<and> Q"}；
  - @{verbatim "conjunct1"}：消去左——从 @{verbatim "P \<and> Q"} 得到 @{verbatim "P"}；
  - @{verbatim "conjunct2"}：消去右——从 @{verbatim "P \<and> Q"} 得到 @{verbatim "Q"}。\<close>

lemma conj_intro_demo:
  assumes "P" and "Q"
  shows "P \<and> Q"
  using assms by blast

lemma conj_elim_left_demo:
  assumes "P \<and> Q"
  shows "P"
  using assms by (rule conjunct1)

lemma conj_elim_right_demo:
  assumes "P \<and> Q"
  shows "Q"
  using assms by (rule conjunct2)

text \<open>合取的消除规则 @{verbatim "conjE"} 允许同时解构两个分量：\<close>

lemma conjE_demo:
  assumes "P \<and> Q" and "P \<Longrightarrow> Q \<Longrightarrow> R"
  shows "R"
  using assms by (rule conjE)

text \<open>合取交换律——用 Isar 手动证一遍：\<close>

lemma conj_comm: "P \<and> Q \<longleftrightarrow> Q \<and> P"
proof
  assume "P \<and> Q"
  then have "P" by (rule conjunct1)
  moreover from \<open>P \<and> Q\<close> have "Q" by (rule conjunct2)
  ultimately show "Q \<and> P" by blast
next
  assume "Q \<and> P"
  then have "Q" by (rule conjunct1)
  moreover from \<open>Q \<and> P\<close> have "P" by (rule conjunct2)
  ultimately show "P \<and> Q" by blast
qed

text \<open>当然，@{verbatim "blast"} 一步就能完成：\<close>

lemma conj_comm_auto: "P \<and> Q \<longleftrightarrow> Q \<and> P"
  by blast


subsection \<open>47.4 析取（disjunction）\<close>

text \<open>析取 @{verbatim "P \<or> Q"} 有引入和消除规则：

  - @{verbatim "disjI1"}：从左引入——@{verbatim "P \<Longrightarrow> P \<or> Q"}；
  - @{verbatim "disjI2"}：从右引入——@{verbatim "Q \<Longrightarrow> P \<or> Q"}；
  - @{verbatim "disjE"}：消除——从 @{verbatim "P \<or> Q"}、@{verbatim "P \<Longrightarrow> R"}、
    @{verbatim "Q \<Longrightarrow> R"} 得到 @{verbatim "R"}。\<close>

lemma disj_intro_left: "P \<Longrightarrow> P \<or> Q"
  by (rule disjI1)

lemma disj_intro_right: "Q \<Longrightarrow> P \<or> Q"
  by (rule disjI2)

lemma disj_elim_demo:
  assumes "P \<or> Q" and "P \<Longrightarrow> R" and "Q \<Longrightarrow> R"
  shows "R"
  using assms by (rule disjE)

text \<open>经典析取引入 @{verbatim "disjCI"}：若 @{verbatim "\<not>Q \<Longrightarrow> P"} 则 @{verbatim "P \<or> Q"}。
这条规则依赖经典逻辑（在 IFOL 里不可用）：\<close>

thm disjCI


subsection \<open>47.5 蕴含（implication）\<close>

text \<open>蕴含 @{verbatim "P \<longrightarrow> Q"} 的核心规则：

  - @{verbatim "impI"}：引入——假设 @{verbatim "P"} 证 @{verbatim "Q"}，则得到 @{verbatim "P \<longrightarrow> Q"}；
  - @{verbatim "mp"}（Modus Ponens）：消去——从 @{verbatim "P \<longrightarrow> Q"} 和 @{verbatim "P"} 得到 @{verbatim "Q"}。\<close>

lemma imp_reflexive: "P \<longrightarrow> P"
  by (rule impI)

lemma mp_demo:
  assumes "P \<longrightarrow> Q" and "P"
  shows "Q"
  using assms by (rule mp)

text \<open>反向 Modus Ponens @{verbatim "rev_mp"}：前提顺序相反：\<close>

lemma rev_mp_demo:
  assumes "P" and "P \<longrightarrow> Q"
  shows "Q"
  using assms by (rule rev_mp)

text \<open>蕴含的消除规则 @{verbatim "impE"} 允许在证明中展开：\<close>

lemma impE_demo:
  assumes "P \<longrightarrow> Q" and "P" and "Q \<Longrightarrow> R"
  shows "R"
  using assms by (rule impE)

text \<open>蕴含的自反性和传递性：\<close>

thm imp_refl

lemma imp_trans:
  assumes "P \<longrightarrow> Q" and "Q \<longrightarrow> R"
  shows "P \<longrightarrow> R"
  using assms by blast


subsection \<open>47.6 否定（negation）\<close>

text \<open>FOL 里 @{verbatim "\<not>P"} 定义为 @{verbatim "P \<longrightarrow> False"}
（ @{verbatim "not_def"}）。核心规则：

  - @{verbatim "notI"}：引入——假设 @{verbatim "P"} 推出 @{verbatim "False"}，
    则 @{verbatim "\<not>P"}；
  - @{verbatim "notE"}：消除——从 @{verbatim "\<not>P"} 和 @{verbatim "P"} 得到任意结论。\<close>

lemma not_intro_demo:
  assumes "P \<Longrightarrow> False"
  shows "\<not>P"
  using assms by (rule notI)

lemma not_elim_demo:
  assumes "\<not>P" and "P"
  shows "R"
  using assms by (rule notE)

text \<open>从 @{verbatim "False"} 可以推出任意命题（爆炸原理）：\<close>

lemma false_elim: "False \<Longrightarrow> P"
  by (rule FalseE)

text \<open>经典反证法 @{verbatim "ccontr"}：若 @{verbatim "\<not>P \<Longrightarrow> False"} 则 @{verbatim "P"}。
这条规则依赖经典逻辑：\<close>

lemma ccontr_demo:
  assumes "\<not>P \<Longrightarrow> False"
  shows "P"
  using assms by (rule ccontr)

text \<open>经典双非消去 @{verbatim "notnotD"}：@{verbatim "\<not>\<not>P \<Longrightarrow> P"}：\<close>

lemma notnotD_demo: "\<not>\<not>P \<Longrightarrow> P"
  by (rule notnotD)

text \<open>注意：在 IFOL（直觉主义逻辑）里，@{verbatim "ccontr"} 和 @{verbatim "notnotD"}
都**不可用**。直觉主义逻辑只接受 @{verbatim "P \<Longrightarrow> \<not>\<not>P"}（双非引入），
不接受反向。\<close>


subsection \<open>47.7 双条件（biconditional）\<close>

text \<open>@{verbatim "P \<longleftrightarrow> Q"} 定义为 @{verbatim "(P \<longrightarrow> Q) \<and> (Q \<longrightarrow> P)"}
（@{verbatim "iff_def"}）。核心规则：

  - @{verbatim "iffI"}：引入——从 @{verbatim "P \<Longrightarrow> Q"} 和 @{verbatim "Q \<Longrightarrow> P"}
    得到 @{verbatim "P \<longleftrightarrow> Q"}；
  - @{verbatim "iffD1"}：从左到右——从 @{verbatim "P \<longleftrightarrow> Q"} 和 @{verbatim "P"} 得到 @{verbatim "Q"}；
  - @{verbatim "iffD2"}：从右到左——从 @{verbatim "P \<longleftrightarrow> Q"} 和 @{verbatim "Q"} 得到 @{verbatim "P"}。\<close>

lemma iff_intro_demo:
  assumes "P \<Longrightarrow> Q" and "Q \<Longrightarrow> P"
  shows "P \<longleftrightarrow> Q"
  using assms by (rule iffI)

lemma iff_elim_lr_demo:
  assumes "P \<longleftrightarrow> Q" and "P"
  shows "Q"
  using assms by (rule iffD1)

lemma iff_elim_rl_demo:
  assumes "P \<longleftrightarrow> Q" and "Q"
  shows "P"
  using assms by (rule iffD2)

text \<open>双条件的自反性、对称性、传递性：\<close>

thm iff_refl
thm iff_sym
thm iff_trans


subsection \<open>47.8 经典 vs 直觉主义：排中律\<close>

text \<open>排中律 @{verbatim "P \<or> \<not> P"} 是经典逻辑的标志性定理。
在 FOL（经典）里 @{verbatim "blast"} 一步完成：\<close>

lemma excluded_middle: "P \<or> \<not> P"
  by blast

text \<open>库中已有 @{verbatim "excluded_middle"} 定理：\<close>

thm excluded_middle

text \<open>情形分解 @{verbatim "case_split"}：若 @{verbatim "P \<Longrightarrow> Q"} 且
@{verbatim "\<not>P \<Longrightarrow> Q"} 则 @{verbatim "Q"}：\<close>

lemma case_split_demo:
  assumes "P \<Longrightarrow> Q" and "\<not>P \<Longrightarrow> Q"
  shows "Q"
  using assms by (rule case_split)

text \<open>在 IFOL（直觉主义）里，排中律**不可证**——不是"难"，
是逻辑上不存在证明。直觉主义语义要求构造性证据，
而 @{verbatim "P \<or> \<not> P"} 没有统一的构造方法。
@{verbatim "iprover"} 是直觉主义证明器，能证直觉主义有效式；
@{verbatim "blast"} 是经典表推演机，能证经典有效式。\<close>

text \<open>双非排中律 @{verbatim "\<not>\<not>(P \<or> \<not> P)"} 在直觉主义里可证：\<close>

lemma dn_dn_lem: "\<not>\<not>(P \<or> \<not> P)"
  by iprover


subsection \<open>47.9 全称量词\<close>

text \<open>全称量词 @{verbatim "\<forall>x. P(x)"} 的核心规则：

  - @{verbatim "allI"}：引入——证 @{verbatim "P(x)"} 对任意 @{verbatim "x"} 成立；
  - @{verbatim "spec"}：消去（实例化）——从 @{verbatim "\<forall>x. P(x)"} 得到 @{verbatim "P(t)"}。\<close>

lemma all_intro_demo:
  fixes P :: "'a \<Rightarrow> o"
  assumes "\<And>x. P(x)"
  shows "\<forall>x. P(x)"
  using assms by (rule allI)

lemma spec_demo:
  fixes P :: "'a \<Rightarrow> o"
  assumes "\<forall>x. P(x)"
  shows "P(a)"
  using assms by (rule spec)

text \<open>更强大的全称消去 @{verbatim "allE"}：\<close>

lemma allE_demo:
  fixes P :: "'a \<Rightarrow> o"
  assumes "\<forall>x. P(x)" and "P(a) \<Longrightarrow> Q"
  shows "Q"
  using assms by (rule allE)

text \<open>手动完成一个量词推理：\<close>

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

text \<open>全称量词的分配律：\<close>

lemma all_conj_distrib: "(\<forall>x. P(x) \<and> Q(x)) \<longleftrightarrow> (\<forall>x. P(x)) \<and> (\<forall>x. Q(x))"
  by blast


subsection \<open>47.10 存在量词\<close>

text \<open>存在量词 @{verbatim "\<exists>x. P(x)"} 的核心规则：

  - @{verbatim "exI"}：引入——从 @{verbatim "P(t)"} 得到 @{verbatim "\<exists>x. P(x)"}；
  - @{verbatim "exE"}：消除——从 @{verbatim "\<exists>x. P(x)"} 和 @{verbatim "P(x) \<Longrightarrow> Q"}
    （@{verbatim "x"} 不在 @{verbatim "Q"} 中自由出现）得到 @{verbatim "Q"}。\<close>

lemma ex_intro_demo:
  fixes P :: "'a \<Rightarrow> o"
  assumes "P(a)"
  shows "\<exists>x. P(x)"
  using assms by (rule exI)

lemma ex_elim_demo:
  fixes P :: "'a \<Rightarrow> o"
  assumes "\<exists>x. P(x)" and "\<And>x. P(x) \<Longrightarrow> Q"
  shows "Q"
  using assms by (rule exE)

text \<open>存在量词的重命名：\<close>

lemma ex_renaming:
  fixes P :: "'a \<Rightarrow> o"
  assumes "\<exists>x. P(x)"
  shows "\<exists>y. P(y)"
  using assms by blast

text \<open>经典存在引入 @{verbatim "exCI"}：若 @{verbatim "\<forall>x. \<not>P(x) \<Longrightarrow> P(a)"}
则 @{verbatim "\<exists>x. P(x)"}：\<close>

thm exCI

text \<open>存在量词的分配律：\<close>

lemma ex_disj_distrib: "(\<exists>x. P(x) \<or> Q(x)) \<longleftrightarrow> (\<exists>x. P(x)) \<or> (\<exists>x. Q(x))"
  by blast


subsection \<open>47.11 唯一存在\<close>

text \<open>唯一存在 @{verbatim "\<exists>!x. P(x)"} 定义为
@{verbatim "\<exists>x. P(x) \<and> (\<forall>y. P(y) \<longrightarrow> y = x)"}（@{verbatim "ex1_def"}）。

引入规则 @{verbatim "ex1I"}：若 @{verbatim "P(a)"} 成立且任何满足 @{verbatim "P"} 的
@{verbatim "x"} 都等于 @{verbatim "a"}，则 @{verbatim "\<exists>!x. P(x)"}：\<close>

lemma ex1_intro_demo:
  fixes P :: "'a \<Rightarrow> o"
  assumes "P(a)" and "\<And>x. P(x) \<Longrightarrow> x = a"
  shows "\<exists>!x. P(x)"
  using assms by (rule ex1I)

text \<open>另一个引入规则 @{verbatim "ex_ex1I"}：若已知 @{verbatim "\<exists>x. P(x)"}
且任意两个满足 @{verbatim "P"} 的元素相等，则唯一存在：\<close>

lemma ex_ex1I_demo:
  fixes P :: "'a \<Rightarrow> o"
  assumes "\<exists>x. P(x)" and "\<And>x y. P(x) \<Longrightarrow> P(y) \<Longrightarrow> x = y"
  shows "\<exists>!x. P(x)"
  using assms by (rule ex_ex1I)

text \<open>消除规则 @{verbatim "ex1E"}：\<close>

thm ex1E

text \<open>唯一存在的功能性：若 @{verbatim "\<exists>!z. P(a,z)"} 且 @{verbatim "P(a,b)"}
和 @{verbatim "P(a,c)"} 都成立，则 @{verbatim "b = c"}：\<close>

thm ex1_functional


subsection \<open>47.12 等词\<close>

text \<open>FOL 的等词 @{verbatim "="} 有三条基本规则：

  - @{verbatim "refl"}：自反性 @{verbatim "a = a"}；
  - @{verbatim "sym"}：对称性 @{verbatim "a = b \<Longrightarrow> b = a"}；
  - @{verbatim "trans"}：传递性 @{verbatim "a = b \<Longrightarrow> b = c \<Longrightarrow> a = c"}。\<close>

lemma refl_demo: "a = a"
  by (rule refl)

lemma sym_demo: "a = b \<Longrightarrow> b = a"
  by (rule sym)

lemma trans_demo: "a = b \<Longrightarrow> b = c \<Longrightarrow> a = c"
  by (rule trans)

text \<open>替换规则 @{verbatim "subst"}：若 @{verbatim "a = b"} 则 @{verbatim "P(a) \<Longrightarrow> P(b)"}：\<close>

lemma subst_demo:
  assumes "a = b" and "P(a)"
  shows "P(b)"
  using assms by (rule subst)

text \<open>对称替换 @{verbatim "ssubst"}：若 @{verbatim "b = a"} 则 @{verbatim "P(a) \<Longrightarrow> P(b)"}：\<close>

lemma ssubst_demo:
  assumes "b = a" and "P(a)"
  shows "P(b)"
  using assms by (rule ssubst)

text \<open>等词的交换律：@{verbatim "a = b \<longleftrightarrow> b = a"}：\<close>

thm eq_commute


subsection \<open>47.13 定义：True、not、iff、Let\<close>

text \<open>FOL 里 @{verbatim "True"} 定义为 @{verbatim "False \<longrightarrow> False"}：\<close>

lemma TrueI_demo: "True"
  by (rule TrueI)

text \<open>@{verbatim "\<not>P"} 定义为 @{verbatim "P \<longrightarrow> False"}（@{verbatim "not_def"}）。
这意味着否定规则本质上就是蕴含规则。\<close>

thm not_def

text \<open>@{verbatim "P \<longleftrightarrow> Q"} 定义为 @{verbatim "(P \<longrightarrow> Q) \<and> (Q \<longrightarrow> P)"}
（@{verbatim "iff_def"}）：\<close>

thm iff_def

text \<open>@{verbatim "Let(s, f)"} 定义为 @{verbatim "f(s)"}——就是简单的代入：\<close>

lemma Let_demo: "Let(s, f) = f(s)"
  by (unfold Let_def, rule refl)

text \<open>@{verbatim "Uniq(P)"} 定义为 @{verbatim "\<forall>x y. P(x) \<longrightarrow> P(y) \<longrightarrow> y = x"}
——谓词 @{verbatim "P"} 最多被一个元素满足：\<close>

thm Uniq_def


subsection \<open>47.14 自动化：simp、blast、iprover\<close>

text \<open>FOL 提供三种自动化工具：

  - @{verbatim "simp"}：化简器，使用 @{verbatim "IFOL_ss"}（直觉主义）
    或 @{verbatim "FOL_ss"}（经典）化简集；
  - @{verbatim "blast"}：经典表推演机，完备的一阶逻辑证明器；
  - @{verbatim "iprover"}：直觉主义证明器，只证构造性有效的公式。

HOL 的 @{verbatim "metis"} 和 @{verbatim "smt"} 在 FOL 里**不可用**。\<close>

text \<open>化简器能自动处理命题逻辑的恒等式：\<close>

lemma conj_comm_simp: "P \<and> Q \<longleftrightarrow> Q \<and> P"
  by blast

lemma disj_comm_simp: "P \<or> Q \<longleftrightarrow> Q \<or> P"
  by blast

lemma imp_conj_distrib_simp: "(P \<longrightarrow> Q \<and> R) \<longleftrightarrow> (P \<longrightarrow> Q) \<and> (P \<longrightarrow> R)"
  by blast

text \<open>@{verbatim "blast"} 能自动处理带量词的公式：\<close>

lemma blast_quantifier:
  fixes P Q :: "'a \<Rightarrow> o"
  shows "(\<forall>x. P(x) \<longrightarrow> Q(x)) \<longrightarrow> (\<forall>x. P(x)) \<longrightarrow> (\<forall>x. Q(x))"
  by blast

text \<open>@{verbatim "iprover"} 能证直觉主义有效式：\<close>

lemma iprover_demo: "\<not>\<not>(P \<or> \<not> P)"
  by iprover

text \<open>但 @{verbatim "iprover"} 证不了经典有效式：\<close>

text \<open>@{verbatim "lemma lem: \"P \<or> \<not> P\" by iprover"} 会失败。\<close>


subsection \<open>47.15 De Morgan 律与分配律\<close>

text \<open>FOL 库提供了完整的 De Morgan 律和分配律：\<close>

thm de_Morgan_disj
thm de_Morgan_conj
thm not_imp
thm not_all
thm not_ex

text \<open>分配律：\<close>

lemma conj_disj_distribL: "P \<and> (Q \<or> R) \<longleftrightarrow> (P \<and> Q) \<or> (P \<and> R)"
  by blast

lemma disj_conj_distribL: "P \<or> (Q \<and> R) \<longleftrightarrow> (P \<or> Q) \<and> (P \<or> R)"
  by blast

text \<open>量词与联结词的交互：\<close>

lemma imp_ex: "((\<exists>x. P(x)) \<longrightarrow> Q) \<longleftrightarrow> (\<forall>x. P(x) \<longrightarrow> Q)"
  by blast

lemma all_conj_distrib_full: "(\<forall>x. P(x) \<and> Q(x)) \<longleftrightarrow> (\<forall>x. P(x)) \<and> (\<forall>x. Q(x))"
  by blast

lemma ex_disj_distrib_full: "(\<exists>x. P(x) \<or> Q(x)) \<longleftrightarrow> (\<exists>x. P(x)) \<or> (\<exists>x. Q(x))"
  by blast


subsection \<open>47.16 等词推理与 calculational 规则\<close>

text \<open>FOL 支持等式的链式推理（calculational reasoning）。
@{verbatim "trans"} 规则标记为 @{verbatim "[trans]"}，可以用于
@{verbatim "also"} / @{verbatim "finally"} 计算块：\<close>

lemma chain_demo:
  assumes "a = b" and "b = c" and "c = d"
  shows "a = d"
proof -
  from assms(1) have "a = b" .
  also from assms(2) have "b = c" .
  also from assms(3) have "c = d" .
  finally show "a = d" .
qed

text \<open>替换规则 @{verbatim "forw_subst"} 和 @{verbatim "back_subst"}
也标记为 @{verbatim "[trans]"}，允许在等式链中做谓词替换：\<close>

thm forw_subst
thm back_subst


subsection \<open>47.17 经典推理的额外规则\<close>

text \<open>FOL（经典）比 IFOL（直觉主义）多出以下规则：

  - @{verbatim "classical"}：@{verbatim "(\<not>P \<Longrightarrow> P) \<Longrightarrow> P"}——经典公理本身；
  - @{verbatim "ccontr"}：@{verbatim "(\<not>P \<Longrightarrow> False) \<Longrightarrow> P"}——反证法；
  - @{verbatim "notnotD"}：@{verbatim "\<not>\<not>P \<Longrightarrow> P"}——双非消去；
  - @{verbatim "excluded_middle"}：@{verbatim "\<not>P \<or> P"}——排中律；
  - @{verbatim "case_split"}：@{verbatim "\<lbrakk>P \<Longrightarrow> Q; \<not>P \<Longrightarrow> Q\<rbrakk> \<Longrightarrow> Q"}——情形分解；
  - @{verbatim "disjCI"}：@{verbatim "(\<not>Q \<Longrightarrow> P) \<Longrightarrow> P \<or> Q"}——经典析取引入；
  - @{verbatim "exCI"}：@{verbatim "(\<forall>x. \<not>P(x) \<Longrightarrow> P(a)) \<Longrightarrow> \<exists>x. P(x)"}——经典存在引入；
  - @{verbatim "impCE"}：@{verbatim "\<lbrakk>P \<longrightarrow> Q; \<not>P \<Longrightarrow> R; Q \<Longrightarrow> R\<rbrakk> \<Longrightarrow> R"}——经典蕴含消去。

这些规则在 IFOL 里都不可用。\<close>

thm classical
thm ccontr
thm notnotD
thm excluded_middle
thm case_split
thm disjCI
thm exCI


subsection \<open>47.18 同余规则（congruence）\<close>

text \<open>FOL 提供了各联结词的同余规则——若子公式等价则整体等价：\<close>

thm conj_cong
thm disj_cong
thm imp_cong
thm iff_cong
thm not_cong
thm all_cong
thm ex_cong
thm ex1_cong

text \<open>这些规则主要用于化简器的上下文敏感重写。\<close>


subsection \<open>47.19 与 HOL 的对照表\<close>

text \<open>同一个命题在 HOL 和 FOL 里的证法对比（实测）：

    | 命题 | HOL | FOL |
    |---|---|---|
    | P \<longrightarrow> P | by (rule impI) | 同左（最小逻辑层）|
    | P \<and> Q \<longleftrightarrow> Q \<and> P | by blast | by blast |
    | P \<or> \<not> P | by simp | by blast（经典公理）|
    | (\<forall>x. P(x)) \<longrightarrow> P(a) | by auto | 手动 allI/spec |
    | \<exists>x. P(x) \<longrightarrow> \<forall>x. P(x) | by blast | by blast |
    | ~~P \<longrightarrow> P | by simp | by (rule notnotD) |

工程代价：

  - HOL-Library / Eisbach 全不可用；
  - @{verbatim "datatype"} / @{verbatim "primrec"} / @{verbatim "fun"} 等包也没有
    （那些是 HOL 的）；
  - @{verbatim "metis"} / @{verbatim "smt"} 不可用（那是 HOL 的引理工具）；
  - @{verbatim "blast"} / @{verbatim "iprover"} / @{verbatim "simp"} 可用。\<close>


subsection \<open>47.20 坑位清单（实测）\<close>

text \<open>1. @{verbatim "i"} 类型不存在——个体用默认 sort 的类型变量 @{verbatim "'a"}，
   谓词 @{verbatim "'a \<Rightarrow> o"}。老教程里的 @{verbatim ":: i"} 写法在
   Isabelle2026 里直接报错。
2. **@{verbatim "P x"} 空格应用解析失败**——用 @{verbatim "P(x)"}
  （ZF 同款，第 48 章）。@{verbatim "P x"} 在量词体里触发
   Inner syntax error，报错位置从 @{verbatim "x"} 开始——极具误导性。
3. IFOL 里证经典命题**不会报错，只会永远证不出**——
   谨慎用 @{verbatim "sorry"} 之外的手段排查。
4. @{verbatim "metis"} / @{verbatim "smt"} 不可用；@{verbatim "blast"} / @{verbatim "iprover"} 可用。
5. 多方法串联 @{verbatim "by m1 m2"} 之后**另起一行的括号**是 outer syntax
   错误（keyword ( expected）——用 apply 脚本分行。
6. @{verbatim "fixes P :: \"'a \<Rightarrow> o\""} 是声明谓词变量的唯一正解——
   不能写 @{verbatim "fixes P :: \"i \<Rightarrow> o\""}（@{verbatim "i"} 不存在）。
7. @{verbatim "spec"} 是全称消去到**任意项**（不是特定变量），
   @{verbatim "erule allE"} 时记得指定实例。
8. FOL 的 @{verbatim "\<longleftrightarrow>"} 写作 @{verbatim "\<longleftrightarrow>"}（与 HOL 相同），
   但内部定义不同（@{verbatim "iff_def"} vs HOL 的 @{verbatim "iff_def"}）。
9. @{verbatim "value"} 不可用（代码生成器没配 FOL）。
10. @{verbatim "True"} 在 FOL 里是定义（@{verbatim "False \<longrightarrow> False"}），
    不是原始常量——@{verbatim "TrueI"} 是它的引入规则。\<close>

thm imp_reflexive mp_demo conj_comm disj_elim_demo
  not_intro_demo ccontr_demo iff_intro_demo
  excluded_middle dn_dn_lem
  all_intro_demo spec_demo all_implies
  ex_intro_demo ex_elim_demo ex_renaming
  ex1_intro_demo refl_demo sym_demo trans_demo subst_demo
  conj_comm_simp blast_quantifier iprover_demo
  chain_demo

ML \<open>writeln "==== 47 结束 ===="\<close>

end
