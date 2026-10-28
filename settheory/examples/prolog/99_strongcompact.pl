:- encoding(utf8).
% 第 99 章：有限理论任意有限子集可满足性检查。

% 文字与子句（变元为自然数）。
lit_sat(V, pos(P)) :- member(P-true, V).
lit_sat(V, neg(P)) :- member(P-false, V).

clause_sat(V, C) :- member(L, C), lit_sat(V, L).

theory_sat(V, T) :- forall(member(C, T), clause_sat(V, C)).

% 全赋值枚举（n 个变元）。
val([], 0).
val([P-B|Rest], N) :-
    N > 0, N1 is N - 1, P is N1,
    (B = true ; B = false),
    val(Rest, N1).

sat(T, N) :- val(V, N), theory_sat(V, T).

% 真·有限子集（严格小于原理论长度）的可满足性。
proper_len(S, T) :- length(S, L), length(T, M), L < M.

finite_sat(T, N) :-
    findall(C, member(C, T), Cs),
    forall((subseq(Cs, S), proper_len(S, Cs)), sat(S, N)).

subseq([], []).
subseq([_|T], S) :- subseq(T, S).
subseq([H|T], [H|S]) :- subseq(T, S).

main :-
    format("==== 99~n"),
    T1 = [[pos(0), neg(1)], [pos(1), pos(2)]],
    sat(T1, 3),
    T2 = [[pos(0)], [neg(0)]],
    \+ sat(T2, 1),
    finite_sat(T2, 1),
    format("理论 1 可满足；理论 2 {p0,¬p0} 整体不可满足~n", []),
    format("但理论 2 的每个（真）有限子集可满足——紧致性骨架账~n", []),
    writeln("END ====").
