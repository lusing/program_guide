# 05 · 状态机三件套：变量、初始状态、动作

对应示例：`../examples/Ch05StateMachine.tla`

这是 TLA+ 的核心肌肉记忆。本章写一个有两个变量、两个动作的小系统，把三个最容易混的
概念彻底讲清：**未加撇 = 现在**、**加撇 = 下一步**、**`UNCHANGED` = 这一步不动它**。

本机实测（`Cap = 3`）：`8 distinct states found ... No error has been found.`
（8 = 计数器 0..3 共 4 个值 × 旗标 2 个值。）

## 变量与初始状态

```tla
EXTENDS Integers, TLC
CONSTANT Cap                  \* 计数器上限，.cfg 里给 3

VARIABLES n, flag             \* 两个状态变量

Init ==
  /\ n    = 0
  /\ flag = FALSE
```

`Init` 用**未加撇**变量描述所有合法起点。它可以有多个起点（用 `\/` 连接），这里只有
一个：`n=0, flag=FALSE`。

> 用 `/\` 竖排、每项一行的"合取列表"是 TLA+ 的招牌排版。对齐很重要：`/\` 必须纵向
> 对齐，否则解析器会困惑。这是 Lamport 提倡的"纵向排版"，读起来像清单。

## 动作：联系"现在"和"下一步"

一个**动作**（action）是一条同时含未加撇和加撇变量的公式。加撇 `n'` 表示**下一步**
里 `n` 的值。

```tla
Tick ==
  /\ n < Cap            \* 使能条件（enablement）：只有没到上限才允许 Tick
  /\ n' = n + 1         \* 规定下一步 n 的值
  /\ flag' = ~flag      \* 规定下一步 flag 的值

Reset ==
  /\ n > 0
  /\ n' = 0
  /\ UNCHANGED flag     \* 这一步不改变 flag
```

两个关键点：

1. **不带撇的部分是"守卫"**：`n < Cap`、`n > 0` 是对**当前**状态的约束，决定这个
   动作此刻**能不能**发生（使能/禁用）。
2. **带撇的部分是"效果"**：`n' = n + 1` 规定**下一步**的值。
3. **每个变量都要有交代**：动作里必须给所有变量的下一步取值定下来。没显式提到的，
   用 `UNCHANGED v`（等价于 `v' = v`）声明"它不变"。漏掉某个变量会让动作对它" unconstrained"，
   TLC 会允许它取任意值——几乎总是 bug。`UNCHANGED` 让意图一目了然。

## Next：一步 = 任选一个动作

```tla
Next == Tick \/ Reset
```

`Next` 是各动作的**析取**：系统每一步"非此即彼"地选一个**当前使能**的动作执行。
这种"或"正是并发/不确定性的来源——到底选哪个，由 TLC 穷举所有可能。

> 当某个状态下 `Tick` 和 `Reset` 都使能（如 `n=1`），TLC 会**分别**探索两条分支。
> 这就是模型检查能抓到"特定交错下才出现"的 bug 的原因。

## 完整规格

```tla
Spec == Init /\ [][Next]_<<n, flag>>
```

`<<n, flag>>` 是把所有状态变量打包成元组（后面到处复用，常命名为 `vars`）。
`[Next]_vars` 和 `[]` 的含义留到第 06 章拆开讲，这里先照抄。

## 性质

```tla
TypeOK ==                    \* 类型不变式：变量始终落在预期范围
  /\ n \in 0..Cap
  /\ flag \in BOOLEAN

Bounded == n <= Cap          \* 业务不变式
```

`TypeOK` 是个好习惯：先把"每个变量的类型/范围"写成不变式。它经常能在你写错动作时
第一时间报错（比如某动作把 `n` 弄成了负数或字符串）。`BOOLEAN` 是内置的 `{TRUE, FALSE}`。

## .cfg 与运行

```text
INIT Init
NEXT Next
CONSTANT Cap = 3
INVARIANT TypeOK
INVARIANT Bounded
```

注意这里用 `INIT` + `NEXT`（而不是 `SPECIFICATION Spec`）：当只检查**安全性**
（状态不变式）时，`INIT`/`NEXT` 更直接、更快。要检查 `<>` 这类**时序/活性**性质时，
才需要 `SPECIFICATION Spec`（第 06、07 章）。

```bash
./run-all.sh 05
```

实测输出节选：

```text
Model checking completed. No error has been found.
13 states generated, 8 distinct states found, 0 states left on queue.
```

## 一个常见错误：死锁

如果你把 `Reset` 的守卫写错，导致某个状态下 `Next` 全被禁用（没有任何动作可走），
TLC 会报 **`Deadlock reached`** 并打印走到死胡同的那条路径。因为 TLA+ 要求行为无限
延伸，"无路可走"是错误。第 06 章的 `Ch06Temporal` 就专门演示了如何用自环动作避免
误报死锁。

---
上一章：[04 · 逻辑与量词](04-logic-quantifiers.md) ｜ 下一章：[06 · 时序算子与公平性](06-temporal.md) ｜ 返回：[README](../README.md)
