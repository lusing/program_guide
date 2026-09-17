%% 语料文件 2：藏在子目录里（验证递归遍历不漏）
-module(beta).
-export([start/1]).

start(N) ->
    [spawn(fun beta_task/0) || _ <- lists:seq(1, N)].

beta_task() -> ok.
%% no keyword here.
