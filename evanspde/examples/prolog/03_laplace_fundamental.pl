% Ch03 Laplace 方程 I：基本解规则库
%
% 对应书 §2.2.1-2.2.2：径向 ODE Φ'' + (n-1)/r Φ' = 0 的解形
% （n=2 是 log、n>=3 是 r^{2-n}）、基本解定义（书式 (6) 的常数）、
% 通量规则（任意环绕原点的球面通量 = -1）、平均值的次/超调和符号规则。
% 数值内核：圆周平均（梯形，谱精度）与通量常数的数值对账。

:- encoding(utf8).

% 基本解公式（书 (6)）：alpha(n) 是单位球体积
alpha(1, 2.0).
alpha(2, pi).
alpha(3, 4.0*pi/3).

fundamental(2, 'Phi(x) = -log|x| / (2 pi)').
fundamental(N, F) :- N >= 3, F = 'Phi(x) = |x|^(2-n) / (n(n-2) alpha(n))'.

% 通量规则：∇Φ·n 在半径 rho 球面上为常数，通量 = -1（-ΔΦ = δ 的化身）
flux_density(2, Rho, D) :- D is -1 / (2 * pi * Rho).
flux_density(3, Rho, D) :- D is -1 / (4 * pi * Rho^2).
surface(2, Rho, S) :- S is 2 * pi * Rho.
surface(3, Rho, S) :- S is 4 * pi * Rho^2.
flux(N, Rho, F) :- flux_density(N, Rho, D), surface(N, Rho, S), F is D * S.

% 次/超调和的球面平均符号（书 §2.2.3 定理 2/3 的判定面）
mean_gap(subharmonic, Gap) :- Gap > 0.
mean_gap(superharmonic, Gap) :- Gap < 0.

% 数值内核：圆周梯形平均
circle_avg(U, Cx, Cy, Rho, A) :-
    N = 4096,
    sum_theta(U, Cx, Cy, Rho, 0, N, 0.0, S),
    A is S / N.

sum_theta(_, _, _, _, K, K, Acc, Acc) :- !.
sum_theta(U, Cx, Cy, Rho, K, N, Acc, Out) :-
    Th is 2 * pi * K / N,
    X is Cx + Rho * cos(Th),
    Y is Cy + Rho * sin(Th),
    call(U, X, Y, V),
    Acc1 is Acc + V,
    K1 is K + 1,
    sum_theta(U, Cx, Cy, Rho, K1, N, Acc1, Out).

u_harm(X, Y, V) :- V is X^2 - Y^2.
u_sub(X, Y, V)  :- V is X^2 + Y^2.

main :-
    format("==== 03~n"),
    fundamental(2, F2), fundamental(3, F3),
    format("n=2: ~w~nn=3: ~w~n", [F2, F3]),
    % 通量对账：任意半径都 = -1
    forall(member(Rho, [0.3, 1.7, 4.0]),
           ( flux(2, Rho, F), abs(F + 1) < 1e-12,
             format("n=2 flux r=~w: ~6f~n", [Rho, F]) )),
    flux(3, 2.1, F3f), abs(F3f + 1) < 1e-12,
    format("n=3 flux r=2.1: ~6f~n", [F3f]),
    % 圆周平均：调和 = 中心值（Lean 通道有完整证明，这里是数值面）
    circle_avg(u_harm, 0.3, -0.4, 0.7, A1),
    abs(A1 - (0.3^2 - 0.4^2)) < 1e-10,
    format("harmonic circle avg ~6f == center~n", [A1]),
    % 次调和：平均 - 中心 = rho^2（书 p.26 的计算）
    circle_avg(u_sub, 0.2, 0.5, 0.6, A2),
    Gap is A2 - (0.2^2 + 0.5^2),
    abs(Gap - 0.36) < 1e-10,
    mean_gap(subharmonic, Gap),
    format("subharmonic gap = ~6f = rho^2~n", [Gap]),
    format("END ====~n").
