%% ============================================================
%% mg_sup —— 顶层监督者：one_for_one，孩子只有 dispatcher
%%
%% worker 池由 dispatcher 动态 spawn+monitor（13 章的 pmap 思路），
%% 不进监督树：worker 是无状态的一次性进程，崩了由本轮回合的
%% DOWN 处理记为 crashed，不需要重启语义。
%% ============================================================
-module(mg_sup).

-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    SupFlags = #{strategy => one_for_one, intensity => 3, period => 5},
    Children = [#{id => mg_dispatcher,
                  start => {mg_dispatcher, start_link, []},
                  restart => permanent,
                  shutdown => 5000,
                  type => worker,
                  modules => [mg_dispatcher]}],
    {ok, {SupFlags, Children}}.
