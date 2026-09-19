-- 18 编译期魔法：TH 引号/拼接/reify、lift 常量预生成、GHC.Generics 自省
-- 运行：ghc -v0 --make main.hs -o 18.exe && ./18.exe
{-# LANGUAGE TemplateHaskell #-}

module Main (main) where

import Ch18
import System.IO (hSetEncoding, stderr, stdout, utf8)

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8

    putStrLn "==[ 18 · 编译期魔法 ]=="

    -- ═══ 18.1 编译期算好的答案
    putStrLn ("answer      = " ++ show answer)
    putStrLn ("typedAnswer = " ++ show typedAnswer)

    -- ═══ 18.2 reify：Maybe 的构造子数量（编译期读出来的）
    putStrLn ("Maybe 构造子数 = " ++ show maybeCons)

    -- ═══ 18.3 lift 常量表
    putStrLn ("compileTimeTable = " ++ show compileTimeTable)

    -- ═══ 18.4 类型引号与名字
    putStrLn ("nameBase ''Maybe? 看文档——这里给 nameBaseOf 用法 = " ++ show (nameBaseOf 'answer))

    -- ═══ 18.5 Generics 自省
    let r = Rec 7 "seven"
    putStrLn ("recTypeName = " ++ show (recTypeName r))

    -- ═══ 18.6 自检
    check "表达式引号" answer 42
    check "typed TH" typedAnswer 42
    check "reify 计数" maybeCons 2
    check "lift 表与和" (sum compileTimeTable) 204
    check "lift 表尾" (foldl (\_ x -> x) 0 compileTimeTable) 64
    check "lift 表长" (length compileTimeTable) 8
    check "名字基名" (nameBaseOf 'answer) "answer"
    check "Generics 名" (recTypeName r) "Rec"

    putStrLn "==== 18 结束 ===="

check :: (Eq a, Show a) => String -> a -> a -> IO ()
check label actual expected
  | actual == expected = return ()
  | otherwise =
      error ("自检失败: " ++ label ++ ": 得到 " ++ show actual ++ " 期望 " ++ show expected)
