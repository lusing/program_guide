:- encoding(utf8).
% 06_inclusion_exclusion.pl —— 第 06 章：容斥、错排与组合恒等式。

perm([], []).
perm(L, [X | P]) :- select(X, L, R), perm(R, P).
perms4(Ps) :- findall(P, perm([1,2,3,4], P), Ps).
no_fixed(P) :- \+ (nth1(I, P, I)).

combo(_, 0, []).
combo([X | Xs], K, [X | C]) :- K > 0, K1 is K - 1, combo(Xs, K1, C).
combo([_ | Xs], K, C) :- K > 0, combo(Xs, K, C).

fact(0, 1) :- !.
fact(N, F) :- N > 0, N1 is N - 1, fact(N1, G), F is N * G.

choose(N, K, C) :-
    fact(N, FN), fact(K, FK), NK is N - K, fact(NK, FNK),
    C is FN // (FK * FNK).

check_derangement :-
    perms4(Ps), length(Ps, 24),
    include(no_fixed, Ps, Ds), length(Ds, 9),
    Closed is 24 * (1 - 1 + 1 rdiv 2 - 1 rdiv 6 + 1 rdiv 24),
    Closed =:= 9,
    format("derangements n=4: 24 perms, D_4=9, closed form agrees: OK~n").

check_balls :-
    findall(Assign, (between(1,3,A), between(1,3,B),
                     between(1,3,C), between(1,3,D),
                     Assign = [A,B,C,D]), All),
    length(All, 81),
    include(all_bins, All, Full), length(Full, 36),
    IE is 81 - 3 * 16 + 3 * 1,
    IE =:= 36,
    format("balls n=3,k=4: 81 assignments, full-cover 36 = IE: OK~n").

all_bins(L) :- sort(L, S), length(S, 3).

check_three_events :-
    findall(X, between(1, 8, X), Omega),
    include(in_any, Omega, Union), length(Union, U),
    IE is 4 + 4 + 4 - 2 - 2 - 2 + 1,
    U =:= IE,
    format("3-event IE on 8-point space gives union size ~w: OK~n", [U]).

in_a(X) :- X >= 5.
in_b(X) :- member(X, [3, 4, 7, 8]).
in_c(X) :- member(X, [1, 4, 6, 8]).
in_any(X) :- (in_a(X) ; in_b(X) ; in_c(X)).

check_hockey :-
    findall(S, combo([0,1,2,3,4,5,6], 3, S), Subs),
    length(Subs, 35),
    findall(M, (between(2, 6, I),
                findall(S, (member(S, Subs), max_list(S, I)), Ss),
                length(Ss, M)), Counts),
    Counts = [1, 3, 6, 10, 15],
    sum_list(Counts, 35),
    format("hockey-stick max classes [1,3,6,10,15] sum to C(7,3)=35: OK~n").

check_vandermonde :-
    V is 1*1 + 3*2 + 3*1,
    V =:= 10,
    choose(5, 2, 10),
    format("Vandermonde (m,n,k)=(3,2,2): 1+6+3=10=C(5,2): OK~n").

check_order_swap :-
    choose(8, 5, L1), choose(5, 3, R1),
    choose(8, 3, L2), choose(5, 2, R2),
    L1 * R1 =:= L2 * R2,
    format("order-swap C(8,5)C(5,3)=C(8,3)C(5,2): OK~n").

main :-
    format("==== 06 inclusion_exclusion~n", []),
    check_derangement,
    check_balls,
    check_three_events,
    check_hockey,
    check_vandermonde,
    check_order_swap,
    format("END ====~n"), !.

:- initialization(main).
