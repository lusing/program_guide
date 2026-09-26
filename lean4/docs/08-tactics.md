# 08 · 战术基础

> 对应示例：`examples/06_tactics/tactics.lean`

战术（tactic）是 `by` 块中的证明构建命令。理解战术模式的心智模型：**一个目标（goal）+ 一组局部假设（context），每个战术变换这个状态**。

## 8.1 常用战术速查

| 战术 | 用途 | 来源 |
|------|------|------|
| `intro` / `intros` | 引入蕴含/∀ 的前提 | 核心 |
| `exact` | 用一个项直接完成目标 | 核心 |
| `apply` | 用结论匹配目标，生成前提子目标 | 核心 |
| `refine` | 带 `?_` 占位符的 exact | 核心 |
| `have` | 引入中间结论 | 核心 |
| `let` | 引入局部定义 | 核心 |
| `rw` | 用等式重写 | 核心 |
| `simp` | 用 simp 引理集化简 | 核心 |
| `cases` | 对归纳类型分情况 | 核心 |
| `rcases` / `obtain` | 花式解构（Mathlib.Tactic.RCases） | Mathlib |
| `induction` | 归纳证明 | 核心 |
| `constructor` | 使用目标的构造子 | 核心 |
| `left` / `right` | 选择 ∨ 的一支 | 核心 |
| `exfalso` | 把目标换成 False | 核心 |
| `contradiction` | 从上下文的矛盾关闭目标 | 核心 |
| `ext` | 外延性（函数/集合相等化为逐点相等） | Mathlib |
| `decide` | 计算判定 | 核心 |
| `norm_num` / `ring` / `linarith` / `omega` | 数值/环/线性/整数算术 | 见第19章 |
| `aesop` | 自动证明搜索 | 见第19章 |

**注**：旧教程中的 `refine'` 已废弃——`refine` 本身支持 `?_` 占位符，直接使用即可。

## 8.2 核心战术详解

```lean
-- intro：引入 ∀/→ 的变量与前提
theorem t1 : P → P := by
  intro h      -- h : P 进入上下文
  exact h

-- intro 支持匿名构造器模式：一次性拆包
theorem t2 : P ∧ Q → Q ∧ P := by
  intro ⟨hp, hq⟩    -- 直接解构合取
  exact ⟨hq, hp⟩

-- apply：结论匹配目标，前提变成新目标
theorem t3 (h1 : P → Q) (h2 : P) : Q := by
  apply h1      -- 目标 Q 匹配 h1 的结论，新目标是 P
  exact h2

-- refine：给出证明骨架，?_ 处留子目标
theorem t4 (h : P ∧ Q) : Q ∧ P := by
  refine ⟨?_, ?_⟩
  · exact h.2
  · exact h.1

-- have：前向推理的中间步骤
theorem t5 (h1 : P) (h2 : P → Q) (h3 : Q → R) : R := by
  have hq : Q := h2 h1
  have hr : R := h3 hq
  exact hr

-- suffices："要证 R，只需证 S"（反向 have）
theorem t6 (h1 : P) (h2 : P → Q) (h3 : Q → R) : R := by
  suffices hq : Q from h3 hq
  exact h2 h1
```

## 8.3 解构战术：cases / rcases / obtain

```lean
-- cases：对归纳类型逐构造子分情况
theorem t7 (h : P ∨ Q) : Q ∨ P := by
  cases h with
  | inl hp => exact Or.inr hp
  | inr hq => exact Or.inl hq

-- rcases（Mathlib.Tactic.RCases.Basic）：模式化深度解构
theorem t8 (h : P ∧ (Q ∨ R)) : (P ∧ Q) ∨ (P ∧ R) := by
  rcases h with ⟨hp, hq | hr⟩
  · exact Or.inl ⟨hp, hq⟩
  · exact Or.inr ⟨hp, hr⟩

-- obtain := rcases + 匿名构造器，可读性最好
theorem t9 (h : ∃ n : Nat, n > 5) : ∃ m : Nat, m > 4 := by
  obtain ⟨n, hn⟩ := h
  exact ⟨n, by omega⟩     -- omega 见第19章（或由 hn 直接推）
```

**rcases 模式语法**：`⟨a, b⟩` 拆构造子，`a | b` 分情况，`*` 递归拆，`rfl` 直接代入等式。组合示例：`rcases h with ⟨x, rfl | rfl⟩` 等。

## 8.4 归纳证明

```lean
-- induction：对归纳类型使用其消去子
-- 注意选材：n + 0 = n 是定义相等（Nat.add 对第二参数递归，rfl 直接可证），
-- 教学用 0 + n = n 才能真正看到归纳假设的用法
theorem zero_add' : ∀ n : Nat, 0 + n = n := by
  intro n
  induction n with
  | zero => rfl
  | succ n ih =>
    -- 目标 0 + succ n = succ n；由 add 定义 0 + succ n ≡ succ (0 + n)
    rw [show 0 + Nat.succ n = Nat.succ (0 + n) from rfl, ih]

-- induction 也能对自定义归纳命题用（Even 见第 4.5 节）
theorem even_add_even (hm : Even m) (hn : Even n) : Even (m + n) := by
  induction hm with
  | zero => simpa using hn
  | add2 k ih =>
    -- with 绑定只拿到构造子的显式参数（k : Even n' 与归纳假设 ih），
    -- 隐式的 n' 不具名；用 add_right_comm 作 simp 规则重排目标
    simp only [Nat.add_right_comm]
    exact ih.add2
```

（`simpa using hn` 表示"simp 化简后恰好是 hn"。）

## 8.5 重写与化简

```lean
-- rw：依次用每个等式重写；← 反向
theorem rw_demo (x y z : Nat) (h1 : x = y) (h2 : y = z) : x + 0 = z := by
  rw [Nat.add_zero]   -- x + 0 → x（核心引理，无需 import Mathlib）
  rw [h1, h2]

-- rw 作用于假设：rw [h] at h'
example (x y : Nat) (h : x = y) (h' : x + 1 = 3) : y + 1 = 3 := by
  rw [h] at h'
  exact h'

-- simp：用全局 @[simp] 引理集反复重写
example (n : Nat) : n + 0 = 0 + n := by simp

-- simp only [引理]：白名单模式，可控、可复现（Mathlib 风格指南推荐）
example (n : Nat) : n + 0 = 0 + n := by
  simp only [Nat.add_zero, Nat.zero_add]

-- simp at h：化简假设；simp_all：全部一起化简（强但可能慢/循环，慎用）
example (l : List Nat) (h : l ++ [] = [1]) : l = [1] := by
  simpa using h

-- simpa using e := simp 后 exact e（第19章详述）
```

**simp 的工作原理**（`Init/SimpLemmas.lean` 定义 `Simp.Config`）：所有 `@[simp]` 定理构成有向重写系统，simp 反复应用直到不动点。关键配置：`simp (config := {decide := true})`、`simp_arith`、`simp_all`。自定义引理：

```lean
@[simp]
theorem myList_id : myId (l : List α) = l := rfl
-- 此后 simp 会自动使用它
```

## 8.6 组合子与子目标管理

```lean
-- <;> 把右侧战术应用到左侧产生的所有子目标
-- 注意：simp 引理清单里放 Nat.add_comm 会循环（x+y → y+x → x+y）！
example (n : Nat) : 0 + n = n + 0 := by
  induction n with
  | zero => rfl
  | succ n ih => simp only [Nat.add_succ, Nat.succ_add, ih, Nat.add_zero]

-- · （圆点，输入 \.）聚焦单个子目标；全角 · 与拉丁 • 混用会报错
example : (1 + 1 = 2) ∧ (2 + 2 = 4) := by
  constructor
  · rfl
  · rfl

-- all_goals / any_goals：对所有/任一子目标执行
example : (1 + 1 = 2) ∧ (2 + 2 = 4) := by
  constructor <;> all_goals rfl

-- try：失败也不算错；repeat：反复执行
example (n : Nat) : n + 0 = n := by
  try rw [Nat.add_succ]   -- 不适用时静默跳过
  rfl
```

## 8.7 结构化工具体：ext / congr / by_cases

```lean
-- ext：外延性把"对象相等"化为"逐点/逐字段相等"
example (f g : Nat → Nat) (h : ∀ x, f x = g x) : f = g := by
  ext x       -- 目标变成 f x = g x
  exact h x

example (s t : Set Nat) (h : ∀ x, x ∈ s ↔ x ∈ t) : s = t := by
  ext x; exact h x

-- by_cases：经典二分（需要 Classical；Decidable 命题也可用）
example (P : Prop) [Decidable P] : (P → Q) → (¬P → Q) → Q := by
  intro h1 h2
  by_cases h : P
  · exact h1 h
  · exact h2 h
```

---

> 上一章：[07 · 命题与证明](07-propositions.md) ｜ 下一章：[09 · 结构与记录](09-structures.md) ｜ 返回：[README](../README.md)
