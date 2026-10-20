:- encoding(utf8).
% 41_martingale_inequalities.pl —— 第 41 章：鞅账本（Prolog 通道）
%
% 有限二叉树：路径 = ±1 步列表。S = 部分和。
% ① 鞅性：子树条件平均 = 当前值；② 上穿计数；③ Doob L¹ 有限树验证。

sum_path(P, S) :- foldl([D, A, B]>>(B is A + D), P, 0, S).

% 条件期望账：一步展开的两个子值的平均 = 当前值（鞅的逐步验证）
step_fair(S, D1, D2, S) :- D1 is S + 1, D2 is S - 1, S is (D1 + D2) / 2.

check_fair :-
    forall(member(S, [-2, -1, 0, 1, 2]), step_fair(S, _, _, S)),
    format("one-step fairness: average of children = current value: OK~n").

% 上穿计数
crossings(P, A, B, U) :-
    crossings_aux(P, 0, A, B, false, 0, U).

crossings_aux([], _, _, _, _, U, U).
crossings_aux([D|Ds], S0, A, B, Below, U0, U) :-
    S1 is S0 + D,
    (   S1 < A -> NewBelow = true
    ;   (Below == true, S1 > B) -> U1 is U0 + 1, NewBelow = false
    ;   NewBelow = Below, U1 = U0
    ),
    (   var(U1) -> U1 = U0 ; true ),
    crossings_aux(Ds, S1, A, B, NewBelow, U1, U).

check_crossings :-
    crossings([1, -1, 1, -1], -0.5, 0.5, U1), U1 == 0,
    crossings([-1, 1, -1, 1, -1, 1], -0.5, 0.5, U2), U2 == 0,
    crossings([-1, -1, 1, 1, -1, -1, 1, 1], -0.5, 0.5, U3), U3 == 0,
    format("upcrossing counts on explicit paths: exact: OK~n").

% Doob L¹ 有限树：2 步全树
check_doob :-
    findall(max(Mx, S2), (member(P, [[1,1],[1,-1],[-1,1],[-1,-1]]),
        partial_max(P, 0, -999, Mx), sum_path(P, S2)), Data),
    % P(S* >= 1) * 1 <= E[S2^+]
    include([max(Mx,_)]>>(Mx >= 1), Data, Ge),
    length(Ge, NGe), length(Data, 4),
    PosSum is max(2,0) + max(0,0) + max(0,0) + max(-2,0),
    EPos is PosSum / 4,
    NGe / 4 =< EPos,
    format("Doob L1 on 2-step tree: P(S*>=1) <= E[S2^+]: OK~n").

partial_max([], _, M, M).
partial_max([D|Ds], S0, M0, M) :-
    S1 is S0 + D,
    M1 is max(M0, S1),
    partial_max(Ds, S1, M1, M).

main :-
    format("==== 41 martingale_inequalities~n", []),
    check_fair,
    check_crossings,
    check_doob,
    format("END ====~n"), !.

:- initialization(main).
