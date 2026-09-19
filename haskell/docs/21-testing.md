# 21 · 测试

> 对应示例：`examples/21_testing/`

## 21.1 自制断言框架

本教程每个 runtests.hs 用的迷你框架（~20 行）：

```haskell
data Case = Case { name :: String, ok :: Bool, detail :: String }

expectEq n got want
  | got == want = Case n True ""
  | otherwise   = Case n False (n ++ ": 得到 " ++ show got ++ " 期望 " ++ show want)

runSuite :: String -> [Case] -> IO Bool
runSuite group cs = do
    let bad = [c | c <- cs, not (ok c)]
    putStrLn (group ++ ": " ++ show (length cs - length bad) ++ "/" ++ show (length cs) ++ " 通过")
    mapM_ (putStrLn . ("  ✗ " ++) . detail) bad
    pure (null bad)

-- main 末尾：unless (s1 && s2) exitFailure
```

为什么不用现成框架？① boot-only 原则（离线可验证）；② 框架本身就是 IO + Foldable + Either 的
复习题；③ HUnit/tasty 的 API 与它同构，学了自制的再迁移零成本。

## 21.2 性质测试：手写 mini-QuickCheck

三个组件：**生成器**（14 章 xorshift 的应用）、**收缩**（反例最小化）、**运行器**：

```haskell
class Generate a where generate :: Gen a
instance Generate Int where
    generate = (\v -> v * 2 - 100) <$> randIn 101      -- v∈[0,100] 映到 [-100,100]

shrinkInt n = if n == 0 then [] else [n `div` 2, 0]    -- 往更小找
shrinkList xs = [take k xs | k <- [length xs `div` 2, length xs - 1], k > 0, k < length xs]

runProperty :: Int -> Word64 -> Gen a -> (a -> [a]) -> (a -> Bool) -> Maybe a
runProperty count seed gen shrs prop =
    case filter (not . prop) samples of
        []    -> Nothing                 -- 全过
        (x:_) -> Just (shrinkLoop x)     -- 失败 → 收缩到最小反例
  where
    samples = [evalState gen (seed + fromIntegral i) | i <- [1 .. count]]
    shrinkLoop x = case filter (not . prop) (shrs x) of
        (y:_) -> shrinkLoop y
        []    -> x
```

经典性质（runtests 各跑 200 样本）：

```haskell
propSortIdempotent xs = sort (sort xs) == sort xs
propAbsNonNeg     x   = abs x >= 0
propReverseTwice  xs  = reverse (reverse xs) == xs
propTextRoundtrip s   = T.unpack (T.pack s) == s
```

## 21.3 故意失败的属性：验证收缩器

```haskell
runProperty 50 7 gen shrinkInt (\x -> x < 5)
-- 必出反例；且收缩后的反例满足"最小性"：它的所有收缩邻居都通过属性
maybe False (\x -> all (\y -> y < 5) (shrinkInt x)) mfail
```

**测试你的测试**——反例"确实违反属性"与"已最小化"都是可断言的不变式。

## 21.4 定种子：可复现是底线

种子硬编码（42/7/2026…），失败可逐位重放。随机断言只断**性质**（收敛带、单调性、守恒），
不断具体样本值。

## 21.5 生态对照

| 库 | 角色 |
|---|---|
| HUnit | xUnit 式断言（与自制框架同构） |
| tasty | 测试组织器/树形汇报（组合 HUnit/QuickCheck/…） |
| QuickCheck | 性质测试鼻祖（Generate=Arbitrary、shrink 内建、coverage） |
| hedgehog | 基于生成的另一家（内建收缩、无类型类） |

stack 工程里它们进 `test-suite` 的 build-depends（20 章），`stack test` 一键跑。

## 21.6 坑位清单

1. **随机数公式先验证范围**：`v * 201 - 100`（v∈[0,100]） Range 算错属性测试跟着错——实测
   踩过，"范围合法"用例拦下（21.2）。
2. **反例断言最小性不断具体值**：收缩终点取决于首个失败样本——断"邻居全通过"才是稳定不变式（21.3）。
3. **生成器覆盖边界**：0、空表、负数——`randIn 101` 含 0，空表由 `[a]` 实例的 randIn 9 产生（21.2）。
4. **性质测试不是全覆盖**：它是"找反例机器"——配上定点用例（runtests 前半）双保险。
