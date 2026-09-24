# 22 · 非干扰（机密性）

对应示例：`../examples/S22_infoflow.thy`

## 22.1 机密性：非干扰

完整性说"不能乱改"，机密性说"不能偷看"。seL4 的机密性定理叫
**非干扰（noninterference）**，在 `l4v/proof/infoflow/`：
`Noninterference_Base.thy` 定义骨架，`Noninterference.thy` 是总定理，
`Ipc_IF.thy`、`CNode_IF.thy`、`Finalise_IF.thy`、`Decode_IF.thy` 分头证明各类调用，
`ADT_IF.thy` 把内核包装成一个带安全域的自动机。

定理的直觉形式：

> 把高安全级主体的一切输入"擦掉"之后再跑一遍系统，
> 低安全级主体看到的东西与原来完全一样。

## 22.2 擦除：把高安全级的东西换成默认值

```text
theorem
  erase_zeroes_high: level_of ?p = High \<Longrightarrow> ks_msgs (erase_high ?s) ?p = 0
```

```text
theorem erase_is_idempotent: erase_high (erase_high ?s) = erase_high ?s
```

高的清零、擦两次等于擦一次。低安全级的对象不受影响。

## 22.3 不可区分关系 uwr

两个状态对某个观察者"不可区分"，当且仅当把它们都擦除之后观察者看到的一致：

```text
theorem uwr_transitive: \<lbrakk>uwr ?s ?d ?t; uwr ?t ?d ?u\<rbrakk> \<Longrightarrow> uwr ?s ?d ?u
```

**`uwr` 是等价关系**——这让"低观察者分不出两种高输入"可以被传递地使用。

## 22.4 单步非干扰

```text
theorem low_step_preserves_uwr:
 \<lbrakk>level_of ?k = Low; uwr ?s ?d ?t\<rbrakk> \<Longrightarrow> uwr (step_at ?k ?s) ?d (step_at ?k ?t)
```

注意这条引理把"这一步是谁跑的"写成**显式参数 `k`**。
为什么要这样？因为非干扰比的是两个不同的世界（一个喂了高输入、一个没喂），
要比较就必须要求"这一步在两边是同一个线程跑的"。
写成 `step s` 自己取 `ks_cur s`，就得额外用一条 `ks_cur t = ks_cur s` 去对齐——
而**等式假设在 `simp` 里的重写方向不确定**，会让 `fun_upd` 的 `if` 无法判定，
证明卡在合取式上。把线程号提到参数里，问题就消失了。

真实证明里同样有这一层条件（`confidentiality_u` 一类定理要求两个世界的调度一致）。

## 22.5 归纳到任意长的运行

```text
theorem
  noninterference_for_runs:
    \<lbrakk>\<forall>s t. uwr s ?d t \<longrightarrow> uwr (step s) ?d (step t); uwr ?s ?d ?t\<rbrakk>
    \<Longrightarrow> uwr (run ?n ?s) ?d (run ?n ?t)
```

**单步保持不可区分 ⟹ 任意步保持不可区分**。这就是整章的主定理形状。
真实定理还要处理调度选择、中断、以及"哪些步骤根本不允许发生"（由策略 `pas` 决定），
但骨架就是这条归纳。

---

## 本章坑位清单（实测）

1. **`record` 字段用 `|` 分隔**：`|` 只属于 `datatype`；写进 `record` 报 `Outer syntax error: command expected`。
2. **记录相等用 `rule ext`**：`ext` 只对函数生效，记录相等要用 `cases` 拆字段。
3. **等式假设的方向不确定**：`ks_cur t = ks_cur s` 在 `simp` 里可能不按预期重写；把公共部分提成参数。
4. **`fun_upd` 的 `if` 无法判定**：索引是否相等不知道时 `simp` 会拆成合取式，要显式 `case_tac`。
5. **递归函数终止性**：`run` 用 `fun` 时要让终止顺序可见（实测输出里有 `Found termination order`）。
6. **以为"高安全级线程运行"就是泄漏**：只要擦除后低观察者看不出差别就不是泄漏。
7. **把 `uwr` 当相等**：它是"擦除后相等"，比相等弱得多。
8. **归纳时忘了 `arbitrary:`**：对 `n` 归纳时 `s t` 必须泛化。
9. **裸调 `Suc.IH`**：要用 `Suc.IH[OF Suc.prems(1) step_u]` 显式实例化。
10. **找非干扰证明找错目录**：`l4v/proof/infoflow/`（完整性在 `l4v/proof/access-control/`）。

---

上一章：[21 · 完整性](21-integrity.md) ｜ 下一章：[23 · capDL](23-capdl.md) ｜ 返回：[README](../README.md)
