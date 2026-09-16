%% ============================================================
%% 05 - Guard：比模式更细的筛选条件
%%
%%    Guard 是挂在子句上的附加条件，写在 when 后面。
%%    三条铁律：
%%      ① guard 里**只能调用一小撮内建函数（BIF）**，自定义函数一律不行
%%         （编译器直接报 illegal guard expression，所以本示例只能注释说明）；
%%      ② guard 失败 ≠ 抛异常，而是「这个子句不匹配」，继续试下一个子句；
%%      ③ 逗号 = and，分号 = or；分号的优先级比逗号低。
%%
%% 编译：
%%   erlc -Werror -Wall -o build examples/05-guards.erl
%% 运行：
%%   erl -noshell -pa build -run '05-guards' main -s init stop
%% ============================================================
-module('05-guards').

-export([main/0, kind/1, clamp/3, classify/1, week_day/1, tree_sum/1]).

main() ->
    basics(),
    allowed_bifs(),
    comma_semicolon(),
    guard_failure_is_silent(),
    guards_on_maps_and_lists(),
    guards_in_comprehensions(),
    io:format("~n==== 05 结束 ====~n").

%% 1) 基本形式
%% ------------------------------------------------------------
clamp(X, Lo, Hi) when Lo =< X, X =< Hi -> X;
clamp(X, Lo, _Hi) when X < Lo -> Lo;
clamp(X, _Lo, Hi) when X > Hi -> Hi;
clamp(X, _Lo, _Hi) -> X.

basics() ->
    io:format("== 1) 基本形式 ==~n"),
    d("clamp(5, 1, 10)", clamp(5, 1, 10)),
    d("clamp(0, 1, 10)", clamp(0, 1, 10)),
    d("clamp(99, 1, 10)", clamp(99, 1, 10)),
    d("clamp(5, 10, 1)（Lo>Hi，落到兜底子句）", clamp(5, 10, 1)),
    ok.

%% 2) guard 里允许出现的函数（必须是 BIF）
%% ------------------------------------------------------------
%% 下面每一项都是**实测可编译**的。
%%
%% 类型判定：is_atom/1 is_binary/1 is_bitstring/1 is_boolean/1 is_float/1
%%          is_function/1,2 is_integer/1 is_list/1 is_map/1 is_map_key/2
%%          is_number/1 is_pid/1 is_port/1 is_record/2,3 is_reference/1
%%          is_tuple/1  is_alive/0
%% 类型转换：abs/1 float/1 hd/1 tl/1 length/1 node/0,1 round/1 size/1
%%          trunc/1 map_get/2 map_size/1
%% 比较/算术：+ - * / div rem bsr bsl band bor bxor bnot
%%          self/0 以及 == /= =< < >= > =:= =/=
%%
%% **不能**出现在 guard 里的东西（编译期就会报错）：
%%   · 自定义函数，例如 lists:member(X, L)、length2(L) 这样的自己写的函数
%%     → error: call to local function length2/1 is illegal in guard
%%   · 大部分 stdlib 函数，例如 lists:reverse/1、maps:get/2（但 map_get/2 可以）
%%   · if 表达式、case 表达式、以及任何有副作用的调用
allowed_bifs() ->
    io:format("~n== 2) guard 里允许的 BIF（抽样） ==~n"),
    %% 数字与类型
    d("hd([1,2])", (fun(L) when hd(L) > 0 -> yes; (_) -> no end)([1, 2])),
    d("length(L) =:= 3", (fun(L) when length(L) =:= 3 -> three; (_) -> other end)([a, b, c])),
    d("abs(X) > 3", (fun(X) when abs(X) > 3 -> big; (_) -> small end)(-5)),
    d("round(X) =:= 2", (fun(X) when round(X) =:= 2 -> two; (_) -> other end)(1.6)),
    d("trunc(X) =:= 3", (fun(X) when trunc(X) =:= 3 -> three; (_) -> other end)(3.9)),
    d("float(X) > 1.0", (fun(X) when float(X) > 1.0 -> big; (_) -> small end)(2)),
    d("size(T) =:= 2（元组或二进制）",
      (fun(T) when size(T) =:= 2 -> two; (_) -> other end)({a, b})),
    d("map_size(M) =:= 1", (fun(M) when map_size(M) =:= 1 -> one; (_) -> other end)(#{a => 1})),
    d("map_get(a, M) =:= 1", (fun(M) when map_get(a, M) =:= 1 -> one; (_) -> other end)(#{a => 1})),
    d("is_map_key(a, M)", (fun(M) when is_map_key(a, M) -> has; (_) -> hasnot end)(#{a => 1})),
    d("bit 运算 (A band 1) =:= 0（偶数）",
      (fun(A) when A band 1 =:= 0 -> even; (_) -> odd end)(10)),
    d("bsl/bsr 也可用于 guard",
      (fun(A) when A bsr 3 > 0 -> big; (_) -> small end)(64)),
    %% 元素访问：element/2 与 hd/tl 都能用
    d("element(1, T) =:= a", (fun(T) when element(1, T) =:= a -> first_a; (_) -> no end)({a, 1})),
    %% is_record/2 需要 record 定义（见第 11 章）
    ok.

%% 3) 逗号与分号
%% ------------------------------------------------------------
%% 逗号是 and（都成立），分号是 or（有一个成立即可），分号优先级更低。
%% 常见写法：when (A 条件) ; (B 条件) —— 用括号让意图更清楚。
kind(X) when is_integer(X), X >= 0 -> non_negative_int;
kind(X) when is_integer(X) -> negative_int;
kind(X) when is_float(X); is_number(X), X == 0.0 -> zero_or_float;
kind(X) when is_atom(X) -> atom;
kind(_) -> other.

comma_semicolon() ->
    io:format("~n== 3) 逗号是 and，分号是 or ==~n"),
    d("kind(5)", kind(5)),
    d("kind(-5)", kind(-5)),
    d("kind(3.5)", kind(3.5)),
    d("kind(0.0)", kind(0.0)),
    d("kind(hello)", kind(hello)),
    d("kind({1})", kind({1})),
    %% 把 or 的多个条件用括号分组，可读性最好
    d("分号分组：偶数或 3 的倍数",
      [N || N <- lists:seq(1, 10),
            (N band 1 =:= 0) orelse (N rem 3 =:= 0)]),
    ok.

%% 4) guard 失败是「静默不匹配」，不是异常
%% ------------------------------------------------------------
%% 这是新手最容易困惑的一点：guard 里的表达式如果「类型不对」，
%% 结果不是抛异常，而是该子句直接不匹配。
guard_failure_is_silent() ->
    io:format("~n== 4) guard 失败不是异常 ==~n"),
    %% hd([]) 在 guard 里会失败 —— 但不会抛，只是子句不匹配
    d("first_or_empty([])", first_or_empty([])),
    d("first_or_empty([7])", first_or_empty([7])),
    %% 对比：在函数体里 hd([]) 就会抛
    d("函数体里 hd([]) 会抛", raises(fun(L) -> hd(L) end, [])),
    %% 所以写 guard 时通常把类型判定放在前面，避免「意外不匹配」
    d("把 is_list 放前面更稳", first_or_empty_safe([5])),
    d("对非列表也能优雅兜底", first_or_empty_safe(not_a_list)),
    ok.

first_or_empty([H | _]) when is_integer(H) -> {first, H};
first_or_empty([]) -> empty;
first_or_empty(_) -> not_int_list.

first_or_empty_safe(L) when is_list(L), L =/= [], is_integer(hd(L)) -> {first, hd(L)};
first_or_empty_safe(L) when is_list(L), L =:= [] -> empty;
first_or_empty_safe(_) -> not_int_list.

%% 5) 在 map / 列表 / record 上用 guard
%% ------------------------------------------------------------
%% 树用 {node, Left, Value, Right} 表示，sum 用 guard 判断叶子
tree_sum({leaf, V}) -> V;
tree_sum({node, L, V, R}) -> tree_sum(L) + V + tree_sum(R).

classify(M) when is_map(M), map_size(M) =:= 0 -> empty_map;
classify(M) when is_map(M), not is_map_key(id, M) -> no_id;
classify(#{id := Id}) when is_integer(Id), Id > 0 -> {positive_id, Id};
classify(#{id := Id}) -> {other_id, Id};
classify(_) -> not_a_map.

guards_on_maps_and_lists() ->
    io:format("~n== 5) guard 与 map / 递归数据结构 ==~n"),
    d("classify(#{})", classify(#{})),
    d("classify(#{x => 1})", classify(#{x => 1})),
    d("classify(#{id => 7})", classify(#{id => 7})),
    d("classify(#{id => -1})", classify(#{id => -1})),
    d("classify(42)", classify(42)),
    d("tree_sum({node,{leaf,1},2,{leaf,3}})",
      tree_sum({node, {leaf, 1}, 2, {leaf, 3}})),
    %% 也可以在 guard 里做算术
    d("week_day(1..3) 的工作日判断",
      [week_day(N) || N <- lists:seq(1, 7)]),
    ok.

week_day(N) when N >= 1, N =< 5 -> workday;
week_day(N) when N =:= 6; N =:= 7 -> weekend;
week_day(_) -> invalid.

%% 6) 推导式里的 guard
%% ------------------------------------------------------------
%% 列表推导的过滤器就是 guard（第 08 章详述）
guards_in_comprehensions() ->
    io:format("~n== 6) 推导式里的过滤器 ==~n"),
    d("1..20 里的完全平方数", [N || N <- lists:seq(1, 20),
                                      S <- [trunc(math:sqrt(N))], S * S =:= N]),
    d("1..30 里既是 2 的倍数又是 3 的倍数", [N || N <- lists:seq(1, 30),
                                                   N rem 2 =:= 0, N rem 3 =:= 0]),
    ok.

raises(F, Arg) ->
    try F(Arg) catch Class:Reason -> {Class, Reason} end.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
