%% ============================================================
%% 04 - 模式匹配
%%
%%    模式匹配不是「语法糖」，而是 Erlang 的函数调用机制：
%%    调用一个函数时，实参会被逐个尝试与各子句的**模式**匹配，
%%    第一个匹配成功的子句被执行。所以 Erlang 里很少写 if。
%%
%% 编译：
%%   erlc -Werror -Wall -o build examples/04-patterns.erl
%% 运行：
%%   erl -noshell -pa build -run '04-patterns' main -s init stop
%% ============================================================
-module('04-patterns').

-export([main/0, area/1, head_tail/1, parse_frame/1, config_get/2, classify/1]).

main() ->
    dispatch_by_shape(),
    tuple_list_patterns(),
    binding_rules(),
    binary_patterns(),
    map_patterns(),
    alias_patterns(),
    match_operator(),
    io:format("~n==== 04 结束 ====~n").

%% 1) 用形状分派：同一函数名的多个子句
%% ------------------------------------------------------------
%% 三个子句用不同的元组形状区分几何体，不需要任何 if / switch。
area({circle, R}) -> 3.141592653589793 * R * R;
area({rect, W, H}) when W > 0, H > 0 -> W * H;
area({triangle, A, B, C}) -> heron(A, B, C);
area(Other) -> {error, {unknown_shape, Other}}.

heron(A, B, C) ->
    S = (A + B + C) / 2,
    math:sqrt(S * (S - A) * (S - B) * (S - C)).

dispatch_by_shape() ->
    io:format("== 1) 按形状分派 ==~n"),
    d("area({circle, 1})", with_precision(area({circle, 1}))),
    d("area({rect, 3, 4})", with_precision(area({rect, 3, 4}))),
    d("area({triangle, 3, 4, 5})", with_precision(area({triangle, 3, 4, 5}))),
    d("area({rect, 0, 4})（guard 不通过，落到兜底子句）", area({rect, 0, 4})),
    d("area(hexagon)", area(hexagon)),
    ok.

with_precision(F) -> round(F * 10000) / 10000.

%% 2) 元组与列表模式
%% ------------------------------------------------------------
%% [H | T] 把列表拆成头和尾；[_ | T] 表示忽略头。
head_tail([]) -> empty;
head_tail([X]) -> {single, X};
head_tail([X, Y | Rest]) -> {two_plus, X, Y, Rest}.

tuple_list_patterns() ->
    io:format("~n== 2) 元组与列表模式 ==~n"),
    d("head_tail([])", head_tail([])),
    d("head_tail([7])", head_tail([7])),
    d("head_tail([1,2,3,4])", head_tail([1, 2, 3, 4])),
    %% 列表模式可以一步取出固定个数的元素
    {A, B, Rest} = {hd([1, 2, 3]), hd(tl([1, 2, 3])), tl(tl([1, 2, 3]))},
    d("手工拆 [1,2,3]", {A, B, Rest}),
    d("[X, Y | Rest] = [1,2,3,4]",
      begin [X, Y | Rs] = [1, 2, 3, 4], {X, Y, Rs} end),
    %% 嵌套模式
    d("匹配嵌套 {ok, {user, N}}",
      begin {ok, {user, N}} = {ok, {user, alice}}, N end),
    d("匹配 [[1|_]|_] 这样的嵌套列表",
      begin [[1 | _] | _] = [[1, 2], [3, 4]], matched end),
    ok.

%% 3) 变量的绑定规则
%% ------------------------------------------------------------
%% 关键点：
%%   ① 变量在一次函数调用中只能绑定一次；同一个变量在模式里出现两次
%%      表示「必须相等」（这是约束，不是重新绑定）。
%%   ② 变量之间不跨子句共享。
%%   ③ 下划线开头的变量只抑制「未使用」警告，仍然会绑定。
binding_rules() ->
    io:format("~n== 3) 变量的绑定规则 ==~n"),
    %% 同一变量 X 出现两次 → 两个位置必须相等
    Inputs = [{1, 1}, {1, 2}, {a, a}, {a, b}],
    d("same_or_diff({X, X}) 的判定", [same_or_diff(T) || T <- Inputs]),
    %% 下划线完全不绑定
    d("_ 不绑定任何变量", (fun(_) -> ok end)(whatever)),
    %% = 在模式中就是「匹配」；不匹配就抛 badmatch
    d("{ok, V} = {ok, 42} 之后 V", begin {ok, V0} = {ok, 42}, V0 end),
    d("{ok, V} = {error, 1} 会抛",
      raises(fun(Val) -> {ok, _Unused} = Val end, {error, 1})),
    %% 模式里可以写字面量
    d("tag_1({tag, 1}) / tag_1({tag, 2})", [tag_1(T) || T <- [{tag, 1}, {tag, 2}]]),
    ok.

%% 同一个变量 X 在模式里出现两次：两个位置必须相等才匹配
same_or_diff({X, X}) -> same;
same_or_diff(_) -> different.

tag_1({tag, 1}) -> hit;
tag_1(_) -> miss.

%% 4) 二进制模式：解析二进制协议的常规手段
%% ------------------------------------------------------------
%% 帧格式：[1 字节类型][2 字节大端长度][负载]
parse_frame(<<Type:8, Len:16, Payload:Len/binary, Rest/binary>>) ->
    {ok, Type, Len, Payload, Rest};
parse_frame(<<Type:8, Len:16, Partial/binary>>) ->
    {incomplete, Type, Len, byte_size(Partial)};
parse_frame(Bin) ->
    {error, {too_short, byte_size(Bin)}}.

binary_patterns() ->
    io:format("~n== 4) 二进制模式 ==~n"),
    Frame = <<1:8, 3:16, "abc", 9:8, 9:8>>,
    d("完整帧 parse_frame(<<1,0,3,\"abc\",9,9>>)", parse_frame(Frame)),
    d("半截帧 parse_frame(<<1,0,3,\"ab\">>)", parse_frame(<<1:8, 3:16, "ab">>)),
    d("太短 parse_frame(<<1>>)", parse_frame(<<1>>)),
    %% 尺寸可以引用前面已经绑定的变量，这是位语法最强大的一点
    d("取自描述长度 <<5:8, \"hello\", \"!\">>",
      begin <<N:8, P:N/binary, Tail/binary>> = <<5:8, "hello", "!">>, {N, P, Tail} end),
    %% 也支持整型字节序、有符号、浮点等修饰
    d("<<X:16/big>> = <<1,0>>", begin <<X1:16/big>> = <<1, 0>>, X1 end),
    d("<<X:16/little>> = <<1,0>>", begin <<X2:16/little>> = <<1, 0>>, X2 end),
    d("有符号 <<X:16/signed>> = <<255,255>>",
      begin <<X3:16/signed>> = <<255, 255>>, X3 end),
    d("无符号 <<X:16/unsigned>> = <<255,255>>",
      begin <<X4:16/unsigned>> = <<255, 255>>, X4 end),
    d("浮点 <<F:32/float>>", begin <<F1:32/float>> = <<63:8, 128:8, 0:8, 0:8>>, F1 end),
    ok.

%% 5) Map 模式：:= 要求键存在，=> 不参与匹配
%% ------------------------------------------------------------
%% 这是 map 模式里最反直觉的一点：
%%   模式中 #{} 内的 := 表示「该键必须存在」，=> 在模式里是**字面量**匹配。
config_get(#{name := N, retries := R}, _Key) when is_integer(R) ->
    {ok, N, R};
config_get(#{name := N}, _Key) ->
    {ok, N, 0};
config_get(Map, Key) when is_map(Map), is_atom(Key) ->
    {missing_name, maps:is_key(Key, Map)}.

map_patterns() ->
    io:format("~n== 5) Map 模式 ==~n"),
    d("config_get(#{name => a, retries => 3})", config_get(#{name => a, retries => 3}, x)),
    d("config_get(#{name => a})（没有 retries，落到第二子句）",
      config_get(#{name => a}, x)),
    d("config_get(#{other => 1})", config_get(#{other => 1}, name)),
    d("is_map_key 可以在 guard 里用",
      begin M = #{k => 1}, (fun(X) when is_map_key(k, X) -> has_k; (_) -> no_k end)(M) end),
    d("maps:get/3 提供默认值", maps:get(nope, #{k => 1}, default)),
    d("maps:find 返回 {ok,V} 或 error", {maps:find(k, #{k => 1}), maps:find(x, #{k => 1})}),
    ok.

%% 6) 别名模式：@ 同时绑定整体和部分
%% ------------------------------------------------------------
classify(P = {point, X, Y}) when X =:= Y ->
    {on_diagonal, P, abs(X)};
classify(P = {point, X, _Y}) ->
    {off_diagonal, P, abs(X)}.

alias_patterns() ->
    io:format("~n== 6) 别名模式 ==~n"),
    %% 别名模式让「整个值」和「拆出来的部分」都能用
    d("classify({point, 3, 3})", classify({point, 3, 3})),
    d("classify({point, 3, 4})", classify({point, 3, 4})),
    d("列表里也能用：Sum = [X | _] 取头", (fun(L = [X | _]) -> {X, length(L)} end)([9, 8, 7])),
    ok.

%% 7) 匹配算符 = 就是模式匹配
%% ------------------------------------------------------------
match_operator() ->
    io:format("~n== 7) 匹配算符 = ==~n"),
    %% 变量已经绑定时，= 变成「断言相等」，不等就抛 badmatch
    X = 1,
    d("X 已绑定为 1，再写 1 = X", 1 = X),
    d("再写 2 = X 会抛", raises(fun(V) -> 2 = V end, X)),
    d("所以在函数里可以用 = 做断言", begin {ok, V} = {ok, 5}, V end),
    ok.

%% 参数由调用方传入，避免编译器做常量传播后把「必然失败」变成编译期错误
raises(F, Arg) ->
    try F(Arg) catch Class:Reason -> {Class, Reason} end.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
