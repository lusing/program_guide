:- encoding(utf8).
% 07_advection.pl —— 第 07 章：对流格式库与特征线插值构造（Prolog 通道）
%
% 编码铁律：首行 encoding(utf8)，运行期输出纯 ASCII。
%   (1) 四格式增长因子扫描 + 稳定域（复用 05 章复数底座）；
%   (2) 特征线插值构造规则：线性(B,C)->迎风、线性(B,D)->LF、
%       抛物(B,C,D)->LW、左侧三点->Beam-Warming；
%   (3) 性格表：一阶单调 vs 二阶振荡。

% ---------- 复数底座与增长因子（与 05 章同款） ----------
cabs2(c(R, I), V) :- V is R * R + I * I.

growth(upwind, Mu, T, c(R, I)) :- R is 1 - Mu * (1 - cos(T)), I is -Mu * sin(T).
growth(lf, Mu, T, c(R, I)) :- R is cos(T), I is -Mu * sin(T).
growth(lw, Mu, T, c(R, I)) :-
    S2 is sin(T / 2) ^ 2,
    R is 1 - 2 * Mu * Mu * S2, I is -Mu * sin(T).
growth(bw, Mu, T, c(R, I)) :-
    % |G|^2 = 1 - 4μ(1-μ)^2(2-μ) sin^4(θ/2)；实部虚部由闭式还原：
    % G = 1 − (μ/2)(3−4e^{-iθ}+e^{-2iθ}) + (μ²/2)(1−2e^{-iθ}+e^{-2iθ})
    E1C is cos(-T), E1S is sin(-T),
    E2C is cos(-2 * T), E2S is sin(-2 * T),
    R is 1 - 0.5 * Mu * (3 - 4 * E1C + E2C) + 0.5 * Mu * Mu * (1 - 2 * E1C + E2C),
    I is -0.5 * Mu * (-4 * E1S + E2S) + 0.5 * Mu * Mu * (-2 * E1S + E2S).

theta_grid(Ts) :-
    Ts = [0.05,0.15,0.30,0.50,0.75,1.00,1.25,1.50,1.75,2.00,
          2.25,2.50,2.75,3.00,3.10].

max_absG(Scheme, Mu, MaxG) :-
    theta_grid(Ts),
    findall(V, ( member(T, Ts), growth(Scheme, Mu, T, G), cabs2(G, V) ), Vs),
    max_list(Vs, M2),
    MaxG is sqrt(M2).

stable(Scheme, Mu) :- max_absG(Scheme, Mu, M), M =< 1.0 + 1.0e-9.
unstable(Scheme, Mu) :- max_absG(Scheme, Mu, M), M > 1.0 + 1.0e-9.

% ---------- 特征线插值构造规则（书 §1.5） ----------
% a>0，过 P 的特征线与 t^n 层网格线交于 Q；Q 落在网格点之间，用插值近似 u(Q)
% 插值(节点表, 格式)
interpolate([b, c], upwind) :- format("linear on B,C -> upwind~n").
interpolate([b, d], lf) :- format("linear on B,D -> Lax-Friedrichs~n").
interpolate([b, c, d], lw) :- format("parabolic on B,C,D -> Lax-Wendroff~n").
interpolate([a2, b, c], bw) :- format("left three points -> Beam-Warming~n").

% ---------- 性格表 ----------
trait(upwind, order, 1).  trait(upwind, monotone, yes).
trait(lf, order, 1).      trait(lf, monotone, yes).
trait(lf, dissipation, heavy).
trait(lw, order, 2).      trait(lw, monotone, no).   trait(lw, dissipation, light).
trait(bw, order, 2).      trait(bw, monotone, no).   trait(bw, dissipation, light).
trait(bw, extended_cfl, mu_le_2).

% ---------- main ----------
main :-
    format("==== 07 advection~n"),

    % (1) 稳定域扫描
    forall(member(Mu, [0.5, 0.9, 1.0]), ( stable(upwind, Mu), stable(lf, Mu), stable(lw, Mu) )),
    forall(member(Mu, [1.1, 1.5]), ( unstable(upwind, Mu), unstable(lf, Mu), unstable(lw, Mu) )),
    forall(member(Mu, [0.8, 1.5, 1.9]), stable(bw, Mu)),
    unstable(bw, 2.2),
    format("stability: upwind/lf/lw mu<=1; bw mu<=2 (2.2 unstable)~n"),

    % (2) 特征线插值构造
    interpolate([b, c], _), interpolate([b, d], _),
    interpolate([b, c, d], _), interpolate([a2, b, c], _),

    % (3) 性格表查询：一阶单调、二阶振荡
    trait(upwind, monotone, yes), trait(lf, monotone, yes),
    trait(lw, monotone, no), trait(bw, monotone, no),
    trait(lf, dissipation, heavy), trait(lw, dissipation, light),
    format("traits: 1st-order one-sided monotone; 2nd-order (lw/bw) oscillatory~n"),

    format("END ====~n").
