-- Ch18 库模块：命令式函数式程序设计（书10）——State 回顾、ST 单子、STRef/STArray
module Ch18
    ( Seed, mkSeed, rnd
    , diceExplicit, diceState
    , fibPair, fibST
    , bsortST
    , shuffleST
    , labelsST
    ) where

import Control.Monad (forM, forM_, replicateM_, when)
import Control.Monad.ST (ST, runST)
import Control.Monad.State (State, evalState, get, put)
import Data.Array.ST (STArray, getElems, newListArray, readArray, writeArray)
import Data.STRef

-- ═══ 18.1 确定性伪随机：种子 -> (区间内值, 新种子)
-- 书 10.3 假设已有 random :: (Int,Int) -> Seed -> (Int,Seed)；这里用经典 LCG 常数实现，
-- 不追求统计性质，只要确定（可复现、可断言）。
type Seed = Int

mkSeed :: Int -> Seed
mkSeed n = n * 2654435761 + 1

rnd :: (Int, Int) -> Seed -> (Int, Seed)
rnd (lo, hi) s = (lo + abs s' `mod` (hi - lo + 1), s')
  where
    s' = (s * 1103515245 + 12345) `rem` 2147483647

-- ═══ 18.2 骰子两版（书10.3）：显式串联 vs State 单子
diceExplicit :: Int -> (Int, Int)
diceExplicit n = (x, y)
  where
    (x, s1) = rnd (1, 6) (mkSeed n)
    (y, _) = rnd (1, 6) s1

throwDie :: State Seed Int
throwDie = do
    s <- get
    let (v, s') = rnd (1, 6) s
    put s'
    pure v

diceState :: Int -> (Int, Int)
diceState n = evalState ((,) <$> throwDie <*> throwDie) (mkSeed n)

-- ═══ 18.3 fib 两版（书10.4）：纯元组递推 vs STRef 的 Python 直译
fibPair :: Int -> Integer -- 纯函数版：线性时间，但每层递归带新变量 a b
fibPair n = fst (go n)
  where
    go 0 = (0, 1)
    go k = (b, a + b)
      where
        (a, b) = go (k - 1)

fibST :: Int -> Integer -- 命令式直译版：两个程序变量，常数空间（小整数意义下）
fibST n = runST $ do
    a <- newSTRef 0
    b <- newSTRef 1
    replicateM_ n $ do
        x <- readSTRef a
        y <- readSTRef b
        writeSTRef a y
        writeSTRef b $! x + y -- $! 强制求和：否则惰性会在这里堆 thunk（书里原话）
    readSTRef a

-- newListArray 的返回类型在多态上下文里有歧义——用单态签名的小辅助钉死数组类型
mkArr :: (Int, Int) -> [e] -> ST s (STArray s Int e)
mkArr = newListArray

-- ═══ 18.4 STArray 冒泡排序（书10.5 的教学版）：原地交换
bsortST :: Ord a => [a] -> [a]
bsortST xs = runST $ do
    let n = length xs
    a <- mkArr (1, n) xs
    forM_ [n, n - 1 .. 2] $ \j -> -- 每轮把最大者冒到位置 j
        forM_ [1 .. j - 1] $ \k -> do
            u <- readArray a k
            v <- readArray a (k + 1)
            when (u > v) $ do
                writeArray a k v
                writeArray a (k + 1) u
    getElems a

-- ═══ 18.5 Fisher-Yates 洗牌（STArray + 种子线程化）：确定性可复现
shuffleST :: [a] -> Seed -> [a]
shuffleST xs seed0 = runST $ do
    let n = length xs
    a <- mkArr (1, n) xs
    let go i seed
            | i <= 1 = return ()
            | otherwise = do
                let (j, seed') = rnd (1, i) seed
                when (j /= i) $ do
                    u <- readArray a j
                    v <- readArray a i
                    writeArray a j v
                    writeArray a i u
                go (i - 1) seed'
    go n seed0
    getElems a

-- ═══ 18.6 程序变量：STRef 计数器发标签（命令式的"自增"）
labelsST :: Int -> [String]
labelsST n = runST $ do
    r <- newSTRef 0
    forM [1 .. n] $ \_ -> do
        modifySTRef' r (+ 1)
        k <- readSTRef r
        pure ("L" ++ show k)
