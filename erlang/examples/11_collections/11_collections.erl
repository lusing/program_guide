%% ============================================================
%% 11_collections —— proplists、sets、queue、array
%%
%%    都是「配置/容器」，但标准库给了好几套实现，接口相似、
%%    代价与顺序完全不同。这一章把选型讲清楚：
%%      proplists  配置与选项列表（允许重复键、先给的赢）
%%      sets/ordsets/gb_sets  三套集合（map/有序列表/平衡树）
%%      queue      FIFO（in/snoc 参数顺序相反！）
%%      array      稀疏数组（越界不报错）
%%      gb_trees   有序的 map（邻居查询 / 优先队列）
%%      digraph    进程持有的可变图（ETS，用完必须 delete）
%%      graph      OTP 29 纯函数式图（每次修改返回新图）
%%
%%    本示例所有输出都先归一化（sort / to_list），因为
%%    sets 的遍历顺序每次启动都随机。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/11_collections examples/11_collections/11_collections.erl
%% 运行：
%%   erl -noshell -pa build/11_collections -run '11_collections' main -s init stop
%% ============================================================
-module('11_collections').

-export([main/0, open/1, describe_open/1, mk/2, as_list/2, raises/2]).

main() ->
    proplist_shapes(),
    proplist_duplicates(),
    proplist_flags(),
    set_impls(),
    set_algebra(),
    gb_sets_extras(),
    queues(),
    queue_hofs(),
    arrays(),
    gb_trees(),
    digraphs(),
    graphs(),
    options_api(),
    choosing(),
    io:format("~n==== 11 结束 ====~n").

%% 1) proplists：形状与读取
%% ------------------------------------------------------------
%% 属性列表（proplist）里的项有三种合法形状：
%%   {Key, Value}   最常见
%%   Key            裸原子，被当成 {Key, true}
%%   其它           会被取值函数**静默忽略**（不报错！）
proplist_shapes() ->
    io:format("== 1) proplists：形状与读取 ==~n"),
    Opts = [{verbose, true}, debug, {retries, 3}, 42],
    d("属性列表（42 不是合法项，会被静默忽略）", Opts),
    d("get_value(verbose, Opts)", proplists:get_value(verbose, Opts)),
    d("get_value(debug, Opts)（裸原子等价 {debug,true}）",
      proplists:get_value(debug, Opts)),
    d("get_value(missing, Opts) → undefined", proplists:get_value(missing, Opts)),
    d("get_value(missing, Opts, 60) → 三参版兜底",
      proplists:get_value(missing, Opts, 60)),
    d("lookup(debug, Opts)（拿整个项而不是值）", proplists:lookup(debug, Opts)),
    d("get_keys（裸原子算键；42 这种非法项不算；顺序随机 → 先 sort）",
      lists:sort(proplists:get_keys(Opts))),
    d("lists:keyfind 也能用（proplist 就是列表）", lists:keyfind(retries, 1, Opts)),
    %% 注意 lists:keysort(1, Opts) 会崩：裸原子 debug 不是元组，element(1,·) badarg
    d("keysort 对含裸原子的 proplist 会抛",
      raises(fun(L) -> lists:keysort(1, L) end, Opts)),
    ok.

%% 2) 重复键：先给的赢（与 map 相反）
%% ------------------------------------------------------------
%% 典型的「合并配置」写法：把「高优先级的那份」放在**前面**、不要合并。
proplist_duplicates() ->
    io:format("~n== 2) 重复键：先给的赢 ==~n"),
    P = [{level, warn}, {level, info}, {level, debug}],
    d("get_value 取**第一个**", proplists:get_value(level, P)),
    d("get_all_values 取全部", proplists:get_all_values(level, P)),
    M = maps:from_list(P),
    d("对照 map：from_list 只剩最后一个", maps:to_list(M)),
    Defaults = [{retries, 3}, {timeout, 60}],
    User = [{timeout, 5}],
    d("默认值 + 用户值（用户放前面 → 用户赢）",
      [{K, proplists:get_value(K, User, proplists:get_value(K, Defaults, undefined))}
       || {K, _} <- Defaults]),
    ok.

%% 3) 布尔开关：get_bool 无法区分「没写」和「写了 false」
%% ------------------------------------------------------------
proplist_flags() ->
    io:format("~n== 3) 布尔开关 ==~n"),
    d("get_bool(debug, [debug])", proplists:get_bool(debug, [debug])),
    d("get_bool(debug, [{debug,false}])", proplists:get_bool(debug, [{debug, false}])),
    d("get_bool(debug, [])（不存在也是 false）", proplists:get_bool(debug, [])),
    d("想区分就用 is_defined/2",
      {proplists:is_defined(debug, []), proplists:is_defined(debug, [{debug, false}])}),
    ok.

%% 4) 三套集合实现：接口名几乎一样，顺序完全不同
%% ------------------------------------------------------------
set_impls() ->
    io:format("~n== 4) 三套集合 ==~n"),
    L = [c, a, b, z, a],
    d("输入（注意 a 出现两次）", L),
    d("sets:to_list（顺序随机！必须 sort）", lists:sort(sets:to_list(mk(sets, L)))),
    d("ordsets:to_list（有序列表实现，天然有序）", as_list(ordsets, mk(ordsets, L))),
    d("gb_sets:to_list（树的中序遍历，也是有序的）",
      as_list(gb_sets, mk(gb_sets, L))),
    d("三套的 size 一致",
      [{I, elem_size(I, mk(I, L))} || I <- [sets, ordsets, gb_sets]]),
    d("sets 的内部表示（就是个 map）",
      lists:sort(maps:to_list(mk(sets, [a, b])))),
    d("ordsets 的内部表示（就是有序列表本身）", mk(ordsets, [b, a])),
    ok.

mk(sets, L) -> sets:from_list(L);
mk(ordsets, L) -> ordsets:from_list(L);
mk(gb_sets, L) -> gb_sets:from_list(L).

as_list(sets, S) -> lists:sort(sets:to_list(S));
as_list(ordsets, S) -> ordsets:to_list(S);
as_list(gb_sets, S) -> gb_sets:to_list(S).

elem_size(sets, S) -> sets:size(S);
elem_size(ordsets, S) -> ordsets:size(S);
elem_size(gb_sets, S) -> gb_sets:size(S).

%% 5) 集合代数：三套实现结果应当完全一致
%% ------------------------------------------------------------
set_algebra() ->
    io:format("~n== 5) 集合代数 ==~n"),
    A = [1, 2, 3, 4],
    B = [3, 4, 5],
    Impls = [sets, ordsets, gb_sets],
    [d("union/intersection/subtract 在三套实现下的结果",
       {Op, [{I, as_list(I, op(Op, I, mk(I, A), mk(I, B)))} || I <- Impls]})
     || Op <- [union, intersection, subtract]],
    d("is_subset({3,4}, {1..5})",
      [{I, elem_subset(I, mk(I, [3, 4]), mk(I, [1, 2, 3, 4, 5]))} || I <- Impls]),
    ok.

op(union, sets, A, B) -> sets:union(A, B);
op(union, ordsets, A, B) -> ordsets:union(A, B);
op(union, gb_sets, A, B) -> gb_sets:union(A, B);
op(intersection, sets, A, B) -> sets:intersection(A, B);
op(intersection, ordsets, A, B) -> ordsets:intersection(A, B);
op(intersection, gb_sets, A, B) -> gb_sets:intersection(A, B);
op(subtract, sets, A, B) -> sets:subtract(A, B);
op(subtract, ordsets, A, B) -> ordsets:subtract(A, B);
op(subtract, gb_sets, A, B) -> gb_sets:subtract(A, B).

elem_subset(sets, A, B) -> sets:is_subset(A, B);
elem_subset(ordsets, A, B) -> ordsets:is_subset(A, B);
elem_subset(gb_sets, A, B) -> gb_sets:is_subset(A, B).

%% 6) gb_sets 独有能力：最小/最大/区间查询
%% ------------------------------------------------------------
gb_sets_extras() ->
    io:format("~n== 6) gb_sets 独有能力 ==~n"),
    G = mk(gb_sets, [5, 1, 9, 3, 7]),
    d("集合", as_list(gb_sets, G)),
    d("smallest / largest", {gb_sets:smallest(G), gb_sets:largest(G)}),
    {S1, Rest1} = gb_sets:take_smallest(G),
    d("take_smallest → {元素, 剩下的集合}", {S1, as_list(gb_sets, Rest1)}),
    d("larger(4, G)（比 4 大的最小元素）", gb_sets:larger(4, G)),
    d("larger(100, G)（没有更大 → none）", gb_sets:larger(100, G)),
    ok.

%% 7) queue：两端都能进出，但函数名容易记反
%% ------------------------------------------------------------
%%   queue:in(Item, Q)    在**尾部**加（最常见的入队）
%%   queue:in_r(Item, Q)  在头部加；cons 等价于 in_r
%%   queue:snoc(Q, Item)  等价于 in  ← 参数顺序反过来了！
%%   queue:out(Q)         → {{value, X}, Q2} | {empty, Q}
queues() ->
    io:format("~n== 7) queue ==~n"),
    Q = queue:from_list([1, 2, 3]),
    d("from_list([1,2,3]) 后 to_list", queue:to_list(Q)),
    Out = queue:out(Q),
    d("out → {取出的项, 剩下的队列}",
      {element(1, Out), queue:to_list(element(2, Out))}),
    d("in(4, Q) 从尾部加", queue:to_list(queue:in(4, Q))),
    d("in_r(0, Q) 从头部加", queue:to_list(queue:in_r(0, Q))),
    d("snoc(Q, 4) 等价于 in（参数顺序反了）", queue:to_list(queue:snoc(Q, 4))),
    d("join 把两个队列接起来", queue:to_list(queue:join(Q, queue:from_list([4, 5])))),
    d("空队列：is_empty / peek / len",
      {queue:is_empty(queue:new()), queue:peek(queue:new()), queue:len(queue:new())}),
    ok.

%% 8) queue 的 lists 风格高阶函数（OTP 24）
%% ------------------------------------------------------------
%% 不用再 to_list 出来处理。两个要点：
%%   · filtermap / delete* 返回**新 queue**，看内容要过 to_list
%%   · _r 后缀是「从队尾方向操作」，**参数顺序不变** ——
%%     delete_r(Item, Q) 与 delete(Item, Q) 同序
%%     （别跟 in/1 对 snoc/2 的参数序反转搞混）
queue_hofs() ->
    io:format("~n== 8) queue 高阶函数（OTP 24）==~n"),
    Q = queue:from_list([1, 2, 3, 4]),
    d("fold（从队头开始折）", queue:fold(fun(X, Acc) -> X + Acc end, 0, Q)),
    d("member(3) / member(9)", {queue:member(3, Q), queue:member(9, Q)}),
    d("all(>0) / all(>1)", {queue:all(fun(X) -> X > 0 end, Q),
                             queue:all(fun(X) -> X > 1 end, Q)}),
    d("any(>3) / any(>9)", {queue:any(fun(X) -> X > 3 end, Q),
                             queue:any(fun(X) -> X > 9 end, Q)}),
    d("filtermap（偶数 ×10，返回新 queue）",
      queue:to_list(queue:filtermap(
                      fun(X) -> case X rem 2 of
                                    0 -> {true, X * 10};
                                    _ -> false
                                end
                      end, Q))),
    d("delete(2)（删队头起第一个匹配；9 不存在则原样）",
      {queue:to_list(queue:delete(2, Q)), queue:to_list(queue:delete(9, Q))}),
    d("delete_r(1, [1,2,1])（从队尾方向删）",
      queue:to_list(queue:delete_r(1, queue:from_list([1, 2, 1])))),
    d("delete_with(偶数) / delete_with_r(偶数)",
      {queue:to_list(queue:delete_with(fun(X) -> X rem 2 =:= 0 end, Q)),
       queue:to_list(queue:delete_with_r(fun(X) -> X rem 2 =:= 0 end, Q))}),
    ok.

%% 9) array：稀疏数组
%% ------------------------------------------------------------
%%   size/1             条目总数（**含**默认值条目）
%%   sparse_size/1      到「最后一个非默认值条目」为止的条目数
%%   sparse_to_orddict  只列**真正设过**的 {下标, 值}
arrays() ->
    io:format("~n== 9) array：稀疏数组 ==~n"),
    A = array:from_list([a, b, c]),
    d("from_list([a,b,c])", array:to_list(A)),
    d("get(0) / get(2)", {array:get(0, A), array:get(2, A)}),
    %% 越界不报错，而是给默认值 —— 这是最容易踩的一条
    d("get(9)（越界！返回默认值而不是报错）", array:get(9, A)),
    Sparse = array:set(1000, x, array:new()),
    d("set(1000, x, new()) 之后",
      {size, array:size(Sparse), sparse_size, array:sparse_size(Sparse)}),
    d("取中间没设过的下标", array:get(500, Sparse)),
    d("sparse_to_orddict（只列真正设过的）", array:sparse_to_orddict(Sparse)),
    ok.

%% 10) gb_trees：有序的 map
%% ------------------------------------------------------------
%% map 的迭代顺序随机（10 章），要「按键有序」就用平衡二叉搜索树 gb_trees，
%% 查询/插入 O(log n)，中序遍历天然升序。独有能力：有序遍历与邻居查询。
gb_trees() ->
    io:format("~n== 10) gb_trees：有序的 map ==~n"),
    T = gb_trees:from_orddict(lists:sort([{3, c}, {1, a}, {2, b}])),
    d("from_orddict 建树后 to_list（按键升序）", gb_trees:to_list(T)),
    {K1, V1, It1} = gb_trees:next(gb_trees:iterator(T)),
    {K2, V2, _It2} = gb_trees:next(It1),
    d("iterator + next 逐个走（迭代器内部结构不打印）", [{K1, V1}, {K2, V2}]),
    d("iterator_from(2, T)（从 >=2 的第一个键开始）",
      element(1, gb_trees:next(gb_trees:iterator_from(2, T)))),
    d("iterator_from(25, T)（没有 >=25 的键 → none）",
      gb_trees:next(gb_trees:iterator_from(25, T))),
    d("larger(1) / smaller(3)（严格邻居查询）",
      {gb_trees:larger(1, T), gb_trees:smaller(3, T)}),
    d("larger(9)（越界返回 none，不抛异常）", gb_trees:larger(9, T)),
    {SK, SV, Rest} = gb_trees:take_smallest(T),
    d("take_smallest → {键, 值, 剩下的树}（可直接当优先队列）",
      {{SK, SV}, gb_trees:to_list(Rest)}),
    d("map/2 变换值（树结构不变）",
      gb_trees:to_list(gb_trees:map(fun(_K, V) -> [V] end, T))),
    ok.

%% 11) digraph：进程持有的可变图
%% ------------------------------------------------------------
%% 图存在 ETS 里，两条天性都由此而来：
%%   ① add_vertex/add_edge 是**原地修改**，返回的不是新图
%%      （add_edge 返回边 id，形如 [$e|0]）
%%   ② ETS 表不随变量出作用域消失，不 delete 就泄漏到持有进程终结
digraphs() ->
    io:format("~n== 11) digraph：进程持有的可变图 ==~n"),
    G = digraph:new(),
    digraph:add_vertex(G, a), digraph:add_vertex(G, b), digraph:add_vertex(G, c),
    E1 = digraph:add_edge(G, a, b),
    digraph:add_edge(G, b, c),
    d("add_edge 返回的是边 id（不是新图）", E1),
    d("add_edge 引用不存在的顶点 → {error, {bad_vertex, V}}",
      digraph:add_edge(G, a, nope)),
    d("get_short_path(a, c)", digraph:get_short_path(G, a, c)),
    d("digraph_utils:topsort（算法在 digraph_utils 里）",
      digraph_utils:topsort(G)),
    C = digraph:new(),
    digraph:add_vertex(C, c1), digraph:add_vertex(C, c2),
    digraph:add_edge(C, c1, c2), digraph:add_edge(C, c2, c1),
    d("有环时 topsort 返回 false（实测）", digraph_utils:topsort(C)),
    d("delete 释放 ETS 表（用完必须删）", {digraph:delete(G), digraph:delete(C)}),
    ok.

%% 12) graph：纯函数式图（OTP 29）
%% ------------------------------------------------------------
%% 把 digraph/digraph_utils 的能力做成纯函数式：每次修改返回新图，
%% 旧值不变、用完交给 GC，没有 delete 纪律。三个不同的设计点：
%%   · 边由 {From, To, Label} 三元组标识（默认 label 是 []），
%%     同一对顶点间可以有多条 label 不同的边
%%   · graph:new([acyclic]) 创建的图，加成环边直接抛 bad_edge
%%   · 返回值两套：add_vertex → {顶点id, 新图}，add_edge → 新图
graphs() ->
    io:format("~n== 12) graph：纯函数式图（OTP 29）==~n"),
    G0 = graph:new(),
    {A, G1} = graph:add_vertex(G0),
    {B, G2} = graph:add_vertex(G1),
    d("add_vertex 返回 {顶点id, 新图}（id 从 0 递增）", {A, B}),
    G3 = graph:add_edge(G2, A, B),
    d("add_edge 直接返回新图；edges 是 {From,To,Label} 三元组", graph:edges(G3)),
    d("topsort（算法内置，不再需要 digraph_utils）", graph:topsort(G3)),
    G4 = graph:add_edge(graph:add_edge(G3, A, B, fast), A, B, slow),
    d("同一对顶点间多条不同 label 的边并存", graph:edges(G4)),
    {X, D1} = graph:add_vertex(graph:new([acyclic])),
    {Y, D2} = graph:add_vertex(D1),
    D3 = graph:add_edge(D2, X, Y),
    d("[acyclic] 图加成环边直接抛 bad_edge（实测）",
      raises(fun(DG) -> graph:add_edge(DG, Y, X) end, D3)),
    ok.

%% 13) 实战：带选项的 API（见文件尾部 open/1）
%% ------------------------------------------------------------
options_api() ->
    io:format("~n== 13) 实战：带选项的 API ==~n"),
    d("全用默认值", describe_open([])),
    d("改两个", describe_open([{mode, write}, {retries, 0}])),
    d("布尔开关写成裸原子", describe_open([{mode, append}, verbose])),
    d("mode 非法", describe_open([{mode, destroy}])),
    d("多写了不认识的键（应该报错，而不是静默忽略）",
      describe_open([{mode, read}, {retry, 5}])),
    ok.

%% 14) 该用哪个
%% ------------------------------------------------------------
choosing() ->
    io:format("~n== 14) 选择建议 ==~n"),
    Tips = [{"频繁成员判断、不在乎顺序", "sets（O(1)，to_list 顺序随机）"},
            {"元素少且要按序遍历", "ordsets（实现就是有序列表）"},
            {"元素多、要按序或取最小/最大", "gb_sets（O(log n)，功能最全）"},
            {"FIFO 队列", "queue（均摊 O(1)，别用 list ++）"},
            {"下标是整数、大部分为空", "array（越界返回默认值）"},
            {"键是任意项、要 O(1) 查找", "map（10 章）"},
            {"键要按键有序遍历/邻居查询", "gb_trees（键上有值；只要键用 gb_sets）"},
            {"有向图 / 任务编排", "graph（OTP 29 纯函数式；需跨进程共享可变图才回 digraph）"}],
    [io:format("  ~ts -> ~ts~n", [K, V]) || {K, V} <- Tips],
    ok.

%% 实战：一个带选项的 API（proplists 最正经的用途：函数的「命名参数」）
%% ------------------------------------------------------------
%% 要点：先合并默认值，再校验取值范围，最后**别保留用户给错的键**。
open(Opts) ->
    Mode = proplists:get_value(mode, Opts, read),
    Retries = proplists:get_value(retries, Opts, 3),
    Verbose = proplists:get_bool(verbose, Opts),
    Known = [mode, retries, verbose],
    Unknown = [K || {K, _} <- Opts, not lists:member(K, Known)]
        ++ [K || K <- Opts, is_atom(K), not lists:member(K, Known)],
    case lists:member(Mode, [read, write, append]) of
        false -> {error, {bad_mode, Mode}};
        true when not is_integer(Retries); Retries < 0 ->
            {error, {bad_retries, Retries}};
        true when Unknown =/= [] ->
            {error, {unknown_options, lists:sort(Unknown)}};
        true ->
            {ok, #{mode => Mode, retries => Retries, verbose => Verbose}}
    end.

describe_open(Opts) ->
    case open(Opts) of
        {ok, M} -> {ok, lists:sort(maps:to_list(M))};
        {error, R} -> {error, R}
    end.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

raises(F, Arg) ->
    try F(Arg) catch Class:Reason -> {Class, Reason} end.
