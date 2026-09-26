# 19 · 常用高级战术

> 对应示例：`examples/16_advanced_tactics/advanced_tactics.lean`

本章按"战术 → 能力边界 → 实现位置 → 实战模式"组织。所有战术的源码都在 `Mathlib/Tactic/`（202 个文件）或 Lean 核心。

## 19.1 ring — 交换半环/环等式

实现：`Mathlib/Tactic/Ring/`（Horner 范式比较）。**能**：任何 `CommSemiring`/`CommRing` 上只含 `+ - * ^` 的恒等式。**不能**：带假设（如 x≠0）、不等式、非交换结构（用 `noncomm_ring`）。

```lean
import Mathlib.Tactic.Ring

example (a b : ℤ) : (a + b) * (a - b) = a^2 - b^2 := by ring
example (x y : ℝ) : (x + y)^3 = x^3 + 3*x^2*y + 3*x*y^2 + y^3 := by ring
example (R : Type) [CommSemiring R] (a b : R) :
    (a + b)^2 = a^2 + 2*a*b + b^2 := by ring

-- ring_nf：只化简不关闭目标（把两边变成范式；相同则 rfl 收尾）
example (a b : ℝ) : (a + b)^2 = a^2 + 2*a*b + b^2 + 0 := by ring_nf

-- 非交换版本（Mathlib.Tactic.NoncommRing）
example (R : Type) [Ring R] (a b : R) : (a + b) - (b + a) + a = a := by noncomm_ring
```

## 19.2 linarith / nlinarith — 线性（非线性）算术

实现：`Mathlib/Tactic/Linarith/`（Fourier–Motzkin 消元）。**能**：序域/序环上的线性（不）等式组合。**不能**：非线性项（nlinarith 有限支持乘积展开）。

```lean
import Mathlib.Tactic.Linarith

example (x y : ℝ) (h1 : x ≤ y) (h2 : y ≤ x + 1) : x ≤ y + 2 := by linarith
example (a b c : ℤ) (h1 : a > b) (h2 : b > c) : a > c := by linarith

-- linarith [额外引理]：把补充事实喂给求解器
example (x : ℝ) (hx : 0 ≤ x^2) : 0 ≤ x^2 + 1 := by linarith

-- nlinarith：处理少量非线性（平方非负是标配补充）
example (x y : ℝ) : x^2 + y^2 ≥ 2 * x * y := by
  nlinarith [sq_nonneg (x - y)]
example (x y : ℝ) (h : x^2 + y^2 ≤ 1) : -1 ≤ x := by
  nlinarith [sq_nonneg y]
```

## 19.3 omega — Presburger 算术

实现：Lean 核心（`Init/Tactics.lean:1529`，4.5 起内置）。**能**：`ℕ`/`ℤ`/`Int` 上的线性算术，含 `%`、`/`（常数除数）、`min`/`max`、类型转换。**不能**：乘法含两个变量、实数。

```lean
-- omega 无需 import Mathlib——核心战术
example (a b c : ℤ) (h1 : a + b > 0) (h2 : b + c > 0) (h3 : a + c > 0) :
    a + b + c > 0 := by omega

example (x y : ℤ) (h : 2 * x + 3 * y = 7) (h' : x ≥ 0) (h'' : y ≥ 0) :
    x = 2 ∧ y = 1 := by omega

-- 处理 Nat 的截断减法与取余（比 linarith 强的关键场景）
example (n m : ℕ) (h : n ≥ 2 * m) : n - m ≥ m := by omega
example (n : ℕ) : n % 5 < 5 := by omega
```

## 19.4 norm_num — 具体数值计算

实现：`Mathlib/Tactic/NormNum/`（可扩展插件式框架）。**能**：具体数值等式/不等式、素性、整除、阶乘、二项式、根号等（插件逐个扩展）。

```lean
import Mathlib.Tactic.NormNum

example : 2 + 3 * 4 = 14 := by norm_num
example : 2^10 = 1024 := by norm_num
example : (123 : ℤ) * 456 = 56088 := by norm_num
example : Nat.choose 10 3 = 120 := by decide   -- choose 走内核计算更直接
example : Nat.Prime 97 := by norm_num          -- 素性扩展在 Mathlib.Tactic.NormNum.Prime
example : (6 : ℚ) / 4 = 3 / 2 := by norm_num

-- norm_num [引理]：给化简器补充 rewrite
example (x : ℝ) (h : x = 2) : x^2 + 1 = 5 := by norm_num [h]
```

## 19.5 positivity — 正性推理

实现：`Mathlib/Tactic/Positivity/`。**目标形态**：`0 ≤ e`、`0 < e`、`e ≠ 0`，按表达式结构递归归因：

```lean
import Mathlib.Tactic.Positivity

example (x y : ℝ) (hx : 0 < x) (hy : 0 < y) : 0 < x * y := by positivity
example (n : ℕ) : 0 ≤ (n : ℝ) := by positivity
example (x : ℝ) : 0 ≤ x^2 := by positivity
example (x : ℝ) (hx : 0 < x) : 0 < x + |x| := by positivity
```

## 19.6 field_simp 与 cancel_denoms — 分式清理

```lean
import Mathlib.Tactic.FieldSimp

-- field_simp：通分消分母；当前版本通常自己就能收尾（不必再 <;> ring）
example (a b c : ℝ) (hb : b ≠ 0) (hc : c ≠ 0) :
    (a / b) * (b / c) = a / c := by
  field_simp

example (x y : ℝ) (hy : y ≠ 0) :
    x / y + y / x = (x^2 + y^2) / (x * y) := by
  field_simp
```

## 19.7 abel — 交换（加）群规范化

```lean
import Mathlib.Tactic.Abel

example (a b c d : ℤ) : (a + b) + (c + d) = (a + d) + (b + c) := by abel
example (G : Type) [AddCommGroup G] (x y z : G) : x + y + z = z + y + x := by abel
```

## 19.8 simp 家族进阶

```lean
-- simpa using e ≈ simp 后 exact e（两端都化简）
example (n : ℕ) (h : 0 + n = n + 1) : n = n + 1 := by simpa using h
example (l : List ℕ) (h : l ++ [] = [1, 2]) : l = [1, 2] := by simpa using h

-- simp?：让 simp 报告它实际用了哪些引理，便于换成 simp only（第20章）
example (n : ℕ) : n + 0 = n := by simp?

-- simp_arith 已废弃（现为 simp +arith 的简写）；这类线性算术目标用 omega 更稳
example (n m : ℕ) (h : n ≤ m) : n + 1 ≤ m + 1 := by omega
```

## 19.9 aesop — 通用证明搜索

实现：独立包（`.lake/packages/aesop`，由 mathlib 依赖）。基于规则的表格式搜索，`@[aesop]` 属性注册规则。

```lean
import Mathlib.Tactic.Common   -- aesop 及常用战术的入口

example (P Q R : Prop) (h1 : P → Q) (h2 : Q → R) (h3 : P) : R := by aesop

example {α : Type} {P Q : α → Prop} (h : ∀ x, P x → Q x) :
    (∀ x, P x) → ∀ x, Q x := by aesop

-- aesop (add safe apply [Nat.succ_le_succ])：给搜索加料
```

## 19.10 fun_prop — 函数性质装配器

`fun_prop`（`Mathlib/Tactic/FunProp/`）专门组装"这个 lambda 函数连续/可测/可微/可积"的证明：

```lean
import Mathlib.Tactic.FunProp
import Mathlib.Topology.Continuous                 -- Continuous 的 fun_prop 规则
import Mathlib.MeasureTheory.Constructions.BorelSpace.Basic  -- ℝ 的 Borel MeasurableSpace
import Mathlib.Analysis.Calculus.FDeriv.Pow        -- Differentiable 的规则

example : Continuous (fun x : ℝ => x^2 + 2*x + 1) := by fun_prop
example : Measurable (fun x : ℝ => x * x) := by fun_prop
example : Differentiable ℝ (fun x : ℝ => x^3 + 2 * x) := by fun_prop
```

**注意**：fun_prop 的规则按性质分散在各主题文件中——`Continuous` 的规则在 Topology 模块，`Measurable` 需要 Borel 实例，`Differentiable` 的在 Analysis.Calculus.FDeriv.*。规则不全时会报 "missing composition rule"，按需补 import 即可。

## 19.11 grind — 新一代自动化（Lean 4 核心）

`grind`（`Init/Grind/`，4.16+ 引入，4.34 已相当成熟）是核心内置的启发式求解器：等式推理（congruence closure）+ 实例搜索 + 算术。mathlib 已在 `hint` 战术中以优先级 200 注册它：

```lean
example (l : List ℕ) : (l ++ []).length = l.length := by grind
example {α : Type} (a b : α) (h : a = b) (l : List α) : a :: l = b :: l := by grind
```

**选用速查**：

| 目标形态 | 首选 | 备选 |
|---------|------|------|
| 环恒等式 | `ring` | `noncomm_ring` |
| 线性 (不)等式 ℝ/ℚ | `linarith` | `nlinarith` |
| Nat/Int 算术含 % / | `omega` | `decide`（小数值） |
| 具体数字 | `norm_num` | `decide` |
| 分式 | `field_simp` + `ring` | `cancel_denoms` |
| 正性 0≤/0< | `positivity` | `nlinarith` |
| 连续/可测/可微 | `fun_prop` | `continuity`/`measurability` |
| 逻辑组装 | `aesop` | `tauto`、`grind` |
| 等式+结构 | `grind` | `simp_all` |

---

> 上一章：[18 · 测度论与概率论](18-measure-probability.md) ｜ 下一章：[20 · 定理检索与 Mathlib 工作流](20-mathlib-workflow.md) ｜ 返回：[README](../README.md)
