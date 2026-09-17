%% ============================================================
%% 15_gen_server 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/15_gen_server examples/15_gen_server/*_tests.erl
%%   erl -noshell -pa build/15_gen_server -eval "eunit:test('15_gen_server_tests'), halt()."
%%
%% gen_server 是注册名单例（?SERVER = ?MODULE），测试串行跑（EUnit 默认），
%% 每个用例自己 start/stop，避免名字冲突。
%% EUnit 每个测试在**新进程**里跑，trap_exit 开着不还原也没关系——
%% 但必须开着：start_link 互相 link，服务崩溃会带走没开 trap_exit 的测试进程
%%（15 章 5 节的实测结论在测试里同样成立）。
%% ============================================================
-module('15_gen_server_tests').

-include_lib("eunit/include/eunit.hrl").

start(Tag) ->
    _ = logger:remove_handler(default),
    _ = process_flag(trap_exit, true),
    {ok, Pid} = '15_gen_server':start_link(Tag),
    Pid.

stop_and_drain() ->
    _ = '15_gen_server':stop(),
    receive {terminating, _, _} -> ok after 2000 -> ok end.

call_basics_test() ->
    _ = start(t_call),
    ?assertEqual(ok, '15_gen_server':put(a, 1, alice)),
    ?assertEqual(ok, '15_gen_server':put(b, 2, bob)),
    ?assertEqual(2, '15_gen_server':count()),
    ?assertEqual(1, '15_gen_server':fetch(a)),
    ?assertEqual(undefined, '15_gen_server':fetch(zzz)),
    ?assertEqual({2, bob}, '15_gen_server':snapshot()),
    stop_and_drain().

unknown_request_test() ->
    _ = start(t_unknown),
    %% 协议外的请求被 handle_call 的兜底子句接住
    ?assertEqual({error, {unknown_request, {weird, 1}}},
                 gen_server:call('15_gen_server', {weird, 1})),
    stop_and_drain().

state_belongs_to_process_test() ->
    _ = start(t_state),
    ok = '15_gen_server':put(x, 100, tester),
    %% 直接调回调传假状态 → 拿到的是假状态里的值，不是服务进程的真实状态
    FakeState = #{notify => self(), tag => fake, data => #{}},
    {reply, Direct, _} = '15_gen_server':handle_call({get, x}, {self(), make_ref()}, FakeState),
    ?assertEqual(undefined, Direct),
    ?assertEqual(100, '15_gen_server':fetch(x)),
    stop_and_drain().

callback_crash_test() ->
    Pid = start(t_crash),
    ?assertMatch({exit, _},
                 try gen_server:call('15_gen_server', boom)
                 catch exit:R -> {exit, R} end),
    %% 进程死了、名字自动释放
    ?assertNot(is_process_alive(Pid)),
    ?assertEqual(undefined, whereis('15_gen_server')),
    %% terminate 通知带原因
    ?assertMatch({terminating, t_crash, _},
                 receive M = {terminating, t_crash, _} -> M after 2000 -> timeout end).

graceful_stop_test() ->
    _ = start(t_stop),
    ?assertEqual(stopped, gen_server:call('15_gen_server', {countdown, 0})),
    ?assertMatch({terminating, t_stop, normal},
                 receive M = {terminating, t_stop, _} -> M after 2000 -> timeout end).
