# 04 · CSpace 与地址解析

对应示例：`../examples/S04_cspace.thy`

## 4.1 CSpace：一张由 CNode 组成的图

用户说"我要用这个能力"时，给的不是地址，而是一串 **bit**。
内核拿这串位去一棵 CNode 树里走：每一级先用 guard 比对、再取 `bits` 位当索引、
余下的位交给下一级。这串位叫 `cnode_index`（`bool list`，
`l4v/spec/abstract/Structures_A.thy:84`），
配上对象引用就是 `cslot_ptr = obj_ref × cnode_index`（同文件第 85 行）。

真实的一条级解析（`l4v/spec/abstract/CSpace_A.thy:153`）长这样：

<!-- 源码块：l4v/spec/abstract/CSpace_A.thy:169-170 -->
```text
       offset \<leftarrow> returnOk $ take radix_bits (drop (size guard) cref);
       rest \<leftarrow> returnOk $ drop (radix_bits + size guard) cref;
```

三种失败要分清楚（同一个函数里，`CSpace_A.thy:163`、`:167`、`:181`）：
`guard` 不是路径前缀 → `GuardMismatch`；路径比这一级需要的位数还短 → `DepthMismatch`；
根能力压根不是 CNode → `InvalidRoot`。
真实定义见 `l4v/spec/abstract/CSpace_A.thy` 与 `l4v/spec/abstract/CSpaceAcc_A.thy`；
C 侧遍历在 `seL4/src/kernel/cspace.c`（`resolveAddressBits:126`、
`lookupSlotForCNodeOp:65`）。

## 4.2 一级解析

单步解析 `resolve_step` 只有两种结局：guard 对不上则 `None`，对上了则把路径切成"索引 + 余下"（实测）：

```text
theorem
  step_guard_mismatch:
    take (length ?guard) ?path \<noteq> ?guard \<Longrightarrow>
    resolve_step ?guard ?bits ?path = None
```

把三段拼回去，是本章最有用的定理：

```text
theorem
  step_splits_path:
    resolve_step ?guard ?bits ?path = Some (?idx, ?rest) \<Longrightarrow>
    ?guard @ ?idx @ ?rest = ?path
```

注意索引是**跳过 guard 之后**再取 `bits` 位，写成 `take bits path` 就把 guard 也算进索引了。

## 4.3 多级解析

`resolve` 沿路径一直走到叶子。这里有个真实的工程坑：
用 `function` 递归定义它，终止性证明**不会自动完成**——
剩余路径长度确实每层递减，但自动化方法跨不过
`radix_bits + size guard` 那段算术，而且要先排除 `radix_bits = 0 ∧ guard = []`
这个"吃不掉任何位"的退化情形，否则真的会原地打转。

l4v 作者的做法是先把这件事写成一条显式算术引理
（`l4v/spec/abstract/CSpace_A.thy:184` 的 `rab_termination`），再在 `termination`
证明里把 `measure (\<lambda>(z,cap,cs). size cs)` 喂进去（同文件第 197 行）。

本教程的解法是不证终止性，改加一个**燃料参数**，把递归深度显式变成结构递归（实测）：

```text
consts
  resolve_fuel ::
    "nat \<Rightarrow> cspace_state \<Rightarrow> cap \<Rightarrow> bool list \<Rightarrow> (nat \<times> bool list) option"

Found termination order: "(\<lambda>p. size (fst p)) <*mlex*> {}"
```

燃料让 `fun` 自己就找到了终止顺序（第一个参数递减），一句证明都不用写。
`resolve s cap path` 就是 `resolve_fuel (Suc (length path)) s cap path`。
真实内核不需要这一手，它的深度被 `word_bits` 天然限死
（`lookup_slot_for_cnode_op` 里 `whenE (depth < 1 \<or> depth > word_bits)` 直接报
`RangeError`，见 `CSpace_A.thy:238`）；
但模型里不显式给界，要么证不出终止性，要么证明跑几分钟不出结果。

## 4.4 叶子能力不能继续走，而"空路径"在真实内核里是非法的

不是 CNode 的东西不能继续往下走（实测）：

```text
theorem resolve_leaf_is_none: resolve ?s NullCap ?path = None
```

```text
theorem resolve_endpoint_is_none: resolve ?s (EndpointCap ?p) ?path = None
```

本模型另给了一个方便的 `lookup_slot`：路径为空就直接返回根槽。
**这一条与真实内核相反**，必须说清楚：`lookup_slot_for_cnode_op`
（`l4v/spec/abstract/CSpace_A.thy:238`）上来第一件事就是
`whenE (depth < 1 \<or> depth > word_bits) (throwError (RangeError 1 (of_nat word_bits)))`，
也就是 **depth = 0 一律拒绝**。空路径写在本模型里只是为了让"根槽"这个概念有名字，
别拿它当"seL4 允许用 0 深度引用根能力"。
把它和"解析失败"混为一谈是本章最常见的证明卡点。

## 4.5 井形 CNode：槽位索引长度必须一致

`well_formed_cnode_n`（`l4v/spec/abstract/Structures_A.thy:471`）是个**等式**，不是包含：

<!-- 源码块：l4v/spec/abstract/Structures_A.thy:472-472 -->
```text
 "well_formed_cnode_n n \<equiv> \<lambda>cs. dom cs = {x. length x = n}"
```

它要求"长度为 n 的索引每一个都有值"。插入一个长度不同的键——或者删掉一个键——
都会破坏井形性，后面所有关于解析与撤销的定理都会失效。
本模型用的是弱化版（只要求"有值的键长度都对"），见 `S04_cspace.thy` 的说明。

---

## 官方教程对照

官方 [capabilities](https://docs.sel4.systems/Tutorials/capabilities.html) 页
（抓取日期 2026-09-25）说："The initial CSpace consists of one CNode containing
capabilities to all resources managed by seL4"、"CNodeSizeBits defines the size
in bits of the initial CNode: 2^CNodeSizeBits slots"。两句话都对，
但名字和参数形状与 16.0.0 的真实 API 有出入，下面逐条钉住。

**1. `CNodeSizeBits` 的真名是 `initThreadCNodeSizeBits`。**
它在 `seL4/libsel4/include/sel4/bootinfo_types.h:69`，注释就写着
"initial thread's root CNode size (2^n slots)"。官方教程正文用的是文档里的口语名，
不是结构体字段名——照着教程写 `info->CNodeSizeBits` 编译不过。

**2. 初始 CNode 的槽位号是写死的枚举。** `seL4_RootCNodeCapSlots`
（`seL4/libsel4/include/sel4/bootinfo_types.h:14--32`）：`seL4_CapNull = 0`、
`seL4_CapInitThreadTCB = 1`、`seL4_CapInitThreadCNode = 2`、
`seL4_CapInitThreadVSpace = 3`、`seL4_CapIRQControl = 4`……
本章所有例子里那个"根槽 0 号"的说法要小心：**内核侧的根 CNode 是 2 号槽里的能力**，
0 号槽是 `NullCap`。官方教程的
`seL4_CNode_Copy(seL4_CapInitThreadCNode, 0, seL4_WordBits, …)`
第一个参数就是"拿 2 号槽里的 CNode 当本次调用的根"。

**3. 16.x 把 `CSpaceData` 拆成平铺参数了。** `CNodeCopy`
（`seL4/libsel4/include/interfaces/object-api.xml:962`）的参数依次是
`dest_index, dest_depth, src_root, src_index, src_depth, rights`，
其中 `src_root` 的说明原话是 "CPtr to the CNode that forms the root of the
source CSpace. **Must be at a depth equivalent to the wordsize.**"
——这句话就是"根必须按满字长解析"的官方口径，对应本章 4.2 节
"第一级没有 guard 可剩"。旧教程里那个打包结构体 `CSpaceData` 在本树 grep 为 0 命中。

**4. guard 的存在形式：CNode 能力自己的一个字。** `seL4_CNode_CapData`
（`seL4/libsel4/mode_include/32/sel4/shared_types.bf` 第 27--32 行）在 32 位下是
`padding 6` + `guard 18` + `guardSize 5` + `padding 3`；64 位
（`seL4/libsel4/mode_include/64/sel4/shared_types.bf`）是 `guard 58` + `guardSize 6`，
正好占满一个字。**`guardSize` 的位宽等于 `wordRadix`**（5 或 6），
也就是说"guard 有多长"这个元信息本身要占掉地址的一位宽度——
本章 4.5 的"槽位索引长度必须一致"在 C 侧不是检查项，是编码塞不下。

**5. 解析循环的真实函数是 `resolveAddressBits`。** 它在
`seL4/src/kernel/cspace.c:126`，签名 `resolveAddressBits(cap_t nodeCap, cptr_t capptr, word_t n_bits)`；
guard 比较与失败构造在 `seL4/src/kernel/cspace.c:156--160`：

```c
        guard = (capptr >> ((n_bits - guardBits) & MASK(wordRadix))) & MASK(guardBits);
        if (unlikely(guardBits > n_bits || guard != capGuard)) {
            current_lookup_fault =
                lookup_fault_guard_mismatch_new(capGuard, n_bits, guardBits);
```

`n_bits` 就是"还剩几位没消耗"，返回值结构里那个字段叫 `bitsRemaining`
（`seL4/include/kernel/cspace.h:42`）。**"消耗了多少位"在 C 里是一个显式的
剩余量，不是靠长度相等反推**——本章 4.3 的定理形状应当照这个来写。
外层入口是 `lookupCap` / `lookupCapAndSlot` / `lookupSlotForCNodeOp`
（`seL4/include/kernel/cspace.h:46--57`）。

> 顺带纠正一个常见误解：本树里**没有** `src/kernel/cnode.c`，
> CSpace 解析在 `src/kernel/cspace.c`，CNode 这个对象本身在
> `seL4/src/object/cnode.c`（revoke/delete 等调用在那儿，见第 06 章）。

---

## 本章坑位清单（实测）

1. **以为 `function` 的终止性会自动证出来**：l4v 自己都要先写一条算术引理（`CSpace_A.thy:184` 的 `rab_termination`）再喂给 `measure`；本教程改用燃料参数，`fun` 才会自己找到 `<*mlex*>` 顺序。
2. **guard 不匹配要返回 `None`**：返回"部分成功"会让后面所有调用方都要处理半截状态。真实规范里对应的是 `throwError $ GuardMismatch (size cref) guard`。
3. **路径拆分顺序写反**：是 `guard @ idx @ rest = path`。
4. **索引取错位置**：`idx = take bits (drop (length guard) path)`，漏掉 `drop` 就把 guard 当索引了。
5. **忽略 `well_formed_cnode_n`**：它是 `dom cs = {x. length x = n}` 这个**等式**，插入长度不同的键、或少一个键都会破；破了之后解析与撤销的定理全部失效。
6. **把"空路径"当解析失败、或反过来当合法**：真实内核两种都不是——`depth < 1` 直接 `RangeError`（CNode 操作），空 cref 走 `resolve_address_bits'` 则 `DepthMismatch`。本模型的 `lookup_slot s root []` 是模型便利，不是内核语义。
7. **`cnode_index` 是 `bool list` 不是 `nat`**：长度等于 `bits`，别用数字索引去算。
8. **`take`/`drop` 的 off-by-one**：`length guard + bits` 的算术要显式给出。
9. **模型里没有深度上界**：真实内核有 `word_bits` 兜底（`depth > word_bits` 报 `RangeError`），模型没有就必须显式加界。
10. **用 `fun` 定义多级解析时 pattern 重叠**：分支要按 cap 类型穷尽，漏一个报 `Missing patterns`。
11. **把三种解析失败混成一种"失败"**：`GuardMismatch` / `DepthMismatch` / `InvalidRoot` 的错误码和参数都不同（`CSpace_A.thy:163`、`167`、`181`），C 侧要按原样回给用户态。

---

上一章：[03 · 权利与掩码](03-rights.md) ｜ 下一章：[05 · 能力派生树](05-cdt.md) ｜ 返回：[README](../README.md)
