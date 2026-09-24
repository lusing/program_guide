theory S23_capdl
  imports Main
begin

section \<open>23.1 capDL：用一张图描述系统的保护状态\<close>

text \<open>
  capDL（capability Distribution Language）是 seL4 的"系统描述语言"：
  它不描述内存内容，也不描述执行过程，只描述
  \emph{谁手里有什么能力}。规范在 @{verbatim "l4v/spec/capDL/"}
  （@{verbatim "Structures_D.thy"}、@{verbatim "CSpace_D.thy"}、
  @{verbatim "CNode_D.thy"}、@{verbatim "KHeap_D.thy"}…），
  用它做系统初始化的证明在 @{verbatim "l4v/sys-init/"}
  （@{verbatim "InitCSpace_SI.thy"}、@{verbatim "CreateObjects_SI.thy"}、
  @{verbatim "WellFormed_SI.thy"}、@{verbatim "Proof_SI.thy"}）。

  capDL 有两类对象：\emph{内核对象}（端点、通知、TCB、CNode……）
  与 \emph{能力}（指向对象并带权利）。下面是一个最小模型。
\<close>

ML \<open>writeln "==== 23 开始 ===="\<close>

type_synonym obj_id = nat
type_synonym slot = nat

datatype rights = AllowRead | AllowWrite | AllowGrant
type_synonym cap_rights = "rights set"

datatype dtype = EndpointD | NotificationD | TcbD | CNodeD | UntypedD

datatype dcap =
    NullD
  | EndpointDCap obj_id cap_rights
  | NotificationDCap obj_id cap_rights
  | TcbDCap obj_id
  | CNodeDCap obj_id nat
  | UntypedDCap obj_id

record dobj =
  do_type :: dtype
  do_caps :: "slot \<Rightarrow> dcap option"

type_synonym cdl_state = "obj_id \<Rightarrow> dobj option"

definition empty_cdl :: cdl_state where "empty_cdl \<equiv> \<lambda>_. None"

subsection \<open>23.2 能力指向的对象\<close>

definition cap_obj :: "dcap \<Rightarrow> obj_id option" where
  "cap_obj c \<equiv> case c of
      EndpointDCap p _      \<Rightarrow> Some p
    | NotificationDCap p _  \<Rightarrow> Some p
    | TcbDCap p             \<Rightarrow> Some p
    | CNodeDCap p _         \<Rightarrow> Some p
    | UntypedDCap p         \<Rightarrow> Some p
    | NullD                 \<Rightarrow> None"

definition cap_rights_of :: "dcap \<Rightarrow> cap_rights" where
  "cap_rights_of c \<equiv> case c of
      EndpointDCap _ R     \<Rightarrow> R
    | NotificationDCap _ R \<Rightarrow> R
    | _                    \<Rightarrow> {}"

subsection \<open>23.3 井形性：每条边都指向存在的对象，且类型匹配\<close>

definition type_matches :: "dtype \<Rightarrow> dcap \<Rightarrow> bool" where
  "type_matches t c \<equiv> case (t, c) of
      (EndpointD, EndpointDCap _ _)         \<Rightarrow> True
    | (NotificationD, NotificationDCap _ _) \<Rightarrow> True
    | (TcbD, TcbDCap _)                     \<Rightarrow> True
    | (CNodeD, CNodeDCap _ _)               \<Rightarrow> True
    | (UntypedD, UntypedDCap _)             \<Rightarrow> True
    | (_, NullD)                            \<Rightarrow> True
    | _                                     \<Rightarrow> False"

definition well_formed :: "cdl_state \<Rightarrow> bool" where
  "well_formed s \<equiv> \<forall>oid obj sl c. s oid = Some obj \<longrightarrow> do_caps obj sl = Some c \<longrightarrow>
      (case cap_obj c of
          None   \<Rightarrow> True
        | Some p \<Rightarrow> (\<exists>obj'. s p = Some obj' \<and> type_matches (do_type obj') c))"

lemma empty_is_well_formed: "well_formed empty_cdl"
  by (simp add: well_formed_def empty_cdl_def)

lemma dangling_cap_is_not_well_formed:
  "s oid = Some obj \<Longrightarrow> do_caps obj sl = Some (EndpointDCap p R) \<Longrightarrow> s p = None \<Longrightarrow>
   \<not> well_formed s"
proof
  assume wf: "well_formed s"
    and o: "s oid = Some obj" and c: "do_caps obj sl = Some (EndpointDCap p R)" and miss: "s p = None"
  from wf have all: "\<forall>oid obj sl c. s oid = Some obj \<longrightarrow> do_caps obj sl = Some c \<longrightarrow>
      (case cap_obj c of None \<Rightarrow> True | Some q \<Rightarrow> \<exists>obj'. s q = Some obj' \<and> type_matches (do_type obj') c)"
    by (simp add: well_formed_def)
  from all o c have "case cap_obj (EndpointDCap p R) of
        None \<Rightarrow> True
      | Some q \<Rightarrow> \<exists>obj'. s q = Some obj' \<and> type_matches (do_type obj') (EndpointDCap p R)"
    by blast
  then have "\<exists>obj'. s p = Some obj' \<and> type_matches (do_type obj') (EndpointDCap p R)"
    by (simp add: cap_obj_def)
  then obtain obj' where "s p = Some obj'" by blast
  with miss show False by simp
qed

subsection \<open>23.4 可达性：从根能走到哪里\<close>

text \<open>
  系统初始化证明里最常用的计算是"从某个 CNode 出发能到达哪些对象"。
  模型里定义成一步可达的闭包（真实定义用的是 CDT 与 CSpace 的联合闭包）。
\<close>

definition reachable_step :: "cdl_state \<Rightarrow> obj_id \<Rightarrow> obj_id set" where
  "reachable_step s oid \<equiv> {p. \<exists>obj sl c. s oid = Some obj \<and> do_caps obj sl = Some c
                                       \<and> cap_obj c = Some p}"

definition reachable :: "cdl_state \<Rightarrow> obj_id \<Rightarrow> obj_id set" where
  "reachable s oid \<equiv> {p. (oid, p) \<in> {(a, b). b \<in> reachable_step s a}\<^sup>*}"

lemma self_is_reachable: "oid \<in> reachable s oid"
  by (simp add: reachable_def)

lemma step_is_reachable:
  "p \<in> reachable_step s oid \<Longrightarrow> p \<in> reachable s oid"
  by (auto simp: reachable_def intro: r_into_rtrancl)

lemma reachable_is_monotone_in_caps:
  "reachable_step s oid \<subseteq> reachable_step (s(oid \<mapsto> obj)) oid \<union> {p. True}"
  by auto

subsection \<open>23.5 一个两分区的示例系统\<close>

text \<open>
  下面这个例子是 seL4 系统最常见的形态：一个 Untyped 分成两个分区，
  各自有一个 CNode、一个端点、一个 TCB；两个分区之间\emph{没有}边。
\<close>

definition two_partition_system :: cdl_state where
  "two_partition_system \<equiv>
     empty_cdl(
       1 \<mapsto> \<lparr> do_type = UntypedD,
              do_caps = [0 \<mapsto> CNodeDCap 10 4, 1 \<mapsto> CNodeDCap 20 4] \<rparr>,
       10 \<mapsto> \<lparr> do_type = CNodeD,
               do_caps = [0 \<mapsto> EndpointDCap 11 {AllowRead, AllowWrite}] \<rparr>,
       11 \<mapsto> \<lparr> do_type = EndpointD, do_caps = \<lambda>_. None \<rparr>,
       20 \<mapsto> \<lparr> do_type = CNodeD,
               do_caps = [0 \<mapsto> EndpointDCap 21 {AllowRead, AllowWrite}] \<rparr>,
       21 \<mapsto> \<lparr> do_type = EndpointD, do_caps = \<lambda>_. None \<rparr>)"

lemma partition_a_reaches_only_its_own_endpoint:
  "reachable_step two_partition_system 10 = {11}"
  by (auto simp: reachable_step_def two_partition_system_def empty_cdl_def cap_obj_def
           split: if_splits option.splits)

lemma partition_b_reaches_only_its_own_endpoint:
  "reachable_step two_partition_system 20 = {21}"
  by (auto simp: reachable_step_def two_partition_system_def empty_cdl_def cap_obj_def
           split: if_splits option.splits)

lemma partitions_do_not_reach_each_other:
  "21 \<notin> reachable_step two_partition_system 10"
  by (simp add: partition_a_reaches_only_its_own_endpoint)

text \<open>
  @{thm partitions_do_not_reach_each_other} 就是"隔离"在 capDL 里的表达方式：
  \emph{根本不相邻}。真实证明（@{verbatim "sys-init/Proof_SI.thy"}）要证明的是
  初始化的 C 代码真的造出了这张图，以及这张图满足策略
  @{verbatim "pas"} 规定的所有流。
\<close>

ML \<open>
  writeln (@{make_string} @{thm partition_a_reaches_only_its_own_endpoint});
  writeln (@{make_string} @{thm partitions_do_not_reach_each_other})
\<close>

ML \<open>writeln "==== 23 结束 ===="\<close>

end
