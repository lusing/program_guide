:- encoding(utf8).
% 第 05 章 · 同余 —— Prolog 通道
%
% CLPFD 模约束 + 新生代梦/费马穷举 + 孙子问题 + 玛雅历 + 模 6/7 乘法表。

:- use_module(library(clpfd)).

prime(N) :-
    N >= 2,
    \+ (between(2, N, D), D * D =< N, N mod D =:= 0).

main :-
    format("==== 05 同余~n"),

    % 新生代梦 (a+b)³ ≡ a³+b³ (mod 3)：穷举 9 对
    forall((between(0, 2, A), between(0, 2, B)),
           ( L is (A + B) ^ 3 mod 3,
             R is (A ^ 3 + B ^ 3) mod 3,
             L =:= R )),
    format("新生代梦 (a+b)³ ≡ a³+b³ (mod 3)：9 对余数穷举 ✓~n"),

    % 费马 p = 5, 7：全余数穷举
    forall((member(P, [5, 7]), Pm1 is P - 1, between(0, Pm1, A)),
           ((A ^ P) mod P =:= A mod P)),
    format("费马小定理 a^p ≡ a (mod p)：p = 5, 7 全余数穷举 ✓~n"),

    % 孙子问题（CLPFD 定义直译）
    sun_tzu(X),
    X == 23,
    format("孙子问题 x ≡ 2,3,2 (mod 3,5,7)：最小正解 x = ~d ✓~n", [X]),

    % 玛雅历（例 1.78）
    maya(D),
    D == 86,
    format("玛雅历：Akbal 13 → Muluc 8 相隔 ~d 天（CRT：d≡6 mod 20 ∧ d≡8 mod 13）✓~n", [D]),

    % 弃九法（例 1.66）
    Exact is (12345 + 5261934) * 1776,
    Exact =:= 9367119504,
    digit_root(Exact, R1),
    digit_root((6 + 3) * 3, R2),
    R1 =:= R2, R1 =:= 0,
    format("弃九法：r((12345+5261934)×1776) = r([6+3]×3) = 0 ✓~n"),

    % ℤ/6ℤ 与 ℤ/7ℤ 乘法表：零因子的现场
    format("ℤ/6ℤ 乘法表（可看到零因子 3×4 ≡ 0）：~n"),
    print_table(6),
    format("ℤ/7ℤ 乘法表（非零行无零——域的预告）：~n"),
    print_table(7),

    format("END ====~n").

% ---------- 孙子问题：CLPFD ----------
sun_tzu(X) :-
    X #> 0, X #< 105,
    X mod 3 #= 2,
    X mod 5 #= 3,
    X mod 7 #= 2,
    indomain(X).                    % 从最小候选开始试探

% ---------- 玛雅历 ----------
maya(D) :-
    D #> 0, D #< 260,               % 卓尔金历周期 260 天
    D mod 20 #= 6,                  % 日名差：Akbal → Muluc
    D mod 13 #= 8,                  % 数字差：13 → 8
    indomain(D).

% ---------- 数字根（书的口径 0 ≤ r < 9） ----------
digit_root(N, R) :- R is N mod 9.

% ---------- 乘法表 ----------
print_table(M) :-
    M1 is M - 1,
    forall(between(0, M1, A),
           ( findall(C, (between(0, M1, B), C is (A * B) mod M), Row),
             format_row(Row),
             format("|~n") )).

format_row([]) :- !.
format_row([C | Cs]) :-
    format("| ~d ", [C]),
    format_row(Cs).
