# 22 · 并发与 STM ⭐

> 对应示例：`examples/22_concurrency/`（`-threaded -rtsopts "-with-rtsopts=-N4"` 编译）

## 22.1 forkIO 与 MVar：最朴素的会合

`forkIO :: IO () -> IO ThreadId` 起轻量线程（Green thread，不是 OS 线程）。
**MVar** 是"空满两态"的槽：take 空则阻塞、put 满则阻塞——天然当"完成票"：

```haskell
spawnJoin n = do
    mvs <- mapM (\i -> do mv <- newEmptyMVar
                          _ <- forkIO (putMVar mv (i * i))
                          pure mv) [1 .. n]
    mapM takeMVar mvs              -- 主线程收齐所有票（汇合点）
```

**主线程不等子线程就退**——MVar 会合是最简单的 join。

## 22.2 threadDelay 的单位是微秒

```haskell
threadDelay 100000        -- 0.1 秒（不是毫秒！）
```

毫秒直觉带过来差三个数量级——runtests 里 `Sleep 0.1s` 的对照断言就是防它的（23 章 FFI 版）。

## 22.3 Chan：无界通道流水线

```haskell
chanPipeline xs = do
    c1 <- newChan; c2 <- newChan
    _ <- forkIO (mapM_ (writeChan c1) xs >> writeChan c1 sentinel)   -- 生产者
    _ <- forkIO (relay c1 c2)                                        -- 加工：×2 转发
    drain c2                                                         -- 消费者
```

三级线程、两个 FIFO 通道，哨兵值（-1）传到底表示流结束。输出保序（通道 FIFO）——可断言。

## 22.4 IORef 竞争：丢更新实测

```haskell
raceCounters n = do ... -- 同槽 2000 次并发 +1，各跑一轮
  where
    bump ref | atomic   = atomicModifyIORef' ref (\v -> (v + 1, ()))
             | otherwise = do v <- readIORef ref      -- 经典竞争窗口
                              writeIORef ref (v + 1)
```

-N4 下实测：非原子版**大概率 < 2000**（读改写之间被插队），原子版**恒等 2000**。
断言策略：非原子只断 `<= n`（丢不丢看调度），原子断 `== n`（永远不丢）——随机性只出现在
"错误写法"里，不变式留给了正确写法。

## 22.5 STM：事务内存

`atomically` 里的一串读写是**事务**：要么全成、要么重来（retry）：

```haskell
stmTransferIO from to amt = atomically $ do
    b1 <- readTVar from
    if b1 < amt then pure False else do
        writeTVar from (b1 - amt)
        b2 <- readTVar to
        writeTVar to (b2 + amt)
        pure True
```

- 余额守恒（`x1 + x2 == 100`）无需锁即可断言——事务原子性是语言保证；
- **retry = 阻塞等变化**：条件不满足就等，直到事务读过的 TVar 有变动再自动重跑：

```haskell
waitForPositive v = atomically $ do
    x <- readTVar v
    if x <= 0 then retry else pure ()

-- 配一个 50ms 后入账的线程：主线程"沉睡→自动唤醒"，实测醒来即正数
```

与锁对比：无死锁（没有锁序）、组合安全（两个事务拼起来还是事务）。`orElse` 一瞥：备选事务。

## 22.6 -threaded 与 -N

默认单核运行时；`-threaded` 启真并行，`+RTS -N4` 给 4 核。22 章示例的编译旗标：

```bash
ghc -threaded -rtsopts "-with-rtsopts=-N4" -o 22.exe main.hs
```

生态一瞥：async 包（async/await 风格、race、超时）是现代主力——base 的 forkIO/MVar 仍是其地基。

## 22.7 坑位清单

1. **threadDelay 微秒**：毫秒直觉差千倍（22.2）。
2. **主线程不等子线程**：主退全退——MVar/Chan 会合（22.1）。
3. **竞争断言策略**：错误写法断上界（可能丢），正确写法断等值（必不丢）——别把"大概率丢"
   写成"必丢"（22.4，runtests 的写法）。
4. **TVar 只能在 STM 里动**：`readTVarIO` 是外面的只读出口；普通 IO 写 TVar 编译不过（22.5）。
5. **retry 不是抛错**：是"等条件"——忘了写正常出口会在条件满足后死循环（22.5）。
