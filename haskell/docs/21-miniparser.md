# 21 · 手写解析器组合子 ⭐

> 对应示例：`examples/21_miniparser/`（Ch21.hs + main.hs + runtests.hs）。
> 本章对应原书第 11 章〈句法分析〉——`newtype Parser`、基本组合子、选择与重复、
> 表达式文法与优先级、`showsPrec` 反向编码，全部提炼并全部可跑。22 章 parsec 库是
> 本章成品的工业化版本；31 章 MiniLang 用它解析完整语言。

## 21.1 解析器是什么：类型的三步进化

**解析器**（parser）= 吃文本、吐"逻辑结构"的函数。先看 `read` 为什么不够格：

```
ghci> read "123"    :: Int     -- 123   ✓ 但整串必须全部吃掉
ghci> read "123+51" :: Int     -- *** Exception: no parse
```

`read :: Read a => String -> a` 是"全有或全无"。而真正的解析是**接力**的：先认一个数、
再认一个运算符、再认一个数——每步吃掉一个**前缀**。于是类型进化第一步：

```haskell
type Parser a = String -> (a, String)      -- 吃前缀，产值 + 剩余
```

第二步：**失败是常态**（"找数字或左括号"必然有一支失败），失败不该是错误，而该是
"选择的单位元"；更一般地，一个输入可能有**多种**解析。把结果做成列表——空表即失败：

```haskell
type Parser a = String -> [(a, String)]    -- Prelude 的 Reads a 正是这个类型
```

第三步：类型同义词不能做类型类实例（它没造新类型），要进 `Monad` 就得**newtype**：

```haskell
newtype Parser a = Parser { applyP :: String -> [(a, String)] }
```

`newtype` 与 `data` 的区别在此兑现：单构造子单字段，编译器**擦掉包装、零运行时开销**，
且与底层类型严格同构（`Parser undefined` 与 `undefined` 同一个 ⊥）；又与 type 同义词
不同——它有权定义**自己的**类型类实例。

## 21.2 单子与选择：两个实例撑起一切

`Monad` 实例一行一个读点（完整代码见 Ch21.hs）：

```haskell
instance Monad Parser where
    pure x  = Parser (\s -> [(x, s)])              -- 不吃输入，直接产值
    p >>= q = Parser $ \s ->
        [ (y, s2) | (x, s1) <- applyP p s          -- 先跑 p
                  , (y, s2) <- applyP (q x) s1 ]   -- 每个成功分支各跑 q，全部串联
```

`(>>=)` 的语义是**顺序与接力**：p 吃掉的前缀，q 从剩余继续。列表把"p 的每个可能结果"
展开成"多世界"——这正是 18 章列表单子的天赋再用一次。**失败自动传播**：p 给空表，
整个推导式就是空表。

选择靠 `Alternative`（失败的单位元 + 或运算）：

```haskell
instance Alternative Parser where
    empty = Parser (const [])                    -- 书里的 fail：空解
    p <|> q = Parser $ \s ->
        case applyP p s of [] -> applyP q s       -- p 失败才试 q
                        r  -> r
```

`<|>` 满足结合律、单位元是 `empty`——与 `many/some`（Alternative 的默认方法）配合，
一个小型解析库就齐了。**单子律对 Parser 成立**（21.9 练习 1 让你证 `fail >> p = fail`）。

## 21.3 基本组合子：sat 与它的一家子

最底层只有一个"读一个字符"：

```haskell
getc = Parser f
  where f (c:cs) = [(c, cs)]        -- 空/⊥ 输入 → 空解/⊥
        f []      = []

sat p = do c <- getc               -- saturate：读一个满足条件的字符
           if p c then pure c else empty
```

`sat` 之上十行内长出一家人：

```haskell
char x   = sat (== x) >> pure ()                 -- 认特定字符（结果无价值 → ()）
string xs = sequence_ (map char xs)              -- 认特定串
digitP   = fromEnum <$> sat isDigit >>= \d -> pure (d - fromEnum '0')
lowls    = many (sat isLower)                    -- many：重复 0+ 次（Alternative 默认）
spaces   = many (sat isSpace) >> pure ()         -- 空白
symbol xs = spaces >> string xs                  -- 跳空白后认串
token p  = spaces >> p                           -- 跳空白后跑 p
```

实录（Ch21 main 实测输出）：

```
applyP (string "hell") "hello"   =  [((), "o")]      -- 吃掉 4 字符
applyP lowls "isUpper"           =  [("is", "Upper")] -- 尽量多吃
applyP lowls "Upper"             =  [("", "Upper")]   -- many 允许零次
```

`token p <|> token q = token (p <|> q)` 成立但右边更高效——左边失败时右边要**重扫一遍
空白**。定律不但保正确，还指认省力的写法。

## 21.4 选择陷阱：wrong、better 与 best

**选择顺序是语义**。认"一位数，或 数字+加号+数字"：

```haskell
wrong = plainDigit <|> addition          -- digit 在前：永远轮不到加法
-- applyP wrong "1+2"  =  [(1, "+2")]   ← 只吃了个 1！
```

`<|>` 是"p 成功就不看 q"——前缀更短的分支把更长的**遮蔽**（shadow）了。交换顺序
（`better = addition <|> plainDigit`）结果对但低效：加法失败后数字要从头再认一遍。
**正解是提取公共前缀 + 累积参数**：

```haskell
best = digitP >>= rest
  where rest m = do { char '+'; n <- digitP; rest (m + n) }
                 <|> pure m
-- applyP best "1+2+3" = [(6, "")]     ← 全吃，且每个字符只认一次
```

数字只认一次，"+"能接多长接多长——与 11 章 `rest` 的累积参数完全同构（那里的
`mss`、这里的 `best`，同一条性能咒语）。

## 21.5 负号的函数技巧与 token 库

自然数：`some digitP`（至少一位）折成整数；整数要处理可选负号。直白的
`(symbol "-" >> natural >>= pure . negate) <|> natural` 低效（负号失败要重扫）且
语义松（`- 34` 数字与负号间允许空白？）。原书的正解——**让"负号可选"返回一个函数**：

```haskell
integer = do { spaces; f <- minus; n <- nat; pure (f n) }
  where minus = (char '-' >> pure negate) <|> pure id    -- negate 或 id
```

`parseFirst integer "-34"` 得 `Just (-34, "")`、`integer "+4"` 失败——一个分支扫描，
没有回溯。

## 21.6 表达式文法：BNF 到解析器的直译

目标：四则运算、乘除优先、同级左结合。先写**文法**（BNF）：

```
expr   ::= term (addop term)*          -- 加减层
term   ::= factor (mulop factor)*      -- 乘除层（优先级高）
factor ::= nat | "(" expr ")"          -- 原子层
```

文法到解析器**逐行直译**（Ch21 的 `exprP/termP/factorP`）：

```haskell
exprP   = token (termP >>= rest)         -- rest 是 "(addop term)*" 的累积参数版
  where rest e1 = do { p <- addop; e2 <- termP; rest (Bin p e1 e2) }
                  <|> pure e1

termP   = token (factorP >>= more)      -- 同构的一层，优先级低半档
  where more e1 = do { p <- mulop; e2 <- factorP; more (Bin p e1 e2) }
                  <|> pure e1

factorP = token (constant <|> paren exprP)
```

**左递归是文法直接直译的天敌**：`expr ::= expr addop term | term` 直译成
`expr = binary <|> term`（binary 先调 expr）会**无限循环**；改成
`expr = term >>= rest`（星号形式 + 累积参数）绕开。这一改写正是 21.4 `best` 的文法版。

左结合性由 `rest` 的折叠方向天然保证（实测）：

```
runExpr "1+2*3"   = Right 7      优先级
runExpr "(1+2)*3" = Right 9      括号覆盖
runExpr "6-2-3"   = Right 1      左结合：6-2-3 是 (6-2)-3
runExpr "8/2/2"   = Right 2      左结合
runExpr "1+"      = Left "多余的输入 \"+\""     部分解析 ≠ 全失败
runExpr "1/0"     = Left "除零"                  解析成功、求值失败——分层报错
```

错误分层值得点破：**语法错误**（吃不完/认不出）与**语义错误**（除零）走两条通道——
`runExpr` 用 `Either String Int` 一条到底，29/31 章的计算器与解释器沿用此设计。

## 21.7 显示：show 是解析之逆

解析产树，显示把树变回文本。目标（原书 11.5）：**`parse expr (show e) = e`**——
显示与解析互逆。朴素 `show` 用 `(++)` 拼接是**二次方**（`++` 代价在左参数——09 章），
正解是差分链 `ShowS = String -> String`：

```haskell
showsPrecE :: Int -> Expr -> ShowS        -- ShowS = String -> String
showsPrecE _ (Con n)     = showString (show n)      -- 常数永不加括
showsPrecE p (Bin op e1 e2)
  = showParen (p > q)                             -- 父优先级更高才加括
      (showsPrecE q e1 . showSpace . showOp op
                  . showSpace . showsPrecE (q+1) e2)
  where q = prec op                                -- Mul/Div=2，Plus/Minus=1
```

两个精妙点：**优先级参数 p** 记录"父亲的优先级"，决定自己要不要戴括号；**右孩子用
q+1**——左结合运算符下，同级的右孩子必须加括（`6 - (2 - 3)`），左孩子不必
（`6 - 2 - 3`）。这正是标准库 `Show` 类第二个方法 `showsPrec` 的由来——`show` 的
默认定义就是 `showsPrec 0`。runtests 断言往返律与一组最少括号样例
（`(1 + 2) * 3`、`1 + 2 * 3`、`6 - (2 - 3)`、`2 * (9 / 3)`）。**解析与显示是一枚
硬币的两面**——26 章优美打印把这个主题推到极致。

## 21.8 坑位清单

1. **`<|>` 的分支遮蔽**：短前缀分支在前会饿死长分支（`digit <|> addition` 只吃一个
   数字）——提取公共前缀 + 累积参数（21.4，实测 `applyP wrong "1+2" = [(1,"+2")]`）。
2. **左递归文法直译死循环**：`expr ::= expr … | …` 必须改写成 `term (op term)*` 星号
   形式再直译（21.6）。
3. **token 重复扫空白**：`token p <|> token q` 合法但低效——提公共 `token (p <|> q)`
   （21.3）。
4. **部分解析 ≠ 解析失败**：`"1+"` 是 `Just`（吃掉 1 剩 "+"）——判断"整串合法"必须
   检查剩余输入为空（`runExpr` 的做法）（21.6）。
5. **deriving 与手写 Show 打架**：`deriving (Eq, Show)` 与手写 `instance Show Expr`
   并存报 Overlapping instances——手写时从 deriving 里删掉（实测）。
6. **`(>>=)` 里记得先 `q x` 再 apply**：`applyP (q x) s1`——q 产解析器，先求值
   （实测编译错一次）。

## 21.9 练习（选自原书第 11 章习题）

**练习 21.1（定律）**：证 `fail >> p = fail`（fail 即 empty）；再证 `<|>` 满足结合律、
单位元是 empty。

**练习 21.2（Maybe 版解析器）**：把类型换成
`newtype Parser a = Parser (String -> Maybe (a, String))` 重写 Monad 实例——多义性
没了，回溯怎么办？（这正是 22 章 parsec 与很多工业解析库的选择。）

**练习 21.3（浮点数）**：设计识别 Haskell 浮点数的解析器：`3.14` 合法、`.314`
非法（小数点前必须有数字）、`3 . 4` 非法（点前后不许空白）。

**练习 21.4（pair 与 shunt）**：用 `many (pair addop term)` + `foldl shunt` 写出与
`rest` 等价的 expr——`shunt` 的类型是什么？为什么 `foldl` 对应左结合？

---

上一章：[20 错误处理](20-errors.md) ｜ 下一章：[22 parsec](22-parsec.md) ｜ 返回：[README](../README.md)
