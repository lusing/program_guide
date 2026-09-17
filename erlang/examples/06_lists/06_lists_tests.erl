%% ============================================================
%% 06_lists 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/06_lists examples/06_lists/*_tests.erl
%%   erl -noshell -pa build/06_lists -eval "eunit:test('06_lists_tests'), halt()."
%% ============================================================
-module('06_lists_tests').

-include_lib("eunit/include/eunit.hrl").

my_map_test() ->
    ?assertEqual([3, 6, 9],
                 '06_lists':my_map(fun(X) -> X * 3 end, [1, 2, 3])),
    ?assertEqual('06_lists':my_map(fun(X) -> X + 1 end, lists:seq(1, 50)),
                 lists:map(fun(X) -> X + 1 end, lists:seq(1, 50))).

my_filter_test() ->
    ?assertEqual([3, 6],
                 '06_lists':my_filter(fun(X) -> X rem 3 =:= 0 end, [1, 2, 3, 4, 5, 6])),
    ?assertEqual('06_lists':my_filter(fun(X) -> X > 2 end, lists:seq(1, 20)),
                 lists:filter(fun(X) -> X > 2 end, lists:seq(1, 20))).

my_foldl_test() ->
    ?assertEqual(10, '06_lists':my_foldl(fun(X, A) -> A + X end, 0, [1, 2, 3, 4])),
    ?assertEqual([3, 2, 1],
                 '06_lists':my_foldl(fun(X, A) -> [X | A] end, [], [1, 2, 3])).

my_reverse_test() ->
    ?assertEqual([], '06_lists':my_reverse([])),
    ?assertEqual([3, 2, 1], '06_lists':my_reverse([1, 2, 3])),
    ?assertEqual('06_lists':my_reverse(lists:seq(1, 100)),
                 lists:reverse(lists:seq(1, 100))).

split_even_odd_test() ->
    ?assertEqual({[2, 4], [1, 3, 5]},
                 '06_lists':split_even_odd([1, 2, 3, 4, 5])).

nth_is_one_based_test() ->
    %% lists:nth 从 1 开始（06 章 2 节的坑）
    ?assertEqual(b, lists:nth(2, [a, b, c])),
    %% nth(0) 没有子句能匹配 → function_clause
    ?assertException(error, function_clause, lists:nth(0, [a])).

keyfind_returns_false_test() ->
    %% keyfind 找不到返回 false（不是 error / [] / none）
    ?assertEqual(false, lists:keyfind(z, 1, [{a, 1}])),
    ?assertEqual({b, 2}, lists:keyfind(b, 1, [{a, 1}, {b, 2}])).

usort_test() ->
    ?assertEqual([1, 2, 3], lists:usort([3, 1, 2, 1, 3])),
    %% usort 按项序排混合类型：number < atom
    ?assertEqual([1, 2.0, a, b, "x"], lists:usort([b, 1, a, 2.0, "x"])).
