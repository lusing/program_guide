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
-include_lib("stdlib/include/zip.hrl").

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

json_test() ->
    %% encode 返回 iodata（坑），要平面二进制自己 iolist_to_binary
    Enc = json:encode(#{name => <<"erlang">>, tags => [a, b], n => 42}),
    ?assertNot(is_binary(Enc)),
    %% map 键的输出顺序 OTP 不保证：按内容断言，不断言字节级顺序
    ?assertEqual(#{<<"name">> => <<"erlang">>, <<"n">> => 42,
                   <<"tags">> => [<<"a">>, <<"b">>]},
                 json:decode(iolist_to_binary(Enc))),
    %% decode：对象 → map，键一律是 binary；null → 原子 null
    ?assertEqual(#{<<"a">> => 1, <<"b">> => [true, null], <<"c">> => <<"x">>},
                 json:decode(<<"{\"a\":1,\"b\":[true,null],\"c\":\"x\"}">>)),
    %% [{a,1}] 不能直接 encode，要用 encode_key_value_list
    ?assertError({unsupported_type, {a, 1}}, json:encode([{a, 1}])),
    ?assertEqual(<<"{\"a\":1,\"b\":2}">>,
                 iolist_to_binary(json:encode_key_value_list(
                                    [{a, 1}, {b, 2}], fun json:encode_value/2))),
    %% 非法输入抛 error 的三种形态
    ?assertError(unexpected_end, json:decode(<<"{\"a\":">>)),
    ?assertError({invalid_byte, $!}, json:decode(<<"{\"a\":!}">>)),
    ?assertError({unexpected_sequence, <<"\\uZZZZ">>},
                 json:decode(<<"\"\\uZZZZ\"">>)),
    %% json:format（OTP 27.1）美化输出
    ?assertEqual(<<"{\n  \"a\": 1,\n  \"b\": [1,2]\n}\n">>,
                 iolist_to_binary(json:format(#{a => 1, b => [1, 2]}))).

base64_test() ->
    ?assertEqual(<<"aGVsbG8=">>, base64:encode(<<"hello">>)),
    ?assert(is_binary(base64:encode(<<"hello">>))),
    ?assertEqual("aGVsbG8=", base64:encode_to_string(<<"hello">>)),
    ?assertEqual(<<"hello">>, base64:decode(<<"aGVsbG8=">>)),
    %% mime_decode 容忍 \r\n
    ?assertEqual(<<"hello">>, base64:mime_decode(<<"aGVs\r\nbG8=">>)),
    %% 非法输入抛错，不返回元组
    ?assertError(missing_padding, base64:decode(<<"!!!">>)),
    %% 模块只提供 MIME 方向的解码，没有 mime_encode
    ?assertNot(erlang:function_exported(base64, mime_encode, 1)).

zstd_test() ->
    Data = binary:copy(<<"abcdef">>, 100),
    ?assertEqual(600, byte_size(Data)),
    C = zstd:compress(Data),
    %% compress 返回 iodata（坑）：直接 byte_size 会 badarg
    ?assertNot(is_binary(C)),
    ?assertError(badarg, byte_size(C)),
    CB = iolist_to_binary(C),
    ?assertEqual(23, byte_size(CB)),
    %% compressionLevel 用 map 传
    C20 = iolist_to_binary(zstd:compress(Data, #{compressionLevel => 20})),
    ?assertEqual(23, byte_size(C20)),
    %% decompress 返回的也是 iodata，roundtrip 完全还原
    D = zstd:decompress(CB),
    ?assertNot(is_binary(D)),
    ?assertEqual(Data, iolist_to_binary(D)),
    ?assertEqual(Data, iolist_to_binary(zstd:decompress(C20))).

archive_test() ->
    cleanup_dir(),
    ok = file:make_dir(?DIR),
    Assets = filename:join(?DIR, "assets"),
    ok = file:make_dir(Assets),
    ok = file:write_file(filename:join(Assets, "a.txt"), <<"AAA">>),
    ok = file:write_file(filename:join(Assets, "b.txt"), <<"BBB">>),
    %% zip：{cwd, Dir} 让裸文件名相对指定目录
    Zip = filename:join(?DIR, "demo.zip"),
    ?assertEqual({ok, Zip}, zip:create(Zip, ["a.txt", "b.txt"], [{cwd, Assets}])),
    %% [memory] 解包直接拿内容不落盘
    ?assertEqual({ok, [{"a.txt", <<"AAA">>}, {"b.txt", <<"BBB">>}]},
                 zip:extract(Zip, [memory])),
    {ok, Entries} = zip:table(Zip),
    ?assertEqual(["a.txt", "b.txt"], [N || #zip_file{name = N} <- Entries]),
    %% erl_tar 没有 cwd 选项：裸文件名只认当前目录
    ?assertEqual({error, {"a.txt", enoent}},
                 erl_tar:create(filename:join(?DIR, "cwd.tar"), ["a.txt"],
                                [{cwd, Assets}])),
    %% 跨目录用 {归档内名字, 磁盘路径} 元组（名字在前）
    Tar = filename:join(?DIR, "demo.tar"),
    ?assertEqual(ok, erl_tar:create(Tar, [{"a.txt", filename:join(Assets, "a.txt")},
                                          {"b.txt", filename:join(Assets, "b.txt")}])),
    ?assertEqual({ok, [{"a.txt", <<"AAA">>}, {"b.txt", <<"BBB">>}]},
                 erl_tar:extract(Tar, [memory])),
    %% 元组顺序写反 → enoent
    ?assertEqual({error, {"a.txt", enoent}},
                 erl_tar:create(filename:join(?DIR, "bad.tar"),
                                [{filename:join(Assets, "a.txt"), "a.txt"}])),
    %% compressed 直接产 .tar.gz；解的时候也要给 compressed
    Gz = filename:join(?DIR, "demo.tar.gz"),
    ?assertEqual(ok, erl_tar:create(Gz, [{"a.txt", filename:join(Assets, "a.txt")}],
                                    [compressed])),
    {ok, GzBin} = file:read_file(Gz),
    ?assertEqual(<<31, 139>>, binary:part(GzBin, 0, 2)),
    ?assertEqual({ok, [{"a.txt", <<"AAA">>}]},
                 erl_tar:extract(Gz, [memory, compressed])),
    cleanup_dir().

file_sorter_test() ->
    cleanup_dir(),
    ok = file:make_dir(?DIR),
    Terms = filename:join(?DIR, "terms.txt"),
    ok = file:write_file(Terms, [io_lib:format("~p.~n", [T]) || T <- [{c, 3}, {a, 1}, {b, 2}]]),
    %% Input 必须是文件名列表：裸字符串被拆成码点，撞上路径首字符（这里是 $/）
    AbsTerms = filename:absname(Terms),
    First = hd(AbsTerms),
    ?assertError({badarg, First},
                 file_sorter:sort(AbsTerms, filename:join(?DIR, "never.txt"),
                                  [{format, term}])),
    %% 正确写法：单个文件名也包一层列表
    Sorted = filename:join(?DIR, "sorted.txt"),
    ?assertEqual(ok, file_sorter:sort([Terms], Sorted, [{format, term}])),
    ?assertEqual({ok, [{a, 1}, {b, 2}, {c, 3}]}, file:consult(Sorted)),
    %% keysort(2, ...) 按 element(2) 排，与整体排序结果不同
    KTerms = filename:join(?DIR, "kterms.txt"),
    ok = file:write_file(KTerms, [io_lib:format("~p.~n", [T]) || T <- [{x, 3}, {y, 1}, {z, 2}]]),
    Ks = filename:join(?DIR, "ks.txt"),
    ?assertEqual(ok, file_sorter:keysort(2, [KTerms], Ks, [{format, term}])),
    ?assertEqual({ok, [{y, 1}, {z, 2}, {x, 3}]}, file:consult(Ks)),
    cleanup_dir().
