theory S17_invariants
  imports Main
begin

section \<open>17.1 不变式：内核证明的骨架\<close>

text \<open>
  前面十六章都是在证明"某一个操作是对的"。要证明"内核\emph{永远}是对的"，
  还需要一组\emph{不变式}：每一次系统调用前后都必须成立的性质。
  l4v 里它们集中在 @{verbatim "l4v/proof/invariant-abstract/"} 与
  @{verbatim "l4v/spec/abstract/KHeap_A.thy"}，典型成员有：

  \begin{itemize}
    \item @{verbatim "valid_objs"}：每个对象的内容与其类型一致；
    \item @{verbatim "valid_mdb"}：CDT 是一棵（或一片）结构良好的树；
    \item @{verbatim "valid_idle"}：idle 线程始终存在且不可运行；
    \item @{verbatim "valid_global_refs"}：内核自己的引用不被用户触碰；
    \item @{verbatim "pspace_aligned"} / @{verbatim "pspace_distinct"}：
          对象按类型对齐、互不重叠（第 15 章的块分配性质在系统层面的形态）。
  \end{itemize}

  本章只建其中两条的最小模型，并证明它们在操作下保持。
\<close>

ML \<open>writeln "==== 17 开始 ===="\<close>

type_synonym obj_ref = nat
type_synonym cslot_ptr = "obj_ref \<times> nat"

datatype otype = EndpointType | NotificationType | UntypedType

datatype cap = NullCap | EndpointCap obj_ref | NotificationCap obj_ref | UntypedCap obj_ref

record kstate =
  ks_objs  :: "obj_ref \<Rightarrow> otype option"
  ks_caps  :: "cslot_ptr \<Rightarrow> cap option"
  ks_cdt   :: "cslot_ptr \<Rightarrow> cslot_ptr option"

definition cap_type :: "cap \<Rightarrow> otype option" where
  "cap_type c \<equiv> case c of
      EndpointCap _      \<Rightarrow> Some EndpointType
    | NotificationCap _  \<Rightarrow> Some NotificationType
    | UntypedCap _       \<Rightarrow> Some UntypedType
    | NullCap            \<Rightarrow> None"

definition cap_target :: "cap \<Rightarrow> obj_ref option" where
  "cap_target c \<equiv> case c of
      EndpointCap p      \<Rightarrow> Some p
    | NotificationCap p  \<Rightarrow> Some p
    | UntypedCap p       \<Rightarrow> Some p
    | NullCap            \<Rightarrow> None"

subsection \<open>17.2 valid_objs：能力指向的对象必须存在且类型一致\<close>

definition valid_objs :: "kstate \<Rightarrow> bool" where
  "valid_objs s \<equiv> \<forall>sl c. ks_caps s sl = Some c \<longrightarrow>
      (case cap_target c of
          None   \<Rightarrow> True
        | Some p \<Rightarrow> ks_objs s p = cap_type c)"

lemma empty_state_is_valid:
  "valid_objs \<lparr> ks_objs = \<lambda>_. None, ks_caps = \<lambda>_. None, ks_cdt = \<lambda>_. None \<rparr>"
  by (simp add: valid_objs_def)

lemma cap_to_missing_object_is_invalid:
  "ks_caps s sl = Some (EndpointCap p) \<Longrightarrow> ks_objs s p = None \<Longrightarrow> \<not> valid_objs s"
proof
  assume v: "valid_objs s" and cap: "ks_caps s sl = Some (EndpointCap p)" and none: "ks_objs s p = None"
  from v have all: "\<forall>x c. ks_caps s x = Some c \<longrightarrow>
        (case cap_target c of None \<Rightarrow> True | Some p \<Rightarrow> ks_objs s p = cap_type c)"
    by (simp add: valid_objs_def)
  from all cap have "case cap_target (EndpointCap p) of
        None \<Rightarrow> True | Some q \<Rightarrow> ks_objs s q = cap_type (EndpointCap p)" by blast
  then have "ks_objs s p = cap_type (EndpointCap p)" by (simp add: cap_target_def)
  with none show False by (simp add: cap_type_def)
qed

text \<open>
  这条不变式看着简单，却是整个证明里最"贵"的一条：
  每次 @{verbatim "set_object"}、@{verbatim "create_cap"}、
  @{verbatim "cap_delete"} 之后都要重新证明它。
\<close>

subsection \<open>17.3 插入能力：只在新对象存在时才保持\<close>

definition insert_cap :: "cap \<Rightarrow> cslot_ptr \<Rightarrow> kstate \<Rightarrow> kstate" where
  "insert_cap c sl s \<equiv> s\<lparr> ks_caps := (ks_caps s)(sl \<mapsto> c) \<rparr>"

lemma insert_cap_preserves_valid_objs:
  "valid_objs s \<Longrightarrow> valid_objs (insert_cap NullCap sl s)"
  by (auto simp: valid_objs_def insert_cap_def cap_target_def cap_type_def split: option.splits)

lemma insert_cap_needs_object:
  "valid_objs s \<Longrightarrow> ks_objs s p = Some EndpointType \<Longrightarrow>
   valid_objs (insert_cap (EndpointCap p) sl s)"
  by (auto simp: valid_objs_def insert_cap_def cap_target_def cap_type_def split: option.splits)

lemma insert_wrong_type_breaks_valid_objs:
  "ks_objs s p = Some NotificationType \<Longrightarrow>
   \<not> valid_objs (insert_cap (EndpointCap p) sl s)"
proof
  assume wrong: "ks_objs s p = Some NotificationType"
    and v: "valid_objs (insert_cap (EndpointCap p) sl s)"
  from v have all: "\<forall>x c. ks_caps (insert_cap (EndpointCap p) sl s) x = Some c \<longrightarrow>
        (case cap_target c of None \<Rightarrow> True
          | Some q \<Rightarrow> ks_objs (insert_cap (EndpointCap p) sl s) q = cap_type c)"
    by (simp add: valid_objs_def)
  have caps_at: "ks_caps (insert_cap (EndpointCap p) sl s) sl = Some (EndpointCap p)"
    by (simp add: insert_cap_def)
  from all caps_at have "case cap_target (EndpointCap p) of
        None \<Rightarrow> True
      | Some q \<Rightarrow> ks_objs (insert_cap (EndpointCap p) sl s) q = cap_type (EndpointCap p)"
    by blast
  then have "ks_objs (insert_cap (EndpointCap p) sl s) p = cap_type (EndpointCap p)"
    by (simp add: cap_target_def)
  with wrong show False by (simp add: insert_cap_def cap_type_def)
qed

text \<open>
  @{thm insert_wrong_type_breaks_valid_objs} 说明"类型必须匹配"这一条
  是\emph{真约束}：把端点能力指向通知对象，状态立刻变得不合法。
  真实内核靠 @{verbatim "default_cap"}
  （@{verbatim "Retype_A.thy"}）保证类型与对象一致。
\<close>

subsection \<open>17.4 valid_mdb：CDT 的父亲必须存在\<close>

definition valid_mdb :: "kstate \<Rightarrow> bool" where
  "valid_mdb s \<equiv> \<forall>sl p. ks_cdt s sl = Some p \<longrightarrow>
      (ks_caps s p \<noteq> None \<and> ks_caps s sl \<noteq> None)"

lemma no_edges_is_valid_mdb:
  "valid_mdb \<lparr> ks_objs = \<lambda>_. None, ks_caps = \<lambda>_. None, ks_cdt = \<lambda>_. None \<rparr>"
  by (simp add: valid_mdb_def)

lemma edge_to_empty_slot_is_invalid:
  "ks_cdt s sl = Some p \<Longrightarrow> ks_caps s p = None \<Longrightarrow> \<not> valid_mdb s"
proof
  assume v: "valid_mdb s" and edge: "ks_cdt s sl = Some p" and none: "ks_caps s p = None"
  from v have all: "\<forall>sl p. ks_cdt s sl = Some p \<longrightarrow>
        ks_caps s p \<noteq> None \<and> ks_caps s sl \<noteq> None"
    by (simp add: valid_mdb_def)
  from all edge have "ks_caps s p \<noteq> None" by blast
  with none show False by simp
qed

text \<open>
  真实的 @{verbatim "valid_mdb"} 要强得多：它要求 CDT 无环、
  每个非原始能力的父亲覆盖同一对象、撤销时子孙集合可达等等
  （@{verbatim "l4v/proof/invariant-abstract/"} 里有几百条引理）。
  模型里的"父亲槽必须非空"只是它的第一层。
\<close>

subsection \<open>17.5 不变式要一起保持\<close>

definition invs :: "kstate \<Rightarrow> bool" where
  "invs s \<equiv> valid_objs s \<and> valid_mdb s"

lemma invs_insert_null:
  "invs s \<Longrightarrow> invs (insert_cap NullCap sl s)"
proof -
  assume h: "invs s"
  have vo: "valid_objs (insert_cap NullCap sl s)"
    using h by (auto simp: invs_def insert_cap_def valid_objs_def cap_target_def cap_type_def
                      split: if_splits option.splits)
  have vm: "valid_mdb (insert_cap NullCap sl s)"
    using h by (auto simp: invs_def insert_cap_def valid_mdb_def split: if_splits)
  from vo vm show "invs (insert_cap NullCap sl s)" by (simp add: invs_def)
qed

text \<open>
  真实证明的模式就是这样的 @{verbatim "invs"}：
  每个操作各自证明它保持 @{verbatim "valid_objs"}、@{verbatim "valid_mdb"}、……，
  再用 @{verbatim "invs"} 打包。l4v 里这一步叫
  @{verbatim "valid_inv"}，是 @{verbatim "Syscall_A"} 层的主定理之一。
\<close>

ML \<open>
  writeln (@{make_string} @{thm insert_wrong_type_breaks_valid_objs});
  writeln (@{make_string} @{thm invs_insert_null})
\<close>

ML \<open>writeln "==== 17 结束 ===="\<close>

end
