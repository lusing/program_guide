# 03 · 权利与掩码

对应示例：`../examples/S03_rights.thy`

## 3.1 权利就是一个集合

seL4 的能力权利是一个集合：`AllowRead`、`AllowWrite`、`AllowGrant`、`AllowGrantReply`
（`l4v/spec/abstract/CapRights_A.thy:19`，`cap_rights = rights set` 在第 29 行）。
别被"四个位"骗了：其中三个只是**别名**，同一个位在不同能力上换名字叫法（同文件第 22–26 行）：

<!-- 源码块：l4v/spec/abstract/CapRights_A.thy:21-26 -->
```text
definition
  "AllowSend \<equiv> AllowWrite"
definition
  "AllowRecv \<equiv> AllowRead"
definition
  "CanModify \<equiv> AllowWrite"
```

所以"端点要有 Send 权利"和"端点要有 Write 权利"是**同一句话**——不存在第五个位。

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

页表/页帧的映射权利（`l4v/spec/abstract/VMRights_A.thy`）与上面那套**是同一个类型**——
第 19 行就一行 `type_synonym vm_rights = cap_rights`。
类型相同意味着编译器不会拦你，出事只能靠下面的合法性检查（实测）：

```text
theorem validate_always_valid: validate_vm_rights ?R \<in> valid_vm_rights
```

```text
theorem mask_vm_always_valid: mask_vm_rights ?V ?R \<in> valid_vm_rights
```

```text
theorem write_only_is_not_valid: {AllowWrite} \<notin> valid_vm_rights
```

合法组合会被压回三种之一（实测）：

```text
theorem
  write_only_becomes_kernel_only:
    validate_vm_rights {AllowWrite} = vm_kernel_only
```

`valid_vm_rights = {vm_read_write, vm_read_only, vm_kernel_only}`
（`VMRights_A.thy:43`），**"只写"不合法**；而内核的处理不是报错，是**静默降级**。
真实定义（`VMRights_A.thy:57`）：

<!-- 源码块：l4v/spec/abstract/VMRights_A.thy:57-57 -->
```text
  "mask_vm_rights V R \<equiv> validate_vm_rights (V \<inter> R)"
```

所以 VM 侧的掩码是"交集 + 再压一次"，两步缺一不可——只做交集就会漏出 `{AllowWrite}`。
你请求了写，得到的是"什么都干不了"。这是真实且反直觉的行为。

## 3.4 从数据字解码权利

用户传进来的是一个机器字，内核先把它解码成权利集合，再掩码（实测）：

```text
theorem decode_subset_of_all: data_to_rights ?w \<subseteq> all_rights
```

**解码得到的权利一定先被 `all_rights` 约束住**——这是"用户传什么位都不能凭空造出权利"的第一道闸。
真实代码：`l4v/spec/abstract/CSpace_A.thy:57` 的 `data_to_rights`
（`l4v/spec/abstract/Decode_A.thy` 第 72 行才调用它），
位序**不是**枚举的书写顺序（`l4v/spec/abstract/CSpace_A.thy:60` 的 `data_to_rights`）；
C 侧的位定义在 `seL4/libsel4/include/sel4/shared_types.h`（`seL4_CanRead` 等）。

<!-- 源码块：l4v/spec/abstract/CSpace_A.thy:60-63 -->
```text
   in {x. case x of AllowWrite \<Rightarrow> w !! 0
                  | AllowRead \<Rightarrow> w !! 1
                  | AllowGrant \<Rightarrow> w !! 2
                  | AllowGrantReply \<Rightarrow> w !! 3}"
```

第 0 位是 Write、第 1 位才是 Read；且解码只取 `data_to_16`，**4 位以上全部丢弃**。

---

## 官方教程对照

官方 [capabilities](https://docs.sel4.systems/Tutorials/capabilities.html) 一节
（抓取日期 2026-09-25）把权利讲成一句规则："能力有一份权利集合，派生时只能削不能加"。
方向完全对，但它给的是**用户视角**；下面四条是 C 侧的实现细节，
恰好解释了为什么本章要把权利建模成集合。

**1. 权利是四个独立的位，不是数学上的集合。** `seL4_CapRights`
（`seL4/libsel4/mode_include/32/sel4/shared_types.bf` 第 18--24 行）是
`padding 28` 之后接 `capAllowGrantReply`、`capAllowGrant`、`capAllowRead`、
`capAllowWrite` 各一位；64 位那版（`seL4/libsel4/mode_include/64/sel4/shared_types.bf`）
只是 `padding 32`，四个字段一模一样。也就是说**跨 arch 权利位永远是最低那 4 位**，
这条不变量 l4v 的 `rights set` 抽象是看不出来的。

**2. 参数顺序要从常量倒推。** `seL4_AllRights`
（`seL4/libsel4/include/sel4/shared_types.h` 第 33--41 行）那组定义写成

```c
#define seL4_ReadWrite     seL4_CapRights_new(0, 0, 1, 1)
#define seL4_CanRead       seL4_CapRights_new(0, 0, 1, 0)
#define seL4_CanWrite      seL4_CapRights_new(0, 0, 0, 1)
```

生成器 `bitfield_gen.py` 按 `.bf` 里字段从高位到低位的顺序收参数，
所以 `seL4_CapRights_new(grant_reply, grant, read, write)`：**read 是倒数第二位，
write 是最低位**。同一批常量里还有官方教程没提的 `seL4_NoWrite` 与 `seL4_NoRead`
（各三个 1、把对应那一位写成 0），它们是"少给一位"的现成写法，
比手写 `new(1, 1, 1, 0)` 可读。

**3. 掩码落到具体能力上是"逐类型改位"。** `maskCapRights`
在 `seL4/src/object/objecttype.c:441`，对端点做的正是

```c
        new_cap = cap_endpoint_cap_set_capCanSend(
                      cap, cap_endpoint_cap_get_capCanSend(cap) &
                      seL4_CapRights_get_capAllowWrite(cap_rights));
```

`AllowWrite → CanSend`、`AllowRead → CanReceive` 就是 3.1 节那两条
`AllowSend ≡ AllowWrite` / `AllowRecv ≡ AllowRead` 别名的 C 实现。
**"交集语义"在这里是字面上的 `&`**，本章 3.2 的定理不是类比。

**4. 权利不够时，用户态拿到的往往不是错误码，而是一条 fault。**
非 MCS 的 fastpath 发端点前先查 `cap_endpoint_cap_get_capCanSend`
（`seL4/src/fastpath/fastpath.c:49--51`），不满足就 `slowpath(SysCall)`；
到了 slowpath，缺 receive 权直接构造 `seL4_Fault_CapFault_new`
（`seL4/src/api/syscall.c:469--473`，第二个实参 `true` 表示 inReceivePhase）。
这条就是第 09 章"fault 优先级高于 error"的 C 版原型：**权利的失败通道是异常，
不是返回值**，只会 `if (res != 0) printf("error")` 的代码看不到这类问题。

> 两边的抽象层次差：l4v 用一个 `cap_rights` 类型统一四类能力，
> C 把权利位嵌进每种能力各自的字里、位置和个数都不同（通知只有两位，见第 02 章第 4 条）。
> 把 l4v 的定理"翻译"成 C 侧断言时，先问"这个权利在哪种能力上有哪一位"。

---

## 本章坑位清单（实测）

1. **把掩码写成并集或差集**：必须是交集；写成并集就等于"可以越权"。VM 侧还要在交集后再 `validate_vm_rights` 压一次。
2. **以为 `derive_cap` / mint 能增加权利**：只能削。
3. **幂等定理换参数就不成立**：`mask (mask R R') R'` 才幂等。
4. **以为 VM 权利与 cap 权利是两个类型**：`vm_rights` 只是 `cap_rights` 的别名（`l4v/spec/abstract/VMRights_A.thy:19`），类型层完全不加区分；合法性只靠另一个集合把关。
5. **以为非法组合会报错**：`{AllowWrite}` 不合法时是静默降级为 `vm_kernel_only`。
6. **按 `rights` 枚举顺序猜位序**：真实位序是 0=Write、1=Read、2=Grant、3=GrantReply（`CSpace_A.thy:60`），与枚举书写顺序相反。
7. **记反单调性的方向**：掩码结果随"请求的权利"单调，不是随被遮的权利单调。
8. **把 `AllowSend`/`AllowRecv`/`CanModify` 当成额外权利**：它们是 `CapRights_A.thy:22` 起的别名（分别 = `AllowWrite`/`AllowRead`/`AllowWrite`），权利始终只有四个位。
9. **在证明里展开 `UNIV`**：会展开四个构造子，目标立刻膨胀；用集合包含推。
10. **以为"权利检查失败会返回错误码"**：很多情况是降级/截断，只有解码阶段才产生 `IllegalOperation`。
11. **别去 l4v 里找 no_rights**：这一版规范只定义了 `all_rights`（`l4v/spec/abstract/CapRights_A.thy:32`），空集直接写 `{}`。`no_rights` 是本教程模型自己起的名。

---

上一章：[02 · 内核对象与能力](02-kernel-objects.md) ｜ 下一章：[04 · CSpace 与地址解析](04-cspace.md) ｜ 返回：[README](../README.md)
