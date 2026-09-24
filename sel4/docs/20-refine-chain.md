# 20 · 精化链与信任基

对应示例：`../examples/S20_refine_chain.thy`

## 20.1 一条链，四个层次

seL4 的验证不是"证明 C 代码正确"，而是证明一条**精化链**：

<!-- 示意块：非构建产物，不参与输出比对 -->
```text
抽象规范 A ── 设计规范 D/Haskell ── C 规范 cspec ── 汇编/二进制
   (安全定理)      (可执行原型)       (来自 C 源码)   (graph lang)
```

每个箭头都是"我这一步对应你那一步"。链子通了，抽象层上的安全定理
才能**转移到真正跑的二进制上**。

## 20.2 精化的传递性

```text
theorem refines'_reflexive: refines' (=) ?f ?f
```

```text
theorem
  refines'_transitive:
    \<lbrakk>refines' ?R1.0 ?f ?g; refines' ?R2.0 ?g ?h\<rbrakk>
    \<Longrightarrow> refines' (?R1.0 OO ?R2.0) ?f ?h
```

关键是 `OO`（关系复合）：A 与 D 的关系复合上 D 与 C 的关系，就是 A 与 C 的关系。
**这就是为什么每一层只需要证明"和相邻那一层对得上"**。

## 20.3 一个简单的三层链

```text
theorem a_to_c: refines' (rel_ad OO rel_dc) a_inc c_inc
```

这条就是"抽象层的 `a_inc` 与 C 层的 `c_inc` 对得上"，
由 `a_to_d` 与 `d_to_c` 复合而来。

## 20.4 链的两端：性质怎么搬过去

```text
theorem
  abstract_property_transfers:
    \<lbrakk>rel_total ?R; refines' ?R ?f ?g; ?R ?a ?b\<rbrakk> \<Longrightarrow> ?R (?f ?a) (?g ?b)
```

只要关系是"全的"（每个抽象状态都有对应的具体状态），
抽象层上成立的性质就能推到具体层。
**这条是"抽象层证明的安全定理适用于 C 代码"的形式化依据**。

## 20.5 假设清单：读证明之前先看它

```text
theorem parser_is_not_verified: CParser \<in> unverified_assumptions
```

seL4 的诚实之处在于它明确列出**未被验证的假设**：

| 假设 | 是否被验证 |
|---|---|
| C 解析器（把 C 翻译成 Isabelle 项） | **否** |
| 编译器/汇编器 | **否** |
| 硬件行为模型 | 部分 |
| 内核配置 | 是（机器检查） |
| 启动代码、某些手工汇编 | 否 |

`seL4/CAVEATS.md` 里有一份完整清单。**读 seL4 的论文却不读 CAVEATS，等于只听了一半。**

---

## 本章坑位清单（实测）

1. **以为"验证了 C 代码"**：验证的是 C 规范，而它由未验证的解析器翻译而来。
2. **把关系复合写成 `O` 或手写存在量词**：是 `OO`（`relcompp`）。
3. **以为传递性不需要"关系是全的"**：`abstract_property_transfers` 需要 `rel_total`。
4. **把自反性当 `refines' (=) f g`**：自反只保证 `refines' (=) f f`。
5. **忽略汇编/二进制那一层**：最后一环是 `l4v/proof/asmrefine/`。
6. **把假设清单当形式主义**：`seL4/CAVEATS.md` 是定理适用范围的一部分。
7. **以为配置被验证就能随便改内核**：改配置会改变生成的代码，需要重跑整条链。
8. **混淆 `verified_assumptions` 与 `unverified_assumptions`**：两者不相交，但都不是"已证明"。
9. **以为链子是线性的**：架构相关部分各有分支，实际是一棵树。
10. **找汇编精化找错目录**：`l4v/proof/asmrefine/`（不是 `refine/`）。

---

上一章：[19 · C 规范与堆](19-cspec.md) ｜ 下一章：[21 · 完整性](21-integrity.md) ｜ 返回：[README](../README.md)
