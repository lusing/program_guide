-- Ch09 库模块：列表与折叠——递归结构、fold 家族、scan、unfoldr、推导式、建造塔
--                + 书4 增补：span/countRuns/msort/merge/nondec/position/triads/commonWords
module Ch09
    ( mySumR, mySumL, mySumL', andR
    , prefixSums, fibs, naturals
    , pythagTriples
    , firstPrimes
    , dot
    , mySpan, countRuns
    , msort, merge
    , nondec, position
    , disjoint, coprime, triads
    , commonWords
    ) where

import Data.Char (toLower)
import Data.List (foldl', unfoldr)

-- ═══ 09.1 fold 家族：foldr 从右（惰性友好）、foldl 从左（惰性陷阱）、foldl' 严格
mySumR, mySumL, mySumL' :: [Int] -> Int
mySumR  = foldr (+) 0        -- (x1 + (x2 + … + 0))
mySumL  = foldl (+) 0        -- ((((0 + x1) + x2) + … )——堆 thunk（12 章实测）
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

-- ═══ 09.7 书4.8：span——最长满足 p 的前缀与余下一分为二（countRuns 的钥匙）
mySpan :: (a -> Bool) -> [a] -> ([a], [a])
mySpan _ [] = ([], [])
mySpan p (x:xs)
    | p x = let (ys, zs) = mySpan p xs in (x : ys, zs)
    | otherwise = ([], x : xs)

countRuns :: Eq a => [a] -> [(Int, a)]
countRuns [] = []
countRuns (w:ws) = (1 + length us, w) : countRuns vs
  where
    (us, vs) = mySpan (== w) ws

-- ═══ 09.8 书4.8：归并排序——分治 + merge；msort [x] 方程不能省（1 div 2 = 0 死循环）
msort :: Ord a => [a] -> [a]
msort [] = []
msort [x] = [x]
msort xs = merge (msort ys) (msort zs)
  where
    n = length xs `div` 2
    (ys, zs) = (take n xs, drop n xs)

merge :: Ord a => [a] -> [a] -> [a]
merge [] ys = ys
merge xs [] = xs
merge (x:xs) (y:ys)
    | x <= y = x : merge xs (y:ys)
    | otherwise = y : merge (x:xs) ys

-- ═══ 09.9 书4.7：zipWith 判非递减；惰性让"算全部位置取第一个"没有代价
nondec :: Ord a => [a] -> Bool
nondec xs = and (zipWith (<=) xs (drop 1 xs))

position :: Eq a => a -> [a] -> Int
position x xs = firstOf ([j | (j, y) <- zip [0 ..] xs, y == x] ++ [-1])
  where
    firstOf = foldr (\h _ -> h) (-1) -- 全函数版 head

-- ═══ 09.10 书4.3：递增两表的公共元素判定 + 互素 + 改进版勾股三元组
disjoint :: Ord a => [a] -> [a] -> Bool
disjoint [] _ = True
disjoint _ [] = True
disjoint xs'@(x:xs) ys'@(y:ys)
    | x < y = disjoint xs ys' -- 谁小谁前进（双指针）
    | x > y = disjoint xs' ys
    | otherwise = False -- 相等：有公共元素

coprime :: Int -> Int -> Bool
coprime x y = disjoint (divisors x) (divisors y)
  where
    divisors n = [d | d <- [2 .. n - 1], n `mod` d == 0]

triads :: Int -> [(Int, Int, Int)]
triads n =
    [ (x, y, z)
    | x <- [1 .. m]
    , y <- [x + 1 .. n]
    , coprime x y
    , z <- [y + 1 .. n]
    , x * x + y * y == z * z
    ]
  where
    m = floor (fromIntegral n / sqrt 2) -- Int 不能直接 /：fromIntegral 过桥

-- ═══ 09.11 书4.8：高频词完整解——span/merge 排版全部手写，01 章管线落地
commonWords :: Int -> String -> String
commonWords n = concat . map showRun . take n . sortRuns . countRuns
    . sortWords . words . map toLower
  where
    sortWords = msort
    sortRuns = reverse . msort -- 元组字典序递增 → 逆序即按次数递减
    showRun (k, w) = w ++ ": " ++ show k ++ "\n"
