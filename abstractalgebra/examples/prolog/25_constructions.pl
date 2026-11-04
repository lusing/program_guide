:- encoding(utf8).
% 第 25 章 · 欧氏作图 —— Prolog 通道
%
% 2 的幂谱 + 费马数 + 有理根候选穷举。

is_pow2(1).
is_pow2(N) :- N > 1, N mod 2 =:= 0, N2 is N // 2, is_pow2(N2).

prime_m(M) :- M >= 2, \+ (between(2, M, D), D * D =< M, M mod D =:= 0).

fermat(K, F) :- F is 2 ^ (2 ^ K) + 1.

% 三等分角：q³·f(p/q) = 8p³ − 6p·q² − q³ = 0 无解（p | 1、q | 8）
no_rational_root :-
    \+ (pm1(P), q8(Q), 8 * P ^ 3 - 6 * P * Q ^ 2 - Q ^ 3 =:= 0).

pm1(P) :- member(P, [1, -1]).
q8(Q) :- member(Q, [1, -1, 2, -2, 4, -4, 8, -8]).

main :-
    format("==== 25 欧氏作图~n"),

    % 2 的幂谱
    forall(member(N, [3, 5, 6, 7, 9, 11, 12, 14]), \+ is_pow2(N)),
    forall(member(N, [1, 2, 4, 8, 16, 32, 64]), is_pow2(N)),
    format("2 的幂谱：{3,5,6,7,...} 全排除；{1,2,4,8,16,32,64} 全入选 ✓~n"),

    % 费马素数
    forall(member(K, [0, 1, 2, 3, 4]), (fermat(K, F), prime_m(F))),
    fermat(5, F5), F5 =:= 641 * 6700417, \+ prime_m(F5),
    format("费马素数 F₀..F₄ 全素；F₅ = 641 × 6700417 非素 ✓~n"),

    % 有理根穷举
    no_rational_root,
    format("三等分角：8x³−6x−1 的 16 个有理候选全落空 ⟹ 不可约（次数 3）✓~n"),

    format("END ====~n").
