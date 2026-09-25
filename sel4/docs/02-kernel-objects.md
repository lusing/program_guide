# 02 · 内核对象与能力

对应示例：`../examples/S02_kernel_objects.thy`

## 2.1 内核对象：seL4 里只有"对象 + 能力"

两个容易混的概念，必须一开始就分开：

- **内核对象（kernel object）**：端点、通知、TCB、CNode、页表、Untyped 内存。看 `l4v/spec/abstract/Structures_A.thy` 的 `kernel_object` 与 `apiobject_type`。
- **能力（capability）**：指向某个对象的"钥匙"，带权利。

对象只有一个，指向它的能力可以有很多份，且每份的权利不同。
**销毁能力不等于销毁对象，销毁对象也不等于能力凭空消失**（后者变成 `NullCap`）。
这一条是第 06 章"回收"与第 15 章"再类型化"全部复杂度的来源。

## 2.2 能力的数据类型

`cap` 是一个大的和类型（`l4v/spec/abstract/Structures_A.thy:102`），十二个构造子里
只有四个带 `cap_rights` 字段：

<!-- 源码块：l4v/spec/abstract/Structures_A.thy:102-117 -->
```text
datatype cap
         = NullCap
         | UntypedCap bool obj_ref nat nat
           \<comment> \<open>device flag, pointer, size in bits (i.e. @{text "size = 2^bits"}) and freeIndex (i.e. @{text "freeRef = obj_ref + (freeIndex * 2^4)"})\<close>
         | EndpointCap obj_ref badge cap_rights
         | NotificationCap obj_ref badge cap_rights
         | ReplyCap obj_ref bool cap_rights
         | CNodeCap obj_ref nat "bool list"
           \<comment> \<open>CNode ptr, number of bits translated, guard\<close>
         | ThreadCap obj_ref
         | DomainCap
         | IRQControlCap
         | IRQHandlerCap irq
         | Zombie obj_ref "nat option" nat
           \<comment> \<open>@{text "cnode ptr * nat + tcb or cspace ptr"}\<close>
         | ArchObjectCap (the_arch_cap: arch_cap)
```

带权利的是 `EndpointCap`、`NotificationCap`、`ReplyCap` 和
`ArchObjectCap`（权利藏在 `acap_rights` 里）；
**`CNodeCap` 与 `ThreadCap` 不带权利字段**——CNode 能力的"权利"体现在它每个槽里的
能力上，TCB 能力靠调用类型本身把关。页/设备帧能力全在 `ArchObjectCap` 一支，
本教程第 2 章的模型（`examples/S02_kernel_objects.thy` 里的 `cap`）省掉了这一支——
11 个构造子对上面的 12 个，差的正是它。

> 由此产生一个真实陷阱：l4v 的 `cap_rights`（`l4v/spec/abstract/Structures_A.thy:210`）
> 写成 `primrec (nonexhaustive)`，
> 对不带 rights 字段的构造子**取值无约束**（`undefined`），
> 既不是 `UNIV` 也不是 `{}`。所以判断"这个能力有没有某权利"要看语义，
> 不能靠选择子的默认值；`mask_cap` 自己也不依赖这些缺失值——
> `cap_rights_update` 的最后一支 `_ ⇒ cap` 把它们原样返回了。

## 2.3 对象被创建时得到的"原始能力"

新对象被创建出来时，装进目标槽位的是一份**默认能力**（`default_cap`）。
默认权利表是内核的策略，不是"能给的都给"（实测）：

```text
theorem
  ep_default_has_all_rights:
    cap_rights_of (default_cap EndpointObject ?p ?sz) = UNIV
```

```text
theorem
  ntfn_default_cannot_grant:
    AllowGrant \<notin> cap_rights_of (default_cap NotificationObject ?p ?sz)
```

真实的两支（`l4v/spec/abstract/Retype_A.thy:36`）：

<!-- 源码块：l4v/spec/abstract/Retype_A.thy:36-38 -->
```text
| "default_cap EndpointObject oref s _ = EndpointCap oref 0 UNIV"
| "default_cap NotificationObject oref s _ =
     NotificationCap oref 0 {AllowRead, AllowWrite}"
```

端点默认给全部权利；通知默认只有 `AllowRead` + `AllowWrite`——
`AllowGrant` 和 `AllowGrantReply` 都不给（防止默认就把通知能力转送出去）。
还有两点容易看漏：`default_cap` 有**四个**参数（类型 / oref / size / device 标志），
签名在 `l4v/spec/abstract/Retype_A.thy:31`；Untyped 那一支把 device 标志原样存进能力。

另一处是 `create_cap`，它在装能力之前还会先 `set_original dest True`
并把 CDT 边挂到那个 Untyped 上（`l4v/spec/abstract/Retype_A.thy:43`）——
第 05 章的"谁是父节点"就发生在这里。

真实代码见 `l4v/spec/abstract/Retype_A.thy` 的 `default_cap`，
对象类型枚举在 `seL4/libsel4/include/sel4/objecttype.h`。

## 2.4 对象的大小

对象大小由 `obj_bits_api` 按"类型 + 请求位数"算出（实测）：

```text
theorem cnode_needs_more_than_asked: ?sz < obj_bits_api CapTableObject ?sz

theorem tcb_needs_exactly_asked: obj_bits_api TCBObject ?sz = ?sz
```

真实定义（`l4v/spec/abstract/Retype_A.thy:78`）只有一支会加，其余类型根本不看请求值：

<!-- 源码块：l4v/spec/abstract/Retype_A.thy:78-81 -->
```text
  "obj_bits_api type obj_size_bits \<equiv> case type of
           Untyped \<Rightarrow> obj_size_bits
         | CapTableObject \<Rightarrow> obj_size_bits + slot_bits
         | TCBObject \<Rightarrow> obj_bits (TCB (default_tcb default_domain))
```

也就是说：**只有 Untyped 的位数由用户说了算，TCB / 端点 / 通知的实际大小是内核编译期
定死的** `obj_bits`；CNode 在请求位数之上再加 `slot_bits`。
`slot_bits` 是**一个槽的字节数的对数**（`l4v/spec/abstract/ARM/Machine_A.thy:116` 取 4，
`X64/Machine_A.thy:106` 取 5；C 侧对应 `seL4_SlotBits`，
aarch32/ia32/riscv32 为 4、aarch64/x86_64/riscv64 为 5），
所以"要 2^n 个槽"就要占 `2^(n+slot_bits)` 字节。
本模型的 `obj_bits_api` 为了可算，把"其余类型"简化成了原样返回 `sz`
（上面第二条定理就是这么来的），**别把这条当成真实内核性质**：
真实内核里请求 5 位 TCB 得到的仍是 `obj_bits TCB`，与 5 无关。

**不要假设"请求多少位就占多少位"**——否则第 15 章的 Untyped 分配账目永远对不上。

## 2.5 内核堆：对象表

`kheap` 是从对象引用到对象的部分函数
（`l4v/spec/abstract/Structures_A.thy:522`：
`type_synonym kheap = "obj_ref \<Rightarrow> kernel_object option"`；实测）：

```text
theorem alloc_hit: alloc ?p ?t ?h ?p = Some ?t
```

```text
theorem alloc_miss: ?q \<noteq> ?p \<Longrightarrow> alloc ?p ?t ?h ?q = ?h ?q
```

这类"命中/落空"配对的引理，在 seL4 的证明里出现频率极高——
几乎每一条不变式证明都要先说清"我没碰的地方没变"。

真实代码：`l4v/spec/abstract/KHeap_A.thy`；C 侧对象实现在
`seL4/src/object/cnode.c`、`seL4/src/object/endpoint.c`。

---

## 官方教程对照

官方 [capabilities](https://docs.sel4.systems/Tutorials/capabilities.html) 与
[untyped](https://docs.sel4.systems/Tutorials/untyped.html) 两页（抓取日期 2026-09-25）
从用户视角讲"对象 + 能力"，和本章讲的是同一批东西。
`untyped.html` 里那句 "TL;DR: objects should be allocated in order of size, largest first"
和 `capabilities.html` 里"CSlot 要么空（null cap）要么满"的划法，
在 C 侧都对应本章 2.4 节那张大小表。下面把两边的差异逐条钉住。

**1. 对象类型枚举的编号是 API 的一部分。** `api_object`
（`seL4/libsel4/include/sel4/objecttype.h` 第 8--19 行）从 0 开始数：

```c
typedef enum api_object {
    seL4_UntypedObject,
    seL4_TCBObject,
    seL4_EndpointObject,
    seL4_NotificationObject,
    seL4_CapTableObject,
#ifdef CONFIG_KERNEL_MCS
    seL4_SchedContextObject,
    seL4_ReplyObject,
#endif
    seL4_NonArchObjectTypeCount,
} seL4_ObjectType;
```

`seL4_SchedContextObject` 和 `seL4_ReplyObject` **只在 MCS 内核里存在**，
而且它们的位置在 `seL4_CapTableObject` 之后——也就是说同一个数字在两种内核下
指的不是同一个类型。第 14 章会看到这一条怎么咬人。
另外同一文件第 21 行有个 `__attribute__((deprecated))` 的
`seL4_AsyncEndpointObject`——通知对象早年叫"异步端点"，
官方教程有些段落还在用旧名。

**2. 大小不是查表，是 switch。** `getObjectSize`
（`seL4/src/object/objecttype.c` 第 33--51 行）对端点/通知/TCB 直接返回编译期常量，
`userObjSize` 只在 `seL4_CapTableObject` 和 `seL4_UntypedObject` 两支被用到。
这正好是 2.4 节那条定理的真实版本：**别指望"请求几位就占几位"**。

**3. "几位"这张表按 arch 分叉，而且内核配置会改数字。** 实测（同一份 `#define`
在七个 `sel4_arch/constants.h` 里各不相同；斜杠左边是配置项关掉时的值）：

| 常量 | aarch32 | aarch64 | ia32 | x86_64 | riscv32 | riscv64 |
|---|---|---|---|---|---|---|
| `seL4_SlotBits` | 4 | 5 | 4 | 5 | 4 | 5 |
| `seL4_EndpointBits` | 4 | 4 | 4 | 4 | 4 | 4 |
| `seL4_NotificationBits`（非 MCS / MCS） | 4 / 5 | 5 / 6 | 4 / 5 | 5 / 6 | 4 / 5 | 5 / 6 |
| `seL4_ReplyBits` | 仅 MCS：4 | 仅 MCS：5 | 仅 MCS：4 | 仅 MCS：5 | 仅 MCS：4 | 仅 MCS：5 |
| `seL4_TCBBits` | 9 / 10 / 11 | 11 / 12 | 恒 11 | 11 / 12 | 9 / 10 | 10 / 11 |

`seL4_NotificationBits` 与 `seL4_ReplyBits` 在
`seL4/libsel4/sel4_arch_include/aarch64/sel4/sel4_arch/constants.h` 第 185--191 行
由 `CONFIG_KERNEL_MCS` 二选一，**MCS 那一支总是比非 MCS 大 1 位**，
而 `seL4_ReplyBits` 只存在于 MCS 分支——非 MCS 内核里这个宏根本没有。
TCB 的大小是另一套条件：同一文件第 179--184 行按
`CONFIG_HARDWARE_DEBUG_API` / hypervisor 取 12 或 11；aarch32 分三档（9/10/11，
`CONFIG_HAVE_FPU` 决定中间那档），ia32 干脆写死 11，x86_64 看
`CONFIG_XSAVE_SIZE`。**抄官方教程里"通知对象占 2^5 字节"这句话之前，
先确认你的 arch 和内核配置。**
2.4 节说 `slot_bits` 32 位为 4、64 位为 5，与这张表一致。

**4. "默认权利"在 C 侧不是一张表，是 `createObject` 里的字面量。**
2.3 节那条"端点默认全权利、通知默认不给 grant"在 C 里有逐字对应：
`createObject`（`seL4/src/object/objecttype.c` 第 508 行起）里

```c
    case seL4_EndpointObject:
        return cap_endpoint_cap_new(0, true, true, true, true,
                                    EP_REF(regionBase));

    case seL4_NotificationObject:
        return cap_notification_cap_new(0, true, true,
                                        NTFN_REF(regionBase));
```

端点那支有**四个** `true`（grant reply / grant / receive / send），
通知那支只有**两个**——不是"内核忘了给"，而是通知能力的位域里根本没有那两个格子：
`notification_cap`（`seL4/include/object/structures_32.bf` 第 40--48 行）是
`capNtfnBadge`、`padding 2`、`capNtfnCanReceive`、`capNtfnCanSend`；
端点却有 `capCanGrantReply`（`seL4/include/object/structures_32.bf` 第 31--34 行）
四个权利位。**权利是每种能力各自编码的，不是共享的一个集合**——
这一点 l4v 的抽象（统一的 `cap_rights` 类型）看不出来，看 C 才看得出来。

**5. 类型和大小对不上时，编译期就拦住。** `ep_size_sane` 与
`notification_size_sane`（`seL4/include/object/structures.h` 第 416--417 行）
要求 `sizeof(endpoint_t) == BIT(seL4_EndpointBits)`、
`sizeof(notification_t) == BIT(seL4_NotificationBits)`。
这就是为什么"改一个 `#define`"能一路炸到编译，而不是运行时才发现。

**6. 本章模型与 C 的对应。** 本教程的 `obj_bits_api`（`l4v/spec/abstract/Retype_A.thy`）
比 C 的 `getObjectSize` 多带一个 `slot_bits` 参数，且把 arch 类型折掉了；
`default_cap` 在 l4v 里是一张可写的表，在 C 里是上面那段 switch。
两边名字像、参数不同，别直接互抄。

---

## 本章坑位清单（实测）

1. **给 `cap_rights` 选择子安一个"默认值"**：l4v 里它是 `primrec (nonexhaustive)`，对不带 rights 字段的构造子取值**无约束**（`undefined`）——既不是 `UNIV` 也不是 `{}`，别拿它判断"这个能力有没有权利"。
2. **以为默认权利越多越好**：通知默认只有 `{AllowRead, AllowWrite}`，`AllowGrant`/`AllowGrantReply` 都要显式 mint；`cap_rights_update` 还会在每次更新时把这两支从通知能力上抹掉。
3. **假设 `obj_bits_api` 等于请求位数**：只有 Untyped 是原样返回；CNode 加 `slot_bits`，TCB/端点/通知直接忽略请求值用编译期的 `obj_bits`。
4. **记错构造子字段顺序**：真实的是 `UntypedCap bool obj_ref nat nat`——第一个是 **device 标志**，最后才是 `freeIndex`（已分配水位）。
5. **拿 `UNIV` 当"所有权利"直接展开**：`simp` 会展开四个构造子，证明状态瞬间爆炸。
6. **不同 `record` 用同名字段**：引用时写限定名（`ks_caps s` 而不是裸 `ks_caps`）。
7. **`record` 字段之间写 `|`**：`|` 只是 `datatype` 构造子的分隔符，写进 `record` 报 `Outer syntax error: command expected`。
8. **把"能力数量"当"对象数量"**：一个对象可被任意多能力指向；销毁对象后能力变成 `NullCap` 而不是消失。
9. **在 ML 里对集合求值**（如 `card all_rights`）：求值器处理不了，改用打印定理。
10. **在 ML 字符串里写 Unicode 符号**（如 `⊂`）：ML 层不认，写 ASCII 的 `<` / `<=`。

---

上一章：[01 · 开场](01-overview.md) ｜ 下一章：[03 · 权利与掩码](03-rights.md) ｜ 返回：[README](../README.md)
