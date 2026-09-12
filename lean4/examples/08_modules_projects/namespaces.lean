/-
文件: 08_modules_projects/namespaces.lean
描述: Lean 4 命名空间使用
编译: lake build Lean4Tutorial.Examples.ModulesProjects.Namespaces
-/

namespace Lean4Tutorial.Examples.ModulesProjects.Namespaces

/-! # 命名空间简介 -/

-- 在 Lean 中，命名空间（namespace）用于组织代码和避免名称冲突
-- 不同的命名空间中可以有相同名称的定义
-- 使用 namespace ... end 来定义命名空间

/-! # 基本命名空间 -/

-- 定义一个命名空间
namespace MyNamespace

  -- 在命名空间内的定义
  def x : Nat := 42

  def double (n : Nat) : Nat := n * 2

  -- 命名空间可以嵌套
  namespace Inner
    def y : String := "hello"
  end Inner

end MyNamespace

-- 在命名空间外部访问需要使用完全限定名
def outside_x : Nat := MyNamespace.x         -- 42
def outside_double : Nat := MyNamespace.double 5  -- 10
def outside_y : String := MyNamespace.Inner.y     -- "hello"

/-! # open 命令 -/

-- 使用 open 可以打开命名空间，之后可以直接使用其中的名称

-- 打开整个命名空间
open MyNamespace

def open_x : Nat := x         -- 42（现在可以直接使用 x）
def open_double : Nat := double 10  -- 20

-- 也可以只打开特定的名称
-- open MyNamespace (x)  -- 只打开 x

/-! # 命名空间的嵌套 -/

namespace Outer

  def a : Nat := 1

  namespace Middle

    def b : Nat := 2

    namespace Inner
      def c : Nat := 3
    end Inner

  end Middle

  -- 在 Outer 内部可以直接访问 Middle 中的内容
  def sum1 : Nat := a + Middle.b + Middle.Inner.c  -- 6

end Outer

-- 在外部需要完整路径
def outer_sum : Nat := Outer.a + Outer.Middle.b + Outer.Middle.Inner.c  -- 6

-- 打开嵌套命名空间
open Outer.Middle

def middle_b : Nat := b    -- 2
-- 注意：a 和 Inner.c 不在 Middle 的直接子命名空间中，不能直接访问
-- 但可以通过 Inner.c 访问

/-! # namespace 与 section 的区别 -/

-- namespace 会影响定义的名称（永久的）
-- section 只是分组，不影响名称（后面会讲）

namespace TestNamespace
  def foo : Nat := 1
end TestNamespace

-- 外部访问必须用 TestNamespace.foo
-- def test := foo  -- 错误，找不到 foo

/-! # 标准库中的命名空间 -/

-- Lean 标准库使用了大量的命名空间
-- 例如：
-- - Nat       自然数相关
-- - List      列表相关
-- - String    字符串相关
-- - Bool      布尔值相关
-- - Prod      乘积类型相关
-- - Option    Option 类型相关
-- - Mathlib   Mathlib 库的根命名空间

-- List 命名空间中的函数
def list_len : Nat := List.length [1, 2, 3]    -- 3
def list_map : List Nat := List.map (· * 2) [1, 2, 3]  -- [2, 4, 6]

-- 打开 List 命名空间后
open List

def len_direct : Nat := length [1, 2, 3]       -- 3
def map_direct : List Nat := map (· * 2) [1, 2, 3]  -- [2, 4, 6]

/-! # 类型类与命名空间 -/

-- 类型类的方法在类型类的命名空间中

-- 例如：Add.add 是加法操作
def add_via_ns : Nat := Add.add 3 4    -- 7

-- 通常我们直接用 + 运算符
def add_via_op : Nat := 3 + 4          -- 7

-- 打开类型类命名空间
open Add

-- 现在可以直接使用 add
def add_open : Nat := add 5 6          -- 11

/-! # 归纳类型的命名空间 -/

-- 归纳类型自动创建一个同名的命名空间
-- 构造子在这个命名空间中

inductive Color where
  | red
  | green
  | blue

-- 构造子的完全限定名
def color1 : Color := Color.red
def color2 : Color := Color.green

-- 打开 Color 命名空间后
open Color

def color3 : Color := red
def color4 : Color := blue

-- 也可以使用 deriving 来自动打开
-- inductive Color where ... deriving ...

/-! # 结构的命名空间 -/

-- 结构也会创建命名空间，字段和方法在其中

structure Point where
  x : Nat
  y : Nat

-- 字段访问器在 Point 命名空间中
def px (p : Point) : Nat := Point.x p
def py (p : Point) : Nat := Point.y p

-- 通常我们用点号表示法
def p : Point := { x := 1, y := 2 }
def px' : Nat := p.x
def py' : Nat := p.y

/-! # 重新导出（export）-/

-- 使用 export 可以将一个命名空间的名称重新导出到当前命名空间

namespace MyLib

  def add (x y : Nat) : Nat := x + y
  def mul (x y : Nat) : Nat := x * y

  -- 将 add 和 mul 导出到 MyLib 的父命名空间
  -- export 命令在这里的具体用法取决于 Lean 版本

end MyLib

-- 也可以在外部使用 open MyLib 来访问

/-! # 命名空间的习惯用法 -/

-- 项目通常有一个根命名空间
-- 例如：Lean4Tutorial（本项目的根）

-- 模块的命名空间通常与文件路径对应
-- 例如：Lean4Tutorial.Examples.Basics.BasicTypes
-- 对应文件：Lean4Tutorial/Examples/Basics/BasicTypes.lean

-- 这是 Lean 的惯例：模块名 = 命名空间名 = 文件路径（点替换为路径分隔符）

/-! # 私有定义 -/

-- 使用 private 关键字定义私有名称
-- 私有名称只能在当前文件/命名空间内访问

namespace PrivateDemo

  private def helper (n : Nat) : Nat := n * 2

  def publicFunc (n : Nat) : Nat := helper n + 1

end PrivateDemo

-- 下面这行会报错（helper 是私有的）
-- def cant_access : Nat := PrivateDemo.helper 5

-- 但可以访问公开的函数
def can_access : Nat := PrivateDemo.publicFunc 5    -- 11

/-! # 受保护的定义 -/

-- 使用 protected 关键字定义受保护的名称
-- 受保护的名称必须通过命名空间访问，不能被 open

namespace ProtectedDemo

  protected def foo : Nat := 42

  def bar : Nat := 100

end ProtectedDemo

open ProtectedDemo

-- bar 可以直接访问
def bar_val : Nat := bar    -- 100

-- foo 是受保护的，必须使用命名空间前缀
-- def foo_val : Nat := foo  -- 错误
def foo_val : Nat := ProtectedDemo.foo    -- 42

/-! # 命名空间与作用域 -/

-- namespace ... end 形成一个作用域
-- 在 end 之后，命名空间内的定义需要完全限定名访问

namespace ScopeDemo

  def x : Nat := 1

  -- 这里可以直接使用 x
  def double_x : Nat := x * 2

end ScopeDemo

-- 这里必须用 ScopeDemo.x
def outside : Nat := ScopeDemo.x

/-! # 非交互模式的命名空间 -/

-- 在顶层也可以有定义，它们在"根"命名空间中
-- 但在实际项目中，最好将所有定义放在适当的命名空间中

/-! # 命名空间的最佳实践 -/

-- 1. 使用有意义的命名空间层次结构
-- 2. 模块名与文件名对应
-- 3. 在文件顶部声明主要的 namespace
-- 4. 合理使用 open，避免打开过多命名空间
-- 5. 使用 private 隐藏内部实现
-- 6. 使用 protected 防止名称冲突

end Lean4Tutorial.Examples.ModulesProjects.Namespaces
