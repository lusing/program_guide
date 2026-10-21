:- encoding(utf8).
% 23_hypothesis_testing.pl —— 第 23 章：假设检验（Prolog 穷举）
%
% ① 掷币 20 次的精确二项尾（12 正面的双侧 p 值）；② 骰子
%    60 投的 χ² 统计量计算与位置；③ 三门 6 格表（换/留的
%    精确账——25 章预热）。

% ① 阶乘与二项系数（整数算术）
fact(0, 1) :- !.
fact(N, F) :- N > 0, N1 is N - 1, fact(N1, F1), F is N * F1.

binomial(N, K, B) :- fact(N, FN), fact(K, FK), NK is N - K, fact(NK, FNK),
                     B is FN // (FK * FNK).

check_coin_p :-
    fact(20, F20),
    findall(B, (between(0, 8, K1), binomial(20, K1, B)), Lows),
    findall(B, (between(12, 20, K2), binomial(20, K2, B)), Highs),
    append(Lows, Highs, All),
    sum_list(All, Num),
    Den is 2 ^ 20,                              % 分母是 2^20 不是 20!（笔误现场）
    P is Num / Den,
    P > 0.3, P < 0.8,                          % 双侧 p ≈ 0.5：不拒绝
    format("coin 12/20 heads: two-sided p = ~3f > 0.05 (no reject): OK~n", [P]).

% ② 骰子 60 投的 χ² 统计量（期望各 10）
check_dice_chi2 :-
    Observed = [8, 11, 9, 12, 10, 10],
    chi2_stat(Observed, 10, Chi),
    Chi < 11.07,                               % χ²(5) 的 5% 临界：不拒绝公平
    format("dice chi2 stat = ~2f below 11.07 (fair dice compatible): OK~n", [Chi]).

chi2_stat([], _, 0).
chi2_stat([O | Os], E, Chi) :- chi2_stat(Os, E, C0),
                               Chi is C0 + (O - E) ^ 2 / E.

% ③ 三门 6 格表：车 3 位置 × 换/留
check_monty_table :-
    findall(Win-Switch, (member(Car, [1, 2, 3]),
                         member(Switch, [stay, switch]),
                         (  Switch = stay
                         -> (Car =:= 3 -> Win = 1 ; Win = 0)   % 留赢 ⟺ 车在 3
                         ;  (Car =\= 3 -> Win = 1 ; Win = 0)   % 换赢 ⟺ 车不在 3
                         )), Table),
    length(Table, 6),
    aggregate_all(count, member(1-switch, Table), Ns),
    aggregate_all(count, member(1-stay, Table), Nt),
    Ns =:= 2, Nt =:= 1,                        % 换 2/3、留 1/3
    format("monty hall 6-cell table: switch wins 2/6, stay wins 1/6: OK~n").

true_win(1-_).

main :-
    format("==== 23 hypothesis_testing~n", []),
    check_coin_p,
    check_dice_chi2,
    check_monty_table,
    format("END ====~n"), !.

:- initialization(main).
