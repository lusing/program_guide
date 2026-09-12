/-
文件: 03_pattern_matching/match_basics.lean
描述: Lean 4 match 表达式基础
编译: lake build Lean4Tutorial.Examples.PatternMatching.MatchBasics
-/

namespace Lean4Tutorial.Examples.PatternMatching.MatchBasics

/-! # match 表达式简介 -/

-- match 表达式用于对值进行模式匹配
-- 语法：match <表达式> with | <模式1> => <结果1> | <模式2> => <结果2> ...

/-! # 对自然数的模式匹配 -/

-- 判断是否为零
def isZero (n : Nat) : Bool :=
  match n with
  | 0 => true
  | _ + 1 => false

def zero_true : Bool := isZero 0     -- true
def one_false : Bool := isZero 1     -- false
def five_false : Bool := isZero 5    -- false

-- 求前驱（对于 0 返回 0）
def pred (n : Nat) : Nat :=
  match n with
  | 0 => 0
  | m + 1 => m

def pred_zero : Nat := pred 0        -- 0
def pred_five : Nat := pred 5        -- 4

/-! # 对布尔值的模式匹配 -/

def my_not (b : Bool) : Bool :=
  match b with
  | true => false
  | false => true

def not_true : Bool := my_not true   -- false
def not_false : Bool := my_not false -- true

def my_and (a b : Bool) : Bool :=
  match a with
  | true => b
  | false => false

def and_tt : Bool := my_and true true    -- true
def and_tf : Bool := my_and true false   -- false
def and_ff : Bool := my_and false false  -- false

/-! # 对 Option 的模式匹配 -/

def option_default {α : Type} (default : α) (opt : Option α) : α :=
  match opt with
  | some x => x
  | none => default

def default_some : Nat := option_default 0 (some 42)   -- 42
def default_none : Nat := option_default 0 none        -- 0

-- 更复杂的 Option 操作
def option_map {α β : Type} (f : α → β) (opt : Option α) : Option β :=
  match opt with
  | some x => some (f x)
  | none => none

def map_some : Option Nat := option_map (· * 2) (some 5)  -- some 10
def map_none : Option Nat := option_map (· * 2) none      -- none

/-! # 对元组的模式匹配 -/

-- 对二元组的模式匹配
def add_pair (p : Nat × Nat) : Nat :=
  match p with
  | (x, y) => x + y

def add_pair_example : Nat := add_pair (3, 4)   -- 7

-- 交换二元组
def swap {α β : Type} (p : α × β) : β × α :=
  match p with
  | (x, y) => (y, x)

def swap_example : String × Nat := swap (42, "hello")  -- ("hello", 42)

-- 对三元组的模式匹配
def sum_triple (t : Nat × Nat × Nat) : Nat :=
  match t with
  | (x, y, z) => x + y + z

def sum_triple_example : Nat := sum_triple (1, 2, 3)   -- 6

/-! # 对列表的模式匹配 -/

-- 判断列表是否为空
def isEmpty {α : Type} (l : List α) : Bool :=
  match l with
  | [] => true
  | _ :: _ => false

def empty_true : Bool := isEmpty ([] : List Nat)       -- true
def empty_false : Bool := isEmpty [1, 2, 3]            -- false

-- 获取列表头部
def head {α : Type} (l : List α) (default : α) : α :=
  match l with
  | [] => default
  | x :: _ => x

def head_cons : Nat := head [1, 2, 3] 0     -- 1
def head_nil : Nat := head ([] : List Nat) 0  -- 0

-- 获取列表尾部
def tail {α : Type} (l : List α) : List α :=
  match l with
  | [] => []
  | _ :: rest => rest

def tail_example : List Nat := tail [1, 2, 3]   -- [2, 3]

/-! # 通配符 _ -/

-- 使用 _ 表示我们不关心这个值

def isEmpty' {α : Type} (l : List α) : Bool :=
  match l with
  | [] => true
  | _::_ => false   -- 不关心头和尾具体是什么

-- 对于多参数的匹配，也可以使用通配符
def isFirstZero (l : List Nat) : Bool :=
  match l with
  | [] => false
  | 0::_ => true
  | _::_ => false

def first_zero_true : Bool := isFirstZero [0, 1, 2]    -- true
def first_zero_false : Bool := isFirstZero [1, 2, 3]   -- false

/-! # 多值匹配 -/

-- match 可以同时匹配多个值

def compare (x y : Nat) : String :=
  match x, y with
  | 0, 0 => "both zero"
  | 0, _ => "first is zero"
  | _, 0 => "second is zero"
  | _, _ => "both non-zero"

def cmp1 : String := compare 0 0       -- "both zero"
def cmp2 : String := compare 0 5       -- "first is zero"
def cmp3 : String := compare 5 0       -- "second is zero"
def cmp4 : String := compare 5 3       -- "both non-zero"

-- 布尔运算的真值表
def xor (a b : Bool) : Bool :=
  match a, b with
  | true, false => true
  | false, true => true
  | _, _ => false

def xor_tf : Bool := xor true false    -- true
def xor_tt : Bool := xor true true     -- false

/-! # 嵌套模式匹配 -/

-- 模式可以嵌套

-- 判断列表是否恰好有一个元素
def isSingleton {α : Type} (l : List α) : Bool :=
  match l with
  | [_] => true
  | _ => false

def singleton_true : Bool := isSingleton [5]       -- true
def singleton_false1 : Bool := isSingleton []      -- false
def singleton_false2 : Bool := isSingleton [1, 2]  -- false

-- 判断列表是否恰好有两个元素
def hasTwoElements {α : Type} (l : List α) : Bool :=
  match l with
  | [_, _] => true
  | _ => false

def two_true : Bool := hasTwoElements [1, 2]       -- true
def two_false : Bool := hasTwoElements [1, 2, 3]   -- false

-- 更复杂的嵌套模式
def firstTwoSum (l : List Nat) : Nat :=
  match l with
  | x :: y :: _ => x + y
  | [x] => x
  | [] => 0

def sum_two : Nat := firstTwoSum [3, 4, 5]    -- 7
def sum_one : Nat := firstTwoSum [7]          -- 7
def sum_zero : Nat := firstTwoSum []          -- 0

/-! # if let 表达式 -/

-- if let 是 match 的一种简化形式
-- 只关心一种模式的情况

def getOrZero (opt : Option Nat) : Nat :=
  if let some n := opt then n else 0

def getor_some : Nat := getOrZero (some 42)   -- 42
def getor_none : Nat := getOrZero none        -- 0

-- 对列表使用 if let
def headIfAny {α : Type} (l : List α) (default : α) : α :=
  if let h::_ := l then h else default

def head_if : Nat := headIfAny [1, 2, 3] 0    -- 1
def head_else : Nat := headIfAny [] 0         -- 0

/-! # 模式匹配中的守卫 -/

-- 使用 if 守卫在模式匹配中添加额外条件

def classify (n : Nat) : String :=
  match n with
  | 0 => "zero"
  | n + 1 => if n < 5 then "small" else "large"

def class_zero : String := classify 0     -- "zero"
def class_small : String := classify 3    -- "small"
def class_large : String := classify 10   -- "large"

-- 另一个例子
def safeHead {α : Type} (l : List α) : Option α :=
  match l with
  | [] => none
  | x :: _ => some x

/-! # 自定义归纳类型的模式匹配 -/

-- 定义一个颜色类型
inductive Color where
  | red
  | green
  | blue
  | rgb (r g b : Nat)
deriving Repr

open Color

-- 对 Color 进行模式匹配
def colorName (c : Color) : String :=
  match c with
  | red => "红色"
  | green => "绿色"
  | blue => "蓝色"
  | rgb _ _ _ => "自定义RGB"

def name_red : String := colorName red              -- "红色"
def name_rgb : String := colorName (rgb 100 200 50) -- "自定义RGB"

-- 获取颜色的亮度（简化计算）
def brightness (c : Color) : Nat :=
  match c with
  | red => 200
  | green => 180
  | blue => 150
  | rgb r g b => (r + g + b) / 3

def bright_red : Nat := brightness red                 -- 200
def bright_rgb : Nat := brightness (rgb 100 200 50)    -- 116

/-! # match 的穷尽性检查 -/

-- Lean 会检查 match 是否覆盖了所有可能的情况
-- 如果有遗漏，Lean 会报错

-- 这是一个完整的匹配（覆盖了 Bool 的所有情况）
def complete_match (b : Bool) : Nat :=
  match b with
  | true => 1
  | false => 0

-- 下面的代码会报错（缺少 false 分支）
-- def incomplete_match (b : Bool) : Nat :=
--   match b with
--   | true => 1

end Lean4Tutorial.Examples.PatternMatching.MatchBasics
