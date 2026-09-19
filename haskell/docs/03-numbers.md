# 03 · 数值与类型类入门

> 对应示例：`examples/03_numbers/`

## 3.1 数值类型一览

| 类型 | 说明 | 坑 |
|---|---|---|
| `Int` | 定长整数（64 位） | `21!` 就溢出变负（实测） |
| `Integer` | 任意精度整数 | 慢一点但永不溢出，默认整数字面量就是它 |
| `Word` | 无符号整数 | 与 C 互操作常见（23 章） |
| `Double` / `Float` | 浮点 | `0.1 + 0.2 == 0.30000000000000004`（IEEE-754，与所有语言一致） |
| `Rational` | 精确分数 | `1 % 3 + 1 % 6 == 1 % 2`，零误差 |

```haskell
maxBound :: Int          -- 9223372036854775807
factInt 20               -- 2432902008176640000（尚在界内）
factInt 21               -- -4249290049419214848（溢出！）
factInteger 21           -- 51090942171709440000（无界）
```

## 3.2 数值的类型类层次

数值运算不绑定具体类型，而是挂在类型类上（08 章细讲类型类）：

```
Num                 -- + - * ：Int/Integer/Double/…
├── Fractional      -- / ：Double/Rational
│     └── Floating  -- sqrt/sin/exp …
└── Integral        -- div/mod/quot/rem：Int/Integer
```

推论：

- `1 / 2` 合法（默认 Double → 0.5）；`1 `div` 2` 才是整数除（得 0）。
- `length xs / 2` **编译不过**——`length` 给 `Int`，`/` 要 `Fractional`。必须
  `fromIntegral (length xs) / 2`。

```haskell
-- fromIntegral 是 Int/Integer 与数值世界之间的桥
count :: [a] -> Double
count xs = fromIntegral (length xs)
```

## 3.3 整除家族四兄弟

`div/mod` 向下取整（余数符号随**除数**）；`quot/rem` 向零取整（余数符号随**被除数**，C 系语言语义）：

```haskell
divMod  (-7) 2    -- (-4, 1)     向下：-7 = 2×(-4) + 1
quotRem (-7) 2    -- (-3, -1)    向零：-7 = 2×(-3) + (-1)
```

正数时两家一致——坑只在负数。教学建议：数学语义用 `div/mod`，FFI 对接 C 用 `quot/rem`。

## 3.4 字面量多态与 defaulting

```haskell
5     :: Num a => a          -- 用在哪类上下文就是哪个类型
5.0   :: Fractional a => a
```

无约束时触发 defaulting 规则：整数默认 `Integer`、小数默认 `Double`（GHCi 里 `:set -XNoMonomorphismRestriction`
一瞥即可，正文不展开）：

```haskell
doubleIt :: Num a => a -> a
doubleIt x = x + x
doubleIt (21 :: Int)         -- 42
doubleIt (2.5 :: Double)     -- 5.0
doubleIt (10^25 :: Integer)  -- 大数照算
```

## 3.5 read 与 readMaybe

`read :: Read a => String -> a` 是**部分函数**——解析失败直接崩：

```haskell
read "42" :: Int        -- 42
read "4x" :: Int        -- 运行时异常！
```

安全版在 `Text.Read`：

```haskell
readMaybe "42" :: Maybe Int    -- Just 42
readMaybe "4x" :: Maybe Int    -- Nothing
```

规则：**边界输入一律 readMaybe**（文件/网络/用户），内部已验证数据才允许 read。

## 3.6 Rational：精确分数

```haskell
import Data.Ratio ((%))

third = 1 % 3 :: Rational
third + 1 % 6                -- 1 % 2（精确）
0.1 + 0.2 :: Double          -- 0.30000000000000004（对照）
```

测试断言浮点别用 `==`（要么 `Rational`，要么误差带）——21 章性质测试也遵守。

## 3.7 坑位清单

1. **`factInt 21` 溢出为负**：阶乘类演示用 `Integer`；`Int` 边界意识常在（3.1）。
2. **`/` 与 `div` 分家**：整数除法写 `` `div` ``；`length` 参与 `/` 前必须 `fromIntegral`（3.2）。
3. **负数整除两家分道**：`divMod` vs `quotRem`——对接 C 用后者（3.3）。
4. **read 是部分函数**：外部输入用 `readMaybe`（3.5）。
5. **浮点相等**：`==` 对 Double 是逐位比较；测试用 Rational 或误差断言（3.6）。
