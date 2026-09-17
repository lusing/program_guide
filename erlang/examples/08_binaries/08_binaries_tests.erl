%% ============================================================
%% 08_binaries 的 EUnit 测试
%%
%%   erlc -Werror -Wall -o build/08_binaries examples/08_binaries/*_tests.erl
%%   erl -noshell -pa build/08_binaries -eval "eunit:test('08_binaries_tests'), halt()."
%% ============================================================
-module('08_binaries_tests').

-include_lib("eunit/include/eunit.hrl").

build_test() ->
    ?assertEqual(<<1:8, 2:8>>, <<1, 2>>),
    ?assertEqual(<<16#12>>, <<1:4, 2:4>>),          %% 两个 4 位段拼一个字节
    ?assertEqual(3, bit_size(<<1:1, 0:1, 1:1>>)),   %% 位串可以不满整字节
    ?assertEqual(<<1, 2, 3, 4>>,
                 <<<<1, 2>>/binary, <<3, 4>>/binary>>).

len_prefixed_test() ->
    %% 位语法杀手锏：尺寸引用前面绑定的变量
    ?assertEqual({3, <<"abc">>, <<"tail">>},
                 '08_binaries':take_len_prefixed(<<3, "abc", "tail">>)),
    %% 长度声明超过实际数据 → function_clause（单子句函数没有匹配）
    ?assertException(error, function_clause,
                     '08_binaries':take_len_prefixed(<<5, "ab">>)).

byte_order_test() ->
    ?assertEqual(<<0, 1>>, <<1:16>>),               %% 默认大端
    ?assertEqual(<<1, 0>>, <<1:16/little>>),
    ?assertEqual(-1, '08_binaries':as_signed(<<255>>)),
    ?assertEqual(255, '08_binaries':as_unsigned(<<255>>)),
    ?assertEqual(1.0, '08_binaries':as_double(<<63, 240, 0, 0, 0, 0, 0, 0>>)).

tlv_test() ->
    Tlv = '08_binaries':encode_tlv(1, <<"hello">>),
    ?assertEqual(<<1, 0, 5, "hello">>, Tlv),
    ?assertEqual({ok, {1, <<"hello">>}, <<>>}, '08_binaries':parse_tlv(Tlv)),
    %% 输入共 5 字节（1 类型 + 2 长度 + 2 数据），负载不够 → incomplete 报总长
    ?assertEqual({incomplete, 5}, '08_binaries':parse_tlv(<<1, 0, 5, "ab">>)).

utf8_decoder_test() ->
    %% 手工位级解码与标准库结果一致
    ?assertEqual([{1, $A}, {3, 20013}],
                 '08_binaries':parse_utf8(<<"A中"/utf8>>)),
    ?assertEqual([C || <<C/utf8>> <= <<"A中"/utf8>>],
                 [CP || {_, CP} <- '08_binaries':parse_utf8(<<"A中"/utf8>>)]).

png_size_test() ->
    Png = <<137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, "IHDR",
            0, 0, 1, 128, 0, 0, 0, 96>>,
    ?assertEqual({ok, 384, 96}, '08_binaries':png_size(Png)),
    ?assertEqual({error, not_png}, '08_binaries':png_size(<<"junk">>)).

binary_module_test() ->
    B = <<1, 2, 3, 4, 5>>,
    ?assertEqual(2, binary:at(B, 1)),
    ?assertEqual(<<2, 3, 4>>, binary:part(B, 1, 3)),
    ?assertEqual([<<1, 2>>, <<3>>, <<4>>],
                 binary:split(<<1, 2, 0, 3, 0, 4>>, <<0>>, [global])),
    ?assertEqual([{1, 2}], binary:matches(<<1, 2, 3>>, <<2, 3>>)).
