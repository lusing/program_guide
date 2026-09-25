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

## 45.6 其余货架（文档节）

Code_Target_Numeral（按目标语言编译数字）、Code_Lazy（惰性化
任意 datatype，第 36 章流的可执行化）、DAList、Permutations
（排列与组合计数）、Disjoint_Sets、List_Lexorder（列表字典序
instance）、Tree/Tree23（搜索树家族）。取货单就是本章头部的
四行 imports。

## 45.7 坑位清单（实测）

1. Library 理论**必须**从 HOL-Library 会话引入
   （`imports "HOL-Library.Multiset"`）；裸名在 Main 会话报 undefined。
2. `{# ... #}` 字面量要带 `nat multiset` 标注（数字字面量老坑复发）。
3. `AList.lookup` 第一个参数是相等函数。
4. `sublist` 谓词版/布尔版重载，签名看清再用。

## 45.8 与其他章的接口

- 第 40 章 Main 漫游：本章是其续集。
- 第 35 章 partial_function：while_option 的家。
- 第 52 章 Newman：multiset 序是终止性度量的主力。
