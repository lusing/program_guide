-- 23 测试套件：等式计算器（书12）
module Main (main) where

import Ch23
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

laws12 :: [String]
laws12 =
    [ "defn filter: filter p = concat . map (box p)"
    , "defn box: box p = if p one nil"
    , "if after dot: if p f g . h = if (p . h) (f . h) (g . h)"
    , "dot after if: h . if p f g = if p (h . f) (h . g)"
    , "nil constant: nil . f = nil"
    , "map after nil: map f . nil = nil"
    , "map after one: map f . one = one . f"
    , "map after concat: map f . concat = concat . map (map f)"
    , "map functor: map f . map g = map (f . g)"
    , "map functor: map id = id"
    ]

lawsIter :: [String]
lawsIter =
    [ "defn iterate: iterate f = cons . fork id (iterate . f)"
    , "head after cons: head . cons = fst"
    , "fst after fork: fst . fork f g = f"
    ]

main :: IO ()
main = do
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8
    s1 <- runSuite "表达式解析与显示（书12.2）"
        [ expectEq "id 解析为空复合" (parseExpr "id") (Right (Compose []))
        , expectEq "变量" (parseExpr "f") (Right (Compose [Var "f"]))
        , expectEq "下标变量" (parseExpr "f1") (Right (Compose [Var "f1"]))
        , expectEq "常量应用" (parseExpr "filter p") (Right (Compose [Con "filter" [Compose [Var "p"]]]))
        , expectEq "复合" (show <$> parseExpr "map f . concat . map (box p)") (Right "map f . concat . map (box p)")
        , expectEq "运算符" (show <$> parseExpr "(f * g) . h") (Right "(f * g) . h")
        , expectEq "括号往返" (show <$> parseExpr "foo (f . g) bar") (Right "foo (f . g) bar")
        , expectTrue "定律解析" (case parseLaw "map functor: map f . map g = map (f . g)" of Right _ -> True; Left _ -> False)
        ]
    s2 <- runSuite "计算（书12.1 招牌例）"
        [ expectEq "filter.map 简化收敛"
            (show . final <$> simplify laws12 "filter p . map f")
            (Right "concat . map (if (p . f) (one . f) nil)")
        , expectEq "另一侧收敛到同式"
            (show . final <$> simplify laws12 "map f . filter (p . f)")
            (Right "concat . map (if (p . f) (one . f) nil)")
        , expectEq "iterate 计算直达 id"
            (show . final <$> simplify lawsIter "head . iterate f")
            (Right "id")
        , expectTrue "证明无 gap"
            (case prove laws12 "filter p . map f = map f . filter (p . f)" of
                Right calc -> not (elem "... ??? ..." (concatMap (\(w, _) -> [w]) (stepsOf calc)))
                Left _ -> False)
        ]
    s3 <- runSuite "定律排序（书12.3）"
        [ expectTrue "简单定律在前" (case sortLaws [parseLawOr l | l <- laws12] of
                (Law n1 _ : _) -> n1 `elem` ["if after dot", "nil constant", "map after nil", "map after one", "map functor"])
        , expectTrue "定义垫底" (case reverse (sortLaws [parseLawOr l | l <- laws12]) of
                (Law n2 _ : _) -> n2 == "defn box" || n2 == "defn filter")
        ]
    unless (s1 && s2 && s3) exitFailure
    putStrLn "==== 23 结束 ===="
  where
    parseLawOr s = case parseLaw s of
        Right l -> l
        Left _ -> Law "bad" (Compose [], Compose [])
    stepsOf (Calc _ sts) = sts
