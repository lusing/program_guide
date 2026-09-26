# 39 · 可变状态

**对标**: *Functional Programming in Lean*（Mutable State / Imperative Programming）；*Reference* 第18章。

Lean 的内核是纯函数式的，但写算法时命令式风格（可变变量、`for`/`while` 循环、原地改数组）往往更自然、更高效。
Lean 的设计很巧妙：**命令式语法是纯状态单子（state monad）的语法糖**——`do` + `let mut` 脱糖成
`bind`/`StateM`，表面 imperative，底层仍是纯函数。本章讲清这套机制和它的性能含义。

> 本章为纯 Lean 核心（含 `IO`），在 4.34.1 验证。

## 39.1 do + let mut：可变变量的真相

`let mut x := v` 声明一个"可变"变量，`x := e` 更新它。但这只是语法糖——整个 `do` 块脱糖成
状态单子，`x` 是状态的一部分，`x := e` 是 `modify`：

```lean
def sumSquares (n : Nat) : Nat := Id.run do
  let mut total := 0
  for i in List.range n do
    total := total + i * i
  return total
#eval sumSquares 5   -- 30  （0² + 1² + 2² + 3² + 4² = 0+1+4+9+16）
```

`Id.run do ...` 让命令式代码参与**纯定义**（`Id` 是"什么都不包"的单子）。`for i in xs do body`
脱糖成 `xs.forM (fun i => body)`，`let mut total` 的状态在 `StateM` 里流转。所以 `sumSquares`
本质是个纯函数，只是写起来像命令式循环。

## 39.2 Array：累积与原地修改

`Array` 是工程代码的主力容器（连续内存、O(1) 随机访问）。两种修改风格：

```lean
-- 风格一：push 累积（重新绑定 let mut 变量）
def fillArray (n : Nat) : Array Nat := Id.run do
  let mut arr := Array.mkEmpty n      -- 预分配容量 n，避免反复扩容
  for i in List.range n do
    arr := arr.push (i * i)
  return arr
#eval fillArray 5   -- #[0, 1, 4, 9, 16]

-- 风格二：set! 就地写（! 表示信任下标合法，越界则 panic）
def setDemo : IO Unit := do
  let mut arr := #[1, 2, 3]
  arr := arr.set! 0 99
  IO.println arr
#eval setDemo   -- #[99, 2, 3]
```

`Array.mkEmpty n` 预分配容量是关键性能技巧：不预分配时，`push` 到满会触发扩容+拷贝（摊还 O(1) 但有常数开销）。
`set!` 是"带 panic 的下标写"；安全版 `arr.set i v h`（`h : i < arr.size`）要带越界证明，`arr[i]?` 读返回 `Option`。

> **版本陷阱**：Lean 4 有 `a[i] <- v` 的就地赋值语法糖，但它依赖特定单子/`MonadStateOf` 上下文，
> 在某些 `do` 块里不被识别（会把 `<-` 当 bind 解析、报 `OfNat (IO _) v`）。最稳的写法是
> `arr := arr.set! i v` 或 `arr := arr.push x`，跨版本、跨单子都可靠。

## 39.3 while 循环

```lean
def countdown (n : Nat) : IO Unit := do
  let mut k := n
  while k > 0 do
    IO.println k
    k := k - 1
#eval countdown 3
-- 3
-- 2
-- 1
```

`while cond do body` 脱糖成尾递归的状态单子循环。Lean 需要它能终止——`while` 的终止性由
内部用 `partial`/`WellFounded` 机制处理（循环体每次让某测度减小）。

## 39.4 StateM：显式的状态单子

`do` + `let mut` 背后就是 `StateM`。直接用 `StateM σ α`（= `σ → (α × σ)`）能更明确地操控状态：

```lean
#eval ((do modify (· + 1); modify (· * 10); get) : StateM Nat Nat) |>.run 5
-- (60, 60)：状态 5 →(＋1) 6 →(×10) 60；get 把状态作为结果返回，.run 返回 (结果, 终态)
```

三个基本操作：`get`（读状态）、`put s`（写状态）、`modify f`（用 `f` 更新状态）。
`.run s0` 提供初值并返回 `(结果, 终态)`；`.run' s0` 只要结果。`StateM` 适合纯计算里需要"带状态"的场景
（解析器、累加器、计数器）。

## 39.5 状态单子家族：ST / EStateM / MonadStateOf

Lean 的状态机制分层，理解它们能看懂 `IO` 的本质：

```lean
#check @EStateM        -- EStateM : Type → Type → Type → Type → Type（异常 + 状态）
#check @ST             -- ST : Type → Type → Type（带 region 参数的纯状态）
#check @MonadStateOf   -- MonadStateOf 的签名（let mut 脱糖的目标类型类）
```

- **`StateM σ α`**：纯状态，`σ → (α × σ)`。
- **`ST` / `StateRefT`**：带"区域"（region）参数的状态，支持 `let mut` 的就地更新语义。
- **`EStateM ε σ α`**：状态 + 异常（`ε` 是错误类型），是 **`IO` 的底层实现**——
  `IO α` 本质是 `EStateM IO.Error IO.RealWorld α`，把"真实世界"当作一个线性传递的状态令牌。

`MonadStateOf` 是 `let mut` 脱糖时用到的类型类，它让 `x := e` 在不同状态单子里都能工作。

## 39.6 原地修改的性能语义

Lean 的 `Array` "修改"何时真的 O(1) 原地、何时拷贝？答案是**引用计数**：当被修改的数组
**引用计数为 1**（没有别的变量持有它）时，`push`/`set!` 直接在原内存上改；否则先拷贝再改（保持纯语义）。

```lean
def inPlace : IO Unit := do
  let mut arr := #[1, 2, 3]      -- arr 独占，引用计数 1
  arr := arr.set! 0 99           -- 原地修改，O(1)
  IO.println arr
#eval inPlace   -- #[99, 2, 3]
```

这就是为什么 `let mut` + `arr := arr.push ...` 在循环里是高效的：每次 `arr` 都是独占引用，
`push` 走原地路径（容量够时）。理解这一点，才能在 Lean 里写出既有纯函数安全性、又有命令式性能的代码——
这正是 FPLE "Programming, Proving, and Performance" 一章的核心。第29章的 `implemented_by`/profiler
是配套的性能工具。

---

> 上一章：[38 · 惰性求值](38-lazy-evaluation.md) ｜ 下一章：[40 · 测试与属性测试](40-testing.md) ｜ 返回：[README](../README.md)
