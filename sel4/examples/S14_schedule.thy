theory S14_schedule
  imports Main
begin

section \<open>14.1 调度：优先级 + 轮转 + 域\<close>

text \<open>
  seL4 的调度策略写在 @{verbatim "l4v/spec/abstract/Schedule_A.thy"}：
  \begin{itemize}
    \item 每个优先级一条就绪队列（@{verbatim "ready_queue"}，
          第 71 行 @{verbatim "max_non_empty_queue"} 用 @{verbatim "Max"} 挑最高优先级）；
    \item 同一优先级内 @{verbatim "hd"} 取队首，跑完一轮再排到队尾；
    \item 之上还有一层 \emph{domain}（域）调度，用时间片做粗粒度隔离
          （第 53 行 @{verbatim "next_domain"}）；
    \item 无线程可跑就切 idle（第 42 行 @{verbatim "switch_to_idle_thread"}）。
  \end{itemize}

  内核状态里的相关字段在 @{verbatim "l4v/spec/abstract/Structures_A.thy"}
  第 570--582 行：@{verbatim "scheduler_action"}、@{verbatim "domain_list"}、
  @{verbatim "domain_index"}、@{verbatim "domain_start_index"}、
  @{verbatim "cur_domain"}、@{verbatim "domain_time"}、
  @{verbatim "ready_queues"}（注意它是 @{verbatim "domain => priority => ready_queue"}
  ——\emph{每个域一套队列}）。

  MCS（mixed-criticality systems）配置下还有调度上下文与预算，
  见 @{verbatim "seL4/src/object/schedcontext.c"}。本章只讲经典调度。
\<close>

ML \<open>writeln "==== 14 开始 ===="\<close>

type_synonym obj_ref = nat
type_synonym priority = nat
type_synonym ready_queue = "obj_ref list"
type_synonym queues = "priority \<Rightarrow> ready_queue"

definition empty_queues :: queues where
  "empty_queues \<equiv> \<lambda>_. []"

definition enqueue :: "priority \<Rightarrow> obj_ref \<Rightarrow> queues \<Rightarrow> queues" where
  "enqueue p t qs \<equiv> qs(p := qs p @ [t])"

definition dequeue :: "priority \<Rightarrow> obj_ref \<Rightarrow> queues \<Rightarrow> queues" where
  "dequeue p t qs \<equiv> qs(p := filter (\<lambda>x. x \<noteq> t) (qs p))"

subsection \<open>14.2 入队与出队\<close>

lemma enqueue_adds: "t \<in> set (enqueue p t qs p)"
  by (auto simp: enqueue_def)

lemma enqueue_keeps_others:
  "q \<noteq> p \<Longrightarrow> enqueue p t qs q = qs q"
  by (simp add: enqueue_def)

lemma dequeue_removes: "t \<notin> set (dequeue p t qs p)"
  by (auto simp: dequeue_def)

lemma dequeue_then_enqueue:
  "t \<notin> set (qs p) \<Longrightarrow> enqueue p t qs p = qs p @ [t]"
  by (simp add: enqueue_def)

lemma dequeue_keeps_others:
  "q \<noteq> p \<Longrightarrow> dequeue p t qs q = qs q"
  by (simp add: dequeue_def)

text \<open>
  真实内核里 @{verbatim "tcb_sched_enqueue"} / @{verbatim "tcb_sched_dequeue"}
  还要处理"同一个线程不能同时在两条队列里"这一不变式；
  上面的 @{thm dequeue_removes} 是它的模型版。
\<close>

subsection \<open>14.3 选线程：Max 加 hd，外面必须套一层守卫\<close>

text \<open>
  规范里的 @{verbatim "max_non_empty_queue"}（@{verbatim "Schedule_A.thy"}
  第 71 行）只有一行：@{verbatim "queues (Max {prio. queues prio \<noteq> []})"}。
  它\emph{没有}处理"全空"的情形，因为调用方 @{verbatim "choose_thread"}
  （第 74 行）先用 @{verbatim "if \<forall>prio. queues prio = []"} 挡掉了。
  这一节把这条守卫为什么不能省算出来。
\<close>

definition max_non_empty_queue :: "queues \<Rightarrow> obj_ref list" where
  "max_non_empty_queue qs \<equiv> qs (Max {prio. qs prio \<noteq> []})"

lemma all_empty_queues_gives_nil: "max_non_empty_queue empty_queues = []"
  by (simp add: max_non_empty_queue_def empty_queues_def)

lemma max_on_singleton_is_the_element: "Max ({p::priority} :: priority set) = p"
  by simp

lemma max_on_two_takes_the_larger: "p \<le> q \<Longrightarrow> Max {p, q::priority} = q"
  by simp

text \<open>
  这两条摆出了 @{verbatim "Max"} 的全部可用等式：\emph{只在非空集合上}有方程
  （@{verbatim "Lattices_Big.thy"} 第 41 行 @{verbatim "singleton"}、
  第 67 行 @{verbatim "insert"}，两条的前提里都明写着集合非空）。
  队列全空时支撑集就是空集，@{verbatim "Max"} 作用在空集上在 HOL 里
  \textbf{没有任何等式}——连"它等于 0"都证不出来，
  它是定义式里那个 @{verbatim "the None"}，一个彻底任意的 nat。
  而每个 nat 都是一个合法线程号，所以调用方那道
  "@{verbatim "if \<forall>prio. queues prio = []"}" 守卫不是防御性编程，
  而是让 @{verbatim "hd"} 有定义的唯一理由。
\<close>

definition choose_thread :: "queues \<Rightarrow> obj_ref option" where
  "choose_thread qs \<equiv>
     if (\<forall>prio. qs prio = []) then None
     else Some (hd (max_non_empty_queue qs))"

lemma no_queues_means_idle: "choose_thread empty_queues = None"
  by (simp add: choose_thread_def empty_queues_def)

lemma single_queue_picks_head:
  "choose_thread (empty_queues(5 := [t1, t2])) = Some t1"
  by (simp add: choose_thread_def max_non_empty_queue_def empty_queues_def)

lemma lower_priority_alone_still_runs:
  "choose_thread (empty_queues(1 := [lo])) = Some lo"
  by (simp add: choose_thread_def max_non_empty_queue_def empty_queues_def)

lemma higher_priority_wins:
  "choose_thread (empty_queues(1 := [lo::obj_ref], 9 := [hi::obj_ref])) = Some hi"
proof -
  have s: "{p. (empty_queues(1 := [lo::obj_ref], 9 := [hi::obj_ref])) p \<noteq> []} = {1, 9}"
    by (auto simp: empty_queues_def)
  show ?thesis
    unfolding choose_thread_def max_non_empty_queue_def s
    by (auto simp: empty_queues_def)
qed

lemma rotate_still_picks_the_highest:
  "choose_thread (empty_queues(1 := [lo], 9 := [hi, next])) = Some hi"
proof -
  have s: "{p. (empty_queues(1 := [lo::obj_ref], 9 := [hi::obj_ref, next::obj_ref])) p \<noteq> []} = {1, 9}"
    by (auto simp: empty_queues_def)
  show ?thesis
    unfolding choose_thread_def max_non_empty_queue_def s
    by (auto simp: empty_queues_def)
qed

definition rotate :: "priority \<Rightarrow> queues \<Rightarrow> queues" where
  "rotate p qs \<equiv> qs(p := tl (qs p) @ [hd (qs p)])"

lemma rotate_moves_head:
  "qs p = t # rest \<Longrightarrow> hd ((rotate p qs) p) = (if rest = [] then t else hd rest)"
  by (cases rest) (auto simp: rotate_def)

lemma rotate_keeps_queue_contents:
  "qs p \<noteq> [] \<Longrightarrow> set (rotate p qs p) = set (qs p)"
  by (cases "qs p") (auto simp: rotate_def)

text \<open>
  @{thm rotate_moves_head} 是"同优先级轮转"的全部内容：
  队列里 @{verbatim "[t1, t2]"}，跑完 @{verbatim "t1"} 把它排回队尾，
  下次 @{verbatim "hd"} 就是 @{verbatim "t2"}。
\<close>

subsection \<open>14.4 域：轮转靠列表末尾的标记，不靠取模\<close>

text \<open>
  域（domain）是一层比优先级更硬的隔离：一个域的时间片用完之后，
  内核切到下一个域，\emph{不管}那边优先级多低。

  这里有一处规范与直觉不同的地方：@{verbatim "next_domain"}
  （@{verbatim "l4v/spec/abstract/Schedule_A.thy"} 第 53--66 行）
  \emph{不是} @{verbatim "(index + 1) mod length list"}。
  它先看下一个表项是不是 @{verbatim "domain_end_marker"}
  （第 50 行，定义就是 @{verbatim "(0, 0)"}），
  是的话回到 @{verbatim "domain_start_index"}。
   @{verbatim "domain_set_start"}（第 167 行）的注释把这层意思写明了：
  表里最后一项\emph{预留}作结束标记，所以设起点时把索引写成
  @{verbatim "length list - 2"}。
\<close>

type_synonym domain = nat

record dom_sched =
  ds_list  :: "(domain \<times> nat) list"
  ds_index :: nat
  ds_start :: nat

definition domain_end_marker :: "domain \<times> nat" where
  "domain_end_marker \<equiv> (0, 0)"

definition next_domain :: "dom_sched \<Rightarrow> dom_sched" where
  "next_domain s \<equiv>
     s\<lparr> ds_index := (if ds_list s ! (ds_index s + 1) = domain_end_marker
                       then ds_start s else ds_index s + 1) \<rparr>"

lemma next_domain_advances_when_no_marker:
  "ds_list s ! (ds_index s + 1) \<noteq> domain_end_marker \<Longrightarrow>
   ds_index (next_domain s) = ds_index s + 1"
  by (simp add: next_domain_def)

lemma next_domain_wraps_at_marker:
  "ds_list s ! (ds_index s + 1) = domain_end_marker \<Longrightarrow>
   ds_index (next_domain s) = ds_start s"
  by (simp add: next_domain_def)

lemma next_domain_keeps_list: "ds_list (next_domain s) = ds_list s"
  by (simp add: next_domain_def)

definition mk_sched :: "(domain \<times> nat) list \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> dom_sched" where
  "mk_sched xs i st \<equiv> \<lparr> ds_list = xs, ds_index = i, ds_start = st \<rparr>"

lemma marker_example_wraps_to_start_not_zero:
  "ds_index (next_domain (mk_sched [(2, 10), (0, 0)] 0 1)) = 1"
  by (simp add: next_domain_def mk_sched_def domain_end_marker_def)

lemma marker_wrap_and_modulo_disagree:
  "ds_index (next_domain (mk_sched [(2, 10), (3, 20), (4, 30), (0, 0)] 2 0)) = 0"
  by (simp add: next_domain_def mk_sched_def domain_end_marker_def)

lemma modulo_would_have_gone_on:
  "(2 + 1) mod length [(2 :: domain), 3, 4, 0] = 3"
  by simp

text \<open>
  最后两条摆在一起看：同一张表、同一个索引，
  标记法回到 @{verbatim "domain_start_index"}（这里是 0），
  取模法会走到 3——而 3 号位\emph{就是那个标记}，
  于是下一次 @{verbatim "choose_thread"} 会对着一个不存在的域挑线程。
  这就是为什么 @{verbatim "domain_start_index"} 要单独存一个字段：
  它允许"只在表的某一段里轮转"（第 167 行的 @{verbatim "domain_set_start"}
  正是这么用的）。
\<close>

definition domain_set_start :: "nat \<Rightarrow> dom_sched \<Rightarrow> dom_sched" where
  "domain_set_start i s \<equiv>
     s\<lparr> ds_start := i, ds_index := length (ds_list s) - 2 \<rparr>"

lemma set_start_moves_index_to_last_but_one:
  "length (ds_list s) = 5 \<Longrightarrow> ds_index (domain_set_start 0 s) = 3"
  by (simp add: domain_set_start_def)

lemma set_start_then_next_lands_on_start:
  "ds_index (next_domain (domain_set_start 0 (mk_sched [(7, 10), (8, 20), (0, 0)] 0 0))) = 0"
  by (simp add: domain_set_start_def next_domain_def mk_sched_def domain_end_marker_def)

subsection \<open>14.5 三条 assert：切线程的三道闸\<close>

text \<open>
  把 @{verbatim "Schedule_A.thy"} 里那三句 @{verbatim "assert"} 摆在一起看：

  \begin{itemize}
    \item 第 26 行 @{verbatim "switch_to_thread"}：
          @{verbatim "assert (get_tcb t state \<noteq> None)"}——要切的线程必须存在；
    \item 第 36 行 @{verbatim "guarded_switch_to"}：
          @{verbatim "assert (runnable ts)"}——必须可运行（第 13 章）；
    \item 第 117 行 @{verbatim "schedule"} 的 @{verbatim "resume_cur_thread"} 分支：
          @{verbatim "assert (ct_runnable \<or> ct = idle_thread)"}——
          当前线程要么还能跑，要么它就是 idle。
  \end{itemize}
\<close>

datatype thread_state = Running | Inactive | Restart | IdleThreadState

primrec runnable :: "thread_state \<Rightarrow> bool" where
  "runnable Running = True"
| "runnable Inactive = False"
| "runnable Restart = True"
| "runnable IdleThreadState = False"

definition switch_allowed :: "obj_ref set \<Rightarrow> (obj_ref \<Rightarrow> thread_state) \<Rightarrow> obj_ref \<Rightarrow> bool" where
  "switch_allowed ks st t \<equiv> t \<in> ks \<and> runnable (st t)"

lemma switch_requires_existence: "\<not> switch_allowed {} st t"
  by (simp add: switch_allowed_def)

lemma switch_requires_runnable: "\<not> switch_allowed ks (\<lambda>_. Inactive) t"
  by (simp add: switch_allowed_def)

lemma switch_allowed_for_running_thread:
  "t \<in> ks \<Longrightarrow> switch_allowed ks (\<lambda>_. Running) t"
  by (simp add: switch_allowed_def)

definition resume_allowed :: "bool \<Rightarrow> obj_ref \<Rightarrow> obj_ref \<Rightarrow> bool" where
  "resume_allowed ct_runnable ct idle \<equiv> ct_runnable \<or> ct = idle"

lemma idle_needs_no_permission: "resume_allowed False i i"
  by (simp add: resume_allowed_def)

lemma nonidle_needs_runnable:
  "\<not> ct_runnable \<Longrightarrow> resume_allowed ct_runnable ct idle = (ct = idle)"
  by (auto simp: resume_allowed_def)

text \<open>
  第三条闸的形状值得记：@{verbatim "ct_runnable \<or> ct = idle_thread"}。
  当前线程不可运行还\emph{合法}的唯一理由，就是它本来就是 idle 线程——
  它是那个"没活干时空转"的线程，从来不在就绪队列里。
\<close>

subsection \<open>14.6 scheduler\_action：下一步该干什么\<close>

text \<open>
  内核不直接切线程，而是先在一个状态字段里记下"打算干什么"：
  @{verbatim "Structures_A.thy"} 第 541 行的
  @{verbatim "datatype scheduler_action = resume_cur_thread
    | switch_thread (sch_act_target : obj_ref) | choose_new_thread"}。
  注意 @{verbatim "switch_thread"} 带着一个线程号，
  而另两个不带——所以"要切到哪"这个信息只可能来自内核自己。
\<close>

datatype scheduler_action =
    resume_cur_thread
  | switch_thread obj_ref
  | choose_new_thread

definition action_picks_a_target :: "scheduler_action \<Rightarrow> obj_ref option" where
  "action_picks_a_target a \<equiv> case a of switch_thread t \<Rightarrow> Some t | _ \<Rightarrow> None"

lemma resume_has_no_target: "action_picks_a_target resume_cur_thread = None"
  by (simp add: action_picks_a_target_def)

lemma choose_new_has_no_target: "action_picks_a_target choose_new_thread = None"
  by (simp add: action_picks_a_target_def)

lemma switch_carries_its_target: "action_picks_a_target (switch_thread t) = Some t"
  by (simp add: action_picks_a_target_def)

lemma targets_are_distinct: "switch_thread t \<noteq> resume_cur_thread"
  by simp

text \<open>
  三条合起来说："只有 @{verbatim "switch_thread"} 这一支带着线程号，
  另外两支都必须让调度器自己去算"。@{verbatim "choose_new_thread"}
  走 @{verbatim "schedule_choose_new_thread"}（第 97 行），
  它先 @{verbatim "when (domain_time = 0) next_domain"} 再 @{verbatim "choose_thread"}；
  @{verbatim "resume_cur_thread"} 什么都不做，只负责断言 14.5 的第三条闸。
\<close>

subsection \<open>14.7 "最高优先级"与抢占：一个严格不等式\<close>

text \<open>
  @{verbatim "switch_thread"} 这一支不是想切就切：
  @{verbatim "schedule_switch_thread_fastfail"}（@{verbatim "Schedule_A.thy"}
  第 92 行）把条件写成一个纯函数
  @{verbatim "return $ ct \<noteq> it \<longrightarrow> target_prio < ct_prio"}。
  注意那个 @{verbatim "<"}：候选线程的优先级必须\emph{严格}高于当前线程，同级不行。
  而 @{verbatim "ct \<noteq> it"} 这个前提就是 idle 线程的豁免，
  规范里那句 "Infoflow does not like asking about the idle thread's priority
  or domain" 的注释解释了原因：当前线程是 idle 时 @{verbatim "ct_prio"}
  被直接当成 0（同一 do 块里那行 @{verbatim "if ct \<noteq> it then thread_get ... else return 0"}），
  于是任何线程都能抢过 idle。

  旁边第 87 行的 @{verbatim "is_highest_prio"} 则是 14.3 那道守卫的"正确姿势"：
  它把"队列全空"写成一个\emph{析取支} @{verbatim "(\<forall>prio. ready_queues s d prio = [])"}，
  而不是让 @{verbatim "Max"} 去碰空集。
\<close>

definition is_highest_prio :: "queues \<Rightarrow> priority \<Rightarrow> bool" where
  "is_highest_prio qs p \<equiv> (\<forall>prio. qs prio = []) \<or> p \<ge> Max {prio. qs prio \<noteq> []}"

lemma highest_prio_holds_when_nothing_is_queued: "is_highest_prio empty_queues p"
  by (simp add: is_highest_prio_def empty_queues_def)

lemma highest_prio_asks_for_nine:
  "is_highest_prio (empty_queues(1 := [lo::obj_ref], 9 := [hi::obj_ref])) p \<longleftrightarrow> 9 \<le> p"
proof -
  have s: "{p. (empty_queues(1 := [lo::obj_ref], 9 := [hi::obj_ref])) p \<noteq> []} = {1, 9}"
    by (auto simp: empty_queues_def)
  show ?thesis unfolding is_highest_prio_def s by (auto simp: empty_queues_def)
qed

lemma nine_is_highest:
  "is_highest_prio (empty_queues(1 := [lo::obj_ref], 9 := [hi::obj_ref])) 9"
proof -
  have s: "{p. (empty_queues(1 := [lo::obj_ref], 9 := [hi::obj_ref])) p \<noteq> []} = {1, 9}"
    by (auto simp: empty_queues_def)
  show ?thesis unfolding is_highest_prio_def s by (auto simp: empty_queues_def)
qed

lemma eight_is_not_highest:
  "\<not> is_highest_prio (empty_queues(1 := [lo::obj_ref], 9 := [hi::obj_ref])) 8"
proof -
  have s: "{p. (empty_queues(1 := [lo::obj_ref], 9 := [hi::obj_ref])) p \<noteq> []} = {1, 9}"
    by (auto simp: empty_queues_def)
  show ?thesis unfolding is_highest_prio_def s by (auto simp: empty_queues_def)
qed

definition target_is_better :: "obj_ref \<Rightarrow> obj_ref \<Rightarrow> priority \<Rightarrow> priority \<Rightarrow> bool" where
  "target_is_better ct it ct_prio target_prio \<equiv> ct = it \<or> target_prio < ct_prio"

lemma preemption_is_strict:
  "ct \<noteq> it \<Longrightarrow> ct_prio \<le> target_prio \<Longrightarrow> \<not> target_is_better ct it ct_prio target_prio"
  by (auto simp: target_is_better_def)

lemma same_priority_does_not_preempt: "ct \<noteq> it \<Longrightarrow> \<not> target_is_better ct it 7 7"
  by (auto simp: target_is_better_def)

lemma idle_is_preempted_by_anything: "target_is_better it it p q"
  by (simp add: target_is_better_def)

text \<open>
  @{thm same_priority_does_not_preempt} 是"优先级数大者先跑"这句话的另一半：
  同优先级\emph{不}抢占，只能靠 14.3 的 @{verbatim "rotate"} 排队轮转。
\<close>

ML \<open>
  writeln (@{make_string} @{thm higher_priority_wins});
  writeln (@{make_string} @{thm marker_example_wraps_to_start_not_zero})
\<close>

ML \<open>writeln "==== 14 结束 ===="\<close>

end
