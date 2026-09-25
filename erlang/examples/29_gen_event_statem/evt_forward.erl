%% ============================================================
%% evt_forward —— gen_event 处理器：把事件转发给一个 pid
%%
%%   init 的参数来自 add_handler 的第三个参数（在调用方进程求值，
%%   所以传 self() 拿到的是调用方 pid）。
%% ============================================================
-module(evt_forward).

-behaviour(gen_event).

-export([init/1, handle_event/2, handle_call/2, handle_info/2,
         terminate/2, code_change/3]).

init([Pid]) -> {ok, Pid}.

handle_event(Event, Pid) -> Pid ! {event, Event}, {ok, Pid}.

handle_call(_Request, Pid) -> {ok, ok, Pid}.

handle_info(_Info, Pid) -> {ok, Pid}.

terminate(_Args, _Pid) -> ok.

code_change(_OldVsn, Pid, _Extra) -> {ok, Pid}.
