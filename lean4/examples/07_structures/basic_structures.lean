/-
文件: 07_structures/basic_structures.lean
描述: Lean 4 结构定义与访问（Person示例）
编译: lake build Lean4Tutorial.Examples.Structures.BasicStructures
-/

namespace Lean4Tutorial.Examples.Structures.BasicStructures

/-! # 结构（Structure）简介 -/

-- 结构是一种特殊的归纳类型，只有一个构造子
-- 用于组织多个相关的数据字段
-- 类似于其他语言中的 record 或 struct

/-! # 基本结构定义 -/

-- 使用 structure 关键字定义结构
structure Person where
  name : String
  age : Nat
deriving Repr, DecidableEq

-- 这会自动生成：
-- - 类型 Person
-- - 构造子 Person.mk (name : String) (age : Nat) : Person
-- - 访问器 Person.name : Person → String
-- - 访问器 Person.age : Person → Nat

-- 创建结构实例
def alice : Person :=
  { name := "Alice", age := 30 }

def bob : Person :=
  Person.mk "Bob" 25

def charlie : Person :=
  ⟨"Charlie", 35⟩  -- 尖括号构造

/-! # 访问字段 -/

-- 使用点号访问字段
def alice_name : String := alice.name    -- "Alice"
def alice_age : Nat := alice.age         -- 30

-- 使用访问器函数
def bob_name : String := Person.name bob    -- "Bob"
def bob_age : Nat := Person.age bob         -- 25

/-! # 结构上的函数 -/

-- 生日：年龄加 1
def birthday (p : Person) : Person :=
  { name := p.name, age := p.age + 1 }

def alice_next_year : Person := birthday alice
-- { name := "Alice", age := 31 }

-- 问候语
def greet (p : Person) : String :=
  s!"Hello, my name is {p.name} and I am {p.age} years old."

def alice_greet : String := greet alice
-- "Hello, my name is Alice and I am 30 years old."

-- 判断是否成年
def isAdult (p : Person) : Bool :=
  p.age >= 18

def alice_adult : Bool := isAdult alice    -- true

/-! # 带默认值的字段 -/

-- 结构字段可以有默认值
structure Point where
  x : Nat := 0
  y : Nat := 0
deriving Repr, DecidableEq

-- 只提供部分字段，其他使用默认值
def origin : Point := {}                  -- x=0, y=0
def point_x : Point := { x := 5 }        -- x=5, y=0
def point_y : Point := { y := 10 }       -- x=0, y=10
def point_full : Point := { x := 3, y := 4 }  -- x=3, y=4

/-! # 多字段结构 -/

-- 更复杂的结构示例：学生
structure Student where
  name : String
  age : Nat
  id : Nat            -- 学号
  major : String      -- 专业
  gpa : Float         -- 平均绩点
deriving Repr

-- 创建学生实例
def student1 : Student :=
  { name := "Alice"
    age := 20
    id := 2023001
    major := "Computer Science"
    gpa := 3.8
  }

-- 访问学生信息
def student_name : String := student1.name
def student_major : String := student1.major

/-! # 嵌套结构 -/

-- 结构可以嵌套
structure Address where
  street : String
  city : String
  zip : Nat
deriving Repr

structure PersonWithAddress where
  name : String
  age : Nat
  address : Address
deriving Repr

-- 创建嵌套结构
def person_with_addr : PersonWithAddress :=
  { name := "Alice"
    age := 30
    address := {
      street := "123 Main St"
      city := "Beijing"
      zip := 100000
    }
  }

-- 访问嵌套字段
def person_city : String := person_with_addr.address.city
-- "Beijing"

def person_zip : Nat := person_with_addr.address.zip
-- 100000

/-! # 结构与归纳类型的关系 -/

-- 结构本质上是只有一个构造子的归纳类型
-- 下面的归纳类型等价于 Person

inductive Person' : Type where
  | mk (name : String) (age : Nat) : Person'

-- 但是 structure 提供了更多便利：
-- - 字段访问器
-- - 更新语法
-- - 继承机制
-- - 默认值

/-! # 结构的相等性 -/

-- 两个结构相等当且仅当所有字段都相等
theorem person_eq (p1 p2 : Person) :
  p1 = p2 ↔ p1.name = p2.name ∧ p1.age = p2.age := by
  constructor
  · intro h
    rw [h]
    <;> simp
  · intro h
    cases p1
    cases p2
    simp [Person.mk] at h ⊢ <;> tauto

-- 字段的注入性
theorem name_inj (p1 p2 : Person) (h : p1 = p2) : p1.name = p2.name := by
  rw [h]

theorem age_inj (p1 p2 : Person) (h : p1 = p2) : p1.age = p2.age := by
  rw [h]

/-! # 结构上的类型类实例 -/

-- 可以为结构定义类型类实例

-- 为 Person 定义 Printable（假设有这个类型类）
-- 这里我们手动定义一个 toString
def Person.toString (p : Person) : String :=
  s!"Person(name={p.name}, age={p.age})"

def alice_str : String := alice.toString
-- "Person(name=Alice, age=30)"

-- 为 Point 定义加法
instance : Add Point where
  add p1 p2 := { x := p1.x + p2.x, y := p1.y + p2.y }

def point_add : Point := { x := 1, y := 2 } + { x := 3, y := 4 }
-- { x := 4, y := 6 }

instance : Zero Point where
  zero := {}

def point_zero : Point := 0
-- { x := 0, y := 0 }

/-! # 结构的归纳证明 -/

-- 因为结构只有一个构造子，证明性质时只需要考虑一种情况

theorem point_add_zero (p : Point) : p + 0 = p := by
  cases p
  simp [Zero.zero, Add.add]
  <;> rfl

theorem point_add_comm (p1 p2 : Point) : p1 + p2 = p2 + p1 := by
  cases p1
  cases p2
  simp [Add.add, add_comm]
  <;> rfl

/-! # 命题作为字段 -/

-- 结构的字段不一定是数据，也可以是命题
-- 这被称为"子类型"或"精炼类型"

-- 正整数（大于 0 的自然数）
structure PosNat where
  val : Nat
  pos : val > 0
deriving Repr

-- 创建正整数
def five_pos : PosNat :=
  { val := 5, pos := by decide }

def ten_pos : PosNat :=
  ⟨10, by decide⟩

-- 访问正整数的值
def five_val : Nat := five_pos.val    -- 5

-- 正整数的性质
def PosNat.add (a b : PosNat) : PosNat :=
  { val := a.val + b.val
    pos := by omega
  }

def five_plus_ten : PosNat := five_pos.add ten_pos
-- val = 15

/-! # 依赖字段 -/

-- 后面的字段可以依赖前面的字段
-- 这在结构中是允许的

-- 长度为 n 的列表
structure Vector (α : Type) (n : Nat) where
  data : List α
  length_eq : data.length = n

-- 创建长度为 3 的向量
def vec3 : Vector Nat 3 :=
  { data := [1, 2, 3]
    length_eq := by rfl
  }

-- 访问
def vec3_data : List Nat := vec3.data        -- [1, 2, 3]
def vec3_len_eq : vec3.data.length = 3 := vec3.length_eq  -- 证明

/-! # 结构与记录 -/

-- 结构也被称为"记录"（record）
-- Lean 的 structure 类似于：
-- - C 的 struct
-- - Java 的 class（没有方法）
-- - Haskell 的 record

-- 结构的优点：
-- 1. 字段命名，可读性好
-- 2. 字段访问器自动生成
-- 3. 支持更新语法（见下一节）
-- 4. 支持继承
-- 5. 支持默认值

end Lean4Tutorial.Examples.Structures.BasicStructures
