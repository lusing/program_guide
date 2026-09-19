-- Ch02 库模块：02 章全部纯函数（main.hs 与 runtests.hs 共同复用）
module Ch02 (banner, greet, shout) where

import Data.List (intercalate)

-- ═══ 02.1 问候：空参容忍（getArgs 可能返回 []）
greet :: [String] -> String
greet []    = "你好，GHC！"                        -- 无参数：默认问候
greet names = "你好，" ++ intercalate "、" names ++ "！"   -- 多参数：顿号连接

-- ═══ 02.2 字符串加工：演示 ++ 与函数组合的最小样例
shout :: String -> String
shout s = s ++ "!"

banner :: String -> String
banner title = "==[ " ++ title ++ " ]=="
