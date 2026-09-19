# 19 · 性能 ⭐

> 对应示例：`examples/19_performance/`

## 19.1 优化次序：算法 > 数据结构 > 严格性 > 常数

```haskell
fibNaive 24       -- 指数级：~10ms 级
fibAcc 90         -- 线性：瞬时（2880067194370816120）
```

同一优化级别下数量级的差距——先动算法，别的都白搭（04 章累加器的回响）。

## 19.2 计时方法论：deepseq 收尾

**计时前必须 force 结果**——否则你测的是"造 thunk"的时间：

```haskell
timed :: NFData a => IO a -> IO (Double, a)
timed act = do
    t0 <- getMonotonicTime               -- GHC.Clock（boot）
    x <- act
    y <- evaluate (force x)              -- 完全求值完才停表
    t1 <- getMonotonicTime
    pure (t1 - t0, y)
```

## 19.3 惰性泄漏的账单

```haskell
sumLazy n   = foldl  (+) 0 [1 .. n]      -- 堆 n 个 thunk
sumStrict n = foldl' (+) 0 [1 .. n]      -- 常量空间
```

两版值相同（测试断言），代价看 RTS 统计：

```bash
./19.exe +RTS -s         # 看 total memory / alloc 两行对比
```

10 章的三板斧（foldl'/seq/bang）在此量化。

## 19.4 字符串拼接的平方律

```haskell
concatSlow    n = T.pack (foldl (++) "" (replicate n "ab"))   -- 左嵌套 ++：O(n²) 拷贝
concatBuilder n = TL.toStrict (B.toLazyText
                   (mconcat (replicate n (B.fromText "ab")))) -- Builder：分段累积一次成型
```

4000 段实测：慢版秒级、Builder 毫秒级（机器不同数字不同——**断言只断同值同长**，时间进正文）。

## 19.5 编译器优化与观测

```bash
ghc -O2 …                  # 优化级别（验证层用 -O0 求快，发布用 -O2）
ghc -ddump-strictness …    # 看严格性分析对函数的判定（教学演示用）
./app +RTS -s              # 运行时统计：内存/分配/GC
./app +RTS -N4             # 多核（22 章 -threaded）
```

生态介绍（不入主线）：criterion（基准测试）、ghc-prof + `-prof`（剖析）、eventlog（并发观测）。

## 19.6 坑位清单

1. **计时不 force = 测了个寂寞**：thunk 构造远比求值便宜——timed 的 evaluate (force …) 是
   教科书姿势（19.2）。
2. **断言别断耗时数字**：机器/负载相关——值与不等式关系（tSlow > tFast 级别）才稳定（本教程
   实测约定）。
3. **foldl 的泄漏在 -O2 下可能被优化掉**：`-O0` 复现最稳（教学用 -O0 展示；生产反正写 foldl'）。
4. **String 拼接的 O(n²)**：`acc ++ x` 循环建串——Text + Builder（19.4）。
5. **deepseq 需要 NFData 实例**：自定义类型 `deriving Generic` 后用 `force`（Control.DeepSeq
   的泛型支持），手写也行（10 章回响）。
