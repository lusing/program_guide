-- 20 测试套件（stack test 入口：退出码即判定）
module Main (main) where

import StackEnv
import Control.Monad (unless)
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stderr, stdout, utf8)

data Case = Case { name :: String, ok :: Bool, detail :: String }

expectEq :: (Eq a, Show a) => String -> a -> a -> Case
expectEq n got want
  | got == want = Case n True ""
  | otherwise   = Case n False (n ++ ": 得到 " ++ show got ++ " 期望 " ++ show want)

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
    s1 <- runSuite "resolver 解析"
        [ expectEq "标准 LTS" (parseSnapshot "lts-24.59") (Just (LTS 24 59))
        , expectEq "LTS 0 系" (parseSnapshot "lts-9.21") (Just (LTS 9 21))
        , expectEq "缺小版本" (parseSnapshot "lts-24") Nothing
        , expectEq "非数字" (parseSnapshot "lts-xx.yy") Nothing
        , expectEq "nightly" (parseSnapshot "nightly-2026-09-18") (Just (Nightly "2026-09-18"))
        , expectEq "无关输入" (parseSnapshot "hackage-abc") Nothing
        , expectEq "空前缀" (parseSnapshot "") Nothing
        ]
    s2 <- runSuite "配置与结构"
        [ expectEq "镜像首行是 setup-info" (head' tunaConfig)
              (Just "setup-info-locations: [\"https://mirrors.tuna.tsinghua.edu.cn/stackage/stack-setup.yaml\"]")
        , expectEq "镜像行数" (length tunaConfig) 4
        , expectEq "yaml 行数" (length ourStackYaml) 4
        , expectEq "三件套部件" (map fst projectParts) ["library", "executable", "test-suite"]
        ]
    unless (s1 && s2) exitFailure
    putStrLn "==== 20 结束 ===="
  where
    head' (x:_) = Just x
    head' []    = Nothing
