:- encoding(utf8).
% 25_famous_problems.pl —— 第 25 章：名题穷举
%
% ① n=4 秘书问题全 24 排列枚举（各 k 的精确成功率）；
% ② 三门 6 格表；③ 无放回抽样的 10 对枚举。

% ① 秘书：perm 生成 + 策略评估
perm([], []).
perm(L, [X | P]) :- select(X, L, R), perm(R, P).

% 策略：前 k 观察后选第一个更优者；无人更优则空手
strategy_outcome(Order, K, Win) :-
    length(Order, N),
    (  K >= N -> Win = 0                          % 全程观察 = 必空手
    ;  max_list_prefix(Order, K, 0, MaxK),
       once((  first_better(Order, K, MaxK, Pos),   % 第一个超过校准最佳者
               nth1(Pos, Order, Val),
               (  Val =:= N -> Win = 1
               ;  Win = 0
               )
            ;  Win = 0                            % 无人超过：空手
       ))
    ).

max_list_prefix([], _, M, M).
max_list_prefix(_, 0, M, M) :- !.
max_list_prefix([X | Xs], K, Acc, M) :-
    A is max(Acc, X), K1 is K - 1, max_list_prefix(Xs, K1, A, M).

first_better([X | _], 0, MaxK, 1) :- X > MaxK, !.
first_better([_ | Xs], Skip, MaxK, Pos) :-
    (  Skip > 0 -> S1 is Skip - 1
    ;  S1 = 0
    ),
    first_better(Xs, S1, MaxK, P0), Pos is P0 + 1.
first_better([], _, _, _) :- fail.

% ② 三门 6 格表；③ 无放回抽样的 10 对枚举。

% ① 秘书：perm 生成 + 策略评估
check_secretary4 :-
    findall(O, perm([1, 2, 3, 4], O), Orders),
    length(Orders, 24),
    findall(W, (member(O, Orders), strategy_outcome(O, 1, W)), Ws1),
    sum_list(Ws1, S1),
    P1 is S1 / 24,
    P1 =:= 11 / 24,                               % k=1: 11/24（n=4 的最优 k）
    findall(W, (member(O, Orders), strategy_outcome(O, 2, W)), Ws2),
    sum_list(Ws2, S2),
    P2 is S2 / 24,
    P2 =:= 10 / 24,                               % k=2: 10/24 = 5/12
    findall(W, (member(O, Orders), strategy_outcome(O, 3, W)), Ws3),
    sum_list(Ws3, S3),
    P3 is S3 / 24,
    P3 =:= 6 / 24,                                % k=3: 6/24 = 1/4（回落）
    format("secretary n=4: P(k=1)=11/24 best, P(k=2)=10/24, P(k=3)=6/24: OK~n").

% ② 三门（选 1 号固定）
check_monty :-
    findall(Car, (between(1, 3, Car), Car > 1), SwitchWins),
    length(SwitchWins, 2),
    findall(Car, (between(1, 3, Car), Car =:= 1), StayWins),
    length(StayWins, 1),
    format("monty hall: switch 2/3, stay 1/3 (6-cell reduced): OK~n").

% ③ 无放回：两红三蓝罐抽两球的组合账
check_sampling :-
    comb(5, 2, C5_2), comb(3, 2, C3_2),
    PNoRed is C3_2 / C5_2,
    PAtLeastOneRed is 1 - PNoRed,
    PAtLeastOneRed =:= 7 / 10,
    format("sampling without replacement: P(>=1 red in 2 of 5) = 7/10: OK~n").

comb(N, K, C) :- fact(N, FN), fact(K, FK), NK is N - K, fact(NK, FNK),
                   C is FN // (FK * FNK).
fact(0, 1) :- !.
fact(N, F) :- N > 0, N1 is N - 1, fact(N1, F1), F is N * F1.

main :-
    format("==== 25 famous_problems~n", []),
    check_secretary4,
    check_monty,
    check_sampling,
    format("END ====~n"), !.

:- initialization(main).
