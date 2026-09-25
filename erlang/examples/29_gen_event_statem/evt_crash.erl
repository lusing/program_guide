%% ============================================================
%% evt_crash —— gen_event 处理器：收到 {die, _} 故意崩溃
%%
%%   教学用：崩溃的 handler 被 manager 摘掉，其他 handler 无恙。
%%   （注意它没实现 terminate 带状态走——崩溃路径本来也不走 terminate）
%% ============================================================
-module(evt_crash).

-behaviour(gen_event).

-export([init/1, handle_event/2, handle_call/2, handle_info/2,
         terminate/2, code_change/3]).

init(_) -> {ok, []}.

handle_event({die, Reason}, _State) -> error({handler_died, Reason});
handle_event(_Other, State) -> {ok, State}.

handle_call(_Request, State) -> {ok, ok, State}.

handle_info(_Info, State) -> {ok, State}.

terminate(_Args, _State) -> ok.

code_change(_OldVsn, State, _Extra) -> {ok, State}.
