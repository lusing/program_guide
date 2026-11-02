:- encoding(utf8).
% 20_conditional_expectation.pl —— 第 20 章：条件期望（Prolog 穷举，有理数精确）
%
% ① 有限联合表 p(X,Y)：E[Y|X=x]、Var(Y|X=x) 用有理数 rdiv 精确计算
% ② 塔性质 E[E[Y|X]]=E[Y]；全方差 Var(Y)=E[Var(Y|X)]+Var(E[Y|X])
% ③ 拿出已知量 E[XY|X]=X E[Y|X]；残差 Y−E[Y|X] 与 X 的函数正交
% ④ 独立联合表 ⇒ 条件期望为常数；均值独立但不独立的反例
% ⑤ 硬币序列：n=4，E[S|前 k 次] = S_k + (n−k)/2（路径枚举）

% 联合表（分母 24）：p(x, y, 概率)
p(0, 0, 2 rdiv 24).  p(0, 1, 3 rdiv 24).  p(0, 3, 1 rdiv 24).
p(1, 0, 1 rdiv 24).  p(1, 1, 4 rdiv 24).  p(1, 3, 3 rdiv 24).
p(2, 0, 4 rdiv 24).  p(2, 1, 2 rdiv 24).  p(2, 3, 4 rdiv 24).

xs([0, 1, 2]).

px(X, PX) :- aggregate_all(sum(P), p(X, _, P), PX).

% 通用期望：E[ h(X,Y) ]
expect(H, E) :-
    aggregate_all(sum(V), (p(X, Y, P), call(H, X, Y, F), V is F * P), E).

% 条件期望：E[ h(X,Y) | X=x ]
cexp(H, X, M) :-
    px(X, PX),
    aggregate_all(sum(V), (p(X, Y, P), call(H, X, Y, F), V is F * P), S),
    M is S / PX.

hy(_, Y, Y).
hy2(_, Y, F) :- F is Y * Y.
hxy(X, Y, F) :- F is X * Y.

cm(X, M) :- cexp(hy, X, M).                       % E[Y|X=x]
cv(X, V) :- cexp(hy2, X, S), cm(X, M), V is S - M * M.   % Var(Y|X=x)

check_cond_means :-
    cm(0, M0), cm(1, M1), cm(2, M2),
    M0 =:= 1, M1 =:= 13 rdiv 8, M2 =:= 7 rdiv 5,
    format("conditional means 1, 13/8, 7/5: OK~n").

check_tower_total_var :-
    xs(Xs),
    expect(hy, EY), EY =:= 11 rdiv 8,
    expect(hy2, EY2), VarY is EY2 - EY * EY, VarY =:= 95 rdiv 64,
    aggregate_all(sum(T), (member(X, Xs), px(X, PX), cm(X, M), T is PX * M), Tower),
    Tower =:= EY,                                              % 塔性质
    aggregate_all(sum(T), (member(X, Xs), px(X, PX), cv(X, V), T is PX * V), EVar),
    aggregate_all(sum(T), (member(X, Xs), px(X, PX), cm(X, M), T is PX * M * M), EM2),
    VarE is EM2 - EY * EY,
    VarY =:= EVar + VarE,                                      % 全方差
    EVar =:= 457 rdiv 320, VarE =:= 9 rdiv 160,
    format("tower property and total variance: OK~n").

check_pullout :-
    xs(Xs),
    forall(member(X, Xs),
           ( cexp(hxy, X, L), cm(X, M), L =:= X * M )),      % E[XY|X]=X E[Y|X]
    expect(hxy, EXY),
    aggregate_all(sum(T), (member(X, Xs), px(X, PX), cm(X, M), T is PX * X * M), R),
    EXY =:= R,
    % 残差与 X 的任意函数正交：E[(Y−m(X)) h(X)] = 0，h ∈ {1, X, X², (X−1)³+7}
    forall(member(Hc, [1, x, x2, cube]),
           ( aggregate_all(sum(V),
                           ( p(X, Y, P), cm(X, M), hfun(Hc, X, HX), V is (Y - M) * HX * P ),
                           Z),
             Z =:= 0 )),
    format("pull-out and residual orthogonality: OK~n").

hfun(1, _, 1).
hfun(x, X, X).
hfun(x2, X, V) :- V is X * X.
hfun(cube, X, V) :- V is (X - 1) ** 3 + 7.

% ④ 独立表：q(x,y)=a(x)*b(y)
a(0, 1 rdiv 4). a(1, 1 rdiv 3). a(2, 5 rdiv 12).
b(0, 1 rdiv 3). b(1, 1 rdiv 3). b(3, 1 rdiv 3).

check_independent :-
    forall(member(X, [0, 1, 2]),
           ( a(X, AX),
             aggregate_all(sum(V), (b(Y, BY), V is Y * AX * BY / AX), M),
             M =:= 4 rdiv 3 )),                              % 对所有 x 同为 E[Y]=4/3
    % 均值独立但不独立：(0,0):1/3，(±1,±1):各 1/6
    Tab = [0-0-(1 rdiv 3), (-1)-(-1)-(1 rdiv 6), (-1)-1-(1 rdiv 6),
           1-(-1)-(1 rdiv 6), 1-1-(1 rdiv 6)],
    forall(member(X, [-1, 0, 1]),
           ( findall(P, member(X-_-P, Tab), Ps), sum_list(Ps, PX),
             findall(Y*P, (member(X-Y-P, Tab)), Ts),
             aggregate_all(sum(V), (member(Y*P, Ts), V is Y * P), S),
             S / PX =:= 0 )),                                % E[Y|X]=0
    findall(P, member(0-_-P, Tab), P0s), sum_list(P0s, PX0),
    findall(P, member(_-0-P, Tab), PY0s), sum_list(PY0s, PY0),
    P00 is 1 rdiv 3,
    P00 =\= PX0 * PY0,                                       % 1/3 ≠ 1/9
    format("independence vs mean-independence: OK~n").

% ⑤ 硬币序列
paths(N, Ps) :- findall(P, (length(P, N), maplist([B]>>member(B, [0, 1]), P)), Ps).

prefix_mean(N, K, Prefix, M) :-
    paths(N, All),
    findall(S, (member(Pth, All), length(Pre, K), append(Pre, _, Pth), Pre == Prefix,
                sum_list(Pth, S)), Ss),
    sum_list(Ss, T), length(Ss, C), M is T rdiv C.

check_coin :-
    N = 4,
    forall(( between(0, N, K), length(Prefix, K),
             maplist([B]>>member(B, [0, 1]), Prefix) ),
           ( prefix_mean(N, K, Prefix, M),
             sum_list(Prefix, SK),
             M =:= SK + (N - K) rdiv 2 )),
    format("coin sequence E[S_n|F_k]=S_k+(n-k)/2: OK~n").

main :-
    format("==== 20 conditional_expectation~n"),
    check_cond_means,
    check_tower_total_var,
    check_pullout,
    check_independent,
    check_coin,
    format("END ====~n"), !.

:- initialization(main).
