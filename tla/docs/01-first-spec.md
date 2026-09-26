# 01 · 第一个规格：系统就是状态机

对应示例：`../examples/Ch01FirstSpec.tla`

## 为什么要用 TLA+

你写过并发代码、分布式系统，或者哪怕只是一个有状态的协议，就一定遇到过这种 bug：
"两个请求几乎同时到达""这个分支理论上不会走到""重试三次后状态就乱了"。它们难复现、
难调试，因为问题藏在**特定的执行顺序**里。

TLA+ 的做法不一样：你不写"程序怎么一步步跑"，而是写清楚——

- 系统有哪些**状态**；
- 哪些状态是合法的**起点**；
- 允许哪些**状态跳变**；
- 什么性质必须**永远成立**（或**终将发生**）。

然后交给 **TLC 模型检查器**：它会**穷举**所有可达状态和所有可能的执行顺序，
只要存在一条违反性质的路径，它就给你把那条路径（反例）打印出来。

> Leslie Lamport（LaTeX 的作者、2013 图灵奖）发明 TLA+ 的初衷就是：硬件和软件的
> 设计错误，往往能在"写在纸上、还没写代码"时就被发现。TLA = Temporal Logic of
> Actions（动作时序逻辑）。

## 一个心智模型：状态机

TLA+ 里，**任何系统都是一台状态机**：

| 概念 | 含义 | 在规格里写作 |
|---|---|---|
| 状态 state | 所有变量在某一瞬间的取值，一张快照 | 一组变量赋值 |
| 初始状态 | 合法的起点 | `Init`（关于未加撇变量的谓词） |
| 动作 action | 从一个状态跳到另一个状态 | `Next`（联系"现在"和"下一步"的谓词） |
| 行为 behavior | 一条**无限长**的状态序列 s0→s1→s2→… | `Spec` |

关键认知：**行为是无限的**。即使系统"停了"，TLA+ 也认为它在原地无限踏步
（叫 stuttering，空转）。这点先记住，第 06 章会解释它为什么重要。

## 第一个规格：数到 N 就停

示例 `Ch01FirstSpec.tla` 是一个最小但完整的状态机：一个计数器 `c`，从 0 数到 `N`
就停住。逐段拆解：

```tla
EXTENDS Integers          \* 引入整数运算（+ - * 等）

CONSTANT N                \* 模型常量：值不在规格里写死，由 .cfg 给

VARIABLES c               \* 唯一的状态变量

Init == c = 0             \* 起点：c 等于 0

CountUp == IF c < N THEN c' = c + 1 ELSE c' = c   \* 动作
Next == CountUp

Spec == Init /\ [][Next]_<<c>>   \* 完整规格

TypeOK    == c \in 0..N   \* 不变式：c 始终在 0..N
NeverOver == c <= N       \* 不变式：c 永远不超过 N
```

几个第一次见到、需要先囫囵接受、后面会展开的东西：

- `c'`（读作 c-prime）表示**下一步**里 `c` 的值。不带撇的 `c` 是**当前**值。
  一个动作就是一条同时约束"现在"和"下一步"的公式。
- `Spec == Init /\ [][Next]_<<c>>` 是**固定形状**，先照抄：
  `[]` 是"永远"，`[Next]_<<c>>` 是"要么走一步 Next、要么 c 不变"。
- `..` 是整数区间：`0..N` 就是 `{0, 1, …, N}`。

## 配套文件 .cfg

TLC 不直接读你的"意图"，它需要一个**模型配置**告诉它：常量取什么值、从哪个
`Init` 出发、用哪个 `Next`/`Spec`、检查哪些性质。这就是同名 `.cfg` 文件：

```text
INIT Init
NEXT Next
CONSTANT N = 3
INVARIANT TypeOK
INVARIANT NeverOver
```

把 `N` 从 3 改成 5，规格一个字不用动，TLC 就去查更大的模型——这就是把参数抽成
`CONSTANT` 的好处。

## 跑起来

```bash
JAR="/Applications/TLA+ Toolbox 2.app/Contents/Eclipse/tla2tools.jar"
java -XX:+UseParallelGC -cp "$JAR" tlc2.TLC examples/Ch01FirstSpec.tla
# 或者用一键脚本：
./run-all.sh 01
```

本机实测输出（TLC 2.19）：

```text
Starting...
Computing initial states...
Finished computing initial states: 1 distinct state generated.
Model checking completed. No error has been found.
5 states generated, 4 distinct states found, 0 states left on queue.
```

`4 distinct states` 正是 `c = 0, 1, 2, 3` 这四个快照。TLC 把它们全走了一遍，
确认 `TypeOK` 和 `NeverOver` 在每个状态都成立——`No error has been found`。

## 一个埋给后面的伏笔

规格里还定义了一条 `EventuallyN == <>(c = N)`（"终将数到 N"），但本章**故意没让
TLC 查它**。原因：`Spec` 允许无限空转，所以"一直卡在 c=0 不动"也是一条合法行为，
在那条行为里 `c` 永远到不了 N。要让这条活性成立，必须加**公平性**——这是第 06、07
章的主题。先记住这个反直觉的点：**"系统会停"和"系统会一直空转"在 TLA+ 里都算合法
行为，除非你用公平性排除掉后者。**

---
下一章：[02 · 值、运算符与表达式](02-values-operators.md) ｜ 返回：[README](../README.md)
