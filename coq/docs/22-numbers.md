# 22 · 数值专题：nat、N 与 Z

对应示例：`../examples/22_numbers.v`

### 22.1 nat 的成本模型：数学家的数 vs 工程师的数

全书用 nat 是**为了证明**——形状只有 O 和 S，归纳原理简单。但第 4 章那个实测坑（`Compute (Nat.pow 2 100)` 内存耗尽）背后是一元表示的成本模型：

| | nat | N / Z |
|---|---|---|
| 表示 | 一元（S 链） | 二进制（positive） |
| 3 是什么 | `S (S (S O))` | `11%positive` 两位 |
| 2^64 需要 | 1.8×10¹⁹ 个构造子 | 64 位 |
| 加法 | O(n) 步逐层 S | O(log n) 位运算 |
| 与证明的关系 | 归纳原理直接、全书主战场 | 引理丰富但定义复杂 |

实测对比（示例 22）：`Nat.pow 2 16`（65536 个 S）还能瞬间算完并打印；`Z.pow 2 64`、`Z.pow 2 100` 输出完整十进制也是瞬间。

```coq
Print Z.
(* Inductive Z : Set :=
     Z0 : Z | Zpos : positive -> Z | Zneg : positive -> Z *)
```

`positive` 是一颗二进制树；`Z0`/`Zpos`/`Zneg` 三构造子——还记得第 5 章 `if 1%Z` 被拒绝吗？就是因为 Z 有**三个**构造子，不满足 if 的「恰好两个」要求，伏笔在此闭环。

### 22.2 选型决策表

| 需求 | 用什么 |
|---|---|
| 写定义、做归纳证明 | **nat**（形状简单，全书默认） |
| 有符号算术、大数计算 | **Z** |
| 明确无符号的二进制 | **N** |
| 程序逻辑里做分支 | bool（`=?` `<=?`）+ reflect 桥 |
| 性能关键的已验证代码 | Coq 里证明，Extraction 抽取成 OCaml 后跑（第 24 章） |

互通的桥：`Z.of_nat` / `Z.to_nat` / `N.of_nat` / `N.to_nat`。注意转换本身有成本（一元 ↔ 二进制是表示形状的整体改写），**在边界一次转换、内部统一数系**是工程习惯。

### 22.3 lia：算术证明的自动化

前 21 章证过 `n + 0 = n`、`plus_comm`——纯算术的体力活。标准库的 `lia`（linear integer arithmetic，来自 `Lia`）把这类活自动包了：

```coq
From Coq Require Import ZArith Lia.

Theorem nat_lia : forall n m : nat, n <= m -> n + 0 <= m.
Proof.
  intros n m H. lia.
Qed.

Theorem z_lia : forall a b : Z, (a <= b)%Z -> (a - b <= 0)%Z.
Proof.
  intros a b H. lia.
Qed.
```

`lia` 处理**线性**目标：加减、常数、比较的任意组合（nat 与 Z 都吃）。非线性的（含未知数相乘，如 `n * n >= 0`）它管不了——那种回到手证或 `nia`（更慢的非线性版）。使用心法：**归纳结构是本质的目标手证，纯算术变形的尾声交 lia**。注意 Z 上的比较要 `%Z` 作用域——裸写 `(a <= b)` 会被解析成 nat 的 `<=`，报「expected nat got Z」（实测，又一条作用域坑）。

### 22.4 本章坑位清单（实测）

1. **`Compute` 大 nat 指数**：`Nat.pow 2 100` 直接 OOM——大数用 `Z.pow`；「装得下」与「算得动」是两回事（第 4 章老坑的算术版）；
2. **Z 上的运算符裸写**：`(a <= b)%Z` 才是 Z 的比较，裸写按 nat 解析报类型错——`Open Scope Z_scope`（模块内）或 `%Z`（局部）二选一；
3. **`lia` 不认非线性**：目标里出现未知数相乘就放弃——先手证非线性骨架，线性收尾再喂给它；
4. **`Z.to_nat` 的隐藏成本**：2^16 瞬间变回 65536 个 S——转换是表示重写，大数转换本身可能爆炸。

---
上一章：[21 · 插入排序与正确性证明](21-sorting.md) ｜ 下一章：[23 · 测试与断言风格](23-testing.md) ｜ 返回：[README](../README.md)
