-- Ch08 库模块：类型类——class/instance、超类、MINIMAL、约束多态、newtype 派生
-- 坑：`deriving newtype (...)` 语法需要 DerivingStrategies 扩展（默认不开）
{-# LANGUAGE DerivingStrategies #-}

module Ch08
    ( Describable(..)
    , Color(..), describeColor
    , Labeled(..), Tag(..)
    , Volume(..), Box(..)
    , Count(..)
    , scaleIt, halfOf
    ) where

-- ═══ 08.1 class 定义：一组行为的接口；方法可以有默认实现
class Describable a where
    describe :: a -> String
    describeTwice :: a -> String          -- 默认实现可以直接调用上面的方法
    describeTwice x = describe x ++ "，" ++ describe x

data Color = Red | Green | Blue deriving (Show, Eq)

instance Describable Color where
    describe Red   = "红"
    describe Green = "绿"
    describe Blue  = "蓝"

instance Describable Bool where
    describe True  = "真"
    describe False = "假"

describeColor :: Color -> String
describeColor = describe

-- ═══ 08.2 超类约束：要当 Labeled，先得是 Eq + Show（能力叠加）
class (Eq a, Show a) => Labeled a where
    label :: a -> String
    label x = show x                       -- 默认实现用到了超类 Show 的能力

data Tag = A | B deriving (Show, Eq)

instance Labeled Tag

-- ═══ 08.3 MINIMAL 注解：声明实例必须实现哪些方法
class Volume v where
    volume :: v -> Double
    halfVolume :: v -> Double
    halfVolume v = volume v / 2            -- 有默认实现，不写进 MINIMAL
    {-# MINIMAL volume #-}

data Box = Box Double deriving (Show, Eq)

instance Volume Box where
    volume (Box s) = s * s * s

-- ═══ 08.4 newtype 派生：直通底层类型的整套实例（与 stock 派生的本质区别）
newtype Count = Count Int
    deriving newtype (Show, Eq, Ord, Num)  -- Count 2 + Count 3 == Count 5，白拿 Int 的算术

-- ═══ 08.5 约束多态：一份代码按约束通用
scaleIt :: (Num a, Show a) => a -> String
scaleIt x = show (x * 2)

halfOf :: Fractional a => a -> a
halfOf = (/ 2)
