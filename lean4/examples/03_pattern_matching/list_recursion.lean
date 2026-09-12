/-
文件: 03_pattern_matching/list_recursion.lean
描述: Lean 4 列表上的递归（length, map, foldr）
编译: lake build Lean4Tutorial.Examples.PatternMatching.ListRecursion
-/

namespace Lean4Tutorial.Examples.PatternMatching.ListRecursion

/-! # 列表递归简介 -/

-- 列表是 Lean 中最常用的递归数据结构之一
-- List α 有两个构造子：[] (空列表) 和 :: (cons)
-- 列表上的递归函数通常遵循类似的模式：
-- - 基础情况：空列表 []
-- - 递归情况：x :: xs，对 xs 递归调用

/-! # 列表长度 -/

-- 计算列表长度
def length {α : Type} : List α → Nat
  | [] => 0
  | _ :: xs => 1 + length xs

def len1 : Nat := length ([] : List Nat)    -- 0
def len2 : Nat := length [1]                -- 1
def len3 : Nat := length [1, 2, 3, 4, 5]    -- 5

/-! # map 映射 -/

-- 对列表中的每个元素应用函数
def map {α β : Type} (f : α → β) : List α → List β
  | [] => []
  | x :: xs => f x :: map f xs

def map_double : List Nat := map (· * 2) [1, 2, 3]
-- [2, 4, 6]

def map_toString : List String := map toString [1, 2, 3]
-- ["1", "2", "3"]

def map_length : List Nat := map String.length ["hello", "world", "lean"]
-- [5, 5, 4]

/-! # filter 过滤 -/

-- 保留满足谓词的元素
def filter {α : Type} (p : α → Bool) : List α → List α
  | [] => []
  | x :: xs =>
    if p x then x :: filter p xs
    else filter p xs

def filter_even : List Nat := filter (· % 2 = 0) [1, 2, 3, 4, 5, 6]
-- [2, 4, 6]

def filter_long : List String := filter (fun s => s.length > 3) ["a", "bb", "ccc", "dddd"]
-- ["dddd"]

/-! # foldr 右折叠 -/

-- foldr f init [x1, x2, ..., xn] = f x1 (f x2 (... (f xn init)...))
-- 从右向左累积
def foldr {α β : Type} (f : α → β → β) (init : β) : List α → β
  | [] => init
  | x :: xs => f x (foldr f init xs)

-- 求和
def sum : List Nat → Nat := foldr (· + ·) 0

def sum_example : Nat := sum [1, 2, 3, 4, 5]    -- 15

-- 求积
def product : List Nat → Nat := foldr (· * ·) 1

def product_example : Nat := product [1, 2, 3, 4, 5]    -- 120

-- 所有元素都满足条件
def all {α : Type} (p : α → Bool) : List α → Bool :=
  foldr (fun x acc => p x && acc) true

def all_even : Bool := all (· % 2 = 0) [2, 4, 6]    -- true
def all_even2 : Bool := all (· % 2 = 0) [2, 3, 6]   -- false

-- 存在元素满足条件
def any {α : Type} (p : α → Bool) : List α → Bool :=
  foldr (fun x acc => p x || acc) false

def any_even : Bool := any (· % 2 = 0) [1, 3, 5]    -- false
def any_even2 : Bool := any (· % 2 = 0) [1, 2, 3]   -- true

/-! # foldl 左折叠 -/

-- foldl f init [x1, x2, ..., xn] = f (... (f (f init x1) x2) ...) xn
-- 从左向右累积
def foldl {α β : Type} (f : β → α → β) (init : β) : List α → β
  | [] => init
  | x :: xs => foldl f (f init x) xs

-- 使用 foldl 计算列表反转
def reverse {α : Type} (l : List α) : List α :=
  foldl (fun acc x => x :: acc) [] l

def reverse_example : List Nat := reverse [1, 2, 3]   -- [3, 2, 1]

-- foldl 求和（与 foldr 结果相同，因为加法是交换的）
def sum_l : List Nat → Nat := foldl (· + ·) 0

def sum_l_example : Nat := sum_l [1, 2, 3]    -- 6

/-! # 列表拼接 append -/

def append {α : Type} : List α → List α → List α
  | [], ys => ys
  | x :: xs, ys => x :: append xs ys

-- 中缀表示法 ++
def append_example : List Nat := append [1, 2] [3, 4]    -- [1, 2, 3, 4]

/-! # flatMap / concatMap -/

-- flatMap f l = join (map f l)
-- 将每个元素映射为一个列表，然后拼接所有结果
def flatMap {α β : Type} (f : α → List β) : List α → List β
  | [] => []
  | x :: xs => append (f x) (flatMap f xs)

-- 示例：对每个元素生成 [n, n*2]
def dup_and_double : List Nat := flatMap (fun n => [n, n * 2]) [1, 2, 3]
-- [1, 2, 2, 4, 3, 6]

/-! # zip 与 zipWith -/

-- 将两个列表的对应元素组合成二元组
def zip {α β : Type} : List α → List β → List (α × β)
  | [], _ => []
  | _, [] => []
  | x :: xs, y :: ys => (x, y) :: zip xs ys

def zip_example : List (Nat × String) := zip [1, 2, 3] ["a", "b", "c"]
-- [(1, "a"), (2, "b"), (3, "c")]

-- 使用自定义函数组合两个列表
def zipWith {α β γ : Type} (f : α → β → γ) : List α → List β → List γ
  | [], _ => []
  | _, [] => []
  | x :: xs, y :: ys => f x y :: zipWith f xs ys

def zipWith_add : List Nat := zipWith (· + ·) [1, 2, 3] [4, 5, 6]
-- [5, 7, 9]

/-! # take 与 drop -/

-- 取前 n 个元素
def take {α : Type} : Nat → List α → List α
  | 0, _ => []
  | _, [] => []
  | n + 1, x :: xs => x :: take n xs

def take_3 : List Nat := take 3 [1, 2, 3, 4, 5]    -- [1, 2, 3]
def take_10 : List Nat := take 10 [1, 2, 3]        -- [1, 2, 3]

-- 丢弃前 n 个元素
def drop {α : Type} : Nat → List α → List α
  | 0, xs => xs
  | _, [] => []
  | n + 1, _ :: xs => drop n xs

def drop_2 : List Nat := drop 2 [1, 2, 3, 4, 5]    -- [3, 4, 5]
def drop_10 : List Nat := drop 10 [1, 2, 3]        -- []

/-! # 索引访问 -/

-- 获取第 n 个元素（返回 Option）
def get? {α : Type} : List α → Nat → Option α
  | [], _ => none
  | x :: _, 0 => some x
  | _ :: xs, n + 1 => get? xs n

def get_2 : Option Nat := get? [10, 20, 30, 40] 2    -- some 30
def get_10 : Option Nat := get? [10, 20, 30] 10      -- none

-- 更新第 n 个元素（返回新列表）
def set? {α : Type} : List α → Nat → α → Option (List α)
  | [], _, _ => none
  | _ :: xs, 0, y => some (y :: xs)
  | x :: xs, n + 1, y =>
    match set? xs n y with
    | some ys => some (x :: ys)
    | none => none

def set_2 : Option (List Nat) := set? [1, 2, 3] 1 42
-- some [1, 42, 3]

/-! # 查找 -/

-- 查找满足条件的第一个元素
def find? {α : Type} (p : α → Bool) : List α → Option α
  | [] => none
  | x :: xs => if p x then some x else find? p xs

def find_even : Option Nat := find? (· % 2 = 0) [1, 3, 4, 5, 6]
-- some 4

-- 查找元素的索引
def findIndex? {α : Type} (p : α → Bool) (l : List α) : Option Nat :=
  go l 0
where
  go : List α → Nat → Option Nat
    | [], _ => none
    | x :: xs, i => if p x then some i else go xs (i + 1)

def find_index : Option Nat := findIndex? (· = 3) [1, 2, 3, 4]
-- some 2

/-! # 列表属性 -/

-- 判断列表是否已排序（升序）
def isSorted : List Nat → Bool
  | [] => true
  | [_] => true
  | x :: y :: rest => x ≤ y && isSorted (y :: rest)

def sorted_true : Bool := isSorted [1, 2, 3, 4, 5]     -- true
def sorted_false : Bool := isSorted [1, 3, 2, 4]       -- false

-- 判断列表是否有重复元素
def hasDuplicates {α : Type} [DecidableEq α] : List α → Bool
  | [] => false
  | x :: xs => xs.contains x || hasDuplicates xs

def dup_true : Bool := hasDuplicates [1, 2, 3, 2]     -- true
def dup_false : Bool := hasDuplicates [1, 2, 3]       -- false

/-! # 递归证明示例 -/

-- 列表长度与拼接的关系
theorem length_append {α : Type} (xs ys : List α) :
  length (append xs ys) = length xs + length ys := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    simp [length, append, ih]
    <;> omega

-- map 与 append 交换
theorem map_append {α β : Type} (f : α → β) (xs ys : List α) :
  map f (append xs ys) = append (map f xs) (map f ys) := by
  induction xs with
  | nil => rfl
  | cons x xs ih =>
    simp [map, append, ih]

/-! # 总结 -/

-- 列表递归的一般模式：
-- 1. 基础情况（空列表）：给出直接结果
-- 2. 递归情况（x :: xs）：对 xs 递归，然后用 x 组合结果
--
-- 常见的列表操作：
-- - map：转换每个元素
-- - filter：保留满足条件的元素
-- - foldr/foldl：累积计算
-- - append：拼接两个列表
-- - zip：组合两个列表
-- - take/drop：截取子列表

end Lean4Tutorial.Examples.PatternMatching.ListRecursion
