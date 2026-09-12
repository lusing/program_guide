/-
文件: 07_structures/pattern_matching_struct.lean
描述: Lean 4 结构模式匹配
编译: lake build Lean4Tutorial.Examples.Structures.PatternMatchingStruct
-/

namespace Lean4Tutorial.Examples.Structures.PatternMatchingStruct

/-! # 结构的模式匹配 -/

-- 结构也可以用模式匹配来解构
-- 因为结构本质上是只有一个构造子的归纳类型

/-! # 基本结构 -/

structure Point where
  x : Nat
  y : Nat
deriving Repr, DecidableEq

def p1 : Point := { x := 3, y := 4 }

/-! # match 中的结构模式 -/

-- 计算点到原点的距离平方
def distSq (p : Point) : Nat :=
  match p with
  | { x := a, y := b } => a * a + b * b

def dist1 : Nat := distSq p1    -- 3*3 + 4*4 = 25

-- 使用通配符
def getX (p : Point) : Nat :=
  match p with
  | { x := a, y := _ } => a

def x1 : Nat := getX p1    -- 3

/-! # 函数定义中的模式匹配 -/

-- 等式定义中也可以使用结构模式
def addPoints : Point → Point → Point
  | { x := x1, y := y1 }, { x := x2, y := y2 } =>
    { x := x1 + x2, y := y1 + y2 }

def sum : Point := addPoints { x := 1, y := 2 } { x := 3, y := 4 }
-- { x := 4, y := 6 }

-- 更简洁的写法
def addPoints' (p1 p2 : Point) : Point :=
  { x := p1.x + p2.x, y := p1.y + p2.y }

/-! # let 模式匹配 -/

-- 使用 let 解构结构
def let_example (p : Point) : Nat :=
  let { x := a, y := b } := p
  a + b

def let_sum : Nat := let_example p1    -- 7

-- 也可以直接在函数参数中解构
def param_destruct {x y : Nat} : Nat := x + y

-- 但这样不能直接用 Point 类型调用
-- 需要手动指定字段

-- 使用匿名函数
def lambda_destruct : Point → Nat :=
  fun { x := a, y := b } => a + b

def lambda_sum : Nat := lambda_destruct p1    -- 7

/-! # 嵌套结构的模式匹配 -/

structure Color where
  red : Nat
  green : Nat
  blue : Nat
deriving Repr

structure ColoredPoint where
  point : Point
  color : Color
deriving Repr

def cp : ColoredPoint :=
  { point := { x := 10, y := 20 }
    color := { red := 255, green := 0, blue := 0 }
  }

-- 嵌套模式匹配
def isRedAtOrigin (cp : ColoredPoint) : Bool :=
  match cp with
  | { point := { x := 0, y := 0 }, color := { red := 255, green := 0, blue := 0 } } => true
  | _ => false

def check_red_origin : Bool := isRedAtOrigin cp    -- false

-- 部分嵌套匹配
def getPointX (cp : ColoredPoint) : Nat :=
  match cp with
  | { point := { x := x, y := _ }, color := _ } => x

def cp_x : Nat := getPointX cp    -- 10

/-! # 结构模式匹配中的 as 模式 -/

-- 使用 @ 可以同时绑定整个结构和它的字段
-- （在 Lean 4 中使用命名模式）

def scaleAndSum (p : Point) (s : Nat) : Nat :=
  match p with
  | p'@ { x := a, y := b } =>
    -- p' 是整个 Point，a 和 b 是字段
    let scaled := { p' with x := a * s, y := b * s }
    scaled.x + scaled.y

def scaled_sum : Nat := scaleAndSum p1 2
-- scaled = (6, 8), sum = 14

/-! # 递归结构的模式匹配 -/

-- 树结构
inductive BinTree where
  | leaf : BinTree
  | node (value : Nat) (left : BinTree) (right : BinTree) : BinTree
deriving Repr

open BinTree

-- 树的求和
def treeSum : BinTree → Nat
  | leaf => 0
  | node v l r => v + treeSum l + treeSum r

-- 叶子计数
def leafCount : BinTree → Nat
  | leaf => 1
  | node _ l r => leafCount l + leafCount r

-- 树的高度
def treeHeight : BinTree → Nat
  | leaf => 0
  | node _ l r => 1 + max (treeHeight l) (treeHeight r)

-- 示例树
def example_tree : BinTree :=
  node 3
    (node 1 leaf leaf)
    (node 5 leaf (node 7 leaf leaf))

def tree_sum : Nat := treeSum example_tree    -- 1 + 3 + 5 + 7 = 16
def tree_leaves : Nat := leafCount example_tree    -- 3
def tree_height : Nat := treeHeight example_tree   -- 3

/-! # 多参数模式匹配 -/

-- 比较两个点的字典序
def pointCompare : Point → Point → Ordering
  | { x := x1, y := _ }, { x := x2, y := _ } =>
    if x1 < x2 then Ordering.lt
    else if x1 > x2 then Ordering.gt
    else Ordering.eq  -- 简化版本，只比较 x

-- 完整的字典序比较
def pointCompareFull : Point → Point → Ordering
  | { x := x1, y := y1 }, { x := x2, y := y2 } =>
    match compare x1 x2 with
    | Ordering.eq => compare y1 y2
    | ord => ord

-- 比较示例
def cmp1 : Ordering := pointCompareFull { x := 1, y := 5 } { x := 2, y := 3 }
-- Ordering.lt

def cmp2 : Ordering := pointCompareFull { x := 1, y := 5 } { x := 1, y := 3 }
-- Ordering.gt

/-! # 带守卫的模式匹配 -/

-- 判断一个点是否在第一象限（x > 0, y > 0）
def inFirstQuadrant : Point → Bool
  | { x := x, y := y } => x > 0 && y > 0

-- 或者用 if 守卫（match 中可以使用条件）
def inFirstQuadrant' (p : Point) : Bool :=
  match p with
  | { x := x, y := y } => x > 0 && y > 0

-- 更复杂的例子：分类点所在的象限
def quadrant : Point → String
  | { x := 0, y := 0 } => "原点"
  | { x := _, y := 0 } => "x轴上"
  | { x := 0, y := _ } => "y轴上"
  | { x := x, y := y } =>
    if x > 0 then
      if y > 0 then "第一象限" else "第四象限"
    else
      if y > 0 then "第二象限" else "第三象限"

def q1 : String := quadrant { x := 3, y := 4 }     -- "第一象限"
def q2 : String := quadrant { x := -2, y := 5 }    -- "第二象限"
def q0 : String := quadrant { x := 0, y := 0 }     -- "原点"

/-! # 列表与结构的组合匹配 -/

-- 点列表
def points : List Point :=
  [{ x := 1, y := 2 }, { x := 3, y := 4 }, { x := 5, y := 6 }]

-- 计算所有点的 x 坐标之和
def sumXs : List Point → Nat
  | [] => 0
  | { x := x, y := _ } :: rest => x + sumXs rest

def sum_xs : Nat := sumXs points    -- 1 + 3 + 5 = 9

-- 寻找第一个 y > 5 的点
def findYGT5 : List Point → Option Point
  | [] => none
  | p :: rest =>
    if p.y > 5 then some p
    else findYGT5 rest

def found : Option Point := findYGT5 points
-- some { x := 5, y := 6 }

/-! # 结构模式匹配的证明 -/

-- 结构模式匹配可以用于证明

theorem point_eq_iff (p1 p2 : Point) :
  p1 = p2 ↔ p1.x = p2.x ∧ p1.y = p2.y := by
  constructor
  · intro h
    rw [h]
    <;> simp
  · intro h
    cases p1 with | mk x1 y1 =>
    cases p2 with | mk x2 y2 =>
      simp at h ⊢
      <;> tauto

-- 模式匹配定义的函数的性质
theorem distSq_nonneg (p : Point) : distSq p ≥ 0 := by
  cases p
  simp [distSq]
  <;> omega

theorem addPoints_comm (p1 p2 : Point) :
  addPoints p1 p2 = addPoints p2 p1 := by
  cases p1 <;> cases p2
  simp [addPoints, add_comm]
  <;> rfl

/-! # 记录通配符 -/

-- 在结构模式中，可以使用 .. 表示"其他所有字段"
-- （Lean 4 支持这种语法）

def getX' (p : Point) : Nat :=
  match p with
  | { x := a, .. } => a

def getY' (p : Point) : Nat :=
  match p with
  | { y := b, .. } => b

-- 对于有很多字段的结构，.. 很方便
structure BigStruct where
  a : Nat
  b : Nat
  c : Nat
  d : Nat
  e : Nat
deriving Repr

def getA (s : BigStruct) : Nat :=
  match s with
  | { a := x, .. } => x

def big : BigStruct := { a := 1, b := 2, c := 3, d := 4, e := 5 }
def a_val : Nat := getA big    -- 1

/-! # 构造子模式 vs 记录模式 -/

-- 可以使用构造子形式或记录形式进行模式匹配

-- 构造子形式
def addPoints2 : Point → Point → Point
  | Point.mk x1 y1, Point.mk x2 y2 =>
    Point.mk (x1 + x2) (y1 + y2)

-- 记录形式
def addPoints3 : Point → Point → Point
  | { x := x1, y := y1 }, { x := x2, y := y2 } =>
    { x := x1 + x2, y := y1 + y2 }

-- 两者等价
theorem addPoints_eq (p1 p2 : Point) :
  addPoints2 p1 p2 = addPoints3 p1 p2 := by
  cases p1 <;> cases p2 <;> rfl

/-! # 模式匹配中的别名 -/

-- 有时候想同时绑定整个结构和它的字段
-- 可以使用命名模式

def describePoint (p : Point) : String :=
  match p with
  | p'@ { x := x, y := y } =>
    s!"Point({x}, {y}), sum={x + y}"

def desc : String := describePoint p1
-- "Point(3, 4), sum=7"

end Lean4Tutorial.Examples.Structures.PatternMatchingStruct
