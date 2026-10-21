%% ============================================================
%% 16_auto_shutdown_sup —— auto_shutdown / hibernate_after 演示用的
%% 通用 supervisor 回调。
%%
%%    与主模块 '16_supervisor' 的 init/1（固定五元组参数、固定孩子清单）
%%    分开：这个模块把调用方给的 sup flags 和 child specs **原样透传**，
%%    给什么策略/标志/孩子就声明什么，方便演示各种 sup flags 组合。
%% ============================================================
-module('16_auto_shutdown_sup').

-behaviour(supervisor).

-export([init/1]).

init({Flags, Children}) ->
    {ok, {Flags, Children}}.
