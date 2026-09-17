%% ============================================================
%% 05_recursion 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/05_recursion examples/05_recursion/*_tests.erl
%%   erl -noshell -pa build/05_recursion -eval "eunit:test('05_recursion_tests'), halt()."
%% ============================================================
-module('05_recursion_tests').

-include_lib("eunit/include/eunit.hrl").

fact_test() ->
    ?assertEqual(1, '05_recursion':fact(0)),
    ?assertEqual(3628800, '05_recursion':fact(10)),
    ?assertException(error, function_clause, '05_recursion':fact(-1)).

fib_test() ->
    %% 双累加器版是 O(N)：fib(80) 也能秒算（朴素递归是指数级）
    ?assertEqual(0, '05_recursion':fib(0)),
    ?assertEqual(55, '05_recursion':fib(10)),
    ?assertEqual(23416728348467685, '05_recursion':fib(80)).

tail_vs_nontail_test() ->
    %% 两种写法结果一致；尾递归在深递归下不会涨内存（布尔断言，见示例 1 节）
    ?assertEqual('05_recursion':count_down(5000),
                 '05_recursion':count_down_tail(5000)).

depth_count_test() ->
    ?assertEqual(0, '05_recursion':depth_count([])),
    ?assertEqual(5, '05_recursion':depth_count([a, b, c, d, e])).

is_even_test() ->
    %% 相互递归 + 负数兜底
    ?assertEqual([{0, true}, {1, false}, {2, true}, {3, false}],
                 [{N, '05_recursion':is_even(N)} || N <- [0, 1, 2, 3]]),
    ?assertEqual(false, '05_recursion':is_even(-7)).

rev_map_test() ->
    %% 尾递归 + 最后 reverse：结果与 lists:map 一致且保序
    ?assertEqual([2, 4, 6, 8],
                 '05_recursion':rev_map(fun(X) -> X * 2 end, [1, 2, 3, 4])).

eval_test() ->
    E = fun '05_recursion':eval/1,
    ?assertEqual(12, E({add, {mul, {num, 2}, {num, 3}}, {sub, {num, 10}, {num, 4}}})),
    ?assertEqual(50, E({divi, {num, 100}, {sub, {num, 3}, {num, 1}}})),
    ?assertEqual({error, divide_by_zero}, E({divi, {num, 1}, {num, 0}})).
