/-
文件: 01_basics/functions.lean
描述: Lean 4 函数定义、匿名函数、高阶函数、柯里化
编译: lake build Lean4Tutorial.Examples.Basics.Functions
-/

namespace Lean4Tutorial.Examples.Basics.Functions

/-! # 函数基本定义 -/

-- 简单函数：计算一个数的两倍
-- 参数类型写在参数名后面，返回类型在冒号后面
def double (x : Nat) : Nat := x * 2

-- 多参数函数
def add (x : Nat) (y : Nat) : Nat := x + y

-- 也可以将参数类型放在一起写
def add' (x y : Nat) : Nat := x + y

-- 函数可以有不同类型的参数
def greet (name : String) (times : Nat) : String :=
  if times = 0 then ""
  else name ++ " " ++ greet name (times - 1)

-- 函数定义中可以使用 where 子句定义局部函数
def factorial (n : Nat) : Nat :=
  if n = 0 then 1
  else n * factorial (n - 1)
where
  -- where 子句中的辅助函数（此例不需要，仅作演示）
  helper (x : Nat) : Nat := x

/-! # 函数类型 -/

-- 函数类型用箭头 → 表示
-- Nat → Nat 表示接受一个 Nat 参数，返回 Nat 的函数
def double_type : Nat → Nat := fun x => x * 2

-- 多参数函数类型：Nat → Nat → Nat
-- 注意：箭头是右结合的，Nat → Nat → Nat 等价于 Nat → (Nat → Nat)
def add_type : Nat → Nat → Nat := fun x y => x + y

/-! # 匿名函数（lambda 表达式）-/

-- 使用 fun 关键字定义匿名函数
def square : Nat → Nat := fun x => x * x

-- 也可以使用 λ 符号（输入 \lambda 或 \lam）
def cube : Nat → Nat := λ x => x * x * x

-- 多参数匿名函数
def multiply : Nat → Nat → Nat := fun x y => x * y

-- 匿名函数可以直接应用
def apply_lambda : Nat := (fun x => x + 1) 5   -- 6

/-! # 函数应用 -/

-- 函数应用：函数名后面跟参数，用空格分隔
def ten : Nat := double 5              -- 10
def fifteen : Nat := add 7 8           -- 15

-- 函数应用优先级最高
def expr1 : Nat := double (3 + 4)      -- double 7 = 14
def expr2 : Nat := double 3 + 4        -- (double 3) + 4 = 10

/-! # 柯里化（Currying）-/

-- 在 Lean 中，所有函数都是自动柯里化的
-- 多参数函数实际上是接受一个参数，返回另一个函数

-- add 5 返回一个新函数，这个新函数接受一个参数并加上 5
def addFive : Nat → Nat := add 5

-- 应用这个部分应用的函数
def eight : Nat := addFive 3           -- 8
def twelve : Nat := addFive 7          -- 12

-- 另一个例子：字符串前缀
def prefix (pre : String) (s : String) : String := pre ++ s

def helloPrefix : String → String := prefix "Hello, "

def helloWorld : String := helloPrefix "World!"     -- "Hello, World!"
def helloLean : String := helloPrefix "Lean 4!"     -- "Hello, Lean 4!"

/-! # 高阶函数 -/

-- 高阶函数：接受函数作为参数，或返回函数的函数

-- 函数作为参数：将函数 f 应用两次
def applyTwice (f : Nat → Nat) (x : Nat) : Nat := f (f x)

-- 使用 applyTwice
def twice_double : Nat := applyTwice double 3       -- double (double 3) = 12
def twice_square : Nat := applyTwice square 2       -- square (square 2) = 16

-- 函数作为返回值
def makeAdder (n : Nat) : Nat → Nat :=
  fun x => x + n

def addThree : Nat → Nat := makeAdder 3
def six : Nat := addThree 3           -- 6

/-! # 函数组合 -/

-- 函数组合运算符 ∘（输入 \circ）
-- (f ∘ g) x = f (g x)
def compose_example : Nat → Nat := double ∘ square

def compose_result : Nat := compose_example 3    -- double (square 3) = 18

-- 自定义函数组合
def comp {α β γ : Type} (f : β → γ) (g : α → β) (x : α) : γ := f (g x)

/-! # 多态函数 -/

-- 恒等函数：适用于任意类型
def identity {α : Type} (x : α) : α := x

def id_nat : Nat := identity 5         -- 5
def id_string : String := identity "hi"  -- "hi"

-- 多态函数也可以作为参数
def applyThreeTimes {α : Type} (f : α → α) (x : α) : α := f (f (f x))

def three_times_double : Nat := applyThreeTimes double 2   -- 16

/-! # let 绑定 -/

-- 使用 let 在表达式中定义局部变量
def complexCalc (x y : Nat) : Nat :=
  let sum := x + y
  let product := x * y
  sum + product

-- let 也可以定义局部函数
def calcWithLocal (n : Nat) : Nat :=
  let square (x : Nat) := x * x
  let cube (x : Nat) := x * square x
  cube n + square n

/-! # 管道运算符 -/

-- 管道运算符 |> 将左边的值作为参数传给右边的函数
-- x |> f 等价于 f x
def pipe_example1 : Nat := 5 |> double           -- 10
def pipe_example2 : Nat := 3 |> double |> square -- square (double 3) = 36

-- 管道运算符在链式调用时很有用
def pipeline : Nat := 10 |> double |> square |> double  -- 800

-- 反向管道 <|
def backward_pipe : Nat := double <| square <| 3   -- 18

/-! # if-then-else 表达式 -/

-- 条件表达式是一个普通的表达式，有返回值
def abs (x : Int) : Int :=
  if x >= 0 then x else -x

def abs_neg : Int := abs (-5)          -- 5
def abs_pos : Int := abs 3             -- 3

-- 嵌套的 if-then-else
def compare (x y : Nat) : String :=
  if x < y then "less than"
  else if x > y then "greater than"
  else "equal"

/-! # 模式匹配简介 -/

-- 使用 match 进行模式匹配（后面章节会详细讲）
def isZero (n : Nat) : Bool :=
  match n with
  | 0 => true
  | _ + 1 => false

def zero_true : Bool := isZero 0       -- true
def one_false : Bool := isZero 1       -- false

end Lean4Tutorial.Examples.Basics.Functions
