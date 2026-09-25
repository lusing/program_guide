%% ============================================================
%% 30_profiling 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/30_profiling examples/30_profiling/*_tests.erl
%%   erl -noshell -pa build/30_profiling -eval "eunit:test('30_profiling_tests'), halt()."
%% ============================================================
-module('30_profiling_tests').

-include_lib("eunit/include/eunit.hrl").

fib_values_test() ->
    ?assertEqual(2584, '30_profiling':fib(18)),
    %% 调用次数闭式自检：calls(10) = 177
    ?assertEqual(177, '30_profiling':fib_calls(10)).

timer_tc_property_test() ->
    {Micros, 2584} = timer:tc('30_profiling', fib, [18]),
    ?assert(is_integer(Micros)),
    ?assert(Micros >= 0).   %% Windows 上偶发量出 0 微秒——下限断言

cprof_counts_test() ->
    cprof:start(),
    ok = '30_profiling':workload(),
    cprof:pause(),
    {'30_profiling', _Own, FAs} = cprof:analyse('30_profiling'),
    Measured = proplists:get_value({'30_profiling', fib, 1}, FAs, 0),
    ?assertEqual('30_profiling':fib_calls(18), Measured),
    cprof:stop(),
    %% stop 后归零/清空：观察者效应要收摊
    ?assertEqual({'30_profiling', 0, []}, cprof:analyse('30_profiling')).

trace_test() ->
    Counts = '30_profiling':trace_calls(fun () -> '30_profiling':fib(10) end),
    ?assertEqual([{{'30_profiling', fib, 1}, 177}],
                 [P || {{M, F, 1}, _} = P <- Counts,
                       M =:= '30_profiling', F =:= fib]),
    %% trace 已关：裸调一次不会出现在任何计数里（这里只验证不再炸）
    ?assertEqual(5, '30_profiling':fib(5)).
