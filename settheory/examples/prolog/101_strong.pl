:- encoding(utf8).
% 第 101 章：有限秩层递归与见证条款查询器。

% ── 一、位编码有限秩层（宇宙 0..15，元素 = 置位位号）──
elems(X, Es) :- findall(I, (between(0, 3, I), X /\ (1 << I) =\= 0), Es).

subsetL([], _).
subsetL([H|T], L) :- member(H, L), subsetL(T, L).

level(0, []).
level(N, L) :-
    N > 0,
    N1 is N - 1,
    level(N1, Cur),
    findall(X, (between(0, 15, X), elems(X, E), subsetL(E, Cur)), L).

% ── 二、见证条款：查询某见证满足哪些条款 ──
% wit(名, crit, jκ, captured)
wit(measurable_like, 2, 3, [2]).
wit(lam3,            2, 5, [3]).
wit(three_points,    2, 5, [2, 3, 4]).
wit(four_points,     2, 6, [2, 3, 4, 5]).
wit(superstrong_w,   2, 4, [4]).

% (κ,λ)-强条款：κ≤λ、λ<j(κ)、λ 被捕获。
clause_lam_strong(W, L) :-
    wit(W, K, J, Cap),
    K =< L, L < J,
    member(L, Cap).

% 可测类似物条款：(κ,κ+1)-强。
clause_measurable_like(W) :-
    wit(W, K, J, Cap),
    J is K + 1,
    member(K, Cap).

% 超强条款：j(κ) 被捕获。
clause_superstrong(W) :-
    wit(W, _, J, Cap),
    member(J, Cap).

% 见证在 maxλ 以内是否「强」（所有 λ≥κ 都 λ-强）。
is_strong_upto(W, MaxL) :-
    wit(W, K, _, _),
    forall(between(K, MaxL, L), clause_lam_strong(W, L)).

% 反向查询：哪些见证满足给定条款。
satisfies(W, lam_strong(L))   :- clause_lam_strong(W, L).
satisfies(W, measurable_like) :- clause_measurable_like(W).
satisfies(W, superstrong)     :- clause_superstrong(W).

main :-
    format("==== 101~n"),
    level(1, L1), L1 == [0],
    level(2, L2), L2 == [0, 1],
    level(3, L3), L3 == [0, 1, 2, 3],
    level(4, L4), L4 == [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15],
    length(L1, 1), length(L2, 2), length(L3, 4), length(L4, 16),
    % 层包含链 V_n ⊆ V_{n+1}。
    forall((between(0, 3, N), succ(N, N1), level(N, A), level(N1, B)),
           subsetL(A, B)),
    % 逐条查询五个见证的条款满足表。
    findall(W-3, clause_lam_strong(W, 3), L3s),
    L3s == [lam3-3, three_points-3, four_points-3],
    findall(W, clause_superstrong(W), SS), SS == [superstrong_w],
    findall(W, clause_measurable_like(W), ML), ML == [measurable_like],
    % 有限捕获恒非强：每个见证都在某层断。
    forall(wit(W, K, _, _),
           (J is K + 20, \+ is_strong_upto(W, J))),
    format("层尺寸 1,2,4,16；λ=3 见证 {lam3,three_points,four_points}；超强 {superstrong_w}；~n"),
    format("可测类似物 {measurable_like}；每见证有限点亮——恒非强~n"),
    writeln("END ====").
