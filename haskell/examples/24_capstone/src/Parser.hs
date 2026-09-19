-- Parser：MiniLang 语法分析——parsec 词法层（lexeme 族）+ 运算符优先级表
module Parser
    ( parseMini
    ) where

import Ast
import Data.Char (isAlphaNum, isDigit)
import Text.Parsec
    (Parsec, ParseError, SourceName, (<|>), between, eof, letter, many, many1, notFollowedBy,
     parse, satisfy, spaces, string, try)
import Text.Parsec.Expr (Assoc (AssocLeft, AssocRight), Operator (Infix), buildExpressionParser)

type P = Parsec String ()

-- ═══ 词法层：所有词法组合子都"吃掉尾随空白"（15 章的 lexeme 套路）
lexm :: P a -> P a
lexm p = p <* spaces

-- 坑：必须 try——"<=" 匹配失败时已吃掉 '<'，不回退的话 "<" 分支永远轮不上
symbol :: String -> P String
symbol s = lexm (try (string s))

natural :: P Integer
natural = lexm (read <$> many1 (satisfy isDigit))

identChar :: P Char
identChar = satisfy (\c -> isAlphaNum c || c == '_')

identifier :: P String
identifier = lexm ((:) <$> letter <*> many identChar)

-- 字符串字面量："…"（教学版：不支持转义）
stringLiteral :: P String
stringLiteral = lexm (between (string "\"") (string "\"") (many (satisfy (/= '"'))))

keywords :: [String]
keywords = ["let", "in", "if", "then", "else", "true", "false"]

-- 关键字不是标识符：identifier 吃到关键字要退回（try + 预看）
kwIdent :: P String
kwIdent = try $ do
    s <- identifier
    if s `elem` keywords
        then fail ("关键字不能当标识符: " ++ s)
        else pure s

-- 关键字匹配必须看到"非标识符字符"边界——否则 let 会吞掉 lets 的前三个字母
keyword :: String -> P String
keyword kw = lexm (try (string kw <* notFollowedBy identChar))

-- ═══ 语法层：运算符优先级表（低 → 高）
parseMini :: SourceName -> String -> Either ParseError Expr
parseMini name src = parse (spaces *> expression <* eof) name src
  where
    expression = buildExpressionParser table term

    -- 坑：buildExpressionParser 的表「先紧后松」——第一行反而绑得最紧！
    table =
        [ [op "*" (EBin Mul) AssocLeft, op "/" (EBin Div) AssocLeft]  -- 最紧：乘除
        , [op "+" (EBin Add) AssocLeft, op "-" (EBin Sub) AssocLeft]
        , [op "<=" (EBin Le) AssocLeft, op ">=" (EBin Ge) AssocLeft,
           op "<" (EBin Lt) AssocLeft, op ">" (EBin Gt) AssocLeft]
        , [op "==" (EBin EqEq) AssocLeft]
        , [op "&&" (EBin And) AssocLeft]
        , [op "||" (EBin Or) AssocLeft]
        , [op ";" ESeq AssocRight]                                  -- 最松：序列
        ]

    op name con = Infix (symbol name >> pure con)

    -- 项：前缀形式（let/if/lambda）或应用链
    term = letP <|> ifP <|> lamP <|> appP

    letP = do
        _ <- keyword "let"
        x <- kwIdent
        _ <- symbol "="
        e1 <- expression
        _ <- keyword "in"
        e2 <- expression
        pure (ELet x e1 e2)

    ifP = do
        _ <- keyword "if"
        c <- expression
        _ <- keyword "then"
        t <- expression
        _ <- keyword "else"
        e <- expression
        pure (EIf c t e)

    lamP = do
        _ <- symbol "\\"
        p <- kwIdent
        _ <- symbol "->"
        ELam p <$> expression

    -- 应用链：f a b = (f a) b，左结合；参数是原子（不再吃应用，天然左结合）
    appP = do
        f <- atom
        as <- many atomArg
        pure (foldl EApp f as)

    atomArg = atom

    atom = intLit <|> strLit <|> boolLit <|> var <|> parens
    intLit = EInt <$> natural
    strLit = EStr <$> stringLiteral
    boolLit = (EBool True <$ keyword "true") <|> (EBool False <$ keyword "false")
    var = EVar <$> kwIdent
    parens = between (symbol "(") (symbol ")") expression
