# 23 · capDL：用一张能力分布图描述整个系统

对应示例：`../examples/S23_capdl.thy`（10 节，90 条实测结论，编译零警告）

前 22 章都在证"内核的**每一步**都对"：抽象规范、可执行规范、内核不变式、
完整性、非干扰。用户拿到这些定理之后要回答的却是另一个问题：

**"我这一套具体的配置里，A 分区到底摸不摸得到 B 分区的端点？"**

这个问题跟"内核每一步"无关，它只跟**一张图**有关——系统里有哪些对象、
每个槽里放着哪条能力。capDL（capability distribution language）就是把这张图
写成 Isabelle 数据类型的那一层。本章按真实规范的样子把这张图造出来：
类型层（23.2–23.4）、CDT（23.5–23.6）、意图（23.7）、调度（23.8）、
井形性（23.9）、syscall 骨架（23.10），
每一节的结论都是机器算出来的，不是文字推的。

## 23.1 先纠正三件常见的事，再把名字与权利摆好

规范目录是 `l4v/spec/capDL/`：连架构子目录一共 27 个理论文件
（顶层 21 个，`AARCH64/`、`ARM/`、`ARM_HYP/` 各 2 个）。
`README.md` 第 12 行起把这一层的口径写得很死：

<!-- 源码块：l4v/spec/capDL/README.md:12-18 -->
```text
This directory contains the Isabelle sources of the seL4 behaviour
specification on the capDL abstraction level. The key features of this
abstraction level are that it models the complete protection state of the
kernel in terms of capabilities, and models, as far as possible, only the
protection state of the kernel (no memory or other state). This means, the
capDL specification contains a significantly higher degree of nondeterminism
compared to the other seL4 specs.
```

从这段话里能读出三件常被讲错的事：

1. **它只描述保护状态**，不描述内存内容、不描述时间。第 21 章的完整性、
   第 22 章的非干扰是**对内核**的定理；capDL 是**对一张具体图**的表述层。
2. **非确定是故意的**（"a significantly higher degree of nondeterminism"），
   不是模型没做完。23.8 会看到调度在这一层就是一个集合。
3. 同文件第 24 行说抽象规范与 capDL 之间有精化证明，在 `proof/drefine/`；
   第 31 行说这一层的顶层理论是 `Syscall_D`，顶层函数是 `call_kernel`。

第二件要纠正的：**类型层真正的定义在 `Types_D.thy`，不是 `Structures_D.thy`。**
`Structures_D.thy` 全文 18 行，内容只有一个 import 加一段 `arch_requalify_consts`：

<!-- 源码块：l4v/spec/capDL/Structures_D.thy:7-13 -->
```text
theory Structures_D
  imports
    Arch_Structs_D
begin

arch_requalify_consts (D)
  slot_bits_cdl
```

对象、能力、状态的全部形状都在 `Types_D.thy`：能力是第 113 行的
`datatype cdl_cap`（NullCap 加 28 个带参构造子，共 29 个），
内核对象是第 245 行的 `datatype cdl_object`，
整个系统是第 301 行的 `record cdl_state`。本章的模型照抄这三个骨架的名字与元数。

第三件：架构常量也不在 `Types_D.thy`。`Setup_D.thy` 第 15 行：

<!-- 源码块：l4v/spec/capDL/Setup_D.thy:15-15 -->
```text
datatype cdl_arch = AARCH32 | AARCH64 | RISCV32 | RISCV64 | IA32 | X64
```

模型直接把这六个构造子抄过来（`S23_capdl.thy` 第 42 行）。

### 名字、位置、权利

真实规范里对象名是机器字，注释还特意说明这个名字**可以**就是对象的内存地址：

<!-- 源码块：l4v/spec/capDL/Types_D.thy:49-55 -->
```text
(*
 * How objects are named within the kernel.
 *
 * Objects are named by machine words.
 * This name may correspond to the memory address of the object.
 *)
type_synonym cdl_object_id = machine_word
```

`cdl_cap_ref`（`l4v/spec/capDL/Types_D.thy:79`）是"对象号 × 槽号"这个二元组——**能力的位置**。
同一文件第 192--195 行连着给了四条 `translations`：`cdl_cap_map`、`cdl_cap_ref`（两条）
与 `cdl_cdt` 各自的显式写法（`nat`、`machine_word`、二元组、函数类型）。
它们只改**打印**，不改类型本身——和第 8 章那段 `translations` 是同一回事。
槽表和对象堆也各是一个函数类型别名：`cdl_cap_map`（`l4v/spec/capDL/Types_D.thy:177`）
是"槽号 → 能力"，`cdl_heap`（`l4v/spec/capDL/Types_D.thy:258`）是"对象号 → 对象"。
模型里对应 `cap_ref`（`S23_capdl.thy` 第 40 行）。

权利只有四种，而且 capDL 不自己定义它——`Intents_D.thy` 第 39 行：

<!-- 源码块：l4v/spec/capDL/Intents_D.thy:39-39 -->
```text
type_synonym cdl_right = rights
```

它复用抽象规范那份 `rights`。模型把四个构造子写全
（`AllowRead`、`AllowWrite`、`AllowGrant`、`AllowGrantReply`），
并且证出"全集确实是全集"这条看似废话、后面每步都要用的引理：

```text
theorem all_cdl_rights_UNIV: all_cdl_rights = UNIV
```

## 23.2 能力：只有四类能力带权利字段

真实 `cap_rights`（`Types_D.thy` 第 446 行）的形状是
"Endpoint/Notification/Reply/CNode 四类取自己的字段，其余一律 `all_cdl_rights`"。
模型的三条实测结论正是这个"其余"的代价：

```text
theorem cap_rights_endpoint: cap_rights (EndpointCap ?p ?b ?R) = ?R

theorem
  cap_rights_cnode_is_all:
    cap_rights (CNodeCap ?p ?g ?gs ?sz) = all_cdl_rights

theorem cap_rights_nullcap_is_all: cap_rights NullCap = all_cdl_rights
```

**空能力的权利是全集**。听起来别扭，但正因为"不是那四类就取全集"，
`update_cap_rights`（第 455 行）才能靠"不是那四类就原样返回"来保证
削权不会作用到别的能力上。于是削权的两条真实行为在模型里是算出来的：

```text
theorem
  update_cap_rights_notification_drops_grant:
    cap_rights (update_cap_rights ?r (NotificationCap ?p ?b ?R)) =
    ?r - {AllowGrant, AllowGrantReply}

theorem
  update_cap_rights_reply_forces_write:
    AllowWrite \<in> cap_rights (update_cap_rights ?r (ReplyCap ?p ?R))

theorem
  update_cap_rights_leaves_cnode:
    update_cap_rights ?r (CNodeCap ?p ?g ?gs ?sz) = CNodeCap ?p ?g ?gs ?sz
```

后两条正好是第 21 章那两件事在 capDL 层的对应物：
通知能力拿不到 `Grant`/`GrantReply`，reply 能力被硬塞 `Write`。
这一节还照抄了真实 `cdl_cap` 的两个细节：`UntypedCap` 带**两个**对象集合
（可用范围与原始范围），而 `DomainCap`、`RestartCap`、`RunningCap`、
`IrqControlCap` 是**零参**构造子——它们不指向任何对象，
因此 23.9 的"指向的对象存在"这类判据对它们必须直接返回真。

## 23.3 对象：十种，其中只有五种有槽

对象那一层的 `cdl_object` 定义在 `Types_D.thy` 第 245 行，共十个构造子。
关键在 `has_slots`（第 528 行）/`object_slots`（第 508 行）/`update_slots`
（第 518 行）这一组配合上：

```text
theorem
  has_slots_five:
    has_slots (Tcb ?t) \<and>
    has_slots (CNode ?c) \<and>
    has_slots (AsidPool ?a) \<and>
    has_slots (PageTable ?l ?m) \<and> has_slots (IRQNode ?i)

theorem
  has_slots_others:
    \<not> has_slots Endpoint \<and>
    \<not> has_slots Notification \<and>
    \<not> has_slots Untyped \<and> \<not> has_slots (Frame ?n) \<and> \<not> has_slots VCPU

theorem
  update_slots_no_slots: \<not> has_slots ?obj \<Longrightarrow> update_slots ?m ?obj = ?obj

theorem
  object_slots_update_slots:
    object_slots (update_slots ?m ?obj) =
    (if has_slots ?obj then ?m else (\<lambda>x. None))
```

端点、通知、Untyped、Frame、VCPU **没有槽**，所以对它们"写一个能力"是无操作。
真实 `KHeap_D.thy` 第 81 行的 `set_cap` 因此在写之前先
`assert (has_slots obj)`；模型里对应 `set_cap_no_slots`。

`object_type`（第 313 行）与 `cdl_object_type`（`Intents_D.thy` 第 89 行）
里，页表类型带层号、帧类型带大小：

<!-- 源码块：l4v/spec/capDL/Intents_D.thy:97-98 -->
```text
  | PageTableType (cdl_pt_type : cdl_pt_type)
  | FrameType nat (* size in bits of desired page *)
```

模型的 `object_type_PageTable_carries_level` 就是在测这条：

```text
theorem
  object_type_PageTable_carries_level:
    object_type (PageTable ?l ?m) = PageTableType ?l
```

## 23.4 状态：一张堆、一棵 CDT、一个当前线程

真实的 `record cdl_state`（`Types_D.thy` 第 301 行）有十个字段：

<!-- 源码块：l4v/spec/capDL/Types_D.thy:301-310 -->
```text
record cdl_state =
  cdl_arch           :: cdl_arch
  cdl_objects        :: cdl_heap
  cdl_cdt            :: cdl_cdt
  cdl_current_thread :: "cdl_object_id option"
  cdl_irq_node       :: "cdl_irq \<Rightarrow> cdl_object_id"
  cdl_asid_table     :: cdl_cap_map
  cdl_current_domain :: domain
  cdl_dom_schedule   :: "(domain \<times> domain_duration) list"
  cdl_dom_start      :: nat
```

模型取其中六个（去掉 ASID 表与那两个调度表字段），名字全部保持一致。
读写对象是纯图操作，不动其他字段——这三条是为 23.8 的
"换个当前线程不碰图"做准备的：

```text
theorem
  get_object_set_object_same:
    get_object ?p (set_object ?p ?obj ?s) = Some ?obj

theorem
  get_object_set_object_other:
    ?p \<noteq> ?q \<Longrightarrow> get_object ?q (set_object ?p ?obj ?s) = get_object ?q ?s

theorem
  set_object_preserves_cdt: cdl_cdt (set_object ?p ?obj ?s) = cdl_cdt ?s
```

读槽与写槽把"对象不存在""对象没有槽"两种失败都编进 `option` 里，
所以签名本身就是一篇文档（模型里 `set_cap` 的返回类型是 `cdl_state option`，
真实的 `set_cap` 跑在 `k_monad` 里，靠 `assert` 失败）：

```text
consts
  opt_cap :: "nat \<times> nat \<Rightarrow> cdl_state \<Rightarrow> cdl_cap option"

theorem
  opt_cap_endpoint_is_none:
    get_object ?p ?s = Some Endpoint \<Longrightarrow> opt_cap (?p, ?sl) ?s = None

theorem
  set_cap_no_slots:
    get_object ?p ?s = Some Endpoint \<Longrightarrow> set_cap (?p, ?sl) ?cap ?s = None

theorem set_cap_cnode_reads_back:
 get_object ?p ?s = Some (CNode ?cn) \<Longrightarrow>
 opt_cap (?p, ?sl) (the (set_cap (?p, ?sl) ?cap ?s)) = Some ?cap
```

最后一条读回是本章第一个"给前提就能算"的例子：只要那个对象确实是个 CNode，
写进 `sl` 槽的能力就一定能读回来。

## 23.5 CDT：撤销的根据就是父亲指针

`Types_D.thy` 第 179–188 行的注释把 CDT 的用途说透了：

<!-- 源码块：l4v/spec/capDL/Types_D.thy:179-184 -->
```text
(* The cap derivation tree (CDT).

   This tree records how certain caps are derived from others. This
   information is important because it affects how caps are revoked; if an
   entity revokes a particular cap, all of the cap's children (as
   recorded in the CDT) are also revoked.
```

类型就是第 189 行那个父亲指针函数：`cdl_cdt = cdl_cap_ref \<Rightarrow> cdl_cap_ref option`。
真实读写在 `KHeap_D.thy`：第 100 行 `opt_parent`、第 107 行 `set_parent`、
第 115 行 `remove_parent`、第 124 行 `swap_parents`；
`has_children` 与 `ensure_no_children` 在 `CSpace_D.thy` 的第 15、18 行。

模型的四条核心结论：

```text
theorem
  set_parent_requires_free_child:
    cdl_cdt ?s ?c \<noteq> None \<Longrightarrow> set_parent ?c ?p ?s = None

theorem remove_parent_clears_itself: cdl_cdt (remove_parent ?p ?s) ?p = None

theorem
  remove_parent_rehangs_children:
    \<lbrakk>cdl_cdt ?s ?x = Some ?p; ?x \<noteq> ?p\<rbrakk>
    \<Longrightarrow> cdl_cdt (remove_parent ?p ?s) ?x = cdl_cdt ?s ?p

theorem
  ensure_no_children_blocks:
    cdl_cdt ?s ?x = Some ?p \<Longrightarrow> ensure_no_children ?p ?s = None
```

第二条要说清口径：`remove_parent` 只把**这个节点的父亲指针**抹掉，
孩子另挂——这就是"撤销一条能力会连带撤销它的孩子"在图上的实现方式。
写成一条三代链上的可算等式：

```text
theorem chain_parent_of_1_1: opt_parent (1, 1) chain_state = Some (0, 0)

theorem chain_parent_of_2_1: opt_parent (2, 1) chain_state = Some (1, 1)

theorem chain_has_children_mid: has_children (1, 1) chain_state

theorem chain_leaf_has_no_children: \<not> has_children (2, 1) chain_state

theorem
  chain_delete_rehangs_to_grandparent:
    opt_parent (2, 1) (remove_parent (1, 1) chain_state) = Some (0, 0)
```

`(2,1)` 原本的父亲是 `(1,1)`；删掉 `(1,1)` 之后它指向的是祖父 `(0,0)`。
**第 6 章"撤销会不会漏"那个问题，在 capDL 层的答案就是这张树加这两条规则。**

## 23.6 三种插法：orphan、sibling、child

`CSpace_D.thy` 给了三条只差在 CDT 上的插入：第 32 行 `insert_cap_orphan`
（注释原话 "The cap will have no parent"）、第 58 行 `insert_cap_sibling`
（跟着源能力的父亲走）、第 72 行 `insert_cap_child`（认源能力当父亲）。
三条签名都是先能力后引用：

<!-- 源码块：l4v/spec/capDL/CSpace_D.thy:32-32 -->
```text
definition insert_cap_orphan :: "cdl_cap \<Rightarrow> cdl_cap_ref \<Rightarrow> unit k_monad" where
```

三条都先 `assert (old_cap = NullCap)`——**目标槽必须是空的**。
模型把这套 monad 链换成 `option`，于是每条链都要一个 `\<bind>`：

```text
consts
  option_bind :: "'a option \<Rightarrow> ('a \<Rightarrow> 'b option) \<Rightarrow> 'b option"

theorem option_bind_Some: Some ?x \<bind> ?f = ?f ?x

theorem option_bind_None: None \<bind> ?f = None
```

有了它，"插一条孤儿能力"的效果是一句可算的合取：

```text
theorem
  insert_cap_orphan_then_read:
    \<lbrakk>opt_cap ?dest ?s = Some NullCap;
     get_object (fst ?dest) ?s = Some (CNode ?cn); cdl_cdt ?s ?dest = None\<rbrakk>
    \<Longrightarrow> opt_cap ?dest (the (insert_cap_orphan ?dest ?cap ?s)) = Some ?cap \<and>
       opt_parent ?dest (the (insert_cap_orphan ?dest ?cap ?s)) = None
```

前提里那三条不是摆设：槽得是空的、目标得真的有槽、这个位置在 CDT 上得还没有父亲。

## 23.7 意图：capDL 连"打算拿来干什么"都写进图里

`Intents_D.thy` 给每种对象都配了一个意图类型：`cdl_cnode_intent`
（第 101 行，九个构造子）、`cdl_tcb_intent`（第 125 行）、
`cdl_untyped_intent`（第 159 行），最后由第 227 行的 `cdl_intent` 收成一个大类型；
第 244–247 行的 `cdl_full_intent` 把 `cdl_intent_op`、`cdl_intent_cap`、
`cdl_intent_extras` 打包。投影那一整排从 `get_cnode_intent`
（`Decode_D.thy` 第 16 行）开始。

意图为什么重要：第 10 章的解码要按**打算做的操作**来检查权利，
而这条信息在纯内核状态里是**没有地方放的**——它就是"能力"本身。
capDL 把它放进对象里，于是"这张图会不会被用来做 X"变成一个图上问题。
模型的四条投影结论：

```text
theorem get_cnode_intent_ok: get_cnode_intent (CNodeIntent ?ci) = Some ?ci

theorem get_cnode_intent_other: get_cnode_intent (TcbIntent ?ti) = None

theorem intents_are_disjoint: CNodeIntent ?ci \<noteq> TcbIntent ?ti

theorem
  get_cnode_intent_of_revoke:
    get_cnode_intent (CNodeIntent (CNodeRevokeIntent ?a ?b)) =
    Some (CNodeRevokeIntent ?a ?b)
```

`intents_are_disjoint` 这条看着 trivial，但它正是"一个 TCB 的意图不可能被
误当成 CNode 的意图"的机器证据——`get_tcb_intent` 对 `CNodeIntent` 返回
`None`（模型里同样有一条），两个投影互斥，解码才敢只按对象类型分发。

## 23.8 调度在这一层是完全非确定的

`Schedule_D.thy` 第 35 行只有一句注释，值得原文照抄：

<!-- 源码块：l4v/spec/capDL/Schedule_D.thy:35-35 -->
```text
(* Scheduling is fully nondeterministic at this level. *)
```

同文件里：第 12 行 `all_active_tcbs`、第 18 行 `active_tcbs_in_domain`、
第 26 行 `switch_to_thread`、第 29 行 `change_current_domain`（里面直接
`select UNIV` 挑一个域）、第 36 行 `schedule` 是两个分支的 `\<sqinter>`：
一支"换域、在活跃线程里 `select`、切过去"，另一支"换域、切到 `None`"。

"哪些线程算活跃"的判据只有一句话：**5 号槽里是 `RunningCap` 或 `RestartCap`**。
这个槽号 `tcb_pending_op_slot` 在 `Types_D.thy` 第 347 行是明写的：

<!-- 源码块：l4v/spec/capDL/Types_D.thy:347-347 -->
```text
definition "tcb_pending_op_slot = (5 :: cdl_cnode_index)"
```

模型造了四个对象（域 0 的两个活跃线程、域 1 的一个、外加一个端点），
然后**把集合算出来**：

```text
theorem pending_op_slot_is_5: tcb_pending_op_slot = 5

theorem active_in_domain_0: active_tcbs_in_domain 0 sched_state = {1, 2}

theorem active_in_domain_1: active_tcbs_in_domain 1 sched_state = {3}

theorem endpoint_not_active: 4 \<notin> active_tcbs_in_domain ?d sched_state

theorem all_active_is_three: all_active_tcbs sched_state = {1, 2, 3}
```

域 0 有两个候选、域 1 有一个、端点永远不活跃、全体活跃是三个。
`capdl_schedule` 因此是一个**返回集合**的函数，其值恰好三个元素
（两条活跃线程加那支"切到 `None`"）：

```text
theorem
  capdl_schedule_three_outcomes:
    capdl_schedule sched_state =
    {switch_to_thread None sched_state, switch_to_thread (Some 1) sched_state,
     switch_to_thread (Some 2) sched_state}
```

这三个元素两两不同（`choices_are_distinct`），且"换线程"这一步真的只动
`cdl_current_thread` 一个字段——图、CDT、域都不变：

```text
theorem
  switch_to_thread_only_moves_current_thread:
    cdl_cdt (switch_to_thread ?t ?s) = cdl_cdt ?s \<and>
    cdl_objects (switch_to_thread ?t ?s) = cdl_objects ?s \<and>
    cdl_current_domain (switch_to_thread ?t ?s) = cdl_current_domain ?s
```

最后这条把 capDL 与抽象规范的关系摆正了：抽象层按优先级选线程（第 14 章），
是**确定的一步**；这一步是 capDL 那**三个值里的一个**：

```text
theorem
  abstract_is_one_of_capdl:
    abstract_schedule sched_state \<in> capdl_schedule sched_state

theorem
  capdl_is_not_deterministic:
    capdl_schedule sched_state \<noteq> {abstract_schedule sched_state}
```

**注意精化箭头用的符号是 `\<in>` 不是 `=`**。"capDL 比抽象规范更非确定"
这句话在模型里就是这两条合在一起：抽象步属于 capDL 的值集，
而 capDL 的值集不止 singleton。

## 23.9 井形性：在 sys-init，不在 spec/capDL

这一节要专门破除一个流传很广的说法——"capDL 里有个 `well_formed`，
可以判一张图是否合法，还能在图上做可达性分析"。事实是：

* `l4v/spec/capDL/` 目录里 **grep 不到** `well_formed`、`reachable`、`island`
  中的任何一个（顶层 21 个理论、连架构子目录 27 个文件，一个都没有）。
* 真正给"一张图是否合法"下定义的是**系统初始化器**那侧，
  即 `l4v/sys-init/WellFormed_SI.thy`（全文 1939 行）：
  第 136 行 `well_formed_cap`、第 187 行 `well_formed_cdt`、
  第 207 行 `well_formed_cap_to_real_object`、第 213 行
  `well_formed_cap_types_match`、第 223 行 `well_formed_caps`、
  第 288 行 `well_formed_tcb`、第 369 行 `well_formed_irq_table`，
  顶层 `well_formed` 在第 376 行。
* 会话链：`SysInitSpec` 建在 `SepDSpec` 之上（`l4v/sys-init/ROOT` 第 14 行），
  `SysInit` 建在 `DSpecProofs` 之上（同文件第 20 行）。

也就是说，**"井形性"根本不是 capDL 语义的一部分，而是 sys-init 证明的前提**：
初始化器只保证"从合法输入图出发能得到正确结果"，
而"合法"这个谓词定义在它自己的目录里。

模型把最常用的两条判据拆开来写，正好对应真实那份里两条**各自命名**的判据：
`no_dangling` 对应 `well_formed_cap_to_real_object`（第 207 行，只说"指到了东西"），
`types_ok` 对应 `well_formed_cap_types_match`（第 213 行）：

<!-- 源码块：l4v/sys-init/WellFormed_SI.thy:215-218 -->
```text
  "well_formed_cap_types_match spec cap \<equiv>
    (cap_has_object cap \<longrightarrow>
    (\<exists>cap_obj. cdl_objects spec (cap_object cap) = Some cap_obj \<and>
               cap_type cap = Some (object_type cap_obj))) \<and>
```

模型的 `cap_type_matches` 是同一件事，只是把每种能力的要求写成
`object_type` 上的等式；`FrameCap` 那一条额外比页大小（23.3 的
`FrameType nat` 就是要比大小的地方）：

```text
theorem
  cap_type_matches_endpoint_ok:
    cap_type_matches (EndpointCap ?p ?b ?R) Endpoint

theorem
  cap_type_matches_endpoint_on_notification_fails:
    \<not> cap_type_matches (EndpointCap ?p ?b ?R) Notification

theorem
  cap_type_matches_frame_checks_size:
    cap_type_matches (FrameCap False ?p ?R ?f) (Frame ?f') = (?f' = ?f)
```

然后是两个反例，共用同一个 `sample_cnode`（0 号槽放一条端点能力，
指向参数给定的对象），区别只在**被指的那个对象在不在堆里、类型对不对**：

```text
theorem
  sample_cnode_slot0:
    object_slots (CNode (sample_cnode ?target)) 0 =
    Some (EndpointCap ?target 0 {AllowRead})

theorem
  opt_cap_dangling_edge:
    opt_cap (5, 0) dangling_state = Some (EndpointCap 9 0 {AllowRead})

theorem get_object_dangling_target: get_object 9 dangling_state = None

theorem dangling_is_not_no_dangling: \<not> no_dangling dangling_state

theorem
  opt_cap_mismatched_edge:
    opt_cap (5, 0) mismatched_state = Some (EndpointCap 6 0 {AllowRead})

theorem
  get_object_mismatched_target:
    get_object 6 mismatched_state = Some Notification

theorem mismatched_not_types_ok: \<not> types_ok mismatched_state

theorem mismatched_is_no_dangling: no_dangling mismatched_state
```

**最后一条是本节最要紧的区分。** `mismatched_is_no_dangling` 说这张图
"每条边都指到了存在的对象"，`mismatched_not_types_ok` 说它同时
"把一条端点能力指到了通知对象上"。两张判据如果合成一条，
这类图就漏了。真实 `well_formed_caps`（第 223 行）正是把
`well_formed_cap_to_real_object` 与 `well_formed_cap_types_match`
**分别**合取进来的，与此一一对应。

## 23.10 syscall 的骨架：五段 glue

`Syscall_D.thy` 是这一层的顶层理论（README 第 31 行说的）。
它第 34 行的 `syscall` 不是内核代码的翻译，而是一个固定的**五参数模板**——
能力解码、解码错误处理、参数解码、参数错误处理、执行：

<!-- 源码块：l4v/spec/capDL/Syscall_D.thy:34-48 -->
```text
definition syscall ::
  "('a fault_monad) \<Rightarrow> unit k_monad \<Rightarrow> ('a \<Rightarrow> 'b except_monad) \<Rightarrow> unit k_monad \<Rightarrow>
   ('b \<Rightarrow> unit preempt_monad) \<Rightarrow> unit preempt_monad"
  where
  "syscall cap_decoder_fn decode_error_handler_fn arg_decode_fn arg_error_handler_fn
           perform_syscall_fn \<equiv>
     cap_decoder_fn
       <handle>
         (\<lambda>_. liftE $ decode_error_handler_fn)
       <else>
         (\<lambda>a. (arg_decode_fn a
                <handle>
                  (\<lambda>_. liftE $ arg_error_handler_fn)
                <else>
                  perform_syscall_fn))"
```

第 101 行的 `handle_invocation` 再把第 50 行的 `perform_invocation` 接上，
后者是一个对 `cdl_invocation` **16 个构造子**（`Invocations_D.thy` 第 106 行起）
做分发的 `fun`。

模型用一个最小的 `cres`（"capability result"）复刻这个模板。
注意它的类型：两个错误处理器都必须返回**最终那种**结果，
否则模板根本接不起来——这是本章踩过的一个坑（见坑位清单第 9 条）：

```text
consts
  syscall ::
    "('e, 'a) cres
     \<Rightarrow> ('e \<Rightarrow> ('e, 'd) cres)
       \<Rightarrow> ('a \<Rightarrow> ('e, 'c) cres)
         \<Rightarrow> ('e \<Rightarrow> ('e, 'd) cres) \<Rightarrow> ('c \<Rightarrow> ('e, 'd) cres) \<Rightarrow> ('e, 'd) cres"
```

三条模板性质，全部一行证完：

```text
theorem
  syscall_decode_error_shortcuts:
    syscall (CErr ?e) ?dech ?arg ?argch ?perf = ?dech ?e

theorem
  syscall_arg_error_shortcuts:
    syscall (COk ?a) ?dech (\<lambda>_. CErr ?e) ?argch ?perf = ?argch ?e

theorem
  syscall_ok_runs_body:
    syscall (COk ?a) ?dech (\<lambda>x. COk (?f x)) ?argch ?perf = ?perf (?f ?a)
```

分发那半边留了两个结论，它们说的是同一件事的两面：
`is_call`/`can_block` 这两个标志**只有端点那一支用得到**，
所以 `InvokeTcb` 在两面对照下相等；而 `InvokeEndpoint` 把两个标志
原样带进效果里：

```text
theorem
  only_endpoint_uses_the_two_flags:
    perform_invocation ?ic ?cb (InvokeTcb ?p) =
    perform_invocation ?ic' ?cb' (InvokeTcb ?p)

theorem
  endpoint_uses_the_two_flags:
    perform_invocation True False (InvokeEndpoint ?p) =
    EffEndpoint ?p True False
```

这就是第 9 章"SysCall 会阻塞、SysSendNB 不会"在 capDL 层的形状：
`handle_syscall`（同文件第 186 行）用
`handle_invocation True True` / `handle_invocation False False`
把这些标志传下来。

---

## 23.11 文本层的 capDL：另一份 570 行的规范

前十节讲的都是 Isabelle 里那一层（`l4v/spec/capDL/`）。工程师实际手写的
是另一种东西：capDL **文本语言**，规范在 `capdl/capDL-tool/doc/capDL.md`，
570 行，自报 revision 1.1。它给自己的定位是这样的：

<!-- 源码块：capdl/capDL-tool/doc/capDL.md:9-16 -->
```text
This document defines capDL revision 1.1, a language for capability
distributions.

# Background and Purpose

The purpose of capDL is describing snapshots of a system running on the
seL4 microkernel. In particular, it can be used to describe which
entities have access to which seL4 capabilities.
```

"snapshot"这个词值得停一下——文本层允许写出**跑得到与否不管**的状态：

<!-- 源码块：capdl/capDL-tool/doc/capDL.md:25-26 -->
```text
via actual system executions. It is also possible to leave out details
in a system specification that for instance are not important for a
```

这正是 23.9 那台"合法类型、悬空目标"的图能在规格层写出来的原因，
只不过那边说的是 Isabelle 的 `cdl_state`，这边说的是语言本身允许。

语法一次列全十四种对象：

<!-- 源码块：capdl/capDL-tool/doc/capDL.md:81-83 -->
```text
      object_type ::= 'ep'  | 'notification' | 'tcb' | 'cnode' | 'ut' | 'irq' |
                      'asid_pool' | 'pt' | 'pd' | 'frame' | 'io_ports' |
                      'io_device' | 'io_pt' | 'vcpu'
```

而"数据模型"那一节给的构造子表只有十二个：

<!-- 源码块：capdl/capDL-tool/doc/capDL.md:229-243 -->
```text
    types CapMap = Map Word Cap

    data Object = Endpoint
                | Notification
                | TCB { slots :: CapMap, initArguments :: [Word] }
                | CNode { slots :: CapMap, sizeBits :: Word }
                | Untyped { maybeSizeBits :: Maybe Word }

                | ASIDPool { slots :: CapMap }
                | PT { slots :: CapMap }
                | PD { slots :: CapMap }
                | Frame { vmSizeBits :: Word }
                | IOPorts { size :: Word }
                | IOPT { slots :: CapMap, level :: Word }
                | IODevice { slots :: CapMap }
```

`'irq'` 与 `'vcpu'` 在语法里合法，在 `data Object` 里没有对应构造子——
同一份文件内部就有口径差，读的时候按"语法宽、模型窄"处理。
也别把这张表和 23.3 的十个对象混起来：Isabelle 层的 `cdl_object`
是第三套构造子名（`Tcb`、`CNode`、`IRQNode`、`ArchObj arch`）。
同一个"capDL 对象"在三个地方有三种拼法，这是本章最容易看串的一处。

CDT 在文本语言里是**独立的一段**，写成嵌套槽引用：

<!-- 源码块：capdl/capDL-tool/doc/capDL.md:147-151 -->
```text
### CDT Declarations

      cdt_decls ::= 'cdt' '{' cdt_decl* '}'

      cdt_decl ::= slot_ref '{' ((slot_ref | cdt_decl) ';'?)* '}'
```

外加能力声明里的 `- child_of` 注解（`capdl/capDL-tool/doc/capDL.md` 第 135 行的 `slot_ref`）。
两处合起来说明一件要紧事：一份手写的 capDL 规格**自己声明派生树**，
不是工具从"谁引用了谁"推出来的。23.5 那句"撤销的根据就是父亲指针"
在文本层的对应物就是这两个构造。

工具侧另有一份 Haskell 数据模型，和 Isabelle 层同名不同物。
最容易踩的是架构名——`data Arch` 只有五个取值
（`capdl/capDL-tool/doc/capDL.md` 第 220 行的 `RISCV`）：

<!-- 源码块：capdl/capDL-tool/doc/capDL.md:204-220 -->
```text
We refer to objects by name. This name could be of any type; for
convenience we either use a plain string or a string with an index. We
use the `Maybe` type of Haskell to express this.

    types ObjID = (String, Maybe Word)

With this the capability state of a system is fully described by a map
from `ObjID` to `Object`. Since not all objects and capabilities are
supported by seL4 on all machine architectures, we also store which
architecture the system is intended for.

    data Model =  Model {
                      arch :: Arch,
                      objects :: Map ObjID Object
                  }

    data Arch = IA32 | ARM11 | X86_64 | AARCH64 | RISCV
```

L4V 证明树那边是 `L4V_ARCH` ∈ `ARM`、`ARM_HYP`、`X64`、`RISCV64`、`AARCH64`
（`l4v/README.md` 第 144 行的 `L4V_ARCH`）。两边都是五个，
对应关系却要逐条查：`ARM11`↔`ARM`、`X86_64`↔`X64`、`RISCV`↔`RISCV64`；
`ARM_HYP` 在工具侧没有，`IA32` 在证明侧没有。

权利字段是三处最容易串的地方：

<!-- 源码块：capdl/capDL-tool/doc/capDL.md:283-292 -->
```text
store explicit access rights. These are modelled as follows:

    data Rights = Read | Write | Grant | GrantReply
    types CapRights = Set Right

Again in contrast to the security model of seL4, we explicitly
distinguish different types of capabilities in capDL and store slightly
different kinds of additional information with each. As a side effect,
we do not need an explicit representation of the create right. The
create right is conferred by the possession of an untyped capability.
```

文本层四种权利、**没有 create**；Isabelle 层（23.2）是
Endpoint/Notification/Reply/CNode 四类能力带自己的权利字段、其余一律全集；
第 24 章的 take-grant 模型里 `Create` 却是一个**显式权利**，
还是"摊平成全部权利"的那一个。三份文档都在说"权利"，说的是三种对象。

文本层把 create 藏进"持有 untyped 能力"这件事，反而和 take-grant 里
`extra_rights` 把 `Create` 摊平的效果同向：一条 untyped 能力
连 create/retype 带 revoke/delete 一起给
（`capdl/capDL-tool/doc/capDL.md` 第 321 行的 `revoke`）：

<!-- 源码块：capdl/capDL-tool/doc/capDL.md:317-321 -->
```text
In detail, the capabilities are as follows. We go through the list of
capabilities and give a brief indication of the authority they convey.
The `NullCap` is occasionally used to represent the absence of a
capability. An untyped capability points to an untyped object and
confers the right to issue create/retype and revoke/delete operations.
```

"covering set"是撤销集在文本层的名字
（`capdl/capDL-tool/doc/capDL.md` 第 253 行的 `ObjID`）：

<!-- 源码块：capdl/capDL-tool/doc/capDL.md:251-256 -->
```text
configurable size. Untyped objects are conceptual containers for
dynamically created objects. They cover a set of objects referred to by
their `ObjID`. This set is called the covering set. In the
implementation untyped objects must have a size, but in capDL
specifications we often want to leave the size unspecified (as large as
necessary).
```

最后是调度。文本层对形式化推理的表态只有一句
（`capdl/capDL-tool/doc/capDL.md` 第 532 行的 `Domain`）：

<!-- 源码块：capdl/capDL-tool/doc/capDL.md:532-533 -->
```text
The Domain schedule declaration is optional and only required for system
initialisation, not for reasoning about capability distribution.
```

23.8 说这一层的调度完全非确定、23.9 说井形性住在 sys-init，
这条声明是同一件事在文本语言里的镜子：domain schedule 只为初始化存在，
能力分布的推理不看它。

---

## 本章坑位清单（实测）

1. **把 `Structures_D.thy` 当类型层**：它全文 18 行，只有一个 import 加
   `arch_requalify_consts`。真正的入口分别是 `cdl_cap`（第 113 行）、
   `cdl_object`（第 245 行）、`cdl_state`（第 301 行），都在 `Types_D.thy`。
2. **以为 capDL 里有 `well_formed`**：`spec/capDL/` 全目录 grep 不到
   `well_formed`/`reachable`/`island`。井形性在 `l4v/sys-init/WellFormed_SI.thy`，
   它是 sys-init 证明的**前提**，不是 capDL 语义的一部分。
3. **把"对象存在"和"类型匹配"合成一条判据**：23.9 的
   `mismatched_is_no_dangling` + `mismatched_not_types_ok` 就是这条合并会漏掉的图。
   真实 `well_formed_caps`（第 223 行）本来就把两条分开合取。
4. **找不到 `tcb_pending_op_slot` 的号**：它是 5（`Types_D.thy` 第 347 行），
   而"哪些线程算活跃"只看它：`all_active_tcbs` 在 `Schedule_D.thy` 第 12 行，
   按域再筛一遍是第 18 行的 `active_tcbs_in_domain`。
   模型里对应 `pending_op_slot_is_5`、`all_active_is_three`。
5. **以为 capDL 的调度是确定的**：第 36 行那个 `\<sqinter>` 有两支，
   其中一支直接 `switch_to_thread None`。模型三条并列输出：
   `capdl_schedule_three_outcomes`、`abstract_is_one_of_capdl`（`\<in>`）、
   `capdl_is_not_deterministic`（`\<noteq>` singleton）。
6. **` datatype` 构造子里写 `right set` 不引号**：`CNodeCopyIntent cdl_right right set`
   报 `Bad number of arguments for type constructor: "Set.set"`。
   类型表达式一律进引号：`"cdl_right set"`。
7. **`@{verbatim "…"}` 卡通没闭合就往下写**：`Outer lexical error: bad input`，
   而且报错位置在**文件末尾附近**，不指回真正漏引号的那一行。
   本章一次性修了 13 处。
8. **嵌套 antiquotation**：`（"@{verbatim "…"}"第 14 行）` 这种"引号里再套卡通"
   直接是词法错误。要么 `@{verbatim "…"}` 后裸写行号，要么整体换成 markdown 反引号。
9. **五段模板里两个 handler 用了不同的类型变量**：真实 `syscall` 的两个错误处理器
   都返回最终类型；模型第一版把第一个写成 `('e, 'b) cres`，
   于是 `only_endpoint_uses_the_two_flags` 那条引理报
   `Type unification failed: Clash of types "_ ⇒ _" and "_ cdl_state_scheme"`。
   两个 handler 必须同为 `'e ⇒ ('e, 'd) cres`。
10. **`case` 里套 `case` 不加括号**：`case dec of … | COk a ⇒ case arg a of …`
    报 `Ambiguous input … produces 2 parse trees`（"Fortunately, only one parse tree
    is well-formed"——它是**警告**，编译照样过，但抽取输出会多出 40 行噪声）。
    给内层 `case` 加括号。
11. **拿 record 更新的老式括号写 `f (x ↦ v)`**：`cdl_objects s(p ↦ obj)` 报
    `Inner syntax error at "↦ obj )"`。老式括号 `r(fld := v)` 只认字段名。
    凡"更新一个函数字段"一律显式 lambda：
    `\<lparr>cdl_objects := (\<lambda>x. if x = p then Some obj else cdl_objects s x)\<rparr>`。
12. **record 更新写成 `r(fld := v)`**：同上，必须是 `r\<lparr>fld := v\<rparr>`。
13. **两个 record 值的相等/不相等交给 `simp`/`auto`**：`switch_to_thread x s ≠
    switch_to_thread y s` 这种目标 `simp` 完全没办法，`card` 三元素集合因此也算不出来
    （`capdl_schedule_three_outcomes` 一度想写成 `card … = 3`，删了）。
    改证一个**选择器方向的注入引理**
    （`switch_to_thread_inj`：由 `cdl_current_thread` 相等推 `x = y`），
    再 `by (auto dest: switch_to_thread_inj split: option.splits)`。
14. **`switch_to_thread \` {None, Some 1, Some 2}`**：函数部分应用被吃成
    "函数的象"，类型报 Clash。写 `(\<lambda>t. switch_to_thread t sched_state) \` {…}`
    （模型里 `capdl_schedule_as_image` 就是这么写的），
    并且数字要带类型 `(1::nat)`。
15. **`card_insert`**：Isabelle 2025 里它是 `card.insert`。
    而且 `apply (subst card.insert)` 对嵌套 insert 只匹配一次就失败——
    finite 集合的枚举式结论不如直接把集合等式证出来。
16. **用 `inv` 当绑定变量**：HOL 里 `inv` 是逆函数常量
    （`('a ⇒ 'b) ⇒ 'b ⇒ 'a`），于是 `perform_invocation ic cb inv` 报
    `Clash of types "_ ⇒ _" and "cdl_invocation"`。改名 `iv`。
17. **`auto` 想实例化四层嵌套的 `∃`**：`no_dangling` 那类
    "对每个对象、每个槽、每条边的目标"的否证，`auto` 会留下
    `∃a b. cdl_cdt s (a,b) = Some p` 之类做不出来。
    结构化写成 `proof (rule notI)` + `have W: "⋀ref cap. …"`，
     witness 用 `by (rule exI [of _ x], assumption)`。
18. **`lemma foo: x = UNIV` 不加引号**：外层 `=` 是关键词，报
    `command expected, but keyword = was found`。命题一律进引号。
19. **`simp` 留下 `(f' = f) = (f = f')`**：`eq_comm` 把结论翻了过来，
    看着"证完了"其实目标没关。把引理陈述改成和 `simp` 规范形一致的那一侧
    （`cap_type_matches_frame_checks_size` 写成 `= (?f' = ?f)`）。
20. **把 `\<lparr>}` 打成 `<lparr>}`**：五处同类笔误里 `sed` 只修好 4 处
    （UTF-8/locale 下多字节模式匹配不可靠），剩下的用 python 逐串替换。

---

## 官方教程对照

`https://docs.sel4.systems/Tutorials/` 的索引（抓取日期 2026-09-26）里
**没有任何一页讲 capDL、系统初始化器或 CDT**。kernel tutorials 一共 13 页
（`setting-up`、`get-the-tutorials`、`hello-world`、`capabilities`、`untyped`、
`mapping`、`threads`、`ipc`、`notifications`、`interrupts`、`fault-handlers`、
`mcs`、`seL4-end`），讲的全是"怎么用 libsel4 写用户态程序"；
capDL 在文档站是**独立的项目页**，不在这条教程链里。
所以本章没有逐条对照表，只有三处**同名不同物**要登记：

* **CSpace 树 ≠ CDT**。官方 `capabilities` 页画的是用户可见的 CSpace 层次；
  capDL 的 `cdl_cdt`（`l4v/spec/capDL/Types_D.thy` 第 189 行）
  记的是**派生关系**，与槽在树里的位置无关：一条能力可以被拷进任意一个 CNode，
  它的父亲仍然只有**一个**（`opt_parent`，`KHeap_D.thy` 第 100 行）。
  这就是为什么 23.6 的 `insert_cap_sibling` 与 `insert_cap_child`
  只差在 CDT 上，而 CSpace 里的位置可以完全不同。
* **内核 C 侧没有那张全局 CDT 表**。撤销关系在实现里散落在每个 CNode 槽的
  MDB next 指针上：`cteRevoke`（`seL4/src/object/cnode.c` 第 528 行）
  沿 `mdb_node_get_mdbNext` 顺着兄弟链走、对每个"确实是本槽孩子"的槽调
  `cteDelete`（同文件第 551 行），而 `cteDelete` 自己再递归清子树。
  也就是说 capDL 用**一个全局函数** `cdl_cdt` 表达的树，
  内核用**链 + 递归**表达。第 6 章说"撤销是 O(子树)"，根据就在这里。
* **文档里的 "domain" 有三种**。官方 MCS 教程的 domain 是调度单位
  （第 14 章）；capDL 状态里的 `cdl_current_domain` 与
  `cdl_tcb_domain` 是**图上的一个字段**（`Schedule_D.thy` 第 18 行的
  `active_tcbs_in_domain` 按它筛线程）；第 22 章的 `'a partition` 是
  **信息流观察者**。本章模型里 `mk_tcb` 的那个 `nat` 是第一种含义，
  与第 22 章的域没有任何关系。

另外两处口径值得在这里说明白：

* 官方材料说"seL4 是形式化验证过的"时，指的是第 16–22 章那条
  抽象规范→可执行规范→C 的精化链；capDL 站在这条链**旁边**，
  它的下游是系统初始化器（README 第 24–26 行同时提到
  `proof/drefine/` 里的精化证明与"capDL spec also forms the basis of
  the system initialiser proofs"）。
* 第 24 章的分区隔离案例会在本章这套类型上写：
  隔离性质在 capDL 层不是内核定理，而是"给定两张子图，检查它们的可达闭包不相交"
  ——而**可达闭包这个词本身不在 `spec/capDL/` 里**（本节开头那条 grep 结果），
  它是 sys-init 与用户工具那侧的概念。

外部 URL 本身不在第 5 关的校验范围内；本章凡说"真实代码是这么写的"，
后面都跟着一个被机器核对过的 `l4v/…` 或 `seL4/…` 路径与行号。

---

上一章：[22 · 非干扰](22-infoflow.md) ｜ 下一章：[24 · 综合案例：分区隔离](24-capstone.md) ｜ 返回：[README](../README.md)
