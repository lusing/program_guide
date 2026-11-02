:- encoding(utf8).
% 第 24 章 Prolog：Markov 链 n 步转移与平稳分布（有理数）。
:- initialization(main).

% 矩阵 = 行列表；有理数用 rdiv。
mmul(A, B, C) :-
    transpose_(B, BT),
    findall(Row, (member(R, A), findall(V, (member(Col, BT), dot(R, Col, V)), Row)), C).
dot(Xs, Ys, S) :- foldl([X, Y, A0, A]>>(A is A0 + X*Y), Xs, Ys, 0, S).
transpose_([[]|_], []) :- !.
transpose_(M, [H|T]) :- findall(X, member([X|_], M), H),
    findall(R, member([_|R], M), M1), transpose_(M1, T).
mpow(_, 0, I) :- !, I = [[1,0],[0,1]].
mpow(P, N, R) :- N > 0, N1 is N-1, mpow(P, N1, R1), mmul(R1, P, R).

p2([[A, B], [C, D]]) :- A is 4 rdiv 5, B is 1 rdiv 5, C is 3 rdiv 10, D is 7 rdiv 10.

% 两状态链平稳分布：π0 = b/(a+b)，a=P01，b=P10
stat2([[_, A], [B, _]], [P0, P1]) :- P0 is B/(A+B), P1 is A/(A+B).

row_vec_mul([V0, V1], [[A,B],[C,D]], [R0, R1]) :- R0 is V0*A + V1*C, R1 is V0*B + V1*D.

% 5 连正面：状态 0..4，E_s = 1 + (E_{s+1} + E_0)/2, E_5 = 0；闭式 E_s = 2^6 − 2^{s+1}
e5(S, E) :- E is 2**6 - 2**(S+1).

% 移动区间（typewriter）：第 n 项 (n>=1) 层 k=floor(log2 n)，i=n-2^k，区间 [i/2^k,(i+1)/2^k]
level(N, K) :- level_(N, 0, K).
level_(N, K0, K) :- N1 is 2**(K0+1), ( N < N1 -> K = K0 ; K1 is K0+1, level_(N, K1, K) ).
inter(N, Lo, Hi) :- level(N, K), I is N - 2**K, Lo is I rdiv 2**K, Hi is (I+1) rdiv 2**K.
cover(N, S) :- inter(N, Lo, Hi), S >= Lo, S =< Hi.
len(N, L) :- inter(N, Lo, Hi), L is Hi - Lo.

main :-
    format("==== 24 markov_chains~n"),
    p2(P), stat2(P, Pi), Pi = [PA, PB], PA =:= 3 rdiv 5, PB =:= 2 rdiv 5,
    row_vec_mul(Pi, P, [PC, PD]), PC =:= PA, PD =:= PB,
    % P^7 = P^3 P^4（Chapman-Kolmogorov）
    mpow(P, 3, P3), mpow(P, 4, P4), mpow(P, 7, P7), mmul(P3, P4, P34), P7 == P34,
    % P^n = Pi + (1/2)^n (I - Pi)
    Lam is 1 rdiv 2,
    mpow(P, 6, P6), P6 = [[X00, X01], _],
    Pi = [Q0, Q1],
    X00 =:= Q0 + Lam**6*(1 - Q0), X01 =:= Q1 + Lam**6*(0 - Q1),
    format("two-state chain: pi=(3/5,2/5), Chapman-Kolmogorov, P^n formula: OK~n"),
    % 5 连正面
    e5(0, E0), E0 =:= 62,
    forall(between(0, 4, S), (e5(S, ES), e5(0, E00), (S < 4 -> S1 is S+1, e5(S1, ES1) ; ES1 = 0),
                              ES =:= 1 + (ES1 + E00)/2)),
    format("5-run chain: E[T] = 62: OK~n"),
    % 移动区间：区间长度 2^-k 趋于 0（P(|Z_n|>eps) -> 0），但每层都覆盖每个 s
    forall(between(1, 63, N), (len(N, L), level(N, K), L =:= 1 rdiv 2**K)),
    len(63, L63), L63 =:= 1 rdiv 32,
    forall(member(Sv, [0, 1 rdiv 3, 2 rdiv 3, 1]),
           ( findall(K, (between(0, 5, K), N0 is 2**K, N1 is 2**(K+1)-1,
                         between(N0, N1, N), cover(N, Sv)), Ks),
             sort(Ks, Us), Us == [0,1,2,3,4,5] )),
    format("typewriter: |I_n| = 2^-k -> 0 yet each level covers every s: OK~n"),
    format("END ====~n"), !.
