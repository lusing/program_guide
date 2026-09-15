% ============================================================
%  05-lists.pl —— 列表
%
%  运行（SWI）: swipl -q -f examples/05-lists.pl -g main -t halt
%  运行（GNU）: gprolog --consult-file examples/05-lists.pl --entry-goal main
% ============================================================

:- set_prolog_flag(double_quotes, codes).

% ------------------------------------------------------------
%  手写版本：理解「列表递归」到底在干什么
% ------------------------------------------------------------
my_length([], 0).
my_length([_ | T], N) :- my_length(T, N0), N is N0 + 1.

my_last([X], X).
my_last([_ | T], X) :- my_last(T, X).

my_reverse(L, R) :- my_reverse(L, [], R).
my_reverse([], Acc, Acc).
my_reverse([H | T], Acc, R) :- my_reverse(T, [H | Acc], R).

my_append([], L, L).
my_append([H | T], L, [H | R]) :- my_append(T, L, R).

my_member(X, [X | _]).
my_member(X, [_ | T]) :- my_member(X, T).

my_nth0(0, [X | _], X).
my_nth0(N, [_ | T], X) :- N > 0, N1 is N - 1, my_nth0(N1, T, X).

% SWI 有 numlist/3、include/3、foldl/4，GNU Prolog 没有 —— 下面是可移植替代
my_range(Lo, Hi, []) :- Lo > Hi, !.
my_range(Lo, Hi, [Lo | Rest]) :- Lo1 is Lo + 1, my_range(Lo1, Hi, Rest).

% 用 call/2 做「闭包」：Goal 缺一个参数，由列表元素补上
my_filter([], _, []).
my_filter([X | Xs], Goal, R) :-
    (   catch(call(Goal, X), _, fail)
    ->  R = [X | R1]
    ;   R = R1
    ),
    my_filter(Xs, Goal, R1).

% 用 call/4 做折叠：Goal 是三参数的 (Acc, Elem, Acc1)
my_foldl([], _, Acc, Acc).
my_foldl([X | Xs], Goal, Acc, R) :-
    call(Goal, Acc, X, Acc1),
    my_foldl(Xs, Goal, Acc1, R).

add3(A, B, C) :- C is A + B.
gt3(X) :- X > 3.

% ------------------------------------------------------------
%  演示
% ------------------------------------------------------------
demo_essence :-
    format("---- 列表的本质 ----~n", []),
    functor([1,2,3], F, N),
    format("  functor([1,2,3], F, N)  -> F=~q N=~w~n", [F, N]),
    format("    （SWI 里是 '[|]'，GNU Prolog 里是 '.'——同一个东西两种名字）~n", []),
    arg(1, [1,2,3], Hd), arg(2, [1,2,3], Tl),
    format("  arg(1) 头=~w   arg(2) 尾=~w~n", [Hd, Tl]),
    ( [a|[b]] == [a,b] -> R2 = '是' ; R2 = '否' ),
    format("  [a|[b]] == [a,b]        -> ~w~n", [R2]),
    ( [] == [] -> R3 = '是' ; R3 = '否' ),
    format("  [] 是原子，[X] 是复合项，两者不同：~w~n", [R3]).

demo_builtin :-
    format("---- 常用谓词 ----~n", []),
    length([a, b, c, d], Len1),
    format("  length([a,b,c,d], N)      -> ~w~n", [Len1]),
    ( member(b, [a,b,c]) -> format("  member(b,[a,b,c])         -> 真~n", []) ; true ),
    ( append([1,2],[3],A) -> format("  append([1,2],[3],X)       -> ~w~n", [A]) ; true ),
    ( append(P, S, [1,2,3]) -> format("  append(P,S,[1,2,3])       -> ~w + ~w（可反着用）~n", [P, S]) ; true ),
    ( nth0(1, [a,b,c], E0) -> format("  nth0(1,[a,b,c],X)         -> ~w（0 基）~n", [E0]) ; true ),
    ( nth1(1, [a,b,c], E1) -> format("  nth1(1,[a,b,c],X)         -> ~w（1 基）~n", [E1]) ; true ),
    ( reverse([1,2,3], Rv) -> format("  reverse([1,2,3],X)        -> ~w~n", [Rv]) ; true ),
    ( sort([c,a,b,a], Sr)  -> format("  sort([c,a,b,a],X)         -> ~w（去重排序）~n", [Sr]) ; true ),
    ( msort([c,a,b,a], Ms) -> format("  msort([c,a,b,a],X)        -> ~w（排序不去重）~n", [Ms]) ; true ),
    ( last([1,2,3], Ls)    -> format("  last([1,2,3],X)           -> ~w~n", [Ls]) ; true ),
    ( select(2, [1,2,3], Rst) -> format("  select(2,[1,2,3],X)       -> ~w（删掉一个 2）~n", [Rst]) ; true ).

demo_handwrite :-
    format("---- 手写递归 ----~n", []),
    my_length([a,b,c,d,e], L1),  format("  my_length  -> ~w~n", [L1]),
    my_last([1,2,3], L2),        format("  my_last    -> ~w~n", [L2]),
    my_reverse([1,2,3], L3),     format("  my_reverse -> ~w（尾递归 + 累加器）~n", [L3]),
    my_append([1,2],[3,4], L4),  format("  my_append  -> ~w~n", [L4]),
    findall(X5, my_member(X5, [a,b]), L5),
    format("  my_member  -> ~w（多解，用 findall 收）~n", [L5]),
    my_nth0(2, [a,b,c,d], L6),   format("  my_nth0    -> ~w~n", [L6]),
    findall(P7-S7, my_append(P7, S7, [1,2]), L7),
    format("  my_append 反向用 -> ~w（一个谓词顶三个函数）~n", [L7]).

demo_set :-
    format("---- 去重与集合运算（自写，两个引擎都能跑）----~n", []),
    Dedup = [3,1,2,1,3],
    sort(Dedup, Sorted),
    format("  sort 去重排序：~w -> ~w~n", [Dedup, Sorted]),
    my_subtract([1,2,3,4], [2,4], Diff),
    format("  差集 ~w \\ ~w = ~w~n", [[1,2,3,4], [2,4], Diff]),
    my_intersect([1,2,3,4], [3,4,5], Inter),
    format("  交集 = ~w~n", [Inter]),
    my_union([1,2], [2,3], U),
    format("  并集 = ~w~n", [U]).

my_subtract([], _, []).
my_subtract([X | Xs], Ys, R) :-
    ( memberchk(X, Ys) -> R = R1 ; R = [X | R1] ),
    my_subtract(Xs, Ys, R1).

my_intersect([], _, []).
my_intersect([X | Xs], Ys, R) :-
    ( memberchk(X, Ys) -> R = [X | R1] ; R = R1 ),
    my_intersect(Xs, Ys, R1).

my_union(A, B, U) :- append(A, B, AB), sort(AB, U).

demo_portability :-
    format("---- 双引擎差异 ----~n", []),
    format("  numlist/3、include/3、exclude/3、foldl/4 属于 SWI 的库，~n", []),
    format("  GNU Prolog 没有。可移植做法是自己写，或用 between + findall：~n", []),
    findall(I, between(1, 5, I), Nums),
    format("  between + findall 造 1..5：~w~n", [Nums]),
    my_range(1, 5, Mine),
    format("  my_range(1,5)：          ~w~n", [Mine]),
    my_filter([1,2,3,4,5,6], gt3, F1),
    format("  my_filter 取 >3：        ~w~n", [F1]),
    my_foldl([1,2,3,4], add3, 0, Sum1),
    format("  my_foldl 求和：          ~w~n", [Sum1]).

run :-
    format("==== 05  列表 ====~n", []), nl,
    demo_essence,    nl,
    demo_builtin,    nl,
    demo_handwrite,  nl,
    demo_set,        nl,
    demo_portability.

main :-
    (   catch((run, nl, format("==== 05 结束 ====~n", [])),
              E, (nl, format(user_error, "*** 异常: ~q~n", [E]), halt(1)))
    ->  halt(0)
    ;   nl, format(user_error, "*** 05 运行失败~n", []), halt(1)
    ).
