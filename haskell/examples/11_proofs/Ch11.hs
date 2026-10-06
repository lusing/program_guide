-- Ch11 库模块：证明与归纳（书6）——定律族 + 程序计算成果的机器对账
-- 手算推导在 docs/11-proofs.md；本模块把"计算出的等价定义"放到确定性样本上互证。
module Ch11
    ( double
    -- ① 基本定律族（书4/6 精选，随机样本全部成立）
    , propAppendAssoc, propReverseTwice, propSumAppend
    , propMapFusion, propMapReverseCommute
    , propFilterMapLaw
    -- ② foldr 融合律的两个经典推论
    , propDoubleSumFusion, propLengthConcatFusion
    -- ③ scanl：二次方规格与线性实现等值（书6.5 的程序计算成果）
    , scanlSpec, propScanlSpecEqLinear
    -- ④ 最大连续段和（书6.6）：三次方规格与线性解等值
    , segments, mssSpec, mssLinear
    -- ⑤ Float 反例：算术结合律在 Float 实例上失效（书6.1）
    , floatAssocL, floatAssocR
    -- ⑥ 样本生成：确定性整数列表族（含空/单/负数/递增）
    , samples
    ) where

import Data.List (inits, tails)

double :: Int -> Int
double x = 2 * x

-- ═══ ① 基本定律：两侧同值即成立（证明见 docs；机器只负责抽查）
propAppendAssoc :: (Eq a, Show a) => [a] -> [a] -> [a] -> Bool
propAppendAssoc xs ys zs = (xs ++ ys) ++ zs == xs ++ (ys ++ zs)

propReverseTwice :: Eq a => [a] -> Bool
propReverseTwice xs = reverse (reverse xs) == xs

propSumAppend :: [Int] -> [Int] -> Bool
propSumAppend xs ys = sum (xs ++ ys) == sum xs + sum ys

propMapFusion :: (Eq b, Show b) => (Int -> a) -> (a -> b) -> [Int] -> Bool
propMapFusion g f xs = map (f . g) xs == (map f . map g) xs

propMapReverseCommute :: (Eq a, Show a) => (Int -> a) -> [Int] -> Bool
propMapReverseCommute f xs = (map f . reverse) xs == (reverse . map f) xs

propFilterMapLaw :: (Int -> Bool) -> (Int -> Int) -> [Int] -> Bool
propFilterMapLaw p f xs = (filter p . map f) xs == (map f . filter (p . f)) xs

-- ═══ ② 融合律推论：f . foldr g a = foldr h b 的特例（书6.3）
propDoubleSumFusion :: [Int] -> Bool
propDoubleSumFusion xs = double (sum xs) == foldr ((+) . double) 0 xs
-- double . sum = foldr ((+).double) 0：两趟并一趟

-- 融合律推论二：length . concat = foldr addLen 0（各内层长度之和；书 6.3 的
-- length . concat = sum . map length 同一定律，addLen ys n = length ys + n）
propLengthConcatFusion :: [[a]] -> Bool
propLengthConcatFusion xss = length (concat xss) == foldr addLen 0 xss
  where
    addLen ys n = length ys + n

-- ═══ ③ scanl（书6.5）：规格（对每个前缀折叠）与线性递归定义等值
scanlSpec :: (b -> a -> b) -> b -> [a] -> [b]
scanlSpec f e = map (foldl f e) . inits -- O(n²)：第 i 个前缀从零算起

propScanlSpecEqLinear :: (Eq b, Show b) => (b -> Int -> b) -> b -> [Int] -> Bool
propScanlSpecEqLinear f e xs = scanlSpec f e xs == scanl f e xs

-- ═══ ④ 最大连续段和（书6.6）：n³ 规格 → 线性解，两侧对账
segments :: [a] -> [[a]]
segments = concat . map inits . tails

mssSpec :: [Int] -> Int -- maximum . map sum . segments：所有段的和取最大
mssSpec = maximum . map sum . segments

mssLinear :: [Int] -> Int -- maximum . scanr step 0：线性（程序计算的成果）
mssLinear = maximum . scanr step 0
  where
    step x y = 0 `max` (x + y) -- (+) 对 max 可分配：x+(y`max`z)=(x+y)`max`(x+z) 的镜像

-- ═══ ⑤ Float 反例（书6.1）：(x*y)*z ≠ x*(y*z)
floatAssocL, floatAssocR :: Float
floatAssocL = (9.9e10 * 0.5e-10) * 0.1e-10
floatAssocR = 9.9e10 * (0.5e-10 * 0.1e-10)

-- ═══ ⑥ 确定性样本族：定律断言全在这里跑
samples :: [[Int]]
samples =
    [ []
    , [5]
    , [1 .. 10]
    , [-1, 2, -3, 5, -2, 1, 3, -2, -2, -3, 6] -- 书中 mss 例子，最大段和 7
    , [-1, -2, -3] -- 全负：最大段和 0（空段）
    , [3, 1, 4, 1, 5, 9, 2, 6]
    ]
