:- encoding(utf8).
% 43_local_martingales.pl —— 第 43 章：截断与策略（Prolog 通道）
%
% ① 停止过程的全树期望；② 可料 vs 偷看策略；③ 停止语义（冻结非 clamp）。

% 停止乘积过程：eps = 1/2，cap = 9/4，两步全树
stopped_product(Path, Cap, M) :- sp_(Path, 1, Cap, M).
sp_([], M, _, M).
sp_([D|Ds], M0, Cap, M) :-
    (   M0 >= Cap -> M = M0                       % 冻结（停止语义）
    ;   M1 is M0 * (1 + (D * 0.5)),               % D = ±1 → ×(1±0.5)
        sp_(Ds, M1, Cap, M)
    ).

check_stopped :-
    findall(M, (member(P, [[1,1],[1,-1],[-1,1],[-1,-1]]),
                stopped_product(P, 2.25, M)), Ms),
    % [+,+]: 1.5*1.5 = 2.25 ≥ cap 但已到末端 = 2.25；[+,-]: 0.75；[-,+]: 0.75；[-,-]: 0.25
    Ms == [2.25, 0.75, 0.75, 0.25],
    Avg is (2.25 + 0.75 + 0.75 + 0.25) / 4,
    abs(Avg - 1.0) < 1e-9,
    format("stopped product 2-step tree: exact mean = 1: OK~n").

% 三步路径 [+,+,-]：cap 触发在第 2 步（2.25 ≥ 2.25）→ 冻结
check_freeze :-
    stopped_product([1, 1, -1], 2.25, M1),
    abs(M1 - 2.25) < 1e-9,                       % 冻结在 2.25（非 clamp 到 cap 再乘）
    stopped_product([1, 1, -1], 100.0, M2),
    abs(M2 - 1.125) < 1e-9,                      % 大 cap 不触发：2.25*0.5
    format("freeze semantics: crossing value kept, not clamped: OK~n").

% 可料 vs 偷看
check_strategy :-
    findall(D1*D2, (member(D1, [-1,1]), member(D2, [-1,1])), Prod),
    sum_list(Prod, S1), S1 == 0,                  % E[D1*D2] = 0
    findall(D2*D2, (member(_D1, [-1,1]), member(D2, [-1,1])), Sq),
    sum_list(Sq, S2), S2 == 4,                    % E[D2²]·4 = 4
    format("predictable E[D1*D2]=0 vs cheating E[D2^2]=1: OK~n").

main :-
    format("==== 43 local_martingales~n", []),
    check_stopped,
    check_freeze,
    check_strategy,
    format("END ====~n"), !.

:- initialization(main).
