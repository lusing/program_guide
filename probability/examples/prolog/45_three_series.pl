:- encoding(utf8).
% 第 45 章 Prolog：三级数与极大不等式的精确判决（rdiv 全程）。
% ① 三账引擎：收敛候选 ±1/k（(c) 有界——望远镜证书）与
%    发散候选 (-1)^k/⌊√k⌋（幅值平方和 = 调和型发散——(c) 发散）；
% ② Kolmogorov 极大不等式的穷举判决：2^12 条 ±1 路径上
%    P(max_{k<=12}|S_k| >= 7) = 计数/4096 <= 12/7^2；
% ③ Feller 条件的精确分数表。
:- initialization(main).

% 整数平方根（floor，穷举版）
isqrt(N, R) :- between(0, N, R), R * R =< N, (R + 1) * (R + 1) > N, !.

% 收敛候选：v_k = (-1)^k / k（k 从 1 起）
conv_v(K, V) :- K1 is K + 1, S is (K1 mod 2) * 2 - 1, V is S rdiv K1.

% 发散候选：w_k = (-1)^k / floor(sqrt(k))（幅值平方和 Σ 1/⌊√k⌋² 发散）
div_v(K, W) :- K1 is K + 1, isqrt(K1, R), R1 is max(R, 1),
               S is (K1 mod 2) * 2 - 1, W is S rdiv R1.

% 三账部分和：A = 越线计数，B = 截尾和，C = 截尾平方和
three_account(Gen, N, D, A, B, C) :-
    findall(X, (between(1, N, K), call(Gen, K, X)), Vs),
    include([X] >> (abs(X) >= D), Vs, Over),
    length(Over, A),
    exclude([X] >> (abs(X) >= D), Vs, Under),
    sum_list(Under, B),
    maplist([X, Y] >> (Y is X * X), Under, Sq),
    sum_list(Sq, C).

% ±1 路径的 max|S_k|（用位串枚举：bit=1 取 +1，bit=0 取 -1）
path_max(N, Bits, M) :-
    path_walk(0, 0, N, Bits, 0, M).
path_walk(_, _, 0, _, M, M).
path_walk(K, S, N, Bits, Cur, M) :-
    K < N,
    Bit is (Bits >> K) /\ 1,
    Step is Bit * 2 - 1,
    S1 is S + Step,
    Cur1 is max(Cur, abs(S1)),
    K1 is K + 1,
    path_walk(K1, S1, N, Bits, Cur1, M).

% 穷举 2^N 条路径：P(max >= Eps) = 计数 / 2^N
kolmogorov_count(N, Eps, Count, Total) :-
    Total is 2 ^ N,
    T1 is Total - 1,
    findall(1,
        ( between(0, T1, Bits),
          path_max(N, Bits, M),
          M >= Eps ),
        Hits),
    length(Hits, Count).

main :-
    format("==== 45 three_series~n"),
    % ---------- ① 三账引擎 ----------
    format("① 三级数三账（eps 精确，d = 1/2）：~n"),
    three_account(conv_v, 100, 1 rdiv 2, A1, B1, C1),
    format("   收敛候选 ±1/k   前 100 项：(a)=~w，(b)=~2f，(c)=~4f~n", [A1, B1, C1]),
    C1 < 2,                                  % 望远镜证书：Σ1/k^2 < 2
    three_account(conv_v, 400, 1 rdiv 2, _, _, C2),
    format("   收敛候选 前 400 项：(c)=~4f（逼近上界 2，单调有界）~n", [C2]),
    C2 > C1, C2 < 2,
    three_account(div_v, 100, 1 rdiv 2, _, _, D1),
    three_account(div_v, 400, 1 rdiv 2, _, _, D2),
    three_account(div_v, 1600, 1 rdiv 2, _, _, D3),
    format("   发散候选 ±1/floor(sqrt(k)) (c) 前缀：~4f -> ~4f -> ~4f（无界——(c) 发散）~n", [D1, D2, D3]),
    D3 > D2, D2 > D1, D3 > 5 rdiv 2,
    % ---------- ② Kolmogorov 极大不等式穷举 ----------
    format("② Kolmogorov 极大不等式穷举（2^12 条路径）：~n"),
    kolmogorov_count(12, 7, Count, Total),
    P is Count rdiv Total,
    Bound is 12 rdiv 49,
    format("   P(max_{{k<=12}}|S_k| >= 7) = ~w/~w = ~w <= var/eps^2 = ~w~n",
           [Count, Total, P, Bound]),
    P =< Bound,
    kolmogorov_count(12, 9, Count9, Total9),
    P9 is Count9 rdiv Total9,
    Bound9 is 12 rdiv 81,
    P9 =< Bound9,
    format("   eps=9：~w/~w = ~w <= 12/81 = ~w~n", [Count9, Total9, P9, Bound9]),
    % ---------- ③ Feller 条件 ----------
    format("③ Feller 条件 nP(|X|>n)（尾 = (1+n)^(-beta)）：~n"),
    forall((member(Beta, [1, 2]), member(N, [10, 100, 1000])),
           (V is N rdiv (1 + N) ** Beta,
            format("   beta=~w，n=~w：nP = ~w~n", [Beta, N, V]))),
    format("   beta=2 趋 0（弱律成立），beta=1 趋 1（失败）~n"),
    format("END ====~n").
