%% ============================================================
%% 21 - gen_server：把第 19 章那套协议变成标准件
%%
%%    手写 receive 循环的问题是：协议形状、超时、错误处理、状态管理，
%%    每写一个服务都要重复一遍，而且很难写对。
%%    gen_server 把这些部分固化下来：
%%      · 回调函数（init / handle_call / handle_cast / handle_info / terminate）
%%      · 调用外壳（gen_server:call / cast / stop）
%%      · 状态只存在于服务进程里，回调把它作为**输入和返回值**传递
%%
%%    最关键的一条：**回调函数永远不要直接调用**（那只是普通函数，
%%    改了状态没人知道），一切请求都要通过 gen_server:call / cast 走消息队列。
%%
%%    本示例的每个服务实例都带一个 Tag，所有通知消息里都带回 Tag，
%%    这样 receive 的配对是确定的，不会捡到上一个实例的残留消息。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/ebin examples/21-gen-server.erl
%% 运行：
%%   erl -noshell -pa build/ebin -run '21-gen-server' main -s init stop
%% ============================================================
-module('21-gen-server').

-behaviour(gen_server).

%% 业务 API
-export([main/0, start_link/1, fetch/1, put/3, count/0, snapshot/0, tick/2, stop/0]).
%% gen_server 回调（必须导出，否则运行期 undef）
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-define(SERVER, ?MODULE).

%% ------------------------------------------------------------
%% 业务 API：给调用方看的接口，内部一律走 call / cast
%% ------------------------------------------------------------
%% 命名注意（实测踩到的坑）：**别把 API 叫成 get/1 或 size/1** ——
%% 它们是自动导入的 BIF（进程字典的 get/1、term 的 size/1），
%% 本地定义会撞上，编译报
%%   ambiguous call of overridden auto-imported BIF get/1
%% 两个办法：改名（本示例改成 fetch/1、count/0），或者写
%%   -compile({no_auto_import, [get/1]}).
%% 一般直接改名更省事。
%%
%% notify 取调用者的 pid（start_link 是在调用者进程里执行的），
%% Tag 用来给「服务主动发出的通知」打记号。
start_link(Tag) ->
    gen_server:start_link({local, ?SERVER}, ?MODULE,
                          #{notify => self(), tag => Tag}, []).

fetch(K)      -> gen_server:call(?SERVER, {get, K}).
put(K, V, By) -> gen_server:call(?SERVER, {put, K, V, By}).
count()       -> gen_server:call(?SERVER, count).
snapshot()    -> gen_server:call(?SERVER, snapshot).
tick(Tag, Ms) -> gen_server:cast(?SERVER, {tick, Tag, Ms}).
stop()        -> gen_server:stop(?SERVER).

%% ------------------------------------------------------------
%% 回调
%% ------------------------------------------------------------
init(#{notify := N, tag := Tag}) ->
    {ok, #{notify => N, tag => Tag, data => #{}}}.

%% handle_call/3：同步请求。必须给调用方一个结果，两种方式：
%%   {reply, Reply, NewState}                     框架替你回
%%   {noreply, NewState} + gen_server:reply/2     自己回（先干活后回的场景）
handle_call({get, K}, _From, State) ->
    {reply, maps:get(K, maps:get(data, State), undefined), State};
handle_call({put, K, V, By}, _From, State) ->
    Data = maps:get(data, State),
    %% 状态不是「改」的：算出新状态**返回**给框架
    {reply, ok, State#{data := Data#{K => V}, last_writer => By}};
handle_call(count, _From, State) ->
    {reply, maps:size(maps:get(data, State)), State};
handle_call(snapshot, _From, State) ->
    %% 只暴露稳定的部分（notify 里是 pid，不能进输出）
    {reply, {maps:size(maps:get(data, State)), maps:get(last_writer, State, none)}, State};
handle_call({countdown, 0}, _From, State) ->
    %% {stop, Reason, Reply, NewState}：先回复再优雅停止，terminate/2 会被调用
    {stop, normal, stopped, State};
handle_call({countdown, N}, _From, State) when is_integer(N), N > 0 ->
    {reply, {countdown, N - 1}, State};
handle_call(boom, _From, _State) ->
    %% 回调里抛异常 → 服务进程崩溃，调用方会收到一个明确的 exit
    erlang:error(callback_boom);
handle_call(Request, _From, State) ->
    {reply, {error, {unknown_request, Request}}, State}.

%% handle_cast/2：异步请求，**没有回复**。
%% cast 的返回值是 ok，但那只说明「消息发出去了」，不代表服务处理完了。
handle_cast({tick, Tag, Ms}, State) ->
    _ = erlang:send_after(Ms, self(), {tick, Tag}),
    {noreply, State};
handle_cast({countdown, 0}, State) ->
    {stop, normal, State};
handle_cast({countdown, N}, State) when is_integer(N), N > 0 ->
    _ = erlang:send_after(10, self(), {countdown, N - 1}),
    {noreply, State}.

%% handle_info/2：收到「不是 call / cast」的普通消息时走这里 ——
%% send_after 的定时消息、别人直接 ! 过来的消息、以及回调返回的 Timeout 到期。
handle_info({tick, Tag}, State) ->
    notify(State, {ticked, Tag, ok}),
    {noreply, State};
handle_info({countdown, N}, State) when N > 0 ->
    _ = erlang:send_after(10, self(), {countdown, N - 1}),
    {noreply, State};
handle_info({countdown, 0}, State) ->
    {stop, normal, State};
handle_info(Info, State) ->
    notify(State, {unexpected_info, maps:get(tag, State), Info}),
    {noreply, State}.

%% terminate/2：**只有框架能察觉的终止**才会调用：
%%   · 回调返回 {stop, Reason, ...}
%%   · gen_server:stop/1
%%   · 父进程（supervisor）要求关闭，或本进程 trap_exit 且收到 exit 信号
%%   · 回调抛异常（进程带着原因死掉之前，terminate 会先被调用）
%% 不会调用：被 exit(Pid, kill) 直接干掉。
terminate(Reason, State) ->
    notify(State, {terminating, maps:get(tag, State), Reason}),
    ok.

code_change(_OldVsn, State, _Extra) -> {ok, State}.

notify(State, Msg) -> maps:get(notify, State) ! Msg.

%% ------------------------------------------------------------
%% 演示
%% ------------------------------------------------------------
main() ->
    %% gen_server 崩溃也会走 logger 的默认 handler（带时间戳的 ERROR REPORT），
    %% 先摘掉才能得到可重复输出（见第 15、27 章）。
    _ = logger:remove_handler(default),
    %% 本进程由 erl -run 启动，trap_exit 本来就是 true（第 20 章实测），
    %% 所以 start_link 的服务崩了不会连带杀掉我们。显式设一遍再还原。
    Old = process_flag(trap_exit, true),

    basics(),
    state_lives_in_the_process(),
    asynchronous_cast(),
    timer_and_info(),
    crash_in_callback(),
    graceful_stop(),

    process_flag(trap_exit, Old),
    io:format("~n==== 21 结束 ====~n").

%% 1) 最小 gen_server：同步 call
basics() ->
    io:format("== 1) 最小 gen_server：同步 call ==~n"),
    {ok, Pid} = start_link(basic),
    d("start_link 返回 {ok, Pid}（只断言是 pid，不打印）", is_pid(Pid)),
    d("初始 count", count()),
    d("put(a, 1, alice) 的返回", put(a, 1, alice)),
    d("put(b, 2, bob) 的返回", put(b, 2, bob)),
    d("count 变成", count()),
    d("fetch(a) / fetch(b)", {fetch(a), fetch(b)}),
    d("fetch(不存在的键) → 回调里给的默认值", fetch(zzz)),
    d("snapshot（size, 最后一个写入者）", snapshot()),
    d("协议外的请求被回调的兜底子句接住", gen_server:call(?SERVER, {weird, 1})),
    d("停止服务", stop()),
    %% 这里有个坑：start_link 让主进程和服务**互相 link**，服务停止时主进程
    %% 还会收到一条 {'EXIT', Pid, Reason}（因为主进程 trap_exit）。
    %% 所以 receive 必须按 tag 精确匹配，写成 catch-all 的 receive Msg -> Msg
    %% 就会捡到那条 EXIT 消息，打印出 <0.83.0> 这种不可重复的内容。
    d("terminate 通知（Tag = basic）",
      receive {terminating, basic, R} -> {terminating, basic, R}
      after 2000 -> timeout
      end),
    ok.

%% 2) 状态活在服务进程里，不在函数里
%% ------------------------------------------------------------
%% 直接调回调会「看起来能跑」，但状态不会被保留 ——
%% 因为状态只是回调的输入/输出参数，真正的状态在服务进程的循环里。
state_lives_in_the_process() ->
    io:format("~n== 2) 为什么不能直接调回调 ==~n"),
    {ok, _Pid} = start_link(state_demo),
    _ = put(x, 100, tester),
    MyState = #{notify => self(), tag => fake, data => #{}},
    Direct = element(2, handle_call({get, x}, {self(), make_ref()}, MyState)),
    d("直接调 handle_call 并传一个空状态，拿到的", Direct),
    d("通过 gen_server:call 问服务进程，拿到的真实状态", fetch(x)),
    d("两个值不同 → 状态属于进程，不属于函数", Direct =/= fetch(x)),
    d("停止服务", stop()),
    d("terminate 通知（Tag = state_demo）",
      receive {terminating, state_demo, R} -> {terminating, state_demo, R}
      after 2000 -> timeout
      end),
    ok.

%% 3) 异步 cast
%% ------------------------------------------------------------
%% cast 立刻返回，服务什么时候处理完不知道。
%% 所以「cast 之后立刻 call」得到的先后是可靠的（同一发送者的消息 FIFO），
%% 但「cast 之后 sleep 一会儿」是不可靠的。
asynchronous_cast() ->
    io:format("~n== 3) 异步 cast ==~n"),
    {ok, _Pid} = start_link(cast_demo),
    d("cast 的返回值（只表示消息发出去了）", tick(cast_demo, 30)),
    d("服务处理完定时消息后主动通知我们（Tag 对上号）",
      receive {ticked, cast_demo, R} -> {ticked, cast_demo, R}
      after 2000 -> timeout
      end),
    _ = put(before, 1, cast_demo),
    _ = tick(cast_demo, 20),
    %% 同一发送者的消息是 FIFO 的，所以这次 call 一定能看到 put 的结果
    d("cast 之后立刻 call（FIFO 保证顺序）", count()),
    receive {ticked, cast_demo, _} -> ok after 2000 -> ok end,
    d("停止服务", stop()),
    receive {terminating, cast_demo, _} -> ok after 2000 -> ok end,
    ok.

%% 4) 定时与 handle_info
timer_and_info() ->
    io:format("~n== 4) 定时器与 handle_info ==~n"),
    {ok, _Pid} = start_link(timer_demo),
    %% 让服务每 10ms 减 1，数到 0 自己停（cast 触发，之后靠 handle_info 驱动）
    gen_server:cast(?SERVER, {countdown, 3}),
    d("服务数到 0 自己停止，terminate 通知我们",
      receive {terminating, timer_demo, R} -> {terminating, timer_demo, R}
      after 2000 -> timeout
      end),
    %% 再起一个，直接 ! 一条服务不认识的消息，看 handle_info 的兜底子句
    {ok, Pid2} = start_link(info_demo),
    Pid2 ! {surprise, 42},
    d("服务收到不认识的消息时通知 notify 进程",
      receive {unexpected_info, info_demo, I} -> I after 2000 -> timeout end),
    d("停止服务", stop()),
    receive {terminating, info_demo, _} -> ok after 2000 -> ok end,
    ok.

%% 5) 回调里抛异常：服务崩掉，调用方收到什么
%% ------------------------------------------------------------
%% 这是 gen_server 最有价值的地方之一：调用方不会拿到半个结果，
%% 而是收到一个明确的 exit（带原因和调用现场）。名字会自动释放。
crash_in_callback() ->
    io:format("~n== 5) 回调里抛异常 ==~n"),
    {ok, Pid} = start_link(crash_demo),
    d("调用会崩的请求，调用方收到",
      try gen_server:call(?SERVER, boom)
      catch
          Class:Reason -> {Class, describe_call_failure(Reason)}
      end),
    d("terminate 也被调用了（原因里带栈）",
      receive {terminating, crash_demo, TR} -> tag_of(TR) after 2000 -> timeout end),
    d("服务进程还活着吗", is_process_alive(Pid)),
    d("注册名字释放了吗（whereis → undefined）", whereis(?SERVER)),
    d("再 call 一个已经没了的服务",
      try gen_server:call(?SERVER, count)
      catch
          exit:R2 -> {exit, describe_call_failure(R2)}
      end),
    ok.

%% 6) 优雅停止
graceful_stop() ->
    io:format("~n== 6) 优雅停止 ==~n"),
    {ok, _Pid} = start_link(stop_demo_call),
    _ = put(k, k1, carol),
    d("从 handle_call 里返回 {stop, normal, Reply, State}",
      gen_server:call(?SERVER, {countdown, 0})),
    d("terminate 的原因",
      receive {terminating, stop_demo_call, R} -> R after 2000 -> timeout end),
    {ok, _} = start_link(stop_demo_api),
    d("gen_server:stop 的返回", stop()),
    d("terminate 的原因",
      receive {terminating, stop_demo_api, R2} -> R2 after 2000 -> timeout end),
    ok.

%% gen_server:call 失败时，调用方拿到的 exit 原因是
%%   {Reason, {gen_server, call, [Name, Request]}}
%% 其中 Reason 可能带着整个栈（里面是 file / line）—— 那就没法当稳定输出了。
%% 只保留标签与请求内容。
describe_call_failure({Reason, {gen_server, call, [_Name, Request]}}) ->
    {call_failed, tag_of(Reason), request, Request};
describe_call_failure(Other) ->
    tag_of(Other).

tag_of({Reason, Stack}) when is_list(Stack) -> {crashed, Reason, stack_non_empty, Stack =/= []};
tag_of(R) -> R.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).

%% ============================================================
%% 附：回调返回值全表（照手册整理，本示例只用到其中一部分）
%%
%% init/1
%%   {ok, State}                   正常启动
%%   {ok, State, Timeout}          并设一个初始超时（到期触发 handle_info(timeout, _)）
%%   {ok, State, hibernate}        启动后立刻休眠（省内存，适合长期不用的状态）
%%   {ok, State, {continue, Term}} 启动后立刻给自己发一条消息
%%   ignore                        不启动，start_link 返回 ignore（不是错误）
%%   {stop, Reason}                启动失败
%%
%% handle_call/3
%%   {reply, Reply, NewState}
%%   {reply, Reply, NewState, Timeout | hibernate | {continue, Term}}
%%   {noreply, NewState}               框架不回，自己用 gen_server:reply/2 回
%%   {noreply, NewState, Timeout | hibernate | {continue, Term}}
%%   {stop, Reason, Reply, NewState}   先回复再停
%%   {stop, Reason, NewState}          不回复直接停（调用方收到 exit）
%%
%% handle_cast/2 与 handle_info/2
%%   {noreply, NewState}
%%   {noreply, NewState, Timeout | hibernate | {continue, Term}}
%%   {stop, Reason, NewState}
%%
%% terminate/2    任何返回值都被忽略
%% code_change/3  {ok, NewState} | {error, Reason}
%% ============================================================
