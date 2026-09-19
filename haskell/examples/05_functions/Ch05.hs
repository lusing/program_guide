-- Ch05 库模块：柯里化、组合、sections、$、flip、自定义中缀运算符
module Ch05
    ( add, inc, mul2
    , sq, pipeline
    , doubleAll, positives, decrementAll
    , applyTwice, composeAll
    , totalNegatives
    , (<+>)
    ) where

-- ═══ 05.1 一切函数都是柯里化的：add 是「取一个数，返回 (Int -> Int)」
add :: Int -> Int -> Int
add x y = x + y

inc :: Int -> Int
inc = add 1              -- 部分应用：喂了第一个参数，得到一元函数

mul2 :: Int -> Int
mul2 = (* 2)             -- operator section：(* 2) == \x -> x * 2

-- ═══ 05.2 组合 (.) 与 $：从右往左的流水线
sq :: Int -> Int
sq x = x * x

pipeline :: Int -> Int
pipeline = negate . sq . (+ 1)     -- 先 +1，再平方，再取负（. 从右往左读）

-- ═══ 05.3 sections 的方向感与 (-) 陷阱
doubleAll :: [Int] -> [Int]
doubleAll = map (* 2)

positives :: [Int] -> [Int]
positives = filter (> 0)           -- (a <) 是 \x -> a < x；(x < b) 是 \x -> x < b

decrementAll :: [Int] -> [Int]
decrementAll = map (subtract 1)    -- (- 1) 不是减法 section，是负数字面量 -1！

-- ═══ 05.4 高阶函数：函数当值传
applyTwice :: (a -> a) -> a -> a
applyTwice f x = f (f x)

composeAll :: [a -> a] -> a -> a
composeAll fs = foldr (.) id fs    -- id 是组合的单位元

totalNegatives :: [Int] -> Int
totalNegatives = length . filter (< 0)   -- 点自由风格：参数 xs 被缩约掉了

-- ═══ 05.5 自定义中缀运算符：名字是符号、要声明优先级（fixity）
infixl 6 <+>                        -- 左结合，优先级 6（与 + 同级）

(<+>) :: [Int] -> [Int] -> [Int]
xs <+> ys = zipWith (+) xs ys       -- 逐元素相加
