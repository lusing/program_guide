-- Ch11 库模块：容器——Data.Map/Data.Set、Foldable 遍历族、Traversable 一瞥
module Ch11
    ( buildCounts, bump, getCount, topCounts, mergeCounts
    , dedup, common, eitherOf, diff
    , sumValues, doubleAll, validateAll
    , firstLast
    ) where

import Data.List (sortOn)
import qualified Data.Map.Strict as M
import qualified Data.Set as S

-- ═══ 11.1 Map：键值表（内部平衡树，按 Ord 键序）
buildCounts :: Ord a => [a] -> M.Map a Int
buildCounts = M.fromListWith (+) . map (\x -> (x, 1))

bump :: Ord a => a -> M.Map a Int -> M.Map a Int
bump k = M.insertWith (+) k 1          -- insertWith：键已存在时用给定函数合并新旧值

getCount :: Ord a => M.Map a Int -> a -> Int
getCount m k = M.findWithDefault 0 k m

topCounts :: Ord a => M.Map a Int -> [(a, Int)]   -- 按次数降序
topCounts = sortOn (negate . snd) . M.toList

mergeCounts :: Ord a => M.Map a Int -> M.Map a Int -> M.Map a Int
mergeCounts = M.unionWith (+)

-- ═══ 11.2 Set：集合运算
dedup :: Ord a => [a] -> [a]
dedup = S.toAscList . S.fromList       -- 副产品：升序去重

common :: Ord a => [a] -> [a] -> [a]
common xs ys = S.toAscList (S.fromList xs `S.intersection` S.fromList ys)

eitherOf :: Ord a => [a] -> [a] -> [a]
eitherOf xs ys = S.toAscList (S.fromList xs `S.union` S.fromList ys)

diff :: Ord a => [a] -> [a] -> [a]
diff xs ys = S.toAscList (S.fromList xs `S.difference` S.fromList ys)

-- ═══ 11.3 Foldable：mapM_/sum/maximum 这些函数对 Map/Set 通用（对 Map 折叠的是值）
sumValues :: M.Map String Int -> Int
sumValues = sum                        -- Foldable M.Map 实例

doubleAll :: M.Map String Int -> M.Map String Int
doubleAll = M.map (* 2)

-- ═══ 11.4 Traversable：带效果的遍历（任一失败 → 整体 Nothing）
validateAll :: M.Map String Int -> Maybe (M.Map String Int)
validateAll m = mapM check m           -- 全部为正才 Just
  where
    check v = if v > 0 then Just v else Nothing

-- ═══ 11.5 元组族（部分函数 head/last 用全函数替代——9.12 起它们默认触发 -Wx-partial 警告）
firstLast :: [a] -> (Maybe a, Maybe a)
firstLast xs = (headMaybe, lastMaybe)
  where
    headMaybe = case xs of [] -> Nothing; (x:_) -> Just x
    lastMaybe = foldl (\_ x -> Just x) Nothing xs    -- 全函数版 last（foldr 版会拿到首元素）
