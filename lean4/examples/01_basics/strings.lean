/-
文件: 01_basics/strings.lean
描述: Lean 4 字符串操作：连接、长度、插值
编译: lake build Lean4Tutorial.Examples.Basics.Strings
-/

namespace Lean4Tutorial.Examples.Basics.Strings

/-! # 字符串基础 -/

-- 字符串字面量用双引号括起来
def hello : String := "Hello, World!"
def empty : String := ""
def single_char : String := "a"

-- 字符串是字符的序列
-- Lean 中的 String 是 UTF-8 编码的

/-! # 字符串连接 -/

-- 使用 ++ 运算符连接字符串
def greeting : String := "Hello, " ++ "Lean 4!"    -- "Hello, Lean 4!"

-- 连接多个字符串
def sentence : String := "I" ++ " " ++ "love" ++ " " ++ "Lean"
-- "I love Lean"

-- 使用 List.join 连接字符串列表
def words : List String := ["Lean", "is", "fun"]
def joined : String := String.join words            -- "Leanisfun"

-- 使用 String.intercalate 用分隔符连接
def with_spaces : String := " ".intercalate words   -- "Lean is fun"

/-! # 字符串长度 -/

-- String.length 返回字符串中字符的数量（Unicode 码点数量）
def len1 : Nat := "Hello".length                    -- 5
def len2 : Nat := "".length                         -- 0
def len3 : Nat := "你好，世界".length                  -- 5（5个中文字符）

-- String.utf8ByteSize 返回 UTF-8 编码的字节数
def byte_size1 : Nat := "Hello".utf8ByteSize        -- 5
def byte_size2 : Nat := "你好".utf8ByteSize           -- 6（每个中文字符3字节）

-- 判断字符串是否为空
def is_empty1 : Bool := "".isEmpty                  -- true
def is_empty2 : Bool := "hello".isEmpty             -- false

/-! # 字符串插值 -/

-- 使用 s!"..." 进行字符串插值
-- 在花括号 {} 中可以放入任意表达式

def name : String := "Alice"
def age : Nat := 30

-- 简单插值
def intro1 : String := s!"My name is {name}."
-- "My name is Alice."

-- 多个插值
def intro2 : String := s!"{name} is {age} years old."
-- "Alice is 30 years old."

-- 插值中可以使用表达式
def intro3 : String := s!"Next year, {name} will be {age + 1}."
-- "Next year, Alice will be 31."

-- 插值中可以调用函数
def name_length : Nat := name.length
def intro4 : String := s!"{name} has {name_length} letters."
-- "Alice has 5 letters."

-- 嵌套的字符串插值
def intro5 : String := s!"Hello, {s!"my name is {name}"}!"
-- "Hello, my name is Alice!"

/-! # 字符串比较 -/

-- 字符串可以比较相等和顺序
def eq1 : Bool := "hello" = "hello"                  -- true
def eq2 : Bool := "hello" = "world"                  -- false
def ne1 : Bool := "hello" ≠ "world"                  -- true

-- 字典序比较
def lt1 : Bool := "apple" < "banana"                 -- true
def le1 : Bool := "apple" ≤ "apple"                  -- true
def gt1 : Bool := "zoo" > "apple"                    -- true

/-! # 字符串索引与子串 -/

-- 注意：Lean 的字符串索引是按字节偏移的，不是按字符的
-- 对于 ASCII 字符串，字节偏移等于字符位置

-- String.get 获取指定字节位置的字符
-- 注意：需要提供证明位置有效的参数
-- 更安全的方式是使用 get? 或 getD

-- 使用 String.get? 获取字符（返回 Option Char）
def first_char : Option Char := "Hello".get? 0      -- some 'H'
def fifth_char : Option Char := "Hello".get? 4      -- some 'o'
def out_of_bounds : Option Char := "Hello".get? 10  -- none

-- 使用 String.getD 获取字符，带默认值
def get_or_default : Char := "Hello".getD 0 '?'     -- 'H'
def get_default : Char := "Hello".getD 10 '?'       -- '?'

-- 获取第一个和最后一个字符
def first_char' : Option Char := "Hello".front?     -- some 'H'
def last_char : Option Char := "Hello".back?        -- some 'o'

-- 字符串截取
def substr1 : Substring := "Hello, World!".substr 0 5
-- Substring 表示子串，用 toString 转换为 String
def substr1_str : String := substr1.toString         -- "Hello"

def substr2 : String := ("Hello, World!".substr 7 5).toString
-- "World"

-- take 和 drop
def take5 : String := "Hello, World!".take 5         -- "Hello"
def drop7 : String := "Hello, World!".drop 7         -- "World!"

/-! # 字符串转换 -/

-- 大小写转换
def upper : String := "hello".toUpper                -- "HELLO"
def lower : String := "HELLO".toLower                -- "hello"

-- 去除首尾空白
def trimmed1 : String := "  hello  ".trim            -- "hello"
def trimmed2 : String := "\n  hello \t ".trim        -- "hello"

-- 去除首部/尾部空白
def triml : String := "  hello".trimLeft             -- "hello"
def trimr : String := "hello  ".trimRight            -- "hello"

-- 字符串反转
def reversed : String := "Hello".reverse             -- "olleH"

-- 字符替换
def replaced : String := "hello".replace 'l' 'x'     -- "hexxo"

-- 字符串重复
def repeated : String := "ha".repeat 3               -- "hahaha"

/-! # 字符串包含与查找 -/

-- 包含子串
def contains1 : Bool := "Hello, World!".contains "World"  -- true
def contains2 : Bool := "Hello, World!".contains "hello"  -- false（区分大小写）

-- 前缀/后缀
def prefix1 : Bool := "Hello".startsWith "He"       -- true
def suffix1 : Bool := "Hello".endsWith "lo"         -- true

-- 查找子串位置
def find_pos : Option String.Pos := "Hello, World!".find? (· = 'W')
-- 返回位置

-- 计数
def count_l : Nat := "hello".count (· = 'l')        -- 2

/-! # 字符串与字符列表转换 -/

-- 字符串转字符列表
def chars : List Char := "Hello".data                -- ['H', 'e', 'l', 'l', 'o']

-- 字符列表转字符串
def from_chars : String := String.mk ['a', 'b', 'c'] -- "abc"

-- 使用 List.asString
def from_list : String := ['x', 'y', 'z'].asString   -- "xyz"

/-! # 字符串与数字转换 -/

-- 字符串转自然数（返回 Option Nat）
def parse_nat1 : Option Nat := "42".toNat?           -- some 42
def parse_nat2 : Option Nat := "abc".toNat?          -- none

-- 字符串转整数
-- 可以使用 Int.ofNat 或其他方法
def string_to_int : Option Int :=
  match "123".toNat? with
  | some n => some (Int.ofNat n)
  | none => none

-- 数字转字符串
def nat_to_string : String := toString 42            -- "42"
def int_to_string : String := toString (-7 : Int)    -- "-7"
def float_to_string : String := toString 3.14        -- "3.140000"

-- 使用 toString 可以将很多类型转为字符串
def bool_to_string : String := toString true         -- "true"

/-! # 多行字符串 -/

-- Lean 4 没有三引号语法，多行字符串用 \n 转义与拼接构造
def poem : String :=
  "床前明月光，\n" ++
  "疑是地上霜。\n" ++
  "举头望明月，\n" ++
  "低头思故乡。"

-- String.intercalate 用分隔符把行列表拼成多行字符串
def code_example : String := String.intercalate "\n"
  ["def hello :=", "  IO.println \"Hello, World!\""]

/-! # 字符串分割 -/

-- 按字符分割
def split_csv : List String := "a,b,c".splitOn ","
-- ["a", "b", "c"]

def split_space : List String := "hello world".splitOn " "
-- ["hello", "world"]

-- split 函数（按谓词分割）
def split_on_comma : List String := "a,b,c".split (· = ',')
-- 注意：split 的行为与 splitOn 略有不同

/-! # 格式化字符串 -/

-- 使用 s! 插值是最常用的格式化方式
def format_example (name : String) (score : Nat) : String :=
  s!"{name}: {score} 分"

def alice_score : String := format_example "Alice" 95
-- "Alice: 95 分"

-- 更复杂的格式化
def format_table_header : String :=
  s!"| {"姓名".pushn ' ' 10} | {"分数".pushn ' ' 5} |"

def format_row (name : String) (score : Nat) : String :=
  s!"| {name.pushn ' ' 10} | {toString score |>.pushn ' ' 5} |"

def table : String :=
  format_table_header ++ "\n" ++
  format_row "Alice" 95 ++ "\n" ++
  format_row "Bob" 87

end Lean4Tutorial.Examples.Basics.Strings
