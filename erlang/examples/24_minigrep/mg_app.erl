%% ============================================================
%% mg_app —— application 回调：整个 grep 服务的入口
%%
%% start/2 返回顶层监督者；prep_stop/stop 演示关闭顺序（17 章）。
%% ============================================================
-module(mg_app).

-behaviour(application).

-export([start/2, prep_stop/1, stop/1]).

start(_StartType, _StartArgs) ->
    %% 返回 {ok, 顶层监督者 pid}——一个应用只应该有一个顶层监督者
    mg_sup:start_link().

prep_stop(_State) ->
    %% 关监督树**之前**的最后机会（本服务无状态要保存，打点日志即可）
    io:format("[mg_app] prep_stop~n"),
    ok.

stop(_State) ->
    %% 树已经关完了，只能收尾
    io:format("[mg_app] stop~n"),
    ok.
