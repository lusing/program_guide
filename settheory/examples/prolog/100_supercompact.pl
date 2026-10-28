:- encoding(utf8).
% 第 100 章：有限对角线交与回归函数检查。

% 子集（列表表示）。
subsetL([], _).
subsetL([H|T], L) :- member(H, L), subsetL(T, L).

% 对角线交：Δ = {ξ : ∀α<ξ, ξ ∈ X_α}（ξ=0 空真）。
in_diag(_, 0).
in_diag(Xs, Xi) :-
    Xi > 0,
    forall((between(0, 32767, A), A < Xi),
           (nth0(A, Xs, Xa), member(Xi, Xa))).

diag_inter(Xs, N, D) :-
    findall(Xi, (between(0, N, Xi), Xi < N, in_diag(Xs, Xi)), D).

% 前段锥序列：X_α = {0,...,α}。
init_seq(N, Xs) :- findall(S, (between(0, N, K), K < N,
                                findall(X, (between(0, K, X)), S)), Xs).

% 常序列：X_α = 全集。
const_seq(N, Xs) :- findall(S, (between(0, N, K), K < N,
                                findall(X, (between(0, N, X), X < N), S)), Xs).

% 回归函数 f = min。
min2(A, B, M) :- (A =< B -> M = A ; M = B).
fmin([H|T], M) :- foldl(min2, T, H, M).

main :-
    format("==== 100~n"),
    init_seq(3, I3),
    diag_inter(I3, 3, DI),
    DI == [0],
    const_seq(3, C3),
    diag_inter(C3, 3, DC),
    DC == [0, 1, 2],
    fmin([1, 2], 1),
    fmin([0, 1, 2], 0),
    fmin([2], 2),
    subsetL([1, 2], [0, 1, 2]),
    \+ subsetL([3], [0, 1, 2]),
    format("前段锥对角线交 {0}、常序列给全集；f=min 三样本~n", []),
    writeln("END ====").
