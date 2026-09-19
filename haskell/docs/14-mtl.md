# 14 · 单子变换器与 mtl ⭐

> 对应示例：`examples/14_mtl/`（含手写 xorshift64* 纯随机）

## 14.1 为什么需要变换器

13 章的 State 是自己写的"裸"单子。真实程序要的是**叠加态**：状态 + 错误 + IO。
**单子变换器**就是给单子"戴帽子"的类型构造子：

```haskell
StateT s m a        -- 在单子 m 上加状态层
ExceptT e m a       -- 在单子 m 上加错误层
ReaderT r m a / WriterT w m a
```

`State Int` ≈ `StateT Int Identity`（纯内芯版）。

## 14.2 mtl 风格：约束代替具体类型

transformers 直用（lift 手动抬）；**mtl 风格**只声明"需要什么能力"：

```haskell
rand01G :: MonadState Word64 m => m Double        -- 不绑死具体单子！
rand01G = do
    s <- get
    let s' = step s
    put s'
    pure (unit01 s')
```

同一段代码，两种单子里跑出**同样的数**（确定性是测试的根基）：

```haskell
randList 7 3          -- evalState (randListG 3) 7   —— 纯跑
evalStateT (randListG 3) 7 :: IO [Double]           —— StateT IO 里跑，结果一致
```

## 14.3 手写 xorshift64*：纯随机

Haskell 没有全局随机源——**种子即状态**，纯函数可测试：

```haskell
step :: Word64 -> Word64                -- 三步移位异或 + 一乘法
step x0 = x3 * 2685821657736338717
  where
    x1 = x0 `xor` (x0 `shiftR` 12)
    x2 = x1 `xor` (x1 `shiftL` 25)
    x3 = x2 `xor` (x2 `shiftR` 27)

unit01 s = fromIntegral (s `shiftR` 11) / 2 ^ (53 :: Int)   -- [0,1)
```

**种子相同 → 序列完全相同**（`randList 42 5` 两次调用逐位一致——runtests 断言的就是它）。
蒙特卡洛 π：

```haskell
piEstimate 2026 50000       -- ≈ 3.1416（偏差 <0.05，断言只断收敛带）
```

## 14.4 ExceptT 叠加：错误 + 状态

```haskell
type Eval = ExceptT String (State Word64)

safeRecipAvg :: Eval Double
safeRecipAvg = do
    x <- rand01G                           -- MonadState 实例自动穿透 ExceptT！
    y <- rand01G
    if y < 0.1 then throwError ("分母太小: " ++ show y)
               else pure (x / y)

runEval seed = evalState (runExceptT safeRecipAvg) seed
```

mtl 的杀手锏：`MonadState`/`MonadError` 实例为各层组合自动生成——`get` 不用写 `lift get`。

## 14.5 lift：穿透不了的才手抬

底层单子的动作（如 IO）没有自动实例，必须 `lift`：

```haskell
countDown :: Int -> StateT Int IO [String]
countDown 0 = pure []
countDown n = do
    lift (putStrLn ("tick " ++ show n))    -- IO 动作手动抬一层
    modify (+ 1)                           -- 状态操作自动（mtl）
    (:) (show n) <$> countDown (n - 1)
```

## 14.6 坑位清单

1. **execStateT/evalStateT/runStateT 三兄弟**：run 给 `(结果, 终态)`、eval 只给结果、exec 只给
   终态——想要"结果+状态"却调了 exec 是实测错误（14 章开发中踩过）（14.2）。
2. **纯 throw 在变换器里**：用 `throwError`（mtl 的 MonadError 方法）——mtl 2.3 不再转出口
   transformers 的 `throwE`（24 章实测）（14.4）。
3. **随机必须可复现**：种子硬编码进测试；"循环内新建同种子生成器 = 同一批样本"（Julia 教程同款
   坑的 Haskell 版）（14.3）。
4. **蒙特卡洛断言收敛带不断具体值**：随机结果的断言用带宽（`abs (est - pi) < 0.05`）（14.3）。
5. **transformers 直用 vs mtl**：小项目 transformers 足够；要"同代码多单子复用"就上 mtl 约束风格。
