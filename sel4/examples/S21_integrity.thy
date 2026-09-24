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

datatype rights = AllowRead | AllowWrite | AllowGrant
type_synonym cap_rights = "rights set"

datatype cap = NullCap | EndpointCap obj_ref cap_rights | UntypedCap obj_ref

definition cap_rights_of :: "cap \<Rightarrow> cap_rights" where
  "cap_rights_of c \<equiv> case c of EndpointCap _ R \<Rightarrow> R | _ \<Rightarrow> {}"

definition cap_target :: "cap \<Rightarrow> obj_ref option" where
  "cap_target c \<equiv> case c of EndpointCap p _ \<Rightarrow> Some p | UntypedCap p \<Rightarrow> Some p | NullCap \<Rightarrow> None"

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

ML \<open>
  writeln (@{make_string} @{thm delete_reduces_authority});
  writeln (@{make_string} @{thm mint_cannot_escalate})
\<close>

ML \<open>writeln "==== 21 结束 ===="\<close>

end
