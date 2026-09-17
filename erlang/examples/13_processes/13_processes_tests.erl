%% ============================================================
%% 13_processes 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/13_processes examples/13_processes/*_tests.erl
%%   erl -noshell -pa build/13_processes -eval "eunit:test('13_processes_tests'), halt()."
%% ============================================================
-module('13_processes_tests').

-include_lib("eunit/include/eunit.hrl").

pmap_test() ->
    ?assertEqual([1, 4, 9, 16],
                 '13_processes':pmap(fun(X) -> X * X end, [1, 2, 3, 4])),
    ?assertEqual('13_processes':pmap(fun(X) -> X + 1 end, lists:seq(1, 50)),
                 [X + 1 || X <- lists:seq(1, 50)]).

pmap_distinct_processes_test() ->
    %% 每个元素由独立进程处理：pid 去重后个数不变
    Pids = '13_processes':pmap(fun(_) -> self() end, [1, 2, 3]),
    ?assertEqual(3, length(lists:usort(Pids))),
    ?assertNot(lists:member(self(), Pids)).

call_with_ref_test() ->
    _ = logger:remove_handler(default),
    Pid = spawn(fun() -> '13_processes':counter_loop(0) end),
    ?assertEqual(0, '13_processes':call(Pid, get, 2000)),
    ok = '13_processes':call(Pid, {add, 7}, 2000),
    ?assertEqual(7, '13_processes':call(Pid, get, 2000)).

call_unknown_request_times_out_test() ->
    _ = logger:remove_handler(default),
    Pid = spawn(fun() -> '13_processes':counter_loop(0) end),
    %% 协议里没定义的请求：服务不认识 → 调用方超时
    ?assertEqual({error, timeout},
                 '13_processes':call(Pid, {no_such, 1}, 50)),
    %% 服务没被影响
    ?assertEqual(0, '13_processes':call(Pid, get, 2000)).

flush_test() ->
    Ref = make_ref(),
    self() ! {reply, Ref, 1},
    self() ! {reply, Ref, 2},
    self() ! unrelated,
    '13_processes':flush(Ref),
    %% 指定 ref 的都被清掉，别的消息还在
    ?assertEqual(none, receive {reply, Ref, _} -> yes after 0 -> none end),
    ?assertEqual(unrelated, receive unrelated -> unrelated after 0 -> missing end).

isolation_test() ->
    %% 消息是拷贝：子进程构造新列表影响不到父进程
    Self = self(),
    Ref = make_ref(),
    Data = [1, 2, 3],
    spawn(fun() -> Self ! {Ref, [0 | Data]} end),
    receive {Ref, ChildNew} ->
        ?assertEqual([1, 2, 3], Data),
        ?assertEqual([0, 1, 2, 3], ChildNew)
    after 1000 -> erlang:error(timeout)
    end.
