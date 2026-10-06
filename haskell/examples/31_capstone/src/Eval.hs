-- Eval：求值器——纯环境传递（词法作用域）+ ExceptT String IO（print 等副作用）
module Eval
    ( runProgram, evalExpr, emptyEnv, builtins
    ) where

import Ast
import Control.Monad.IO.Class (liftIO)
import Control.Monad.Except (ExceptT, MonadError (throwError), runExceptT)
import Data.Map.Strict (Map, insert)
import qualified Data.Map.Strict as M

-- ═══ 求值单子：错误走 throwE，副作用走 liftIO
type Eval a = ExceptT String IO a

-- 词法作用域：环境是纯数据，闭包捕获"定义时"环境，调用时恢复
evalExpr :: Env -> Expr -> Eval Value
evalExpr _   (EInt n)       = pure (VInt n)
evalExpr _   (EBool b)      = pure (VBool b)
evalExpr _   (EStr s)       = pure (VStr s)
evalExpr env (EVar x)       = case M.lookup x env of
    Nothing -> throwError ("未绑定变量: " ++ x)
    Just v  -> pure v
evalExpr env (EBin op a b)  = evalBin env op a b
evalExpr env (EIf c t e)    = evalExpr env c >>= \v -> case v of
    VBool True  -> evalExpr env t
    VBool False -> evalExpr env e
    other       -> throwError ("if 条件须是布尔值，得到 " ++ show other)

-- let 两种语义：lambda 绑定 = 递归（环境打结）；其余 = 先求值再绑定
evalExpr env (ELet x e1 e2) = case e1 of
    ELam p body ->
        let env' = insert x (VClos p body env') env     -- 惰性闭环：fact 能引用自己
        in evalExpr env' e2
    _ -> do
        v <- evalExpr env e1
        evalExpr (insert x v env) e2

evalExpr env (ELam p body)  = pure (VClos p body env)
evalExpr env (EApp f a)     = do
    fv <- evalExpr env f
    av <- evalExpr env a
    applyValue fv av
evalExpr env (ESeq a b)     = evalExpr env a >> evalExpr env b

applyValue :: Value -> Value -> Eval Value
applyValue (VClos p body cenv) arg = evalExpr (insert p arg cenv) body
applyValue (VPrim _ f) arg         = either throwError pure =<< liftIO (f arg)
applyValue other _                 = throwError ("不可调用: " ++ show other)

-- ═══ 二元运算：整数算术、字符串拼接（+ 重载）、比较、布尔短路
evalBin :: Env -> BinOp -> Expr -> Expr -> Eval Value
evalBin env op a b = case op of
    And -> evalExpr env a >>= \va -> case va of
        VBool False -> pure (VBool False)               -- 短路：右侧不求值
        VBool True  -> evalExpr env b >>= wantBool op
        other       -> throwError ("&& 左侧须布尔，得到 " ++ show other)
    Or  -> evalExpr env a >>= \va -> case va of
        VBool True  -> pure (VBool True)                -- 短路
        VBool False -> evalExpr env b >>= wantBool op
        other       -> throwError ("|| 左侧须布尔，得到 " ++ show other)
    _   -> do
        va <- evalExpr env a
        vb <- evalExpr env b
        binop op va vb
  where
    wantBool :: BinOp -> Value -> Eval Value
    wantBool _ (VBool x) = pure (VBool x)
    wantBool o other     = throwError (describeOp o ++ " 右侧须布尔，得到 " ++ show other)

binop :: BinOp -> Value -> Value -> Eval Value
binop Add (VInt x) (VInt y)  = pure (VInt (x + y))
binop Add (VStr x) (VStr y)  = pure (VStr (x ++ y))     -- + 重载：字符串拼接
binop Sub (VInt x) (VInt y)  = pure (VInt (x - y))
binop Mul (VInt x) (VInt y)  = pure (VInt (x * y))
binop Div (VInt _) (VInt 0)  = throwError "除数为零"
binop Div (VInt x) (VInt y)  = pure (VInt (x `div` y))
binop o   (VInt x) (VInt y)  = pure (VBool (cmp o (compare x y)))
binop EqEq (VStr x) (VStr y) = pure (VBool (x == y))
binop o   (VStr x) (VStr y)
  | o == Lt || o == Le || o == Gt || o == Ge = pure (VBool (cmp o (compare x y)))
binop o   x y                = throwError ("类型不配: " ++ describeOp o ++ " " ++ show x ++ " " ++ show y)

cmp :: BinOp -> Ordering -> Bool
cmp Lt LT   = True
cmp Le LT   = True
cmp Le EQ   = True
cmp Gt GT   = True
cmp Ge GT   = True
cmp Ge EQ   = True
cmp EqEq EQ = True
cmp _   _   = False

-- ═══ 内建函数（教学集：print/str/abs/min/max/strlen）
builtins :: Env
builtins = M.fromList
    [ ("print",  VPrim "print" $ \v -> do
          putStrLn (display v)
          pure (Right VUnit))
    , ("str",    VPrim "str" $ pure . Right . VStr . show)
    , ("abs",    VPrim "abs" $ \v -> case v of
          VInt n -> pure (Right (VInt (abs n)))
          other  -> pure (Left ("abs 须整数: " ++ show other)))
    , ("min",    VPrim "min" $ \v -> pure (Right
                   (VPrim "min#" (\w -> pure (Right (minmaxV min v w))))))
    , ("max",    VPrim "max" $ \v -> pure (Right
                   (VPrim "max#" (\w -> pure (Right (minmaxV max v w))))))
    , ("strlen", VPrim "strlen" $ \v -> case v of
          VStr s -> pure (Right (VInt (fromIntegral (length s))))
          other  -> pure (Left ("strlen 须字符串: " ++ show other)))
    ]
  where
    minmaxV f (VInt x) (VInt y) = VInt (f x y)
    minmaxV _ x _               = x
    display (VStr s) = s        -- 字符串直接显示，其余按 show
    display other    = show other

emptyEnv :: Env
emptyEnv = builtins

-- 顶层入口
runProgram :: Expr -> IO (Either String Value)
runProgram e = runExceptT (evalExpr emptyEnv e)
