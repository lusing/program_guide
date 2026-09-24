theory S12_notification
  imports Main
begin

section \<open>12.1 通知：一组二元信号量\<close>

text \<open>
  通知对象与端点的区别只有一句：\emph{通知是异步的}。发送方不会阻塞，
  只是把 badge 里的那些位"或"进通知的字里；接收方可以选择阻塞等待。

  真实定义 @{verbatim "l4v/spec/abstract/Structures_A.thy"} 第 308 行起是一个
  @{verbatim "record notification"}，核心字段是
  @{verbatim "ntfnBoundTCB"} 与 @{verbatim "ntfnMsgIdentifier"}；
  C 侧在 @{verbatim "seL4/src/object/notification.c"}。
\<close>

ML \<open>writeln "==== 12 开始 ===="\<close>

type_synonym badge = nat
type_synonym obj_ref = nat

subsection \<open>12.2 位运算模型\<close>

text \<open>
  真实内核里 badge 是一个机器字，每一位代表一个"信号"。
  模型用 @{typ "nat set"} 表示"哪些位被置上了"，避免引入字长。
\<close>

type_synonym signal_set = "nat set"

definition signal :: "signal_set \<Rightarrow> signal_set \<Rightarrow> signal_set" where
  "signal pending badge \<equiv> pending \<union> badge"

definition poll :: "signal_set \<Rightarrow> signal_set \<Rightarrow> signal_set \<times> signal_set" where
  "poll pending badge \<equiv> (pending \<inter> badge, pending - badge)"

lemma signal_is_monotone: "pending \<subseteq> signal pending badge"
  by (auto simp: signal_def)

lemma signal_is_idempotent: "signal (signal pending b) b = signal pending b"
  by (auto simp: signal_def)

lemma signal_commutes: "signal (signal p b1) b2 = signal (signal p b2) b1"
  by (auto simp: signal_def)

text \<open>
  @{thm signal_is_idempotent} 与 @{thm signal_commutes} 合起来说明：
  通知是\emph{累加}的，多次 signal 不会记数，只会置位。
  这正是"通知不是计数信号量"的形式化说法——
  想知道发生了几次，就得给每次发不同的 badge 位。
\<close>

lemma poll_returns_subset_of_badge: "fst (poll pending badge) \<subseteq> badge"
  by (auto simp: poll_def)

lemma poll_clears_those_bits:
  "snd (poll pending badge) = pending - fst (poll pending badge)"
  by (auto simp: poll_def)

lemma poll_then_signal_no_gain:
  "signal (snd (poll p b)) (fst (poll p b)) = p"
  by (auto simp: poll_def signal_def)

subsection \<open>12.3 绑定 TCB：通知只能有一个等待者\<close>

text \<open>
  通知对象可以绑定到一个线程（@{verbatim "seL4_TCB_BindNotification"}）。
  绑定之后只有那个线程能等待它，因此"谁被唤醒"是确定的——
  这也是通知比端点简单的地方：没有队列。
\<close>

record notification =
  ntfn_signals :: signal_set
  ntfn_bound   :: "obj_ref option"

definition default_notification :: notification where
  "default_notification \<equiv> \<lparr> ntfn_signals = {}, ntfn_bound = None \<rparr>"

definition bind_tcb :: "obj_ref \<Rightarrow> notification \<Rightarrow> notification option" where
  "bind_tcb t n \<equiv> case ntfn_bound n of
      None \<Rightarrow> Some (n\<lparr> ntfn_bound := Some t \<rparr>)
    | Some _ \<Rightarrow> None"

lemma fresh_notification_is_unbound: "ntfn_bound default_notification = None"
  by (simp add: default_notification_def)

lemma bind_once_ok:
  "ntfn_bound n = None \<Longrightarrow> bind_tcb t n = Some (n\<lparr> ntfn_bound := Some t \<rparr>)"
  by (simp add: bind_tcb_def)

lemma bind_twice_rejected:
  "ntfn_bound n = Some t' \<Longrightarrow> bind_tcb t n = None"
  by (simp add: bind_tcb_def)

lemma bind_sets_thread:
  "bind_tcb t n = Some n' \<Longrightarrow> ntfn_bound n' = Some t"
  by (auto simp: bind_tcb_def split: option.splits)

text \<open>
  真实内核里重复绑定会返回 @{verbatim "seL4_IllegalOperation"}；
  模型用 @{verbatim "None"} 表达"这一步被拒绝"。
\<close>

subsection \<open>12.4 Reply 对象与一次性回答\<close>

text \<open>
  @{verbatim "ReplyCap"} 是"回答某一次 Call"的一次性票据。
  它在 @{verbatim "CSpace_A.thy"} 第 106 行的 @{verbatim "derive_cap"} 里
  派生结果是 @{verbatim "NullCap"}——\emph{不可复制}。
  这是"一次性"在类型层面的体现。
\<close>

datatype reply_state = Unused | Consumed

definition consume_reply :: "reply_state \<Rightarrow> reply_state option" where
  "consume_reply r \<equiv> case r of Unused \<Rightarrow> Some Consumed | Consumed \<Rightarrow> None"

lemma reply_consumed_once: "consume_reply Unused = Some Consumed"
  by (simp add: consume_reply_def)

lemma reply_cannot_be_reused: "consume_reply Consumed = None"
  by (simp add: consume_reply_def)

lemma reply_is_one_shot:
  "consume_reply r = Some r' \<Longrightarrow> consume_reply r' = None"
  by (auto simp: consume_reply_def split: reply_state.splits)

text \<open>
  @{thm reply_is_one_shot} 就是 Call/Reply 协议的核心：一次 Call 对应
  至多一次 Reply。真实内核里这条性质支撑着"Reply 能力不会被用来
  冒充别人回答"——它是完整性证明里被反复用到的一条。
\<close>

ML \<open>
  writeln (@{make_string} @{thm signal_commutes});
  writeln (@{make_string} @{thm reply_is_one_shot})
\<close>

ML \<open>writeln "==== 12 结束 ===="\<close>

end
