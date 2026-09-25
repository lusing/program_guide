# 05 · 能力派生树（CDT）

对应示例：`../examples/S05_cdt.thy`

## 5.1 CDT：能力派生树

只有"权利会衰减"还不够。设想：root 把能力给了 A，A 给了 B，B 给了 C。
现在 root 想收回——它必须能一次收回 A、B、C 三份，否则"收回"就是一句空话。

seL4 的办法是维护一棵 **CDT（Capability Derivation Tree）**：
每次派生（mint/copy）都在树里加一条边"新槽的父是老槽"，于是"收回"就是"删掉整棵子树"。
类型本身就是一张部分函数（`l4v/spec/abstract/Structures_A.thy:532`）：

<!-- 源码块：l4v/spec/abstract/Structures_A.thy:532-532 -->
```text
type_synonym cdt = "cslot_ptr \<Rightarrow> cslot_ptr option"
```

读它的工具函数在 `l4v/spec/abstract/CSpaceAcc_A.thy`：`is_cdt_parent`（第 109 行）、
`cdt_parent_rel`（第 113 行）、`descendants_of`（第 144 行）。

## 5.2 父亲、子孙与传递闭包

```text
theorem
  parent_is_ancestor: is_cdt_parent ?t ?p ?c \<Longrightarrow> ?c \<in> descendants_of ?p ?t
```

`descendants_of p t = {q. (p,q) ∈ (cdt_parent_rel t)⁺}`——注意是**传递闭包** `⁺`，
不是直接儿子。这一个符号之差，决定了"收回"能不能连带孙辈。

## 5.3 派生：derive_cap

派生是唯一能造出新能力的动作，而它对某些能力直接说不（实测）：

```text
theorem
  derive_untyped_needs_no_children:
    descendants_of ?slot ?t \<noteq> {} \<Longrightarrow>
    derive_cap ?t ?slot (UntypedCap ?p ?sz ?f) = DeriveFailed
```

真实代码是 `l4v/spec/abstract/CSpace_A.thy:106` 的 `derive_cap`：

<!-- 源码块：l4v/spec/abstract/CSpace_A.thy:110-110 -->
```text
    | UntypedCap dev ptr sz f \<Rightarrow> doE ensure_no_children slot; returnOk cap odE
```

`ensure_no_children`（同文件第 67 行）在"有谁的父亲是这个槽"时
`throwError RevokeFirst`。**为什么只管 Untyped**：其它能力的副本与原件互不干扰，
而一个带子孙的 Untyped 能力如果还能被复制出去，那些子对象就会同时挂在两个
Untyped 能力下面——撤销其中一个无法说清该删谁。
注意这条限制发生在**复制/转授**路径上，不发生在 retype 路径上：
带子孙的 Untyped 照样可以继续 retype（第 15 章讲它与时水位的关系）。

## 5.4 mint / copy / move：三种"搬能力"的方式

`mint` 派生时可以顺便削权，`copy` 原样复制，`move` 搬走原槽。
三者的共同点是不增权（实测）：

```text
theorem
  mint_never_grows:
    mint ?t ?slot ?c ?R = Derived ?c' \<Longrightarrow>
    cap_rights_of ?c' \<subseteq> cap_rights_of ?c
```

`mint` = "先掩码再派生"，所以它的不增长性是第 03 章 `mask_never_grows`
与 `derive_never_grows_rights` 的复合：两步包含 + 传递。

真实代码里这三条走的是同一个解码函数 `decode_cnode_invocation`
（`l4v/spec/abstract/Decode_A.thy:46`），
顺序是"解码 rights → `mask_cap` → `derive_cap` → 插入"（第 82–87 行）：

<!-- 源码块：l4v/spec/abstract/Decode_A.thy:82-83 -->
```text
    src_cap \<leftarrow> returnOk $ mask_cap rights src_cap;
    new_cap \<leftarrow> (if is_move then returnOk else derive_cap src_slot) (case cap_data of
```

差别只在参数：`CNodeCopy` 只带 rights 字；`CNodeMint` 带 rights + capData（可打 badge）；
`CNodeMove` / `CNodeMutate` 是 `is_move = True`，rights 直接取 `all_rights`（移动不削权），
而且**跳过 `derive_cap`**——所以"Untyped 有子孙不能被派生"那条限制对 move 不成立，
move 本来就不复制任何东西。最后还有一道 `whenE (new_cap = NullCap) $ throwError IllegalOperation`：
派生成 `NullCap` 的能力（Reply、Zombie、IRQControl）不能搬。

## 5.5 插入时谁当父亲：should_be_parent_of

```text
theorem
  not_original_never_parent:
    \<not> ?src_orig \<Longrightarrow> \<not> should_be_parent_of ?src ?src_orig ?new ?new_orig
```

只要源能力自己是"复制品"（`original = False`），它就不会成为别人的父节点。
这条保证了 CDT 里"源头"唯一，撤销时不会漏。
真实定义在 `l4v/spec/abstract/CSpace_A.thy:724` 的 `should_be_parent_of`。配套的
`is_cap_revocable`（同文件第 740 行）判断"新能力算不算对象的原始能力"——
带 badge 的端点能力、IRQHandler、Untyped 是例外，它们即便从别处派生来也仍被视为源头。
`"original"` 位存在状态字段 `is_original_cap` 里（`l4v/spec/abstract/Structures_A.thy:573`），
不是能力类型自带的字段。

## 5.6 插入能力与 CDT 的单调性

```text
theorem
  descendants_mono:
    ?t ?p = None \<Longrightarrow> descendants_of ?x ?t \<subseteq> descendants_of ?x (?t(?p \<mapsto> ?q))
```

往空位加一条边，子孙集合只会变大（前提是那个位置原本没有边）。
真实内核里对应的操作是 `l4v/spec/abstract/CSpace_A.thy` 的
`cap_insert`（第 762 行）、`cap_move`（第 370 行）、`cap_swap`（第 344 行），
三者都会同步改 CDT，并各自带一个 `*_ext` 侧条件（如 `cap_insert_ext`）。

## 5.7 同一个概念，三份实现：CDT 在设计层和 C 代码里根本不存在

5.1 到 5.6 一直在讲"CDT 是一张父映射表"。这是**抽象规范**的写法，不是内核的写法。
把三层的真实形状摆在一起，是本章最值得记住的一件事。

### 1. 抽象规范：一张父映射表 + 一条大不变式

抽象层的 `cdt` 就是 5.1 那个类型。仓库自带的词汇表给出的正式定义是
（这个理论挂在 `l4v/spec/ROOT` 第 41 行的 `ASpec` 会话里，而该会话第 31 行开了
`document=pdf`，所以它是会随规范一起出文档的少数几处解释之一）：

<!-- 源码块：l4v/spec/abstract/Glossary_Doc.thy:100-109 -->
```text
\glossaryentry
  {cdt}
  {Capability Derivation Tree. A kernel-internal data structure that
  tracks the child/parent relationship between capabilities. Capabilities
  to new objects are children of the Untyped capability the object was
  created from. Capabilities can also be copied; in this case the user may
  specify if the operation should produce children or siblings of
  the source capability. The revoke operation will delete all children
  of the invoked capability.}
  {}
```

"revoke 删掉所有子孙"这句话就是 5.2 那条传递闭包存在的理由。
而这张表**不是随便填的**。`l4v/proof/invariant-abstract/Invariants_AI.thy`
第 997--1001 行把 `valid_mdb` 放进 `valid_state`，第 1034--1035 行再把
`valid_state` 放进 `invs`，于是下面这一整串就成了每步执行都要保持的东西：

<!-- 源码块：l4v/proof/invariant-abstract/Invariants_AI.thy:899-907 -->
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

`valid_mdb` 里最要紧的两个名词在同一文件第 860--867 行定义：

<!-- 源码块：l4v/proof/invariant-abstract/Invariants_AI.thy:860-867 -->
```text
definition
  "has_reply_cap t s \<equiv> \<exists>p. cte_wp_at (is_reply_cap_to t) p s"

definition
  "mdb_cte_at ct_at m \<equiv> \<forall>p c. m c = Some p \<longrightarrow> ct_at p \<and> ct_at c"

definition
  "no_mloop m \<equiv> \<forall>p. \<not> m \<Turnstile> p \<rightarrow> p"
```

`mdb_cte_at` 说的是"父边两端都必须是真实存在的槽"；
`no_mloop` 说的是"没有槽是自己的子孙"——后一种说法在
`l4v/proof/invariant-abstract/Deterministic_AI.thy` 第 700 行被写成等式
`no_mloop m = (\<forall>x. x \<notin> descendants_of x m)`。
另外注意 `valid_mdb` 里有三项带 `is_original_cap`：
**能不能撤销，取决于这个能力是不是源头**，这正是 5.5 那条 `original` 位的用处。

### 2. 设计层：没有 `cdt` 这个字段，只有一条链表

设计（可执行）规范里，每个 CTE 结点带的是 `mdbPrev`/`mdbNext`，
同一个父结点的孩子串成一条链表。于是"子孙"要靠归纳谓词来定义：

<!-- 源码块：l4v/proof/refine/Invariants_H.thy:567-580 -->
```text
inductive
  subtree :: "cte_heap \<Rightarrow> machine_word \<Rightarrow> machine_word \<Rightarrow> bool" ("_ \<turnstile> _ \<rightarrow> _" [60,0,60] 61)
  for s :: cte_heap and c :: machine_word
where
  direct_parent:
  "\<lbrakk> s \<turnstile> c \<leadsto> c'; c' \<noteq> 0; s \<turnstile> c parentOf c'\<rbrakk> \<Longrightarrow> s \<turnstile> c \<rightarrow> c'"
 |
  trans_parent:
  "\<lbrakk> s \<turnstile> c \<rightarrow> c'; s \<turnstile> c' \<leadsto> c''; c'' \<noteq> 0; s \<turnstile> c parentOf c'' \<rbrakk> \<Longrightarrow> s \<turnstile> c \<rightarrow> c''"

end

definition
  "descendants_of' c s \<equiv> {c'. s \<turnstile> c \<rightarrow> c'}"
```

`s ⊢ c → c'` 这个谓词写作 `subtree`，它是一步 `parentOf` 走出来的，
而 `parentOf`（同文件第 556--560 行）读的就是链表字段：

<!-- 源码块：l4v/proof/refine/Invariants_H.thy:556-560 -->
```text
definition
  parentOf :: "cte_heap \<Rightarrow> machine_word \<Rightarrow> machine_word \<Rightarrow> bool" ("_ \<turnstile> _ parentOf _" [60,0,60] 61)
where
  "s \<turnstile> c' parentOf c \<equiv>
  \<exists>cte' cte. s c = Some cte \<and> s c' = Some cte' \<and> isMDBParentOf cte' cte"
```

设计层那条和 `valid_mdb` 位置相当的不变式，名字几乎一样，只是全部拼在链表上：

<!-- 源码块：l4v/proof/refine/Invariants_H.thy:636-645 -->
```text
definition
  valid_mdb_ctes :: "cte_heap \<Rightarrow> bool"
where
  "valid_mdb_ctes \<equiv> \<lambda>m. valid_dlist m \<and> no_0 m \<and> mdb_chain_0 m \<and>
                        valid_badges m \<and> caps_contained' m \<and>
                        mdb_chunked m \<and> untyped_mdb' m \<and>
                        untyped_inc' m \<and> valid_nullcaps m \<and>
                        ut_revocable' m \<and> class_links m \<and> distinct_zombies m
                        \<and> irq_control m \<and> reply_masters_rvk_fb m"

```

`valid_dlist`、`mdb_chain_0` 这两项是抽象层那份里没有的——它们管的正是链表的形状。
把 1 和 2 这两份 `valid_*` 并排读，是理解"精化在数据层到底在证什么"的最快路径。

### 3. 精化关系量的不是"边"，是"子孙集合"

状态关系里那条 CDT 对应，写在 `l4v/proof/refine/StateRelation.thy` 第 222 行：

<!-- 源码块：l4v/proof/refine/StateRelation.thy:222-225 -->
```text
definition cdt_relation :: "(cslot_ptr \<Rightarrow> bool) \<Rightarrow> cdt \<Rightarrow> cte_heap \<Rightarrow> bool" where
  "cdt_relation \<equiv> \<lambda>cte_at m m'.
     \<forall>c. cte_at c \<longrightarrow> cte_map ` descendants_of c m = descendants_of' (cte_map c) m'"

```

它**没有**说"两边的父边一一对应"，而是说"抽象层某个槽的子孙集合，
经过 `cte_map` 搬到地址空间之后，等于设计层对应结点的子孙集合"。
这不是偷懒，是**只能这么写**：设计层的链表能区分兄弟顺序，
抽象层的父映射不能，两边唯一可比的就是集合。
同文件第 226 行另有一条 `cdt_list_relation` 把链表头指针也接上，
它在 `l4v/proof/refine/ADT_H.thy` 第 837 行被 `subgoal_tac` 现造出来用。

### 4. 想要抽象层那张表，就得从链表里重建

反方向（设计层 → 抽象层的 `cdt`）才是精化证明里真正干活的方向，
`l4v/proof/refine/ADT_H.thy` 第 517--531 行那段注释就是它的说明书：

<!-- 源码块：l4v/proof/refine/ADT_H.thy:517-531 -->
```text
text \<open>
  In the executable specification,
  a linked list connects all children of a certain node.
  More specifically, the predicate @{term "subtree h c c'"} holds iff
  the map @{term h} from addresses to CTEs contains capabilities
  at the addresses @{term c} and @{term c'} and
  the latter is a child of the former.

  In the abstract specification, the capability-derivation tree @{term "cdt s"}
  maps the address of each capability to the address of its immediate parent.

  The definition below takes a binary predicate @{term ds} as parameter,
  which represents a childhood relation like @{term "subtree h"},
  and converts this into an optional function to the immediate parent
  in the same format as @{term "cdt s"}.
```

重建靠两条定义：

<!-- 源码块：l4v/proof/refine/ADT_H.thy:533-543 -->
```text
definition
  "parent_of' ds \<equiv> \<lambda>x.
     if \<forall>p. \<not> ds p x
     then None
     else Some (THE p. ds p x \<and> (\<forall>q. ds p q \<and> ds q x \<longrightarrow> p = q))"

definition
  "absCDT cnp h \<equiv> \<lambda>(oref,cref).
     if cnp (cte_map (oref, cref)) = (oref, cref)
     then map_option cnp (parent_of' (subtree h) (cte_map (oref, cref)))
     else None"
```

`parent_of'` 里那个 `THE p` 是 HOL 的**限定描述符**：用它必须先证唯一性，
而唯一性恰好来自第 2 节那条 `valid_mdb'`。
整条重建的正确性是一整段证明的落点：

<!-- 源码块：l4v/proof/refine/ADT_H.thy:549-558 -->
```text
lemma absCDT_correct':
  assumes pspace_aligned: "pspace_aligned s"
  assumes pspace_distinct: "pspace_distinct s"
  assumes pspace_aligned': "pspace_aligned' s'"
  assumes pspace_distinct': "pspace_distinct' s'"
  assumes valid_objs: "valid_objs s"
  assumes valid_mdb:  "valid_mdb s"
  assumes rel:  "(s,s') \<in> state_relation"
  shows
    "absCDT (cteMap (gsCNodes s')) (ctes_of s') = cdt s" (is ?P)
```

七个假设（两侧内存对齐、互不重叠、`valid_objs`、`valid_mdb`、状态关系）
缺一个都推不出结论。**"CDT 是抽象层的记账工具，设计层必须靠不变式把它算出来"
这句话，形式化之后就是这一条引理。**

### 5. C 代码里搜不到 `cdt`

在 `seL4/src/` 与 `seL4/include/` 里搜 `cdt`，命中数是 **0**；
整个 `l4v/proof/crefine/` 会话里提到 `cdt` 的理论文件数也是 **0**。
C 侧留下的只有链表的物理版本——CTE 长这样：

<!-- 源码块：seL4/include/object/structures.h:148-153 -->
```text
/* Capability table entry (CTE) */
struct cte {
    cap_t cap;
    mdb_node_t cteMDBNode;
};
typedef struct cte cte_t;
```

`mdb_node_t` 里的 `mdbPrev`/`mdbNext` 由生成的位段访问器读写：
移动能力时改链的那一句是 `mdb_node_ptr_set_mdbNext`
（`seL4/src/object/cnode.c` 第 437 行）。
删除则是一圈迭代：`finaliseSlot` 的 while 循环（同文件第 622 行）
把槽里的能力反复降级，`reduceZombie`（第 664 行）按 zombie 记的编号逐个删子槽。
顺带一个跨层的小痕迹：这两条函数里写着
`/* Haskell error: "reduceZombie: expected unremovable zombie" */`——
C 代码在**指名设计层那条错误信息**，那是第 19 章逐函数对应的现场证据。

结论要说得准确：**不是"C 实现了 CDT"，而是"C 实现了一套行为，
其效果等于抽象层用 CDT 算出来的那套行为"**。
5.6 那条 `descendants_mono` 在 C 里没有对应物，它是证明侧的推理工具。

### 6. 第三份实现：capDL 工具里的用户态 CDT

capDL 的建模工具（Haskell 写的用户态程序，不是内核）也维护一张同形状的表：

<!-- 源码块：capdl/capDL-tool/CapDL/Model.hs:313-313 -->
```text
type CDT = Map CapRef CapRef
```

插入时它显式拒绝多父：

<!-- 源码块：capdl/capDL-tool/CapDL/MakeModel.hs:952-956 -->
```text
insertCDT :: CapRef -> CapRef -> CDT -> CDT
insertCDT child parent cdt =
    if isNothing (Map.lookup child cdt)
    then Map.insert child parent cdt
    else error $ show child ++ " has multiple parents"
```

而生成 C 初始化数据时，"这个槽在不在 CDT 里"直接就是那个 `is_orig` 位：

<!-- 源码块：capdl/capDL-tool/CapDL/PrintC.hs:222-225 -->
```text
    where
        index = fst x
        slot = showCap objs (snd x) irqNode is_orig ms
        is_orig = if Map.notMember (obj_id, index) cdt then "true" else "false"
```

和第 1 节 `valid_mdb` 里那三条带 `is_original_cap` 的合取项对照着看：
**同一个"是不是原件"的判断，在抽象规范里是不变式，在工具里是一行查表。**

---

## 官方教程对照

| 官方文档 / 文件 | 覆盖本章哪一段 | 本教程的处理 |
|---|---|---|
| `l4v/spec/abstract/Glossary_Doc.thy` | CDT 的正式定义（随 `ASpec` 出 PDF） | 5.7 第 1 条 |
| `capdl/capDL-tool/CapDL/Model.hs`、`MakeModel.hs`、`PrintC.hs` | 用户态工具里的第二份 CDT | 5.7 第 6 条 |
| `l4v/proof/invariant-abstract/Invariants_AI.thy` | `valid_mdb` 如何进入 `invs` | 5.7 第 1 条，第 11 章 |

**1. 本地文档镜像里没有 CDT 教程。** `docs/Tutorials/` 下这几页在镜像里是
占位文件；全仓库唯一给 CDT 下正式定义的地方是 l4v 树里的
`Glossary_Doc.thy`，所以本节的引用全部落在源码与 `capdl/` 工具里。

**2. 镜像里唯一讲 `revoke` 的教程类内容是 Microkit 手册**，
而它说的是被动保护域"初始化后撤销调度上下文再绑定"
（镜像里 `docs/projects/microkit/manual/2.3.1/index.md` 第 170 行那段 "Passive"），
和内核那个 `seL4_CNode_Revoke` **不是一回事**。查文档时别把两处混起来。

---

## 本章坑位清单（实测）

1. **把 CDT 的子孙当"直接儿子"**：`descendants_of`（`CSpaceAcc_A.thy:145`）用的是父边关系的传递闭包，收回要连孙辈一起。
2. **以为 mint 可以增权**：`mint` 内部先做掩码，不增长性要拆成"掩码 + 派生"两步证。
3. **以为 Untyped 有子孙时还能被复制/转授**：`derive_cap` 走 `ensure_no_children`，报的是 `RevokeFirst`（本模型抽象成 `DeriveFailed`）。注意限制在复制路径上，不在 retype 路径上。
4. **忽略 `original` 位**：源能力是复制品时不当父节点，漏掉会让撤销漏网。`original` 存在状态字段 `is_original_cap` 里，不是 cap 类型的字段。
5. **`descendants_mono` 忘了 `t p = None` 前提**：往已有边的位置覆盖，单调性不成立。
6. **传递闭包定理用错归纳规则**：`intro` 重复时报 `Ignoring duplicate unsafe introduction`，要用 `r_into_trancl` 之类的具体规则。
7. **把 CDT 当 CSpace**：CDT 只记派生关系（状态字段 `cdt`，`Structures_A.thy:572`），与"哪个槽里放着什么能力"（`kheap` 里的 `CNode` 对象）是两个结构。
8. **在证明里展开传递闭包**：`simp` 会无休止展开 `⁺`，要用引入/归纳规则。
9. **以为 copy 与 mint 只差名字**：`CNodeMint` 多一个 capData 参数（可打 badge）；`copy`/`mint` 会走 `derive_cap`，`move`/`mutate` 不走，且 rights 恒为 `all_rights`。
10. **忘了"空树"基线**：`descendants_of p (\<lambda>x. None) = {}`，很多归纳从这里起步。
11. **忘了搬能力时的 `NullCap` 检查**：派生成 `NullCap` 的东西（Reply/Zombie/IRQControl）根本不许插入，`decode_cnode_invocation` 会报 `IllegalOperation`。
12. **以为 C 代码里有一张 CDT**：内核源码里搜 `cdt` 是零命中，C 侧只有 `cteMDBNode` 里那对链表字段和 `reduceZombie` 那条循环。
13. **把 `cdt_relation` 读成"父边一一对应"**：它量的是两边**子孙集合**相等；设计层的兄弟顺序在抽象层没有对应物。
14. **用 `absCDT` 却不交假设**：`parent_of'` 里那个 `THE` 要靠 `valid_mdb` 才唯一，`absCDT_correct'` 那七条假设一条都不能少。

---

上一章：[04 · CSpace 与地址解析](04-cspace.md) ｜ 下一章：[06 · 回收与删除](06-revoke-delete.md) ｜ 返回：[README](../README.md)
