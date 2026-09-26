# 07 · 安全性 vs 活性

对应示例：`../examples/Ch07SafetyLiveness.tla`

并发/分布式系统里，要证的性质几乎都落进两类：**安全性**（坏事永不发生）和**活性**
（好事终将发生）。分清它们，你才知道该写 `[]` 还是 `<>`、要不要加公平性、TLC 怎么查。

本机实测：`Progress(2) ... 2 distinct states found ... No error has been found.`

## 两类性质

| | 安全性 safety | 活性 liveness |
|---|---|---|
| 直觉 | 坏事**永远不**发生 | 好事**终将**发生 |
| 形式 | `[](\lnot Bad)` 或状态不变式 | `<>Good`、`[]<>Good` |
| 证伪 | 找到**一个**违反的状态/前缀即可 | 必须看**整条无限行为** |
| 需要公平性吗 | 不需要 | **通常需要**（否则永远空转就证伪了） |
| 例子 | "至多一个进程在临界区" | "请求终将被响应" |

一句话区分：**安全性是"前缀封闭"的**——只要某条有限前缀里出了坏事，整条行为就被判
违反；**活性是"无法靠有限前缀证伪"的**——好事可能"再等一步"就来，所以必须看无限行为。

## 红绿灯例子

```tla
VARIABLES light
vars == <<light>>
Init == light = "red"
Flip == light' = IF light = "red" THEN "green" ELSE "red"
Next == Flip
Spec == Init /\ [][Next]_vars /\ WF_vars(Next)
```

`Flip` 是个**永远使能**的动作（红→绿→红…）。加 `WF_vars(Next)` 保证它不会无限期
停摆，于是灯真的一直在变。

性质：

```tla
SafetyNeverBlue == [](light \in {"red", "green"})   \* 安全性：绝不会变蓝
LivenessGreenIO == []<>(light = "green")            \* 活性：无限次变绿
LivenessRedIO   == []<>(light = "red")              \* 活性：无限次变红
```

`.cfg`：

```text
SPECIFICATION Spec
PROPERTY SafetyNeverBlue
PROPERTY LivenessGreenIO
PROPERTY LivenessRedIO
```

`[]<>(light="green")` 读作"无限次绿"（infinitely often）：对任意时刻，其后总有某个
时刻是绿。因为灯不停翻转，这成立。

## 一个故意不查的"假活性"

规格里还写了 `NotChecked == [](light = "green")`（"灯永远是绿"），但**没放进 cfg**。
它显然为假——灯也会是红。留作思考：把 `[]` 和 `<>` 写反，是新手最常见的活性 bug。
`[](light="green")` 是（假的安全性强断言），`[]<>(light="green")` 才是（真的活性）。

## TLC 怎么查这两类

- **安全性 / 不变式**：TLC 在**生成每个状态**时就检查，发现违反立刻停下、打印那条
  **有限前缀**作为反例。快、直观。
- **活性 / 时序性质**：TLC 先构建完整状态图，再做"implied-temporal checking"，
  在图上找是否存在一条满足公平性、却违反 `<>` 的无限路径（本质是找反例环）。
  输出里会看到 `Implied-temporal checking--satisfiability problem has N branches`。

## 写性质时的判断流程

1. 我想说的是"X 永远成立"还是"X 终会发生"？
   - 永远成立 → 安全性 → 写不变式或 `[]X`，用 `INVARIANT`。
   - 终会发生 → 活性 → 写 `<>X` 或 `[]<>X`，用 `PROPERTY`。
2. 是活性？→ **几乎一定要加公平性**（`WF`/`SF`），否则 TLC 用"永远空转"就证伪了。
3. 想证"系统永不卡死"？→ `[]ENABLED Next` 或 `[](ENABLED Next => <>(...))`（第 06 章）。

实战章里：互斥（14）、不透支/守恒（15）、不溢出（16）都是**安全性**；而"请求终将
被处理"这类才需要活性 + 公平性。你会发现绝大多数工程性质其实是安全性——这也是 TLA+
最擅长、最值钱的部分。

---
上一章：[06 · 时序算子与公平性](06-temporal.md) ｜ 下一章：[08 · 读懂 TLC 的反例](08-counterexample.md) ｜ 返回：[README](../README.md)
