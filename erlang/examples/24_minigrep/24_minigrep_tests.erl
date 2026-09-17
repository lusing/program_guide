%% ============================================================
%% 24_minigrep 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/24_minigrep examples/24_minigrep/*.erl
%%   erl -noshell -pa build/24_minigrep -eval "eunit:test('24_minigrep_tests'), halt()."
%%
%% 语料用 fixture 现场造（build/eunit-24-corpus/），不依赖仓库相对路径。
%% ============================================================
-module('24_minigrep_tests').

-include_lib("eunit/include/eunit.hrl").

-define(DIR, "build/eunit-24-corpus").
-define(PAT, <<"spawn">>).

make_corpus() ->
    _ = file:del_dir_r(?DIR),
    ok = filelib:ensure_dir(filename:join(?DIR, "sub/x")),
    ok = file:write_file(filename:join(?DIR, "a.txt"),
                         <<"no hit here\nspawn me\nspawn you too\nplain\n">>),
    ok = file:write_file(filename:join(?DIR, "b.txt"),
                         <<"nothing relevant\n">>),
    ok = file:write_file(filename:join(?DIR, "sub/c.txt"),
                         <<"deep spawn\nlast line\n">>).

%% ---------- worker（纯函数层） ----------

scan_file_test() ->
    make_corpus(),
    {ok, [{2, <<"spawn me">>}, {3, <<"spawn you too">>}]} =
        mg_worker:scan_file(filename:join(?DIR, "a.txt"), ?PAT),
    {ok, []} = mg_worker:scan_file(filename:join(?DIR, "b.txt"), ?PAT),
    {error, {unreadable, enoent}} =
        mg_worker:scan_file(filename:join(?DIR, "nope.txt"), ?PAT),
    _ = file:del_dir_r(?DIR).

crlf_strip_test() ->
    %% Windows CRLF 的行尾 \r 剥掉再比对
    F = "build/eunit-24-crlf.txt",
    ok = file:write_file(F, <<"win spawn\r\n">>),
    {ok, [{1, <<"win spawn">>}]} = mg_worker:scan_file(F, ?PAT),
    ok = file:delete(F).

%% ---------- 目录遍历（CLI 层） ----------

walk_test() ->
    make_corpus(),
    Files = '24_minigrep':walk(?DIR),
    %% 排序确定：a.txt、b.txt 在前，sub/c.txt 在后（子目录按名序排在其后）
    ?assertEqual([filename:join(?DIR, "a.txt"),
                  filename:join(?DIR, "b.txt"),
                  filename:join([?DIR, "sub", "c.txt"])], Files),
    _ = file:del_dir_r(?DIR).

walk_missing_dir_test() ->
    ?assertEqual([], '24_minigrep':walk("build/no-such-dir-xyz")).

format_test() ->
    Lines = '24_minigrep':format_matches(
              [{<<"f.txt">>, {ok, [{3, <<"hi spawn">>}]}},
               {<<"g.txt">>, {error, {unreadable, eacces}}}]),
    %% 期望值必须从**列表**字面量转（unicode:characters_to_binary）——
    %% 直接写 <<"...读不了...">> 会被 latin1 截断成错误字节（09 章头号坑，
    %% 本教程自己的测试就踩了一次，实测 <<读不了>> → <<251,13,134>>）
    ?assertEqual([<<"f.txt:3: hi spawn">>,
                  unicode:characters_to_binary("g.txt: <读不了: {unreadable,eacces}>")],
                 [unicode:characters_to_binary(L) || L <- Lines]).

%% ---------- 集成：整棵监督树 + worker 池 ----------

dispatcher_pool_test() ->
    make_corpus(),
    _ = logger:remove_handler(default),
    Old = process_flag(trap_exit, true),
    {ok, _} = application:ensure_all_started(mg),
    ?assert(is_pid(whereis(mg_dispatcher))),
    Files = '24_minigrep':walk(?DIR),
    ?assertMatch({ok, [{_, {ok, [{2, _}, {3, _}]}},
                       {_, {ok, []}},
                       {_, {ok, [{1, _}]}}]},
                 mg_dispatcher:grep(Files, ?PAT)),
    %% env 快照：max_workers 默认 4，能从 application env 读到
    ?assertEqual(4, application:get_env(mg, max_workers, undefined)),
    ok = application:stop(mg),
    _ = process_flag(trap_exit, Old),
    _ = file:del_dir_r(?DIR).

pool_more_files_than_workers_test() ->
    %% 造 10 个文件（> max_workers=4）：回合制补员也要全部扫到
    _ = file:del_dir_r(?DIR),
    ok = filelib:ensure_dir(filename:join(?DIR, "x")),
    [ok = file:write_file(filename:join(?DIR, "f" ++ integer_to_list(N) ++ ".txt"),
                          [<<"line\n">> || _ <- lists:seq(1, N)] ++ [<<"spawn\n">>])
     || N <- lists:seq(1, 10)],
    _ = logger:remove_handler(default),
    Old = process_flag(trap_exit, true),
    {ok, _} = application:ensure_all_started(mg),
    Files = '24_minigrep':walk(?DIR),
    ?assertEqual(10, length(Files)),
    {ok, Results} = mg_dispatcher:grep(Files, ?PAT),
    %% 每个文件恰好一行命中（最后一行）——一个都不能少
    ?assertEqual(10, length([R || {_, {ok, [_ | _]}} = R <- Results])),
    ok = application:stop(mg),
    _ = process_flag(trap_exit, Old),
    _ = file:del_dir_r(?DIR).
