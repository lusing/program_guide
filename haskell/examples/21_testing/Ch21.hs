-- Ch21 库模块：测试——自制迷你属性测试（生成器 + 收缩 + 定种子复现）
module Ch21
    ( Gen, Generate(..)
    , shrinkInt, shrinkList
    , runProperty
    , sampleInts
    , propSortIdempotent, propAbsNonNeg, propReverseTwice, propTextRoundtrip
    ) where

import Control.Monad.State (State, evalState, get, put)
import Data.Bits (shiftL, shiftR, xor)
import Data.Char (chr, ord)
import Data.List (sort)
import Data.Word (Word64)
import qualified Data.Text as T

-- ═══ 21.1 生成器：xorshift64* 确定性随机（与 14 章同款；种子定 → 序列定）
step :: Word64 -> Word64
step x0 = x3 * 2685821657736338717
  where
    x1 = x0 `xor` (x0 `shiftR` 12)
    x2 = x1 `xor` (x1 `shiftL` 25)
    x3 = x2 `xor` (x2 `shiftR` 27)

unit01 :: Word64 -> Double
unit01 s = fromIntegral (s `shiftR` 11) / 2 ^ (53 :: Int)

type Gen a = State Word64 a

rand01 :: Gen Double
rand01 = do
    s <- get
    let s' = step s
    put s'
    pure (unit01 s')

randIn :: Int -> Gen Int                -- [0, n)
randIn n = floor . (* fromIntegral n) <$> rand01

class Generate a where
    generate :: Gen a

instance Generate Bool where
    generate = (< 0.5) <$> rand01

instance Generate Int where
    generate = (\v -> v * 2 - 100) <$> randIn 101      -- v∈[0,100] 映到 [-100,100]

instance Generate Double where
    generate = (\v -> v * 200 - 100) <$> rand01        -- [-100, 100)

instance Generate Char where
    generate = (\n -> chr (ord 'a' + n)) <$> randIn 26  -- 'a'..'z'

instance Generate a => Generate [a] where
    generate = randIn 9 >>= \n -> mapM (const generate) [1 .. n]

sampleInts :: Word64 -> [Int]
sampleInts seed = evalState (mapM (const generate) [1 .. 8 :: Int]) seed

-- ═══ 21.2 收缩：反例最小化（往"更小"的方向找仍失败的邻居）
shrinkInt :: Int -> [Int]
shrinkInt n = if n == 0 then [] else [n `div` 2, 0]

shrinkList :: [a] -> [[a]]
shrinkList xs =
    [ take k xs | k <- [length xs `div` 2, length xs - 1], k > 0, k < length xs ]

-- ═══ 21.3 属性运行器：count 个样本；失败则收缩到最小反例
-- Nothing = 全部通过；Just x = 收缩后的最小反例
runProperty :: Int -> Word64 -> Gen a -> (a -> [a]) -> (a -> Bool) -> Maybe a
runProperty count seed gen shrs prop =
    case filter (not . prop) samples of
        []    -> Nothing
        (x:_) -> Just (shrinkLoop x)
  where
    samples = [evalState gen (seed + fromIntegral i) | i <- [1 .. fromIntegral count]]
    shrinkLoop x = case filter (not . prop) (shrs x) of
        (y:_) -> shrinkLoop y
        []    -> x

-- ═══ 21.4 内置属性：经典不变式
propSortIdempotent :: [Int] -> Bool
propSortIdempotent xs = sort (sort xs) == sort xs

propAbsNonNeg :: Int -> Bool
propAbsNonNeg x = abs x >= 0

propReverseTwice :: [Int] -> Bool
propReverseTwice xs = reverse (reverse xs) == xs

propTextRoundtrip :: String -> Bool
propTextRoundtrip s = T.unpack (T.pack s) == s
