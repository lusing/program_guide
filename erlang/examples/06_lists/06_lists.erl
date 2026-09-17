%% ============================================================
%% 06_lists —— lists 模块与列表处理
%%
%%    列表是 Erlang 的主力数据结构。这一章把 lists 模块按用途
%%    分类过一遍，并说清楚每类操作的代价，避免写出 O(N^2) 的代码。
%%
%% 编译：
%%   erlc -Werror -Wall -o build/06_lists examples/06_lists/06_lists.erl
%% 运行：
%%   erl -noshell -pa build/06_lists -run '06_lists' main -s init stop
%% ============================================================
-module('06_lists').

-export([main/0, my_map/2, my_filter/2, my_foldl/3, my_reverse/1, split_even_odd/1]).

%% 1) 构造与分解
%% ------------------------------------------------------------
main() ->
    construct(),
    take_and_drop(),
    higher_order(),
    searching(),
    sorting_and_grouping(),
    associative_lists(),
    cost_notes(),
    io:format("~n==== 06 结束 ====~n").

construct() ->
    io:format("== 1) 构造与分解 ==~n"),
    d("lists:seq(1, 5)", lists:seq(1, 5)),
    d("lists:seq(1, 10, 3)", lists:seq(1, 10, 3)),
    d("lists:seq(5, 1, -2)（也能倒着走）", lists:seq(5, 1, -2)),
    d("lists:duplicate(3, x)", lists:duplicate(3, x)),
    d("lists:append([[1,2],[3],[4]])", lists:append([[1, 2], [3], [4]])),
    d("[1,2] ++ [3,4]", [1, 2] ++ [3, 4]),
    d("[1,2,3] -- [2]", [1, 2, 3] -- [2]),
    d("lists:flatten([[1,[2]],[3]])", lists:flatten([[1, [2]], [3]])),
    d("lists:flatten 会把深层也压平", lists:flatten([a, [b, [c, [d]]]])),
    d("lists:reverse([1,2,3])", lists:reverse([1, 2, 3])),
    d("lists:reverse([1,2,3], [9])（带初值）", lists:reverse([1, 2, 3], [9])),
    d("[H|T] 解构 [1,2,3]", begin [H | T] = [1, 2, 3], {H, T} end),
    ok.

%% 2) 取元素
%% ------------------------------------------------------------
take_and_drop() ->
    io:format("~n== 2) 取元素 ==~n"),
    L = [a, b, c, d, e],
    d("lists:nth(2, L)（从 1 开始）", lists:nth(2, L)),
    d("lists:last(L)", lists:last(L)),
    d("lists:hd / lists:tl", {hd(L), tl(L)}),
    d("lists:sublist(L, 3)（前 3 个）", lists:sublist(L, 3)),
    d("lists:sublist(L, 2, 3)（从第 2 个起取 3 个）", lists:sublist(L, 2, 3)),
    d("lists:droplast(L)", lists:droplast(L)),
    d("lists:partition(偶数, 1..8)", lists:partition(fun(X) -> X rem 2 =:= 0 end, lists:seq(1, 8))),
    d("lists:splitwith(<4, [1,2,5,1])", lists:splitwith(fun(X) -> X < 4 end, [1, 2, 5, 1])),
    d("lists:split(2, L)", lists:split(2, L)),
    ok.

%% 3) 高阶函数四件套
%% ------------------------------------------------------------
%% map / filter / foldl / foldr 是列表处理的全部基础，其它都是组合。
higher_order() ->
    io:format("~n== 3) 高阶函数 ==~n"),
    L = [1, 2, 3, 4, 5],
    d("lists:map(平方, L)", lists:map(fun(X) -> X * X end, L)),
    d("lists:filter(偶数, L)", lists:filter(fun(X) -> X rem 2 =:= 0 end, L)),
    %% foldl 从左边开始：((((0+1)+2)+3)+4)+5
    d("lists:foldl(+, 0, L)", lists:foldl(fun(X, A) -> X + A end, 0, L)),
    %% foldr 从右边开始：1+(2+(3+(4+(5+0))))
    d("lists:foldr(+, 0, L)", lists:foldr(fun(X, A) -> X + A end, 0, L)),
    %% 用 foldl 构造列表得到逆序，用 foldr 得到正序 —— 这个差别很实用
    d("foldl 构造列表（逆序）", lists:foldl(fun(X, A) -> [X | A] end, [], [1, 2, 3])),
    d("foldr 构造列表（正序）", lists:foldr(fun(X, A) -> [X | A] end, [], [1, 2, 3])),
    %% foreach 只为了副作用
    d("lists:foreach 返回 ok", lists:foreach(fun(_) -> ok end, [1, 2])),
    d("mapfoldl 同时变换与累积", lists:mapfoldl(fun(X, S) -> {X * 2, S + X} end, 0, [1, 2, 3])),
    d("zip / unzip", {lists:zip([1, 2], [a, b]), lists:unzip([{1, a}, {2, b}])}),
    d("zipwith", lists:zipwith(fun(A, B) -> A + B end, [1, 2, 3], [10, 20, 30])),
    d("lists:enumerate 带上序号", lists:enumerate([a, b, c])),
    d("lists:flatmap（map 后压平一层）",
      lists:flatmap(fun(X) -> [X, X] end, [1, 2, 3])),
    d("lists:filtermap（一个函数同时管过滤和变换）",
      lists:filtermap(fun(X) when X rem 2 =:= 0 -> {true, X * 10};
                         (_) -> false
                      end, [1, 2, 3, 4])),
    d("lists:join 会在元素之间插入分隔符",
      lists:join(",", ["a", "b", "c"])),
    d("所以 join 后接 flatten 才是拼接",
      lists:flatten(lists:join(",", ["a", "b", "c"]))),
    ok.

%% 4) 查找与判定
%% ------------------------------------------------------------
searching() ->
    io:format("~n== 4) 查找与判定 ==~n"),
    L = [{a, 1}, {b, 2}, {c, 3}],
    d("lists:member(b, [a,b,c])", lists:member(b, [a, b, c])),
    d("lists:keyfind(b, 1, L)", lists:keyfind(b, 1, L)),
    d("lists:keyfind(z, 1, L)（找不到返回 false）", lists:keyfind(z, 1, L)),
    d("lists:keymember", lists:keymember(b, 1, L)),
    d("lists:keytake(b, 1, L)", lists:keytake(b, 1, L)),
    d("lists:search(>2, [1,2,3])", lists:search(fun(X) -> X > 2 end, [1, 2, 3])),
    d("lists:search(>9, [1,2,3])（找不到返回 false）", lists:search(fun(X) -> X > 9 end, [1, 2, 3])),
    d("lists:all / any", {lists:all(fun(X) -> X > 0 end, [1, 2]),
                          lists:any(fun(X) -> X > 1 end, [1, 2])}),
    d("lists:sum / max / min",
      {lists:sum([1, 2, 3]), lists:max([1, 5, 3]), lists:min([1, 5, 3])}),
    d("lists:sum 可以算浮点", lists:sum([0.1, 0.2])),
    ok.

%% 5) 排序、去重与合并
%% ------------------------------------------------------------
sorting_and_grouping() ->
    io:format("~n== 5) 排序、去重与合并 ==~n"),
    d("lists:sort([3,1,2])", lists:sort([3, 1, 2])),
    d("lists:sort 是稳定排序",
      lists:sort(fun({A, _}, {B, _}) -> A =< B end,
                 [{1, a}, {2, b}, {1, c}, {2, d}])),
    d("lists:usort 去重并排序", lists:usort([3, 1, 2, 1, 3])),
    d("lists:sort/2 传自定义比较器（这里降序）", lists:sort(fun(A, B) -> A >= B end, [1, 2, 3])),
    d("lists:umerge 合并两个有序表", lists:umerge([1, 3, 5], [2, 3, 4])),
    d("lists:merge 不要求输入有序", lists:merge([[3, 1], [2]])),
    d("lists:usort 按项序排列混合类型", lists:usort([b, 1, a, 2.0, "x"])),
    d("lists:uniq 去掉相邻重复", lists:uniq([1, 1, 2, 3, 3])),
    d("先 sort 再 uniq 才是「按值去重」",
      begin L = [3, 1, 3, 1, 2], lists:uniq(lists:sort(L)) end),
    %% OTP 的 lists 里没有「把连续的相等元素打包」的函数，自己写一个：
    d("自实现 group/1（相等元素打包）", group([1, 1, 2, 3, 3, 3])),
    d("配合 sort 就是 SQL 的 GROUP BY",
      group(lists:sort([b, a, b, c, a]))),
    d("lists:prefix([1,2], [1,2,3])", lists:prefix([1, 2], [1, 2, 3])),
    d("lists:suffix([3], [1,2,3])", lists:suffix([3], [1, 2, 3])),
    d("lists:takewhile(<3, [1,2,3,1])", lists:takewhile(fun(X) -> X < 3 end, [1, 2, 3, 1])),
    d("lists:dropwhile(<3, [1,2,3,1])", lists:dropwhile(fun(X) -> X < 3 end, [1, 2, 3, 1])),
    d("lists:concat([a, \"-\", 1])", lists:concat([a, "-", 1])),
    ok.

%% 把「连续相等」的元素打包成子列表（OTP 的 lists 没有这个函数）
group([]) -> [];
group([H | T]) ->
    {Same, Rest} = lists:splitwith(fun(X) -> X =:= H end, [H | T]),
    [Same | group(Rest)].

%% 6) 关联列表（键值对列表）的专用函数
%% ------------------------------------------------------------
associative_lists() ->
    io:format("~n== 6) 关联列表 ==~n"),
    L = [{name, "alice"}, {age, 30}, {city, "beijing"}],
    d("lists:keyfind(age, 1, L)", lists:keyfind(age, 1, L)),
    d("取出值用 pattern", begin {age, A} = lists:keyfind(age, 1, L), A end),
    d("lists:keyreplace", lists:keyreplace(age, 1, L, {age, 31})),
    d("lists:keystore（存在则替换，不存在则追加）",
      lists:keystore(email, 1, L, {email, "a@b.c"})),
    d("lists:keydelete", lists:keydelete(age, 1, L)),
    %% 提一个常见需求的封装
    d("split_even_odd([1..7])", split_even_odd(lists:seq(1, 7))),
    ok.

%% 用 foldr 一次遍历完成分类，并且保持原顺序
split_even_odd(L) ->
    lists:foldr(fun(X, {Ev, Od}) when X rem 2 =:= 0 -> {[X | Ev], Od};
                   (X, {Ev, Od}) -> {Ev, [X | Od]}
                end, {[], []}, L).

%% 7) 代价：哪些是 O(1)、哪些是 O(N)
%% ------------------------------------------------------------
%% 这是写 Erlang 时最该记住的一张表：
%%   O(1)   [H|T] 取头、els:hd/1
%%   O(N)   length/1、lists:last/1、++（左操作数长度）、--、lists:nth/2
%%          以及 **任何遍历整个列表的操作**
%%   特别地：list ++ list 的代价由**左边**决定；
%%           用 ++ 反复追加到列表尾部是 O(N^2)，要改成 «凑出来再 reverse»
cost_notes() ->
    io:format("~n== 7) 代价与惯用法 ==~n"),
    %% 演示「先攒后转」的惯用法：把 N 个元素追加到结果里
    Naive = append_naive(lists:seq(1, 200), []),
    Fast = lists:reverse(append_fast(lists:seq(1, 200), [])),
    d("朴素追加与「攒完再 reverse」结果相同", Naive =:= Fast),
    d("两者结果的前 5 个", lists:sublist(Naive, 5)),
    d("自实现 my_map/2 与 lists:map/2 一致",
      my_map(fun(X) -> X * 3 end, lists:seq(1, 20)) =:= lists:map(fun(X) -> X * 3 end, lists:seq(1, 20))),
    d("自实现 my_filter/2 与 lists:filter/2 一致",
      my_filter(fun(X) -> X rem 3 =:= 0 end, lists:seq(1, 20))
      =:= lists:filter(fun(X) -> X rem 3 =:= 0 end, lists:seq(1, 20))),
    d("自实现 my_foldl/3 与 lists:foldl/3 一致",
      my_foldl(fun(X, A) -> A + X end, 0, lists:seq(1, 20))
      =:= lists:foldl(fun(X, A) -> A + X end, 0, lists:seq(1, 20))),
    d("自实现 my_reverse/1 与 lists:reverse/1 一致",
      my_reverse(lists:seq(1, 20)) =:= lists:reverse(lists:seq(1, 20))),
    ok.

%% 反例：每轮都往尾部追加，O(N^2)
append_naive([], Acc) -> Acc;
append_naive([H | T], Acc) -> append_naive(T, Acc ++ [H * 2]).

%% 正解：头插是 O(1)，最后一次性 reverse
append_fast([], Acc) -> Acc;
append_fast([H | T], Acc) -> append_fast(T, [H * 2 | Acc]).

%% 三个「自实现」，都用尾递归 + 累加器
my_map(F, L) -> lists:reverse(my_map(F, L, [])).
my_map(_F, [], Acc) -> Acc;
my_map(F, [H | T], Acc) -> my_map(F, T, [F(H) | Acc]).

%% filter 保持顺序，所以用 foldr 或者「头插 + reverse」
my_filter(F, L) -> lists:reverse(my_filter(F, L, [])).
my_filter(_F, [], Acc) -> Acc;
my_filter(F, [H | T], Acc) ->
    case F(H) of
        true -> my_filter(F, T, [H | Acc]);
        false -> my_filter(F, T, Acc)
    end.

my_foldl(_F, Acc, []) -> Acc;
my_foldl(F, Acc, [H | T]) -> my_foldl(F, F(H, Acc), T).

my_reverse(L) -> my_reverse(L, []).
my_reverse([], Acc) -> Acc;
my_reverse([H | T], Acc) -> my_reverse(T, [H | Acc]).

d(Label, Value) -> io:format("  ~ts = ~p~n", [Label, Value]).



