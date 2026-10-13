:- encoding(utf8).
% 第 08 章 奇异基数：几乎不交族的判定与支配关系
%
% 1. almost_disjoint(F, G)：除有限多处外 F ≠ G（有限域穷举）；
% 2. eventually_dominates(Psi, Phi)：Psi 最终支配 Phi；
% 3. 范数的降链终止检查。

% ---------- 一、几乎不交（有限域：尾部无碰撞） ----------

% tail_distinct(F, G, B)：从 B 起逐点不同
tail_distinct(_, _, B, N) :- B >= N.
tail_distinct(F, G, B, N) :-
    B < N,
    nth0(B, F, X), nth0(B, G, Y),
    X \= Y,
    B1 is B + 1,
    tail_distinct(F, G, B1, N).

almost_disjoint(F, G) :-
    length(F, N), length(G, N),
    N1 is N - 1,
    between(0, N1, B),          % 至少检查一位（排除 B=N 的平凡真）
    tail_distinct(F, G, B, N), !.

% ---------- 二、最终支配 ----------

tail_dominates(_, _, B, N) :- B >= N.
tail_dominates(Psi, Phi, B, N) :-
    B < N,
    nth0(B, Psi, X), nth0(B, Phi, Y),
    X > Y,
    B1 is B + 1,
    tail_dominates(Psi, Phi, B1, N).

eventually_dominates(Psi, Phi) :-
    length(Psi, N), length(Phi, N),
    N1 is N - 1,
    between(0, N1, B),
    tail_dominates(Psi, Phi, B, N), !.

% ---------- 三、范数：降链长度（逐点 -1 到零） ----------

dec_all([], []).
dec_all([X|Xs], [Y|Ys]) :- Y is max(X - 1, 0), dec_all(Xs, Ys).

all_zero(L) :- forall(member(X, L), X == 0).

norm_chain(L, 0) :- all_zero(L), !.
norm_chain(L, S1) :-
    dec_all(L, L1),
    norm_chain(L1, S),
    S1 is S + 1.

% ---------- main ----------

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 08 奇异基数：几乎不交与支配~n"),
    (   almost_disjoint([1,5,2,9,3], [2,6,7,8,4]) ->
        format("  [1,5,2,9,3] 与 [2,6,7,8,4]：几乎不交 ✓~n")
    ;   format("  （错误）~n") ),
    (   almost_disjoint([1,2,3], [1,2,4]) ->
        format("  [1,2,3] 与 [1,2,4]：几乎不交 ✓（只在尾部分离）~n")
    ;   format("  （错误）~n") ),
    (   almost_disjoint([1,2,3], [1,2,3]) ->
        format("  自身与自身几乎不交（错误！尾恒撞）~n")
    ;   format("  f 与自身非几乎不交 ✓（尾恒撞）~n") ),
    (   eventually_dominates([2,6,7,8,4], [1,5,2,9,3]) ->
        format("  [2,6,7,8,4] 最终支配 [1,5,2,9,3] ✓~n")
    ;   format("  （错误）~n") ),
    norm_chain([3,1,4,1,5], S),
    format("  [3,1,4,1,5] 的降链长度 = ~w（范数的有限代理）~n", [S]),
    format("  Silver 链条：几乎不交族 + Fodor + 范数归纳。~n"),
    format("END ====~n").
