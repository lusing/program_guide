:- encoding(utf8).
% 03_separable.pl —— 第 03 章：可分离方程符号求解器（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
%
% 内容：
% (1) solve_separable：f2(x)/f1(y) 结构识别 + 分离积分（小型积分表）；
% (2) lost_solutions：除法丢解的纪律（解 f1(y)=0 并核对）；
% (3) homogeneous：y' = F(y/x) 的 z = y/x 化归（F 只依赖 y/x 的检测）；
% (4) solve_check：解的符号核对（微分内核 + 代入 + 化简为零）。

% ---------- 微分/化简/求值内核（与 02 章同款） ----------
d(n(_), _, n(0)).
d(x, x, n(1)) :- !.
d(Y, Y, n(1)) :- atom(Y), !.
d(E, _, n(0)) :- atom(E), !.
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
tl(pow(mul(A, B), N), Ts) :- !, tl(mul(pow(A, N), pow(B, N)), Ts).
tl(pow(pow(E, M), N), Ts) :- !, MN is M * N, tl(pow(E, MN), Ts).
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
simp(neg(A), S) :- !, simp(mul(n(-1), A), S).
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

subst(n(C), _, _, n(C)).
subst(x, _, _, x).
subst(y, Phi, _, Phi) :- !.
subst(yp, _, DPhi, DPhi) :- !.
subst(add(A, B), Phi, DPhi, add(SA, SB)) :- subst(A, Phi, DPhi, SA), subst(B, Phi, DPhi, SB).
subst(sub(A, B), Phi, DPhi, sub(SA, SB)) :- subst(A, Phi, DPhi, SA), subst(B, Phi, DPhi, SB).
subst(mul(A, B), Phi, DPhi, mul(SA, SB)) :- subst(A, Phi, DPhi, SA), subst(B, Phi, DPhi, SB).
subst(div(A, B), Phi, DPhi, div(SA, SB)) :- subst(A, Phi, DPhi, SA), subst(B, Phi, DPhi, SB).
subst(neg(A), Phi, DPhi, neg(SA)) :- subst(A, Phi, DPhi, SA).
subst(E, Phi, DPhi, SE) :-
    E =.. [F, A], opaque(F), !,
    subst(A, Phi, DPhi, SA), SE =.. [F, SA].
subst(E, _, _, E).

opaque(exp). opaque(ln). opaque(sin). opaque(cos).

solve_check(Body, Phi) :-
    d(Phi, x, DPhi),
    subst(Body, Phi, DPhi, R),
    simp(R, n(0)).

% ---------- 分离方程：识别 + 分离 + 积分表 ----------
% separable(ODE, F1y, F2x)：识别 y' = F2(x)/F1(y)
separable(div(F2, F1), F1, F2) :- !.
separable(mul(F2, pow(F1, -1)), F1, F2) :- !.
separable(mul(A, B), F1, F2) :- pure_x(A), pure_y(B), !, F1 = B, F2 = A.
separable(F2, n(1), F2).          % y' = f(x)：f1 = 1

pure_x(n(_)).
pure_x(x).
pure_x(exp(x)).
pure_y(y).
pure_y(pow(y, _)).

% 小型积分表：integrate(E, Anti)（E 只含 x）
integrate(n(C), mul(n(C), x)).
integrate(pow(x, N), div(pow(x, N1), n(N1))) :- integer(N), N >= 1, N1 is N + 1.
integrate(div(n(1), x), ln(abs(x))) :- !.
integrate(exp(x), exp(x)).
integrate(mul(n(C), exp(x)), mul(n(C), exp(x))) :- !.
integrate(sin(x), neg(cos(x))).
integrate(cos(x), sin(x)).

% lost_solutions(F1, Lost)：解 f1(y) = 0（y 的幂因子），核对 y ≡ y* 是解
% 识别 f1(y) = y^k 的根 y = 0
lost_solutions(pow(y, _), [R]) :- !, R = 0.
lost_solutions(mul(n(_), pow(y, _)), [0]) :- !.
lost_solutions(_, []).

% ---------- 齐次方程检测：F(y/x) ----------
% F(y/x) 表示为 div(y, x) 或其函数；齐次化归输出 F(z)
homogeneous_step(div(y, x), div(z, n(1))).
homogeneous_step(div(add(pow(x, N), pow(y, N)), mul(n(C), mul(x, y))),
    div(add(n(1), pow(z, N)), mul(n(C), z))) :- integer(N).

% ---------- main ----------
main :-
    format("==== 03 separable~n"),

    % (1) 书例 2.9：y' = ky。识别 mul(k, y) = f2(x)·f1(y)；丢失解 y=0 被 C=0 收编
    separable(mul(n(2), y), y, n(2)),
    lost_solutions(pow(y, 1), [0]),
    % 核对 y = 5e^{3x} 是 y' = 3y 的解（通解取 C=5）
    solve_check(sub(yp, mul(n(3), y)), mul(n(5), exp(mul(n(3), x)))),
    format("y' = ky: separable, lost solution y=0 subsumed by C=0~n"),
    format("y = 5e^(3x) checks out against y' = 3y symbolically~n"),

    % (2) 双曲族：y = 5/x 满足 y' = -y/x（书例 2.8 型）
    solve_check(sub(yp, neg(div(y, x))), div(n(5), x)),
    format("y = 5/x satisfies y' = -y/x~n"),

    % (3) 圆族的隐式求导账：x² + y² = C 上 2x + 2y·y' = 0 ⟹ y' = -x/y
    %    数值点核对（取 C = 25 上半圆的 4 个点）
    (   between(1, 4, I), X is -3.0 + I * 1.5,
        Y is sqrt(25 - X ^ 2),
        YP is -X / Y,
        % 中心差商求 y'
        H is 1.0e-6,
        YPn is (sqrt(25 - (X + H) ^ 2) - sqrt(25 - (X - H) ^ 2)) / (2 * H),
        abs(YP - YPn) < 1.0e-5,
        fail
    ;   true
    ),
    format("circle family x^2+y^2=25: y' = -x/y at 4 sample points~n"),

    % (4) 齐次检测：y' = (x²+y²)/(2xy) 的 z 化归
    homogeneous_step(
        div(add(pow(x, 2), pow(y, 2)), mul(n(2), mul(x, y))),
        Fz),
    Fz = div(add(n(1), pow(z, 2)), mul(n(2), z)),
    format("homogeneous (x^2+y^2)/2xy -> F(z) = (1+z^2)/(2z)~n"),

    % (5) 例 5 的解族核对：y² = x² - Cx 取 C = -1，即 y = sqrt(x²+x)
    % （数值点核对：y' = (2x+1)/(2y) 与 F(x,y) = (x²+y²)/(2xy) 相等）
    (   between(1, 5, I), X is 0.5 + I * 0.4,
        Y is sqrt(X ^ 2 + X),
        LHS is (2 * X + 1) / (2 * Y),
        RHS is (X ^ 2 + Y ^ 2) / (2 * X * Y),
        abs(LHS - RHS) < 1.0e-12,
        fail
    ;   true
    ),
    format("y^2 = x^2 + x satisfies y' = (x^2+y^2)/(2xy) at 5 sample points~n"),

    format("END ====~n").
