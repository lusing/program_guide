%% ============================================================
%% 26_sockets —— 套接字编程：TCP/UDP 服务器与流控
%%
%%    Erlang 写网络服务的原生姿态：
%%      · 顺序服务器 —— accept 之后专心陪一个客户端，别的连接排队
%%      · 并行服务器 —— accept 一个 spawn 一个，人人有人陪
%%      · active 三态 —— true（消息推送）/ false（recv 拉取）/ once
%%        （推一条、停一条——每个包之间要主动「再武装」）
%%      · {packet, N} —— 驱动层自动加/剥 N 字节长度前缀，消息边界回来
%%        了；raw 模式则是纯字节流，send 的边界不作数
%%      · 请求-响应协议 —— 载荷用 term_to_binary 编解码（零依赖协议）
%%
%%    确定性纪律：监听用端口 0（系统分配，只打印 >0 布尔）；
%%    所有 recv 都有超时；并发客户端的结果按固定标签排序后打印。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/26_sockets examples/26_sockets/26_sockets.erl
%% 运行：
%%   erl -noshell -pa build/26_sockets -run '26_sockets' main
%% ============================================================
-module('26_sockets').

-export([main/0, start_seq_server/0, start_par_server/0, start_once_server/0,
         start_udp_echo/0, echo_roundtrip/2, free_port/1]).

-define(RECV_TIMEOUT, 3000).     %% 服务器单次 recv 超时
-define(CLIENT_TIMEOUT, 800).    %% 演示用的客户端超时（比服务器超时短）

main() ->
    logger:remove_handler(default),
    listen_and_accept(),
    active_modes(),
    seq_vs_par(),
    udp_echo_demo(),
    raw_stream(),
    io:format("~n==== 26 结束 ====~n").

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

%% 系统分配空闲端口：监听端口 0，再向内核问实际端口号
free_port(Listen) -> {ok, Port} = inet:port(Listen), Port.

%% 起一个监听：binary + packet 2 帧 + 被动模式 + 地址复用
listen() ->
    {ok, Listen} = gen_tcp:listen(0, [binary, {packet, 2}, {active, false},
                                      {reuseaddr, true}]),
    Listen.

%% 供测试复用：顺序 echo 服务器，返回 {监听 socket, 端口}
start_seq_server() ->
    Listen = listen(),
    spawn(fun () -> seq_accept_loop(Listen) end),
    {Listen, free_port(Listen)}.

start_par_server() ->
    Listen = listen(),
    spawn(fun () -> par_accept_loop(Listen) end),
    {Listen, free_port(Listen)}.

start_once_server() ->
    Listen = listen(),
    spawn(fun () -> once_accept_loop(Listen) end),
    {Listen, free_port(Listen)}.

%% 客户端：发一个 term，收 {echo, Term}（一次请求-响应）
echo_roundtrip(Port, Term) ->
    {ok, Sock} = gen_tcp:connect("localhost", Port,
                                 [binary, {packet, 2}, {active, false}]),
    ok = gen_tcp:send(Sock, term_to_binary(Term)),
    Result = case gen_tcp:recv(Sock, 0, ?CLIENT_TIMEOUT * 3) of
                 {ok, Bin} -> binary_to_term(Bin);
                 {error, R} -> {error, R}
             end,
    gen_tcp:close(Sock),
    Result.

%% ------------------------------------------------------------ %%
%% 1) listen / accept：一条连接的诞生
%% ------------------------------------------------------------
listen_and_accept() ->
    io:format("~n== 1) listen / accept：一条连接的诞生 ==~n"),
    {Listen, Port} = start_seq_server(),
    d("端口由系统分配（端口 0），拿到的是正数", is_integer(Port) andalso Port > 0),
    d("请求-响应：发 hello，回 {echo,hello}", echo_roundtrip(Port, hello)),
    d("term 直接当协议载荷（list）", echo_roundtrip(Port, [1, 2, 3])),
    d("中文 term 也没问题", echo_roundtrip(Port, {ok, "中文"})),
    gen_tcp:close(Listen).

%% ------------------------------------------------------------ %%
%% 2) 顺序服务器：一次只陪一个客户端
%% ------------------------------------------------------------
seq_accept_loop(Listen) ->
    case gen_tcp:accept(Listen) of
        {ok, Sock} -> seq_conn_loop(Sock), seq_accept_loop(Listen);
        {error, _} -> ok                       %% 监听关了：服务器体面退出
    end.

seq_conn_loop(Sock) ->
    case gen_tcp:recv(Sock, 0, ?RECV_TIMEOUT) of
        {ok, Bin} ->
            ok = gen_tcp:send(Sock, term_to_binary({echo, binary_to_term(Bin)})),
            seq_conn_loop(Sock);
        {error, _} -> %% closed 或 timeout：这单生意结束
            gen_tcp:close(Sock)
    end.

%% ------------------------------------------------------------ %%
%% 3) active 三态：true / false / once
%% ------------------------------------------------------------
once_accept_loop(Listen) ->
    case gen_tcp:accept(Listen) of
        {ok, Sock} ->
            inet:setopts(Sock, [{active, once}]),  %% 武装一次
            once_conn_loop(Sock),
            once_accept_loop(Listen);
        {error, _} -> ok
    end.

once_conn_loop(Sock) ->
    receive
        {tcp, Sock, Bin} ->
            ok = gen_tcp:send(Sock, term_to_binary({echo, binary_to_term(Bin)})),
            inet:setopts(Sock, [{active, once}]),  %% 每包之后必须再武装
            once_conn_loop(Sock);
        {tcp_closed, Sock} ->
            gen_tcp:close(Sock)
    after ?RECV_TIMEOUT ->
        gen_tcp:close(Sock)
    end.

active_modes() ->
    io:format("~n== 3) active 三态：true / false / once ==~n"),
    %% true：消息主动投递进邮箱（洪流风险由内核背压兜底）
    {Listen1, Port1} = start_once_server(),
    {ok, C1} = gen_tcp:connect("localhost", Port1,
                               [binary, {packet, 2}, {active, once}]),
    ok = gen_tcp:send(C1, term_to_binary(first)),
    receive {tcp, C1, Bin1} -> d("active once：第 1 条作为消息到达",
                                 binary_to_term(Bin1))
    after ?CLIENT_TIMEOUT -> d("active once：第 1 条", timeout) end,
    %% 关键坑：once 只武装一次——不重新 setopts，第 2 条永远躺在驱动里
    ok = gen_tcp:send(C1, term_to_binary(second)),
    receive {tcp, C1, _} -> d("没再武装就收到第 2 条？", impossible)
    after ?CLIENT_TIMEOUT -> d("没再武装：第 2 条收不到（驱动停推）", true) end,
    inet:setopts(C1, [{active, once}]),
    receive {tcp, C1, Bin2} -> d("再武装后第 2 条立刻到达", binary_to_term(Bin2))
    after ?CLIENT_TIMEOUT -> d("再武装后", timeout) end,
    gen_tcp:close(C1),
    gen_tcp:close(Listen1),
    %% false：recv 拉模式（顺序服务器用的就是它）
    {Listen2, Port2} = start_seq_server(),
    d("active false：recv 拉模式（默认 echo 服务器）", echo_roundtrip(Port2, pull)),
    gen_tcp:close(Listen2).

%% ------------------------------------------------------------ %%
%% 4) 顺序 vs 并行：第二个客户端的遭遇
%% ------------------------------------------------------------
par_accept_loop(Listen) ->
    case gen_tcp:accept(Listen) of
        {ok, Sock} ->
            spawn(fun () -> par_accept_loop(Listen) end),  %% 马上回去等下一个
            seq_conn_loop(Sock);                           %% 每连接一个进程
        {error, _} -> ok
    end.

seq_vs_par() ->
    io:format("~n== 4) 顺序 vs 并行：第二个客户端的遭遇 ==~n"),
    %% 顺序服务器：客户端 A 连上但不说话（占住服务器的 recv）
    {ListenS, PortS} = start_seq_server(),
    {ok, Holder} = gen_tcp:connect("localhost", PortS,
                                   [binary, {packet, 2}, {active, false}]),
    %% 客户端 B：connect 成功（内核完成握手排队），但没人 accept 它
    {ok, Waiter} = gen_tcp:connect("localhost", PortS,
                                   [binary, {packet, 2}, {active, false}]),
    ok = gen_tcp:send(Waiter, term_to_binary(me_too)),
    d("顺序服务器：B 发了请求，recv 等到的只有", gen_tcp:recv(Waiter, 0, ?CLIENT_TIMEOUT)),
    gen_tcp:close(Holder), gen_tcp:close(Waiter), gen_tcp:close(ListenS),
    %% 并行服务器：两个客户端都被即时接待
    {ListenP, PortP} = start_par_server(),
    {ok, CA} = gen_tcp:connect("localhost", PortP,
                               [binary, {packet, 2}, {active, false}]),
    {ok, CB} = gen_tcp:connect("localhost", PortP,
                               [binary, {packet, 2}, {active, false}]),
    ok = gen_tcp:send(CA, term_to_binary(a)),
    ok = gen_tcp:send(CB, term_to_binary(b)),
    {ok, RA} = gen_tcp:recv(CA, 0, ?CLIENT_TIMEOUT * 3),
    {ok, RB} = gen_tcp:recv(CB, 0, ?CLIENT_TIMEOUT * 3),
    %% 结果按固定标签排序打印（谁先到不承诺）
    d("并行服务器：两位都拿到回音", lists:sort([binary_to_term(RA), binary_to_term(RB)])),
    gen_tcp:close(CA), gen_tcp:close(CB), gen_tcp:close(ListenP).

%% ------------------------------------------------------------ %%
%% 5) UDP：无连接的数据报
%% ------------------------------------------------------------
start_udp_echo() ->
    {ok, Socket} = gen_udp:open(0, [binary, {active, false}]),
    {ok, Port} = inet:port(Socket),
    spawn(fun () -> udp_loop(Socket) end),
    {Socket, Port}.

udp_loop(Socket) ->
    %% OTP 29 实测：recv 返回扁平的 {ok, {对端地址, 对端端口, 数据}}——
    %% （老书写法 {ok, {地址, 端口}, 数据} 直接 badmatch！）回信用 send/4
    case gen_udp:recv(Socket, 0, ?RECV_TIMEOUT * 2) of
        {ok, {Addr, FromPort, Data}} ->
            gen_udp:send(Socket, Addr, FromPort, Data),
            udp_loop(Socket);
        {error, _} -> ok
    end.

udp_echo_demo() ->
    io:format("~n== 5) UDP：无连接的数据报 ==~n"),
    {Socket, Port} = start_udp_echo(),
    {ok, Client} = gen_udp:open(0, [binary, {active, false}]),
    ok = gen_udp:send(Client, {127,0,0,1}, Port, <<"datagram">>),
    {ok, {_, _, <<"datagram">>}} = gen_udp:recv(Client, 0, ?CLIENT_TIMEOUT * 3),
    d("UDP 一去一回", ok),
    %% UDP 没有连接语义：send 目标写地址，掉包/乱序是应用层的事
    ok = gen_udp:send(Client, {127,0,0,1}, Port, term_to_binary({udp, "也行"})),
    {ok, {_, _, Bin}} = gen_udp:recv(Client, 0, ?CLIENT_TIMEOUT * 3),
    d("载荷一样可以是 term", binary_to_term(Bin)),
    gen_udp:close(Client),
    gen_udp:close(Socket).

%% ------------------------------------------------------------ %%
%% 6) raw 字节流：send 的边界不作数
%% ------------------------------------------------------------
raw_stream() ->
    io:format("~n== 6) raw 字节流：send 的边界不作数 ==~n"),
    %% 服务器用 raw 模式：recv(Sock, N) 凑满 N 字节才返回
    {ok, Listen} = gen_tcp:listen(0, [binary, {packet, raw}, {active, false},
                                      {reuseaddr, true}]),
    {ok, Port} = inet:port(Listen),
    spawn(fun () ->
                  {ok, Sock} = gen_tcp:accept(Listen),
                  {ok, Ten} = gen_tcp:recv(Sock, 10, ?RECV_TIMEOUT),
                  %% 原样回去：用 2 字节长度前缀手工成帧（packet 2 的手写版）
                  ok = gen_tcp:send(Sock, [<<(byte_size(Ten)):16>>, Ten]),
                  gen_tcp:close(Sock)
          end),
    {ok, Client} = gen_tcp:connect("localhost", Port,
                                   [binary, {packet, raw}, {active, false}]),
    %% 两次 send，对端一次 recv 凑满——TCP 里没有「消息」只有字节流
    ok = gen_tcp:send(Client, <<"aaaa">>),
    ok = gen_tcp:send(Client, <<"bbbbbb">>),
    {ok, <<10:16, Bytes/binary>>} = gen_tcp:recv(Client, 12, ?CLIENT_TIMEOUT * 3),
    d("两次 send 的 4+6 字节，对端一次收成", binary_to_list(Bytes)),
    io:format("  （两次 send 的边界在字节流里消失了——这就是要 packet 帧的原因）~n"),
    gen_tcp:close(Client),
    gen_tcp:close(Listen).
