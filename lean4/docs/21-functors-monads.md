# 21 · 函子、应用算子与单子

**对标**: *Functional Programming in Lean* 第4-5章；*Reference* 第18章。

`Functor`/`Applicative`/`Monad` 是三个逐层加强的类型类：`Functor` 只能"把函数映射进上下文"，
`Applicative` 能组合多个带上下文的计算，`Monad` 才允许后续计算依赖前一步的**结果**（`bind`）。

## 21.1 Functor：map 与 `<$>`

```lean
def double (n : Nat) : Nat := n * 2

#eval (some 5).map double        -- some 10
#eval [1, 2, 3].map (· + 1)      -- [2, 3, 4]
#eval double <$> some 5          -- some 10（<$> 是 map 的中缀记法）

-- 自定义类型实现 Functor：为 Tree 写实例
inductive Tree (α : Type u) where
  | leaf : Tree α
  | node : Tree α → α → Tree α → Tree α
deriving Repr

def Tree.map (f : α → β) : Tree α → Tree β
  | .leaf => .leaf
  | .node l x r => .node (l.map f) (f x) (r.map f)

instance : Functor Tree where
  map := Tree.map

#eval (Tree.node Tree.leaf 3 Tree.leaf).map (· * 2)
-- Tree.node (Tree.leaf) 6 (Tree.leaf)
```

实现 `Functor` 时只需提供 `map`，`mapConst`、`<$$>` 等由默认实现派生。

## 21.2 Applicative：`<*>`

```lean
#eval (some fun n => n + 1) <*> some 4   -- some 5
```

`<*>` 把"装在上下文里的函数"应用到"装在上下文里的值"上。典型用途是组合多参数函数：

```lean
#eval (pure (· + ·)) <*> some 2 <*> some 3   -- some 5
```

## 21.3 Monad 与 do 的关系

`do` 块是 `bind` 链的语法糖——下面两行完全等价：

```lean
#eval (do let x ← some 3; pure (x + 1) : Option Nat)   -- some 4
#eval ((some 3).bind (fun x => pure (x + 1)) : Option Nat)   -- some 4
```

> **版本陷阱**：核心库中 `List` 只有 `Functor`，没有 `Monad`/`Bind` 实例（`[1,2,3] >>= f` 不可用）。
> 列表单子实例由 Mathlib 提供；纯 Lean 环境下用 `.flatMap`：

```lean
#eval [1, 2, 3].flatMap (fun x => [x, -x])   -- [1, -1, 2, -2, 3, -3]

-- Id（恒等单子）：do 记法可以写在纯代码里，立即求值
#eval (pure 3 : Id Nat)   -- 3
```

---

> 上一章：[20 · 定理检索与 Mathlib 工作流](20-mathlib-workflow.md) ｜ 下一章：[22 · do-记法深入](22-do-notation.md) ｜ 返回：[README](../README.md)
