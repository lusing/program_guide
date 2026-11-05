:- encoding(utf8).
% 第 47 章 Prolog：离散鞅的精确判决（rdiv 全程）。
% ① 上穿计数状态机：有理路径逐条判定 + 持有增益的望远镜账；
% ② 停时判决：首中时 τ_1 的 8 条 3 步路径穷举，P(τ_1 <= 3) = 7/8；
% ③ 两步赌局的鞅变换：四点空间期望精确为 0（赌倍法无免费午餐）；
% ④ 条件期望的鞅性判决：公平游走的 E[X_{n+1} | X_n = s] = s 逐 s 判定。
:- initialization(main).

% 上穿计数（与 Lean/Python 件同构的状态机）
upcross(Path, A, B, U) :- upcross_below(Path, A, B, 0, U).
upcross_below([], _, _, U, U).
upcross_below([V | Vs], A, B, Acc, U) :-
    (   V =< A -> upcross_above(Vs, A, B, Acc, U)
    ;   upcross_below(Vs, A, B, Acc, U) ).
upcross_above([], _, _, U, U).
upcross_above([V | Vs], A, B, Acc, U) :-
    (   V >= B -> Acc1 is Acc + 1, upcross_below(Vs, A, B, Acc1, U)
    ;   upcross_above(Vs, A, B, Acc, U) ).

% 部分和
partsums(Steps, Sums) :- scanl([X, S, T] >> (T is S + X), Steps, 0, Sums0), Sums = Sums0.

% 首中时：第一个下标（1 基）使部分和 >= T；不存在则 none
first_hit(Steps, T, N) :- first_hit_(Steps, 0, T, 1, N).
first_hit_([], _, _, _, none).
first_hit_([X | Xs], S, T, K, N) :-
    S1 is S + X,
    (   S1 >= T -> N = K
    ;   K1 is K + 1, first_hit_(Xs, S1, T, K1, N) ).

% 全部 2^3 条 ±1 路径
signs3(L) :-
    findall(P, (member(A, [-1, 1]), member(B, [-1, 1]), member(C, [-1, 1]),
                P = [A, B, C]), L).

% 两步赌倍法的终值（与 Python 件同一函数）
doubling_wealth(E1, E2, W) :-
    (   E1 =< 0 -> C2 = 2 ; C2 = 0 ),
    W is E1 + C2 * E2.

main :-
    format("==== 47 martingales~n"),
    % ---------- ① 上穿计数 ----------
    format("① 上穿计数（a=3/10，b=7/10）：~n"),
    upcross([0, 1, 0, 1], 3 rdiv 10, 7 rdiv 10, U1), U1 =:= 2,
    format("   [0,1,0,1]     ：~w~n", [U1]),
    upcross([0, 0, 1, 0, 1, 1], 3 rdiv 10, 7 rdiv 10, U2), U2 =:= 2,
    format("   [0,0,1,0,1,1] ：~w~n", [U2]),
    upcross([1, 1, 1], 3 rdiv 10, 7 rdiv 10, U3), U3 =:= 0,
    format("   [1,1,1]       ：~w（从未跌到 a 以下，无上穿机会）~n", [U3]),
    (2 * (7 rdiv 10)) =< 2,
    format("   持有增益 2 >= b*U = 7/5（命题 7.2.1 的路径版账）~n"),
    % ---------- ② 首中时穷举 ----------
    format("② 首中时穷举（tau_1 = min{n: S_n >= 1}，8 条 3 步路径）：~n"),
    signs3(All),
    findall(P, (member(P, All), first_hit(P, 1, N), N \== none), Hits),
    length(Hits, H), length(All, 7),
    P7 is H rdiv 8,
    format("   P(tau_1 <= 3) = ~w/8 = ~w（只漏掉 [-1,-1,-1] 一条）~n", [H, P7]),
    P7 =:= 7 rdiv 8,
    \+ (member([-1, -1, -1], Hits)),
    % ---------- ③ 鞅变换期望 ----------
    format("③ 两步赌倍法（四点空间，rdiv 精确）：~n"),
    findall(W, (member(E1, [-1, 1]), member(E2, [-1, 1]), doubling_wealth(E1, E2, W)), Ws),
    sum_list(Ws, Total),
    Avg is Total rdiv 4,
    format("   四个终值 ~w，平均 = ~w（鞅变换保鞅——期望精确为 0）~n", [Ws, Avg]),
    Avg =:= 0,
    % ---------- ④ 条件期望鞅性 ----------
    format("④ 公平游走的条件期望（E[S_{{n+1}} | S_n = s] = s，rdiv 判决）：~n"),
    forall(member(S, [-3, -1, 0, 1, 3]),
           ( Eup is (S + 1 + S) rdiv 2,
             Edn  is (S - 1 + S) rdiv 2,
             Eup =:= S, Edn =:= S,
             format("   s = ~w：上下两支的平均 = ~w = s~n", [S, Eup]) )),
    format("END ====~n").
