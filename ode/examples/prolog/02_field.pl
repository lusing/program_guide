:- encoding(utf8).
% 02_field.pl —— 第 02 章：反问题引擎 + 等斜线代数（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
%
% (1) 反问题：曲线族 y = C·g(x) ⟹ 微分方程 y' = g'(x)·y/g(x)。
%     对 g 的函数表逐个符号求导并化简，产出的 ODE 用符号微分回核。
% (2) 等斜线：对给定 f(x,y)（多项式），解 f(x,y) = k 输出 y(x) 的
%     代数式（线性情形精确；一般多项式给出关系式）。

% ---------- 微分/化简内核（与 01 章同款） ----------
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
d(sin(A), V, mul(cos(A), DA)) :- d(A, V, DA).
d(cos(A), V, neg(mul(sin(A), DA))) :- d(A, V, DA).

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
ev_at(sin(A), X, V) :- ev_at(A, X, VA), V is sin(VA).
ev_at(cos(A), X, V) :- ev_at(A, X, VA), V is cos(VA).
ev_at(pow(A, N), X, V) :- ev_at(A, X, VA), V is VA ^ N.
ev_at(sum(Ts), X, V) :- ev_terms(Ts, X, V).
ev_terms([], _, 0).
ev_terms([t(C, Ms) | Ts], X, V) :- ev_mono(Ms, X, VM), ev_terms(Ts, X, VR),
    V is C * VM + VR.
ev_mono([], _, 1).
ev_mono([p(F, N) | Ps], X, V) :- ev_at(F, X, VF), VN is VF ^ N,
    ev_mono(Ps, X, VR), V is VN * VR.

% ---------- 反问题引擎 ----------
% family_ode(G, Ode)：y = C·g(x) ⟹ y' = g'(x)·y/g(x)。
% 产出形式 mul(div(dg, g), y)。
family_ode(G, Ode) :-
    d(G, x, DG),
    simp(div(DG, G), Q),
    simp(mul(Q, y), Ode).

% family_check(G)：符号验证——取 y = C·g，算 y'，与 Ode 右端数值对照。
% 用 ev_at 在若干点核对 |C·g'(x) - g'/g·C·g| = 0（精确抵消，浮点应 < 1e-12）
family_check(G, Points, MaxErr) :-
    family_ode(G, Ode),
    maplist(point_err(G, Ode), Points, Errs),
    max_list(Errs, MaxErr).
point_err(G, Ode, X, E) :-
    C = 2.7,
    ev_at(G, X, GV),
    d(G, x, DG), ev_at(DG, X, DGV),
    subst_y(Ode, C * GV, OdeV),           % y 代入 C·g(x)
    ev_at(OdeV, X, OV),
    E is abs(C * DGV - OV).

subst_y(y, V, n(V)) :- !.
subst_y(n(C), _, n(C)) :- !.
subst_y(x, _, x) :- !.
subst_y(add(A, B), V, R) :- !, subst_y(A, V, RA), subst_y(B, V, RB),
    R = add(RA, RB).
subst_y(mul(A, B), V, R) :- !, subst_y(A, V, RA), subst_y(B, V, RB),
    R = mul(RA, RB).
subst_y(sub(A, B), V, R) :- !, subst_y(A, V, RA), subst_y(B, V, RB),
    R = sub(RA, RB).
subst_y(div(A, B), V, R) :- !, subst_y(A, V, RA), subst_y(B, V, RB),
    R = div(RA, RB).
subst_y(pow(A, N), V, R) :- !, subst_y(A, V, RA), R = pow(RA, N).
subst_y(E, _, E).

% ---------- 等斜线代数 ----------
% isocline(F, K, Line)：f(x,y) = k 解出 y（f 限于 y 的线性式：a·y + b(x)）
% 形式 add(mul(A, y), B) 或 y 或 add(B, mul(A, y))
isocline(add(mul(A, y), B), K, sub(div(sub(n(K), B), A))) :- !.
isocline(add(B, mul(A, y)), K, sub(div(sub(n(K), B), A))) :- !.
isocline(y, K, n(K)) :- !.
isocline(add(B, y), K, sub(n(K), B)) :- !.
isocline(add(y, B), K, sub(n(K), B)) :- !.

% ---------- main ----------
main :-
    format("==== 02 field~n"),

    % (1) 族 y = C·g(x) 的反问题：三个 g 的核对
    family_check(pow(x, 3), [0.7, 1.3, 2.1], E1), E1 < 1.0e-12,
    format("family y = C*x^3 -> ODE y' = 3y/x, residual ~w~n", [E1]),
    family_check(exp(x), [0.3, 1.0], E2), E2 < 1.0e-12,
    format("family y = C*e^x -> ODE y' = y, residual ~w~n", [E2]),
    family_check(sin(x), [0.5, 1.2], E3), E3 < 1.0e-12,
    format("family y = C*sin x -> ODE y' = cot(x)*y, residual ~w~n", [E3]),

    % (2) 手工账：g = x³ 时 family_ode 产出的右端化简为 3y/x
    family_ode(pow(x, 3), Ode),
    format("family_ode(x^3) = ~w~n", [Ode]),

    % (3) 等斜线：y' = x + y 的 f = 2 ⟹ y = 2 - x；y' = y 的 f = 3 ⟹ y = 3
    isocline(add(x, y), 2, sub(n(2), x)),
    format("isocline of y'=x+y at k=2: y = 2 - x~n"),
    isocline(y, 3, n(3)),
    format("isocline of y'=y at k=3: y = 3~n"),

    % (4) 方向场一撇：y' = y/x 在点 (2, 6) 的斜率 = 3（射线斜率 = 到原点连线斜率）
    S is 6 / 2,
    format("direction field y'=y/x: slope at (2,6) is ~w (ray slope)~n", [S]),

    format("END ====~n").
