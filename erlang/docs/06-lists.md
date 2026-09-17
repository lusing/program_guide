# 06 · 列表

> 对应示例：`examples/06_lists/`

## 6.1 列表是 singly-linked 链表

```erlang
[H | T] = [1, 2, 3].        %% H=1, T=[2,3]：取头是 O(1)
[1, 2] ++ [3, 4].           %% 拼接：代价正比于**左边**的长度
lists:reverse([1, 2, 3], [9]).   %% 带尾初值：[3,2,1,9]
```

只有头插 `[X | L]` 是 O(1)；`length/1`、`lists:last/1`、`++`、`--`、`nth/2` 全是 O(N)。**在循环里往尾部 `++` 是 O(N²)**——攒到头上、最后 `lists:reverse` 一次。

## 6.2 取元素：从 1 开始

```erlang
lists:nth(2, [a,b,c,d,e]).     %% b —— 1 基，nth(0, _) 是 function_clause
lists:sublist(L, 2, 3).        %% 从第 2 个起取 3 个
lists:partition(Pred, L).      %% {满足, 不满足}
lists:splitwith(Pred, L).      %% {Pred 为真的前缀, 其余}——边界在第一次不满足处
```

## 6.3 高阶函数四件套

```erlang
lists:map(F, L).        %% 变换
lists:filter(Pred, L).  %% 过滤
lists:foldl(F, Acc, L). %% 从左折：((((0+1)+2)+3)+4)+5
lists:foldr(F, Acc, L). %% 从右折
```

`foldl` 与 `foldr` 构造列表时**方向相反**：foldl 头插攒出逆序，foldr 正序。组合件：`flatmap`、`filtermap`（一个 fun 同时管过滤与变换）、`mapfoldl`（边变换边累积）、`zip`/`zipwith`/`enumerate`/`join`。

## 6.4 查找：四种"查不到"，四种返回

| 函数 | 查不到返回 |
|---|---|
| `lists:keyfind/3`、`lists:search/2` | `false` |
| `maps:find/2` | `error` |
| `ets:lookup/2` | `[]` |
| `proplists:get_value/2` | `false`（`lookup/2` 是 `none`） |

**没有一致性可言**——用之前先确认（这是 stdlib 最令人头疼的地方）。键值对列表专用族：`keyfind / keytake / keystore / keydelete`（`keystore` 存在则替换、不存在则**追加**）。

## 6.5 排序、去重与分组

```erlang
lists:sort(L).                       %% 稳定排序，混合类型按项序
lists:usort([3,1,2,1,3]).            %% [1,2,3]：去重并排序
lists:sort(fun(A,B) -> A >= B end, L).  %% 比较器要返回 =< 语义（这里是降序）
lists:uniq(L).                       %% 只去**相邻**重复；先 sort 再 uniq 才是按值去重
```

没有 `lists:group/1`——"连续相等打包"自己写（示例里的 `group/1`），或用 `maps:groups_from_list/2,3`（OTP 25+，10 章）。

## 6.6 惰性边界：takewhile / dropwhile

```erlang
lists:takewhile(fun(X) -> X < 3 end, [1,2,3,1]).   %% [1,2]：停在第一个不满足
lists:dropwhile(fun(X) -> X < 3 end, [1,2,3,1]).   %% [3,1]：丢前缀，后面的 1 保住了
```

对照 07 章的 `filter`（全表扫描）理解"边界"语义。

## 6.7 坑位清单

1. **`nth` 是 1 基**：从 0 数的语言过来的先改直觉；`nth(0, _)` 抛 `function_clause`。
2. **`++` 代价看左边**：`Acc ++ [X]` 循环 N 次是 O(N²)；`[X | Acc]` + 最后 reverse。
3. **lookup 家族返回值不统一**：`false` / `error` / `[]` / `none`——逐个确认。
4. **`lists:uniq` 只去相邻重复**：`[1,1,2,1]` uniq 完是 `[1,2,1]`。
5. **`join` 是插分隔符**：`lists:join(",", ["a","b"])` 得 `["a",",","b"]`，拼接要再 flatten。
6. **foldl 造列表是逆序**：保序用 foldr 或头插后 reverse。

---
