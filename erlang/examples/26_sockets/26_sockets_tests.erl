%% ============================================================
%% 26_sockets 的 EUnit 测试
%%
%%   每个测试自起监听（端口 0 由系统分配），互不抢端口；
%%   所有 recv 都带超时，测试进程不会被挂死的连接拖住。
%%
%%   erlc -Werror -Wall -o build/26_sockets examples/26_sockets/*_tests.erl
%%   erl -noshell -pa build/26_sockets -eval "eunit:test('26_sockets_tests'), halt()."
%% ============================================================
-module('26_sockets_tests').

-include_lib("eunit/include/eunit.hrl").

echo_roundtrip_test() ->
    {Listen, Port} = '26_sockets':start_seq_server(),
    try
        ?assertEqual({echo, hello}, '26_sockets':echo_roundtrip(Port, hello)),
        ?assertEqual({echo, [1, 2, 3]}, '26_sockets':echo_roundtrip(Port, [1, 2, 3])),
        ?assertEqual({echo, {ok, "中文"}},
                     '26_sockets':echo_roundtrip(Port, {ok, "中文"}))
    after
        gen_tcp:close(Listen)
    end.

%% active once 每次交付后必须再武装——漏了 setopts 第二条永远到不了
active_once_rearm_test() ->
    {Listen, Port} = '26_sockets':start_once_server(),
    try
        {ok, Sock} = gen_tcp:connect("localhost", Port,
                                     [binary, {packet, 2}, {active, once}]),
        ok = gen_tcp:send(Sock, term_to_binary(first)),
        receive {tcp, Sock, B1} -> ?assertEqual({echo, first}, binary_to_term(B1))
        after 1000 -> error(first_missing)
        end,
        ok = gen_tcp:send(Sock, term_to_binary(second)),
        receive {tcp, Sock, _} -> error(should_not_deliver_without_rearm)
        after 200 -> ok          %% 没再武装：收不到是预期
        end,
        inet:setopts(Sock, [{active, once}]),
        receive {tcp, Sock, B2} -> ?assertEqual({echo, second}, binary_to_term(B2))
        after 1000 -> error(second_missing)
        end,
        gen_tcp:close(Sock)
    after
        gen_tcp:close(Listen)
    end.

%% 顺序服务器忙于第一个客户端：第二个客户端 recv 只有超时
sequential_blocks_second_test() ->
    {Listen, Port} = '26_sockets':start_seq_server(),
    try
        {ok, Holder} = gen_tcp:connect("localhost", Port,
                                       [binary, {packet, 2}, {active, false}]),
        {ok, Waiter} = gen_tcp:connect("localhost", Port,
                                       [binary, {packet, 2}, {active, false}]),
        ok = gen_tcp:send(Waiter, term_to_binary(me_too)),
        ?assertEqual({error, timeout}, gen_tcp:recv(Waiter, 0, 400)),
        gen_tcp:close(Holder),
        gen_tcp:close(Waiter)
    after
        gen_tcp:close(Listen)
    end.

%% 并行服务器：accept 一个 spawn 一个，两个客户端都被即时接待
parallel_serves_both_test() ->
    {Listen, Port} = '26_sockets':start_par_server(),
    try
        {ok, CA} = gen_tcp:connect("localhost", Port,
                                   [binary, {packet, 2}, {active, false}]),
        {ok, CB} = gen_tcp:connect("localhost", Port,
                                   [binary, {packet, 2}, {active, false}]),
        ok = gen_tcp:send(CA, term_to_binary(a)),
        ok = gen_tcp:send(CB, term_to_binary(b)),
        {ok, RA} = gen_tcp:recv(CA, 0, 2400),
        {ok, RB} = gen_tcp:recv(CB, 0, 2400),
        ?assertEqual([{echo, a}, {echo, b}],
                     lists:sort([binary_to_term(RA), binary_to_term(RB)])),
        gen_tcp:close(CA),
        gen_tcp:close(CB)
    after
        gen_tcp:close(Listen)
    end.

udp_echo_test() ->
    {Socket, Port} = '26_sockets':start_udp_echo(),
    try
        {ok, Client} = gen_udp:open(0, [binary, {active, false}]),
        ok = gen_udp:send(Client, {127, 0, 0, 1}, Port, <<"ping">>),
        %% OTP 29 实测：recv 返回扁平 {ok, {Addr, Port, Packet}}
        {ok, {{127, 0, 0, 1}, _, <<"ping">>}} = gen_udp:recv(Client, 0, 2400),
        ok,
        gen_udp:close(Client)
    after
        gen_udp:close(Socket)
    end.
