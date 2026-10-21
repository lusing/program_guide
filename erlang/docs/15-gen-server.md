# 15 · gen_server ⭐

> 对应示例：`examples/15_gen_server/`（`-behaviour(gen_server)`）

## 15.1 把手写协议变成标准件

13 章手写的 receive 循环：协议形状、超时、错误处理、状态管理每个服务都要重写一遍。gen_server 把它们固化成**回调契约（behaviour）**：

```erlang
-behaviour(gen_server).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

%% 业务 API 层：内部一律走 call / cast
start_link()   -> gen_server:start_link({local, ?SERVER}, ?MODULE, Args, []).
fetch(K)       -> gen_server:call(?SERVER, {get, K}).
put(K, V)      -> gen_server:call(?SERVER, {put, K, V}).
tick(Ms)       -> gen_server:cast(?SERVER, {tick, Ms}).
stop()         -> gen_server:stop(?SERVER).
```

## 15.2 回调速查

```erlang
init(Args) -> {ok, State}.                                %% 启动
handle_call(Req, From, State) -> {reply, Reply, NewState}.  %% 同步请求
handle_cast(Req, State)       -> {noreply, NewState}.       %% 异步请求
handle_info(Msg, State)       -> {noreply, NewState}.       %% 其它一切消息
terminate(Reason, State)      -> ok.                        %% 收尾
```

状态不是"改"的——回调把 State 当**输入和返回值**传递，真正的状态活在服务进程的循环里。变体：`{noreply, State}` + `gen_server:reply/2`（先干活后回）、`{stop, Reason, Reply, State}`（先回再优雅停止）、`{continue, Term}`、`hibernate`（完整表在示例尾部注释）。

## 15.3 call / cast / info 三通道

| | 阻塞 | 回复 | 典型用途 |
|---|---|---|---|
| `gen_server:call/2,3` | 阻塞等回复（默认超时 5000ms） | `handle_call` | 查询/需要结果的写 |
| `gen_server:cast/2` | 立即返回 ok（只表示**发出去了**） | `handle_cast` | 通知 |
| 直接 `Pid ! Msg` | 永不阻塞 | `handle_info` | 定时器消息、系统消息 |

同一发送者消息 FIFO——"cast 之后立刻 call"顺序可靠；"cast 之后 sleep 一会儿"不可靠。定时消息（`erlang:send_after` 发给自己）与一切非 call/cast 消息都走 `handle_info`——**必须留兜底子句**，否则未知消息堆积。

## 15.4 send_request：不阻塞的同步调用（OTP 23）

`call` 是"发出去就睡在原地等"。想**同时向多个服务发请求、谁先回先处理谁**，OTP 23 把 call 拆成了"发"和"收"两步（本机 OTP 29 实测）：

```erlang
ReqId = gen_server:send_request(S, {echo, hi}).  %% => #Ref<...>——立即返回请求标识
gen_server:wait_response(ReqId, 1000).           %% => {reply, {echoed, hi}}——收的时候才等
gen_server:receive_response(ReqId, 1000).        %% 同左，纯阻塞语义
```

自己 receive 收响应时要匹配**真实消息形状**（OTP 24+ 实测）：`{[alias|ReqId], Reply}`——不是 `{ReqId, Reply}`：

```erlang
receive {[alias|ReqId], Reply} -> Reply end.   %% => {echoed, hi}
```

平时尽量走上面三个收取函数，它们替你匹配这个形状。

wait_response 超时**不抛异常、返回 `timeout`**（实测：50ms 等一个 200ms 的活 → `timeout`；睡够再取 → `{reply, slow_done}`）。三个收取函数的分工：

| 函数 | 语义 | 返回 |
|---|---|---|
| `wait_response(ReqId, Timeout)` | 等响应，无关消息留在邮箱 | `{reply, R}` \| `timeout` |
| `receive_response(ReqId, Timeout)` | 阻塞直取响应 | `{reply, R}` \| `timeout` |
| `check_response(Msg, ReqId)` | **不等待**——检查手里这条消息是不是响应 | `{reply, R}` \| `no_reply` |

check_response 是给 receive 循环当过滤器用的（实测）：

```erlang
R3 = gen_server:send_request(S, {echo, checkme}),
receive M3 -> ok end,
gen_server:check_response(M3, R3).              %% => {reply, {echoed, checkme}}
gen_server:check_response(some_other_msg, R3).  %% => no_reply——这条不是它的响应
```

**一把发、按标签收（OTP 25）**：请求多了用 reqids collection 管理，每个请求贴个标签，取响应时标签告诉你这是谁：

```erlang
C0 = gen_server:reqids_new(),
C1 = gen_server:send_request(S, {echo, 1}, first,  C0),  %% /4：带标签直接进 collection
C2 = gen_server:send_request(S, {echo, 2}, second, C1),
gen_server:reqids_size(C2).                 %% => 2
{Res, Label, C3} = gen_server:wait_response(C2, 1000, true),
%% => Res = {reply, {echoed, 1}}, Label = first——先到的先出；C3 自动移除该请求
gen_server:reqids_size(C3).                 %% => 1
```

场景：扇出查询（问一圈节点谁有 key）、并行聚合（同时查汇率和库存，慢的不拖快的）。循环发 N 个 call 是**串行**——第一个 5000ms 超时后面全排队；send_request 是真并行。

**新式超时消息（OTP 25）**：回调返回值第三元从裸毫秒数升级为 `{timeout, Time, Msg}`——到点后 handle_info 收到的**就是 Msg 原样**，不再是魔法原子 `timeout`（实测：`{ok, [], {timeout, 30, tick}}` → 30ms 后收到 `tick`）。超时消息从此可以带上下文、跟普通消息一个写法；老式裸 `Time` 仍兼容。

## 15.5 状态属于进程不属于函数

```erlang
%% 直接调回调"看起来能跑"，但状态不会被保留：
{reply, undefined, _} = '15_gen_server':handle_call({get, x}, From, 假状态).
%% 通过消息问服务进程，拿到的才是真实状态：
100 = '15_gen_server':fetch(x).
```

直接调回调 = 绕过消息队列 = 状态丢了还没人知道。**一切请求走 call / cast**。

## 15.6 回调抛异常会怎样

`handle_call` 里 `erlang:error(boom)`：服务进程崩溃 → 调用方收到 `exit`（带原因与 `{gen_server, call, [Name, Request]}` 现场，**不会拿到半个结果**）→ 注册名自动释放 → `terminate/2` 在死前被调用。之后 `gen_server:call` 对已死名字直接抛 exit。这就是"崩溃是可观测的"——监督树（16 章）在这个信号上重建进程。

## 15.7 terminate 什么时候被调

调用的场景：回调返回 `{stop,...}`、`gen_server:stop`、父进程（supervisor）要求关闭（**前提是 trap_exit**）、回调抛异常。**不被调用**：`exit(Pid, kill)` 直接干掉。17 章 kvapp 在 `init` 里 `process_flag(trap_exit, true)` 就是为了让 terminate 一定跑。

## 15.8 坑位清单

1. **API 别叫 get/1、size/1**：撞自动导入 BIF，编译报 `ambiguous call of overridden auto-imported BIF`——改名（fetch/count）或 `-compile({no_auto_import, [get/1]})`。
2. **直接调回调**：状态不会被保留，还绕过了消息顺序——见 15.5 实测。
3. **handle_info 没兜底**：未知消息永远留在邮箱，内存泄漏 + 排障黑洞。
4. **call 默认 5000ms 超时**：慢操作要么传大超时，要么改 cast + 主动通知。
5. **忘了回调要导出**：behaviour 只检查"声明了"，漏导出运行期才 undef。
6. **测试里 start_link 不开 trap_exit**：服务崩溃把测试进程一起带走（EUnit 整组 cancelled——本教程实测踩过）。
7. **check_response 不等待**：签名是 `check_response(Msg, ReqId)`——检查**已收到**的消息，不是 `check_response(ReqId, Timeout)`（实测传 Timeout 数字直接 badarg）。
8. **collection 版 wait/receive 是 /3**：`wait_response(C2, 1000)` 当单请求处理会返回 timeout，collection 必须 `wait_response(C2, 1000, true)`（实测）。
9. **自收响应匹配错形状**：响应消息是 `{[alias|ReqId], Reply}`（OTP 24 起经 alias 发送），裸 receive 写 `{ReqId, Reply}` 永远等不到——见 15.4。

---

---

上一章：[14 链接与监控](14-links.md) · 下一章：[16 supervisor ⭐](16-supervisor.md)
