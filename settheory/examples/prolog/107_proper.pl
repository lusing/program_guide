:- encoding(utf8).
% 第 107 章：(M,P)-泛型条件查询——反链、准稠密与相容性检查。

% 样本宇宙：extT 表（根 0 分叉到终端 1、2；3+ 空延展）。
ext_of(0, [0,1,2]) :- !.
ext_of(1, [1]) :- !.
ext_of(2, [2]) :- !.
ext_of(_, []).

% 相容：有公共延展。
compat(R, P) :- ext_of(R, ER), ext_of(P, EP), member(S, ER), member(S, EP).

% 反链：两两不相容。
is_antichain(A) :- forall((member(P,A), member(Q,A), P \= Q), \+ compat(P, Q)).

% A 在 q 之下准稠密。
predense_below(A, Q) :-
    ext_of(Q, EQ),
    forall(member(R, EQ), (member(P, A), compat(R, P))).

% (M,P)-泛型条件证书。
generic_cond(As, Q) :- forall(member(A, As), predense_below(A, Q)).

% 更强条件：q 的延展含于 p 的延展（q 强于 p）。
stronger(Q, P) :- ext_of(Q, EQ), ext_of(P, EP), subsetL(EQ, EP).

subsetL([], _).
subsetL([H|T], L) :- member(H, L), subsetL(T, L).

% 泛型搜索。
search_generic(As, Max, Qs) :-
    findall(Q, (between(0, Max, Q), generic_cond(As, Q)), Qs).

main :-
    format("==== 107~n"),
    % 反链正反。
    is_antichain([1,2]),
    \+ is_antichain([0,1]),
    % 准稠密正反。
    predense_below([1,2], 0),
    predense_below([1,2], 1),
    predense_below([1,2], 2),
    \+ predense_below([2], 1),
    \+ predense_below([1], 2),
    % 泛型条件正反。
    generic_cond([[1,2]], 0),
    generic_cond([[1,2]], 1),
    \+ generic_cond([[2]], 1),
    % 泛型搜索。
    search_generic([[1,2]], 2, [0,1,2]),
    search_generic([[1]], 2, [1]),
    search_generic([[1],[1,2]], 2, [1]),
    % 更强条件与证书下放。
    stronger(1, 0), stronger(2, 0),
    \+ stronger(0, 1),
    forall((between(0,2,P), between(0,2,Q),
            generic_cond([[1,2]], P), stronger(Q, P)),
           generic_cond([[1,2]], Q)),
    % 相容性样本（泛型性与相容性双查）。
    compat(0, 1), compat(0, 2), compat(1, 1), compat(2, 2),
    \+ compat(1, 2), \+ compat(2, 1),
    format("反链/准稠密/泛型正反；搜索三例；更强条件保持；相容六样本~n"),
    writeln("END ====").
