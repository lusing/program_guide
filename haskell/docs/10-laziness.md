# 10 · 惰性求值 ⭐

> 对应示例：`examples/10_laziness/`

## 10.1 thunk：不到最后不动手

Haskell 的值默认是 **thunk**（"未兑现的承诺"）。`let x = expensive 42` 此刻什么都不算；
`x` 被用到的那一刻才算，算完共享结果。这就是"取多少算多少"的机制（9 章无穷列表的根基）。

```haskell
take 5 nats        -- 只算前五个，其余的 thunk 永远不兑现
```

## 10.2 自引用定义

值可以在自己的定义里引用自己——thunk 图成环，按需逐层展开：

```haskell
nats :: [Int]
nats = 0 : map (+ 1) nats                -- take 5 == [0..4]

fibsZ :: [Integer]
fibsZ = 0 : 1 : zipWith (+) fibsZ (drop 1 fibsZ)
-- 每个 fib thunk 复用前两个的结果：记忆化的雏形
```

（坑：这里用 `drop 1` 而不是 `tail`——9.12 起 `tail` 默认 -Wx-partial 警告，06 章讲过。）

## 10.3 空间泄漏：惰性的账单

foldl 的经典翻车（本机 -O0 实测，RTS `-s` 可见内存对照）：

```haskell
sumLazy n   = foldl  (+) 0 [1 .. fromIntegral n]   -- 堆一百万个 (…(0+1)+2)… thunk
sumStrict n = foldl' (+) 0 [1 .. fromIntegral n]   -- 每步强制，常量内存
```

两版**值相同**，代价天差地别。修复三板斧：

1. `foldl'`（Data.List）——折叠场景首选；
2. `seq a b`——把 a 求值到 WHNF 再返回 b（`l `seq` s `seq` s / fromIntegral l`）；
3. bang patterns（`go !acc …`）——04 章累加器已经用上。

## 10.4 经典泄漏形态：where 里的双 thunk

```haskell
average xs = s / fromIntegral l            -- l、s 两个 thunk 挂到除法才强制
  where l = length xs
        s = sum xs

average' xs = l `seq` s `seq` s / fromIntegral l   -- 用完即弃
```

教程断言只断值——内存数字进正文（19 章给 RTS `-s` 实测法）。

## 10.5 deepseq：整棵算完

`seq` 只强制到 **WHNF**（最外层构造子）；`deepseq`（Control.DeepSeq）把整棵结构算到底：

```haskell
strictLen xs = force xs `seq` length xs    -- NFData 约束
```

计时、断言"已完全求值"的标准姿势（19 章 `timed` 就靠它）。

## 10.6 共享 vs 重复计算

```haskell
squareOnce n =
    let sq = n * n          -- 一个 thunk，两处引用只算一次
    in (sq + 0, sq + 1)
```

let 绑定天然共享；反过来，把 `n * n` 写两遍**不保证**只算一次（编译器可能公共子表达式消除，
也可能不消）——想要共享，显式 let。

## 10.7 坑位清单

1. **foldl 堆 thunk**：大列表一律 foldl'（10.3）。
2. **seq 语义**：`seq a b` 只保证 a 到 WHNF——`seq (x:xs) y` 不算 x！要算完用 deepseq（10.5）。
3. **惰性 IO 的句柄悬锁**（16 章实测重灾）：未消费完的 readFile 句柄锁文件直到 GC（10.1 与 16.2）。
4. **"算两次"陷阱**：不带共享的重复表达式可能真的算两遍（10.6）。
5. **断言别断内存数字**：惰性使内存/时序不确定——教程与测试只断值与大小关系（10.4）。
