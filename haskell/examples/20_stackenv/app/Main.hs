-- 20 Stack 工程与生态：本工程即本章示例（stack build / test / run 三连）
-- 运行：stack build && stack test && stack exec stackenv
module Main (main) where

import StackEnv
import Data.List (intercalate)
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    putStrLn "==[ 20 · Stack 工程 ]=="

    -- ═══ 20.1 镜像配置（正文讲 global-hints 的手动下载与 fpco 路径坑）
    mapM_ putStrLn ("  镜像配置：" : map ("    " ++) tunaConfig)

    -- ═══ 20.2 本工程 stack.yaml 的四行决策
    mapM_ putStrLn ("  本工程 stack.yaml：" : map ("    " ++) ourStackYaml)

    -- ═══ 20.3 resolver 解析
    mapM_ (\s -> putStrLn ("    parse " ++ show s ++ " = " ++ show (parseSnapshot s)))
          ["lts-24.59", "nightly-2026-09-18", "hackage-base-4.21", "lts-24", "lts-x.y"]

    -- ═══ 20.4 工程三件套
    mapM_ (\(part, items) -> putStrLn ("    " ++ part ++ ": " ++ intercalate "；" items))
          projectParts

    -- ═══ 20.5 自检
    check "resolver 全量" (parseSnapshot "lts-24.59") (Just (LTS 24 59))
    check "resolver 短名" (parseSnapshot "lts-24") Nothing
    check "resolver 烂名" (parseSnapshot "lts-x.y") Nothing
    check "nightly" (parseSnapshot "nightly-2026-09-18") (Just (Nightly "2026-09-18"))
    check "镜像四行" (length tunaConfig) 4
    check "yaml 四行" (length ourStackYaml) 4
    check "三件套" (length projectParts) 3

    putStrLn "==== 20 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
