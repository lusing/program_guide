# 15 · 内存再类型化（Retype）

对应示例：`../examples/S15_retype.thy`

## 15.1 Untyped：内存的唯一来源

seL4 里所有内核对象都从 **Untyped 内存**里长出来。一个 Untyped 能力记着：
基址（`ut_base`）、总大小（`ut_size`）、**已分配水位**（`ut_free`）。
分配一个对象 = 从水位处切一块，水位前进。

真实代码：`l4v/spec/abstract/Retype_A.thy` 的 `retype_region` /
`create_cap` / `default_object`，C 侧 `seL4/src/object/untyped.c`。

## 15.2 分配：从 freeIndex 往后切

```text
theorem alloc_zero_rejected: alloc_chunk 0 ?u = None
```

```text
theorem
  alloc_returns_free_pointer:
    alloc_chunk ?n ?u = Some (?p, ?u') \<Longrightarrow> ?p = ut_base ?u + ut_free ?u
```

零大小拒绝、越界拒绝、地址正好是水位处、水位按分配量前进——
加上"基址不变"，就是一个完整的内存分配器规格。

## 15.3 分配出来的块互不重叠

```text
theorem
  chunks_do_not_overlap:
    \<lbrakk>alloc_chunk ?n ?u = Some (?p, ?u');
     alloc_chunk ?m ?u' = Some (?q, ?u'')\<rbrakk>
    \<Longrightarrow> ?p + ?n \<le> ?q
```

连续两次分配，第二块的起点不早于第一块的终点——
**这就是"两个对象不会占同一块物理内存"**。
它是第 17 章 `pspace_distinct` 不变式的算术内核。

## 15.4 retype 之前必须没有子孙

```text
theorem empty_means_no_children: ensure_no_children {}
```

`ensure_no_children` 要求这个 Untyped 还没有派生出任何能力。
一旦分出了子对象，就不能再重新类型化这块内存——
否则之前分出去的对象会和新的对象重叠。
这与第 05 章的 `derive_untyped_needs_no_children` 是同一条规则的两个视角。

一句话总结本章：**内存的类型是"谁拥有这块物理内存"的唯一凭证**。
seL4 没有动态分配的内核堆，所有对象的生命周期都由能力图决定。

---

## 本章坑位清单（实测）

1. **分配零大小**：被拒绝，别指望它返回空块。
2. **水位加法溢出**：`ut_free + n` 可能超过 `ut_size`，必须先判越界。
3. **把 `ut_end` 当别的东西**：它就是结束地址，分配块必须不越过它。
4. **以为可以重新类型化已有子孙的内存**：`ensure_no_children` 会拒绝。
5. **把 `freeIndex` 当"剩余大小"**：它是**已分配的水位**，不是剩余量。
6. **以为对象大小等于请求位数**：CNode 会多一个 slot。
7. **忽略对齐**：真实内核还要求对象按自身大小对齐，模型里省掉了但 C 侧有。
8. **把两次分配的地址顺序想反**：第二块的起点 ≥ 第一块的终点。
9. **在证明里用 `simp` 推地址算术**：`p + n ≤ q` 需要 `linarith`。
10. **找实现找错文件**：`seL4/src/object/untyped.c`（不在 `src/kernel/`）。

---

上一章：[14 · 调度](14-schedule.md) ｜ 下一章：[16 · 霍尔逻辑与 wp](16-hoare-wp.md) ｜ 返回：[README](../README.md)
