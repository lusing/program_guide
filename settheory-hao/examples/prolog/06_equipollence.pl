:- encoding(utf8).
% 第 06 章 Prolog：鸽笼穷举与配对函数的终审。
% ① 书 3.3.5 鸽笼原理：n=3 时对每个更小的目标集，穷举全部映射
%    （值元组），没有一个单射；
% ② 配对函数 f(k,n)=2^k(2n+1)−1（书 3.3.9）：m 的分解复原往返、
%    网格内单射；
% ③ 交错序列（书 3.3.7）。

% ---------- ① 鸽笼穷举 ----------
tuple(0, _, []).
tuple(N, Max, [H|T]) :- N > 0, N1 is N - 1, MaxM is Max - 1,
    between(0, MaxM, H), tuple(N1, Max, T).

no_dup(L) :- sort(L, S), length(S, Len), length(L, Len).

check_pigeonhole :-
    forall(between(0, 2, Size),                   % 目标集 {0..Size-1} ⊊ {0,1,2}
           \+ (tuple(3, Size, F), no_dup(F))),    % 不存在单射
    format("pigeonhole: no injective 3-tuple into any smaller set: OK~n").

% ---------- ② 配对函数往返 ----------
pairkn(K, N, M) :- M is 2 ^ K * (2 * N + 1) - 1.

strip_twos(Q, K, Q, K) :- Q mod 2 =\= 0, !.
strip_twos(Q0, K0, Q, K) :- Q0 mod 2 =:= 0, !,
    Q1 is Q0 // 2, K1 is K0 + 1, strip_twos(Q1, K1, Q, K).

unpair(M, K, N) :- Q0 is M + 1, strip_twos(Q0, 0, Q, K), N is (Q - 1) // 2.

check_pairing :-
    forall(between(0, 199, M),
           (unpair(M, K, N), pairkn(K, N, M2), M2 == M)),
    findall(M, (between(0, 5, K), between(0, 29, N), pairkn(K, N, M)), Ms0),
    sort(Ms0, Ms), length(Ms0, L0), length(Ms, L), L == L0,
    format("pairing: roundtrip 0..199, injective on 6x30 grid: OK~n").

% ---------- ③ 交错序列 ----------
interleave([], [], []).
interleave([A|As], [B|Bs], [A, B|Cs]) :- interleave(As, Bs, Cs).

evens_odds(Upto, Es, Os) :-
    findall(X, (between(0, Upto, X), X mod 2 =:= 0), Es),
    findall(X, (between(0, Upto, X), X mod 2 =:= 1), Os).

check_interleave :-
    evens_odds(39, Es, Os),
    interleave(Es, Os, Cs),
    numlist(0, 39, All),
    msort(Cs, Cs0), Cs0 == All,
    format("interleave: even/odd sequences merge into 0..39: OK~n").

main :-
    format("==== 06 equipollence~n"),
    check_pigeonhole,
    check_pairing,
    check_interleave,
    format("END ====~n"), !.

:- initialization(main).
