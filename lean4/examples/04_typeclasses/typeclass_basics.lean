/-
文件: 04_typeclasses/typeclass_basics.lean
描述: Lean 4 类型类定义与实例（Printable示例）
编译: lake build Lean4Tutorial.Examples.Typeclasses.TypeclassBasics
-/

namespace Lean4Tutorial.Examples.Typeclasses.TypeclassBasics

/-! # 类型类简介 -/

-- 类型类（Typeclass）是一种抽象接口，定义了一组操作
-- 不同的类型可以为同一个类型类提供不同的实现（实例）
-- 类似于 Java 的接口或 Haskell 的 typeclass

-- 使用 class 关键字定义类型类
-- Printable 类型类表示"可以转换为字符串的类型"
class Printable (α : Type) where
  toString : α → String

-- 类型类有一个参数 α，表示"为哪种类型提供实现"
-- toString 是类型类的方法

/-! # 定义类型类实例 -/

-- 使用 instance 关键字定义类型类实例
-- 为 Nat 类型实现 Printable

instance : Printable Nat where
  toString n := Lean4Tutorial.Examples.Typeclasses.TypeclassBasics.toString n
  where
    toString (n : Nat) : String :=
      match n with
      | 0 => "0"
      | n' + 1 => Nat.succ n' |> Nat.repr

-- 更简单的方式：使用标准的 toString
instance natPrintable : Printable Nat where
  toString n := toString n

-- 为 Bool 类型实现 Printable
instance : Printable Bool where
  toString b := if b then "true" else "false"

-- 为 String 类型实现 Printable
instance : Printable String where
  toString s := s

-- 为 Char 类型实现 Printable
instance : Printable Char where
  toString c := String.singleton c

/-! # 使用类型类 -/

-- 定义一个使用 Printable 类型类的函数
-- [Printable α] 表示需要 α 有 Printable 实例
def printIt {α : Type} [Printable α] (x : α) : String :=
  Printable.toString x

-- 使用示例
def print_nat : String := printIt 42          -- "42"
def print_bool : String := printIt true       -- "true"
def print_string : String := printIt "hello"  -- "hello"
def print_char : String := printIt 'a'        -- "a"

-- 泛型打印函数
def printPair {α β : Type} [Printable α] [Printable β] (p : α × β) : String :=
  "(" ++ printIt p.1 ++ ", " ++ printIt p.2 ++ ")"

def print_pair : String := printPair (42, true)
-- "(42, true)"

/-! # 多参数类型类 -/

-- 类型类可以有多个类型参数
-- 例如：可以将类型 α 转换为类型 β

class Convertible (α β : Type) where
  convert : α → β

-- Nat 可以转换为 String
instance : Convertible Nat String where
  convert n := toString n

-- Bool 可以转换为 Nat（true -> 1, false -> 0）
instance : Convertible Bool Nat where
  convert b := if b then 1 else 0

-- 使用多参数类型类
def convertExample {α β : Type} [Convertible α β] (x : α) : β :=
  Convertible.convert x

def nat_to_string : String := convertExample (42 : Nat)   -- "42"
def bool_to_nat : Nat := convertExample true               -- 1

/-! # 带默认实现的类型类 -/

-- 类型类的方法可以有默认实现
-- 如果实例不提供实现，就使用默认的

class Describable (α : Type) where
  describe : α → String
  name : α → String
  -- 默认实现：name 就是 describe 的前10个字符
  name x :=
    let s := describe x
    if s.length ≤ 10 then s else s.take 10 ++ "..."

-- 为 Person 类型实现 Describable
-- 只提供 describe，name 使用默认实现
structure Person where
  name : String
  age : Nat
deriving Repr

instance : Describable Person where
  describe p := s!"Person(name={p.name}, age={p.age})"

def alice : Person := ⟨"Alice", 30⟩

def describe_alice : String := Describable.describe alice
-- "Person(name=Alice, age=30)"

def name_alice : String := Describable.name alice
-- "Person(na..."（取前10个字符加省略号）

-- 也可以覆盖默认实现
structure Book where
  title : String
  author : String

instance : Describable Book where
  describe b := s!"《{b.title}》by {b.author}"
  name b := b.title  -- 覆盖默认实现，用书名作为 name

def book : Book := ⟨"Lean 4 教程", "张三"⟩

def describe_book : String := Describable.describe book
-- "《Lean 4 教程》by 张三"

def name_book : String := Describable.name book
-- "Lean 4 教程"

/-! # 类型类的扩展 -/

-- 我们可以定义一个"可打印列表"的函数
-- 要求元素类型是 Printable 的

def printList {α : Type} [Printable α] (l : List α) : String :=
  match l with
  | [] => "[]"
  | [x] => "[" ++ printIt x ++ "]"
  | x :: xs => "[" ++ printIt x ++ ", " ++ printListTail xs ++ "]"
where
  printListTail {α : Type} [Printable α] : List α → String
    | [] => ""
    | [x] => printIt x
    | x :: xs => printIt x ++ ", " ++ printListTail xs

def print_nat_list : String := printList [1, 2, 3, 4, 5]
-- "[1, 2, 3, 4, 5]"

def print_bool_list : String := printList [true, false, true]
-- "[true, false, true]"

/-! # 类型类的实例合成 -/

-- Lean 可以自动合成类型类实例
-- 例如：如果 α 和 β 都是 Printable 的，那么 α × β 也可以是 Printable 的

instance {α β : Type} [Printable α] [Printable β] : Printable (α × β) where
  toString p := "(" ++ printIt p.1 ++ ", " ++ printIt p.2 ++ ")"

-- 现在元组也可以直接打印了
def print_pair' : String := printIt ((42, "hello") : Nat × String)
-- "(42, hello)"

-- 嵌套的元组也可以
def print_nested : String := printIt (((1, 2), (3, 4)) : (Nat × Nat) × (Nat × Nat))
-- "((1, 2), (3, 4))"

-- List 的 Printable 实例
instance {α : Type} [Printable α] : Printable (List α) where
  toString l := printList l

def print_list_of_lists : String :=
  printIt ([[1, 2], [3, 4], [5]] : List (List Nat))
-- "[[1, 2], [3, 4], [5]]"

/-! # 类型类继承简介 -/

-- 一个类型类可以继承另一个类型类
-- 例如：ReadablePrintable 继承 Printable，并额外提供 parse 方法

class ReadablePrintable (α : Type) extends Printable α where
  parse : String → Option α

-- 为 Nat 实现 ReadablePrintable
instance : ReadablePrintable Nat where
  toString n := toString n
  parse s := s.toNat?

def parse_nat : Option Nat := ReadablePrintable.parse "42"    -- some 42
def parse_fail : Option Nat := ReadablePrintable.parse "abc"  -- none

-- 因为 ReadablePrintable 继承自 Printable
-- 所以有 ReadablePrintable 实例的类型自动有 Printable 实例
def print_via_readable {α : Type} [ReadablePrintable α] (x : α) : String :=
  printIt x  -- 这里使用的是 Printable 的方法

def print_42 : String := print_via_readable 42    -- "42"

/-! # 类型类的命名空间 -/

-- 类型类的方法在类型类的命名空间中
-- 例如 Printable.toString

-- 可以打开类型类的命名空间
open Printable

-- 然后可以直接使用 toString
def direct_print {α : Type} [Printable α] (x : α) : String :=
  toString x

/-! # 实例参数 -/

-- 方括号 [Printable α] 表示"实例参数"
-- Lean 会自动搜索并填充合适的实例

-- 一个更复杂的例子：比较两个值的字符串表示
def comparePrint {α β : Type} [Printable α] [Printable β] (x : α) (y : β) : Ordering :=
  compare (printIt x) (printIt y)

def cmp_result : Ordering := comparePrint 10 2    -- GT（"10" > "2" 按字典序）

/-! # 类型类的法则 -/

-- 类型类通常有一些"法则"（law），即实例应该满足的性质
-- 例如：Printable 可能没有法则，但 Monoid 有结合律等
-- Lean 不会自动检查这些法则，但可以手动证明

-- 定义一个"可比较"类型类
class Comparable (α : Type) where
  compare : α → α → Ordering

-- Comparable 的法则（这里只声明，不做证明要求）
-- 1. 自反性：compare x x = Ordering.eq
-- 2. 反对称性：如果 compare x y = Ordering.lt 则 compare y x = Ordering.gt
-- 3. 传递性：如果 compare x y = Ordering.lt 且 compare y z = Ordering.lt
--    则 compare x z = Ordering.lt

-- 为 Nat 实现 Comparable
instance : Comparable Nat where
  compare x y :=
    if x < y then Ordering.lt
    else if x > y then Ordering.gt
    else Ordering.eq

def cmp_nat : Ordering := Comparable.compare 3 5   -- Ordering.lt

/-! # 匿名实例 -/

-- 有时候我们可以直接给实例命名
instance intPrintable : Printable Int where
  toString n := toString n

-- 命名实例的好处是可以明确引用
-- 但通常 Lean 会自动找到实例

/-! # 局部实例 -/

-- 可以在 section 或 namespace 中定义局部实例

section LocalInstances
  -- 为 Float 定义一个局部的 Printable 实例
  instance : Printable Float where
    toString f := toString f

  -- 在这个 section 内可以使用
  def print_float : String := printIt 3.14    -- "3.140000"
end LocalInstances

-- 在 section 外，Float 没有 Printable 实例
-- 下面这行无法编译
-- def print_float_outside : String := printIt 3.14

end Lean4Tutorial.Examples.Typeclasses.TypeclassBasics
