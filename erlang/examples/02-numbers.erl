%% ============================================================
%% 02 - 数值：整数、浮点与它们的陷阱
%%
%%    本示例演示：任意精度整数、进制字面量、位运算、
%%    div/rem 的符号规则、浮点精度与溢出、取整家族、
%%    以及 == 与 =:= 的区别。
%%
%% 编译：
%%   erlc -Werror -Wall -o build examples/02-numbers.erl
%% 运行：
%%   erl -noshell -pa build -run '02-numbers' main -s init stop
%% ============================================================
-module('02-numbers').

-export([main/0, fact/1, shift_demo/0, float_traps/0, rounding/0, compare/0]).

main() ->
    integers(),
    literal_forms(),
    shift_demo(),
    div_rem(),
    float_traps(),
    rounding(),
    compare(),
    io:format("~n==== 02 结束 ====~n").

%% 1) 整数没有上限：需要多大就有多大
%% ------------------------------------------------------------
integers() ->
    io:format("== 1) 任意精度整数 ==~n"),
    d("2^64", 1 bsl 64),
    d("2^128 的十进制位数", length(integer_to_list(1 bsl 128))),
    d("100!（末尾有几个 0）", count_trailing_zeros(fact(100))),
    d("fact(20)", fact(20)),
    %% 注意：Erlang 里没有溢出，只有「变慢」
    d("(1 bsl 10000) 的位数", length(integer_to_list(1 bsl 10000))),
    ok.

fact(N) when is_integer(N), N >= 0 -> fact(N, 1);
fact(_) -> erlang:error(badarg).

%% 尾递归：累加器在参数里，不占调用栈（第 06 章详述）
fact(0, Acc) -> Acc;
fact(N, Acc) -> fact(N - 1, N * Acc).

count_trailing_zeros(N) -> count_trailing_zeros(N, 0).
count_trailing_zeros(N, C) when N rem 10 =:= 0 -> count_trailing_zeros(N div 10, C + 1);
count_trailing_zeros(_, C) -> C.

%% 2) 各种字面量写法
%% ------------------------------------------------------------
literal_forms() ->
    io:format("~n== 2) 数字字面量 ==~n"),
    d("16#FF", 16#FF),
    d("2#1010", 2#1010),
    d("8#777", 8#777),
    d("36#Z（最大进制 36）", 36#Z),
    d("1_000_000（下划线只是分隔）", 1_000_000),
    d("$A（字符即码点）", $A),
    d("$中", $中),
    d("1.5e3", 1.5e3),
    d("1.0e-3", 1.0e-3),
    ok.

%% 3) 位运算
%% ------------------------------------------------------------
shift_demo() ->
    io:format("~n== 3) 位运算 ==~n"),
    d("1 bsl 8", 1 bsl 8),
    d("256 bsr 4", 256 bsr 4),
    d("12 band 10", 12 band 10),
    d("12 bor 10", 12 bor 10),
    d("12 bxor 10", 12 bxor 10),
    d("bnot 0（按位取反，负数）", bnot 0),
    d("用位运算拆分字节：0xABCD 的高/低字节", {16#ABCD bsr 8, 16#ABCD band 16#FF}),
    ok.

%% 4) div / rem 的符号规则（这里是最容易写错的地方）
%% ------------------------------------------------------------
div_rem() ->
    io:format("~n== 4) div / rem 一律向零截断 ==~n"),
    d(" 7 div 2", 7 div 2),
    d("-7 div 2", -7 div 2),
    d(" 7 div -2", 7 div -2),
    d("-7 div -2", -7 div -2),
    d(" 7 rem 2", 7 rem 2),
    d("-7 rem 2（余数跟随被除数符号）", -7 rem 2),
    d(" 7 rem -2", 7 rem -2),
    d("-7 rem -2", -7 rem -2),
    d(" 7 / 2（/ 永远返回浮点）", 7 / 2),
    %% 整数除 0 抛 badarith，不是返回 0。
    %% 注意：写 try 1 div 0 ... 编译器做常量传播，会在**编译期**就报
    %%   evaluation of operator 'div'/2 will fail with a 'badarith' exception
    %% 所以要让除数为「运行期才知道」的值，才演示得到运行期异常。
    d("1 div 0 会抛", raises(fun(D) -> 1 div D end, 0)),
    d("恒等式 7 =:= (-7 div 2)*2 + (-7 rem 2)",
      -7 =:= (-7 div 2) * 2 + (-7 rem 2)),
    ok.

%% 把「可能在运行期抛异常」的表达式包起来，参数由调用方给出，
%% 这样编译器无法在编译期折叠出异常。
raises(F, Arg) ->
    try F(Arg) catch Class:Reason -> {Class, Reason} end.

%% 5) 浮点：精度与溢出
%% ------------------------------------------------------------
%% Erlang 的浮点是 IEEE 754 双精度。两个陷阱：
%%   ① 二进制浮点表示不了 0.1，所以 0.1+0.2 不等于 0.3；
%%   ② **溢出抛 badarith，不产生 inf/nan** —— 这点和 C/Java/Python 都不同。
float_traps() ->
    io:format("~n== 5) 浮点精度与溢出 ==~n"),
    d("0.1 + 0.2", 0.1 + 0.2),
    d("0.1 + 0.2 =:= 0.3", 0.1 + 0.2 =:= 0.3),
    d("1/3", 1 / 3),
    d("float_to_binary(0.1)", float_to_binary(0.1)),
    d("float_to_binary(0.1, [short])（最短往返表示）", float_to_binary(0.1, [short])),
    %% 溢出抛 badarith —— 和 C/Java/Python 产生 inf 完全不同。同样要绕开常量传播。
    d("1.0e308 * 10", raises(fun(X) -> X * 10 end, 1.0e308)),
    d("1.0e308 * 10 会得到 inf 吗", false),
    d("0.0 / 0.0", raises(fun(X) -> X / X end, 0.0)),
    ok.

%% 6) 取整家族：四个函数四种语义
%% ------------------------------------------------------------
rounding() ->
    io:format("~n== 6) 取整 ==~n"),
    d("trunc(2.7)  截断", trunc(2.7)),
    d("round(2.5)  四舍五入（.5 远离零）", round(2.5)),
    d("round(3.5)", round(3.5)),
    d("round(-2.5)", round(-2.5)),
    d("floor(-2.5) 向下", floor(-2.5)),
    d("ceil(-2.5)  向上", ceil(-2.5)),
    d("trunc(-2.5)", trunc(-2.5)),
    %% 格式化浮点时精度不能写 0，这是一个很隐蔽的 badarg
    d("io_lib:format(\"~.2f\", [2.0/3])", lists:flatten(io_lib:format("~.2f", [2.0 / 3]))),
    d("io_lib:format(\"~.0f\", [2.5]) 会抛", try io_lib:format("~.0f", [2.5]) catch _:R -> R end),
    ok.

%% 7) 比较：算术比较 == 与精确比较 =:=
%% ------------------------------------------------------------
compare() ->
    io:format("~n== 7) 比较运算符 ==~n"),
    d("1 == 1.0（算术比较，会把整数提升为浮点）", 1 == 1.0),
    d("1 =:= 1.0（精确比较，类型也必须相同）", 1 =:= 1.0),
    d("1 /= 1.0", 1 /= 1.0),
    d("1 =/= 1.0", 1 =/= 1.0),
    d("min(1, 1.0)（算术比较下两者相等，返回第一个）", min(1, 1.0)),
    d("1 < a（数字永远排在原子前面）", 1 < a),
    d("lists:sort([b, 1, a, \"x\", 3.0]) 的项序", lists:sort([b, 1, a, "x", 3.0])),
    ok.

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
