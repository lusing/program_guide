%% ============================================================
%% 25_distributed 的 EUnit 测试
%%
%%   ⚠ peer 依赖测试节点本身是分布式节点——build.ps1 起 eunit 时
%%     会带 -sname ex25_a；手工跑同理：
%%     erl -noshell -sname ex25_a -pa build/25_distributed
%%         -eval "eunit:test('25_distributed_tests'), halt()."
%%
%%   erlc -Werror -Wall -o build/25_distributed examples/25_distributed/*_tests.erl
%% ============================================================
-module('25_distributed_tests').

-include_lib("eunit/include/eunit.hrl").

start_peer(Name) ->
    {ok, Peer, Node} = peer:start(#{name => Name}),
    {Peer, Node}.

start_tcp_peer(Name) ->
    {ok, Peer, Node} = peer:start(#{name => Name, connection => 0,
                                    args => ["-eval", "logger:remove_handler(default)"]}),
    {Peer, Node}.

strip_host_test() ->
    ?assertEqual(ex25_a, '25_distributed':strip_host('ex25_a@somehost')),
    ?assertEqual(nonode@nohost, '25_distributed':strip_host(nonode@nohost)).

rpc_roundtrip_test() ->
    {Peer, Node} = start_peer(ex25_peer_t1),
    try
        ?assert(is_alive()),
        ?assertEqual(42, rpc:call(Node, erlang, '+', [19, 23])),
        %% 对端跑自己的模块：先共享 beam 目录
        BeamDir = filename:dirname(code:which('25_distributed')),
        true = rpc:call(Node, code, add_patha, [BeamDir]),
        ?assertEqual(3, rpc:call(Node, '25_distributed', add, [1, 2])),
        %% 失败形状：对端 undef / 节点不存在
        ?assertMatch({badrpc, {'EXIT', {undef, _}}},
                     rpc:call(Node, '25_no_such_module', no_fun, [])),
        Nobody = list_to_atom("ex25_nobody_t@" ++ net_adm:localhost()),
        ?assertEqual({badrpc, nodedown},
                     rpc:call(Nobody, erlang, node, [], 1000))
    after
        peer:stop(Peer)
    end.

remote_spawn_and_global_test() ->
    {Peer, Node} = start_peer(ex25_peer_t2),
    try
        ok = '25_distributed':share_code(Node),
        Pid = spawn(Node, '25_distributed', loop, []),
        %% global:register_name 成功返回 yes（不是 true——易错点）
        ?assertEqual(yes, rpc:call(Node, global, register_name, [ex25_echo_t, Pid])),
        ok = global:sync(),
        ?assert(is_pid(global:whereis_name(ex25_echo_t))),
        global:send(ex25_echo_t, {ping, self()}),
        receive {pong, Node} -> ok
        after 3000 -> error(pong_missing)
        end,
        Pid ! stop
    after
        peer:stop(Peer)
    end.

cookie_test() ->
    %% 真实的失配握手会产生 ERTS 层 ERROR REPORT（带时间戳、不走
    %% logger、摘 handler 拦不住）——确定性测试同样要避开，见正文第 6 节
    {Peer, Node} = start_tcp_peer(ex25_peer_t3),
    try
        true = erlang:set_cookie(Node, erlang:get_cookie()),
        ?assertEqual(pong, net_adm:ping(Node)),
        Ghost = list_to_atom("ex25_ghost_t@" ++ net_adm:localhost()),
        ?assertEqual(pang, net_adm:ping(Ghost))
    after
        peer:stop(Peer)
    end.

disconnect_test() ->
    %% 断开/重连只对 TCP 控制 peer 可演示——
    %% 默认 peer 的分布式连接就是控制通道，disconnect 会杀死节点
    {Peer, Node} = start_tcp_peer(ex25_peer_t4),
    try
        ?assertEqual(pong, net_adm:ping(Node)),
        ?assertEqual(true, net_kernel:disconnect(Node)),
        ?assertEqual([], nodes()),
        ?assertEqual(pong, net_adm:ping(Node))
    after
        peer:stop(Peer)
    end.
