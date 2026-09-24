# 21 · 完整性

对应示例：`../examples/S21_integrity.thy`

## 21.1 完整性：没人能在没被授权时改动别人的东西

seL4 的第一个安全定理叫 **完整性（integrity）**，在 `l4v/proof/access-control/`：
`Syscall_AC.thy` 是总定理，`CNode_AC.thy`、`Ipc_AC.thy`、`Finalise_AC.thy`、
`Retype_AC.thy` 分别证明"每一类系统调用都保持完整性"。

定理的直觉形式：

> 如果一次状态变化不被某个主体的 authority 授权，那么该主体**可观察到的**那部分状态没有变化。

注意"可观察到"四个字：**完整性不是"状态没变"，而是"对该主体而言没变"**。

## 21.2 权威（authority）与可观察部分

```text
theorem
  no_cap_no_authority: ks_caps ?s (?x, 0) = None \<Longrightarrow> authority ?s ?x = {}
```

没有能力就没有权威；有能力但是 `NullCap` 同样没有权威。
而"写授权"要求权利里真的有 `AllowWrite`（实测）：

```text
theorem
  read_only_is_not_write_authority:
    ks_caps ?s (?x, 0) = Some (EndpointCap ?p {AllowRead}) \<Longrightarrow>
    \<not> authorised ?s ?x ?p
```

只读能力**不授权写入**——看着显然，但它是整条完整性链的起点。

## 21.3 完整性谓词

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
integrity s x s' ≡ ∀p. ks_data s' p ≠ ks_data s p ⟶ authorised s x p
```

凡是发生了变化的对象，主体必须有写授权。
真实定义（`l4v/proof/access-control/Access.thy`）比这复杂：
它区分"哪些状态分量算可观察"、区分"直接写"与"通过能力间接写"。

## 21.4 删除只会减少权威

```text
theorem
  delete_reduces_authority:
    authority (delete_cap ?sl ?s) ?x \<subseteq> authority ?s ?x
```

**删能力不会让任何人获得新的权威**。这是"删除是安全操作"的形式化说法。

## 21.5 派生不增加权威

```text
theorem
  mint_cannot_escalate:
    AllowWrite \<notin> cap_rights_of ?c \<Longrightarrow> AllowWrite \<notin> cap_rights_of (mint ?R ?c)
```

这就是第 03 章"掩码不增权"在安全语言里的说法：**没有写权利的人，派生不出写权利**。
整条完整性证明链的最后一步都会落到这一类"权利不增长"的引理上。

---

## 本章坑位清单（实测）

1. **槽位类型写成 `nat` 却按二元组使用**：`cslot` 是 `obj_ref × cnode_index`，写 `type_synonym cslot = nat` 后再写 `ks_caps s (x, 0)` 会报类型冲突。
2. **把"可观察"漏掉**：完整性比的是该主体可见的那部分状态，不是全状态相等。
3. **把 `authority` 与 `authorised` 混用**：前者是 `(对象 × 权利)` 的集合，后者是谓词。
4. **以为只读能力授权写入**：实测 `read_only_is_not_write_authority`。
5. **以为删除会改变别人的权威**：`delete_reduces_authority` 说明只会减少。
6. **以为 mint 能提权**：`mint_cannot_escalate` 明确禁止。
7. **把主体（subject）当线程**：它是"责任的归属单位"，模型里可以就是一个对象 id。
8. **在证明里展开 `authority` 的集合概括**：会引入三重存在量词，用成员引理代替。
9. **忽略 `NullCap`**：空能力的权威是空集，但它**存在**——与"槽里没有能力"是两种情形。
10. **找完整性证明找错目录**：`l4v/proof/access-control/`（信息流在 `l4v/proof/infoflow/`）。

---

上一章：[20 · 精化链与信任基](20-refine-chain.md) ｜ 下一章：[22 · 非干扰](22-infoflow.md) ｜ 返回：[README](../README.md)
