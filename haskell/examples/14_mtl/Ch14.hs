-- Ch14 库模块：单子变换器与 mtl——StateT/ExceptT、MonadState 约束风格、手写纯随机
module Ch14
    ( step, unit01, rand01G, randIntG, randListG
    , piMC, randList, piEstimate
    , safeRecipAvg, runEval
    , countDown
    ) where

import Control.Monad.Except (ExceptT, runExceptT, throwError)
import Control.Monad.State
    (MonadState, State, StateT, evalState, evalStateT, get, put, modify, runStateT)
import Control.Monad.Trans.Class (lift)
import Data.Bits (shiftL, shiftR, xor)
import Data.Word (Word64)

-- ═══ 14.1 xorshift64*：三步移位异或 + 一乘法，纯函数确定性 PRNG
-- 种子相同 → 序列完全相同（测试可复现的关键）
step :: Word64 -> Word64
step x0 = x3 * 2685821657736338717
  where
    x1 = x0 `xor` (x0 `shiftR` 12)
    x2 = x1 `xor` (x1 `shiftL` 25)
    x3 = x2 `xor` (x2 `shiftR` 27)

unit01 :: Word64 -> Double                  -- 映射到 [0,1)：取高 53 位除 2^53
unit01 s = fromIntegral (s `shiftR` 11) / 2 ^ (53 :: Int)

-- ═══ 14.2 mtl 风格：只声明"需要 MonadState Word64"，不绑死具体单子
rand01G :: MonadState Word64 m => m Double
rand01G = do
    s <- get
    let s' = step s
    put s'
    pure (unit01 s')

randIntG :: MonadState Word64 m => Int -> m Int   -- [0, n)
randIntG n = do
    v <- rand01G
    pure (floor (v * fromIntegral n))

randListG :: MonadState Word64 m => Int -> m [Double]
randListG 0 = pure []
randListG n = (:) <$> rand01G <*> randListG (n - 1)

-- ═══ 14.3 蒙特卡洛 π（纯 State 版 + 泛型版各一）
piMC :: Int -> State Word64 Double
piMC n = do
    vs <- randListG (2 * n)
    let (xs, ys) = halve vs
        inside = length [() | (x, y) <- zip xs ys, x * x + y * y <= 1]
    pure (4 * fromIntegral inside / fromIntegral n)
  where
    halve zs = (evens zs, odds zs)
    evens (a:_:r) = a : evens r
    evens _       = []
    odds (_:b:r)  = b : odds r
    odds _        = []

randList :: Word64 -> Int -> [Double]        -- 直接跑：种子 → 列表
randList seed n = evalState (randListG n) seed

piEstimate :: Word64 -> Int -> Double
piEstimate seed n = evalState (piMC n) seed

-- ═══ 14.4 ExceptT 叠在 State 上：错误走左、状态照走
type Eval = ExceptT String (State Word64)

safeRecipAvg :: Eval Double                 -- 两个随机数相除；分母太小则报错
safeRecipAvg = do
    x <- rand01G                             -- MonadState 实例自动"穿透"ExceptT
    y <- rand01G
    if y < 0.1
        then throwError ("分母太小: " ++ show y)
        else pure (x / y)

runEval :: Word64 -> Either String Double
runEval seed = evalState (runExceptT safeRecipAvg) seed

-- ═══ 14.5 lift：把底层 IO 动作抬进 StateT
countDown :: Int -> StateT Int IO [String]
countDown 0 = pure []
countDown n = do
    lift (putStrLn ("tick " ++ show n))      -- IO 动作必须 lift
    modify (+ 1)                             -- 状态操作不用 lift（mtl 泛型实例）
    (:) (show n) <$> countDown (n - 1)
