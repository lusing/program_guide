%% ============================================================
%% 09 - 二进制与位语法
%%
%%    位语法（bit syntax）是 Erlang 处理二进制协议、文件格式、编码的
%%    核心工具。它能在**一次模式匹配**里完成「读长度 + 按长度取负载」，
%%    这是其它语言很难写出的表达力。
%%
%%    通式：<<Value:Size/Type-Signedness-Endianness-Unit>>
%%
%% 编译：
%%   erlc -Werror -Wall -o build examples/09-binaries.erl
%% 运行：
%%   erl -noshell -pa build -run '09-binaries' main -s init stop
%% ============================================================
-module('09-binaries').

-export([main/0, parse_tlv/1, encode_tlv/2, parse_utf8/1, png_size/1]).

main() ->
    building(),
    matching(),
    byte_order(),
    text_encodings(),
    binary_module(),
    real_world(),
    io:format("~n==== 09 结束 ====~n").

%% 1) 构造二进制
%% ------------------------------------------------------------
building() ->
    io:format("== 1) 构造 ==~n"),
    d("<<1, 2, 3>>", <<1, 2, 3>>),
    d("<<\"abc\">>", <<"abc">>),
    d("<<255>>（单字节，取值必须 0..255）", <<255>>),
    d("<<300:16>>（16 位存放 300）", <<300:16>>),
    d("<<1:4, 2:4>>（两段拼成一个字节）", <<1:4, 2:4>>),
    d("<<1:1, 0:1, 1:1>>（只占 3 位）", <<1:1, 0:1, 1:1>>),
    d("bit_size(<<1:1,0:1,1:1>>)", bit_size(<<1:1, 0:1, 1:1>>)),
    d("<<1:8, 2:8>> 与 <<1,2>> 相同", <<1:8, 2:8>> =:= <<1, 2>>),
    %% 拼接两段
    d("<<<<1,2>>/binary, <<3,4>>/binary>>", <<<<1, 2>>/binary, <<3, 4>>/binary>>),
    %% 大二进制用 /binary 拼能避免复制
    Big = binary:copy(<<"ab">>, 3),
    d("binary:copy(<<\"ab\">>, 3)", Big),
    ok.

%% 2) 匹配与解析
%% ------------------------------------------------------------
matching() ->
    io:format("~n== 2) 匹配与解析 ==~n"),
    d("<<A:8, B:8>> = <<7,8>>", take_two(<<7, 8>>)),
    d("<<H:16>> = <<1,0>>（大端）", take_u16(<<1, 0>>)),
    %% 尺寸可以引用前面绑定的变量 —— 位语法的杀手锏
    d("<<N:8, P:N/binary, T/binary>>（先读长度再读负载）",
      take_len_prefixed(<<3, "abc", "tail">>)),
    %% 匹配失败会抛 badmatch，不会静默
    d("长度声明比实际数据长（没有子句可匹配）", raises(fun take_len_prefixed/1, <<5, "ab">>)),
    %% 用 /binary 拿到剩余全部
    d("<<_:8, Rest/binary>>", skip_first(<<1, 2, 3>>)),
    %% ASCII 字面量可以直接写在模式里
    d("模式里的字面量 <<\"GET \", Path/binary>>", strip_get(<<"GET /index">>)),
    d("不是 GET 开头就落到兜底子句", strip_get(<<"POST /x">>)),
    ok.

take_two(<<A:8, B:8>>) -> {A, B}.
take_u16(<<H:16>>) -> H.
take_len_prefixed(<<N:8, P:N/binary, T/binary>>) -> {N, P, T}.
skip_first(<<_:8, Rest/binary>>) -> Rest.
strip_get(<<"GET ", Path/binary>>) -> {ok, Path};
strip_get(Other) -> {not_get, Other}.

%% 3) 字节序与符号
%% ------------------------------------------------------------
byte_order() ->
    io:format("~n== 3) 字节序与符号 ==~n"),
    d("<<1:16>>（默认 big）", <<1:16>>),
    d("<<1:16/big>>", <<1:16/big>>),
    d("<<1:16/little>>", <<1:16/little>>),
    d("<<1:16/native>>（随机器）", <<1:16/native>>),
    d("<<16#1234:16/little>>", <<16#1234:16/little>>),
    %% unit 修饰符：unit:8 时尺寸的单位是 8 位而不是 1 位
    d("<<1:2/unit:8>>（2 个 8 位单元 = 16 位）", <<1:2/unit:8>>),
    %% 同样的字节，按有符号解释是 -1，按无符号是 255
    d("按有符号读 <<255>>", as_signed(<<255>>)),
    d("按无符号读 <<255>>", as_unsigned(<<255>>)),
    %% 浮点
    d("<<1.0:32/float>>（IEEE 754 单精度）", <<1.0:32/float>>),
    d("<<1.0:64/float>>（双精度）", <<1.0:64/float>>),
    d("读回来 <<63,240,0,0,0,0,0,0>> 是 1.0", as_double(<<63, 240, 0, 0, 0, 0, 0, 0>>)),
    ok.

as_signed(<<X:8/signed>>) -> X.
as_unsigned(<<X:8/unsigned>>) -> X.
as_double(<<F:64/float>>) -> F.

%% 4) 文本编码
%% ------------------------------------------------------------
text_encodings() ->
    io:format("~n== 4) 文本编码 ==~n"),
    %% utf8 是三字节、utf16 两字节、utf32 四字节
    d("<<$中/utf8>> 及字节", {<<$中/utf8>>, binary:bin_to_list(<<$中/utf8>>)}),
    d("<<$中/utf16>> 及字节（大端）", {<<$中/utf16>>, binary:bin_to_list(<<$中/utf16>>)}),
    %% utf16 / utf32 的字节序要用「-」连接，写成 /utf16/little 是语法错误
d("<<$中/utf16-little>> 及字节（小端）", {<<$中/utf16-little>>, binary:bin_to_list(<<$中/utf16-little>>)}),
    d("<<$中/utf32>> 及字节", {<<$中/utf32>>, binary:bin_to_list(<<$中/utf32>>)}),
    d("byte_size 分别是", [byte_size(<<$中/utf8>>),
                           byte_size(<<$中/utf16>>),
                           byte_size(<<$中/utf32>>)]),
    %% 按 utf8 解码回来
    d("[C || <<C/utf8>> <= <<\"中文\"/utf8>>]",
      [C || <<C/utf8>> <= <<"中文"/utf8>>]),
    d("unicode:characters_to_list(<<\"中文\"/utf8>>)",
      unicode:characters_to_list(<<"中文"/utf8>>)),
    %% 重新编码
    d("unicode:characters_to_binary([20013,25991])",
      unicode:characters_to_binary([20013, 25991])),
    ok.

%% 5) binary 模块常用函数
%% ------------------------------------------------------------
binary_module() ->
    io:format("~n== 5) binary 模块 ==~n"),
    B = <<1, 2, 3, 4, 5>>,
    d("binary:at(B, 1)", binary:at(B, 1)),
    d("binary:first(B) / binary:last(B)", {binary:first(B), binary:last(B)}),
    d("binary:part(B, 1, 3)", binary:part(B, 1, 3)),
    d("binary:split(<<1,2,0,3,0,4>>, <<0>>, [global])",
      binary:split(<<1, 2, 0, 3, 0, 4>>, <<0>>, [global])),
    d("binary:split(<<1,2,3>>, <<3>>)", binary:split(<<1, 2, 3>>, <<3>>)),
    d("binary:match(<<1,2,3>>, <<2,3>>)", binary:match(<<1, 2, 3>>, <<2, 3>>)),
    d("binary:matches(<<1,2,1,2>>, <<1,2>>)", binary:matches(<<1, 2, 1, 2>>, <<1, 2>>)),
    d("binary:replace 全局替换",
      binary:replace(<<"aXbXc">>, <<"X">>, <<"-">>, [global])),
    d("binary:copy", binary:copy(<<7>>, 4)),
    d("binary:longest_common_prefix", binary:longest_common_prefix([<<"abcdef">>, <<"abcxyz">>])),
    d("binary:decode_unsigned(<<1,0>>)", binary:decode_unsigned(<<1, 0>>)),
    d("binary:encode_unsigned(256)", binary:encode_unsigned(256)),
    d("binary:bin_to_list(B)", binary:bin_to_list(B)),
    d("binary:list_to_bin([1,2,3])", binary:list_to_bin([1, 2, 3])),
    d("iolist_to_binary([<<\"a\">>, \"bc\"])", iolist_to_binary([<<"a">>, "bc"])),
    ok.

%% 6) 实战：TLV 协议、UTF-8 手工解码、PNG 头解析
%% ------------------------------------------------------------
%% TLV = Type-Length-Value，很多二进制协议的基础形状
parse_tlv(<<Type:8, Len:16, Value:Len/binary, Rest/binary>>) ->
    {ok, {Type, Value}, Rest};
parse_tlv(B) ->
    {incomplete, byte_size(B)}.

encode_tlv(Type, Value) when is_integer(Type), is_binary(Value) ->
    <<Type:8, (byte_size(Value)):16, Value/binary>>.

%% 手工按 UTF-8 规则解码：演示位语法做位级操作
parse_utf8(<<0:1, A:7, Rest/binary>>) -> [{1, A} | parse_utf8(Rest)];
parse_utf8(<<2#110:3, A:5, 2#10:2, B:6, Rest/binary>>) ->
    [{2, (A bsl 6) bor B} | parse_utf8(Rest)];
parse_utf8(<<2#1110:4, A:4, 2#10:2, B:6, 2#10:2, C:6, Rest/binary>>) ->
    [{3, (A bsl 12) bor (B bsl 6) bor C} | parse_utf8(Rest)];
parse_utf8(<<>>) -> [];
parse_utf8(_) -> [{error, invalid_utf8}].

%% PNG 文件头：8 字节魔数 + 4 字节长度 + "IHDR" + 宽 4 字节 + 高 4 字节
png_size(<<137, 80, 78, 71, 13, 10, 26, 10,
           _Len:32, "IHDR", Width:32, Height:32, _/binary>>) ->
    {ok, Width, Height};
png_size(_) ->
    {error, not_png}.

real_world() ->
    io:format("~n== 6) 实战 ==~n"),
    Tlv = encode_tlv(1, <<"hello">>),
    d("编码 {1, <<\"hello\">>}", Tlv),
    d("解析回来", parse_tlv(Tlv)),
    d("两帧连在一起也能顺序解出", parse_two_frames()),
    d("半截帧被识别为 incomplete", parse_tlv(<<1, 0, 5, "ab">>)),
    d("UTF-8 手工解码 <<\"A中\"/utf8>>", parse_utf8(<<"A中"/utf8>>)),
    d("与 unicode 模块的结果对照",
      {parse_utf8(<<"A中"/utf8>>), [C || <<C/utf8>> <= <<"A中"/utf8>>]}),
    %% 造一个最小的 PNG 头（只有前 24 字节里的关键字段）
    Png = <<137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, "IHDR",
            0, 0, 1, 128, 0, 0, 0, 96>>,
    d("PNG 尺寸（宽 384 高 96）", png_size(Png)),
    d("非 PNG 数据", png_size(<<"not a png at all">>)),
    ok.

parse_two_frames() ->
    Two = <<(encode_tlv(1, <<"ab">>))/binary, (encode_tlv(2, <<"cd">>))/binary>>,
    {ok, F1, Rest} = parse_tlv(Two),
    {ok, F2, <<>>} = parse_tlv(Rest),
    {F1, F2}.

raises(F, Arg) ->
    try F(Arg) catch Class:Reason -> {Class, Reason} end.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
