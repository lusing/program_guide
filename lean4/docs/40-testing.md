# 40 · 测试与属性测试

**对标**: *Functional Programming in Lean*（Testing 章）。

证明能保证正确性，但写证明前你总得先**确认猜想是对的**、代码没 bug。Lean 提供了从"`#eval` 看结果"
到"自定义测试框架"再到"随机属性测试"的一整套手段。本章覆盖它们，并讲清各自的能力边界——
尤其是属性测试工具 `plausible` 的一个关键陷阱：**它是测试，不是证明**。

> 纯 Lean 部分在 4.34.1 验证；`plausible` 部分在 Mathlib4 v4.35.0-rc3（含 plausible 包）验证。

## 40.1 #eval：最简测试

最快的"测试"就是 `#eval` 一个 `Bool` 断言：

```lean
#eval (2 + 2 == 4)                       -- true
#eval ([1, 2, 3].reverse == [3, 2, 1])   -- true
#eval (List.length [1,2,3] == 3)         -- true
```

注意用 `==`（`BEq`，返回 `Bool`）而非 `=`（命题）。`#eval` 只对**可计算**的表达式有效，
所以测的是计算行为，不能直接 `#eval` 一个 `Prop`（要先 `decide` 成 `Bool`）。

## 40.2 #guard_msgs：断言信息输出

`#guard_msgs` 把一段命令产生的 info/warning/error 信息**固化成期望值**，不一致就报错——
这是 Lean 自身测试套件大量使用的手段，适合断言 `#check`/`#eval` 的输出：

```lean
/--
info: 4
-/
#guard_msgs in
  #eval 2 + 2
```

期望的输出写在 `#guard_msgs` **前面的 docstring** 里（`/-- ... -/`）。若实际信息与 docstring 不符，
编译报错并给出 diff。只想断言"没有警告/错误"、放行 info 时用 `(drop info)`：

```lean
#guard_msgs (drop info) in
  #eval 2 + 2     -- 打印 4，但只要没有 warning/error 就通过
```

## 40.3 自定义测试框架

要跑一组测试并报告通过率，搭一个迷你框架（纯 `IO`，无需外部依赖）：

```lean
structure Test where
  name : String
  run  : IO Bool

def runTests (tests : Array Test) : IO Unit := do
  let mut passed := 0
  for t in tests do
    let ok ← t.run
    if ok then
      passed := passed + 1
      IO.println s!"[PASS] {t.name}"
    else
      IO.println s!"[FAIL] {t.name}"
  IO.println s!"{passed}/{tests.size} passed"

#eval runTests #[
  { name := "addition", run := pure (2 + 2 == 4) },
  { name := "string",   run := pure ("ab".length == 2) },
  { name := "list map", run := pure ([1,2,3].map (·*2) == [2,4,6]) },
  { name := "故意失败",  run := pure (2 + 2 == 5) }
]
-- [PASS] addition
-- [PASS] string
-- [PASS] list map
-- [FAIL] 故意失败
-- 3/4 passed
```

这正是 *Functional Programming in Lean* 里测试框架的雏形：`Test` 携带名字和一个 `IO Bool` 动作，
`runTests` 用第39章的 `let mut` 累积通过数。真实项目会再加上失败时打印期望/实际值、
彩色输出、`Except` 传播错误等。

## 40.4 decide：可判定命题的精确与穷举验证

对**可判定**命题，`decide` 让内核直接计算真假并生成证明——比随机测试更强（它是**完全**验证）：

```lean
example : (List.range 5).sum == 10 := by decide
#eval (List.range 10).all (fun n => n + 0 == n)   -- true（穷举前 10 个）
#eval (List.range 5).all (fun n => n < 5)          -- true
```

`decide` 适合"输入空间有限或命题可由内核归约判定"的场景（小数值等式、`Nat.Prime`、有限列表的全称量词）。
它的可信度来自内核计算，不依赖测试覆盖率——但只对 `Decidable` 命题有效，且输入太大会超时（见第29章 `maxHeartbeats`）。

## 40.5 属性测试：plausible

`plausible`（独立包，Mathlib 依赖之一）做 **property-based testing**：对全称命题 `∀ x, p x`，
它随机生成大量 `x`，检查 `p x`，一旦找到反例就报告（还会自动 shrink 到最小反例）：

```lean
import Plausible

example (n m : Nat) : n + m = m + n := by plausible
-- 输出：Unable to find a counter-example

example (xs ys : List Nat) : (xs ++ ys).length = xs.length + ys.length := by plausible
example (xs : List Nat) : xs.reverse.reverse = xs := by plausible
```

它需要被量化类型有 `Arbitrary`（随机生成）实例——`Nat`、`List`、`Bool` 等标准类型都有（可 `deriving Arbitrary`）。

> **关键陷阱**：`plausible` **不是证明**！随机测试通过后，它用 `sorry` 收尾关闭目标——编译会警告
> `declaration uses sorry`，`#print axioms` 会显示依赖 `sorryAx`。它的价值在于**写证明前快速找反例**：
> 如果你以为 `∀ n, n + m = m + n` 成立，`plausible` 帮你确认（或推翻）；确认后再写真正的证明（这里用 `Nat.add_comm`）。
> 把 `by plausible` 留在正式代码里等于留了个 `sorry`，证明无效。

对比记忆：

| 工具 | 强度 | 适用 | 是否真证明 |
|---|---|---|---|
| `#eval` 断言 | 单点 | 快速看结果 | 否（只是求值） |
| `#guard_msgs` | 单点 | 固化输出回归测试 | 否（断言信息） |
| `decide` | 完全 | 可判定命题 | **是**（内核计算） |
| `plausible` | 随机抽样 | 找反例、增信心 | 否（用 `sorry` 收尾） |
| 手写证明 / `simp`/`omega` | 完全 | 一般定理 | **是** |

## 40.6 测试会失败的代码

测试不只是验证"对的"，也要验证"错误处理是对的"。用 `try/catch` 测异常路径：

```lean
def safeDiv (a b : Nat) : IO Nat := do
  if b == 0 then throw (IO.userError "divide by zero") else pure (a / b)

#eval (try safeDiv 6 2 catch _ => pure 0)   -- 3
#eval (try safeDiv 6 0 catch _ => pure 0)   -- 0（除零被捕获，走兜底分支）
```

这覆盖了第23章 IO 异常处理的测试面：正常路径返回 `3`，异常路径被 `catch` 接住返回 `0`。
完善的测试套件应当同时覆盖成功与失败两类路径。

---

> 上一章：[39 · 可变状态](39-mutable-state.md) ｜ 下一章：[41 · 与 Lean 交互与精细化](41-interacting-elaboration.md) ｜ 返回：[README](../README.md)
