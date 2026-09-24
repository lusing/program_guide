theory S02_kernel_objects
  imports Main
begin

section \<open>2.1 内核对象：seL4 里只有"对象 + 能力"\<close>

text \<open>
  seL4 的内核不提供"文件""进程""socket"这类抽象，它只提供一组
  \emph{内核对象（kernel objects）}，用户态对对象做任何事都必须出示
  \emph{能力（capability）}。真实的类型定义在
  @{verbatim "l4v/spec/abstract/Structures_A.thy"} 第 57 行：

  @{verbatim "datatype apiobject_type = Untyped | TCBObject | EndpointObject"}
  @{verbatim "  | NotificationObject | CapTableObject | ArchObject aobject_type"}

  用户可见的那一半在 C 头文件
  @{verbatim "seL4/libsel4/include/sel4/objecttype.h"} 里：
  @{verbatim "seL4_UntypedObject"}、@{verbatim "seL4_TCBObject"}、
  @{verbatim "seL4_EndpointObject"}、@{verbatim "seL4_NotificationObject"}、
  @{verbatim "seL4_CapTableObject"}（MCS 配置下还多
  @{verbatim "seL4_SchedContextObject"} 与 @{verbatim "seL4_ReplyObject"}）。

  注意两侧的对应关系不是"同一个枚举"，而是\emph{证明出来的}：C 侧的
  @{verbatim "api_object_t"} 与规范侧的 @{verbatim "apiobject_type"} 之间由
  @{verbatim "l4v/spec/abstract/Decode_A.thy"} 里的
  @{verbatim "data_to_obj_type"} 之类的解码函数连接，解码失败就是
  @{verbatim "IllegalOperation"}。本教程后面第 10 章会回到这一点。

  本章的模型按上面的形状建，但去掉体系结构相关的那一支（真实代码里的
  @{verbatim "ArchObject"} 分支），以便把注意力放在对象与能力的关系上。
\<close>

ML \<open>writeln "==== 02 开始 ===="\<close>

datatype apiobject_type =
    Untyped
  | TCBObject
  | EndpointObject
  | NotificationObject
  | CapTableObject

subsection \<open>2.2 能力的数据类型\<close>

text \<open>
  真实定义见 @{verbatim "l4v/spec/abstract/Structures_A.thy"} 第 102 行。
  为了能在本章里计算，模型把 @{verbatim "obj_ref"} 取成 @{typ nat}、
  @{verbatim "badge"} 取成 @{typ nat}、CNode 的 guard 取成 @{typ "bool list"}，
  这些选择在真实代码里分别是 @{verbatim "machine_word"} 与
  @{verbatim "cnode_index = bool list"}（第 84 行）。
\<close>

datatype rights = AllowRead | AllowWrite | AllowGrant | AllowGrantReply

type_synonym cap_rights = "rights set"
type_synonym obj_ref = nat
type_synonym badge = nat

datatype cap =
    NullCap
  | UntypedCap obj_ref nat nat              \<comment> \<open>指针 / 大小（2^n 字节）/ freeIndex\<close>
  | EndpointCap obj_ref badge cap_rights
  | NotificationCap obj_ref badge cap_rights
  | ReplyCap obj_ref cap_rights
  | CNodeCap obj_ref nat "bool list"        \<comment> \<open>指针 / 翻译位数 / guard\<close>
  | ThreadCap obj_ref
  | DomainCap
  | IRQControlCap
  | IRQHandlerCap nat
  | Zombie obj_ref "nat option" nat

text \<open>能力上挂着哪些权利，由下面这个函数给出。真实代码里它是
  @{verbatim "Structures_A.thy"} 自动生成的选择子 @{verbatim "cap_rights"}
  （第 242 行的 @{verbatim "mask_cap"} 就作用在它上面）。

  注意：那个选择子对不带 rights 字段的构造子返回 @{verbatim "UNIV"}，
  这是选择子的默认值，不是"这个能力拥有全部权利"。语义上
  @{verbatim "NullCap"} 什么也不授权，所以本模型按语义写成空集。\<close>

definition cap_rights_of :: "cap \<Rightarrow> cap_rights" where
  "cap_rights_of c \<equiv> case c of
      EndpointCap _ _ R      \<Rightarrow> R
    | NotificationCap _ _ R  \<Rightarrow> R
    | ReplyCap _ R           \<Rightarrow> R
    | _                      \<Rightarrow> {}"

definition is_ep_cap :: "cap \<Rightarrow> bool" where
  "is_ep_cap c \<equiv> case c of EndpointCap _ _ _ \<Rightarrow> True | _ \<Rightarrow> False"

definition obj_ref_of :: "cap \<Rightarrow> obj_ref" where
  "obj_ref_of c \<equiv> case c of
      UntypedCap r _ _       \<Rightarrow> r
    | EndpointCap r _ _      \<Rightarrow> r
    | NotificationCap r _ _  \<Rightarrow> r
    | ReplyCap r _           \<Rightarrow> r
    | CNodeCap r _ _         \<Rightarrow> r
    | ThreadCap r            \<Rightarrow> r
    | _                      \<Rightarrow> 0"

subsection \<open>2.3 对象被创建时得到的"原始能力"\<close>

text \<open>
  retype 一个对象时，内核会给目标槽位装上一个\emph{原始能力（original cap）}。
  真实定义在 @{verbatim "l4v/spec/abstract/Retype_A.thy"} 的
  @{verbatim "default_cap"}（紧跟着 "Creating Caps" 一节）：

  @{verbatim "default_cap EndpointObject oref s _ = EndpointCap oref 0 UNIV"}
  @{verbatim "default_cap NotificationObject oref s _ = NotificationCap oref 0 {AllowRead,AllowWrite}"}

  端点能力默认是\emph{全权}的，通知能力默认\emph{不给 Grant}——因为没有
  badge 的通知能力无法区分发送方，转授出去没有意义。
\<close>

primrec default_cap :: "apiobject_type \<Rightarrow> obj_ref \<Rightarrow> nat \<Rightarrow> cap" where
  "default_cap Untyped oref sz = UntypedCap oref sz 0"
| "default_cap TCBObject oref _ = ThreadCap oref"
| "default_cap EndpointObject oref _ = EndpointCap oref 0 UNIV"
| "default_cap NotificationObject oref _ = NotificationCap oref 0 {AllowRead, AllowWrite}"
| "default_cap CapTableObject oref sz = CNodeCap oref sz []"

lemma ep_default_has_all_rights:
  "cap_rights_of (default_cap EndpointObject p sz) = UNIV"
  by (simp add: cap_rights_of_def)

lemma ntfn_default_cannot_grant:
  "AllowGrant \<notin> cap_rights_of (default_cap NotificationObject p sz)"
  by (simp add: cap_rights_of_def)

lemma untyped_default_free_index_zero:
  "default_cap Untyped p sz = UntypedCap p sz 0"
  by simp

text \<open>这两条差别在第 5、6 章会变成真正的定理：\emph{派生出来的能力，权利不可能
  比原始能力更多}。而"通知不给 Grant"这一条，正是"权利不是从天上掉下来的"
  的第一个例子。\<close>

subsection \<open>2.4 对象的大小\<close>

text \<open>
  CNode 是个特例：用户说"要一个 n 位的 CNode"，内核实际占用的是
  @{verbatim "obj_size_bits + slot_bits"} 位，因为槽位本身也要空间
  （真实定义 @{verbatim "Retype_A.thy"} 的 @{verbatim "obj_bits_api"}）。
\<close>

definition slot_bits :: nat where "slot_bits \<equiv> 4"

definition obj_bits_api :: "apiobject_type \<Rightarrow> nat \<Rightarrow> nat" where
  "obj_bits_api t sz \<equiv> case t of
      CapTableObject \<Rightarrow> sz + slot_bits
    | _              \<Rightarrow> sz"

lemma cnode_needs_more_than_asked: "obj_bits_api CapTableObject sz > sz"
  by (simp add: obj_bits_api_def slot_bits_def)

lemma tcb_needs_exactly_asked: "obj_bits_api TCBObject sz = sz"
  by (simp add: obj_bits_api_def)

subsection \<open>2.5 内核堆：对象表\<close>

text \<open>
  内核状态的核心是一张 @{verbatim "kheap"}：地址 @{verbatim "\<Rightarrow>"} 可选对象
  （真实定义 @{verbatim "Structures_A.thy"} 第 522 行：
  @{verbatim "type_synonym kheap = obj_ref => kernel_object option"}）。
  模型里省掉对象的内容细节，只保留"这个地址上有没有东西"。
\<close>

type_synonym kheap = "obj_ref \<Rightarrow> apiobject_type option"

definition empty_heap :: kheap where
  "empty_heap \<equiv> \<lambda>_. None"

definition alloc :: "obj_ref \<Rightarrow> apiobject_type \<Rightarrow> kheap \<Rightarrow> kheap" where
  "alloc p t h \<equiv> h(p \<mapsto> t)"

lemma alloc_hit: "alloc p t h p = Some t"
  by (simp add: alloc_def)

lemma alloc_miss: "q \<noteq> p \<Longrightarrow> alloc p t h q = h q"
  by (simp add: alloc_def)

text \<open>真实内核里"地址上有对象"这件事还需要更强的不变式：对象类型与地址对齐
  一致、同一个物理区域不能被两个对象覆盖（第 15、17 章）。\<close>

ML \<open>
  writeln (@{make_string} @{thm ep_default_has_all_rights});
  writeln (@{make_string} @{thm ntfn_default_cannot_grant})
\<close>

ML \<open>writeln "==== 02 结束 ===="\<close>

end
