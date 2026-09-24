# 19 · C 规范与堆

对应示例：`../examples/S19_cspec.thy`

## 19.1 把 C 代码搬进 Isabelle

第 18 章的"具体层"到底是什么？在 seL4 里它是 **C 规范（cspec）**：
把 `seL4/src/` 的 C 源码预处理后，用 C 解析器翻译成 Isabelle 里的单子程序。
翻译结果在 `l4v/spec/cspec/`（`KernelState_C.thy`、`KernelInc_C.thy`，
按架构分目录的生成物在 `l4v/spec/cspec/c/`）。

这一层的关键特征是：**状态是字节堆，不是记录**。

## 19.2 最基础的三条堆定律

```text
theorem load_after_store: load ?a (store ?a ?v ?h) = Some ?v
```

```text
theorem
  load_other_after_store: ?b \<noteq> ?a \<Longrightarrow> load ?b (store ?a ?v ?h) = load ?b ?h
```

写了就能读到、写别处不影响、重复写覆盖。
真实 C 规范里这套由 autocorres 的堆模型提供，比这里的模型严谨得多
（区分类型、对齐、指针有效性）。

## 19.3 一个 C 函数的翻译形态

结构体字段访问被翻译成"堆上的偏移读写"（实测）：

```text
theorem
  set_preserves_other_field:
    ?h ?p = Some ?c \<Longrightarrow>
    cap_word0 (the (cap_set_rights ?p ?v ?h ?p)) = cap_word0 ?c
```

**改一个字段不会影响同一结构体里的其他字段**。
在记录层这是免费的（record 更新天然如此），在堆层要单独证明。

## 19.4 从 C 回到设计规范：c_corres

```text
theorem
  c_matches_d:
    ?h ?p = Some ?c \<Longrightarrow>
    cap_get_rights ?p ?h = Some (d_get_rights (dcap_of ?c))
```

C 堆里某个地址上的权利字段，等于设计规范里那个能力的权利。
真实代码里这一层对应由 autocorres 生成的定理与
`l4v/proof/crefine/` 下的证明共同完成（`Move_C.thy`、`base/`、`intermediate/`）。

## 19.5 翻译不是"信它没错"

因为**真正跑的是 C**。抽象规范与设计规范再漂亮，如果 C 的行为和它们不一致，
证明就是自娱自乐。cspec 把"C 源码做了什么"变成可推理的 Isabelle 项，
才让"证明一直连到源码"成为可能。

---

## 本章坑位清单（实测）

1. **把 C 规范的手写模型当真**：教程里 `load`/`store` 是模型，真实的是 autocorres 生成的堆模型。
2. **以为结构体字段更新是免费的**：在堆层"改一个字段不动其他字段"要单独证明。
3. **忘了地址可能未映射**：读取要有 `h p ≠ None` 的前提。
4. **把字节当结构化值**：类型化视图是叠加在字节上的解释。
5. **以为 `store` 会保留旧值**：是覆盖。
6. **忽略对齐**：真实的 C 堆模型对未对齐访问给出未定义行为。
7. **在 cspec 层直接复用抽象层的引理**：两个状态类型不同，必须走 `corres`。
8. **以为 C 解析器是被验证的**：它不是（第 20 章把 CParser 列为未验证假设）。
9. **找 C 规范找错地方**：`l4v/spec/cspec/`（生成物在 `l4v/spec/cspec/c/`），不是 `l4v/proof/crefine/`。
10. **把 `the (…)` 当安全操作**：它在 `None` 上未定义，使用时要带 `h p ≠ None`。

---

上一章：[18 · 精化关系](18-corres.md) ｜ 下一章：[20 · 精化链与信任基](20-refine-chain.md) ｜ 返回：[README](../README.md)
