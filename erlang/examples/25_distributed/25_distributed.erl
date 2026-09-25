%% ============================================================
%% 25_distributed —— 分布式 Erlang：节点、rpc 与 global
%%
%%    「进程之间 send 永远长一样」——不管那个进程住在哪台机器上。
%%    分布式 Erlang 把这句话做成了语言的一部分：
%%      · 节点   —— 起一个带名字的 VM（erl -sname ex25_a）
%%      · peer   —— OTP 25+ 的脚本化起节点方式（老书的命令行手工做法
%%                  升级成一个函数调用；这是本教程按 OTP 29 写的地方）
%%      · rpc    —— 在对端节点上调用任意模块函数
%%      · spawn(Node, M, F, A) —— 在对端节点上起进程，位置透明
%%      · global —— 集群级别的注册名（register 只在本节点）
%%      · cookie —— 两个节点握手时的口令
%%
%%    ⚠ 本示例必须以分布式节点启动（build.ps1 自动加 -sname ex25_a）：
%%      erl -noshell -sname ex25_a -pa build/25_distributed -run '25_distributed' main
%%
%%    两种 peer 的用法（实测出的分野）：
%%      · peer:start(#{name => X})            —— 节点启动即自动与父节点建立
%%        分布式连接；但父侧断开连接会把 peer 节点连带杀死（peer 生命周期
%%        绑在分布式连接上）
%%      · peer:start(#{name => X, connection => 0}) —— 控制通道走 TCP，分布
%%        式连接不自动建立：cookie 演示（先 pang 后 pong）与断开重连都可控
%%
%%    确定性纪律：输出里不打印 pid、不打印带主机名的完整节点名
%%    （strip_host 只留 @ 前的短名）——主机名因机器而异。
%% ============================================================
-module('25_distributed').

-export([main/0, strip_host/1, share_code/1, loop/0, add/2,
         start_peer/1, start_tcp_peer/1]).

main() ->
    logger:remove_handler(default),
    node() =/= nonode@nohost orelse halt(2),   %% 手跑忘了 -sname：立即失败
    {Peer1, Node1} = start_peer(ex25_peer1),
    section_node(),
    section_peer(Node1),
    section_rpc(Node1),
    section_spawn(Node1),
    section_global(Node1),
    {Peer2, Node2} = start_tcp_peer(ex25_peer2),
    section_cookie(Node2),
    section_topology(Node2),
    section_stop(Peer1, Peer2),
    io:format("~n==== 25 结束 ====~n").

%% 自动连接的 peer：节点起来就跟父节点握手（用同一份 ~~/.erlang.cookie）
start_peer(Name) ->
    {ok, Peer, Node} = peer:start(#{name => Name,
                                    args => ["-eval", "logger:remove_handler(default)"]}),
    {Peer, Node}.

%% TCP 控制的 peer：分布式连接不自动建立——cookie/断开重连要可控时用它
start_tcp_peer(Name) ->
    %% peer 的控制通道会把它的 stdout 转发回父节点——握手被拒的
    %% ERROR REPORT 带时间戳，必须让 peer 自己静音
    {ok, Peer, Node} = peer:start(#{name => Name, connection => 0,
                                    args => ["-eval", "logger:remove_handler(default)"]}),
    {Peer, Node}.

%% 把本模块的 beam 所在目录挂到对端节点的代码路径——
%% 「在对端跑我们的代码」的前提是对端 load 得到模块
share_code(Node) ->
    BeamDir = filename:dirname(code:which(?MODULE)),
    true = rpc:call(Node, code, add_patha, [BeamDir]),
    ok.

%% 给对端 spawn 用的循环体：收到 {ping, 客户端} 就回 {pong, 自己的节点名}
loop() ->
    receive
        {ping, Client} -> Client ! {pong, node()}, loop();
        stop -> ok
    end.

add(A, B) -> A + B.

%% 节点短名：'ex25_a@somehost' -> ex25_a（输出纪律：不打印主机名）
strip_host(nonode@nohost) -> nonode@nohost;   %% 「不是分布式节点」的哨兵，原样返回
strip_host(Node) when is_atom(Node) ->
    case string:split(atom_to_list(Node), "@") of
        [Short | _] -> list_to_atom(Short);
        _ -> Node
    end.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

%% ------------------------------------------------------------ %%
%% 1) 节点：给 VM 一个名字
%% ------------------------------------------------------------
section_node() ->
    io:format("~n== 1) 节点：给 VM 一个名字 ==~n"),
    d("node()（短名，主机名不打印）", strip_host(node())),
    d("is_alive()（没带 -sname 时是 false）", is_alive()),
    d("不带名字启动时 node() 是（哨兵）", strip_host(nonode@nohost)),
    io:format("  （-sname 短名=<主机名>，-name 长名=<FQDN>；口令见第 6 节）~n").

%% ------------------------------------------------------------ %%
%% 2) peer：一个函数起一个节点
%% ------------------------------------------------------------
section_peer(Node1) ->
    io:format("~n== 2) peer：一个函数起一个节点 ==~n"),
    d("对端节点", strip_host(Node1)),
    d("对端 is_alive()", rpc:call(Node1, erlang, is_alive, [])),
    d("nodes()（已连的对端，排序后只显示短名）",
      [strip_host(N) || N <- lists:sort(nodes())]).

%% ------------------------------------------------------------ %%
%% 3) rpc：在对端节点上调用函数
%% ------------------------------------------------------------
section_rpc(Node1) ->
    io:format("~n== 3) rpc：在对端节点上调用函数 ==~n"),
    d("rpc:call(对端, erlang, '+', [19,23])", rpc:call(Node1, erlang, '+', [19, 23])),
    %% 对端跑**我们自己的模块**——先把 beam 目录挂上对端代码路径
    ok = share_code(Node1),
    d("rpc:call(对端, ?MODULE, add, [1,2])", rpc:call(Node1, ?MODULE, add, [1, 2])),
    d("rpc:call 带超时（毫秒，第 5 个参数）",
      rpc:call(Node1, ?MODULE, add, [20, 22], 5000)),
    %% 失败形状一：对端没有那个函数 → badrpc 包着 EXIT
    {badrpc, {'EXIT', {undef, _}}} =
        rpc:call(Node1, '25_no_such_module', no_fun, []),
    d("对端 undef 的失败形状（只看第一层标签）", badrpc),
    %% 失败形状二：节点根本不存在（epmd 里查无此名）→ nodedown
    Nobody = list_to_atom("ex25_nobody@" ++ net_adm:localhost()),
    {badrpc, nodedown} = rpc:call(Nobody, erlang, node, [], 1000),
    d("对端不存在的失败形状", {badrpc, nodedown}).

%% ------------------------------------------------------------ %%
%% 4) 对端 spawn：代码在哪，进程就在哪
%% ------------------------------------------------------------
section_spawn(Node1) ->
    io:format("~n== 4) 对端 spawn：代码在哪，进程就在哪 ==~n"),
    %% 分布式 spawn 原语：第一个参数是节点名
    RemotePid = spawn(Node1, ?MODULE, loop, []),
    d("spawn(对端, M, F, A) 得到的是远端 pid", is_pid(RemotePid)),
    d("进程位置的节点", strip_host(Node1)),
    %% send 的语法完全没有变——位置透明性
    RemotePid ! {ping, self()},
    {pong, Node1} = receive {pong, N} -> {pong, N} after 3000 -> timeout end,
    d("远端进程回信，回信里带的节点名", strip_host(Node1)),
    %% rpc 的等价物：让对端自己 spawn（spawn/3 在对端求值）
    RemotePid2 = rpc:call(Node1, erlang, spawn, [?MODULE, loop, []]),
    RemotePid2 ! {ping, self()},
    {pong, Node1} = receive {pong, N2} -> {pong, N2} after 3000 -> timeout end,
    d("rpc 起 spawn 的进程同样回信", pong),
    RemotePid ! stop,
    RemotePid2 ! stop.

%% ------------------------------------------------------------ %%
%% 5) global：集群级注册名
%% ------------------------------------------------------------
section_global(Node1) ->
    io:format("~n== 5) global：集群级注册名 ==~n"),
    RemotePid = spawn(Node1, ?MODULE, loop, []),
    %% register 只在本节点注册；global 的名字整个集群共享。
    %% 注意成功返回的是原子 yes（不是 true）
    yes = rpc:call(Node1, global, register_name, [ex25_echo, RemotePid]),
    %% global 名字的跨节点同步是异步的——查之前先 sync 等一次交换
    ok = global:sync(),
    d("global:whereis_name 从本节点查", is_pid(global:whereis_name(ex25_echo))),
    d("同一个名字在对端查也一样", is_pid(rpc:call(Node1, global, whereis_name, [ex25_echo]))),
    global:send(ex25_echo, {ping, self()}),
    {pong, Node1} = receive {pong, N} -> {pong, N} after 3000 -> timeout end,
    d("global:send 送到的进程节点", strip_host(Node1)),
    d("查不存在的 global 名（对比）", global:whereis_name(no_such_global_name)),
    RemotePid ! stop.

%% ------------------------------------------------------------ %%
%% 6) cookie：节点握手的口令
%%    用 TCP 控制 peer：分布式连接不自动建立，握手由我们发起，可控
%% ------------------------------------------------------------
section_cookie(Node2) ->
    io:format("~n== 6) cookie：节点握手的口令 ==~n"),
    d("本节点 cookie 是原子（值保密不打印）", is_atom(erlang:get_cookie())),
    io:format("  （同机节点默认读同一份 ~~/.erlang.cookie，握手不用管口令；~n"),
    io:format("   set_cookie(节点, 口令) 改的是「连那个节点」用的口令）~n"),
    true = erlang:set_cookie(Node2, erlang:get_cookie()),
    d("显式设成当前口令再 ping", net_adm:ping(Node2)),
    %% 口令不同时握手在「挑战应答」阶段被拒，ping 返回 pang——但拒绝会
    %% 触发 ERTS 层的 ERROR REPORT（带时间戳、不走 logger、摘 handler
    %% 也拦不住），确定性演示必须避开真实的失配握手，用「节点不存在」
    %% 演示同款的 pang（连握手都没有，自然无报告）
    Nobody = list_to_atom("ex25_ghost@" ++ net_adm:localhost()),
    d("ping 不存在的节点（pang，无握手无报告）", net_adm:ping(Nobody)).

%% ------------------------------------------------------------ %%
%% 7) 拓扑：连接、断开、重连
%% ------------------------------------------------------------
section_topology(Node2) ->
    io:format("~n== 7) 拓扑：连接、断开、重连 ==~n"),
    d("当前已连节点", [strip_host(N) || N <- lists:sort(nodes())]),
    d("对已连接节点再 ping（幂等）", net_adm:ping(Node2)),
    true = net_kernel:disconnect(Node2),
    d("disconnect 之后 nodes()", [strip_host(N) || N <- lists:sort(nodes())]),
    d("再 ping 一次就回来了（口令没变）", net_adm:ping(Node2)),
    io:format("  （注意：对默认 peer——分布式连接即控制通道——disconnect 会把~n"),
    io:format("   peer 节点一并杀死；本节用的是 TCP 控制 peer 才能反复断连）~n").

%% ------------------------------------------------------------ %%
%% 8) 收摊：节点生命周期归 peer 管
%% ------------------------------------------------------------
section_stop(Peer1, Peer2) ->
    io:format("~n== 8) 收摊：节点生命周期归 peer 管 ==~n"),
    ok = peer:stop(Peer1),
    ok = peer:stop(Peer2),
    d("两个 peer 都停了，nodes()", [strip_host(N) || N <- lists:sort(nodes())]),
    d("停掉后再 whereis_name 集群名", global:whereis_name(ex25_echo)).
