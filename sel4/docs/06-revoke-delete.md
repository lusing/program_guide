# 06 · 回收与删除

对应示例：`../examples/S06_revoke_delete.thy`

## 6.1 为什么要 revoke

删掉一个能力，只影响那个槽；但派生出去的那些副本还活着。
想要"彻底收回"，必须沿着 CDT 把整棵子树清掉——这就是 `revoke`。

真实内核里对应 `l4v/spec/abstract/CSpace_A.thy` 的 `cap_delete`、`cap_revoke`、
`rec_del`、`finalise_cap`，C 侧在 `seL4/src/object/cnode.c`。

## 6.2 单槽删除

```text
theorem
  delete_slot_clears_cap: ks_cspace (delete_slot ?p ?s) ?p = Some NullCap
```

删除是把槽里填成 `NullCap`，**不是把槽删掉**。
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

两条合起来就是"回收"的完整规格：**精确命中子孙集合，不多也不少**。
少了会漏，多了会误伤无关能力。

## 6.4 撤销是幂等的

CDT 里的边也要一起清，否则会留下指向空槽的悬空边（实测）：

```text
theorem revoke_no_out_edges: \<nexists>y. ks_cdt (revoke ?p ?s) y = Some ?p
```

证明这条定理时出现过一个真实的告警（实测）：

```text
Warning (line 107 of "/Volumes/mac004/code/programming/sel4/examples/S06_revoke_delete.thy"):
### Ignoring duplicate unsafe introduction (intro)
### (?a, ?b) \<in> ?r \<Longrightarrow> (?a, ?b) \<in> ?r\<^sup>+
```

把 `(a,b) ∈ r ⟹ (a,b) ∈ r⁺` 直接塞进 `intro` 时，它与已有引入规则重复。
**告警不是错误，但它说明有一处规则是多余的**——看到就该换成具体的 `r_into_trancl`。

## 6.5 Zombie：删不完的中间态

真实内核里"删除一个对象"往往不是一步完成的：删一个 TCB 要先把它从各种队列里摘掉，
这些动作可能跨越多次系统调用。中间状态用专门的 cap 构造子 **`Zombie`** 表示，
它记着"还差几步"。

`can_be_replaced` 判定一个槽能不能被直接覆盖——**`Zombie` 不能**。
这是本章想传达的点：删除在 seL4 里是一个**有状态的、可分阶段的过程**，不是一个布尔操作。

---

## 本章坑位清单（实测）

1. **把 `delete` 当 `revoke`**：前者只清一个槽，后者清整棵子树。
2. **只清能力不清 CDT 边**：树里留下悬空边，后续回收走错路径。
3. **"别人不动"的前提漏掉 `q ≠ p`**：`simp` 不会替你补这个前提。
4. **传递闭包引入规则重复**：报 `Ignoring duplicate unsafe introduction`，换成 `r_into_trancl`。
5. **以为删除是原子的**：真实内核里长删除会产生 `Zombie`，分多次系统调用完成。
6. **以为 `Zombie` 槽可以被覆盖**：`can_be_replaced` 对它返回假。
7. **用 `simp` 直接展开 `descendants_of`**：传递闭包会无限展开，必须用归纳规则。
8. **把 `NullCap` 当"槽不存在"**：`ks_cspace s p = None` 与 `= Some NullCap` 是两回事。
9. **回收后忘了清 `ks_cdt`**：下一次 `descendants_of` 会算出错误的集合。
10. **找 C 侧实现找错文件**：删除/回收在 `seL4/src/object/cnode.c`，不在 `seL4/src/kernel/cspace.c`。

---

上一章：[05 · 能力派生树](05-cdt.md) ｜ 下一章：[07 · 非确定性状态单子](07-nondet-monad.md) ｜ 返回：[README](../README.md)
