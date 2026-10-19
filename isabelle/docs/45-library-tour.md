# 45 · HOL-Library 选讲

对应示例：`../examples/T45_library_tour.thy`（IsaTutLib 会话）

## 45.1 一句话概括

Main 之外的下一站：`HOL-Library` 几十个"值得进标准库但不必进
Main"的理论。本章按使用频率挑四件：多重集（Multiset）、
子序列（Sublist）、关联表（AList）、while 组合子
（While_Combinator——第 35 章手搓版的官方正品）。

## 45.2 Multiset

```isabelle
value "count ({#1, 2, 2#} + {#2, 3#} :: nat multiset) 2"
value "set_mset ({#1, 2, 2#} + {#3#} :: nat multiset)"
```

`'a multiset` 是带重数的袋子：字面量 `{# ... #}`、并 `+`
（重数相加）、`count`、`set_mset`、`add_mset`（加一个）。
它是 multiset 序（终止性度量的主力）的载体。

## 45.3 Sublist

```isabelle
value "prefix [1, 2] [1, 2, 3 :: nat]"
value "suffix [2, 3] [1, 2, 3 :: nat]"
value "sublist [1, 3] [1, 2, 3 :: nat]"
```

`prefix_def` 一族是证明的抓手：`prefix xs ys ⟹ length xs ≤ length ys`
一行 auto。

## 45.4 AList

```isabelle
value "map_of [(1::nat, ''a''), (2::nat, ''b'')] (2::nat)"
value "map_of (AList.update (2::nat) ''B'' [(1::nat, ''a''), (2::nat, ''b'')]) (2::nat)"
```

`(k × v) list` 上"先到先得"的查找——**查找用 Main 的 `map_of`**，
维护用 `AList.update`（qualified）。实测**没有** `AList.lookup`
这个函数；`(op =)` 语法在 2025-2 里要写 `((=))`。

## 45.5 While_Combinator

```isabelle
value "while_option (λn. n ≠ (1::nat))
  (λn. if even (n::nat) then n div 2 else 3 * n + 1) 6"
```

Collatz 从 6 实测会到 1。配套定理：`while_option_stop`
（终态必不满足条件）、`while_option_induct`（对执行步数归纳）。
第 35 章的 `mywhile` 手搓版与它逐条对应。

## 45.6 其余货架（指路节）

本章四行 imports 只是入口。同一会话里的其余货架按去处指路：

- **字典两族**：fmap 与 Mapping 抽象字典见第 57 章；红黑树后端
  与 RBT_Set（集合的对数实现）见第 59 章；DAList 是带「键互异」
  不变量的抽象关联表（`DAList.lookup` 在它上面，不在 AList 上）。
- **集合有限化**：FSet 与 Disjoint_FSets 见第 58 章。
- **序与排序**：Comparator、Sorting_Algorithms、List_Lexorder、
  Prefix_Order 等见第 60 章。
- **代码生成周边**：Code_Target_Numeral（按目标语言编译数字，
  第 19/37 章的延伸，第 65 章再深挖）、Code_Lazy（惰性化任意
  datatype，第 36 章流的可执行化）。
- **计数**：Permutations（排列与组合计数）、Tree/Tree23（搜索树
  家族，第 59 章 Tree 的兄弟）。

## 45.7 坑位清单（实测）

1. Library 理论**必须**从 HOL-Library 会话引入
   （`imports "HOL-Library.Multiset"`）；裸名在 Main 会话报 undefined。
2. `{# ... #}` 字面量要带 `nat multiset` 标注（数字字面量老坑复发）。
3. AList 确实**没有** `lookup`（45.4 已实测）：查找用 Main 的
   `map_of`；`lookup` 在 DAList 的抽象关联表上（与第 57 章
   Mapping 是近亲）。旧版 Isabelle 的 `AList.lookup`（带相等
   函数参数）早已移除，别照旧书抄。
4. `sublist` 谓词版/布尔版重载，签名看清再用。

## 45.8 与其他章的接口

- 第 40 章 Main 漫游：本章是其续集。
- 第 35 章 partial_function：while_option 的家。
- 第 52 章 Newman：multiset 序是终止性度量的主力。
