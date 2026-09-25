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

subsection \<open>11.5 badge：区分发送方，但\emph{不}决定能不能发\<close>

text \<open>
  端点能力上带一个 @{verbatim "badge"}（徽章）。发送时接收方看到的徽章
  来自\emph{能力本身}，不是用户参数：@{verbatim "l4v/spec/abstract/Decode_A.thy"}
  第 632--634 行把端点能力解成
  @{verbatim "InvokeEndpoint ptr badge (AllowGrant \<in> rights) (AllowGrantReply \<in> rights)"}。

  一条常见误传要在这里纠正：**徽章为 0 并不阻止发送**。能不能发由\emph{权利位}
  决定——C 侧是端点能力的 @{verbatim "capCanSend"} 一位
  （@{verbatim "seL4/include/object/structures_32.bf"} 第 28 行的位域
  @{verbatim "endpoint_cap(capEPBadge, capCanGrantReply, capCanGrant, capCanSend, \<dots>)"}），
  Isabelle 侧就是 @{verbatim "AllowSend"}，而它按第 03 章等于 @{verbatim "AllowWrite"}。
  取徽章的工具函数是 @{verbatim "cap_ep_badge"}，定义在
  @{verbatim "l4v/spec/abstract/Structures_A.thy"} 第 141 行；
  mint 时把徽章打上去的是 @{verbatim "update_cap_data"}，在
  @{verbatim "l4v/spec/abstract/CSpace_A.thy"} 第 122 行。
\<close>

datatype rights = AllowRead | AllowWrite | AllowGrant | AllowGrantReply

type_synonym cap_rights = "rights set"

type_synonym badge = nat

datatype ep_cap = EndpointCap nat badge cap_rights

definition AllowSend :: rights where "AllowSend \<equiv> AllowWrite"

definition can_send :: "ep_cap \<Rightarrow> bool" where
  "can_send c \<equiv> case c of EndpointCap _ _ R \<Rightarrow> AllowSend \<in> R"

lemma zero_badge_still_sends: "can_send (EndpointCap ptr 0 {AllowSend})"
  by (simp add: can_send_def AllowSend_def)

lemma no_right_blocks_sending: "AllowWrite \<notin> R \<Longrightarrow> \<not> can_send (EndpointCap ptr b R)"
  by (auto simp: can_send_def AllowSend_def)

text \<open>
  徽章真正触发的是另一件事：@{verbatim "seL4_CNode_CancelBadgedSends"}。
  它的解码闸是 @{verbatim "has_cancel_send_rights"}
  （@{verbatim "l4v/spec/abstract/CSpace_A.thy"} 第 787 行），条件苛刻——
  权利集必须等于全集；执行那一支则是
  @{verbatim "CancelBadgedSendsCall (EndpointCap ep b R) \<Rightarrow> without_preemption $ when (b \<noteq> 0) $ cancel_badged_sends ep b"}（同文件第 838 行）。
  换句话说：\emph{只有"全权利 + 有徽章"的那一份能力能取消别人排队的发送}。
\<close>

definition has_cancel_send_rights :: "ep_cap \<Rightarrow> bool" where
  "has_cancel_send_rights c \<equiv> case c of EndpointCap _ _ R \<Rightarrow> R = UNIV"

definition cancels_pending_sends :: "ep_cap \<Rightarrow> bool" where
  "cancels_pending_sends c \<equiv>
     case c of EndpointCap _ b R \<Rightarrow> R = UNIV \<and> b \<noteq> 0"

lemma unbadged_full_cap_cancels_nothing:
  "\<not> cancels_pending_sends (EndpointCap ptr 0 UNIV)"
  by (simp add: cancels_pending_sends_def)

lemma badged_full_cap_cancels:
  "cancels_pending_sends (EndpointCap ptr 7 UNIV)"
  by (simp add: cancels_pending_sends_def)

lemma reduced_rights_cannot_cancel:
  "R \<noteq> UNIV \<Longrightarrow> \<not> cancels_pending_sends (EndpointCap ptr b R)"
  by (simp add: cancels_pending_sends_def)

text \<open>
  @{thm zero_badge_still_sends} 与 @{thm unbadged_full_cap_cancels_nothing}
  放在一起才是徽章的完整语义：0 号徽章是"没有身份标记"，
  它让\emph{取消}失去对象，但从不关闭\emph{发送}。
\<close>

ML \<open>
  writeln (@{make_string} @{thm send_preserves_well_formed});
  writeln (@{make_string} @{thm send_to_receiver_delivers})
\<close>

ML \<open>writeln "==== 11 结束 ===="\<close>

end
