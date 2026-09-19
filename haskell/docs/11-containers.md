# 11 · 容器：Map/Set 与遍历族

> 对应示例：`examples/11_containers/`

## 11.1 Data.Map：键值表

内部平衡树，按 `Ord` 键序组织（不是哈希——键必须可排序）：

```haskell
import qualified Data.Map.Strict as M

buildCounts :: Ord a => [a] -> M.Map a Int
buildCounts = M.fromListWith (+) . map (\x -> (x, 1))     -- 词频统计

bump k = M.insertWith (+) k 1          -- insertWith：键已存在时合并 (新值 旧值)
getCount m k = M.findWithDefault 0 k m -- 缺省零，不崩
topCounts = sortOn (negate . snd) . M.toList
mergeCounts = M.unionWith (+)
```

`M.keys freq` 按键序输出（`["be","not","or","to"]`）——**有序性是 Map 的天然不变式**，
也是测试断言的依据。

## 11.2 Strict 与 Lazy 两种 Map

`Data.Map.Lazy`（默认）：插入的值是 thunk——更新场景可能堆泄漏；`Data.Map.Strict`：插入即
强制值。**计数/累加场景用 Strict 版**（教程全用 Strict）。

## 11.3 Data.Set：集合运算

```haskell
import qualified Data.Set as S

dedup = S.toAscList . S.fromList        -- 去重 + 免费排序
common xs ys = S.toAscList (S.fromList xs `S.intersection` S.fromList ys)
eitherOf xs ys = S.toAscList (S.fromList xs `S.union` S.fromList ys)
diff     xs ys = S.toAscList (S.fromList xs `S.difference` S.fromList ys)
```

`Data.IntMap`：键恒为 Int 的特化版（更快，生态一瞥）。

## 11.4 Foldable：一个接口，处处求和

`sum`/`maximum`/`mapM_`/`length` 这些函数其实属于 **Foldable** 类型类——对 Map（折叠**值**）、
Set、列表通用：

```haskell
sumValues :: M.Map String Int -> Int
sumValues = sum                       -- M.Map 的 Foldable 实例折值不折键
```

## 11.5 Traversable：带效果地遍历

```haskell
validateAll :: M.Map String Int -> Maybe (M.Map String Int)
validateAll m = mapM check m          -- 任一 Nothing → 整体 Nothing
  where check v = if v > 0 then Just v else Nothing
```

Traversable 的 `mapM`/`sequenceA` 把"容器里的效果"提出来——13 章 Applicative 后再看它会更通透。

## 11.6 元组族

```haskell
fst (1, 'x')        -- 1
swap (1, 'x')       -- ('x', 1)   （Data.Tuple.swap）
firstLast xs        -- (Maybe a, Maybe a)——head/last 的安全化（06 章全函数版）
```

## 11.7 坑位清单

1. **Map 键要 Ord 不要 Eq 就够**：平衡树不是哈希表；键类型没有 Ord 实例直接编译不过（11.1）。
2. **Lazy Map 的值 thunk**：累加器场景用 `Data.Map.Strict`（11.2）。
3. **`M.!` 是部分函数**（缺键崩）：用 `lookup`/`findWithDefault`（11.1）。
4. **listDirectory/Map 遍历顺序**：Map 键序稳定，但目录列举顺序不定——断言前先 sort（16 章实测同款）。
5. **head (topCounts …) 恰好非空也不能写 head**：9.12 默认 -Wx-partial 警告——case 解构
   （本教程 runtests 的写法）（06 章回响）。
