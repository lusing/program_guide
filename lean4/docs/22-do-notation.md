# 22 · do-记法深入

**对标**: *Reference* 第18章；*Functional Programming in Lean* 第4章。

## 22.1 do 的脱糖规则

`do` 块中每条语句依次脱糖：`let x ← e; rest` 变成 `e.bind (fun x => rest)`，
`pure e` 原样保留，普通 `let`/赋值仍是纯绑定。脱糖发生在任何单子上，包括 `Option`：

```lean
def optAdd (a b : Option Nat) : Option Nat := do
  let x ← a
  let y ← b
  pure (x + y)
#eval optAdd (some 2) (some 3)   -- some 5
#eval optAdd none (some 3)       -- none（任一步失败，整链短路）
```

## 22.2 Id.run：用 do 写纯计算

`Id` 是"什么都不包"的单子，所以 `Id.run do ...` 能让命令式风格的代码参与纯定义：

```lean
def sumListDo (xs : List Nat) : Nat := Id.run do
  let mut s := 0
  for x in xs do
    s := s + x
  return s
#eval sumListDo [1, 2, 3, 4]   -- 10

def countWords (s : String) : Nat := Id.run do
  let mut n := 0
  let mut inWord := false
  for c in s do
    if c.isWhitespace then
      inWord := false
    else if !inWord then
      inWord := true
      n := n + 1
  return n
#eval countWords "hello  lean world"   -- 3
```

## 22.3 return 与提前退出

`do` 块里 `return` 提前给出整个块的结果——在 `Option`/`Except` 单子里这就是"提前退出"：

```lean
def firstEven (xs : List Nat) : Option Nat := do
  for x in xs do
    if x % 2 == 0 then return x
  none
#eval firstEven [1, 3, 4, 7]   -- some 4
```

## 22.4 StateM：最小的状态单子

`StateM σ α` = `σ → (α, σ)`。`get` 读取、`modify` 更新状态，`.run s0` 提供初值并返回 `(结果, 终态)`：

```lean
#eval (do modify (· + 1); modify (· * 10); get : StateM Nat Nat) |>.run 5
-- (60, 60)：状态 5 → 6 → 60，get 把状态作为结果返回，.run 返回 (结果, 终态)
```

---

> 上一章：[21 · 函子、应用算子与单子](21-functors-monads.md) ｜ 下一章：[23 · IO 与程序入口](23-io.md) ｜ 返回：[README](../README.md)
