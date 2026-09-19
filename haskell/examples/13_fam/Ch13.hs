-- Ch13 库模块：函子·应用·单子三部曲——类型类定义、手写 State、do 记法、三定律
module Ch13
    ( addMaybes, mul3, firstJust
    , describeUser, describeUserE
    , State(..), evalState, execState
    , sget, sput, smodify
    , tick, tick3, tick3Desugar
    , Stack, push, pop
    ) where

-- ═══ 13.1 Applicative 风格：纯函数"抬"进上下文
addMaybes :: Maybe Int -> Maybe Int -> Maybe Int
addMaybes a b = (+) <$> a <*> b          -- 任一 Nothing → 整体 Nothing

mul3 :: Applicative f => f Int -> f Int -> f Int -> f Int
mul3 a b c = (\x y z -> x * y * z) <$> a <*> b <*> c

-- Alternative 的 <|> 在 Maybe 上的行为：取首个"有值"的（这里直接手写等价物）
firstJust :: Maybe a -> Maybe a -> Maybe a
firstJust (Just x) _ = Just x
firstJust Nothing  r = r

-- ═══ 13.2 同一"链式查找"任务的三种上下文写法
lookupUser :: Int -> Maybe String
lookupUser 1 = Just "Alice"
lookupUser 2 = Just "Bob"
lookupUser _ = Nothing

lookupAge :: String -> Maybe Int
lookupAge "Alice" = Just 30
lookupAge _       = Nothing

describeUser :: Int -> Maybe String          -- Maybe 单子：任一步失败整体失败
describeUser uid = do
    name <- lookupUser uid
    age  <- lookupAge name
    pure (name ++ " (" ++ show age ++ ")")

describeUserE :: Int -> Either String String -- Either 单子：失败带原因
describeUserE uid = do
    name <- maybe (Left "用户不存在") Right (lookupUser uid)
    age  <- maybe (Left ("无年龄: " ++ name)) Right (lookupAge name)
    pure (name ++ " (" ++ show age ++ ")")

-- ═══ 13.3 手写 State 单子：从零实现 Functor/Applicative/Monad 三实例
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

evalState :: State s a -> s -> a
evalState m s0 = fst (runState m s0)

execState :: State s a -> s -> s
execState m s0 = snd (runState m s0)

-- ═══ 13.4 State 的三个原语
sget :: State s s
sget = State (\s -> (s, s))

sput :: s -> State s ()
sput s = State (\_ -> ((), s))

smodify :: (s -> s) -> State s ()
smodify f = State (\s -> ((), f s))

-- ═══ 13.5 计数器：do 记法
tick :: State Int Int            -- 返回旧值，计数 +1
tick = do
    n <- sget
    sput (n + 1)
    pure n

tick3 :: State Int Int
tick3 = do                       -- do 记法：顺序计算的语法糖
    a <- tick
    b <- tick
    c <- tick
    pure (a * 100 + b * 10 + c)  -- 012 → 12

tick3Desugar :: State Int Int
tick3Desugar =                   -- do 的完全脱糖形态（>>= 链）
    tick >>= \a ->
    tick >>= \b ->
    tick >>= \c ->
    pure (a * 100 + b * 10 + c)

-- ═══ 13.6 手写栈
type Stack = [Int]

push :: Int -> State Stack ()
push x = smodify (x :)

pop :: State Stack Int
pop = do
    st <- sget
    case st of
        []     -> pure (-1)      -- 教学版：空栈给哨兵（生产代码该用 Maybe）
        (x:xs) -> sput xs >> pure x
