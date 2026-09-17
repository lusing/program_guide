%% ============================================================
%% 14_links 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/14_links examples/14_links/*_tests.erl
%%   erl -noshell -pa build/14_links -eval "eunit:test('14_links_tests'), halt()."
%% ============================================================
-module('14_links_tests').

-include_lib("eunit/include/eunit.hrl").

%% 这些测试全在 trap_exit=false 的默认状态下跑：被 link 的进程崩溃
%% 会把测试进程一起带走，所以只用 monitor / spawn_monitor 形态。

down_shape_test() ->
    _ = logger:remove_handler(default),
    %% error 类崩溃的 DOWN reason 是 {原因, 栈}；exit 类原样
    {_P, Ref} = spawn_monitor(fun() -> erlang:error(boom) end),
    ?assertMatch({'DOWN', Ref, process, _, {boom, [_ | _]}},
                 receive M = {'DOWN', Ref, process, _, _} -> M
                 after 2000 -> timeout end),
    {_P2, Ref2} = spawn_monitor(fun() -> exit(reason_x) end),
    ?assertMatch({'DOWN', Ref2, process, _, reason_x},
                 receive M2 = {'DOWN', Ref2, process, _, _} -> M2
                 after 2000 -> timeout end).

monitor_is_one_way_test() ->
    _ = logger:remove_handler(default),
    %% monitor 单向：目标崩了，我只收消息，自己活着
    {P, Ref} = spawn_monitor(fun() -> exit(kaboom) end),
    receive {'DOWN', Ref, process, P, kaboom} -> ok after 2000 -> timeout end,
    ?assert(is_process_alive(self())).

kill_is_untrappable_test() ->
    _ = logger:remove_handler(default),
    %% trap_exit 的目标能吞掉普通 exit 信号，但吞不掉 kill
    Self = self(),
    Ready = make_ref(),
    T = spawn(fun() ->
                      process_flag(trap_exit, true),
                      Self ! {ready, Ready},
                      receive {'EXIT', _, _} -> exit(handled) end
              end),
    receive {ready, Ready} -> ok after 2000 -> ok end,
    MRef = erlang:monitor(process, T),
    exit(T, kill),
    ?assertMatch({'DOWN', MRef, process, _, killed},
                 receive M = {'DOWN', MRef, process, _, _} -> M
                 after 2000 -> timeout end).

trap_exit_flag_test() ->
    %% process_flag 返回**改动前**的值；改完用 process_info 确认真的还原了
    Old = process_flag(trap_exit, true),
    ?assertEqual(true, process_flag(trap_exit, Old)),   %% 第二次调用返回 true（改前）
    ?assertEqual(Old, element(2, process_info(self(), trap_exit))).

tag_of_test() ->
    %% tag_of 把 {Reason, Stack} 汇总成带 stack_non_empty 的标签
    ?assertMatch({crashed, boom, stack_non_empty, true},
                 '14_links':tag_of({boom, [{m, f, 0, []}]})),
    ?assertEqual(normal, '14_links':tag_of(normal)).
