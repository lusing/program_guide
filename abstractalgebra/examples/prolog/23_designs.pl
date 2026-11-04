:- encoding(utf8).
% 第 23 章 · 一个数学旅程 —— Prolog 通道
%
% CLPFD 幻方求解 + 拉丁方构造 + Fano 平面。

:- use_module(library(clpfd)).

magic_sum(N, S) :- S is N * (N * N + 1) // 2.

% CLPFD 幻方：3 阶
magic3(L) :-
    L = [A, B, C, D, E, F, G, H, I],
    L ins 1..9,
    all_distinct(L),
    magic_sum(3, S),
    A + B + C #= S,
    D + E + F #= S,
    G + H + I #= S,
    A + D + G #= S,
    B + E + H #= S,
    C + F + I #= S,
    A + E + I #= S,
    C + E + G #= S,
    label(L).

% 拉丁方：4 阶 CLPFD（向量表示，行列约束）
latin4(L) :-
    length(L, 16), L ins 1..4,
    rows_of(L, Rows), maplist(all_distinct, Rows),
    cols_of(L, Cols), maplist(all_distinct, Cols),
    label(L).

rows_of(L, Rows) :-
    findall(R, (between(1, 4, I), row_i(L, I, R)), Rows).
row_i(L, I, R) :-
    findall(X, (between(1, 4, J), IX is (I - 1) * 4 + J, nth1(IX, L, X)), R).
cols_of(L, Cols) :-
    findall(C, (between(1, 4, J), col_j(L, J, C)), Cols).
col_j(L, J, C) :-
    findall(X, (between(1, 4, I), IX is (I - 1) * 4 + J, nth1(IX, L, X)), C).

fano_lines([[0,1,3], [1,2,4], [2,3,5], [3,4,6], [4,5,0], [5,6,1], [6,0,2]]).

main :-
    format("==== 23 一个数学旅程~n"),

    % 幻方：CLPFD 直接求解
    magic3([A, B, C, D, E, F, G, H, I]),
    format("3 阶幻方（CLPFD 首解）：~d ~d ~d / ~d ~d ~d / ~d ~d ~d~n",
           [A, B, C, D, E, F, G, H, I]),
    findall(_, magic3(_), All), length(All, 8),
    format("3 阶幻方恰 8 解（含旋转反射）✓~n"),

    % 拉丁方构造
    latin4(Lat),
    nth1(1, Lat, R11), nth1(2, Lat, R12), nth1(3, Lat, R13), nth1(4, Lat, R14),
    format("4 阶拉丁方（CLPFD）：首行 = ~d ~d ~d ~d ✓~n", [R11, R12, R13, R14]),

    % Fano 平面：21 对点各恰共一线
    fano_lines(Lines),
    forall((between(0, 6, P1), between(0, 6, P2), P1 < P2),
           (include([L]>>(member(P1, L), member(P2, L)), Lines, Cs),
            length(Cs, 1))),
    format("Fano 平面：21 对点各恰共一线（STS(7)）✓~n"),

    format("END ====~n").
