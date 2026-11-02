:- encoding(utf8).
% 17_joint_distributions.pl —— 第 17 章：有限联合表（Prolog 穷举，有理数精确）
%
% ① 联合表 p(X,Y)：归一、边际化（aggregate_all）；
% ② 条件分布 p(y|x) 归一，P(Y=2|X=0)=1/2；
% ③ 独立判定：该表边际均匀但不独立；乘积表独立；
% ④ 多项分布 n=4：全部格点和为 1，N1 边际 = 二项。

p(0,0, 1 rdiv 12). p(0,1, 1 rdiv 12). p(0,2, 1 rdiv 6).
p(1,0, 1 rdiv 12). p(1,1, 1 rdiv 6).  p(1,2, 1 rdiv 12).
p(2,0, 1 rdiv 6).  p(2,1, 1 rdiv 12). p(2,2, 1 rdiv 12).

pr(X, Y, P) :- p(X, Y, E), P is E.

total(T) :- aggregate_all(sum(P), pr(_, _, P), T).
marg_x(X, M) :- aggregate_all(sum(P), pr(X, _, P), M).
marg_y(Y, M) :- aggregate_all(sum(P), pr(_, Y, P), M).
cond_y_given_x(Y, X, C) :- pr(X, Y, P), marg_x(X, M), C is P / M.

independent :-
    \+ ( pr(X, Y, P), marg_x(X, MX), marg_y(Y, MY), P =\= MX * MY ).

check_table :-
    total(T), T =:= 1,
    forall(member(X, [0,1,2]), (marg_x(X, M), M =:= 1 rdiv 3)),
    forall(member(Y, [0,1,2]), (marg_y(Y, M), M =:= 1 rdiv 3)),
    format("① joint table: total 1, both marginals uniform 1/3: OK~n").

check_cond :-
    forall(member(X, [0,1,2]),
           ( aggregate_all(sum(C), cond_y_given_x(_, X, C), S), S =:= 1 )),
    cond_y_given_x(2, 0, C), C =:= 1 rdiv 2,
    format("② conditional pmfs normalise; P(Y=2|X=0)=1/2: OK~n").

check_indep :-
    \+ independent,
    % 乘积表：独立
    findall(X-Y-Q, (member(X,[0,1,2]), member(Y,[0,1,2]),
                    marg_x(X,MX), marg_y(Y,MY), Q is MX*MY), L),
    length(L, 9),
    aggregate_all(sum(Q), member(_-_-Q, L), S), S =:= 1,
    % 具体违反点：p(0,2)=1/6 ≠ 1/9
    pr(0, 2, P), P =\= 1 rdiv 9,
    format("③ independence test: table dependent (1/6 ≠ 1/9), product table sums to 1: OK~n").

% ④ 多项分布 n=4, p=(1/2,1/3,1/6)
fact(0, 1) :- !.
fact(N, F) :- N1 is N - 1, fact(N1, F1), F is N * F1.
multinom(K1, K2, K3, P) :-
    N is K1 + K2 + K3, fact(N, FN), fact(K1, A), fact(K2, B), fact(K3, C),
    P is FN / (A * B * C) * (1 rdiv 2)^K1 * (1 rdiv 3)^K2 * (1 rdiv 6)^K3.
cell(K1, K2, K3) :- between(0, 4, K1), between(0, 4, K2), K3 is 4 - K1 - K2, K3 >= 0.
choose(N, K, C) :- fact(N, A), fact(K, B), M is N - K, fact(M, D), C is A / (B * D).

check_multinomial :-
    aggregate_all(sum(P), (cell(A,B,C), multinom(A,B,C,P)), T), T =:= 1,
    forall(between(0, 4, K1),
           ( aggregate_all(sum(P), (cell(K1,B,C), multinom(K1,B,C,P)), M),
             choose(4, K1, Ch), R is 4 - K1,
             M =:= Ch * (1 rdiv 2)^K1 * (1 rdiv 2)^R )),
    format("④ multinomial n=4: cells sum to 1, N1 marginal = Bin(4,1/2): OK~n").

main :-
    format("==== 17 joint distributions~n"),
    check_table, check_cond, check_indep, check_multinomial,
    format("END ====~n"), !.

:- initialization(main).
