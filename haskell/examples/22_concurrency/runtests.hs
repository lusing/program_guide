-- 22 测试套件（-threaded -N4 编译；断言只断不变式，竞争演示断"非原子≤n、原子=n"）
module Main (main) where

import Ch22
import Control.Concurrent (forkIO, threadDelay)
import Control.Concurrent.STM (atomically, newTVarIO, readTVarIO, writeTVar)
import Control.Monad (unless)
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
    let a = Acct "甲" 100
        b = Acct "乙" 30
    s1 <- runSuite "转账纯核心"
        [ expectEq "正常转账" (applyTransfer a b 40)
                      (Just (Acct "甲" 60, Acct "乙" 70))
        , expectEq "总额守恒" (maybe 0 totalOf (fmap (\(x, y) -> [x, y]) (applyTransfer a b 40))) 130
        , expectEq "超额拒绝" (applyTransfer a b 999) Nothing
        , expectEq "零额拒绝" (applyTransfer a b 0) Nothing
        , expectEq "负额拒绝" (applyTransfer a b (-5)) Nothing
        ]
    squares <- spawnJoin 5
    piped <- chanPipeline [1 .. 6]
    (lost, exact) <- raceCounters 1500
    s2 <- runSuite "线程与流水线"
        [ expectEq "MVar 收齐" (sum squares) (sum [1, 4, 9, 16, 25])
        , expectEq "数量对" (length squares) 5
        , expectEq "流水线结果" piped [2, 4 .. 12]
        , expectEq "流水线保序" piped (map (* 2) [1 .. 6])
        ]
    -- STM 三连
    va <- newTVarIO 100
    vb <- newTVarIO 0
    ok1 <- stmTransferIO va vb 70
    ok2 <- stmTransferIO va vb 70
    x1 <- readTVarIO va
    x2 <- readTVarIO vb
    vwait <- newTVarIO 0
    _ <- forkIO (threadDelay 30000 >> atomically (writeTVar vwait 5))
    waitForPositive vwait
    finalW <- readTVarIO vwait
    s3 <- runSuite "竞争与 STM"
        [ expectTrue "非原子不超发" (lost <= 1500)
        , expectEq "原子恰好" exact 1500
        , expectEq "STM 首次成功" ok1 True
        , expectEq "STM 超额拒绝" ok2 False
        , expectEq "STM 总额守恒" (x1 + x2) 100
        , expectTrue "retry 等到入账" (finalW > 0)
        ]
    unless (s1 && s2 && s3) exitFailure
    putStrLn "==== 22 结束 ===="
