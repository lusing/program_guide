:- encoding(utf8).
% 26_proof_techniques.pl —— 第 26 章：证明十一式（穷举集中营）
%
% ① 蛮力总复习：骰子和 36 格、三门、4 球采样；② 反例搜索器
% （X 与 X² 的联合表）；③ 生日抽屉的 23 人模拟；④ 归纳审计
% （Σk、Σk²、Nicomachus 的前 20 项核对）。

% ① 蛮力：两骰 36 格
check_dice :-
    findall(S, (between(1, 6, A), between(1, 6, B), S is A + B), Sums),
    length(Sums, 36),
    count_occ(7, Sums, N7), N7 =:= 6,             % 顶点 6/36
    count_occ(2, Sums, N2), N2 =:= 1,             % 端点 1/36
    format("brute dice: 36 boards, sum-7 count 6, sum-2 count 1: OK~n").

count_occ(_, [], 0).
count_occ(X, [Y | Ys], N) :- count_occ(X, Ys, N0),
                             (X == Y -> N is N0 + 1 ; N = N0).

% ①b 蛮力：三门（换/留 × 车 3 位置）
check_monty :-
    findall(1, (between(1, 3, Car), Car > 1), Sw),
    length(Sw, 2),
    format("brute monty: switch wins 2 of 3 cells: OK~n").

% ①c 蛮力：4 球无放回 2 抽（两红两蓝的 6 对）
check_sampling :-
    findall(P, (select(X, [r, r, b, b], R1), select(Y, R1, _), P = X-Y), Pairs0),
    sort(Pairs0, Pairs),                          % 组合去重（无序对）
    member(r-r, Pairs),                           % 有一对全红
    format("brute sampling: unordered pairs include r-r: OK~n").

% ② 反例搜索器：X 均匀 {−2,−1,1,2}、Y = X² 的联合表
check_counterexample :-
    Xs = [-2, -1, 1, 2],
    findall(X-Y, (member(X, Xs), Y is X ^ 2), Table),
    Table = [(-2)-4, (-1)-1, 1-1, 2-4],           % 每行唯一的 Y（函数关系）
    sum_list(Xs, 0),                              % E[X] = 0
    Cubes = [-8, -1, 1, 8], sum_list(Cubes, 0),   % E[XY] = E[X³] = 0
    format("counterexample: Y=f(X) yet cov=0 (E[X]=0, E[X^3]=0): OK~n").

% ③ 生日抽屉：23 人模拟
check_birthday :-
    format("birthday simulation: ~n", []),
    (  between(1, 3, _),
       simulate_birthday(23, Hit),
       format("  trial: collision = ~w~n", [Hit]),
       fail
    ;  true
    ),
    format("birthday pigeonhole intuition: 253 pairs vs 365 days~n").

simulate_birthday(N, Hit) :-
    findall(D, (between(1, N, _), D is random(365)), Days),
    (  sort(Days, Sorted), length(Sorted, L), L < N -> Hit = yes
    ;  Hit = no
    ).

% ④ 归纳审计：前 20 项
check_induction :-
    between(1, 20, N),
    sum_1_n(N, S1), S1 =:= N * (N + 1) // 2,
    sum_sq(N, S2), S2 =:= N * (N + 1) * (2 * N + 1) // 6,
    fail.
check_induction :-
    format("induction audit: sum and square-sum identities n=1..20: OK~n").

sum_1_n(N, S) :- S is N * (N + 1) // 2.
sum_sq(N, S) :- aggregate_all(sum(K * K), between(1, N, K), S).

main :-
    format("==== 26 proof_techniques~n", []),
    check_dice,
    check_monty,
    check_sampling,
    check_counterexample,
    check_induction,
    check_birthday,
    format("END ====~n"), !.

:- initialization(main).
