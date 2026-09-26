# 03 · 依赖类型与宇宙

> 对应示例：`examples/02_inductive_types/universes.lean`

## 3.1 Sort：宇宙的真正分层

Lean 的类型宇宙用 `Sort u` 表示（u 是自然数层级），`Type u` 只是 `Sort (u+1)` 的别名，`Prop` 是 `Sort 0`：

```lean
#check Nat        -- Type（即 Type 0 = Sort 1）
#check Type       -- Type 1
#check Type 1     -- Type 2
#check Prop       -- Type（注意：Sort 0 本身在 Type 中！）
#check Sort 0     -- Type，即 Prop : Type
```

宇宙是**累积的**：`Type u` 的元素也是 `Type (u+1)` 的元素。这就是为什么 `Nat : Type` 和 `Nat : Type 3` 都成立。

理解层级的小抄：

| 写法 | 含义 |
|------|------|
| `Sort 0` | `Prop`，命题宇宙 |
| `Sort 1` | `Type 0` = `Type`，普通类型 |
| `Sort 2` | `Type 1`，"类型的类型" |
| `Sort u` | 任意层级（u 是层级变量） |

## 3.2 宇宙多态

函数和类型可以工作在任意宇宙层级。声明里直接写 `u`：

```lean
-- 宇宙多态的恒等函数（universe 变量 u 自动推断）
def id' {α : Type u} (x : α) : α := x
#check @id'       -- {α : Type u_1} → α → α

-- Sort 版本覆盖 Prop：标准库的 id 就是这样写的
#check @id        -- {α : Sort u} → α → α

-- 多宇宙的函数类型构造
def FuncType (α : Type u) (β : Type v) : Type (max u v) := α → β

-- universe 声明：给层级变量起名字、做约束
universe a b
def Pair' (α : Type a) (β : Type b) : Type (max a b) := α × β
```

**max 与 imax**：`Type (max u v)` 是能同时容纳两者的最小宇宙；`imax` 用于处理 `Prop` 的特殊性（`imax u 0 = 0`，保证 ∀ 命题仍在 Prop 中）。日常几乎不需要手写，但读 Mathlib 源码时会遇到。

## 3.3 依赖函数类型（Π 类型）

返回类型可以**依赖于输入值**，写作 `∀ (x : α), β x`（或 `Π x : α, β x`，两者等价）：

```lean
-- 普通多态：返回类型只依赖"类型参数"α，不依赖具体的值 n
#check @List.length   -- {α : Type u} → List α → Nat

-- 真正的依赖函数：返回类型依赖值参数 n
inductive MyVec (α : Type) : Nat → Type where
  | nil  : MyVec α 0
  | cons : α → MyVec α n → MyVec α (n + 1)

-- 索引保持的映射：类型层面保证长度不变
def vMap {α β : Type} (f : α → β) : {n : Nat} → MyVec α n → MyVec β n
  | _, MyVec.nil       => MyVec.nil
  | _, MyVec.cons x xs => MyVec.cons (f x) (vMap f xs)

-- 安全取首元素：非空性是索引的一部分
def vHead {α : Type} {n : Nat} : MyVec α (n + 1) → α
  | MyVec.cons x _ => x

#eval vMap (· * 2) (MyVec.cons 1 (MyVec.cons 2 MyVec.nil))  -- cons 2 (cons 4 nil)
#eval vHead (MyVec.cons 7 MyVec.nil)                        -- 7
```

**注**：真正的向量拼接 `MyVec α m → MyVec α n → MyVec α (m + n)` 会立刻撞上索引算术
（`0 + n` 与 `n` 只是命题相等而非定义相等）——这正是依赖类型的"甜蜜点与痛点"，
Mathlib 选择用 `Fin n → α` 函数式表示回避它（见第 16.1 节）。

## 3.4 Prop 宇宙与证明无关性

`Prop` 是命题的宇宙：

```lean
#check True                  -- Prop
#check False                 -- Prop
#check (2 + 2 = 4)           -- Prop
#check (∀ n : Nat, n ≥ 0)    -- Prop
```

`Prop` 的三条关键性质：

1. **证明无关（proof irrelevance）**：一个命题的所有证明在定义上相等。

   ```lean
   example (p q : 2 + 2 = 4) : p = q := rfl   -- 无需任何假设，自动成立
   ```

2. **Impredicative（非直谓）**：`∀ x : α, P x` 即使 α 是任意大宇宙，结果仍在 `Prop` 中。这让 Mathlib 能在 Prop 里自由量化任意类型。

3. **Prop 可消除到任意宇宙**，但反过来不行：`Type` 里的数据不能无条件"消除"成 `Prop` 的证明（类型与证明的职责分离）。

## 3.5 依赖对（Sigma）与子类型

```lean
-- Σ (n : Nat), Vector α n：第二个分量的类型依赖第一个分量
def pair : Σ n : Nat, List Nat := ⟨2, [1, 2]⟩
#eval pair.2        -- [1, 2]

-- 子类型 {x : α // p x}：值 + 性质证明的打包（Init/Core.lean）
def PosNat := {n : Nat // n > 0}
def three : PosNat := ⟨3, by decide⟩
#eval three.1       -- 3
#check three.2      -- three.1 > 0（证明伴随值一起流动）

-- Mathlib 中 {x // x ∈ s}、NonZero 等都基于子类型
```

## 3.6 类型标注与 show

```lean
def x : Nat := 5

-- show T from e：告诉精化器目标类型，也常用于"把目标改成定义等值的形式"
example : 1 + 1 = 2 := show 2 = 2 from rfl

-- by 块里用 show 换目标：把 ((fun x => x + 1) 2) 这种"未展开"的目标
-- 换成定义等值的 2 + 1，更便于阅读
example : (fun x => x + 1) 2 = 3 := by
  show 2 + 1 = 3
  rfl
```

---

> 上一章：[02 · 基础类型与函数](02-basics.md) ｜ 下一章：[04 · 归纳类型](04-inductive-types.md) ｜ 返回：[README](../README.md)
