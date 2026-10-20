:- encoding(utf8).
% 02_axioms.pl —— 第 02 章：公理与定律（Prolog 穷举通道）
%
% Ω = {1,2,3,4} 的玩具概率空间（显式逐点概率）；程序枚举
% ① 16 个子集验证补律与单调性（全部包含对）；② 全部
% (A,B) 对（256 组）验证容斥二项版；③ De Morgan 律。

% 逐点概率：p(1)=1/8, p(2)=1/8, p(3)=1/4, p(4)=1/2（和 = 1）
p_prob(1, 1 rdiv 8).
p_prob(2, 1 rdiv 8).
p_prob(3, 1 rdiv 4).
p_prob(4, 1 rdiv 2).

% 子集表示为列表；prob 计算 P(A)
prob([], 0).
prob([X | Xs], P) :- p_prob(X, Q), prob(Xs, R), P is Q + R.

subsets([], []).
subsets([X | Xs], [X | S]) :- subsets(Xs, S).
subsets([_X | Xs], S) :- subsets(Xs, S).

compl(Omega, A, C) :- subtract(Omega, A, C).

subseteq([], _).
subseteq([X | Xs], B) :- member(X, B), subseteq(Xs, B).

union_list([], []).
union_list([A | As], U) :- union_list(As, V), union(A, V, U).

inter_list([], Omega, Omega) :- !.
inter_list([A | As], U0, U) :- intersection(U0, A, U1), inter_list(As, U1, U).

% ① 补律 + 单调性：全部 16 子集 / 全部包含对
check_complement :-
    Omega = [1, 2, 3, 4],
    forall((subsets(Omega, A), compl(Omega, A, Ac)),
           (prob(A, P), prob(Ac, Q), 1 is P + Q)),
    format("complement law: all 16 subsets P(A)+P(Ac)=1: OK~n").

check_monotone :-
    Omega = [1, 2, 3, 4],
    forall((subsets(Omega, A), subsets(Omega, B), subseteq(A, B)),
           (prob(A, P), prob(B, Q), P =< Q)),
    format("monotonicity: all subset pairs P(A)<=P(B): OK~n").

% ② 容斥二项版：全部 (A,B) 对（256 组）
check_inclusion_exclusion :-
    Omega = [1, 2, 3, 4],
    forall((subsets(Omega, A), subsets(Omega, B)),
           (union(A, B, AuB), inter_list([A, B], Omega, AiB),
            prob(A, P), prob(B, Q), prob(AiB, R), prob(AuB, U),
            U is P + Q - R)),
    format("inclusion-exclusion: all 256 pairs P(AuB)=P(A)+P(B)-P(AB): OK~n").

% ③ De Morgan：(A∪B)^c = A^c ∩ B^c 与 (A∩B)^c = A^c ∪ B^c
same_set(A, B) :- msort(A, X), msort(B, Y), X == Y.

check_demorgan :-
    Omega = [1, 2, 3, 4],
    forall((subsets(Omega, A), subsets(Omega, B)),
           (union(A, B, AuB), compl(Omega, AuB, L1),
            compl(Omega, A, Ac), compl(Omega, B, Bc),
            inter_list([Ac, Bc], Omega, R1),
            same_set(L1, R1),
            inter_list([A, B], Omega, AiB), compl(Omega, AiB, L2),
            union_list([Ac, Bc], R2),
            same_set(L2, R2))),
    format("De Morgan: complement flips union/intersection (256 pairs): OK~n").

main :-
    format("==== 02 axioms~n", []),
    check_complement,
    check_monotone,
    check_inclusion_exclusion,
    check_demorgan,
    format("END ====~n"), !.

:- initialization(main).
