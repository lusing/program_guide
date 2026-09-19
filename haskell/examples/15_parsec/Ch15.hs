-- Ch15 库模块：解析器组合子——基本组合子、try 与回溯、buildExpressionParser 表达式表
module Ch15
    ( Parser
    , lexeme, symbol, natural, identifier, keyword
    , Expr(..), evalExpr
    , parseExpr, calc
    , parsePair, parseKeyValues
    ) where

import Text.Parsec
    (Parsec, ParseError, (<|>), alphaNum, char, digit, eof, letter, many, many1,
     notFollowedBy, parse, spaces, string, try)
import Text.Parsec.Expr (Assoc (AssocLeft), Operator (Infix), buildExpressionParser)

type Parser = Parsec String ()             -- 不用 Text.Parsec.String（历史模块，自建类型别名更稳）

-- ═══ 15.1 词法包装：跳过尾随空白（"吃空白"统一放词法层）
lexeme :: Parser a -> Parser a
lexeme p = p <* spaces

symbol :: String -> Parser String
symbol s = lexeme (string s)

natural :: Parser Integer
natural = lexeme (read <$> many1 digit)

identifier :: Parser String
identifier = lexeme ((:) <$> letter <*> many (alphaNum <|> char '_'))

-- 关键字 vs 标识符：let 不是 lex 的前缀匹配——try + notFollowedBy
keyword :: String -> Parser String
keyword kw = lexeme (try (string kw <* notFollowedBy alphaNum))

-- ═══ 15.2 AST 与求值（24 章 MiniLang 的雏形）
data Expr
    = Lit Integer
    | Add Expr Expr
    | Sub Expr Expr
    | Mul Expr Expr
    | Div Expr Expr
    deriving (Show, Eq)

evalExpr :: Expr -> Either String Integer
evalExpr (Lit n)   = Right n
evalExpr (Add a b) = (+) <$> evalExpr a <*> evalExpr b
evalExpr (Sub a b) = (-) <$> evalExpr a <*> evalExpr b
evalExpr (Mul a b) = (*) <$> evalExpr a <*> evalExpr b
evalExpr (Div a b) = do
    x <- evalExpr a
    y <- evalExpr b
    if y == 0 then Left "除数为零" else Right (x `div` y)   -- 嵌套除零也要传播（do 记法串 Either）

-- ═══ 15.3 表达式解析器：运算符表驱动优先级（中缀 > 括号/整数）
parseExpr :: String -> Either ParseError Expr
parseExpr src = parse (spaces *> expression <* eof) "表达式" src
  where
    expression = buildExpressionParser table term
    table =
        [ [op "*" Mul, op "/" Div]        -- 先结合（优先级高）
        , [op "+" Add, op "-" Sub]        -- 后结合（优先级低）
        ]
    op name con = Infix (symbol name >> pure con) AssocLeft
    term = parens expression <|> (Lit <$> natural)
    parens p = symbol "(" *> p <* symbol ")"

-- 解析 + 求值一条龙（ParseError 先转成 String，两种错误才能在 Either String 里汇流）
calc :: String -> Either String Integer
calc src = either (Left . show) evalExpr (parseExpr src)

-- ═══ 15.4 组合子拼装：结构化小数据
parsePair :: String -> Either ParseError (String, Integer)
parsePair src = parse (spaces *> p <* eof) "键值对" src
  where
    p = (\k _ v -> (k, v)) <$> identifier <*> symbol "=" <*> natural

parseKeyValues :: String -> Either ParseError [(String, Integer)]
parseKeyValues src = parse (spaces *> p <* eof) "键值表" src
  where
    p = many1 (pair <* spaces)
    pair = (\k _ v -> (k, v)) <$> identifier <*> symbol "=" <*> natural
