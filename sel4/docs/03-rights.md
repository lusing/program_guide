# 03 · 权利与掩码

对应示例：`../examples/S03_rights.thy`

## 3.1 权利就是一个集合

seL4 的能力权利是一个集合：`AllowRead`、`AllowWrite`、`AllowGrant`、`AllowGrantReply`
（`l4v/spec/abstract/CapRights_A.thy`）。

`AllowGrant` 是其中最关键的一个：它决定"你能不能把这份能力再转给别人"。
没有 `AllowGrant` 的能力是**死路**——你能用，但不能扩散。
整个能力系统的 confinement（能力不会越界扩散）性质就建立在这个位上。

## 3.2 掩码：派生时削权

```text
theorem mask_never_grows: S03_rights.mask ?R ?R' \<subseteq> ?R
```

掩码就是取交集，只缩不放。第 05 章会把它升级成 `mint_never_grows`，
第 21 章再升级成 `mint_cannot_escalate`——**"权利不增长"是本教程最重要的一条不变量**，
它在不同抽象层被重复证明了三次。

## 3.3 虚拟内存权利：交集可能不合法

页表/页帧的映射权利（`l4v/spec/abstract/VMRights_A.thy`）与上面那套**不是同一个类型**：

```text
theorem validate_always_valid: validate_vm_rights ?R \<in> valid_vm_rights
```

```text
theorem write_only_is_not_valid: {AllowWrite} \<notin> valid_vm_rights
```

合法组合只有三种：`vm_kernel_only`、`vm_read_only`、`vm_read_write`。
**"只写"不合法**，而内核的处理不是报错，是**静默降级**（实测）：

```text
theorem
  write_only_becomes_kernel_only:
    validate_vm_rights {AllowWrite} = vm_kernel_only
```

你请求了写，得到的是"什么都干不了"。这是真实且反直觉的行为。

## 3.4 从数据字解码权利

用户传进来的是一个机器字，内核先把它解码成权利集合，再掩码（实测）：

```text
theorem decode_subset_of_all: data_to_rights ?w \<subseteq> all_rights
```

**解码得到的权利一定先被 `all_rights` 约束住**——这是"用户传什么位都不能凭空造出权利"的第一道闸。
真实代码：`l4v/spec/abstract/Decode_A.thy` 的 `data_to_rights`，
位定义在 `seL4/libsel4/include/sel4/shared_types.h`（`seL4_CanRead` 等）。

---

## 本章坑位清单（实测）

1. **把掩码写成并集或差集**：必须是交集；写成并集就等于"可以越权"。
2. **以为 `derive_cap` / mint 能增加权利**：只能削。
3. **幂等定理换参数就不成立**：`mask (mask R R') R'` 才幂等。
4. **把 VM 权利和 cap 权利混用**：`vm_read_write` 与 `cap_rights` 是两个类型。
5. **以为非法组合会报错**：`{AllowWrite}` 不合法时是静默降级为 `vm_kernel_only`。
6. **忽略 `data_to_rights` 的位序耦合**：位的排列与 `rights` 枚举顺序绑定。
7. **记反单调性的方向**：掩码结果随"请求的权利"单调，不是随被遮的权利单调。
8. **`no_rights` 与 `{}` 是否等价要看定义**：证明里常需要一步 `simp` 对齐。
9. **在证明里展开 `UNIV`**：会展开四个构造子，目标立刻膨胀；用集合包含推。
10. **以为"权利检查失败会返回错误码"**：很多情况是降级/截断，只有解码阶段才产生 `IllegalOperation`。

---

上一章：[02 · 内核对象与能力](02-kernel-objects.md) ｜ 下一章：[04 · CSpace 与地址解析](04-cspace.md) ｜ 返回：[README](../README.md)
