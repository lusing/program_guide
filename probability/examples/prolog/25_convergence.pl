:- encoding(utf8).
% 第 25 章 Prolog：移动区间（typewriter）反例与 Borel–Cantelli 尾界的有理数穷举。
:- initialization(main).

% 第 n 项 (n>=1)：层 k=floor(log2 n)，i=n-2^k，区间 [i/2^k,(i+1)/2^k]
level(N, K) :- level_(N, 0, K).
level_(N, K0, K) :- N1 is 2**(K0+1), ( N < N1 -> K = K0 ; K1 is K0+1, level_(N, K1, K) ).
inter(N, Lo, Hi) :- level(N, K), I is N - 2**K, Lo is I rdiv 2**K, Hi is (I+1) rdiv 2**K.
cover(N, S) :- inter(N, Lo, Hi), S >= Lo, S =< Hi.
len(N, L) :- inter(N, Lo, Hi), L is Hi - Lo.

% 在层 K 中命中 s 的项数
hits_in_level(K, S, C) :-
    N0 is 2**K, N1 is 2**(K+1)-1,
    aggregate_all(count, (between(N0, N1, N), cover(N, S)), C).
miss_in_level(K, S, C) :-
    N0 is 2**K, N1 is 2**(K+1)-1,
    aggregate_all(count, (between(N0, N1, N), \+ cover(N, S)), C).

% 独立 Bernoulli(1/n)：P(m..N 全无事件) = prod (1-1/n) = (m-1)/N
noevent(M, N, P) :- numlist(M, N, L), foldl([X, A0, A]>>(A is A0*(1 - 1 rdiv X)), L, 1, P).

% Σ_{n>=m} n^-2 <= 1/(m-1) 的有限段检验
tail_sum(M, N, S) :- numlist(M, N, L), foldl([X, A0, A]>>(A is A0 + 1 rdiv (X*X)), L, 0, S).

main :-
    format("==== 25 convergence~n"),
    forall(between(1, 255, N), (len(N, L), level(N, K), L =:= 1 rdiv 2**K)),
    format("typewriter: |I_n| = 2^-k, so P(Z_n=1) -> 0: OK~n"),
    forall(member(S, [0, 1 rdiv 3, 2 rdiv 3, 5 rdiv 7, 1]),
           forall(between(0, 9, K),
                  ( hits_in_level(K, S, H), H >= 1,
                    ( K >= 1 -> miss_in_level(K, S, Ms), Ms >= 1 ; true ) ))),
    format("every level covers every s and also misses it: limsup=1, liminf=0: OK~n"),
    forall(( member(M, [2, 5, 10]), member(N2, [M, 50, 400]) ),
           ( noevent(M, N2, P), P =:= (M-1) rdiv N2 )),
    format("independent Bern(1/n): P(no event in [m,N]) = (m-1)/N: OK~n"),
    forall(member(M, [2, 10, 100]),
           ( tail_sum(M, 3000, T), T =< 1 rdiv (M-1) )),
    format("Borel-Cantelli tail: sum_{n>=m} n^-2 <= 1/(m-1): OK~n"),
    format("END ====~n"), !.
