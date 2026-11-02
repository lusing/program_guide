% Chapter 23 (Prolog): conditional laws of finite Bernoulli samples, exact rationals.
% n = 4: given sum x = t, every sample point has conditional probability 1/C(4,t), free of p.

bits(0, []) :- !.
bits(N, [B|T]) :- N > 0, N1 is N-1, member(B, [0,1]), bits(N1, T).

sum_([], 0).
sum_([X|Xs], S) :- sum_(Xs, S1), S is S1 + X.

lik(Xs, P, L) :-
    length(Xs, N), sum_(Xs, S), K is N - S,
    L is P^S * (1-P)^K.

% P(X = x | T = t) with T = sum
cond(N, P, X, T, C) :-
    bits(N, X), sum_(X, T),
    lik(X, P, L),
    findall(L2, (bits(N, Y), sum_(Y, T), lik(Y, P, L2)), Ls),
    sum_(Ls, Tot),
    C is L / Tot.

% C(N,K) by enumerating bit vectors
choose(N, K, C) :-
    findall(Y, (bits(N, Y), sum_(Y, K)), L), length(L, C).

check_p(P) :-
    forall(cond(4, P, _, T, C),
           ( choose(4, T, K), C =:= 1 rdiv K )).

% P(x3 = 1 | x1 + x2 = 1) for the non-sufficient statistic x1 + x2
partial(P, R) :-
    findall(L, (bits(4, X), X = [A,B,_,_], A+B =:= 1, lik(X, P, L)), Den),
    findall(L, (bits(4, X), X = [A,B,1,_], A+B =:= 1, lik(X, P, L)), Num),
    sum_(Den, D), sum_(Num, Nn),
    R is Nn / D.

main :-
    format("==== 23 sufficiency~n"),
    maplist(check_p, [1 rdiv 3, 1 rdiv 2, 3 rdiv 4, 1 rdiv 97]),
    format("Bernoulli n=4: P(x|T=t)=1/C(4,t) for p in {1/3,1/2,3/4,1/97}: OK~n"),
    forall(member(P, [1 rdiv 3, 3 rdiv 4]),
           ( partial(P, R), R =:= P )),
    format("T'=x1+x2 leaves a p-dependent conditional law: OK~n"),
    format("END ====~n"), !.

:- initialization(main).
