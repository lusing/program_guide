/-
文件: 01_basics/basic_types.lean
描述: Lean 4 基本类型 - Nat, Int, Bool, String, Char, Float, Unit
编译: lake build Lean4Tutorial.Examples.Basics.BasicTypes
-/

namespace Lean4Tutorial.Examples.Basics.BasicTypes

/-! # 自然数 Nat -/

-- 自然数类型 Nat，表示非负整数
def zero : Nat := 0
def one : Nat := 1
def two : Nat := 2
def ten : Nat := 10

-- 自然数运算
def add_example : Nat := 3 + 7       -- 加法：10
def sub_example : Nat := 10 - 3      -- 减法：7（自然数减法，0-1=0）
def mul_example : Nat := 4 * 5       -- 乘法：20
def div_example : Nat := 10 / 3      -- 除法：3（整数除法）
def mod_example : Nat := 10 % 3      -- 取模：1
def pow_example : Nat := 2 ^ 10      -- 幂运算：1024

-- 比较运算
def eq_example : Bool := 5 = 5       -- 相等
def neq_example : Bool := 5 ≠ 3      -- 不等
def lt_example : Bool := 3 < 5       -- 小于
def le_example : Bool := 3 ≤ 5       -- 小于等于
def gt_example : Bool := 5 > 3       -- 大于
def ge_example : Bool := 5 ≥ 3       -- 大于等于

/-! # 整数 Int -/

-- 整数类型 Int，可以表示正整数、负整数和零
def pos_int : Int := 42
def neg_int : Int := -17
def zero_int : Int := 0

-- 整数运算
def int_add : Int := 5 + (-3)        -- 2
def int_sub : Int := 5 - 10          -- -5
def int_mul : Int := (-4) * 3        -- -12
def int_div : Int := 10 / 3          -- 3
def int_neg : Int := - (7 : Int)     -- -7

-- Nat 与 Int 转换
def nat_to_int : Int := ↑(5 : Nat)   -- 自然数转整数
def int_abs : Nat := Int.natAbs (-7) -- 整数绝对值转自然数

/-! # 布尔值 Bool -/

-- 布尔类型 Bool，只有两个值：true 和 false
def t : Bool := true
def f : Bool := false

-- 布尔运算
def and_example : Bool := true && false   -- 逻辑与：false
def or_example : Bool := true || false    -- 逻辑或：true
def not_example : Bool := !true           -- 逻辑非：false
def xor_example : Bool := true ^^ false   -- 异或：true

-- 条件表达式（if-then-else）
def cond_example : Nat := if 3 > 5 then 10 else 20  -- 20

/-! # 字符串 String -/

-- 字符串类型 String，表示文本
def hello : String := "Hello, Lean 4!"
def empty_str : String := ""

-- 字符串连接
def greeting : String := "Hello, " ++ "World!"       -- "Hello, World!"

-- 字符串长度
def str_length : Nat := "Lean 4".length              -- 6

-- 字符串插值（使用 s! 前缀）
def name : String := "Alice"
def age : Nat := 30
def intro : String := s!"My name is {name}, and I am {age} years old."

-- 多行字符串（用三个双引号）
def multi_line : String := """
这是第一行
这是第二行
这是第三行
"""

/-! # 字符 Char -/

-- 字符类型 Char，表示单个 Unicode 字符
def char_a : Char := 'a'
def char_Z : Char := 'Z'
def char_digit : Char := '5'
def char_space : Char := ' '
def char_chinese : Char := '中'

-- 字符操作
def is_upper : Bool := Char.isUpper 'A'     -- true
def is_lower : Bool := Char.isLower 'a'     -- true
def is_digit : Bool := Char.isDigit '7'     -- true
def to_upper : Char := Char.toUpper 'b'     -- 'B'
def to_lower : Char := Char.toLower 'B'     -- 'b'

/-! # 浮点数 Float -/

-- 浮点数类型 Float，表示双精度浮点数
def pi : Float := 3.14159
def e : Float := 2.71828
def zero_float : Float := 0.0

-- 浮点运算
def float_add : Float := 1.5 + 2.3          -- 3.8
def float_sub : Float := 5.0 - 2.5          -- 2.5
def float_mul : Float := 3.0 * 4.0          -- 12.0
def float_div : Float := 10.0 / 3.0         -- 3.333...
def float_neg : Float := -3.14              -- -3.14

-- 浮点函数
def float_sqrt : Float := Float.sqrt 16.0   -- 4.0
def float_abs : Float := Float.abs (-3.5)   -- 3.5
def float_sin : Float := Float.sin 0.0      -- 0.0
def float_cos : Float := Float.cos 0.0      -- 1.0

-- 类型转换
def nat_to_float : Float := (5 : Nat).toFloat    -- 5.0
def int_to_float : Float := ((-3 : Int)).toFloat  -- -3.0

/-! # Unit 类型 -/

-- Unit 类型只有一个值：()
-- 类似于其他语言中的 void 或 unit
def unit_val : Unit := ()

-- 返回 Unit 的函数通常表示有副作用的操作
def doNothing : Unit := ()

-- IO 操作返回 Unit（在 IO 单子中）
-- def printHello : IO Unit := IO.println "Hello"

/-! # 类型推断 -/

-- Lean 可以自动推断类型
def inferred_nat := 42                -- 推断为 Nat
def inferred_int := -7                -- 推断为 Int
def inferred_bool := true             -- 推断为 Bool
def inferred_string := "Hello"        -- 推断为 String
def inferred_float := 3.14            -- 推断为 Float

-- 使用 #check 可以查看表达式的类型（在编辑器中交互使用）
-- #check 42        -- Nat
-- #check "hello"   -- String
-- #check true      -- Bool

-- 使用 #eval 可以计算表达式的值（在编辑器中交互使用）
-- #eval 2 + 3      -- 5
-- #eval "Hello" ++ " World"  -- "Hello World"

end Lean4Tutorial.Examples.Basics.BasicTypes
