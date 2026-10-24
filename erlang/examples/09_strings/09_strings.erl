%% ============================================================
%% 09_strings —— 字符串与 Unicode
%%
%%    三个结论请记牢：
%%      ① Erlang 里「字符串」就是整数列表，没有专门的字符串类型；
%%         二进制 <<"abc">> 是另一种表示，两者 =:= 不相等。
%%      ② <<"中文">> 这种二进制字面量里的字符串默认按 latin1 截断，
%%         中文必须写 <<"中文"/utf8>>。
%%      ③ ~s 只认 latin1，码点超过 255 直接 badarg；中文要用 ~ts。
%%
%%    覆盖点：
%%      字符串即整数列表 / latin1 截断坑 / 三种长度 / string 模块 /
%%      iolist / string:replace（OTP 20，返回 iodata，默认只换第一处）/
%%      uri_string（OTP 21，parse 的 map 只含出现过的部件）。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/09_strings examples/09_strings/09_strings.erl
%% 运行：
%%   erl -noshell -pa build/09_strings -run '09_strings' main -s init stop
%% ============================================================
-module('09_strings').

-export([main/0, raises/2]).

main() ->
    strings_are_lists(),
    latin1_trap(),
    three_lengths(),
    string_module(),
    iolists(),
    string_replace(),
    uri_string_parts(),
    io:format("~n==== 09 结束 ====~n").

%% 1) 字符串就是整数列表
%% ------------------------------------------------------------
strings_are_lists() ->
    io:format("== 1) 字符串就是整数列表 ==~n"),
    d("\"abc\" =:= [97, 98, 99]", "abc" =:= [97, 98, 99]),
    d("is_list(\"abc\")", is_list("abc")),
    d("length(\"abc\")（按码点计数）", length("abc")),
    d("[$a, $b, $c]", [$a, $b, $c]),
    d("[$中]（$x 取的是码点）", [$中]),
    d("hd(\"abc\")", hd("abc")),
    d("\"ab\" ++ \"cd\"", "ab" ++ "cd"),
    d("列表推导处理字符串：每个字符加 1", [C + 1 || C <- "abc"]),
    d("所以 \"abc\" 和 <<\"abc\">> 是两个不同的东西", {"abc", <<"abc">>}),
    ok.

%% 2) 头号编码坑：二进制字面量里的字符串按 latin1 截断
%% ------------------------------------------------------------
latin1_trap() ->
    io:format("~n== 2) 坑：<<\"中文\">> 会被 latin1 截断 ==~n"),
    %% '中' 的码点是 20013，截断成单字节就是 20013 rem 256 = 45
    d("$中", $中),
    d("20013 rem 256", 20013 rem 256),
    d("<<\"中\">>（错！只剩一个字节）", <<"中">>),
    d("<<\"中\"/utf8>>（对：三字节 UTF-8）", <<"中"/utf8>>),
    d("byte_size 对比", {byte_size(<<"中">>), byte_size(<<"中"/utf8>>)}),
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

%% 3) 三个「长度」：码点 / 字节 / 字素簇
%% ------------------------------------------------------------
three_lengths() ->
    io:format("~n== 3) 三个长度 ==~n"),
    S = <<"中文"/utf8>>,
    d("length(\"中文\")（码点数）", length("中文")),
    d("byte_size(<<\"中文\"/utf8>>)（UTF-8 字节数）", byte_size(S)),
    d("string:length(<<\"中文\"/utf8>>)（字素簇数）", string:length(S)),
    %% 字素簇：é 可以是一个码点，也可以是 e + 组合重音符（两个码点一个字）
    Combining = [$e, 16#0301],
    d("e+组合重音符 的 length / string:length",
      {length(Combining), string:length(Combining)}),
    ok.

%% 4) string 模块（chardata 通吃：列表与二进制都收）
%% ------------------------------------------------------------
string_module() ->
    io:format("~n== 4) string 模块 ==~n"),
    d("string:uppercase(\"abc\")", string:uppercase("abc")),
    d("string:reverse(\"abc\")", string:reverse("abc")),
    d("string:split(\"a,b,c\", \",\", all)", string:split("a,b,c", ",", all)),
    d("string:trim(\"  x  \")", string:trim("  x  ")),
    d("string:pad(\"7\", 3, leading, $0)", string:pad("7", 3, leading, $0)),
    d("string:find(\"hello\", \"ll\")", string:find("hello", "ll")),
    d("string:slice(\"hello\", 1, 3)", string:slice("hello", 1, 3)),
    d("string:lexemes(\"a,,b\", \",\")（连续分隔符当一个）", string:lexemes("a,,b", ",")),
    d("string:to_integer(\"42x\")", string:to_integer("42x")),
    d("string:to_float(\"1.5\")", string:to_float("1.5")),
    %% 注意 string:to_integer 失败时返回 {error, no_integer} 而不是抛异常
    d("string:to_integer(\"x\")", string:to_integer("x")),
    ok.

%% 5) iolist：构造输出的高效中间格式
%% ------------------------------------------------------------
iolists() ->
    io:format("~n== 5) iolist ==~n"),
    Deep = ["a", [$b, $c], <<"def">>, [[<<"g">>]]],
    d("嵌套的 iodata", Deep),
    d("iolist_to_binary 扁平化", iolist_to_binary(Deep)),
    d("iolist_size", iolist_size(Deep)),
    %% 大量拼接时，iolist 比反复 ++ 快得多（06 章讲了 ++ 的代价）
    d("用列表推导拼 iolist",
      iolist_to_binary([integer_to_list(I) || I <- [1, 2, 3]])),
    ok.

%% 6) string:replace（OTP 20）：返回 iodata，默认只换第一处
%% ------------------------------------------------------------
string_replace() ->
    io:format("~n== 6) string:replace ==~n"),
    d("string:replace(\"a-b-c\", \"-\", \"+\")（默认只换第一处）",
      string:replace("a-b-c", "-", "+")),
    d("string:replace(\"a-b-c\", \"-\", \"+\", all)（全换）",
      string:replace("a-b-c", "-", "+", all)),
    d("string:replace(\"a-b-c\", \"-\", \"+\", trailing)（只换最后一处）",
      string:replace("a-b-c", "-", "+", trailing)),
    %% 返回的是嵌套列表（iodata），要平面二进制得再转一道
    d("unicode:characters_to_binary 转平面二进制",
      unicode:characters_to_binary(string:replace("a-b-c", "-", "+", all))),
    ok.

%% 7) uri_string（OTP 21）：解析与构造 URI
%% ------------------------------------------------------------
uri_string_parts() ->
    io:format("~n== 7) uri_string ==~n"),
    Full = uri_string:parse("https://user@example.com:8443/a/b?x=1#frag"),
    d("uri_string:parse 全件（map 只含出现过的部件）", Full),
    d("maps:get(port, Full)（port 是整数）", maps:get(port, Full)),
    %% 没出现的部件不进 map，取可选项要给默认值
    NoPort = uri_string:parse("https://example.com/"),
    d("无 port 的解析结果", NoPort),
    d("maps:get(port, NoPort, 443)（兜底）", maps:get(port, NoPort, 443)),
    %% 非法输入不抛异常，返回 {error, Reason, Rest} 三元组
    d("非法输入（含空格）", uri_string:parse("http://h/p?a=b c")),
    %% 重组函数名是 recompose，不是 compose
    d("uri_string:recompose 把部件 map 拼回 URI",
      uri_string:recompose(#{scheme => "https", host => "example.com", path => "/a"})),
    d("uri_string:normalize（小写化、去默认端口、解码 %7e）",
      uri_string:normalize("HTTP://Example.COM:80/%7euser")),
    d("uri_string:quote(\"a b\")", uri_string:quote("a b")),
    d("uri_string:unquote(\"a%20b\")", uri_string:unquote("a%20b")),
    ok.

%% 把「预期会抛异常」的调用包起来。
%% 参数由调用方传入 —— 编译器会做常量传播，写死参数会变成编译期错误。
raises(F, Arg) ->
    try F(Arg) catch Class:Reason -> {Class, Reason} end.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
