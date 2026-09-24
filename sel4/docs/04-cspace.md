# 04 · CSpace 与地址解析

对应示例：`../examples/S04_cspace.thy`

## 4.1 CSpace：一张由 CNode 组成的图

用户说"我要用这个能力"时，给的不是地址，而是一串 **bit**。
内核拿这串位去一棵 CNode 树里走：每一级先用 guard 比对、再取 `bits` 位当索引、
余下的位交给下一级。这串位叫 `cnode_index`（`bool list`），
配上对象引用就是 `cslot_ptr = obj_ref × cnode_index`。

真实定义见 `l4v/spec/abstract/Structures_A.thy` 与 `l4v/spec/abstract/CSpaceAcc_A.thy`；
C 侧遍历在 `seL4/src/kernel/cspace.c`。

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
用 `function` 递归定义它，终止性证明在本机**会挂死**——
路径长度确实递减，但自动化方法要跨过 guard/索引的算术才看得出来。

本教程的解法是加一个**燃料参数**，把递归深度显式变成结构递归
（实测输出里能看到找到的终止顺序）：

```text
Found termination order: "(\<lambda>p. size (fst p)) <*mlex*> {}"
```

真实内核不需要这一手，它的深度被 `word_bits` 天然限死；
但模型里不显式给界，要么证不出终止性，要么证明跑几分钟不出结果。

## 4.4 空路径解析到根槽位本身

不是 CNode 的东西不能继续往下走（实测）：

```text
theorem resolve_leaf_is_none: resolve ?s NullCap ?path = None
```

而"路径为空"是**合法**的，它表示"就取这个槽本身"——
但它带着"根槽真的存在"的前提，把它和"解析失败"混为一谈是本章最常见的证明卡点。

## 4.5 井形 CNode：槽位索引长度必须一致

`well_formed_cnode_n` 要求同一个 CNode 里所有槽的键长度一致（都是 `n`）。
插入一个长度不同的键就破坏井形性，后面所有关于解析的定理都会失效。

---

## 本章坑位清单（实测）

1. **递归定义的终止性证明挂死**：CSpace 解析用 `function` 时自动化方法在长度算术上打转；加燃料参数把递归变成结构递归。
2. **guard 不匹配要返回 `None`**：返回"部分成功"会让后面所有调用方都要处理半截状态。
3. **路径拆分顺序写反**：是 `guard @ idx @ rest = path`。
4. **索引取错位置**：`idx = take bits (drop (length guard) path)`，漏掉 `drop` 就把 guard 当索引了。
5. **忽略 `well_formed_cnode_n`**：插入不同长度的键会破坏井形性，静默地让解析定理失效。
6. **把"空路径"当解析失败**：空路径 = 取根槽，合法且常见（`lookup_slot_for_thread` 就用它）。
7. **`cnode_index` 是 `bool list` 不是 `nat`**：长度等于 `bits`，别用数字索引去算。
8. **`take`/`drop` 的 off-by-one**：`length guard + bits` 的算术要显式给出。
9. **模型里没有深度上界**：真实内核有 `word_bits` 兜底，模型没有就必须显式加界。
10. **用 `fun` 定义多级解析时 pattern 重叠**：分支要按 cap 类型穷尽，漏一个报 `Missing patterns`。

---

上一章：[03 · 权利与掩码](03-rights.md) ｜ 下一章：[05 · 能力派生树](05-cdt.md) ｜ 返回：[README](../README.md)
