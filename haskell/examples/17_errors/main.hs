-- 17 错误处理：Either vs 异常、throw 惰性、evaluate、bracket、精确捕获
-- 运行：ghc -v0 --make main.hs -o 17.exe && ./17.exe
module Main (main) where

import Ch17
import Control.Exception (IOException, SomeException, evaluate, throwIO, try)
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    -- ═══ 17.1 纯错误走 Either：全量可组合
    putStrLn "==[ 17 · 错误处理 ]=="
    mapM_ (putStrLn . describeAge) ["42", "999", "abc"]

    -- ═══ 17.2 IO 异常：try 只捕指定类型（IOException 精确捕）
    r1 <- try (readFile "这个文件不存在.txt") :: IO (Either IOException String)
    putStrLn ("读缺失文件 = " ++ either (const "已捕获 IO 异常") (const "读到内容?!") r1)

    -- ═══ 17.3 throw 的惰性：不强制就不炸
    let landmine = divideOrThrow 10 0        -- 埋雷：此刻无任何动静
    putStrLn ("埋了个雷（未触发），继续算别的 = " ++ show (1 + 1 :: Int))
    r2 <- try (evaluate landmine) :: IO (Either Boom Int)   -- evaluate：在 IO 里强制求值
    putStrLn ("引爆结果 = " ++ either (const "雷炸了（已捕获）") (const "居然没炸?!") r2)
    putStrLn ("正常除法 = " ++ show (divideOrThrow 10 2))

    -- ═══ 17.4 throwIO：在 IO 里立即抛（没有惰性问题）
    r3 <- try (throwIO (Boom "主动失败")) :: IO (Either Boom Int)
    putStrLn ("throwIO = " ++ either (const "立即失败（已捕获）") (const "?") r3)

    -- ═══ 17.5 bracket：异常路径也保证清理
    (phase, cleaned) <- runBracketDemo
    putStrLn ("bracket 阶段 = " ++ phase ++ "，资源已清理 = " ++ show cleaned)

    -- ═══ 17.6 SomeException 太宽：会把编程错误也吞掉（正文告诫，这里只演示能捕）
    r4 <- try (evaluate (divideOrThrow 1 0)) :: IO (Either SomeException Int)
    putStrLn ("宽捕获 = " ++ either (const "同样能捕（但不推荐）") (const "?") r4)

    -- ═══ 17.7 自检
    check "解析成功" (parseAge "42") (Right 42)
    check "范围错误" (parseAge "999") (Left (OutOfRange 999))
    check "类型错误" (parseAge "abc") (Left (NotAnInt "abc"))
    check "兜底默认" (ageOrDefault "abc") 0
    check "兜底成功" (ageOrDefault "20") 20
    check "IO 异常捕获" (either (const True) (const False) r1) True
    check "惰性埋雷无害" (1 + 1 :: Int) 2
    check "evaluate 引爆" (either (const True) (const False) r2) True
    check "正常除法" (divideOrThrow 10 2) 5
    check "throwIO 立即" (either (const True) (const False) r3) True
    check "bracket 清理" cleaned True
    check "宽捕获也行" (either (const True) (const False) r4) True

    putStrLn "==== 17 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
