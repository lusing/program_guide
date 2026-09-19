# 07 · 代数数据类型 ⭐

> 对应示例：`examples/07_adt/`

## 7.1 data：和 × 积

**代数数据类型（ADT）= 和类型（sum，多选一）× 积类型（product，全都要）**：

```haskell
data Shape = Circle Double | Rect Double Double
    deriving (Show, Eq, Ord)
```

`Shape` 是"圆 **或** 矩形"（两个构造子之和）；`Rect Double Double` 是宽与高的积。
消费它只能模式匹配（这就是 06 章的"结构分派"）：

```haskell
area :: Shape -> Double
area (Circle r) = pi * r * r
area (Rect w h) = w * h
```

`deriving` 白拿实例：`Show`（可打印）、`Eq`（可比较相等）、`Ord`（可排序）。
**Ord 的派生序 = 构造子声明顺序，同构造子再按字段字典序**：

```haskell
compare (Circle 1) (Rect 1 1)    -- LT（Circle 声明在前）
maximum [Circle 1, Circle 3, Circle 2]   -- Circle 3.0
```

## 7.2 记录语法

```haskell
data Person = Person
    { pName :: String          -- 字段名 = 同名访问函数
    , pAge  :: Int
    } deriving (Show, Eq)

alice = Person { pName = "Alice", pAge = 30 }

birthday :: Person -> Person
birthday p = p { pAge = pAge p + 1 }     -- 记录更新：拷贝 + 改字段
```

**不可变值语义**：`birthday alice` 不改 `alice`，产出新值（原值照旧）。更新语法是
"拷贝其余字段"的糖。

## 7.3 newtype：零成本包裹

```haskell
newtype Age = Age Int deriving (Show, Eq)
```

编译后与 `Int` 同表示（零运行时开销），但类型不混——`Age 5 + 1` 编译不过。用途：
区分同构类型（`newtype Email = Email String`）、给类型挂新实例（08 章 `deriving newtype`）。
与 `data` 的差别：恰好一个字段、模式匹配严格、无额外构造层。

## 7.4 递归数据类型

类型可以引用自己——**列表的本质**就是一个递归 ADT：

```haskell
data IntList = INil | ICons Int IntList deriving (Show, Eq)

fromList []     = INil
fromList (x:xs) = ICons x (fromList xs)

sumIL INil        = 0                    -- 消费者也递归
sumIL (ICons x t) = x + sumIL t
```

二叉搜索树——递归数据 + 递归函数的标准配对：

```haskell
data Tree = Leaf | Node Tree Int Tree deriving (Show, Eq)

insertT :: Tree -> Int -> Tree
insertT Leaf x           = Node Leaf x Leaf
insertT (Node l v r) x
  | x < v                = Node (insertT l x) v r
  | x > v                = Node l v (insertT r x)
  | otherwise            = Node l v r          -- 已存在：集合语义，保持不变

inOrder :: Tree -> [Int]
inOrder Leaf         = []
inOrder (Node l v r) = inOrder l ++ [v] ++ inOrder r   -- 中序遍历恰好有序！
```

`foldl insertT Leaf [5,3,8,1,4,9,2,6,7]` 建树，`inOrder` 吐出 `[1..9]`——数据结构的不变式
就是测试断言（runtests 里就是这么测的）。

## 7.5 Maybe 与 Either：标准库最重要的两个 ADT

```haskell
data Maybe a = Nothing | Just a                -- 可能失败
data Either a b = Left a | Right b             -- 失败带原因
```

```haskell
safeDiv :: Int -> Int -> Maybe Int
safeDiv _ 0 = Nothing
safeDiv a b = Just (a `div` b)

annotate :: Int -> Int -> Either String Int    -- Left 带说明
annotate _ 0 = Left "除数为零"
annotate a b = Right (a `div` b)
```

没有 null——"可能没有"必须在类型里（13 章看它们如何组成单子链）。

## 7.6 坑位清单

1. **Ord 派生序是声明序**：靠 `sort shapes` 排出"合理顺序"是想当然——排序语义自己写（7.1）。
2. **记录字段访问函数是顶层函数**：两个字段同名会冲突（`DuplicateRecordFields` 扩展一瞥，
   或像本教程用 `pName` 前缀规避）（7.2）。
3. **更新语法不改变原值**：忘记接住返回值是常错——`p { … }` 产出新值（7.2）。
4. **newtype 恰好一个字段**：多字段/零字段用 data；别用 data 包单字段（浪费一层）（7.3）。
5. **递归数据的遍历代价**：`inOrder l ++ [v] ++ inOrder r` 是教学写法；++ 左嵌套 O(n²)
   （9 章建造塔、19 章 Builder 是正解）（7.4）。
