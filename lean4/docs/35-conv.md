# 35 · conv 转换战术

**对标**: *Theorem Proving in Lean 4* 第11章（The Conversion Tactic Mode）；*Reference* 第14章。

`rw` 很好用，但它有两个硬限制：(1) 默认重写**所有**匹配项（或加 `[h] at` 也只能选假设，不能选目标里的某一处）；
(2) 它**进不去绑定符内部**（`fun x => ...`、`∀ x, ...` 里的 `x` 被绑死，`rw` 够不着）。
当你要精确改写目标里**某一个子项**时，就用 `conv`——它让你"钻进"表达式的某个位置再做改写。

> 本章为纯 Lean 核心战术，无需 Mathlib。`conv` 在 4.34.1 验证通过。

## 35.1 lhs / rhs：聚焦等式的一边

`conv => lhs` 把焦点移到等式（或关系）左边，之后的战术只作用于左边：

```lean
example (a b c : Nat) (h : a = b) : a + c = b + c := by
  conv => lhs; rw [h]      -- 只把左边的 a 换成 b，右边不动

example (a b : Nat) (h : b = 0) : a = a + b := by
  conv => rhs; rw [h, Nat.add_zero]   -- 聚焦右边 a + b，化简成 a
```

没有 `conv` 时，第一例的 `rw [h]` 会把左右两边的 `a` 都换掉（虽然这里恰好无害），
但当左右都含 `a` 而只想改一边时，`conv => lhs` 是唯一精确的手段。

## 35.2 enter：钻进绑定符

`enter [x]` 进入 `fun`/`∀`/`→` 的绑定符，把绑定的变量"释放"出来供改写：

```lean
example : (fun x : Nat => 0 + x) = (fun x => x) := by
  conv => lhs; enter [x]; rw [Nat.zero_add]
```

这里 `rw [Nat.zero_add]`（`0 + x = x`）直接作用于 lambda **体内**的 `0 + x`——
普通的 `rw` 做不到，因为 `x` 被 `fun x =>` 绑住了。`enter` 还能一次进多层：
`enter [x, y]`、`enter [1, x]`（先进第 1 个参数再进 binder）。

## 35.3 arg：聚焦第 i 个参数

`arg n` 把焦点移到当前应用的第 `n` 个参数：

```lean
example (f : Nat → Nat) (a : Nat) : f (a + 0) = f a := by
  conv => lhs; arg 1; rw [Nat.add_zero]   -- 钻进 f 的第 1 个参数 (a + 0)
```

`f (a + 0)` 是 `f` 作用于 `(a + 0)`；`arg 1` 聚焦那个参数，于是 `rw` 只在它内部生效，
不会去碰 `f` 本身或等式右边。

## 35.4 pattern：按形态定位

`pattern p` 聚焦所有匹配模式 `p` 的子项：

```lean
example (a b : Nat) : a + 0 + b = a + b := by
  conv => lhs; pattern _ + 0; rw [Nat.add_zero]
```

`a + 0 + b` 解析为 `(a + 0) + b`，`pattern _ + 0` 命中内层的 `a + 0`，`rw` 把它化掉。

> **注意**：`pattern` 命中**多处**时，改写一处可能让其余处的位置失效（conv 用位置定位）。
> 多出现场景更稳的写法是 `conv => lhs; simp`（让 simp 一次扫平），或用 `pattern` 后接 `simp`。

## 35.5 conv at h：改写假设

`conv` 不止能改目标，也能改假设——`conv at h => ...`：

```lean
example (n : Nat) (h : 0 + n = 0) : n = 0 := by
  conv at h => lhs; rw [Nat.zero_add]   -- 把假设 h 的左边 0 + n 化成 n
  exact h                               -- 现在 h : n = 0，正好是目标
```

## 35.6 conv 内的归约：whnf / simp / dsimp

`conv` 块里能用任何作用于"单个表达式"的战术。归约类最常用：

```lean
-- whnf：归约到弱头范式（含 beta-归约）
example : (fun x => x + x) 5 = 10 := by
  conv => lhs; whnf; simp        -- whnf 把 (fun x => x+x) 5 beta-归约成 5 + 5，simp 算出 10

example (n : Nat) : (fun m => m + 1) n = n + 1 := by
  conv => lhs; whnf

-- simp / dsimp：在聚焦的子项上化简
example (xs : List Nat) : (xs ++ []).length = xs.length := by
  conv => lhs; simp

example : (2 + 3) * (4 + 5) = 45 := by
  conv => lhs; simp
```

> **版本陷阱**：4.34.1 的 conv 归约战术名是 `whnf`、`simp`、`dsimp`——**没有** `beta`/`beta_reduce`/
> `zeta`/`zeta_reduce` 这些独立名字（网上旧资料常写 `conv => beta`，在新版会报
> "unexpected identifier"）。beta-归约用 `whnf` 或 `simp` 即可达成。

## 35.7 conv 与 Mathlib 战术

`conv` 是核心机制，块内同样能调用 Mathlib 的 `ring_nf`、`norm_num`、`field_simp` 等——
这在"只想规范化等式某一边的代数表达式"时极有用。关键要点：conv 只改写**聚焦的那一处**，
不会自动闭合整个等式，所以要么把某一边/某一子项规范成与另一边**逐字相同**的形态，
要么规范后再补一步 `rfl`/`ring`。例如 `example : 2 ^ 10 = 1024 := by conv => lhs; norm_num`
（聚焦左边、`norm_num` 算出 `1024`，与右边逐字相同故闭合）；又如 `conv => lhs; arg i; ring_nf`
钻进某个参数子项做代数规范化。这类组合在手工调整证明目标的局部形态时非常顺手。

**何时用 conv 速查**：

| 场景 | 手段 |
|---|---|
| 只改等式一边 | `conv => lhs`/`rhs` |
| 改写 `fun`/`∀` 体内 | `conv => enter [x]` |
| 改写某个参数子项 | `conv => arg i` |
| 按形态定位子项 | `conv => pattern p` |
| 改写假设的局部 | `conv at h => ...` |
| 局部归约/化简 | `conv => ...; whnf`/`simp`/`ring_nf` |

---

> 上一章：[34 · 逻辑深入与经典推理](34-logic-classical.md) ｜ 下一章：[36 · 归纳类型深入](36-inductive-deep.md) ｜ 返回：[README](../README.md)
