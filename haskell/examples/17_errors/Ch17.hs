-- Ch17 库模块：错误处理——Either 模式、try/catch、throw 惰性、evaluate、bracket、自定义异常
module Ch17
    ( AppError(..), parseAge, ageOrDefault, describeAge
    , Boom(..), divideOrThrow
    , runBracketDemo
    ) where

import Control.Exception (Exception, bracket, throw, throwIO, try)
import System.Directory (doesFileExist, removeFile)

-- ═══ 17.1 纯错误：ADT + Either（可测试、全量值语义）
data AppError = NotAnInt String | OutOfRange Int
    deriving (Show, Eq)

parseAge :: String -> Either AppError Int
parseAge s = case reads s of
    [(n, "")] | n >= 0 && n <= 150 -> Right n
              | otherwise          -> Left (OutOfRange n)
    _                              -> Left (NotAnInt s)

ageOrDefault :: String -> Int
ageOrDefault = either (const 0) id . parseAge          -- either 组合子：左右各有处理

describeAge :: String -> String
describeAge s = either showE (("年龄 " ++) . show) (parseAge s)
  where
    showE (NotAnInt raw) = "不是整数: " ++ show raw
    showE (OutOfRange n) = "超出范围: " ++ show n

-- ═══ 17.2 自定义异常类型（IO 世界）：Show + Exception 实例即可 throw/try
data Boom = Boom String
    deriving (Show)

instance Exception Boom

-- ═══ 17.3 throw 的惰性陷阱：纯代码里的 throw 只是"埋雷"，不强制就不炸
divideOrThrow :: Int -> Int -> Int
divideOrThrow _ 0 = throw (Boom "纯代码里的除零")
divideOrThrow a b = a `div` b

-- ═══ 17.4 bracket 三段式：申请 → 使用 → 释放（无论成功失败，释放必跑）
runBracketDemo :: IO (String, Bool)
runBracketDemo = do
    let p = "bracket_demo.tmp"
    r <- try (bracket
                (writeFile p "初始化")          -- 申请：建资源
                (\_ -> removeFile p)            -- 释放：异常路径也会执行
                (\_ -> throwIO (Boom "中途失败")))  -- 使用：这里故意失败
            :: IO (Either Boom ())
    gone <- not <$> doesFileExist p
    pure (either (const "中途失败已捕获") (const "不该成功") r, gone)
