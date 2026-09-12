/-
文件: 03_pattern_matching/equation_compiler.lean
描述: Lean 4 等式定义（阶乘、斐波那契）
编译: lake build Lean4Tutorial.Examples.PatternMatching.EquationCompiler
-/

namespace Lean4Tutorial.Examples.PatternMatching.EquationCompiler

/-! # 等式定义（Equation Compiler）-/

-- Lean 支持使用等式的方式定义递归函数
-- 可以直接写多个等式子句，而不用写 match 表达式
-- 这就是所谓的"等式编译器"（equation compiler）

/-! # 阶乘函数 -/

-- 使用 match 表达式定义阶乘
def factorial_match (n : Nat) : Nat :=
  match n with
  | 0 => 1
  | k + 1 => (k + 1) * factorial_match k

-- 使用等式定义阶乘（更简洁）
def factorial : Nat → Nat
  | 0 => 1
  | n + 1 => (n + 1) * factorial n

-- 计算示例
def fac_0 : Nat := factorial 0     -- 1
def fac_1 : Nat := factorial 1     -- 1
def fac_5 : Nat := factorial 5     -- 120
def fac_10 : Nat := factorial 10   -- 3628800

/-! # 斐波那契数列 -/

-- 斐波那契数列的递归定义
-- fib(0) = 0
-- fib(1) = 1
-- fib(n+2) = fib(n+1) + fib(n)
def fib : Nat → Nat
  | 0 => 0
  | 1 => 1
  | n + 2 => fib (n + 1) + fib n

def fib_0 : Nat := fib 0     -- 0
def fib_1 : Nat := fib 1     -- 1
def fib_2 : Nat := fib 2     -- 1
def fib_5 : Nat := fib 5     -- 5
def fib_10 : Nat := fib 10   -- 55

-- 注意：这个朴素的斐波那契实现效率很低（指数时间）
-- 因为每次计算都要递归计算两个子问题

/-! # 加法 -/

-- 自然数加法的递归定义
def add : Nat → Nat → Nat
  | m, 0 => m
  | m, n + 1 => (add m n) + 1

def add_3_4 : Nat := add 3 4    -- 7

-- 乘法
def mul : Nat → Nat → Nat
  | _, 0 => 0
  | m, n + 1 => add (mul m n) m

def mul_3_4 : Nat := mul 3 4    -- 12

-- 幂运算
def power : Nat → Nat → Nat
  | _, 0 => 1
  | m, n + 1 => mul (power m n) m

def power_2_10 : Nat := power 2 10   -- 1024

/-! # 列表上的等式定义 -/

-- 列表长度
def length {α : Type} : List α → Nat
  | [] => 0
  | _ :: rest => 1 + length rest

def len_example : Nat := length [1, 2, 3, 4, 5]   -- 5

-- 列表拼接
def append {α : Type} : List α → List α → List α
  | [], ys => ys
  | x :: xs, ys => x :: append xs ys

def append_example : List Nat := append [1, 2] [3, 4, 5]
-- [1, 2, 3, 4, 5]

-- 列表反转
def reverse {α : Type} : List α → List α
  | [] => []
  | x :: xs => reverse xs ++ [x]

def reverse_example : List Nat := reverse [1, 2, 3]   -- [3, 2, 1]

/-! # 多参数等式定义 -/

-- 列表的 zip 函数
def zip {α β : Type} : List α → List β → List (α × β)
  | [], _ => []
  | _, [] => []
  | x :: xs, y :: ys => (x, y) :: zip xs ys

def zip_example : List (Nat × String) := zip [1, 2, 3] ["a", "b", "c"]
-- [(1, "a"), (2, "b"), (3, "c")]

-- 取列表的前 n 个元素
def take {α : Type} : Nat → List α → List α
  | 0, _ => []
  | _, [] => []
  | n + 1, x :: xs => x :: take n xs

def take_3 : List Nat := take 3 [1, 2, 3, 4, 5]    -- [1, 2, 3]
def take_10 : List Nat := take 10 [1, 2, 3]        -- [1, 2, 3]

-- 删除列表的前 n 个元素
def drop {α : Type} : Nat → List α → List α
  | 0, xs => xs
  | _, [] => []
  | n + 1, _ :: xs => drop n xs

def drop_2 : List Nat := drop 2 [1, 2, 3, 4, 5]    -- [3, 4, 5]

/-! # 布尔函数的等式定义 -/

-- 逻辑与
def and : Bool → Bool → Bool
  | true, true => true
  | _, _ => false

-- 逻辑或
def or : Bool → Bool → Bool
  | false, false => false
  | _, _ => true

-- 异或
def xor : Bool → Bool → Bool
  | true, false => true
  | false, true => true
  | _, _ => false

/-! # 自然数比较 -/

-- 小于等于
def leq : Nat → Nat → Bool
  | 0, _ => true
  | _ + 1, 0 => false
  | m + 1, n + 1 => leq m n

def leq_example1 : Bool := leq 3 5     -- true
def leq_example2 : Bool := leq 5 3     -- false
def leq_example3 : Bool := leq 5 5     -- true

-- 等于
def eq_nat : Nat → Nat → Bool
  | 0, 0 => true
  | 0, _ + 1 => false
  | _ + 1, 0 => false
  | m + 1, n + 1 => eq_nat m n

def eq_example1 : Bool := eq_nat 5 5   -- true
def eq_example2 : Bool := eq_nat 3 5   -- false

/-! # 最大公约数（欧几里得算法）-/

-- 使用有根递归定义 GCD
-- Lean 需要知道递归是终止的
def gcd : Nat → Nat → Nat
  | 0, n => n
  | m + 1, n =>
    have : n % (m + 1) ≤ m := by
      apply Nat.mod_lt
      <;> simp
      <;> omega
    gcd (n % (m + 1)) (m + 1)
termination_by _ m n => m + 1
decreasing_by
  simp_wf
  <;> omega

def gcd_example1 : Nat := gcd 48 18    -- 6
def gcd_example2 : Nat := gcd 100 75   -- 25
def gcd_example3 : Nat := gcd 7 13     -- 1

/-! # 结构递归 vs 有根递归 -/

-- 上面的阶乘、斐波那契等函数使用的是"结构递归"
-- 即递归调用的参数是输入参数的"子结构"
-- 例如 factorial (n + 1) 调用 factorial n，n 是 n+1 的直接子结构

-- 而 gcd 使用的是"有根递归"（well-founded recursion）
-- 递归调用的参数不一定是子结构，但某种"度量"在减小
-- gcd 使用 m + n 作为度量（termination_by）

/-! # 更复杂的例子：插入排序 -/

-- 插入一个元素到已排序的列表中
def insert (x : Nat) : List Nat → List Nat
  | [] => [x]
  | y :: ys =>
    if x ≤ y then x :: y :: ys
    else y :: insert x ys

-- 插入排序
def insertionSort : List Nat → List Nat
  | [] => []
  | x :: xs => insert x (insertionSort xs)

def sort_example : List Nat := insertionSort [3, 1, 4, 1, 5, 9, 2, 6]
-- [1, 1, 2, 3, 4, 5, 6, 9]

/-! # 等式定义的性质 -/

-- 等式定义会自动生成等式定理
-- 例如 factorial 0 = 1
-- 这些定理可以在证明中使用 rfl 或 simp

theorem factorial_zero : factorial 0 = 1 := by rfl
theorem factorial_succ (n : Nat) :
  factorial (n + 1) = (n + 1) * factorial n := by rfl

theorem fib_zero : fib 0 = 0 := by rfl
theorem fib_one : fib 1 = 1 := by rfl
theorem fib_succ_succ (n : Nat) :
  fib (n + 2) = fib (n + 1) + fib n := by rfl

/-! # 使用 where 子句 -/

-- 快速排序（使用 where 子句定义辅助函数）
def quicksort : List Nat → List Nat
  | [] => []
  | x :: xs =>
    quicksort (filter (· ≤ x) xs) ++ [x] ++ quicksort (filter (· > x) xs)
where
  filter (p : Nat → Bool) : List Nat → List Nat
    | [] => []
    | y :: ys =>
      if p y then y :: filter p ys
      else filter p ys

def qsort_example : List Nat := quicksort [3, 1, 4, 1, 5, 9, 2, 6]
-- [1, 1, 2, 3, 4, 5, 6, 9]

end Lean4Tutorial.Examples.PatternMatching.EquationCompiler
