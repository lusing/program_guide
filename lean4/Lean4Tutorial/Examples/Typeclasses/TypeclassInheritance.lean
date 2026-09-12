/-
文件: 04_typeclasses/typeclass_inheritance.lean
描述: Lean 4 类型类继承（半群、幺半群层次）
编译: lake build Lean4Tutorial.Examples.Typeclasses.TypeclassInheritance
-/

namespace Lean4Tutorial.Examples.Typeclasses.TypeclassInheritance

/-! # 类型类继承简介 -/

-- 类型类可以继承自其他类型类
-- 子类继承父类的所有方法，并可以添加新的方法
-- 这形成了类型类的层次结构

/-! # 半群（Semigroup）-/

-- 半群：有一个结合的二元运算
-- 在 Lean 中，半群通过 AddSemigroup 和 MulSemigroup 表示
-- 这里我们用加法半群来演示

-- 加法半群：有 + 运算，满足结合律
-- class AddSemigroup G extends Add G where
--   add_assoc : ∀ a b c : G, (a + b) + c = a + (b + c)

-- 注意：实际的 Lean 标准库中类型类层次更复杂
-- 这里我们简化演示

-- 自定义一个简单的半群类型类
class SimpleSemigroup (α : Type) extends Add α where
  add_assoc : ∀ (a b c : α), (a + b) + c = a + (b + c)

-- Nat 是加法半群
instance : SimpleSemigroup Nat where
  add_assoc a b c := by
    omega

-- 验证结合律
theorem nat_add_assoc (a b c : Nat) : (a + b) + c = a + (b + c) :=
  SimpleSemigroup.add_assoc a b c

/-! # 幺半群（Monoid）-/

-- 幺半群：半群 + 单位元
-- 加法幺半群有 + 和 0，满足：
--   0 + a = a
--   a + 0 = a

class SimpleAddMonoid (α : Type) extends SimpleSemigroup α, Zero α where
  zero_add : ∀ (a : α), 0 + a = a
  add_zero : ∀ (a : α), a + 0 = a

-- Nat 是加法幺半群
instance : SimpleAddMonoid Nat where
  zero_add a := by simp
  add_zero a := by simp

-- 使用幺半群的性质
def monoid_demo (n : Nat) : Nat := 0 + n + 0

theorem monoid_demo_eq (n : Nat) : monoid_demo n = n := by
  simp [monoid_demo, SimpleAddMonoid.zero_add, SimpleAddMonoid.add_zero]
  <;> omega

/-! # 群（Group）-/

-- 群：幺半群 + 逆元
-- 加法群有 +, 0, 和 -，满足：
--   a + (-a) = 0
--   (-a) + a = 0

class SimpleAddGroup (α : Type) extends SimpleAddMonoid α, Neg α where
  add_left_neg : ∀ (a : α), -a + a = 0
  add_right_neg : ∀ (a : α), a + (-a) = 0

-- Int 是加法群
instance : SimpleAddGroup Int where
  add_left_neg a := by simp
  add_right_neg a := by simp

-- 使用群的性质
theorem int_cancel_left (a b c : Int) (h : a + b = a + c) : b = c := by
  have h1 : -a + (a + b) = -a + (a + c) := by rw [h]
  have h2 : (-a + a) + b = (-a + a) + c := by
    simpa [SimpleSemigroup.add_assoc] using h1
  have h3 : (0 : Int) + b = (0 : Int) + c := by
    rw [SimpleAddGroup.add_left_neg] at h2 <;> exact h2
  simpa using h3

/-! # 半环（Semiring）-/

-- 半环：同时有加法和乘法，满足分配律
-- 加法是交换幺半群，乘法是幺半群，乘法对加法分配

-- 交换性
class SimpleAddCommSemigroup (α : Type) extends SimpleSemigroup α where
  add_comm : ∀ (a b : α), a + b = b + a

class SimpleAddCommMonoid (α : Type) extends SimpleAddMonoid α, SimpleAddCommSemigroup α

-- 乘法半群
class SimpleMulSemigroup (α : Type) extends Mul α where
  mul_assoc : ∀ (a b c : α), (a * b) * c = a * (b * c)

-- 乘法幺半群
class SimpleMulMonoid (α : Type) extends SimpleMulSemigroup α, One α where
  one_mul : ∀ (a : α), 1 * a = a
  mul_one : ∀ (a : α), a * 1 = a

-- 半环
class SimpleSemiring (α : Type) extends SimpleAddCommMonoid α, SimpleMulMonoid α where
  left_distrib : ∀ (a b c : α), a * (b + c) = a * b + a * c
  right_distrib : ∀ (a b c : α), (a + b) * c = a * c + b * c
  zero_mul : ∀ (a : α), 0 * a = 0
  mul_zero : ∀ (a : α), a * 0 = 0

-- Nat 是半环
instance natAddCommSemigroup : SimpleAddCommSemigroup Nat where
  add_comm a b := by omega

instance : SimpleAddCommMonoid Nat where

instance natMulSemigroup : SimpleMulSemigroup Nat where
  mul_assoc a b c := by omega

instance natMulMonoid : SimpleMulMonoid Nat where
  one_mul a := by simp
  mul_one a := by simp

instance : SimpleSemiring Nat where
  left_distrib a b c := by
    simp [mul_add]
    <;> ring
  right_distrib a b c := by
    simp [add_mul]
    <;> ring
  zero_mul a := by simp
  mul_zero a := by simp

/-! # 类型类继承的好处 -/

-- 一旦证明了某个类型是群，就可以使用所有群的定理
-- 不需要重复证明

-- 通用的双倍函数（适用于任何有 Add 的类型）
def double {α : Type} [Add α] (x : α) : α := x + x

-- 通用的求和函数（适用于任何加法幺半群）
def sumList {α : Type} [SimpleAddMonoid α] (l : List α) : α :=
  l.foldr (· + ·) 0

-- 对 Nat 使用
def sum_nat : Nat := sumList [1, 2, 3, 4, 5]    -- 15

-- 对其他幺半群也可以使用（需要先定义实例）

/-! # 多重继承 -/

-- 类型类可以继承多个父类
-- 例如 Ring 继承自 AddGroup 和 MulMonoid 等

class SimpleRing (α : Type) extends SimpleAddGroup α, SimpleSemiring α

-- Int 是环
instance : SimpleAddCommSemigroup Int where
  add_comm a b := by simp [add_comm]

instance : SimpleAddCommMonoid Int where

instance : SimpleMulSemigroup Int where
  mul_assoc a b c := by simp [mul_assoc]

instance : SimpleMulMonoid Int where
  one_mul a := by simp
  mul_one a := by simp

instance : SimpleSemiring Int where
  left_distrib a b c := by simp [mul_add] <;> ring
  right_distrib a b c := by simp [add_mul] <;> ring
  zero_mul a := by simp
  mul_zero a := by simp

instance : SimpleRing Int where

/-! # 有序类型类 -/

-- 另一个重要的类型类层次是有序结构
-- LT (<), LE (≤), Ord (全序)

-- 偏序：自反、反对称、传递
class SimplePreorder (α : Type) extends LE α where
  le_refl : ∀ (a : α), a ≤ a
  le_trans : ∀ (a b c : α), a ≤ b → b ≤ c → a ≤ c

-- 全序：任意两个元素都可以比较
class SimpleLinearOrder (α : Type) extends SimplePreorder α where
  le_total : ∀ (a b : α), a ≤ b ∨ b ≤ a

-- Nat 是全序的
instance : SimplePreorder Nat where
  le_refl a := by simp
  le_trans a b c h1 h2 := by omega

instance : SimpleLinearOrder Nat where
  le_total a b := by omega

/-! # 标准库中的类型类层次 -/

-- Lean 标准库中的实际类型类层次更丰富
-- 以下是一些重要的类型类（按层次从低到高）：
--
-- 加法结构：
--   Add α           (+)
--   AddSemigroup α  加法半群（结合律）
--   AddCommSemigroup α  交换加法半群（交换律）
--   AddMonoid α     加法幺半群（+ 单位元 0）
--   AddCommMonoid α 交换加法幺半群
--   AddGroup α      加法群（+ 逆元 -）
--   AddCommGroup α  交换加法群
--
-- 乘法结构：
--   Mul α           (*)
--   MulSemigroup α  乘法半群
--   MulCommSemigroup α  交换乘法半群
--   MulMonoid α     乘法幺半群（* 单位元 1）
--   MulCommMonoid α 交换乘法幺半群
--   MulGroup α      乘法群
--   MulCommGroup α  交换乘法群
--
-- 环结构：
--   Semiring α      半环
--   CommSemiring α  交换半环
--   Ring α          环
--   CommRing α      交换环
--   DivisionRing α  除环
--   Field α         域
--
-- 有序结构：
--   LT α            (<)
--   LE α            (≤)
--   Preorder α      偏序
--   PartialOrder α  偏序（反对称）
--   LinearOrder α   全序

/-! # 有序代数结构 -/

-- 同时具有代数结构和有序结构
-- 例如：有序交换群

class OrderedAddCommGroup (α : Type) extends SimpleAddCommMonoid α, SimplePreorder α where
  add_le_add_left : ∀ (a b c : α), a ≤ b → c + a ≤ c + b

-- 整数是有序加法群
instance : OrderedAddCommGroup Int where
  add_le_add_left a b c h := by
    simp [add_le_add_iff_left] at * <;> omega

/-! # 类型类推断 -/

-- Lean 的类型类推断系统会自动查找合适的实例
-- 包括继承链上的实例

-- 例如：如果 α 是 Ring，那么它自动也是 AddGroup, AddMonoid, MulMonoid 等

-- 一个只需要 AddMonoid 的函数
def doubleAndAddZero {α : Type} [SimpleAddMonoid α] (x : α) : α :=
  double x + 0

-- 可以用 Ring 类型调用（因为 Ring 继承自 AddMonoid）
def int_example : Int := doubleAndAddZero (5 : Int)    -- 10

/-! # 钻石问题 -/

-- 类型类多重继承可能遇到"钻石问题"
-- 即一个类型类通过多条路径继承另一个类型类
--
-- 例如：CommRing 继承自 Ring 和 CommSemigroup
--       Ring 继承自 Semiring
--       CommSemigroup 继承自 MulSemigroup
--       Semiring 也继承自 MulSemigroup
--
-- 这样 MulSemigroup 就被继承了两次
-- Lean 通过要求实例唯一来解决这个问题

/-! # 示例：自定义类型的类型类实例 -/

-- 定义一个新的类型
newtype MyInt where
  | ofInt : Int → MyInt
deriving Repr, DecidableEq

-- 实现基本运算
instance : Add MyInt where
  add
    | MyInt.ofInt a, MyInt.ofInt b => MyInt.ofInt (a + b)

instance : Zero MyInt where
  zero := MyInt.ofInt 0

instance : Neg MyInt where
  neg
    | MyInt.ofInt a => MyInt.ofInt (-a)

instance : Mul MyInt where
  mul
    | MyInt.ofInt a, MyInt.ofInt b => MyInt.ofInt (a * b)

instance : One MyInt where
  one := MyInt.ofInt 1

-- 证明性质并建立类型类实例
instance : SimpleSemigroup MyInt where
  add_assoc a b c := by
    cases a <;> cases b <;> cases c <;> simp [Add.add] <;> ring

instance : SimpleAddMonoid MyInt where
  zero_add a := by cases a <;> simp [Zero.zero, Add.add]
  add_zero a := by cases a <;> simp [Zero.zero, Add.add]

instance : SimpleAddGroup MyInt where
  add_left_neg a := by cases a <;> simp [Neg.neg, Add.add, Zero.zero] <;> ring
  add_right_neg a := by cases a <;> simp [Neg.neg, Add.add, Zero.zero] <;> ring

-- 使用
def myint_ex1 : MyInt := MyInt.ofInt 3 + MyInt.ofInt 5
-- MyInt.ofInt 8

def myint_ex2 : MyInt := double (MyInt.ofInt 7)
-- MyInt.ofInt 14

end Lean4Tutorial.Examples.Typeclasses.TypeclassInheritance
