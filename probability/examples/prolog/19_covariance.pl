:- encoding(utf8).
% 19_covariance.pl —— 第 19 章：有限联合表的协方差与独立判定（Prolog，有理数精确）
%
% 两张表：A = 不相关但不独立 {(−1,1),(0,0),(1,1)} 各 1/3（Y=X²）；
%         B = 一般相依表；再核对 Var(X+Y)=Var X+Var Y+2Cov。

% joint(Name, X, Y, P)
joint(a, -1, 1, 1 rdiv 3).
joint(a,  0, 0, 1 rdiv 3).
joint(a,  1, 1, 1 rdiv 3).
joint(b, 0, 1, 1 rdiv 8).
joint(b, 1, 0, 3 rdiv 8).
joint(b, 1, 2, 1 rdiv 4).
joint(b, 2, 1, 1 rdiv 4).

pm(T, X, Y, P) :- joint(T, X, Y, E), P is E.

ex(T, E) :- aggregate_all(sum(X*P), pm(T, X, _, P), E0), E is E0.
ey(T, E) :- aggregate_all(sum(Y*P), pm(T, _, Y, P), E0), E is E0.
exy(T, E) :- aggregate_all(sum(X*Y*P), pm(T, X, Y, P), E0), E is E0.
vx(T, V) :- ex(T, M), aggregate_all(sum((X-M)^2*P), pm(T, X, _, P), V0), V is V0.
vy(T, V) :- ey(T, M), aggregate_all(sum((Y-M)^2*P), pm(T, _, Y, P), V0), V is V0.
cov(T, C) :- ex(T, A), ey(T, B), exy(T, M), C is M - A * B.
vsum(T, V) :- ex(T, A), ey(T, B), aggregate_all(sum((X+Y-A-B)^2*P), pm(T, X, Y, P), V0), V is V0.

marg_x(T, X, M) :- aggregate_all(sum(P), pm(T, X, _, P), M0), M is M0.
marg_y(T, Y, M) :- aggregate_all(sum(P), pm(T, _, Y, P), M0), M is M0.

% 独立 ⇔ 所有 (x,y) 格（含值域内零格）都等于边际积
support(T, XS, YS) :-
    findall(X, pm(T, X, _, _), X0), sort(X0, XS),
    findall(Y, pm(T, _, Y, _), Y0), sort(Y0, YS).
independent(T) :-
    support(T, XS, YS),
    forall(( member(X, XS), member(Y, YS) ),
           ( ( pm(T, X, Y, P) -> true ; P = 0 ),
             marg_x(T, X, MX), marg_y(T, Y, MY),
             P =:= MX * MY )).

check_uncorrelated :-
    cov(a, C), C =:= 0,
    \+ independent(a),
    marg_x(a, 0, MX), marg_y(a, 0, MY), MX * MY =:= 1 rdiv 9,
    pm(a, 0, 0, P), P =:= 1 rdiv 3,
    format("① table A: Cov=0 but P(0,0)=1/3 ≠ 1/9 = marginal product: OK~n").

check_algebra :-
    cov(b, C), vx(b, VX), vy(b, VY), vsum(b, VS),
    VS =:= VX + VY + 2 * C,
    C =\= 0,
    \+ independent(b),
    C =:= 1 rdiv 64, VX =:= 23 rdiv 64, VY =:= 39 rdiv 64,
    format("② table B: Cov=1/64, Var X=23/64, Var Y=39/64, Var(X+Y)=sum+2Cov: OK~n").

check_cauchy_schwarz :-
    forall(member(T, [a, b]),
           ( cov(T, C), vx(T, VX), vy(T, VY), C * C =< VX * VY )),
    format("③ Cauchy–Schwarz: Cov² ≤ VarX·VarY on both tables: OK~n").

% Bernoulli 对：Cov=0 ⇒ 独立（二值特例）
check_bernoulli :-
    forall(member(P1-P2, [(1 rdiv 2)-(1 rdiv 3), (1 rdiv 4)-(3 rdiv 5)]),
           ( P11 is P1 * P2,                       % Cov=0 ⇒ P(1,1)=p1p2
             P10 is P1 - P11, P01 is P2 - P11,
             P00 is 1 - P1 - P2 + P11,
             P10 =:= P1 * (1 - P2), P01 =:= (1 - P1) * P2,
             P00 =:= (1 - P1) * (1 - P2) )),
    format("④ Bernoulli pair: Cov=0 forces all four cells to be marginal products: OK~n").

main :-
    format("==== 19 covariance~n"),
    check_uncorrelated, check_algebra, check_cauchy_schwarz, check_bernoulli,
    format("END ====~n"), !.

:- initialization(main).
