%% ============================================================
%% 19_files 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/19_files examples/19_files/*_tests.erl
%%   erl -noshell -pa build/19_files -eval "eunit:test('19_files_tests'), halt()."
%%
%% 文件类测试用 build/eunit-19 作为沙箱目录，setup/cleanup 兜底清理。
%% ============================================================
-module('19_files_tests').

-include_lib("eunit/include/eunit.hrl").

-define(DIR, "build/eunit-19").

cleanup_dir() -> _ = file:del_dir_r(?DIR), ok.

whole_file_io_test() ->
    cleanup_dir(),
    ok = file:make_dir(?DIR),
    F = filename:join(?DIR, "one.txt"),
    ok = file:write_file(F, <<"hello">>),
    ?assertEqual({ok, <<"hello">>}, file:read_file(F)),
    %% 读不存在的文件返回 error 元组，不抛
    ?assertMatch({error, enoent}, file:read_file(filename:join(?DIR, "nope.txt"))),
    %% iodata 深嵌套写入
    ok = file:write_file(F, ["ab", ["cd", <<"ef">>], "g"]),
    ?assertEqual({ok, <<"abcdefg">>}, file:read_file(F)),
    %% append 才不截断
    ok = file:write_file(F, <<"!">>, [append]),
    ?assertEqual({ok, <<"abcdefg!">>}, file:read_file(F)),
    cleanup_dir().

encoding_trap_test() ->
    cleanup_dir(),
    ok = file:make_dir(?DIR),
    F = filename:join(?DIR, "enc.txt"),
    %% 中文码点 > 255：write_file 返回 {error,badarg}（不抛）
    ?assertMatch({error, badarg}, file:write_file(F, "你好")),
    %% 正确写法：/utf8 二进制或 unicode:characters_to_binary
    ok = file:write_file(F, <<"你好"/utf8>>),
    ?assertEqual(6, byte_size(element(2, file:read_file(F)))),
    %% encoding 选项对 write_file 无效（也不报错，静默忽略）
    ?assertMatch({error, badarg},
                 file:write_file(F, "你好", [{encoding, utf8}])),
    cleanup_dir().

streaming_test() ->
    cleanup_dir(),
    ok = file:make_dir(?DIR),
    F = filename:join(?DIR, "stream.txt"),
    ok = file:write_file(F, <<"abcdefg">>),
    {ok, Fd} = file:open(F, [read, binary]),
    ?assertEqual({ok, <<"abc">>}, file:read(Fd, 3)),
    %% pread 定位读——本机实测**会**把偏移移到 pread 结束处（macOS 不动）
    ?assertEqual({ok, <<"ab">>}, file:pread(Fd, 0, 2)),
    ?assertEqual({ok, 2}, file:position(Fd, cur)),
    %% 超过长度给剩下的；再读才是 eof
    ?assertEqual({ok, <<"cdefg">>}, file:read(Fd, 100)),
    ?assertEqual(eof, file:read(Fd, 1)),
    ok = file:close(Fd),
    %% 关掉之后句柄 terminated
    ?assertMatch({error, terminated}, file:read(Fd, 1)),
    cleanup_dir().

protocol_roundtrip_test() ->
    Pkt = '19_files':encode(1, 7, <<"hello">>),
    %% 头 2+1+1+2 = 6 字节 + 5 payload + 4 crc = 15
    ?assertEqual(15, byte_size(Pkt)),
    ?assertMatch({ok, #{ver := 1, type := 7, payload := <<"hello">>}},
                 '19_files':decode(Pkt)),
    ?assertMatch({ok, #{payload := <<>>}}, '19_files':decode('19_files':encode(1, 0, <<>>))),
    %% 解不开的四种情况都显式返回 error
    ?assertEqual({error, bad_magic}, '19_files':decode(<<0, 0, 1, 7, 0, 1, 0>>)),
    ?assertEqual({error, truncated},
                 '19_files':decode(<<16#45, 16#52, 1, 7, 0, 5, $h>>)),
    ?assertEqual({error, crc_mismatch},
                 '19_files':decode(<<16#45, 16#52, 1, 7, 0, 5,
                                     $h, $e, $l, $l, $x, 0, 0, 0, 0>>)).

term_serialization_test() ->
    T = {user, <<"张三"/utf8>>, 30, #{tags => [a, b]}},
    B = term_to_binary(T),
    %% 外部格式首字节固定 131
    ?assertEqual(131, binary:at(B, 0)),
    ?assert(binary_to_term(B) =:= T),
    %% 压缩对长列表明显；对很短的数据实测**持平**（OTP 29 / 本机）
    Big = lists:seq(1, 20000),
    ?assert(byte_size(term_to_binary(Big, [{compressed, 9}]))
            < byte_size(term_to_binary(Big))),
    ?assertEqual(byte_size(term_to_binary({a})),
                 byte_size(term_to_binary({a}, [{compressed, 9}]))),
    %% [safe] 拦住「会创建新原子」的不可信输入
    ?assertException(error, _, binary_to_term(unknown_atom_ext(), [safe])),
    ?assertException(error, _, binary_to_term(<<0, 1, 2, 3>>)).

%% 手工拼外部格式里的原子（131 版本号，100 ATOM_EXT，16 位长度 + 字节）
unknown_atom_ext() ->
    Name = "zz_atom_that_does_not_exist_yet",
    <<131, 100, (length(Name)):16, (list_to_binary(Name))/binary>>.
