# 24 · 实战：MiniLang 迷你解释器 ⭐

> 对应示例：`examples/24_capstone/`（stack 工程：src 库 + app 入口 + test 三层测试）

## 24.1 我们要造什么

一门小语言：整数/布尔/字符串、算术与比较、let（递归绑定）、lambda 与闭包、if、调用、序列、
六个内建函数——词法、语法、求值三层管线各司其职，最后套一个 REPL。

```
源码文本 ──Parser.hs──→ Expr（AST） ──Eval.hs──→ Value（含打印副作用）
                Ast.hs 定义两侧的数据
```

选解释器做压轴的理由：它是"ADT × 模式匹配 × 递归 × 单子 × parsec"的集大成——07/06/09/13/15
章每一件武器都在这里上桌。

## 24.2 Ast.hs：两个 ADT 定下全语言

```haskell
data Expr
    = EInt Integer | EBool Bool | EStr String
    | EVar String
    | EBin BinOp Expr Expr
    | EIf Expr Expr Expr
    | ELet String Expr Expr          -- let 名 = 值 in 主体
    | ELam String Expr               -- \参数 -> 体
    | EApp Expr Expr                 -- 调用（柯里化靠嵌套）
    | ESeq Expr Expr                 -- a; b
    deriving (Show, Eq)

data Value
    = VInt Integer | VBool Bool | VStr String | VUnit
    | VClos String Expr Env          -- 闭包 = 参数 + 体 + 定义时环境
    | VPrim String (Value -> IO (Either String Value))
```

`Value` 含函数字段派生不了 Eq/Show 的默认实例——自定义 `show`（闭包显示 `<fn \x -> …>`）
与 `show` 语义的 `Eq`（24 章实测第一课）。

## 24.3 Parser.hs：词法层 + 优先级表

词法层 = 15 章的 lexeme 族（吃空白、关键字边界 `notFollowedBy`）；语法层 =
buildExpressionParser：

```haskell
table =
    [ [op "*" Mul, op "/" Div]                    -- ← 先紧后松！
    , [op "+" Add, op "-" Sub]
    , [op "<=" Le, op ">=" Ge, op "<" Lt, op ">" Gt]
    , [op "==" EqEq]
    , [op "&&" And]
    , [op "||" Or]
    , [op ";" ESeq AssocRight]                    -- 最松
    ]
```

两个开发现场（都写进了代码注释）：

- **表序写反**：第一版把 `;` 放第一行（以为"最低"），结果 `else` 分支把后续语句整段吞掉——
  buildExpressionParser 的表是**先紧后松**；
- **symbol 必须 try**：`"<="` 吃掉 `"<"` 后失败不回退，`"<"` 分支永远轮不上。

## 24.4 Eval.hs：词法作用域 + 递归绑定打结

求值单子：`type Eval a = ExceptT String IO a`（错误走左、print 走 IO——14 章的叠加态）。

环境是**纯 Map 随闭包捕获**（不是全局 State——那会变成动态作用域）：

```haskell
evalExpr env (ELam p body)  = pure (VClos p body env)        -- 捕获"定义时"环境

evalExpr env (ELet x e1 e2) = case e1 of
    ELam p body ->
        let env' = insert x (VClos p body env') env          -- 惰性闭环：fact 引用自己
        in evalExpr env' e2
    _ -> do v <- evalExpr env e1                             -- 非 lambda：先求值再绑定
            evalExpr (insert x v env) e2
```

递归 let 靠**惰性打结**：`env'` 的定义里引用 `env'` 自己（10 章自引用的实战出场）。
词法作用域的试金石（test 里的名题）：

```
let x = 10 in let f = \y -> x + y in let x = 0 in f 5     -- ⇒ 15（不是 5！）
```

## 24.5 内建函数

```haskell
builtins = M.fromList
    [ ("print", VPrim "print" $ \v -> putStrLn (display v) >> pure (Right VUnit))
    , ("str",   VPrim "str" $ pure . Right . VStr . show)
    , ("abs", …), ("min", …), ("max", …), ("strlen", …) ]
```

min/max 用柯里化内建（两层 VPrim）——参数一个一个来，与用户函数同一套调用协议。

## 24.6 Repl 与入口

```haskell
putStr "mini> "; hFlush stdout          -- 坑：提示符不换行，不 flush 看不到
result <- case parseMini "<repl>" line of
    Left err -> pure (Left (…))
    Right e  -> runExceptT (evalExpr emptyEnv e)
```

`minilang demo`（内置演示）/ `minilang 文件.ml` / 无参 REPL。演示程序全特性一网打尽：

```
16
fact 10 = 3628800
strlen = 8
比较成立
⇒ 9
```

## 24.7 三层测试 + 性质层

test/Spec.hs：

- **解析层**（11 例）：字符串 → AST 逐构造子断言（优先级/左结合/lambda/let/if/应用链/序列/
  烂输入/关键字边界）；
- **求值层**（15 例）：程序 → 值（递归 fact/fib、柯里化、遮蔽、**词法作用域名题**、+ 重载、
  序列取末值、min/max）；
- **错误层**（5 例）：未绑定/类型不配/除零——断言错误消息前缀；
- **性质层**：xorshift 生成 30 个随机算术表达式，断言**两次求值逐位一致**（确定性）。

## 24.8 扩展练习

1. 浮点与负数字面量（`EFloat`、一元减）；
2. REPL 环境跨行延续（`it` 绑定上一行值）；
3. 列表类型与 `map`（新的 Value 构造子 + 内建）；
4. 尾调用优化（Eval 里 EApp 尾位置的跳转化）；
5. 用 18 章 TH 生成 Expr 的 pretty-printer。

## 24.9 坑位清单

1. **buildExpressionParser 表序先紧后松**：写反语法照过、结构错位——AST 断言兜底（24.3）。
2. **symbol 配 try**：前缀共享的运算符（<= vs <）不回退就死（24.3）。
3. **mtl 2.3 不转出口 throwE**：用 `throwError`；transformers 是隐藏包、直接 import 报错
   （24.4，cabal 里显式 build-depends 才行）。
4. **惰性 else 贪食**：`;` 最松意味着 else 分支会吞掉后续语句——演示里给 if 加括号（24.6）。
5. **含函数字段的 ADT**：手写 Show/Eq——派生不了（24.2）。
