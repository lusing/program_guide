# 02 · 基础类型与函数

> 对应示例：`examples/01_basics/basics.lean`

## 2.1 基本数据类型

```lean
-- 自然数 (Nat)：非负整数，Lean 中最重要的类型
def n : Nat := 42
#check n   -- Nat
#eval n    -- 42

-- 整数 (Int)：由 Nat 通过 ofNat / negSucc 两个构造子生成
def z : Int := -7
#check z   -- Int
#eval Int.negSucc 6      -- -7（negSucc k 表示 -(k+1)）

-- 布尔值 (Bool)
def b1 : Bool := true
def b2 : Bool := false
#eval b1 && !b2          -- true（&& 是与，! 是非）
#eval if 3 < 5 then "yes" else "no"   -- "yes"

-- 字符串 (String)：UTF-8 编码的不可变字符串
def s : String := "Lean 4"
#eval s.length           -- 6（按 Unicode 码点计数）

-- 字符 (Char)：单个 Unicode 码点
def c : Char := 'A'
#eval c.isUpper          -- true
#eval 'λ'.toNat          -- 955（码点值）

-- 浮点数 (Float)：IEEE 754 双精度
def f : Float := 3.14
#eval f * 2              -- 6.28

-- 单位类型 (Unit)：只有一个值 ()，类似其他语言的 void
def u : Unit := ()

-- 空类型 (Empty)：没有任何值，表示"不可能发生"
-- （无法构造 Empty 的项，也没有 #eval 演示）
```

**Nat 的内部表示**：Lean 4 的 `Nat` 编译后使用 GMP 大整数（小数字是机器字），是**二进制表示**而非 Peano 一元表示。源码层面 `Nat` 定义（`Init/Prelude.lean`）只有两个构造子：

```lean
-- Nat 的真实定义（Init/Prelude.lean）：
-- inductive Nat where
--   | zero : Nat
--   | succ : Nat → Nat
-- 但编译器对字面量与 +、* 等有原生实现，不会展开成一元数

#eval 2^64 + 1    -- 18446744073709551617（大数运算毫无压力）
```

## 2.2 数值字面量与 OfNat

数字字面量是多态的：`42` 可以是任何实现 `OfNat` 类型类的类型的值：

```lean
#check (42 : Nat)     -- Nat
#check (42 : Int)     -- Int
#check (42 : Float)   -- Float

-- OfNat 类型类的核心（Init/OfNat.lean）：
-- class OfNat (α : Type u) (n : Nat) where
--   ofNat : α
-- 因此 42 : Int 实际是 OfNat.ofNat (α := Int) 42
```

`0` 和 `1` 更特殊：`Zero α` / `One α` 类型类提供 `0 : α`、`1 : α`（`Init/Prelude.lean`）——这就是为什么抽象代数里到处需要 `[Zero R]`、`[One R]` 约束。

## 2.3 函数定义

### 基本函数定义

```lean
-- 单参数函数：参数名在前、类型在后，返回类型在最后一个冒号后
def double (n : Nat) : Nat := n + n
#eval double 5    -- 10
#check double     -- Nat → Nat

-- 多参数函数
def add (m n : Nat) : Nat := m + n
#eval add 3 4     -- 7
#check add        -- Nat → Nat → Nat（箭头右结合：Nat → (Nat → Nat)）

-- 同类型参数可合并标注
def add2 (m n : Nat) : Nat := m + n
```

### 匿名函数 (Lambda)

```lean
-- 完整形式
#check fun (x : Nat) => x + 1    -- Nat → Nat

-- 靠类型推断省略标注
#check fun x => x + (1 : Nat)    -- Nat → Nat

-- 多参数 lambda
#eval (fun x y => x * y) 6 7     -- 42

-- 运算符节（dot notation）：· 是参数占位符
#check (· + 1)                    -- Nat → Nat
#eval (· + 1) 5                   -- 6
#eval (· * ·) 3 4                 -- 12（每个 · 是独立参数）
#eval [1, 2, 3].map (· * 10)      -- [10, 20, 30]
```

### 柯里化与部分应用

多参数函数本质上是返回函数的函数，因此可以**部分应用**：

```lean
def adder (n : Nat) : Nat → Nat := fun m => n + m
#eval (adder 3) 4     -- 7
#eval adder 3 4       -- 7（函数应用左结合，两种写法等价）

def add10 : Nat → Nat := adder 10    -- 固定第一个参数
#eval add10 5         -- 15
```

### 函数组合与管道

```lean
-- ∘ 是函数组合（Function.comp）：(g ∘ f) x = g (f x)
#eval ((· + 1) ∘ (· * 2)) 3    -- 7：先 *2 再 +1

-- |> 是管道运算符：x |> f = f x，数据流从左到右
#eval 3 |> (· * 2) |> (· + 1)  -- 7
#eval "hello" |> String.toUpper |> (String.dropRight · 2)   -- "HEL"（|> 把值喂给参数末位，函数在前时需占位符）

-- <| 是反向应用（低优先级），减少括号
#eval List.length <| [1, 2, 3] ++ [4]    -- 4
```

### 高阶函数

```lean
def applyTwice (f : Nat → Nat) (x : Nat) : Nat := f (f x)
#eval applyTwice (· * 2) 3   -- 12

-- 标准库经典高阶函数
#eval List.map (· ^ 2) [1, 2, 3, 4]          -- [1, 4, 9, 16]
#eval List.filter (· % 2 == 0) [1,2,3,4,5]   -- [2, 4]
#eval List.foldl (init := 0) (· + ·) [1,2,3,4,5]  -- 15
```

## 2.4 多态函数与隐式参数

花括号 `{α : Type}` 标注的**隐式参数**由类型推断自动填充：

```lean
def identity {α : Type} (x : α) : α := x

#eval identity 5          -- 5
#eval identity "hello"    -- "hello"
#eval identity (3, 4)     -- (3, 4)

-- @ 前缀把所有隐式参数变成显式，便于观察真实类型
#check @identity          -- {α : Type} → α → α
#check @identity Nat      -- Nat → Nat（手动提供 α）

-- 多态组合
def compose {α β γ : Type} (g : β → γ) (f : α → β) : α → γ :=
  fun x => g (f x)
#eval compose (· + 1) (· * 2) 3   -- 7

-- 标准库版本用宇宙多态写法（见第3章）：
#check @id            -- {α : Sort u} → α → α
#check @Function.comp -- {α β γ} → (β → γ) → (α → β) → α → γ
```

## 2.5 类型推断与类型标注

```lean
-- 推断成功：从 n * 3 反推 n : Nat
def triple n := n * 3

-- 空列表需要标注：没有元素信息可推断
-- #eval [].length                    -- 报错：无法推断元素类型
#eval ([] : List Nat).length         -- 0

-- 类型标注的几种写法
def x : Nat := 5
def y := (5 : Nat)

-- 注：def 的类型位置不能只用 _ 凭空推断（会报 inferDefTypeFailed），需要上下文
def w : String := "anything"
```

## 2.6 元组

```lean
-- Prod（二元组），记号 α × β
def p : Nat × String := (42, "answer")
#eval p.1     -- 42（投影用点号）
#eval p.2     -- "answer"
#eval p.fst   -- 42（等价写法）

-- 嵌套元组表示三元组
def triple' : Nat × String × Bool := (1, "a", true)

-- 模式匹配解构
def swap {α β : Type} : α × β → β × α
  | (a, b) => (b, a)
#eval swap (1, 2)   -- (2, 1)

-- let 解构
def demo : Nat :=
  let (a, b) := (3, 4)
  a * b
#eval demo    -- 12
```

## 2.7 字符串操作

```lean
-- 连接
#eval "Hello" ++ " " ++ "world"   -- "Hello world"

-- 长度、大小写、分割
#eval String.length "Lean"        -- 4
#eval "Lean".toUpper              -- "LEAN"
#eval "Hello".dropRight 2         -- "Hel"
#eval "a,b,c".splitOn ","         -- ["a", "b", "c"]

-- 字符串插值：s! 宏，{} 内是任意可 toString 的表达式
def name := "Lean"
def version := 4
#eval s!"Hello, {name} {version}!"        -- "Hello, Lean 4!"

-- Lean 4 没有三引号多行字符串，用 \n 转义或 intercalate 拼接
#eval String.intercalate "\n" ["第一行", "第二行"]

-- String ↔ List Char 转换
#eval "λμ".toList                  -- ['λ', 'μ']
#eval String.mk ['a', 'b']         -- "ab"
#eval "AB".utf8ByteSize            -- 2（UTF-8 字节数；4.34 起由 utf8ByteLength 改名）
```

**Repr 与 toString**：`#eval` 显示值靠 `Repr` 类型类；字符串转换靠 `ToString`。自定义类型用 `deriving Repr` 自动生成（见第4章）。

## 2.8 Array：工程代码的主力容器

链表 `List` 适合教学，但 Lean 4 的实际代码大量使用 `Array`——带引用计数的数组（纯函数式接口 + 唯一引用时原地更新）：

```lean
-- 字面量与构造
#eval #[1, 2, 3]                    -- Array Nat
#eval Array.mk [1, 2, 3]            -- #[1, 2, 3]

-- push 是摊还 O(1)（List 的 ++ 是 O(n)）
#eval #[1, 2].push 3                -- #[1, 2, 3]

-- 索引访问的三种姿势
def arr : Array Nat := #[10, 20, 30]
#eval arr[1]!      -- 20（!：信任边界，越界 panic）
#eval arr[5]?      -- none（安全版本，返回 Option）
#eval arr.size     -- 3

-- do 记法 + 局部可变变量
def sumArray (a : Array Nat) : Nat := Id.run do
  let mut total := 0
  for x in a do
    total := total + x
  return total
#eval sumArray #[1, 2, 3, 4]    -- 10
```

其他常用容器：`ByteArray`（原始字节）、`HashMap`/`HashSet`（4.34 起核心提供）、`Fin n`（小于 n 的自然数，是矩阵索引的标准选择，见第16章）。

---

> 上一章：[01 · Lean 4 简介与环境搭建](01-intro-setup.md) ｜ 下一章：[03 · 依赖类型与宇宙](03-universes.md) ｜ 返回：[README](../README.md)
