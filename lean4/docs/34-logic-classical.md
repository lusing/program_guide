# 34 · 逻辑深入与经典推理

**对标**: *Theorem Proving in Lean 4* 第3-4章（Propositions / Quantifiers）；*Mathematics in Lean* 第3章（Logic）。

第7章建立了"命题即类型、证明即项"的柯里-霍华德基础。本章聚焦**实战层面**：
连接词的 term/tactic 双写法、Lean 默认构造性逻辑与经典逻辑的切换、以及三个最常用的经典战术
`by_cases` / `by_contra` / `push Not`。这些是读 Mathlib 证明、写自己的证明时天天要用的。

> 本章依赖 Mathlib（`tauto`、`push Not`、`by_contra` 等），在 Mathlib4 v4.35.0-rc3 验证。

## 34.1 连接词：term 与 tactic 双写法

每个连接词都有"构造（intro）"和"消去（elim）"两个方向，term 模式和 tactic 模式各有所长：

```lean
import Mathlib.Tactic

variable {P Q R : Prop}

-- term 模式：模式匹配解构，匿名构造子 ⟨⟩ 组装
theorem and_comm' : P ∧ Q → Q ∧ P := fun ⟨hp, hq⟩ => ⟨hq, hp⟩

-- tactic 模式：cases 解构，exact 组装
theorem or_comm' : P ∨ Q → Q ∨ P := by
  intro h
  cases h with
  | inl hp => exact Or.inr hp
  | inr hq => exact Or.inl hq
```

| 连接词 | 构造（intro） | 消去（elim） |
|---|---|---|
| `P ∧ Q` | `⟨hp, hq⟩` / `constructor` | `h.1`、`h.2` / `cases h` / `rcases h with ⟨hp, hq⟩` |
| `P ∨ Q` | `Or.inl hp` / `Or.inr hq` | `cases h` / `rcases h with hp \| hq` |
| `P ↔ Q` | `⟨mp, mpr⟩` / `constructor` | `h.1`（→）、`h.2`（←）/ `h.mp`、`h.mpr` |
| `¬P`（= `P → False`） | `fun h => ...` | 应用 / `absurd` / `contradiction` |

`rcases`/`rintro`（Mathlib）能一次性拆多层嵌套结构，比裸 `cases` 高效得多——
`rcases h with ⟨x, ⟨y, hy⟩, rfl⟩` 一行拆三层，`rfl` 还顺带把等式代入。

## 34.2 经典逻辑三战术

Lean 默认是**构造性**的：`P ∨ ¬P`（排中律）不是免费定理，需要经典选择公理。Mathlib 全程
`open Classical`，所以经典推理是常态。三个主力战术：

```lean
-- by_cases：对某命题分"成立/不成立"两种情况（生成两个子目标）
theorem not_and_or' (h : ¬(P ∧ Q)) : ¬P ∨ ¬Q := by
  by_cases hP : P
  · by_cases hQ : Q
    · exact absurd ⟨hP, hQ⟩ h    -- P 与 Q 都成立 ⇒ P ∧ Q，与 h 矛盾
    · exact Or.inr hQ
  · exact Or.inl hP

-- by_contra：反证法——把目标 ¬G 变成"假设 G 推出 False"
theorem contrapositive (h : P → Q) : ¬Q → ¬P := fun hnq hp => hnq (h hp)
example : ¬¬P → P := by
  intro hnn
  by_contra hn      -- 目标变 False，手里多了 hn : ¬P
  exact hnn hn      -- hnn : ¬¬P 应用到 hn : ¬P 得 False

-- 排中律本身（来自 Classical）
example : P ∨ ¬P := Classical.em P
```

`by_cases h : p` 生成两个子目标：一个带 `h : p`，一个带 `h : ¬p`。`by_contra h` 把当前目标 `G`
替换为 `False` 并引入 `h : ¬G`——这是证明否定命题或"某物存在"的利器。两者背后都是 `Classical.em`。

## 34.3 push Not：把否定推进去

`push Not`（**旧名 `push_neg`，2026 起已弃用**）把外层的 `¬` 推进量词和连接词内部，
`¬∀` 变 `∃¬`、`¬∃` 变 `∀¬`、`¬(a < b)` 变 `b ≤ a` 等。最常用的是改写**假设**：

```lean
theorem demo (h : ¬(∃ x : Nat, x > 0)) : ∀ x : Nat, x ≤ 0 := by
  push Not at h     -- h 从 ¬(∃ x, x > 0) 变成 ∀ x, x ≤ 0
  exact h
```

`push Not at h` 一步把"不存在大于 0 的 x"翻译成"所有 x 都 ≤ 0"，目标随即被 `h` 命中。
没有它，你得手动 `intro x; by_contra; ...` 绕一大圈。它也能作用于目标（`push Not`），
把 `¬(∀ ...)` 形态的目标翻成 `∃ ... ¬` 便于继续。

> **版本陷阱（2026 重要变化）**：`push_neg` 已弃用，编译会警告 "Prefer using `push Not` instead"。
> 新写法是 `push Not`（`push` 是更通用的"把某类操作推进结构"战术族，`Not` 是参数）。
> 旧代码里的 `push_neg`/`push_neg at h` 要相应改成 `push Not`/`push Not at h`。

## 34.4 De Morgan 与命题自动化

经典的 De Morgan 律（`¬(P ∧ Q) ↔ ¬P ∨ ¬Q` 需要排中律）用 `tauto` 一步搞定：

```lean
example : ¬(P ∧ Q) ↔ ¬P ∨ ¬Q := by tauto
example : ¬(P ∨ Q) ↔ ¬P ∧ ¬Q := by tauto
```

`tauto`（`Mathlib.Tactic.Tauto`）是经典命题逻辑的判定过程：任何命题重言式（含 `¬`、`∧`、`∨`、`→`、`↔`）
它都能判。注意第一条 `¬(P ∧ Q) ↔ ¬P ∨ ¬Q` 是**经典**有效的（构造性下只有 `¬P ∨ ¬Q → ¬(P ∧ Q)` 这半边），
`tauto` 默认走经典逻辑所以能证。

> **`push Not` 不等于 De Morgan**：`push Not` 把 `¬(P ∧ Q)` 推成 `P → ¬Q`（curry 形态），
> 而不是 `¬P ∨ ¬Q`。要 De Morgan 的析取形态得靠 `tauto` 或经典推理。两者用途不同：
> `push Not` 用于"把否定推进量词/比较"，`tauto` 用于"判定命题重言式"。

## 34.5 量词推理小结

```lean
-- ∀：intro 引入，应用消去
example : ∀ n : Nat, n ≥ 0 := fun n => Nat.zero_le n
-- ∃：⟨见证, 证明⟩ 构造，rcases/obtain 消去
example : ∃ n : Nat, n > 5 := ⟨6, by decide⟩
theorem exists_demo {α : Type} {p : α → Prop} {q : Prop}
    (h : ∃ x, p x) (h2 : ∀ x, p x → q) : q := by
  obtain ⟨x, hx⟩ := h
  exact h2 x hx
```

`obtain ⟨x, hx⟩ := h`（等价 `rcases h with ⟨x, hx⟩`）是拆 `∃` 的标准动作：拿出见证 `x` 和性质 `hx`。
`use e`（反向）则是证明 `∃` 时给出见证，留下 `p e` 作为新目标。

**战术选用速查**：

| 目标/假设形态 | 首选战术 |
|---|---|
| 分情况讨论某命题真假 | `by_cases h : p` |
| 证明否定命题 / 反证 | `by_contra h` |
| 假设里有 `¬∃`/`¬∀`/`¬(a<b)` | `push Not at h` |
| 命题重言式（纯 ¬∧∨→↔） | `tauto` |
| 拆 `∃`/`∧` 假设 | `obtain`/`rcases` |
| 证 `∃` | `use 见证` |
| 线性算术矛盾收尾 | `omega`/`linarith` |

---

> 上一章：[33 · 滤子](33-filters.md) ｜ 下一章：[35 · conv 转换战术](35-conv.md) ｜ 返回：[README](../README.md)
