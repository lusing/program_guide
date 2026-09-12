/-
文件: 08_modules_projects/sections_variables.lean
描述: Lean 4 section 与 variable 命令
编译: lake build Lean4Tutorial.Examples.ModulesProjects.SectionsVariables
-/

namespace Lean4Tutorial.Examples.ModulesProjects.SectionsVariables

/-! # section 简介 -/

-- section 用于组织代码和共享变量/假设
-- 与 namespace 不同，section 不影响定义的名称
-- section 结束后，其中的 variable 会被自动清理
-- 但定义仍然可以访问（它们不在 section 的命名空间内）

/-! # 基本 section -/

section BasicSection

  -- 在 section 内定义变量
  variable (x y : Nat)

  -- 定义的函数会自动包含 section 中的变量作为参数
  def sum : Nat := x + y

  def product : Nat := x * y

end BasicSection

-- 注意：sum 和 product 仍然可以访问
-- 但它们的类型会自动包含变量参数
#check sum      -- Nat → Nat → Nat
#check product  -- Nat → Nat → Nat

-- 调用时需要传入参数
def sum_result : Nat := sum 3 4       -- 7
def product_result : Nat := product 3 4   -- 12

/-! # variable 命令 -/

-- variable 命令声明变量，这些变量会被之后的定义自动包含
-- 这可以避免在每个函数中重复写相同的参数

section VariablesDemo

  -- 声明类型变量
  variable {α : Type}

  -- 声明值变量
  variable (xs : List α)

  -- 定义会自动获得这些变量作为参数
  def myLength : Nat := xs.length

  def myHead? : Option α := xs.head?

end VariablesDemo

-- 这些定义的类型自动包含了变量
-- myLength : {α : Type} → List α → Nat
-- myHead? : {α : Type} → List α → Option α

def len_demo : Nat := myLength [1, 2, 3]    -- 3
def head_demo : Option Nat := myHead? [1, 2, 3]  -- some 1

/-! # 隐式变量 -/

-- 使用花括号 {} 声明隐式变量（类型推断）

section ImplicitVars

  variable {α β γ : Type}

  -- 这些函数自动有隐式类型参数
  def compose (f : β → γ) (g : α → β) (x : α) : γ :=
    f (g x)

  def flip (f : α → β → γ) (b : β) (a : α) : γ :=
    f a b

end ImplicitVars

-- 调用时不需要显式指定类型参数
def composed : Nat := compose (· * 2) (· + 1) 3   -- 8
def flipped : Nat := flip (fun x y => x - y) 3 10  -- 7

/-! # 多个变量声明 -/

section MultiVars

  -- 可以一次声明多个同类型的变量
  variable (a b c : Nat)

  -- 也可以声明不同类型的变量
  variable (s : String)
  variable (p : Bool)

  -- 定义会自动包含所有需要的变量
  -- 注意：只有实际使用的变量才会被包含

  def sum3 : Nat := a + b + c
  -- sum3 类型：Nat → Nat → Nat → Nat
  -- 只使用了 a, b, c，没有 s 和 p

  def greeting : String := s ++ "!"
  -- greeting 类型：String → String
  -- 只使用了 s

  def cond : Nat := if p then a else b
  -- cond 类型：Bool → Nat → Nat → Nat
  -- 使用了 p, a, b

end MultiVars

def sum3_demo : Nat := sum3 1 2 3       -- 6
def greeting_demo : String := greeting "hello"  -- "hello!"
def cond_demo : Nat := cond true 10 20   -- 10

/-! # 假设变量 -/

-- variable 也可以声明命题假设（证明参数）

section HypothesisVars

  variable (n : Nat)
  variable (h : n > 0)

  -- 使用假设的定义
  def pred_val : Nat := n - 1

  -- 定理也可以使用
  theorem pred_plus_one : pred_val + 1 = n := by
    simp [pred_val]
    <;> omega

end HypothesisVars

-- pred_val 的类型包含假设
-- pred_val : ∀ (n : Nat), n > 0 → Nat

def pred_demo : Nat := pred_val 5 (by decide)    -- 4

/-! # 嵌套 section -/

-- section 可以嵌套
-- 内层 section 可以访问外层的变量

section OuterSection

  variable (x : Nat)

  def outer_func : Nat := x + 1

  section InnerSection

    variable (y : Nat)

    -- 可以使用外层的 x 和内层的 y
    def inner_func : Nat := x + y

  end InnerSection

  -- 内层结束后，y 不再可用
  -- 但 inner_func 仍然可以访问（它的类型包含 y）
  -- outer_func 也可以访问

end OuterSection

-- 两个定义都可以访问
def outer_demo : Nat := outer_func 5          -- 6
def inner_demo : Nat := inner_func 3 4        -- 7

/-! # section 与 namespace 的区别 -/

-- section：
-- - 不影响定义的名称
-- - 用于共享变量和假设
-- - variable 在 end 后自动消失
-- - 定义被提升到外层作用域

-- namespace：
-- - 定义的名称会加上命名空间前缀
-- - 用于组织代码和避免名称冲突
-- - 所有定义都保留在命名空间中
-- - 需要 open 或完全限定名访问

/-! # include 和 omit -/

-- 有时 variable 声明的变量可能不会被自动包含
-- 可以使用 include 强制包含，使用 omit 排除

section IncludeOmitDemo

  variable (a b : Nat)

  -- 正常情况下，只有使用的变量会被包含

  include a
  -- 从这里开始，a 会被强制包含

  def uses_a : Nat := a + 1
  -- uses_a 一定包含 a 参数

  omit a
  -- 从这里开始，a 不再被强制包含

  def no_a : Nat := b + 1
  -- no_a 只包含 b（因为 a 没有被使用，且被 omit 了）

end IncludeOmitDemo

/-! # 类型类变量 -/

-- variable 也可以声明类型类实例参数

section TypeclassVars

  variable {α : Type} [Add α] [Zero α]

  -- 这些定义自动有类型类参数
  def double (x : α) : α := x + x

  def double_zero : α := double (0 : α)

end TypeclassVars

-- 注意：类型类实例也会被自动包含
-- double : {α : Type} → [Add α] → [Zero α] → α → α

-- 可以用于任何有 Add 和 Zero 的类型
def double_nat : Nat := double 5        -- 10
def double_zero_nat : Nat := double_zero (α := Nat)   -- 0

/-! # 使用 variable 的好处 -/

-- 1. 避免重复书写相同的参数
-- 2. 代码更简洁
-- 3. 参数顺序一致，减少错误
-- 4. 类型类实例自动传递

-- 没有 variable 的写法：
def map_without_var {α β : Type} (f : α → β) (xs : List α) : List β :=
  List.map f xs

def filter_without_var {α : Type} (p : α → Bool) (xs : List α) : List α :=
  List.filter p xs

-- 有 variable 的写法：
section WithVar
  variable {α β : Type}
  variable (xs : List α)

  def map' (f : α → β) : List β := List.map f xs
  def filter' (p : α → Bool) : List α := List.filter p xs
  def length' : Nat := xs.length
end WithVar

/-! # 命题证明中的 variable -/

-- 在证明中使用 variable 可以避免重复假设

section ProofVars

  variable (P Q R : Prop)
  variable (hPQ : P → Q)
  variable (hQR : Q → R)

  theorem trans : P → R :=
    fun hP => hQR (hPQ hP)

  theorem contra : ¬R → ¬P :=
    fun hNR hP =>
      have hQ : Q := hPQ hP
      have hR : R := hQR hQ
      hNR hR

end ProofVars

/-! # variable 与归纳证明 -/

section InductionVars

  variable {α : Type}

  -- 列表拼接的性质
  theorem append_nil (xs : List α) : xs ++ [] = xs := by
    induction xs with
    | nil => rfl
    | cons x xs ih =>
      simp [List.cons_append, ih] <;> rfl

  theorem append_assoc (xs ys zs : List α) :
    (xs ++ ys) ++ zs = xs ++ (ys ++ zs) := by
    induction xs with
    | nil => rfl
    | cons x xs ih =>
      simp [List.cons_append, ih] <;> rfl

end InductionVars

/-! # 作用域规则 -/

-- variable 的作用域从声明处开始，到所在的 section 结束
-- 定义中使用了哪些 variable，就会包含哪些

section Scoping

  variable (x : Nat)

  -- 这里定义的函数会包含 x
  def f1 : Nat := x + 1

  variable (y : Nat)

  -- 这里定义的函数会包含 x 和 y（如果使用了的话）
  def f2 : Nat := x + y   -- 包含 x 和 y
  def f3 : Nat := y * 2   -- 只包含 y

end Scoping

-- f1 : Nat → Nat
-- f2 : Nat → Nat → Nat
-- f3 : Nat → Nat

/-! # 最佳实践 -/

-- 1. 合理使用 variable 减少重复
-- 2. 不要过度使用 variable，避免变量过多
-- 3. 将相关的定义放在同一个 section 中
-- 4. 使用 section 组织相关的证明和定义
-- 5. 注意 variable 的作用域

end Lean4Tutorial.Examples.ModulesProjects.SectionsVariables
