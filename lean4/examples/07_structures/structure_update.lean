/-
文件: 07_structures/structure_update.lean
描述: Lean 4 结构更新与继承（ColoredPoint示例）
编译: lake build Lean4Tutorial.Examples.Structures.StructureUpdate
-/

namespace Lean4Tutorial.Examples.Structures.StructureUpdate

/-! # 结构更新语法 -/

-- Lean 提供了方便的结构更新语法
-- { old_struct with field1 := new_val1, field2 := new_val2, ... }
-- 这会创建一个新的结构，指定的字段被更新，其他字段保持不变

/-! # 基本结构 -/

structure Point where
  x : Nat
  y : Nat
deriving Repr, DecidableEq

def p1 : Point := { x := 1, y := 2 }

-- 更新 x 字段
def p1' : Point := { p1 with x := 10 }
-- { x := 10, y := 2 }

-- 更新 y 字段
def p1'' : Point := { p1 with y := 20 }
-- { x := 1, y := 20 }

-- 同时更新多个字段
def p1''' : Point := { p1 with x := 10, y := 20 }
-- { x := 10, y := 20 }

/-! # 结构更新的性质 -/

-- 更新一个字段不影响其他字段
theorem update_x_preserves_y (p : Point) (nx : Nat) :
  ({ p with x := nx }).y = p.y := by
  cases p
  simp

theorem update_y_preserves_x (p : Point) (ny : Nat) :
  ({ p with y := ny }).x = p.x := by
  cases p
  simp

-- 更新同一个字段两次，最后一次生效
theorem update_twice (p : Point) (v1 v2 : Nat) :
  { { p with x := v1 } with x := v2 } = { p with x := v2 } := by
  cases p
  simp

-- 更新相同的值等于不更新
theorem update_same (p : Point) :
  { p with x := p.x } = p := by
  cases p
  simp

/-! # 函数式更新的优点 -/

-- 结构更新是函数式的（不可变的）
-- 原结构不会被修改，总是创建新结构

def original : Point := { x := 5, y := 5 }
def updated : Point := { original with x := 10 }

-- original 保持不变
theorem original_unchanged : original.x = 5 := by rfl

/-! # 嵌套结构更新 -/

structure Color where
  red : Nat
  green : Nat
  blue : Nat
deriving Repr, DecidableEq

structure ColoredPoint where
  point : Point
  color : Color
deriving Repr

def redPoint : ColoredPoint :=
  { point := { x := 10, y := 20 }
    color := { red := 255, green := 0, blue := 0 }
  }

-- 更新嵌套字段
-- 方法1：使用 with 更新外层，然后更新内层
def darkerRed : ColoredPoint :=
  { redPoint with
    color := { redPoint.color with red := 128 }
  }

-- 更新点坐标
def moveRight : ColoredPoint :=
  { redPoint with
    point := { redPoint.point with x := redPoint.point.x + 10 }
  }

-- 同时更新点和颜色
def moveAndRecolor : ColoredPoint :=
  { redPoint with
    point := { redPoint.point with x := 100 }
    color := { red := 0, green := 255, blue := 0 }
  }

/-! # 结构继承 -/

-- 结构可以继承其他结构
-- 使用 extends 关键字

-- Point3D 继承自 Point，添加了 z 字段
structure Point3D extends Point where
  z : Nat
deriving Repr, DecidableEq

-- 创建 Point3D
def p3d1 : Point3D :=
  { x := 1, y := 2, z := 3 }

def p3d2 : Point3D :=
  Point3D.mk (Point.mk 1 2) 3

-- 访问继承的字段
def p3d_x : Nat := p3d1.x    -- 1（继承自 Point）
def p3d_y : Nat := p3d1.y    -- 2（继承自 Point）
def p3d_z : Nat := p3d1.z    -- 3（Point3D 自己的字段）

-- 访问父结构
def p3d_point : Point := p3d1.toPoint
-- { x := 1, y := 2 }

/-! # 继承结构的更新 -/

-- 更新继承的字段
def p3d1' : Point3D := { p3d1 with x := 10 }
-- { x := 10, y := 2, z := 3 }

def p3d1'' : Point3D := { p3d1 with z := 30 }
-- { x := 1, y := 2, z := 30 }

-- 同时更新继承的和新的字段
def p3d1''' : Point3D := { p3d1 with x := 10, y := 20, z := 30 }
-- { x := 10, y := 20, z := 30 }

/-! # 多级继承 -/

-- 可以多级继承
structure NamedPoint3D extends Point3D where
  name : String
deriving Repr

def np3d : NamedPoint3D :=
  { x := 1, y := 2, z := 3, name := "origin" }

def np3d_name : String := np3d.name    -- "origin"
def np3d_x : Nat := np3d.x             -- 1（继承自 Point）
def np3d_z : Nat := np3d.z             -- 3（继承自 Point3D）

-- 转换为父类型
def np3d_to_p3d : Point3D := np3d.toPoint3D
def np3d_to_point : Point := np3d.toPoint

/-! # ColoredPoint 的继承版本 -/

-- 使用继承来定义 ColoredPoint
structure ColoredPoint' extends Point where
  color : Color
deriving Repr

def redPoint' : ColoredPoint' :=
  { x := 10, y := 20, color := { red := 255, green := 0, blue := 0 } }

-- 直接访问 x, y（继承自 Point）
def rp_x : Nat := redPoint'.x    -- 10
def rp_y : Nat := redPoint'.y    -- 20
def rp_color : Color := redPoint'.color  -- (255, 0, 0)

-- 更新继承的字段
def greenPoint' : ColoredPoint' :=
  { redPoint' with
    x := 100
    color := { red := 0, green := 255, blue := 0 }
  }

/-! # 继承的类型类实例 -/

-- 为 Point 定义 Add 实例
instance : Add Point where
  add p1 p2 := { x := p1.x + p2.x, y := p1.y + p2.y }

instance : Zero Point where
  zero := { x := 0, y := 0 }

-- Point3D 也可以有自己的 Add 实例
instance : Add Point3D where
  add p1 p2 := { x := p1.x + p2.x, y := p1.y + p2.y, z := p1.z + p2.z }

instance : Zero Point3D where
  zero := { x := 0, y := 0, z := 0 }

def p3d_add : Point3D := { x := 1, y := 2, z := 3 } + { x := 4, y := 5, z := 6 }
-- { x := 5, y := 7, z := 9 }

/-! # 结构的转换函数 -/

-- 继承自动生成转换函数（toParent）
-- Point3D.toPoint : Point3D → Point
-- NamedPoint3D.toPoint3D : NamedPoint3D → Point3D
-- NamedPoint3D.toPoint : NamedPoint3D → Point

-- 向上转型是安全的
def upcast_example : Point := p3d1.toPoint
-- { x := 1, y := 2 }

-- 向下转型需要手动定义（不一定总能成功）
def Point.toPoint3D (p : Point) (z : Nat) : Point3D :=
  { x := p.x, y := p.y, z := z }

def downcast_example : Point3D := ({ x := 1, y := 2 } : Point).toPoint3D 3
-- { x := 1, y := 2, z := 3 }

/-! # 继承与代码复用 -/

-- 继承的一个好处是可以复用父结构的函数

-- 对 Point 定义的函数
def Point.double (p : Point) : Point :=
  { x := p.x * 2, y := p.y * 2 }

-- 可以通过转换在 Point3D 上使用
def Point3D.doubleXY (p : Point3D) : Point3D :=
  let p2 := p.toPoint.double
  { p with x := p2.x, y := p2.y }

def p3d_double_xy : Point3D := p3d1.doubleXY
-- { x := 2, y := 4, z := 3 }

-- 更好的方式：直接为 Point3D 定义 double
def Point3D.double (p : Point3D) : Point3D :=
  { x := p.x * 2, y := p.y * 2, z := p.z * 2 }

def p3d_double : Point3D := p3d1.double
-- { x := 2, y := 4, z := 6 }

/-! # 多重继承 -/

-- 结构可以继承多个父结构

structure HasName where
  name : String
deriving Repr

structure HasAge where
  age : Nat
deriving Repr

-- Student 继承自 HasName 和 HasAge
structure Student extends HasName, HasAge where
  id : Nat
  major : String
deriving Repr

def student : Student :=
  { name := "Alice"
    age := 20
    id := 12345
    major := "Computer Science"
  }

-- 访问继承的字段
def student_name : String := student.name    -- from HasName
def student_age : Nat := student.age         -- from HasAge
def student_id : Nat := student.id           -- Student 自己的

-- 转换为父结构
def student_has_name : HasName := student.toHasName
def student_has_age : HasAge := student.toHasAge

/-! # 继承与钻石问题 -/

-- 如果两个父结构有相同名字的字段，会怎样？
-- Lean 要求字段名不能冲突

-- 这是不行的（会报错）：
-- structure A where
--   x : Nat
-- structure B where
--   x : Nat
-- structure C extends A, B where
--   ...  -- 错误：x 重复定义

/-! # 结构 vs 归纳类型 -/

-- 什么时候用 structure，什么时候用 inductive？
--
-- 用 structure 当：
-- - 只有一种构造方式
-- - 有命名字段的数据记录
-- - 需要字段更新语法
-- - 需要继承
--
-- 用 inductive 当：
-- - 有多种构造方式（枚举、联合类型等）
-- - 需要递归定义
-- - 需要模式匹配

end Lean4Tutorial.Examples.Structures.StructureUpdate
