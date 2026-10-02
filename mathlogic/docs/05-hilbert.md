# 05 Hilbert 系统与演绎定理

> 对书：Mendelson §1.4 / Ben-Ari 3e §3.3 / 2e §3.5（proof checker 思路）

Mendelson 的系统 L：三条公理模式 + 一条推理规则（MP）——

```
A1  p → (q → p)
A2  (p → (q → r)) → ((p → q) → (p → r))
A3  (¬q → ¬p) → (p → q)
MP  从 p → q 与 p 得 q
```

本章把「演算」本身变成研究对象：**推导关系用归纳定义**（hyp/ax/mp
三个构造子），演绎定理对推导结构归纳——「元定理」的标准机器证法。

## 演绎定理

```
derives (p :: Γ) q → derives Γ (p → q)
```

三分支：

- **hyp**：若 q = p，输出 identity（p→p 的五步 A1/A2 组合，
  组合子视角就是 I = SKK）；若 q ∈ Γ，A1 一步弱化（weakK）；
- **ax**：公理无所谓上下文——weakK 白送；
- **mp**：A2 的「柯里化分配」两步接力：
  `(p→(r→A)) → ((p→r)→(p→A))`，MP 吃 IH₁ 再吃 IH₂。

## identity = SKK

```
s1 = A1 p (p→p)            p → ((p→p) → p)
s2 = A2 p (p→p) p          (s1 的形) → ((p → (p→p)) → (p→p))
s3 = MP s2 s1              (p → (p→p)) → (p→p)
s4 = A1 p p                p → (p→p)
s5 = MP s3 s4              p → p
```

## 深浅两种嵌入

- **深嵌入**（Coq/Agda/Lean/Isabelle）：语言是 datatype，推导是归纳
  谓词，元定理对推导归纳——演绎定理是真的定理；
- **浅嵌入**（HOL4）：公理模式直接是内核定理，MP 是 `MATCH_MP`，
  而 →I 长在内核规则 `DISCH` 上——演绎定理「免费」。这正是 LCF
  设计哲学：元规则即内核规则。

## 坑位速记

- **Coq**：`induction H as [A HIn | A HAx | r A H1 IH1 H2 IH2]`——
  dMP 的 IH 跟在各自递归参数后面；identity 要在**任意上下文**立
  （演绎定理的假设分支要用，不只是 `[]`）。
- **Lean**：构造子的 intro 模式是「全部字段在前、IH 在后」：
  `| @mp r A h₁ h₂ ih₁ ih₂`（写成 h₁ ih₁ h₂ ih₂ 会张冠李戴）；
  `@` 前缀具名隐式。
- **Agda**：函数级隐式 {Γ p} 必须在子句里具名绑定
  （`deduction {Γ} {p} (mp …)`）——子句体看不见未绑定的隐式。
- **Isabelle**：`inductive derives for Γ` 把上下文钉成参数；
  公理模式用 `definition + ∃`（fun 的模式写不了结构等式）；
  dMP 分支 `with dMP … by (metis derives.dMP)`——把 A2 实例 s2
  与全部 IH 一起喂给 metis。
- **通用**：演绎定理 MP 分支的 A2 实例化方向——
  `(p → (r → A)) → ((p → r) → (p → A))`，p 是被剥离的假设。
