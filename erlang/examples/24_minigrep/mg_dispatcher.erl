%% ============================================================
%% mg_dispatcher —— gen_server：分派文件给 worker 池，聚合结果
%%
%% 请求-响应用了 15 章的「先干活后回」形态：
%% handle_call 返回 {noreply, State} 并记下 From，
%% 全部 worker 结束时用 gen_server:reply/2 回复。
%%
%% worker 池：min(cap, 剩余文件) 个并发，DOWN 一个补一个（回合制）。
%% cap 从 application env 读（init 快照，17 章）。
%% ============================================================
-module(mg_dispatcher).

-behaviour(gen_server).

%% API
-export([start_link/0, grep/2]).
%% 回调
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2]).

-define(SERVER, ?MODULE).
-define(GREP_TIMEOUT, 30000).

%% ------------------------------------------------------------
%% API
%% ------------------------------------------------------------
start_link() ->
    gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%% 同步 grep：等全部 worker 扫完，返回按文件路径排序的结果
grep(Files, Pattern) when is_list(Files), is_binary(Pattern) ->
    gen_server:call(?SERVER, {grep, Files, Pattern}, ?GREP_TIMEOUT).

%% ------------------------------------------------------------
%% 回调
%% ------------------------------------------------------------
init([]) ->
    %% env 快照：进程起来时读一次（改了要重启才生效）
    Cap = application:get_env(mg, max_workers, 4),
    {ok, #{phase => idle, cap => Cap}}.

handle_call({grep, Files, Pattern}, From, #{phase := idle} = State) ->
    %% 第一回合：起 min(cap, 文件数) 个 worker
    Cap = maps:get(cap, State),
    {First, Rest} = split_at(Cap, Files),
    Running = spawn_workers(First, Pattern),
    {noreply, State#{phase := busy,
                     from => From,
                     pattern => Pattern,
                     remaining => Rest,
                     running => Running,      %% Pid => File
                     done => #{},             %% Pid => 已收到的结果
                     results => []}};         %% 未排序的 {File, Result}
handle_call(_Req, _From, State) ->
    {reply, {error, busy}, State}.      %% 上一轮还在跑：简单拒绝（演示够用）

handle_cast(_Req, State) ->
    {noreply, State}.

%% worker 结果：先于 DOWN 到达（同一发送者 FIFO + 死亡在发送之后）
handle_info({worker_done, Pid, Result}, State) ->
    {noreply, store_result(Pid, Result, State)};
%% worker 结束（正常或崩溃）：补员或收工
handle_info({'DOWN', _Ref, process, Pid, _Reason}, State) ->
    {noreply, worker_down(Pid, State)};
handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

%% ------------------------------------------------------------
%% worker 管理
%% ------------------------------------------------------------
spawn_workers([], _Pattern) -> #{};
spawn_workers(Files, Pattern) ->
    maps:from_list([{spawn_worker(File, Pattern), File} || File <- Files]).

spawn_worker(File, Pattern) ->
    Self = self(),
    Pid = spawn(fun() ->
                        Result = mg_worker:scan_file(File, Pattern),
                        Self ! {worker_done, self(), Result}
                end),
    _ = erlang:monitor(process, Pid),
    Pid.

store_result(Pid, Result, State) ->
    %% 结果先到、DOWN 后到：把结果挂在 done 里，DOWN 时取走
    Done = maps:get(done, State, #{}),
    State#{done => Done#{Pid => Result}}.

worker_down(Pid, State = #{running := Running, remaining := Remaining,
                           results := Acc, from := From, pattern := Pattern,
                           cap := Cap}) ->
    case maps:take(Pid, Running) of
        {File, StillRunning} ->
            %% done 里有结果就取走，配上下文里的 File；没有 = 崩了没交结果
            Acc1 = case maps:take(Pid, maps:get(done, State, #{})) of
                       {Result, _Done2} -> [{File, Result} | Acc];
                       error -> [{File, {error, worker_crashed}} | Acc]
                   end,
            case {maps:size(StillRunning), Remaining} of
                {0, []} ->
                    %% 全部结束：排序、回复、回到 idle
                    gen_server:reply(From, {ok, lists:sort(Acc1)}),
                    State#{phase => idle, results => [], done => #{}};
                {0, More} ->
                    %% 回合空了但还有文件：补一整轮
                    {First, Rest} = split_at(Cap, More),
                    State#{running => spawn_workers(First, Pattern),
                           remaining => Rest,
                           results => Acc1, done => #{}};
                {_, []} ->
                    State#{running => StillRunning, results => Acc1};
                {_, [NextFile | Rest]} ->
                    %% 还有名额：从剩余里补一个
                    NewPid = spawn_worker(NextFile, Pattern),
                    State#{running => StillRunning#{NewPid => NextFile},
                           remaining => Rest,
                           results => Acc1}
            end;
        error ->
            State    %% 不认识的 DOWN（不该发生）：忽略
    end.

split_at(N, L) when N >= length(L) -> {L, []};
split_at(N, L) -> lists:split(N, L).
