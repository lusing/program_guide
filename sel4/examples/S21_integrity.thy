theory S21_integrity
  imports Main
begin

section \<open>21.1 完整性：没人能在没被授权时改动别人的东西\<close>

text \<open>
  seL4 的第一个安全定理叫 \emph{完整性（integrity）}，位于
  @{verbatim "l4v/proof/access-control/"}：@{verbatim "Syscall_AC.thy"}、
  @{verbatim "CNode_AC.thy"}、@{verbatim "Ipc_AC.thy"}、@{verbatim "Finalise_AC.thy"}
  等文件分别证明"每一类系统调用都保持完整性"。

  定理的直觉形式是这样的：

  \begin{quote}
  如果一次状态变化不被某个主体的 authority 授权，那么该主体
  \emph{可观察到的}那部分状态没有变化。
  \end{quote}

  注意"可观察到"四个字：完整性不是"状态没变"，
  而是"\emph{对该主体而言}没变"。
\<close>

ML \<open>writeln "==== 21 开始 ===="\<close>

type_synonym obj_ref = nat
type_synonym subject = nat
type_synonym cnode_index = nat
text \<open>
  槽位在 seL4 里是"对象引用 + 槽号"的二元组
  （真实定义 @{verbatim "cslot_ptr = obj_ref × cnode_index"}，
  本章简化成 @{verbatim "obj_ref × nat"}）。
  主体的 CSpace 根槽记作 @{term "(x, 0)"}。
\<close>
type_synonym cslot = "obj_ref \<times> cnode_index"

datatype rights = AllowRead | AllowWrite | AllowGrant | AllowGrantReply
type_synonym cap_rights = "rights set"

datatype cap = NullCap
             | EndpointCap obj_ref cap_rights
             | NotificationCap obj_ref cap_rights
             | ReplyCap obj_ref bool cap_rights
             | UntypedCap obj_ref

definition cap_rights_of :: "cap \<Rightarrow> cap_rights" where
  "cap_rights_of c \<equiv> case c of EndpointCap _ R \<Rightarrow> R
                         | NotificationCap _ R \<Rightarrow> R
                         | ReplyCap _ _ R \<Rightarrow> R | _ \<Rightarrow> {}"

definition cap_target :: "cap \<Rightarrow> obj_ref option" where
  "cap_target c \<equiv> case c of
      EndpointCap p _ \<Rightarrow> Some p
    | NotificationCap p _ \<Rightarrow> Some p
    | ReplyCap p _ _ \<Rightarrow> Some p
    | UntypedCap p \<Rightarrow> Some p
    | NullCap \<Rightarrow> None"

subsection \<open>21.2 权威（authority）与可观察部分\<close>

record kstate =
  ks_caps :: "cslot \<Rightarrow> cap option"
  ks_data :: "obj_ref \<Rightarrow> nat"

definition authority :: "kstate \<Rightarrow> subject \<Rightarrow> (obj_ref \<times> cap_rights) set" where
  "authority s x \<equiv> {(p, R) | p R c. ks_caps s (x, 0) = Some c \<and>
                                     cap_target c = Some p \<and> R = cap_rights_of c}"

definition authorised :: "kstate \<Rightarrow> subject \<Rightarrow> obj_ref \<Rightarrow> bool" where
  "authorised s x p \<equiv> \<exists>R. (p, R) \<in> authority s x \<and> AllowWrite \<in> R"

lemma no_cap_no_authority:
  "ks_caps s (x, 0) = None \<Longrightarrow> authority s x = {}"
  by (auto simp: authority_def)

lemma null_cap_no_authority:
  "ks_caps s (x, 0) = Some NullCap \<Longrightarrow> authority s x = {}"
  by (auto simp: authority_def cap_target_def cap_rights_of_def split: cap.splits)

lemma read_only_is_not_write_authority:
  "ks_caps s (x, 0) = Some (EndpointCap p {AllowRead}) \<Longrightarrow> \<not> authorised s x p"
  by (auto simp: authorised_def authority_def cap_target_def cap_rights_of_def)

lemma write_right_gives_authority:
  "ks_caps s (x, 0) = Some (EndpointCap p {AllowRead, AllowWrite}) \<Longrightarrow> authorised s x p"
  by (auto simp: authorised_def authority_def cap_target_def cap_rights_of_def)

subsection \<open>21.3 完整性谓词\<close>

text \<open>
  模型里的完整性谓词只比较"数据"那部分状态：
  凡是发生了变化的对象，主体必须有写授权。
\<close>

definition integrity :: "kstate \<Rightarrow> subject \<Rightarrow> kstate \<Rightarrow> bool" where
  "integrity s x s' \<equiv> \<forall>p. ks_data s' p \<noteq> ks_data s p \<longrightarrow> authorised s x p"

lemma integrity_reflexive: "integrity s x s"
  by (simp add: integrity_def)

lemma unauthorised_write_breaks_integrity:
  "ks_data s' p \<noteq> ks_data s p \<Longrightarrow> \<not> authorised s x p \<Longrightarrow> \<not> integrity s x s'"
  by (auto simp: integrity_def)

lemma authorised_writes_are_fine:
  "(\<forall>p. ks_data s' p \<noteq> ks_data s p \<longrightarrow> authorised s x p) \<Longrightarrow> integrity s x s'"
  by (simp add: integrity_def)

subsection \<open>21.4 删除只会减少权威\<close>

definition delete_cap :: "cslot \<Rightarrow> kstate \<Rightarrow> kstate" where
  "delete_cap sl s \<equiv> s\<lparr> ks_caps := (ks_caps s)(sl := None) \<rparr>"

lemma delete_reduces_authority:
  "authority (delete_cap sl s) x \<subseteq> authority s x"
  by (auto simp: authority_def delete_cap_def split: if_splits)

lemma deleting_own_cap_removes_authority:
  "ks_caps s (x, 0) = Some (EndpointCap p R) \<Longrightarrow> authority (delete_cap (x, 0) s) x = {}"
  by (auto simp: authority_def delete_cap_def cap_target_def cap_rights_of_def split: cap.splits)

text \<open>
  @{thm delete_reduces_authority} 是"删除安全"的形式化说法：
  删能力不会让任何人获得新的权威。真实内核里对应的定理是
  @{verbatim "Finalise_AC.thy"} 与 @{verbatim "CNode_AC.thy"} 里的
  @{verbatim "delete_integrity"} 一类结果。
\<close>

subsection \<open>21.5 派生不增加权威\<close>

definition mint :: "cap_rights \<Rightarrow> cap \<Rightarrow> cap" where
  "mint R c \<equiv> case c of EndpointCap p R' \<Rightarrow> EndpointCap p (R' \<inter> R) | _ \<Rightarrow> c"

lemma mint_never_grows_rights:
  "cap_rights_of (mint R c) \<subseteq> cap_rights_of c"
  by (auto simp: mint_def cap_rights_of_def split: cap.splits)

lemma mint_cannot_escalate:
  "AllowWrite \<notin> cap_rights_of c \<Longrightarrow> AllowWrite \<notin> cap_rights_of (mint R c)"
  by (auto simp: mint_def cap_rights_of_def split: cap.splits)

text \<open>
  @{thm mint_cannot_escalate} 就是第 3 章那条"掩码不增权"在安全语言里的说法：
  没有写权利的人，派生不出写权利。整条完整性证明链的最后一步
  都会落到这一类"权利不增长"的引理上。
\<close>

subsection \<open>21.6 权利到权威：照搬真实映射的形状\<close>

text \<open>
  真实策略（@{verbatim "l4v/proof/access-control/Types.thy"}）里的"权威"不是权利，
  而是标号之间的一条带标签的边。把权利翻成权威的函数是
  @{verbatim "cap_rights_to_auth"}（@{verbatim "Access.thy"} 第 107--113 行），
  这里原样搬过来。第二个参数是"这块内存/这个端点是不是同步的"。
\<close>

datatype auth = Control | Receive | SyncSend | Notify | Reset | Grant | Call
                    | Reply | Write | Read | DeleteDerived

definition rights_to_auth :: "cap_rights \<Rightarrow> bool \<Rightarrow> auth set" where
  "rights_to_auth r sync \<equiv>
     {Reset}
   \<union> (if AllowRead \<in> r then {Receive} else {})
   \<union> (if AllowWrite \<in> r then (if sync then {SyncSend} else {Notify}) else {})
   \<union> (if AllowGrant \<in> r then UNIV else {})
   \<union> (if AllowGrantReply \<in> r \<and> AllowWrite \<in> r then {Call} else {})"

lemma reset_conferred_alone: "Reset \<in> rights_to_auth R sync"
  by (simp add: rights_to_auth_def)

lemma grant_confers_everything: "AllowGrant \<in> R \<Longrightarrow> rights_to_auth R sync = UNIV"
  by (auto simp: rights_to_auth_def split: if_split_asm)

lemma write_auth_only_via_grant: "Write \<in> rights_to_auth R sync \<Longrightarrow> AllowGrant \<in> R"
  by (auto simp: rights_to_auth_def split: if_split_asm)

lemma control_auth_only_via_grant: "Control \<in> rights_to_auth R sync \<Longrightarrow> AllowGrant \<in> R"
  by (auto simp: rights_to_auth_def split: if_split_asm)

lemma write_right_gives_syncsend: "AllowWrite \<in> R \<Longrightarrow> SyncSend \<in> rights_to_auth R True"
  by (auto simp: rights_to_auth_def split: if_split_asm)

lemma write_right_gives_notify: "AllowWrite \<in> R \<Longrightarrow> Notify \<in> rights_to_auth R False"
  by (auto simp: rights_to_auth_def split: if_split_asm)

lemma call_needs_grantreply_and_write:
  "Call \<in> rights_to_auth R sync \<Longrightarrow> AllowGrant \<in> R \<or> (AllowGrantReply \<in> R \<and> AllowWrite \<in> R)"
  by (auto simp: rights_to_auth_def split: if_split_asm)

text \<open>
  通知能力在进入这张表之前先被减掉两条权利
  （@{verbatim "Access.thy"} 第 123 行的 @{verbatim "r - {AllowGrant, AllowGrantReply}"}），
  再加上 @{verbatim "sync = False"}：
\<close>

definition ntfn_rights_to_auth :: "cap_rights \<Rightarrow> auth set" where
  "ntfn_rights_to_auth r \<equiv> rights_to_auth (r - {AllowGrant, AllowGrantReply}) False"

lemma ntfn_never_gives_call: "Call \<notin> ntfn_rights_to_auth R"
  by (auto simp: ntfn_rights_to_auth_def rights_to_auth_def split: if_split_asm)

lemma ntfn_never_gives_control: "Control \<notin> ntfn_rights_to_auth R"
  by (auto simp: ntfn_rights_to_auth_def rights_to_auth_def split: if_split_asm)

lemma ntfn_write_gives_notify: "AllowWrite \<in> R \<Longrightarrow> Notify \<in> ntfn_rights_to_auth R"
  by (auto simp: ntfn_rights_to_auth_def rights_to_auth_def split: if_split_asm)

lemma ntfn_bounded: "ntfn_rights_to_auth R \<subseteq> {Reset, Receive, Notify}"
  by (auto simp: ntfn_rights_to_auth_def rights_to_auth_def split: if_split_asm)

text \<open>
  Reply 能力走另一条路（第 115--116 行），注意 master 那一条**不看权利**：
\<close>

definition reply_rights_to_auth :: "bool \<Rightarrow> cap_rights \<Rightarrow> auth set" where
  "reply_rights_to_auth master r \<equiv>
     if AllowGrant \<in> r \<or> master then UNIV else {Reply}"

lemma master_reply_confers_everything: "reply_rights_to_auth True R = UNIV"
  by (simp add: reply_rights_to_auth_def)

lemma non_master_reply_confers_only_reply:
  "AllowGrant \<notin> R \<Longrightarrow> reply_rights_to_auth False R = {Reply}"
  by (auto simp: reply_rights_to_auth_def)

subsection \<open>21.7 一类能力一个权威集合\<close>

text \<open>
  @{verbatim "cap_auth_conferred"}（第 118--131 行）按能力类型分派。
  这里保留玩具能力集里有的那几支；真实表里 @{verbatim "CNodeCap"}
  @{verbatim "ThreadCap"} @{verbatim "DomainCap"} @{verbatim "IRQControlCap"}
  @{verbatim "IRQHandlerCap"} @{verbatim "Zombie"} 全都落在 @{verbatim "{Control}"} 上。
\<close>

definition cap_auth_conferred :: "cap \<Rightarrow> auth set" where
  "cap_auth_conferred cap \<equiv> case cap of
     NullCap \<Rightarrow> {}
   | UntypedCap _ \<Rightarrow> {Control}
   | EndpointCap _ r \<Rightarrow> rights_to_auth r True
   | NotificationCap _ r \<Rightarrow> ntfn_rights_to_auth r
   | ReplyCap _ m r \<Rightarrow> reply_rights_to_auth m r"

lemma nullcap_confers_nothing: "cap_auth_conferred NullCap = {}"
  by (simp add: cap_auth_conferred_def)

lemma untyped_cap_confers_control: "cap_auth_conferred (UntypedCap p) = {Control}"
  by (simp add: cap_auth_conferred_def)

lemma grant_on_endpoint_confers_control:
  "AllowGrant \<in> R \<Longrightarrow> Control \<in> cap_auth_conferred (EndpointCap p R)"
  by (auto simp: cap_auth_conferred_def rights_to_auth_def split: if_split_asm)

lemma ntfn_cap_never_confers_control:
  "Control \<notin> cap_auth_conferred (NotificationCap p R)"
  by (auto simp: cap_auth_conferred_def ntfn_rights_to_auth_def rights_to_auth_def split: if_split_asm)

subsection \<open>21.8 策略自己要先良构\<close>

text \<open>
  @{verbatim "policy_wellformed"}（第 63--77 行）列了九条，这里只搬三条最要紧的。
  第二条"谁都有对自己的一切权威"是 @{verbatim "trm_lrefl"} 那条规则的来源；
  第五条"Call 蕴含 SyncSend"、第三条"Grant 与 Receive 撞在同一个端点上就互为 Control"
  是模型里两条可判定的性质。
\<close>

type_synonym policy = "(subject \<times> auth \<times> subject) set"

definition auth_to :: "policy \<Rightarrow> subject set \<Rightarrow> auth \<Rightarrow> subject \<Rightarrow> bool" where
  "auth_to P subs auth l \<equiv> \<exists>s \<in> subs. (s, auth, l) \<in> P"

definition wf_policy :: "subject \<Rightarrow> policy \<Rightarrow> bool" where
  "wf_policy agent P \<equiv>
     (\<forall>a. (agent, a, agent) \<in> P)
   \<and> (\<forall>s ep. (s, Call, ep) \<in> P \<longrightarrow> (s, SyncSend, ep) \<in> P)
   \<and> (\<forall>s r ep. (s, Grant, ep) \<in> P \<and> (r, Receive, ep) \<in> P
                \<longrightarrow> (s, Control, r) \<in> P \<and> (r, Control, s) \<in> P)"

lemma self_has_all_authority: "wf_policy agent P \<Longrightarrow> auth_to P {agent} Write agent"
  by (auto simp: wf_policy_def auth_to_def)

lemma call_edge_brings_a_syncsend_edge:
  "wf_policy agent P \<Longrightarrow> auth_to P subs Call l \<Longrightarrow> auth_to P subs SyncSend l"
  by (auto simp: wf_policy_def auth_to_def)

lemma grant_and_receive_make_peers:
  "wf_policy agent P \<Longrightarrow> auth_to P subs Grant ep \<Longrightarrow> auth_to P subs' Receive ep
   \<Longrightarrow> \<exists>s \<in> subs. \<exists>r \<in> subs'. (s, Control, r) \<in> P \<and> (r, Control, s) \<in> P"
  unfolding wf_policy_def auth_to_def
  by blast

subsection \<open>21.9 能在主体之间流动的只有三种槽内容\<close>

text \<open>
  @{verbatim "is_transferable"}（第 152--155 行）只有三条引入规则：
  空槽、@{verbatim "NullCap"}、以及**非 master** 的 reply 能力。
\<close>

inductive transferable :: "cap option \<Rightarrow> bool" where
  tf_None: "opt = None \<Longrightarrow> transferable opt"
| tf_Null: "opt = Some NullCap \<Longrightarrow> transferable opt"
| tf_Reply: "opt = Some (ReplyCap t False R) \<Longrightarrow> transferable opt"

lemma transferable_empty_slot: "transferable None"
  by (auto simp: transferable.simps)

lemma transferable_null_cap: "transferable (Some NullCap)"
  by (auto simp: transferable.simps)

lemma transferable_non_master_reply: "transferable (Some (ReplyCap t False R))"
  by (auto simp: transferable.simps)

lemma master_reply_not_transferable: "\<not> transferable (Some (ReplyCap t True R))"
  by (auto simp: transferable.simps)

lemma endpoint_not_transferable: "\<not> transferable (Some (EndpointCap p R))"
  by (auto simp: transferable.simps)

lemma untyped_not_transferable: "\<not> transferable (Some (UntypedCap p))"
  by (auto simp: transferable.simps)

lemma transferable_exhausted:
  "transferable opt \<Longrightarrow> opt = None \<or> opt = Some NullCap
                        \<or> (\<exists>t R. opt = Some (ReplyCap t False R))"
  by (auto simp: transferable.simps)

subsection \<open>21.10 内存可以被改动的五种理由\<close>

text \<open>
  @{verbatim "integrity_mem"}（第 831--844 行）是五条引入规则。
  参数顺序照真实定义：@{verbatim "lab"} 是 @{verbatim "pasObjectAbs"}，
  @{verbatim "has"} 是"某主体对某指针有 Write 权威"，
  @{verbatim "can_recv"} 是 @{verbatim "can_receive_ipc"}，
  @{verbatim "running"} 是终止态那个 @{verbatim "ts' p' = Some Running"}，
  @{verbatim "ipcbufs"} 是 IPC 缓冲表，@{verbatim "globals"} 是那条已废弃的旁路。
\<close>

definition mem_ok ::
  "(obj_ref \<Rightarrow> subject) \<Rightarrow> (subject \<Rightarrow> obj_ref \<Rightarrow> bool) \<Rightarrow> subject set
     \<Rightarrow> (obj_ref \<Rightarrow> bool) \<Rightarrow> (obj_ref \<Rightarrow> bool) \<Rightarrow> (obj_ref \<Rightarrow> obj_ref set)
     \<Rightarrow> obj_ref set \<Rightarrow> obj_ref \<Rightarrow> obj_ref \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> bool" where
  "mem_ok lab has subs can_recv running ipcbufs globals p p' w w' \<equiv>
     lab p \<in> subs
   \<or> w = w'
   \<or> (\<exists>s \<in> subs. has s p)
   \<or> p \<in> globals
   \<or> (can_recv p' \<and> running p' \<and> p \<in> ipcbufs p' \<and> lab p' \<notin> subs)"

lemma mem_ok_owned:
  "lab p \<in> subs \<Longrightarrow> mem_ok lab has subs can_recv running ipcbufs globals p p' w w'"
  by (simp add: mem_ok_def)

lemma mem_ok_unchanged:
  "w = w' \<Longrightarrow> mem_ok lab has subs can_recv running ipcbufs globals p p' w w'"
  by (simp add: mem_ok_def)

lemma mem_ok_write_auth:
  "(\<exists>s \<in> subs. has s p) \<Longrightarrow> mem_ok lab has subs can_recv running ipcbufs globals p p' w w'"
  by (simp add: mem_ok_def)

lemma mem_ok_globals:
  "p \<in> globals \<Longrightarrow> mem_ok lab has subs can_recv running ipcbufs globals p p' w w'"
  by (simp add: mem_ok_def)

lemma mem_ok_ipc_buffer:
  "\<lbrakk>can_recv p'; running p'; p \<in> ipcbufs p'; lab p' \<notin> subs\<rbrakk>
   \<Longrightarrow> mem_ok lab has subs can_recv running ipcbufs globals p p' w w'"
  by (simp add: mem_ok_def)

lemma mem_ok_only_five_reasons:
  "mem_ok lab has subs can_recv running ipcbufs globals p p' w w' \<Longrightarrow>
     lab p \<in> subs \<or> w = w' \<or> (\<exists>s \<in> subs. has s p) \<or> p \<in> globals
   \<or> (can_recv p' \<and> running p' \<and> p \<in> ipcbufs p' \<and> lab p' \<notin> subs)"
  by (simp add: mem_ok_def)

text \<open>
  前四条对 @{verbatim "subs"} 单调，第五条带一个 @{verbatim "\<notin>"}，
  所以整条关系**不**单调：把接收者所在那一组主体加进 @{verbatim "subs"}，
  一个先前合法的改动可以变成不合法。
\<close>

definition mem_ok4 ::
  "(obj_ref \<Rightarrow> subject) \<Rightarrow> (subject \<Rightarrow> obj_ref \<Rightarrow> bool) \<Rightarrow> subject set
     \<Rightarrow> (obj_ref \<Rightarrow> bool) \<Rightarrow> (obj_ref \<Rightarrow> bool) \<Rightarrow> (obj_ref \<Rightarrow> obj_ref set)
     \<Rightarrow> obj_ref set \<Rightarrow> obj_ref \<Rightarrow> obj_ref \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> bool" where
  "mem_ok4 lab has subs can_recv running ipcbufs globals p p' w w' \<equiv>
     lab p \<in> subs \<or> w = w' \<or> (\<exists>s \<in> subs. has s p) \<or> p \<in> globals"

lemma mem_ok4_monotone_in_subjects:
  "\<lbrakk>subs \<subseteq> subs'; mem_ok4 lab has subs can_recv running ipcbufs globals p p' w w'\<rbrakk>
   \<Longrightarrow> mem_ok4 lab has subs' can_recv running ipcbufs globals p p' w w'"
  by (auto simp: mem_ok4_def)

lemma mem_ok4_is_mem_ok:
  "mem_ok4 lab has subs can_recv running ipcbufs globals p p' w w'
   \<Longrightarrow> mem_ok lab has subs can_recv running ipcbufs globals p p' w w'"
  by (auto simp: mem_ok_def mem_ok4_def)

text \<open>
  下面这四个常量是给"非单调"这件事造的一个具体反例：指针 7 属于 9 号主体，
  3 号线程正在那个端点上等消息，它的 IPC 缓冲就是 7 号页。
\<close>

definition lab3 :: "obj_ref \<Rightarrow> subject" where
  "lab3 \<equiv> \<lambda>x. if x = (3::nat) then 3 else 9"

definition has0 :: "subject \<Rightarrow> obj_ref \<Rightarrow> bool" where
  "has0 \<equiv> \<lambda>_ _. False"

definition recv3 :: "obj_ref \<Rightarrow> bool" where
  "recv3 \<equiv> \<lambda>x. x = (3::nat)"

definition ipc3 :: "obj_ref \<Rightarrow> obj_ref set" where
  "ipc3 \<equiv> \<lambda>x. if x = (3::nat) then {7} else {}"

theorem mem_ok_by_the_ipc_rule_with_no_subjects:
  "mem_ok lab3 has0 {} recv3 recv3 ipc3 {} 7 3 0 1"
  by (auto simp: mem_ok_def lab3_def has0_def recv3_def ipc3_def)

theorem mem_ok_blocked_once_the_receiver_is_a_subject:
  "\<not> mem_ok lab3 has0 {3} recv3 recv3 ipc3 {} 7 3 0 1"
  by (auto simp: mem_ok_def lab3_def has0_def recv3_def ipc3_def)

theorem mem_ok_is_not_monotone_in_subjects:
  "\<exists>subs subs'. subs \<subset> subs'
     \<and> mem_ok lab3 has0 subs recv3 recv3 ipc3 {} (7::nat) 3 0 1
     \<and> \<not> mem_ok lab3 has0 subs' recv3 recv3 ipc3 {} 7 3 0 1"
  by (rule exI[where x="{}"], rule exI[where x="{3}"],
      auto simp: mem_ok_def lab3_def has0_def recv3_def ipc3_def)

subsection \<open>21.11 设备内存没有 IPC 这条例外\<close>

text \<open>
  @{verbatim "integrity_device"}（第 849--855 行）只有三条规则：自己的、没变的、
  有 Write 权威的。
\<close>

definition dev_ok ::
  "(obj_ref \<Rightarrow> subject) \<Rightarrow> (subject \<Rightarrow> obj_ref \<Rightarrow> bool) \<Rightarrow> subject set
     \<Rightarrow> obj_ref \<Rightarrow> nat \<Rightarrow> nat \<Rightarrow> bool" where
  "dev_ok lab has subs p w w' \<equiv>
     lab p \<in> subs \<or> w = w' \<or> (\<exists>s \<in> subs. has s p)"

lemma dev_ok_is_mem_ok4:
  "dev_ok lab has subs p w w'
   \<Longrightarrow> mem_ok4 lab has subs can_recv running ipcbufs globals p p' w w'"
  by (auto simp: dev_ok_def mem_ok4_def)

theorem the_same_write_is_mem_ok_but_not_dev_ok:
  "mem_ok lab3 has0 {} recv3 recv3 ipc3 {} 7 3 0 1
   \<and> \<not> dev_ok lab3 has0 {} (7::nat) 0 1"
  by (auto simp: mem_ok_def dev_ok_def lab3_def has0_def recv3_def ipc3_def)

subsection \<open>21.12 派生树：reply 槽是唯一不需要所有权的例外\<close>

text \<open>
  @{verbatim "cdt_direct_change_allowed"}（第 739--744 行）两条规则，
  第二条要求槽号正好是 @{verbatim "tcb_cnode_index 3"}。
\<close>

definition cdt_direct_ok ::
  "(obj_ref \<Rightarrow> subject) \<Rightarrow> subject set \<Rightarrow> (obj_ref \<Rightarrow> bool) \<Rightarrow> nat \<Rightarrow> cslot \<Rightarrow> bool" where
  "cdt_direct_ok lab subs called rslot sl \<equiv>
     lab (fst sl) \<in> subs \<or> (called (fst sl) \<and> snd sl = rslot)"

lemma cdt_other_slot_needs_ownership:
  "snd sl \<noteq> rslot \<Longrightarrow> cdt_direct_ok lab subs called rslot sl \<Longrightarrow> lab (fst sl) \<in> subs"
  by (auto simp: cdt_direct_ok_def)

lemma cdt_reply_slot_needs_no_ownership:
  "called p \<Longrightarrow> cdt_direct_ok lab subs called rslot (p, rslot)"
  by (auto simp: cdt_direct_ok_def)

lemma cdt_reply_slot_rule_works_for_empty_subjects:
  "cdt_direct_ok lab {} called rslot (p, rslot) = called p"
  by (auto simp: cdt_direct_ok_def)

ML \<open>
  writeln (@{make_string} @{thm delete_reduces_authority});
  writeln (@{make_string} @{thm mint_cannot_escalate});
  writeln (@{make_string} @{thm grant_confers_everything});
  writeln (@{make_string} @{thm ntfn_never_gives_call});
  writeln (@{make_string} @{thm master_reply_not_transferable})
\<close>

ML \<open>writeln "==== 21 结束 ===="\<close>

end
