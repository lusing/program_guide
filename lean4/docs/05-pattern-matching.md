# 05 · 模式匹配与递归

> 对应示例：`examples/03_pattern_matching/pattern_matching.lean`

## 5.1 match 表达式

```lean
-- 对自然数：0 与 _+1 是 Nat 构造子的模式写法
def isZero : Nat → Bool
  | 0     => true
  | _ + 1 => false

#eval isZero 0    -- true
#eval isZero 5    -- false

-- 对列表
def isEmpty {α : Type} : List α → Bool
  | []      => true
  | _ :: _  => false

-- match 可以作为表达式出现在任何位置
def describe (n : Nat) : String :=
  match n with
  | 0 => "零"
  | 1 => "一"
  | _ => "很多"
#eval describe 2    -- "很多"
```

**模式的花样写法**：

```lean
-- 嵌套模式：直接匹配到第二层构造子
def second? {α : Type} : List α → Option α
  | _ :: x :: _ => some x
  | _           => none
#eval second? [1, 2, 3]   -- some 2

-- 析取模式：多个模式共享一个右值
def isSmallPrime (n : Nat) : Bool :=
  match n with
  | 2 | 3 | 5 | 7 => true
  | _             => false

-- as-模式（@）：既匹配结构又保留整体
def tail? {α : Type} : List α → Option (List α)
  | []       => none
  | l@(_::t) => some t     -- l 绑定整个列表，t 绑定尾部

-- 守卫：模式后跟 if 条件
def sign (n : Int) : String :=
  match n with
  | Int.ofNat n => if n == 0 then "zero" else "positive"
  | _           => "negative"
```

## 5.2 if-let 与 let-else（Lean 4.30+ 的现代语法）

处理 `Option` 等"单构造子或失败"类型时的惯用语法糖：

```lean
-- if let：匹配成功则进入分支
def printHead (l : List Nat) : String :=
  if let some h := head? l then
    s!"head = {h}"
  else
    "empty"

-- let ... else 是 do 记法的特性：模式失败时执行 | 后的分支
def headOrZero (l : List Nat) : Nat := Id.run do
  let some h := head? l | return 0
  return h

#eval printHead [7, 8]    -- "head = 7"
#eval headOrZero []       -- 0
```

## 5.3 等式编译器（equation compiler）

用多个等式定义函数时，Lean 的等式编译器会检查**模式覆盖完整性**，并自动生成便于证明的等式引理（`foo.eq_1`、`foo.eq_def` 等，`simp [foo]` 可用）：

```lean
-- 阶乘
def factorial : Nat → Nat
  | 0     => 1
  | n + 1 => (n + 1) * factorial n

#eval factorial 5   -- 120

-- 等式引理自动可用：
example : factorial 3 = 6 := by simp [factorial]
example : factorial 5 = 120 := rfl

-- 斐波那契
def fib : Nat → Nat
  | 0     => 0
  | 1     => 1
  | n + 2 => fib (n + 1) + fib n

#eval fib 10    -- 55
```

**结构性递归的证明义务**：Lean 默认尝试结构递归（参数在递归调用中"变小"）。无法自动证明终止时，需要 `termination_by`（第 5.5 节）。

## 5.4 尾递归与累加器

`fib` 是指数级递归，工程上常用累加器改写为线性/尾递归：

```lean
-- 尾递归版：参数在每次调用中"消耗"，栈安全且高效
def fibFast (n : Nat) : Nat :=
  go n 0 1
where
  go : Nat → Nat → Nat → Nat
    | 0,     a, _ => a
    | n + 1, a, b => go n b (a + b)

#eval fibFast 50    -- 12586269025

-- where 子句：辅助定义的局部作用域写法（替代 let/嵌套 def）
def quickreverse {α : Type} (l : List α) : List α := go l []
where
  go : List α → List α → List α
    | [],    acc => acc
    | x::xs, acc => go xs (x :: acc)

#eval quickreverse [1, 2, 3]   -- [3, 2, 1]
```

## 5.5 有根递归（Well-founded Recursion）

递归结构不"明显变小"时，显式给出**度量**（`termination_by`）与**递减证明**（`decreasing_by`）：

```lean
-- 阿克曼函数：字典序度量 (m, n)
def ackermann : Nat → Nat → Nat
  | 0,     n     => n + 1
  | m + 1, 0     => ackermann m 1
  | m + 1, n + 1 => ackermann m (ackermann (m + 1) n)
  termination_by m n => (m, n)   -- 元组自动按字典序比较

#eval ackermann 3 4   -- 125

-- 欧几里得 gcd：第二个参数严格递减
def myGcd : Nat → Nat → Nat
  | 0,     n => n
  | m + 1, n => myGcd (n % (m + 1)) (m + 1)
  termination_by m _ => m      -- 度量：第一个参数
  decreasing_by exact Nat.mod_lt _ (Nat.succ_pos _)   -- 递减义务：n % (m+1) < m+1

#eval myGcd 12 8    -- 4
```

**终止性证明是证明，不是注释**：`decreasing_by` 里写的是战术证明。`termination_by` 省略时 Lean 依次尝试结构递归、大小递减启发式。理解这套机制对写"非常规递归"（区间二分、互递归等）至关重要。

## 5.6 互递归与 partial

```lean
-- 互递归函数（mutual 块）
mutual
  def isEven : Nat → Bool
    | 0     => true
    | n + 1 => isOdd n
  def isOdd : Nat → Bool
    | 0     => false
    | n + 1 => isEven n
end

#eval isEven 10   -- true
#eval isOdd 7     -- true
```

`partial def` 跳过终止性检查（生成不安全的代码，**不能用于证明**，仅供纯计算场景）：

```lean
-- partial：放弃终止性证明换表达自由（证明中不可使用）
partial def collatz (n : Nat) (fuel : Nat) : List Nat :=
  match fuel with
  | 0 => []
  | fuel + 1 =>
    if n ≤ 1 then [n]
    else n :: collatz (if n % 2 == 0 then n / 2 else 3 * n + 1) fuel

#eval collatz 27 20   -- [27, 82, 41, 124, 62, 31, 94, 47, ...]
```

---

> 上一章：[04 · 归纳类型](04-inductive-types.md) ｜ 下一章：[06 · 类型类](06-typeclasses.md) ｜ 返回：[README](../README.md)
