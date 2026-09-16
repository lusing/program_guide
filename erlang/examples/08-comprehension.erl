%% ============================================================
%% 08 - 列表推导式与二进制推导式
%%
%%    推导式是「从已有集合构造新集合」的语法：
%%      [ 表达式 || 生成器, 过滤器, ... ]
%%    生成器写 Pattern <- List（或 Pattern <= Binary），
%%    过滤器就是一个 guard。多个生成器等于嵌套循环。
%%
%% 编译：
%%   erlc -Werror -Wall -o build examples/08-comprehension.erl
%% 运行：
%%   erl -noshell -pa build -run '08-comprehension' main -s init stop
%% ============================================================
-module('08-comprehension').

-export([main/0, flatten_deep/1, quicksort/1, quoted/1]).

main() ->
    basics(),
    generators_and_filters(),
    multiple_generators(),
    binary_comprehensions(),
    real_world(),
    io:format("~n==== 08 结束 ====~n").

%% 1) 基本形式
%% ------------------------------------------------------------
basics() ->
    io:format("== 1) 基本形式 ==~n"),
    d("[X*2 || X <- [1,2,3]]", [X * 2 || X <- [1, 2, 3]]),
    %% 过滤器写在生成器后面
    d("[X || X <- 1..10, X rem 2 =:= 0]", [X || X <- lists:seq(1, 10), X rem 2 =:= 0]),
    %% 表达式里可以用模式解构
    d("[N || {N, _} <- [{a,1},{b,2}]] —— 注意这里 N 是原子",
      [N || {N, _} <- [{a, 1}, {b, 2}]]),
    d("[N*10 || {_K, N} <- [{a,1},{b,2}]]", [N * 10 || {_K, N} <- [{a, 1}, {b, 2}]]),
    %% 模式不匹配的元素会被**静默跳过**（这是很多 bug 的来源）
    d("模式不匹配会被跳过：[X || {X} <- [{1},{2},not_tuple,{3}]]",
      [X || {X} <- [{1}, {2}, not_tuple, {3}]]),
    d("所以需要严格时要用 = 强制：见注释",
      {strict, ok}),
    ok.

%% 2) 生成器与过滤器的组合
%% ------------------------------------------------------------
generators_and_filters() ->
    io:format("~n== 2) 生成器与过滤器 ==~n"),
    %% 三重过滤
    d("1..30 中 3 的倍数且不是 6 的倍数",
      [N || N <- lists:seq(1, 30), N rem 3 =:= 0, N rem 6 =/= 0]),
    %% 过滤条件里可以做复杂计算，
    %% 甚至可以「先算出来再判断」——用生成器当局部变量（很常用的技巧）
    d("用生成器当局部变量：完全平方数",
      [N || N <- lists:seq(1, 50), S <- [trunc(math:sqrt(N))], S * S =:= N]),
    d("生成器可以使用外层变量", [N * K || N <- [1, 2, 3], K <- [10], K > 5]),
    %% 输出表达式里也可以调用函数
    d("输出表达式调用自定义函数", [quoted(X) || X <- ["a", "b"]]),
    ok.

quoted(S) -> [$[, S, $]].

%% 3) 多个生成器 = 嵌套循环
%% ------------------------------------------------------------
%% 写成 [X || A <- L1, B <- L2] 时，右面的生成器在**内层**，
%% 所以 A 变化最慢、B 变化最快。
multiple_generators() ->
    io:format("~n== 3) 多个生成器 ==~n"),
    d("笛卡尔积 [[A,B] || A<-[1,2], B<-[x,y]]",
      [[A, B] || A <- [1, 2], B <- [x, y]]),
    d("两个 1..3 的求和表", [[A + B || B <- lists:seq(1, 3)] || A <- lists:seq(1, 3)]),
    %% 经典的勾股数：用三个生成器，靠过滤器剪枝
    d("20 以内的勾股数",
      [{A, B, C} || C <- lists:seq(1, 20),
                    B <- lists:seq(1, C),
                    A <- lists:seq(1, B),
                    A * A + B * B =:= C * C]),
    %% 生成器也可以依赖前一个生成器绑定的变量
    d("第二个生成器的范围由第一个决定",
      [{N, M} || N <- lists:seq(1, 3), M <- lists:seq(1, N)]),
    ok.

%% 4) 二进制推导式
%% ------------------------------------------------------------
%% 语法上是 << ... || Pattern <= Binary >>，生成器用 <= 而不是 <-。
binary_comprehensions() ->
    io:format("~n== 4) 二进制推导式 ==~n"),
    %% 语法要点（两个都容易踩）：
    %%   ① 生成器用 <= 而不是 <-（<= 表示「从二进制里切出片段」）；
    %%   ② **输出表达式必须是一个二进制**，写成 << <<E:尺寸/类型>> || ... >>。
    %%      直接写 <<E || ...>> 会在运行期 badarg（把 E 当二进制去嵌入）。
    Bin = <<1, 2, 3, 4, 5, 6>>,
    d("<<<<X>> || <<X>> <= Bin>>（原样复制）", <<<<X>> || <<X>> <= Bin>>),
    d("<<<<(X*2)>> || <<X>> <= Bin, X rem 2 =:= 0>>（取偶数再翻倍）",
      <<<<(X * 2)>> || <<X>> <= Bin, X rem 2 =:= 0>>),
    %% 每次读 2 字节（大端），重写为 2 字节小端 —— 字节序转换的常用写法
    d("<<<<Y:16/little>> || <<Y:16/big>> <= <<1,0,2,0,3,0>>>>",
      <<<<Y:16/little>> || <<Y:16/big>> <= <<1, 0, 2, 0, 3, 0>>>>),
    %% 按 UTF-8 解码再重新编码
    Utf8 = <<"中文abc"/utf8>>,
    d("按 utf8 解出码点（列表推导）", [C || <<C/utf8>> <= Utf8]),
    d("只保留 ASCII 字符（重新编码成二进制）",
      <<<<C/utf8>> || <<C/utf8>> <= Utf8, C < 128>>),
    %% 同一份数据，既能产列表也能产二进制
    d("列表推导版", [X * X || <<X>> <= Bin]),
    d("二进制推导版", <<<<(X * X)>> || <<X>> <= Bin>>),
    ok.

%% 5) 实战：几个常见需求的推导式写法
%% ------------------------------------------------------------
real_world() ->
    io:format("~n== 5) 实战用法 ==~n"),
    %% 展平任意深度的列表
    d("flatten_deep([1,[2,[3,[4]]],5])", flatten_deep([1, [2, [3, [4]]], 5])),
    %% 去重同时保序（nub）
    d("保序去重 [3,1,3,2,1]", nub([3, 1, 3, 2, 1])),
    %% 索引
    d("带下标 [{1,a},{2,b}]",
      lists:zip(lists:seq(1, length([a, b])), [a, b])),
    %% 分组计数
    d("词频统计", word_freq(["a", "b", "a", "c", "a", "b"])),
    %% 快速排序：推导式让它的表达非常短
    d("quicksort([3,6,1,8,2])", quicksort([3, 6, 1, 8, 2])),
    %% maps:from_list 配合推导式构造 map
    d("maps:from_list([{N,N*N} || N<-1..5]) 的排序输出",
      lists:sort(maps:to_list(maps:from_list([{N, N * N} || N <- lists:seq(1, 5)])))),
    ok.

%% 递归展平：既演示推导式，也演示「递归 + 推导式」的组合
flatten_deep(L) ->
    [X || E <- L, X <- do_flatten(E)].

do_flatten(L) when is_list(L) -> flatten_deep(L);
do_flatten(X) -> [X].

%% 保序去重：用「已出现过的集合」做过滤器
nub(L) -> nub(L, sets:new([{version, 2}]), []).

nub([], _Seen, Acc) -> lists:reverse(Acc);
nub([H | T], Seen, Acc) ->
    case sets:is_element(H, Seen) of
        true -> nub(T, Seen, Acc);
        false -> nub(T, sets:add_element(H, Seen), [H | Acc])
    end.

%% 词频：排序后输出，避免依赖 map 的迭代顺序
word_freq(Words) ->
    Counts = lists:foldl(fun(W, Acc) -> maps:update_with(W, fun(N) -> N + 1 end, 1, Acc) end,
                         #{}, Words),
    lists:sort(maps:to_list(Counts)).

%% 快速排序：推导式把「取小于基准的 / 取大于基准的」写得非常直观
quicksort([]) -> [];
quicksort([Pivot | Rest]) ->
    quicksort([X || X <- Rest, X < Pivot])
        ++ [Pivot] ++
        quicksort([X || X <- Rest, X >= Pivot]).

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).
