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

%% auto_shutdown 演示用的 child spec（与 '16_supervisor':auto_spec/2 同形）：
%% temporary + significant 标记
auto_spec(Id, Significant) ->
    #{id => Id,
      start => {'16_supervisor', worker_start, [{Id, self()}]},
      restart => temporary, significant => Significant,
      shutdown => 1000, type => worker, modules => ['16_supervisor']}.

%% 16.5：auto_shutdown => any_significant —— 主角正常退出，整棵树自动关闭
auto_shutdown_test() ->
    _ = logger:remove_handler(default),
    Old = process_flag(trap_exit, true),
    Flags = #{strategy => one_for_one, auto_shutdown => any_significant},
    Children = [auto_spec(main_task, true), auto_spec(helper, false)],
    {ok, Sup} = supervisor:start_link('16_auto_shutdown_sup', {Flags, Children}),
    {main_task, Main, _, _} = lists:keyfind(main_task, 1, supervisor:which_children(Sup)),
    Main ! stop,
    %% supervisor 自动终止，链接方收到 {'EXIT', Sup, shutdown}
    ?assertMatch({'EXIT', Sup, shutdown},
                 receive M = {'EXIT', Sup, _} -> M after 2000 -> no_exit end),
    timer:sleep(100),
    ?assertNot(is_process_alive(Sup)),
    _ = process_flag(trap_exit, Old).

%% 16.5：陪跑（significant => false）正常退出不触发自动关闭
non_significant_exit_keeps_sup_test() ->
    _ = logger:remove_handler(default),
    Old = process_flag(trap_exit, true),
    Flags = #{strategy => one_for_one, auto_shutdown => any_significant},
    {ok, Sup} = supervisor:start_link('16_auto_shutdown_sup',
                                      {Flags, [auto_spec(helper, false)]}),
    {helper, H, _, _} = lists:keyfind(helper, 1, supervisor:which_children(Sup)),
    H ! stop,
    timer:sleep(300),
    ?assert(is_process_alive(Sup)),
    ?assertEqual(none, receive {'EXIT', Sup, _} -> got_exit after 0 -> none end),
    stop_sup(Sup),
    _ = process_flag(trap_exit, Old).

%% 16.5 / 16.7：auto_shutdown => never（默认）时 significant => true 被直接拒绝
significant_rejected_without_auto_shutdown_test() ->
    _ = logger:remove_handler(default),
    %% start_link 失败时，没起成的 supervisor 进程退出信号会顺着 link 传过来，
    %% 测试进程必须 trap_exit，否则会被一起带走
    Old = process_flag(trap_exit, true),
    ?assertEqual({error, {start_spec, {bad_combination, [{auto_shutdown, never},
                                                         {significant, true}]}}},
                 supervisor:start_link('16_auto_shutdown_sup',
                                       {#{strategy => one_for_one},
                                        [auto_spec(bad, true)]})),
    %% 清掉那条启动失败的 EXIT 残信
    receive {'EXIT', _, {start_spec, _}} -> ok after 0 -> ok end,
    _ = process_flag(trap_exit, Old).

%% 16.5：hibernate_after sup flag（OTP 28）被接受，空闲后进入休眠
hibernate_after_flag_test() ->
    _ = logger:remove_handler(default),
    Old = process_flag(trap_exit, true),
    {ok, Sup} = supervisor:start_link('16_auto_shutdown_sup',
                                      {#{strategy => one_for_one, hibernate_after => 100},
                                       [auto_spec(w, false)]}),
    ?assert(is_process_alive(Sup)),
    timer:sleep(300),
    ?assertEqual({gen_server, loop_hibernate, 4},
                 element(2, process_info(Sup, current_function))),
    stop_sup(Sup),
    _ = process_flag(trap_exit, Old).
