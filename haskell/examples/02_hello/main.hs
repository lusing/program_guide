-- 02 第一个程序：putStrLn/print 差别、getArgs 与空参容忍、Windows 编码坑
-- 运行：ghc -v0 --make main.hs -o 02.exe && ./02.exe [名字…]
module Main (main) where

import Ch02 (banner, greet, shout)
import System.Environment (getArgs)
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    -- Windows 坑（实测，9.12.1）：stdout 默认走 ANSI 代码页（本机 GBK），中文重定向即乱码；
    -- GHC_CHARENC=UTF-8 环境变量实测不生效——代码内 hSetEncoding 是唯一可靠修复。
    -- 本教程每个示例的第一件事都是它。
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    -- ═══ 02.1 putStrLn 与 print 的差别
    putStrLn (banner "02 · 第一个程序")
    putStrLn (shout "Hello, Haskell")     -- putStrLn :: String -> IO ()：原样输出
    print (shout "print 走 show 加引号")  -- print 走 show：源码字面量，非 ASCII 转十进制转义（中文坑）
    print (42 :: Int)                     -- print 对任意 Show 类型都行
    print (3.14 :: Double)

    -- ═══ 02.2 命令行参数：getArgs :: IO [String]，可能为空
    args <- getArgs
    putStrLn (greet args)                 -- 空参容忍逻辑在 Ch02.greet
    putStrLn ("参数个数: " ++ show (length args))

    -- ═══ 02.3 自检：失败即异常退出非 0（每章 main 都带）
    check "greet 空参" (greet []) "你好，GHC！"
    check "greet 两参" (greet ["Julia", "1.13"]) "你好，Julia、1.13！"
    check "banner" (banner "x") "==[ x ]=="
    check "shout" (shout "Hi") "Hi!"

    putStrLn "==== 02 结束 ===="

-- 自检辅助：值不等即抛异常（未捕获异常 → stderr + 退出码 1）
check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
