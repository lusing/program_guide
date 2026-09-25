theory S20_refine_chain
  imports Main
begin

section \<open>20.1 一条链，四个层次\<close>

text \<open>
  把前面几章拼起来，seL4 的正确性是一条\emph{精化链}：

  \begin{enumerate}
    \item \textbf{抽象规范 A}：@{verbatim "l4v/spec/abstract/"}，写"内核做什么"；
    \item \textbf{设计规范 H}：@{verbatim "l4v/spec/design/"}，由 Haskell 模型生成，
          数据结构与 C 同形（第 18 章的 @{verbatim "corres"}）；
    \item \textbf{C 规范}：@{verbatim "l4v/spec/cspec/"}，由 C 代码自动翻译而来
          （第 19 章的 @{verbatim "ccorres"}）；
    \item \textbf{机器码}：@{verbatim "l4v/proof/asmrefine/"}，把 C 语义导出成
          SydTV-GL 语言，与 HOL4 反编译器产出的二进制表示比对。
  \end{enumerate}

  链上每一环都给出"上一层做的事，下一层也做了"的定理。
  这一章不写新规范，只把\emph{给出这种定理的那套代数}搬进来——
  它就是 @{verbatim "l4v/lib/Simulation.thy"}，
  一个只 @{verbatim "imports Main"} 的独立 theory，全文 321 行，
  整条 seL4 链的每一环都在用它。
\<close>

ML \<open>writeln "==== 20 开始 ===="\<close>

subsection \<open>20.2 "层"是什么：@{text "data_type"}\<close>

text \<open>
  一层不是"一个函数"，而是三个函数（@{verbatim "l4v/lib/Simulation.thy"} 第 39--42 行）：
  私有状态 @{typ "'a"}、可观察状态 @{typ "'b"}、操作 @{typ "'j"}。
  @{verbatim "Init"} 把可观察初值展开成一\emph{集合}的私有初值
  （"实现可以任选内部表示"），
  @{verbatim "Step"} 是一个\emph{关系}而不是函数（"实现可以任选细节"），
  @{verbatim "Fin"} 把私有状态投影回可观察状态。
\<close>

record ('a, 'b, 'j) data_type =
  Init :: "'b \<Rightarrow> 'a set"
  Fin :: "'a \<Rightarrow> 'b"
  Step :: "'j \<Rightarrow> ('a \<times> 'a) set"

text \<open>
  一段操作序列的执行 = 反复施加关系（@{verbatim "steps"} 第 48--50 行），
  跑一整层 = 初始化、执行、投影回去（@{verbatim "execution"} 第 58--60 行）。
\<close>

definition steps :: "('j \<Rightarrow> ('a \<times> 'a) set) \<Rightarrow> 'a set \<Rightarrow> 'j list \<Rightarrow> 'a set" where
  "steps \<delta> \<equiv> foldl (\<lambda>S j. \<delta> j `` S)"

definition execution :: "('a, 'b, 'j) data_type \<Rightarrow> 'b \<Rightarrow> 'j list \<Rightarrow> 'b set" where
  "execution A s js \<equiv> Fin A ` steps (Step A) (Init A s) js"

lemma steps_Nil [simp]: "steps \<delta> S [] = S"
  by (simp add: steps_def)

lemma steps_Cons [simp]: "steps \<delta> S (j # js) = steps \<delta> (\<delta> j `` S) js"
  by (simp add: steps_def)

text \<open>
  Hoare 三元组（@{verbatim "hoare_triple"}）和精化（@{verbatim "refines"}）
  都是\emph{对整个} @{verbatim "execution"} 集合说的，
  分别在第 67--70 行和第 77--80 行：
\<close>

definition hoare_triple :: "('a, 'b, 'j) data_type \<Rightarrow> 'b set \<Rightarrow> 'j list \<Rightarrow> 'b set \<Rightarrow> bool" where
  "hoare_triple A P js Q \<equiv> \<forall>s \<in> P. execution A s js \<subseteq> Q"

definition refines :: "('c, 'b, 'j) data_type \<Rightarrow> ('a, 'b, 'j) data_type \<Rightarrow> bool"
  (infix "\<sqsubseteq>" 60) where
  "C \<sqsubseteq> A \<equiv> \<forall>js s. execution C s js \<subseteq> execution A s js"

lemma refinement_refl [simp]: "A \<sqsubseteq> A"
  by (simp add: refines_def)

lemma refinement_trans [trans]:
  "\<lbrakk>C \<sqsubseteq> B; B \<sqsubseteq> A\<rbrakk> \<Longrightarrow> C \<sqsubseteq> A"
  by (simp add: refines_def) blast

text \<open>
  这两条（第 274--280 行）就是"链"的代数依据：
  @{verbatim "refinement_trans"} 挂着 @{text "[trans]"}，
  所以 @{text "C \<sqsubseteq> B"} 和 @{text "B \<sqsubseteq> A"} 会自动串成
  @{text "C \<sqsubseteq> A"}。真实链上那一步写在
  @{verbatim "l4v/proof/crefine/ARM/Refine_C.thy"} 第 1003--1005 行。
\<close>

ML \<open>
  writeln (@{make_string} @{thm refinement_trans});
  writeln (@{make_string} @{thm refinement_refl})
\<close>

subsection \<open>20.3 精化为什么等价于"性质搬得过去"\<close>

text \<open>
  @{text "C \<sqsubseteq> A"} 看着像"具体行为的集合更小"，
  但它同时\emph{就是}"抽象层证过的每条 Hoare 三元组在具体层也成立"
  （@{verbatim "hoare_triple_refinement"}，第 86--88 行）。
  这不是两个碰巧等价的定义，是一条等式，
  所以"搬性质"这件事不需要任何额外假设。
\<close>

lemma hoare_triple_refinement:
  "C \<sqsubseteq> A = (\<forall>P Q js. hoare_triple A P js Q \<longrightarrow> hoare_triple C P js Q)"
  by (simp add: refines_def hoare_triple_def) blast

subsection \<open>20.4 逐条证明太贵：前向模拟\<close>

text \<open>
  @{text "\<sqsubseteq>"} 是全称量词套在\emph{所有}操作序列上的，
  没法归约到"一次调用"的粒度。真实证明走更弱的
  \emph{前向模拟}（第 92--112 行）：
  找一个私有状态之间的关系 @{text R}，证明三件事——
  初值可相关、单步可对齐、终值投影相同。
\<close>

definition rel_semi :: "('a \<times> 'b) set \<Rightarrow> ('b \<times> 'c) set \<Rightarrow> ('a \<times> 'c) set"
  (infixl ";;;" 65) where
  "A ;;; B \<equiv> A O B"

definition fw_sim :: "('a \<times> 'c) set \<Rightarrow> ('c, 'b, 'j) data_type \<Rightarrow> ('a, 'b, 'j) data_type \<Rightarrow> bool" where
  "fw_sim R C A \<equiv> (\<forall>s. Init C s \<subseteq> R `` Init A s) \<and>
                  (\<forall>j. R ;;; Step C j \<subseteq> Step A j ;;; R) \<and>
                  (\<forall>s s'. (s, s') \<in> R \<longrightarrow> Fin C s' = Fin A s)"

definition fw_simulates :: "('c, 'b, 'j) data_type \<Rightarrow> ('a, 'b, 'j) data_type \<Rightarrow> bool"
  (infixl "\<sqsubseteq>\<^sub>F" 50) where
  "C \<sqsubseteq>\<^sub>F A \<equiv> \<exists>R. fw_sim R C A"

text \<open>
  中间那条 @{text "R ;;; Step C j \<subseteq> Step A j ;;; R"} 就是交换图：
  先跨到具体层再走一步，等于先在抽象层走一步再跨回来。
  对它归纳一次操作序列，就得到全链唯一真正"搬运行为"的引理
  （第 114--138 行，证明脚本逐字照抄）。
\<close>

lemma fw_sim_steps:
  assumes steps: "t' \<in> steps (Step C) S' js" "S' \<subseteq> R `` S"
  assumes sim: "fw_sim R C A"
  shows "\<exists>t \<in> steps (Step A) S js. (t, t') \<in> R" using steps
proof (induct js arbitrary: S' S)
  case Nil
  thus ?case by (simp add: steps_def) blast
next
  case (Cons j js)
  hence "t' \<in> steps (Step C) (Step C j `` S') js"
    by (clarsimp simp: steps_def)
  moreover {
    from Cons.prems
    have "S' \<subseteq> R `` S" by simp
    moreover
    from sim
    have "R ;;; Step C j \<subseteq> Step A j ;;; R" by (simp add: fw_sim_def)
    ultimately
    have "Step C j `` S' \<subseteq> R `` (Step A j `` S)"
      by (simp add: rel_semi_def) blast
  }
  ultimately
  show ?case using Cons.hyps
    by (auto simp: steps_def)
qed

lemma sim_imp_refines:
  "C \<sqsubseteq>\<^sub>F A \<Longrightarrow> C \<sqsubseteq> A"
  apply (clarsimp simp: refines_def execution_def fw_simulates_def)
  apply (rename_tac t)
  apply (drule fw_sim_steps)
    prefer 2
    apply assumption
   apply (simp add: fw_sim_def)
   apply blast
  apply clarsimp
  apply (erule rev_image_eqI)
  apply (simp add: fw_sim_def)
  done

text \<open>
  @{verbatim "sim_imp_refines"} 只有一个前提，
  但 seL4 主链那条 @{verbatim "refinement"} 的证明有 6 行
  （@{verbatim "l4v/proof/refine/Refine.thy"} 第 842--849 行），
  因为它还要夹进"不变式"这一层。
\<close>

subsection \<open>20.5 不变式：交换图走不通的时候\<close>

text \<open>
  前向模拟要求交换图对\emph{所有}私有状态成立。
  真实内核里这是假的：那些"初始化之后再也到不了"的内部状态
  会让图对不上，而它们本来就不影响任何行为。
  所以第 161--205 行给出带不变式的版本：
  证明单步那条时\emph{允许假设}两端都在不变式里，
  不变式本身单独证。
\<close>

definition invariant_holds :: "('a, 'b, 'j) data_type \<Rightarrow> 'a set \<Rightarrow> bool"
  (infix "\<Turnstile>" 60) where
  "D \<Turnstile> I \<equiv> (\<forall>s. Init D s \<subseteq> I) \<and> (\<forall>j. Step D j `` I \<subseteq> I)"

lemma invariantI:
  "\<lbrakk>\<forall>s. Init D s \<subseteq> I; \<forall>j. Step D j `` I \<subseteq> I\<rbrakk> \<Longrightarrow> D \<Turnstile> I"
  by (simp add: invariant_holds_def)

definition LI :: "('a, 'b, 'j) data_type \<Rightarrow> ('c, 'b, 'j) data_type \<Rightarrow> ('a \<times> 'c) set \<Rightarrow> ('a \<times> 'c) set \<Rightarrow> bool" where
  "LI A C R I \<equiv> (\<forall>s. Init C s \<subseteq> R `` Init A s) \<and>
                (\<forall>j. (R \<inter> I) ;;; Step C j \<subseteq> Step A j ;;; R) \<and>
                (\<forall>s s'. (s, s') \<in> R \<inter> I \<longrightarrow> Fin C s' = Fin A s)"

text \<open>
  下面这条 @{verbatim "LI_fw_sim"}（第 208--248 行，逐字照抄）
  是整套机制真正"机械"的部分：把两条不变式用
  "恒等关系切片" @{text "(UNIV \<times> I\<^sub>a) \<inter> Id"} 压进模拟关系里，
  靠一串关系复合的代数变形走完。
\<close>

lemma LI_fw_sim:
  assumes ia: "A \<Turnstile> I\<^sub>a" and ic: "C \<Turnstile> I\<^sub>c" and li: "LI A C r (I\<^sub>a \<times> I\<^sub>c)"
  shows "fw_sim (r \<inter> I\<^sub>a \<times> I\<^sub>c) C A"
proof -
  from li have
    init: "\<forall>s. Init C s \<subseteq> r `` Init A s" and
    step: "\<forall>j. (r \<inter> (I\<^sub>a \<times> I\<^sub>c)) ;;; Step C j \<subseteq> Step A j ;;; r" and
    fin: "(\<forall>s s'. (s, s') \<in> r \<inter> (I\<^sub>a \<times> I\<^sub>c) \<longrightarrow> Fin C s' = Fin A s)"
    by (auto simp: LI_def)
  from ia have "\<forall>s. (r \<inter> (UNIV \<times> I\<^sub>c)) `` Init A s = (r \<inter> (I\<^sub>a \<times> I\<^sub>c)) `` Init A s"
    by (simp add: invariant_holds_def, blast)
  moreover from init ic have "\<forall>s. Init C s \<subseteq> (r \<inter> (UNIV \<times> I\<^sub>c)) `` Init A s"
    by (simp add: invariant_holds_def, blast)
  ultimately have initI: "\<forall>s. Init C s \<subseteq> (r \<inter> (I\<^sub>a \<times> I\<^sub>c)) `` Init A s" by simp
  moreover {
    fix j
    from step have "r \<inter> (I\<^sub>a \<times> I\<^sub>c) ;;; Step C j \<subseteq> Step A j ;;; r"..
    also
    have "r \<inter> (I\<^sub>a \<times> I\<^sub>c) = ((UNIV \<times> I\<^sub>a) \<inter> Id) ;;; r ;;; ((I\<^sub>c \<times> UNIV) \<inter> Id)"
      (is "_ = ?I\<^sub>a ;;; r ;;; ?I\<^sub>c")
      by (simp add: rel_semi_def, blast)
    finally
    have "?I\<^sub>a ;;; r ;;; ?I\<^sub>c ;;; Step C j \<subseteq> ?I\<^sub>a ;;; Step A j ;;; r"
      by (simp add: rel_semi_def, blast)
    also
    from ia have "\<dots> \<subseteq> Step A j ;;; ?I\<^sub>a ;;; r"
      by (simp add: invariant_holds_def rel_semi_def, blast)
    finally
    have "?I\<^sub>a ;;;  r ;;; ?I\<^sub>c ;;; Step C j;;; ?I\<^sub>c \<subseteq>  Step A j ;;; ?I\<^sub>a ;;; r ;;; ?I\<^sub>c"
      by (simp add: rel_semi_def, blast)
    also
    from ic
    have "?I\<^sub>a ;;; r ;;; ?I\<^sub>c ;;; Step C j;;; ?I\<^sub>c =  ?I\<^sub>a ;;; r ;;; ?I\<^sub>c ;;; Step C j"
      by (simp add: invariant_holds_def rel_semi_def, blast)
    finally
    have "r \<inter> (I\<^sub>a \<times> I\<^sub>c) ;;; Step C j \<subseteq> Step A j ;;; r \<inter> (I\<^sub>a \<times> I\<^sub>c)"
      by (simp add: rel_semi_def, blast)
  }
  ultimately show "fw_sim (r \<inter> I\<^sub>a \<times> I\<^sub>c) C A" using fin
    by (simp add: fw_sim_def)
qed

lemma L_invariantI:
  assumes "A \<Turnstile> I\<^sub>a" and "C \<Turnstile> I\<^sub>c" and "LI A C r (I\<^sub>a \<times> I\<^sub>c)"
  shows "C \<sqsubseteq>\<^sub>F A"
  using assms
  by (simp add: fw_simulates_def, rule_tac x="r \<inter> I\<^sub>a \<times> I\<^sub>c" in exI,
      simp add: LI_fw_sim)

text \<open>
  @{text LI} 与 @{text fw_sim} 的关系很直白：不变式取 @{text UNIV}
  就是同一个东西（第 260--261 行，一行 @{text "simp"}）。
  这条等式的用处是\emph{反方向}读：
  凡是 @{text "LI A C R UNIV"} 证不出来的，@{text "fw_sim R C A"} 也证不出来。
\<close>

lemma fw_sim_eq_LI: "fw_sim r C A = LI A C r UNIV"
  by (simp add: fw_sim_def LI_def)

lemma weaken_LI:
  assumes LI: "LI A C R I'" and weaker: "I \<subseteq> I'"
  shows "LI A C R I"
  using LI weaker
  by (auto simp: LI_def rel_semi_def relcomp_def) blast

text \<open>
  @{text L_invariantI} 里 @{text "r \<inter> I\<^sub>a \<times> I\<^sub>c"} 这一步
  （把不变式\emph{切进}模拟关系）是整套机制里最不显眼、
  却最要紧的一处：真实链上它就是 @{verbatim "fw_sim_A_H"}
  （@{verbatim "Refine.thy"} 第 769--771 行）
  和两条 @{verbatim "kernel_invariant"} 的合流点。
\<close>

subsection \<open>20.6 三层链：跑一遍\<close>

text \<open>
  现在造三层 @{text data_type}，把上面的规则全用上。
  可观察状态都是 @{typ nat}，操作 @{typ nat} 表示"加几"：
  \begin{itemize}
    \item @{text ADT_A}：抽象层，一个计数器，一步加完；
    \item @{text ADT_M}：设计层，多加一个"永远为 0 的备用字段"，
          模拟 H 层那种"跟 C 同形但语义不变"的改写；
    \item @{text ADT_C}：具体层，值拆成两半存放，
          并且\emph{多写了一条只有到不了的状态才会触发的坏行为}。
  \end{itemize}
\<close>

definition a_step :: "nat \<Rightarrow> (nat \<times> nat) set" where
  "a_step k = {(p, p'). p' = p + k}"

definition m_step :: "nat \<Rightarrow> ((nat \<times> nat) \<times> (nat \<times> nat)) set" where
  "m_step k = {(p, p'). p' = (fst p + k, snd p)}"

definition c_step :: "nat \<Rightarrow> ((nat \<times> nat) \<times> (nat \<times> nat)) set" where
  "c_step k = {(p, p'). p' = (fst p + k, snd p) \<or> (snd p > 0 \<and> p' = (0, 0))}"

definition ADT_A :: "(nat, nat, nat) data_type" where
  "ADT_A \<equiv> \<lparr> Init = (\<lambda>s. {s}), Fin = (\<lambda>n. n), Step = a_step \<rparr>"

definition ADT_M :: "((nat \<times> nat), nat, nat) data_type" where
  "ADT_M \<equiv> \<lparr> Init = (\<lambda>s. {(s, 0)}), Fin = fst, Step = m_step \<rparr>"

definition ADT_C :: "((nat \<times> nat), nat, nat) data_type" where
  "ADT_C \<equiv> \<lparr> Init = (\<lambda>s. {(s, 0)}), Fin = (\<lambda>p. fst p + snd p), Step = c_step \<rparr>"

text \<open>
  下面这九条就是"层的说明书"，证明里所有 @{text auto} 都只在它们之上运行。
  写成 @{text "(p, p') \<in> Step D k"} 这种"自由变量可直接匹配"的形状，
  而不是把 @{text "Step"} 当函数用，是 l4v 证明脚本里最常见的一个小技巧：
  @{text "\<delta> j `` S"} 展开后先出现的是一对\emph{自由}变量，
  只有 iff 形式的成员引理喂得进 simplifier。
\<close>

lemma A_Init [simp]: "Init ADT_A s = {s}"
  by (simp add: ADT_A_def)

lemma A_Fin [simp]: "Fin ADT_A n = n"
  by (simp add: ADT_A_def)

lemma A_Step [simp]: "(p, p') \<in> Step ADT_A k \<longleftrightarrow> p' = p + k"
  by (simp add: ADT_A_def a_step_def)

lemma M_Init [simp]: "Init ADT_M s = {(s, 0)}"
  by (simp add: ADT_M_def)

lemma M_Fin [simp]: "Fin ADT_M p = fst p"
  by (simp add: ADT_M_def)

lemma M_Step [simp]: "(p, p') \<in> Step ADT_M k \<longleftrightarrow> p' = (fst p + k, snd p)"
  by (simp add: ADT_M_def m_step_def)

lemma C_Init [simp]: "Init ADT_C s = {(s, 0)}"
  by (simp add: ADT_C_def)

lemma C_Fin [simp]: "Fin ADT_C p = fst p + snd p"
  by (simp add: ADT_C_def)

lemma C_Step [simp]:
  "(p, p') \<in> Step ADT_C k \<longleftrightarrow> p' = (fst p + k, snd p) \<or> (snd p > 0 \<and> p' = (0, 0))"
  by (simp add: ADT_C_def c_step_def)

text \<open>
  \medskip\noindent{\bf H 环：@{text "ADT_M \<sqsubseteq>\<^sub>F ADT_A"}，不用不变式。}
  模拟关系丢掉备用字段即可，三条义务都直接成立。
\<close>

definition R_MA :: "(nat \<times> (nat \<times> nat)) set" where
  "R_MA \<equiv> {(v, p). v = fst p}"

lemma R_MA_iff [simp]: "(v, p) \<in> R_MA \<longleftrightarrow> v = fst p"
  by (simp add: R_MA_def)

lemma fw_sim_MA: "fw_sim R_MA ADT_M ADT_A"
  by (auto simp: fw_sim_def rel_semi_def R_MA_def)

lemma refinement_H: "ADT_M \<sqsubseteq>\<^sub>F ADT_A"
  unfolding fw_simulates_def by (rule exI[of _ R_MA], rule fw_sim_MA)

text \<open>
  \medskip\noindent{\bf C 环：@{text "ADT_C \<sqsubseteq>\<^sub>F ADT_M"}，必须用不变式。}
  两层的备用字段都从 0 开始、从不被改动，这就是不变式说的东西。
\<close>

definition inv_M :: "(nat \<times> nat) set" where "inv_M \<equiv> {p. snd p = 0}"

definition inv_C :: "(nat \<times> nat) set" where "inv_C \<equiv> {p. snd p = 0}"

lemma invariant_M: "ADT_M \<Turnstile> inv_M"
  by (auto simp: invariant_holds_def inv_M_def)

lemma invariant_C: "ADT_C \<Turnstile> inv_C"
  by (auto simp: invariant_holds_def inv_C_def)

text \<open>
  模拟关系：抽象层的值等于具体层两半之和。
\<close>

definition R_CM :: "((nat \<times> nat) \<times> (nat \<times> nat)) set" where
  "R_CM \<equiv> {(p, p'). fst p = fst p' + snd p'}"

lemma R_CM_iff [simp]: "(p, p') \<in> R_CM \<longleftrightarrow> fst p = fst p' + snd p'"
  by (simp add: R_CM_def)

lemma LI_CM: "LI ADT_M ADT_C R_CM (inv_M \<times> inv_C)"
  by (auto simp: LI_def rel_semi_def inv_M_def inv_C_def)

text \<open>
  于是 C 环与 seL4 主链同形——下面这四行和
  @{verbatim "Refine.thy"} 第 845--849 行的 @{verbatim "rule"} 序列一一对应：
\<close>

lemma refinement_C: "ADT_C \<sqsubseteq>\<^sub>F ADT_M"
  apply (rule L_invariantI)
    apply (rule invariant_M)
   apply (rule invariant_C)
  apply (rule LI_CM)
  done

text \<open>
  两条 @{text "\<sqsubseteq>\<^sub>F"} 先各换成一条 @{text "\<sqsubseteq>"}，再合成——
  这一步的形状和真实项目完全一样：
  @{verbatim "refinement"}（H ⊑ A）、@{verbatim "refinement2"}（C ⊑ H）、
  最后 @{verbatim "seL4_refinement"}（C ⊑ A）。
\<close>

theorem refinement_H_A: "ADT_M \<sqsubseteq> ADT_A"
  by (rule sim_imp_refines[OF refinement_H])

theorem refinement_C_M: "ADT_C \<sqsubseteq> ADT_M"
  by (rule sim_imp_refines[OF refinement_C])

theorem chain: "ADT_C \<sqsubseteq> ADT_A"
  by (rule refinement_trans[OF refinement_C_M refinement_H_A])

ML \<open>
  writeln (@{make_string} @{thm refinement_C_M});
  writeln (@{make_string} @{thm refinement_H_A});
  writeln (@{make_string} @{thm chain});
  writeln (@{make_string} @{thm sim_imp_refines})
\<close>

text \<open>
  真实链上 @{text refinement_C} 那一环是 @{verbatim "refinement2"}
  （@{text "ADT_C \<sqsubseteq> ADT_H"}，
  @{verbatim "l4v/proof/crefine/ARM/Refine_C.thy"} 第 993--995 行），
  最上一条 @{text chain} 是 @{verbatim "seL4_refinement"}
  （@{text "ADT_C uop \<sqsubseteq> ADT_A uop"}），
  它的证明体只有 @{verbatim "blast"}，
  因为两条挂 @{text "[trans]"} 的引理已经把链条备好了。
\<close>

subsection \<open>20.7 链条怎么接上：模拟关系可以复合\<close>

text \<open>
  上一节把两环各自证成 @{text "\<sqsubseteq>\<^sub>F"}，再各换成 @{text "\<sqsubseteq>"} 后复合。
  其实 @{text "\<sqsubseteq>\<^sub>F"} 这一层自己也是可传的，靠的是
  \emph{模拟关系的复合} @{verbatim "fw_sim_trans"}
  （@{verbatim "l4v/lib/Simulation.thy"} 第 312--315 行）：
\<close>

lemma fw_sim_trans:
  "\<lbrakk>fw_sim Q C B; fw_sim R B A\<rbrakk> \<Longrightarrow> fw_sim (R O Q) C A"
  by (auto simp: fw_sim_def rel_semi_def; blast)

text \<open>
  结论里的关系是 @{text "R O Q"}，不是 @{text "Q O R"}——
  谁在前取决于谁是中间层。包一层存在量词就是
  @{verbatim "fw_simulates_trans"}（同一文件第 316--319 行）：
\<close>

lemma fw_simulates_trans:
  "\<lbrakk>C \<sqsubseteq>\<^sub>F B; B \<sqsubseteq>\<^sub>F A\<rbrakk> \<Longrightarrow> C \<sqsubseteq>\<^sub>F A"
  apply (auto simp: fw_simulates_def dest: fw_sim_trans)
  done

text \<open>
  真实主链用的是 @{text "[trans]"} 那一条
  （@{verbatim "refinement_trans"}），因为每一环的
  @{verbatim "fw_simulates"} 都带着自己的不变式切片，
  复合出来的关系长什么样并不重要。
  在这里我们反倒可以把中间关系\emph{算出来}：
  先把 C 环换成带切片的形式模拟，再复合。
\<close>

lemma fw_sim_CM_sliced: "fw_sim (R_CM \<inter> inv_M \<times> inv_C) ADT_C ADT_M"
  by (rule LI_fw_sim [OF invariant_M invariant_C LI_CM])

lemma fw_sim_CA: "fw_sim (R_MA O (R_CM \<inter> inv_M \<times> inv_C)) ADT_C ADT_A"
  by (rule fw_sim_trans [OF fw_sim_CM_sliced fw_sim_MA])

theorem chain_F: "ADT_C \<sqsubseteq>\<^sub>F ADT_A"
  unfolding fw_simulates_def
  by (rule exI [of _ "R_MA O (R_CM \<inter> inv_M \<times> inv_C)"], rule fw_sim_CA)

text \<open>
  把中间量消掉看这条复合关系到底是什么。
  左边是"@{verbatim "R_MA"} 复合 @{verbatim "R_CM"} 的不变式切片"，
  右边只看第一个分量：
\<close>

lemma R_CA_simp:
  "(v, p) \<in> R_MA O (R_CM \<inter> inv_M \<times> inv_C) \<longleftrightarrow> v = fst p \<and> snd p = 0"
  by (auto simp: inv_M_def inv_C_def R_CM_def R_MA_def)

text \<open>
  中间层的备用字段在复合时被消去了：@{text R_CM} 要求
  @{text "fst p' = fst p + snd p'"}，切片又把 @{text "snd p'"} 钉成 0，
  于是 @{text "v = fst p"}。这正是"证一次、三层都成立"的机制。
\<close>

text \<open>
  还有一类东西也沿着链搬：不变式本身
  （@{verbatim "fw_inv_transport"}，
  @{verbatim "l4v/lib/Simulation.thy"} 第 283--300 行）：
  抽象层不变式 @{text "?I\<^sub>a"}、具体层不变式 @{text "?I\<^sub>c"} 加一条
  @{text LI}，就得到"具体层满足那个由关系像刻出来的集合"。
  真实的 @{verbatim "full_invs"} 与 @{verbatim "full_invs'"}
  （@{verbatim "l4v/proof/refine/Refine.thy"} 第 769--771 行的参数）
  走的就是这条路。
\<close>

ML \<open>
  writeln (@{make_string} @{thm fw_sim_trans});
  writeln (@{make_string} @{thm chain_F});
  writeln (@{make_string} @{thm R_CA_simp})
\<close>

subsection \<open>20.8 不变式不是装饰：一个反例\<close>

text \<open>
  @{text ADT_C} 里那句"备用字段非 0 就跳到 @{text "(0, 0)"}"
  看着像故意找茬，但它正是内核里"这段代码到不了"那类分支的抽象。
  下面证明：\emph{不带不变式的前向模拟对这条链根本证不出来}。
  按 @{text fw_sim_eq_LI}，这等价于说 @{text LI} 取 @{text UNIV} 失败。
\<close>

lemma not_fw_sim_CM: "\<not> fw_sim R_CM ADT_C ADT_M"
proof (rule notI)
  assume sim: "fw_sim R_CM ADT_C ADT_M"
  then have sub: "R_CM ;;; Step ADT_C 0 \<subseteq> Step ADT_M 0 ;;; R_CM"
    by (auto simp: fw_sim_def)
  have rc: "((1, 0), (0, 1)) \<in> R_CM" by simp
  have st: "((0, 1), (0, 0)) \<in> Step ADT_C 0" by simp
  have "((1, 0), (0, 0)) \<in> R_CM ;;; Step ADT_C 0"
    unfolding rel_semi_def by (rule relcompI [OF rc st])
  then have in_right: "((1, 0), (0, 0)) \<in> Step ADT_M 0 ;;; R_CM" using sub by blast
  have notin: "((1, 0), (0, 0)) \<notin> Step ADT_M 0 ;;; R_CM"
    by (auto simp: rel_semi_def)
  from notin in_right show False by contradiction
qed

lemma not_LI_CM_univ: "\<not> LI ADT_M ADT_C R_CM UNIV"
  using not_fw_sim_CM by (simp add: fw_sim_eq_LI)

text \<open>
  坏行为确实\emph{进不了}任何执行：不变式把它挡住了。
  这条事实是"@{text "\<Turnstile>"} 就是可达性"的直观说明，
  也正是 @{text L_invariantI} 要把不变式切进模拟关系的原因。
\<close>

lemma step_on_inv: "snd p = 0 \<Longrightarrow> (p, p') \<in> Step ADT_C k \<Longrightarrow> p' = (fst p + k, 0)"
  by auto

lemma steps_C: "steps (Step ADT_C) {(s, 0)} js = {(s + sum_list js, 0)}"
proof (induct js arbitrary: s)
  case Nil show ?case by simp
next
  case (Cons k js)
  then have "Step ADT_C k `` {(s, 0)} = {(s + k, 0)}" by auto
  with Cons.hyps[of "s + k"] show ?case by (simp add: steps_def ac_simps)
qed

text \<open>
  于是三层的行为集合完全相同——这是链能成立的实质，
  而"交换图只在可达状态上成立"是它\emph{证得出来}的形式。
\<close>

lemma execution_A: "execution ADT_A s js = {s + sum_list js}"
proof -
  have "steps (Step ADT_A) {s} js = {s + sum_list js}"
  proof (induct js arbitrary: s)
    case Nil show ?case by simp
  next
    case (Cons k js)
    then have "Step ADT_A k `` {s} = {s + k}" by auto
    with Cons.hyps[of "s + k"] show ?case by (simp add: steps_def ac_simps)
  qed
  thus ?thesis by (simp add: execution_def)
qed

lemma execution_C: "execution ADT_C s js = {s + sum_list js}"
  using steps_C[of s js] by (simp add: execution_def)

subsection \<open>20.9 性质的搬运：证一次，三层都成立\<close>

text \<open>
  链的终点不是"行为一致"这种玄学，而是一件很具体的事：
  在抽象层证一条 Hoare 三元组，@{text hoare_triple_refinement}
  把它换成"具体层也成立"。下面这条就是全流程走一遍。
\<close>

lemma hoare_A_result: "hoare_triple ADT_A {s} js {t. t = s + sum_list js}"
  by (simp add: hoare_triple_def execution_A)

theorem hoare_C_result: "hoare_triple ADT_C {s} js {t. t = s + sum_list js}"
  using chain hoare_triple_refinement hoare_A_result by blast

text \<open>
  @{text hoare_C_result} 里没有一次真正的归纳：
  归纳在 @{text hoare_A_result}，链条在 @{text chain}。
  真实项目里"抽象层证性质"是 @{verbatim "l4v/spec/abstract/"}
  那一批 @{verbatim "_AI"} 引理，"链"是 @{verbatim "Simulation.thy"}
  加 @{verbatim "Refine.thy"}。第 21--24 章的安全性质就落在这条通道上。
\<close>

ML \<open>
  writeln (@{make_string} @{thm hoare_triple_refinement});
  writeln (@{make_string} @{thm not_fw_sim_CM});
  writeln (@{make_string} @{thm fw_sim_eq_LI});
  writeln (@{make_string} @{thm steps_C})
\<close>

subsection \<open>20.10 假设清单：读证明之前先看它\<close>

text \<open>
  @{verbatim "Simulation.thy"} 只保证"抽象层到 C 语义"这一段。
  l4v 的每条定理都带着假设，真正读完整个仓库的人会告诉你：
  最有价值的不是定理本身，而是这份假设清单。
  @{verbatim "seL4/CAVEATS.md"} 第 64--67 行写得很明确——
  证明覆盖 C 代码的\emph{功能行为}，不覆盖机器码、编译器、链接器、
  启动代码、缓存与 TLB；编译器/链接器那一项可以用
  针对 AArch32 或 RISC-V 的二进制验证工具链补上。
  机器码那一环（@{verbatim "l4v/proof/asmrefine/README.md"} 第 10--17 行）
  的真实形状是：把 C 语义导出成 SydTV-GL，
  HOL4 反编译器产出二进制的 SydTV-GL 表示，
  两边交给外部工具 SydTV 比对（PLDI'13）。
\<close>

datatype assumption = HardwareModel | CompilerLinker | BootCode | ConfigSet | Decompiler

definition verified_assumptions :: "assumption set" where
  "verified_assumptions \<equiv> {ConfigSet}"

definition unverified_assumptions :: "assumption set" where
  "unverified_assumptions \<equiv> {HardwareModel, CompilerLinker, BootCode, Decompiler}"

lemma decompiler_is_external: "Decompiler \<in> unverified_assumptions"
  by (simp add: unverified_assumptions_def)

lemma config_is_checked: "ConfigSet \<in> verified_assumptions"
  by (simp add: verified_assumptions_def)

lemma assumptions_partition:
  "verified_assumptions \<inter> unverified_assumptions = {}"
  by (auto simp: verified_assumptions_def unverified_assumptions_def)

text \<open>
  @{verbatim "ConfigSet"} 进"已验证"这一栏，
  是因为只有 @{verbatim "*_verified.cmake"} 里那一批配置组合
  真的跑过一遍证明（见 @{verbatim "seL4/configs/"}），换配置不在链上。
  @{verbatim "KernelInit_A"}（@{verbatim "l4v/spec/abstract/KernelInit_A.thy"}）
  之后才是被证明的状态；反编译器是一份\emph{外部}输入，
  它的正确性不在 Isabelle 里——这条最常被人忘掉。
\<close>

ML \<open>writeln "==== 20 结束 ===="\<close>

end
