# 06 · 模式匹配 ⭐

> 对应示例：`examples/06_patterns/`

## 6.1 按结构分派

模式匹配是 Haskell 的"分支语句"——不比布尔条件，比**数据的形状**。函数定义写多个等式，
自上而下首个匹配者胜：

```haskell
describe :: [Int] -> String
describe []        = "空"
describe [x]       = "单元素 " ++ show x
describe [x, y]    = "两个 " ++ show x ++ "," ++ show y
describe (x:_:z:_) = "至少三个，首尾 " ++ show x ++ "," ++ show z
```

`(x:_:z:_)`：首元素、跳过一位、第三元素、剩余不管。`_` 是"不关心"。

## 6.2 部分函数的安全化

`head`/`tail` 对空表直接崩。模式匹配逼你处理空表分支：

```haskell
safeHead :: [a] -> Maybe a
safeHead []    = Nothing
safeHead (x:_) = Just x
```

**GHC 9.12 实测坑**：`head`/`last`/`tail`/`init` 默认触发 `-Wx-partial` 警告（不用开 -Wall）。
本教程全量清扫为模式匹配/`foldr`/`drop 1` 等全函数写法（21 章讲为什么部分函数是设计气味）。

## 6.3 元组与字面量模式

```haskell
sumPairs :: [(Int, Int)] -> [Int]
sumPairs = map (\(a, b) -> a + b)        -- lambda 参数位直接解构

swapPair :: (a, b) -> (b, a)
swapPair (a, b) = (b, a)

isVowel :: Char -> Bool                  -- 字面量模式按值分派
isVowel 'a' = True
isVowel 'e' = True
isVowel 'i' = True
isVowel 'o' = True
isVowel 'u' = True
isVowel _   = False                      -- _ 兜底
```

## 6.4 @ 绑定：整体与部件兼得

```haskell
firstAndRest :: [Int] -> (Int, [Int], Int)
firstAndRest whole@(x:_) = (x, whole, length whole)   -- whole 复用原值，零拷贝
firstAndRest []          = (0, [], 0)
```

## 6.5 模式 + guard 共存

先按结构分派，再在分支内按条件细分：

```haskell
categorize :: [Int] -> String
categorize (x:_)
  | x > 0     = "首元素为正"
  | x < 0     = "首元素为负"
  | otherwise = "首元素为零"
categorize [] = "没有首元素"
```

## 6.6 视图模式（-XViewPatterns）

先对参数应用函数，再对**结果**做匹配——"以计算后的形状分派"：

```haskell
{-# LANGUAGE ViewPatterns #-}

readInt :: String -> Maybe Int
readInt (reads -> [(n, "")]) = Just n     -- reads " 42" == [(42,"")]
readInt _                    = Nothing    -- 读尽才算数：丢弃 "4x"
```

`reads` 返回 `[(值, 剩余串)]`；恰好读尽（剩余空串）才是完整整数。这比"read + try"优雅得多。

## 6.7 惰性模式 `~`

`~(x:_)` 匹配时**必成功**（不强制参数），取 `x` 时才崩——错误被推迟到使用处：

```haskell
lazyHead :: [a] -> a
lazyHead ~(x:_) = x
```

主要用途：解构"保证稍后才有"的数据（如自引用元组）。日常代码少用——它把"立即暴露的 bug"
变成"远处莫名的崩"。

## 6.8 坑位清单

1. **head/last/tail/init 默认警告**（9.12 的 -Wx-partial）：换模式匹配或全函数等价物（6.2）。
2. **分支顺序即优先级**：上面的等式会遮蔽下面的——字面量分支放通配分支前（6.1、6.3）。
3. **非穷尽模式**：默认无警告（-Wall 才有），漏网输入运行时异常——用 `case` + 兜底（4.4 对照）。
4. **视图模式需扩展**：`{-# LANGUAGE ViewPatterns #-}`，默认不开（6.6）。
5. **`~` 掩盖错误**：只用于"确定会有数据"的场景，别拿它绕过空表检查（6.7）。
