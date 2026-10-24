%% ============================================================
%% 27_ports 的 EUnit 测试
%%
%%   escript 源码由模块在运行时落到 build/27_ports，测试直接复用。
%%
%%   erlc -Werror -Wall -o build/27_ports examples/27_ports/*_tests.erl
%%   erl -noshell -pa build/27_ports -eval "eunit:test('27_ports_tests'), halt()."
%% ============================================================
-module('27_ports_tests').

-include_lib("eunit/include/eunit.hrl").

open_good() ->
    Path = '27_ports':write_escript("echo_port_t.escript", '27_ports':echo_source()),
    '27_ports':open_echo_port(Path).

roundtrip_test() ->
    Port = open_good(),
    try
        ?assertEqual({0, <<"hello">>}, '27_ports':call(Port, <<"hello">>)),
        ?assertEqual({1, <<1, 2, 3>>}, '27_ports':call(Port, <<1, 2, 3>>)),
        ?assertEqual({2, <<"中文"/utf8>>},
                     '27_ports':call(Port, unicode:characters_to_binary("中文")))
    after
        try port_close(Port) catch error:_ -> ok end
    end.

%% 忘了 binary+latin1 的坏版本：ASCII 能过，非 ASCII 一来就崩
bad_version_crash_test() ->
    Path = '27_ports':write_escript("bad_echo_port_t.escript",
                                    '27_ports':bad_echo_source()),
    Port = '27_ports':open_echo_port(Path),
    try
        ?assertEqual({0, <<"ascii">>}, '27_ports':call(Port, <<"ascii">>)),
        Port ! {self(), {command, unicode:characters_to_binary("中文")}},
        receive {Port, {exit_status, S}} -> ?assert(S =/= 0)
        after 3000 -> error(exit_status_missing)
        end,
        %% 死端口再 close 抛 badarg
        try port_close(Port), error(unexpected_ok)
        catch error:badarg -> ok
        end
    after
        try port_close(Port) catch error:_ -> ok end
    end.

escript_written_test() ->
    Path = '27_ports':write_escript("probe_t.escript", '27_ports':echo_source()),
    ?assertEqual(true, filelib:is_file(Path)),

    %% 好版本的源码里要有 binary+latin1 的 setopts（自检）
    {ok, Bin} = file:read_file(Path),
    ?assertMatch({_Pos, 6}, binary:match(Bin, <<"latin1">>)),
    ok.

%% ---------------- argparse（教程 27.6） ----------------
%% 注意：这里只测纯函数 argparse:parse/2——run/3 出错路径直接 halt(1)，
%% 会把整个测试 VM 带走。

argparse_parse_ok_test() ->
    Cli = '27_ports':mul_cli(),
    %% 成功：{ok, 参数 map, 命令路径, 原规格}——type 已自动转 integer
    {ok, M, ["mul"], Cli} = argparse:parse(["3", "4", "-v"], Cli, #{progname => mul}),
    ?assertEqual(#{left => 3, right => 4, verbose => true}, M),
    %% 不给 -v 落 default；长选项 --verbose 与 -v 等价
    {ok, M2, _, _} = argparse:parse(["1", "2"], Cli, #{progname => mul}),
    ?assertEqual(false, maps:get(verbose, M2)),
    {ok, M3, _, _} = argparse:parse(["1", "2", "--verbose"], Cli, #{progname => mul}),
    ?assertEqual(true, maps:get(verbose, M3)).

argparse_missing_arg_test() ->
    %% 缺必需参数：{error, {命令路径, 出错的参数规格, 原始输入, 原因}}
    {error, {Path, ArgSpec, undefined, <<>>}} =
        argparse:parse(["1"], '27_ports':mul_cli(), #{progname => mul}),
    ?assertEqual(["mul"], Path),
    ?assertEqual(right, maps:get(name, ArgSpec)),
    %% format_error 返回 io_lib 格式，flatten 后是人话
    ?assertEqual("mul: required argument missing: right",
                 lists:flatten(argparse:format_error({Path, ArgSpec, undefined, <<>>}))).

argparse_type_error_test() ->
    %% 类型转不过去也是 {error, 四元组}；信息里含 "is not an integer"
    {error, Err} = argparse:parse(["1", "x"], '27_ports':mul_cli(), #{progname => mul}),
    Msg = unicode:characters_to_binary(argparse:format_error(Err)),
    ?assertMatch({_Pos, 17}, binary:match(Msg, <<"is not an integer">>)).

argparse_subcommand_test() ->
    Git = '27_ports':git_cli(),
    %% 子命令：parse 结果第二元是命令路径
    {ok, #{file := "a.txt"}, ["git", "add"], _} =
        argparse:parse(["add", "a.txt"], Git, #{progname => git}),
    %% 长选项支持 = 赋值
    {ok, #{m := "init"}, ["git", "commit"], _} =
        argparse:parse(["commit", "--message=init"], Git, #{progname => git}),
    %% 未知子命令同样是 {error, 四元组}，不抛异常
    {error, {["git"], undefined, "bogus", <<>>}} =
        argparse:parse(["bogus"], Git, #{progname => git}),
    ok.

argparse_help_test() ->
    %% help 免费：按规格自动生成 usage 文本
    Help = unicode:characters_to_binary(argparse:help('27_ports':mul_cli(), #{progname => mul})),
    ?assertMatch({_P1, 6}, binary:match(Help, <<"Usage:">>)),
    ?assertMatch({_P2, 6}, binary:match(Help, <<"<left>">>)),
    ok.
