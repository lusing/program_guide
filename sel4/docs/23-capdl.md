# 23 · capDL：用一张图描述系统的保护状态

对应示例：`../examples/S23_capdl.thy`

## 23.1 capDL：用一张图描述系统的保护状态

前面各章证明了"内核的每一步都安全"。但用户真正想知道的是：
**"我这套具体的系统配置，A 分区和 B 分区是不是真的隔离？"**
这个问题不是关于内核的，而是关于**某个具体的对象-能力图**的。

capDL（Capability Distribution Language）把"有哪些对象、每个对象里放着哪些能力"
写成一张图，然后在图上做可达性分析。真实代码在 `l4v/spec/capDL/`：
`Structures_D.thy` 定义图，`CSpace_D.thy`、`CNode_D.thy`、`Decode_D.thy` 等
给出"内核操作在这张图上怎么走"，`KHeap_D.thy`、`Schedule_D.thy` 连回内核状态。

## 23.2 能力指向的对象

图里每个对象有一个 id，槽里放着能力，能力可以指向另一个对象（或为空）。

## 23.3 井形性：每条边都指向存在的对象，且类型匹配

```text
theorem empty_is_well_formed: well_formed empty_cdl
```

```text
theorem
  dangling_cap_is_not_well_formed:
    \<lbrakk>?s ?oid = Some ?obj; do_caps ?obj ?sl = Some (EndpointDCap ?p ?R);
     ?s ?p = None\<rbrakk>
    \<Longrightarrow> \<not> well_formed ?s
```

**悬空能力直接判这张图不合法**。这与第 17 章内核不变式里的 `valid_objs`
是同一条要求，只不过发生在"配置图"这一层。

## 23.4 可达性：从根能走到哪里

```text
theorem self_is_reachable: ?oid \<in> reachable ?s ?oid
```

`reachable_step` 是"一步可达"，`reachable` 是它的自反传递闭包。
**隔离性质就写成"A 的可达集里没有 B 的东西"**。

证明闭包定理时会出现一个告警（实测）：

```text
Warning (line 123 of "/Volumes/mac004/code/programming/sel4/examples/S23_capdl.thy"):
### Ignoring duplicate unsafe introduction (intro)
### ?p \<in> ?r \<Longrightarrow> ?p \<in> ?r\<^sup>*
```

`r*` 的引入规则重复了。它只是告警，但说明应该用具体的
`rtrancl` 引入规则（如 `r_into_rtrancl`）。

## 23.5 一个两分区的示例系统

```text
theorem
  partitions_do_not_reach_each_other:
    21 \<notin> reachable_step two_partition_system 10
```

这是 capDL 最典型的用法：给定一张具体的图，**机器算出**
"分区 A 摸不到分区 B 的端点"。隔离由此从定性描述变成可计算判据。

---

## 本章坑位清单（实测）

1. **把 `reachable_step` 当 `reachable`**：前者是一步，后者是闭包；隔离要用闭包。
2. **闭包引入规则重复**：报 `Ignoring duplicate unsafe introduction`，换成 `r_into_rtrancl`。
3. **以为悬空能力可以被忽略**：`well_formed` 直接判否。
4. **只查"对象存在"不查"类型匹配"**：capDL 的 `type_matches` 与内核的 `valid_objs` 一样要求两者。
5. **把 capDL 图当内核状态**：它是**描述**，与内核状态之间的对应要由 `l4v/spec/capDL/` 的定理桥接。
6. **以为 capDL 能推出运行时性质**：它只描述初始配置，运行期性质要靠内核证明 + 对应定理。
7. **在证明里展开 `reachable`**：闭包会无限展开，用归纳规则。
8. **把对象 id 当地址**：capDL 里是抽象的 oid，与物理地址无关。
9. **忽略架构分支**：`l4v/spec/capDL/` 下有 `AARCH64/`、`ARM/`、`ARM_HYP/` 等架构专属部分。
10. **找 capDL 找错目录**：定义与图上定理在 `l4v/spec/capDL/`，相关证明在 `l4v/proof/capDL-api/` 与 `l4v/proof/sep-capDL/`。

---

上一章：[22 · 非干扰](22-infoflow.md) ｜ 下一章：[24 · 综合案例：分区隔离](24-capstone.md) ｜ 返回：[README](../README.md)
