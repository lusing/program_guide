% ============================================================
% 04 - 算术与比较
%   运行：swipl -q -f 04-arithmetic.pl -g main -t halt
%        gprolog --consult-file 04-arithmetic.pl --entry-goal main
% ============================================================
% 要点：= 是合一，is 才是求值。这是 Prolog 初学者第一个大坑。

show(Label, Goal) :-
    (   catch(Goal, E, (format("  ~w -> 异常 ~q~n", [Label, E]), fail))
    ->  true
    ;   format("  ~w -> 失败~n", [Label])
    ).

demo_unify_vs_is :-
    format("---- = 与 is 的区别 ----~n", []),
    ( X = 1 + 2 -> format("  X = 1 + 2        => X = ~q（未求值，是个复合项）~n", [X]) ; true ),
    ( Y is 1 + 2 -> format("  Y is 1 + 2       => Y = ~w（求值）~n", [Y]) ; true ),
    ( Z is 7 // 2 -> format("  7 // 2（整除）    => ~w~n", [Z]) ; true ),
    ( W is 7 / 2 -> format("  7 / 2（浮点）     => ~w~n", [W]) ; true ),
    ( M is 7 mod 2 -> format("  7 mod 2（取模）   => ~w~n", [M]) ; true ),
    ( P is 2 ** 10 -> format("  2 ** 10          => ~w~n", [P]) ; true ),
    ( A1 is abs(-3), A2 is sign(-5), A3 is max(2, 9), A4 is min(2, 9)
    -> format("  abs/sign/max/min  => ~w ~w ~w ~w~n", [A1, A2, A3, A4]) ; true ),
    ( R1 is round(3.7), R2 is truncate(3.7), R3 is sqrt(16)
    -> format("  round/trunc/sqrt  => ~w ~w ~w~n", [R1, R2, R3]) ; true ),
    ( B1 is 12 /\ 10, B2 is 12 \/ 10, B3 is 1 << 4
    -> format("  /\\ \\/ <<          => ~w ~w ~w~n", [B1, B2, B3]) ; true ).

demo_compare :-
    format("---- 比较运算符 ----~n", []),
    format("  =:= 等于   =\\= 不等于   < > =< >=~n", []),
    ( 3 =:= 3 -> format("  3 =:= 3           真~n", []) ; true ),
    ( 3 =:= 3.0 -> format("  3 =:= 3.0         真（数值比较会跨整数/浮点）~n", []) ; true ),
    ( 3 == 3.0 -> format("  3 == 3.0          真~n", []) ; format("  3 == 3.0          假（== 是项等价，不做数值转换）~n", []) ),
    ( 3 =:= 1 + 2 -> format("  3 =:= 1 + 2       真（右边先求值）~n", []) ; true ).

demo_sort_order :-
    format("---- 标准项序（== 之外的一切排序都靠它）----~n", []),
    format("  变量 < 数字 < 原子 < 复合项~n", []),
    show('compare(1,2)',        (compare(C1, 1, 2),    format("    => ~w~n", [C1]))),
    show('compare(abc,abd)',    (compare(C2, abc, abd),format("    => ~w~n", [C2]))),
    show('compare(f(a),f(b))',  (compare(C3, f(a), f(b)), format("    => ~w~n", [C3]))),
    show('compare(f(1),f(1,2))',(compare(C4, f(1), f(1,2)), format("    => ~w~n", [C4]))).

% ---------- 递归算术：阶乘与斐波那契 ----------
fact(0, 1).
fact(N, F) :- N > 0, N1 is N - 1, fact(N1, F1), F is N * F1.

fib(0, 0).
fib(1, 1).
fib(N, F) :- N > 1, A is N - 1, B is N - 2, fib(A, FA), fib(B, FB), F is FA + FB.

demo_recursion :-
    format("---- 递归算术 ----~n", []),
    forall(member(N, [0,1,2,5,10]),
           ( fact(N, F), format("  ~w! = ~w~n", [N, F]) )),
    forall(member(K, [0,1,2,5,10,15]),
           ( fib(K, V), format("  fib(~w) = ~w~n", [K, V]) )).

% ---------- 累加器版：尾递归 ----------
fact_acc(N, F) :- fact_acc(N, 1, F).
fact_acc(0, Acc, Acc).
fact_acc(N, Acc, F) :- N > 0, Acc1 is Acc * N, N1 is N - 1, fact_acc(N1, Acc1, F).

demo_acc :-
    format("---- 尾递归 + 累加器 ----~n", []),
    fact_acc(10, F),
    fact(10, F2),
    ( F =:= F2 -> Same = '一致' ; Same = '不一致' ),
    format("  10! = ~w（朴素递归 ~w，两者~w）~n", [F, F2, Same]).

% ---------- 数值区间与计数 ----------
demo_range :-
    format("---- between/3 与计数 ----~n", []),
    findall(I, (between(1, 100, I), 0 is I mod 17), Ms),
    format("  1..100 中 17 的倍数：~w~n", [Ms]),
    aggregate_manual(Ms, Sum),
    format("  它们的和：~w~n", [Sum]).

aggregate_manual([], 0).
aggregate_manual([X | Xs], S) :- aggregate_manual(Xs, S1), S is S1 + X.

run :-
    demo_unify_vs_is,  nl,
    demo_compare,      nl,
    demo_sort_order,   nl,
    demo_recursion,    nl,
    demo_acc,          nl,
    demo_range.

main :-
    (   catch(run, E, (format(user_error, "异常: ~q~n", [E]), fail))
    ->  format("==== 04 结束 ====~n", []), halt(0)
    ;   format(user_error, "04 运行失败~n", []), halt(1)
    ).
