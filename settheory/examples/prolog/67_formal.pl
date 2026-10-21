:- encoding(utf8).
% 第 67 章：传递集合与形式理论（冯琦 引言+§1.1-1.2）
% Hilbert 推导检查器：Prolog 项 unify 即公理模式匹配，MP 即查表。

% ---------- 定义 1.22 (1)：公理模式（unify 即匹配） ----------
axiom(imp(P, imp(Q, P))).                                  % (c)
axiom(imp(imp(P, imp(Q, R)),                               % (a)
          imp(imp(P, Q), imp(P, R)))).

% ---------- 推导检查：steps 为 step(Formula, Just) 列表 ----------
% Just = ax（公理实例）或 mp(I, J)（第 I 步 X→Y、第 J 步 X，本步 Y）
check(Der) :- check_steps(Der, Der).

check_steps([], _).
check_steps([step(F, ax)|Rest], Full) :-
    ( axiom(F) -> true
    ; format("第 ~w 步不是公理实例~n", [F]), fail ),
    check_steps(Rest, Full).
check_steps([step(Y, mp(I, J))|Rest], Full) :-
    nth0(I, Full, step(imp(X, Y), _)),
    nth0(J, Full, step(X, _)),
    check_steps(Rest, Full).

main :-
    % ---------- 67.6 五步链 ----------
    P = v(0),
    S1 = imp(P, imp(imp(P, P), P)),
    S2 = imp(imp(P, imp(imp(P, P), P)),
             imp(imp(P, imp(P, P)), imp(P, P))),
    S3 = imp(imp(P, imp(P, P)), imp(P, P)),
    S4 = imp(P, imp(P, P)),
    S5 = imp(P, P),
    Chain = [step(S1, ax), step(S2, ax), step(S3, mp(1, 0)),
             step(S4, ax), step(S5, mp(2, 3))],
    ( check(Chain) -> format("五步链 P→P 验证通过 ✓~n")
    ; format("五步链失败（不应发生）~n"), halt(1) ),
    % 篡改：交换 MP 实参
    Bad = [step(S1, ax), step(S2, ax), step(S3, mp(0, 1)),
           step(S4, ax), step(S5, mp(2, 3))],
    ( check(Bad) -> format("篡改链不应通过~n"), halt(1)
    ; format("篡改链（MP 实参交换）被拒绝 ✓~n") ),
    format("END ====~n").
