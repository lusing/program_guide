-- Ast：MiniLang 的抽象语法树与值域——全语言的"数据定义"只有这两个 ADT
module Ast
    ( Expr(..), BinOp(..)
    , Value(..)
    , Env
    , describeOp
    ) where

import Data.Map.Strict (Map)

-- ═══ 表达式：和类型把"所有语法形态"列成一个表，模式匹配逐一处理（24 章核心）
data Expr
    = EInt Integer                       -- 字面量
    | EBool Bool
    | EStr String
    | EVar String                        -- 变量引用
    | EBin BinOp Expr Expr               -- 二元运算
    | EIf Expr Expr Expr                 -- if cond then a else b
    | ELet String Expr Expr              -- let 名 = 值 in 主体（支持递归绑定）
    | ELam String Expr                   -- \参数 -> 体
    | EApp Expr Expr                     -- 调用（柯里化靠嵌套）
    | ESeq Expr Expr                     -- a; b（先算 a 弃值，再算 b）
    deriving (Show, Eq)

data BinOp = Add | Sub | Mul | Div | Lt | Le | Gt | Ge | EqEq | And | Or
    deriving (Show, Eq)

describeOp :: BinOp -> String
describeOp op = case op of
    Add  -> "+";  Sub -> "-";  Mul -> "*";  Div -> "/"
    Lt   -> "<";  Le  -> "<="; Gt  -> ">";  Ge  -> ">="
    EqEq -> "=="; And -> "&&"; Or  -> "||"

-- ═══ 值域：解释器运行时里的"结果宇宙"
data Value
    = VInt Integer
    | VBool Bool
    | VStr String
    | VUnit
    | VClos String Expr Env              -- 闭包 = 参数 + 函数体 + 定义时环境（词法作用域）
    | VPrim String (Value -> IO (Either String Value))   -- 内建函数

-- Eq 按显示语义比较：含函数字段（闭包/内建）无法派生 Eq，
-- 显示串相同的值视为相等（测试只比较字面量结果，语义够用）
instance Eq Value where
    a == b = show a == show b

-- 环境：名字 → 值（containers 的严格 Map）
type Env = Map String Value

-- 自定义 Show：闭包与内建显示为可读标记（默认派生会倾泻整个环境）
instance Show Value where
    show (VInt n)          = show n
    show (VBool b)         = if b then "true" else "false"
    show (VStr s)          = "\"" ++ s ++ "\""
    show VUnit             = "()"
    show (VClos p _ _)     = "<fn \\" ++ p ++ " -> …>"
    show (VPrim n _)       = "<prim " ++ n ++ ">"
