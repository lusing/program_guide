# 09 · 调试工具箱：PrintT、Assert、ASSUME、CONSTRAINT

对应示例：`../examples/Ch09Debugging.tla`

当模型出错、或行为不符合预期时，光看反例有时不够——你需要在检查过程中**打印中间值**、
**加自定义断言**、**把无限模型截断成有限**。`EXTENDS TLC` 提供的这些算子就是干这个的。

本机实测：`9 distinct states found ... No error has been found.`（受状态约束裁剪）

## PrintT：让 TLC 说话

`PrintT(x)` 把 `x` 打到 TLC 的标准输出，**返回 `TRUE`**，所以能直接塞进合取里。
`Print(x)` 类似但不换行。

```tla
Init ==
  /\ n = 0
  /\ steps = 0
  /\ PrintT(<<"[init] Cap =", Cap>>)     \* 确认初始状态长啥样

Step ==
  /\ PrintT(<<"[step] n:", n, "-> ", IF n < Cap THEN n + 1 ELSE 0>>)
  /\ n' = IF n < Cap THEN n + 1 ELSE 0
  /\ steps' = steps + 1
```

用 `./run-all.sh -v 09` 就能看到每步打印的 `<<[step] n: 0 -> 1>>` 之类。常用来确认
"某动作到底有没有被走到""某变量在某步是什么值"。

> `PrintT` 只在**模型检查时**有意义，不属于 TLA+ 数学语义。别把它用在你想推理的性质里，
> 它纯粹是调试探针。

## Assert：带自定义报错的断言

`Assert(p, msg)`：`p` 为真时返回 `TRUE`；为假时 TLC 立刻报错并打印 `msg`。把它当
不变式用，等于"会说话的断言"：

```tla
TypeOK == Assert(n \in 0..Cap, "n out of range")
```

> ⚠ `msg` 是**字符串字面量**，因此**不能含中文/非 ASCII**（见 [19 章](19-pitfalls.md)）。
> 这里用英文 `"n out of range"`。

## ASSUME：给常量附加前提

`ASSUME P` 声明"只在 `P` 成立的前提下检查"。常用来约束模型常量的取值范围：

```tla
ASSUME Cap >= 1
```

若 `.cfg` 给了 `Cap = 0`，TLC 会因 `ASSUME` 失败而报警，提醒你配置不合法。
`ASSUME` 也能缩小状态空间（如 `ASSUME x \in 1..3`）。

> 区分 `ASSUME`（假设，TLC 当作前提，不验证）和 `INVARIANT`/`PROPERTY`（要 TLC 去
> **证明**的性质）。把该证的东西误写成 `ASSUME`，等于自己给自己开后门。

## CONSTRAINT：把无限模型截断

`steps` 这种每步递增、无上界的变量会让状态空间**无限**，TLC 永远跑不完。解决办法是在
`.cfg` 里写 `CONSTRAINT`（状态约束），让 TLC 在越界时**剪枝**、不再往深处探索：

```tla
StateBound == steps <= 8
```

```text
INIT Init
NEXT Next
CONSTANT Cap = 3
CONSTRAINT StateBound
INVARIANT TypeOK
INVARIANT NonNeg
```

`CONSTRAINT StateBound` 告诉 TLC："任何 `steps > 8` 的状态都不要展开它的后继。"
于是无限的行为被截成有限深度，TLC 得以收敛。这是处理"逻辑上无界、但只想验证有限
深度内性质"的标准手段。

> `CONSTRAINT`（状态约束，剪枝用）和 `CONSTANT`（模型常量的赋值）是两个不同的关键字，
> 别拼混。

## TLC 模块里其它有用的算子

| 算子 | 用途 |
|---|---|
| `PrintT(x)` / `Print(x)` | 打印调试（返回 TRUE） |
| `Assert(p, msg)` | 断言，失败即报错并打印 msg |
| `RandomElement(S)` | 随机取一个元素（**不确定**，慎用，会让结果不可复现） |
| `Any` | 任意值（同样不确定，一般只用于占位） |
| `Colored(x, "color")` | 给反例里的值上色，便于在 GUI 里辨认 |
| `<< >>` 等 | 元组/序列辅助 |

`RandomElement`、`Any` 会引入不确定性，**让模型检查结果不可复现**，调试时尽量别用；
需要"任选一个"时，用 `\E` 或 `CHOOSE` 这种语义明确的写法。

## 调试心法

1. 先写 `TypeOK`（每个变量的类型/范围），它能在第一时间抓住"动作把变量写成了奇怪的
   类型/越界值"。
2. 反例看不懂时，往动作里塞 `PrintT`，把关键变量在每步打出来。
3. 状态空间爆炸/跑不完 → 用 `CONSTRAINT` 截断，或缩小 `CONSTANT` 的值（把 N 调小）。
4. 报 `Deadlock` 但你认为系统本就该停 → 给终态加自环动作（第 06 章）。

---
上一章：[08 · 读懂 TLC 的反例](08-counterexample.md) ｜ 下一章：[10 · PlusCal 入门](10-pluscal-intro.md) ｜ 返回：[README](../README.md)
