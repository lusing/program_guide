theory S14_schedule
  imports Main
begin

section \<open>14.1 调度：优先级 + 轮转 + 域\<close>

text \<open>
  seL4 的调度策略写在 @{verbatim "l4v/spec/abstract/Schedule_A.thy"}：
  \begin{itemize}
    \item 每个优先级一条就绪队列（@{verbatim "ready_queue"}），
          调度时取\emph{最高优先级}的非空队列队首（第 74 行
          @{verbatim "choose_thread"}）；
    \item 同一优先级内轮转；
    \item 之上还有一层 \emph{domain}（域）调度，用时间片做粗粒度隔离
          （第 53 行 @{verbatim "next_domain"}）；
    \item 无线程可跑就切 idle（第 42 行 @{verbatim "switch_to_idle_thread"}）。
  \end{itemize}

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

definition max_non_empty_queue :: "queues \<Rightarrow> priority list \<Rightarrow> priority option" where
  "max_non_empty_queue qs ps \<equiv>
     let ne = filter (\<lambda>p. qs p \<noteq> []) ps in
     if ne = [] then None else Some (last ne)"

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

subsection \<open>14.3 选线程：取最高优先级\<close>

datatype sched_result = SwitchTo obj_ref | SwitchToIdle

definition choose_thread :: "queues \<Rightarrow> priority list \<Rightarrow> sched_result" where
  "choose_thread qs ps \<equiv> case max_non_empty_queue qs ps of
      None \<Rightarrow> SwitchToIdle
    | Some p \<Rightarrow> SwitchTo (hd (qs p))"

lemma no_queues_means_idle: "choose_thread empty_queues ps = SwitchToIdle"
  by (simp add: choose_thread_def max_non_empty_queue_def empty_queues_def Let_def)

lemma single_queue_picks_head:
  "choose_thread (empty_queues(5 := [t1, t2])) [5] = SwitchTo t1"
  by (simp add: choose_thread_def max_non_empty_queue_def empty_queues_def Let_def)

lemma higher_priority_wins:
  "choose_thread (empty_queues(1 := [lo], 9 := [hi])) [1, 9] = SwitchTo hi"
  by (simp add: choose_thread_def max_non_empty_queue_def empty_queues_def Let_def)

text \<open>
  @{thm higher_priority_wins} 就是"高优先级抢占"的一句话版本。
  注意 @{verbatim "max_non_empty_queue"} 用的是 @{verbatim "last"}：
  优先级列表按\emph{升序}排列，所以最后一个非空队列就是最高优先级。
  这类"列表顺序即优先级顺序"的约定，是读调度代码时最容易看错的地方。
\<close>

subsection \<open>14.4 域：粗粒度的时间隔离\<close>

text \<open>
  域（domain）是一层比优先级更硬的隔离：一个域的时间片用完之后，
  内核切到下一个域，\emph{不管}那边优先级多低。这给"关键子系统
  不会被饿死"提供了可证的保证。
\<close>

type_synonym domain = nat

record dom_state =
  ds_index  :: domain
  ds_list   :: "domain list"

definition next_domain :: "dom_state \<Rightarrow> dom_state" where
  "next_domain s \<equiv> s\<lparr> ds_index := (ds_index s + 1) mod length (ds_list s) \<rparr>"

lemma next_domain_changes_index:
  "ds_index (next_domain s) = (ds_index s + 1) mod length (ds_list s)"
  by (simp add: next_domain_def)

lemma next_domain_wraps:
  "ds_index s + 1 = length (ds_list s) \<Longrightarrow> ds_index (next_domain s) = 0"
  by (simp add: next_domain_def)

lemma next_domain_keeps_list: "ds_list (next_domain s) = ds_list s"
  by (simp add: next_domain_def)

subsection \<open>14.5 idle 线程不是普通线程\<close>

text \<open>
  idle 线程的状态是 @{verbatim "IdleThreadState"}（见第 13 章），
  它不可运行、不在任何队列里、也不参与优先级比较。
  切到它的路径是独立的（@{verbatim "switch_to_idle_thread"}）。
\<close>

datatype switch_target = TargetThread obj_ref | TargetIdle

definition switch :: "sched_result \<Rightarrow> switch_target" where
  "switch r \<equiv> case r of SwitchTo t \<Rightarrow> TargetThread t | SwitchToIdle \<Rightarrow> TargetIdle"

lemma idle_switch_is_idle: "switch SwitchToIdle = TargetIdle"
  by (simp add: switch_def)

lemma thread_switch_is_thread: "switch (SwitchTo t) = TargetThread t"
  by (simp add: switch_def)

ML \<open>
  writeln (@{make_string} @{thm higher_priority_wins});
  writeln (@{make_string} @{thm next_domain_wraps})
\<close>

ML \<open>writeln "==== 14 结束 ===="\<close>

end
