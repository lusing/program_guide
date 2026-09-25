theory S17_invariants
  imports Main
begin

section \<open>17.1 不变式在规范里长什么样：一条 @{verbatim "and"} 链\<close>

text \<open>
  前十六章都在证"某一个操作是对的"。要证"内核\emph{永远}是对的"，
  还需要一组\emph{不变式}：每次系统调用前后都必须成立的性质。
  l4v 里它们的总和就在
  @{verbatim "l4v/proof/invariant-abstract/Invariants_AI.thy"}
  第 1035 行，一行而已：

  @{verbatim "invs \<equiv> valid_state and cur_tcb"}

  展开来是一条\emph{谓词上的合取链}（@{verbatim "and"} 就是 HOL 里
  @{verbatim "inf"} 在 @{verbatim "'s \<Rightarrow> bool"} 上的实例）：
  @{verbatim "valid_state"}（第 998 行）有二十几条合取，它自己包含
  @{verbatim "valid_pspace"}（第 800 行）、@{verbatim "valid_mdb"}（第 899 行）、
  @{verbatim "valid_idle"}（第 913 行）、@{verbatim "valid_global_refs"}
  （第 956 行）；@{verbatim "valid_pspace"} 又包含
  @{verbatim "valid_objs"}（同文件第 557 行）。

  \begin{itemize}
    \item @{verbatim "valid_objs"}：@{verbatim "kheap"} 里每个对象都对自己的类型合法；
    \item @{verbatim "valid_mdb"}：CDT 结构良好（无环、父亲覆盖同一对象、……）；
    \item @{verbatim "pspace_aligned"}：对象按自己的大小对齐，见
          @{verbatim "l4v/proof/invariant-abstract/InvariantsPre_AI.thy"} 第 104 行；
    \item @{verbatim "pspace_distinct"}：对象占的地址区间互不重叠（同一文件第 115 行），
          第 15 章那条 @{verbatim "chunks_stay_inside"} 在系统层面的形态；
    \item @{verbatim "cur_tcb"}：当前线程是一个存在的 TCB。
  \end{itemize}

  本章先把"合取链"这件事本身写成可证的定理。
\<close>

ML \<open>writeln "==== 17 开始 ===="\<close>

text \<open>
  这份记号不是 HOL 自带的，是库自己给的：
  @{verbatim "l4v/lib/Monads/Fun_Pred_Syntax.thy"} 第 26--27 行的
  @{verbatim "pred_conj"} 把它缩写成函数上的 @{verbatim "inf"}，
  第 62 行才配上中缀（@{verbatim "infixl"}）；
  同一份代码库里另一处
  @{verbatim "pred_and"}（@{verbatim "l4v/lib/sep_algebra/Separation_Algebra.thy"}
  第 25 行）用的却是 @{verbatim "infixr"}。
  本章照前一种写法抄一份，理由是同一个文件第 61 行的注释：
  用 @{verbatim "infixl"} 是为了"从左边把合取支拆出来"。
\<close>

definition pred_and :: "('a \<Rightarrow> bool) \<Rightarrow> ('a \<Rightarrow> bool) \<Rightarrow> 'a \<Rightarrow> bool"
  (infixl "and" 35) where
  "a and b \<equiv> \<lambda>s. a s \<and> b s"

lemma and_apply: "(P and Q) s = (P s \<and> Q s)"
  by (simp add: pred_and_def)

lemma and3_apply: "((P and Q) and R) s = (P s \<and> Q s \<and> R s)"
  by (simp add: pred_and_def)

lemma andD1: "(P and Q) s \<Longrightarrow> P s"
  by (simp add: pred_and_def)

lemma andD2: "(P and Q) s \<Longrightarrow> Q s"
  by (simp add: pred_and_def)

text \<open>
  这四条就是 @{verbatim "invs \<equiv> valid_state and cur_tcb"}
  这类式子的全部技术含量：合取链没有新的逻辑内容，它只是\emph{把很多条性质
  起一个名字}。真正的后果是\emph{两个方向}的：证明时要一条一条证，
  使用时可以一条一条取出来（@{thm andD1} 与 @{thm andD2}），
  而 "@{verbatim "invs and 额外条件"}" 这种写法就是 17.5--17.6 要用的。
\<close>

subsection \<open>17.2 模型状态与 @{verbatim "valid_objs"}\<close>

text \<open>
  真实规范里 @{verbatim "valid_objs"} 只说"堆里每个对象都 @{verbatim "valid_obj"}"，
  类型与引用的一致性藏在 @{verbatim "valid_obj"} 的分支里
  （@{verbatim "Invariants_AI.thy"} 第 547 行）：CNode 那一支走
  @{verbatim "valid_cs"}（第 426 行），而 @{verbatim "valid_cs"} 说的正是
  "槽里\emph{每个}能力都合法"。本章把这个"合法"具体化成
  "能力指向的对象存在且类型对得上"。
\<close>

type_synonym obj_ref = nat
type_synonym cslot_ptr = "obj_ref \<times> nat"

datatype otype = EndpointType | NotificationType | UntypedType

datatype cap = NullCap | EndpointCap obj_ref | NotificationCap obj_ref | UntypedCap obj_ref

record kstate =
  ks_objs  :: "obj_ref \<Rightarrow> otype option"
  ks_caps  :: "cslot_ptr \<Rightarrow> cap option"
  ks_cdt   :: "cslot_ptr \<Rightarrow> cslot_ptr option"

text \<open>
  第三个字段的类型抄自
  @{verbatim "l4v/spec/abstract/Structures_A.thy"} 第 532 行的那个
  @{verbatim "cdt"}——"槽位到父槽位的偏函数"，第 05 章的 CDT 就是这个东西。
\<close>

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

definition valid_objs :: "kstate \<Rightarrow> bool" where
  "valid_objs s \<equiv> \<forall>sl c. ks_caps s sl = Some c \<longrightarrow>
      (case cap_target c of
          None   \<Rightarrow> True
        | Some p \<Rightarrow> ks_objs s p = cap_type c)"

lemma empty_state_is_valid:
  "valid_objs \<lparr> ks_objs = \<lambda>_. None, ks_caps = \<lambda>_. None, ks_cdt = \<lambda>_. None \<rparr>"
  by (simp add: valid_objs_def)

lemma valid_objsI:
  "(\<And>sl c. ks_caps s sl = Some c \<Longrightarrow>
        case cap_target c of None \<Rightarrow> True | Some p \<Rightarrow> ks_objs s p = cap_type c)
   \<Longrightarrow> valid_objs s"
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

subsection \<open>17.3 插入能力：只在对象存在且类型对得上时才保持\<close>

definition insert_cap :: "cap \<Rightarrow> cslot_ptr \<Rightarrow> kstate \<Rightarrow> kstate" where
  "insert_cap c sl s \<equiv> s\<lparr> ks_caps := (ks_caps s)(sl \<mapsto> c) \<rparr>"

lemma insert_cap_untouched [simp]: "ks_cdt (insert_cap c sl s) = ks_cdt s"
  by (simp add: insert_cap_def)

lemma insert_cap_ks_objs [simp]: "ks_objs (insert_cap c sl s) = ks_objs s"
  by (simp add: insert_cap_def)

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
  真实内核在 retype 时靠 @{verbatim "default_cap"} 保证类型与对象一致
  （@{verbatim "l4v/spec/abstract/Retype_A.thy"} 第 31--36 行）：
  新建对象时写进目的槽的能力就是由那个对象类型算出来的，
  所以"@{verbatim "EndpointCap"} 指向一个通知对象"这类状态根本构造不出来。
\<close>

subsection \<open>17.4 @{verbatim "valid_mdb"}：CDT 边的两端都得有非空能力\<close>

text \<open>
  真实 @{verbatim "valid_mdb"} 的定义见
  @{verbatim "l4v/proof/invariant-abstract/Invariants_AI.thy"}
  第 899--907 行，十条合取。第一条写的是
  @{verbatim "mdb_cte_at (swp (cte_wp_at ((\<noteq>) NullCap)) s) (cdt s)"}：
  这两个名字（@{verbatim "mdb_cte_at"}、@{verbatim "swp"}）都不在这份代码树里
  （它们来自 l4v 依赖的 AbsSpec 会话），所以本章只对第一条读到这里为止——
  它谈的是"CDT 边上的槽得真的持有非空能力"。
  模型里把这一条具体化成"@{verbatim "ks_cdt"} 的每条边，两端都不是空格"，
  这既是对第一条的一种读法，也是后面 @{verbatim "delete_cap"} 会破坏的那种性质。
\<close>

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

lemma insert_cap_preserves_valid_mdb:
  "valid_mdb s \<Longrightarrow> valid_mdb (insert_cap NullCap sl s)"
  by (auto simp: valid_mdb_def insert_cap_def split: option.splits)

subsection \<open>17.5 删除能力：为什么 l4v 要先问 @{verbatim "emptyable"}\<close>

text \<open>
  插入很温顺，删除不是。这里照内核的做法定义删除：
  能力清成空格、这个槽自己的 CDT 边一起摘掉，
  但\emph{别人的}边指向它时不动。于是 17.4 那条不变式可以当场破掉：
\<close>

definition delete_cap :: "cslot_ptr \<Rightarrow> kstate \<Rightarrow> kstate" where
  "delete_cap sl s \<equiv>
     s\<lparr> ks_caps := (ks_caps s)(sl := None),
          ks_cdt  := (ks_cdt s)(sl := None) \<rparr>"

lemma delete_cap_ks_caps [simp]: "ks_caps (delete_cap sl s) = (ks_caps s)(sl := None)"
  by (simp add: delete_cap_def)

lemma delete_cap_ks_cdt [simp]: "ks_cdt (delete_cap sl s) = (ks_cdt s)(sl := None)"
  by (simp add: delete_cap_def)

lemma delete_cap_ks_objs [simp]: "ks_objs (delete_cap sl s) = ks_objs s"
  by (simp add: delete_cap_def)

lemma valid_mdbD:
  "valid_mdb s \<Longrightarrow> ks_cdt s child = Some parent \<Longrightarrow> ks_caps s parent \<noteq> None"
  unfolding valid_mdb_def by blast

lemma valid_mdbD_child:
  "valid_mdb s \<Longrightarrow> ks_cdt s child = Some parent \<Longrightarrow> ks_caps s child \<noteq> None"
  unfolding valid_mdb_def by blast

lemma delete_parent_cap_breaks_valid_mdb:
  "\<lbrakk>ks_cdt s child = Some parent; child \<noteq> parent\<rbrakk>
   \<Longrightarrow> \<not> valid_mdb (delete_cap parent s)"
proof
  assume edge: "ks_cdt s child = Some parent" and ne: "child \<noteq> parent"
  have cdt': "ks_cdt (delete_cap parent s) child = Some parent"
    using ne edge by (auto simp: delete_cap_def split: if_splits)
  have nf: "ks_caps (delete_cap parent s) parent = None"
    by (simp add: delete_cap_def)
  assume "valid_mdb (delete_cap parent s)"
  then have "ks_caps (delete_cap parent s) parent \<noteq> None"
    by (rule valid_mdbD [OF _ cdt'])
  with nf show False by blast
qed

text \<open>
  这就是 @{verbatim "l4v/proof/invariant-abstract/CNodeInv_AI.thy"}
  第 2527 行的 @{verbatim "cap_delete_invs"} 为什么要在前件里额外要求
  @{verbatim "emptyable ptr"}：先把子孙从 CDT 上摘干净，才允许删。
  模型里对应的条件是"没有任何槽将此人认作父亲"。
\<close>

definition no_children :: "cslot_ptr \<Rightarrow> kstate \<Rightarrow> bool" where
  "no_children sl s \<equiv> \<forall>sl'. ks_cdt s sl' \<noteq> Some sl"

lemma delete_cap_preserves_valid_objs:
  "valid_objs s \<Longrightarrow> valid_objs (delete_cap sl s)"
  by (auto simp: valid_objs_def delete_cap_def split: option.splits)

lemma delete_cap_keeps_valid_mdb_if_no_children:
  "valid_mdb s \<Longrightarrow> no_children parent s \<Longrightarrow> valid_mdb (delete_cap parent s)"
  by (auto simp: valid_mdb_def delete_cap_def no_children_def)

subsection \<open>17.6 打包成 @{verbatim "invs"}：使用与保持\<close>

definition invs :: "kstate \<Rightarrow> bool" where
  "invs s \<equiv> valid_objs s \<and> valid_mdb s"

lemma invsI: "valid_objs s \<Longrightarrow> valid_mdb s \<Longrightarrow> invs s"
  by (simp add: invs_def)

lemma invsD_objs: "invs s \<Longrightarrow> valid_objs s"
  by (simp add: invs_def)

lemma invsD_mdb: "invs s \<Longrightarrow> valid_mdb s"
  by (simp add: invs_def)

lemma invs_insert_null: "invs s \<Longrightarrow> invs (insert_cap NullCap sl s)"
  using insert_cap_preserves_valid_objs insert_cap_preserves_valid_mdb
  by (auto simp: invs_def)

lemma invs_delete_if_no_children: "invs s \<Longrightarrow> no_children sl s \<Longrightarrow> invs (delete_cap sl s)"
  using delete_cap_preserves_valid_objs delete_cap_keeps_valid_mdb_if_no_children
  by (auto simp: invs_def)

text \<open>
  两条 @{verbatim "invsD_*"} 对应 l4v 里那条
  @{verbatim "invs_valid_objs"}（@{verbatim "Invariants_AI.thy"}
  第 3308 行，标着 @{verbatim "[elim!]"}）；
  两条保持性对应那批 @{verbatim "xxx_invs [wp]"} 规则，
  形状是前件 @{verbatim "invs and emptyable ptr"}、后件 @{verbatim "(\<lambda>rv. invs)"}。
  第 16 章说 @{verbatim "invariant f P"} 读作"@{verbatim "f"} 保住 @{verbatim "P"}"，
  那些规则就是它的实例：前件是 @{verbatim "invs"} 加一条额外条件，
  后件把返回值丢掉、仍然是 @{verbatim "invs"}。
\<close>

subsection \<open>17.7 模型比规范弱：环混得过去\<close>

text \<open>
  17.4 明说了模型只取 @{verbatim "valid_mdb"} 十条合取里的第一条。
  这一节把"少掉了什么"做成定理：真实规范里同一段定义的第 902 行有
  @{verbatim "no_mloop"}（CDT 无环），模型里没有。
  于是下面这个状态满足本章的 @{verbatim "invs"}，
  却因为两个槽互相认作父亲而不满足真实规范。
\<close>

definition parent_rel :: "kstate \<Rightarrow> (cslot_ptr \<times> cslot_ptr) set" where
  "parent_rel s \<equiv> {(c, p). ks_cdt s c = Some p}"

text \<open>
  写成"@{verbatim "R^+"} 里没有形如 @{verbatim "(x, x)"} 的对"最贴近
  @{verbatim "no_mloop"} 的原意，但 @{verbatim "cslot_ptr"} 本身是个二元组，
  所以这里把量词拆成"@{verbatim "cp"} 的两半各是什么"，
  后面 @{verbatim "acyclicD"} 用起来才不会和 simplifier 的
  拆对规则打架。
\<close>

definition acyclic :: "kstate \<Rightarrow> bool" where
  "acyclic s \<equiv> \<forall>cp \<in> (parent_rel s)^+. fst cp \<noteq> snd cp"

lemma acyclicD: "\<lbrakk>acyclic s; (c, p) \<in> (parent_rel s)^+\<rbrakk> \<Longrightarrow> c \<noteq> p"
  unfolding acyclic_def by auto

lemma acyclicI: "(\<And>c p. (c, p) \<in> (parent_rel s)^+ \<Longrightarrow> c \<noteq> p) \<Longrightarrow> acyclic s"
  by (auto simp: acyclic_def)

definition cycle_state :: "cslot_ptr \<Rightarrow> cslot_ptr \<Rightarrow> kstate" where
  "cycle_state a b \<equiv>
     \<lparr> ks_objs = \<lambda>_. None,
       ks_caps = \<lambda>_. Some NullCap,
       ks_cdt  = (\<lambda>_. None)(a := Some b, b := Some a) \<rparr>"

lemma cycle_state_has_invs: "invs (cycle_state a b)"
  unfolding cycle_state_def invs_def valid_objs_def valid_mdb_def cap_target_def
  by (auto split: option.splits)

lemma cycle_state_edges:
  "(a, b) \<in> parent_rel (cycle_state a b) \<and> (b, a) \<in> parent_rel (cycle_state a b)"
  by (auto simp: parent_rel_def cycle_state_def)

lemma cycle_state_loop: "(a, a) \<in> (parent_rel (cycle_state a b))^+"
  by (auto intro: r_r_into_trancl simp: parent_rel_def cycle_state_def)

text \<open>
  注意下面这条\emph{不}需要 @{verbatim "a \<noteq> b"}：两个槽互相认作父亲时
  有环，@{verbatim "a = b"}（自己认作自己的父亲）时同样有环。
  真实规范里 @{verbatim "no_mloop"} 说的就是这两种情况都不许出现。
\<close>

lemma cycle_state_not_acyclic: "\<not> acyclic (cycle_state a b)"
  by (meson acyclicD cycle_state_loop)

text \<open>
  下面这条把"@{verbatim "cycle_state"} 真的是两个槽互相认作父亲"说出来，
  代入 @{verbatim "(0, 0)"} 与 @{verbatim "(0, 1)"} 就是一对\emph{不同}的槽位。
\<close>

lemma model_admits_cdt_cycles: "\<exists>s. invs s \<and> \<not> acyclic s"
proof -
  have "invs (cycle_state (0, 0) (0, 1)) \<and> \<not> acyclic (cycle_state (0, 0) (0, 1))"
    by (rule conjI [OF cycle_state_has_invs cycle_state_not_acyclic])
  then show ?thesis by blast
qed

lemma parent_rel_insert [simp]: "parent_rel (insert_cap cap ptr s) = parent_rel s"
  by (simp add: parent_rel_def insert_cap_def)

lemma acyclic_insert_cap: "acyclic s \<Longrightarrow> acyclic (insert_cap cap ptr s)"
  by (intro acyclicI) (erule acyclicD, simp)

lemma parent_rel_delete_subset: "parent_rel (delete_cap ptr s) \<subseteq> parent_rel s"
  by (auto simp: parent_rel_def delete_cap_def split: if_splits)

lemma acyclic_delete_cap: "acyclic s \<Longrightarrow> acyclic (delete_cap ptr s)"
proof (rule acyclicI)
  fix c p
  assume ac: "acyclic s"
  assume step: "(c, p) \<in> (parent_rel (delete_cap ptr s))^+"
  have "(c, p) \<in> (parent_rel s)^+"
    by (rule subsetD [OF _ step])
       (rule trancl_mono_subset [OF parent_rel_delete_subset])
  from acyclicD [OF ac this] show "c \<noteq> p" .
qed

text \<open>
  最后两条是这一节的实用结论，也是两种\emph{不一样}的保持性。
  @{verbatim "insert_cap"} 根本不碰 CDT（第一条证明只有定义），
  对新增的这条不变式是\emph{白送}的；
  @{verbatim "delete_cap"} 碰了——它摘掉自己那条出边——但删边只会让
  父亲关系\emph{变小}，而"无环"对取子集是封闭的
  （@{thm parent_rel_delete_subset} 加 @{verbatim "trancl_mono_subset"}），
  所以仍然是白送的。
\<close>

text \<open>
  白送是模型的便宜，不是规范的便宜。真实证明里 @{verbatim "no_mloop"}
  从来不是这么过的：第 05、06 章的 revoke、delete、retype 都会\emph{加}边，
  而加边恰恰是可能造出环的那一步，所以每一个改 CDT 的操作
  都得单独重证一次无环（l4v 里那批 @{verbatim "no_mloop"} 引理）。
  这就是"加一条不变式，全树跟着重证一遍"的成本。
  本章的模型之所以躲掉了这笔账，是因为它的两个操作压根不会往 CDT 上加边——
  这一句本身就是 17.4 那句"模型只取十条合取里的第一条"的具体代价。
\<close>

ML \<open>
  writeln (@{make_string} @{thm delete_parent_cap_breaks_valid_mdb});
  writeln (@{make_string} @{thm invs_delete_if_no_children});
  writeln (@{make_string} @{thm model_admits_cdt_cycles});
  writeln (@{make_string} @{thm and3_apply})
\<close>

ML \<open>writeln "==== 17 结束 ===="\<close>

end
