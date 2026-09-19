-- Repl：交互式循环——逐行"解析→求值→打印"，:quit 退出、:env 列内建名
module Repl
    ( runRepl
    ) where

import Ast (Expr)
import Control.Monad.Except (runExceptT)
import Data.Map.Strict (toList)
import Eval (emptyEnv, evalExpr)
import Parser (parseMini)
import System.IO (hFlush, isEOF, stdout)

runRepl :: IO ()
runRepl = loop
  where
    loop = do
        putStr "mini> "
        hFlush stdout                 -- 坑：提示符不带换行，必须手动冲缓冲
        done <- isEOF
        if done
            then putStrLn ""
            else do
                line <- getLine
                case line of
                    ":quit" -> putStrLn "再见"
                    ":env"  -> do
                        mapM_ (putStrLn . ("  " ++)) (map fst (toList emptyEnv))
                        loop
                    _ -> do
                        result <- case parseMini "<repl>" line of
                            Left err -> pure (Left ("解析错误: " ++ show err))
                            Right e  -> runExceptT (evalExpr emptyEnv e)
                        case result of
                            Left msg -> putStrLn msg >> loop
                            Right v  -> print v >> loop
