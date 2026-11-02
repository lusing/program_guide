:- encoding(utf8).
% 12_discrete_dists.pl —— 第 12 章：离散分布族（Prolog 穷举）
%
% ① 四骰赌局 1296 局全枚举 E = 239/1296；② 饼干 3⁶ = 729
%    加权序列 → 3-2-1 概率；③ German Tank N = 8、k = 3 的
%    56 组合全枚举 E[M] = 27/4 = k/(k+1)·(N+1)；④ 几何截断归一。

% ① 四骰：押定 1（对称性不失一般），出现 k 次赢 k 元
count_1s(Dice, K) :- include(=(1), Dice, Ones), length(Ones, K).

check_die_game :-
    findall(W, (between(1,6,A), between(1,6,B), between(1,6,C),
                between(1,6,D), count_1s([A,B,C,D], K),
                (K == 0 -> W = -1 ; W = K)), Ws),
    length(Ws, 1296),
    sum_list(Ws, S),
    S =:= 239,                                    % 每局 1296 分之一
    format("four-die game: 1296 boards sum to 239, E = 239/1296: OK~n").

% ② 饼干：三色权重 45/30/25，6 抽恰 3-2-1
weight(0, 45). weight(1, 30). weight(2, 25).

seq_weight([], 1).
seq_weight([C|Cs], W) :- weight(C, W0), seq_weight(Cs, W1), W is W0 * W1.

check_cookies :-
    findall(W, (between(0,2,A), between(0,2,B), between(0,2,C),
                between(0,2,D), between(0,2,E), between(0,2,F),
                Seq = [A,B,C,D,E,F],
                include(=(0), Seq, Zs), length(Zs, 3),
                include(=(1), Seq, Os), length(Os, 2),
                seq_weight(Seq, W)), Ws),
    length(Ws, 60),                               % 3-2-1 的排列数 = 6!/(3!2!1!)
    sum_list(Ws, Num),                            % 分子（/100^6）
    Den is 100 ^ 6,
    P is Num / Den,
    abs(P - 0.123019) < 1e-6,
    format("cookies 3-2-1: 60 weighted seqs, P = 0.123019: OK~n").

% ③ German Tank：N = 8、k = 3，56 组合全枚举
combo3(N, [A,B,C]) :- between(1,N,A), A1 is A + 1, between(A1, N, B),
                      B1 is B + 1, between(B1, N, C).

check_tank :-
    findall(M, (combo3(8, S), max_list(S, M)), Ms),
    length(Ms, 56),
    sum_list(Ms, Sum),
    E is Sum rdiv 56,
    E =:= 27 rdiv 4,                              % k/(k+1)(N+1) = 6.75
    format("german tank N=8,k=3: E[M]=27/4 = k/(k+1)(N+1) by 56 combos: OK~n").

% ④ 几何 p = 1/2：n ≤ 8 截断归一 Σ (1/2)^n = 255/256
check_geometric :-
    findall(T, (between(1, 8, N), T is 1 rdiv 2 ^ N), Ts),
    sum_list(Ts, S),
    S =:= 255 rdiv 256,
    format("geometric(1/2) truncated sum n<=8 = 255/256: OK~n").

main :-
    format("==== 12 discrete_dists~n", []),
    check_die_game,
    check_cookies,
    check_tank,
    check_geometric,
    format("END ====~n"), !.

:- initialization(main).
