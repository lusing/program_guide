# 17 · 不变式

对应示例：`../examples/S17_invariants.thy`

## 17.1 主不变式只是一条 `and` 链

前十六章证的是单个操作："这次调用如果成功，结果是这样"。
要证"内核**永远**是对的"，还差一组每次系统调用前后都成立的性质。
l4v 里它们的总和写在
`l4v/proof/invariant-abstract/Invariants_AI.thy` 第 1035 行，一行而已：

<!-- 源码块：l4v/proof/invariant-abstract/Invariants_AI.thy 第 1033--1035 行 -->
```text
definition
  invs :: "'z::state_ext state \<Rightarrow> bool" where
  "invs \<equiv> valid_state and cur_tcb"
```

这里的 `and` 不是 HOL 对象级的合取，而是**谓词上的合取**，
也就是函数空间上的 `inf`。缩写由
`l4v/lib/Monads/Fun_Pred_Syntax.thy` 第 26 行给出：

<!-- 源码块：l4v/lib/Monads/Fun_Pred_Syntax.thy 第 26--27 行 -->
```text
abbreviation pred_conj :: "('a \<Rightarrow> 'b::boolean_algebra) \<Rightarrow> ('a \<Rightarrow> 'b) \<Rightarrow> ('a \<Rightarrow> 'b)" where
  "pred_conj \<equiv> inf"
```

中缀名是第 61 行那句注释之后才配上去的：

<!-- 源码块：l4v/lib/Monads/Fun_Pred_Syntax.thy 第 61--62 行 -->
```text
  (* infixl instead of infixr, because we want to split off conjuncts from the left *)
  notation pred_conj (infixl "and" 35)
```

同一份代码库里另有一份**互不兼容**的记号：`l4v/lib/sep_algebra/Separation_Algebra.thy`
第 25 行的 `pred_and` 用 `infixr`，定义式还带 λ：

<!-- 源码块：l4v/lib/sep_algebra/Separation_Algebra.thy 第 24--26 行 -->
```text
abbreviation (input)
  pred_and :: "('a \<Rightarrow> bool) \<Rightarrow> ('a \<Rightarrow> bool) \<Rightarrow> 'a \<Rightarrow> bool" (infixr "and" 35) where
  "a and b \<equiv> \<lambda>s. a s \<and> b s"
```

同一个 `and`，两份文件里结合方向相反——打开一个新理论时先查它 import 了哪个 bundle，
这是"复制粘贴一条引理就证明不动了"的一个来源。

`valid_state` 展开来是一条长链，`Invariants_AI.thy` 第 1000 行起，
到第 1025 行收尾，二十六支：

<!-- 源码块：l4v/proof/invariant-abstract/Invariants_AI.thy 第 997--1025 行 -->
```text
definition
  valid_state :: "'z::state_ext state \<Rightarrow> bool"
where
  "valid_state \<equiv> valid_pspace
                  and valid_mdb
                  and valid_ioc
                  and valid_idle
                  and only_idle
                  and if_unsafe_then_cap
                  and valid_reply_caps
                  and valid_reply_masters
                  and valid_global_refs
                  and valid_arch_state
                  and valid_cur_fpu
                  and valid_irq_node
                  and valid_irq_handlers
                  and valid_irq_states
                  and valid_machine_state
                  and valid_vspace_objs
                  and valid_arch_caps
                  and valid_global_objs
                  and valid_kernel_mappings
                  and equal_kernel_mappings
                  and valid_asid_map
                  and valid_global_vspace_mappings
                  and pspace_in_kernel_window
                  and cap_refs_in_kernel_window
                  and pspace_respects_device_region
                  and cap_refs_respects_device_region"
```

第一支 `valid_pspace`（同文件第 802 行）自己还是合取，
`valid_objs` 就在它里面：

<!-- 源码块：l4v/proof/invariant-abstract/Invariants_AI.thy 第 799--806 行 -->
```text
definition
  valid_pspace :: "'z::state_ext state \<Rightarrow> bool"
where
  "valid_pspace \<equiv> valid_objs and pspace_aligned and
                  pspace_distinct and if_live_then_nonz_cap
                  and zombies_final
                  and (\<lambda>s. sym_refs (state_refs_of s))
                  and (\<lambda>s. sym_refs (state_hyp_refs_of s))" (* ARMHYP *)
```

后两支是第 15 章对齐结论的系统层面形态，定义在
`l4v/proof/invariant-abstract/InvariantsPre_AI.thy` 第 104 行和第 115 行：

<!-- 源码块：l4v/proof/invariant-abstract/InvariantsPre_AI.thy 第 103--107 行 -->
```text
definition
  pspace_aligned :: "'z::state_ext state \<Rightarrow> bool"
where
  "pspace_aligned s \<equiv>
     \<forall>x \<in> dom (kheap s). is_aligned x (obj_bits (the (kheap s x)))"
```

<!-- 源码块：l4v/proof/invariant-abstract/InvariantsPre_AI.thy 第 113--120 行 -->
```text
text "objects don't overlap"
definition
  pspace_distinct :: "'z::state_ext state \<Rightarrow> bool"
where
  "pspace_distinct \<equiv>
   \<lambda>s. \<forall>x y ko ko'. kheap s x = Some ko \<and> kheap s y = Some ko' \<and> x \<noteq> y \<longrightarrow>
         {x .. x + (2 ^ obj_bits ko - 1)} \<inter>
         {y .. y + (2 ^ obj_bits ko' - 1)} = {}"
```

合取链没有新的逻辑内容：它只是**给很多条性质起一个名字**。
后果是**两个方向**的——证的时候一条条证，用的时候一条条取出来。
示例把这条记号照抄了一份（`infixl`，理由同上），四条基本规则（实测）：

```text
theorem and_apply: (?P and ?Q) ?s = (?P ?s \<and> ?Q ?s)
```

```text
theorem and3_apply: (?P and ?Q and ?R) ?s = (?P ?s \<and> ?Q ?s \<and> ?R ?s)
```

```text
theorem andD1: (?P and ?Q) ?s \<Longrightarrow> ?P ?s
```

```text
theorem andD2: (?P and ?Q) ?s \<Longrightarrow> ?Q ?s
```

`invs and 额外条件` 这种写法后面两节要用，它就是第 16 章那条
`invariant f P` 的前件形状。

## 17.2 `valid_objs`：类型一致性藏在分支里

真实规范里 `valid_objs`（同文件第 557 行）只说"堆里每个对象对自己的类型合法"，

<!-- 源码块：l4v/proof/invariant-abstract/Invariants_AI.thy 第 556--559 行 -->
```text
definition
  valid_objs :: "'z::state_ext state \<Rightarrow> bool"
where
  "valid_objs s \<equiv> \<forall>ptr \<in> dom $ kheap s. \<exists>obj. kheap s ptr = Some obj \<and> valid_obj ptr obj s"
```

类型与引用的一致性藏在 `valid_obj`（第 547 行）的分支里，CNode 那一支走 `valid_cs`：

<!-- 源码块：l4v/proof/invariant-abstract/Invariants_AI.thy 第 546--554 行 -->
```text
definition
  valid_obj :: "obj_ref \<Rightarrow> kernel_object \<Rightarrow> 'z::state_ext state \<Rightarrow> bool"
where
  "valid_obj ptr ko s \<equiv> case ko of
    Endpoint p \<Rightarrow> valid_ep p s
  | Notification p \<Rightarrow> valid_ntfn p s
  | TCB t \<Rightarrow> valid_tcb ptr t s
  | CNode sz cs \<Rightarrow> valid_cs sz cs s
  | ArchObj ao \<Rightarrow> arch_valid_obj ao s"
```

<!-- 源码块：l4v/proof/invariant-abstract/Invariants_AI.thy 第 425--427 行 -->
```text
definition
  valid_cs :: "nat \<Rightarrow> cnode_contents \<Rightarrow> 'z::state_ext state \<Rightarrow> bool" where
  "valid_cs sz cs s \<equiv> (\<forall>cap \<in> ran cs. s \<turnstile> cap) \<and> valid_cs_size sz cs"
```

`valid_cs` 说的是"槽里**每个**能力都合法"。示例把"合法"具体化成
"能力指向的对象存在且类型对得上"，对象表、槽位表、CDT 三样东西各是一个字段。
第三个字段的类型抄自 `l4v/spec/abstract/Structures_A.thy` 第 532 行的 `cdt`
（"槽位到父槽位的偏函数"，第 05 章的 CDT 就是这个东西）。三条基本结论（实测）：

```text
theorem
  empty_state_is_valid:
    valid_objs \<lparr>ks_objs = \<lambda>_. None, ks_caps = \<lambda>_. None, ks_cdt = \<lambda>_. None\<rparr>
```

```text
theorem
  valid_objsI:
    (\<And>sl c.
        ks_caps ?s sl = Some c \<Longrightarrow>
        case cap_target c of None \<Rightarrow> True
        | Some p \<Rightarrow> ks_objs ?s p = cap_type c) \<Longrightarrow>
    valid_objs ?s
```

```text
theorem
  cap_to_missing_object_is_invalid:
    \<lbrakk>ks_caps ?s ?sl = Some (EndpointCap ?p); ks_objs ?s ?p = None\<rbrakk>
    \<Longrightarrow> \<not> valid_objs ?s
```

最后一条的方向值得注意：**单个**坏能力就足以推翻整个 `valid_objs`，
不需要遍历全堆。

## 17.3 插入能力：对象存在且类型对得上才保得住

示例里的 `insert_cap` 只改 `ks_caps` 一个字段，所以另外两个投影是白送的（实测）：

```text
theorem insert_cap_untouched: ks_cdt (insert_cap ?c ?sl ?s) = ks_cdt ?s
```

```text
theorem insert_cap_ks_objs: ks_objs (insert_cap ?c ?sl ?s) = ks_objs ?s
```

保持性只有两种安全做法，插 `NullCap` 无条件安全；
插一个指向 `p` 的能力，**必须先有 `p` 处类型匹配的对象**（实测）：

```text
theorem
  insert_cap_preserves_valid_objs:
    valid_objs ?s \<Longrightarrow> valid_objs (insert_cap NullCap ?sl ?s)
```

```text
theorem
  insert_cap_needs_object:
    \<lbrakk>valid_objs ?s; ks_objs ?s ?p = Some EndpointType\<rbrakk>
    \<Longrightarrow> valid_objs (insert_cap (EndpointCap ?p) ?sl ?s)
```

反方向也成立，而且是**类型**不对就不行，与对象在不在无关（实测）：

```text
theorem
  insert_wrong_type_breaks_valid_objs:
    ks_objs ?s ?p = Some NotificationType \<Longrightarrow>
    \<not> valid_objs (insert_cap (EndpointCap ?p) ?sl ?s)
```

真实内核之所以不会掉进最后这个坑，是因为 retype 时写进目的槽的能力
由对象类型**算**出来：`l4v/spec/abstract/Retype_A.thy` 第 31 行的 `default_cap`，
函数体在第 33--39 行（实测的是本节定理，这里只标定义位置）：

<!-- 源码块：l4v/spec/abstract/Retype_A.thy 第 30--39 行 -->
```text
primrec
  default_cap :: "apiobject_type  \<Rightarrow> obj_ref \<Rightarrow> nat \<Rightarrow> bool \<Rightarrow> cap"
where
  "default_cap CapTableObject oref s _ = CNodeCap oref s []"
| "default_cap Untyped oref s dev = UntypedCap dev oref s 0"
| "default_cap TCBObject oref s _ = ThreadCap oref"
| "default_cap EndpointObject oref s _ = EndpointCap oref 0 UNIV"
| "default_cap NotificationObject oref s _ =
     NotificationCap oref 0 {AllowRead, AllowWrite}"
| "default_cap (ArchObject aobj) oref s dev = ArchObjectCap (arch_default_cap aobj oref s dev)"
```

也就是说"一个 `EndpointCap` 指向通知对象"这类状态在真实规范里**根本构造不出来**，
而不是"构造出来了但证明失败了"。这是规范设计的功夫，不是证明的功夫。

## 17.4 `valid_mdb`：CDT 边两端的槽都得非空

真实定义在 `l4v/proof/invariant-abstract/Invariants_AI.thy` 第 899 行开始，
十条合取：

<!-- 源码块：l4v/proof/invariant-abstract/Invariants_AI.thy 第 899--907 行 -->
```text
definition
  "valid_mdb \<equiv> \<lambda>s. mdb_cte_at (swp (cte_wp_at ((\<noteq>) NullCap)) s) (cdt s) \<and>
                   untyped_mdb (cdt s) (caps_of_state s) \<and> descendants_inc (cdt s) (caps_of_state s) \<and>
                   no_mloop (cdt s) \<and> untyped_inc (cdt s) (caps_of_state s) \<and>
                   ut_revocable (is_original_cap s) (caps_of_state s) \<and>
                   irq_revocable (is_original_cap s) (caps_of_state s) \<and>
                   reply_master_revocable (is_original_cap s) (caps_of_state s) \<and>
                   reply_mdb (cdt s) (caps_of_state s) \<and>
                   valid_arch_mdb (is_original_cap s) (caps_of_state s)"
```

坦白一句：第一条里的 `mdb_cte_at` 与 `swp` **不在这份代码树里**
（它们来自 l4v 依赖的 AbsSpec 会话），所以本章对第一条只读到"CDT 边上的槽
得真的持有非空能力"为止，不再往下猜。模型里把这一条具体化成
"`ks_cdt` 的每条边，两端都不是空格"——这既是对第一条的一种读法，
也正是 17.5 里 `delete_cap` 会当场破坏的那种性质（实测）：

```text
theorem
  no_edges_is_valid_mdb:
    valid_mdb \<lparr>ks_objs = \<lambda>_. None, ks_caps = \<lambda>_. None, ks_cdt = \<lambda>_. None\<rparr>
```

```text
theorem
  edge_to_empty_slot_is_invalid:
    \<lbrakk>ks_cdt ?s ?sl = Some ?p; ks_caps ?s ?p = None\<rbrakk> \<Longrightarrow> \<not> valid_mdb ?s
```

两端各有一条消去规则，父子都要（实测）：

```text
theorem
  valid_mdbD:
    \<lbrakk>valid_mdb ?s; ks_cdt ?s ?child = Some ?parent\<rbrakk>
    \<Longrightarrow> ks_caps ?s ?parent \<noteq> None
```

```text
theorem
  valid_mdbD_child:
    \<lbrakk>valid_mdb ?s; ks_cdt ?s ?child = Some ?parent\<rbrakk>
    \<Longrightarrow> ks_caps ?s ?child \<noteq> None
```

插入这一侧很温顺，因为它不碰 CDT（实测）：

```text
theorem
  insert_cap_preserves_valid_mdb:
    valid_mdb ?s \<Longrightarrow> valid_mdb (insert_cap NullCap ?sl ?s)
```

## 17.5 删除能力：为什么 l4v 要先问 `emptyable`

示例照内核的做法定义删除：能力清成空格、**这个槽自己的**CDT 出边一起摘掉，
但别人的边指向它时不动（实测，投影方程即删除的定义展开）：

```text
theorem
  delete_cap_ks_caps:
    ks_caps (delete_cap ?sl ?s) = (ks_caps ?s)(?sl := None)
```

```text
theorem
  delete_cap_ks_cdt: ks_cdt (delete_cap ?sl ?s) = (ks_cdt ?s)(?sl := None)
```

于是 17.4 那条不变式可以当场破掉。注意前件里那句 `?child ≠ ?parent`：
它排除的是"自己当自己父亲"这种退化情形——那种情况下连出边也被摘掉了，
破坏不了不变式（实测）：

```text
theorem
  delete_parent_cap_breaks_valid_mdb:
    \<lbrakk>ks_cdt ?s ?child = Some ?parent; ?child \<noteq> ?parent\<rbrakk>
    \<Longrightarrow> \<not> valid_mdb (delete_cap ?parent ?s)
```

这就是 `l4v/proof/invariant-abstract/CNodeInv_AI.thy` 第 2527 行的
`cap_delete_invs` 为什么要在前件里额外要求 `emptyable ptr`：
先把子孙从 CDT 上摘干净，才允许删。

<!-- 源码块：l4v/proof/invariant-abstract/CNodeInv_AI.thy 第 2527--2531 行 -->
```text
lemma cap_delete_invs[wp]:
  "\<And>ptr.
    \<lbrace>invs and emptyable ptr :: 'state_ext state \<Rightarrow> bool\<rbrace>
      cap_delete ptr
    \<lbrace>\<lambda>rv. invs\<rbrace>"
```

模型里对应的条件叫 `no_children`（"没有任何槽将此槽认作父亲"），
两条保持性凑成完整一对（实测）：

```text
theorem
  delete_cap_preserves_valid_objs:
    valid_objs ?s \<Longrightarrow> valid_objs (delete_cap ?sl ?s)
```

```text
theorem
  delete_cap_keeps_valid_mdb_if_no_children:
    \<lbrakk>valid_mdb ?s; no_children ?parent ?s\<rbrakk>
    \<Longrightarrow> valid_mdb (delete_cap ?parent ?s)
```

`valid_objs` 那一支不需要任何额外条件，因为删除不碰对象表——
**"要不要条件"这件事本身就是每个字段的结论**，逐条问一遍才知道。

## 17.6 打包成 `invs`：使用与保持

模型把两条不变式包成一个总谓词，四条基本定理（实测）：

```text
theorem invsI: \<lbrakk>valid_objs ?s; valid_mdb ?s\<rbrakk> \<Longrightarrow> invs ?s
```

```text
theorem invsD_objs: invs ?s \<Longrightarrow> valid_objs ?s
```

```text
theorem invsD_mdb: invs ?s \<Longrightarrow> valid_mdb ?s
```

两条保持性，一条无条件、一条带 `no_children`（实测）：

```text
theorem invs_insert_null: invs ?s \<Longrightarrow> invs (insert_cap NullCap ?sl ?s)
```

```text
theorem
  invs_delete_if_no_children:
    \<lbrakk>invs ?s; no_children ?sl ?s\<rbrakk> \<Longrightarrow> invs (delete_cap ?sl ?s)
```

那两条消去规则对应 l4v 里 `Invariants_AI.thy` 第 3308 行的
`invs_valid_objs`，它标着 `[elim!]`——所以真实证明里
`apply (erule invs_valid_objs)` 这类一步就顺手把 `invs` 拆开了：

<!-- 源码块：l4v/proof/invariant-abstract/Invariants_AI.thy 第 3308--3310 行 -->
```text
lemma invs_valid_objs [elim!]:
  "invs s \<Longrightarrow> valid_objs s"
  by (simp add: invs_def valid_state_def valid_pspace_def)
```

注意它的证明：`invs_def` 一层、`valid_state_def` 一层、`valid_pspace_def` 一层，
**三层展开才碰到 `valid_objs`**。合取链的代价就在这里——
用一条子不变式，得先知道它挂在哪个名字下面。
而 17.5 那条 `cap_delete_invs` 的形状（前件 `invs and emptyable ptr`、
后件 `λrv. invs`）正是第 16 章 `invariant f P` 的实例：
前件是 `invs` 加一条额外条件，后件把返回值丢掉、仍然是 `invs`。

## 17.7 模型比规范弱：环混得过去

17.4 明说了模型只取十条合取里的第一条。这一节把"少掉了什么"做成定理。
真实规范同一段定义的第 902 行有 `no_mloop`（CDT 无环），模型里没有：

<!-- 源码块：l4v/proof/invariant-abstract/Invariants_AI.thy 第 900--902 行 -->
```text
  "valid_mdb \<equiv> \<lambda>s. mdb_cte_at (swp (cte_wp_at ((\<noteq>) NullCap)) s) (cdt s) \<and>
                   untyped_mdb (cdt s) (caps_of_state s) \<and> descendants_inc (cdt s) (caps_of_state s) \<and>
                   no_mloop (cdt s) \<and> untyped_inc (cdt s) (caps_of_state s) \<and>
```

模型里把父亲关系写成集合，无环写成"`R^+` 里没有形如 `(x, x)` 的对"。
一个坑：`cslot_ptr` 本身就是二元组，所以量词要拆成"`cp` 的两半各是什么"
（用 `fst`/`snd`），否则 simplifier 的拆对规则 `split_paired_All`
会把 `∀sl. (sl, sl) ∉ R^+` 改成 `∀a b. ((a, b), a, b) ∉ R^+`，
从此**永远匹配不上**任何一条 `(p, p) ∈ R^+` 的正事实（实测）：

```text
theorem
  acyclicD:
    \<lbrakk>S17_invariants.acyclic ?s; (?c, ?p) \<in> (parent_rel ?s)\<^sup>+\<rbrakk> \<Longrightarrow> ?c \<noteq> ?p
```

```text
theorem
  local.acyclicI:
    (\<And>c p. (c, p) \<in> (parent_rel ?s)\<^sup>+ \<Longrightarrow> c \<noteq> p) \<Longrightarrow> S17_invariants.acyclic ?s
```

反例状态只有三行：对象表全空、每个槽都放 `NullCap`、两个槽互相认作父亲。
它满足本章的 `invs`（实测）：

```text
theorem cycle_state_has_invs: invs (cycle_state ?a ?b)
```

但它确实有环，而且是**两种**环里较隐蔽的那种（`a = b`，自己当自己父亲，
同样有环，所以下面几条都不需要 `a ≠ b`）（实测）：

```text
theorem
  cycle_state_edges:
    (?a, ?b) \<in> parent_rel (cycle_state ?a ?b) \<and>
    (?b, ?a) \<in> parent_rel (cycle_state ?a ?b)
```

```text
theorem cycle_state_loop: (?a, ?a) \<in> (parent_rel (cycle_state ?a ?b))\<^sup>+
```

```text
theorem
  cycle_state_not_acyclic: \<not> S17_invariants.acyclic (cycle_state ?a ?b)
```

合起来就是"本章模型严格弱于规范"这句话的定理形式（实测，
把 `?a`/`?b` 代入 `(0, 0)` 与 `(0, 1)` 就是一对**不同**的槽位）：

```text
theorem model_admits_cdt_cycles: \<exists>s. invs s \<and> \<not> S17_invariants.acyclic s
```

最后四条是这一节的实用结论，两种**不一样**的保持性（实测）：

```text
theorem
  parent_rel_insert: parent_rel (insert_cap ?cap ?ptr ?s) = parent_rel ?s
```

```text
theorem
  acyclic_insert_cap:
    S17_invariants.acyclic ?s \<Longrightarrow>
    S17_invariants.acyclic (insert_cap ?cap ?ptr ?s)
```

```text
theorem
  parent_rel_delete_subset: parent_rel (delete_cap ?ptr ?s) \<subseteq> parent_rel ?s
```

```text
theorem
  acyclic_delete_cap:
    S17_invariants.acyclic ?s \<Longrightarrow> S17_invariants.acyclic (delete_cap ?ptr ?s)
```

`insert_cap` 根本不碰 CDT（第一条证明只有定义），无环是白送的；
`delete_cap` 碰了——摘掉自己那条出边——但删边只让父亲关系**变小**，
而"无环"对取子集封闭（第二条加 `trancl_mono_subset`），所以也白送。

白送是模型的便宜，不是规范的便宜。真实证明里 `no_mloop` 从来不是这么过的：
第 05、06 章的 revoke、delete、retype 都会**加**边，而加边恰恰是可能造出环的那一步，
所以每一个改 CDT 的操作都得单独重证一次无环（l4v 里那批 `no_mloop` 引理）。
这就是"加一条不变式，全树跟着重证一遍"的成本；
本章模型之所以躲掉这笔账，是因为它的两个操作压根不往 CDT 上加边——
这一句本身就是 17.4 那句"模型只取十条合取里的第一条"的具体代价。

## 17.8 crunch 是流水线：官方文档里的三条与代码里的一个例子

前面七节手工证了"某操作保住某不变式"。真实会话里这种引理有几千条，
全部手写不可能——`invariant-abstract` 靠的是 **crunch**：一条命令生成一批
"`f` 保住 `P`"形状的引理。这一节讲三件官方文档说清楚、而本章前面没讲的事：
crunch 为什么会不够用（以及补它的那类引理叫什么）、规则怎么再生、
以及为什么重复子目标本身就是信号。

**1. crunch 的天花板，和补它的"提升引理"。**
官方那份去重文档里有一段专门讲这个（`l4v/docs/de-duplicating-proofs.md:238-249`）：

<!-- 源码块：l4v/docs/de-duplicating-proofs.md:238-249 -->
```text
## Lifting Rules and Locales

In our Hoare logic proofs we have a lot of invariants which only discuss
an isolated part of the state, and functions which similarly only modify
a small part of the state. Usually *crunch* can trivially show that a
given invariant is preserved by a function if they depend on different
fields of the *state* record. Often, however, both depend on the `kheap`
(kernel heap) and thus their independence is not as obvious. If you have
a function that only involves TCBs and a collection of invariants that
only discuss page tables, it might be worth writing a *lifting lemma* to
prove an abstract property that would show that your given invariants
are preserved by your function.
```

关键词是 `kheap`：只要不变式和函数都碰它，crunch 看字段独立性就看不出来了。
文档开的方子是**先证一条抽象性质**再搬回来——这类引理官方叫 lifting lemma。
它在代码里有个非常具体的样子，`l4v/proof/invariant-abstract/Invariants_AI.thy`
第 155 行的注释（`crunch` 这个词就在那一行）说的正是同一件事：

<!-- 源码块：l4v/proof/invariant-abstract/Invariants_AI.thy:153-157 -->
```text
(*
  'itcb' is a projection of the "mostly preserved" fields of 'tcb'. Many
  functions in the spec will leave these fields of a TCB unchanged. The 'crunch'
  tool is easily able to ascertain this from the types of the fields.

```

这段注释下面就是它的实现：把"大多数字段不被碰"这件事做成一个投影记录
`itcb`（同文件第 170 行的 `record itcb`），再让断言谓词
`pred_tcb_at`（第 224 行）吃"投影 + 性质"两个参数。
于是 17.6 那类 `st_tcb_at` 保持性变成一条更一般定理的实例——
注释最后一句写得很直白："We get \"for free\" that 'st_tcb_at P t' is also preserved"。
本章 17.4 那条 `valid_mdb` 与 17.5 那条 `cap_delete_invs` 之间缺的就是这一层：
不写"这个函数保住线程状态"，而写"这个函数保住 `itcb` 的任意投影"，
然后所有具体状态性质一起到手。crunch 命令本身在
`l4v/lib/Crunch.thy:12`（`crunch` 与 `crunch_ignore` 是注册的两个关键词），
同文件另外三行注册了它取用的命名定理集。ML 侧按名字把它们查出来：第 17 行的
`crunch_param_rules`（带参数的规则）在 `l4v/lib/crunch-cmd.ML` 第 339 行读出，
第 15 行的 `crunch_def`（要展开的定义）在第 343 行，第 16 行的 `crunch_rules`
（每次调用追加的重写规则）在第 882 行。
一条真实样本，`crunch` 命令在
`l4v/proof/invariant-abstract/CSpaceInv_AI.thy` 第 94 行：

<!-- 源码块：l4v/proof/invariant-abstract/CSpaceInv_AI.thy:94-96 -->
```text
crunch get_cap
  for inv[wp]: "P"
  (simp: crunch_simps)
```

这条样本还顺手解掉一个和第 16 章表面的冲突。16.8 说
"`function_inv` 那一族通常不许挂 `[wp]`"，而这里 crunch 生成的规则
形状是"前条件是一个没写死的性质、后条件把它原样搬过去"，
却明明白白标着 `[wp]`。差别只有一个：那里的性质是**特征变元**，
`wp` 用它倒推时只会把这个变元原样搬到义务位；
16.8 那句禁令针对的是性质已经写成 `invs`、`valid_objs` 这类具体谓词的
引理——那种规则会把目标的后条件换成一条固定的大不变式，于是证不动。**看名字认形状，看 `P` 是否 schematic 决定能不能挂**，
这条比任何口诀都耐用。

**2. 规则是再生出来的，不是抄第二遍。** 17.6 那组 `invs` 打包定理，
在真实会话里往往是一条一般引理的特殊化。官方给的标准套路
（`l4v/docs/de-duplicating-proofs.md:146-152`）值得整段记住：

<!-- 源码块：l4v/docs/de-duplicating-proofs.md:146-152 -->
```text
lemma f_invs_and_ct:
  "⦃λs. invs s ∧ Q (cur_thread s)⦄ f ⦃λr s. invs s ∧ Q (cur_thread s)⦄"
  ...

lemmas invs_True = f_invs_and_ct[where Q="λ_. True"] -- "⦃λs. invs s ∧ True⦄ f ⦃λr s. invs s ∧ True⦄"

lemmas invs = invs_True[simplified] -- "⦃invs⦄ f ⦃λr. invs⦄"
```

三步：证一条带参数 `Q` 的一般定理 → 用 `where Q="λ_. True"` 把参数钉死 →
用 `simplified` 把 `invs s ∧ True` 化回 `invs`。
紧接着那段解释了为什么值得这么绕：默认化简规则会把 `A ∧ True` 吃掉，
**产出的那条规则形状是干净的，所以 `wp` 认得它**——
第 16 章坑位 6 说的"挂 `[wp]` 会影响别处"在这里正好反过来用。
`l4v/docs/de-duplicating-proofs.md` 第 159--168 行也很诚实地给了止损线：
一条事实表达式套到
`OF _ _ _ _ my_final_fact[of "¬final_form",simplified], simplified]` 这种深度时，
"就该老老实实再写一条引理"。

**3. 同一个子目标出现两次，是模型在报警。** 不变式全是合取，
所以本章的证明里最容易撞上重复子目标。官方分两种病、给两味药。
药一（`l4v/docs/de-duplicating-proofs.md:185-189`）：

<!-- 源码块：l4v/docs/de-duplicating-proofs.md:185-189 -->
```text
lemma
  assumes AB: "A ∧ B"
  shows "A ∧ B ∧ A"
  apply (simp cong: conj_cong) -- "reduces the goal to "A ∧ B""
  by (rule AB)
```

自动化方法经常把同一个合取支塞好几份；`simp cong: conj_cong` 会把它压回去，
比多写一遍 `rule conjI` 稳。药二是"后一支的证明要用前一支"这种依赖
（`l4v/docs/de-duplicating-proofs.md:228-235`）：

<!-- 源码块：l4v/docs/de-duplicating-proofs.md:228-235 -->
```text
lemma
  assumes A: "X ⟹ A"
  assumes B: "A ⟹ B"
  shows "X ⟹ A ∧ B"
  apply (rule context_conjI)
   apply (erule A)
  apply (erule B) -- "A is assumed"
  done
```

`context_conjI` 把已经证出的那一半送回假设位。17.5 里"先证槽位可空、
再用它保住 `valid_mdb`"这类两半互相引用的不变式，用普通 `intro` 就得重证一遍。

**4. 最后是给维护者留活路的那几条。** 不变式会话是全仓库最大的，
读它的人最多，所以官方那份样式指南在"General Principles"之后立刻列了一小节
"To not drive proof maintainers insane"（`l4v/docs/Style.thy:55-67`）：

<!-- 源码块：l4v/docs/Style.thy:55-67 -->
```text
text \<open>
  To not drive proof maintainers insane:

    * Do not use `auto` except at the end of a proof, see [1].

    * Never check in proofs containing `back`.

    * Instantiate bound variables in preference to leaving schematics in a subgoal
      (i.e. use erule_tac ... allE in preference to erule allE)

    * Explicitly name variables that the proof text refers to (e.g. with rename_tac)

    * Don't mix object and meta logic in a lemma statement.\<close>
```

`l4v/docs/Style.thy` 第 58 行那条 `auto` 与第 60 行那条 `back`
是本章最相关的：`invs` 这类合取链上，`auto` 会顺手挑走它想当然的那条消去规则，
几个月后一条无关的 `simp` 改动就能让它翻车；`back` 更是直接把一次性的
不确定选择写进仓库。17.6 那条三层展开的 `invs_valid_objs` 就是反面教材的另一半——
它之所以还能读，是因为证明只有一行 `by simp`。

官方那份去重文档开头引了 Fowler 的"三次法则"，把它当作整份文档的度量
（`l4v/docs/de-duplicating-proofs.md:67-72`）：

<!-- 源码块：l4v/docs/de-duplicating-proofs.md:67-72 -->
```text
> The first time you do something you just do it. The second time you do
> something similar, you wince at the duplication, but you do the
> duplicate thing anyway. The third time you do something similar, you
> refactor.
>
> *-Martin Fowler, Refactoring: Improving the Design of Existing Code*
```

对读规范的人，这条同样成立：**同一条不变式你手工证到第三遍，
就说明缺一条 crunch 认得的引理或者一个 lifting lemma**，
而不是缺耐心。

---

## 官方教程对照

第 16 章末尾那张表列的是全仓库共享的规范侧文档地图（`l4v/docs/`），
这里只列本章直接用的那几篇，以及本教程与官方口径的差异。

| 官方文档 | 覆盖本章哪一段 | 本教程的处理 |
|---|---|---|
| `l4v/docs/de-duplicating-proofs.md` | 提升引理、`simplified` 再生、重复子目标 | 17.8，坑位 13--15 |
| `l4v/docs/Style.thy` | 什么 tactic 不许提交 | 17.8 第 4 条 |
| `l4v/docs/conventions.md` | `invs` / `invs'` 这类属性命名 | 下面第 2 条 |
| `l4v/docs/haskell-assertions.md` | 不变式怎么"搬"到 Haskell 与 C | 下面第 3 条，第 18/19 章 |
| `l4v/docs/arch-split.md` | 每份不变式要按架构跑几遍 | 第 20 章 20.11 |

**1. "主不变式只是一条 `and` 链"有官方出处。** 17.1 的形状
（`invs ≡ … and … and …`）不是本教程的简化：官方去重文档里那条示例引理
（`l4v/docs/de-duplicating-proofs.md:147`）写的就是
`⦃λs. invs s ∧ Q (cur_thread s)⦄ f ⦃λr s. invs s ∧ Q (cur_thread s)⦄`
这种"不变式 + 一个小性质"的合取形状，
17.8 第 2 条把它整套流程接上了。

**2. 抽象层与设计层的不变式靠撇号区分，命名有明文规定。**
`l4v/docs/conventions.md:94-96` 那一节写死了这件事：
属性名两边都用 `underscore_case`，但设计层可能与抽象层重名时
**加一撇**，例子正是 `invs'` 与 `valid_objs'`。
也就是说第 18 章会看到的 `invs'` 不是随手写的名字，
而是"这是设计层的同名不变式"这一份声明。同理，抽象层的常量用
`underscore_case`、Haskell 与设计层用 `CamelCase`
（第 84--89 行），违反直觉但是官方约定。

**3. 本章证的东西在下一层不重证，靠断言运下去。**
17.6 结尾说过"打包成 `invs` 是给上面用的"。官方对这件事有一页专门论述
（`l4v/docs/haskell-assertions.md`），核心是那份 tl;dr 的第 16--20 行：
在 Haskell 里写一条 `assert P'`，只要能从抽象侧的 `P` 配上状态关系推出 `P'`，
`CRefine` 就能白拿 `P'`。第 62--68 行给出的理由很实在：
"我们不在 C 层证任何不变式，那太痛了"，
而在 Haskell 层重证一遍与抽象规范等价的不变式是**重复劳动**，
所以现在倾向于用 `assert` 把信息运下去、再回 `Refine` 补那一笔。
本章 17.7 那条"模型比规范弱"因此不是纯理论问题：
往下运的每一条性质都得在精化会话里还一次账。

---

## 本章坑位清单（实测）

1. **把 `invs` 当单一谓词展开**：它是合取链，展开后子目标翻倍；用现成的 `invsD_*` / `[elim!]` 规则取支。
2. **不知道 `and` 有两个版本**：`Fun_Pred_Syntax.thy` 是 `infixl`，`Separation_Algebra.thy` 是 `infixr`，结合方向相反。
3. **以为"对象存在"与"类型匹配"可以分开保**：`valid_objs` 经由 `valid_obj` 的分支同时要求，一个坏能力就推翻全局。
4. **插入能力时忘了带类型前提**：`insert_cap_needs_object` 的前件不是装饰；真实代码靠 `default_cap` 从类型算出能力。
5. **只查 CDT 一端的非空**：`valid_mdbD` 与 `valid_mdbD_child` 是两条引理，缺一边就有 17.5 那个反例。
6. **以为删父亲槽是安全的**：`delete_parent_cap_breaks_valid_mdb`——被摘的边是**自己**的出边，别人的入边还在。
7. **不查 `emptyable` 就 `cap_delete`**：`cap_delete_invs` 的前件是 `invs and emptyable ptr`，少一半就没规则可用。
8. **三层展开才发现子不变式挂在哪**：`invs_valid_objs` 的证明同时用到 `invs_def`、`valid_state_def`、`valid_pspace_def`。
9. **对 `mdb_cte_at`/`swp` 想当然**：它们来自 AbsSpec 会话，不在这份代码树里，别猜定义。
10. **把 `∀sl. (sl, sl) ∉ R^+` 直接交给 `auto`**：`split_paired_All` 会把它改成永远匹配不上的形状；写成 `∀cp ∈ R^+. fst cp ≠ snd cp`。
11. **在 `^+` 与 `^++` 之间随手换**：前者是集合关系（`trancl`），后者是谓词（`tranclp`），类型不同。
12. **以为模型的白送等于规范的白送**：本章两个操作不加 CDT 边，所以躲掉了 `no_mloop` 的重证；真实操作加边，每一处都得重证。
13. **以为 crunch 什么保持性都能证**：不变式和函数都碰 `kheap` 时它的字段独立性看不出来，官方给的是先证一条 lifting lemma（`l4v/docs/de-duplicating-proofs.md` 的 "Lifting Rules and Locales" 一节）；`Invariants_AI.thy` 里那组 `itcb` 投影就是现成的例子。
14. **手抄一条只换了参数的引理**：把参数钉成 `λ_. True` 再 `simplified`，再生出来的形状 `wp` 才认得；反过来，fact expression 套到第四层就该新写一条引理而不是继续绕（`l4v/docs/de-duplicating-proofs.md`）。
15. **看见同一个子目标出现两次就复制证明脚本**：重复合取支用 `simp cong: conj_cong` 压回去，后一半要用前一半用 `context_conjI`——两种病两味药，别开第三张方子。

---

上一章：[16 · 霍尔逻辑与 wp](16-hoare-wp.md) ｜ 下一章：[18 · 精化关系](18-corres.md) ｜ 返回：[README](../README.md)
