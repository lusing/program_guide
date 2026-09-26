# 08 · 读懂 TLC 的反例

对应示例：`../examples/Ch08Counterexample.tla`

模型检查最大的价值**不是"证明对"，而是"抓出错"**。这一章我们故意写一个有 bug 的
计数器，让 TLC 找出违反不变式的那条路径，然后逐行读懂它打印的反例。

> 因为这是"演示错误"的示例，`run-all.sh` 期望 TLC **报错**——抓到 bug 才算通过。

## 场景：漏写守卫的计数器

一个本应在 `0..Cap` 之间循环的计数器，bug 是：加一时**漏写了上限守卫**。

```tla
CONSTANT Cap                 \* .cfg 给 Cap = 3
VARIABLES n
Init == n = 0

\* 有 bug：没有 "n < Cap" 守卫，n 会一直涨上去
NextBuggy == n' = n + 1

\* 修复：加守卫，到 Cap 就归零
NextFixed == n' = IF n < Cap THEN n + 1 ELSE 0

SpecBuggy == Init /\ [][NextBuggy]_<<n>>
SpecFixed == Init /\ [][NextFixed]_<<n>>

Bounded == n <= Cap          \* 我们想保证的不变式
InvBuggy == Bounded
```

`.cfg`（检查 bug 版）：

```text
SPECIFICATION SpecBuggy
INVARIANT InvBuggy
CONSTANT Cap = 3
```

## TLC 的反例（本机实测原文）

```text
Error: Invariant InvBuggy is violated.
Error: The behavior up to this point is:
State 1: <Initial predicate>
n = 0

State 2: <NextBuggy line 18, col 14 to line 18, col 23 of module Ch08Counterexample>
n = 1

State 3: <NextBuggy ...>
n = 2

State 4: <NextBuggy ...>
n = 3

State 5: <NextBuggy ...>
n = 4

5 states generated, 5 distinct states found, 0 states left on queue.
```

## 怎么读这条反例

- **`Invariant InvBuggy is violated`**：哪条性质被打破了。
- **`State 1 ... State 5`**：从初始状态到出事的那条**最短路径**。TLC 用广度优先搜索，
  所以反例总是"最快出事"的那条。
- 每个 `State k` 下面列出**所有变量当时的值**。这里只有一个变量 `n`。
- `<NextBuggy line 18 ...>` 告诉你**是哪个动作**导致了这一步，并给出它在源码里的行列
  位置——直接跳到 `Ch08Counterexample.tla` 第 18 行就能定位。
- 出事在 **State 5：`n = 4`**。而 `Cap = 3`，`Bounded == n <= 3` 被打破。反例到此为止
  （TLC 一发现违反就停，不会继续往深处跑）。

读懂反例 = 读懂"系统是怎么一步步走到坏事发生的"。这正是你复现并发 bug 时最缺的信息，
而 TLC 免费给你。

## 修复并验证

把 bug 改掉（加上守卫），并把 `.cfg` 换成检查修复版：

```text
SPECIFICATION SpecFixed
INVARIANT Bounded
CONSTANT Cap = 3
```

再跑 TLC，得到 `Model checking completed. No error has been found.`——`n` 现在在
`0..3` 之间循环，永不超过 `Cap`。

> 这就是 TLA+ 的日常循环：**写规格 → TLC 抓反例 → 看反例定位 bug → 改规格 → 再查**，
> 直到 `No error has been found`。整个过程在写一行实现代码之前就完成。

## 反例不只用于"找 bug"

下一节（13 章水壶问题）会看到一个反转用法：**把"目标"故意写成会被违反的不变式，让
TLC 的反例变成"求解器"输出的解法**。同样的机制，既能抓错，也能找方案。

---
上一章：[07 · 安全性 vs 活性](07-safety-liveness.md) ｜ 下一章：[09 · 调试工具箱](09-debugging.md) ｜ 返回：[README](../README.md)
