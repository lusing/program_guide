-- Ch26 库模块：优美打印（书8）——浅/深两种嵌入、24 定律的参考实现、线性 pretty
module Ch26
    ( Layout
    -- 深嵌入（对外抽象：只给构造子的结果函数）
    , Doc (..)
    , nil, line, text, nest, (<=>), group
    , flatten
    , layouts, layoutsLinear
    , pretty, prettyNaive
    -- 示例文档族
    , CExpr (..), cexpr
    , GenTree (..), gtree
    , para
    , bookIf, bookTree, bookPara
    ) where

type Layout = String

-- ════════════════ 深嵌入：Doc 是抽象语法树（书8.6）════════════════
-- 每个库运算对应一个构造子；(:<>:) 是中缀构造子（冒号开头是 Haskell 的规定）
data Doc
    = Nil
    | Line
    | Text String
    | Nest Int Doc
    | Group Doc
    | Doc :<>: Doc

nil :: Doc
nil = Nil

line :: Doc
line = Line

text :: String -> Doc
text = Text

nest :: Int -> Doc -> Doc
nest = Nest

(<=>) :: Doc -> Doc -> Doc -- 库的串联（避开与 (++) 混淆，本教学版取名 <=>）
(<=>) = (:<>:)

group :: Doc -> Doc
group = Group

-- ════════════════ 参考实现：layouts / flatten（书8.6 的定律版）════════════════
-- 定义即 24 条定律的"构造子版"；同时是浅嵌入 type Doc = [Layout] 的化身
layouts :: Doc -> [Layout]
layouts (x :<>: y) = layouts x <++ layouts y
layouts Nil = [""]
layouts Line = ["\n"]
layouts (Text s) = [s]
layouts (Nest i x) = map (nestl i) (layouts x)
layouts (Group x) = layouts (flatten x) ++ layouts x

(<++) :: [Layout] -> [Layout] -> [Layout] -- 提升的串联：格式集合的笛卡尔拼接
xss <++ yss = [xs ++ ys | xs <- xss, ys <- yss]

nestl :: Int -> Layout -> Layout -- 换行后补 i 格
nestl i = concat . map (indent i)
  where
    indent j c = if c == '\n' then c : replicate j ' ' else [c]

flatten :: Doc -> Doc -- 把换行（及缩进）压成一个空格的单行文档
flatten (x :<>: y) = flatten x :<>: flatten y
flatten Nil = Nil
flatten Line = Text " "
flatten (Text s) = Text s
flatten (Nest _ x) = flatten x
flatten (Group x) = flatten x

-- ════════════════ 线性版 layouts（书8.6 的 layr）：延迟串联 + 延迟嵌套 ════════════════
layoutsLinear :: Doc -> [Layout]
layoutsLinear x = lay [(0, x)]
  where
    lay [] = [""]
    lay ((i, x' :<>: y') : ids) = lay ((i, x') : (i, y') : ids) -- 串联不急着做
    lay ((i, Nil) : ids) = lay ids
    lay ((i, Line) : ids) = ['\n' : replicate i ' ' ++ l | l <- lay ids]
    lay ((i, Text s) : ids) = [s ++ l | l <- lay ids]
    lay ((i, Nest j x') : ids) = lay ((i + j, x') : ids) -- 嵌套只记账不穿透
    lay ((i, Group x') : ids) = lay ((i, flatten x') : ids) ++ lay ((i, x') : ids)

-- ════════════════ 指数版 pretty（书8.5）：枚举全部格式再选 ════════════════
-- 贪心比较：第一行装得下越长越好；都装不下则越短越好（书 8.5 的 better）
prettyNaive :: Int -> Doc -> Layout
prettyNaive w d = fst (foldr1 choose (map augment (layouts d)))
  where
    augment l = (l, map length (linesOf l))
    choose al aly = if better (snd al) (snd aly) then al else aly
    better [] _ = True
    better _ [] = False
    better (j : js) (k : ks)
        | j == k = better js ks
        | otherwise = j <= w
    linesOf s = case break (== '\n') s of
        (l, "") -> [l]
        (l, _ : rest) -> l : linesOf rest

-- ════════════════ 线性版 pretty（书8.6 的 best/fits）════════════════
pretty :: Int -> Doc -> Layout
pretty w x = best w [(0, x)]
  where
    best _ [] = ""
    best r ((i, x' :<>: y') : ids) = best r ((i, x') : (i, y') : ids)
    best r ((i, Nil) : ids) = best r ids
    best r ((i, Line) : ids) = '\n' : replicate i ' ' ++ best (w - i) ids -- 换行后剩余宽重置
    best r ((i, Text s) : ids) = s ++ best (r - length s) ids
    best r ((i, Nest j x') : ids) = best r ((i + j, x') : ids)
    best r ((i, Group x') : ids) = better r (best r ((i, flatten x') : ids)) (best r ((i, x') : ids))
    -- better 依赖"扁平版第一行不短"的事实；r 是当前行剩余宽度；fits 惰性：够判断就停（书 8.6）
    better r lx ly = if fits r lx then lx else ly
    fits r _ | r < 0 = False
    fits _ [] = True
    fits r (c : cs)
        | c == '\n' = True
        | otherwise = fits (r - 1) cs

-- ════════════════ 示例文档族（书8.4）════════════════
data CExpr = Atom String | Cond String CExpr CExpr deriving (Show)

-- 本教程版 cexpr：外层不 group（顶层必换行展示 if），then/else 各自带 group
cexpr :: CExpr -> Doc
cexpr (Atom p) = text p
cexpr (Cond p x y) =
    text ("if " ++ p)
        <=> group (line <=> text "then " <=> nest 5 (cexpr x))
        <=> group (line <=> text "else " <=> nest 5 (cexpr y))

data GenTree a = GNode a [GenTree a] deriving (Show)

-- 本教程版 gtree/bracket（书版 bracket 显示逗号分隔；树没有子树时单行收口）
gtree :: Show a => GenTree a -> Doc
gtree (GNode x []) = text ("Node " ++ show x ++ " []")
gtree (GNode x ts) = text ("Node " ++ show x) <=> group (nest 2 (line <=> bracket (map gtree ts)))
  where
    bracket ds = text "[" <=> nest 1 (spread (punctuate (text ",") ds)) <=> text "]"
    spread = foldr (<=>) nil
    punctuate _ [] = []
    punctuate _ [d] = [d]
    punctuate p (d : ds) = (d <=> p) : punctuate p ds

-- 段落（书8.4 的 para）：词间每处可选"空格或换行"，group 交给 pretty 装行
para :: String -> Doc
para = cvt . map text . words
  where
    cvt [] = nil
    cvt (x : xs) = x <=> foldr (<=>) nil [group (line <=> t) | t <- xs]

-- 书 8.4 的三个实例
bookIf :: CExpr
bookIf =
    Cond
        "wealthy"
        (Cond "happy" (Atom "lucky you") (Atom "tough"))
        (Cond "in love" (Atom "content") (Atom "miserable"))

bookTree :: GenTree Int
bookTree =
    GNode
        1
        [ GNode 2 [GNode 7 [], GNode 8 []]
        , GNode 3 [GNode 9 [GNode 10 [], GNode 11 []]]
        , GNode 4 []
        , GNode 5 [GNode 6 []]
        ]

bookPara :: String
bookPara = "This is a fairly short paragraph with just twenty-two words. The problem is that pretty-printing it takes time, in fact 31.32 seconds."
