%% ============================================================
%% 16_supervisor 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/16_supervisor examples/16_supervisor/*_tests.erl
%%   erl -noshell -pa build/16_supervisor -eval "eunit:test('16_supervisor_tests'), halt()."
%%
%% supervisor 的行为只能靠「观察消息」验证（child_up 通知），与示例同法。
%% ============================================================
-module('16_supervisor_tests').

-include_lib("eunit/include/eunit.hrl").

wait_up() -> receive {child_up, T} -> T after 2000 -> timeout end.

stop_sup(Sup) ->
    MRef = erlang:monitor(process, Sup),
    exit(Sup, shutdown),
    receive {'DOWN', MRef, process, _, _} -> ok after 2000 -> ok end.

one_for_one_test() ->
    _ = logger:remove_handler(default),
    Old = process_flag(trap_exit, true),
    {ok, Sup} = supervisor:start_link('16_supervisor',
                                       {one_for_one, 5, 1, [a, b, c], self()}),
    [a, b, c] = [wait_up() || _ <- [a, b, c]],
    %% 杀 c：one_for_one 只重启 c
    {c, Pid, _, _} = lists:keyfind(c, 1, supervisor:which_children(Sup)),
    exit(Pid, kill),
    ?assertEqual(c, wait_up()),
    ?assertEqual([], drain()),
    stop_sup(Sup),
    _ = process_flag(trap_exit, Old).

one_for_all_test() ->
    _ = logger:remove_handler(default),
    Old = process_flag(trap_exit, true),
    {ok, Sup} = supervisor:start_link('16_supervisor',
                                       {one_for_all, 5, 1, [a, b, c], self()}),
    _ = [wait_up() || _ <- [a, b, c]],
    {c, Pid, _, _} = lists:keyfind(c, 1, supervisor:which_children(Sup)),
    exit(Pid, kill),
    %% 三个全部重启（顺序不定，sort 后比较）
    ?assertEqual([a, b, c], lists:sort([wait_up() || _ <- [a, b, c]])),
    stop_sup(Sup),
    _ = process_flag(trap_exit, Old).

intensity_gives_up_test() ->
    _ = logger:remove_handler(default),
    Old = process_flag(trap_exit, true),
    %% intensity=2 / period=1：1 秒内最多重启 2 次，第 3 次放弃整棵树
    {ok, Sup} = supervisor:start_link('16_supervisor',
                                       {one_for_one, 2, 1, [a], self()}),
    _ = wait_up(),
    MRef = erlang:monitor(process, Sup),
    [begin
         {a, P, _, _} = lists:keyfind(a, 1, supervisor:which_children(Sup)),
         exit(P, kill),
         ?assertEqual(a, wait_up())
     end || _ <- [1, 2]],
    {a, P3, _, _} = lists:keyfind(a, 1, supervisor:which_children(Sup)),
    exit(P3, kill),
    ?assertMatch({'DOWN', MRef, process, _, shutdown},
                 receive M = {'DOWN', MRef, process, _, _} -> M
                 after 3000 -> no_down end),
    _ = process_flag(trap_exit, Old).

dynamic_children_test() ->
    _ = logger:remove_handler(default),
    Old = process_flag(trap_exit, true),
    {ok, Sup} = supervisor:start_link('16_supervisor',
                                       {one_for_one, 5, 1, [a], self()}),
    _ = wait_up(),
    ?assertEqual([{specs, 1}, {workers, 1}],
                 lists:sort(lists:filter(fun({specs, _}) -> true;
                                            ({workers, _}) -> true;
                                            (_) -> false
                                         end, supervisor:count_children(Sup)))),
    %% 动态加孩子 → terminate → delete 三步
    Spec = #{id => extra, start => {'16_supervisor', worker_start, [{extra, self()}]},
             restart => permanent, shutdown => 5000, type => worker,
             modules => ['16_supervisor']},
    {ok, _} = supervisor:start_child(Sup, Spec),
    ?assertEqual(extra, wait_up()),
    ?assertEqual(ok, supervisor:terminate_child(Sup, extra)),
    ?assertEqual(ok, supervisor:delete_child(Sup, extra)),
    %% 重复删除被拒绝
    ?assertMatch({error, _}, supervisor:delete_child(Sup, extra)),
    stop_sup(Sup),
    _ = process_flag(trap_exit, Old).

drain() ->
    receive {child_up, T} -> [T | drain()] after 150 -> [] end.
