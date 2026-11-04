:- encoding(utf8).
% 01_existence.pl —— 第 01 章：Picard 迭代的符号引擎（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
%
% 对 y' = x + y、y(0) = 1 做符号 Picard 迭代：
%   y_{n+1}(x) = 1 + ∫₀ˣ (t + y_n(t)) dt
% 多项式用系数表 [a0, a1, a2, ...]（aᵢ 是 xⁱ 的有理系数）表示，
% 积分 = 逐项升次（∫xⁿ = x^{n+1}/(n+1)），全程 rdiv 精确算术。

% ---------- 多项式内核 ----------
% padd(P, Q, R)：加法（先补齐再逐位加）
padd(P, Q, R) :-
    length(P, LP), length(Q, LQ), L is max(LP, LQ),
    D1 is L - LP, D2 is L - LQ,
    length(Z1, D1), maplist(=(0), Z1),
    length(Z2, D2), maplist(=(0), Z2),
    append(P, Z1, P2), append(Q, Z2, Q2),
    maplist(sum2, P2, Q2, R).
sum2(A, B, C) :- C is A + B.

% pmul_const(P, C, R)：数乘
pmul_const([], _, []).
pmul_const([A | P], C, [B | R]) :- B is C * A, pmul_const(P, C, R).

% pintegral(P, R)：∫₀ˣ P dx（常数项升 x^0 -> x 等）：[a0,a1,...] -> [0, a0, a1/1, a2/2, ...]
pintegral(P, [0 | R]) :- pintegral_(P, 1, R).
pintegral_([], _, []).
pintegral_([A | P], N, [B | R]) :- B is A rdiv N, N1 is N + 1, pintegral_(P, N1, R).

% pmul(P, Q, R)：多项式乘法（卷积）
pmul(P, Q, R) :-
    length(P, LP), length(Q, LQ), LR is LP + LQ - 1,
    length(R0, LR), maplist(=(0), R0),
    pmul_rows(P, Q, R0, R).
pmul_rows([], _, R, R).
pmul_rows([A | P], Q, Acc, R) :-
    ( A =:= 0 -> pmul_rows(P, Q, Acc, R)
    ; scale_shift(Q, A, 1, Shifted),
      padd(Shifted, Acc, Acc2),
      pmul_rows(P, Q, Acc2, R) ).
scale_shift([], _, _, []).
scale_shift([B | Q], A, I, [C | R]) :-
    ( I =:= 1 -> C is A * B ; C = 0 ),
    I1 is I + 1, scale_shift(Q, A, I1, R).

% poly_at(P, X, V)：Horner 求值（浮点）
poly_at(P, X, V) :- poly_at_(P, X, 0, V).
poly_at_([], _, A, A).
poly_at_([C | P], X, A, V) :- A2 is A * X + C, poly_at_(P, X, A2, V).

% ---------- Picard 迭代 ----------
% y' = x + y、y(0)=1：y_{n+1} = [1] + ∫(t + y_n)，t 的多项式是 [0,1]
picard(0, [1]).
picard(N, Yn1) :-
    N >= 1, N1 is N - 1,
    picard(N1, Yn),
    padd(Yn, [0, 1], Integrand),      % y_n(t) + t
    pintegral(Integrand, I),
    padd(I, [1], Yn1).                 % + 初值 1

% y' = y、y(0)=1：y_{n+1} = [1] + ∫y_n —— 逐项咬住 eˣ 的 Taylor
picard_exp(0, [1]).
picard_exp(N, Yn1) :-
    N >= 1, N1 is N - 1,
    picard_exp(N1, Yn),
    pintegral(Yn, I),
    padd(I, [1], Yn1).

% eˣ 的 Taylor 系数表
taylor_exp(N, T) :- length(T, N), taylor_exp_(0, T).
taylor_exp_(_, []).
taylor_exp_(K, [C | T]) :- factorial(K, F), C is 1 rdiv F, !,
    K1 is K + 1, taylor_exp_(K1, T).

factorial(0, 1) :- !.
factorial(N, F) :- N1 is N - 1, factorial(N1, F1), F is N * F1.

% ---------- main ----------
main :-
    format("==== 01 existence~n"),

    % (1) y' = y 的 Picard 逐轮咬 Taylor：第 n 轮 = 1+x+...+x^n/n!
    picard_exp(5, P5),
    taylor_exp(6, T6),
    P5 = T6,
    format("y'=y: Picard round 5 = 6-term Taylor of e^x (exact)~n"),
    picard_exp(6, P6),
    taylor_exp(7, T7),
    P6 = T7,
    format("y'=y: Picard round 6 = 7-term Taylor of e^x~n"),

    % (2) y' = x + y 的 Picard：第 4 轮系数账
    picard(4, P4),
    format("y'=x+y: Picard round 4 coefficients = ~w~n", [P4]),
    % hand account: y4 = [1, 1, 1, 1/3, 1/12, 1/120]
    nth0(3, P4, C3), C3 =:= 1 rdiv 3,
    nth0(4, P4, C4), C4 =:= 1 rdiv 12,
    nth0(5, P4, C5), C5 =:= 1 rdiv 120,
    format("matches hand account [1,1,1,1/3,1/12,1/120] exactly~n"),

    % (3) 第 6 轮在 x=1 的值 vs 真值 2e-2（浮点对照，误差 ~2.5e-4）
    picard(6, P6xy),
    poly_at(P6xy, 1.0, V),
    True is 2 * exp(1) - 2,
    Err is abs(V - True),
    format("y'=x+y: y_6(1) = ~4f, truth ~4f~n", [V, True]),
    Err < 5.0e-4,
    format("error ~w < 5e-4 (contraction)~n", [Err]),

    % (4) 爆破方程 y' = y²、y(1)=1：符号验证 y = 1/(2-x) 满足方程
    % y = (2-x)^{-1}：dy/dx = (2-x)^{-2} = y²（链式符号账走微分内核）
    d(div(n(1), sub(n(2), x)), x, D),
    simp(D, Ds),
    % Ds 应为 (2-x)^{-2}：即 1/(2-x)²；数值点核对
    ev_at(Ds, 1.5, DV),
    YV is 1 / (2 - 1.5),
    abs(DV - YV * YV) < 1e-12,
    format("y = 1/(2-x) satisfies y' = y^2 (symbolic + numeric)~n"),

    format("END ====~n").

% ---------- 附：微分/化简/求值内核（与 00 章同款，本章用到） ----------
d(n(_), _, n(0)).
d(x, x, n(1)) :- !.
d(add(A, B), V, add(DA, DB)) :- d(A, V, DA), d(B, V, DB).
d(sub(A, B), V, sub(DA, DB)) :- d(A, V, DA), d(B, V, DB).
d(mul(A, B), V, add(mul(DA, B), mul(A, DB))) :- d(A, V, DA), d(B, V, DB).
d(div(A, B), V, div(sub(mul(DA, B), mul(A, DB)), mul(B, B))) :-
    d(A, V, DA), d(B, V, DB).
d(pow(A, N), V, mul(n(N), mul(pow(A, N1), DA))) :-
    integer(N), N1 is N - 1, d(A, V, DA).
d(exp(A), V, mul(exp(A), DA)) :- d(A, V, DA).

tl(sum(Ts), Ts) :- !.
tl(n(C), Ts) :- !, (C =:= 0 -> Ts = [] ; Ts = [t(C, [])]).
tl(add(A, B), Ts) :- !, tl(A, TA), tl(B, TB), append(TA, TB, Ts).
tl(sub(A, B), Ts) :- !, tl(A, TA), tl(B, TB),
    maplist(neg_t, TB, TBN), append(TA, TBN, Ts).
tl(mul(A, B), Ts) :- !, tl(A, TA), tl(B, TB), prod_terms(TA, TB, Ts).
tl(div(A, B), Ts) :- !, tl(mul(A, pow(B, -1)), Ts).
tl(pow(A, N), Ts) :- !,
    ( A = n(V) -> W is V ^ N, tl(n(W), Ts)
    ; Ts = [t(1, [p(A, N)])] ).
tl(E, [t(1, [p(E, 1)])]).

neg_t(t(C, M), t(CN, M)) :- CN is -C.

prod_terms([], _, []).
prod_terms([t(Ca, Ma) | Rest], TB, Ts) :-
    prod_terms(Rest, TB, TsRest),
    ( Ca =:= 0 -> Ts = TsRest
    ; maplist(mul_term(Ca, Ma), TB, TsHead), append(TsHead, TsRest, Ts) ).

mul_term(Ca, Ma, t(Cb, Mb), t(C, M)) :- C is Ca * Cb, merge_pows(Ma, Mb, M).

merge_pows([], M, M).
merge_pows([p(F, N) | Ps], Qs, M) :- insert_pow(F, N, Qs, Qs2), merge_pows(Ps, Qs2, M).

insert_pow(F, N, [], [p(F, N)]).
insert_pow(F, N, [p(G, M) | Qs], R) :-
    ( F == G -> N2 is N + M,
        ( N2 =:= 0 -> R = Qs ; R = [p(F, N2) | Qs] )
    ; F @< G -> R = [p(F, N), p(G, M) | Qs]
    ; R = [p(G, M) | R2], insert_pow(F, N, Qs, R2) ).

combine_terms([], []).
combine_terms([t(C, M) | Ts], Out) :-
    partition(same_mono(M), Ts, Same, Rest),
    maplist(arg(1), Same, Cs),
    sum_list([C | Cs], C2),
    combine_terms(Rest, Rest2),
    ( C2 =:= 0 -> Out = Rest2 ; Out = [t(C2, M) | Rest2] ).
same_mono(M, t(_, M2)) :- M == M2.

rebuild([], n(0)).
rebuild([t(C, [])], n(C)) :- !.
rebuild([t(1, [p(F, 1)])], F) :- !.
rebuild([t(1, Ms)], S) :- !, rebuild_prod(Ms, S).
rebuild([t(C, Ms)], S) :- !, rebuild_prod(Ms, P),
    (P = n(1) -> S = n(C) ; S = mul(n(C), P)).
rebuild(Ts, sum(Ts)).

rebuild_prod([], n(1)).
rebuild_prod([p(F, 1)], F) :- !.
rebuild_prod([p(F, N)], pow(F, N)) :- !.
rebuild_prod([p(F, 1) | Ps], mul(F, R)) :- !, rebuild_prod(Ps, R).
rebuild_prod([p(F, N) | Ps], mul(pow(F, N), R)) :- rebuild_prod(Ps, R).

simp(n(C), n(C)) :- !.
simp(x, x) :- !.
simp(sum(Ts), S) :- !, combine_terms(Ts, TsC), rebuild(TsC, S).
simp(add(A, B), S) :- !, simp(A, SA), simp(B, SB),
    tl(add(SA, SB), Ts), combine_terms(Ts, TsC), rebuild(TsC, S).
simp(sub(A, B), S) :- !, simp(A, SA), simp(B, SB),
    tl(sub(SA, SB), Ts), combine_terms(Ts, TsC), rebuild(TsC, S).
simp(mul(A, B), S) :- !, simp(A, SA), simp(B, SB),
    tl(mul(SA, SB), Ts), combine_terms(Ts, TsC), rebuild(TsC, S).
simp(div(A, B), S) :- !, simp(A, SA), simp(B, SB),
    ( SB = n(V), V =\= 0 -> Q is 1 rdiv V, tl(mul(SA, n(Q)), Ts)
    ; tl(mul(SA, pow(SB, -1)), Ts) ),
    combine_terms(Ts, TsC), rebuild(TsC, S).
simp(E, E).

ev_at(n(C), _, C).
ev_at(x, X, X).

ev_at(add(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA + VB.
ev_at(sub(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA - VB.
ev_at(mul(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA * VB.
ev_at(div(A, B), X, V) :- ev_at(A, X, VA), ev_at(B, X, VB), V is VA / VB.
ev_at(neg(A), X, V) :- ev_at(A, X, VA), V is -VA.
ev_at(exp(A), X, V) :- ev_at(A, X, VA), V is exp(VA).
ev_at(pow(A, N), X, V) :- ev_at(A, X, VA), V is VA ^ N.
ev_at(sum(Ts), X, V) :- ev_terms(Ts, X, V).
ev_terms([], _, 0).
ev_terms([t(C, Ms) | Ts], X, V) :- ev_mono(Ms, X, VM), ev_terms(Ts, X, VR),
    V is C * VM + VR.
ev_mono([], _, 1).
ev_mono([p(F, N) | Ps], X, V) :- ev_at(F, X, VF), VN is VF ^ N,
    ev_mono(Ps, X, VR), V is VN * VR.



