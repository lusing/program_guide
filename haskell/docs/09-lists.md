# 09 · 列表与折叠 ⭐

> 对应示例：`examples/09_lists/`

## 9.1 列表是递归结构

```haskell
data [a] = [] | a : [a]        -- 列表的定义（概念版）
```

`:` 是构造子（cons）：`1 : 2 : 3 : []` 即 `[1,2,3]`。所以 06 章的列表模式就是构造子模式，
09 章的一切操作都建立在"首:尾"的递归视角上。

## 9.2 fold 三兄弟

```haskell
foldr  (+) 0 [1,2,3]   -- 1 + (2 + (3 + 0))   从右往左、惰性友好
foldl  (+) 0 [1,2,3]   -- ((0 + 1) + 2) + 3   从左往左、堆 thunk（10 章实测坑）
foldl' (+) 0 [1,2,3]   -- 严格折叠，每步强制——大列表唯一正确姿势（Data.List）
```

**foldr 的独门能力：短路**——它能把"决策函数"变成惰性的：

```haskell
andR = foldr (&&) True
andR [True, False, undefined]     -- False：undefined 根本没被碰！
```

`&&` 第二参不需求值时，右侧整段列表的折叠就停了。foldl 做不到（必须先走完全表才有结果）。

## 9.3 scanl：保留中间结果的折叠

```haskell
prefixSums = scanl (+) 0          -- [0, x1, x1+x2, …] 长度 +1
prefixSums [1,2,3]                -- [0,1,3,6]
scanl1 (+) [1,2,3]                -- [1,3,6]
```

## 9.4 无穷结构与展开

```haskell
naturals :: [Integer]
naturals = iterate (+ 1) 0        -- 无穷：0,1,2,… 取多少算多少

fibs :: [Integer]                 -- unfoldr：fold 的对偶——种子反向展开
fibs = unfoldr (\(a, b) -> Just (a, (b, a + b))) (0, 1)

take 10 fibs                      -- [0,1,1,2,3,5,8,13,21,34]
fibs !! 90                        -- 2880067194370816120
```

`iterate f x = x : iterate f (f x)`；`unfoldr` 把"状态 → (输出, 新状态)"的函数展开成流。
配合 `take/drop/zip/zipWith`，"生成器"不 needs 特殊语法。

## 9.5 列表推导

```haskell
pythagTriples :: Int -> [(Int, Int, Int)]
pythagTriples n =
    [ (x, y, z)
    | x <- [1 .. n]              -- 生成器
    , y <- [x .. n]              -- 后面的能用前面的变量
    , z <- [y .. n]
    , x * x + y * y == z * z     -- 守卫：不满足就跳过
    ]
```

## 9.6 建造塔：筛法

组合的过滤层逐层叠加——"流"思维的招牌：

```haskell
primes = sieve [2 ..]
  where
    sieve (p:rest) = p : sieve [x | x <- rest, x `mod` p /= 0]

take 10 primes                    -- [2,3,5,7,11,13,17,19,23,29]
```

（教学演示；工业级用包级素数筛，此处体会"无穷流 + 过滤组合"的思维方式。）

## 9.7 zipWith 与点积

```haskell
dot xs ys = sum (zipWith (*) xs ys)
dot [1,2,3] [4,5,6]               -- 32
zipWith (+) [1,2,3] [10]          -- [11]：zip 家族一律截到短的
zip "ab" [1,2,3]                  -- [('a',1),('b',2)]
```

## 9.8 坑位清单

1. **foldl 大列表空间泄漏**：值对、内存炸——一律 `foldl'`（Data.List）（9.2，10 章实测内存对照）。
2. **`!!` 是部分函数**（越界崩）：O(n) 且不安全——随机访问用 Vector（生态）或 Map（11 章）。
3. **++ 左嵌套 O(n²)**：循环里 `acc ++ [x]` 建大列表是经典性能坑——用 foldr 建表/DList（9.1 注）。
4. **无穷列表要"有底"**：`foldr` 配短路函数才能收尾；`foldl` 在无穷表上永挂（9.2）。
5. **defaulting 与空表**：`sum []` 是 `0`（Num 的零元）——类型定了才有"零"是什么（8 章回响）。
