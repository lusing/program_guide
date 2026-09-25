theory S23_capdl
  imports Main
begin

section \<open>23.1 capDL：只描述保护状态的那一层\<close>

text \<open>
  前面几章都在证"内核的每一步"。capDL 换了一个问题：
  \emph{"这一整套系统配置长什么样"}。它不是运行时的东西，而是
  一张能力分布图。规范在 @{verbatim "l4v/spec/capDL/"}，
  @{verbatim "README.md"} 第 12 行起把口径写得很死：这一层
  "models the complete protection state of the kernel in terms of
  capabilities, and models, as far as possible, only the protection state
  of the kernel (no memory or other state)"，
  并且紧接着承认 "the capDL specification contains a significantly higher
  degree of nondeterminism compared to the other seL4 specs"——
  这一层故意比别的层更非确定（23.8 会看到为什么）。

  类型层真正的定义在 @{verbatim "Types_D.thy"}，不是 @{verbatim "Structures_D.thy"}：
  后者全文 18 行，是个架构包装。对象与能力的全部形状都在
  @{verbatim "Types_D.thy"}：能力是第 113 行那个
  @{verbatim "datatype cdl_cap"}，内核对象是第 245 行的
  @{verbatim "datatype cdl_object"}，整个系统是第 301 行的
  @{verbatim "record cdl_state"}。
\<close>

ML \<open>writeln "==== 23 开始 ===="\<close>

type_synonym obj_id = nat

type_synonym slot = nat

text \<open>
  真实的对象名是机器字（第 55 行 @{verbatim "cdl_object_id = machine_word"}），
  第 49--53 行的注释还特意说明"这个名字\emph{可以}对应对象的内存地址"。
  能力的位置则是第 191--195 行那条 @{verbatim "translations"} 给出的二元组：
  @{verbatim "cdl_cap_ref"} 就是 (对象, 槽)。
\<close>

type_synonym cap_ref = "obj_id \<times> slot"

datatype cdl_arch = AARCH32 | AARCH64 | RISCV32 | RISCV64 | IA32 | X64

text \<open>
  六个架构常量照抄 @{verbatim "Setup_D.thy"} 第 15 行。
  权利只有四种，而且 capDL 并不自己定义它：
  @{verbatim "Intents_D.thy"} 第 39 行写的是
  @{verbatim "type_synonym cdl_right = rights"}，
  直接复用抽象规范那四个 @{verbatim "rights"} 构造子。
\<close>

datatype right = AllowRead | AllowWrite | AllowGrant | AllowGrantReply

type_synonym cdl_right = right

definition all_cdl_rights :: "cdl_right set" where
  "all_cdl_rights = {AllowRead, AllowWrite, AllowGrant, AllowGrantReply}"

lemma all_cdl_rights_UNIV: "all_cdl_rights = UNIV"
  unfolding all_cdl_rights_def
  apply (auto split: right.splits)
  by (metis right.exhaust)

subsection \<open>23.2 能力：只有四种能力带权利字段\<close>

text \<open>
  这里挑真实 @{verbatim "cdl_cap"}（第 113 行起，共 29 个构造子）里
  IPC、CSpace、内存三类常用的 12 个，构造子名与参数元数保持一致。
  两个细节值得照抄：@{verbatim "UntypedCap"} 带\emph{两个}对象集合
  （@{verbatim "UntypedCap bool cdl_object_set cdl_object_set"}），
  而 @{verbatim "DomainCap"}、@{verbatim "RestartCap"}、@{verbatim "RunningCap"}、
  @{verbatim "IrqControlCap"} 是\emph{零参}的——它们不指向任何对象。
\<close>

datatype cdl_cap =
    NullCap
  | UntypedCap bool "obj_id set" "obj_id set"
  | EndpointCap obj_id obj_id "cdl_right set"
  | NotificationCap obj_id obj_id "cdl_right set"
  | ReplyCap obj_id "cdl_right set"
  | CNodeCap obj_id nat nat nat
  | TcbCap obj_id
  | FrameCap bool obj_id "cdl_right set" nat
  | DomainCap
  | RestartCap
  | RunningCap
  | IrqControlCap

text \<open>
  @{verbatim "cap_rights"}（第 446 行）的形状是"四个构造子取自己的字段，
  其余一律 @{verbatim "all_cdl_rights"}"。这条兜底把 @{verbatim "NullCap"}
  也算进去了——空能力的权利是全集。听起来别扭，但
  @{verbatim "update_cap_rights"}（第 455 行）正是靠"不是这四类就原样返回"
  来保证削权不会作用到别的能力上。
\<close>

definition cap_rights :: "cdl_cap \<Rightarrow> cdl_right set" where
  "cap_rights c \<equiv> case c of
      FrameCap _ _ R _      \<Rightarrow> R
    | NotificationCap _ _ R \<Rightarrow> R
    | EndpointCap _ _ R     \<Rightarrow> R
    | ReplyCap _ R          \<Rightarrow> R
    | _                     \<Rightarrow> all_cdl_rights"

definition update_cap_rights :: "cdl_right set \<Rightarrow> cdl_cap \<Rightarrow> cdl_cap" where
  "update_cap_rights r c \<equiv> case c of
      FrameCap dev f1 _ f2   \<Rightarrow> FrameCap dev f1 r f2
    | NotificationCap f1 f2 _ \<Rightarrow> NotificationCap f1 f2 (r - {AllowGrant, AllowGrantReply})
    | EndpointCap f1 f2 _     \<Rightarrow> EndpointCap f1 f2 r
    | ReplyCap f1 _           \<Rightarrow> ReplyCap f1 (r - {AllowRead, AllowGrantReply} \<union> {AllowWrite})
    | _                       \<Rightarrow> c"

lemma cap_rights_endpoint: "cap_rights (EndpointCap p b R) = R"
  by (simp add: cap_rights_def)

lemma cap_rights_cnode_is_all: "cap_rights (CNodeCap p g gs sz) = all_cdl_rights"
  by (simp add: cap_rights_def)

lemma cap_rights_nullcap_is_all: "cap_rights NullCap = all_cdl_rights"
  by (simp add: cap_rights_def)

lemma update_cap_rights_notification_drops_grant:
  "cap_rights (update_cap_rights r (NotificationCap p b R)) = r - {AllowGrant, AllowGrantReply}"
  by (simp add: update_cap_rights_def cap_rights_def)

lemma update_cap_rights_reply_forces_write:
  "AllowWrite \<in> cap_rights (update_cap_rights r (ReplyCap p R))"
  by (simp add: update_cap_rights_def cap_rights_def)

lemma update_cap_rights_leaves_cnode: "update_cap_rights r (CNodeCap p g gs sz) = CNodeCap p g gs sz"
  by (simp add: update_cap_rights_def)

text \<open>
  后三条实测正好是第 21 章那两件事在 capDL 层的对应物：
  通知能力拿不到 @{verbatim "Grant"}/@{verbatim "GrantReply"}，
  reply 能力被硬塞 @{verbatim "Write"} 并被拿掉 @{verbatim "Read"}。
\<close>

subsection \<open>23.3 对象：十种内核对象，只有五种有槽\<close>

type_synonym cap_map = "slot \<Rightarrow> cdl_cap option"

text \<open>
  真实的名字是 @{verbatim "cdl_cap_map"}（第 177 行）。带槽的对象各有一个 record：
  @{verbatim "cdl_tcb"}（第 211 行）、@{verbatim "cdl_cnode"}（第 219 行）、
  @{verbatim "cdl_asid_pool"}（第 223 行）、@{verbatim "cdl_irq_node"}（第 238 行），
  加上 @{verbatim "PageTable"} 自己直接带一张 @{verbatim "cdl_cap_map"}。
  槽号 @{verbatim "tcb_pending_op_slot"} 在真实规范里是明写的 5
  （第 347 行），它决定这个线程算不算"活跃"（23.8）。
\<close>

record cdl_tcb_extra =
  cdl_tcb_prio :: nat
  cdl_tcb_mcp  :: nat
  cdl_tcb_ip   :: obj_id
  cdl_tcb_sp   :: obj_id

record cdl_tcb =
  cdl_tcb_caps :: cap_map
  cdl_tcb_domain :: nat
  cdl_tcb_has_fault :: bool
  cdl_tcb_extra :: cdl_tcb_extra

record cdl_cnode =
  cdl_cnode_caps :: cap_map
  cdl_cnode_size_bits :: nat

record cdl_asid_pool =
  cdl_asid_pool_caps :: cap_map

record cdl_irq_node =
  cdl_irq_node_caps :: cap_map

datatype cdl_object =
    Endpoint
  | Notification
  | Untyped
  | Frame nat
  | VCPU
  | Tcb cdl_tcb
  | CNode cdl_cnode
  | AsidPool cdl_asid_pool
  | PageTable nat cap_map
  | IRQNode cdl_irq_node

datatype cdl_object_type =
    EndpointType
  | NotificationType
  | TcbType
  | CNodeType
  | IRQNodeType
  | UntypedType
  | AsidPoolType
  | PageTableType nat
  | FrameType nat
  | VCPUType

definition object_type :: "cdl_object \<Rightarrow> cdl_object_type" where
  "object_type x \<equiv> case x of
      Untyped \<Rightarrow> UntypedType
    | Endpoint \<Rightarrow> EndpointType
    | Notification \<Rightarrow> NotificationType
    | Tcb _ \<Rightarrow> TcbType
    | CNode _ \<Rightarrow> CNodeType
    | IRQNode _ \<Rightarrow> IRQNodeType
    | AsidPool _ \<Rightarrow> AsidPoolType
    | PageTable l _ \<Rightarrow> PageTableType l
    | Frame f \<Rightarrow> FrameType f
    | VCPU \<Rightarrow> VCPUType"

definition object_slots :: "cdl_object \<Rightarrow> cap_map" where
  "object_slots obj \<equiv> case obj of
      PageTable _ x \<Rightarrow> x
    | AsidPool x \<Rightarrow> cdl_asid_pool_caps x
    | CNode x \<Rightarrow> cdl_cnode_caps x
    | Tcb x \<Rightarrow> cdl_tcb_caps x
    | IRQNode x \<Rightarrow> cdl_irq_node_caps x
    | _ \<Rightarrow> Map.empty"

definition update_slots :: "cap_map \<Rightarrow> cdl_object \<Rightarrow> cdl_object" where
  "update_slots new_val obj \<equiv> case obj of
      PageTable l x \<Rightarrow> PageTable l new_val
    | AsidPool x \<Rightarrow> AsidPool (x\<lparr>cdl_asid_pool_caps := new_val\<rparr>)
    | CNode x \<Rightarrow> CNode (x\<lparr>cdl_cnode_caps := new_val\<rparr>)
    | Tcb x \<Rightarrow> Tcb (x\<lparr>cdl_tcb_caps := new_val\<rparr>)
    | IRQNode x \<Rightarrow> IRQNode (x\<lparr>cdl_irq_node_caps := new_val\<rparr>)
    | _ \<Rightarrow> obj"

definition has_slots :: "cdl_object \<Rightarrow> bool" where
  "has_slots obj \<equiv> case obj of
      PageTable _ _ \<Rightarrow> True
    | AsidPool _ \<Rightarrow> True
    | CNode _ \<Rightarrow> True
    | Tcb _ \<Rightarrow> True
    | IRQNode _ \<Rightarrow> True
    | _ \<Rightarrow> False"

lemma has_slots_five:
  "has_slots (Tcb t) \<and> has_slots (CNode c) \<and> has_slots (AsidPool a)
     \<and> has_slots (PageTable l m) \<and> has_slots (IRQNode i)"
  by (simp add: has_slots_def)

lemma has_slots_others:
  "\<not> has_slots Endpoint \<and> \<not> has_slots Notification \<and> \<not> has_slots Untyped
     \<and> \<not> has_slots (Frame n) \<and> \<not> has_slots VCPU"
  by (simp add: has_slots_def)

lemma object_slots_no_slots:
  "object_slots Endpoint = Map.empty \<and> object_slots Untyped = Map.empty
     \<and> object_slots VCPU = Map.empty"
  by (simp add: object_slots_def)

lemma update_slots_no_slots: "\<not> has_slots obj \<Longrightarrow> update_slots m obj = obj"
  by (cases obj) (auto simp: has_slots_def update_slots_def)

lemma object_slots_update_slots:
  "object_slots (update_slots m obj) = (if has_slots obj then m else Map.empty)"
  by (cases obj) (auto simp: object_slots_def update_slots_def has_slots_def)

lemma object_type_Tcb: "object_type (Tcb t) = TcbType"
  by (simp add: object_type_def)

lemma object_type_PageTable_carries_level: "object_type (PageTable l m) = PageTableType l"
  by (simp add: object_type_def)

text \<open>
  @{text has_slots} 与 @{text update_slots} 这对组合是 capDL 的一个设计要点：
  端点、通知、Untyped、Frame、VCPU \emph{没有}槽，
  所以对它们"写一个能力"是无操作的（@{thm update_slots_no_slots}）。
  真实 @{verbatim "set_cap"}（"@{verbatim "KHeap_D.thy"}"第 81 行）
  因此在写之前要 @{verbatim "assert (has_slots obj"}。
\<close>

subsection \<open>23.4 状态：一张堆、一棵 CDT、一个当前线程\<close>

record cdl_state =
  sarch :: cdl_arch
  cdl_objects :: "obj_id \<Rightarrow> cdl_object option"
  cdl_cdt :: "cap_ref \<Rightarrow> cap_ref option"
  cdl_current_thread :: "obj_id option"
  cdl_current_domain :: nat
  cdl_irq_node :: "nat \<Rightarrow> obj_id"

text \<open>
  六个字段取自真实 @{verbatim "record cdl_state"}（第 301 行）；
  真实那份还有 @{verbatim "cdl_asid_table"}、@{verbatim "cdl_dom_schedule"}、
  @{verbatim "cdl_dom_start"} 三个调度字段。
  @{verbatim "cdl_objects"} 的类型是第 258 行的
  @{verbatim "cdl_heap = cdl_object_id \<Rightarrow> cdl_object option"}。
\<close>

definition empty_state :: cdl_state where
  "empty_state \<equiv> \<lparr> sarch = AARCH64,
                       cdl_objects = Map.empty,
                       cdl_cdt = Map.empty,
                       cdl_current_thread = None,
                       cdl_current_domain = 0,
                       cdl_irq_node = \<lambda>_. 0 \<rparr>"

definition get_object :: "obj_id \<Rightarrow> cdl_state \<Rightarrow> cdl_object option" where
  "get_object p s \<equiv> cdl_objects s p"

definition set_object :: "obj_id \<Rightarrow> cdl_object \<Rightarrow> cdl_state \<Rightarrow> cdl_state" where
  "set_object p obj s \<equiv> s\<lparr>cdl_objects := (\<lambda>x. if x = p then Some obj else cdl_objects s x)\<rparr>"

lemma get_object_set_object_same: "get_object p (set_object p obj s) = Some obj"
  by (simp add: get_object_def set_object_def)

lemma get_object_set_object_other: "p \<noteq> q \<Longrightarrow> get_object q (set_object p obj s) = get_object q s"
  by (simp add: get_object_def set_object_def)

lemma set_object_preserves_cdt: "cdl_cdt (set_object p obj s) = cdl_cdt s"
  by (simp add: set_object_def)

lemma set_object_preserves_current_thread: "cdl_current_thread (set_object p obj s) = cdl_current_thread s"
  by (simp add: set_object_def)

definition opt_cap :: "cap_ref \<Rightarrow> cdl_state \<Rightarrow> cdl_cap option" where
  "opt_cap ref s \<equiv> case get_object (fst ref) s of
      None \<Rightarrow> None
    | Some obj \<Rightarrow> object_slots obj (snd ref)"

definition set_cap :: "cap_ref \<Rightarrow> cdl_cap \<Rightarrow> cdl_state \<Rightarrow> cdl_state option" where
  "set_cap ref cap s \<equiv> case get_object (fst ref) s of
      None \<Rightarrow> None
    | Some obj \<Rightarrow>
        if has_slots obj
        then Some (set_object (fst ref)
                   (update_slots (\<lambda>x. if x = snd ref then Some cap else object_slots obj x) obj) s)
        else None"

lemma opt_cap_missing_object: "get_object p s = None \<Longrightarrow> opt_cap (p, sl) s = None"
  by (simp add: opt_cap_def split: option.splits)

lemma opt_cap_endpoint_is_none: "get_object p s = Some Endpoint \<Longrightarrow> opt_cap (p, sl) s = None"
  by (simp add: opt_cap_def get_object_def object_slots_def split: option.splits)

lemma set_cap_missing_object: "get_object p s = None \<Longrightarrow> set_cap (p, sl) cap s = None"
  by (simp add: set_cap_def split: option.splits)

lemma set_cap_no_slots: "get_object p s = Some Endpoint \<Longrightarrow> set_cap (p, sl) cap s = None"
  by (simp add: set_cap_def has_slots_def split: option.splits)

lemma set_cap_cnode_reads_back:
  assumes "get_object p s = Some (CNode cn)"
  shows "opt_cap (p, sl) (the (set_cap (p, sl) cap s)) = Some cap"
  using assms
  by (simp add: set_cap_def opt_cap_def get_object_def set_object_def object_slots_def
                update_slots_def has_slots_def split: option.splits if_splits)

subsection \<open>23.5 CDT：能力推导树就是父亲指针\<close>

text \<open>
  @{verbatim "Types_D.thy"} 第 179--188 行的注释把 CDT 的用途说透了：
  "if an entity revokes a particular cap, all of the cap's children
  (as recorded in the CDT) are also revoked"——
  第 6 章撤销的根据就在这棵树里。类型是第 189 行的
  @{verbatim "cdl_cdt = cdl_cap_ref \<Rightarrow> cdl_cap_ref option"}：一个父亲指针函数。
\<close>

definition opt_parent :: "cap_ref \<Rightarrow> cdl_state \<Rightarrow> cap_ref option" where
  "opt_parent p s \<equiv> cdl_cdt s p"

definition set_parent :: "cap_ref \<Rightarrow> cap_ref \<Rightarrow> cdl_state \<Rightarrow> cdl_state option" where
  "set_parent child parent s \<equiv>
     if cdl_cdt s child = None
     then Some (s\<lparr>cdl_cdt := (\<lambda>x. if x = child then Some parent else cdl_cdt s x)\<rparr>)
     else None"

definition remove_parent :: "cap_ref \<Rightarrow> cdl_state \<Rightarrow> cdl_state" where
  "remove_parent p s \<equiv>
     s\<lparr>cdl_cdt := (\<lambda>x. if x = p then None
                     else if cdl_cdt s x = Some p then cdl_cdt s p
                     else cdl_cdt s x)\<rparr>"

definition has_children :: "cap_ref \<Rightarrow> cdl_state \<Rightarrow> bool" where
  "has_children p s \<equiv> \<exists>child. cdl_cdt s child = Some p"

definition ensure_no_children :: "cap_ref \<Rightarrow> cdl_state \<Rightarrow> cdl_state option" where
  "ensure_no_children x s \<equiv> if has_children x s then None else Some s"

lemma set_parent_requires_free_child: "cdl_cdt s c \<noteq> None \<Longrightarrow> set_parent c p s = None"
  by (simp add: set_parent_def)

lemma set_parent_reads_back:
  "cdl_cdt s c = None \<Longrightarrow> opt_parent c (the (set_parent c p s)) = Some p"
  unfolding set_parent_def opt_parent_def by simp

lemma remove_parent_clears_itself: "cdl_cdt (remove_parent p s) p = None"
  by (simp add: remove_parent_def)

lemma remove_parent_rehangs_children:
  "cdl_cdt s x = Some p \<Longrightarrow> x \<noteq> p \<Longrightarrow> cdl_cdt (remove_parent p s) x = cdl_cdt s p"
  by (simp add: remove_parent_def)

lemma remove_parent_keeps_others:
  "x \<noteq> p \<Longrightarrow> cdl_cdt s x \<noteq> Some p \<Longrightarrow> cdl_cdt (remove_parent p s) x = cdl_cdt s x"
  by (simp add: remove_parent_def)

lemma has_children_witness: "cdl_cdt s x = Some p \<Longrightarrow> has_children p s"
  unfolding has_children_def by (rule exI [of _ x], assumption)

lemma ensure_no_children_blocks: "cdl_cdt s x = Some p \<Longrightarrow> ensure_no_children p s = None"
  using has_children_witness by (simp add: ensure_no_children_def)

text \<open>
  一条具体的三代链，把"删掉父亲、孩子挂到祖父"跑成可算的等式：
\<close>

definition chain_state :: cdl_state where
  "chain_state \<equiv> empty_state\<lparr>cdl_cdt :=
     (\<lambda>r. if r = ((1, 1) :: cap_ref) then Some (0, 0)
           else if r = (2, 1) then Some (1, 1) else None)\<rparr>"

lemma chain_parent_of_1_1: "opt_parent (1, 1) chain_state = Some (0, 0)"
  by (simp add: opt_parent_def chain_state_def empty_state_def)

lemma chain_parent_of_2_1: "opt_parent (2, 1) chain_state = Some (1, 1)"
  by (simp add: opt_parent_def chain_state_def empty_state_def)

lemma chain_has_children_mid: "has_children (1, 1) chain_state"
  unfolding has_children_def by (rule exI [where x = "(2, 1) :: cap_ref"]) (simp add: chain_state_def empty_state_def)

lemma chain_leaf_has_no_children: "\<not> has_children (2, 1) chain_state"
  unfolding has_children_def chain_state_def empty_state_def by (simp split: prod.splits)

lemma chain_delete_rehangs_to_grandparent:
  "opt_parent (2, 1) (remove_parent (1, 1) chain_state) = Some (0, 0)"
  unfolding opt_parent_def remove_parent_def chain_state_def empty_state_def
  by simp

subsection \<open>23.6 三种插法：orphan、sibling、child\<close>

text \<open>
  @{verbatim "CSpace_D.thy"} 给了三条只差在 CDT 上的插入：
  第 32 行 @{verbatim "insert_cap_orphan"}（"The cap will have no parent"）、
  第 58 行 @{verbatim "insert_cap_sibling"}（跟着源能力的父亲走）、
  第 72 行 @{verbatim "insert_cap_child"}（认源能力当父亲）。
  三条都先 @{verbatim "assert (old_cap = NullCap"}——目标槽必须是空的。
\<close>

definition option_bind :: "'a option \<Rightarrow> ('a \<Rightarrow> 'b option) \<Rightarrow> 'b option" (infixl "\<bind>" 54) where
  "x \<bind> f \<equiv> case x of None \<Rightarrow> None | Some y \<Rightarrow> f y"

lemma option_bind_Some: "Some x \<bind> f = f x"
  by (simp add: option_bind_def)

lemma option_bind_None: "None \<bind> f = None"
  by (simp add: option_bind_def)

definition insert_cap_orphan :: "cap_ref \<Rightarrow> cdl_cap \<Rightarrow> cdl_state \<Rightarrow> cdl_state option" where
  "insert_cap_orphan dest cap s \<equiv>
     if opt_cap dest s = Some NullCap then set_cap dest cap s else None"

definition insert_cap_child :: "cap_ref \<Rightarrow> cap_ref \<Rightarrow> cdl_cap \<Rightarrow> cdl_state \<Rightarrow> cdl_state option" where
  "insert_cap_child src dest cap s \<equiv>
     if opt_cap dest s = Some NullCap
     then set_cap dest cap s \<bind> set_parent dest src
     else None"

definition insert_cap_sibling :: "cap_ref \<Rightarrow> cap_ref \<Rightarrow> cdl_cap \<Rightarrow> cdl_state \<Rightarrow> cdl_state option" where
  "insert_cap_sibling src dest cap s \<equiv>
     if opt_cap dest s \<noteq> Some NullCap then None
     else case opt_parent src s of
            None \<Rightarrow> set_cap dest cap s
          | Some p \<Rightarrow> set_cap dest cap s \<bind> set_parent dest p"

lemma insert_cap_orphan_then_read:
  "opt_cap dest s = Some NullCap \<Longrightarrow> get_object (fst dest) s = Some (CNode cn)
     \<Longrightarrow> cdl_cdt s dest = None
     \<Longrightarrow> opt_cap dest (the (insert_cap_orphan dest cap s)) = Some cap
        \<and> opt_parent dest (the (insert_cap_orphan dest cap s)) = None"
  unfolding insert_cap_orphan_def opt_parent_def set_cap_def opt_cap_def get_object_def
    set_object_def option_bind_def
  by (simp add: object_slots_def update_slots_def has_slots_def split: option.splits if_splits)

subsection \<open>23.7 意图：capDL 连"打算拿来干什么"都写进图里\<close>

text \<open>
  真实 @{verbatim "Intents_D.thy"} 给每种对象都配了一个意图类型：
  @{verbatim "cdl_cnode_intent"}（第 101 行，九个构造子）、
  @{verbatim "cdl_tcb_intent"}（第 125 行）、
  @{verbatim "cdl_untyped_intent"}（第 159 行），
  最后由第 227 行的 @{verbatim "cdl_intent"} 收成一个大类型。
  @{verbatim "Decode_D.thy"} 第 16 行起是一整排
  @{verbatim "get_*_intent"} 投影。
\<close>

datatype cdl_cnode_intent =
    CNodeCopyIntent nat nat nat nat "cdl_right set"
  | CNodeMintIntent nat nat nat nat "cdl_right set" nat
  | CNodeMoveIntent nat nat nat nat
  | CNodeMutateIntent nat nat nat nat nat
  | CNodeRevokeIntent nat nat
  | CNodeDeleteIntent nat nat
  | CNodeSaveCallerIntent nat nat
  | CNodeCancelBadgedSendsIntent nat nat
  | CNodeRotateIntent nat nat nat nat nat nat nat nat

datatype cdl_tcb_intent =
    TcbReadRegistersIntent bool nat
  | TcbWriteRegistersIntent bool nat nat
  | TcbSuspendIntent
  | TcbResumeIntent
  | TcbSetNtfnReceiverIntent obj_id

datatype cdl_intent =
    CNodeIntent cdl_cnode_intent
  | TcbIntent cdl_tcb_intent
  | UntypedIntent bool nat
  | EndpointIntent obj_id
  | NotificationIntent obj_id
  | DomainIntent nat

definition get_cnode_intent :: "cdl_intent \<Rightarrow> cdl_cnode_intent option" where
  "get_cnode_intent i \<equiv> case i of CNodeIntent ci \<Rightarrow> Some ci | _ \<Rightarrow> None"

definition get_tcb_intent :: "cdl_intent \<Rightarrow> cdl_tcb_intent option" where
  "get_tcb_intent i \<equiv> case i of TcbIntent ti \<Rightarrow> Some ti | _ \<Rightarrow> None"

lemma get_cnode_intent_ok: "get_cnode_intent (CNodeIntent ci) = Some ci"
  by (simp add: get_cnode_intent_def)

lemma get_cnode_intent_other: "get_cnode_intent (TcbIntent ti) = None"
  by (simp add: get_cnode_intent_def)

lemma get_tcb_intent_other: "get_tcb_intent (CNodeIntent ci) = None"
  by (simp add: get_tcb_intent_def)

lemma intents_are_disjoint: "CNodeIntent ci \<noteq> TcbIntent ti"
  by simp

lemma get_cnode_intent_of_revoke:
  "get_cnode_intent (CNodeIntent (CNodeRevokeIntent a b)) = Some (CNodeRevokeIntent a b)"
  by (simp add: get_cnode_intent_def)

subsection \<open>23.8 调度在这一层是完全非确定的\<close>

text \<open>
  @{verbatim "Schedule_D.thy"} 第 35 行的注释只有一句话：
  "Scheduling is fully nondeterministic at this level."
  @{verbatim "all_active_tcbs"}（第 12 行）算的是
  "5 号槽里是 @{verbatim "RunningCap"} 或 @{verbatim "RestartCap"} 的 TCB"，
  @{verbatim "active_tcbs_in_domain"}（第 18 行）再按域筛一遍；
  @{verbatim "change_current_domain"}（第 29 行）直接
  @{verbatim "select UNIV"} 挑一个域。
\<close>

definition tcb_pending_op_slot :: slot where "tcb_pending_op_slot = 5"

definition default_extra :: cdl_tcb_extra where
  "default_extra \<equiv> \<lparr> cdl_tcb_prio = 0, cdl_tcb_mcp = 0, cdl_tcb_ip = 0, cdl_tcb_sp = 0 \<rparr>"

definition mk_tcb :: "nat \<Rightarrow> cdl_cap option \<Rightarrow> cdl_tcb" where
  "mk_tcb d opcap \<equiv> \<lparr> cdl_tcb_caps = (\<lambda>sl. if sl = tcb_pending_op_slot then opcap else None),
                       cdl_tcb_domain = d, cdl_tcb_has_fault = False,
                       cdl_tcb_extra = default_extra \<rparr>"

definition sched_state :: cdl_state where
  "sched_state \<equiv> empty_state\<lparr>cdl_objects :=
     (\<lambda>p. if p = 1 then Some (Tcb (mk_tcb 0 (Some RunningCap)))
        else if p = 2 then Some (Tcb (mk_tcb 0 (Some RestartCap)))
        else if p = 3 then Some (Tcb (mk_tcb 1 (Some RunningCap)))
        else if p = 4 then Some Endpoint
        else None)\<rparr>"

definition active_tcbs_in_domain :: "nat \<Rightarrow> cdl_state \<Rightarrow> obj_id set" where
  "active_tcbs_in_domain d s \<equiv>
     {x \<in> dom (cdl_objects s). \<exists>a. cdl_objects s x = Some (Tcb a)
        \<and> (cdl_tcb_caps a tcb_pending_op_slot = Some RunningCap
           \<or> cdl_tcb_caps a tcb_pending_op_slot = Some RestartCap)
        \<and> cdl_tcb_domain a = d}"

definition all_active_tcbs :: "cdl_state \<Rightarrow> obj_id set" where
  "all_active_tcbs s \<equiv>
     {x \<in> dom (cdl_objects s). \<exists>a. cdl_objects s x = Some (Tcb a)
        \<and> (cdl_tcb_caps a tcb_pending_op_slot = Some RunningCap
           \<or> cdl_tcb_caps a tcb_pending_op_slot = Some RestartCap)}"

definition switch_to_thread :: "obj_id option \<Rightarrow> cdl_state \<Rightarrow> cdl_state" where
  "switch_to_thread t s \<equiv> s\<lparr>cdl_current_thread := t\<rparr>"

text \<open>
  真实的 @{verbatim "schedule"}（同文件第 36 行）是两个分支的 @{verbatim "\<sqinter>"}：
  一支"换域、在活跃线程里 @{verbatim "select"}、切过去"，另一支"换域、切到
  @{verbatim "None"}"。模型把两支都留着，于是 @{text capdl_schedule} 是
  一个集合而不是函数。
\<close>

definition capdl_schedule :: "cdl_state \<Rightarrow> cdl_state set" where
  "capdl_schedule s \<equiv>
     {switch_to_thread (Some p) s |p. p \<in> active_tcbs_in_domain (cdl_current_domain s) s}
     \<union> {switch_to_thread None s}"

lemma pending_op_slot_is_5: "tcb_pending_op_slot = 5"
  by (simp add: tcb_pending_op_slot_def)

lemma mk_tcb_pending_op_running:
  "cdl_tcb_caps (mk_tcb d (Some RunningCap)) tcb_pending_op_slot = Some RunningCap"
  by (simp add: mk_tcb_def)

lemma mk_tcb_other_slot_is_none:
  "sl \<noteq> tcb_pending_op_slot \<Longrightarrow> cdl_tcb_caps (mk_tcb d opcap) sl = None"
  by (simp add: mk_tcb_def)

lemma active_in_domain_0: "active_tcbs_in_domain 0 sched_state = {1, 2}"
  unfolding active_tcbs_in_domain_def dom_def sched_state_def empty_state_def
    mk_tcb_def default_extra_def
  by (auto split: option.splits if_splits)

lemma active_in_domain_1: "active_tcbs_in_domain 1 sched_state = {3}"
  unfolding active_tcbs_in_domain_def dom_def sched_state_def empty_state_def
    mk_tcb_def default_extra_def
  by (auto split: option.splits if_splits)

lemma endpoint_not_active: "4 \<notin> active_tcbs_in_domain d sched_state"
  unfolding active_tcbs_in_domain_def dom_def sched_state_def empty_state_def
  by (auto split: option.splits if_splits)

lemma all_active_is_three: "all_active_tcbs sched_state = {1, 2, 3}"
  unfolding all_active_tcbs_def dom_def sched_state_def empty_state_def
    mk_tcb_def default_extra_def
  by (auto split: option.splits if_splits)

lemma active_in_domain_subset_all_active:
  "active_tcbs_in_domain d s \<subseteq> all_active_tcbs s"
  by (auto simp: active_tcbs_in_domain_def all_active_tcbs_def)

lemma current_domain_sched_state: "cdl_current_domain sched_state = 0"
  by (simp add: sched_state_def empty_state_def)

lemma switch_to_thread_inj:
  "switch_to_thread x s = switch_to_thread y s \<Longrightarrow> x = y"
proof -
  assume h: "switch_to_thread x s = switch_to_thread y s"
  then have "cdl_current_thread (switch_to_thread x s) = cdl_current_thread (switch_to_thread y s)"
    by simp
  then show "x = y" by (simp add: switch_to_thread_def)
qed

lemma switch_to_thread_only_moves_current_thread:
  "cdl_cdt (switch_to_thread t s) = cdl_cdt s
     \<and> cdl_objects (switch_to_thread t s) = cdl_objects s
     \<and> cdl_current_domain (switch_to_thread t s) = cdl_current_domain s"
  by (simp add: switch_to_thread_def)

lemma switch_to_thread_None_is_a_choice:
  "switch_to_thread None s \<in> capdl_schedule s"
  by (auto simp: capdl_schedule_def)

lemma capdl_schedule_as_image:
  "capdl_schedule sched_state =
     ((\<lambda>t. switch_to_thread t sched_state) ` {None, Some (1::nat), Some 2})"
  unfolding capdl_schedule_def current_domain_sched_state active_in_domain_0
  by (auto simp: image_def split: option.splits)

lemma capdl_schedule_three_outcomes:
  "capdl_schedule sched_state =
     {switch_to_thread None sched_state, switch_to_thread (Some (1::nat)) sched_state,
      switch_to_thread (Some 2) sched_state}"
  unfolding capdl_schedule_as_image by (auto simp: image_def split: option.splits)

lemma choices_are_distinct:
  "switch_to_thread None sched_state
     \<noteq> switch_to_thread (Some (1::nat)) sched_state"
  "switch_to_thread (Some 1) sched_state
     \<noteq> switch_to_thread (Some 2) sched_state"
  by (auto dest: switch_to_thread_inj split: option.splits)


text \<open>
  与抽象规范那层的对照就写成"确定的一步是这一层多值步里的一个值"。
  这里把抽象层画成一个固定选 1 号的函数（真实的抽象规范按优先级选，见第 14 章），
  于是"抽象细化 capDL"这件事在模型里就是一句 @{verbatim "\<in>"}：
  @{text capdl_schedule} 是多值的，@{text abstract_schedule} 只取其中一个值。
\<close>

definition abstract_schedule :: "cdl_state \<Rightarrow> cdl_state" where
  "abstract_schedule s \<equiv> switch_to_thread (Some 1) s"

lemma abstract_is_one_of_capdl: "abstract_schedule sched_state \<in> capdl_schedule sched_state"
  unfolding abstract_schedule_def capdl_schedule_as_image
  by (auto simp: image_def split: option.splits)

lemma capdl_is_not_deterministic: "capdl_schedule sched_state \<noteq> {abstract_schedule sched_state}"
proof (rule notI)
  assume eq: "capdl_schedule sched_state = {abstract_schedule sched_state}"
  have a: "switch_to_thread None sched_state \<in> capdl_schedule sched_state"
    by (rule switch_to_thread_None_is_a_choice)
  have b: "switch_to_thread (Some 1) sched_state \<in> capdl_schedule sched_state"
    unfolding capdl_schedule_as_image by (auto simp: image_def)
  from eq have "switch_to_thread None sched_state = switch_to_thread (Some 1) sched_state"
    using a b by simp
  then show False by (auto dest: switch_to_thread_inj split: option.splits)
qed

subsection \<open>23.9 井形性：在 sys-init，不在 spec/capDL\<close>

text \<open>
  要特别说明的是：@{verbatim "l4v/spec/capDL/"} 里没有 @{verbatim "well_formed"}、
  也没有 @{verbatim "reachable"} 或 @{verbatim "island"} 这类整图谓词。该目录本身
  有 21 个理论，连架构子目录一共 27 个，@{verbatim "grep"} 下来一个都没有。
  真正给"一张图是否合法"下定义的是\emph{系统初始化器}那侧，即
  @{verbatim "l4v/sys-init/WellFormed_SI.thy"}：第 136 行的
  @{verbatim "well_formed_cap"}、第 223 行的 @{verbatim "well_formed_caps"}
  （它合取了 @{verbatim "well_formed_cdt"} 与
  @{verbatim "well_formed_cap_to_real_object"} 等一堆检查）、第 288 行的
  @{verbatim "well_formed_tcb"}、第 369 行的 @{verbatim "well_formed_irq_table"}。
  会话链写在 @{verbatim "l4v/sys-init/ROOT"} 里：第 14 行的
  @{verbatim "SysInitSpec"} 建在 @{verbatim "SepDSpec"} 之上，第 20 行的
  @{verbatim "SysInit"} 建在 @{verbatim "DSpecProofs"} 之上。
\<close>

definition cap_object :: "cdl_cap \<Rightarrow> obj_id option" where
  "cap_object c \<equiv> case c of
      EndpointCap p _ _      \<Rightarrow> Some p
    | NotificationCap p _ _  \<Rightarrow> Some p
    | ReplyCap p _           \<Rightarrow> Some p
    | TcbCap p               \<Rightarrow> Some p
    | CNodeCap p _ _ _       \<Rightarrow> Some p
    | FrameCap _ p _ _       \<Rightarrow> Some p
    | _                      \<Rightarrow> None"

definition frame_size :: "cdl_object \<Rightarrow> nat" where
  "frame_size obj \<equiv> case obj of Frame n \<Rightarrow> n | _ \<Rightarrow> 0"

text \<open>
  "能力要求的类型恰好等于目标对象的类型"这一条，在真实规范里写成
  @{verbatim "cap_type cap = Some (object_type cap_obj)"}（下一段给出出处）。
  模型的 @{text cap_type_matches} 是同一件事，只是把每种能力的要求写成
  @{text object_type} 上的等式；@{text FrameCap} 那一条额外比页大小，
  因为 @{verbatim "Intents_D.thy"} 第 98 行的 @{verbatim "FrameType"}
  把"这一页有多大"带在构造子参数里（注释原话：size in bits of desired page）。
\<close>

definition cap_type_matches :: "cdl_cap \<Rightarrow> cdl_object \<Rightarrow> bool" where
  "cap_type_matches c obj \<equiv> case c of
      EndpointCap _ _ _       \<Rightarrow> object_type obj = EndpointType
    | NotificationCap _ _ _   \<Rightarrow> object_type obj = NotificationType
    | ReplyCap _ _            \<Rightarrow> object_type obj = TcbType
    | TcbCap _                \<Rightarrow> object_type obj = TcbType
    | CNodeCap _ _ _ _        \<Rightarrow> object_type obj = CNodeType
    | FrameCap _ _ _ f        \<Rightarrow> object_type obj = FrameType f
    | _                       \<Rightarrow> True"

lemma cap_type_matches_endpoint_ok: "cap_type_matches (EndpointCap p b R) Endpoint"
  by (simp add: cap_type_matches_def object_type_def)

lemma cap_type_matches_endpoint_on_notification_fails:
  "\<not> cap_type_matches (EndpointCap p b R) Notification"
  by (simp add: cap_type_matches_def object_type_def)

lemma cap_type_matches_frame_checks_size:
  "cap_type_matches (FrameCap False p R f) (Frame f') = (f' = f)"
  by (simp add: cap_type_matches_def object_type_def)

lemma cap_type_matches_untyped_is_true: "cap_type_matches (UntypedCap False A B) obj"
  by (simp add: cap_type_matches_def)

lemma cap_object_untyped_is_none: "cap_object (UntypedCap False A B) = None"
  by (simp add: cap_object_def)

lemma cap_object_domain_is_none: "cap_object DomainCap = None"
  by (simp add: cap_object_def)

lemma frame_size_Frame: "frame_size (Frame n) = n"
  by (simp add: frame_size_def)

lemma frame_size_non_frame: "frame_size Endpoint = 0"
  by (simp add: frame_size_def)

definition edge_ok :: "cdl_state \<Rightarrow> cdl_cap \<Rightarrow> bool" where
  "edge_ok s cap \<equiv> case cap_object cap of None \<Rightarrow> True | Some q \<Rightarrow> get_object q s \<noteq> None"

definition no_dangling :: "cdl_state \<Rightarrow> bool" where
  "no_dangling s \<equiv> \<forall>ref cap. opt_cap ref s = Some cap \<longrightarrow> edge_ok s cap"

definition types_ok :: "cdl_state \<Rightarrow> bool" where
  "types_ok s \<equiv> \<forall>ref cap q obj'. opt_cap ref s = Some cap \<longrightarrow> cap_object cap = Some q
      \<longrightarrow> get_object q s = Some obj' \<longrightarrow> cap_type_matches cap obj'"

lemma empty_is_no_dangling: "no_dangling empty_state"
  by (auto simp: no_dangling_def edge_ok_def opt_cap_def get_object_def empty_state_def
                 cap_object_def split: option.splits)

lemma empty_types_ok: "types_ok empty_state"
  by (auto simp: types_ok_def opt_cap_def get_object_def empty_state_def split: option.splits)

text \<open>
  两个反例共用同一个 @{verbatim "sample_cnode"}：0 号槽里放一条端点能力，
  指向参数给定的那个对象。两张图的区别只在于\emph{被指的那个对象在不在堆里}、
  以及\emph{它的类型对不对}。
\<close>

definition sample_cnode :: "obj_id \<Rightarrow> cdl_cnode" where
  "sample_cnode target \<equiv>
     \<lparr> cdl_cnode_caps = (\<lambda>sl. if sl = 0 then Some (EndpointCap target 0 {AllowRead}) else None),
        cdl_cnode_size_bits = 2 \<rparr>"

lemma sample_cnode_slot0:
  "object_slots (CNode (sample_cnode target)) 0 = Some (EndpointCap target 0 {AllowRead})"
  by (simp add: sample_cnode_def object_slots_def)

lemma sample_cnode_other_slot:
  "sl \<noteq> 0 \<Longrightarrow> object_slots (CNode (sample_cnode target)) sl = None"
  by (simp add: sample_cnode_def object_slots_def)

definition dangling_state :: cdl_state where
  "dangling_state \<equiv> empty_state\<lparr>cdl_objects :=
     (\<lambda>p. if p = 5 then Some (CNode (sample_cnode 9)) else None)\<rparr>"

lemma opt_cap_dangling_edge:
  "opt_cap (5, 0) dangling_state = Some (EndpointCap 9 0 {AllowRead})"
  by (simp add: opt_cap_def get_object_def dangling_state_def empty_state_def sample_cnode_def
                object_slots_def)

lemma get_object_dangling_target: "get_object 9 dangling_state = None"
  by (simp add: get_object_def dangling_state_def empty_state_def)

lemma cap_object_dangling_edge: "cap_object (EndpointCap 9 0 R) = Some 9"
  by (simp add: cap_object_def)

lemma dangling_is_not_no_dangling: "\<not> no_dangling dangling_state"
proof (rule notI)
  assume wf: "no_dangling dangling_state"
  then have W: "\<And>ref cap. opt_cap ref dangling_state = Some cap \<Longrightarrow> edge_ok dangling_state cap"
    by (auto simp: no_dangling_def)
  then have "edge_ok dangling_state (EndpointCap 9 0 {AllowRead})"
    using opt_cap_dangling_edge by blast
  then show False
    by (simp add: edge_ok_def cap_object_dangling_edge get_object_dangling_target get_object_def
                  dangling_state_def empty_state_def split: option.splits)
qed

definition mismatched_state :: cdl_state where
  "mismatched_state \<equiv> empty_state\<lparr>cdl_objects :=
     (\<lambda>p. if p = 5 then Some (CNode (sample_cnode 6))
           else if p = 6 then Some Notification else None)\<rparr>"

lemma opt_cap_mismatched_edge:
  "opt_cap (5, 0) mismatched_state = Some (EndpointCap 6 0 {AllowRead})"
  by (simp add: opt_cap_def get_object_def mismatched_state_def empty_state_def sample_cnode_def
                object_slots_def)

lemma get_object_mismatched_target: "get_object 6 mismatched_state = Some Notification"
  by (simp add: get_object_def mismatched_state_def empty_state_def)

lemma cap_object_mismatched_edge: "cap_object (EndpointCap 6 0 R) = Some 6"
  by (simp add: cap_object_def)

lemma mismatched_not_types_ok: "\<not> types_ok mismatched_state"
proof (rule notI)
  assume wf: "types_ok mismatched_state"
  then have W: "\<And>ref cap q obj'. \<lbrakk>opt_cap ref mismatched_state = Some cap;
        cap_object cap = Some q; get_object q mismatched_state = Some obj'\<rbrakk>
        \<Longrightarrow> cap_type_matches cap obj'"
    by (auto simp: types_ok_def)
  then have "cap_type_matches (EndpointCap 6 0 {AllowRead}) Notification"
    using opt_cap_mismatched_edge cap_object_mismatched_edge get_object_mismatched_target by blast
  then show False by (simp add: cap_type_matches_def object_type_def)
qed

lemma mismatched_is_no_dangling: "no_dangling mismatched_state"
  by (auto simp: no_dangling_def edge_ok_def opt_cap_def get_object_def mismatched_state_def
                 empty_state_def sample_cnode_def object_slots_def cap_object_def
                 split: option.splits if_splits)

text \<open>
  最后一条是本章最要紧的一个区分：@{thm mismatched_is_no_dangling} 说明
  "指向的对象存在"与"指向的对象类型对"是两件事——
  只查前者的检查会放过把端点能力指到通知对象上的那张图。
  真实 @{verbatim "WellFormed_SI.thy"} 里这两件事\emph{本来就是两条定义}：
  第 207 行的 @{verbatim "well_formed_cap_to_real_object"} 只要求
  @{verbatim "cap_has_object cap \<longrightarrow> real_object_at (cap_object cap) spec"}，
  即"指到了东西"；第 213 行的 @{verbatim "well_formed_cap_types_match"} 才要求
  @{verbatim "cap_type cap = Some (object_type cap_obj)"} 这种等式，
  两条都被第 223 行的 @{verbatim "well_formed_caps"} 合取起来。
  也就是说：真实规范里"存在"与"类型对"是\emph{两个各自命名的判据}，
  与上面 @{verbatim "no_dangling"}/@{verbatim "types_ok"} 的分工一一对应。
\<close>

subsection \<open>23.10 syscall 的骨架：五段 glue\<close>

text \<open>
  @{verbatim "Syscall_D.thy"} 第 34 行的 @{verbatim "syscall"} 不是内核代码的翻译，
  而是一个固定的五参数模板：能力解码、解码错误处理、参数解码、
  参数错误处理、执行。第 101 行的 @{verbatim "handle_invocation"}
  再把 @{verbatim "perform_invocation"}（第 50 行，一个对
  @{verbatim "cdl_invocation"} 16 个构造子的 @{verbatim "fun"} 分发）接上。
  模型用一个最小 @{verbatim "cres"} 复刻这个模板。
\<close>

datatype ('e, 'a) cres = COk 'a | CErr 'e

definition syscall ::
  "('e, 'a) cres \<Rightarrow> ('e \<Rightarrow> ('e, 'd) cres) \<Rightarrow> ('a \<Rightarrow> ('e, 'c) cres)
     \<Rightarrow> ('e \<Rightarrow> ('e, 'd) cres) \<Rightarrow> ('c \<Rightarrow> ('e, 'd) cres) \<Rightarrow> ('e, 'd) cres" where
  "syscall dec dech arg argch perf \<equiv>
     case dec of
       CErr e \<Rightarrow> dech e
     | COk a \<Rightarrow> (case arg a of
           CErr e \<Rightarrow> argch e
         | COk c \<Rightarrow> perf c)"

datatype cdl_invocation =
    InvokeUntyped obj_id
  | InvokeEndpoint obj_id
  | InvokeNotification obj_id
  | InvokeReply obj_id
  | InvokeTcb obj_id
  | InvokeCNode obj_id
  | InvokeDomain obj_id
  | InvokeIrqControl
  | InvokePageTable obj_id

datatype cdl_effect =
    EffUntyped obj_id
  | EffEndpoint obj_id bool bool
  | EffNotification obj_id
  | EffReply obj_id
  | EffTcb obj_id
  | EffCNode obj_id
  | EffDomain obj_id
  | EffIrqControl
  | EffPageTable obj_id

fun perform_invocation :: "bool \<Rightarrow> bool \<Rightarrow> cdl_invocation \<Rightarrow> cdl_effect" where
  "perform_invocation ic cb (InvokeUntyped p) = EffUntyped p"
| "perform_invocation ic cb (InvokeEndpoint p) = EffEndpoint p ic cb"
| "perform_invocation ic cb (InvokeNotification p) = EffNotification p"
| "perform_invocation ic cb (InvokeReply p) = EffReply p"
| "perform_invocation ic cb (InvokeTcb p) = EffTcb p"
| "perform_invocation ic cb (InvokeCNode p) = EffCNode p"
| "perform_invocation ic cb (InvokeDomain p) = EffDomain p"
| "perform_invocation ic cb InvokeIrqControl = EffIrqControl"
| "perform_invocation ic cb (InvokePageTable p) = EffPageTable p"

lemma syscall_decode_error_shortcuts:
  "syscall (CErr e) dech arg argch perf = dech e"
  by (simp add: syscall_def)

lemma syscall_arg_error_shortcuts:
  "syscall (COk a) dech (\<lambda>_. CErr e) argch perf = argch e"
  by (simp add: syscall_def)

lemma syscall_ok_runs_body:
  "syscall (COk a) dech (\<lambda>x. COk (f x)) argch perf = perf (f a)"
  by (simp add: syscall_def)

lemma syscall_glue_is_five_pieces:
  "syscall dec dech arg argch perf =
     (case dec of CErr e \<Rightarrow> dech e
                | COk a \<Rightarrow> (case arg a of CErr e \<Rightarrow> argch e | COk c \<Rightarrow> perf c))"
  by (cases dec) (auto simp: syscall_def split: cres.splits)

lemma only_endpoint_uses_the_two_flags:
  "perform_invocation ic cb (InvokeTcb p) = perform_invocation ic' cb' (InvokeTcb p)"
  by simp

lemma endpoint_uses_the_two_flags:
  "perform_invocation True False (InvokeEndpoint p) = EffEndpoint p True False"
  by simp

definition handle_invocation :: "bool \<Rightarrow> bool \<Rightarrow> cdl_invocation \<Rightarrow> cdl_effect" where
  "handle_invocation ic cb iv \<equiv> perform_invocation ic cb iv"

lemma handle_invocation_is_dispatch:
  "handle_invocation ic cb iv = perform_invocation ic cb iv"
  by (simp add: handle_invocation_def)

lemma handle_invocation_endpoint:
  "handle_invocation ic cb (InvokeEndpoint p) = EffEndpoint p ic cb"
  by (simp add: handle_invocation_def)

lemma handle_invocation_preserves_args:
  "handle_invocation ic cb (InvokeUntyped p) = EffUntyped p"
  by (simp add: handle_invocation_def)

ML \<open>
  writeln (@{make_string} @{thm update_cap_rights_notification_drops_grant});
  writeln (@{make_string} @{thm update_cap_rights_reply_forces_write});
  writeln (@{make_string} @{thm object_slots_update_slots});
  writeln (@{make_string} @{thm set_cap_cnode_reads_back});
  writeln (@{make_string} @{thm chain_delete_rehangs_to_grandparent});
  writeln (@{make_string} @{thm all_active_is_three});
  writeln (@{make_string} @{thm capdl_schedule_three_outcomes});
  writeln (@{make_string} @{thm abstract_is_one_of_capdl});
  writeln (@{make_string} @{thm capdl_is_not_deterministic});
  writeln (@{make_string} @{thm mismatched_is_no_dangling})
\<close>

ML \<open>writeln "==== 23 结束 ===="\<close>

end
