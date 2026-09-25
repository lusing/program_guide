theory S12_notification
  imports Main
begin

section \<open>12.1 通知：一组二元信号量\<close>

text \<open>
  通知对象与端点的区别，规范里就写在数据类型上面那三行注释里
  （@{verbatim "l4v/spec/abstract/Structures_A.thy"} 第 299 行）：
  通知是"存在徽章字里的一组二元信号量"，而且
  "Unlike endpoints, threads may choose to block waiting to receive,
  \emph{{}}but not to send}" —— 发送方永远不阻塞。

  C 侧的全部逻辑在 @{verbatim "seL4/src/object/notification.c"}，
  入口 @{verbatim "sendSignal"} 在第 62 行。
\<close>

ML \<open>writeln "==== 12 开始 ===="\<close>

type_synonym obj_ref = nat

subsection \<open>12.2 状态：Idle / Waiting / Active\<close>

text \<open>
  真实定义（@{verbatim "l4v/spec/abstract/Structures_A.thy"} 第 303--310 行）
  是一个三构造子的 @{verbatim "ntfn"} 加一条 @{verbatim "record notification"}。
  模型照抄形状，只把"徽章是一个机器字"换成"哪些位被置上"的集合，
  免得把字长拖进每一页证明。
\<close>

type_synonym badge_bits = "nat set"

datatype ntfn = IdleNtfn | WaitingNtfn "obj_ref list" | ActiveNtfn badge_bits

record notification =
  ntfn_obj :: ntfn
  ntfn_bound_tcb :: "obj_ref option"

definition mk_ntfn :: "ntfn \<Rightarrow> obj_ref option \<Rightarrow> notification" where
  "mk_ntfn n b \<equiv> \<lparr> ntfn_obj = n, ntfn_bound_tcb = b \<rparr>"

lemma mk_ntfn_obj [simp]: "ntfn_obj (mk_ntfn n b) = n"
  by (simp add: mk_ntfn_def)

lemma mk_ntfn_bound [simp]: "ntfn_bound_tcb (mk_ntfn n b) = b"
  by (simp add: mk_ntfn_def)

definition default_notification :: notification where
  "default_notification \<equiv> mk_ntfn IdleNtfn None"

lemma fresh_notification_is_idle: "ntfn_obj default_notification = IdleNtfn"
  by (simp add: default_notification_def)

definition ntfn_well_formed :: "ntfn \<Rightarrow> bool" where
  "ntfn_well_formed n \<equiv> case n of
      IdleNtfn      \<Rightarrow> True
    | WaitingNtfn q \<Rightarrow> q \<noteq> []
    | ActiveNtfn _  \<Rightarrow> True"

lemma idle_ntfn_well_formed: "ntfn_well_formed IdleNtfn"
  by (simp add: ntfn_well_formed_def)

lemma empty_wait_queue_not_well_formed: "\<not> ntfn_well_formed (WaitingNtfn [])"
  by (simp add: ntfn_well_formed_def)

text \<open>
  注意 @{verbatim "WaitingNtfn"} 里装的是一个\emph{列表}：
  一个通知上可以同时挂着多个等待者。第 12.6 节会把这条和
  "绑定线程只有一个"摆在一起看。
\<close>

subsection \<open>12.3 累加：把按位或写成并集\<close>

text \<open>
  两个徽章怎么合成一个？规范里 @{verbatim "combine_ntfn_badges"} 的定义是
  一行 @{verbatim "combine_ntfn_badges \<equiv> semiring_bit_operations_class.or"}
  （@{verbatim "l4v/spec/abstract/ARM/Machine_A.thy"} 第 96 行）。
  C 里对应 @{verbatim "badge2 |= badge;"}
  （@{verbatim "seL4/src/object/notification.c"} 第 186 行）。
  换成集合表示，"或"就是"并"。
\<close>

definition combine :: "badge_bits \<Rightarrow> badge_bits \<Rightarrow> badge_bits" where
  "combine s1 s2 \<equiv> s1 \<union> s2"

lemma combine_commutes: "combine a b = combine b a"
  by (simp add: combine_def ac_simps)

lemma combine_idempotent: "combine s s = s"
  by (simp add: combine_def)

lemma combine_assoc: "combine (combine a b) c = combine a (combine b c)"
  by (simp add: combine_def ac_simps)

lemma combine_never_loses_a_bit: "s \<subseteq> combine s s'"
  by (simp add: combine_def)

lemma combine_same_signal_twice: "combine (combine p b) b = combine p b"
  by (auto simp: combine_def)

text \<open>
  @{thm combine_idempotent} 就是"通知不是计数信号量"的形式化说法：
  同一个位发多少次都只算一次。想知道发生了几次，
  就得给每次发\emph{不同}的位。
\<close>

subsection \<open>12.4 发送：四条分支\<close>

text \<open>
  @{verbatim "Ipc_A.thy"} 第 461 行 @{verbatim "send_signal"} 把通知状态分成四种
  处理：空闲就置成 Active；有人排队就唤醒队首；已经 Active 就把两个徽章并起来。
  第四条分支（绑定线程恰好阻塞在 receive 上）要看线程状态，
  那是第 13 章的对象，这里先按"空闲"处理。

  @{verbatim "Asserted"} 这一支对应规范里
  @{verbatim "update_waiting_ntfn"} 开头那句 @{verbatim "assert (queue \<noteq> [])"}
  （@{verbatim "l4v/spec/abstract/Ipc_A.thy"} 第 437 行）：
  实现\emph{依赖}井形性才敢取队首。
\<close>

datatype send_step = Woke obj_ref | Signalled | Merged | Asserted

definition send_signal :: "badge_bits \<Rightarrow> notification \<Rightarrow> notification \<times> send_step" where
  "send_signal b n \<equiv>
     (case ntfn_obj n of
         IdleNtfn \<Rightarrow> (n\<lparr> ntfn_obj := ActiveNtfn b \<rparr>, Signalled)
       | WaitingNtfn (q # rest) \<Rightarrow>
            (n\<lparr> ntfn_obj := (if rest = [] then IdleNtfn else WaitingNtfn rest) \<rparr>, Woke q)
       | WaitingNtfn [] \<Rightarrow> (n, Asserted)
       | ActiveNtfn b' \<Rightarrow> (n\<lparr> ntfn_obj := ActiveNtfn (combine b b') \<rparr>, Merged))"

lemma send_to_idle_signals:
  "send_signal b (mk_ntfn IdleNtfn t) = (mk_ntfn (ActiveNtfn b) t, Signalled)"
  by (simp add: send_signal_def)

lemma send_wakes_head_of_queue:
  "send_signal b (mk_ntfn (WaitingNtfn [q]) t) = (mk_ntfn IdleNtfn t, Woke q)"
  by (simp add: send_signal_def)

lemma send_keeps_rest_of_queue:
  "send_signal b (mk_ntfn (WaitingNtfn [q1, q2]) t) = (mk_ntfn (WaitingNtfn [q2]) t, Woke q1)"
  by (simp add: send_signal_def)

lemma send_on_active_merges:
  "send_signal b (mk_ntfn (ActiveNtfn b') t) = (mk_ntfn (ActiveNtfn (b \<union> b')) t, Merged)"
  by (simp add: send_signal_def combine_def)

lemma well_formed_send_is_never_asserted:
  "ntfn_well_formed (ntfn_obj n) \<Longrightarrow> snd (send_signal b n) \<noteq> Asserted"
  by (auto simp: send_signal_def ntfn_well_formed_def split: ntfn.splits list.splits)

definition waiting_queue :: "ntfn \<Rightarrow> obj_ref list" where
  "waiting_queue n \<equiv> case n of WaitingNtfn q \<Rightarrow> q | _ \<Rightarrow> []"

lemma send_never_adds_a_waiter:
  "length (waiting_queue (ntfn_obj (fst (send_signal b n)))) \<le> length (waiting_queue (ntfn_obj n))"
  by (auto simp: send_signal_def waiting_queue_def split: ntfn.splits list.splits if_splits)

text \<open>
  最后一条是"发送方从不阻塞"的另一种写法：
  发送这个动作本身不会往队列里添人。端点那条规则（第 11 章）在这里反了过来。
\<close>

subsection \<open>12.5 接收：全取并清空\<close>

text \<open>
  @{verbatim "Ipc_A.thy"} 第 489 行 @{verbatim "receive_signal"} 的三条分支里，
  最该记住的是 @{verbatim "ActiveNtfn badge \<Rightarrow> … setRegister badge_register badge;
  … ntfn_set_obj ntfn IdleNtfn"} ——
  接收方\emph{一次拿走整个徽章}，然后通知回到 Idle。
  这里\emph{没有}掩码：想挑走部分位，只能在发的时候用不同的位。

  非阻塞且没有消息时走 @{verbatim "do_nbrecv_failed_transfer"}
  （第 370 行），它把徽章寄存器写成 @{verbatim "0"} ——
  "没有消息"在寄存器层面就是一个真零。
\<close>

datatype recv_step = Received badge_bits | Joined | No_message

definition receive_signal :: "obj_ref \<Rightarrow> bool \<Rightarrow> notification \<Rightarrow> notification \<times> recv_step" where
  "receive_signal t blocking n \<equiv>
     (case ntfn_obj n of
         ActiveNtfn b \<Rightarrow> (n\<lparr> ntfn_obj := IdleNtfn \<rparr>, Received b)
       | IdleNtfn \<Rightarrow>
            (if blocking then (n\<lparr> ntfn_obj := WaitingNtfn [t] \<rparr>, Joined) else (n, No_message))
       | WaitingNtfn q \<Rightarrow>
            (if blocking then (n\<lparr> ntfn_obj := WaitingNtfn (q @ [t]) \<rparr>, Joined)
                        else (n, No_message)))"

lemma receive_takes_the_whole_badge:
  "receive_signal t b (mk_ntfn (ActiveNtfn s) t') = (mk_ntfn IdleNtfn t', Received s)"
  by (simp add: receive_signal_def)

lemma receive_resets_notification_to_idle:
  "snd (receive_signal t b n) = Received s \<Longrightarrow> ntfn_obj (fst (receive_signal t b n)) = IdleNtfn"
  by (auto simp: receive_signal_def split: ntfn.splits if_splits)

lemma receive_appends_to_the_queue:
  "receive_signal t True (mk_ntfn (WaitingNtfn q) b) =
     (mk_ntfn (WaitingNtfn (q @ [t])) b, Joined)"
  by (simp add: receive_signal_def)

text \<open>
  "有没有消息"必须说成"状态不是 Active"。写成
  @{verbatim "ntfn_obj n \<noteq> ActiveNtfn s"} 是\emph{不}够的——那只是
  "不是某一个特定的徽章"，@{thm receive_resets_notification_to_idle}
  的反例正好落在这上面。
\<close>

definition no_message :: "ntfn \<Rightarrow> bool" where
  "no_message n \<equiv> case n of ActiveNtfn _ \<Rightarrow> False | _ \<Rightarrow> True"

lemma no_message_covers_idle_and_waiting:
  "no_message IdleNtfn \<and> no_message (WaitingNtfn q)"
  by (simp add: no_message_def)

lemma active_is_a_message: "\<not> no_message (ActiveNtfn s)"
  by (simp add: no_message_def)

lemma nonblocking_receive_without_message_changes_nothing:
  "no_message (ntfn_obj n) \<Longrightarrow> fst (receive_signal t False n) = n"
  by (auto simp: receive_signal_def no_message_def split: ntfn.splits)

definition badge_of_step :: "recv_step \<Rightarrow> badge_bits" where
  "badge_of_step r \<equiv> case r of Received s \<Rightarrow> s | _ \<Rightarrow> {}"

lemma no_message_badge_is_zero:
  "no_message (ntfn_obj n) \<Longrightarrow> badge_of_step (snd (receive_signal t False n)) = {}"
  by (auto simp: receive_signal_def badge_of_step_def no_message_def split: ntfn.splits)

lemma send_then_receive_delivers_everything:
  "ntfn_obj n = IdleNtfn \<Longrightarrow>
   receive_signal t True (fst (send_signal b n)) = (n\<lparr> ntfn_obj := IdleNtfn \<rparr>, Received b)"
  by (auto simp: send_signal_def receive_signal_def)

text \<open>
  两条通知叠上来时，第二次发只是并位：
  实测 @{thm send_then_receive_delivers_everything} 说的是"一次收全部"，
  而 @{thm send_on_active_merges} 说的是"发不会丢已攒下的位"。
\<close>

subsection \<open>12.6 绑定：一个绑定线程，多个等待者\<close>

text \<open>
  这是本章最容易记反的一处。@{verbatim "ntfn_bound_tcb"} 是
  @{verbatim "obj_ref option"}（@{verbatim "l4v/spec/abstract/Structures_A.thy"}
  第 310 行）——\emph{只}能绑一个线程；
  但 @{verbatim "WaitingNtfn"} 里装的是列表，等待者\emph{可以有很多个}。
  两者不是一回事：绑定回答"reply/signal 该叫谁"，队列回答"谁在等这个通知"。

  绑定的实现 @{verbatim "bind_notification"}
  （@{verbatim "l4v/spec/abstract/Tcb_A.thy"} 第 135 行）没有任何"已经绑过"的检查，
  它只是把两侧都改写成新值；@{verbatim "seL4/src/object/notification.c"}
  第 380 行的 @{verbatim "bindNotification"} 一字不差地照做。
  反过来，\emph{解绑}才有闸：@{verbatim "decode_unbind_notification"}
  （@{verbatim "l4v/spec/abstract/Decode_A.thy"} 第 365 行）读到
  @{verbatim "None"} 就直接 @{verbatim "throwError IllegalOperation"}。
\<close>

definition bind_notification :: "obj_ref \<Rightarrow> notification \<Rightarrow> notification" where
  "bind_notification t n \<equiv> n\<lparr> ntfn_bound_tcb := Some t \<rparr>"

definition unbind_notification :: "obj_ref \<Rightarrow> notification \<Rightarrow> notification option" where
  "unbind_notification t n \<equiv>
     if ntfn_bound_tcb n = Some t then Some (n\<lparr> ntfn_bound_tcb := None \<rparr>) else None"

lemma bind_sets_the_bound_thread:
  "ntfn_bound_tcb (bind_notification t n) = Some t"
  by (simp add: bind_notification_def)

lemma rebinding_just_moves_it:
  "bind_notification t2 (bind_notification t1 n) = bind_notification t2 n"
  by (simp add: bind_notification_def)

lemma unbinding_an_unbound_thread_is_rejected:
  "ntfn_bound_tcb n = None \<Longrightarrow> unbind_notification t n = None"
  by (simp add: unbind_notification_def)

lemma unbinding_the_bound_thread_succeeds:
  "unbind_notification t (bind_notification t n) = Some (n\<lparr> ntfn_bound_tcb := None \<rparr>)"
  by (simp add: bind_notification_def unbind_notification_def)

lemma bound_field_holds_one_but_queue_holds_many:
  "length (waiting_queue (WaitingNtfn [a, b, c])) = 3"
  by (simp add: waiting_queue_def)

text \<open>
  对照看 @{thm rebinding_just_moves_it} 与
  @{thm bound_field_holds_one_but_queue_holds_many}：
  同一个通知对象上，"绑给谁"是单值、"谁在等"是列表。
  模型里 @{verbatim "None"} 表示被拒绝，对应真实的
  @{verbatim "seL4_IllegalOperation"}。
\<close>

subsection \<open>12.7 Reply 对象与一次性回答\<close>

text \<open>
  @{verbatim "ReplyCap"} 是"回答某一次 Call"的一次性票据。
  它在 @{verbatim "l4v/spec/abstract/CSpace_A.thy"} 第 106 行的
  @{verbatim "derive_cap"} 里派生结果是 @{verbatim "NullCap"}——\emph{不可复制}。
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
  writeln (@{make_string} @{thm combine_idempotent});
  writeln (@{make_string} @{thm receive_takes_the_whole_badge});
  writeln (@{make_string} @{thm reply_is_one_shot})
\<close>

ML \<open>writeln "==== 12 结束 ===="\<close>

end
