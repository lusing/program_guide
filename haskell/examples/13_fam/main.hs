-- 13 函子·应用·单子：三部曲、手写 State、do 记法脱糖、三定律
-- 运行：ghc -v0 --make main.hs -o 13.exe && ./13.exe
module Main (main) where

import Ch13
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    -- ═══ 13.1 Applicative 风格 vs 单子风格
    putStrLn "==[ 13 · 函子·应用·单子 ]=="
    putStrLn ("addMaybes (Just 1) (Just 2) = " ++ show (addMaybes (Just 1) (Just 2)))
    putStrLn ("addMaybes Nothing  (Just 2) = " ++ show (addMaybes Nothing (Just 2)))
    putStrLn ("mul3 列表 = 笛卡尔积 " ++ show (mul3 [1, 2] [10] [100, 200] :: [Int]))
    putStrLn ("firstJust = " ++ show (firstJust Nothing (Just 5)))

    -- ═══ 13.2 链式查找：Maybe 与 Either
    putStrLn ("describeUser 1 = " ++ show (describeUser 1))
    putStrLn ("describeUser 9 = " ++ show (describeUser 9))
    putStrLn ("describeUserE 2 = " ++ show (describeUserE 2))   -- Bob 存在但无年龄

    -- ═══ 13.3 手写 State：计数器
    putStrLn ("evalState tick3 0 = " ++ show (evalState tick3 0))
    putStrLn ("tick3 脱糖等价    = " ++ show (evalState tick3Desugar 0 == evalState tick3 0))
    putStrLn ("execState tick3 0 = " ++ show (execState tick3 0))  -- 只留终态

    -- ═══ 13.4 手写栈
    putStrLn ("栈操作序列终态 = " ++ show (execState stackDemo []))

    -- ═══ 13.5 自检（含三定律）
    check "Maybe 加法" (addMaybes (Just 1) (Just 2)) (Just 3)
    check "Maybe 失败传染" (addMaybes Nothing (Just 2)) Nothing
    check "列表笛卡尔" (mul3 [1] [2] [3] :: [Int]) [6]
    check "Alternative" (firstJust Nothing (Just 5)) (Just 5)
    check "Maybe 命中" (describeUser 1) (Just "Alice (30)")
    check "Maybe 落空" (describeUser 9) Nothing
    check "Either 带原因" (describeUserE 2) (Left "无年龄: Bob")
    check "State 计数" (evalState tick3 0) 12
    check "do 即脱糖" (evalState tick3Desugar 5) 567
    check "终态" (execState tick3 0) 3
    -- 单子定律：左单位 pure a >>= f == f a；右单位 m >>= pure == m
    check "左单位" (evalState (pure 9 >>= \x -> smodify (+ x) >> sget) 0) 9
    check "右单位" (evalState (tick >>= pure) 0) (evalState tick 0)
    -- 函子定律：fmap id == id；fmap (f.g) == fmap f . fmap g
    check "函子 id" (evalState (fmap id tick) 0) (evalState tick 0)
    -- 注意括号：fmap f . fmap g 是函数组合，整体作用于 tick3（不加括号会解析错——. 的优先级低于应用）
    check "函子复合" (evalState (fmap ((* 2) . (+ 1)) tick3) 0)
                     (evalState ((fmap (* 2) . fmap (+ 1)) tick3) 0)

    putStrLn "==== 13 结束 ===="

stackDemo :: State Stack Int
stackDemo = do
    push 1
    push 2
    push 3
    a <- pop      -- 3
    b <- pop      -- 2
    pure (a * 10 + b)

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
