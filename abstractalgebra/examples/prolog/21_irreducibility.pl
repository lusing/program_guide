:- encoding(utf8).
% 第 21 章 · 不可约性判别 —— Prolog 通道
%
% Eisenstein 检查 + 模 p 归约 + Φ_p(x+1) 系数。

prime_m(M) :- integer(M), M >= 2,
    \+ (between(2, M, D), D * D =< M, M mod D =:= 0).

% Eisenstein：系数低位在前；P 先限定范围再判素（避开未实例化比较）
eisenstein_p(F, P) :-
    between(2, 50, P),
    prime_m(P),
    last(F, An), An mod P =\= 0,
    init(F, Init),
    forall(member(C, Init), C mod P =:= 0),
    F = [A0 | _], A0 mod (P * P) =\= 0.

init(F, I) :- append(I, [_], F).

binom(N, 0, 1) :- !.
binom(N, N, 1) :- !.
binom(N, K, C) :- K > 0, K < N,
    K1 is K - 1, binom(N, K1, C1),
    C is C1 * (N - K1) // K.

eval2(F, A, V) :-
    reverse(F, FR),
    foldl([C, Acc0, Acc1]>>(Acc1 is (Acc0 * A + C) mod 2), FR, 0, V).

main :-
    format("==== 21 不可约性判别~n"),

    % Eisenstein 正反案
    eisenstein_p([2, -4, 0, 0, 0, 1], 2),       % x⁵−4x+2
    \+ eisenstein_p([1, 2, 1], _),              % (x+1)² 落空
    format("Eisenstein：x⁵−4x+2 命中 p = 2；(x+1)² 正确落空 ✓~n"),

    % Φ₃(x+1) = x²+3x+3（p = 3 命中）
    eisenstein_p([3, 3, 1], 3),
    format("Φ₃(x+1) = x²+3x+3：Eisenstein p = 3 命中 ✓~n"),

    % 二项系数 C(p,k) 被 p 整除
    forall((member(P, [3, 5, 7]), Pm is P - 1, between(1, Pm, K)),
           (binom(P, K, C), C mod P =:= 0)),
    forall(member(P, [3, 5, 7]),
           (binom(P, P, C), C mod P =\= 0)),
    format("C(p,k) 整除性：p = 3,5,7 全档 ✓~n"),

    % 模 p 归约：x³+x+1 (mod 2) 无根
    F2 = [1, 1, 0, 1],
    \+ (between(0, 1, A), eval2(F2, A, V), V =:= 0),
    format("模 2 归约：x³+x+1 无根 ⟹ 不可约（deg 3 判据）✓~n"),

    format("END ====~n").
