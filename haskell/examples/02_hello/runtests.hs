-- 02 测试套件：自制迷你框架（分组 + 统计 + 失败明细 + exitFailure；21 章正文化）
module Main (main) where

import Ch02 (banner, greet, shout)
import Control.Monad (unless)
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stderr, stdout, utf8)

-- ═══ 迷你测试框架（每章 runtests.hs 同款）
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
    s1 <- runSuite "greet"
        [ expectEq "空参数默认问候" (greet []) "你好，GHC！"
        , expectEq "单参数" (greet ["Haskell"]) "你好，Haskell！"
        , expectEq "多参数顿号连接" (greet ["a", "b", "c"]) "你好，a、b、c！"
        ]
    s2 <- runSuite "shout/banner"
        [ expectEq "shout 加叹号" (shout "Hi") "Hi!"
        , expectEq "banner 包框" (banner "t") "==[ t ]=="
        , expectTrue "banner 以 ==[ 开头" (take 3 (banner "x") == "==[")
        , expectTrue "shout 长度加一" (length (shout "abc") == 4)
        ]
    unless (s1 && s2) exitFailure
    putStrLn "==== 02 结束 ===="
