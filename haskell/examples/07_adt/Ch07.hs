-- Ch07 库模块：代数数据类型——data/记录语法/newtype/Maybe/Either/递归数据/deriving
module Ch07
    ( Shape(..), area, perimeter
    , Person(..), birthday
    , IntList(..), fromList, sumIL, lenIL
    , Tree(..), insertT, sizeT, heightT, inOrder
    , safeDiv, annotate
    , Age(..), unpack
    ) where

-- ═══ 07.1 和类型 × 积类型：Shape = 圆 或 矩形；字段是积
data Shape = Circle Double | Rect Double Double
    deriving (Show, Eq, Ord)      -- Ord 派生序 = 构造子声明序，再按字段字典序

area :: Shape -> Double
area (Circle r)     = pi * r * r
area (Rect w h)     = w * h

perimeter :: Shape -> Double
perimeter (Circle r) = 2 * pi * r
perimeter (Rect w h) = 2 * (w + h)

-- ═══ 07.2 记录语法：字段名即访问函数
data Person = Person
    { pName :: String
    , pAge  :: Int
    } deriving (Show, Eq)

-- 记录更新语法：不改原值（不可变），拷贝一份改字段
birthday :: Person -> Person
birthday p = p { pAge = pAge p + 1 }

-- ═══ 07.3 newtype：零成本包裹（编译后与底层类型同表示），用来区分语义
newtype Age = Age Int deriving (Show, Eq)

unpack :: Age -> Int
unpack (Age n) = n

-- ═══ 07.4 递归数据类型：用自己的构造子引用自己（列表的本质）
data IntList = INil | ICons Int IntList
    deriving (Show, Eq)

fromList :: [Int] -> IntList
fromList []     = INil
fromList (x:xs) = ICons x (fromList xs)

sumIL :: IntList -> Int
sumIL INil        = 0
sumIL (ICons x t) = x + sumIL t

lenIL :: IntList -> Int
lenIL INil        = 0
lenIL (ICons _ t) = 1 + lenIL t

-- ═══ 07.5 二叉搜索树：递归数据 + 递归函数的标准配对
data Tree = Leaf | Node Tree Int Tree
    deriving (Show, Eq)

insertT :: Tree -> Int -> Tree
insertT Leaf x             = Node Leaf x Leaf
insertT (Node l v r) x
  | x < v                  = Node (insertT l x) v r
  | x > v                  = Node l v (insertT r x)
  | otherwise              = Node l v r          -- 已存在：保持不变（集合语义）

sizeT :: Tree -> Int
sizeT Leaf           = 0
sizeT (Node l _ r)   = 1 + sizeT l + sizeT r

heightT :: Tree -> Int
heightT Leaf         = 0
heightT (Node l _ r) = 1 + max (heightT l) (heightT r)

inOrder :: Tree -> [Int]
inOrder Leaf           = []
inOrder (Node l v r)   = inOrder l ++ [v] ++ inOrder r    -- 中序遍历恰好有序

-- ═══ 07.6 Maybe / Either：标准库里最常用的两个 ADT
safeDiv :: Int -> Int -> Maybe Int
safeDiv _ 0 = Nothing
safeDiv a b = Just (a `div` b)

-- Either 带错误说明：Left 原因 / Right 结果
annotate :: Int -> Int -> Either String Int
annotate _ 0 = Left "除数为零"
annotate a b = Right (a `div` b)
