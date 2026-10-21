%% ============================================================
%% 11_collections 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/11_collections examples/11_collections/*_tests.erl
%%   erl -noshell -pa build/11_collections -eval "eunit:test('11_collections_tests'), halt()."
%% ============================================================
-module('11_collections_tests').

-include_lib("eunit/include/eunit.hrl").

proplist_shape_test() ->
    Opts = [{verbose, true}, debug, {retries, 3}, 42],
    ?assertEqual(true, proplists:get_value(verbose, Opts)),
    ?assertEqual(true, proplists:get_value(debug, Opts)),   %% 裸原子 = {K,true}
    ?assertEqual(undefined, proplists:get_value(missing, Opts)),
    ?assertEqual(60, proplists:get_value(missing, Opts, 60)),
    ?assertEqual({retries, 3}, proplists:lookup(retries, Opts)),
    %% 42 不是合法项：取值函数静默忽略，get_keys 也不把它算作键
    ?assertEqual([debug, retries, verbose], lists:sort(proplists:get_keys(Opts))).

proplist_first_wins_test() ->
    P = [{level, warn}, {level, info}],
    ?assertEqual(warn, proplists:get_value(level, P)),      %% 先给的赢
    ?assertEqual([warn, info], proplists:get_all_values(level, P)),
    %% 对照 map：后写的赢
    ?assertEqual(#{level => info}, maps:from_list(P)).

get_bool_test() ->
    ?assert(proplists:get_bool(debug, [debug])),
    ?assertNot(proplists:get_bool(debug, [{debug, false}])),
    ?assertNot(proplists:get_bool(debug, [])),
    %% 区分「没写」与「写了 false」用 is_defined
    ?assertNot(proplists:is_defined(debug, [])),
    ?assert(proplists:is_defined(debug, [{debug, false}])).

sets_impls_test() ->
    L = [c, a, b, z, a],
    ?assertEqual([a, b, c, z], lists:sort(sets:to_list(sets:from_list(L)))),
    ?assertEqual([a, b, c, z], ordsets:to_list(ordsets:from_list(L))),
    ?assertEqual([a, b, c, z], gb_sets:to_list(gb_sets:from_list(L))).

set_algebra_test() ->
    A = [1, 2, 3, 4], B = [3, 4, 5],
    ?assertEqual([1, 2, 3, 4, 5], ordsets:to_list(ordsets:union(A, B))),
    ?assertEqual([3, 4], ordsets:to_list(ordsets:intersection(A, B))),
    ?assertEqual([1, 2], ordsets:to_list(ordsets:subtract(A, B))),
    ?assert(ordsets:is_subset([3, 4], [1, 2, 3, 4, 5])).

gb_sets_extras_test() ->
    G = gb_sets:from_list([5, 1, 9, 3, 7]),
    ?assertEqual(1, gb_sets:smallest(G)),
    ?assertEqual(9, gb_sets:largest(G)),
    ?assertEqual({1, [3, 5, 7, 9]},
                 begin {S, R} = gb_sets:take_smallest(G),
                       {S, gb_sets:to_list(R)} end),
    ?assertEqual({found, 5}, gb_sets:larger(4, G)),
    ?assertEqual(none, gb_sets:larger(100, G)).

queue_test() ->
    Q = queue:from_list([1, 2, 3]),
    ?assertEqual([1, 2, 3, 4], queue:to_list(queue:in(4, Q))),      %% 尾部加
    ?assertEqual([0, 1, 2, 3], queue:to_list(queue:in_r(0, Q))),    %% 头部加
    ?assertEqual([1, 2, 3, 4], queue:to_list(queue:snoc(Q, 4))),    %% snoc=in 但参数序反
    ?assertEqual({1, [2, 3]},
                 begin {{value, X}, Q2} = queue:out(Q), {X, queue:to_list(Q2)} end).

array_test() ->
    A = array:from_list([a, b, c]),
    ?assertEqual(a, array:get(0, A)),
    ?assertEqual(undefined, array:get(9, A)),        %% 越界返回默认值不报错
    Sparse = array:set(1000, x, array:new()),
    ?assertEqual(1001, array:size(Sparse)),
    ?assertEqual([{1000, x}], array:sparse_to_orddict(Sparse)).

queue_hofs_test() ->
    Q = queue:from_list([1, 2, 3, 4]),
    ?assertEqual(10, queue:fold(fun(X, Acc) -> X + Acc end, 0, Q)),
    ?assert(queue:member(3, Q)),
    ?assertNot(queue:member(9, Q)),
    ?assert(queue:all(fun(X) -> X > 0 end, Q)),
    ?assertNot(queue:all(fun(X) -> X > 1 end, Q)),
    ?assert(queue:any(fun(X) -> X > 3 end, Q)),
    ?assertNot(queue:any(fun(X) -> X > 9 end, Q)),
    %% filtermap / delete* 返回**新 queue**，看内容要过 to_list
    ?assertEqual([20, 40],
                 queue:to_list(queue:filtermap(
                                 fun(X) -> case X rem 2 of
                                               0 -> {true, X * 10};
                                               _ -> false
                                           end
                                 end, Q))),
    ?assertEqual([1, 3, 4], queue:to_list(queue:delete(2, Q))),
    ?assertEqual([1, 2, 3, 4], queue:to_list(queue:delete(9, Q))),  %% 不匹配则原样
    %% _r 后缀是「从队尾方向」，参数顺序不变
    ?assertEqual([1, 2], queue:to_list(queue:delete_r(1, queue:from_list([1, 2, 1])))),
    ?assertEqual([1, 3, 4],
                 queue:to_list(queue:delete_with(fun(X) -> X rem 2 =:= 0 end, Q))),
    ?assertEqual([1, 2, 3],
                 queue:to_list(queue:delete_with_r(fun(X) -> X rem 2 =:= 0 end, Q))).

gb_trees_test() ->
    T = gb_trees:from_orddict(lists:sort([{3, c}, {1, a}, {2, b}])),
    %% 迭代器按键升序走
    {1, a, It1} = gb_trees:next(gb_trees:iterator(T)),
    {2, b, _} = gb_trees:next(It1),
    %% iterator_from 从「大于等于给定键」的第一个开始；越界返回 none
    {2, b, _} = gb_trees:next(gb_trees:iterator_from(2, T)),
    ?assertEqual(none, gb_trees:next(gb_trees:iterator_from(25, T))),
    %% 严格邻居查询：找不到返回 none，不抛异常
    ?assertEqual({2, b}, gb_trees:larger(1, T)),
    ?assertEqual({2, b}, gb_trees:smaller(3, T)),
    ?assertEqual(none, gb_trees:larger(9, T)),
    %% take_smallest 让 gb_trees 直接当优先队列
    ?assertEqual({1, a, [{2, b}, {3, c}]},
                 begin {K, V, T2} = gb_trees:take_smallest(T),
                       {K, V, gb_trees:to_list(T2)} end),
    ?assertEqual([{1, [a]}, {2, [b]}, {3, [c]}],
                 gb_trees:to_list(gb_trees:map(fun(_K, V) -> [V] end, T))).

digraph_test() ->
    G = digraph:new(),
    digraph:add_vertex(G, a), digraph:add_vertex(G, b), digraph:add_vertex(G, c),
    %% add_edge 是原地修改，返回边 id（形如 [$e|0]），不是新图
    ?assertMatch(['$e' | _], digraph:add_edge(G, a, b)),
    digraph:add_edge(G, b, c),
    %% 引用不存在的顶点返回 error，不会自动建顶点
    ?assertEqual({error, {bad_vertex, nope}}, digraph:add_edge(G, a, nope)),
    ?assertEqual([a, b, c], digraph:get_short_path(G, a, c)),
    ?assertEqual([a, b, c], digraph_utils:topsort(G)),
    ?assertEqual(true, digraph:delete(G)).

digraph_cyclic_test() ->
    C = digraph:new(),
    digraph:add_vertex(C, c1), digraph:add_vertex(C, c2),
    digraph:add_edge(C, c1, c2), digraph:add_edge(C, c2, c1),
    %% 有环时不存在拓扑序：topsort 返回 false
    ?assertNot(digraph_utils:is_acyclic(C)),
    ?assertEqual(false, digraph_utils:topsort(C)),
    ?assertEqual(true, digraph:delete(C)).

graph_test() ->
    G0 = graph:new(),
    {A, G1} = graph:add_vertex(G0),
    {B, G2} = graph:add_vertex(G1),
    %% add_vertex 返回 {顶点id, 新图}，id 从 0 递增
    ?assertEqual({0, 1}, {A, B}),
    %% add_edge 直接返回新图；边是 {From, To, Label}，默认 label []
    G3 = graph:add_edge(G2, A, B),
    ?assertEqual([{0, 1, []}], graph:edges(G3)),
    ?assertEqual([0, 1], graph:topsort(G3)),
    %% 同一对顶点间可以有多条 label 不同的边（实测 edges/1 的列出顺序）
    G4 = graph:add_edge(graph:add_edge(G3, A, B, fast), A, B, slow),
    ?assertEqual([{0, 1, fast}, {0, 1, slow}, {0, 1, []}], graph:edges(G4)),
    %% [acyclic] 图加成环边直接抛 bad_edge
    {X, D1} = graph:add_vertex(graph:new([acyclic])),
    {Y, D2} = graph:add_vertex(D1),
    D3 = graph:add_edge(D2, X, Y),
    ?assertEqual({error, {bad_edge, {1, 0}}},
                 '11_collections':raises(fun(DG) -> graph:add_edge(DG, Y, X) end, D3)).

options_api_test() ->
    ?assertEqual({ok, [{mode, read}, {retries, 3}, {verbose, false}]},
                 '11_collections':describe_open([])),
    ?assertEqual({ok, [{mode, append}, {retries, 3}, {verbose, true}]},
                 '11_collections':describe_open([{mode, append}, verbose])),
    ?assertEqual({error, {bad_mode, destroy}},
                 '11_collections':describe_open([{mode, destroy}])),
    ?assertEqual({error, {unknown_options, [retry]}},
                 '11_collections':describe_open([{mode, read}, {retry, 5}])).
