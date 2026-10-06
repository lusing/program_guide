-- Ch13 库模块：无穷列表（书9）——循环结构、素数筛、approx 方法、石头剪刀布
module Ch13
    ( myCycle, repeat1, repeat2
    , iterate1, iterate2, iterate3
    , fibs
    , minus, merge, xmerge, mergeAll, primes
    , approx
    -- 石头剪刀布（书9.4）
    , Move (..), beats, Round, score
    , Strategy, copy, smart, cheat, devious
    , rounds, match
    ) where

-- ═══ 13.1 循环列表：定义里打一个结（书9.2）
myCycle :: [a] -> [a]
myCycle xs = ys where ys = xs ++ ys -- ys 在自己的定义里被共享：一个结，O(1) 每步

repeat1 :: a -> [a] -- 不打结：每步重新构造（对照版）
repeat1 x = x : repeat1 x

repeat2 :: a -> [a] -- 打结：尾指针共享（书里实测快 ~27 倍）
repeat2 x = xs where xs = x : xs

-- ═══ 13.2 iterate 三定义（书9.2）：三个都正确，代价天差地别
iterate1 :: (a -> a) -> a -> [a] -- 库版：线性，但不共享
iterate1 f x = x : iterate1 f (f x)

iterate2 :: (a -> a) -> a -> [a] -- 循环 + map 共享：线性（推荐姿势）
iterate2 f x = xs where xs = x : map f xs

iterate3 :: (a -> a) -> a -> [a] -- 不打结的 map：二次方（反面教材）
iterate3 f x = x : map f (iterate3 f x)

-- ═══ 13.3 fibs：循环结构上的 zipWith（打结的直接受益者）
fibs :: [Integer]
fibs = 0 : 1 : zipWith (+) fibs (drop 1 fibs)

-- ═══ 13.4 素数的循环筛（书9.2 最终版）：
-- primes 的定义用到 composites，composites 又用 primes——靠"显式给出第一个素数"破循环
minus :: Ord a => [a] -> [a] -> [a] -- 从严格递增列表里减去严格递增列表
minus (x : xs) (y : ys)
    | x < y = x : minus xs (y : ys)
    | x == y = minus xs ys
    | otherwise = minus (x : xs) ys
minus xs _ = xs

merge :: Ord a => [a] -> [a] -> [a] -- 归并去重（两个严格递增列表）
merge (x : xs) (y : ys)
    | x < y = x : merge xs (y : ys)
    | x == y = x : merge xs ys
    | otherwise = y : merge (x : xs) ys
merge xs ys = if null xs then ys else xs

xmerge :: Ord a => [a] -> [a] -> [a] -- 无穷列表友好：先吐左边首元素再看右边
xmerge (x : xs) ys = x : merge xs ys
xmerge [] ys = ys

mergeAll :: Ord a => [[a]] -> [a] -- 不能用 foldr1 xmerge：foldr1 对 x:⊥ 给 ⊥（书9.2 的坑）
mergeAll (xs : xss) = xmerge xs (mergeAll xss)
mergeAll [] = []

primes :: [Integer]
primes = 2 : ([3 ..] `minus` composites)
  where
    composites = mergeAll [map (p *) [p ..] | p <- primes]

-- ═══ 13.5 approx：取无穷列表的第 n 个"近似"（书9.3 证明方法的载体）
approx :: Int -> [a] -> [a]
approx n _ | n <= 0 = undefined -- 0 号近似 = ⊥：什么都不知道
approx n (x : xs) = x : approx (n - 1) xs
approx _ [] = undefined

-- ═══ 13.6 石头剪刀布（书9.4）：策略 = 无穷流 → 无穷流
data Move = Paper | Rock | Scissors deriving (Eq, Show)

beats :: Move -> Move -> Bool
beats Paper Rock = True -- 布包石头
beats Rock Scissors = True -- 石头钝剪刀
beats Scissors Paper = True -- 剪刀剪布
beats _ _ = False

type Round = (Move, Move)

score :: Round -> (Int, Int)
score (x, y)
    | x `beats` y = (1, 0)
    | y `beats` x = (0, 1)
    | otherwise = (0, 0)

type Strategy = [Move] -> [Move] -- 吃对手（潜在无穷）出手流，回自己的出手流

copy :: Strategy -- 第一手 Rock，此后复读对手上一手
copy ms = Rock : ms

-- smart：统计对手三种手势的累计次数，按确定性"随机数"落在哪个区间选克制手势
smart :: Strategy
smart ms = Rock : map pick (drop 1 (scanl (flip count) (0, 0, 0) ms))
  where
    count Paper (p, r, s) = (p + 1, r, s)
    count Rock (p, r, s) = (p, r + 1, s)
    count Scissors (p, r, s) = (p, r, s + 1)
    pick (p, r, s)
        | m < p = Scissors -- 对手布多 → 多出剪刀
        | m < p + r = Paper -- 对手石头多 → 多出布
        | otherwise = Rock
      where
        m = rand (p + r + s)
    -- 书里用 System.Random（非 boot 库）；这里用确定性整数哈希替代——对局可复现可断言
    rand n = fromIntegral ((toInteger n * 6364136223846793005 + 1442695040888963407) `mod` toInteger n)

cheat :: Strategy -- 不诚实策略：直接看对手这一手出克星
cheat ms = map trump ms
  where
    trump Paper = Scissors
    trump Rock = Paper
    trump Scissors = Rock

devious :: Int -> Strategy -- 前 n 手装老实，然后开始作弊
devious n ms = take n (copy ms) ++ cheat (drop n ms)

rounds :: (Strategy, Strategy) -> [Round] -- 两个循环列表互相定义（诚实的策略才收敛）
rounds (p1, p2) = zip xs ys
  where
    xs = p1 ys
    ys = p2 xs

match :: Int -> (Strategy, Strategy) -> (Int, Int)
match n ps = total (map score (take n (rounds ps)))
  where
    total rs = (sum (map fst rs), sum (map snd rs))
