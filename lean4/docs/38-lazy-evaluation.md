# 38 · 惰性求值

**对标**: *Functional Programming in Lean*（Lazy Evaluation / Streams 相关章节）；*Reference* 第18章。

Haskell 默认惰性（call-by-need），Lean 默认**严格**（call-by-value）：函数参数在调用前就求值完毕。
但 Lean 提供了按需惰性的工具——`Thunk`（记忆化延迟值）和 `partial`/惰性列表，让你也能构造无穷数据结构、
短路计算。本章讲清楚 Lean 的求值策略、如何手动惰性化，以及一个绕不开的根本约束：**Lean 是全函数语言**。

> 本章为纯 Lean 核心，在 4.34.1 验证。

## 38.1 严格求值：Lean 的默认策略

```lean
def double (n : Nat) : Nat := n * 2
#eval double (3 + 4)   -- 14：先算出 3 + 4 = 7，再传给 double
```

参数 `3 + 4` 在 `double` 被调用**之前**就归约为 `7`。这与 Haskell 不同（Haskell 会把 `3+4` 原样传入，
用到时才算）。严格求值简单、可预测，但浪费在"算了用不到"的场景——这时需要手动惰性化。

## 38.2 Thunk：记忆化的延迟值

`Thunk α` 是"一个还没算、但算过一次就记住的 `α`"。它包装一个 `Unit → α`，首次 `.get` 时求值并**缓存**：

```lean
def t : Thunk Nat := Thunk.mk (fun () => 21 * 2)
#eval t.get          -- 42
#check @Thunk.mk     -- @Thunk.mk : (Unit → α) → Thunk α
```

记忆化是 `Thunk` 区别于裸 `fun () => ...` 的关键——同一个 `Thunk` 多次 `.get` 只算一次：

```lean
def expensive : Thunk Nat := Thunk.mk (fun () => (List.range 100).sum)
#eval expensive.get   -- 4950
#eval expensive.get   -- 4950（第二次命中缓存，不重算 List.range 100 的求和）
```

`Thunk` 在核心库里到处用作"延迟字段"——比如 `IO` 的某些缓冲、`LazyList` 的尾部。

## 38.3 Lean 是全函数语言：无穷结构不能裸定义

这是 Lean 与 Haskell 惰性流的**根本差异**。Haskell 里 `nats = 1 : map (+1) nats` 是合法的无穷列表；
Lean 里直接写会**编译失败**：

```lean
inductive LList (α : Type u) where
  | nil : LList α
  | cons : α → Thunk (LList α) → LList α

-- ✗ 编译失败：Lean 要求所有递归终止
def countFrom (n : Nat) : LList Nat :=
  .cons n (Thunk.mk (fun () => countFrom (n + 1)))
-- 报错：fail to show termination for countFrom ... ⊢ n + 1 < n
```

即使递归调用包在 `Thunk.mk (fun () => ...)` 里"延迟"了，Lean 的终止检查器**仍会检查它**——
而且 Lean **不做余归纳（coinductive）的 productivity 检查**，它只认结构递归或 `termination_by` 给的良基测度。
`countFrom (n + 1)` 的参数在增大，没有任何递减测度，所以被拒。这是 Lean "全函数"（每个函数都终止）设计的直接后果：
它保证了逻辑一致性（`Part`/`Computable` 那套可计算性理论、`decide` 的可信度都依赖于此）。

## 38.4 partial：用 unsafe 语义造无穷惰性结构

要造无穷结构，用 `partial def`——它**跳过终止检查**，用 `unsafe` 语义编译。代价是 `partial` 定义
不能进入内核检验的证明（不能用来 `rw`/`exact` 证定理），但**可以 `#eval`**，正好用于惰性数据流：

```lean
inductive LList (α : Type u) where
  | nil : LList α
  | cons : α → Thunk (LList α) → LList α
  deriving Inhabited          -- partial 要求返回类型可证 Nonempty

partial def countFrom (n : Nat) : LList Nat :=
  .cons n (Thunk.mk (fun () => countFrom (n + 1)))

-- take 在 n 上结构递归，是终止的普通 def
def LList.take : Nat → LList α → List α
  | 0, _ => []
  | _, .nil => []
  | n + 1, .cons x xs => x :: take n xs.get

partial def LList.map (f : α → β) : LList α → LList β
  | .nil => .nil
  | .cons x xs => .cons (f x) (Thunk.mk (fun () => map f xs.get))

partial def LList.filter (p : α → Bool) : LList α → LList α
  | .nil => .nil
  | .cons x xs =>
      if p x then .cons x (Thunk.mk (fun () => filter p xs.get))
      else filter p xs.get

#eval LList.take 5 (countFrom 1)                              -- [1, 2, 3, 4, 5]
#eval LList.take 4 (LList.map (· * 10) (countFrom 1))         -- [10, 20, 30, 40]
#eval LList.take 3 (LList.filter (fun n => n % 2 == 0) (countFrom 1))  -- [2, 4, 6]
```

`countFrom 1` 是无穷的 `[1, 2, 3, …]`，但 `take 5` 只强制求值前 5 个——`Thunk` 让尾部"用到才算"，
`map`/`filter` 也只在被 `take` 拉取时逐元素推进。这就是惰性求值的威力：**无穷结构 + 有限消费 = 终止**。

> **版本陷阱**：`partial def` 要求返回类型可证 `Nonempty`（它内部要造一个"占位默认值"）。
> 给归纳类型加 `deriving Inhabited`（或 `deriving Nonempty`）即可，否则报
> "could not prove that the type ... is nonempty"。

## 38.5 库里的惰性列表：LazyList 与 Std.Stream

自己写 `partial` 惰性列表适合教学；生产代码用现成的：

- **`LazyList α`**（在 **Batteries**，非核心）：构造子 `LazyList.nil` / `LazyList.cons a (fun () => rest)`，
  配套 `LazyList.map`/`filter`/`take`/`toList`/`range`/`iterate` 等。`LazyList.range` 给无穷自然数流。
- **`Std.Stream`**：核心里有 `Stream`（已弃用，指向 `Std.Stream`），是另一种惰性流。

> **版本陷阱**：纯 Lean 4.34.1 **核心不含 `LazyList`**（`#check LazyList` 报 unknown），它在 Batteries 包；
> 核心里的 `Stream` 已弃用，提示改用 `Std.Stream`。要惰性列表就 `import Batteries`（或经 Mathlib 间接获得）。

## 38.6 何时用惰性

| 场景 | 手段 |
|---|---|
| 延迟一次昂贵计算、可能用不到 | `Thunk` |
| 缓存一次计算结果反复用 | `Thunk`（自带记忆化） |
| 无穷序列 / 流 | `partial def` + 惰性列表，或 Batteries `LazyList` |
| 短路（找到即停） | 惰性 `filter`/`find?` + `take 1` |
| 需要进入证明的逻辑 | **避免** `partial`（它不可用于内核证明），改用结构递归 + `termination_by` |

惰性与 Lean 的全函数性是一对张力：`Thunk` 给你"按需"，但"无穷"必须靠 `partial` 的 unsafe 语义，
且这类定义被隔离在证明体系之外。理解这条边界，才能既享受惰性的表达力，又不破坏 Lean 的逻辑可信度。

---

> 上一章：[37 · 可计算性](37-computability.md) ｜ 下一章：[39 · 可变状态](39-mutable-state.md) ｜ 返回：[README](../README.md)
