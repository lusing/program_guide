-- 13 测试套件
module Main (main) where

import Ch13
import Control.Monad (unless)
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stderr, stdout, utf8)

data Case = Case { name :: String, ok :: Bool, detail :: String }

expectEq :: (Eq a, Show a) => String -> a -> a -> Case
expectEq n got want
  | got == want = Case n True ""
  | otherwise   = Case n False (n ++ ": 得到 " ++ show got ++ " 期望 " ++ show want)

expectTrue :: String -> Bool -> Case
expectTrue n b = Case n b (if b then "" else n ++ ": 期望为真，得到假")

runSuite :: String -> [Case] -> IO Bool
runSuite group cs = do
    let bad = [c | c <- cs, not (ok c)]
    putStrLn (group ++ ": " ++ show (length cs - length bad) ++ "/" ++ show (length cs) ++ " 通过")
    mapM_ (putStrLn . ("  ✗ " ++) . detail) bad
    pure (null bad)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8
    s1 <- runSuite "Applicative"
        [ expectEq "Maybe 双值" (addMaybes (Just 3) (Just 4)) (Just 7)
        , expectEq "Maybe 左败" (addMaybes Nothing (Just 4)) Nothing
        , expectEq "Maybe 右败" (addMaybes (Just 3) Nothing) Nothing
        , expectEq "列表笛卡尔" (mul3 [1, 2] [3] [5] :: [Int]) [15, 30]
        , expectEq "Alternative 首" (firstJust (Just 1) (Just 2)) (Just 1)
        , expectEq "Alternative 右兜底" (firstJust Nothing (Just 2)) (Just 2)
        ]
    s2 <- runSuite "链式查找"
        [ expectEq "Maybe 命中" (describeUser 1) (Just "Alice (30)")
        , expectEq "Maybe 用户落空" (describeUser 9) Nothing
        , expectEq "Either 用户落空" (describeUserE 9) (Left "用户不存在")
        , expectEq "Either 年龄落空" (describeUserE 2) (Left "无年龄: Bob")
        , expectEq "Either 命中" (describeUserE 1) (Right "Alice (30)")
        ]
    s3 <- runSuite "手写 State"
        [ expectEq "tick3 从 0" (evalState tick3 0) 12
        , expectEq "tick3 从 5" (evalState tick3 5) 567
        , expectEq "脱糖等价" (evalState tick3Desugar 7) (evalState tick3 7)
        , expectEq "execState" (execState tick3 0) 3
        , expectEq "sget" (evalState sget "hi") "hi"
        , expectEq "sput" (execState (sput 9) 0) 9
        , expectEq "smodify" (execState (smodify (* 2)) 21) 42
        , expectEq "栈弹出" (evalState (pop >> pop >> sget) [1, 2, 3]) [3]
        , expectEq "空栈哨兵" (evalState pop []) (-1)
        ]
    s4 <- runSuite "三定律"
        [ expectTrue "函子 id" (evalState (fmap id tick3) 0 == evalState tick3 0)
        , expectTrue "函子复合" (evalState (fmap ((* 2) . (+ 1)) tick3) 41
                                  == evalState ((fmap (* 2) . fmap (+ 1)) tick3) 41)
        , expectTrue "单子左单位" (evalState (pure 9 >>= \x -> smodify (+ x) >> sget) 0 == 9)
        , expectTrue "单子右单位" (evalState (tick >>= pure) 0 == evalState tick 0)
        ]
    unless (s1 && s2 && s3 && s4) exitFailure
    putStrLn "==== 13 结束 ===="
