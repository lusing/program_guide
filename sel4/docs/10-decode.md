# 10 · 解码器

对应示例：`../examples/S10_decode.thy`

## 10.1 decode：把用户字变成内核结构

用户只能传机器字。解码器（`decode_*_invocation`）负责把它们翻译成
一个类型安全的结构化请求。它是**安全边界**：所有越界、非法组合、权利膨胀，
都必须在这里被挡住。真实代码：`l4v/spec/abstract/Decode_A.thy`，
调用标签在 `l4v/spec/abstract/InvocationLabels_A.thy`（`gen_invocation_type` 在第 26 行）。

## 10.2 一次完整的 CNode 解码

标签是一个整数，超出范围映射到 `InvalidInvocation`（实测）：

```text
theorem label_out_of_range: gen_invocation_type 7 = InvalidInvocation
```

```text
theorem
  decode_bad_label:
    gen_invocation_type ?label = InvalidInvocation \<Longrightarrow>
    decode_cnode_invocation ?label ?args ?ctx = DError IllegalOperation
```

**越界标签不会落到"默认分支"去执行某个操作**——这是很多 C 代码会犯的错，
seL4 的规范里没有默认分支这种东西。

参数个数不足就报 `TruncatedMessage`（实测）：

```text
theorem
  decode_truncated:
    \<lbrakk>gen_invocation_type ?label = CNodeCopy; length ?args < 2\<rbrakk>
    \<Longrightarrow> decode_cnode_invocation ?label ?args ?ctx = DError TruncatedMessage
```

注意前提与取值的关系：**先确认参数够，才去取 `args ! 0`、`args ! 1`**，顺序反了就是越界读。

## 10.3 权利：解码之后必须掩码

```text
theorem
  minted_rights_subset_of_request:
    cap_rights_of (mask_cap ?R (EndpointCap ?p ?b ?R')) \<subseteq> ?R
```

派生出来的权利是"请求 ∩ 原有"。第 03 章那条"掩码不增权"在这里
以**解码器输出**的形式又出现了一次。

## 10.4 接收窗口与 extra caps：全有或全无

这是两条不同的通道，教程初稿把它们混成了一条：

* **发送方**随消息带来的 extra caps：`lookup_extra_caps`（`Ipc_A.thy` 第 64 行）
  把消息缓冲里的每个 CPtr 在**发送者**的 CSpace 里解析一遍（`mapME` 配
  `lookup_cap_and_slot`）。第 212 行调用它时写的是
  `if grant then lookup_extra_caps sender sbuf mi <catch> K (return [])`——
  没有 grant 就一个都不传，解析中途失败就把整表清空。
* **接收方**的接收窗口：`get_receive_slots`
  （`l4v/spec/abstract/CSpace_A.thy` 第 292 行）只解析**一个**槽，
  而且要求那个槽当下就是 `NullCap`，整段被 `empty_on_failure` 包着。

模型保留两边共有的性质（实测）：

```text
theorem
  receive_window_holds_at_most_one_slot: length (get_receive_slots ?r) \<le> 1

theorem filled_target_yields_no_window: get_receive_slots AlreadyFilled = []

theorem failed_lookup_yields_no_window: get_receive_slots NotFound = []

theorem
  only_a_clean_resolve_yields_a_slot:
    (get_receive_slots ?r = [?s]) = (?r = Resolved ?s)
```

**"部分成功"在这套接口里根本没有表示**：要么给出那一个槽，要么什么都没有。
宁可少给，不可多给。

---

## 官方教程对照

官方 [mapping](https://docs.sel4.systems/Tutorials/mapping.html) 与
[fault-handlers](https://docs.sel4.systems/Tutorials/fault-handlers.html) 两页
（抓取日期 2026-09-25）都要求读者"看懂解码失败报回来的是什么"，
但两边用的是**两套不同的 MR 编号**，官方文档从没把它们并排放在一起。
本章的解码模型正好是它们的公共上层。

**1. CapFault 的 MR 下标是一份枚举，而且有两项故意撞号。**
`seL4_CapFault_IP` 等下标（`seL4/libsel4/include/sel4/shared_types.h:22--31`）：

```c
    seL4_CapFault_IP,
    seL4_CapFault_Addr,
    seL4_CapFault_InRecvPhase,
    seL4_CapFault_LookupFailureType,
    seL4_CapFault_BitsLeft,
    seL4_CapFault_DepthMismatch_BitsFound,
    seL4_CapFault_GuardMismatch_GuardFound = seL4_CapFault_DepthMismatch_BitsFound,
    seL4_CapFault_GuardMismatch_BitsFound,
```

第 28 行那个 `=` **不是笔误**：guard mismatch 的 `GuardFound` 与 depth mismatch 的
`BitsFound` 共用 5 号槽。含义由 `LookupFailureType` 决定——
**这就是 10.1 节"解码结果依赖标签"的字面实现**：同一段字节，标签不同读法不同。

**2. 内核写完这些槽之后，用 `assert` 自查编号没漂。**
`setMRs_lookup_failure`（`seL4/src/api/faults.c:28--72`）里紧跟着

```c
    /* check constants match libsel4 */
    if (offset == seL4_CapFault_LookupFailureType) {
        assert(offset + 1 == seL4_CapFault_BitsLeft);
```

`seL4/src/api/faults.c:37--42` 那段自查（`assert`）把"C 内核与 libsel4 头文件的
对应关系"**写成了可执行断言**。本章 10.2 的解码顺序在 C 侧不是靠人记住的。

**3. 有一类失败连 `BitsLeft` 都没有。** `lookup_fault_invalid_root`
（`seL4/src/api/faults.c:47--48`）直接返回，不写后续 MR。
另外 `lufType` 平移一位（`seL4/src/api/faults.c:35`）：
用户侧枚举 `seL4_NoFailure = 0` 把 0 号占了
（`seL4/libsel4/include/sel4/constants.h:64--70`），
内核内部的 0 基类型要 `+1` 才对得上。
**"解码字段的数量随标签变化"这件事，在这里是三段代码而不是一个定理**。

**4. 映射失败另有一套编号。** `seL4_MappingFailedLookupLevel`
的全部实现就是 `return seL4_GetMR(SEL4_MAPPING_LOOKUP_LEVEL);`
（`seL4/libsel4/sel4_arch_include/aarch64/sel4/sel4_arch/mapping.h:14--17`），
`SEL4_MAPPING_LOOKUP_LEVEL` 在六个 arch 里都取 2；
`SEL4_MAPPING_LOOKUP_NO_PT`（`seL4/libsel4/sel4_arch_include/aarch64/sel4/sel4_arch/mapping.h:9--12`）
这类"缺哪一级"的常数则**逐 arch 不同**：aarch64 是 21/30/39，
ia32 只有 `NO_PT 22`（两级页表），x86_64 第三级叫 `NO_PDPT` 而不是官方
mapping 页里那个 `NO_PD`，aarch32 有两档 `NO_PT`（21 或 20，按配置）。
**照抄官方页里的名字前先确认 arch**——那一页的示例是 x86 的。

> 一处我**没有**核实的东西，写在这里以免被误读：
> `SEL4_MAPPING_LOOKUP_LEVEL` 指向 MR 2，而通用枚举里 MR 2 叫
> `seL4_CapFault_InRecvPhase`。两者是否同槽复用、内核在映射失败时往 MR 2
> 写了什么，我在本树里没有查到直接证据（`grep -rn "MAPPING_LOOKUP" src/ include/`
> 零命中，这些名字只活在 libsel4 侧）。
> **本教程不为此下结论**，请自己按第 19 章的办法去 C 规范里找写入点。

**5. 额外能力的窗口也是解码的一部分。** `seL4_MsgMaxExtraCaps`
（`seL4/libsel4/include/sel4/constants.h:58`）等于 `BIT(2)-1 = 3`，
`seL4_MsgMaxLength = 120`（`seL4/libsel4/include/sel4/constants.h:52--56`）。
10.4 节"全有或全无"在 C 侧对应 `lookupExtraCaps`
（`seL4/src/api/syscall.c:337`）——它失败时**整条调用改成 fault**，
不会"少传两个 cap 继续跑"。

---

## 本章坑位清单（实测）

1. **给越界标签留"默认分支"**：规范里没有默认分支，越界一律 `InvalidInvocation`。
2. **先取参数再查长度**：`2 ≤ length args` 必须是取 `args ! 0` 的前提。
3. **以为 `mask_cap` 在解码阶段可以省略**：省略就等于"要多少给多少"，越权通道由此打开。
4. **把 `move` 当成也做掩码**：`move` 是 `mask UNIV`，权利不变。
5. **以为接收窗口是一串槽**：真实 `get_receive_slots` 只给一个（`returnOk [slot]`），且要求目标槽是 `NullCap`。
6. **前提写成 `length args < 2` 还是 `2 ≤ length args` 搞反**：两条互补，写反会得到矛盾前提。
7. **把解码结果 `DError` / `DResult` 当异常**：它们是普通构造子，用 `case` 处理。
8. **以为标签是字符串或枚举**：规范里它是机器字，靠 `gen_invocation_type` 转换。
9. **忽略 `dc_dest_slot` 这类上下文字段**：解码结果里带着已解析好的槽，重复解析会产生不一致。
10. **找 C 侧解码找错地方**：CNode 的解码在 `seL4/src/object/cnode.c`，入口分发在 `seL4/src/api/syscall.c`。

---

上一章：[09 · 系统调用入口](09-syscall-entry.md) ｜ 下一章：[11 · IPC](11-ipc.md) ｜ 返回：[README](../README.md)
