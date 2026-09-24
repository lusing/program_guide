theory S06_revoke_delete
  imports Main
begin

section \<open>6.1 为什么要 revoke\<close>

text \<open>
  \emph{删除}只清掉一个槽；\emph{撤销}要清掉一个能力及其\emph{所有子孙}。
  seL4 的隔离性很大程度上依赖这个操作：把一份能力发给别人之后，
  只要 revoke 自己的那一份，所有派生出去的副本就一起失效。

  真实定义在 @{verbatim "l4v/spec/abstract/CSpace_A.thy"} 第 603 行：

  @{verbatim "function cap_revoke :: cslot_ptr => (unit,'z::state_ext) p_monad"}

  它的主体是一个循环：取当前槽的一个子孙（@{verbatim "select_ext"} 从
  @{verbatim "descendants_of"} 里挑一个），删掉它，直到没有子孙为止。
  注意这里用了 @{verbatim "select_ext"}——\emph{挑哪一个是不确定的}，
  规范有意不承诺顺序（第 7 章讲的非确定性单子就派这个用场）。
\<close>

ML \<open>writeln "==== 06 开始 ===="\<close>

type_synonym obj_ref = nat
type_synonym cnode_index = "bool list"
type_synonym cslot_ptr = "obj_ref \<times> cnode_index"
type_synonym cdt = "cslot_ptr \<Rightarrow> cslot_ptr option"

datatype cap = NullCap | EndpointCap obj_ref | ThreadCap obj_ref | ZombieCap obj_ref nat

type_synonym cspace = "cslot_ptr \<Rightarrow> cap option"

record kstate =
  ks_cspace :: cspace
  ks_cdt    :: cdt

definition is_cdt_parent :: "cdt \<Rightarrow> cslot_ptr \<Rightarrow> cslot_ptr \<Rightarrow> bool" where
  "is_cdt_parent t p c \<equiv> t c = Some p"

definition cdt_parent_rel :: "cdt \<Rightarrow> (cslot_ptr \<times> cslot_ptr) set" where
  "cdt_parent_rel t \<equiv> {(p, c). is_cdt_parent t p c}"

definition descendants_of :: "cslot_ptr \<Rightarrow> cdt \<Rightarrow> cslot_ptr set" where
  "descendants_of p t \<equiv> {q. (p, q) \<in> (cdt_parent_rel t)\<^sup>+}"

subsection \<open>6.2 单槽删除\<close>

text \<open>
  真实内核的"删一个槽"叫 @{verbatim "empty_slot"}
  （@{verbatim "CSpace_A.thy"}，被 @{verbatim "rec_del"} 第 514 行调用），
  它做四件事：把槽置成 @{verbatim "NullCap"}、摘掉它在 CDT 里的边、
  清掉 @{verbatim "is_original_cap"} 标记、把孩子们改挂到它父亲下。
\<close>

definition delete_slot :: "cslot_ptr \<Rightarrow> kstate \<Rightarrow> kstate" where
  "delete_slot p s \<equiv> s\<lparr> ks_cspace := (ks_cspace s)(p \<mapsto> NullCap),
                         ks_cdt := (ks_cdt s)(p := None) \<rparr>"

lemma delete_slot_clears_cap: "ks_cspace (delete_slot p s) p = Some NullCap"
  by (simp add: delete_slot_def)

lemma delete_slot_keeps_others:
  "q \<noteq> p \<Longrightarrow> ks_cspace (delete_slot p s) q = ks_cspace s q"
  by (simp add: delete_slot_def)

subsection \<open>6.3 撤销：把子孙全部删掉\<close>

text \<open>
  模型里用"一次性把所有子孙槽清掉"来等价真实内核的循环。
  两者在\emph{结果}上相同（真实证明要证的就是这一点），
  模型省掉的是中间那些不确定的步骤顺序。
\<close>

definition revoke :: "cslot_ptr \<Rightarrow> kstate \<Rightarrow> kstate" where
  "revoke p s \<equiv> s\<lparr> ks_cspace := \<lambda>q. if q = p \<or> q \<in> descendants_of p (ks_cdt s)
                                    then Some NullCap else ks_cspace s q,
                    ks_cdt := \<lambda>q. if q = p \<or> q \<in> descendants_of p (ks_cdt s)
                                    then None else ks_cdt s q \<rparr>"

lemma revoke_clears_target: "ks_cspace (revoke p s) p = Some NullCap"
  by (simp add: revoke_def)

lemma revoke_clears_descendant:
  "q \<in> descendants_of p (ks_cdt s) \<Longrightarrow> ks_cspace (revoke p s) q = Some NullCap"
  by (simp add: revoke_def)

lemma revoke_keeps_non_descendant:
  "q \<noteq> p \<Longrightarrow> q \<notin> descendants_of p (ks_cdt s) \<Longrightarrow>
   ks_cspace (revoke p s) q = ks_cspace s q"
  by (simp add: revoke_def)

lemma revoke_removes_cdt_edges:
  "q \<in> descendants_of p (ks_cdt s) \<Longrightarrow> ks_cdt (revoke p s) q = None"
  by (simp add: revoke_def)

text \<open>
  这四条放在一起就是 revoke 的规格：\emph{目标与它的所有子孙被清空，
  其他人毫发无损}。"毫发无损"这一条在真实证明里是最难的部分——
  要证明被删对象没有别的引用（@{verbatim "is_final_cap"}），
  见 @{verbatim "CSpace_A.thy"} 第 335 行。
\<close>

subsection \<open>6.4 撤销是幂等的\<close>

lemma cdt_edge_implies_descendant:
  "ks_cdt s x = Some p \<Longrightarrow> x \<in> descendants_of p (ks_cdt s)"
  by (auto simp: descendants_of_def cdt_parent_rel_def is_cdt_parent_def
           intro: r_into_trancl)

text \<open>
  撤销之后，p 在 CDT 里\emph{不再有任何出边}：任何"父亲是 p"的槽
  按定义都是 p 的子孙，而子孙的边已经被清掉了。
\<close>

lemma revoke_no_out_edges: "\<nexists>y. ks_cdt (revoke p s) y = Some p"
proof
  assume "\<exists>y. ks_cdt (revoke p s) y = Some p"
  then obtain y where hy: "ks_cdt (revoke p s) y = Some p" by blast
  then have y_out: "y \<noteq> p" "y \<notin> descendants_of p (ks_cdt s)"
    by (auto simp: revoke_def split: if_splits)
  have "ks_cdt s y = Some p"
    using hy y_out by (auto simp: revoke_def split: if_splits)
  then have "y \<in> descendants_of p (ks_cdt s)" by (rule cdt_edge_implies_descendant)
  with y_out(2) show False by blast
qed

text \<open>
  没有出边就没有子孙：从 p 出发的任何一条传递路径，第一步都得是一条
  p 的出边。这条用 @{verbatim "trancl_induct"} 证，是因为传递闭包的
  归纳原则就是"先看第一步，再看后续"。
\<close>

lemma revoke_no_descendants: "descendants_of p (ks_cdt (revoke p s)) = {}"
proof (rule equals0I)
  fix x
  assume hx: "x \<in> descendants_of p (ks_cdt (revoke p s))"
  then have "(p, x) \<in> (cdt_parent_rel (ks_cdt (revoke p s)))\<^sup>+"
    by (simp add: descendants_of_def)
  then have "\<exists>y. (p, y) \<in> cdt_parent_rel (ks_cdt (revoke p s))"
    by (blast dest: tranclD)
  then obtain y where "(p, y) \<in> cdt_parent_rel (ks_cdt (revoke p s))" by blast
  then have "ks_cdt (revoke p s) y = Some p"
    by (simp add: cdt_parent_rel_def is_cdt_parent_def)
  with revoke_no_out_edges show False by blast
qed

lemma revoke_idempotent_caps:
  "ks_cspace (revoke p (revoke p s)) = ks_cspace (revoke p s)"
proof (rule ext)
  fix q
  show "ks_cspace (revoke p (revoke p s)) q = ks_cspace (revoke p s) q"
    using revoke_no_descendants
    by (auto simp: revoke_def split: if_splits)
qed

text \<open>
  真实内核里 @{verbatim "cap_revoke"} 也满足这个性质：撤销过的槽再撤销一次
  不会有任何额外效果。幂等性是这类"递归删除"操作最容易写错的地方——
  一旦中间步骤改变了子孙集合（比如孩子们改挂到父亲下），
  第二次遍历就会漏掉或重复。
\<close>

subsection \<open>6.5 Zombie：删不完的中间态\<close>

text \<open>
  删除 CNode 或 TCB 是\emph{长操作}：它可能要删掉成千上万个槽，
  中途可能被抢占（@{verbatim "long_running_delete"}，
  @{verbatim "CSpace_A.thy"} 第 318 行）。为了在中间态里保持"这个对象
  正在被删除"的信息，内核把槽里的能力换成 @{verbatim "Zombie"}：

  @{verbatim "finalise_cap (CNodeCap r bits g) final = ..."}（第 443 行）

  Zombie 不授权任何操作，但\emph{不能被替换}，直到删除完成。
\<close>

definition is_zombie :: "cap \<Rightarrow> bool" where
  "is_zombie c \<equiv> case c of ZombieCap _ _ \<Rightarrow> True | _ \<Rightarrow> False"

definition can_be_replaced :: "cap \<Rightarrow> bool" where
  "can_be_replaced c \<equiv> \<not> is_zombie c"

lemma zombie_cannot_be_replaced: "\<not> can_be_replaced (ZombieCap p n)"
  by (simp add: can_be_replaced_def is_zombie_def)

lemma null_cap_can_be_replaced: "can_be_replaced NullCap"
  by (simp add: can_be_replaced_def is_zombie_def)

text \<open>
  @{verbatim "NullCap"} 与 @{verbatim "Zombie"} 都不授权，但只有前者能被覆盖。
  这条区别是 delete-first 类错误（@{verbatim "seL4_DeleteFirst"}）的根源：
  往一个还挂着 Zombie 的槽里插能力会被拒绝。
\<close>

ML \<open>
  writeln (@{make_string} @{thm revoke_clears_descendant});
  writeln (@{make_string} @{thm zombie_cannot_be_replaced})
\<close>

ML \<open>writeln "==== 06 结束 ===="\<close>

end
