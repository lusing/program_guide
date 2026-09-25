theory S22_infoflow
  imports Main
begin

section \<open>22.1 机密性：非干扰与无泄漏\<close>

text \<open>
  完整性说"不能乱改"，机密性说"不能偷看"。seL4 的机密性证明在
  @{verbatim "l4v/proof/infoflow/"}：那份目录里的 @{verbatim "README.md"}
  第一句就写明，信息流安全是用\emph{非传递的}（intransitive）非干扰定义的。
  更要紧的是 @{verbatim "Noninterference.thy"} 第 28 行的自述——
  文件名里那个 Noninterference 恰恰是\emph{没有}被证明的性质，
  真正证到的是 Nonleakage。本章把这套层次
  （@{verbatim "sources"}/@{verbatim "ipurge"}/@{verbatim "Nonleakage_gen"}/
  @{verbatim "confidentiality_u"}/@{verbatim "integrity_u"}）
  在一个可判定的小模型里逐条复现，包括那条"Noninterference 不成立"。
\<close>

ML \<open>writeln "==== 22 开始 ===="\<close>

type_synonym obj_ref = nat

datatype level = Low | High

record kstate =
  ks_msgs :: "obj_ref \<Rightarrow> nat"
  ks_cur  :: obj_ref

subsection \<open>22.2 擦除：把高安全级的东西换成默认值\<close>

definition level_of :: "obj_ref \<Rightarrow> level" where
  "level_of p \<equiv> if p < 10 then Low else High"

definition erase_high :: "kstate \<Rightarrow> kstate" where
  "erase_high s \<equiv> s\<lparr> ks_msgs := (\<lambda>p. if level_of p = High then 0 else ks_msgs s p) \<rparr>"

lemma erase_touches_only_high:
  "level_of p = Low \<Longrightarrow> ks_msgs (erase_high s) p = ks_msgs s p"
  by (simp add: erase_high_def)

lemma erase_zeroes_high:
  "level_of p = High \<Longrightarrow> ks_msgs (erase_high s) p = 0"
  by (simp add: erase_high_def)

text \<open>
  这里要证的是\emph{记录}相等，不是函数相等，所以 @{verbatim "rule ext"} 不好使：
  得先把记录拆开再比较两个字段。
\<close>

lemma erase_is_idempotent: "erase_high (erase_high s) = erase_high s"
  by (cases s; simp add: erase_high_def fun_eq_iff)

subsection \<open>22.3 域：分区，外加一个"调度器分区"\<close>

text \<open>
  真实定义（@{verbatim "Noninterference.thy"} 第 36 行）是
  @{verbatim "datatype 'a partition = Partition 'a | PSched"}：
  观察者要么是某个分区，要么就是调度器本身。
  调度器必须单列，因为它是\emph{人人可见}的信道——
  这也正是 @{verbatim "integrity_u"} 后来证不出来的地方。
\<close>

datatype dom2 = LowD | HighD | SchedD

definition dom_of :: "obj_ref \<Rightarrow> dom2" where
  "dom_of p \<equiv> if p = 0 then SchedD else if p < 10 then LowD else HighD"

definition cur_dom :: "kstate \<Rightarrow> dom2" where
  "cur_dom s \<equiv> dom_of (ks_cur s)"

text \<open>
  策略 @{verbatim "flows"} 就是真实的 @{verbatim "policy :: ('d \<times> 'd) set"}
  （"@{verbatim "who can send info to whom"}"，第 411 行的注释）。
  两条关于调度器的公理照抄 @{verbatim "noninterference_policy"}
  那两个 locale 假设：@{verbatim "schedFlowsToAll"} 与
  @{verbatim "schedNotGlobalChannel"}——调度器流向所有人，
  但\emph{没人}能流向调度器。
\<close>

definition flows :: "dom2 \<Rightarrow> dom2 \<Rightarrow> bool" (infix "\<leadsto>" 50) where
  "u \<leadsto> v \<equiv> case u of
      SchedD \<Rightarrow> True
    | LowD \<Rightarrow> v \<noteq> SchedD
    | HighD \<Rightarrow> v = HighD"

lemma schedFlowsToAll: "SchedD \<leadsto> v"
  by (simp add: flows_def split: dom2.splits)

lemma schedNotGlobalChannel: "x \<leadsto> SchedD \<Longrightarrow> x = SchedD"
  by (cases x) (auto simp: flows_def)

lemma flows_Low [simp]: "(LowD \<leadsto> v) = (v \<noteq> SchedD)"
  by (simp add: flows_def)

lemma flows_High [simp]: "(HighD \<leadsto> v) = (v = HighD)"
  by (simp add: flows_def)

lemma flows_Sched [simp]: "(SchedD \<leadsto> v) = True"
  by (simp add: flows_def)

lemma high_does_not_flow_low: "\<not> (HighD \<leadsto> LowD)"
  by simp

lemma flows_refl: "u \<leadsto> u"
  by (cases u) (auto simp: flows_def)

subsection \<open>22.4 不可区分关系 uwr\<close>

text \<open>
  真实的 @{verbatim "uwr :: 'd \<Rightarrow> ('s \<times> 's) set"} 是\emph{按域索引的一对状态集合}，
  记作 @{verbatim "s \<sim>u\<sim> t"}。@{verbatim "Noninterference.thy"} 里那份
  @{verbatim "sameFor_subject"} 逐项列出"分区 l 看不看得出差别"：
  @{verbatim "cur_domain"}、@{verbatim "globals_equiv"}、
  @{verbatim "scheduler_action"}、@{verbatim "work_units_completed"}、
  @{verbatim "irq_state"}，以及只在 @{verbatim "user_modes"} 下才比较的用户上下文。
  这里按同一副骨架简化成"当前域 + 自己那批信箱"。
\<close>

definition UWR :: "dom2 \<Rightarrow> (kstate \<times> kstate) set" where
  "UWR d \<equiv> case d of
      SchedD \<Rightarrow> {(s, t). ks_cur s = ks_cur t}
    | LowD \<Rightarrow> {(s, t). cur_dom s = cur_dom t \<and> (\<forall>p<10. ks_msgs s p = ks_msgs t p)}
    | HighD \<Rightarrow> {(s, t). cur_dom s = cur_dom t \<and> ks_msgs s = ks_msgs t}"

abbreviation uwr2 :: "kstate \<Rightarrow> dom2 \<Rightarrow> kstate \<Rightarrow> bool" ("(_/ \<sim>_\<sim>/ _)" [50, 100, 50] 1000) where
  "s \<sim>u\<sim> t \<equiv> (s, t) \<in> UWR u"

lemma uwr_refl: "s \<sim>u\<sim> s"
  by (simp add: UWR_def split: dom2.splits)

lemma uwr_sym: "s \<sim>u\<sim> t \<Longrightarrow> t \<sim>u\<sim> s"
  by (auto simp: UWR_def split: dom2.splits)

lemma uwr_trans: "\<lbrakk>s \<sim>u\<sim> t; t \<sim>u\<sim> v\<rbrakk> \<Longrightarrow> s \<sim>u\<sim> v"
  by (auto simp: UWR_def split: dom2.splits)

text \<open>
  真实 locale 把这三条打包成一个假设
  @{verbatim "uwr_equiv_rel: equiv UNIV (uwr u)"}——
  不可区分关系\emph{必须}是等价关系，否则"分不出"没法传递地用。
\<close>

lemma uwr_equiv_rel: "equiv UNIV {(s, t). s \<sim>u\<sim> t}"
  by (auto simp: equiv_def refl_on_def sym_def trans_def intro: uwr_refl uwr_sym uwr_trans)

lemma schedIncludesCurrentDom: "s \<sim>SchedD\<sim> t \<Longrightarrow> cur_dom s = cur_dom t"
  by (simp add: UWR_def cur_dom_def)

text \<open>
  多个域同时不可区分，真实里叫 @{verbatim "sameFor_dom"}，记 @{verbatim "s \<approx>D\<approx> t"}。
  它就是"对 @{verbatim "D"} 里每个域都不可区分"，于是天然对 @{verbatim "D"} 单调递减。
\<close>

definition sameFor_dom :: "kstate \<Rightarrow> dom2 set \<Rightarrow> kstate \<Rightarrow> bool" ("(_/ \<approx>_\<approx>/ _)" [50, 100, 50] 1000) where
  "s \<approx>ds\<approx> t \<equiv> \<forall>u\<in>ds. s \<sim>u\<sim> t"

lemma sameFor_subset_dom: "\<lbrakk>s \<approx>x\<approx> t; y \<subseteq> x\<rbrakk> \<Longrightarrow> s \<approx>y\<approx> t"
  by (auto simp: sameFor_dom_def)

lemma sameFor_sym_dom: "s \<approx>S\<approx> t \<Longrightarrow> t \<approx>S\<approx> s"
  by (auto simp: sameFor_dom_def intro: uwr_sym)

subsection \<open>22.5 观察函数 out：真实那份实例化成了 undefined\<close>

text \<open>
  @{verbatim "Noninterference_Base.thy"} 的策略 locale 里有
  @{verbatim "out :: 'd \<Rightarrow> 's \<Rightarrow> 'p"}——每个域看得见的那部分状态。
  而 @{verbatim "Noninterference.thy"} 第 1517 行把它实例化成
  @{verbatim "undefined"}，紧跟的注释说的是 "out -- unused"。
  模型里\emph{有} @{verbatim "out"}，正是为了把两者的分工显示出来：
  带 @{verbatim "out"} 的那一族（@{verbatim "obs_equiv"}、
  @{verbatim "Noninterference"}）要多一条 @{verbatim "output_consistent"} 才推得动；
  只带 uwr 的那一族（@{verbatim "uwr_equiv"}、@{verbatim "Nonleakage_gen"}）不要，
  所以 seL4 证的是后者。
\<close>

definition visible :: "dom2 \<Rightarrow> obj_ref set" where
  "visible d \<equiv> case d of LowD \<Rightarrow> {p. p < 10} | SchedD \<Rightarrow> {} | HighD \<Rightarrow> UNIV"

definition out :: "dom2 \<Rightarrow> kstate \<Rightarrow> dom2 \<times> (obj_ref \<Rightarrow> nat) \<times> obj_ref" where
  "out d s \<equiv> (cur_dom s, (\<lambda>p. if p \<in> visible d then ks_msgs s p else 0),
               if d = SchedD then ks_cur s else 0)"

definition output_consistent :: bool where
  "output_consistent \<equiv> \<forall>s t u. s \<sim>u\<sim> t \<longrightarrow> out u s = out u t"

lemma output_consistent_holds: output_consistent
  unfolding output_consistent_def UWR_def out_def visible_def
  by (auto split: dom2.splits simp: cur_dom_def dom_of_def)

subsection \<open>22.6 事件、Step 与可达状态\<close>

text \<open>
  真实的"一步"是内核的\emph{大阶}：@{verbatim "ADT_IF.thy"} 把内核包装成
  @{verbatim "big_step_ADT_A_if"}，事件类型就是 @{verbatim "unit"}——
  一次"从用户态进内核再回用户态"。模型里一步做两件事：
  当前线程给自己信箱加一，然后换下一个线程。
\<close>

datatype ev = Big

definition advance :: "kstate \<Rightarrow> kstate" where
  "advance s \<equiv> s\<lparr> ks_msgs := (ks_msgs s)(ks_cur s := ks_msgs s (ks_cur s) + 1),
                   ks_cur := Suc (ks_cur s) \<rparr>"

text \<open>
  @{verbatim "Step :: 'e \<Rightarrow> ('s \<times> 's) set"} 是\emph{关系}而不是函数
  （第 96 行）：内核是非确定的，什么时候被抢占、调度谁由环境决定。
  这里刻意让它退化成函数——于是
  @{verbatim "obs_det"}（可观察部分确定，第 101 行）在模型里恒成立，
  代价是 @{verbatim "sources"} 的那个并集塌成一项。
\<close>

definition Step :: "ev \<Rightarrow> (kstate \<times> kstate) set" where
  "Step a \<equiv> {(s, s'). s' = advance s}"

lemma Step_iff [simp]: "(s, s') \<in> Step a \<longleftrightarrow> s' = advance s"
  by (simp add: Step_def)

fun exec :: "kstate \<Rightarrow> ev list \<Rightarrow> kstate set" where
  "exec s [] = {s}"
| "exec s (a # as) = (\<Union>s' \<in> {s''::kstate. (s, s'') \<in> Step a}. exec s' as)"

lemma exec_one: "exec s [a] = {advance s}"
  by (cases a) simp

definition s0 :: kstate where
  "s0 \<equiv> \<lparr> ks_msgs = \<lambda>_. 0, ks_cur = 0 \<rparr>"

fun run :: "nat \<Rightarrow> kstate" where
  "run 0 = s0"
| "run (Suc n) = advance (run n)"

definition reachable :: "kstate \<Rightarrow> bool" where
  "reachable s \<equiv> \<exists>n. s = run n"

lemma reachable_s0: "reachable s0"
  unfolding reachable_def by (rule exI[where x=0]) (simp add: s0_def)

lemma reachable_run: "reachable (run n)"
  unfolding reachable_def by blast

lemma reachable_advance: "reachable s \<Longrightarrow> reachable (advance s)"
  unfolding reachable_def
proof (erule exE)
  fix n assume ns: "s = run n"
  then have "advance s = run (Suc n)" by simp
  then show "\<exists>m. advance s = run m" by blast
qed

lemma ks_cur_run: "ks_cur (run n) = n"
  by (induct n) (simp add: s0_def, simp add: advance_def)

lemma obs_det_model: "\<exists>s'. exec s as = {s'}"
proof (induct as arbitrary: s)
  case Nil show ?case by simp
next
  case (Cons a as)
  then obtain s' where ih: "exec (advance s) as = {s'}" by (cases a) auto
  then show ?case by (cases a) simp
qed

text \<open>
  @{verbatim "enabled_system"}（第 126 行）那条假设
  "@{verbatim "reachable s \<Longrightarrow> \<exists>s'. s' \<in> execution A s js"}"看着平平无奇，
  但没有它，@{verbatim "sources_Cons"} 里的并集会在一对 @{verbatim "Step a = {}"}
  上塌成空集，@{verbatim "sources (a # as) s u"} 直接变成 @{term "{}"}，
  整条 purge 就把一切都删光。模型里 @{verbatim "Step"} 是函数，所以这条免费。
\<close>

lemma sources_empty_without_Step: "(\<Union>s' \<in> {}. P s') = {}"
  by simp

subsection \<open>22.7 sources：这条 trace 里谁会影响到 u\<close>

text \<open>
  这是 @{verbatim "Noninterference_Base.thy"} 第 481 行那份
  @{verbatim "primrec sources"} 的形状——非传递性的全部机关都在这一条递归里：
  事件\emph{此刻}的域 @{verbatim "dom a s"} 只有能流向
  "后面某个还会影响 u 的域"时，才算 u 的信息来源。
  模型里 @{verbatim "dom"} 与事件无关（就是 @{verbatim "cur_dom s"}），
  这一点和真实的 @{verbatim "\<lambda>e s. part s"} 一致。
\<close>

primrec sources :: "ev list \<Rightarrow> kstate \<Rightarrow> dom2 \<Rightarrow> dom2 set" where
  sources_Nil: "sources [] s u = {u}"
| sources_Cons: "sources (a # as) s u =
    (\<Union>{sources as s' u | s'. (s, s') \<in> Step a}) \<union>
    {w. w = cur_dom s \<and> (\<exists>v s'. cur_dom s \<leadsto> v \<and> (s, s') \<in> Step a \<and> v \<in> sources as s' u)}"

declare sources_Nil [simp del]
declare sources_Cons [simp del]

lemma sources_Un:
  "sources (a # as) s u = sources as (advance s) u \<union>
     (if (\<exists>v \<in> sources as (advance s) u. cur_dom s \<leadsto> v) then {cur_dom s} else {})"
  by (cases a) (auto simp: sources_Cons)

lemma sources_tail_subset: "sources as (advance s) u \<subseteq> sources (a # as) s u"
  by (subst sources_Un) simp

lemma sources_refl: "u \<in> sources as s u"
  by (induct as arbitrary: s) (simp add: sources_Nil, simp add: sources_Un)

text \<open>
  下面两条就是真实的第 1179 与第 1184 行那对
  @{verbatim "sources_Step"}/@{verbatim "sources_Step_2"}。
  真实版本多一个 @{verbatim "reachable s"} 前提——那是为了用
  @{verbatim "enabled_Step"}，模型里 @{verbatim "Step"} 全定义，前提自然消失。
\<close>

lemma sources_Step: "\<not> (cur_dom s \<leadsto> u) \<Longrightarrow> sources [a] s u = {u}"
  by (simp add: sources_Un sources_Nil)

lemma sources_Step_2: "cur_dom s \<leadsto> u \<Longrightarrow> sources [a] s u = {cur_dom s, u}"
  by (simp add: sources_Un sources_Nil)

lemma sources_sched_is_sched: "sources as s SchedD = {SchedD}"
  by (induct as arbitrary: s)
     (simp add: sources_Nil, simp add: sources_Un, fastforce dest: schedNotGlobalChannel)

lemma low_sources_bounded: "sources as s LowD \<subseteq> {LowD, SchedD}"
proof (induct as arbitrary: s)
  case Nil show ?case by (simp add: sources_Nil)
next
  case (Cons a as)
  then show ?case
    by (simp add: sources_Un) (cases "cur_dom s", auto)
qed

lemma high_not_a_source_for_low: "HighD \<notin> sources as s LowD"
  using low_sources_bounded [of as s] by auto

text \<open>
  @{thm high_not_a_source_for_low} 是策略真正"起作用"的地方：
  无论 trace 多长、非确定分支怎么走，@{term HighD} 永远进不了
  @{term LowD} 的信息来源集合。
\<close>

subsection \<open>22.8 ipurge：把与 u 无关的事件删掉\<close>

text \<open>
  @{verbatim "gen_purge"}（第 529 行）配上
  @{verbatim "ipurge = gen_purge sources"}（第 536 行）。
  注意判定用的是 @{verbatim "\<exists>s\<in>ss"}——只要 @{verbatim "ss"} 里\emph{有}一个状态
  认为这个事件相关，就把它留下。
\<close>

primrec ipurge :: "dom2 \<Rightarrow> ev list \<Rightarrow> kstate set \<Rightarrow> ev list" where
  ipurge_Nil: "ipurge u [] ss = []"
| ipurge_Cons: "ipurge u (a # as) ss =
     (if (\<exists>s \<in> ss. cur_dom s \<in> sources (a # as) s u)
      then a # ipurge u as (\<Union>s \<in> ss. {s'. (s, s') \<in> Step a})
      else ipurge u as ss)"

lemma ipurge_shortens: "set (ipurge u as ss) \<subseteq> set as"
  by (induct as arbitrary: ss) auto

lemma ipurge_one_Sched: "ipurge SchedD [a] {s} = (if cur_dom s = SchedD then [a] else [])"
  by (cases a) (simp add: sources_sched_is_sched)

lemma ipurge_two_Sched_from_s0: "ipurge SchedD [Big, Big] {s0} = [Big]"
  by (simp add: sources_sched_is_sched s0_def cur_dom_def dom_of_def advance_def)

lemma ipurge_drops_high_world:
  assumes "\<And>s. s \<in> ss \<Longrightarrow> cur_dom s = HighD"
  shows "ipurge LowD (a # as) ss = ipurge LowD as ss"
proof -
  have "a = Big" by (cases a) simp
  moreover have "\<And>s. s \<in> ss \<Longrightarrow> HighD \<notin> sources (Big # as) s LowD"
    using high_not_a_source_for_low by blast
  ultimately show ?thesis by (simp add: assms)qed

subsection \<open>22.9 三条安全性质：obs、uwr、以及带 purge 的那条\<close>

text \<open>
  三兄弟只差在\emph{结论}：@{verbatim "obs_equiv"} 比观察值，
  @{verbatim "uwr_equiv"} 比 uwr，@{verbatim "Nonleakage_gen"} 用后者，
  @{verbatim "Noninterference"} 用前者且把第二条 trace 换成 @{verbatim "ipurge"}。
  定义逐字对着第 490、494、508、564 行抄。
\<close>

definition obs_equiv :: "kstate \<Rightarrow> ev list \<Rightarrow> kstate \<Rightarrow> ev list \<Rightarrow> dom2 \<Rightarrow> bool" where
  "obs_equiv s as t bs d \<equiv>
     \<forall>s' \<in> exec s as. \<forall>t' \<in> exec t bs. out d s' = out d t'"

definition uwr_equiv :: "kstate \<Rightarrow> ev list \<Rightarrow> kstate \<Rightarrow> ev list \<Rightarrow> dom2 \<Rightarrow> bool" where
  "uwr_equiv s as t bs d \<equiv>
     \<forall>s' \<in> exec s as. \<forall>t' \<in> exec t bs. s' \<sim>d\<sim> t'"

definition Nonleakage :: bool where
  "Nonleakage \<equiv> \<forall>as s u t. reachable s \<and> reachable t
                  \<longrightarrow> s \<sim>SchedD\<sim> t
                  \<longrightarrow> s \<approx>(sources as s u)\<approx> t
                  \<longrightarrow> obs_equiv s as t as u"

definition Nonleakage_gen :: bool where
  "Nonleakage_gen \<equiv> \<forall>as s u t. reachable s \<and> reachable t
                     \<longrightarrow> s \<sim>SchedD\<sim> t
                     \<longrightarrow> s \<approx>(sources as s u)\<approx> t
                     \<longrightarrow> uwr_equiv s as t as u"

definition Noninterference :: bool where
  "Noninterference \<equiv>
     \<forall>u as s. reachable s \<longrightarrow> obs_equiv s as s (ipurge u as {s}) u"

text \<open>
  真实的第 743 行那条桥叫 @{verbatim "obs_equivI"}：
  @{verbatim "output_consistent"} 一给上，
  uwr 版立刻推出 obs 版。这条桥在 seL4 里\emph{架不起来}——
  因为 @{verbatim "out"} 是 @{verbatim "undefined"}。
\<close>

lemma uwr_equiv_imp_obs_equiv:
  assumes oc: \<open>output_consistent\<close> and u: "uwr_equiv s as t bs d"
  shows "obs_equiv s as t bs d"
  using assms unfolding obs_equiv_def uwr_equiv_def output_consistent_def by blast

subsection \<open>22.10 两条 unwinding 条件：一条成立，一条不成立\<close>

text \<open>
  @{verbatim "confidentiality_u"}（第 664 行）与
  @{verbatim "integrity_u"}（第 678 行）——整个机密性证明就压在这两条上。
  两条都只说"一步"，于是可以从 @{verbatim "Nonleakage_gen"} 里取
  长度一的 trace 反推出来（第 1211 行
  @{verbatim "Nonleakage_gen_confidentiality_u"}）。
  真实 @{verbatim "integrity_u"} 的前提写的是
  @{verbatim "(dom a s, u) \<notin> policy"}，也就是"这一步的执行者不许流向 @{verbatim "u"}"；
  模型里每个事件都由当前线程跑，所以那就是 @{verbatim "\<not> (cur_dom s \<leadsto> u)"}。
\<close>

definition confidentiality_u :: bool where
  "confidentiality_u \<equiv>
     \<forall>a s t u. reachable s \<and> reachable t
       \<longrightarrow> s \<sim>SchedD\<sim> t
       \<longrightarrow> ((cur_dom s \<leadsto> u) \<longrightarrow> s \<sim>cur_dom s\<sim> t)
       \<longrightarrow> s \<sim>u\<sim> t
       \<longrightarrow> (\<forall>s' t'. (s, s') \<in> Step a \<and> (t, t') \<in> Step a \<longrightarrow> s' \<sim>u\<sim> t')"

definition integrity_u :: bool where
  "integrity_u \<equiv>
     \<forall>a u s. reachable s \<longrightarrow> \<not> (cur_dom s \<leadsto> u)
            \<longrightarrow> (\<forall>s'. (s, s') \<in> Step a \<longrightarrow> s \<sim>u\<sim> s')"

lemma advance_preserves_uwr:
  "\<lbrakk>s \<sim>SchedD\<sim> t; s \<sim>u\<sim> t\<rbrakk> \<Longrightarrow> (advance s) \<sim>u\<sim> (advance t)"
  unfolding UWR_def advance_def cur_dom_def dom_of_def by (auto split: dom2.splits)

lemma confidentiality_u_holds: confidentiality_u
  unfolding confidentiality_u_def
  by (auto intro: advance_preserves_uwr)

lemma run_9_cur: "cur_dom (run 9) = LowD"
  by (simp add: cur_dom_def dom_of_def ks_cur_run)

lemma not_self_uwr_SchedD_after_advance: "\<not> ((s, advance s) \<in> UWR SchedD)"
  unfolding UWR_def advance_def by simp

lemma integrity_witness:
  "reachable (run 9) \<and> \<not> (cur_dom (run 9) \<leadsto> SchedD)
     \<and> (run 9, advance (run 9)) \<in> Step Big
     \<and> \<not> ((run 9, advance (run 9)) \<in> UWR SchedD)"
  using reachable_run run_9_cur
  by (auto simp: flows_def UWR_def advance_def cur_dom_def dom_of_def ks_cur_run)

lemma integrity_u_fails: "\<not> integrity_u"
  using integrity_witness unfolding integrity_u_def by blast

text \<open>
  坏在哪一步？@{term "run 9"} 的当前线程是 9 号（@{term LowD}），
  走一步之后是 10 号（@{term HighD}）——\emph{换分区}了。
  对 @{term SchedD} 这个观察者来说"现在轮到谁"恰是它看得见的那部分，
  而"低分区不许流向调度器"（@{thm schedNotGlobalChannel}）又是策略硬要求的。
  于是 @{verbatim "integrity_u"} 在分区边界上必然失败。
  这正是真实的 @{verbatim "integrity_part"}（第 1976 行）
  为什么要在前提里写死 @{verbatim "u \<noteq> PSched"} 与 @{verbatim "part s \<noteq> PSched"}。
\<close>

lemma run_9_switches_partition: "cur_dom (run 9) = LowD \<and> cur_dom (run 10) = HighD"
  by (simp add: cur_dom_def dom_of_def ks_cur_run)

subsection \<open>22.11 主定理：Nonleakage\<sub>gen</sub> 成立，Noninterference 不成立\<close>

text \<open>
  先证成立的那条。归纳的全部负担是"@{verbatim "sources"} 随状态前进只会变小"，
  而 @{thm sources_tail_subset} 一步就给出来了。
\<close>

lemma advance_preserves_sameFor:
  assumes "s \<sim>SchedD\<sim> t" and "s \<approx>D\<approx> t"
  shows "(advance s) \<approx>D\<approx> (advance t)"
proof -
  { fix v assume "v \<in> D"
    with assms(2) have "s \<sim>v\<sim> t" by (simp add: sameFor_dom_def)
    with assms(1) have "(advance s) \<sim>v\<sim> (advance t)" by (rule advance_preserves_uwr) }
  then show ?thesis by (simp add: sameFor_dom_def)
qed

lemma nonleakage_gen_aux:
  "\<lbrakk>reachable s; reachable t; s \<sim>SchedD\<sim> t; s \<approx>(sources as s u)\<approx> t\<rbrakk>
     \<Longrightarrow> uwr_equiv s as t as u"
proof (induct as arbitrary: s t)
  case Nil
  then show ?case by (auto simp: uwr_equiv_def sameFor_dom_def sources_Nil)
next
  case (Cons a as)
  then have sch: "(advance s) \<sim>SchedD\<sim> (advance t)"
    unfolding UWR_def advance_def by simp
  have sf0: "s \<approx>(sources as (advance s) u)\<approx> t"
    using Cons.prems(4)
    by (rule sameFor_subset_dom [OF _ sources_tail_subset])
  have sf: "(advance s) \<approx>(sources as (advance s) u)\<approx> (advance t)"
    using Cons.prems(3) sf0 by (rule advance_preserves_sameFor)
  have ih_use: "uwr_equiv (advance s) as (advance t) as u"
  proof (rule Cons(1) [of "advance s" "advance t"])
    from Cons.prems(1) show "reachable (advance s)" by (rule reachable_advance)
    from Cons.prems(2) show "reachable (advance t)" by (rule reachable_advance)
    show "(advance s) \<sim>SchedD\<sim> (advance t)" by (rule sch)
    show "(advance s) \<approx>(sources as (advance s) u)\<approx> (advance t)" by (rule sf)
  qed
  then show ?case by (auto simp: uwr_equiv_def)
qed

lemma nonleakage_gen: Nonleakage_gen
  using nonleakage_gen_aux unfolding Nonleakage_gen_def by blast

text \<open>
  真实的证明顺序与这里相反：第 1112 行那条 @{verbatim "Nonleakage_gen"}
  是"@{verbatim "confidentiality_u \<Longrightarrow> Nonleakage_gen"}"（先有 unwinding 条件，
  再抬到无泄漏），第 1211 行 @{verbatim "Nonleakage_gen_confidentiality_u"}
  是反方向——把 trace 取成长度一就还原出 @{verbatim "confidentiality_u"}。
  模型里 @{verbatim "confidentiality_u"} 由 @{thm confidentiality_u_holds}
  直接成立，两条方向合起来就是第 1221 行那条
  @{verbatim "Nonleakage_gen_equiv_confidentiality_u"}，即
  @{verbatim "Nonleakage_gen = confidentiality_u"}——
  这条 unwinding 条件对 @{verbatim "Nonleakage_gen"} 既\emph{可靠}又\emph{充分}。
\<close>

lemma one_step_uwr:
  assumes nl: Nonleakage_gen
      and rs: "reachable s" and rt: "reachable t"
      and sch: "s \<sim>SchedD\<sim> t"
      and conf: "cur_dom s \<leadsto> u \<longrightarrow> s \<sim>cur_dom s\<sim> t"
      and ut: "s \<sim>u\<sim> t"
  shows "(advance s) \<sim>u\<sim> (advance t)"
proof -
  have sf: "s \<approx>(sources [a] s u)\<approx> t"
    using sch conf ut by (auto simp: sources_Un sources_Nil sameFor_dom_def)
  have "uwr_equiv s [a] t [a] u"
    using nl rs rt sch sf unfolding Nonleakage_gen_def by blast
  then show ?thesis by (auto simp: uwr_equiv_def image_def)
qed

lemma nonleakage_gen_confidentiality_u:
  assumes nl: Nonleakage_gen
  shows confidentiality_u
  using nl unfolding confidentiality_u_def
  by (intro allI impI) (auto dest: one_step_uwr [OF nl])

text \<open>
  然后是那条\emph{不成立}的。@{verbatim "Noninterference.thy"} 第 28 行
  写得很直白：Noninterference 没有被证明。模型里能\emph{举出反例}，
  而且反例正好落在调度器分区上：策略禁止任何东西流向 @{verbatim "PSched"}，
  于是 @{verbatim "ipurge"} 把低分区的事件全删了——
  可"轮到谁"本身就是 @{verbatim "PSched"} 的观察对象。
\<close>

lemma obs_equiv_two_vs_one:
  "\<not> obs_equiv (run 0) [Big, Big] (run 0) [Big] SchedD"
  unfolding obs_equiv_def by (auto simp: exec_one out_def advance_def ks_cur_run)

lemma obs_equiv_two_vs_one_s0:
  "\<not> obs_equiv s0 [Big, Big] s0 [Big] SchedD"
  using obs_equiv_two_vs_one by (simp add: s0_def)

lemma noninterference_fails: "\<not> Noninterference"
proof (unfold Noninterference_def, intro notI)
  fix h assume h: "\<forall>u as s. reachable s \<longrightarrow> obs_equiv s as s (ipurge u as {s}) u"
  then have P: "obs_equiv s0 [Big, Big] s0 (ipurge SchedD [Big, Big] {s0}) SchedD"
    using reachable_s0 by blast
  have ip: "ipurge SchedD [Big, Big] {s0} = [Big]" by (rule ipurge_two_Sched_from_s0)
  then have "obs_equiv s0 [Big, Big] s0 [Big] SchedD" using P by simp
  with obs_equiv_two_vs_one_s0 show False by blast
qed

text \<open>
  反过来，@{verbatim "Nonleakage_gen"} 加一条
  @{verbatim "output_consistent"} 就抬到 @{verbatim "Nonleakage"}——
  模型里 @{verbatim "out"} 是真的，所以这座桥走得通；
  seL4 那边 @{verbatim "out := undefined"}，走不通，于是论文与代码
  给出的都是 @{verbatim "Nonleakage_gen"}。
\<close>

lemma nonleakage: Nonleakage
  using nonleakage_gen output_consistent_holds
  unfolding Nonleakage_def Nonleakage_gen_def
  by (metis uwr_equiv_imp_obs_equiv)

subsection \<open>22.12 Noninfluence：要两条条件一起才够\<close>

text \<open>
  @{verbatim "Noninfluence_gen"}（第 643 行）比 @{verbatim "Nonleakage_gen"} 强，
  因为它把 @{verbatim "ipurge"} 掺进了第二条 trace。
  真实文件第 1284 行 @{verbatim "Noninfluence_gen \<Longrightarrow> integrity_u"}
  说它\emph{蕴含}完整性条件；配上 @{thm integrity_u_fails}
  就得到 @{verbatim "Noninfluence_gen"} 的反证。
  这解释了整件事：seL4 只证了无泄漏，没证"无影响"。
\<close>

definition Noninfluence_gen :: bool where
  "Noninfluence_gen \<equiv>
     \<forall>u as s ts. reachable s \<and> (\<forall>t \<in> ts. reachable t)
       \<longrightarrow> (\<forall>t \<in> ts. s \<approx>(sources as s u)\<approx> t)
       \<longrightarrow> (\<forall>t \<in> ts. s \<sim>SchedD\<sim> t)
       \<longrightarrow> (\<forall>t \<in> ts. uwr_equiv s as t (ipurge u as ts) u)"

lemma Noninfluence_gen_integrity_u:
  assumes ni: Noninfluence_gen
  shows integrity_u
proof -
  have niu: "\<forall>u as s ts. reachable s \<and> (\<forall>t \<in> ts. reachable t)
               \<longrightarrow> (\<forall>t \<in> ts. s \<approx>(sources as s u)\<approx> t)
               \<longrightarrow> (\<forall>t \<in> ts. s \<sim>SchedD\<sim> t)
               \<longrightarrow> (\<forall>t \<in> ts. uwr_equiv s as t (ipurge u as ts) u)"
    using ni by (auto simp: Noninfluence_gen_def)
  { fix a :: ev and u :: dom2 and s :: kstate
    assume rs: "reachable s" and nf: "\<not> (cur_dom s \<leadsto> u)"
    have sf: "s \<approx>(sources [a] s u)\<approx> s"
      by (auto simp: sameFor_dom_def UWR_def split: dom2.splits)
    from niu rs sf have P: "uwr_equiv s [a] s (ipurge u [a] {s}) u"
      by (blast intro: uwr_refl)
    have ne: "cur_dom s \<noteq> u" using nf by (blast intro: flows_refl)
    have ip: "ipurge u [a] {s} = []"
      using nf ne by (simp add: sources_Un sources_Nil)
    with P have "uwr_equiv s [a] s [] u" by simp
    then have "(advance s) \<sim>u\<sim> s" by (auto simp: uwr_equiv_def exec_one)
    note this }
  then show ?thesis
    unfolding integrity_u_def by (auto intro: uwr_sym)
qed

lemma noninfluence_gen_fails: "\<not> Noninfluence_gen"
  using Noninfluence_gen_integrity_u integrity_u_fails by blast

subsection \<open>22.13 xources：换成"所有分支"也一样的那版\<close>

text \<open>
  @{verbatim "Noninterference_Base_Alternatives.thy"} 第 14 行的自述是
  "试探 @{verbatim "sources"} 与 @{verbatim "ipurge"} 的一堆替身定义，
  结果它们\emph{全都等价}"。最要紧的那个替身把
  @{verbatim "sources_Cons"} 里的 @{verbatim "\<Union>"} 换成 @{verbatim "\<Inter>"}，
  判定条件从 @{verbatim "\<exists>s\<in>ss"} 换成 @{verbatim "\<forall>s\<in>ss"}。
  不过真实那份 @{verbatim "xources_sources"}（同文件第 108 行）是
  "@{verbatim "confidentiality_u \<Longrightarrow> reachable s \<Longrightarrow> xources = sources"}"——
  等价要挂两条前提；模型里 @{verbatim "Step"} 是函数，
  前提全用不上，所以那条 @{verbatim "sources_eq_xources"} 是裸的等式。
\<close>

primrec xources :: "ev list \<Rightarrow> kstate \<Rightarrow> dom2 \<Rightarrow> dom2 set" where
  xources_Nil: "xources [] s u = {u}"
| xources_Cons: "xources (a # as) s u =
    (\<Inter>{xources as s' u | s'. (s, s') \<in> Step a}) \<union>
    {w. w = cur_dom s \<and>
        (\<forall>s'. (s, s') \<in> Step a \<longrightarrow> (\<exists>v. cur_dom s \<leadsto> v \<and> v \<in> xources as s' u))}"

lemma xources_Un:
  "xources (a # as) s u = xources as (advance s) u \<union>
     (if (\<exists>v \<in> xources as (advance s) u. cur_dom s \<leadsto> v) then {cur_dom s} else {})"
  by (cases a) auto

lemma sources_eq_xources: "sources as s u = xources as s u"
proof (induct as arbitrary: s)
  case Nil show ?case by (simp add: sources_Nil)
next
  case (Cons a as)
  have inu: "u \<in> sources as (advance s) u" by (rule sources_refl)
  with Cons show ?case unfolding sources_Un xources_Un
    by (cases "(\<exists>v \<in> sources as (advance s) u. cur_dom s \<leadsto> v)") auto
qed

ML \<open>
  writeln (@{make_string} @{thm high_not_a_source_for_low});
  writeln (@{make_string} @{thm integrity_u_fails});
  writeln (@{make_string} @{thm noninterference_fails});
  writeln (@{make_string} @{thm nonleakage_gen});
  writeln (@{make_string} @{thm nonleakage});
  writeln (@{make_string} @{thm Noninfluence_gen_integrity_u});
  writeln (@{make_string} @{thm noninfluence_gen_fails});
  writeln (@{make_string} @{thm sources_eq_xources})
\<close>

ML \<open>writeln "==== 22 结束 ===="\<close>

end
