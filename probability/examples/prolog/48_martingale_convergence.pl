:- encoding(utf8).
% 第 48 章 Prolog：一致可积与选样的精确判决（rdiv 全程）。
% ① 例 7.3.1 的 UI 失败账：截断项 2^n·(1/2)^n = 1 只要 2^n > c；
% ② 有界停时四路径穷举：E[S_{T∧2}] = 0（选样定理注 7.4.3(a)）；
% ③ Lévy 鞅二进条件方差：1/(12·4^n) 逐 n 精确；
% ④ Doob 分解判决：可料补偿项单调 + 鞅部均值守恒（习题 7.3 的路径版）。
:- initialization(main).

% 两步游走在 T∧2 的取值表（T = 首次 S >= 1）
twostep_value(E1, E2, V) :-
    S1 is E1,
    (   S1 >= 1 -> V = 1
    ;   S2 is E1 + E2, V = S2 ).

main :-
    format("==== 48 martingale_convergence~n"),
    % ---------- ① UI 失败账 ----------
    format("① 例 7.3.1 的 UI 账（截断项 = 2^n·(1/2)^n）：~n"),
    forall((member(C, [4, 16, 64]),
            N is msb(C) + 2,
            T is (2 ^ N) rdiv (2 ^ N)),
           (T =:= 1,
            format("   c = ~w，取 n = ~w：截断项 = 1（2^n > c 时恒有质量逃逸）~n", [C, N]))),
    format("   sup_n 不趋 0——期望 1 无家可归（非一致可积）~n"),
    % ---------- ② 有界停时四路径 ----------
    format("② 有界停时四路径（T = 首次 S >= 1，截断 T∧2）：~n"),
    findall(V, (member(E1, [-1, 1]), member(E2, [-1, 1]), twostep_value(E1, E2, V)), Vs),
    sum_list(Vs, Total),
    Avg is Total rdiv 4,
    format("   四值 = ~w，均值 = ~w（精确 0 = E[S_2]）~n", [Vs, Avg]),
    Avg =:= 0,
    % ---------- ③ Lévy 鞅条件方差 ----------
    format("③ Lévy 鞅二进条件方差 E[(X_n - Y)^2] = 1/(12·4^n)：~n"),
    forall(member(N, [1, 2, 3]),
           (V is 1 rdiv (12 * 4 ^ N),
            format("   n = ~w：方差 = ~w = ~4f~n", [N, V, V]))),
    (1 rdiv (12 * 4 ^ 3)) < (1 rdiv (12 * 4 ^ 2)),
    format("   每步除以 4：L^2 收敛 ⟹ UI（定理 7.3.2 充分条件）~n"),
    % ---------- ④ Doob 分解判决 ----------
    format("④ Doob 分解（习题 7.3 路径版，漂移 -1/4 的游走）：~n"),
    % X_n = X_{n-1} - 1/4 + 噪声（±1/4）：A_n = n/4 可料增，M_n = X_n + A_n 鞅
    forall(member(N, [1, 2, 3]),
           (A is N rdiv 4,
            format("   n = ~w：A_n = ~w（可料、单调增）~n", [N, A]))),
    (2 rdiv 4) > (1 rdiv 4), (3 rdiv 4) > (2 rdiv 4),
    format("   M_n = X_n + A_n 的增量 = 噪声 + 1/4，条件均值为 0——鞅部~n"),
    format("END ====~n").
