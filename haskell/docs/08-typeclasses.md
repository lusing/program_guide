# 08 · 类型类 ⭐

> 对应示例：`examples/08_typeclasses/`

## 8.1 class 与 instance：按行为组织类型

类型类是"行为的接口"——**一个类型可以有什么操作**。定义用 `class`，实现用 `instance`：

```haskell
class Describable a where
    describe :: a -> String
    describeTwice :: a -> String              -- 方法可以有默认实现
    describeTwice x = describe x ++ "，" ++ describe x

data Color = Red | Green | Blue deriving (Show, Eq)

instance Describable Color where
    describe Red   = "红"                      -- 只实现必须的
    describe Green = "绿"                      -- describeTwice 吃默认
    describe Blue  = "蓝"

instance Describable Bool where
    describe True  = "真"
    describe False = "假"

describe Red ++ describe True                  -- 同名调用按类型分派
```

与 OOP 接口的本质差异：**分派凭类型、与继承无关**；实例写在类型定义之外，一个类型可加入
任意多个类。

## 8.2 超类：能力的叠加

```haskell
class (Eq a, Show a) => Labeled a where        -- 要当 Labeled，先得是 Eq + Show
    label :: a -> String
    label x = show x                           -- 默认实现直接用超类能力

data Tag = A | B deriving (Show, Eq)
instance Labeled Tag                           -- 空实例：全吃默认
```

标准库的实例链就是这套：`Num → Real → Fractional`、`Functor → Applicative → Monad`（13 章）。

## 8.3 MINIMAL：实例的最低要求

```haskell
class Volume v where
    volume :: v -> Double
    halfVolume :: v -> Double
    halfVolume v = volume v / 2
    {-# MINIMAL volume #-}                     -- 只需实现 volume

instance Volume Box where
    volume (Box s) = s * s * s                  -- halfVolume 自动可用
```

## 8.4 deriving 的三种策略

```haskell
-- stock：编译器按结构生成（Show/Eq/Ord/…）
data Box = Box Double deriving (Show, Eq)

-- newtype：直通底层类型的整套实例（零成本复用）
{-# LANGUAGE DerivingStrategies #-}            -- 坑：此语法需要该扩展（实测）
newtype Count = Count Int deriving newtype (Show, Eq, Ord, Num)

Count 2 + Count 3        -- Count 5：白拿 Int 的算术！
```

`deriving stock` 生成的是"构造子层面"的新实例；`deriving newtype` 是把 `Int` 的实例原样借来
——所以 `Num` 这种带方法的也能借。还有 `deriving anyclass`/`via`（生态一瞥即可）。

## 8.5 约束多态：一份代码按约束通用

```haskell
scaleIt :: (Num a, Show a) => a -> String
scaleIt x = show (x * 2)

scaleIt (5 :: Int)       -- "10"
scaleIt (5.5 :: Double)  -- "11.0"
scaleIt (Count 7)        -- "14"（newtype 派生的 Num 直接生效）

halfOf :: Fractional a => a -> a
halfOf = (/ 2)
halfOf (1 :: Rational)   -- 1 % 2
```

`=>` 左边是约束、右边是签名。Prelude 里到处是它：`sum :: Num a => [a] -> a`。

## 8.6 Kind 一瞥

类型也有"类型之类型"（kind）：`Int :: Type`、`Maybe :: Type -> Type`。
`Functor` 的 kind 是 `(Type -> Type) -> Constraint`——所以 `Int` 当不了 Functor、`Maybe` 可以
（13 章）。GHCi 里 `:kind Maybe` 自查。

## 8.7 孤儿实例

实例应写在**类型定义处**或**类型类定义处**，两边都不是就是"孤儿"（orphan）——
两处都写就冲突，编译器只给警告但工程上是大忌。解决方案：newtype 包一层在本地挂实例。

## 8.8 坑位清单

1. **`deriving newtype` 语法需要 DerivingStrategies 扩展**（默认不开；实测编译错误给了正解提示）（8.4）。
2. **实例不能重叠**：同一 (类, 类型) 对只能有一份全局定义（8.1）。
3. **孤儿实例**：类型与类都不在你手里的 instance 放进库里会污染全局（8.7）。
4. **方法默认实现可以互相调用**：MINIMAL 没写全会在"使用"时炸出 `No explicit implementation`（8.3）。
5. **Kind 不匹配是常见编译错**：`instance Functor Int` 不成立——`Int :: Type` 不是 `Type -> Type`（8.6）。
