# 46 · 收官：CHEATSheet

> 46 章（00-45 + 收官）走完了 Jech 44 节的全部旅程——
> 从 ZFC 公理到力迫、大基数、描述集合论。这是速查与总账。

## 46.1 全书结构总表

| 篇 | 章 | Jech 节 | 主题 |
|---|---|---|---|
| 导引 | 00 | — | 机器证明的六通道立场 |
| 一 公理 | 01-09 | §1-9 | ZFC、序数、基数、实数、AC、基数算术、滤子、奇异、正则 |
| 二 传递模型 | 10-15 | §10-15 | 绝对性、坍缩、L、AC+GCH 在 L、Σₙ、OD |
| 三 力迫 | 16-22 | §16-21 | 泛型扩张、cBa、V^B、CH/AC 独立、积、对称 |
| 四 应用 | 23-27 | §22-26 | Suslin、MA、迭代、组合、cBa 对应 |
| 五 可测 | 28-33 | §27-32 | 测度、超幂、分划、0#、L[U]、弱紧 |
| 六 大基数 | 34-39 | §33-38 | 紧、实值可测、饱和、GCH、力迫应用、超滤 |
| 七 DST | 40-45 | §39-44 | Borel、投影、L 中的投影、Solovay、AD、力迫 |

## 46.2 通道分工速查

| 通道 | 角色 | 典型锚点 |
|---|---|---|
| Lean+mathlib | 主证明 | Ordinal/Cardinal/ZFC/Zorn/Ultrafilter/cantorSet |
| Isabelle/ZF | 二证明 | Lset/DPow/AC_in_L/Zorn/ZF-AC |
| Coq | 三证明 | 浅嵌入 ZF Record/transport Russell/SB 区间套/有限 König |
| Agda | 构造性 | HF/VNO/birth/club 检查器/AD 有限版 |
| Julia | 计算 | CNF 序数计算器/gamma_pair/SB 算法/对角线机器 |
| Python | 计算 | Cantor-Bendixson/Mostowski/泛型实数/V_n 枚举 |
| Prolog | 有限模型 | 滤子判定/König 对角逃逸/公式深嵌入/坍缩 |

## 46.3 数学工具箱

| 工具 | 章 | 首次出现 |
|---|---|---|
| Russell/Berry 对角线 | 00/15 | transport 版 nprp |
| Cantor 定理 κ < 2^κ | 03 | Cardinal.cantor |
| Schröder-Bernstein | 03 | Embedding.antisymm |
| Zorn 引理 | 05 | zorn_le |
| 超穷归纳/递归 | 02 | WellFoundedLT.induction |
| Fodor 定理 | 07 | 数值影子 |
| Mostowski 坍缩 | 11 | 可执行四通道 |
| 反射原理 | 11 | Skolem 闭包 |
| Condensation | 13 | 四步链讲义 |
| 力迫定理 | 18 | ‖φ‖ ∈ G' |
| ccc 计数 | 19 | Δ-系统 |
| Product Lemma | 20 | G = G₁×G₂ |
| 对称模型 | 21 | 正规滤子+遗传对称 |
| Aronszajn 构造 | 22 | 有理数序列 |

## 46.4 关键库锚点总表

**mathlib（v4.33.1 钉版）**：
- `Ordinal.natCast_add_omega0`（吸收律）
- `Cardinal.aleph_lt_aleph`（aleph 严格递增）
- `Cardinal.cantor`（κ < 2^κ）
- `Function.Embedding.antisymm`（SB）
- `Cardinal.isStrongLimit_beth`（强极限）
- `PSet.rank_lt_of_mem`（秩的单调性）
- `cantorSet_eq_union_halves`（自相似）
- `Function.Embedding.antisymm`（SB）
- `Filter.exists_ultrafilter_le`（Tarski）
- `zorn_le` / `zorn_superset`（Zorn）

**Isabelle/ZF（2025-2）**：
- `Lset` / `DPow_def`（L 层级）
- `AC_in_L`（Gödel 1938 机器化）
- `InfCard_square_eqpoll`（κ·κ=κ）
- `Zorn` / `Zorn_Lemma`（Zorn）
- `Transset_iff_Union_subset`（传递集）
- `Ord_linear_lt`（序数三歧）
- `aleph0_power_aleph0`（ℵ₀^ℵ₀=𝔠）

## 46.5 坑位总账（TOP 20）

| # | 坑 | 通道 |
|---|---|---|
| 1 | `Ordinal.induction` 弃用 → `WellFoundedLT.induction` | Lean |
| 2 | `ω` 被 Cardinal scope 劫持为 aleph0 | Lean |
| 3 | `IsSuccPrelimit` 在 Order 命名空间 | Lean |
| 4 | Reflection.thy 是孤儿理论（堆中无） | Isabelle |
| 5 | poly.exe 逃逸进程锁 db → SQLITE 冲突 | Isabelle |
| 6 | 嵌套归纳 guard 三撞（list 嵌套） | Coq |
| 7 | `apply F` 的函数变量不可反推 | Coq |
| 8 | where 块参数捕获错位 → mutual 块 | Agda |
| 9 | `$var全角标点` → `$(var)` | Julia |
| 10 | 中文串内 ASCII 引号截断 | Julia |
| 11 | Fraction(float) 伪精确 | Python |
| 12 | 坍缩规范化键 (len,str) 非纯字典序 | Python |
| 13 | `between(0,N,B)` 的 B=N 平凡真 | Prolog |
| 14 | `(A;B)->C` 双解污染 findall | Prolog |
| 15 | `Mathlib.Order.BooleanAlgebra` 路径 | Lean |
| 16 | `cantorSet_subset_unitInterval` 大写 I | Lean |
| 17 | `InfCard_square_eq` 实为 `eqpoll` 形态 | Isabelle |
| 18 | 构造子签名与 match 一致性 | Coq |
| 19 | `Data.List.all` 已迁移 → 自写 `allB` | Agda |
| 20 | wslpath 路径反斜杠被吃 | build.ps1 |

## 46.6 结语

这部教程把 Jech《Set Theory》第一版 44 节全部覆盖，用
七个机器通道（Lean/Isabelle-ZF/Coq/Agda/Julia/Python/Prolog）
逐章验证了集合论的核心事实。每个通道有自己的立场——
类型论的公理降格、ZF object-logic 的公理化、浅嵌入的
显式记账、构造性的有限模型、可执行的算法与数值实验。
**数学事实是唯一的，但表达它的方式是多样的**——这正是
"多通道集合论"的教学价值。

---

上一章：[45 DST 力迫应用](docs/45-dstforcing.md) · [返回目录](README.md)
