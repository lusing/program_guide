:- encoding(utf8).
% 第 103 章：Lévy 条件的支撑相容性与稠密扩展查询。

% 条件 = 三元组表 (α, n, β)（键 (α,n) 无重复由插入侧保证）。
lookup((A, N), [(A, N, B)|_], B) :- !.
lookup(K, [_|T], B) :- lookup(K, T, B).

has_key((A, N), [(A, N, _)|_]) :- !.
has_key(K, [_|T]) :- has_key(K, T).

% 支撑相容：公共键上取值一致。
compat(P, Q) :-
    forall((member((A, N, B1), P), lookup((A, N), Q, B2)), B1 == B2).

% 书式新鲜槽号：n₀ = 1 + max{已用 n}。
fresh_n(L, P, N0) :-
    findall(N, (member((A, N, _), P), A == L), Ns),
    ( Ns == [] -> N0 = 1 ; max_list(Ns, M), N0 is M + 1 ).

% 稠密扩展：q = p ∪ {(λ, n₀, β)}。
extend_dense(L, Beta, P, Q) :-
    fresh_n(L, P, N0),
    append(P, [(L, N0, Beta)], Q).

% 稠密性核查：扩展后相容且含目标项。
dense_ok(L, Beta, P) :-
    extend_dense(L, Beta, P, Q),
    compat(P, Q),
    lookup((L, _), Q, Beta).

main :-
    format("==== 103~n"),
    % 样本相容/不相容。
    compat([(2,0,1)], [(3,1,2)]),
    \+ compat([(2,0,1)], [(2,0,0)]),
    % 新鲜槽号三样本（与 Julia/Python 对拍）。
    fresh_n(2, [(2,0,1)], 1),
    fresh_n(2, [(2,5,0)], 6),
    fresh_n(3, [(2,0,1)], 1),
    % 稠密性核查：全体 (λ,β) × 样本条件。
    forall((between(1, 4, L), between(0, 3, B), B < L),
           dense_ok(L, B, [(2,0,1), (3,1,2)])),
    % 贪心相遇：对稠密目标序列逐个扩展（定理 2.2 机制）。
    findall((L, B), (between(1, 4, L), between(0, 3, B), B < L), Targets),
    greedy(Targets, [], G),
    % f_λ 满射还原。
    forall((between(1, 4, L), between(0, 3, B), B < L),
           (member((L, _, B), G))),
    format("相容/不相容样本；n₀=1+max 全核验；贪心相遇后 f_λ 满射——λ 可数化~n"),
    writeln("END ====").

greedy([], P, P).
greedy([(L, B)|Ts], P, G) :-
    extend_dense(L, B, P, P1),
    greedy(Ts, P1, G).
