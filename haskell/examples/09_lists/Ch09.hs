-- Ch09 库模块：列表与折叠——递归结构、fold 家族、scan、unfoldr、推导式、建造塔
module Ch09
    ( mySumR, mySumL, mySumL', andR
    , prefixSums, fibs, naturals
    , pythagTriples
    , firstPrimes
    , dot
    ) where

import Data.List (foldl', unfoldr)

-- ═══ 09.1 fold 家族：foldr 从右（惰性友好）、foldl 从左（惰性陷阱）、foldl' 严格
mySumR, mySumL, mySumL' :: [Int] -> Int
mySumR  = foldr (+) 0        -- (x1 + (x2 + … + 0))
mySumL  = foldl (+) 0        -- ((((0 + x1) + x2) + … )——堆 thunk（10 章实测）
mySumL' = foldl' (+) 0       -- 每步强制求值——大列表唯一正确姿势

-- foldr 的独门能力：短路（foldl 做不到，它必须走完全表）
andR :: [Bool] -> Bool
andR = foldr (&&) True       -- 遇 False 右侧整段不再求值

-- ═══ 09.2 scanl：保留每步中间结果的折叠（前缀和）
prefixSums :: Num a => [a] -> [a]
prefixSums = scanl (+) 0     -- [0, x1, x1+x2, …]，长度 +1

-- ═══ 09.3 unfoldr：从种子反向展开成列表（fold 的对偶）
fibs :: [Integer]
fibs = unfoldr (\(a, b) -> Just (a, (b, a + b))) (0, 1)   -- 无穷流，取多少算多少

naturals :: [Integer]
naturals = iterate (+ 1) 0

-- ═══ 09.4 列表推导：生成器 + 守卫 + 三元组枚举
pythagTriples :: Int -> [(Int, Int, Int)]
pythagTriples n =
    [ (x, y, z)
    | x <- [1 .. n]
    , y <- [x .. n]                  -- 后生成器可用前生成器的变量
    , z <- [y .. n]
    , x * x + y * y == z * z         -- 守卫：不满足就跳过
    ]

-- ═══ 09.5 建造塔：筛法——无穷输入流过组合的过滤层
firstPrimes :: Int -> [Int]
firstPrimes n = take n (sieve [2 ..])
  where
    sieve (p:rest) = p : sieve [x | x <- rest, x `mod` p /= 0]

-- ═══ 09.6 zipWith：两列表逐位配对（点积）
dot :: [Double] -> [Double] -> Double
dot xs ys = sum (zipWith (*) xs ys)
