theory S10_decode
  imports Main
begin

section \<open>10.1 decode：把用户字变成内核结构\<close>

text \<open>
  用户调用内核时给的是"一个标签 + 若干个机器字"。把它们变成
  @{verbatim "invocation"} 结构的过程叫 \emph{decode}，全部集中在
  @{verbatim "l4v/spec/abstract/Decode_A.thy"}。该文件开头写得很清楚：

  "these definitions check the validity of these arguments,
   throwing an error if given an invalid request" ——
  解码\emph{同时}就是检查。

  标签的合法性检查用 @{verbatim "gen_invocation_type"}
  （@{verbatim "l4v/spec/abstract/InvocationLabels_A.thy"} 第 26 行）完成，
  它把越界的数字压成 @{verbatim "InvalidInvocation"}。
\<close>

ML \<open>writeln "==== 10 开始 ===="\<close>

datatype rights = AllowRead | AllowWrite | AllowGrant | AllowGrantReply

type_synonym cap_rights = "rights set"

datatype cnode_label = CNodeRevoke | CNodeDelete | CNodeCopy | CNodeMint
                     | CNodeMove | CNodeMutate | CNodeSaveCaller
                     | InvalidInvocation

definition gen_invocation_type :: "nat \<Rightarrow> cnode_label" where
  "gen_invocation_type x \<equiv> if x < 7 then
       [CNodeRevoke, CNodeDelete, CNodeCopy, CNodeMint,
        CNodeMove, CNodeMutate, CNodeSaveCaller] ! x
     else InvalidInvocation"

lemma label_mint: "gen_invocation_type 3 = CNodeMint"
  by (simp add: gen_invocation_type_def)

lemma label_copy: "gen_invocation_type 2 = CNodeCopy"
  by (simp add: gen_invocation_type_def)

lemma label_out_of_range: "gen_invocation_type 7 = InvalidInvocation"
  by (simp add: gen_invocation_type_def)

text \<open>
  @{thm label_out_of_range} 是"越界即非法"的模板：真实定义用的是
  @{verbatim "toEnum"} / @{verbatim "fromEnum"} 加一个
  @{verbatim "if \<exists>v. fromEnum v = data_to_nat x"} 的存在性检查，
  效果一样——不认识的标签一律 @{verbatim "InvalidInvocation"}，
  而不会让 @{verbatim "toEnum"} 抛异常。
\<close>

subsection \<open>10.2 一次完整的 CNode 解码\<close>

text \<open>
  @{verbatim "Decode_A.thy"} 第 49 行的
  @{verbatim "decode_cnode_invocation label args cap excaps"} 骨架是四步：查标签 → 查参数个数 → 查目标槽 →（复制类操作）查源槽、
  解权利、掩码、派生。模型按这个顺序写一遍。
\<close>

datatype cap = NullCap | EndpointCap nat nat cap_rights | UntypedCap nat

type_synonym cslot = nat

definition cap_rights_of :: "cap \<Rightarrow> cap_rights" where
  "cap_rights_of c \<equiv> case c of EndpointCap _ _ R \<Rightarrow> R | _ \<Rightarrow> {}"

definition mask_cap :: "cap_rights \<Rightarrow> cap \<Rightarrow> cap" where
  "mask_cap R c \<equiv> case c of EndpointCap p b R' \<Rightarrow> EndpointCap p b (R' \<inter> R) | _ \<Rightarrow> c"

datatype ('a,'e) decode_result = DResult 'a | DError 'e

datatype syscall_error = IllegalOperation | TruncatedMessage | DeleteFirst | FailedLookup

type_synonym rights_word = "bool \<times> bool \<times> bool \<times> bool"

definition data_to_rights :: "rights_word \<Rightarrow> cap_rights" where
  "data_to_rights w \<equiv> case w of (gr, gw, rd, wr) \<Rightarrow>
     (if rd then {AllowRead} else {}) \<union>
     (if wr then {AllowWrite} else {}) \<union>
     (if gr then {AllowGrant} else {}) \<union>
     (if gw then {AllowGrantReply} else {})"

datatype cnode_invocation =
    RevokeCall cslot
  | DeleteCall cslot
  | InsertCall cap cslot cslot
  | MoveCall cap cslot cslot

record decode_ctx =
  dc_dest_slot :: cslot
  dc_src_slot  :: cslot
  dc_src_cap   :: cap

definition decode_cnode_invocation ::
  "nat \<Rightarrow> nat list \<Rightarrow> decode_ctx \<Rightarrow> (cnode_invocation, syscall_error) decode_result" where
  "decode_cnode_invocation label args ctx \<equiv>
     let lab = gen_invocation_type label in
     if lab = InvalidInvocation then DError IllegalOperation
     else if length args < 2 then DError TruncatedMessage
     else if lab = CNodeRevoke then DResult (RevokeCall (dc_dest_slot ctx))
     else if lab = CNodeDelete then DResult (DeleteCall (dc_dest_slot ctx))
     else let rw = data_to_rights (True, False, True, False) in
          if lab = CNodeMove
          then DResult (MoveCall (dc_src_cap ctx) (dc_src_slot ctx) (dc_dest_slot ctx))
          else DResult (InsertCall (mask_cap rw (dc_src_cap ctx))
                                  (dc_src_slot ctx) (dc_dest_slot ctx))"

text \<open>
  注意 @{verbatim "decode_cnode_invocation"} 的类型：返回值是
  @{verbatim "(cnode_invocation, syscall_error) Result"}，
  即"要么得到一个内部结构，要么得到一个错误码"。真实定义里它是
  @{verbatim "se_monad"}（第 8 章的错误单子），因为解码过程中还要读状态
  （查槽位）。模型把它做成纯函数，代价是丢掉了"解码会读内核状态"这一点。
\<close>

lemma decode_bad_label:
  "gen_invocation_type label = InvalidInvocation \<Longrightarrow>
   decode_cnode_invocation label args ctx = DError IllegalOperation"
  by (simp add: decode_cnode_invocation_def Let_def)

lemma decode_truncated:
  "gen_invocation_type label = CNodeCopy \<Longrightarrow> length args < 2 \<Longrightarrow>
   decode_cnode_invocation label args ctx = DError TruncatedMessage"
  by (simp add: decode_cnode_invocation_def Let_def)

lemma decode_revoke:
  "gen_invocation_type label = CNodeRevoke \<Longrightarrow> length args \<ge> 2 \<Longrightarrow>
   decode_cnode_invocation label args ctx = DResult (RevokeCall (dc_dest_slot ctx))"
  by (simp add: decode_cnode_invocation_def Let_def)

subsection \<open>10.3 权利：解码之后必须掩码\<close>

text \<open>
  这是本章最该记住的一条：用户给的权利字只是"请求"，
  真正生效的是 @{verbatim "mask_cap rights src_cap"} 之后的结果。
  少了这一步，用户就能给自己签发任意权利。
\<close>

lemma mask_never_grows:
  "cap_rights_of (mask_cap R c) \<subseteq> cap_rights_of c"
  by (auto simp: mask_cap_def cap_rights_of_def split: cap.splits)

lemma minted_rights_subset_of_request:
  "cap_rights_of (mask_cap R (EndpointCap p b R')) \<subseteq> R"
  by (auto simp: mask_cap_def cap_rights_of_def)

lemma move_keeps_rights:
  "cap_rights_of (dc_src_cap ctx) = R \<Longrightarrow>
   cap_rights_of (mask_cap UNIV (dc_src_cap ctx)) = R"
  by (auto simp: mask_cap_def cap_rights_of_def split: cap.splits)

text \<open>
  最后一条对应 @{verbatim "CNodeMove"} 的实现细节：移动不削权，
  所以解码时直接取 @{verbatim "all_rights"} 作掩码。
  代价是移动之后源槽被清空——"权利守恒"靠的是源槽消失，不是掩码。
\<close>

subsection \<open>10.4 接收窗口与 extra caps：全有或全无\<close>

text \<open>
  这里有两条不同的通道，别混在一起：

  \begin{itemize}
    \item \emph{发送方}随消息带来的 extra caps：@{verbatim "lookup_extra_caps"}
          （@{verbatim "Ipc_A.thy"} 第 64 行）把消息缓冲里的每个 CPtr 在
          \emph{发送者}的 CSpace 里解析一遍（@{verbatim "mapME"} 配
          @{verbatim "lookup_cap_and_slot"}。第 212 行调用它时写的是
          @{verbatim "if grant then lookup_extra_caps sender sbuf mi <catch> K (return [])"}
          ——没有 grant 就一个都不传，解析中途失败就把整表清空。
    \item \emph{接收方}的接收窗口：@{verbatim "get_receive_slots"}
          （@{verbatim "l4v/spec/abstract/CSpace_A.thy"} 第 292 行）只解析
          \emph{一个}槽，而且要求那个槽当下就是 @{verbatim "NullCap"}，
          整段被 @{verbatim "empty_on_failure"} 包着：任何一步出错就返回空表。
  \end{itemize}

  模型保留的是两边共有的那条性质——"全有或全无"：
\<close>

datatype resolve = Resolved cslot | NotFound | AlreadyFilled

definition get_receive_slots :: "resolve \<Rightarrow> cslot list" where
  "get_receive_slots r \<equiv> case r of Resolved s \<Rightarrow> [s] | _ \<Rightarrow> []"

lemma receive_window_holds_at_most_one_slot:
  "length (get_receive_slots r) \<le> 1"
  by (cases r) (auto simp: get_receive_slots_def)

lemma filled_target_yields_no_window:
  "get_receive_slots AlreadyFilled = []"
  by (simp add: get_receive_slots_def)

lemma failed_lookup_yields_no_window:
  "get_receive_slots NotFound = []"
  by (simp add: get_receive_slots_def)

lemma only_a_clean_resolve_yields_a_slot:
  "get_receive_slots r = [s] \<longleftrightarrow> r = Resolved s"
  by (cases r) (auto simp: get_receive_slots_def)

text \<open>
  @{thm only_a_clean_resolve_yields_a_slot} 说的是"部分成功"在这套接口里
  \emph{根本没有表示}：要么给出那一个槽，要么什么都没有。
  这是 seL4 的一贯取舍——宁可少给，不可多给。
  发送方那一路的"没有 grant 就不传能力"是同一取向的另一半。
\<close>

ML \<open>
  writeln (@{make_string} @{thm decode_bad_label});
  writeln (@{make_string} @{thm minted_rights_subset_of_request})
\<close>

ML \<open>writeln "==== 10 结束 ===="\<close>

end
