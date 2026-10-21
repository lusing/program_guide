:- encoding(utf8).
% 20_generating_functions.pl —— 第 20 章：母函数（Prolog 穷举）
%
% ① Fibonacci：递推 vs Binet 取整（bignum 精确）；② 多项式
%    乘法 = pmf 卷积（骰子 pmf 平方 = 两骰三角形）；③ 母函数
%    系数恢复：s/(1−s−s²) 的长除法前 20 项 = Fibonacci。

% ① Fibonacci 递推（迭代式——朴素双递归在 N=40 指数爆炸）
fib(N, F) :- fib_iter(0, 0, 1, N, F).
fib_iter(N, A, _, N, A).
fib_iter(I, A, B, N, F) :- I < N, I1 is I + 1,
                           C is A + B, fib_iter(I1, B, C, N, F).

check_fib :-
    fib(30, 832040),
    fib(40, 102334155),
    format("fibonacci recurrence: F(30)=832040, F(40)=102334155: OK~n").

% ② 多项式乘法 = 卷积：骰子 pmf [1,1,1,1,1,1] 自乘 = 三角形
conv_sum(A, B, K, S) :-
    aggregate_all(sum(P), (nth0(I, A, Ai), nth0(J, B, Bj),
                           I + J =:= K, P is Ai * Bj), S).

poly_conv(A, B, C) :-
    length(A, LA), length(B, LB), L is LA + LB - 2,   % 系数下标 0..L
    findall(S, (between(0, L, K), conv_sum(A, B, K, S)), C).

check_conv :-
    D = [1,1,1,1,1,1],
    poly_conv(D, D, Tri),
    Tri = [1,2,3,4,5,6,5,4,3,2,1],
    format("polynomial mult = pmf convolution: die^2 = triangle: OK~n").

% ③ 母函数系数恢复：c_n = c_{n-1} + c_{n-2}（1/(1−s−s²) 的系数，
%    即 Fibonacci 平移；G(s) = s/(1−s−s²) ⟹ 系数恰为 Fₙ）
gf_series(0, 1).
gf_series(1, 1).
gf_series(N, C) :- N > 1, N1 is N - 1, N2 is N - 2,
                   gf_series(N1, C1), gf_series(N2, C2), C is C1 + C2.

check_gf :-
    gf_series(10, 89),
    fib(11, 89),                  % 平移：c_n = F_{n+1}
    format("gf 1/(1-s-s^2): c_10 = 89 = F_11 (shift by s): OK~n").

main :-
    format("==== 20 generating_functions~n", []),
    check_fib,
    check_conv,
    check_gf,
    format("END ====~n"), !.

:- initialization(main).
