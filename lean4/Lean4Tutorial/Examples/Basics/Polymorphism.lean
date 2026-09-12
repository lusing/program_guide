/-
文件: 01_basics/polymorphism.lean
描述: Lean 4 多态函数、类型推断、元组
编译: lake build Lean4Tutorial.Examples.Basics.Polymorphism
-/

namespace Lean4Tutorial.Examples.Basics.Polymorphism

/-! # 多态函数 -/

-- 多态函数：可以操作任意类型的函数
-- 类型参数用花括号 {} 括起来，表示隐式参数（Lean 会自动推断）

-- 恒等函数：返回传入的参数
def id {α : Type} (x : α) : α := x

-- 调用时不需要显式指定类型参数，Lean 会自动推断
def id_nat : Nat := id 5               -- 5
def id_string : String := id "hello"   -- "hello"
def id_bool : Bool := id true          -- true

-- 也可以显式指定类型参数（使用 @ 符号）
def id_explicit : Nat := @id Nat 5     -- 5

-- 或者使用点号表示法
def id_with_type : Nat := id (α := Nat) 5

/-! # 多个类型参数 -/

-- 函数可以有多个类型参数
def pair {α β : Type} (x : α) (y : β) : α × β := (x, y)

def nat_string_pair : Nat × String := pair 42 "answer"
def bool_int_pair : Bool × Int := pair true (-3)

-- 交换二元组的元素
def swap {α β : Type} (p : α × β) : β × α := (p.2, p.1)

def swapped : String × Nat := swap nat_string_pair   -- ("answer", 42)

/-! # 类型推断 -/

-- Lean 的类型推断非常强大，很多时候不需要显式写类型

-- 自动推断参数类型
def triple x := x + x + x
-- #check triple   -- Nat → Nat（从 + 运算符推断）

-- 自动推断返回类型
def greet (name : String) := "Hello, " ++ name
-- #check greet    -- String → String

-- 多态函数的类型参数由使用方式推断
def first {α β : Type} (p : α × β) : α := p.1
def second {α β : Type} (p : α × β) : β := p.2

-- Lean 自动推断 α 和 β
def fst_val : Nat := first (3, "hello")     -- 3
def snd_val : String := second (3, "hello") -- "hello"

/-! # 隐式参数 vs 显式参数 -/

-- 花括号 {} 表示隐式参数（自动推断）
def implicit_id {α : Type} (x : α) : α := x

-- 圆括号 () 表示显式参数（必须手动传入）
def explicit_id (α : Type) (x : α) : α := x

-- 隐式参数：调用时不需要传类型
def imp1 : Nat := implicit_id 42

-- 显式参数：调用时必须传类型
def exp1 : Nat := explicit_id Nat 42

-- 使用 @ 可以将隐式参数变为显式参数
def exp2 : Nat := @implicit_id Nat 42

/-! # 元组（Product Types）-/

-- 二元组（有序对）：α × β
def point2d : Nat × Nat := (3, 4)
def name_age : String × Nat := ("Alice", 30)

-- 访问元组的元素
def x_coord : Nat := point2d.1          -- 3（第一个元素）
def y_coord : Nat := point2d.2          -- 4（第二个元素）
def person_name : String := name_age.1  -- "Alice"
def person_age : Nat := name_age.2      -- 30

-- 也可以使用 prod.fst 和 prod.snd
def fst_example : Nat := Prod.fst point2d    -- 3
def snd_example : Nat := Prod.snd point2d    -- 4

-- 三元组
def triple_val : Nat × String × Bool := (42, "hello", true)

-- 访问三元组元素
def tri_fst : Nat := triple_val.1       -- 42
def tri_snd : String := triple_val.2.1  -- "hello"
def tri_thr : Bool := triple_val.2.2    -- true

-- 或者用括号分组更清晰
def triple2 : Nat × (String × Bool) := (42, ("hello", true))

-- 元组也可以嵌套
def nested : (Nat × Nat) × (String × String) :=
  ((1, 2), ("first", "second"))

/-! # 元组上的多态函数 -/

-- 对元组的第一个元素应用函数
def mapFirst {α β γ : Type} (f : α → γ) (p : α × β) : γ × β :=
  (f p.1, p.2)

-- 对元组的第二个元素应用函数
def mapSecond {α β γ : Type} (f : β → γ) (p : α × β) : α × γ :=
  (p.1, f p.2)

def map_first_result : Nat × String := mapFirst (fun x => x * 2) (5, "hello")
-- (10, "hello")

def map_second_result : Nat × Nat := mapSecond String.length (5, "hello")
-- (5, 5)

-- 对两个元组应用函数
def zipWith {α β γ : Type} (f : α → β → γ) (p1 : α × α) (p2 : β × β) : γ × γ :=
  (f p1.1 p2.1, f p1.2 p2.2)

def add_points : Nat × Nat := zipWith (· + ·) (1, 2) (3, 4)   -- (4, 6)

/-! # Unit 类型 -/

-- Unit 类型只有一个元素：()
-- 类似于其他语言中的 void
def unit_val : Unit := ()

-- Unit 可以看作是 0 元组
-- Unit 的类型等价于空元组

/-! # 类型别名 -/

-- 使用 def 可以定义类型别名
def Point := Nat × Nat
def Person := String × Nat

def origin : Point := (0, 0)
def alice : Person := ("Alice", 30)

-- 类型别名只是别名，与原始类型完全等价
def same_type : Point = Nat × Nat := rfl

/-! # 多态数据结构示例 -/

-- 一个简单的多态包装类型
inductive Box (α : Type) : Type where
  | mk (content : α) : Box α

-- 创建 Box
def boxed_int : Box Nat := Box.mk 42
def boxed_string : Box String := Box.mk "hello"

-- 打开 Box
def unbox {α : Type} (b : Box α) : α :=
  match b with
  | Box.mk x => x

def unboxed_nat : Nat := unbox boxed_int        -- 42
def unboxed_string : String := unbox boxed_string  -- "hello"

-- 对 Box 中的值应用函数
def mapBox {α β : Type} (f : α → β) (b : Box α) : Box β :=
  Box.mk (f (unbox b))

def mapped_box : Box Nat := mapBox (fun x => x * 2) boxed_int
-- Box.mk 84

end Lean4Tutorial.Examples.Basics.Polymorphism
