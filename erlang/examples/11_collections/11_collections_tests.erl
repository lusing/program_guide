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

options_api_test() ->
    ?assertEqual({ok, [{mode, read}, {retries, 3}, {verbose, false}]},
                 '11_collections':describe_open([])),
    ?assertEqual({ok, [{mode, append}, {retries, 3}, {verbose, true}]},
                 '11_collections':describe_open([{mode, append}, verbose])),
    ?assertEqual({error, {bad_mode, destroy}},
                 '11_collections':describe_open([{mode, destroy}])),
    ?assertEqual({error, {unknown_options, [retry]}},
                 '11_collections':describe_open([{mode, read}, {retry, 5}])).
