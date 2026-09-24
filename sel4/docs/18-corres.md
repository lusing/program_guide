# 18 · 精化关系

对应示例：`../examples/S18_corres.thy`

## 18.1 从抽象规范到设计规范

两个状态机类型不同（抽象状态用记录，具体状态用另一种表示），
要比较它们就得有一座桥：**状态关系**。有了桥，
"A 的这一步被 B 的这一步实现"就可以写成 `corres`。

真实定义在 `l4v/lib/Corres_UL.thy` 与 `l4v/proof/refine/Corres.thy`，
配套方法在 `l4v/lib/Corres_Method.thy`、`l4v/lib/CorresK_Method.thy`。

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
corres rel R m m' ≡ ∀s s'. rel s s' ⟶
    (结果一一对应，且对应结果满足 R) ∧ (A 失败 ⟹ B 也失败)
```

## 18.2 两层状态与状态关系

```text
theorem
  relation_is_functional:
    \<lbrakk>state_relation ?as ?cs; state_relation ?as ?cs'\<rbrakk>
    \<Longrightarrow> \<forall>p. (c_objs ?cs p \<noteq> None) = (c_objs ?cs' p \<noteq> None)
```

同一个抽象状态对应的两个具体状态，在"哪些对象存在"上必须一致，
否则"抽象层说有对象"无法翻译成"具体层某个位置上有东西"。

## 18.3 corres 的定义

```text
theorem
  corres_object_at:
    corres state_relation (=) (a_object_at ?p) (c_object_at ?p)
```

结果关系是"这一层允许有多少信息损失"的旋钮：
查询类操作用 `(=)`（返回值必须相等），创建/删除类用 `(\<lambda>_ _. True)`（只看状态）。

## 18.4 两个操作的对应证明

对应证明的形状是"从一对相关状态出发，跑完两边之后仍然相关，且结果匹配"。

## 18.5 修改类的对应最容易写错的方向

最容易写反的是**失败方向**：具体层可以在抽象层失败时任意发挥，
但抽象层成功时具体层必须给出对应的结果。

## 18.6 非确定性的对应

```text
theorem abstract_failure_admits_any_concrete: refine_result Failed = None
```

**抽象层说"失败"时，具体层做什么都可以**（因为抽象层没有规定失败后的状态）；
反过来，抽象层成功时具体层必须给出结果（`Ok x` ↔ `Some x`）。

> 这条性质直接解释了为什么"内核在某些错误路径上行为随意"不影响验证：
> 那些路径在抽象规范里是失败，具体实现做什么都不违反精化。

---

## 本章坑位清单（实测）

1. **把 `corres` 定义成同类型的关系**：两个状态类型不同，写同类型会直接类型冲突。
2. **结果关系一律写 `(=)`**：无返回值的操作要用 `(\<lambda>_ _. True)`。
3. **忘了"抽象失败 ⟹ 具体任意"**：这条能省掉大量错误路径的证明。
4. **以为对应关系必须集合相等**：是"每个抽象结果有对应的具体结果"。
5. **把状态关系当函数**：它是关系；需要函数性时要单独证。
6. **在精化里直接比较具体状态**：只能通过状态关系间接比较。
7. **忽略非确定性**：具体层的每个选择都要落在抽象层允许的集合内。
8. **手工展开 `corres`**：展开后三样东西同时出现，应该用 `Corres_Method` 分解。
9. **以为精化是等价**：具体层可以比抽象层更确定。
10. **找错文件**：`l4v/lib/Corres_UL.thy` 是定义，`l4v/proof/refine/Corres.thy` 是 seL4 专用引理。

---

上一章：[17 · 不变式](17-invariants.md) ｜ 下一章：[19 · C 规范与堆](19-cspec.md) ｜ 返回：[README](../README.md)
