# 07 · 命题与证明

> 对应示例：`examples/05_propositions/propositions.lean`

## 7.1 柯里-霍华德对应

在 Lean 中，**命题是 Prop 类型的元素，证明是该命题的项**。这个对应贯穿一切：

| 逻辑概念 | 类型概念 | 构造 | 消去 |
|---------|---------|------|------|
| 蕴含 P → Q | 函数类型 | `fun h => ...` | 函数应用 `f h` |
| 合取 P ∧ Q | 积类型（结构） | `⟨hp, hq⟩` | `h.1`、`h.2` |
| 析取 P ∨ Q | 和类型 | `Or.inl hp` | `cases` / `rcases` |
| 全称 ∀ x, P x | 依赖函数 | `fun x => ...` | 应用 `h x` |
| 存在 ∃ x, P x | 依赖对 | `⟨x, hx⟩` | `rcases h with ⟨x, hx⟩` |
| 假 False | 空类型 | — | `False.elim` / `contradiction` |
| 否定 ¬P | P → False | `fun h => ...` | 应用 |

```lean
-- 命题与证明就是类型与项
def p : Prop := 2 + 2 = 4
theorem two_plus_two_eq_four : 2 + 2 = 4 := rfl
#check two_plus_two_eq_four   -- 2 + 2 = 4 : Prop

-- term 模式（直接写证明项）与 tactic 模式（by 块）等价：
theorem t_term : 1 + 1 = 2 := rfl
theorem t_tac  : 1 + 1 = 2 := by rfl
```

## 7.2 逻辑连接词实战

> 本节代码假设所在文件顶部有 `variable {P Q R : Prop} {α β : Type}`——
> 不显式声明的话，自动绑定会把 `R` 推断为任意 `Sort`，导致 `theorem`（要求 Prop）报错。

### 合取 (∧) 与 Iff (↔)

```lean
-- 构造：⟨⟩ 是匿名构造器，按目标类型自动选择构造子
theorem and_intro' (hp : P) (hq : Q) : P ∧ Q := ⟨hp, hq⟩

-- 消去：.1/.2 或 rcases 解构
theorem and_swap : P ∧ Q → Q ∧ P
  | ⟨hp, hq⟩ => ⟨hq, hp⟩

-- Iff 同样是结构：⟨mp, mpr⟩
theorem iff_comm : (P ↔ Q) ↔ (Q ↔ P) :=
  ⟨fun h => ⟨h.2, h.1⟩, fun h => ⟨h.2, h.1⟩⟩

-- constructor 战术：对有"一个构造子"的目标逐一给分量
theorem and_tac : 2 + 2 = 4 ∧ 3 + 3 = 6 := by
  constructor
  · rfl
  · rfl
```

### 析取 (∨)

```lean
theorem or_swap : P ∨ Q → Q ∨ P
  | .inl hp => .inr hp
  | .inr hq => .inl hq

theorem or_elim' (h : P ∨ Q) (hpr : P → R) (hqr : Q → R) : R := by
  cases h with
  | inl hp => exact hpr hp
  | inr hq => exact hqr hq
```

### 否定 (¬) 与爆炸原理

```lean
-- ¬P 就是 P → False（Init/Core.lean: def Not (a : Prop) := a → False）
theorem not_not_intro (h : P) : ¬¬P := fun hn => hn h

-- 从矛盾推出一切
theorem absurd' (hp : P) (hnp : ¬P) : Q := absurd hp hnp
```

## 7.3 经典逻辑

Lean 默认是**构造性**的：`P ∨ ¬P` 不是免费定理。需要时打开 `Classical`：

```lean
-- 经典公理来自 Classical 命名空间（Init/Classical.lean）
open Classical in
theorem em' (P : Prop) : P ∨ ¬P := em P

-- by_cases：经典分情况（Mathlib 中最常用的经典战术之一）
-- by_cases h : P  -- 生成两个子目标：一个带 h : P，一个带 h : ¬P

-- by_contra：反证法
-- by_contra h     -- 目标变成 False，手里有 h : ¬目标

-- push_neg：把 ¬∀ x, P x 推进成 ∃ x, ¬P x 等（需要 import Mathlib）
```

Mathlib 默认大量使用经典逻辑（`open Classical`），初学者不必抗拒：数学定理的证明里经典逻辑是常态。

## 7.4 量词

```lean
-- ∀：intro 引入，应用消去
theorem all_intro' : ∀ n : Nat, n ≥ 0 := fun n => Nat.zero_le n

-- ∃：⟨见证, 证明⟩ 构造，rcases 解构
theorem exists_intro' : ∃ n : Nat, n > 5 := ⟨6, by decide⟩

-- 注意：P 作谓词要显式标注 {P : α → Prop}，
-- 否则自动绑定会把 P 推断成 Prop 而非函数
theorem exists_elim' {α : Type} {P : α → Prop} {Q : Prop}
    (h : ∃ x, P x) (h2 : ∀ x, P x → Q) : Q := by
  rcases h with ⟨x, hx⟩
  exact h2 x hx

-- rcases 的模式可以嵌套多层结构：
-- rcases h with ⟨x, ⟨y, hy⟩, rfl⟩   -- 一次拆三层
```

## 7.5 等式与重写

```lean
-- rfl：定义相等（比"值相等"更强，编译期可判定）
theorem eq_refl' (a : α) : a = a := rfl

-- 等式的基本操作（Init/Core.lean）
theorem eq_ops (h1 : a = b) (h2 : b = c) : a = c := h1.trans h2
example (h : a = b) : b = a := h.symm

-- congrArg：函数保持等式
example (f : α → β) (h : a = b) : f a = f b := congrArg f h

-- rw：用等式重写目标（← 反向）
theorem rewrite_example (x y : Nat) (h : x = y) : x + 0 = y := by
  rw [h]        -- 目标变成 y + 0 = y
  rw [add_zero] -- 或 exact Nat.add_zero y（视导入而定）

-- ▸ ：就地替换（可读性差但 Mathlib 源码常见）
example {α : Type} {P : α → Prop} {a b : α} (h : a = b) : P a → P b := h ▸ id
```

## 7.6 可判定性与 decide

`Decidable p` 把"命题 p"包装成"能算出真假的判定过程"（`Init/Prelude.lean`）：

```lean
-- decide 战术：对 Decidable 命题直接计算得证
example : 2 + 2 = 4 := by decide
example : Nat.Prime 7 := by decide
example : (7 : Nat) % 3 = 1 := by decide

-- decide 的威力来自类型类：DecidableEq、Nat.Prime 的 Decidable 实例等
-- 都是库提供的"判定算法"
#check (inferInstance : Decidable (2 + 2 = 4))

-- Decidable 还能在项级使用：if 需要它
example (n : Nat) : String := if n = 0 then "zero" else "nonzero"
-- ↑ Nat 有 DecidableEq 实例，所以 if n = 0 合法
```

**decide vs rfl**：`rfl` 要求定义相等（编译器展开即可），`decide` 走 `Decidable` 实例的计算+`of_decide_eq_true`。前者快但只能处理 definitional 等式，后者能处理任意可判定命题。

## 7.7 calc 链式证明

```lean
theorem calc_example (a b c : Nat) (h1 : a = b + 1) (h2 : b = c + 2) :
    a = c + 3 := by
  calc
    a = b + 1         := h1
    _ = (c + 2) + 1   := by rw [h2]
    _ = c + 3         := rfl

-- calc 支持不等式链（用 IsTrans 类型类驱动）：
example (a b c d : Nat) (h1 : a < b) (h2 : b ≤ c) (h3 : c < d) : a < d := by
  calc
    a < b := h1
    _ ≤ c := h2
    _ < d := h3
```

---

> 上一章：[06 · 类型类](06-typeclasses.md) ｜ 下一章：[08 · 战术基础](08-tactics.md) ｜ 返回：[README](../README.md)
