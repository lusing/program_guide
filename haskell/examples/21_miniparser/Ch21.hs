-- Ch21 库模块：手写解析器组合子（书11）——newtype Parser、组合子、表达式文法、show 往返
module Ch21
    ( Parser (..)
    , parseFirst
    , sat, char, string, digitP, lowls, spaces, symbol, token
    , wrong, best
    , natural, integer
    , Expr (..), Op (..)
    , exprP, termP, factorP
    , evalE, runExpr
    , showsPrecE
    ) where

import Control.Applicative (Alternative (..))
import Data.Char (isDigit, isLower, isSpace)

-- ═══ 21.1 类型：吃前缀、可失败、可多解（书11.1 的三步进化终点）
newtype Parser a = Parser {applyP :: String -> [(a, String)]}
  -- 结果是"值 + 剩余输入"的列表：空 = 失败；多元素 = 多义

parseFirst :: Parser a -> String -> Maybe (a, String) -- 全函数版取首解
parseFirst p s = case applyP p s of
    ((x, rest) : _) -> Just (x, rest)
    [] -> Nothing

-- ═══ 21.2 类型类实例：单子的"顺序"、Alternative 的"选择"
instance Functor Parser where
    fmap f p = Parser (\s -> [(f x, s') | (x, s') <- applyP p s])

instance Applicative Parser where
    pure x = Parser (\s -> [(x, s)]) -- 不消耗输入，直接产值
    pf <*> px = Parser $ \s ->
        [ (f y, s2)
        | (f, s1) <- applyP pf s
        , (y, s2) <- applyP px s1
        ]

instance Monad Parser where
    p >>= q = Parser $ \s -> -- 先跑 p；对每个分支跑 q；全部串联（列表单子的"多世界"）
        [ (y, s2)
        | (x, s1) <- applyP p s
        , (y, s2) <- applyP (q x) s1
        ]

instance Alternative Parser where
    empty = Parser (const []) -- 失败：空解（书里的 fail）
    p <|> q = Parser $ \s -> -- 选择：p 失败才试 q（确定分析器的合取）
        case applyP p s of
            [] -> applyP q s
            r -> r

-- ═══ 21.3 基本组合子（书11.2）
sat :: (Char -> Bool) -> Parser Char
sat p = do
    c <- getc
    if p c then pure c else empty
  where
    getc = Parser f
      where
        f (c : cs) = [(c, cs)]
        f [] = []

char :: Char -> Parser ()
char x = sat (== x) >> pure ()

string :: String -> Parser ()
string [] = pure ()
string (x : xs) = char x >> string xs

digitP :: Parser Int -- 数字字符 → 数
digitP = do
    d <- sat isDigit
    pure (fromEnum d - fromEnum '0')

lowls :: Parser String -- 一串小写字母（many 的示例）
lowls = many (sat isLower)

-- ═══ 21.4 选择陷阱与公共前缀（书11.3 的 wrong/best）
wrong :: Parser Int -- digit 在前：永远轮不到加法分支
wrong = plainDigit <|> addition
  where
    plainDigit = digitP
    addition = do
        m <- digitP
        char '+'
        n <- digitP
        pure (m + n)

best :: Parser Int -- 提取公共前缀 digit，rest 用累积参数（书的正解）
best = digitP >>= rest
  where
    rest m = do
        char '+'
        n <- digitP
        rest (m + n)
        <|> pure m

-- ═══ 21.5 空白与 token（书11.3）
spaces :: Parser ()
spaces = many (sat isSpace) >> pure ()

symbol :: String -> Parser ()
symbol xs = spaces >> string xs

token :: Parser a -> Parser a
token p = spaces >> p

-- ═══ 21.6 自然数与整数（书11.3 的 minus-函数技巧）
natural :: Parser Int
natural = token nat
  where
    nat = do
        ds <- some digitP
        pure (foldl shiftl 0 ds)
    shiftl m n = 10 * m + n

integer :: Parser Int
integer = do
    spaces
    f <- minus
    n <- nat
    pure (f n)
  where
    nat = do
        ds <- some digitP
        pure (foldl (\m n -> 10 * m + n) 0 ds)
    -- 负号"可选"返回函数：有负号得 negate，没得 id——避免重扫前缀
    minus = (char '-' >> pure negate) <|> pure id

-- ═══ 21.7 表达式文法（书11.4）：四则、优先级、左结合
data Op = Plus | Minus | Mul | Div deriving (Eq, Show)

data Expr = Con Int | Bin Op Expr Expr deriving (Eq)

-- expr ::= term (addop term)*      —— rest 是累积参数版的星号重复
exprP :: Parser Expr
exprP = token (termP >>= rest)
  where
    rest e1 = do
        p <- addop
        e2 <- termP
        rest (Bin p e1 e2)
        <|> pure e1
    addop = (symbol "+" >> pure Plus) <|> (symbol "-" >> pure Minus)

-- term ::= factor (mulop factor)*
termP :: Parser Expr
termP = token (factorP >>= more)
  where
    more e1 = do
        p <- mulop
        e2 <- factorP
        more (Bin p e1 e2)
        <|> pure e1
    mulop = (symbol "*" >> pure Mul) <|> (symbol "/" >> pure Div)

-- factor ::= nat | "(" expr ")"
factorP :: Parser Expr
factorP = token (constant <|> paren exprP)
  where
    constant = do
        n <- some digitP
        pure (Con (foldl (\m d -> 10 * m + d) 0 n))
    paren p = do
        symbol "("
        e <- p
        symbol ")"
        pure e

-- ═══ 21.8 求值（Either 一条到底：除零/语法错都是 Left）
evalE :: Expr -> Either String Int
evalE (Con n) = Right n
evalE (Bin op e1 e2) = do
    v1 <- evalE e1
    v2 <- evalE e2
    case op of
        Plus -> Right (v1 + v2)
        Minus -> Right (v1 - v2)
        Mul -> Right (v1 * v2)
        Div
            | v2 == 0 -> Left "除零"
            | otherwise -> Right (v1 `div` v2)

runExpr :: String -> Either String Int
runExpr s = case parseFirst exprP s of
    Just (e, "") -> evalE e -- 剩余输入必须为空：整串都被吃掉
    Just (_, rest) -> Left ("语法错误：多余的输入 " ++ show rest)
    Nothing -> Left "语法错误：无法解析"

-- ═══ 21.9 显示：show 是解析之逆（书11.5 的 showsPrec）
prec :: Op -> Int
prec Mul = 2
prec Div = 2
prec Plus = 1
prec Minus = 1

showsPrecE :: Int -> Expr -> String -> String
showsPrecE _p (Con n) = showString (show n)
  where
    showString = (++)
showsPrecE p (Bin op e1 e2) = showParenL (p > q) (showsPrecE q e1 . showSpace . showOp op . showSpace . showsPrecE (q + 1) e2)
  where
    q = prec op
    showParenL True s = ('(' :) . s . (')' :)
    showParenL False s = s
    showSpace = (' ' :)
    showOp Plus = ('+' :)
    showOp Minus = ('-' :)
    showOp Mul = ('*' :)
    showOp Div = ('/' :)

instance Show Expr where
    show e = showsPrecE 0 e "" -- 父上下文按优先级 0：顶层不加括号
