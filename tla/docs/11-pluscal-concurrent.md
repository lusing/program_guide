# 11 · PlusCal 并发：process、await、原子步

对应示例：`../examples/Ch11PlusCalConcurrent.tla`

并发的关键是 PlusCal 的 **process**：声明多个进程，TLC 会以**所有可能的交错**调度它们。
本章用一把锁实现两个进程对临界区的互斥，并让 TLC 证明"任意时刻至多一个进程在临界区"
永远成立。

本机实测：`21 states generated, 12 distinct states found ... No error has been found.`

## 两个 PlusCal 核心概念

- **标签（label，如 `a:` `b:` `c:`）划定原子步边界**：同一标签下、到下一个标签之前的
  所有语句，作为**一个不可分割的步骤**执行。这是并发正确性的命门——哪些语句之间会被
  别的进程插队，完全由标签的位置决定。
- **`await P`**（等价 `wait P`）：阻塞本进程，直到谓词 `P` 为真才继续。
- **`self`**：当前进程自己的 id。

## 互斥算法

```tla
EXTENDS Integers, FiniteSets, TLC

(* --fair algorithm Mutex {
  variables lock = FALSE;
  process (P \in {1, 2})
  variable inCS = FALSE;
  {
    a: while (TRUE) {
         b: await (lock = FALSE);
            lock := TRUE;
         c: inCS := TRUE;
         d: inCS := FALSE;
            lock := FALSE;
       }
  }
} *)
```

读这段代码：

- `process (P \in {1, 2})` 声明两个进程，id 是 1 和 2。
- `variable inCS = FALSE;` 是**每进程私有**变量，写在 `process (...)` 与 body 花括号
  **之间**（⚠ 放进花括号里 `pcal.trans` 会报 `Expected ":=" but found ";"`）。翻译后
  `inCS` 变成"以进程 id 为下标"的数组：`inCS[1]`、`inCS[2]`。
- 标签 `b:` 下的 `await (lock = FALSE); lock := TRUE;` 是**同一原子步**——这是经典的
  **test-and-set**：检查锁空闲和上锁之间**没有标签**，所以不可能被别的进程插队。两个
  进程因此不可能同时拿到锁。
- `c:` 进入临界区（`inCS := TRUE`），`d:` 退出并释放锁。

> 为什么 `b:` 和 `c:` 之间要有标签？因为"上锁"和"进入临界区"是两个步骤。如果把它们
> 放同一标签下当然也行；这里分开是为了让"在临界区里停留"成为一个可被观察的状态。
> 标签放哪 = 你允许调度器在哪切走，必须想清楚。

## 性质

翻译后 `ProcSet = {1, 2}`，`inCS` 是 `ProcSet` 上的函数。

```tla
\* 互斥（安全性）：不存在两个不同进程同时 inCS 为真
MutEx ==
  \A i \in ProcSet : \A j \in ProcSet :
    (i # j) => ~(inCS[i] /\ inCS[j])

\* 等价的「计数」写法：临界区里的进程数 <= 1
AtMostOneInCS == Cardinality({i \in ProcSet : inCS[i]}) <= 1
```

`.cfg`：

```text
SPECIFICATION Spec
INVARIANT MutEx
INVARIANT AtMostOneInCS
```

TLC 穷举所有交错（12 个不同状态），确认 `MutEx` 永远成立。

## 一个诚实的坑：per-process 活性需要 per-process 公平性

规格里还定义了 `P1InfinitelyOften == []<>(inCS[1])`（"进程 1 无限次进临界区"），但
**故意没查**。直觉上它似乎该成立，可如果你把它加进 cfg，TLC 会给出反例：

```text
State 1: inCS = <<FALSE, FALSE>>  lock = FALSE  pc = <<"a","a">>
...
State 5: inCS = <<FALSE, TRUE>>   lock = TRUE   ...   \* 进程 2 进了临界区
```

原因是 PlusCal 的 `--fair` 只对**整个 `Next` 析取**加公平性，并不保证**单个进程**不被
饿死——TLC 能构造出"进程 2 一直抢到锁、进程 1 永远卡在 `await`"的合法行为。要证每条
进程的活性，需要给每个进程**单独**的公平性假设（`WF`/`SF` 按进程展开），这是更深的
话题。**本章把安全性 `MutEx` 查绿即可**——这也印证了第 07 章的话：工程里绝大多数
要证的性质是安全性，而安全性不需要公平性。

## PlusCal vs 纯 TLA+

| | PlusCal | 纯 TLA+ |
|---|---|---|
| 风格 | 命令式伪代码（`while`/`:=`/`await`） | 声明式（动作 = 谓词） |
| 并发 | `process` + 标签自动展开成交错 | 手写 `\E p \in Procs : ...` |
| 上手 | 对程序员友好 | 需要状态机思维 |
| 本质 | 翻译成 TLA+，等价 | — |

下一章（14）会用**纯 TLA+** 重写一遍互斥，对照体会两种风格。

---
上一章：[10 · PlusCal 入门](10-pluscal-intro.md) ｜ 下一章：[12 · 模块化与 INSTANCE](12-modules-instance.md) ｜ 返回：[README](../README.md)
