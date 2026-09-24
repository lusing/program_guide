# 10 · 解码器

对应示例：`../examples/S10_decode.thy`

## 10.1 decode：把用户字变成内核结构

用户只能传机器字。解码器（`decode_*_invocation`）负责把它们翻译成
一个类型安全的结构化请求。它是**安全边界**：所有越界、非法组合、权利膨胀，
都必须在这里被挡住。真实代码：`l4v/spec/abstract/Decode_A.thy`，
调用标签在 `l4v/spec/abstract/InvocationLabels_A.thy`。

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

## 10.4 extra caps：随消息带来的能力

IPC 可以附带"额外能力"（把能力随消息一起传过去）。槽号 0 表示"这一项没有"，
而且一旦出现 0，整个列表被丢弃（实测）：

```text
theorem
  bad_extra_cap_drops_all: 0 \<in> set ?cptrs \<Longrightarrow> get_receive_slots ?cptrs = []
```

**"全有或全无"是刻意的**：部分成功会给调用者带来歧义。

---

## 本章坑位清单（实测）

1. **给越界标签留"默认分支"**：规范里没有默认分支，越界一律 `InvalidInvocation`。
2. **先取参数再查长度**：`2 ≤ length args` 必须是取 `args ! 0` 的前提。
3. **以为 `mask_cap` 在解码阶段可以省略**：省略就等于"要多少给多少"，越权通道由此打开。
4. **把 `move` 当成也做掩码**：`move` 是 `mask UNIV`，权利不变。
5. **把"槽号 0"当成普通槽**：它是"没有额外能力"的哨兵，出现即整表丢弃。
6. **前提写成 `length args < 2` 还是 `2 ≤ length args` 搞反**：两条互补，写反会得到矛盾前提。
7. **把解码结果 `DError` / `DResult` 当异常**：它们是普通构造子，用 `case` 处理。
8. **以为标签是字符串或枚举**：规范里它是机器字，靠 `gen_invocation_type` 转换。
9. **忽略 `dc_dest_slot` 这类上下文字段**：解码结果里带着已解析好的槽，重复解析会产生不一致。
10. **找 C 侧解码找错地方**：CNode 的解码在 `seL4/src/object/cnode.c`，入口分发在 `seL4/src/api/syscall.c`。

---

上一章：[09 · 系统调用入口](09-syscall-entry.md) ｜ 下一章：[11 · IPC](11-ipc.md) ｜ 返回：[README](../README.md)
