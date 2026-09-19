-- Ch22 库模块：并发——forkIO/MVar/Chan、IORef 竞争、STM（TVar/retry/orElse）
module Ch22
    ( Acct(..), applyTransfer, totalOf
    , spawnJoin, collectMVars
    , chanPipeline
    , raceCounters
    , stmTransferIO, waitForPositive
    ) where

import Control.Concurrent (Chan, MVar, ThreadId, forkIO, newChan, newEmptyMVar, readChan,
                           takeMVar, writeChan, putMVar)
import Control.Concurrent.STM (STM, TVar, atomically, newTVarIO, readTVar, retry, writeTVar)
import Data.IORef (IORef, atomicModifyIORef', newIORef, readIORef, writeIORef)
import Data.List (sort)

-- ═══ 22.1 账户模型：转账的纯核心（余额不足拒绝、总额守恒——可离线测试）
data Acct = Acct { aName :: String, balance :: Int }
    deriving (Show, Eq)

applyTransfer :: Acct -> Acct -> Int -> Maybe (Acct, Acct)
applyTransfer from to amt
  | amt <= 0 || balance from < amt = Nothing
  | otherwise = Just ( from { balance = balance from - amt }
                     , to   { balance = balance to + amt } )

totalOf :: [Acct] -> Int
totalOf = sum . map balance

-- ═══ 22.2 forkIO + MVar 汇合：主线程等所有子线程的"完成票"
spawnJoin :: Int -> IO [Int]          -- 起 n 个线程各算 sq，按完成序收
spawnJoin n = do
    mvs <- mapM (\i -> do
                    mv <- newEmptyMVar
                    _ <- forkIO (putMVar mv (i * i))
                    pure mv) [1 .. n]
    collectMVars mvs

collectMVars :: [MVar Int] -> IO [Int]
collectMVars = mapM takeMVar

-- ═══ 22.3 Chan 流水线：生产者 → 加工者 → 消费者（两个无界通道串三级线程）
chanPipeline :: [Int] -> IO [Int]
chanPipeline xs = do
    c1 <- newChan
    c2 <- newChan
    _ <- forkIO (mapM_ (writeChan c1) xs >> writeChan c1 (-1 :: Int))     -- 生产者：数据+哨兵
    _ <- forkIO (relay c1 c2)                                             -- 加工者：*2 后转发
    drain c2
  where
    relay cin cout = do
        v <- readChan cin
        if v == sentinel then writeChan cout sentinel else writeChan cout (v * 2) >> relay cin cout
    drain c = do
        v <- readChan c
        if v == sentinel then pure [] else (v :) <$> drain c
    sentinel = -1 :: Int

-- ═══ 22.4 IORef 竞争：同一槽的非原子读改写会丢更新；atomicModifyIORef' 不丢
raceCounters :: Int -> IO (Int, Int)      -- (非原子结果, 原子结果)；n 次并发 +1 各跑一轮
raceCounters n = do
    r1 <- raceRound False n
    r2 <- raceRound True n
    pure (r1, r2)
  where
    raceRound atomic n = do
        ref <- newIORef (0 :: Int)
        mvs <- mapM (\_ -> do
                        mv <- newEmptyMVar
                        _ <- forkIO (bump ref >> putMVar mv ())
                        pure mv) [1 .. n]
        mapM_ takeMVar mvs
        readIORef ref
      where
        bump ref
          | atomic    = atomicModifyIORef' ref (\v -> (v + 1, ()))
          | otherwise = do                              -- 经典竞争窗口：读与写之间可被插队
              v <- readIORef ref
              writeIORef ref (v + 1)

-- ═══ 22.5 STM：事务内读改写要么整体成功要么重试；retry 阻塞到依赖的 TVar 变化
stmTransferIO :: TVar Int -> TVar Int -> Int -> IO Bool
stmTransferIO from to amt = atomically $ do
    b1 <- readTVar from
    if b1 < amt then pure False else do
        writeTVar from (b1 - amt)
        b2 <- readTVar to
        writeTVar to (b2 + amt)
        pure True

-- retry 版"等到条件成立"：余额到正数才返回（配合外部线程定时入账）
waitForPositive :: TVar Int -> IO ()
waitForPositive v = atomically $ do
    x <- readTVar v
    if x <= 0 then retry else pure ()
