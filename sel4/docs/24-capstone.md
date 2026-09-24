# 24 · 综合案例：证明一个两分区系统是隔离的

对应示例：`../examples/S24_capstone.thy`

## 24.1 综合案例：证明一个两分区系统是隔离的

本章把整本教程收束到一个具体问题：**两个分区，永远互相摸不到**。
它同时用到：能力（第 02、03 章）与派生树（第 05 章）、删除/回收（第 06 章）、
系统调用与解码（第 09、10 章）、不变式（第 17 章）与精化的思想（第 18–20 章）、
完整性的"授权才允许变化"（第 21 章）与非干扰的"不可区分"（第 22 章）、
capDL 的可达性判据（第 23 章）。

## 24.2 一步可达与"不跨界"

```text
theorem system_without_edges_is_isolated: isolated (\<lambda>_. None) ?a
```

`isolated s a`：从分区 a 里的任何对象出发，一步之内能摸到的东西
仍然在同一个分区里。没有边的系统当然是隔离的——这是基例。

## 24.3 四类操作

模型里有四类操作：插入能力（`Ins`）、删除（`Del`）、回收（`Rev`）、
以及"什么都不做"。每类操作都要分别证明它不破坏隔离。

## 24.4 单步引理：只有"同分区插入"才被允许

```text
theorem
  insert_crossing_partition_is_illegal:
    \<lbrakk>?s ?oid = Some ?n; cn_part ?n = 1; part_of ?s ?p = Some 2\<rbrakk>
    \<Longrightarrow> \<not> legal ?s (Ins ?oid ?sl (EndpointCap ?p {AllowRead}))
```

注意这里的能力权利只有 `{AllowRead}`——**权利再小也不行**，
因为隔离是连通性性质，与读/写无关。这一点常被误解。

## 24.5 单步保持隔离

```text
theorem
  op_delete_reduces_reaches:
    ?p \<in> reaches (op_delete ?oid ?sl ?s) ?x \<Longrightarrow> ?p \<in> reaches ?s ?x
```

删除与回收**只会让可达集变小**——不可达性不会因为删东西而被破坏。

```text
theorem
  step_preserves_isolation:
    \<lbrakk>isolated ?s ?a; legal ?s ?op\<rbrakk> \<Longrightarrow> isolated (apply_op ?op ?s) ?a
```

**合法的一步不会破坏隔离**。

## 24.6 归纳：任意长的运行

```text
theorem
  run_ops_preserves_isolation:
    \<lbrakk>isolated ?s ?a; all_legal ?s ?ops\<rbrakk> \<Longrightarrow> isolated (run_ops ?ops ?s) ?a
```

终局：**任意长的合法操作序列之后，分区依然隔离**。
它的证明就是第 22 章那条归纳的翻版——单步保持 ⟹ 序列保持。

## 24.7 回头看：这条定理依赖了什么

| 本章的东西 | 真实位置 |
|---|---|
| `isolated` / `legal` | `l4v/proof/access-control/`（策略与完整性） |
| 可达性与分区 | `l4v/spec/capDL/`、`l4v/proof/sep-capDL/` |
| 单步 ⟹ 序列 | `l4v/proof/infoflow/Noninterference.thy` |
| 每一步都合法 | `l4v/spec/abstract/Syscall_A.thy` 上的全部操作定理 |

真实 seL4 的分区隔离不是靠"一次大证明"，而是靠
**每一类系统调用各自证明保持隔离** + **策略层禁止非法初始配置** + **归纳到任意序列**。
本章的模型把这三件事压缩成了一个两百行的文件。

---

## 本章坑位清单（实测）

1. **以为"只有读权利"就不破坏隔离**：隔离是连通性性质，`{AllowRead}` 的跨分区插入同样非法。
2. **忘了 `legal` 的前提**：不合法的操作当然可以破坏隔离。
3. **把 `part_of` 当总函数**：它返回 `option`，未归属的对象要单独处理。
4. **以为插入会改变分区归属**：实测 `op_insert_preserves_part_of` 说不变。
5. **删除/回收的可达性方向写反**：是"操作后可达 ⟹ 操作前可达"（只减不增）。
6. **归纳时忘了 `all_legal` 要随状态推进**：每一步的合法性要在**当时的状态**上判定。
7. **`run_ops` 的终止性**：对列表递归，`fun` 能自动找到顺序（实测输出里有 `Found termination order`）。
8. **把"初始配置隔离"当"运行时隔离"**：前者靠 `legal`，后者靠 `step_preserves_isolation`，两者都要。
9. **在证明里展开 `isolated`**：它是带全称量词的谓词，要显式 `intro allI impI` 再分情况。
10. **以为一个模型能替代真实证明**：本章是**形状的复现**，真实 seL4 要对每一类系统调用分别证明。

---

上一章：[23 · capDL](23-capdl.md) ｜ 返回：[README](../README.md)
