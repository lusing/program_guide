# 33 · stdlib 数据结构系统：List / Vec / Fin / Tree.AVL

Data/ 是 stdlib 最大的目录（实测 3.0 有 567 个模块）。这一章不教你每种结构
的 API 全表（那是 `README` 门面该干的），而是教你**在 `Data` 里找路**：每个
数据类型一家四口（`Base`/`Properties`/`Relation.*`/门面 `Data.X`）怎么分层，
`List` 的"关系树"（Membership/Sublist/Permutation/Pointwise）各自在哪、
`Fin` 的构造子与转换、以及 **3.0 的大搬家：`Data.AVL` → `Data.Tree.AVL`**。
行号均实测于 `/Volumes/mac004/lang/agda-stdlib/src`。

对应示例：`../examples/Ex33_stdlib-data.agda`

## 33.1 一家四口的分层（以 List 为准）

`Data/List.agda` 很薄，实测只 public 转发两处（第 17–20 行）：

```text
17:open import Data.List.Base public
19:open import Data.List.Scans.Base public
```

`Data.List.Base` 里的主力函数（实测行号）：

```text
48:map    : (A → B) → List A → List B
54:_++_   : List A → List A → List A
126:foldr  : (A → B → B) → B → List A → B
137:concatMap : (A → List B) → List A → List B
153:length : List A → ℕ
166:replicate : ℕ → A → List A
206:tabulate : ∀ {n} (f : Fin n → A) → List A
210:lookup : (xs : List A) → Fin (length xs) → A
237:reverse : List A → List A
301:take / 306:drop : ℕ → List A → List A
359:filter : ∀ {P : Pred A p} → Decidable P → List A → List A
563:all / 577:any : (A → Bool) → List A → Bool
```

**记住纪律**：`Data.List`（门面）只给 Base+Scans；`map`/`filter` 这些在
`Data.List.Base`。`Membership`/`Sublist`/`Permutation`/`Pointwise` 这些关系
**不在** `Data.List` 邻居里，而在 `Data.List.Relation.*` / `Data.List.Membership.*`
（详见 33.2）。想用 `sort`？它单独一个 `Data.List.Sort`，参数是 `DecTotalOrder`，
不是 `Data.List` 的成员（`Data/List/Sort.agda` 第 12–18 行）。

## 33.2 List 的关系树：Membership / Sublist / Permutation / Pointwise

`Data/List/` 下的关系按"对象类型"分两棵：`Relation/Unary`（单参谓词，如
Membership 里的 `_∈_`）和 `Relation/Binary`（二元关系，如 `_≋_`、`_↭_`、
`_⊆_`）。实测路径：

```text
Data/List/Membership/Propositional.agda       -- _∈_（命题式成员关系）
Data/List/Membership/Setoid.agda              -- Setoid 版成员关系
Data/List/Relation/Binary/Sublist/Propositional.agda  -- _⊆_ 子表
Data/List/Relation/Binary/Permutation/Propositional.agda  -- _↭_ 置换
Data/List/Relation/Binary/Pointwise/Base.agda -- _≋_ 逐点相等
```

每个关系又套 `Base/Properties/Setoid/Propositional` 的格子——**这就是 27 章
"四层"约定的放大型**：同一个"子表"概念，要给出 Propositional（`_≡_`）版与
Setoid 版，因为"元素怎么算相等"在不同场景不一样。

3.0 特别提示：`Permutation.{Propositional|Setoid}` 的 `swap`/`prep` 自定义语法
**移除**了（`CHANGELOG.md` 3.0 高亮第 155–158 行）——网上旧例子的置换图
写法要改成书写的构造子。

## 33.3 Fin：构造子 + 转换 + 网络

`Data/Fin/Base.agda` 实测：

```text
34:data Fin : ℕ → Set where
35:  zero : Fin (suc n)          -- 注意：zero 是 Fin (suc n)，不是 Fin n！
36:  suc  : (i : Fin n) → Fin (suc n)
40:toℕ     : Fin n → ℕ
75:fromℕ   : (n : ℕ) → Fin (suc n)      -- 恒要成功：0..n
81:fromℕ<  : .(m ℕ.< n) → Fin n          -- 要失败证明才能压进 Fin n
126:inject≤ : Fin m → .(m ℕ.≤ n) → Fin n  -- 把一个 Fin 压进更大的界
```

**头号心智**：`zero` 的索引是 `Fin (suc n)` 而非 `Fin n`。所以"最大元素
`fromℕ (n - 1)`"这类直觉要换算成 `Fin (suc n)`。`Data/Fin.agda`（门面）实测
额外 public 转发 `Data.Fin.Properties`，并给出 `#_`（第 29 行）：

```text
29:#_ : ∀ m {n} {m<n : True (m ℕ.<? n)} → Fin n
```

`#_ 3` 之类当你证明 `3 < n` 时就是 `Fin n` 的直接字面量。（27 章已提过
`Fin` 构造子 3.0 是 `zero`/`suc`。）

## 33.4 3.0 大搬家：Data.AVL → Data.Tree.AVL

**3.0 把整个 AVL 树从 `Data.AVL` 挪到 `Data.Tree.AVL`**（`CHANGELOG.md` 3.0
高亮列出的删除模块里 `Data.AVL` 及它一整个 `.Indexed/.Map/...` 家族全在）。
新路径实测：

```text
Data/Tree/AVL.agda          -- 主模块：module Data.Tree.AVL {a ℓ₁ ℓ₂} (strictTotalOrder : StrictTotalOrder a ℓ₁ ℓ₂)
Data/Tree/AVL/Key.agda      -- Key 来自 StrictTotalOrder.Carrier
Data/Tree/AVL/Value.agda    -- record Value + 构造子 MkValue
Data/Tree/AVL/IndexedMap.agda
Data/Tree/AVL/Sets.agda
```

主 `data Tree` 与操作（`Data/Tree/AVL.agda` 第 49–116 行）：

```text
49:data Tree {v} (V : Value v) : Set (a ⊔ v ⊔ ℓ₂) where
60:singleton : (k : Key) → Val k → Tree V
63:insert : (k : Key) → Val k → Tree V → Tree V
70:delete : Key → Tree V → Tree V
73:lookup : Tree V → (k : Key) → Maybe (Val k)
90:member : Key → Tree V → Bool
103:foldr / 108:fromList / 113:toList / 116:size
```

一条要命的点（实测第 37 行）：`open StrictTotalOrder ... renaming (Carrier to Key)`，
所以**键是严格全序的 `Carrier`**。想建一棵 `Data.Tree.AVL`，你得先有一个
`StrictTotalOrder`（31 章讲过怎么造）。凡看到 AVL 旧文档里 `Data.AVL.Map`，
一律改成 `Data.Tree.AVL`（`Map` 也在新路径下）。

## 坑位清单

1. **`Data.List` 门面很薄**，`Membership`/`Sublist`/`Permutation`/`Pointwise`
   不在它邻居里，去 `Data.List.Relation.*`/`Membership.*` 单独 import。
2. **`sort` 不在 `Data.List`**：`Data.List.Sort` 单独模块，参数是 `DecTotalOrder`；
   且官方排序不配合 `refl`（27 章头号坑），要算用 `merge`。
3. **`Fin.zero` 是 `Fin (suc n)`**：想表示"0..n-1"你自己负责把界+1，`fromℕ<`
   才给 `Fin n` 且要失败证明。
4. **`Data.AVL` → `Data.Tree.AVL`**：3.0 删除 `Data.AVL.*` 整族，旧 import 全
   `No such module`，`Key` 是 `StrictTotalOrder.Carrier`。
5. **Permutation 的 `swap`/`prep` 语法 3.0 移除**：改用声明式构造子。
6. **`filter` 要 `Decidable P`**（`Dec p → ...`，不是 `Bool`）：想按谓词过滤，
   先给出判定（30 章）。

---
上一章：[32 · stdlib 函数论与类型运算](32-stdlib-functions.md) ｜ 下一章：[34 · stdlib 自动证明](34-stdlib-automation.md) ｜ 返回：[README](../README.md)