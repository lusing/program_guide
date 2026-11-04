:- encoding(utf8).
% 第 24 章 · 向量空间 —— Prolog 通道
%
% GF(2)³ 全枚举：子空间清单 + Fano 回环 + 无关对计数。

vec3([A, B, C]) :- member(A, [0, 1]), member(B, [0, 1]), member(C, [0, 1]).

vec_add3(U, V, W) :- maplist([X, Y, Z]>>(Z is (X + Y) mod 2), U, V, W).

subset_of([], []).
subset_of([H | T], [H | S]) :- subset_of(T, S).
subset_of([_ | T], S) :- subset_of(T, S).

closed3(S) :-
    forall((member(U, S), member(V, S), vec_add3(U, V, W)), member(W, S)).

scalar_mul(0, _, [0, 0, 0]).
scalar_mul(1, U, U).

% 相关：存在不全零系数使 a·U = b·V
dep_pair(U, V) :-
    member(A, [0, 1]), member(B, [0, 1]), (A, B) \= (0, 0),
    scalar_mul(A, U, AU), scalar_mul(B, V, BV), AU = BV.

main :-
    format("==== 24 向量空间~n"),

    findall(V, vec3(V), Vs),
    length(Vs, 8),

    findall(S, (subset_of(Vs, S), S \= [], closed3(S)), Subs0),
    maplist(sort, Subs0, Subs1), sort(Subs1, Subs),
    length(Subs, NS), NS == 16,

    include([S]>>(length(S, 2)), Subs, Lines),
    length(Lines, NL), NL == 7,
    include([S]>>(length(S, 4)), Subs, Planes),
    length(Planes, NP), NP == 7,

    format("GF(2)³：8 向量、16 子空间（7 直线 + 7 平面 + 全空间）✓~n"),

    cnt_indep(NI), NI == 42,
    format("线性无关有序对：42 = (8−1)(8−2) ✓~n"),

    forall((member(P1, Planes), member(P2, Planes), P1 \= P2),
           (intersection(P1, P2, I), length(I, LI), LI == 2)),
    format("任意两平面交恰 1 维（2 元 = 非零交）✓~n"),

    format("END ====~n").

cnt_indep(N) :-
    findall(U-V, (vec3(U), vec3(V), U \= [0,0,0], V \= [0,0,0], U \= V,
                  \+ dep_pair(U, V)), L),
    length(L, N).
