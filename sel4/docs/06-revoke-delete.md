# 06 · 回收与删除

对应示例：`../examples/S06_revoke_delete.thy`

## 6.1 为什么要 revoke

删掉一个能力，只影响那个槽；但派生出去的那些副本还活着。
想要"彻底收回"，必须沿着 CDT 把整棵子树清掉——这就是 `revoke`。

真实内核里对应 `l4v/spec/abstract/CSpace_A.thy` 的
`cap_delete`（第 569 行）、`cap_revoke`（第 603 行）、
`rec_del`（第 509 行）、`finalise_cap`（第 431 行），
C 侧在 `seL4/src/object/cnode.c`（`cteRevoke` 第 528 行、`cteDelete` 第 552 行）。

## 6.2 单槽删除

```text
theorem
  delete_slot_clears_cap: ks_cspace (delete_slot ?p ?s) ?p = Some NullCap
```

删除是把槽里填成 `NullCap`，**不是把槽删掉**。
真实实现 `empty_slot`（定义在 `l4v/spec/abstract/IpcCancel_A.thy:275`，
由 `l4v/spec/abstract/CSpace_A.thy` 第 514 行的 `rec_del` 调用）除了填 `NullCap`
还要摘 CDT 边、清 `is_original_cap`、把孩子们改挂到被删槽的父亲下。
"我没碰的地方没变"这类引理在 seL4 的证明里到处都是，
`l4v/lib/Crunch.thy` 就是专门批量生成它们的框架。

## 6.3 撤销：把子孙全部删掉

```text
theorem revoke_clears_target: ks_cspace (revoke ?p ?s) ?p = Some NullCap
```

```text
theorem
  revoke_clears_descendant:
    ?q \<in> descendants_of ?p (ks_cdt ?s) \<Longrightarrow>
    ks_cspace (revoke ?p ?s) ?q = Some NullCap
```

两条合起来是**本模型**的规格。⚠️ 第一条与真实内核**不一致**，必须记住这个偏差：
`cap_revoke`（`CSpace_A.thy:603`）删的是 `descendants_of slot cdt`，
**目标槽自己的能力原样保留**——

<!-- 源码块：l4v/spec/abstract/CSpace_A.thy:608-613 -->
```text
    descendants \<leftarrow> returnOk $ descendants_of slot cdt;
    whenE (cap \<noteq> NullCap \<and> descendants \<noteq> {}) (doE
      child \<leftarrow> without_preemption $ select_ext (next_revoke_cap slot) descendants;
      cap \<leftarrow> without_preemption $ get_cap child;
      assertE (cap \<noteq> NullCap);
      cap_delete child;
```

用户要连自己那份一起没，得再发一次 `seL4_CNode_Delete`。
另外还有三处真实细节被模型抹平了：目标槽已是 `NullCap` 时真实实现什么都不做；
每次只删一个子孙然后递归重来；中间有 `preemption_point`——
**revoke 是可抢占的长操作**，"删到一半"是合法状态。
"精确命中子孙集合，不多也不少"仍是真实证明要证的性质，
只是"多"的那一半（目标槽）模型替你做了。

## 6.4 撤销是幂等的

CDT 里的边也要一起清，否则会留下指向空槽的悬空边（实测）：

```text
theorem revoke_no_out_edges: \<nexists>y. ks_cdt (revoke ?p ?s) y = Some ?p
```

证明这条定理时出现过一个真实的告警：把 `(a,b) ∈ r ⟹ (a,b) ∈ r⁺`
直接塞进 `intro` 时，它与已有的传递闭包引入规则重复，Isabelle 报

<!-- 示意块：编译期告警，不在 process_theories 的抽取区间内 -->
```text
### Ignoring duplicate unsafe introduction (intro)
```

**告警不是错误，但它说明有一处规则是多余的**——看到就该换成具体的 `r_into_trancl`
（`S06_revoke_delete.thy` 的 `cdt_edge_implies_descendant` 就是这么写的）。

## 6.5 Zombie：删不完的中间态

真实内核里"删除一个对象"往往不是一步完成的：删一个 CNode 要先把它下面所有槽清空，
这可能跨越多次系统调用（`long_running_delete`，`CSpace_A.thy:319`）。
中间状态用专门的 cap 构造子 **`Zombie`** 表示（`finalise_cap`，同文件第 431 行），
它记着"还差几步"。

`can_be_replaced` 是本模型给的名字，真实判定叫 `cap_removeable`（`CSpace_A.thy:493`）：
`Zombie slot' bits n` 只有在它不再覆盖别的槽时才算可移除。
这是本章想传达的点：删除在 seL4 里是一个**有状态的、可分阶段的过程**，不是一个布尔操作。

---

## 官方教程对照

官方 [capabilities](https://docs.sel4.systems/Tutorials/capabilities.html)
（抓取日期 2026-09-25）演示撤销只用了两行：
`seL4_CNode_Revoke(seL4_CapInitThreadCNode, seL4_CapInitThreadTCB, seL4_WordBits)`。
这一页把 revoke 讲成"把派生出去的能力全部收回"，方向对，但它掩盖了四件本章正是要讲的事。

**1. 接口上没有"撤销到什么程度"的选项。** `CNodeRevoke`
在 `seL4/libsel4/include/interfaces/object-api.xml:862`，参数只有 `index` 和 `depth`
（`CNodeDelete` 同形，`:894`）——**没有 rights、没有 badge、没有"只撤这一支"的开关**。
所以 6.3 那句"撤销是一整棵子树"不是模型的偷懒，是 API 的硬约束。

**2. 内核侧的 revoke 是"顺兄弟链删"，不是"递归下子树"。**
`invokeCNodeRevoke`（`seL4/src/object/cnode.c:315`）只有一行
`return cteRevoke(destSlot);`，而 `cteRevoke`（`seL4/src/object/cnode.c:528`）是

```c
    for (nextPtr = CTE_PTR(mdb_node_get_mdbNext(slot->cteMDBNode));
         nextPtr && isMDBParentOf(slot, nextPtr);
         nextPtr = CTE_PTR(mdb_node_get_mdbNext(slot->cteMDBNode))) {
        status = cteDelete(nextPtr, true);
```

它沿 MDB 的 `mdbNext` 链往前走，只要下一个还是自己的孩子就删掉它。
**"整棵子树没了"这件事是由每次 `cteDelete` 自己递归保证的**，
循环本身只处理同一层。抽象规范里的 `descendants_of` 把这层结构压扁了——
看证明时别以为内核真的在做一次全子树遍历。
另外那句注释 "there is no need to check for a NullCap as NullCaps are always
accompanied by null mdb pointers" 是一个典型的实现不变式：它不在 `invs` 里，
却是这段代码正确的依据。

**3. "有子孙就不能删"在 C 里是一个用户可见的错误码。** `ensureNoChildren`
（`seL4/src/object/cnode.c:821`）发现槽位仍有孩子时，把
`current_syscall_error.type` 设成 `seL4_RevokeFirst`
（`seL4/src/object/cnode.c:828`），
它在 `seL4/libsel4/include/sel4/errors.h:19`。
旁边还住着 `seL4_DeleteFirst`（`seL4/libsel4/include/sel4/errors.h:18`）——
"要往非空槽里装能力"报的都是它。它的**唯一出处**是
`ensureEmptySlot`（`seL4/src/object/cnode.c:836--844`）那句
`cap_get_capType(slot->cap) != cap_null_cap`，
而调这个函数的不止 retype：本章上文的 CNode 派生（`seL4/src/object/cnode.c:93`）、
第 12 章的 IRQ handler 安装、第 15 章的整窗检查都走它。
**这两个错误码在教程正文里经常被混说成"先删再用"**，触发条件其实不同：
`RevokeFirst` 出自"还有子孙"（CDT 里有孩子），`DeleteFirst` 出自"目标槽非空"。
前者问的是派生树，后者问的是一个槽位——retype 只是最常撞到后者的地方。

**4. Zombie 真的带一个计数器。** `cap_zombie_cap_get_capZombieNumber`
在 `seL4/src/object/cnode.c:600`；同一函数里那句
`finaliseCap` 注释（`seL4/src/object/cnode.c:605`）说明"中间态"只有
Zombie 与 NullCap 两种可能。`reduceZombie`
在 `seL4/src/object/cnode.c:664`，每删掉一个孩子计数少 1。
6.5 节把 Zombie 建模成"装着未删完子孙的容器"，与这段代码一比一对应。

**5. 官方教程没讲、但 API 里在的三个操作：** `CNodeMutate`
（`seL4/libsel4/include/interfaces/object-api.xml:1100`）、
带两端 badge 的 `CNodeRotate`
（`seL4/libsel4/include/interfaces/object-api.xml:1144`）、以及只在 MCS 下才存在的
`CNodeCancelBadgedSends`（`seL4/libsel4/include/interfaces/object-api.xml:926`）。
反过来 `CNodeSaveCaller`（`seL4/libsel4/include/interfaces/object-api.xml:1190`）
的 `<condition>` 写着 `CONFIG_KERNEL_MCS` 的**取反**——
**MCS 内核里没有 SaveCaller**，因为 reply 对象取代了它（第 12 章）。

---

## 本章坑位清单（实测）

1. **把 `delete` 当 `revoke`**：前者只清一个槽，后者清整棵子树——但真实 `cap_revoke` **不动目标槽自己**，要连自己一起删得再发一次 `CNode_Delete`。
2. **只清能力不清 CDT 边**：树里留下悬空边，后续回收走错路径。
3. **"别人不动"的前提漏掉 `q ≠ p`**：`simp` 不会替你补这个前提。
4. **传递闭包引入规则重复**：报 `Ignoring duplicate unsafe introduction`，换成 `r_into_trancl`。
5. **以为删除是原子的**：真实内核里长删除（`long_running_delete`）会产生 `Zombie`，分多次系统调用完成；`cap_revoke` 还带 `preemption_point`，删到一半被抢占是正常状态。
6. **以为 `Zombie` 槽可以被覆盖**：真实判定是 `cap_removeable`（`CSpace_A.thy:493`，本模型叫它 `can_be_replaced`），只有"已不再覆盖别的槽"的 Zombie 才可移除。
7. **用 `simp` 直接展开 `descendants_of`**：传递闭包会无限展开，必须用归纳规则。
8. **把 `NullCap` 当"槽不存在"**：`ks_cspace s p = None` 与 `= Some NullCap` 是两回事。
9. **回收后忘了清 `ks_cdt`**：下一次 `descendants_of` 会算出错误的集合。
10. **找 C 侧实现找错文件**：删除/回收在 `seL4/src/object/cnode.c`，不在 `seL4/src/kernel/cspace.c`。
11. **以为 `RevokeFirst` 是撤销失败**：它是 `ensure_no_children` 抛的（`l4v/spec/abstract/CSpace_A.thy:71`），意思是"想复制/删一个还带着子孙的能力，先把子孙 revoke 掉"。

---

上一章：[05 · 能力派生树](05-cdt.md) ｜ 下一章：[07 · 非确定性状态单子](07-nondet-monad.md) ｜ 返回：[README](../README.md)
