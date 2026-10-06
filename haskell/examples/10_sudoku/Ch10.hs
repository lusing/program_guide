-- Ch10 库模块：数独求解器（书5）——矩阵建模、全麦定律、剪枝、最少选择格搜索
module Ch10
    ( Digit, Row, Matrix, Grid
    , blank, digits
    , group, ungroup
    , rows, cols, boxs
    , nodups
    , cp
    , choices, expand, valid
    , solve1
    , remove, pruneRow, pruneBy, prune
    , single, complete, safe
    , extract, expand1
    , search, solve
    , example
    ) where

-- ═══ 10.1 建模：棋盘 = 字符矩阵（书5.1）
-- 数字用 Char 表示（Char 是 Enum，['1'..'9'] 直接可用）；'.' 是空格
type Digit = Char

type Row a = [a]

type Matrix a = [Row a]

type Grid = Matrix Digit

blank :: Digit -> Bool
blank d = d == '.'

digits :: [Digit]
digits = ['1' .. '9']

-- ═══ 10.2 三个视图函数（书5.1）：rows/cols/boxs + 分组
group :: [a] -> [[a]] -- 3 个一组
group [] = []
group xs = take 3 xs : group (drop 3 xs)

ungroup :: [[a]] -> [a]
ungroup = concat

rows :: Matrix a -> Matrix a
rows = id -- 矩阵就是行的列表：rows 是恒等函数

cols :: Matrix a -> Matrix a -- 转置（书版手写；与 Data.List.transpose 等价）
cols [xs] = [[x] | x <- xs]
cols (xs : xss) = zipWith (:) xs (cols xss)

boxs :: Matrix a -> Matrix a -- 行→组→转置→合并组：列出每个 3×3 宫
boxs = map ungroup . ungroup . map cols . group . map group

-- ═══ 10.3 有效性（书5.1）
nodups :: Eq a => [a] -> Bool
nodups [] = True
nodups (x : xs) = not (elem x xs) && nodups xs

valid :: Grid -> Bool
valid g = all nodups (rows g) && all nodups (cols g) && all nodups (boxs g)

-- ═══ 10.4 第一版求解器（书5.1）：候选矩阵 + 笛卡尔积全展开 + 过滤
choices :: Grid -> Matrix [Digit]
choices = map (map choice)
  where
    choice d = if blank d then digits else [d]

cp :: [[a]] -> [[a]] -- 笛卡尔积：cp [[1,2,3],[2],[1,3]] 得 6 个长度 3 的列表
cp [] = [[]]
cp (xs : xss) = [x : ys | x <- xs, ys <- cp xss]

expand :: Matrix [Digit] -> [Grid]
expand = cp . map cp

solve1 :: Grid -> [Grid]
solve1 = filter valid . expand . choices

-- ═══ 10.5 剪枝（书5.3）
remove :: Eq a => [a] -> [a] -> [a] -- 从未确定格子里剔除已定数字
remove _ xs@[_] = xs -- 已确定的格子不动
remove ds xs = filter (`notElem` ds) xs

pruneRow :: Row [Digit] -> Row [Digit]
pruneRow row = map (remove fixed) row
  where
    fixed = [d | [d] <- row] -- 模式 [d] 只匹配单元素列表

pruneBy :: (Matrix [Digit] -> Matrix [Digit]) -> Matrix [Digit] -> Matrix [Digit]
pruneBy f = map pruneRow . f . map pruneRow . f

prune :: Matrix [Digit] -> Matrix [Digit]
prune = pruneBy boxs . pruneBy cols . pruneBy rows

-- ═══ 10.6 单格扩展与最终搜索（书5.4）
single :: [a] -> Bool
single [_] = True
single _ = False

complete :: Matrix [Digit] -> Bool
complete = all (all single)

safe :: Matrix [Digit] -> Bool -- 所有行/列/宫里的"已定格"无重复
safe m = all ok (rows m) && all ok (cols m) && all ok (boxs m)
  where
    ok row = nodups [x | [x] <- row]

extract :: Matrix [Digit] -> Grid
extract = map (map first) -- complete 前提下每个格子都是单元素
  where
    first [x] = x
    first _ = '.'

expand1 :: Matrix [Digit] -> [Matrix [Digit]] -- 只展开"选择最少"的那个格子
expand1 rowsm = [rows1 ++ [row1 ++ [c] : row2] ++ rows2 | c <- cs]
  where
    (rows1, row : rows2) = break (any smallest) rowsm
    (row1, cs : row2) = break smallest row
    smallest cs = length cs == n
    n = minimum (counts rowsm) -- 有空格子时 n=0：第一时间发现死路
    counts = filter (/= 1) . map length . concat

search :: Matrix [Digit] -> [Grid]
search cm
    | not (safe pm) = [] -- 裁剪后不安全：此路不通
    | complete pm = [extract pm] -- 全部确定：直接抽取
    | otherwise = concat (map search (expand1 pm)) -- 展开一格继续搜
  where
    pm = prune cm

solve :: Grid -> [Grid]
solve = search . prune . choices

-- ═══ 10.7 演示谜题（经典可解题，唯一解）
example :: Grid
example =
    [ "53..7...."
    , "6..195..."
    , ".98....6."
    , "8...6...3"
    , "4..8.3..1"
    , "7...2...6"
    , ".6....28."
    , "...419..5"
    , "....8..79"
    ]
