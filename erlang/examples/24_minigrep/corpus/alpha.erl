%% 语料文件 1：示例运行时 grep 的目标（含多个 spawn 命中）
-module(alpha).
-export([run/0]).

run() ->
    Pid = spawn(fun worker/0),
    %% spawn 一个再 spawn 一个——同一行多个命中只算一行
    Pid2 = spawn(fun worker/0),
    [P ! go || P <- [Pid, Pid2]].

worker() -> receive go -> ok end.
%% 这里没有关键词。
