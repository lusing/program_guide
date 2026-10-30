:- encoding(utf8).
% 第 105 章：Silver 条件的偏序查询、Easton 支撑与相遇稠密集的条件链。

% 条件 = 三元组表 ((α,ξ),b)：b∈{0,1}。
lookup((A, X), [((A, X), B)|_], B) :- !.
lookup(K, [_|T], B) :- lookup(K, T, B).

has_key(K, [(K, _)|_]) :- !.
has_key(K, [_|T]) :- has_key(K, T).

% 反向包含：q ≤ p ⟺ p ⊆ q。
extC([], _).
extC([(K, B)|T], Q) :- lookup(K, Q, B), extC(T, Q).

% 相容。
agree(P, Q) :-
    forall((member((K, B1), P), lookup(K, Q, B2)), B1 == B2).

% 合并：q 中去掉已覆盖键后拼接。
merge(P, Q, R) :- include(not_covered(P), Q, Q1), append(P, Q1, R).
not_covered(P, (K, _)) :- \+ has_key(K, P).

% 支撑：α-坐标全体（去重）。
support(P, S) :-
    findall(A, member(((A, _), _), P), S0),
    remove_dup(S0, S).
remove_dup([], []).
remove_dup([H|T], [H|R]) :- exclude(=(H), T, T1), remove_dup(T1, R).

% Easton 条款：|spt ∩ μ| < μ。
easton_ok(P, Mu) :-
    support(P, S),
    findall(A, (member(A, S), A < Mu), Sub),
    length(Sub, N), N < Mu.

% 相遇稠密集的条件链（Task 20 Step 2 指定件：输出链）。
chain_meet([], P, P).
chain_meet([K-B|Ts], P, R) :-
    ( has_key(K, P) -> P1 = P
    ; append(P, [(K, B)], P1) ),
    chain_meet(Ts, P1, R).

main :-
    format("==== 105~n"),
    % 偏序律样本。
    extC([((0,0),1)], [((0,0),1), ((1,2),0)]),
    extC([((0,0),1), ((1,2),0)],
         [((0,0),1), ((1,2),0), ((3,5),1)]),
    extC([((0,0),1)], [((0,0),1), ((1,2),0), ((3,5),1)]),
    \+ extC([((0,0),1), ((9,9),0)], [((0,0),1)]),
    % 相容与合并。
    agree([((0,0),1)], [((1,2),0)]),
    \+ agree([((0,0),1)], [((0,0),0)]),
    merge([((0,0),1)], [((1,2),0)], R1),
    R1 == [((0,0),1), ((1,2),0)],
    % Easton 支撑正反样本。
    easton_ok([((0,0),1), ((1,2),0)], 3),
    \+ easton_ok([((0,0),1), ((1,2),0)], 2),
    easton_ok([((0,0),1)], 2),
    \+ easton_ok([((0,0),1)], 1),
    % 相遇条件链：目标序列逐个击中。
    findall(((A, X)-0), (between(0, 2, A), between(0, 1, X)), Ts),
    chain_meet(Ts, [], R),
    length(R, 6),
    forall((between(0, 2, A), between(0, 1, X)), lookup((A, X), R, 0)),
    format("偏序律/相容/合并/Easton 支撑正反；条件链相遇 6 目标~n"),
    writeln("END ====").
