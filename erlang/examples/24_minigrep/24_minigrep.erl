%% ============================================================
%% 24_minigrep —— 实战：带监督树和 worker 池的 mini-grep
%%
%%    把 15–17 章（gen_server / supervisor / application）、13 章
%%    （进程 + monitor + 按 Ref/结果聚合）、19 章（文件）、08 章
%%    （二进制匹配）组装成一个完整服务：
%%
%%        mg.app          应用资源文件（env 里有 max_workers）
%%        mg_app.erl      application 回调
%%        mg_sup.erl      顶层监督者（one_for_one：dispatcher）
%%        mg_dispatcher.erl  gen_server：分派 + 聚合（先干活后回）
%%        mg_worker.erl   worker：单文件扫描（纯函数可测）
%%
%%    目录递归遍历自己写（filelib:wildcard 不递归、不跨分隔符）。
%%    输出按 (文件路径, 行号) 排序——worker 完成顺序是乱的，聚合时排序去随机。
%%
%% 编译：
%%   erlc +debug_info -Werror -Wall -o build/24_minigrep examples/24_minigrep/*.erl
%%   copy examples\24_minigrep\mg.app build\24_minigrep\     ← .app 要手工拷
%% 运行（在本目录下）：
%%   erl -noshell -pa build/24_minigrep -run '24_minigrep' main spawn corpus -s init stop
%% 测试：
%%   erl -noshell -pa build/24_minigrep -eval "eunit:test('24_minigrep_tests'), halt()."
%% ============================================================
-module('24_minigrep').

-export([main/1, walk/1, format_matches/1]).

main([]) ->
    io:format("用法: erl -noshell -pa build/24_minigrep "
              "-run '24_minigrep' main <模式> <目录> -s init stop~n"),
    io:format("~n==== 24 结束 ====~n");
main([Pattern, Dir | _]) ->
    _ = logger:remove_handler(default),
    {ok, _Started} = application:ensure_all_started(mg),
    Files = walk(Dir),
    io:format("扫描 ~p 个文件，找含 \"~ts\" 的行：~n", [length(Files), Pattern]),
    {ok, Results} = mg_dispatcher:grep(Files, unicode:characters_to_binary(Pattern)),
    print_matches(Results),
    Total = lists:sum([count_hits(R) || R <- Results]),
    HitFiles = length([R || R <- Results, count_hits(R) > 0]),
    io:format("共 ~p 处命中，分布在 ~p 个文件里。~n", [Total, HitFiles]),
    ok = application:stop(mg),
    io:format("~n==== 24 结束 ====~n").

%% ------------------------------------------------------------
%% 递归列出目录下全部文件（排序保证确定顺序；wildcard 不递归）
%% ------------------------------------------------------------
walk(Dir) ->
    case file:list_dir(Dir) of
        {ok, Names} ->
            lists:append([entry(filename:join(Dir, N)) || N <- lists:sort(Names)]);
        {error, _R} ->
            []
    end.

entry(Path) ->
    case filelib:is_dir(Path) of
        true  -> walk(Path);
        false -> [Path]
    end.

%% ------------------------------------------------------------
%% 输出
%% ------------------------------------------------------------
print_matches(Results) ->
    [io:format("  ~ts~n", [Line]) || Line <- format_matches(Results)].

format_matches(Results) ->
    [io_lib:format("~ts:~p: ~ts", [File, No, Text])
     || {File, {ok, Lines}} <- Results, {No, Text} <- Lines]
    ++ [io_lib:format("~ts: <读不了: ~p>", [File, R])
        || {File, {error, R}} <- Results].

count_hits({_File, {ok, Lines}}) -> length(Lines);
count_hits({_File, {error, _}}) -> 0.
