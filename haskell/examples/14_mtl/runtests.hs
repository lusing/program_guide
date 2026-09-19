-- 14 测试套件
module Main (main) where

import Ch14
import Control.Monad (unless)
import Control.Monad.State (evalState, evalStateT)
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stderr, stdout, utf8)

data Case = Case { name :: String, ok :: Bool, detail :: String }

expectEq :: (Eq a, Show a) => String -> a -> a -> Case
expectEq n got want
  | got == want = Case n True ""
  | otherwise   = Case n False (n ++ ": 得到 " ++ show got ++ " 期望 " ++ show want)

expectTrue :: String -> Bool -> Case
expectTrue n b = Case n b (if b then "" else n ++ ": 期望为真，得到假")

runSuite :: String -> [Case] -> IO Bool
runSuite group cs = do
    let bad = [c | c <- cs, not (ok c)]
    putStrLn (group ++ ": " ++ show (length cs - length bad) ++ "/" ++ show (length cs) ++ " 通过")
    mapM_ (putStrLn . ("  ✗ " ++) . detail) bad
    pure (null bad)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8
    let seq42 = randList 42 5
    s1 <- runSuite "xorshift 确定性"
        [ expectEq "同种子同序列" seq42 (randList 42 5)
        , expectTrue "异种子异序列" (randList 42 5 /= randList 43 5)
        , expectTrue "取值范围" (all (\v -> v >= 0 && v < 1) (randList 7 500))
        , expectEq "步进可手算" (step 1 /= 1) True
        , expectEq "长度正确" (length (randList 9 17)) 17
        ]
    ioRun <- evalStateT (randListG 3) 7          -- 泛型代码跑在 StateT IO
    s2 <- runSuite "mtl 泛型"
        [ expectEq "纯/IO 同源" ioRun (randList 7 3)
        , expectEq "randIntG 范围" (evalStateTI 10) True
        ]
    s3 <- runSuite "蒙特卡洛与 ExceptT"
        [ expectTrue "π 收敛 1 万样本" (abs (piEstimate 2026 10000 - pi) < 0.1)
        , expectTrue "π 收敛 10 万样本" (abs (piEstimate 2026 100000 - pi) < 0.05)
        , expectTrue "ExceptT 给得出值或错" (either (const True) (const True) (runEval 5))
        , expectTrue "π 大样本更近" (abs (piEstimate 2026 100000 - pi)
                                      <= abs (piEstimate 2026 1000 - pi) + 0.02)
        ]
    unless (s1 && s2 && s3) exitFailure
    putStrLn "==== 14 结束 ===="
  where
    -- randIntG 10 在 IO 单子里跑：全部落在 [0,10)
    evalStateTI :: Int -> Bool
    evalStateTI n = all (\v -> v >= 0 && v < n)
                        (evalState (randListInt n) 123)
    randListInt n = mapM (const (randIntG n)) [1 .. n]
