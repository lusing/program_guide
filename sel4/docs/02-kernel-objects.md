# 02 · 内核对象与能力

对应示例：`../examples/S02_kernel_objects.thy`

## 2.1 内核对象：seL4 里只有"对象 + 能力"

两个容易混的概念，必须一开始就分开：

- **内核对象（kernel object）**：端点、通知、TCB、CNode、页表、Untyped 内存。看 `l4v/spec/abstract/Structures_A.thy` 的 `kernel_object` 与 `apiobject_type`。
- **能力（capability）**：指向某个对象的"钥匙"，带权利。

对象只有一个，指向它的能力可以有很多份，且每份的权利不同。
**销毁能力不等于销毁对象，销毁对象也不等于能力凭空消失**（后者变成 `NullCap`）。
这一条是第 06 章"回收"与第 15 章"再类型化"全部复杂度的来源。

## 2.2 能力的数据类型

`cap` 是一个大的和类型：每种对象对应一个构造子，
带权利的构造子（`EndpointCap`、`NotificationCap`、页相关能力）才带一个 `rights set`；
不带权利的构造子（`NullCap`、`UntypedCap`、`Zombie`…）没有这个字段。

> 由此产生一个真实陷阱：l4v 的 `cap_rights` **选择子**对不带权利的构造子返回 `UNIV`，
> 不是 `{}`。判断"这个能力有没有某权利"要看语义，不能只看选择子。

## 2.3 对象被创建时得到的"原始能力"

新对象被创建出来时，拿到的是一份**默认能力**。默认权利表是内核的策略（实测）：

```text
theorem
  ep_default_has_all_rights:
    cap_rights_of (default_cap EndpointObject ?p ?sz) = UNIV
```

```text
theorem
  ntfn_default_cannot_grant:
    AllowGrant \<notin> cap_rights_of (default_cap NotificationObject ?p ?sz)
```

端点默认给全部权利；通知默认**不给** `AllowGrant`
（防止默认就把通知能力转送出去）。真实代码见 `l4v/spec/abstract/Retype_A.thy` 的 `default_cap`，
对象类型枚举在 `seL4/libsel4/include/sel4/objecttype.h`。

## 2.4 对象的大小

对象大小由 `obj_bits_api` 按"类型 + 请求位数"算出（实测）：

```text
theorem cnode_needs_more_than_asked: ?sz < obj_bits_api CapTableObject ?sz
```

CNode 会比请求多出一个 slot 的位数（内部还要存 guard/尺寸等元数据）。
**不要假设"请求多少位就占多少位"**——否则第 15 章的 Untyped 分配账目永远对不上。

## 2.5 内核堆：对象表

`kheap` 是从对象引用到对象的部分函数（实测）：

```text
theorem alloc_hit: alloc ?p ?t ?h ?p = Some ?t
```

这类"命中/落空"配对的引理，在 seL4 的证明里出现频率极高——
几乎每一条不变式证明都要先说清"我没碰的地方没变"。

真实代码：`l4v/spec/abstract/KHeap_A.thy`；C 侧对象实现在
`seL4/src/object/cnode.c`、`seL4/src/object/endpoint.c`。

---

## 本章坑位清单（实测）

1. **把 `cap_rights` 选择子当"没有 rights 字段就返回空"**：l4v 里返回的是 `UNIV`，要看语义。
2. **以为默认权利越多越好**：通知默认不给 `AllowGrant` 是刻意的安全策略。
3. **假设 `obj_bits_api` 等于请求位数**：CNode 会多一个 slot。
4. **记错构造子字段顺序**：`UntypedCap p sz f` 里第三个是 `freeIndex`（已分配水位），不是大小。
5. **拿 `UNIV` 当"所有权利"直接展开**：`simp` 会展开四个构造子，证明状态瞬间爆炸。
6. **不同 `record` 用同名字段**：引用时写限定名（`ks_caps s` 而不是裸 `ks_caps`）。
7. **`record` 字段之间写 `|`**：`|` 只是 `datatype` 构造子的分隔符，写进 `record` 报 `Outer syntax error: command expected`。
8. **把"能力数量"当"对象数量"**：一个对象可被任意多能力指向；销毁对象后能力变成 `NullCap` 而不是消失。
9. **在 ML 里对集合求值**（如 `card all_rights`）：求值器处理不了，改用打印定理。
10. **在 ML 字符串里写 Unicode 符号**（如 `⊂`）：ML 层不认，写 ASCII 的 `<` / `<=`。

---

上一章：[01 · 开场](01-overview.md) ｜ 下一章：[03 · 权利与掩码](03-rights.md) ｜ 返回：[README](../README.md)
