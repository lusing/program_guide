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
