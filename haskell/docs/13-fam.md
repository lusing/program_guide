# 13 · 函子·应用·单子 ⭐

> 对应示例：`examples/13_fam/`（含从零手写的 State 单子）

## 13.1 三部曲：类型类逐级叠加

```haskell
class Functor f where                    -- f :: Type -> Type（Kind！）
    fmap :: (a -> b) -> f a -> f b       -- 对容器里的值做映射

class Functor f => Applicative f where
    pure :: a -> f a                     -- 裸值进容器
    (<*>) :: f (a -> b) -> f a -> f b    -- 容器里的函数应用容器里的值

class Applicative f => Monad f where
    (>>=) :: f a -> (a -> f b) -> f b    -- 前一步的**值**决定后一步的动作
```

直觉：**Functor**——"map 一下"；**Applicative**——"多值并行组合"（结构固定）；
**Monad**——"下一步依赖上一步的结果"（结构动态）。

## 13.2 Applicative 风格

```haskell
addMaybes :: Maybe Int -> Maybe Int -> Maybe Int
addMaybes a b = (+) <$> a <*> b          -- 任一 Nothing → 整体 Nothing

mul3 a b c = (\x y z -> x * y * z) <$> a <*> b <*> c
mul3 [1,2] [10] [100,200] :: [Int]       -- [1000,2000,2000,4000]：列表 = 笛卡尔积
```

`<*>` 组合的是"多个独立上下文"——效果不能互相影响，因此结构静态可知。

## 13.3 同一任务的 Maybe / Either 两写法

```haskell
describeUser :: Int -> Maybe String              -- 任一步失败整体失败
describeUser uid = do
    name <- lookupUser uid
    age  <- lookupAge name
    pure (name ++ " (" ++ show age ++ ")")

describeUserE :: Int -> Either String String     -- 失败带原因
describeUserE uid = do
    name <- maybe (Left "用户不存在") Right (lookupUser uid)
    age  <- maybe (Left ("无年龄: " ++ name)) Right (lookupAge name)
    pure (name ++ " (" ++ show age ++ ")")
```

`do` 记法是 `>>=` 链的糖（下面脱糖对照）。

## 13.4 从零手写 State 单子

"带状态的计算"= 函数 `s -> (a, s)`。包成 newtype 就是 State：

```haskell
newtype State s a = State { runState :: s -> (a, s) }

instance Functor (State s) where
    fmap f (State g) = State (\s -> let (a, s') = g s in (f a, s'))

instance Applicative (State s) where
    pure a = State (\s -> (a, s))
    State f <*> State g = State (\s ->
        let (h, s1) = f s
            (a, s2) = g s1
        in (h a, s2))

instance Monad (State s) where
    State g >>= k = State (\s -> let (a, s') = g s in runState (k a) s')
```

三个原语 + 计数器：

```haskell
sget   = State (\s -> (s, s))
sput s = State (\_ -> ((), s))
smodify f = State (\s -> ((), f s))

tick :: State Int Int                  -- 返回旧值，计数 +1
tick = do n <- sget; sput (n + 1); pure n

tick3 = do a <- tick; b <- tick; c <- tick; pure (a*100 + b*10 + c)
evalState tick3 0                      -- 12（0,1,2）
```

**do 即脱糖**——下面两行完全等价：

```haskell
tick3 = do { a <- tick; b <- tick; c <- tick; pure (a*100+b*10+c) }
tick3Desugar = tick >>= \a -> tick >>= \b -> tick >>= \c -> pure (a*100+b*10+c)
```

## 13.5 三定律（测试即证据）

runtests 里把定律写成断言：

- 函子：`fmap id m == m`；`fmap (f . g) == fmap f . fmap g`
- 单子左单位：`pure a >>= f == f a`；右单位：`m >>= pure == m`

**定律不是装饰**——手写实例写错（比如 `>>=` 忘了传新状态）定律测试立刻红。

## 13.6 Alternative 一瞥

```haskell
firstJust (Just x) _ = Just x           -- Maybe 的 <|> 语义：取首个有值
firstJust Nothing  r = r
```

## 13.7 坑位清单

1. **组合链作用到值要加括号**：`(fmap f . fmap g) m ≠ fmap f . fmap g m`——`.` 优先级低于应用
   （5 章坑的定律版，实测摔过）（13.5）。
2. **`return` 已不推荐**：用 `pure`（语义更准——它不是"返回"，是"入容器"）（13.3）。
3. **Functor 的 Kind 门槛**：`Type -> Type` 才能当 Functor——`Maybe` 行、`Int` 不行（8.6 回响）。
4. **do 里的 <- 是绑定不是赋值**：同一名字重复绑定是遮蔽（04 章对照）。
5. **Applicative 够用就别上 Monad**：结构静态可推（解析器并行分支 vs 依赖前值时再升级）。
