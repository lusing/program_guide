/-
文件: 02_inductive_types/enums.lean
描述: Lean 4 枚举类型（Weekday示例）
编译: lake build Lean4Tutorial.Examples.InductiveTypes.Enums
-/

namespace Lean4Tutorial.Examples.InductiveTypes.Enums

/-! # 枚举类型简介 -/

-- 枚举类型是最简单的归纳类型
-- 使用 inductive 关键字定义

-- 星期几的枚举类型
inductive Weekday where
  | monday    : Weekday
  | tuesday   : Weekday
  | wednesday : Weekday
  | thursday  : Weekday
  | friday    : Weekday
  | saturday  : Weekday
  | sunday    : Weekday
deriving Repr, DecidableEq

-- 打开 Weekday 命名空间，可以直接使用构造子
open Weekday

-- 使用枚举值
def today : Weekday := monday
def weekend_start : Weekday := saturday

/-! # 枚举类型上的函数 -/

-- 判断是否是工作日
def isWeekday (d : Weekday) : Bool :=
  match d with
  | monday => true
  | tuesday => true
  | wednesday => true
  | thursday => true
  | friday => true
  | saturday => false
  | sunday => false

-- 判断是否是周末
def isWeekend (d : Weekday) : Bool :=
  match d with
  | saturday => true
  | sunday => true
  | _ => false

-- 计算下一天
def nextDay (d : Weekday) : Weekday :=
  match d with
  | monday => tuesday
  | tuesday => wednesday
  | wednesday => thursday
  | thursday => friday
  | friday => saturday
  | saturday => sunday
  | sunday => monday

-- 计算前一天
def prevDay (d : Weekday) : Weekday :=
  match d with
  | monday => sunday
  | tuesday => monday
  | wednesday => tuesday
  | thursday => wednesday
  | friday => thursday
  | saturday => friday
  | sunday => saturday

/-! # 枚举值的使用示例 -/

def monday_is_weekday : Bool := isWeekday monday        -- true
def saturday_is_weekend : Bool := isWeekend saturday    -- true
def next_monday : Weekday := nextDay monday             -- tuesday
def prev_monday : Weekday := prevDay monday             -- sunday

-- 多次调用
def three_days_later (d : Weekday) : Weekday :=
  nextDay (nextDay (nextDay d))

def wed_plus_three : Weekday := three_days_later wednesday  -- saturday

/-! # 将枚举转换为字符串 -/

def Weekday.toString (d : Weekday) : String :=
  match d with
  | monday => "星期一"
  | tuesday => "星期二"
  | wednesday => "星期三"
  | thursday => "星期四"
  | friday => "星期五"
  | saturday => "星期六"
  | sunday => "星期日"

def print_monday : String := monday.toString    -- "星期一"

/-! # 其他枚举类型示例 -/

-- 交通信号灯
inductive TrafficLight where
  | red    : TrafficLight
  | yellow : TrafficLight
  | green  : TrafficLight
deriving Repr, DecidableEq

open TrafficLight

-- 判断是否可以通行
def canGo (light : TrafficLight) : Bool :=
  match light with
  | green => true
  | _ => false

-- 下一个信号灯状态
def nextLight (light : TrafficLight) : TrafficLight :=
  match light with
  | red => green
  | yellow => red
  | green => yellow

-- 方向
inductive Direction where
  | north : Direction
  | south : Direction
  | east  : Direction
  | west  : Direction
deriving Repr, DecidableEq

open Direction

-- 相反方向
def opposite (dir : Direction) : Direction :=
  match dir with
  | north => south
  | south => north
  | east => west
  | west => east

-- 左转
def turnLeft (dir : Direction) : Direction :=
  match dir with
  | north => west
  | west => south
  | south => east
  | east => north

-- 右转
def turnRight (dir : Direction) : Direction :=
  match dir with
  | north => east
  | east => south
  | south => west
  | west => north

/-! # 布尔类型也是枚举 -/

-- Lean 中的 Bool 本质上也是一个枚举类型
-- inductive Bool where
--   | false : Bool
--   | true  : Bool

def my_not (b : Bool) : Bool :=
  match b with
  | false => true
  | true => false

def my_and (a b : Bool) : Bool :=
  match a with
  | true => b
  | false => false

/-! # 带参数的枚举 -/

-- 枚举的构造子也可以携带数据（这就不再是简单的枚举了）
-- 这是更一般的归纳类型

-- 形状类型：有些构造子带参数
inductive Shape where
  | circle (radius : Nat) : Shape
  | rectangle (width height : Nat) : Shape
  | square (side : Nat) : Shape
deriving Repr

-- 计算面积
def area (s : Shape) : Nat :=
  match s with
  | Shape.circle r => r * r * 3  -- 简化计算，用 3 代替 π
  | Shape.rectangle w h => w * h
  | Shape.square s => s * s

def circle_area : Nat := area (Shape.circle 5)          -- 75
def rect_area : Nat := area (Shape.rectangle 4 6)       -- 24
def square_area : Nat := area (Shape.square 5)          -- 25

/-! # 枚举的等式证明 -/

-- 不同的构造子产生不同的值
-- monday ≠ tuesday

theorem monday_ne_tuesday : monday ≠ tuesday := by
  intro h
  cases h

-- 枚举类型的相等性是可判定的
example : DecidableEq Weekday := inferInstance

/-! # 有限枚举类型 -/

-- Weekday 是有限的，只有 7 个元素
-- 可以列出所有可能的值

def allWeekdays : List Weekday :=
  [monday, tuesday, wednesday, thursday, friday, saturday, sunday]

def allWeekdays_length : allWeekdays.length = 7 := by rfl

end Lean4Tutorial.Examples.InductiveTypes.Enums
