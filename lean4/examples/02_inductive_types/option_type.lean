/-
文件: 02_inductive_types/option_type.lean
描述: Lean 4 Option 类型
编译: lake build Lean4Tutorial.Examples.InductiveTypes.OptionType
-/

namespace Lean4Tutorial.Examples.InductiveTypes.OptionType

/-! # Option 类型简介 -/

-- Option α 表示可能存在也可能不存在的值
-- 有两种可能：some x（值为 x）或 none（没有值）
-- 类似于其他语言中的 Maybe 或 Optional

-- Option 的定义大致如下：
-- inductive Option (α : Type) : Type where
--   | none : Option α
--   | some (val : α) : Option α

-- 使用 some 包装一个值
def some_number : Option Nat := some 42
def some_string : Option String := some "hello"

-- 使用 none 表示没有值
def no_number : Option Nat := none
def no_string : Option String := none

/-! # Option 的基本操作 -/

-- 判断是否有值
def is_some_example : Bool := (some 5).isSome     -- true
def is_none_example : Bool := (none : Option Nat).isNone  -- true

-- 获取值（如果为 none 则返回默认值）
def get_or_zero : Nat := (some 42).getD 0         -- 42
def get_default : Nat := (none : Option Nat).getD 0  -- 0

-- 获取值（假设一定有值，不推荐）
-- (some 5).get!  -- 不安全，若为 none 会产生错误

/-! # Option 上的 map 操作 -/

-- Option.map：对 Option 中的值应用函数
-- 如果是 some x，返回 some (f x)
-- 如果是 none，返回 none

def double (x : Nat) : Nat := x * 2

def map_some : Option Nat := Option.map double (some 5)   -- some 10
def map_none : Option Nat := Option.map double none       -- none

-- 使用点号表示法
def map_some' : Option Nat := (some 5).map double         -- some 10

-- 对 Option String 应用操作
def map_string : Option String :=
  (some "hello").map String.toUpper                       -- some "HELLO"

def map_none_string : Option String :=
  (none : Option String).map String.toUpper               -- none

/-! # Option 的绑定（bind）-/

-- Option.bind：将返回 Option 的函数应用到 Option 中的值
-- 也称为 "flatMap"

-- 示例：安全的除法（除数为 0 时返回 none）
def safeDiv (x y : Nat) : Option Nat :=
  if y = 0 then none else some (x / y)

-- 使用 bind 链式调用
def chain_div : Option Nat :=
  (some 100).bind (fun x =>
    (some 5).bind (fun y =>
      safeDiv x y))
-- some 20

-- 更简洁的写法使用 do 表示法（Option 是一个 monad）
def chain_div_do : Option Nat := do
  let x ← some 100
  let y ← some 5
  safeDiv x y
-- some 20

-- 如果中间有 none，整个结果就是 none
def chain_div_fail : Option Nat := do
  let x ← some 100
  let y ← (none : Option Nat)
  safeDiv x y
-- none

/-! # 使用 Option 的例子 -/

-- 安全的列表索引访问
-- List.get? 返回 Option α
def myList : List Nat := [1, 2, 3, 4, 5]

def get_third : Option Nat := myList.get? 2     -- some 3
def get_tenth : Option Nat := myList.get? 9     -- none

-- 安全的字符串索引
def first_char_of (s : String) : Option Char :=
  if s.isEmpty then none else some (s.get 0)

def first_hello : Option Char := first_char_of "Hello"   -- some 'H'
def first_empty : Option Char := first_char_of ""        -- none

-- 字符串转数字
def parseNat (s : String) : Option Nat :=
  s.toNat?

def parse_42 : Option Nat := parseNat "42"              -- some 42
def parse_abc : Option Nat := parseNat "abc"             -- none

/-! # Option 的模式匹配 -/

-- 使用 match 解构 Option
def optionToString (opt : Option Nat) : String :=
  match opt with
  | some n => s!"值为 {n}"
  | none => "没有值"

def str1 : String := optionToString (some 42)     -- "值为 42"
def str2 : String := optionToString none           -- "没有值"

-- 使用 if let 简化匹配
def doubleOption (opt : Option Nat) : Option Nat :=
  if let some n := opt then some (n * 2) else none

def double_some : Option Nat := doubleOption (some 5)   -- some 10
def double_none : Option Nat := doubleOption none       -- none

/-! # Option 的组合子 -/

-- Option.orElse：如果第一个是 none，使用第二个
def or_else1 : Option Nat := (some 5).orElse (some 10)    -- some 5
def or_else2 : Option Nat := (none : Option Nat).orElse (some 10)  -- some 10
def or_else3 : Option Nat := (none : Option Nat).orElse none        -- none

-- <|> 运算符等价于 orElse
def or_else_op : Option Nat := (none : Option Nat) <|> some 42  -- some 42

-- Option.guard：如果条件满足返回 some ()，否则返回 none
def guard_pos (n : Int) : Option Unit :=
  if n > 0 then some () else none

def guard_5 : Option Unit := guard_pos 5     -- some ()
def guard_neg : Option Unit := guard_pos (-3)  -- none

/-! # 自定义 Option 函数 -/

-- 对两个 Option 值应用二元函数
def map2 {α β γ : Type} (f : α → β → γ)
  (oa : Option α) (ob : Option β) : Option γ :=
  match oa, ob with
  | some a, some b => some (f a b)
  | _, _ => none

def add_options : Option Nat := map2 (· + ·) (some 3) (some 4)   -- some 7
def add_none : Option Nat := map2 (· + ·) (some 3) none          -- none

-- 从 List 中过滤出所有 some 值
def catOptions {α : Type} (l : List (Option α)) : List α :=
  match l with
  | [] => []
  | some x :: rest => x :: catOptions rest
  | none :: rest => catOptions rest

def filtered : List Nat :=
  catOptions [some 1, none, some 3, none, some 5]
-- [1, 3, 5]

/-! # Option 与错误处理 -/

-- Option 可以用来表示可能失败的计算
-- none 表示失败，但不携带失败信息

-- 查找列表中的最大值
def maxList (l : List Nat) : Option Nat :=
  match l with
  | [] => none
  | x :: rest =>
    match maxList rest with
    | none => some x
    | some m => some (if x > m then x else m)

def max_of_list : Option Nat := maxList [3, 7, 2, 9, 5]    -- some 9
def max_empty : Option Nat := maxList []                    -- none

/-! # Option 的等式性质 -/

-- some 是单射的
theorem some_inj {α : Type} (x y : α) :
  some x = some y → x = y := by
  intro h
  injection h

-- none 不等于 some
theorem none_ne_some {α : Type} (x : α) :
  none ≠ some x := by
  intro h
  cases h

end Lean4Tutorial.Examples.InductiveTypes.OptionType
