# 15 · 内存再类型化（Retype）

对应示例：`../examples/S15_retype.thy`

## 15.1 Untyped：内存的唯一来源

seL4 里所有内核对象都从 **Untyped 内存**里"改类型"（retype）长出来。
一个 Untyped 能力只记四件事：

<!-- 源码块：l4v/spec/abstract/Structures_A.thy:102-105 -->
```text
datatype cap
         = NullCap
         | UntypedCap bool obj_ref nat nat
           \<comment> \<open>device flag, pointer, size in bits (i.e. @{text "size = 2^bits"}) and freeIndex (i.e. @{text "freeRef = obj_ref + (freeIndex * 2^4)"})\<close>
```

依次是：是否设备内存、起始地址、**大小位数**（`obj_size` 就是 `1 << bits`，
同文件第 487 行）、以及 `freeIndex`。

最后这个**不是地址**，而是从基址起"已经用掉多少"的水位。
正反两个方向的换算写在一起：`get_free_ref` 与
`get_free_index`（`l4v/spec/abstract/Retype_A.thy` 第 127、132 行）：

<!-- 源码块：l4v/spec/abstract/Retype_A.thy:126-132 -->
```text
definition
  get_free_ref :: "obj_ref \<Rightarrow> nat \<Rightarrow> obj_ref" where
  "get_free_ref base free_index \<equiv> base +  (of_nat free_index)"

definition
  get_free_index :: "obj_ref \<Rightarrow> obj_ref \<Rightarrow> nat" where
  "get_free_index base free \<equiv> unat $ (free - base)"
```

注意 `get_free_ref` 只做**加法**：在这份抽象规范里，`freeIndex` 按字节数。
C 侧的位字段却不是——它按 `2^seL4_MinUntypedBits` 一块地数，
所以那个字段的最大值也要跟着减掉几个位数：

<!-- 源码块：seL4/include/object/untyped.h:19-25 -->
```text
 * capFreeIndex counts in chunks of size 2^seL4_MinUntypedBits. The seL4_MaxUntypedBits
 * is the minimal untyped that can be stored when considering both how
 * many bits of capBlockSize there are, and the largest offset that can
 * be stored in capFreeIndex */
#define MAX_FREE_INDEX(sizeBits) (BIT((sizeBits) - seL4_MinUntypedBits))
#define FREE_INDEX_TO_OFFSET(freeIndex) ((freeIndex)<<seL4_MinUntypedBits)
#define GET_FREE_REF(base,freeIndex) ((word_t)(((word_t)(base)) + FREE_INDEX_TO_OFFSET(freeIndex)))
```

第一段引文里那句注释（`l4v/spec/abstract/Structures_A.thy` 第 105 行）讲的是 C 的表示，
不是 `UntypedCap` 这个数据值的表示。同名不同单位，是这一章最容易踩的坑。

"用到头了"在规范里也有具体数值（`l4v/spec/abstract/CSpace_A.thy` 第 76 行）：

<!-- 源码块：l4v/spec/abstract/CSpace_A.thy:74-76 -->
```text
definition
  max_free_index :: "nat \<Rightarrow> nat" where
  "max_free_index magnitude_bits \<equiv> 2 ^ magnitude_bits"
```

模型（`../examples/S15_retype.thy`）就按这份规范来：

```text
consts
  max_free_index :: "nat \<Rightarrow> nat"
```

```text
theorem max_free_index_is_size: max_free_index (ut_bits ?u) = ut_size ?u
```

```text
theorem
  fully_used_means_watermark_at_end:
    fully_used ?u \<Longrightarrow> ut_base ?u + ut_free ?u = ut_end ?u
```

## 15.2 分配：水位前进，基址不动

分配一个对象 = 从水位处切一块，水位前进。规范里这是
`l4v/spec/abstract/Retype_A.thy` 的 `create_cap` / `retype_region`；
C 侧在 `seL4/src/object/untyped.c` 的 `decodeUntypedInvocation` 里算剩余字节
`untypedFreeBytes`（第 200 行）与对齐后的 `alignedFreeRef`（第 225 行），
水位本身存在能力字段里、上限由 `MAX_FREE_INDEX` 宏定（`seL4/include/object/untyped.h` 第 23 行）。
模型里的 `alloc_chunk` 抓住四条：

```text
theorem alloc_zero_rejected: alloc_chunk 0 ?u = None
```

```text
theorem
  alloc_beyond_end_rejected:
    ut_size ?u < ut_free ?u + ?n \<Longrightarrow> alloc_chunk ?n ?u = None
```

```text
theorem
  alloc_returns_free_pointer:
    alloc_chunk ?n ?u = Some (?p, ?u') \<Longrightarrow> ?p = ut_base ?u + ut_free ?u
```

```text
theorem
  alloc_advances_free_index:
    alloc_chunk ?n ?u = Some (?p, ?u') \<Longrightarrow> ut_free ?u' = ut_free ?u + ?n
```

零大小拒绝、越界拒绝、地址正好落在水位处、水位按分配量前进。
第二条约分两半记：判的是 `ut_free + n > ut_size`，
**先加后比**——只比 `n > ut_size` 会漏掉"水位已经过半"的情形。

## 15.3 分配出来的块互不重叠

```text
theorem
  chunks_do_not_overlap:
    \<lbrakk>alloc_chunk ?n ?u = Some (?p, ?u');
     alloc_chunk ?m ?u' = Some (?q, ?u'')\<rbrakk>
    \<Longrightarrow> ?p + ?n \<le> ?q
```

```text
theorem
  chunks_stay_inside:
    alloc_chunk ?n ?u = Some (?p, ?u') \<Longrightarrow> ?p + ?n \<le> ut_end ?u
```

连续两次分配，第二块的起点不早于第一块的终点；每块都不越过 `ut_end`。
**这就是"两个对象不会占同一块物理内存"**，
也是第 17 章 `pspace_distinct` 不变式的算术内核。
再加上"基址与位数都不动"这两条，`untyped` 记录里能被分配改掉的字段
就只有 `ut_free` 一个：

```text
theorem
  alloc_never_moves_base:
    alloc_chunk ?n ?u = Some (?p, ?u') \<Longrightarrow> ut_base ?u' = ut_base ?u
```

```text
theorem
  alloc_keeps_bits:
    alloc_chunk ?n ?u = Some (?p, ?u') \<Longrightarrow> ut_bits ?u' = ut_bits ?u
```

## 15.4 回收：水位能*倒退*，但是分块倒的

回收（把整块内存重新分配）要先删旧对象、再清零。
这件事在规范里叫 `reset_untyped_cap`
（`l4v/spec/abstract/Retype_A.thy` 第 143 行），
它把"回收"做成了**逐块**回退（第 149--167 行）：

<!-- 源码块：l4v/spec/abstract/Retype_A.thy:149-167 -->
```text
  if free_index_of cap = 0
    then returnOk ()
  else doE
    liftE $ delete_objects base sz;
  dev \<leftarrow> returnOk $ is_device_untyped_cap cap;

  if dev \<or> sz < resetChunkBits
      then liftE $ do
        unless dev $ do_machine_op $ clearMemory base (2 ^ sz);
        set_cap (UntypedCap dev base sz 0) src_slot
      od
    else mapME_x (\<lambda>i. doE
          liftE $ do_machine_op $ clearMemory (base + (of_nat i << resetChunkBits))
              (2 ^ resetChunkBits);
          liftE $ set_cap (UntypedCap dev base sz
              (i * 2 ^ resetChunkBits)) src_slot;
          preemption_point
        odE) (rev [i \<leftarrow> [0 ..< 2 ^ (sz - resetChunkBits)].
            i * 2 ^ resetChunkBits < free_index_of cap])
```

一次清完整块只发生在设备内存或小块上（比较的是**位数**
`sz < resetChunkBits`，不是字节数）；否则沿着那个被 `rev` 倒过来的下标表，
**从高位往低位**走，每轮清 `2 ^ resetChunkBits` 字节、
把 `freeIndex` 设成刚清完的位置、再插一个 `preemption_point`。
C 侧的同一个函数叫 `resetUntypedCap`，在
`seL4/src/object/untyped.c` 第 234 行，
分支在第 253 行，倒着走的 for 循环在第 259--267 行：

<!-- 源码块：seL4/src/object/untyped.c:253-268 -->
```text
    if (deviceMemory || block_size < chunk) {
        if (! deviceMemory) {
            clearMemory(regionBase, block_size);
        }
        srcSlot->cap = cap_untyped_cap_set_capFreeIndex(prev_cap, 0);
    } else {
        for (offset = ROUND_DOWN(offset - 1, chunk);
             offset != - BIT(chunk); offset -= BIT(chunk)) {
            clearMemory(GET_OFFSET_FREE_PTR(regionBase, offset), chunk);
            srcSlot->cap = cap_untyped_cap_set_capFreeIndex(prev_cap, OFFSET_TO_FREE_INDEX(offset));
            status = preemptionPoint();
            if (status != EXCEPTION_NONE) {
                return status;
            }
        }
    }
```

分块的理由是实时性：清零一整块 1GiB 的内存不能把系统锁在那里。
也正因为可以中途被抢占，`freeIndex` 必须**每一步**都停在合法位置上——
这就是"倒的是偏移、而且是一块一块倒"的原因。

模型把一个 chunk 抽象成字节数 `s`，`reset_steps s k u` 是走 `k` 步：

```text
consts
  reset_chunk :: "nat \<Rightarrow> untyped \<Rightarrow> untyped"
```

```text
consts
  reset_steps :: "nat \<Rightarrow> nat \<Rightarrow> untyped \<Rightarrow> untyped"
```

```text
theorem reset_chunk_never_grows: ut_free (reset_chunk ?c ?u) \<le> ut_free ?u
```

```text
theorem
  reset_chunk_of_zero_is_a_no_op: ut_free ?u = 0 \<Longrightarrow> reset_chunk ?s ?u = ?u
```

第二条就是第 149 行那句 `if free_index_of cap = 0 then returnOk ()`：
已经在水位起点上，"再清一块"是空转，能力一字未动。

```text
theorem
  reset_chunk_is_strict_progress:
    \<lbrakk>0 < ?s; 0 < ut_free ?u\<rbrakk> \<Longrightarrow> ut_free (reset_chunk ?s ?u) < ut_free ?u
```

```text
theorem
  reset_steps_reach_zero:
    ut_free ?u \<le> ?s * ?n \<Longrightarrow> ut_free (reset_steps ?s (Suc ?n) ?u) = 0
```

`reset_steps_reach_zero` 是那个 for 循环**有穷**的理由：
水位不超过 `s * n` 字节，最多 `n` 步就回到 0。
注意 `reset_chunk_is_strict_progress` 的两个前提都省不得——
`s = 0`（chunk 大小为零）时"每步严格变小"是**假命题**，
写成定理只能靠前提把它挡在外面。
另外两条"倒退不动别的字段"：

```text
theorem reset_steps_keeps_base: ut_base (reset_steps ?s ?k ?u) = ut_base ?u
```

```text
theorem reset_steps_keeps_bits: ut_bits (reset_steps ?s ?k ?u) = ut_bits ?u
```

整体回退之后，第一次分配一定落在基址上；
而**内存是否真的被清零**要看是不是设备内存——
寄存器不能被内核抹掉，那条分支只改能力：

```text
theorem
  alloc_right_after_reset_lands_on_base:
    \<lbrakk>0 < ?n; ?n \<le> ut_size ?u\<rbrakk>
    \<Longrightarrow> alloc_chunk ?n (?u\<lparr>ut_free := 0\<rparr>) =
       Some (ut_base ?u, ?u\<lparr>ut_free := ?n\<rparr>)
```

```text
theorem device_memory_is_not_cleared: \<not> snd (reset_untyped True ?u)
```

```text
theorem ram_is_cleared: ?dev = False \<Longrightarrow> snd (reset_untyped ?dev ?u)
```

## 15.5 有没有子孙，决定的是"能不能回退"

C 侧那段判定连着它的注释，在 `seL4/src/object/untyped.c` 第 171--189 行：

<!-- 源码块：seL4/src/object/untyped.c:171-189 -->
```text
    /*
     * Determine where in the Untyped region we should start allocating new
     * objects.
     *
     * If we have no children, we can start allocating from the beginning of
     * our untyped, regardless of what the "free" value in the cap states.
     * (This may happen if all of the objects beneath us got deleted).
     *
     * If we have children, we just keep allocating from the "free" value
     * recorded in the cap.
     */
    status = ensureNoChildren(slot);
    if (status != EXCEPTION_NONE) {
        freeIndex = cap_untyped_cap_get_capFreeIndex(cap);
        reset = false;
    } else {
        freeIndex = 0;
        reset = true;
    }
```

也就是说：**"有子孙"不阻止 retype，它只阻止回退**。
子孙还在，就沿用水位、不清零、从水位往后继续切；
子孙都删掉了，就可以从头再来——即使能力里记的水位不为 0。

`ensureNoChildren` 在规范里也有一个同名条目，但那是**另一道闸门**：
它挡的是**拷贝/传送**这个能力。规范里那个同名函数叫
`ensure_no_children`（`l4v/spec/abstract/CSpace_A.thy` 第 68 行），
被 `derive_cap`（同文件第 106 行）用在 `UntypedCap` 那一支（第 110 行）。

<!-- 源码块：l4v/spec/abstract/CSpace_A.thy:67-72 -->
```text
definition
  ensure_no_children :: "cslot_ptr \<Rightarrow> (unit,'z::state_ext) se_monad" where
  "ensure_no_children cslot_ptr \<equiv> doE
    cdt \<leftarrow> liftE $ gets cdt;
    whenE (\<exists>c. cdt c = Some cslot_ptr) (throwError RevokeFirst)
  odE"
```

<!-- 源码块：l4v/spec/abstract/CSpace_A.thy:107-110 -->
```text
"derive_cap slot cap \<equiv>
 case cap of
    ArchObjectCap c \<Rightarrow> arch_derive_cap c
    | UntypedCap dev ptr sz f \<Rightarrow> doE ensure_no_children slot; returnOk cap odE
```

第 05 章的 `derive_untyped_needs_no_children` 与本章这条是同一份规范代码，
两个视角：那章讲"能不能拷"，这章讲"能不能倒回去"。
模型里把 C 侧那个决定写成 `decode_retype_start`（返回"从哪儿开始切"和"要不要清零"）：

```text
theorem empty_means_no_children: ensure_no_children {}
```

```text
theorem child_blocks_children_free: \<not> ensure_no_children {?s}
```

```text
theorem no_children_restart_from_zero: decode_retype_start {} ?u = (0, True)
```

```text
theorem
  children_keep_the_watermark:
    \<not> ensure_no_children ?ds \<Longrightarrow>
    fst (decode_retype_start ?ds ?u) = ut_free ?u
```

```text
theorem
  children_forbid_reset:
    \<not> ensure_no_children ?ds \<Longrightarrow> \<not> snd (decode_retype_start ?ds ?u)
```

```text
theorem
  reset_flag_means_no_children:
    snd (decode_retype_start ?ds ?u) \<Longrightarrow> ensure_no_children ?ds
```

最后一条是反方向：`reset` 这个标志为真，就足以推出"没有子孙"——
它是那道 `if` 的等价改写，不是额外假设。
而"有子孙"时 retype 照样能干活（只要剩余空间够）：

```text
theorem
  retype_still_works_with_children:
    \<lbrakk>0 < ?n; ut_free ?u + ?n \<le> ut_size ?u\<rbrakk> \<Longrightarrow> alloc_chunk ?n ?u \<noteq> None
```

## 15.6 把 untyped 切成子 untyped 时，父亲被置为"满"

`l4v/spec/abstract/CSpace_A.thy` 第 95 行的 `set_untyped_cap_as_full`
由第 762 行的 `cap_insert` 在第 770 行调用：

<!-- 源码块：l4v/spec/abstract/CSpace_A.thy:97-100 -->
```text
  "set_untyped_cap_as_full src_cap new_cap src_slot \<equiv>
   if (is_untyped_cap src_cap \<and> is_untyped_cap new_cap
       \<and> obj_ref_of src_cap = obj_ref_of new_cap \<and> cap_bits_untyped src_cap = cap_bits_untyped new_cap)
       then set_cap (max_free_index_update src_cap) src_slot else return ()"
```

如果这次插入的**新**能力和 `src` 槽里的能力指向同一个 untyped 区域
（同基址、同位数），就把 `src` 那一份的 `freeIndex` 直接推到
`max_free_index`，也就是整块大小。直觉是：
这份内存已经被"分给子 untyped 了"，父能力再怎么留着也不该再切出新东西。

```text
theorem parent_becomes_fully_used: fully_used (set_parent_as_full ?p)
```

```text
theorem
  full_parent_allocates_nothing:
    0 < ?n \<Longrightarrow> alloc_chunk ?n (set_parent_as_full ?p) = None
```

```text
theorem
  full_is_the_only_state_that_allocates_nothing_of_any_size:
    fully_used ?p \<Longrightarrow> \<forall>n>0. alloc_chunk n ?p = None
```

```text
theorem
  making_a_parent_full_touches_nothing_else:
    ut_base (set_parent_as_full ?p) = ut_base ?p \<and>
    ut_bits (set_parent_as_full ?p) = ut_bits ?p
```

一句话总结本章：**内存的类型是"谁拥有这块物理内存"的唯一凭证**。
seL4 没有动态增长的内核堆，水位、清零、子孙关系三件事
就把"谁能在这块内存上放对象"说得死死的。

---

## 官方教程对照

官方 [untyped](https://docs.sel4.systems/Tutorials/untyped.html) 一页
（抓取日期 2026-09-25）的 TL;DR 是这么写的：
"objects should be allocated in order of size, largest first, to avoid wasting memory."
这句话在本章有一处代码级的理由，另有一处它没说的硬限制。下面按"官方页说了什么 →
内核实际做什么"排开。规范侧的那份（水位、回退、置满）见 15.1--15.6，
这里只讲 C。

**1. 一次 retype 的参数：七个签名、六个字、一份额外能力。**
`decodeUntypedInvocation`（`seL4/src/object/untyped.c:26`）
从消息寄存器按顺序读六个字：`newType`（`seL4/src/object/untyped.c:58`）到
`nodeWindow`（`seL4/src/object/untyped.c:63`），第七个参数 `root`
走的是 extra caps：`rootSlot`（`seL4/src/object/untyped.c:64`）。
所以 XML 里那个叫 `num_objects` 的参数（`seL4/libsel4/include/interfaces/object-api.xml:49`）
在内核里的名字叫 `nodeWindow`——**同一件事两个名字**，读代码时别找第三个。
截断判定看的是 `length`（`seL4/src/object/untyped.c:51`）与那份额外能力在不在。

**2. `size_bits` 只对三类对象有意义。** `getObjectSize`
（`seL4/src/object/objecttype.c:33`）里只有三支用到它：
`seL4_CapTableObject`（`seL4/src/object/objecttype.c:45--46`）返回
`seL4_SlotBits + userObjSize`、`seL4_UntypedObject`
（`seL4/src/object/objecttype.c:47--48`）与 MCS 的 `seL4_SchedContextObject`
（`seL4/src/object/objecttype.c:50--51`）原样返回。
其余类型（TCB、Endpoint、Notification、Reply）忽略它。
配套的下限检查各有分支：CNode 至少 1 格（`seL4/src/object/untyped.c:88`）、
子 untyped 至少 `seL4_MinUntypedBits`（`seL4/src/object/untyped.c:96`）、
调度上下文至少 `seL4_MinSchedContextBits`（`seL4/src/object/untyped.c:104`，MCS 才有）。
上下界本身是每 sel4_arch 的宏：aarch64 上
`seL4_MinUntypedBits` 是 4（`seL4/libsel4/sel4_arch_include/aarch64/sel4/sel4_arch/constants.h:224`）、
`seL4_MaxUntypedBits` 是 47（`seL4/libsel4/sel4_arch_include/aarch64/sel4/sel4_arch/constants.h:225`）。
官方页把 `size_bits` 讲成"所有对象都要传"，那是历史遗留（第 12 章对照第 2 条同）。

**3. "大的先来"的理由写在注释里。** 内核算完剩余字节
`untypedFreeBytes`（`seL4/src/object/untyped.c:200--203`）用的是**右移比较**
而不是乘法，注释接着说：如果放得下，就一定"对齐之后也放得下，
因为对象是贴着 untyped 右侧码放的"。真正的对齐在
`alignUp`（`seL4/src/object/untyped.c:225`）：**每切一个对象，先把水位向上对齐到
该对象的大小**。空洞就是这样产生的——先切一堆小的，再来一个大的，
中间那段对齐差就永久留在 untyped 里（水位只往前走）。
这就是 TL;DR 那句话的全部机制。

**4. 一次 retype 装多少，上限不是 API 那个宏。** 内核查的是
`CONFIG_RETYPE_FAN_OUT_LIMIT`（`seL4/src/object/untyped.c:144--151`），
libsel4 给用户的 `seL4_UntypedRetypeMaxObjects`
（`seL4/libsel4/include/sel4/types.h:26`）只是"KConfig 没定义时"的退路，
退回值是 256（同文件 `#else` 那一支）。
**以内核那个为准**：配置里改小了，报的 `seL4_RangeError`
（`seL4/src/object/untyped.c:147`）里的 max 就是它。

**5. 目标窗口是三条 RangeError，不是一条。** 起点不能越界（`nodeSize`（`seL4/src/object/untyped.c:135--136`）由目标 CNode 的 radix 算出）、
窗口大小要在 1 到 fan-out 上限之间（`seL4/src/object/untyped.c:144--151`）、
窗口不能盖过节点末尾（`nodeWindow`（`seL4/src/object/untyped.c:152--158`）加上偏移之后才比较）。
之后才是逐槽查空：`ensureEmptySlot`（`seL4/src/object/untyped.c:162--163`）
对窗口里每一格都跑一遍，任何一格非空就整条调用失败——
第 10 章"全有或全无"在内存分配这一侧的落点。
顺带修一处常见误解：`seL4_DeleteFirst`（`seL4/src/object/cnode.c:839`）
不是 retype 专属——`ensureEmptySlot`（`seL4/src/object/cnode.c:836`）就定义在
cnode.c，CNode 的三种派生操作都调它（`seL4/src/object/cnode.c:93` 是其中一处），
IRQ handler 安装与 x86 ioport 也调。

**6. 官方页没说的一条硬限制：设备内存不能装内核对象。**
`deviceMemory`（`seL4/src/object/untyped.c:214`）为真、而目标类型又不是
`Arch_isFrameType`（`seL4/src/object/untyped.c:215`）、又不是子 untyped 时，
直接 `seL4_InvalidArgument`（`seL4/src/object/untyped.c:218`）。
也就是说 boot info 里那些 `isDevice` 为真的 untyped 只能再切成
页/框架或者子 untyped，不能拿来造 TCB、CNode、端点。
15.4 那条"设备内存不清零"是回收侧的差别，这一条是分配侧的差别，两处独立。

**7. `nodeDepth == 0` 是条捷径。** `seL4/src/object/untyped.c:113--114`
在 `nodeDepth` 为 0 时**不做解析**，直接把 `rootSlot->cap` 当目标 CNode 用；
非 0 才走 `lookupTargetSlot`（`seL4/src/object/untyped.c:117`）。
第 04 章那套 guard/bits 解析在这里被一个 `if` 短路掉了。
目标不是 CNode（或者只读）时报的是 `seL4_FailedLookup`
（`seL4/src/object/untyped.c:126--131`），
同时把 `current_lookup_fault` 填成 `lookup_fault_missing_capability_new`
（`seL4/src/object/untyped.c:130`）——错误码与 fault 载荷一起写，
这是本章见过最"混合"的一条分支。

---

## 本章坑位清单（实测）

1. **把 `freeIndex` 当"剩余大小"**：它是**已用水位**（从基址起算的偏移），不是剩余量。
2. **以为 `freeIndex` 的单位是统一的**：`l4v` 规范里按字节（`get_free_ref` 只做加法），
   C 位字段里按 `2^seL4_MinUntypedBits` 一块（`FREE_INDEX_TO_OFFSET` 左移）。
3. **分配零大小**：`alloc_chunk 0 u = None`，被拒绝，不会返回空块。
4. **越界判断写成 `n > ut_size`**：正确判断是 `ut_free + n > ut_size`，先加后比。
5. **把 `ensureNoChildren` 失败读成"整个 retype 失败"**：它只把 `reset` 置为 `false`、
   沿用水位继续分配（`seL4/src/object/untyped.c` 第 182--189 行）。
6. **混用两处 `ensure_no_children`**：`CSpace_A.thy` 第 68 行那个被 `derive_cap`
   用来挡**拷贝**；C 侧 `ensureNoChildren` 管的是**回退**。
7. **以为水位一步清零**：大块是从高位往低位一块一块倒，中间夹 `preemption_point`；
   证明终止要写出"步数 ≥ 水位 / 块大小"这条算式（`reset_steps_reach_zero`）。
8. **在"每步严格变小"的定理里省掉 `0 < s`**：chunk 大小为 0 时那条命题是假的，
   Isabelle 会直接拒绝你。
9. **以为回收一定清零**：设备内存那条分支只改能力，不 `clearMemory`
   （`unless dev $ do_machine_op $ clearMemory …`）。
10. **整块清零的条件看字节数**：规范比的是位数 `sz < resetChunkBits`，
    C 侧比的是 `block_size < chunk`，两处都不是"剩余字节"。
11. **以为置满会改动别的字段**：`set_untyped_cap_as_full` 只推 `freeIndex`，
    基址与位数都不动。
12. **找实现找错文件**：`seL4/src/object/untyped.c` 与
    `seL4/include/object/untyped.h`（都在 `object/`，不在 `src/kernel/`）。
13. **以为 `seL4_UntypedRetypeMaxObjects` 就是内核的上限**：内核查的是
    `CONFIG_RETYPE_FAN_OUT_LIMIT`，前者只是退路（对照第 4 条）。
14. **以为设备 untyped 什么都能切**：非 frame、非子 untyped 一律 `InvalidArgument`。
15. **以为 `DeleteFirst` 是 retype 专属错误**：它来自"目标槽非空"这一条通用检查。

---

上一章：[14 · 调度](14-schedule.md) ｜ 下一章：[16 · 霍尔逻辑与 wp](16-hoare-wp.md) ｜ 返回：[README](../README.md)
