%% ============================================================
%% kvapp_store —— 应用里的那个真正的干活进程（gen_server）
%%
%% 用法上它跟第 21 章写的 gen_server 没有区别，唯一的新东西是：
%% init/1 里的配置是**从应用环境（application environment）读的**，
%% 而不是写死在代码里 —— 这就是「应用」这一层最日常的价值。
%% ============================================================
-module(kvapp_store).

-behaviour(gen_server).

-export([start_link/0, put/2, get/1, all/0, count/0, capacity/0, put_async/2]).

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
         terminate/2, code_change/3]).

-define(TAB, kvapp_store_tab).
-define(SERVER, ?MODULE).

start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%% ---- 客户端 API ----
put(K, V) -> gen_server:call(?SERVER, {put, K, V}).
put_async(K, V) -> gen_server:cast(?SERVER, {put_async, K, V}).
get(K) -> gen_server:call(?SERVER, {get, K}).
all() -> gen_server:call(?SERVER, all).
count() -> gen_server:call(?SERVER, count).
capacity() -> gen_server:call(?SERVER, capacity).

%% ---- 回调 ----

init([]) ->
    %% **实测坑**：gen_server 默认 **trap_exit = false**，而监督者关闭孩子的方式是
    %% `exit(Child, shutdown)`。不 trap 的话这个信号直接把它打死，
    %% `terminate/2` **根本不会被调用**（于是你在 terminate 里写的落盘/关表全丢了）。
    %% 想让 terminate/2 在正常关闭时跑起来，必须自己打开 trap_exit。
    %% 打开之后：来自「父进程」的 {'EXIT', Parent, Reason} 会被 gen_server 转成
    %% terminate(Reason, State) 调用；来自其它链接进程的 EXIT 变成普通消息，
    %% 需要自己在 handle_info 里处理（本模块的做法是忽略并记下来）。
    process_flag(trap_exit, true),

    %% 三条关键实测行为：
    %%   1. 应用**已加载**（loaded）时，get_env/3 能读到 .app 里的默认值；
    %%   2. 应用根本没加载时，get_env/3 返回 undefined → 用第三个参数的默认值；
    %%   3. 应用**已启动**之后 set_env/3 改的值，这里就能读到新的。
    Max = application:get_env(kvapp, max_items, 100),
    Mode = application:get_env(kvapp, store_mode, memory),
    Tab = ets:new(?TAB, [set, protected, named_table, {read_concurrency, true}]),
    {ok, #{tab => Tab, max => Max, mode => Mode, puts => 0}}.

handle_call({put, K, V}, _From, S = #{tab := T, max := Max, puts := N}) ->
    %% 满了就拒绝（覆盖已有键不算新增），演示「配置真的在起作用」
    Full = (ets:info(T, size) >= Max) andalso (ets:lookup(T, K) =:= []),
    case Full of
        true  -> {reply, {error, full}, S};
        false -> true = ets:insert(T, {K, V}),
                 {reply, ok, S#{puts := N + 1}}
    end;
handle_call({get, K}, _From, S = #{tab := T}) ->
    Reply = case ets:lookup(T, K) of
                [{_, V}] -> {ok, V};
                []       -> not_found
            end,
    {reply, Reply, S};
handle_call(all, _From, S = #{tab := T}) ->
    {reply, lists:sort(ets:tab2list(T)), S};
handle_call(count, _From, S = #{tab := T}) ->
    {reply, ets:info(T, size), S};
handle_call(capacity, _From, S = #{max := Max, mode := Mode}) ->
    {reply, {Max, Mode}, S};
handle_call(Other, _From, S) ->
    {reply, {error, {unknown_request, Other}}, S}.

handle_cast({put_async, K, V}, S = #{tab := T}) ->
    true = ets:insert(T, {K, V}),
    {noreply, S};
handle_cast(_Msg, S) ->
    {noreply, S}.

handle_info(Info, S) ->
    %% 收到不认识的消息只记下来，绝不崩 —— 这是写服务进程的基本纪律
    {noreply, S#{last_info => Info}}.

%% 应用停止时，监督者会先发 shutdown 信号，本回调就会被调到。
%% 注意：如果是被 kill 杀掉的，terminate/2 **不会**执行（第 20 章实测过）。
terminate(Reason, #{tab := T}) ->
    io:format("    [kvapp_store:terminate/2] Reason=~p，关表时还剩 ~p 条~n",
              [Reason, ets:info(T, size)]),
    ok.

code_change(_OldVsn, S, _Extra) ->
    {ok, S}.
