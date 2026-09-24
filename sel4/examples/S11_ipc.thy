theory S11_ipc
  imports Main
begin

section \<open>11.1 端点：同步的汇合点\<close>

text \<open>
  端点是 seL4 里唯一的同步 IPC 对象。它的状态只有三种
  （@{verbatim "l4v/spec/abstract/Structures_A.thy"} 第 294 行）：

  @{verbatim "datatype endpoint = IdleEP | SendEP (obj_ref list) | RecvEP (obj_ref list)"}

  关键约束：\emph{发送队列与接收队列不会同时非空}。两端都在等的时候
  消息是直接交接的（@{verbatim "Ipc_A.thy"} 第 298 行的
  @{verbatim "send_ipc"} 会先看有没有接收者在等）。

  C 侧对应的是 @{verbatim "seL4/src/object/endpoint.c"}：
  @{verbatim "sendIPC"}（第 20 行）与 @{verbatim "receiveIPC"}（第 134 行）。
\<close>

ML \<open>writeln "==== 11 开始 ===="\<close>

type_synonym obj_ref = nat

datatype endpoint = IdleEP | SendEP "obj_ref list" | RecvEP "obj_ref list"

definition ep_well_formed :: "endpoint \<Rightarrow> bool" where
  "ep_well_formed ep \<equiv> case ep of
      IdleEP    \<Rightarrow> True
    | SendEP qs \<Rightarrow> qs \<noteq> []
    | RecvEP qr \<Rightarrow> qr \<noteq> []"

lemma idle_is_well_formed: "ep_well_formed IdleEP"
  by (simp add: ep_well_formed_def)

lemma empty_send_queue_not_well_formed: "\<not> ep_well_formed (SendEP [])"
  by (simp add: ep_well_formed_def)

subsection \<open>11.2 发送：有接收者就交接，没有就排队\<close>

text \<open>
  @{verbatim "send_ipc"} 的语义：端点上若有接收者在等，直接把消息交给队首；
  否则把自己挂到发送队列上并阻塞（除非是非阻塞发送）。
\<close>

datatype send_result = Delivered obj_ref | Queued | Dropped

definition send_ipc :: "bool \<Rightarrow> endpoint \<Rightarrow> obj_ref \<Rightarrow> (endpoint \<times> send_result)" where
  "send_ipc blocking ep thread \<equiv> case ep of
      RecvEP (r # rest) \<Rightarrow> (if rest = [] then IdleEP else RecvEP rest, Delivered r)
    | RecvEP []         \<Rightarrow> (IdleEP, Queued)
    | SendEP qs         \<Rightarrow> (SendEP (qs @ [thread]), Queued)
    | IdleEP            \<Rightarrow> (if blocking then (SendEP [thread], Queued)
                               else (IdleEP, Dropped))"

lemma send_to_receiver_delivers:
  "send_ipc True (RecvEP [r]) t = (IdleEP, Delivered r)"
  by (simp add: send_ipc_def)

lemma send_to_two_receivers_keeps_queue:
  "send_ipc True (RecvEP [r1, r2]) t = (RecvEP [r2], Delivered r1)"
  by (simp add: send_ipc_def)

lemma send_to_idle_blocks:
  "send_ipc True IdleEP t = (SendEP [t], Queued)"
  by (simp add: send_ipc_def)

lemma nonblocking_send_to_idle_drops:
  "send_ipc False IdleEP t = (IdleEP, Dropped)"
  by (simp add: send_ipc_def)

lemma send_to_sender_queues:
  "send_ipc True (SendEP [s]) t = (SendEP [s, t], Queued)"
  by (simp add: send_ipc_def)

subsection \<open>11.3 接收：对称的另一半\<close>

definition receive_ipc :: "bool \<Rightarrow> endpoint \<Rightarrow> obj_ref \<Rightarrow> (endpoint \<times> send_result)" where
  "receive_ipc blocking ep thread \<equiv> case ep of
      SendEP (s # rest) \<Rightarrow> (if rest = [] then IdleEP else SendEP rest, Delivered s)
    | SendEP []         \<Rightarrow> (IdleEP, Queued)
    | RecvEP qr         \<Rightarrow> (RecvEP (qr @ [thread]), Queued)
    | IdleEP            \<Rightarrow> (if blocking then (RecvEP [thread], Queued)
                               else (IdleEP, Dropped))"

lemma recv_from_sender_delivers:
  "receive_ipc True (SendEP [s]) t = (IdleEP, Delivered s)"
  by (simp add: receive_ipc_def)

lemma recv_on_idle_blocks:
  "receive_ipc True IdleEP t = (RecvEP [t], Queued)"
  by (simp add: receive_ipc_def)

lemma nonblocking_recv_on_idle_fails:
  "receive_ipc False IdleEP t = (IdleEP, Dropped)"
  by (simp add: receive_ipc_def)

subsection \<open>11.4 井形性在状态转移下保持\<close>

text \<open>
  这是本章唯一一条"像样的"定理：从井形的端点出发，
  发送与接收之后仍然是井形的。真实证明里这一条会被写成
  @{verbatim "valid_objs"} 的一部分（第 17 章）。
\<close>

lemma send_preserves_well_formed:
  "ep_well_formed ep \<Longrightarrow> ep_well_formed (fst (send_ipc b ep t))"
  by (auto simp: send_ipc_def ep_well_formed_def split: endpoint.splits list.splits)

lemma receive_preserves_well_formed:
  "ep_well_formed ep \<Longrightarrow> ep_well_formed (fst (receive_ipc b ep t))"
  by (auto simp: receive_ipc_def ep_well_formed_def split: endpoint.splits list.splits)

text \<open>
  注意 @{verbatim "SendEP []"} 与 @{verbatim "RecvEP []"} 都被判为不井形：
  空队列应当写成 @{verbatim "IdleEP"}。这两种写法在真实内核里是同一个状态，
  规范用"井形性"逼着实现不要产生第二种写法。
\<close>

subsection \<open>11.5 badge：区分发送方\<close>

text \<open>
  端点能力上带一个 @{verbatim "badge"}（徽章）。带 badge 的能力派生出的
  副本在发送消息时，接收方会看到这个 badge，从而知道"是谁发的"。
  没有 badge（@{verbatim "badge = 0"}）的端点能力不能用于发送。

  @{verbatim "Ipc_A.thy"} 里 @{verbatim "cap_ep_badge"} 取这个值，
  @{verbatim "Decode_A.thy"} 的 @{verbatim "update_cap_data"} 在 mint 时把它打上去。
\<close>

type_synonym badge = nat

definition can_send :: "badge \<Rightarrow> bool" where
  "can_send b \<equiv> b \<noteq> 0"

lemma unbadged_cannot_send: "\<not> can_send 0"
  by (simp add: can_send_def)

lemma badged_can_send: "can_send 42"
  by (simp add: can_send_def)

text \<open>
  "0 号 badge 不能发送"这条规则看似小，却是 seL4 认证里"身份不可伪造"
  的关键一环：只有持有带 badge 能力的一方才能以该身份发言。
\<close>

ML \<open>
  writeln (@{make_string} @{thm send_preserves_well_formed});
  writeln (@{make_string} @{thm send_to_receiver_delivers})
\<close>

ML \<open>writeln "==== 11 结束 ===="\<close>

end
