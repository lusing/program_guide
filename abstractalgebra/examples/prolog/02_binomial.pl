:- encoding(utf8).
% 第 02 章 · 二项式定理与复数 —— Prolog 通道
%
% 帕斯卡三角的表驱动记忆化 + 欧拉函数与 Σ_{d∣n} φ(d) = n。

:- table ch/3.

% ---------- 帕斯卡恒等式直译（表驱动记忆化，避免指数级重算） ----------
ch(0, 0, 1) :- !.
ch(N, 0, 1) :- !, N > 0.
ch(N, N, 1) :- !, N > 0.
ch(N, K, C) :-
    N > 0, K > 0, K < N,
    N1 is N - 1, K1 is K - 1,
    ch(N1, K1, C1),
    ch(N1, K, C2),
    C is C1 + C2.

% 行和：Σ_k C(n,k) = 2ⁿ
row_sum(N, S) :-
    findall(C, (between(0, N, K), ch(N, K, C)), Cs),
    sum_list(Cs, S).

% ---------- 因数与欧拉函数 ----------
divisor(D, N) :- between(1, N, D), N mod D =:= 0.

% B = 0 时答案 G = A（G 已知且 ≠ A 则失败——决不能落到 mod 0）
gcd(A, 0, G) :- !, G = A.
gcd(A, B, G) :- B > 0, C is A mod B, gcd(B, C, G).

totient(N, Phi) :-
    N > 0,
    aggregate_all(count, (between(1, N, K), gcd(N, K, 1)), Phi).

main :-
    format("==== 02 二项式定理与复数~n"),

    % 帕斯卡行和 = 2ⁿ（n ≤ 20）
    forall(between(0, 20, N),
           ( row_sum(N, S), S =:= 2 ^ N )),
    format("帕斯卡行和 Σ_k C(n,k) = 2ⁿ：n ≤ 20 全部成立（表驱动记忆化）✓~n"),

    % 帕斯卡恒等式抽查：C(n+1,k+1) = C(n,k) + C(n,k+1)
    forall((between(1, 15, N), Nm1 is N - 1, between(0, Nm1, K)),
           ( Kp1 is K + 1, Np1 is N + 1,
             ch(N, K, C1),
             ch(N, Kp1, C2),
             ch(Np1, Kp1, C),
             C =:= C1 + C2 )),
    format("帕斯卡恒等式 C(n+1,k+1) = C(n,k) + C(n,k+1)：n ≤ 15 全数对成立 ✓~n"),

    % Σ_{d∣n} φ(d) = n（n ≤ 60）
    forall(between(1, 60, N),
           ( findall(Phi, (divisor(D, N), totient(D, Phi)), Phis),
             sum_list(Phis, N) )),
    format("Σ_{d∣n} φ(d) = n：n ≤ 60 全部成立 ✓~n"),

    format("END ====~n").
