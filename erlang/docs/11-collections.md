# 11 · 容器与配置结构

> 对应示例：`examples/11_collections/`（proplists / sets / queue / array）

## 11.1 proplists：配置的标准形状

```erlang
Opts = [{verbose, true}, debug, {retries, 3}, 42].
proplists:get_value(debug, Opts).    %% true —— 裸原子等价 {debug, true}
proplists:get_value(missing, Opts).  %% undefined（三参版可给默认值）
proplists:lookup(retries, Opts).     %% {retries,3}——拿整项而不是值
```

OTP 的选项、sys.config、gen_server 启动参数到处是它。**不合法项（如裸整数 42）被取值函数静默忽略**——`get_keys` 也不把它算作键；`lists:keysort(1, Opts)` 更是直接 badarg（裸原子不是元组）。

## 11.2 重复键：先给的赢（与 map 相反）

```erlang
proplists:get_value(level, [{level, warn}, {level, info}]).   %% warn
maps:from_list([{level, warn}, {level, info}]).                %% #{level => info}
```

这正是「命令行 > 配置文件 > 默认值」的覆盖语义——**高优先级的放前面，不要合并**。取全部值用 `get_all_values/2`。

## 11.3 布尔开关

`get_bool(debug, Opts)` 在"没写"和"写了 false"时都返回 false——**无法区分**；要区分用 `is_defined/2`。命令行开关（`--verbose`）的经典形态就是裸原子。

## 11.4 三套集合实现

| | sets | ordsets | gb_sets |
|---|---|---|---|
| 内部表示 | map | 有序列表 | 平衡树 |
| 成员判断 | O(1) | O(n) | O(log n) |
| to_list 顺序 | **随机**（必须 sort） | 天然有序 | 中序遍历有序 |
| 独有能力 | — | — | smallest/largest/larger/smaller、iterator |

集合代数（union/intersection/subtract/is_subset）三套语义一致。选型：频繁成员判断→sets；元素少要有序→ordsets；元素多要有序或区间查询→gb_sets。

顺带一提：stdlib 还有个 `sofs`（sets of sets）模块，把集合论整套搬到了 Erlang——集合、关系（relation）、函数（function）三族类型，支持交并差、笛卡尔积、关系复合（`composition`）、逆（`converse`）、像（`image`）等几十种运算，元素可以是任意 Erlang 项。它表达能力很强（`to_external/from_external` 与列表互转），但表示重、API 数学味浓，工程里多数集合需求三套实现就够了——知道它存在、做复杂关系演算时想得起它即可。

## 11.5 queue：注意 in 与 snoc

```erlang
queue:in(4, Q).      %% 尾部加（常规入队）
queue:in_r(0, Q).    %% 头部加（cons 等价）
queue:snoc(Q, 4).    %% 等价于 in —— 但**参数顺序反了**（Q 在前）！
queue:out(Q).        %% {{value, X}, Q2} | {empty, Q}
```

内部是两个列表，均摊 O(1)。BFS/工作队列用它，别用 `list ++ [X]`。

OTP 24 起 queue 补全了 lists 风格的高阶函数，不用再 `to_list` 出来处理：

```erlang
Q = queue:from_list([1, 2, 3, 4]).
queue:fold(fun(X, Acc) -> X + Acc end, 0, Q).    %% 10：从队头开始折
queue:member(3, Q).                               %% true
queue:all(fun(X) -> X > 0 end, Q).                %% true
queue:any(fun(X) -> X > 3 end, Q).                %% true
queue:to_list(queue:filtermap(
                fun(X) -> case X rem 2 of 0 -> {true, X * 10}; _ -> false end end, Q)).
%% [20, 40]：filtermap 返回的是新 queue，看内容要过 to_list
queue:to_list(queue:delete(2, Q)).                          %% [1,3,4]：删队头起第一个匹配
queue:to_list(queue:delete_r(1, queue:from_list([1,2,1]))). %% [1,2]：从队尾方向删
queue:to_list(queue:delete_with(fun(X) -> X rem 2 =:= 0 end, Q)).    %% [1,3,4]：删队头起首个偶数
queue:to_list(queue:delete_with_r(fun(X) -> X rem 2 =:= 0 end, Q)).  %% [1,2,3]：删队尾起首个偶数
```

两个要点：① `filtermap`、`delete*` 返回**新 queue** 而不是列表；② `_r` 后缀表示"从队尾方向操作"，**参数顺序不变**——`delete_r(Item, Q)` 与 `delete(Item, Q)` 同序，这跟 `in/1` 对 `snoc/2` 的参数序反转不是一回事。

## 11.6 array：稀疏数组

```erlang
array:get(9, array:from_list([a, b, c])).   %% undefined——越界不报错，返回默认值
S = array:set(1000, x, array:new()).
array:size(S).            %% 1001（随最大下标增长，含默认值条目）
array:sparse_to_orddict(S).   %% [{1000,x}]——只列真正设过的
```

`size` 含默认值条目、`sparse_size` 是"到最后一个非默认条目为止"、`sparse_to_orddict` 才是"真正存了几个"——三个语义完全不同。

## 11.7 gb_trees：有序的 map

map 的迭代顺序是随机的（10.4），需要"按键有序"时上 `gb_trees`——一棵平衡二叉搜索树，查询/插入 O(log n)，中序遍历天然升序。除了与 map 对应的 `enter/lookup/get/update/delete`，它的独有能力是**有序遍历与邻居查询**：

```erlang
T = gb_trees:from_orddict(lists:sort([{3, c}, {1, a}, {2, b}])).
gb_trees:next(gb_trees:iterator(T)).    %% {1, a, Iter2}：迭代器按键升序走
gb_trees:larger(1, T).                  %% {2, b}：严格大于 1 的最小键
gb_trees:smaller(3, T).                 %% {2, b}：严格小于 3 的最大键
gb_trees:larger(9, T).                  %% none——越界返回 none，不抛异常
gb_trees:take_smallest(T).              %% {1, a, T2}：取走最小项（最大用 take_largest）
```

`larger/smaller` 是区间查询的答案（"日程表里 9 点以后的第一个会议"）；`take_smallest/take_largest` 让 gb_trees 直接当**优先队列**用。这一族（含 `next/1`、`map/2`）OTP 17 就齐了。gb_sets 是它的"只要键"版本，独有能力同一套。

## 11.8 digraph：进程持有的可变图

`digraph` 是有向图的老牌实现，算法配套在 `digraph_utils`：

```erlang
G = digraph:new(),
digraph:add_vertex(G, a), digraph:add_vertex(G, b), digraph:add_vertex(G, c),
digraph:add_edge(G, a, b), digraph:add_edge(G, b, c),
digraph:get_short_path(G, a, c).    %% [a, b, c]
digraph_utils:topsort(G).           %% [a, b, c]——有环时返回 false（实测）
digraph:delete(G).                  %% true——用完必须手动释放
```

两条天性来自它的实现——**图存在 ETS 里**：① `add_vertex/add_edge` 是**原地修改**，返回的不是新图（`add_edge` 返回的是边 id，形如 `[$e | 0]`）；② ETS 表不随变量出作用域消失，**不 `delete` 就泄漏到持有进程终结**。也正因 ETS 背书，digraph 可以跨进程共享（`new([protected])` 等选项控制可见性）。依赖分析、任务编排这类"图跟着进程走"的场景它依然称职，但新项目先看下一节。

## 11.9 graph：纯函数式图（OTP 29）

OTP 29 新增的 `graph` 模块把 digraph/digraph_utils 的能力做成了**纯函数式**：每次修改返回新图，旧值不变、用完交给 GC，没有 delete 纪律，也不怕共享时的竞态。

```erlang
G0 = graph:new(),
{A, G1} = graph:add_vertex(G0),     %% A = 0：顶点 id 从 0 递增，返回 {Id, 新图}
{B, G2} = graph:add_vertex(G1),
G3 = graph:add_edge(G2, A, B),      %% add_edge 直接返回新图（不是元组）
graph:edges(G3).                    %% [{0, 1, []}]：边是 {From, To, Label} 三元组
graph:topsort(G3).                  %% [0, 1]——digraph_utils 的算法全部内置
```

三个与 digraph 不同的设计点：

1. **边由 `{From, To, Label}` 三元组标识**，默认 label 是 `[]`。同一对 From/To 之间可以有多条 label 不同的边——`graph:add_edge(G, X, Y, fast)` 与 `graph:add_edge(G, X, Y, slow)` 并存，`edges/1` 会列出 `[{0,1,fast},{0,1,slow}]`；
2. **可选无环约束**：`graph:new([acyclic])` 创建的图，加成环边直接抛 `{bad_edge, {From, To}}`（实测）——DAG 场景由数据结构替你兜底；
3. **返回值形态两套**：`add_vertex` 返回 `{顶点id, 新图}`（id 要分配给你），`add_edge` 直接返回新图（边由三元组标识，不需要单独 id）。

从 digraph 迁移的心智切换只有一句话：每次修改都返回新图、必须接住返回值。选型：新代码默认 graph；确实需要跨进程共享可变图时再回 digraph（并牢记 delete）。

## 11.10 带选项的 API 模板

```erlang
open(Opts) ->
    Mode = proplists:get_value(mode, Opts, read),      %% ① 合并默认值
    ...
    Unknown = [K || {K, _} <- Opts, not lists:member(K, Known)],
    ... {error, {unknown_options, ...}} ...            %% ② 不认识的键报错
```

不认识的选项**必须报错**而不是静默忽略——`{retry, 5}`（拼错的 retries）静默吞掉就是线上事故。

## 11.11 坑位清单

1. **proplists 的裸项静默忽略**：`[42]` 混进选项列表没人报错；`lists:keysort` 则直接崩——形状校验自己做。
2. **get_bool 区分不了"没写"与"false"**：要区分用 `is_defined/2`。
3. **sets 的 to_list 顺序随机**：与 map 同源（内部就是 map），输出前 sort。
4. **queue:snoc 参数顺序与 in 相反**：`in(Item, Q)` vs `snoc(Q, Item)`；但 OTP 24 的 `delete_r(Item, Q)` 参数序不变，`_r` 只是操作方向。
5. **array 越界返回默认值不报错**：写错下标不会崩，只会拿到 undefined——排查更难。
6. **proplists:property/1,2 是构造器不是判定器**：`property(a, true)` 缩成裸原子 `a`；它不做合法性检查（对源码核过）。
7. **digraph 用完必须 `digraph:delete/1`**：图存在 ETS 里，不删就泄漏到进程终结；OTP 29 起新代码优先纯函数式的 graph（11.8/11.9）。
8. **gb_trees 邻居查询越界返回 `none`**：`larger/smaller` 找不到不抛异常，记得匹配 `none` 分支（11.7）。
9. **graph 的两种返回值形态**：`add_vertex` 返回 `{顶点id, 新图}`、`add_edge` 直接返回新图——别统一按 `{_, G}` 去匹配（11.9）。

---

---

上一章：[10 映射与记录](10-maps.md) · 下一章：[12 异常与错误哲学](12-errors.md)
