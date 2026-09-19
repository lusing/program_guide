-- 14 单子变换器与 mtl：MonadState 泛型、ExceptT、lift、手写 xorshift 纯随机
-- 运行：ghc -v0 --make main.hs -o 14.exe && ./14.exe
module Main (main) where

import Ch14
import Control.Monad.State (evalStateT, runStateT)
import System.IO (hSetEncoding, stderr, stdout, utf8)

-- 同一段泛型代码 randListG 在 StateT Word64 IO 里跑（与纯 State 版对照）
evalStateTIO :: IO [Double]
evalStateTIO = evalStateT (randListG 3) 7

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    -- ═══ 14.1 确定性：同种子同序列
    putStrLn "==[ 14 · 单子变换器与 mtl ]=="
    putStrLn ("randList 42 5  = " ++ show (randList 42 5))
    putStrLn ("randList 42 5 再来一次 = " ++ show (randList 42 5))   -- 完全一样！
    putStrLn ("randList 43 5  = " ++ show (randList 43 5))           -- 换种子就变

    -- ═══ 14.2 同一段泛型代码，两种单子里跑出同样的数
    putStrLn ("纯跑（State Identity）= " ++ show (randList 7 3))
    ioThree <- evalStateTIO
    putStrLn ("IO 跑（StateT IO）     = " ++ show ioThree)


    -- ═══ 14.3 蒙特卡洛 π：5 万样本（确定性种子）
    putStrLn ("pi ≈ " ++ show (piEstimate 2026 50000))

    -- ═══ 14.4 ExceptT：错误短路，状态保留
    putStrLn ("runEval 42   = " ++ show (runEval 42))
    putStrLn ("runEval 1    = " ++ show (runEval 1))

    -- ═══ 14.5 lift：IO 抬进 StateT
    (logs, total) <- runStateT (countDown 3) 0    -- runStateT 给 (结果, 终态)；execStateT 只给终态
    putStrLn ("countDown 产出 " ++ show (length logs) ++ " 条，状态累计 " ++ show total)

    -- ═══ 14.6 自检
    check "确定性" (randList 42 5 == randList 42 5) True
    check "种子敏感" (randList 42 5 /= randList 43 5) True
    check "取值范围" (all (\v -> v >= 0 && v < 1) (randList 99 100)) True
    check "纯/IO 同源" ioThree (randList 7 3)
    check "π 收敛带" (abs (piEstimate 2026 50000 - pi) < 0.05) True
    check "ExceptT 二值" (either (const False) (const True) (runEval 42)) True
    check "countDown 计数" (length logs) 3
    check "countDown 状态" total 3

    putStrLn "==== 14 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
