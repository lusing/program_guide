%% ============================================================
%% 03 - 原子、字符串与二进制（Unicode 陷阱集中地）
%%
%%    这一章是全教程「坑」最密集的一章。三个结论请记牢：
%%      ① Erlang 里「字符串」就是整数列表，没有专门的字符串类型；
%%      ② <<"中文">> 这种**二进制字面量里的字符串默认按 latin1 截断**，
%%         中文必须写 <<"中文"/utf8>>；
%%      ③ ~s 只认 latin1，码点超过 255 直接 badarg；中文要用 ~ts。
%%
%% 编译：
%%   erlc -Werror -Wall -o build examples/03-atoms-strings.erl
%% 运行：
%%   erl -noshell -pa build -run '03-atoms-strings' main -s init stop
%% ============================================================
-module('03-atoms-strings').

-export([main/0, safe_atom/1]).

main() ->
    atoms(),
    strings_are_lists(),
    binaries(),
    latin1_trap(),
    unicode_api(),
    iolists(),
    io:format("~n==== 03 结束 ====~n").

%% 1) 原子
%% ------------------------------------------------------------
%% 原子是「自己的名字就是自己的值」的常量。全小写字母、数字、下划线、@
%% 组成的原子不用加引号，其它情况（大写开头、含空格/连字符/中文）必须加引号。
atoms() ->
    io:format("== 1) 原子 ==~n"),
    d("hello", hello),
    d("'Hello'（大写开头必须引号）", 'Hello'),
    d("'has space'", 'has space'),
    d("'01-hello'", '01-hello'),
    d("'中文'", '中文'),
    d("atom =:= atom（原子比较是常数时间）", hello =:= hello),
    d("atom_to_list(hello)", atom_to_list(hello)),
    d("atom_to_binary(hello, utf8)", atom_to_binary(hello, utf8)),
    d("binary_to_atom(<<\"hi\">>, utf8)", binary_to_atom(<<"hi">>, utf8)),
    %% 原子表**不回收**：从外部输入造原子有被撑爆的风险（atom_limit 默认 1048576）
    d("本机原子表上限", erlang:system_info(atom_limit)),
    d("用 list_to_existing_atom 只能命中已存在的原子", safe_atom("hello")),
    d("造一个不存在的原子会被拦下", safe_atom("definitely_not_an_atom_xyz")),
    ok.

%% 从不可信来源「造原子」的安全写法：优先命中已有原子，命中不了就报错。
safe_atom(Str) ->
    try {ok, list_to_existing_atom(Str)}
    catch error:badarg -> {error, not_existing}
    end.

%% 2) 字符串就是整数列表
%% ------------------------------------------------------------
strings_are_lists() ->
    io:format("~n== 2) 字符串就是整数列表 ==~n"),
    d("\"abc\" =:= [97, 98, 99]", "abc" =:= [97, 98, 99]),
    d("is_list(\"abc\")", is_list("abc")),
    d("length(\"abc\")（按码点计数）", length("abc")),
    d("[$a, $b, $c]", [$a, $b, $c]),
    d("[$中]（$x 取的是码点）", [$中]),
    d("hd(\"abc\")", hd("abc")),
    d("\"abc\" -- \"b\"", "abc" -- "b"),
    d("\"ab\" ++ \"cd\"", "ab" ++ "cd"),
    d("列表推导也能当字符串处理：每个字符加 1", [C + 1 || C <- "abc"]),
    d("所以 \"abc\" 和 <<\"abc\">> 是两个不同的东西", {"abc", <<"abc">>}),
    ok.

%% 3) 二进制
%% ------------------------------------------------------------
binaries() ->
    io:format("~n== 3) 二进制 ==~n"),
    d("<<1, 2, 3>>", <<1, 2, 3>>),
    d("<<\"abc\">>", <<"abc">>),
    d("byte_size(<<1,2,3>>)", byte_size(<<1, 2, 3>>)),
    d("bit_size(<<1:4>>)（按位）", bit_size(<<1:4>>)),
    d("<<1:16>>（默认大端）", <<1:16>>),
    d("<<1:16/little>>", <<1:16/little>>),
    d("<<1>> =:= <<1:8>>", <<1>> =:= <<1:8>>),
    d("istio 判定 is_binary / is_bitstring",
      {is_binary(<<1>>), is_bitstring(<<1:4>>), is_binary(<<1:4>>)}),
    d("binary_to_list(<<\"abc\">>)", binary_to_list(<<"abc">>)),
    d("list_to_binary([1,2,3])", list_to_binary([1, 2, 3])),
    ok.

%% 4) 最大的坑：二进制字面量里的字符串按 latin1 截断
%% ------------------------------------------------------------
latin1_trap() ->
    io:format("~n== 4) 坑：<<\"中文\">> 会被 latin1 截断 ==~n"),
    %% '中' 的码点是 20013，截断成单字节就是 20013 rem 256 = 45
    d("$中", $中),
    d("20013 rem 256", 20013 rem 256),
    d("<<\"中\">>（错！只剩一个字节）", <<"中">>),
    d("<<\"中\"/utf8>>（对：三字节 UTF-8）", <<"中"/utf8>>),
    d("byte_size(<<\"中\">>)", byte_size(<<"中">>)),
    d("byte_size(<<\"中\"/utf8>>)", byte_size(<<"中"/utf8>>)),
    d("纯 ASCII 时两者等价", <<"abc">> =:= <<"abc"/utf8>>),
    %% 截断出来的二进制往往**不是合法 UTF-8**，下游会以奇怪的方式出错
    d("unicode:characters_to_list(<<\"中文\">>)", unicode:characters_to_list(<<"中文">>)),
    d("unicode:characters_to_list(<<\"中文\"/utf8>>)",
      unicode:characters_to_list(<<"中文"/utf8>>)),
    %% list_to_binary 对码点 > 255 直接 badarg（这点编译器能在编译期发现）
    d("list_to_binary 遇到 >255 的码点会 badarg",
      raises(fun(L) -> list_to_binary(L) end, [$中])),
    d("正确做法 unicode:characters_to_binary([$中])",
      unicode:characters_to_binary([$中])),
    ok.

%% 5) unicode 模块与 string 模块
%% ------------------------------------------------------------
unicode_api() ->
    io:format("~n== 5) unicode / string 模块 ==~n"),
    d("string:length(\"中文\")（按字符数）", string:length("中文")),
    d("length(\"中文\")（对列表来说一样）", length("中文")),
    d("string:length(<<\"中文\"/utf8>>)", string:length(<<"中文"/utf8>>)),
    d("byte_size(<<\"中文\"/utf8>>)（按字节数）", byte_size(<<"中文"/utf8>>)),
    d("unicode:characters_to_binary(\"中文\")", unicode:characters_to_binary("中文")),
    d("string:uppercase(\"abc\")", string:uppercase("abc")),
    d("string:lowercase(\"ABC\")", string:lowercase("ABC")),
    d("string:reverse(\"abc\")", string:reverse("abc")),
    d("string:split(\"a,b,c\", \",\", all)", string:split("a,b,c", ",", all)),
    d("string:trim(\"  x  \")", string:trim("  x  ")),
    d("string:pad(\"7\", 3, leading, $0)", string:pad("7", 3, leading, $0)),
    d("string:find(\"hello\", \"ll\")", string:find("hello", "ll")),
    d("string:slice(\"hello\", 1, 3)", string:slice("hello", 1, 3)),
    d("string:lexemes(\"a,,b\", \",\")", string:lexemes("a,,b", ",")),
    d("string:to_integer(\"42x\")", string:to_integer("42x")),
    d("string:to_float(\"1.5\")", string:to_float("1.5")),
    %% 注意 string:to_integer 失败时返回 {error, badarg} 而不是抛异常
    d("string:to_integer(\"x\")", string:to_integer("x")),
    ok.

%% 6) iolist：构造输出的高效中间格式
%% ------------------------------------------------------------
iolists() ->
    io:format("~n== 6) iolist ==~n"),
    Deep = ["a", [$b, $c], <<"def">>, [[<<"g">>]]],
    d("嵌套的 iodata", Deep),
    d("iolist_to_binary 扁平化", iolist_to_binary(Deep)),
    d("iolist_size", iolist_size(Deep)),
    %% 大量拼接时，iolist 比反复 ++ 快得多（第 07 章讲原因）
    d("用列表推导拼 iolist 也很自然", iolist_to_binary([integer_to_list(I) || I <- [1, 2, 3]])),
    ok.

%% 把「预期会抛异常」的调用包起来。
%% 参数由调用方传入 —— 编译器会做常量传播，写死参数会变成编译期错误。
raises(F, Arg) ->
    try F(Arg) catch Class:Reason -> {Class, Reason} end.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
