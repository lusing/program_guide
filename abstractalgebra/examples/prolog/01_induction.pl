:- encoding(utf8).
% 第 01 章 · 数学归纳法与良序 —— Prolog 通道
%
% 良序原则的可执行化：between(1, N, X) 升序生成 + 割断取第一个 = 最小反例。
% 全文件只用整数算术，无浮点。


% ---------- 命题 1.3 直译：试除判素 ----------
prime(N) :-
    N >= 2,
    \+ (between(2, N, D), D * D =< N, N mod D =:= 0).

% ---------- 最小反例搜索（良序原则直译） ----------
% between 升序生成，! 保证取到第一个就停。
first_counterexample(Bad, N) :-
    between(1, 200, N),
    call(Bad, N), !.

% 欧拉多项式：n² − n + 41 在 n = 41 处出现第一个合数值
euler_bad(N) :-
    V is N * N - N + 41,
    \+ prime(V).

% 2^N 与 N² 的关系（eq / lt / gt）
pow_vs_square(N, Op) :-
    P is 2 ^ N,
    (   P =:= N * N -> Op = eq
    ;   P < N * N -> Op = lt
    ;   Op = gt
    ).

% ---------- 高斯求和：递归定义 ----------
sum_to(0, 0) :- !.
sum_to(N, S) :-
    N > 0,
    N1 is N - 1,
    sum_to(N1, S1),
    S is S1 + N.

% ---------- 斐波那契：迭代版 ----------
fib(N, F) :- fib_iter(N, 0, 1, F).
fib_iter(0, A, _, A) :- !.
fib_iter(N, A, B, F) :-
    N > 0,
    N1 is N - 1,
    C is A + B,
    fib_iter(N1, B, C, F).

% ---------- 期望行为 ----------
expected(1, gt).
expected(2, eq).
expected(3, lt).
expected(4, eq).
expected(N, gt) :- N >= 5.

% 卡西尼全量断言
cassini_ok(N) :-
    Nm1 is N - 1, Np1 is N + 1,
    fib(Nm1, F1), fib(Np1, F2), fib(N, F),
    LHS is F1 * F2 - F * F,
    (   N mod 2 =:= 0 -> LHS =:= 1
    ;   LHS =:= -1
    ).

main :-
    format("==== 01 数学归纳法与良序~n"),

    first_counterexample(euler_bad, N1),
    format("欧拉多项式 n²−n+41：第一个合数值出现在 n = ~d~n", [N1]),

    forall(between(1, 12, N),
           ( pow_vs_square(N, Op), expected(N, Op) )),
    format("2ⁿ 与 n²：n = 2, 4 相等；n = 3 反向；n ≥ 5 严格大于 ✓~n"),

    forall(between(0, 100, N),
           ( sum_to(N, S), 2 * S =:= N * (N + 1) )),
    format("高斯求和：递归与公式在 n ≤ 100 逐点一致 ✓~n"),

    forall(between(1, 200, N), cassini_ok(N)),
    format("卡西尼恒等式 F_{n−1}F_{n+1} − F_n² = (−1)ⁿ：n ≤ 200 全部成立 ✓~n"),

    format("END ====~n").
