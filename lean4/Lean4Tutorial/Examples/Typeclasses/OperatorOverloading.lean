/-
文件: 04_typeclasses/operator_overloading.lean
描述: Lean 4 操作符重载（Point加法示例）
编译: lake build Lean4Tutorial.Examples.Typeclasses.OperatorOverloading
-/

namespace Lean4Tutorial.Examples.Typeclasses.OperatorOverloading

/-! # 操作符重载简介 -/

-- 在 Lean 中，操作符（如 +, -, *, / 等）都是通过类型类实现的
-- 例如：
--   + 对应 Add 类型类的 add 方法
--   - 对应 Sub 类型类的 sub 方法
--   * 对应 Mul 类型类的 mul 方法
--   -（一元负号）对应 Neg 类型类的 neg 方法
--   0 对应 Zero 类型类的 zero
--   1 对应 One 类型类的 one

-- 要为自定义类型重载操作符，只需要为对应的类型类提供实例

/-! # Point 类型定义 -/

-- 二维点类型
structure Point where
  x : Nat
  y : Nat
deriving Repr, DecidableEq

-- 一些示例点
def p1 : Point := ⟨1, 2⟩
def p2 : Point := ⟨3, 4⟩
def p3 : Point := ⟨5, 6⟩

/-! # 加法操作符重载 -/

-- 为 Point 实现 Add 类型类，就可以使用 + 运算符
instance : Add Point where
  add p1 p2 := ⟨p1.x + p2.x, p1.y + p2.y⟩

-- 现在可以使用 + 了
def p_add : Point := p1 + p2     -- ⟨4, 6⟩

-- 加法的链式调用
def p_add3 : Point := p1 + p2 + p3   -- ⟨9, 12⟩

/-! # 零元素 -/

-- 实现 Zero 类型类，就可以使用 0 表示零元
instance : Zero Point where
  zero := ⟨0, 0⟩

def p_zero : Point := 0    -- ⟨0, 0⟩

-- 零元的性质
theorem add_zero (p : Point) : p + 0 = p := by
  cases p
  <;> simp [Zero.zero, Add.add]
  <;> rfl

theorem zero_add (p : Point) : 0 + p = p := by
  cases p
  <;> simp [Zero.zero, Add.add]
  <;> rfl

/-! # 乘法操作符重载 -/

-- 点与标量的乘法
-- 我们可以定义一个标量乘法
-- 注意：这里我们用的是 Nat × Point，不是 Point × Point

-- 定义一个"标量乘法"类型类（或者直接使用已有的）
-- 实际上，标准库中有 HMul 等类型类用于异构乘法

-- 简单起见，我们定义 Point 与 Nat 的乘法
-- 使用标准的 Mul 类型类，但 Mul 需要两个相同类型的参数
-- 所以我们用另一种方式：定义一个 scale 函数

def Point.scale (p : Point) (s : Nat) : Point :=
  ⟨p.x * s, p.y * s⟩

def p_scale : Point := p1.scale 3    -- ⟨3, 6⟩

-- 如果想使用 * 运算符，需要用 HMul（异构乘法）
instance : HMul Point Nat Point where
  hMul p s := p.scale s

def p_hmul : Point := p1 * 3    -- ⟨3, 6⟩

/-! # 减法操作符重载 -/

-- 对于 Nat 来说，减法是"截断减法"（0-1=0）
-- Point 的减法也类似

instance : Sub Point where
  sub p1 p2 := ⟨p1.x - p2.x, p1.y - p2.y⟩

def p_sub : Point := p3 - p1    -- ⟨4, 4⟩
def p_sub_trunc : Point := p1 - p3    -- ⟨0, 0⟩（截断）

/-! # 整数版本的 Point -/

-- 使用 Nat 的 Point 在减法上有限制
-- 我们定义一个使用 Int 的版本

structure IPoint where
  x : Int
  y : Int
deriving Repr, DecidableEq

-- 实现各种运算
instance : Add IPoint where
  add p1 p2 := ⟨p1.x + p2.x, p1.y + p2.y⟩

instance : Sub IPoint where
  sub p1 p2 := ⟨p1.x - p2.x, p1.y - p2.y⟩

instance : Neg IPoint where
  neg p := ⟨-p.x, -p.y⟩

instance : Zero IPoint where
  zero := ⟨0, 0⟩

instance : HMul IPoint Int IPoint where
  hMul p s := ⟨p.x * s, p.y * s⟩

-- 示例
def ip1 : IPoint := ⟨1, 2⟩
def ip2 : IPoint := ⟨3, 4⟩

def ip_add : IPoint := ip1 + ip2     -- ⟨4, 6⟩
def ip_sub : IPoint := ip1 - ip2     -- ⟨-2, -2⟩
def ip_neg : IPoint := -ip1          -- ⟨-1, -2⟩
def ip_zero : IPoint := 0            -- ⟨0, 0⟩
def ip_mul : IPoint := ip1 * 3       -- ⟨3, 6⟩

/-! # 比较操作符 -/

-- 可以通过实现 Ord 类型类来获得比较操作符

instance : Ord Point where
  compare p1 p2 :=
    -- 先比较 x，再比较 y（字典序）
    match compare p1.x p2.x with
    | Ordering.eq => compare p1.y p2.y
    | ord => ord

def p_lt : Bool := p1 < p2     -- true
def p_le : Bool := p1 ≤ p1     -- true
def p_gt : Bool := p3 > p2     -- true
def p_ge : Bool := p3 ≥ p1     -- true

/-! # 数值类型类层次 -/

-- Lean 的数值操作符背后有一套完整的类型类层次
-- 简单来说：
--
-- Add      (+)
-- Sub      (-)
-- Mul      (*)
-- Div      (/)
-- Neg      (-x)
-- Zero     (0)
-- One      (1)
--
-- 更高级的结构：
-- Semigroup         半群（结合律）
-- Monoid            幺半群（半群 + 单位元）
-- Group             群（幺半群 + 逆元）
-- Semiring          半环
-- Ring              环
-- Field             域

/-! # 向量类型的操作符 -/

-- 固定长度的向量类型
structure Vec3 where
  x : Float
  y : Float
  z : Float
deriving Repr

-- 向量加法
instance : Add Vec3 where
  add v1 v2 := ⟨v1.x + v2.x, v1.y + v2.y, v1.z + v2.z⟩

-- 向量减法
instance : Sub Vec3 where
  sub v1 v2 := ⟨v1.x - v2.x, v1.y - v2.y, v1.z - v2.z⟩

-- 零向量
instance : Zero Vec3 where
  zero := ⟨0.0, 0.0, 0.0⟩

-- 负向量
instance : Neg Vec3 where
  neg v := ⟨-v.x, -v.y, -v.z⟩

-- 标量乘法
instance : HMul Vec3 Float Vec3 where
  hMul v s := ⟨v.x * s, v.y * s, v.z * s⟩

-- 向量点积
def dot (v1 v2 : Vec3) : Float :=
  v1.x * v2.x + v1.y * v2.y + v1.z * v2.z

-- 示例
def v1 : Vec3 := ⟨1.0, 2.0, 3.0⟩
def v2 : Vec3 := ⟨4.0, 5.0, 6.0⟩

def v_add : Vec3 := v1 + v2         -- ⟨5.0, 7.0, 9.0⟩
def v_sub : Vec3 := v1 - v2         -- ⟨-3.0, -3.0, -3.0⟩
def v_neg : Vec3 := -v1             -- ⟨-1.0, -2.0, -3.0⟩
def v_scale : Vec3 := v1 * 2.0      -- ⟨2.0, 4.0, 6.0⟩
def v_dot : Float := dot v1 v2      -- 32.0

/-! # 字符串的操作符 -/

-- ++ 运算符对应 Append 类型类
-- String 的 ++ 就是字符串连接

def str_concat : String := "Hello, " ++ "World!"    -- "Hello, World!"

-- 也可以为自定义类型实现 Append
structure Name where
  first : String
  last : String
deriving Repr

-- 使用 ++ 组合名字（虽然不太常见）
instance : Append Name where
  append n1 n2 := ⟨n1.first ++ " " ++ n2.first, n1.last ++ " " ++ n2.last⟩

def n1 : Name := ⟨"张", "三"⟩
def n2 : Name := ⟨"李", "四"⟩
def n_appended : Name := n1 ++ n2
-- Name "张 李" "三 四"

/-! # 列表的操作符 -/

-- 列表的 ++ 也是 Append 类型类
def list_concat : List Nat := [1, 2] ++ [3, 4]    -- [1, 2, 3, 4]

-- 列表的 :: 是 cons 操作符
def list_cons : List Nat := 1 :: [2, 3]            -- [1, 2, 3]

/-! # 自定义操作符 -/

-- 除了重载已有的操作符，还可以定义新的操作符
-- 使用 infix, prefix, postfix 等命令

-- 定义一个"中点"操作符 ⊙（输入 \odot）
infixl:65 " ⊙ " => fun (p1 p2 : Point) =>
  ⟨(p1.x + p2.x) / 2, (p1.y + p2.y) / 2⟩

def midpoint : Point := p1 ⊙ p2    -- ⟨2, 3⟩

-- 定义一个"距离的平方"操作符
infix:50 " ⋅ " => fun (p1 p2 : Point) =>
  let dx := p1.x - p2.x
  let dy := p1.y - p2.y
  dx * dx + dy * dy

def dist_sq : Nat := p1 ⋅ p2       -- 8

-- 定义前缀操作符（取反）
-- 实际上 - 已经通过 Neg 类型类实现了

-- 定义后缀操作符（归一化，这里仅示意）
-- postfix:max "⃗" => fun (v : Vec3) => ...
-- （Lean 对后缀操作符的支持有限）

/-! # OfNat 类型类 -/

-- 当我们写 (42 : α) 时，Lean 使用 OfNat 类型类
-- OfNat α n 表示类型 α 有一个对应于自然数 n 的值

-- 标准的数值类型都有 OfNat 实例

-- 我们也可以为 Point 实现 OfNat
-- 但通常只有 n = 0 有意义（零向量）
-- Zero 类型类实际上提供了 0 的语法

-- 更一般地，可以为任意自然数提供点 (n, n)
instance : OfNat Point n where
  ofNat := ⟨n, n⟩

-- 现在可以用数字字面量表示 Point
def p_of_nat : Point := 5    -- ⟨5, 5⟩

-- 这在某些情况下很方便
def p_add_nat : Point := p1 + 3    -- ⟨4, 5⟩

/-! # 总结 -/

-- 操作符重载的本质是实现对应的类型类：
--
--   操作符    类型类       方法
--   +         Add          add
--   -         Sub          sub
--   *         Mul          mul
--   /         Div          div
--   -x        Neg          neg
--   0         Zero         zero
--   1         One          one
--   ++        Append       append
--   < ≤ > ≥   Ord/LT/LE/GT/GE
--   =         DecidableEq
--
-- 要重载操作符，只需要为对应的类型类提供实例即可

end Lean4Tutorial.Examples.Typeclasses.OperatorOverloading
