%% ============================================================
%% 31_multicore 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/31_multicore examples/31_multicore/*_tests.erl
%%   erl -noshell -pa build/31_multicore -eval "eunit:test('31_multicore_tests'), halt()."
%% ============================================================
-module('31_multicore_tests').

-include_lib("eunit/include/eunit.hrl").

pmap_ordered_test() ->
    Input = [18, 14, 17, 15, 16],
    ?assertEqual(['31_multicore':fib(X) || X <- Input],
                 '31_multicore':pmap_ordered(fun '31_multicore':fib/1, Input)).

pmap_unordered_test() ->
    Input = [15, 17, 14],
    Got = '31_multicore':pmap_unordered(fun '31_multicore':fib/1, Input),
    %% 完成顺序随机：只能断言排序后的等价
    ?assertEqual(lists:sort(['31_multicore':fib(X) || X <- Input]), lists:sort(Got)).

%% 卡死元素被放弃、其余照常完成；孤儿消息被 drain 清干净
pmmap_timeout_test() ->
    Job = fun (3) -> receive after 60_000 -> never end;
              (_X) -> quick
          end,
    ?assertEqual([1, 2, 4], '31_multicore':pmmap(Job, 300, [1, 2, 3, 4])),
    %% drain 之后邮箱是干净的：下一条 receive 立即超时
    receive {pm, _} -> error(orphan_left_behind) after 0 -> ok end.

pmmap_all_done_test() ->
    %% 都不卡：全量返回
    Job = fun (_X) -> quick end,
    ?assertEqual([1, 2, 3], '31_multicore':pmmap(Job, 2000, [1, 2, 3])).

future_test() ->
    F1 = '31_multicore':future(fun () -> '31_multicore':fib(20) end),
    F2 = '31_multicore':future(fun () -> lists:sum(lists:seq(1, 1000)) end),
    ?assertEqual(6765, '31_multicore':yield(F1)),
    ?assertEqual(500500, '31_multicore':yield(F2)).

fib_value_test() ->
    ?assertEqual(2584, '31_multicore':fib(18)).
