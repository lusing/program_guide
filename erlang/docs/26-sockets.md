# 26 · 套接字编程：TCP/UDP 服务器与流控

> 对应示例：`examples/26_sockets/`

Erlang 写网络服务的原生姿态：一条连接一个进程、消息驱动、崩溃隔离。
取材《Erlang 程序设计》第 17 章（顺序服务器 → 并行服务器 → 路由器）；
第 18 章的 WebSocket 走 cowboy 生态、超出「零依赖」铁律，只在文末
留一段概念。

## 26.1 listen / accept：一条连接的诞生

```erlang
{ok, Listen} = gen_tcp:listen(0, [binary, {packet, 2}, {active, false},
                                  {reuseaddr, true}]),
{ok, Port} = inet:port(Listen),          %% 端口 0 = 系统分配空闲端口
{ok, Sock} = gen_tcp:accept(Listen),     %% 阻塞等一条连接（继承 listener 的模式）
```

端口 0 让内核挑空闲端口——确定性脚本不抢固定端口。协议载荷用
`term_to_binary/binary_to_term`：零依赖的「结构化协议」，中文、
元组、列表直接当消息发。

## 26.2 顺序服务器：一次只陪一个客户端

```erlang
seq_accept_loop(Listen) ->
    case gen_tcp:accept(Listen) of
        {ok, Sock} -> seq_conn_loop(Sock), seq_accept_loop(Listen);
        {error, _} -> ok
    end.
seq_conn_loop(Sock) ->
    case gen_tcp:recv(Sock, 0, 3000) of   %% 被动模式：recv 拉取
        {ok, Bin} -> gen_tcp:send(Sock, term_to_binary({echo, binary_to_term(Bin)})),
                     seq_conn_loop(Sock);
        {error, _} -> gen_tcp:close(Sock)
    end.
```

第一个客户端不说话，服务器就干等——**第二个客户端 connect 成功**
（内核握手排队）**但没人 accept 它**：

```text
顺序服务器：B 发了请求，recv 等到的只有 = {error,timeout}
```

## 26.3 active 三态：true / false / once

| 模式 | 语义 | 代价 |
|---|---|---|
| `{active, true}` | 驱动把数据推进邮箱（`{tcp, Sock, Data}`） | 无背压——洪流可能撑爆邮箱 |
| `{active, false}` | 全靠 `recv/2,3` 拉 | 每次都要显式调 |
| `{active, once}` | 推**一条**，停——想再收必须再 `inet:setopts` | 流控的甜点位 |

**once 的坑是双侧的**：服务器每回一条要再武装，客户端每收一条也要
再武装——任何一侧忘了，下一条消息永远躺在驱动里：

```text
active once：第 1 条作为消息到达 = {echo,first}
没再武装：第 2 条收不到（驱动停推） = true
再武装后第 2 条立刻到达 = {echo,second}
```

## 26.4 并行服务器：accept 一个 spawn 一个

```erlang
par_accept_loop(Listen) ->
    case gen_tcp:accept(Listen) of
        {ok, Sock} ->
            spawn(fun () -> par_accept_loop(Listen) end),  %% 马上回去等下一个
            seq_conn_loop(Sock);                           %% 每连接一个进程
        {error, _} -> ok
    end.
```

一条连接一个进程：慢客户端只堵它自己那条进程，acceptor 永远有空。
两位并发客户端都拿到回音：

```text
并行服务器：两位都拿到回音 = [{echo,a},{echo,b}]
```

这**不是** gen_server——纯 receive 循环就是最朴素的 socket 进程；
要挂进监督树时才把 `seq_conn_loop` 换成 OTP 行为的回调。

## 26.5 UDP：无连接的数据报

```erlang
{ok, S} = gen_udp:open(0, [binary, {active, false}]),
ok = gen_udp:send(C, {127, 0, 0, 1}, Port, <<"ping">>),
{ok, {Addr, FromPort, Data}} = gen_udp:recv(C, 0, 2400).
```

三个实测形状坑：

1. **`gen_udp:recv` 返回扁平三元组** `{ok, {Addr, Port, Packet}}`
   （OTP 29 的 spec 就这么写；老教程的 `{ok, {Addr, Port}, Packet}`
   直接 badmatch）；
2. 回信要 `gen_udp:send/4` 拆开地址端口——把 recv 里那个内层元组
   整个塞回去 badarg；
3. 未 connect 的 socket 用 **send/3** 也 badarg——send/3 是「连过之后
   只给端口」的版本，永远写全 `send(Socket, Addr, Port, Data)` 稳妥；
   地址用字面 `{127,0,0,1}`（`"localhost"` 可能解析到 IPv6，回信走丢）。

## 26.6 raw 字节流：send 的边界不作数

```text
两次 send 的 4+6 字节，对端一次收成 = "aaaabbbbbb"
```

`{packet, raw}` 下 TCP 就是纯字节流：两次 send 的边界在对端一次
recv 里消失。`{packet, N}` 帧由驱动负责加/剥——消息边界回来了；
`recv(Sock, N)` 定长读则自己凑字节（演示里手工写了 2 字节前缀成帧，
这是第 27 章端口协议的预告）。

## 26.7 WebSocket 一段概念

`gen_tcp` 之上手写 WebSocket 要处理 HTTP 升级握手、帧格式
（FIN/opcode/mask）、掩码解码——书上第 18 章正是这么教的。工程里
用 cowboy/ranch（监听器/路由/升级都是现成的）。本教程守住零依赖，
知道「WebSocket = TCP + 升级握手 + 帧协议」即可。

## 26.8 要点小结

```text
  监听端口 0 由系统分配；{reuseaddr,true} 防重启撞 TIME_WAIT
  顺序服务器一次陪一个；并行服务器 accept 一个 spawn 一个
  active 三态：true 推送无背压 / false 拉取 / once 推一条停一条
  active once 双侧都要再武装——漏一侧消息永远躺在驱动里
  UDP 扁平三元组 {Addr,Port,Packet}；send 永远写全 /4 + 字面 {127,0,0,1}
  raw 是字节流、send 边界不作数；packet N 让驱动管帧
  协议载荷 term_to_binary——零依赖的结构化协议
  确定性纪律：端口只打印 >0 布尔、recv 全带超时、并发结果排序后打印
```

## 26.9 坑位清单

1. **`gen_udp:recv` 的扁平三元组**（OTP 29）：`{ok, {Addr, Port,
   Packet}}`——老书写法 badmatch；源码 `-spec` 为证。
2. **`gen_udp:send/3` 只服务已 connect 的 socket**——未连接就用
   send/4，且地址写 `{127,0,0,1}` 而不是 `"localhost"`（v6 解析回信
   走丢）。
3. **active once 是「武装一次」不是「切到主动模式」**：双侧每条消息
   后都要 `inet:setopts(Sock, [{active, once}])`。
4. **recv 必须带超时**：顺序服务器 busy 时第二个客户端的 recv 若无
   超时就是永挂；演示/测试全用有界等待。
5. **accept 循环要兜 `{error, _}`**：监听 socket 一关，阻塞中的
   accept 返回错误——没有兜底子句的循环会崩给你看。
6. **并发客户端结果要排序后打印**：两连接的完成顺序不承诺，第 4 层
   逐字节验证只认排序后的输出。
