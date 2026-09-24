theory S03_rights
  imports Main
begin

section \<open>3.1 权利就是一个集合\<close>

text \<open>
  seL4 的访问控制只有四个"位"（真实定义
  @{verbatim "l4v/spec/abstract/CapRights_A.thy"} 第 19 行）：

  @{verbatim "datatype rights = AllowRead | AllowWrite | AllowGrant | AllowGrantReply"}
  @{verbatim "type_synonym cap_rights = rights set"}

  四个位在不同能力类型上的\emph{含义}不同，所以同一份类型被复用了两次：

  \begin{itemize}
    \item 端点能力上：@{verbatim "AllowWrite"} 别名 @{verbatim "AllowSend"}，
          @{verbatim "AllowRead"} 别名 @{verbatim "AllowRecv"}（同文件第 22–27 行）；
    \item 页能力上：@{verbatim "AllowRead"} / @{verbatim "AllowWrite"} 就是读写；
    \item @{verbatim "AllowGrant"} 表示"允许把这个能力再转授出去"；
    \item @{verbatim "AllowGrantReply"} 表示"允许用它建立 Reply 能力"。
  \end{itemize}

  用户侧看到的同样是这四个位，见
  @{verbatim "seL4/libsel4/include/sel4/shared_types.h"}：
  @{verbatim "seL4_CanRead"}、@{verbatim "seL4_CanWrite"}、@{verbatim "seL4_CanGrant"}、
  @{verbatim "seL4_CanGrantReply"}、@{verbatim "seL4_AllRights"}。
\<close>

ML \<open>writeln "==== 03 开始 ===="\<close>

datatype rights = AllowRead | AllowWrite | AllowGrant | AllowGrantReply

type_synonym cap_rights = "rights set"

definition all_rights :: cap_rights where "all_rights \<equiv> UNIV"
definition no_rights :: cap_rights where "no_rights \<equiv> {}"

subsection \<open>3.2 掩码：派生时削权\<close>

text \<open>
  真实定义在 @{verbatim "l4v/spec/abstract/Structures_A.thy"} 第 242 行：

  @{verbatim "mask_cap R cap \<equiv> cap_rights_update (cap_rights cap \<inter> R) cap"}

  一句话：掩码 = 取交集。本章把它单独抽出来证，因为整条安全链都压在这上面。
\<close>

definition mask :: "cap_rights \<Rightarrow> cap_rights \<Rightarrow> cap_rights" where
  "mask R R' \<equiv> R \<inter> R'"

lemma mask_never_grows: "mask R R' \<subseteq> R"
  by (auto simp: mask_def)

lemma mask_never_grows_mem: "r \<in> mask R R' \<Longrightarrow> r \<in> R"
  by (auto simp: mask_def)

lemma mask_idempotent: "mask (mask R R') R' = mask R R'"
  by (auto simp: mask_def)

lemma mask_mono: "R1 \<subseteq> R2 \<Longrightarrow> mask R R1 \<subseteq> mask R R2"
  by (auto simp: mask_def)

lemma mask_empty_is_no_rights: "mask R no_rights = no_rights"
  by (auto simp: mask_def no_rights_def)

text \<open>
  @{thm mask_never_grows} 是 seL4 权限模型的地基：\emph{任何派生操作都只能
  减少权利}。第 5 章会把它用到 mint / copy / move 上，第 21 章会把它放大成
  完整性（integrity）定理。
\<close>

subsection \<open>3.3 虚拟内存权利：交集可能不合法\<close>

text \<open>
  这里有一个真实的坑，写在 @{verbatim "l4v/spec/abstract/VMRights_A.thy"} 的
  注释里：能力权利和 VM 权利共用同一个类型，但 VM 侧只承认三种组合——
  @{verbatim "vm_kernel_only = {}"}、
  @{verbatim "vm_read_only = {AllowRead}"}、
  @{verbatim "vm_read_write = {AllowRead,AllowWrite}"}（第 21–33 行）。

  直接取交集可能得到 @{term "{AllowWrite}"} 这种"只写"的非法组合，所以
  交集之后还要 @{verbatim "validate_vm_rights"}（第 45 行）再压一次：

  @{verbatim "mask_vm_rights V R \<equiv> validate_vm_rights (V \<inter> R)"}（第 55 行）
\<close>

type_synonym vm_rights = cap_rights

definition vm_kernel_only :: vm_rights where "vm_kernel_only \<equiv> {}"
definition vm_read_only :: vm_rights where "vm_read_only \<equiv> {AllowRead}"
definition vm_read_write :: vm_rights where "vm_read_write \<equiv> {AllowRead, AllowWrite}"

definition valid_vm_rights :: "vm_rights set" where
  "valid_vm_rights \<equiv> {vm_read_write, vm_read_only, vm_kernel_only}"

definition validate_vm_rights :: "vm_rights \<Rightarrow> vm_rights" where
  "validate_vm_rights rs \<equiv>
     if AllowRead \<in> rs
     then if AllowWrite \<in> rs then vm_read_write else vm_read_only
     else vm_kernel_only"

definition mask_vm_rights :: "vm_rights \<Rightarrow> cap_rights \<Rightarrow> vm_rights" where
  "mask_vm_rights V R \<equiv> validate_vm_rights (V \<inter> R)"

lemma validate_always_valid: "validate_vm_rights R \<in> valid_vm_rights"
  by (auto simp: validate_vm_rights_def valid_vm_rights_def
                 vm_kernel_only_def vm_read_only_def vm_read_write_def)

lemma mask_vm_always_valid: "mask_vm_rights V R \<in> valid_vm_rights"
  by (simp add: mask_vm_rights_def validate_always_valid)

text \<open>上面这条看似平淡，实际挡住了一类真实 bug：只写不可读的映射在多数
  体系结构上要么无法实现，要么语义含混，所以规范\emph{在类型层面就不让它出现}。\<close>

lemma write_only_is_not_valid: "{AllowWrite} \<notin> valid_vm_rights"
  by (auto simp: valid_vm_rights_def vm_kernel_only_def vm_read_only_def
                 vm_read_write_def)

lemma write_only_becomes_kernel_only:
  "validate_vm_rights {AllowWrite} = vm_kernel_only"
  by (auto simp: validate_vm_rights_def vm_kernel_only_def)

text \<open>注意最后一条：不是"报错"，而是\emph{静默降到最小权限}。这是 seL4 的
  一贯作风——权利相关的问题默认往"更小"的方向收敛，而不是往"更大"。\<close>

subsection \<open>3.4 从数据字解码权利\<close>

text \<open>
  用户通过一个机器字传权利进来，内核用 @{verbatim "data_to_rights"} 解码
  （@{verbatim "l4v/spec/abstract/CSpace_A.thy"} 第 56 行附近）。
  模型里用一个四位布尔组合同样地做一次，顺便验证"解码再掩码"是幂等的。
\<close>

type_synonym rights_word = "bool \<times> bool \<times> bool \<times> bool"

definition data_to_rights :: "rights_word \<Rightarrow> cap_rights" where
  "data_to_rights w \<equiv> case w of (gr, gw, rd, wr) \<Rightarrow>
     (if rd then {AllowRead} else {}) \<union>
     (if wr then {AllowWrite} else {}) \<union>
     (if gr then {AllowGrant} else {}) \<union>
     (if gw then {AllowGrantReply} else {})"

lemma decode_then_mask_idempotent:
  "mask (mask (data_to_rights w) R) R = mask (data_to_rights w) R"
  by (simp add: mask_idempotent)

lemma decode_subset_of_all: "data_to_rights w \<subseteq> all_rights"
  by (auto simp: data_to_rights_def all_rights_def)

ML \<open>
  writeln (@{make_string} @{thm mask_never_grows});
  writeln (@{make_string} @{thm mask_vm_always_valid})
\<close>

ML \<open>writeln "==== 03 结束 ===="\<close>

end
