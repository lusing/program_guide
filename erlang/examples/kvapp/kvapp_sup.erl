%% ============================================================
%% kvapp_sup —— 应用的顶层监督者
%%
%% 规矩：**一个应用只应该有一个顶层监督者**（由 start/2 启动）。
%% 它下面挂的是本应用的进程树；应用之间的依赖交给 `applications` 字段，
%% 不要自己手动去 start 别的应用的进程。
%% ============================================================
-module(kvapp_sup).

-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    %% 注册名用模块名（也就是应用名 + _sup，这是 OTP 的惯例）
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    %% 监督者自己的策略：一个孩子挂了只重启它自己；
    %% 5 秒内超过 3 次就放弃（自己终止，并连带把整个应用拖下去）。
    SupFlags = #{strategy => one_for_one,
                 intensity => 3,
                 period => 5},
    Child = #{id => kvapp_store,
              start => {kvapp_store, start_link, []},
              restart => permanent,
              shutdown => 5000,
              type => worker,
              modules => [kvapp_store]},
    {ok, {SupFlags, [Child]}}.
