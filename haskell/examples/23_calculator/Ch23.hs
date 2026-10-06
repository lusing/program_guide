-- Ch23 库模块：等式计算器（书12）——点自由定律的自动证明器，教学版单模块
-- 书里拆成 Expressions/Laws/Calculations/Rewrites/Matchings/Substitutions/Utilities/Parsing/Main
-- 九个模块；此处按同一分工用分节注释组织，便于对照原书。
module Ch23
    ( Expr (..), Atom (..)
    , Law (..), Equation, Calculation (..)
    , parseExpr, parseLaw, parseEquation
    , sortLaws
    , calculate, simplify, prove
    , rewrites
    , final
    ) where

import Control.Applicative (Alternative (..))
import Data.Char (isAlpha, isAlphaNum, isDigit, isSpace)
import Data.List (partition)
import Data.Maybe (fromMaybe)

-- ════════════════ Parsing（书11 的组合子，本章内嵌）════════════════

newtype Parser a = Parser {applyP :: String -> [(a, String)]}

instance Functor Parser where
    fmap f p = Parser (\s -> [(f x, s') | (x, s') <- applyP p s])

instance Applicative Parser where
    pure x = Parser (\s -> [(x, s)])
    pf <*> px = Parser (\s -> [(f y, s2) | (f, s1) <- applyP pf s, (y, s2) <- applyP px s1])

instance Monad Parser where
    p >>= q = Parser (\s -> [(y, s2) | (x, s1) <- applyP p s, (y, s2) <- applyP (q x) s1])

instance Alternative Parser where
    empty = Parser (const [])
    p <|> q = Parser (\s -> case applyP p s of [] -> applyP q s; r -> r)

sat :: (Char -> Bool) -> Parser Char
sat pr = Parser f
  where
    f (c : cs) | pr c = [(c, cs)]
    f _ = []

spaces :: Parser ()
spaces = many (sat isSpace) >> pure ()

token :: Parser a -> Parser a
token p = spaces >> p

symbol :: String -> Parser ()
symbol xs = token (string xs)

string :: String -> Parser ()
string [] = pure ()
string (x : xs) = do
    c <- token' (sat (== x))
    _ <- string xs
    pure ()
  where
    token' p = p -- symbol 里空白只认前导；字符之间不许空白

upto :: Char -> Parser String -- 读到 c 为止（不含 c），丢弃 c
upto c = Parser f
  where
    f s =
        let (xs, ys) = break (== c) s
        in if null ys then [] else [(xs, drop 1 ys)]

-- 全函数版取首解（书的 parse = fst . head 是部分函数，教学版改安全）
firstParse :: Parser a -> String -> Either String a
firstParse p s = case applyP (spaces >> p) s of
    ((x, _) : _) -> Right x
    [] -> Left "解析失败"

-- ════════════════ Expressions（书12.2）════════════════

newtype Expr = Compose {deCompose :: [Atom]} deriving (Eq)

data Atom = Var String | Con String [Expr] deriving (Eq)

opSymbols :: String
opSymbols = "!#$%&*+/<=>?|~:-"

symbolic :: Char -> Bool
symbolic c = c `elem` opSymbols

isVarName :: String -> Bool -- 变量：单字母，或字母+一位数字（f、f1）
isVarName [x] = isAlpha x
isVarName [x, d] = isAlpha x && isDigit d
isVarName _ = False

operator :: Parser String
operator = do
    op <- token (some (sat symbolic))
    guard' (op /= "." && op /= "=")
    pure op
  where
    guard' b = if b then pure () else empty

expr :: Parser Expr
expr = simple >>= rest
  where
    rest s1 = do
        op <- operator
        s2 <- simple
        pure (Compose [Con op [s1, s2]])
        <|> pure s1

simple :: Parser Expr -- 项的复合：f.g.h
simple = do
    es <- someWith (symbol ".") term
    pure (Compose (concatMap deCompose es))

term :: Parser Expr
term = ident args <|> paren expr
  where
    args = many (ident (pure []) <|> paren expr)

firstIsAlpha :: String -> Bool
firstIsAlpha (c : _) = isAlpha c -- 全函数版 head（-Wx-partial 规避）
firstIsAlpha [] = False

ident :: Parser [Expr] -> Parser Expr
ident args = do
    x <- token (some (sat isAlphaNum))
    guard' (firstIsAlpha x)
    if isVarName x
        then pure (Compose [Var x])
        else
            if x == "id"
                then pure (Compose []) -- id 是复合的单位元：直接消掉
                else do
                    as <- args
                    pure (Compose [Con x as])
  where
    guard' b = if b then pure () else empty

paren :: Parser Expr -> Parser Expr
paren p = do
    symbol "("
    e <- p
    symbol ")"
    pure e

someWith :: Parser () -> Parser a -> Parser [a] -- p 实例之间用 sep 分隔，至少一次
someWith sep p = do
    x <- p
    xs <- many (sep >> p)
    pure (x : xs)

-- 显示（书12.2 的 showsPrec 三档优先级）
showSep :: String -> (a -> ShowS') -> [a] -> ShowS'
showSep sep f xs = compose (intersperse' (showString' sep) (map f xs))
  where
    intersperse' _ [] = []
    intersperse' _ [x] = [x]
    intersperse' s (x : xs) = x : s : intersperse' s xs

type ShowS' = String -> String

showString' :: String -> ShowS'
showString' = (++)

showChar' :: Char -> ShowS'
showChar' c = (c :)

showParen' :: Bool -> ShowS' -> ShowS'
showParen' b p = if b then showChar' '(' . p . showChar' ')' else p

compose :: [ShowS'] -> ShowS'
compose = foldr (.) id

instance Show Expr where
    show e = showsE 0 e ""

showsE :: Int -> Expr -> ShowS'
showsE p (Compose []) = showString' "id"
showsE p (Compose [a]) = showsA p a
showsE p (Compose as) = showParen' (p > 0) (showSep " . " (showsA 1) as)

showsA :: Int -> Atom -> ShowS'
showsA _ (Var v) = showString' v
showsA _ (Con f []) = showString' f
showsA p (Con f [e1, e2])
    | all symbolic f = showParen' (p > 0) (showsE 1 e1 . showChar' ' ' . showString' f . showChar' ' ' . showsE 1 e2)
showsA p (Con f es) = showParen' (p > 1) (showString' f . showChar' ' ' . showSep " " (showsE 2) es)

-- ════════════════ Utilities（书 Utilities 模块）════════════════

cp :: [[a]] -> [[a]] -- 笛卡尔积
cp [] = [[]]
cp (xs : xss) = [x : ys | x <- xs, ys <- cp xss]

splits :: [a] -> [([a], [a])]
splits [] = [([], [])]
splits (a : as) = ([], a : as) : [(a : l, r) | (l, r) <- splits as]

segments :: [a] -> [([a], [a], [a])] -- 三段切分（中段非空由两次 splits 组合保证）
segments as = [(as1, as2, as3) | (as1, bs) <- splits as, (as2, as3) <- splits bs]

parts :: Int -> [a] -> [[[a]]] -- 划分成恰好 n 段（允许空段）；n>0 且空列表由第三子句递归
parts 0 [] = [[]] -- 0 段分空表：唯一
parts 0 _ = [] -- 0 段分非空：不可能
parts n as = [bs : bss | (bs, cs) <- splits as, bss <- parts (n - 1) cs]

anyOne :: (a -> [a]) -> [a] -> [[a]] -- 恰好为一个元素设置一次选择
anyOne _ [] = []
anyOne f (x : xs) = [x' : xs | x' <- f x] ++ [x : xs' | xs' <- anyOne f xs]

-- ════════════════ Substitutions（书12.7）════════════════

type Subst = [(String, Expr)]

emptySub :: Subst
emptySub = []

unitSub :: String -> Expr -> Subst
unitSub v e = [(v, e)]

binding :: Subst -> String -> Expr
binding sub v = fromMaybe (error ("未绑定变量: " ++ v)) (lookup v sub)

apply :: Subst -> Expr -> Expr
apply sub (Compose as) = Compose (concatMap (applyA sub) as)

applyA :: Subst -> Atom -> [Atom]
applyA sub (Var v) = deCompose (binding sub v) -- 变量替换为绑定的表达式（摊平）
applyA sub (Con k es) = [Con k (map (apply sub) es)]

unify :: Subst -> Subst -> [Subst] -- 相容则并，否则失败（空表）
unify sub1 sub2 = if compatible sub1 sub2 then [unionSub sub1 sub2] else []

compatible :: Subst -> Subst -> Bool
compatible [] _ = True
compatible _ [] = True
compatible sub1@((v1, e1) : r1) sub2@((v2, e2) : r2)
    | v1 < v2 = compatible r1 sub2
    | v1 > v2 = compatible sub1 r2
    | e1 == e2 = compatible r1 r2
    | otherwise = False

unionSub :: Subst -> Subst -> Subst
unionSub [] sub2 = sub2
unionSub sub1 [] = sub1
unionSub sub1@((v1, e1) : r1) sub2@((v2, e2) : r2)
    | v1 < v2 = (v1, e1) : unionSub r1 sub2
    | v1 > v2 = (v2, e2) : unionSub sub1 r2
    | otherwise = (v1, e1) : unionSub r1 r2

unifyAll :: [Subst] -> [Subst]
unifyAll = foldr f [emptySub]
  where
    f sub subs = concatMap (unify sub) subs

combine :: [[Subst]] -> [Subst] -- 每列选一个再合一
combine = concatMap unifyAll . cp

-- ════════════════ Matchings（书12.6）════════════════

-- match (e1, e2)：所有让 e1 转化为 e2 的代换。变量可绑表达式的"多种切法"都保留，
-- 过早承诺单一代换会错失成功匹配（书里的 foo 例子）。
match :: Equation -> [Subst]
match (e1, e2) = concatMap (combine . map matchA) (alignments (e1, e2))

alignments :: (Expr, Expr) -> [[(Atom, Expr)]]
alignments (Compose as, Compose bs) = [zip as (map Compose bss) | bss <- parts (length as) bs]

matchA :: (Atom, Expr) -> [Subst]
matchA (Var v, e) = [unitSub v e] -- 变量匹配一切
matchA (Con k1 es1, Compose [Con k2 es2])
    | k1 == k2 = combine (map match (zip es1 es2)) -- 同名常量：逐参数匹配
matchA _ = []

-- ════════════════ Rewrites（书12.5）════════════════

rewrites :: Equation -> Expr -> [Expr] -- 用等式重写表达式的一切方式
rewrites eqn (Compose as) =
    map Compose (rewritesSeg eqn as ++ anyOne (rewritesA eqn) as)

rewritesA :: Equation -> Atom -> [Atom] -- 钻进带参数的常量里重写
rewritesA _ (Var _) = []
rewritesA eqn (Con k es) = map (Con k) (anyOne (rewrites eqn) es)

rewritesSeg :: Equation -> [Atom] -> [[Atom]] -- 中段整段匹配等式左端
rewritesSeg (e1, e2) as =
    [ as1 ++ deCompose (apply sub e2) ++ as3
    | (as1, as2, as3) <- segments as
    , sub <- match (e1, Compose as2)
    ]

-- ════════════════ Laws（书12.3）════════════════

data Law = Law String Equation deriving (Show)

type Equation = (Expr, Expr)

law :: Parser Law
law = do
    name <- upto ':'
    eqn <- equation
    pure (Law name eqn)

equation :: Parser Equation
equation = do
    e1 <- expr
    symbol "="
    e2 <- expr
    pure (e1, e2)

-- 定律排序：简单定律 → 其他 → 定义（先化简后展开，防止中间表达式膨胀）
sortLaws :: [Law] -> [Law]
sortLaws laws = simple ++ others ++ defns
  where
    (simple, nonsimple) = partition isSimple laws
    (defns, others) = partition isDefn nonsimple

isSimple :: Law -> Bool -- 右边比左边原子少：一旦可用就用，只赚不亏
isSimple (Law _ (Compose as1, Compose as2)) = length as1 > length as2

isDefn :: Law -> Bool -- 左边是"常量应用到变量"：定义，最后才用
isDefn (Law _ (Compose [Con _ es], _)) = all isVarE es
  where
    isVarE (Compose [Var _]) = True
    isVarE _ = False
isDefn _ = False

-- ════════════════ Calculations（书12.4）════════════════

data Calculation = Calc Expr [(String, Expr)]

instance Show Calculation where
    show (Calc e steps) =
        "  " ++ show e ++ "\n"
            ++ concatMap (\(why, e') -> "= {" ++ why ++ "}\n  " ++ show e' ++ "\n") steps

final :: Calculation -> Expr -- 计算的结论（无步时即起点）
final (Calc e steps) = case reverse steps of
    ((_, last') : _) -> last'
    [] -> e

calculate :: [Law] -> Expr -> Calculation
calculate laws e = Calc e (manyStep rws e)
  where
    sorted = sortLaws laws
    rws e' =
        [ (name, e'')
        | Law name eqn <- sorted
        , e'' <- rewrites eqn e'
        , e'' /= e' -- 重写回自身的步不采纳（防死循环）
        ]
    manyStep r e' =
        case r e' of
            [] -> []
            step : more -> step : manyStep r (snd step)

reverseCalc :: Calculation -> Calculation
reverseCalc (Calc e steps) = foldl shunt (Calc e []) steps
  where
    shunt (Calc e1 sts) (why, e2) = Calc e2 ((why, e1) : sts)

paste :: Calculation -> Calculation -> Calculation -- 证明 = 两个计算对接
paste calc1@(Calc e1 steps1) calc2 =
    if conc1 == conc2
        then Calc e1 (prune conc1 rsteps1 rsteps2)
        else Calc e1 (steps1 ++ (gap, conc2) : rsteps2)
  where
    Calc conc1 rsteps1 = reverseCalc calc1
    Calc conc2 rsteps2 = reverseCalc calc2
    gap = "... ??? ..."
    prune e ((_, a) : as) ((_, b) : bs)
        | a == b = prune a as bs -- 两边最后一步殊途同归：剪掉重复
    prune e as bs = sndOf (reverseCalc (Calc e as)) ++ bs
      where
        sndOf (Calc _ s) = s

-- ════════════════ Main 层入口（书 simplify/prove 的串版本）════════════════

parseExpr :: String -> Either String Expr
parseExpr = firstParse expr

parseLaw :: String -> Either String Law
parseLaw = firstParse law

parseEquation :: String -> Either String Equation
parseEquation = firstParse equation

simplify :: [String] -> String -> Either String Calculation
simplify lawStrs s = do
    laws <- mapM parseLaw lawStrs
    e <- parseExpr s
    pure (calculate laws e)

prove :: [String] -> String -> Either String Calculation
prove lawStrs s = do
    laws <- mapM parseLaw lawStrs
    (e1, e2) <- parseEquation s
    pure (paste (calculate laws e1) (calculate laws e2))
