/-
文件: 02_inductive_types/dependent_types.lean
描述: Lean 4 依赖归纳类型（Vector 向量）
编译: lake build Lean4Tutorial.Examples.InductiveTypes.DependentTypes
-/

namespace Lean4Tutorial.Examples.InductiveTypes.DependentTypes

/-! # 什么是依赖类型 -/

-- 依赖类型是指其定义依赖于另一个值的类型
-- 在 Lean 中，类型本身也可以是值（Type : Type 1）
-- 因此我们可以定义"由值索引的类型族"

-- 一个简单的依赖类型例子：Fin n
-- Fin n 表示小于 n 的自然数类型
-- Fin 0 是空类型（没有元素）
-- Fin 1 只有一个元素 {0}
-- Fin 2 有两个元素 {0, 1}
-- 等等

-- 使用标准库的 Fin
def fin0_val : Fin 5 := ⟨3, by decide⟩  -- 表示 3 < 5
def fin1_val : Fin 10 := ⟨7, by decide⟩ -- 表示 7 < 10

-- Fin 的值由两部分组成：自然数 + 证明它小于上界

/-! # Vector 向量类型 -/

-- Vector α n 是长度为 n 的 α 类型元素的向量
-- 这是一个依赖归纳类型，因为它的类型依赖于长度 n

inductive Vector (α : Type) : Nat → Type where
  | nil : Vector α 0                  -- 空向量，长度为 0
  | cons (x : α) (v : Vector α n) : Vector α (n + 1)  -- 非空向量，长度为 n+1

-- 注：上面的定义中 n 是隐式参数
-- Vector α 0 是一个类型（空向量的类型）
-- Vector α 1 是另一个类型（长度为 1 的向量类型）
-- Vector α n 是长度为 n 的向量类型

open Vector

-- 示例向量
def vnil : Vector Nat 0 := nil
def v1 : Vector Nat 1 := cons 5 nil
def v2 : Vector Nat 2 := cons 3 (cons 7 nil)
def v3 : Vector Nat 3 := cons 1 (cons 2 (cons 3 nil))

/-! # Vector 上的操作 -/

-- 获取向量的长度（编译时已知，因为长度是类型的一部分）
def vlength {α : Type} {n : Nat} (v : Vector α n) : Nat := n

def len3 : Nat := vlength v3    -- 3

-- 向量的头部（只有非空向量才能取头）
-- 注意：类型保证了 n > 0，所以不会出现运行时错误
def vhead {α : Type} {n : Nat} (v : Vector α (n + 1)) : α :=
  match v with
  | cons x _ => x

def head2 : Nat := vhead v2     -- 3

-- 向量的尾部
def vtail {α : Type} {n : Nat} (v : Vector α (n + 1)) : Vector α n :=
  match v with
  | cons _ rest => rest

def tail2 : Vector Nat 1 := vtail v2   -- [7]

-- 向量拼接
def vappend {α : Type} {m n : Nat}
  (v1 : Vector α m) (v2 : Vector α n) : Vector α (m + n) :=
  match v1 with
  | nil => v2
  | cons x rest => cons x (vappend rest v2)

def vapp : Vector Nat 5 := vappend v2 v3
-- [3, 7, 1, 2, 3]

-- 向量的 map
def vmap {α β : Type} {n : Nat} (f : α → β) (v : Vector α n) : Vector β n :=
  match v with
  | nil => nil
  | cons x rest => cons (f x) (vmap f rest)

def vdoubled : Vector Nat 3 := vmap (· * 2) v3
-- [2, 4, 6]

/-! # 安全的索引访问 -/

-- Vector 的一个重要优势是可以实现安全的索引访问
-- 索引的类型是 Fin n，保证了索引在有效范围内

def vget {α : Type} {n : Nat} (v : Vector α n) (i : Fin n) : α :=
  match v, i with
  | cons x _, ⟨0, _⟩ => x
  | cons _ rest, ⟨i' + 1, h⟩ =>
    vget rest ⟨i', by
      simp at h
      <;> omega⟩
  | nil, ⟨_, h⟩ => by
    simp at h <;> omega

-- 安全访问示例
def get_v3_0 : Nat := vget v3 ⟨0, by decide⟩   -- 1
def get_v3_1 : Nat := vget v3 ⟨1, by decide⟩   -- 2
def get_v3_2 : Nat := vget v3 ⟨2, by decide⟩   -- 3

-- 越界访问在编译时就会被拒绝
-- 下面这行无法编译，因为 3 ≥ 3
-- def get_v3_3 : Nat := vget v3 ⟨3, by decide⟩

/-! # 向量的其他操作 -/

-- 向量反转
def vreverse_aux {α : Type} {m n : Nat}
  (v : Vector α m) (acc : Vector α n) : Vector α (m + n) :=
  match v with
  | nil => acc
  | cons x rest =>
    vreverse_aux rest (cons x acc)

-- 简化版本（不证明长度相等）
def vreverse {α : Type} {n : Nat} (v : Vector α n) : Vector α n :=
  match v with
  | nil => nil
  | cons x rest => vappend (vreverse rest) (cons x nil)

-- 注意：上面的定义中 vappend 返回 Vector α (n + 1)，
-- 而我们需要返回 Vector α (n + 1)，类型是匹配的

/-! # 有限集合 Fin -/

-- Fin n 是一个标准的依赖类型，表示 {0, 1, ..., n-1}
-- 它的构造子：
--   Fins.zero : Fin (n + 1)
--   Fins.succ : Fin n → Fin (n + 1)

-- 另一种构造方式：⟨value, proof⟩
-- 其中 proof 证明 value < n

def f0 : Fin 3 := ⟨0, by decide⟩
def f1 : Fin 3 := ⟨1, by decide⟩
def f2 : Fin 3 := ⟨2, by decide⟩

-- Fin n 的元素个数恰好是 n
-- Fin 0 没有元素

/-! # 其他依赖类型示例 -/

-- 长度为 n 的列表（另一种写法）
-- 使用 Σ 类型（依赖对）也可以表达"长度为 n 的列表"
-- 即 ∃ n, List α （长度为 n 的列表）
-- 但 Vector α n 更直接

-- 依赖对类型 Σ x : α, β x
-- 第一个分量是 x : α，第二个分量是 β x（类型依赖于 x）
def dep_pair : Σ n : Nat, Vector Nat n := ⟨3, v3⟩

/-! # 类型族 -/

-- 我们可以定义由布尔值索引的类型族
def BoolType (b : Bool) : Type :=
  match b with
  | true => Nat
  | false => String

-- BoolType true 是 Nat 类型
-- BoolType false 是 String 类型

def bt_true : BoolType true := 42
def bt_false : BoolType false := "hello"

-- 依赖函数：返回类型依赖于输入
def dependentFunction (b : Bool) : BoolType b :=
  match b with
  | true => 100
  | false => "world"

def df_true : Nat := dependentFunction true     -- 100
def df_false : String := dependentFunction false  -- "world"

/-! # 相等类型 -/

-- Eq 也是一个依赖类型
-- Eq a b （即 a = b）是关于两个值相等的命题类型
-- refl a : a = a 是唯一的构造子

-- 相等证明
def eq_refl : 2 + 2 = 4 := by rfl

-- 等式的对称性
def eq_symm {α : Type} {a b : α} (h : a = b) : b = a :=
  Eq.symm h

-- 等式的传递性
def eq_trans {α : Type} {a b c : α} (h1 : a = b) (h2 : b = c) : a = c :=
  Eq.trans h1 h2

/-! # 依赖类型的意义 -/

-- 依赖类型让我们可以在类型层面表达更多信息
-- 例如：
-- - Vector α n：长度为 n 的向量（保证长度正确）
-- - Fin n：小于 n 的自然数（保证范围正确）
-- - {x : Nat // x > 0}：正整数（保证大于 0）

-- 这些类型信息可以在编译时保证程序的正确性
-- 很多运行时错误可以被转化为编译时错误

/-! # 子类型 -/

-- 子类型 {x : α // P x} 表示满足性质 P 的 α 的子集
-- 这也是一种依赖类型

-- 正自然数
def PosNat := {n : Nat // n > 0}

-- 构造正自然数
def one_pos : PosNat := ⟨1, by decide⟩
def five_pos : PosNat := ⟨5, by decide⟩

-- 获取正自然数的值
def pos_val : Nat := one_pos.val    -- 1

-- 非空字符串
def NonEmptyString := {s : String // s ≠ ""}

def hello_nonempty : NonEmptyString := ⟨"hello", by decide⟩

end Lean4Tutorial.Examples.InductiveTypes.DependentTypes
