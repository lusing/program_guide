# 15 · 解析器组合子 parsec ⭐

> 对应示例：`examples/15_parsec/`（24 章 MiniLang 的直系前置）

## 15.1 Parser 也是普通值

parsec（boot 库）把"解析器"做成可组合的值——小解析器拼成大解析器：

```haskell
type Parser = Parsec String ()            -- 自建别名（Text.Parsec.String 是历史模块）

lexeme p = p <* spaces                    -- 词法包装：吃掉尾随空白
symbol s  = lexm (string s)
natural   = lexeme (read <$> many1 digit)
identifier = lexeme ((:) <$> letter <*> many (alphaNum <|> char '_'))
```

## 15.2 try 与回溯边界

`<|>` 的语义：左边**没消费输入**失败才试右边。消费到一半失败就整体失败——`try` 把"消费"变
"可撤销"：

```haskell
-- 经典场景：let vs lex（前缀共享）
keyword kw = lexeme (try (string kw <* notFollowedBy alphaNum))
```

**实测坑（24 章开发现场）**：`symbol "<="` 没有 try 时，匹配 `"< 5"` 会吃掉 `<` 后失败且不回退，
`"<"` 分支永远轮不上——**含前缀共享的运算符表必须 try**。

## 15.3 buildExpressionParser：优先级表驱动

```haskell
parseExpr src = parse (spaces *> expression <* eof) "表达式" src
  where
    expression = buildExpressionParser table term
    table =
        [ [op "*" Mul, op "/" Div]        -- ← 先紧后松！第一行绑得最紧
        , [op "+" Add, op "-" Sub]
        ]
    op name con = Infix (try (symbol name) >> pure con) AssocLeft
    term = parens expression <|> (Lit <$> natural)
```

**实测坑**：表序是**先紧后松**（第一行优先级最高）——按直觉写"从低到高"会得到诡异结构
（`3 < 5 && 2 == 2` 解析成 `3 < (5 && …)`）。AST 断言（runtests）就是防它的。

## 15.4 AST 与求值分离

解析产出 ADT，求值是纯函数——测试可以分层打（24 章三件套的前身）：

```haskell
data Expr = Lit Integer | Add Expr Expr | Sub Expr Expr
          | Mul Expr Expr | Div Expr Expr deriving (Show, Eq)

evalExpr :: Expr -> Either String Integer
evalExpr (Lit n)   = Right n
evalExpr (Add a b) = (+) <$> evalExpr a <*> evalExpr b    -- Applicative 组合错误
evalExpr (Div a b) = do
    x <- evalExpr a
    y <- evalExpr b
    if y == 0 then Left "除数为零" else Right (x `div` y)
```

**实测坑**：嵌套除零要靠 do 链传播——手写 `case` 版本漏掉一侧分支就吞错（开发中真踩）。

## 15.5 错误汇流

`ParseError` 与 `String` 是两种错误，`Either` 里要汇流：

```haskell
calc :: String -> Either String Integer
calc src = either (Left . show) evalExpr (parseExpr src)   -- 先把 ParseError 转 String
```

## 15.6 坑位清单

1. **Text.Parsec 不转出口 Expr 模块**（3.1.17 实测）：`buildExpressionParser`/`Infix`/`Assoc`
   要 `import Text.Parsec.Expr` 单独导（15.3）。
2. **优先级表先紧后松**：第一行最紧——写反了语法照过、结构错位（15.3）。
3. **符号匹配配 try**：`<=` 吃掉 `<` 不回退坑前缀共享的运算符（15.2）。
4. **eof 显式收尾**：`parse` 不自动检查输入耗尽——`1 2`（尾随垃圾）不过 eof 就是合法解析（15.3）。
5. **两种错误不能直接 >>=**：`Either ParseError` 与 `Either String` 先映射统一（15.5）。
