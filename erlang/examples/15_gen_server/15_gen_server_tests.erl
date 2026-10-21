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

%% 15.4：send_request 把 call 拆成「发」和「收」两步（OTP 23）
send_request_test() ->
    _ = start(t_sr),
    ok = '15_gen_server':put(a, 1, alice),
    ReqId = gen_server:send_request('15_gen_server', {get, a}),
    ?assert(is_reference(ReqId)),
    ?assertEqual({reply, 1}, gen_server:wait_response(ReqId, 1000)),
    R2 = gen_server:send_request('15_gen_server', count),
    ?assertEqual({reply, 1}, gen_server:receive_response(R2, 1000)),
    stop_and_drain().

%% 15.4：wait_response 超时不抛异常、返回原子 timeout；响应之后还能取到
wait_response_timeout_test() ->
    _ = start(t_slow),
    R = gen_server:send_request('15_gen_server', {slow, 200, slow_done}),
    ?assertEqual(timeout, gen_server:wait_response(R, 50)),
    ?assertEqual({reply, slow_done}, gen_server:wait_response(R, 1000)),
    stop_and_drain().

%% 15.4：check_response(Msg, ReqId) 不等待，检查已收到的消息是不是响应
check_response_test() ->
    _ = start(t_check),
    R = gen_server:send_request('15_gen_server', {echo, checkme}),
    %% 响应消息的真实形状是 {[alias|ReqId], Reply}（OTP 24+ 的 alias 形状）
    Checked = receive M = {[alias|R], _} -> gen_server:check_response(M, R)
              after 2000 -> no_message end,
    ?assertEqual({reply, {echoed, checkme}}, Checked),
    ?assertEqual(no_reply, gen_server:check_response(some_other_msg, R)),
    stop_and_drain().

%% 15.4：reqids collection 一把发、按标签收（OTP 25），收取必须用 /3
reqids_collection_test() ->
    _ = start(t_coll),
    C0 = gen_server:reqids_new(),
    C1 = gen_server:send_request('15_gen_server', {echo, 1}, first, C0),
    C2 = gen_server:send_request('15_gen_server', {echo, 2}, second, C1),
    ?assertEqual(2, gen_server:reqids_size(C2)),
    {Res1, Lab1, C3} = gen_server:wait_response(C2, 1000, true),
    ?assertEqual({reply, {echoed, 1}}, Res1),
    ?assertEqual(first, Lab1),
    ?assertEqual(1, gen_server:reqids_size(C3)),
    {Res2, Lab2, C4} = gen_server:receive_response(C3, 1000, true),
    ?assertEqual({reply, {echoed, 2}}, Res2),
    ?assertEqual(second, Lab2),
    ?assertEqual(0, gen_server:reqids_size(C4)),
    %% 对 collection 误用 /2 形式只会等到 timeout（响应本身不丢）
    Cx = gen_server:send_request('15_gen_server', {echo, 9}, third, gen_server:reqids_new()),
    ?assertEqual(timeout, gen_server:wait_response(Cx, 100)),
    ?assertMatch({{reply, {echoed, 9}}, third, _},
                 gen_server:receive_response(Cx, 1000, true)),
    stop_and_drain().

%% 15.4：新式超时 action {timeout, Time, Msg}（OTP 25）——
%% init 返回 {ok, State, {timeout, 30, tick}} 后，handle_info 收到的就是 tick 原样
timeout_action_test() ->
    _ = logger:remove_handler(default),
    _ = process_flag(trap_exit, true),
    {ok, _Pid} = gen_server:start_link({local, '15_gen_server'}, '15_gen_server',
                                       #{notify => self(), tag => t_timeout,
                                         timeout_after => 30}, []),
    ?assertEqual({timeout_tick, t_timeout},
                 receive M = {timeout_tick, t_timeout} -> M after 2000 -> timeout end),
    stop_and_drain().
