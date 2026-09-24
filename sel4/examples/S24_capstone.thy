theory S24_capstone
  imports Main
begin

section \<open>24.1 综合案例：证明一个两分区系统是隔离的\<close>

text \<open>
  这一章把整本教程用过的东西串起来，证明一条"像样的"定理。
  系统模型沿用第 23 章的形状，操作集合取自第 5、6 章
  （mint / copy / delete / revoke），性质取自第 21、22 章
  （权威不越界）。

  要证的命题：

  \begin{quote}
  从两个互不可达的分区出发，\emph{任意}多次合法操作之后，
  分区 A 仍然无法到达分区 B 的任何对象。
  \end{quote}

  这是"任意长的运行"性质，所以证明必然是\emph{归纳}的：
  先证明单步保持，再归纳到任意步。
\<close>

ML \<open>writeln "==== 24 开始 ===="\<close>

type_synonym obj_id = nat
type_synonym slot = nat
type_synonym partition = nat

datatype rights = AllowRead | AllowWrite | AllowGrant
type_synonym cap_rights = "rights set"

datatype cap =
    NullCap
  | EndpointCap obj_id cap_rights
  | CNodeCap obj_id

record cnode =
  cn_part :: partition
  cn_caps :: "slot \<Rightarrow> cap option"

type_synonym system = "obj_id \<Rightarrow> cnode option"

definition cap_part_of :: "cap \<Rightarrow> partition option" where
  "cap_part_of c \<equiv> case c of EndpointCap _ _ \<Rightarrow> None | CNodeCap _ \<Rightarrow> None | NullCap \<Rightarrow> None"

definition cap_obj :: "cap \<Rightarrow> obj_id option" where
  "cap_obj c \<equiv> case c of EndpointCap p _ \<Rightarrow> Some p | CNodeCap p \<Rightarrow> Some p | NullCap \<Rightarrow> None"

definition cap_rights_of :: "cap \<Rightarrow> cap_rights" where
  "cap_rights_of c \<equiv> case c of EndpointCap _ R \<Rightarrow> R | _ \<Rightarrow> {}"

definition part_of :: "system \<Rightarrow> obj_id \<Rightarrow> partition option" where
  "part_of s p \<equiv> case s p of None \<Rightarrow> None | Some n \<Rightarrow> Some (cn_part n)"

subsection \<open>24.2 一步可达与"不跨界"\<close>

definition reaches :: "system \<Rightarrow> obj_id \<Rightarrow> obj_id set" where
  "reaches s oid \<equiv> {p. \<exists>sl c. s oid \<noteq> None \<and> cn_caps (the (s oid)) sl = Some c
                            \<and> cap_obj c = Some p}"

definition isolated :: "system \<Rightarrow> partition \<Rightarrow> bool" where
  "isolated s a \<equiv> \<forall>oid p. part_of s oid = Some a \<longrightarrow> p \<in> reaches s oid \<longrightarrow>
                            part_of s p = Some a"

text \<open>
  @{verbatim "isolated s a"} 的意思是：a 分区里任何一个 CNode
  能一步走到的对象，仍然在 a 分区里。这是"隔离"的单步形式。
\<close>

lemma system_without_edges_is_isolated: "isolated (\<lambda>_. None) a"
  by (simp add: isolated_def reaches_def part_of_def)

subsection \<open>24.3 四类操作\<close>

definition op_insert :: "obj_id \<Rightarrow> slot \<Rightarrow> cap \<Rightarrow> system \<Rightarrow> system" where
  "op_insert oid sl c s \<equiv> case s oid of
      None \<Rightarrow> s
    | Some n \<Rightarrow> s(oid \<mapsto> n\<lparr> cn_caps := (cn_caps n)(sl \<mapsto> c) \<rparr>)"

definition op_delete :: "obj_id \<Rightarrow> slot \<Rightarrow> system \<Rightarrow> system" where
  "op_delete oid sl s \<equiv> case s oid of
      None \<Rightarrow> s
    | Some n \<Rightarrow> s(oid \<mapsto> n\<lparr> cn_caps := (cn_caps n)(sl := None) \<rparr>)"

definition op_mint :: "cap_rights \<Rightarrow> cap \<Rightarrow> cap" where
  "op_mint R c \<equiv> case c of EndpointCap p R' \<Rightarrow> EndpointCap p (R' \<inter> R) | _ \<Rightarrow> c"

definition op_revoke :: "obj_id \<Rightarrow> system \<Rightarrow> system" where
  "op_revoke oid s \<equiv> case s oid of
      None \<Rightarrow> s
    | Some n \<Rightarrow> s(oid \<mapsto> n\<lparr> cn_caps := \<lambda>_. None \<rparr>)"

subsection \<open>24.4 单步引理：只有"同分区插入"才被允许\<close>

text \<open>
  关键设计：操作分为\emph{合法}与\emph{非法}两类。
  合法操作里唯一会增加边的是 @{verbatim "op_insert"}，
  而它只在"被插入的对象与目标 CNode 同分区"时才合法。
  这个条件就是 @{verbatim "legal s op"} 里的那一项。
\<close>

datatype operation =
    Ins obj_id slot cap
  | Del obj_id slot
  | Rev obj_id

definition legal :: "system \<Rightarrow> operation \<Rightarrow> bool" where
  "legal s op \<equiv> case op of
      Ins oid sl c \<Rightarrow> s oid \<noteq> None \<and>
          (case cap_obj c of
              None \<Rightarrow> True
            | Some p \<Rightarrow> part_of s p = part_of s oid)
    | Del oid sl \<Rightarrow> s oid \<noteq> None
    | Rev oid    \<Rightarrow> s oid \<noteq> None"

definition apply_op :: "operation \<Rightarrow> system \<Rightarrow> system" where
  "apply_op op s \<equiv> case op of
      Ins oid sl c \<Rightarrow> op_insert oid sl c s
    | Del oid sl \<Rightarrow> op_delete oid sl s
    | Rev oid    \<Rightarrow> op_revoke oid s"

lemma insert_crossing_partition_is_illegal:
  "s oid = Some n \<Longrightarrow> cn_part n = 1 \<Longrightarrow> part_of s p = Some 2 \<Longrightarrow>
   \<not> legal s (Ins oid sl (EndpointCap p {AllowRead}))"
proof
  assume sn: "s oid = Some n" and pn: "cn_part n = 1" and pp: "part_of s p = Some 2"
    and lg: "legal s (Ins oid sl (EndpointCap p {AllowRead}))"
  from lg have eq: "part_of s p = part_of s oid"
    by (simp add: legal_def cap_obj_def)
  have po: "part_of s oid = Some 1" using sn pn by (simp add: part_of_def)
  from eq pp po show False by simp
qed

text \<open>
  @{thm insert_crossing_partition_is_illegal} 是整套隔离保证的\emph{唯一}
  入口检查：内核不允许往 CSpace 里插入一条跨分区的边。
  真实内核里这个检查分散在 @{verbatim "decode_cnode_invocation"}
  （权限与掩码）与 @{verbatim "cap_insert"}（CDT 父子判定）里。
\<close>

subsection \<open>24.5 单步保持隔离\<close>

text \<open>
  下面这条引理是证明的关键：插入操作只改 @{verbatim "cn_caps"}，
  不改 @{verbatim "cn_part"}，所以"属于哪个分区"这一信息不受影响。
  这类"只动一个字段"的引理在第 13 章见过，在真实证明里成千上万条。
\<close>

lemma op_insert_preserves_part_of:
  "part_of (op_insert oid sl c s) p = part_of s p"
  by (auto simp: op_insert_def part_of_def split: option.splits)

lemma op_delete_preserves_part_of:
  "part_of (op_delete oid sl s) p = part_of s p"
  by (auto simp: op_delete_def part_of_def split: option.splits)

lemma op_revoke_preserves_part_of:
  "part_of (op_revoke oid s) p = part_of s p"
  by (auto simp: op_revoke_def part_of_def split: option.splits)

lemma op_delete_reduces_reaches:
  "p \<in> reaches (op_delete oid sl s) x \<Longrightarrow> p \<in> reaches s x"
  by (auto simp: reaches_def op_delete_def split: if_splits option.splits)

lemma op_revoke_reduces_reaches:
  "p \<in> reaches (op_revoke oid s) x \<Longrightarrow> p \<in> reaches s x"
  by (auto simp: reaches_def op_revoke_def split: if_splits option.splits)

lemma delete_preserves_isolation:
  "isolated s a \<Longrightarrow> isolated (op_delete oid sl s) a"
proof -
  assume inv: "isolated s a"
  show "isolated (op_delete oid sl s) a"
    unfolding isolated_def
  proof (intro allI impI)
    fix x p
    assume px: "part_of (op_delete oid sl s) x = Some a"
      and rp: "p \<in> reaches (op_delete oid sl s) x"
    have px': "part_of s x = Some a" using px by (simp add: op_delete_preserves_part_of)
    have rp': "p \<in> reaches s x" using rp by (rule op_delete_reduces_reaches)
    with inv px' have "part_of s p = Some a" by (auto simp: isolated_def)
    then show "part_of (op_delete oid sl s) p = Some a" by (simp add: op_delete_preserves_part_of)
  qed
qed

lemma revoke_preserves_isolation:
  "isolated s a \<Longrightarrow> isolated (op_revoke oid s) a"
proof -
  assume inv: "isolated s a"
  show "isolated (op_revoke oid s) a"
    unfolding isolated_def
  proof (intro allI impI)
    fix x p
    assume px: "part_of (op_revoke oid s) x = Some a"
      and rp: "p \<in> reaches (op_revoke oid s) x"
    have px': "part_of s x = Some a" using px by (simp add: op_revoke_preserves_part_of)
    have rp': "p \<in> reaches s x" using rp by (rule op_revoke_reduces_reaches)
    with inv px' have "part_of s p = Some a" by (auto simp: isolated_def)
    then show "part_of (op_revoke oid s) p = Some a" by (simp add: op_revoke_preserves_part_of)
  qed
qed

lemma legal_insert_preserves_isolation:
  "isolated s a \<Longrightarrow> legal s (Ins oid sl c) \<Longrightarrow> isolated (op_insert oid sl c s) a"
proof -
  assume inv: "isolated s a" and lg: "legal s (Ins oid sl c)"
  show "isolated (op_insert oid sl c s) a"
    unfolding isolated_def
  proof (intro allI impI)
    fix x p
    assume px: "part_of (op_insert oid sl c s) x = Some a"
      and rp: "p \<in> reaches (op_insert oid sl c s) x"
    show "part_of (op_insert oid sl c s) p = Some a"
    proof (cases "x = oid")
      case False
      then have px': "part_of s x = Some a" using px by (simp add: op_insert_preserves_part_of)
      have rp': "p \<in> reaches s x"
        using rp False by (auto simp: reaches_def op_insert_def split: if_splits option.splits)
      with inv px' have "part_of s p = Some a" by (auto simp: isolated_def)
      then show ?thesis by (simp add: op_insert_preserves_part_of)
    next
      case True
      from lg have snne: "s oid \<noteq> None" by (auto simp: legal_def)
      then obtain n where sn: "s oid = Some n" by auto
      have pxoid: "part_of s oid = Some a"
        using px True by (simp add: op_insert_preserves_part_of)
      from rp True obtain sl' c' where
        cc: "cn_caps (the (op_insert oid sl c s oid)) sl' = Some c'"
        and co: "cap_obj c' = Some p"
        by (auto simp: reaches_def split: if_splits option.splits)
      show "part_of (op_insert oid sl c s) p = Some a"
      proof (cases "sl' = sl")
        case True
        then have c'eq: "c' = c" using cc sn by (auto simp: op_insert_def)
        from lg co c'eq have pp: "part_of s p = part_of s oid"
          by (auto simp: legal_def cap_obj_def split: option.splits)
        with pxoid show ?thesis by (simp add: op_insert_preserves_part_of)
      next
        case False
        then have "cn_caps n sl' = Some c'"
          using cc sn by (auto simp: op_insert_def split: if_splits)
        then have "p \<in> reaches s oid" using sn co by (auto simp: reaches_def)
        with inv pxoid have "part_of s p = Some a" by (auto simp: isolated_def)
        then show ?thesis by (simp add: op_insert_preserves_part_of)
      qed
    qed
  qed
qed

lemma step_preserves_isolation:
  "isolated s a \<Longrightarrow> legal s op \<Longrightarrow> isolated (apply_op op s) a"
  apply (cases op)
    apply (simp_all add: apply_op_def)
    apply (rule legal_insert_preserves_isolation; assumption)
   apply (rule delete_preserves_isolation; assumption)
  apply (rule revoke_preserves_isolation; assumption)
  done

subsection \<open>24.6 归纳：任意长的运行\<close>

fun run_ops :: "operation list \<Rightarrow> system \<Rightarrow> system" where
  "run_ops [] s = s"
| "run_ops (op # ops) s = run_ops ops (apply_op op s)"

text \<open>
  注意"每一步都合法"也要被归纳地定义：第 n 步的合法性
  是在前 n-1 步之后的状态上判定的。
\<close>

fun all_legal :: "system \<Rightarrow> operation list \<Rightarrow> bool" where
  "all_legal s [] = True"
| "all_legal s (op # ops) = (legal s op \<and> all_legal (apply_op op s) ops)"

lemma run_ops_preserves_isolation:
  "isolated s a \<Longrightarrow> all_legal s ops \<Longrightarrow> isolated (run_ops ops s) a"
proof (induction ops arbitrary: s)
  case Nil
  then show ?case by simp
next
  case (Cons op ops)
  then have lg: "legal s op" and rest: "all_legal (apply_op op s) ops" by simp_all
  from step_preserves_isolation[OF Cons.prems(1) lg] rest show ?case
    by (simp add: Cons.IH)
qed

text \<open>
  @{thm run_ops_preserves_isolation} 就是本章的目标定理：
  任意多次合法操作之后，分区仍然隔离。

  把它与真实 l4v 对照一下，会发现结构完全一样：
  \begin{itemize}
    \item @{verbatim "isolated"} ↔ @{verbatim "pas_refined"} /
          @{verbatim "tegrity"} 那一族不变式；
    \item @{verbatim "legal"} ↔ @{verbatim "decode_invocation"} 的检查；
    \item @{verbatim "step_preserves_isolation"} ↔
          @{verbatim "Syscall_AC.thy"} / @{verbatim "Syscall_IF.thy"} 的主引理；
    \item @{verbatim "run_ops_preserves_isolation"} ↔
          @{verbatim "Noninterference.thy"} 的最终定理。
  \end{itemize}

  差的是规模：真实证明要覆盖几十个系统调用、若干体系结构、
  以及从抽象规范一路到 C 与汇编的四层精化。
\<close>

subsection \<open>24.7 回头看：这条定理依赖了什么\<close>

text \<open>
  最后把这条定理的依赖列清楚——这是读任何 seL4 证明时最该做的事：

  \begin{enumerate}
    \item 权利只能被掩码削弱（第 3 章）；
    \item 派生不会凭空造出权利（第 5 章）；
    \item 删除只减不增（第 6、21 章）；
    \item 每一步操作都不失败、且保持状态不变式（第 16、17 章）；
    \item 抽象层的行为与 C 代码一致（第 18、19、20 章）。
  \end{enumerate}

  少任何一条，@{thm run_ops_preserves_isolation} 都只是"一个模型的性质"，
  而不是"seL4 的性质"。
\<close>

ML \<open>
  writeln (@{make_string} @{thm step_preserves_isolation});
  writeln (@{make_string} @{thm run_ops_preserves_isolation})
\<close>

ML \<open>writeln "==== 24 结束 ===="\<close>

end
