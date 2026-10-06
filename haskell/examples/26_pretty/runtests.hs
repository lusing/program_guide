-- 26 测试套件：优美打印（书8）
module Main (main) where

import Ch26
import Control.Monad (unless)
import System.Exit (exitFailure)
import System.IO (hSetEncoding, stderr, stdout, utf8)

data Case = Case {name :: String, ok :: Bool, detail :: String}

expectEq :: (Eq a, Show a) => String -> a -> a -> Case
expectEq n got want
    | got == want = Case n True ""
    | otherwise = Case n False (n ++ ": 得到 " ++ show got ++ " 期望 " ++ show want)

expectTrue :: String -> Bool -> Case
expectTrue n b = Case n b (if b then "" else n ++ ": 期望为真，得到假")

runSuite :: String -> [Case] -> IO Bool
runSuite group cs = do
    let bad = [c | c <- cs, not (ok c)]
    putStrLn (group ++ ": " ++ show (length cs - length bad) ++ "/" ++ show (length cs) ++ " 通过")
    mapM_ (putStrLn . ("  ✗ " ++) . detail) bad
    pure (null bad)

linesOf :: String -> [String]
linesOf s = case break (== '\n') s of
    (l, "") -> [l]
    (l, _ : r) -> l : linesOf r

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8
    let ifDoc = cexpr bookIf
        treeDoc = gtree bookTree
    s1 <- runSuite "构造子定律（书8.2 的抽样）"
        [ expectEq "nil 右单位元" (layouts (text "a" <=> nil)) (layouts (text "a"))
        , expectEq "nil 左单位元" (layouts (nil <=> text "a")) (layouts (text "a"))
        , expectEq "text 同态" (layouts (text ("ab" ++ "cd"))) (layouts (text "ab" <=> text "cd"))
        , expectEq "text 空串 = nil" (layouts (text "")) (layouts nil)
        , expectEq "nest 分配" (layouts (nest 2 (text "a" <=> line <=> text "b"))) (layouts (nest 2 (text "a") <=> nest 2 line <=> nest 2 (text "b")))
        , expectEq "nest 加法" (layouts (nest 2 (nest 3 line))) (layouts (nest 5 line))
        , expectEq "nest 0" (layouts (nest 0 (text "a" <=> line))) (layouts (text "a" <=> line))
        , expectEq "nest 对 text 无操作" (layouts (nest 3 (text "abc"))) (layouts (text "abc"))
        , expectEq "flatten 压行" (layouts (flatten (text "a" <=> line <=> text "b"))) ["a b"]
        , expectEq "group 前置扁平格式（flatten(line)=空格，带尾随空格）" (firstL (layouts (group (text "a" <=> line)))) "a "
        ]
    s2 <- runSuite "两种嵌入一致（书8.3 vs 8.6）"
        [ expectEq "layouts 参考==线性（条件）" (layouts ifDoc) (layoutsLinear ifDoc)
        , expectEq "layouts 参考==线性（树）" (layouts treeDoc) (layoutsLinear treeDoc)
        , expectEq "layouts 参考==线性（段落）" (layouts (para "aa bb cc dd")) (layoutsLinear (para "aa bb cc dd"))
        , expectEq "条件格式数 25" (length (layouts ifDoc)) 25
        , expectTrue "格式形状字典序递减" (descending (map (map length . linesOf) (layouts ifDoc)))
        ]
    s3 <- runSuite "pretty 两版一致与输出（书8.5/8.6）"
        [ expectEq "两版同文（条件 30）" (prettyNaive 30 ifDoc) (pretty 30 ifDoc)
        , expectEq "两版同文（条件 50）" (prettyNaive 50 ifDoc) (pretty 50 ifDoc)
        , expectEq "两版同文（树 26）" (prettyNaive 26 treeDoc) (pretty 26 treeDoc)
        , expectEq "两版同文（树 70）" (prettyNaive 70 treeDoc) (pretty 70 treeDoc)
        , expectEq "两版同文（段落）" (prettyNaive 22 (para "aa bb cc dd ee ff gg hh")) (pretty 22 (para "aa bb cc dd ee ff gg hh"))
        , expectTrue "段落每行不超宽" (all (<= 30) (map length (linesOf (pretty 30 (para bookPara)))))
        , expectEq "窄宽两档不同" (pretty 12 (para "aaaaaa bb cccc dddddd ee") /= pretty 40 (para "aaaaaa bb cccc dddddd ee")) True
        ]
    unless (s1 && s2 && s3) exitFailure
    putStrLn "==== 26 结束 ===="
  where
    firstL (x : _) = x
    firstL [] = ""
    descending xs = and (zipWith lexGeq xs (drop 1 xs))
    lexGeq [] _ = True
    lexGeq _ [] = False
    lexGeq (a : as) (b : bs)
        | a > b = True
        | a < b = False
        | otherwise = lexGeq as bs
