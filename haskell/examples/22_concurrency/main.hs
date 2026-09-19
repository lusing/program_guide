-- 22 并发：forkIO/MVar/Chan、IORef 竞争、STM 与 retry（-threaded -N4 运行）
-- 运行：ghc -threaded -rtsopts "-with-rtsopts=-N4" -o 22.exe main.hs && ./22.exe
module Main (main) where

import Ch22
import Control.Concurrent (forkIO, threadDelay)
import Data.List (sort)
import Control.Concurrent.STM (atomically, newTVarIO, readTVarIO, writeTVar)
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    -- ═══ 22.1 转账纯核心
    putStrLn "==[ 22 · 并发 ]=="
    let a = Acct "甲" 100
        b = Acct "乙" 30
    putStrLn ("转账 40： " ++ show (applyTransfer a b 40))
    putStrLn ("超额转账：" ++ show (applyTransfer a b 999))

    -- ═══ 22.2 forkIO + MVar 汇合
    squares <- spawnJoin 8
    putStrLn ("8 线程各算平方 = " ++ show squares)

    -- ═══ 22.3 三级流水线
    piped <- chanPipeline [1 .. 5]
    putStrLn ("流水线 [1..5] ×2 = " ++ show piped)

    -- ═══ 22.4 竞争：非原子丢更新（-N4 下大概率 <2000），原子版恒等 2000
    (lost, exact) <- raceCounters 2000
    putStrLn ("非原子 2000 次 +1 → " ++ show lost ++ "（丢了 " ++ show (2000 - lost) ++ " 次更新）")
    putStrLn ("原子版 2000 次 +1 → " ++ show exact)

    -- ═══ 22.5 STM 转账与 retry 等待
    va <- newTVarIO 100
    vb <- newTVarIO 0
    ok1 <- stmTransferIO va vb 70
    ok2 <- stmTransferIO va vb 70        -- 余额只剩 30：拒绝
    x1 <- readTVarIO va
    x2 <- readTVarIO vb
    putStrLn ("STM 转账：第一次=" ++ show ok1 ++ " 第二次(超额)=" ++ show ok2
              ++ "，余额 " ++ show x1 ++ " / " ++ show x2)
    -- retry：等外部线程入账到正数
    vwait <- newTVarIO 0
    _ <- forkIO (threadDelay 50000 >> atomically (writeTVar vwait 9))
    waitForPositive vwait
    finalW <- readTVarIO vwait
    putStrLn ("retry 等到入账 → " ++ show finalW)

    -- ═══ 22.6 threadDelay 单位是微秒
    putStrLn ("threadDelay 100000 = 0.1 秒（微秒坑见正文）")

    -- ═══ 22.7 自检
    check "转账守恒" (maybe 0 totalOf (fmap (\(x, y) -> [x, y]) (applyTransfer a b 40))) 130
    check "超额拒绝" (applyTransfer a b 999) Nothing
    check "MVar 全收" (sort squares) [1, 4, 9, 16, 25, 36, 49, 64]
    check "流水线保序" piped [2, 4 .. 10]
    check "非原子不超发" (lost <= 2000) True
    check "原子恰好" exact 2000
    check "STM 两次后总额" (x1 + x2) 100
    check "retry 醒来" (finalW > 0) True

    putStrLn "==== 22 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
