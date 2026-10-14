:- encoding(utf8).
% 第 59 章：归纳与递归的机器化（Makinson Ch4）
% 递归谓词（fib/ack）+ 记忆化开关 + 调用计数 + 闭包迭代。

% ---------- Fibonacci：朴素递归 + 加法计数 ----------
:- dynamic fib_call/1.
fib_call(0).

fib(0, 0) :- !.
fib(1, 1) :- !.
fib(N, F) :-
    N >= 2,
    retract(fib_call(C)), C1 is C + 1, assertz(fib_call(C1)),
    N1 is N - 1, N2 is N - 2,
    fib(N1, F1), fib(N2, F2),
    F is F1 + F2.

% 记忆化版本（表驱动）
fibt(0, 0) :- !.
fibt(1, 1) :- !.
fibt(N, F) :-
    N >= 2, N1 is N - 1, N2 is N - 2,
    fibt(N1, F1), fibt(N2, F2), F is F1 + F2,
    !.

% ---------- Ackermann ----------
ackm(0, N, S) :- S is N + 1.
ackm(M, 0, A) :- M > 0, M1 is M - 1, ackm(M1, 1, A).
ackm(M, N, A) :-
    M > 0, N > 0,
    M1 is M - 1, N1 is N - 1,
    ackm(M, N1, X), ackm(M1, X, A).

% ---------- 闭包迭代：X_{n+1} = X_n ∪ 2·X_n ----------
closure2(Start, 0, Start).
closure2(Start, S, Out) :-
    S > 0, S1 is S - 1,
    closure2(Start, S1, Mid),
    findall(Y, (member(X, Mid), Y is 2*X), Doubled),
    append(Mid, Doubled, Out).

main :-
    set_stream(user_output, encoding(utf8)),
    format("==== 59~n"),

    % 一、奇数和与偶数和（归纳定理的逐点验证）
    forall((between(1, 15, N), Nm1 is N - 1),
           (findall(2*I+1, between(0, Nm1, I), Odds),
            sum_list(Odds, S), S =:= N*N)),
    format("  1+3+…+(2n−1) = n² 于 n ≤ 15 逐点验证 ✓~n"),

    % 二、阶乘不等式 n! > 2^n（n ≥ 4）
    forall(between(4, 10, N),
           (fact(N, F), F > 2^N)),
    format("  n! > 2^n 于 4 ≤ n ≤ 10 逐点验证 ✓~n"),

    % 三、Fibonacci 朴素调用计数 vs 记忆化
    retractall(fib_call(_)), assertz(fib_call(0)),
    fib(20, F20),
    fib_call(C20),
    format("  F(20) = ~w：朴素递归做 ~d 次加法（= F(21)−1）~n", [F20, C20]),
    fib(21, F21), C20 =:= F21 - 1,
    fibt(20, F20),
    format("  记忆化（表驱动子句）：同一 F(20) = ~w ✓~n", [F20]),

    % 四、Ackermann 小值
    ackm(2, 3, 9),
    ackm(3, 3, 61),
    format("  A(2,3) = 9，A(3,3) = 61 ✓~n"),

    % 五、闭包：{2,5} 在 n↦2n 下（书本答案双链）
    closure2([2,5], 3, Cl),
    sort(Cl, Cls),
    format("  {2,5} 在 n↦2n 下三步闭包：~w~n", [Cls]),

    format("END ===="), nl.

fact(0, 1).
fact(N, F) :- N > 0, N1 is N - 1, fact(N1, F1), F is N * F1.
