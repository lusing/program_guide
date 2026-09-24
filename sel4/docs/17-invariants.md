# 17 · 不变式

对应示例：`../examples/S17_invariants.thy`

## 17.1 不变式：内核证明的骨架

seL4 的每一条系统调用证明都要带上同一句话：**操作前后，内核状态都满足不变式**。
核心不变式是 `valid_objs`（能力指向的对象存在且类型一致）、
`valid_mdb`（CDT 每条边的两端槽都非空）、
`pspace_aligned` / `pspace_distinct`（对齐且不重叠，见第 15 章）。

真实代码在 `l4v/proof/invariant-abstract/`：`AInvs.thy`、`AInvsPre.thy`、
`CSpaceInv_AI.thy`、`ADT_AI.thy`。

空状态是不变式的起点（实测）：

```text
theorem
  empty_state_is_valid:
    valid_objs \<lparr>ks_objs = \<lambda>_. None, ks_caps = \<lambda>_. None, ks_cdt = \<lambda>_. None\<rparr>
```

## 17.2 valid_objs：能力指向的对象必须存在且类型一致

```text
theorem
  cap_to_missing_object_is_invalid:
    \<lbrakk>ks_caps ?s ?sl = Some (EndpointCap ?p); ks_objs ?s ?p = None\<rbrakk>
    \<Longrightarrow> \<not> valid_objs ?s
```

一个指向"空气"的能力会让整个状态不合法。类型不对也不行（实测）：

```text
theorem
  insert_wrong_type_breaks_valid_objs:
    ks_objs ?s ?p = Some NotificationType \<Longrightarrow>
    \<not> valid_objs (insert_cap (EndpointCap ?p) ?sl ?s)
```

## 17.3 插入能力：只在新对象存在时才保持

插入能力时只有两种安全做法：插 `NullCap` 无条件安全；
插一个指向 `p` 的能力，**必须已经证明 `p` 处有一个类型匹配的对象**。

## 17.4 valid_mdb：CDT 的父亲必须存在

```text
theorem
  edge_to_empty_slot_is_invalid:
    \<lbrakk>ks_cdt ?s ?sl = Some ?p; ks_caps ?s ?p = None\<rbrakk> \<Longrightarrow> \<not> valid_mdb ?s
```

一条边要求**两端**槽都非空，否则第 06 章的回收会沿着边走到一个已经不存在的槽。

## 17.5 不变式要一起保持

```text
theorem invs_insert_null: invs ?s \<Longrightarrow> invs (insert_cap NullCap ?sl ?s)
```

`invs` 是把几条不变式合起来的总谓词。每一条系统调用定理的形状都是
`⟦invs s; …⟧ ⟹ invs s'`——**不变式是归纳的骨架**：
只要初始状态满足，任何操作序列之后仍满足。

---

## 本章坑位清单（实测）

1. **只证"操作成功"不证"保持不变式"**：seL4 的定理一律是 `invs s ⟹ invs s'`。
2. **忘了空状态是基例**：归纳要从这里起步。
3. **把"对象存在"与"类型匹配"分开证**：`valid_objs` 同时要求两者。
4. **CDT 边只查一端**：两端槽都要非空。
5. **在证明里展开 `valid_objs` 的全称量化**：要显式实例化出那个具体的槽和对象。
6. **变量遮蔽**：`fix`/`obtain` 时与外层同名变量冲突，实例化的事实会指向错误的变量。
7. **把 `invs` 当单一谓词展开**：它是合取，展开后子目标翻倍；用已有的 `invs_*` 引理组合。
8. **忽略 `pspace_distinct`**：对象不重叠是地址算术的结论，不是前提。
9. **以为不变式只用于"安全"**：它首先用于"正确性"——没有它连"能力指向哪"都说不清。
10. **找不变式找错目录**：`l4v/proof/invariant-abstract/`（不是 `l4v/spec/abstract/`，后者只有定义）。

---

上一章：[16 · 霍尔逻辑与 wp](16-hoare-wp.md) ｜ 下一章：[18 · 精化关系](18-corres.md) ｜ 返回：[README](../README.md)
