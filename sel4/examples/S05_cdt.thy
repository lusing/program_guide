theory S05_cdt
  imports Main
begin

section \<open>5.1 CDT：能力派生树\<close>

text \<open>
  除了"哪个槽里放着什么"，内核还维护一张 \emph{CDT（Capability Derivation
  Tree，能力派生树）}：记录"这个槽里的能力是从哪个槽派生来的"。真实类型是
  @{verbatim "l4v/spec/abstract/Structures_A.thy"} 第 532 行的一张部分函数：

  @{verbatim "type_synonym cdt = cslot_ptr => cslot_ptr option"}

  @{verbatim "cdt c = Some p"} 表示 p 是 c 的父亲。读这张表的工具函数都在
  @{verbatim "l4v/spec/abstract/CSpaceAcc_A.thy"}：@{verbatim "is_cdt_parent"}
  （第 109 行）、@{verbatim "cdt_parent_rel"}（第 113 行）、
  @{verbatim "descendants_of"}（第 144 行，取传递闭包）。

  为什么要有它：\emph{撤销（revoke）}需要"把这个能力的所有子孙一次删干净"。
  没有派生树，内核就得遍历整张 CSpace 才能找出谁是谁的副本。
\<close>

ML \<open>writeln "==== 05 开始 ===="\<close>

type_synonym obj_ref = nat
type_synonym cnode_index = "bool list"
type_synonym cslot_ptr = "obj_ref \<times> cnode_index"
type_synonym cdt = "cslot_ptr \<Rightarrow> cslot_ptr option"

datatype rights = AllowRead | AllowWrite | AllowGrant | AllowGrantReply

type_synonym cap_rights = "rights set"

datatype cap =
    NullCap
  | EndpointCap obj_ref nat cap_rights
  | NotificationCap obj_ref nat cap_rights
  | ReplyCap obj_ref cap_rights
  | UntypedCap obj_ref nat nat
  | ThreadCap obj_ref
  | IRQControlCap

text \<open>
  一个容易踩的坑：l4v 里 @{verbatim "cap_rights"} 是第 210 行的
  @{verbatim "primrec (nonexhaustive)"} 选择子，只覆盖
  EndpointCap、NotificationCap、ReplyCap、ArchObjectCap 四支，
  对其余构造子取值\emph{无约束}（@{verbatim "undefined"}）。
  既别把它当 UNIV 也别把它当空集用—— @{verbatim "mask_cap"}（第 242 行）
  之所以安全，是因为 @{verbatim "cap_rights_update"} 对不带权利字段的
  构造子写了 @{verbatim "_ \<Rightarrow> cap"} 直接原样返回，交集结果根本没被用到。
  语义上 @{verbatim "NullCap"} 什么也不授权，模型里按语义写：没有权利字段就是空集。
\<close>

definition cap_rights_of :: "cap \<Rightarrow> cap_rights" where
  "cap_rights_of c \<equiv> case c of
      EndpointCap _ _ R     \<Rightarrow> R
    | NotificationCap _ _ R \<Rightarrow> R
    | ReplyCap _ R          \<Rightarrow> R
    | _                     \<Rightarrow> {}"

subsection \<open>5.2 父亲、子孙与传递闭包\<close>

definition is_cdt_parent :: "cdt \<Rightarrow> cslot_ptr \<Rightarrow> cslot_ptr \<Rightarrow> bool" where
  "is_cdt_parent t p c \<equiv> t c = Some p"

definition cdt_parent_rel :: "cdt \<Rightarrow> (cslot_ptr \<times> cslot_ptr) set" where
  "cdt_parent_rel t \<equiv> {(p, c). is_cdt_parent t p c}"

definition descendants_of :: "cslot_ptr \<Rightarrow> cdt \<Rightarrow> cslot_ptr set" where
  "descendants_of p t \<equiv> {q. (p, q) \<in> (cdt_parent_rel t)\<^sup>+}"

lemma parent_is_ancestor:
  "is_cdt_parent t p c \<Longrightarrow> c \<in> descendants_of p t"
  by (auto simp: descendants_of_def cdt_parent_rel_def is_cdt_parent_def)

lemma no_children_iff: "descendants_of p (Map.empty) = {}"
  by (auto simp: descendants_of_def cdt_parent_rel_def is_cdt_parent_def)

text \<open>
  真实内核里 @{verbatim "ensure_no_children"} 判的就是这个条件为空
  （@{verbatim "l4v/spec/abstract/CSpace_A.thy"} 第 67 行）：只要 CDT 里有谁的
  父亲是这个槽，就 @{verbatim "throwError RevokeFirst"}。
  它的用途要说准：用在 @{verbatim "derive_cap"}（把 Untyped 能力\emph{复制/转授}
  出去）上，而\emph{不是} retype 本身——带子孙的 Untyped 照样可以继续 retype，
  只是不会再复位水位（第 15 章）。
\<close>

subsection \<open>5.3 派生：derive_cap\<close>

text \<open>
  @{verbatim "CSpace_A.thy"} 第 106 行的 @{verbatim "derive_cap"} 决定
  "把一个能力复制到别处之前，它必须先变成什么样"：

  @{verbatim "Zombie ptr n sz => returnOk NullCap"}
  @{verbatim "ReplyCap ptr m cr => returnOk NullCap"}
  @{verbatim "IRQControlCap => returnOk NullCap"}
  @{verbatim "UntypedCap dev ptr sz f => doE ensure_no_children slot; returnOk cap odE"}

  三种能力派生出来是 @{verbatim "NullCap"}（即"不能被复制"），因为它们的语义
  与"槽位本身"绑定：Reply 是一次性的、Zombie 是删除过程中的中间态、
  IRQControl 全局唯一。
\<close>

datatype derive_result = Derived cap | DeriveFailed

definition derive_cap :: "cdt \<Rightarrow> cslot_ptr \<Rightarrow> cap \<Rightarrow> derive_result" where
  "derive_cap t slot c \<equiv> case c of
      ReplyCap _ _      \<Rightarrow> Derived NullCap
    | IRQControlCap     \<Rightarrow> Derived NullCap
    | UntypedCap p sz f \<Rightarrow> if descendants_of slot t = {} then Derived c else DeriveFailed
    | _                 \<Rightarrow> Derived c"

text \<open>
  命名提醒：Isabelle 的词法层会把 @{verbatim "ALL EX SUM PROD INT UN INF SUP"}
  这类全大写标识符\emph{整词替换成符号}，报
  @{verbatim "Failed to parse prop"} 且位置指向 RHS。给常量起名时要绕开它们。
\<close>

lemma derive_never_grows_rights:
  "derive_cap t slot c = Derived c' \<Longrightarrow> cap_rights_of c' \<subseteq> cap_rights_of c"
  by (auto simp: derive_cap_def cap_rights_of_def split: cap.splits if_splits)

lemma derive_reply_is_null:
  "derive_cap t slot (ReplyCap p R) = Derived NullCap"
  by (simp add: derive_cap_def)

lemma derive_untyped_needs_no_children:
  "descendants_of slot t \<noteq> {} \<Longrightarrow>
   derive_cap t slot (UntypedCap p sz f) = DeriveFailed"
  by (simp add: derive_cap_def)

subsection \<open>5.4 mint / copy / move：三种"搬能力"的方式\<close>

text \<open>
  @{verbatim "CNodeMint"}、@{verbatim "CNodeCopy"}、@{verbatim "CNodeMove"}、
  @{verbatim "CNodeMutate"} 这四个 label 都进
  @{verbatim "decode_cnode_invocation"}（@{verbatim "l4v/spec/abstract/Decode_A.thy"} 第 49 行），
  被解码成同一件事：
  \emph{先掩码，再派生，最后插入}。区别只在两处参数：

  \begin{itemize}
    \item @{verbatim "CNodeCopy"}：只有 rights 字，没有 capData；
    \item @{verbatim "CNodeMint"}：rights 字 + capData（可打 badge）；
    \item @{verbatim "CNodeMove"} / @{verbatim "CNodeMutate"}：@{verbatim "is_move = True"}，
          源槽被清空，权利取 @{verbatim "all_rights"}（移动不削权）。
  \end{itemize}
\<close>

definition mask_cap :: "cap_rights \<Rightarrow> cap \<Rightarrow> cap" where
  "mask_cap R c \<equiv> case c of
      EndpointCap p b R'     \<Rightarrow> EndpointCap p b (R' \<inter> R)
    | NotificationCap p b R' \<Rightarrow> NotificationCap p b (R' \<inter> R)
    | ReplyCap p R'          \<Rightarrow> ReplyCap p (R' \<inter> R)
    | _                      \<Rightarrow> c"

definition mint :: "cdt \<Rightarrow> cslot_ptr \<Rightarrow> cap \<Rightarrow> cap_rights \<Rightarrow> derive_result" where
  "mint t slot c R \<equiv> derive_cap t slot (mask_cap R c)"

lemma mask_cap_never_grows:
  "cap_rights_of (mask_cap R c) \<subseteq> cap_rights_of c"
  by (auto simp: mask_cap_def cap_rights_of_def split: cap.splits)

lemma mint_never_grows:
  "mint t slot c R = Derived c' \<Longrightarrow> cap_rights_of c' \<subseteq> cap_rights_of c"
proof -
  assume h: "mint t slot c R = Derived c'"
  have step1: "cap_rights_of c' \<subseteq> cap_rights_of (mask_cap R c)"
    using h derive_never_grows_rights[of t slot "mask_cap R c" c']
    by (auto simp: mint_def split: derive_result.splits)
  have step2: "cap_rights_of (mask_cap R c) \<subseteq> cap_rights_of c"
    by (rule mask_cap_never_grows)
  from step1 step2 show "cap_rights_of c' \<subseteq> cap_rights_of c" by blast
qed

text \<open>
  @{thm mint_never_grows} 就是"权利只能被削弱"的第一条完整形态：
  掩码削一次权，派生再削一次（或不削），合起来仍然不增长。
  第 21 章的完整性定理把这条推广到"任意系统调用序列"。
\<close>

subsection \<open>5.5 插入时谁当父亲：should_be_parent_of\<close>

text \<open>
  @{verbatim "CSpace_A.thy"} 第 724 行的 @{verbatim "should_be_parent_of"}
  决定新能力挂在谁的下面：源能力（且它是"原始的"）覆盖同一区域时，
  新能力成为它的孩子；否则新能力直接挂在目标槽原本的父亲下。
  端点能力还有额外的 badge 规则（badged 端点能力本身被视为"原始的"，
  可以再派生一层）。

  模型只保留判定结果，把"是否成为孩子"抽成布尔函数。
\<close>

definition obj_ref_of :: "cap \<Rightarrow> obj_ref" where
  "obj_ref_of c \<equiv> case c of
      EndpointCap p _ _     \<Rightarrow> p
    | NotificationCap p _ _ \<Rightarrow> p
    | ReplyCap p _          \<Rightarrow> p
    | UntypedCap p _ _      \<Rightarrow> p
    | ThreadCap p           \<Rightarrow> p
    | _                     \<Rightarrow> 0"

definition same_object_as :: "cap \<Rightarrow> cap \<Rightarrow> bool" where
  "same_object_as c c' \<equiv> obj_ref_of c = obj_ref_of c'"

definition should_be_parent_of :: "cap \<Rightarrow> bool \<Rightarrow> cap \<Rightarrow> bool \<Rightarrow> bool" where
  "should_be_parent_of src src_orig new new_orig \<equiv>
     src_orig \<and> same_object_as src new \<and> (src \<noteq> new \<or> \<not> new_orig)"

lemma not_original_never_parent:
  "\<not> src_orig \<Longrightarrow> \<not> should_be_parent_of src src_orig new new_orig"
  by (simp add: should_be_parent_of_def)

subsection \<open>5.6 插入能力与 CDT 的单调性\<close>

text \<open>
  把一条新边 @{verbatim "parent -> child"} 加进 CDT（child 原来没有父亲），
  子孙集合只会变大不会变小。这条单调性在第 6 章证明 revoke 的正确性时要用。
\<close>

lemma cdt_rel_mono:
  "t p = None \<Longrightarrow> cdt_parent_rel t \<subseteq> cdt_parent_rel (t(p \<mapsto> q))"
  by (auto simp: cdt_parent_rel_def is_cdt_parent_def)

lemma descendants_mono:
  "t p = None \<Longrightarrow> descendants_of x t \<subseteq> descendants_of x (t(p \<mapsto> q))"
  apply (auto simp: descendants_of_def)
  apply (meson cdt_rel_mono trancl_mono)
  done

lemma new_child_is_descendant:
  "t p = None \<Longrightarrow> is_cdt_parent (t(p \<mapsto> q)) q p"
  by (simp add: is_cdt_parent_def)

lemma new_child_in_descendants:
  "t p = None \<Longrightarrow> p \<in> descendants_of q (t(p \<mapsto> q))"
  by (simp add: parent_is_ancestor new_child_is_descendant)

ML \<open>
  writeln (@{make_string} @{thm mint_never_grows});
  writeln (@{make_string} @{thm descendants_mono})
\<close>

ML \<open>writeln "==== 05 结束 ===="\<close>

end
