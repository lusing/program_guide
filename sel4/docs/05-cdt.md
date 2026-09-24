# 05 · 能力派生树（CDT）

对应示例：`../examples/S05_cdt.thy`

## 5.1 CDT：能力派生树

只有"权利会衰减"还不够。设想：root 把能力给了 A，A 给了 B，B 给了 C。
现在 root 想收回——它必须能一次收回 A、B、C 三份，否则"收回"就是一句空话。

seL4 的办法是维护一棵 **CDT（Capability Derivation Tree）**：
每次派生（mint/copy）都在树里加一条边"新槽的父是老槽"，于是"收回"就是"删掉整棵子树"。
真实定义见 `l4v/spec/abstract/CSpaceAcc_A.thy` 的 `cdt`、`is_cdt_parent`、`descendants_of`。

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

Untyped 只有在**没有子孙**时才允许再分配。这条正好解释了第 15 章
`ensure_no_children` 为什么存在：**Untyped 一旦分出子对象就不能再改尺寸**，
否则会出现两份重叠的内存。

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

## 5.5 插入时谁当父亲：should_be_parent_of

```text
theorem
  not_original_never_parent:
    \<not> ?src_orig \<Longrightarrow> \<not> should_be_parent_of ?src ?src_orig ?new ?new_orig
```

只要源能力自己是"复制品"（`original = False`），它就不会成为别人的父节点。
这条保证了 CDT 里"源头"唯一，撤销时不会漏。

## 5.6 插入能力与 CDT 的单调性

```text
theorem
  descendants_mono:
    ?t ?p = None \<Longrightarrow> descendants_of ?x ?t \<subseteq> descendants_of ?x (?t(?p \<mapsto> ?q))
```

往空位加一条边，子孙集合只会变大（前提是那个位置原本没有边）。
真实内核里对应的操作是 `l4v/spec/abstract/CSpace_A.thy` 的
`cap_insert` / `cap_move` / `cap_swap`。

---

## 本章坑位清单（实测）

1. **把 `descendants_of` 当"直接儿子"**：它是父边关系的传递闭包 `⁺`，收回要连孙辈一起。
2. **以为 mint 可以增权**：`mint` 内部先做掩码，不增长性要拆成"掩码 + 派生"两步证。
3. **以为 Untyped 有子孙时还能再分配**：实测是 `DeriveFailed`。
4. **忽略 `original` 位**：源能力是复制品时不当父节点，漏掉会让撤销漏网。
5. **`descendants_mono` 忘了 `t p = None` 前提**：往已有边的位置覆盖，单调性不成立。
6. **传递闭包定理用错归纳规则**：`intro` 重复时报 `Ignoring duplicate unsafe introduction`，要用 `r_into_trancl` 之类的具体规则。
7. **把 CDT 当 CSpace**：CDT 只记派生关系，与"哪个槽里放着什么能力"是两个结构（`ks_cdt` vs `ks_cspace`）。
8. **在证明里展开传递闭包**：`simp` 会无休止展开 `⁺`，要用引入/归纳规则。
9. **以为 copy 与 mint 语义相同**：`mint` 带掩码参数，`copy` 等价于 `mint UNIV`（全保留）。
10. **忘了"空树"基线**：`descendants_of p (\<lambda>x. None) = {}`，很多归纳从这里起步。

---

上一章：[04 · CSpace 与地址解析](04-cspace.md) ｜ 下一章：[06 · 回收与删除](06-revoke-delete.md) ｜ 返回：[README](../README.md)
