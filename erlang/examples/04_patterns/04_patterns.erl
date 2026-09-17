%% ============================================================
%% 04_patterns —— 模式匹配与卫语句
%%
%%    模式匹配不是「语法糖」，而是 Erlang 的函数调用机制：
%%    调用一个函数时，实参被逐个尝试与各子句的**模式**匹配，
%%    第一个匹配成功的子句被执行。所以 Erlang 里很少写 if——
%%    匹配即分派，guard 再做第二道筛选。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/04_patterns examples/04_patterns/04_patterns.erl
%% 运行：
%%   erl -noshell -pa build/04_patterns -run '04_patterns' main -s init stop
%% ============================================================
-module('04_patterns').

-export([main/0, area/1, head_tail/1, same_or_diff/1, parse_frame/1,
         kind/1, clamp/3, describe/1, sign/1, raises/2,
         first_or_empty/1, first_or_empty_safe/1]).

main() ->
    dispatch_by_shape(),
    match_everywhere(),
    binding_rules(),
    binary_patterns(),
    match_operator(),
    guard_basics(),
    guard_bifs(),
    guard_failure_is_silent(),
    case_and_if(),
    io:format("~n==== 04 结束 ====~n").

%% 1) 用形状分派：同一函数名的多个子句
%% ------------------------------------------------------------
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

%% 2) 元组、列表、map、别名——各种地方都能匹配
%% ------------------------------------------------------------
head_tail([]) -> empty;
head_tail([X]) -> {single, X};
head_tail([X, Y | Rest]) -> {two_plus, X, Y, Rest}.

match_everywhere() ->
    io:format("~n== 2) 各处都能匹配 ==~n"),
    d("head_tail([])", head_tail([])),
    d("head_tail([7])", head_tail([7])),
    d("head_tail([1,2,3,4])", head_tail([1, 2, 3, 4])),
    d("[X, Y | Rest] = [1,2,3,4]",
      begin [X, Y | Rs] = [1, 2, 3, 4], {X, Y, Rs} end),
    d("匹配嵌套 {ok, {user, N}}",
      begin {ok, {user, N}} = {ok, {user, alice}}, N end),
    %% map 模式：:= 要求键必须存在（=> 在模式里不参与匹配）
    d("map 模式 #{name := N, retries := R}",
      begin #{name := Nm, retries := R} = #{name => a, retries => 3}, {ok, Nm, R} end),
    d("is_map_key/2 可以在 guard 里用",
      begin M = #{k => 1}, (fun(Mp) when is_map_key(k, Mp) -> has_k; (_) -> no_k end)(M) end),
    %% 别名模式 P = ...：同时绑定「整体」与「部分」
    d("classify({point, 3, 3})", classify({point, 3, 3})),
    d("classify({point, 3, 4})", classify({point, 3, 4})),
    ok.

classify(P = {point, X, Y}) when X =:= Y ->
    {on_diagonal, P, abs(X)};
classify(P = {point, X, _Y}) ->
    {off_diagonal, P, abs(X)}.

%% 3) 变量的绑定规则
%% ------------------------------------------------------------
%%   ① 变量在一次匹配中只能绑定一次；同一变量在模式里出现两次
%%      表示「必须相等」（约束，不是重新绑定）。
%%   ② _ 完全不绑定；_Foo 会绑定但抑制 unused 警告。
binding_rules() ->
    io:format("~n== 3) 变量的绑定规则 ==~n"),
    Inputs = [{1, 1}, {1, 2}, {a, a}, {a, b}],
    d("same_or_diff({X, X}) 的判定", [same_or_diff(T) || T <- Inputs]),
    d("_ 不绑定任何变量", (fun(_) -> ok end)(whatever)),
    ok.

%% 同一个变量 X 在模式里出现两次：两个位置必须相等才匹配
same_or_diff({X, X}) -> same;
same_or_diff(_) -> different.

%% 4) 二进制模式：解析二进制协议的常规手段（08 章展开）
%% ------------------------------------------------------------
%% 帧格式：[1 字节类型][2 字节大端长度][负载]
parse_frame(<<Type:8, Len:16, Payload:Len/binary, Rest/binary>>) ->
    {ok, Type, Len, Payload, Rest};
parse_frame(<<Type:8, Len:16, Partial/binary>>) ->
    {incomplete, Type, Len, byte_size(Partial)};
parse_frame(Bin) ->
    {error, {too_short, byte_size(Bin)}}.

binary_patterns() ->
    io:format("~n== 4) 二进制模式（预览） ==~n"),
    Frame = <<1:8, 3:16, "abc", 9:8, 9:8>>,
    d("完整帧 parse_frame(<<1,0,3,\"abc\",9,9>>)", parse_frame(Frame)),
    d("半截帧 parse_frame(<<1,0,3,\"ab\">>)", parse_frame(<<1:8, 3:16, "ab">>)),
    d("太短 parse_frame(<<1>>)", parse_frame(<<1>>)),
    %% 尺寸可以引用前面已绑定的变量——位语法最强大的一点
    d("自描述长度 <<5:8, \"hello\", \"!\">>",
      begin <<N:8, P:N/binary, Tail/binary>> = <<5:8, "hello", "!">>, {N, P, Tail} end),
    d("有符号 <<X:16/signed>> = <<255,255>>",
      begin <<X:16/signed>> = <<255, 255>>, X end),
    ok.

%% 5) 匹配算符 = 在函数体里就是断言
%% ------------------------------------------------------------
match_operator() ->
    io:format("~n== 5) = 就是断言 ==~n"),
    X = 1,
    d("X 已绑定为 1，再写 1 = X", 1 = X),
    d("再写 2 = X 会抛", raises(fun(V) -> 2 = V end, X)),
    d("所以函数里可以用 = 断言成功",
      begin {ok, V} = {ok, 5}, V end),
    ok.

%% 6) 卫语句：when 后面的附加条件
%% ------------------------------------------------------------
clamp(X, Lo, Hi) when Lo =< X, X =< Hi -> X;
clamp(X, Lo, _Hi) when X < Lo -> Lo;
clamp(X, _Lo, Hi) when X > Hi -> Hi;
clamp(X, _Lo, _Hi) -> X.

guard_basics() ->
    io:format("~n== 6) 卫语句 ==~n"),
    d("clamp(5, 1, 10)", clamp(5, 1, 10)),
    d("clamp(0, 1, 10)", clamp(0, 1, 10)),
    d("clamp(99, 1, 10)", clamp(99, 1, 10)),
    d("clamp(5, 10, 1)（Lo>Hi 落到兜底）", clamp(5, 10, 1)),
    d("week_day(1..7)",
      [week_day(N) || N <- lists:seq(1, 7)]),
    ok.

week_day(N) when N >= 1, N =< 5 -> workday;
week_day(N) when N =:= 6; N =:= 7 -> weekend;
week_day(_) -> invalid.

%% 7) guard 的三条铁律
%% ------------------------------------------------------------
%%   ① 只能用一小撮 BIF（见下面抽样），自定义函数一律不行；
%%   ② 逗号 = and、分号 = or（与多数语言相反）；
%%   ③ guard 出错（如 hd([])）静默变 false，继续试下一个子句。
kind(X) when is_integer(X), X >= 0 -> non_negative_int;
kind(X) when is_integer(X) -> negative_int;
kind(X) when is_float(X); is_number(X), X == 0.0 -> zero_or_float;
kind(X) when is_atom(X) -> atom;
kind(_) -> other.

guard_bifs() ->
    io:format("~n== 7) guard 里允许的 BIF（抽样） ==~n"),
    d("hd([1,2])", (fun(L) when hd(L) > 0 -> yes; (_) -> no end)([1, 2])),
    d("length(L) =:= 3", (fun(L) when length(L) =:= 3 -> three; (_) -> other end)([a, b, c])),
    d("abs(X) > 3", (fun(X) when abs(X) > 3 -> big; (_) -> small end)(-5)),
    d("map_size(M) =:= 1", (fun(M) when map_size(M) =:= 1 -> one; (_) -> other end)(#{a => 1})),
    d("map_get(a, M) =:= 1", (fun(M) when map_get(a, M) =:= 1 -> one; (_) -> other end)(#{a => 1})),
    d("is_map_key(a, M)", (fun(M) when is_map_key(a, M) -> has; (_) -> hasnot end)(#{a => 1})),
    d("bit 运算 (A band 1) =:= 0（偶数）",
      (fun(A) when A band 1 =:= 0 -> even; (_) -> odd end)(10)),
    d("element(1, T) =:= a", (fun(T) when element(1, T) =:= a -> first_a; (_) -> no end)({a, 1})),
    d("kind(5)/kind(-5)/kind(3.5)/kind(hello)", [kind(V) || V <- [5, -5, 3.5, hello]]),
    ok.

guard_failure_is_silent() ->
    io:format("~n== 8) guard 失败不是异常 ==~n"),
    d("first_or_empty([])", first_or_empty([])),
    d("first_or_empty([7])", first_or_empty([7])),
    %% 对比：在函数体里 hd([]) 就会抛
    d("函数体里 hd([]) 会抛", raises(fun(L) -> hd(L) end, [])),
    d("把 is_list 放前面更稳", first_or_empty_safe([5])),
    d("对非列表也能优雅兜底", first_or_empty_safe(not_a_list)),
    ok.

first_or_empty([H | _]) when is_integer(H) -> {first, H};
first_or_empty([]) -> empty;
first_or_empty(_) -> not_int_list.

first_or_empty_safe(L) when is_list(L), L =/= [], is_integer(hd(L)) -> {first, hd(L)};
first_or_empty_safe(L) when is_list(L), L =:= [] -> empty;
first_or_empty_safe(_) -> not_int_list.

%% 9) case 与 if：对中间结果分派
%% ------------------------------------------------------------
%% 对函数参数分派 → 多子句；对中间结果分派 → case；
%% 纯条件阶梯 → if（分支必须是 guard，且必须留 true 兜底）。
describe({ok, V}) -> {success, V};
describe({error, Reason}) -> {failure, Reason};
describe([]) -> empty_list;
describe(L) when is_list(L) -> {list_of, length(L)};
describe(Other) -> {unknown, Other}.

case_and_if() ->
    io:format("~n== 9) case 与 if ==~n"),
    d("describe({ok, 1})", describe({ok, 1})),
    d("describe({error, not_found})", describe({error, not_found})),
    d("describe([1,2,3])", describe([1, 2, 3])),
    d("对中间结果用 case", lookup_report(#{a => 1}, a)),
    d("对中间结果用 case（缺失）", lookup_report(#{a => 1}, b)),
    d("sign(5) / sign(-5) / sign(0)", [sign(N) || N <- [5, -5, 0]]),
    d("if 没有 true 兜底时会抛 if_clause",
      raises(fun(X) -> if X > 10 -> big end end, 1)),
    d("case X > 10 of true -> ... 达到同样效果且更安全",
      (fun(X) -> case X > 10 of true -> big; false -> small end end)(1)),
    ok.

lookup_report(Map, Key) ->
    case maps:find(Key, Map) of
        {ok, V} when is_integer(V) -> {found_int, V};
        {ok, V} -> {found, V};
        error -> missing
    end.

sign(X) when is_number(X) ->
    if
        X > 0 -> positive;
        X < 0 -> negative;
        true -> zero          %% 这一行不能省
    end.

%% 参数由调用方传入，避免编译器做常量传播后把「必然失败」变成编译期错误
raises(F, Arg) ->
    try F(Arg) catch Class:Reason -> {Class, Reason} end.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
