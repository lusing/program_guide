:- encoding(utf8).
% 第 03 章 · 最大公因子 —— Prolog 通道
%
% 欧几里得算法直译 + 扩展版（三元组回代）+ CLPFD 天平称量 + 进制转换。

:- use_module(library(clpfd)).

% ---------- 欧几里得算法直译 ----------
gcd(A, 0, A) :- !.
gcd(A, B, D) :- C is A mod B, gcd(B, C, D).

% ---------- 扩展欧几里得：三元组回代 ----------
% extgcd(+A, +B, -D, -S, -T)：D = S·A + T·B
extgcd(A, 0, A, 1, 0) :- !.
extgcd(A, B, D, S, T) :-
    B > 0,
    Q is A // B,
    R is A mod B,
    extgcd(B, R, D, S1, T1),
    % 回代：D = S1·B + T1·R = S1·B + T1·(A − Q·B) = T1·A + (S1 − Q·T1)·B
    S is T1,
    T is S1 - Q * T1.

% ---------- 进制转换（例 1.48） ----------
base_digits(N, B, Ds) :- base_digits_(N, B, DsR), reverse(DsR, Ds).
base_digits_(0, _, []) :- !.
base_digits_(N, B, [D | Rest]) :-
    D is N mod B,
    N1 is N // B,
    base_digits_(N1, B, Rest).

% ---------- 天平称量：CLPFD 定义直译 ----------
weighable(N, E1, E3, E9, E27) :-
    [E1, E3, E9, E27] ins -1..1,
    N #= E1 * 1 + E3 * 3 + E9 * 9 + E27 * 27,
    label([E1, E3, E9, E27]).

main :-
    format("==== 03 最大公因子~n"),

    % 例 1.45
    extgcd(326, 78, D1, S1, T1),
    D1 =:= 2, S1 =:= -11, T1 =:= 46,
    S1 * 326 + T1 * 78 =:= 2,
    format("extgcd(326, 78)：d = ~d = ~d·326 + ~d·78（与手算一致）~n", [D1, S1, T1]),

    % 全量对拍：gcd 与 extgcd 一致 + 贝祖恒等式（a ≤ b ≤ 60）
    forall((between(1, 60, A), between(A, 60, B)),
           ( gcd(A, B, G1),
             extgcd(A, B, G2, S, T),
             G1 =:= G2,
             S * A + T * B =:= G1 )),
    format("gcd/extgcd：a ≤ b ≤ 60 全量一致，贝祖恒等式逐对成立 ✓~n"),

    % 7 进制
    base_digits(12345, 7, Ds),
    Ds == [5, 0, 6, 6, 4],
    format("12345 = (50664)₇ ✓~n"),

    % 天平：1..40 全部可称，且方式唯一
    forall(between(1, 40, N),
           ( findall(s, weighable(N, _, _, _, _), [_]) )),
    weighable(19, E1, E3, E9, E27),
    format("天平 1,3,9,27：1..40 每重量恰一法；19 = 27 − 9 + 1：~w,~w,~w,~w ✓~n",
           [E27, E9, E3, E1]),

    format("END ====~n").
