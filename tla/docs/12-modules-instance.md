# 12 · 模块化与 INSTANCE

对应示例：`../examples/Ch12ModulesInstance.tla`（库模块：`../examples/Ch12Counter.tla`）

规格大了就要拆分复用。TLA+ 有两种机制：**`EXTENDS`**（原样并入）和 **`INSTANCE`**
（带命名空间、可参数化、可多次实例化）。本章用一个被参数化的"环形计数器"库演示后者。

本机实测：`No error has been found.`（单状态断言）

## EXTENDS vs INSTANCE

| | `EXTENDS M` | `INSTANCE M` |
|---|---|---|
| 效果 | 把 M 的所有定义**原样并入**当前模块 | 把 M 的定义**带命名空间地引入** |
| 像 | `import *` | 实例化一个参数化模块 |
| 能否给常量赋值 | 否 | 能，用 `WITH` |
| 能否多次引入 | 否 | 能，各喂不同参数 |
| 访问算子 | 直接用名字 | `Name!算子`（感叹号） |

标准库都用 `EXTENDS` 引入（`Integers`、`Sequences`、`FiniteSets`、`TLC`）。要复用
**自己写的、带参数的**模块，用 `INSTANCE`。

## 标准库一览

| 模块 | 提供 |
|---|---|
| `Naturals` | 自然数 0,1,2,…，`+ - * \div %`、`> <`、`Nat` |
| `Integers` | 整数（含负数）、`Int` |
| `Sequences` | 有限序列：`Append`/`Head`/`Tail`/`Len`/`SubSeq`/`SelectSeq`、`Seq(S)` |
| `FiniteSets` | `Cardinality(S)`、`IsFiniteSet(S)` |
| `TLC` | 模型检查辅助：`Print`/`PrintT`/`Assert`/`RandomElement`/`Any` 等 |

```tla
EXTENDS Integers, Sequences, FiniteSets, TLC
```

实测几个标准库算子：

```tla
Cardinality({1,2,3}) = 3                  \* FiniteSets
IsFiniteSet({1,2}) /\ ~IsFiniteSet(Int)   \* Int 是无限集
Len(<<"a","b","c">>) = 3                  \* Sequences
Append(<<1,2>>, 3) = <<1,2,3>>            \* Sequences
{2,3} \subseteq 1..5                       \* 区间
```

## 参数化库模块 Ch12Counter

`Ch12Counter.tla`（**没有 `.cfg`，是库文件，不会被单独运行**）：

```tla
MODULE Ch12Counter
EXTENDS Integers
CONSTANT Max                 \* 参数：计数上限，由实例化方提供

InitVal == 0
StepVal(v) == IF v < Max THEN v + 1 ELSE 0   \* 纯函数：当前值 -> 下一个值
InRange(v) == v \in 0..Max
```

把"会变的东西"声明成 `CONSTANT`，由使用方填值——这就是参数化。注意 `StepVal` 是
**纯函数**（输入当前值、输出下一个值，不碰带撇变量），这样最容易被复用。

## INSTANCE ... WITH：同模块、不同参数

`Ch12ModulesInstance.tla`：

```tla
C3 == INSTANCE Ch12Counter WITH Max <- 3
C5 == INSTANCE Ch12Counter WITH Max <- 5
```

语法要点（实测踩过的坑）：

- 命名实例写作 **`C3 == INSTANCE 模块 WITH 常量 <- 值`**，不是 `INSTANCE C3 <- 模块`。
- 访问引入的算子用**感叹号**：`C3!StepVal`，**不是**点号 `C3.StepVal`。

于是同一个 `Ch12Counter` 被实例化成两份，`Max` 分别是 3 和 5：

```tla
InstanceOK ==
  /\ C3!StepVal(2) = 3        \* Max=3：2 没到上限，加一到 3
  /\ C3!StepVal(3) = 0        \* Max=3：到上限 3，归零
  /\ C5!StepVal(3) = 4        \* Max=5：3 远没到上限，加一到 4
  /\ C5!StepVal(5) = 0        \* Max=5：到上限 5，归零
  /\ C3!InRange(3) /\ ~C3!InRange(4)   \* 4 超出 Max=3 的范围
  /\ C5!InRange(4) /\ C5!InRange(5)    \* 4、5 都在 Max=5 范围内
```

TLC 验证 `InstanceOK` 成立——证明"同一份泛型规格，喂不同常量，确实给出了不同行为"。
这就是 TLA+ 复用规格的方式：写一次泛型模块，按参数实例化任意多份。

## 不带前缀的 INSTANCE

也可以 `INSTANCE Ch12Counter WITH Max <- 3`（不给 `Name ==`），这样算子直接用原名
引入、无前缀。但当你想引入**同一模块的多个实例**时，必须用 `Name ==` 前缀区分，否则
名字冲突。本例正是如此。

## 多文件如何被找到

`INSTANCE`/`EXTENDS` 本地模块时，TLC 会在**同一目录**找同名 `.tla`。`run-all.sh` 因此
把 `examples/` 下**所有** `.tla` 都拷进工作目录，保证 `Ch12ModulesInstance` 能找到
`Ch12Counter.tla`。你手动跑时，确保被引入的模块文件和主文件在同一目录（或在 classpath
里）即可。

---
上一章：[11 · PlusCal 并发](11-pluscal-concurrent.md) ｜ 下一章：[13 · 水壶问题（Die Hard）](13-diehard.md) ｜ 返回：[README](../README.md)
