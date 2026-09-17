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

## 15.4 状态属于进程不属于函数

```erlang
%% 直接调回调"看起来能跑"，但状态不会被保留：
{reply, undefined, _} = '15_gen_server':handle_call({get, x}, From, 假状态).
%% 通过消息问服务进程，拿到的才是真实状态：
100 = '15_gen_server':fetch(x).
```

直接调回调 = 绕过消息队列 = 状态丢了还没人知道。**一切请求走 call / cast**。

## 15.5 回调抛异常会怎样

`handle_call` 里 `erlang:error(boom)`：服务进程崩溃 → 调用方收到 `exit`（带原因与 `{gen_server, call, [Name, Request]}` 现场，**不会拿到半个结果**）→ 注册名自动释放 → `terminate/2` 在死前被调用。之后 `gen_server:call` 对已死名字直接抛 exit。这就是"崩溃是可观测的"——监督树（16 章）在这个信号上重建进程。

## 15.6 terminate 什么时候被调

调用的场景：回调返回 `{stop,...}`、`gen_server:stop`、父进程（supervisor）要求关闭（**前提是 trap_exit**）、回调抛异常。**不被调用**：`exit(Pid, kill)` 直接干掉。17 章 kvapp 在 `init` 里 `process_flag(trap_exit, true)` 就是为了让 terminate 一定跑。

## 15.7 坑位清单

1. **API 别叫 get/1、size/1**：撞自动导入 BIF，编译报 `ambiguous call of overridden auto-imported BIF`——改名（fetch/count）或 `-compile({no_auto_import, [get/1]})`。
2. **直接调回调**：状态不会被保留，还绕过了消息顺序——见 15.4 实测。
3. **handle_info 没兜底**：未知消息永远留在邮箱，内存泄漏 + 排障黑洞。
4. **call 默认 5000ms 超时**：慢操作要么传大超时，要么改 cast + 主动通知。
5. **忘了回调要导出**：behaviour 只检查"声明了"，漏导出运行期才 undef。
6. **测试里 start_link 不开 trap_exit**：服务崩溃把测试进程一起带走（EUnit 整组 cancelled——本教程实测踩过）。

---
