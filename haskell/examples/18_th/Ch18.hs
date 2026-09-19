-- Ch18 库模块：编译期魔法——Template Haskell 引号/拼接/reify、GHC.Generics 一瞥
-- 坑：TH 拼接不能引用同模块的定义（阶段限制）——本模块的拼接只用 Prelude 与字面量
{-# LANGUAGE TemplateHaskell #-}

module Ch18
    ( answer, typedAnswer, maybeCons, compileTimeTable, nameBaseOf
    , Rec(..), recTypeName
    ) where

import Language.Haskell.TH
    (Dec (DataD), Info (TyConI), Name, integerL, litE, nameBase, reify)
import Language.Haskell.TH.Syntax (lift)   -- lift（Lift 类方法）在 Syntax 子模块
import GHC.Generics (Datatype (datatypeName), Generic (..))

-- ═══ 18.1 表达式引号 [| … |] 与拼接 $( … )：编译期先算好
answer :: Int
answer = $( [| 40 + 2 |] )          -- 编译时求值为字面量 42，运行时零计算

-- typed TH：[|| … ||] 带类型检查的引号（9.x 起稳定），用 $$ 拼接
-- 坑（9.12 实测）：$$ 必须紧贴括号——"$$ (" 带空格直接 parse error（$ 无此限制）
typedAnswer :: Int
typedAnswer = $$( [|| 41 + 1 ||] )

-- ═══ 18.2 reify：向编译器询问类型的元信息（Maybe 有几个构造子？）
maybeCons :: Int
maybeCons = $( do
    info <- reify ''Maybe                    -- 拿到 Maybe 的抽象语法描述
    case info of
        TyConI (DataD _ _ _ _ cons _) -> litE (integerL (fromIntegral (length cons)))
        _                                 -> fail "不是数据类型" )

-- ═══ 18.3 lift：把 Haskell 值在编译期"抬"进表达式（常量表预生成）
compileTimeTable :: [Int]
compileTimeTable = $( lift (map (^ 2) [1 .. 8 :: Int]) )    -- 编译期算好 [1,4,9,…64]

-- ═══ 18.4 类型引号 ''T 与 nameBase（取不带模块前缀的名字）
nameBaseOf :: Name -> String
nameBaseOf = nameBase

-- ═══ 18.5 GHC.Generics：deriving Generic 白拿结构自省（不用写一行模板代码）
data Rec = Rec { ra :: Int, rb :: String }
    deriving (Show, Eq, Generic)

recTypeName :: Rec -> String
recTypeName r = datatypeName (from r)      -- "Rec"——来自 Generic 派生的元信息
