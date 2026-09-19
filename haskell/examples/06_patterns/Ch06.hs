-- Ch06 库模块：模式匹配——构造子/字面量/元组模式、@绑定、guard 共存、视图模式、惰性模式
{-# LANGUAGE ViewPatterns #-}

module Ch06
    ( describe, safeHead, safeTail, sumPairs, isVowel
    , firstAndRest, categorize, readInt, lazyHead, swapPair
    ) where

-- ═══ 06.1 构造子模式 + 字面量模式：按结构层层拆解（自上而下首个匹配者胜）
describe :: [Int] -> String
describe []        = "空"
describe [x]       = "单元素 " ++ show x
describe [x, y]    = "两个 " ++ show x ++ "," ++ show y
describe (x:_:z:_) = "至少三个，首尾 " ++ show x ++ "," ++ show z

-- ═══ 06.2 把部分函数安全化：head/tail 对 [] 会崩，模式匹配逼你处理空表
safeHead :: [a] -> Maybe a
safeHead []    = Nothing
safeHead (x:_) = Just x

safeTail :: [a] -> Maybe [a]
safeTail []     = Nothing
safeTail (_:xs) = Just xs

-- ═══ 06.3 元组模式（lambda 参数位直接解构）
sumPairs :: [(Int, Int)] -> [Int]
sumPairs = map (\(a, b) -> a + b)

swapPair :: (a, b) -> (b, a)
swapPair (a, b) = (b, a)

-- ═══ 06.4 字面量模式：对 Char/Int 等直接按值分派
isVowel :: Char -> Bool
isVowel 'a' = True
isVowel 'e' = True
isVowel 'i' = True
isVowel 'o' = True
isVowel 'u' = True
isVowel _   = False          -- _ 兜底：不关心具体是什么

-- ═══ 06.5 @ 绑定：既拿整体又拿部件（whole 复用，不重新构造）
firstAndRest :: [Int] -> (Int, [Int], Int)
firstAndRest whole@(x:_) = (x, whole, length whole)
firstAndRest []          = (0, [], 0)

-- ═══ 06.6 模式 + guard 共存：先按结构分派，再按条件细分
categorize :: [Int] -> String
categorize (x:_)
  | x > 0     = "首元素为正"
  | x < 0     = "首元素为负"
  | otherwise = "首元素为零"
categorize [] = "没有首元素"

-- ═══ 06.7 视图模式：先对参数应用函数，再对结果做匹配
-- reads "42" = [(42,"")]——读出 (值, 剩余未消费串)；恰好读尽才算整数
readInt :: String -> Maybe Int
readInt (reads -> [(n, "")]) = Just n
readInt _                    = Nothing

-- ═══ 06.8 惰性模式 ~：匹配时必成功（不强制参数），取值时才崩——错误被推迟
lazyHead :: [a] -> a
lazyHead ~(x:_) = x           -- lazyHead [] 不会在"匹配"时崩，在用返回值时才崩
